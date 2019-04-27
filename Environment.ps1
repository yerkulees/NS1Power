# Set Environment
# Sets the location for encrypted key files
$KeyDirectory = "$PSScriptRoot\Local"
$DefaultKeyName = "SecureString.txt"

# Variable used by Get-APIKey for accessing API information
$CurrentContextKey = "$KeyDirectory\$DefaultKeyName"

# Performance Tuning
# Pause if Rate Limits Remaining is less than or equal to this number
$SoftRateLimit = 10

# Sleep Time in Seconds, wait for request RateLimit to replenish.
$SleepTime = 5