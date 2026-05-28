unit uMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, FMX.Types, FMX.Controls, FMX.Forms,
  FMX.Graphics, FMX.Dialogs, FMX.Edit, FMX.ListBox,
  FMX.Controls.Presentation,
  FMX.Layouts, uData, System.ImageList,
  FMX.ImgList, System.UIConsts, uDFirebase, System.JSON, FMX.StdCtrls,
  FMX.DialogService;

type
  TForm1 = class(TForm)
    lytCartas: TLayout;
    btnIniciar: TButton;
    edtJ1: TEdit;
    cmbNoCar: TComboBox;
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
    procedure FormResize(Sender: TObject);
    procedure btnConectarClick(Sender: TObject);
    procedure TimerSincronizadorTimer(Sender: TObject);

  private
    procedure ActualizarMarcador(PtsJ1, PtsJ2, TurnoActual: Integer);
    procedure AjustarDisenoPorOrientacion;

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

  Cerebro.ConfigurarOpcionesCartas(cmbNoCar);
  Cerebro.ListarTemas(cmbTematica);

  Label1.Text := 'Selecciona el No de cartas';
  Label3.Text := 'Selecciona la Temática';

  // Este label ya no lo usamos porque el marcador real es lblPointsJ1
  Label2.Visible := False;

  pnlTop.Align := TAlignLayout.Top;
  pnlBajo.Align := TAlignLayout.Bottom;
  lytCartas.Align := TAlignLayout.Client;

  Self.OnResize := FormResize;

  {$IFDEF MSWINDOWS}
  // En PC hacemos que inicie con buen tamaño
  Self.Width := 1200;
  Self.Height := 760;
  Self.Constraints.MinWidth := 1000;
  Self.Constraints.MinHeight := 650;
  {$ENDIF}

  AjustarDisenoPorOrientacion;

  // Esto ayuda a que Android/Windows acomode bien después de crear la ventana
  TThread.ForceQueue(nil,
    procedure
    begin
      AjustarDisenoPorOrientacion;

      if Assigned(Cerebro) then
        Cerebro.ReacomodarTablero;
    end
  );
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  AjustarDisenoPorOrientacion;

  if Assigned(Cerebro) then
    Cerebro.ReacomodarTablero;

  // En Android al girar pantalla a veces actualiza medidas después de unos ms
  TThread.ForceQueue(nil,
    procedure
    begin
      AjustarDisenoPorOrientacion;

      if Assigned(Cerebro) then
        Cerebro.ReacomodarTablero;
    end
  );
end;

procedure TForm1.AjustarDisenoPorOrientacion;
var
  EsVertical: Boolean;
  Margen: Single;
  Gap: Single;
  W: Single;
  ColW: Single;
  CtrlW: Single;
  BtnW: Single;
  BtnGap: Single;
  BtnInicioX: Single;
  X1, X2, X3, X4: Single;
