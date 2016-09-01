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
  TDMStorage = class(TDataModule)
    FDBConn: TFDConnection;
    FDQuery1: TFDQuery;
    FDMoniRemoteClientLink1: TFDMoniRemoteClientLink;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    /// <summary> Create an UPDATE statement.
    /// No placeholders are used, so the resulting string is of the following form
    /// UPDATE `summary` SET `click` = `click` + 10, `view` = `view` + 6 WHERE `campaign` = "venditori";
    /// < / summary >
    function updateStatement(const tableName, row: String;
      const Data: TDictionary<String, Integer>): String;
  private
    /// <summary> [Optional] Reference to a logger</summary>
    FLogger: ILogger;
    /// <summary> Parameters of connection to a DB.
    /// </summary>
    FConnectionSettings: TJsonObject;
    /// <summary>The number of objects to accumulate before write them in
    /// the database </summary>
    FCacheSize: Integer;
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
    /// <summary> token under which the cache size is stored in the status object
    /// </summary>
    CACHE_SIZE_TOKEN = 'cache size';
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
    procedure empty(const summary: TDictionary < String, TDictionary < String,
      Integer >> );
    /// <summary> logger setter </summary>
    procedure setLogger(const Logger: ILogger);
    /// <summary> Connect to a database using given parameters
    /// The parameter is supposed to be not nil</summary>
    procedure connect(const params: TJsonObject);
    /// <summary> FCacheSize setter</summary>
    procedure setCacheSize(cacheSize: Integer);

    /// <summary> Replace values of keys matching given criteria
    /// by some hash values </summary>
    // function hideValues_old(const Data: TJsonObject; const crit: TRegEx;
    // const replace: String): TJsonObject;
    function hideValues(const Data: TJsonObject; const crit: TRegEx;
      callback: TFunc<String, String>): TJsonObject;

  public
    /// <summary> Set connection settings
    /// The argument is supposed to be not nil. </summary >
    procedure setConnectionSettings(const parameters: TJsonObject);

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
    property cacheSize: Integer write setCacheSize;
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
  FLogger := nil;
  FCache.Clear;
  FCache.DisposeOf;
  FLockObject.DisposeOf;
  if not(FConnectionSettings = nil) then
    FConnectionSettings.DisposeOf;
  inherited;
end;

constructor TDMStorage.Create(AOwner: TComponent);
begin
  inherited;
  FCache := TObjectList<TRequestType>.Create;
  FLockObject := TObject.Create;
end;

procedure TDMStorage.connect(const params: TJsonObject);
const
  TAG: String = 'TDMStorage.connect';
  KEY_VALUE_SEP: String = '=';
var
  pair: TJsonPair;
  driverId: String;
begin
  if (params = nil) then
  begin
    if not(FLogger = nil) then
      FLogger.logWarning(TAG, 'Connection parameters are missing.');
    Exit();
  end;
  for pair in params do
  begin
    FDBConn.params.Values[pair.JsonString.value] := pair.JsonValue.value;
  end;
  try
    if FDBConn.Connected then
    begin
      FDBConn.Connected := False;
      FLogger.logInfo(TAG, 'Disconnect');
    end;
    FDBConn.Connected := True;
    if not(FLogger = nil) then
      FLogger.logInfo(TAG, 'Connected!');
  except
    on e: Exception do
    begin
      if not(FLogger = nil) then
        FLogger.logException(TAG, e.Message);
    end;
  end;
end;

procedure TDMStorage.setConnectionSettings(const parameters: TJsonObject);
var
  item: TJsonValue;
begin
  /// clean previous settings if they exist
  if not(FConnectionSettings = nil) then
    FConnectionSettings.DisposeOf;
  FConnectionSettings := parameters.Clone as TJsonObject;
  connect(FConnectionSettings);
end;

procedure TDMStorage.DataModuleCreate(Sender: TObject);
begin
  if Assigned(FConnectionSettings) then
    connect(FConnectionSettings);
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
  TAG: String = 'TDMStorage.insertRedirect';
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
  if (FConnectionSettings = nil) then
    Result.AddPair(CONNECTION_STATUS_TOKEN, TJsonBool.Create(False))
  else
    Result.AddPair(CONNECTION_STATUS_TOKEN, hideValues(FConnectionSettings,
      TRegEx.Create('password|user_name', [roIgnoreCase]),
      function(input: String): String
      begin
        Result := TRegEx.Create('.').replace(input, '*');
      end));
  Result.AddPair(CACHE_SIZE_TOKEN, FCacheSize.ToString);
  Result.AddPair('records', FCache.Count.ToString);

end;

function TDMStorage.save(const items: TObjectList<TRequestType>): Boolean;
const
  TAG: String = 'TDMStorage.save';
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
    FLogger.logWarning(TAG, 'The database connection is missing.')
  else
  begin
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
        FLogger.logException(TAG, e.Message);
        raise;
      end;
    end;
    empty(summary);
    summary.DisposeOf;

  end;
end;

{
  Empty the nested dictionary
}
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
  tableName: String;
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

function TDMStorage.hideValues(const Data: TJsonObject; const crit: TRegEx;
callback: TFunc<String, String>): TJsonObject;
var
  pair: TJsonPair;
  key, value: String;
begin
  Result := TJsonObject.Create;
  for pair in Data do
  begin
    key := pair.JsonString.value;
    if crit.IsMatch(key) then
      Result.AddPair(key, callback(pair.JsonValue.value))
    else
      Result.AddPair(pair.Clone as TJsonPair)
  end;
end;

function TDMStorage.updateStatement(const tableName, row: String;
const Data: TDictionary<String, Integer>): String;
const
  TAG = 'TDMStorage.updateStatement';
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

procedure TDMStorage.setCacheSize(cacheSize: Integer);
begin
  if (cacheSize >= 0) then
    FCacheSize := cacheSize;
end;

procedure TDMStorage.add(const item: TRequestType);
begin
  FCache.add(item);
  if FCache.Count > FCacheSize then
    Commit();
end;

procedure TDMStorage.Commit();
const
  TAG: String = 'TDMStorage.Commit';
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
        FLogger.logWarning(TAG,
          'Saving of the statistics to the DB has been postponed.');
    except
      on e: Exception do
      begin
        FLogger.logException(TAG, e.Message);
      end;
    end;
  finally
    TMonitor.Exit(FLockObject);
  end;

end;

end.
