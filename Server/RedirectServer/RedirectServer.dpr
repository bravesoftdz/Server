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
  SERVER_CONFIG_SWITCH = 'c';
  SWITCH_CHAR = '-';
  ERROR_TEXT_COLOR = FOREGROUND_RED or FOREGROUND_INTENSITY;
  WARNING_TEXT_COLOR = FOREGROUND_GREEN or FOREGROUND_INTENSITY;
  DEFAULT_TEXT_COLOR = 7;

var
  ConfigFile: String;
  isConfigFileOK: Boolean;

begin
  ReportMemoryLeaksOnShutdown := true;
  isConfigFileOK := False;
  if (FindCmdLineSwitch(SERVER_CONFIG_SWITCH, ConfigFile, False)) then
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
    Writeln('Usage:' + sLineBreak + ExtractFileName(paramstr(0)) + ' ' + SWITCH_CHAR +
      SERVER_CONFIG_SWITCH + ' <config file> ' + sLineBreak + 'where ' + sLineBreak +
      '<config file> - path to the configuration file.');
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), DEFAULT_TEXT_COLOR);
    try
      TServerLauncher.EndServer;
    except
      on E: Exception do
        // begin
        // SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 15 OR BACKGROUND_RED);
        Writeln('Error when stopping the server: ' + E.Message);
      // SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), DEFAULT_TEXT_COLOR);
      // end;

    end;

  end;

end.
