<#
.SYNOPSIS
  Phase 0 controller script — baseline for all future phases.

.DESCRIPTION
  - Runs out-of-process worker scripts (e.g., Network-Monitor.ps1)
  - Can execute a feature script (dummy-feature.ps1) for testing or discovery
  - Provides a standard orchestration pattern for later phases
#>

param(
  [string]$RunFeature = "",
  [string[]]$Args
)

$ErrorActionPreference = 'Stop'
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$PhaseName = Split-Path $ScriptRoot -Leaf
$ResultsPath = Join-Path $ScriptRoot 'results'
if (-not (Test-Path $ResultsPath)) {
  New-Item -ItemType Directory -Force -Path $ResultsPath | Out-Null
}

Write-Host ""
Write-Host "=============================================================="
Write-Host "Starting Phase Controller: $PhaseName"
Write-Host "Path: $ScriptRoot"
Write-Host "=============================================================="
Write-Host ""

# ---------------------------------------------------------------------
#  Helper: Run a child process
# ---------------------------------------------------------------------
function Invoke-OutProcess {
  param(
    [Parameter(Mandatory)][string]$Script,
    [string[]]$Arguments = @(),
    [int]$TimeoutSec = 30
  )

  if (-not (Test-Path $Script)) {
    Write-Warning "Script not found: $Script"
    return
  }

  Write-Host "Launching: $Script"
  $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $Script) + $Arguments
  $proc = Start-Process pwsh -ArgumentList $argList -PassThru -WindowStyle Hidden

  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  while (-not $proc.HasExited -and $sw.Elapsed.TotalSeconds -lt $TimeoutSec) {
    Start-Sleep -Seconds 2
    Write-Host ("Running {0}... {1}s elapsed" -f (Split-Path $Script -Leaf), [int]$sw.Elapsed.TotalSeconds)
  }

  if (-not $proc.HasExited) {
    Write-Warning "Timeout reached. Terminating process PID $($proc.Id)"
    Stop-Process -Id $proc.Id -Force
  }
  else {
    Write-Host ("Completed: {0} exited with code {1}" -f (Split-Path $Script -Leaf), $proc.ExitCode)
  }
}

# ---------------------------------------------------------------------
#  Mode: Run Feature
# ---------------------------------------------------------------------
if ($RunFeature) {
  Write-Host "Feature mode requested: $RunFeature"

  $featureScript = Join-Path $ScriptRoot "$RunFeature.ps1"
  if (-not (Test-Path $featureScript)) {
    $featureScript = Join-Path $ScriptRoot "dummy-feature.ps1"
  }

  Invoke-OutProcess -Script $featureScript -Arguments @('-Features') + $Args -TimeoutSec 20
  Write-Host "Feature run complete."
  Write-Host ""
  exit 0
}

# ---------------------------------------------------------------------
#  Mode: Normal (Run network monitor)
# ---------------------------------------------------------------------
Write-Host "Running network monitor baseline..."

$monitorPath = Join-Path $ScriptRoot 'Network-Monitor.ps1'
Invoke-OutProcess -Script $monitorPath -TimeoutSec 60

Write-Host ""
Write-Host "=============================================================="
Write-Host "Phase0.All completed successfully"
Write-Host "=============================================================="
Write-Host ""
exit 0
