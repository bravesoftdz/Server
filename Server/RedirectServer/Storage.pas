unit Storage;

interface

uses
  System.IOUtils,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Error,
  FireDAC.UI.Intf,
  FireDAC.Phys.Intf,
  FireDAC.Stan.Def,
  FireDAC.Phys,
  FireDAC.Comp.Client,
  FireDAC.Stan.Pool,
  FireDAC.Stan.Async,
  FireDAC.Phys.MySQL,
  FireDAC.Phys.MySQLDef,
  FireDAC.Stan.Param,
  FireDAC.DatS,
  FireDAC.DApt.Intf,
  FireDAC.DApt,
  Data.DB,
  FireDAC.Comp.DataSet,
  System.JSON,
  FireDAC.Moni.Base,
  RequestType,
  Settings,
  FireDAC.Moni.RemoteClient,
  System.Generics.Collections, FireDAC.VCLUI.Wait, uTPLb_Hash,
  uTPLb_BaseNonVisualComponent, System.Classes, InterfaceLogger,
  System.RegularExpressions, System.SysUtils;

type
  TStorageConfig = class
  private
    FUserName, FDatabase, FDriverID, FPassword, FServer: String;
    FCacheSize: Integer;
  published
    property username: String read FUserName write FUserName;
    property database: String read FDatabase write FDatabase;
    property driverid: String read FDriverID write FDriverID;
    property password: String read FPassword write FPassword;
    property server: String read FServer write FServer;
    property cachesize: Integer read FCacheSize write FCacheSize;
    /// <summary> assign values of the properties from given object</summary>
    procedure loadFrom(const Data: TStorageConfig);
  end;

type
  TDMStorage = class(TDataModule)
    FDBConn: TFDConnection;
    FDQuery1: TFDQuery;
    FDMoniRemoteClientLink1: TFDMoniRemoteClientLink;
    procedure DataModuleDestroy(Sender: TObject);
    /// <summary> Create an UPDATE statement.
    /// No placeholders are used, so the resulting string is of the following form
    /// UPDATE `summary` SET `click` = `click` + 10, `view` = `view` + 6 WHERE `campaign` = "venditori";
    /// </summary >
    function updateStatement(const tableName, row: String;
      const Data: TDictionary<String, Integer>): String;
  private
    /// <summary> [Optional] Reference to a logger</summary>
    FLogger: ILogger;
    /// <summary> Parameters of connection to a DB.
    /// </summary>
    // FConnectionSettings: TJsonObject;

    FConnectionConfig: TStorageConfig;
    /// <summary>The number of objects to accumulate before write them in
    /// the database </summary>
    FMaxCacheSize: Integer;
    /// <summary> The cache of the requests</summary>
    FCache: TObjectList<TRequestType>;
    /// <summary> a dumb object used for locking purposes </summary>
    FLockObject: TObject;

  const
    /// <summary>table into which the overall summary is to be written</summary>
    DB_SUMMARY_TABLE_NAME: String = 'summary';
    /// <summary>a name of the token under which the connection-related
    /// data are to be stored into the status object</summary>
    CONNECTION_STATUS_TOKEN = 'connection';
    /// <summary> token under which the max cache size value is stored in the
    /// status object </summary>
    MAX_CACHE_SIZE_TOKEN = 'max cache size';

    /// <summary> token under which the current cache size value is stored in the
    /// status object </summary>
    CACHE_SIZE_TOKEN = 'cache size';

    // name of the attribute for the user name in the definition of the
    // connection to the database
    USER_NAME_TOKEN = 'User_Name';
    // name of the attribute for the database name in the definition of the
    // connection to the database
    DB_TOKEN = 'Database';
    // name of the attribute for the driver id in the definition of the
    // connection to the database
    DRIVER_TOKEN = 'DriverID';
    // name of the attribute for the password in the definition of the
    // connection to the database
    PASSWORD_TOKEN = 'Password';
    // name of the attribute for the server ip in the definition of the
    // connection to the database
    SERVER_TOKEN = 'Server';
    /// <summary> Constructs an insert-into-table statement for a
    /// table with a given name and column values</summary>
    function insertStatement(const tableName: String;
      const Data: TDictionary<String, String>): String;
    procedure updateSummary(const summary: TDictionary < String,
      TDictionary < String, Integer >> );
    procedure updateSummaryRow(const tableName, line: String;
      const Data: TDictionary<String, Integer>);
    procedure createSummaryRow(const tableName, line: String;
      const Data: TDictionary<String, Integer>);
    function concatList(const list: TStringList; const separator: Char): String;
    /// <summary> Empty the nested dictionary</summary>
    procedure empty(const summary: TDictionary < String, TDictionary < String,
      Integer >> );
    /// <summary> logger setter </summary>
    procedure setLogger(const Logger: ILogger);
    /// <summary> Establish connection to a database using parameters
    /// in TFDConn.</summary>
    procedure connect();
    /// <summary> FCacheSize setter</summary>
    procedure setCacheSize(cachesize: Integer);

    /// <summary> Close (if it is open) the connection to the database
    /// established by means of ConnDef</summary>
    procedure Disconnect(const ConnDef: TFDConnection);

    /// <summary>Log the message if possible.</summary>
    procedure LogIfPossible(const tag, msg: String);

  public
    /// <summary> Set connection settings
    /// The argument is supposed to be not nil. </summary >
    procedure configure(const parameters: TStorageConfig);

    /// <summary> Add the given request to the storage cache. Once its
    /// size exceeds FCacheSize, it should be written to the database
    /// </summary>
    procedure add(const item: TRequestType);
    function save(const items: TObjectList<TRequestType>): Boolean;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    /// <summary> Get the status of the storage</summary>
    function getStatus(): TJsonObject;

    /// <summary> Try to save the cache content to the database and then empty
    /// the cache </summary>
    procedure Commit();

    property Logger: ILogger write setLogger;
    property cachesize: Integer write setCacheSize;
  end;

