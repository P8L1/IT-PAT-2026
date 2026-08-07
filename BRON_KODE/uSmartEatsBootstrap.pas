unit uSmartEatsBootstrap;

interface

uses
  System.SysUtils;

function KrySmartEatsWortelGids: string;
function KrySmartEatsDataGids: string;
function KrySmartEatsLogGids: string;
function KrySmartEatsWebViewGids: string;
function KrySmartEatsVerslaeGids: string;
function LaaiIngebeddeUi: string;
function VersekerWebView2LaaierBeskikbaar: string;
function VersekerDatabasisBeskikbaar: string;
procedure ValideerDatabasis(const ADatabasisPad: string);
function SmartEatsUiWeergawe: string;
function SmartEatsUiHash: string;
function SmartEatsSeedHash: string;
function SmartEatsSkemaWeergawe: Integer;

implementation

uses
  Winapi.Windows, Winapi.ShlObj, System.Classes, System.Hash,
  System.IOUtils, System.StrUtils, Data.DB, Data.Win.ADODB;

const
  C_UI_HULPBRON = 'SMARTEATS_UI_HTML';
  C_SEED_HULPBRON = 'SMARTEATS_SEED_DB';
  C_WEBVIEW2_HULPBRON = 'SMARTEATS_WEBVIEW2_LOADER';
  C_BOOTSTRAP_MUTEX = 'Local\SmartEats.DatabaseBootstrap.v1';
  C_RUNTIME_MUTEX = 'Local\SmartEats.RuntimeBootstrap.v1';
  C_DATABASIS_NAAM = 'SmartEats.accdb';
  C_WEBVIEW2_LAAIER_NAAM = 'WebView2Loader.dll';

{$I 'resources\SmartEatsAssetsHashes.inc'}

function SmartEatsUiWeergawe: string;
begin
  Result := C_SMARTEATS_UI_WEERGAWE;
end;

function SmartEatsUiHash: string;
begin
  Result := C_SMARTEATS_UI_SHA256;
end;

function SmartEatsSeedHash: string;
begin
  Result := C_SMARTEATS_SEED_SHA256;
end;

function SmartEatsSkemaWeergawe: Integer;
begin
  Result := C_SMARTEATS_SKEMA_WEERGAWE;
end;

function KryPlaaslikeAppDataGids: string;
var
  buffer: array [0 .. MAX_PATH] of Char;
begin
{$IFDEF DEBUG}
  Result := Trim(GetEnvironmentVariable('SMARTEATS_TEST_ROOT'));
  if Result <> '' then
    Exit(TPath.GetFullPath(Result));
{$ENDIF}
  if Failed(SHGetFolderPath(0, CSIDL_LOCAL_APPDATA, 0, SHGFP_TYPE_CURRENT,
    @buffer[0])) then
    raise Exception.Create
      ('Windows kon nie die plaaslike AppData-gids vir SmartEats bepaal nie.');
  Result := string(PChar(@buffer[0]));
  if Result = '' then
    raise Exception.Create
      ('Windows het ’n leë plaaslike AppData-pad teruggestuur.');
end;

function KrySmartEatsWortelGids: string;
begin
  Result := TPath.Combine(KryPlaaslikeAppDataGids, 'SmartEats');
end;

function VersekerGids(const AGids: string): string;
begin
  if TFile.Exists(AGids) then
    raise Exception.CreateFmt
      ('SmartEats kan nie die gids skep nie omdat ’n lêer reeds by %s bestaan.',
      [AGids]);
  if not TDirectory.Exists(AGids) then
    ForceDirectories(AGids);
  if not TDirectory.Exists(AGids) then
    raise Exception.CreateFmt
      ('SmartEats kon nie die gids skep nie: %s', [AGids]);
  Result := AGids;
end;

function KrySmartEatsDataGids: string;
begin
  Result := VersekerGids(TPath.Combine(KrySmartEatsWortelGids, 'data'));
end;

function KrySmartEatsLogGids: string;
begin
  Result := VersekerGids(TPath.Combine(KrySmartEatsWortelGids, 'logs'));
end;

function KrySmartEatsWebViewGids: string;
begin
  Result := VersekerGids(TPath.Combine(KrySmartEatsWortelGids, 'WebView2'));
end;

function KrySmartEatsRuntimeWin64Gids: string;
begin
  Result := VersekerGids(TPath.Combine(TPath.Combine(
    KrySmartEatsWortelGids, 'runtime'), 'win64'));
