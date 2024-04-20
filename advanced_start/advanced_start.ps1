$DEBUG = 1

function Debug-Output {
    param (
        $line
    )

    if ( $DEBUG -eq 1 )
    {
        Write-Output "[DEBUG]    $line"
    }
}

$originalFileName = "resources.assets"
$csvFileName = "advanced_start.csv"

$newPath = Join-Path $PWD "new"
mkdir $newPath 2> $null # don't show error
$originalFilePath = Join-Path $PWD $originalFileName
$newFilePath = Join-Path $newPath $originalFileName
$csvFilePath = Join-Path $PWD $csvFileName



$fileContent = Get-Content -Raw -Path $originalFilePath

# 11801008 # "nail	Enabled"	# 0xb411b0 but should start at b411bd 
# 11026072 = 0xA83E98 but should be 0xB41280 - difference is 0xBD3E8 = 775144
$searchPattern = 'MinQmorphosWhenVictims' 
$match = [regex]::Match($fileContent, $searchPattern)

if ($match.Success) {
    # Get the index of the match within the file content
    $matchIndex = $match.Index + 775144 # no clue why this offset is necessary

    $originalFileStream = [System.IO.File]::Open($originalFilePath, 'Open', 'Read')
    $notUsed = $originalFileStream.Seek($matchIndex, 'Begin')

    $bytesToRead = 30
    $bytesRead = @()

    $startIndices = @()
    $startIndices += $matchIndex + 1
    # we will ignore the first and last index
    # the first one is part of the pattern matching + offset
    # each next entry will be the starting line of each faction
    # the last one will be #end

    # find factions after column name row (past \x0A which is \n)
    # as well as after each new line \x0A
    do 
    {
        # start with previous index # startIndices is appended per faction line
        $factionStart = $startIndices[-1] 
        if ( $startIndices.Length -gt 1)
        {
            Debug-Output "New Faction Index is at $factionStart"
        }
        $notUsed = $originalFileStream.Seek($factionStart, 'Begin')
        $bytesToRead = 200 # longest line is 145 # lines may become longer
        $buffer = New-Object byte[] $bytesToRead
        # notused is only used to hide the resulting message
        $notUsed = $originalFileStream.Read($buffer, 0, $bytesToRead)


        # find \x0A
        if ( $DEBUG -eq 1)
        {
            for ( ($i = 0); $i -lt $bytesToRead; $i++  )
            {
                $hexValue = [System.BitConverter]::ToString($buffer[$i]) -replace '-', ' '

                if ( $hexValue -match "09")
                {
                    if ( $startIndices.Length -gt 1)
                    {
                        Debug-Output "    Found \tab @ $i"
                        $testBuffer = [System.Text.Encoding]::UTF8.GetString($buffer).SubString(0, $i)

                        Debug-Output "Faction is $testBuffer"
                    }
                    
                    break # don't need to finish for loop, when we found what we were looking for
                }
            }
        }

        # find \x0A
        for ( ($i = 0); $i -lt $bytesToRead; $i++  )
        {
            $hexValue = [System.BitConverter]::ToString($buffer[$i]) -replace '-', ' '

            if ( $hexValue -match "0A")
            {
                Debug-Output "    Found \newline @ $i"
                break # don't need to finish for loop, when we found what we were looking for
            }
        }
        # turn the buffer into a string for the while condition
        $testBuffer = [System.Text.Encoding]::UTF8.GetString($buffer)
        # $testBuffer

        # next faction index
        $startIndices += $factionStart + $i + 1

    } while (-not ($testBuffer -match "end"))
    
    $csvFile = Import-CSV -Path $csvFilePath -Delimiter "," > $null
    $currentLine = 1

    for ( ($i = 1); $i -lt $startIndices.Length-1; $i++  )
    {
        $notUsed = $originalFileStream.Seek($startIndices[$i], 'Begin')
        $bytesToRead = $startIndices[$i+1] - $startIndices[$i]
        $buffer = New-Object byte[] $bytesToRead
        $notUsed = $originalFileStream.Read($buffer, 0, $bytesToRead)
        # $buffer
        $hexString = [System.BitConverter]::ToString($buffer)
        # $hexString
        $testBuffer = [System.Text.Encoding]::UTF8.GetString($buffer)
        # $testBuffer
        # $csvFile[$currentLine].InitialTechLevel
        $currentLine++;
        
        # $originalFileStream.Write($buffer, 0, $bytesToRead)

        # find TRUE/FALSE \s \S+

        for ( ($j = 0); $j -lt $bytesToRead; $j++  )
        {
            $hexValue = [System.Text.Encoding]::UTF8.GetString($buffer).SubString($j, 5)

            if ( $hexValue -match "TRUE\t" -or $hexValue -match "FALSE")
            {
                Debug-Output "Found BOOL @ $j"

                if ( $hexValue -match "TRUE" ) # is shorter than FALSE for the search above
                {
                    $initialPowerIndex = $j+5
                }
                else
                {
                    $initialPowerIndex = $j+6
                }
                $rest = [System.Text.Encoding]::UTF8.GetString($buffer).SubString($initialPowerIndex)
                Write-Output "Start initialPowerIndex:"
                $rest

                break # don't need to finish for loop, when we found what we were looking for
            }
        }
        
    }

    Write-Output "Creating New File @ $newFilePath"
    Remove-Item -Path $newFilePath
    New-Item -Path $newFilePath > $null

    Debug-Output "Write till relevant part starts"

    
    $newFileStream = [System.IO.File]::Open($newFilePath, 'Open', 'Write')
    $originalFileLength = $originalFileStream.Seek(0, 'End')
   
    # copy first unchanged part
    $bytesToWrite = $startIndices[1]
    $writeBuffer = New-Object byte[] $bytesToWrite
    $originalFileStream.Seek(0, 'Begin')
    $notUsed = $originalFileStream.Read($writeBuffer, 0, $bytesToWrite)
    $newFileStream.Write($writeBuffer, 0, $bytesToWrite)

    # copy changed part
    $bytesToWrite = $startIndices[-1] - $startIndices[1]
    $writeBuffer = New-Object byte[] $bytesToWrite
    $originalFileStream.Seek($startIndices[1], 'Begin') # shouldn't be necessary
    $notUsed = $originalFileStream.Read($writeBuffer, 0, $bytesToWrite)
    $newFileStream.Write($writeBuffer, 0, $bytesToWrite)

    # copy last unchange part
    $bytesToWrite = $originalFileLength - $startIndices[-1]
    $writeBuffer = New-Object byte[] $bytesToWrite
    $originalFileStream.Seek($startIndices[-1], 'Begin')
    $notUsed = $originalFileStream.Read($writeBuffer, 0, $bytesToWrite)
    $newFileStream.Write($writeBuffer, 0, $bytesToWrite)

    $startIndices


    $newFileStream.close()
    $originalFileStream.close()

    exit



    while ($bytesRead.Count -lt $bytesToRead) {
        # Calculate the remaining bytes to read
        $remainingBytes = $bytesToRead - $bytesRead.Count
        
        # Create a byte array to store the bytes read in this iteration
        $buffer = New-Object byte[] $remainingBytes

        # Read bytes from the file into the buffer
        $bytesReadInThisIteration = $originalFileStream.Read($buffer, 0, $remainingBytes)

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


        



        # $lineArray[3] = $csvFile[$lineNumber].InitialTechLevel
    }

    


}
else
{
    Write-Output "No bueno"
    exit
}


exit

$lineFound = $false


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






