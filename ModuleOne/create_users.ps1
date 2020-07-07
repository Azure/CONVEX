# This PowerShell script will create a specified amount of users
param ($guid)
Add-Type -AssemblyName System.Web

$displayname
$domainname = "@suzyicode4food.onmicrosoft.com"
$upn

# Ask user how many users to create
[int] $n = Read-Host -Prompt "Input the number of users you would like"

# Get the group and kv that the users will be added to 
$groups = Get-AzAdGroup
$search = "*" + $guid + "*"
$toAdd = $groups | Where-Object DisplayName -Clike $search
$UserKV = Get-AzResource | Where-Object Name -CLike "*userkv*"

# Create the users
for ($cur = 1; $cur -le $n; $cur++) {
    
    # Create all the things
    $displayname = "User" + $cur
    $upn = $displayname + $domainname
    $ptpw = [System.Web.Security.Membership]::GeneratePassword(12,2)
    $sspw = ConvertTo-SecureString -String $ptpw -AsPlainText -Force

    # Create the user
    $thisuser = New-AzADUser -DisplayName $displayname -UserPrincipalName $upn -Password $sspw -MailNickname $displayname
    Add-AzADGroupMember -MemberObjectId $thisuser.Id -TargetGroupObjectId $toAdd.Id

    # Store username and password in keyvault 
    Set-AzKeyVaultSecret -VaultName $UserKV.Name -Name $displayname -SecretValue $sspw
}
