# Taak 9: Formele toetsverslag

## Doel en toetsgrens

Hierdie verslag bevat slegs toetse wat werklik teen die finale SmartEats-bron, 'n geboude EXE, 'n geïsoleerde toetsdatabasis of die aktiewe leesbeveiligde AppData-databasis uitgevoer is.
Vernietigende CRUD-toetse is teen 'n afgesonderde Debug-databasis uitgevoer en nie teen die gebruiker se produksiedata nie.
Rou skermgrepe, masjienuitvoer en toetsskopiee is vir oudit onder `NIE_VIR_INDIENING\rou_toetsbewyse` behou, maar vorm nie deel van die formele skriftelike indiening nie.

## Toetsresultate

| Toets-ID | Funksie | Waarom | Toetstipe | Invoer of aksie | Verwagte resultaat | Werklike resultaat | Status | Bewysverwysing |
|---|---|---|---|---|---|---|---|---|
| T9-01 | Eerste aanvang | Bewys veilige installasie sonder los databasis | Normaal | Begin Debug met 'n leë geïsoleerde toetswortel | Seed word geverifieer, atomies onttrek en gekoppel | ACCDB is geskep en die ingebedde UI het met 'n gekoppelde brug gelaai | SLAAG | `finale-e2e-eerste-lopie.png` |
| T9-02 | Bestaande databasis | Bewys persistensie en geen seed-oorskryf | Herbegin | Begin weer met die bestaande toetsdatabasis | Lêerinhoud en tydstempel bly onveranderd | Voor/na SHA-256 en tydstempel was identies | SLAAG | Hashvergelyking in rou E2E-verslag |
| T9-03 | Kliënt skep | Bewys geldige invoeging | Normaal | Geldige naam, selfoon `0612345678` en e-pos | Een nuwe klient word geskep en beskikbaar vir bestelling | Kliënttelling het van 6 na 7 verander en ID 7 is gelees | SLAAG | `finale-klient-skep.png` |
| T9-04 | Kliëntvalidering | Bewys dat ongeldige toevoer nie skryf nie | Ongeldig | Leë naam, selfoon `123`, e-pos `ongeldig` | Veldfoute en geen `INSERT` | Kliënttelling het 6 gebly en presiese veldfoute het verskyn | SLAAG | `finale-ongeldige-klient.png` |
| T9-05 | Item skep | Bewys minimum geldige numeriese grens | Grens | Naam `E2E Grensitem`, prys R0,01, voorraad 0, herbestelvlak 0 | Presies een item word aanvaar | Een presiese databasisry is gelees | SLAAG | `finale-grensitem-skep.png` |
| T9-06 | Item wysig | Bewys geselekteerde rekordwysiging | Normaal/grens | Verander grensitem se naam en voorraad na 1 | Presies die gekose item verander | Een presiese gewysigde ry is gelees | SLAAG | `finale-grensitem-wysig.png` |
| T9-07 | Item verwyder | Bewys bevestigde verwydering | Normaal | Bevestig verwydering van die grensitem | Die item bestaan nie meer nie | Geen ry met die toetsnaam het oorgebly nie | SLAAG | `finale-grensitem-verwyder.png` |
| T9-08 | Itemvalidering | Bewys tipe- en reeksfoute | Ongeldig | Leë naam, prys 0, voorraad -1, herbestelvlak 100001 | Veldfoute en geen `INSERT` | Itemtelling het 10 gebly en elke reeksfout is gewys | SLAAG | `finale-ongeldige-item.png` |
| T9-09 | Bestelling skep | Bewys volledige normale transaksie | Normaal | Aktiewe klient, Wegneem en een verkoopbare item | Kop, lyn, voorraad, punte, bedrae en kwitansie stem ooreen | Bestelling-ID 1, een lyn en totaal R78,20 is bevestig | SLAAG | `finale-bestelling-skep.png` |
| T9-10 | Leë bestelling | Bewys verpligte seleksies | Ongeldig | Geen klient, tipe of items | Duidelike fout en geen transaksie | Bestellingstelling het 0 gebly en `Kies 'n aktiewe kliënt uit die lys.` is gewys | SLAAG | `finale-ongeldige-bestelling.png` |
| T9-11 | Bestelling verwyder | Bewys gekoppelde hersteltransaksie | Normaal | Bevestig verwydering van toetsbestelling 1 | Lyne en kop verdwyn; voorraad en punte word herstel | Kop- en lyne-tellings was albei 0 na verwydering | SLAAG | `finale-bestelling-verwyder.png` |
| T9-12 | Bedrae en BTW | Bewys gesaghebbende finansiële berekening | Normaal | Een lyn met databasisprys wat R68,00 subtotaal lewer | BTW R10,20 en totaal R78,20 | UI en gestoor bestelling het R68,00, R10,20 en R78,20 getoon | SLAAG | `finale-bestelling-skep.png` |
| T9-13 | Dagverslag | Bewys dat afvoer uit datatransformasie kom | Normaal | Genereer verslag vir 2026-08-03 met een bestelling | Gegroepeerde item, hoeveelheid, omset en UTF-8-lêer | UI en 490-greep `Dagverslag-20260803.txt` het ooreengestem | SLAAG | `finale-dagverslag.png` en `finale-Dagverslag-20260803.txt` |
| T9-14 | Datum-/middernaggrens | Voorkom verkeerde daggroepering | Grens | Rye net voor, presies op en net na middernag | Elke ry val slegs in sy korrekte half-oop dagreeks | Al 12 datum-, nuldata-, verfris- en herbeginkontroles het geslaag | SLAAG | `ToetsDaaglikseStatistiek.ps1`-uitvoer |
| T9-15 | Databasisintegriteit | Bewys skema, sleutels en verwantskappe | Integriteit | Oudit die werklike aktiewe AppData-ACCDB | Alle verwagte tabelle, velde, sleutels, indekse en verhoudings bestaan; geen weesrekords nie | Al 27 kontroles het met ACE OLE DB 16.0 geslaag | SLAAG | `ToetsDatabasis.ps1`-uitvoer |
| T9-16 | EXE-resources | Bewys dat produksie nie los UI- of seedlêers benodig nie | Resource | Vergelyk Debug en Release se RCDATA byte-vir-byte met die bronne | UI en seed stem presies ooreen | Beide EXE's se UI- en seed-grepe en SHA-256 het ooreengestem | SLAAG | `ToetsIngebeddeHulpbronne.ps1`-uitvoer |
| T9-17 | Responsiewe UI | Bewys bruikbaarheid op normale en kompakte uitleg | Visueel/grens | 960 x 700, 800 x 700, DPR 1,25 en DPR 1,5-ekwivalente viewports | Geen horisontale oorloop; kompakte navigasie bly benoem en bereikbaar | Breedtes het ooreengestem en al sewe mobiele navigasieknoppies was bereikbaar | SLAAG | Browsermetings en finale UI-skermgrepe |
| T9-18 | Veilige afsluiting | Bewys dat afsluiting bevestig en voltooi | Normaal/kansellasie | Kies Sluit SmartEats en bevestig | Gesentreerde dialoog en prosesbeëindiging sonder data-skryf | Dialoog is vasgelê en die proses het veilig geëindig | SLAAG | `finale-sluitbevestiging.png` |

