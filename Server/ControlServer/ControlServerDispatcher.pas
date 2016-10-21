unit ControlServerDispatcher;

interface

uses
  Controller.Base,
  MVCFramework,
  System.Classes, Settings, MVCFramework.RESTAdapter,
  RedirectServerProxy.interfaces, InterfaceAuthentication;

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

    [MVCPath('/login')]
    [MVCHTTPMethod([httpPOST])]
    procedure login(ctx: TWebContext);
  end;

implementation

uses
  FireDAC.Comp.Client,
  Vcl.Forms,
  IdURI,
  System.Types, System.SysUtils, IdStack, SimpleAuthentification,
  InterfaceAuthData, System.JSON, SimpleAuthData;

{ TControlServerController }

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
  AuthData: IAuthData;
  data: TJSonObject;
  Auth: IAuthentication;
begin
  data := ctx.Request.BodyAsJSONObject;
  AuthData := TSimpleAuthData.Create(data.getValue['username'].value,
    data.getValue['password'].value);
  Auth := TSimpleAuthentification.Create();
  Session[AUTHENTICATED_TOKEN] := Auth.isValidLoginData(AuthData);
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
TControlServerController.Authentication := TSimpleAuthentification.Create();
TControlServerController.WebResource := TControlServerController.RESTAdapter.Build
  (TControlServerController.Settings.redirectServerUrl,
  TControlServerController.Settings.redirectServerPort);

finalization

TControlServerController.Settings.DisposeOf;
TControlServerController.Authentication := nil;

end.
