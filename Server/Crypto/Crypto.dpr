{ This program generate a salt and a hash for given login and password.
  It requires that the following comand line arguments are provided:
  1. the login name
  2. the password
  3. the salt length
}
program Crypto;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  Encrypt in 'Encrypt.pas';

const
  // switches for comand line inputs. They must be all different (in order
  // to identify the parameters properly.
  LOGIN_SWITCH = 'l';
  PASSWORD_SWITCH = 'p';
  SALT_LENGHT_SWITCH = 's';

var
  cipher: TEncrypt;
  encryptData: TEncryptData;
  login, password, saltLengthStr: String;
  saltLength: Integer;
  switchChar: Char;

begin
  cipher := TEncrypt.Create();
  if FindCmdLineSwitch(LOGIN_SWITCH, login, False) And FindCmdLineSwitch(PASSWORD_SWITCH, password,
    False) And FindCmdLineSwitch(SALT_LENGHT_SWITCH, saltLengthStr, False) then
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
  // print the instructions on how to use this program
  begin
    // this is an ugly way just to pick up a first char from SwitchChars set.
    for switchChar in SwitchChars do
    begin
      Break
    end;
    Writeln('Usage:' + sLineBreak + ExtractFileName(paramstr(0)) + ' ' + switchChar + LOGIN_SWITCH +
      ' <login name> ' + switchChar + PASSWORD_SWITCH + ' <password> ' + switchChar +
      SALT_LENGHT_SWITCH + ' <salt length>');
    cipher.DisposeOf;
  end;

end.
