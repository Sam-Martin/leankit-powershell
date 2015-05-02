# leankit-powershell
This PowerShell module provides a series of cmdlets for interacting with the [LeanKit REST API](https://support.leankit.com/hc/en-us/sections/200668393-LeanKit-API-Application-Programming-Interface-), performed by wrapping `Invoke-RestMethod` for the API calls.  
**IMPORTANT:** Neither this module, nor its creator are in any way affiliated with LeanKit, or LeanKit Inc.

## Requirements
Requires PowerShell 3.0 or above as this is when `Invoke-RestMethod` was introduced.

## Usage
Simply extract the .psm1 file to your PowerShell profile directory (i.e. the `Modules` directory under wherever `$profile` points to in your PS console) and run:  
`Import-Module Leankit-Module`  
Once you've done this, all the cmdlets will be at your disposal, you can see a full list using `Get-Command -Module Leankit-Module`.

### Example - Creating a Card
```
Import-Module Leankit-Module  
Set-LeanKitAuth -url 'sammartintest.leankit.com'  
$Board = Get-LeanKitBoard -BoardID 197340277  
$CardType = $Board.CardTypes | Get-Random  
$Lane = $board.Lanes | ?{$_.Type -eq 99} | Get-Random  
Add-LeanKitCard -BoardID 197340277 -Title "Test Card" -Description "Let's test!" -CardTypeID $CardType.Id -LaneID $Lane.Id -UserWipOverrideComment "Testing"  
```

## Cmdlets
Singularly named cmdlets are wrappers of their plurally named counterparts with a simpler set of parameters. 
It is highly recommended that multiple commands of the same type are wrapped up into the more complex parameter set of the pluralised cmdlet for the sake of efficiency. (Otherwise an HTTP request will occur per item created/updated/deleted)

* Add-LeanKitCard
* Add-LeanKitCards 
* Get-LeanKitBoard 
* Get-LeankitCard
* Remove-Card
* Remove-Cards
* Set-LeanKitAuth
* Update-LeankitCard
* Update-LeankitCards 

## Tests
This module comes with [Pester](https://github.com/pester/Pester/) tests for integration testing.

## Scope & Contributing
This module has been created as an abstraction layer to suit my immediate requirements. Contributions are gratefully received however, so please feel free to submit a pull request with additional features or amendments.

## Author
Author:: Sam Martin (<samjackmartin@gmail.com>)

