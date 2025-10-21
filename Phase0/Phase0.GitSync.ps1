param([string]$ExpectedBranch="master",[switch]$AutoPull)
$root=Split-Path -Parent $MyInvocation.MyCommand.Path
$log=Join-Path $root "logs/git-sync.log"
function Write-GitLog{param([string]$Message,[string]$Level="INFO")$t=(Get-Date -Format "yyyy-MM-dd HH:mm:ss");Add-Content -Path $log -Value "[$t][$Level] $Message"}
if(-not(Test-Path(Join-Path $root ".git"))){Write-Warning "No .git directory found.";Write-GitLog "Missing .git folder." "WARN";return}
try{$branch=(git -C $root rev-parse --abbrev-ref HEAD).Trim()}catch{Write-Warning "Failed to read branch.";Write-GitLog "Failed to read branch: $_" "ERROR";return}
Write-Host "Current branch: $branch";Write-GitLog "Branch: $branch"
if($branch -ne $ExpectedBranch){Write-Warning "Expected $ExpectedBranch, on $branch.";Write-GitLog "Branch mismatch" "WARN";return}
if($AutoPull){Write-Host "Pulling latest from origin/$ExpectedBranch...";git -C $root pull origin $ExpectedBranch | Tee-Object -FilePath $log -Append;Write-Host "Git sync done.";Write-GitLog "Pull complete" "OK"}
