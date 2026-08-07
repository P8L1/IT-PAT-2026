# SmartEats Projeknotas

Hierdie dokument beskryf die finale SmartEats Graad 11 IT PAT 2026-toepassing.
Dit is op die aktiewe bronkode, die Access-databasis en uitgevoerde toetse gegrond.
Alle paaie is Windows-paaie.

## 1. Projeknaam en doel

Die projeknaam is SmartEats.
SmartEats is 'n Windows-rekenaartoepassing vir 'n klein restaurant se kliente, spyskaart, voorraad, bestellings en dagverslae.
Die hoofdoel is om 'n volledige bestelling veilig van toevoer tot databasisstoor en verslagafvoer te verwerk.

## 2. Probleem wat SmartEats oplos

Handgeskrewe bestellings en los sigblaaie veroorsaak maklik verkeerde pryse, voorraadfoute en onvolledige dagtotale.
SmartEats hou verwante data in een gestruktureerde Access-databasis.
Die toepassing herbereken pryse en voorraad op die Delphi-kant voordat data gestoor word.
Dit verminder die kans op 'n gedeeltelike bestelling of 'n totaal wat nie met die databasis ooreenstem nie.

## 3. Teikengebruikers

| Gebruiker | Rol | Hoofaktiwiteit | Waarde |
|---|---|---|---|
| Bedienings- of kassapersoneel | Neem bestellings | Kies klient, besteltipe, items en hoeveelhede | Vinnige, geldige bestelling met korrekte totaal |
| Bestuurder | Bestuur data en dagafsluiting | Werk spyskaart en voorraad by en genereer dagverslag | Betroubare voorraad- en verkoopsinligting |

Albei gebruikertipes gebruik dieselfde toepassing, maar hul gewone werkvloeie verskil.

## 4. Reikwydte

Die finale toepassing dek die volgende funksies:

- Dashboard met vandag se bestellings, omset en lae voorraad.
- Lees, soek, sorteer, skep, wysig en verwyder van spyskaartitems.
- Lees van aktiewe kliente en skep van 'n nuwe klient.
- Skep van Eet-in- en Wegneem-bestellings.
- Outomatiese subtotal-, BTW- en totaalberekening.
- Transaksionele stoor van bestelling, lyne, voorraad en lojaliteitspunte.
- Lees en verwyder van bestellingsgeskiedenis.
- Daaglikse gegroepeerde verslag en UTF-8-teksleerafvoer.
- Veilige eerste lopie, skemavalidering en migrasie van die Access-databasis.

## 5. Bekende en eerlike beperkings

SmartEats is 'n enkelmasjien-, Windows- en Access-oplossing.
Dit is nie 'n multi-tak-, wolk- of aanlyn bestelstelsel nie.
Die toepassing laat nuwe kliente toe en lees kliente vir bestellings, maar bied nie 'n afsonderlike klientwysigingskerm nie.
Spyskaartitems verskaf die volledige skep-, lees-, wysig- en verwyderbewerkings wat die databasismanipulasierubriek vereis.
Die HTML-bron kan buite Delphi oopgemaak word, maar databasisfunksies werk doelbewus slegs deur die geverifieerde WebView2-brug.

## 6. Stelselvereistes

- Windows 10 of nuwer word aanbeveel.
- Die finale teiken is Win64.
- Microsoft Edge WebView2 Runtime moet beskikbaar wees.
- Microsoft Access Database Engine met ACE OLE DB 16.0 of 12.0 moet vir 64-bis gebruik beskikbaar wees.
- Die gebruiker moet skryfregte tot sy of haar plaaslike AppData-gids he.

## 7. Installasie en opstelling

Die finale runtime bestaan uit `SmartEats.exe` en die vereiste WebView2Loader-DLL in dieselfde verspreidingsgids.
Die UI en die skoon seeddatabasis is resources binne die EXE en word nie as los produksielers versprei nie.
By die eerste lopie skep SmartEats sy eie gidse onder `%LOCALAPPDATA%\SmartEats`.
Geen installer hoef 'n skryfbare databasis langs die EXE te plaas nie.

## 8. WebView2-runtime

