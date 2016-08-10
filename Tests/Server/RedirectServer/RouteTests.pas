unit RouteTests;

interface

uses
  DUnitX.TestFramework, System.Generics.Collections, Route;

type

  [TestFixture]
  TRouteTests = class(TObject)
  strict private
    aTRoute: TRoute;
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
  campaigns: TStringList;
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
  Assert.IsTrue(campaigns.Count = 2,
    'campaign list must contain two elements');

  Assert.AreNotEqual(campaigns.indexOf('campaign1'), -1);
  Assert.AreNotEqual(campaigns.indexOf('campaign2'), -1);
  campaigns.Clear;
  campaigns.DisposeOf;
  mapIn.DisposeOf;

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
  aTRoute := TRoute.Create(nil, '');
end;

procedure TRouteTests.TearDown;
begin
  aTRoute.DisposeOf;
end;

end.
