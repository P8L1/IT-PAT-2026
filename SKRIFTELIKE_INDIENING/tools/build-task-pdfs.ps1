[CmdletBinding()]
param(
    [switch]$VisualReviewPass
)

$ErrorActionPreference = 'Stop'
$workspaceRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $workspaceRoot

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    throw 'Node.js is required. Install Node.js 20 or newer and rerun this command.'
}

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    throw 'Python 3.11 or newer is required. Install Python and rerun this command.'
}

if (-not (Test-Path -LiteralPath (Join-Path $workspaceRoot 'package-lock.json'))) {
    Write-Host 'Creating the pinned project-local Node dependency lock...'
    & npm install --no-audit --no-fund
} elseif (-not (Test-Path -LiteralPath (Join-Path $workspaceRoot 'node_modules'))) {
    Write-Host 'Installing pinned project-local Node dependencies...'
    & npm ci --no-audit --no-fund
}

$venvRoot = Join-Path $PSScriptRoot '.venv'
$venvPython = Join-Path $venvRoot 'Scripts\python.exe'
if (-not (Test-Path -LiteralPath $venvPython)) {
    Write-Host 'Creating the project-local PDF validation environment...'
    & python -m venv $venvRoot
    & $venvPython -m pip install --disable-pip-version-check -r (Join-Path $PSScriptRoot 'requirements-pdf.txt')
}

$env:SMART_EATS_PDF_PYTHON = $venvPython
$nodeArguments = @((Join-Path $PSScriptRoot 'build-task-pdfs.mjs'))
if ($VisualReviewPass) {
    $nodeArguments += '--visual-review-pass'
}
& node $nodeArguments
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
