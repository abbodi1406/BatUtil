# Windows 10 Updates Installer

Automated batch script to install/integrate Windows 10 Updates

## Features:

* Supported targets:
- Current Online OS
- Offline image (already mounted directory, another partition)
- Distribution folder (extracted iso, copied dvd/usb)
- Distribution Drive (virtual mounted iso, inserted dvd, usb drive)
- WIM file directly (unmounted)

* Supports having updates in one folder:
- Detect and install servicing stack update first
- Skip installing non-winpe updates for boot.wim/winre.wim (flash, oobe, .net 4.x)
- Skip installing Adobe Flash update for Server Core or if the package is removed
- Handle dynamic updates for setup media 'sources' folder (skip installing it, extract it for distribution target)

* Enable .NET Framework 3.5 if available source detected, and reinstall Cumulative updates afterwards.  
valid locations: mounted iso, inserted dvd/usb, sxs folder for distribution target, custom specified folder path

* Detect Windows 10 ADK [Deployment Tools](https://msdn.microsoft.com/en-us/windows/hardware/dn913721.aspx) for offline integration

## Limitations:

* Updates version will not be checked for applicability  
meaning for example, if 10240 updates are specified for 10586 target, the script will proceed to install them  
be sure to specify the correct updates files

* These extra updates are not processed correctly

[RSAT - KB2693643](https://support.microsoft.com/en-us/help/2693643/)  
[Media Feature Pack for Windows N editions](https://support.microsoft.com/en-us/help/3145500/)

the script will try to install them whether applicable, already installed or not  
avoid using them with the script and install them manually

## How to:

* Recommended Host OS: Windows 8.1 or later

* Optional: place W10UI.cmd next to the updates (.msu/.cab) to detect them by default

* Run the script as administrator

* Change the options to suit your needs, make sure all are set correctly, do not use quotes marks "" in paths

* Press zero '0' to start the process

* At the end, Press 9 to exit, or close the windows with red X button

## Options:

Press each option corresponding number/letter to change it

1. Target  
target windows image, default is current online system  
if a wim file is available besides the script, it will be detected automatically

2. Updates  
location of updates files

3. DISM  
the path for custom dism.exe  
required when the current Host OS is lower than Windows 10 without ADK installed

4. Enable .NET 3.5  
process or skip enabling .NET 3.5 feature

5. Cleanup System Image: YES      6. Reset Image Base: NO  
in this choice, the OS images will be cleaned and superseded components will be "delta-compressed"  
safe operation, but might take long time to complete.

5. Cleanup System Image: YES      6. Reset Image Base: YES  
in this choice, the OS images will be rebased and superseded components will be "removed"  
quick operation and reduce size further more, but might break "Reset this PC" feature.

7. Update WinRE.wim  
available only if the target is a distribution folder, or WIM file  
enable or disable updating winre.wim inside install.wim

8. Selected Install.wim indexes  
available only if the target is a distribution folder, or WIM file  
a choice to select specific index(s) to update from install.wim, or all indexes by default

K. Keep indexes  
available only if you selected specific index(s) in above option 8  
a choice to only keep selected index(s) when rebuilding install.wim, or keep ALL indexes

M. Mount Directory  
available only if the target is a distribution folder, or WIM file  
mount directory for updating wim files, default is on the same drive as the script

E. Extraction Directory  
directory for temporary extracted files, default is on the same drive as the script

## Configuration options (for advanced users):

- Edit W10UI.ini to change the default value of main options:  
> Target  
Repo  
DismRoot  
Net35  
Cleanup  
ResetBase  
WinRE  
_CabDir  
MountDir

or set extra manual options below:

* Net35Source  
specify custom "folder" path for microsoft-windows-netfx3-ondemand-package.cab

* wim2esd  
convert install.wim to install.esd, if the target is a distribution  
warning: the process will consume very high amount of CPU and RAM resources

* ISO  
create new iso file, if the target is a distribution folder  
require Win10 ADK, or place oscdimg.exe or cdimage.exe next to the script

* ISODir  
folder path for iso file, leave it blank to create in the script current directory

* Delete_Source  
keep or delete DVD distribution folder after creating updated ISO

* AutoStart  
start the process automatically once you execute the script

- Note: Do not change the structure of W10UI.ini, just set your options after the equal sign `=`

- To restore old behavior and change options by editing the script, simply detele W10UI.ini file

## Debug Mode (for advanced users):

* Create a log file of the integration process for debugging purposes

* The operation progress will not be shown in this mode

* How To:  
- edit the script and change set _Debug=0 to 1  
- set main manual options correctly, specially "target" and "repo"  
- save and run the script as admin  
- wait until command prompt window is closed and W10UI_Debug.log is created

## Credits:

[Creator](https://forums.mydigitallife.net/members/abbodi1406.204274/)  
[Concept](https://forums.mydigitallife.net/members/burfadel.84828/)  
[WHDownloader](https://forums.mydigitallife.net/threads/44645)

## Changelog:

7:7:  
- x64 target on x86 host: Fix for unseen registry flush error.

7:6:  
- x64 target on x86 host: Fix for wrong detection.

7:5:  
- Code improvements and fixes.

- Added option wim2esd to convert install.wim to install.esd (only for distribution target)

7:4:  
- Detect and skip WinPE only updates for install.wim

7.3:  
- Enhanced Mount and Extraction Directory processing

7.2:  
- Mount Directory will be always created as a subdirectory (even if it's already a subdirectory)

7.1:  
- Do not overwrite iso\sources files with dynamic updates when non-UUP boot.wim is used and updated

7.0:  
- Proper extraction of multilingual dynamic updates to only update existing language directories

- Support for the new 1909 Enablement Package to set the proper version tag

6.6:  
- ResetBase will be disabled for build 18362 and later, to avoid breaking future LCU installation

6.5:
- Enhanced processing DU  
now if you choose install.wim (or boot.wim) as target from inside \sources\ folder, DU will be processed and extracted

- Enhanced UUP boot.wim index 2 updating  
if DU is detected, \sources\ folder will be updated with newer files

6.4:  
Fixed .NET cumulative update reinstallation for build 18362

6.3:  
- Added workaround fix for updating refreshed 18362 WinPE images

- If you selected specific indexes from install.wim, you will get extra option to only keep the selected indexes when rebuilding install.wim  
you can still choose to keep them ALL

- To avoid accidental closing before reading or copying cmd window output, you now need to Press 9 to exit  
or close the window with the red X button

- Cosmetic change, option 3. DISM will now show "Windows 10 ADK" instead the long dism.exe path (if ADK is detected)

6.2:  
- Fixed already-installed detection for 1903 Cumlative Update

6.1:  
- Added manual option "isodir" to specify alternative folder path for saving iso file

- Added support for configuration file W10UI.ini to set options:  
Values in W10UI.ini take precedence over the ones inside W10UI.cmd (by default both are the same)  
Do not change the structure of W10UI.ini, just set your options after the equal sign  
To restore old behavior and change options by editing the script, simply detele W10UI.ini file

6.0:  
- Code improvement and fixes, mostly to avoid issues with paths and spaces in files names

5.9:  
- Added workaround to perform Cleanup System Image for current online OS after installing updates that require reboot to complete (i.e. Cumulative Update)  
how to:  
run W10UI.cmd and install updates, assuming you choose to cleanup OS image (with or without resetbase)  
restart system  
run W10UI.cmd again, it will go directly to Cleanup or Reset OS image (it doesn't install or check any updates)

5.8:  
- Fixed secondary SSU integration for 14393 WinPE images

5.7:  
- Normal 1809 cumulative update will be reinstalled (with .NET cumulative) after enabling .NET 3.5, to keep WU happy

5.6:  
- Added support and menu option "Selected Install.wim indexes"  
to select specific index(s) to update from install.wim, instead updating them all of them always

all indexes is the default setting, to change press 8 at menu  
the available indexes will be listed, enter the desired index(s) numbers to choose, separated with space  
you can revert to all indexes by entering * alone

- Fixed netfx cumulative update duplication, and the accidentally iso option set to 0

5.5:  
- Added support to handle the new .NET cumulative update for build 17763 and later

5.4:  
- Added support for multi-versioned updates, to avoid skipping new version if old version already installed

5.3:  
- Fixed Flash update integration for 17763 (non-applicable editions will be skipped)

- Fixed SSU integration for 16299 and later (previously it was always re-integrated even if pesent)

- Implemented Debug Mode (for advanced users)

5.2:  
- Fixed: image cleanup is not executed if you only integrated Servicing Stack Update

5.1:  
- Fixed ISO creation typo

5.0:  
- Fixed confliction issue in detecting offline partition as target, if it had boot files

- Added Mount & Extraction directories options to main menu

4.8:  
- Fixed detecting and integrating build 14393 cumulative update for WinPE images

4.7:  
- Added workaround to prevent breaking operation if Dism Error 1726 occur in cleanup OS image (W10 ver 1803)

- Added support to use DVD drive letter as target, whether mounted ISO or inserted DVD

4.6:  
- Added architecture to updated ISO file name

4.5:  
- Added manual option "delete_source" to keep or delete DVD distribution folder after creating updated ISO

4.3/4.4:  
- Skip .NET lang packs integration for WinPE images

- Updated WinRE.wim will not be left over, if the target is direct install.wim file

4.2:  
- Code improvements and fixes

- Detailed documentation for options in ReadMe.txt

- Added workaround for resetting 16299 WinPE images (they have the same restriction as OS image)

- Added option to update or skip winre.wim (if detected within install.wim)

- oscdimg.exe will be detected automatically if Windows 10 ADK is installed

- ISO file name will have the cumulative update version, and today's date (e.g. Win10_16299.214_2018-02-10.iso)

4.1:  
- Implemented workaround for offline ResetBase of build 16299 and later

4.0:  
- Cumulative update will now be installed separately after other updates (to avoid confliction with dynamic/.NET updates)

- Verbose script version

- Fixed .NET 3.5 feature enabling on Server editions

3.6:  
- Fixed: if net35source is set manually, the script still try to check and find another source

3.5:  
- Update files cab/msu will be processed from current location directly without copying over to temp location

3.4:  
- Fixed: when selected target is already mounted boot.wim index 2, detection conflict will cause the script to hang

3.3:  
- Fixed accidental mount directory confliction when updating live OS

3.2:  
- Splitted the ResetBase option to two, Cleanup System Image / Reset Image Base

3.0/3.1:  
- Added option to skip Resetbase operation

- Added option for custom path to .NET 3.5 cab source

- Added visible menu options for .NET 3.5 and Resetbase

- Implemented auto fix/change for registry value DisableResetbase (to allow Resetbase)

- Enabling .NET 3.5 now occurs after installing updates (to allow Resetbase), and cumulative update will be reinstalled afterwards

- Few improvement to handle "All applicable updates are found installed" situation

- Windows 10 ADK DISM will be used if detected, even if Host OS is Windows 10

2.0:  
- Updated WinRE.wim will not be left over, if the target is distribution folder

1.8:  
- Added workaround for "The remote procedure call failed." error when adding cumulative update to winpe image

1.2:  
- Fixed a check bug that prevent integrating 10240 cumulative into boot.wim/winre.wim

- Added two manual options for advanced users, autostart / iso

1.1:  
- Minor revision

1.0:  
- Initial release
