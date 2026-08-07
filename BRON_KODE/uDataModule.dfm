object dmData: TdmData
  OnDestroy = DataModuleDestroy
  Height = 240
  Width = 320
  object conSmartEats: TADOConnection
    LoginPrompt = False
    Mode = cmShareDenyNone
    Provider = 'Microsoft.ACE.OLEDB.16.0'
    Left = 48
    Top = 40
  end
end
