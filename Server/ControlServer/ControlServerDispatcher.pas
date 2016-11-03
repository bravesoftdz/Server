unit ControlServerDispatcher;

interface

uses
  Controller.Base,
  MVCFramework,
  System.Classes, Settings, MVCFramework.RESTAdapter,
  RedirectServerProxy.interfaces, InterfaceAuthentication, InterfaceAuthData;

type

  [MVCPath('/control')]
  TControlServerController = class abstract(TBaseController)
  private

    class var Settings: TSettings;
    class var RESTAdapter: TRESTAdapter<IRedirectServerProxy>;
    class var WebResource: IRedirectServerProxy;
    class var Authentication: IAuthentication;

  const
    AUTHENTICATED_TOKEN: String = 'authenticated';

  protected
    procedure OnBeforeAction(Context: TWebContext; const AActionNAme: string;
      var Handled: Boolean); override;

    /// <summary>Mark the user with given credetials as authorized</summary>
    procedure authorize(authData: IAuthData);
  public
    [MVCPath('/connect')]
    [MVCHTTPMethod([httpGET])]
    procedure testConnection(ctx: TWebContext);

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
  System.Types, System.SysUtils, IdStack, SimpleAuthentification, System.JSON, SimpleAuthData;

{ TControlServerController }

procedure TControlServerController.authorize(authData: IAuthData);
begin
  /// TODO
end;

procedure TControlServerController.getRoutes(ctx: TWebContext);
begin
  // Render(WebResource.getRoutes);
end;

procedure TControlServerController.getStatus(ctx: TWebContext);
begin

  Render(WebResource.getServerStatus());
end;

procedure TControlServerController.login(ctx: TWebContext);
var
  authData: IAuthData;
  data: TJSonObject;
  Auth: IAuthentication;
begin
  data := ctx.Request.BodyAsJSONObject;
  authData := TSimpleAuthData.Create(data.getValue('username').value,
    data.getValue('password').value);
  if TControlServerController.Authentication.isValidLoginData(authData) then
    authorize(authData);
  authData := nil;
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

procedure TControlServerController.testConnection(ctx: TWebContext);
var
  resp: TResponse;
begin
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
end;

initialization

TControlServerController.Settings := TSettings.Create('.\ControlServer.conf');
TControlServerController.RESTAdapter := TRESTAdapter<IRedirectServerProxy>.Create;
TControlServerController.Authentication := TSimpleAuthentification.Create('authentications.txt');
TControlServerController.WebResource := TControlServerController.RESTAdapter.Build
  (TControlServerController.Settings.redirectServerUrl,
  TControlServerController.Settings.redirectServerPort);

finalization

TControlServerController.Settings.DisposeOf;
TControlServerController.Authentication := nil;

end.
