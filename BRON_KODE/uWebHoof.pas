unit uWebHoof;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.WebView2, System.SysUtils,
  System.Classes,
  System.JSON, System.Generics.Collections, Vcl.Controls, Vcl.Forms,
  Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Graphics, Vcl.Edge, uSmartEatsService;

type
  TfrmWebHoof = class(TForm)
  private const
    MaksimumVersoekgrepe = 65536;
  private
    FEdge: TEdgeBrowser;
    FDiens: TSmartEatsService;
    FAntwoordKas: TDictionary<string, string>;
    FKasVolgorde: TQueue<string>;
    FLaaiTydhouer: TTimer;
    FNoodpaneel: TPanel;
    FNoodOpskrif: TLabel;
    FNoodBoodskap: TLabel;
    FUiHtml: string;
    FUiUri: string;
    FUiGereed: Boolean;
    FNavigationGeblokkeer: Boolean;
{$IFDEF DEBUG}
    FToetsVaslegging: TTimer;
    FToetsAksie: string;
{$ENDIF}
    procedure ApplyDarkTitleBar;
    function AksieToegelaat(const AAksie: string): Boolean;
    procedure BergAntwoord(const AVersoekID, AAntwoord: string);
    function BouFoutAntwoord(const AVersoekID, AKode, ABoodskap,
      AVeld: string): string;
    function BouSuksesAntwoord(const AVersoekID: string;
      AData: TJSONObject): string;
    procedure PlaasAntwoord(const AJson: string);
    procedure SkryfTegnieseLog(const AKategorie, ABesonderhede: string);
    procedure ToonNoodtoestand(const AOpskrif, ABoodskap: string);
    procedure VerwerkBoodskap(const ABron, AJson: string);
    procedure WanneerEdgeGeskep(Sender: TCustomEdgeBrowser; AResult: HResult);
    procedure WanneerLaaiKlaar(Sender: TCustomEdgeBrowser; IsSuccess: Boolean;
      WebErrorStatus: COREWEBVIEW2_WEB_ERROR_STATUS);
    procedure WanneerLaaiBegin(Sender: TCustomEdgeBrowser;
      Args: TNavigationStartingEventArgs);
    procedure WanneerNuweVenster(Sender: TCustomEdgeBrowser;
      Args: TNewWindowRequestedEventArgs);
    procedure WanneerProsesMisluk(Sender: TCustomEdgeBrowser;
      ProcessFailedKind: COREWEBVIEW2_PROCESS_FAILED_KIND);
    procedure WanneerWebBoodskap(Sender: TCustomEdgeBrowser;
      Args: TWebMessageReceivedEventArgs);
    procedure WanneerWagVerstryk(Sender: TObject);
{$IFDEF DEBUG}
    procedure WanneerToetsVaslegging(Sender: TObject);
{$ENDIF}
    procedure SluitKlik(Sender: TObject);
  protected
    procedure CreateWnd; override;
    procedure DoClose(var Action: TCloseAction); override;
{$IFDEF DEBUG}
    procedure WndProc(var Message: TMessage); override;
{$ENDIF}
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  frmWebHoof: TfrmWebHoof;

implementation

uses
  System.DateUtils, System.IOUtils, System.StrUtils, System.Win.ComObj,
  Winapi.ActiveX,
  Winapi.EdgeUtils, uSmartEatsBootstrap;

constructor TfrmWebHoof.Create(AOwner: TComponent);
var
  knoppie: TButton;
  laaierPad: string;
