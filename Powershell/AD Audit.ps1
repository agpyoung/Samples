$ModulesRequired = @{
AD = "ActiveDirectory"
Excel = "ImportExcel"
}

If(!(Get-Module -ListAvailable -Name ImportExcel))
{
	Install-Module ImportExcel -SkipPublisherCheck
}

Foreach($Module in $ModulesRequired.Values)
{
	Import-Module $Module
}

$OULocations = @{
PCReviewOU = "OU=90\+ Days,OU=Computers,OU=TMP,DC=TMP,DC=local"
UserReviewOU = "OU=90\+ Days,OU=Users,OU=TMP,DC=TMP,DC=local"
RemotePCOU = "OU=Remote Workstations,OU=Computers,OU=TMP,DC=TMP,DC=local"
}

$today = Get-Date
$lastDay = [DateTime]::DaysInMonth($today.Year, $today.Month)
$Dates = @{
File = $today.ToString("MM.dd.yyyy")
ReportSelection = $today.Day.Equals($lastday)
Days90 = $today.AddDays(-90).ToShortDateString()
}

$ParentDirectory = "C:\Users\ayoung\Desktop\Audit Reports\AD Audit Reports" #Location in place for testing must be updated for deployment
$Directories = @{
PCDaily = "$ParentDirectory\Moved PC Reports\$($today.Year)\$($today.ToString("MM"))"
UserDaily = "$ParentDirectory\Moved User Reports\$($today.Year)\$($today.ToString("MM"))"
Monthly = "$ParentDirectory\Monthly Reports\$($today.Year)"
}

$EmailSettings = @{
SMTP = # Input SMTP Address
From = # Input Desired Outbound Address
To = # Input Recipient
CC = # Input Addtional Users or Group to notify
PCDailySubject = "PCs Moved for Review"
PCDailyBody = "Attached is the list of all PCs that were moved for review due to not being signed in for 90+ days."
PCDailyAttachment = "$($Directories.PCDaily)\Daily PC Move Report $($Dates.File).xlsx"
UserDailySubject = "User Accounts Moved for Review"
UserDailyBody = "Attached is the list of all Users that were moved for review due to not being signed in for 90+ days."
UserDailyAttachment = "$($Directories.UserDaily)\Daily User Move Report $($Dates.File).xlsx"
MonthlySubject = "Monthly Active Directory Audit Report"
MonthlyAttachment = "$($Directories.Monthly)\Monthly Report $($Dates.File).xlsx"
MonthlyBody = "Attached is the list of all Users and Computers that have not signed in for 90+ days."
Port = "25"
}

Foreach($Directory in $Directories.Values)
{
	If(!(Test-Path $Directory))
	{
		New-Item $Directory -ItemType Directory
	}

}

$Comps = Get-AdComputer -filter { DistinguishedName -notlike "*$($OULocations.PCDisabledOU)" -and DistinguishedName -notlike "*$($OULocations.RemotePCOU)" -and OperatingSystem -notlike "*Server*"} -Properties * |
where {$_.LastLogonDate -le $Dates.Days90} |
select Name, Enabled, LastLogonDate, OperatingSystem, OperatingSystemVersion, DistinguishedName

$Users = Get-ADUser -Filter {Enabled -eq $true -and DistinguishedName -notlike "*$($OULocations.UserReviewOU)"} -Properties * | 
where {$_.LastLogonDate -le $Dates.Days90} |
select Name, EmailAddress, LastLogonDate, DistinguishedName 

$CompsMoved = @()
$UsersMoved = @()

Foreach( $Comp in $Comps )
{
	#Disable-ADAccount $Comp.DistinguishedName #Not Approved to auto disable at this time
	$CompsMoved += $Comp 
	Move-ADObject $Comp.DistinguishedName -TargetPath $OULocations.PCReviewOU
}

Foreach( $User in $Users )
{
	#Disable-ADAccount $User.DistinguishedName #Not Approved to auto disable at this time
	$UsersMoved += $User 
	Move-ADObject $User.DistinguishedName -TargetPath $OULocations.UserReviewOU
}

If(!([string]::IsNullOrWhitespace($CompsMoved)))
{
	$CompsMoved | 
	select Name, Enabled, LastLogonDate, OperatingSystem, OperatingSystemVersion | 
	sort OperatingSystem, OperatingSystemVersion | 
	Export-Excel $EmailSettings.PCDailyAttachment -AutoSize -WorksheetName "PCList" -FreezeTopRow
	
	Send-MailMessage `
	-SmtpServer $EmailSettings.SMTP `
	-To $EmailSettings.To `
	-From $EmailSettings.From `
	-Subject $EmailSettings.PCDailySubject `
	-Body $EmailSettings.PCDailySubject `
	-Attachments $EmailSettings.PCDailyAttachment `
	-Port $EmailSettings.Port
}

If(!([string]::IsNullOrWhitespace($UsersMoved)))
{
	$UsersMoved | 
	select Name, EmailAddress, LastLogonDate | 
	sort Name |
	Export-Excel $EmailSettings.PCDailyAttachment -AutoSize -WorksheetName "PCList" -FreezeTopRow
	
	Send-MailMessage `
	-SmtpServer $EmailSettings.SMTP `
	-To $EmailSettings.To `
	-From $EmailSettings.From `
	-Subject $EmailSettings.UserDailySubject `
	-Body $EmailSettings.UserDailySubject `
	-Attachments $EmailSettings.UserDailyAttachment `
	-Port $EmailSettings.Port
}

If($Dates.ReportSelection -eq $true)
{
	Get-ADComputer -SearchBase "$($OULocations.PCReviewOU)" -Filter * -Properties * | 
	select Name, Enabled, LastLogonDate, OperatingSystem, OperatingSystemVersion | 
	sort OperatingSystem, OperatingSystemVersion | 
	Export-Excel $EmailSettings.MonthlyAttachment -AutoSize -WorksheetName "PC List" -FreezeTopRow 

	Get-ADUser -SearchBase "$($OULocations.UserReviewOU)" -Filter * -Properties * | 
	select Name, EmailAddress, LastLogonDate | 
	sort Name |
	Export-Excel $EmailSettings.MonthlyAttachment -AutoSize -WorksheetName "User List" -FreezeTopRow 

	Send-MailMessage `
	-SmtpServer $EmailSettings.SMTP `
	-To $EmailSettings.To `
	-CC $EmailSettings.CC `
	-From $EmailSettings.From `
	-Subject $EmailSettings.MonthlySubject `
	-Body $EmailSettings.MonthlyBody `
	-Attachments $EmailSettings.MonthlyAttachment `
	-Port $EmailSettings.Port
}