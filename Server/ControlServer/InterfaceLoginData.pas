unit InterfaceLoginData;

interface

type

  /// <summary> Login data provided by user. Contains the login and the password.</summary>
  ILoginData = interface
    ['{42E30F8F-8737-4F12-8CB6-0042D034A6C8}']
    function getUsername(): String;
    function getPassword(): String;
  end;

implementation

end.
