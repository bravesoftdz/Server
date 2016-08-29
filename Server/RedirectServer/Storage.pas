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
    FSettings: TSettings;
    /// <summary> Parameters of connection to a DB.
    /// </summary>
    FConnectionSettings: TJsonObject;

  const
    DRIVER_ID_TOKEN: String = 'DriverID';
    CONNECTION_DEF_NAME: String = 'Storage_db_con';
    /// <summary> Constructs an insert-into-table statement for a table with a given name and
    /// column values</summary>
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

    function save(const items: TObjectList<TRequestType>): Boolean;
    procedure setSettings(const Settings: TSettings);
    // constructor Create(const Settings: TSettings; const Logger: ILogger);
    procedure configure(const Settings: TSettings; const Logger: ILogger);
    destructor Destroy; override;

    /// <summary> Get the status of the storage</summary>
    function getStatus(): TJsonObject;

    property Logger: ILogger write setLogger;
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
  FSettings := nil;
  if not(FConnectionSettings = nil) then
    FConnectionSettings.DisposeOf;
  inherited;
end;

procedure TDMStorage.configure(const Settings: TSettings;
  const Logger: ILogger);
begin
  self.FSettings := Settings;
  self.FLogger := Logger;
end;

procedure TDMStorage.connect(const params: TJsonObject);
const
  TAG: String = 'TDMStorage.connect';
  KEY_VALUE_SEP: String = '=';
var
  oParams: TStrings;
  pair: TJsonPair;
  driverId: String;
begin
  if (params = nil) then
  begin
    if not(FLogger = nil) then
      FLogger.logWarning(TAG, 'Connection parameters are missing.');
    Exit();
  end;
  if (params.GetValue(DRIVER_ID_TOKEN) = nil) then
  begin
    if not(FLogger = nil) then
      FLogger.logWarning(TAG, 'No key ' + DRIVER_ID_TOKEN +
        ' among parameter settings');
    Exit();
  end;

  oParams := TStringList.Create;
  for pair in params do
  begin
    oParams.Add(pair.JsonString.value + KEY_VALUE_SEP + pair.JsonValue.value);
  end;

  try
    FDManager.AddConnectionDef(CONNECTION_DEF_NAME, driverId, oParams);
    FDBConn.ConnectionDefName := CONNECTION_DEF_NAME;
    FDBConn.Connected := True;
    FLogger.logException(TAG, 'Connected!!!!');
  except
    on e: Exception do
    begin
      if not(FLogger = nil) then
        FLogger.logException(TAG, e.Message);
    end;
  end;
  oParams.DisposeOf;
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

procedure TDMStorage.setSettings(const Settings: TSettings);
begin
  self.FSettings := Settings;
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
  keys, values: TStringList;
begin
  keys := TStringList.Create;
  values := TStringList.Create;
  for key in Data.keys do
  begin
    keys.Add(FIELDNAMEWRAPPER + key + FIELDNAMEWRAPPER);
    value := TRegEx.replace(Data.items[key], '(?<!\\)&', '\\&', [roIgnoreCase]);
    values.Add('"' + value + '"')
  end;
  Result := 'INSERT INTO ' + tableName + ' (' + concatList(keys, FIELDSEPARATOR)
    + ') VALUES (' + concatList(values, FIELDSEPARATOR) + ');';
  keys.Clear;
  values.Clear;
  keys.DisposeOf;
  values.DisposeOf;
end;

function TDMStorage.getStatus(): TJsonObject;
begin
  Result := TJsonObject.Create;
  if (FConnectionSettings = nil) then
    Result.AddPair('settings', TJsonBool.Create(False))
  else
    Result.AddPair('settings', hideValues(FConnectionSettings,
      TRegEx.Create('password|user_name', [roIgnoreCase]),
      function(input: String): String
      begin
        Result := TRegEx.Create('.').Replace(input, '*');
      end));
end;

function TDMStorage.save(const items: TObjectList<TRequestType>): Boolean;
const
  TAG: String = 'TDMStorage.insertRedirect';
  separator: String = ', ';
  FIELDNAMEWRAPPER: String = '`';
  PLACEHOLDERVALUE: String = ':a';
var
  item: TRequestType;
  statement, tableName, campaign: String;
  values: TDictionary<String, String>;
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
        values := item.getValues;
        statement := insertStatement(tableName, values);
        values.Clear;
        FDBConn.ExecSQL(statement, []);
        // update summary
        campaign := item.getCampaign;
        if not(summary.ContainsKey(campaign)) then
          summary.Add(campaign, TDictionary<String, Integer>.Create);
        if summary.items[campaign].ContainsKey(tableName) then
          summary.items[campaign].items[tableName] := summary.items[campaign]
            .items[tableName] + 1
        else
          summary.items[campaign].Add(tableName, 1);
      end;
      updateSummary(summary);
      FDBConn.Commit;
      Result := True;
    except
      on e: Exception do
      begin
        FDBConn.Rollback;
        FLogger.logException('TDMStorage.insertRedirect', e.Message);
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
  fieldNames.Add('`campaign`');
  fieldValues.Add('"' + line + '"');
  for fieldName in Data.keys do
  begin
    fieldNames.Add('`' + fieldName + '`');
    fieldValues.Add(inttostr(Data.items[fieldName]));

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
  tableName := FSettings.dbSummaryTableName;
  for line in summary.keys do
  begin
    rowFetch := FDBConn.ExecSQLScalar('SELECT * FROM ' + tableName +
      '  WHERE `campaign` = "' + line + '";');
    if VarIsEmpty(rowFetch) then
      createSummaryRow(tableName, line, summary.items[line])
    else
      updateSummaryRow(tableName, line, summary.items[line]);
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
  values: TArray<Integer>;
begin
  values := Data.values.ToArray;
  statement := updateStatement(tableName, line, Data);
  FDBConn.ExecSQL(statement, []);
end;

end.
