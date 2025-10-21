<#
.Feature
    Name        : TcpProbe
    Category    : Network.Probe
    Version     : 1.0.0
    Description : Performs a TCP connectivity test and reports latency statistics.
    Authoring   : PS-Feature-Standard-2025
    Created     : 2025-10-21
#>

. "$PSScriptRoot\..\..\Phase1.Init.ps1"

param(
    [string]$Target = "8.8.8.8",
    [int]$Port = 80,
    [switch]$Verbose
)

# --- Prepare environment ---
$FeatureName = "TcpProbe"
$ConfigPath  = Join-Path $PSScriptRoot "config.json"
if (Test-Path $ConfigPath) {
    $cfg = Get-Content $ConfigPath | ConvertFrom-Json
    $Interval = $cfg.interval
} else {
    $cfg = @{ interval = 10; telemetry = @{ seq = "http://localhost:5341" } }
}

$ResultsDir = Join-Path $PSScriptRoot "results"
New-Item -ItemType Directory -Path $ResultsDir -Force | Out-Null

# --- Perform probe ---
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $tcp.Connect($Target, $Port)
    $sw.Stop()
    $success = $true
    $latency = [math]::Round($sw.Elapsed.TotalMilliseconds,2)
    $tcp.Close()
} catch {
    $sw.Stop()
    $success = $false
    $latency = [math]::Round($sw.Elapsed.TotalMilliseconds,2)
    $error = $_.Exception.Message
}

# --- Construct result ---
$result = [ordered]@{
    feature    = $FeatureName
    timestamp  = (Get-Date).ToUniversalTime().ToString("o")
    target     = $Target
    port       = $Port
    success    = $success
    latency_ms = $latency
    error      = $error
}

# --- Save + telemetry ---
$json = $result | ConvertTo-Json -Compress
$file = Join-Path $ResultsDir "${FeatureName}_$((Get-Date).ToString('yyyyMMdd_HHmmss')).json"
$json | Out-File $file -Encoding utf8

if ($success) {
    Write-Host "✅ $Target:$Port → OK ($latency ms)"
} else {
    Write-Warning "❌ $Target:$Port → FAILED ($error)"
}

# --- Optional: Telemetry to SEQ ---
try {
    $seqUrl = $cfg.telemetry.seq
    $body = @{ level = "Information"; messageTemplate = "TcpProbe result {target}:{port} success={success} latency={latency}" ; properties = $result } | ConvertTo-Json
    Invoke-RestMethod -Uri "$seqUrl/api/events/raw?clef" -Method POST -ContentType "application/vnd.serilog.clef" -Body $body -ErrorAction SilentlyContinue
} catch {
    Write-Verbose "Telemetry send failed: $($_.Exception.Message)"
}
