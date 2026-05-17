program Memorama;

uses
  System.StartUpCopy,
  FMX.Forms,
  uMain in 'uMain.pas' {Form1},
  uData in 'uData.pas'; // <-- También limpiamos el comentario del DataModule que estaba aquí

{$R *.res}

begin
  Application.Initialize;
  Application.FormFactor.Orientations := [TFormOrientation.Landscape, TFormOrientation.InvertedLandscape];
  Application.CreateForm(TForm1, Form1);
  // Eliminamos la línea del DataModule1 que daba el error E2003
  Application.Run;
end.
