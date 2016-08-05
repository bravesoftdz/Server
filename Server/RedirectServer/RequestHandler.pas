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
  end;

  TRequestHandler = class(TInterfacedObject, IRequestHandler)
  private
    FRequests: TObjectList<TRequestType>;
    Logger: ILogger;
    BufferSize: Integer;
    Storage: TDMStorage;

  public
    procedure Archive(const data: TRequestType);
    procedure Commit;
    function Count: Integer;
    constructor Create(const Logger: ILogger; const CacheSize: Integer;
      const Storage: TDMStorage);

    procedure configure(const Logger: ILogger; const CacheSize: Integer;
      const Storage: TDMStorage);
    destructor Destroy; override;
  end;

implementation

uses
  System.IOUtils,
  System.SysUtils,
  Logger, Settings;

var
  FLockObject: TObject;

  { TRequestHandler }

constructor TRequestHandler.Create(const Logger: ILogger;
  const CacheSize: Integer; const Storage: TDMStorage);
begin
  FRequests := TObjectList<TRequestType>.Create;
  FLockObject := TObject.Create;
  configure(Logger, CacheSize, Storage);
end;

destructor TRequestHandler.Destroy;
begin
  Storage := nil;
  Logger := nil;
  FLockObject.DisposeOf;
  FRequests.DisposeOf;
  inherited;
end;

procedure TRequestHandler.configure(const Logger: ILogger;
  const CacheSize: Integer; const Storage: TDMStorage);
begin
  BufferSize := CacheSize;
  self.Logger := Logger;
  self.Storage := Storage;
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
    if FRequests.Count > BufferSize then
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
      outcome := Storage.save(FRequests);
      if outcome then
        FRequests.Clear
      else
        Logger.logWarning(TAG,
          'Saving of the statistics to the DB has been postponed.');
    except
      on e: Exception do
      begin
        Logger.logException(TAG, e.Message);
      end;
    end;
  finally
    TMonitor.Exit(FLockObject);
  end;

end;

initialization

finalization

end.
