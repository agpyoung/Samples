#Requires -RunAsAdministrator

$connectionString = # Input SQL Connection String


$CSV = Import-Csv # Input CSV Location

$Results = @()
foreach( $Account in $CSV.<#Header#>)
{
    $Query = "
    select * from openquery
        (adb,
        '
        select 
        TRIM(aroot.acctnum) [Account Number]
        , (
            Select TOP 1
                IMAGEDEF.EFFECTDATE
            FROM 
                IMTYPE
            JOIN 
                IMAGEDEF on IMAGEDEF.PKIMTYPE = IMTYPE.PKIMTYPE
            WHERE 
                IMTYPE.CODE = ''SAT0''
                AND IMAGEDEF.PKAROOT = AROOT.PKAROOT
                ORDER BY IMAGEDEF.EFFECTDATE ASC
        ) [SAT0]
        , (
            Select TOP 1
                IMAGEDEF.EFFECTDATE
            FROM 
                IMTYPE
            JOIN 
                IMAGEDEF on IMAGEDEF.PKIMTYPE = IMTYPE.PKIMTYPE
            WHERE 
                IMTYPE.CODE = ''SAT1''
                AND IMAGEDEF.PKAROOT = AROOT.PKAROOT
                ORDER BY IMAGEDEF.EFFECTDATE ASC
        ) [SAT1]
        , (
            Select TOP 1
                IMAGEDEF.EFFECTDATE
            FROM 
                IMTYPE
            JOIN 
                IMAGEDEF on IMAGEDEF.PKIMTYPE = IMTYPE.PKIMTYPE
            WHERE 
                IMTYPE.CODE = ''SAT2''
                AND IMAGEDEF.PKAROOT = AROOT.PKAROOT
                ORDER BY IMAGEDEF.EFFECTDATE ASC
        ) [SAT2]
        FROM
        AROOT
        WHERE TRIM(ACCTNUM) = ''$($Account)''
        '
    )"
    $Results += Invoke-Sqlcmd -Query $Query -ConnectionString $connectionString 
} 
$Results | Export-Csv <# Input Export Location#> -NoTypeInformation -Force -NoClobber