unit RedirectServerDispatcher;

interface

uses
  Controller.Base,
  MVCFramework,
  Route, System.Classes,
  InterfaceRoute, System.JSON, System.Generics.Collections,
  Settings, Storage, Logger, RequestHandler, InterfaceLogger,
  MVCFramework.Commons;

type

  [MVCPath('/news')]
  TRedirectController = class abstract(TBaseController)
  private const
    /// <summary>token corrsponding to the folder containing images</summary>
    IMAGE_DIR_TOKEN: String = 'images dir';
//    class var Settings: TSettings;
    class var Route: IRoute;
    class var RequestHandler: IRequestHandler;
    class var Storage: TDMStorage;
    class var Logger: ILogger;
    class var ImgDir: String;

    procedure SendImage(const path: String; const ctx: TWebContext);
    procedure ArchiveAndRedirect(const campaign, article, track: String;
      const ctx: TWebContext);
    function GetQueryMap(const data: TStrings): TDictionary<String, String>;
    function feedQueryParams(const Base: String;
      const params: TDictionary<String, String>): String;
    class procedure StartServer();
    class procedure StopServer();
    /// <summary>Get json object containing server proper parameters</summary>
    function getStatus(): TJsonObject;
    /// <summary>Validate given argument and in case of success, set
    /// the image dir to that value.
    /// A valid directory name may contain only alphanumeric symbols, underscore
    /// and the path delimiters. </summary>
    procedure SetImagesDir(const dirName: String); overload;

  protected
    procedure OnBeforeAction(Context: TWebContext; const AActionNAme: string;
      var Handled: Boolean); override;

  public

    [MVCHTTPMethod([httpGET])]
    [MVCPath('/echo/($text)')]
    [MVCProduces('text/plain', 'UTF-8')]
    procedure Echo(ctx: TWebContext);

    [MVCPath('/images/($img)')]
    [MVCHTTPMethod([httpGET])]
    procedure getImage(ctx: TWebContext);

    [MVCPath('/images/($campaign)/($img)')]
    [MVCHTTPMethod([httpGET])]
    procedure getCampaignImage(ctx: TWebContext);

    [MVCPath('/images/($campaign)/($trackCode)/($img)')]
    [MVCHTTPMethod([httpGET])]
    procedure getCampaignImageWithTrack(ctx: TWebContext);

    /// ================== Routes START ==========
    ///
    [MVCPath('/routes')]
    [MVCHTTPMethod([httpGET])]
    procedure getRoutes(ctx: TWebContext);

    [MVCPath('/routes/delete')]
    [MVCHTTPMethod([httpPUT])]
    procedure DeleteRoutes(ctx: TWebContext);

    /// <summary> Add routes passed in the body of the request.
    /// Routes whose keys are already present in the redirect mapping,
    /// are ignored. </summary>
    /// <return> Json object with routes that were added to the existing ones.</return>
    [MVCPath('/routes/add')]
    [MVCHTTPMethod([httpPUT])]
    procedure addRoutes(ctx: TWebContext);
    ///
    /// ================== Routes END ==========

    /// ================== Logger START ==========
    ///
    [MVCPath('/logger/status')]
    [MVCHTTPMethod([httpGET])]
    procedure getLoggerStatus(ctx: TWebContext);

    /// <summary>Setter for the logger properties. The properties must be
    /// passed as a json object.</summary>
    [MVCPath('/logger/set')]
    [MVCHTTPMethod([httpPUT])]
    procedure setLoggerProperty(ctx: TWebContext);
    ///
    /// ================== Logger END ==========

    /// ================== Server START ==========
    ///
    /// <summary>Get the status of the server and of all its compenents (logger,
    /// router and storage (if any))</summary>
    [MVCPath('/server/status')]
    [MVCHTTPMethod([httpGET])]
    procedure getStatusComponents(ctx: TWebContext);

    /// <summary>set the images folder
    /// It must be passed as a key-value pair associated with IMAGE_DIR_TOKEN
    /// of a json object </summary>
    [MVCPath('/server/set/imagesdir')]
    [MVCHTTPMethod([httpPUT])]
    procedure SetImagesDir(ctx: TWebContext); overload;
    ///
    /// ================== Server END ==========

    /// ================== Storage START ==========
    ///
    [MVCPath('/storage/set')]
    [MVCHTTPMethod([httpPUT])]
    procedure setStorageProperties(ctx: TWebContext);

    /// ================== Storage END   ==========

    [MVCPath('/statistics/commit')]
    [MVCHTTPMethod([httpPUT])]
    procedure flushStatistics(ctx: TWebContext);

    [MVCPath('/($campaign)/($article)')]
    [MVCHTTPMethod([httpGET])]
    [MVCProduces('text/html', 'UTF-8')]
    procedure redirectNoTrack(ctx: TWebContext);

    [MVCPath('/($campaign)/($article)/($track)')]
    [MVCHTTPMethod([httpGET])]
    [MVCProduces('text/html', 'UTF-8')]
    procedure redirectAndTrack(ctx: TWebContext);
  end;

