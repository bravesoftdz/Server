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
    procedure deleteAllRoutes;

  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [TEST]
    procedure DoesNotChangeRoutesWhenDeletingNonExistingRoute;
    [TEST]
    procedure LeavesZeroRoutesWhenDeletingFromEmptyRouteMap;
    [TEST]
    procedure DeleteOneExistingRouteFromTwoAvailable;
    [TEST]
    procedure DeleteNoRoutesFromRouteFromThreeAvailable;
    [TEST]
    procedure GetRouteAfterAddingSingleRoute;
    [TEST]
    procedure GetRoutesAfterAdding2Different;
    [TEST]
    procedure DoesNotOverrideExistingRoute;
    [TEST]
    procedure ZeroRoutesOnceCleaned;
    [TEST]
    procedure ThreeRoutesAfterLoadingThreeDifferentRoutes;
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
  deleteAllRoutes;
end;

procedure TRedirectServerTests.TearDown;
begin
  RedirectServerResource := nil;
end;

{ Deletes all routes. This procedure is created in order to clean up the server
  routes between different runs. Otherwise, routes used for previous tests might
  affect other tests. }
procedure TRedirectServerTests.deleteAllRoutes;
var
  joOut: TJSonObject;
  ja: TJsonArray;
  item: TJSonPair;
begin
  joOut := RedirectServerResource.getRoutes;
  if joOut.Count > 0 then
  begin
    ja := TJsonArray.Create;
    for item in joOut do
      ja.Add(item.JsonString.value);
    RedirectServerResource.deleteRoutes(ja.ToString);
    joOut.DisposeOf;
  end;
end;

{ When the server has three routes and one passes empty list for routes to remove,
  the initial three routes must remain. }
procedure TRedirectServerTests.DeleteNoRoutesFromRouteFromThreeAvailable;
var
  joIn, joOut: TJSonObject;
begin
  joIn := TJSonObject.Create;
  joIn.AddPair('route-1/first/', 'first/target');
  joIn.AddPair('route-2/second/', 'second/target');
  joIn.AddPair('route-3/third/', 'third/target');
  RedirectServerResource.addRoutes(joIn.ToString);
  RedirectServerResource.deleteRoutes(TJsonArray.Create.ToString);
  joOut := RedirectServerResource.getRoutes;
  Assert.AreEqual(3, joOut.Count, 'three one route must remain');
  Assert.AreEqual('first/target', joOut.Values['route-1/first/'].value);
  Assert.AreEqual('second/target', joOut.Values['route-2/second/'].value);
  Assert.AreEqual('third/target', joOut.Values['route-3/third/'].value);
  joIn.DisposeOf;
  joOut.DisposeOf;
end;

{ When the server has two routes and one gets removed, only the other one must
  remain. }
procedure TRedirectServerTests.DeleteOneExistingRouteFromTwoAvailable;
var
  joIn, joOut: TJSonObject;
  routesToDelete: TJsonArray;
begin
  joIn := TJSonObject.Create;
  joIn.AddPair('routeTo/delete', 'target-to-delete');
  joIn.AddPair('routeTo/remain', 'target-to-remain');
  RedirectServerResource.addRoutes(joIn.ToString);
  routesToDelete := TJsonArray.Create;
  routesToDelete.Add('routeTo/delete');
  RedirectServerResource.deleteRoutes(routesToDelete.ToString);
  joOut := RedirectServerResource.getRoutes;
  Assert.AreEqual(1, joOut.Count, 'only one route must remain');
  Assert.AreEqual('target-to-remain', joOut.Values['routeTo/remain'].value,
    'routeTo/remain must redirect to target-to-remain');
  Assert.IsNull(joOut.GetValue('routeTo/delete'),
    'routeTo/delete must be absent in to route map');
  joIn.DisposeOf;
  joOut.DisposeOf;
  routesToDelete.DisposeOf;
end;

{ When the server has two routes and one tries to remove a route that is not among
  those two, the server must continue to have the two initial routes. }
procedure TRedirectServerTests.DoesNotChangeRoutesWhenDeletingNonExistingRoute;
var
  routesSetUp, routesOutput: TJSonObject;
  routesToDelete: TJsonArray;
begin
  deleteAllRoutes;
  routesSetUp := TJSonObject.Create;
  routesSetUp.AddPair('route1', 'initial-target1');
  routesSetUp.AddPair('route2', 'initial-target2');
  RedirectServerResource.addRoutes(routesSetUp.ToString);
  routesToDelete := TJsonArray.Create;
  routesToDelete.Add('route-that-does-not-exist');
  RedirectServerResource.deleteRoutes(routesToDelete.ToString);
  routesOutput := RedirectServerResource.getRoutes;
  Assert.AreEqual(2, routesOutput.Count);
  Assert.AreEqual('initial-target1', routesOutput.Values['route1'].value);
  Assert.AreEqual('initial-target2', routesOutput.Values['route2'].value);
end;

procedure TRedirectServerTests.DoesNotOverrideExistingRoute;
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
  Assert.AreEqual('initial-target', joOut.GetValue('new-campaign/route').value);
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
  Assert.AreEqual('target', joOut.GetValue('campaign/route').value);
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
  Assert.AreEqual('target1', joOut.GetValue('campaign1/route1').value);
  Assert.AreEqual('target2', joOut.GetValue('campaign2/route2').value);
  joIn.DisposeOf;
end;

{ When the server has no routes and one tries to remove a route, the server
  must continue to have no routes }
procedure TRedirectServerTests.LeavesZeroRoutesWhenDeletingFromEmptyRouteMap;
var
  routesToDelete: TJsonArray;
begin
  routesToDelete := TJsonArray.Create;
  routesToDelete.Add('some/route');
  RedirectServerResource.deleteRoutes(routesToDelete.ToString);
  Assert.AreEqual(0, RedirectServerResource.getRoutes.Count);
end;

procedure TRedirectServerTests.ThreeRoutesAfterLoadingThreeDifferentRoutes;
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

procedure TRedirectServerTests.ZeroRoutesOnceCleaned;
var
  joOut: TJSonObject;
begin
  deleteAllRoutes;
  joOut := RedirectServerResource.getRoutes;
  Assert.AreEqual(0, joOut.Count, 'the server must have no routes on start');
end;

end.
