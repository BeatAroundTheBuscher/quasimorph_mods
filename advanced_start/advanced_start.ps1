function Backup-File {

    if ( [System.IO.File]::Exists($backupPath) )
    {
        $overwriteBackup = Read-Host "Do you want to overwrite your backup? (y to proceed, anything else to abort)"
        if ( $overwriteBackup -match "y" )
        {
            Write-Output "Overwriting backup in path $backupPath"
        }
        else
        {
            Write-Output "Not overwriting backup - Stopping here"
            exit
        }
    }
}


# There are odd values (f. ex. 127) for line length so maybe padding isn't needed after all
function Line-Padding-Alignment-4 {

    param (
        $line
    )

    Write-Output $line
    Write-Output $line.Length

}



$originalFileName = "resources.assets"
$csvFileName = "advanced_start.csv"

$originalFilePath = Join-Path $PWD $originalFileName
$csvFilePath = Join-Path $PWD $csvFileName

$backupPath = "$originalFilePath.bak"
# Backup-File
Write-Output "$originalFilePath"
Write-Output "$csvFilePath"



cp $originalFilePath $backupPath

# $content = [System.IO.File]::ReadAllBytes($originalFilePath)
# $content = [System.IO.File]::ReadAllLines($originalFilePath)

$streamReader = [System.IO.File]::OpenText($originalFilePath)
$streamReaderCSV = [System.IO.File]::OpenText($csvFilePath)
$lineFound = $false

while ( ($line = $streamReader.ReadLine()) -ne $null)
{
    if ( $lineFound -eq $false -and $line -match "InitialPower.*InitialTechLevel" )
    {
        $lineFound = $true
        $lineNumber = 0 # index start at 0
    }
    if ( $lineFound)
    {
        $csvLine = $streamReaderCSV.ReadLine()
        Write-Output "$csvLine"
        Write-Output "$line"
        # Line-Padding-Alignment-4 $line
        $lineNumber += 1
        Write-Output "$lineNumber"
    }
    if ( $lineFound -eq $true -and $line -match "#end" )
    {
        $lineFound = $false
        exit
    }

}