begin
  inherited CreateNew(AOwner);
  Caption := 'SmartEats Bestellings- en Spyskaartbestuur';
  Icon.Assign(Application.Icon);
  Position := poScreenCenter;
  ShowInTaskBar := True;
  WindowState := wsMaximized;
  Constraints.MinWidth := 960;
  Constraints.MinHeight := 640;
  Color := clBlack;

  FDiens := TSmartEatsService.Create;
  FAntwoordKas := TDictionary<string, string>.Create;
  FKasVolgorde := TQueue<string>.Create;

  FNoodpaneel := TPanel.Create(Self);
  FNoodpaneel.Parent := Self;
  FNoodpaneel.Align := alClient;
  FNoodpaneel.BevelOuter := bvNone;
  FNoodpaneel.Color := $00111111;

  FNoodOpskrif := TLabel.Create(Self);
  FNoodOpskrif.Parent := FNoodpaneel;
  FNoodOpskrif.Left := 56;
  FNoodOpskrif.Top := 64;
  FNoodOpskrif.Font.Name := 'Segoe UI';
  FNoodOpskrif.Font.Size := 24;
  FNoodOpskrif.Font.Color := clWhite;
  FNoodOpskrif.Caption := 'SmartEats word voorberei';

  FNoodBoodskap := TLabel.Create(Self);
  FNoodBoodskap.Parent := FNoodpaneel;
  FNoodBoodskap.Left := 58;
  FNoodBoodskap.Top := 118;
  FNoodBoodskap.Width := 720;
  FNoodBoodskap.AutoSize := False;
  FNoodBoodskap.WordWrap := True;
  FNoodBoodskap.Font.Name := 'Segoe UI';
  FNoodBoodskap.Font.Size := 11;
  FNoodBoodskap.Font.Color := $00C0C0C0;
  FNoodBoodskap.Caption := 'Die plaaslike koppelvlak laai veilig.';

  knoppie := TButton.Create(Self);
  knoppie.Parent := FNoodpaneel;
  knoppie.Left := 58;
  knoppie.Top := 212;
  knoppie.Width := 118;
  knoppie.Height := 38;
  knoppie.Caption := 'Sluit SmartEats';
  knoppie.OnClick := SluitKlik;

  try
    FUiHtml := LaaiIngebeddeUi;
  except
    on E: Exception do
    begin
      ToonNoodtoestand('Ingebedde UI is ongeldig', E.Message + sLineBreak +
        'Herbou SmartEatsAssets.res en daarna die toepassing.');
      Exit;
    end;
  end;
  if FUiHtml = '' then
  begin
    ToonNoodtoestand('Ingebedde UI is leeg',
      'Die EXE bevat nie ’n bruikbare SmartEats-HTML-dokument nie.');
    Exit;
  end;

  try
    laaierPad := VersekerWebView2LaaierBeskikbaar;
  except
    on E: Exception do
    begin
      ToonNoodtoestand('WebView2-laaier kon nie voorberei word nie', E.Message +
        sLineBreak + 'SmartEats kon nie die ingebedde laaier veilig na AppData onttrek nie.');
      Exit;
    end;
  end;
  SetWebView2Path(laaierPad);
  FUiUri := 'about:blank';

  FEdge := TEdgeBrowser.Create(Self);
  FEdge.Parent := Self;
  FEdge.Align := alClient;
  FEdge.UserDataFolder := KrySmartEatsWebViewGids;
  FEdge.OnCreateWebViewCompleted := WanneerEdgeGeskep;
  FEdge.OnNavigationStarting := WanneerLaaiBegin;
  FEdge.OnNavigationCompleted := WanneerLaaiKlaar;
  FEdge.OnNewWindowRequested := WanneerNuweVenster;
  FEdge.OnProcessFailed := WanneerProsesMisluk;
  FEdge.OnWebMessageReceived := WanneerWebBoodskap;

  FLaaiTydhouer := TTimer.Create(Self);
  FLaaiTydhouer.Enabled := False;
  FLaaiTydhouer.Interval := 15000;
  FLaaiTydhouer.OnTimer := WanneerWagVerstryk;
  FLaaiTydhouer.Enabled := True;

{$IFDEF DEBUG}
  FToetsVaslegging := TTimer.Create(Self);
  FToetsVaslegging.Enabled := False;
  FToetsVaslegging.Interval := 500;
  FToetsVaslegging.OnTimer := WanneerToetsVaslegging;
{$ENDIF}
  FEdge.CreateWebView;
end;

destructor TfrmWebHoof.Destroy;
begin
  if Assigned(FEdge) then
    FEdge.CloseWebView;
  FKasVolgorde.Free;
  FAntwoordKas.Free;
  FDiens.Free;
  inherited;
