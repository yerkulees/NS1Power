# https://ns1.com/api#account-management
Function Get-AccountSettings {
<#
.SYNOPSIS
Get account contact details and settings
.DESCRIPTION
Returns the basic contact details associated with your account.
.LINK
https://ns1.com/api#get-get-account-contact-details-and-settings
#>
    [CmdletBinding()]
    param (
        
    )
    
    begin {
    }
    
    process {
        Invoke-APIRequest -URI "$BaseURI/account/settings" -Method "Get"
    }
    
    end {
    }
}
function Set-AccountSettings {
<#
.SYNOPSIS
Set account contact details and settings
.DESCRIPTION
Sets and returns the basic contact details associated with your account.
.LINK
https://ns1.com/api#post-modify-contact-details-and-settings
#>
    [CmdletBinding()]
    param (
        # General Account Email Address
        [Parameter(
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true
        )]
        [String]
        $Email,
        # General account country
        [Parameter(
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true
        )]
        [string]
        $Country,
        # General account street address
        [Parameter(
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true
        )]
        [string]
        $Street,
        # General account state
        [Parameter(
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true
        )]
        [string]
        $State,
        # General account city
        [Parameter(
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true
        )]
        [string]
        $City,
        # General account postal code
        [Parameter(
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true
        )]
        [string]
        $PostalCode,
        # General account phone
        [Parameter(
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true
        )]
        [string]
        $Phone,
        # General account company name
        [Parameter(
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true
        )]
        [string]
        $Company,
        # General account last name
        [Parameter(
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true
        )]
        [string]
        $LastName,
        # General account first name
        [Parameter(
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true
        )]
        [string]
        $FirstName
    )
    
    begin {
    }
    
    process {
        $BodyAsHash = @{}
        if($Country -or $Street -or $State -or $City -or $PostalCode){
            $address = @{}
            if($Country){$address.Add("country",$Country)}
            if($Street){$address.Add("street",$Street)}
            if($State){$address.Add("state",$State)}
            if($City){$address.Add("city",$City)}
            if($PostalCode){$address.Add("postalcode",$PostalCode)}
            $BodyAsHash.Add("address",$address)
        }
        
        if($Email){$BodyAsHash.Add("email",$Email)}
        if($Phone){$BodyAsHash.Add("phone",$Phone)}
        if($Company){$BodyAsHash.Add("company",$Company)}
        if($LastName){$BodyAsHash.Add("lastname",$LastName)}
        if($FirstName){$BodyAsHash.Add("firstname",$FirstName)}

        $body = $BodyAsHash | ConvertTo-Json -Depth 2

        Invoke-APIRequest -URI "$baseURL/account/settings" -Method "POST" -Body $Body
    }
    
    end {
    }
}
function Get-OverageAlertingSettings {
<#
.SYNOPSIS
Get overage alerting settings
.DESCRIPTION
Returns toggles and thresholds used when sending overage warning alert messages to users with billing notifications enabled.
#>
    [CmdletBinding()]
    param (
        
    )
    
    begin {
    }
    
    process {
        Invoke-APIRequest -URI "$BaseURI/account/usagewarnings" -Method "Get"
    }
    
    end {
    }
}
function Set-OverageAlertingSettings {
<#
.SYNOPSIS
Modify overage alerting settings

.DESCRIPTION
Changes alerting toggles and thresholds for overage warning alert messages. First thresholds (warning_1) must be smaller than second ones (warning_2) and all thresholds must be percentages between 0 and 100.

#>
    [CmdletBinding()]
    param (
        # Sets queries warning threshold. If you put one number it will set the warning_1 theshold, if you put two it will set the higher number to warning_2
        [Parameter(
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true
        )]
        [ValidateRange(0,100)]
        [ValidateCount(1,2)]
        [Int[]]
        $QueriesWarnings,
        # Sets records warning threshold. If you put one number it will set the warning_1 theshold, if you put two it will set the higher number to warning_2
        [Parameter(
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true
        )]
        [ValidateRange(0,100)]
        [ValidateCount(1,2)]
        [Int[]]
        $RecordsWarnings,
        # Indicates whether warnings should be sent or not if query threshold is met
        [Parameter(
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true
        )]
        [ValidateSet("false","true")]
        [String]
        $QueriesSendWarnings,
        # Indicates whether warnings should be sent or not if record threshold is met
        [Parameter(
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true
        )]
        [ValidateSet("false","true")]
        [String]
        $RecordsSendWarnings
    )
    
    begin {
    }
    
    process {
        $BodyAsHash = @{}
        if($QueriesWarnings -or $QueriesSendWarnings){
            $Queries = @{}
            if($QueriesWarnings.count){
                $i = 1
                foreach($q in ($QueriesWarnings | Sort-Object)){
                    $Queries.Add("warning_$i",$q)
                    $i++
                }
            }
            if($QueriesSendWarnings){
                $Queries.Add("send_warnings",[bool]::Parse($QueriesSendWarnings))
            }
            $BodyAsHash.Add("queries",$Queries)
        }
        if($RecordsWarnings -or $RecordsSendWarnings){
            $Records = @{}
            if($RecordsWarnings){
                $i = 1
                foreach($q in ($RecordsWarnings | Sort-Object)){
                    $Records.Add("warning_$i",$q)
                    $i++
                }
            }
            if($RecordsSendWarnings){
                $Records.Add("send_warnings", [bool]::Parse($RecordsSendWarnings))
            }
            $BodyAsHash.Add("records",$Records)
        }

        $Body = $BodyAsHash | ConvertTo-Json -Depth 2
        
        write-Debug -Message $Body
        
        Invoke-APIRequest -URI "$BaseURI/account/usagewarnings" -Method "POST" -Body $Body
    }
    
    end {
    }
}
function Get-AccountUser {
    [Alias("Get-User")]
    [CmdletBinding(
        DefaultParameterSetName="AllUsers"
    )]
    param (
        # Username to return the details
        [Parameter(
            ParameterSetName="SingleUser"
        )]
        [String[]]
        $UserName
    )
    
    begin {
    }
    
    process {
        Switch($PSCmdlet.ParameterSetName){
            "AllUsers" {
                Invoke-APIRequest -URI "$baseURI/account/users" -Method Get
            }
            "SingleUser" {
                Foreach($User in $UserName){
                    Invoke-APIRequest -URI "$baseURI/account/users/$User" -Method Get
                }
            }
        }
    }
    
    end {
    }
}
function New-AccountUser {
    [Alias("New-User")]
    [CmdletBinding()]
    param (
        # Username to Create
        [Parameter(
            Mandatory=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [String[]]
        $UserName,
        # User's Email Address
        [Parameter(
            Mandatory=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [String]
        $Email,
        # Teams to add user to
        [Parameter(
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true
        )]
        [String[]]
        $Teams,
        # Permission for pushing to datafeeds
        [Parameter(
            Mandatory=$false
        )]
        [ValidateSet("false","true")]
        [String]
        $push_to_datafeeds,
        # Permission for managing datafeeds
        [Parameter(
            Mandatory=$true
        )]
        [ValidateSet("false","true")]
        [String]
        $manage_datafeeds,
        # Permission for managing datasources
        [Parameter(
            Mandatory=$true
        )]
        [ValidateSet("false","true")]
        [String]
        $manage_datasources,
        # Permission for viewing invoices
        [Parameter(
            Mandatory=$true
        )]
        [ValidateSet("false","true")]
        [String]
        $view_invoices,
        # Permission for viewing activity logs
        [Parameter(
            Mandatory=$true
        )]
        [ValidateSet("false","true")]
        [String]
        $view_activity_log,
        # Permission for managing teams
        [Parameter(
            Mandatory=$true
        )]
        [ValidateSet("false","true")]
        [String]
        $manage_teams,
        # Permission for managing api keys
        [Parameter(
            Mandatory=$true
        )]
        [ValidateSet("false","true")]
        [String]
        $manage_apikey,
        # Permission for managing users
        [Parameter(
            Mandatory=$true
        )]
        [ValidateSet("false","true")]
        [String]
        $manage_users,
        # Permission for managing payment methods
        [Parameter(
            Mandatory=$true
        )]
        [ValidateSet("false","true")]
        [String]
        $manage_payment_methods,
        # Permission for managing billing plan
        [Parameter(
            Mandatory=$true
        )]
        [ValidateSet("false","true")]
        [String]
        $manage_plan,
        # Permission for managing account settings
        [Parameter(
            Mandatory=$true
        )]
        [ValidateSet("false","true")]
        [String]
        $manage_account_settings,
        # Specific zones to allow user access
        [Parameter(
            Mandatory=$false
        )]
        [Alias("allow")]
        [String[]]
        $Zones_allow,
        # Default policy for new zones
        [Parameter(
            Mandatory=$true
        )]
        [ValidateSet("false","true")]
        [Alias("ZoneDefault")]
        [String]
        $Zones_allow_by_default,
        # Permission to manage zones
        [Parameter(
            Mandatory=$true
        )]
        [ValidateSet("false","true")]
        [String]
        $Manage_zones,
        # Permission to view zones
        [Parameter(
            Mandatory=$true
        )]
        [ValidateSet("false","true")]
        [String]
        $View_zones,
        # Permission to manage monitoring lists
        [Parameter(
            Mandatory=$true
        )]
        [ValidateSet("false","true")]
        [String]
        $Manage_lists,
        # Permission to manage monitoring jobs
        [Parameter(
            Mandatory=$true
        )]
        [ValidateSet("false","true")]
        [String]
        $Manage_jobs,
        # Permission to view monitoring jobs
        [Parameter(
            Mandatory=$true
        )]
        [ValidateSet("false","true")]
        [String]
        $View_jobs
    )
    
    begin {
    }
    
    process {
        $BodyAsHash = @{}
        
        $BodyAsHash.Add("username",$UserName)
        if($email){$BodyAsHash.Add("email",$Email)}
        if($name){$BodyAsHash.Add("name",$name)}

        if($Teams){
            $BodyAsHash.Add("teams",@($Teams))
        }else{
            $BodyAsHash.Add("teams",@())
        }

        $Data = @{}
        $Data.Add("push_to_datafeeds",[bool]::Parse($push_to_datafeeds))
        $Data.Add("manage_datafeeds",[bool]::Parse($manage_datafeeds))
        $Data.Add("manage_datasources",[bool]::Parse($manage_datasources))

        $Account = @{}
        $Account.Add("view_invoices",[bool]::Parse($view_invoices))
        $Account.Add("view_activity_log",[bool]::Parse($view_activity_log))
        $Account.Add("manage_teams",[bool]::Parse($manage_datafeeds))
        $Account.Add("manage_apikeys",[bool]::Parse($manage_apikey))
        $Account.Add("manage_users",[bool]::Parse($manage_users))
        $Account.Add("manage_payment_methods",[bool]::Parse($manage_payment_methods))
        $Account.Add("manage_plan",[bool]::Parse($manage_plan))
        $Account.Add("manage_account_settings",[bool]::Parse($manage_account_settings))

        $Dns = @{}

        if($Zones_allow){
            $Dns.Add("zones_allow",@($Zones_allow))
        }else{
            $Dns.Add("zones_allow",@())
        }

        $Dns.Add("zones_allow_by_default",$Zones_allow_by_default)
        $Dns.Add("manage_zones",[bool]::Parse($Manage_zones))
        $Dns.Add("view_zones",[bool]::Parse($View_zones))

        $Monitoring = @{}
        $Monitoring.Add("manage_lists",[bool]::Parse($Manage_lists))
        $Monitoring.Add("manage_jobs",[bool]::Parse($Manage_jobs))
        $Monitoring.Add("view_jobs",[bool]::Parse($View_jobs))

        $Permissions = @{}
        $Permissions.Add("data",$Data)
        $Permissions.Add("account",$Account)
        $Permissions.Add("dns",$Dns)
        $Permissions.Add("monitoring",$Monitoring)

        $BodyAsHash.Add("permissions",$Permissions)

        $Body = $BodyAsHash | ConvertTo-Json -Depth 3

        Write-Debug -Message $Body

        Invoke-APIRequest -URI "$baseURI/account/users/$UserName" -Method "PUT" -Body $Body
    }
    
    end {
    }
}
function Set-AccountUser {
    [Alias("Set-User")]
    [CmdletBinding()]
    param (
        # Username to Create
        [Parameter(
            Mandatory=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [String[]]
        $UserName,
        # User's Email Address
        [Parameter(
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true
        )]
        [String]
        $Email,
        # Teams to add user to. Use "" to set to empty array.
        [Parameter(
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true
        )]
        [AllowEmptyCollection()]
        [String[]]
        $Teams,
        # Permission for pushing to datafeeds
        [Parameter(
            Mandatory=$false
        )]
        [ValidateSet("false","true")]
        [String]
        $push_to_datafeeds,
        # Permission for managing datafeeds
        [Parameter(
            Mandatory=$false
        )]
        [ValidateSet("false","true")]
        [String]
        $manage_datafeeds,
        # Permission for managing datasources
        [Parameter(
            Mandatory=$false
        )]
        [ValidateSet("false","true")]
        [String]
        $manage_datasources,
        # Permission for viewing invoices
        [Parameter(
            Mandatory=$false
        )]
        [ValidateSet("false","true")]
        [String]
        $view_invoices,
        # Permission for viewing activity logs
        [Parameter(
            Mandatory=$false
        )]
        [ValidateSet("false","true")]
        [String]
        $view_activity_log,
        # Permission for managing teams
        [Parameter(
            Mandatory=$false
        )]
        [ValidateSet("false","true")]
        [String]
        $manage_teams,
        # Permission for managing api keys
        [Parameter(
            Mandatory=$false
        )]
        [ValidateSet("false","true")]
        [String]
        $manage_apikey,
        # Permission for managing users
        [Parameter(
            Mandatory=$false
        )]
        [ValidateSet("false","true")]
        [String]
        $manage_users,
        # Permission for managing payment methods
        [Parameter(
            Mandatory=$false
        )]
        [ValidateSet("false","true")]
        [String]
        $manage_payment_methods,
        # Permission for managing billing plan
        [Parameter(
            Mandatory=$false
        )]
        [ValidateSet("false","true")]
        [String]
        $manage_plan,
        # Permission for managing account settings
        [Parameter(
            Mandatory=$false
        )]
        [ValidateSet("false","true")]
        [String]
        $manage_account_settings,
        # Specific zones to allow user access. Set to 
        [Parameter(
            Mandatory=$false
        )]
        [Alias("allow")]
        [AllowEmptyCollection()]
        [String[]]
        $Zones_allow,
        # Default policy for new zones
        [Parameter(
            Mandatory=$false
        )]
        [ValidateSet("false","true")]
        [Alias("ZoneDefault")]
        [String]
        $Zones_allow_by_default,
        # Permission to manage zones
        [Parameter(
            Mandatory=$false
        )]
        [ValidateSet("false","true")]
        [String]
        $Manage_zones,
        # Permission to view zones
        [Parameter(
            Mandatory=$false
        )]
        [ValidateSet("false","true")]
        [String]
        $View_zones,
        # Permission to manage monitoring lists
        [Parameter(
            Mandatory=$false
        )]
        [ValidateSet("false","true")]
        [String]
        $Manage_lists,
        # Permission to manage monitoring jobs
        [Parameter(
            Mandatory=$false
        )]
        [ValidateSet("false","true")]
        [String]
        $Manage_jobs,
        # Permission to view monitoring jobs
        [Parameter(
            Mandatory=$false
        )]
        [ValidateSet("false","true")]
        [String]
        $View_jobs
    )
    
    begin {
    }
    
    process {
        $BodyAsHash = @{}
        
        #$BodyAsHash.Add("username",$UserName)

        if($email){$BodyAsHash.Add("email",$Email)}
        if($name){$BodyAsHash.Add("name",$name)}

        if($null -eq $teams){
            $BodyAsHash.Add("teams",@())
        }elseif($Teams){
            $BodyAsHash.Add("teams",@($Teams))
        }

        if($push_to_datafeeds -or $manage_datafeeds -or $manage_datasources){
            $Data = @{}
            if($push_to_datafeeds){
                $Data.Add("push_to_datafeeds",[bool]::Parse($push_to_datafeeds))
            }
            if($manage_datafeeds){
                $Data.Add("manage_datafeeds",[bool]::Parse($manage_datafeeds))
            }
            if($manage_datasources){
                $Data.Add("manage_datasources",[bool]::Parse($manage_datasources))
            }
            
        }

        if($view_invoices -or $view_activity_log -or $manage_teams -or $manage_apikey -or $manage_users -or $manage_payment_methods -or $manage_plan -or $manage_account_settings){
            $Account = @{}
            if($view_invoices){
                $Account.Add("view_invoices",[bool]::Parse($view_invoices))
            }
            if($view_activity_log){
                $Account.Add("view_activity_log",[bool]::Parse($view_activity_log))
            }
            if($manage_teams){
                $Account.Add("manage_teams",[bool]::Parse($manage_datafeeds))
            }
            if($manage_apikey){
                $Account.Add("manage_apikeys",[bool]::Parse($manage_apikey))
            }
            if($manage_users){
                $Account.Add("manage_users",[bool]::Parse($manage_users))
            }
            if($manage_payment_methods){
                $Account.Add("manage_payment_methods",[bool]::Parse($manage_payment_methods))
            }
            if($manage_plan){
                $Account.Add("manage_plan",[bool]::Parse($manage_plan))
            }
            if($manage_account_settings){
                $Account.Add("manage_account_settings",[bool]::Parse($manage_account_settings)) 
            }
        }

        if($Zones_allow -or $Zones_allow_by_default -or $Manage_zones -or $View_zones){
            $Dns = @{}
            if($null -eq $Zones_allow){
                $Dns.Add("zones_allow",@())
            }elseif($Zones_allow){
                $Dns.Add("zones_allow",@($Zones_allow))
            }
            if($Zones_allow_by_default){
                $Dns.Add("zones_allow_by_default",$Zones_allow_by_default)
            }
            if($Manage_zones){
                $Dns.Add("manage_zones",[bool]::Parse($Manage_zones))
            }
            if($View_zones){
                $Dns.Add("view_zones",[bool]::Parse($View_zones))
            }
        }

        if($Manage_lists -or $Manage_jobs -or $View_jobs){
            $Monitoring = @{}
            if($Manage_lists){
                $Monitoring.Add("manage_lists",[bool]::Parse($Manage_lists))
            }
            if($Manage_jobs){
                $Monitoring.Add("manage_jobs",[bool]::Parse($Manage_jobs))
            }
            if($View_jobs){
                $Monitoring.Add("view_jobs",[bool]::Parse($View_jobs))
            }
        }

        if($Data -or $Account -or $Dns -or $Monitoring){
            $Permissions = @{}
            if($Data){
                $Permissions.Add("data",$Data)
            }
            if($Account){
                $Permissions.Add("account",$Account)
            }
            if($Dns){
                $Permissions.Add("dns",$Dns)
            }
            if($Monitoring){
                $Permissions.Add("monitoring",$Monitoring)
            }
        }

        if($Permissions){
            $BodyAsHash.Add("permissions",$Permissions)
        }

        $Body = $BodyAsHash | ConvertTo-Json -Depth 3

        Write-Debug -Message $Body

        Invoke-APIRequest -URI "$baseURI/account/users/$UserName" -Method "PUT" -Body $Body
    }
    
    end {
    }
}