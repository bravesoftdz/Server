unit Encrypt;

interface

uses
  System.Hash, System.StrUtils;

type
  TEncrypt = class
  public
    /// <summary>Encrypt given string. Encryption is supposed to be a one-way one
    /// (without possibility to decrypt) </summary>
    function Encrypt(const msg: String): String;

  end;

implementation

{ TEncrypt }

function TEncrypt.Encrypt(const msg: String): String;
var
  h2: THashSHA2;
  salt: String;
begin
  salt := ansireversestring(msg);
  h2 := THashSHA2.Create(SHA256);
  h2.Update(salt + msg);
  result := h2.HashAsString;
end;


end.
