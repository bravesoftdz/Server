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
    procedure extractCampaignFromEmpty();
    [Test]
    procedure extractCampaignFromSingle();
    [Test]
    procedure extractCampaignFromTwoEqual();
    [Test]
    procedure extractCampaignFromTwoDifferent();
    [Test]
    procedure extractCampaignFromThreeRoutesTwoCampaigns();
    [Test]
    [TestCase('Empty String', ',/,')]
    [TestCase('String without the separator', 'abc,/,abc')]
    [TestCase('String starts with the separator', '/abc,/,abc')]
    [TestCase('Three parts', 'a/b/c,/,a')]
    procedure extractCampaign(const str, separ, expected: String);

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
    procedure loadTwoRoutesDifferentCampaigns();

    [Test]
    procedure remove1From0();
    [Test]
    procedure remove1ExistingFrom1();
    [Test]
    procedure remove2ExistingFrom3();
    [Test]
    procedure remove0From2();

    [Test]
    procedure remove2RoutesOfCampaign22();
    [Test]
    procedure remove1RouteOfCampaign22();

  end;

implementation

uses
  System.Classes, System.JSON;

procedure TRouteTests.extractCampaign(const str, separ, expected: String);
var
  actual: String;
begin
  actual := aTRoute.extractCampaign(str, separ[Low(separ)]);
  Assert.AreEqual(expected, actual, false);
end;

procedure TRouteTests.extractCampaignFromEmpty;
var
  actual: TStringList;
  map: TDictionary<String, String>;
begin
  map := TDictionary<String, String>.Create;
  actual := aTRoute.extractCampaigns(map);
  Assert.AreEqual(0, actual.Count,
    'The method must return an empty string list');
  actual.DisposeOf;
end;

procedure TRouteTests.extractCampaignFromSingle;
var
  actual: TStringList;
  map: TDictionary<String, String>;
begin
  map := TDictionary<String, String>.Create;
  map.Add('campaign1/article1', 'destination1');
  map.Add('campaign1/article2', 'destination2');
  actual := aTRoute.extractCampaigns(map);
  Assert.AreEqual(1, actual.Count,
    'The method must return a string list with a single element');
  Assert.AreEqual('campaign1', actual[0],
    'The string list element must be "campaign1".');
  actual.DisposeOf;
end;

procedure TRouteTests.extractCampaignFromThreeRoutesTwoCampaigns;
var
  actual: TStringList;
  map: TDictionary<String, String>;
begin
  map := TDictionary<String, String>.Create;
  map.Add('campaign1/article1', 'destination1');
  map.Add('campaign2/article2', 'destination2');
  map.Add('campaign1/article3', 'destination3');

  actual := aTRoute.extractCampaigns(map);

  Assert.AreEqual(2, actual.Count,
    'The method must return a string list with two elements');
  Assert.IsFalse(actual.indexOf('campaign1') = -1,
    'The string list must contain "campaign1".');
  Assert.IsFalse(actual.indexOf('campaign2') = -1,
    'The string list must contain "campaign2".');

  actual.DisposeOf;
end;

procedure TRouteTests.extractCampaignFromTwoDifferent;
var
  actual: TStringList;
  map: TDictionary<String, String>;
begin
  map := TDictionary<String, String>.Create;
  map.Add('campaign1/article1', 'destination1');
  map.Add('campaign2/article2', 'destination2');
  actual := aTRoute.extractCampaigns(map);
  Assert.AreEqual(2, actual.Count,
    'The method must return a string list with two elements');
  Assert.IsFalse(actual.indexOf('campaign1') = -1,
    'The string list must contain "campaign1".');
  Assert.IsFalse(actual.indexOf('campaign2') = -1,
    'The string list must contain "campaign2".');

  actual.DisposeOf;
end;

procedure TRouteTests.extractCampaignFromTwoEqual;
var
  actual: TStringList;
  map: TDictionary<String, String>;
begin
  map := TDictionary<String, String>.Create;
  map.Add('campaign1/article1', 'destination1');
  actual := aTRoute.extractCampaigns(map);
  Assert.AreEqual(1, actual.Count,
    'The method must return a string list with a single element');
  Assert.AreEqual('campaign1', actual[0],
    'The string list element must be "campaign1".');
  actual.DisposeOf;
end;

/// Ignore those routes whose values are nill
///
procedure TRouteTests.loadRoutesIgnoreNilValues;
var
  mapIn, mapOut: TJSonObject;
  key1, key2, value: String;
