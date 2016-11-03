unit ServerConfig;

interface

uses System.JSON, LoggerConfig, System.Generics.Collections, rttiObjectsMappers,
  ImageStorage, Storage;

type

  [MapperJSONNaming(JSONNameLowerCase)]
  TRouteMapper = class
  private
    FKey: String;
    FValue: String;
  published
    property Key: String read FKey write FKey;
    property Value: String read FValue write FValue;
  end;

  [MapperJSONNaming(JSONNameLowerCase)]
  TServerConfig = class
  private
    FRoutes: TObjectList<TRouteMapper>;
    FDbStorage: TStorageConfig;
    FRequestHandler: String;
    FLogger: TLoggerConfig;
    FImageStorage: TImageStorageConfig;
  public
    property Logger: TLoggerConfig read FLogger write FLogger;
    [MapperItemsClassType(TRouteMapper)]
    property Routes: TObjectList<TRouteMapper> read FRoutes write FRoutes;
    property dbStorage: TStorageConfig read FDbStorage write FDbStorage;
    property ImageStorage: TImageStorageConfig read FImageStorage write FImageStorage;
    property requestHandler: String read FRequestHandler write FRequestHandler;
    constructor Create(const fileName: String);
    destructor Destroy; override;
  end;

implementation

uses bo.Helpers, System.IOUtils, System.SysUtils, Winapi.Windows;

constructor TServerConfig.Create(const fileName: String);
begin
  if TFile.Exists(fileName, False) then
  begin
    FLogger := TLoggerConfig.Create();
    FRoutes := TObjectList<TRouteMapper>.Create();
    FImageStorage := TImageStorageConfig.Create();
    FDbStorage := TStorageConfig.Create();
    LoadFromJFile(fileName);

    System.Writeln('routes: ' + inttostr(FRoutes.Count));

  end
  else
  begin
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 15 OR BACKGROUND_RED);
    System.Write('Warning:');
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 7);
    System.Write(' Configuration file ');
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 15);
    System.Write(fileName);
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 7);
    System.Writeln(' is not found. Hope to find it later.');
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 7);
  end;

end;

destructor TServerConfig.Destroy;
begin
  FDbStorage.DisposeOf;
  FImageStorage.DisposeOf;
  FRoutes.Clear;
  FRoutes.DisposeOf;
  FLogger.DisposeOf;
end;

end.
