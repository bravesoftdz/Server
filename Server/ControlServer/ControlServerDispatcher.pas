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
  private

    class var Settings: TSettings;
    class var RESTAdapter: TRESTAdapter<IRedirectServerProxy>;
    class var WebResource: IRedirectServerProxy;
    class var Authentication: IAuthentication;

  const
    AUTHENTICATED_TOKEN: String = 'authenticated';
    /// <summary>Configure the server</summary>
    /// <param name="ServerConfigFile">path to the server config file.
    /// Assume that it exists.</param>
    /// <param name="UserAuthFile">path to the file containing authorization data.
    /// Assume that it exists.</param>
    class procedure Configure(const ServerConfigFile, UserAuthFile: String);
    /// <summary>Stop the server</summary>
    class procedure Stop();

  protected
    procedure OnBeforeAction(Context: TWebContext; const AActionNAme: string;
      var Handled: Boolean); override;

    /// <summary>Mark the user with given credetials as authorized</summary>
    procedure authorize(authData: ILoginData);
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
  System.Types, System.SysUtils, IdStack, SimpleAuthentification, System.JSON, LoginData;

{ TControlServerController }

procedure TControlServerController.authorize(authData: ILoginData);
begin
  /// TODO
end;

class procedure TControlServerController.Configure(const ServerConfigFile, UserAuthFile: String);
begin
  try
    TControlServerController.Settings := TSettings.Create(ServerConfigFile);
    TControlServerController.Authentication := TSimpleAuthentification.Create(UserAuthFile);
    TControlServerController.RESTAdapter := TRESTAdapter<IRedirectServerProxy>.Create;
    TControlServerController.WebResource := TControlServerController.RESTAdapter.Build
      (TControlServerController.Settings.redirectServerUrl,
      TControlServerController.Settings.redirectServerPort);
  except
    on e: Exception do
    begin
      System.Writeln('Error: ' + e.Message);
      Exit();
    end;
  end;

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
  LoginData: ILoginData;
  data: TJSonObject;
  Auth: IAuthentication;
begin
  data := ctx.Request.BodyAsJSONObject;
  LoginData := TLoginData.Create(data);
  if TControlServerController.Authentication.isValidLoginData(LoginData) then
    authorize(LoginData);
  LoginData := nil;
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

class procedure TControlServerController.Stop;
begin
  if Assigned(TControlServerController.Settings) then
    TControlServerController.Settings.DisposeOf;
  if Assigned(TControlServerController.RESTAdapter) then
    TControlServerController.RESTAdapter.DisposeOf;

  TControlServerController.Authentication := nil;
  TControlServerController.WebResource := nil;
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

TControlServerController.Configure('.\ControlServer.conf', 'authentications.txt');

finalization

TControlServerController.Stop();

end.
