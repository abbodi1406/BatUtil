# Office MSI Upsourcer

- Slipstream patches for Office MSI 2007/2010/2013/2016 and rebuild setup source files

## Introduction

- Most Windows Installer (MSI) programs allows to create administrative installation point (AIP) and apply (preinstall) updates patches to it, then optionally rebuild the msi media files

for example, .NET Framework AIO repacks, VC++ redists, Office 2003 and eariler

https://learn.microsoft.com/en-us/windows/win32/msi/applying-small-updates-by-patching-an-administrative-image

- However, the setup architecture for Office 2007 and later is changed, and that ability is disabled and prevented

https://learn.microsoft.com/en-us/previous-versions/office/office-2007-resource-kit/dd162398(v=office.12)  
https://learn.microsoft.com/en-us/previous-versions/office/office-2010/dd162398(v=office.14)  
https://learn.microsoft.com/en-us/previous-versions/office/office-2013-resource-kit/dd162398(v=office.15)

- Setup does not let you create an administrative installation point (the required sequence table is removed from all msi files)

- None of the digitally signed XML files (Setup.xml and Package.xml) can be edited or altered (i.e. you cannot update new msi/cab files hashes and sizes)

- Setup is required to collect the files and information to orchestrate the installation process (i.e. it's near impossible to install and deploy msi files on their own)

- Applying patches in the correct order if required, updating msi files sequences, and rebuilding cab files is error-prone task

## Concept Guide

* A basic understanding is needed for the msi files and how to modify it  
either using external program like InstEd or Orca, or Windows Installer Scripting Examples VBScript files

https://learn.microsoft.com/en-us/windows/win32/msi/windows-installer-scripting-examples  
https://github.com/microsoft/Windows-classic-samples/tree/main/Samples/Win7Samples/sysmgmt/msi/scripts

* Use simple short path for the work/ and extraction directories. The drive should have at least 10-20 GB of free space

**1) Modify setup controller**

<details><summary>Click to expand</summary>


`osetup.dll` must be patched to allow loading modified setup and package xml files

`setup.exe` must be patched to allow loading modified `osetup.dll`

this can be done with the help of IDA Pro or similar programs
</details>

**2) Modify Setup and Package xml files**

<details><summary>Click to expand</summary>


* required - modify all `setup.xml` files:  
remove signature lines (_SIG and _MODULUS)  
modify all nodes of Setup/LocalCache/File, and replace all MD5/Size elements with empty `""` value (i.e. `MD5="" Size=""`)

* optional - modify all other package xml files (e.g. `ProPlusWW.xml`):  
remove signature lines (_SIG and _MODULUS)  
update `MSIVersion` of Package node with the version of latest service pack (if any)  
this version will be reflected in Add/Remove programs entry
</details>

**3) Restore MSI admin install**

<details><summary>Click to expand</summary>


* note:  
if you are updating multiple products, `Office64WW.*/OWOW64WW.cab` and `Office32WW.*/OWOW32WW.cab` are shared across them all  
to avoid collision with other msi administrative point and to avoid updating WOW files multiple times, it's recommended to temporary move them to new separate folder

* use InstEd/Orca or WiImport.vbs to import AdminExecuteSequence.idt table  
```
Action    Condition    Sequence
s72    S255    I2
AdminExecuteSequence    Action
CostInitialize        490
CostFinalize        630
FileCost        510
InstallValidate        1305
InstallInitialize        1420
InstallAdminPackage        3900
InstallFiles        4000
InstallFinalize        7900
```

* note that Sequence number for each Action should match the number of same Action from InstallExecuteSequence table  
except for InstallFiles, which must be changed to come after InstallAdminPackage

luckily, the Sequence numbers above are the same for all MSI files for all Office 2010/2013/2016

for Office 2007, it's slightly different  
```
Action    Condition    Sequence
s72    S255    I2
AdminExecuteSequence    Action
CostInitialize        800
FileCost        900
CostFinalize        1000
InstallValidate        1300
InstallInitialize        1400
InstallAdminPackage        3900
InstallFiles        4000
InstallFinalize        8000
```

* notice:  
If your host OS is Windows 8 or later, you cannot configure (update) IME msi files for Office 2007/2010, see here for details:  
https://forums.mydigitallife.net/posts/1795044/
</details>

**4) Slipstream Service Pack**

<details><summary>Click to expand</summary>


