unit LoggerConfig;

interface

type
  TLoggerConfig = class
  private
    FLogDir: String;
    FMaxCacheSize: Integer;
  public
    property logdir: String read FLogDir write FLogDir;
    property maxcachesize: Integer read FMaxCacheSize write FMaxCacheSize;
  end;


implementation

end.
