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

  end;

implementation

uses
  System.Classes;

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

procedure TRouteTests.Setup;
begin
  aTRoute := TRoute.Create(nil, '');
end;

procedure TRouteTests.TearDown;
begin
  aTRoute.DisposeOf;
end;

end.
