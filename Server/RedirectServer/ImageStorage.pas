unit ImageStorage;

interface

uses Web.HTTPApp;

type
  TImageStorage = class(TObject)
    /// <summary>Folder where to store the images.</summary>
  private
    BaseDirName: String;

  public
    /// <summary>save a file into a given folder.
    /// DirName is a relative path with respect to BaseDirName.
    /// Returns a path to the saved file.
    /// </summary>
    function saveFile(const DirName: String;
      const AFile: TAbstractWebRequestFile): String;
    /// <summary>
    /// Instantiate an ImageStorage object with BaseDirName being a relative
    /// path with respect to the server executable path.
    /// </summary>
    constructor Create(const BaseDirName: String);

  end;

implementation

uses
  System.IOUtils, System.Classes, System.SysUtils;

{ TImageStorage }

constructor TImageStorage.Create(const BaseDirName: String);
begin
  if (TDirectory.Exists(BaseDirName)) then
    TDirectory.CreateDirectory(BaseDirName);
  Self.BaseDirName := BaseDirName;
end;

function TImageStorage.saveFile(const DirName: String;
  const AFile: TAbstractWebRequestFile): String;
var
  fname: string;
  I: Integer;
  fs: TFileStream;
  campaign, article, baseDir, path: String;
begin
  fname := TPath.GetFileName(AFile.FileName.Trim(['"']));
  if TPath.HasValidFileNameChars(fname, false) then
  begin
    if not TDirectory.Exists(baseDir, false) then
      TDirectory.CreateDirectory(baseDir);
    path := TPath.Combine(baseDir, fname);
    fs := TFile.Create(path);
    try
      fs.CopyFrom(AFile.Stream, 0);
      Result := path;
    finally
      fs.DisposeOf;
    end;
  end
  else
    Result := '';
end;

end.
