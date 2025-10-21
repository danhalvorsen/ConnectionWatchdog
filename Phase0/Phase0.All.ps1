# ==============================================================
# PHASE0 CORE MODULE (ASCII SAFE)
# --------------------------------------------------------------
# Phase0.All.ps1 – Primary Controller Entry
# ==============================================================
param(
    [int]    $TimeoutSeconds = 5,
    [string] $FeatureScript  = "Dummy.ps1"
)

# --------------------------------------------------------------
# 0. Resolve Root
# --------------------------------------------------------------
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

# --------------------------------------------------------------
# 1. Ensure Dependencies.ps1 exists and load it
# --------------------------------------------------------------
$depsPath = Join-Path $root "Dependencies.ps1"
if (-not (Test-Path $depsPath)) {
    throw "Critical dependency missing: Dependencies.ps1 not found in $root"
}
$runtime = . $depsPath

# --------------------------------------------------------------
# 2. Ensure PowerShell 7+
# --------------------------------------------------------------
if ($PSVersionTable.PSVersion.Major -lt 7) {
    $pwshPath = Join-Path $env:PHASE0_TOOLS "pwsh.exe"
    if (-not (Test-Path $pwshPath)) {
        throw "PowerShell 7 executable not found at $pwshPath"
    }
    Write-Host "Restarting Phase0.All.ps1 under PowerShell 7..."
    & $pwshPath -NoProfile -ExecutionPolicy Bypass -File $MyInvocation.MyCommand.Path @args
    exit
}

# --------------------------------------------------------------
# 3. Validate Parameters and Environment
# --------------------------------------------------------------
Assert-True ($TimeoutSeconds -gt 0) "TimeoutSeconds > 0" -Fatal
Assert-Path  $PSScriptRoot "Valid script root" -Fatal
Assert-WriteAccess $PSScriptRoot -Fatal

$pwshPath    = Join-Path $env:PHASE0_TOOLS "pwsh.exe"
$featurePath = Join-Path $runtime.Root $FeatureScript
Assert-Path $pwshPath    "PowerShell 7 executable located" -Fatal
Assert-Path $featurePath "Feature script exists" -Fatal

# --------------------------------------------------------------
# 4. Startup Banner
# --------------------------------------------------------------
Write-Host ""
Write-Host "=============================================================="
Write-Host "Starting Phase Controller: Phase0"
Write-Host "Root Path: $($runtime.Root)"
Write-Host "Feature:   $FeatureScript"
Write-Host "=============================================================="

# --------------------------------------------------------------
# 5. Integrity Verification and Self-Healing
# --------------------------------------------------------------
try {
    $hashFile     = Join-Path $root "phase0.hash.json"
    $logFile      = Join-Path $env:PHASE0_LOGS "phase0.integrity.log"
    $templateRoot = Join-Path $root "Templates"
    $coreFiles    = @("Phase0.All.ps1","Dependencies.ps1","Assert.ps1","Process-Handling.ps1")

    function Write-IntegrityLog {
        param([string] $Message,[string] $Level="INFO")
        $timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        Add-Content -Path $logFile -Value "[$timestamp][$Level] $Message"
    }

    function Get-Phase0HashSet {
        param([string[]] $Files)
        $set = @{}
        foreach ($f in $Files) {
            $path = Join-Path $root $f
            if (Test-Path $path) {
                $hash = (Get-FileHash -Algorithm SHA256 -Path $path).Hash
                $set[$f] = $hash
            }
        }
        return $set
    }

    $current = Get-Phase0HashSet -Files $coreFiles
    $stored  = if (Test-Path $hashFile) { Get-Content $hashFile | ConvertFrom-Json } else { $null }
    $mismatch = @()

    if ($stored) {
        foreach ($f in $coreFiles) {
            if ($stored.$f -ne $current[$f]) { $mismatch += $f }
        }
    }

    # --- Self-heal logic ---------------------------------------
    if (($mismatch.Count -gt 0) -or (-not (Test-Path $hashFile))) {
        if ($env:PHASE0_SELFHEAL -eq "1" -and (Test-Path $templateRoot)) {
            foreach ($f in $coreFiles) {
                $target   = Join-Path $root $f
                $template = Join-Path $templateRoot $f
                if (-not (Test-Path $target) -and (Test-Path $template)) {
                    Write-Warning "$f missing. Restoring from template."
                    Copy-Item $template $target -Force
                    Write-IntegrityLog "$f restored from template" "WARN"
                }
                elseif ($stored -and ($stored.$f -ne $current[$f]) -and (Test-Path $template)) {
                    Write-Warning "$f hash mismatch. Replaced from template."
                    Copy-Item $template $target -Force
                    Write-IntegrityLog "$f replaced from template" "WARN"
                }
            }
            $current = Get-Phase0HashSet -Files $coreFiles
            $current | ConvertTo-Json | Set-Content -Path $hashFile -Encoding UTF8
            Write-IntegrityLog "Baseline regenerated after self-heal" "INFO"
            Write-Host "Self-healing completed. Baseline updated."
        }
        elseif ($env:PHASE0_STRICT_MODE -eq "1") {
            throw "Strict mode enforced - integrity mismatch detected."
        }
        else {
            if ($mismatch.Count -gt 0) {
                Write-Warning "Integrity mismatch in: $($mismatch -join ', ')"
                Write-IntegrityLog "Integrity mismatch in: $($mismatch -join ', ')" "WARN"
            }
            else {
                Write-Host "Phase0 hash reference missing - creating new baseline."
                $current | ConvertTo-Json | Set-Content -Path $hashFile -Encoding UTF8
                Write-IntegrityLog "Baseline created at $hashFile" "INFO"
            }
        }
    }
    else {
        Write-Host "Phase0 core integrity verified successfully."
        Write-IntegrityLog "Core integrity verified successfully" "OK"
    }
}
catch {
    Write-Warning "Integrity verification failed: $_"
}

# --------------------------------------------------------------
# 6. Execute Feature Out-of-Process
# --------------------------------------------------------------
try {
    $result = Invoke-FeatureProcess `
        -ScriptPath $featurePath `
        -PwshPath   $pwshPath `
        -WorkingDir $runtime.Root `
        -TimeoutSeconds $TimeoutSeconds

    Write-Host ""
    Write-Host "--------------------------------------------------------------"
    Write-Host "Feature completed in $($result.DurationSec)s with exit code $($result.ExitCode)"
    Write-Host "Kill script: $($result.KillScript)"
    Write-Host "--------------------------------------------------------------"
}
catch {
    Write-Error "Feature execution failed: $_"
}

# --------------------------------------------------------------
# 7. Completion Banner
# --------------------------------------------------------------
Write-Host ""
Write-Host "=============================================================="
Write-Host "Phase0.All completed successfully"
Write-Host "=============================================================="