begin
  W := Self.Width;

  if W <= 0 then
    Exit;

  Margen := 14;
  Gap := 14;

  EsVertical := Self.Height > Self.Width;

  // Aseguramos padres correctos
  edtJ1.Parent := pnlTop;
  edtJ2.Parent := pnlTop;
  Label1.Parent := pnlTop;
  cmbNoCar.Parent := pnlTop;
  Label3.Parent := pnlTop;
  cmbTematica.Parent := pnlTop;

  lblPointsJ1.Parent := pnlBajo;
  lblTurno.Parent := pnlBajo;
  btnIniciar.Parent := pnlBajo;
  btnConectar.Parent := pnlBajo;

  Label2.Visible := False;

  // ==========================================================
  // VERTICAL / TELÉFONO
  // Este diseño ya te quedó bien, por eso casi no se toca
  // ==========================================================
  if EsVertical then
  begin
    pnlTop.Height := 145;
    pnlBajo.Height := 125;

    ColW := (W - (Margen * 3)) / 2;

    edtJ1.Width := ColW;
    edtJ1.Height := 36;
    edtJ1.Position.X := Margen;
    edtJ1.Position.Y := 12;

    edtJ2.Width := ColW;
    edtJ2.Height := 36;
    edtJ2.Position.X := Margen + ColW + Margen;
    edtJ2.Position.Y := 12;

    Label1.Width := ColW;
    Label1.Height := 22;
    Label1.Position.X := Margen;
    Label1.Position.Y := 58;
    Label1.TextSettings.HorzAlign := TTextAlign.Leading;

    cmbNoCar.Width := ColW;
    cmbNoCar.Height := 36;
    cmbNoCar.Position.X := Margen;
    cmbNoCar.Position.Y := 84;

    Label3.Width := ColW;
    Label3.Height := 22;
    Label3.Position.X := Margen + ColW + Margen;
    Label3.Position.Y := 58;
    Label3.TextSettings.HorzAlign := TTextAlign.Leading;

    cmbTematica.Width := ColW;
    cmbTematica.Height := 36;
    cmbTematica.Position.X := Margen + ColW + Margen;
    cmbTematica.Position.Y := 84;

    lblPointsJ1.Width := W - (Margen * 2);
    lblPointsJ1.Height := 24;
    lblPointsJ1.Position.X := Margen;
    lblPointsJ1.Position.Y := 8;
    lblPointsJ1.TextSettings.HorzAlign := TTextAlign.Leading;

    lblTurno.Width := W - (Margen * 2);
    lblTurno.Height := 24;
    lblTurno.Position.X := Margen;
    lblTurno.Position.Y := 36;
    lblTurno.TextSettings.HorzAlign := TTextAlign.Leading;

    btnIniciar.Width := ColW;
    btnIniciar.Height := 40;
    btnIniciar.Position.X := Margen;
    btnIniciar.Position.Y := 76;

    btnConectar.Width := ColW;
    btnConectar.Height := 40;
    btnConectar.Position.X := Margen + ColW + Margen;
    btnConectar.Position.Y := 76;
  end
  else
  begin
    // ==========================================================
    // HORIZONTAL / PC Y CELULAR
    // Aquí se corrige el encimado usando columnas automáticas
    // ==========================================================

    pnlTop.Height := 105;
    pnlBajo.Height := 78;

    // Dividimos el panel superior en 4 columnas:
    // Jugador 1 | Jugador 2 | No. cartas | Temática
    ColW := (W - (Margen * 2) - (Gap * 3)) / 4;

    if ColW < 120 then
      ColW := 120;

    CtrlW := ColW;

    if CtrlW > 210 then
      CtrlW := 210;

    X1 := Margen;
    X2 := Margen + ColW + Gap;
    X3 := Margen + ((ColW + Gap) * 2);
    X4 := Margen + ((ColW + Gap) * 3);

    // Jugador 1
    edtJ1.Width := CtrlW;
    edtJ1.Height := 34;
    edtJ1.Position.X := X1 + ((ColW - CtrlW) / 2);
    edtJ1.Position.Y := 47;

    // Jugador 2
    edtJ2.Width := CtrlW;
    edtJ2.Height := 34;
    edtJ2.Position.X := X2 + ((ColW - CtrlW) / 2);
    edtJ2.Position.Y := 47;

    // Label cartas
    Label1.Width := ColW;
    Label1.Height := 24;
    Label1.Position.X := X3;
    Label1.Position.Y := 18;
    Label1.TextSettings.HorzAlign := TTextAlign.Center;

    // Combo cartas
    cmbNoCar.Width := CtrlW;
    cmbNoCar.Height := 34;
    cmbNoCar.Position.X := X3 + ((ColW - CtrlW) / 2);
    cmbNoCar.Position.Y := 47;

    // Label temática
    Label3.Width := ColW;
    Label3.Height := 24;
    Label3.Position.X := X4;
    Label3.Position.Y := 18;
    Label3.TextSettings.HorzAlign := TTextAlign.Center;

    // Combo temática
    cmbTematica.Width := CtrlW;
    cmbTematica.Height := 34;
    cmbTematica.Position.X := X4 + ((ColW - CtrlW) / 2);
    cmbTematica.Position.Y := 47;

    // Botones centrados abajo
    BtnGap := 22;
    BtnW := 170;

    if W < 900 then
      BtnW := 150;

    BtnInicioX := (W - ((BtnW * 2) + BtnGap)) / 2;

    btnIniciar.Width := BtnW;
    btnIniciar.Height := 38;
    btnIniciar.Position.X := BtnInicioX;
    btnIniciar.Position.Y := 10;

    btnConectar.Width := BtnW;
    btnConectar.Height := 38;
    btnConectar.Position.X := BtnInicioX + BtnW + BtnGap;
    btnConectar.Position.Y := 10;

    // Marcador abajo izquierda
    lblPointsJ1.Width := (W / 2) - 40;
    lblPointsJ1.Height := 24;
    lblPointsJ1.Position.X := Margen;
    lblPointsJ1.Position.Y := 50;
    lblPointsJ1.TextSettings.HorzAlign := TTextAlign.Leading;

    // Turno abajo derecha
    lblTurno.Width := (W / 2) - 40;
    lblTurno.Height := 24;
    lblTurno.Position.X := W - lblTurno.Width - Margen;
    lblTurno.Position.Y := 50;
    lblTurno.TextSettings.HorzAlign := TTextAlign.Trailing;
  end;
