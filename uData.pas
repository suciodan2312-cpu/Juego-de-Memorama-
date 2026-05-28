unit uData;

interface

uses
  System.SysUtils, System.Classes, System.Math, FMX.Types, FMX.Layouts,
  FMX.Objects, FMX.Dialogs, System.UIConsts, System.UITypes,
  System.Types, FMX.ImgList, FMX.Graphics, FMX.ListBox, FMX.DialogService,
  System.IOUtils, FMX.StdCtrls;

type
  TCartaLogica = record
    IDPareja: Integer;
    Volteada: Boolean;
    Encontrada: Boolean;
    DuenioPar: Integer;       // 0 = nadie, 1 = jugador 1, 2 = jugador 2
    BotonVisual: TImage;

    MarcaFondo: TRectangle;   // Fondo tipo etiqueta
    MarcaVisual: TLabel;      // Texto de la marca
  end;

  TActualizarUIEvent = procedure(PtsJ1, PtsJ2, TurnoActual: Integer) of object;

  TCerebroMemorama = class
  private
    FTablero: TLayout;
    FListaImagenes: TCustomImageList;
    FTimerEspera: TTimer;

    procedure GenerarYRevolverCartas(TotalCartas: Integer);
    procedure CartaClickeada(Sender: TObject);
    procedure TimerEsperaTick(Sender: TObject);
    procedure MostrarImagen(CartaIdx, ImgIndex: Integer);
    procedure CalcularGrid(Total: Integer; out Cols, Filas: Integer);

    procedure CrearMarcaCarta(CartaIdx: Integer);
    procedure MostrarMarcaGanador(CartaIdx, Duenio: Integer);

  public
    Cartas: array of TCartaLogica;

    FPrimerCarta, FSegundaCarta: Integer;

    ParesTotales: Integer;
    Turno: Integer;
    PtsJ1, PtsJ2: Integer;
    NombreJ1, NombreJ2: String;
    OnActualizarUI: TActualizarUIEvent;
    MiRol: Integer;
    EsModoLocal: Boolean;
    JuegoTerminado: Boolean;

    constructor Create;
    destructor Destroy; override;

    procedure ConfigurarOpcionesCartas(AComboBox: TComboBox);
    procedure ListarTemas(AComboBox: TComboBox);
    procedure CargarImagenesDeCarpeta(NombreTema: String; AImageList: TImageList);
    procedure VerificarFinDeJuego;

    procedure AplicarParEncontrado(CartaIdx, Duenio: Integer);
    function ObtenerEncontradasCSV: string;
    function ObtenerDuenosParesCSV: string;

    procedure IniciarJuego(
      TextoCantCartas: String;
      ContenedorVisual: TLayout;
      ListaImagenes: TCustomImageList;
      J1, J2: String
    );
  end;

var
  Cerebro: TCerebroMemorama;

implementation

uses
  uDFirebase;

constructor TCerebroMemorama.Create;
begin
  FTimerEspera := TTimer.Create(nil);
  FTimerEspera.Enabled := False;
  FTimerEspera.Interval := 1500;
  FTimerEspera.OnTimer := TimerEsperaTick;

  EsModoLocal := False;
  JuegoTerminado := False;
end;

destructor TCerebroMemorama.Destroy;
begin
  FTimerEspera.Free;
  inherited;
end;

procedure TCerebroMemorama.ConfigurarOpcionesCartas(AComboBox: TComboBox);
begin
  AComboBox.Items.Clear;
  AComboBox.Items.Add('4');
  AComboBox.Items.Add('8');
  AComboBox.Items.Add('12');
  AComboBox.Items.Add('16');
  AComboBox.Items.Add('20');
  AComboBox.ItemIndex := 1;
end;

procedure TCerebroMemorama.ListarTemas(AComboBox: TComboBox);
var
  RutaBase, RutaTemas: string;
  Carpetas: TStringDynArray;
  Carpeta: string;
begin
  AComboBox.Items.Clear;

  {$IFDEF MSWINDOWS}
  RutaBase := TPath.GetDirectoryName(ParamStr(0));
  {$ELSE}
  RutaBase := TPath.GetDocumentsPath;
  {$ENDIF}

  RutaTemas := TPath.Combine(RutaBase, 'Temas');

  if TDirectory.Exists(RutaTemas) then
  begin
    Carpetas := TDirectory.GetDirectories(RutaTemas);

    for Carpeta in Carpetas do
      AComboBox.Items.Add(TPath.GetFileName(Carpeta));

    if AComboBox.Items.Count > 0 then
      AComboBox.ItemIndex := 0;
  end;
end;

