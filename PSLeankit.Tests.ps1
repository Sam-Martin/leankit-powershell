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
        ($script:LeanKitBoard = Get-LeanKitBoard -BoardID $defaults.BoardID).Id | Should be $defaults.BoardID
    }

    It "Add-LeanKitCard works (and by extension Add-LeanKitCards and New-LeanKitCard)" {

        # Pick random values for this test
        $RandomLane = $LeanKitBoard.DefaultDropLaneID
        $RandomCardType = ($LeanKitBoard.CardTypes | Get-Random).Id
        $RandomUser = ($LeanKitBoard.BoardUsers | Get-Random).Id
        $RandomClassOfService = ($LeanKitBoard.ClassesOfService | Get-Random).Id

        # Add a card!
        $script:AddCardResult =  Add-LeanKitCard `
            -BoardID $defaults.BoardID `
            -LaneID  $RandomLane `
            -Title  "Test Card" `
            -Description  "Don't worry, only testing" `
            -TypeID  $RandomCardType `
            -Priority  1 `
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
        $AddCardResult.Priority | Should be 1
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
        $global:CardID = $AddCardResult.Id;
    }

    It "Get-Card works" {
        (Get-LeanKitCard -BoardID $defaults.BoardID -CardID $CardID).id | Should be $CardID
    }

    It "Update-LeanKitCard (and by extension Update-LeanKitCards) works" {
       # Pick random values for this test
        $RandomLane = $LeanKitBoard.DefaultDropLaneID
        $RandomCardType = ($LeanKitBoard.CardTypes | Get-Random).Id
        $RandomUser = ($LeanKitBoard.BoardUsers | Get-Random).Id
        $RandomClassOfService = ($LeanKitBoard.ClassesOfService | Get-Random).Id

        # Add a card!
        $script:UpdateCardResult =  Update-LeanKitCard -Verbose `
            -BoardID $defaults.BoardID `
            -LaneID  $RandomLane `
            -CardID $CardID `
            -Title  "Test Card - Updated" `
            -Description  "Don't worry, only testing - Updated" `
            -TypeID  $RandomCardType `
            -IsBlocked  $false `
            -BlockReason  "I'm waiting on a dependency :( - Updated" `
            -Index  0 `
            -StartDate  (Get-Date).AddDays(2) `
            -DueDate  (Get-Date).AddDays(8) `
            -ExternalSystemName  "Service Now - Updated" `
            -ExternalSystemUrl  "https://github.com/Sam-Martin/servicenow-powershell#Updated" `
            -Tags "Groovy,Awesome,Fabulous" `
            -ExternalCardID  "44" `
            -AssignedUserIDs $RandomUser `
            -ClassOfServiceID  $RandomClassOfService `
            -Priority  1

        $UpdateCardResult.UpdatedCardsCount | Should be 1
        $global:UpdatedCard =  Get-LeanKitCard -CardID $CardID -boardID $defaults.BoardID
        $UpdatedCard.Title | Should be "Test Card - Updated"
        $UpdatedCard.LaneID | Should be $RandomLane
        $UpdatedCard.Description | Should be "Don't worry, only testing - Updated"
        $UpdatedCard.TypeID | Should be $RandomCardType
        $UpdatedCard.Priority | Should be 1
        $UpdatedCard.IsBlocked | Should be $false
        $UpdatedCard.BlockReason | Should be "I'm waiting on a dependency :( - Updated"
        $UpdatedCard.Index | Should be 0
        $UpdatedCard.ExternalCardID | Should be 44
        $UpdatedCard.ExternalSystemName | Should be "Service Now - Updated"
        $UpdatedCard.ExternalSystemUrl | Should be "https://github.com/Sam-Martin/servicenow-powershell#Updated"
        $UpdatedCard.Tags | Should be "Groovy,Awesome,Fabulous"
        $UpdatedCard.ClassOfServiceID | Should be $RandomClassOfService
        $UpdatedCard.AssignedUserIDs | Should be @($RandomUser)
    }

    It "Remove-LeanKitCard works" {
        
        # Weirdly DeletedCardsCount is the board version rather the number of the cards deleted, so don't be surprised if it's a large number
        #(Remove-LeanKitCard -BoardID $defaults.BoardID -CardID $CardID).DeletedCardsCount | Should Match "\d?"
    }

    It "Get-LeanKitCardsInBoard works"{
        (Get-LeanKitCardsInBoard -BoardID $defaults.BoardID).Count -gt 0 | Should be $true
    }

    It "Remove-LeanKitAuth works"{
        Remove-LeanKitAuth | Should be $true
    }
}
