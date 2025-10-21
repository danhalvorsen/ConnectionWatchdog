#requires -Version 7
<#
.SYNOPSIS
  Phase 0 – Core Network Monitor
.DESCRIPTION
  Collects TCP connection data every N seconds, computes deltas,
  writes formatted output to console and identical lines to
  C:\TEMP\dump\terminal-report_<date>.txt
#>

param(
    [int]$IntervalSeconds = 3
)

if ($IntervalSeconds -lt 1) { $IntervalSeconds = 1 }

# --- Globals ---
$global:LastSnapshot = @()
$global:DumpFolder   = "C:\TEMP\dump"
if (-not (Test-Path $global:DumpFolder)) {
    New-Item -ItemType Directory -Path $global:DumpFolder | Out-Null
}
$global:DumpFile = Join-Path $global:DumpFolder ("terminal-report_{0:yyyyMMdd}.txt" -f (Get-Date))

# ============================================================
# Utility: aligned console + file writer
function Write-ToTerminalAndDump {
    param([string]$Text, [ConsoleColor]$Color = [ConsoleColor]::Gray)
    Write-Host $Text -ForegroundColor $Color
    try   { Add-Content -Path $global:DumpFile -Value $Text }
    catch { Write-Host "[WARN] Dump failed: $($_.Exception.Message)" -ForegroundColor Yellow }
}

# ============================================================
# Snapshot collector
function Collect-Snapshot {
    try {
        Get-NetTCPConnection -State Established |
        Select-Object -Property LocalAddress,LocalPort,RemoteAddress,RemotePort,State,OwningProcess
    }
    catch {
        Write-ToTerminalAndDump "[ERROR] Unable to collect snapshot: $($_.Exception.Message)" -Color Red
        @()
    }
}

# ============================================================
# Delta calculator
function Compare-Deltas {
    param($Current,$Previous)
    $currKeys = $Current | ForEach-Object { "$($_.LocalAddress):$($_.LocalPort)->$($_.RemoteAddress):$($_.RemotePort)" }
    $prevKeys = $Previous | ForEach-Object { "$($_.LocalAddress):$($_.LocalPort)->$($_.RemoteAddress):$($_.RemotePort)" }

    [pscustomobject]@{
        NewConnections     = ($currKeys | Where-Object { $_ -notin $prevKeys }).Count
        ClosedConnections  = ($prevKeys | Where-Object { $_ -notin $currKeys }).Count
        TotalConnections   = $currKeys.Count
    }
}

# ============================================================
# Console + file output
function Write-LiveOutput {
    param($Delta)
    $time = (Get-Date).ToString("HH:mm:ss")
    $line = ("[{0}]  Active:{1,-5}  +New:{2,-3}  -Closed:{3,-3}" -f $time, $Delta.TotalConnections, $Delta.NewConnections, $Delta.ClosedConnections)
    Write-ToTerminalAndDump $line ([ConsoleColor]::Cyan)
}

# ============================================================
# Graceful exit
$script:stopLoop = $false
$null = Register-EngineEvent PowerShell.Exiting -Action { $script:stopLoop = $true }

# ============================================================
# Main loop
Write-ToTerminalAndDump "=== Network Monitor Phase 0 started at $(Get-Date -Format u) ===" ([ConsoleColor]::Green)
while (-not $script:stopLoop) {
    $snapshot = Collect-Snapshot
    if ($global:LastSnapshot.Count -eq 0) {
        Write-ToTerminalAndDump ("Initial sample: {0} connections" -f $snapshot.Count)
    } else {
        $delta = Compare-Deltas $snapshot $global:LastSnapshot
        Write-LiveOutput $delta
    }
    $global:LastSnapshot = $snapshot
    Start-Sleep -Seconds $IntervalSeconds
}
Write-ToTerminalAndDump "=== Network Monitor Phase 0 stopped at $(Get-Date -Format u) ===" ([ConsoleColor]::Yellow)
