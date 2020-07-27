# This PowerShell script will teardown Module One
# Both a Storage Account and Key Vault will be deleted if their resource group
# is deleted.

param($SubOne, $SubTwo)
$ErrorActionPreference = 'silentycontinue'
Write-Host "`n          =====Tearing Down Module One=====`n"

Get-AzSubscription –SubscriptionId $SubOne.Id -TenantId $SubOne.TenantId | Set-AzContext 

# Delete created users and group
..\Utils\delete_users.ps1 "m1"

# ------Sub One------ #

# Get the right resource group
$allRGs1 = Get-AzResourceGroup
$RG1 = $allRGs1 | Where-Object ResourceGroupName -CLike "m1*"
Remove-AzResourceGroup -Name $RG1.ResourceGroupName -Force

# ------Sub Two------ #
Get-AzSubscription –SubscriptionId $SubTwo.Id -TenantId $SubTwo.TenantId | Set-AzContext

# Get the right resource group
$allRGs2 = Get-AzResourceGroup
$RG2 = $allRGs2 | Where-Object ResourceGroupName -CLike "m1*"
Remove-AzResourceGroup -Name $RG2.ResourceGroupName -Force
