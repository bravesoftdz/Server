unit Settings;

interface

type
  TSettings = class
  private
    FRedirectServerUrl: String;
    FRedirectServerPort: Integer;
    FAuth: String;
    fileName: String;
  public
    property redirectServerUrl: String read FRedirectServerUrl write FRedirectServerUrl;
    property redirectServerPort: Integer read FRedirectServerPort write FRedirectServerPort;
    property auth: String read FAuth write FAuth;
    constructor Create(const fileName: String);
    procedure load();
  end;

implementation

uses bo.Helpers, System.IOUtils, System.SysUtils, Winapi.Windows;

{ TSettings }

constructor TSettings.Create(const fileName: String);
begin
  if FileExists(fileName) then
  begin
    self.fileName := fileName;
    load();
  end
  else
  begin
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 15 OR BACKGROUND_RED);
    System.Write('Warning:');
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 7);
    Write(' Configuration file ');
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 15);
    Write(fileName);
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 7);
    Write(' is not found in folder ');
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 15);
    Write(GetCurrentDir);
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 7);
  end;
end;

procedure TSettings.load;
begin
  if TFile.Exists(fileName) then
    LoadFromJFile(fileName)
  else
  begin
    Writeln('Warning: file ' + fileName + ' does not exist!');
    Writeln('No configuration is loaded.');
  end;
end;

end.