end;

procedure TfrmWebHoof.DoClose(var Action: TCloseAction);
begin
  if Assigned(FLaaiTydhouer) then
    FLaaiTydhouer.Enabled := False;
  inherited;
end;

{$IFDEF DEBUG}

procedure TfrmWebHoof.WndProc(var Message: TMessage);
const
  WM_SMARTEATS_TOETS = WM_APP + 172;
var
  skrip: string;
begin
  if Message.Msg = WM_SMARTEATS_TOETS then
  begin
    case Message.WParam of
      1:
        skrip := 'document.querySelector(''[data-view-button="menu"]'').click();';
      2:
        skrip := 'document.querySelector(''[data-view-button="orders"]'').click();';
      3:
        skrip := 'document.querySelector(''[data-view-button="history"]'').click();';
      4:
        skrip := 'document.querySelector(''[data-view-button="report"]'').click();';
      5:
        skrip := 'document.querySelector(''[data-open-dialog="clientDialog"]'').click();'
          + 'document.getElementById(''clientName'').value=''E2E Toetsklient'';'
          + 'document.getElementById(''clientPhone'').value=''0612345678'';' +
          'document.getElementById(''clientEmail'').value=''e2e@example.test'';'
          + 'document.getElementById(''clientActive'').checked=true;' +
          'document.getElementById(''clientForm'').requestSubmit();';
      6:
        skrip := 'document.querySelector(''[data-view-button="report"]'').click();'
          + 'document.getElementById(''generateReport'').click();';
      7:
        skrip := 'document.querySelector(''[data-view-button="orders"]'').click();'
          + 'setTimeout(()=>{' +
          'const customer=document.getElementById(''customerSelect'');' +
          'const option=[...customer.options].find(o=>o.textContent.startsWith(''E2E Toetsklient''));'
          + 'customer.value=option.value;' +
          'const type=document.getElementById(''orderType'');' +
          'type.value=''Wegneem'';type.dispatchEvent(new Event(''change''));' +
          'const line=document.querySelector(''#orderItems .item-line'');' +
          'const box=line.querySelector(''input[type="checkbox"]'');' +
          'box.checked=true;box.dispatchEvent(new Event(''change''));' +
          'line.querySelector(''.qty'').value=''1'';' +
          'document.getElementById(''saveOrder'').click();},600);';
      8:
        skrip := 'document.querySelector(''[data-view-button="history"]'').click();'
          + 'setTimeout(()=>{' +
          'document.querySelector(''#historyRows tr'').click();' +
          'document.getElementById(''deleteOrder'').click();' +
          'setTimeout(()=>document.getElementById(''confirmAction'').click(),50);'
          + '},600);';
      9:
        skrip := 'document.querySelector(''[data-open-dialog="clientDialog"]'').click();'
          + 'document.getElementById(''clientName'').value='''';' +
          'document.getElementById(''clientPhone'').value=''123'';' +
          'document.getElementById(''clientEmail'').value=''ongeldig'';' +
          'document.getElementById(''clientForm'').requestSubmit();';
      10:
        skrip := 'document.querySelector(''[data-view-button="menu"]'').click();'
          + 'document.querySelector(''[data-open-dialog="addItemDialog"]'').click();'
          + 'document.getElementById(''addItemName'').value='''';' +
          'document.getElementById(''addItemCategory'').value=''Drankie'';' +
          'document.getElementById(''addItemPrice'').value=''0'';' +
          'document.getElementById(''addItemStock'').value=''-1'';' +
          'document.getElementById(''addItemReorder'').value=''100001'';' +
          'document.getElementById(''addItemForm'').requestSubmit();';
      11:
        skrip := 'document.querySelector(''[data-view-button="menu"]'').click();'
          + 'document.querySelector(''[data-open-dialog="addItemDialog"]'').click();'
          + 'document.getElementById(''addItemName'').value=''E2E Grensitem'';'
          + 'document.getElementById(''addItemCategory'').value=''Drankie'';' +
          'document.getElementById(''addItemPrice'').value=''0.01'';' +
          'document.getElementById(''addItemStock'').value=''0'';' +
          'document.getElementById(''addItemReorder'').value=''0'';' +
          'document.getElementById(''addItemAvailable'').checked=true;' +
          'document.getElementById(''addItemForm'').requestSubmit();';
      12:
        skrip := 'document.getElementById(''itemName'').value=''E2E Grensitem Gewysig'';'
          + 'document.getElementById(''itemStock'').value=''1'';' +
          'document.getElementById(''menuForm'').requestSubmit();';
      13:
        skrip := 'document.getElementById(''deleteItem'').click();' +
          'setTimeout(()=>document.getElementById(''confirmAction'').click(),50);';
      14:
        skrip := 'document.querySelector(''[data-view-button="orders"]'').click();'
          + 'setTimeout(()=>document.getElementById(''saveOrder'').click(),300);';
    else
      skrip := '';
    end;
    if skrip <> '' then
    begin
      FEdge.ExecuteScript(skrip);
      FToetsAksie := 'ui-' + IntToStr(Message.WParam);
      FToetsVaslegging.Enabled := False;
      FToetsVaslegging.Enabled := True;
    end;
    Message.Result := 1;
    Exit;
  end;
  inherited;
