# Windows 7 ESUs Standalone Installer

Automated batch script to install/integrate Windows 7 Extended Security Updates without the need for ESU eligibility suppressor or bypass.

## Features:

* Supported targets:  
> Current Online OS  
Offline image (already mounted directory, or another partition)  
Distribution folder (extracted iso, copied dvd/usb)  
Distribution Drive (virtual mounted iso, inserted dvd drive, usb drive)  
WIM file directly (unmounted)

* Supports having updates in one folder:  
> Detect and install servicing stack update first  
Check required stack installer version for each update  
Works with Monthly Quality Rollup, or Security Only update / IE11 cumulative update  
Skip installing non-winpe updates for boot.wim/winre.wim (IE11 and .NET 3.5)

* Detect Windows 8.1 ADK [Deployment Tools](http://www.microsoft.com/en-us/download/details.aspx?id=39982) for offline integration and iso/wim updating

* Detect Windows NT 10.0 ADK [imagex.exe and oscdimg.exe](https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install) for iso/wim updating  

## Limitations:

* SHA2 support updates KB4490628 and KB4474419 are prerequisites for ESU updates

either install them yourself first,  
or put their msu files with ESU updates files together and the script will install them

* The script is specifically designed to process ESU updates only.

other regular updates should be installed normally
either manually or using other tools (e.g. WHD-W7UI script)

## How to:

* Recommended Host OS: Windows 7 or later
* Optional: place W7ESUI.cmd next to the updates (.msu/.cab) to detect them by default
* Run the script as administrator
* Change the options to suit your needs, make sure all are set correctly, do not use quotes marks "" in paths
* Press zero 0 to start the process
* At the end, Press 9 to exit, or close the windows with red X button

## Options:

Press each option corresponding number/letter to change it

**1.** Target
target windows image, default is current online system
if a wim file is available next to the script, it will be detected automatically

**2.** Updates
location of ESU updates files

**D.** DISM
the path for custom dism.exe

**U.** Update WinRE.wim
available only if the target is a distribution, or WIM file
enable or disable updating winre.wim inside install.wim

**I.** Install.wim selected indexes
available only if the target is a distribution, or WIM file
a choice to select specific index(s) to update from install.wim, or all indexes by default

**K.** Keep indexes
available only if you selected specific index(s) in above option [I]
a choice to only keep selected index(s) when rebuilding install.wim, or keep ALL indexes

**M.** Mount Directory
available only if the target is a distribution, or WIM file
mount directory for updating wim files, default is on the same drive as the script

**E.** Extraction Directory
directory for temporary extracted files, default is on the same drive as the script

## Configuration options (for advanced users):

- Edit W7ESUI.ini to change the default value of main options:  
> Target  
Repo  
DismRoot  
WinRE  
Cab_Dir  
MountDir  
WinreMount

or set extra manual options below:

* ISO  
create new iso file, if the target is a distribution  
require installed ADK, or place oscdimg.exe or cdimage.exe next to the script

* ISODir  
folder path for iso file, leave it blank to create in the script current directory

* Delete_Source  
keep or delete DVD distribution folder after creating updated ISO

* AutoStart  
start the process automatically once you execute the script

- Note: Do not change the structure of W7ESUI.ini, just set your options after the equal sign =

- To restore old behavior and change options by editing the script, simply detele W7ESUI.ini file

## Remarks:

* for offline integration, a simple script will be created on desktop RunOnce_W10_Telemetry_Tasks.cmd  
after installing the OS, you need to run it as administrator, it will be self-deleted afterwards

* for offline integration, to rebuild wim files, you need one of:  
> imagex.exe placed next to W7ESUI.cmd  
Windows 8.1 ADK or Windows NT 10.0 ADK is installed  
Host OS is Windows 8.1 or later

## Debug Mode (for advanced users):

* Create a log file of the integration process for debugging purposes

* The operation progress will not be shown in this mode

* How To:  
> edit the script and change set _Debug=0 to 1  
set main manual options correctly, specially "target" and "repo"  
save and run the script as admin  
wait until command prompt window is closed and Debug.log is created

## Credits:

[Creator](https://forums.mydigitallife.net/members/abbodi1406.204274/)  
[Concept](https://github.com/Gamers-Against-Weed)  
[WHDownloader](https://forums.mydigitallife.net/threads/44645)  
[Special assistance: komm](http://www.windows-update-checker.com/)

## Changelog:

<details><summary>changelog</summary>

0.4:  
- added support to install ESU Suppressor

0.3:  
- enhanced detection for updates files and KB number

0.2:  
- added support to install SHA2 updates KB4490628 and KB4474419 if detected

0.1:  
- initial release
</details>
