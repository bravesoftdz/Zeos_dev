unit ZURL;

interface

uses
  Classes,
  SysUtils;

type
  TZURL = class
  private
    FPrefix: string;
    FProtocol: string;
    FHostName: string;
    FPort: Integer;
    FDatabase: string;
    FUserName: string;
    FPassword: string;
    FProperties: TStringList;
    procedure SetPrefix(const Value: string);
    procedure SetProtocol(const Value: string);
    procedure SetHostName(const Value: string);
    procedure SetPort(const Value: Integer);
    procedure SetDatabase(const Value: string);
    procedure SetUserName(const Value: string);
    procedure SetPassword(const Value: string);
    function GetURL: string;
    procedure SetURL(const Value: string);
    procedure OnPropertiesChange(Sender: TObject);
  public
    constructor Create;
    destructor Destroy; override;
    property Prefix: string read FPrefix write SetPrefix;
    property Protocol: string read FProtocol write SetProtocol;
    property HostName: string read FHostName write SetHostName;
    property Port: Integer read FPort write SetPort;
    property Database: string read FDatabase write SetDatabase;
    property UserName: string read FUserName write SetUserName;
    property Password: string read FPassword write SetPassword;
    property Properties: TStringList read FProperties;
    property URL: string read GetURL write SetURL;
  end;

implementation

{ TZURL }

constructor TZURL.Create;
begin
  inherited;

  FPrefix := 'zdbc';
  FProperties := TStringList.Create;
  FProperties.CaseSensitive := False;
  FProperties.OnChange := OnPropertiesChange;
end;

destructor TZURL.Destroy;
begin
  FProperties.Free;

  inherited;
end;

procedure TZURL.SetPrefix(const Value: string);
begin
  FPrefix := Value;
end;

procedure TZURL.SetProtocol(const Value: string);
begin
  FProtocol := Value;
end;

procedure TZURL.SetHostName(const Value: string);
begin
  FHostName := Value;
end;

procedure TZURL.SetPort(const Value: Integer);
begin
  FPort := Value;
end;

procedure TZURL.SetDatabase(const Value: string);
begin
  FDatabase := Value;
end;

procedure TZURL.SetUserName(const Value: string);
begin
  FUserName := Value;
end;

procedure TZURL.SetPassword(const Value: string);
begin
  FPassword := Value;
end;

function TZURL.GetURL: string;
var
  I: Integer;
  PropName: string;
  PropValue: string;
begin
  Result := '';

  // Prefix
  Result := Result + Prefix + ':';

  // Protocol
  Result := Result + Protocol + ':';

  // HostName/Port
  if HostName <> '' then
  begin
    Result := Result + '//' + HostName;
    if Port <> 0 then
      Result := Result + ':' + IntToStr(Port);
  end;

  // Database
  if Database <> '' then
    Result := Result + '/' + Database;

  // ?
  if (FUserName <> '') or (FPassword <> '') or (Properties.Count > 0) then
    Result := Result + '?';

  // UserName
  if FUserName <> '' then
    Result := Result + 'username=' + FUserName;

  // Password
  if FPassword <> '' then
  begin
    if Result[Length(Result)] <> '?' then
      Result := Result + ';';
    Result := Result + 'password=' + FPassword
  end;

  // Properties
  for I := 0 to Properties.Count - 1 do
  begin
    PropName := FProperties.Names[I];
    PropValue := LowerCase(FProperties.Values[PropName]);
    if (PropValue <> '') and (PropValue <> '') and (PropValue <> 'uid') and (PropValue <> 'pwd') and (PropValue <> 'username') and (PropValue <> 'password') then
    begin
      if Result[Length(Result)] <> '?' then
        Result := Result + ';';
      Result := Result + FProperties[I]
    end;
  end;
end;

procedure TZURL.SetURL(const Value: string);
var
  APrefix: string;
  AProtocol: string;
  AHostName: string;
  APort: string;
  ADatabase: string;
  AUserName: string;
  APassword: string;
  AProperties: TStrings;
  AValue: string;
  I: Integer;
