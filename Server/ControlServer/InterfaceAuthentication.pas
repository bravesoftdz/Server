unit InterfaceAuthentication;

interface

uses
  System.JSON, InterfaceAuthData;

type
  IAuthentication = interface
    ['{CF32495D-BEF3-4C93-90D7-A7B21A3D5B16}']
    function isValidLoginData(const data: IAuthData): Boolean;
//    function encrypt(const str: String): String;
  end;

implementation

end.
