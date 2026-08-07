[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateRange(1, [int]::MaxValue)]
    [int]$ProcessId,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$UitvoerPad,

    [string]$VensterTitel = ''
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;

public static class SmartEatsVensterVaslegging
{
    public delegate bool VensterTerugroep(IntPtr hWnd, IntPtr lParam);

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT
    {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

    [DllImport("user32.dll")]
    public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdcBlt, uint nFlags);

    [DllImport("user32.dll")]
    public static extern bool EnumWindows(VensterTerugroep lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int maximum);

    public static IntPtr VindVenster(int processId, string titelDeel)
    {
        IntPtr beste = IntPtr.Zero;
        long besteOppervlakte = -1;
        EnumWindows(delegate(IntPtr hWnd, IntPtr lParam)
        {
            uint kandidaatProses;
            if (!IsWindowVisible(hWnd) ||
                GetWindowThreadProcessId(hWnd, out kandidaatProses) == 0 ||
                kandidaatProses != (uint)processId)
                return true;

            var titel = new StringBuilder(512);
            GetWindowText(hWnd, titel, titel.Capacity);
            if (!String.IsNullOrWhiteSpace(titelDeel) &&
                titel.ToString().IndexOf(titelDeel, StringComparison.OrdinalIgnoreCase) < 0)
                return true;

            RECT reghoek;
            if (!GetWindowRect(hWnd, out reghoek))
                return true;
            long oppervlakte = Math.Max(0, reghoek.Right - reghoek.Left) *
                (long)Math.Max(0, reghoek.Bottom - reghoek.Top);
            if (oppervlakte > besteOppervlakte)
            {
                beste = hWnd;
                besteOppervlakte = oppervlakte;
            }
            return true;
        }, IntPtr.Zero);
        return beste;
    }
}
'@

$proses = Get-Process -Id $ProcessId -ErrorAction Stop
$proses.Refresh()
$venster = [SmartEatsVensterVaslegging]::VindVenster($ProcessId, $VensterTitel)
if ($venster -eq [IntPtr]::Zero) {
    throw "Proses $ProcessId het nie 'n vaslegbare venster met die gevraagde titel nie."
}

$reghoek = New-Object SmartEatsVensterVaslegging+RECT
if (-not [SmartEatsVensterVaslegging]::GetWindowRect($venster, [ref]$reghoek)) {
    throw "Die grense van proses $ProcessId se hoofvenster kon nie gelees word nie."
}

$wydte = $reghoek.Right - $reghoek.Left
$hoogte = $reghoek.Bottom - $reghoek.Top
if (($wydte -le 0) -or ($hoogte -le 0)) {
    throw "Proses $ProcessId se hoofvenster het ongeldige afmetings."
}

$volleUitvoerPad = [IO.Path]::GetFullPath($UitvoerPad)
$uitvoerGids = Split-Path -Parent $volleUitvoerPad
if (-not (Test-Path -LiteralPath $uitvoerGids -PathType Container)) {
    New-Item -ItemType Directory -Path $uitvoerGids -Force | Out-Null
}

$bitmap = New-Object Drawing.Bitmap $wydte, $hoogte
$grafika = [Drawing.Graphics]::FromImage($bitmap)
$toestelkonteks = $grafika.GetHdc()
try {
    if (-not [SmartEatsVensterVaslegging]::PrintWindow($venster, $toestelkonteks, 2)) {
        throw "Windows kon nie proses $ProcessId se vensterinhoud vaslê nie."
    }
}
finally {
    $grafika.ReleaseHdc($toestelkonteks)
    $grafika.Dispose()
}

try {
    $bitmap.Save($volleUitvoerPad, [Drawing.Imaging.ImageFormat]::Png)
}
finally {
    $bitmap.Dispose()
}

"Slegs proses $ProcessId se hoofvenster is vasgelê: $volleUitvoerPad"
