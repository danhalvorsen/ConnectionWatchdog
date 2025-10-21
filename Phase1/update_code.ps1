<#
.SYNOPSIS
    Updates and validates Phase codebase.
.DESCRIPTION
    - Works on any active branch (default: detect automatically)
    - Validates Phase0/Phase1 structure
    - Rebuilds feature hashes
    - Optionally regenerates missing features
#>

param(
    [string]$Branch,
    [switch]$RegenerateMissing,
    [switch]$ForcePull
)

# --- Detect repo root ---
$scriptPath = Split-Path -Parent $PSCommandPath
if ((Split-Path $scriptPath -Leaf) -eq "Phase1") {
    $root = Split-Path $scriptPath -Parent
} else {
    $root = $scriptPath
}

Write-Host "`n=============================================================="
Write-Host " Update-Code.ps1  (branch validation)"
Write-Host " Root detected: $root"
Write-Host "=============================================================="

# --- Git branch detection ---
try {
    $current = (git -C $root rev-parse --abbrev-ref HEAD)
    if (-not $Branch) { $Branch = $current }

    Write-Host "Current branch: $current"
    if ($current -ne $Branch) {
        Write-Warning "You are on '$current', expected '$Branch'. Using '$current' for safety."
        $Branch = $current
    }

    if ($ForcePull) {
        Write-Host "Pulling latest from origin/$Branch..."
        git -C $root pull origin $Branch
    }
} catch {
    Write-Warning "Git not available or not initialized at $root"
    $Branch = "unknown"
}

# --- Verify structure ---
$phase0 = Join-Path $root "Phase0"
$phase1 = Join-Path $root "Phase1"
if (-not (Test-Path $phase0) -or -not (Test-Path $phase1)) {
    throw "Missing Phase0 or Phase1 directories at $root"
}

# --- Required files ---
$required = @("Phase1.Init.ps1","FeatureTemplate.ps1","Feature.Update.ps1")
foreach ($req in $required) {
    $path = Join-Path $phase1 $req
    if (-not (Test-Path $path)) {
        Write-Warning "Missing $req"
    } else {
        Write-Host "✔ Found $req"
    }
}

# --- Validate features ---
$features = Get-ChildItem "$phase1\Features" -Directory -ErrorAction SilentlyContinue
if (-not $features) {
    Write-Warning "No features found under $phase1\Features"
} else {
    foreach ($f in $features) {
        $hashFile = Join-Path $f.FullName "hash.json"
        if (-not (Test-Path $hashFile)) {
            Write-Host "Rebuilding hash for feature '$($f.Name)'..."
            $hash = @{}
            Get-ChildItem $f.FullName -Filter "*.ps1" | ForEach-Object {
                $hash[$_.Name] = (Get-FileHash $_.FullName).Hash
            }
            $hash | ConvertTo-Json -Depth 3 | Set-Content $hashFile -Encoding utf8
        } else {
            Write-Host "✔ Hash exists for $($f.Name)"
        }

        if ($RegenerateMissing) {
            $main = Join-Path $f.FullName "$($f.Name).ps1"
            if (-not (Test-Path $main)) {
                Write-Warning "Feature '$($f.Name)' missing main file. Regenerating..."
                pwsh (Join-Path $phase1 "FeatureTemplate.ps1") -Name $f.Name
            }
        }
    }
}

# --- Summary ---
Write-Host "`n=============================================================="
Write-Host " Phase validation completed."
Write-Host " Branch  : $Branch"
Write-Host " Features: $($features.Count)"
Write-Host " Time    : $(Get-Date)"
Write-Host "==============================================================`n"
