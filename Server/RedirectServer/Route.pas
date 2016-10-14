unit Route;

interface

uses
  System.Generics.Collections,
  System.JSON,
  InterfaceRoute,
  ServerConfig,
  InterfaceLogger, System.Classes;

type
  TRouteConfig = class

  end;

type
  /// <summary>Manage routes.
  /// This class performs a redirect from one url to another.
  /// It msut be as fast as possible, so it should contain as little logic as
  /// possible.
  /// In fact, it contains just a string-to-string dictinary corresponding to the
  /// redirects.
  /// </summary>
  TRouter = class(TInterfacedObject, IRoute)
  private
    /// <summary> A dictionary of the redirects </summary>
    FMapper: TDictionary<String, String>;
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
    /// In case a route key already exists, the new route
    // is ignored.
    /// </summary>
    procedure addRoutes(const routes: TObjectList<TRouteMapper>);
    /// <summary>Delete routes.
    /// The argument is suposed of the following format
    /// {0: 'route1', 1: 'route2', ...}</summary>
    procedure delete(const routes: TJsonArray);
    destructor Destroy; override;
    /// <summary>Return the router status </summary>
    function getStatus(): TJsonObject;
  end;

implementation

uses
  System.IOUtils,
  System.SysUtils, System.RegularExpressions;

constructor TRouter.Create;
begin
  FMapper := TDictionary<String, String>.Create;
end;

destructor TRouter.Destroy;
begin
  FMapper.Clear;
  FMapper.DisposeOf;
  inherited;
end;

procedure TRouter.addRoutes(const routes: TObjectList<TRouteMapper>);
var
  mapper: TRouteMapper;
  key, value: String;
begin
  if routes = nil then
    Exit();
  for mapper in routes do
  begin
    key := mapper.key;
    value := mapper.value;
    if not(FMapper.containsKey(key)) then
      FMapper.add(key, value);
  end;
end;

function TRouter.getUrl(const campaign: String; article: String): String;
var
  aValue: String;
begin
  Result := '';
  aValue := campaign + '/' + article;
  if FMapper.containsKey(aValue) then
    Result := FMapper.Items[aValue];
end;

procedure TRouter.delete(const routes: TJsonArray);
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

procedure TRouter.setRoutes(const routes: TDictionary<String, String>);
var
  item: TPair<String, String>;
begin
  FMapper.Clear;
  for item in routes do
    FMapper.add(item.key, item.value);
end;

function TRouter.getRoutes(): TJsonObject;
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

function TRouter.getStatus: TJsonObject;
begin
  Result := TJsonObject.Create;
  Result.AddPair('routes', TJSonNumber.Create(FMapper.Count));
end;

initialization

finalization

end.
