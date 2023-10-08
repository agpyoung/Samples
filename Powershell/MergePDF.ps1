# Need to build PdfSharp solution in VS and copy dll to location
Add-Type -Path C:\PdfSharp.dll

$path = # Input File Location
$outputDirectory = "$path\Testing"
$PdfReader = [PdfSharp.Pdf.IO.PdfReader]
$PdfDocumentOpenMode = [PdfSharp.Pdf.IO.PdfDocumentOpenMode]
$items = Get-ChildItem $path *.pdf
$accounts = $items.Name.substring(0,6) | select -Unique
foreach($account in $accounts)
{
    $filename = "$outputDirectory\AP0000$account.pdf" # Set Name of Merged File
    $merged = New-Object PdfSharp.Pdf.PdfDocument
    $pagecount = 0
    foreach($item in $items)
    {
        if($item.Name.substring(0,6) -eq $account)
        {
            $file = New-Object PdfSharp.Pdf.PdfDocument
            $file = $PdfReader::Open($item.fullname, $PdfDocumentOpenMode::Import)
            for ($i = 0; $i -lt $file.PageCount; $i++)
            {
                $merged.AddPage($file.Pages[$i]) | Out-Null
                $pagecount++
            }
        }
    }
    If($merged.PageCount -ne $pagecount)
    {
        Write-Host "$filename Missing Pages"
    }
    $merged.Save($filename)
}