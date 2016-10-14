object DMStorage: TDMStorage
  OldCreateOrder = False
  OnDestroy = DataModuleDestroy
  Height = 461
  Width = 638
  object FDBConn: TFDConnection
    Params.Strings = (
      'Server=192.168.5.45'
      'Database=advlite_dev'
      'User_Name=abc'
      'DriverID=MySQL')
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
