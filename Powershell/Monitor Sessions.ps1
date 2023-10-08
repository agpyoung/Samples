#Requires -RunAsAdministrator
Do
{
    $wshell = New-Object -ComObject Wscript.Shell
    $Computers = Get-WmiObject -class Win32_ServerConnection | select -ExpandProperty ComputerName
    If($Computer -ne $null)
    {
        Foreach($Computer in $Computers)
        {
            $HostName = ([System.Net.Dns]::GetHostByAddress($Computer).HostName).Split('.')[0]
            $Button = $wshell.Popup("Would you like to reboot $HostName ?",30,"Information",4)
            If($Button -eq 6)
            {
                Shutdown -r -t 10 -f -m \\$Computer -c "Get Out!!!"
                $wshell.Popup("$HostName Has Been Rebooted",30,"Information",0)
            }
        }
    }
    Start-Sleep 60
}
While($c -eq $null)
Pause