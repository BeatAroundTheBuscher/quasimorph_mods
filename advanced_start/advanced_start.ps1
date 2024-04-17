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
# $content.length


## Chat GPT


# Read the content of the file into an array of lines
$lines = Get-Content -Path $originalFilePath
$lines | Set-Content -Path $originalFilePath

exit

$lineFound = $false

$csvFile = Import-CSV -Path $csvFilePath -Delimiter ","
$currentLine = 0
foreach ($line in $lines)
{
    if ( $lineFound -eq $true -and $line -match "#end" )
    {
        $lineFound = $false
    }

    if ( $lineFound -eq $false -and $line -match "InitialPower.*InitialTechLevel" )
    {
        $lineFound = $true
        $lineNumber = 0 # index start at 0
    }
    elseif ( $lineFound)
    {
        $lineArray = $line -split '\t{1,}'
        $lineArray[2] = $csvFile[$lineNumber].InitialPower
        $lineArray[3] = $csvFile[$lineNumber].InitialTechLevel
        $newLine = $lineArray -join [char]0x09
        $lines[$currentLine] = $newLine
        $lineNumber += 1
    }

    $currentLine++
}

# Write the modified lines back to the file






