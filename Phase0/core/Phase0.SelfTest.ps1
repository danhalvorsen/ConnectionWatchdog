<#
.SYNOPSIS
  Executes all self-tests under core/tests and logs results.
.DESCRIPTION
  Discovers *.ps1 test scripts in core/tests, runs each in isolation,
  captures exit codes and output, and logs a structured summary.
#>

# --- Guard ---------------------------------------------------------------
if ($global:Phase0_SelfTestRunning) { return }
$global:Phase0_SelfTestRunning = $true

# --- Resolve paths ------------------------------------------------------
$phase0Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$testDir    = Join-Path $phase0Root "tests"
$logDir     = Join-Path $phase0Root "..\logs"
$logFile    = Join-Path $logDir "phase0.log"

# --- Ensure logging -----------------------------------------------------
if (-not (Get-Command Write-PhaseLog -ErrorAction SilentlyContinue)) {
    if (Test-Path (Join-Path $phase0Root "Phase0.Log.ps1")) {
        . (Join-Path $phase0Root "Phase0.Log.ps1")
        Write-PhaseInfo "Self-test logging initialized."
    } else {
        Write-Host "[Phase0.SelfTest] Logging not available; using console only." -ForegroundColor Yellow
    }
}

Write-PhaseInfo "=============================================================="
Write-PhaseInfo "Starting Phase0 Self-Tests at $(Get-Date -Format 'u')"
Write-PhaseInfo "=============================================================="

if (-not (Test-Path $testDir)) {
    Write-PhaseWarn "No test directory found at $testDir"
    return
}

# --- Discover tests -----------------------------------------------------
$tests = Get-ChildItem -Path $testDir -Filter "*.ps1" -File -Recurse
if (-not $tests) {
    Write-PhaseWarn "No test scripts found in $testDir"
    return
}

Write-PhaseInfo ("Discovered {0} test(s)." -f $tests.Count)

# --- Execute tests ------------------------------------------------------
$results = @()
foreach ($test in $tests) {
    Write-PhaseInfo ("Running test: {0}" -f $test.Name)
    try {
        $proc = Start-Process pwsh -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $test.FullName `
            -NoNewWindow -PassThru -Wait -ErrorAction Stop
        $exitCode = $proc.ExitCode
        $status = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
    } catch {
        $status = "ERROR"
        $exitCode = -1
        Write-PhaseError ("Error running {0}: {1}" -f $test.Name, $_.Exception.Message)
    }
    $results += [PSCustomObject]@{
        Name      = $test.Name
        Path      = $test.FullName
        Status    = $status
        ExitCode  = $exitCode
    }
}

# --- Summary ------------------------------------------------------------
$passed = ($results | Where-Object { $_.Status -eq "PASS" }).Count
$failed = ($results | Where-Object { $_.Status -eq "FAIL" }).Count
$errors = ($results | Where-Object { $_.Status -eq "ERROR" }).Count
$total  = $results.Count

Write-PhaseInfo "=============================================================="
Write-PhaseInfo ("Self-Test Summary: {0} Total | {1} Passed | {2} Failed | {3} Errors" -f $total, $passed, $failed, $errors)
Write-PhaseInfo "=============================================================="

# --- Persist results ----------------------------------------------------
$summaryPath = Join-Path $logDir "selftest-summary.json"
$results | ConvertTo-Json -Depth 3 | Set-Content $summaryPath -Encoding UTF8
Write-PhaseInfo "Detailed results written to $summaryPath"
Write-PhaseInfo "=============================================================="
