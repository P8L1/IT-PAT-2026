# Taak 5: TVA, validering, verwerking en afvoer

TVA beteken toevoer, verwerking en afvoer.
Die tabelle hieronder beskryf UI en die Delphi-dienslaag wat elke invoer weer valideer voordat die Access-databasis verander word.

## Hoofkoppelvlak 1: Spyskaart en voorraad

### Toevoer en validering

| Invoer | Bron | Datatipe en formaat | HTML-komponent | WebView-aksie | Delphi-hantering | Validering en werklike foutboodskap |
|---|---|---|---|---|---|---|
| Itemnaam | Sleutelbord | String, 1 tot 60 karakters | Teksinvoer in itemvorm | `menu.create` of `menu.update` | `LeesString(..., 60)` | Leegte en lengte; `Vul 'n itemnaam van hoogstens 60 karakters in.` |
| Kategorie | Keuselys | String uit vier toegelate waardes | `select` | `menu.create` of `menu.update` | `MatchText`-toelaatlys | Seleksie; `Kies 'n geldige kategorie uit die lys.` |
| Prys | Sleutelbord | Currency, groter as 0 en hoogstens 1 000 000 | Numeriese teksinvoer | `menu.create` of `menu.update` | `LeesGeld` en reeksreel | `Voer 'n geldige prys groter as R0,00 in.` |
| Voorraad | Sleutelbord | Integer, 0 tot 100 000 | Getalinvoer | `menu.create` of `menu.update` | `LeesHeelgetal(..., 0, 100000)` | `Voorraad moet tussen 0 en 100 000 wees.` |
| Herbestelvlak | Sleutelbord | Integer, 0 tot 100 000 | Getalinvoer | `menu.create` of `menu.update` | `LeesHeelgetal(..., 0, 100000)` | `Herbestelvlak moet tussen 0 en 100 000 wees.` |
| Beskikbaar | Merkblokkie | Boolean | `checkbox` | `menu.create` of `menu.update` | `LeesBool` | Die payload moet 'n logiese waarde bevat |
| Soek | Sleutelbord | String, hoogstens 100 karakters | `#menuSearch` | `menu.load` | Parametergebonde `LIKE` | Lengte word begrens en die waarde word as parameter gebind |
| Sorteer | Keuselys | Vaste stringwaarde | `#menuSort` | `menu.load` | `SpyskaartSorteerSQL` | Slegs 'n vaste kolom-/rigtingtoelaatlys word aanvaar |

### Verwerking

1. Die UI normaliseer die gebruikerwaarde en wys onmiddellike veldterugvoer.
2. Geen brugversoek word gestuur terwyl die kliëntkantvorm ongeldig is nie.
3. Delphi herhaal die tipe, leegte, lengte, reeks en toelaatlysreels.
4. Alle gebruikerwaardes word aan ADO-parameters gebind.
5. Die gekose `SELECT`, `INSERT`, `UPDATE` of `DELETE` word uitgevoer.
6. Die werklike tabeltoestand, bestelbare items en dashboard word na 'n suksesvolle verandering herlaai.

### Afvoer

| Data | Databron en verwerking | Formaat | Komponent | Voorbeeld |
|---|---|---|---|---|
| Spyskaartitems | `tblSpyskaart`, met soek en toegelate sortering | Tabel; ZAR-prys; Ja/Nee; heelgetalle | `#menuRows` | `Rooibos-ystee`, `Drankie`, `R 38,00`, voorraad `24` |
| Seleksiestatus | Gekose tabelry | Afrikaanse status en `aria-selected` | Statuslyn en gemerkte ry | `Item 8 gekies` |
| Veldfout | UI-validator of gestruktureerde Delphi-fout | Kort spesifieke Afrikaanse teks | Foutopsomming en teks by die veld | `Voorraad moet tussen 0 en 100 000 wees.` |
| Sukses | Diensantwoord na bevestigde skryf | Kort toast | `#toastRegion` | `Nuwe spyskaartitem is suksesvol gestoor.` |

## Hoofkoppelvlak 2: Nuwe bestelling en klient

### Toevoer en validering

