unit server.test.register;

interface

implementation

uses
  StorageTests,
  DUnitX.TestFramework, RouteTests;

initialization

{$IFDEF DEBUG}
  TDUnitX.RegisterTestFixture(TStorageTests);
TDUnitX.RegisterTestFixture(TRouteTests);

{$ELSE}
  TDUnitX.RegisterTestFixture(TStorageTests);
TDUnitX.RegisterTestFixture(TRouteTests);
{$ENDIF}

end.
