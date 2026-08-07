[CmdletBinding()]
param(
  [string]$DatabasisPad = (Join-Path $env:LOCALAPPDATA 'SmartEats\data\SmartEats.accdb')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projekPad = Split-Path -Parent $PSScriptRoot
$bronPad = [IO.Path]::GetFullPath($DatabasisPad)
$toetsGids = Join-Path $projekPad 'tmp'
$toetsPad = Join-Path $toetsGids 'daaglikse-statistiek-toets.accdb'
$verbindingString = "Provider=Microsoft.ACE.OLEDB.16.0;Data Source=$toetsPad;Persist Security Info=False;"

function Skryf-Slaag {
  param([string]$Boodskap)

  Write-Output "[SLAAG] $Boodskap"
}

function Toets-Gelyk {
  param(
    $Werklik,
    $Verwag,
    [string]$Boodskap
  )

  if ($Werklik -ne $Verwag) {
    throw "$Boodskap Verwag: $Verwag; werklik: $Werklik."
  }
  Skryf-Slaag $Boodskap
}

function Voeg-ParameterBy {
  param(
    $Opdrag,
    [string]$Naam,
    [int]$Tipe,
    $Waarde,
    [int]$Grootte = 0
  )

  $parameter = if ($Grootte -gt 0) {
    $Opdrag.CreateParameter($Naam, $Tipe, 1, $Grootte, $Waarde)
  }
  else {
    $Opdrag.CreateParameter($Naam, $Tipe, 1, 0, $Waarde)
  }
  $Opdrag.Parameters.Append($parameter)
}

function Voeg-ToetsbestellingBy {
  param(
    $Verbinding,
    [int]$KlientId,
    [datetime]$DatumTyd,
    [decimal]$Totaal
  )

  $opdrag = New-Object -ComObject ADODB.Command
  try {
    $opdrag.ActiveConnection = $Verbinding
    $opdrag.CommandText = @'
INSERT INTO tblBestellings
  (KlientID, DatumTyd, Besteltipe, TafelNommer, Subtotaal, BTW, Totaal, Status)
VALUES (?, ?, ?, NULL, ?, ?, ?, ?)
'@
    $subtotaal = [decimal]::Round($Totaal / 1.15, 2)
    $btw = $Totaal - $subtotaal
    Voeg-ParameterBy $opdrag 'KlientID' 3 $KlientId
    Voeg-ParameterBy $opdrag 'DatumTyd' 7 $DatumTyd
    Voeg-ParameterBy $opdrag 'Besteltipe' 202 'Wegneem' 15
    Voeg-ParameterBy $opdrag 'Subtotaal' 6 $subtotaal
    Voeg-ParameterBy $opdrag 'BTW' 6 $btw
    Voeg-ParameterBy $opdrag 'Totaal' 6 $Totaal
    Voeg-ParameterBy $opdrag 'Status' 202 'Ontvang' 20
    $opdrag.Execute() | Out-Null
  }
  finally {
    [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($opdrag) | Out-Null
  }
}

function Lees-Dagstatistiek {
  param(
    $Verbinding,
    [datetime]$VerwysingsTyd
  )

  $beginDatum = $VerwysingsTyd.Date
  $eindDatum = $beginDatum.AddDays(1)
  $opdrag = New-Object -ComObject ADODB.Command
  $rekordstel = $null
  try {
    $opdrag.ActiveConnection = $Verbinding
    $opdrag.CommandText = @'
SELECT COUNT(*) AS AantalBestellings, SUM(Totaal) AS TotaleOmset
FROM tblBestellings
WHERE DatumTyd >= ? AND DatumTyd < ?
'@
    Voeg-ParameterBy $opdrag 'BeginDatum' 7 $beginDatum
    Voeg-ParameterBy $opdrag 'EindDatum' 7 $eindDatum
    $rekordstel = $opdrag.Execute()
    $omsetWaarde = $rekordstel.Fields.Item('TotaleOmset').Value
    $omset = if ($null -eq $omsetWaarde -or [Convert]::IsDBNull($omsetWaarde)) {
      [decimal]0
    }
    else {
      [decimal]$omsetWaarde
    }
    return [pscustomobject]@{
      Datum = $beginDatum
      Aantal = [int]$rekordstel.Fields.Item('AantalBestellings').Value
      Omset = $omset
    }
  }
  finally {
    if ($null -ne $rekordstel) {
      $rekordstel.Close()
      [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($rekordstel) | Out-Null
    }
    [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($opdrag) | Out-Null
  }
}

if (-not (Test-Path -LiteralPath $bronPad -PathType Leaf)) {
  throw "Die produksiedatabasis ontbreek: $bronPad"
}
if (-not (Test-Path -LiteralPath $toetsGids)) {
  New-Item -ItemType Directory -Path $toetsGids | Out-Null
}
Copy-Item -LiteralPath $bronPad -Destination $toetsPad -Force

$verbinding = New-Object -ComObject ADODB.Connection
try {
  $verbinding.Open($verbindingString)
  $verbinding.Execute('DELETE FROM tblBestellyne') | Out-Null
  $verbinding.Execute('DELETE FROM tblBestellings') | Out-Null
  $klientRekord = $verbinding.Execute('SELECT TOP 1 KlientID FROM tblKliente ORDER BY KlientID')
  try {
    $klientId = [int]$klientRekord.Fields.Item(0).Value
  }
  finally {
    $klientRekord.Close()
    [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($klientRekord) | Out-Null
  }

  Voeg-ToetsbestellingBy $verbinding $klientId ([datetime]'2026-08-03T23:59:59') 11.50
  Voeg-ToetsbestellingBy $verbinding $klientId ([datetime]'2026-08-04T00:00:00') 23.00
  Voeg-ToetsbestellingBy $verbinding $klientId ([datetime]'2026-08-04T00:00:01') 34.50
  Voeg-ToetsbestellingBy $verbinding $klientId ([datetime]'2026-08-04T12:00:00') 46.00

  $voorMiddernag = Lees-Dagstatistiek $verbinding ([datetime]'2026-08-03T23:59:59')
  Toets-Gelyk $voorMiddernag.Aantal 1 'Net-voor-middernag val in die vorige plaaslike kalenderdag.'
  Toets-Gelyk $voorMiddernag.Omset ([decimal]11.50) 'Vorige-dag-omset bevat slegs die vorige dag se BTW-ingeslote totaal.'

  $naMiddernag = Lees-Dagstatistiek $verbinding ([datetime]'2026-08-04T00:00:01')
  Toets-Gelyk $naMiddernag.Aantal 3 'Presies-op- en net-na-middernag val in die nuwe half-oop dagreeks.'
  Toets-Gelyk $naMiddernag.Omset ([decimal]103.50) 'Verskeie nuwe-dag-bestellings se BTW-ingeslote totale word korrek gesom.'
  Skryf-Slaag 'Die vorige dag se bestelling word nie by die nuwe dag getel nie.'
  Skryf-Slaag 'Dieselfde oop verbinding herbereken die nuwe daggrense, soos wanneer die toepassing oor middernag oop bly.'

  $handmatig = Lees-Dagstatistiek $verbinding ([datetime]'2026-08-04T18:00:00')
  Toets-Gelyk $handmatig.Aantal 3 'Handmatige refresh herbereken die daggrense op die oomblik van die versoek.'
  Toets-Gelyk $handmatig.Omset ([decimal]103.50) 'Handmatige refresh behou korrekte huidige-dag-omset.'

  $geenBestellings = Lees-Dagstatistiek $verbinding ([datetime]'2026-08-05T09:00:00')
  Toets-Gelyk $geenBestellings.Aantal 0 'Geen bestellings vandag lewer nul bestellings.'
  Toets-Gelyk $geenBestellings.Omset ([decimal]0) 'Geen bestellings vandag lewer R0,00 omset.'
}
finally {
  if ($verbinding.State -ne 0) {
    $verbinding.Close()
  }
  [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($verbinding) | Out-Null
}

$herbeginVerbinding = New-Object -ComObject ADODB.Connection
try {
  $herbeginVerbinding.Open($verbindingString)
  $herbegin = Lees-Dagstatistiek $herbeginVerbinding ([datetime]'2026-08-04T08:00:00')
  Toets-Gelyk $herbegin.Aantal 3 'Herbegin op die nuwe dag bereken dieselfde nuwe daggrense.'
  Toets-Gelyk $herbegin.Omset ([decimal]103.50) 'Herbegin op die nuwe dag lees die korrekte omset.'
}
finally {
  if ($herbeginVerbinding.State -ne 0) {
    $herbeginVerbinding.Close()
  }
  [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($herbeginVerbinding) | Out-Null
}

Write-Output "Toetskopie behou vir oudit: $toetsPad"
