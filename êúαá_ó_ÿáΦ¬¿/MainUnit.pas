unit MainUnit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  PosFrame, StdCtrls, GameLogic, Menus, ComCtrls, Clipbrd, ActnList;

const
  MM_DOMOVE = WM_USER + 1;
  MM_DEBUG = WM_USER + 2;
  MM_IS_ANIMATION = WM_USER + 3;

type
  TMode = (mdMachineWhite, mdMachineBlack, mdTwoMachine, mdView);

  TGameHistory = class
  private
    function GetPartyView: TListView;
    function GetPositionFrame: TPositionFrame;
  private
    FPositions: array[0..255] of TPosition;
    FMoveNo: Integer;
    procedure AddBlackMove(const Move: string);
    procedure AddWhiteMove(const Move: string);
    property PositionFrame: TPositionFrame read GetPositionFrame;
    property PartyView: TListView read GetPartyView;
  public
    procedure NewGame;
    procedure AddMove(NewPosition: TPosition);
    procedure Undo;
    property MoveNo: Integer read FMoveNo write FMoveNo;
  end;

  TMainForm = class(TForm)
    PositionFrame: TPositionFrame;
    Memo: TMemo;
    MainMenu: TMainMenu;
    GameMenu: TMenuItem;
    NewItem: TMenuItem;
    Separator1: TMenuItem;
    BeginerItem: TMenuItem;
    IntermediateItem: TMenuItem;
    ExpertItem: TMenuItem;
    Separator2: TMenuItem;
    ExitItem: TMenuItem;
    ModeMenu: TMenuItem;
    MachineWhiteItem: TMenuItem;
    MachineBlackItem: TMenuItem;
    TwoMachineItem: TMenuItem;
    ViewItem: TMenuItem;
    Separator3: TMenuItem;
    FlipBoardItem: TMenuItem;
    PartyView: TListView;
    DebugMenu: TMenuItem;
    SetPositionItem: TMenuItem;
    AddToLibraryItem: TMenuItem;
    CopyGameItem: TMenuItem;
    Separator4: TMenuItem;
    UndoMoveItem: TMenuItem;
    ActionList: TActionList;
    NewGameAction: TAction;
    BeginerAction: TAction;
    IntermediateAction: TAction;
    ExpertAction: TAction;
    UndoMoveAction: TAction;
    ExitAction: TAction;
    MachineWhiteAction: TAction;
    MachineBlackAction: TAction;
    TwoMachineAction: TAction;
    ViewGameAction: TAction;
    FlipBoardAction: TAction;
    SetPositionAction: TAction;
    AddToLibraryAction: TAction;
    CopyGameAction: TAction;
    procedure FormShow(Sender: TObject);
    procedure SelectCellBtnClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure UndoMoveItemClick(Sender: TObject);
    procedure NewGameActionExecute(Sender: TObject);
    procedure LevelActionExecute(Sender: TObject);
    procedure UndoMoveActionExecute(Sender: TObject);
    procedure ActionListUpdate(Action: TBasicAction; var Handled: Boolean);
    procedure ExitActionExecute(Sender: TObject);
    procedure MachineWhiteActionExecute(Sender: TObject);
    procedure MachineBlackActionExecute(Sender: TObject);
    procedure TwoMachineActionExecute(Sender: TObject);
    procedure ViewGameActionExecute(Sender: TObject);
    procedure FlipBoardActionExecute(Sender: TObject);
    procedure SetPositionActionExecute(Sender: TObject);
    procedure AddToLibraryActionExecute(Sender: TObject);
    procedure CopyGameActionExecute(Sender: TObject);
  private
    FDeep: Integer;
    FGameHistory: TGameHistory;
    FMode: TMode;
    FThreadHandle: THandle;
    procedure AcceptMove(Sender: TObject; const NewPosition: TPosition);
    procedure TuneState;
    procedure StopThinking;
    procedure DoMove(var Message: TMessage); message MM_DOMOVE;
    procedure DoDebug(var Message: TMessage); message MM_DEBUG;
    procedure IsAnimation(var Message: TMessage); message MM_IS_ANIMATION;
    property Mode: TMode read FMode;
    property Deep: Integer read FDeep write FDeep;
    property ThreadHandle: THandle read FThreadHandle write FThreadHandle;
    property GameHistory: TGameHistory read FGameHistory write FGameHistory;
    procedure Deselect(Action: TAction; const Category: string);
  end;

