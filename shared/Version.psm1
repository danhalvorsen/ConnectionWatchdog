#requires -Version 7
<#
.SYNOPSIS
  Version management feature for all scripts.
.DESCRIPTION
  Provides structured access to version.json for reading,
  incrementing, and writing version info.
  Uses Debug.psm1 for consistent logging and quiet operation.
.EXAMPLE
  Import-Module "$PSScriptRoot\Version.psm1" -ArgumentList $DebugMode -Force
  $info = Get-VersionInfo
  Increment-V
