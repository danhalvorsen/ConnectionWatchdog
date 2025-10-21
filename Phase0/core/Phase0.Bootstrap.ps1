# Phase0.Bootstrap.ps1
param([switch]$AutoPull)

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (git rev-parse --show-toplevel 2>$null)

if (-not $repoRoot) {
    Write-Host "Not inside a Git repository. Proceeding standalone..." -ForegroundColor Yellow
} else {
    Write-Host "Git repository root found at: $repoRoot"
    $branch = git rev-parse --abbrev-ref HEAD
    Write-Host "Current branch: $branch"
    if ($AutoPull) {
        Write-Host "Pulling latest from origin/$branch..."
        git pull origin $branch
    }
}

. "$root\Phase0.All.ps1"
Write-Host "[Phase0] Bootstrap completed successfully." -ForegroundColor Green