implementation

uses System.IOUtils, System.SysUtils, System.StrUtils,
  FireDAC.Comp.Client, Vcl.Forms, InterfaceAuthentication, System.DateUtils,
  RequestClick, RequestView, SimpleAuthentification, MessageCodes,
  System.RegularExpressions, IdURI, System.Types;

{ TRedirectController }

procedure TRedirectController.redirectNoTrack(ctx: TWebContext);
var
  resourse: String;
  request: TMVCWebRequest;
begin
  request := ctx.request;
  resourse := request.params['campaign'] + '/' + request.params['article'];
  ArchiveAndRedirect(request.params['campaign'],
    request.params['article'], '', ctx);
end;

procedure TRedirectController.redirectAndTrack(ctx: TWebContext);
var
  resourse, track: String;
  request: TMVCWebRequest;
begin
  request := ctx.request;
  resourse := request.params['campaign'] + '/' + request.params['article'];
  track := request.params['track'];
  ArchiveAndRedirect(request.params['campaign'], request.params['article'],
    track, ctx);
end;

procedure TRedirectController.addRoutes(ctx: TWebContext);
var
  mappings: TJsonObject;
  request: TMVCWebRequest;
begin
  request := ctx.request;
  mappings := request.BodyAsJSONObject();
  Route.add(mappings)
end;

procedure TRedirectController.ArchiveAndRedirect(const campaign, article,
  track: String; const ctx: TWebContext);
const
  TAG: String = 'TAdvStatsController.ArchiveAndRedirect';

var
  bareUrl, url, userAgent, ip, resourse, queryStr: String;
  request: TMVCWebRequest;
  click: TRequestClick;
  paramMap: TDictionary<String, String>;
  query: TStrings;
begin
  request := ctx.request;
  resourse := campaign + '/' + article;
  bareUrl := Route.getUrl(campaign, article);

  if not(bareUrl.isEmpty) then
  begin
    ip := request.ClientIP;
    userAgent := request.Headers['User-Agent'];
    query := request.RawWebRequest.QueryFields;
    queryStr := query.Text.Trim;
    paramMap := GetQueryMap(query);
    url := feedQueryParams(bareUrl, paramMap);
    paramMap.Clear;
    paramMap.DisposeOf;
    TThread.CreateAnonymousThread(
      procedure
      begin
        click := TRequestClick.Create;
        click.setField('ip', ip);
        click.setCampaign(campaign);
        click.setField('user-agent', userAgent);
        click.setField('request', resourse);
        click.setField('trackCode', track);
        click.setField('query', queryStr);
        click.setField('target', url);
        RequestHandler.Archive(click);
      end).start;
    Redirect(url);
  end
  else
  begin
    Logger.logInfo(TAG, 'campaign: ' + campaign + ', no redirect for ' +
      request.PathInfo + ': ip = ' + ctx.request.ClientIP);
  end;

end;

