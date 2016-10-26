unit InterfaceAuthData;

interface

type
  IAuthData = interface
    ['{42E30F8F-8737-4F12-8CB6-0042D034A6C8}']
    function getUsername(): String;
    function getPassword(): String;
//    constructor Create(const username, password: String);

  end;

implementation

end.