end;

function MaakUniekeTydelikePad(const AGids, ABasisnaam: string): string;
var
  gidsId: TGUID;
begin
  CreateGUID(gidsId);
  Result := TPath.Combine(AGids, ABasisnaam + '.' +
    StringReplace(StringReplace(GUIDToString(gidsId), '{', '', []), '}', '', [])
    + '.tmp');
end;

function GidsIsSkryfbaar(const AGids: string): Boolean;
var
  grepe: TBytes;
  stroom: TFileStream;
  tydelik: string;
begin
  tydelik := MaakUniekeTydelikePad(AGids, '.smarteats-skryftoets');
  try
    stroom := TFileStream.Create(tydelik, fmCreate or fmShareExclusive);
    try
      grepe := TEncoding.ASCII.GetBytes('SmartEats');
      stroom.WriteBuffer(grepe[0], Length(grepe));
      if not FlushFileBuffers(stroom.Handle) then
        RaiseLastOSError;
    finally
      stroom.Free;
    end;
    Result := True;
  except
    Result := False;
  end;
  if TFile.Exists(tydelik) then
    TFile.Delete(tydelik);
end;

function KrySmartEatsVerslaeGids: string;
var
  uitvoerGids: string;
begin
  uitvoerGids := ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
{$IFDEF DEBUG}
  if SameText(Trim(GetEnvironmentVariable
    ('SMARTEATS_TEST_FORCE_REPORT_FALLBACK')), '1') then
    Exit(VersekerGids(TPath.Combine(KrySmartEatsWortelGids, 'Verslae')));
{$ENDIF}
  if TDirectory.Exists(uitvoerGids) and GidsIsSkryfbaar(uitvoerGids) then
    Exit(uitvoerGids);
  Result := VersekerGids(TPath.Combine(KrySmartEatsWortelGids, 'Verslae'));
end;

function LeesHulpbronGrepe(const AHulpbronnaam: string): TBytes;
var
  hulpbronnaam: string;
  stroom: TResourceStream;
begin
  hulpbronnaam := AHulpbronnaam;
{$IFDEF DEBUG}
  if SameText(AHulpbronnaam, C_UI_HULPBRON) and
    SameText(Trim(GetEnvironmentVariable('SMARTEATS_TEST_MISSING_UI_RESOURCE')
    ), '1') then
    hulpbronnaam := 'SMARTEATS_UI_HTML_ONTBREEK'
  else if SameText(AHulpbronnaam, C_SEED_HULPBRON) and
    SameText(Trim(GetEnvironmentVariable('SMARTEATS_TEST_MISSING_SEED_RESOURCE')
    ), '1') then
    hulpbronnaam := 'SMARTEATS_SEED_DB_ONTBREEK';
{$ENDIF}
  try
    stroom := TResourceStream.Create(HInstance, hulpbronnaam, RT_RCDATA);
  except
    on E: Exception do
      raise Exception.CreateFmt
        ('Die ingebedde SmartEats-resource %s ontbreek of is ongeldig. %s',
        [hulpbronnaam, E.Message]);
  end;
  try
    if stroom.Size <= 0 then
      raise Exception.CreateFmt('Die ingebedde resource %s is leeg.',
        [hulpbronnaam]);
    SetLength(Result, stroom.Size);
    stroom.Position := 0;
    stroom.ReadBuffer(Result[0], Length(Result));
  finally
    stroom.Free;
  end;
end;

function HashVanGrepe(const AGrepe: TBytes): string;
var
  stroom: TBytesStream;
begin
  stroom := TBytesStream.Create(AGrepe);
  try
    stroom.Position := 0;
    Result := THashSHA2.GetHashString(stroom);
  finally
    stroom.Free;
  end;
end;

procedure VerifieerHash(const AWerklik, AVerwag, ABeskrywing: string);
begin
  if not SameText(AWerklik, AVerwag) then
    raise Exception.CreateFmt
      ('%s se SHA-256-integriteitskontrole het misluk. Verwag %s maar kry %s.',
      [ABeskrywing, AVerwag, AWerklik]);
end;

function LaaiIngebeddeUi: string;
var
  grepe: TBytes;
  verwagteHash: string;
