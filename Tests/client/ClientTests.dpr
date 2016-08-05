program ClientTests;

{$APPTYPE CONSOLE}

uses
  Firedac.Dapt,
  SysUtils,
  Server.Launcher,
  MainWebModule,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  Controller.webbase,
  client.test.init in 'client.test.init.pas',
  client.test.register in 'client.test.register.pas',
  clientexample.tests in 'clientexample.tests.pas';

var
  runner: ITestRunner;
  results: IRunResults;
  logger: ITestLogger;
  nunitLogger: ITestLogger;
  s: string;

begin

{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := true;
{$ENDIF}
  TServerLauncher.RunInSeparateThread(5500, TWebBaseController, TwmMain);
  try
    // Check command line options, will exit if invalid
    TDUnitX.CheckCommandLine;
    // Create the test runner
    runner := TDUnitX.CreateRunner;
    // Tell the runner to use RTTI to find Fixtures
    // runner.UseRTTI := true;
    // tell the runner how we will log things
    // Log to the console window
    logger := TDUnitXConsoleLogger.Create(true);
    runner.AddLogger(logger);
    // Generate an NUnit compatible XML File
    nunitLogger := TDUnitXXMLNUnitFileLogger.Create
      (TDUnitX.Options.XMLOutputFile);
    runner.AddLogger(nunitLogger);
    // Run tests
    results := runner.Execute;
{$IFNDEF CI}
    ReportMemoryLeaksOnShutdown := true;
    s := '';
    repeat
      // We don't want this happening when running under CI.
      if s.ToLower.Equals('r') then
        results := runner.Execute;
      System.Write('Done.. press <Enter> key to quit.');
      System.Read(s);
    until not s.ToLower.Equals('r');
{$ENDIF}
    TServerLauncher.EndServer;
    if not results.AllPassed then
      ExitCode:=100;

  except
{$IFNDEF CI}
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
{$ELSE}
    raise;

{$ENDIF}
  end;


end.
