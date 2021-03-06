unit Encrypt;

interface

uses
  System.Hash, System.StrUtils, System.Math;

type
  TEncryptData = class
  private
    FSalt: String;
    FHash: String;
  public
    property Salt: String read FSalt;
    property Hash: String read FHash;
    /// <summary>Create an instance with a given salt and a hash which is
    /// calculated based on given login, password and hash.
    /// For any given salt, the hash should be different for all splittings of
    /// the concatenated string login+password. E.g.: login-password pairs
    /// {user, 1234} and {user1, 234} should have different hashes.</summary>
    constructor Create(const Login, Password, Salt: String);
    /// <summary>Generate a hash of a string.</summary>
    /// <param name="msg">a string which hash is to be generated</param>
    class function generateHash(const msg: String): String;
    /// <summary>Human-read representation of the class instance.
    /// Contains the salt and the hash</summary>
    function ToString: String; override;
  end;

type
  TEncrypt = class
  private
    /// <summary>Generate a random string of given length. Assume that the argument
    /// is a positive integer.</summary>
    class function randomString(const len: Integer): String;
  public
    /// <summary>Encrypt given string. Encryption is supposed to be a one-way one
    /// (without possibility to decrypt) </summary>
    /// <param name="login">user login. Assume non empty</param>
    /// <param name="password">user password. Assume non empty</param>
    /// <param name="saltLength">length of the salt to generate. Assume positive.</param>
    /// <return>Return an object containing the salt of requested length and the login and password hash.</return>
    class function Encrypt(const Login, Password: String; const saltLength: Integer): TEncryptData;

  end;

implementation

uses
  System.SysUtils;

{ TEncrypt }

class function TEncrypt.Encrypt(const Login, Password: String; const saltLength: Integer)
  : TEncryptData;
var
  Salt: String;
begin
  Salt := randomString(saltLength);
  result := TEncryptData.Create(Login, Password, Salt);
end;

class function TEncryptData.generateHash(const msg: String): String;
var
  h2: THashSHA2;
begin
  h2 := THashSHA2.Create(SHA256);
  h2.Update(msg);
  result := h2.HashAsString;
end;

function TEncryptData.ToString: String;
begin
  result := 'salt: "' + Salt + '"' + sLineBreak + 'hash: "' + Hash + '"';
end;

class function TEncrypt.randomString(const len: Integer): String;
const
  pool = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
var
  counter, size, rnd: Integer;
begin
  result := '';
  size := length(pool);
  for counter := 1 to len do
  begin
    Randomize;
    rnd := RandomRange(0, size) + 1;
    result := result + pool[rnd];
  end;
end;

{ TEncryptData }

constructor TEncryptData.Create(const Login, Password, Salt: String);
begin
  FSalt := Salt;
  FHash := generateHash(Login + Salt + Password);
end;

end.
