unit uData;

interface

uses
  System.SysUtils, System.Classes, System.Math, FMX.Types, FMX.Layouts,
  FMX.Objects, FMX.Dialogs, System.UIConsts, System.UITypes,
  System.Types, FMX.ImgList, FMX.Graphics, FMX.ListBox,
  System.IOUtils; // Para manejo de carpetas y archivos

type
  TCartaLogica = record
    IDPareja: Integer;
    Volteada: Boolean;
    Encontrada: Boolean;
    BotonVisual: TImage;
  end;

  TActualizarUIEvent = procedure(PtsJ1, PtsJ2, TurnoActual: Integer) of object;

  TCerebroMemorama = class
  private
    FTablero: TLayout;
    FListaImagenes: TCustomImageList;
    FPrimerCarta, FSegundaCarta: Integer;
    FTimerEspera: TTimer;

    procedure GenerarYRevolverCartas(TotalCartas: Integer);
    procedure CartaClickeada(Sender: TObject);
    procedure TimerEsperaTick(Sender: TObject);
    procedure MostrarImagen(CartaIdx, ImgIndex: Integer);
    procedure CalcularGrid(Total: Integer; out Cols, Filas: Integer);

  public
    Cartas: array of TCartaLogica;
    ParesTotales: Integer;
    Turno: Integer;
    PtsJ1, PtsJ2: Integer;
    NombreJ1, NombreJ2: String;
    OnActualizarUI: TActualizarUIEvent;

    constructor Create;
    destructor Destroy; override;

    procedure ConfigurarOpcionesCartas(AComboBox: TComboBox);
    procedure ListarTemas(AComboBox: TComboBox);
    procedure CargarImagenesDeCarpeta(NombreTema: String; AImageList: TImageList);

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

{ TCerebroMemorama }

constructor TCerebroMemorama.Create;
begin
  FTimerEspera := TTimer.Create(nil);
  FTimerEspera.Enabled := False;
  FTimerEspera.Interval := 800;
  FTimerEspera.OnTimer := TimerEsperaTick;
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

    if AComboBox.Items.Count > 0 then AComboBox.ItemIndex := 0;
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

  if not TDirectory.Exists(RutaTema) then Exit;

  Archivos := TDirectory.GetFiles(RutaTema, '*.png');
  RutaReverso := '';
  ListaCaras := TStringList.Create;

  try
    // CORRECCIÓN MÓVIL: Separación estricta de archivos usando SameText (ignora mayúsculas/minúsculas)
    for Archivo in Archivos do
    begin
      NombreArchivo := TPath.GetFileName(Archivo);
      if SameText(NombreArchivo, 'reverso.png') then
        RutaReverso := Archivo
      else
        ListaCaras.Add(Archivo);
    end;

    // 1. El reverso se guarda OBLIGATORIAMENTE en el índice 0 del ImageList
    if RutaReverso <> '' then
    begin
      SourceItem := AImageList.Source.Add;
      SourceItem.MultiResBitmap.Add.Bitmap.LoadFromFile(RutaReverso);
    end;

    // 2. Se cargan las caras de las cartas consecutivamente (índices 1, 2, 3...)
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
  while (Total mod Cols <> 0) do Inc(Cols);
  Filas := Total div Cols;

  if (FTablero.Width > FTablero.Height) and (Filas > Cols) then
  begin
    Total := Cols; Cols := Filas; Filas := Total;
  end;
end;

procedure TCerebroMemorama.IniciarJuego(TextoCantCartas: String; ContenedorVisual: TLayout;
  ListaImagenes: TCustomImageList; J1, J2: String);
var
  TotalCartas, Cols, Filas, I, C, F: Integer;
  Margen, AnchoCarta, AltoCarta: Single;
