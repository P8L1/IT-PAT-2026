# Taak 2: Datawoordeboek

Hierdie datawoordeboek beskryf slegs veranderlikes, komponente, skikkings, tekslêers en metodes wat in die SmartEats-bronkode aktief is.

## Veranderlikes

| Naam | Omvang | Datatipe | Doel | Voorbeeld | Gebruike |
|---|---|---|---|---|---|
| `FDatabasisPad` | Privaat veld | `string` | Hou die gevalideerde aktiewe AppData-databasispad | `C:\Users\...\SmartEats.accdb` | `TSmartEatsService` |
| `FBTWKoers` | Privaat veld | `Currency` | Hou die BTW koers vir UI en bestellingberekenings | `0.15` | `TSmartEatsService` |
| `FUiHtml` | Privaat veld | `string` | Hou die geverifieerde ingebedde HTML wat WebView2 laai | Volledige HTML-dokument | `TfrmWebHoof` |
| `FEdge` | Privaat veld | `TEdgeBrowser` | Gasheer die ingebedde UI en boodskapbrug | Dinamiese WebView2 komponent | `TfrmWebHoof` |
| `FLaaiTydhouer` | Privaat veld | `TTimer` | Beperk en monitor WebView2 inisialisering | 15-sekonde gereedheidsgrens | `TfrmWebHoof` |
| `versoekID` | Plaaslik | `string` | Koppel 'n WebView versoek aan presies een antwoord | `req-42` | `OntvangWebboodskap` |
| `klientID` | Plaaslik | `Integer` | Identifiseer die gekose bestaande aktiewe klient | `3` | `StoorBestelling` |
| `itemID` | Plaaslik/rekordveld | `Integer` | Identifiseer 'n spyskaartitem | `8` | Item en bestellingmetodes |
| `hoeveelheid` | Plaaslik/rekordveld | `Integer` | Hou 'n begrensde bestellynhoeveelheid | `2` | `StoorBestelling` |
| `voorraad` | Plaaslik/rekordveld | `Integer` | Hou die  voorraad data wat binne die transaksie herlees word | `24` | `StoorBestelling` |
| `prys` | Plaaslik/rekordveld | `Currency` | Hou die databasis eenheidsprys | `38.00` | `StoorBestelling` |
| `subtotaal` | Plaaslik | `Currency` | Som prys maal hoeveelheid vir alle lyne | `68.00` | `StoorBestelling` |
| `btw` | Plaaslik | `Currency` | Hou die afgeronde belastingbedrag | `10.20` | `StoorBestelling` |
| `totaal` | Plaaslik | `Currency` | Hou subtotaal plus BTW | `78.20` | `StoorBestelling` |
| `punte` | Plaaslik | `Integer` | Hou die lojaliteitspunte wat uit die totaal afgelei word | `78` | `StoorBestelling` |
| `dagBegin` | Plaaslik | `TDateTime` | Ondergrens van 'n plaaslike kalenderdag | `2026-08-03 00:00` | Dashboard en verslagmetodes |
| `dagEinde` | Plaaslik | `TDateTime` | Grens van 'n kalenderdag | `2026-08-04 00:00` | Dashboard en verslagmetodes |
| `transaksieAktief` | Plaaslik | `Boolean` | Bepaal of rollback nog nodig is | `True` | Transaksionele skryfmetodes |
| `soek` | Plaaslik | `string` | Hou die spyskaartsoekwaarde | `Rooibos` | `SkepSpyskaart` |
| `sorteer` | Plaaslik | `string` | Kies 'n SQL-sorteeropsie uit die toegelate opsie lys | `naam` | `SpyskaartSorteerSQL` |

## Aktiewe komponente en koppelvlakelemente