begin
  Assert.IsTrue(aTRoute.getRoutes.Count = 0);
  key1 := 'campaign1/article1';
  key2 := 'campaign2/article2';
  value := 'http://www.example.com/';
  mapIn := TJSonObject.Create;
  mapIn.AddPair(key1, value);
  mapIn.AddPair(key2, nil);
  aTRoute.Add(mapIn);
  mapOut := aTRoute.getRoutes;
  Assert.IsTrue(mapOut.Count = 1);
  Assert.AreEqual(mapOut.GetValue(key1).value, value);
  mapIn.DisposeOf;
end;

/// when loading new routes, the list of campaigns gets updated.
procedure TRouteTests.loadTwoRoutesDifferentCampaigns;
var
  mapIn: TJSonObject;
  campaigns: TJsonArray;
  campaignsList: TStringList;
  key1, key2, value1, value2: String;
begin
  Assert.AreEqual(aTRoute.getCampaigns.Count, 0);
  key1 := 'campaign1/article1';
  key2 := 'campaign2/article2';
  value1 := 'http://www.example.com/';
  value2 := 'http://www.another-example.com';
  mapIn := TJSonObject.Create;
  mapIn.AddPair(key1, value1);
  mapIn.AddPair(key2, value2);
  aTRoute.Add(mapIn);
  campaigns := aTRoute.getCampaigns;
  Assert.IsTrue(campaigns.Count = 2, 'campaign list must contain two elements');
  campaignsList := TStringList.Create;
  campaignsList.Add(campaigns.Get(0).value);
  campaignsList.Add(campaigns.Get(1).value);

  Assert.AreNotEqual(campaignsList.indexOf('campaign1'), -1);
  Assert.AreNotEqual(campaignsList.indexOf('campaign2'), -1);
  campaigns.DisposeOf;
  mapIn.DisposeOf;

end;

/// Removes zero routes from two exisitng ones
procedure TRouteTests.remove0From2;
var
  routes: TJsonArray;
  mapIn, mapOut: TJSonObject;
  key1, key2, value1, value2: String;
begin
  Assert.AreEqual(0, aTRoute.getRoutes.Count);
  key1 := 'campaign1/article1';
  value1 := 'http://www.example.com';
  key2 := 'campaign2/article2';
  value2 := 'http://www.another-example.com';

  mapIn := TJSonObject.Create;
  mapIn.AddPair(key1, value1);
  mapIn.AddPair(key2, value2);
  aTRoute.Add(mapIn);

  Assert.AreEqual(2, aTRoute.getRoutes.Count);

  routes := TJsonArray.Create;

  aTRoute.delete(routes);
  mapOut := aTRoute.getRoutes;
  Assert.AreEqual(2, mapOut.Count);
  Assert.AreEqual(value1, mapOut.GetValue(key1).value);
  Assert.AreEqual(value2, mapOut.GetValue(key2).value);
end;

/// Removes the only exising route
procedure TRouteTests.remove1ExistingFrom1;
var
  routes: TJsonArray;
  mapIn: TJSonObject;
  key, value: String;
begin
  Assert.AreEqual(aTRoute.getRoutes.Count, 0);
  key := 'campaign1/article1';
  value := 'http://www.another-example.com';
  mapIn := TJSonObject.Create;
  mapIn.AddPair(key, value);
  aTRoute.Add(mapIn);
  Assert.AreEqual(aTRoute.getRoutes.Count, 1);

  routes := TJsonArray.Create;
  routes.Add(key);
  aTRoute.delete(routes);
  Assert.AreEqual(aTRoute.getRoutes.Count, 0);
end;

/// Tries to removes a route from empty mapping
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

/// Suppose there are two campaigns, with two routes each. Then let's remove
/// just one routes of the first campaign. Both campaign must remain.
procedure TRouteTests.remove1RouteOfCampaign22;
var
  mapIn, mapOut: TJSonObject;
  routes: TJsonArray;
  key11, key12, key21, key22, value11, value12, value21, value22: String;
  campaignsList : TStringList;
begin
  Assert.AreEqual(aTRoute.getCampaigns.Count, 0);
  key11 := 'campaign1/article1';
  key12 := 'campaign1/article2';
  key21 := 'campaign2/article1';
  key22 := 'campaign2/article2';
  value11 := 'http://www.example11.com';
  value12 := 'http://www.example12.com';
  value21 := 'http://www.example21.com';
  value22 := 'http://www.example22.com';
  mapIn := TJSonObject.Create;
  mapIn.AddPair(key11, value11);
  mapIn.AddPair(key12, value12);
  mapIn.AddPair(key21, value21);
  mapIn.AddPair(key22, value22);

  aTRoute.Add(mapIn);
  Assert.AreEqual(2, aTRoute.getCampaigns.Count);

  routes := TJsonArray.Create;
  routes.Add(key11);

  aTRoute.delete(routes);
  Assert.AreEqual(2, aTRoute.getCampaigns.Count);

  campaignsList := TStringList.Create;
  campaignsList.Add(aTRoute.getCampaigns.Get(0).value);
  campaignsList.Add(aTRoute.getCampaigns.Get(1).value);

  Assert.AreNotEqual(campaignsList.indexOf('campaign1'), -1);
  Assert.AreNotEqual(campaignsList.indexOf('campaign2'), -1);

  campaignsList.DisposeOf;

