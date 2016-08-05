unit MainWebModule;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, BaseWM, IPPeerServer,
  Datasnap.DSCommonServer, Datasnap.DSHTTP, Datasnap.DSHTTPWebBroker,
  Datasnap.DSServer;

type
  TwbmMain = class(TwmBase)
    procedure WebModuleCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  wbmMain: TwbmMain;

implementation

uses
  ControlServerDispatcher;

{$R *.dfm}

procedure TwbmMain.WebModuleCreate(Sender: TObject);
begin
  inherited;
  GetEngine.AddController(TControlServerController);

end;

end.
