# Getting started
1. Import the Module 

2. Set the API key
```
Import-Module NS1Power
Set-NS1KeyFile
```

The Set-NS1KeyFile advanced function accepts cmdline info or a secure string object and writes the encrypted output to $KeyPath. From that point on Invoke-APIRequest will read from that file and decrypt the data each time a function is called.

# Rate Limiting
NS1 Takes adavantage of rate limiting API requests so we're using Invoke-WebRequest instead of Invoke-RestMethod to better utilize the header information. All Rate Limiting logic should happen within the Invoke-APIRequest function. All other functions should send API requests through that function. 

https://ns1.com/knowledgebase/api-rate-limiting

# Responses
Response should be:
Hashtables using (ConvertFrom-Json)

Unfortunately the request and response keys don't always match up so its not easy to pipe info to the next command. Some commands have aliases which  others do not.

# API Key
The API key is protected using the secure string method used by powershell to encrypt all credentials.

# Key Context
You can now use multiple API keys and switch between them using Set-NS1KeyContext.
```
PS #> Set-NS1KeyFile -Name "MyAwesomeKey.txt" -SetContext
PS #> Get-NS1Zone
*Results*
PS #> Set-NS1KeyContext
PS #> Get-NS1Zone
*Results*
PS #> Set-NS1KeyContext -Name "MyAwesomeKey.txt"
```
The first advanced function creates a key and sets the context so that all commands following use the newly created key. The first Get-NS1Zone uses "MyAwesomeKey.txt". The first Set-NS1KeyContext sets the context back to the default "SecureString.txt" so the second Get-NS1Zone uses that default key. Then Set-NS1KeyContext sets the key back to "MyAwesomeKey.txt".

You can check your current key context using Get-NS1KeyContext. 
```
PS #> Set-NS1KeyContext
PS #> Get-NS1KeyContext
C:\Users\UserName\Documents\Powershell\NS1Power\Local\SecureString.txt
PS #> Set-NS1KeyContext -Name "MySecondAwesomeKey.txt"
PS #> Get-NS1KeyContext
C:\Users\UserName\Documents\Powershell\NS1Power\Local\MyAwesomeContext.txt
```
This advanced function inelegantly returns the full file path of the key file.
