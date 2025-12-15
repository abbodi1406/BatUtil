# Office 2007 Updates Downloader

## Info

- Download and arrange Office 2007 updates files with meaningful names from Windows Update links

- Alternative for the global exe files which are removed from Microsoft Download Center

- Advantage over the global exe files: shared msp files are downloaded only once

## Lists Details

* `SP3_*.txt` provide Service Pack 3 files, per product

- `SP3_Office_*.txt` is for regular Office suites and Applications, except Project/Visio/SharePointDesigner

- For each `SP3_*.txt` product list:  
if you need one or more languages, use its specific language list, one by one
if you want all languages, use All.txt list

- Exception: SP3-Extras lists (addons) only have All.txt list  
if you don't need all languages files, edit its All.txt and delete unwanted langs before download

* `Updates_*.txt` provide post-SP3 updates files

- `Updates_important_All.txt` provide all required updates, regardless languages  
==this is a mandatory list==

- `Updates_optional_*.txt` provide optional updates (for Help Topics)  
if you need one or more languages, use its specific language list, one by one  
if you want all languages, use optional_All.txt list

## Requirements

- Download aria2c.exe if not present  
https://aria2.github.io/

or

- Download curl.exe if not present  
https://skanthak.homepage.t-online.de/curl.html
https://curl.se/windows/

- Windows 11 / Windows 10 version 1803 and later already contain curl.exe

- Place aria2c.exe or curl.exe in the script current directory or system directories:  
```
C:\Windows
C:\Windows\System32
C:\Windows\SysWOW64
```

- Generally, aria2c is better, and provide more informative and prettier progress

## How To Use

- Extract the desired list text file(s) from zip files, depending on the chosen script:  
**Lists_aria2** or **Lists_curl**

- Drag and drop the desired list text file(s) on the chosen script:  
**Downloader_aria2.cmd** or **Downloader_curl.cmd**

- The files will be downloaded in the script current directory under ==Office2007== or ==Others2007== folders  
existing and shared files will be skipped and not redownloaded

- To control download options, edit the chosen script before running and change:

`speedLimit`:  
Limit the download speed (bandwidth) for all downloads

`parallel`: (aria2 only)  
Set the number of parallel (concurrent) downloads (example: 4 or 8 files together)

## Extract or Install MSPs

- To install updates for already installed Office 2007:  
copy `InstallerOfficeV16.cmd` to ==Office2007== folder and run

- To extract msp files for use with `_OfficeUpsourcer2007.cmd` or "Updates" folder of installation media:  
use `Extract_Msp_Office.cmd`

first, you need to edit the script and set the correct variables for desired langs  
or run the script from command prompt and use switches

Example:  
`Extract_Msp_Office.cmd -e "W:\Storage\Office2007" --dirOfMSP "E:\OfficeISO\Updates" -o "E:\OfficeISO\Updates\Old" -l "en-us" --ProofLang "fr-fr,es-es"`

## Special Thanks

@hearywarlot  
@mkuba50  
@Sajjo  
@heinoganda