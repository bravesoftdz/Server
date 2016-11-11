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
    [TestCase('Cover: diff, diff', 'user1, pswd1, salt1, user2, pswd2, salt2')]
    [TestCase('Cover: equal, diff', 'user, pswd1, salt1, user, pswd2, salt2')]
    [TestCase('Cover: diff, equal', 'user1, pswd, salt1, user2, pswd, salt2')]
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

procedure TMyTestObject.testDifferentInputGivesDifferentHashes(const msg1, salt1, msg2, salt2: String);
var
  enc: TEncrypt;
  hash1, hash2: String;
begin
  hash1 := enc.generateHash(msg1, salt1);
  hash2 := enc.generateHash(msg2, salt2);
  Assert.AreNotEqual(hash1, hash2);
end;

initialization

TDUnitX.RegisterTestFixture(TMyTestObject);

end.
