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
    // Test a method that generates a hash and salt for a given login and password.
    // Testing strategy: partition the input as follows:
    // 1. salt length: 1, 2, > 2
    // 2. split login + password
    [Test]
    [TestCase('Cover: 1-length salt', '1,user,password')]
    [TestCase('Cover: 2-length salt', '2,user,password')]
    [TestCase('Cover: 5-length salt', '1,user,password')]
    procedure TestGenerateEncryptionSaltOfRequestedLength;
    procedure Test

    // Test a method that generate a hash string.
    // Testing strategy: partition the input as follows:
    // 1. the strings are: different, equal
    // 2. the salts are: different, equal
      [Test][TestCase('Cover: diff, diff', 'string-1, salt-1, string-2, salt-2')
      ][TestCase('Cover: equal, diff', 'String, salt-1, String, salt-2')
      ][TestCase('Cover: diff, equal', 'String-1, salt, String-2, salt')
      ] procedure testDifferentInputGivesDifferentHashes(const msg1, salt1, msg2, salt2: String);
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

procedure TMyTestObject.TestValidEncryption;
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
