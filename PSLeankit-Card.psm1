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
        LaneID=$LaneID
        Title=$Title
        Description=$Description
        TypeID=$TypeID
        Priority=$Priority
        IsBlocked=$IsBlocked
        BlockReason=$BlockReason
        Index=$Index
        StartDate=$StartDate
        DueDate=$DueDate
        ExternalSystemName=$ExternalSystemName
        ExternalSystemUrl=$ExternalSystemUrl
        Tags=$Tags
        ClassOfServiceID=$ClassOfServiceID
        ExternalCardID=$ExternalCardID
        AssignedUserIDs=$AssignedUserIDs
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

    $StartDate = if($StartDate){(Get-Date $StartDate -format $global:LeanKitDateFormat)}else{""}
    $DueDate = if($DueDate ){Get-Date $DueDate  -format $global:LeanKitDateFormat}else{""}

    $script:Card = New-LeanKitCard `
        -LaneID  $LaneID `
        -Title  $Title `
        -Description  $Description `
        -TypeID  $TypeID `
        -Priority  $Priority `
        -IsBlocked  $IsBlocked `
        -BlockReason  $BlockReason `
        -Index  $Index `
        -StartDate  $StartDate `
        -DueDate  $DueDate `
        -ExternalSystemName  $ExternalSystemName `
        -ExternalSystemUrl  $ExternalSystemUrl `
        -Tags  $Tags `
        -ClassOfServiceID  $ClassOfServiceID `
        -ExternalCardID  $ExternalCardID `
        -AssignedUserIDs  $AssignedUserIDs


    return (Add-LeanKitCards -boardID $BoardID -cards @($Card) -WipOverrideComment $UserWipOverrideComment).ReplyData
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
    return [array](Invoke-RestMethod -Uri $uri -Credential $global:LeanKitCreds -Method Post -Body $(ConvertTo-Json $cards ) -ContentType "application/json")

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

    [string]$uri = $global:LeanKitURL + "/Kanban/Api/Board/$boardID/GetCard/$CardID"
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
   
    if($StartDate){$StartDate = (Get-Date $StartDate -format $global:LeanKitDateFormat)}
    if($DueDate){$DueDate = Get-Date $DueDate  -format $global:LeanKitDateFormat}
    
    # Pipe the card's existing values into a hashtable for manipulation 
    $CardHashTable = @{};
    $Card = Get-LeanKitCard -boardID $BoardID -CardID $CardID;
    $Card | Get-Member | ?{$_.MemberType -eq "NoteProperty"} | %{$CardHashTable.add($_.name, $Card.$($_.name))}

    # Loop through our params (those that are set) and ensure the hashtable reflects the values we've updated
    foreach($key in $CardHashTable.Keys.Clone()){

        if(([array]$PSBoundParameters.keys) -Contains($key)){
            $CardHashTable.$key = (Get-Item variable:\$key).Value
        }
    }

    return Update-LeanKitCards -BoardID $BoardID -Cards @($CardHashTable)  -UserWipOverrideComment $UserWipOverrideComment
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

    [string]$uri = $global:LeanKitURL + "/Kanban/Api/Board/$boardID/UpdateCards?wipOverrideComment=$UserWipOverrideComment"
    $result = Invoke-RestMethod -Uri $uri -Credential $global:LeanKitCreds -Method Post -Body $(ConvertTo-Json $cards) -ContentType "application/json" 
    if($result.ReplyCode -ne 201){
        return $result
    }else{
        return $result.ReplyData
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
    
    return Remove-LeanKitCards -BoardID $BoardID -CardIDs @($CardID)
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

    [string]$uri = $global:LeanKitURL + "/Kanban/Api/Board/$boardID/DeleteCards/"
    $result = Invoke-RestMethod -Uri $uri  -Credential $global:LeanKitCreds -Method Post -Body $(ConvertTo-Json $CardIDs) -ContentType "application/json" 
    return $result.ReplyData
}