end;

/// Removes two existing routes from the mapping with three routes
procedure TRouteTests.remove2ExistingFrom3;
var
  routes: TJsonArray;
  mapIn: TJSonObject;
  key1, key2, key3, value1, value2, value3: String;
begin
  Assert.AreEqual(aTRoute.getRoutes.Count, 0);
  key1 := 'campaign1/article1';
  key2 := 'campaign2/article2';
  key3 := 'campaign3/article3';
  value1 := 'http://www.example1.com';
  value2 := 'http://www.example2.com';
  value3 := 'http://www.example3.com';
  mapIn := TJSonObject.Create;
  mapIn.AddPair(key1, value1);
  mapIn.AddPair(key2, value2);
  mapIn.AddPair(key3, value3);

  aTRoute.Add(mapIn);
  Assert.AreEqual(3, aTRoute.getRoutes.Count);

  routes := TJsonArray.Create;
  routes.Add(key1);
  routes.Add(key3);
  aTRoute.delete(routes);
  Assert.AreEqual(1, aTRoute.getRoutes.Count);
  Assert.AreEqual(value2, aTRoute.getRoutes.GetValue(key2).value);
end;

/// Suppose there are two campaigns, with two routes each. Then let's remove
/// both routes of the second campaign. Only the first campaign must remain.
procedure TRouteTests.remove2RoutesOfCampaign22;
var
  mapIn, mapOut: TJSonObject;
  routes: TJsonArray;
  key11, key12, key21, key22, value11, value12, value21, value22: String;
begin
  Assert.AreEqual(aTRoute.getCampaigns.Count, 0);
  key11 := 'campaign1/article1';
  key12 := 'campaign1/article2';
  key21 := 'campaign2/article1';
  key22 := 'campaign2/article2';
  value11 := 'http://www.example11.com';
  value12 := 'http://www.example12.com';
  value21 := 'http://www.example21.com';
  value22 := 'http://www.example22.com';
  mapIn := TJSonObject.Create;
  mapIn.AddPair(key11, value11);
  mapIn.AddPair(key12, value12);
  mapIn.AddPair(key21, value21);
  mapIn.AddPair(key22, value22);

  aTRoute.Add(mapIn);
  Assert.AreEqual(2, aTRoute.getCampaigns.Count);

  routes := TJsonArray.Create;
  routes.Add(key21);
  routes.Add(key22);

  aTRoute.delete(routes);
  Assert.AreEqual(1, aTRoute.getCampaigns.Count);
  Assert.AreEqual('campaign1', aTRoute.getCampaigns.Get(0).value);
end;

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

  aTRoute.Add(map1);
  mapOut := aTRoute.getRoutes;

  Assert.IsTrue(mapOut.Count = 0);
end;

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
  aTRoute.Add(mapIn1);
  mapIn2 := TJSonObject.Create;
  mapIn2.AddPair(key, value2);
  aTRoute.Add(mapIn2);

  mapOut := aTRoute.getRoutes;

  Assert.IsTrue(mapOut.Count = 1);
  Assert.AreEqual(mapOut.GetValue(key).value, value1);

  mapIn1.DisposeOf;
  mapIn2.DisposeOf;
end;

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
  aTRoute.Add(mapIn);
  mapOut := aTRoute.getRoutes;
  Assert.IsTrue(mapOut.Count = 1);
  Assert.AreEqual(mapOut.GetValue(key).value, value);
  mapIn.DisposeOf;
end;

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
  aTRoute.Add(mapIn);
  mapOut := aTRoute.getRoutes;
  Assert.IsTrue(mapOut.Count = 2);
  Assert.AreEqual(mapOut.GetValue(key1).value, value1);
  Assert.AreEqual(mapOut.GetValue(key2).value, value2);
  mapIn.DisposeOf;
end;

procedure TRouteTests.Setup;
begin
  aTRoute := TRoute.Create;
end;

procedure TRouteTests.TearDown;
begin
  aTRoute:= nil;
end;

end.
