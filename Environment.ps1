# Set Environment
# Left $KeyPath for backward compatibility. Is this necessary? No
# $KeyPath = "$HOME\.NS1Power\SecureString.txt"
if($KeyPath){
    $KeyDirectory = Split-Path $KeyPath
    $DefaultKeyName = Split-Path $KeyPath -Leaf
}else{
    $KeyDirectory = "$PSScriptRoot\Local"
    $DefaultKeyName = "SecureString.txt"
}

# Variable used by Get-APIKey for accessing API information
$CurrentContextKey = "$KeyDirectory\$DefaultKeyName"

# Performance Tuning
# Pause if Rate Limits Remaining is less than or equal to this number
$SoftRateLimit = 10

# Sleep Time in Seconds, wait for request RateLimit to replenish.
$SleepTime = 5