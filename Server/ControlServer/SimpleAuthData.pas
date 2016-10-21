unit SimpleAuthData;

interface

uses
  InterfaceAuthData;

type
  TSimpleAuthData = class(TInterfacedObject, IAuthData)
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

constructor TSimpleAuthData.Create(const username, password: String);
begin
  Self.username := username;
  Self.password := password;
end;

function TSimpleAuthData.getPassword: String;
begin
  Result := password;
end;

function TSimpleAuthData.getUsername: String;
begin
  Result := username;
end;

end.
