Get-ChildItem -Path $PSScriptRoot | Unblock-File
Get-ChildItem -Path $PSScriptRoot\Functions\*.ps1 | Foreach-Object{ . $_.FullName }


Export-ModuleMember -Function * -Alias *