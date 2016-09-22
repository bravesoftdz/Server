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
    /// return true if there exists a file with given file path.
    /// The file path is relative w.r.t. base directory
    function ImageExists(const path: String): Boolean;

  const
    /// <summary>table into which the overall summary is to be written</summary>
    IMAGE_DIR_TOKEN: String = 'base dir';

  public
    /// <summary>save a file into a given folder.
    /// DirName is a relative path with respect to BaseDirName.
    /// Returns true in case of success, false otherwise.
    /// </summary>
    function saveFile(const DirName: String;
      const AFile: TAbstractWebRequestFile): Boolean;
    /// <summary>
    /// Instantiate an ImageStorage object with BaseDirName being a relative
    /// path with respect to the server executable path.
    /// </summary>
    constructor Create(const BaseDirName: String);

    function getStatus(): TJsonObject;

    /// append given path to the base directory
    function getAbsolutePath(const path: String): String;
    /// delete an image located at given path.
    /// The path is relative with respect to the base directory
    function DeleteImage(const path: String): Boolean;

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

function TImageStorage.DeleteImage(const path: String): Boolean;
begin
  /// TODO
  Result := False;
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

function TImageStorage.ImageExists(const path: String): Boolean;
begin
  Result := FileExists(TPath.Combine(BaseDirName, path))
end;

function TImageStorage.saveFile(const DirName: String;
  const AFile: TAbstractWebRequestFile): Boolean;
var
  I: Integer;
  outputStreamSize, inputStreamSize: Int64;
  fs: TFileStream;
  fname, BaseDir, path: String;
begin
  fname := TPath.GetFileName(AFile.FileName.Trim(['"']));
  Result := False;
  if not(ImageExists(TPath.Combine(DirName, fname))) and
    TPath.HasValidFileNameChars(fname, False) then
  begin
    BaseDir := TPath.Combine(BaseDirName, DirName);
    if not TDirectory.Exists(BaseDir, False) then
      TDirectory.CreateDirectory(BaseDir);
    path := TPath.Combine(BaseDir, fname);
    inputStreamSize := AFile.Stream.Size;
    fs := TFile.Create(path);
    try
      outputStreamSize := fs.CopyFrom(AFile.Stream, 0);
      Result := outputStreamSize = AFile.Stream.Size;
    finally
      fs.DisposeOf;
    end;
  end;
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
  dirNameTmp := TRegEx.Replace(dir, '^(\' + PathDelim + ')*|(\' + PathDelim +
    ')*$', '');
  /// remove duplicate path delimiters
  dirNameTmp := TRegEx.Replace(dirNameTmp, '(\' + PathDelim + ')*', PathDelim);
  if not(dirNameTmp.isEmpty) then
    BaseDirName := IncludeTrailingPathDelimiter(dirNameTmp);
end;

end.
