# Lucidchart-pariteitsoudit

Die redigeerbare Lucidchart-dokument is uit die aktiewe Delphi-, HTML-, JavaScript-, CSS- en Access-implementering saamgestel.
Die plugin het 15 bladsye geskep en elke bladsy is daarna as PNG uitgevoer en visueel nagegaan.

| Diagramstap | Werklike UI-aksie | WebView-aksie-ID | Delphi-metode | Databasis/tekslêer | Getoets |
|---|---|---|---|---|---|
| Begin en inisialisering | Begin `Project1.exe` | `app.initialize` | `KryAktieweDatabasisPad`, `TdmData.KoppelDatabasis`, `VoerAksieUit` | Ingebedde seed en AppData-ACCDB | Ja: skoon eerste lopie |
| Dashboard laai | Open Dashboard | `app.initialize` | `SkepDashboard` | `tblBestellings`, `tblSpyskaart` | Ja |
| Dashboard verfris | Kies Verfris | `dashboard.refresh` | `SkepDashboard` | Half-oop vandag-reeks | Ja |
| Spyskaart lees/soek/sorteer | Open Spyskaart | `menu.load` | `SkepSpyskaart` | `tblSpyskaart` | Ja |
| Item voeg by | Kies Nuwe item en stoor | `menu.create` | `VoegSpyskaartitemBy` | Parameter-`INSERT` | Ja: grensitem |
| Item wysig | Kies item en stoor verandering | `menu.update` | `WysigSpyskaartitem` | Parameter-`UPDATE` | Ja |
| Item verwyder | Kies Verwyder en bevestig | `menu.confirmDelete` | `VerwyderSpyskaartitem` | Parameter-`DELETE` | Ja |
| Kliënt voeg by | Open kliëntdialoog en stoor | `clients.create` | `VoegKlientBy` | `tblKliente` | Ja |
| Bestelkeuses laai | Open Nuwe bestelling | `orders.load` | `SkepKliente`, `SkepBestelitems` | Kliënt- en itemlees | Ja |
| Bestelling stoor | Kies tipe/items en stoor | `orders.create` | `StoorBestelling` | Vier gekoppelde skrywes in een transaksie; kwitansie | Ja |
| Geskiedenis lees | Open Geskiedenis | `history.load` | `SkepGeskiedenis` | `tblBestellings` plus `tblKliente` | Ja |
| Bestelling verwyder | Kies ry en bevestig | `history.confirmDelete` | `VerwyderBestelling` | Herstel voorraad/punte en verwyder in transaksie | Ja |
| Dagverslag | Kies datum en Genereer | `reports.generateDaily` | `GenereerDagverslag` | Gegroepeerde query, dinamiese skikking, UTF-8-tekslêer | Ja |
| Veilige afsluiting | Kies Sluit en bevestig | `app.requestExit` | `TfrmWebHoof.OntvangWebboodskap` | Geen data-skryf | Ja |

## Bladsye

1. Globale SmartEats-programvloei
2. Inisialisering en databasisverbinding
3. Hoofnavigasie en dashboard
4. Kliënte lees en voeg by
5. Spyskaartitems lys, voeg by, wysig en verwyder
6. Voorraad en herbestelvlak
7. Nuwe bestelling
8. Bestellingstipe en itemkeuse
9. Totale, BTW en finale bestelling
10. Databasisstoor en rollback by fout
11. Daaglikse statistiek
12. Dagverslag en tekslêeruitvoer
13. Algemene datavalidering
14. Algemene fout- en uitsonderingshantering
15. Sluit SmartEats

Die globale bladsy bevat die vorm- en kleurlegende.
Elke besluit gebruik `decision`, elke begin/einde gebruik `terminator`, en databasis-, dokument-, data-, subprocess- en off-page-stappe gebruik hul onderskeie standaardvorme.
