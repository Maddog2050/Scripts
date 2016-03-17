<#
	This script sets a users account so that the password is to expire as per MRG policy, 
	and resets the last password change date so that the user doesn't need login and change 
	their password straight away.
#>

# Define input parameters the script can accept.
param
(
	[Parameter(Mandatory=$True)]
	[string]$SearchBase,

	[Parameter(Mandatory=$True)]
	[string]$DNSDomainName,
	
	[Parameter(Mandatory=$True)]
	[string]$sAMAccountName,
	
	[bool]$Change = $False,

	[string]$LogFile = $MyInvocation.MyCommand.Name + ".log"
)

$Culture = Get-Culture
If ((Test-Path $Logfile) -eq $False)
{
	# Add headers to the LogFile if it doesn't already exist.
	Add-Content $LogFile "sAMAccountName, LastChange, Today, Changed"
}

# Get the user & properties from AD
$ADUser = Get-ADUser -Filter {sAMAccountName -eq $sAMAccountName} -SearchScope Subtree -SearchBase $SearchBase -Properties Name,pwdLastSet,PasswordNeverExpires -Server $DNSDomainName

# Check that user exist before going further.
If($ADUser -eq $Null)
{
	Write-Host "User not found. Aborting."
}
Else
{
	# Get the sAMAccountName from AD (Don't rely on the users input)
	$ADsAMAccountName = $ADUser.sAMAccountName

	# Get todays date and format it correctly.
	$Today = Get-Date -Format ($Culture.DateTimeFormat.FullDateTimePattern)

	# Get the date of the last password change and format it correctly.
	$LastChange = Get-Date -Date ([DateTime]::FromFileTime($ADUser.pwdLastSet)) -Format ($Culture.DateTimeFormat.FullDateTimePattern)

	If ($Change -eq $True)
	{
		# Set the password to expired, must be done first.
		$ADUser.pwdLastSet = 0
		# Set the account so that the password expires.
		$ADUser.PasswordNeverExpires = $False
		# Save the changes
		Set-ADUser -Instance $ADUser -Server $DNSDomainName

		# Reset the date of the last password change to today.
		$ADUser.pwdLastSet = -1
		# Save the changes
		Set-ADUser -Instance $ADUser -Server $DNSDomainName

		# Inform the user of the script that the account was changed.
		Write-Host "Account Changed."
	}

	# Log the change to the LogFile.
	Add-Content $LogFile "$ADsAMAccountName, $LastChange, $Today, $Change"
}