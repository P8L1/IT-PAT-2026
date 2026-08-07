# SmartEats finale ontwerp-, TVA-, IPO- en toetsplan

Hierdie dokument beskryf die finale geïmplementeerde stelsel.
Dit vervang vorige prototipebeplanning.

## Taakdefinisie

SmartEats los die probleem van los restaurantbestellings, onbetroubare voorraad en handmatige dagtotale op.
Die program is 'n Win64 Delphi VCL-toepassing met 'n ingebedde WebView2-koppelvlak en 'n skryfbare Access-databasis in die gebruiker se plaaslike AppData.
Die toepassing moet klante en spyskaartdata veilig lees, geldige bestellings transaksioneel stoor, voorraad en lojaliteit konsekwent bywerk, en bruikbare daguitsette lewer.
Sukses beteken dat normale werk vinnig voltooi word, ongeldige data geen gedeeltelike skrywes veroorsaak nie, bestaande data oor herbegin behoue bly, en alle belangrike foute 'n duidelike Afrikaanse herstelpad het.

## Gebruikers en gebruikerstories

| Gebruiker | Rol | Aktiwiteit | Waarde |
|---|---|---|---|
| Kassapersoneel | Neem en finaliseer bestellings | Kies kliënt, tipe, tafel, items en hoeveelhede | Korrekte bestelling, BTW en kwitansie sonder handberekening |
| Restaurantbestuurder | Beheer operasionele data | Werk items en voorraad by, lees geskiedenis en genereer dagverslag | Betroubare voorraad- en verkoopsbesluite |

### Gebruikerstories

- As kassapersoneellid wil ek 'n aktiewe kliënt en verkoopbare items kies sodat ek 'n geldige bestelling kan stoor.
- As kassapersoneellid wil ek die subtotaal, BTW en totaal voor stoor sien sodat ek die bedrag kan bevestig.
- As bestuurder wil ek spyskaartitems skep, lees, wysig en verwyder sodat die aanbod en voorraad op datum bly.
- As bestuurder wil ek lae voorraad op die dashboard sien sodat ek betyds kan herbestel.
- As bestuurder wil ek 'n dagverslag vir 'n gekose datum genereer sodat ek hoeveelheid en omset per item kan ontleed.
- As gebruiker wil ek verstaanbare Afrikaanse foutboodskappe sien sodat ek toevoer kan herstel sonder dat data beskadig word.

## Aanvaardingstoetse

| ID | Afleiding | Gegewe | Wanneer | Dan |
|---|---|---|---|---|
| AT-01 | Geldige bestelling | 'n Aktiewe kliënt en item met voorraad bestaan | Die gebruiker stoor een Wegneem-item | Kop en lyn word geskep, voorraad daal, punte styg en totaal is korrek |
| AT-02 | Geen gedeeltelike skryf | 'n Item het onvoldoende voorraad | Die gebruiker probeer 'n te groot hoeveelheid stoor | 'n Afrikaanse fout verskyn en geen bestelling, lyn, voorraad- of puntverandering bly agter nie |
| AT-03 | Spyskaart-CRUD | 'n Unieke geldige itemnaam word ingevoer | Die item word geskep, gewysig en bevestig verwyder | Elke stap persisteer en die tabel herlaai die werklike toestand |
| AT-04 | Kliëntvalidering | 'n Leë naam en ongeldige selfoon word ingevoer | Stoor word gekies | Veldfoute verskyn en geen kliëntry word geskep nie |
| AT-05 | Daggrens | Rye bestaan net voor en op middernag | Die dashboard of verslag vir elke dag word gelaai | Elke ry verskyn slegs in sy korrekte half-oop kalenderdagreeks |
| AT-06 | Eerste lopie | Die aktiewe AppData-ACCDB ontbreek | Die EXE begin | Die geverifieerde ingebedde seed word atomies onttrek en gekoppel |
| AT-07 | Bestaande data | 'n Geldige AppData-ACCDB bestaan | Die EXE begin weer | Die bestaande lêer word gevalideer en nie deur die seed oorskryf nie |
| AT-08 | Verslagafvoer | 'n Bestelling bestaan op die gekose datum | Genereer word gekies | Die UI en UTF-8-tekslêer toon dieselfde gegroepeerde, gesorteerde resultate |

