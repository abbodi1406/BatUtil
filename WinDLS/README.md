# Windows Display Language Switcher

* A mostly automated script to install and change "Display Language" for Windows Editions (SKUs) that are not alllowed to have multiple languages by default

* Supports the following editions:
- Windows 10 Home Single Language
- Windows 8.1 Single Language
- Windows 8 Single Language
- Windows 7 SP1 Starter
- Windows 7 SP1 Starter N
- Windows 7 SP1 Home Basic
- Windows 7 SP1 Home Basic N
- Windows 7 SP1 Home Premium
- Windows 7 SP1 Home Premium N
- Windows 7 SP1 Professional
- Windows 7 SP1 Professional N

* Supports the following languages:

Arabic, Bulgarian, Chinese (Simplified), Chinese (Hong Kong S.A.R.), Chinese (Taiwan), Croatian,  
Czech, Danish, Dutch, English, English (United Kingdom), Estonian, Finnish, French, French (Canada),  
German, Greek, Hungarian, Italian, Japanese, Korean, Latvian, Lithuanian, Norwegian, Polish,  
Portuguese (Brazil), Portuguese (Portugal), Romanian, Russian, Serbian (Latin), Slovak, Slovenian,  
Spanish, Spanish (Mexico), Swedish, Thai, Turkish, Ukrainian

## How To Use:

* Get desired Language Pack matching operating system version and architecture (32bit or 64 bit), and put the file in "LangPack" folder  
for Windows 7, you can use the original EXE file, or manually converted CAB file  
for Windows 10, you can use LangPacks in .cab or .esd format

* Optional: Get Language Features On Demand Packs for Windows 10 if available, and put the files in "FOD" folder  
you can let Windows Update to install them later after changing the language

* Right-click on DisplayLanguageSwitcher.cmd and select "Run as administrator"

* After loading and showing Opetating System and detected Language Pack information, you will be prompted to continue to install new LangPack or exit

* You must restart the system to complete the language change

## Notes:

* If you later want to go back to original language or already installed multiple languages, run the script and you will be prompted to select one of detected languages to set as primary

* The script will not set or change the local language preferences:  
Formats, Location, Keyboards, language for non-unicode programs (system locale)

you can set them manually, before or after changing the display language:
- Windows 7     : "Region and Language" Control Panel
- Windows 8/8.1 : "Region", "Language" Control Panels
- Windows 10    : "Region", "Language" Control Panels, or Settings app

* It is recommended for Windows 8/8.1 to enable .NET Framework 3.5 feature before installing new language

* All files in "FOD" folder will be installed on Windows 10 without checking, make sure to download and place the correct files matching Windows 10 version and architecture

* To spare yourself the trouble, keep the work directory path short, do not use spaces and do not use non-ASCII characters. 
