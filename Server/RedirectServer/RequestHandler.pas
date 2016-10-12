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
    procedure SetStorage(const St: TDMStorage);
    procedure SetLogger(const Logger: ILogger);

    property Storage: TDMStorage write SetStorage;
    property Logger: ILogger write SetLogger;
  end;

  TRequestHandler = class(TInterfacedObject, IRequestHandler)
  private
    FLogger: ILogger;
    FStorage: TDMStorage;

  public
    /// <summary> Archive the request. </summary>
    procedure Archive(const data: TRequestType);
    destructor Destroy; override;
    procedure SetStorage(const St: TDMStorage);
    procedure SetLogger(const Logger: ILogger);

    property Storage: TDMStorage write SetStorage;
    property Logger: ILogger write SetLogger;
  end;

implementation

uses
  System.IOUtils,
  System.SysUtils,
  Logger, Settings;

{ TRequestHandler }

destructor TRequestHandler.Destroy;
begin
  FStorage := nil;
  FLogger := nil;
  inherited;
end;

procedure TRequestHandler.SetLogger(const Logger: ILogger);
begin
  FLogger := Logger;
end;

procedure TRequestHandler.SetStorage(const St: TDMStorage);
begin
  FStorage := St;
end;

procedure TRequestHandler.Archive(const data: TRequestType);
begin
  TThread.CreateAnonymousThread(
    procedure
    begin
      if not(FStorage = nil) then
        FStorage.add(data);
    end).Start;
end;

initialization

finalization

end.
