unit RequestHandler;

interface

uses
  InterfaceRequestData,
  MVCFramework,
  System.Classes,
  System.JSON,
  RequestType, InterfaceLogger,
  Storage,
  System.Generics.Collections;

type
  IRequestHandler = interface
    ['{ED36121D-23E8-45FA-8F19-CF46EAB85E9F}']

    procedure Archive(const data: TRequestType);
    procedure Commit;
    function Count: Integer;
    procedure configure(const Logger: ILogger; const CacheSize: Integer;
      const Storage: TDMStorage);
    procedure SetStorage(const St: TDMStorage);
    procedure SetLogger(const Logger: ILogger);
    procedure SetMaxCacheSize(MaxcacheSize: Integer);

    property Storage: TDMStorage write SetStorage;
    property Logger: ILogger write SetLogger;
    property CacheSize: Integer write SetMaxCacheSize;
  end;

  TRequestHandler = class(TInterfacedObject, IRequestHandler)
  private
    FRequests: TObjectList<TRequestType>;
    FLogger: ILogger;
    FMaxCacheSize: Integer;
    FStorage: TDMStorage;

  public
    procedure Archive(const data: TRequestType);
    procedure Commit;
    function Count: Integer;
    constructor Create;

    procedure configure(const Logger: ILogger; const CacheSize: Integer;
      const Storage: TDMStorage);
    destructor Destroy; override;
    procedure SetStorage(const St: TDMStorage);
    procedure SetLogger(const Logger: ILogger);
    procedure SetMaxCacheSize(MaxCacheSize: Integer);

    property Storage: TDMStorage write SetStorage;
    property Logger: ILogger write SetLogger;
    property CacheSize: Integer write SetMaxCacheSize;
  end;

implementation

uses
  System.IOUtils,
  System.SysUtils,
  Logger, Settings;

var
  FLockObject: TObject;

  { TRequestHandler }

constructor TRequestHandler.Create;
begin
  FRequests := TObjectList<TRequestType>.Create;
  FLockObject := TObject.Create;
end;

destructor TRequestHandler.Destroy;
begin
  FStorage := nil;
  FLogger := nil;
  FLockObject.DisposeOf;
  FRequests.DisposeOf;
  inherited;
end;

procedure TRequestHandler.SetLogger(const Logger: ILogger);
begin
  FLogger := Logger;
end;

procedure TRequestHandler.SetMaxCacheSize(MaxCacheSize: Integer);
begin
  if MaxCacheSize >= 0 then
    FMaxCacheSize := MaxCacheSize;
end;

procedure TRequestHandler.SetStorage(const St: TDMStorage);
begin
  FStorage := St;
end;

procedure TRequestHandler.configure(const Logger: ILogger;
  const CacheSize: Integer; const Storage: TDMStorage);
begin
  FMaxCacheSize := CacheSize;
  self.FLogger := Logger;
  self.FStorage := Storage;
end;

function TRequestHandler.Count;
begin
  result := FRequests.Count;
end;

procedure TRequestHandler.Archive(const data: TRequestType);
begin
  TMonitor.Enter(FLockObject);
  try
    FRequests.Add(data);
    if FRequests.Count > FMaxCacheSize then
    begin
      Commit();
    end;
  finally
    TMonitor.Exit(FLockObject);
  end;
end;

procedure TRequestHandler.Commit();
const
  TAG: String = 'TRequestHandler.Commit';
var
  outcome: Boolean;
begin
  TMonitor.Enter(FLockObject);
  try
    try
      outcome := FStorage.save(FRequests);
      if outcome then
        FRequests.Clear
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

initialization

finalization

end.
