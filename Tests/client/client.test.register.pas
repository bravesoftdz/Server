unit client.test.register;

interface

implementation

uses
  DUnitX.TestFramework,
  clientexample.tests;

initialization

{$IFDEF DEBUG}
  TDUnitX.RegisterTestFixture(TClientExampleTest);
{$ELSE}
  TDUnitX.RegisterTestFixture(TClientExampleTest);
{$ENDIF}

end.
