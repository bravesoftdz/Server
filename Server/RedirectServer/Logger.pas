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

    /// token corresponding to the MaxCacheSize property
  const
    MAX_CACHE_SIZE_TOKEN: String = 'max cache size';

    /// token corresponding to the LogDir property
  const
    LOG_DIR_TOKEN: String = 'logger folder';

    procedure flushCacheSync;
    procedure emptyCache;
    /// <summary> Set the max cache size to the given value if it is a
    /// non-negative integer </summary>
    procedure setMaxCacheSize(const MaxSize: Integer);
    procedure setLogDir(const dir: String);

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
  System.SysUtils, System.RegularExpressions;

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

procedure TLogger.setLogDir(const dir: String);
var
  MaxCacheSize: Integer;
  LogDirTmp: String;
  regex: TRegEx;
begin
  regex := TRegEx.Create('[^a-zA-Z0-9_\' + PathDelim + ']');
  if not(regex.isMatch(dir)) then
  begin
    LogDirTmp := TRegEx.Replace(dir, '^(\' + PathDelim + ')*|(\' + PathDelim +
      ')*$', '');
    LogDirTmp := TRegEx.Replace(LogDirTmp, '(\' + PathDelim + ')*', PathDelim);
    if not(LogDirTmp.IsEmpty) then
      Self.LogDir := LogDirTmp + PathDelim;
  end;
end;

procedure TLogger.setMaxCacheSize(const MaxSize: Integer);
begin
  if MaxSize >= 0 then
    MaxCacheSize := MaxSize;
end;

/// <summary> Set the properties passed as json object. All unrecognized
/// properties are ignored. </summary>
procedure TLogger.setProperties(const params: TJsonObject);
begin
   flushCache();
  if (params.GetValue(MAX_CACHE_SIZE_TOKEN) is TJSONNumber) then
    setMaxCacheSize(StrToIntDef(params.Values[MAX_CACHE_SIZE_TOKEN].Value, -1));
  if not(params.Values[LOG_DIR_TOKEN] = nil) then
    setLogDir(params.Values[LOG_DIR_TOKEN].Value);
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
  // TThread.CreateAnonymousThread(flushCacheSync).Start;
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
  Result.AddPair(LOG_DIR_TOKEN, LogDir);
  Result.AddPair(MAX_CACHE_SIZE_TOKEN, TJSONNumber.Create(MaxCacheSize));
  Result.AddPair('current size', TJSONNumber.Create(CurrentSize));
end;

end.
