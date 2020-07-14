# This file is used to prevent code redundancy in the module scripts

function Get-GuidSS {
    $ret = New-Guid
    $ret = $ret -replace '-',''
    $ret = $ret.ToString().Substring(0,15)
    $ret.ToString()
}

# TODO: Get these three functions working, they have this random issue where
# They just list a bunch of the subs but don't do it right, don't store vars
# and don't return anything 
function Get-UserSub ([String]$prompt) {
    begin {$allSubs = Get-AzSubscription}
    process {
        $userInput = Read-Host -Prompt $prompt
        $userInput = "*" + $userInput + "*"
        $ret = $allSubs | Where-Object Name -CLike $userInput
        return $ret
    }
}

function Get-StartSub {
    $prompt = "Input the name of the Start Subscription"
    $ret = Get-UserSub -prompt $prompt
    return $ret
}

function Get-EndSub {
    $prompt = "Input the name of the End Subscription"
    $ret = Get-UserSub -prompt $prompt
    return $ret
}

Export-ModuleMember -Function *
