unit RedirectServerDispatcher;

interface

uses
  Controller.Base,
  MVCFramework,
  Route, System.Classes,
  InterfaceRoute, System.JSON, System.Generics.Collections,
  Settings, Storage, Logger, RequestHandler, InterfaceLogger,
  MVCFramework.Commons, ImageStorage, ServerConfig;

type

  [MVCPath('/news')]
  TRedirectController = class abstract(TBaseController)
  private const
    /// <summary>token corrsponding to the folder containing images</summary>
    IMAGE_STORAGE_TOKEN: String = 'images storage status';
    LOGGER_TOKEN: String = 'logger status';
    ROUTER_TOKEN: String = 'router status';
    STORAGE_TOKEN: String = 'storage status';
    // class var Settings: TSettings;
    class var Router: IRoute;
    class var RequestHandler: IRequestHandler;
    class var Storage: TDMStorage;
    class var Logger: ILogger;
    class var ImageStorage: TImageStorage;
    class var ServerConfig: TServerConfig;
    class var ServerConfigPath: String;

    procedure SendImage(const path: String; const ctx: TWebContext);
    procedure SetConfigFilePath(const path: String);
    procedure ArchiveAndRedirect(const campaign, article, track: String;
      const ctx: TWebContext);
    function GetQueryMap(const data: TStrings): TDictionary<String, String>;
    function feedQueryParams(const Base: String;
      const params: TDictionary<String, String>): String;
    class procedure StartServer();
    class procedure StopServer();
    /// <summary>Validate given argument and in case of success, set
    /// the image dir to that value.
    /// A valid directory name may contain only alphanumeric symbols, underscore
    /// and the path delimiters. </summary>
    procedure SetImagesDir(const dirName: String); overload;
    /// <summary>Convert string into a json object</summary>
    /// <param name="str">string containing a valid json object</param>
    // class function StringToJsonObject(const str: String): TJsonObject;

    // procedure SaveImage(const dir: String; const ctx: TWebContext);
    /// Delete an image in a given location inside the image storage
    // procedure DeleteImage(const path: String);

  protected
    procedure OnBeforeAction(Context: TWebContext; const AActionNAme: string;
      var Handled: Boolean); override;

  public

    // [MVCHTTPMethod([httpGET])]
    // [MVCPath('/echo/($text)')]
    // [MVCProduces('text/plain', 'UTF-8')]
    // procedure Echo(ctx: TWebContext);

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

    /// Get the status of the server and of all its compenents (logger,
    /// router and storage (if any))
    [MVCPath('/server/status')]
    [MVCHTTPMethod([httpGET])]
    procedure getStatusComponents(ctx: TWebContext);

    /// Make the server flush the content of its components (records stored in
    /// caches of the logger, storage) and re-read the config file.
    [MVCPath('/server/reload')]
    [MVCHTTPMethod([httpGET])]
    // procedure reload(ctx: TWebContext);

    /// Redirect to an url corresponding to the given path.
    /// The url-to-path map is taken from the config file.
    [MVCPath('/($campaign)/($article)')]
    [MVCHTTPMethod([httpGET])]
    [MVCProduces('text/html', 'UTF-8')]
    procedure redirectNoTrack(ctx: TWebContext);

    /// Redirect to an url corresponding to the given path.
    /// The url-to-path map is taken from the config file.
    [MVCPath('/($campaign)/($article)/($track)')]
    [MVCHTTPMethod([httpGET])]
    [MVCProduces('text/html', 'UTF-8')]
    procedure redirectAndTrack(ctx: TWebContext);

    /// ================== Routes START ==========
    ///
    // [MVCPath('/routes')]
    // [MVCHTTPMethod([httpGET])]
    // procedure getRoutes(ctx: TWebContext);
    //
    // /// <summary>Delete routes encoded as a json array in the request body </summary>
    // [MVCPath('/routes/delete')]
    // [MVCHTTPMethod([httpPUT])]
    // procedure DeleteRoutes(ctx: TWebContext);
    //
    // /// <summary> Add routes passed in the body of the request.
    // /// Routes whose keys are already present in the redirect mapping,
    // /// are ignored. </summary>
    // /// <return> Json object with routes that were added to the existing ones.</return>
    // [MVCPath('/routes/add')]
    // [MVCHTTPMethod([httpPUT])]
    // procedure addRoutes(ctx: TWebContext);
    ///
    /// ================== Routes END ==========

    /// ================== Logger START ==========
    ///
    // [MVCPath('/logger/status')]
    // [MVCHTTPMethod([httpGET])]
    // procedure getLoggerStatus(ctx: TWebContext);
    //
    // /// <summary>Setter for the logger properties. The properties must be
    // /// passed as a json object.</summary>
    // [MVCPath('/logger/set')]
    // [MVCHTTPMethod([httpPUT])]
    // procedure setLoggerProperty(ctx: TWebContext);
    ///
    /// ================== Logger END ==========

    /// ================== Server START ==========
    ///


    // /// <summary>set the images folder
    // /// It must be passed as a key-value pair associated with IMAGE_DIR_TOKEN
    // /// of a json object </summary>
    // [MVCPath('/server/set/imagesdir')]
    // [MVCHTTPMethod([httpPUT])]
    // procedure SetImagesDir(ctx: TWebContext); overload;
    ///
    /// ================== Server END ==========

    /// ================== Storage START ==========
    ///
    // [MVCPath('/storage/set')]
    // [MVCHTTPMethod([httpPUT])]
    // procedure setStorageProperties(ctx: TWebContext);
    ///
    /// ================== Storage END   ==========

    /// ================== Image upload START =====
    ///
    /// <summary>Save image corresponding to a given article of a given campaign
    /// </summary>
    /// <return>a string representation of the image uri after saving </return>
    // [MVCPath('/save/image')]
    // [MVCHTTPMethod([httpPOST])]
    // procedure SaveCommonImage(ctx: TWebContext);
    //
    // /// <summary>Save image corresponding to a given campaign</summary>
    // /// <return>a string representation of the image uri after saving </return>
    // [MVCPath('/save/image/($campaign)')]
    // [MVCHTTPMethod([httpPOST])]
    // procedure SaveCampaignImage(ctx: TWebContext);
    //
    // /// <summary>Delete an image </summary>
    // [MVCPath('/delete/image/($image)')]
    // [MVCHTTPMethod([httpPOST])]
    // procedure DeleteCommonImage(ctx: TWebContext);
    //
    // /// <summary>Delete an image </summary>
    // [MVCPath('/delete/image/($campaign)/($image)')]
    // [MVCHTTPMethod([httpPOST])]
    // procedure DeleteCampaignImage(ctx: TWebContext);
    ///
    /// ================== Image upload END =======

    // [MVCPath('/statistics/commit')]
    // [MVCHTTPMethod([httpPUT])]
    // procedure flushStatistics(ctx: TWebContext);
    //

  end;

