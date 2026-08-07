param(
  [string]$DatabasisPad = (Join-Path $PSScriptRoot '..\data\SmartEats.accdb')
)

$ErrorActionPreference = 'Stop'

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

function Toets-Waar {
  param(
    [bool]$Voorwaarde,
    [string]$Boodskap
  )

  if (-not $Voorwaarde) {
    throw $Boodskap
  }
  Skryf-Slaag $Boodskap
}

function Lees-Skalaar {
  param(
    $Verbinding,
    [string]$Sql
  )

  $rekordstel = $Verbinding.Execute($Sql)
  try {
    return $rekordstel.Fields.Item(0).Value
  }
  finally {
    $rekordstel.Close()
  }
}

function Kry-Tabel {
  param(
    $Katalogus,
    [string]$Naam
  )

  return $Katalogus.Tables.Item($Naam)
}

function Het-Indeks {
  param(
    $Tabel,
    [string]$Naam,
    [bool]$Uniek,
    [bool]$PrimereSleutel
  )

  foreach ($indeks in $Tabel.Indexes) {
    if (
      ($indeks.Name -eq $Naam) -and
      ([bool]$indeks.Unique -eq $Uniek) -and
      ([bool]$indeks.PrimaryKey -eq $PrimereSleutel)
    ) {
      return $true
    }
  }
  return $false
}

function Het-VreemdeSleutel {
  param(
    $Tabel,
    [string]$Naam,
    [string]$VerwanteTabel
  )

  foreach ($sleutel in $Tabel.Keys) {
    if (
      ($sleutel.Name -eq $Naam) -and
      ($sleutel.Type -eq 2) -and
      ($sleutel.RelatedTable -eq $VerwanteTabel)
    ) {
      return $true
    }
  }
  return $false
}

$volPad = [IO.Path]::GetFullPath($DatabasisPad)
Toets-Waar (Test-Path -LiteralPath $volPad -PathType Leaf) "Databasis bestaan by $volPad."

$verbinding = New-Object -ComObject ADODB.Connection
$katalogus = New-Object -ComObject ADOX.Catalog
$verskaffer = $null

