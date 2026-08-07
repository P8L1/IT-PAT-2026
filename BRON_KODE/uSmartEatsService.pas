unit uSmartEatsService;

interface

uses
  System.SysUtils, System.Classes, System.JSON;

type
  ESmartEatsFout = class(Exception)
  private
    FKode: string;
    FVeld: string;
  public
    constructor Create(const AKode, ABoodskap: string;
      const AVeld: string = '');
    property Kode: string read FKode;
    property Veld: string read FVeld;
  end;

  TSmartEatsService = class
  private type
    TBestellynInvoer = record
      ItemID: Integer;
      Hoeveelheid: Integer;
      ItemNaam: string;
      Prys: Currency;
      Voorraad: Integer;
    end;

    TVerslagItem = record
      ItemNaam: string;
      Aantal: Integer;
      Omset: Currency;
    end;
  private
    function FormateerAfrikaanseDatum(const ADatum: TDateTime): string;
    function LeesDatum(const AWaarde, AVeld: string): TDateTime;
    function LeesBool(AObjek: TJSONObject; const ANaam: string;
      AVerstek: Boolean): Boolean;
    function LeesGeld(AObjek: TJSONObject; const ANaam: string): Currency;
    function LeesHeelgetal(AObjek: TJSONObject; const ANaam: string;
      AMinimum, AMaksimum: Integer): Integer;
    function LeesString(AObjek: TJSONObject; const ANaam: string;
      AMaksimum: Integer; AVerplig: Boolean = True): string;
    procedure GooiDatabasisFout(const AKonteks: string; E: Exception);
    function IsGeldigeEpos(const AEpos: string): Boolean;
    function IsGeldigeSelfoon(const ASelfoon: string): Boolean;
    function KryPayload(AWortel: TJSONObject): TJSONObject;
    function SpyskaartSorteerSQL(const ASorteer: string): string;
    function GeskiedenisSorteerSQL(const ASorteer: string): string;
    function SkepDashboard: TJSONObject;
    function SkepSpyskaart(const ASoek, ASorteer: string): TJSONArray;
    function SkepKliente: TJSONArray;
    function SkepBestelitems: TJSONArray;
    function SkepGeskiedenis(const ASoek, ASorteer: string): TJSONArray;
    function VoegSpyskaartitemBy(APayload: TJSONObject): TJSONObject;
    function WysigSpyskaartitem(APayload: TJSONObject): TJSONObject;
    function VerwyderSpyskaartitem(APayload: TJSONObject): TJSONObject;
    function VoegKlientBy(APayload: TJSONObject): TJSONObject;
    function StoorBestelling(APayload: TJSONObject): TJSONObject;
    function VerwyderBestelling(APayload: TJSONObject): TJSONObject;
    function GenereerDagverslag(APayload: TJSONObject): TJSONObject;
    procedure SkryfKwitansie(ABestellingID: Integer; AKlientID: Integer;
      const ABesteltipe: string; ATafel: Integer;
      const ALyne: TArray<TBestellynInvoer>;
      ASubtotaal, ABTW, ATotaal: Currency; out ALêernaam: string);
  public
    function VoerAksieUit(const AAksie: string; AWortel: TJSONObject)
      : TJSONObject;
  end;

implementation

uses
  System.DateUtils, System.Generics.Collections, System.IOUtils,
  System.Math, System.StrUtils, System.Variants, Data.DB, Data.Win.ADODB,
  uDataModule;

constructor ESmartEatsFout.Create(const AKode, ABoodskap, AVeld: string);
begin
  inherited Create(ABoodskap);
  FKode := AKode;
  FVeld := AVeld;
end;

function TSmartEatsService.FormateerAfrikaanseDatum(const ADatum
  : TDateTime): string;
const
  DAE: array [1 .. 7] of string = ('Sondag', 'Maandag', 'Dinsdag', 'Woensdag',
    'Donderdag', 'Vrydag', 'Saterdag');
  MAANDE: array [1 .. 12] of string = ('Januarie', 'Februarie', 'Maart',
    'April', 'Mei', 'Junie', 'Julie', 'Augustus', 'September', 'Oktober',
    'November', 'Desember');
var
  iDag: Word;
  iJaar: Word;
  iMaand: Word;
begin
  DecodeDate(ADatum, iJaar, iMaand, iDag);
  Result := Format('%s, %d %s %d', [DAE[DayOfWeek(ADatum)], iDag,
    MAANDE[iMaand], iJaar]);
end;

function TSmartEatsService.LeesDatum(const AWaarde, AVeld: string): TDateTime;
var
  iDag: Integer;
  iJaar: Integer;
  iMaand: Integer;
begin
  if (Length(AWaarde) <> 10) or (AWaarde[5] <> '-') or (AWaarde[8] <> '-') or
    (not TryStrToInt(Copy(AWaarde, 1, 4), iJaar)) or
    (not TryStrToInt(Copy(AWaarde, 6, 2), iMaand)) or
    (not TryStrToInt(Copy(AWaarde, 9, 2), iDag)) or
    (not TryEncodeDate(iJaar, iMaand, iDag, Result)) then
    raise ESmartEatsFout.Create('ONGELDIGE_DATUM',
      'Kies ’n geldige verslagdatum.', AVeld);
end;

function TSmartEatsService.LeesBool(AObjek: TJSONObject; const ANaam: string;
  AVerstek: Boolean): Boolean;
var
  waarde: TJSONValue;
begin
  waarde := AObjek.GetValue(ANaam);
  if waarde = nil then
    Exit(AVerstek);
  if not(waarde is TJSONBool) then
    raise ESmartEatsFout.Create('ONGELDIGE_PAYLOAD',
      Format('%s moet ’n waar-of-onwaar-waarde wees.', [ANaam]), ANaam);
  Result := TJSONBool(waarde).AsBoolean;
end;

function TSmartEatsService.LeesGeld(AObjek: TJSONObject; const ANaam: string)
  : Currency;
var
  waarde: TJSONValue;
begin
  waarde := AObjek.GetValue(ANaam);
  if not(waarde is TJSONNumber) then
    raise ESmartEatsFout.Create('ONGELDIGE_PAYLOAD',
      Format('%s moet ’n geldige bedrag wees.', [ANaam]), ANaam);
  Result := TJSONNumber(waarde).AsDouble;
end;

function TSmartEatsService.LeesHeelgetal(AObjek: TJSONObject;
  const ANaam: string; AMinimum, AMaksimum: Integer): Integer;
var
  dWaarde: Double;
  waarde: TJSONValue;
begin
  waarde := AObjek.GetValue(ANaam);
  if not(waarde is TJSONNumber) then
    raise ESmartEatsFout.Create('ONGELDIGE_PAYLOAD',
      Format('%s moet ’n heelgetal wees.', [ANaam]), ANaam);
  dWaarde := TJSONNumber(waarde).AsDouble;
  if (Frac(dWaarde) <> 0) or (dWaarde < AMinimum) or (dWaarde > AMaksimum) then
    raise ESmartEatsFout.Create('ONGELDIGE_REEKS',
      Format('%s moet tussen %d en %d wees.', [ANaam, AMinimum,
      AMaksimum]), ANaam);
  Result := Trunc(dWaarde);
end;

function TSmartEatsService.LeesString(AObjek: TJSONObject; const ANaam: string;
  AMaksimum: Integer; AVerplig: Boolean): string;
