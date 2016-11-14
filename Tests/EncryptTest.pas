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
    [Test]
    [TestCase('Cover: salt length 1', 'user,password,1')]
    [TestCase('Cover: salt length 2', 'user,password,2')]
    [TestCase('Cover: salt length > 2', 'user,password,5')]
    procedure TestGenerateEncryptionSaltOfRequestedLength(const login, pswd: String;
      const len: Integer);

    // Test uniqueness of a hash for a given login, password and salt.
    // Testing strategy: partition the input as follows:
    // 1. salt length: 1, 2, 3 < s <= 100, > 100
    // 2. login + password splitting: 1 + 2 vs 2 + 1, 1 + 50 vs 50 + 1, 1000 + 300 vs 300 + 1000
    [Test]
    [TestCase('Cover: salt 1, split: 1 + 2', '1,1,2')]
    [TestCase('Cover: salt 2, split 1 + 2', '2,1,2')]
    [TestCase('Cover: salt 3..100,  split 1 + 2', '80,1,2')]
    [TestCase('Cover: salt > 100,  split 1 + 2', '200,1,2')]

    [TestCase('Cover: salt 1, split: 1 + 50', '1,1,50')]
    [TestCase('Cover: salt 2, split 1 + 50', '2,1,50')]
    [TestCase('Cover: salt 3..100,  split 1 + 2', '20,1,50')]
    [TestCase('Cover: salt > 100,  split 1 + 2', '300,1,50')]

    [TestCase('Cover: salt 1, split: 1000 + 300', '1,1000,300')]
    [TestCase('Cover: salt 2, split 1000 + 300', '2,1000,300')]
    [TestCase('Cover: salt 3..100,  split 1000 + 300', '20,1000,300')]
    [TestCase('Cover: salt > 100,  split 1000 + 300', '3000,1000,300')]
    procedure TestHashUniqueness(const saltLen, firstPartLength, secondPartLength: Integer);

    // Test a method that generate a hash string.
    // Testing strategy: partition the input as follows:
    // 1. the strings are: different, equal
    // 2. the salts are: different, equal
    [Test]
    [TestCase('Cover: diff, diff', 'string-1, salt-1, string-2, salt-2')
      ]
    [TestCase('Cover: equal, diff', 'String, salt-1, String, salt-2')
      ]
    [TestCase('Cover: diff, equal', 'String-1, salt, String-2, salt')
      ]
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

procedure TMyTestObject.testDifferentInputGivesDifferentHashes(const msg1, salt1, msg2,
  salt2: String);
var
  hash1, hash2: String;
begin
  hash1 := TEncryptData.generateHash(msg1);
  hash2 := TEncryptData.generateHash(msg2);
  Assert.AreNotEqual(hash1, hash2);
end;

procedure TMyTestObject.TestGenerateEncryptionSaltOfRequestedLength(const login, pswd: String;
  const len: Integer);
var
  data: TEncryptData;
begin
  data := TEncrypt.Encrypt(login, pswd, len);
  Assert.AreEqual(len, Length(data.salt));
  data.DisposeOf;

end;

procedure TMyTestObject.TestHashUniqueness(const saltLen, firstPartLength, secondPartLength: Integer);
var
  data1, data2: TEncryptData;
  dumbString, salt, login1, login2, pswd1, pswd2: String;
begin
  salt := StringOfChar('A', saltLen);
  // create a string that is to be split in two ways
  dumbString := StringOfChar('B', firstPartLength + secondPartLength);
  // first splitting
  login1 := Copy(dumbString, 1, firstPartLength);
  pswd1 := Copy(dumbString, firstPartLength + 1, firstPartLength + secondPartLength);
  // second splitting
  login2 := Copy(dumbString, 1, secondPartLength);
  pswd2 := Copy(dumbString, secondPartLength + 1, firstPartLength + secondPartLength);
  // make sure that the splittings are correct
  Assert.AreEqual(login1 + pswd1, login2 + pswd2);
  // create the instances and compare their hashes (should be different)
  data1 := TEncryptData.Create(login1, pswd1, salt);
  data2 := TEncryptData.Create(login2, pswd2, salt);
  Assert.AreNotEqual(data1.Hash, data2.Hash);
  data1.DisposeOf;
  data2.DisposeOf;
end;

initialization

TDUnitX.RegisterTestFixture(TMyTestObject);

end.
