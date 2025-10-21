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
