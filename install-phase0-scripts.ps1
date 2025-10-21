<#
.SYNOPSIS
    Master bootstrap for Phase 0 – Environment validation and publishing.
.DESCRIPTION
    Loads all required shared modules and scripts for Phase 0,
    runs validation (Phase0.test.ps1), and optionally archives results
    using Publish-Phase0.ps1.
#>

$ErrorActionPreference = 'Stop'
Clear-Host
Write-Host "`n=== PHASE 0 – Full Bootstrap ===`n" -ForegroundColor Cyan

# ---------------------------------------------------------------------
# Resolve paths
# ---------------------------------------------------------------------
$ScriptRoot  = Split-Path -Parent $MyInvocation.MyCommand.Path
$NetworkRoot = Split-Path -Parent $ScriptRoot
$SharedPath  = Join-Path $NetworkRoot 'shared'
$ResultsPath = Join-Path $ScriptRoot 'results'
if (-not (Test-Path $ResultsPath)) { New-Item -ItemType Directory -Force -Path $ResultsPath | Out-Null }

Write-Host "Network Root : $NetworkRoot"
Write-Host "Shared Path  : $SharedPath"
Write-Host "Results Path : $ResultsPath`n"

# ---------------------------------------------------------------------
# Import shared modules
# ---------------------------------------------------------------------
$modules = @(
    Join-Path $SharedPath 'Debug.psm1',
    Join-Path $SharedPath 'Version.psm1'
)
foreach ($m in $modules) {
    if (Test-Path $m) {
        Import-Module $m -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Loaded $(Split-Path $m -Leaf)"
    } else {
        Write-Warning "⚠️ Missing shared module: $m"
    }
}

# ---------------------------------------------------------------------
# Run Phase0 test
# ---------------------------------------------------------------------
$phase0Test = Join-Path $ScriptRoot 'Phase0.test.ps1'
if (-not (Test-Path $phase0Test)) {
    throw "Phase0.test.ps1 not found!"
}

Write-Host "`n▶ Running Phase0.test.ps1..." -ForegroundColor Yellow
& $phase0Test
if ($LASTEXITCODE -ne 0) {
    Write-Warning "❌ Phase0.test.ps1 failed. See logs under $ResultsPath"
    exit 1
}

# ---------------------------------------------------------------------
# Optional: publish results (if Publish-Phase0.ps1 exists)
# ---------------------------------------------------------------------
$publishScript = Join-Path $ScriptRoot 'Publish-Phase0.ps1'
if (Test-Path $publishScript) {
    Write-Host "`n▶ Running Publish-Phase0.ps1..." -ForegroundColor Yellow
    & $publishScript
    Write-Host "✅ Results packaged"
} else {
    Write-Host "ℹ️ Skipping publish – script not found."
}

Write-Host "`n=== Phase 0 Completed Successfully ===" -ForegroundColor Green
