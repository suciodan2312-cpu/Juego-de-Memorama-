unit uDFirebase;

interface

uses
  System.SysUtils, System.Classes, REST.Types, REST.Client,
  Data.Bind.Components, Data.Bind.ObjectScope, System.JSON;

type
  // DataModule encargado de la comunicación con Firebase Realtime Database.
  // Aquí se centralizan las funciones para subir, descargar y actualizar la partida.
  TdmFirebase = class(TDataModule)
    RESTClient1: TRESTClient;       // Cliente REST: contiene la URL base de Firebase.
    RESTRequest1: TRESTRequest;     // Petición REST: configura recurso, método y cuerpo JSON.
    RESTResponse1: TRESTResponse;   // Respuesta REST: recibe el contenido devuelto por Firebase.

  private
    // Sección privada: aquí irían métodos internos si se necesitaran.

  public
    // Envía un JSON de prueba para comprobar que la conexión con Firebase funciona.
    procedure ProbarConexion;

    // Sube el JSON inicial de la partida completa a Firebase.
    procedure SubirInicioJuego(const ConfigJSON: string);

    // Descarga el estado actual de la partida desde Firebase.
    function DescargarPartida: string;

    // Actualiza parcialmente el estado de la partida en Firebase.
    // Guarda turno, puntos, cartas activas, cartas encontradas y dueño de cada par.
    procedure ActualizarEstadoNube(
      TurnoActual,
      Puntos1,
      Puntos2,
      Carta1,
      Carta2: Integer;
      const Encontradas,
      DuenosPares: string
    );

    // Actualiza el nombre del jugador 2 cuando se conecta a la partida.
    procedure SubirNombreJ2(Nombre: string);
  end;

var
  // Instancia global del DataModule para poder usar Firebase desde otras unidades.
  dmFirebase: TdmFirebase;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

// Descarga el nodo PartidaActual desde Firebase usando GET.
// Devuelve el JSON completo como texto.
function TdmFirebase.DescargarPartida: string;
begin
  RESTRequest1.Resource := 'PartidaActual.json';
  RESTRequest1.Method := rmGET;

  RESTRequest1.ClearBody;
  RESTRequest1.Execute;

  Result := RESTResponse1.Content;
end;

// Envía un mensaje simple a Firebase para verificar que sí hay conexión.
// Usa PUT porque sobrescribe el nodo Prueba.
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

// Sube el JSON inicial de la partida.
// Usa PUT porque crea o reemplaza por completo el nodo PartidaActual.
procedure TdmFirebase.SubirInicioJuego(const ConfigJSON: string);
begin
  RESTRequest1.Resource := 'PartidaActual.json';
  RESTRequest1.Method := rmPUT;

  RESTRequest1.ClearBody;
  RESTRequest1.AddBody(ConfigJSON, ctAPPLICATION_JSON);

  RESTRequest1.Execute;
end;

// Actualiza el estado de la partida sin borrar todo el nodo.
// Usa PATCH para modificar solo los campos necesarios.
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
  EstadoObj: TJSONObject; // Objeto JSON que se enviará a Firebase.
begin
  RESTRequest1.Resource := 'PartidaActual.json';
  RESTRequest1.Method := rmPATCH;
  RESTRequest1.ClearBody;

  EstadoObj := TJSONObject.Create;

  try
    // Variables principales del juego.
    EstadoObj.AddPair('turno', TJSONNumber.Create(TurnoActual));
    EstadoObj.AddPair('puntosJ1', TJSONNumber.Create(Puntos1));
    EstadoObj.AddPair('puntosJ2', TJSONNumber.Create(Puntos2));

    // Cartas que están volteadas actualmente.
    EstadoObj.AddPair('carta1', TJSONNumber.Create(Carta1));
    EstadoObj.AddPair('carta2', TJSONNumber.Create(Carta2));

    // Lista de cartas ya encontradas.
    EstadoObj.AddPair('encontradas', Encontradas);

    // Lista de cartas con el jugador que encontró cada par.
    EstadoObj.AddPair('duenosPares', DuenosPares);

    RESTRequest1.AddBody(EstadoObj.ToString, ctAPPLICATION_JSON);
    RESTRequest1.Execute;
  finally
    EstadoObj.Free;
  end;
end;

// Sube el nombre del jugador 2 cuando se une a una partida.
// Usa PATCH para actualizar solo el campo j2.
procedure TdmFirebase.SubirNombreJ2(Nombre: string);
var
  NombreObj: TJSONObject; // JSON pequeño que solo contiene el nombre del jugador 2.
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
