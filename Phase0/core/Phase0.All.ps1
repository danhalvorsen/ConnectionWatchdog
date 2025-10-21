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

# --- Git info ----------------------------------------------------------
if (-not $repoRoot) {
    Write-Host "Not inside a Git repository. Proceeding standalone..." -ForegroundColor Yellow
}
else {
    Write-Host "Git repository root found at: $repoRoot"
    $branch = git rev-parse --abbrev-ref HEAD
    Write-Host "Current branch: $branch"
    if ($AutoPull) {
        Write-Host "Pulling latest from origin/$branch..."
        git pull origin $branch
    }
}

# --- Load all ----------------------------------------------------------
. "$root\Phase0.All.ps1"

# --- Done --------------------------------------------------------------
Write-Host "[Phase0] Bootstrap completed successfully." -ForegroundColor Green