| Invoer | Bron | Datatipe en formaat | HTML-komponent | WebView-aksie | Delphi-hantering | Validering en werklike foutboodskap |
|---|---|---|---|---|---|---|
| Klientnaam | Sleutelbord | String, 2 tot 50 karakters | `#clientName` | `clients.create` | `LeesString` en minimumlengte | `Die kliëntnaam moet minstens twee karakters bevat.` |
| Selfoon | Sleutelbord | String, Suid-Afrikaanse tien-syferformaat | `#clientPhone` | `clients.create` | `IsGeldigeSelfoon` en unieke indeks | `Voer 'n geldige Suid-Afrikaanse selfoonnommer met tien syfers in.` |
| E-pos | Sleutelbord | Opsionele String, hoogstens 100 karakters | `#clientEmail` | `clients.create` | `IsGeldigeEpos` | `Voer 'n geldige e-posadres in of laat die veld leeg.` |
| Klient-ID | Access en gebruikerkeuse | Integer groter as 0 | `#customerSelect` | `orders.create` | Aktiewe-klientnavraag | `Kies 'n aktiewe kliënt uit die lys.` |
| Besteltipe | Keuselys | String `Eet-in` of `Wegneem` | `#orderType` | `orders.create` | `MatchText`-toelaatlys | `Kies Eet-in of Wegneem as besteltipe.` |
| Tafelnommer | Sleutelbord | Integer 1 tot 40 vir Eet-in; leeg vir Wegneem | `#tableNumber` | `orders.create` | Voorwaardelike `LeesHeelgetal` | `Voer 'n tafelnommer van 1 tot 40 in.` |
| Item-ID | Access en gebruikerkeuse | Bestaande positiewe Integer | Merkblokkie in `#orderItems` | `orders.create` | Databasisherlees binne transaksie | Ontbrekende of onbeskikbare items word verwerp |
| Hoeveelheid | Sleutelbord | Integer vanaf 1 tot beskikbare voorraad | `.qty` by elke item | `orders.create` | `LeesHeelgetal` en atomiese voorraad-`UPDATE` | `Onvoldoende voorraad vir <item>. Herlaai en probeer weer.` |
| Bestellyne | UI-skikking | Een tot 100 unieke JSON-lyne | Gekose itemlys | `orders.create` | `TArray<TBestellynInvoer>` en `TDictionary` | `Kies minstens een en hoogstens 100 spyskaartitems.` |

### Verwerking

1. Kliënt, tipe, tafel en lynkeuses word nagegaan.
2. Elke lyn word na 'n `TBestellynInvoer`-rekord omgeskakel en duplikaatitem-ID's word verwerp.
3. Delphi begin die ADO-transaksie.
4. Elke item se huidige naam, prys, beskikbaarheid en voorraad word binne die transaksie herlees.
5. Bedrae word met `Currency` bereken en tot twee desimale afgerond waar nodig.
6. Die bestelling en elke bestellyn word ingevoeg.
7. Voorraad word slegs verminder wanneer genoeg voorraad steeds bestaan.
8. Lojaliteitspunte word met die heelgetaldeel van die totaal verhoog.
9. Alles word saam gecommit of alles word by enige fout teruggerol.
10. Die kwitansie word uit die gecommitteerde data geskryf en die relevante skerms word herlaai.

### Afvoer

| Data | Databron en verwerking | Formaat | Komponent | Voorbeeld |
|---|---|---|---|---|
| Verkoopbare items | Aktiewe `tblSpyskaart`-rye | Naam, ZAR-prys en voorraad | Kiesbare itemlys | `Rooibos-ystee - R 38,00 - 24 beskikbaar` |
| Subtotaal, BTW en totaal | Delphi-berekening uit herleeste pryse | ZAR met twee desimale | `#subtotal`, `#vat`, `#total` | `R 68,00`, `R 10,20`, `R 78,20` |
| Gestoor bestelling | Gekoppelde bestelling-, klient- en lynrekords | Tyd, klient, tipe, tafel, bedrae en status | Geskiedenistabel | `Wegneem`, totaal `R 78,20` |
| Kwitansie | Gecommitteerde bestelling en lynskikking | UTF-8-teks met een item per lyn | `.txt`-lêer | `Kwitansie-1-20260803-072337.txt` |
| Fout of sukses | Gestruktureerde JSON-antwoord | Afrikaanse dialoog, veldfout of toast | `#messageDialog` of `#toastRegion` | `Kliënt is suksesvol gestoor.` |

## Hoofkoppelvlak 3: Dashboard en dagverslag

| Toevoer | Bron | Datatipe/formaat | Verwerking | Afvoer |
|---|---|---|---|---|
| Huidige datum | Windows | Plaaslike `TDateTime` | Bereken `[Trunc(Now), Trunc(Now)+1)` by elke verfris | Bestellingstelling en omset vir vandag |
| Verslagdatum | Datuminvoer | `YYYY-MM-DD` | `LeesDatum`; gegroepeerde parameter-SQL; dinamiese skikking; geneste sortering | Verslagtabel, totale omset en UTF-8-lêer |
| Bestellings, lyne en items | Access | Gekoppelde databasissrye | `SUM`, `GROUP BY`, half-oop datumreeks | Hoeveelheid en omset per item |