class procedure TRedirectController.StopServer;
begin
  TRedirectController.Logger.logInfo('TAdvStatsController.StopServer',
    'Stop the server');
  TRedirectController.RequestHandler := nil;
  TRedirectController.Storage.DisposeOf;
  TRedirectController.Route := nil;
  TRedirectController.Logger := nil;

end;

{ Delete routes encoded as a json array in the request body }
procedure TRedirectController.DeleteRoutes(ctx: TWebContext);
var
  request: TMVCWebRequest;
begin
  request := ctx.request;
  if request.BodyAsJSONValue is TJsonArray then
    Route.delete(request.BodyAsJSONValue as TJsonArray);
end;

procedure TRedirectController.getImage(ctx: TWebContext);
begin
  SendImage(ctx.request.params['img'], ctx);
end;

{ Return the logger status. If no logger is set, return a json object
  with a single pair whose key is "logger" and its value is "none" }
procedure TRedirectController.getLoggerStatus(ctx: TWebContext);
var
  jo: TJsonObject;
begin
  if Logger = nil then
  begin
    jo := TJsonObject.Create;
    jo.AddPair('logger', 'none');
  end
  else
    jo := Logger.getStatus();
  Render(jo);
end;

function TRedirectController.GetQueryMap(const data: TStrings)
  : TDictionary<String, String>;
var
  line: String;
  parts: TStringDynArray;
begin
  Result := TDictionary<String, String>.Create;
  for line in data do
  begin
    parts := SplitString(line, '=');
    if Length(parts) = 2 then
      Result.add(parts[0], parts[1]);
  end;

end;

procedure TRedirectController.getRoutes(ctx: TWebContext);
begin
  Render(Route.getRoutes);
end;

procedure TRedirectController.getStatusComponents(ctx: TWebContext);
var
  status: TJsonObject;
begin
  status := getStatus();
  if not(Logger = nil) then
    status.AddPair('logger status', Logger.getStatus);
  if not(Route = nil) then
    status.AddPair('router status', Route.getStatus);
  if not(Storage = nil) then
    status.AddPair('storage status', Storage.getStatus);
  if not(ImgDir.isEmpty) then
    status.AddPair(IMAGE_DIR_TOKEN, ImgDir);
  Render(status);
end;

function TRedirectController.getStatus: TJsonObject;
begin
  Result := TJsonObject.Create;
  Result.AddPair(IMAGE_DIR_TOKEN, ImgDir);
end;

procedure TRedirectController.getCampaignImage(ctx: TWebContext);
var
  imageName, campaign: String;
  filePath: String;
begin
  campaign := ctx.request.params['campaign'];
  imageName := ctx.request.params['img'];
  filePath := campaign + '/' + imageName;
  SendImage(filePath, ctx);
  ctx.Response.ContentType := TMVCMediaType.IMAGE_PNG + ';charset=UTF-16';
end;

procedure TRedirectController.getCampaignImageWithTrack(ctx: TWebContext);
var
  campaign, imageName, trackCode: String;
  ip, filePath, userAgent: String;
  request: TMVCWebRequest;
  view: TRequestView;

begin
  request := ctx.request;
  campaign := request.params['campaign'];
  imageName := request.params['img'];
  trackCode := request.params['trackCode'];
  ip := request.ClientIP;
  userAgent := request.Headers['User-Agent'];
  filePath := campaign + '/' + imageName;
  TThread.CreateAnonymousThread(
    procedure
    begin
      view := TRequestView.Create;
      view.setField('ip', ip);
      view.setCampaign(campaign);
      view.setField('user-agent', userAgent);
      view.setField('request', filePath);
      view.setField('trackCode', trackCode);
      RequestHandler.Archive(view);
    end).start;
  SendImage(filePath, ctx);
end;

procedure TRedirectController.OnBeforeAction(Context: TWebContext;
const AActionNAme: string; var Handled: Boolean);
begin
  // inherited;
end;

procedure TRedirectController.SendImage(const path: String;
const ctx: TWebContext);
var
  filePath: String;
