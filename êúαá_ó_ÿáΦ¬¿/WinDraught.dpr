program WinDraught;

uses
  Forms,
  MainUnit in 'MainUnit.pas' {MainForm},
  GameLogic in 'GameLogic.pas',
  PosFrame in 'PosFrame.pas' {PositionFrame: TFrame},
  GameTactics in 'GameTactics.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
