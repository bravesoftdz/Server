unit LoginData;

interface

uses
  InterfaceLoginData, System.JSON;

type
  TLoginData = class(TInterfacedObject, ILoginData)
  private
    username: String;
    password: String;
  public
    function getUsername(): String;
    function getPassword(): String;
    /// <summary>Constructor</summary>
    /// <param name="obj">a json object containing string-valued keys
    /// "username" and "password"</param>
    constructor Create(const obj: TJSONObject);

  end;

implementation

{ TSimpleAuthData }

constructor TLoginData.Create(const obj: TJSONObject);
const
  USERNAME_TOKEN = 'username';
  PASSWORD_TOKEN = 'password';
var
  ValueUserName, ValuePassword: TJSONValue;
begin
  ValueUserName := obj.getValue(USERNAME_TOKEN);
  ValuePassword := obj.getValue(PASSWORD_TOKEN);
  if not(ValueUserName = nil) AND not(ValuePassword = nil) then
  begin
    Self.username := ValueUserName.value;
    Self.password := ValuePassword.value;
  end;
end;

function TLoginData.getPassword: String;
begin
  Result := password;
end;

function TLoginData.getUsername: String;
begin
  Result := username;
end;

end.
