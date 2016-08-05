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
    { A mapping of the routes }
    FMapper: TDictionary<String, String>;
    { a map of campaign statuses: true for active, false for paused }
    FCampaignStatuses: TDictionary<String, Boolean>;
    Logger: ILogger;

  public
    function getUrl(const campaign: String; article: String): String; overload;
    function getPausedCampaigns: TJsonObject;
    function getCampaigns: TJsonObject;
    function convertToRoutes(const lines: TStringList)
      : TDictionary<String, String>;
    procedure loadRoutesFromFile(const fileName: String);
    procedure setRoutes(const routes: TDictionary<String, String>);
    procedure markCampaignsAsActive(const campaigns: TStringList);
    function extractCampaigns(const routes: TDictionary<String, String>)
      : TStringList;
    function extractCampaign(const str: String; const separ: Char): String;
    function getRoutes(): TJsonObject;
    procedure setCampaignStatus(const campaign: String;
      const status: Boolean); overload;
    procedure configure(const Logger: ILogger; const fileName: String);
    constructor Create(const Logger: ILogger; const routeFileName: String);
    destructor Destroy; override;
  end;

implementation

uses
  System.IOUtils,
  System.SysUtils, System.RegularExpressions;

constructor TRoute.Create(const Logger: ILogger; const routeFileName: String);
begin
  FMapper := TDictionary<String, String>.Create;
  FCampaignStatuses := TDictionary<String, Boolean>.Create;
  configure(Logger, routeFileName);
end;

destructor TRoute.Destroy;
begin
  FMapper.Clear;
  FMapper.DisposeOf;

  FCampaignStatuses.Clear;
  FCampaignStatuses.DisposeOf;
  Logger := nil;
  inherited;
end;

{ Splits a string using a separator and returns the first non-empty substring (if exists) }
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

{ Re }
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
      Result.Add(campaign);
  end;

end;

procedure TRoute.configure(const Logger: ILogger; const fileName: String);
const
  TAG: String = 'TRoute.configure';
begin
  self.Logger := Logger;
  loadRoutesFromFile(fileName);
end;

{ Retrieve an url corresponding to the argument. }
function TRoute.getUrl(const campaign: String; article: String): String;
var
  aValue: String;
begin
  Result := '';
  aValue := campaign + '/' + article;
  if (FCampaignStatuses.ContainsKey(campaign) AND FCampaignStatuses.Items[campaign]
    AND FMapper.ContainsKey(aValue)) then
    Result := FMapper.Items[aValue];
end;

procedure TRoute.markCampaignsAsActive(const campaigns: TStringList);
var
  key: String;
begin
  FCampaignStatuses.Clear;
  for key in campaigns do
  begin
    FCampaignStatuses.Add(key, True);
  end;

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
      Result.Add(Items[0], Items[1])
    else
      Logger.logInfo(TAG, 'line "' + line + '" seems to contain ' +
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
    if not(Logger = nil) then
      Logger.logInfo(TAG, 'can not load the routes because the file "' +
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
      Logger.logException(TAG, E.Message);
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
  if (FCampaignStatuses.ContainsKey(campaign)) then
    FCampaignStatuses.Items[campaign] := status;
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
    FMapper.Add(item.key, item.Value);
  end;
end;

function TRoute.getCampaigns: TJsonObject;
var
  item: TPair<String, Boolean>;
  Counter: Integer;
begin
  Result := TJsonObject.Create;
  Counter := 0;
  for item in FCampaignStatuses do
  begin
    Result.AddPair(IntToStr(Counter), item.key);
    Counter := Counter + 1;
  end;
end;

function TRoute.getPausedCampaigns: TJsonObject;
var
  item: TPair<String, Boolean>;
  Counter: Integer;
begin
  Result := TJsonObject.Create;
  Counter := 0;
  for item in FCampaignStatuses do
    if not(item.Value) then
    begin
      Result.AddPair(IntToStr(Counter), item.key);
      Counter := Counter + 1;
    end;
end;

function TRoute.getRoutes(): TJsonObject;
var
  key, Value: String;
begin
  Result := TJsonObject.Create;
  for key in self.FMapper.Keys do
  begin
    Value := self.FMapper.Items[key];
    Result.AddPair(key, Value);
  end;
end;

end.
