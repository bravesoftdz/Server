unit LoginData;

interface

uses
  InterfaceLoginData;

type
  TLoginData = class(TInterfacedObject, ILoginData)
  private
    username: String;
    password: String;
  public
    function getUsername(): String;
    function getPassword(): String;
    constructor Create(const username, password: String);

  end;

implementation

{ TSimpleAuthData }

constructor TLoginData.Create(const username, password: String);
begin
  Self.username := username;
  Self.password := password;
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
