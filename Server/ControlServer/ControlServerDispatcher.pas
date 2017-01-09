unit ControlServerDispatcher;

interface

uses
  Controller.Base,
  MVCFramework,
  System.Classes, Settings, MVCFramework.RESTAdapter,
  RedirectServerProxy.interfaces, InterfaceAuthentication, InterfaceLoginData;

type

  [MVCPath('/control')]
  TControlServerController = class abstract(TBaseController)
  const
    AUTHENTICATED_TOKEN: String = 'authenticated';

    /// <summary>Stop the server</summary>
    class procedure Stop();
    class function isLoggedIn(const LoginData: ILoginData): Boolean;

  protected
    procedure OnBeforeAction(Context: TWebContext; const AActionNAme: string;
      var Handled: Boolean); override;

    /// <summary>Mark the user with given credetials as authorized</summary>
    procedure authorize(authData: ILoginData);
  public
    class var RESTAdapter: TRESTAdapter<IRedirectServerProxy>;
    class var RedirectServer: IRedirectServerProxy;
    class var Authentication: IAuthentication;
    /// <summary> Initialize the control server</summary>
    /// <param name="AuthFileName">path to a file with authentification data.
    /// Assume that it exists.</param>
    /// <param name="ServerUrl">Url of the server that is supposed to be controlled</param>
    /// <param name="ServerPort">Port number of the server that is supposed to be controlled</param>
    class procedure Initialize(AuthFileName: String; ServerUrl: String; ServerPort: Integer);

    // [MVCPath('/connect')]
    // [MVCHTTPMethod([httpGET])]
    // procedure testConnection(ctx: TWebContext);

    [MVCPath('/ping')]
    [MVCHTTPMethod([httpGET])]
    procedure ping(ctx: TWebContext);

    [MVCPath('/status')]
    [MVCHTTPMethod([httpGET])]
    procedure getStatus(ctx: TWebContext);

    [MVCPath('/routes')]
    [MVCHTTPMethod([httpGET])]
    procedure getRoutes(ctx: TWebContext);

    /// <summary>Perform a log in. The authentication parameters must be provided
    /// as a json object with two keys: "username" and "password".
    /// Value corresponding to the key "password" is not a password, but its
    /// hash obtained from the password by applying a cryptographic algorithm.</summary>
    [MVCPath('/login')]
    [MVCHTTPMethod([httpPOST])]
    procedure login(ctx: TWebContext);

    /// <summary>Perform a log out.</summary>
    [MVCPath('/logout')]
    [MVCHTTPMethod([httpPOST])]
    procedure logout(ctx: TWebContext);
  end;

implementation

uses
  FireDAC.Comp.Client,
  Vcl.Forms,
  IdURI,
  Winapi.Windows,
  System.Types, System.SysUtils, IdStack, SimpleAuthentification, System.JSON, LoginData;

{ TControlServerController }

procedure TControlServerController.authorize(authData: ILoginData);
begin
  Session[authData.getUsername] := 'logged';
end;

procedure TControlServerController.getRoutes(ctx: TWebContext);
begin
  // Render(WebResource.getRoutes);
end;

procedure TControlServerController.getStatus(ctx: TWebContext);
begin

  Render(RedirectServer.getServerStatus());
end;

class function TControlServerController.isLoggedIn(const LoginData: ILoginData): Boolean;
begin
  // stub
  Result := False;
end;

procedure TControlServerController.login(ctx: TWebContext);
var
  LoginData: ILoginData;
  data: TJSonObject;
  isValid: Boolean;
  isLogged: Boolean;
begin
  data := ctx.Request.BodyAsJSONObject;
  LoginData := TLoginData.Create(data);
  isValid := TControlServerController.Authentication.isValidLoginData(LoginData);
  isLogged := isLoggedIn(LoginData);
  if isValid then
    authorize(LoginData);
  LoginData := nil;
  Render(TJsonBool.Create(isValid));
end;

procedure TControlServerController.logout(ctx: TWebContext);
begin

end;

procedure TControlServerController.OnBeforeAction(Context: TWebContext; const AActionNAme: string;
  var Handled: Boolean);
begin
  // inherited;

end;

procedure TControlServerController.ping(ctx: TWebContext);
begin
  Render('ok');
end;

class procedure TControlServerController.Initialize(AuthFileName: String; ServerUrl: String;
  ServerPort: Integer);
begin
  Authentication := TFileBasedAuthentification.Create(AuthFileName);
  RESTAdapter := TRESTAdapter<IRedirectServerProxy>.Create;
  RedirectServer := RESTAdapter.Build(ServerUrl, ServerPort);
end;

class procedure TControlServerController.Stop;
begin
  Authentication := nil;
  RedirectServer := nil;
end;

// procedure TControlServerController.testConnection(ctx: TWebContext);
// var
// resp: TResponse;
// begin
// try
// resp := WebResource.serverPing;
// try
// if not(resp = nil) then
// Render('Received responce: ' + resp.status)
// else
// Render('Null responce');
// except
// on E: EIdSocketError do
// Render('No connection');
// end;
// finally
// resp := nil
// end;
// end;

initialization

finalization

TControlServerController.Stop();

end.