| HTML/VCL-element | WebView-aksie | Delphi-hantering | Doel |
|---|---|---|---|
| `#mainContent` en `[data-view-button]` | Verskillende laaiaksies | `VoerAksieUit` en toepaslike `Skep...` metode | Hoofinhoud en navigasie tussen werkvloeie |
| `#ordersToday`, `#revenueToday`, `#lowStockItems` | `dashboard.refresh` | `SkepDashboard` | Wys vandag se bestellings, omset en lae voorraad |
| `#menuSearch` en `#menuSort` | `menu.load` | `SkepSpyskaart` | Parametergebonde soek en toegelate sortering |
| `#menuRows` en `#menuForm` | `menu.update` | `WysigSpyskaartitem` | Kies en wysig 'n bestaande item |
| `#addItemDialog` | `menu.create` | `VoegSpyskaartitemBy` | Voeg 'n nuwe geldige item by |
| `#confirmDialog` | `menu.confirmDelete` of `history.confirmDelete` | `VerwyderSpyskaartitem` of `VerwyderBestelling` | Verwyder 'n item |
| `#clientDialog` en `#clientForm` | `clients.create` | `VoegKlientBy` | Voeg 'n unieke geldige klient by |
| `#customerSelect` | `orders.load` | `SkepKliente` | Kies 'n bestaande aktiewe klient |
| `#orderType` en `#tableNumber` | `orders.create` | `StoorBestelling` | Verskaf bestellingstipe en voorwaardelike tafelnommer |
| `#orderItems` en `.qty` | `orders.create` | `StoorBestelling` | Kies items en hoeveelhede |
| `#subtotal`, `#vat` en `#total` | Plaaslike voorskou en `orders.create` | Herberekening in `StoorBestelling` | Wys en bevestig finansiële bedrae |
| `#historyRows` | `history.load` | `SkepGeskiedenis` | Wys gekoppelde bestelling en klientdata |
| `#reportDate`, `#generateReport`, `#reportRows` | `reports.generateDaily` | `GenereerDagverslag` | Kies datum en wys gegroepeerde verslagdata |
| `#messageDialog` en `[data-error-summary]` | Foutantwoord | `BouFoutAntwoord` | Wys 'n opsomming, veldfout en herstelaksie |
| `#toastRegion` | Suksesantwoord | Diensmetode se suksesboodskap | Wys kort nie modale terugvoer |
| `dmData.conSmartEats` | Geen direkte UI-aksie | `TdmData.KoppelDatabasis` | Enkele beheerde ADO verbinding |

## Skikkings

| Skikking | Elementtipe | Waar gevul | Verwerking | Waarde |
|---|---|---|---|---|
| `TArray<TBestellynInvoer>` | Rekord met item-ID, hoeveelheid, naam, prys en voorraad | `StoorBestelling` bou een element per JSON bestellyn | Duplikaat-ID's word verwerp; pryse en voorraad word herlees; bedrae word bereken; lyne word gestoor; kwitansie word geskryf | Verwante lynwaardes beweeg saam en voorkom foutgevoelige parallelle skikkings |
| Dinamiese `TVerslagItem` skikking | Rekord met itemnaam, aantal en omset | `GenereerDagverslag` voeg een element per gegroepeerde query by | 'n Geneste sortering rangskik eers volgens hoeveelheid en dan itemnaam | Dieselfde verwerkte data dryf die UI-tabel en die UTF-8-verslag |
| `DAE` | Vaste stringskikking | By kompilering | `DayOfWeek` kies die korrekte Afrikaanse dagnaam | Lewer natuurlike datums sonder herhaalde voorwaardes |
| `MAANDE` | Vaste stringskikking | By kompilering | Maandnommer kies die Afrikaanse maandnaam | Hou datumformatering konsekwent |

## Tekslêers

