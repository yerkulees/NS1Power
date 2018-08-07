. $PSScriptRoot\Environment.ps1

Get-ChildItem $PSScriptRoot\Functions\* | ForEach-Object {. $_.FullName }