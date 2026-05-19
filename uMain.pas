unit uMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, FMX.Types, FMX.Controls, FMX.Forms,
  FMX.Graphics, FMX.Dialogs, FMX.Edit, FMX.ListBox,
  FMX.Controls.Presentation, FMX.StdCtrls,
  FMX.Layouts, uData, System.ImageList,
  FMX.ImgList, System.UIConsts, uDFirebase, System.JSON;

type
  TForm1 = class(TForm)
    lytCartas: TLayout;
    btnIniciar: TButton;
    edtJ1: TEdit;
    cmbNoCar: TComboBox; // Cambiado de Edit a ComboBox
    edtJ2: TEdit;
    lblTurno: TLabel;
    lblPointsJ1: TLabel;
    Label2: TLabel;
    pnlTop: TPanel;
    pnlBajo: TPanel;
    ImageList1: TImageList;
    cmbTematica: TComboBox;
    Label1: TLabel;
    Label3: TLabel;
    btnConectar: TButton;
    TimerSincronizador: TTimer;

    procedure btnIniciarClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnConectarClick(Sender: TObject);
    procedure TimerSincronizadorTimer(Sender: TObject);
  private
    procedure ActualizarMarcador(PtsJ1, PtsJ2, TurnoActual: Integer);
  public
  end;

var
  Form1: TForm1;

implementation



{$R *.fmx}
{$R *.LgXhdpiPh.fmx ANDROID}
{$R *.NmXhdpiPh.fmx ANDROID}

procedure TForm1.FormCreate(Sender: TObject);
begin
  Cerebro.OnActualizarUI := ActualizarMarcador;

  // 1. El cerebro llena el ComboBox de número de cartas
  Cerebro.ConfigurarOpcionesCartas(cmbNoCar);

  // 2. El cerebro escanea la carpeta "Temas" y llena el ComboBox de temáticas
  Cerebro.ListarTemas(cmbTematica);
end;

procedure TForm1.TimerSincronizadorTimer(Sender: TObject);
var
  JSONStr: string;
  ConfigObj: TJSONObject;
  NubeTurno, NubePtsJ1, NubePtsJ2, NubeCarta1, NubeCarta2: Integer;
  CantidadCaras, ImgIndex, CardIdx, I: Integer;
  StrEnc: string;
  ArrEnc: TArray<string>;
begin
  TimerSincronizador.Enabled := False;
  try
    JSONStr := dmFirebase.DescargarPartida;
    if (JSONStr = '') or (JSONStr = 'null') then Exit;

    ConfigObj := TJSONObject.ParseJSONValue(JSONStr) as TJSONObject;
    if not Assigned(ConfigObj) then Exit;

    try
      // --- 1. SINCRONIZAR NOMBRES EN TIEMPO REAL ---
      if ConfigObj.GetValue('j1') <> nil then Cerebro.NombreJ1 := ConfigObj.GetValue('j1').Value;
      if ConfigObj.GetValue('j2') <> nil then Cerebro.NombreJ2 := ConfigObj.GetValue('j2').Value;

      // --- 2. EXTRAER VARIABLES DE JUEGO ---
      if ConfigObj.GetValue('turno') <> nil then NubeTurno := ConfigObj.GetValue('turno').Value.ToInteger else NubeTurno := Cerebro.Turno;
      if ConfigObj.GetValue('puntosJ1') <> nil then NubePtsJ1 := ConfigObj.GetValue('puntosJ1').Value.ToInteger else NubePtsJ1 := 0;
      if ConfigObj.GetValue('puntosJ2') <> nil then NubePtsJ2 := ConfigObj.GetValue('puntosJ2').Value.ToInteger else NubePtsJ2 := 0;
      if ConfigObj.GetValue('carta1') <> nil then NubeCarta1 := ConfigObj.GetValue('carta1').Value.ToInteger else NubeCarta1 := -1;
      if ConfigObj.GetValue('carta2') <> nil then NubeCarta2 := ConfigObj.GetValue('carta2').Value.ToInteger else NubeCarta2 := -1;

      // --- 3. ¡AVISO DE CAMBIO DE TURNO (SHOWMESSAGE)! ---
      if (Cerebro.Turno <> NubeTurno) then
      begin
        if NubeTurno = Cerebro.MiRol then
          ShowMessage('¡Es tu turno!');
      end;

      // Actualizamos datos locales
      Cerebro.Turno := NubeTurno;
      Cerebro.PtsJ1 := NubePtsJ1;
      Cerebro.PtsJ2 := NubePtsJ2;

      // Forzamos a tu interfaz a redibujar los textos (Ahora ya traerán los nombres correctos)
      if Assigned(Cerebro.OnActualizarUI) then
        Cerebro.OnActualizarUI(Cerebro.PtsJ1, Cerebro.PtsJ2, Cerebro.Turno);

      // --- 4. LEER PARES ENCONTRADOS Y DEJARLOS VOLTEADOS ---
      if ConfigObj.GetValue('encontradas') <> nil then
      begin
        StrEnc := ConfigObj.GetValue('encontradas').Value;
        ArrEnc := StrEnc.Split([',']);
        for I := 0 to Length(ArrEnc) - 1 do
        begin
          if TryStrToInt(ArrEnc[I], CardIdx) then
          begin
            Cerebro.Cartas[CardIdx].Encontrada := True;
            Cerebro.Cartas[CardIdx].Volteada := True;
            Cerebro.Cartas[CardIdx].BotonVisual.Opacity := 0.5;

            CantidadCaras := ImageList1.Source.Count - 1;
            if CantidadCaras > 0 then ImgIndex := (Cerebro.Cartas[CardIdx].IDPareja mod CantidadCaras) + 1 else ImgIndex := 0;
            Cerebro.Cartas[CardIdx].BotonVisual.Bitmap.Assign(ImageList1.Source.Items[ImgIndex].MultiResBitmap.Items[0].Bitmap);
          end;
        end;
      end;

      // --- 5. REVISAR CARTAS ACTIVAS (LAS QUE SE ESTÁN VOLTEANDO AHORITA) ---
      CantidadCaras := ImageList1.Source.Count - 1;
      for I := 0 to High(Cerebro.Cartas) do
      begin
        if (I = NubeCarta1) or (I = NubeCarta2) then
        begin
          if not Cerebro.Cartas[I].Volteada then
          begin
            Cerebro.Cartas[I].Volteada := True;
            if CantidadCaras > 0 then ImgIndex := (Cerebro.Cartas[I].IDPareja mod CantidadCaras) + 1 else ImgIndex := 0;
            Cerebro.Cartas[I].BotonVisual.Bitmap.Assign(ImageList1.Source.Items[ImgIndex].MultiResBitmap.Items[0].Bitmap);
          end;
        end
        else
        begin
          // Si no es la activa, ni es una encontrada, la ocultamos
          if Cerebro.Cartas[I].Volteada and not Cerebro.Cartas[I].Encontrada then
          begin
            Cerebro.Cartas[I].Volteada := False;
            Cerebro.Cartas[I].BotonVisual.Bitmap.Assign(ImageList1.Source.Items[0].MultiResBitmap.Items[0].Bitmap);
          end;
        end;
      end;

    finally
      ConfigObj.Free;
    end;
  finally
    TimerSincronizador.Enabled := True;
  end;
