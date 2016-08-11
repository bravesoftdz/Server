unit StorageTests;

interface

uses
  DUnitX.TestFramework, Storage, System.Generics.Collections;

type

  [TestFixture]
  TStorageTests = class(TObject)
  strict private
    aTStorage: TDMStorage;
    data1: TDictionary<String, Integer>;
    data2: TDictionary<String, Integer>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [TEST]
    procedure TestPingServer;
    // [TEST]
    // procedure TestGetCampainImage;

    // [Test]
    // [TestCase('Single key',
    // 'report,auto-moto,UPDATE `report` SET `cars`=`cars`+5 WHERE `campaign`="auto-moto";')
    // ]
    procedure updateStatementSingleKey(const tblName, row, expected: String);

    // [Test]
    // [TestCase('Three keys',
    // 'digest#news#UPDATE `digest` SET `table`=`table`+3,`e-book`=`e-book`+21,`room`=`room`+98 WHERE `campaign`="news";',
    // '#')
    // ]
    procedure updateStatementThreeKeys(const tblName, row, expected: String);

  end;

implementation

uses
  MVCFramework.RESTAdapter, RedirectServerProxy.interfaces, System.Classes,
  MVCFramework.RESTClient, System.SysUtils, System.JSON;

procedure TStorageTests.Setup;
begin
  // aTStorage := TDMStorage.Create(nil,nil);
  // data1 := TDictionary<String, Integer>.Create;
  // data1.Add('cars', 5);
  // data2 := TDictionary<String, Integer>.Create;
  // data2.Add('table', 3);
  // data2.Add('e-book', 21);
  // data2.Add('room', 98);
end;

procedure TStorageTests.TearDown;
begin
  aTStorage := nil;
end;

// procedure TStorageTests.TestGetCampainImage;
// var
// RESTAdapter: TRESTAdapter<IRedirectServerProxy>;
// NewsWebResource: IRedirectServerProxy;
// r: String;
// begin
// RESTAdapter := TRESTAdapter<IRedirectServerProxy>.Create;
// NewsWebResource := RESTAdapter.Build('localhost', 5000);
// r := NewsWebResource.getCampaignImage('venditori',
// 'cartellina_natale_2015.jpg');
// Assert.IsTrue(r.equals('hello'), 'Il metodo non ha riportato hello');
// end;

procedure TStorageTests.TestPingServer;
var
  RESTAdapter: TRESTAdapter<IRedirectServerProxy>;
  NewsWebResource: IRedirectServerProxy;
  s: string;
  jo: TResponse;
begin
  RESTAdapter := TRESTAdapter<IRedirectServerProxy>.Create;
  NewsWebResource := RESTAdapter.Build('localhost', 5000);
  // r:=NewsWebResource.EchoText('hello');
  jo := NewsWebResource.serverPing;
  Assert.IsTrue(not jo.message.isempty);

end;

procedure TStorageTests.updateStatementSingleKey(const tblName, row,
  expected: String);
var
  actual: String;
begin
  actual := aTStorage.updateStatement(tblName, row, data1);
  Assert.AreEqual(expected, actual);
end;

procedure TStorageTests.updateStatementThreeKeys(const tblName, row,
  expected: String);
var
  actual: String;

begin
  actual := aTStorage.updateStatement(tblName, row, data2);
  Assert.AreEqual(expected, actual);
end;

end.
