# Taak 3: Databasisontwerp

## Doel en ligging

Die Access-databasis is SmartEats se gesaghebbende bron vir metadata, kliente, spyskaartitems, voorraad, bestellings en bestellyne.
Die finale toepassing lees en manipuleer die data deur 64-bit ADO en probeer eers `Microsoft.ACE.OLEDB.16.0` en daarna `Microsoft.ACE.OLEDB.12.0`.
Die aktiewe skryfbare databasis is altyd `%LOCALAPPDATA%\SmartEats\data\SmartEats.accdb`.
Die databasis word as resource in die EXE ingebed, en dan na AppData geskryf. Dit is slegs 'n skoon seed en word nooit binne die EXE gewysig nie.

## Veldontwerp

| Tabel | Veld | Access-datatipe | Grootte | Sleutel | Vereis | Beskrywing en rede |
|---|---|---|---:|---|---|---|
| `tblMetadata` | `Sleutel` | Short Text | 40 | PK | Ja | Unieke naam vir 'n stelselinstelling, byvoorbeeld `BTWKoers` |
| `tblMetadata` | `Waarde` | Short Text | 200 | - | Ja | Hou weergawe en restaurantinstellings in 'n eenvoudige uitbreibare formaat |
| `tblKliente` | `KlientID` | AutoNumber | 4 bytes | PK | Outomaties | Stabiele unieke identifiseerder vir verwysings uit bestellings |
| `tblKliente` | `Naam` | Short Text | 50 | - | Ja | Stoor kwitansienaam van die klient |
| `tblKliente` | `Selfoon` | Short Text | 13 | Unieke indeks | Ja | Kontakwaarde en besigheidsreel wat duplikaatkliente beperk |
| `tblKliente` | `Epos` | Short Text | 100 | - | Nee | Opsionele kontakbesonderheid met formaatreel wanneer dit ingevul is |
| `tblKliente` | `Lojaliteitspunte` | Long Integer | 4 bytes | - | Ja | Gepersisteerde punte wat by bestellings bygewerk word |
| `tblKliente` | `Aktief` | Yes/No | 1 byte | - | Ja | Bepaal of die klient vir nuwe bestellings gekies mag word |
| `tblSpyskaart` | `ItemID` | AutoNumber | 4 bytes | PK | Outomaties | Stabiele unieke identifiseerder vir bestellyne |
| `tblSpyskaart` | `ItemNaam` | Short Text | 20 | Unieke indeks | Ja | Unieke naam wat in lyste, geskiedenis, kwitansies en verslae verskyn |
| `tblSpyskaart` | `Kategorie` | Short Text | 30 | - | Ja | Groepeer die item as voorgereg, hoofgereg, nagereg of drankie |
| `tblSpyskaart` | `Prys` | Currency | 8 bytes | - | Ja | Gesaghebbende huidige eenheidsprys |
| `tblSpyskaart` | `Voorraad` | Long Integer | 4 bytes | - | Ja | Beskikbare hoeveelheid wat transaksioneel verminder en herstel word |
| `tblSpyskaart` | `Herbestelvlak` | Long Integer | 4 bytes | - | Ja | Drempel waarvolgens die dashboard lae voorraad uitlig |
| `tblSpyskaart` | `Beskikbaar` | Yes/No | 1 byte | - | Ja | Bepaal of die item vir nuwe bestellings verkoopbaar is |
| `tblBestellings` | `BestellingID` | AutoNumber | 4 bytes | PK | Outomaties | Unieke bestellingkop-ID vir geskiedenis, lyne en kwitansies |
| `tblBestellings` | `KlientID` | Long Integer | 4 bytes | FK | Ja | Koppel die bestelling aan presies een bestaande klient |
| `tblBestellings` | `DatumTyd` | Date/Time | 8 bytes | Indeks | Ja | Tydstempel vir geskiedenis, dagstatistiek en verslaggrense |
| `tblBestellings` | `Besteltipe` | Short Text | 15 | - | Ja | Onderskei `Eet-in` en `Wegneem` |
| `tblBestellings` | `TafelNommer` | Long Integer | 4 bytes | - | Voorwaardelik | Nodig vir Eet-in en leeg vir Wegneem |
| `tblBestellings` | `Subtotaal` | Currency | 8 bytes | - | Ja | Historiese som voor BTW wat nie deur latere prysveranderinge mag verander nie |
| `tblBestellings` | `BTW` | Currency | 8 bytes | - | Ja | Historiese afgeronde belastingbedrag |
| `tblBestellings` | `Totaal` | Currency | 8 bytes | - | Ja | Finale historiese betaalbedrag vir geskiedenis en omset |
| `tblBestellings` | `Status` | Short Text | 20 | - | Ja | Beskryf die huidige bestellingstoestand |
| `tblBestellyne` | `BestellynID` | AutoNumber | 4 bytes | PK | Outomaties | Unieke identifiseerder vir elke lyn |
| `tblBestellyne` | `BestellingID` | Long Integer | 4 bytes | FK, indeks | Ja | Koppel die lyn aan sy bestellingkop |
| `tblBestellyne` | `ItemID` | Long Integer | 4 bytes | FK, indeks | Ja | Koppel die lyn aan die oorspronklike spyskaartitem |
| `tblBestellyne` | `Hoeveelheid` | Long Integer | 4 bytes | - | Ja | Aantal eenhede wat vir die item verkoop is |
| `tblBestellyne` | `Eenheidsprys` | Currency | 8 bytes | - | Ja | Historiese prys tydens verkoop sodat latere itempryse ou verkope nie verander nie |