var
  DMStorage: TDMStorage;

implementation

uses
  Logger, System.Rtti, System.Variants;

{ %CLASSGROUP 'Vcl.Controls.TControl' }

{$R *.dfm}

{ TDataModule1 }
destructor TDMStorage.Destroy;
begin
  FConnectionConfig.DisposeOf;
  FCache.Clear;
  FCache.DisposeOf;
  FLockObject.DisposeOf;
  FLogger := nil;
  inherited;
end;

constructor TDMStorage.Create(AOwner: TComponent);
begin
  inherited;
  FCache := TObjectList<TRequestType>.Create;
  FLockObject := TObject.Create;
  FConnectionConfig := TStorageConfig.Create;
end;

procedure TDMStorage.connect();
const
  tag: String = 'TDMStorage.connect';
begin
  try
    FDBConn.Connected := True;
//    LogIfPossible(tag, 'Connected!');
  except
    on e: Exception do
      LogIfPossible(tag, e.message);
  end;
end;

procedure TDMStorage.Disconnect(const ConnDef: TFDConnection);
begin
  if (not(FDBConn = nil)) AND (FDBConn.Connected) then
  begin
    FDBConn.Connected := False;
    LogIfPossible('TDMStorage.Disconnect', 'Disconnect');
  end;
end;

procedure TDMStorage.configure(const parameters: TStorageConfig);
begin
  /// save the provided connection parameters for further use
  FConnectionConfig.loadFrom(parameters);
  FDBConn.params.Values[USER_NAME_TOKEN] := FConnectionConfig.username;
  FDBConn.params.Values[DB_TOKEN] := FConnectionConfig.database;
  FDBConn.params.Values[DRIVER_TOKEN] := FConnectionConfig.driverid;
  FDBConn.params.Values[PASSWORD_TOKEN] := FConnectionConfig.password;
  FDBConn.params.Values[SERVER_TOKEN] := FConnectionConfig.server;
  FMaxCacheSize := parameters.cachesize;
end;

procedure TDMStorage.DataModuleDestroy(Sender: TObject);
begin
  FDBConn.Connected := False;
end;

procedure TDMStorage.setLogger(const Logger: ILogger);
begin
  self.FLogger := Logger;
end;

function TDMStorage.insertStatement(const tableName: String;
  const Data: TDictionary<String, String>): String;
