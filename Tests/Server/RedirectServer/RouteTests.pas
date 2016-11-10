unit RouteTests;

interface

uses
  DUnitX.TestFramework, System.Generics.Collections, Route, InterfaceRoute;

type

  [TestFixture]
  TRouteTests = class(TObject)
  strict private
    aTRoute: IRoute;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure loadSingleCampaign();
    [Test]
    procedure loadTwoDifferentCampaigns();
    [Test]
    procedure loadRouteWithExisitingKey();
    [Test]
    procedure loadRoutesNonStringValue();
    [Test]
    procedure loadRoutesIgnoreNilValues();

    [Test]
    procedure remove1From0();
    [Test]
    procedure remove1ExistingFrom1();
    [Test]
    procedure remove2ExistingFrom3();
    [Test]
    procedure remove0From2();

  end;

implementation

uses
  System.Classes, System.JSON;


/// Ignore those routes whose values are nill
///
procedure TRouteTests.loadRoutesIgnoreNilValues;
var
  mapIn, mapOut: TJSonObject;
  key1, key2, value: String;
begin
//  Assert.IsTrue(aTRoute.getRoutes.Count = 0);
//  key1 := 'campaign1/article1';
//  key2 := 'campaign2/article2';
//  value := 'http://www.example.com/';
//  mapIn := TJSonObject.Create;
//  mapIn.AddPair(key1, value);
//  mapIn.AddPair(key2, nil);
//  aTRoute.AddRoutes(mapIn);
//  mapOut := aTRoute.getRoutes;
//  Assert.IsTrue(mapOut.Count = 1);
//  Assert.AreEqual(mapOut.GetValue(key1).value, value);
//  mapIn.DisposeOf;
end;

/// Removes zero routes from two exisitng ones
[Ignore('Need to rewrite this test')]
procedure TRouteTests.remove0From2;
var
  routes: TJsonArray;
  mapIn, mapOut: TJSonObject;
  key1, key2, value1, value2: String;
begin
//  Assert.AreEqual(0, aTRoute.getRoutes.Count);
//  key1 := 'campaign1/article1';
//  value1 := 'http://www.example.com';
//  key2 := 'campaign2/article2';
//  value2 := 'http://www.another-example.com';
//
//  mapIn := TJSonObject.Create;
//  mapIn.AddPair(key1, value1);
//  mapIn.AddPair(key2, value2);
//  aTRoute.AddRoutes(mapIn);
//
//  Assert.AreEqual(2, aTRoute.getRoutes.Count);
//
//  routes := TJsonArray.Create;
//
//  aTRoute.delete(routes);
//  mapOut := aTRoute.getRoutes;
//  Assert.AreEqual(2, mapOut.Count);
//  Assert.AreEqual(value1, mapOut.GetValue(key1).value);
//  Assert.AreEqual(value2, mapOut.GetValue(key2).value);
end;

/// Removes the only exising route
[Ignore('Need to rewrite this test')]
procedure TRouteTests.remove1ExistingFrom1;
var
  routes: TJsonArray;
  mapIn: TJSonObject;
  key, value: String;
begin
//  Assert.AreEqual(aTRoute.getRoutes.Count, 0);
//  key := 'campaign1/article1';
//  value := 'http://www.another-example.com';
//  mapIn := TJSonObject.Create;
//  mapIn.AddPair(key, value);
//  aTRoute.AddRoutes(mapIn);
//  Assert.AreEqual(aTRoute.getRoutes.Count, 1);
//
//  routes := TJsonArray.Create;
//  routes.Add(key);
//  aTRoute.delete(routes);
//  Assert.AreEqual(aTRoute.getRoutes.Count, 0);
end;

/// Tries to removes a route from empty mapping
[Ignore('Need to rewrite this test')]
procedure TRouteTests.remove1From0;
var
  routes: TJsonArray;
begin
  Assert.AreEqual(aTRoute.getRoutes.Count, 0);
  routes := TJsonArray.Create;
  routes.Add('a/route');
  aTRoute.delete(routes);
  Assert.AreEqual(aTRoute.getRoutes.Count, 0);
end;


/// Removes two existing routes from the mapping with three routes
[Ignore('Need to rewrite this test')]
procedure TRouteTests.remove2ExistingFrom3;
var
  routes: TJsonArray;
  mapIn: TJSonObject;
  key1, key2, key3, value1, value2, value3: String;
