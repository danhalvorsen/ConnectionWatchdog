<#
.SYNOPSIS
  Initializes the Phase1 environment.
  Loads Phase0 core utilities and Phase1 configuration.
#>

$Phase1Root = Split-Path -Parent $PSCommandPath
$ParentRoot = Split-Path -Parent $Phase1Root
$Phase0Root = Join-Path $ParentRoot "Phase0"

# --- Verify Phase0 Core Exists ---
if (-not (Test-Path $Phase0Root)) {
    throw "Phase0 folder not found at expected location: $Phase0Root"
}

# --- Core Imports ---
$assertPath = Join-Path $Phase0Root "Assert.ps1"
$procPath   = Join-Path $Phase0Root "Process-Handling.ps1"

if (-not (Test-Path $assertPath)) {
    Write-Warning "Missing Assert.ps1 in $Phase0Root — creating a dummy fallback."
    function Assert-Path { param([string]$Path,[string]$Message) Write-Host "Assert placeholder: $Message" }
} else {
    . $assertPath
}

if (-not (Test-Path $procPath)) {
    Write-Warning "Missing Process-Handling.ps1 in $Phase0Root — creating a dummy fallback."
    function Start-ExternalProcess { param([string]$Command) Write-Host "Process start stub: $Command" }
    function Stop-ExternalProcess  { param([int]$PID) Write-Host "Process stop stub: $PID" }
} else {
    . $procPath
}

# --- Load configuration ---
$configFile = Join-Path $Phase1Root "phase1.config.json"
if (-not (Test-Path $configFile)) {
    Write-Warning "Missing phase1.config.json; using defaults."
    $Global:Phase1Config = @{ telemetry = @{ seq = "http://localhost:5341" } }
}
else {
    $Global:Phase1Config = Get-Content $configFile | ConvertFrom-Json
    Write-Host "Phase1 configuration loaded from $configFile"
}

Write-Host "Phase1 initialized (core from: $Phase0Root)"