`uWebHoof.pas` skep 'n `TEdgeBrowser` dinamies en vul die hele klientarea van die hoofvenster.
`ui/index.html` word deur `LaaiIngebeddeUi` uit resource `SMARTEATS_UI_HTML` gelees en met `NavigateToString` gelaai.
Navigasie na ander adresse en nuwe vensters word geblokkeer.
Die WebView2-gebruikersdatagids is onder `%LOCALAPPDATA%\SmartEats\WebView2`.
As WebView2 nie kan begin nie, toon die VCL-noodvlak 'n veilige Afrikaanse fout en voer geen skryfaksie uit nie.

## 9. ACE OLE DB-verskaffer en bitheid

Die toepassing probeer eers `Microsoft.ACE.OLEDB.16.0`.
As dit nie beskikbaar is nie, probeer dit `Microsoft.ACE.OLEDB.12.0`.
Die Delphi-uitvoerbare leer en ACE-verskaffer moet dieselfde 64-bis-argitektuur gebruik.
`TADOConnection` gebruik `LoginPrompt = False`, 'n verbindingstydperk en 'n opdragtydperk.

## 10. Gids- en databasisstruktuur

Die aktiewe databasis is altyd:

```text
%LOCALAPPDATA%\SmartEats\data\SmartEats.accdb
```

Die sentrale funksie `KryPlaaslikeAppDataGids` bepaal die gebruikerspesifieke basispad.
`KrySmartEatsWortelGids`, `KrySmartEatsDataGids`, `KrySmartEatsLogGids` en `KrySmartEatsWebViewGids` lei die res af.
Die projek se relatiewe bronstruktuur is:

```text
SmartEats.dpr
uDataModule.pas
uSmartEatsBootstrap.pas
uSmartEatsService.pas
uWebHoof.pas
ui\index.html
resources\SmartEats.seed.accdb
resources\SmartEatsAssets.rc
tools\
```

Die aktiewe databasis word nooit in die projekgids, langs die EXE of binne die EXE gewysig nie.

## 11. Hoe om die program te bou

Open `SmartEats.dproj` in Delphi 12 Community Edition.
Kies `Windows 64-bit` as teikenplatform.
Kies `Debug` of `Release` onder Build Configurations.
Gebruik `Project > Build SmartEats`.
Die pre-build-teiken loop `tools\BouHulpbronne.ps1` om SHA-256-konstantes en `SmartEatsAssets.res` te herskep.
Die Community Edition laat nie op hierdie masjien die los `dcc64`-opdragreelkompileerder toe nie, daarom is die Delphi IDE die herhaalbare bouroete.
Geen Node-, npm-, Bun-, localhost- of webbedienerbouketting is deel van SmartEats nie.

## 12. Hoe om die program te begin

Begin `Win64\Release\SmartEats.exe` vir die finale weergawe.
Die program koppel eers die databasis en skep daarna die hoof-WebView2-venster.
Die eerste lopie kan langer neem terwyl die seed en WebView2-gebruikersgids geskep word.
Die hoofvenster se titel is `SmartEats Bestellings- en Spyskaartbestuur`.

## 13. Hoofnavigasie

Die sybalk bied Dashboard, Spyskaart en voorraad, Nuwe bestelling, Geskiedenis en Dagverslag.
Hulp en Sluit SmartEats is onderaan beskikbaar.
By 'n smal logiese viewport word die sybalk deur 'n horisontaal skuifbare kompakte kopnavigasie vervang.
Die huidige skerm se knoppie gebruik `aria-current="page"`.
Die kortpaaie is Alt+S vir Spyskaart, Alt+B vir Bestelling, Alt+D vir Dagverslag en Alt+V vir Sluit.

## 14. Dashboard

Die dashboard wys die plaaslike kalenderdatum, vandag se bestellingstelling, BTW-ingeslote omset en die aantal laevoorraaditems.
Die SQL-daggrens is half-oop: `DatumTyd >= BeginDatum AND DatumTyd < EindDatum`.
Hierdie formule sluit die volle huidige dag in en sluit presies middernag van die volgende dag uit.
'n Tydhouer verfris net na middernag.
Fokus-herwinning en die Verfris-knoppie kontroleer ook of die datum verander het.

