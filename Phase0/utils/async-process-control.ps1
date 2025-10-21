<#
.SYNOPSIS
  Async process control with mutex-safe logging.
.DESCRIPTION
  Launches external PowerShell or CLI processes asynchronously,
  streams output, and writes logs atomically using async.lock.ps1.
#>

# Load mutex helper
. (Join-Path $PSScriptRoot 'sync-lock.ps1')

function Start-AsyncProcess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Exe,
        [Parameter(Mandatory)] [string] $Args,
        [Parameter()] [string] $LogPath = "$env:TEMP",
        [Parameter()] [string] $LockName = "Phase0LogLock",
        [Parameter()] [TimeSpan] $Timeout = ([TimeSpan]::FromMinutes(5)),
        [Parameter()] [switch] $ThreadSafe,   # enables mutex protection
        [Parameter()] [switch] $Async         # return Task instead of blocking
    )

    if (-not (Test-Path $LogPath)) {
        New-Item -ItemType Directory -Force -Path $LogPath | Out-Null
    }

    $logFile = Join-Path $LogPath ("process-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + ".log")

    $psi = [System.Diagnostics.ProcessStartInfo]::new($Exe, $Args)
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $proc = [System.Diagnostics.Process]::new()
    $proc.StartInfo = $psi
    $null = $proc.Start()

    Write-Verbose "Started PID=$($proc.Id) EXE=$Exe"

    $coreAction = {
        while (-not $proc.StandardOutput.EndOfStream) {
            $line = $proc.StandardOutput.ReadLine()
            if ($line) {
                Write-Host $line
                if ($ThreadSafe) {
                    Use-Lock -Name $LockName -Action {
                        Add-Content -Path $logFile -Value $line
                    }
                } else {
                    Add-Content -Path $logFile -Value $line
                }
            }
        }

        $proc.WaitForExit()
        @{
            PID       = $proc.Id
            ExitCode  = $proc.ExitCode
            LogFile   = $logFile
            Duration  = $sw.Elapsed
        }
    }

    $sw = [Diagnostics.Stopwatch]::StartNew()

    if ($Async) {
        # return .NET Task
        return [System.Threading.Tasks.Task]::Run($coreAction)
    } else {
        # run synchronously
        $result = & $coreAction
        $sw.Stop()
        Write-Verbose ("Process complete in {0:N1}s Exit={1}" -f $sw.Elapsed.TotalSeconds, $result.ExitCode)
        return $result
    }
}
