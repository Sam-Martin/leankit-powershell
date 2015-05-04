$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$DefaultsFile = "$here\PSLeanKit.Pester.Defaults.json"

# Load defaults from file (merging into $global:LeanKitPesterTestDefaults
if(Test-Path $DefaultsFile){
    $defaults = if($global:LeanKitPesterTestDefaults){$global:LeanKitPesterTestDefaults}else{@{}};
    (Get-Content $DefaultsFile | Out-String | ConvertFrom-Json).psobject.properties | %{$defaults."$($_.Name)" = $_.Value}
    
    # Prompt for credentials
    $defaults.Creds = if($defaults.Creds){$defaults.Creds}else{Get-Credential}

    $global:LeanKitPesterTestDefaults = $defaults
}else{
    Write-Error "$DefaultsFile does not exist. Created example file. Please populate with your values";
    
    # Write example file
    @{
        LeanKitURL = 'sammartintest.LeanKit.com'
        BoardID = 197340277
    } | ConvertTo-Json | Set-Content $DefaultsFile
    return;
}

Remove-Module PSLeanKit -ErrorAction SilentlyContinue
Import-Module $here\PSLeanKit.psd1
    

Describe "LeanKit-Module" {
    
    It "Set-LeanKitAuth works" {
        Set-LeanKitAuth -url $defaults.LeanKitURL -credentials $defaults.Creds | Should be $true
    }

    It "Find-LeanKitBoard works"{
        (Find-LeanKitBoard).count -gt 0 | Should be $true
    }

    It "Get-LeanKitBoard works" {
        ($LeanKitBoard = Get-LeanKitBoard -BoardID $defaults.BoardID).Id | Should be $defaults.BoardID
        
        # Pick a random lane for future tests
        $script:RandomLane = $LeanKitBoard.DefaultDropLaneID
        Write-Verbose "Picked Random Card Lane: $RandomLane"

        # Pick a random card type for future tests
        $script:RandomCardType = ($LeanKitBoard.CardTypes | Get-Random).Id
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
        (Get-LeanKitCard -BoardID $defaults.BoardID -CardID $CardID).id | Should be $CardID
    }

    It "Update-LeanKitCard (and by extension Update-LeanKitCards) works" {
        $result = Update-LeanKitCard -BoardID $defaults.BoardID -CardID $CardID -Title "Updated Test Card"

        $result.UpdatedCardsCount | Should be 1
    }

    It "Remove-LeanKitCard works" {
        
        # Weirdly DeletedCardsCount is the board version rather the number of the cards deleted, so don't be surprised if it's a large number
        (Remove-LeanKitCard -BoardID $defaults.BoardID -CardID $CardID).DeletedCardsCount | Should Match "\d?"
    }

    It "Get-LeanKitCardsInBoard works"{
        (Get-LeanKitCardsInBoard -BoardID $defaults.BoardID).Count -gt 0 | Should be $true
    }

    It "Remove-LeanKitAuth works"{
        Remove-LeanKitAuth | Should be $true
    }
}
