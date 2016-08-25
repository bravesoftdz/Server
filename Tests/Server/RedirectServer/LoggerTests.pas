unit LoggerTests;

interface

uses
  DUnitX.TestFramework, Logger, InterfaceLogger;

type

  [TestFixture]
  TLoggerTests = class(TObject)
  strict private
    aTLogger: ILogger;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    /// <summary> Set the log dir if the corresponding parameter in the json object
    /// is a valid one </summary>
    [Test]
    [TestCase('Append the path delimiter to the first level dir', 'dir,dir\')]
    [TestCase('Append the path delimiter to the second level dir',
      'abc\efg,abc\efg\')]
    [TestCase('Removes the path delimiter at the beginning',
      '\folder\,folder\')]
    [TestCase('Assign the log dir', 'abc\,abc\')]
    [TestCase('Assign the log dir with digits', 'abc123\,abc123\')]
    [TestCase('Assign the log dir with underscores', 'a_bc\,a_bc\')]
    [TestCase('Assign the log dir of the second level', 'abc\efg\,abc\efg\')]
    [TestCase('Removes multiple path delimiters', '\\a,a\')]
    [TestCase('Removes multiple path delimiters', '\\a\\\\,a\')]
    [TestCase('Removes multiple path delimiters', 'a\b\\\,a\b\')]
    procedure setLogDir(const validLogName, output: String);

    /// <summary> If the log dir parameter is set to 'logfolder\' and then
    /// one tries to set it to a path that contains illegal symbols, that
    /// parameter remains equal to 'logfolder\'. </summary>
    [Test]
    [TestCase('Do not set if question sign is present', '?aaa')]
    [TestCase('Do not set if question sign is present', 'aaa?')]
    [TestCase('Do not set if question sign is present', 'a?a')]
    [TestCase('Do not set if exclamation sign is present', '!aaa')]
    [TestCase('Do not set if exclamation sign is present', 'aaa!')]
    [TestCase('Do not set if exclamation sign is present', 'a!a')]
    [TestCase('Do not set if a dot is present', '.aaa')]
    [TestCase('Do not set if a dot is present', './aaa')]
    [TestCase('Do not set if a dot is present', '../aaa')]
    [TestCase('Do not set if a dot is present', '.\aaa')]
    [TestCase('Do not set if a dot is present', '..\aaa')]
    [TestCase('Do not set if a dot is present', 'aaa/../')]
    [TestCase('Do not set if a dot is present', 'aaa\..\')]
    [TestCase('Do not set if it is empty', '')]
    [TestCase('Do not set if it is \\\', '\\\')]
    procedure doNotSetDirNameWithIllegalSymbols(const illegalDirName: String);

    /// <summary>  When the json object containing the parameters, contains max
    /// cache size property equal to 5, then this value must be set </summary>
    [Test]
    [TestCase('Set max cache size to 0', '0,0')]
    [TestCase('Set max cache size to 1', '1,1')]
    [TestCase('Set max cache size to 20', '20,20')]
    procedure setMaxCacheSizeToNonNegativeInteger(const input, output: String);

    /// <summary>  When setting the max cache size property first to 2 and
    /// then to an invalid number (negative or non-integer), the property must
    // remain equal to 2 </summary>
    [Test]
    [TestCase('Do not set max cache size to -1', '-1')]
    [TestCase('Do not set max cache size to -2', '-2')]
    [TestCase('Do not set max cache size to 1.1', '1.1')]
    [TestCase('Do not set max cache size to -6.32', '-6.32')]
    procedure doNotSetMaxCacheSizeToInvalid(const input: String);

    /// <summary> Set log dir and max cache size parameters
    /// simultaneoulsy to valid values </summary>
    [Test]
    [TestCase('Set log dir to aaa\, max cache size to 10', 'aaa\,10,aaa\,10')]
    [TestCase('Set log dir to aaa\, max cache size to 5', 'aaa,5,aaa\,5')]
    [TestCase('Set log dir to aaa\bbb\, max cache size to 0',
      'aaa\bbb\,0,aaa\bbb\,0')]
    [TestCase('Set log dir to aaa\bbb\, max cache size to 0',
      'aaa\bbb,0,aaa\bbb\,0')]
    procedure setLogDirAndMaxCacheSize(const logDirIn, cacheSizeIn, logDirOut,
      cacheSizeOut: String);

  end;

implementation

uses System.JSON, System.SysUtils;

{ TLoggerTests }

procedure TLoggerTests.doNotSetDirNameWithIllegalSymbols
  (const illegalDirName: String);
var
  paramIn, paramOut: TJsonObject;
begin
  paramIn := TJsonObject.Create;
  paramIn.AddPair('logger folder', 'logfolder\');
  aTLogger.setProperties(paramIn);
  paramIn.Disposeof;
  paramIn := TJsonObject.Create;
  paramIn.AddPair('logger folder', illegalDirName);
  aTLogger.setProperties(paramIn);
  paramOut := aTLogger.getStatus;
  Assert.AreEqual('logfolder\', paramOut.Values['logger folder'].Value,
    'The log folder must remain equal to logfolder\');
  paramIn.Disposeof;
  paramOut.Disposeof;
end;

procedure TLoggerTests.setLogDir(const validLogName, output: String);
var
  paramIn, paramOut: TJsonObject;
begin
  paramIn := TJsonObject.Create;
  paramIn.AddPair('logger folder', validLogName);
  aTLogger.setProperties(paramIn);
  paramOut := aTLogger.getStatus;
  Assert.AreEqual(output, paramOut.Values['logger folder'].Value,
    'The log dir must be equal to ' + output);
  paramIn.Disposeof;
  paramOut.Disposeof;
end;

procedure TLoggerTests.setLogDirAndMaxCacheSize(const logDirIn, cacheSizeIn,
  logDirOut, cacheSizeOut: String);
var
  paramIn, paramOut: TJsonObject;
begin
  paramIn := TJsonObject.Create;
  paramIn.AddPair('max cache size', TJSONNumber.Create(strtoint(cacheSizeIn)));
  paramIn.AddPair('logger folder', logDirIn);
  aTLogger.setProperties(paramIn);
  paramOut := aTLogger.getStatus;
  Assert.AreEqual(cacheSizeOut, paramOut.Values['max cache size'].Value,
    'The max cache size param must be set to ' + cacheSizeOut);
  Assert.AreEqual(logDirOut, paramOut.Values['logger folder'].Value,
    'The log dir must be set to ' + logDirOut);
  paramIn.Disposeof;
  paramOut.Disposeof;
end;

procedure TLoggerTests.setMaxCacheSizeToNonNegativeInteger(const input,
  output: String);
var
  paramIn, paramOut: TJsonObject;
begin
  paramIn := TJsonObject.Create;
  paramIn.AddPair('max cache size', TJSONNumber.Create(strtoint(input)));
  aTLogger.setProperties(paramIn);
  paramOut := aTLogger.getStatus;
  Assert.AreEqual(output, paramOut.Values['max cache size'].Value,
    'The max cache size param must be set to ' + output);
  paramIn.Disposeof;
  paramOut.Disposeof;
end;

procedure TLoggerTests.doNotSetMaxCacheSizeToInvalid(const input: String);
var
  paramIn, paramOut: TJsonObject;
begin
  paramIn := TJsonObject.Create;
  paramIn.AddPair('max cache size', TJSONNumber.Create(2));
  aTLogger.setProperties(paramIn);
  paramIn.Disposeof;
  paramIn := TJsonObject.Create;
  paramIn.AddPair('max cache size', TJSONNumber.Create(input));
  aTLogger.setProperties(paramIn);
  paramOut := aTLogger.getStatus;
  Assert.AreEqual('2', paramOut.Values['max cache size'].Value,
    'The max cache size param must be equal to 2');
  paramIn.Disposeof;
  paramOut.Disposeof;
end;

procedure TLoggerTests.Setup;
begin
  aTLogger := TLogger.Create();
end;

procedure TLoggerTests.TearDown;
begin
  aTLogger := nil;
end;

end.