var
  waarde: TJSONValue;
begin
  waarde := AObjek.GetValue(ANaam);
  if waarde = nil then
  begin
    if AVerplig then
      raise ESmartEatsFout.Create('VERPLIGTE_VELD',
        Format('Vul %s in.', [ANaam]), ANaam);
    Exit('');
  end;
  if not(waarde is TJSONString) then
    raise ESmartEatsFout.Create('ONGELDIGE_PAYLOAD',
      Format('%s moet teks wees.', [ANaam]), ANaam);
  Result := Trim(TJSONString(waarde).Value);
  if AVerplig and (Result = '') then
    raise ESmartEatsFout.Create('VERPLIGTE_VELD',
      Format('Vul %s in.', [ANaam]), ANaam);
  if Length(Result) > AMaksimum then
    raise ESmartEatsFout.Create('TE_LANK',
      Format('%s mag hoogstens %d karakters bevat.', [ANaam, AMaksimum]
      ), ANaam);
end;

procedure TSmartEatsService.GooiDatabasisFout(const AKonteks: string;
  E: Exception);
begin
  if ContainsText(E.Message, 'duplicate') or
    ContainsText(E.Message, 'duplikaat') or ContainsText(E.Message, 'unique')
  then
    raise ESmartEatsFout.Create('DUPLIKAAT',
      'Daardie unieke waarde bestaan reeds. Gebruik ’n ander waarde.')
  else if ContainsText(E.Message, 'reference') or
    ContainsText(E.Message, 'verwante') or
    ContainsText(E.Message, 'related record') then
    raise ESmartEatsFout.Create('VERWANTE_DATA',
      'Die rekord kan nie verander word nie omdat verwante data bestaan.')
  else if ContainsText(E.Message, 'lock') or ContainsText(E.Message, 'gesluit')
  then
    raise ESmartEatsFout.Create('DATABASIS_GESLUIT',
      'Die databasis is tans besig. Wag ’n oomblik en probeer weer.')
  else
    raise ESmartEatsFout.Create('DATABASIS_FOUT',
      Format('Die databasis kon nie %s nie. Geen onvolledige verandering is aanvaar nie.',
      [AKonteks]));
end;

function TSmartEatsService.IsGeldigeEpos(const AEpos: string): Boolean;
var
  iAt: Integer;
  iPunt: Integer;
begin
  if AEpos = '' then
    Exit(True);
  iAt := Pos('@', AEpos);
  iPunt := LastDelimiter('.', AEpos);
  Result := (iAt > 1) and (iPunt > iAt + 1) and (iPunt < Length(AEpos)) and
    (Pos(' ', AEpos) = 0);
end;

function TSmartEatsService.IsGeldigeSelfoon(const ASelfoon: string): Boolean;
var
  i: Integer;
begin
  Result := (Length(ASelfoon) = 10) and (ASelfoon[1] = '0') and
    CharInSet(ASelfoon[2], ['6', '7', '8']);
  if not Result then
    Exit;
  for i := 1 to Length(ASelfoon) do
    if not CharInSet(ASelfoon[i], ['0' .. '9']) then
      Exit(False);
end;

function TSmartEatsService.KryPayload(AWortel: TJSONObject): TJSONObject;
var
  waarde: TJSONValue;
begin
  waarde := AWortel.GetValue('payload');
  if not(waarde is TJSONObject) then
    raise ESmartEatsFout.Create('ONGELDIGE_PAYLOAD',
      'Die versoek se payload moet ’n JSON-objek wees.');
  Result := TJSONObject(waarde);
end;

function TSmartEatsService.SpyskaartSorteerSQL(const ASorteer: string): string;
begin
  if ASorteer = 'category' then
    Result := 'Kategorie ASC, ItemNaam ASC'
  else if ASorteer = 'priceAsc' then
    Result := 'Prys ASC, ItemNaam ASC'
  else if ASorteer = 'priceDesc' then
    Result := 'Prys DESC, ItemNaam ASC'
  else if ASorteer = 'stockAsc' then
    Result := 'Voorraad ASC, ItemNaam ASC'
  else
    Result := 'ItemNaam ASC';
end;

function TSmartEatsService.GeskiedenisSorteerSQL(const ASorteer
  : string): string;
begin
  if ASorteer = 'oldest' then
    Result := 'b.DatumTyd ASC'
  else if ASorteer = 'totalDesc' then
    Result := 'b.Totaal DESC, b.DatumTyd DESC'
  else if ASorteer = 'customer' then
    Result := 'k.Naam ASC, b.DatumTyd DESC'
  else
    Result := 'b.DatumTyd DESC';
end;

function TSmartEatsService.SkepDashboard: TJSONObject;
var
  dagBegin: TDateTime;
  dagEinde: TDateTime;
  bestellingsVandag: Integer;
  omsetVandag: Currency;
  items: TJSONArray;
  qry: TADOQuery;
  qryStatistiek: TADOQuery;
begin
  dagBegin := Trunc(Now);
  dagEinde := dagBegin + 1;
  omsetVandag := 0;
  qryStatistiek := dmData.SkepNavraag(nil);
  try
    qryStatistiek.SQL.Text :=
      'SELECT COUNT(*) AS AantalBestellings, SUM(Totaal) AS TotaleOmset ' +
      'FROM tblBestellings WHERE DatumTyd >= :BeginDatum ' +
      'AND DatumTyd < :EindDatum';
    qryStatistiek.Parameters.ParamByName('BeginDatum').DataType := ftDateTime;
    qryStatistiek.Parameters.ParamByName('BeginDatum').Value := dagBegin;
    qryStatistiek.Parameters.ParamByName('EindDatum').DataType := ftDateTime;
    qryStatistiek.Parameters.ParamByName('EindDatum').Value := dagEinde;
    qryStatistiek.Open;
    bestellingsVandag := qryStatistiek.FieldByName('AantalBestellings')
      .AsInteger;
    if not qryStatistiek.FieldByName('TotaleOmset').IsNull then
      omsetVandag := qryStatistiek.FieldByName('TotaleOmset').AsCurrency;
  finally
    qryStatistiek.Free;
  end;

  Result := TJSONObject.Create;
  items := TJSONArray.Create;
  Result.AddPair('dateIso', FormatDateTime('yyyy-mm-dd', dagBegin));
  Result.AddPair('dateDisplay', FormateerAfrikaanseDatum(dagBegin));
  Result.AddPair('ordersToday', TJSONNumber.Create(bestellingsVandag));
  Result.AddPair('revenueToday', TJSONNumber.Create(Double(omsetVandag)));
  Result.AddPair('lowStockCount',
    TJSONNumber.Create(dmData.LeesHeelgetal('SELECT COUNT(*) FROM tblSpyskaart '
    + 'WHERE Voorraad <= Herbestelvlak AND Beskikbaar = True')));
  Result.AddPair('lowStockItems', items);

  qry := dmData.SkepNavraag(nil);
  try
    qry.SQL.Text :=
      'SELECT TOP 4 ItemID, ItemNaam, Kategorie, Voorraad, Herbestelvlak ' +
      'FROM tblSpyskaart WHERE Voorraad <= Herbestelvlak ' +
      'AND Beskikbaar = True ORDER BY Voorraad ASC, ItemNaam ASC';
    qry.Open;
    while not qry.Eof do
    begin
      items.AddElement(TJSONObject.Create.AddPair('id',
        TJSONNumber.Create(qry.FieldByName('ItemID').AsInteger)).AddPair('name',
        qry.FieldByName('ItemNaam').AsString).AddPair('category',
        qry.FieldByName('Kategorie').AsString).AddPair('stock',
        TJSONNumber.Create(qry.FieldByName('Voorraad').AsInteger))
        .AddPair('reorderLevel',
        TJSONNumber.Create(qry.FieldByName('Herbestelvlak').AsInteger)));
      qry.Next;
    end;
  finally
    qry.Free;
  end;
