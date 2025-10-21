# ==============================================================
# PHASE0 DEPENDENCY VERIFIER
# --------------------------------------------------------------
# Verifies all required Phase0 core and utility files before launch.
# Works regardless of whether core or utils files are reorganized.
# ==============================================================

param(
    [switch] $AutoLaunch
)

# --- Resolve Phase0 root -------------------------------------
# Go one level up (out of Utils)
$phase0Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host ""
Write-Host "=============================================================="
Write-Host "Verifying Phase0 Core Dependencies"
Write-Host "Path: $phase0Root"
Write-Host "=============================================================="

# --- Define expected files relative to Phase0 root ------------
$requiredFiles = @(
    "core/Phase0.All.ps1",
    "core/Phase0.Bootstrap.ps1",
    "Utils/Dependencies.ps1",
    "Utils/Assert.ps1",
    "Utils/Process-Handling.ps1",
    "Utils/Dummy.ps1"
)

# --- Check for missing files ----------------------------------
$missing = @()
foreach ($file in $requiredFiles) {
    $fullPath = Join-Path $phase0Root $file
    if (-not (Test-Path $fullPath)) {
        $missing += $file
    }
}

if ($missing.Count -eq 0) {
    Write-Host ""
    Write-Host "✅ All required dependencies found." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Warning "Missing required files:"
    foreach ($m in $missing) { Write-Host "  - $m" }
}

# --- Display file summary -------------------------------------
Write-Host ""
Write-Host "Current directory contents:"
Get-ChildItem -Path $phase0Root -Recurse -File |
    Select-Object FullName, Length, LastWriteTime |
    Sort-Object FullName |
    Format-Table -AutoSize

# --- Integrity baseline (hash file) ----------------------------
$hashFile = Join-Path $phase0Root "phase0.hash.json"

if (Test-Path $hashFile) {
    Write-Host ""
    Write-Host "Existing integrity baseline found (phase0.hash.json):"
    try {
        $stored = Get-Content $hashFile | ConvertFrom-Json
        foreach ($key in $stored.PSObject.Properties.Name) {
            $val = $stored.$key
            Write-Host "  $key -> $val"
        }
    } catch {
        Write-Warning "Failed to parse hash baseline."
    }
} else {
    Write-Host ""
    Write-Warning "No hash baseline found (phase0.hash.json will be created at first run)."
}

# --- Optional AutoLaunch --------------------------------------
if ($missing.Count -eq 0 -and $AutoLaunch) {
    Write-Host ""
    Write-Host "AutoLaunch enabled. Bootstrapping Phase0..." -ForegroundColor Yellow

    $bootstrapPath = Join-Path $phase0Root "core\Phase0.Bootstrap.ps1"
    if (Test-Path $bootstrapPath) {
        & $bootstrapPath
    } else {
        Write-Warning "Bootstrap script not found at: $bootstrapPath"
    }
}
elseif ($missing.Count -eq 0) {
    Write-Host ""
    Write-Host "You can now safely launch Phase0 manually via core\Phase0.Bootstrap.ps1" -ForegroundColor Cyan
}
else {
    Write-Host ""
    Write-Warning "Phase0 launch aborted due to missing dependencies."
}

Write-Host ""
Write-Host "=============================================================="
Write-Host "Phase0 verification completed at $(Get-Date -Format u)"
Write-Host "=============================================================="
