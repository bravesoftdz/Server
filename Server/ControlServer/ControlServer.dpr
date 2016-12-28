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

  if FindCmdLineSwitch(SERVER_URL_SWITCH, ServerUrl, False) AND
    FindCmdLineSwitch(SERVER_PORT_SWITCH, ServerPortStr, False) AND
    FindCmdLineSwitch(AUTH_SWITCH, UserAuthFile, False) then
  begin
    ServerPort := -1;
    try
      ServerPort := StrToInt(ServerPortStr);
      IsServerPortValid := ServerPort > 0;
    except
      on E: Exception do
      begin
        SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 15);
        Writeln('Invalid port number: ' + ServerPortStr, E.Message);
        SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 7);
      end
    end;
    isUserAuthFileValid := TFile.Exists(UserAuthFile);
    isServerUrlValid := NOT(ServerUrl.IsNullOrWhiteSpace());
    if ServerPort > 0 then
    begin
      if TFile.Exists(UserAuthFile) then
      begin
        TControlServerController.Authentication := TFileBasedAuthentification.Create(UserAuthFile);
        TControlServerController.RESTAdapter := TRESTAdapter<IRedirectServerProxy>.Create;
        TControlServerController.WebResource := TControlServerController.RESTAdapter.Build
          (ServerUrl, ServerPort);
        TServerLauncher.RunAsConsole(TWebBaseController, TwbmMain);
      end
      else
      begin
        SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 15);
        Writeln('File ' + UserAuthFile + ' is not found');
        SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 7);
        TServerLauncher.EndServer;
      end;
    end
    else
    begin
      SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 15);
      Writeln('Port number must be a positive one');
      SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 7);
    end;
  end
  else
  begin
    Writeln('Usage:' + sLineBreak + ExtractFileName(paramstr(0)) + ' ' + SWITCH_CHAR +
      SERVER_URL_SWITCH + ' <url> ' + SWITCH_CHAR + SERVER_PORT_SWITCH + ' <port> ' + SWITCH_CHAR +
      AUTH_SWITCH + ' <file>' + sLineBreak + 'where ' + sLineBreak +
      '<url> - url of the redirect server,' + sLineBreak +
      '<port> - port number of the redirect server,' + sLineBreak +
      '<file> - file name containing authorization data.');
    TServerLauncher.EndServer;
  end;

end.
