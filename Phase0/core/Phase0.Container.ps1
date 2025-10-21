# ==============================================================
# PHASE0 CONTAINER SCRIPT (ASCII SAFE)
# --------------------------------------------------------------
# Recreates full Phase0 folder structure and core files.
# Use for Git commits, portability, and re-materialization.
# ==============================================================

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$phase0 = Join-Path $root "Phase0"
if (-not (Test-Path $phase0)) {
    New-Item -ItemType Directory -Path $phase0 | Out-Null
}

function Write-File($name, $content) {
    $path = Join-Path $phase0 $name
    Set-Content -Path $path -Value $content -Encoding ASCII
    Write-Host "Created: $name"
}

# --------------------------------------------------------------
# Phase0.All.ps1
# --------------------------------------------------------------
$Phase0All = @'
<Phase0.All.ps1 content will be inserted here if needed>
'@

# (For brevity here, you can paste the full Phase0.All.ps1 code from the version we finalized earlier.)

# --------------------------------------------------------------
# Dependencies.ps1
# --------------------------------------------------------------
$Dependencies = @'
# Dependencies.ps1
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$env:PHASE0_ROOT  = $root
$env:PHASE0_LOGS  = Join-Path $root "logs"
$env:PHASE0_TEMP  = Join-Path $root "temp"
$env:PHASE0_TOOLS = "$env:USERPROFILE\.dotnet\tools"
foreach ($d in @($env:PHASE0_LOGS, $env:PHASE0_TEMP)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d | Out-Null }
}
. (Join-Path $root "Assert.ps1")
. (Join-Path $root "Process-Handling.ps1")
'@

# --------------------------------------------------------------
# Assert.ps1
# --------------------------------------------------------------
$Assert = @'
function Assert-True { param([bool]$Condition,[string]$Message,[switch]$Fatal)
    if (-not $Condition) { if ($Fatal) { throw "Assert-True failed: $Message" } else { Write-Warning "Assert-True failed: $Message" } }
}
function Assert-Path { param([string]$Path,[string]$Message,[switch]$Fatal)
    if (-not (Test-Path $Path)) { if ($Fatal) { throw "Assert-Path failed: $Message ($Path)" } else { Write-Warning "Assert-Path failed: $Message ($Path)" } }
}
function Assert-WriteAccess { param([string]$Path,[switch]$Fatal)
    try {
        $t = Join-Path $Path "assert.tmp"
        Set-Content -Path $t -Value "test"
        Remove-Item $t -Force
    } catch { if ($Fatal) { throw "Assert-WriteAccess failed for: $Path" } else { Write-Warning "Assert-WriteAccess failed for: $Path" } }
}
'@

# --------------------------------------------------------------
# Process-Handling.ps1
# --------------------------------------------------------------
$ProcessHandling = @'
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
'@

# --------------------------------------------------------------
# Dummy.ps1
# --------------------------------------------------------------
$Dummy = @'
Write-Host "=== Dummy Feature Running ==="
Start-Sleep -Seconds 2
Write-Host "=== Dummy Feature Completed ==="
'@

# --------------------------------------------------------------
# Phase0.Bootstrap.ps1
# --------------------------------------------------------------
$Bootstrap = @'
# Phase0.Bootstrap.ps1
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$folders=@("logs","temp","Templates")
foreach($f in $folders){$p=Join-Path $root $f;if(-not(Test-Path $p)){New-Item -ItemType Directory -Path $p|Out-Null;Write-Host "Created folder: $p"}}
$gitSync=Join-Path $root "Phase0.GitSync.ps1"
if(Test-Path $gitSync){. $gitSync -ExpectedBranch "master" -AutoPull}
$all=Join-Path $root "Phase0.All.ps1"
if(Test-Path $all){& $all}else{Write-Warning "Phase0.All.ps1 not found."}
'@

# --------------------------------------------------------------
# Phase0.GitSync.ps1
# --------------------------------------------------------------
$GitSync = @'
param([string]$ExpectedBranch="master",[switch]$AutoPull)
$root=Split-Path -Parent $MyInvocation.MyCommand.Path
$log=Join-Path $root "logs/git-sync.log"
function Write-GitLog{param([string]$Message,[string]$Level="INFO")$t=(Get-Date -Format "yyyy-MM-dd HH:mm:ss");Add-Content -Path $log -Value "[$t][$Level] $Message"}
if(-not(Test-Path(Join-Path $root ".git"))){Write-Warning "No .git directory found.";Write-GitLog "Missing .git folder." "WARN";return}
try{$branch=(git -C $root rev-parse --abbrev-ref HEAD).Trim()}catch{Write-Warning "Failed to read branch.";Write-GitLog "Failed to read branch: $_" "ERROR";return}
Write-Host "Current branch: $branch";Write-GitLog "Branch: $branch"
if($branch -ne $ExpectedBranch){Write-Warning "Expected $ExpectedBranch, on $branch.";Write-GitLog "Branch mismatch" "WARN";return}
if($AutoPull){Write-Host "Pulling latest from origin/$ExpectedBranch...";git -C $root pull origin $ExpectedBranch | Tee-Object -FilePath $log -Append;Write-Host "Git sync done.";Write-GitLog "Pull complete" "OK"}
'@

# --------------------------------------------------------------
# Write all files
# --------------------------------------------------------------
Write-File "Dependencies.ps1"      $Dependencies
Write-File "Assert.ps1"            $Assert
Write-File "Process-Handling.ps1"  $ProcessHandling
Write-File "Dummy.ps1"             $Dummy
Write-File "Phase0.Bootstrap.ps1"  $Bootstrap
Write-File "Phase0.GitSync.ps1"    $GitSync
# You can optionally add Phase0.All.ps1 later using Write-File.

Write-Host "=============================================================="
Write-Host "Phase0.Container completed. Files recreated in:"
Write-Host "  $phase0"
Write-Host "=============================================================="