procedure TCerebroMemorama.CargarImagenesDeCarpeta(NombreTema: String; AImageList: TImageList);
var
  RutaBase, RutaTema, Archivo, NombreArchivo: string;
  Archivos: TStringDynArray;
  SourceItem: TCustomSourceItem;
  RutaReverso: string;
  ListaCaras: TStringList;
begin
  AImageList.Source.Clear;

  {$IFDEF MSWINDOWS}
  RutaBase := TPath.GetDirectoryName(ParamStr(0));
  {$ELSE}
  RutaBase := TPath.GetDocumentsPath;
  {$ENDIF}

  RutaTema := TPath.Combine(TPath.Combine(RutaBase, 'Temas'), NombreTema);

  if not TDirectory.Exists(RutaTema) then
    Exit;

  Archivos := TDirectory.GetFiles(RutaTema, '*.png');
  RutaReverso := '';
  ListaCaras := TStringList.Create;

  try
    for Archivo in Archivos do
    begin
      NombreArchivo := TPath.GetFileName(Archivo);

      if SameText(NombreArchivo, 'reverso.png') then
        RutaReverso := Archivo
      else
        ListaCaras.Add(Archivo);
    end;

    if RutaReverso <> '' then
    begin
      SourceItem := AImageList.Source.Add;
      SourceItem.MultiResBitmap.Add.Bitmap.LoadFromFile(RutaReverso);
    end;

    for Archivo in ListaCaras do
    begin
      SourceItem := AImageList.Source.Add;
      SourceItem.MultiResBitmap.Add.Bitmap.LoadFromFile(Archivo);
    end;
  finally
    ListaCaras.Free;
  end;
end;

procedure TCerebroMemorama.CalcularGrid(Total: Integer; out Cols, Filas: Integer);
begin
  Cols := Ceil(Sqrt(Total));

  while (Total mod Cols <> 0) do
    Inc(Cols);

  Filas := Total div Cols;

  if (FTablero.Width > FTablero.Height) and (Filas > Cols) then
  begin
    Total := Cols;
    Cols := Filas;
    Filas := Total;
  end;
end;

procedure TCerebroMemorama.CrearMarcaCarta(CartaIdx: Integer);
begin
  // Fondo tipo etiqueta/pastilla
  Cartas[CartaIdx].MarcaFondo := TRectangle.Create(FTablero);
  Cartas[CartaIdx].MarcaFondo.Parent := FTablero;

  Cartas[CartaIdx].MarcaFondo.Width := Cartas[CartaIdx].BotonVisual.Width * 0.65;
  Cartas[CartaIdx].MarcaFondo.Height := 32;

  Cartas[CartaIdx].MarcaFondo.Position.X :=
    Cartas[CartaIdx].BotonVisual.Position.X +
    ((Cartas[CartaIdx].BotonVisual.Width - Cartas[CartaIdx].MarcaFondo.Width) / 2);

  Cartas[CartaIdx].MarcaFondo.Position.Y :=
    Cartas[CartaIdx].BotonVisual.Position.Y + 8;

  Cartas[CartaIdx].MarcaFondo.XRadius := 12;
  Cartas[CartaIdx].MarcaFondo.YRadius := 12;

  Cartas[CartaIdx].MarcaFondo.Fill.Kind := TBrushKind.Solid;
  Cartas[CartaIdx].MarcaFondo.Fill.Color := TAlphaColors.Black;

  Cartas[CartaIdx].MarcaFondo.Stroke.Kind := TBrushKind.Solid;
  Cartas[CartaIdx].MarcaFondo.Stroke.Color := TAlphaColors.White;
  Cartas[CartaIdx].MarcaFondo.Stroke.Thickness := 2;

  Cartas[CartaIdx].MarcaFondo.Opacity := 0.90;
  Cartas[CartaIdx].MarcaFondo.Visible := False;
  Cartas[CartaIdx].MarcaFondo.HitTest := False;

  // Texto encima del fondo
  Cartas[CartaIdx].MarcaVisual := TLabel.Create(Cartas[CartaIdx].MarcaFondo);
  Cartas[CartaIdx].MarcaVisual.Parent := Cartas[CartaIdx].MarcaFondo;

  Cartas[CartaIdx].MarcaVisual.Align := TAlignLayout.Client;
  Cartas[CartaIdx].MarcaVisual.Text := '';
  Cartas[CartaIdx].MarcaVisual.Visible := True;
  Cartas[CartaIdx].MarcaVisual.HitTest := False;

  Cartas[CartaIdx].MarcaVisual.StyledSettings :=
    Cartas[CartaIdx].MarcaVisual.StyledSettings -
    [TStyledSetting.FontColor, TStyledSetting.Size, TStyledSetting.Style];

  Cartas[CartaIdx].MarcaVisual.TextSettings.HorzAlign := TTextAlign.Center;
  Cartas[CartaIdx].MarcaVisual.TextSettings.VertAlign := TTextAlign.Center;
  Cartas[CartaIdx].MarcaVisual.TextSettings.Font.Size := 15;
  Cartas[CartaIdx].MarcaVisual.TextSettings.Font.Style := [TFontStyle.fsBold];
  Cartas[CartaIdx].MarcaVisual.TextSettings.FontColor := TAlphaColors.White;

  Cartas[CartaIdx].MarcaFondo.BringToFront;
