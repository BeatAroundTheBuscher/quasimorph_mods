## WIP - Advanced Start

Start the game with higher power and tech level for the corporations

## How to Use

- Move resources.assets into the same folder
- modify advanced_start.csv (For now only Column C - InitialPower and D - InitialTechLevel)
- Run
    - in Linux with `pwsh advanced_start.ps1`
    - in Windows with `ps  advanced_start.ps1`

## Limitations

- Due to the nature of the serialization the total length of the CSV file MUST NOT be longer. You can change to less symbols like from 800 to 0 but you cannot raise a value from single digit to multiple digit (unless you reduce digits elsewhere)