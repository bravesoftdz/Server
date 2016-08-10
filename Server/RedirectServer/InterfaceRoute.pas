unit InterfaceRoute;

interface

uses
  System.JSON, InterfaceLogger, System.Classes, System.Generics.Collections;

type
  IRoute = interface
    ['{21B460EC-B67F-42C9-836B-A1347FD2177C}']
    { Retrieve an url corresponding to the argument. }
    function getUrl(const campaign: String; article: String): String;
    function getRoutes(): TJsonObject;
    function convertToRoutes(const lines: TStringList)
      : TDictionary<String, String>;
    procedure loadRoutesFromFile(const fileName: String);
    procedure setRoutes(const routes: TDictionary<String, String>);
    procedure setCampaignStatus(const campaign: String; const status: Boolean);
    procedure configure(const Logger: ILogger; const fileName: String);
    function getCampaigns: TJsonArray;
    function getPausedCampaigns: TJsonArray;
    procedure add(const routes: TJsonObject);
  end;

implementation

end.
