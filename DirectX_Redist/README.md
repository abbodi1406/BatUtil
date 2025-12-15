# DirectX_Redist_Repack

## Overview

- Yet another repack for Microsoft DirectX® End-User Runtime (June 2010) redistributable

- Simple INF-based installer/uninstaller, using 7zSfxMod archive

- Include XAudio 2.9 redistributable  
https://www.nuget.org/packages/Microsoft.XAudio2.Redist/

- Managed DirectX is installed/uninstalled separately

- Include mdxi.exe/mdxu.exe to properly handle Managed DirectX GAC assemblies

require .NET Framework 2.0/3.5 (for all),  
or .NET Framework 1.1 (for Windows XP / NT 5.x family)

- If Managed DirectX is installed before .NET Framework,  
after installing .NET, run mdxi.exe (as administrator on NT 6.x), or reinstall Managed DirectX from the repack

- `XAudio2_9redist.dll` will be installed on Windows XP and Vista, but it's only usable on Windows 7 and later

- `xinput9_1_0.dll will` not be removed upon uninstallation on Windows XP / NT 5.x family

## Unattended switches

```
/y  
Passive mode, shows progress. *Both* Runtime and Managed are installed.  
/ai  
Quiet mode, no output shown. *Both* Runtime and Managed are installed.  
/ai1  
Quiet mode. *Only* Runtime package is installed.  
/ai2  
Quiet mode. *Only* Managed package is installed.  
/ai3  
Uninstall mode. Try to remove both using bundled INF files.

/gm2  
Optional switch to disable extraction dialog for all other switches  
/h | /?  
Display this help.
```
Examples:  
```
Automatically install all packages and display progress:  
DirectX_Redist_Repack_x86_x64.exe /y

Silently install all packages and display no progress:  
DirectX_Redist_Repack_x86_x64.exe /ai /gm2

Silently install Runtime package:  
DirectX_Redist_Repack_x86_x64.exe /ai1

Silently uninstall all packages:  
DirectX_Redist_Repack_x86_x64.exe /ai3 /gm2
```

## Credits

- bphlpt: DXCB - DirectX Collector and addon Builder  
- ricktendo64: INF tips and tricks. modded VC++ 7zSD.sfx / multilingual config.txt  
- Reaper: Wintoolkit INF AddOn template  
- Yumeyao: LaunchINFSectionEx.exe
