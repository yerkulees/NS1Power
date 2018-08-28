Function New-DmarcReportDomain {
    [cmdletbinding()]
    Param(
        # Domain which receives aggregate or forensic reports
        [Parameter()]
        [String]
        $receivingDomain,
        # Domain which hosts dmarc record
        [Parameter()]
        [String]
        $dmarcDomain
    )

    $DomainObj = Get-NS1Zone -zone $receivingDomain

    if(($DomainObj.records | Where-Object -Property Domain -Like "${dmarcDomain}._report._dmarc.${receivingDomain}" | Select-Object -ExpandProperty short_answers) -ne "v=DMARC1"){
        New-NS1Record -zone $receivingDomain -Domain "${dmarcDomain}._report._dmarc.${receivingDomain}" -Type TXT -Answers "v=DMARC1"
    }
}

Function New-DmarcRecord {
    [cmdletbinding()]
    Param(
        # Zone which will host dmarc record
        [Parameter()]
        [String]
        $Zone,
        # Domain which will host dmarc record
        [Parameter()]
        [String]
        $Domain,
        # DKIM "Alignment Mode". Options are Relaxed or Strict
        [Parameter()]
        [ValidateSet("Strict","Relaxed")]
        [String]
        $DKIMMode,
        # SPF "Alignment Mode". Options are Relaxed or Strict
        [Parameter()]
        [ValidateSet("Strict","Relaxed")]
        [String]
        $SPFMode,
        # Policy for this domain. Mail which fails checks will follow this policy. Options are "None","Quarantine","Recject"
        [Parameter()]
        [ValidateSet("None","Quarantine","Reject")]
        [String]
        $Policy,
        # Percentage of mail to apply to policy. Useful for slow roll out.
        [Parameter()]
        [ValidateRange(0,100)]
        [Int]
        $Percentage,
        # Subdomain Policy. Mail from subdomains which fails checks will follow this policy. Options are "None","Quarantine","Recject"
        [Parameter()]
        [ValidateSet("None","Quarantine","Recject")]
        [String]
        $SubdomainPolicy,
        # Report URI's for aggregate reports. DMARC requires a list of URIs of the form "mailto:address@example.org".
        [Parameter()]
        [String[]]
        $AggregateReportURI,
        # Report URI's for forensic reports. DMARC requires a list of URIs of the form "mailto:address@example.org".
        [Parameter()]
        [String[]]
        $ForensicReportURI,
        # Forensic Reporting Policy.
        [Parameter()]
        [ValidateSet("All","Any","Dkim","Spf")]
        [String]
        $ForensicReportingOptions,
        # Report Format for forensic reporting
        [Parameter()]
        [ValidateSet("afrf","iodef")]
        [String]
        $ForensicReportFormat,
        # Reporting Interval in Seconds
        [Parameter()]
        [Int64]
        $ReportingInterval
    )

    $DmarcRecord = @()
    $DmarcRecord += "v=DMARC1"

    switch($DKIMMode){
        "Relaxed" {$DmarcRecord += "adkim=r"}
        "Strict" {$DmarcRecord += "adkim=s"}
    }
    switch($SPFMode){
        "Relaxed" {$DmarcRecord += "aspf=r"}
        "Strict" {$DmarcRecord += "aspf=s"}
    }

    if($Policy){$DmarcRecord += "p=$($Policy.ToLower())"}
    if($SubdomainPolicy){$DmarcRecord += "sp=$($SubdomainPolicy.ToLower())"}

    if($Percentage){$DmarcRecord += "pct=$Percentage"}

    if($AggregateReportURI){$DmarcRecord += "rua=$($AggregateReportURI -join ",")"}
    if($ForensicReportURI){$DmarcRecord += "ruf=$($ForensicReportURI -join ",")"}

    switch($SPFMode){
        "All" {$DmarcRecord += "fo=0"}
        "Any" {$DmarcRecord += "fo=1"}
        "DKIM" {$DmarcRecord += "fo=d"}
        "SPF" {$DmarcRecord += "fo=s"}
    }

    if($ForensicReportFormat){
        $DmarcRecord += "rf=$ForensicReportFormat"
    }

    if($ReportingInterval){
        $DmarcRecord += "ri=$ReportInterval"
    }
    
    write-Debug "$zone _dmarc.$Domain $($DmarcRecord -join ";")"

    New-NS1record -zone $zone -domain "_dmarc.$Domain" -Type TXT -Answers ($DmarcRecord -join ";")
}