unit InterfaceAuthentication;

interface

uses
  System.JSON, InterfaceLoginData;

type
  { Class for performing authentification of users }
  IAuthentication = interface
    ['{CF32495D-BEF3-4C93-90D7-A7B21A3D5B16}']
    { Whether the provided login data is a valid one. The validity is
      performed by doing a comparison agains data stored in memory, in a database,
      in a file etc. }
    function isValidLoginData(const data: ILoginData): Boolean;
  end;

implementation

end.
