<#
.SYNOPSIS
    Returns a new LeanKit card hashtable but does not add it to a board
#>

function New-LeanKitCard{
    [CmdletBinding(DefaultParameterSetName='Profile')]
    [OutputType([array])]
    param(
        
        # ID of the lane to add the card to
        [parameter(mandatory=$true)]
        [int]$LaneID,

        # Title of the card
        [parameter(mandatory=$true)]
        [string]$Title,
        
        # Description of the card
        [parameter(mandatory=$true)]
        [string]$Description,

        # Identity of the type of card to be created
        [parameter(mandatory=$true)]
        [alias("CardTypeID")]
        [int]$TypeID,

        # Numeric priority of card
        [parameter(mandatory=$false)]
        [ValidateRange(0,3)]
        [int]$Priority=0,

        # Whether the card action is 'blocked'
        [parameter(mandatory=$false)]
        [boolean]$IsBlocked=$false,

        # The reason the card action is blocked!
        [parameter(mandatory=$false)]
        [string]$BlockReason=$null,

        # Card's location in the lane?
        [parameter(mandatory=$false)]
        [int]$Index=0,

        # Time the card's action will start
        [parameter(mandatory=$false)]
        [datetime]$StartDate=0,

        # Time the card's action will be due
        [parameter(mandatory=$false)]
        [datetime]$DueDate=0,

        # The name of the external system which the ticket is referencing with "ExternalCardID
        [parameter(mandatory=$false)]
        [string]$ExternalSystemName=0,

        # The url of the external system which the ticket is referencing with "ExternalCardID
        [parameter(mandatory=$false)]
        [string]$ExternalSystemUrl=0,

        # Comma seperated string of tags
        [parameter(mandatory=$false)]
        [string]$Tags=0,

        # ID of the class of service to be assigned to this card
        [parameter(mandatory=$false)]
        [int]$ClassOfServiceID=$null,

        # The ID of an external reference (e.g. a ticket) for this card
        [parameter(mandatory=$false)]
        [string]$ExternalCardID,
        
        # Array of user IDs assigned to this card
        [parameter(mandatory=$false)]
        [int[]]$AssignedUserIDs=@()
    )
    return @{
        LaneID=$private:LaneID
        Title=$private:Title
        Description=$private:Description
        TypeID=$private:TypeID
        Priority=$private:Priority
        IsBlocked=$private:IsBlocked
        BlockReason=$private:BlockReason
        Index=$private:Index
        StartDate=$private:StartDate
        DueDate=$private:DueDate
        ExternalSystemName=$private:ExternalSystemName
        ExternalSystemUrl=$private:ExternalSystemUrl
        Tags=$private:Tags
        ClassOfServiceID=$private:ClassOfServiceID
        ExternalCardID=$private:ExternalCardID
        AssignedUserIDs=$private:AssignedUserIDs
    }
}

<#
.SYNOPSIS
    Adds a leankit card to a board
