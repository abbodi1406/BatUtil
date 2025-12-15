# Office C2R Extender for Windows 7/8.1

## Intro

- Official support for Windows 7/8.1 ended January 2023

https://learn.microsoft.com/deployoffice/endofsupport/windows-7-support  
https://learn.microsoft.com/deployoffice/endofsupport/windows-81-support

- Because of that, restricted versions targeted for Windows 10/11 are not allowed to be installed on Windows 7/8.1

- This DLL hook is to bypass the version restriction and allow installing versions outside of the fixed range

## How to Use

- If you are installing with Office Deployment Tool, you must first rename the file `setup.exe` to `ODTsetup.exe`

- Make sure there are no running Office programs, it's not required to uninstall older Office C2R versions

- Extract the pack contents to a folder with simple path

- Right-click on `installer.cmd` and "Run as administrator"

- Proceed to install Office C2R afterward, or initiate an Update

- Removal: right-click on `remover.cmd` and "Run as administrator"

## Disclaimer

- This is a prototype project, it is not tested extensively, and could have side effects on Office functioning or experience

If you have any errors or issues during Office installation/updating, remove it, and consider upgrading to Windows 8.1

- Installing higher versions does not mean that new Office C2R features will necessary work

Those features are controlled with complicated Enhanced Configuration Service (ECS) mechanism, which cannot be easily fooled

## Special Thanks

- namazso     - avrf code  
- Enthousiast - testing