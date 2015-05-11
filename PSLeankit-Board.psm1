function Get-LeanKitBoard{
    [CmdletBinding()]
    [OutputType([array])]
    param(
        [parameter(mandatory=$true)]
        [int]$BoardID
    )

    if(!(Test-LeanKitAuthIsSet)){
        Set-LeanKitAuth | Out-Null
    }
    
    [string]$private:uri = $global:LeanKitURL + "/Kanban/Api/Boards/$private:boardID/"

    $private:Board = $(Invoke-RestMethod -Uri $private:uri  -Credential $global:LeanKitCreds).ReplyData

    # Add the custom type to each card to enable a default view
    $private:Board | %{$_.psobject.TypeNames.Insert(0, "PSLeanKit.Board")}
    $private:Board.Lanes | %{$_.psobject.TypeNames.Insert(0, "PSLeanKit.Lane")}
    if($private:Board.Lanes.cards){
        $private:Board.Lanes.cards | %{$_.psobject.TypeNames.Insert(0, "PSLeanKit.Card")}
    }
    if($private:Board.Archive){
        $private:Board.Archive | %{$_.psobject.TypeNames.Insert(0, "PSLeanKit.Card")}
    }
    if($private:Board.Backlog.Cards){
        $private:Board.Backlog.Cards | %{$_.psobject.TypeNames.Insert(0, "PSLeanKit.Card")}
    }
    $private:Board.CardTypes | %{$_.psobject.TypeNames.Insert(0, "PSLeanKit.CardType")}

    return $private:Board
}


<#
.SYNOPSIS
    Lists all boards you have access to in your account
#>

function Find-LeanKitBoard{
    [CmdletBinding()]
    [OutputType([array])]
    param()

    if(!(Test-LeanKitAuthIsSet)){
        Set-LeanKitAuth | Out-Null
    }

    [string]$private:uri = $global:LeanKitURL + "/Kanban/Api/Boards/"
    return $(Invoke-RestMethod -Uri $private:uri  -Credential $global:LeanKitCreds).ReplyData
}

<#
.SYNOPSIS
    Gets all cards in a given board
#>
function Get-LeanKitCardsInBoard{
    [CmdletBinding()]
    [OutputType([array])]
    param(
        # ID of the board to fetch cards from
        [parameter(mandatory=$true)]
        [int]$BoardID
    )

    $private:Board = Get-LeanKitBoard -BoardID $private:BoardID
    $private:Cards = $private:Board.Lanes.cards + $private:Board.Archive + $private:Board.Backlog.Cards;
    # Add the custom type to each card to enable a default view
    $private:Cards | %{$_.psobject.TypeNames.Insert(0, "PSLeanKit.Card")}

    return [array]$private:Cards
}
