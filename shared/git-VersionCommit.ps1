#requires -Version 7
<#
.SYNOPSIS
  Commits and tags the current version after publish.
.DESCRIPTION
  Reads version.json and performs a lightweight git add, commit, and tag.
  Safe to run even if git is unavailable.
.EXAMPLE
  pwsh ./shared/git-VersionCommit.ps1 -DebugMode
#>

param(
    [string]$VersionFile = "$PSScriptRoot\..\Phase0\version.json",
    [switch]$DebugMode
)

Import-Module "$PSScriptRoot\Debug.psm1" -ArgumentList $DebugMode -Force

# --- verify git ----------------------------------------------------
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    WarnOut "Git not available in PATH. Skipping version commit."
    exit 0
}

# --- ensure version file exists ------------------------------------
if (-not (Test-Path $VersionFile)) {
    ErrorOut "version.json not found — nothing to commit."
    exit 1
}

# --- read version --------------------------------------------------
$verInfo = Get-Content $VersionFile | ConvertFrom-Json
$versionTag = "v$($verInfo.version)"
$commitMsg  = "Publish version $($verInfo.version)"

DebugOut "Preparing git commit for version: $versionTag"

# --- stage & commit ------------------------------------------------
try {
    git add . | Out-Null
    git commit -m $commitMsg | Out-Null
    git tag $versionTag | Out-Null
    git push origin $versionTag | Out-Null
    WriteOut "✅ Version $versionTag committed and tagged successfully."
}
catch {
    ErrorOut "Git operation failed: $($_.Exception.Message)"
}
