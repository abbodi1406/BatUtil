# Windows 7 Updates Installer

Automated batch script to install/integrate Windows 7 Updates, depending on WHDownloader repository.

## Features:

* Supported targets:  
- Current Online OS  
- Offline image (already mounted directory, or another partition)  
- Distribution folder (extracted iso, copied dvd/usb)  
- Distribution Drive (virtual mounted iso, inserted dvd drive, usb drive)  
- WIM file directly (unmounted)

* Detect Windows 8.1 ADK [Deployment Tools](http://www.microsoft.com/en-us/download/details.aspx?id=39982) for offline integration and iso/wim updating

* Detect Windows 10 ADK [imagex.exe and oscdimg.exe](https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install) for iso/wim updating

## How to:

* Recommended Host OS: Windows 7 or Windows 8.1

* Recommended: place WHD-W7UI.cmd next to WHDownloader.exe to detect updates by default

* Run the script as administrator

* Change the options to suit your needs, make sure all are set correctly, do not use quotes marks "" in paths

* Press zero 0 to start the process

* At the end, Press 9 to exit, or close the windows with red X button

## Options:

Press each option corresponding number/letter to change it

* [1] Target  
target windows image, default is current online system  
if a wim file is available next to the script, it will be detected automatically

* [2] WHD Repo  
location for WHD repository "Updates" directory (default is next to the script)

* [3] LDR branch  
force installing of LDR branch for any updates that have it

* [4] IE11  
install (Internet Explorer 11) packages found in "Additional\_IE11"  
if you switch it OFF, "Extra\IE9" will be installed if exist, otherwise "Extra\IE8" if exist

* [5] RDP  
install (Remote Desktop Protocol 8/8.1) packages found in "Additional\RDP"  
if you switch it OFF, "Extra\WithoutRDP" updates will be installed if exist

* [6] Hotfixes  
install updates found in "Hotfix"

* [7] WMF  
install (Windows Management Framework) packages found in "Additional\WMF"  
these packages require .NET Framework 4.5 or higher to be already installed

* [8] Features (WHD-W7UI_WithoutKB3125574.cmd only)  
install updates found in "Extra\WithoutKB3125574\_Features"

* [A] KB971033  
install (Windows Activation Technologies) package found in "Additional\WAT"  
this package is required for online genuine validation for non-volume editions

* [W] Windows10  
install Windows10 related updates found in "Additional\Windows10"

* [S] ADLDS  
install (Active Directory LDS) package and updates found in "Extra\AD_LDS"

* [R] RSAT  
install (Remote Server Administration Tools) package and updates found in "Extra\RSAT"

* [L] Online installation limit  
available only if the target is Current Online OS  
limit number of updates that will be installed before requiring to reboot  
installing a large number of updates on live OS makes the process slower and slower

* [D] DISM
available only if the target is an offline image  
the path for custom dism.exe  
required when the current Host OS is lower than Windows 7 without ADK installed

* [U] Update WinRE.wim  
available only if the target is a distribution folder, or WIM file  
enable or disable updating winre.wim inside install.wim

* [I] Install.wim selected indexes  
available only if the target is a distribution folder, or WIM file  
a choice to select specific index(s) to update from install.wim, or all indexes by default

* [K] Keep indexes  
available only if you selected specific index(s) in above option [I]  
a choice to only keep selected index(s) when rebuilding install.wim, or keep ALL indexes

* [M] Mount Directory  
available only if the target is a distribution folder, or WIM file
mount directory for updating wim files, default is on the same drive as the script

* [E] Extraction Directory  
directory for temporary extracted files, default is on the same drive as the script

## Configuration options (for advanced users):

* Edit WHD-W7UI.ini to change the default value of main options:  
Target  
Repo  
DismRoot  
WinRE  
Cab_Dir  
MountDir  
WinreMount  
OnlineLimit  
LDRbranch  
IE11  
RDP  
Hotfix  
Features  
WAT  
WMF  
Windows10  
ADLDS  
RSAT

* or set extra manual options below:

- ISO  
create new iso file, if the target is a distribution  
require installed ADK, or place oscdimg.exe or cdimage.exe next to the script

- ISODir  
folder path for iso file, leave it blank to create in the script current directory

- Delete_Source  
keep or delete DVD distribution folder after creating updated ISO

- AutoStart  
start the process automatically once you execute the script

* Note: Do not change the structure of WHD-W7UI.ini, just set your options after the equal sign =

* To restore old behavior and change options by editing the script, simply detele WHD-W7UI.ini file

## Remarks:

* for offline integration, a simple script will be created on desktop RunOnce_W10_Telemetry_Tasks.cmd  
after installing the OS, you need to run it as administrator, it will be self-deleted afterwards

* for offline integration, to process x64 update KB2603229 correctly, a simple script will be created on desktop: RunOnce_KB2603229_Fix.cmd  
after installing the OS, you need to run it as administrator, it will be self-deleted afterwards

* for offline integration, to rebuild wim files, you need either of:  
- imagex.exe placed next to WHD-W7UI.cmd  
- Windows 8.1 ADK or Windows 10 ADK is installed  
- Host OS is Windows 8.1 or later

* WinPE images (boot.wim/winre.wim) will be updated only with:  
- Servicing Stack Update  
- SHA2 Code Signing Support Update  
- Extended Servicing Stack Update  
- Monthly Quality Rollup

* Extra registry settings will be added one time only if "Hotfixes" option is YES  
if you do not want these settings, edit the script, search for this line and delete it:  
`if /i "%Hotfix%"=="YES" call :regfix`

## Debug Mode (for advanced users):

* Create a log file of the integration process for debugging purposes

* The operation progress will not be shown in this mode

* How To:  
- edit the script and change set _Debug=0 to 1  
- set main options correctly, specially "target" and "repo"  
- save and run the script as admin  
- wait until command prompt window is closed and Debug.log is created

## Credits:

[Creator](https://forums.mydigitallife.net/members/abbodi1406.204274/)  
[Concept](https://forums.mydigitallife.net/members/burfadel.84828/)  
[WHDownloader](https://forums.mydigitallife.net/threads/44645)

## Changelog:

* 6.1:  
implemented IE11 registry fix for Embedded x64

* 6.0:  
lite revamp with backported features of W10UI  
support for configuration file WHD-W7UI.ini  
more menu options (WinRE.wim, install.wim indexes, Mount and Extraction dirs)  
added manual option ISODir  
implemented debug mode  
code improvemens and fixes to avoid paths issues  
optimized checking Security Updates  
added detection support for Windows 10 ADK (for imagex.exe and oscdimg.exe only)  
added theoretical support if Win7 build is bumped to 7602 after ESU  
added support to suppress the EOS notification  
new extended servicing stack update KB4531786

* 5.3:  
fixed installing updates if SSU/SHA2 updates are already installed previously

* 5.2:  
new servicing stack update KB4523206

* 5.1:  
readded SSU KB4490628 support, fixed SSU KB4516655 integration

* 5.0:  
new servicing stack update KB4516655

* 4.9:  
new servicing stack update KB4490628

* 4.7/4.8:  
added support and menu option to select specific index(s) to update from install.wim

* 4.6:  
new servicing stack update KB3177467-v2  
process telemetry appraiser block for monthly rollup

* 4.5:  
fixed KB2952664 installation  
added support to use DVD drive as target (mounted iso, inserted dvd)

* 4.4:  
fixed issue with KB4099950 online installation  
added architecture to updated iso name

* 4.3:  
fixed minor issues with WHD-W7UI_WithoutKB3125574

* 4.2:  
moved "online update" before monthly rollup, to better handle KB4099950  
added option to keep or delete DVD distribution folder after creating updated ISO

* 4.1:  
remove winre.wim left behind when updating install.wim directly  
added/updated WHD-W7UI_WithoutKB3125574.cmd with new features

* 4.0:  
improvements and optimizations  
continous messeges in cmd window  
support for different targets  
workaround to offline integrate SSU KB3177467  
process online updates for offline targets (if possible)  
add block tweaks related to diagtrack (telemetry service) when installing Monthly Rollup

* 2.7: enhanced Windows10 telemetry block tweaks, new hyper-v integration services version
* 2.6: fixed KB2646060 installation
* 2.5: updated wmf, Windows10/telemetry block tweaks
* 2.4: fixed issue with WHD-W7UI_WithoutKB3125574.cmd
* 2.2: changed IE11/RDP/ADLDS/RSAT installation order to precede Monthly Rollup
* 2.1: new hyper-v integration services version
* 2.0: added support for rollup KB3125574, added another script without it
* 1.8: updated wmf installation, Windows10 block tweaks
* 1.5: improved rdp7 updates handling
* 1.4: new hyper-v integration services version
* 1.3: fixed: if IE11 option is OFF, IE9/IE8 gets installed regardless if IE11 already installed
* 1.2: registry fixes are now tied with Hotfixes option
* 1.1: add a skip exception for SUR tool KB947821
* 1.0: initial release
