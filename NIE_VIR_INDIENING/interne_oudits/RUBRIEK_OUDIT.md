# SmartEats finale nie-onderhoudsrubriekoudit

Amptelike basis: Graad 11 IT PAT 2026, Take 1 tot 10.
Nie-onderhoudsmaksimum: 142 punte.
Persoonlike onderhoud: afsonderlike 8 punte en nie hier as voltooi gemerk nie.

`MAKSIMUM_BEWYS` beteken dat die maksimum beskrywing deur die finale implementering, presiese dokumentasie en 'n herhaalbare toets of konkrete dokumentbewys ondersteun word.
Dit is 'n bewysklassifikasie en nie 'n puntwaarborg nie.

| ID | Taak | Rubriekvereiste | Maksimum vlak | Punte | Implementeringsplek | Dokumentasiebewys | Toets | Werklike resultaat | Status |
|---|---|---|---|---:|---|---|---|---|---|
| T1.1 | 1 | Taakdefinisie | Probleem, doel, omvang en suksesmaatstaf is volledig en toepaslik | 4 | Finale SmartEats-stelsel | `ONTWERP_EN_TOETSPLAN.md`: Taakdefinisie; `PROJEKNOTAS.md` 1-5 | Vergelyk vier aspekte met aktiewe funksies | Al vier stem met die finale stelsel ooreen | MAKSIMUM_BEWYS |
| T1.2 | 1 | Gebruikertipes | Minstens twee gebruikers met rol, aktiwiteit en waarde | 4 | Bedienings- en bestuurswerkvloeie | `ONTWERP_EN_TOETSPLAN.md`: Gebruikers; `PROJEKNOTAS.md` 3 | Karteer elke rol na bereikbare UI-vloei | Kassapersoneel en bestuurder het onderskeibare rolle en waarde | MAKSIMUM_BEWYS |
| T1.3 | 1 | Aanvaardingstoetse | Minstens vyf duidelike toetse uit gebruikerstories | 4 | Finale funksionele vloei | `ONTWERP_EN_TOETSPLAN.md`: AT-01 tot AT-08 | Voer normale, grens-, fout-, eerste-lopie- en verslagtoetse uit | Agt stories-afgeleide toetse met konkrete resultate bestaan | MAKSIMUM_BEWYS |
| T2.1 | 2 | Veranderlikes en komponente | Uitstekende relevante beplanning wat met implementering ooreenstem | 4 | Alle aktiewe `.pas`/`.dfm` en `ui/index.html` | Beplanningstabel in `ONTWERP_EN_TOETSPLAN.md` | Vergelyk tipe, omvang, doel en werklike naam | Currency, Integer, Boolean, TDateTime, string, ADO, WebView en tydhouers stem ooreen | MAKSIMUM_BEWYS |
| T2.2 | 2 | Tekslêers | Relevante beplanning van lees/skryf/byvoeg en waarde | 4 | `SkryfKwitansie`, `GenereerDagverslag`, `SkryfTegnieseLog` | Tekslêertabel in `ONTWERP_EN_TOETSPLAN.md` | Genereer kwitansie, dagverslag en log | Werklike UTF-8-uitsette en log is geskryf | MAKSIMUM_BEWYS |
| T2.3 | 2 | Skikkings | Uitstekende relevante skikkingbeplanning | 4 | `TBestellynInvoer`, `TVerslagItem`, `DAE`, `MAANDE` | Skikkingstabel in `ONTWERP_EN_TOETSPLAN.md` | Skep bestelling en dagverslag | Dinamiese rekordskikkings word gevul, verwerk en uitgevoer | MAKSIMUM_BEWYS |
| T2.4 | 2 | Gebruikergedefinieerde metodes | Relevante metodes met parameters/terugkeerwaardes en geen beplande fopfunksie | 4 | Bootstrap-, diens-, data- en WebView-eenhede | Metodetabel in `ONTWERP_EN_TOETSPLAN.md` | Bronoudit teen elke beplande metode | Alle genoemde metodes bestaan en word aktief aangeroep | MAKSIMUM_BEWYS |
| T3.1 | 3 | Databasisrol en velde | Alle toepaslike velde dra by; geen onnodige berekenbare veld | 3 | Vyf Access-tabelle | `PROJEKNOTAS.md` 24; `ONTWERP_EN_TOETSPLAN.md`: Databasisrol | ADOX-skema-oudit en veldrede-teënbewys | 29 doelgerigte velde; historiese finansiële velde is gemotiveer | MAKSIMUM_BEWYS |
| T3.2 | 3 | Veldtipes en -groottes | Korrekte, konsekwente Access-tipes en toepaslike groottes | 3 | `resources\SmartEats.seed.accdb`; `tools\SkepDatabasis.ps1` | Datatabelle en TVA-veldreëls | `ToetsDatabasis.ps1` plus ADOX | Alle verwagte kolomme en numeriese reëls slaag | MAKSIMUM_BEWYS |
| T3.3 | 3 | Tabelle en primêre sleutels | Minstens twee toepaslike tabelle met korrekte sleutels | 3 | `tblMetadata`, `tblKliente`, `tblSpyskaart`, `tblBestellings`, `tblBestellyne` | `PROJEKNOTAS.md` 24 | ADOX-kontrole van vyf primêre sleutels | Vyf tabelle en vyf primêre sleutels is bevestig | MAKSIMUM_BEWYS |
| T3.4 | 3 | Verwantskappe | Duidelike, korrekte en gebruikte verwantskappe | 3 | Drie vreemde sleutels en gekoppelde diensnavrae | Databasisontwerp in beide sentrale dokumente | ADOX plus drie weesrekordnavrae | Al drie FK's bestaan; geen weesrekord nie | MAKSIMUM_BEWYS |
| T4.1 | 4 | Vloeidiagram | Uitstekende volledige begin-, navigasie-, besluit-, alternatief-, fout-, kansellasie-, sukses- en afsluitvloei | 4 | Lucid-dokument `424408a5-29e3-488d-aa2e-c9dd6f1db212` | `LUCIDCHART_PARITEIT.md`; 15 PNG's | Visuele inspeksie van alle bladsye en pariteitsoudit | Globale plus 14 subprocessbladsye gebruik standaardvorms en gekoppelde paaie | MAKSIMUM_BEWYS |
| T5.1 | 5 | Toevoerontwerp | Minstens twee hoofkoppelvlakke; bron, tipe, formaat en komponent vir alle relevante toevoer | 4 | Spyskaart/voorraad en nuwe bestelling | Drie TVA/IPO-afdelings in `ONTWERP_EN_TOETSPLAN.md` | Vergelyk elke veld met `ui/index.html` en Delphi-lesers | Alle finale toevoervelde en komponente stem ooreen | MAKSIMUM_BEWYS |
| T5.2 | 5 | Validering | Minstens vier datatipes en vier velde met duidelike foutboodskappe | 4 | JavaScript-validatorregister en `LeesString/Bool/Geld/Heelgetal/Datum` | TVA-tabelle en `PROJEKNOTAS.md` 23 | Ongeldige kliënt, item en bestelling | String, Integer, Currency/Double, Boolean en DateTime word met veldfoute hanteer | MAKSIMUM_BEWYS |
| T5.3 | 5 | Verwerkingsprosesse | Minstens agt relevante werklike prosesse | 4 | Bootstrap, brug, dienslaag en verslag | Lys van 14 prosesse in `ONTWERP_EN_TOETSPLAN.md` | Spoor elke proses na aktiewe metode en E2E waar toepaslik | Veertien nie-kunsmatige prosesse bestaan | MAKSIMUM_BEWYS |
| T5.4 | 5 | Algoritmes/formules | Duidelike algoritmes of formules vir minstens vier prosesse | 4 | Seed, bestelling, daggrens en verslag | `PROJEKNOTAS.md` 19 en 30; TVA-verwerking | Hash/seed, bedrag, middernag en sorteringstoetse | Vier kernalgoritmes is geïmplementeer en getoets | MAKSIMUM_BEWYS |
| T5.5 | 5 | Afvoerontwerp | Minstens twee hoofkoppelvlakke; data, formaat en komponent; volle TVA-pariteit | 4 | Dashboard, spyskaart, bestelling, geskiedenis, verslag en tekslêers | TVA-afvoertabelle | Vergelyk UI/teks met JSON en databasis | ZAR, datums, getalle, tabelle, state en lêers stem ooreen | MAKSIMUM_BEWYS |
| T6.1 | 6 | GGK-hoofkoppelvlak 1 | Doel, gebruiker, beginsels, vloei, navigasie, dialoog, foute en komponente | 3 | Spyskaart en voorraad | GGK-plan; `UI_FUNKSIONELE_PARITEIT.md` | Werklike EXE normale/grens/ongeldige itemtoetse | Duidelike tabel, vorm, bevestiging, foute, fokus en toast | MAKSIMUM_BEWYS |
| T6.2 | 6 | GGK-hoofkoppelvlak 2 | Doel, gebruiker, beginsels, vloei, navigasie, dialoog, foute en komponente | 3 | Nuwe bestelling | GGK-plan; `UI_FUNKSIONELE_PARITEIT.md` | Werklike EXE bestelling- en skaaltoetse | Logiese kliënt-tipe-item-totaal-stoorvloei is responsief en verstaanbaar | MAKSIMUM_BEWYS |
| T7.1 | 7 | Tabel-/veldontwerp en koppeling | Gepaste name, groottes, tipes, ADO en korrekte tabelkoppeling | 3 | `uDataModule`, seed en diensnavrae | `PROJEKNOTAS.md` 9 en 24; TVA | 27 databasis-/integriteitskontroles | ACE 16.0, skema, sleutels en data-integriteit slaag | MAKSIMUM_BEWYS |
| T7.2 | 7 | Betroubare masjienonafhanklike verbinding en persistensie | Sentrale AppData-pad, atomiese seed, geen oorskryf, validering, migrasie en persistensie | 3 | `uSmartEatsBootstrap.pas`; `TdmData.KoppelDatabasis` | `PACKAGING_EN_BOOTSTRAP.md` | Skoon eerste lopie, bestaande DB-herbegin, Release-AppData en hashvergelyking | Onttrekking werk; bestaande toets- en werklike DB-hashes bly onveranderd | MAKSIMUM_BEWYS |
| T8.1 | 8 | Veranderlikes en komponente | Toepaslike verskeidenheid, omvang, name en voorvoegsels | 4 | Alle aktiewe Delphi-eenhede en dinamiese komponente | `PROJEKNOTAS.md` 28-29; beplanningstabel | Bronoudit en suksesvolle Debug/Release-bou | Sterk tipes, lokale/private velde en konsekwente name is korrek | MAKSIMUM_BEWYS |
| T8.2 | 8 | Tekslêers | Effektiewe, uitstekende, relevante lees/skryf/byvoeg met veilige hulpbronne | 4 | `SkryfKwitansie`, `GenereerDagverslag`, `SkryfTegnieseLog` | `PROJEKNOTAS.md` 21 en 27 | Werklike kwitansie, 490-greep dagverslag en log | Drie waardevolle teksuitsetpaaie werk met `try/finally` | MAKSIMUM_BEWYS |
| T8.3 | 8 | Skikkings | Effektiewe, betekenisvolle skikkinggebruik en verwerking | 4 | `TArray<TBestellynInvoer>`, dinamiese `TVerslagItem`, datumkonstantes | `PROJEKNOTAS.md` 26 | Bestelling plus verslag | Rekordskikkings dryf berekening, stoor, sortering en uitsette | MAKSIMUM_BEWYS |
| T8.4 | 8 | Gebruikergedefinieerde metodes | Relevante herbruikbare prosedures/funksies met parameters en terugkeerwaardes | 4 | Bootstrap-, data-, diens- en WebView-klasse | `PROJEKNOTAS.md` 28 | Bronoproepgrafiek en alle E2E-vloeie | Modulêre metodes word oor inisialisering, laai, validering en skryf hergebruik | MAKSIMUM_BEWYS |
| T8.5 | 8 | Toevoerdata | Verskillende bronne, korrekte tipes/formate en toepaslike kontroles | 4 | HTML-invoer, Access, metadata, Windows-datum en JSON-skikkings | TVA/IPO en `PROJEKNOTAS.md` 23 | Geldige, grens- en ongeldige E2E | Sleutelbord, keuses, databasis, stelseldatum en skikkingtoevoer werk korrek | MAKSIMUM_BEWYS |
| T8.6 | 8 | Algoritmekorrektheid en verwerking | Alle vereistes, grense en fouttoestande korrek | 4 | Bestelling, dashboard, bootstrap en verslag | Algoritme-afdelings | Normale ketting, 12 daggrense, grensitem en drie ongeldige gevalle | Verwagte en werklike resultate stem ooreen | MAKSIMUM_BEWYS |
| T8.7 | 8 | Algoritmedoeltreffendheid | Modulêr, goeie tegnieke, geen vermybare duplisering/herhaalde DB-werk | 4 | Dienslaag, queryfabriek, enkele inisialiseringsantwoord en SQL-aggregasie | Onderhoudsnotas en metodebeplanning | Teënbewys vir N+1, duplisering en ongebinde SQL | Gegroepeerde SQL, metodehergebruik, kas en transaksies is doelmatig | MAKSIMUM_BEWYS |
| T8.8 | 8 | Relevante komplekse kode | Minstens een betekenisvolle gevorderde konstruksie | 4 | Dinamiese WebView/tydhouers, rekords, generiese woordeboek, mutex, transaksies, geneste sortering | `PROJEKNOTAS.md` 29 | E2E-, resource-, duplikaat- en verslagpaaie | Verskeie korrekte komplekse konstruksies voeg werklike waarde by | MAKSIMUM_BEWYS |
| T8.9 | 8 | Afvoer | Nuttig, duidelik, leesbaar, korrek geformateer en geskik | 4 | Dashboard, tabelle, dialoë, toasts, verslag en kwitansie | TVA-afvoer; skermbewyse | Visuele inspeksie en databasis-/lêervergelyking | ZAR, datums, getalle, state en lêers is duidelik en korrek | MAKSIMUM_BEWYS |
| T8.10 | 8 | Verwyder rekord(s) | Verwydering word toegepas | 2 | `VerwyderSpyskaartitem`, `VerwyderBestelling` | CRUD- en transaksiedokumentasie | Grensitem en bestelling bevestig verwyder | Navrae lees nul rye ná verwydering | MAKSIMUM_BEWYS |
| T8.11 | 8 | Voeg rekord(s) in | Invoeging word toegepas | 2 | `VoegSpyskaartitemBy`, `VoegKlientBy`, `StoorBestelling` | CRUD-dokumentasie | Grensitem, kliënt en bestelling | Presiese nuwe rye en ID's is gelees | MAKSIMUM_BEWYS |
| T8.12 | 8 | Wysig rekord(s)/velde | Geselekteerde verandering word toegepas | 2 | `WysigSpyskaartitem`; voorraad- en punt-`UPDATE`s | CRUD-dokumentasie | Grensitemwysiging en bestellingstransaksie | Gewysigde naam/voorraad plus gekoppelde opdaterings is bewys | MAKSIMUM_BEWYS |
| T8.13 | 8 | Valideer by invoeg/wysiging | Veldvalidering blokkeer ongeldige skrywes | 2 | JS-validatorregister en Delphi-lesers | TVA-validering | Ongeldige kliënt en item met voor/na-tellings | Geen ry is bygevoeg nie; presiese foute is gewys | MAKSIMUM_BEWYS |
| T8.14 | 8 | Lees/bekyk rekords en velde | Geselekteerde nuttige data word gelees en gewys | 2 | `SkepDashboard`, `SkepSpyskaart`, `SkepKliente`, `SkepGeskiedenis` | UI-pariteitsmatriks | Werklike EXE op elke hoofskerm | Access-data verskyn in toepaslike tabelle, lyste en metrieke | MAKSIMUM_BEWYS |
| T8.15 | 8 | Navigeer rekords met metodes | Eerste, volgende, vorige en laaste navigasie | 2 | Inline JS `R`, `A` en `P` oor die gelaaide rekordstel | `PROJEKNOTAS.md` 25; UI-13 | Aktiveer die vier knoppies op spyskaart/geskiedenis | Metodes begrens bladsy-indeks en herteken die korrekte rekordsubset | MAKSIMUM_BEWYS |
| T8.16 | 8 | Verslag/tekslêer ná datatransformasie | Minstens een verwerkte verslag- of teksuitset | 2 | `GenereerDagverslag` | TVA/IPO en `PROJEKNOTAS.md` 21 | Genereer verslag met een bestelling | Gegroepeerde, gesorteerde UI en UTF-8-lêer van 490 grepe is geskep | MAKSIMUM_BEWYS |
| T9.1 | 9 | Validering, foutopvang en boodskappe | Verskeidenheid relevante validering, uitsonderings en duidelike Afrikaans | 4 | UI-validatorregister, `ESmartEatsFout`, brug- en transaksieopvang | `PROJEKNOTAS.md` 23; `WEBVIEW_BRUG.md` | Drie ongeldige E2E-gevalle, skema/resource-negatiewe bronpaaie | Geen ongeldige skryf nie; veilige veld-/dialoogboodskappe | MAKSIMUM_BEWYS |
| T9.2 | 9 | Toetsing | Betekenisvolle geldige, grens- en ongeldige uitvoerbare toetse met resultate | 4 | Debug-toetshake, PowerShell-toetse en werklike EXE | `E2E_TOETSVERSLAG.md`; TVA-toetsmatriks | Normale ketting, grensitem, 12 daggrense, 27 DB-kontroles, drie ongeldige gevalle | Alle aangetekende finale toetse het geslaag | MAKSIMUM_BEWYS |
| T10.1 | 10 | Kommentaar en projeknotas | Nodige kode volledig en nuttig geannoteer; uitstekende uitgebreide notas | 4 | Kommentaar in aktiewe `.pas`; `PROJEKNOTAS.md` | 38 ASCII-skoon afdelings plus bronkommentaar | Bronoudit en masjien-ASCII-kontrole | Kommentaar verduidelik waarom; 380 reëls en nul nie-ASCII-karakters | MAKSIMUM_BEWYS |
| T10.2 | 10 | Omvattendheid en insig | Omvattende werkende program wat Fase 1 oorskry en insig toon | 4 | Volle Delphi/WebView/Access-oplossing | Alle finale dokumente, Lucidchart en manifest | Debug/Release, werklike EXE, CRUD, transaksies, verslag, bootstrap en teenbewyspas | Finale elemente funksioneer soos gedokumenteer | MAKSIMUM_BEWYS |

## Rekonsiliasie

| Taak | Maksimum | Bewysbaar in hierdie oudit |
|---|---:|---:|
| Taak 1 | 12 | 12 |
| Taak 2 | 16 | 16 |
| Taak 3 | 12 | 12 |
| Taak 4 | 4 | 4 |
| Taak 5 | 20 | 20 |
| Taak 6 | 6 | 6 |
| Taak 7 | 6 | 6 |
| Taak 8 | 50 | 50 |
| Taak 9 | 8 | 8 |
| Taak 10, nie-onderhoud | 8 | 8 |
| **Totaal** | **142** | **142** |

Statusrye: 41 `MAKSIMUM_BEWYS`, 0 `GEDEELTELIK`, 0 `ONTBREEK`, 0 `GEBLOKKEER`.
Die berekende 142/142 is 'n tegniese bewystelling teen die amptelike nie-onderhoudskriteria, nie 'n waarborg van die nasiener se punt nie.
Die afsonderlike 8 onderhoudspunte bly vir die leerder se persoonlike verifikasie.
