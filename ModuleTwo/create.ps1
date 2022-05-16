# This PowerShell Script will create Module 2

param($SubOne, $SubTwo, $userNum, $domainname)

Write-Host "`n          =====Creating Module Two=====`n"

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

Get-AzSubscription -SubscriptionId $SubOne.Id -TenantId $SubOne.TenantId | Set-AzContext 

# Create security group
Write-Host "Creating security group"
$groupname = "m2_" + $guid1
$group = New-AzADGroup -DisplayName $groupname -MailNickname "m2_group_nick"
Write-Host "Security group created"

# ------In Sub One------ #
# Create Resoure Group
New-AzResourceGroup -Name $RG1Name -Location $Location

# Create User Key Vault and App Service
Write-Host "Creating $UserVaultName Storage Account"
New-AzKeyVault -Name $UserVaultName -ResourceGroupName $RG1Name -Location $Location
Write-Host "$UserVaultName Storage Account created"
Write-Host "Creating $RG1Name Web App"
New-AzWebApp -ResourceGroupName $RG1Name -Name $webServiceName -Location $Location
Write-Host "$RG1Name Web App created"

# Assign Group Access
New-AzRoleAssignment -ObjectId $group.Id -RoleDefinitionName Contributor -ResourceName $webServiceName -ResourceType Microsoft.Web/sites -ResourceGroupName $RG1Name

#Switch Subscriptions
Get-AzSubscription -SubscriptionId $SubTwo.Id -TenantId $SubTwo.TenantId | Set-AzContext

# ------In Sub Two------ #
# Create Resource Group
New-AzResourceGroup -Name $RG2Name -Location $Location

# Create Key Vault and Storage Account
Write-Host "Creating Key Vault"
$theVault = New-AzKeyVault -Name $VaultName -ResourceGroupName $RG2Name -Location $Location
Write-Host "Key Vault created"
Write-Host "Creating $RG2Name Storage Account"
New-AzStorageAccount -ResourceGroupName $RG2Name -AccountName $SA2Name -Location $Location -SkuName $SKU
Write-Host "$RG2Name Storage Account created"
$Key1 = (Get-AzStorageAccountKey -ResourceGroupName $RG2Name -Name $SA2Name) | Where-Object {$_.KeyName -eq "key1"}

# Create the Service Principles
Write-Host "Creating Service Principals"
$sp1Name = "m2webapp"
$sp1Scope = '/subscriptions/' + $SubTwo.Id + '/resourceGroups/' + $RG2Name + '/providers/Microsoft.KeyVault/vaults/' + $VaultName
$sp1 = New-AzADServicePrincipal -DisplayName $sp1Name -Role Reader -Scope $sp1Scope
$sp2Name = "m2webapp-admin"
$sp2Scope = '/subscriptions/' + $SubTwo.Id + '/resourceGroups/' + $RG2Name
$sp2 = New-AzADServicePrincipal -DisplayName $sp2Name -Scope $sp2Scope
New-AzRoleAssignment -ObjectId $sp2.Id -RoleDefinitionName "Reader" -Scope $sp2Scope
$sa2Scope = $sp2Scope + '/providers/Microsoft.Storage/storageAccounts/' + $SA2Name
New-AzRoleAssignment -ObjectId $sp2.Id -RoleDefinitionName "Classic Storage Account Key Operator Service Role" -Scope $sa2Scope
Write-Host "Service Principals created"

# Add the flag to the SA
$ctx = New-AzStorageContext -StorageAccountName $SA2Name -StorageAccountKey $Key1.Value
New-AzStorageContainer -Name $BlobName -Context $ctx -Permission Blob
Set-AzStorageBlobContent -File "..\Utils\flag.txt" -Container $BlobName -Blob flag.txt -Context $ctx

# Add in the appKey to the prived app
$currentUser = az ad signed-in-user show --query objectId -o tsv
Set-AzKeyVaultAccessPolicy -VaultName $theVault.VaultName -ObjectId $currentUser -PermissionsToKeys all -PermissionsToSecrets all
$sp2AppId = $sp2.AppId.ToString()
$ssid = ConvertTo-SecureString -String $sp2AppId -AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $theVault.VaultName -Name "appId" -SecretValue $ssid
$sspw = ConvertTo-SecureString -String $sp2.PasswordCredentials.SecretText -AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $theVault.VaultName -Name "appKey" -SecretValue $sspw

# Set Key Vault permissions
Set-AzKeyVaultAccessPolicy -VaultName $theVault.VaultName -ObjectId $sp1.Id -PermissionsToKeys get,list -PermissionsToSecrets get,list
Remove-AzKeyVaultAccessPolicy -VaultName $theVault.VaultName -ObjectId $currentUser

# ------In Sub One------ #
Get-AzSubscription -SubscriptionId $SubOne.Id -TenantId $SubOne.TenantId | Set-AzContext 

# Update App Settings to include App1 id and key
Write-Host "Updating Web App Application settings"
$webapp = Get-AzWebApp -ResourceGroupName $RG1Name -Name $webServiceName
$appSettings = $webApp.SiteConfig.AppSettings
$settings = @{}
foreach ($kvp in $appSettings) {
    $settings[$kvp.Name] = $kvp.Value
}
$spAppId = $sp1.AppId.ToString()
$settings['application_id'] = $spAppId
$settings['application_key'] = $sp1.PasswordCredentials.SecretText
Set-AzWebApp -ResourceGroupName $RG1Name -Name $webServiceName -AppSettings $settings
Write-Host "Web App Application settings updated"

# Create Users
..\Utils\create_users.ps1 $guid1 $domainname "m2" $userNum
