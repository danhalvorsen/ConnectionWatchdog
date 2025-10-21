# ==============================================================
# update_code_file.ps1
# --------------------------------------------------------------
# Safely updates or replaces a PowerShell file with versioned
# backup and logging through Phase0.Log.ps1
# ==============================================================

param(
    [Parameter(Mandatory)][string]$TargetFile,
    [Parameter(Mandatory)][string]$SourceFile
)

$ErrorActionPreference = "Stop"
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$phase0Root = Split-Path $scriptRoot -Parent
$backupDir  = Join-Path $phase0Root "backups"
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Force -Path $backupDir | Out-Null }

. "$phase0Root\core\Phase0.Log.ps1"

try {
    if (-not (Test-Path $TargetFile)) {
        Write-PhaseWarn "Target file not found: $TargetFile"
        return
    }

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $relBackupDir = Join-Path $backupDir $timestamp
    if (-not (Test-Path $relBackupDir)) { New-Item -ItemType Directory -Force -Path $relBackupDir | Out-Null }

    $backupFile = Join-Path $relBackupDir (Split-Path $TargetFile -Leaf)
    Copy-Item $TargetFile $backupFile -Force

    Write-PhaseInfo "Backup created: $backupFile"

    Copy-Item $SourceFile $TargetFile -Force
    Write-PhaseSuccess "Updated $TargetFile from $SourceFile"
}
catch {
    Write-PhaseError "Failed to update file: $_"
}
