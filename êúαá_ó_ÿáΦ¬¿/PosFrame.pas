unit PosFrame;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, GameLogic, ImgList;

const
  ANSWERS_SIZE = 128;
  ANSWERS_LIMIT = ANSWERS_SIZE - 1;

  ANIMATE_SUBSTEP_COUNT = 4;

type
  TAcceptMoveEvent = procedure (Sender: TObject; const NewPosition: TPosition) of object;

  TPositionFrame = class(TFrame)
    ImageList: TImageList;
    Image: TImage;
    Timer: TTimer;
    TransparentImages: TImageList;
    procedure ImageMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure TimerTimer(Sender: TObject);
  private
    FPosition: TPosition;
    FSelectedCells: array[0..31] of Boolean;
    FAnswers: array[0..ANSWERS_LIMIT] of TPosition;
    FAnswersCount: Integer;
    FEnabledAnswer: array[0..ANSWERS_LIMIT] of Integer;
    FUserSelect: array[0..12] of Integer;
    FAnimatePosition: TPosition;
    FAnimateWay: array[0..63] of Integer;
    FAnimateStep: Integer;
    FAnimateSubStep: Integer;
    FAnimateObject: Integer;
    FUserSelectCount: Integer;
    FFlipBoard: Boolean;
    FSelected: Integer;
    FOnAcceptMove: TAcceptMoveEvent;
    FAcceptMove: Boolean;
    FDebug: TStrings;
    procedure SetFlipBoard(const Value: Boolean);
    procedure SetAcceptMove(const Value: Boolean);
    procedure OutputDebugSelectMove;
    function GetAnimate: Boolean;
  public
    procedure Loaded; override;
    procedure SetPosition(const Position: TPosition; NeedAnimate: Boolean = True);
    procedure RefreshView;
    procedure DrawField(X, Y, Index: Integer);
    function IsWhite(X, Y: Integer): Boolean;
    function CellToField(X, Y: Integer): Integer;
    procedure SelectCell(X, Y: Integer);
    procedure BeginMove(Field: Integer);
    procedure ClearSelect;
    procedure BeginDebug;
    procedure EndDebug;
    procedure OutputDebug(const St: string); overload;
    procedure OutputDebug(const St: string; const Args: array of const); overload;
    function PrepareAccept: Boolean;
    procedure InitSelectMoveVars;
    procedure AddCellToMove(X, Y: Integer);
    function Unselect(Field: Integer): Boolean;
    function ThinkBetter(Field: Integer): Boolean;
    function MoveComplete(Field: Integer): Boolean;
    procedure ContinueMove(Field: Integer);
    procedure BeginAnimate(const Position: TPosition);
    function CellRect(X, Y: Integer; Grow: Integer = 0): TRect;
    property Debug: TStrings read FDebug write FDebug;
    property FlipBoard: Boolean read FFlipBoard write SetFlipBoard;
    property AcceptMove: Boolean read FAcceptMove write SetAcceptMove;
    property OnAcceptMove: TAcceptMoveEvent read FOnAcceptMove write FOnAcceptMove;
    property Position: TPosition read FPosition;
    property Animate: Boolean read GetAnimate;
  end;

implementation

{$R *.DFM}

{ TPositionFrame }

procedure TPositionFrame.BeginDebug;
begin
  {$IFDEF SELECT_DEBUG}
    if Assigned(Debug) then
    begin
      Debug.BeginUpdate;
      Debug.Clear;
    end;
  {$ENDIF}
end;

procedure TPositionFrame.EndDebug;
begin
  {$IFDEF SELECT_DEBUG}
    if Assigned(Debug) then Debug.EndUpdate;
  {$ENDIF}
end;

procedure TPositionFrame.OutputDebug(const St: string);
begin
  {$IFDEF SELECT_DEBUG}
    Debug.Add(St);
  {$ENDIF}
end;

