unit InterfaceRequestData;

interface

type
  IRequestData = interface
    ['{76FF14D6-B230-49D7-A34F-50342C8B7B5F}']
    function getIp(): String;
    function getUserAgent(): String;
    function getRequestedPath(): String;
    function getUrl(): String;
    function getTime(): String;
    function getParameters(): String;

  end;

implementation

end.
