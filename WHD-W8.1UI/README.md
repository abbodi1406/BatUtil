# Windows 8.1 Updates Installer

Automated batch script to install/integrate Windows 8.1 Updates, depending on WHDownloader repository.

## Features:

* Supported targets:
- Current Online OS
- Offline image (already mounted directory, another partition)
- Distribution folder (extracted iso, copied dvd/usb)
- WIM file directly

* Enable .NET Framework 3.5 if available source detected

checked locations: mounted iso, inserted dvd/usb, sxs folder for distribution target

* Detect Windows 8.1 ADK [Deployment Tools](http://www.microsoft.com/en-us/download/details.aspx?id=39982) for offline integration

## How to:

* Recommended Host OS: Windows 7 or later

* Recommended: place WHD-W81UI.cmd next to WHDownloader.exe to detect updates by default

* Run the script as administrator

* Change the options to suit your needs, make sure all are set correctly, do not use quotes marks "" in paths

* Press zero '0' to start the process

## Options:

Press each option corresponding number/letter to change it

1. Target  
target windows image, default is current online system  
if a wim file is available besides the script, it will be detected automatically

2. WHD Repository  
location of WHDownloader "Updates" folder

3. LDR branch  
force installing of LDR branch for .NET updates that have it

4. Hotfixes  
install updates found in "Hotfix"

5. WU Satisfy  
install updates found in "Additional\WU.Satisfy"

6. Windows10  
install Windows10 related updates found in "Additional\Windows10"  
if you switch it ON, another option will be available: B. Block Windows10/Telemetry

7. WMF  
install (Windows Management Framework 5.1) package found in "Additional\WMF"

8. RSAT updates  
install (Remote Server Administration Tools) package and updates found in "Extra\RSAT"

9. Online installation limit  
available only if the target is Current Online OS  
limit number of updates that will be installed before requiring to reboot  
installing a large number of updates on live OS makes the process slower and slower

D. DISM  
available only if the target is an offline image  
the path for custom dism.exe  
required when the current Host OS is lower than Windows 8.1 without ADK installed

E. Update WinRE.wim  
available only if the target is a distribution folder, or WIM file  
enable or disable updating winre.wim inside install.wim

I. Selected Install.wim indexes  
available only if the target is a distribution folder, or WIM file  
ability to select specific index(s) to update from install.wim, or all indexes by default

## Manual options (for advanced users):

Edit the script with notepad (or text editor) to change

* net35  
process or skip enabling .NET 3.5 feature

* iso  
create new iso file if the target is a distribution folder  
require ADK installed, or placing oscdimg.exe or cdimage.exe next to the script

* delete_source  
keep or delete DVD distribution folder after creating updated ISO

* autostart  
start the process automatically once you execute the script

* cab_dir  
directory for temporary extracted files, default is on the same drive as the script

* mountdir / winremount  
mount directory for updating wim files, default is on system drive C:\

* you can also change the default value of main Options  
examples:  
set LDR branch or Hotfixes as OFF  
set specific folder as default for WHD repository  
set custom dism.exe path on Windows 7

## Remarks:

* for offline integration, if "Block Windows10/Telemetry" option is active, a simple script will be created on desktop: RunOnce_W10_Telemetry_Tasks.cmd  
after installing the OS, you need to run it as administrator, it will be self-deleted afterwards

* WinPE images (boot.wim/winre.wim) will be updated only with:
- servicing stack update
- baseline updates
- Monthly Quality Rollup
- extra few WinPE update

## Credits:

[Creator](https://forums.mydigitallife.net/members/abbodi1406.204274/)  
[Concept](https://forums.mydigitallife.net/members/burfadel.84828/)  
[WHDownloader](https://forums.mydigitallife.net/threads/44645)

## Changelog:

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