end;

function TSmartEatsService.SkepSpyskaart(const ASoek, ASorteer: string)
  : TJSONArray;
var
  qry: TADOQuery;
begin
  Result := TJSONArray.Create;
  qry := dmData.SkepNavraag(nil);
  try
    qry.SQL.Text := 'SELECT ItemID, ItemNaam, Kategorie, Prys, Voorraad, ' +
      'Herbestelvlak, Beskikbaar FROM tblSpyskaart ' +
      'WHERE ItemNaam LIKE :Soek OR Kategorie LIKE :Soek ' + 'ORDER BY ' +
      SpyskaartSorteerSQL(ASorteer);
    qry.Parameters.ParamByName('Soek').Value := '%' + Trim(ASoek) + '%';
    qry.Open;
    while not qry.Eof do
    begin
      Result.AddElement(TJSONObject.Create.AddPair('id',
        TJSONNumber.Create(qry.FieldByName('ItemID').AsInteger)).AddPair('name',
        qry.FieldByName('ItemNaam').AsString).AddPair('category',
        qry.FieldByName('Kategorie').AsString).AddPair('price',
        TJSONNumber.Create(Double(qry.FieldByName('Prys').AsCurrency)))
        .AddPair('stock', TJSONNumber.Create(qry.FieldByName('Voorraad')
        .AsInteger)).AddPair('reorderLevel',
        TJSONNumber.Create(qry.FieldByName('Herbestelvlak').AsInteger))
        .AddPair('available', TJSONBool.Create(qry.FieldByName('Beskikbaar')
        .AsBoolean)));
      qry.Next;
    end;
  finally
    qry.Free;
  end;
end;

function TSmartEatsService.SkepKliente: TJSONArray;
var
  qry: TADOQuery;
begin
  Result := TJSONArray.Create;
  qry := dmData.SkepNavraag(nil);
  try
    qry.SQL.Text :=
      'SELECT KlientID, Naam, Selfoon, Epos, Lojaliteitspunte, Aktief ' +
      'FROM tblKliente WHERE Aktief = True ORDER BY Naam';
    qry.Open;
    while not qry.Eof do
    begin
      Result.AddElement(TJSONObject.Create.AddPair('id',
        TJSONNumber.Create(qry.FieldByName('KlientID').AsInteger))
        .AddPair('name', qry.FieldByName('Naam').AsString).AddPair('phone',
        qry.FieldByName('Selfoon').AsString).AddPair('email',
        qry.FieldByName('Epos').AsString).AddPair('loyaltyPoints',
        TJSONNumber.Create(qry.FieldByName('Lojaliteitspunte').AsInteger))
        .AddPair('active', TJSONBool.Create(qry.FieldByName('Aktief')
        .AsBoolean)));
      qry.Next;
    end;
  finally
    qry.Free;
  end;
end;

function TSmartEatsService.SkepBestelitems: TJSONArray;
var
  qry: TADOQuery;
begin
  Result := TJSONArray.Create;
  qry := dmData.SkepNavraag(nil);
  try
    qry.SQL.Text := 'SELECT ItemID, ItemNaam, Kategorie, Prys, Voorraad ' +
      'FROM tblSpyskaart WHERE Beskikbaar = True AND Voorraad > 0 ' +
      'ORDER BY Kategorie, ItemNaam';
    qry.Open;
    while not qry.Eof do
    begin
      Result.AddElement(TJSONObject.Create.AddPair('id',
        TJSONNumber.Create(qry.FieldByName('ItemID').AsInteger)).AddPair('name',
        qry.FieldByName('ItemNaam').AsString).AddPair('category',
        qry.FieldByName('Kategorie').AsString).AddPair('price',
        TJSONNumber.Create(Double(qry.FieldByName('Prys').AsCurrency)))
        .AddPair('stock', TJSONNumber.Create(qry.FieldByName('Voorraad')
        .AsInteger)));
      qry.Next;
    end;
  finally
    qry.Free;
  end;
end;

function TSmartEatsService.SkepGeskiedenis(const ASoek, ASorteer: string)
  : TJSONArray;
var
  item: TJSONObject;
  qry: TADOQuery;
begin
  Result := TJSONArray.Create;
  qry := dmData.SkepNavraag(nil);
  try
    qry.SQL.Text := 'SELECT b.BestellingID, b.DatumTyd, b.KlientID, ' +
      'k.Naam AS Klient, b.Besteltipe, b.TafelNommer, ' +
      'b.Subtotaal, b.BTW, b.Totaal, b.Status ' +
      'FROM tblBestellings AS b INNER JOIN tblKliente AS k ' +
      'ON b.KlientID = k.KlientID ' +
      'WHERE k.Naam LIKE :Soek OR b.Status LIKE :Soek ' + 'ORDER BY ' +
      GeskiedenisSorteerSQL(ASorteer);
    qry.Parameters.ParamByName('Soek').Value := '%' + Trim(ASoek) + '%';
    qry.Open;
    while not qry.Eof do
    begin
      item := TJSONObject.Create.AddPair('id',
        TJSONNumber.Create(qry.FieldByName('BestellingID').AsInteger))
        .AddPair('dateTime', FormatDateTime('yyyy-mm-dd hh:nn',
        qry.FieldByName('DatumTyd').AsDateTime)).AddPair('customerId',
        TJSONNumber.Create(qry.FieldByName('KlientID').AsInteger))
        .AddPair('customer', qry.FieldByName('Klient').AsString)
        .AddPair('type', qry.FieldByName('Besteltipe').AsString)
        .AddPair('subtotal',
        TJSONNumber.Create(Double(qry.FieldByName('Subtotaal').AsCurrency)))
        .AddPair('vat', TJSONNumber.Create(Double(qry.FieldByName('BTW')
        .AsCurrency))).AddPair('total',
        TJSONNumber.Create(Double(qry.FieldByName('Totaal').AsCurrency)))
        .AddPair('status', qry.FieldByName('Status').AsString);
      if qry.FieldByName('TafelNommer').IsNull then
        item.AddPair('tableNumber', TJSONNull.Create)
      else
        item.AddPair('tableNumber',
          TJSONNumber.Create(qry.FieldByName('TafelNommer').AsInteger));
      Result.AddElement(item);
      qry.Next;
    end;
  finally
    qry.Free;
  end;
end;

function TSmartEatsService.VoegSpyskaartitemBy(APayload: TJSONObject)
  : TJSONObject;
var
  bBeskikbaar: Boolean;
  dPrys: Currency;
  iHerbestel: Integer;
  iItemID: Integer;
  iVoorraad: Integer;
  qry: TADOQuery;
  sKategorie: string;
  sNaam: string;
