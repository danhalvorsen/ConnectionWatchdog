<#
.SYNOPSIS
  Organizes Phase0 folder into a structured layout.
.DESCRIPTION
  Moves files into subdirectories based on naming conventions.
  Automatically creates folders if missing.
#>

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Host ""
Write-Host "=============================================================="
Write-Host "Phase0 file translator / organizer"
Write-Host "Source: $root"
Write-Host "=============================================================="
Write-Host ""

# ---------------------------------------------------------------------
# Folder definitions
# ---------------------------------------------------------------------
$structure = @{
  "core"   = @("Phase0.*.ps1", "Network-Monitor.ps1")
  "utils"  = @("Assert.ps1", "Dependencies.ps1", "Process-Handling.ps1", "Verify-Phase0Dependencies.ps1")
  "scripts"= @("Dummy.ps1", "kill-job-*.ps1")
  "deploy" = @("Publish-Phase0.ps1", "Phase0.Bootstrap.ps1", "Phase0.Container.ps1", "Phase0.GitSync.ps1")
  "tests"  = @("Phase0.test.ps1")
  "templates" = @("Templates\*")
}

# ---------------------------------------------------------------------
# Ensure structure exists
# ---------------------------------------------------------------------
foreach ($folder in $structure.Keys) {
  $target = Join-Path $root $folder
  if (-not (Test-Path $target)) {
    New-Item -ItemType Directory -Force -Path $target | Out-Null
    Write-Host "Created: $target"
  }
}

# ---------------------------------------------------------------------
# Move files based on patterns
# ---------------------------------------------------------------------
foreach ($folder in $structure.Keys) {
  foreach ($pattern in $structure[$folder]) {
    Get-ChildItem -Path $root -Filter $pattern -File -ErrorAction SilentlyContinue | ForEach-Object {
      $targetPath = Join-Path $root $folder
      Move-Item -Path $_.FullName -Destination $targetPath -Force
      Write-Host ("Moved {0} -> {1}" -f $_.Name, $folder)
    }
  }
}

Write-Host ""
Write-Host "=============================================================="
Write-Host "File reorganization complete."
Write-Host "=============================================================="
Write-Host ""
