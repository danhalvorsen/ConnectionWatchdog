# ==============================================================
# PHASE0 BOOTSTRAP (SMART GIT ROOT DISCOVERY)
# --------------------------------------------------------------
# Finds nearest .git upward, ensures folders exist,
# optionally pulls latest from origin/<branch>,
# then runs core\Phase0.All.ps1 with safety guards.
# ==============================================================

param(
    [string] $Branch = "main",
    [switch] $AutoPull
)

# --- Recursion guard ------------------------------------------
if ($global:Phase0_Initialized) {
    Write-Host "[Phase0] Already initialized. Skipping bootstrap." -ForegroundColor Yellow
    return
}
$global:Phase0_Initialized = $true

# --- Root resolution ------------------------------------------
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$phaseRoot = Split-Path $root -Parent  # we are in /core
if (-not (Test-Path (Join-Path $phaseRoot "core"))) {
    $phaseRoot = $root
}

# --- Git discovery --------------------------------------------
$probe = $phaseRoot
while ($probe -and -not (Test-Path (Join-Path $probe ".git"))) {
    $parent = Split-Path $probe -Parent
    if ($parent -eq $probe) { break }
    $probe = $parent
}
if (Test-Path (Join-Path $probe ".git")) {
    $gitRoot = $probe
    Write-Host "Git repository root found at: $gitRoot"
    try {
        $current = (git -C $gitRoot rev-parse --abbrev-ref HEAD).Trim()
        Write-Host "Current branch: $current"
        if ($AutoPull) {
            Write-Host "Pulling latest from origin/$current..."
            git -C $gitRoot pull origin $current | Out-Null
            Write-Host "Git sync completed."
        }
    }
    catch { Write-Warning "Git operation failed: $_" }
}
else {
    Write-Warning "No .git directory found above $phaseRoot."
}

# --- Ensure basic folders exist -------------------------------
@("logs", "temp", "Templates") | ForEach-Object {
    $path = Join-Path $phaseRoot $_
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path | Out-Null
        Write-Host "Created folder: $path"
    }
}

# --- Load Banner & Logger -------------------------------------
$bannerPath = Join-Path $root "Phase0.Banner.ps1"
if (Test-Path $bannerPath) { . $bannerPath; Show-Phase0Banner }
$logPath = Join-Path $root "Phase0.Log.ps1"
if (Test-Path $logPath) { . $logPath; Write-PhaseInfo "Bootstrap logging initialized." }

# --- Launch Core ----------------------------------------------
$all = Join-Path $root "Phase0.All.ps1"
if (Test-Path $all) {
    Write-Host "Launching Phase0 core runtime..."
    & $all
    Write-PhaseInfo "[Phase0] Bootstrap completed successfully."
} else {
    Write-Warning "Missing core/Phase0.All.ps1. Cannot continue."
}

Write-Host "[Phase0] Bootstrap completed successfully." -ForegroundColor Green
