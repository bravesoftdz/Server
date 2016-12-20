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
  Winapi.Windows,
  Encrypt in 'Encrypt.pas';

const
  // switches for comand line inputs. They must be all different (in order
  // to identify the parameters properly.
  LOGIN_SWITCH = 'l';
  PASSWORD_SWITCH = 'p';
  SALT_LENGHT_SWITCH = 's';
  // prefix for the switches. Use the common one (for the moment of writing)
  // for all platforms (Windows, Linux, MacOs, Android)
  SWITCH_CHAR = '-';

var
  cipher: TEncrypt;
  encryptData: TEncryptData;
  login, password, saltLengthStr: String;
  saltLength: Integer;

begin
  cipher := TEncrypt.Create();
  if FindCmdLineSwitch(LOGIN_SWITCH, login, False) And FindCmdLineSwitch(PASSWORD_SWITCH, password,
    False) And FindCmdLineSwitch(SALT_LENGHT_SWITCH, saltLengthStr, False) then
  begin
    // initialize the salt length by a non-valid value in order to be able to
    // see whether it gets then assigned a valid one
    saltLength := -1;
    try
      saltLength := StrToInt(saltLengthStr);
    except
      on E: Exception do
      begin
        SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 15);
        Writeln('Error while parsing the salt length parameter: ', E.Message);
        SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 7);
      end;

    end;
    if (saltLength > 0) then
    begin
      encryptData := cipher.Encrypt(login, password, saltLength);
      Writeln('login: "' + login + '"');
      Writeln('password: "' + password + '"');
      Writeln(encryptData.ToString);
      encryptData.DisposeOf;
    end
    else
      Writeln('Salt length must be a postive integer number.');
  end
  else
  // print the instructions on how to use this program
  begin
    Writeln('Usage:' + sLineBreak + ExtractFileName(paramstr(0)) + ' ' + SWITCH_CHAR + LOGIN_SWITCH
      + ' <login name> ' + SWITCH_CHAR + PASSWORD_SWITCH + ' <password> ' + SWITCH_CHAR +
      SALT_LENGHT_SWITCH + ' <salt length>');
    cipher.DisposeOf;
  end;

end.