begin
  NombreJ1 := J1; NombreJ2 := J2;
  FTablero := ContenedorVisual;
  FListaImagenes := ListaImagenes;
  FTablero.DeleteChildren;

  TotalCartas := StrToIntDef(TextoCantCartas, 8);
  ParesTotales := TotalCartas div 2;
  Turno := 1; PtsJ1 := 0; PtsJ2 := 0;
  FPrimerCarta := -1; FSegundaCarta := -1;

  if Assigned(OnActualizarUI) then OnActualizarUI(PtsJ1, PtsJ2, Turno);

  GenerarYRevolverCartas(TotalCartas);
  CalcularGrid(TotalCartas, Cols, Filas);

  Margen := 10;
  AnchoCarta := (FTablero.Width - (Margen * (Cols + 1))) / Cols;
  AltoCarta := (FTablero.Height - (Margen * (Filas + 1))) / Filas;

  for I := 0 to TotalCartas - 1 do
  begin
    F := I div Cols; C := I mod Cols;

    Cartas[I].BotonVisual := TImage.Create(FTablero);
    Cartas[I].BotonVisual.Parent := FTablero;

    Cartas[I].BotonVisual.Width := AnchoCarta;
    Cartas[I].BotonVisual.Height := AltoCarta;
    Cartas[I].BotonVisual.Position.X := Margen + (C * (AnchoCarta + Margen));
    Cartas[I].BotonVisual.Position.Y := Margen + (F * (AltoCarta + Margen));

    Cartas[I].BotonVisual.Tag := I;
    Cartas[I].BotonVisual.WrapMode := TImageWrapMode.Stretch;

    MostrarImagen(I, 0); // Muestra el índice 0 (reverso aislado)
    Cartas[I].BotonVisual.OnClick := CartaClickeada;
  end;
end;

procedure TCerebroMemorama.MostrarImagen(CartaIdx, ImgIndex: Integer);
begin
  if not Assigned(FListaImagenes) or (ImgIndex >= FListaImagenes.Source.Count) then Exit;

  Cartas[CartaIdx].BotonVisual.Bitmap.Assign(
    FListaImagenes.Source.Items[ImgIndex].MultiResBitmap.Items[0].Bitmap
  );
end;

procedure TCerebroMemorama.GenerarYRevolverCartas(TotalCartas: Integer);
var I, RndIdx: Integer; Temp: TCartaLogica;
begin
  SetLength(Cartas, TotalCartas);
  for I := 0 to TotalCartas - 1 do
  begin
    Cartas[I].IDPareja := I div 2;
    Cartas[I].Volteada := False;
    Cartas[I].Encontrada := False;
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

procedure TCerebroMemorama.CartaClickeada(Sender: TObject);
var
  Idx, CantidadCaras, ImgIndex: Integer;
begin
  if FTimerEspera.Enabled then Exit;
  Idx := TImage(Sender).Tag;

  if Cartas[Idx].Encontrada or Cartas[Idx].Volteada then Exit;

  Cartas[Idx].Volteada := True;

  // CORRECCIÓN MATEMÁTICA: Usamos MOD para reciclar imágenes si faltan archivos en la carpeta
  CantidadCaras := FListaImagenes.Source.Count - 1;
  if CantidadCaras > 0 then
    ImgIndex := (Cartas[Idx].IDPareja mod CantidadCaras) + 1
  else
    ImgIndex := 0;

  MostrarImagen(Idx, ImgIndex);

  if FPrimerCarta = -1 then
    FPrimerCarta := Idx
  else
  begin
    FSegundaCarta := Idx;
    if Cartas[FPrimerCarta].IDPareja = Cartas[FSegundaCarta].IDPareja then
    begin
      Cartas[FPrimerCarta].Encontrada := True;
      Cartas[FSegundaCarta].Encontrada := True;
      Cartas[FPrimerCarta].BotonVisual.Opacity := 0.5;
      Cartas[FSegundaCarta].BotonVisual.Opacity := 0.5;

      if Turno = 1 then Inc(PtsJ1) else Inc(PtsJ2);

      FPrimerCarta := -1; FSegundaCarta := -1;
      if Assigned(OnActualizarUI) then OnActualizarUI(PtsJ1, PtsJ2, Turno);

      if (PtsJ1 + PtsJ2) = ParesTotales then
        ShowMessage('¡Juego Terminado! ' + NombreJ1 + ': ' + PtsJ1.ToString + ' vs ' + NombreJ2 + ': ' + PtsJ2.ToString);
    end
    else
    begin
      Turno := IfThen(Turno = 1, 2, 1);
      if Assigned(OnActualizarUI) then OnActualizarUI(PtsJ1, PtsJ2, Turno);
      FTimerEspera.Enabled := True;
    end;
  end;
end;

procedure TCerebroMemorama.TimerEsperaTick(Sender: TObject);
begin
  FTimerEspera.Enabled := False;
  Cartas[FPrimerCarta].Volteada := False;
  MostrarImagen(FPrimerCarta, 0);
  Cartas[FSegundaCarta].Volteada := False;
  MostrarImagen(FSegundaCarta, 0);
  FPrimerCarta := -1; FSegundaCarta := -1;
end;

initialization
  Cerebro := TCerebroMemorama.Create;

finalization
  Cerebro.Free;

end.
