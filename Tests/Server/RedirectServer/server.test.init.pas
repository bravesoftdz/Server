unit server.test.init;

interface

implementation

uses
  proxy.interfaces,
  proxy.base,
  spring.container,
  proxy.MVCRestClient,
  bo.OrmFDServiceAdapter,
  bo.ormInterfaces;

procedure ServerTestsRegister;
begin
  GlobalContainer.RegisterType<TFDConnectionAdapter>.
    Implements<IBaseOrmServiceConnectionAdapter>.InjectMethod('AddParam',
    ['DriverID', 'MySQL'])

    .InjectMethod('AddParam', ['Server', 'LocalHost']).InjectMethod('AddParam',
    ['DataBase', 'presenzetest']).InjectMethod('AddParam', ['User_Name', 'root']
    ).InjectMethod('AddParam', ['Password', 'rtc29d21'])
    .InjectMethod('AddParam', ['Port', '3306']);

  GlobalContainer.Build;

end;

initialization

ServerTestsRegister;

end.
