# This PowerShell Script will create Module 1

# Import Functions
$wd = Get-Location
$len = $wd.ToString().Length
$modules = $wd.ToString().Substring(0,$len-10) + "\Utils\functions"
Import-Module -Name $modules 

# Name some names
$guid1 = Get-GuidSS 
$RG1Name = "m1rg1" + $guid1
$guid2 = Get-GuidSS
$RG2Name = "m1rg2" + $guid2
$VaultName = "m1kv" + $guid2
$UserVaultName = "m1userkv" + $guid2
$SAName = "m1sa" + $guid1
$Location = "westus"
$SKU = "Standard_LRS"
$KeyName = "SAKey1"
$BlobName = "m1blob"
$FileName = "m1Flag"

# Create a group 
$groupname = "m1_" + $guid1
$group = New-AzADGroup -DisplayName $groupname -MailNickname "m1_group_nick"

# Get the right subscriptions
$allSubs = Get-AzSubscription
$prompt1 = Read-Host -Prompt 'Input the name of the first subscription.'
$prompt2 = Read-Host -Prompt 'Input the name of the second subscription.'
$input1 = "*" + $prompt1 + "*"
$input2 = "*" + $prompt2 + "*"
$SubOne = $allSubs | Where-Object Name -CLike $input1
$SubTwo = $allSubs | Where-Object Name -CLike $input2

Get-AzSubscription –SubscriptionId $SubOne.Id -TenantId $SubOne.TenantId | Set-AzContext 

# ------In Sub One------ #
# Create Resoure Group
New-AzResourceGroup -Name $RG1Name -Location $Location

# Create the Storage Account and store the key
New-AzStorageAccount -ResourceGroupName $RG1Name -AccountName $SAName -Location $Location -SkuName $SKU
$Key1 = (Get-AzStorageAccountKey -ResourceGroupName $RG1Name -Name $SAName) | Where-Object {$_.KeyName -eq "key1"}
$SecretKey1 = ConvertTo-SecureString -String $Key1.Value -AsPlainText -Force

# Add the flag to the Storage Account
$ctx = New-AzStorageContext -StorageAccountName $SAName -StorageAccountKey $Key1.Value
New-AzStorageContainer -Name $BlobName -Context $ctx -Permission Blob
Set-AzStorageBlobContent -File "..\Utils\flag.txt" -Container $BlobName -Blob $FileName -Context $ctx

#Switch Subscriptions
Get-AzSubscription –SubscriptionId $SubTwo.Id -TenantId $SubTwo.TenantId | Set-AzContext
 
# ------In Sub Two------ #
# Create Resource Group and give Group access
New-AzResourceGroup -Name $RG2Name -Location $Location

# Create Key Vaults
$theVault = New-AzKeyVault -Name $VaultName -ResourceGroupName $RG2Name -Location $Location
New-AzKeyVault -Name $UserVaultName -ResourceGroupName $RG2Name -Location $Location
Set-AzKeyVaultAccessPolicy -VaultName $theVault.VaultName -ObjectId $group.Id -PermissionsToKeys get,list -PermissionsToSecrets get,list
New-AzRoleAssignment -ObjectId $group.Id -RoleDefinitionName Reader -ResourceName $theVault.VaultName -ResourceType Microsoft.KeyVault/vaults -ResourceGroupName $RG2Name

# Fill the Vaults with secrets
Set-AzKeyVaultSecret -VaultName $VaultName -Name $KeyName -SecretValue $SecretKey1

# Create the Users
..\Utils\create_users.ps1 $guid1 "@suzyicode4food.onmicrosoft.com" "m1"
