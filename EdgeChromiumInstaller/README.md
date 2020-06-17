# ECOI

* A command Script to install Microsoft Edge (Chromium) offline with working Edge Update

basically, an alternative to Enterprise MSI installers, with the ability to install any version for any channel

______________________________

## Requirements

* Latest untagged meta installer for Microsoft Edge Update:

https://msedgesetup.azureedge.net/latest/MicrosoftEdgeSetup.exe

you can also acquire it from this page, search for: MicrosoftEdgeUpdateSetup

https://edgeupdates.microsoft.com/api/products

* Latest offline installer for Microsoft Edge:

https://32767.ga/edge/

- choose desired channel / architecture  
- choose desired / latest build  
- click Get button  
- download the biggest file, example: MicrosoftEdge_X64_83.0.472.0.exe  
- rename the file after download, keeping the original name

* For more info on languages codes see:  
https://docs.microsoft.com/en-us/deployedge/microsoft-edge-supported-languages

______________________________

## How To

* Place both downloaded files above next to the script in the same folder

![alt text](https://i.imgur.com/zutP24L.png)

* If you run EdgeChromiumInstaller.cmd without administrator privileges:

you get the option to install Edge for current user only  
capabilities to set Edge as default browser will be missing

* If you run EdgeChromiumInstaller.cmd as administrator:

you get the option to install Edge for current user, or all users / system wide (except Canary channel)  
capabilities to set Edge as default browser will be available

* For Windows x64 OS, you can choose between x64/x86 Edge if both installers are detected

* Choose the desired Channel

* Choose the desired Language
 
* Choose Installation Type: System or User

this option is available only with administrator privileges, and selected channel is not Canary

* At the end, choose to Start Installation or Exit

______________________________

## Remarks

* Installation will be executed silently

if it succeeded, MS Edge shortcut will appear on Desktop (and Taskbar)

if it failed, check these log files for details:

```
"%ProgramData%\Microsoft\EdgeUpdate\Log\MicrosoftEdgeUpdate.log"
"%temp%\MicrosoftEdgeUpdate.log"
"%temp%\msedge_installer.log"
```

* To set MS Edge Canary as default browser:

run EdgeChromiumInstaller.cmd as administrator and perform the installation

then, go to Control Panel / Default Programs / Set your default programs

______________________________

## Command Line Switches

* All switches are case-insensitive, works in any order, but must be separated with spaces

* You can use the long form or the short form for channel and level

* Architecture is determined based on the detected offline installer  
for Windows x64/arm64, 64-bit installer takes precedence if detected with 32-bit installer (x86)

- language:

`/L lang`

mandatory switch, it must be specified

- channel:

```
/Canary
/Dev
/Beta
/Stable
/CC
/CD
/CB
/CS
```

if not specified, default is Stable  
if multiple switches are specified, the last one takes precedence

- installation level:

```
/System
/User
/S
/U
```

if not specified, default is System (with admin privileges), or User (without admin privileges)  
if multiple switches are specified, the last one takes precedence  
Canary channel always default to User level

* Examples:

install Edge Canary, french language  
`EdgeChromiumInstaller.cmd /canary /l fr`

install Edge Stable, english language, system level  
```
EdgeChromiumInstaller.cmd /L en
EdgeChromiumInstaller.cmd /L en /Stable
EdgeChromiumInstaller.cmd /L en /Stable /System
```

install Edge Beta, chinese language, system level  
```
EdgeChromiumInstaller.cmd /Beta /System /L zh-cn
EdgeChromiumInstaller.cmd /l zh-cn /cb /s
```

______________________________

## Credits

- whatever127: 32767.ga/edge
