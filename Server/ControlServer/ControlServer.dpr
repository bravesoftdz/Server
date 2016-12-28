{ A control server launcher.
  It is a console program and it requires that arguments (such as server url,
  port number and a file containing authorisations) are given. See the usage
  string for details. }
program ControlServer;
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
  Datasnap.DSSession, MVCFramework.RESTAdapter,
  ControlServerDispatcher in 'ControlServerDispatcher.pas',
  MainWebModule in 'MainWebModule.pas' {wbmMain: TWebModule} ,
  Settings in 'Settings.pas',
  RedirectServerProxy.interfaces in '..\Common\proxies\RedirectServerProxy.interfaces.pas',
  FileBasedAuthentification in 'FileBasedAuthentification.pas',
  InterfaceLoginData in 'InterfaceLoginData.pas',
  LoginData in 'LoginData.pas',
  AuthData in 'AuthData.pas',
  Encrypt in '..\Crypto\Encrypt.pas', System.IOUtils;

{$R *.res}

const
  SERVER_URL_SWITCH = 'u';
  SERVER_PORT_SWITCH = 'p';
  AUTH_SWITCH = 'a';
  SWITCH_CHAR = '-';
  ERROR_TEXT_COLOR = FOREGROUND_RED or FOREGROUND_INTENSITY;
  WARNING_TEXT_COLOR = FOREGROUND_GREEN or FOREGROUND_INTENSITY;
  DEFAULT_TEXT_COLOR = 7;

var
  ServerUrl, ServerPortStr, UserAuthFile: String;
  ServerPort: Integer;
  IsServerPortValid, isServerUrlValid, isUserAuthFileValid: Boolean;

begin
  ReportMemoryLeaksOnShutdown := True;

  FindCmdLineSwitch(SERVER_URL_SWITCH, ServerUrl, False);
  FindCmdLineSwitch(SERVER_PORT_SWITCH, ServerPortStr, False);
  FindCmdLineSwitch(AUTH_SWITCH, UserAuthFile, False);

  isUserAuthFileValid := TFile.Exists(UserAuthFile);
  isServerUrlValid := NOT(ServerUrl.Trim.IsEmpty());

  try
    ServerPort := StrToInt(ServerPortStr);
    IsServerPortValid := ServerPort > 0;
  except
    on E: Exception do
    begin
      IsServerPortValid := False;
      SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), ERROR_TEXT_COLOR);
      Writeln('Error: ' + E.Message);
      SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), DEFAULT_TEXT_COLOR);
    end
  end;

  if NOT(isUserAuthFileValid) then
  begin
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), ERROR_TEXT_COLOR);
    Writeln('Error: file "' + UserAuthFile + '" is not found.');
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), DEFAULT_TEXT_COLOR);
  end;

  if NOT(IsServerPortValid) then
  begin
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), ERROR_TEXT_COLOR);
    Writeln('Error: port number must be positive integer.');
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), DEFAULT_TEXT_COLOR);
  end;

  if isUserAuthFileValid AND isServerUrlValid AND IsServerPortValid then
  begin
    TControlServerController.Authentication := TFileBasedAuthentification.Create(UserAuthFile);
    TControlServerController.RESTAdapter := TRESTAdapter<IRedirectServerProxy>.Create;
    TControlServerController.WebResource := TControlServerController.RESTAdapter.Build(ServerUrl,
      ServerPort);
    TServerLauncher.RunAsConsole(TWebBaseController, TwbmMain);
  end
  else
  begin
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), WARNING_TEXT_COLOR);
    Writeln('Usage:' + sLineBreak + ExtractFileName(paramstr(0)) + ' ' + SWITCH_CHAR +
      SERVER_URL_SWITCH + ' <url> ' + SWITCH_CHAR + SERVER_PORT_SWITCH + ' <port> ' + SWITCH_CHAR +
      AUTH_SWITCH + ' <file>' + sLineBreak + 'where ' + sLineBreak +
      '<url> - url of the redirect server,' + sLineBreak +
      '<port> - port number of the redirect server,' + sLineBreak +
      '<file> - file name containing authorization data.');
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), DEFAULT_TEXT_COLOR);
    try
      TServerLauncher.EndServer;
    except
      on E: Exception do
        Writeln('Error when stopping the server: ' + E.Message);
    end;
  end;

end.
