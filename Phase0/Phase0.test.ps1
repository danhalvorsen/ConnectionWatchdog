#requires -Version 7
param(
    [string]$MonitorScript = ".\Network-Monitor.ps1",
    [string]$DumpFolder = "C:\TEMP\dump",
    [int]$TestDurationSec = 15
)

Write-Host "=== Phase 0 Test: Network Monitor Health ===" -ForegroundColor Cyan

if (-not (Test-Path $MonitorScript)) {
    Write-Host "❌ Monitor script not found: $MonitorScript" -ForegroundColor Red
    exit 1
}

# --- Launch monitor as background job ---
Write-Host "Starting monitor for $TestDurationSec seconds..."
$job = Start-Job -ScriptBlock {
    param($script)
    & $script -IntervalSeconds 3 -Verbose:$false -Debug:$false
} -ArgumentList (Resolve-Path $MonitorScript)

Start-Sleep -Seconds $TestDurationSec

# --- Stop job gracefully ---
Write-Host "Stopping monitor..."
try { Stop-Job $job -Force | Out-Null } catch {}

Receive-Job $job -Keep | Out-Null
Remove-Job $job | Out-Null

# --- Verify dump file existence ---
if (-not (Test-Path $DumpFolder)) {
    Write-Host "❌ Dump folder missing: $DumpFolder" -ForegroundColor Red
    exit 1
}

$latest = Get-ChildItem $DumpFolder -Filter "terminal-report_*.txt" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (-not $latest) {
    Write-Host "❌ No dump file found." -ForegroundColor Red
    exit 1
}

# --- Validate file content ---
$content = Get-Content $latest.FullName -Raw
$lines = ($content -split "`r?`n") | Where-Object { $_ -match '\S' }
$lineCount = $lines.Count

$hasEstablished = $content -match "Established"
$sizeKB = [math]::Round($latest.Length / 1KB, 2)

# --- System metrics ---
$proc = Get-Process -Name "pwsh" | Sort-Object StartTime -Descending | Select-Object -First 1
$cpu = [math]::Round($proc.CPU,2)
$mem = [math]::Round($proc.WorkingSet / 1MB,2)

Write-Host "File: $($latest.Name)"
Write-Host "Lines: $lineCount   Size: $sizeKB KB"
Write-Host "CPU: $cpu   MEM: $mem MB"

# --- Assertions ---
$pass = $true
if ($lineCount -lt 3) { Write-Host "❌ Too few lines in dump." -ForegroundColor Red; $pass=$false }
if (-not $hasEstablished) { Write-Host "❌ No 'Established' entries found." -ForegroundColor Red; $pass=$false }
if ($mem -gt 100) { Write-Host "⚠️  Memory high ($mem MB)" -ForegroundColor Yellow }

if ($pass) {
    Write-Host "✅ Phase 0 Monitor Test Passed" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ Phase 0 Monitor Test Failed" -ForegroundColor Red
    exit 1
}
