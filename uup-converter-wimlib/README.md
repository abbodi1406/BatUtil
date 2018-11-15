# UUP -> ISO Converter ft. WimLib

* Automated windows command script to process Microsoft Windows 10 Unified Update Platform files, allowing to build/convert them into a usable state (ISO / WIM).

* You can get UUP files by performing upgrade from Windows 10 build to later build (starting 15063).

* You can also obtain UUP canonical source using one of these projects:
- [UUP dump website](https://uupdump.ml/)
- [UUP dump downloader](https://gitlab.com/uup-dump/downloader/)
- [UUPDL](https://gitlab.com/uup-dump/uupdl/)
- [UUP Generation Project](https://uup.rg-adguard.net/)

## Remarks

* Administrator privileges are required to run the script

* Creating normal boot.wim from UUP require Windows 10 host OS, or installed Windows 10 ADK (Deployment Tools).

otherwise, you will get winre.wim acting as setup boot.wim, without recovery options

- If the upgrade is done via Express UUP (multiple expanded folders in the download directory), you need to perform the UUP > ISO operation before starting the upgrade process (before first restart).

to do so, when WU prompt you to restart, start convert-UUP.cmd and paste the path to download directory, example:

`C:\Windows\SoftwareDistribution\Download\07172dda91861218ecc095600216d792`

Alternatively, if you are testing in VM machine or have multi boot systems, you can choose to Shut down/Restart the system without upgrading.

on Desktop, press Alt+F4 and choose option without Update.

[example](https://i.imgbox.com/vxZLhGPM.png)

## How To Use

- Optional: temporary disable AV or protection program so it doesn't interfere with the process.

- Make sure the files are not read-only or blocked.

- Extract this pack to a folder with simple spaceless path to avoid troubles (example: C:\UUP).

- Place the files in "UUPs" folder to be detected automatically.

Alternatively, you will be prompted to enter other UUP folder path.

- If multiple Editions detected, you will be prompted first to select one of them, or create AIO.

- To exit of the prompt or options menu just press "Enter".

#### Options:

1 - Create ISO with install.wim

4 - Create ISO with install.esd

convert UUP files to a regular ISO distribution that contains install.wim or install.esd file.

2 - Create install.wim

5 - Create install.esd

create install.wim/install.esd file only, which can be used with other ISO with the same version, or for manual apply using dism/wimlib.

3 - UUP Edition info

Display info about detected editions (architecture, language, build version, build branch, editions name).

#### Manual Options

for advanced users, edit convert-UUP.cmd to change the default value

**AutoStart**

If you want to start the conversion process directly without prompts.

By default this will create ISO with install.wim. For multiple UUP editions it will create AIO ISO with install.wim.

to do so, change "SET AutoStart=0" to "SET AutoStart=1"

**SkipISO**

If you are not interested to create ISO file currently, or intend to create Multi-Architecture ISO (x86/x64) later with multi_arch_iso.cmd

to do so, change "SET SkipISO=0" to "SET SkipISO=1"

**SkipWinRE**

If you are not interested to have recovery environment or want to reduce ISO size/conversion period.. etc, it is possible to skip adding winre.wim to install.wim/install.esd

to do so, change "SET SkipWinRE=0" to "SET SkipWinRE=1"

p.s. adding winre.wim to install.esd will consume high amount of CPU/RAM

**RefESD**

If you plan to use your local UUP source repeatedly, you can choose to keep converted reference ESD files for future operations instead converting them each time.

to do so, change "SET RefESD=0" to "SET RefESD=1"

if UUP source is Express, Reference ESDs and Edition ESDs will be copied to new folder "CanonicalUUP". Practically, this convert/backup Express UUP source to Canonical

if UUP source is Canonical, Reference ESDs will be copied to the same UUP source folder. Original CAB files will be moved to subdirectory "Original"

## Multi-Architecture ISO (x86/x64)

**How to:**

- Optional: if you do not intend to keep single architecture ISOs, edit convert-UUP.cmd and SET SkipISO=1

- Use convert-UUP.cmd to create two ISO distributions, one for x64 and another for x86. You may select the desired editions to include in each one

- Run multi_arch_iso.cmd and choose the option that suits you

**Options:**

1 - Create ISO with 1 combined install.wim/install.esd

create a custom ISO structure with 1 install.wim/install.esd for all x64/x86 images, and slighlty modified bootx64.wim/bootx86.wim to allow coexistence

2 - Create ISO with 2 separate install.wim/install.esd

create the same ISO structure as Media Creation Tool with 2 separate install.wim/install.esd for each architecture

**Notes:**

- To preserve source single-architecture distributions folders edit multi_arch_iso.cmd and SET Preserve=1

- If the installation file is install.esd, be aware that option 1 will require high amount of CPU/RAM to unify install.esd files

- multi_arch_iso.cmd can be used also to create multi-architecture ISO from any similar Windows x64/x86 ISO distributions, starting Windows 7 SP1

however, option 2 require Windows 10 setup files

## Virtual Editions

**Info:**

- Starting WIP build 17063, Windows 10 regular editions have been unified into two base editions:

Home & Pro (with their variants Home N & Pro N)

Home China edition still separate

- According to that, UUP will only deliver installation files for above editions only

- The following editions are now exist as "virtual upgrade editions" with base editions:

with Home : Home Single Language

with Pro  : Enterprise, Education, Pro Education, Pro for Workstations, Enterprise for Remote Desktops

with Pro N: Enterprise N, Education N, Pro Education N, Pro N for Workstations

- Therefore, the extra script is to help create these virtual editions for UUP source

**How to:**

- Optional: if you do not intend to keep converted ISO, edit convert-UUP.cmd and SET SkipISO=1

- Use convert-UUP.cmd to create the converted ISO distribution file/folder

- Run create_virtual_editions.cmd and choose the desired option from menu

**Options:**

1 - Create all editions

create all possible target virtual editions

2 - Create one edition

create one of the target virtual editions

3 - Create randomly selected editions

create some of the target virtual editions

**Notes:**

- To preserve source distribution folder, edit create_virtual_editions.cmd and set Preserve=1

- If you do not need to keep source editions (example: create Enterprise and delete Pro), edit create_virtual_editions.cmd and set DeleteSource=1

## Credits

* [mkuba50](https://gitlab.com/users/mkuba50) - UUP dump
* [Eric Biggers](http://wimlib.net) - wimlib
* [Igor Pavlov](https://www.7-zip.org/) - 7-zip
* [erwan.l](http://reboot.pro/files/file/313-offlinereg) - offlinereg
* [cdob](http://reboot.pro/topic/20471-windows-pe-5x-boot-problem) - create aio efisys.bin
* [@rgadguard](https://twitter.com/rgadguard) - initial script and co-enhancing
* Special thanks to: @Enthousiast, @Ratiborus58, @NecrosoftCore, @DiamondMonday, @WzorNET
* cdimage and imagex are intellectual property of Microsoft Corporation.