## Beplanning van veranderlikes en komponente

| Naam/tipe | Omvang | Doel | Finale implementering |
|---|---|---|---|
| `Currency` | Plaaslik | Pryse, subtotaal, BTW, totaal en omset sonder algemene binêre-drywende puntgebruik | `uSmartEatsService.pas` |
| `Integer` | Plaaslik | ID's, voorraad, hoeveelheid, punte, tafelnommer en lusindekse | Diens- en UI-laag |
| `Boolean` | Plaaslik/veld | Beskikbaarheid, bevestiging, transaksiestatus en gereedstatus | Bootstrap, diens en WebView |
| `TDateTime` | Plaaslik | Daggrense, bestellingtyd en verslagdatum | Dienslaag |
| `string` | Plaaslik/veld | Name, kategorie, foutkode, JSON en lêerpaaie | Alle aktiewe eenhede |
| `TADOConnection` | Datamodule | Enkele beheerde Access-verbinding | `dmData.conSmartEats` |
| `TADOQuery` | Metode-plaaslik | Parametergebonde lees- en skryfnavrae | `SkepNavraag` |
| `TEdgeBrowser` | Vormveld | Ingebedde produksie-UI en brug | `TfrmWebHoof.FEdge` |
| `TTimer` | Vormveld | WebView-gereedtyd en Debug-bewysvaslegging | `uWebHoof.pas` |

Die dinamiese VCL-komponente gebruik die voorvoegsels `FEdge`, `FLaaiTydhouer` en `FToetsVaslegging` omdat hulle private vormvelde is.
HTML-komponente gebruik betekenisvolle ID's soos `menuRows`, `saveOrder`, `reportDate` en `toastRegion`.

## Beplanning van tekslêers

| Teksuitset | Bron/verwerking | Formaat | Waarde | Fout- en hulpbronhantering |
|---|---|---|---|---|
| Dagverslag | Gegroepeerde SQL, dinamiese skikking en geneste sortering | UTF-8, vaste kolomme, datum en ZAR | Dagafsluiting en itemontleding | `TStringList` met `try/finally`; EXE-gids of AppData-fallback |
| Kwitansie | Gecommitteerde bestelling en gevalideerde bestellynskikking | UTF-8, een lyn per item en totale | Naspeurbare verkoopsbewys | Fout word as waarskuwing teruggestuur sonder om die gecommitteerde bestelling uit te vee |
| Tegniese log | WebView-, brug- en navigasiegebeure | Tydstempel, kode en konteks | Diagnose sonder sensitiewe UI-detail | Kort oop-skryf-sluit-siklus en uitsonderingopvang |

## Beplanning van skikkings

| Skikking | Element | Vulproses | Verwerking | Afvoer |
|---|---|---|---|---|
| `TArray<TBestellynInvoer>` | Rekord met ID, hoeveelheid, naam, prys en voorraad | Een rekord per JSON-bestellyn | Valideer duplikate, herlees databasiswaardes, bereken, stoor en skryf kwitansie | Bestelling en kwitansie |
| Dinamiese `TVerslagItem`-skikking | Rekord met itemnaam, aantal en omset | Een rekord per gegroepeerde queryry | Geneste sortering volgens aantal en itemnaam | UI-verslagtabel en teksverslag |
| `DAE` en `MAANDE` | Stringkonstantes | Kompileertyd | Indeksering uit `TDateTime` | Natuurlike Afrikaanse datum |

Die rekords voorkom foutgevoelige parallelle skikkings omdat verwante waardes saam beweeg.

