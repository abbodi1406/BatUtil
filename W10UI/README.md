# Windows 10 Updates Installer

Automated batch script to install/integrate Windows 10 Updates

## Features:

* Supported targets:
- Current Online OS
- Offline image (already mounted directory, another partition)
- Distribution folder (extracted iso, copied dvd/usb)
- Distribution Drive (virtual mounted iso, inserted dvd)
- WIM file directly

* Supports having updates in one folder:
- Detect and install servicing stack update first
- Skip installing non-winpe updates for boot.wim/winre.wim (flash, oobe, .net 4.x)
- Skip installing Adobe Flash update for Server Core or if the package is removed
- Handle dynamic updates for setup media 'sources' folder (skip installing it, extract it for distribution target)

* Enable .NET Framework 3.5 if available source detected

checked locations: mounted iso, inserted dvd/usb, sxs folder for distribution target

* Detect Windows 10 ADK [Deployment Tools](https://msdn.microsoft.com/en-us/windows/hardware/dn913721.aspx) for offline integration

## Limitations:

* Updates version will not be checked for applicability

meaning for example, if 10240 updates are specified for 10586 target, the script will proceed to install them

be sure to specify the correct updates files

* These extra updates are not processed correctly

RSAT: KB2693643

Media Feature Packs: KB3010081, KB3099229, KB3133719, KB4016817

the script will try to install them whether applicable, already installed or not

avoid using them with the script and install them manually

## How to:

* Recommended Host OS: Windows 8.1 or later

* Optional: place W10UI.cmd next to the updates (.msu/.cab) to detect them by default

* Run the script as administrator

* Change the options to suit your needs, make sure all are set correctly, do not use quotes marks "" in paths

* Press zero '0' to start the process

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

M. Mount Directory

mount directory for updating wim files, default is on system drive C:\

available only if the target is a distribution folder, or WIM file

E. Extraction Directory

directory for temporary extracted files, default is on the same drive as the script

## Manual options (for advanced users):

Edit the script with notepad (or text editor) to change

* net35source

specify custom "folder" path for microsoft-windows-netfx3-ondemand-package.cab

* iso

create new iso file if the target is a distribution folder

require ADK installed, or placing oscdimg.exe or cdimage.exe next to the script

* delete_source

keep or delete DVD distribution folder after creating updated ISO

* autostart

start the process automatically once you execute the script

* you can also change the default value of main Options

examples:

set specific folder as default updates location

set custom dism.exe path on Windows 8.1

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
