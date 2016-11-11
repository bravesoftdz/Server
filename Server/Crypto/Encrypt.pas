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
    property salt: String read FSalt;
    property Hash: String read FHash;
    constructor Create(const salt, Hash: String);
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
    class function Encrypt(const login, password: String; const saltLength: Integer): TEncryptData;
    /// <summary>Generate a "salted" hash of a string. For any pair
    /// of different input it must generate different output strings.
    /// </summary>
    /// <param name="msg">a string which hash is to be generated</param>
    /// <param name="salt">a salt</param>
    class function generateHash(const msg, salt: String): String;

  end;

implementation

uses
  System.SysUtils;

{ TEncrypt }

class function TEncrypt.Encrypt(const login, password: String; const saltLength: Integer)
  : TEncryptData;
var
  salt: String;
begin
  salt := randomString(saltLength);
  result := TEncryptData.Create(salt, generateHash(login + password, salt));
end;

class function TEncrypt.generateHash(const msg, salt: String): String;
var
  h2: THashSHA2;
begin
  h2 := THashSHA2.Create(SHA256);
  h2.Update(msg + salt);
  result := h2.HashAsString;
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

constructor TEncryptData.Create(const salt, Hash: String);
begin
  FSalt := salt;
  FHash := Hash;
end;

end.
