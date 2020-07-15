# This PowerShell Script will create Module 3

# Import Functions
$wd = Get-Location
$len = $wd.ToString().Length
$modules = $wd.ToString().Substring(0,$len-10) + "\Utils\functions"
Import-Module -Name $modules 

# Create some names
# Substring some guids first
$guid1 = Get-GuidSS
$guid2 = Get-GuidSS

# Starting RG resource names
$RG1Name = "m3rg1" + $guid1
$appName = "m3aadapp" + $guid1
$UserVaultName = "m3userkv" + $guid1
$SA1Name = "m3sa" + $guid1
$Blob1Name = "m3function"
$functionApp = "m3fx" + $guid1
$function = "m3function"

# Ending RG resource names
$RG2Name = "m3rg2" + $guid2
$SA2Name = "m3sa" + $guid2
$Blob2Name = "m3resources"

$Location = "westus"
$SKU = "Standard_LRS"

# Connect to AzureAd and AzureCLI
Connect-AzureAD
Az login

# Create security group
$groupname = "m3_" + $guid1
New-AzADGroup -DisplayName $groupname -MailNickname "m3_group_nick"

# Create Azure App
$app = New-AzureADApplication -DisplayName $appName
$appPswd = New-AzureAdApplicationPasswordCredential -ObjectId $app.ObjectId

# Get the right subscriptions
$allSubs = Get-AzSubscription
$prompt1 = Read-Host -Prompt 'Input the name of the start subscription'
$prompt2 = Read-Host -Prompt 'Input the name of the end subscription'
$prompt3 = Read-Host -Prompt 'Input the user domain name'
$input1 = "*" + $prompt1 + "*"
$input2 = "*" + $prompt2 + "*"
$SubOne = $allSubs | Where-Object Name -CLike $input1
$SubTwo = $allSubs | Where-Object Name -CLike $input2

Get-AzSubscription -SubscriptionId $SubOne.Id -TenantId $SubOne.TenantId | Set-AzContext 

# ------In Sub One------ #
# Create Resoure Group
New-AzResourceGroup -Name $RG1Name -Location $Location

# Create User Key Vault, Storage Account, and Function App
New-AzKeyVault -Name $UserVaultName -ResourceGroupName $RG1Name -Location $Location
New-AzStorageAccount -ResourceGroupName $RG1Name -AccountName $SA1Name -Location $Location -SkuName $SKU
$Key1 = (Get-AzStorageAccountKey -ResourceGroupName $RG1Name -Name $SA1Name) | Where-Object {$_.KeyName -eq "key1"}
New-AzFunctionApp -Name $functionApp -ResourceGroupName $RG1Name -Location $Location -StorageAccountName $SA1Name -Runtime PowerShell

# Create function
func new -n $function -t "Timer trigger" -l PowerShell

# Modify function code
Copy-Item .\run.ps1 .\$function\
Set-Location .\$function\
$str = '$TenantId = ' + $SubTwo.TenantId
(Get-Content .\run.ps1).replace('$TenantId = ', $str) | Set-Content .\run.ps1
$str = '$AppObjectId = ' + $app.ObjectId
(Get-Content .\run.ps1).replace('$AppObjectId = ', $str) | Set-Content .\run.ps1
$str = '$Password = ' + $appPswd.Value
(Get-Content .\run.ps1).replace('$Password = ', $str) | Set-Content .\run.ps1
Set-Location ..

# Add function to the SA
$ctx = New-AzStorageContext -StorageAccountName $SA1Name -StorageAccountKey $Key1.Value
New-AzStorageContainer -Name $Blob1Name -Context $ctx -Permission Blob
Set-AzStorageBlobContent -File .\run.ps1 -Container $Blob1Name -Blob function -Context $ctx

#Switch Subscriptions
Get-AzSubscription -SubscriptionId $SubTwo.Id -TenantId $SubTwo.TenantId | Set-AzContext

# ------In Sub Two------ #
# Create Resource Group
New-AzResourceGroup -Name $RG2Name -Location $Location

# Create Storage Account
New-AzStorageAccount -ResourceGroupName $RG2Name -AccountName $SA2Name -Location $Location -SkuName $SKU
$Key1 = (Get-AzStorageAccountKey -ResourceGroupName $RG2Name -Name $SA2Name) | Where-Object {$_.KeyName -eq "key1"}

# Add the flag to the SA
$ctx = New-AzStorageContext -StorageAccountName $SA2Name -StorageAccountKey $Key1.Value
New-AzStorageContainer -Name $Blob2Name -Context $ctx -Permission Blob
Set-AzStorageBlobContent -File "..\Utils\flag.txt" -Container $Blob2Name -Blob flag -Context $ctx

# ------In Sub One------ #
Get-AzSubscription -SubscriptionId $SubOne.Id -TenantId $SubOne.TenantId | Set-AzContext 

# Create Users
if ($prompt3) {$prompt3 = '@' + $prompt3} else {$prompt3 = '@microsoft.onmicrosoft.com'}
..\Utils\create_users.ps1 $guid1 $prompt3 "m3"

# Deploy function to function app
func azure functionapp publish $functionApp --force