begin
  APrefix := '';
  AProtocol := '';
  AHostName := '';
  APort := '';
  ADatabase := '';
  AUserName := '';
  APassword := '';
  AProperties := TStringList.Create;

  try
    AValue := Value;

    // APrefix
    I := Pos(':', AValue);
    if I = 0 then
      raise Exception.Create('TZURL.SetURL - The prefix is missing');
    APrefix := Copy(AValue, 1, I - 1);
    Delete(AValue, 1, I);

    // AProtocol
    I := Pos(':', AValue);
    if I = 0 then
      raise Exception.Create('TZURL.SetURL - The protocol is missing');
    AProtocol := Copy(AValue, 1, I - 1);
    Delete(AValue, 1, I);

    // AHostName
    if Pos('//', AValue) = 1 then
    begin
      Delete(AValue, 1, 2);
      if (Pos(':', AValue) > 0) and (Pos(':', AValue) < Pos('/', AValue))  then
        AHostName := Copy(AValue, 1, Pos(':', AValue) - 1)
      else if Pos('/', AValue) > 0 then
        AHostName := Copy(AValue, 1, Pos('/', AValue) - 1)
      else if Pos('?', AValue) > 0 then
        AHostName := Copy(AValue, 1, Pos('?', AValue) - 1)
      else
        AHostName := AValue;

      Delete(AValue, 1, Length(AHostName));

      // APort
      if Pos(':', AValue) = 1 then
      begin
        Delete(AValue, 1, 1);
        if Pos('/', AValue) > 0 then
          APort := Copy(AValue, 1, Pos('/', AValue) - 1)
        else if Pos('?', AValue) > 0 then
          APort := Copy(AValue, 1, Pos('?', AValue) - 1)
        else
          APort := AValue;

        Delete(AValue, 1, Length(APort));
      end;
    end;

    if Pos('/', AValue) = 1 then
      Delete(AValue, 1, 1);

    // ADatabase
    I := Pos('?', AValue);
    if I > 0 then
    begin
      ADatabase := Copy(AValue, 1, I - 1);
      Delete(AValue, 1, I);
      AProperties.Text := StringReplace(AValue, ';', #13#10, [rfReplaceAll]);
    end
    else
      ADatabase := AValue;

    // AUserName
    AUserName := AProperties.Values['UID'];
    if AUserName = '' then
      AUserName := AProperties.Values['username'];

    // APassword
    APassword := AProperties.Values['PWD'];
    if APassword = '' then
      APassword := AProperties.Values['password'];

    // AProperties
    AProperties.Values['UID'] := '';
    AProperties.Values['PWD'] := '';
    AProperties.Values['username'] := '';
    AProperties.Values['password'] := '';

    FPrefix := APrefix;
    FProtocol := AProtocol;
    FHostName := AHostName;
    FPort := StrToIntDef(APort, 0);
    FDatabase := ADatabase;
    FUserName := AUserName;
    FPassword := APassword;
    FProperties.Text := AProperties.Text;
  finally
    AProperties.Free;
  end;
end;

procedure TZURL.OnPropertiesChange(Sender: TObject);
begin
  FProperties.OnChange := nil;
  try
    if FProperties.Values['UID'] <> '' then
    begin
      UserName := FProperties.Values['UID'];
      FProperties.Values['UID'] := '';
    end;

    if FProperties.Values['PWD'] <> '' then
    begin
      Password := FProperties.Values['PWD'];
      FProperties.Values['PWD'] := '';
    end;

    if FProperties.Values['username'] <> '' then
    begin
      UserName := FProperties.Values['username'];
      FProperties.Values['username'] := '';
    end;

    if FProperties.Values['password'] <> '' then
    begin
      Password := FProperties.Values['password'];
      FProperties.Values['password'] := '';
    end;
  finally
    FProperties.OnChange := OnPropertiesChange;
  end;
end;

end.