## 15. Klientebestuur

Aktiewe kliente word uit `tblKliente` in die bestellingskeuselys gelaai.
Die nuwe-klientdialoog lees naam, selfoon, opsionele e-pos en aktiewe status.
Die selfoon moet tien syfers lank wees, met 0 begin en 'n toepaslike 6-, 7- of 8-reeks volg.
Die databasis het 'n unieke indeks op `Selfoon` om duplikate ook op databasisvlak te blokkeer.
Na 'n suksesvolle invoeging word die lys herlaai en die nuwe klient gekies.

## 16. Spyskaart- en itembeheer

Die spyskaarttabel wys ID, naam, kategorie, prys, voorraad, herbestelvlak en beskikbaarheid.
Soek gebruik 'n parameter en sortering gebruik 'n vaste toelaatlys van veilige SQL-fragmente.
Die gebruiker kan 'n item skep, kies en wysig, of na bevestiging verwyder.
Prys moet groter as R0,00 en hoogstens R1 000 000,00 wees.
Voorraad en herbestelvlak moet heelgetalle tussen 0 en 100 000 wees.

## 17. Voorraad en herbestelvlak

'n Item verg aandag wanneer dit beskikbaar is en `Voorraad <= Herbestelvlak`.
Die dashboard wys hierdie items met huidige voorraad en herbestelvlak.
Wanneer 'n bestelling gestoor word, verminder die Delphi-transaksie die werklike voorraad.
Wanneer 'n bestelling verwyder word, herstel dieselfde tipe transaksie die voorraad.

## 18. Bestellingsproses

Die gebruiker kies 'n aktiewe klient en Eet-in of Wegneem.
Eet-in vereis 'n tafelnommer van 1 tot 40.
Minstens een verkoopbare item moet gekies word.
Elke hoeveelheid moet 'n heelgetal van minstens 1 wees en mag nie die jongste databasisvoorraad oorskry nie.
Die UI kan die ongestoorde bestelling veilig skoonmaak sonder 'n databasisverandering.

## 19. Totale en BTW

Die UI gee onmiddellik 'n gebruikersvoorskou van die bedrae.
Die gesaghebbende Delphi-berekening herlees elke prys uit die databasis.
Die formules is:

```text
Subtotaal = som(Eenheidsprys * Hoeveelheid)
BTW = Round(Subtotaal * BTWKoers, 2)
Totaal = Subtotaal + BTW
Lojaliteitspunte = Trunc(Totaal)
```

Die BTW-koers kom uit `tblMetadata` en is nie in die UI hardgekodeer as die finale gesag nie.

## 20. Daaglikse statistiek

Vandag se statistiek gebruik die plaaslike datum wat op die oomblik van die versoek bereken word.
`COUNT(*)` lewer die aantal bestellings.
`SUM(Totaal)` lewer die BTW-ingeslote omset en word as nul behandel wanneer daar geen rye is nie.
Middernag-, herbegin- en handmatige-verfristoetse bevestig die daggrense.

## 21. Verslae en teksleerafvoer

Die dagverslag voeg bestellings, bestellyne en spyskaartitems saam en groepeer per item.
Die resultaat word in 'n dinamiese `TVerslagItem`-skikking gelaai.
'n Geneste sortering rangskik die hoogste hoeveelheid eerste en gebruik itemnaam as gelykopbreker.
Die verslag word as UTF-8 geskryf met die naam `Dagverslag-YYYYMMDD.txt`.
Die EXE-gids word gebruik indien dit skryfbaar is.
Anders gebruik SmartEats `%LOCALAPPDATA%\SmartEats\Verslae`.
Elke suksesvolle bestelling probeer ook 'n UTF-8-kwitansie skryf.

## 22. Kansellasie, bevestigings en popups

Verwydering van 'n item of bestelling vereis 'n bevestigingsdialoog.
Kansellasie sluit die dialoog en herstel fokus sonder 'n skryfaksie.
Sluit SmartEats vereis ook bevestiging.
Suksesvolle skryfaksies wys 'n toast regs onder.
Foute wys 'n veldopsomming of 'n aparte boodskapdialoog met 'n herstelbare volgende stap.

