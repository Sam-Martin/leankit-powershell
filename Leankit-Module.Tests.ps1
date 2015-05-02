$here = Split-Path -Parent $MyInvocation.MyCommand.Path
#$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
#. "$here\$sut"

Remove-Module Leankit-Module -ErrorAction SilentlyContinue
Import-Module $here\Leankit-Module.psm1

$global:defaults = @{
    LeankitURL = 'sammartintest.leankit.com'
    BoardID = 197340277
    Creds = $(if($defaults.Creds){$defaults.Creds}else{Get-Credential})
}
    

Describe "Leankit-Module" {
    
    It "Set-LeanKitAuth works" {
        Set-LeanKitAuth -url $defaults.LeankitURL -credentials $defaults.Creds | Should be $true
    }

    It "Get-LeanKitBoard works" {
        ($LeankitBoard = Get-LeanKitBoard -BoardID $defaults.BoardID).Id | Should be $defaults.BoardID
        
        # Pick a random lane for future tests
        $script:RandomLane = ($LeankitBoard.Lanes | ?{$_.Type -eq 99} | Get-Random).Id
        Write-Verbose "Picked Random Card Lane: $RandomLane"

        # Pick a random card type for future tests
        $script:RandomCardType = ($LeankitBoard.CardTypes | Get-Random).Id
        Write-Verbose "Picked Random Card Type: $RandomCardType"
    }

    It "Add-LeanKitCard works (and by extension Add-LeanKitCards)" {
        $result = Add-LeanKitCard -boardID $defaults.BoardID -LaneID $RandomLane `
            -Title "Test Card" -Description "Testing!" -CardTypeID $RandomCardType `
            -UserWipOverrideComment "Don't worry, only testing!" 
        
        $result.Title | Should be "Test Card"

        # Save the card ID for our next test
        $script:CardID = $result.Id;
    }

    It "Get-Card works" {
        (Get-LeankitCard -BoardID $defaults.BoardID -CardID $CardID).id | Should be $CardID
    }

    It "Update-LeankitCard (and by extension Update-LeankitCards) works" {
        $result = Update-LeankitCard -BoardID $defaults.BoardID -CardID $CardID -Title "Updated Test Card"

        $result.UpdatedCardsCount | Should be 1
    }

    It "Remove-Card works" {
        
        # Weirdly DeletedCardsCount is the board version rather the number of the cards deleted, so don't be surprised if it's a large number
        (Remove-Card -BoardID $defaults.BoardID -CardID $CardID).DeletedCardsCount | Should Match "\d?"
    }
}