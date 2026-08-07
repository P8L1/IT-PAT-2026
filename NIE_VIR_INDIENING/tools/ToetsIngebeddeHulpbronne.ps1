[CmdletBinding()]
param(
  [string]$ProjekWortel,
  [string]$UitvoerbarePad
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjekWortel)) {
  $indieningWortel = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
  $ProjekWortel = Join-Path $indieningWortel 'BRON_KODE'
}
$projekPad = [IO.Path]::GetFullPath($ProjekWortel)
if ([string]::IsNullOrWhiteSpace($UitvoerbarePad)) {
  $UitvoerbarePad = Join-Path $projekPad 'Win64\Release\SmartEats.exe'
}
$uitvoerbareVolpad = [IO.Path]::GetFullPath($UitvoerbarePad)

if (-not (Test-Path -LiteralPath $uitvoerbareVolpad -PathType Leaf)) {
  throw "Die uitvoerbare lêer ontbreek: $uitvoerbareVolpad"
}

if (-not ('SmartEatsHulpbronLeser' -as [type])) {
  Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;

public static class SmartEatsHulpbronLeser
{
    private const uint LOAD_LIBRARY_AS_DATAFILE = 0x00000002;

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern IntPtr LoadLibraryEx(string fileName, IntPtr file, uint flags);

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern IntPtr FindResource(IntPtr module, string name, IntPtr type);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr LoadResource(IntPtr module, IntPtr resourceInfo);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr LockResource(IntPtr resourceData);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern uint SizeofResource(IntPtr module, IntPtr resourceInfo);

    [DllImport("kernel32.dll")]
    private static extern bool FreeLibrary(IntPtr module);

    public static byte[] Read(string executablePath, string resourceName)
    {
        IntPtr module = LoadLibraryEx(executablePath, IntPtr.Zero, LOAD_LIBRARY_AS_DATAFILE);
        if (module == IntPtr.Zero)
            throw new Win32Exception(Marshal.GetLastWin32Error());
        try
        {
            IntPtr info = FindResource(module, resourceName, new IntPtr(10));
            if (info == IntPtr.Zero)
                throw new Win32Exception(Marshal.GetLastWin32Error());
            uint size = SizeofResource(module, info);
            IntPtr loaded = LoadResource(module, info);
            IntPtr pointer = LockResource(loaded);
            if (size == 0 || loaded == IntPtr.Zero || pointer == IntPtr.Zero)
                throw new Win32Exception(Marshal.GetLastWin32Error());
            byte[] result = new byte[size];
            Marshal.Copy(pointer, result, 0, checked((int)size));
            return result;
        }
        finally
        {
            FreeLibrary(module);
        }
    }
}
'@
}

function Kry-Sha256VanGrepe {
  param([byte[]]$Grepe)

  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    # Windows PowerShell 5.1 loop op .NET Framework, waar
    # Convert.ToHexString nog nie beskikbaar is nie.
    return ([BitConverter]::ToString($sha.ComputeHash($Grepe))).Replace('-', '')
  }
  finally {
    $sha.Dispose()
  }
}

$toetse = @(
  @('SMARTEATS_UI_HTML', (Join-Path $projekPad 'ui\index.html')),
  @('SMARTEATS_SEED_DB', (Join-Path $projekPad 'resources\SmartEats.seed.accdb')),
  @('SMARTEATS_WEBVIEW2_LOADER', (Join-Path $projekPad 'runtime\win64\WebView2Loader.dll'))
)

foreach ($toets in $toetse) {
  $naam = $toets[0]
  $bronPad = $toets[1]
  $ingebed = [SmartEatsHulpbronLeser]::Read($uitvoerbareVolpad, $naam)
  $bron = [IO.File]::ReadAllBytes($bronPad)
  $ingebeddeHash = Kry-Sha256VanGrepe $ingebed
  $bronHash = Kry-Sha256VanGrepe $bron
  if ($ingebeddeHash -ne $bronHash) {
    throw "$naam se EXE-resource stem nie met $bronPad ooreen nie."
  }
  Write-Output "[SLAAG] $naam is $($ingebed.Length) grepe en stem byte-vir-byte met die bron ooreen ($ingebeddeHash)."
}

Write-Output 'RESULTAAT: al drie runtime-resources is volledig en korrek in die EXE ingebed.'
