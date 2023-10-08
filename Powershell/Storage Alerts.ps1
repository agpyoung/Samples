$props = @(
    'PSComputerName'
    'DriveLetter'
    'FileSystemLabel'
    @{
        Name = 'SizeRemaining'
        Expression = { "{0:N2} Gb" -f ($_.SizeRemaining/ 1Gb) }
    }
    @{
        Name = 'Size'
        Expression = { "{0:N2} Gb" -f ($_.Size / 1Gb) }
    }
    @{
        Name = '% Free'
        Expression = { "{0:P}" -f ($_.SizeRemaining / $_.Size) }
    }
)

$Results = Get-ADComputer -Filter {OperatingSystem -like "*Server*"} | 
select -ExpandProperty Name | 
Foreach {Invoke-Command -ComputerName $_ -Command {Get-Volume | 
Where {$_.DriveLetter -ne $null -and $_.DriveType -eq "Fixed"}} -ErrorAction SilentlyContinue | 
select $props} | sort PSComputerName

$HTMLFormatting = foreach($Result in $Results)
{
    If([int]$Result.'% Free'.TrimEnd("%") -le [int]"10.00")
    {
        $Class = 'class="DarkRed"'
    }
    elseif ($Result.'% Free'.TrimEnd("%") -ge "10.00" -and $Result.'% Free'.TrimEnd("%") -le "20.00") 
    {
        $Class = 'class="Gold"'
    }
    else 
    {
        $Class = 'class="DarkGreen"'
    }
    "<tr $Class><td>$($Result.PSComputerName)</td><td>$($Result.DriveLetter)</td><td>$($Result.FileSystemLabel)</td><td>$($Result.SizeRemaining)</td><td>$($Result.Size)</td><td>$($Result.'% Free')</td></tr>"
    Clear-Variable Class
}

$HTML = @"
<head>
<style>
.content {
max-width: 700px;
margin: auto;
}
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: Darkblue;}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
.darkgreen {background-color: darkgreen;}
.gold {background-color: gold;}
.darkred {background-color: darkred;}
</style>
<title>Server Storage Status</title>
</head>
<body>
<div class="content">
<table>
<colgroup><col/><col/><col/><col/><col/><col/></colgroup>
<tr><th>PSComputerName</th><th>DriveLetter</th><th>FileSystemLabel</th><th>SizeRemaining</th><th>Size</th><th>% Free</th></tr>
$HTMLFormatting
</table>
</body></html>
"@

$EmailSettings = @{
    SMTP = # Input SMTP Address
    From = # Input Desired Outbound Address
    To = # Input Recipient
    Subject = "Weekly Storage Report"
    Body = $HTML
    Port = "25"
}

Send-MailMessage `
-SmtpServer $EmailSettings.SMTP `
-To $EmailSettings.To `
-From $EmailSettings.From `
-Subject $EmailSettings.Subject `
-BodyAsHtml $EmailSettings.Body `
-Priority High `
-Port $EmailSettings.Port
