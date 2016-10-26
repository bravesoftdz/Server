unit Encrypt;

interface

uses
  System.Hash, System.StrUtils, System.Math;

type
  TEncrypt = class
  private
    /// <summary>Generate a random string of given length. Assume that the argument
    /// is a positive integer.</summary>
    function randomString(const len: Integer): String;
  public
    /// <summary>Encrypt given string. Encryption is supposed to be a one-way one
    /// (without possibility to decrypt) </summary>
    function Encrypt(const msg: String; const saltLength: Integer): String;

  end;

implementation

uses
  System.SysUtils;

{ TEncrypt }

function TEncrypt.Encrypt(const msg: String; const saltLength: Integer): String;
var
  h2: THashSHA2;
  salt: String;
begin
  salt := randomString(saltLength);
  System.Writeln('salt:  ' + salt);
  h2 := THashSHA2.Create(SHA256);
  h2.Update(salt + msg);
  result := h2.HashAsString;
end;

function TEncrypt.randomString(const len: Integer): String;
const
  pool = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
var
  counter, size, rnd: Integer;
begin
  result := '';
  size := length(pool);
  rnd := RandomRange(1, size);
  for counter := 0 to len do
  begin
    rnd := RandomRange(1, size);
    Randomize;
    result := result + pool[RandomRange(1, size)];
  end;
end;

end.
