# SmartEats finale E2E-toetsverslag

Toetsdatum: 2026-08-03.
Platform: Windows 64-bit, Delphi 12 Community Edition, WebView2 en Microsoft ACE OLE DB 16.0.

## Bewysgrens

Alle vernietigende funksionele toetse het 'n afgesonderde Debug-toetswortel en 'n gekopieerde/onttrekte ACCDB gebruik.
Die werklike `%LOCALAPPDATA%`-databasis is slegs deur die Release-inisialisering gelees en sy voor/na-hash en tydstempel was identies.
Geen toetsresultaat hieronder is uitgedink of uit 'n nie-uitgevoerde plan afgelei nie.

## Bouresultate

| Konfigurasie | Resultaat | EXE | Grootte | Bewys |
|---|---|---|---:|---|
| Debug Win64 | Sukses, geen boufout in Delphi Messages | `Win64\Debug\Project1.exe` | 18 339 245 grepe | `toetsbewyse\finale-debug-herbou.png` |
| Release Win64 | Sukses, geen boufout in Delphi Messages | `Win64\Release\Project1.exe` | 5 489 664 grepe | `toetsbewyse\finale-release-bou.png` |
| Verspreidingskopie | Byte-identies aan Release | `dist\SmartEats\Project1.exe` | 5 489 664 grepe | SHA-256-vergelyking |

Die Community Edition se los opdragreëlkompileerder het doelbewus geweier om te kompileer.
Die gesaghebbende boue is daarom deur die gelisensieerde Delphi IDE gedoen en visueel as `Success` bevestig.

## Resource- en eerste-lopie-toetse

| ID | Toets | Werklike resultaat | Status |
|---|---|---|---|
| E2E-01 | Vergelyk `SMARTEATS_UI_HTML` met `ui/index.html` | 106 278 grepe en SHA-256 `01262AD2...2FBBEAA` stem byte-vir-byte ooreen | SLAAG |
| E2E-02 | Vergelyk `SMARTEATS_SEED_DB` met seed | 376 832 grepe en SHA-256 `A001213D...6F9945D` stem byte-vir-byte ooreen | SLAAG |
| E2E-03 | Begin Debug met 'n leë toetswortel | `%toetswortel%\SmartEats\data\SmartEats.accdb` is geskep en WebView het gelaai | SLAAG |
| E2E-04 | Herbegin met bestaande toetsdatabasis | Voor/na SHA-256 `B8F880D3...F1C9F34` en tydstempel is identies | SLAAG |
| E2E-05 | Begin finale Release teen werklike AppData | Gekoppel by `C:\Users\User\AppData\Local\SmartEats\data\SmartEats.accdb` | SLAAG |
| E2E-06 | Bewaar werklike AppData tydens Release-inisialisering | Voor/na SHA-256 en tydstempel is identies | SLAAG |

`toetsbewyse\finale-e2e-eerste-lopie.png` en `toetsbewyse\finale-release-loop.png` wys die werklike ingebedde UI en gekoppelde brug.

## Geldige funksionele ketting

| Stap | Databasis-/lêerbewys | Werklike resultaat | Status |
|---|---|---|---|
| Skep kliënt | Kliënttelling 6 na 7; ID 7; selfoon `0612345678` | Nuwe kliënt verskyn en word gekies | SLAAG |
| Skep Wegneem-bestelling | Bestelling-ID 1; een bestellyn; totaal R78,20 | Transaksie commit en UI herlaai | SLAAG |
| Skryf kwitansie | `Kwitansie-1-20260803-072337.txt` | UTF-8-lêer is uit die gecommitteerde bestelling geskryf | SLAAG |
| Genereer dagverslag | `Dagverslag-20260803.txt`, 490 grepe | Gegroepeerde item, hoeveelheid en omset verskyn in UI en teks | SLAAG |
| Verwyder bestelling | Bestellingtelling vir ID 1 is 0; bestellyntelling is 0 | Voorraad en punte is in dieselfde transaksie herstel | SLAAG |

Bewyse is `finale-klient-skep.png`, `finale-bestelling-skep.png`, `finale-dagverslag.png`, `finale-bestelling-verwyder.png` en `finale-Dagverslag-20260803.txt` onder `toetsbewyse`.

