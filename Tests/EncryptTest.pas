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

    // Test method that generate a hash string.
    // Testing strategy: partition the input as follows:
    // 1. the strings are: different, equal
    // 2. the salts are: different, equal
    [Test]
    [TestCase('Cover: diff, diff', 'string-1, salt-1, string-2, salt-2')]
    [TestCase('Cover: equal, diff', 'String, salt-1, String, salt-2')]
    [TestCase('Cover: diff, equal', 'String-1, salt, String-2, salt')]
    procedure testDifferentInputGivesDifferentHashes(const msg1, salt1, msg2, salt2: String);
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

procedure TMyTestObject.testDifferentInputGivesDifferentHashes(const msg1, salt1, msg2,
  salt2: String);
var
  hash1, hash2: String;
begin
  hash1 := TEncrypt.generateHash(msg1, salt1);
  hash2 := TEncrypt.generateHash(msg2, salt2);
  Assert.AreNotEqual(hash1, hash2);
end;

initialization

TDUnitX.RegisterTestFixture(TMyTestObject);

end.