#>
function Add-LeanKitCard{
    [CmdletBinding(DefaultParameterSetName='Profile')]
    [OutputType([array])]
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
        [string]$ProfileName,

        # ID of the board in which to update the card
        [parameter(mandatory=$true)]
        [int]$BoardID,

        # ID of the lane to update the card to
        [parameter(mandatory=$false)]
        [int]$LaneID,

        # Title of the card
        [parameter(mandatory=$false)]
        [string]$Title,
        
        # Description of the card
        [parameter(mandatory=$false)]
        [string]$Description,

        # Identity to which to update the card
        [parameter(mandatory=$false)]
        [alias("CardTypeID")]
        [int]$TypeID,

        # Numeric priority to which to update the card
        [parameter(mandatory=$false)]
        [int]$Priority,

        # Whether the card action is 'blocked'
        [parameter(mandatory=$false)]
        [boolean]$IsBlocked,

        # The reason the card action is blocked!
        [parameter(mandatory=$false)]
        [string]$BlockReason,

        # Card's location in the lane?
        [parameter(mandatory=$false)]
        [int]$Index=0,

        # Time the card's action will start
        [parameter(mandatory=$false)]
        $StartDate,

        # Time the card's action will be due
        [parameter(mandatory=$false)]
        $DueDate,

        # The name of the external system which the ticket is referencing with "ExternalCardID"
        [parameter(mandatory=$false)]
        [string]$ExternalSystemName,

        # The url of the external system which the ticket is referencing with "ExternalCardID"
        [parameter(mandatory=$false)]
        [string]$ExternalSystemUrl,

        # Comma seperated string of tags
        [parameter(mandatory=$false)]
        [string]$Tags,

        # ID of the class of service to be assigned to this card
        [parameter(mandatory=$false)]
        [int]$ClassOfServiceID=$null,

        # The ID of an external reference (e.g. a ticket) for this card
        [parameter(mandatory=$false)]
        [string]$ExternalCardID,
        
        # Array of user IDs assigned to this card
        [parameter(mandatory=$false)]
        [int[]]$AssignedUserIDs,

        # A comment to be added in case we're overriding the lane's Work in Process limit
        [parameter(mandatory=$false)]
        [string]$UserWipOverrideComment="Created programatically by PSLeanKit"
    )

    $private:Card = New-LeanKitCard `
        -LaneID  $private:LaneID `
        -Title  $private:Title `
        -Description  $private:Description `
        -TypeID  $private:TypeID `
        -Priority  $private:Priority `
        -IsBlocked  $private:IsBlocked `
        -BlockReason  $private:BlockReason `
        -Index  $private:Index `
        -StartDate  $private:StartDate `
        -DueDate  $private:DueDate `
        -ExternalSystemName  $private:ExternalSystemName `
        -ExternalSystemUrl  $private:ExternalSystemUrl `
        -Tags  $private:Tags `
        -ClassOfServiceID  $private:ClassOfServiceID `
        -ExternalCardID  $private:ExternalCardID `
        -AssignedUserIDs  $private:AssignedUserIDs

    # Pass any common parameters on to the superordinate cmdlet
    $private:Params = Merge-LeanKitProfileDataWithExplicitParams -ExplicitParams $PsBoundParameters

    $private:Params.boardID = $private:BoardID 
    $private:Params.cards = @($private:Card)
    $private:Params.WipOverrideComment = $private:UserWipOverrideComment
    $global:testgoat2 = $private:params;
    return Add-LeanKitCards @private:params
}

function Add-LeanKitCards{
    [CmdletBinding(DefaultParameterSetName='Profile')]
    [OutputType([array])]
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
        [string]$ProfileName,

        # ID of the board
        [parameter(mandatory=$true)]
        [int]$boardID,

        # A reason for overridding the WorkInProgress Limit
        [parameter(mandatory=$false)]
        [string]$WipOverrideComment='',

        # Array of card hashtables created from New-LeanKitCard
        [parameter(mandatory=$true)]
        [ValidateScript({
            if($_.length -gt 100){
                #"You cannot pass greater than 100 cards at a time to add-LeanKitCards"
                return $false;
            }
            return $true;
        })]
        [hashtable[]]$cards
    )

    # Try and get defaults and break out of the function with a null value if we can't
    $private:LeanKitProfile = Merge-LeanKitProfileDataWithExplicitParams -ProfileData $(Get-LeanKitProfile) -ExplicitParams $PsBoundParameters -ErrorOnIncompleteResultantData -ErrorAction Stop

    # Loop through and convert each card's date to the correct format
    $Private:LeanKitDateFormat = Get-LeanKitDateFormat @private:LeanKitProfile
    
    foreach($private:Card in $private:Cards){
        
        $private:Card.StartDate = [string]$(if($private:Card.StartDate){(Get-Date $private:Card.StartDate -format $Private:LeanKitDateFormat)}else{""})
        $private:Card.DueDate = [string]$(if($private:Card.DueDate ){Get-Date $private:Card.DueDate  -format $Private:LeanKitDateFormat}else{""})
    }
    
    [string]$uri = $private:LeanKitProfile.URL + "/Kanban/Api/Board/$boardID/AddCards?wipOverrideComment=$WipOverrideComment"
    $private:result = Invoke-RestMethod -Uri $uri -Credential $private:LeanKitProfile.Credential -Method Post -Body $(ConvertTo-Json $cards ) -ContentType "application/json"
    if($private:result.ReplyCode -ne 201){
        Write-Warning "Failed to add cards `r`n`t$($private:result.ReplyCode) - $($private:result.ReplyText)";
        return $private:result
    }else{
        return $private:result.ReplyData
    }

    

}

