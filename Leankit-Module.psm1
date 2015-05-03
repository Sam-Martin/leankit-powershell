

function Set-LeanKitAuth{
    param(
        [parameter(mandatory=$true)]
        [string]$url,
        
        [parameter(mandatory=$true)]
        [System.Management.Automation.PSCredential]$credentials
    )
    $script:leanKitURL = 'https://' + $url;
    $script:leankitCreds = $credentials
    return $true;
}

function Get-LeanKitBoard{
    param(
        [parameter(mandatory=$true)]
        [int]$BoardID
    )

    if(!($script:leanKitURL -and $script:LeanKitCreds)){
        throw "You must run set-leankitauth first"
    }
    
    [string]$uri = $script:leanKitURL + "/Kanban/Api/Boards/$boardID/"
    return $(Invoke-RestMethod -Uri $uri  -Credential $script:leankitCreds).ReplyData
}

function Add-LeanKitCard{
    param(
        
        # ID of the board to which to add the card
        [parameter(mandatory=$true)]
        [int]$BoardID,

        # Title of the card
        [parameter(mandatory=$true)]
        [string]$Title,
        
        # Description of the card
        [parameter(mandatory=$true)]
        [string]$Description,

        # The ID of an external reference (e.g. a ticket) for this card
        [parameter(mandatory=$false)]
        [string]$ExternalCardID,
        
        # Identity of the type of card to be created
        [parameter(mandatory=$true)]
        [int]$CardTypeID,
        
        # ID of the lane to add the card to
        [parameter(mandatory=$true)]
        [int]$LaneID,

        # A comment to be added in case we're overriding the lane's Work in Process limit
        [parameter(mandatory=$true)]
        [string]$UserWipOverrideComment
    )

    $cardArray = @(@{
        Title = $Title;
        Description = $Description;
        TypeId=$CardTypeID;
        laneID=$LaneID;
        ExternalCardID=$ExternalCardID;
        UserWipOverrideComment = $UserWipOverrideComment;
    })


    return (Add-LeanKitCards -boardID $BoardID -cards $cardArray).ReplyData
}

function Add-LeanKitCards{

    param(
        [parameter(mandatory=$true)]
        [int]$boardID,

        [parameter(mandatory=$true)]
        [ValidateScript({
            if($_.length -gt 100){
                #"You cannot pass greater than 100 cards at a time to add-LeankitCards"
                return $false;
            }
           if(
                ($_ |?{$_.UserWipOverrideComment}).length -lt $_.length
               ){
                # "All cards must have UserWipOverrideComment when passing to Update-LeankitCards";
                return $false;
            }
            return $true;
        })]
        [hashtable[]]$cards
    )

    
    [string]$uri = $script:leanKitURL + "/Kanban/Api/Board/$boardID/AddCards?wipOverrideComment=Automation"
    return Invoke-RestMethod -Uri $uri -Credential $script:leankitCreds -Method Post -Body $(ConvertTo-Json $cards ) -ContentType "application/json" 

}

function Get-LeankitCard {
    param(
        # ID of the board in which the card we're getting resides
        [parameter(mandatory=$true)]
        [int]$boardID,

        # ID of the card we're getting
        [parameter(mandatory=$true)]
        [int]$CardID
    )
    [string]$uri = $script:leanKitURL + "/Kanban/Api/Board/$boardID/GetCard/$CardID"
    return $(Invoke-RestMethod -Uri $uri  -Credential $script:leankitCreds).ReplyData
}

function Update-LeankitCard {
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
    
    # Fetch the original card to amend
    $Card = Get-LeankitCard -BoardID $BoardID -CardID $CardID

    # Transform it into a hashtable
    $UpdatedCard = @{UserWipOverrideComment = "No override"};
    $Card | Get-Member | ?{$_.MemberType -eq "NoteProperty"} | %{$UpdatedCard.add($_.name, $Card.$($_.name))}

    # Update our params (I wish PowerShell had ternary operators...)
    $UpdatedCard.Title = if($Title){$Title}else{$Card.Title};

    return (Update-LeankitCards -BoardID $BoardID -Cards @($UpdatedCard))[0]
}

function Update-LeankitCards{
    
    param(
        [parameter(mandatory=$true)]
        [int]$boardID,

        [parameter(mandatory=$true)]
        [ValidateScript({
            if($_.length -gt 100){
                # "You cannot pass greater than 100 cards at a time to Update-LeankitCards"
                return $false;
            }
            if(
                ($_ |?{$_.UserWipOverrideComment}).length -lt $_.length
               ){
                # "All cards must have UserWipOverrideComment when passing to Update-LeankitCards";
                return $false;
            }
             if(
                ($_ |?{$_.ID}).length -lt $_.length
               ){
                # "All cards must have an ID when passing to Update-LeankitCards";
                return $false;
            }
            return $true;
        })]
        [hashtable[]]$cards
    )

    [string]$uri = $script:leanKitURL + "/Kanban/Api/Board/$boardID/UpdateCards?wipOverrideComment=Automation"
    $result = Invoke-RestMethod -Uri $uri  -Credential $script:leankitCreds -Method Post -Body $(ConvertTo-Json $cards) -ContentType "application/json" 
    return $result.ReplyData
}

function Remove-Card {
    param(
        # ID of the board in which the card we're deleting resides
        [parameter(mandatory=$true)]
        [int]$BoardID,

        # ID of the card we're deleting
        [parameter(mandatory=$true)]
        [int]$CardID
    )
    
    return Remove-Cards -BoardID $BoardID -CardIDs @($CardID)
}

function Remove-Cards {
    param(
        # ID of the board in which the cards we're deleting reside
        [parameter(mandatory=$true)]
        [int]$BoardID,

        # Array of card IDs to delete
        [parameter(mandatory=$true)]
        [int[]]$CardIDs
    )
    [string]$uri = $script:leanKitURL + "/Kanban/Api/Board/$boardID/DeleteCards/"
    $result = Invoke-RestMethod -Uri $uri  -Credential $script:leankitCreds -Method Post -Body $(ConvertTo-Json $CardIDs) -ContentType "application/json" 
    return $result.ReplyData
}