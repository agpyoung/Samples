$TaskServers = # Input Servers Where Scheduled Tasks are Run
$Path = # Input Report Path
$LogPath = # Input Log Path
if (!(Test-Path $LogPath)) 
{
    New-Item -ItemType Directory $LogPath
}

$Today = Get-Date
$LogName = $Today.ToString("MM.dd.yyyy")
$LogContents = @()

foreach($Server in $TaskServers)
{
    $Tasks = Get-ScheduledTask -CimSession $Server | 
    where `
    {
        $_.State -ne "Disabled" -and `
        $_.TaskPath -notlike "\Microsoft*" -and `
        $_.TaskPath -notlike "\Mozilla*" -and `
        $_.TaskName -notlike "*OneDrive*" -and`
        $_.TaskName -notlike "User_Feed_Synchronization*"
    } | Get-ScheduledTaskInfo | 
    where `
    {
        $_.NumberofMissedRuns -gt 0 -and `
        $_.NextRunTime.ToShortDateString() -ne $Today.ToShortDateString()
    } | select PSComputerName, TaskName, TaskPath, LastRunTime, NumberOfMissedRuns 

    if ($Tasks -ne "" -and $null -ne $Tasks) 
    {
        $Tasks | Export-Csv "$Path\$Server Tasks.csv" -NoTypeInformation
    }
}

cd $Path

$csvs = Get-ChildItem .\* -Include *.csv

$outputfilename = "Scheduled Task Report $(get-date -f MMddyyyy).xlsx" 
Write-Host Creating: $outputfilename
$excelapp = new-object -comobject Excel.Application
$excelapp.sheetsInNewWorkbook = $csvs.Count
$xlsx = $excelapp.Workbooks.Add()
$sheet = 1

foreach ($csv in $csvs)
{
    $row=1
    $column=1
    $worksheet = $xlsx.Worksheets.Item($sheet)
    $worksheet.Name = $csv.Name.TrimEnd(".csv")
    $file = (Get-Content $csv)
    foreach($line in $file)
    {
        $linecontents = $line -split ',(?!\s*\w+")'
        $linecontents = $linecontents.trim("`"")
        foreach($cell in $linecontents)
        {
            $worksheet.Cells.Item($row,$column) = $cell
            $column++
        }
        $column = 1
        $row++
    }
    $sheet++
}

$output = "$path\$outputfilename"
$xlsx.SaveAs($output)
$excelapp.quit()
$csvs | Remove-Item

Start-Sleep -Seconds 2

$EmailSettings = @{
    SMTP = # Input SMTP Address
    From = # Input Desired Outbound Address
    To = # Input Recipient
    Subject = "Automations That Have Not Run As Scheduled"
    Body = "Attached is the list of all automations that have not run as scheduled. Please review and run any automations that need manual intervention.`n`n
    This is an automated message. Do not reply"
    Attachment = $output
    Port = "25"
}

Send-MailMessage `
-SmtpServer $EmailSettings.SMTP `
-To $EmailSettings.To `
-From $EmailSettings.From `
-Subject $EmailSettings.Subject `
-Body $EmailSettings.Body `
-Attachments $EmailSettings.Attachment `
-Port $EmailSettings.Port