$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$DefaultsFile = "$here\PSLeanKit.Pester.Defaults.json"

# Load defaults from file (merging into $global:LeanKitPesterTestDefaults
if(Test-Path $DefaultsFile){
    $defaults = if($global:LeanKitPesterTestDefaults){$global:LeanKitPesterTestDefaults}else{@{}};
    (Get-Content $DefaultsFile | Out-String | ConvertFrom-Json).psobject.properties | %{$defaults."$($_.Name)" = $_.Value}

    # Convert the credential property into a PSCredentials object
    $defaults.credential = New-Object System.Management.Automation.PSCredential -ArgumentList $ProfileValues.credential.username, $(ConvertTo-SecureString $ProfileValues.credential.password)

    $global:LeanKitPesterTestDefaults = $defaults
}else{
    Write-Error "$DefaultsFile does not exist. Please create a file with your testing values (copy a profile created by Initialize-LeanKitDefaults)";
    
    return;
}


Remove-Module PSLeanKit -ErrorAction SilentlyContinue
Import-Module $here\PSLeanKit.psd1
    

Describe "LeanKit-Module Using Explicit Profile Values" {
    <#
    # While deprecated we still want to see if it works
    It "Set-LeanKitAuth works" {
        Set-LeanKitAuth -url $defaults.URL -credential $defaults.Credential | Should be $true
    }
    #>
    
    It "Get-LeanKitProfile returns null when provieded with an invalid profilename" {
        
        (Get-LeanKitProfile -ProfileName "65465798721asda213").URL -eq $null | Should be $true
    }
    
    It "Find-LeanKitBoard works"{
        $script:LeanKitBoard = Find-LeanKitBoard -url $defaults.URL -credential $defaults.Credential | Get-Random
        $script:LeanKitBoard.ID -gt 0 | Should be $true
    }
    
    It "Get-LeanKitBoard works" {
        ($script:LeanKitBoard = Get-LeanKitBoard -BoardID $script:LeanKitBoard.ID -url $defaults.URL -credential $defaults.Credential).Id | Should be $script:LeanKitBoard.ID
    }
    
    <#
    It "Add-LeanKitCard works (and by extension Add-LeanKitCards and New-LeanKitCard)" {

        # Pick random values for this test
        $RandomLane = $script:LeanKitBoard.DefaultDropLaneID
        $RandomCardType = ($script:LeanKitBoard.CardTypes | Get-Random).Id
        $RandomUser = ($script:LeanKitBoard.BoardUsers | Get-Random).Id
        $RandomClassOfService = ($script:LeanKitBoard.ClassesOfService | Get-Random).Id

        $private:params = @{
            BoardID = $defaults.BoardID 
            LaneID =  $RandomLane 
            Title =  "Test Card" 
            Description =  "Don't worry, only testing" 
            TypeID =  $RandomCardType 
            Priority =  1 
            IsBlocked =  $true 
            BlockReason =  "I'm waiting on a dependency :(" 
            Index =  0 
            StartDate =  (Get-Date).AddDays(3) 
            DueDate =  (Get-Date).AddDays(7) 
            Tags = "Groovy,Awesome"
            AssignedUserIDs =  $RandomUser 
        }


        # Add a card!
        $script:AddCardResult =  Add-LeanKitCard @private:params

        # Check the results
        $AddCardResult.Title | Should be $private:params.Title
        $AddCardResult.LaneID | Should be $private:params.LaneID
        $AddCardResult.Description | Should be $private:params.Description
        $AddCardResult.TypeID | Should be $private:params.TypeID
        $AddCardResult.Priority | Should be $private:params.Priority
        $AddCardResult.IsBlocked | Should be $private:params.IsBlocked
        $AddCardResult.BlockReason | Should be $private:params.BlockReason
        $AddCardResult.Index | Should be $private:params.Index
        $AddCardResult.Tags | Should be $private:params.Tags
        $AddCardResult.AssignedUserIDs | Should be $private:params.AssignedUserIDs

        # Save the card ID for our next test
        $global:CardID = $AddCardResult.Id;
    }
    <#
    It "Get-Card works" {
        (Get-LeanKitCard -BoardID $defaults.BoardID -CardID $CardID).id | Should be $CardID
    }

    It "Update-LeanKitCard (and by extension Update-LeanKitCards) works" {
       # Pick random values for this test
        $RandomLane = $script:LeanKitBoard.DefaultDropLaneID
        $RandomCardType = ($script:LeanKitBoard.CardTypes | Get-Random).Id
        $RandomUser = ($script:LeanKitBoard.BoardUsers | Get-Random).Id
        $RandomClassOfService = ($script:LeanKitBoard.ClassesOfService | Get-Random).Id

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
            -Tags "Groovy,Awesome,Fabulous" `
            -AssignedUserIDs $RandomUser `
            -Priority  1 `
            

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

        $UpdatedCard.Tags | Should be "Groovy,Awesome,Fabulous"
        $UpdatedCard.AssignedUserIDs | Should be @($RandomUser)
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
    #>
}
