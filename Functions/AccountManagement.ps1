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
        Invoke-APIRequest -URL "$BaseURI/account/settings" -Method "Get"
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

        Invoke-APIRequest -URL "$baseURL/account/settings" -Method "POST" -Body $Body
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
        Invoke-APIRequest -URL $BaseURI/account/usagewarnings -Method "Get"
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
        [ValidateCount(2)]
        [Int[]]
        $QueriesWarnings,
        # Sets records warning threshold. If you put one number it will set the warning_1 theshold, if you put two it will set the higher number to warning_2
        [Parameter(
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true
        )]
        [ValidateRange(0,100)]
        [ValidateCount(2)]
        [Int[]]
        $RecordsWarnings,
        # Indicates whether warnings should be sent or not if query threshold is met
        [Parameter(
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true
        )]
        [bool]
        $QueriesSendWarnings,
        # Indicates whether warnings should be sent or not if record threshold is met
        [Parameter(
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true
        )]
        [bool]
        $RecordsSendWarnings
    )
    
    begin {
    }
    
    process {
        $BodyAsHash = @{}
        if($QueriesWarnings){
            $Queries = @{}
            if($QueriesWarnings.count -lt 2){
                $i = 1
                foreach($q in ($QueriesWarnings | Sort-Object -Descending)){
                    $Queries.Add("warning_$i",$q)
                    $i++
                }
            }
            if($null -ne $QueriesSendWarnings){
                $Queries.Add("send_warnings",$QueriesWarnings)
            }
            $BodyAsHash.Add("queries",$Queries)
        }
        if($RecordsWarnings){
            $Records = @{}
            if($RecordsWarnings.count -lt 2){
                $i = 1
                foreach($q in ($RecordsWarnings | Sort-Object -Descending)){
                    $Records.Add("warning_$i",$q)
                    $i++
                }
            }
            if($null -ne $RecordsWarnings){
                $Records.Add("send_warnings",$RecordsWarnings)
            }
            $BodyAsHash.Add("records",$Records)
        }

        $Body = $BodyAsHash | ConvertTo-Json -Depth 2

        Invoke-APIRequest -URL "$BaseURI/account/usagewarnings" -Method "POST" -Body $Body
    }
    
    end {
    }
}