procedure TPositionFrame.OutputDebug(const St: string; const Args: array of const);
begin
  {$IFDEF SELECT_DEBUG}
    OutputDebug(Format(St, Args));
  {$ENDIF}
end;

procedure TPositionFrame.OutputDebugSelectMove;
{$IFDEF SELECT_DEBUG}
  var
    I, J: Integer;
    St: string;
{$ENDIF}
begin
  {$IFDEF SELECT_DEBUG}
    OutputDebug('Возможные хода:');
    for I := 0 to FAnswersCount - 1 do
    begin
      St := PointsDef[FAnswers[I].MoveStr[0]];
      J := 1;
      repeat
        if FAnswers[I].MoveStr[J] = -1 then Break;
        St := St + FAnswers[I].TakeChar + PointsDef[FAnswers[I].MoveStr[J]];
        J := J + 1;
      until False;
      OutputDebug('(%d) %s', [I, St]);
    end;

    OutputDebug('');

    St := '';
    for I := 0 to 31 do
      if FSelectedCells[I] then St := ' ' + PointsDef[I];
    OutputDebug('Selected =' + St);

    St := '';
    for I := 0 to FAnswersCount-1 do
      St := St + Format(' %d(%d)', [FEnabledAnswer[I], I]);
    OutputDebug('EnabledAnswer =' + St);

    St := '';
    for I := 0 to FUserSelectCount-1 do
      St := St + ' ' + PointsDef[FUserSelect[I]];
    OutputDebug('UserSelect =' + St);
  {$ENDIF}
end;

function TPositionFrame.CellToField(X, Y: Integer): Integer;
begin
  if FlipBoard
    then Result := 4*Y + (7-X) div 2
    else Result := 28 - 4*Y + (X div 2);
end;

procedure TPositionFrame.ClearSelect;
begin
  FSelected := -1;
  RefreshView;
end;

procedure TPositionFrame.DrawField(X, Y, Index: Integer);
begin
  ImageList.Draw(Image.Canvas, X*ImageList.Width, Y*ImageList.Height, Index);
end;

function TPositionFrame.IsWhite(X, Y: Integer): Boolean;
begin
  Result := ((X xor Y) and 1) = 0;
end;

procedure TPositionFrame.Loaded;
begin
  inherited;
  FSelected := -1;
end;

procedure TPositionFrame.RefreshView;
var
  X, Y: Integer;
  X1, X2, Y1, Y2: Integer;
  P, Q: Single;
  FieldIndex: Integer;
  OutPosition: PPosition;

begin
  if Animate
    then OutPosition := @FAnimatePosition
    else OutPosition := @FPosition; 
  ClientWidth := 8 * ImageList.Width;
  ClientWidth := 8 * ImageList.Height;
  for Y := 0 to 7 do
    for X := 0 to 7 do
      if IsWhite(X, Y) then
        DrawField(X, Y, 0)
      else begin
        FieldIndex := CellToField(X, Y);
        if Animate and (Position.MoveStr[0] = FieldIndex) then
          DrawField(X, Y, 1)
        else
          case OutPosition.Field[FieldIndex] of
            brWhiteSingle: DrawField(X, Y, 2);
            brBlackSingle: DrawField(X, Y, 3);
            brWhiteMam: DrawField(X, Y, 4);
            brBlackMam: DrawField(X, Y, 5);
            brEmpty: DrawField(X, Y, 1)
            else DrawField(X, Y, 6)
          end;
        if FSelectedCells[FieldIndex] then
        begin
          Image.Canvas.Brush.Style := bsClear;
          Image.Canvas.Pen.Width := 1;
          Image.Canvas.Pen.Color := clGreen;
          Image.Canvas.Rectangle(CellRect(X, Y));
          Image.Canvas.Rectangle(CellRect(X, Y, -1));
        end;
      end;
  if Animate then
  begin
    if FlipBoard then
    begin
      X1 := ImageList.Width * (7 - FAnimateWay[FAnimateStep-1] mod 8);
      Y1 := ImageList.Height * (FAnimateWay[FAnimateStep-1] div 8);
      X2 := ImageList.Width * (7 - FAnimateWay[FAnimateStep] mod 8);
      Y2 := ImageList.Height * (FAnimateWay[FAnimateStep] div 8);
    end
    else begin
      X1 := ImageList.Width * (FAnimateWay[FAnimateStep-1] mod 8);
      Y1 := ImageList.Height * (7 - FAnimateWay[FAnimateStep-1] div 8);
      X2 := ImageList.Width * (FAnimateWay[FAnimateStep] mod 8);
      Y2 := ImageList.Height * (7 - FAnimateWay[FAnimateStep] div 8);
    end;
    P := FAnimateSubStep /ANIMATE_SUBSTEP_COUNT;
    Q := 1 - P; 
    X := Round(Q*X1+P*X2);
    Y := Round(Q*Y1+P*Y2);
    TransparentImages.Draw(Image.Canvas, X, Y, FAnimateObject);
  end;
  Image.Refresh;
