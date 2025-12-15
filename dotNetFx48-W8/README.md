# dotNetFx48-W8

- .NET Framework 4.8 Installer for Windows 8 Client

## Supported Packs (cab or msu files)

- .NET Framework 4.8 for Windows Embedded 8 Standard (KB4486081)

x64  
`http://wsus.ds.download.windowsupdate.com/d/msdownload/update/software/ftpk/2019/12/windows8-rt-kb4486081-x64_b3e0bdffee1cf7a1c718de205034eb05737014cb.msu`

x86  
`http://wsus.ds.download.windowsupdate.com/d/msdownload/update/software/ftpk/2019/12/windows8-rt-kb4486081-x86_b69d115387b6ff93c70492e9361207f5f714a07b.msu`

- .NET Framework 4.8 Language Packs for Windows Embedded 8 Standard (KB4087513)

`https://dl.dropboxusercontent.com/s/bqrpblnjczzobfd/NET48-LangPacks-W8.txt`

## Requirements

- Download necessary updates and place the files in the same folder next to NET48.cmd

- To install the updates for already installed system, you need either of:

Another installed Host OS: Windows 8 or later, or Windows 7 with Windows ADK

Or, create custom Windows 8/8.1/10 WinPE image with Windows PowerShell support  
https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/winpe-adding-powershell-support-to-windows-pe

- To install the updates for install.wim image, you need:

Host OS: Windows 8 or later, or Windows 7 with Windows ADK

## How to update already installed system

- reboot to the other Windows OS, or boot the custom WinPE image

- run `NET48.cmd` as administrator

- enter the correct drive letter for the target system, then press Enter

you can run and use notepad in WinPE as explorer to find the correct drive

## How to update install.wim image

- manually mount the needed index of install.wim using DISM.exe tool

- run `NET48.cmd` as administrator

- enter the mount directory path, then press Enter

- manually unmount install.wim and commit changes

## Remarks

- You can also set target automatically:

edit `NET48.cmd`  
change blank target to the correct mount directory path, or offline image driver letter  
save the script and then run

- If you get errors, you can enable the debug mode to help troubleshooting:

edit `NET48.cmd`  
change blank target to the correct mount directory path, or offline image driver letter  
change `_Debug=0` to `1`  
save the script and then run

- You can use refreshed .NET 4.8 pack instead original pack, or to update already installed pack

## Alternative Approach

- Install Prerequesities packages fon .NET 4.8 and IE11 from Windows Embedded 8 Standard

- To do so, extract all contents of **W8_NetFx4_IE11_Prereqs.7z** and run `installer.cmd` as administrator

- Afterward, you can install .NET 4.8 pack directly from msu/cab file on live running W8 OS
