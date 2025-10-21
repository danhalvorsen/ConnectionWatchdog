# ==============================================================
# Phase0.Theme.psm1
# --------------------------------------------------------------
# Theme engine for Phase0 runtime (supports persistence + color)
# ==============================================================

# --- Resolve paths -------------------------------------------------------
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$phase0Root = Split-Path $scriptRoot -Parent
$configFile = Join-Path $phase0Root ".phase0rc.json"

# --- Built-in themes ----------------------------------------------------
$Phase0Themes = [ordered]@{
    Default = [ordered]@{
        Name = "Default"
        InfoColor       = "Cyan"
        WarnColor       = "DarkYellow"
        ErrorColor      = "Red"
        AccentColor     = "DarkCyan"
        BannerTextColor = "White"
        BannerOkFrame   = "Cyan"
        BannerWarnFrame = "DarkYellow"
        BannerErrorFrame = "Red"
        IntegrityOk     = "Cyan"
        IntegrityWarn   = "Yellow"
        IntegrityError  = "Red"
        Symbols = @{
            OK      = "✅"
            Warning = "⚠️"
            Error   = "❌"
            Info    = "ℹ️"
        }
    }

    NightMode = [ordered]@{
        Name = "NightMode"
        InfoColor       = "Magenta"
        WarnColor       = "DarkYellow"
        ErrorColor      = "Red"
        AccentColor     = "DarkMagenta"
        BannerTextColor = "Gray"
        BannerOkFrame   = "DarkMagenta"
        BannerWarnFrame = "DarkYellow"
        BannerErrorFrame = "Red"
        IntegrityOk     = "Magenta"
        IntegrityWarn   = "Yellow"
        IntegrityError  = "Red"
        Symbols = @{
            OK      = "🌙"
            Warning = "🔥"
            Error   = "💀"
            Info    = "🕯️"
        }
    }

    Monochrome = [ordered]@{
        Name = "Monochrome"
        InfoColor       = "White"
        WarnColor       = "White"
        ErrorColor      = "White"
        AccentColor     = "White"
        BannerTextColor = "White"
        BannerOkFrame   = "White"
        BannerWarnFrame = "White"
        BannerErrorFrame = "White"
        IntegrityOk     = "White"
        IntegrityWarn   = "White"
        IntegrityError  = "White"
        Symbols = @{
            OK      = "[OK]"
            Warning = "[!]"
            Error   = "[X]"
            Info    = "[i]"
        }
    }
} # ✅ this closes the $Phase0Themes hashtable

# --- Load persisted config ----------------------------------------------
if (Test-Path $configFile) {
    try {
        $cfg = Get-Content $configFile -Raw | ConvertFrom-Json
        if ($Phase0Themes.Contains($cfg.Theme)) {
            $Global:Phase0Theme = $Phase0Themes[$cfg.Theme]
        } else {
            $Global:Phase0Theme = $Phase0Themes.Default
        }
    }
    catch {
        $Global:Phase0Theme = $Phase0Themes.Default
    }
}
else {
    $Global:Phase0Theme = $Phase0Themes.Default
}

# --- Public functions ---------------------------------------------------
function Set-Phase0Theme {
    [CmdletBinding()]
    param(
        [ValidateSet("Default","NightMode","Monochrome")]
        [string]$Name = "Default"
    )

    if ($Phase0Themes.Contains($Name)) {
        $Global:Phase0Theme = $Phase0Themes[$Name]
        $cfg = @{ Theme = $Name }
        $cfg | ConvertTo-Json -Depth 2 | Out-File -FilePath $configFile -Encoding UTF8
        Write-Host "[Phase0.Theme] Switched to theme: $Name" -ForegroundColor $Phase0Theme.AccentColor
    }
    else {
        Write-Warning "[Phase0.Theme] Unknown theme name: $Name"
    }
}

function Get-Phase0Theme {
    Write-Host ""
    Write-Host "==============================================================" -ForegroundColor $Phase0Theme.BannerOkFrame
    Write-Host " Active Theme: $($Phase0Theme.Name)" -ForegroundColor $Phase0Theme.AccentColor
    Write-Host " InfoColor: $($Phase0Theme.InfoColor)" -ForegroundColor $Phase0Theme.InfoColor
    Write-Host " WarnColor: $($Phase0Theme.WarnColor)" -ForegroundColor $Phase0Theme.WarnColor
    Write-Host " ErrorColor: $($Phase0Theme.ErrorColor)" -ForegroundColor $Phase0Theme.ErrorColor
    Write-Host "==============================================================" -ForegroundColor $Phase0Theme.BannerOkFrame
    Write-Host ""
}

Export-ModuleMember -Function Set-Phase0Theme, Get-Phase0Theme
