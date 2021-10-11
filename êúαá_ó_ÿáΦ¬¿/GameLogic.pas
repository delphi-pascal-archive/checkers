unit GameLogic;

interface

type
  TDirection = (drLeftUp, drRightUp, drLeftDown, drRightDown);
  TDirectionTable = array [TDirection, 0..31] of Integer;

  PPosition = ^TPosition;
  TPosition = record
    Field: array[0..31] of ShortInt;
    MoveStr: array[0..11] of ShortInt;
    Active: Integer;
    TakeChar: Char;
    MoveCount: Integer;
  end;

const
  DecodeField: array [0..31] of Integer =
    (0, 2, 4, 6, 9, 11, 13, 15, 16, 18, 20, 22, 25, 27, 29, 31,
     32, 34, 36, 38, 41, 43, 45, 47, 48, 50, 52, 54, 57, 59, 61, 63);

  brWhiteSingle = 20;
  brWhiteMam = 70;
  brBlackSingle = -20;
  brBlackMam = -70;
  brEmpty = 0;

  ActiveWhite = 1;
  ActiveBlack = 0;

  PointsDef: array[0..31] of string =
    (
      'a1', 'c1', 'e1', 'g1', 'b2', 'd2', 'f2', 'h2',
      'a3', 'c3', 'e3', 'g3', 'b4', 'd4', 'f4', 'h4',
      'a5', 'c5', 'e5', 'g5', 'b6', 'd6', 'f6', 'h6',
      'a7', 'c7', 'e7', 'g7', 'b8', 'd8', 'f8', 'h8'
    );
var
  DirectionTable: TDirectionTable;
  StartBoard: TPosition;
  Buffer: array[0..1023] of TPosition;

function GetMoves(Position: TPosition; Buf: PPosition; BufSize: Integer): Integer;
function GameOver(const Position: TPosition): string;
function GetMovesWhite(N: Integer; var Board: TPosition): Integer;
function GetMovesBlack(N: Integer; var Board: TPosition): Integer;
function GetLastMove(Position: TPosition): string;

implementation


var
  Dead: array[0..31] of ShortInt;
  DeadCount: Integer;
  MoveWriter: Integer;

const
  brWhiteDead = -10;
  brBlackDead = 10;

  WhiteMamLine = 28;
  BlackMamLine = 3;

  WasTake = ':';
  WasNotTake = '-';

  OrtDirection1: array [TDirection] of TDirection = (drRightUp, drLeftUp, drLeftUp, drRightUp);
  OrtDirection2: array [TDirection] of TDirection = (drLeftDown, drRightDown, drRightDown, drLeftDown);

