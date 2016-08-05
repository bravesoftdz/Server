unit MainWebModule;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, BaseWM, IPPeerServer,
  Datasnap.DSCommonServer, Datasnap.DSHTTP, Datasnap.DSHTTPWebBroker,
  Datasnap.DSServer, RedirectServerDispatcher;

type
  TwmMain = class(TwmBase)
    procedure WebModuleCreate(Sender: TObject);
    procedure WebModuleDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  wmMain: TwmMain;

implementation

uses Settings, Route;

{$R *.dfm}

procedure TwmMain.WebModuleCreate(Sender: TObject);
begin
  inherited;
  GetEngine.AddController(TRedirectController);

end;

procedure TwmMain.WebModuleDestroy(Sender: TObject);
begin
  inherited;
  //
end;


end.