end;
{$ENDIF}

function TfrmWebHoof.AksieToegelaat(const AAksie: string): Boolean;
begin
  Result := MatchText(AAksie, ['app.initialize', 'app.requestExit',
    'dashboard.refresh', 'menu.load', 'menu.create', 'menu.update',
    'menu.confirmDelete', 'clients.create', 'orders.load', 'orders.create',
    'history.load', 'history.confirmDelete', 'reports.generateDaily']);
end;

procedure TfrmWebHoof.BergAntwoord(const AVersoekID, AAntwoord: string);
var
  oudste: string;
begin
  if FAntwoordKas.ContainsKey(AVersoekID) then
    Exit;
  FAntwoordKas.Add(AVersoekID, AAntwoord);
  FKasVolgorde.Enqueue(AVersoekID);
  while FKasVolgorde.Count > 200 do
  begin
    oudste := FKasVolgorde.Dequeue;
    FAntwoordKas.Remove(oudste);
  end;
end;

function TfrmWebHoof.BouFoutAntwoord(const AVersoekID, AKode, ABoodskap,
  AVeld: string): string;
var
  fout: TJSONObject;
  wortel: TJSONObject;
begin
  wortel := TJSONObject.Create;
  try
    wortel.AddPair('requestId', AVersoekID);
    wortel.AddPair('ok', TJSONBool.Create(False));
    fout := TJSONObject.Create;
    fout.AddPair('code', AKode);
    fout.AddPair('message', ABoodskap);
    if AVeld <> '' then
      fout.AddPair('field', AVeld);
    wortel.AddPair('error', fout);
    Result := wortel.ToJSON;
  finally
    wortel.Free;
  end;
end;

function TfrmWebHoof.BouSuksesAntwoord(const AVersoekID: string;
  AData: TJSONObject): string;
var
  wortel: TJSONObject;
begin
  wortel := TJSONObject.Create;
  try
    wortel.AddPair('requestId', AVersoekID);
    wortel.AddPair('ok', TJSONBool.Create(True));
    wortel.AddPair('data', AData);
    Result := wortel.ToJSON;
  finally
    wortel.Free;
  end;
end;

procedure TfrmWebHoof.PlaasAntwoord(const AJson: string);
begin
  if Assigned(FEdge) and Assigned(FEdge.DefaultInterface) then
    OleCheck(FEdge.DefaultInterface.PostWebMessageAsJson(PChar(AJson)));
end;

procedure TfrmWebHoof.SkryfTegnieseLog(const AKategorie, ABesonderhede: string);
var
  gids: string;
  lêer: string;
  lyn: string;
  stroom: TFileStream;
  grepe: TBytes;
