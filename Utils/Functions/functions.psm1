# This file is used to prevent code redundancy in the module scripts

function Get-GuidSS {
    $ret = New-Guid
    $ret = $ret -replace '-',''
    $ret = $ret.ToString().Substring(0,15)
    $ret.ToString()
}

Export-ModuleMember -Function *
