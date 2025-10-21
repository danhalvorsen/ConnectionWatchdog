# ==============================================================
# PHASE0 BOOTSTRAP (SMART GIT ROOT DISCOVERY)
# --------------------------------------------------------------
# Finds the nearest .git folder upward, ensures folders exist,
# optionally pulls latest from origin/<branch>, then runs Phase0.All.ps1.
# ==============================================================

param(
    [string] $Branch = "main",
    [switch] $AutoPull
)

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$phaseRoot = $root

# --- Locate nearest .git folder --------------------------------
$gitRoot = $null
$probe = $phaseRoot
while ($probe -and -not (Test-Path (Join-Path $probe ".git"))) {
    $parent = Split-Path $probe -Parent
    if ($parent -eq $probe) { break }  # reached drive root
    $probe = $parent
}
if (Test-Path (Join-Path $probe ".git")) { $gitRoot = $probe }

if ($null -eq $gitRoot) {
    Write-Warning "No .git directory found above $phaseRoot."
} else {
    Write-Host "Git repository root found at: $gitRoot"
}

# --- Ensure local work folders --------------------------------
$folders = @("logs","temp","Templates")
foreach ($f in $folders) {
    $p = Join-Path $phaseRoot $f
    if (-not (Test-Path $p)) {
        New-Item -ItemType Directory -Path $p | Out-Null
        Write-Host "Created folder: $p"
    }
}

# --- Git sync (if repo found) ---------------------------------
if ($gitRoot) {
    try {
        $current = (git -C $gitRoot rev-parse --abbrev-ref HEAD).Trim()
        Write-Host "Current branch: $current"
        if ($current -ne $Branch) {
            Write-Warning "Switching from $current to $Branch..."
            git -C $gitRoot checkout $Branch | Out-Null
        }
        if ($AutoPull) {
            Write-Host "Pulling latest from origin/$Branch..."
            git -C $gitRoot pull origin $Branch | Out-Null
            Write-Host "Git sync completed."
        }
    }
    catch {
        Write-Warning "Git operation failed: $_"
    }
}

# --- Verify Phase0 core files ---------------------------------
$core = @("Phase0.All.ps1","Dependencies.ps1","Assert.ps1","Process-Handling.ps1","Dummy.ps1")
$missing = $core | Where-Object { -not (Test-Path (Join-Path $phaseRoot $_)) }

if ($missing.Count -gt 0) {
    Write-Warning "Missing core files: $($missing -join ', ')"
    Write-Host "Run 'git pull origin $Branch' or verify repository integrity."
    exit 1
}

# --- Launch the core runtime ----------------------------------
$all = Join-Path $phaseRoot "Phase0.All.ps1"
Write-Host "Launching Phase0.All.ps1..."
& $all
