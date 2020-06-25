# This script will delete all service principles beginning with a certain string

function Remove-ServicePrincipals {
    param($name)
    Connect-AzureAD
    $sps = Get-AzureADApplication
    $name = $name + "*"
    $toDel = $sps | Where-Object DisplayName -Clike $name
    foreach ($app in $toDel) {Remove-AzureADApplication -ObjectId $app.ObjectId}
}

Export-ModuleMember -Function Remove-ServicePrincipals
