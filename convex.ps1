# This wrapper function will call on the necessary creation or teardown scripts

# Fail immediately if necessary
$ErrorActionPreference = 'stop'

# Make sure RM is not installed
if (Get-Module -name AzureRM -list) {Write-Error "AzureRM cannot be installed for CONVEX to run. Please uninstall AzureRM and install the new Azure Module, AzureAD, Azure CLI, and Azure Function Core Tools."}

# Make sure the three required modules are installed
if (-Not (Get-Module -name Azure -list)) {Write-Error "Azure Module needs be installed for CONVEX to run. Please uninstall AzureRM and install the new Azure Module, AzureAD, Azure CLI, and Azure Function Core Tools."}
if (-Not (Get-Module -name AzureAD -list)) {Write-Error "AzureAD Module needs be installed for CONVEX to run. Please uninstall AzureRM and install the new Azure Module, AzureAD, Azure CLI, and Azure Function Core Tools."}
if (-Not (az --version)) {Write-Error "AzureCLI needs be installed for CONVEX to run. Please uninstall AzureRM and install the new Azure Module, AzureAD, Azure CLI, and Azure Function Core Tools."}
if (-Not (func --version)) {Write-Error "Azure Function Core Tools needs to be installed for CONVEX to run. Please uninstall AzureRM and install the new Azure Module, AzureAD, Azure CLI, and Azure Function Core Tools."}

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
} catch {Write-Error "Azure Powershell module must be installed and authenticated."}

# Connect to AzureAD
try {
    Connect-AzureAD
} catch {Write-Error "AzureAD PowerShell module must be installed and authenticated."}

# Connect to AzureCLI
try {
    az logout
   $login = az login --only-show-errors| ConvertFrom-Json
} catch {Write-Error "Azure CLI must be installed and authenticated."}


# Print out available subs
$login | Select-Object Name, id
$subIds = New-Object System.Collections.Generic.List[System.Object]
foreach ($id in $login.id) {$subIds.Add($id)}
Write-Host ""

# Try getting all of the subs
try {$allSubs = Get-AzSubscription -ErrorAction 'stop'} 
catch{Write-Host "Error getting subscriptions from Az PowerShell Identity" -ForegroundColor Yellow}

# Get the first sub id and store the value
do {
    $prompt1 = Read-Host -Prompt 'Input the Id of the start subscription'
    $input1 = "*" + $prompt1 + "*"
    $SubOne = $allSubs | Where-Object id -CLike $input1
    $s1 = $subIds.Contains($SubOne.Id)
    if (-Not $s1) {Write-Host "Not a valid subscription"}
} until ($s1)

# Remove sub one to avoid repeats
$null = $subIds.Remove($SubOne.Id)

# Get the second sub and store the value
do {
    $prompt2 = Read-Host -Prompt 'Input the id of the end subscription'
    $input2 = "*" + $prompt2 + "*"
    $SubTwo = $allSubs | Where-Object id -CLike $input2
    $s2 = $subIds.Contains($SubTwo.Id)
    if ($SubTwo.Id -eq $SubOne.Id) {Write-Host "That subscription is already being used"}
    elseif (-Not $s2) {Write-Host "Not a valid subscription"}
} until ($s2)

# Decide if we are creating or deleting modules
$cOrT =@()
$cOrT += "create"
$cOrT += "teardown"
do {
    $decision = Read-Host -Prompt 'Do you want to create or teardown modules?'
    $d1 = $cOrT.Contains($decision)
    if (-Not $d1) {Write-Host "Not a valid input"}
} until ($d1)

# If creating, ask for the number of users
if ($decision -eq "create") {
    do 
    {
        try
        {
            [ValidateRange(1, [int]::MaxValue)] $users = Read-Host -Prompt "How many users would you like?"
        } catch {}
    } until ($?)
    do 
    {
        try {
            $domainname = Read-Host -Prompt "What domain name will the user account(s) use?"
            $check = Get-AzureADDomain -Name $domainname -ErrorAction 'stop'            
        } catch {}
    } until ($check)
}

# Either create or teardown each module
$dirs = Get-ChildItem . -Directory | Where-Object Name -CLike Module*
foreach ($mod in $dirs.Name) {

    # Create or delete
    Set-Location .\$mod
    if ($decision -eq "create") {
        .\create.ps1 $SubOne $SubTwo $users $domainname
    } else {
        .\teardown $SubOne $SubTwo
    }
    Set-Location ..
}
