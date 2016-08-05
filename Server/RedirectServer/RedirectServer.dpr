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
  MainWebModule in 'MainWebModule.pas' {wmMain: TWebModule},
  RequestHandler in 'RequestHandler.pas',
  Route in 'Route.pas',
  InterfaceRoute in 'InterfaceRoute.pas',
  Storage in 'Storage.pas' {DMStorage: TDataModule},
  InterfaceAuthentication in 'InterfaceAuthentication.pas',
  InterfaceLogger in 'InterfaceLogger.pas',
  MessageCodes in 'MessageCodes.pas',
  Settings in 'Settings.pas' {$R *.res},
  RequestClick in 'RequestClick.pas',
  RequestView in 'RequestView.pas' {$R *.res},
  Logger in 'Logger.pas' {$R *.res},
  RedirectServerDispatcher in 'RedirectServerDispatcher.pas' {$R *.res},
  RedirectServerProxy.interfaces in '..\Common\proxies\RedirectServerProxy.interfaces.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := true;
  TServerLauncher.SetPort(80);
  TServerLauncher.RunAsConsole(TWebBaseController, TwmMain);

end.
