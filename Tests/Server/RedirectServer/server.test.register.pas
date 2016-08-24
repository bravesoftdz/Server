unit server.test.register;

interface

implementation

uses
  StorageTests,
  DUnitX.TestFramework, RouteTests, RedirectServerTests, LoggerTests;

initialization

{$IFDEF DEBUG}
  TDUnitX.RegisterTestFixture(TStorageTests);
TDUnitX.RegisterTestFixture(TRedirectServerTests);
TDUnitX.RegisterTestFixture(TRouteTests);
TDUnitX.RegisterTestFixture(TLoggerTests);

{$ELSE}
  TDUnitX.RegisterTestFixture(TStorageTests);
TDUnitX.RegisterTestFixture(TRouteTests);
TDUnitX.RegisterTestFixture(TRedirectServerTests);
TDUnitX.RegisterTestFixture(TLoggerTests);
{$ENDIF}

end.