## 23. Datavalidering en foutboodskappe

Validering vind op die HTML/JavaScript-kant en weer op die Delphi-kant plaas.
Die brug aanvaar slegs 'n JSON-objek met presies `version`, `requestId`, `action` en `payload`.
Boodskappe groter as 64 KB, onbekende aksies en verkeerde datatipes word verwerp.
Delphi lees strings, heelgetalle, geld en datums deur gebruikergedefinieerde metodes.
Gebruikerdata word met benoemde ADO-parameters gebind en nie in SQL saamgevoeg nie.
Afrikaanse foutboodskappe identifiseer die ongeldige veld en die verwagte reeks of formaat.

## 24. Databasisontwerp en tabelle

| Tabel | Doel | Primere sleutel | Belangrike verwantskap |
|---|---|---|---|
| `tblMetadata` | Skemaweergawe, restaurantnaam en BTW-koers | `Sleutel` | Geen |
| `tblKliente` | Klientbesonderhede en lojaliteit | `KlientID` | Een klient na baie bestellings |
| `tblSpyskaart` | Items, pryse en voorraad | `ItemID` | Een item na baie bestellyne |
| `tblBestellings` | Bestellingkop, datum, tipe en totale | `BestellingID` | Verwys na een klient |
| `tblBestellyne` | Hoeveelheid en vasgelegde eenheidsprys | `BestellynID` | Verwys na bestelling en item |

Die velde gebruik toepaslike Access-tipes soos AUTOINCREMENT, LONG, VARCHAR, CURRENCY, DATETIME en YESNO.
Totale word op die bestelling vasgele omdat dit die historiese finansiele transaksie voorstel.
Die lyn se eenheidsprys word vasgele om die historiese verkoopprys te behou indien die spyskaartprys later verander.

## 25. CRUD-bewerkings

`VoegSpyskaartitemBy` voer 'n parameter-`INSERT` uit.
`SkepSpyskaart` voer 'n veilige `SELECT` uit.
`WysigSpyskaartitem` voer 'n parameter-`UPDATE` uit.
`VerwyderSpyskaartitem` voer na bevestiging 'n parameter-`DELETE` uit.
Bestellings gebruik verdere gekoppelde invoeg-, wysig- en verwyderbewerkings binne transaksies.
Die UI se Eerste, Vorige, Volgende en Laaste knoppies navigeer herhaalbaar deur die gelaaide rekordstel in bladsye van agt rye.

## 26. Skikkings

`TBestellynInvoer` is 'n rekord wat item-ID, hoeveelheid, naam, prys en voorraad saamhou.
`TArray<TBestellynInvoer>` bevat die gevalideerde bestellyne vir berekening, databasisstoor en kwitansie-uitvoer.
`TVerslagItem` hou itemnaam, aantal en omset saam.
Die dinamiese `TVerslagItem`-skikking ondersteun verwerking en geneste sortering voor die verslag geskryf word.
Konstante skikkings bevat die Afrikaanse dag- en maandname vir datumformatering.

## 27. Tekslers

Tegniese WebView-gebeure word met tydstempel na `WebView-tegnies.log` bygevoeg.
Kwitansies en dagverslae word as UTF-8-teks geskryf.
`TStringList` en `try/finally` verseker dat geheue en leerhandvatsels vrygestel word.
Verslag- en kwitansiefoute vernietig nie 'n reeds gecommitteerde bestelling nie en word duidelik gerapporteer.

## 28. Gebruikergedefinieerde metodes

Die projek gebruik herbruikbare funksies en prosedures vir paaie, bootstrap, hashverifikasie, verbinding, validering, JSON-antwoorde, SQL-navrae, datumformatering, CRUD en verslae.
Voorbeelde is `KryPlaaslikeAppDataGids`, `SkryfSeedAtomies`, `LeesHeelgetal`, `SkepDashboard`, `StoorBestelling`, `GenereerDagverslag`, `AksieToegelaat` en `BouFoutAntwoord`.
Parameters en terugkeerwaardes dra die nodige data sonder globale duplisering.

## 29. Relevante komplekse kode

