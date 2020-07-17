# This wrapper function will call on the necessary creation or teardown scripts

# Import Functions
$wd = Get-Location
$modules = $wd.ToString() + "\Utils\functions"
Import-Module -Name $modules 

# Connect to AzureAd and AzureCLI
Connect-AzureAD
Az login

# Get the start and end subscriptions
$allSubs = Get-AzSubscription
$prompt1 = Read-Host -Prompt 'Input the name of the start subscription'
$prompt2 = Read-Host -Prompt 'Input the name of the end subscription'
$input1 = "*" + $prompt1 + "*"
$input2 = "*" + $prompt2 + "*"
$SubOne = $allSubs | Where-Object Name -CLike $input1
$SubTwo = $allSubs | Where-Object Name -CLike $input2

# Decide if we are creating or deleting modules
$cOrT = "create","teardown"
do {
    $prompt3 = Read-Host -Prompt 'Do you want to create or teardown modules?'
    $input3 = $input3 + "*"
    $decision = $cOrT -match $prompt3
    if ((($decision -ne "create") -and ($decision -ne "teardown")) -or !$decision) {
        Write-Host "That wasn't a valid input, try again `n"
    } else {
        break
    }
} while ((($decision -ne "create") -and ($decision -ne "teardown")) -or !$decision)

# Which modules to create/teardown?
Write-Host "Enter the modules you want to $decision, comma separated if there are multiple. `r"
Write-Host "For example, for Modules One and Two, you could enter 'ModuleOne, ModuleTwo' or 'm1,m2'"
$modules = Read-Host -Prompt "Enter module name(s)"

# If creating, ask for the number of users
if ($decision -eq "create") {
    $users = Read-Host -Prompt "How many users would you like?"
    $domainname = Read-Host -Prompt "What domain name will the user account(s) use?"
}

# Modify String
$modules = $modules.Replace(" ","")

# Either create or teardown each module
$res
foreach ($mod in $modules.Split(",")) {
    
    # Finding the module name
    if (($mod -eq "moduleone") -or ($mod -eq "module1") -or ($mod -eq "m1")) {
        $res = "ModuleOne"
    } elseif (($mod -eq "moduletwo") -or ($mod -eq "module2") -or ($mod -eq "m2")) {
        $res = "ModuleTwo"
    } elseif(($mod -eq "modulethree") -or ($mod -eq "module3") -or ($mod -eq "m3")) {
        $res = "ModuleThree"}
    else {
        Write-Host "$mod is not a recognized module name`n"
        $res = $null
    }

    # Create or delete
    if ($res) {
        if ($decision -eq "create") {
            Set-Location .\$res
            .\create.ps1 $SubOne $SubTwo $users $domainname
            Set-Location ..
        } else {
            Set-Location .\$res
            .\teardown $SubOne $SubTwo
            Set-Location ..
        }
    }
}

