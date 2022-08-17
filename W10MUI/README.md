# Windows 11/10 Multilingual Distribution Creator

* A mostly automated script to add language packs to Windows 11/10 distribution, resulting a multilingual ISO, including:  
- Choice of language at setup
- Languages packs preinstalled so that you can switch between them in the system
- Multilingual Windows Recovery Environment with a choice of language at boot (if standard WinPE localization is on)
- Preinstalled/Reinstalled latest updates

* Supports any Windows 11/10 build starting 10240

* Supports the normal language packs (cab) files, or the new language packs (esd) files (available from UUP source since build 15063)

* Distributions that have install.esd are not supported (esd file is not serviceable), this includes ISOs created by Media Creation Tool

* Supports updating one-architecture distributions (x86 or x64), or custom AIOs that have both architectures together in one install.wim

* Two-architecture distributions created by esd-decrypter-wimlib are not supported directly
however, if it's created using option:
- 2 separate install.wim, you can update each file separately by choosing x86 or x64 folder as distribution path
- 1 combined install.wim, you can update it with W10MUI_Mini.cmd script

______________________________

## Notes:

* If the distribution already contain installed updates (e.g. refreshed ISO media), it's required/recommended to add the latest updates after language packs

* Since version 1809 (build 17763), regular windowsupdate links for cab files are no longer available

instead, you need to download the required files from UUP source

* UUP links depends on Update ID to fetch the files from Microsoft servers

sometimes, those Update IDs stop working or get removed by Microsoft

the LangPacks/OnDemand files themselves are the same for all releases of the same build number

* To get new ID, or if links for 17763 and later stop working:

