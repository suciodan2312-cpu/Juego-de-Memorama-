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
  public
    procedure ProbarConexion;
    procedure SubirInicioJuego(const ConfigJSON: string);
    function DescargarPartida: string;

    procedure ActualizarEstadoNube(
      TurnoActual,
      Puntos1,
      Puntos2,
      Carta1,
      Carta2: Integer;
      const Encontradas,
      DuenosPares: string
    );

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
  RESTRequest1.Method := rmGET;

  RESTRequest1.ClearBody;
  RESTRequest1.Execute;

  Result := RESTResponse1.Content;
end;

procedure TdmFirebase.ProbarConexion;
begin
  RESTRequest1.Resource := 'Prueba.json';
  RESTRequest1.Method := rmPUT;

  RESTRequest1.ClearBody;
  RESTRequest1.AddBody(
    '{"Mensaje": "Hola desde Delphi FMX", "Estado": "Conectado"}',
    ctAPPLICATION_JSON
  );

  RESTRequest1.Execute;
end;

procedure TdmFirebase.SubirInicioJuego(const ConfigJSON: string);
begin
  RESTRequest1.Resource := 'PartidaActual.json';
  RESTRequest1.Method := rmPUT;

  RESTRequest1.ClearBody;
  RESTRequest1.AddBody(ConfigJSON, ctAPPLICATION_JSON);

  RESTRequest1.Execute;
end;

procedure TdmFirebase.ActualizarEstadoNube(
  TurnoActual,
  Puntos1,
  Puntos2,
  Carta1,
  Carta2: Integer;
  const Encontradas,
  DuenosPares: string
);
var
  EstadoObj: TJSONObject;
begin
  RESTRequest1.Resource := 'PartidaActual.json';
  RESTRequest1.Method := rmPATCH;
  RESTRequest1.ClearBody;

  EstadoObj := TJSONObject.Create;

  try
    EstadoObj.AddPair('turno', TJSONNumber.Create(TurnoActual));
    EstadoObj.AddPair('puntosJ1', TJSONNumber.Create(Puntos1));
    EstadoObj.AddPair('puntosJ2', TJSONNumber.Create(Puntos2));
    EstadoObj.AddPair('carta1', TJSONNumber.Create(Carta1));
    EstadoObj.AddPair('carta2', TJSONNumber.Create(Carta2));

    EstadoObj.AddPair('encontradas', Encontradas);
    EstadoObj.AddPair('duenosPares', DuenosPares);

    RESTRequest1.AddBody(EstadoObj.ToString, ctAPPLICATION_JSON);
    RESTRequest1.Execute;
  finally
    EstadoObj.Free;
  end;
end;

procedure TdmFirebase.SubirNombreJ2(Nombre: string);
var
  NombreObj: TJSONObject;
begin
  RESTRequest1.Resource := 'PartidaActual.json';
  RESTRequest1.Method := rmPATCH;
  RESTRequest1.ClearBody;

  NombreObj := TJSONObject.Create;

  try
    NombreObj.AddPair('j2', Nombre);

    RESTRequest1.AddBody(NombreObj.ToString, ctAPPLICATION_JSON);
    RESTRequest1.Execute;
  finally
    NombreObj.Free;
  end;
end;

end.
