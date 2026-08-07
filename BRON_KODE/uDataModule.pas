unit uDataModule;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, Data.DB, Data.Win.ADODB;

type
  TdmData = class(TDataModule)
    conSmartEats: TADOConnection;
    procedure DataModuleDestroy(Sender: TObject);
  private
    FBTWKoers: Double;
    FDataPad: string;
    FDatabasisPad: string;
    FRestaurantNaam: string;
    FVerslaePad: string;
    procedure BepaalRelatiewePaaie;
    procedure LaaiInstellings;
    procedure OpenMetVerskaffer(const AVerskaffer: string);
  public
    procedure KoppelDatabasis;
    function LeesGeld(const ASQL: string): Currency;
    function LeesHeelgetal(const ASQL: string): Integer;
    function SkepNavraag(AEienaar: TComponent): TADOQuery;
    property BTWKoers: Double read FBTWKoers;
    property DataPad: string read FDataPad;
    property DatabasisPad: string read FDatabasisPad;
    property RestaurantNaam: string read FRestaurantNaam;
    property VerslaePad: string read FVerslaePad;
  end;

var
  dmData: TdmData;

implementation

uses
  uSmartEatsBootstrap;

{%CLASSGROUP 'Vcl.Controls.TControl'}
{$R *.dfm}

procedure TdmData.BepaalRelatiewePaaie;
begin
  FDataPad := KrySmartEatsDataGids;
  FDatabasisPad := VersekerDatabasisBeskikbaar;
  FVerslaePad := KrySmartEatsVerslaeGids;
end;

procedure TdmData.DataModuleDestroy(Sender: TObject);
begin
  if conSmartEats.Connected then
    conSmartEats.Close;
end;

procedure TdmData.KoppelDatabasis;
var
  sEersteFout: string;
begin
  if conSmartEats.Connected then
    Exit;

  BepaalRelatiewePaaie;
  try
    OpenMetVerskaffer('Microsoft.ACE.OLEDB.16.0');
  except
    on E: Exception do
    begin
      sEersteFout := E.Message;
      try
        OpenMetVerskaffer('Microsoft.ACE.OLEDB.12.0');
      except
        on E2: Exception do
          raise Exception.CreateFmt
            ('Die Access-databasis kon nie oopgemaak word nie.%s%s%s' +
            'ACE 16.0: %s%sACE 12.0: %s%s' +
            'Bou en begin die Win64-teiken wanneer 64-bis Microsoft 365 geïnstalleer is.',
            [sLineBreak, FDatabasisPad, sLineBreak, sEersteFout, sLineBreak,
            E2.Message, sLineBreak]);
      end;
    end;
  end;
  LaaiInstellings;
end;

procedure TdmData.LaaiInstellings;
var
  qry: TADOQuery;
  sKoers: string;
begin
  FRestaurantNaam := '';
  sKoers := '';
  qry := SkepNavraag(nil);
  try
    qry.SQL.Text := 'SELECT Sleutel, Waarde FROM tblMetadata ' +
      'WHERE Sleutel IN (''RestaurantNaam'', ''BTWKoers'')';
    qry.Open;
    while not qry.Eof do
    begin
      if SameText(qry.FieldByName('Sleutel').AsString, 'RestaurantNaam') then
        FRestaurantNaam := Trim(qry.FieldByName('Waarde').AsString)
      else if SameText(qry.FieldByName('Sleutel').AsString, 'BTWKoers') then
        sKoers := Trim(qry.FieldByName('Waarde').AsString);
      qry.Next;
    end;

    sKoers := StringReplace(sKoers, '.', FormatSettings.DecimalSeparator,
      [rfReplaceAll]);

    if FRestaurantNaam = '' then
      raise Exception.Create
        ('RestaurantNaam is leeg of ontbreek in tblMetadata.');

    if (not TryStrToFloat(sKoers, FBTWKoers)) or (FBTWKoers < 0) or
      (FBTWKoers > 1) then
      raise Exception.Create
        ('BTWKoers in tblMetadata moet ’n desimale waarde tussen 0 en 1 wees.');
  finally
    qry.Free;
  end;
end;

function TdmData.LeesGeld(const ASQL: string): Currency;
var
  qryLees: TADOQuery;
begin
  Result := 0;
  qryLees := SkepNavraag(nil);
  try
    qryLees.SQL.Text := ASQL;
    qryLees.Open;
    if not qryLees.Fields[0].IsNull then
      Result := qryLees.Fields[0].AsCurrency;
  finally
    qryLees.Free;
  end;
end;

function TdmData.LeesHeelgetal(const ASQL: string): Integer;
var
  qryLees: TADOQuery;
begin
  Result := 0;
  qryLees := SkepNavraag(nil);
  try
    qryLees.SQL.Text := ASQL;
    qryLees.Open;
    if not qryLees.Fields[0].IsNull then
      Result := qryLees.Fields[0].AsInteger;
  finally
    qryLees.Free;
  end;
end;

procedure TdmData.OpenMetVerskaffer(const AVerskaffer: string);
begin
  conSmartEats.Close;
  conSmartEats.ConnectionString := 'Provider=' + AVerskaffer + ';' +
    'Data Source=' + FDatabasisPad + ';' + 'Persist Security Info=False;';
  conSmartEats.Open;
end;

function TdmData.SkepNavraag(AEienaar: TComponent): TADOQuery;
begin
  Result := TADOQuery.Create(AEienaar);
  Result.Connection := conSmartEats;
  Result.CursorLocation := clUseClient;
  // ParamCheck verseker dat benoemde SQL-parameters geskep en deur die dienslaag
  // gevul word, eerder as om gebruiker-invoer in SQL-teks saam te voeg.
  Result.ParamCheck := True;
end;

end.
