# Getting started
1. Import the Module 
Import-Module NS1Power

2. Set the API key
Set-NS1KeyFile

This advanced function accepts cmdline info or a secure string object and writes the encrypted output to $KeyPath. From that point on Invoke-NS1APIRequest will read from that file and decrypt the data each time a function is called.

# Rate Limiting
NS1 Takes adavantage of rate limiting API requests so we're using Invoke-WebRequest instead of Invoke-RestMethod to better utilize the header information. All Rate Limiting logic should happen within the Invoke-NS1APIRequest function. All other functions should send API requests through that function. 

https://ns1.com/knowledgebase/api-rate-limiting

# Responses
Response should be:
Hashtables using (ConvertFrom-Json)

Unfortunately the request and response keys don't always match up so its not easy to pipe info to the next command. Some commands have aliases which  others do not.

# API Key
The API key is protected using the secure string method used by powershell to encrypt all credentials.