const
  tag: String = 'TDMStorage.insertRedirect';
  FIELDNAMEWRAPPER: String = '`';
  FIELDSEPARATOR = ',';
var
  key, value: String;
  keys, Values: TStringList;
begin
  keys := TStringList.Create;
  Values := TStringList.Create;
  for key in Data.keys do
  begin
    keys.add(FIELDNAMEWRAPPER + key + FIELDNAMEWRAPPER);
    value := TRegEx.replace(Data.items[key], '(?<!\\)&', '\\&', [roIgnoreCase]);
    Values.add('"' + value + '"')
  end;
  Result := 'INSERT INTO ' + tableName + ' (' + concatList(keys, FIELDSEPARATOR)
    + ') VALUES (' + concatList(Values, FIELDSEPARATOR) + ');';
  keys.Clear;
  Values.Clear;
  keys.DisposeOf;
  Values.DisposeOf;
end;

function TDMStorage.getStatus(): TJsonObject;
begin
  Result := TJsonObject.Create;
  Result.AddPair(USER_NAME_TOKEN, FConnectionConfig.username);
  Result.AddPair(DB_TOKEN, FConnectionConfig.database);
  Result.AddPair(DRIVER_TOKEN, FConnectionConfig.driverid);
  Result.AddPair(PASSWORD_TOKEN,
    TJSONBool.Create(not FConnectionConfig.password.IsEmpty));
  Result.AddPair(SERVER_TOKEN, FConnectionConfig.server);
  Result.AddPair(MAX_CACHE_SIZE_TOKEN, TJSonNumber.Create(FMaxCacheSize));
  Result.AddPair(CACHE_SIZE_TOKEN, TJSonNumber.Create(FCache.Count));
end;

function TDMStorage.save(const items: TObjectList<TRequestType>): Boolean;
const
  tag: String = 'TDMStorage.save';
  separator: String = ', ';
  FIELDNAMEWRAPPER: String = '`';
  PLACEHOLDERVALUE: String = ':a';
var
  item: TRequestType;
  statement, tableName, campaign: String;
  Values: TDictionary<String, String>;
  summary: TDictionary<String, TDictionary<String, Integer>>;
begin
  Result := False;
  if not(FDBConn.Connected) then
  begin
    connect();
  end;
  if not(FDBConn.Connected) then
  begin
    if not(FLogger = nil) then
      FLogger.logWarning(tag, 'Failed to connect to the database.');
    Exit();
  End;

  summary := TDictionary < String, TDictionary < String, Integer >>.Create;
  try
    FDBConn.StartTransaction;
    for item in items do
    begin
      tableName := item.getMarker;
      Values := item.getValues;
      statement := insertStatement(tableName, Values);
      Values.Clear;
      FDBConn.ExecSQL(statement, []);
      // update summary
      campaign := item.getCampaign;
      if not(summary.ContainsKey(campaign)) then
        summary.add(campaign, TDictionary<String, Integer>.Create);
      if summary.items[campaign].ContainsKey(tableName) then
        summary.items[campaign].items[tableName] := summary.items[campaign]
          .items[tableName] + 1
      else
        summary.items[campaign].add(tableName, 1);
    end;
    updateSummary(summary);
    FDBConn.Commit;
    Result := True;
  except
    on e: Exception do
    begin
      FDBConn.Rollback;
      FLogger.logException(tag, e.message);
      empty(summary);
      raise;
    end;
  end;
  empty(summary);
  summary.DisposeOf;
end;

procedure TDMStorage.empty(const summary: TDictionary < String,
  TDictionary < String, Integer >> );
var
  key: String;
  keys: TDictionary < String, TDictionary < String, Integer >>.TKeyCollection;
begin
  keys := summary.keys;
  for key in keys do
  begin
    summary.items[key].DisposeOf;
    summary.Remove(key);
  end;

end;

{ Concatenates the string list elements with a given separator being put between
  the elements. }
function TDMStorage.concatList(const list: TStringList;
  const separator: Char): String;
begin
  Result := list.Text.Trim.replace(sLineBreak, separator, [rfReplaceAll]);
end;

procedure TDMStorage.createSummaryRow(const tableName, line: String;
  const Data: TDictionary<String, Integer>);
const
  FIELDSEPARATOR = ',';
