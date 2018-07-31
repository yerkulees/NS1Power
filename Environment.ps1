# Set-Environment
# $KeyPath = "$HOME\.NS1Power\SecureString.txt"
$KeyPath = "$PSScriptRoot\Local\SecureString.txt"


# Performance Tuning
# Pause if Rate Limits Remaining is less than or equal to this number
$SoftRateLimit = 10

# Sleep Time in Seconds, wait for request RateLimit to replenish.
$SleepTime = 5