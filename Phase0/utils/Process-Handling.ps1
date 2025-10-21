function Invoke-FeatureProcess {
    param([string]$ScriptPath,[string]$PwshPath,[string]$WorkingDir,[int]$TimeoutSeconds=10)
    if (-not (Test-Path $ScriptPath)) { throw "Feature script not found: $ScriptPath" }
    Write-Host "Launching feature: $ScriptPath"
    $job = Start-Job -ScriptBlock { param($p,$s) & $p -NoProfile -ExecutionPolicy Bypass -File $s } -ArgumentList $PwshPath, $ScriptPath
    Write-Host "Feature process started (Job ID = $($job.Id))"
    $kill = Join-Path $WorkingDir "kill-job-$($job.Id).ps1"
    "@echo off`r`npowershell -Command `"Stop-Job -Id $($job.Id) -Force`"" | Set-Content -Path $kill -Encoding ASCII
    $sw=[Diagnostics.Stopwatch]::StartNew()
    while (-not (Receive-Job $job -Keep)) {
        if ($sw.Elapsed.TotalSeconds -gt $TimeoutSeconds) { Stop-Job -Id $job.Id -Force; break }
        Start-Sleep 1
    }
    $sw.Stop()
    $state=$job.State
    Remove-Job $job
    return [PSCustomObject]@{ JobId=$job.Id; State=$state; DurationSec=[int]$sw.Elapsed.TotalSeconds; KillScript=$kill }
}
