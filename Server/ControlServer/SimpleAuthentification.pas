unit SimpleAuthentification;

interface

uses
  InterfaceAuthentication,
  System.JSON,
  System.SysUtils,
  System.Classes,
  uTPLb_Hash,
  uTPLb_BaseNonVisualComponent, uTPLb_CryptographicLibrary, MVCFramework,
  InterfaceLoginData, System.Generics.Collections, rttiObjectsMappers, AuthData;

type
  TSimpleAuthentification = class(TInterfacedObject, IAuthentication)
  private
    FUsers: TObjectList<TAuthData>;
    /// <summary>Convert given list of authorisation data into a dictionary whose
    /// keys are the authorisation login names. Assume that the list contains no
    /// pair of objects with equal login names. </summary>
    function groupByLogin(const items: TObjectList<TAuthData>): TDictionary<String, TAuthData>;

  var
    FCore: TDictionary<String, TAuthData>;
    function isFoundInFile(const fileName, key, value: String): Boolean;
    function encrypt(const str: String): String;

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

    [MapperItemsClassType(TAuthData)]
    property users: TObjectList<TAuthData> read FUsers write FUsers;
    /// <summary> Return true if the argument contains valid login credentials,
    /// otherwise return false</summary>
    function isValidLoginData(const AuthData: ILoginData): Boolean;
    /// <summary> Constructor.</summary>
    /// <param name="path">Location of a file that contains login info of all
    /// authorized users. Assume the file exists.</param>
    constructor Create(const path: String);
  end;

implementation

uses uTPLb_Constants, System.hash, System.IOUtils,
  System.RegularExpressions, bo.Helpers;

{ TSimpleAuthentification }

constructor TSimpleAuthentification.Create(const path: String);
begin
  FUsers := TObjectList<TAuthData>.Create();
  if not(TFile.Exists(path, False)) then
    raise Exception.Create('File "' + path + '" with authentication data is not found');
  LoadFromJFile(path);
  try
    FCore := groupByLogin(users);
  except
    on e: Exception do
    begin
      FUsers.Clear;
      FUsers.DisposeOf;
      raise Exception.Create('Failed to group by login name: ' + e.Message);
    end;
  end;
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

function TSimpleAuthentification.groupByLogin(const items: TObjectList<TAuthData>)
  : TDictionary<String, TAuthData>;
var
  item: TAuthData;
begin
  result := TDictionary<String, TAuthData>.Create();
  for item in items do
  begin
    if result.ContainsKey(item.login) then
    begin
      result.Clear;
      result.DisposeOf;
      raise Exception.Create('Duplicate login name: ' + item.login)
    end
    else
      result.Add(item.login, item);
  end
end;

{ Returns true iff a file with given name contains a line with two
  given strings: key and value
}
function TSimpleAuthentification.isFoundInFile(const fileName, key, value: String): Boolean;
var
  lines: TStringList;
  Size, i: Integer;
  RegexObj: TRegEx;
  items: TArray<String>;
  trimmed: String;

begin
  result := False;
  lines := TStringList.Create();
  if FileExists(fileName) then
    lines.LoadFromFile(fileName)
  else
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
    if (Length(items) = 2) and (Trim(items[0]) = key) and (Trim(items[1]) = value) then
    begin
      result := True;
      break;
    end;
  end;
  lines.DisposeOf;
end;

function TSimpleAuthentification.isValidLoginData(const AuthData: ILoginData): Boolean;
var
  username: String;

begin
  username := AuthData.getUsername();
  /// stub
  result := True;
end;

end.