var
  fieldNames, fieldValues: TStringList;
  statement, fieldName: String;
begin
  if Data.Count = 0 then
    Exit;
  fieldNames := TStringList.Create;
  fieldValues := TStringList.Create;
  fieldNames.add('`campaign`');
  fieldValues.add('"' + line + '"');
  for fieldName in Data.keys do
  begin
    fieldNames.add('`' + fieldName + '`');
    fieldValues.add(inttostr(Data.items[fieldName]));
  end;
  statement := 'INSERT INTO ' + tableName + ' (' + concatList(fieldNames,
    FIELDSEPARATOR) + ') VALUES (' + concatList(fieldValues,
    FIELDSEPARATOR) + ');';
  fieldNames.DisposeOf;
  fieldValues.DisposeOf;
  FDBConn.ExecSQL(statement, []);
end;

procedure TDMStorage.updateSummary(const summary: TDictionary < String,
  TDictionary < String, Integer >> );
var
  line: String;
var
  rowFetch: Variant;
begin
  for line in summary.keys do
  begin
    rowFetch := FDBConn.ExecSQLScalar('SELECT * FROM ' + DB_SUMMARY_TABLE_NAME +
      '  WHERE `campaign` = "' + line + '";');
    if VarIsEmpty(rowFetch) then
      createSummaryRow(DB_SUMMARY_TABLE_NAME, line, summary.items[line])
    else
      updateSummaryRow(DB_SUMMARY_TABLE_NAME, line, summary.items[line]);
  end;
end;

function TDMStorage.updateStatement(const tableName, row: String;
  const Data: TDictionary<String, Integer>): String;
const
  tag = 'TDMStorage.updateStatement';
  COMMA_SEPARATOR = ',';
  FIELDNAMEWRAPPER = '`';

var
  fieldNameWrapped, fieldName, sep: String;
begin
  Result := 'UPDATE ' + FIELDNAMEWRAPPER + tableName + FIELDNAMEWRAPPER
    + ' SET ';
  sep := '';
  for fieldName in Data.keys do
  begin
    fieldNameWrapped := FIELDNAMEWRAPPER + fieldName + FIELDNAMEWRAPPER;
    Result := Result + sep + fieldNameWrapped + '=' + fieldNameWrapped + '+' +
      inttostr(Data.items[fieldName]);
    if not(sep = COMMA_SEPARATOR) then
      sep := COMMA_SEPARATOR;
  end;
  Result := Result + ' WHERE ' + FIELDNAMEWRAPPER + 'campaign' +
    FIELDNAMEWRAPPER + '="' + row + '";';
end;

procedure TDMStorage.updateSummaryRow(const tableName, line: String;
  const Data: TDictionary<String, Integer>);
var
  statement: String;
  Values: TArray<Integer>;
begin
  Values := Data.Values.ToArray;
  statement := updateStatement(tableName, line, Data);
  FDBConn.ExecSQL(statement, []);
end;

procedure TDMStorage.setCacheSize(cachesize: Integer);
begin
  if (cachesize >= 0) then
    FMaxCacheSize := cachesize;
end;

procedure TDMStorage.add(const item: TRequestType);
begin
  FCache.add(item);
  if FCache.Count > FMaxCacheSize then
    Commit();
end;

procedure TDMStorage.Commit();
const
  tag: String = 'TDMStorage.Commit';
var
  outcome: Boolean;
begin
  TMonitor.Enter(FLockObject);
  try
    try
      outcome := save(FCache);
      if outcome then
        FCache.Clear
      else
        FLogger.logWarning(tag,
          'Saving of the statistics to the DB has been postponed.');
    except
      on e: Exception do
      begin
        FLogger.logException(tag, e.message);
      end;
    end;
  finally
    TMonitor.Exit(FLockObject);
  end;

end;

procedure TDMStorage.LogIfPossible(const tag: string; const msg: string);
begin
  if not(FLogger = nil) then
    FLogger.logInfo(tag, msg);
end;

procedure TStorageConfig.loadFrom(const Data: TStorageConfig);
begin
  username := Data.username;
  database := Data.database;
  driverid := Data.driverid;
  password := Data.password;
  server := Data.server;
end;

end.
