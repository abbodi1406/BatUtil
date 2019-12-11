# Windows 8.1 Updates Installer

Automated batch script to install/integrate Windows 8.1 Updates, depending on WHDownloader repository.

## Features:

* Supported targets:  
- Current Online OS  
- Offline image (already mounted directory, or another partition)  
- Distribution folder (extracted iso, copied dvd/usb)  
- Distribution Drive (virtual mounted iso, inserted dvd drive, usb drive)  
- WIM file directly (unmounted)

* Enable .NET Framework 3.5 if available source detected

checked locations: mounted iso, inserted dvd/usb, sxs folder for distribution target

* Detect Windows 8.1 ADK [Deployment Tools](http://www.microsoft.com/en-us/download/details.aspx?id=39982) for offline integration and iso/wim updating

* Detect Windows 10 ADK [Deployment Tools](https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install) for offline integration and iso/wim updating

* Perform pending cleanup operation for online OS after restarting

## How to:

* Recommended Host OS: Windows 7 or later

* Recommended: place WHD-W81UI.cmd next to WHDownloader.exe to detect updates by default

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
force installing of LDR branch for .NET updates that have it

* [4] Hotfixes  
install updates found in "Hotfix"

* [5] WU Satisfy  
install updates found in "Additional\WU.Satisfy"

* [6] Windows10  
install Windows10 related updates found in "Additional\Windows10"

* [7] WMF  
install (Windows Management Framework 5.1) package found in "Additional\WMF"

* [8] RSAT  
install (Remote Server Administration Tools) package and updates found in "Extra\RSAT"

* [N] Enable .NET 3.5  
enable .NET Framework 3.5 feature

* [C] Cleanup System Image: YES      [T] Reset Base: YES  
in this choice, the OS images will be rebased and superseded components will be "removed"  
quick operation and reduce size further more.

* [C] Cleanup System Image: YES      [T] Reset Base: NO  
in this choice, the OS images will be cleaned and superseded components will be "delta-compressed"  
safe operation, but might take long time to complete.

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

* Edit WHD-W81UI.ini to change the default value of main options:  
Target  
Repo  
DismRoot  
Net35  
Cleanup  
ResetBase  
WinRE  
Cab_Dir  
MountDir  
WinreMount  
OnlineLimit  
LDRbranch  
Hotfix  
WUSatisfy  
Windows10  
WMF  
RSAT

* or set extra manual options below:

- wim2esd  
convert install.wim to install.esd, if the target is a distribution  
warning: the process will consume very high amount of CPU and RAM resources

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

* To restore old behavior and change options by editing the script, simply detele WHD-W81UI.ini file


## Remarks:

* How to perform the pending cleanup operation for online OS:  
- run WHD-W81UI.cmd and install updates, assuming you choose to cleanup OS image (with or without resetbase)  
- restart system  
- run WHD-W81UI.cmd again, it will go directly to Cleanup or Reset OS image (it doesn't install or check any updates)

* for offline integration, a simple script will be created on desktop RunOnce_W10_Telemetry_Tasks.cmd  
after installing the OS, you need to run it as administrator, it will be self-deleted afterwards

* WinPE images (boot.wim/winre.wim) will be updated only with:  
- servicing stack update  
- baseline updates  
- Monthly Quality Rollup  
- extra few WinPE updates

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

* 6.0:  
lite revamp with backported features of W10UI  
support for configuration file WHD-W81UI.ini  
more menu options (.NET 3.5, Cleanup, install.wim indexes, Mount and Extraction dirs)  
added manual options wim2esd, ISODir  
implemented debug mode  
code improvemens and fixes to avoid paths issues

* 5.2:  
new servicing stack update KB4524445

* 5.1:  
new servicing stack update KB4521864

* 5.0:  
new servicing stack update KB4512938

* 4.9:  
new servicing stack update KB4504418

* 4.8:  
added support for Windows 10 ADK

* 4.6/4.7:  
added support and menu option to select specific index(s) to update from install.wim

* 4.5:  
process telemetry appraiser block for monthly rollup

* 4.4:  
fixed KB2976978 installation  
added support to use DVD drive as target (mounted iso, inserted dvd)

* 4.3:  
added architecture to updated iso name

* 4.2:  
added option to keep or delete DVD distribution folder after creating updated ISO

* 4.1:  
remove winre.wim left behind when updating install.wim directly

* 4.0:  
improvements and optimizations  
continous messeges in cmd window  
support for different targets  
process online updates for offline targets (if possible)  
add block tweaks related to diagtrack (telemetry service) when installing Monthly Rollup

* 2.7: fixed issue detecting wim file with spaces in path
* 2.5: fixed issue when updates count equals 100
* 2.4: enhanced Windows10 telemetry block tweaks, new hyper-v integration services version
* 2.3: updated wmf, Windows10/telemetry block tweaks
* 2.2: suppress error messege for Do.Not.Integrate updates
* 2.1: updated .net 3.5 gdrlist, added exclusion for secure boot update KB3172729
* 2.0: can now handle wim files, added support for new Package_for_RollupFix updates
* 1.8: new hyper-v integration services version
* 1.7: added options: wmf, Windows10 block tweaks
* 1.4: fixed issue with gdr satisfy option
* 1.3: updated: .net 3.5 gdr list / hyper-v integration services package / EnterpriseEdition packages
* 1.2: fixed typo bug when using custom dism path
* 1.1: fixed typo issue with LDR branch option
* 1.0: initial release