end;

procedure TForm1.TimerSincronizadorTimer(Sender: TObject);
var
  JSONStr: string;
  ConfigObj: TJSONObject;
  NubeTurno, NubePtsJ1, NubePtsJ2, NubeCarta1, NubeCarta2: Integer;
  CantidadCaras, ImgIndex, CardIdx, I: Integer;
  StrEnc, StrDuenos: string;
  ArrEnc, ArrDuenos, Partes: TArray<string>;
  Duenio: Integer;
begin
  if Cerebro.EsModoLocal then
  begin
    TimerSincronizador.Enabled := False;
    Exit;
  end;

  TimerSincronizador.Enabled := False;

  try
    JSONStr := dmFirebase.DescargarPartida;

    if (JSONStr = '') or (JSONStr = 'null') then
      Exit;

    ConfigObj := TJSONObject.ParseJSONValue(JSONStr) as TJSONObject;

    if not Assigned(ConfigObj) then
      Exit;

    try
      if ConfigObj.GetValue('j1') <> nil then
        Cerebro.NombreJ1 := ConfigObj.GetValue('j1').Value;

      if ConfigObj.GetValue('j2') <> nil then
        Cerebro.NombreJ2 := ConfigObj.GetValue('j2').Value;

      if ConfigObj.GetValue('turno') <> nil then
        NubeTurno := ConfigObj.GetValue('turno').Value.ToInteger
      else
        NubeTurno := Cerebro.Turno;

      if ConfigObj.GetValue('puntosJ1') <> nil then
        NubePtsJ1 := ConfigObj.GetValue('puntosJ1').Value.ToInteger
      else
        NubePtsJ1 := 0;

      if ConfigObj.GetValue('puntosJ2') <> nil then
        NubePtsJ2 := ConfigObj.GetValue('puntosJ2').Value.ToInteger
      else
        NubePtsJ2 := 0;

      if ConfigObj.GetValue('carta1') <> nil then
        NubeCarta1 := ConfigObj.GetValue('carta1').Value.ToInteger
      else
        NubeCarta1 := -1;

      if ConfigObj.GetValue('carta2') <> nil then
        NubeCarta2 := ConfigObj.GetValue('carta2').Value.ToInteger
      else
        NubeCarta2 := -1;

      Cerebro.Turno := NubeTurno;
      Cerebro.PtsJ1 := NubePtsJ1;
      Cerebro.PtsJ2 := NubePtsJ2;

      if Assigned(Cerebro.OnActualizarUI) then
        Cerebro.OnActualizarUI(Cerebro.PtsJ1, Cerebro.PtsJ2, Cerebro.Turno);

      Cerebro.VerificarFinDeJuego;

      // Leer cartas encontradas
      if ConfigObj.GetValue('encontradas') <> nil then
      begin
        StrEnc := ConfigObj.GetValue('encontradas').Value;
        ArrEnc := StrEnc.Split([',']);

        for I := 0 to Length(ArrEnc) - 1 do
        begin
          if TryStrToInt(ArrEnc[I], CardIdx) then
          begin
            if (CardIdx >= 0) and (CardIdx <= High(Cerebro.Cartas)) then
            begin
              CantidadCaras := ImageList1.Source.Count - 1;

              if CantidadCaras > 0 then
                ImgIndex := (Cerebro.Cartas[CardIdx].IDPareja mod CantidadCaras) + 1
              else
                ImgIndex := 0;

              Cerebro.Cartas[CardIdx].BotonVisual.Bitmap.Assign(
                ImageList1.Source.Items[ImgIndex].MultiResBitmap.Items[0].Bitmap
              );

              Cerebro.AplicarParEncontrado(CardIdx, 0);
            end;
          end;
        end;
      end;

      // Leer dueño de cada carta encontrada
      if ConfigObj.GetValue('duenosPares') <> nil then
      begin
        StrDuenos := ConfigObj.GetValue('duenosPares').Value;
        ArrDuenos := StrDuenos.Split([',']);

        for I := 0 to Length(ArrDuenos) - 1 do
        begin
          if ArrDuenos[I].Trim = '' then
            Continue;

          Partes := ArrDuenos[I].Split([':']);

          if Length(Partes) = 2 then
          begin
            if TryStrToInt(Partes[0], CardIdx) and TryStrToInt(Partes[1], Duenio) then
            begin
              if (CardIdx >= 0) and (CardIdx <= High(Cerebro.Cartas)) then
                Cerebro.AplicarParEncontrado(CardIdx, Duenio);
            end;
          end;
        end;
      end;

      // Replicar cartas activas en vivo
      CantidadCaras := ImageList1.Source.Count - 1;

      for I := 0 to High(Cerebro.Cartas) do
      begin
        if (I = NubeCarta1) or (I = NubeCarta2) then
        begin
          if not Cerebro.Cartas[I].Volteada then
          begin
            Cerebro.Cartas[I].Volteada := True;

            if CantidadCaras > 0 then
              ImgIndex := (Cerebro.Cartas[I].IDPareja mod CantidadCaras) + 1
            else
              ImgIndex := 0;

            Cerebro.Cartas[I].BotonVisual.Bitmap.Assign(
              ImageList1.Source.Items[ImgIndex].MultiResBitmap.Items[0].Bitmap
            );
          end;
        end
        else
        begin
          if Cerebro.Cartas[I].Volteada and not Cerebro.Cartas[I].Encontrada then
          begin
            if (I <> Cerebro.FPrimerCarta) and (I <> Cerebro.FSegundaCarta) then
            begin
              Cerebro.Cartas[I].Volteada := False;

              Cerebro.Cartas[I].BotonVisual.Bitmap.Assign(
                ImageList1.Source.Items[0].MultiResBitmap.Items[0].Bitmap
              );
            end;
          end;
        end;
      end;

      AjustarDisenoPorOrientacion;
      Cerebro.ReacomodarTablero;

    finally
      ConfigObj.Free;
    end;

  finally
    if not Cerebro.JuegoTerminado then
      TimerSincronizador.Enabled := True;
  end;

  Cerebro.VerificarFinDeJuego;