## Normale, grens- en ongeldige dekking

Normale data word deur kliëntinvoeging, itemwysiging, bestellingstoor, bestellingverwydering, dagverslag en veilige afsluiting gedek.
Grensdata word deur R0,01, nulvoorraad, nulherbestelvlak, middernag en klein/geskaalde viewports gedek.
Ongeldige data word deur die klient-, item- en leëbestellingstoetse gedek, met databasisvoor/na-tellings wat bewys dat geen ry geskryf is nie.

## Foutopvang en gebruikersboodskappe

Die UI wys veldspesifieke foutteks, merk ongeldige velde met `aria-invalid` en skuif fokus na 'n herstelbare plek.
Delphi herhaal elke kritieke tipe-, reeks-, formaat-, duplikaat- en verwantskapkontrole.
Databasisfoute word na veilige Afrikaanse boodskappe omgeskakel en interne verskafferbesonderhede word nie aan die gebruiker blootgestel nie.

## Finale resultaat

Al 18 formeel aangetekende toetse het die verwagte resultaat gelewer.
Ná die skriftelike herindeling is `SmartEats.dproj` weer as Debug en Release in die Delphi IDE gebou, en albei Messages-vensters het `Success` gewys.
Die finale `dist\SmartEats\SmartEats.exe` is SHA-256-identies aan die Release-bou en het die ingebedde UI teen die aktiewe AppData-databasis gelaai.
'n Nuwe geïsoleerde regressie het 'n grensitem geskep, gewysig en verwyder, waarna nul toetsitems oorgebly het.
Dieselfde regressie het een klient, een bestelling, een bestellyn, 'n 490-greep dagverslag en 'n kwitansie geskep.
Die finale Release-inisialisering het die werklike AppData-databasis se SHA-256 en tydstempel onveranderd gelaat.
Die persoonlike onderhoud is nie deur hierdie verslag voltooi of gewaarborg nie.
