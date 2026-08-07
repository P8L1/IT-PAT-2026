# SmartEats WebView2-brug

## Grens en verantwoordelikhede

Die inline JavaScript in `ui/index.html` beheer aanbieding, gebeurtenisse, kliëntkant-validering en JSON-versoeke.
Delphi bly die enigste gesag vir databasisverbinding, bedienerkant-validering, berekenings, transaksies, lêerafvoer en veilige afsluiting.
JavaScript het geen direkte Access- of lêerstelseltoegang nie.

## Versoekkontrak

Elke versoek bevat presies:

```json
{
  "version": 1,
  "requestId": "unieke-id",
  "action": "menu.load",
  "payload": {}
}
```

`uWebHoof.pas` verwerp nie-objekte, verkeerde eienskaptellings, onbekende velde, verkeerde weergawes, leë of te lang `requestId`-waardes, onbekende aksies, nie-objek-payloads en boodskappe groter as 64 KB.
Die aksietoelaatlys is:

- `app.initialize`
- `app.requestExit`
- `dashboard.refresh`
- `menu.load`
- `menu.create`
- `menu.update`
- `menu.confirmDelete`
- `clients.create`
- `orders.load`
- `orders.create`
- `history.load`
- `history.confirmDelete`
- `reports.generateDaily`

## Antwoordkontrak

'n Sukses bevat `requestId`, `ok: true` en `data`.
'n Fout bevat `requestId`, `ok: false` en `error` met `code`, `message` en opsionele `field`.
Die UI gebruik die veldnaam om die ooreenstemmende invoer te merk en te fokus.

## Duplikaatindiening

Die Delphi-gasheer kas hoogstens 200 antwoorde volgens `requestId`.
Wanneer dieselfde versoek weer aankom, word die gekaste antwoord teruggestuur en die skryfaksie word nie weer uitgevoer nie.

## Navigasie en inhoudsekuriteit

Die UI word as `about:blank`-inhoud met `NavigateToString` gelaai.
Navigasie buite die aanvanklike dokument en nuwe vensters word gekanselleer en gelog.
Die HTML se Content Security Policy laat slegs inline styl en skrip plus `data:`-beelde toe.
Daar is geen `eval`, `innerHTML`, localhost, webbediener of eksterne eerste-party bate nie.

## Fout- en hulpbronhantering

Verwagte `ESmartEatsFout`-waardes behou 'n veilige kode, Afrikaanse boodskap en veld.
Onverwagte uitsonderings word tegnies gelog, maar sensitiewe besonderhede word nie na die UI gestuur nie.
JSON-voorwerpe, diensvoorwerpe, tydhouers en WebView-hulpbronne word met `try/finally` of eienaarskap vrygestel.
