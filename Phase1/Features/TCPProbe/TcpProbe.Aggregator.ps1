<#
.Aggregator
    Feature     : TcpProbe
    IntervalSec : 10
    Purpose     : Aggregates raw probe results into summary reports.
#>

. "$PSScriptRoot\..\..\Phase1.Init.ps1"

param([int]$IntervalSec = 10)

$Feature = "TcpProbe"
$ResultsDir = Join-Path $PSScriptRoot "results"
$Aggregates = Join-Path $ResultsDir "aggregate"
New-Item -ItemType Directory -Path $Aggregates -Force | Out-Null

Write-Host "Aggregator for $Feature running every $IntervalSec seconds..."

while ($true) {
    $files = Get-ChildItem $ResultsDir -Filter "$Feature*.json" -ErrorAction SilentlyContinue
    if ($files.Count -gt 0) {
        $data = @()
        foreach ($f in $files) {
            try { $data += Get-Content $f.FullName | ConvertFrom-Json } catch {}
            Remove-Item $f.FullName -Force
        }

        if ($data.Count -gt 0) {
            $ok  = ($data | Where-Object success).Count
            $fail = $data.Count - $ok
            $avg = [math]::Round(($data | Measure-Object latency_ms -Average).Average,2)
            $summary = [ordered]@{
                feature = $Feature
                timestamp = (Get-Date).ToUniversalTime().ToString("o")
                count = $data.Count
                success = $ok
                fail = $fail
                successRate = [math]::Round(($ok / $data.Count) * 100, 2)
                latency_ms = $avg
            }
            $json = $summary | ConvertTo-Json -Compress
            $file = Join-Path $Aggregates "${Feature}_aggregate_$((Get-Date).ToString('yyyyMMdd_HHmmss')).json"
            $json | Out-File $file -Encoding utf8
            Write-Host "📊 $Feature aggregate written: $file"
        }
    }
    Start-Sleep -Seconds $IntervalSec
}