var
  MainForm: TMainForm;

implementation

uses GameTactics;

{$R *.DFM}

function Thinker(APosition: Pointer): Integer;
var
  Position: TPosition;
  Estimate: Integer;
begin
  Position := TPosition(APosition^);
  SelectMove(Position, MainForm.Deep, Estimate);
  SendMessage(MainForm.Handle, MM_DOMOVE, Integer(@Position), Estimate);
  Result := 0;
end;

procedure TMainForm.FormShow(Sender: TObject);
var
  Position: TPosition;
begin
  LoadLib;
  Position := StartBoard;
  PositionFrame.Debug := Memo.Lines;
  PositionFrame.OnAcceptMove := AcceptMove;
  NewGameAction.Execute;
  BeginerAction.Execute;
  MachineBlackAction.Execute;
end;

procedure TMainForm.SelectCellBtnClick(Sender: TObject);
begin
  PositionFrame.SelectCell(1, 6);
end;

procedure TMainForm.AcceptMove(Sender: TObject; const NewPosition: TPosition);
var
  St: string;
begin
  GameHistory.AddMove(NewPosition);
  PositionFrame.SetPosition(NewPosition);
  St := GameOver(NewPosition);
  if St <> '' then
  begin
    ShowMessage(St);
    PositionFrame.AcceptMove := False;
    Exit;
  end;
  TuneState;
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  PositionFrame.Left := 3;
  PositionFrame.Top := 3;
  Memo.Left := 3;
  Memo.Top := PositionFrame.Top + PositionFrame.Height + 3;
  Memo.Width := ClientWidth - 6;
  Memo.Height := ClientHeight - PositionFrame.Height - 9;
  PartyView.Left := PositionFrame.Left + PositionFrame.Width + 3;
  PartyView.Width := ClientWidth - PositionFrame.Width - 9;
  PartyView.Top := 3;
  PartyView.Height := PositionFrame.Height;
  PartyView.Columns[0].Width := 30;
  PartyView.Columns[1].Width := (PartyView.Width - 40) div 2;
  PartyView.Columns[2].Width := (PartyView.Width - 40) div 2;
end;

procedure TMainForm.DoMove(var Message: TMessage);
var
  NewPosition: TPosition;
begin
  NewPosition := TPosition(Pointer(Message.WParam)^);
  CloseHandle(ThreadHandle);
  ThreadHandle := 0;
  AcceptMove(nil, NewPosition);
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FMode := mdMachineBlack;
  Memo.Clear;
  DoubleBuffered := True;
  FGameHistory := TGameHistory.Create;
end;

procedure TMainForm.TuneState;
var
  RunThinker: Boolean;
  ThreadId: Cardinal;
  Index: Integer;
  V: Integer;
begin
  if ThreadHandle <> 0 then StopThinking;
  PositionFrame.AcceptMove := (Mode = mdView)
    or ((Mode = mdMachineWhite) and (PositionFrame.Position.Active = ActiveBlack))
    or ((Mode = mdMachineBlack) and (PositionFrame.Position.Active = ActiveWhite));
  RunThinker := (Mode = mdTwoMachine)
    or ((Mode = mdMachineWhite) and (PositionFrame.Position.Active = ActiveWhite))
    or ((Mode = mdMachineBlack) and (PositionFrame.Position.Active = ActiveBlack));
  if DebugMenu.Visible then
  begin
    Index := Lib.IndexOf(FormatPosition(PositionFrame.Position));
    if Index <> -1 then
    begin
      V := Integer(Lib.Objects[Index]);
      Memo.Lines.Add(Format('Theory = %.3f', [V/200]));
    end;
  end;
  if not RunThinker then Exit;
  ThreadHandle := BeginThread(nil, 8*4096, @Thinker, @PositionFrame.Position, CREATE_SUSPENDED, ThreadId);
  SetThreadPriority(ThreadHandle, THREAD_PRIORITY_BELOW_NORMAL);
  ResumeThread(ThreadHandle);
