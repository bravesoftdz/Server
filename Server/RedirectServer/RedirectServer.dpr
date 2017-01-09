program RedirectServer;
{$APPTYPE CONSOLE}

uses
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  System.SysUtils,
  Winapi.Windows,
  IdHTTPWebBrokerBridge,
  Web.WebReq,
  Web.WebBroker,
  Server.Launcher,
  Controller.webbase,
  Datasnap.DSSession,
  MainWebModule in 'MainWebModule.pas' {wmMain: TWebModule} ,
  RequestHandler in 'RequestHandler.pas',
  Route in 'Route.pas',
  InterfaceRoute in 'InterfaceRoute.pas',
  Storage in 'Storage.pas' {DMStorage: TDataModule} ,
  InterfaceLogger in 'InterfaceLogger.pas',
  MessageCodes in 'MessageCodes.pas',
  Settings in 'Settings.pas',
  RequestClick in 'RequestClick.pas',
  RequestView in 'RequestView.pas',
  Logger in 'Logger.pas',
  RedirectServerDispatcher in 'RedirectServerDispatcher.pas',
  RedirectServerProxy.interfaces in '..\Common\proxies\RedirectServerProxy.interfaces.pas',
  ImageStorage in 'ImageStorage.pas',
  ServerConfig in 'ServerConfig.pas',
  LoggerConfig in 'LoggerConfig.pas',
  InterfaceLoggable in 'InterfaceLoggable.pas', System.IOUtils;

{$R *.res}

const
  ROUTE_FILE = 'r';
  LOGGER_OUT_DIR = 'o';
  LOGGER_MAX_CACHE_SIZE = 'c';
  LOGGER_MAX_CACHE_SIZE_DEFAULT = 10;

  STORAGE_DSN = 'dsn';
  STORAGE_LOGIN = 'l';
  STORAGE_PASSWORD = 'p';
  STORAGE_MAX_CACHE_SIZE = 'd';
  STORAGE_MAX_CACHE_SIZE_DAFAULT = 10;
  IMAGE_POOL_FOLDER = 'i';
  SWITCH_CHAR = '-';
  ERROR_TEXT_COLOR = FOREGROUND_RED or FOREGROUND_INTENSITY;
  WARNING_TEXT_COLOR = FOREGROUND_GREEN or FOREGROUND_INTENSITY;
  DEFAULT_TEXT_COLOR = 7;
  USAGE_ARRAY: TArray < TArray < String >>
    = [[ROUTE_FILE, '<file>', 'path to the file with routes'],
    [LOGGER_OUT_DIR, '<dir>', 'logger directory'], [LOGGER_MAX_CACHE_SIZE, '<log cache>',
    'maximal number of records that the logger may hold in memory before persisting them']];

var
  ConfigFile: String;
  isConfigFileOK: Boolean;

begin
  ReportMemoryLeaksOnShutdown := true;
  isConfigFileOK := False;
  if (FindCmdLineSwitch(ROUTE_FILE, ConfigFile, False)) then
    isConfigFileOK := NOT(String.IsNullOrEmpty(ConfigFile)) AND TFile.exists(ConfigFile);
  if (isConfigFileOK) then
  begin
    TRedirectController.setConfigFile(ConfigFile);
    TServerLauncher.SetPort(80);
    TServerLauncher.RunAsConsole(TWebBaseController, TwmMain);
  end
  else
  begin
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), WARNING_TEXT_COLOR);
    Writeln('Usage:' + sLineBreak + ExtractFileName(paramstr(0)) + ' [' + SWITCH_CHAR + ROUTE_FILE +
      ' <route file>] ' + SWITCH_CHAR + LOGGER_OUT_DIR + ' <dir> ' + SWITCH_CHAR +
      LOGGER_MAX_CACHE_SIZE + ' <log cache> ' + SWITCH_CHAR + STORAGE_DSN + ' <dsn> ' + SWITCH_CHAR
      + STORAGE_LOGIN + ' <login> ' + SWITCH_CHAR + STORAGE_PASSWORD + ' <pswd> [' + SWITCH_CHAR +
      STORAGE_MAX_CACHE_SIZE + ' <storage cache>] ' + SWITCH_CHAR + IMAGE_POOL_FOLDER +
      ' <image pool>' + sLineBreak + 'where ' + sLineBreak +
      '<route file> - path to the file with routes,' + sLineBreak + '<dir> - logger directory' +
      sLineBreak +
      '<log cache> - maximal number of records that the logger may hold in memory before persisting them'
      + sLineBreak +
      '<dsn> - database source name of the storage, i.e: mysql:host=192.168.1.1;dbname=statistics' +
      sLineBreak + '<login> - login to access the storage' + sLineBreak +
      '<pswd> - password to access the storage' + sLineBreak +
      '<storage cache> - maximal number of records that the storage may hold in memory before persisting them'
      + sLineBreak + '<image pool> - an image folder.');
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), DEFAULT_TEXT_COLOR);
    try
      TServerLauncher.EndServer;
    except
      on E: Exception do
      begin
        SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 15 OR BACKGROUND_RED);
        Writeln('Error when stopping the server: ' + E.Message);
        SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), DEFAULT_TEXT_COLOR);
      end;

    end;

  end;

end.
