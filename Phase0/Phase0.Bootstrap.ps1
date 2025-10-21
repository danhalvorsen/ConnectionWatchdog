# Phase0.Bootstrap.ps1
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$folders=@("logs","temp","Templates")
foreach($f in $folders){$p=Join-Path $root $f;if(-not(Test-Path $p)){New-Item -ItemType Directory -Path $p|Out-Null;Write-Host "Created folder: $p"}}
$gitSync=Join-Path $root "Phase0.GitSync.ps1"
if(Test-Path $gitSync){. $gitSync -ExpectedBranch "master" -AutoPull}
$all=Join-Path $root "Phase0.All.ps1"
if(Test-Path $all){& $all}else{Write-Warning "Phase0.All.ps1 not found."}
