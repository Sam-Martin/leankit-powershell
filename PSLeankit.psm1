function Test-LeankitAuthIsSet{
    if($Global:leankitCreds){
        return $true;
    }else{
        return $false;
    }   
}

function Set-LeanKitAuth{
    param(
        [parameter(mandatory=$true)]
        [string]$url,
        
        [parameter(mandatory=$true)]
        [System.Management.Automation.PSCredential]$credentials
    )
    $global:leanKitURL = 'https://' + $url;
    $global:leankitCreds = $credentials
    return $true;
}

<#
.SYNOPSIS
    Cleans up the variables containing your authentication information from your PowerShell session
#>
function Remove-LeanKitAuth{
     Remove-Variable -Name leanKitURL -Scope Global
     Remove-Variable -Name leankitCreds -Scope Global
     return $true;
}
