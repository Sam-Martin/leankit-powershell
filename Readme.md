# PSLeankit  
[![GitHub release](https://img.shields.io/github/release/Toukakoukan/leankit-powershell.svg)](https://github.com/Toukakoukan/leankit-powershell/releases/latest) [![GitHub license](https://img.shields.io/github/license/Toukakoukan/leankit-powershell.svg)](LICENSE) ![Test Coverage](https://img.shields.io/badge/coverage-89%25-yellowgreen.svg)  
This PowerShell module provides a series of cmdlets for interacting with the [LeanKit REST API](https://support.leankit.com/hc/en-us/sections/200668393-LeanKit-API-Application-Programming-Interface-), performed by wrapping `Invoke-RestMethod` for the API calls.  
**IMPORTANT:** Neither this module, nor its creator are in any way affiliated with LeanKit, or LeanKit Inc.

## Requirements
Requires PowerShell 3.0 or above as this is when `Invoke-RestMethod` was introduced.

## Usage
Download the [latest release](releases/latest) and  extract the .psm1 and .psd1 files to your PowerShell profile directory (i.e. the `Modules` directory under wherever `$profile` points to in your PS console) and run:  
`Import-Module PSLeanKit`  
Once you've done this, all the cmdlets will be at your disposal, you can see a full list using `Get-Command -Module PSLeanKit`.

### Example - Creating a Card
```
# Setup our default authentication
Set-LeanKitAuth -url 'sammartintest.leankit.com'  

# Get a random board and its ID
$BoardID = (Find-LeanKitBoard | Get-Random).Id

# Get full board details
$Board = Get-LeanKitBoard -BoardID $BoardID

# Choose a random card type
$CardType = $Board.CardTypes | Get-Random  

# Get the default drop lane
$Lane = $board.DefaultDropLaneId

# Add the card!
Add-LeanKitCard -BoardID $Board.Id -Title "Test Card" -Description "Let's test!" -CardTypeID $CardType.Id -LaneID $Lane.Id
```

## Cmdlets
Singularly named cmdlets are wrappers of their plurally named counterparts with a simpler set of parameters. 
It is highly recommended that multiple commands of the same type are wrapped up into the more complex parameter set of the pluralised cmdlet for the sake of efficiency. (Otherwise an HTTP request will occur per item created/updated/deleted.)

* Add-LeanKitCard
* Add-LeanKitCards
* Find-LeanKitBoard
* Get-LeanKitBoard
* Get-LeanKitCard
* Get-LeanKitCardsInBoard
* Remove-LeanKitAuth
* Remove-LeanKitCard
* Remove-LeanKitCards
* Set-LeanKitAuth
* Test-LeankitAuthIsSet
* Update-LeanKitCard
* Update-LeanKitCards

## Tests
This module comes with [Pester](https://github.com/pester/Pester/) tests for unit testing.

## Scope & Contributing
This module has been created as an abstraction layer to suit my immediate requirements. Contributions are gratefully received though!  
So please submit a pull request or raise an issue or both!
 

## Author
Author:: Sam Martin (<samjackmartin@gmail.com>)

