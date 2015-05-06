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
        $global:RandomLane = $LeanKitBoard.DefaultDropLaneID
        Write-Verbose "Picked Random Card Lane: $RandomLane"

        # Pick a random card type for future tests
        $global:RandomCardType = ($LeanKitBoard.CardTypes | Get-Random).Id
        Write-Verbose "Picked Random Card Type: $RandomCardType"

        # Pick a random user for future tests
        $global:RandomUser = ($LeanKitBoard.BoardUsers | Get-Random).Id
        
        # Pick a random class of service for future tests
        $global:RandomClassOfService = ($board.ClassesOfService | Get-Random).Id
    }

    It "Add-LeanKitCard works (and by extension Add-LeanKitCards and New-LeanKitCard)" {
        $script:AddCardResult =  Add-LeanKitCard `
            -BoardID $defaults.BoardID `
            -LaneID  $RandomLane `
            -Title  "Test Card" `
            -Description  "Don't worry, only testing" `
            -TypeID  $RandomCardType `
            -Priority  4 `
            -IsBlocked  $true `
            -BlockReason  "I'm waiting on a dependency :(" `
            -Index  0 `
            -StartDate  (Get-Date).AddDays(3) `
            -DueDate  (Get-Date).AddDays(7) `
            -ExternalSystemName  "Service Now" `
            -ExternalSystemUrl  "https://github.com/Sam-Martin/servicenow-powershell" `
            -Tags "Groovy,Awesome" `
            -ClassOfServiceID  $RandomClassOfService `
            -ExternalCardID  "22" `
            -AssignedUserIDs  $RandomUser

        $AddCardResult.Title | Should be "Test Card"
        $AddCardResult.LaneID | Should be $RandomLane
        $AddCardResult.Description | Should be "Don't worry, only testing"
        $AddCardResult.TypeID | Should be $RandomCardType
        $AddCardResult.Priority | Should be 4
        $AddCardResult.IsBlocked | Should be $true
        $AddCardResult.BlockReason | Should be "I'm waiting on a dependency :("
        $AddCardResult.Index | Should be 0
        $AddCardResult.ExternalCardID | Should be 22
        $AddCardResult.ExternalSystemName | Should be "Service Now"
        $AddCardResult.ExternalSystemUrl | Should be "https://github.com/Sam-Martin/servicenow-powershell"
        $AddCardResult.Tags | Should be "Groovy,Awesome"
        $AddCardResult.ClassOfServiceID | Should be $RandomClassOfService
        $AddCardResult.AssignedUserIDs | Should be @($RandomUser)

        # Save the card ID for our next test
        $script:CardID = $AddCardResult.Id;
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
