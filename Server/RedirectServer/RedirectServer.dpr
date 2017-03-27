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
  InterfaceLoggable in 'InterfaceLoggable.pas',

  System.Generics.Collections, System.IOUtils;

{$R *.res}


/// <summary>An immutable type to represent errors in using command line parameters</summary>
type
  TParamError = class
  strict private
    FMsg: String;
  public
    constructor Create(const Msg: String);
    property Msg: String read FMsg;

  end;

  /// <summary>An immutable class to represent a comand line parameter, its meaning and usage</summary>
type
  TCliParam = class
  strict private
    FSwitchString: String;
    FTag: String;
    FDescr: String;
    FIsRequired: Boolean;
    FCliUsage: String;
    FExplanation: String;
  public
    constructor Create(const SwitchString, Tag, Descr: String; const IsRequired: Boolean);
    /// a switch corresponding to the parameter
    property SwitchString: String read FSwitchString;
    /// a tag corresponding to the parameter
    property Tag: String read FTag;
    /// usage  description
    property Description: String read FDescr;
    /// whether the parameter is required or optional
    property IsRequired: Boolean read FIsRequired;
    /// string describing the usage of the parameter in the command line
    property CliUsage: String read FCliUsage;
    /// explanation of what the parameter means
    property Explanation: String read FExplanation;

  end;

const
  PORT_NUM = 'p';
  PORT_NUM_DEFAULT = 80;
  ROUTE_FILE = 'r';
  LOGGER_OUT_DIR = 'o';
  LOGGER_MAX_CACHE_SIZE = 'c';
  LOGGER_MAX_CACHE_SIZE_DEFAULT = 10;
  STORAGE_DSN = 'dsn';
  STORAGE_LOGIN = 'l';
  STORAGE_PASSWORD = 'p';
  STORAGE_MAX_CACHE_SIZE = 'd';
  STORAGE_MAX_CACHE_SIZE_DEFAULT = 10;
  IMAGE_POOL_FOLDER = 'i';
  SWITCH_CHAR = '-';
  ERROR_TEXT_COLOR = FOREGROUND_RED or FOREGROUND_INTENSITY;
  WARNING_TEXT_COLOR = FOREGROUND_GREEN or FOREGROUND_INTENSITY;
  DEFAULT_TEXT_COLOR = 7;

var
  RouteFile: String;
  Item: TCliParam;
  usage, explanation: String;
  UsageParams: TArray<TCliParam>;
  PortNumberStr: String;
  PortNum: Integer;
  ErrorList: TList<TParamError>;

  { TArgument }

  { TComandLineParam }

constructor TCliParam.Create(const SwitchString, Tag, Descr: String;
  const IsRequired: Boolean);
const
  OPEN_TAG = '<';
  CLOSE_TAG = '>';
begin
  FSwitchString := SwitchString;
  FDescr := Descr;
  FTag := Tag;
  FIsRequired := IsRequired;
  FCliUsage := '-' + FSwitchString + ' ' + OPEN_TAG + FTag + CLOSE_TAG;
  if Not(FIsRequired) then
    FCliUsage := '[' + FCliUsage + ']';
  FExplanation := OPEN_TAG + FTag + CLOSE_TAG + ' - ' + FDescr;
end;

{ TParamError }

constructor TParamError.Create(const Msg: String);
begin
  FMsg := Msg;
end;

begin
  ReportMemoryLeaksOnShutdown := true;
  UsageParams := [
    TCliParam.Create(PORT_NUM, 'port', 'port on which this server runs', False),
    TCliParam.Create(ROUTE_FILE, 'routes', 'path to the file with routes', True),
    TCliParam.Create(STORAGE_DSN, 'dsn', 'database source name of the storage, i.e: mysql:host=192.168.1.1;dbname=statistics', True),
    TCliParam.Create(STORAGE_LOGIN, 'login', 'login name to access the storage', True),
    TCliParam.Create(STORAGE_PASSWORD, 'pswd', 'password to access the storage', True),
    TCliParam.Create(IMAGE_POOL_FOLDER, 'image pool', 'path to the image folder', True),
    TCliParam.Create(LOGGER_OUT_DIR, 'log dir', 'logger output folder', False),
    TCliParam.Create(LOGGER_MAX_CACHE_SIZE, 'log cache size', 'maximal number of records that the logger may hold in memory before persisting them', False),
    TCliParam.Create(STORAGE_MAX_CACHE_SIZE, 'storage cache size', 'maximal number of records that the storage may hold in memory before persisting them', False)
    ];

  ErrorList := Tlist<TParamError>.Create;
  // control whether the port number is set correctly
  if (FindCmdLineSwitch(PORT_NUM, PortNumberStr, False)) then
  begin
    try
      PortNum := Strtoint(PortNumberStr);
    except
      on E: Exception do
        ErrorList.add(TParamError.create('Wrong port number: ' + E.Message));
    end;
  end
  else
  begin
    PortNum := PORT_NUM_DEFAULT;
  end;

  // control whether the route file is set up correctly
  if (Not(FindCmdLineSwitch(ROUTE_FILE, RouteFile, False))) then
  begin
    ErrorList.add(TParamError.create('No route file is given.'));
  end
  else
  begin
    if (String.IsNullOrEmpty(RouteFile) OR NOT(TFile.exists(RouteFile))) then
    begin
      ErrorList.add(TParamError.create('Route file "' + RouteFile + '"  is not found.'));
    end;

  end;

  if (ErrorList.Count = 0) then
  begin
    TRedirectController.setConfigFile(RouteFile);
    TServerLauncher.SetPort(PortNum);
    TServerLauncher.RunAsConsole(TWebBaseController, TwmMain);
  end
  else
  begin
    usage := 'Usage:' + sLineBreak + ExtractFileName(paramstr(0));
    explanation := '';
    for Item in UsageParams do
    begin
      usage := usage + ' ' + Item.CliUsage;
      explanation := explanation + item.Explanation + sLineBreak;
    end;
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), WARNING_TEXT_COLOR);
    Writeln(usage);
    Writeln('where:');
    Writeln(explanation);
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
