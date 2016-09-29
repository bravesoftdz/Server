unit ControlServerDispatcher;

interface

uses
  Controller.Base,
  MVCFramework,
  System.Classes, Settings, MVCFramework.RESTAdapter,
  RedirectServerProxy.interfaces;

type

  [MVCPath('/control')]
  TControlServerController = class abstract(TBaseController)
  private
    class var Settings: TSettings;
    class var RESTAdapter: TRESTAdapter<IRedirectServerProxy>;
    class var WebResource: IRedirectServerProxy;

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
  end;

implementation

uses
  FireDAC.Comp.Client,
  Vcl.Forms,
  IdURI,
  System.Types, System.SysUtils, IdStack;

{ TControlServerController }

procedure TControlServerController.getRoutes(ctx: TWebContext);
begin
  Render(WebResource.getRoutes);
end;

procedure TControlServerController.getStatus(ctx: TWebContext);
begin
  Render(WebResource.getRedirectServerStatus());
end;

procedure TControlServerController.OnBeforeAction(Context: TWebContext;
  const AActionNAme: string; var Handled: Boolean);
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
  try
    resp := WebResource.serverPing;
    try
      if not(resp = nil) then
        Render('Received responce: ' + resp.status)
      else
        Render('Null responce');
    except
      on E: EIdSocketError do
        Render('No connection');
    end;
  finally
    resp := nil
  end;
end;

initialization

TControlServerController.Settings := TSettings.Create('.\ControlServer.conf');
TControlServerController.RESTAdapter :=
  TRESTAdapter<IRedirectServerProxy>.Create;
TControlServerController.WebResource :=
  TControlServerController.RESTAdapter.Build
  (TControlServerController.Settings.redirectServerUrl,
  TControlServerController.Settings.redirectServerPort);

finalization

TControlServerController.Settings.DisposeOf;

end.
