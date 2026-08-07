# SmartEats finale indieningsmanifest

Hierdie manifest lys die aktiewe bron-, runtime-, data-, dokumentasie- en bewysitems.
Items onder `unused` is doelbewus nie deel van die aktiewe indiening nie.

## BRONKODE

| Pad | Rede vir insluiting |
|---|---|
| `Project1.dpr` | Programbegin, datamodule en hoofvorm |
| `Project1.dproj` | Delphi-projek, Win64-konfigurasies en pre-build-resource-teiken |
| `Project1.res` | Delphi-hoofprojekresource wat deur `{$R *.res}` vereis word |
| `smarteats.ico` | Hoofprogramikoon waarna `Project1.dproj` eksplisiet verwys |
| `uDataModule.pas` | ADO-verbinding, metadata en navraagfabriek |
| `uDataModule.dfm` | Datamodule se ontwerpresource |
| `uSmartEatsBootstrap.pas` | AppData-paaie, UI/seed-resources, skema, migrasie en atomiese bootstrap |
| `uSmartEatsService.pas` | Validering, CRUD, transaksies, berekenings en teksuitsette |
| `uWebHoof.pas` | Dinamiese WebView2-gasheer, brug, navigasiegrens en Debug-E2E-hake |
| `ui\index.html` | Enigste produksie-UI-bron met alle eerste-party HTML, CSS en JavaScript inline |
| `resources\SmartEatsAssets.rc` | Benoem UI en seed as RCDATA-resources |
| `resources\SmartEatsAssets.res` | Gekoppelde UI- en seed-resource vir die EXE |
| `resources\SmartEatsAssetsHashes.inc` | Gegenereerde UI-/seed-hashes en skemaweergawe vir kompilasie |
| `resources\Project1.res` | Behoue Delphi-bouresource; benodigdheid is projek-/IDE-spesifiek |
| `tools\BouHulpbronne.ps1` | Herhaalbare hash- en resourcebou |
| `tools\SkepDatabasis.ps1` | Herhaalbare skema- en seedopwekking met rugsteungrens |
| `tools\ToetsDatabasis.ps1` | 27 skema- en integriteitskontroles |
| `tools\ToetsDaaglikseStatistiek.ps1` | 12 middernag- en daggrenskontroles |
| `tools\ToetsIngebeddeHulpbronne.ps1` | Byte-vir-byte EXE-resourcekontrole |
| `tools\NeemVensterSkermgreep.ps1` | Herhaalbare werklike-vensterbewys |
| `tools\MeetKodeAandeel.ps1` | Inligtingsoudit van eerste-party bronreëls |

## RUNTIME

| Pad | Rede vir insluiting |
|---|---|
| `dist\SmartEats\Project1.exe` | Finale Win64 Release, byte-identies aan `Win64\Release\Project1.exe` |
| `dist\SmartEats\WebView2Loader.dll` | Win64 WebView2-laaier wat saam met die EXE versprei word |

Die masjien benodig ook die Microsoft Edge WebView2 Evergreen Runtime en 'n 64-bis ACE OLE DB 16.0- of 12.0-verskaffer.
Daar is geen los produksie-HTML, JavaScript, CSS, localhost-bediener of netwerk-UI-bate in die runtimepakket nie.

## DATA

| Pad/ligging | Rede vir insluiting |
|---|---|
| `resources\SmartEats.seed.accdb` | Skoon, onveranderlike seed wat in die EXE ingebed word |
| `data\SmartEats.accdb` | Behoue ontwikkelings-/skema-ACCDB wat die databasisbou- en ouditgereedskap se eksplisiete of verstekbron kan wees |
| `%LOCALAPPDATA%\SmartEats\data\SmartEats.accdb` | Werklike aktiewe, skryfbare runtime-databasis; dit word nie uit die gebruikerprofiel as 'n indieningskopie verskuif nie |

Die seed word slegs onttrek wanneer die aktiewe databasis ontbreek.
'n Bestaande aktiewe databasis word nooit deur die seed oorskryf nie.

## SKRIFTELIKE_INDIENING

| Pad | Rede vir insluiting |
|---|---|
| `PROJEKNOTAS.md` | Sentrale 38-afdeling gebruikers- en ontwikkelaarsdokument; ASCII-skoon |
| `ONTWERP_EN_TOETSPLAN.md` | Taakdefinisie, stories, aanvaarding, veranderlikes, tekslêers, skikkings, metodes, TVA/IPO, GGK en toetse |
| `RUBRIEK_OUDIT.md` | 41 ondeelbare nie-onderhoudsrye en presiese 142-puntrekonsiliasie |
| `E2E_TOETSVERSLAG.md` | Werklik uitgevoerde bou-, normale-, grens-, ongeldige-, data- en visuele resultate |
| `PACKAGING_EN_BOOTSTRAP.md` | Finale EXE-resource- en AppData-argitektuur |
| `WEBVIEW_BRUG.md` | Boodskapkontrak, toelaatlys, antwoorde, duplikaatkas en sekuriteitsgrens |
| `UI_FUNKSIONELE_PARITEIT.md` | 32 finale UI-funksies na aksie en Delphi-metode gekarteer |
| `LUCIDCHART_PARITEIT.md` | Diagram na UI, aksie, metode en data/teks gekarteer |
| `LUCIDCHART_SKAKEL.txt` | Lucid-titel, dokument-ID, anonieme redigeerskakel en PNG-gids |
| `PROBLEEMOPLOSSING.md` | Herstelstappe vir resource, WebView2, ACE, seed, skema en verslag |
| `DOOIE_KODE_OUDIT.md` | Finale aktiewe-/afgetrede bron- en bateklassifikasie |
| `KODE_AANDEEL_OUDIT.md` | Inligtingsnota dat 20% nie 'n finale harde kriterium is nie |
| `unused\README.md` | Herstelbare rekord van elke opruimingskuif |
| `Instructions\Gr 11 IT PAT 2026 Afr.pdf (1)\Gr 11 IT PAT 2026 Afr.pdf` | Behoue amptelike PAT- en rubriekbron |
| `Instructions\Gr 10 PAT IT Bylaag Taak1_2026 Afr.docx` | Behoue amptelike blanko bylaag/werkdokument |

