function Show-Phase0Banner {
    param ([string]$Branch = "main")

    # --- Load Theme -----------------------------------------------------
    $themePath = Join-Path $PSScriptRoot "Phase0.Theme.ps1"
    if (Test-Path $themePath) {
        . $themePath
    }
    else {
        Write-Host "[Phase0.Banner] Theme not found, using fallback colors." -ForegroundColor Yellow
        $Phase0Theme = @{ BannerOkFrame="Cyan"; BannerWarnFrame="DarkYellow" }
    }

    $user     = $env:USERNAME
    $machine  = $env:COMPUTERNAME
    $ver      = $PSVersionTable.PSVersion
    $date     = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $repo     = (git rev-parse --show-toplevel 2>$null)

    # --- Discover root & baseline ---------------------------------------
    $coreRoot   = $PSScriptRoot
    $phase0Root = Split-Path $coreRoot -Parent
    $hashFile   = Join-Path $phase0Root "phase0.hash.json"

    $hashStatus = "No baseline"
    $warnLevel  = $false
    $changed    = @()

    if (Test-Path $hashFile) {
        try {
            $json = Get-Content $hashFile -Raw | ConvertFrom-Json
            $fileCount = ($json.PSObject.Properties | Measure-Object).Count
            $hashDate  = (Get-Item $hashFile).LastWriteTimeUtc.ToString("yyyy-MM-ddTHH:mm:ssZ")

            $currentFiles = Get-ChildItem -Path $phase0Root -Recurse -Include *.ps1
            foreach ($f in $currentFiles) {
                $rel = $f.FullName.Substring($phase0Root.Length + 1)
                $newHash = (Get-FileHash $f.FullName -Algorithm SHA256).Hash
                if (-not $json.PSObject.Properties.Name.Contains($rel)) {
                    $changed += "NEW: $rel"
                }
                elseif ($json.$rel -ne $newHash) {
                    $changed += "MODIFIED: $rel"
                }
            }

            foreach ($oldKey in $json.PSObject.Properties.Name) {
                if (-not ($currentFiles.FullName -match [regex]::Escape($oldKey))) {
                    $changed += "REMOVED: $oldKey"
                }
            }

            if ($changed.Count -gt 0) {
                $hashStatus = "$($Phase0Theme.Symbols.Warning) Integrity mismatch ($($changed.Count) file(s) differ)"
                $warnLevel = $true
            } else {
                $hashStatus = "$($Phase0Theme.Symbols.OK) $fileCount files | Baseline: $hashDate"
            }
        }
        catch {
            $hashStatus = "$($Phase0Theme.Symbols.Error) Invalid baseline"
            $warnLevel = $true
        }
    }
    else { $warnLevel = $true }

    # --- Pick Frame Colors ----------------------------------------------
    $frameColor = if ($warnLevel) { $Phase0Theme.BannerWarnFrame } else { $Phase0Theme.BannerOkFrame }

    Write-Host ""
    Write-Host "==============================================================" -ForegroundColor $frameColor
    Write-Host " Phase0 Bootstrap – Host: $machine  |  Branch: $Branch" -ForegroundColor $frameColor
    Write-Host " User: $user  |  PSVersion: $ver" -ForegroundColor $frameColor
    if ($repo) { Write-Host " RepoRoot: $repo" -ForegroundColor $frameColor }
    Write-Host " Date: $date" -ForegroundColor $frameColor
    Write-Host " Integrity: $hashStatus" -ForegroundColor $frameColor

    if ($warnLevel -and $changed.Count -gt 0) {
        Write-Host ""
        Write-Host " $($Phase0Theme.Symbols.Warning) Changed files:" -ForegroundColor $Phase0Theme.IntegrityWarn
        $changed | Select-Object -First 3 | ForEach-Object {
            Write-Host "   - $_" -ForegroundColor $Phase0Theme.IntegrityWarn
        }
        if ($changed.Count -gt 3) {
            Write-Host "   ...and $($changed.Count - 3) more." -ForegroundColor $Phase0Theme.IntegrityWarn
        }
    }

    Write-Host "==============================================================" -ForegroundColor $frameColor
    Write-Host ""
}
