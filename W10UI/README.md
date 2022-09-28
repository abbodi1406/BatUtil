# Windows NT 10.0 Updates Installer

Automated script to install or integrate updates for:  
- Windows 10
- Windows 11
- Windows Server 2016, 2019, 2022

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

* Detect Windows ADK [Deployment Tools](https://docs.microsoft.com/windows-hardware/get-started/adk-install) for offline integration

* Perform pending cleanup operation for online OS after restarting.  
you must run W10UI.cmd at least once after restart to perform Cleanup or Reset OS image, before installing any new updates

## Updated ISO recommendation:

* Creating updated iso file for a distribution target require either of:  
- install Windows ADK
- place oscdimg.exe or cdimage.exe in the same folder next to W10UI.cmd

otherwise, embedded Powershell/.NET funcion `DIR2ISO` will be used to create the iso

## Limitations:

* Updates version will not be checked for applicability  
meaning for example, if 10240 updates are specified for 10586 target, the script will proceed to install them  
be sure to specify the correct updates files

* These extra updates are not processed correctly

[Remote Server Administration Tools (RSAT)](https://support.microsoft.com/en-us/help/2693643/)  
[Media Feature Pack for Windows N editions](https://support.microsoft.com/en-us/help/3145500/)

the script will try to install them whether applicable, already installed or not  
avoid using them with the script and install them manually

## How to:

* Recommended Host OS: Windows 8.1 or later

* Updating offline images of Windows 11 builds 22567 and later, require at least Windows 10 v1607 Host OS

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
required when the current Host OS is lower than Windows NT 10.0 without ADK installed

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

- Edit W10UI.ini to change the default value of the main options:  
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
specify custom "folder" path which contain microsoft-windows-netfx3-ondemand-package.cab

* LCUwinre  
force updating winre.wim with Cumulative Update even if SafeOS update detected

* UpdtBootFiles  
update ISO boot files bootmgr/bootmgr.efi/efisys.bin from Cumulative Update

* SkipEdge  
1 = do not install EdgeChromium with Enablement Package or Cumulative Update  
2 = alternative workaround to skip EdgeChromium with Cumulative Update only

* wim2esd  
convert install.wim to install.esd, if the target is a distribution  
warning: the process will consume very high amount of CPU and RAM resources

* wim2swm  
split install.wim into multiple install.swm files, if the target is a distribution

note: if both wim2esd/wim2swm are 1, install.esd takes precedence over split install.swm

* ISO  
create new iso file, if the target is a distribution folder  

* ISODir  
folder path for iso file, leave it blank to create in the script current directory

* Delete_Source  
keep or delete DVD distribution folder after creating updated ISO

* AutoStart  
start the process automatically once you execute the script  
the option will also auto exit at the end without prompt

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
[PSFExtractor / th1r5bvn23](https://www.betaworld.org/)  
[SxSExpand](https://forums.mydigitallife.net/members/superbubble.250156/)  
[Compressed2TXT](https://github.com/AveYo/Compressed2TXT)

## Changelog:

<details><summary>changelog</summary>

10.24:  
- Add support for future Windows 11 22H2 Moments Enablement Packages

10.23:  
- Detect and use external PSFExtractor.exe (located next to the script)

10.22:  
- Fix detection for .NET 4.8.1 pack KB5011048
- Skip Enablement Package for not applicable editions
- Skip rebuilding sources\install.wim if wim2esd is enabled

10.21:  
- Added support for Azure Stack HCI, 22H2 Enablement Package

10.20:  
- Restore original timestamp for Package_for_RollupFix .mum for 22621+ MSU integration

10.19:  
- Added support for Windows 11 22622 Enablement Package
- Fixed Combined UUP update naming scheme for Windows 11 22H2

10.18:  
- Enhanced detection for wmic.exe
- Changed option "SkipBootFiles" to "UpdtBootFiles" to avoid confusion

10.17:  
- Added support for the new updates file name "Windows11.0-KB*"

10.16:  
- Added option "SkipBootFiles" for not updating ISO boot files bootmgr/bootmgr.efi/efisys.bin

10.15:  
- Added support to install Windows 11 Combined UUP .msu file directly

10.14:  
- Check and exclude unsupported editions for 19041 WindowsExperienceFeaturePack
- Fixed: ADK parameter is not enabled when using custom dism.exe

10.13:  
- Added workaround for the missing wmic.exe in build 22483 (and later)
- When running within W10MUI, W10UI will install detected updates, regardless if already installed

10.12:  
- Added support for the new UUP dump file name scheme (PSF updates)

10.11:  
- Added support for Windows 11 Combined UUP updates
- Updated Windows Defender cab integration routine
- If AutoStart option is active, the script will not clear initial screen, and will auto exit at the end

10.10:  
- Added workaround for updating 1904x images on Host OS below Windows 10 1803

10.9:  
- Added manual option "LCUwinre" to force updating winre.wim with Cumulative Update
- Fixed architecture detection for already mounted WinPE images

10.8:  
- Fix updated iso label for Windows 10 1909

10.7:  
- Implemented DIR2ISO by AveYo as a last resort to create updated iso
- Improved updated iso label accuracy

10.6:  
- Updated PSFExtractor to remove SxSExpand dependency
- Embedded PSFExtractor using Compressed2TXT v5.3
- Include detected language(s) in ISO file name

10.5:  
- Changed updated ISO file name scheme  
example old:  
Win10_22000.71_x64_2021-07-16.iso  
example new:  
22000.71.210709-1028.CO_RELEASE_SVC_PROD1_CLIENT_X64FRE.iso

10.4:  
- Rebrand to Windows NT 10.0 Updates Installer
- Improved PSF files processing, and updated PSFExtractor

10.3:  
- Added workaround for long path issue when extracting PSF updates

10.2:  
- Build 18362, added alternative workaround to suppress Supplemental Servicing or SkipEdge
- Build 20231 and later, LCU will be re-extracted from cab file for updating install.wim
- Build 21382 and later, added support for new LCU PSFX format (cab + psf), require external PSFExtractor/SxSExpand

10.1:  
- Added detection for 19044 / v21H2 Enablement package
- Fixed wrong ISO version detection in some scenarios

10.0:  
- Added "SkipEdge=2" option to skip LCU's EdgeChromium via "Microsoft\Edge" folder
- Build 20231 and later, for updating install.wim, LCU will be added from cab file directly
- Build 20231 and later, if ReservicingLCU is detected, .NET CU / LCU will not be re-added after enabling NetFx3 feature
- Enhanced Flash updates detection to avoid confliction when Flash Removal update is merged with LCU

9.9:  
- Extended `SkipEdge` option to skip EdgeChromium bunded with Cumulative Update

9.8:  
- Further enhancement to prevent setup.exe conflict (if ISO files dates are newer than DU)

9.7:  
- Fix setup.exe conflict for UUP created ISO  
- Fix cosmetic bug detecting EP KB5000736 as Flash  
- Show W10UI version in the menu header

9.6:  
- Fix setup.exe conflict between boot.wim and DU for ISO distribution

9.5:  
- Added proper detection and integration for the new combined msu/cab files

9.4:  
- Fixed detection for SSU file and custom Updates location path

9.3:  
- Add proper detection and integration for the new SSU file name  
- Added "theoretical " support for Windows 10 ARM64 target

9.2:  
- Added detection for 19043 / v21H1 Enablement package  
- Added detection to install .NET 4.x main pack before .NET LP/Rollup  
- Skip wim2swm if install.wim size is less than 4GB

9.0:  
- Improved detection for update KB number and version
- Added detection support for WindowsExperienceFeaturePack updates (e.g. KB4592784)  
- Added wim2swm option to split install.wim into multiple install.swm files  
note: if both wim2esd/wim2swm are 1, install.esd takes precedence over split install.swm
- Added internal support to work with W10MUI.cmd (multilingual distribution script)

8.9:  
- Improved processing for 20H2 Enablement/EdgeChromium package  
- Added support to install v1607 updates for unsupported editions (non Enterprise LTSB)  
- Fixed detection for Adobe Flash Removal Update KB4577586  
- Defender update will not be processed for online live OS

8.8:  
- Added support to integrate Microsoft Defender update (defender-dism-[x86|x64].cab)  
https://support.microsoft.com/en-us/help/4568292  
- Improved integration for 20H2 Enablement/EdgeChromium package

8.7:  
- Implemented specific fixes for build 14393 (WinPE will not be updated with LCU)  
- Enhanced Setup DU updating

8.6:  
- Fixed fail-safe integration using update cab file directly

8.5:  
- Added SkipEdge option for EdgeChromium with Feature Update Enablement Package  
- Fixed cosmetic double image cleanup without EdgeChromium update

8.4:  
- Fixed iso version for 19042 / 20H2

8.3:  
- Defer adding EdgeChromium update after CU  
- Handle Safe OS (WinPE) updates separately  
- Show when setup dynamic update is added  
- Identify updates types as possible  
- winre.wim will not be updated with CU if Safe OS update is detected and added, per Microsoft recommendation  
https://docs.microsoft.com/en-us/windows/deployment/update/media-dynamic-update

8.2:  
- Added differentiation for Win10 20H1 and 20H2

8.1:  
- Enhanced installed updates detection on live online OS

8.0:  
- Fixed offline installation for secure boot update KB4524244

7.9:  
- Updated .NET CU detection for 1809 and later

7.8:  
- Fixed error regarding creating Dism logs

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
</details>
