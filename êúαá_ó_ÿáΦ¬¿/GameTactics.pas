unit GameTactics;

interface

uses GameLogic, Classes, Dialogs;

procedure LoadLib(FileName: string= '');
procedure SaveLib(FileName: string = '');
function FormatPosition(const Position: TPosition): string;
function SelectMove(var Board: TPosition; MaxBufLen: Integer; var CurrentEstimate: Integer): Integer;

var
  Lib: TStringList;

implementation

uses Windows, SysUtils, MainUnit;

var
  MySide: ShortInt;
  Deep: Integer;
  MaxBufferLen: Integer;
  CurrentN: Integer;

const
  NO_MOVES = 1;

  SingleCosts: array[0..31] of Integer =
    ( 7, 11, 13, 10,
     10, 12, 11, 10,
      8, 12, 12, 11,
     11, 13, 15, 11,
     10, 16, 10,  9,
     11, 13, 16, 11,
     10, 10, 10, 10,
      0,  0, 0,  0);

  MamCosts: array[0..31] of Integer =
    (12, 11, 10, 13,
     13, 10, 13, 13,
     11, 14, 14, 13,
     10, 15, 14, 10,
     11, 14, 15, 10,
     13, 14, 14, 11,
     13, 13, 10, 13,
     13, 11, 11, 12);

   Diag: array[0..31] of Integer =
     (
       1, 0, 0, 0,
       1, 0, 0, 0,
       0, 1, 0, 0,
       0, 1, 0, 0,
       0, 0, 1, 0,
       0, 0, 1, 0,
       0, 0, 0, 1,
       0, 0, 0, 1
     );

function LibPosition(const Position: TPosition; var Estimate: Integer): Boolean;
var
  Index: Integer;
  PositionStr: string;
begin
  PositionStr := FormatPosition(Position);
  Index := Lib.IndexOf(PositionStr);
  Result := Index <> -1;
  if Result then
    Estimate := Integer(Lib.Objects[Index]);
end; 

function Estimate(const Board: TPosition): Integer;
var
  I: Integer;
  C: Integer;
  WS, BS, WM, BM: Integer;
  WhiteDiag: Boolean;
  BlackDiag: Boolean;
begin
  Result := 0;
  WS := 0; BS := 0;
  WM := 0; BM := 0;
  WhiteDiag := False;
  BlackDiag := False;
  C := 0;
  
  for I := 0 to 31 do
  begin
    case Board.Field[I] of
      brWhiteSingle:
        begin
          C := SingleCosts[I];
          WS := WS + 1;
        end;
      brBlackSingle:
        begin
          C := SingleCosts[31-I];
          BS := BS + 1;
        end;
      brWhiteMam:
        begin
          C := MamCosts[I];
          WM := WM + 1;
          if Diag[I] = 1 then WhiteDiag := True;
        end;
      brBlackMam:
        begin
          C := MamCosts[31-I];
          BM := BM + 1; 
          if Diag[I] = 1 then BlackDiag := True;
        end;
      else Continue
    end;  
    Result := Result + C*Board.Field[I];
  end;
  if (BM <> 0) and (WS <> 0) then Result := Result div 2;
  if (WS=0) and (BS=0) then
  begin
    if (WM=1) and (BM=1) then Result := 0;
    if (WM=2) and (BM=1) then Result := 0;
    if (WM=1) and (BM=2) then Result := 0;
    if (WM=3) and (BM=1) and BlackDiag then Result := 0; 
    if (WM=1) and (BM=3) and WhiteDiag then Result := 0; 
  end;
  if WhiteDiag then Result := Result + 100;  
  if BlackDiag then Result := Result - 100;
end;



// Beta tested 20.02.2002
function RecurseEstimate(var Position: TPosition): Integer;
var
  SaveCurrentN: Integer;
  PositionCount: Integer;
  I: Integer;
  Temp: Integer;
  Board: TPosition;
begin
  Board := Position;
  if CurrentN > MaxBufferLen then
  begin
    Result := Estimate(Board);
    Exit;
  end;

  Deep := Deep + 20;
  SaveCurrentN := CurrentN;
  if Board.Active = ActiveWhite
    then PositionCount := GetMovesWhite(SaveCurrentN, Board)
    else PositionCount := GetMovesBlack(SaveCurrentN, Board);
  CurrentN := CurrentN + PositionCount;

  if PositionCount = 0 then
  begin
    if Board.Active = ActiveWhite
      then Result := -100000 + Deep
      else Result := +100000 - Deep;
  end
  else if PositionCount = 1 then
  begin
    Result := RecurseEstimate(Buffer[SaveCurrentN]);
  end
  else begin

    // Обычная рекурсивная оценка
    Result := RecurseEstimate(Buffer[SaveCurrentN]);
    for I := SaveCurrentN+1 to CurrentN - 1 do
    begin
      Temp := RecurseEstimate(Buffer[I]);
      if (Board.Active = ActiveWhite) then
      begin
        if Temp > Result then
          Result := Temp;
      end
      else begin
        if Temp < Result then
          Result := Temp;
      end;
    end;
  end;

  Deep := Deep - 20;
  CurrentN := SaveCurrentN;
