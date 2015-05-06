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
        
        # ID of the board to which to add the card
        [parameter(mandatory=$true)]
        [int]$BoardID,

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
        $StartDate=$null,

        # Time the card's action will be due
        [parameter(mandatory=$false)]
        $DueDate=$null,

        # The name of the external system which the ticket is referencing with "ExternalCardID"
        [parameter(mandatory=$false)]
        [string]$ExternalSystemName=0,

        # The url of the external system which the ticket is referencing with "ExternalCardID"
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
        [int[]]$AssignedUserIDs=@(),

        # A comment to be added in case we're overriding the lane's Work in Process limit
        [parameter(mandatory=$false)]
        [string]$UserWipOverrideComment="Created programatically by PSLeanKit"
    )

    # Fetch the date format for the user (API doesn't use ISO standard date formats :O)
    $script:Board = Get-LeanKitBoard -BoardID $BoardID 
    $script:DateFormat= ($Board.BoardUsers | ?{$_.EmailAddress -eq $global:LeanKitCreds.UserName}).DateFormat

    $StartDate = if($StartDate){(Get-Date $StartDate -format $DateFormat)}else{""}
    $DueDate = if($DueDate ){Get-Date $DueDate  -format $DateFormat}else{""}

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
        Set-LeanKitAuth
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
        Set-LeanKitAuth
    }

    [string]$uri = $global:LeanKitURL + "/Kanban/Api/Board/$boardID/GetCard/$CardID"
    return $(Invoke-RestMethod -Uri $uri  -Credential $global:LeanKitCreds).ReplyData
}

function Update-LeanKitCard {
    [CmdletBinding()]
    [OutputType([array])]
    param(
        # ID of the board in which the card we're updating resides
        [parameter(mandatory=$true)]
        [int]$BoardID,

        # ID of the card we're updating
        [parameter(mandatory=$true)]
        [int]$CardID,

        # Title to change the card to have
        [parameter(mandatory=$false)]
        [string]$Title
    )

    if(!(Test-LeanKitAuthIsSet)){
        Set-LeanKitAuth
    }
    
    # Fetch the original card to amend
    $Card = Get-LeanKitCard -BoardID $BoardID -CardID $CardID

    # Transform it into a hashtable
    $UpdatedCard = @{UserWipOverrideComment = "No override"};
    $Card | Get-Member | ?{$_.MemberType -eq "NoteProperty"} | %{$UpdatedCard.add($_.name, $Card.$($_.name))}

    # Update our params (I wish PowerShell had ternary operators...)
    $UpdatedCard.Title = if($Title){$Title}else{$Card.Title};

    return (Update-LeanKitCards -BoardID $BoardID -Cards @($UpdatedCard))[0]
}

function Update-LeanKitCards{
    [CmdletBinding()]
    [OutputType([array])]
    param(
        [parameter(mandatory=$true)]
        [int]$boardID,

        [parameter(mandatory=$true)]
        [ValidateScript({
            if($_.length -gt 100){
                # "You cannot pass greater than 100 cards at a time to Update-LeanKitCards"
                return $false;
            }
            if(
                ($_ |?{$_.ID}).length -lt $_.length
               ){
                # "All cards must have an ID when passing to Update-LeanKitCards";
                return $false;
            }
            return $true;
        })]
        [hashtable[]]$cards
    )

    if(!(Test-LeanKitAuthIsSet)){
        Set-LeanKitAuth
    }

    [string]$uri = $global:LeanKitURL + "/Kanban/Api/Board/$boardID/UpdateCards?wipOverrideComment=Automation"
    $result = Invoke-RestMethod -Uri $uri  -Credential $global:LeanKitCreds -Method Post -Body $(ConvertTo-Json $cards) -ContentType "application/json" 
    return $result.ReplyData
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
        Set-LeanKitAuth
    }

    [string]$uri = $global:LeanKitURL + "/Kanban/Api/Board/$boardID/DeleteCards/"
    $result = Invoke-RestMethod -Uri $uri  -Credential $global:LeanKitCreds -Method Post -Body $(ConvertTo-Json $CardIDs) -ContentType "application/json" 
    return $result.ReplyData
}