end;

procedure TPositionFrame.SelectCell(X, Y: Integer);
begin
  if IsWhite(X, Y) then Exit;
  FSelected := CellToField(X, Y);
  RefreshView;
end;

procedure TPositionFrame.SetFlipBoard(const Value: Boolean);
begin
  if FFlipBoard = Value then Exit;
  FFlipBoard := Value;
  RefreshView;
end;

procedure TPositionFrame.SetPosition(const Position: TPosition; NeedAnimate: Boolean);
begin
  FAnimatePosition := FPosition;
  FPosition := Position;
  if AcceptMove then PrepareAccept;
  if NeedAnimate and (Position.MoveStr[0] <> -1)
    then BeginAnimate(Position)
    else RefreshView
end;

procedure TPositionFrame.ImageMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if not AcceptMove then Exit;
  BeginDebug;
  try
    OutputDebug('Перед ходом:');
    OutputDebug('=========================================');
    OutputDebugSelectMove;
    AddCellToMove(X div ImageList.Width, Y div ImageList.Height);
    OutputDebug('');
    OutputDebug('Ппосле хода:');
    OutputDebug('=========================================');
    OutputDebugSelectMove;
  finally
    EndDebug;
  end;
end;

function TPositionFrame.CellRect(X, Y: Integer; Grow: Integer = 0): TRect;
begin
  Result.Left := X * ImageList.Width - Grow;
  Result.Top := Y * ImageList.Height - Grow;
  Result.Right := Result.Left + ImageList.Width + 2*Grow;
  Result.Bottom := Result.Top + ImageList.Height + 2*Grow;
end;

procedure TPositionFrame.SetAcceptMove(const Value: Boolean);
begin
  if FAcceptMove = Value then Exit;
  if Value and not PrepareAccept then Exit;
  FAcceptMove := Value;
end;

procedure TPositionFrame.InitSelectMoveVars;
begin
  FillChar(FSelectedCells, SizeOf(FSelectedCells), $00);
  FillChar(FEnabledAnswer, SizeOf(FEnabledAnswer), $00);
  FUserSelectCount := 0;
end;

function TPositionFrame.PrepareAccept: Boolean;
begin
  FAnswersCount := GetMoves(FPosition, @FAnswers, ANSWERS_SIZE);
  Result := (FAnswersCount <> 0) and (FAnswersCount <= ANSWERS_SIZE);
  InitSelectMoveVars;
end;

procedure TPositionFrame.AddCellToMove(X, Y: Integer);
begin
  if IsWhite(X, Y) then Exit;
  if FUserSelectCount = 0 then
  begin
    BeginMove(CellToField(X, Y));
    Exit;
  end;
  if Unselect(CellToField(X, Y)) then Exit;
  if ThinkBetter(CellToField(X, Y)) then Exit;
  if MoveComplete(CellToField(X, Y)) then Exit;
  ContinueMove(CellToField(X, Y));