## Beplanning van gebruikergedefinieerde metodes

| Metode | Parameters | Terugkeerwaarde | Hergebruik/waarde |
|---|---|---|---|
| `KryPlaaslikeAppDataGids` | Geen | Sentrale plaaslike pad | Enkele masjienonafhanklike basis vir alle skryfbare runtime-data |
| `OpenDatabasis` | Verbinding en pad | Geen | ACE 16.0/12.0-fallback en eenvormige verbinding |
| `LeesHeelgetal` | JSON, veldnaam, minimum, maksimum | Gevalideerde `Integer` | Alle begrensde heelgetalvelde |
| `LeesString` | JSON, veldnaam, maksimum, verplig | Gevalideerde `string` | Alle teksvelde |
| `SkepDashboard` | Geen | `TJSONObject` | Inisialisering en handmatige/middernagverfris |
| `SkepSpyskaart` | Soek en sorteer | `TJSONArray` | Inisialisering en spyskaartlaai |
| `StoorBestelling` | JSON-payload | `TJSONObject` | Volledige bestellingstransaksie en antwoord |
| `GenereerDagverslag` | JSON-payload | `TJSONObject` | Datatransformasie, UI-afvoer en tekslêer |
| `BouFoutAntwoord` | Versoek-ID, kode, boodskap en veld | JSON-string | Eenvormige brugfoute |

## Databasisrol en ontwerp

Die Access-databasis is die gesaghebbende bron vir kliënte, spyskaart, voorraad, bestellings, lyne en metadata.
Vyf tabelle skei entiteite en voorkom onnodige herhaling.
Primêre sleutels identifiseer elke ry en vreemde sleutels beskerm verwantskappe.
Unieke indekse beskerm kliëntselfone en itemname.
Historiese `Eenheidsprys`, `Subtotaal`, `BTW` en `Totaal` word doelbewus vasgelê omdat latere prys- of belastingveranderinge nie ou transaksies mag verander nie.

## TVA/IPO: Spyskaart en voorraad

### Toevoer

| Veld | Bron | Datatipe | Formaat/reël | GGK-komponent |
|---|---|---|---|---|
| Itemnaam | Sleutelbord | String | 1..60 karakters, uniek | Teksinvoer |
| Kategorie | Gebruikerkeuse | String | Een van vier vaste waardes | Keuselys |
| Prys | Sleutelbord | Currency | > 0 en <= 1 000 000 | Numeriese teksinvoer |
| Voorraad | Sleutelbord | Integer | 0..100 000 | Getalinvoer |
| Herbestelvlak | Sleutelbord | Integer | 0..100 000 | Getalinvoer |
| Beskikbaar | Gebruikerkeuse | Boolean | Waar/onwaar | Merkblokkie |
| Soek | Sleutelbord | String | Hoogstens 100 karakters | Soekveld |
| Sorteer | Gebruikerkeuse | String | Vaste toelaatlys | Keuselys |

### Verwerking

1. Normaliseer en valideer elke veld op die UI.
2. Herhaal tipe-, lengte-, reeks- en toelaatlysvalidering in Delphi.
3. Bind gebruikerwaardes aan ADO-parameters.
4. Voer die gekose `SELECT`, `INSERT`, `UPDATE` of `DELETE` uit.
5. Herlaai die werklike tabeltoestand en bou 'n JSON-antwoord.

### Afvoer

| Data | Formaat | Komponent |
|---|---|---|
| Itemrekords | Tabel, ZAR-prys, heelgetalle en Ja/Nee | HTML-tabel in WebView2 |
| Seleksiestatus | Afrikaanse teks en gemerkte ry | Statuslyn en `aria-selected` |
| Fout | Opsomming plus veldboodskap | `role="alert"` en veldfout |
| Sukses | Kort Afrikaanse bevestiging | Toast |

## TVA/IPO: Nuwe bestelling

