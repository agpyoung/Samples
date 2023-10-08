Function Get-Folder()
{  
    [System.Reflection.Assembly]::LoadWithPartialName("system.windows.forms") |
    Out-Null

    $OpenFileDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $OpenFileDialog.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true })) | Out-Null
    $OpenFileDialog.SelectedPath
}

$path = Get-Folder
cd $path

$csvs = Get-ChildItem .\* -Include *.csv

Write-Host "Detected the following CSV files: ($($csvs.count))"
foreach ($csv in $csvs)
{
    Write-Host " "$csv.Name
}

$outputfilename = # Input Merged File Name
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