| Lêer | Databron | Lêernaampatroon en formaat | Fout- en hulpbronhantering | Gebruikerswaarde |
|---|---|---|---|---|
| Kwitansie | Die gecommitteerde bestelling en gevalideerde `TBestellynInvoer` skikking | `Kwitansie-<ID>-<YYYYMMDD-HHMMSS>.txt`; UTF-8; itemlyne en ZAR-totale | `TStringList` word in `try/finally` vrygestel; 'n skryffout word as waarskuwing teruggestuur sonder om die reeds gecommitteerde bestelling uit te vee | Naspeurbare verkoopsbewys |
| Dagverslag | Gegroepeerde SQL en die gesorteerde `TVerslagItem` skikking | `Dagverslag-<YYYYMMDD>.txt`; UTF-8; datum, vaste kolomme, hoeveelheid en omset | Die program probeer die EXE-gids indien skryfbaar en gebruik anders 'n AppData-verslaggids; hulpbronne word in `try/finally` vrygestel | Dagafsluiting en itemontleding |
| Tegniese log | WebView, brug, bootstrap en navigasiegebeure | Tydstempel, kode en kort konteks in die AppData loggids | Elke skryf gebruik 'n kort oop-skryf-sluit siklus en vang diagnostiese foute op | Help om WebView2, resource en verbindingsprobleme te diagnoseer |

## Gebruikergedefinieerde metodes

| Metode | Soort | Parameters | Terugkeerwaarde | Doel en hergebruik |
|---|---|---|---|---|
| `KryPlaaslikeAppDataGids` | Funksie | Geen | `string` | Lewer die enkele masjienonafhanklike basis vir alle skryfbare runtime data |
| `KryAktieweDatabasisPad` | Funksie | Geen | `string` | Skep, valideer of migreer die aktiewe databasis en lewer sy finale pad |
| `OpenDatabasis` | Prosedure | ADO verbinding en databasisdatapad | Geen | Pas ACE 16.0/12.0-fallback konsekwent toe |
| `KoppelDatabasis` | Prosedure | Databasispad | Geen | Open en toets die datamodule se verbinding |
| `SkepNavraag` | Funksie | SQL teks | `TADOQuery` | Skep 'n query met verbinding, tydperk en parameterkontrole op een plek |
| `LeesString` | Funksie | JSON, veldnaam, maksimumlengte en verpligtheid | Gevalideerde `string` | Hergebruik tipe, leegte en lengtevalidering vir teksvelde |
| `LeesHeelgetal` | Funksie | JSON, veldnaam, minimum en maksimum | Gevalideerde `Integer` | Hergebruik heelgetalvalidering |
| `LeesGeld` | Funksie | JSON, veldnaam, minimum en maksimum | Gevalideerde `Currency` | Hergebruik geld en reeksvalidering |
| `SkepDashboard` | Funksie | Geen | `TJSONObject` | Lewer stats/data by inisialisering en elke dashboard refresh |
| `SkepSpyskaart` | Funksie | Soek en sorteerwaarde | `TJSONArray` | Lewer werklike spyskaartdata vir lees, soek en sorteer |
| `StoorBestelling` | Funksie | JSON-payload | `TJSONObject` | Valideer, bereken en stoor 'n volledige bestellingstransaksie |
| `VerwyderBestelling` | Funksie | JSON-payload | `TJSONObject` | Herstel voorraad en punte en verwyder die gekoppelde rekords atomies |
| `GenereerDagverslag` | Funksie | JSON-payload | `TJSONObject` | Transformeer querydata na gesorteerde UI en teksafvoer |
| `BouFoutAntwoord` | Funksie | Versoek-ID, kode, boodskap en veld | JSON-`string` | Gee elke brugfout dieselfde veilige struktuur |

## Naam en omvangbeginsels

Private vormvelde gebruik die `F`-voorvoegsel, soos `FEdge` en `FLaaiTydhouer`.
Plaaslike veranderlikes bly binne die kortste toepaslike metode.
`Currency` word vir geld gebruik, `Integer` vir ID's en hoeveelhede, `Boolean` vir toestande en `TDateTime` vir datums en daggrense.