### Toevoer

| Veld | Bron | Datatipe | Formaat/reël | GGK-komponent |
|---|---|---|---|---|
| Kliënt-ID | Access/gebruikerkeuse | Integer | Bestaande aktiewe kliënt | Keuselys |
| Besteltipe | Gebruikerkeuse | String | `Eet-in` of `Wegneem` | Keuselys |
| Tafelnommer | Sleutelbord | Integer | 1..40 vir Eet-in | Getalinvoer |
| Item-ID | Access/gebruikerkeuse | Integer | Bestaande beskikbare item | Merkblokkie per item |
| Hoeveelheid | Sleutelbord | Integer | 1..jongste voorraad | Getalinvoer per item |
| BTW-koers | `tblMetadata` | Currency/Double | Finale metadatawaarde | Geen direkte invoerkomponent |

### Verwerking

1. Verseker dat kliënt, tipe, tafel en minstens een lyn geldig is.
2. Bou 'n dinamiese rekordskikking en verwerp duplikaatitem-ID's.
3. Begin die ADO-transaksie.
4. Herlees pryse, voorraad en beskikbaarheid binne die transaksie.
5. Bereken `Subtotaal = som(Prys * Hoeveelheid)`.
6. Bereken `BTW = Round(Subtotaal * BTWKoers, 2)`.
7. Bereken `Totaal = Subtotaal + BTW` en `Punte = Trunc(Totaal)`.
8. Voeg kop en lyne in en werk voorraad en punte by.
9. Commit alles, of rollback alles by enige fout.
10. Skryf die kwitansie en herlaai dashboard, items, kliënte en geskiedenis.

### Afvoer

| Data | Formaat | Komponent |
|---|---|---|
| Verkoopbare items | Naam, ZAR-prys en voorraad | Kiesbare itemlys |
| Bedrae | ZAR met twee desimale | Opsommingspaneel |
| Bestelling | Tyd, kliënt, tipe, tafel, subtotal, BTW, totaal en status | Geskiedenistabel |
| Kwitansie | UTF-8 vastekolomteks | `.txt`-lêer |
| Fout/sukses | Afrikaans | Dialoog, veldfout of toast |

## TVA/IPO: Dashboard en dagverslag

### Toevoer

| Veld | Bron | Datatipe | Formaat/reël | Komponent |
|---|---|---|---|---|
| Huidige datum | Windows | `TDateTime` | Plaaslike kalenderdag | Outomaties |
| Verslagdatum | Sleutelbord/kalender | `TDateTime` | Geldige `YYYY-MM-DD` | Datuminvoer |
| Bestellings/lyne/items | Access | Verskeie | Geldige gekoppelde rekords | Geen direkte invoerkomponent |

### Verwerking en afvoer

Die dashboard tel en som met 'n half-oop dagreeks.
Die verslag groepeer hoeveelhede en omset per item, bou 'n dinamiese skikking, sorteer dit en skryf UTF-8.
Die UI wys duidelike metrieke, lae voorraad, 'n verslagtafel, totaal, lêernaam en leë toestand.

## Verwerkingsprosesse

Die finale stelsel bevat minstens die volgende werklike prosesse:

1. AppData-padberekening en gidsvorming.
2. SHA-256-resourceverifikasie.
3. Atomiese seed-onttrekking onder 'n benoemde mutex.
4. Skemavalidering en transaksionele migrasie.
5. WebView-boodskapkontrakvalidering en duplikaatantwoordkas.
6. Spyskaartsoek, sortering en CRUD.
7. Kliëntinvoeging met unieke selfoon.
8. Bestellynskikkingvalidasie en duplikaatopsporing.
9. Gesaghebbende bedrag- en BTW-berekening.
10. Transaksionele bestellingstoor met voorraad en punte.
11. Transaksionele bestellingverwydering met herstel van voorraad en punte.
12. Half-oop kalenderdagstatistiek.
13. Gegroepeerde dagverslag en geneste sortering.
14. UTF-8-kwitansie, verslag en tegniese log.

