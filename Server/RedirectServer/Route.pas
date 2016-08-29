unit Route;

interface

uses
  System.Generics.Collections,
  System.JSON,
  InterfaceRoute,
  // Settings,
  InterfaceLogger, System.Classes;

type
  /// <summary>Manage routes.
  /// This class performs a redirect from one url to another.
  /// It msut be as fast as possible, so it should contain as little logic as
  /// possible.
  /// In fact, it contains just a string-to-string dictinary corresponding to the
  /// redirects.
  /// </summary>
  TRoute = class(TInterfacedObject, IRoute)
  private
    /// <summary> A dictionary of the redirects </summary>
    FMapper: TDictionary<String, String>;
    /// <summary>[Optional] a logger by means of which to log important events.</summary>
    FLogger: ILogger;
  public
    /// <summary>Retrieve an url corresponding to the argument.</summary>
    function getUrl(const campaign: String; article: String): String; overload;
    /// <summary> Reset the exisiting map of the routes and add new ones
    /// copying them one-by-one from given ones
    /// </summary>
    procedure setRoutes(const routes: TDictionary<String, String>);
    /// <summary> Getter of existing redirects</summary>
    function getRoutes(): TJsonObject;
    constructor Create();
    /// <summary> Add given routes to exisiting ones.
    /// The argument is supposed to have the following format:
    // {'campaign1/route1':'http://www.example.com',
    // 'campaign2/route2':'http://www.another-example.com',
    // .... }
    /// In case a route key already exists, the new route
    // is ignored.
    /// </summary>
    procedure addRoutes(const routes: TJsonObject);
    /// <summary>Delete routes.
    /// The argument is suposed of the following format
    /// {0: 'route1', 1: 'route2', ...}</summary>
    procedure delete(const routes: TJsonArray);
    destructor Destroy; override;
    /// <summary>Return the router status </summary>
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
end;

destructor TRoute.Destroy;
begin
  FMapper.Clear;
  FMapper.DisposeOf;
  FLogger := nil;
  inherited;
end;

procedure TRoute.addRoutes(const routes: TJsonObject);
var
  aPair: TJSONPair;
  key, value: String;
begin
  if routes = nil then
    Exit();
  for aPair in routes do
  begin
    key := aPair.JsonString.value;
    value := aPair.JsonValue.value;
    if not(FMapper.containsKey(key)) then
      FMapper.add(key, value);
  end;
end;

function TRoute.getUrl(const campaign: String; article: String): String;
var
  aValue: String;
begin
  Result := '';
  aValue := campaign + '/' + article;
  if FMapper.containsKey(aValue) then
    Result := FMapper.Items[aValue];
end;

procedure TRoute.delete(const routes: TJsonArray);
var
  routeJSONValue: TJSONValue;
  Route: String;
begin
  if (routes = nil) OR (routes.Count = 0) then
    Exit();
  for routeJSONValue in routes do
  begin
    Route := routeJSONValue.value;
    if FMapper.containsKey(Route) then
      FMapper.remove(Route);
  end
end;

procedure TRoute.setLogger(const Logger: ILogger);
begin
  self.FLogger := Logger;
end;

procedure TRoute.setRoutes(const routes: TDictionary<String, String>);
var
  item: TPair<String, String>;
begin
  FMapper.Clear;
  for item in routes do
    FMapper.add(item.key, item.value);
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

function TRoute.getStatus: TJsonObject;
begin
  Result := TJsonObject.Create;
  Result.AddPair('logger', TJSonBool.Create(assigned(FLogger)));
  Result.AddPair('routes', TJSonNumber.Create(FMapper.Count));
end;

initialization

finalization

end.
