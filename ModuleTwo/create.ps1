# This PowerShell Script will create Module 2

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
$RG1Name = "m2rg1" + $guid1
$UserVaultName = "m2userkv" + $guid1
$webServiceName = "m2ws" + $guid1

# Ending RG resource names
$RG2Name = "m2rg2" + $guid2
$VaultName = "m2kv" + $guid2
$SA2Name = "m2sa" + $guid2
$BlobName = "m2resources"

$Location = "westus"
$SKU = "Standard_LRS"

# Connect to AzureAd
Connect-AzureAD

# Get the right subscriptions
$allSubs = Get-AzSubscription
$prompt1 = Read-Host -Prompt 'Input the name of the first subscription'
$prompt2 = Read-Host -Prompt 'Input the name of the second subscription'
$prompt3 = Read-Host -Prompt 'Input the user domain name'
$input1 = "*" + $prompt1 + "*"
$input2 = "*" + $prompt2 + "*"
$SubOne = $allSubs | Where-Object Name -CLike $input1
$SubTwo = $allSubs | Where-Object Name -CLike $input2

Get-AzSubscription -SubscriptionId $SubOne.Id -TenantId $SubOne.TenantId | Set-AzContext 

# Create security group
$groupname = "m2_" + $guid1
$group = New-AzADGroup -DisplayName $groupname -MailNickname "m2_group_nick"

# ------In Sub One------ #
# Create Resoure Group
New-AzResourceGroup -Name $RG1Name -Location $Location

# Create User Key Vault and App Service
New-AzKeyVault -Name $UserVaultName -ResourceGroupName $RG1Name -Location $Location
New-AzWebApp -ResourceGroupName $RG1Name -Name $webServiceName -Location $Location

# Assign Group Access
New-AzRoleAssignment -ObjectId $group.Id -RoleDefinitionName Contributor -ResourceName $webServiceName -ResourceType Microsoft.Web/sites -ResourceGroupName $RG1Name

#Switch Subscriptions
Get-AzSubscription -SubscriptionId $SubTwo.Id -TenantId $SubTwo.TenantId | Set-AzContext

# ------In Sub Two------ #
# Create Resource Group
New-AzResourceGroup -Name $RG2Name -Location $Location

# Create Key Vault and Storage Account
$theVault = New-AzKeyVault -Name $VaultName -ResourceGroupName $RG2Name -Location $Location
New-AzStorageAccount -ResourceGroupName $RG2Name -AccountName $SA2Name -Location $Location -SkuName $SKU
$Key1 = (Get-AzStorageAccountKey -ResourceGroupName $RG2Name -Name $SA2Name) | Where-Object {$_.KeyName -eq "key1"}

# Create the Service Principles
$sp1Name = "m2participant"
$sp1Scope = '/subscriptions/' + $SubTwo.Id + '/resourceGroups/' + $RG2Name + '/providers/Microsoft.KeyVault/vaults/' + $VaultName
$sp1 = New-AzADServicePrincipal -DisplayName $sp1Name -Role Reader -Scope $sp1Scope
$sp2Name = "m2admin"
$sp2Scope = '/subscriptions/' + $SubTwo.Id + '/resourceGroups/' + $RG2Name
$sp2 = New-AzADServicePrincipal -DisplayName $sp2Name -Scope $sp2Scope

# Add the flag to the SA
$ctx = New-AzStorageContext -StorageAccountName $SA2Name -StorageAccountKey $Key1.Value
New-AzStorageContainer -Name $BlobName -Context $ctx -Permission Blob
Set-AzStorageBlobContent -File "..\Utils\flag.txt" -Container $BlobName -Blob flag -Context $ctx

# Add in the appKey to the prived app
Set-AzKeyVaultSecret -VaultName $theVault.VaultName -Name "appKey" -SecretValue $sp2.Secret

# Set Key Vault permissions
Set-AzKeyVaultAccessPolicy -VaultName $theVault.VaultName -ObjectId $sp1.Id -PermissionsToKeys get,list -PermissionsToSecrets get,list

# ------In Sub One------ #
Get-AzSubscription -SubscriptionId $SubOne.Id -TenantId $SubOne.TenantId | Set-AzContext 

# Update App Settings to include App1 id and key
$webapp = Get-AzWebApp -ResourceGroupName $RG1Name -Name $webServiceName
$appSettings = $webApp.SiteConfig.AppSettings
$settings = @{}
foreach ($kvp in $appSettings) {
    $settings[$kvp.Name] = $kvp.Value
}
$spAppId = $sp1.ApplicationId.ToString()
$settings['application_id'] = $spAppId
$secret = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($sp1.Secret)
$secret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($secret)
$settings['application_key'] = $secret.ToString()
Set-AzWebApp -ResourceGroupName $RG1Name -Name $webServiceName -AppSettings $settings

# Create Users
..\Utils\create_users.ps1 $guid1 $prompt3 "m2"