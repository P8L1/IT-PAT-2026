# Taak 1: Gebruikersvereistes

## Taak 1A: Taakdefinisie

SmartEats is 'n Windows program vir kleinskaal se restaurante wat kliente, spyskaartitems, voorraad, bestellings en dag opsommings in een stelsel moet bestuur.
Handgeskrewe bestellings en los sigblaaie lei maklik tot verkeerde pryse, onvolledige dagtotale, voorraadfoute en data wat nie tussen prosesse ooreenstem nie.
SmartEats los hierdie behoefte op deur 'n management UI met 'n plaaslike Access-databasis te verbind.
Personeel kan hierdie UI gebruik instede van ander minder betroubare opsies. Hulle kan 'n aktiewe klient, bestellingstipe, items en hoeveelhede kies en die subtotaal, BTW en totaal voor stoor nagaan.
Die Delphi-dienslaag ('service-layer') valideer die toevoer, herlees die werklike pryse en voorraad en stoor die bestelling, bestellyne, voorraadverandering en lojaliteitspunte binne een db transaksie.
Bestuurders kan spyskaartitems skep, lees, wysig en verwyder, op lae voorraad opvolg, geskiedenis lees en 'n daaglikse verslag genereer.
Die reikwydte sluit veilige eerste-aanvang ('first-run'), databasisintegriteit, kwitansies en UTF-8-dagverslae in.
Let wel, SmartEats is doelbewus 'n Windows en Access oplossing en nie 'n aanlyn bestelstelsel nie.
Kliente kan geskep en gelees word.
Sukses beteken dat geldige werk korrek persisteer, ongeldige toevoer geen gedeeltelike skryf veroorsaak nie en elke belangrike fout 'n verstaanbare Afrikaanse herstelpad toon.

## Taak 1B: Gebruikerstories

| Gebruiker/rol        | Wil ek ...                                                                                                   | Sodat ...                                                                                                               | Kernaktiwiteite                                                                                                                                                                                                      | Aanvaarbare beperkings                                                                                                                                            |
| -------------------- | ------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Personeel by kasregister    | ’n wegneembestelling vir ’n bestaande of nuwe kliënt kan saamstel en stoor                                   | die korrekte bedrag outomaties bereken word en die bestelling vinnig en akkuraat afgehandel kan word                    | Kies of skep ’n kliënt; kies **Wegneem** as bestellingstipe; voeg beskikbare spyskaartitems en hoeveelhede by; kontroleer die subtotaal, BTW en totaal; stoor die bestelling; gebruik die kwitansie as verkoopsbewys | Die stelsel verwerk nie aanlynbetalings, kaarttransaksies of aanlyn bestellings nie; betalings word slegs as deel van die restaurant se interne proses aangeteken |
| Bediener of kelner   | ’n aansitbestelling aan ’n kliënt en tafel kan koppel en die verlangde items kan byvoeg                      | die kombuis en restaurant ’n volledige, korrekte rekord van die bestelling het                                          | Kies ’n bestaande kliënt; kies **Aansit** as bestellingstipe; kies of voer die toepaslike tafel in; voeg items en hoeveelhede by; kontroleer die berekende bedrag; stoor die bestelling                              | Slegs beskikbare spyskaartitems met genoeg voorraad kan bestel word; tafelbesprekings en die uitleg van die restaurant val buite die projek se omvang             |
| Restauranteienaar    | kliënte kan registreer en besigtig en toegang tot die restaurant se belangrikste bedryfsinligting kan verkry | kliënte korrek aan bestellings gekoppel word en ek ’n volledige oorsig van die restaurant se daaglikse bedrywighede het | Skep en besigtig kliënte; kontroleer kliëntbesonderhede en lojaliteitspunte; raadpleeg bestelgeskiedenis; monitor lae voorraad; besigtig dagtotale en gegenereerde verslae                                           | Kliënte kan slegs geskep en besigtig word; kliëntwysiging en -verwydering val buite die projek se omvang; die stelsel bied nie afstandtoegang of wolkverslae nie  |
| Restaurantbestuurder | spyskaartitems en voorraad kan onderhou en verkoopsinligting kan raadpleeg                                   | die restaurant se aanbod, voorraadvlakke en bestuursbesluite op korrekte, huidige data gebaseer is                      | Skep, lees, wysig en verwyder spyskaartitems; werk voorraadwaardes en herbestelvlakke by; volg lae voorraad op; raadpleeg bestelgeskiedenis; genereer en kontroleer dagverslae                                       | Die stelsel werk plaaslik op Windows met Microsoft Access en sluit nie wolkberging, aanlyn bestellings of ondersteuning vir ander bedryfstelsels in nie           |

## Aanvaardingstoetse

| ID | Afgeleide gebruikerstorie | Gegewe | Wanneer | Verwagte resultaat |
|---|---|---|---|---|
| AT-01 | Geldige bestelling | 'n Aktiewe klient en item met genoeg voorraad bestaan | Een Wegneem-item word gestoor | Bestelling en lyn word geskep, voorraad daal, punte styg en die totaal is korrek |
| AT-02 | Geen gedeeltelike skryf | 'n Item het onvoldoende voorraad | 'n Te groot hoeveelheid word gestoor | 'n Afrikaanse fout verskyn en geen bestelling-, lyn-, voorraad- of puntverandering bly agter nie |
| AT-03 | Spyskaartonderhoud | 'n Unieke geldige itemnaam word ingevoer | Die item word geskep, gewysig en bevestig verwyder | Elke stap persisteer en die tabel wys die werklike databasistoestand |
| AT-04 | Kliëntvalidering | Die naam is leeg en die selfoon is ongeldig | Stoor word gekies | Veldfoute verskyn en geen klientry word geskep nie |
| AT-05 | Lae voorraad | 'n Item se voorraad is op of onder sy herbestelvlak | Die dashboard word verfris | Die item en die laevoorraadtelling word gewys |
| AT-06 | Dagverslag | 'n Bestelling bestaan op die gekose datum | Die dagverslag word gegenereer | Die UI en UTF-8-teksleer toon dieselfde gegroepeerde, gesorteerde resultaat |
| AT-07 | Eerste aanvang | Die AppData-databasis ontbreek | Die EXE begin | Die geverifieerde seed word atomies onttrek en gekoppel |
| AT-08 | Bestaande data | 'n Geldige AppData-databasis bestaan | Die EXE begin weer | Die bestaande databasis word gevalideer en nie deur die seed oorskryf nie |
