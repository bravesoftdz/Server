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
  uTPLb_BaseNonVisualComponent, System.Classes, InterfaceLogger;

type
  TDMStorage = class(TDataModule)
    FDBConn: TFDConnection;
    FDQuery1: TFDQuery;
    FDMoniRemoteClientLink1: TFDMoniRemoteClientLink;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    function updateStatement(const tableName, row: String;
      const Data: TDictionary<String, Integer>): String;
  private
  var
    /// <summary> [Optional] Reference to a logger</summary>
    FLogger: ILogger;

  var
    FSettings: TSettings;
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

  public
    function save(const items: TObjectList<TRequestType>): Boolean;
    procedure setSettings(const Settings: TSettings);
    // constructor Create(const Settings: TSettings; const Logger: ILogger);
    procedure configure(const Settings: TSettings; const Logger: ILogger);
    destructor Destroy; override;

    /// <summary> Get the status of the storage</summary>
    function getStatus(): TJSonObject;

    property Logger: ILogger write setLogger;

  end;

var
  DMStorage: TDMStorage;

implementation

uses
  Logger, System.Rtti, System.Variants, System.SysUtils,
  System.RegularExpressions;

{ %CLASSGROUP 'Vcl.Controls.TControl' }

{$R *.dfm}

{ TDataModule1 }
destructor TDMStorage.Destroy;
begin
  FLogger := nil;
  FSettings := nil;
  inherited;
end;

// constructor TDMStorage.Create(const Settings: TSettings; const Logger: ILogger);
// begin
// configure(Settings, Logger);
// inherited Create(nil);
// end;

procedure TDMStorage.configure(const Settings: TSettings;
  const Logger: ILogger);
begin
  self.FSettings := Settings;
  self.FLogger := Logger;
end;

procedure TDMStorage.DataModuleCreate(Sender: TObject);
const
  TAG: String = 'TDMStorage.DataModuleCreate';
begin
  if not(Assigned(FSettings)) then
    Exit();
  FDManager.ConnectionDefFileName := FSettings.dbConnFileName;
  FDManager.ConnectionDefFileAutoLoad := True;
  try
    FDBConn.ConnectionDefName := FSettings.dbConnDefName;
    FDBConn.Connected := True;
  except
    on e: Exception do
    begin
      FLogger.logException(TAG, e.Message);
    end;
  end;
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
    value := TRegEx.Replace(Data.items[key], '(?<!\\)&', '\\&', [roIgnoreCase]);
    values.Add('"' + value + '"')
  end;
  Result := 'INSERT INTO ' + tableName + ' (' + concatList(keys, FIELDSEPARATOR)
    + ') VALUES (' + concatList(values, FIELDSEPARATOR) + ');';
  keys.Clear;
  values.Clear;
  keys.DisposeOf;
  values.DisposeOf;
end;

function TDMStorage.getStatus(): TJSonObject;
begin
  raise Exception.Create('Storage status is not implemenented yet.');
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
  Result := list.Text.Trim.Replace(sLineBreak, separator, [rfReplaceAll]);
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

{ Create an UPDATE statement.  No placeholders are used, so the resulting string
  is of the following form
  UPDATE `summary` SET `click` = `click` + 10, `view` = `view` + 6 WHERE `campaign` = "venditori";
}
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
