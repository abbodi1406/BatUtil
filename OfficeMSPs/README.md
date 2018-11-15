# Organize Office MSP Updates

* Extract and prepare Office msp files from global exe update files, and rename them uniquely per KB number

* Mainly ment for Office 2010 to avoid confliction between neutral update and multilingual update for same product

## Variables:

- "EXEFOL" the path to parent office updates folder

- "MSPFOL" extracted MSP files path, default is 'MSPs' folder next to the script

- "LANG" the locale to be kept. Leaving it empty will keep all locales.

- "PROOFLANG" the companion [proofing languages](https://technet.microsoft.com/en-us/library/ee942198(office.14).aspx). Leaving it empty will only keep the above locale patch.

## Last Step

After the process is completed, manually delete msp files that have newer similar files (based on timestamps)

example:
z_word2010-kb2965313-x86.msp <- delete
z_word2010-kb3128034-x86.msp <- keep

## Credits:

[hearywarlot](https://forums.mydigitallife.net/threads/64028)
