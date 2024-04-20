## WIP - Advanced Start

Start the game with higher power and tech level for the corporations

## How to Use

- Copy resources.assets into the same folder
- modify copy "original_start_modified.csv" to "advanced_start.csv" and change values. Make sure to pay attention to the limitations!
- Run
    - in Linux with `pwsh advanced_start.ps1`
    - in Windows with `ps  advanced_start.ps1`
- There should be a folder "new" in this folder now which contains a new resources.assets
- Make a backup of the original files!
- Copy that back to the game directory

## Limitations

- Due to the nature of the serialization the total length of the CSV file MUST NOT be longer. You can change to less symbols like from 800 to 0 but you cannot raise a value from single digit to multiple digit (unless you reduce digits elsewhere)