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
    

Describe "LeanKit-Module Using Explicit Credentials" {
    
    It "Get-LeanKitProfile returns null when provieded with an invalid profilename" {
        
        (Get-LeanKitProfile -ProfileName "65465798721asda213").URL -eq $null | Should be $true
    }
    
    It "Get-LeanKitDateFormat works"{
        $global:DateFormat = Get-LeanKitDateFormat -url $defaults.URL -credential $defaults.Credential
    }

    It "Find-LeanKitBoard works"{
        $script:LeanKitBoard = Find-LeanKitBoard -url $defaults.URL -credential $defaults.Credential | Get-Random
        $script:LeanKitBoard.ID -gt 0 | Should be $true
    }
    
    It "Get-LeanKitBoard works" {
        ($script:LeanKitBoard = Get-LeanKitBoard -BoardID $script:LeanKitBoard.ID -url $defaults.URL -credential $defaults.Credential).Id | Should be $script:LeanKitBoard.ID
    }
    
    
    It "Add-LeanKitCard works (and by extension Add-LeanKitCards and New-LeanKitCard)" {


        $private:params = @{
            url = $defaults.URL 
            credential = $defaults.Credential
            BoardID = $script:LeanKitBoard.ID
            LaneID =  $script:LeanKitBoard.DefaultDropLaneID 
            Title =  "Test Card" 
            Description =  "Don't worry, only testing" 
            TypeID =  ($script:LeanKitBoard.CardTypes | Get-Random).Id
            Priority =  1 
            IsBlocked =  $true 
            BlockReason =  "I'm waiting on a dependency :(" 
            Index =  0 
            StartDate =  (Get-Date).AddDays(3) 
            DueDate =  (Get-Date).AddDays(7) 
            Tags = "Groovy,Awesome"
            AssignedUserIDs =  ($script:LeanKitBoard.BoardUsers | Get-Random).Id
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
        $script:CardID = $AddCardResult.Id;
    }
    
    It "Get-Card works" {
        $private:params = @{
            BoardID = $script:LeanKitBoard.ID 
            CardID = $script:CardID 
            url = $defaults.URL 
            credential = $defaults.Credential
        }
        (Get-LeanKitCard @private:params).id | Should be $script:CardID
    }
   
    It "Update-LeanKitCard (and by extension Update-LeanKitCards) works" {
       
       $private:params = @{
            url = $defaults.URL 
            credential = $defaults.Credential
            CardID = $script:CardID
            BoardID = $script:LeanKitBoard.ID
            LaneID =  $script:LeanKitBoard.DefaultDropLaneID 
            Title =  "Test Card  - Updated" 
            Description =  "Don't worry, only testing - Updated" 
            TypeID =  ($script:LeanKitBoard.CardTypes | Get-Random).Id
            Priority =  2 
            IsBlocked =  $false 
            BlockReason =  "I'm waiting on a dependency :(  - Updated" 
            Index =  0 
            StartDate =  (Get-Date).AddDays(3) 
            DueDate =  (Get-Date).AddDays(7) 
            Tags = "Groovy,Awesome,Fabulous"
            AssignedUserIDs =  ($script:LeanKitBoard.BoardUsers | Get-Random).Id
        }
        $script:UpdateCardResult = Update-LeanKitCard @private:params
            

        $script:UpdateCardResult.UpdatedCardsCount | Should be 1
        
        # Fetch the card details and check it more fully
        $script:UpdatedCard =  Get-LeanKitCard -CardID $script:CardID -boardID $script:LeanKitBoard.ID -url $defaults.URL -credential $defaults.Credential
        $script:UpdatedCard.Title | Should be $private:params.Title
        $script:UpdatedCard.LaneID | Should be $private:params.LaneID
        $script:UpdatedCard.Description | Should be $private:params.Description
        $script:UpdatedCard.TypeID | Should be $private:params.TypeID
        $script:UpdatedCard.Priority | Should be $private:params.Priority
        $script:UpdatedCard.IsBlocked | Should be $private:params.IsBlocked
        $script:UpdatedCard.BlockReason | Should be $private:params.BlockReason
        $script:UpdatedCard.Index | Should be $private:params.Index
        $script:UpdatedCard.Tags | Should be $private:params.Tags
        $script:UpdatedCard.AssignedUserIDs | Should be $private:params.AssignedUserIDs
    }

    
    It "Remove-LeanKitCard works" {
        
        # Weirdly DeletedCardsCount is the board version rather the number of the cards deleted, so don't be surprised if it's a large number
        (Remove-LeanKitCard -BoardID $script:LeanKitBoard.ID -CardID $CardID -url $defaults.URL -credential $defaults.Credential).DeletedCardsCount | Should Match "\d?"
    }

    It "Get-LeanKitCardsInBoard works"{
        (Get-LeanKitCardsInBoard -BoardID $script:LeanKitBoard.ID -url $defaults.URL -credential $defaults.Credential).Count -gt 0 | Should be $true
    }

}


Describe "LeanKit-Module Using Named Profile Values" {
    
    It "Add-LeanKitProfile works" {
        $script:ProfileName = "PesterTesting"
        $private:ProfileResults = Add-LeanKitProfile -ProfileName $script:ProfileName -url $defaults.URL -credential $defaults.Credential -confirm:$false
        $private:ProfileResults.url | Should be $defaults.URL
    }

     It "Get-LeanKitProfile a value when provided with a valid profilename" {
        
        (Get-LeanKitProfile -ProfileName $script:ProfileName).URL -eq  $defaults.URL | Should be $true
    }
    
    It "Get-LeanKitDateFormat works"{
        ($global:DateFormat = Get-LeanKitDateFormat -ProfileName $script:ProfileName) | Should be $true
        
    }
    
    It "Find-LeanKitBoard works"{
        $script:LeanKitBoard = Find-LeanKitBoard -ProfileName $script:ProfileName | Get-Random
        $script:LeanKitBoard.ID -gt 0 | Should be $true
    }
    
    It "Get-LeanKitBoard works" {
        ($script:LeanKitBoard = Get-LeanKitBoard -BoardID $script:LeanKitBoard.ID -ProfileName $script:ProfileName).Id | Should be $script:LeanKitBoard.ID
    } 

    It "Add-LeanKitCard works (and by extension Add-LeanKitCards and New-LeanKitCard)" {


        $private:params = @{
            ProfileName = $script:ProfileName
            BoardID = $script:LeanKitBoard.ID
            LaneID =  $script:LeanKitBoard.DefaultDropLaneID 
            Title =  "Test Card" 
            Description =  "Don't worry, only testing" 
            TypeID =  ($script:LeanKitBoard.CardTypes | Get-Random).Id
            Priority =  1 
            IsBlocked =  $true 
            BlockReason =  "I'm waiting on a dependency :(" 
            Index =  0 
            StartDate =  (Get-Date).AddDays(3) 
            DueDate =  (Get-Date).AddDays(7) 
            Tags = "Groovy,Awesome"
            AssignedUserIDs =  ($script:LeanKitBoard.BoardUsers | Get-Random).Id
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
        $script:CardID = $AddCardResult.Id;
    }
    
    It "Get-Card works" {
        $private:params = @{
            BoardID = $script:LeanKitBoard.ID 
            CardID = $script:CardID 
            ProfileName = $script:ProfileName
        }
        (Get-LeanKitCard @private:params).id | Should be $script:CardID
    }
   
    It "Update-LeanKitCard (and by extension Update-LeanKitCards) works" {
       
       $private:params = @{
            ProfileName = $script:ProfileName
            CardID = $script:CardID
            BoardID = $script:LeanKitBoard.ID
            LaneID =  $script:LeanKitBoard.DefaultDropLaneID 
            Title =  "Test Card  - Updated" 
            Description =  "Don't worry, only testing - Updated" 
            TypeID =  ($script:LeanKitBoard.CardTypes | Get-Random).Id
            Priority =  2 
            IsBlocked =  $false 
            BlockReason =  "I'm waiting on a dependency :(  - Updated" 
            Index =  0 
            StartDate =  (Get-Date).AddDays(3) 
            DueDate =  (Get-Date).AddDays(7) 
            Tags = "Groovy,Awesome,Fabulous"
            AssignedUserIDs =  ($script:LeanKitBoard.BoardUsers | Get-Random).Id
        }
        $script:UpdateCardResult = Update-LeanKitCard @private:params
            

        $script:UpdateCardResult.UpdatedCardsCount | Should be 1
        
        # Fetch the card details and check it more fully
        $script:UpdatedCard =  Get-LeanKitCard -CardID $script:CardID -boardID $script:LeanKitBoard.ID -ProfileName $script:ProfileName
        $script:UpdatedCard.Title | Should be $private:params.Title
        $script:UpdatedCard.LaneID | Should be $private:params.LaneID
        $script:UpdatedCard.Description | Should be $private:params.Description
        $script:UpdatedCard.TypeID | Should be $private:params.TypeID
        $script:UpdatedCard.Priority | Should be $private:params.Priority
        $script:UpdatedCard.IsBlocked | Should be $private:params.IsBlocked
        $script:UpdatedCard.BlockReason | Should be $private:params.BlockReason
        $script:UpdatedCard.Index | Should be $private:params.Index
        $script:UpdatedCard.Tags | Should be $private:params.Tags
        $script:UpdatedCard.AssignedUserIDs | Should be $private:params.AssignedUserIDs
    }

    
    It "Remove-LeanKitCard works" {
        
        # Weirdly DeletedCardsCount is the board version rather the number of the cards deleted, so don't be surprised if it's a large number
        (Remove-LeanKitCard -BoardID $script:LeanKitBoard.ID -CardID $CardID -ProfileName $script:ProfileName).DeletedCardsCount | Should Match "\d?"
    }

    It "Get-LeanKitCardsInBoard works"{
        (Get-LeanKitCardsInBoard -BoardID $script:LeanKitBoard.ID -ProfileName $script:ProfileName).Count -gt 0 | Should be $true
    }

    It "Remove-LeanKitProfile works"{
        Remove-LeankitProfile -profilename $script:ProfileName -confirm:$false | Should be $true
    }
    
    <#  These are deprecated and will overwrite your default credentials. Uncomment if you really want to test
    It "Set-LeanKitAuth works" {
        Set-LeanKitAuth -url $defaults.URL -credential $defaults.Credential | Should be $true
    }
        
    It "Remove-LeanKitAuth works (just an alias of Remove-LeanKitProfile now)"{
        Remove-LeanKitAuth | Should be $true
    } #>
    
}