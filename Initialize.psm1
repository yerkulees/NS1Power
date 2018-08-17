
Get-ChildItem -Path $PSScriptRoot -Recurse | Unblock-File

. $(Get-Item -Path $PSScriptRoot\Environment.ps1).FullName
Get-ChildItem -Path $PSScriptRoot\Functions\*.ps1 | Foreach-Object{ . $_.FullName }

$Functions = 'Find-NS1Zone',
    'Get-NS1AccountSettings',
    'Get-NS1DataFeeds',
    'Get-NS1DataSources',
    'Get-NS1FilterTypes',
    'Get-NS1Headers',
    'Get-NS1Metadata',
    'Get-NS1MonitoringJob',
    'Get-NS1MonitoringJobHistoricMetrics',
    'Get-NS1MonitoringJobHistoricStatus',
    'Get-NS1MonitoringJobTypes',
    'Get-NS1MonitoringRegions',
    'Get-NS1Networks',
    'Get-NS1NotificationList',
    'Get-NS1NotificationTypes',
    'Get-NS1QPS',
    'Get-NS1UsageStats',
    'Get-NS1ZoneRecord',
    'Invoke-NS1APIRequest',
    'New-NS1DataFeed',
    'New-NS1DataSource',
    'New-NS1MonitoringJob',
    'New-NS1NotificationList',
    'New-NS1Record',
    'New-NS1Zone',
    'Remove-NS1DataFeed',
    'Remove-NS1DataSource',
    'Remove-NS1MonitoringJob',
    'Remove-NS1NotificationList',
    'Remove-NS1Zone',
    'Set-NS1AccountSettings',
    'Set-NS1DataFeed',
    'Set-NS1DataSource',
    'Set-NS1KeyFile',
    'Set-NS1MonitoringJob',
    'Set-NS1NotificationList',
    'Set-NS1PublishDataSource',
    'Set-NS1Record',
    'Set-NS1Zone'

Export-ModuleMember -Function $Functions