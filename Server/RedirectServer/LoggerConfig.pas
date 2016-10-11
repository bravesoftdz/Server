unit LoggerConfig;

interface

type
  TLoggerConfig = class
  private
    FLogDir: String;
    FMaxCacheSize: Integer;
  public
    property LogDir: String read FLogDir write FLogDir;
    property MaxCacheSize: Integer read FMaxCacheSize write FMaxCacheSize;
  end;


implementation

end.
