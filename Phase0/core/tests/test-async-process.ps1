. "$PSScriptRoot/_TestBootstrap.ps1"

Write-Host "=============================================================="
Write-Host "Testing Start-AsyncProcess"
Write-Host "=============================================================="

# --- dummy child command ---------------------------------------------
$tempTest = Join-Path $logPath "child-test.ps1"
@'
Write-Host "Child process starting..."
Start-Sleep -Seconds 2
Write-Host "Child process finishing..."
exit 0
'@ | Set-Content -Path $tempTest -Encoding UTF8

try {
    # --- execute ----------------------------------------------------------
    $result = Start-AsyncProcess -Exe "pwsh.exe" -Args "-NoLogo -File `"$tempTest`"" -LogPath $logPath -Verbose

    Write-Host "`n=== Test result ==="
    $result | Format-List

    # --- validate ---------------------------------------------------------
    if (-not (Test-Path $result.LogFile)) {
        throw "❌ Log file not created: $($result.LogFile)"
    }

    if ($result.ExitCode -ne 0) {
        throw "❌ Exit code not 0: $($result.ExitCode)"
    }

    Write-Host "✅ Async process test passed."
}
finally {
    if (Test-Path $tempTest) { Remove-Item $tempTest -Force }
    Write-Host "=============================================================="
}
