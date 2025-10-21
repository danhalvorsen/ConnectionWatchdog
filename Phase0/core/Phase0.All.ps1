# Phase0.Bootstrap.ps1
param([switch]$AutoPull)

# --- Recursion guard ----------------------------------------------------
if ($global:Phase0_Initialized) {
    Write-Host "[Phase0] Already initialized. Skipping bootstrap." -ForegroundColor Yellow
    return
}
$global:Phase0_Initialized = $true

# --- Resolve root ------------------------------------------------------
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (git rev-parse --show-toplevel 2>$null)

# --- Load banner -------------------------------------------------------
$bannerPath = Join-Path $root "Phase0.Banner.ps1"
if (Test-Path $bannerPath) {
    . $bannerPath
} else {
    Write-Host "[Phase0] Banner script not found at: $bannerPath" -ForegroundColor DarkYellow
}

# --- Load logger -------------------------------------------------------
$logPath = Join-Path $root "Phase0.Log.ps1"
if (Test-Path $logPath) {
    . $logPath
    Write-PhaseInfo "Bootstrap logging initialized."
} else {
    Write-Host "[Phase0] Log script not found at: $logPath" -ForegroundColor DarkYellow
}

# --- Git info ----------------------------------------------------------
if (-not $repoRoot) {
    Write-PhaseWarn "Not inside a Git repository. Proceeding standalone..."
}
else {
    Write-PhaseInfo "Git repository root found at: $repoRoot"
    $branch = git rev-parse --abbrev-ref HEAD
    Write-PhaseInfo "Current branch: $branch"
    if ($AutoPull) {
        Write-PhaseInfo "Pulling latest from origin/$branch..."
        git pull origin $branch | Out-Null
    }
}

# --- Load all ----------------------------------------------------------
. "$root\Phase0.All.ps1"

# --- Done --------------------------------------------------------------
Write-PhaseInfo "Bootstrap completed successfully."
Write-Host "[Phase0] Bootstrap completed successfully." -ForegroundColor Green
