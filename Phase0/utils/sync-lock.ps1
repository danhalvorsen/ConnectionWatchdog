function Use-Lock {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [ScriptBlock] $Action,
        [Parameter()] [int] $TimeoutMs = 5000
    )

    $mutex = [System.Threading.Mutex]::new($false, "Global\$Name")
    $hasLock = $false
    try {
        $hasLock = $mutex.WaitOne($TimeoutMs)
        if (-not $hasLock) {
            throw "Timeout waiting for mutex '$Name'."
        }
        & $Action
    }
    finally {
        if ($hasLock) { $mutex.ReleaseMutex() }
        $mutex.Dispose()
    }
}