begin
  grepe := LeesHulpbronGrepe(C_UI_HULPBRON);
  verwagteHash := C_SMARTEATS_UI_SHA256;
{$IFDEF DEBUG}
  if SameText(Trim(GetEnvironmentVariable('SMARTEATS_TEST_BAD_UI_HASH')), '1')
  then
    verwagteHash := StringOfChar('0', 64);
{$ENDIF}
  VerifieerHash(HashVanGrepe(grepe), verwagteHash,
    'Die ingebedde SmartEats-UI');
  Result := TEncoding.UTF8.GetString(grepe);
  if not ContainsText(Result, '<!doctype html>') or
    not ContainsText(Result, 'id="smartEatsStyles"') or
    not ContainsText(Result,
      'https://smarteats-ui-package.vercel.app/smarteats-ui.min.css') or
    not ContainsText(Result, 'id="smartEatsScript"') or
    not ContainsText(Result,
      'https://smarteats-ui-package.vercel.app/smarteats-ui.min.js') or
    not ContainsText(Result, 'id="mainContent"') then
    raise Exception.Create
      ('Die ingebedde SmartEats-UI bevat nie die verwagte HTML- en Vercel-bateverwysings nie.');
end;

function VersekerWebView2LaaierBeskikbaar: string;
var
  grepe: TBytes;
  mutex: THandle;
  stroom: TFileStream;
  tydelik: string;
  wagResultaat: DWORD;
begin
  Result := TPath.Combine(KrySmartEatsRuntimeWin64Gids,
    C_WEBVIEW2_LAAIER_NAAM);
  if TDirectory.Exists(Result) then
    raise Exception.CreateFmt
      ('Die WebView2-laaierpad is ’n gids in plaas van ’n lêer: %s',
      [Result]);

  mutex := CreateMutex(nil, False, C_RUNTIME_MUTEX);
  if mutex = 0 then
    RaiseLastOSError;
  try
    wagResultaat := WaitForSingleObject(mutex, 30000);
    if (wagResultaat <> WAIT_OBJECT_0) and
      (wagResultaat <> WAIT_ABANDONED) then
      raise Exception.Create
        ('SmartEats kon nie binne 30 sekondes die runtime-bootstrap-slot verkry nie.');
    try
      if TFile.Exists(Result) and SameText(
        THashSHA2.GetHashStringFromFile(Result),
        C_SMARTEATS_WEBVIEW2_LOADER_SHA256) then
        Exit;

      grepe := LeesHulpbronGrepe(C_WEBVIEW2_HULPBRON);
      VerifieerHash(HashVanGrepe(grepe),
        C_SMARTEATS_WEBVIEW2_LOADER_SHA256,
        'Die ingebedde Microsoft WebView2-laaier');
      tydelik := MaakUniekeTydelikePad(ExtractFilePath(Result),
        C_WEBVIEW2_LAAIER_NAAM);
      try
        stroom := TFileStream.Create(tydelik, fmCreate or fmShareExclusive);
        try
          stroom.WriteBuffer(grepe[0], Length(grepe));
          if not FlushFileBuffers(stroom.Handle) then
            RaiseLastOSError;
        finally
          stroom.Free;
        end;
        if TFile.GetSize(tydelik) <> Length(grepe) then
          raise Exception.Create
            ('Die tydelike WebView2-laaier se grootte stem nie ooreen nie.');
        VerifieerHash(THashSHA2.GetHashStringFromFile(tydelik),
          C_SMARTEATS_WEBVIEW2_LOADER_SHA256,
          'Die onttrekte Microsoft WebView2-laaier');
        if not MoveFileEx(PChar(tydelik), PChar(Result),
          MOVEFILE_REPLACE_EXISTING or MOVEFILE_WRITE_THROUGH) then
          RaiseLastOSError;
        tydelik := '';
      finally
        if (tydelik <> '') and TFile.Exists(tydelik) then
          TFile.Delete(tydelik);
      end;
    finally
      ReleaseMutex(mutex);
    end;
  finally
    CloseHandle(mutex);
  end;
end;

procedure OpenDatabasis(AConnection: TADOConnection;
  const ADatabasisPad: string);
var
  eersteFout: string;

  procedure ProbeerVerskaffer(const AVerskaffer: string);
  begin
    AConnection.Close;
    AConnection.ConnectionString := 'Provider=' + AVerskaffer + ';' +
      'Data Source=' + ADatabasisPad + ';' + 'Persist Security Info=False;';
    AConnection.Open;
  end;

