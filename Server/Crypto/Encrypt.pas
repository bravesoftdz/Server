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
    function randomString(const len: Integer): String;
  public
    /// <summary>Encrypt given string. Encryption is supposed to be a one-way one
    /// (without possibility to decrypt) </summary>
    function Encrypt(const login, password: String; const saltLength: Integer): TEncryptData;
    /// <summary>Generate hash of a password with given salt.</summary>
    function generateHash(const login, password, salt: String): String;

  end;

implementation

uses
  System.SysUtils;

{ TEncrypt }

function TEncrypt.Encrypt(const login, password: String; const saltLength: Integer): TEncryptData;
var
  salt: String;
begin
  salt := randomString(saltLength);
  result := TEncryptData.Create(salt, generateHash(login, password, salt));
end;

function TEncrypt.generateHash(const login, password, salt: String): String;
var
  h2: THashSHA2;
begin
  h2 := THashSHA2.Create(SHA256);
  h2.Update(login + salt + password);
  Result := h2.HashAsString;
end;

function TEncrypt.randomString(const len: Integer): String;
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
