# PSFX Repack

## Info

- Some Windows 11/10 updates are available as a PSFX format

It consist of cab file that contain the update manifests, and psf file that contain the raw payload files

- There are two types of this format:

PSFX v2: delta update files which require WinSxS source files

Baseless PSFX: complete update files which have no dependencies

- To use those files with DISM `/Add-Package` command, it is required to extract (generate) the actual payload files first

Afterward, you can use the extracted folder path with DISM, or compress the folder into a full cab file or esd file

- The provided scripts automate the process and repackage the psf/cab files into full file

## Usage

- Extract this package zip file to a folder with a simple path

- Copy or move the psf/cab files next to the script, then run one of the scripts:

**psfx2cab_CLI.cmd**  
use cabarc.exe to create the full cab file / no progress info shown

**psfx2cab_GUI.cmd**  
use DXTool.exe to create the full cab file / show GUI progress info

**psfx2esd_CLI.cmd**  
use imagex.exe to create the full esd file / show percentage progress info

- Or from command prompt, run the desired script and provide path to the folder containing psf/cab files

example:  
`psfx2cab_CLI.cmd E:\Downloads\uup-converter\UUPs`

- The result file will be located in the same folder (current or provided)  
and it will have the same name of the original cab file, appended with -full_psfx

example:  
`windows10.0-kb5004564-arm64-full_psfx.cab`

## Remarks

- The script do not require administrator privileges  
however, if you get Access Denied errors, run it as administrator

- CAB file has limitation by design: 2 GB size - 65535 included files/directories

if you are repacking big baseless update, it's recomended to create esd file instead

- **psfx2esd_CLI.cmd** is set to create the full esd file with max-compression ratio

if you want to create the file with solid high-compression ratio (require high amount of CPU/RAM),  
edit the script and uncomment this line:  
`set compress=LZMS`

## Credits

- [PSFExtractor / BetaWorld](https://github.com/Secant1006/PSFExtractor)  
- [OnePiece / DXTool](https://www.wincert.net/forum/topic/9409-tool-dx-tool-x86x64/)
- [Melinda Bellemore / SxSExpand](https://forums.mydigitallife.net/members/superbubble.250156/)