end;

procedure TPositionFrame.BeginMove(Field: Integer);
var
  I: Integer;
  FindMove: Boolean;
begin
  FindMove := False;
  for I := 0 to FAnswersCount-1 do
    if FAnswers[I].MoveStr[0] = Field then
    begin
      FindMove := True;
      FEnabledAnswer[I] := 1;
    end;
  if not FindMove then Exit;
  FUserSelect[0] := Field;
  FUserSelectCount := 1;
  FSelectedCells[Field] := True;
  RefreshView;
end;

function TPositionFrame.Unselect(Field: Integer): Boolean;
var
  I: Integer;
begin
  Result := False;
  if FUserSelectCount = 0 then Exit;
  if FUserSelect[FUserSelectCount-1] <> Field then Exit;
  FSelectedCells[Field] := False;
  for I := 0 to FAnswersCount-1 do
    if FEnabledAnswer[I] = FUserSelectCount then
      FEnabledAnswer[I] := FEnabledAnswer[I] - 1;
  FUserSelectCount := FUserSelectCount - 1;
  RefreshView;
  Result := True;
end;

function TPositionFrame.ThinkBetter(Field: Integer): Boolean;
var
  I: Integer;
begin
  Result := False;
  if FUserSelectCount <> 1 then Exit;
  for I := 0 to FAnswersCount-1 do
  begin
    if FAnswers[I].MoveStr[0] = Field then
    begin
      InitSelectMoveVars;
      BeginMove(Field);
      Result := True;
      Exit;
    end;
  end;
end;

function TPositionFrame.MoveComplete(Field: Integer): Boolean;
var
  I, J: Integer;
  UserMove: Integer;
begin
  Result := False;
  UserMove := -1;
  for I := 0 to FAnswersCount-1 do
  begin
    if FEnabledAnswer[I] <> FUserSelectCount then Continue;
    J := 2;
    while FAnswers[I].MoveStr[J] <> -1 do J := J + 1;
    if FAnswers[I].MoveStr[J-1] = Field then
      if UserMove <> -1 then Exit
      else UserMove := I;
  end;
  if UserMove = -1 then Exit;
  AcceptMove := False;
  FillChar(FSelectedCells, SizeOf(FSelectedCells), $00);
  if Assigned(FOnAcceptMove) then FOnAcceptMove(Self, FAnswers[UserMove]);
  Result := True;
end;

procedure TPositionFrame.ContinueMove(Field: Integer);
var
  I: Integer;
  FindMove: Boolean;

function FreeWay(Field1, Field2: Integer): Boolean;
var
  NextI: Integer;
  Direction: TDirection;
begin
  Result := False;
  for Direction := Low(TDirection) to High(TDirection) do
  begin
    NextI := Field1;
    repeat
      NextI := DirectionTable[Direction, NextI];
      if NextI = -1 then Break;
      if FPosition.Field[NextI] <> 0 then Break;
      if NextI = Field2 then
      begin
        Result := True;
        Exit;
      end;
    until False;
  end;
end;

function SameDiagonal(StartField, Field1, Field2, Field3: Integer): Boolean;
var
  FindCount: Integer;
  NextI: Integer;
  Direction: TDirection;
begin
  Result := False;
  for Direction := Low(TDirection) to High(TDirection) do
  begin
    NextI := StartField;
    FindCount := 0;
    repeat
      NextI := DirectionTable[Direction, NextI];
      if NextI = -1 then Break;
      if NextI = Field1 then FindCount := FindCount + 1;
      if NextI = Field2 then FindCount := FindCount + 1;
      if NextI = Field3 then FindCount := FindCount + 1;
      if FindCount = 3 then
      begin
        Result := True;
        Exit;
      end;
    until False;
  end;
