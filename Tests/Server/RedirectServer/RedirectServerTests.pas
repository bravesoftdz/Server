unit RedirectServerTests;

interface

uses
  DUnitX.TestFramework, System.Generics.Collections, Route, InterfaceRoute;

type

  [TestFixture]
  TRedirectServerTests = class(TObject)
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [TEST]
    procedure TestDeleteRoute;
    [TEST]
    procedure TestPingServer;
    [TEST]
    procedure TestGetCampainImage;

  end;

implementation

uses
  MVCFramework.RESTAdapter, RedirectServerProxy.interfaces, System.SysUtils;

procedure TRedirectServerTests.Setup;
begin

end;

procedure TRedirectServerTests.TearDown;
begin

end;

procedure TRedirectServerTests.TestDeleteRoute;
var
  RESTAdapter: TRESTAdapter<IRedirectServerProxy>;
  NewsWebResource: IRedirectServerProxy;
  s: string;
  jo: TResponse;
begin
  // TODO
  RESTAdapter := TRESTAdapter<IRedirectServerProxy>.Create;
  NewsWebResource := RESTAdapter.Build('localhost', 5000);
  // r:=NewsWebResource.EchoText('hello');
  jo := NewsWebResource.serverPing;
  Assert.IsTrue(true);

end;

procedure TRedirectServerTests.TestGetCampainImage;
var
  RESTAdapter: TRESTAdapter<IRedirectServerProxy>;
  NewsWebResource: IRedirectServerProxy;
  r: String;
begin
  // TODO
  RESTAdapter := TRESTAdapter<IRedirectServerProxy>.Create;
  NewsWebResource := RESTAdapter.Build('localhost', 5000);
  r := NewsWebResource.getCampaignImage('venditori',
    'cartellina_natale_2015.jpg');

  // Assert.IsTrue(r.equals('hello'), 'Il metodo non ha riportato hello');
end;

procedure TRedirectServerTests.TestPingServer;
var
  RESTAdapter: TRESTAdapter<IRedirectServerProxy>;
  NewsWebResource: IRedirectServerProxy;
  s: string;
  jo: TResponse;
begin
  RESTAdapter := TRESTAdapter<IRedirectServerProxy>.Create;
  NewsWebResource := RESTAdapter.Build('localhost', 5000);
  // r:=NewsWebResource.EchoText('hello');
  jo := NewsWebResource.serverPing;
  Assert.IsTrue(not jo.message.isEmpty);
end;

end.
