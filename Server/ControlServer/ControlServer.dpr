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

var
  ServerUrl, ServerPortStr, UserAuthFile: String;
  ServerPort: Integer;
  IsServerPortValid, isServerUrlValid, isUserAuthFileValid: Boolean;

begin
  ReportMemoryLeaksOnShutdown := True;
  IsServerPortValid := False;
  isServerUrlValid := False;
  isUserAuthFileValid := False;

  FindCmdLineSwitch(SERVER_URL_SWITCH, ServerUrl, False);
  FindCmdLineSwitch(SERVER_PORT_SWITCH, ServerPortStr, False);
  FindCmdLineSwitch(AUTH_SWITCH, UserAuthFile, False);

  try
    ServerPort := StrToInt(ServerPortStr);
    IsServerPortValid := ServerPort > 0;
  except
    on E: Exception do
    begin
      SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 15);
      Writeln('Warning: port number: "' + ServerPortStr + '" is invalid.', E.Message);
      SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 7);
    end
  end;
  isUserAuthFileValid := TFile.Exists(UserAuthFile);
  isServerUrlValid := NOT(ServerUrl.Trim.IsEmpty());

  if NOT(isUserAuthFileValid) then
  begin
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 16);
    Writeln('Warning: file "' + UserAuthFile + '" is not found.');
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 7);
  end;

  if NOT(IsServerPortValid) then
  begin
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 15);
    Writeln('Port number must be a positive one');
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 7);
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
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 15);
    Writeln('Please, provide valid arguments.');
    Writeln('Usage:' + sLineBreak + ExtractFileName(paramstr(0)) + ' ' + SWITCH_CHAR +
      SERVER_URL_SWITCH + ' <url> ' + SWITCH_CHAR + SERVER_PORT_SWITCH + ' <port> ' + SWITCH_CHAR +
      AUTH_SWITCH + ' <file>' + sLineBreak + 'where ' + sLineBreak +
      '<url> - url of the redirect server,' + sLineBreak +
      '<port> - port number of the redirect server,' + sLineBreak +
      '<file> - file name containing authorization data.');
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 7);
    try
      TServerLauncher.EndServer;
    except
      on E: Exception do
        Writeln('Error when stopping the server: ' + E.Message);
    end;
  end;

end.