## Valideringsdekking

| Kontrole | Voorbeeld | Waar toegepas |
|---|---|---|
| Leë/null-kontrole | Itemnaam, klientnaam, klientkeuse, besteltipe en bestellyne | UI en `LeesString`/payloadkontrole |
| Seleksiekontrole | Kategorie, aktiewe klient en besteltipe | Vaste toelaatlys of databasisherlees |
| Numeriese reeks | Prys, voorraad, herbestelvlak, tafel en hoeveelheid | UI en `LeesGeld`/`LeesHeelgetal` |
| Tekslengte | Itemnaam 60, klientnaam 50, selfoon 15 en e-pos 100 | UI `maxlength` en `LeesString` |
| Formaatkontrole | Selfoon, e-pos en `YYYY-MM-DD` | UI-formaatreels en Delphi-funksies |
| Duplikaatkontrole | Selfoon, itemnaam en item-ID binne 'n bestelling | Unieke indekse, databasisfoutomskakeling en `TDictionary` |
| Verwantskapkontrole | Aktiewe klient, bestaande item en gekoppelde bestellyne | Parameter-SQL en foreign sleutels |
| Boolean-tipe | Beskikbaar en aktief | UI-merkblokkie en `LeesBool` |

Die vier hoofdatatipes wat by invoer gevalideer word, is `String`, `Integer`, `Currency` en `Boolean`.
Datums word addisioneel na `TDateTime` omgeskakel en teen die vereiste formaat getoets.

## Werklike verwerkingsprosesse

1. Bereken die AppData-pad en vorm die vereiste runtimegidse.
2. Verifieer UI- en seed-resources met SHA-256.
3. Onttrek die seed atomies wanneer die aktiewe databasis ontbreek.
4. Valideer die skema en voer 'n rugsteunbegrensde migrasie uit waar nodig.
5. Valideer die WebView-boodskapkontrak en voorkom duplikaatindiening met 'n antwoordkas.
6. Lees, soek, sorteer en manipuleer spyskaartitems.
7. Voeg 'n klient met 'n unieke selfoon by.
8. Valideer en bou 'n dinamiese bestellynskikking.
9. Bereken finansiële bedrae uit gesaghebbende databasiswaardes.
10. Stoor bestelling, lyne, voorraad en punte in een transaksie.
11. Verwyder 'n bestelling en herstel voorraad en punte in een transaksie.
12. Bereken huidige-dagstatistiek met 'n half-oop datumreeks.
13. Groepeer en sorteer dagverslagdata.
14. Skryf UTF-8-kwitansie-, dagverslag- en tegniese loglêers.

## Algoritmes en formules

### 1. Bestellingstotaal en BTW

```text
Subtotaal = som(Eenheidsprys * Hoeveelheid) vir elke gevalideerde lyn
BTW = rond(Subtotaal * BTWKoers, 2)
Totaal = Subtotaal + BTW
```

Die BTW-koers kom uit `tblMetadata` en die pryse word binne die transaksie uit `tblSpyskaart` herlees.

### 2. Voorraadvermindering

Vir elke lyn:

```sql
  UPDATE tblSpyskaart
  SET Voorraad = Voorraad - Hoeveelheid
  WHERE ItemID = gekose ID
    AND Beskikbaar = True
    AND Voorraad >= Hoeveelheid
```

As presies een ry nie verander nie: gooi fout en rollback alles.

### 3. Lojaliteitspunte

```text
Nuwe punte = huidige punte + Trunc(Totaal)
```

Wanneer 'n bestelling verwyder word, word dieselfde hoeveelheid punte veilig afgetrek sonder om onder nul te gaan.

### 4. Daaglikse omset

```python
DagBegin = Trunc(gekose datum)
DagEinde = DagBegin + 1
```

Kies rye waar:

```python
DatumTyd >= DagBegin && DatumTyd < DagEinde
Totale_omset = som(Totaal) # vir die gekose rye
```

Die half oop reeks voorkom dat presies middernag van die volgende dag saamgetel word.

### 5. Herbestelvlak

```text
Lae voorraad indien Voorraad <= Herbestelvlak EN Beskikbaar = True
```

Die dashboard tel hierdie items en wys die vier dringendste rye.

### 6. Dagverslagsortering

```text
Groepeer bestellyne per ItemNaam.
Bereken Aantal = SUM(Hoeveelheid).
Bereken Omset = SUM(Hoeveelheid * Eenheidsprys).
Sorteer aflopend volgens Aantal.
By gelyke Aantal, sorteer alfabeties volgens ItemNaam.
```

Dieselfde gesorteerde skikking word vir die UI en die tekslêer gebruik.