end;

procedure TForm1.btnIniciarClick(Sender: TObject);
begin
  TDialogService.MessageDialog(
    '¿Desea jugar una partida LOCAL en este mismo dispositivo?' + #13#10 +
    'Seleccione "No" para iniciar una partida en RED (como Servidor/Host).',
    TMsgDlgType.mtConfirmation,
    [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
    TMsgDlgBtn.mbYes,
    0,
    procedure(const AResult: TModalResult)
    var
      ConfigObj: TJSONObject;
      OrdenArr: TJSONArray;
      I: Integer;
    begin
      if AResult = mrYes then
      begin
        Cerebro.EsModoLocal := True;
        TimerSincronizador.Enabled := False;

        Cerebro.CargarImagenesDeCarpeta(cmbTematica.Selected.Text, ImageList1);

        Cerebro.IniciarJuego(
          cmbNoCar.Selected.Text,
          lytCartas,
          ImageList1,
          edtJ1.Text,
          edtJ2.Text
        );

        AjustarDisenoPorOrientacion;
        Cerebro.ReacomodarTablero;
      end
      else
      begin
        Cerebro.EsModoLocal := False;

        Cerebro.CargarImagenesDeCarpeta(cmbTematica.Selected.Text, ImageList1);

        Cerebro.IniciarJuego(
          cmbNoCar.Selected.Text,
          lytCartas,
          ImageList1,
          edtJ1.Text,
          edtJ2.Text
        );

        ConfigObj := TJSONObject.Create;

        try
          ConfigObj.AddPair('cartas', cmbNoCar.Selected.Text);
          ConfigObj.AddPair('tematica', cmbTematica.Selected.Text);
          ConfigObj.AddPair('j1', edtJ1.Text);
          ConfigObj.AddPair('j2', edtJ2.Text);
          ConfigObj.AddPair('turno', TJSONNumber.Create(1));

          ConfigObj.AddPair('encontradas', '');
          ConfigObj.AddPair('duenosPares', '');
          ConfigObj.AddPair('carta1', TJSONNumber.Create(-1));
          ConfigObj.AddPair('carta2', TJSONNumber.Create(-1));
          ConfigObj.AddPair('puntosJ1', TJSONNumber.Create(0));
          ConfigObj.AddPair('puntosJ2', TJSONNumber.Create(0));

          OrdenArr := TJSONArray.Create;

          for I := 0 to High(Cerebro.Cartas) do
            OrdenArr.Add(Cerebro.Cartas[I].IDPareja);

          ConfigObj.AddPair('orden', OrdenArr);

          dmFirebase.SubirInicioJuego(ConfigObj.ToString);
        finally
          ConfigObj.Free;
        end;

        AjustarDisenoPorOrientacion;
        Cerebro.ReacomodarTablero;

        TimerSincronizador.Enabled := True;
        Cerebro.MiRol := 1;
      end;
    end
  );
end;

procedure TForm1.btnConectarClick(Sender: TObject);
var
  JSONStr: string;
  ConfigObj: TJSONObject;
  OrdenArr: TJSONArray;
  I: Integer;
begin
  Cerebro.EsModoLocal := False;

  JSONStr := dmFirebase.DescargarPartida;

  if (JSONStr = 'null') or (JSONStr = '') then
  begin
    TDialogService.ShowMessage('Aún no hay ninguna partida iniciada en la nube.');
    Exit;
  end;

  ConfigObj := TJSONObject.ParseJSONValue(JSONStr) as TJSONObject;

  try
    Cerebro.CargarImagenesDeCarpeta(ConfigObj.GetValue('tematica').Value, ImageList1);

    Cerebro.IniciarJuego(
      ConfigObj.GetValue('cartas').Value,
      lytCartas,
      ImageList1,
      ConfigObj.GetValue('j1').Value,
      ConfigObj.GetValue('j2').Value
    );

    OrdenArr := ConfigObj.GetValue('orden') as TJSONArray;

    for I := 0 to OrdenArr.Count - 1 do
    begin
      Cerebro.Cartas[I].IDPareja := OrdenArr.Items[I].Value.ToInteger;
    end;

    AjustarDisenoPorOrientacion;
    Cerebro.ReacomodarTablero;

    TDialogService.ShowMessage(
      '¡Conectado exitosamente a la partida de ' +
      ConfigObj.GetValue('j1').Value +
      '!'
    );

  finally
    ConfigObj.Free;
  end;

  dmFirebase.SubirNombreJ2(edtJ1.Text);

  TimerSincronizador.Enabled := True;
  Cerebro.MiRol := 2;
end;

procedure TForm1.ActualizarMarcador(PtsJ1, PtsJ2, TurnoActual: Integer);
begin
  lblPointsJ1.Text :=
    Cerebro.NombreJ1 + ': ' + PtsJ1.ToString +
    '  vs  ' +
    Cerebro.NombreJ2 + ': ' + PtsJ2.ToString;

  if Cerebro.EsModoLocal then
  begin
    if TurnoActual = 1 then
      lblTurno.Text := '¡Es turno de ' + Cerebro.NombreJ1 + '!'
    else
      lblTurno.Text := '¡Es turno de ' + Cerebro.NombreJ2 + '!';

    lblTurno.FontColor := TAlphaColors.Black;
    lblTurno.Font.Style := [TFontStyle.fsBold];
  end
  else
  begin
    if TurnoActual = Cerebro.MiRol then
    begin
      lblTurno.Text := '¡ES TU TURNO!';
      lblTurno.FontColor := TAlphaColors.Darkred;
      lblTurno.Font.Style := [TFontStyle.fsBold];
    end
    else
    begin
      if TurnoActual = 1 then
        lblTurno.Text := 'Esperando a ' + Cerebro.NombreJ1 + '...'
      else
        lblTurno.Text := 'Esperando a ' + Cerebro.NombreJ2 + '...';

      lblTurno.FontColor := TAlphaColors.Gray;
      lblTurno.Font.Style := [];
    end;
  end;
end;

end.
