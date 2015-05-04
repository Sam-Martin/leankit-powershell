function Get-LeanKitBoard{
    param(
        [parameter(mandatory=$true)]
        [int]$BoardID
    )

    if(!(Test-LeanKitAuthIsSet)){
        Set-LeanKitAuth
    }
    
    [string]$uri = $global:LeanKitURL + "/Kanban/Api/Boards/$boardID/"

    $Board = $(Invoke-RestMethod -Uri $uri  -Credential $global:LeanKitCreds).ReplyData

    # Add the custom type to each card to enable a default view
    $Board | %{$_.psobject.TypeNames.Insert(0, "PSLeanKit.Board")}
    $board.Lanes | %{$_.psobject.TypeNames.Insert(0, "PSLeanKit.Lane")}
    $board.Lanes.cards | %{$_.psobject.TypeNames.Insert(0, "PSLeanKit.Card")}
    $board.Archive | %{$_.psobject.TypeNames.Insert(0, "PSLeanKit.Card")}
    $board.Backlog.Cards | %{$_.psobject.TypeNames.Insert(0, "PSLeanKit.Card")}
    $board.CardTypes | %{$_.psobject.TypeNames.Insert(0, "PSLeanKit.CardType")}

    return $Board
}


<#
.SYNOPSIS
    Lists all boards you have access to in your account
#>

function Find-LeanKitBoard{

    if(!(Test-LeanKitAuthIsSet)){
        Set-LeanKitAuth
    }

    [string]$uri = $global:LeanKitURL + "/Kanban/Api/Boards/"
    return $(Invoke-RestMethod -Uri $uri  -Credential $global:LeanKitCreds).ReplyData
}

<#
.SYNOPSIS
    Gets all cards in a given board
#>
function Get-LeanKitCardsInBoard{
    param(
        # ID of the board to fetch cards from
        [parameter(mandatory=$true)]
        [int]$BoardID
    )

    $Board = Get-LeanKitBoard -BoardID $BoardID
    $Cards = $board.Lanes.cards + $board.Archive + $board.Backlog.Cards;
    # Add the custom type to each card to enable a default view
    $Cards | %{$_.psobject.TypeNames.Insert(0, "PSLeanKit.Card")}

    return $Cards
}
