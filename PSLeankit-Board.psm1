function Get-LeanKitBoard{
    param(
        [parameter(mandatory=$true)]
        [int]$BoardID
    )

    if(!(Test-LeankitAuthIsSet)){
        Set-LeanKitAuth
    }
    
    [string]$uri = $global:leanKitURL + "/Kanban/Api/Boards/$boardID/"

    $Board = $(Invoke-RestMethod -Uri $uri  -Credential $global:leankitCreds).ReplyData

    # Add the custom type to each card to enable a default view
    $Board | %{$_.psobject.TypeNames.Insert(0, "PSLeankit.Board")}
    $board.Lanes | %{$_.psobject.TypeNames.Insert(0, "PSLeankit.Lane")}
    $board.Lanes.cards | %{$_.psobject.TypeNames.Insert(0, "PSLeankit.Card")}
    $board.Archive | %{$_.psobject.TypeNames.Insert(0, "PSLeankit.Card")}
    $board.Backlog.Cards | %{$_.psobject.TypeNames.Insert(0, "PSLeankit.Card")}
    $board.CardTypes | %{$_.psobject.TypeNames.Insert(0, "PSLeankit.CardType")}

    return $Board
}


<#
.SYNOPSIS
    Lists all boards you have access to in your account
#>

function Find-LeankitBoard{

    if(!(Test-LeankitAuthIsSet)){
        Set-LeanKitAuth
    }

    [string]$uri = $global:leanKitURL + "/Kanban/Api/Boards/"
    return $(Invoke-RestMethod -Uri $uri  -Credential $global:leankitCreds).ReplyData
}

<#
.SYNOPSIS
    Gets all cards in a given board
#>
function Get-LeankitCardsInBoard{
    param(
        # ID of the board to fetch cards from
        [parameter(mandatory=$true)]
        [int]$BoardID
    )

    $Board = Get-LeanKitBoard -BoardID $BoardID
    $Cards = $board.Lanes.cards + $board.Archive + $board.Backlog.Cards;
    # Add the custom type to each card to enable a default view
    $Cards | %{$_.psobject.TypeNames.Insert(0, "PSLeankit.Card")}

    return $Cards
}
