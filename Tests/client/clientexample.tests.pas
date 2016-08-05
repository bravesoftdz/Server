unit clientexample.tests;

interface

uses
  DUnitX.TestFramework;

type

  [TestFixture]
  TClientExampleTest = class(TObject)
  private
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [TEST]
    procedure Test1;
  end;

implementation

{ TServerTests }

procedure TClientExampleTest.Setup;
begin

end;

procedure TClientExampleTest.TearDown;
begin

end;

procedure TClientExampleTest.Test1;
begin

end;


end.