begin
//  Assert.AreEqual(aTRoute.getRoutes.Count, 0);
//  key1 := 'campaign1/article1';
//  key2 := 'campaign2/article2';
//  key3 := 'campaign3/article3';
//  value1 := 'http://www.example1.com';
//  value2 := 'http://www.example2.com';
//  value3 := 'http://www.example3.com';
//  mapIn := TJSonObject.Create;
//  mapIn.AddPair(key1, value1);
//  mapIn.AddPair(key2, value2);
//  mapIn.AddPair(key3, value3);
//
//  aTRoute.AddRoutes(mapIn);
//  Assert.AreEqual(3, aTRoute.getRoutes.Count);
//
//  routes := TJsonArray.Create;
//  routes.Add(key1);
//  routes.Add(key3);
//  aTRoute.delete(routes);
//  Assert.AreEqual(1, aTRoute.getRoutes.Count);
//  Assert.AreEqual(value2, aTRoute.getRoutes.GetValue(key2).value);
end;

[Ignore('Need to rewrite this test')]
{ Only a json object with key and value being of string types are to be loaded }
procedure TRouteTests.loadRoutesNonStringValue;
var
  map1, map2, mapOut: TJSonObject;
  key: String;
begin
  Assert.IsTrue(aTRoute.getRoutes.Count = 0);
  key := 'a key';

  map1 := TJSonObject.Create;
  map2 := TJSonObject.Create;
  map2.AddPair('foo', 'boo');
  map1.AddPair(key, map2);

//  aTRoute.AddRoutes(map1);
  mapOut := aTRoute.getRoutes;

  Assert.IsTrue(mapOut.Count = 0);
end;

[Ignore('Need to rewrite this test')]
procedure TRouteTests.loadRouteWithExisitingKey;
var
  mapIn1, mapIn2, mapOut: TJSonObject;
  key, value1, value2: String;
begin
  Assert.IsTrue(aTRoute.getRoutes.Count = 0);
  key := 'camp/art';
  value1 := 'http://www.example.com/';
  value2 := 'http://www.another-example.com';
  mapIn1 := TJSonObject.Create;
  mapIn1.AddPair(key, value1);
//  aTRoute.AddRoutes(mapIn1);
  mapIn2 := TJSonObject.Create;
  mapIn2.AddPair(key, value2);
//  aTRoute.AddRoutes(mapIn2);

  mapOut := aTRoute.getRoutes;

  Assert.IsTrue(mapOut.Count = 1);
  Assert.AreEqual(mapOut.GetValue(key).value, value1);

  mapIn1.DisposeOf;
  mapIn2.DisposeOf;
end;

[Ignore('Need to rewrite this test')]
procedure TRouteTests.loadSingleCampaign;
var
  mapIn, mapOut: TJSonObject;
  key, value: String;
begin
  Assert.IsTrue(aTRoute.getRoutes.Count = 0);
  key := 'campaign/article';
  value := 'http://www.example.com/';
  mapIn := TJSonObject.Create;
  mapIn.AddPair(key, value);
//  aTRoute.AddRoutes(mapIn);
  mapOut := aTRoute.getRoutes;
  Assert.IsTrue(mapOut.Count = 1);
  Assert.AreEqual(mapOut.GetValue(key).value, value);
  mapIn.DisposeOf;
end;

[Ignore('Need to rewrite this test')]
procedure TRouteTests.loadTwoDifferentCampaigns;
var
  mapIn, mapOut: TJSonObject;
  key1, key2, value1, value2: String;
begin
  Assert.IsTrue(aTRoute.getRoutes.Count = 0);
  key1 := 'campaign1/article1';
  key2 := 'campaign2/article2';
  value1 := 'http://www.example.com/';
  value2 := 'http://www.another-example.com';
  mapIn := TJSonObject.Create;
  mapIn.AddPair(key1, value1);
  mapIn.AddPair(key2, value2);
//  aTRoute.AddRoutes(mapIn);
  mapOut := aTRoute.getRoutes;
  Assert.IsTrue(mapOut.Count = 2);
  Assert.AreEqual(mapOut.GetValue(key1).value, value1);
  Assert.AreEqual(mapOut.GetValue(key2).value, value2);
  mapIn.DisposeOf;
end;

procedure TRouteTests.Setup;
begin
//  aTRoute := TRoute.Create;
end;

procedure TRouteTests.TearDown;
begin
  aTRoute:= nil;
end;

end.
