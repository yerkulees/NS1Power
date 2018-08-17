# Getting started
Firstly you must load the module so that Environment.ps1 runs and creates some important
variables. 
Import-Module NS1Power

Once the module is loaded, you need to set the API key using:
Set-NS1KeyFile

This advanced function accepts cmdline info or a secure string object and writes the 
encrypted output to $KeyPath. From that point on Invoke-NS1APIRequest will read from 
that file and decrypt the data each time a function is called.

Then you are ready to go.

# Rate Limiting
NS1 Takes adavantage of rate limiting API requests so we're using Invoke-WebRequest instead of
Invoke-RestMethod to better utilize the header information. All Rate Limiting logic 
should happen within the Invoke-NS1APIRequest function. All other functions should
send API requests through that function

https://ns1.com/knowledgebase/api-rate-limiting

# Responses
Response should be:
String
Hash (ConvertFrom-Json)

Microsoft.PowerShell.Commands.HtmlWebResponseObject

# API Key
The API key is protected using the secure string method used by powershell to 
encrypt all credentials. 