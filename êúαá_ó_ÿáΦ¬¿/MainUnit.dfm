object MainForm: TMainForm
  Left = 236
  Top = 134
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = #1048#1075#1088#1072' '#1074' '#1064#1072#1096#1082#1080
  ClientHeight = 328
  ClientWidth = 561
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -14
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Icon.Data = {
    0000010001002020100000000000E80200001600000028000000200000004000
    0000010004000000000080020000000000000000000000000000000000000000
    0000000080000080000000808000800000008000800080800000C0C0C0008080
    80000000FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00CCC0
    000CCCC0000000000CCCC7777CCCCCCC0000CCCC00000000CCCC7777CCCCCCCC
    C0000CCCCCCCCCCCCCC7777CCCCC0CCCCC0000CCCCCCCCCCCC7777CCCCC700CC
    C00CCCC0000000000CCCC77CCC77000C0000CCCC00000000CCCC7777C7770000
    00000CCCC000000CCCC777777777C000C00000CCCC0000CCCC77777C777CCC00
    CC00000CCCCCCCCCC77777CC77CCCCC0CCC000CCCCC00CCCCC777CCC7CCCCCCC
    CCCC0CCCCCCCCCCCCCC7CCCCCCCCCCCC0CCCCCCCCCCCCCCCCCCCCCC7CCC70CCC
    00CCCCCCCC0CC0CCCCCCCC77CC7700CC000CCCCCC000000CCCCCC777CC7700CC
    0000CCCC00000000CCCC7777CC7700CC0000C0CCC000000CCC7C7777CC7700CC
    0000C0CCC000000CCC7C7777CC7700CC0000CCCC00000000CCCC7777CC7700CC
    000CCCCCC000000CCCCCC777CC7700CC00CCCCCCCC0CC0CCCCCCCC77CC770CCC
    0CCCCCCCCCCCCCCCCCCCCCC7CCC7CCCCCCCC0CCCCCCCCCCCCCC7CCCCCCCCCCC0
    CCC000CCCCC00CCCCC777CCC7CCCCC00CC00000CCCCCCCCCC77777CC77CCC000
    C00000CCCC0000CCCC77777C777C000000000CCCC000000CCCC777777777000C
    0000CCCC00000000CCCC7777C77700CCC00CCCC0000000000CCCC77CCC770CCC
    CC0000CCCCCCCCCCCC7777CCCCC7CCCCC0000CCCCCCCCCCCCCC7777CCCCCCCCC
    0000CCCC00000000CCCC7777CCCCCCC0000CCCC0000000000CCCC7777CCC0000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    000000000000000000000000000000000000000000000000000000000000}
  Menu = MainMenu
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  OnShow = FormShow
  PixelsPerInch = 120
  TextHeight = 16
  inline PositionFrame: TPositionFrame
    Left = 8
    Top = 8
    Width = 329
    Height = 257
    TabOrder = 0
    inherited Image: TImage
      Width = 329
      Height = 257
    end
  end
  object Memo: TMemo
    Left = 8
    Top = 272
    Width = 545
    Height = 49
    Enabled = False
    Lines.Strings = (
      'Memo')
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 1
  end
  object PartyView: TListView
    Left = 344
    Top = 8
    Width = 209
    Height = 257
    Columns = <
      item
        Caption = '#'
        Width = 62
      end
      item
        Caption = 'White'
        Width = 62
      end
      item
        Caption = 'Black'
        Width = 62
      end>
    ReadOnly = True
    RowSelect = True
    TabOrder = 2
    ViewStyle = vsReport
  end
  object MainMenu: TMainMenu
    Left = 105
    Top = 102
    object GameMenu: TMenuItem
      Tag = 60
      Caption = '&Game'
      ShortCut = 16451
      OnClick = CopyGameActionExecute
      object NewItem: TMenuItem
        Action = NewGameAction
      end
      object Separator1: TMenuItem
        Caption = '-'
      end
      object BeginerItem: TMenuItem
        Tag = 20
        Action = BeginerAction
        GroupIndex = 2
        RadioItem = True
      end
      object IntermediateItem: TMenuItem
        Tag = 55
        Action = IntermediateAction
        GroupIndex = 2
        RadioItem = True
      end
      object ExpertItem: TMenuItem
        Tag = 60
        Action = ExpertAction
        GroupIndex = 2
        RadioItem = True
      end
      object Separator2: TMenuItem
        Caption = '-'
        GroupIndex = 2
      end
      object UndoMoveItem: TMenuItem
        Action = UndoMoveAction
        GroupIndex = 2
      end
      object CopyGameItem: TMenuItem
        Action = CopyGameAction
        GroupIndex = 2
      end
      object Separator4: TMenuItem
        Caption = '-'
        GroupIndex = 2
      end
      object ExitItem: TMenuItem
        Action = ExitAction
        GroupIndex = 2
      end
    end
    object ModeMenu: TMenuItem
      Caption = '&Mode'
      object MachineWhiteItem: TMenuItem
        Action = MachineWhiteAction
        GroupIndex = 1
        RadioItem = True
      end
      object MachineBlackItem: TMenuItem
        Action = MachineBlackAction
        GroupIndex = 1
        RadioItem = True
      end
      object TwoMachineItem: TMenuItem
        Action = TwoMachineAction
        GroupIndex = 1
        RadioItem = True
      end
      object ViewItem: TMenuItem
        Action = ViewGameAction
        GroupIndex = 1
        RadioItem = True
      end
      object Separator3: TMenuItem
        Caption = '-'
        GroupIndex = 1
      end
      object FlipBoardItem: TMenuItem
        Action = FlipBoardAction
        GroupIndex = 1
      end
    end
    object DebugMenu: TMenuItem
      Caption = 'Debug'
      Visible = False
      object SetPositionItem: TMenuItem
        Action = SetPositionAction
      end
      object AddToLibraryItem: TMenuItem
        Action = AddToLibraryAction
      end
    end
  end
  object ActionList: TActionList
    OnUpdate = ActionListUpdate
    Left = 144
    Top = 159
    object NewGameAction: TAction
      Category = 'Game'
      Caption = '&New'
      ShortCut = 113
      OnExecute = NewGameActionExecute
    end
    object BeginerAction: TAction
      Tag = 20
      Category = 'Level'
      Caption = '&Beginer'
      OnExecute = LevelActionExecute
    end
    object IntermediateAction: TAction
      Tag = 40
      Category = 'Level'
      Caption = '&Intermediate'
      OnExecute = LevelActionExecute
    end
    object ExpertAction: TAction
      Tag = 60
      Category = 'Level'
      Caption = '&Expert'
      OnExecute = LevelActionExecute
    end
    object UndoMoveAction: TAction
      Category = 'Game'
      Caption = '&Undo move'
      ShortCut = 8
      OnExecute = UndoMoveActionExecute
    end
    object ExitAction: TAction
      Category = 'Game'
      Caption = 'E&xit'
      ShortCut = 32856
      OnExecute = ExitActionExecute
    end
    object MachineWhiteAction: TAction
      Category = 'Mode'
      Caption = 'Machine &white'
      OnExecute = MachineWhiteActionExecute
    end
    object MachineBlackAction: TAction
      Category = 'Mode'
      Caption = 'Machine &black'
      OnExecute = MachineBlackActionExecute
    end
    object TwoMachineAction: TAction
      Category = 'Mode'
      Caption = '&Two machine'
      OnExecute = TwoMachineActionExecute
    end
    object ViewGameAction: TAction
      Category = 'Mode'
      Caption = '&View game'
      OnExecute = ViewGameActionExecute
    end
    object FlipBoardAction: TAction
      Caption = '&Flip board'
      ShortCut = 114
      OnExecute = FlipBoardActionExecute
    end
    object SetPositionAction: TAction
      Category = 'Debug'
      Caption = 'Set position'
      OnExecute = SetPositionActionExecute
    end
    object AddToLibraryAction: TAction
      Category = 'Debug'
      Caption = 'Add to library'
      ShortCut = 49217
      OnExecute = AddToLibraryActionExecute
    end
    object CopyGameAction: TAction
      Category = 'Game'
      Caption = 'Copy game'
      ShortCut = 16451
      OnExecute = CopyGameActionExecute
    end
  end
end
