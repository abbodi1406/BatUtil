# Office 2007 MSI Upsourcer

## Overview

* Automated windows command script to update Office source installation media via slipstream MSP patches, and rebuild setup files

* Include patched setup controller files and necessary VBScript files

* Support updating multiple languages office folders

* It does not support Office Server products or standalone addons and converters, only regular Office Client products

* Make sure Windows Script Host is not disabled or blocked by antivirus program (temporary turn protection OFF if possible)

* Unlocked pack additional features:  
patched `osetup.dll` to bypass installation blocks on unsupported OS  
patched `mso.dll` to bypass phone activation (fill confirmation code with zeros)

______________________________

## Download Required Files

* Service Pack 3 and Updates files

Office 2007 Updates Downloader:  
https://rentry.co/abd-Off2007UpdtDowloader  
https://forums.mydigitallife.net/posts/1804104/  
https://github.com/abbodi1406/WHD/raw/master/scripts/Office2007UpdatesDownloader.zip  
https://gitlab.com/stdout12/adns/uploads/0760498a0476e73dc2e11aa8188a44f1/Office2007UpdatesDownloader.zip  
https://pixeldrain.com/u/pnusDEQv

based on:  
https://forums.mydigitallife.net/posts/1656145/  
https://msfn.org/board/topic/0--/?do=findComment&comment=1167334  
https://msfn.org/board/index.php?showtopic=179482&do=findComment&comment=1167334

or check _Updates.txt inside _bin folder

Make sure to download Proof msp files for all companion languages

- Note:

Office media for some languages include fallback en-us msi files  
therefore, it's required to also download en-us msp files too  
`ClientSharedMUIsp3-en-us, MAINMUIsp3-en-us, KB963671 officehelp-en-us, KB963673 ribbonhelp-en-us`

* Optional:

Office Customization Tool v2 (Admin folder in ISO), include patched oct.dll to load modified xml files

https://github.com/abbodi1406/WHD/raw/master/scripts/Admin2007.7z

______________________________

## How To Use

* Create a work directory on a drive with enough space, use simple short path (example: `C:\OfficeMSI`)

* Extract the downloaded Upsourcer 7z file to work directory

* Extract or copy Office installation media to work directory (next to Upsourcer files)

* Delete the msp and `osetup.dll` files from **Updates** folder if any (because they are obsolete)

* Use Extract_MSP_Office.cmd to extract and organize updates  
https://github.com/abbodi1406/WHD/raw/master/scripts/Extract-MSP-Office_2025-01-05.zip  
mirror: https://mega.nz/folder/Twd2RKBA#gqbgugoOwxR59IiAkI0JGg

* To manually extract updates exe files, run them from command line with `/extract` parameter:  
`file.exe /extract:<extraction_folder> /quiet`

* Copy or move all msp files into "Updates" folder of work directory

* Change `_OfficeUpsourcer2007.cmd` options if needed (see below), then Run as administrator

______________________________

## Options

* By default, the script is set to run attended

it will pause after each step, to allow the user to check and cancel if any errors occur

if want to run it unattended, edit the script and change `set Pause_After_Each_Step=1` to zero 0

* By default, the script will backup original files upon processing, and it's set to remove them at the end when it finish

if you want to keep the original files or remove them yourself, edit the script and change `set Remove_Backups_When_Finished=1` to zero 0

* By default, the script will compress new CAB files using maximum LZX level (same level used for original CAB files)

you may use MSZIP level, which increase files sizes, but it's faster to create and Office installations

if you want to, edit the script and change `set Use_LZX_CAB_Compression=1` to zero 0

* By default, the script is set to insert **PatchAdd** VBScript into each updated msi file

if you do not want this, or plan to use the external `RegisterOfficePatches.cmd` later after installation,  
edit the script and change `set Insert_PatchAdd_VBScript=1` to zero 0

______________________________

## Important Remarks

* If you previously installed Office, or got unsuccessful installation,  
make sure to remove old remnants before running new installation

you can either use OfficeScrubber script, or start command prompt as administrator and run:  
`rd /s /q "%SystemDrive%\MSOCache\All Users" 2>nul`

* Upsourcer script depends on the original name scheme for detecting MSI and MSP files
for MSI files, you must not change any of the files names
for MSP files, you must keep the original name scheme, however, you can add prefix or suffix to the file name

* If any errors occur at any step, you can close the script window, then run the script `_RestoreBackups.cmd`
it will remove any AIP directories and modified files, and restore original files before retry

* To suppress slipstreamed updates, Upsourcer script will insert **PatchAdd** VBScript into each msi file, which will be executed during installation

however, the execution will fail if Windows Script Host is disabled, or antivirus protection program block vbscripts and javascripts

moreover, if you repair or reconfigure Office products, the patches registry keys may get reset or removed

* When that occur or you get Office updates via Windows Update, and to re-register slipstreamed patches,  
run `_bin\Patches\RegisterOfficePatches.cmd`

* If for any reason you want to remove patches registration or you got configuration/uninstallation failures,  
run `_bin\Patches\unRegisterOfficePatches.cmd`

______________________________

## Special Thanks

* Microsoft Windows SDK:  
Windows Installer VBScript Examples files

* @dumpydooby, @yumeyao, @ricktendo64:  
MSI modding expertise

* @Whatever127, @daniel_k:  
Patching PE expertise

* @George King:  
OS requirement check patch for osetup.dll

* @NewEraCracker:  
Offline phone activation patch for mso.dll
