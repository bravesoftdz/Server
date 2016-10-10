unit InterfaceLogger;

interface

uses
  System.JSON, Logger;

type
  ILogger = interface
    ['{0020D75E-C10E-466B-AB6B-3DB8506EE126}']
    procedure logAccess(const source, msg: String);
    procedure logWarning(const source, msg: String);
    procedure logException(const source, msg: String);
    procedure logInfo(const source, msg: String);
    procedure flushCache;
    procedure configure(const data: TLoggerConfig);
    function getStatus(): TJsonObject;
    procedure setProperties(const Params: TJsonObject);

  end;

implementation

end.
