# Simple entry point to run the full Phase0 with async monitor

Write-Host "=== Bootstrapping Phase0 ===" -ForegroundColor Cyan
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$core = Join-Path $root "core"

$all = Join-Path $core "Phase0.All.ps1"
if (-not (Test-Path $all)) {
    Write-Host "❌ Phase0.All.ps1 missing at $all" -ForegroundColor Red
    exit 1
}

Write-Host "Launching core orchestrator..."
& $all
