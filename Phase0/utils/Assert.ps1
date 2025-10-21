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