function Get-LeanKitCard {
    [CmdletBinding(DefaultParameterSetName='Profile')]
    [OutputType([array])]
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
        [string]$ProfileName,

        # ID of the board in which the card we're getting resides
        [parameter(mandatory=$true)]
        [int]$boardID,

        # ID of the card we're getting
        [parameter(mandatory=$true)]
        [int]$CardID
    )

    # Check for a default profile and merge the explicit creds/url with it
    $private:LeanKitProfile = Merge-LeanKitProfileDataWithExplicitParams -ProfileData $(Get-LeanKitProfile) -ExplicitParams $PsBoundParameters -ErrorOnIncompleteResultantData -ErrorAction Stop

    [string]$private:uri = $private:LeanKitProfile.URL + "/Kanban/Api/Board/$private:boardID/GetCard/$private:CardID"
    Write-Verbose $private:uri #debug
    return $(Invoke-RestMethod -Uri $private:uri  -Credential $private:LeanKitProfile.Credential).ReplyData
}

function Update-LeanKitCard{
    [CmdletBinding(DefaultParameterSetName='Profile')]
    [OutputType([array])]
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
        [string]$ProfileName,

        # ID of the board in which to update the card
        [parameter(mandatory=$true)]
        [int]$BoardID,

         # ID of the card to update
        [parameter(mandatory=$true)]
        [alias('CardID')]
        [int]$ID,

        # ID of the lane to update the card to
        [parameter(mandatory=$false)]
        [int]$LaneID,

        # Title of the card
        [parameter(mandatory=$false)]
        [string]$Title,
        
        # Description of the card
        [parameter(mandatory=$false)]
        [string]$Description,

        # Identity to which to update the card
        [parameter(mandatory=$false)]
        [alias("CardTypeID")]
        [int]$TypeID,

        # Numeric priority to which to update the card
        [parameter(mandatory=$false)]
        [ValidateRange(0,3)]
        [int]$Priority,

        # Whether the card action is 'blocked'
        [parameter(mandatory=$false)]
        [boolean]$IsBlocked,

        # The reason the card action is blocked!
        [parameter(mandatory=$false)]
        [string]$BlockReason,

        # Card's location in the lane?
        [parameter(mandatory=$false)]
        [int]$Index=0,

        # Time the card's action will start
        [parameter(mandatory=$false)]
        $StartDate,

        # Time the card's action will be due
        [parameter(mandatory=$false)]
        $DueDate,

        # The name of the external system which the ticket is referencing with "ExternalCardID"
        [parameter(mandatory=$false)]
        [string]$ExternalSystemName,

        # The url of the external system which the ticket is referencing with "ExternalCardID"
        [parameter(mandatory=$false)]
        [string]$ExternalSystemUrl,

        # Comma seperated string of tags
        [parameter(mandatory=$false)]
        [string]$Tags,

        # ID of the class of service to be assigned to this card
        [parameter(mandatory=$false)]
        [int]$ClassOfServiceID=$null,

        # The ID of an external reference (e.g. a ticket) for this card
        [parameter(mandatory=$false)]
        [string]$ExternalCardID,
        
        # Array of user IDs assigned to this card
        [parameter(mandatory=$false)]
        [int[]]$AssignedUserIDs,

        # A comment to be added in case we're overriding the lane's Work in Process limit
        [parameter(mandatory=$false)]
        [string]$UserWipOverrideComment="Created programatically by PSLeanKit"
    )
   
    # Pass any common parameters on to the superordinate cmdlet
    $private:LeanKitProfile = Merge-LeanKitProfileDataWithExplicitParams -ExplicitParams $PsBoundParameters
    
    # Fetch the card and pipe it's existing values into a hashtable for manipulation 
    $private:CardHashTable = @{};
    $private:Params = $private:LeanKitProfile.clone()
    $private:Params.boardID = $private:BoardID 
    $private:Params.CardID = $private:Id
    $private:Card = Get-LeanKitCard @private:Params
    $private:Card | Get-Member | ?{$_.MemberType -eq "NoteProperty"} | %{$private:CardHashTable.add($_.name, $private:Card.$($_.name))}

    # Loop through our params (those that are set) and ensure the hashtable reflects the values we've updated
    foreach($private:key in $private:CardHashTable.Keys.Clone()){

        if(([array]$PSBoundParameters.keys) -Contains($private:key)){
            $private:CardHashTable.$private:key = (Get-Variable  -Scope Private -Name $private:key).Value
        }
    }

    $private:Params = $private:LeanKitProfile.clone();
    $private:Params.BoardID = $private:BoardID 
    $private:Params.Cards = @($private:CardHashTable) 
    $private:Params.UserWipOverrideComment = $private:UserWipOverrideComment
    return Update-LeanKitCards @private:Params
}

