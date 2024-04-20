$DEBUG = 1

function Debug-Output {
    param (
        $line
    )

    if ( $DEBUG -eq 1 )
    {
        Write-Output "[DEBUG]`t$line"
    }
}

function Write-Part-For-Resources-Assets {
    param (
        $originalFileStream,
        $newFileStream,
        $startIndex,
        $bytesToWrite
    )
    
    $writeBuffer = New-Object byte[] $bytesToWrite
    $notUsed = $originalFileStream.Seek($startIndex, 'Begin') # shouldn't be necessary
    $notUsed = $originalFileStream.Read($writeBuffer, 0, $bytesToWrite)
    $newFileStream.Write($writeBuffer, 0, $bytesToWrite)
    Debug-Output "Writing modified faction part"
    Debug-Output "Start Index: $startIndex"
    Debug-Output "Bytes to Write: $bytesToWrite"
}

$originalFileName = "resources.assets"
# $csvFileName = "advanced_start.csv"
$csvFileName = "original_start_modified.csv"

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

    # Create new File
    Write-Output "Creating New File @ $newFilePath"
    Remove-Item -Path $newFilePath
    New-Item -Path $newFilePath > $null

    $newFileStream = [System.IO.File]::Open($newFilePath, 'Open', 'Write')
    $originalFileLength = $originalFileStream.Seek(0, 'End')
   
    # copy first unchanged part
    $startIndex = 0
    $bytesToWrite = $startIndices[1]
    Write-Part-For-Resources-Assets $originalFileStream $newFileStream $startIndex $bytesToWrite

    # copy changed part - factions
    $startIndex = $startIndices[1]

    $csvFile = Import-CSV -Path $csvFilePath -Delimiter ","
    $bytesToWrite = 0
    
    $csvText = "" # probably redundant # but helps with correct writeBuffer size

    foreach ( $row in $csvFile ) {
        if ( -not ($row -match "#end" ))
        {
            # quick and dirty
            $rowId = $row.Id
            $rowEnabled = $row.Enabled
            $rowInitialPower = $row.InitialPower
            $rowInitialTechLevel = $row.InitialTechLevel
            $rowInitialPlayerReputation = $row.InitialPlayerReputation
            $rowFactionType = $row.FactionType
            $rowAllianceType = $row.AllianceType
            $rowSpawnMissionChance = $row.SpawnMissionChance
            $rowStrategies = $row.Strategies
            $rowStrategyDurationMinHours = $row.StrategyDurationMinHours
            $rowStrategyDurationMaxHours = $row.StrategyDurationMaxHours
            $rowGuardCreatureId = $row.GuardCreatureId
            $rowAgentCreatureId = $row.AgentCreatureId
            $rowMinQmorphosWhenVictims = $row.MinQmorphosWhenVictims

            $rowOutput =  "$rowId`t`t$rowEnabled`t$rowInitialPower`t$rowInitialTechLevel`t$rowInitialPlayerReputation`t$rowFactionType`t$rowAllianceType`t$rowSpawnMissionChance`t$rowStrategies`t$rowStrategyDurationMinHours`t$rowStrategyDurationMaxHours`t$rowGuardCreatureId`t$rowAgentCreatureId`t$rowMinQmorphosWhenVictims`t`t`t`r`n"
            $csvText += $rowOutput
            $bytesToWrite += $rowOutput.Length
        }
    }

    $writeBuffer = New-Object byte[] $bytesToWrite
    # https://shellgeek.com/powershell-convert-string-to-byte-array/
    $csvText = [System.Text.Encoding]::UTF8.GetBytes($csvText)
    $writeBuffer += $csvText # probably redundant
 
    $newFileStream.Write($csvText, 0, $bytesToWrite)
    Debug-Output "Altered $bytesToWrite Bytes"

    # copy last unchange part modified with length from before
    $startIndex = $startIndices[-1]
    $bytesToWrite = $originalFileLength - $startIndex
    Write-Part-For-Resources-Assets $originalFileStream $newFileStream $startIndex $bytesToWrite

    $newFileStream.close()
    $originalFileStream.close()

    exit
}
else
{
    Write-Output "No bueno"
    exit
}


