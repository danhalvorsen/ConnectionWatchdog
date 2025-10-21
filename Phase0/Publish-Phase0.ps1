<#
.SYNOPSIS
  Shared output and debug helpers for all PowerShell scripts.
.DESCRIPTION
  Provides standardized WriteOut(), DebugOut(), and Assert()
  functions for consistent logging, debugging, and flow tracing.
#>

param(
    [switch]$DebugMode
)

# region --- helpers ------------------------------------------------

function WriteOut {
    param([string]$Message)
    $time = (Get-Date).ToString("HH:mm:ss")
    Write-Host "[INFO  $time] $Message" -ForegroundColor Cyan
}

function DebugOut {
    param([string]$Message)
    if ($DebugMode) {
        $time = (Get-Date).ToString("HH:mm:ss.fff")
        Write-Host "[DEBUG $time] $Message" -ForegroundColor DarkGray
    }
}

function WarnOut {
    param([string]$Message)
    $time = (Get-Date).ToString("HH:mm:ss")
    Write-Host "[WARN  $time] $Message" -ForegroundColor Yellow
}

function ErrorOut {
    param([string]$Message)
    $time = (Get-Date).ToString("HH:mm:ss")
    Write-Host "[ERROR $time] $Message" -ForegroundColor Red
}

function Assert {
    param(
        [bool]$Condition,
        [string]$Message
    )
    if (-not $Condition) {
        ErrorOut "Assertion failed: $Message"
        throw "Assertion failed: $Message"
    } elseif ($DebugMode) {
        DebugOut "Assert OK: $Message"
    }
}

Export-ModuleMember -Function WriteOut, DebugOut, WarnOut, ErrorOut, Assert
# endregion
