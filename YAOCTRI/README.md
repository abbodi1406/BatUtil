# Yet Another Office Click-To-Run Installer

## Intro

* A mostly automated script(s) to install Office Click-to-Run from an offline source without using Office Deployment Tool (setup.exe), which allow bypassing ODT restrictions

* Support installing Product Suites or Single Apps individually

* Support installing multiple languages separately or together

* Support configuration options like the ones available with ODT, including:  
- Source Path  
- Excluding Apps  
- Update Channel  
- Miscellaneous Options (Display Level, Updates Enabled, Eula, Pin Icons, App Shutdown, Auto Activate)

* Includes a proper workaround with working updates to install Office 2021/2019 on Windows 8.1 or Office 2019 on Windows 7

* There are two flavors available of the scripts:

- YAOCTRI - Volume  
install volume products for Office 2024/2021/2019, in addition to Microsoft 365 Enterprise (O365ProPlus) and Office Mondo 2016

- YAOCTRIR - Retail  
install retail products for Microsoft 365 / Office 2024/2021/2019/2016 Suites, in addition to Office 2024/2021/2019 Single Apps

* Each flavor consist of two command scripts:

- Configurator.cmd  
the main script which is used to select products and installation options  
it also creates configuration ini files, with the ability to start the installation at the end  

- Installer.cmd  
the secondary script which is only used to execute the installation, depending on the already created the configuration ini file

* Office LTSC is a branding for the volume licensing of Office 2024/2021

* Project and Visio products are not available for the following languages by design:  
bg-BG, et-EE, hr-HR, lt-LT, lv-LV, sr-Latn-RS, th-TH, hi-IN, id-ID, kk-KZ, MS-MY, vi-VN, en-GB, es-MX, fr-CA

* Office C2R source files are universal, and contain all possible products, any SKU can be installed from the same source  
https://docs.microsoft.com/office365/troubleshoot/installation/product-ids-supported-office-deployment-click-to-run

* If you are using Office C2R for the first time or you are confused with the different products, the most recommended choices are:  
Product: Microsoft 365 Enterprise  
Channel: Current / Monthly

______________________________

## How To

* Run YAOCTRI_Configurator.cmd or YAOCTRIR_Configurator.cmd as administrator and follow the prompts

- For each menu, press the corresponding number or letter beside an option to change its state or proceed

- To exit at any menu press X (Version/Arch/Lang/Type menus have no return option, only proceed or exit)

- At first, enter the path for Office offline source

either the drive, directory or network share that contain "Office" folder (not Office folder path itself)

Configurator.cmd will auto detect the path for the drive letter of Office .img file (virtual mounted / dvd / usb)

if Configurator.cmd is placed inside "Office" folder, the path will be auto-detected

if Configurator.cmd is placed next to "Office" folder, the path will be auto-detected

- If multiple versions are detected in the source, you will be prompted to choose one

- If the current OS is x64, and multi-architecture Office 64-bit/32-bit is detected, you will be prompted to choose one

- If multiple languages are detected in the specified version, you will be prompted to choose one, or all

- If you chose all languages, you will be prompted to choose the primary language  
(which determines the setup and Office Shell UI culture, including shortcuts, right-click context menus, and tooltips)

- Select the installation type: complete product suites, or single apps separately

- If you selected a product suite, you will get a menu to exclude (turn OFF) unneeded apps

- Select the desired Update Channel

- Change the Miscellaneous Options to your needs

- In the end, you will have three options:

1. Install Now  
start normal installation now with the selected options (Config ini will be created too)

2. Create setup configuration (Normal Install)  
create Config ini file, to be used later with Installer.cmd

3. Create setup configuration (Auto Install)  
create Config ini file with the unattended option, which allow Installer.cmd to start the installation immediately

______________________________

## Remarks

* If Configurator.cmd runs from a read-only path (e.g. DVD or network share), Config ini file will be created on the Desktop

* When using Installer.cmd, if Office SourcePath does not exist, the script will try to auto-detect alternative path, similar to Configurator.cmd

* Installer.cmd script support command line switch /s or -s  
which in that case it perform the installation silently automatically, regardless the options in the Config ini file

* YAOCTRIR - Retail flavor is recommended only if you have actual retail key or subscription account

but you can still use it to install Retail SKUs, then use C2R-R2V to convert licensing to volume

* The workaround to install Office 2021/2019 on Windows 8.1/7 requires installing corresponding Office 2016 products, and corresponding Office 2021/2019 licenses

therefore, the underlying Product IDs and entries in "Program and Features" will be always Office 2016, but Office 2021/2019 licenses will determine the features

* For YAOCTRI - Volume flavor, if the source files are from Volume LTSC channels, only those channels will available for selection

* For YAOCTRI - Volume flavor, if you choose "Microsoft 365 Enterprise" along with Project and/or Visio,

Mondo licenses used for volume conversion will take precedence over Project/Visio licenses (this is a limitation in Office itself, not the script)

a better choice would be to select Mondo directly, which include Project/Visio

* For "Microsoft 365" suites, Disable Telemetry option will not disable "connected experiences" policies  
https://learn.microsoft.com/deployoffice/privacy/manage-privacy-controls

* Auto Activate option has no effect in YAOCTRIR - Retail flavor

