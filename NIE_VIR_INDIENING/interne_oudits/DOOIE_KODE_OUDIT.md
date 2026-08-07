# Finale dooie-kode- en bate-oudit

## Aktiewe produksie-eenhede

| Item | Status | Rede |
|---|---|---|
| `Project1.dpr` | Aktief | Programbegin en datamodule-/vormskepping |
| `uDataModule.pas/.dfm` | Aktief | ADO-verbinding, metadata en navraagfabriek |
| `uSmartEatsBootstrap.pas` | Aktief | Resources, AppData, seed, skema en migrasie |
| `uSmartEatsService.pas` | Aktief | Validering, CRUD, transaksies, berekenings en uitsette |
| `uWebHoof.pas` | Aktief | Dinamiese VCL/WebView2-gasheer en boodskapbrug |
| `ui/index.html` | Aktief | Enigste produksie-UI-bron met inline HTML/CSS/JS |
| `resources\SmartEatsAssets.rc/.res` | Aktief | UI- en seed-inbedding |

## Afgetrede of nie-produksie-items

| Item | Finale behandeling | Bewys |
|---|---|---|
| Voormalige los `ui/app.js` en CSS-lêers | Nie aktief en nie in die produksie-UI-gids nie | Projek- en resource-soektog vind slegs `ui/index.html` |
| Voormalige Delphi-subvorme | Nie in `.dpr`, `.dproj` of aktiewe eenhede nie | Projekbestuurder toon slegs die vier aktiewe eenhede plus datamodule |
| Ontwerpprototipes | Na `unused\old_design` verskuif | `unused\README.md` |
| Ou tydelike renders, WebView-profiele en logs | Na `unused\temporary` verskuif | `unused\README.md` |
| Verouderde ou toetsbewyse | Na `unused\old_evidence` verskuif | `unused\README.md` |

Geen aktiewe kode verwys na 'n los produksie-JavaScript-, CSS-, localhost- of eksterne UI-bate nie.
Die finale Debug- en Release-boue en werklike EXE-toetse het ná die bronopruiming geslaag.
