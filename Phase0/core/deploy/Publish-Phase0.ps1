# deploy/Publish-Phase0.ps1
param(
    [string]$OutputPath = "$PSScriptRoot/../../dist",
    [switch]$VerboseOutput
)

$ErrorActionPreference = 'Stop'

Write-Host "Publishing Phase0 module..." -ForegroundColor Cyan

$root = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath | Out-Null
}

Copy-Item -Recurse -Force `
    -Path "$root\*" `
    -Destination $OutputPath `
    -Exclude @('*.git', 'node_modules', 'dist')

Write-Host "Phase0 module exported to: $OutputPath" -ForegroundColor Green
