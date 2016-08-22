unit RedirectServerTests;

interface

uses
  MVCFramework.RESTAdapter, RedirectServerProxy.interfaces,
  DUnitX.TestFramework, System.Generics.Collections, Route, InterfaceRoute,
  Server.Launcher, Controller.webbase, MainWebModule;

type

  [TestFixture]
  TRedirectServerTests = class(TObject)
  private
    procedure TestDeleteRoute;

  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [TEST]
    [Ignore('to do')]
    procedure deleteNonExistingRoute;
    [TEST]
    procedure deleteExistingRoute;
    [TEST]
    [Ignore('convert TJSonObject into TJsonArray first')]
    procedure deleteAllRoute;

    [TEST]
    procedure GetRouteAfterAddingSingleRoute;
    [TEST]
    procedure GetRoutesAfterAdding2Different;
    [TEST]
    procedure doesNotOverrideExistingRoute;
    [TEST]
    procedure zeroRoutesUponServerStart;
    [TEST]
    [Ignore('Need to understand why the server remembers its state after tear down')
      ]
    procedure threeRoutesAfterLoadingThreeDifferentRoutes;

    // [TEST]
    procedure TestPingServer;
    // [TEST]
    procedure TestGetCampainImage;

  end;

implementation

uses
  System.SysUtils,
  System.JSON;

var
  RESTAdapter: TRESTAdapter<IRedirectServerProxy>;
  RedirectServerResource: IRedirectServerProxy;

const
  SERVERPORT = 5000;

procedure TRedirectServerTests.Setup;
begin
  RESTAdapter := TRESTAdapter<IRedirectServerProxy>.Create;
  RedirectServerResource := RESTAdapter.Build('localhost', SERVERPORT);
end;

procedure TRedirectServerTests.TearDown;
begin
  RedirectServerResource := nil;
end;

procedure TRedirectServerTests.deleteAllRoute;
var
  joIn, joOut: TJSonObject;
begin
  joIn := TJSonObject.Create;
  joIn.AddPair('route-to-be-deleted1', 'target-to-be-deleted1');
  RedirectServerResource.addRoutes(joIn.ToString);
  joOut := RedirectServerResource.getRoutes;
  Assert.isTrue(joOut.Count > 0);
  RedirectServerResource.deleteRoutes(joOut.ToString);
  Assert.AreEqual(0, RedirectServerResource.getRoutes.Count, 'no routes must remain');
  joIn.DisposeOf;
  joOut.DisposeOf;
end;

procedure TRedirectServerTests.deleteExistingRoute;
var
  joIn, joOut: TJSonObject;
  routesToDelete: TJSonArray;
begin
  joIn := TJSonObject.Create;
  joIn.AddPair('route-to-be-deleted', 'target-to-be-deleted');
  RedirectServerResource.addRoutes(joIn.ToString);
  routesToDelete := TJSonArray.Create;
  routesToDelete.Add('route-to-be-deleted');
  RedirectServerResource.deleteRoutes(routesToDelete.ToString);

  joOut := RedirectServerResource.getRoutes;

  Assert.IsNull(joOut.GetValue('route-to-be-deleted'));
  joIn.DisposeOf;
  routesToDelete.DisposeOf;
end;

procedure TRedirectServerTests.deleteNonExistingRoute;
begin

end;

procedure TRedirectServerTests.doesNotOverrideExistingRoute;
var
  joIn1, joIn2, joOut: TJSonObject;
begin
  joIn1 := TJSonObject.Create;
  joIn1.AddPair('new-campaign/route', 'initial-target');
  RedirectServerResource.addRoutes(joIn1.ToString);
  joIn2 := TJSonObject.Create;
  joIn2.AddPair('new-campaign/route', 'new-target');
  RedirectServerResource.addRoutes(joIn2.ToString);

  joOut := RedirectServerResource.getRoutes;
  Assert.AreEqual('initial-target', joOut.GetValue('new-campaign/route').Value);
  joIn1.DisposeOf;
  joIn2.DisposeOf;
end;

procedure TRedirectServerTests.GetRouteAfterAddingSingleRoute;
var
  joIn, joOut: TJSonObject;
begin
  joIn := TJSonObject.Create;
  joIn.AddPair('campaign/route', 'target');
  RedirectServerResource.addRoutes(joIn.ToString);
  joOut := RedirectServerResource.getRoutes;
  Assert.AreEqual('target', joOut.GetValue('campaign/route').Value);
  joIn.DisposeOf;
end;

procedure TRedirectServerTests.GetRoutesAfterAdding2Different;
var
  joIn, joOut: TJSonObject;
begin
  joIn := TJSonObject.Create;
  joIn.AddPair('campaign1/route1', 'target1');
  joIn.AddPair('campaign2/route2', 'target2');
  RedirectServerResource.addRoutes(joIn.ToString);
  joOut := RedirectServerResource.getRoutes;
  Assert.AreEqual('target1', joOut.GetValue('campaign1/route1').Value);
  Assert.AreEqual('target2', joOut.GetValue('campaign2/route2').Value);
  joIn.DisposeOf;
end;

procedure TRedirectServerTests.TestDeleteRoute;
var
  jo: TJSonObject;
begin
  // TODO
  // jo := TJSonObject.Create;
  // jo.AddPair('0', 'aaa/aa');
  // jo := RedirectServerResource.getRoutes;
  // Assert.IsTrue(jo.Size > 0, 'routes must contain at least one element');
  // RedirectServerResource.DeleteRoutes(jo);

end;

procedure TRedirectServerTests.TestGetCampainImage;
var
  r: String;
begin
  // TODO
  // r := RedirectServerResource.getCampaignImage('venditori',
  // 'cartellina_natale_2015.jpg');

  // Assert.IsTrue(r.equals('hello'), 'Il metodo non ha riportato hello');
end;

procedure TRedirectServerTests.TestPingServer;
var
  s: string;
  jo: TResponse;
begin
  // r:=NewsWebResource.EchoText('hello');
  // jo := RedirectServerResource.serverPing;
  // Assert.IsTrue(not jo.message.isEmpty);
end;

procedure TRedirectServerTests.threeRoutesAfterLoadingThreeDifferentRoutes;
var
  joIn, joOut: TJSonObject;
begin
  joIn := TJSonObject.Create;
  joIn.AddPair('key1', 'target1');
  joIn.AddPair('key2', 'target2');
  joIn.AddPair('key3', 'target3');
  RedirectServerResource.addRoutes(joIn.ToString);
  joOut := RedirectServerResource.getRoutes;
  Assert.AreEqual(3, joOut.Count);
  joIn.DisposeOf;
end;

procedure TRedirectServerTests.zeroRoutesUponServerStart;
var
  joOut: TJSonObject;
begin
  joOut := RedirectServerResource.getRoutes;
  Assert.AreEqual(0, joOut.Count, 'the server must have no routes on start');
end;

end.
