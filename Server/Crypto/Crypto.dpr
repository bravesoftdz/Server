program Crypto;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  Encrypt in 'Encrypt.pas';

const
  // switches for comand line inputs
  LOGIN_SWITCH = 'l';
  PASSWORD_SWITCH = 'p';
  SALT_LENGHT_SWITCH = 's';

var
  cipher: TEncrypt;
  encryptData: TEncryptData;
  login, password, saltLengthStr: String;
  saltLength: Integer;

begin
  cipher := TEncrypt.Create();
  if FindCmdLineSwitch(LOGIN_SWITCH, login, False) And FindCmdLineSwitch(PASSWORD_SWITCH, password, False) And
    FindCmdLineSwitch(SALT_LENGHT_SWITCH, saltLengthStr, False) then
  begin
    saltLength := StrToInt(saltLengthStr);
    try
      encryptData := cipher.Encrypt(login, password, saltLength);
      Writeln('login -> "' + login + '"');
      Writeln('password -> "' + password + '"');
      Writeln('salt -> "' + encryptData.salt + '"');
      Writeln('hash -> "' + encryptData.hash + '"');
      encryptData.DisposeOf;
    except
      on E: Exception do
        Writeln(E.ClassName, ': ', E.Message);
    end;
  end
  else
    Writeln('Usage:' + sLineBreak + ExtractFileName(paramstr(0)) + ' -' + LOGIN_SWITCH +
      ' <login name> -' + PASSWORD_SWITCH + ' <password> -' + SALT_LENGHT_SWITCH + ' <salt length>');
  cipher.DisposeOf;

end.
