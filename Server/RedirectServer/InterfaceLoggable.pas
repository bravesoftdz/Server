unit InterfaceLoggable;

interface

uses
  InterfaceLogger;

type
  ILoggable = interface
    ['{8CF9443E-A268-4736-B049-C0A4FC09C306}']
    procedure LogIfPossible(const level: TLEVELS; const tag, msg: string);
  end;

implementation

end.