implementation

uses System.IOUtils, System.SysUtils, System.StrUtils,
  FireDAC.Comp.Client, Vcl.Forms, InterfaceAuthentication, System.DateUtils,
  RequestClick, RequestView, SimpleAuthentification, MessageCodes,
  System.RegularExpressions, IdURI, System.Types, Web.HTTPApp, Winapi.Windows;

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

// procedure TRedirectController.addRoutes(ctx: TWebContext);
// var
// mappings: TJsonObject;
// request: TMVCWebRequest;
// begin
// request := ctx.request;
// mappings := request.BodyAsJSONObject();
// Route.addRoutes(mappings)
// end;

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
  bareUrl := Router.getUrl(campaign, article);

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
  TRedirectController.ImageStorage.DisposeOf;
  TRedirectController.RequestHandler := nil;
  TRedirectController.Storage.DisposeOf;
  TRedirectController.Router := nil;
  TRedirectController.Logger := nil;

end;

// procedure TRedirectController.DeleteCampaignImage(ctx: TWebContext);
// var
// path: String;
// outcome: Boolean;
// begin
// path := TPath.Combine(ctx.request.params['campaign'],
// ctx.request.params['image']);
// DeleteImage(path);
// end;

// procedure TRedirectController.DeleteCommonImage(ctx: TWebContext);
// begin
// DeleteImage(ctx.request.params['image']);
// end;
//
// procedure TRedirectController.DeleteImage(const path: String);
// var
// outcome: Boolean;
// res: TJsonObject;
// begin
// outcome := ImageStorage.DeleteImage(path);
// res := TJsonObject.Create();
// res.AddPair(path, TJSonBool.Create(outcome));
// Render(res);
// end;

