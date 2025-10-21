<#
.SYNOPSIS
  Lightweight Phase0 logging utility.
.DESCRIPTION
  Provides Write-PhaseLog, Write-PhaseInfo, Write-PhaseWarn, and Write-PhaseError.
  Auto-creates a logs folder and appends time-stamped entries.
#>

# --- Recursion guard ----------------------------------------------------
if ($global:Phase0_LogLoaded) { return }
$global:Phase0_LogLoaded = $true

# --- Resolve paths ------------------------------------------------------
$phase0Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$logDir     = Join-Path $phase0Root "logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Force -Path $logDir | Out-Null
}
$logFile    = Join-Path $logDir "phase0.log"

# --- Core writer --------------------------------------------------------
function Write-PhaseLog {
    param(
        [Parameter(Mandatory)] [string] $Message,
        [ValidateSet("INFO","WARN","ERROR","DEBUG")] [string] $Level = "INFO"
    )
    $time = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    $entry = "[{0}] [{1}] {2}" -f $time, $Level, $Message
    Add-Content -Path $logFile -Value $entry
    switch ($Level) {
        "INFO"  { Write-Host  $entry -ForegroundColor Cyan }
        "WARN"  { Write-Host  $entry -ForegroundColor Yellow }
        "ERROR" { Write-Host  $entry -ForegroundColor Red }
        "DEBUG" { Write-Host  $entry -ForegroundColor DarkGray }
    }
}

# --- Convenience wrappers ----------------------------------------------
function Write-PhaseInfo  { param([string]$Message) Write-PhaseLog -Message $Message -Level "INFO" }
function Write-PhaseWarn  { param([string]$Message) Write-PhaseLog -Message $Message -Level "WARN" }
function Write-PhaseError { param([string]$Message) Write-PhaseLog -Message $Message -Level "ERROR" }
function Write-PhaseDebug { param([string]$Message) Write-PhaseLog -Message $Message -Level "DEBUG" }

# --- Banner hook --------------------------------------------------------
Write-PhaseInfo "Phase0.Log.ps1 initialized. Log file: $logFile"
