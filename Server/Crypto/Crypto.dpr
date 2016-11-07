program Crypto;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  Encrypt in 'Encrypt.pas';

var
  cipher: TEncrypt;
  encryptData: TEncryptData;
  login, password: String;
  saltLength: Integer;

begin
  cipher := TEncrypt.Create();
  try
    if ParamCount >= 3 then
    begin
      login := paramstr(1);
      password := paramstr(2);
      saltLength := StrToInt(paramstr(3));
      encryptData := cipher.Encrypt(login, password, saltLength);
      Writeln('login -> "' + login + '"');
      Writeln('password -> "' + password + '"');
      Writeln('salt -> "' + encryptData.salt + '"');
      Writeln('hash -> "' + encryptData.hash + '"');
      encryptData.DisposeOf;
    end
    else
      Writeln('No input string is given.');
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  cipher.DisposeOf;

end.