## LUCIDCHART-UITVOERE

Redigeerbare dokument: `SmartEats Finale Programvloei - PAT 2026`.
Dokument-ID: `424408a5-29e3-488d-aa2e-c9dd6f1db212`.

| Pad | Bladsy |
|---|---|
| `SKRIFTELIKE_INDIENING\Lucidchart\01-Globale-SmartEats-programvloei.png` | Globale vloei en legende |
| `SKRIFTELIKE_INDIENING\Lucidchart\02-Inisialisering-en-databasisverbinding.png` | Bootstrap en verbinding |
| `SKRIFTELIKE_INDIENING\Lucidchart\03-Hoofnavigasie-en-dashboard.png` | Navigasie en dashboard |
| `SKRIFTELIKE_INDIENING\Lucidchart\04-Kliente-lees-en-voeg-by.png` | Kliënte |
| `SKRIFTELIKE_INDIENING\Lucidchart\05-Spyskaartitems-CRUD.png` | Spyskaart-CRUD |
| `SKRIFTELIKE_INDIENING\Lucidchart\06-Voorraad-en-herbestelvlak.png` | Voorraad |
| `SKRIFTELIKE_INDIENING\Lucidchart\07-Nuwe-bestelling.png` | Nuwe bestelling |
| `SKRIFTELIKE_INDIENING\Lucidchart\08-Bestellingstipe-en-itemkeuse.png` | Tipe en items |
| `SKRIFTELIKE_INDIENING\Lucidchart\09-Totale-BTW-en-finale-bestelling.png` | Totale en finale bevestiging |
| `SKRIFTELIKE_INDIENING\Lucidchart\10-Databasisstoor-en-rollback.png` | Transaksie en rollback |
| `SKRIFTELIKE_INDIENING\Lucidchart\11-Daaglikse-statistiek.png` | Daggrense en statistiek |
| `SKRIFTELIKE_INDIENING\Lucidchart\12-Dagverslag-en-teksleeruitvoer.png` | Verslag en tekslêer |
| `SKRIFTELIKE_INDIENING\Lucidchart\13-Algemene-datavalidering.png` | Validering |
| `SKRIFTELIKE_INDIENING\Lucidchart\14-Fout-en-uitsonderingshantering.png` | Foutopvang |
| `SKRIFTELIKE_INDIENING\Lucidchart\15-Sluit-SmartEats.png` | Sluitvloei |

## TOETSBEWYS

| Pad | Bewysdoel |
|---|---|
| `toetsbewyse\finale-e2e-eerste-lopie.png` | Skoon seed-onttrekking en ingebedde UI |
| `toetsbewyse\finale-release-bou.png` | Delphi Release `Success` |
| `toetsbewyse\finale-debug-herbou.png` | Finale Delphi Debug `Success` na resource-hergenerering en opruiming |
| `toetsbewyse\finale-release-loop.png` | Werklike finale Release-EXE en AppData-verbinding |
| `toetsbewyse\finale-klient-skep.png` | Geldige kliëntinvoeging |
| `toetsbewyse\finale-bestelling-skep.png` | Geldige bestelling en bedrae |
| `toetsbewyse\finale-dagverslag.png` | Verwerkte dagverslag in die UI |
| `toetsbewyse\finale-Dagverslag-20260803.txt` | Finale UTF-8-dagverslaglêer |
| `toetsbewyse\finale-bestelling-verwyder.png` | Transaksionele bestellingverwydering |
| `toetsbewyse\finale-grensitem-skep.png` | Minimum geldige grensitem |
| `toetsbewyse\finale-grensitem-wysig.png` | Geselekteerde rekordwysiging |
| `toetsbewyse\finale-grensitem-verwyder.png` | Bevestigde itemverwydering |
| `toetsbewyse\finale-ongeldige-klient.png` | Kliëntveldvalidering sonder `INSERT` |
| `toetsbewyse\finale-ongeldige-item.png` | Itemreeksvalidering sonder `INSERT` |
| `toetsbewyse\finale-ongeldige-bestelling.png` | Bestellingfout sonder transaksie |
| `toetsbewyse\finale-sluitbevestiging.png` | Gesentreerde sluitbevestiging en veilige uitkliek |

## LEERDER_MOET_SELF_VOLTOOI

| Item | Leerderaksie |
|---|---|
| Amptelike verklaring van egtheid | Lees, voltooi en onderteken self volgens die skool se instruksies |
| Erkenning van KI/Codex-hulp | Verklaar die werklike hulp eerlik volgens die skool se beleid |
| Persoonlike onderhoud | Demonstreer en verduidelik die eie begrip van kode, databasis, algoritmes, toetsing en ontwerp |
| Persoonlike besonderhede op amptelike vorms | Vul naam, kandidaat-/skoolbesonderhede en datums self in |

Geen verklaring is namens die leerder ingevul of onderteken nie.
Die afsonderlike 8 onderhoudspunte is nie as voltooi of gewaarborg gemerk nie.