end;




procedure WaitAnimation;
begin
  while SendMessage(MainForm.Handle, MM_IS_ANIMATION, 0, 0) = 1 do
    Sleep(30);
end;



// Beta tested 20.05.2002
function SelectMove(var Board: TPosition; MaxBufLen: Integer; var CurrentEstimate: Integer): Integer;
var
  I: Integer;
  CurrentIndex: Integer;
  Temp: Integer;
begin
  try
    MySide := Board.Active;
    MaxBufferLen := MaxBufLen;
    CurrentN := 0;
    Deep := 0;

    if Board.Active = ActiveWhite
      then CurrentN := Abs(GetMovesWhite(0, Board))
      else CurrentN := Abs(GetMovesBlack(0, Board));

    if CurrentN = 0 then
    begin
      Result := NO_MOVES;
      Exit;
    end;

    if CurrentN = 1 then
    begin
      Board := Buffer[0];
      Result := 0;
      Exit;
    end;

    SendMessage(MainForm.Handle, MM_DEBUG, 0, 0);
    if not LibPosition(Buffer[0], CurrentEstimate) then
      CurrentEstimate := RecurseEstimate(Buffer[0]);
    SendMessage(MainForm.Handle, MM_DEBUG, Integer(@Buffer[0]), CurrentEstimate);
    CurrentEstimate := CurrentEstimate + Random(101) - 50;
    CurrentIndex := 0;
    for I := 1 to CurrentN - 1 do
    begin
      if not LibPosition(Buffer[I], Temp) then
        Temp := RecurseEstimate(Buffer[I]);
      SendMessage(MainForm.Handle, MM_DEBUG, Integer(@Buffer[I]), Temp);
      Temp := Temp + Random(21) - 10;
      if MySide = ActiveWhite then
      begin
        if Temp > CurrentEstimate then
        begin
          CurrentEstimate := Temp;
          CurrentIndex := I;
        end;
      end
      else begin
        if Temp < CurrentEstimate then
        begin
          CurrentEstimate := Temp;
          CurrentIndex := I;
        end;
      end;
    end;

    Board := Buffer[CurrentIndex];
    Result := 0;

  finally
    WaitAnimation;
  end;  
end;

function DefaultFileName: string;
begin
  Result := IncludeTrailingBackslash(ExtractFilePath(ParamStr(0))) +
    'WinDraught.lib'
end;

procedure LoadLib(FileName: string= '');
var
  Temp: TStringList;
  I: Integer;
  No: Integer;
begin
  if Trim(FileName) = '' then FileName := DefaultFileName;
  try
    Temp := TStringList.Create;
    try
      Temp.LoadFromFile(FileName);
      for I := 0 to Temp.Count-1 do
      begin
        if Length(Trim(Temp[I])) <> 6 + 33 then Continue;
        No := StrToIntDef(Copy(Trim(Temp[I]), 1, 6), -$7FFFFFFF);
        if No = -$7FFFFFFF then Continue;
        Lib.AddObject(Copy(Trim(Temp[I]), 7, 33), TObject(No));
      end;
      Lib.Sorted := True;
    finally
      Temp.Free;
    end;
  except
    MessageDlg(Format('Error loading file "%s"', [FileName]), mtWarning, [mbOk], 0);
  end;
end;

procedure SaveLib(FileName: string = '');
var
  I: Integer;
  Estimate: Integer;
  Temp: TStringList;
begin
  if Trim(FileName) = '' then FileName := DefaultFileName;
  Temp := TStringList.Create;
  try
    for I := 0 to Lib.Count-1 do
    begin
      Estimate := Integer(Lib.Objects[I]);
      if Estimate < 0
        then Temp.Add('-' + FormatFloat('00000', -Estimate) + Lib[I])
        else Temp.Add('+' + FormatFloat('00000', Estimate) + Lib[I]);
    end;    
    Temp.SaveToFile(FileName);
  finally
    Temp.Free;
  end;
end;

function FormatPosition(const Position: TPosition): string;
var
  I: Integer;
begin
  SetLength(Result, 33);
  if Position.Active = ActiveWhite
    then Result[1] := '+'
    else Result[1] := '-';
  for I := 0 to 31 do
    case Position.Field[I] of
      brWhiteSingle: Result[I+2] := 'w';
      brBlackSingle: Result[I+2] := 'b';
      brWhiteMam: Result[I+2] := 'W';
      brBlackMam: Result[I+2] := 'B'
      else Result[I+2] := '.'
    end;  
end;

initialization
  Randomize;
  Lib := TStringList.Create;

finalization
  Lib.Free;

end.
