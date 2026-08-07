# Verpakking en AppData-bootstrap

## Finale produksie-argitektuur

`ui/index.html` is die enigste produksie-UI-bronlêer.
Alle eerste-party HTML, CSS, JavaScript en noodstilering is inline in dié lêer.
Daar is geen aparte produksie-`.js`- of `.css`-lêer en geen eksterne UI-netwerkafhanklikheid nie.
`resources\SmartEatsAssets.rc` bind `ui/index.html` as `SMARTEATS_UI_HTML` en `SmartEats.seed.accdb` as `SMARTEATS_SEED_DB` in die EXE in.
`tools\BouHulpbronne.ps1` bereken SHA-256-waardes, skryf die gegenereerde include en bou `SmartEatsAssets.res`.

## UI-laai

`uSmartEatsBootstrap.LaaiIngebeddeUi` lees die RCDATA-resource met `TResourceStream`.
Dit vergelyk die SHA-256 en kontroleer die verwagte doctype, inline styl, inline skrip en `mainContent`-merkers.
`TfrmWebHoof` gebruik `TEdgeBrowser.NavigateToString` om die geverifieerde UTF-8-teks direk uit geheue te laai.
Geen localhost, webbediener, los runtime-HTML of Node-bouketting word gebruik nie.

## Aktiewe databasis

Die aktiewe, skryfbare databasis is:

```text
%LOCALAPPDATA%\SmartEats\data\SmartEats.accdb
```

`KryPlaaslikeAppDataGids` is die sentrale basispadfunksie.
Die seed binne die EXE is onveranderlik.
As die aktiewe databasis ontbreek, verkry die bootstrap 'n benoemde mutex, verifieer die seed, skryf en flush 'n unieke tydelike lêer, verifieer weer en skuif atomies na die finale naam.
As die aktiewe databasis bestaan, word dit nooit deur die seed oorskryf nie.
Die bestaande databasis word teen die vereiste tabelle, velde, metadata en skemaweergawe gevalideer.
'n Migrasie skep eers 'n rugsteun en loop binne 'n transaksie.

## Verslagpad

`KrySmartEatsVerslaeGids` gebruik die EXE-gids wanneer dit skryfbaar is.
Anders gebruik dit `%LOCALAPPDATA%\SmartEats\Verslae`.

## Finale runtimepakket

| Lêer | Rede |
|---|---|
| `dist\SmartEats\Project1.exe` | Finale Win64 Release met UI- en seed-resources |
| `dist\SmartEats\WebView2Loader.dll` | Win64 WebView2-laaier wat deur `TEdgeBrowser` vereis word |

Die Edge WebView2 Evergreen Runtime en 'n 64-bis ACE OLE DB-verskaffer is masjienvereistes.
Netwerktoegang is nie nodig om die SmartEats-UI te laai nie.

## Finale verifikasie

- Debug en Release is op 2026-08-03 suksesvol in Delphi 12 Community Edition gebou.
- Beide EXE-resources stem byte-vir-byte met die huidige UI en seed ooreen.
- 'n Skoon Debug-toetswortel het die seed na AppData onttrek en gekoppel.
- 'n Herbegin met 'n bestaande toetsdatabasis het dieselfde SHA-256 en tydstempel behou.
- Die Release-EXE het die werklike `%LOCALAPPDATA%`-databasis oopgemaak sonder om sy SHA-256 of tydstempel te verander.
