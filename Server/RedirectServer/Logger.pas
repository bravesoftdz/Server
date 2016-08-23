unit Logger;

interface

uses InterfaceLogger, System.Classes, System.Generics.Collections, System.JSON;

type
  TLogger = class(TInterfacedObject, ILogger)
  private
    Cache: TDictionary<String, TStringList>;
    LogDir: String;
    CurrentSize: Integer;
    MaxCacheSize: Integer;

  const
    LEVEL_ACCESS: String = 'access';

  const
    LEVEL_WARNING: String = 'warning';

  const
    LEVEL_EXCEPTION: String = 'exception';

  const
    LEVEL_INFO: String = 'info';

    procedure flushCacheSync;
    procedure emptyCache;

  public
    constructor Create(const logDirName: String; const logCacheSize: Integer);
    destructor Destroy; override;

    procedure log(const level, source, msg: String);
    procedure logAccess(const source, msg: String);
    procedure logWarning(const source, msg: String);
    procedure logException(const source, msg: String);
    procedure logInfo(const source, msg: String);
    procedure flushCache;
    procedure configure(const LogDir: String; const logCacheSize: Integer);
    function getStatus(): TJsonObject;
    procedure setProperties(const params: TJsonObject);
  end;

implementation

uses
  System.IOUtils, System.DateUtils,
  System.SysUtils;

var
  FLockObject: TObject;

procedure TLogger.emptyCache;
var
  item: TPair<string, TStringList>;
  I, Size: Integer;
begin
  for item in Cache do
  begin
    Size := item.Value.Count;
    for I := Size - 1 downto 0 do
      item.Value.Delete(I);

    item.Value.Clear;
    item.Value.DisposeOf;
  end;
  Cache.Clear;

end;

procedure TLogger.logAccess(const source, msg: String);
begin
  log(LEVEL_ACCESS, source, msg);
end;

procedure TLogger.logException(const source, msg: String);
begin
  log(LEVEL_EXCEPTION, source, msg);
end;

procedure TLogger.logInfo(const source, msg: String);
begin
  log(LEVEL_INFO, source, msg);
end;

procedure TLogger.logWarning(const source, msg: String);
begin
  log(LEVEL_WARNING, source, msg);
end;

{ Set the properties passed as json object. All unrecognized propertires
  are ignored. }
procedure TLogger.setProperties(const params: TJsonObject);
var
  MaxCacheSize: Integer;
  LogDir: String;
begin
  flushCache();
  MaxCacheSize := TJSONNumber.Create(params.Values['max cache size']);
  if MaxCacheSize >= 0 then
    Self.MaxCacheSize := MaxCacheSize;
  LogDir := params.Values['logger folder'].Value;
  if not(LogDir = nil) then
    Self.LogDir := LogDir;
end;

procedure TLogger.log(const level, source, msg: String);
var
  currentTime: TDateTime;
  list: TStringList;
  fullPath, FullMessage: String;
begin
  currentTime := Now;
  fullPath := LogDir + PathDelim + formatdatetime('yyyy' + PathDelim + 'mm' +
    PathDelim + 'yyyy_mm_dd', currentTime);

  TMonitor.Enter(FLockObject);

  if not(Cache.ContainsKey(fullPath)) then
    Cache.Add(fullPath, TStringList.Create);
  FullMessage := DateTimeToStr(currentTime) + ' ' + level + ' ' + source +
    ' ' + msg;
  list := Cache.Items[fullPath];
  list.Add(FullMessage);
  CurrentSize := CurrentSize + 1;

  TMonitor.Exit(FLockObject);

  if CurrentSize > MaxCacheSize then
    flushCache();
end;

procedure TLogger.configure(const LogDir: String; const logCacheSize: Integer);
const
  TAG: String = 'TLogger.configure';
begin
  Self.LogDir := LogDir;
  MaxCacheSize := logCacheSize;
  logInfo(TAG, 'The loggers settings: folder ' + LogDir + ', buffer size ' +
    inttostr(logCacheSize));
end;

constructor TLogger.Create(const logDirName: String;
  const logCacheSize: Integer);
begin
  Cache := TDictionary<String, TStringList>.Create;
  FLockObject := TObject.Create;
  configure(logDirName, logCacheSize);
end;

destructor TLogger.Destroy;
begin
  flushCacheSync;
  emptyCache;
  Cache.DisposeOf;
  FLockObject.DisposeOf;

  inherited;
end;

procedure TLogger.flushCache;
begin
  TThread.CreateAnonymousThread(flushCacheSync).Start;
end;

procedure TLogger.flushCacheSync;
var
  line: String;
  item: TPair<String, TStringList>;
  dirPath, FileName: String;
  writer: TStreamWriter;
begin
  try
    TMonitor.Enter(FLockObject);
    for item in Cache do
    begin
      // try
      dirPath := ExtractFileDir(item.Key);
      FileName := extractfilename(item.Key);
      if not DirectoryExists(dirPath) then
        TDirectory.CreateDirectory(dirPath);

      if FileExists(item.Key) then
        writer := TFile.AppendText(item.Key)
      else
        writer := TFile.CreateText(item.Key);
      try
        writer.AutoFlush := True;
        // Flush automatically after write
        writer.NewLine := sLineBreak;
        for line in item.Value do
        begin
          writer.WriteLine(line);
          CurrentSize := CurrentSize - 1;
        end;
        item.Value.Clear;
        item.Value.DisposeOf;
      finally
        writer.Close();
        writer.DisposeOf;
      end;
      // except
      // on E: Exception do
      // begin
      //
      // end;
      // end;
      Cache.Clear;
    end;
  finally
    TMonitor.Exit(FLockObject);
  end;
end;

{ Return the status of the logger }
function TLogger.getStatus: TJsonObject;
begin
  Result := TJsonObject.Create;
  Result.AddPair('logger name', 'Logger');
  Result.AddPair('logger folder', LogDir);
  Result.AddPair('max cache size', TJSONNumber.Create(MaxCacheSize));
  Result.AddPair('current size', TJSONNumber.Create(CurrentSize));
end;

end.