`TfrmWebHoof` skep die WebView2-komponent en tydhouers dinamies.
Die dienslaag gebruik generiese woordeboeke, dinamiese rekordskikkings en geneste lusse.
Die brug hou 'n maksimum kas van 200 antwoorde volgens `requestId` om toevallige duplikaatindienings idempotent te hanteer.
Bestellingstoor en bestellingverwydering gebruik meervoudige SQL-stappe binne ADO-transaksies.
Die bootstrap gebruik 'n benoemde Windows-mutex, SHA-256 en 'n atomiese `MoveFileEx`-skuif.

## 30. Belangrike algoritmes en formules

### Seed-onttrekking

1. Kry die sentrale AppData-pad.
2. Verkry die benoemde bootstrap-mutex.
3. Hou 'n bestaande databasis onveranderd.
4. Lees die ingebedde seed en verifieer sy SHA-256.
5. Skryf na 'n unieke tydelike leer en flush na skyf.
6. Verifieer grootte en hash weer.
7. Skuif atomies na die finale naam.

### Bestellingstoor

1. Valideer klient, tipe, tafel en dinamiese lyne.
2. Begin die ADO-transaksie.
3. Herlees elke item se prys, voorraad en beskikbaarheid.
4. Bereken bedrae op die Delphi-kant.
5. Voeg bestelling en lyne in.
6. Werk voorraad en lojaliteit by.
7. Commit alles, of rollback alles by enige fout.

### Dagverslagsortering

Die buitenste lus verminder die ongesorteerde deel na elke pas.
Die binneste lus ruil aangrensende rekords wanneer die linker aantal kleiner is.
Gelyke aantalle word alfabeties volgens itemnaam gerangskik.

## 31. Toetsstrategie

Die toetsstrategie kombineer bronoudit, IDE-bou, werklike EXE-E2E, Access-integriteitsnavrae, resource-hashvergelyking en visuele browserkontrole.
Produksiedata word nie vir vernietigende toetse gebruik nie.
Die Debug-bou aanvaar `SMARTEATS_TEST_ROOT` om 'n afgesonderde AppData-boom te gebruik.
Normale, grens- en ongeldige data word afsonderlik getoets.
Na skryfaksies lees 'n onafhanklike ADO-verbinding die toetsdatabasis om die resultaat te bewys.

## 32. Voorbeelde van normale, grens- en ongeldige toetse

| Tipe | Toets | Verwagte resultaat | Finale resultaat |
|---|---|---|---|
| Normaal | Skep klient, skep bestelling, genereer verslag en verwyder bestelling | Data word korrek geskep; verslag kom uit verwerking; voorraad en lyne word herstel/verwyder | Geslaag op afgesonderde Debug-databasis |
| Grens | Itemprys R0,01, voorraad 0 en herbestelvlak 0 | Waardes word aanvaar en item kan weer gewysig en verwyder word | Herhaalbare Debug-E2E-toets beskikbaar |
| Grens | Rekords presies voor, op en na middernag | Elke rekord val in die korrekte half-oop dagreeks | Alle kalenderdagkontroles het geslaag |
| Ongeldig | Lee klientnaam, selfoon `123` en ongeldige e-pos | Veldfoute; geen `INSERT` | Herhaalbare Debug-E2E-toets beskikbaar |
| Ongeldig | Prys 0, voorraad -1 en herbestelvlak 100001 | Veldfoute; geen `INSERT` | Herhaalbare Debug-E2E-toets beskikbaar |
| Ongeldig | Bestelling sonder klient, tipe of item | Duidelike fout; geen transaksie begin | Herhaalbare Debug-E2E-toets beskikbaar |

Die formele leerdergerigte resultate is in `SKRIFTELIKE_INDIENING\Taak_9\TAAK_9_TOETSING.md` aangeteken.
Rou E2E-uitvoer en skermbewyse is apart onder `NIE_VIR_INDIENING\rou_toetsbewyse` behou.

## 33. Rugsteun en dataherstel

