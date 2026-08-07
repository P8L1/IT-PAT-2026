[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$projekWortel = Split-Path -Parent $PSScriptRoot
$bronLêers = @(
    'SmartEats.dpr',
    'uDataModule.pas',
    'uDataModule.dfm',
    'uSmartEatsBootstrap.pas',
    'uSmartEatsService.pas',
    'uWebHoof.pas',
    'ui\index.html',
    'tools\SkepDatabasis.ps1',
    'tools\BouHulpbronne.ps1',
    'tools\ToetsDatabasis.ps1',
    'tools\ToetsDaaglikseStatistiek.ps1',
    'tools\ToetsIngebeddeHulpbronne.ps1',
    'tools\NeemVensterSkermgreep.ps1',
    'tools\MeetKodeAandeel.ps1'
)

$resultate = foreach ($relatiewePad in $bronLêers) {
    $vollePad = Join-Path $projekWortel $relatiewePad
    if (-not (Test-Path -LiteralPath $vollePad -PathType Leaf)) {
        throw "Die vereiste bronlêer ontbreek: $relatiewePad"
    }

    $reëls = @(Get-Content -LiteralPath $vollePad)
    $nieLeëReëls = @($reëls | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count
    $isWeb = [IO.Path]::GetExtension($vollePad) -in @('.html', '.css', '.js')

    [pscustomobject]@{
        Lêer = $relatiewePad
        Reëls = $nieLeëReëls
        Web = $isWeb
    }
}

$webTotaal = ($resultate | Where-Object Web | Measure-Object Reëls -Sum).Sum
$projekTotaal = ($resultate | Measure-Object Reëls -Sum).Sum
$persentasie = if ($projekTotaal -eq 0) { 0 } else { 100 * $webTotaal / $projekTotaal }
$status = "INLIGTING SLEGS — 20% IS NIE MEER ’N AANVAARDINGSKRITERIUM NIE"

$resultate | Format-Table Lêer, Reëls, Web -AutoSize
''
"Produksie-webkodereëls: $webTotaal"
"Totale relevante projekkodereëls: $projekTotaal"
"Webkodepersentasie: $($persentasie.ToString('F2', [Globalization.CultureInfo]::InvariantCulture))%"
"Resultaat: $status"
