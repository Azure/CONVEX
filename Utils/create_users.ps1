# This PowerShell script will create a specified amount of users
param ($guid, $domainname, $module, $n)
Write-Host "Creating $module users"
Add-Type -AssemblyName System.Web

$displayname
$upn

# Get the group and kv that the users will be added to 
$groups = Get-AzAdGroup
$search = "*" + $guid + "*"
$toAdd = $groups | Where-Object DisplayName -Clike $search
$userkvname = $module + "userkv*"
$UserKV = Get-AzResource | Where-Object Name -CLike $userkvname

# Create the users
for ($cur = 1; $cur -le $n; $cur++) {
    
    # Create all the things
    $displayname = $module + "user" + $cur
    $upn = $displayname + "@" + $domainname
    $ptpw = [System.Web.Security.Membership]::GeneratePassword(12,2)
    $sspw = ConvertTo-SecureString -String $ptpw -AsPlainText -Force

    # Create the user
    $thisuser = New-AzADUser -DisplayName $displayname -UserPrincipalName $upn -Password $sspw -MailNickname $displayname
    Add-AzADGroupMember -MemberObjectId $thisuser.Id -TargetGroupObjectId $toAdd.Id

    # Store username and password in keyvault 
    Set-AzKeyVaultSecret -VaultName $UserKV.Name -Name $displayname -SecretValue $sspw
}
