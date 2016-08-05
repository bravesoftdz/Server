unit RequestClick;

interface

uses RequestType, System.Classes, System.Rtti, System.Generics.Collections;

type
  TRequestClick = class(TRequestType)
  const
    MARKER = 'click';
  private
  class var
    FFieldNames: TArray<String>;
    FCampaign: String;
  public
    class function getFieldNames: TArray<String>; override;
    function getMarker: String; override;
    function getCampaign: String; override;
    procedure setCampaign(const name: String); override;
    constructor Create;

  end;

implementation

{ TRequestClick }
uses
  System.SysUtils;

constructor TRequestClick.Create;
begin
  inherited;
  inherited setField(FFieldNames[0], FormatDateTime('yyyy-mm-dd hh:nn:ss',
    System.SysUtils.Now));
end;

function TRequestClick.getCampaign: String;
begin
  Result := FCampaign;
end;

class function TRequestClick.getFieldNames: TArray<String>;
begin
  Result := FFieldNames;
end;

function TRequestClick.getMarker: String;
begin
  Result := MARKER;
end;

procedure TRequestClick.setCampaign(const name: String);
begin
  FCampaign := name;
end;

initialization

TRequestClick.FFieldNames := ['time', 'request', 'query', 'target', 'trackCode',
  'ip', 'user-agent'];

finalization

end.
