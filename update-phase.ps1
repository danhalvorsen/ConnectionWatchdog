<#
.SYNOPSIS
    Smart updater for Network phases (Phase0, Phase1, etc.)
.DESCRIPTION
    Downloads or updates all scripts and modules required for a given phase.
    Default source: GitHub raw URLs or local template folder.
#>

param(
    [string]$Phase = "Phase0",
    [string]$Repo = "https://raw.githubusercontent.com/<youruser>/<yourrepo>/main/Powershell/Network",
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$phaseDir = Join-Path $root $Phase
$sharedDir = Join-Path $root "shared"

if (-not (Test-Path $phaseDir))  { New-Item -ItemType Directory -Force -Path $phaseDir | Out-Null }
if (-not (Test-Path $sharedDir)) { New-Item -ItemType Directory -Force -Path $sharedDir | Out-Null }

Write-Host "`n=== Updating $Phase scripts ===`n" -ForegroundColor Cyan

# --- helper
function Get-RemoteFile($subpath, $dest) {
    $url = "$Repo/$subpath"
    $file = Join-Path $root $subpath
    $dir = Split-Path $file -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    try {
        Write-Host "→ $subpath" -ForegroundColor DarkGray
        Invoke-WebRequest -Uri $url -UseBasicParsing -OutFile $file -ErrorAction Stop
    } catch {
        Write-Warning "Failed to fetch $url"
    }
}

# --- shared files
$sharedFiles = @(
    "shared/Debug.psm1",
    "shared/Version.psm1",
    "shared/git-VersionCommit.ps1"
)

foreach ($f in $sharedFiles) { Get-RemoteFile $f }

# --- phase files
$phaseFiles = @(
    "$Phase/$Phase.All.ps1",
    "$Phase/$Phase.test.ps1",
    "$Phase/Publish-$Phase.ps1",
    "$Phase/Network-Monitor.ps1"
)
foreach ($f in $phaseFiles) { Get-RemoteFile $f }

Write-Host "`n✅ $Phase updated successfully" -ForegroundColor Green

# --- optional local commit
if (Get-Command git -ErrorAction SilentlyContinue) {
    git add . | Out-Null
    git commit -m "Updated scripts for $Phase on $(Get-Date)" | Out-Null
}