* for each MSI file, use the following command to create administrative installation point along with integrating SP patches

you must run the command from within the msi file directory, where each msp represent "full path" to msp file  
`start /wait msiexec.exe /a file.msi /quiet TARGETDIR="%cd%" PATCH="msp;msp;msp;..."`

* you can specify all SP msp files together  
Windows Installer will check and apply the applicable patches only, and skip others

logically, you would specify:  
```
all *WW*.msp files for *WW*.msi files  
all *MUI*.msp files for *MUI*.msi files  
Proofing*.msp file for matching lang Proofing.msi file  
Proof*.msp file for matching lang Proof.msi file  
IME*.msp file for matching lang IME*.msi file  
langpack omui/pmui/vismui/xmui msp files for matching lang omui/pmui/vismui/xmui msi files  
```

* sometimes, `Proof*.msp` patches has different Code Page than the Proof.msi file  
in that case, it's required to change `Proof.msi` code page to 0 (neutral), then apply `Proof*.msp` patch  
`cscript WiLangId.vbs Proof.msi Codepage 0`

* sometimes, an old update must be applied before or with service pack patches  
```
examples:
office2010-kb2879953 rmaddlocal-x-none.msp (before or with SP)  
office2007-kb967642 targetdir.msp (before SP)  
office2007 Help updates kb963662 > kb963678 (before SP)
```

* in case you need to apply an update before SP, then you have to:

execute the AIP command specifying the update  
`start /wait msiexec.exe /a file.msi /quiet TARGETDIR="%cd%" PATCH="updatemsp"`

use InstEd/Orca to change msi file Summary Info / Image Type (source files) to `External tree, long filenames`, or use WiSumInf.vbs  
`cscript WiSumInf.vbs file.msi Words=0`

execute new AIP command specifying SP patches, change `TARGETDIR` location  
then copy the updated files to the first "current" location, and remove redundant new location  
```
start /wait msiexec.exe /a file.msi /quiet TARGETDIR="%cd%\Z" PATCH="msp;msp;msp;..."
xcopy /CIDERY "%cd%\Z\*" "%cd%\"
rd /s /q "%cd%\Z"
```
</details>

**5) Slipstream Updates**

<details><summary>Click to expand</summary>


* similar to Service Pack, gather patches relatively for msi files:  
```
all x-none msp files for *WW*.msi files  
all lang msp files for *MUI*.msi files  
Proof*.msp file for matching lang Proof.msi file
```

* note:  
you cannot specify more than 127 patch together  
https://learn.microsoft.com/en-us/windows/win32/msi/installing-multiple-patches

* some x-none msp files apply to few `*MUI*.msi` files, usually one of those:  
`mstore, ose, osetup, targetdir`

* note:  
office2010-kb2879953 and ocfxca2010-kb2553347 apply to all Office 2010 msi files  
patchca2016-kb2920716 apply to all Office 2016 msi files

* if you already created AIP and applied Service Pack, then you need to use the "TARGETDIR new location, copy updated files, remove new location" procedure to apply updates:  
```
start /wait msiexec.exe /a file.msi /quiet TARGETDIR="%cd%\Z" /p "msp;msp;msp;..."
xcopy /CIDERY "%cd%\Z\*" "%cd%\"
rd /s /q "%cd%\Z"
```
</details>

**6) Replace original `osetup.dll` and `setup.exe`**

<details><summary>Click to expand</summary>


* msi files that represent main products include and install `osetup.dll` and `setup.exe` (and `psetup.dll` for Proofing Tools Kit)

these files must be replaced either in the AIP directories with modified (hacked) files, or must be replaced after installation  
otherwise, you cannot repair or uninstall Office

example location in AIP directories:  
```
"FILES\PFILES\COMMON\MSSHARED\OFFICE12\Office Setup Controller\"
"FILES\Program Files\Common Files\Microsoft Shared\OFFICE14\Office Setup Controller\"
```
example location after installation:  
```
"%ProgramFiles%\Common Files\Microsoft Shared\OFFICE12\Office Setup Controller\"
"%ProgramFiles(x86)%\Common Files\Microsoft Shared\OFFICE14\Office Setup Controller\"
```
</details>

**7) Create MakeCAB DDF directives**

<details><summary>Click to expand</summary>


* this is the hardest part for rebuilding cab files

