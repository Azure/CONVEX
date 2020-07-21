# This PowerShell Script will create Module 3

param($SubOne, $SubTwo, $userNum, $domainname)

Write-Host "`n          =====Creating Module Three=====`n"

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
$VaultName = "m3kv" + $guid2
$SA2Name = "m3sa" + $guid2
$Blob2Name = "m3resources"

$Location = "westus"
$SKU = "Standard_LRS"

# Switch Subscriptions
Get-AzSubscription -SubscriptionId $SubOne.Id -TenantId $SubOne.TenantId | Set-AzContext

# Create security group
$groupname = "m3_" + $guid1
New-AzADGroup -DisplayName $groupname -MailNickname "m3_group_nick"

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

# Switch Subscriptions
Get-AzSubscription -SubscriptionId $SubTwo.Id -TenantId $SubTwo.TenantId | Set-AzContext

# ------In Sub Two------ #
# Create Resource Group
New-AzResourceGroup -Name $RG2Name -Location $Location

# Create Storage Account
New-AzStorageAccount -ResourceGroupName $RG2Name -AccountName $SA2Name -Location $Location -SkuName $SKU
$Key2 = (Get-AzStorageAccountKey -ResourceGroupName $RG2Name -Name $SA2Name) | Where-Object {$_.KeyName -eq "key1"}

# Add the flag to the SA
$ctx2 = New-AzStorageContext -StorageAccountName $SA2Name -StorageAccountKey $Key2.Value
New-AzStorageContainer -Name $Blob2Name -Context $ctx2 -Permission Blob
Set-AzStorageBlobContent -File "..\Utils\flag.txt" -Container $Blob2Name -Blob flag.txt -Context $ctx2

# Create KV
$theVault = New-AzKeyVault -Name $VaultName -ResourceGroupName $RG2Name -Location $Location

# Create Azure App
$appScope = '/subscriptions/' + $SubTwo.Id + '/resourceGroups/' + $RG2Name + '/providers/Microsoft.KeyVault/vaults/' + $VaultName
$app = New-AzADServicePrincipal -DisplayName $appName -Scope $appScope

# Set KV policy
Set-AzKeyVaultAccessPolicy -VaultName $theVault.VaultName -ObjectId $app.Id -PermissionsToKeys get,list -PermissionsToSecrets get,list

# Create dummy user and give them access to storage account
$displayname = "JohnDoe"
$upn = "johndoe@" + $domainname
$ptpw = [System.Web.Security.Membership]::GeneratePassword(12,2)
$sspw = ConvertTo-SecureString -String $ptpw -AsPlainText -Force
$duser = New-AzADUser -DisplayName $displayname -UserPrincipalName $upn -Password $sspw -MailNickname $displayname
$dscope = '/subscriptions/' + $SubTwo.Id + '/resourceGroups/' + $RG2Name + '/providers/Microsoft.Storage/storageAccounts/' + $SA2Name
New-AzRoleAssignment -ObjectId $duser.Id -RoleDefinitionName "Storage Blob Data Reader" -Scope $dscope

# Add user info to KV
Set-AzKeyVaultSecret -VaultName $VaultName -Name $displayname -SecretValue $sspw

# Switch Subscription
Get-AzSubscription -SubscriptionId $SubOne.Id -TenantId $SubOne.TenantId | Set-AzContext 

# Modify function code
Copy-Item .\run.ps1 .\$function\
Set-Location .\$function\
$str = '$TenantId = "' + $SubTwo.TenantId + '"'
(Get-Content .\run.ps1).replace('$TenantId = ', $str) | Set-Content .\run.ps1
$str = '$AppObjectId = "' + $app.ApplicationId + '"'
(Get-Content .\run.ps1).replace('$AppObjectId = ', $str) | Set-Content .\run.ps1
$secret = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($app.Secret)
$secret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($secret)
$str = '$Password = "' + $secret.ToString() + '"'
(Get-Content .\run.ps1).replace('$Password = ', $str) | Set-Content .\run.ps1
Set-Location ..

# Add function to the SA
$ctx1 = New-AzStorageContext -StorageAccountName $SA1Name -StorageAccountKey $Key1.Value
New-AzStorageContainer -Name $Blob1Name -Context $ctx1 -Permission Blob
Set-AzStorageBlobContent -File .\run.ps1 -Container $Blob1Name -Blob function -Context $ctx1

# Create Users
..\Utils\create_users.ps1 $guid1 $domainname "m3" $userNum

# Deploy function to function app
func azure functionapp publish $functionApp --force
