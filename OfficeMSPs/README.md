# Organize Office MSP Updates

* Extract and prepare Office msp files from global exe/cab update files to a folder with meaningful names.

* The MSP files will be renamed with prefix `Y_` or `Z_` followed by the package name, KB ID, Arch and MSP file name.

## Variables:

- `dirOfEXE` the path to parent office updates folder

- `dirOfMSP` extracted MSP files path, default is **MSPs** folder next to the script

- `OldMSPdir` Folder to move old MSP versions, default is **OLD** inside dirOfMSP.

- `langOfMSP` language files to keep. Leaving it **empty** will keep all langs.

- `ProofLang` comma separated companion proofing languages. Leaving it **empty** will keep all proof msp files.

## Companion proofing languages

- [Office 2010](https://technet.microsoft.com/en-us/library/ee942198(office.14).aspx)
- [Office 2013](https://technet.microsoft.com/en-us/library/ee942198(office.15).aspx)
- Office 2016: Not needed, Proof msp update contain all languages

## Remark

After the process is completed, manually delete msp files that have newer similar files (based on timestamps)

## Credits:

[hearywarlot](https://forums.mydigitallife.net/threads/64028)