begin
  filePath := ImgDir + path;
  if fileExists(filePath) then
    TMVCStaticContents.SendFile(filePath, 'image/jpg', ctx);
end;

procedure TRedirectController.SetImagesDir(const dirName: String);
var
  regex: TRegEx;
  dirNameTmp: String;
begin
  /// a pattern for invalid folder names
  regex := TRegEx.Create('[^a-zA-Z0-9_\' + PathDelim + ']');
  if (regex.isMatch(dirName)) then
    Exit;
  /// remove trailing path delimiters
  dirNameTmp := TRegEx.Replace(dirName, '^(\' + PathDelim + ')*|(\' + PathDelim
    + ')*$', '');
  /// remove duplicate path delimiters
  dirNameTmp := TRegEx.Replace(dirNameTmp, '(\' + PathDelim + ')*', PathDelim);
  if not(dirName.isEmpty) then
    TRedirectController.ImgDir := IncludeTrailingPathDelimiter(dirName);
end;

procedure TRedirectController.SetImagesDir(ctx: TWebContext);
var
  request: TMVCWebRequest;
  params: TJsonObject;
  item: TJSonValue;
  dirName: String;
begin
  request := ctx.request;
  params := request.BodyAsJSONObject();
  item := params.GetValue(IMAGE_DIR_TOKEN);
  if (item = nil) then
    Exit();
  dirName := item.Value;
  SetImagesDir(dirName);
end;

procedure TRedirectController.setLoggerProperty(ctx: TWebContext);
var
  request: TMVCWebRequest;
  params: TJsonObject;
begin
  if Logger = nil then
    Exit();
  request := ctx.request;
  params := request.BodyAsJSONObject();
  Logger.setProperties(params);
end;

procedure TRedirectController.setStorageProperties(ctx: TWebContext);
const
  TAG: String = 'TRedirectController.setStorageProperties';
var
  params: TJsonObject;
begin
  if Storage = nil then
  begin
    if (Logger = nil) then
      Logger.logWarning(TAG,
        'Failed to configure storage properties since no storage is found');
    Exit();
  end;
  params := ctx.request.BodyAsJSONObject();
  if not(params = nil) then
    Storage.setConnectionSettings(params);
end;

{ Initialize the server parameters }
class procedure TRedirectController.StartServer;
begin
  TRedirectController.Logger := TLogger.Create('log' + PathDelim, 10);
  TRedirectController.Logger.logInfo('TAdvStatsController.StartServer',
    'Start the server.');

  TRedirectController.Route := TRoute.Create;
  TRedirectController.Route.setLogger(TRedirectController.Logger);

  TRedirectController.Storage := TDMStorage.Create(nil);
  TRedirectController.Storage.Logger := TRedirectController.Logger;

  TRedirectController.RequestHandler := TRequestHandler.Create(10);
  TRedirectController.RequestHandler.Storage := TRedirectController.Storage;
  TRedirectController.RequestHandler.Logger := TRedirectController.Logger;
end;

procedure TRedirectController.Echo(ctx: TWebContext);
begin
  Render(ctx.request.params['text']);
end;

function TRedirectController.feedQueryParams(const Base: String;
const params: TDictionary<String, String>): String;
var
  URI: TIdURI;
  query, queryBound: String;
  item: TPair<String, String>;
begin
  URI := nil;
  try
    URI := TIdURI.Create(Base);
    query := URI.params;
    queryBound := query;
    if Length(query) > 0 then
    begin
      for item in params do
      // for param in params.Keys do
      begin
        queryBound := StringReplace(queryBound, item.Key + '=',
          item.Key + '=' + item.Value, [rfReplaceAll]);
      end;
    end;
  finally
    if Assigned(URI) then
      URI.Free;
  end;
  Result := StringReplace(Base, query, queryBound, [rfReplaceAll]);
end;

procedure TRedirectController.flushStatistics(ctx: TWebContext);
begin
  RequestHandler.commit();
end;

initialization

TRedirectController.StartServer();

finalization

TRedirectController.StopServer();

end.
