# SmartEats probleemoplossing

## Die ingebedde UI ontbreek of se hash verskil

Loop `tools\BouHulpbronne.ps1`, bou die projek weer in Delphi en loop `tools\ToetsIngebeddeHulpbronne.ps1`.
Moenie 'n los `index.html`, CSS of JavaScript langs die EXE plaas nie, want die toepassing lees dit nie.

## WebView2 kan nie begin nie

Bevestig dat `WebView2Loader.dll` by die EXE is.
Installeer of herstel die Microsoft Edge WebView2 Evergreen Runtime.
Lees `%LOCALAPPDATA%\SmartEats\logs\WebView-tegnies.log` vir die tegniese konteks.

## Access kan nie koppel nie

Bevestig dat 'n 64-bis ACE OLE DB 16.0- of 12.0-verskaffer geïnstalleer is.
Bevestig dat `%LOCALAPPDATA%\SmartEats\data\SmartEats.accdb` bestaan en lees-/skryfbaar is.
Moenie die databasis na die EXE-gids skuif nie.

## Die seed kan nie op die eerste lopie onttrek nie

Bevestig skryfregte en beskikbare skyfspasie in die gebruiker se plaaslike AppData.
Maak seker dat geen ander SmartEats-eerste-lopie langer as 30 sekondes die bootstrap-mutex hou nie.
Die bootstrap ruim mislukte tydelike lêers op en vervang nie 'n bestaande databasis nie.

## Die bestaande databasis se skema is ongeldig

Gebruik die boodskap en tegniese log om die ontbrekende tabel, veld of metadata te identifiseer.
Herstel van 'n bekende goeie rugsteun is veiliger as handmatige ad hoc-veranderinge.
Skemawysigings moet deur 'n weergawebeheerste migrasie met rugsteun en transaksie geskied.

## 'n Dagverslag verskyn nie langs die EXE nie

Die EXE-gids was waarskynlik nie skryfbaar nie.
Kontroleer `%LOCALAPPDATA%\SmartEats\Verslae` vir die gedokumenteerde fallback.

## 'n Bestelling is gestoor maar die kwitansie ontbreek

Die bestellingstransaksie kan reeds suksesvol gecommit wees voordat die afsonderlike lêerskryf misluk.
Lees die waarskuwing en kontroleer die verslag-/kwitansiegids se skryfregte.
Moenie die bestelling weer indien sonder om eers die geskiedenis na te gaan nie.

## Die UI lyk afgesny op hoë skaal

Gebruik die kompakte kopnavigasie by 'n logiese viewport onder 820 pixels.
Bevestig dat die venster minstens die toepassing se minimum grootte het.
Die finale CSS is teen 100%, 125%- en 150%-ekwivalente viewports getoets.
