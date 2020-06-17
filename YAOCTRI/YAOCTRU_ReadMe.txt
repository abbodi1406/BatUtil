# Office Click To Run URL Generator

## Intro

* A command line script to generate download links for Office Click To Run installation source files

* Office C2R source files are universal, and contain all possible products, any SKU can be installed from the same source  
https://docs.microsoft.com/office365/troubleshoot/installation/product-ids-supported-office-deployment-click-to-run

* To install Office C2R, you can use third-party tools like YAOCTRI and OfficeRTool  
https://forums.mydigitallife.net/posts/1479890/  
https://forums.mydigitallife.net/posts/1125229/

or you can use the official Office Deployment Tool, which has some limitations  
for more info:  
https://docs.microsoft.com/deployoffice/overview-of-the-office-customization-tool-for-click-to-run  
https://docs.microsoft.com/deployoffice/overview-office-deployment-tool  
https://docs.microsoft.com/deployoffice/office2019/deploy

* The most recommended choices for download:  
Channel: 3. Current / Monthly  
Output : 1. Aria2 script

______________________________

## How To

* Run the script normally with a double-click

* Choose Office source from the listed 10 channels

* If the selected channel offers different builds per Windows OS, you will be prompt to choose one

* Choose desired Office Bitness (architecture)

* Choose a Language by entering its option number (for the first 9 languages, you can enter the number without leading zero 0)

* Choose Office source type to download: Full, Language Pack, or Proofing Tools

* Finally, choose the output type: 

1. Aria2 script (aria2c.exe)  
https://aria2.github.io/

2. Wget script (wget.exe)  
https://eternallybored.org/misc/wget/

3. cURL script (curl.exe)  
https://skanthak.homepage.t-online.de/curl.html
https://curl.haxx.se/windows/

Windows 10 version 1803 or later already contain curl.exe by default

4. Text file  
plain text file with links, to be used with any Download Manager program, or through the browser
additionally, an "arrange" batch file will be created to help to organize files in a proper hierarchy

______________________________

## Output Files

* Naming scheme: Version_Bitness_Lang_SourceType_Channel_OutputType

examples:  
16.0.11231.20174_x86x64_en-US_Monthly_plain.txt  
16.0.11414.20014_x86_ar-SA_Proofing_Insiders_aria2.bat  
16.0.11421.20006_x64_fr-FR_DogfoodDevMain_wget.bat  
16.0.11807.20000_x86_en-US_Insiders_curl.bat

* aria2c.exe, wget.exe or curl.exe must be placed next to the download scripts,  
or in the system path directories, C:\Windows or C:\Windows\System32

* Aria2, Wget and cURL scripts will properly download and arrange the files under "C2R_xxx" folder in the same directory they are executed in  
where xxx represent the channel name, for example: C2R_Monthly

* Aria2, Wget and cURL scripts allow limiting the download speed (bandwidth)  
to do so, edit the scripts prior downloading and change speedLimit

* Aria2 script allows changing the parallel (concurrent) downloads  
to do so, edit the script prior downloading and change set "parallel=1"

______________________________

## Channels Overview

* Frequent update channels:

1. Beta / Insider Fast

gets frequent updates with new features, improvements, and fixes as soon as possible  
it receives multiple builds per month

2. Current / Monthly Preview

formerly known as Insider Slow / Monthly Targeted / First Release for Current

gets new features and improvements at least once a month, in addition to important fixes as a preview for production  
it receives multiple builds per month

3. Current / Monthly

gets new features and quality fixes as soon as they are ready for production  
it can receive more than one build per month, as needed

* Business stable channels:

4. Monthly Enterprise

new channel since May 2020

gets new features/quality/security updates once a month  
it receives only one build a month, on the second Tuesday of the month (Patch Tuesday)

5. Semi-Annual Preview

formerly known as Semi-Annual Targeted / First Release for Business  
provides the same new features four months before Semi-Annual channel

gets new features updates twice a year (in March and September), in addition to quality/security updates once a month  
it receives only one build a month, on the second Tuesday of the month (Patch Tuesday)

6. Semi-Annual

formerly known as Broad / Deferred / Business

gets new features updates twice a year (in January and July), in addition to quality/security updates once a month  
it receives only one build a month, on the second Tuesday of the month (Patch Tuesday)

* Office 2019 Volume channels:

7. Perpetual2019 VL

the official update channel for volume licensed products of Office 2019 (although, it can work from any other channel)  
it only gets security and quality fixes once a month (Patch Tuesday)

8. Microsoft Perpetual

internal preview channel for Perpetual2019 VL channel

* Testing channels:

9. Microsoft Elite

the second most frequent channel for Office builds as soon as they are tested  
it mostly aligns with Beta channel and works as an internal preview for it

10. DevMain Channel

the most frequent channel for Office builds as soon as they are compiled, providing new features/improvements/fixes or even new bugs and issues

______________________________

## Available Builds Level

* Since the support for Windows 7 had ended on 2020-01-14, Office C2R on Windows 7 will only receive security updates until January 2023

* Because of that, almost all Office channels will offer a specific build targeted for Windows 7

* You cannot choose a build targeted for Windows 8.1 and 10, to be installed on Windows 7

* For more information:  
https://docs.microsoft.com/DeployOffice/windows-7-support

______________________________

## Proofing Tools

* Installing proofing tools require using Office Deployment Tool Setup.exe with simple configuration xml file

* The generator script will create this configuration file (one per architecture)

* When you execute downloading script (Aria2, Wget, or cURL), it will move the config file(s) into the downloaded "Office" folder

* Then, to install the proofing tools, run command prompt as administrator, and execute the following command as an example:  
Setup.exe /configure config_file.xml

replace config_file.xml with the complete path for the config file inside Office folder

______________________________

## Unattended Options

* Edit YAOCTRU.ini to change the options values and generate links automatically

or, delete YAOCTRU.ini and edit YAOCTRU_Generator.cmd script directly

- uLanguage

mandatory option, it must be specified to enable unattended mode

supported values:  
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

- uChannel

if not specified, "Monthly" will be used

supported values:  
InsiderFast  
MonthlyPreview  
Monthly  
MonthlyEnterprise  
SemiAnnualPreview  
SemiAnnual  
Perpetual2019  
MicrosoftLTSC  
MicrosoftElite  
DogfoodDevMain

- uLevel

if not specified, "Default" will be used

supported values:  
Default  
Win7

- uBitness

if not specified, "x86x64" will be used

supported values:  
x86  
x64  
x86x64

- uType

if not specified, "Full" will be used

supported values:  
Full  
Lang  
Proof

- uOutput

if not specified, "aria" will be used

supported values:  
aria  
wget  
curl  
text

______________________________

## Credits

* Creator       : @abbodi1406  
* Special Thanks: @ratzlefatz (OfficeRTool), @Windows_Addict