unit Logger;

interface

uses InterfaceLogger, System.Classes, System.Generics.Collections, System.JSON,
  System.SysUtils;

type
  TLoggerConfig = class
  private
    FLogDir: String;
    FMaxCacheSize: Integer;
  public
    property LogDir: String read FLogDir write FLogDir;
    property MaxCacheSize: Integer read FMaxCacheSize write FMaxCacheSize;
    constructor Create;
  end;

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

    /// <summary>path name pattern of the log file.
    /// The pat is relative with respect to LogDir. </summary>
  const
    FILE_PATH_PATTERN: String = 'yyyy' + PathDelim + 'mm' + PathDelim +
      'yyyy_mm_dd';

    /// <summary>token corresponding to the MaxCacheSize property</summary>
  const
    MAX_CACHE_SIZE_TOKEN: String = 'max cache size';

    /// token corresponding to the LogDir property
  const
    LOG_DIR_TOKEN: String = 'folder';

    procedure flushCacheSync;
    procedure emptyCache;
    /// <summary> Set the max cache size to the given value if it is a
    /// non-negative integer </summary>
    procedure setMaxCacheSize(const MaxSize: Integer);
    procedure setLogDir(const dir: String);

  public
    /// <summary>Constructor</summary>
    /// <param name="data">a json object with two keys:
    /// 1. defined by constant LOG_DIR_TOKEN for the folder in which the log files are to be saved,
    /// 2. defined by constant MAX_CACHE_SIZE_TOKEN for the max number of recores to maintain in memory
    /// </param>
    constructor Create(const data: TJSonObject); overload;

    /// <summary>Constructor</summary>
    /// <param name="DirName">name of directory in which the log files are saved.
    /// It can contain only alphanumeric symbols, underscore and the path delimiter </param>
    /// <param name="MaxCacheSize">max number of records to maintain in memory
    /// before saving in a file </param>
    constructor Create(const DirName: String;
      const MaxCacheSize: Integer); overload;
    /// <summary>Constructor that sets only the maximal cache size to the default value
    /// and does not set a directory in which to save the log files.</summary>
    /// <param name="DirName">name of directory in which the log files are saved.
    /// It can contain only alphanumeric symbols, underscore and the path delimiter </param>
    /// <param name="MaxCacheSize">max number of records to maintain in memory
    /// before saving in a file </param>
    constructor Create(); overload;

    destructor Destroy; override;

    procedure log(const level, source, msg: String);
    procedure logAccess(const source, msg: String);
    procedure logWarning(const source, msg: String);
    procedure logException(const source, msg: String);
    procedure logInfo(const source, msg: String);
    procedure flushCache;
    procedure configure(const LogDir: String; const MaxCacheSize: Integer);
    function getStatus(): TJSonObject;
    procedure setProperties(const params: TJSonObject);
  end;

implementation

uses
  System.IOUtils, System.DateUtils, System.RegularExpressions;

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
procedure TLogger.setProperties(const params: TJSonObject);
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
  fullPath := formatdatetime(FILE_PATH_PATTERN, currentTime);

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

procedure TLogger.configure(const LogDir: String; const MaxCacheSize: Integer);
const
  TAG: String = 'TLogger.configure';
begin
  Self.LogDir := LogDir;
  Self.MaxCacheSize := MaxCacheSize;
  logInfo(TAG, 'The logger settings: folder ' + LogDir + ', buffer size ' +
    inttostr(MaxCacheSize));
end;

constructor TLogger.Create(const data: TJSonObject);
begin
  Create();
  configure(data.GetValue(LOG_DIR_TOKEN).Value,
    StrToInt(data.GetValue(MAX_CACHE_SIZE_TOKEN).Value));
end;

constructor TLogger.Create(const DirName: String; const MaxCacheSize: Integer);
begin
  Create;
  configure(DirName, MaxCacheSize);
end;

constructor TLogger.Create;
const
  TAG: String = 'TLogger.Create';
begin
  Cache := TDictionary<String, TStringList>.Create;
  FLockObject := TObject.Create;
  Self.MaxCacheSize := 10;
  logInfo(TAG, 'The logger is created.');
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
  line, fullPath: String;
  item: TPair<String, TStringList>;
  dirPath, fileName: String;
  writer: TStreamWriter;
begin
  if LogDir.IsEmpty then
    Exit();
  try
    TMonitor.Enter(FLockObject);
    for item in Cache do
    begin
      // try
      fullPath := LogDir + PathDelim + item.Key;
      dirPath := ExtractFileDir(fullPath);
      fileName := extractfilename(fullPath);
      if not DirectoryExists(dirPath) then
        TDirectory.CreateDirectory(dirPath);

      if FileExists(fullPath) then
        writer := TFile.AppendText(fullPath)
      else
        writer := TFile.CreateText(fullPath);
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
function TLogger.getStatus: TJSonObject;
begin
  Result := TJSonObject.Create;
  Result.AddPair('logger name', 'Logger');
  Result.AddPair(LOG_DIR_TOKEN, LogDir);
  Result.AddPair(MAX_CACHE_SIZE_TOKEN, TJSONNumber.Create(MaxCacheSize));
  Result.AddPair('current size', TJSONNumber.Create(CurrentSize));
end;

{ TLoggerConfig }

constructor TLoggerConfig.Create;
begin
end;

end.
