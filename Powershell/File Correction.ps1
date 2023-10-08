$Directories = @{
    # Set File Paths for Documents containing invalid data
    NYCoS = ''
    FLCoS = ''
}

Function Edit-NYServiceFiles
{
    $FileList = Get-ChildItem $Directories.NYCoS -File 
    
    foreach($File in $FileList)
    {
        $csv = Import-Csv $File.FullName
        $csv | foreach `
        {
            if($_.Age -ne '' -and $null -ne $_.Age)
            {
                $_.Age = $_.Age.Split('-',2)[0] -Replace "[\D]",""
            }

            if($_.Weight -ne '' -and $null -ne $_.Weight)
            {
                $_.Weight = $_.Weight.Split('-',2)[0] -Replace "[\D]","" 
            }
        } 
        $csv | Export-Csv $File.FullName -NoTypeInformation -Force
    }
}

Function Edit-FLServiceFiles
{
    $FileList = Get-ChildItem $Directories.FLCoS -File 
    
    foreach($File in $FileList)
    {
        $csv = Import-Csv $File.FullName
        $csv | foreach `
        {
            if($_.Age -ne '' -and $null -ne $_.Age)
            {
                $_.Age = $_.Age.Split('-',2)[0] -Replace "[\D]",""
            }

            if($_.Weight -ne '' -and $null -ne $_.Weight)
            {
                $_.Weight = $_.Weight.Split('-',2)[0] -Replace "[\D]","" 
            }
        } 
        $csv | Export-Csv $File.FullName -NoTypeInformation -Force
    }
}
