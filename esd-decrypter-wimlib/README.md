# ESD -> ISO Decrypter ft. WimLib

* Automated windows command script to process Microsoft's full ESD file (encrypted or decrypted),to convert it into a usable state (ISO / WIM / decrypted ESD).

## Remarks

* Administrator privileges are required to run the script

* The script is set to not backup encrypted ESD before decrypting it, which will change the file hash

if you want to maintain the original file state, turn the backup ON by pressing 9 before proceeding to other operations.

## How To Use

* Optional: temporary disable AV or protection program so it doesn't interfere with the process.

* Make sure the ESD file is not read-only or blocked.

* Extract this pack to a folder with simple path to avoid troubles (example: C:\ESD).

* Optional: to get accurate ISO file name for refreshed ESDs, edit **decrypt.cmd** and `set ISOnameESD=1`  
warning, for this to work, ESD name must be the original, with or without sha1 hash suffix

* You may start the process with any of these ways:  
- Copy/Move ESD file to the same folder besides the script, then run decrypt.cmd

- Drag & drop ESD file on decrypt.cmd

- Directly run decrypt.cmd and you will be prompted to enter the ESD file path

- Open Admin Command Prompt in the current directory, and Execute: decrypt ESDFileNameAndPath

examples:  
```
decrypt 15063.0.170317-1834.rs2_release_cliententerprise_vol_x86fre_en-us_dc818e39982d8bd922dca73fd51e330aa99bc3f1.esd`

decrypt C:\RecoveryImage\install.esd

decrypt H:\ESD\ir4_cpra_x64frer_en-us.esd
```

#### Multi Editions ESD Options

* If the choosen ESD contains multiple editions, you will get these options:

1 - Continue including all editions

2 - Include one edition

3 - Include consecutive range of editions

4 - Include randomly selected editions

* To disable this menu and go to main menu directly, edit decrypt.cmd and change "SET MultiChoice=1" to "SET MultiChoice=0"

#### Main Menu Options

1 - Create ISO with Standard install.wim

2 - Create ISO with Compressed install.esd

convert ESD to a regular ISO distribution that contains install.wim or install.esd file

3 - Create Standard install.wim

4 - Create Compressed install.esd

create install.wim/install.esd file only, which can be used with other ISO with the same version, or for manual apply using dism/wimlib

5 - Decrypt ESD file only

if the file is encrypted

5 - ESD file info

if the file is not encrypted

## Multi-Architecture ISO (x86/x64)

**How to:**

- Get 2 ESDs with different architectures, same language, same version (i.e. both en-us build 16299)
- Put the ESD files next to decrypt.cmd
- Run decrypt.cmd directly, and choose an option that suits you

**Options:**

1 - ISO with 2 separate install.esd

create the same ISO structure as Media Creation Tool with 2 separate solid install.esd for each architecture

2 - ISO with 2 separate install.wim

create the same ISO structure as Media Creation Tool with 2 separate standard install.wim for each architecture

3 - ISO with 1 combined install.wim

create a custom ISO structure with 1 install.wim for all x64/x86 images, and slighlty modified bootx64.wim/bootx86.wim to allow coexistence

**Notes:**

- This feature in decrypt.cmd will include all editions in the 2 ESD files

if you want to create an ISO for some selected editions, see "Edition-Specific Multi-Architecture ISO" below

- ISO created with options 1 or 2 support these boot modes:

BIOS: x64 (64bit) & x86 (32bit)

UEFI: x64 (64bit) only

- ISO created with option 3 support these boot modes:

BIOS: x64 (64bit) & x86 (32bit)

UEFI: x64 (64bit) & x86 (32bit)

- For ISO created with option 3 (Custom AIO), on installation, select an edition architecture that matches the selected architecture in boot screen

Windows 10 Setup (64-bit) -> Windows 10 Pro x64

Windows 10 Setup (32-bit) -> Windows 10 Home N x86

- For ISO created with option 3 (Custom AIO), if you want to start the recovery environment (Repair your computer), at language selection window, press Shift + F10 keys to launch command prompt, then type:

`recovery\recenv.exe`

- Limitation: ISO created with option 3 (Custom AIO), will be valid only for clean installation from boot, no upgrades
 
## Edition-Specific Multi-Architecture ISO (x86/x64)

**How to:**

- Optional: if you do not intend to keep single architecture ISOs, edit decrypt.cmd and SET SkipISO=1

- Use decrypt.cmd to create two ISO distributions, one for x64 and another for x86 and select the desired editions to include in each one

- Run multi_arch_iso.cmd and choose the option that suits you

**Options:**

1 - Create ISO with 1 combined install.wim/.esd

create a custom ISO structure

with 1 install.wim/install.esd for all x64/x86 images, and slighlty modified bootx64.wim/bootx86.wim to allow coexistence

2 - Create ISO with 2 separate install.wim/.esd (Win 10)

create the same ISO structure as Media Creation Tool

with 2 separate install.wim/install.esd for each architecture

**Notes:**

- To preserve source single-architecture distributions folders edit multi_arch_iso.cmd and SET Preserve=1

- If the installation file is install.esd, be aware that option 1 will require high amount of CPU/RAM to unify install.esd

- multi_arch_iso.cmd can be used also to create multi-architecture ISO from any similar Windows x64/x86 ISO distributions, starting Windows 7 SP1

however, option 2 require Windows 10 setup files

## Credits

* qad - esddecrypt.exe program

* [@tfwboredom](https://twitter.com/tfwboredom) - new key support for esddecrypt.exe

* [Eric Biggers](http://wimlib.net) - wimlib

* [mkuba50](https://gitlab.com/users/mkuba50) - busybox.exe method to create identical single ISO from the same ESD

* [Igor Pavlov](https://www.7-zip.org/) - 7-zip

* [erwan.l](http://reboot.pro/files/file/313-offlinereg) - offlinereg

* [cdob](http://reboot.pro/topic/20471-windows-pe-5x-boot-problem) - create aio efisys.bin

* [@rgadguard](https://twitter.com/rgadguard) - RSA cryptokeys key.cmd host server / update script

* MrMagic, Chris123NT, mohitbajaj143, Superwzt, timster - RSA cryptokeys

* murphy78 - original script

* nosferati87, NiFu, s1ave77, Enthousiast, ztsoft, and any other MDL forums members contributed in the ESD project
