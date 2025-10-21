<#
.SYNOPSIS
  Common bootstrap for Phase0 unit tests.
.DESCRIPTION
  Standardizes environment initialization, path resolution, and dependency loading.
  Import this file at the top of every test using:
      . "$PSScriptRoot/_TestBootstrap.ps1"
#>

$ErrorActionPreference = "Stop"

# --- Path Resolution -----------------------------------------------------
$testRoot   = Split-Path -Parent $MyInvocation.MyCommand.Path       # /core/tests
$coreRoot   = Split-Path $testRoot -Parent                          # /core
$phaseRoot  = Split-Path $coreRoot -Parent                          # /Phase0
$utilsPath  = Join-Path $phaseRoot "Utils"
$logPath    = Join-Path $phaseRoot "logs"

# --- Ensure logs directory exists ---------------------------------------
if (-not (Test-Path $logPath)) {
    New-Item -ItemType Directory -Force -Path $logPath | Out-Null
}

# --- Load shared dependencies -------------------------------------------
. (Join-Path $utilsPath "async-process-control.ps1")
. (Join-Path $utilsPath "sync-lock.ps1")
. (Join-Path $utilsPath "Process-Handling.ps1")

Write-Host "[Phase0.Tests] Bootstrap initialized." -ForegroundColor Cyan
Write-Host "  Phase0 Root:  $phaseRoot"
Write-Host "  Utils Path:   $utilsPath"
Write-Host "  Logs Path:    $logPath"
Write-Host "--------------------------------------"