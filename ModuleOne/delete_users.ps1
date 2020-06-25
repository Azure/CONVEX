# This PowerShell script will delete all users and group

# Get the group that the users are in
$groups = Get-AzAdGroup
$toDel = $groups | where DisplayName -Clike "m1*"

# Remove all the users
$usrList = Get-AzADGroupMember -GroupObjectId $toDel.Id
foreach ($usr in $usrList) {
    
    Remove-AzADUser -DisplayName $usr.DisplayName -Force
}

# Remove the group from AAD
Remove-AzADGroup -ObjectId $toDel.id -Force
