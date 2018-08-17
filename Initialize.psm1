
Get-ChildItem -Path $PSScriptRoot -Recurse | Unblock-File

. $(Get-Item -Path $PSScriptRoot\Environment.ps1).FullName
Get-ChildItem -Path $PSScriptRoot\Functions\*.ps1 | Foreach-Object{ . $_.FullName }

$Functions = 'Find-Zone',
    'Get-AccountSettings',
    'Get-DataFeeds',
    'Get-DataSources',
    'Get-FilterTypes',
    'Get-Metadata',
    'Get-MonitoringJob',
    'Get-MonitoringJobHistoricMetrics',
    'Get-MonitoringJobHistoricStatus',
    'Get-MonitoringJobTypes',
    'Get-MonitoringRegions',
    'Get-Networks',
    'Get-NotificationList',
    'Get-NotificationTypes',
    'Get-QPS',
    'Get-UsageStats',
    'Get-ZoneRecord',
    'Invoke-APIRequest',
    'New-DataFeed',
    'New-DataSource',
    'New-MonitoringJob',
    'New-NotificationList',
    'New-Record',
    'New-Zone',
    'Remove-DataFeed',
    'Remove-DataSource',
    'Remove-MonitoringJob',
    'Remove-NotificationList',
    'Remove-Zone',
    'Set-AccountSettings',
    'Set-DataFeed',
    'Set-DataSource',
    'Set-KeyFile',
    'Set-MonitoringJob',
    'Set-NotificationList',
    'Set-PublishDataSource',
    'Set-Record',
    'Set-Zone'

$ModuleAlias = "Get-Zone",
    "Get-Record"

Export-ModuleMember -Function $Functions -Alias $ModuleAlias