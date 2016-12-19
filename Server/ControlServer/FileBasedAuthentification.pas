unit FileBasedAuthentification;

interface

uses
  InterfaceAuthentication,
  System.JSON,
  System.SysUtils,
  System.Classes,
  uTPLb_Hash,
  uTPLb_BaseNonVisualComponent, uTPLb_CryptographicLibrary, MVCFramework,
  InterfaceLoginData, System.Generics.Collections, rttiObjectsMappers, AuthData,
  Encrypt;

type
  { Class that performs authetification of users agains data stored in a file.
    This file is provided as an argument of the constructor. }
  TFileBasedAuthentification = class(TInterfacedObject, IAuthentication)
  private
    FUsers: TObjectList<TAuthData>;
    // authentication data of users indexed by their names
    FUsersIndexed: TDictionary<String, TAuthData>;
    FEncryptor: TEncrypt;
    /// <summary>Convert given list of authorisation data into a dictionary whose
    /// keys are the authorisation login names. Assume that the list contains no
    /// pair of objects with equal login names. </summary>
    function groupByLogin(const items: TObjectList<TAuthData>): TDictionary<String, TAuthData>;
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
    function isValidLoginData(const LoginData: ILoginData): Boolean;
    /// <summary> Constructor.</summary>
    /// <param name="path">Location of a file that contains login info of all
    /// authorized users. Assume the file exists.</param>
    constructor Create(const path: String);
  end;

implementation

uses uTPLb_Constants, System.hash, System.IOUtils,
  System.RegularExpressions, bo.Helpers;

{ TSimpleAuthentification }

constructor TFileBasedAuthentification.Create(const path: String);
begin
  FUsers := TObjectList<TAuthData>.Create();
  FEncryptor := TEncrypt.Create();
  if not(TFile.Exists(path, False)) then
    raise Exception.Create('File "' + path + '" with authentication data is not found');
  LoadFromJFile(path);
  try
    FUsersIndexed := groupByLogin(users);
  except
    on e: Exception do
    begin
      FUsers.Clear;
      FUsers.DisposeOf;
      raise Exception.Create('Failed to group by login name: ' + e.Message);
    end;
  end;
end;

function TFileBasedAuthentification.groupByLogin(const items: TObjectList<TAuthData>)
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

function TFileBasedAuthentification.isValidLoginData(const LoginData: ILoginData): Boolean;
var
  LoginUserName, salt, hash: String;
  AuthData: TAuthData;
  encryptData: TEncryptData;
begin
  LoginUserName := LoginData.getUsername();
  // find authentication data related to a user with a given name
  if not(FUsersIndexed.ContainsKey(LoginUserName)) then
    result := False
  else
  begin
    AuthData := FUsersIndexed.items[LoginUserName];
    salt := AuthData.salt;
    hash := AuthData.hash;
    encryptData := TEncryptData.Create(LoginUserName, LoginData.getPassword(), salt);
    result := encryptData.hash = hash;
  end;
end;

end.
