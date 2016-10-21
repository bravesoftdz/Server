unit InterfaceAuthentication;

interface

uses
  System.JSON, MVCFramework, InterfaceAuthData;

type
  IAuthentication = interface
    ['{CF32495D-BEF3-4C93-90D7-A7B21A3D5B16}']
    { Controls whether the context contains data that are considered to be valid
      with respect to a  file with given name }
    function isAuthenticated(const fileName: String; const ctx: TWebContext): Boolean; overload;
    function isValidInput(const input: IAuthData): Boolean;
    function isValidLoginData(const data: IAuthData): Boolean;
    function encrypt(const str: String): String;
  end;

implementation

end.