begin
{$IFDEF DEBUG}
  if SameText(Trim(GetEnvironmentVariable('SMARTEATS_TEST_PROVIDER_MISSING')
    ), '1') then
    raise Exception.Create
      ('Toetssimulasie: geen ondersteunde Microsoft ACE-provider is beskikbaar nie.');
{$ENDIF}
  AConnection.LoginPrompt := False;
  AConnection.ConnectionTimeout := 15;
  AConnection.CommandTimeout := 30;
  try
    ProbeerVerskaffer('Microsoft.ACE.OLEDB.16.0');
  except
    on E: Exception do
    begin
      eersteFout := E.Message;
      try
        ProbeerVerskaffer('Microsoft.ACE.OLEDB.12.0');
      except
        on E2: Exception do
          raise Exception.CreateFmt
            ('Die Access-databasis kon nie met ACE 16 of ACE 12 oopmaak nie.' +
            '%sDatabasis: %s%sACE 16: %s%sACE 12: %s',
            [sLineBreak, ADatabasisPad, sLineBreak, eersteFout, sLineBreak,
            E2.Message]);
      end;
    end;
  end;
end;

function TabelBestaan(AConnection: TADOConnection;
  const ATabelnaam: string): Boolean;
var
  name: string;
  tabelle: TStringList;
begin
  Result := False;
  tabelle := TStringList.Create;
  try
    tabelle.CaseSensitive := False;
    AConnection.GetTableNames(tabelle, False);
    for name in tabelle do
      if SameText(name, ATabelnaam) then
        Exit(True);
  finally
    tabelle.Free;
  end;
end;

procedure ValideerNavraag(AConnection: TADOConnection;
  const ASQL, ABeskrywing: string);
var
  qry: TADOQuery;
begin
  qry := TADOQuery.Create(nil);
  try
    qry.Connection := AConnection;
    qry.CursorLocation := clUseClient;
    qry.SQL.Text := ASQL;
    try
      qry.Open;
    except
      on E: Exception do
        raise Exception.CreateFmt('Die databasis se %s is ongeldig: %s',
          [ABeskrywing, E.Message]);
    end;
  finally
    qry.Free;
  end;
end;

procedure ValideerBasisskema(AConnection: TADOConnection);
const
  tabelle: array [0 .. 3] of string = ('tblKliente', 'tblSpyskaart',
    'tblBestellings', 'tblBestellyne');
var
  tabel: string;
begin
  for tabel in tabelle do
    if not TabelBestaan(AConnection, tabel) then
      raise Exception.CreateFmt
        ('Die vereiste databasistabel %s ontbreek.', [tabel]);
  ValideerNavraag(AConnection,
    'SELECT TOP 1 KlientID, Naam, Selfoon, Epos, Lojaliteitspunte, Aktief ' +
    'FROM tblKliente', 'tblKliente-velde');
  ValideerNavraag(AConnection,
    'SELECT TOP 1 ItemID, ItemNaam, Kategorie, Prys, Voorraad, ' +
    'Herbestelvlak, Beskikbaar FROM tblSpyskaart', 'tblSpyskaart-velde');
  ValideerNavraag(AConnection,
    'SELECT TOP 1 BestellingID, KlientID, DatumTyd, Besteltipe, ' +
    'TafelNommer, Subtotaal, BTW, Totaal, Status FROM tblBestellings',
    'tblBestellings-velde');
  ValideerNavraag(AConnection,
    'SELECT TOP 1 BestellynID, BestellingID, ItemID, Hoeveelheid, ' +
    'Eenheidsprys FROM tblBestellyne', 'tblBestellyne-velde');
end;

function LeesSkemaWeergawe(AConnection: TADOConnection): Integer;
var
  qry: TADOQuery;
begin
  if not TabelBestaan(AConnection, 'tblMetadata') then
    Exit(0);
  qry := TADOQuery.Create(nil);
  try
    qry.Connection := AConnection;
    qry.SQL.Text := 'SELECT Waarde FROM tblMetadata WHERE Sleutel = :Sleutel';
    qry.Parameters.ParamByName('Sleutel').Value := 'SkemaWeergawe';
    try
      qry.Open;
    except
      on E: Exception do
        raise Exception.CreateFmt('tblMetadata se velde is ongeldig: %s',
          [E.Message]);
    end;
    if qry.IsEmpty or not TryStrToInt(Trim(qry.Fields[0].AsString), Result) then
      raise Exception.Create
        ('tblMetadata bevat nie ’n geldige SkemaWeergawe nie.');
  finally
    qry.Free;
  end;
