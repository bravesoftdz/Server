unit ServerConfig;

interface

uses System.JSON, Logger;

type
  TServerConfig = class
  private
    FLogger, FRouter, FDbStorage, FImageStorage, FRequestHandler: String;
  public
    property logger: String read FLogger write FLogger;
    property router: String read FRouter write FRouter;
    property dbStorage: String read FDbStorage write FDbStorage;
    property imageStorage: String read FImageStorage write FImageStorage;
    property requestHandler: String read FRequestHandler write FRequestHandler;
    constructor Create(const fileName: String);
  end;

implementation

uses bo.Helpers, System.IOUtils, System.SysUtils, Winapi.Windows,
  rttiObjectsMappers;

constructor TServerConfig.Create(const fileName: String);
begin
  if TFile.Exists(fileName, False) then
    LoadFromJFile(fileName)
  else
  begin
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE),
      15 OR BACKGROUND_RED);
    System.Write('Warning:');
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 7);
    System.Write(' Configuration file ');
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 15);
    System.Write(fileName);
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 7);
    System.Writeln(' is not found. Hope to find it later.');
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 7);
  end;

end;

end.
