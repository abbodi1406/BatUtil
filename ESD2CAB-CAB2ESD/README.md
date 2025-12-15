# ESD2CAB-CAB2ESD

* Convert simple ESD files to CAB files and vice versa,

* Mainly ment to be used with Windows 10 UUP files:

Language Packs : ESD -> CAB (esd2cab)

Reference files: CAB -> ESD (cab2esd)

## Usage:

extract this package to a folder with a simple path

copy/move ESD or CAB files to extraction folder, and launch the proper script

## Note:

cab2esd_CLI.cmd is set to convert CAB files to max-compressed ESD files

to get high-compressed solid ESD files (require high amount of CPU/RAM), edit the script and uncomment this line:

`set compress=LZMS`

## Credits

* OnePiece [DXTool](https://www.wincert.net/forum/topic/9409-tool-dx-tool-x86x64/)
* Melinda Bellemore [SxSExpand](https://forums.mydigitallife.net/members/superbubble.250156/)