end;

function SkepMigrasieRugsteun(const ADatabasisPad: string): string;
var
  gids: string;
begin
  gids := VersekerGids(TPath.Combine(KrySmartEatsWortelGids, 'Rugsteun'));
  Result := TPath.Combine(gids, 'SmartEats-voor-migrasie-' +
    FormatDateTime('yyyymmdd-hhnnss-zzz', Now) + '.accdb');
  TFile.Copy(ADatabasisPad, Result, False);
end;

procedure MigreerSkema0Na1(const ADatabasisPad: string);
var
  verbinding: TADOConnection;
  foutBoodskap: string;
  qry: TADOQuery;
  rugsteunPad: string;
  transaksieAktief: Boolean;
begin
  rugsteunPad := SkepMigrasieRugsteun(ADatabasisPad);
  verbinding := TADOConnection.Create(nil);
  qry := TADOQuery.Create(nil);
  transaksieAktief := False;
  try
    try
      OpenDatabasis(verbinding, ADatabasisPad);
      qry.Connection := verbinding;
      verbinding.BeginTrans;
      transaksieAktief := True;
      qry.SQL.Text := 'CREATE TABLE tblMetadata (' +
        'Sleutel VARCHAR(50) CONSTRAINT PK_tblMetadata PRIMARY KEY, ' +
        'Waarde VARCHAR(255) NOT NULL)';
      qry.ExecSQL;
      qry.SQL.Text := 'INSERT INTO tblMetadata (Sleutel, Waarde) ' +
        'VALUES (''SkemaWeergawe'', ''1'')';
      qry.ExecSQL;
      qry.SQL.Text := 'INSERT INTO tblMetadata (Sleutel, Waarde) ' +
        'VALUES (''RestaurantNaam'', ''SmartEats Sentrum'')';
      qry.ExecSQL;
      qry.SQL.Text := 'INSERT INTO tblMetadata (Sleutel, Waarde) ' +
        'VALUES (''BTWKoers'', ''0.15'')';
      qry.ExecSQL;
      verbinding.CommitTrans;
      transaksieAktief := False;
    except
      on E: Exception do
      begin
        foutBoodskap := E.Message;
        if transaksieAktief and verbinding.InTransaction then
          verbinding.RollbackTrans;
        if verbinding.Connected then
          verbinding.Close;
        TFile.Copy(rugsteunPad, ADatabasisPad, True);
        raise Exception.CreateFmt
          ('Databasismigrasie 0 na 1 het misluk en die rugsteun is herstel. %s',
          [foutBoodskap]);
      end;
    end;
  finally
    qry.Free;
    verbinding.Free;
  end;
end;

procedure ValideerDatabasis(const ADatabasisPad: string);
var
  verbinding: TADOConnection;
  weergawe: Integer;
begin
  if TDirectory.Exists(ADatabasisPad) then
    raise Exception.CreateFmt
      ('Die databasisligging is ’n gids in plaas van ’n lêer: %s',
      [ADatabasisPad]);
  if not TFile.Exists(ADatabasisPad) then
    raise Exception.CreateFmt('Die databasis ontbreek: %s', [ADatabasisPad]);
  if TFile.GetSize(ADatabasisPad) <= 0 then
    raise Exception.CreateFmt('Die bestaande databasis is nul grepe: %s',
      [ADatabasisPad]);

  verbinding := TADOConnection.Create(nil);
  try
    OpenDatabasis(verbinding, ADatabasisPad);
    ValideerBasisskema(verbinding);
    weergawe := LeesSkemaWeergawe(verbinding);
  finally
    verbinding.Free;
  end;

  if weergawe = 0 then
  begin
    MigreerSkema0Na1(ADatabasisPad);
    ValideerDatabasis(ADatabasisPad);
    Exit;
  end;
  if weergawe <> C_SMARTEATS_SKEMA_WEERGAWE then
    raise Exception.CreateFmt
      ('Die databasis gebruik skemaweergawe %d; hierdie toepassing vereis %d. '
      + 'Geen data is vervang nie.', [weergawe, C_SMARTEATS_SKEMA_WEERGAWE]);

  verbinding := TADOConnection.Create(nil);
  try
    OpenDatabasis(verbinding, ADatabasisPad);
    ValideerNavraag(verbinding, 'SELECT TOP 1 Sleutel, Waarde FROM tblMetadata',
      'tblMetadata-velde');
    ValideerNavraag(verbinding,
      'SELECT Waarde FROM tblMetadata WHERE Sleutel IN ' +
      '(''RestaurantNaam'', ''BTWKoers'')', 'toepassinginstellings');
  finally
    verbinding.Free;
  end;
