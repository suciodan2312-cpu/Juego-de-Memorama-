unit uDFirebase;

interface

uses
  System.SysUtils, System.Classes, REST.Types, REST.Client,
  Data.Bind.Components, Data.Bind.ObjectScope, System.JSON;

type
  TdmFirebase = class(TDataModule)
    RESTClient1: TRESTClient;
    RESTRequest1: TRESTRequest;
    RESTResponse1: TRESTResponse;
  private
    { Private declarations }
  public
    procedure ProbarConexion;
    procedure SubirInicioJuego(const ConfigJSON: string);
    function DescargarPartida: string;
    procedure ActualizarEstadoNube(TurnoActual, Puntos1, Puntos2, Carta1, Carta2: Integer; const Encontradas: string);
    procedure SubirNombreJ2(Nombre: string);
  end;

var
  dmFirebase: TdmFirebase;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}
{$R *.dfm}

function TdmFirebase.DescargarPartida: string;
begin
  RESTRequest1.Resource := 'PartidaActual.json';
  RESTRequest1.Method := rmGET; // GET es el método para descargar datos

  RESTRequest1.ClearBody;
  RESTRequest1.Execute;

  // Devolvemos el texto que descargamos (el JSON)
  Result := RESTResponse1.Content;
end;

procedure TdmFirebase.ProbarConexion;
begin
  // 1. Le decimos a Firebase a qué "nodo" o carpeta queremos ir
  // Importante: La API REST de Firebase requiere que agreguemos ".json" al final
  RESTRequest1.Resource := 'Prueba.json';

  // 2. Usamos el método PUT para escribir datos (reemplaza lo que haya)
  RESTRequest1.Method := rmPUT;

  // 3. Limpiamos cualquier dato anterior y agregamos nuestro JSON de prueba
  RESTRequest1.ClearBody;
  RESTRequest1.AddBody('{"Mensaje": "Hola desde Delphi FMX", "Estado": "Conectado"}',
                       ctAPPLICATION_JSON);

  // 4. ¡Ejecutamos la petición!
  RESTRequest1.Execute;
end;

procedure TdmFirebase.SubirInicioJuego(const ConfigJSON: string);
begin
  // Lo guardaremos en un "nodo" llamado PartidaActual
  RESTRequest1.Resource := 'PartidaActual.json';
  RESTRequest1.Method := rmPUT; // PUT reemplaza toda la partida anterior por esta nueva

  RESTRequest1.ClearBody;
  RESTRequest1.AddBody(ConfigJSON, ctAPPLICATION_JSON);

  RESTRequest1.Execute;
end;

procedure TdmFirebase.ActualizarEstadoNube(TurnoActual, Puntos1, Puntos2, Carta1, Carta2: Integer; const Encontradas: string);
var
  EstadoObj: TJSONObject;
begin
  RESTRequest1.Resource := 'PartidaActual.json';
  RESTRequest1.Method := rmPATCH;

  EstadoObj := TJSONObject.Create;
  try
    EstadoObj.AddPair('turno', TJSONNumber.Create(TurnoActual));
    EstadoObj.AddPair('puntosJ1', TJSONNumber.Create(Puntos1));
    EstadoObj.AddPair('puntosJ2', TJSONNumber.Create(Puntos2));
    EstadoObj.AddPair('carta1', TJSONNumber.Create(Carta1));
    EstadoObj.AddPair('carta2', TJSONNumber.Create(Carta2));

    // NUEVO: Agregamos las cartas descubiertas
    EstadoObj.AddPair('encontradas', Encontradas);

    RESTRequest1.ClearBody;
    RESTRequest1.AddBody(EstadoObj.ToString, ctAPPLICATION_JSON);
    RESTRequest1.Execute;
  finally
    EstadoObj.Free;
  end;
end;

procedure TdmFirebase.SubirNombreJ2(Nombre: string);
var
  Obj: TJSONObject;
begin
  RESTRequest1.Resource := 'PartidaActual.json';
  RESTRequest1.Method := rmPATCH;
  Obj := TJSONObject.Create;
  try
    Obj.AddPair('j2', Nombre); // Guardamos el nombre del Jugador 2
    RESTRequest1.ClearBody;
    RESTRequest1.AddBody(Obj.ToString, ctAPPLICATION_JSON);
    RESTRequest1.Execute;
  finally
    Obj.Free;
  end;
end;

end.

