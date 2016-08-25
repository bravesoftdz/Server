unit Route;

interface

uses
  System.Generics.Collections,
  System.JSON,
  InterfaceRoute,
  Settings,
  InterfaceLogger, System.Classes;

type
  TRoute = class(TInterfacedObject, IRoute)
  private
    /// <summary> A mapping of the routes </summary>
    FMapper: TDictionary<String, String>;
    /// <summary>a map of campaign statuses: true for active, false for paused </summary>
    FCampaignStatuses: TDictionary<String, Boolean>;
    FLogger: ILogger;
    function campaignExistsInMapper(const campaign: String): Boolean;

  public
    function getUrl(const campaign: String; article: String): String; overload;
    function getPausedCampaigns: TJsonArray;
    function getCampaigns: TJsonArray;
    function convertToRoutes(const lines: TStringList)
      : TDictionary<String, String>;
    procedure loadRoutesFromFile(const fileName: String);
    procedure setRoutes(const routes: TDictionary<String, String>);
    procedure markCampaignsAsActive(const campaigns: TStringList);
    function extractCampaigns(const routes: TDictionary<String, String>)
      : TStringList;
    /// <summary>Splits a string using a separator and returns the first
    /// non-empty substring (if exists)</summary>
    function extractCampaign(const str: String; const separ: Char): String;
    function getRoutes(): TJsonObject;
    procedure setCampaignStatus(const campaign: String;
      const status: Boolean); overload;
    procedure configure(const Logger: ILogger; const fileName: String);
    /// <summary> Deprecated.
    /// Do not use it, because it loads routes from a file and hence
    /// breaks the RESTful approach </summary>
    constructor Create(const Logger: ILogger;
      const routeFileName: String); overload;
    constructor Create();  overload;
    procedure add(const routes: TJsonObject);
    procedure delete(const routes: TJsonArray);
    destructor Destroy; override;
    procedure Reset();
    function getStatus(): TJsonObject;
    /// <summary> logger setter</summary>
    procedure setLogger(const Logger: ILogger);
  end;

implementation

uses
  System.IOUtils,
  System.SysUtils, System.RegularExpressions;

constructor TRoute.Create;
begin
  FMapper := TDictionary<String, String>.Create;
  FCampaignStatuses := TDictionary<String, Boolean>.Create;
end;

constructor TRoute.Create(const Logger: ILogger; const routeFileName: String);
begin
  Raise Exception.Create('Deprecated constructor is used!');
  Create();
  configure(Logger, routeFileName);
end;

destructor TRoute.Destroy;
begin
  Reset();
  FMapper.DisposeOf;
  FCampaignStatuses.DisposeOf;
  FLogger := nil;
  inherited;
end;

function TRoute.extractCampaign(const str: String; const separ: Char): String;
var
  pieces: TArray<String>;
begin
  pieces := str.Trim(separ).Split(separ);
  if (Length(pieces) > 0) then
    Result := pieces[0]
  else
    Result := '';
end;

{ Returns a list of campaigns. }
function TRoute.extractCampaigns(const routes: TDictionary<String, String>)
  : TStringList;
var
  key, campaign: String;
begin
  Result := TStringList.Create;
  for key in routes.Keys do
  begin
    campaign := extractCampaign(key, '/');
    if not(campaign.IsEmpty) AND (Result.IndexOf(campaign) = -1) then
      Result.add(campaign);
  end;

end;

// { Adds routes to exisitng one. In case a route key already exists, the new route
// is ignored. The argument is subbosed to have the following format:
// {'campaign1/route1':'http://www.example.com',
// 'campaign2/route2':'http://www.another-example.com',
// .... }
// }
procedure TRoute.add(const routes: TJsonObject);
var
  aPair: TJSONPair;
  key, value, campaign: String;
begin
  if assigned(routes) then
  begin
    for aPair in routes do
    begin
      key := aPair.JsonString.value;
      value := aPair.JsonValue.value;
      if not(FMapper.containsKey(key)) then
      begin
        FMapper.add(key, value);
        // update the campaign list
        campaign := extractCampaign(key, '/');
        if not(campaign.IsEmpty) AND not(FCampaignStatuses.containsKey(campaign))
        then
          FCampaignStatuses.add(campaign, true);
      end;
    end;
  end;
end;

/// Returns true if there is at least one route corresponding
// to the given campaign, false otherwise.
function TRoute.campaignExistsInMapper(const campaign: String): Boolean;
var
  item: TPair<String, String>;
  routeCampaign: String;
begin
  Result := False;
  for item in FMapper do
  begin
    routeCampaign := extractCampaign(item.key, '/');
    if (campaign = routeCampaign) then
    begin
      Result := true;
      Exit
    end;

  end;

end;

{ Reset the mapper and the campaign statuses }
procedure TRoute.Reset;
begin
  FMapper.Clear;
  FCampaignStatuses.Clear;
end;

procedure TRoute.configure(const Logger: ILogger; const fileName: String);
const
  TAG: String = 'TRoute.configure';
begin
  self.FLogger := Logger;
  loadRoutesFromFile(fileName);
end;

{ Retrieve an url corresponding to the argument. }
function TRoute.getUrl(const campaign: String; article: String): String;
var
  aValue: String;
