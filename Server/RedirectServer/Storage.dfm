object DMStorage: TDMStorage
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  OnDestroy = DataModuleDestroy
  Height = 461
  Width = 638
  object FDBConn: TFDConnection
    Left = 104
    Top = 40
  end
  object FDQuery1: TFDQuery
    Connection = FDBConn
    Left = 48
    Top = 41
  end
  object FDMoniRemoteClientLink1: TFDMoniRemoteClientLink
    Left = 240
    Top = 168
  end
end
