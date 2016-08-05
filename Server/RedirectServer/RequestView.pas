unit RequestView;

interface

uses RequestType, System.Rtti, System.Classes, System.Generics.Collections;

type
  TRequestView = class(TRequestType)
  const
    MARKER = 'view';
    // FIELDNAMES : TArray<String> = ['time', 'request', 'query', 'trackCode', 'ip', 'user-agent'];
  private
    FCampaign: String;

    class var FFieldNames: TArray<String>;
  public
    class function getFieldNames: TArray<String>; override;
    function getCampaign: String; override;
    procedure setCampaign(const name: String); override;
    function getMarker: String; override;
    constructor Create;

  end;

implementation

uses
  System.SysUtils;

{ TRequestView }

constructor TRequestView.Create;
begin
  inherited;
  inherited setField(FFieldNames[0], FormatDateTime('yyyy-mm-dd hh:nn:ss',
    System.SysUtils.Now));
end;

function TRequestView.getCampaign: String;
begin
  Result := FCampaign;
end;

class function TRequestView.getFieldNames: TArray<String>;
begin
  Result := FFieldNames;
end;

function TRequestView.getMarker: String;
begin
  Result := MARKER;
end;

procedure TRequestView.setCampaign(const name: String);
begin
  FCampaign := name;
end;

initialization

TRequestView.FFieldNames := ['time', 'request', 'query', 'trackCode', 'ip',
  'user-agent'];

finalization

end.
