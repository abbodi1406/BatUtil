# Office Click To Run URL Generator

## Intro

* A command line script to generate download links for Office Click To Run installation source files

* Office C2R source files are universal, and contain all possible products, any SKU can be installed from the same source  
https://learn.microsoft.com/office365/troubleshoot/installation/product-ids-supported-office-deployment-click-to-run

* To install Office C2R, you can use third-party tools like YAOCTRI, OfficeRTool or Office Tool Plus

or you can use the official Office Deployment Tool, which has some limitations

for more info:  
https://learn.microsoft.com/deployoffice/overview-of-the-office-customization-tool-for-click-to-run  
https://learn.microsoft.com/deployoffice/overview-office-deployment-tool  
https://learn.microsoft.com/deployoffice/office2019/deploy  
https://learn.microsoft.com/deployoffice/ltsc2021/deploy
https://learn.microsoft.com/deployoffice/preview-ltsc2024/install-ltsc-preview

* The most recommended choices for download:  
==Channel:== 3. Current / Monthly  
==Output :== 1. Aria2 script

______________________________

## How To

* Run the script normally with a double-click

* Choose Office source from the listed channels

* If the selected channel offers different builds per Windows OS, you will be prompt to choose one

* Choose desired Office Bitness (architecture)

* Choose a Language by entering its option number (for the first 9 languages, you can enter the number without leading zero 0)

* Choose Office source type to download: Full, Language Pack, or Proofing Tools

* Finally, choose the output type: 

**1. Aria2 script (aria2c.exe)**  
https://aria2.github.io/

**2. Wget script (wget.exe)**  
https://eternallybored.org/misc/wget/

**3. cURL script (curl.exe)**  
https://skanthak.homepage.t-online.de/curl.html  
https://curl.se/windows/

Windows 11 and Windows 10 version 1803 or later already contain curl.exe by default

**4. Text file**  
plain text file with links, to be used with any Download Manager program, or through the browser
additionally, an "arrange" batch file will be created to help to organize files in a proper hierarchy

______________________________

## Output Files

* Naming scheme: Version_Bitness_Lang_SourceType_Channel_OutputType

examples:  
```
16.0.11231.20174_x86x64_en-US_Monthly_plain.txt  
16.0.11414.20014_x86_ar-SA_Proofing_Insiders_aria2.bat  
16.0.11421.20006_x64_fr-FR_DogfoodDevMain_wget.bat  
16.0.11807.20000_x86_en-US_Insiders_curl.bat
```

* aria2c.exe, wget.exe or curl.exe must be placed next to the download scripts,  
or in the system path directories, `C:\Windows` or `C:\Windows\System32`

* Aria2, Wget and cURL scripts will properly download and arrange the files under "C2R_xxx" folder in the same directory they are executed in  
where xxx represent the channel name, for example: `C2R_Monthly`

* Aria2, Wget and cURL scripts allow limiting the download speed (bandwidth)  
to do so, edit the scripts prior downloading and change speedLimit

* Aria2 script allows changing the parallel (concurrent) downloads  
to do so, edit the script prior downloading and change `set "parallel=1"`

______________________________

## Channels Overview

==* Frequent update channels:==

**1. Beta / Insider Fast**

gets frequent updates with new features, improvements, and fixes as soon as possible  
it receives multiple builds per month

**2. Current / Monthly Preview**

formerly known as Insider Slow / Monthly Targeted / First Release for Current

gets new features and improvements at least once a month, in addition to important fixes as a preview for production  
it receives multiple builds per month

**3. Current / Monthly**

gets new features and quality fixes as soon as they are ready for production  
it receives two or more builds per month, as needed

==* Business stable channels:==

**4. Monthly Enterprise**

new channel since May 2020

gets new features/quality/security updates once a month  
it receives only one build a month, on the second Tuesday of the month (Patch Tuesday)

**5. Semi-Annual Preview**

formerly known as Semi-Annual Targeted / First Release for Business  
provides the same new features 4 months before Semi-Annual channel

gets new features updates twice a year (in March and September), in addition to quality/security updates once a month  
it receives only one build a month, on the second Tuesday of the month (Patch Tuesday)

**6. Semi-Annual**

formerly known as Broad / Deferred / Business