- visit [uupdump.ml](https://uupdump.ml/)

- in "Search for builds" box, type the needed build number (e.g. 19041) and press Enter (or click the blue button)

- from the listed builds, open one of them matching your needed Architecture

- in "Search files" box on the right, type the word (language) followed by space, then your Lang ID  
example: language fr-fr

- click the blue search button (or press Enter)

- download the listed files, then download and run File renaming script

______________________________

## Requirements:

* Working Environment: Windows 8.1 or later with at least 15 GB of free space.

* Windows 11/10 distribution (ISO file, DVD/USB, ISO extracted to folder).

* Windows 11/10 Language Packs, matching the distribution build version

* Windows 11/10 OnDemand Packs if available (Optional, recommended).

* Windows 11/10 Updates msu/cab files (Optional, recommended).

* If you want the Standard WinPE localization:

Windows 11/10 ADK (Deployment Tools & Preinstallation Environment).

<details><summary>ADK Links</summary>


- Build 22621 - Windows 11 version 22H2:
```
https://download.microsoft.com/download/6/7/4/674ec7db-7c89-4f2b-8363-689055c2b430/adk/adksetup.exe
https://download.microsoft.com/download/5/2/5/525dcde0-c7b8-487a-894d-0952775a78c7/adkwinpeaddons/adkwinpesetup.exe

full ISO  
https://software-static.download.prss.microsoft.com/dbazure/888969d5-f34g-4e03-ac9d-1f9786c66749/22621.1.220506-1250.ni_release_amd64fre_ADK.iso
https://software-static.download.prss.microsoft.com/dbazure/888969d5-f34g-4e03-ac9d-1f9786c66749/22621.1.220506-1250.ni_release_amd64fre_adkwinpeaddons.iso
```

- Build 22000 - Windows 11 version 21H2:
```
https://download.microsoft.com/download/1/f/d/1fd2291e-c0e9-4ae0-beae-fbbe0fe41a5a/adk/adksetup.exe
https://download.microsoft.com/download/5/5/e/55e3e34a-5708-46cd-a90d-92044c29336b/adkwinpeaddons/adkwinpesetup.exe

full ISO  
https://software-download.microsoft.com/download/sg/22000.1.210604-1628.co_release_amd64fre_ADK.iso
https://software-download.microsoft.com/download/sg/22000.1.210604-1628.co_release_amd64fre_adkwinpeaddons.iso
```

- Build 20348 - Windows Server 2022:
```
https://download.microsoft.com/download/b/9/8/b98fd877-f00f-49e3-8abb-77784cdae268/adk/adksetup.exe
https://download.microsoft.com/download/8/3/8/838d6e29-eaac-498b-82ad-5fbac20136f8/adkwinpeaddons/adkwinpesetup.exe

full ISO  
https://software-download.microsoft.com/download/sg/20348.1.210507-1500.fe_release_amd64fre_ADK.iso
https://software-download.microsoft.com/download/sg/20348.1.210507-1500.fe_release_amd64fre_adkwinpeaddons.iso
```

- Build 19041 - Windows 10 versions 2004-22H2:  
```
https://download.microsoft.com/download/8/6/c/86c218f3-4349-4aa5-beba-d05e48bbc286/adk/adksetup.exe
https://download.microsoft.com/download/3/c/2/3c2b23b2-96a0-452c-b9fd-6df72266e335/adkwinpeaddons/adkwinpesetup.exe

full ISO  
https://software-download.microsoft.com/download/pr/19041.1.191206-1406.vb_release_amd64fre_ADK.iso
https://software-download.microsoft.com/download/pr/19041.1.191206-1406.vb_release_amd64fre_adkwinpeaddons.iso
```

- Build 18362 - Windows 10 versions 1903-1909:  
```
https://download.microsoft.com/download/B/E/6/BE63E3A5-5D1C-43E7-9875-DFA2B301EC70/adk/adksetup.exe  
https://download.microsoft.com/download/E/F/A/EFA17CF0-7140-4E92-AC0A-D89366EBD79E/adkwinpeaddons/adkwinpesetup.exe

full ISO  
https://software-download.microsoft.com/download/pr/18362.1.190318-1202.19h1_release_amd64fre_ADK.iso  
https://software-download.microsoft.com/download/pr/18362.1.190318-1202.19h1_release_amd64fre_adkwinpeaddons.iso
```

- Build 17763 - Windows 10 version 1809:  
```
https://download.microsoft.com/download/0/1/C/01CC78AA-B53B-4884-B7EA-74F2878AA79F/adk/adksetup.exe  
https://download.microsoft.com/download/D/7/E/D7E22261-D0B3-4ED6-8151-5E002C7F823D/adkwinpeaddons/adkwinpesetup.exe

full ISO  
https://software-download.microsoft.com/download/pr/17763.1.180914-1434.rs5_release_amd64fre_ADK.iso  
https://software-download.microsoft.com/download/pr/17763.1.180914-1434.rs5_release_amd64fre_ADKwinpeaddons.iso
```

- Build 17134 - Windows 10 version 1803:  
```
https://download.microsoft.com/download/6/8/9/689E62E5-C50F-407B-9C3C-B7F00F8C93C0/adk/adksetup.exe

full ISO  
https://software-download.microsoft.com/download/pr/17134.1.180410-1804.rs4_release_amd64fre_ADK.iso
```

- Build 16299 - Windows 10 version 1709:  
```
https://download.microsoft.com/download/3/1/E/31EC1AAF-3501-4BB4-B61C-8BD8A07B4E8A/adk/adksetup.exe

full ISO  
https://download.microsoft.com/download/3/1/E/31EC1AAF-3501-4BB4-B61C-8BD8A07B4E8A/16299.15.170928-1534.rs3_release_amd64fre_ADK.iso
```

- Build 15063 - Windows 10 version 1703:  
```
https://download.microsoft.com/download/5/D/9/5D915042-FCAA-4859-A1C3-29E198690493/adk/adksetup.exe

full ISO  
https://download.microsoft.com/download/5/D/9/5D915042-FCAA-4859-A1C3-29E198690493/15063.0.170317-1834.rs2_release_amd64fre_ADK.iso
```

- Build 14393 - Windows 10 version 1607:  
```
https://download.microsoft.com/download/9/A/E/9AE69DD5-BA93-44E0-864E-180F5E700AB4/adk/adksetup.exe
```
</details>

______________________________

## How To:

* Step 1
	> Create a directory on a partition with enough space on it (at least 15 GB), depending on the number of LPs you are adding (e.g. C:\MUIDVD), and extract this package to the directory your created.

* Step 2
	> Place language packs (cab/esd) files in "Langs" folder.  
	> Place ondemand packs (cab) files in "OnDemand\x86" or "OnDemand\x64" folder (based on architecture).

* Step 3
	> Place updates (msu/cab) files in "Updates" folder (you can add both architecture files together).  
edit Updates\W10UI.ini to change the updates options, but don't change Target or Repo (leave them blank)

* Step 4
	> Edit the script with notepad and adjust the following variables to suite your needs, or leave it as-is:

**DVDPATH**

Path for Windows 11/10 distribution (without quotation marks)

you can use the iso file path directly, or path to custom extracted folder, or DVD/USB dive letter.

leave it blank if you want to use iso file placed next to the script, or prompted to enter path.

**ISO** (set 1 or 0)

Create iso file afterwards or not

**WINPE** (set 1 or 0)

when enabled "1":

require WinPE lang packs from ADK (Preinstallation Environment), winre.wim and boot.wim will be updated

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

**NET35** (set 1 or 0)

Enable .NET Framework feature or not

if you enable it, microsoft-windows-netfx3-ondemand-package.cab file will be removed from iso\sources\sxs afterwards

**WINPEPATH**

optional, custom directory path for WinPE language packs files, in case you do not want to install whole ADK WinPE feature

you must keep the same directory hierarchy as original installed ADK

then you set the parent WinPE directory as path:  
`set WINPEPATH=C:\MUIDVD\WinPE`

leave it blank to auto detect the path for WinPE folder in the script current directory 

example:

x64 German files:  
`C:\MUIDVD\WinPE\amd64\WinPE_OCs\de-de`

x86 Arabic files:  
`C:\MUIDVD\WinPE\x86\WinPE_OCs\ar-sa`

**DEFAULTLANGUAGE**

culture code of the default language that will be set in the Windows images and as initial setup language

it will be changed later when/if you choose another language at setup

leave it blank if you want to keep the current default language in install image.

**MOUNTDIR**

optional, mount directory on another partition if available to speed integration, or leave it blank

* Step 5
	> Verify that all your settings are correct and that the required files are in the proper location. Then, execute the script as Administrator.

	> The process will take quite some time to finish depending on number of LPs to add, so WAIT. If all went OK, You will get the "Finished" message.

	> The new multilingual ISO can be found in the same directory besides the script. If you choose not to create iso file, the distribution folder "DVD" will remain after you close the script.

______________________________

## Remarks:

* Build version will be determined based on install.wim file

* Language files, codes and architecture will be determined based on the detected files in "Langs" folder

* All detected files in "OnDemand" folder will be added as supplementary packges

* to spare yourself the trouble, keep the work directory path short, do not use spaces and do not use non-ASCII characters. 
