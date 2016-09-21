unit ImageStorage;

interface

uses Web.HTTPApp, System.JSON;

type
  TImageStorage = class(TObject)
    /// <summary>Folder where to store the images.</summary>
  private
    BaseDirName: String;
    /// set the base dir
    procedure setBaseDir(const dir: String);

  const
    /// <summary>table into which the overall summary is to be written</summary>
    IMAGE_DIR_TOKEN: String = 'base dir';

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

    function getStatus(): TJsonObject;

    /// append given path to the base directory
    function getAbsolutePath(const path: String): String;

    property BaseDir: String read BaseDirName write setBaseDir;
  end;

implementation

uses
  System.IOUtils, System.Classes, System.SysUtils, System.RegularExpressions;

{ TImageStorage }

constructor TImageStorage.Create(const BaseDirName: String);
begin
  if (TDirectory.Exists(BaseDirName)) then
    TDirectory.CreateDirectory(BaseDirName);
  Self.BaseDirName := BaseDirName;
end;

function TImageStorage.getAbsolutePath(const path: String): String;
begin
  Result := TPath.Combine(BaseDirName, path);
end;

function TImageStorage.getStatus: TJsonObject;
begin
  Result := TJsonObject.Create;
  Result.AddPair(IMAGE_DIR_TOKEN, TJSonString.Create(BaseDirName));
end;

function TImageStorage.saveFile(const DirName: String;
  const AFile: TAbstractWebRequestFile): String;
var
  fname: string;
  I: Integer;
  fs: TFileStream;
  campaign, article, BaseDir, path: String;
begin
  fname := TPath.GetFileName(AFile.FileName.Trim(['"']));
  if TPath.HasValidFileNameChars(fname, false) then
  begin
    if not TDirectory.Exists(BaseDir, false) then
      TDirectory.CreateDirectory(BaseDir);
    path := TPath.Combine(BaseDir, fname);
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

procedure TImageStorage.setBaseDir(const dir: String);
var
  regex: TRegEx;
  dirNameTmp: String;
begin
  /// a pattern for invalid folder names
  regex := TRegEx.Create('[^a-zA-Z0-9_\' + PathDelim + ']');
  if (regex.isMatch(dir)) then
    Exit;
  /// remove trailing path delimiters
  dirNameTmp := TRegEx.Replace(dir, '^(\' + PathDelim + ')*|(\' + PathDelim
    + ')*$', '');
  /// remove duplicate path delimiters
  dirNameTmp := TRegEx.Replace(dirNameTmp, '(\' + PathDelim + ')*', PathDelim);
  if not(dirNameTmp.isEmpty) then
    BaseDirName := IncludeTrailingPathDelimiter(dirNameTmp);
end;

end.
