# Windows 7 Multilingual Distribution Creator

* A mostly automated way to add language packs to Windows 7 SP1 distribution, resulting a multilingual ISO, including:
- Choice of language at setup
- Languages packs preinstalled so that you can switch between them in Windows.
- Multilingual Windows Recovery Environment (if standard WinPE localization is on)

* Only Ultimate and Enterprise Editions has the ability to change the display language normally after install

* Supports updating one-architecture distributions (x86 or x64), or custom AIOs that have both architectures together in one install.wim

## Requirements:

* Working Environment: Windows 7 or later with at least 15GB of free space.

* Windows 7 SP1 distribution (ISO file, DVD/USB, ISO extracted to folder).

* Windows 7 SP1 Languages Packs matching the distribution architecture(s).

* If you want the Standard WinPE localization, [Windows AIK Supplement for Windows 7 SP1](http://www.microsoft.com/downloads/en/details.aspx?FamilyID=0aee2b4b-494b-4adc-b174-33bc62f02c5d)

## How To:

* Step 1
	> Create a directory on a partition with enough space on it (at least 15 GB), depending on the number of LPs you are adding (e.g. C:\MUIDVD), and extract this package to the directory your created.

* Step 2
	> Place language packs files in "Langs" folder. You can use the original .exe files, or manually converted .cab files

* Step 3
	> If you want the Standard WinPE localization, place waik_supplement iso in "winpe" folder. 

* Step 4
	> Edit the script with notepad and adjust the following variables to suite your needs, or leave it as-is:

**DVDPATH**

Path for Windows 7 sp1 distribution (without quotation marks)

you can use the iso file path directly, or path to custom extracted folder, or DVD/USB dive letter.

leave it blank if you want to use iso file placed next to the script, or prompted to enter path.

**ISO** (set 1 or 0)

Create iso file afterwards or not

**WINPE** (set 1 or 0)

when enabled "1":

require WinPE lang packs from WAIK supplement, winre.wim and boot.wim will be updated.

when disabled "0":

boot.wim index 2 (setup image) will be updated manually with setup resources found in the main lang pack.

when adding East-Asian lang, both boot.wim indices will be updated with font support

**SLIM** (set 1 or 0)

when disabled "0":

all applicable WinPE lang packs will be added to boot.wim and winre.wim

all lang resources files will be added to ISO sources directory and keep it as default.

when enabled "1":

only necessary WinPE LPs for setup/recovery will be added to boot.wim and winre.wim (Main, Setup, SRT).

ISO payload files will be deleted, and keep required files for boot-setup (iso can be used only for clean install).

**DEFAULTLANGUAGE**

culture code of the default language that will be set in the Windows images and as initial setup language

it will be changed later when/if you choose another language at setup

leave it blank if you want to keep the current default language in install image.

**MOUNTDIR**

Optional, set mount directory on another partition if available to speed integration, or leave it blank

* Step 5
	> Verify that all your settings are correct and that the required files are in the proper location. Then, execute the script as Administrator.

	> The process will take quite some time to finish depending on number of LPs to add, so WAIT. If all went OK, You will get the "Done" message after all is finished.

	> The new multilingual ISO can be found in the same directory besides the script. If you choose not to create iso file, the distribution folder "DVD" will remain after you close the script.

## Remarks:

* to spare yourself the trouble, keep the work directory path short, do not use spaces and do not use non-ASCII characters. 

* Language files, codes and architecture will be determined based on the detected files in "Langs" folder

* Security update KB2883457 for System Recovery Tools (WinSRT) will be added to winre.wim and boot.wim. If you do not want it, simply delete the two cab file in "bin" folder after extracting this package.
