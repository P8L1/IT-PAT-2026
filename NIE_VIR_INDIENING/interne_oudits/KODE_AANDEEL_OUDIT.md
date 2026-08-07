# Finale kode-aandeel-oudit

Die voormalige 20%-HTML-teiken is nie 'n aanvaardingskriterium in die amptelike finale assesseringsinstrument nie.
Hierdie dokument word dus slegs as argitektuurinligting behou.

## Eerste-party bronverdeling

`tools\MeetKodeAandeel.ps1` tel die nie-leë reëls van die aktiewe Delphi-, HTML- en PowerShell-bronne.
Die geformateerde `ui/index.html` bevat die volledige eerste-party HTML, CSS en JavaScript, daarom word daardie kode nou plaaslik en deursigtig getel.
Binêre resources, EXE's, DLL's, DCU's, Access-data, gegenereerde hashkonstantes en derdeparty-runtime-inhoud word nie as handgeskrewe bronkode getel nie.

Die finale herhaalbare meting tel 3 265 produksie-webkodereëls uit 6 750 relevante projekkodereëls, oftewel 48,37%.

## Gevolgtrekking

Die UI is nie 'n los webtoepassing nie.
Dit is die aanbiedingslaag binne 'n Delphi VCL/WebView2-toepassing.
Delphi behou alle databasis-, validerings-, transaksie-, verslag- en lêerstelselgesag.
Die rubriekbewys word teen funksionaliteit, ontwerp, kodegehalte en toetsing gelewer, nie teen 'n kunsmatige reëlpersentasie nie.