Die ingebedde seed is 'n onveranderlike beginpunt en nie 'n rugsteun van gebruikersdata nie.
'n Bestaande aktiewe databasis word nooit deur die seed oorskryf nie.
Voor 'n skemamigrasie skep SmartEats 'n tydgestempelde ACCDB-rugsteun in die data-gids.
Mislukte migrasies word teruggerol en die fout word gerapporteer.
Vir gewone herstel moet die gebruiker SmartEats sluit en 'n bekende goeie kopie van die aktiewe ACCDB terugplaas.

## 34. Onderhoud vir ontwikkelaars

`ui/index.html` is die enigste produksie-UI-bron en bevat alle eerste-party HTML, CSS, JavaScript en noodstilering.
Moenie 'n aparte produksie-CSS- of JavaScript-leer byvoeg nie.
Na enige UI- of seed-verandering moet `tools\BouHulpbronne.ps1` loop en albei EXE-resources moet weer getoets word.
Nuwe WebView-aksies moet in die JavaScript, `AksieToegelaat` en `VoerAksieUit` in sinkronisasie bygevoeg word.
Skemaveranderinge vereis 'n hoer metadataweergawe, validering, rugsteun en 'n idempotente migrasiepad.
Gebruik altyd parameters vir gebruikerdata en transaksies vir gekoppelde skrywes.

## 35. Probleemoplossing

### WebView2 begin nie

Installeer of herstel die Microsoft Edge WebView2 Runtime.
Kontroleer dat `WebView2Loader.dll` by die EXE is.
Lees die tegniese log onder `%LOCALAPPDATA%\SmartEats\logs`.

### Access kan nie koppel nie

Installeer die 64-bis Microsoft Access Database Engine.
Kontroleer dat die aktiewe databasis by `%LOCALAPPDATA%\SmartEats\data\SmartEats.accdb` bestaan.
Moenie die databasis langs die EXE kopieer as 'n ompad nie.

### Verslag kan nie geskryf word nie

Kontroleer die EXE-gids se skryfregte.
Kontroleer daarna die fallback-gids `%LOCALAPPDATA%\SmartEats\Verslae`.

### Die UI stem nie met die bron ooreen nie

Loop die resource-bouskrip, bou die EXE weer in Delphi en loop `tools\ToetsIngebeddeHulpbronne.ps1`.

## 36. Bekende foute

Geen bekende reproduseerbare kernfunksiefout is na die finale regressietoetse oopgelaat nie.
Die persoonlike onderhoud en 'n nasiener se finale puntetoekenning is nie deur tegniese toetsing vervang nie.

## 37. Hulp, bronne en erkenning

Die amptelike Graad 11 IT PAT 2026-instruksies en rubriek is die hoogste bron vir die projekvereistes.
Die toepassing gebruik Delphi VCL, dbGo/ADO, Microsoft Access, Microsoft Edge WebView2 en gewone ingebedde HTML, CSS en JavaScript.
KI- en Codex-hulp is vir finale oudit, kodeherstel, dokumentasie, toetsoutomatisering en Lucidchart-samestelling gebruik.
Die leerder moet hierdie hulp eerlik volgens die skool se vereistes verklaar en moet self die kode kan verduidelik.
Geen verklaring van egtheid is deur hierdie dokument namens die leerder onderteken nie.

## 38. Finale indieningsinhoud

`SKRIFTELIKE_INDIENING\LEES_MY_EERSTE.txt` is die gesaghebbende gids tot die formele taakdokumente.
Die formele gids bevat Taak 1, 2, 3, 4, 5, 9 en 10, die Lucidchart-uitsette en onvoltooide verklaringsmateriaal.
Die kernprogramitems bly die Delphi-projek en eenhede, `ui/index.html`, die seed en resourceleer, die finale EXE en runtime-DLL.
Interne oudits, tegniese ontwikkelaardokumentasie en rou toetsbewyse is onder `NIE_VIR_INDIENING` en vorm nie deel van die formele skriftelike indiening nie.
Die redigeerbare Lucidchart-skakel is in `SKRIFTELIKE_INDIENING\Lucidchart\LUCIDCHART_SKAKEL.txt`.
Die 15 PNG-bladsye is in `SKRIFTELIKE_INDIENING\Lucidchart`.
Die leerder moet enige skoolverklaring of onderhoud self voltooi.