* applied patches can change File Sequence table for existing files, or add new files with new Sequence  
and sometimes, the sequences collide (duplicated)  
msi Media table must be also updated to represent correct LastSequence for the files

* original `WiMakCab.vbs` is probably the only reliable way to automate that, but it has limitations and will not work for all msi files

specifically, it does not support Media multiple cab files (e.g. `ProPsWW.cab` and `ProPsWW2.cab` for ProPlus)

it also specify and change the Media cab file based on the supplied base name

its "/S" parameter to re-sequence file table is also not optimal and can go out of range for big products (because it start count from highest sequence)

* here is a custom modified WiMakCabs.vbs which hopefully solve those limitations

https://github.com/abbodi1406/WHD/raw/master/scripts/WiMakCabs.zip

usage:  
```
cscript WiSumInf.vbs file.msi Words=0
cscript WiMakCabs.vbs file.msi new /U /L
```
</details>

**8) Create new CAB files**

<details><summary>Click to expand</summary>


* make sure to rename or move original cab files

* simply use makecab.exe for each created directive  
`makecab.exe /V0 /F file.ddf >nul`
</details>

**9) Remove administrative installation directories**

<details><summary>Click to expand</summary>


* after successfully creating cabs, now you need to remove the AIP directories

i.e. any new created subdirectory (don't remove original subfolders)

you can save this as .bat file and run it in the root extracted Office media  
```
@echo off
for /r %%# in (*MUI*.msi *Proof.msi *Proofing.msi *WW.msi) do (
pushd "%%~dp#"
rd /s /q "FILES\" 2>nul
rd /s /q "GAC_MSIL\" 2>nul
rd /s /q "PFiles\" 2>nul
rd /s /q "Program Files\" 2>nul
rd /s /q "Program Files (x86)\" 2>nul
rd /s /q "IDE\" 2>nul
rd /s /q "COMMON\" 2>nul
rd /s /q "GlobalAssemblyCache\" 2>nul
rd /s /q "Windows\" 2>nul
popd
)
```

* if you moved Office WOW files, copy or move updated files to original directories (e.g. `ProPlus.WW`)
</details>

## Pros

<details><summary>Click to expand</summary>


* Freshly install up-to-date Office products, saving time and resources of installing updates afterward

* Reduce and eliminate wasted disk space for the cached MSP patches and backup directory `C:\Windows\Installer\$PatchCache$`
</details>

## Cons

<details><summary>Click to expand</summary>


* Updating Office MSI files this way will apply all the updated files / components / registry with the patches, except registering patches themselves as installed

Windows Update can recognize the slipstreamed service packs, but it will not recognize any or most of the slipstreamed regular updates

* A simple solution for the EOS products like Office 2007/2010/2013, is to just ignore and hide all the offered updates (as long as you correctly added them all)

or, slipstream the last service pack, and install post updates regularly

* A proper solution is to use VBScript file that scan installed Office msi files and register any slipstreamed patches

https://github.com/abbodi1406/WHD/raw/master/scripts/RegisterSlipstreamedPatches.zip

the script rely on the fact that each slipstreamed msp adds two unique properties in the msi file which represent its `PatchGUID` and `PatchFamily`  
the GUID can be used to register the patch as installed based on the ProductCode GUID of the msi file

example:  
```
Patch._C444285D_5E4F_48A4_91DD_47AAAA68E92D_.isMinorUpgrade    0
_C444285D_5E4F_48A4_91DD_47AAAA68E92D_    Patch;targetdir;12.0.6341.5001

ProductCode    {90120000-0030-0000-0000-0000000FF1CE}
```

can be used to add these registry keys (GUIDs are in compressed format)  
```
[HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Installer\Products\00002109030000000000000000F01FEC\Patches]
; REG_MULTI_SZ that contain compressed GUIDs of all applied patches
"Patches"=""

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\00002109030000000000000000F01FEC\Patches\D582444CF4E54A8419DD74AAAA869ED2]
"State"=dword:00000001
"MSI3"=dword:00000001
"PatchType"=dword:00000000
"LUAEnabled"=dword:00000000
"Uninstallable"=dword:00000000

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Patches\D582444CF4E54A8419DD74AAAA869ED2]
"LocalPackage"="C:\\Windows\\Installer\\fffff.msp"
```

WU detection does not need fffff.msp file to exist  
however, if you want to repair or change Office installation, the file must exist, you can use one small office msp file for all patches
</details>
