# This wrapper function will call on the necessary creation or teardown scripts

# Fail immediately if necessary
$ErrorActionPreference = 'stop'

# Make sure RM is not installed
if (Get-Module AzureRM) {
    Write-Error "AzureRM cannot be installed for CONVEX to run"
}

# Enable translation between AzureRM and Azure Az
Enable-AzureRmAlias -Scope CurrentUser

# Import Functions
$wd = Get-Location
$modules = $wd.ToString() + "\Utils\functions"
Import-Module -Name $modules 

# Connect to Azure Module
try {
    Disconnect-AzAccount
    Connect-AzAccount
} catch {Write-Error "Azure Powershell module must be installed and authenticated"}

# Connect to AzureAD
try {
    Connect-AzureAD
} catch {Write-Error "AzureAD PowerShell module must be installed and authenticated"}

# Connect to AzureCLI
try {
    $login = az login | ConvertFrom-Json
} catch {Write-Error "Azure CLI must be installed and authenticated"}


# Print out available subs
$login.Name
Write-Host ""

# Get the start and end subscriptions
try 
{
    $allSubs = Get-AzSubscription
    $prompt1 = Read-Host -Prompt 'Input the name of the start subscription'
    $prompt2 = Read-Host -Prompt 'Input the name of the end subscription'
    $input1 = "*" + $prompt1 + "*"
    $input2 = "*" + $prompt2 + "*"
    $SubOne = $allSubs | Where-Object Name -CLike $input1
    $SubTwo = $allSubs | Where-Object Name -CLike $input2
} catch 
{
    Write-Host "Error getting subscriptions from Az PowerShell Identity" -ForegroundColor Yellow
}

# Decide if we are creating or deleting modules
$cOrT = "create","teardown"
do {
    $prompt3 = Read-Host -Prompt 'Do you want to create or teardown modules?'
    $input3 = $input3 + "*"
    $decision = $cOrT -match $prompt3
    if ((($decision -ne "create") -and ($decision -ne "teardown")) -or !$decision) {
        Write-Host "That wasn't a valid input, try again `n"
    } else {
        break
    }
} while ((($decision -ne "create") -and ($decision -ne "teardown")) -or !$decision)

# If creating, ask for the number of users
if ($decision -eq "create") {
    do 
    {
        try
        {
            [ValidateRange(1, [int]::MaxValue)] $users = Read-Host -Prompt "How many users would you like?"
        } catch {}
    } until ($?)
    $domainname = Read-Host -Prompt "What domain name will the user account(s) use?"
}

# Either create or teardown each module
$dirs = Get-ChildItem . -Directory | Where-Object Name -CLike Module*
foreach ($mod in $dirs.Name) {

    # Create or delete
    if ($decision -eq "create") {
        Set-Location .\$mod
        .\create.ps1 $SubOne $SubTwo $users $domainname
        Set-Location ..
    } else {
        Set-Location .\$mod
        .\teardown $SubOne $SubTwo
        Set-Location ..
    }
}