begin
  try
    gids := KrySmartEatsLogGids;
    lêer := TPath.Combine(gids, 'WebView-tegnies.log');
    lyn := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ' [' +
      Copy(AKategorie, 1, 40) + '] ' + Copy(ABesonderhede, 1, 500) + sLineBreak;
    grepe := TEncoding.UTF8.GetBytes(lyn);
    if TFile.Exists(lêer) then
      stroom := TFileStream.Create(lêer, fmOpenReadWrite or fmShareDenyWrite)
    else
      stroom := TFileStream.Create(lêer, fmCreate or fmShareDenyWrite);
    try
      stroom.Seek(0, soEnd);
      stroom.WriteBuffer(grepe[0], Length(grepe));
    finally
      stroom.Free;
    end;
  except
    { Tegniese logfoute mag nooit die werksvloei onderbreek nie. }
  end;
end;

procedure TfrmWebHoof.ToonNoodtoestand(const AOpskrif, ABoodskap: string);
begin
  FNoodOpskrif.Caption := AOpskrif;
  FNoodBoodskap.Caption := ABoodskap;
  FNoodpaneel.BringToFront;
  FNoodpaneel.Visible := True;
end;

procedure TfrmWebHoof.VerwerkBoodskap(const ABron, AJson: string);
var
  aksie: string;
  antwoord: string;
  data: TJSONObject;
  i: Integer;
  jsonWaarde: TJSONValue;
  payload: TJSONValue;
  versoekID: string;
  wortel: TJSONObject;
