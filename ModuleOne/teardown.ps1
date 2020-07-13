# This PowerShell script will teardown Module One
# Both a Storage Account and Key Vault will be deleted if their resource group
# is deleted.

#Get the right subs
$allSubs = Get-AzSubscription
$prompt1 = Read-Host -Prompt 'Input the name of the first subscription.'
$prompt2 = Read-Host -Prompt 'Input the name of the second subscription.'
$input1 = "*" + $prompt1 + "*"
$input2 = "*" + $prompt2 + "*"
$SubOne = $allSubs | Where-Object Name -CLike $input1
$SubTwo = $allSubs | Where-Object Name -CLike $input2

# Delete created users and group
.\delete_users.ps1

# ------Sub One------ #
Get-AzSubscription –SubscriptionId $SubOne.Id -TenantId $SubOne.TenantId | Set-AzContext 

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
