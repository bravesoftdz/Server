unit InterfaceRoute;

interface

uses
  System.JSON, InterfaceLogger, System.Classes, ServerConfig,
  System.Generics.Collections;

type
  IRoute = interface
    ['{21B460EC-B67F-42C9-836B-A1347FD2177C}']
    { Retrieve an url corresponding to the argument. }
    function getUrl(const campaign: String; article: String): String;
    function getRoutes(): TJsonObject;
    procedure setRoutes(const routes: TDictionary<String, String>);
    procedure addRoutes(const routes: TObjectList<TRouteMapper>);
    procedure delete(const routes: TJsonArray);
    function getStatus(): TJsonObject;
    procedure setLogger(const Logger: ILogger);
  end;

implementation

end.