function Update-LeanKitCards{
    [CmdletBinding(DefaultParameterSetName='Profile')]
    [OutputType([array])]
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
        [string]$ProfileName,

        # ID of the board the card resides in
        [parameter(mandatory=$true)]
        [int]$BoardID,

        [parameter(mandatory=$true)]
        [ValidateScript({
            if($_.length -gt 100){
                # You cannot pass greater than 100 cards at a time to Update-LeanKitCards
                return $false;
            }
            if(
                ($_ |?{$_.ID}).length -lt $_.length
               ){
                # All cards must have an ID when passing to Update-LeanKitCards;
                return $false;
            }
            return $true;
        })]
        [hashtable[]]$Cards,

        # A message to provide in case we override a lane's Work in Process limit
        [parameter(mandatory=$false)]
        [string]$UserWipOverrideComment="Updated by PSLeankit automatically"
    )

    # Check for a default profile and merge the explicit creds/url with it
    $private:LeanKitProfile = Merge-LeanKitProfileDataWithExplicitParams -ProfileData $(Get-LeanKitProfile) -ExplicitParams $PsBoundParameters -ErrorOnIncompleteResultantData -ErrorAction Stop

    # Loop through and convert each card's date to the correct format
    $Private:LeanKitDateFormat = Get-LeanKitDateFormat @private:LeanKitProfile
    
    foreach($private:Card in $private:Cards){
        
        $private:Card.StartDate = [string]$(if($private:Card.StartDate){(Get-Date $private:Card.StartDate -format $Private:LeanKitDateFormat)}else{""})
        $private:Card.DueDate = [string]$(if($private:Card.DueDate ){Get-Date $private:Card.DueDate  -format $Private:LeanKitDateFormat}else{""})
    }

    # Format the URL and submit the request
    [string]$private:uri = $private:LeanKitProfile.URL + "/Kanban/Api/Board/$private:boardID/UpdateCards?wipOverrideComment=$private:UserWipOverrideComment"
    $private:result = Invoke-RestMethod -Uri $private:uri -Credential $private:LeanKitProfile.Credential -Method Post -Body $(ConvertTo-Json $private:cards) -ContentType "application/json" 
    
    # Check the request succeeded
    if($private:result.ReplyCode -ne 201){
        Write-Warning "Failed to update cards `r`n`t$($private:result.ReplyCode) - $($private:result.ReplyText)";
        return $private:result
    }else{
        return @($private:result).ReplyData
    }

}

function Remove-LeanKitCard {
    [CmdletBinding(DefaultParameterSetName='Profile')]
    [OutputType([array])]
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
        [string]$ProfileName,

        # ID of the board in which the card we're deleting resides
        [parameter(mandatory=$true)]
        [int]$BoardID,

        # ID of the card we're deleting
        [parameter(mandatory=$true)]
        [int]$CardID
    )

    # Pass any common parameters on to the superordinate cmdlet
    $private:Params = Merge-LeanKitProfileDataWithExplicitParams -ExplicitParams $PsBoundParameters

    $private:Params.BoardID = $private:BoardID 
    $private:Params.CardIDs = @($private:CardID)

    return Remove-LeanKitCards @private:Params
}

function Remove-LeanKitCards {
    [CmdletBinding(DefaultParameterSetName='Profile')]
    [OutputType([array])]
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
        [string]$ProfileName,

        # ID of the board in which the cards we're deleting reside
        [parameter(mandatory=$true)]
        [int]$BoardID,

        # Array of card IDs to delete
        [parameter(mandatory=$true)]
        [int[]]$CardIDs
    )

    # Check for a default profile and merge the explicit creds/url with it
    $private:LeanKitProfile = Merge-LeanKitProfileDataWithExplicitParams -ProfileData $(Get-LeanKitProfile) -ExplicitParams $PsBoundParameters -ErrorOnIncompleteResultantData -ErrorAction Stop

    [string]$uri = $private:LeanKitProfile.URL + "/Kanban/Api/Board/$private:boardID/DeleteCards/"
    $result = Invoke-RestMethod -Uri $uri  -Credential $private:LeanKitProfile.Credential -Method Post -Body $(ConvertTo-Json $private:CardIDs) -ContentType "application/json" 
    return $result.ReplyData
}