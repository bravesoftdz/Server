unit EncryptTest;

interface

uses
  DUnitX.TestFramework;

type

  [TestFixture]
  TMyTestObject = class(TObject)
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    // Sample Methods
    // Simple single Test
    [Test]
    procedure Test1;
    // Test with TestCase Attribute to supply parameters.
    // Test method that generate a hash string.
    // Testing strategy: partition the input as follows:
    // 1.
    [Test]
    [TestCase('TestA', '1,2')]
    [TestCase('TestB', '3,4')]
    procedure Test2(const AValue1: Integer; const AValue2: Integer);
  end;

implementation

uses
  Encrypt;

procedure TMyTestObject.Setup;
begin
end;

procedure TMyTestObject.TearDown;
begin
end;

procedure TMyTestObject.Test1;
begin

end;

procedure TMyTestObject.Test2(const AValue1: Integer; const AValue2: Integer);
var
  enc: TEncrypt;
  hash1, hash2: String;
begin
  enc.generateHash()
end;

initialization

TDUnitX.RegisterTestFixture(TMyTestObject);

end.