end;

procedure SkryfSeedAtomies(const ADatabasisPad: string);
var
  grepe: TBytes;
  stroom: TFileStream;
  tydelik: string;
  verwagteHash: string;
begin
  grepe := LeesHulpbronGrepe(C_SEED_HULPBRON);
  verwagteHash := C_SMARTEATS_SEED_SHA256;
{$IFDEF DEBUG}
  if SameText(Trim(GetEnvironmentVariable('SMARTEATS_TEST_BAD_SEED_HASH')), '1')
  then
    verwagteHash := StringOfChar('0', 64);
  if SameText(Trim(GetEnvironmentVariable('SMARTEATS_TEST_NO_SPACE')), '1') then
    raise EInOutError.Create
      ('Toetssimulasie: onvoldoende skyfspasie vir die seeddatabasis.');
{$ENDIF}
  VerifieerHash(HashVanGrepe(grepe), verwagteHash,
    'Die ingebedde SmartEats-seeddatabasis');
  tydelik := MaakUniekeTydelikePad(ExtractFilePath(ADatabasisPad),
    C_DATABASIS_NAAM);
  try
    stroom := TFileStream.Create(tydelik, fmCreate or fmShareExclusive);
    try
      stroom.WriteBuffer(grepe[0], Length(grepe));
      if not FlushFileBuffers(stroom.Handle) then
        RaiseLastOSError;
    finally
      stroom.Free;
    end;
{$IFDEF DEBUG}
    if SameText
      (Trim(GetEnvironmentVariable('SMARTEATS_TEST_INTERRUPT_AFTER_TEMP_WRITE')
      ), '1') then
      raise EInOutError.Create
        ('Toetssimulasie: onttrekking is ná die tydelike skryf onderbreek.');
{$ENDIF}
    if TFile.GetSize(tydelik) <> Length(grepe) then
      raise Exception.Create
        ('Die tydelike seeddatabasis se grootte stem nie ooreen nie.');
    VerifieerHash(THashSHA2.GetHashStringFromFile(tydelik), verwagteHash,
      'Die onttrekte SmartEats-seeddatabasis');
    if TFile.Exists(ADatabasisPad) then
      Exit;
    // Eers na grootte- en hashverifikasie word die tydelike seed atomies na die
    // finale naam geskuif; 'n bestaande gebruiker-databasis word nooit vervang nie.
    if not MoveFileEx(PChar(tydelik), PChar(ADatabasisPad),
      MOVEFILE_WRITE_THROUGH) then
      RaiseLastOSError;
    tydelik := '';
  finally
    if (tydelik <> '') and TFile.Exists(tydelik) then
      TFile.Delete(tydelik);
  end;
end;

function VersekerDatabasisBeskikbaar: string;
var
  mutex: THandle;
  nuutGeskep: Boolean;
  wagResultaat: DWORD;
begin
  Result := TPath.Combine(KrySmartEatsDataGids, C_DATABASIS_NAAM);
  // Die benoemde mutex keer dat twee gelyktydige eerste lopies dieselfde seed
  // probeer onttrek of migreer.
  mutex := CreateMutex(nil, False, C_BOOTSTRAP_MUTEX);
  if mutex = 0 then
    RaiseLastOSError;
  try
    wagResultaat := WaitForSingleObject(mutex, 30000);
    if (wagResultaat <> WAIT_OBJECT_0) and (wagResultaat <> WAIT_ABANDONED) then
      raise Exception.Create
        ('SmartEats kon nie binne 30 sekondes die databasis-bootstrap-slot verkry nie.');
    try
      nuutGeskep := not TFile.Exists(Result);
      if nuutGeskep then
        SkryfSeedAtomies(Result);
      try
        ValideerDatabasis(Result);
      except
        if nuutGeskep and TFile.Exists(Result) then
          TFile.Delete(Result);
        raise;
      end;
    finally
      ReleaseMutex(mutex);
    end;
  finally
    CloseHandle(mutex);
  end;
end;

end.