(**************************
 ** GetMovesWhite - получить список всех ходов за белых
 ** GetMovesBlack - получить список всех ходов за черных
 ** GetLastMove - получить последний ход в строковом представлении
 **
 ** Поле задается: 
 **   первые 32 элемента массива --- шашки (brWhiteSingle; brWhiteMam; brBlackSingle; brBlackMam; или нуль
 **   32 элемент - счетчик ходов только дамками
 **   33 элемент - кто ходит
 ** 
 ** (С) Mystic, 2002. 
 **   Этот алгоритм реализован в программе http://www.listsoft.ru/program.php?id=13904&allowunchecked=yes
 **   Разрешается использовать в некоммерческих целях со ссылкой на автора.
**************************)

type
  TSingleMoveRec = record
    PointFrom: Integer;
    PointTo: Integer;
    Counter: ShortInt;
    WhatPut: ShortInt;
  end;


// Beta tested 19.05.2002
function GetLastMove(Position: TPosition): string;
var
  I: Integer;
begin
  Result := PointsDef[Position.MoveStr[0]];
  I := 1;
  while Position.MoveStr[I] <> -1 do
  begin
    Result := Result + Position.TakeChar + PointsDef[Position.MoveStr[I]];
    I := I + 1;
  end;
end;




// Beta tested 19.05.2002
function RecurseMamTakeWhite(var N: Integer; Cell : Integer; Direction: TDirection; var Board: TPosition): Integer;
var
  OrtDirection: TDirection;
  NN: Integer;
  I, J, NextI, NextNextI: Integer;
  SaveDead: ShortInt;
begin
  Result := 0;

  I := Cell;
  repeat
    OrtDirection := OrtDirection1[Direction];
    NextI := I;
    repeat
      NextI := DirectionTable[OrtDirection, NextI];
      if NextI = -1 then Break;
      if Board.Field[NextI] <> 0 then Break;
    until False;
    if (NextI <> -1) and (Board.Field[NextI] < 0) then
    begin
      NextNextI := DirectionTable[OrtDirection, NextI];
      if (NextNextI <> -1) and (Board.Field[NextNextI] = 0) then
      begin
        Dead[DeadCount] := NextI;
        SaveDead := Board.Field[NextI];
        Board.Field[NextI] := brBlackDead;
        DeadCount := DeadCount + 1;
        Board.MoveStr[MoveWriter] := I;
        MoveWriter := MoveWriter + 1;
        Result := Result + RecurseMamTakeWhite(N, NextNextI, OrtDirection, Board);
        Board.Field[NextI] := SaveDead;
        MoveWriter := MoveWriter - 1;
        DeadCount := DeadCount - 1;
      end;
    end;

    OrtDirection := OrtDirection2[Direction];
    NextI := I;
    repeat
      NextI := DirectionTable[OrtDirection, NextI];
      if NextI = -1 then Break;
      if Board.Field[NextI] <> 0 then Break;
    until False;
    if (NextI <> -1) and (Board.Field[NextI] < 0) then
    begin
      NextNextI := DirectionTable[OrtDirection, NextI];
      if (NextNextI <> -1) and (Board.Field[NextNextI] = 0) then
      begin
        Dead[DeadCount] := NextI;
        SaveDead := Board.Field[NextI];
        Board.Field[NextI] := brBlackDead;
        DeadCount := DeadCount + 1;
        Board.MoveStr[MoveWriter] := I;
        MoveWriter := MoveWriter + 1;
        Result := Result + RecurseMamTakeWhite(N, NextNextI, OrtDirection, Board);
        Board.Field[NextI] := SaveDead;
        MoveWriter := MoveWriter - 1;
        DeadCount := DeadCount - 1;
      end;
    end;

    I := DirectionTable[Direction, I];
    if I = -1 then Break;
    if Board.Field[I] > 0 then Break;
    if Board.Field[I] < 0 then
    begin
      NextI := DirectionTable[Direction, I];
      if NextI = -1 then Break;
      if Board.Field[NextI] = 0 then
      begin
        Dead[DeadCount] := I;
        SaveDead := Board.Field[I];
        Board.Field[I] := brBlackDead;
        DeadCount := DeadCount + 1;
        Board.MoveStr[MoveWriter] := Cell;
        MoveWriter := MoveWriter + 1;
        Result := Result + RecurseMamTakeWhite(N, NextI, Direction, Board);
        Board.Field[I] := SaveDead;
        MoveWriter := MoveWriter - 1;
        DeadCount := DeadCount - 1;
      end;
      Break;
    end;
  until False;

  if Result = 0 then
  begin
    Buffer[N] := Board;
    for J := 0 to DeadCount-1 do
      Buffer[N].Field[Dead[J]] := 0;
    Buffer[N].MoveCount := 0;
    Buffer[N].Active := ActiveBlack;
    Buffer[N].TakeChar := WasTake;
    Buffer[N].MoveStr[MoveWriter+1] := -1;
    NN := N + 1;
    Result := 1;
    NextI := DirectionTable[Direction, Cell];
    repeat
      if NextI = -1 then Break;
      if Board.Field[NextI] <> 0 then Break;
      Buffer[NN] := Buffer[N];
      Buffer[NN].Field[NextI] := brWhiteMam;
      Buffer[NN].MoveStr[MoveWriter] := NextI;
      NN := NN + 1;
      Result := Result + 1;
      NextI := DirectionTable[Direction, NextI];
    until False;
    Buffer[N].Field[Cell] := brWhiteMam;
    Buffer[N].MoveStr[MoveWriter] := Cell;
    N := NN;
  end;
end;



// Beta tested 20.05.2002
function RecurseSingleTakeWhite(var N: Integer; Cell : Integer; Direction: TDirection; var Board: TPosition): Integer;
var
  OrtDirection: TDirection;
  NExtI, NExtNextI: Integer;
  SaveDead: ShortInt;
  J: Integer;
begin
  Result := 0;

  OrtDirection := OrtDirection1[Direction];
  NextI := DirectionTable[OrtDirection, Cell];
  if (NextI <> -1) and (Board.Field[NextI] < 0) then
  begin
    NextNextI := DirectionTable[OrtDirection, NextI];
    if (NextNextI <> -1) and (Board.Field[NextNextI] = 0) then
    begin
      Dead[DeadCount] := NextI;
      DeadCount := DeadCount + 1;
      SaveDead := Board.Field[NextI];
      Board.Field[NextI] := brBlackDead;
      Board.MoveStr[MoveWriter] := Cell;
      MoveWriter := MoveWriter + 1;
      if NextNextI >= WhiteMamLine
        then Result := Result + RecurseMamTakeWhite(N, NextNextI, OrtDirection, Board)
        else Result := Result + RecurseSingleTakeWhite(N, NextNextI, OrtDirection, Board);
      MoveWriter := MoveWriter - 1;
      DeadCount := DeadCount - 1;
      Board.Field[NextI] := SaveDead;
    end;
  end;

  OrtDirection := OrtDirection2[Direction];
  NextI := DirectionTable[OrtDirection, Cell];
  if (NextI <> -1) and (Board.Field[NextI] < 0) then
  begin
    NextNextI := DirectionTable[OrtDirection, NextI];
    if (NextNextI <> -1) and (Board.Field[NextNextI] = 0) then
    begin
      Dead[DeadCount] := NextI;
      SaveDead := Board.Field[NextI];
      Board.Field[NextI] := brBlackDead;
      DeadCount := DeadCount + 1;
      Board.MoveStr[MoveWriter] := Cell;
      MoveWriter := MoveWriter + 1;
      if NextNextI >= WhiteMamLine
        then Result := Result + RecurseMamTakeWhite(N, NextNextI, OrtDirection, Board)
        else Result := Result + RecurseSingleTakeWhite(N, NextNextI, OrtDirection, Board);
      Board.Field[NextI] := SaveDead;
      MoveWriter := MoveWriter - 1;
      DeadCount := DeadCount - 1;
    end;
  end;

  NextI := DirectionTable[Direction, Cell];
  if (NextI <> -1) and (Board.Field[NextI] < 0) then
  begin
    NextNextI := DirectionTable[Direction, NextI];
    if (NextNextI <> -1) and (Board.Field[NextNextI] = 0) then
    begin
      Dead[DeadCount] := NextI;
      SaveDead := Board.Field[NextI];
      Board.Field[NextI] := brBlackDead;
      DeadCount := DeadCount + 1;
      Board.MoveStr[MoveWriter] := Cell;
      MoveWriter := MoveWriter + 1;
      if NextNextI >= WhiteMamLine
        then Result := Result + RecurseMamTakeWhite(N, NextNextI, Direction, Board)
        else Result := Result + RecurseSingleTakeWhite(N, NextNextI, Direction, Board);
      Board.Field[NextI] := SaveDead;
      MoveWriter := MoveWriter - 1;
      DeadCount := DeadCount - 1;
    end;
  end;

  if Result = 0 then
  begin
    Buffer[N] := Board;
    for J := 0 to DeadCount-1 do
      Buffer[N].Field[Dead[J]] := 0;
    Buffer[N].Field[Cell] := brWhiteSingle;
    Buffer[N].MoveCount := 0;
    Buffer[N].Active := ActiveBlack;
    Buffer[N].TakeChar := WasTake;
    Buffer[N].MoveStr[MoveWriter] := Cell;
    Buffer[N].MoveStr[MoveWriter+1] := -1;
    N := N + 1;
    Result := 1;
  end

end;




// Beta tested 19.05.2002
function GetMovesWhite(N: Integer; var Board: TPosition): Integer;
var
  I: Integer;
  Temp: Integer;
  NextI, NextNextI: Integer;
  SaveDead: ShortInt;
  Direction: TDirection;
  SingleMoves: array[0..1023] of TSingleMoveRec;
begin
  Result := 0;
  DeadCount := 0;
  MoveWriter := 0;
  for I := 0 to 31 do
  begin

    // Ход простой
    if Board.Field[I] = brWhiteSingle then
    begin

      // Проверка на взятие вниз влево
      NextI := DirectionTable[drLeftDown, I];
      if (NextI <> -1) and (Board.Field[NextI] < 0) then
      begin
        NextNextI := DirectionTable[drLeftDown, NextI];
        if (NextNextI <> -1) and (Board.Field[NextNextI] = 0) then
        begin
          if Result > 0 then Result := 0;
          Board.Field[I] := 0;
          Dead[DeadCount] := NextI;
          SaveDead := Board.Field[NextI];
          Board.Field[NextI] := brBlackDead;
          DeadCount := DeadCount + 1;
          Board.MoveStr[MoveWriter] := I;
          MoveWriter := MoveWriter + 1;
          {if NextNextI >= WhiteMamLine} // Оптимизаия --- взятие назад не может привести к дамке
          {  then Result := Result - RecurseMamTakeWhite(N, NextNextI, drLeftDown, Board)}
            {else} Result := Result - RecurseSingleTakeWhite(N, NextNextI, drLeftDown, Board);
          Board.Field[NextI] := SaveDead;
          MoveWriter := MoveWriter - 1;
          DeadCount := DeadCount - 1;
          Board.Field[I] := brWhiteSingle;
        end;
      end;

      // Проверка на взятие вниз вправо
      NextI := DirectionTable[drRightDown, I];
      if (NextI <> -1) and (Board.Field[NextI] < 0) then
      begin
        NextNextI := DirectionTable[drRightDown, NextI];
        if (NextNextI <> -1) and (Board.Field[NextNextI] = 0) then
        begin
          if Result > 0 then Result := 0;
          Board.Field[I] := 0;
          Dead[DeadCount] := NextI;
          SaveDead := Board.Field[NextI];
          Board.Field[NextI] := brBlackDead;
          DeadCount := DeadCount + 1;
          Board.MoveStr[MoveWriter] := I;
          MoveWriter := MoveWriter + 1;
          {if NextNextI >= WhiteMamLine} // Оптимизаия --- взятие назад не может привести к дамке
          {  then Result := Result - RecurseMamTakeWhite(N, NextNextI, drRightDown, Board)}
            {else} Result := Result - RecurseSingleTakeWhite(N, NextNextI, drRightDown, Board);
          Board.Field[NextI] := SaveDead;
          MoveWriter := MoveWriter - 1;
          DeadCount := DeadCount - 1;
          Board.Field[I] := brWhiteSingle;
        end;
      end;

      // Ход влево вверх
      NextI := DirectionTable[drLeftUp, I];
      if NextI >= 0 then
      begin
        Temp := Board.Field[NextI];
        if Temp = 0 then // Поле свободно
        begin
          if Result >= 0 then // Не было взятий
          begin
            SingleMoves[Result].PointFrom := I;
            SingleMoves[Result].PointTo := NextI;
            SingleMoves[Result].Counter := 0;
            if NextI >= WhiteMamLine
              then SingleMoves[Result].WhatPut := brWhiteMam
              else SingleMoves[Result].WhatPut := brWhiteSingle;
            Result := Result + 1;
          end
        end
        else begin
          if Temp < 0 then
          begin
            NextNextI := DirectionTable[drLeftUp, NextI];
            if (NextNextI <> -1) and (Board.Field[NextNextI] = 0) then
            begin
              if Result > 0 then Result := 0;
              Board.Field[I] := 0;
              Dead[DeadCount] := NextI;
              SaveDead := Board.Field[NextI];
              Board.Field[NextI] := brBlackDead;
              DeadCount := DeadCount + 1;
              Board.MoveStr[MoveWriter] := I;
              MoveWriter := MoveWriter + 1;
              if NextNextI >= WhiteMamLine
                then Result := Result - RecurseMamTakeWhite(N, NextNextI, drLeftUp, Board)
                else Result := Result - RecurseSingleTakeWhite(N, NextNextI, drLeftUp, Board);
              Board.Field[NextI] := SaveDead;
              MoveWriter := MoveWriter - 1;
              DeadCount := DeadCount - 1;
              Board.Field[I] := brWhiteSingle;
            end;
          end;
        end;
      end;

      // Ход вправо вверх
      NextI := DirectionTable[drRightUp, I];
      if NextI >= 0 then
      begin
        Temp := Board.Field[NextI];
        if Temp = 0 then // Поле свободно
        begin
          if Result >= 0 then // Не было взятий
          begin
            SingleMoves[Result].PointFrom := I;
            SingleMoves[Result].PointTo := NextI;
            SingleMoves[Result].Counter := 0;
            if NextI >= WhiteMamLine
              then SingleMoves[Result].WhatPut := brWhiteMam
              else SingleMoves[Result].WhatPut := brWhiteSingle;
            Result := Result + 1;
          end
        end
        else begin
          if Temp < 0 then
          begin
            NextNextI := DirectionTable[drRightUp, NextI];
            if (NextNextI <> -1) and (Board.Field[NextNextI] = 0) then
            begin
              if Result > 0 then Result := 0;
              Board.Field[I] := 0;
              Dead[DeadCount] := NextI;
              SaveDead := Board.Field[NextI];
              Board.Field[NextI] := brBlackDead;
              DeadCount := DeadCount + 1;
              Board.MoveStr[MoveWriter] := I;
              MoveWriter := MoveWriter + 1;
              if NextNextI >= WhiteMamLine
                then Result := Result - RecurseMamTakeWhite(N, NextNextI, drRightUp, Board)
                else Result := Result - RecurseSingleTakeWhite(N, NextNextI, drRightUp, Board);
              Board.Field[NextI] := SaveDead;
              MoveWriter := MoveWriter - 1;
              DeadCount := DeadCount - 1;
              Board.Field[I] := brWhiteSingle;
            end;
          end;
        end;
      end;
    end

    // Ход дамкой.
    else if Board.Field[I] = brWhiteMam then
    begin
      Board.Field[I] := 0;
      for Direction := Low(TDirection) to High(TDirection) do
      begin
        NextI := DirectionTable[Direction, I];
        repeat
          if NextI = -1 then Break;
          Temp := Board.Field[NextI];
          if Temp = 0 then
          begin
            if Result >= 0 then // Не было взятий
            begin
              SingleMoves[Result].PointFrom := I;
              SingleMoves[Result].PointTo := NextI;
              SingleMoves[Result].Counter := Board.MoveCount + 1;
              SingleMoves[Result].WhatPut := brWhiteMam;
              Result := Result + 1;
            end;
            NextI := DirectionTable[Direction, NextI];
          end
          else if Temp < brBlackDead then begin
            NextNextI := DirectionTable[Direction, NextI];
            if (NextNextI <> -1) and (Board.Field[NextNextI] = 0) then
            begin
              Dead[DeadCount] := NextI;
              SaveDead := Board.Field[NextI];
              Board.Field[NextI] := brBlackDead;
              DeadCount := DeadCount + 1;
              Board.MoveStr[MoveWriter] := I;
              MoveWriter := MoveWriter + 1;
              if Result > 0 then Result := 0;
              Result := Result - RecurseMamTakeWhite(N, NextNextI, Direction, Board);
              Board.Field[NextI] := SaveDead;
              MoveWriter := MoveWriter - 1;
              DeadCount := DeadCount - 1;
            end;
            Break;
          end
          else
            Break;
        until False;
      end;
      Board.Field[I] := brWhiteMam;
    end;


  end;

  for I := 0 to Result-1 do
  begin
    Buffer[N] := Board;
    Buffer[N].Field[SingleMoves[I].PointFrom] := 0;
    Buffer[N].Field[SingleMoves[I].PointTo] := SingleMoves[I].WhatPut;
    Buffer[N].MoveCount := SingleMoves[I].Counter;
    Buffer[N].Active := ActiveBlack;
    Buffer[N].MoveStr[0] := SingleMoves[I].PointFrom;
    Buffer[N].MoveStr[1] := SingleMoves[I].PointTo;
    Buffer[N].MoveStr[2] := -1;
    Buffer[N].TakeChar := WasNotTake;
    N := N + 1;
  end;
  Result := Abs(Result);
end;




// Beta tested 19.05.2002
function RecurseMamTakeBlack(var N: Integer; Cell : Integer; Direction: TDirection; var Board: TPosition): Integer;
var
  OrtDirection: TDirection;
  NN: Integer;
  I, J, NextI, NextNextI: Integer;
  SaveDead: ShortInt;
begin
  Result := 0;

  I := Cell;
  repeat
    OrtDirection := OrtDirection1[Direction];
    NextI := I;
    repeat
      NextI := DirectionTable[OrtDirection, NextI];
      if NextI = -1 then Break;
      if Board.Field[NextI] <> 0 then Break;
    until False;
    if (NextI <> -1) and (Board.Field[NextI] > 0) then
    begin
      NextNextI := DirectionTable[OrtDirection, NextI];
      if (NextNextI <> -1) and (Board.Field[NextNextI] = 0) then
      begin
        Dead[DeadCount] := NextI;
        SaveDead := Board.Field[NextI];
        Board.Field[NextI] := brWhiteDead;
        DeadCount := DeadCount + 1;
        Board.MoveStr[MoveWriter] := I;
        MoveWriter := MoveWriter + 1;
        Result := Result + RecurseMamTakeBlack(N, NextNextI, OrtDirection, Board);
        Board.Field[NextI] := SaveDead;
        MoveWriter := MoveWriter - 1;
        DeadCount := DeadCount - 1;
      end;
    end;

    OrtDirection := OrtDirection2[Direction];
    NextI := I;
    repeat
      NextI := DirectionTable[OrtDirection, NextI];
      if NextI = -1 then Break;
      if Board.Field[NextI] <> 0 then Break;
    until False;
    if (NextI <> -1) and (Board.Field[NextI] > 0) then
    begin
      NextNextI := DirectionTable[OrtDirection, NextI];
      if (NextNextI <> -1) and (Board.Field[NextNextI] = 0) then
      begin
        Dead[DeadCount] := NextI;
        SaveDead := Board.Field[NextI];
        Board.Field[NextI] := brWhiteDead;
        DeadCount := DeadCount + 1;
        Board.MoveStr[MoveWriter] := I;
        MoveWriter := MoveWriter + 1;
        Result := Result + RecurseMamTakeBlack(N, NextNextI, OrtDirection, Board);
        Board.Field[NextI] := SaveDead;
        MoveWriter := MoveWriter - 1;
        DeadCount := DeadCount - 1;
      end;
    end;

    I := DirectionTable[Direction, I];
    if I = -1 then Break;
    if Board.Field[I] < 0 then Break;
    if Board.Field[I] > 0 then
    begin
      NextI := DirectionTable[Direction, I];
      if NextI = -1 then Break;
      if Board.Field[NextI] = 0 then
      begin
        Dead[DeadCount] := I;
        SaveDead := Board.Field[I];
        Board.Field[I] := brWhiteDead;
        DeadCount := DeadCount + 1;
        Board.MoveStr[MoveWriter] := Cell;
        MoveWriter := MoveWriter + 1;
        Result := Result + RecurseMamTakeBlack(N, NextI, Direction, Board);
        Board.Field[I] := SaveDead;
        MoveWriter := MoveWriter - 1;
        DeadCount := DeadCount - 1;
      end;
      Break;
    end;
  until False;

  if Result = 0 then
  begin
    Buffer[N] := Board;
    for J := 0 to DeadCount-1 do
      Buffer[N].Field[Dead[J]] := 0;
    Buffer[N].MoveCount := 0;
    Buffer[N].Active := ActiveWhite;
    Buffer[N].TakeChar := WasTake;
    Buffer[N].MoveStr[MoveWriter+1] := -1;
    NN := N + 1;
    Result := 1;
    NextI := DirectionTable[Direction, Cell];
    repeat
      if NextI = -1 then Break;
      if Board.Field[NextI] <> 0 then Break;
      Buffer[NN] := Buffer[N];
      Buffer[NN].Field[NextI] := brBlackMam;
      Buffer[NN].MoveStr[MoveWriter] := NextI;
      NN := NN + 1;
      Result := Result + 1;
      NextI := DirectionTable[Direction, NextI];
    until False;
    Buffer[N].Field[Cell] := brBlackMam;
    Buffer[N].MoveStr[MoveWriter] := Cell;
    N := NN;
  end;
end;




// Beta tested 20.05.2002
function RecurseSingleTakeBlack(var N: Integer; Cell : Integer; Direction: TDirection; var Board: TPosition): Integer;
var
  OrtDirection: TDirection;
  NExtI, NExtNextI: Integer;
  SaveDead: ShortInt;
  J: Integer;
begin
  Result := 0;

  OrtDirection := OrtDirection1[Direction];
  NextI := DirectionTable[OrtDirection, Cell];
  if (NextI <> -1) and (Board.Field[NextI] > 0) then
  begin
    NextNextI := DirectionTable[OrtDirection, NextI];
    if (NextNextI <> -1) and (Board.Field[NextNextI] = 0) then
    begin
      Dead[DeadCount] := NextI;
      DeadCount := DeadCount + 1;
      SaveDead := Board.Field[NextI];
      Board.Field[NextI] := brWhiteDead;
      Board.MoveStr[MoveWriter] := Cell;
      MoveWriter := MoveWriter + 1;
      if NextNextI <= BlackMamLine
        then Result := Result + RecurseMamTakeBlack(N, NextNextI, OrtDirection, Board)
        else Result := Result + RecurseSingleTakeBlack(N, NextNextI, OrtDirection, Board);
      MoveWriter := MoveWriter - 1;
      DeadCount := DeadCount - 1;
      Board.Field[NextI] := SaveDead;
    end;
  end;

  OrtDirection := OrtDirection2[Direction];
  NextI := DirectionTable[OrtDirection, Cell];
  if (NextI <> -1) and (Board.Field[NextI] > 0) then
  begin
    NextNextI := DirectionTable[OrtDirection, NextI];
    if (NextNextI <> -1) and (Board.Field[NextNextI] = 0) then
    begin
      Dead[DeadCount] := NextI;
      SaveDead := Board.Field[NextI];
      Board.Field[NextI] := brWhiteDead;
      DeadCount := DeadCount + 1;
      Board.MoveStr[MoveWriter] := Cell;
      MoveWriter := MoveWriter + 1;
      if NextNextI <= BlackMamLine
        then Result := Result + RecurseMamTakeBlack(N, NextNextI, OrtDirection, Board)
        else Result := Result + RecurseSingleTakeBlack(N, NextNextI, OrtDirection, Board);
      Board.Field[NextI] := SaveDead;
      MoveWriter := MoveWriter - 1;
      DeadCount := DeadCount - 1;
    end;
  end;

  NextI := DirectionTable[Direction, Cell];
  if (NextI <> -1) and (Board.Field[NextI] > 0) then
  begin
    NextNextI := DirectionTable[Direction, NextI];
    if (NextNextI <> -1) and (Board.Field[NextNextI] = 0) then
    begin
      Dead[DeadCount] := NextI;
      SaveDead := Board.Field[NextI];
      Board.Field[NextI] := brWhiteDead;
      DeadCount := DeadCount + 1;
      Board.MoveStr[MoveWriter] := Cell;
      MoveWriter := MoveWriter + 1;
      if NextNextI <= BlackMamLine
        then Result := Result + RecurseMamTakeBlack(N, NextNextI, Direction, Board)
        else Result := Result + RecurseSingleTakeBlack(N, NextNextI, Direction, Board);
      Board.Field[NextI] := SaveDead;
      MoveWriter := MoveWriter - 1;
      DeadCount := DeadCount - 1;
    end;
  end;

  if Result = 0 then
  begin
    Buffer[N] := Board;
    for J := 0 to DeadCount-1 do
      Buffer[N].Field[Dead[J]] := 0;
    Buffer[N].Field[Cell] := brBlackSingle;
    Buffer[N].MoveCount := 0;
    Buffer[N].Active := ActiveWhite;
    Buffer[N].TakeChar := WasTake;
    Buffer[N].MoveStr[MoveWriter] := Cell;
    Buffer[N].MoveStr[MoveWriter+1] := -1;
    N := N + 1;
    Result := 1;
  end

end;




// Beta tested 19.05.2002
function GetMovesBlack(N: Integer; var Board: TPosition): Integer;
var
  I: Integer;
  Temp: Integer;
  NextI, NextNextI: Integer;
  SaveDead: ShortInt;
  Direction: TDirection;
  SingleMoves: array[0..1023] of TSingleMoveRec;
begin
  Result := 0;
  DeadCount := 0;
  MoveWriter := 0;
  for I := 0 to 31 do
  begin

    // Ход простой
    if Board.Field[I] = brBlackSingle then
    begin

      // Проверка на взятие вверх влево
      NextI := DirectionTable[drLeftUp, I];
      if (NextI <> -1) and (Board.Field[NextI] > 0) then
      begin
        NextNextI := DirectionTable[drLeftUp, NextI];
        if (NextNextI <> -1) and (Board.Field[NextNextI] = 0) then
        begin
          if Result > 0 then Result := 0;
          Board.Field[I] := 0;
          Dead[DeadCount] := NextI;
          SaveDead := Board.Field[NextI];
          Board.Field[NextI] := brWhiteDead;
          DeadCount := DeadCount + 1;
          Board.MoveStr[MoveWriter] := I;
          MoveWriter := MoveWriter + 1;
          {if NextNextI >= WhiteMamLine} // Оптимизаия --- взятие назад не может привести к дамке
          {  then Result := Result - RecurseMamTakeBlack(N, NextNextI, drLeftDown, Board)}
            {else} Result := Result - RecurseSingleTakeBlack(N, NextNextI, drLeftUp, Board);
          Board.Field[NextI] := SaveDead;
          MoveWriter := MoveWriter - 1;
          DeadCount := DeadCount - 1;
          Board.Field[I] := brBlackSingle;
        end;
      end;

      // Проверка на взятие вверх вправо
      NextI := DirectionTable[drRightUp, I];
      if (NextI <> -1) and (Board.Field[NextI] > 0) then
      begin
        NextNextI := DirectionTable[drRightUp, NextI];
        if (NextNextI <> -1) and (Board.Field[NextNextI] = 0) then
        begin
          if Result > 0 then Result := 0;
          Board.Field[I] := 0;
          Dead[DeadCount] := NextI;
          SaveDead := Board.Field[NextI];
          Board.Field[NextI] := brWhiteDead;
          DeadCount := DeadCount + 1;
          Board.MoveStr[MoveWriter] := I;
          MoveWriter := MoveWriter + 1;
          {if NextNextI >= WhiteMamLine} // Оптимизаия --- взятие назад не может привести к дамке
          {  then Result := Result - RecurseMamTakeBlack(N, NextNextI, drRightDown, Board)}
            {else} Result := Result - RecurseSingleTakeBlack(N, NextNextI, drRightUp, Board);
          Board.Field[NextI] := SaveDead;
          MoveWriter := MoveWriter - 1;
          DeadCount := DeadCount - 1;
          Board.Field[I] := brBlackSingle;
        end;
      end;

      // Ход влево вниз
      NextI := DirectionTable[drLeftDown, I];
      if NextI >= 0 then
      begin
        Temp := Board.Field[NextI];
        if Temp = 0 then // Поле свободно
        begin
          if Result >= 0 then // Не было взятий
          begin
            SingleMoves[Result].PointFrom := I;
            SingleMoves[Result].PointTo := NextI;
            SingleMoves[Result].Counter := 0;
            if NextI <= BlackMamLine
              then SingleMoves[Result].WhatPut := brBlackMam
              else SingleMoves[Result].WhatPut := brBlackSingle;
            Result := Result + 1;
          end
        end
        else begin
          if Temp > 0 then
          begin
            NextNextI := DirectionTable[drLeftDown, NextI];
            if (NextNextI <> -1) and (Board.Field[NextNextI] = 0) then
            begin
              if Result > 0 then Result := 0;
              Board.Field[I] := 0;
              Dead[DeadCount] := NextI;
              SaveDead := Board.Field[NextI];
              Board.Field[NextI] := brWhiteDead;
              DeadCount := DeadCount + 1;
              Board.MoveStr[MoveWriter] := I;
              MoveWriter := MoveWriter + 1;
              if NextNextI <= BlackMamLine
                then Result := Result - RecurseMamTakeBlack(N, NextNextI, drLeftDown, Board)
                else Result := Result - RecurseSingleTakeBlack(N, NextNextI, drLeftDown, Board);
              Board.Field[NextI] := SaveDead;
              MoveWriter := MoveWriter - 1;
              DeadCount := DeadCount - 1;
              Board.Field[I] := brBlackSingle;
            end;
          end;
        end;
      end;

      // Ход вправо вниз
      NextI := DirectionTable[drRightDown, I];
      if NextI >= 0 then
      begin
        Temp := Board.Field[NextI];
        if Temp = 0 then // Поле свободно
        begin
          if Result >= 0 then // Не было взятий
          begin
            SingleMoves[Result].PointFrom := I;
            SingleMoves[Result].PointTo := NextI;
            SingleMoves[Result].Counter := 0;
            if NextI <= BlackMamLine
              then SingleMoves[Result].WhatPut := brBlackMam
              else SingleMoves[Result].WhatPut := brBlackSingle;
            Result := Result + 1;
          end
        end
        else begin
          if Temp > 0 then
          begin
            NextNextI := DirectionTable[drRightDown, NextI];
            if (NextNextI <> -1) and (Board.Field[NextNextI] = 0) then
            begin
              if Result > 0 then Result := 0;
              Board.Field[I] := 0;
              Dead[DeadCount] := NextI;
              SaveDead := Board.Field[NextI];
              Board.Field[NextI] := brWhiteDead;
              DeadCount := DeadCount + 1;
              Board.MoveStr[MoveWriter] := I;
              MoveWriter := MoveWriter + 1;
              if NextNextI <= BlackMamLine
                then Result := Result - RecurseMamTakeBlack(N, NextNextI, drRightDown, Board)
                else Result := Result - RecurseSingleTakeBlack(N, NextNextI, drRightDown, Board);
              Board.Field[NextI] := SaveDead;
              MoveWriter := MoveWriter - 1;
              DeadCount := DeadCount - 1;
              Board.Field[I] := brBlackSingle;
            end;
          end;
        end;
      end;
    end

    // Ход дамкой.
    else if Board.Field[I] = brBlackMam then
    begin
      Board.Field[I] := 0;
      for Direction := Low(TDirection) to High(TDirection) do
      begin
        NextI := DirectionTable[Direction, I];
        repeat
          if NextI = -1 then Break;
          Temp := Board.Field[NextI];
          if Temp = 0 then
          begin
            if Result >= 0 then // Не было взятий
            begin
              SingleMoves[Result].PointFrom := I;
              SingleMoves[Result].PointTo := NextI;
              SingleMoves[Result].Counter := Board.MoveCount + 1;
              SingleMoves[Result].WhatPut := brBlackMam;
              Result := Result + 1;
            end;
            NextI := DirectionTable[Direction, NextI];
          end
          else if Temp >0 then begin
            NextNextI := DirectionTable[Direction, NextI];
            if (NextNextI <> -1) and (Board.Field[NextNextI] = 0) then
            begin
              Dead[DeadCount] := NextI;
              SaveDead := Board.Field[NextI];
              Board.Field[NextI] := brWhiteDead;
              DeadCount := DeadCount + 1;
              Board.MoveStr[MoveWriter] := I;
              MoveWriter := MoveWriter + 1;
              if Result > 0 then Result := 0;
              Result := Result - RecurseMamTakeBlack(N, NextNextI, Direction, Board);
              Board.Field[NextI] := SaveDead;
              MoveWriter := MoveWriter - 1;
              DeadCount := DeadCount - 1;
            end;
            Break;
          end
          else
            Break;
        until False;
      end;
      Board.Field[I] := brBlackMam;
    end;

  end;

  for I := 0 to Result-1 do
  begin
    Buffer[N] := Board;
    Buffer[N].Field[SingleMoves[I].PointFrom] := 0;
    Buffer[N].Field[SingleMoves[I].PointTo] := SingleMoves[I].WhatPut;
    Buffer[N].MoveCount := SingleMoves[I].Counter;
    Buffer[N].Active := ActiveWhite;
    Buffer[N].MoveStr[0] := SingleMoves[I].PointFrom;
    Buffer[N].MoveStr[1] := SingleMoves[I].PointTo;
    Buffer[N].MoveStr[2] := -1;
    Buffer[N].TakeChar := WasNotTake;
    N := N + 1;
  end;

  Result := Abs(Result);
end;



function GetMoves(Position: TPosition; Buf: PPosition; BufSize: Integer): Integer;
var
  TempPosition: TPosition;
begin
  TempPosition := Position;
  if Position.Active = ActiveWhite
    then Result := GetMovesWhite(0,  TempPosition)
    else Result := GetMovesBlack(0,  TempPosition);
  if BufSize > 0 then
    if BufSize > Result
      then Move(Buffer, Buf^, Result*SizeOf(TPosition))
      else Move(Buffer, Buf^, BufSize*SizeOf(TPosition));
end;




function IsMaterialDraw(const Position: TPosition): Boolean;
var
  BMamCount: Integer;
  BSingleCount: Integer;
  WMamCount: Integer;
  WSingleCount: Integer;
  WMamPos: Integer;
  BMamPos: Integer;
  I: Integer;

function Code(WMam, BMam, WSingle, BSingle: Integer): Boolean;
begin
  Result := (WMam = WMamCount)
    and (BMam = BMamCount)
    and (WSingle = WSingleCount)
    and (BSingle = BSingleCount)
end;

function BlackAround(Pos: Integer): Boolean;
var
  Direction: TDirection;
  NextI: Integer;
begin
  Result := False;
  for Direction := Low(TDirection) to High(TDirection) do
  begin
    NextI := Pos;
    repeat
      NextI := DirectionTable[Direction, NextI];
      if NextI = -1 then Break;
      if Position.Field[NextI] < 0 then
      begin
        Result := True;
        Exit;
      end;
    until False; 
  end;
end;

function WhiteAround(Pos: Integer): Boolean;
var
  Direction: TDirection;
  NextI: Integer;
begin
  Result := False;
  for Direction := Low(TDirection) to High(TDirection) do
  begin
    NextI := Pos;
    repeat
      NextI := DirectionTable[Direction, NextI];
      if NextI = -1 then Break;
      if Position.Field[NextI] > 0 then
      begin
        Result := True;
        Exit;
      end;
    until False;
  end;
end;

begin
  BMamCount := 0;
  BSingleCount := 0;
  WMamCount := 0;
  WSingleCount := 0;
  WMamPos := -1; // Make compiler happy
  BMamPos := -1; // Make compiler happy
  for I := 0 to 31 do
  begin
    case Position.Field[I] of
      brWhiteSingle: WSingleCount := WSingleCount + 1;
      brWhiteMam:
        begin
          WMamCount := WMamCount + 1;
          WMamPos := I;
        end;
      brBlackSingle: BSingleCount := BSingleCount + 1;
      brBlackMam:
        begin
          BMamCount := BMamCount + 1;
          BMamPos := I;
        end;  
    end;
  end;
  if Code(1, 1, 0, 0) then Result := not BlackAround(WMamPos) else
  if Code(1, 2, 0, 0) then Result := not BlackAround(WMamPos) else
  if Code(2, 1, 0, 0) then Result := not WhiteAround(BMamPos) else
  if Code(1, 1, 1, 0) then Result := not WhiteAround(BMamPos) else
  if Code(1, 1, 0, 1) then Result := not BlackAround(WMamPos) else
    Result := False;
end;


function GameOver(const Position: TPosition): string;
begin
  if GetMoves(Position, nil, 0) = 0 then
  begin
    if Position.Active = ActiveWhite
      then Result := 'Black win 0-1 (no moves)'
      else Result := 'White win 1-0 (no moves)';
    Exit;
  end;
  if IsMaterialDraw(Position) then
  begin
    Result := 'Draw 1/2-1/2 (material)';
    Exit;
  end;
  if Position.MoveCount > 32 then
  begin
    Result := 'Draw 1/2-1/2 (16 moves rule)';
    Exit;
  end;
end;





// Beta - tested 19.05.2002
procedure InitDirectionTable;
var
  X, Y, C: Integer;
begin
  C := 0;
  for Y := 0 to 7 do
    for X := 0 to 7 do
    begin
      if (X xor Y) and $01 = 0 then // Если поле черное...
      begin
        if (X>0) and (Y<7)
          then DirectionTable[drLeftUp, C] := (X + 8*Y + 7) div 2
          else DirectionTable[drLeftUp, C] :=  -1;
        if (X<7) and (Y<7)
          then DirectionTable[drRightUp, C] := (X + 8*Y + 9) div 2
          else DirectionTable[drRightUp, C] :=  -1;
        if (X>0) and (Y>0)
          then DirectionTable[drLeftDown, C] := (X + 8*Y - 9) div 2
          else DirectionTable[drLeftDown, C] :=  -1;
        if (X<7) and (Y>0)
          then DirectionTable[drRightDown, C] := (X + 8*Y -7) div 2
          else DirectionTable[drRightDown, C] :=  -1;
        C := C + 1;
      end;
    end;
end;




// Beta tested 19.05.2002
procedure SetStartBoard;
var
  I: Integer;
begin
  for I := 0 to 11 do
    StartBoard.Field[I] := brWhiteSingle;
  for I := 20 to 31 do
    StartBoard.Field[I] := brBlackSingle;
  StartBoard.MoveStr[0] := -1;
  StartBoard.MoveCount := 0;
  StartBoard.Active := ActiveWhite;
end;




procedure Init;
begin
  InitDirectionTable;
  SetStartBoard;
end;

procedure Done;
begin
end;

initialization
  Init;

finalization
  Done;

end.


