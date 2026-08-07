# Taak 4: Navigasie, programvloei en GGK-ontwerp

## Finale koppelvlak

SmartEats gebruik een dinamiese Delphi `TEdgeBrowser` wat die ingebedde `ui/index.html` as die UI vertoon.
Die groot uitleg gebruik 'n permanente linkersybalk en die kompakte uitleg gebruik 'n benoemde mobiele navigasiebalk onder 820 logiese pixels.

## Globale navigasie

| Skerm | Hoofdoel | Hoe die gebruiker dit bereik | Belangrikste volgende aksies |
|---|---|---|---|
| Dashboard | Wys vandag se bestellings, omset en lae voorraad | `Dashboard` | Verfris, begin bestelling, werk voorraad of open verslag |
| Spyskaart en voorraad | Lees, soek, sorteer en onderhou items | `Spyskaart en voorraad` | Voeg item by, kies/wysig item, verwyder met bevestiging |
| Nuwe bestelling | Skep 'n Eet-in- of Wegneem-bestelling | `Nuwe bestelling` | Kies klient, tipe, tafel, items en hoeveelhede; maak skoon of stoor |
| Geskiedenis | Lees en navigeer vorige bestellings | `Geskiedenis` | Eerste/vorige/volgende/laaste bladsy of bevestigde verwydering |
| Dagverslag | Genereer verwerkte verkoopsuitvoer vir 'n datum | `Dagverslag` | Kies datum en genereer UI- en teksafvoer |
| Hulp | Verduidelik werkvloei en kortpaaie | `Hulp en kortpaaie` | Sluit dialoog en keer terug na die huidige skerm |
| Sluit SmartEats | Beëindig die program veilig | `Sluit SmartEats` | Kanselleer of bevestig veilige afsluiting |

> Suksesvolle skryfaksies herlaai die relevante skerms sodat die UI die werklike databasistoestand toon.

## Lucidchart-dokument

Verwys na: [SmartEats-programvloei](../Lucidchart/SmartEats-Programvloei-PAT-2026.pdf)

## Standaardvloeidiagramsimbole

| Simbool | Betekenis in SmartEats |
|---|---|
| Afgeronde terminator | Begin of einde van 'n hoof of subprocessvloei |
| Reghoek | 'n Verwerkingsstap soos berekening, validering of UI-laai |
| Diamant | 'n Benoemde besluit met duidelike Ja/Nee of alternatiewe paaie |
| Parallelogram | Toevoer uit die gebruiker of afvoer na die UI |
| Silinder | Lees of skryf van die Access-databasis |
| Dokumentvorm | Kwitansie, dagverslag of ander tekslêeruitvoer |
| Dubbelrand-reghoek | 'n Subprocess of verwysing na 'n ander Lucidchart-bladsy |
| Afbladskakel | 'n Vervolgpad na 'n ander deel van die programvloei |
| Pyl | Rigting van uitvoering; lynteks benoem die besluitpad |

## Kleurlegende

| Kleur | Betekenis |
|---|---|
| Groen | Begin, suksesvolle beëindiging of veilige einde |
| Blou | Gewone proses of verwerking |
| Geel/amber | Besluit wat die volgende pad bepaal |
| Pers | Toevoer of afvoer |
| Turkoois | Access-databasis |
| Oranje | Teksleerdokument soos 'n kwitansie of verslag |
| Liggrys | Subprocess, ander bladsy of gekoppelde programdeel |
| Rooi/pienk | Foutpad, verwerpte toevoer of veilige foutboodskap |

## GGK- en HCI-beginsels

### Konsekwentheid

Alle hoofskerms gebruik dieselfde donker hoëkontras paletsisteem, opskrif styl, knoppiehiërargie, veldetikette, dialoë en toast posisie.
ZAR-bedrae, datums en Ja/Nee-waardes word konsekwent geformateer.

### Sigbaarheid en terugvoer

Die huidige navigasie is gemerk, laaitoestande word aangekondig en elke skryfaksie lewer 'n sukses toast of 'n gestruktureerde foutdialoog.
Die dashboard wys kern statistieke en lae voorraad sonder dat die gebruiker eers 'n verslag hoef te genereer.

### Foutvoorkoming en herstel

Verpligte velde is benoem, ongeldige velde gebruik `aria-invalid`, en die foutopsomming skuif fokus na 'n herstelbare plek.
Verwydering en programafsluiting vereis bevestiging.
Die Wegneem opsie deaktiveer die irrelevante tafelnommerveld.

### Toeganklikheid en sleutelbordgebruik

Betekenisvolle `aria-label`, `aria-current`, `role="alert"` en dialoogfokus ondersteun skermlesers en sleutelbordgebruik.
Een sigbare fokusraam wys waar die volgende sleutelbordaksie sal plaasvind.
`prefers-reduced-motion` verminder onnodige animasie.

### Responsiwiteit

Die sybalk verander na 'n kompakte benoemde navigasiebalk op smal skerms en by hoër ekwivalente skaal.
Toetse by 960 x 700, 800 x 700, 768 x 560 by DPR 1,25 en 640 x 467 by DPR 1,5 het geen horisontale bladsy-oorloop getoon nie.

## Finale UI-skermkopiee

- [Dashboard en gekoppelde Release-UI](..\Skermkopiee\release-loop.png)
- [Spyskaartitemwysiging](..\Skermkopiee\grensitem-wysig.png)
- [Geldige bestelling](..\Skermkopiee\bestelling-skep.png)
- [Dagverslag](..\Skermkopiee\dagverslag.png)
- [Veilige sluitbevestiging](..\Skermkopiee\sluitbevestiging.png)
