# Office 2016 MSI Upsourcer

## Overview

* Automated windows command script to update Office source installation media via slipstream MSP patches, and rebuild setup files

* Include patched setup controller files and necessary VBScript files

* Support updating multiple languages office folders

* It does not support Office Server products or standalone addons and converters, only regular Office Client products

* Make sure Windows Script Host is not disabled or blocked by antivirus program (temporary turn protection OFF if possible)

______________________________

## Download Required Files

* Updated binaries

Since Office 2016 is still not reached EOS, "suppress updates" vbscripts will need constant (monthly) updating

therefore, make sure to download this zip file which contain the latest up-to-date scripts:  
http://tiny.cc/SuppressPatches2016

extract it, then move the new scripts into `_bin` folder and overwrite the current files, before running Upsourcer script

* Updates

Use WHDownloader to download the updates  
https://forums.mydigitallife.net/forums/whdownloader.56/  
https://www.mediafire.com/file/ootxxrbhw73wt4h/WHDownloader_0.0.2.4.zip/file

or check these text files for manual links  
https://github.com/abbodi1406/WHD/raw/master/files/Office2016-x64.txt  
https://github.com/abbodi1406/WHD/raw/master/files/Office2016-x86.txt

- Note:

Project and Visio updates are also applicable (required) for other Office products
to get proper result, make sure to download all updates

______________________________

## How To Use

* Create a work directory on a drive with enough space, use simple short path (example: `C:\OfficeMSI`)

* Extract the downloaded Upsourcer 7z file to work directory

* Extract or copy Office installation media to work directory (next to Upsourcer files)

* Use Extract_MSP_Office.cmd to extract and organize updates  
https://github.com/abbodi1406/WHD/raw/master/scripts/Extract-MSP-Office_2025-01-05.zip  
mirror: https://mega.nz/folder/Twd2RKBA#gqbgugoOwxR59IiAkI0JGg

* To manually extract updates exe files, run them from command line with `/extract` parameter:  
`file.exe /extract:<extraction_folder> /quiet`

* Copy or move all msp files into "Updates" folder of work directory

* Change `_OfficeUpsourcer2016.cmd` options if needed (see below), then Run as administrator

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

* Upsourcer script does not verify the architecture (bitness) of msp files  
make sure to download the correct files matching your Office media architecture (x86 or x64, not both)

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

* Not all msi files can be updated and not for all langs, for those, the associated cab files will remain unchanged

______________________________

## Special Thanks

* Microsoft Windows SDK:  
Windows Installer VBScript Examples files

* @dumpydooby, @yumeyao, @ricktendo64:  
MSI modding expertise

* @Whatever127, @daniel_k:  
Patching PE expertise
