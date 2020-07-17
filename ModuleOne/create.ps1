# This PowerShell Script will create Module 1

param($SubTwo, $SubOne, $userNum, $domainname)

Write-Host "`n          =====Creating Module One=====`n"

# Name some names
# Get Guids
$guid1 = Get-GuidSS 
$guid2 = Get-GuidSS

# RG One
$RG1Name = "m1rg1" + $guid1
$SAName = "m1sa" + $guid1
$KeyName = "SAKey1"
$BlobName = "m1blob"
$FileName = "m1Flag.txt"

# RG Two
$RG2Name = "m1rg2" + $guid2
$VaultName = "m1kv" + $guid2
$UserVaultName = "m1userkv" + $guid2

$Location = "westus"
$SKU = "Standard_LRS"

Get-AzSubscription –SubscriptionId $SubOne.Id -TenantId $SubOne.TenantId | Set-AzContext 

# Create a group 
Write-Host "Creating security group"
$groupname = "m1_" + $guid1
$group = New-AzADGroup -DisplayName $groupname -MailNickname "m1_group_nick"
Write-Host "Security group created"

# ------In Sub Two------ #
# Create Resoure Group
New-AzResourceGroup -Name $RG1Name -Location $Location

# Create the Storage Account and store the key
Write-Host "Creating $RG1Name Storage Account"
New-AzStorageAccount -ResourceGroupName $RG1Name -AccountName $SAName -Location $Location -SkuName $SKU
Write-Host "$RG1Name Storage Account created"
$Key1 = (Get-AzStorageAccountKey -ResourceGroupName $RG1Name -Name $SAName) | Where-Object {$_.KeyName -eq "key1"}
$SecretKey1 = ConvertTo-SecureString -String $Key1.Value -AsPlainText -Force

# Add the flag to the Storage Account
$ctx = New-AzStorageContext -StorageAccountName $SAName -StorageAccountKey $Key1.Value
Write-Host "Adding flag to $SAName"
New-AzStorageContainer -Name $BlobName -Context $ctx -Permission Blob
Set-AzStorageBlobContent -File "..\Utils\flag.txt" -Container $BlobName -Blob $FileName -Context $ctx
Write-Host "Flag added to $SAName"
$scope = '/subscriptions/' + $SubOne.Id + '/resourceGroups/' + $RG1Name + '/providers/Microsoft.Storage/storageAccounts/' + $SAName
New-AzRoleAssignment -ObjectId $group.Id -RoleDefinitionName Reader -Scope $scope

#Switch Subscriptions
Get-AzSubscription –SubscriptionId $SubTwo.Id -TenantId $SubTwo.TenantId | Set-AzContext
 
# ------In Sub Two------ #
# Create Resource Group and give Group access
New-AzResourceGroup -Name $RG2Name -Location $Location

# Create Key Vaults
Write-Host "Creating starting Key Vault"
$theVault = New-AzKeyVault -Name $VaultName -ResourceGroupName $RG2Name -Location $Location
Write-Host "Sstarting Key Vault created"
Write-Host "Creating User Key Vault"
New-AzKeyVault -Name $UserVaultName -ResourceGroupName $RG2Name -Location $Location
Write-Host "User Key Vault created"
Set-AzKeyVaultAccessPolicy -VaultName $theVault.VaultName -ObjectId $group.Id -PermissionsToKeys get,list -PermissionsToSecrets get,list
New-AzRoleAssignment -ObjectId $group.Id -RoleDefinitionName Reader -ResourceName $theVault.VaultName -ResourceType Microsoft.KeyVault/vaults -ResourceGroupName $RG2Name

# Fill the Vaults with secrets
Write-Host "Adding secrets to starting Key Vault"
Set-AzKeyVaultSecret -VaultName $VaultName -Name $KeyName -SecretValue $SecretKey1

# Create the Users
..\Utils\create_users.ps1 $guid1 $domainname "m1" $userNum


Write-Host "`n          =====Module One Created=====`n"
