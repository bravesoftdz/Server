unit RedirectServerDispatcher;

interface

uses
  Controller.Base,
  MVCFramework,
  Route, System.Classes,
  InterfaceRoute, System.JSON, System.Generics.Collections,
  Settings, Storage, Logger, RequestHandler, InterfaceLogger,
  MVCFramework.Commons, ImageStorage, ServerConfig, InterfaceLoggable;

type

  [MVCPath('/news')]
  TRedirectController = class abstract(TBaseController)
  private const
    /// <summary>token corrsponding to the folder containing images</summary>
    IMAGE_STORAGE_TOKEN: String = 'images storage status';
    LOGGER_TOKEN: String = 'logger status';
    ROUTER_TOKEN: String = 'router status';
    STORAGE_TOKEN: String = 'storage status';

    class var Router: IRoute;
    class var RequestHandler: IRequestHandler;
    class var Storage: TDMStorage;
    class var Logger: ILogger;
    class var ImageStorage: TImageStorage;
    class var ServerConfigPath: String;

    procedure SendImage(const path: String; const ctx: TWebContext);
    procedure ArchiveAndRedirect(const campaign, article, track: String; const ctx: TWebContext);
    function GetQueryMap(const data: TStrings): TDictionary<String, String>;
    function feedQueryParams(const Base: String; const params: TDictionary<String, String>): String;
    class procedure Initialize;
    class procedure StopServer();
    /// <summary>Load configuration from the file whose name is stored
    /// in ServerConfigPath</sumamry>
    class procedure Configure();
    /// <summary>Log the message if the logger is available. Otherwise, ignore
    /// the message.</summary>
    class procedure LogIfPossible(const level: TLEVELS; const tag, msg: string);

  protected
    procedure OnBeforeAction(Context: TWebContext; const AActionNAme: string;
      var Handled: Boolean); override;

  public
    /// <summary>configuration file setter</summary>
    class procedure setConfigFile(const ConfigFile: String);

    /// Retrieve an image from the image storage
    [MVCPath('/images/($img)')]
    [MVCHTTPMethod([httpGET])]
    procedure getImage(ctx: TWebContext);

    /// Retrieve a campaign-specific image from the image storage
    [MVCPath('/images/($campaign)/($img)')]
    [MVCHTTPMethod([httpGET])]
    procedure getCampaignImage(ctx: TWebContext);

    /// Retrieve a campaign specific image from the image storage and keep
    /// track of the request
    [MVCPath('/images/($campaign)/($trackCode)/($img)')]
    [MVCHTTPMethod([httpGET])]
    procedure getCampaignImageWithTrack(ctx: TWebContext);

    /// Get the status of the server along with all its components (logger,
    /// router, db storage, image storage)
    /// The components' statuses are delegated to the components themselves.
    [MVCPath('/server/status')]
    [MVCHTTPMethod([httpGET])]
    procedure getStatus(ctx: TWebContext);

    /// Make the server flush the content of its components (records stored in
    /// caches of the logger, storage) and re-read the config file.
    [MVCPath('/server/reload')]
    [MVCHTTPMethod([httpPOST])]
    procedure reload(ctx: TWebContext);

    /// Redirect to an url corresponding to the given path.
    /// The request gets archived.
    /// The url-to-path map is taken from the config file.
    /// If no url is found, no redirect occurs.
    [MVCPath('/($campaign)/($article)')]
    [MVCHTTPMethod([httpGET])]
    [MVCProduces('text/html', 'UTF-8')]
    procedure redirectNoTrack(ctx: TWebContext);

    /// Redirect to an url corresponding to the given path.
    /// The request gets archived along with the track code.
    /// The url-to-path map is taken from the config file.
    /// If no url is found, no redirect occurs.
    [MVCPath('/($campaign)/($article)/($track)')]
    [MVCHTTPMethod([httpGET])]
    [MVCProduces('text/html', 'UTF-8')]
    procedure redirectAndTrack(ctx: TWebContext);
  end;

implementation

uses System.IOUtils, System.SysUtils, System.StrUtils,
  FireDAC.Comp.Client, Vcl.Forms, System.DateUtils,
  RequestClick, RequestView, MessageCodes,
  System.RegularExpressions, IdURI, System.Types, Web.HTTPApp, Winapi.Windows;

{ TRedirectController }

procedure TRedirectController.redirectNoTrack(ctx: TWebContext);
var
  resourse: String;
  request: TMVCWebRequest;
begin
  request := ctx.request;
  resourse := request.params['campaign'] + '/' + request.params['article'];
  ArchiveAndRedirect(request.params['campaign'], request.params['article'], '', ctx);
end;

procedure TRedirectController.reload(ctx: TWebContext);
begin
  TRedirectController.Storage.Commit;
  TRedirectController.Logger.flushCache;
  Configure;
end;

procedure TRedirectController.redirectAndTrack(ctx: TWebContext);
var
  resourse, track: String;
  request: TMVCWebRequest;
begin
  request := ctx.request;
  resourse := request.params['campaign'] + '/' + request.params['article'];
  track := request.params['track'];
  ArchiveAndRedirect(request.params['campaign'], request.params['article'], track, ctx);
end;

procedure TRedirectController.ArchiveAndRedirect(const campaign, article, track: String;
  const ctx: TWebContext);
const
  tag: String = 'TAdvStatsController.ArchiveAndRedirect';

var
  bareUrl, url, userAgent, ip, resourse, queryStr: String;
  request: TMVCWebRequest;
  click: TRequestClick;
  paramMap: TDictionary<String, String>;
  query: TStrings;
