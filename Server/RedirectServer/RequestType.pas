unit RequestType;

interface

uses System.Classes, System.Rtti, System.SysUtils, System.Generics.Collections,
  System.StrUtils, Logger, InterfaceLogger;

type
  TRequestType = class abstract
  const
    MAXSTRLEN = 255;
  protected
    FKeyValue: TDictionary<String, String>;
    class var Logger: ILogger;

  public
    function truncateString(const str: String; const len: Integer): String;
    class function getFieldNames: TArray<String>; virtual; abstract;
    function getValues: TDictionary<String, String>;
    function getMarker: String; virtual; abstract;
    function getCampaign: String; virtual; abstract;
    procedure setCampaign(const name: String); virtual; abstract;
    procedure setField(const fieldName, fieldValue: String);
    constructor Create;
    destructor Destroy; override;
  end;

implementation

constructor TRequestType.Create;
begin
  FKeyValue := TDictionary<String, String>.Create;
end;

function TRequestType.truncateString(const str: String;
  const len: Integer): String;
begin
  if Length(str) > len then
    Result := str.Substring(1, len)
  else
    Result := str;
end;

destructor TRequestType.Destroy;
begin
  FKeyValue.Clear;
  FKeyValue.DisposeOf;
end;

function TRequestType.getValues: TDictionary<String, String>;
begin
  Result := FKeyValue;
end;

procedure TRequestType.setField(const fieldName, fieldValue: String);
const
  TAG = 'TRequestType.setField';
begin
  inherited;
  if MatchStr(fieldName, getFieldNames) then
    FKeyValue.Add(fieldName, truncateString(fieldValue, MAXSTRLEN))
  else
  begin
    Logger.logWarning(TAG, 'field name ' + fieldName +
      ' is not among allowed ones.');
  end;

end;

end.
