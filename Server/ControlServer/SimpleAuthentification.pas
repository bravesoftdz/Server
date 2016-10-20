unit SimpleAuthentification;

interface

uses
  InterfaceAuthentication,
  System.JSON,
  System.SysUtils,
  System.Classes,
  uTPLb_Hash,
  uTPLb_BaseNonVisualComponent, uTPLb_CryptographicLibrary, MVCFramework,
  InterfaceLogger;

type
  TSimpleAuthentification = class(TInterfacedObject, IAuthentication)
  private
    function isFoundInFile(const fileName, key, value: String): Boolean;
    function isAuthenticated(const fileName: String; const input: TJsonObject)
      : Boolean; overload;
    function encrypt(const str: String): String;
    function isAuthenticated(const fileName, input: String): Boolean; overload;
    class var Logger: ILogger;

  public
  { name of the key under which json object stores authorization info }
    const
    AUTH_TOKEN: String = 'auth';

    { name of the key under which json object stores redirect paths }
  const
    PATH_TOKEN: String = 'paths';

  const
    AUTH_TOKEN_LOGIN = 'login';

  const
    AUTH_TOKEN_PASSWORD = 'password';

    function isAuthenticated(const fileName: String; const ctx: TWebContext)
      : Boolean; overload;
    function isValidInput(const input: TJsonObject): Boolean;
    function isValidLoginData(const input: TJsonObject): Boolean;
    function createHash(const key, salt: String): String;
  end;

implementation

uses uTPLb_Constants, System.Hash, System.IOUtils, Logger,
  System.RegularExpressions;

{ TSimpleAuthentification }

{ creates a hash based on key and salt strings }
function TSimpleAuthentification.createHash(const key, salt: String): String;
var
  salt2: String;
begin
  salt2 := upperCase(salt);
  result := encrypt(key + salt2);
end;

{ Encrypts a string }
function TSimpleAuthentification.encrypt(const str: String): String;
var
  h2: THashSHA2;

begin
  h2 := THashSHA2.Create(SHA256);
  h2.Update(str);
  result := h2.HashAsString;
end;

function TSimpleAuthentification.isAuthenticated(const fileName: String;
  const input: TJsonObject): Boolean;
var
  authPair: TJsonObject;
  login, password: TJsonValue;
  loginStr, passwordStr, passwordStrEnc: String;
begin
  result := false;
  if isValidLoginData(input) then
  begin
    authPair := input.getValue(AUTH_TOKEN) as TJsonObject;
    login := authPair.getValue(AUTH_TOKEN_LOGIN);
    password := authPair.getValue(AUTH_TOKEN_PASSWORD);
    if ((not(login = nil)) and (not(password = nil))) then
    begin
      loginStr := login.value;
      passwordStr := password.value;
      passwordStrEnc := createHash(passwordStr, loginStr);
      result := isFoundInFile(fileName, loginStr, passwordStrEnc);
    end;

  end;

end;

function TSimpleAuthentification.isAuthenticated(const fileName,
  input: String): Boolean;
var
  constructJSON: TJsonObject;
begin
  constructJSON := TJsonObject.Create;
  try
    { convert String to JSON }
    constructJSON.Parse(BytesOf(input), 0);
    result := isAuthenticated(fileName, constructJSON);
  finally
    constructJSON.DisposeOf;
  end;
end;

{ Returns true iff a file with given name contains a line with two
  given strings: key and value
}
function TSimpleAuthentification.isFoundInFile(const fileName, key,
  value: String): Boolean;
var
  lines: TStringList;
  Size, i: Integer;
  RegexObj: TRegEx;
  items: TArray<String>;
  trimmed: String;

begin
  result := false;
  lines := TStringList.Create();
  if FileExists(fileName) then
  begin
    try
      lines.LoadFromFile(fileName);
    except
      on e: Exception do
      begin
        Logger.logException('TSimpleAuthentification.isFoundInFile', e.Message);
        raise;
      end;
    end;
  end
  else
  begin
    Logger.logWarning('TSimpleAuthentification.isFoundInFile',
      'file ' + fileName + ' does not exist.');
  end;
  Size := lines.Count;
  for i := 0 to Size - 1 do
  begin
    trimmed := Trim(lines[i]);
    // ignore empty lines and those starting with # (that are comments)
    if (Length(trimmed) = 0) or (trimmed[low(trimmed)] = '#') then
      continue;
    // split the string on inner white spaces
    RegexObj := TRegEx.Create('(?<=[^\s])\s+(?=[^\s])');
    items := RegexObj.Split(trimmed, 0);
    if (Length(items) = 2) and (Trim(items[0]) = key) and
      (Trim(items[1]) = value) then
    begin
      result := True;
      break;
    end;
  end;
  lines.DisposeOf;
end;

{ Returns true if all of the following holds:
  1. the input is a json object
  2. the input contains exactly two keys
  3. one key is 'auth'
  4. the other key is 'paths'
  Otherwise, false is returned. }
function TSimpleAuthentification.isValidInput(const input: TJsonObject)
  : Boolean;
begin
  result := false;
  if (not(input = nil)) and (input.Count = 2) then
  begin
    result := (not(input.getValue(AUTH_TOKEN) = nil) and
      (not(input.getValue(PATH_TOKEN) = nil)));
  end;
end;

{ Returns true if the argument contains a key "auth"
}
function TSimpleAuthentification.isValidLoginData
  (const input: TJsonObject): Boolean;
begin
  result := false;
  if (not(input = nil)) then
  begin
    result := not(input.getValue(AUTH_TOKEN) = nil);
  end;
end;

{ Returns true if the WebContext object contains information
  sufficient for authentification. The authentification is performed
  against a file that stores logins and corresponding passwords.
}
function TSimpleAuthentification.isAuthenticated(const fileName: String;
  const ctx: TWebContext): Boolean;
var
  inputJSON: TJsonObject;
begin
  inputJSON := ctx.request.BodyAsJSONObject();
  if (not(inputJSON = nil)) then
    result := isAuthenticated(fileName, inputJSON)
  else
    result := isAuthenticated(fileName, ctx.request.Body);
end;


end.
