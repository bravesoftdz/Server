unit ControlServerDispatcher;

interface

uses
  Controller.Base,
  MVCFramework,
  System.Classes, Settings, MVCFramework.RESTAdapter,
  RedirectServerProxy.interfaces, InterfaceAuthentication, InterfaceLoginData;

type

  [MVCPath('/control')]
  TControlServerController = class abstract(TBaseController)
  private

    class var Settings: TSettings;
    class var RESTAdapter: TRESTAdapter<IRedirectServerProxy>;
    class var WebResource: IRedirectServerProxy;
    class var Authentication: IAuthentication;
    class function getUsageString(): String;

  const
    AUTHENTICATED_TOKEN: String = 'authenticated';
    SERVER_URL_SWITCH = 's';
    SERVER_PORT_SWITCH = 'p';
    AUTH_SWITCH = 'a';
    SWITCH_CHAR = '-';

    /// <summary>Configure the server</summary>
    class procedure Configure();
    /// <summary>Stop the server</summary>
    class procedure Stop();
    class function isLoggedIn(const LoginData: ILoginData): Boolean;

  protected
    procedure OnBeforeAction(Context: TWebContext; const AActionNAme: string;
      var Handled: Boolean); override;

    /// <summary>Mark the user with given credetials as authorized</summary>
    procedure authorize(authData: ILoginData);
  public
    [MVCPath('/connect')]
    [MVCHTTPMethod([httpGET])]
    procedure testConnection(ctx: TWebContext);

    [MVCPath('/ping')]
    [MVCHTTPMethod([httpGET])]
    procedure ping(ctx: TWebContext);

    [MVCPath('/status')]
    [MVCHTTPMethod([httpGET])]
    procedure getStatus(ctx: TWebContext);

    [MVCPath('/routes')]
    [MVCHTTPMethod([httpGET])]
    procedure getRoutes(ctx: TWebContext);

    /// <summary>Perform a log in. The authentication parameters must be provided
    /// as a json object with two keys: "username" and "password".
    /// Value corresponding to the key "password" is not a password, but its
    /// hash obtained from the password by applying a cryptographic algorithm.</summary>
    [MVCPath('/login')]
    [MVCHTTPMethod([httpPOST])]
    procedure login(ctx: TWebContext);

    /// <summary>Perform a log out.</summary>
    [MVCPath('/logout')]
    [MVCHTTPMethod([httpPOST])]
    procedure logout(ctx: TWebContext);
  end;

implementation

uses
  FireDAC.Comp.Client,
  Vcl.Forms,
  IdURI,
  Winapi.Windows,
  System.Types, System.SysUtils, IdStack, SimpleAuthentification, System.JSON, LoginData;

{ TControlServerController }

procedure TControlServerController.authorize(authData: ILoginData);
begin
  Session[authData.getUsername] := 'logged';
end;

class procedure TControlServerController.Configure();
var
  ServerUrl, ServerPortStr, UserAuthFile: String;
  ServerPort: Integer;
begin
  if FindCmdLineSwitch(SERVER_URL_SWITCH, ServerUrl, False) AND
    FindCmdLineSwitch(SERVER_PORT_SWITCH, ServerPortStr, False) AND
    FindCmdLineSwitch(AUTH_SWITCH, UserAuthFile, False) then
  begin
    ServerPort := -1;
    try
      ServerPort := StrToInt(ServerPortStr);
    except
      on E: Exception do
      begin
        SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 15);
        Writeln('Invalid port number: ', E.Message);
        SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 7);
      end
    end;
    if ServerPort > 0 then
    begin
      TControlServerController.Authentication := TFileBasedAuthentification.Create(UserAuthFile);
      TControlServerController.RESTAdapter := TRESTAdapter<IRedirectServerProxy>.Create;
      TControlServerController.WebResource := TControlServerController.RESTAdapter.Build(ServerUrl,
        ServerPort);
    end
    else
    begin
      SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 15);
      Writeln('Port number must be a positive one');
      SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 7);
    end;
  end
  else
  begin
    Writeln(getUsageString());
    Exit();
  end;
end;

procedure TControlServerController.getRoutes(ctx: TWebContext);
begin
  // Render(WebResource.getRoutes);
end;

procedure TControlServerController.getStatus(ctx: TWebContext);
begin

  Render(WebResource.getServerStatus());
end;

class function TControlServerController.isLoggedIn(const LoginData: ILoginData): Boolean;
begin
  // stub
  Result := False;
end;

procedure TControlServerController.login(ctx: TWebContext);
var
  LoginData: ILoginData;
  data: TJSonObject;
  Auth: IAuthentication;
  isValid: Boolean;
  isLogged: Boolean;
begin
  data := ctx.Request.BodyAsJSONObject;
  LoginData := TLoginData.Create(data);
  isValid := TControlServerController.Authentication.isValidLoginData(LoginData);
  isLogged := isLoggedIn(LoginData);
  if isValid then
    authorize(LoginData);
  LoginData := nil;
  Render(TJsonBool.Create(isValid));
end;

procedure TControlServerController.logout(ctx: TWebContext);
begin

end;

procedure TControlServerController.OnBeforeAction(Context: TWebContext; const AActionNAme: string;
  var Handled: Boolean);
begin
  // inherited;

end;

procedure TControlServerController.ping(ctx: TWebContext);
begin
  Render('ok');
end;

class function TControlServerController.getUsageString: String;
begin
  Result := 'Usage:' + sLineBreak + ExtractFileName(paramstr(0)) + ' ' + SWITCH_CHAR +
    SERVER_URL_SWITCH + ' <url> ' + SWITCH_CHAR + SERVER_PORT_SWITCH + ' <port> ' + SWITCH_CHAR +
    AUTH_SWITCH + ' <file>' + sLineBreak + 'where ' + sLineBreak +
    '<url> - url of the redirect server,' + sLineBreak +
    '<port> - port number of the redirect server,' + sLineBreak +
    '<file> - file name containing authorization data.';
end;

class procedure TControlServerController.Stop;
begin
  if Assigned(TControlServerController.Settings) then
    TControlServerController.Settings.DisposeOf;
  if Assigned(TControlServerController.RESTAdapter) then
    TControlServerController.RESTAdapter.DisposeOf;

  TControlServerController.Authentication := nil;
  TControlServerController.WebResource := nil;
end;

procedure TControlServerController.testConnection(ctx: TWebContext);
var
  resp: TResponse;
begin
  // try
  // resp := WebResource.serverPing;
  // try
  // if not(resp = nil) then
  // Render('Received responce: ' + resp.status)
  // else
  // Render('Null responce');
  // except
  // on E: EIdSocketError do
  // Render('No connection');
  // end;
  // finally
  // resp := nil
  // end;
end;

initialization

TControlServerController.Configure();

finalization

TControlServerController.Stop();

end.