begin
  iItemID := 0;
  sNaam := LeesString(APayload, 'name', 60);
  sKategorie := LeesString(APayload, 'category', 30);
  if not MatchText(sKategorie, ['Voorgereg', 'Hoofgereg', 'Nagereg', 'Drankie'])
  then
    raise ESmartEatsFout.Create('ONGELDIGE_KATEGORIE',
      'Kies ’n geldige kategorie uit die lys.', 'category');
  dPrys := LeesGeld(APayload, 'price');
  if (dPrys <= 0) or (dPrys > 1000000) then
    raise ESmartEatsFout.Create('ONGELDIGE_PRYS',
      'Voer ’n geldige prys groter as R0,00 in.', 'price');
  iVoorraad := LeesHeelgetal(APayload, 'stock', 0, 100000);
  iHerbestel := LeesHeelgetal(APayload, 'reorderLevel', 0, 100000);
  bBeskikbaar := LeesBool(APayload, 'available', True);

  qry := dmData.SkepNavraag(nil);
  try
    try
      qry.SQL.Text := 'INSERT INTO tblSpyskaart ' +
        '(ItemNaam, Kategorie, Prys, Voorraad, Herbestelvlak, Beskikbaar) ' +
        'VALUES (:ItemNaam, :Kategorie, :Prys, :Voorraad, ' +
        ':Herbestelvlak, :Beskikbaar)';
      qry.Parameters.ParamByName('ItemNaam').Value := sNaam;
      qry.Parameters.ParamByName('Kategorie').Value := sKategorie;
      qry.Parameters.ParamByName('Prys').Value := dPrys;
      qry.Parameters.ParamByName('Voorraad').Value := iVoorraad;
      qry.Parameters.ParamByName('Herbestelvlak').Value := iHerbestel;
      qry.Parameters.ParamByName('Beskikbaar').Value := bBeskikbaar;
      qry.ExecSQL;
      qry.Close;
      qry.SQL.Text := 'SELECT @@IDENTITY AS NuweID';
      qry.Open;
      iItemID := qry.FieldByName('NuweID').AsInteger;
    except
      on E: ESmartEatsFout do
        raise;
      on E: Exception do
        GooiDatabasisFout('die spyskaartitem byvoeg', E);
    end;
  finally
    qry.Free;
  end;

  Result := TJSONObject.Create.AddPair('itemId', TJSONNumber.Create(iItemID))
    .AddPair('message', 'Nuwe spyskaartitem is suksesvol gestoor.')
    .AddPair('menu', SkepSpyskaart('', 'name')).AddPair('orderItems',
    SkepBestelitems).AddPair('dashboard', SkepDashboard);
end;

function TSmartEatsService.WysigSpyskaartitem(APayload: TJSONObject)
  : TJSONObject;
var
  bBeskikbaar: Boolean;
  dPrys: Currency;
  iHerbestel: Integer;
  iItemID: Integer;
  iRye: Integer;
  iVoorraad: Integer;
  qry: TADOQuery;
  sKategorie: string;
  sNaam: string;
begin
  iItemID := LeesHeelgetal(APayload, 'itemId', 1, MaxInt);
  sNaam := LeesString(APayload, 'name', 60);
  sKategorie := LeesString(APayload, 'category', 30);
  if not MatchText(sKategorie, ['Voorgereg', 'Hoofgereg', 'Nagereg', 'Drankie'])
  then
    raise ESmartEatsFout.Create('ONGELDIGE_KATEGORIE',
      'Kies ’n geldige kategorie uit die lys.', 'category');
  dPrys := LeesGeld(APayload, 'price');
  if (dPrys <= 0) or (dPrys > 1000000) then
    raise ESmartEatsFout.Create('ONGELDIGE_PRYS',
      'Voer ’n geldige prys groter as R0,00 in.', 'price');
  iVoorraad := LeesHeelgetal(APayload, 'stock', 0, 100000);
  iHerbestel := LeesHeelgetal(APayload, 'reorderLevel', 0, 100000);
  bBeskikbaar := LeesBool(APayload, 'available', True);

  qry := dmData.SkepNavraag(nil);
  try
    try
      qry.SQL.Text := 'UPDATE tblSpyskaart SET ItemNaam = :ItemNaam, ' +
        'Kategorie = :Kategorie, Prys = :Prys, Voorraad = :Voorraad, ' +
        'Herbestelvlak = :Herbestelvlak, Beskikbaar = :Beskikbaar ' +
        'WHERE ItemID = :ItemID';
      qry.Parameters.ParamByName('ItemNaam').Value := sNaam;
      qry.Parameters.ParamByName('Kategorie').Value := sKategorie;
      qry.Parameters.ParamByName('Prys').Value := dPrys;
      qry.Parameters.ParamByName('Voorraad').Value := iVoorraad;
      qry.Parameters.ParamByName('Herbestelvlak').Value := iHerbestel;
      qry.Parameters.ParamByName('Beskikbaar').Value := bBeskikbaar;
      qry.Parameters.ParamByName('ItemID').Value := iItemID;
      iRye := qry.ExecSQL;
      if iRye <> 1 then
        raise ESmartEatsFout.Create('ITEM_NIE_GEVIND',
          'Die gekose spyskaartitem bestaan nie meer nie. Herlaai die lys.');
    except
      on E: ESmartEatsFout do
        raise;
      on E: Exception do
        GooiDatabasisFout('die spyskaartitem wysig', E);
    end;
  finally
    qry.Free;
  end;

  Result := TJSONObject.Create.AddPair('itemId', TJSONNumber.Create(iItemID))
    .AddPair('message', 'Die geselekteerde spyskaartitem is opgedateer.')
    .AddPair('menu', SkepSpyskaart('', 'name')).AddPair('orderItems',
    SkepBestelitems).AddPair('dashboard', SkepDashboard);
end;

function TSmartEatsService.VerwyderSpyskaartitem(APayload: TJSONObject)
  : TJSONObject;
var
  iItemID: Integer;
  iRye: Integer;
  qry: TADOQuery;
begin
  if not LeesBool(APayload, 'confirmed', False) then
    raise ESmartEatsFout.Create('BEVESTIGING_VEREIS',
      'Bevestig eers dat die item verwyder moet word.');
  iItemID := LeesHeelgetal(APayload, 'itemId', 1, MaxInt);
  qry := dmData.SkepNavraag(nil);
  try
    try
      qry.SQL.Text := 'DELETE FROM tblSpyskaart WHERE ItemID = :ItemID';
      qry.Parameters.ParamByName('ItemID').Value := iItemID;
      iRye := qry.ExecSQL;
      if iRye <> 1 then
        raise ESmartEatsFout.Create('ITEM_NIE_GEVIND',
          'Die gekose spyskaartitem bestaan nie meer nie. Herlaai die lys.');
    except
      on E: ESmartEatsFout do
        raise;
      on E: Exception do
        GooiDatabasisFout('die spyskaartitem verwyder', E);
    end;
  finally
    qry.Free;
  end;
  Result := TJSONObject.Create.AddPair('itemId', TJSONNumber.Create(iItemID))
    .AddPair('message', 'Spyskaartitem is verwyder.')
    .AddPair('menu', SkepSpyskaart('', 'name')).AddPair('orderItems',
    SkepBestelitems).AddPair('dashboard', SkepDashboard);
end;

function TSmartEatsService.VoegKlientBy(APayload: TJSONObject): TJSONObject;
var
  bAktief: Boolean;
  iKlientID: Integer;
  qry: TADOQuery;
  sEpos: string;
  sNaam: string;
  sSelfoon: string;