begin
  request := ctx.request;
  resourse := campaign + '/' + article;
  bareUrl := Router.getUrl(campaign, article);

  if (bareUrl.isEmpty) then
    LogIfPossible(TLEVELS.INFO, tag, 'campaign: ' + campaign + ', no redirect for ' +
      request.PathInfo + ': ip = ' + ctx.request.ClientIP)
  else
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
  end;

end;

class procedure TRedirectController.StopServer;
begin
  TRedirectController.Logger.logInfo('TAdvStatsController.StopServer', 'Stop the server');
  TRedirectController.ImageStorage.DisposeOf;
  TRedirectController.RequestHandler := nil;
  TRedirectController.Storage.DisposeOf;
  TRedirectController.Router := nil;
  TRedirectController.Logger := nil;

end;

procedure TRedirectController.getImage(ctx: TWebContext);
begin
  SendImage(ctx.request.params['img'], ctx);
end;

function TRedirectController.GetQueryMap(const data: TStrings): TDictionary<String, String>;
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

procedure TRedirectController.getStatus(ctx: TWebContext);
var
  status: TJsonObject;
begin
  status := TJsonObject.Create;
  if not(Logger = nil) then
    status.AddPair(LOGGER_TOKEN, Logger.getStatus);
  if not(Router = nil) then
    status.AddPair(ROUTER_TOKEN, Router.getStatus);
  if not(Storage = nil) then
    status.AddPair(STORAGE_TOKEN, Storage.getStatus);
  if not(ImageStorage = nil) then
    status.AddPair(IMAGE_STORAGE_TOKEN, ImageStorage.getStatus);
  Render(status);
end;

class procedure TRedirectController.Configure;
const
  tag = 'TRedirectController.Configure';
var
  ServerConfig: TServerConfig;
begin
  ServerConfig := TServerConfig.Create(ServerConfigPath);
  if Assigned(ServerConfig) then
  begin
    TRedirectController.LogIfPossible(TLEVELS.INFO, tag, 'Loading the configuration.');
    TRedirectController.Logger.Configure(ServerConfig.Logger);
    TRedirectController.Router.addRoutes(ServerConfig.Routes);
    TRedirectController.Storage.Configure(ServerConfig.DbStorage);
    TRedirectController.ImageStorage.Configure(ServerConfig.ImageStorage);
    ServerConfig.DisposeOf;
  end
  else
    LogIfPossible(TLEVELS.INFO, tag, 'The content of the configuration file \"' +
      TRedirectController.ServerConfigPath + '\" is ignored.');
end;

class procedure TRedirectController.LogIfPossible(const level: TLEVELS; const tag, msg: string);
begin
  if not(TRedirectController.Logger = nil) then
    TRedirectController.Logger.log(level, tag, msg);

end;

procedure TRedirectController.getCampaignImage(ctx: TWebContext);
var
  imageName, campaign: String;
  filePath: String;
begin
  campaign := ctx.request.params['campaign'];
  imageName := ctx.request.params['img'];
  filePath := TPath.Combine(campaign, imageName);
  SendImage(filePath, ctx);
  // ctx.Response.ContentType := TMVCMediaType.IMAGE_PNG + ';charset=UTF-16';
end;

procedure TRedirectController.getCampaignImageWithTrack(ctx: TWebContext);
var
  campaign, imageName, trackCode, requestResource, ip, filePath, userAgent: String;
  request: TMVCWebRequest;
  view: TRequestView;
begin
  request := ctx.request;
  campaign := request.params['campaign'];
  imageName := request.params['img'];
  trackCode := request.params['trackCode'];
  ip := request.ClientIP;
  userAgent := request.Headers['User-Agent'];
  filePath := TPath.Combine(campaign, imageName);
  requestResource := campaign + '/' + imageName;
  TThread.CreateAnonymousThread(
    procedure
    begin
      view := TRequestView.Create;
      view.setField('ip', ip);
      view.setCampaign(campaign);
      view.setField('user-agent', userAgent);
      view.setField('request', requestResource);
      view.setField('trackCode', trackCode);
      RequestHandler.Archive(view);
    end).start;
  SendImage(filePath, ctx);
end;

procedure TRedirectController.OnBeforeAction(Context: TWebContext; const AActionNAme: string;
var Handled: Boolean);
begin
  // inherited;
end;

procedure TRedirectController.SendImage(const path: String; const ctx: TWebContext);
var
  filePath: String;
begin
  filePath := ImageStorage.getAbsolutePath(path);
  if (TFile.exists(filePath)) then
    TMVCStaticContents.SendFile(filePath, 'image/jpg', ctx);
end;

class procedure TRedirectController.setConfigFile(const ConfigFile: String);
begin
  ServerConfigPath := ConfigFile;
  Configure();
end;


class procedure TRedirectController.Initialize;
begin
  TRedirectController.Logger := TLogger.Create();
  TRedirectController.Router := TRouter.Create;
  TRedirectController.Storage := TDMStorage.Create(nil);
  TRedirectController.Storage.Logger := TRedirectController.Logger;
  TRedirectController.RequestHandler := TRequestHandler.Create;
  TRedirectController.RequestHandler.Storage := TRedirectController.Storage;
  TRedirectController.RequestHandler.Logger := TRedirectController.Logger;
  TRedirectController.ImageStorage := TImageStorage.Create();

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
      begin
        queryBound := StringReplace(queryBound, item.Key + '=', item.Key + '=' + item.Value,
          [rfReplaceAll]);
      end;
    end;
  finally
    if Assigned(URI) then
      URI.Free;
  end;
  Result := StringReplace(Base, query, queryBound, [rfReplaceAll]);
end;

initialization

TRedirectController.Initialize();

finalization

TRedirectController.StopServer();

end.
