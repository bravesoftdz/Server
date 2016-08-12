unit RedirectServerProxy.interfaces;

interface

uses
  MVCFramework.RESTAdapter, MVCFramework, System.Classes, System.JSON;

type
  TResponse = class
  private
    fstatus: String;
    Fclassname: TObject;
    Fmessage: String;
  public
    property status: String read fstatus write fstatus;
    property classname: TObject read Fclassname write Fclassname;
    property message: String read Fmessage write Fmessage;
  end;

  IRedirectServerProxy = interface(IInvokable)
    ['{6001900A-DB38-4251-BE9D-94CA892A8F73}']

    [RESTResource(TMVCHTTPMethodType.httpGET, '/news/images/{campaign}/{img}')]
    [Headers('ContentEncoding', 'UTF-16')]
    function getCampaignImage([Param('campaign')] campaign: string;
      [Param('img')] img: String): string;

    [RESTResource(TMVCHTTPMethodType.httpGET, '/server/ping')]
    // [mapping(TJSONOBJECT)]
    function serverPing: TResponse;

    // [RESTResource(TMVCHTTPMethodType.httpGET, '/news/echo/{text}')]
    // [Headers('ContentType', 'text/plain')]
    // [Headers('Accept', 'text/plain')]
    // function EchoText([Param('text')] aText: string): String;

    [RESTResource(TMVCHTTPMethodType.httpPUT, '/news/pause')]
    procedure pause;

    [RESTResource(TMVCHTTPMethodType.httpPUT, '/news/resume')]
    procedure resume;

    [RESTResource(TMVCHTTPMethodType.httpPUT, '/news/restart')]
    procedure restart;

    { Route related commands: start }

    [RESTResource(TMVCHTTPMethodType.httpPUT, '/news/routes/reload')]
    procedure LoadRoutes;

    [RESTResource(TMVCHTTPMethodType.httpGET, '/news/routes')]
    function getRoutes: TJSonObject;

    [RESTResource(TMVCHTTPMethodType.httpPUT, '/news/routes/delete')]
    procedure DeleteRoutes([Body] ABody: String);

    [RESTResource(TMVCHTTPMethodType.httpPUT, '/news/routes/add')]
    procedure addRoutes([Body] ABody: String);

    { Route related commands: end }

    [RESTResource(TMVCHTTPMethodType.httpGET, '/news/paused-campaigns')]
    procedure getPausedCampaigns;

    [RESTResource(TMVCHTTPMethodType.httpGET, '/news/campaigns')]
    procedure getCampaigns;

    // [MVCPath('/images/($img)')]
    // [MVCHTTPMethod([httpGET])]
    // procedure getImage(ctx: TWebContext);
    //
    // [MVCPath('/images/($campaign)/($img)')]
    // [MVCHTTPMethod([httpGET])]
    // procedure getCampaignImage(ctx: TWebContext);
    //
    // [MVCPath('/images/($campaign)/($trackCode)/($img)')]
    // [MVCHTTPMethod([httpGET])]
    // procedure getCampaignImageWithTrack(ctx: TWebContext);
    //
    // [MVCPath('/routes/reload')]
    // [MVCHTTPMethod([httpPUT])]
    // procedure LoadRoutes(ctx: TWebContext);

    // [MVCPath('/statistics/commit')]
    // [MVCHTTPMethod([httpPUT])]
    // procedure flushStatistics(ctx: TWebContext);
    //

    // [MVCPath('/($campaign)/($article)')]
    // [MVCHTTPMethod([httpGET])]
    // [MVCProduces('text/html', 'UTF-8')]
    // procedure redirectNoTrack(ctx: TWebContext);
    //
    // [MVCPath('/($campaign)/($article)/($track)')]
    // [MVCHTTPMethod([httpGET])]
    // [MVCProduces('text/html', 'UTF-8')]
    // procedure redirectAndTrack(ctx: TWebContext);

    // [RESTResource(TMVCHTTPMethodType.httpGET, '/hello')]
    // function HelloWorld(): string;
    //
    // [RESTResource(TMVCHTTPMethodType.httpGET, '/user')]
    // function GetUser(): TAppUser;
    //
    // [RESTResource(TMVCHTTPMethodType.httpPOST, '/user/save')]
    // procedure PostUser([Body] pBody: TAppUser);
    //
    // [RESTResource(TMVCHTTPMethodType.httpGET, '/users')]
    // [MapperListOf(TAppUser)]
    // function GetUsers(): TObjectList<TAppUser>;
    //
    // [RESTResource(TMVCHTTPMethodType.httpPOST, '/users/save')]
    // [MapperListOf(TAppUser)]
    // procedure PostUsers([Body] pBody: TObjectList<TAppUser>);
  end;

implementation

end.
