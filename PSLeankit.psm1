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
    
    # Fetch the date format for the user (API doesn't use ISO standard date formats :( )
    try{
        $private:Board = Find-LeanKitBoard -ErrorAction Stop | Get-Random
        $private:Board = Get-LeanKitBoard -BoardID $private:Board.Id -ErrorAction Stop
        $global:LeanKitDateFormat= ($Board.BoardUsers | ?{$_.EmailAddress -eq $global:LeanKitCreds.UserName}).DateFormat
    }catch{
        Write-Error $_.Exception.Message;
        return $false;
    }

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
