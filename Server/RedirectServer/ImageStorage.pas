unit ImageStorage;

interface

uses Web.HTTPApp;

type
  TImageStorage = class(TObject)

  public
    /// <summary>save a file into a given folder.
    /// DirName is a relative path with respect to BaseDirName
    /// </summary>
    procedure saveFile(const DirName: String;
      const AFile: TAbstractWebRequestFile);
    constructor Create(const BaseDirName: String);

  end;

implementation

{ TImageStorage }

procedure TImageStorage.saveFile(const DirName: String;
  const AFile: TAbstractWebRequestFile);
begin

end;

end.
