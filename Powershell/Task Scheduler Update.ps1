#Requires -RunAsAdministrator
$Verified = $false
$ErrorCount = 0

# Loop to Verify Credentials Are Valid 
while ($Verified -ne $true -and $ErrorCount -lt 5) 
{
    # Input Dialog for New Credentials
    $Credential = Get-Credential -Message "Please enter new credentials" -UserName $env:USERNAME
    $Root = "LDAP://" + ([ADSI]'').distinguishedName
    $Domain = New-Object System.DirectoryServices.DirectoryEntry($Root,$Credential.UserName,$Credential.GetNetworkCredential().Password)
    if ($null -ne $Domain.Name) 
    {
        $Verified = $true
    }
    else 
    {
        $ErrorCount++
    }
}
# If Error Count From Loop is Greater Than or Equal to 5 Kill Script
if ($ErrorCount -ge 5) 
{
    Write-Host -ForegroundColor Red -BackgroundColor Black "Valid Credentials Not Entered. Exiting Script"
    Start-Sleep -Seconds 5 
    Exit
}
# Remove Variables on Success 
Remove-Variable ErrorCount, Verified

$ServerList = @(
    # Input Servers Where Scheduled Tasks Are Located
)

# Selection of server where tasks are located
$ServerSelection = $ServerList | Out-GridView -Title "Server Selection" -PassThru

# List of Task Names to be Updated
$Tasks = Get-ScheduledTask -CimSession $ServerSelection | 
where {$_.Principal.userid -like $Credential.UserName -and $_.Principal.LogonType -eq "Password"} |
Select -ExpandProperty TaskName

# Loop to Update Tasks with new Credentials 
foreach($Task in $Tasks)
{
    # Get Path for Task
    $TaskPath = Get-ScheduledTask -TaskName $Task | select -ExpandProperty TaskPath
    # Update Task with Set-ScheduledTask
    Set-ScheduledTask -TaskPath $TaskPath -TaskName $Task -User $Credential.UserName -Password $Credential.GetNetworkCredential().Password | Out-Null
    # Write Something cuz why not
    Write-Host -ForegroundColor Green -BackgroundColor Black "$Task updated successfully"
    # Clear Task Path Variable for next use
    Clear-Variable TaskPath
}
# Remove Credential Variable at Completion 
Remove-Variable Credential, TaskPath, Task, Tasks, ServerSelection, ServerList