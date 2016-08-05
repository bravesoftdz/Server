unit server.version;

interface

const

{$IFDEF RELEASE}
  version = '#DATETIME#';

{$ELSE}
  version = '1';

{$ENDIF}

implementation

end.