end;

procedure TForm1.btnIniciarClick(Sender: TObject);
var
  ConfigObj: TJSONObject;
  OrdenArr: TJSONArray;
  I: Integer;
begin
  // 1. Inicias tu juego local con el Cerebro
  Cerebro.CargarImagenesDeCarpeta(cmbTematica.Selected.Text, ImageList1);
  Cerebro.IniciarJuego(cmbNoCar.Selected.Text, lytCartas, ImageList1, edtJ1.Text, edtJ2.Text);

  // 2. Empaquetar todo en un JSON
  ConfigObj := TJSONObject.Create;
  try
    ConfigObj.AddPair('cartas', cmbNoCar.Selected.Text);
    ConfigObj.AddPair('tematica', cmbTematica.Selected.Text);
    ConfigObj.AddPair('j1', edtJ1.Text);
    ConfigObj.AddPair('j2', edtJ2.Text);
    ConfigObj.AddPair('turno', TJSONNumber.Create(1));

    // Obtenemos cómo barajeó el cerebro
    OrdenArr := TJSONArray.Create;
    for I := 0 to High(Cerebro.Cartas) do
      OrdenArr.Add(Cerebro.Cartas[I].IDPareja);

    ConfigObj.AddPair('orden', OrdenArr);

    // 3. ¡A LA NUBE! Mandamos llamar el método que creamos en el Paso 1
    dmFirebase.SubirInicioJuego(ConfigObj.ToString);

  finally
    ConfigObj.Free;
  end;
  TimerSincronizador.Enabled := True;
  Cerebro.MiRol := 1;
end;

procedure TForm1.btnConectarClick(Sender: TObject);
var
  JSONStr: string;
  ConfigObj: TJSONObject;
  OrdenArr: TJSONArray;
  I: Integer;
begin
  // 1. Descargamos el texto de la nube
  JSONStr := dmFirebase.DescargarPartida;

  // Si está vacío o es 'null', es que no han iniciado la partida
  if (JSONStr = 'null') or (JSONStr = '') then
  begin
    ShowMessage('Aún no hay ninguna partida iniciada en la nube.');
    Exit;
  end;

  // 2. Convertimos el texto a un Objeto JSON de Delphi
  ConfigObj := TJSONObject.ParseJSONValue(JSONStr) as TJSONObject;
  try
    // 3. Le pasamos al Cerebro la misma configuración que eligió el Host
    Cerebro.CargarImagenesDeCarpeta(ConfigObj.GetValue('tematica').Value, ImageList1);

    // Iniciamos el tablero
    Cerebro.IniciarJuego(
      ConfigObj.GetValue('cartas').Value,
      lytCartas,
      ImageList1,
      ConfigObj.GetValue('j1').Value,
      ConfigObj.GetValue('j2').Value
    );

    // 4. EL TRUCO MÁGICO: Acomodamos las cartas en el mismo orden
    OrdenArr := ConfigObj.GetValue('orden') as TJSONArray;
    for I := 0 to OrdenArr.Count - 1 do
    begin
      Cerebro.Cartas[I].IDPareja := OrdenArr.Items[I].Value.ToInteger;
    end;

    ShowMessage('¡Conectado exitosamente a la partida de ' + ConfigObj.GetValue('j1').Value + '!');

  finally
    // Limpiamos la memoria
    ConfigObj.Free;
  end;
  dmFirebase.SubirNombreJ2(edtJ1.Text);
  TimerSincronizador.Enabled := True;
  Cerebro.MiRol := 2;
end;

procedure TForm1.ActualizarMarcador(PtsJ1, PtsJ2, TurnoActual: Integer);
begin
  // Asumiendo que tu label de puntos se llama lblPointsJ1
  lblPointsJ1.Text := Cerebro.NombreJ1 + ': ' + PtsJ1.ToString + '  vs  ' +
                      Cerebro.NombreJ2 + ': ' + PtsJ2.ToString;

  // Asumiendo que tu label de turno se llama lblTurno
  if TurnoActual = 1 then
    lblTurno.Text := '¡Es turno de ' + Cerebro.NombreJ1 + '!'
  else
    lblTurno.Text := '¡Es turno de ' + Cerebro.NombreJ2 + '!';
end;

end.