begin
  Result := '';
  aValue := campaign + '/' + article;
  if (FCampaignStatuses.containsKey(campaign) AND FCampaignStatuses.Items
    [campaign] AND FMapper.containsKey(aValue)) then
    Result := FMapper.Items[aValue];
end;

procedure TRoute.markCampaignsAsActive(const campaigns: TStringList);
var
  key: String;
begin
  FCampaignStatuses.Clear;
  for key in campaigns do
  begin
    FCampaignStatuses.add(key, true);
  end;

end;

/// Delete given routes.
/// The argument is suposed of the following format
/// {0: 'route1', 1: 'route2', ...}
procedure TRoute.delete(const routes: TJsonArray);
var
  routeJSONValue: TJSONValue;
  Route, campaign: String;
begin
  if (routes = nil) OR (routes.Count = 0) then
    Exit();
  for routeJSONValue in routes do
  begin
    Route := routeJSONValue.value;
    if FMapper.containsKey(Route) then
    begin
      FMapper.remove(Route);
      campaign := extractCampaign(Route, '/');
      if not(campaignExistsInMapper(campaign)) then
      begin
        FCampaignStatuses.remove(campaign);
      end;
    end;

  end
end;

function TRoute.convertToRoutes(const lines: TStringList)
  : TDictionary<String, String>;
const
  TAG: String = 'TRoute.loadRoutes';
var
  line: String;
  RegexObj: TRegEx;
  Items: TArray<String>;
  itemNumber: Integer;
begin
  Result := TDictionary<String, String>.Create;
  // split the string on inner white spaces
  RegexObj := TRegEx.Create('(?<=[^\s])\s+(?=[^\s])');
  for line in lines do
  begin
    Items := RegexObj.Split(Trim(line), 0);
    itemNumber := Length(Items);
    if (itemNumber = 2) then
      Result.add(Items[0], Items[1])
    else if assigned(FLogger) then
      FLogger.logInfo(TAG, 'line "' + line + '" seems to contain ' +
        IntToStr(itemNumber) + ' entries (expected: 2)');
  end;
  Items := nil;
end;

{ Read the file with given name, convert its content into string-to-string maps
  and sets these maps as new routes.
}
procedure TRoute.loadRoutesFromFile(const fileName: String);
const
  TAG: String = 'TRoute.loadRoutes';
var
  lines: TStringList;
  routes: TDictionary<String, String>;
  campaigns: TStringList;
begin
  if not(fileExists(fileName)) then
  begin
    if assigned(FLogger) then
      FLogger.logInfo(TAG, 'can not load the routes because the file "' +
        fileName + '" does not exist.');
    Exit
  end;
  try
    lines := TStringList.Create;
    try
      lines.LoadFromFile(fileName);
      try
        routes := convertToRoutes(lines);
        campaigns := extractCampaigns(routes);
        try
          setRoutes(routes);
          markCampaignsAsActive(campaigns);
        finally
          routes.Clear;
          routes.DisposeOf;
          campaigns.Clear;
          campaigns.DisposeOf
        end;
      except
        on E: Exception do
      end;
    finally
      lines.Clear;
      lines.DisposeOf;
    end;
  except
    on E: Exception do
    begin
      if assigned(FLogger) then
        FLogger.logException(TAG, E.Message);
    end;
  end;
end;

{
  Sets the status of the campaign. The compaign must exist in order to its status
  to be set.
}
procedure TRoute.setCampaignStatus(const campaign: String;
  const status: Boolean);
begin
  if (FCampaignStatuses.containsKey(campaign)) then
    FCampaignStatuses.Items[campaign] := status;
end;

procedure TRoute.setLogger(const Logger: ILogger);
begin
  self.FLogger := Logger;
end;

{ Reset the previous routes and copy the new ones one-by-one from given maps
  into the class member }
procedure TRoute.setRoutes(const routes: TDictionary<String, String>);
var
  item: TPair<String, String>;
begin
  FMapper.Clear;
  for item in routes do
  begin
    FMapper.add(item.key, item.value);
  end;
end;

/// Returns a list of campaigns.
///
function TRoute.getCampaigns: TJsonArray;
var
  item: TPair<String, Boolean>;
  Counter: Integer;
begin
  Result := TJsonArray.Create;
  for item in FCampaignStatuses do
  begin
    Result.add(item.key);
  end;
end;

function TRoute.getPausedCampaigns: TJsonArray;
var
  item: TPair<String, Boolean>;
  Counter: Integer;
begin
  Result := TJsonArray.Create;
  Counter := 0;
  for item in FCampaignStatuses do
    if not(item.value) then
    begin
      Result.add(item.key);
    end;
end;

function TRoute.getRoutes(): TJsonObject;
var
  key, value: String;
begin
  Result := TJsonObject.Create;
  for key in self.FMapper.Keys do
  begin
    value := self.FMapper.Items[key];
    Result.AddPair(key, value);
  end;
end;

{ Return status of the router }
function TRoute.getStatus: TJsonObject;
begin
  Result := TJsonObject.Create;
  Result.AddPair('logger', TJSonBool.Create(assigned(FLogger)));
  Result.AddPair('routes', TJSonNumber.Create(FMapper.Count));
end;

initialization

finalization

end.
