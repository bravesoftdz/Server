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
  Datasnap.DSSession,
  ControlServerDispatcher in 'ControlServerDispatcher.pas',
  MainWebModule in 'MainWebModule.pas' {wbmMain: TWebModule},
  Settings in 'Settings.pas',
  RedirectServerProxy.interfaces in '..\Common\proxies\RedirectServerProxy.interfaces.pas',
  FileBasedAuthentification in 'FileBasedAuthentification.pas',
  InterfaceLoginData in 'InterfaceLoginData.pas',
  LoginData in 'LoginData.pas',
  AuthData in 'AuthData.pas',
  Encrypt in '..\Crypto\Encrypt.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := true;
  TServerLauncher.RunAsConsole(TWebBaseController, TwbmMain);

end.
