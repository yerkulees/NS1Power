<# 

# Rate Limiting
NS1 Takes adavantage of Rate Limiting so we're using Invoke-WebRequest instead of
Invoke-RestMethod to utilize the rate limiting headers. All Rate Limiting logic 
should happen within the Invoke-NS1APIRequest function. All other functions should
send API requests through that function

https://ns1.com/knowledgebase/api-rate-limiting

Response should be:
String
Hash (ConvertFrom-Json)

Microsoft.PowerShell.Commands.HtmlWebResponseObject

# API Key
The API key is protected using the secure string method used by powershell to 
encrypt all credentials. 

#>

#Vars
$BaseURI = "https://api.nsone.net/v1"

$Global:NS1RateLimits = @{}

# Setting and Retrieving the API Key
Function Set-NS1KeyFile {
    Read-Host -Prompt "Enter API Key:" -AsSecureString | ConvertFrom-SecureString | Set-Content $KeyPath
}

Function Get-NS1APIKey {
    if(Test-Path $KeyPath){
        $SecurePassword = Get-Content $KeyPath | ConvertTo-SecureString
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
        [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    }else{
        Write-Error "API Key was called but key file does not exist. Use Set-NS1KeyFile to set the NS1 key file"
        Set-NS1KeyFile
    }
}

Function Get-NS1Headers {
    @{"X-NSONE-Key"= $(Get-NS1APIKey)}
}

Function Invoke-NS1APIRequest {
<#

.SYNOPSIS
This function handles the actual web request, api limiting, and error handling for the NS1Power.
Don't use cmdlet directly unless necessary.

.DESCRIPTION


#>
    [cmdletbinding()]
    param(
        [Parameter(
            ParameterSetName="Body",
            Mandatory=$true
        )]
        [Parameter(
            ParameterSetName="NoBody",
            Mandatory=$true
        )]
        [system.Uri]$URI,
        [Parameter(
            ParameterSetName="Body",
            Mandatory=$true,
            HelpMessage='Web Request Method'
        )]
        [Parameter(
            ParameterSetName="NoBody",
            Mandatory=$true,
            HelpMessage='Web Request Method'
        )]
        [Microsoft.PowerShell.Commands.WebRequestMethod]$Method,
        [Parameter(
            ParameterSetName="Body",
            Mandatory=$true
        )]
        [Object]$Body
    );

    $Splat = @{
        URI = $URI;
        Method = $Method;
        MaximumRedirection=0;
        UseBasicParsing=$true;
    }

    if($Body){$Splat.Add("Body","$Body")}

    # Rate Limit Logic Here

    Write-Debug "Method: $Method"

    if($NS1RateLimits[$Method.tostring()]){
        if(
            $NS1RateLimits.($method.ToString()).'X-RateLimit-Remaining' -le $SoftRateLimit -and
            ([datetime]::now - $NS1RateLimits.($method.ToString()).dateTime).TotalSeconds -le 5
        ){
            Write-Verbose "Rate Limit Matched. Starting Sleep"
            Start-Sleep -Seconds $SleepTime
        }
    }

    try{
        $WebResponse = Invoke-WebRequest @splat -Headers $(Get-NS1Headers)

        # Set the limit data here
        $NS1RateLimits[$method.ToString()] = @{"X-RateLimit-Remaining"=$WebResponse.headers.'X-RateLimit-Remaining';"dateTime"=[datetime]::now}
        Write-Verbose ("Method: " + $Method.ToString())
        Write-Verbose ("X-RateLimit-Remaining: " + $WebResponse.headers.'X-RateLimit-Remaining')
        Write-Verbose ("X-RateLimit-By: " + $WebResponse.headers.'X-RateLimit-By')
        Write-Verbose ("X-RateLimit-Limit: " + $WebResponse.headers.'X-RateLimit-Limit')
        Write-Verbose ("X-RateLimit-Period: " + $WebResponse.headers.'X-RateLimit-Period')

        # Output
        $WebResponse.content | ConvertFrom-Json
    }catch{
        $Err = $_
        Write-Debug "Error: $($err.Exception.Response.StatusCode.value__)"
        switch($err.Exception.Response.StatusCode.value__){
            {$_ -ge 504} {
                Write-Error -Message $Err.ErrorDetails.Message -Exception $err.Exception
            }
            {$_ -ge 504 -and $_ -ne 504} {
                Write-Error -Message $Err.ErrorDetails.Message -Exception $err.Exception
            }
            {$_ -eq 404} {
                $Err.ErrorDetails.Message | ConvertFrom-Json
            }
            {$_ -eq 400} {
                Write-Error -Message $Err.ErrorDetails.Message -Exception $err.Exception
                $Err.ErrorDetails.Message | ConvertFrom-Json
            }
            {($_ -ge 401 -and $_ -lt 404) -or ($_ -gt 404 -and $_ -lt 500)} {
                Write-Error -Message $Err.ErrorDetails.Message -Exception $err.Exception
                $Err.ErrorDetails.Message | ConvertFrom-Json
            }
        }
    }
}

# Begin Zone and Records Functions
Function Get-NS1ZoneRecord {
<#
.DESCRIPTION
This function can get all active zones, the details of a specific zone, or the details of a specific zone record.

.EXAMPLE
Get-NS1ZoneRecord

.EXAMPLE
Get-NS1ZoneRecord -Zone MyFirstTestZone.com

.EXAMPLE
Get-NS1ZoneRecord -Zone MyFirstTestZone.com -Domain www.MyFirstTestZone.com -RecordType AAAA

#>

    [cmdletbinding(
        DefaultParameterSetName='AllActiveZones'
    )]
    Param(
        [Parameter(
            Position=0,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName="Zone",
            Mandatory = $true
        )]
        [Parameter(
            Position=0,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName="Record",
            Mandatory = $true
        )]
        [String]$Zone,
        [Alias("Record")]
        [Parameter(
            Position=1,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName="Record",
            Mandatory = $true
        )]
        [String]$Domain,
        [Alias("RecordType")]
        [ValidateSet("A", "AAAA", "ALIAS", "AFSDB", "CERT", "CNAME", "DNAME", "HINFO", "MX", "NAPTR", "NS", "PTR", "RP", "SPF", "SRV", "TXT")]
        [Parameter(
            Position=2,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName="Record",
            Mandatory = $true
        )]
        [String]$Type
    );
    
    Switch($PSCmdlet.ParameterSetName){
        "AllActiveZones" {$URI = "$BaseURI/zones"}
        "Zone" {$URI = "$BaseURI/zones/$Zone"}
        "Record" {$URI = "$BaseURI/zones/$Zone/$Domain/$Type"}
    }

    Invoke-NS1APIRequest -URI $URI -Method Get
}

Function New-NS1Zone {
<#
.SYNOPSIS
Create a standard, secondary or linked zone.

.DESCRIPTION
Create a standard, secondary or linked zone.

.NOTES

.LINK
https://ns1.com/api#create-a-new-dns-zone

#>
    [cmdletbinding()]
    Param(
        [Parameter(
            ParameterSetName="Standard",
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName="Secondary",
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName="Linked",
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName="PrimaryWithSlaves",
            Mandatory = $true
        )]
        $Zone,
        [Parameter(
            ParameterSetname="Standard",
            Mandatory = $false
        )]
        [Parameter(
            ParameterSetName="PrimaryWithSlaves",
            Mandatory = $false
        )]
        $TTL,
        [Parameter(
            ParameterSetname="Standard",
            Mandatory = $false
        )]
        [Parameter(
            ParameterSetName="PrimaryWithSlaves",
            Mandatory = $false
        )]
        $refresh,
        [Parameter(
            ParameterSetname="Standard",
            Mandatory = $false
        )]
        [Parameter(
            ParameterSetName="PrimaryWithSlaves",
            Mandatory = $false
        )]
        $retry,
        [Parameter(
            ParameterSetname="Standard",
            Mandatory = $false
        )]
        [Parameter(
            ParameterSetName="PrimaryWithSlaves",
            Mandatory = $false
        )]
        $expiry,
        [Parameter(
            ParameterSetname="Standard",
            Mandatory = $false
        )]
        [Parameter(
            ParameterSetName="PrimaryWithSlaves",
            Mandatory = $false
        )]
        $ns_ttl,
        [Parameter(
            ParameterSetName="Secondary",
            Mandatory = $true
        )]
        [Switch]$enabledAsSecondary,
        [Parameter(
            ParameterSetName="Secondary",
            Mandatory = $true
        )]
        [IPAddress]$primary_ip,
        [Parameter(
            ParameterSetName="Secondary",
            Mandatory = $false
        )]
        [IPAddress]$primary_port,
        [Parameter(
            ParameterSetName="Linked",
            Mandatory = $true
        )]
        [String]$link,
        [Parameter(
            ParameterSetName="PrimaryWithSlaves",
            Mandatory = $true
        )]
        [switch]$EnabledAsPrimary,
        [Parameter(
            ParameterSetName="PrimaryWithSlaves",
            Mandatory = $true
        )]
        [IPaddress[]]$ip,
        [Parameter(
            ParameterSetName="PrimaryWithSlaves",
            Mandatory = $false
        )]
        [Int[]]$port,
        [Parameter(
            ParameterSetName="PrimaryWithSlaves",
            Mandatory = $true
        )]
        [switch[]]$notify
    )

    BEGIN{

    }
    PROCESS{

        $bodyAsHash = @{
            "zone"=$Zone
        }

        Switch($PSCmdlet.ParameterSetName){
            "Standard" {
                if($TTL){$bodyAsHash.Add("ttl",$TTL)}
                if($refresh){$bodyAsHash.Add("refresh",$refresh)}
                if($retry){$bodyAsHash.Add("retry",$retry)}
                if($expiry){$bodyAsHash.Add("retry",$expiry)}
                if($ns_ttl){$bodyAsHash.Add("ns_ttl",$ns_ttl)}
            }
            "Secondary" {
                $SecondaryObject = @{
                    "enabled"=$enabledAsSecondary;
                    "primary_ip"=$primary_ip.IPAddressToString
                }
                if($primary_port){$SecondaryObject.Add("primary_port",$primary_port)}

                $bodyAsHash.Add("secondary",$SecondaryObject)
            }
            "Linked" {
                $bodyAsHash.Add("link",$link)
            }
            "PrimaryWithSlaves"{

                $secondaries = 0..($ip.Count-1)|ForEach-Object{
                    $hash = @{"ip"=$ip[$_]}
                    if(($port.count - 1) -ge $_){$hash.Add("port",$port[$_])}
                    if(($notify.count - 1) -ge $_){$hash.Add("notify",$notify[$_])}
                    $hash
                }

                $PrimaryObject = @{
                    "enabled"=$EnabledAsPrimary;
                    "secondaries"=[System.Array]$secondaries
                }
                
                $bodyAsHash.Add("primary",$PrimaryObject)

            }
        }

        $Body = $bodyAsHash | ConvertTo-Json

        Invoke-NS1APIRequest -URI $BaseURI/zones/$Zone -Method Put -Body $Body
    }

    END{

    }
}

Function New-NS1Record {
<#

.SYNOPSIS

.PARAMETER Answers
This is an Array of Objects but looks different depending on the record type.

For example, 3 MX records looks like @(5,"mx1.mydomain.com"),@(10,"mx2.mydomain.com"),@(15,"mx1.mydomain.com")

For example, 3 A records looks like "1.2.3.4","2.3.4.5","3.4.5.6"

.EXAMPLE
New-NS1Record -zone myfirsttestzone.com -domain myfirsttestzone.com -Type MX -Answers @(5,"mx1.mydomain.com"),@(10,"mx2.mydomain.com"),@(15,"mx1.mydomain.com")

.EXAMPLE
New-NS1Record -zone myfirsttestzone.com -domain myfirsttestzone.com -Type A -Answers "1.2.3.4","2.3.4.5","3.4.5.6"

.LINK
https://ns1.com/api#putcreate-a-new-dns-record

#>
    [cmdletbinding()]
    Param(
        [Parameter(
            ParameterSetName="answer",
            Mandatory=$true
        )]
        [String]$zone,
        [Alias("Record")]
        [Parameter(
            ParameterSetName="answer",
            Mandatory=$true
        )]
        [String]$domain,
        [Alias("RecordType")]
        [Parameter(
            ParameterSetName="answer",
            Mandatory=$true
        )]
        [ValidateSet("A", "AAAA", "ALIAS", "AFSDB", "CERT", "CNAME", "DNAME", "HINFO", "MX", "NAPTR", "NS", "PTR", "RP", "SPF", "SRV", "TXT")]
        [String]$Type,
        [Parameter(
            ParameterSetName="answer",
            Mandatory=$true
        )]
        [Object[]]$answers
    )

    $BodyAsHash = @{
        "zone"=$zone;
        "domain"=$domain;
        "type"=$Type;
        "answers"=@($answers |ForEach-Object{@{"answer" = @($_)}});
    }

    <#
    $BodyAsHash = @{
        "zone"=$zone;
        "domain"=$domain;
        "type"=$Type;
    }
    #>
    #$BodyAsHash.Add("answers",$(ConvertTo-json -InputObject $($answers |%{@{"answer" = @("$_")}})))

    $Body = ConvertTo-Json -InputObject $BodyAsHash -Depth 3

    Write-Debug "Body: $Body"

    Invoke-NS1APIRequest -URI "$BaseURI/zones/$zone/$domain/$Type" -Method Put -Body $Body
}

Function Set-NS1Record {
<#

.SYNOPSIS

.PARAMETER Answers
This is an Array of Objects but looks different depending on the record type.

For example, 3 MX records looks like @(5,"mx1.mydomain.com"),@(10,"mx2.mydomain.com"),@(15,"mx1.mydomain.com")

For example, 3 A records looks like "1.2.3.4","2.3.4.5","3.4.5.6"

.EXAMPLE
Set-NS1Record -zone myfirsttestzone.com -domain myfirsttestzone.com -Type MX -Answers @(5,"mx1.mydomain.com"),@(10,"mx2.mydomain.com"),@(15,"mx1.mydomain.com")

.EXAMPLE
Set-NS1Record -zone myfirsttestzone.com -domain myfirsttestzone.com -Type A -Answers "1.2.3.4","2.3.4.5","3.4.5.6"

.LINK
https://ns1.com/api#putcreate-a-new-dns-record

#>
    [cmdletbinding()]
    Param(
        [Parameter(
            ParameterSetName="answer",
            Mandatory=$true
        )]
        [String]$zone,
        [Alias("Record")]
        [Parameter(
            ParameterSetName="answer",
            Mandatory=$true
        )]
        [String]$domain,
        [Alias("RecordType")]
        [Parameter(
            ParameterSetName="answer",
            Mandatory=$true
        )]
        [ValidateSet("A", "AAAA", "ALIAS", "AFSDB", "CERT", "CNAME", "DNAME", "HINFO", "MX", "NAPTR", "NS", "PTR", "RP", "SPF", "SRV", "TXT")]
        [String]$Type,
        [Parameter(
            ParameterSetName="answer",
            Mandatory=$true
        )]
        [Object[]]$answers
    )

    $BodyAsHash = @{
        "zone"=$zone;
        "domain"=$domain;
        "type"=$Type;
        "answers"=@($answers |ForEach-Object{@{"answer" = @($_)}});
    }

    <#
    $BodyAsHash = @{
        "zone"=$zone;
        "domain"=$domain;
        "type"=$Type;
    }
    #>
    #$BodyAsHash.Add("answers",$(ConvertTo-json -InputObject $($answers |%{@{"answer" = @("$_")}})))

    $Body = ConvertTo-Json -InputObject $BodyAsHash -Depth 3

    Write-Debug "Body: $Body"

    Invoke-NS1APIRequest -URI "$BaseURI/zones/$zone/$domain/$Type" -Method Post -Body $Body
}

Function Remove-NS1Zone {
    [cmdletbinding()]
    param(
        [Parameter(
            ParameterSetName="Zone",
            Mandatory=$true
        )]
        [Parameter(
            ParameterSetName="Record",
            Mandatory=$true
        )]
        $Zone,
        [Alias("Record")]
        [Parameter(
            ParameterSetName="Record",
            Mandatory=$true
        )]
        $Domain,
        [Alias("RecordType")]
        [Parameter(
            ParameterSetName="Record",
            Mandatory=$true
        )]
        $Type

    )

    Switch($PSCmdlet.ParameterSetName){
        "Zone" {
            $URI = "$BaseURI/zones/$Zone"
        }
        "Record" {
            $URI = "$BaseURI/zones/$Zone/$Domain/$Type"
        }
    }
        Invoke-NS1APIRequest -URI $URI -Method Delete
}

Function Set-NS1Zone {
<#
.SYNOPSIS
Update or Create a standard, secondary or linked zone.

.DESCRIPTION

First attempts to update a zone then will attempt to create the zone.

.NOTES

ToDo:
Allow use of JSON objects


.EXAMPLE

Set-NS1Zone -Zone MyFirstTestZone.com

If the zone exists, it will be set to defaults. If it does not exist it will be created with default values.

.EXAMPLE

Set-NS1Zone -Zone MyFirstTestZone.com

If the zone exists, it will be set to defaults. If it does not exist it will be created with default values.

.EXAMPLE

Set-NS1Zone -Zone MyFirstTestZone.com -enabledAsSecondary -primary_ip "192.168.1.1"

If the zone exists, it will be changed to a secondary zone with its primary set to 192.168.1.1, otherwise it will be created.

.EXAMPLE

Set-NS1Zone -Zone MyFirstTestZone.com -enabledAsSecondary $false

If the zone exists, it will be changed from a secondary zone to a primary zone, otherwise an attempt will be made to create it.

.EXAMPLE

Set-NS1Zone -Zone MyFirstTestZone.com -TTL 3600 -Refresh 3600 -Retry 600 -Expiry 604800

If the zone exists, 

.LINK
https://ns1.com/api#create-a-new-dns-zone

#>
    [cmdletbinding()]
    Param(
        [Parameter(
            ParameterSetName="Standard",
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName="Secondary",
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName="Linked",
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName="PrimaryWithSlaves",
            Mandatory = $true
        )]
        $Zone,
        [Parameter(
            ParameterSetname="Standard",
            Mandatory = $false
        )]
        [Parameter(
            ParameterSetName="PrimaryWithSlaves",
            Mandatory = $false
        )]
        [Int]$TTL,
        [Parameter(
            ParameterSetname="Standard",
            Mandatory = $false
        )]
        [Parameter(
            ParameterSetName="PrimaryWithSlaves",
            Mandatory = $false
        )]
        [Int]$refresh,
        [Parameter(
            ParameterSetname="Standard",
            Mandatory = $false
        )]
        [Parameter(
            ParameterSetName="PrimaryWithSlaves",
            Mandatory = $false
        )]
        [Int]$retry,
        [Parameter(
            ParameterSetname="Standard",
            Mandatory = $false
        )]
        [Parameter(
            ParameterSetName="PrimaryWithSlaves",
            Mandatory = $false
        )]
        [Int]$expiry,
        [Parameter(
            ParameterSetname="Standard",
            Mandatory = $false
        )]
        [Parameter(
            ParameterSetName="PrimaryWithSlaves",
            Mandatory = $false
        )]
        [Int]$ns_ttl,
        [Parameter(
            ParameterSetName="Secondary",
            Mandatory = $true
        )]
        [Bool]$enabledAsSecondary,
        [Parameter(
            ParameterSetName="Secondary",
            Mandatory = $false
        )]
        [IPAddress]$primary_ip,
        [Parameter(
            ParameterSetName="Secondary",
            Mandatory = $false
        )]
        [IPAddress]$primary_port,
        [Parameter(
            ParameterSetName="Linked",
            Mandatory = $true
        )]
        [String]$link,
        [Parameter(
            ParameterSetName="PrimaryWithSlaves",
            Mandatory = $true
        )]
        [switch]$EnabledAsPrimary,
        [Parameter(
            ParameterSetName="PrimaryWithSlaves",
            Mandatory = $true
        )]
        [IPaddress[]]$ip,
        [Parameter(
            ParameterSetName="PrimaryWithSlaves",
            Mandatory = $false
        )]
        [Int[]]$port,
        [Parameter(
            ParameterSetName="PrimaryWithSlaves",
            Mandatory = $true
        )]
        [switch[]]$notify

    )

    $bodyAsHash = @{}

    Switch($PSCmdlet.ParameterSetName){
        "Standard" {
            if($TTL){$bodyAsHash.Add("ttl",$TTL)}
            if($refresh){$bodyAsHash.Add("refresh",$refresh)}
            if($retry){$bodyAsHash.Add("retry",$retry)}
            if($expiry){$bodyAsHash.Add("expiry",$expiry)}
            if($ns_ttl){$bodyAsHash.Add("ns_ttl",$ns_ttl)}
        }
        "Secondary" {
            $SecondaryObject = @{
                "enabled"=$enabledAsSecondary;
            }
            if($primary_ip){$SecondaryObject.Add("primary_ip",$primary_ip.IPAddressToString)}
            if($primary_port){$SecondaryObject.Add("primary_port",$primary_port)}

            $bodyAsHash.Add("secondary",$SecondaryObject)
        }
        "Linked" {
            $bodyAsHash.Add("link",$link)
        }
        "PrimaryWithSlaves"{

            $secondaries = 0..($ip.Count-1)|ForEach-Object {
                $hash = @{"ip"=$ip[$_]}
                if(($port.count - 1) -ge $_){$hash.Add("port",$port[$_])}
                if(($notify.count - 1) -ge $_){$hash.Add("notify",$notify[$_])}
                $hash
            }

            $PrimaryObject = @{
                "enabled"=$EnabledAsPrimary;
                "secondaries"=[System.Array]$secondaries
            }
            
            $bodyAsHash.Add("primary",$PrimaryObject)

        }
    }

    $Body = $bodyAsHash | ConvertTo-Json

    Write-Debug "Body: $Body"

    $WebResponse = Invoke-NS1APIRequest -URI $BaseURI/zones/$Zone -Method Post -Body $Body

    Write-Debug "Update $Zone WebRespone: $WebResponse"

    If($WebResponse -and $($WebResponse | ConvertFrom-Json).message -eq "zone not found"){
        
        Write-Debug "Update Failed running create"

        $BodyAsHash.Add("zone",$zone)

        $Body = $bodyAsHash | ConvertTo-Json

        Write-Debug "Body: $Body"

        Invoke-NS1APIRequest -URI $BaseURI/zones/$Zone -Method Put -Body $Body

    }else{
        Write-Debug "Update success"

        $WebResponse
    }

}

Function Find-NS1Zone {
    [cmdletbinding()]
    Param(
        [Alias("q")]
        [Parameter(
            mandatory=$true
        )]
        [String]$querystring,
        [Parameter(
            mandatory=$false
        )]
        [Int]$max,
        [Alias("RecordType")]
        [ValidateSet("zone","record","all")]
        [Parameter(
            mandatory=$false
        )]
        [String]$Type
    )

    $URI = "$BaseURI/search?q=$querystring"

    if($max){$URI = "$URI/&max=$max"}
    if($type){$URI = "$URI/&type=$type"}

    Invoke-NS1APIRequest -URI $URI -Method Get

}

Function Get-NS1Networks {
    [cmdletbinding()]
    Param()
    Invoke-NS1APIRequest -URI $BaseURI/networks -Method Get
}

Function Get-NS1Metadata {
    [cmdletbinding()]
    Param()
    Invoke-NS1APIRequest -URI $BaseURI/metatypes -Method Get
}

Function Get-NS1FilterTypes {
    [cmdletbinding()]
    Param()
    Invoke-NS1APIRequest -URI $BaseURI/filtertypes -Method Get
}

# Begin QPS Functions
Function Get-NS1UsageStats {
    [cmdletbinding(
        DefaultParameterSetName="AllZones"
    )]
    Param(
        [Parameter(
            Position=0,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName="Zone",
            Mandatory = $true
        )]
        [Parameter(
            Position=0,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName="Record",
            Mandatory = $true
        )]
        $zone,
        [Alias("Record")]
        [Parameter(
            Position=1,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName="Record",
            Mandatory = $true
        )]
        $domain,
        [Alias("RecordType")]
        [ValidateSet("A", "AAAA", "ALIAS", "AFSDB", "CERT", "CNAME", "DNAME", "HINFO", "MX", "NAPTR", "NS", "PTR", "RP", "SPF", "SRV", "TXT")]
        [Parameter(
            Position=2,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName="Record",
            Mandatory = $true

        )]
        $type,
        [ValidateSet("1h","24h","30d")]
        [Parameter(
            ParameterSetName="AllZones",
            Mandatory = $false
        )]
        [Parameter(
            ParameterSetName="Record",
            Mandatory = $false

        )]
        [Parameter(
            ParameterSetName="Zone",
            Mandatory = $false
        )]
        [string]$Period,
        [Parameter(
            ParameterSetName="AllZones",
            Mandatory = $false
        )]
        [Parameter(
            ParameterSetName="Zone",
            Mandatory = $false

        )]
        [Bool]$Expand,
        [Parameter(
            ParameterSetName="AllZones",
            Mandatory = $false
        )]
        [Bool]$Aggregate,
        [Parameter(
            ParameterSetName="AllZones",
            Mandatory = $false
        )]
        [Parameter(
            ParameterSetName="Zone",
            Mandatory = $false
        )]
        [Bool]$by_tier
    )

    Switch($PSCmdlet.ParameterSetName){
        "AllZones" {
            $URI = "$BaseURI/stats/usage";
        }
        "Zone" {
            $URI = "$BaseURI/stats/usage/$zone";
        }
        "Record" {
            $URI = "$BaseURI/stats/usage/$zone/$domain/$type"
        }
    }

    if($Period -or $Expand -or $Aggregate -or $by_tier){
        $URI += "?"
        if($Period){
            $URI += "period=$Period;"
        }
        if($Expand){
            $URI += "expand=$expand;"
        }
        if($Aggregate){
            $URI += "aggregate=$Aggregate;"
        }
        if($by_tier){
            $URI += "by_tier=$by_tier;"
        }
        $URI = $URI.trimEnd(';')
    }

    Invoke-NS1APIRequest -URI $URI -Method Get
}

Function Get-NS1QPS {
    [cmdletbinding(
        DefaultParameterSetName="AccountWide"
    )]
    Param(
        [Parameter(
            ParameterSetName="Zone",
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName="Record",
            Mandatory = $true
        )]
        $zone,
        [Alias("Record")]
        [Parameter(
            ParameterSetName="Record",
            Mandatory = $true
        )]
        $domain,
        [Alias("RecordType")]
        [ValidateSet("A", "AAAA", "ALIAS", "AFSDB", "CERT", "CNAME", "DNAME", "HINFO", "MX", "NAPTR", "NS", "PTR", "RP", "SPF", "SRV", "TXT")]
        [Parameter(
            ParameterSetName="Record",
            Mandatory = $true
        )]
        $type
    )

    $URI = "$BaseURI/stats/qps"

    Switch($PSCmdlet.ParameterSetName){
        "AccountWide" {
            
        }
        "Zone" {
            $URI = "$URI/$zone"
        }
        "Record" {
            $URI = "$URI/$zone/$domain/$type"
        }
    }

    Invoke-NS1APIRequest -URI $URI -Method get

}

Function Get-NS1DataSources {
    [cmdletbinding(
        DefaultParameterSetName="AllAvailableDataSources"
    )]
    Param(
        [Parameter(
            ParameterSetName="ActiveDataSources",
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName="DataSource",
            Mandatory = $true
        )]
        [String]$SourceID,
        [Parameter(
            ParameterSetName="ActiveDataSources",
            Mandatory = $true
        )]
        [String]$FeedID
    )

    Switch($PSCmdlet.ParameterSetName) {
        "AllAvailableDataSources" {
            $URI = "$BaseURI/data/sourcetypes"
        }
        "ActiveDataSources" {
            $URI = "$BaseURI/data/feeds/$SourceID/$FeedID"
        }
        "DataSource" {
            $URI = "$BaseURI/data/sources/$SourceID"
        }
    }

    Invoke-NS1APIRequest -URI $URI -Method Get
}

Function Get-NS1DataFeeds {
    [cmdletbinding()]
    Param(
        [Parameter(
            ParameterSetName="ActiveDataFeeds",
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName="DataFeed",
            Mandatory = $true
        )]
        [String]$SourceID,
        [Parameter(
            ParameterSetName="DataFeed",
            Mandatory = $true
        )]
        [String]$FeedID
    )

    Switch($PSCmdlet.ParameterSetName) {
        "DataFeed" {
            $URI = "$BaseURI/data/feeds/$SourceID/$FeedID"
        }
        "ActiveDataFeeds" {
            $URI = "$BaseURI/data/feeds/$SourceID"
        }
    }

    Invoke-NS1APIRequest -URI $URI -Method Get
}

Function New-NS1DataSource {
    [cmdletbinding()]
    Param(
        [Parameter(
            Mandatory = $true
        )]
        [String]$Name,
        [Parameter(
            Mandatory = $true
        )]
        [String]$sourcetype,
        [Parameter(
            Mandatory = $true
        )]
        [String]$secret_key,
        [Parameter(
            Mandatory = $true
        )]
        [String]$api_key
    )

    $bodyAsHash = @{
        "config"=@{
            "secret_key"=$secret_key;
            "api_key"=$api_key;
        }
        "name" = $Name;
        "sourcetype" = $sourcetype
    }

    Invoke-NS1APIRequest -URI "$BaseURI/data/sources" -Method Put -Body ($bodyAsHash | ConvertTo-Json)
}

Function Set-NS1DataSource {
    [cmdletbinding()]
    Param(
        [Parameter(
            Mandatory = $true
        )]
        [String]$SourceID,
        [Parameter(
            Mandatory = $false
        )]
        [String]$Name,
        [Parameter(
            Mandatory = $false
        )]
        [String]$alarm_id,
        [Parameter(
            Mandatory = $false
        )]
        [String]$entity_id
    )

    $BodyAsHash = @{}
    
    if($Name){
        $BodyAsHash.Add("name",$Name)
    }
    if($alarm_id -or $entity_id){
        $config = @{}
        if($alarm_id){
            $config.Add("alarm_id",$alarm_id)
        }
        if($entity_id){
            $config.Add("entity_id",$entity_id)
        }
        $BodyAsHash.Add("config",$config)
    }

    Invoke-NS1APIRequest -URI "$BaseURI/data/sources/$SourceID" -Method post -Body ($BodyAsHash | ConvertTo-Json)

}

Function Remove-NS1DataSource {
    [cmdletbinding()]
    Param(
        [Parameter(
            Mandatory = $true
        )]
        [String]$SourceID
    )

    Invoke-NS1APIRequest -URI "$BaseURI/data/sources/$SourceID" -Method Delete

}

Function New-NS1DataFeed {
    [cmdletbinding()]
    Param(
        [Parameter(
            Mandatory = $true
        )]
        [String]$SourceID,
        [Parameter(
            Mandatory = $true
        )]
        [String]$name,
        [Parameter(
            Mandatory = $true
        )]
        [String]$alarm_id,
        [Parameter(
            Mandatory = $true
        )]
        [String]$entity_id
    )

    $BodyAsHash = @{
        "name"=$name;
        "config"=@{
            "alarm_id"=$alarm_id;
            "entity_id"=$entity_id
        }
    }

    Invoke-NS1APIRequest -URI "$BaseURI/data/feeds/$SourceID" -Method Put -Body ($BodyAsHash | ConvertFrom-Json)
}

Function Set-NS1DataFeed {
    [cmdletbinding()]
    Param(
        [Parameter(
            Mandatory = $true
        )]
        [String]$SourceID,
        [Parameter(
            Mandatory = $false
        )]
        [String]$Name,
        [Parameter(
            Mandatory = $false
        )]
        [String]$alarm_id,
        [Parameter(
            Mandatory = $false
        )]
        [String]$entity_id
    )

    $BodyAsHash = @{}
    
    if($Name){
        $BodyAsHash.Add("name",$Name)
    }
    if($alarm_id -or $entity_id){
        $config = @{}
        if($alarm_id){
            $config.Add("alarm_id",$alarm_id)
        }
        if($entity_id){
            $config.Add("entity_id",$entity_id)
        }
        $BodyAsHash.Add("config",$config)
    }

    Invoke-NS1APIRequest -URI "$BaseURI/data/feeds/$SourceID" -Method post -Body ($BodyAsHash | ConvertTo-Json)
}

Function Remove-NS1DataFeed {
    [cmdletbinding()]
    Param(
        [Parameter(
            Mandatory = $true
        )]
        [String]$SourceID,
        [Parameter(
            Mandatory = $true
        )]
        [String]$FeedID
    )

    Invoke-NS1APIRequest -URI "$BaseURI/data/feeds/$SourceID/$FeedID" -Method Delete
}

Function Set-NS1PublishDataSource {
<#
https://ns1.com/api#postpublish-data-from-a-data-source
#>
    [cmdletbinding()]
    Param(
        
    )

    Write-Error "Set-NS1PublishDataSource does not work yet"

}

# Monitoring & Notifications
Function Get-NS1MonitoringJob {
<#

.DESCRIPTION
Gets the information about a Monitoring Job

.LINK
https://ns1.com/api#get-list-monitoring-jobs
https://ns1.com/api#get-get-a-monitoring-jobs-details
#>
    [cmdletbinding(
        DefaultParameterSetName="AllMonitoringJobs"
    )]
    Param(
        [Alias("ID")]
        [Parameter(
            Position=0,
            ValueFromPipeline=$true,
            ParameterSetName="MonitoringJob",
            Mandatory = $true
        )]
        [String]$JobID
    )

    $URI = "$BaseURI/monitoring/jobs"

    Switch($PSCmdlet.ParameterSetName){
        "AllMonitoringJobs" {}
        "MonitoringJob" {$URI += "/$JobID"}
    }

    Invoke-NS1APIRequest -URI $URI -Method Get
}

Function New-NS1MonitoringJob {
<#
.DESCRIPTION
Creates an NS1 Monitoring Job 

.EXAMPLE

#>
    [cmdletbinding()]
    Param(
        [Parameter(
            ParameterSetName="MonitoringJob",
            Mandatory = $true
        )]
        [String]$Name,
        [Parameter(
            ParameterSetName="MonitoringJob",
            Mandatory = $false
        )]
        [Bool]$Active,
        [ValidateSet("fixed")]
        [Parameter(
            ParameterSetName="MonitoringJob",
            Mandatory = $false
        )]
        [String]$region_scope = "fixed",
        [ValidateSet("LGA","SJC","AMS","DAL","SIN")]
        [ValidateCount(1,3)]
        [Parameter(
            ParameterSetName="MonitoringJob",
            Mandatory = $true
        )]
        [String[]]$regions,
        [ValidateSet("tcp","http","dns","ping")]
        [Parameter(
            ParameterSetName="MonitoringJob",
            Mandatory = $true,
            HelpMessage = "The type of monitoring job to be run"
        )]
        [String]$job_type,
        [Parameter(
            ParameterSetName="MonitoringJob",
            Mandatory = $true,
            HelpMessage="The frequency, in seconds, at which to run the monitoring job in each region. The minimum frequency depends on your account type and billing plan."
        )]
        [int64]$frequency,
        [Parameter(
            ParameterSetName="MonitoringJob",
            Mandatory = $false
        )]
        [Bool]$rapid_recheck,
        [ValidateSet("quorum","all","one")]
        [Parameter(
            ParameterSetName="MonitoringJob",
            Mandatory = $false
        )]
        [String]$policy,
        [Parameter(
            ParameterSetName="MonitoringJob",
            Mandatory = $false
        )]
        [String]$notes,
        [Parameter(
            ParameterSetName="MonitoringJob",
            Mandatory = $true,
            HelpMessage = "Use a powershell hash table, do not use json. A configuration dictionary with keys and values depending on the job_type."
        )]
        [HashTable]$config,
        [ValidateScript({ $_.key -and $_.comparison -and $_.value })]
        [Parameter(
            ParameterSetName="MonitoringJob",
            Mandatory = $true,
            HelpMessage = 'Use a powershell hash table, do not use json. A list of rules for determining failure conditions. Each rule acts on one of the outputs from the monitoring job. You must specify key (the output key); comparison (a comparison to perform on the the output); and value (the value to compare to). For example, {"key":"rtt", "comparison":"<", "value":100} is a rule requiring the rtt from a job to be under 100ms, or the job will be marked failed.'
        )]
        [HashTable[]]$rules,
        [Parameter(
            ParameterSetName="MonitoringJob",
            Mandatory = $false,
            HelpMessage = 'time in seconds after a failure to wait before sending a notification. If the job is marked "up" before this time expires, no notification is sent. Set to 0 to send a notification immediately upon failure.'
        )]
        [int]$notify_delay,
        [ValidateScript({$_ -eq 0 -or $_ -ge 60})]
        [Parameter(
            ParameterSetName="MonitoringJob",
            Mandatory = $false,
            HelpMessage = 'time in seconds between repeat notifications of a failed job. Set to 0 to disable repeating notifications. Otherwise the value must be greater than or equal to 60.'
        )]
        [int]$notify_repeat,
        [Parameter(
            ParameterSetName="MonitoringJob",
            Mandatory = $false,
            HelpMessage = 'If true, a notification is sent when a job returns to an "up" state.'
        )]
        [Bool]$notify_failback,
        [Parameter(
            ParameterSetName="MonitoringJob",
            Mandatory = $false,
            HelpMessage = 'If true, notifications are sent for any regional failure (and failback if desired), in addition to global state notifications.'
        )]
        [Bool]$notify_regional,
        [Parameter(
            ParameterSetName="MonitoringJob",
            Mandatory = $false,
            HelpMessage = 'The id of the notification list to send notifications to. If no list is specified, no notifications will be sent for this job.'
        )]
        [String]$notify_list
    )

    $BodyAsHash = @{
        "name"= $Name;
        "job_type" = $job_type;
        "region_scope" = $region_scope;
        "regions" = ($regions | ForEach-Object ToLower) ;
        "frequency" = $frequency;
        "config" = $config;
        "rules" = $rules;
        "notify_list"= $notify_list
    }

    if($notify_failback){$BodyAsHash.Add("notify_failback",$notify_failback)}
    if($notify_regional){$BodyAsHash.Add("notify_regional",$notify_regional)}

    $Body = $BodyAsHash | ConvertTo-Json -Depth 3

    Invoke-NS1APIRequest -URI "$BaseURI/monitoring/jobs" -Method Put -Body $Body

}

Function Remove-NS1MonitoringJob {
<#
.DESCRIPTION
Immediately terminates and deletes an existing monitoring job. There is no response other than the HTTP status code.

.EXAMPLE
Remove-NS1MonitoringJob -JobID 5b2adb2fa632f6000187fd88

#>
    [cmdletbinding()]
    Param(
        [Parameter(
            Mandatory=$true,
            Position=0,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            HelpMessage = 'JobID'
        )]
        [String]$JobID
    )

    Invoke-NS1APIRequest -URI "$BaseURI/monitoring/jobs/$JobID" -Method Delete

}

Function Set-NS1MonitoringJob {
<#
.DESCRIPTION
Updates a NS1 MonitoringJob.

.EXAMPLE


#>
    [cmdletbinding()]
    Param(
        [Parameter(
            ParameterSetName="MonitoringJob",
            Mandatory = $true
        )]
        [String]$JobID,
        [Parameter(
            ParameterSetName="MonitoringJob",
            Mandatory = $false
        )]
        [String]$Name,
        [Parameter(
            ParameterSetName="MonitoringJob",
            Mandatory = $false
        )]
        [Bool]$Active,
        [ValidateSet("fixed")]
        [Parameter(
            ParameterSetName="MonitoringJob",
            Mandatory = $false
        )]
        [String]$region_scope = "fixed",
        [ValidateSet("LGA","SJC","AMS","DAL","SIN")]
        [ValidateCount(1,3)]
        [Parameter(
            ParameterSetName="MonitoringJob",
            Mandatory = $false
        )]
        [String[]]$regions,
        [ValidateSet("tcp","http","dns","ping")]
        [Parameter(
            ParameterSetName="MonitoringJob",
            Mandatory = $false,
            HelpMessage = "The type of monitoring job to be run"
        )]
        [String]$job_type,
        [Parameter(
            ParameterSetName="MonitoringJob",
            Mandatory = $false,
            HelpMessage="The frequency, in seconds, at which to run the monitoring job in each region. The minimum frequency depends on your account type and billing plan."
        )]
        [int64]$frequency,
        [Parameter(
            ParameterSetName="MonitoringJob",
            Mandatory = $false
        )]
        [Bool]$rapid_recheck,
        [ValidateSet("quorum","all","one")]
        [Parameter(
            ParameterSetName="MonitoringJob",
            Mandatory = $false
        )]
        [String]$policy,
        [Parameter(
            ParameterSetName="MonitoringJob",
            Mandatory = $false
        )]
        [String]$notes,
        [Parameter(
            ParameterSetName="MonitoringJob",
            Mandatory = $false,
            HelpMessage = "Use a powershell hash table, do not use json. A configuration dictionary with keys and values depending on the job_type."
        )]
        [HashTable]$config,
        [ValidateScript({ $_.key -and $_.comparison -and $_.value })]
        [Parameter(
            ParameterSetName="MonitoringJob",
            Mandatory = $false,
            HelpMessage = 'Use a powershell hash table, do not use json. A list of rules for determining failure conditions. Each rule acts on one of the outputs from the monitoring job. You must specify key (the output key); comparison (a comparison to perform on the the output); and value (the value to compare to). For example, {"key":"rtt", "comparison":"<", "value":100} is a rule requiring the rtt from a job to be under 100ms, or the job will be marked failed.'
        )]
        [HashTable[]]$rules,
        [Parameter(
            ParameterSetName="MonitoringJob",
            Mandatory = $false,
            HelpMessage = 'time in seconds after a failure to wait before sending a notification. If the job is marked "up" before this time expires, no notification is sent. Set to 0 to send a notification immediately upon failure.'
        )]
        [int]$notify_delay,
        [ValidateScript({$_ -eq 0 -or $_ -ge 60})]
        [Parameter(
            ParameterSetName="MonitoringJob",
            Mandatory = $false,
            HelpMessage = 'time in seconds between repeat notifications of a failed job. Set to 0 to disable repeating notifications. Otherwise the value must be greater than or equal to 60.'
        )]
        [int]$notify_repeat,
        [Parameter(
            ParameterSetName="MonitoringJob",
            Mandatory = $false,
            HelpMessage = 'If true, a notification is sent when a job returns to an "up" state.'
        )]
        [Bool]$notify_failback,
        [Parameter(
            ParameterSetName="MonitoringJob",
            Mandatory = $false,
            HelpMessage = 'If true, notifications are sent for any regional failure (and failback if desired), in addition to global state notifications.'
        )]
        [Bool]$notify_regional,
        [Parameter(
            ParameterSetName="MonitoringJob",
            Mandatory = $false,
            HelpMessage = 'The id of the notification list to send notifications to. If no list is specified, no notifications will be sent for this job.'
        )]
        [String]$notify_list
    )
    $BodyAsHash = @{}

    if($Name){$BodyAsHash.Add("name",$Name)}
    if($job_type){$BodyAsHash.Add("job_type",$job_type)}
    if($region_scope){$BodyAsHash.Add("region_scope",$region_scope)}
    if($regions){$BodyAsHash.Add("region_scope",($regions | ForEach-Object ToLower))}
    if($frequency){$BodyAsHash.Add("frequency",$frequency)}
    if($config){$BodyAsHash.Add("config",$config)}
    if($rules){$BodyAsHash.Add("rules",$rules)}
    if($notify_list){$BodyAsHash.Add("notify_list",$notify_list)}
    if($notify_failback){$BodyAsHash.Add("notify_failback",$notify_failback)}
    if($notify_regional){$BodyAsHash.Add("notify_regional",$notify_regional)}

    $Body = $BodyAsHash | ConvertTo-Json -Depth 3

    Invoke-NS1APIRequest -URI "$BaseURI/monitoring/jobs/$JobID" -Method Post -Body $Body
}

Function Get-NS1MonitoringJobHistoricStatus {
    [cmdletbinding()]
    Param(
        [Alias("id")]
        [Parameter(
            Position=0,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName="Period",
            Mandatory = $true
        )]
        [Parameter(
            Position=0,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName="StartTime",
            Mandatory = $true
        )]
        [String]$JobID,
        [Parameter(
            ParameterSetName="StartTime",
            Mandatory = $false
        )]
        [DateTime]$Start,
        [Parameter(
            ParameterSetName="StartTime",
            Mandatory = $false
        )]
        [DateTime]$End,
        [ValidateSet("1h","24h","30d")]
        [Parameter(
            Position=1,
            ParameterSetName="Period",
            Mandatory = $true
        )]
        [String]$period,
        [Parameter(
            ParameterSetName="Period",
            Mandatory = $false
        )]
        [Parameter(
            ParameterSetName="StartTime",
            Mandatory = $false
        )]
        [int]$limit,
        [ValidateSet("LGA","SJC","AMS","DAL","SIN")]
        [Parameter(
            ParameterSetName="Period",
            Mandatory = $false
        )]
        [Parameter(
            ParameterSetName="StartTime",
            Mandatory = $false
        )]
        [String]$region,
        [Parameter(
            ParameterSetName="Period",
            Mandatory = $false
        )]
        [Parameter(
            ParameterSetName="StartTime",
            Mandatory = $false
        )]
        [Switch]$exact
    )

    $URI = "$BaseURI/monitoring/history/$JobID"

    if($Start -or $End -or $period -or $limit -or $region -or $exact){
        $URI += "?"
        if($Start){
            $URI += "start={0:G}&" -f [int][double]::Parse((Get-Date -Date $Start -UFormat %s))
        }
        if($End){
            $URI += "end={0:G}&" -f [int][double]::Parse((Get-Date -Date $End -UFormat %s))
        }
        if($period){
            $URI += "period=$period&"
        }
        if($limit){
            $URI += "limit=$limit&"
        }
        if($region){
            $URI += "region=$region&"
        }
        if($exact){
            $URI += "exact=$exact"
        }
        $URI = $URI.TrimEnd("&")
    }
    
    Invoke-NS1APIRequest -URI $URI -Method Get
}

Function Get-NS1MonitoringJobHistoricMetrics {
    [cmdletbinding(
        
    )]
    Param(
        [Parameter(
            Mandatory = $false
        )]
        [String]$JobID,
        [ValidateSet("global","LGA","SJC","AMS","DAL","SIN")]
        [Parameter(
            Mandatory = $false
        )]
        [String]$region,
        [Parameter(
            Mandatory = $false
        )]
        [String]$metric,
        [ValidateSet("1h","24h","30d")]
        [Parameter(
            Mandatory = $false
        )]
        [String]$period
    )

    $URI = "$baseURI/monitoring/metrics/$JobID"
    
    if($region -or $metric -or $period){
        $URI += "?"
        if($region){
            $URI += "region=$region&"
        }
        if($metric){
            $URI += "metric=$metric&"
        }
        if($period){
            $URI += "period=$period"
        }

        $URI = $URI.trimEnd("&")

    }

    Invoke-NS1APIRequest -URI $URI -Method Get

}

Function Get-NS1MonitoringJobTypes {
    [cmdletbinding()]
    Param()

    Invoke-NS1APIRequest -URI "$BaseURI/monitoring/jobtypes" -Method Get
}

Function Get-NS1MonitoringRegions {
    [cmdletbinding()]
    Param()

    Invoke-NS1APIRequest -URI "$BaseURI/monitoring/regions" -Method Get
}

# Notification Lists
Function Get-NS1NotificationList {
    [cmdletbinding(
        DefaultParameterSetName="AllLists"
    )]
    Param(
        [Parameter(
            ParameterSetName="List",
            Mandatory=$true
        )]
        [String]$ListID
    )

    Switch($PSCmdlet.ParameterSetName){
        "AllLists" {
            $URI = "$BaseURI/lists"
        }
        "List" {
            $URI = "$BaseURI/lists/$ListID"
        }
    }

    Invoke-NS1APIRequest -URI $URI -Method Get
}

Function New-NS1NotificationList {
    [cmdletbinding()]
    Param(
        [Parameter(
            Mandatory=$true
        )]
        [String]$Name,
        [Parameter(
            HelpMessage='A list of email addresses'
        )]
        [String[]]$Email,
        [Parameter(
            HelpMessage="A list of nsone datafeed source ID's"
        )]
        [string[]]$SourceID
    )

    $List = foreach($addr in $Email){
        @{"type"="email";"config"= @{ "email"=$addr}}
    }
    $List += foreach($src in $SourceID){
        @{"type"="datafeed";"config"= @{ "sourceid"=$src}}
    }
    $BodyAsHash = @{
        "name"=$Name;
        "notify_list"=@($List)
    }

    $Body = $BodyAsHash | ConvertTo-Json -Depth 3

    Invoke-NS1APIRequest -URI "$BaseURI/lists" -Method Put -Body $Body
}

Function Set-NS1NotificationList {
    [cmdletbinding()]
    Param(
        [Parameter(
            Mandatory=$true
        )]
        [String]$ListID,
        [Parameter(
            Mandatory=$true
        )]
        [String]$Name,
        [Parameter(
            HelpMessage='A list of email addresses'
        )]
        [String[]]$Email,
        [Parameter(
            HelpMessage="A list of nsone datafeed source ID's"
        )]
        [string[]]$SourceID
    )

    $List = foreach($addr in $Email){
        @{"type"="email";"config"= @{ "email"=$addr}}
    }
    $List += foreach($src in $SourceID){
        @{"type"="datafeed";"config"= @{ "sourceid"=$src}}
    }
    $BodyAsHash = @{
        "notify_list"=@($List)
    }

    $BodyAsHash.Add("name",$Name)

    $Body = $BodyAsHash | ConvertTo-Json -Depth 3

    Invoke-NS1APIRequest -URI "$BaseURI/lists/$ListID" -Method Post -Body $Body
}

Function Remove-NS1NotificationList {
    [cmdletbinding()]
    Param(
        [Parameter(
            Mandatory=$true
        )]
        [String]$ListID
    )

    Invoke-NS1APIRequest -URI "$BaseURI/lists/$ListID" -Method Delete
}

Function Get-NS1NotificationTypes {
    [cmdletbinding()]
    Param()

    Invoke-NS1APIRequest -URI "$BaseURI/notificationtypes" -Method Get

}

# Account Management
Function Get-NS1AccountSettings {
    [cmdletbinding()]
    Param()

    Invoke-NS1APIRequest -URI "$BaseURI/account/settings" -Method Get

}

Function Set-NS1AccountSettings {
    [cmdletbinding()]
    Param(
        [Parameter(
            Mandatory=$false
        )]
        [String]$email,
        [Parameter(
            Mandatory=$false
        )]
        [String]$secondary_email,
        [Parameter(
            Mandatory=$false
        )]
        [String]$country,
        [Parameter(
            Mandatory=$false
        )]
        [String]$Street,
        [Parameter(
            Mandatory=$false
        )]
        [String]$State,
        [Parameter(
            Mandatory=$false
        )]
        [String]$City,
        [Parameter(
            Mandatory=$false
        )]
        [String]$PostalCode,
        [Parameter(
            Mandatory=$false
        )]
        [String]$Phone,
        [Parameter(
            Mandatory=$false
        )]
        [String]$Company,
        [Parameter(
            Mandatory=$false
        )]
        [String]$LastName,
        [Parameter(
            Mandatory=$false
        )]
        [String]$FirstName
    )

    $BodyAsHash = @{}

    if($phone){$BodyAsHash.Add("phone",$phone)}
    if($Company){$BodyAsHash.Add("company",$Company)}
    if($LastName){$BodyAsHash.Add("lastname",$LastName)}
    if($FirstName){$BodyAsHash.Add("firstname",$FirstName)}
    if($email){$BodyAsHash.Add("email",$email)}
    if($secondary_email){$BodyAsHash.Add("secondary_email",$secondary_email)}

    if($country -or $Street -or $State -or $City -or $PostalCode){
        $Address = @{}
        if($country){$Address.Add("country",$country)}
        if($Street){$Address.Add("street",$Street)}
        if($State){$Address.Add("state",$State)}
        if($City){$Address.Add("city",$City)}
        if($PostalCode){$Address.Add("postalCode",$PostalCode)}
    }

    if($Address){$BodyAsHash.Add("address",$Address)}

    Invoke-NS1APIRequest -URI "$BaseURI/account/settings" -Method Post -Body $Body
}