# PSLeankit  
[![GitHub release](https://img.shields.io/github/release/Sam-Martin/leankit-powershell.svg)](https://github.com/Sam-Martin/leankit-powershell/releases/latest) [![GitHub license](https://img.shields.io/github/license/Sam-Martin/leankit-powershell.svg)](LICENSE) ![Test Coverage](https://img.shields.io/badge/coverage-91%25-yellowgreen.svg)  
This PowerShell module provides a series of cmdlets for interacting with the [LeanKit REST API](https://support.leankit.com/hc/en-us/sections/200668393-LeanKit-API-Application-Programming-Interface-), performed by wrapping `Invoke-RestMethod` for the API calls.  
**IMPORTANT:** Neither this module, nor its creator are in any way affiliated with LeanKit, or LeanKit Inc.

## Requirements
Requires PowerShell 3.0 or above as this is when `Invoke-RestMethod` was introduced.

## Usage
Download the [latest release](https://github.com/Sam-Martin/leankit-powershell/releases/latest) and  extract the .psm1 and .psd1 files to your PowerShell profile directory (i.e. the `Modules` directory under wherever `$profile` points to in your PS console) and run:  
`Import-Module PSLeanKit`  
Once you've done this, all the cmdlets will be at your disposal, you can see a full list using `Get-Command -Module PSLeanKit`.

### Example - Creating a Card
```
# Setup our default authentication
Add-LeanKitProfile -url 'sammartintest.leankit.com'

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

## Authentication & Profiles  
As of version `0.2` PSLeanKit stores your credentials as encrypted strings in a JSON file in `$env:USERPROFILE` by default.  
You can change the location by passing `-ProfileLocation` to `Add-LeanKitProfile` when you execute it.  
Alternatively you can opt not to use profiles by instead passing the parameters `-URL` and `-Credential` to every parameter you call.

## Cmdlets
Singularly named cmdlets are wrappers of their plurally named counterparts with a simpler set of parameters. 
It is highly recommended that multiple commands of the same type are wrapped up into the more complex parameter set of the pluralised cmdlet for the sake of efficiency. (Otherwise an HTTP request will occur per item created/updated/deleted.)

* Add-LeanKitCard
* Add-LeanKitCards
* Add-LeanKitProfile
* Find-LeanKitBoard
* Get-LeanKitBoard
* Get-LeanKitCard
* Get-LeanKitCardsInBoard
* Get-LeanKitDateFormat
* Get-LeanKitProfile
* New-LeanKitCard
* Remove-LeankitAuth
* Remove-LeanKitCard
* Remove-LeanKitCards
* Remove-LeanKitProfile
* Set-LeankitAuth
* Test-LeanKitAuthIsSet
* Update-LeanKitCard
* Update-LeanKitCards


## Tests
This module comes with [Pester](https://github.com/pester/Pester/) tests for unit testing.
It is *strongly* recommended that you have a dedicated (free) LeanKit account to test against as these tests pick a random board and populate that.  
If it succeeds it will clean up after itself.

## Scope & Contributing
This module has been created as an abstraction layer to suit my immediate requirements. Contributions are gratefully received though!  
So please submit a pull request or raise an issue or both!
 

## Author
Author:: Sam Martin (<samjackmartin@gmail.com>)

