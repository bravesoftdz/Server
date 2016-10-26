program Crypto;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  Encrypt in 'Encrypt.pas';
var
  cipher: TEncrypt;
  input: String;
  saltLength: Integer;
begin
  cipher := TEncrypt.Create();
  try
    if ParamCount >= 2 then
    begin
      input := paramstr(1);
      saltLength := StrToInt(paramstr(2));
      Writeln(input + ' -> "' + cipher.Encrypt(input, saltLength) + '"');
    end
    else
      Writeln('No input string is given.');
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  cipher.DisposeOf;

end.