end;

procedure TMainForm.DoDebug(var Message: TMessage);
var
  Position: PPosition;
begin
  if not DebugMenu.Visible then Exit;
  if Message.WPAram = 0 then
  begin
    Memo.Clear;
    Exit;
  end;

  Position := Pointer(Message.WPAram);
  Memo.Lines.Add(Format('E=%d N=%.3f M=%s',
    [Message.LParam, Message.LParam/200, GetLastMove(Position^)]));
end;

procedure TMainForm.IsAnimation(var Message: TMessage);
begin
  if PositionFrame.Animate
    then Message.Result := 1
    else Message.Result := 0 
end;

const
  MAX_LEN = 60;

procedure TMainForm.StopThinking;
begin
  TerminateThread(ThreadHandle, 0);
  CloseHandle(ThreadHandle);
  ThreadHandle := 0;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FGameHistory);
end;

procedure TMainForm.UndoMoveItemClick(Sender: TObject);
begin
end;

{ TGameHistory }

procedure TGameHistory.AddWhiteMove(const Move: string);
var
  NewItem: TListItem;
begin
  NewItem := PartyView.Items.Add;
  NewItem.Caption := IntToStr((MoveNo div 2) + 1);
  NewItem.Subitems.Add(Move);
  PartyView.Selected := NewItem;
  PartyView.Selected.MakeVisible(False);
end;

procedure TGameHistory.AddBlackMove(const Move: string);
var
  Item: TListItem;
begin
  Assert(MainForm.PartyView.Items.Count > 0);
  Item := PartyView.Items[PartyView.Items.Count-1];
  Item.Subitems.Add(Move);
  PartyView.Selected := Item;
  PartyView.Selected.MakeVisible(False);
end;

procedure TGameHistory.AddMove(NewPosition: TPosition);
var
  Move: string;
begin
  Move := GetLastMove(NewPosition);
  if Move <> '' then
    if FPositions[MoveNo].Active = ActiveWhite
      then AddWhiteMove(Move)
      else AddBlackMove(Move);
  MoveNo := MoveNo + 1;
  FPositions[MoveNo] := NewPosition;
end;

procedure TGameHistory.NewGame;
begin
  MoveNo := 0;
  PartyView.Items.Clear;
  FPositions[0] := StartBoard;
  PositionFrame.SetPosition(StartBoard);
end;

function TGameHistory.GetPartyView: TListView;
begin
  Result := MainForm.PartyView;
end;

function TGameHistory.GetPositionFrame: TPositionFrame;
begin
  Result := MainForm.PositionFrame;
end;

procedure TGameHistory.Undo;
var
  Last: Integer;
  Item: TListItem;
begin
  Assert(MoveNo > 0);
  MainForm.ViewItem.Click;
  MoveNo := MoveNo - 1;
  PositionFrame.SetPosition(FPositions[MoveNo], False);
  Last := PartyView.Items.Count-1;
  Assert(Last >= 0);
  Item := PartyView.Items[Last];
  if Item.SubItems.Count > 1
    then Item.SubItems.Delete(1)
    else PartyView.Items.Delete(Last);
end;

procedure TMainForm.NewGameActionExecute(Sender: TObject);
begin
  StopThinking;
  GameHistory.NewGame;
  if Mode in [mdMachineWhite, mdTwoMachine] then MachineBlackItem.Click;
  PositionFrame.AcceptMove := True;
end;

procedure TMainForm.Deselect(Action: TAction; const Category: string);
var
  I: Integer;
begin
  for I := 0 to ActionList.ActionCount - 1 do
  begin
    if ActionList.Actions[I].Category <> Category then Continue;
    if ActionList.Actions[I] = Action then Continue;
    (ActionList.Actions[I] as TAction).Checked := False;
  end;
end;

procedure TMainForm.LevelActionExecute(Sender: TObject);
begin
  Deselect(Sender as TAction, 'Level');
  with Sender as TAction do
  begin
    Checked := True;
    Deep := Tag;
  end;
end;

procedure TMainForm.UndoMoveActionExecute(Sender: TObject);
begin
  GameHistory.Undo;
end;

procedure TMainForm.ActionListUpdate(Action: TBasicAction;
  var Handled: Boolean);