## Grens- en CRUD-toetse

| ID | Toetsdata | Werklike resultaat | Status |
|---|---|---|---|
| E2E-07 | Itemnaam `E2E Grensitem`, prys R0,01, voorraad 0, herbestelvlak 0 | Een presiese ry is geskep | SLAAG |
| E2E-08 | Wysig grensitem se naam en voorraad na 1 | Een presiese gewysigde ry is gelees | SLAAG |
| E2E-09 | Bevestig verwydering van grensitem | Geen ry met die grensitemnaam bly oor nie | SLAAG |

Bewyse is `finale-grensitem-skep.png`, `finale-grensitem-wysig.png` en `finale-grensitem-verwyder.png`.

## Ongeldige toetse

| ID | Ongeldige toevoer | Telling voor/na | Werklike UI-resultaat | Status |
|---|---|---|---|---|
| E2E-10 | Leë kliëntnaam, selfoon `123`, e-pos `ongeldig` | Kliënte 6 na 6 | Opsomming en veldfoute; geen `INSERT` | SLAAG |
| E2E-11 | Leë itemnaam, prys 0, voorraad -1, herbestelvlak 100001 | Items 10 na 10 | Presiese reeks-/verpligte veldfoute; geen `INSERT` | SLAAG |
| E2E-12 | Bestelling sonder kliënt, tipe of items | Bestellings 0 na 0 | `Kies 'n aktiewe kliënt uit die lys.`; geen transaksie | SLAAG |

Bewyse is `finale-ongeldige-klient.png`, `finale-ongeldige-item.png` en `finale-ongeldige-bestelling.png`.

## Kalenderdag en databasisintegriteit

`tools\ToetsDaaglikseStatistiek.ps1` het 12 kontroles laat slaag.
Dit sluit net voor middernag, presies op middernag, net na middernag, verskeie bestellings, geen bestellings, handmatige verfris en herbegin in.
`tools\ToetsDatabasis.ps1` het al 27 kontroles op die werklike aktiewe AppData-databasis laat slaag.
Dit dek vyf tabelle, velde, primêre sleutels, unieke indekse, drie vreemde sleutels, metadata, numeriese reëls en weesrekords.

## Visuele en toeganklikheidstoetse

| Viewport/skaal | Meting | Resultaat |
|---|---|---|
| 100% normale groot venster | Werklike Release-skermgreep | Geen afgesnyde hoofinhoud of oorvleueling nie |
| 960 x 700 logiese viewport | Browser-toeganklikheidsboom | Sybalk en alle hoofkontroles bereikbaar |
| 768 x 560 by DPR 1,25 | 125%-ekwivalent | `bodyScrollWidth = bodyClientWidth = 768`; kompakte kop `flex`; sybalk `none` |
| 640 x 467 by DPR 1,5 | 150%-ekwivalent | `bodyScrollWidth = bodyClientWidth = 640`; kompakte kop `flex`; sybalk `none` |
| 800 x 700 smal venster | Toeganklikheidsmomentopname | Al sewe mobiele navigasieknoppies het bereikbare name |

Die statiese browserkontrole het net `file:///.../ui/index.html` versoek en geen netwerk- of consolefout aangeteken nadat die verwagte brug-onbeskikbaar-dialoog gesluit is nie.
Die werklike Delphi-EXE-toetse is die gesaghebbende funksionele bewys omdat hulle die WebView2-brug en Access-databasis insluit.

## Dialoë, fokus en afsluiting

Verwyderaksies het bevestigings vereis.
Die sluitdialoog is in die werklike EXE gesentreer vasgelê en `Sluit veilig` het die proses beëindig.
`toetsbewyse\finale-sluitbevestiging.png` is die visuele bewys.
Foutdialoë gebruik een sigbare fokusraam en 'n duidelike herstelknoppie.

## Finale gevolgtrekking

Alle uitgevoerde finale bou-, resource-, databasis-, normale-, grens-, ongeldige-, visuele en afsluitingstoetse het geslaag.
Die 8 persoonlike onderhoudspunte is nie deur hierdie tegniese toetsverslag geverifieer of as voltooi gemerk nie.
