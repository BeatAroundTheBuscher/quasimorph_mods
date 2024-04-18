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


$originalFileName = "resources.assets"
$csvFileName = "advanced_start.csv"

$originalFilePath = Join-Path $PWD $originalFileName
$csvFilePath = Join-Path $PWD $csvFileName

$backupPath = "$originalFilePath.bak"

# Backup-File

Write-Output "$originalFilePath"
Write-Output "$csvFilePath"

cp $originalFilePath $backupPath


$fileContent = Get-Content -Raw -Path $originalFilePath

# 11801008 # nail	Enabled	# 0xb411b0 but should start at b411bd 
# it's possible that pattern matching is only 16 bytes accurate

# 11026072 = 0xA83E98 but should be 0xB41280 - difference is 0xBD3E8 = 775144
$searchPattern = 'MinQmorphosWhenVictims' 

$match = [regex]::Match($fileContent, $searchPattern)



if ($match.Success) {
    # Get the index of the match within the file content
    $matchIndex = $match.Index + 775144 # no clue why this offset is necessary

    $fileStream = [System.IO.File]::Open($originalFilePath, 'Open', 'ReadWrite')
    $fileStream.Seek($matchIndex, 'Begin')

    $bytesToRead = 30
    $bytesRead = @()

    $startIndices = @()
    $startIndices += $matchIndex + $i + 1
    # we will ignore the first and last index
    # the first one is part of the pattern matching + offset
    # each next entry will be the starting line of each faction
    # the last one will be #end

    # find factions after column name row (past \x0A which is \n)
    # as well as after each new line \x0A
    do 
    {
        # start with previous index
        $factionStart = $startIndices[-1] 
        $fileStream.Seek($factionStart, 'Begin')
        $bytesToRead = 150 # longest line is 145
        $buffer = New-Object byte[] $bytesToRead
        $bytesReadInThisIteration = $fileStream.Read($buffer, 0, $bytesToRead)

        # find \x0A
        for ( ($i = 0); $i -lt $bytesToRead; $i++  )
        {
            $hexValue = [System.BitConverter]::ToString($buffer[$i]) -replace '-', ' '

            if ( $hexValue -match "0A")
            {
                Write-Output "Found \newline @ $i"
                break # don't need to finish for loop, when we found what we were looking for
            }
        }
        # turn the buffer into a string for the while condition
        $testbuffer = [System.Text.Encoding]::UTF8.GetString($buffer)
        $testbuffer

        # next faction index
        $startIndices += $factionStart + $i + 1

    } while (-not ($testbuffer -match "end"))


    for ( ($i = 1); $i -lt $startIndices.Length-1; $i++  )
    {
        $fileStream.Seek($startIndices[$i], 'Begin')
        $bytesToRead = $startIndices[$i+1] - $startIndices[$i]
        $buffer = New-Object byte[] $bytesToRead
        $bytesReadInThisIteration = $fileStream.Read($buffer, 0, $bytesToRead)
        # $buffer
        $hexString = [System.BitConverter]::ToString($buffer)
        $hexString
        $testbuffer = [System.Text.Encoding]::UTF8.GetString($buffer)
        $testbuffer
    }

    exit


    while ($bytesRead.Count -lt $bytesToRead) {
        # Calculate the remaining bytes to read
        $remainingBytes = $bytesToRead - $bytesRead.Count
        
        # Create a byte array to store the bytes read in this iteration
        $buffer = New-Object byte[] $remainingBytes

        # Read bytes from the file into the buffer
        $bytesReadInThisIteration = $fileStream.Read($buffer, 0, $remainingBytes)

        # Check if any bytes were read in this iteration
        if ($bytesReadInThisIteration -eq 0) {
            # End of file reached or no bytes available
            break
        }

        # Append the bytes read in this iteration to the array of bytes read
        $bytesRead += $buffer[0..($bytesReadInThisIteration - 1)]
        $hexString = [System.BitConverter]::ToString($buffer) -replace '-', ' '
        $bytesRead.Length
        $hexString
    }

    

    # $Mybytes = [byte[]]
    # $fileStream.ReadExactly($MyBytes, $matchIndex, 10)
    # $MyBytes
}
else
{
    Write-Output "No bueno"
    exit
}


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






