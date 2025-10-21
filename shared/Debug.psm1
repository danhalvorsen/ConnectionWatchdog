<#
.SYNOPSIS
    Phase 0 – Environment validation before running create-webapi-from-template.ps1
#>

$ErrorActionPreference = 'Stop'

# ----------------------- helpers -----------------------
function Write-Stage([string]$msg, [ConsoleColor]$color='Cyan') {
    Write-Host "`n==== $msg ====" -ForegroundColor $color
}
function Ensure-Dir($path) {
    if (-not (Test-Path $path)) { New-Item -ItemType Directory -Force -Path $path | Out-Null }
}

# ----------------------- setup --------------------------
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Results = Join-Path $Root "results"
Ensure-Dir $Results
$Log = Join-Path $Results "phase0.log"

Write-Stage "PHASE 0 – Environment validation starting"

# ----------------------- PowerShell ---------------------
$psVersion = $PSVersionTable.PSVersion.ToString()
Write-Host "PowerShell version: $psVersion"
if ([Version]$PSVersionTable.PSVersion -lt [Version]"7.3.0") {
    throw "PowerShell 7.3+ required"
}

# ----------------------- dotnet -------------------------
if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    throw "dotnet SDK not found"
}
$dotnetVersion = (dotnet --version)
Write-Host "dotnet SDK version: $dotnetVersion"

# ----------------------- modules ------------------------
$modules = @('Tree','posh-git')
foreach ($m in $modules) {
    if (Get-Module -ListAvailable -Name $m) {
        Write-Host "✅ Module $m found"
    } else {
        Write-Warning "⚠️ Module $m missing"
    }
}

# shared modules
$shared = Join-Path $Root "..\shared"
$debug = Join-Path $shared "Debug.psm1"
$version = Join-Path $shared "Version.psm1"
if (Test-Path $debug -and Test-Path $version) {
    Import-Module $debug -ErrorAction SilentlyContinue
    Import-Module $version -ErrorAction SilentlyContinue
    Write-Host "✅ Shared modules loaded"
} else {
    Write-Warning "⚠️ Missing shared Debug/Version modules"
}

# ----------------------- report -------------------------
$result = [ordered]@{
    PowerShell = $psVersion
    Dotnet     = $dotnetVersion
    Modules    = $modules
    Root       = $Root
    Time       = (Get-Date)
}
$result | ConvertTo-Json -Depth 3 | Out-File (Join-Path $Results "phase0-result.json") -Encoding utf8

Add-Content $Log ("[{0}] Phase 0 completed successfully" -f (Get-Date))
Write-Stage "✅ Environment ready – Phase 0 passed"