## GGK-plan en bewys

### Spyskaart en voorraad

Die doel is vinnige lees en veilige itemonderhoud deur die bestuurder.
Die skerm gebruik 'n duidelike opskrif, soek en sorteer bo die tabel, selekteerbare rye, 'n aparte wysigingspaneel en bevestiging voor verwydering.
Etikette, verpligte merkers, foutteks, fokusbestuur en sukses-toasts ondersteun gebruiksgemak.

### Nuwe bestelling

Die doel is 'n lineêre werkvloei vir kassapersoneel.
Die skerm volg kliënt, tipe, items/hoeveelhede, opsomming en finale stoor.
Onrelevante tafelinvoer is gedeaktiveer vir Wegneem.
Die opsomming bly sigbaar en die gebruiker kan veilig skoonmaak of stoor.

### Gemeenskaplike beginsels

- Konsekwente donker hoëkontras-styl en betekenisvolle oppervlakgroepering.
- Sigbare sleutelbordfokus met een fokusraam.
- Duidelike navigasiename en huidige-bladsy-aanduiding.
- Responsiewe kompakte navigasie onder 820 logiese pixels.
- `aria-label`, `aria-current`, `aria-invalid`, dialoogfokus en `role="alert"`.
- `prefers-reduced-motion` verminder animasie vir gebruikers wat dit verkies.

## Finale toetsmatriks

| ID | Kategorie | Toetsdata/aksie | Verwagte resultaat | Bewysbron |
|---|---|---|---|---|
| T-01 | Geldig | Skoon Debug-toetswortel | Seed word onttrek en ACCDB koppel | `finale-e2e-eerste-lopie.png` en databasisbestaan |
| T-02 | Geldig | Nuwe kliënt `0612345678` | Kliënttelling 6 na 7 en nuwe ID bestaan | Onafhanklike ADO-navraag |
| T-03 | Geldig | Een Wegneem-item | Kop, een lyn, R78,20-totaal en kwitansie | ADO-navraag en WebView-vaslegging |
| T-04 | Geldig | Genereer huidige dagverslag | Gegroepeerde verslag en tekslêer | `Dagverslag-20260803.txt` en WebView-vaslegging |
| T-05 | Geldig | Verwyder toetsbestelling | Kop en lyne weg; voorraad/punte herstel | ADO-navraag en geskiedenisvaslegging |
| T-06 | Grens | Prys 0,01; voorraad 0; herbestelvlak 0 | Item word aanvaar | Debug-E2E-aksie 11 |
| T-07 | Grens | Net voor/op/na middernag | Korrekte daggroepering | `ToetsDaaglikseStatistiek.ps1` |
| T-08 | Ongeldig | Leë kliëntnaam, selfoon 123, e-pos ongeldig | Veldfoute en geen ry | Debug-E2E-aksie 9 |
| T-09 | Ongeldig | Prys 0, voorraad -1, herbestelvlak 100001 | Veldfoute en geen ry | Debug-E2E-aksie 10 |
| T-10 | Ongeldig | Bestelling sonder kliënt/tipe/items | Duidelike fout en geen transaksie | Debug-E2E-aksie 14 |
| T-11 | Integriteit | Databasisskema en verwantskappe | Al 27 kontroles slaag | `ToetsDatabasis.ps1` |
| T-12 | Resource | Vergelyk EXE-resources byte-vir-byte | UI en seed stem met bronne ooreen | `ToetsIngebeddeHulpbronne.ps1` |
| T-13 | Responsief | 100%, 125%- en 150%-ekwivalente viewports | Geen bladsy-oorloop; kompakte navigasie sigbaar | Browsermetings en skermbewys |

Die persoonlike onderhoud is nie deur hierdie toetsmatriks voltooi of gewaarborg nie.
