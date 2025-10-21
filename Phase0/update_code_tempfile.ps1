# ==============================================================
# update_code_file.ps1
# --------------------------------------------------------------
# Non-interactive safe updater for PowerShell code files.
# - Always creates timestamped backup.
# - Supports both file and inline content update.
# - Uses Phase0.Log.ps1 for themed logging.
# ==============================================================

param(
    [Parameter(Mandatory = $true)]
    [string]$TargetFile,

    [Parameter(Mandatory = $false)]
    [string]$SourceFile,

    [Parameter(Mandatory = $false)]
    [string]$Content
)

$ErrorActionPreference = "Stop"

# --- Phase0 Context -----------------------------------------------------
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$phase0Root = Split-Path $scriptRoot -Parent
$backupRoot = Join-Path $phase0Root "backups"
if (-not (Test-Path $backupRoot)) {
    New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
}

# --- Load Logger --------------------------------------------------------
try {
    . "$phase0Root\core\Phase0.Log.ps1"
} catch {
    Write-Host "[update_code_file] Fallback logging: $($_.Exception.Message)" -ForegroundColor Yellow
}

# --- Validation ---------------------------------------------------------
if (-not (Test-Path $TargetFile)) {
    Write-PhaseError "Target file not found: $TargetFile"
    exit 1
}

if (-not $SourceFile -and -not $Content) {
    Write-PhaseError "No update source provided. Use -SourceFile or -Content."
    exit 1
}

# --- Backup -------------------------------------------------------------
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = Join-Path $backupRoot $timestamp
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
$backupFile = Join-Path $backupDir (Split-Path $TargetFile -Leaf)

Copy-Item $TargetFile $backupFile -Force
Write-PhaseInfo "Backup created at: $backupFile"

# --- Update -------------------------------------------------------------
try {
    if ($SourceFile -and (Test-Path $SourceFile)) {
        Copy-Item $SourceFile $TargetFile -Force
        Write-PhaseSuccess "Updated $TargetFile from $SourceFile"
    }
    elseif ($Content) {
        Set-Content -Path $TargetFile -Value $Content -Encoding UTF8 -Force
        Write-PhaseSuccess "Updated $TargetFile from inline content"
    }
    else {
        Write-PhaseWarn "Nothing to update — no valid source provided."
        exit 1
    }
}
catch {
    Write-PhaseError "Update failed: $($_.Exception.Message)"
    exit 1
}

exit 0
