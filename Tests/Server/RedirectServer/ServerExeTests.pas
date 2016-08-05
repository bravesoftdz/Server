unit ServerExeTests;

interface

uses
  resources.clientproxy.interfaces,
  DUnitX.TestFramework,
  Server.Launcher,
  bo.users;

type

  [TestFixture]
  TServerTests = class(TObject)
  private
    FUserClientProxy: IResourceClientProxy<TUser>;
    function ProxyUtenti: IResourceClientProxy<TUser>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    // [TEST]
    procedure TestGetUtenteID_1;
    [TEST]
    procedure TestGetUtenti;
    [TEST]
    procedure TestGetDeleteUtente;
    [TEST]
    procedure TestGetInsertUtente;
    [TEST]
    procedure TestGetUpdateUtente;
  end;

implementation

uses
  system.SysUtils,
  bo.helpers,
  system.Classes,
  Controller.webbase,
  PresenzeWebModule,
  bo.ormInterfaces,
  Services.Locator,
  resource.users.clientproxy,
  system.Generics.Collections;

{ TServerTests }

function TServerTests.ProxyUtenti: IResourceClientProxy<TUser>;
begin
  if not Assigned(FUserClientProxy) then

    FUserClientProxy := TServicesLocator.GetInstance.
      Resolve<IResourceClientProxy<TUser>>;
  Result := FUserClientProxy;
end;

procedure TServerTests.Setup;
var
  c: IBaseOrmServiceConnectionAdapter;
begin
  c := TServicesLocator.GetInstance.Resolve<IBaseOrmServiceConnectionAdapter>;
  c.ExecuteScriptFile('Data\utenti.sql');

end;

procedure TServerTests.TearDown;
begin
end;

procedure TServerTests.TestGetDeleteUtente;
var
  u: TUser;
begin
  ProxyUtenti.Delete(1);
  try
    u := ProxyUtenti.Get(1);
    Assert.IsTrue(Assigned(u));
    Assert.IsTrue(u.ID = 0);
  finally
    u.DisposeOf;
  end;

end;

procedure TServerTests.TestGetInsertUtente;
var
  u, u2: TUser;
begin
  u := TUser.create;
  try
    u.ID := 3;
    u.Nome := 'Test';
    u.Cognome := 'TestCognome';
    ProxyUtenti.post(u);
    u2 := ProxyUtenti.Get(3);
    try
      Assert.IsTrue(Assigned(u2));
      Assert.IsTrue(u2.ToJsonString.equals(u.ToJsonString));
    finally
      u2.DisposeOf;
    end;
  finally
    u.DisposeOf;
  end;

end;

procedure TServerTests.TestGetUpdateUtente;
var
  u, u2: TUser;
begin
  u := TUser.create;
  try
    u.ID := 2;
    u.Nome := 'Test';
    u.Cognome := 'TestCognome';
    ProxyUtenti.put(u);
    u2 := ProxyUtenti.Get(2);
    try
      Assert.IsTrue(Assigned(u2));
      Assert.IsTrue(u2.ToJsonString.equals(u.ToJsonString));
    finally
      u2.DisposeOf;
    end;
  finally
    u.DisposeOf;
  end;

end;

procedure TServerTests.TestGetUtenteID_1;
var
  u: TUser;
begin
  u := ProxyUtenti.Get(1);
  try
    Assert.IsTrue(Assigned(u));
  finally
    u.DisposeOf;
  end;
end;

procedure TServerTests.TestGetUtenti;
var
  u: TObjectList<TUser>;
begin
  u := ProxyUtenti.Get;
  try
    Assert.IsTrue(Assigned(u));
    Assert.IsTrue(u.Count = 2);
  finally
    u.DisposeOf;
  end;

end;

initialization

end.
