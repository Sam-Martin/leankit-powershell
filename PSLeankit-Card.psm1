<#
.SYNOPSIS
    Returns a new LeanKit card hashtable but does not add it to a board
#>

function New-LeanKitCard{
    [CmdletBinding()]
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
        [string]$StartDate=0,

        # Time the card's action will be due
        [parameter(mandatory=$false)]
        [string]$DueDate=0,

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
    [CmdletBinding()]
    [OutputType([array])]
    param(
        
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

    $private:StartDate = if($private:StartDate){(Get-Date $private:StartDate -format $global:LeanKitDateFormat)}else{""}
    $private:DueDate = if($private:DueDate ){Get-Date $private:DueDate  -format $global:LeanKitDateFormat}else{""}

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


    return Add-LeanKitCards -boardID $private:BoardID -cards @($private:Card) -WipOverrideComment $private:UserWipOverrideComment
}

function Add-LeanKitCards{
    [CmdletBinding()]
    [OutputType([array])]
    param(
        [parameter(mandatory=$true)]
        [int]$boardID,

        [parameter(mandatory=$false)]
        [string]$WipOverrideComment='',

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

    if(!(Test-LeanKitAuthIsSet)){
        Set-LeanKitAuth | Out-Null
    }
    
    [string]$uri = $global:LeanKitURL + "/Kanban/Api/Board/$boardID/AddCards?wipOverrideComment=$WipOverrideComment"
    $private:result = Invoke-RestMethod -Uri $uri -Credential $global:LeanKitCreds -Method Post -Body $(ConvertTo-Json $cards ) -ContentType "application/json"
    if($private:result.ReplyCode -ne 201){
        Write-Warning "Failed to add cards `r`n`t$($private:result.ReplyCode) - $($private:result.ReplyText)";
        return $private:result
    }else{
        return $private:result.ReplyData
    }

    

}

function Get-LeanKitCard {
    [CmdletBinding()]
    [OutputType([array])]
    param(
        # ID of the board in which the card we're getting resides
        [parameter(mandatory=$true)]
        [int]$boardID,

        # ID of the card we're getting
        [parameter(mandatory=$true)]
        [int]$CardID
    )

    if(!(Test-LeanKitAuthIsSet)){
        Set-LeanKitAuth | Out-Null
    }

    [string]$uri = $global:LeanKitURL + "/Kanban/Api/Board/$private:boardID/GetCard/$private:CardID"
    return $(Invoke-RestMethod -Uri $uri  -Credential $global:LeanKitCreds).ReplyData
}

function Update-LeanKitCard{
    [CmdletBinding()]
    [OutputType([array])]
    param(
        
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
   
    if($private:StartDate){$private:StartDate = (Get-Date $private:StartDate -format $global:LeanKitDateFormat)}
    if($private:DueDate){$private:DueDate = Get-Date $private:DueDate  -format $global:LeanKitDateFormat}
    
    # Pipe the card's existing values into a hashtable for manipulation 
    $private:CardHashTable = @{};
    $private:Card = Get-LeanKitCard -boardID $private:BoardID -CardID $private:Id;
    $private:Card | Get-Member | ?{$_.MemberType -eq "NoteProperty"} | %{$private:CardHashTable.add($_.name, $private:Card.$($_.name))}

    # Loop through our params (those that are set) and ensure the hashtable reflects the values we've updated
    foreach($private:key in $private:CardHashTable.Keys.Clone()){

        if(([array]$PSBoundParameters.keys) -Contains($private:key)){
            $private:CardHashTable.$private:key = (Get-Variable  -Scope Private -Name $private:key).Value
        }
    }

    return Update-LeanKitCards -BoardID $private:BoardID -Cards @($private:CardHashTable)  -UserWipOverrideComment $private:UserWipOverrideComment
}

function Update-LeanKitCards{
    [CmdletBinding()]
    [OutputType([array])]
    param(
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

    if(!(Test-LeanKitAuthIsSet)){
        Set-LeanKitAuth | Out-Null
    }

    [string]$private:uri = $global:LeanKitURL + "/Kanban/Api/Board/$private:boardID/UpdateCards?wipOverrideComment=$private:UserWipOverrideComment"
    $private:result = Invoke-RestMethod -Uri $private:uri -Credential $global:LeanKitCreds -Method Post -Body $(ConvertTo-Json $private:cards) -ContentType "application/json" 
    if($private:result.ReplyCode -ne 201){
        Write-Warning "Failed to update cards `r`n`t$($private:result.ReplyCode) - $($private:result.ReplyText)";
        return $private:result
    }else{
        return @($private:result).ReplyData
    }

}

function Remove-LeanKitCard {
    [CmdletBinding()]
    [OutputType([array])]
    param(
        # ID of the board in which the card we're deleting resides
        [parameter(mandatory=$true)]
        [int]$BoardID,

        # ID of the card we're deleting
        [parameter(mandatory=$true)]
        [int]$CardID
    )
    
    return Remove-LeanKitCards -BoardID $private:BoardID -CardIDs @($private:CardID)
}

function Remove-LeanKitCards {
    [CmdletBinding()]
    [OutputType([array])]
    param(
        # ID of the board in which the cards we're deleting reside
        [parameter(mandatory=$true)]
        [int]$BoardID,

        # Array of card IDs to delete
        [parameter(mandatory=$true)]
        [int[]]$CardIDs
    )

    if(!(Test-LeanKitAuthIsSet)){
        Set-LeanKitAuth | Out-Null
    }

    [string]$uri = $global:LeanKitURL + "/Kanban/Api/Board/$private:boardID/DeleteCards/"
    $result = Invoke-RestMethod -Uri $uri  -Credential $global:LeanKitCreds -Method Post -Body $(ConvertTo-Json $private:CardIDs) -ContentType "application/json" 
    return $result.ReplyData
}