* Auto Activate option in YAOCTRI - Volume flavor will work only in these scenarios:

- on Windows 11, 10 or 8.1:  
the system is KMS activated with an external or real KMS server, or SppExtComObjHook is installed (or similar KMS service solutions)

- on Windows 7:  
SppExtComObjHook is installed, or external or real KMS server is added manually to OSPP registry  
'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\OfficeSoftwareProtectionPlatform'

* The script will not check or detect already installed Office products (C2R or MSI) before installation

while it is possible to install Office C2R on the top of already installed C2R, it is advisable to start clean

* If you want to update Office manually, set Updates option to False,  
then, you can execute this in command prompt as administrator to update Office:

"%CommonProgramFiles%\Microsoft Shared\ClickToRun\OfficeC2RClient.exe" /update user updatepromptuser=True displaylevel=True

* Starting MAY 2020, Office 365 products are being renamed to Microsoft 365, keeping the same SKU names and included apps:  
https://docs.microsoft.com/deployoffice/name-change

SKU ID                 | Old Name                  | New Name  
---------------------- | ------------------------- | -------------------------------  
O365ProPlusRetail      | Office 365 ProPlus        | Microsoft 365 Enterprise  
O365BusinessRetail     | Office 365 Business       | Microsoft 365 Business  
O365SmallBusPremRetail | Office 365 Small Business | Microsoft 365 Small Business  
O365HomePremRetail     | Office 365 Home           | Microsoft 365 Family  
O365EduCloudRetail     | Office 365 Education      | Microsoft 365 Education

______________________________

## Windows 7/8.1 Limited Support

* Official support for Windows 7/8.1 ended January 2023

* Because of that, most Office channels will offer a specific build targeted for Windows 7/8.1

* You cannot choose a build targeted for Windows 11/10 to be installed on Windows 7/8.1,  
or build targeted for Windows 8.1 to be installed on Windows 7

* For more information:  
https://learn.microsoft.com/deployoffice/endofsupport/windows-7-support  
https://learn.microsoft.com/deployoffice/endofsupport/windows-81-support

* YAOCTRI will not block Office 2019/2021/2024 installation on Windows 7/8.1  
however, builds higher than the specific build range, or builds from Volume channels, are mostly not compatible with these OSs

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
it receives two or more builds per month, as needed

* Business stable channels:

4. Monthly Enterprise

new channel since May 2020

gets new features/quality/security updates once a month  
it receives only one build a month, on the second Tuesday of the month (Patch Tuesday)

5. Semi-Annual Preview

formerly known as Semi-Annual Targeted / First Release for Business  
provides the same new features 4 months before Semi-Annual channel

gets new features updates twice a year (in March and September), in addition to quality/security updates once a month  
it receives only one build a month, on the second Tuesday of the month (Patch Tuesday)

6. Semi-Annual

formerly known as Broad / Deferred / Business

gets new features updates twice a year (in January and July), in addition to quality/security updates once a month  
it receives only one build a month, on the second Tuesday of the month (Patch Tuesday)

* Testing channels:

7. DevMain Channel

the most frequent channel for Office builds as soon as they are compiled, providing new features/improvements/fixes and new bugs or issues

8. Microsoft Elite

the second most frequent channel for Office builds as soon as they are tested  
it mostly aligns with Beta channel and works as an internal preview for it

* Office 2024 Volume channels:

1. Perpetual2024 VL

the official update channel for volume licensed products of Office 2024  
it only gets security and quality fixes once a month (Patch Tuesday)

2. Microsoft2024 VL

internal preview channel for Perpetual2024 VL channel

* Office 2021 Volume channels:

1. Perpetual2021 VL

the official update channel for volume licensed products of Office 2021  
it only gets security and quality fixes once a month (Patch Tuesday)

2. Microsoft2021 VL

internal preview channel for Perpetual2021 VL channel

* Office 2019 Volume channels:

7. Perpetual2019 VL

the official update channel for volume licensed products of Office 2019  
it only gets security and quality fixes once a month (Patch Tuesday)

8. Microsoft2019 VL

internal preview channel for Perpetual2019 VL channel

______________________________

## Behind the scenes

* YAOCTRI - Volume flavor:

- Microsoft 365 Enterprise will be installed as Retail SKU, then converted with Mondo 2016 Volume licenses  
additionally, O365ProPlusRetail grace key will be installed to enable more features

- On Windows 11/10:  
all other products will be installed directly as Volume SKUs

- On Windows 8.1/7:  
Office Mondo 2016 will be installed directly as Volume SKU  
all other products will be installed as Office 2016 Retail SKUs, then converted with Office 2021/2019 Volume licenses

* YAOCTRIR - Retail flavor:

- On Windows 11/10:  
all products will be installed directly as Retail SKUs

- On Windows 8.1/7:  
all Microsoft 365 and Office 2016 products will be installed directly as Retail SKUs  
Office 2021/2019 products will be installed as Office 2016 Retail SKUs, then converted with Office 2021/2019 Retail licenses

______________________________

## Special Thanks

@Windows_Addict / features suggestion and testing  
@ratzlefatz     / OfficeRTool  
@Krakatoa       / WOTOK  
@presto1234     / code improvements suggestion  
@Enthousiast    / reporting and testing