begin
  UndoMoveAction.Enabled := GameHistory.MoveNo > 0;
end;

procedure TMainForm.ExitActionExecute(Sender: TObject);
begin
  ViewItem.Click;
  Close;
end;

procedure TMainForm.MachineWhiteActionExecute(Sender: TObject);
begin
  Deselect(Sender as TAction, 'Mode');
  (Sender as TAction).Checked := True;
  if Mode = mdMachineWhite then Exit;
  FMode := mdMachineWhite;
  PositionFrame.FlipBoard := True;
  TuneState;
end;

procedure TMainForm.MachineBlackActionExecute(Sender: TObject);
begin
  Deselect(Sender as TAction, 'Mode');
  (Sender as TAction).Checked := True;
  if Mode = mdMachineBlack then Exit;
  FMode := mdMachineBlack;
  PositionFrame.FlipBoard := False;
  TuneState;
end;

procedure TMainForm.TwoMachineActionExecute(Sender: TObject);
begin
  Deselect(Sender as TAction, 'Mode');
  (Sender as TAction).Checked := True;
  if Mode = mdTwoMachine then Exit;
  FMode := mdTwoMachine;
  TuneState;
end;

procedure TMainForm.ViewGameActionExecute(Sender: TObject);
begin
  Deselect(Sender as TAction, 'Mode');
  (Sender as TAction).Checked := True;
  if Mode = mdView then Exit;
  FMode := mdView;
  ViewItem.Checked := True;
  if ThreadHandle <> 0 then StopThinking;
end;

procedure TMainForm.FlipBoardActionExecute(Sender: TObject);
begin
  PositionFrame.FlipBoard := not PositionFrame.FlipBoard;
end;

procedure TMainForm.SetPositionActionExecute(Sender: TObject);
var
  Position: TPosition;
begin
  ViewItem.Click;
  FillChar(Position.Field, 32, $00);
  Position.Field[31] := -20;
  Position.Field[29] := 70;
  Position.Active := ActiveWhite;
//  Position.Field[0] := 20;
//  Position.Field[2] := -70;
//  Position.Active := ActiveBlack;
  Position.MoveCount := 0;
  PositionFrame.SetPosition(Position);
end;

procedure TMainForm.AddToLibraryActionExecute(Sender: TObject);
var
  V: Integer;
  Estimate: string;
  PositionFmt: string;
  Index: Integer;
begin
  DecimalSeparator := '.';
  Estimate := InputBox('Input', 'Please, enter estimate', '');
  if Estimate = '' then Exit;
  Estimate := StringReplace(Estimate, ',', '.', []);
  V := Round(200 * StrToFloat(Estimate));
  PositionFmt := FormatPosition(PositionFrame.Position);
  Index := Lib.IndexOf(PositionFmt);
  if Index = -1 then
    Lib.AddObject(PositionFmt, TObject(V))
  else begin
    Lib.Sorted := False;
    Lib[Index] := PositionFmt;
    Lib.Objects[Index] := TObject(V);
    Lib.Sorted := True;
  end;
  SaveLib;
end;

procedure TMainForm.CopyGameActionExecute(Sender: TObject);
var
  MoveNo: Integer;
  Item: TListItem;
  CurrentSt: string;
  AllParty: TStringList;

procedure Add(const St: string);
begin
  if Length(CurrentSt) + Length(St) + 1 > MAX_LEN then
  begin
    AllParty.Add(CurrentSt);
    CurrentSt := '';
  end;
  if CurrentSt <> '' then CurrentSt := CurrentSt + ' ';
  CurrentSt := CurrentSt + St;
end;

begin
  AllParty := TStringList.Create;
  try
    CurrentSt := '';
    for MoveNo := 0 to PartyView.Items.Count-1 do
    begin
      Item := PartyView.Items[MoveNo];
      Add(Item.Caption + '.');
      Add(Item.SubItems[0]);
      if Item.SubItems.Count > 1 then
        Add(Item.SubItems[1]);
    end;
    if CurrentSt <> '' then AllParty.Add(CurrentSt);
    Clipboard.AsText := AllParty.Text;
  finally
    AllParty.Free;
  end;
end;

end.
