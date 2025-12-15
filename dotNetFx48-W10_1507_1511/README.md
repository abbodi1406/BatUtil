# dotNetFx48-W10_1507_1511

- .NET 4.8 Installer/Updater for Windows 10 Version 1507/1511

## Supported Packs (cab or msu files)

- .NET Framework 4.8 for Windows 10 Version 1607 (KB4486129)

x64  
`http://wsus.ds.download.windowsupdate.com/c/msdownload/update/software/ftpk/2020/01/windows10.0-kb4486129-x64_0b61d9a03db731562e0a0b49383342a4d8cbe36a.msu`

x86  
`http://wsus.ds.download.windowsupdate.com/c/msdownload/update/software/ftpk/2020/01/windows10.0-kb4486129-x86_d38ebe43baeabaef927675c7ff2295843f19a077.msu`

- .NET Framework 4.8 Language Packs for Windows 10 Version 1607 (KB4087515)

**NET48-LangPacks1607.txt**

- Latest Cumulative Update for .NET 4.8 Framework for Windows 10 Version 1607

https://www.catalog.update.microsoft.com/Search.aspx?q=Framework+Version+1607

- Extract the whole archive file to a folder with short simple path

- Download necessary updates and place the files in the same folder next to `DNF48.cmd`

______________________________

## How To Use - Current Online system

- temporary turn OFF antivirus or realtime protection if any

- make sure no other servicing operation is pending

- run `1-Patch-Servicing_Stack.cmd` as administrator and press Y

- run `DNF48.cmd` as administrator and verify that updates are installed currectly

- restart the system if asked to

- run `2-Restore-Servicing_Stack.cmd` as administrator and press Y

- repeat the same steps with each new .NET 4.8 Cumulative Update 

- Note:  
Current OS target will not work unless servicing stack is patched first

______________________________

## How To Use - Offline installed system

- Requirements:

Another installed Host OS: Windows 10, or Windows 8.1/7 with Windows ADK

Or, create custom Windows 10 WinPE image with Windows PowerShell support  
https://web.archive.org/web/20201130170752/https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/winpe-adding-powershell-support-to-windows-pe

- reboot to the other Windows OS, or boot the custom WinPE image

- run `DNF48.cmd` as administrator

- enter the correct drive letter for the target system, then press Enter

you can run and use notepad in WinPE as explorer to find the correct drive

- Repeat the same steps with each new .NET 4.8 Cumulative Update

______________________________

## How To Use - install.wim image

- Requirements:

Host OS: Windows 10, or Windows 8.1/7 with Windows ADK

- manually mount the needed index of install.wim using DISM.exe tool

- run `DNF48.cmd` as administrator

- enter the mount directory path, then press Enter

- manually unmount install.wim and commit changes

______________________________

## Remarks

- You can also set target automatically:

edit `DNF48.cmd`  
change blank target to the correct mount directory path, or offline image driver letter  
save the script and then run

- If you get errors, you can enable the debug mode to help troubleshooting:

edit `DNF48.cmd`  
change blank target to the correct mount directory path, or offline image driver letter  
change `_Debug=0` to `1`  
save the script and then run

- You can use refreshed .NET 4.8 pack instead original pack

however, it's recommended to either use refreshed .NET pack or .NET cumulative update, not both

______________________________

## Special Thanks

* whatever127: servicing stack patch concept