// procedure TRedirectController.DeleteRoutes(ctx: TWebContext);
// var
// request: TMVCWebRequest;
// begin
// request := ctx.request;
// if request.BodyAsJSONValue is TJsonArray then
// Route.delete(request.BodyAsJSONValue as TJsonArray);
// end;

procedure TRedirectController.getImage(ctx: TWebContext);
begin
  SendImage(ctx.request.params['img'], ctx);
end;

{ Return the logger status. If no logger is set, return a json object
  with a single pair whose key is "logger" and its value is "none" }
// procedure TRedirectController.getLoggerStatus(ctx: TWebContext);
// var
// jo: TJsonObject;
// begin
// if Logger = nil then
// begin
// jo := TJsonObject.Create;
// jo.AddPair('logger', 'none');
// end
// else
// jo := Logger.getStatus();
// Render(jo);
// end;

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

// procedure TRedirectController.getRoutes(ctx: TWebContext);
// begin
// Render(Route.getRoutes);
// end;

procedure TRedirectController.getStatusComponents(ctx: TWebContext);
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
  campaign, imageName, trackCode, requestResource, ip, filePath,
    userAgent: String;
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

procedure TRedirectController.OnBeforeAction(Context: TWebContext;
const AActionNAme: string; var Handled: Boolean);
begin
  // inherited;
end;

// procedure TRedirectController.SaveCampaignImage(ctx: TWebContext);
// var
// campaign: String;
// begin
// campaign := ctx.request.params['campaign'];
// SaveImage(campaign, ctx);
// end;

// procedure TRedirectController.SaveCommonImage(ctx: TWebContext);
// begin
// SaveImage('', ctx);
// end;

// procedure TRedirectController.SaveImage(const dir: String;
// const ctx: TWebContext);
// var
// fs: TFileStream;
// I, numOfFiles: Integer;
// report: TJsonObject;
// status: Boolean;
// path: String;
// begin
// numOfFiles := ctx.request.RawWebRequest.Files.Count;
// report := TJsonObject.Create();
// for I := 0 to numOfFiles - 1 do
// begin
// status := ImageStorage.saveFile(dir, ctx.request.Files[I]);
// report.AddPair(ctx.request.Files[I].FileName, TJSonBool.Create(status))
// end;
// Render(report);
// end;

procedure TRedirectController.SendImage(const path: String;
const ctx: TWebContext);
var
  filePath: String;
begin
  filePath := ImageStorage.getAbsolutePath(path);
  if fileExists(filePath) then
    TMVCStaticContents.SendFile(filePath, 'image/jpg', ctx);
end;

procedure TRedirectController.SetConfigFilePath(const path: String);
begin
  TRedirectController.ServerConfig := TServerConfig.Create(path);

end;

procedure TRedirectController.SetImagesDir(const dirName: String);
begin
  ImageStorage.BaseDir := dirName;
end;

// procedure TRedirectController.SetImagesDir(ctx: TWebContext);
// begin
// SetImagesDir(ctx.request.Body);
// end;

