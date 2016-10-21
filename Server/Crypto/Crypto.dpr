program Crypto;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  Encrypt in 'Encrypt.pas';

var
  cipher: TEncrypt;
  input: String;

begin
  cipher := TEncrypt.Create();
  try
    if ParamCount >= 1 then
    begin
      input := paramstr(1);
      Writeln(input + ' -> "' + cipher.Encrypt(input) + '"');
    end
    else
      Writeln('No input string is given.');
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  cipher.DisposeOf;

end.
