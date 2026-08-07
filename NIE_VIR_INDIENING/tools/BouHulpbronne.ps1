[CmdletBinding()]
param(
    [Parameter()]
    [string]$ProjekWortel
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjekWortel)) {
    $ProjekWortel = Split-Path -Parent $PSScriptRoot
}
$projekWortel = [IO.Path]::GetFullPath($ProjekWortel)
$hulpbronGids = Join-Path $projekWortel 'resources'
$uiPad = Join-Path $projekWortel 'ui\index.html'
$seedPad = Join-Path $hulpbronGids 'SmartEats.seed.accdb'
$loaderPad = Join-Path $projekWortel 'runtime\win64\WebView2Loader.dll'
$rcPad = Join-Path $hulpbronGids 'SmartEatsAssets.rc'
$resPad = Join-Path $hulpbronGids 'SmartEatsAssets.res'
$includePad = Join-Path $hulpbronGids 'SmartEatsAssetsHashes.inc'
$brcc32Pad = Join-Path ${env:ProgramFiles(x86)} 'Embarcadero\Studio\23.0\bin\brcc32.exe'

foreach ($pad in @($uiPad, $seedPad, $loaderPad, $rcPad, $brcc32Pad)) {
    if (-not (Test-Path -LiteralPath $pad -PathType Leaf)) {
        throw "Vereiste hulpbron of kompileerder ontbreek: $pad"
    }
}

function Get-Sha256Hex {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Pad
    )

    # Gebruik die .NET-API sodat die Delphi-voorbou ook werk wanneer MSBuild
    # nie Windows PowerShell se Get-FileHash-cmdlet outomaties laai nie.
    $sha256 = [Security.Cryptography.SHA256]::Create()
    $stroom = [IO.File]::OpenRead($Pad)
    try {
        return ([BitConverter]::ToString($sha256.ComputeHash($stroom))).Replace('-', '')
    }
    finally {
        $stroom.Dispose()
        $sha256.Dispose()
    }
}

$uiHash = Get-Sha256Hex -Pad $uiPad
$seedHash = Get-Sha256Hex -Pad $seedPad
$loaderHash = Get-Sha256Hex -Pad $loaderPad
$uiWeergawe = '2026.08.02-' + $uiHash.Substring(0, 12).ToLowerInvariant()
$includeInhoud = @(
    '{ Hierdie lêer word deur tools\BouHulpbronne.ps1 gegenereer. }'
    "C_SMARTEATS_UI_WEERGAWE = '$uiWeergawe';"
    "C_SMARTEATS_UI_SHA256 = '$uiHash';"
    "C_SMARTEATS_SEED_SHA256 = '$seedHash';"
    "C_SMARTEATS_WEBVIEW2_LOADER_SHA256 = '$loaderHash';"
    'C_SMARTEATS_SKEMA_WEERGAWE = 1;'
) -join [Environment]::NewLine

[IO.File]::WriteAllText($includePad, $includeInhoud + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))

Push-Location $hulpbronGids
try {
    & $brcc32Pad '-foSmartEatsAssets.res' 'SmartEatsAssets.rc'
    if ($LASTEXITCODE -ne 0) {
        throw "BRCC32 het met kode $LASTEXITCODE misluk."
    }
}
finally {
    Pop-Location
}

if (-not (Test-Path -LiteralPath $resPad -PathType Leaf)) {
    throw "Die gekoppelde resource is nie geskep nie: $resPad"
}

Write-Output "UI SHA-256: $uiHash"
Write-Output "Seed SHA-256: $seedHash"
Write-Output "WebView2Loader SHA-256: $loaderHash"
Write-Output "Resource geskep: $resPad"
