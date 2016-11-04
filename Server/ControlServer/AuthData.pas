unit AuthData;

interface

type
  [MapperJSONNaming(JSONNameLowerCase)]
  TAuthData = class
  private
    FHash: String;
    FSalt: String;
    FLogin: String;
  published
    property login: String read FLogin write FLogin;
    property salt: String read FSalt write FSalt;
    property hash: String read FHash write FHash;
  end;

implementation

end.
