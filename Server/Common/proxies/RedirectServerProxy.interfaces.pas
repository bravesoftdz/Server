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

    [RESTResource(TMVCHTTPMethodType.httpGET, '/news/images/{img}')
      ]
    [Headers('ContentEncoding', 'UTF-16')]
    function getImage([Param('img')] img: String): string;

    [RESTResource(TMVCHTTPMethodType.httpGET, '/news/images/{campaign}/{img}')]
    [Headers('ContentEncoding', 'UTF-16')]
    function getCampaignImage([Param('campaign')] campaign: string;
      [Param('img')] img: String): string;

    [RESTResource(TMVCHTTPMethodType.httpGET, '/news/images/{campaign}/(track)/{img}')]
    [Headers('ContentEncoding', 'UTF-16')]
    function getCampaignImageWithTrack([Param('campaign')] campaign: string;
      [Param('track')] track: string; [Param('img')] img: String): string;

    [RESTResource(TMVCHTTPMethodType.httpGET, '/news/(campaign)/(article)')]
    function getArticle([Param('campaign')] campaign: String; [Param('article')] article: String)
      : TResponse;

    [RESTResource(TMVCHTTPMethodType.httpGET, '/news/(campaign)/(article)/(track)')]
    function getArticleWithTrack([Param('campaign')] campaign: String;
      [Param('article')] article: String; [Param('track')] track: String): TResponse;

    [RESTResource(TMVCHTTPMethodType.httpGET, '/news/server/reload')]
    procedure reload();

    [RESTResource(TMVCHTTPMethodType.httpGET, '/news/server/status')]
    function getServerStatus(): TJSonObject;

  end;

implementation

end.
