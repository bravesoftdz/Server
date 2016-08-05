unit Settings;

interface

type
  TSettings = class
  private
    FDbConnFileName, FRouteFileName, FConnDefName, FSummaryTableName, FLogDir,
      FImgDir: String;
    FRequestCacheSize, FLogCacheSize: Integer;
    fileName: String;
  public
    property routeFileName: String read FRouteFileName write FRouteFileName;
    property requestCacheSize: Integer read FRequestCacheSize
      write FRequestCacheSize;
    property dbConnFileName: String read FDbConnFileName write FDbConnFileName;
    property dbConnDefName: String read FConnDefName write FConnDefName;
    property dbSummaryTableName: String read FSummaryTableName
      write FSummaryTableName;
    property logCacheSize: Integer read FLogCacheSize write FLogCacheSize;
    property logDir: String read FLogDir write FLogDir;
    property imgDir: String read FImgDir write FImgDir;
    constructor Create(const fileName: String);
    procedure load();
  end;

implementation

uses bo.Helpers, System.IOUtils, System.SysUtils;

{ TSettings }

constructor TSettings.Create(const fileName: String);
begin
  self.fileName := fileName;
  load();
end;

procedure TSettings.load;
begin
  if TFile.Exists(fileName) then
    LoadFromJFile(fileName)
  else
  begin
    Writeln('Warning; file ' + fileName + ' does not exist!');
    Writeln('No configuration is loaded.');
  end;
end;

end.