end;

function AcceptMarginaly: Boolean;
begin
  Assert(FUserSelectCount > 0);
  Result :=
    (FAnswers[I].MoveStr[FUserSelectCount+1] <> -1) and // это не последнее поле
    FreeWay(FAnswers[I].MoveStr[FUserSelectCount], Field) and // можно пройти
    SameDiagonal( // Одна диагональ
        FAnswers[I].MoveStr[FUserSelectCount-1],
        FAnswers[I].MoveStr[FUserSelectCount],
        Field,
        FAnswers[I].MoveStr[FUserSelectCount+1])
end;

function AcceptDirectly: Boolean;
begin
  Result := Field = FAnswers[I].MoveStr[FUserSelectCount];
end;

function AcceptVariant: Boolean;
begin
  Result := AcceptDirectly or AcceptMarginaly;
end;

begin
  FindMove := False;
  for I := 0 to FAnswersCount-1 do
  begin
    if FEnabledAnswer[I] <> FUserSelectCount then Continue;
    if AcceptVariant then
    begin
      FindMove := True;
      FEnabledAnswer[I] := FEnabledAnswer[I] + 1;
    end;
  end;
  
  if FindMove then
  begin
    FUserSelect[FUserSelectCount] := Field;
    FUserSelectCount := FUserSelectCount + 1;
    FSelectedCells[Field] := True;
    RefreshView;
  end;
end;

function TPositionFrame.GetAnimate: Boolean;
begin
  Result := Timer.Enabled;
end;

procedure TPositionFrame.BeginAnimate(const Position: TPosition);

var
  AnimateWayPos: Integer;
  I: Integer;

procedure ProcessPair(Field1, Field2: Integer);
var
  Delta: Integer;
  Step: Integer;
  NextI: Integer;
begin
  Delta := Abs(Field1 - Field2);
  if Field1 > Field2 then
  begin
    if Delta mod 9 = 0
      then Step := -9
      else Step := -7
  end
  else begin
    if Delta mod 9 = 0
      then Step := 9
      else Step := 7
  end;
  NextI := Field1;
  repeat
    NextI := NextI + Step;
    FAnimateWay[AnimateWayPos] := NextI;
    AnimateWayPos := AnimateWayPos + 1;
  until NextI = Field2;   
end;

begin
  // Вычисляем путь
  with Position do
  begin
    if MoveStr[0] = -1 then Exit; 
    FAnimateWay[0] := DecodeField[MoveStr[0]];
    AnimateWayPos := 1;
    I := 1;
    while MoveStr[I] <> -1 do
    begin
      ProcessPair(DecodeField[MoveStr[I-1]], DecodeField[MoveStr[I]]);
      I := I + 1;
    end;
    case FAnimatePosition.Field[MoveStr[0]] of
      brWhiteSingle: FAnimateObject := 0;
      brBlackSingle: FAnimateObject := 1;
      brWhiteMam: FAnimateObject := 2;
      brBlackMam: FAnimateObject := 3;
    end;  
  end;
  FAnimateWay[AnimateWayPos] := -1;

  FAnimateStep := 1;
  FAnimateSubStep := 0;
  Timer.Enabled := True;
end;

procedure TPositionFrame.TimerTimer(Sender: TObject);
begin
  FAnimateSubStep := FAnimateSubStep + 1;
  if FAnimateSubStep = ANIMATE_SUBSTEP_COUNT then
  begin
    FAnimateStep := FAnimateStep + 1;
    if FAnimateWay[FAnimateStep] = -1 then Timer.Enabled := False;
    if (FAnimateObject = 0) and (FAnimateWay[FAnimateStep] >= 56) then FAnimateObject := 2;
    if (FAnimateObject = 1) and (FAnimateWay[FAnimateStep] <= 7) then FAnimateObject := 3;
    FAnimateSubStep := 0;
  end;
  RefreshView;
end;

end.
