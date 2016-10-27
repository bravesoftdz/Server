program Crypto;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  Encrypt in 'Encrypt.pas';

var
  cipher: TEncrypt;
  encryptData: TEncryptData;
  input: String;
  saltLength: Integer;

begin
  cipher := TEncrypt.Create();
  try
    if ParamCount >= 2 then
    begin
      input := paramstr(1);
      saltLength := StrToInt(paramstr(2));
      encryptData := cipher.Encrypt(input, saltLength);
      Writeln(input);
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