// procedure TRedirectController.setLoggerProperty(ctx: TWebContext);
// var
// request: TMVCWebRequest;
// params: TJsonObject;
// begin
// if Logger = nil then
// Exit();
// request := ctx.request;
// params := request.BodyAsJSONObject();
// Logger.setProperties(params);
// end;

// procedure TRedirectController.setStorageProperties(ctx: TWebContext);
// const
// TAG: String = 'TRedirectController.setStorageProperties';
// var
// params: TJsonObject;
// begin
// if Storage = nil then
// begin
// if (Logger = nil) then
// Logger.logWarning(TAG,
// 'Failed to configure storage properties since no storage is found');
// Exit();
// end;
// params := ctx.request.BodyAsJSONObject();
// if not(params = nil) then
// Storage.setProperties(params);
// end;

{ Initialize the server parameters }
class procedure TRedirectController.StartServer;
var
  ServerConfig: TServerConfig;
begin
  if ParamCount >= 1 then
    TRedirectController.ServerConfigPath := paramstr(1)
  else
  begin
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE),
      15 OR BACKGROUND_RED);
    System.Write('Warning:');
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 7);
    System.Writeln(' the program is called without argument hence ' +
      'no configuration file is to be used.');
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 15);
    System.Writeln('Hardly believe this is what you want.');
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 7);
    StopServer();
  end;

  TRedirectController.Logger := TLogger.Create();
  TRedirectController.Router := TRouter.Create;
  TRedirectController.Router.setLogger(TRedirectController.Logger);
  TRedirectController.Storage := TDMStorage.Create(nil);
  TRedirectController.Storage.Logger := TRedirectController.Logger;
  TRedirectController.RequestHandler := TRequestHandler.Create;
  TRedirectController.RequestHandler.Storage := TRedirectController.Storage;
  TRedirectController.RequestHandler.Logger := TRedirectController.Logger;
  // TRedirectController.ImageStorage := TImageStorage.Create();

  ServerConfig := TServerConfig.Create(TRedirectController.ServerConfigPath);
  if Assigned(ServerConfig) then
  begin
    TRedirectController.Logger.Configure(ServerConfig.Logger);
    TRedirectController.Router.addRoutes(ServerConfig.routes);
//    TRedirectController.Storage.Configure(ServerConfig.DbStorage);

    // TRedirectController.ImageStorage.Configure(ServerConfig.ImageStorage);
    // TImageStorage.Create('images' + PathDelim);

    TRedirectController.Logger.logInfo('TAdvStatsController.StartServer',
      'Start the server with custom settings.');
    ServerConfig.DisposeOf;
  end
  else
  begin
    TRedirectController.Logger.logInfo('TAdvStatsController.StartServer',
      'Start the server with default settings.');

  end

  // TRedirectController.Route := TRoute.Create;
  // TRedirectController.Route.setLogger(TRedirectController.Logger);
  // TRedirectController.Route.addRoutes
  // (StringToJsonObject(TRedirectController.ServerConfig.router));
  //
  // TRedirectController.Storage := TDMStorage.Create(nil);
  // TRedirectController.Storage.CacheSize := 10;
  // TRedirectController.Storage.Logger := TRedirectController.Logger;
  //
  // TRedirectController.RequestHandler := TRequestHandler.Create;
  // TRedirectController.RequestHandler.Storage := TRedirectController.Storage;
  // TRedirectController.RequestHandler.Logger := TRedirectController.Logger;
  //
  // TRedirectController.ImageStorage := TImageStorage.Create('images' + PathDelim)
end;

// class function TRedirectController.StringToJsonObject(const str: String): TJsonObject;
// begin
// Result := TJsonObject.ParseJSONValue
// (TEncoding.ASCII.GetBytes(TRedirectController.ServerConfig.Logger), 0)
// as TJsonObject
// end;

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

// procedure TRedirectController.flushStatistics(ctx: TWebContext);
// begin
// Storage.commit();
// end;

initialization

TRedirectController.StartServer();

finalization

TRedirectController.StopServer();

end.