begin
  iKlientID := 0;
  sNaam := LeesString(APayload, 'name', 50);
  if Length(sNaam) < 2 then
    raise ESmartEatsFout.Create('NAAM_TE_KORT',
      'Die kliëntnaam moet minstens twee karakters bevat.', 'name');
  sSelfoon := LeesString(APayload, 'phone', 15);
  if not IsGeldigeSelfoon(sSelfoon) then
    raise ESmartEatsFout.Create('ONGELDIGE_SELFOON',
      'Voer ’n geldige Suid-Afrikaanse selfoonnommer met tien syfers in.',
      'phone');
  sEpos := LeesString(APayload, 'email', 100, False);
  if not IsGeldigeEpos(sEpos) then
    raise ESmartEatsFout.Create('ONGELDIGE_EPOS',
      'Voer ’n geldige e-posadres in of laat die veld leeg.', 'email');
  bAktief := LeesBool(APayload, 'active', True);

  qry := dmData.SkepNavraag(nil);
  try
    try
      qry.SQL.Text := 'INSERT INTO tblKliente ' +
        '(Naam, Selfoon, Epos, Lojaliteitspunte, Aktief) ' +
        'VALUES (:Naam, :Selfoon, :Epos, :Punte, :Aktief)';
      qry.Parameters.ParamByName('Naam').Value := sNaam;
      qry.Parameters.ParamByName('Selfoon').Value := sSelfoon;
      if sEpos = '' then
        qry.Parameters.ParamByName('Epos').Value := Null
      else
        qry.Parameters.ParamByName('Epos').Value := sEpos;
      qry.Parameters.ParamByName('Punte').Value := 0;
      qry.Parameters.ParamByName('Aktief').Value := bAktief;
      qry.ExecSQL;
      qry.Close;
      qry.SQL.Text := 'SELECT @@IDENTITY AS NuweID';
      qry.Open;
      iKlientID := qry.FieldByName('NuweID').AsInteger;
    except
      on E: ESmartEatsFout do
        raise;
      on E: Exception do
      begin
        if ContainsText(E.Message, 'duplicate') or
          ContainsText(E.Message, 'unique') then
          raise ESmartEatsFout.Create('DUPLIKAAT_SELFOON',
            'Hierdie selfoonnommer bestaan reeds. Gebruik ’n unieke nommer.',
            'phone');
        GooiDatabasisFout('die kliënt byvoeg', E);
      end;
    end;
  finally
    qry.Free;
  end;

  Result := TJSONObject.Create.AddPair('customerId',
    TJSONNumber.Create(iKlientID)).AddPair('message',
    'Kliënt is suksesvol gestoor.').AddPair('customers', SkepKliente);
end;

procedure TSmartEatsService.SkryfKwitansie(ABestellingID, AKlientID: Integer;
  const ABesteltipe: string; ATafel: Integer;
  const ALyne: TArray<TBestellynInvoer>; ASubtotaal, ABTW, ATotaal: Currency;
  out ALêernaam: string);
var
  i: Integer;
  lst: TStringList;
  qry: TADOQuery;
  sKlient: string;
