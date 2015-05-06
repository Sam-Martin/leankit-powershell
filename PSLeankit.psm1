function Test-LeanKitAuthIsSet{
    if($Global:LeanKitCreds){
        return $true;
    }else{
        return $false;
    }   
}

function Set-LeanKitAuth{
    [CmdletBinding()]
    param(
        [parameter(mandatory=$true)]
        [string]$url,
        
        [parameter(mandatory=$true)]
        [System.Management.Automation.PSCredential]$credentials
    )
    $global:LeanKitURL = 'https://' + $url;
    $global:LeanKitCreds = $credentials
    return $true;
}

<#
.SYNOPSIS
    Cleans up the variables containing your authentication information from your PowerShell session
#>
function Remove-LeanKitAuth{
    [CmdletBinding()]
    param()
    Remove-Variable -Name LeanKitURL -Scope Global
    Remove-Variable -Name LeanKitCreds -Scope Global
    return $true;
}