gets new features updates twice a year (in January and July), in addition to quality/security updates once a month  
it receives only one build a month, on the second Tuesday of the month (Patch Tuesday)

==* Testing channels:==

**7. DevMain Channel**

the most frequent channel for Office builds as soon as they are compiled, providing new features/improvements/fixes and new bugs or issues

**8. Microsoft Elite**

the second most frequent channel for Office builds as soon as they are tested  
it mostly aligns with Beta channel and works as an internal preview for it

==* Office 2019 Volume channels:==

**9. Perpetual2019 VL**

the official update channel for volume licensed products of Office 2019  
it only gets security and quality fixes once a month (Patch Tuesday)

**10. Microsoft2019 VL**

internal preview channel for Perpetual2019 VL channel

==* Office 2021 Volume channels:==

**11. Perpetual2021 VL**

the official update channel for volume licensed products of Office 2021  
it only gets security and quality fixes once a month (Patch Tuesday)

**12. Microsoft2021 VL**

internal preview channel for Perpetual2021 VL channel

==* Office 2024 Volume channels:==

**11. Perpetual2024 VL**

the official update channel for volume licensed products of Office 2024  
it only gets security and quality fixes once a month (Patch Tuesday)

**12. Microsoft2024 VL**

internal preview channel for Perpetual2024 VL channel

______________________________

## Available Builds Level

* Official support for Windows 7/8.1 ended January 2023

* Because of that, most Office channels will offer a specific build targeted for Windows 7/8.1

* You cannot choose a build targeted for Windows 11/10 to be installed on Windows 7/8.1,  
or a build targeted for Windows 8.1 to be installed on Windows 7

* For more information:  
https://learn.microsoft.com/deployoffice/endofsupport/windows-7-support  
https://learn.microsoft.com/deployoffice/endofsupport/windows-81-support

______________________________

## Proofing Tools

* Installing proofing tools require using Office Deployment Tool Setup.exe with simple `configuration xml` file

* The generator script will create this configuration file (one per architecture)

* When you execute downloading script (Aria2, Wget, or cURL), it will move the config file(s) into the downloaded **"Office"** folder

* Then, to install the proofing tools, run command prompt as administrator, and execute the following command as an example:  
`Setup.exe /configure config_file.xml`

replace `config_file.xml` with the complete path for the config file inside `Office` folder

______________________________

## Unattended Options

* Edit `YAOCTRU.ini` to change the options values and generate links automatically

or, delete `YAOCTRU.ini` and edit `YAOCTRU_Generator.cmd` script directly

- uLanguage

mandatory option, it must be specified to enable unattended mode

supported values:  
```
en-US         fr-FR         nl-NL         th-TH  
ar-SA         he-IL         pl-PL         tr-TR  
bg-BG         hr-HR         pt-BR         uk-UA  
cs-CZ         hu-HU         pt-PT         zh-CN  
da-DK         it-IT         ro-RO         zh-TW  
de-DE         ja-JP         ru-RU         hi-IN  
el-GR         ko-KR         sk-SK         id-ID  
es-ES         lt-LT         sl-SI         kk-KZ  
et-EE         lv-LV         sr-Latn-RS    MS-MY  
fi-FI         nb-NO         sv-SE         vi-VN
```

Office 365/2021/2024 additionally support these languages since Version 2108 (Build 14326.20238):  
```
en-GB         es-MX         fr-CA
```

- uChannel

if not specified, "Monthly" will be used

supported values:  
```
InsiderFast
MonthlyPreview
Monthly
MonthlyEnterprise
SemiAnnualPreview
SemiAnnual
DogfoodDevMain
MicrosoftElite
PerpetualVL2019
MicrosoftLTSC
PerpetualVL2021
MicrosoftLTSC2021
PerpetualVL2024
MicrosoftLTSC2024
```

- uLevel

if not specified, "Default" will be used

supported values:  
```
Default  
Win81  
Win7
```

- uBitness

if not specified, "x86x64" will be used

supported values:  
```
x86  
x64  
x86x64
x86arm64
x64arm64
```

- uType

if not specified, "Full" will be used

supported values:  
```
Full  
Lang  
Proof
```

- uOutput

if not specified, "aria" will be used

supported values:  
```
aria  
wget  
curl  
text
```

______________________________

## Special Thanks

@ratzlefatz (OfficeRTool)  
@Windows_Addict