end;

procedure TCerebroMemorama.MostrarMarcaGanador(CartaIdx, Duenio: Integer);
var
  Nombre: string;
begin
  if (CartaIdx < 0) or (CartaIdx > High(Cartas)) then
    Exit;

  if not Assigned(Cartas[CartaIdx].MarcaFondo) then
    Exit;

  if not Assigned(Cartas[CartaIdx].MarcaVisual) then
    Exit;

  Cartas[CartaIdx].DuenioPar := Duenio;

  if Duenio = 1 then
  begin
    Nombre := NombreJ1;

    // Azul para jugador 1
    Cartas[CartaIdx].MarcaFondo.Fill.Color := TAlphaColors.Dodgerblue;
    Cartas[CartaIdx].MarcaFondo.Stroke.Color := TAlphaColors.White;
  end
  else if Duenio = 2 then
  begin
    Nombre := NombreJ2;

    // Rojo para jugador 2
    Cartas[CartaIdx].MarcaFondo.Fill.Color := TAlphaColors.Crimson;
    Cartas[CartaIdx].MarcaFondo.Stroke.Color := TAlphaColors.White;
  end
  else
  begin
    Nombre := '';
  end;

  if Nombre.Trim <> '' then
  begin
    Cartas[CartaIdx].MarcaVisual.Text := '✓ ' + Nombre;
    Cartas[CartaIdx].MarcaFondo.Visible := True;
    Cartas[CartaIdx].MarcaFondo.BringToFront;
  end
  else
  begin
    Cartas[CartaIdx].MarcaVisual.Text := '';
    Cartas[CartaIdx].MarcaFondo.Visible := False;
  end;
end;

procedure TCerebroMemorama.AplicarParEncontrado(CartaIdx, Duenio: Integer);
begin
  if (CartaIdx < 0) or (CartaIdx > High(Cartas)) then
    Exit;

  Cartas[CartaIdx].Encontrada := True;
  Cartas[CartaIdx].Volteada := True;
  Cartas[CartaIdx].DuenioPar := Duenio;

  if Assigned(Cartas[CartaIdx].BotonVisual) then
    Cartas[CartaIdx].BotonVisual.Opacity := 0.5;

  MostrarMarcaGanador(CartaIdx, Duenio);
end;

function TCerebroMemorama.ObtenerEncontradasCSV: string;
var
  J: Integer;
begin
  Result := '';

  for J := 0 to High(Cartas) do
  begin
    if Cartas[J].Encontrada then
      Result := Result + J.ToString + ',';
  end;
end;

function TCerebroMemorama.ObtenerDuenosParesCSV: string;
var
  J: Integer;
begin
  Result := '';

  for J := 0 to High(Cartas) do
  begin
    if Cartas[J].Encontrada and (Cartas[J].DuenioPar > 0) then
      Result := Result + J.ToString + ':' + Cartas[J].DuenioPar.ToString + ',';
  end;
end;

procedure TCerebroMemorama.IniciarJuego(TextoCantCartas: String; ContenedorVisual: TLayout;
  ListaImagenes: TCustomImageList; J1, J2: String);
var
  TotalCartas, Cols, Filas, I, C, F: Integer;
  Margen, AnchoCarta, AltoCarta: Single;