begin
  versoekID := '';
  if Length(AJson) > MaksimumVersoekgrepe then
  begin
    PlaasAntwoord(BouFoutAntwoord('', 'VERSOEK_TE_GROOT',
      'Die versoek is groter as die toegelate 64 KB.', ''));
    Exit;
  end;
  { WebView2 rapporteer die topvlak-dokument van NavigateToString doelbewus
    as about:blank, selfs al gebruik TEdgeBrowser intern 'n data-URI. }
  if not SameText(ABron, 'about:blank') then
  begin
    SkryfTegnieseLog('BRON_GEBLOKKEER', Copy(ABron, 1, 240));
    Exit;
  end;
  jsonWaarde := TJSONObject.ParseJSONValue(AJson, False, True);
  try
    try
      if not(jsonWaarde is TJSONObject) then
        raise ESmartEatsFout.Create('ONGELDIGE_JSON',
          'Die versoek moet ’n JSON-objek wees.');
      wortel := TJSONObject(jsonWaarde);
      if wortel.Count <> 4 then
        raise ESmartEatsFout.Create('ONGELDIGE_KONTRAK',
          'Die versoek bevat ontbrekende of onbekende kontrakvelde.');
      if not(wortel.GetValue('version') is TJSONNumber) or
        (TJSONNumber(wortel.GetValue('version')).AsInt <> 1) then
        raise ESmartEatsFout.Create('ONGESTEUNDE_WEERGAWE',
          'Slegs brugweergawe 1 word ondersteun.', 'version');
      if not(wortel.GetValue('requestId') is TJSONString) then
        raise ESmartEatsFout.Create('ONGELDIGE_VERSOEK_ID',
          'requestId moet teks wees.', 'requestId');
      versoekID := TJSONString(wortel.GetValue('requestId')).Value;
      if (Length(versoekID) < 1) or (Length(versoekID) > 80) then
        raise ESmartEatsFout.Create('ONGELDIGE_VERSOEK_ID',
          'requestId moet 1 tot 80 veilige karakters bevat.', 'requestId');
      for i := 1 to Length(versoekID) do
        if not CharInSet(versoekID[i], ['A' .. 'Z', 'a' .. 'z', '0' .. '9', '.',
          '_', ':', '-']) then
          raise ESmartEatsFout.Create('ONGELDIGE_VERSOEK_ID',
            'requestId bevat ’n onveilige karakter.', 'requestId');
      if FAntwoordKas.TryGetValue(versoekID, antwoord) then
      begin
        PlaasAntwoord(antwoord);
        Exit;
      end;
      if not(wortel.GetValue('action') is TJSONString) then
        raise ESmartEatsFout.Create('ONGELDIGE_AKSIE', 'action moet teks wees.',
          'action');
      aksie := TJSONString(wortel.GetValue('action')).Value;
      if (Length(aksie) < 1) or (Length(aksie) > 80) or
        (not AksieToegelaat(aksie)) then
        raise ESmartEatsFout.Create('ONBEKENDE_AKSIE',
          'Hierdie aksie word nie deur SmartEats toegelaat nie.', 'action');
      payload := wortel.GetValue('payload');
      if not(payload is TJSONObject) then
        raise ESmartEatsFout.Create('ONGELDIGE_PAYLOAD',
          'payload moet ’n JSON-objek wees.', 'payload');

      if aksie = 'app.requestExit' then
      begin
        if not(TJSONObject(payload).GetValue('confirmed') is TJSONBool) or
          (not TJSONBool(TJSONObject(payload).GetValue('confirmed')).AsBoolean)
        then
          raise ESmartEatsFout.Create('BEVESTIGING_VEREIS',
            'Bevestig eers dat SmartEats moet sluit.');
        data := TJSONObject.Create.AddPair('message',
          'SmartEats sluit veilig.');
        antwoord := BouSuksesAntwoord(versoekID, data);
        BergAntwoord(versoekID, antwoord);
        PlaasAntwoord(antwoord);
        Close;
        Exit;
      end;

      data := FDiens.VoerAksieUit(aksie, wortel);
      antwoord := BouSuksesAntwoord(versoekID, data);
      BergAntwoord(versoekID, antwoord);
      PlaasAntwoord(antwoord);
{$IFDEF DEBUG}
      FToetsAksie := aksie;
      FToetsVaslegging.Enabled := False;
      FToetsVaslegging.Enabled := True;
{$ENDIF}
      if aksie = 'app.initialize' then
      begin
        FUiGereed := True;
        FLaaiTydhouer.Enabled := False;
        FNoodpaneel.Visible := False;
      end;
    except
      on E: ESmartEatsFout do
      begin
        antwoord := BouFoutAntwoord(versoekID, E.Kode, E.Message, E.Veld);
        if versoekID <> '' then
          BergAntwoord(versoekID, antwoord);
        PlaasAntwoord(antwoord);
        SkryfTegnieseLog(E.Kode, 'Aksie het veilig misluk.');
      end;
      on E: Exception do
      begin
        SkryfTegnieseLog('ONVERWAGTE_FOUT', E.ClassName + ': ' + E.Message);
        antwoord := BouFoutAntwoord(versoekID, 'INTERNE_FOUT',
          'SmartEats kon nie die aksie voltooi nie. Geen onvolledige verandering is aanvaar nie.',
          '');
        if versoekID <> '' then
          BergAntwoord(versoekID, antwoord);
        PlaasAntwoord(antwoord);
      end;
    end;
  finally
    jsonWaarde.Free;
  end;
end;

procedure TfrmWebHoof.WanneerEdgeGeskep(Sender: TCustomEdgeBrowser;
  AResult: HResult);
var
  instellings: ICoreWebView2Settings;
begin
  if Failed(AResult) then
  begin
    SkryfTegnieseLog('WEBVIEW_SKEP', SysErrorMessage(AResult));
    ToonNoodtoestand('WebView2 kon nie begin nie',
      'Die Microsoft Edge WebView2 Runtime ontbreek of kon nie begin nie. Installeer of herstel die Evergreen Runtime en begin SmartEats weer.');
    Exit;
  end;
  OleCheck(FEdge.DefaultInterface.Get_Settings(instellings));
  OleCheck(instellings.Set_IsScriptEnabled(1));
  OleCheck(instellings.Set_IsWebMessageEnabled(1));
  OleCheck(instellings.Set_AreDefaultContextMenusEnabled(0));
  OleCheck(instellings.Set_AreDevToolsEnabled(0));
  OleCheck(instellings.Set_IsStatusBarEnabled(0));
  OleCheck(instellings.Set_IsZoomControlEnabled(0));
  OleCheck(instellings.Set_IsBuiltInErrorPageEnabled(0));
  SkryfTegnieseLog('WEBVIEW_GEREED',
    Format('WebView2 geskep; scripts=%s; boodskappe=%s; UI=%s.',
    [BoolToStr(FEdge.ScriptEnabled, True), BoolToStr(FEdge.WebMessageEnabled,
    True), SmartEatsUiWeergawe]));
  if not FEdge.NavigateToString(FUiHtml) then
    ToonNoodtoestand('Ingebedde UI kon nie laai nie',
      'WebView2 het die geverifieerde HTML uit die EXE-resource geweier.');
end;

procedure TfrmWebHoof.WanneerLaaiKlaar(Sender: TCustomEdgeBrowser;
  IsSuccess: Boolean; WebErrorStatus: COREWEBVIEW2_WEB_ERROR_STATUS);
begin
  if FNavigationGeblokkeer then
  begin
    FNavigationGeblokkeer := False;
    SkryfTegnieseLog('NAVIGASIE_KANSELLEER',
      'Die geblokkeerde eksterne navigasie het die plaaslike UI nie vervang nie.');
    Exit;
  end;
  if not IsSuccess then
  begin
    SkryfTegnieseLog('NAVIGASIE_FOUT', IntToStr(Ord(WebErrorStatus)));
    ToonNoodtoestand('Ingebedde UI kon nie laai nie',
      'SmartEats kon die geverifieerde HTML uit die EXE-resource nie veilig laai nie.');
  end
  else
  begin
    SkryfTegnieseLog('NAVIGASIE_GEREED', Copy(FUiUri, 1, 240));
{$IFDEF DEBUG}
    try
      FEdge.CapturePreview(TPath.Combine(KrySmartEatsLogGids,
        'webview-preview.png'));
    except
      on E: Exception do
        SkryfTegnieseLog('VOORSKOU_FOUT', E.Message);
    end;
{$ENDIF}
  end;
end;

procedure TfrmWebHoof.WanneerLaaiBegin(Sender: TCustomEdgeBrowser;
  Args: TNavigationStartingEventArgs);
var
  uri: PWideChar;
  huidige: string;
begin
  uri := nil;
  if Succeeded(Args.ArgsInterface.Get_uri(uri)) then
    try
      huidige := string(uri);
      if SameText(FUiUri, 'about:blank') and
        StartsText('data:text/html;charset=utf-8;base64,', huidige) then
      begin
        FUiUri := huidige;
        FNavigationGeblokkeer := False;
        SkryfTegnieseLog('INGEBEDDE_NAVIGASIE',
          'Die eenmalige NavigateToString-data-URI is aanvaar en as brugbron vasgesluit.');
      end
      else if not SameText(huidige, FUiUri) then
      begin
        FNavigationGeblokkeer := True;
        Args.ArgsInterface.Set_Cancel(1);
        SkryfTegnieseLog('NAVIGASIE_GEBLOKKEER', Copy(huidige, 1, 240));
      end;
      if SameText(huidige, FUiUri) then
        FNavigationGeblokkeer := False;
    finally
      CoTaskMemFree(uri);
    end;
end;

procedure TfrmWebHoof.WanneerNuweVenster(Sender: TCustomEdgeBrowser;
  Args: TNewWindowRequestedEventArgs);
begin
  Args.ArgsInterface.Set_Handled(1);
  SkryfTegnieseLog('NUWE_VENSTER_GEBLOKKEER',
    'Webinhoud het ’n nuwe venster versoek.');
end;

procedure TfrmWebHoof.WanneerProsesMisluk(Sender: TCustomEdgeBrowser;
  ProcessFailedKind: COREWEBVIEW2_PROCESS_FAILED_KIND);
begin
  SkryfTegnieseLog('WEBVIEW_PROSES', IntToStr(Ord(ProcessFailedKind)));
  ToonNoodtoestand('WebView2 het onverwags gestop',
    'Die koppelvlakproses het gestop. Geen databasisaksie is deur hierdie fout herhaal nie. Sluit SmartEats en begin weer.');
end;

procedure TfrmWebHoof.WanneerWebBoodskap(Sender: TCustomEdgeBrowser;
  Args: TWebMessageReceivedEventArgs);
var
  bron: PWideChar;
  JSON: PWideChar;
  bronKopie: string;
  jsonKopie: string;
begin
  bron := nil;
  JSON := nil;
  if Failed(Args.ArgsInterface.Get_Source(bron)) then
    Exit;
  try
    bronKopie := string(bron);
  finally
    CoTaskMemFree(bron);
  end;
  if Failed(Args.ArgsInterface.Get_webMessageAsJson(JSON)) then
    Exit;
  try
    jsonKopie := string(JSON);
  finally
    CoTaskMemFree(JSON);
  end;
  SkryfTegnieseLog('BRUG_BOODSKAP', Format('Bron=%s; lengte=%d',
    [Copy(bronKopie, 1, 240), Length(jsonKopie)]));
  VerwerkBoodskap(bronKopie, jsonKopie);
end;

procedure TfrmWebHoof.WanneerWagVerstryk(Sender: TObject);
begin
  FLaaiTydhouer.Enabled := False;
  if not FUiGereed then
    ToonNoodtoestand('Die koppelvlak antwoord nie',
      'Die plaaslike WebView-koppelvlak het nie binne 15 sekondes gereed gemeld nie. Geen skryfaksie is uitgevoer nie. Sluit SmartEats en probeer weer.');
end;

{$IFDEF DEBUG}

procedure TfrmWebHoof.WanneerToetsVaslegging(Sender: TObject);
var
  lêernaam: string;
begin
  FToetsVaslegging.Enabled := False;
  lêernaam := 'webview-' + StringReplace(FToetsAksie, '.', '-', [rfReplaceAll]
    ) + '.png';
  try
    FEdge.CapturePreview(TPath.Combine(KrySmartEatsLogGids, lêernaam));
  except
    on E: Exception do
      SkryfTegnieseLog('VOORSKOU_FOUT', E.Message);
  end;
end;
{$ENDIF}

procedure TfrmWebHoof.SluitKlik(Sender: TObject);
begin
  Close;
end;

const
  C_DWMWA_USE_IMMERSIVE_DARK_MODE = 20;
  C_DWMWA_BORDER_COLOR = 34;
  C_DWMWA_CAPTION_COLOR = 35;
  C_DWMWA_TEXT_COLOR = 36;

function DwmSetWindowAttribute(hWnd: hWnd; dwAttribute: DWORD;
  pvAttribute: Pointer; cbAttribute: DWORD): HResult; stdcall;
  external 'dwmapi.dll';

procedure TfrmWebHoof.CreateWnd;
begin
  inherited;
  ApplyDarkTitleBar;
end;

// Laat die native vensterrand by die donker WebView-koppelvlak aansluit.
procedure TfrmWebHoof.ApplyDarkTitleBar;
var
  DarkMode: BOOL;
  CaptionColor: COLORREF;
  TextColor: COLORREF;
  BorderColor: COLORREF;
begin
  if Handle = 0 then
    Exit;

  DarkMode := True;
  CaptionColor := RGB(0, 0, 0);
  TextColor := RGB(255, 255, 255);
  BorderColor := RGB(0, 0, 0);

  DwmSetWindowAttribute(Handle, C_DWMWA_USE_IMMERSIVE_DARK_MODE, @DarkMode,
    SizeOf(DarkMode));

  DwmSetWindowAttribute(Handle, C_DWMWA_CAPTION_COLOR, @CaptionColor,
    SizeOf(CaptionColor));

  DwmSetWindowAttribute(Handle, C_DWMWA_TEXT_COLOR, @TextColor,
    SizeOf(TextColor));

  DwmSetWindowAttribute(Handle, C_DWMWA_BORDER_COLOR, @BorderColor,
    SizeOf(BorderColor));

  RedrawWindow(Handle, nil, 0, RDW_INVALIDATE or RDW_FRAME or RDW_UPDATENOW);
end;

end.