Daar is 29 doelgerigte velde oor vyf tabelle.
`Eenheidsprys`, `Subtotaal`, `BTW` en `Totaal` word doelbewus gestoor omdat hulle historiese transaksiewaardes is en nie uit veranderbare huidige pryse herbereken moet word nie.

## Sleutels, verwantskappe en indekse

| Verwantskap | Kardinaliteit | Integriteitsdoel |
|---|---|---|
| `tblKliente.KlientID` na `tblBestellings.KlientID` | Een-tot-baie | Geen bestelling mag na 'n ontbrekende klient verwys nie |
| `tblBestellings.BestellingID` na `tblBestellyne.BestellingID` | Een-tot-baie | Elke bestellyn behoort aan presies een bestelling |
| `tblSpyskaart.ItemID` na `tblBestellyne.ItemID` | Een-tot-baie | Elke bestellyn verwys na 'n geldige spyskaartitem |

`UX_tblKliente_Selfoon` maak selfone uniek en `UX_tblSpyskaart_ItemNaam` maak itemname uniek.
`DatumTyd`, `KlientID`, `BestellingID` en `ItemID` het addisionele indekse om algemene geskiedenis-, verslag- en koppelnavrae te ondersteun.

## CRUD-bewerkings per tabel

| Tabel | Skep | Lees | Wysig | Verwyder |
|---|---|---|---|---|
| `tblMetadata` | Seed of beheerde migrasie | BTW, restaurantnaam en skemaweergawe | Slegs beheerde migrasie | Nie 'n gebruikersfunksie nie |
| `tblKliente` | `VoegKlientBy` | `SkepKliente`, geskiedenis en bestellings | Lojaliteitspunte word binne bestellingstransaksies bygewerk | Geen gebruikersverwydering word in die finale omvang ingesluit nie. Dit is nie die moeite werd nie weens die dataintegriteitsrisiko’s wat dit kan veroorsaak.|
| `tblSpyskaart` | `VoegSpyskaartitemBy` | Dashboard, `SkepSpyskaart`, bestelitems en verslae | `WysigSpyskaartitem` en voorraadopdaterings | `VerwyderSpyskaartitem`, onder verwysingsbeheer |
| `tblBestellings` | `StoorBestelling` | Dashboard en `SkepGeskiedenis` | Transaksionele status/verwante verwerking waar toepaslik | `VerwyderBestelling` |
| `tblBestellyne` | `StoorBestelling` | Kwitansie, geskiedenisberekening en dagverslag | Geen los gebruikerswysiging nie | Saam met `VerwyderBestelling` |

Die spyskaartitemwerkvloei demonstreer die volledige skep, lees, wysig en verwyderlewensiklus.
Klientwysiging is nie as 'n gebruikerskoppelvlakfunksie voorgegee nie.

## Parametergebonde SQL

Alle gebruikerwaardes word met ADO-parameters gebind en nie deur stringsaamvoeging in SQL geplaas nie.
`TdmData.SkepNavraag` skep queries met die sentrale verbinding, `ParamCheck = True` en konsekwente opdragtydperke.
Sorteringskolomme kan nie as parameters gebind word nie en word daarom slegs uit `SpyskaartSorteerSQL` se vaste toelaatlys gekies.

## Transaksies en data-integriteit

`StoorBestelling` begin een ADO-transaksie voordat pryse, beskikbaarheid en voorraad herlees word.
Die bestelling, elke bestellyn, voorraadvermindering en lojaliteitspuntverhoging word saam gecommit.
Enige fout veroorsaak rollback, dus kan geen gedeeltelike bestelling agterbly nie.
`VerwyderBestelling` herstel voorraad en punte en verwyder die gekoppelde lyne binne een transaksie.

> Die databasis het vyf primêre sleutels, drie foreign sleutels en twee unieke indekse.

## Seed en bestaande gebruikersdata

`resources\SmartEats.seed.accdb` is 'n onveranderlike eerste aanvangbron wat in resource `SMARTEATS_SEED_DB` binne die EXE ingebed word.
Wanneer `%LOCALAPPDATA%\SmartEats\data\SmartEats.accdb` ontbreek, word die seed onder 'n benoemde mutex na 'n tydelike lêer onttrek, geflush, gehash en atomies na die finale naam verskuif.
Wanneer 'n bestaande databasis teenwoordig is, word dit gevalideer en waar nodig met 'n rugsteun en transaksie gemigreer.
Die seed oorskryf nooit 'n bestaande databasis nie.
