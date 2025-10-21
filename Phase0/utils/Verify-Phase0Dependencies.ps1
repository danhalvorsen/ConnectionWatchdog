<#
.SYNOPSIS
  Verifies that all required Phase0 dependencies exist and validates
  file integrity using a SHA256 hash baseline. Supports auto-generation
  and controlled rebuild of the baseline.
#>

param(
    [switch]$AutoLaunch,
    [switch]$RebuildBaseline
)

$ErrorActionPreference = "Stop"

Write-Host "`n=============================================================="
Write-Host "Verifying Phase0 Core Dependencies"
# --- Resolve Phase0 root (works from any subfolder) ----------------------
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$maybeRoot  = Split-Path $scriptPath -Parent
if (Test-Path (Join-Path $maybeRoot 'core')) {
    $phaseRoot = $maybeRoot
} else {
    $phaseRoot = $scriptPath
}
Write-Host "Path: $phaseRoot"
Write-Host "==============================================================`n"

# --- Define required files -----------------------------------------------
$required = @(
    "core/Phase0.All.ps1",
    "core/Phase0.Bootstrap.ps1",
    "core/Phase0.Banner.ps1",
    "core/Phase0.Log.ps1",
    "Utils/Dependencies.ps1",
    "Utils/Assert.ps1",
    "Utils/Process-Handling.ps1",
    "Utils/Dummy.ps1"
)

# --- Check for missing ---------------------------------------------------
$missing = @()
foreach ($file in $required) {
    $full = Join-Path $phaseRoot $file
    if (-not (Test-Path $full)) { $missing += $file }
}

if ($missing.Count -gt 0) {
    Write-Warning "Missing required files:`n  - $($missing -join "`n  - ")"
    Write-Host "`nCurrent directory contents:`n"
    Get-ChildItem -Recurse -Path $phaseRoot | Select-Object FullName, Length, LastWriteTime
    Write-Host "`nWARNING: Phase0 launch aborted due to missing dependencies."
    return
}

Write-Host "✅ All required dependencies found.`n"

# --- Hash verification ---------------------------------------------------
$hashFile = Join-Path $phaseRoot "phase0.hash.json"
$scriptFiles = Get-ChildItem -Path $phaseRoot -Recurse -Include *.ps1
$hashes = @{}

foreach ($f in $scriptFiles) {
    $hash = (Get-FileHash $f.FullName -Algorithm SHA256).Hash
    $relPath = $f.FullName.Substring($phaseRoot.Length + 1)
    $hashes[$relPath] = $hash
}

function Save-Baseline {
    param($hashDict, $target)
    $hashDict | ConvertTo-Json -Depth 3 | Out-File -FilePath $target -Encoding UTF8
}

if ($RebuildBaseline -or -not (Test-Path $hashFile)) {
    if ($RebuildBaseline) {
        Write-Host "Rebuilding hash baseline..." -ForegroundColor Cyan
    } else {
        Write-Warning "No hash baseline found. Creating $hashFile ..."
    }
    Save-Baseline $hashes $hashFile
    Write-Host "✅ Baseline created successfully.`n"
}
else {
    $existing = Get-Content $hashFile | ConvertFrom-Json
    $changed = @()

    foreach ($key in $hashes.Keys) {
        if (-not $existing.ContainsKey($key)) {
            $changed += "NEW: $key"
        } elseif ($existing[$key] -ne $hashes[$key]) {
            $changed += "MODIFIED: $key"
        }
    }

    foreach ($key in $existing.Keys) {
        if (-not $hashes.ContainsKey($key)) {
            $changed += "REMOVED: $key"
        }
    }

    if ($changed.Count -gt 0) {
        Write-Warning "Detected modified or new files:`n  - $($changed -join "`n  - ")"
        Write-Host "Updating baseline..."
        Save-Baseline $hashes $hashFile
        Write-Host "✅ Hash baseline updated.`n"
    } else {
        Write-Host "✅ All file hashes match baseline.`n"
    }
}

# --- Optional AutoLaunch -------------------------------------------------
if ($AutoLaunch) {
    Write-Host "AutoLaunch enabled. Bootstrapping Phase0..."
    $bootstrap = Join-Path $phaseRoot "core\Phase0.Bootstrap.ps1"
    if (Test-Path $bootstrap) {
        & $bootstrap
    } else {
        Write-Warning "Bootstrap script not found at $bootstrap"
    }
}

Write-Host "`n=============================================================="
Write-Host "Phase0 verification completed at $(Get-Date -Format "yyyy-MM-dd HH:mm:ssZ")"
Write-Host "==============================================================`n"
