unit server.test.register;

interface

implementation

uses
  StorageTests,
  DUnitX.TestFramework, RouteTests, RedirectServerTests;

initialization

{$IFDEF DEBUG}
  TDUnitX.RegisterTestFixture(TStorageTests);
  TDUnitX.RegisterTestFixture(TRedirectServerTests);
  TDUnitX.RegisterTestFixture(TRouteTests);


{$ELSE}
  TDUnitX.RegisterTestFixture(TStorageTests);
TDUnitX.RegisterTestFixture(TRouteTests);
TDUnitX.RegisterTestFixture(TRedirectServerTests);
{$ENDIF}

end.
