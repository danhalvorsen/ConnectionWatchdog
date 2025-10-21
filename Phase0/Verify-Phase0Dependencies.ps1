# ==============================================================
# PHASE0 DEPENDENCY VERIFIER (ASCII SAFE)
# --------------------------------------------------------------
# Verifies all required Phase0 core files before launch
# ==============================================================

param(
    [switch] $AutoLaunch
)

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$expectedFiles = @(
    "Phase0.All.ps1",
    "Dependencies.ps1",
    "Assert.ps1",
    "Process-Handling.ps1",
    "Dummy.ps1"
)

Write-Host ""
Write-Host "=============================================================="
Write-Host "Verifying Phase0 Core Dependencies"
Write-Host "Path: $root"
Write-Host "=============================================================="

# Collect actual files
$actual = Get-ChildItem -Path $root -File | Select-Object Name, Length, LastWriteTime
$actualNames = $actual.Name

# Check for missing files
$missing = @()
foreach ($file in $expectedFiles) {
    if (-not ($actualNames -contains $file)) {
        $missing += $file
    }
}

if ($missing.Count -eq 0) {
    Write-Host "All required dependencies found."
} else {
    Write-Host ""
    Write-Warning "Missing required files:"
    foreach ($m in $missing) { Write-Host "  - $m" }
}

# Print summary table
Write-Host ""
Write-Host "Current directory contents:"
$actual | Format-Table -AutoSize

# Optional: show existing hash baseline
$hashFile = Join-Path $root "phase0.hash.json"
if (Test-Path $hashFile) {
    $stored = Get-Content $hashFile | ConvertFrom-Json
    Write-Host ""
    Write-Host "Existing integrity baseline found (phase0.hash.json):"
    foreach ($key in $stored.PSObject.Properties.Name) {
        $val = $stored.$key
        Write-Host "  $key -> $val"
    }
} else {
    Write-Host ""
    Write-Warning "No hash baseline found (phase0.hash.json will be created at first run)."
}

# Optional auto-launch
if ($missing.Count -eq 0 -and $AutoLaunch) {
    Write-Host ""
    Write-Host "All checks passed. Launching Phase0.All.ps1..."
    & "$root\Phase0.All.ps1"
}
elseif ($missing.Count -eq 0) {
    Write-Host ""
    Write-Host "You can now safely launch Phase0.All.ps1."
}
else {
    Write-Host ""
    Write-Warning "Phase0 launch aborted due to missing dependencies."
}