begin
  NombreJ1 := J1;

  if EsModoLocal and (J2.Trim = '') then
    NombreJ2 := 'Jugador 2'
  else
    NombreJ2 := J2;

  FTablero := ContenedorVisual;
  FListaImagenes := ListaImagenes;
  FTablero.DeleteChildren;

  TotalCartas := StrToIntDef(TextoCantCartas, 8);
  ParesTotales := TotalCartas div 2;

  Turno := 1;
  PtsJ1 := 0;
  PtsJ2 := 0;

  FPrimerCarta := -1;
  FSegundaCarta := -1;
  JuegoTerminado := False;

  if Assigned(OnActualizarUI) then
    OnActualizarUI(PtsJ1, PtsJ2, Turno);

  GenerarYRevolverCartas(TotalCartas);
  CalcularGrid(TotalCartas, Cols, Filas);

  Margen := 10;
  AnchoCarta := (FTablero.Width - (Margen * (Cols + 1))) / Cols;
  AltoCarta := (FTablero.Height - (Margen * (Filas + 1))) / Filas;

  for I := 0 to TotalCartas - 1 do
  begin
    F := I div Cols;
    C := I mod Cols;

    Cartas[I].BotonVisual := TImage.Create(FTablero);
    Cartas[I].BotonVisual.Parent := FTablero;

    Cartas[I].BotonVisual.Width := AnchoCarta;
    Cartas[I].BotonVisual.Height := AltoCarta;
    Cartas[I].BotonVisual.Position.X := Margen + (C * (AnchoCarta + Margen));
    Cartas[I].BotonVisual.Position.Y := Margen + (F * (AltoCarta + Margen));

    Cartas[I].BotonVisual.Tag := I;
    Cartas[I].BotonVisual.WrapMode := TImageWrapMode.Stretch;
    Cartas[I].BotonVisual.Opacity := 1;

    MostrarImagen(I, 0);

    CrearMarcaCarta(I);

    Cartas[I].BotonVisual.OnClick := CartaClickeada;
  end;
end;

procedure TCerebroMemorama.MostrarImagen(CartaIdx, ImgIndex: Integer);
begin
  if not Assigned(FListaImagenes) then
    Exit;

  if ImgIndex >= FListaImagenes.Source.Count then
    Exit;

  Cartas[CartaIdx].BotonVisual.Bitmap.Assign(
    FListaImagenes.Source.Items[ImgIndex].MultiResBitmap.Items[0].Bitmap
  );
end;

procedure TCerebroMemorama.GenerarYRevolverCartas(TotalCartas: Integer);
var
  I, RndIdx: Integer;
  Temp: TCartaLogica;
begin
  SetLength(Cartas, TotalCartas);

  for I := 0 to TotalCartas - 1 do
  begin
    Cartas[I].IDPareja := I div 2;
    Cartas[I].Volteada := False;
    Cartas[I].Encontrada := False;
    Cartas[I].DuenioPar := 0;
    Cartas[I].BotonVisual := nil;
    Cartas[I].MarcaFondo := nil;
    Cartas[I].MarcaVisual := nil;
  end;

  Randomize;

  for I := TotalCartas - 1 downto 1 do
  begin
    RndIdx := Random(I + 1);
    Temp := Cartas[I];
    Cartas[I] := Cartas[RndIdx];
    Cartas[RndIdx] := Temp;
  end;
end;

procedure TCerebroMemorama.VerificarFinDeJuego;
var
  MsgText: string;
  Diferencia: Integer;
begin
  if JuegoTerminado or ((PtsJ1 + PtsJ2) <> ParesTotales) then
    Exit;

  JuegoTerminado := True;
  Diferencia := Abs(PtsJ1 - PtsJ2);

  if PtsJ1 > PtsJ2 then
  begin
    MsgText := '🌟🏆 ¡VICTORIA ABSOLUTA! 🏆🌟' + #13#10 +
               '──────────────────────────────' + #13#10 +
               '¡Felicidades! El jugador ' + NombreJ1 + ' ha ganado la partida.' + #13#10#13#10 +
               '📊 MARCADOR FINAL:' + #13#10 +
               '   👑 ' + NombreJ1 + ': ' + PtsJ1.ToString + ' puntos' + #13#10 +
               '   👤 ' + NombreJ2 + ': ' + PtsJ2.ToString + ' puntos' + #13#10#13#10 +
               '✨ Se corona ganador por una ventaja de ' + Diferencia.ToString + ' punto(s).' + #13#10#13#10 +
               '¡Gracias por jugar Memorama! 🎉';

    TDialogService.ShowMessage(MsgText);
  end
  else if PtsJ2 > PtsJ1 then
  begin
    MsgText := '🌟🏆 ¡VICTORIA ABSOLUTA! 🏆🌟' + #13#10 +
               '──────────────────────────────' + #13#10 +
               '¡Felicidades! El jugador ' + NombreJ2 + ' ha ganado la partida.' + #13#10#13#10 +
               '📊 MARCADOR FINAL:' + #13#10 +
               '   👤 ' + NombreJ1 + ': ' + PtsJ1.ToString + ' puntos' + #13#10 +
               '   👑 ' + NombreJ2 + ': ' + PtsJ2.ToString + ' puntos' + #13#10#13#10 +
               '✨ Se corona ganador por una ventaja de ' + Diferencia.ToString + ' punto(s).' + #13#10#13#10 +
               '¡Gracias por jugar Memorama! 🎉';

    TDialogService.ShowMessage(MsgText);
  end
  else
  begin
    MsgText := '🤝 ¡UN EMPATE LEGENDARIO! 🤝' + #13#10 +
               '──────────────────────────────' + #13#10 +
               '¡Ambos competidores demostraron una memoria implacable!' + #13#10#13#10 +
               '📊 MARCADOR FINAL:' + #13#10 +
               '   👤 ' + NombreJ1 + ': ' + PtsJ1.ToString + ' puntos' + #13#10 +
               '   👤 ' + NombreJ2 + ': ' + PtsJ2.ToString + ' puntos' + #13#10#13#10 +
               '✨ ¡Es un empate exacto con ' + PtsJ1.ToString + ' puntos cada uno!' + #13#10#13#10 +
               '¿Quién se anima a la revancha? 🔄🎉';

    TDialogService.ShowMessage(MsgText);
  end;
