# Yet Another Office Click-To-Run Installer

* A mostly automated script(s) to install Office Click-to-Run from offline source without using Office Deployment Tool (setup.exe), which allow to bypass ODT restrictions

* Support installing Product Suites or Single Apps individually

* Support installing multiple languages separately or together

* Support configuration options like the ones available with ODT, including:
- Source Path
- Excluding Apps
- Update Channel
- Miscellaneous Options (Display Level, Updates Enabled, Eula, Pin Icons, App Shutdown, Auto Activate)

* Includes a proper workaround to install Office 2019 on Windows 7 and 8.1, with working updates

* There are two flavors available of the scripts:

- YAOCTRI - Volume  
install volume products for Office 2019 only, in addition to the special SKUs O365ProPlus and Mondo

- YAOCTRIR - Retail  
install retail products for Office 365 / 2016 / 2019 Suites, in addition to Office 2019 Single Apps

* Each flavor consist of two command scripts:  
- Configurator.cmd : create C2R_Config ini files, with the ability to start the installation at the end  
- Installer.cmd    : read C2R_Config ini files and execute the installation

## How To:

* Run YAOCTRI_Configurator.cmd or YAOCTRIR_Configurator.cmd as administrator and follow the prompts

- For each menu, press the corresponding number or letter beside an option to change its state or proceed

- To exit at any menu press X (Version/Arch/Lang/Type menus have no return option, only proceed or exit)

- At first, enter the path for Office offline source

either the directory that contain "Office" folder (not Office folder path itself)

or the drive letter if use .img file mounted as virtual DVD

you can also place Configurator.cmd script inside "Office" folder, and the path will be detected automatically

- If multiple versions are detected in the source, you will be prompted to choose one

- If current OS is x64, and multi-architecture Office 64-bit/32-bit is detected, you will be prompted to choose one

- If multiple languages are detected in the specified version, you will be prompted to choose one, or all

- If you chose all languages, you will be prompted to choose primary language  
(determines the setup and Office Shell UI culture, including shortcuts, right-click context menus, and tooltips)

- Select the installation type: complete product suites, or single apps separately

- If you selected a product suite, you will get a menu to exclude (turn OFF) unneeded apps

- Select the desired Update Channel

- Change the Miscellaneous Options to your need

- At the end, you will have three options:

1. Install Now  
start normal installation now with the selected options (C2R_Config ini will be created too)

2. Create setup configuration (Normal Install)  
create C2R_Config ini file, to be used later with YAOCTRI_Installer.cmd

3. Create setup configuration (Auto Install)  
create C2R_Config ini file with unattended option, which allow YAOCTRI_Installer.cmd to start the installation immediately

## Remarks:

* YAOCTRIR - Retail flavor is recommended only if you have actual retail/subscription key

but you still can use it to install Retail SKUs, then use C2R-R2V to convert licensing to volume

* For Windows 7 and 8.1, the workaround to install Office 2019 require installing corresponding Office 2016 products, and corresponding Office 2019 volume licences

therefore, the underlying Product IDs and entries in "Program and Features" will be always Office 2016, but Office 2019 licenses will determine the features

* For YAOCTRI - Volume flavor, if you choose "Office 365 ProPlus" along with Project 2019 and/or Visio 2019,

Mondo licenses used for volume conversion will take precedence over Project/Visio licenses (that is Office limitation not the script)

a better choice would be to select Mondo directly, which include Project/Visio

* Disable Telemetry option is not processed for "Office 365" suties because it affect features

* Auto Activate option has no affect in YAOCTRIR - Retail flavor

* Auto Activate option will work in YAOCTRI - Volume flavor only in these scenarios:

- on Windows 10 or 8.1:

system is KMS activated with external online KMS server, or installed SppExtComObjPatcher (or similar KMS service solutions)

- on Windows 7:

SppExtComObjPatcher is installed, or external online KMS server is added manually to OSPP registry  
`HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\OfficeSoftwareProtectionPlatform`

* C2R_Config ini files are system-specific (architecture and Windows version level):

- you cannot create config file on x86 system and use it on x64 system, or vice versa

- you cannot create config file on Windows 10 and use it on Windows 7/8.1, or vice versa

* The script will not check or detect already installed Office products (C2R or MSI) before installation

while it is possible to install Office C2R on top of already installed C2R, it is advisable to start clean

* If you want to update Office manually, you may disable Updates option

and after installation, you can execute this in command prompt as administrator to update Office:  
`"%CommonProgramFiles%\Microsoft Shared\ClickToRun\OfficeC2RClient.exe" /update user updatepromptuser=True displaylevel=True`

## Special Thanks

@ratzlefatz / OfficeRTool
@Krakatoa   / WOTOK