begin
  sKlient := '';
  qry := dmData.SkepNavraag(nil);
  try
    qry.SQL.Text := 'SELECT Naam FROM tblKliente WHERE KlientID = :KlientID';
    qry.Parameters.ParamByName('KlientID').Value := AKlientID;
    qry.Open;
    if not qry.IsEmpty then
      sKlient := qry.FieldByName('Naam').AsString;
  finally
    qry.Free;
  end;

  ForceDirectories(dmData.VerslaePad);
  ALêernaam := TPath.Combine(dmData.VerslaePad, Format('Kwitansie-%d-%s.txt',
    [ABestellingID, FormatDateTime('yyyymmdd-hhnnss', Now)]));
  lst := TStringList.Create;
  try
    lst.Add(dmData.RestaurantNaam);
    lst.Add(Format('KWITANSIE / BESTELLING #%d', [ABestellingID]));
    lst.Add(FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
    lst.Add(StringOfChar('-', 54));
    lst.Add(sKlient);
    lst.Add('Besteltipe: ' + ABesteltipe);
    if SameText(ABesteltipe, 'Eet-in') then
      lst.Add(Format('Tafel: %d', [ATafel]));
    lst.Add(StringOfChar('-', 54));
    for i := 0 to High(ALyne) do
      lst.Add(Format('%-28s %3d x %12s', [ALyne[i].ItemNaam,
        ALyne[i].Hoeveelheid, FormatCurr('R #,##0.00', ALyne[i].Prys)]));
    lst.Add(StringOfChar('-', 54));
    lst.Add(Format('%-36s %16s', ['Subtotaal:', FormatCurr('R #,##0.00',
      ASubtotaal)]));
    lst.Add(Format('%-36s %16s', [Format('BTW (%.0f%%):',
      [dmData.BTWKoers * 100]), FormatCurr('R #,##0.00', ABTW)]));
    lst.Add(Format('%-36s %16s', ['Totaal:', FormatCurr('R #,##0.00',
      ATotaal)]));
    lst.Add('');
    lst.Add('Dankie dat jy SmartEats gekies het.');
    lst.SaveToFile(ALêernaam, TEncoding.UTF8);
  finally
    lst.Free;
  end;
end;

function TSmartEatsService.StoorBestelling(APayload: TJSONObject): TJSONObject;
var
  arrLyne: TJSONArray;
  bKlientGeldig: Boolean;
  bedraeBTW: Currency;
  bedraeSubtotaal: Currency;
  bedraeTotaal: Currency;
  gesien: TDictionary<Integer, Boolean>;
  i: Integer;
  iBestellingID: Integer;
  iKlientID: Integer;
  iRye: Integer;
  iTafel: Integer;
  itemObjek: TJSONObject;
  lyne: TArray<TBestellynInvoer>;
  qry: TADOQuery;
  sBesteltipe: string;
  sKwitansie: string;
  sWaarskuwing: string;
  waarde: TJSONValue;
begin
  iBestellingID := 0;
  bedraeSubtotaal := 0;
  bedraeBTW := 0;
  bedraeTotaal := 0;
  iKlientID := LeesHeelgetal(APayload, 'customerId', 1, MaxInt);
  sBesteltipe := LeesString(APayload, 'orderType', 15);
  if not MatchText(sBesteltipe, ['Eet-in', 'Wegneem']) then
    raise ESmartEatsFout.Create('ONGELDIGE_BESTELTIPE',
      'Kies Eet-in of Wegneem as besteltipe.', 'orderType');
  if sBesteltipe = 'Eet-in' then
    iTafel := LeesHeelgetal(APayload, 'tableNumber', 1, 40)
  else
    iTafel := 0;
  waarde := APayload.GetValue('lines');
  if not(waarde is TJSONArray) then
    raise ESmartEatsFout.Create('ONGELDIGE_PAYLOAD',
      'Die bestelling se items ontbreek.', 'lines');
  arrLyne := TJSONArray(waarde);
  if (arrLyne.Count = 0) or (arrLyne.Count > 100) then
    raise ESmartEatsFout.Create('ONGELDIGE_BESTELLYNE',
      'Kies minstens een en hoogstens 100 spyskaartitems.', 'lines');

  // Die dinamiese skikking hou 'n vaste, gevalideerde momentopname van elke
  // bestellyn voordat enige databasisverandering begin.
  SetLength(lyne, arrLyne.Count);
  gesien := TDictionary<Integer, Boolean>.Create;
  qry := dmData.SkepNavraag(nil);
  try
    try
      qry.SQL.Text := 'SELECT COUNT(*) AS Aantal FROM tblKliente ' +
        'WHERE KlientID = :KlientID AND Aktief = True';
      qry.Parameters.ParamByName('KlientID').Value := iKlientID;
      qry.Open;
      bKlientGeldig := qry.FieldByName('Aantal').AsInteger = 1;
      qry.Close;
      if not bKlientGeldig then
        raise ESmartEatsFout.Create('KLIENT_NIE_GEVIND',
          'Kies ’n aktiewe kliënt uit die lys.', 'customerId');

      for i := 0 to arrLyne.Count - 1 do
      begin
        if not(arrLyne.items[i] is TJSONObject) then
          raise ESmartEatsFout.Create('ONGELDIGE_PAYLOAD',
            'Elke bestellyn moet ’n JSON-objek wees.', 'lines');
        itemObjek := TJSONObject(arrLyne.items[i]);
        lyne[i].ItemID := LeesHeelgetal(itemObjek, 'itemId', 1, MaxInt);
        lyne[i].Hoeveelheid := LeesHeelgetal(itemObjek, 'quantity', 1, 100000);
        if gesien.ContainsKey(lyne[i].ItemID) then
          raise ESmartEatsFout.Create('DUPLIKAAT_BESTELLYN',
            'Dieselfde item mag net een keer in ’n bestelling verskyn.',
            'lines');
        gesien.Add(lyne[i].ItemID, True);
      end;

      // Bestelling, lyne, voorraad en lojaliteit vorm een ondeelbare transaksie.
      // Enige fout rol alles terug sodat geen gedeeltelike bestelling kan oorbly nie.
      dmData.conSmartEats.BeginTrans;
      try
        bedraeSubtotaal := 0;
        // Herlees pryse en voorraad binne die transaksie; die UI se waardes word
        // nooit as die gesaghebbende verkoopsbedrae aanvaar nie.
        for i := 0 to High(lyne) do
        begin
          qry.SQL.Text := 'SELECT ItemNaam, Prys, Voorraad, Beskikbaar ' +
            'FROM tblSpyskaart WHERE ItemID = :ItemID';
          qry.Parameters.ParamByName('ItemID').Value := lyne[i].ItemID;
          qry.Open;
          if qry.IsEmpty then
            raise ESmartEatsFout.Create('ITEM_NIE_GEVIND',
              'Een van die gekose items bestaan nie meer nie. Herlaai die itemlys.',
              'lines');
          lyne[i].ItemNaam := qry.FieldByName('ItemNaam').AsString;
          lyne[i].Prys := qry.FieldByName('Prys').AsCurrency;
          lyne[i].Voorraad := qry.FieldByName('Voorraad').AsInteger;
          if (not qry.FieldByName('Beskikbaar').AsBoolean) or
            (lyne[i].Voorraad < lyne[i].Hoeveelheid) then
            raise ESmartEatsFout.Create('ONVOLDOENDE_VOORRAAD',
              Format('Slegs %d eenhede van %s is beskikbaar.',
              [lyne[i].Voorraad, lyne[i].ItemNaam]), 'lines');
          qry.Close;
          bedraeSubtotaal := bedraeSubtotaal +
            (lyne[i].Prys * lyne[i].Hoeveelheid);
        end;
        bedraeBTW := SimpleRoundTo(bedraeSubtotaal * dmData.BTWKoers, -2);
        bedraeTotaal := bedraeSubtotaal + bedraeBTW;

        qry.SQL.Text := 'INSERT INTO tblBestellings ' +
          '(KlientID, DatumTyd, Besteltipe, TafelNommer, ' +
          'Subtotaal, BTW, Totaal, Status) ' +
          'VALUES (:KlientID, :DatumTyd, :Besteltipe, :TafelNommer, ' +
          ':Subtotaal, :BTW, :Totaal, :Status)';
        qry.Parameters.ParamByName('KlientID').Value := iKlientID;
        qry.Parameters.ParamByName('DatumTyd').DataType := ftDateTime;
        qry.Parameters.ParamByName('DatumTyd').Value := Now;
        qry.Parameters.ParamByName('Besteltipe').Value := sBesteltipe;
        if sBesteltipe = 'Eet-in' then
          qry.Parameters.ParamByName('TafelNommer').Value := iTafel
        else
          qry.Parameters.ParamByName('TafelNommer').Value := Null;
        qry.Parameters.ParamByName('Subtotaal').Value := bedraeSubtotaal;
        qry.Parameters.ParamByName('BTW').Value := bedraeBTW;
        qry.Parameters.ParamByName('Totaal').Value := bedraeTotaal;
        qry.Parameters.ParamByName('Status').Value := 'Ontvang';
        qry.ExecSQL;
        qry.Close;
        qry.SQL.Text := 'SELECT @@IDENTITY AS NuweID';
        qry.Open;
        iBestellingID := qry.FieldByName('NuweID').AsInteger;
        qry.Close;

        for i := 0 to High(lyne) do
        begin
          qry.SQL.Text := 'INSERT INTO tblBestellyne ' +
            '(BestellingID, ItemID, Hoeveelheid, Eenheidsprys) ' +
            'VALUES (:BestellingID, :ItemID, :Hoeveelheid, :Eenheidsprys)';
          qry.Parameters.ParamByName('BestellingID').Value := iBestellingID;
          qry.Parameters.ParamByName('ItemID').Value := lyne[i].ItemID;
          qry.Parameters.ParamByName('Hoeveelheid').Value :=
            lyne[i].Hoeveelheid;
          qry.Parameters.ParamByName('Eenheidsprys').Value := lyne[i].Prys;
          qry.ExecSQL;
          qry.Close;
          qry.SQL.Text :=
            'UPDATE tblSpyskaart SET Voorraad = Voorraad - :Verminder ' +
            'WHERE ItemID = :ItemID AND Beskikbaar = True ' +
            'AND Voorraad >= :Minimum';
          qry.Parameters.ParamByName('Verminder').Value := lyne[i].Hoeveelheid;
          qry.Parameters.ParamByName('ItemID').Value := lyne[i].ItemID;
          qry.Parameters.ParamByName('Minimum').Value := lyne[i].Hoeveelheid;
          iRye := qry.ExecSQL;
          if iRye <> 1 then
            raise ESmartEatsFout.Create('ONVOLDOENDE_VOORRAAD',
              Format('Onvoldoende voorraad vir %s. Herlaai en probeer weer.',
              [lyne[i].ItemNaam]), 'lines');
        end;

        qry.Close;
        qry.SQL.Text := 'UPDATE tblKliente SET Lojaliteitspunte = ' +
          'Lojaliteitspunte + :Punte WHERE KlientID = :KlientID';
        qry.Parameters.ParamByName('Punte').Value := Trunc(bedraeTotaal);
        qry.Parameters.ParamByName('KlientID').Value := iKlientID;
        if qry.ExecSQL <> 1 then
          raise ESmartEatsFout.Create('KLIENT_NIE_GEVIND',
            'Die kliënt bestaan nie meer nie. Die bestelling is nie gestoor nie.');
        dmData.conSmartEats.CommitTrans;
      except
        if dmData.conSmartEats.InTransaction then
          dmData.conSmartEats.RollbackTrans;
        raise;
      end;
    except
      on E: ESmartEatsFout do
        raise;
      on E: Exception do
        GooiDatabasisFout('die bestelling stoor', E);
    end;
  finally
    qry.Free;
    gesien.Free;
  end;

  sWaarskuwing := '';
  sKwitansie := '';
  try
    SkryfKwitansie(iBestellingID, iKlientID, sBesteltipe, iTafel, lyne,
      bedraeSubtotaal, bedraeBTW, bedraeTotaal, sKwitansie);
  except
    on E: Exception do
      sWaarskuwing :=
        'Die bestelling is veilig gestoor, maar die tekskwitansie kon nie geskep word nie.';
  end;

  Result := TJSONObject.Create.AddPair('orderId',
    TJSONNumber.Create(iBestellingID)).AddPair('subtotal',
    TJSONNumber.Create(Double(bedraeSubtotaal)))
    .AddPair('vat', TJSONNumber.Create(Double(bedraeBTW)))
    .AddPair('total', TJSONNumber.Create(Double(bedraeTotaal)))
    .AddPair('receiptFile', sKwitansie).AddPair('warning', sWaarskuwing)
    .AddPair('message', Format('Bestelling #%d is suksesvol gestoor.',
    [iBestellingID])).AddPair('dashboard', SkepDashboard)
    .AddPair('menu', SkepSpyskaart('', 'name')).AddPair('orderItems',
    SkepBestelitems).AddPair('customers', SkepKliente)
    .AddPair('history', SkepGeskiedenis('', 'newest'));
end;

function TSmartEatsService.VerwyderBestelling(APayload: TJSONObject)
  : TJSONObject;
var
  dTotaal: Currency;
  iBestellingID: Integer;
  iKlientID: Integer;
  iPunte: Integer;
  qryBestelling: TADOQuery;
  qryLyne: TADOQuery;
  qryWerk: TADOQuery;
begin
  if not LeesBool(APayload, 'confirmed', False) then
    raise ESmartEatsFout.Create('BEVESTIGING_VEREIS',
      'Bevestig eers dat die bestelling verwyder moet word.');
  iBestellingID := LeesHeelgetal(APayload, 'orderId', 1, MaxInt);
  qryBestelling := dmData.SkepNavraag(nil);
  qryLyne := dmData.SkepNavraag(nil);
  qryWerk := dmData.SkepNavraag(nil);
  try
    try
      qryBestelling.SQL.Text := 'SELECT KlientID, Totaal FROM tblBestellings ' +
        'WHERE BestellingID = :BestellingID';
      qryBestelling.Parameters.ParamByName('BestellingID').Value :=
        iBestellingID;
      qryBestelling.Open;
      if qryBestelling.IsEmpty then
        raise ESmartEatsFout.Create('BESTELLING_NIE_GEVIND',
          'Die gekose bestelling bestaan nie meer nie. Herlaai die geskiedenis.');
      iKlientID := qryBestelling.FieldByName('KlientID').AsInteger;
      dTotaal := qryBestelling.FieldByName('Totaal').AsCurrency;
      iPunte := Trunc(dTotaal);

      // Herstel voorraad en punte in dieselfde transaksie waarin die bestelling
      // verwyder word, anders kan 'n mislukking die datastel inkonsekwent laat.
      dmData.conSmartEats.BeginTrans;
      try
        qryLyne.SQL.Text := 'SELECT ItemID, Hoeveelheid FROM tblBestellyne ' +
          'WHERE BestellingID = :BestellingID';
        qryLyne.Parameters.ParamByName('BestellingID').Value := iBestellingID;
        qryLyne.Open;
        while not qryLyne.Eof do
        begin
          qryWerk.Close;
          qryWerk.SQL.Text :=
            'UPDATE tblSpyskaart SET Voorraad = Voorraad + :Aantal ' +
            'WHERE ItemID = :ItemID';
          qryWerk.Parameters.ParamByName('Aantal').Value :=
            qryLyne.FieldByName('Hoeveelheid').AsInteger;
          qryWerk.Parameters.ParamByName('ItemID').Value :=
            qryLyne.FieldByName('ItemID').AsInteger;
          if qryWerk.ExecSQL <> 1 then
            raise ESmartEatsFout.Create('VERWANTE_DATA',
              '’n Verwante spyskaartitem ontbreek. Geen data is verander nie.');
          qryLyne.Next;
        end;
        qryWerk.Close;
        qryWerk.SQL.Text :=
          'DELETE FROM tblBestellyne WHERE BestellingID = :BestellingID';
        qryWerk.Parameters.ParamByName('BestellingID').Value := iBestellingID;
        qryWerk.ExecSQL;
        qryWerk.Close;
        qryWerk.SQL.Text :=
          'DELETE FROM tblBestellings WHERE BestellingID = :BestellingID';
        qryWerk.Parameters.ParamByName('BestellingID').Value := iBestellingID;
        if qryWerk.ExecSQL <> 1 then
          raise ESmartEatsFout.Create('BESTELLING_NIE_GEVIND',
            'Die bestelling bestaan nie meer nie. Geen data is verander nie.');
        qryWerk.Close;
        qryWerk.SQL.Text := 'UPDATE tblKliente SET Lojaliteitspunte = ' +
          'IIf(Lojaliteitspunte >= :MinimumPunte, ' +
          'Lojaliteitspunte - :AftrekPunte, 0) ' + 'WHERE KlientID = :KlientID';
        qryWerk.Parameters.ParamByName('MinimumPunte').Value := iPunte;
        qryWerk.Parameters.ParamByName('AftrekPunte').Value := iPunte;
        qryWerk.Parameters.ParamByName('KlientID').Value := iKlientID;
        if qryWerk.ExecSQL <> 1 then
          raise ESmartEatsFout.Create('KLIENT_NIE_GEVIND',
            'Die verwante kliënt ontbreek. Geen data is verander nie.');
        dmData.conSmartEats.CommitTrans;
      except
        if dmData.conSmartEats.InTransaction then
          dmData.conSmartEats.RollbackTrans;
        raise;
      end;
    except
      on E: ESmartEatsFout do
        raise;
      on E: Exception do
        GooiDatabasisFout('die bestelling verwyder', E);
    end;
  finally
    qryWerk.Free;
    qryLyne.Free;
    qryBestelling.Free;
  end;

  Result := TJSONObject.Create.AddPair('orderId',
    TJSONNumber.Create(iBestellingID)).AddPair('message',
    Format('Bestelling #%d is verwyder en voorraad is herstel.', [iBestellingID]
    )).AddPair('dashboard', SkepDashboard)
    .AddPair('menu', SkepSpyskaart('', 'name')).AddPair('orderItems',
    SkepBestelitems).AddPair('customers', SkepKliente)
    .AddPair('history', SkepGeskiedenis('', 'newest'));
end;

function TSmartEatsService.GenereerDagverslag(APayload: TJSONObject)
  : TJSONObject;
var
  arrItems: TJSONArray;
  datum: TDateTime;
  dTotaleOmset: Currency;
  i: Integer;
  j: Integer;
  items: TArray<TVerslagItem>;
  lst: TStringList;
  qry: TADOQuery;
  sDatum: string;
  sLêernaam: string;
  tydelik: TVerslagItem;
begin
  sDatum := LeesString(APayload, 'date', 10);
  datum := LeesDatum(sDatum, 'date');
  SetLength(items, 0);
  dTotaleOmset := 0;
  qry := dmData.SkepNavraag(nil);
  try
    try
      qry.SQL.Text := 'SELECT s.ItemNaam, SUM(l.Hoeveelheid) AS Aantal, ' +
        'SUM(l.Hoeveelheid * l.Eenheidsprys) AS Omset ' +
        'FROM (tblBestellings AS b INNER JOIN tblBestellyne AS l ' +
        'ON b.BestellingID = l.BestellingID) ' +
        'INNER JOIN tblSpyskaart AS s ON l.ItemID = s.ItemID ' +
        'WHERE b.DatumTyd >= :BeginDatum AND b.DatumTyd < :EindDatum ' +
        'GROUP BY s.ItemNaam';
      qry.Parameters.ParamByName('BeginDatum').DataType := ftDateTime;
      // 'n Half-oop reeks sluit die volle gekose kalenderdag in sonder om presies
      // middernag van die volgende dag per ongeluk saam te tel.
      qry.Parameters.ParamByName('BeginDatum').Value := Trunc(datum);
      qry.Parameters.ParamByName('EindDatum').DataType := ftDateTime;
      qry.Parameters.ParamByName('EindDatum').Value := Trunc(datum) + 1;
      qry.Open;
      while not qry.Eof do
      begin
        i := Length(items);
        SetLength(items, i + 1);
        items[i].ItemNaam := qry.FieldByName('ItemNaam').AsString;
        items[i].Aantal := qry.FieldByName('Aantal').AsInteger;
        items[i].Omset := qry.FieldByName('Omset').AsCurrency;
        dTotaleOmset := dTotaleOmset + items[i].Omset;
        qry.Next;
      end;
    except
      on E: Exception do
        GooiDatabasisFout('die dagverslag genereer', E);
    end;
  finally
    qry.Free;
  end;

  // Die geneste sortering is doelbewus sigbaar vir die PAT-algoritmebewys:
  // meeste verkope eerste, met itemnaam as 'n deterministiese gelykopbreker.
  for i := 0 to High(items) - 1 do
    for j := 0 to High(items) - i - 1 do
      if (items[j].Aantal < items[j + 1].Aantal) or
        ((items[j].Aantal = items[j + 1].Aantal) and
        (CompareText(items[j].ItemNaam, items[j + 1].ItemNaam) > 0)) then
      begin
        tydelik := items[j];
        items[j] := items[j + 1];
        items[j + 1] := tydelik;
      end;

  sLêernaam := '';
  if Length(items) > 0 then
  begin
    ForceDirectories(dmData.VerslaePad);
    sLêernaam := TPath.Combine(dmData.VerslaePad,
      'Dagverslag-' + FormatDateTime('yyyymmdd', datum) + '.txt');
    lst := TStringList.Create;
    try
      lst.Add(dmData.RestaurantNaam);
      lst.Add('DAAGLIKSE VERKOOPSVERSLAG');
      lst.Add(FormateerAfrikaanseDatum(datum));
      lst.Add(StringOfChar('=', 62));
      lst.Add(Format('%-34s %10s %14s', ['Item', 'Aantal', 'Omset']));
      lst.Add(StringOfChar('-', 62));
      for i := 0 to High(items) do
        lst.Add(Format('%-34s %10d %14s', [items[i].ItemNaam, items[i].Aantal,
          FormatCurr('R #,##0.00', items[i].Omset)]));
      lst.Add(StringOfChar('-', 62));
      lst.Add(Format('%-45s %16s', ['Totale itemomset:',
        FormatCurr('R #,##0.00', dTotaleOmset)]));
      lst.Add('');
      lst.Add(Format('Gegenereer: %s',
        [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]));
      lst.SaveToFile(sLêernaam, TEncoding.UTF8);
    finally
      lst.Free;
    end;
  end;

  arrItems := TJSONArray.Create;
  for i := 0 to High(items) do
    arrItems.AddElement(TJSONObject.Create.AddPair('name', items[i].ItemNaam)
      .AddPair('quantity', TJSONNumber.Create(items[i].Aantal))
      .AddPair('revenue', TJSONNumber.Create(Double(items[i].Omset))));
  Result := TJSONObject.Create.AddPair('date', sDatum).AddPair('dateDisplay',
    FormateerAfrikaanseDatum(datum)).AddPair('hasData',
    TJSONBool.Create(Length(items) > 0)).AddPair('items', arrItems)
    .AddPair('totalRevenue', TJSONNumber.Create(Double(dTotaleOmset)))
    .AddPair('fileName', sLêernaam);
  if Length(items) = 0 then
    Result.AddPair('message',
      'Geen bestellings is vir hierdie datum gevind nie.')
  else
    Result.AddPair('message',
      'Dagverslag is gegenereer en as UTF-8-teks geskryf.');
end;

function TSmartEatsService.VoerAksieUit(const AAksie: string;
  AWortel: TJSONObject): TJSONObject;
var
  payload: TJSONObject;
  sSoek: string;
  sSorteer: string;
begin
  payload := KryPayload(AWortel);
  if AAksie = 'app.initialize' then
    Result := TJSONObject.Create.AddPair('restaurantName',
      dmData.RestaurantNaam).AddPair('vatRate',
      TJSONNumber.Create(dmData.BTWKoers)).AddPair('databaseConnected',
      TJSONBool.Create(dmData.conSmartEats.Connected))
      .AddPair('dashboard', SkepDashboard)
      .AddPair('menu', SkepSpyskaart('', 'name')).AddPair('customers',
      SkepKliente).AddPair('orderItems', SkepBestelitems)
      .AddPair('history', SkepGeskiedenis('', 'newest'))
  else if AAksie = 'dashboard.refresh' then
    Result := TJSONObject.Create.AddPair('dashboard', SkepDashboard)
  else if AAksie = 'menu.load' then
  begin
    sSoek := LeesString(payload, 'search', 100, False);
    sSorteer := LeesString(payload, 'sort', 20, False);
    Result := TJSONObject.Create.AddPair('menu',
      SkepSpyskaart(sSoek, sSorteer));
  end
  else if AAksie = 'menu.create' then
    Result := VoegSpyskaartitemBy(payload)
  else if AAksie = 'menu.update' then
    Result := WysigSpyskaartitem(payload)
  else if AAksie = 'menu.confirmDelete' then
    Result := VerwyderSpyskaartitem(payload)
  else if AAksie = 'clients.create' then
    Result := VoegKlientBy(payload)
  else if AAksie = 'orders.load' then
    Result := TJSONObject.Create.AddPair('customers', SkepKliente)
      .AddPair('orderItems', SkepBestelitems)
  else if AAksie = 'orders.create' then
    Result := StoorBestelling(payload)
  else if AAksie = 'history.load' then
  begin
    sSoek := LeesString(payload, 'search', 100, False);
    sSorteer := LeesString(payload, 'sort', 20, False);
    Result := TJSONObject.Create.AddPair('history',
      SkepGeskiedenis(sSoek, sSorteer));
  end
  else if AAksie = 'history.confirmDelete' then
    Result := VerwyderBestelling(payload)
  else if AAksie = 'reports.generateDaily' then
    Result := GenereerDagverslag(payload)
  else
    raise ESmartEatsFout.Create('ONBEKENDE_AKSIE',
      'Hierdie aksie word nie deur SmartEats toegelaat nie.');
end;

end.
