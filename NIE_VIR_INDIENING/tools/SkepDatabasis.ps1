param(
    [switch]$Herskep,
    [string]$DatabasisPad = (Join-Path $PSScriptRoot '..\data\SmartEats.accdb')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$databasisPad = [IO.Path]::GetFullPath($DatabasisPad)
$dataPad = Split-Path -Parent $databasisPad

if (-not (Test-Path -LiteralPath $dataPad)) {
    New-Item -ItemType Directory -Path $dataPad | Out-Null
}

if (Test-Path -LiteralPath $databasisPad) {
    if (-not $Herskep) {
        throw "Die databasis bestaan reeds by $databasisPad. Gebruik -Herskep slegs wanneer 'n nuwe demonstrasiedatabasis doelbewus verlang word."
    }

    $tydstempel = Get-Date -Format 'yyyyMMdd-HHmmss'
    $rugsteunPad = Join-Path $dataPad "SmartEats-rugsteun-$tydstempel.accdb"
    Copy-Item -LiteralPath $databasisPad -Destination $rugsteunPad
    Remove-Item -LiteralPath $databasisPad
    Write-Output "Herstelbare rugsteun geskep: $rugsteunPad"
}

$access = New-Object -ComObject Access.Application
$access.Visible = $false
try {
    $access.NewCurrentDatabase($databasisPad)
    $access.CloseCurrentDatabase()
}
finally {
    $access.Quit()
    [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($access) | Out-Null
}

$verbinding = New-Object -ComObject ADODB.Connection
try {
    $verbinding.Open("Provider=Microsoft.ACE.OLEDB.16.0;Data Source=$databasisPad;Persist Security Info=False;")

    $stellings = @(
        @'
CREATE TABLE tblMetadata (
  Sleutel VARCHAR(50) CONSTRAINT PK_tblMetadata PRIMARY KEY,
  Waarde VARCHAR(255) NOT NULL
)
'@,
        @'
CREATE TABLE tblKliente (
  KlientID AUTOINCREMENT CONSTRAINT PK_tblKliente PRIMARY KEY,
  Naam VARCHAR(50) NOT NULL,
  Selfoon VARCHAR(15) NOT NULL,
  Epos VARCHAR(100),
  Lojaliteitspunte LONG DEFAULT 0 NOT NULL,
  Aktief YESNO DEFAULT TRUE NOT NULL
)
'@,
        @'
CREATE TABLE tblSpyskaart (
  ItemID AUTOINCREMENT CONSTRAINT PK_tblSpyskaart PRIMARY KEY,
  ItemNaam VARCHAR(60) NOT NULL,
  Kategorie VARCHAR(30) NOT NULL,
  Prys CURRENCY NOT NULL,
  Voorraad LONG NOT NULL,
  Herbestelvlak LONG NOT NULL,
  Beskikbaar YESNO DEFAULT TRUE NOT NULL
)
'@,
        @'
CREATE TABLE tblBestellings (
  BestellingID AUTOINCREMENT CONSTRAINT PK_tblBestellings PRIMARY KEY,
  KlientID LONG NOT NULL,
  DatumTyd DATETIME NOT NULL,
  Besteltipe VARCHAR(15) NOT NULL,
  TafelNommer LONG,
  Subtotaal CURRENCY NOT NULL,
  BTW CURRENCY NOT NULL,
  Totaal CURRENCY NOT NULL,
  Status VARCHAR(20) NOT NULL
)
'@,
        @'
CREATE TABLE tblBestellyne (
  BestellynID AUTOINCREMENT CONSTRAINT PK_tblBestellyne PRIMARY KEY,
  BestellingID LONG NOT NULL,
  ItemID LONG NOT NULL,
  Hoeveelheid LONG NOT NULL,
  Eenheidsprys CURRENCY NOT NULL
)
'@,
        'CREATE UNIQUE INDEX UX_tblKliente_Selfoon ON tblKliente (Selfoon)',
        'CREATE UNIQUE INDEX UX_tblSpyskaart_ItemNaam ON tblSpyskaart (ItemNaam)',
        'CREATE INDEX IX_tblBestellings_DatumTyd ON tblBestellings (DatumTyd)',
        'CREATE INDEX IX_tblBestellings_KlientID ON tblBestellings (KlientID)',
        'CREATE INDEX IX_tblBestellyne_BestellingID ON tblBestellyne (BestellingID)',
        'CREATE INDEX IX_tblBestellyne_ItemID ON tblBestellyne (ItemID)',
        'ALTER TABLE tblBestellings ADD CONSTRAINT FK_Bestellings_Kliente FOREIGN KEY (KlientID) REFERENCES tblKliente (KlientID)',
        'ALTER TABLE tblBestellyne ADD CONSTRAINT FK_Bestellyne_Bestellings FOREIGN KEY (BestellingID) REFERENCES tblBestellings (BestellingID)',
        'ALTER TABLE tblBestellyne ADD CONSTRAINT FK_Bestellyne_Spyskaart FOREIGN KEY (ItemID) REFERENCES tblSpyskaart (ItemID)'
    )

    foreach ($stelling in $stellings) {
        $verbinding.Execute($stelling) | Out-Null
    }

    $verbinding.BeginTrans() | Out-Null
    try {
        $verbinding.Execute("INSERT INTO tblMetadata (Sleutel, Waarde) VALUES ('SkemaWeergawe', '1')") | Out-Null
        $verbinding.Execute("INSERT INTO tblMetadata (Sleutel, Waarde) VALUES ('RestaurantNaam', 'SmartEats Sentrum')") | Out-Null
        $verbinding.Execute("INSERT INTO tblMetadata (Sleutel, Waarde) VALUES ('BTWKoers', '0.15')") | Out-Null

        $kliente = @(
            "INSERT INTO tblKliente (Naam, Selfoon, Epos, Lojaliteitspunte, Aktief) VALUES ('Anika Botha', '0825550101', 'anika@example.test', 120, TRUE)",
            "INSERT INTO tblKliente (Naam, Selfoon, Epos, Lojaliteitspunte, Aktief) VALUES ('Musa Dlamini', '0835550102', 'musa@example.test', 75, TRUE)",
            "INSERT INTO tblKliente (Naam, Selfoon, Epos, Lojaliteitspunte, Aktief) VALUES ('Liam Jacobs', '0845550103', 'liam@example.test', 30, TRUE)",
            "INSERT INTO tblKliente (Naam, Selfoon, Epos, Lojaliteitspunte, Aktief) VALUES ('Naledi Mokoena', '0725550104', 'naledi@example.test', 205, TRUE)",
            "INSERT INTO tblKliente (Naam, Selfoon, Epos, Lojaliteitspunte, Aktief) VALUES ('Sara Petersen', '0735550105', 'sara@example.test', 18, TRUE)",
            "INSERT INTO tblKliente (Naam, Selfoon, Epos, Lojaliteitspunte, Aktief) VALUES ('Theo van Wyk', '0745550106', 'theo@example.test', 0, TRUE)"
        )

        $items = @(
            "INSERT INTO tblSpyskaart (ItemNaam, Kategorie, Prys, Voorraad, Herbestelvlak, Beskikbaar) VALUES ('Botterskorsiesop', 'Voorgereg', 58.00, 18, 5, TRUE)",
            "INSERT INTO tblSpyskaart (ItemNaam, Kategorie, Prys, Voorraad, Herbestelvlak, Beskikbaar) VALUES ('Biltong-en-vy-slaai', 'Voorgereg', 82.50, 12, 4, TRUE)",
            "INSERT INTO tblSpyskaart (ItemNaam, Kategorie, Prys, Voorraad, Herbestelvlak, Beskikbaar) VALUES ('Karoo-lamskenkel', 'Hoofgereg', 189.00, 9, 4, TRUE)",
            "INSERT INTO tblSpyskaart (ItemNaam, Kategorie, Prys, Voorraad, Herbestelvlak, Beskikbaar) VALUES ('Kaapse kerrievis', 'Hoofgereg', 164.00, 7, 3, TRUE)",
            "INSERT INTO tblSpyskaart (ItemNaam, Kategorie, Prys, Voorraad, Herbestelvlak, Beskikbaar) VALUES ('Sampioenrisotto', 'Hoofgereg', 138.00, 14, 4, TRUE)",
            "INSERT INTO tblSpyskaart (ItemNaam, Kategorie, Prys, Voorraad, Herbestelvlak, Beskikbaar) VALUES ('Melktert met kaneelroom', 'Nagereg', 66.00, 11, 3, TRUE)",
            "INSERT INTO tblSpyskaart (ItemNaam, Kategorie, Prys, Voorraad, Herbestelvlak, Beskikbaar) VALUES ('Malvapoeding', 'Nagereg', 72.00, 6, 3, TRUE)",
            "INSERT INTO tblSpyskaart (ItemNaam, Kategorie, Prys, Voorraad, Herbestelvlak, Beskikbaar) VALUES ('Rooibos-ystee', 'Drankie', 38.00, 24, 8, TRUE)",
            "INSERT INTO tblSpyskaart (ItemNaam, Kategorie, Prys, Voorraad, Herbestelvlak, Beskikbaar) VALUES ('Vonkelwater', 'Drankie', 32.00, 20, 6, TRUE)",
            "INSERT INTO tblSpyskaart (ItemNaam, Kategorie, Prys, Voorraad, Herbestelvlak, Beskikbaar) VALUES ('Huisrooiwyn per glas', 'Drankie', 68.00, 3, 5, TRUE)"
        )

        foreach ($stelling in $kliente + $items) {
            $verbinding.Execute($stelling) | Out-Null
        }

        $verbinding.CommitTrans() | Out-Null
    }
    catch {
        $verbinding.RollbackTrans() | Out-Null
        throw
    }
}
finally {
    if ($verbinding.State -ne 0) {
        $verbinding.Close()
    }
    [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($verbinding) | Out-Null
}

Write-Output "SmartEats-databasis geskep: $databasisPad"