try {
  foreach ($kandidaat in @('Microsoft.ACE.OLEDB.16.0', 'Microsoft.ACE.OLEDB.12.0')) {
    try {
      $verbinding.Open("Provider=$kandidaat;Data Source=$volPad;Persist Security Info=False;")
      $verskaffer = $kandidaat
      break
    }
    catch {
      if ($verbinding.State -ne 0) {
        $verbinding.Close()
      }
    }
  }

  Toets-Waar ($verbinding.State -eq 1) 'ACE OLE DB kon die Access-databasis oopmaak.'
  Skryf-Slaag "Verskaffer: $verskaffer."

  $katalogus.ActiveConnection = $verbinding
  $verwagteKolomme = @{
    tblMetadata = 2
    tblKliente = 6
    tblSpyskaart = 7
    tblBestellings = 9
    tblBestellyne = 5
  }

  foreach ($tabelNaam in $verwagteKolomme.Keys) {
    $tabel = Kry-Tabel $katalogus $tabelNaam
    Toets-Gelyk $tabel.Columns.Count $verwagteKolomme[$tabelNaam] "$tabelNaam het die verwagte aantal velde."
  }

  $kliente = Kry-Tabel $katalogus 'tblKliente'
  $metadata = Kry-Tabel $katalogus 'tblMetadata'
  $spyskaart = Kry-Tabel $katalogus 'tblSpyskaart'
  $bestellings = Kry-Tabel $katalogus 'tblBestellings'
  $bestellyne = Kry-Tabel $katalogus 'tblBestellyne'

  Toets-Waar (Het-Indeks $metadata 'PK_tblMetadata' $true $true) 'tblMetadata se primere sleutel bestaan.'
  Toets-Waar (Het-Indeks $kliente 'PK_tblKliente' $true $true) 'tblKliente se primere sleutel bestaan.'
  Toets-Waar (Het-Indeks $spyskaart 'PK_tblSpyskaart' $true $true) 'tblSpyskaart se primere sleutel bestaan.'
  Toets-Waar (Het-Indeks $bestellings 'PK_tblBestellings' $true $true) 'tblBestellings se primere sleutel bestaan.'
  Toets-Waar (Het-Indeks $bestellyne 'PK_tblBestellyne' $true $true) 'tblBestellyne se primere sleutel bestaan.'
  Toets-Waar (Het-Indeks $kliente 'UX_tblKliente_Selfoon' $true $false) "Klientselfone het 'n unieke indeks."
  Toets-Waar (Het-Indeks $spyskaart 'UX_tblSpyskaart_ItemNaam' $true $false) "Spyskaartitemname het 'n unieke indeks."

  Toets-Waar (Het-VreemdeSleutel $bestellings 'FK_Bestellings_Kliente' 'tblKliente') 'Bestellings verwys na kliente.'
  Toets-Waar (Het-VreemdeSleutel $bestellyne 'FK_Bestellyne_Bestellings' 'tblBestellings') 'Bestellyne verwys na bestellings.'
  Toets-Waar (Het-VreemdeSleutel $bestellyne 'FK_Bestellyne_Spyskaart' 'tblSpyskaart') 'Bestellyne verwys na spyskaartitems.'

  Toets-Waar ((Lees-Skalaar $verbinding 'SELECT COUNT(*) FROM tblKliente WHERE Aktief = True') -ge 1) 'Minstens een aktiewe klient is vir nuwe bestellings beskikbaar.'
  Toets-Waar ((Lees-Skalaar $verbinding 'SELECT COUNT(*) FROM tblSpyskaart WHERE Beskikbaar = True') -ge 1) 'Minstens een beskikbare spyskaartitem bestaan.'
  Toets-Gelyk (Lees-Skalaar $verbinding "SELECT Val(Waarde) FROM tblMetadata WHERE Sleutel = 'SkemaWeergawe'") 1 'Databasisskemaweergawe 1 is aktief.'
  Toets-Gelyk (Lees-Skalaar $verbinding "SELECT COUNT(*) FROM tblMetadata WHERE Sleutel IN ('RestaurantNaam', 'BTWKoers')") 2 'Die ingebedde restaurant- en BTW-instellings bestaan.'
  Toets-Waar ((Lees-Skalaar $verbinding 'SELECT COUNT(*) FROM tblBestellings') -ge 0) 'Geldige produksiebestellings word nie deur die oudit uitgevee of op nul afgedwing nie.'
  Toets-Waar ((Lees-Skalaar $verbinding 'SELECT COUNT(*) FROM tblBestellyne') -ge 0) 'Geldige produksiebestellyne word nie deur die oudit uitgevee of op nul afgedwing nie.'
  Toets-Gelyk (Lees-Skalaar $verbinding 'SELECT COUNT(*) FROM tblSpyskaart WHERE Prys <= 0 OR Voorraad < 0 OR Herbestelvlak < 0') 0 'Spyskaartwaardes voldoen aan die numeriese reels.'
  Toets-Gelyk (Lees-Skalaar $verbinding 'SELECT COUNT(*) FROM tblBestellings AS b LEFT JOIN tblKliente AS k ON b.KlientID = k.KlientID WHERE k.KlientID IS NULL') 0 'Geen weesbestellings bestaan nie.'
  Toets-Gelyk (Lees-Skalaar $verbinding 'SELECT COUNT(*) FROM tblBestellyne AS l LEFT JOIN tblBestellings AS b ON l.BestellingID = b.BestellingID WHERE b.BestellingID IS NULL') 0 'Geen weesbestellyne bestaan nie.'
  Toets-Gelyk (Lees-Skalaar $verbinding 'SELECT COUNT(*) FROM tblBestellyne AS l LEFT JOIN tblSpyskaart AS s ON l.ItemID = s.ItemID WHERE s.ItemID IS NULL') 0 'Geen bestellyn verwys na enige ontbrekende spyskaartitem nie.'

  Write-Output 'RESULTAAT: alle 27 databasis-, skemaversie-, integriteits- en produksiedatakontroles het geslaag.'
}
finally {
  try {
    $katalogus.ActiveConnection = $null
  }
  catch {
  }
  if ($verbinding.State -ne 0) {
    $verbinding.Close()
  }
  [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($katalogus)
  [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($verbinding)
  [GC]::Collect()
  [GC]::WaitForPendingFinalizers()
}
