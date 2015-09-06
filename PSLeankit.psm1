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

    Write-Warning "Set-LeanKitAuth is deprecated and will be removed in a later version. Please use Initialize-LeanKitDefaults"

    $global:LeanKitURL = 'https://' + $url;
    $global:LeanKitCreds = $credential
    
    # Fetch the date format for the user (API doesn't use ISO standard date formats :( )
    try{
        $private:Board = Find-LeanKitBoard -URL $url -credential $credential -ErrorAction Stop | Get-Random
        $private:Board = Get-LeanKitBoard -URL $url -credential $credential -BoardID $private:Board.Id -ErrorAction Stop
        $global:LeanKitDateFormat= ($Board.BoardUsers | ?{$_.EmailAddress -eq $global:LeanKitCreds.UserName}).DateFormat
    }catch{
        Write-Error $_.Exception.Message;
        return $false;
    }

    return $true;
}

function Get-LeanKitDateFormat{
     param(
        # URL of the leankit account
        [Parameter(ParameterSetName='Credential')]
        [string]$URL,
        
        # PSCredentialsObject with the username and password needed to auth against leankit
        [Parameter(ParameterSetName='Credential')]
        [alias('credentials')]
        [pscredential]$credential,
        
        # Name of the profile to load
        [Parameter(ParameterSetName='Profile')]
        [string]$ProfileName
    )

    # Pass any common parameters on to the superordinate cmdlet
    $private:BaseParams = Merge-LeanKitProfileDataWithExplicitParams -ProfileData $(Get-LeanKitProfile -ProfileName $ProfileName) -ExplicitParams $PsBoundParameters
    $private:BaseParams.ErrorAction = 'Stop'
    
    # Get a board from the list
    $private:Board = Find-LeanKitBoard @private:BaseParams | Get-Random
        
    Write-Verbose "Looking for user in $($private:Board.Id)"

    # Get board details
    $private:Params = $private:BaseParams.clone();
    $private:Params.BoardID = $private:Board.Id
    $private:Board = Get-LeanKitBoard @private:Params

    $global:board = $private:Board

    # Find the DateFormat from the user
    if(!($private:LeanKitDateFormat = ($private:Board.BoardUsers | ?{$_.EmailAddress -eq $private:BaseParams.Credential.UserName}).DateFormat)){
        Write-Error "Failed to get DateFormat for some reason";
    }
    return $private:LeanKitDateFormat

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

function Add-LeanKitProfile{
    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
    param(
        [parameter(mandatory=$true)]
        [string]$url,
        
        [parameter(mandatory=$true)]
        [Alias("credentials")] 
        [System.Management.Automation.PSCredential]$credential,

        # Optional profile name to allow you to store defaults for multiple leankit organisations
        [string]$profilename = 'default',
        
        # Optional parameter specifying the folder where profiles are stored
        $private:ProfileLocation = "$env:USERPROFILE\PSLeankit\"
    )

    # Strip http/s from the URL if it's provided
    $private:url = $url -replace 'http[s]?://', ''

    # Build the leankit Profile
    $private:Configuration = @{
        "url" = $private:url
        "credential" = @{
            "username" = $private:credential.UserName
            "password" = $private:credential.Password | ConvertFrom-SecureString
        }
    } 

    # Create the profile folder if need be
    New-Item $private:ProfileLocation -ItemType container -ErrorAction SilentlyContinue
    
    $private:ProfilePath = "$env:USERPROFILE\PSLeankit\$ProfileName-$env:COMPUTERNAME.json"
    
    # Check for the existence of a matching profile for this computer and confirm if we find it
    if((Test-Path $private:ProfilePath) -and !($pscmdlet.ShouldProcess($private:ProfilePath, "Overwrite"))){
        
        # User opted not to overwrite
        return;   
    }

    Set-Content -Path $private:ProfilePath -Value $($private:Configuration| ConvertTo-Json)

    return $private:Configuration

}


<#
    .SYNOPSIS
        Helper function to merge explicitly defined params with profile defaults.

#>
function Merge-LeanKitProfileDataWithExplicitParams{
    param(
        # The ProfileData hashtable (you can usefully merge with a blank hashtable to filter out irrelevant params)
        [parameter(Mandatory=$false)]
        $ProfileData = @{},
        
        # The Explicit Params hashtable
        [parameter(Mandatory=$true)]
        $ExplicitParams,
        
        # Optional switch to error if we don't end up with a full profile
        [switch]$ErrorOnIncompleteResultantData
    )

    # Ensure $ProfileData is a hashtable rather than $null
    if(!$ProfileData){$ProfileData = @{}}
    
    # Ensure $ProfileData is a hashtable
    if($ProfileData.GetType().name -ne "HashTable"){
        $Private:ProfileHashTable = @{}
        $private:ProfileData | Get-Member | ?{$_.MemberType -eq "NoteProperty"} | %{$private:ProfileHashTable.add($_.name, $private:ProfileData.$($_.name))}
        $private:ProfileData = $Private:ProfileHashTable
    }
    

    # We're only interested in a few params to merge into the profile
    $private:ParamsToSearchFor = @("URL", "Credential")

    # Loop through only those parameters we're interested in
    foreach($private:Parameter in $ExplicitParams.keys | ?{$private:ParamsToSearchFor -contains $_}){
        
        Write-Verbose "Found explicit $private:Parameter";
        # Merge this param into the profile properties
        $ProfileData.$private:Parameter = $ExplicitParams.$private:Parameter
    }

    # Do we want to validate if we have a full dataset?
    if(!$ErrorOnIncompleteResultantData.IsPresent){
        return $Private:ProfileData
    }

    # Generate a list of any missing properties
    Write-Verbose "Checking we have all the variables we need to authenticate against the API"
    $private:MissingProperties = $private:ParamsToSearchFor | ?{$private:ProfileData.Keys -notcontains $_}

    $global:profiledata = $private:ProfileData  #debug

    # Throw an error if we have missing properties
    if($private:MissingProperties.Count -gt 0){
        $private:ErrorMessage =  "You are missing the following properties `r`n`t" + 
                         "{0}`r`n" -f $($private:MissingProperties -join ', ') +
                         "Please populate defaults using Initialize-LeankitDefaults or pass these values as parameters" 
        Write-Error $private:ErrorMessage
        return;
    }

    return $Private:ProfileData
}

function Get-LeanKitProfile{
    [CmdletBinding()]
    param(
        # Name of the profile we wish to load
        [string]$ProfileName = 'default'
    )

    # Check for the existence of a matching profile for this computer and load it if we find it
    $private:ProfilePath = "$env:USERPROFILE\PSLeankit\$ProfileName-$env:COMPUTERNAME.json"
    if(Test-Path $private:ProfilePath){

        Write-Verbose "Loading defaults from $private:ProfilePath"
        $private:ProfileProperties = Get-Content $private:ProfilePath | Out-String | ConvertFrom-Json
    }else{
        Write-Verbose "Could not find $private:ProfilePath"
    }

    # Convert the credential property into a PSCredentials object if it exists
    if($private:ProfileProperties.credential){
        $private:Params = @{ArgumentList = @($ProfileValues.credential.username, $(ConvertTo-SecureString $ProfileValues.credential.password))}
        $private:ProfileProperties.credential = New-Object System.Management.Automation.PSCredential @private:Params
    }

    # Return the defaults merged with the params
    return $private:ProfileProperties
}