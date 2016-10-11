unit ServerConfig;

interface

uses System.JSON, LoggerConfig;

type
  TServerConfig = class
  private
    FRoutes: TJSONObject;
    FDbStorage, FImageStorage, FRequestHandler: String;
    FLogger: TLoggerConfig;
  public
    property Logger: TLoggerConfig read FLogger write FLogger;
    property routes: TJSONObject read FRoutes write FRoutes;
    property dbStorage: String read FDbStorage write FDbStorage;
    property imageStorage: String read FImageStorage write FImageStorage;
    property requestHandler: String read FRequestHandler write FRequestHandler;
    constructor Create(const fileName: String);
    destructor Destroy; override;
  end;

implementation

uses bo.Helpers, System.IOUtils, System.SysUtils, Winapi.Windows,
  rttiObjectsMappers;

constructor TServerConfig.Create(const fileName: String);
begin
  if TFile.Exists(fileName, False) then
  begin
    Logger := TLoggerConfig.Create();
    routes := TJSONObject.Create();
    LoadFromJFile(fileName)
  end
  else
  begin
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE),
      15 OR BACKGROUND_RED);
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
  Logger.disposeOf;
  routes.DisposeOf;
end;

end.
