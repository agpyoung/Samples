#Requires -RunAsAdministrator
Import-Module SQLServer
$connectionString = # Input SQL Connection String
$Date = Get-Date

# Exception Directory Locations
$ExceptionDirectories = @{
    Testing = ''
    AffidavitOfOriginalCreditor = ''
}

# Processing Directory Locations
$ProcessingDirectories = @{
    Testing = ''
    AffidavitOfOriginalCreditor = ''
}

# Processed Directory Locations
$CompletedDirectories = @{
    Testing = ''
    AutoImage = ''
}

# Naming Conventions 
$Barcode = @{
    Testing = 'ON'
    FirstProcess = 'DB'
    AffidavitOfOriginalCreditor = 'ON'
}

# Check for duplicate files move duplicates to exception directory
Function Test-Duplicates
{
    $Duplicates = @()
    $FileNames = $Script:Files | foreach {$_.Name.Split(" _-")[0]}
    foreach($Name in $FileNames)
    {
        If(($FileNames -match $Name).count -gt 1)
        {
            Write-Host "Duplicate found for $Name"
            $Duplicates += $Files | where {$_.Name -like "$Name*" -and $Duplicates -notcontains $_}
        }
    }
    $Duplicate = $Duplicates | sort $_.LastWriteTime -Descending | select -First 1
    Move-Item $Duplicate.FullName $ExceptionDirectories.$Directory
    $Script:Files = $Files | Where {$_.Name -ne $Duplicate.Name}
}

# File renmaing process
Function Rename-Files
{
    #Set New Name Value
    $Script:NewName = "$($Barcode.$Directory)$(([string]$Results.ACCTNUM).PadLeft(10, '0')).pdf"
    # Rename File
    Rename-Item $File.FullName -NewName $NewName
    if($Test)
    {
        # Move File to Testing Move Location
        Move-Item "$($ProcessingDirectories.$Directory)\$NewName" -Destination $CompletedDirectories.Testing
    }
    else 
    {
        # Move File to Production Location
        Move-Item "$($ProcessingDirectories.$Directory)\$NewName" -Destination $CompletedDirectories.AutoImage
    }
}

# Main Process
Function Invoke-FileRename
{
    # Parameter to designate if testing
    param
    (
        [Parameter(Mandatory=$true)]
        [Bool[]]
        $Test
    )

    # Get list of files for processing
    $Script:Files = Get-ChildItem $ProcessingDirectories.$Directory -File | select Name, FullName, LastWriteTime
    Test-Duplicates

    # Loop through Network Numbers to get Account Number and rename Files
    Foreach ($File in $Files) 
    {
        # Convert file Name to Network Number
        $Script:Auxnum = $File | Foreach `
        {
            $_.Name.Split(" _-")[0]
        }

        # SQL Query to get account number for file based on Network Number in JST
        $Query = 
            "SELECT * FROM OPENQUERY(ADB,'
            SELECT 
            TRIM(ACCTNUM) [ACCTNUM],
            TRIM(AUXNUM) [AUXNUM]
            FROM AROOT
            WHERE 
            AUXNUM = ''$Auxnum''
            ')"

        # SQL Query Results
        $Script:Results = Invoke-Sqlcmd -query $Query -ConnectionString $connectionString -ErrorAction SilentlyContinue

        # If query returns results rename files
        IF($null -ne $Results)
        {
            Rename-Files
        }
        Else{ Write-Warning "No Results Returned" } # Output for verification 
    }
}

# Process init
Foreach($Directory in $ProcessingDirectories.Keys)
{
    # Verify exception directory exists if not create directory
    if (!(Test-Path $ExceptionDirectories.$Directory)) 
    {
        New-Item -ItemType Directory $ExceptionDirectories.$Directory
    }
    
    Invoke-FileRename -Test $true
}