# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

Write-Host "Entering function ProcessData. TIME: $currentUTCtime"

# The 'IsPastDue' porperty is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "Timer is running late!"
}

Write-Host "Processing request..."

$Resource = "https://vault.azure.net"
$TenantId = 
$AppId = 
$Password = 

$body = @{Resource = $Resource; client_id = $AppId; grant_type = "client_credentials"; client_secret = $Password} 

$url = "https://login.microsoftonline.com/$TenantId/oauth2/token" 

$result = Invoke-WebRequest -Uri $url -Method Post -Body $body  

Write-Host "Authenticating..."

$token = (ConvertFrom-Json $result.Content).access_token 

Write-Host "Authentication complete $token"

Write-Host "Processing complete."

# Write an information log with the current time.
Write-Host "Exiting function ProcessData. TIME: $currentUTCtime"