end;

procedure TCerebroMemorama.CartaClickeada(Sender: TObject);
var
  Idx, CantidadCaras, ImgIndex: Integer;
  StrEnc, StrDuenos: string;
  UltimoParEncontrado: Boolean;
begin
  if FTimerEspera.Enabled then
    Exit;

  if EsModoLocal = False then
  begin
    if Turno <> MiRol then
      Exit;
  end;

  Idx := TImage(Sender).Tag;

  if Cartas[Idx].Encontrada or Cartas[Idx].Volteada then
    Exit;

  Cartas[Idx].Volteada := True;

  CantidadCaras := FListaImagenes.Source.Count - 1;

  if CantidadCaras > 0 then
    ImgIndex := (Cartas[Idx].IDPareja mod CantidadCaras) + 1
  else
    ImgIndex := 0;

  MostrarImagen(Idx, ImgIndex);

  UltimoParEncontrado := False;

  if FPrimerCarta = -1 then
  begin
    FPrimerCarta := Idx;
  end
  else
  begin
    FSegundaCarta := Idx;

    if Cartas[FPrimerCarta].IDPareja = Cartas[FSegundaCarta].IDPareja then
    begin
      AplicarParEncontrado(FPrimerCarta, Turno);
      AplicarParEncontrado(FSegundaCarta, Turno);

      if Turno = 1 then
        Inc(PtsJ1)
      else
        Inc(PtsJ2);

      if Assigned(OnActualizarUI) then
        OnActualizarUI(PtsJ1, PtsJ2, Turno);

      UltimoParEncontrado := True;
    end
    else
    begin
      if Turno = 1 then
        Turno := 2
      else
        Turno := 1;

      if Assigned(OnActualizarUI) then
        OnActualizarUI(PtsJ1, PtsJ2, Turno);

      FTimerEspera.Enabled := True;
    end;
  end;

  if not EsModoLocal then
  begin
    StrEnc := ObtenerEncontradasCSV;
    StrDuenos := ObtenerDuenosParesCSV;

    if Assigned(dmFirebase) then
      dmFirebase.ActualizarEstadoNube(
        Turno,
        PtsJ1,
        PtsJ2,
        FPrimerCarta,
        FSegundaCarta,
        StrEnc,
        StrDuenos
      );
  end;

  if UltimoParEncontrado then
  begin
    FPrimerCarta := -1;
    FSegundaCarta := -1;
    VerificarFinDeJuego;
  end;
end;

procedure TCerebroMemorama.TimerEsperaTick(Sender: TObject);
var
  StrEnc, StrDuenos: string;
begin
  FTimerEspera.Enabled := False;

  Cartas[FPrimerCarta].Volteada := False;
  MostrarImagen(FPrimerCarta, 0);

  Cartas[FSegundaCarta].Volteada := False;
  MostrarImagen(FSegundaCarta, 0);

  FPrimerCarta := -1;
  FSegundaCarta := -1;

  if not EsModoLocal then
  begin
    StrEnc := ObtenerEncontradasCSV;
    StrDuenos := ObtenerDuenosParesCSV;

    if Assigned(dmFirebase) then
      dmFirebase.ActualizarEstadoNube(
        Turno,
        PtsJ1,
        PtsJ2,
        FPrimerCarta,
        FSegundaCarta,
        StrEnc,
        StrDuenos
      );
  end;
end;

initialization
  Cerebro := TCerebroMemorama.Create;

finalization
  Cerebro.Free;

end.
