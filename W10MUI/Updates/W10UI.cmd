@setlocal DisableDelayedExpansion
@set uiv=v10.47r
@echo off
:: enable debug mode, you must also set target and repo (if updates are not beside the script)
set _Debug=0

:: when changing below options, recommended to set the new values between = and " marks

:: target distribution, wim file or offline image
:: leave it blank to update current online os, or automatically detect wim file next to the script
set "Target="

:: updates location
:: leave it blank to automatically detect the current script directory
set "Repo="

:: dism.exe tool custom path (if Host OS is Win8.1 or earlier and no Win10 ADK installed)
set "DismRoot=dism.exe"

:: enable .NET 3.5 feature
set Net35=1

:: optional, custom "folder" path for microsoft-windows-netfx3-ondemand-package.cab
set "Net35Source="

:: Cleanup OS images to "compress" superseded components (might take long time to complete)
set Cleanup=0

:: Rebase OS images to "remove" superseded components (warning: break "Reset this PC" feature)
:: require first to set Cleanup=1
set ResetBase=0

:: update winre.wim if detected inside install.wim
set WinRE=1

:: Force updating winre.wim with Cumulative Update regardless if SafeOS update detected
:: auto enabled for builds 22000-26050, change to 2 to disable
:: ignored and auto disabled for builds 26052 and later
set LCUwinre=0

:: Expand Cumulative Update and install from loose files via update.mum
:: applicable only for builds 26052 and later
set LCUmsuExpand=0

:: update ISO boot files bootmgr/memtest/efisys.bin from Cumulative Update
set UpdtBootFiles=0

:: 1 = do not install EdgeChromium with Enablement Package or Cumulative Update
:: 2 = alternative workaround to avoid EdgeChromium with Cumulative Update only
set SkipEdge=0

:: do not install Edge WebView with Cumulative Update
set SkipWebView=0

:: optional, set directory for temporary extracted files (default is on the same drive as the script)
set "_CabDir=W10UItemp"

:: optional, set mount directory for updating wim files (default is on the same drive as the script)
set "MountDir=W10UImount"
set "WinreMount=W10UImountre"

:: start the process directly once you execute the script, as long as the other options are correctly set
set AutoStart=0

:: detect and use wimlib-imagex.exe for exporting wim files instead dism.exe
set UseWimlib=0

:: ### Options for wim or distribution target only ###

:: add drivers to install.wim and boot.wim / winre.wim
set AddDrivers=0

:: custom folder path for drivers - default is "Drivers" folder next to the script
:: the folder must contain subfolder for each drivers target:
:: ALL   / drivers will be added to all wim files
:: OS    / drivers will be added to install.wim only
:: WinPE / drivers will be added to boot.wim / winre.wim only
set "Drv_Source=\Drivers"

:: ### Options for distribution target only ###

:: convert install.wim to install.esd
:: warning: the process will consume very high amount of CPU and RAM resources
set wim2esd=0

:: split install.wim into multiple install.swm files
:: note: if both options are 1, install.esd takes precedence over split install.swm
set wim2swm=0

:: create new iso file
:: require either of: Win10 ADK, oscdimg.exe, cdimage.exe, Windows Powershell
set ISO=1

:: folder path for iso file, leave it blank to create ISO in the script current directory
set "ISODir="

:: delete DVD distribution folder after creating updated ISO
set Delete_Source=0

:: ###################################################################
:: # NORMALLY THERE IS NO NEED TO CHANGE ANYTHING BELOW THIS COMMENT #
:: ###################################################################

set "_cmdf=%~f0"
if exist "%SystemRoot%\Sysnative\cmd.exe" (
setlocal EnableDelayedExpansion
start %SystemRoot%\Sysnative\cmd.exe /c ""!_cmdf!" %*"
exit /b
)
if exist "%SystemRoot%\SysArm32\cmd.exe" if /i %PROCESSOR_ARCHITECTURE%==AMD64 (
setlocal EnableDelayedExpansion
start %SystemRoot%\SysArm32\cmd.exe /c ""!_cmdf!" %*"
exit /b
)

set _offdu=0
set _embd=0
set _keep=0
set cmd_target=
set cmd_tmpdir=
set cmd_source=
set _args=
set _args=%*
if not defined _args goto :NoProgArgs
set _keep=%~1
set "cmd_target=%~2"
set "cmd_tmpdir=%~3"
set "cmd_source=%~4"

:NoProgArgs
set "SysPath=%SystemRoot%\System32"
if exist "%SystemRoot%\Sysnative\reg.exe" (set "SysPath=%SystemRoot%\Sysnative")
set "Path=%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
set "xOS=amd64"
if /i "%PROCESSOR_ARCHITECTURE%"=="arm64" set "xOS=arm64"
if /i "%PROCESSOR_ARCHITECTURE%"=="x86" if "%PROCESSOR_ARCHITEW6432%"=="" set "xOS=x86"
if /i "%PROCESSOR_ARCHITEW6432%"=="amd64" set "xOS=amd64"
if /i "%PROCESSOR_ARCHITEW6432%"=="arm64" set "xOS=arm64"
set "_Null=1>nul 2>nul"
set "_err===== ERROR ===="
set "_psc=powershell -nop -c"
set winbuild=1
for /f "tokens=6 delims=[]. " %%# in ('ver') do set winbuild=%%#
set _cwmi=0
for %%# in (wmic.exe) do @if not "%%~$PATH:#"=="" (
cmd /c "wmic path Win32_ComputerSystem get CreationClassName /value" 2>nul | find /i "ComputerSystem" 1>nul && set _cwmi=1
)
set _pwsh=1
for %%# in (powershell.exe) do @if "%%~$PATH:#"=="" set _pwsh=0
cmd /c "%_psc% "$ExecutionContext.SessionState.LanguageMode"" | find /i "FullLanguage" 1>nul || (set _pwsh=0)
if %_cwmi% equ 0 if %_pwsh% equ 0 goto :E_PWS
reg.exe query HKU\S-1-5-19 %_Null% || goto :E_Admin
set "_oscdimg=%SysPath%\oscdimg.exe"
set "_sbs=Microsoft\Windows\CurrentVersion\SideBySide\Configuration"
set "_SxS=HKLM\SOFTWARE\%_sbs%"
set "_CBS=Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages"
set "_batf=%~f0"
set "_batp=%_batf:'=''%"
set "_log=%~dpn0"
set "_work=%~dp0"
set "_work=%_work:~0,-1%"
for /f "skip=2 tokens=2*" %%a in ('reg.exe query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop') do call set "_dsk=%%b"
if exist "%PUBLIC%\Desktop\desktop.ini" set "_dsk=%PUBLIC%\Desktop"
set psfnet=0
if exist "%SystemRoot%\Microsoft.NET\Framework\v4.0.30319\ngen.exe" set psfnet=1
if %_pwsh% equ 0 set psfnet=0
for %%# in (E F G H I J K L M N O P Q R S T U V W X Y Z) do (
set "_adr%%#=%%#"
)
if %_cwmi% equ 1 for /f "tokens=2 delims==:" %%# in ('"wmic path Win32_Volume where (DriveLetter is not NULL) get DriveLetter /value" ^| findstr ^=') do (
if defined _adr%%# set "_adr%%#="
)
if %_cwmi% equ 1 for /f "tokens=2 delims==:" %%# in ('"wmic path Win32_LogicalDisk where (DeviceID is not NULL) get DeviceID /value" ^| findstr ^=') do (
if defined _adr%%# set "_adr%%#="
)
if %_cwmi% equ 0 for /f "tokens=1 delims=:" %%# in ('%_psc% "(([WMISEARCHER]'Select * from Win32_Volume where DriveLetter is not NULL').Get()).DriveLetter; (([WMISEARCHER]'Select * from Win32_LogicalDisk where DeviceID is not NULL').Get()).DeviceID"') do (
if defined _adr%%# set "_adr%%#="
)
for %%# in (E F G H I J K L M N O P Q R S T U V W X Y Z) do (
if not defined _sdr (if defined _adr%%# set "_sdr=%%#:")
)
if not defined _sdr set psfnet=0
set "_Pkt=31bf3856ad364e35"
set "_OurVer=25.10.0.0"
set "_SupCmp=microsoft-client-li..pplementalservicing"
set "_EdgCmp=microsoft-windows-e..-firsttimeinstaller"
set "_CedCmp=microsoft-windows-edgechromium"
set "_EwvCmp=microsoft-edge-webview"
set "_EsuCmp=microsoft-windows-s..edsecurityupdatesai"
set "_SupIdn=Microsoft-Client-Licensing-SupplementalServicing"
set "_EdgIdn=Microsoft-Windows-EdgeChromium-FirstTimeInstaller"
set "_CedIdn=Microsoft-Windows-EdgeChromium"
set "_EwvIdn=Microsoft-Edge-WebView"
set "_EsuIdn=Microsoft-Windows-SLC-Component-ExtendedSecurityUpdatesAI"
setlocal EnableDelayedExpansion

if %_Debug% equ 0 (
  set "_Nul1=1>nul"
  set "_Nul2=2>nul"
  set "_Nul6=2^>nul"
  set "_Nul3=1>nul 2>nul"
  set "_Pause=pause >nul"
  set "_Goto=goto :mainmenu"
  goto :Begin
)
  set "_Nul1="
  set "_Nul2="
  set "_Nul6="
  set "_Nul3="
  set "_Pause="
  set "_Goto=exit /b"
copy /y nul "!_work!\#.rw" %_Null% && (if exist "!_work!\#.rw" del /f /q "!_work!\#.rw") || (set "_log=!_dsk!\%~n0")
set "_suf="
if %_Debug% neq 0 if exist "!_log!_Debug.log" (
set /a _suf=%random%
)
echo.
echo Running W10UI %uiv% in Debug Mode...
echo The window will be closed when finished
@echo on
@prompt $G
@call :Begin >"!_log!_tmp.log" 2>&1 &cmd /u /c type "!_log!_tmp.log">"!_log!_Debug!_suf!.log"&del "!_log!_tmp.log"
@title %ComSpec%
@exit /b

:Begin
title Installer for Windows NT 10.0 Updates
set "_dLog=%SystemRoot%\Logs\DISM"
cd /d "!_work!"
set psfcpp=0
if exist "PSFExtractor.exe" set psfcpp=1&set _exe="!_work!\PSFExtractor.exe"
if exist "bin\PSFExtractor.exe" set psfcpp=1&set _exe="!_work!\bin\PSFExtractor.exe"
if not defined _sdr set psfcpp=0
set psfwim=0
set _delta=msdelta.dll
set stcexp=0
set _exp=expand.exe
if exist "bin\expand.exe" if exist "bin\dpx.dll" (set stcexp=1&set _exp="!_work!\bin\expand.exe")
if exist "expand.exe" if exist "dpx.dll" (set stcexp=1&set _exp="!_work!\expand.exe")
if not exist "W10UI.ini" goto :proceed
find /i "[W10UI-Configuration]" W10UI.ini %_Nul1% || goto :proceed
setlocal DisableDelayedExpansion
for %%# in (
target
repo
dismroot
net35
net35source
cleanup
resetbase
winre
lcuwinre
lcumsuexpand
updtbootfiles
skipedge
skipwebview
usewimlib
_cabdir
mountdir
winremount
wim2esd
wim2swm
iso
isodir
delete_source
autostart
adddrivers
drv_source
) do (
call :ReadINI %%#
)
setlocal EnableDelayedExpansion
goto :proceed

:ReadINI
find /i "%1 " W10UI.ini >nul || goto :eof
for /f "skip=2 tokens=1* delims==" %%A in ('find /i "%1 " W10UI.ini') do call set "%1=%%~B"
goto :eof

:proceed
set _configured=0
if %_Debug% neq 0 set autostart=1
if "!repo!"=="" set "repo=!_work!"
if "!dismroot!"=="" set "DismRoot=dism.exe"
if "!_cabdir!"=="" set "_CabDir=W10UItemp"
if "!mountdir!"=="" set "MountDir=W10UImount"
if "!winremount!"=="" set "WinreMount=W10UImountre"
if "%Net35%"=="" set Net35=1
if "%Cleanup%"=="" set Cleanup=0
if "%ResetBase%"=="" set ResetBase=0
if "%WinRE%"=="" set WinRE=1
if "%LCUwinre%"=="" set LCUwinre=0
if "%LCUmsuExpand%"=="" set LCUmsuExpand=0
if "%UpdtBootFiles%"=="" set UpdtBootFiles=0
if "%SkipEdge%"=="" set SkipEdge=0
if "%SkipWebView%"=="" set SkipWebView=0
if "%UseWimlib%"=="" set UseWimlib=1
if "%ISO%"=="" set ISO=1
if "%AutoStart%"=="" set AutoStart=0
if "%Delete_Source%"=="" set Delete_Source=0
if "%AddDrivers%"=="" set AddDrivers=0
if "%Drv_Source%"=="" set "Drv_Source=\Drivers"
if "%wim2esd%"=="" set wim2esd=0
if "%wim2swm%"=="" set wim2swm=0
set _wlib=0
if %UseWimlib% equ 1 for %%# in (wimlib-imagex.exe) do @if not "%%~$PATH:#"=="" (
set _wlib=1
set _wimlib=wimlib-imagex.exe
)
if %UseWimlib% equ 1 if %_wlib% equ 0 (
if exist "wimlib-imagex.exe" set _wlib=1&set _wimlib="!_work!\wimlib-imagex.exe"
if exist "bin\wimlib-imagex.exe" set _wlib=1&set _wimlib="!_work!\bin\wimlib-imagex.exe"
if /i %xOS%==amd64 if exist "bin\bin64\wimlib-imagex.exe" set _wlib=1&set _wimlib="!_work!\bin\bin64\wimlib-imagex.exe"
)
if "!Drv_Source!"=="\Drivers" set "Drv_Source=!_work!\Drivers"
set "DrvSrcALL="
set "DrvSrcOS="
set "DrvSrcPE="
if %AddDrivers% neq 0 if exist "!Drv_Source!\" (
cd /d "!Drv_Source!"
if exist ALL\ dir /b /s "ALL\*.inf" %_Nul3% && set "DrvSrcALL=!Drv_Source!\ALL"
if exist OS\ dir /b /s "OS\*.inf" %_Nul3% && set "DrvSrcOS=!Drv_Source!\OS"
if exist WinPE\ dir /b /s "WinPE\*.inf" %_Nul3% && set "DrvSrcPE=!Drv_Source!\WinPE"
cd /d "!_work!"
)
set _ADK=0
set "showdism=Host OS"
set "_dism2=%dismroot% /English /NoRestart /ScratchDir"
if /i not "!dismroot!"=="dism.exe" (
set _ADK=1
set "showdism=%dismroot%"
set _dism2="%dismroot%" /English /NoRestart /ScratchDir
set "dsv=!dismroot:\=\\!"
call :DismVer
) else (
set "dsv=%SysPath%\dism.exe"
set "dsv=!dsv:\=\\!"
call :DismVer
)
set _drv=%~d0
if /i "%_cabdir:~0,5%"=="W10UI" set "_cabdir=%_drv%\W10UItemp"
set _ntf=NTFS
if /i not "%_drv%"=="%SystemDrive%" if %_cwmi% equ 1 for /f "tokens=2 delims==" %%# in ('"wmic volume where DriveLetter='%_drv%' get FileSystem /value"') do set "_ntf=%%#"
if /i not "%_drv%"=="%SystemDrive%" if %_cwmi% equ 0 for /f %%# in ('%_psc% "(([WMISEARCHER]'Select * from Win32_Volume where DriveLetter=\"%_drv%\"').Get()).FileSystem"') do set "_ntf=%%#"
if /i not "%_ntf%"=="NTFS" set _drv=%SystemDrive%
if /i "%mountdir:~0,5%"=="W10UI" set "mountdir=%_drv%\W10UImount"
if /i "%winremount:~0,5%"=="W10UI" set "winremount=%_drv%\W10UImountre"
if "%_cabdir:~-1%"=="\" set "_cabdir=!_cabdir:~0,-1!"
if "%_cabdir:~-1%"==":" set "_cabdir=!_cabdir!\"
if not "!_cabdir!"=="!_cabdir: =!" set "_cabdir=!_cabdir: =!"
if "%mountdir:~-1%"=="\" set "mountdir=!mountdir:~0,-1!"
if "%mountdir:~-1%"==":" set "mountdir=!mountdir!\"
if not "!mountdir!"=="!mountdir: =!" set "mountdir=!mountdir: =!"
set "mountdir=!mountdir!_%random%"
set "winremount=!winremount!_%random%"
set "_cabdir=!_cabdir!_%random%"
set cmd_repo=1
if defined cmd_target if defined cmd_tmpdir if exist "!cmd_target!\Windows\regedit.exe" (
if not "!repo!"=="!_work!" (if not exist "!repo!\*Windows1*-KB*.*" if not exist "!repo!\SSU-*-*.*" set "repo=!_work!")
if not exist "!repo!\*Windows1*-KB*.*" if not exist "!repo!\SSU-*-*.*" set cmd_repo=0
)
if defined cmd_target if defined cmd_tmpdir if exist "!cmd_target!\Windows\regedit.exe" if %cmd_repo%==1 (
if %_Debug% neq 0 echo "!cmd_target!"
set "Target=!cmd_target!"
set "_cabdir=!cmd_tmpdir!"
if defined cmd_source if exist "!cmd_source!\setup.exe" (
  if exist "!cmd_source!\sxs\*netfx3*.cab" set "Net35Source=!cmd_source!\sxs"
  set _offdu=1
  cd /d "!cmd_source!"
  cd ..
  set "cmd_dvd=!cd!"
  cd /d "!_work!"
  )
set AutoStart=1
set _embd=1
)
if %_embd% equ 0 if exist "!_cabdir!\" (
echo.
echo ============================================================
echo Cleaning temporary extraction folder...
echo ============================================================
echo.
rmdir /s /q "!_cabdir!\" %_Nul1%
)
set _init=1
if %_Debug% equ 0 if %autostart% neq 0 set "_Goto=exit /b"

:checktarget
set basekbn=
set basepkg=
set tmpssu=
set isomin=0
set _fixEP=0
set _actEP=0
set _SrvEdt=0
set _DNF=0
set directcab=0
set dvd=0
set wim=0
set offline=0
set online=0
set copytarget=0
set imgcount=0
set wimfiles=0
set keep=0
set targetname=0
set _skpd=0
set _skpp=0
set uupboot=0
if not defined _all set _all=1
if %_init%==1 if "!target!"=="" if exist "*.wim" (for /f "tokens=* delims=" %%# in ('dir /b /a:-d "*.wim"') do set "target=!_work!\%%~nx#")
if "!target!"=="" set "target=%SystemDrive%"
if "%target:~-1%"=="\" set "target=!target:~0,-1!"
if /i "!target!"=="%SystemDrive%" (
if /i %xOS%==x86 (set arch=x86) else if /i %xOS%==amd64 (set arch=x64) else (set arch=arm64)
if %_init%==1 (goto :check) else (goto :mainmenu)
)
if /i "%target:~-4%"==".wim" (
if exist "!target!" (
  set wim=1
  for %%# in ("!target!") do set "targetname=%%~nx#"&setlocal DisableDelayedExpansion&set "targetpath=%%~dp#"&setlocal EnableDelayedExpansion
  )
) else (
if exist "!target!\sources\install.wim" set dvd=1
if exist "!target!\Windows\regedit.exe" set offline=1
)
if %offline%==0 if %wim%==0 if %dvd%==0 (if %_init%==1 (set "target=%SystemDrive%"&goto :check) else (set "MESSAGE=Specified location is not valid"&goto :E_Target))
if %offline%==1 (
dir /b /ad "!target!\Windows\Servicing\Version\10.0.*" %_Nul3% || (
dir /b /ad "!target!\Windows\Servicing\Version\11.0.*" %_Nul3% || (set "MESSAGE=Detected target offline image is not Windows NT 10.0"&goto :E_Target)
)
for /f "tokens=3 delims=." %%# in ('dir /b /ad "!target!\Windows\Servicing\Version\1*"') do set _build=%%#
set "mountdir=!target!"
set arch=x86
if exist "!target!\Windows\Servicing\Packages\*~amd64~~*.mum" set arch=x64
if exist "!target!\Windows\Servicing\Packages\*~arm64~~*.mum" set arch=arm64
)
if %wim%==1 (
echo.
echo ============================================================
echo Please wait...
echo ============================================================
cd /d "!targetpath!"
dism.exe /english /get-wiminfo /wimfile:"%targetname%" /index:1 | find /i "Version : 10." %_Nul1% || (
dism.exe /english /get-wiminfo /wimfile:"%targetname%" /index:1 | find /i "Version : 11." %_Nul1% || (set "MESSAGE=Detected wim version is not Windows NT 10.0"&goto :E_Target)
)
for /f "tokens=4 delims=:. " %%# in ('dism.exe /english /get-wiminfo /wimfile:"%targetname%" /index:1 ^| find /i "Version :"') do set _build=%%#
for /f "tokens=2 delims=: " %%# in ('dism.exe /english /get-wiminfo /wimfile:"%targetname%" /index:1 ^| find /i "Architecture"') do set arch=%%#
for /f "tokens=2 delims=: " %%# in ('dism.exe /english /get-wiminfo /wimfile:"%targetname%" ^| find /i "Index"') do set imgcount=%%#
for /L %%# in (1,1,!imgcount!) do (
  for /f "tokens=1* delims=: " %%i in ('dism.exe /english /get-wiminfo /wimfile:"%targetname%" /index:%%# ^| findstr /b /c:"Name"') do set name%%#="%%j"
  )
set "indices=*"
set wimfiles=1
cd /d "!_work!"
)
if %dvd%==1 (
echo.
echo ============================================================
echo Please wait...
echo ============================================================
copy /y nul "!target!\#.rw" %_Nul3% && (del /f /q "!target!\#.rw" %_Nul3%) || (set copytarget=1)
cd /d "!target!"
dism.exe /english /get-wiminfo /wimfile:"sources\install.wim" /index:1 | find /i "Version : 10." %_Nul1% || (
dism.exe /english /get-wiminfo /wimfile:"sources\install.wim" /index:1 | find /i "Version : 11." %_Nul1% || (set "MESSAGE=Detected install.wim version is not Windows NT 10.0"&goto :E_Target)
)
for /f "tokens=4 delims=:. " %%# in ('dism.exe /english /get-wiminfo /wimfile:"sources\install.wim" /index:1 ^| find /i "Version :"') do set _build=%%#
for /f "tokens=2 delims=: " %%# in ('dism.exe /english /get-wiminfo /wimfile:"sources\install.wim" /index:1 ^| find /i "Architecture"') do set arch=%%#
for /f "tokens=2 delims=: " %%# in ('dism.exe /english /get-wiminfo /wimfile:"sources\install.wim" ^| find /i "Index"') do set imgcount=%%#
for /f "tokens=2 delims=: " %%# in ('dism.exe /english /get-wiminfo /wimfile:"sources\boot.wim" ^| find /i "Index"') do set bootimg=%%#
for /L %%# in (1,1,!imgcount!) do (
  for /f "tokens=1* delims=: " %%i in ('dism.exe /english /get-wiminfo /wimfile:"sources\install.wim" /index:%%# ^| findstr /b /c:"Name"') do set name%%#="%%j"
  )
set "indices=*"
set "targetname=install.wim"
set wimfiles=1
cd /d "!_work!"
)
if %_init%==1 (goto :check) else (goto :mainmenu)

:check
if /i "!target!"=="%SystemDrive%" (
if /i %xOS%==x86 (set arch=x86) else if /i %xOS%==amd64 (set arch=x64) else (set arch=arm64)
set _build=%winbuild%
reg.exe query %_SxS% /v W10UIclean %_Nul3% && (set onlineclean=1)
reg.exe query %_SxS% /v W10UIrebase %_Nul3% && (set onlineclean=1)
)
if not defined onlineclean goto :main1board

:main0board
set _elr=0
@cls
echo ====================== W10UI %uiv% =======================
echo.
echo Detected pending "Cleanup System Image" for Current OS:
echo.
echo [1] Execute Cleanup
echo.
echo [2] Skip Cleanup and continue
echo.
echo ============================================================
choice /c 129 /n /m "Choose a menu option, or press 9 to exit: "
set _elr=%errorlevel%
if %_elr%==3 goto :eof
if %_elr%==2 (
set onlineclean=
reg.exe delete %_SxS% /v W10UIclean /f %_Nul3%
reg.exe delete %_SxS% /v W10UIrebase /f %_Nul3%
goto :main1board
)
if %_elr%==1 (
reg.exe query %_SxS% /v W10UIclean %_Nul3% && (set online=1&set cleanup=1)
reg.exe query %_SxS% /v W10UIrebase %_Nul3% && (set online=1&set cleanup=1&set resetbase=1)
goto :main2board
)
goto :main0board

:main1board
set _bit=%arch%
if /i %arch%==arm64 set _bit=arm
call :counter
set "brep=!repo!"
if %_sum%==0 set "repo="
if /i not "!dismroot!"=="dism.exe" if exist "!dismroot!" goto :mainmenu
goto :checkadk

:mainboard
if %winbuild% lss 10240 if /i "!target!"=="%SystemDrive%" (%_Goto%)
if %winbuild% lss 10240 if %_ADK% equ 0 (%_Goto%)
if "!target!"=="" (%_Goto%)
if "!repo!"=="" (%_Goto%)
if "%repo:~-1%"=="\" set "repo=!repo:~0,-1!"
if "!_cabdir!"=="" (%_Goto%)
if "!mountdir!"=="" (%_Goto%)
if /i "!target!"=="%SystemDrive%" (set dismtarget=/online&set "mountdir=!target!"&set online=1&set _build=%winbuild%) else (set dismtarget=/image:"!mountdir!")

:main2board
if %_embd% neq 0 (
echo.
) else if %autostart% neq 0 (
echo.
) else (
@cls
)
echo ============================================================
echo Running W10UI %uiv%
echo ============================================================
if %online%==1 (
net stop trustedinstaller %_Nul3%
net stop wuauserv %_Nul3%
del /f /q %systemroot%\Logs\CBS\* %_Nul3%
)
if not exist "%_dLog%\" mkdir "%_dLog%" %_Nul3%
if %_embd% equ 0 (
del /f /q %_dLog%\* %_Nul3%
del /f /q %systemroot%\Logs\MoSetup\* %_Nul3%
)
if not exist "%SystemRoot%\temp\" mkdir "%SystemRoot%\temp" %_Nul3%
del /f /q %SystemRoot%\temp\*.mum %_Nul3%
if defined onlineclean (
if exist "%SystemRoot%\WinSxS\pending.xml" (
  echo.
  echo ============================================================
  echo ERROR: you must restart the system first before cleaning up
  echo ============================================================
  echo.
  echo.
  echo Press any key to exit.
  %_Pause%
  goto :eof
  )
set verb=0
set "mountdir=!target!"
set "mumtarget=!target!"
set dismtarget=/online
set _build=%winbuild%
reg.exe delete %_SxS% /v W10UIclean /f %_Nul3%
reg.exe delete %_SxS% /v W10UIrebase /f %_Nul3%
if not exist "!_cabdir!\" mkdir "!_cabdir!"
call :cleanup
goto :fin
)
set "mumpkgs=Package_for_ServicingStack Package_for_DotNetRollup"
if %_build% lss 26052 set "mumpkgs=%mumpkgs% Package_for_WindowsExperienceFeaturePack Package_for_RollupFix"
set c_pkg=
set c_ver=0
set c_num=0
set s_pkg=
set ssvr_aa=0
set ssvr_bl=0
set ssvr_mj=0
set ssvr_mn=0
if %Cleanup% equ 0 set ResetBase=0
if %_build% geq 22000 (
if %LCUwinre% equ 2 (set LCUwinre=0) else (set LCUwinre=1)
if %_build% geq 26052 (set LCUwinre=0)
)
if %_build% lss 26052 set LCUmsuExpand=0
if %_build% geq 20348 set SkipEdge=0
if %_build% geq 26080 set SkipWebView=0
if %wimfiles% equ 0 (
set WinRE=0
set LCUwinre=0
)
if %dvd%==0 (
set wim2esd=0
set wim2swm=0
set ISO=0
set Delete_Source=0
)
for %%# in (
AutoStart
Net35
Cleanup
ResetBase
WinRE
LCUwinre
LCUmsuExpand
UpdtBootFiles
SkipEdge
SkipWebView
AddDrivers
UseWimlib
wim2esd
wim2swm
ISO
Delete_Source
) do (
if !%%#! neq 0 set _configured=1
)
if /i not "!dismroot!"=="dism.exe" set _configured=1
if %_configured% equ 1 (
echo.
echo ============================================================
echo Configured Options...
echo ============================================================
echo.
  if %Net35% neq 0 (
  echo Net35
  if not "!Net35Source!"=="" echo Net35Source
  )
  for %%# in (
  Cleanup
  ResetBase
  LCUmsuExpand
  UpdtBootFiles
  SkipEdge
  SkipWebView
  AddDrivers
  AutoStart
  UseWimlib
  ) do (
  if !%%#! neq 0 echo %%#
  )
  if %wimfiles%==1 (
  if %WinRE% neq 0 echo WinRE
  if %LCUwinre% neq 0 echo LCUwinre
  )
  if %dvd%==1 (
  if %wim2esd% neq 0 echo wim2esd
  if %wim2esd% equ 0 if %wim2swm% neq 0 echo wim2swm
  if %ISO% neq 0 echo ISO
  if not "!ISODir!"=="" echo ISODir
  if %Delete_Source% neq 0 echo Delete_Source
  )
  if /i not "!DismRoot!"=="dism.exe" echo DismRoot
)
if %dvd%==1 if %copytarget%==1 (
echo.
echo ============================================================
echo Copying DVD Drive contents to work directory...
echo ============================================================
if exist "!_work!\DVD10UI\" rmdir /s /q "!_work!\DVD10UI\" %_Nul1%
robocopy "!target!" "!_work!\DVD10UI" /E /A-:R >nul
set "target=!_work!\DVD10UI"
)
call :extract
if %_sum%==0 goto :fin

:igonline
if %online%==0 goto :igoffline
call :doupdate
if %net35%==1 call :enablenet35
goto :fin

:igoffline
if %offline%==0 goto :igwim
call :doupdate
if %net35%==1 call :enablenet35
if %_offdu%==1 if not exist "!_cabdir!\cmd_dvd\#.tag" (
  mkdir "!_cabdir!\cmd_dvd" %_Nul3%
  copy /y nul "!_cabdir!\cmd_dvd\#.tag" %_Nul3%
  if %UpdtBootFiles% equ 1 (
  if exist "!mountdir!\Windows\Boot\EFI\winsipolicy.p7b" if exist "!cmd_dvd!\efi\microsoft\boot\winsipolicy.p7b" copy /y "!mountdir!\Windows\Boot\EFI\winsipolicy.p7b" "!cmd_dvd!\efi\microsoft\boot\" %_Nul3%
  if exist "!mountdir!\Windows\Boot\EFI\CIPolicies\" if exist "!cmd_dvd!\efi\microsoft\boot\cipolicies\" xcopy /CERY "!mountdir!\Windows\Boot\EFI\CIPolicies" "!cmd_dvd!\efi\microsoft\boot\cipolicies\" %_Nul3%
  for %%i in (efisys.bin,efisys_noprompt.bin) do if exist "!mountdir!\Windows\Boot\DVD\EFI\en-US\%%i" (copy /y "!mountdir!\Windows\Boot\DVD\EFI\en-US\%%i" "!cmd_dvd!\efi\microsoft\boot\" %_Nul1%)
  if /i not %arch%==arm64 (
    copy /y "!mountdir!\Windows\Boot\PCAT\bootmgr" "!cmd_dvd!\" %_Nul1%
    copy /y "!mountdir!\Windows\Boot\EFI\memtest.efi" "!cmd_dvd!\efi\microsoft\boot\" %_Nul1%
    copy /y "!mountdir!\Windows\Boot\PCAT\memtest.exe" "!cmd_dvd!\boot\" %_Nul1%
    )
  )
  if exist "!cmd_dvd!\efi\boot\bootmgfw.efi" copy /y "!mountdir!\Windows\Boot\EFI\bootmgfw.efi" "!cmd_dvd!\efi\boot\bootmgfw.efi" %_Nul1%
  copy /y "!mountdir!\Windows\Boot\EFI\bootmgfw.efi" "!cmd_dvd!\efi\boot\%efifile%" %_Nul1%
  copy /y "!mountdir!\Windows\Boot\EFI\bootmgr.efi" "!cmd_dvd!\" %_Nul1%
)
if not defined isoupdate goto :fin
if %_offdu%==1 if not exist "!_cabdir!\du\" (
  mkdir "!_cabdir!\du" %_Nul3%
  for %%i in (!isoupdate!) do expand.exe -r -f:* "!repo!\%%~i" "!_cabdir!\du" %_Nul1%
  if exist "!mountdir!\Windows\Servicing\Packages\WinPE-Setup-Package~*.mum" (
  if exist "!mountdir!\sources\setup.exe" if exist "!_cabdir!\du\setup.exe" del /f /q "!_cabdir!\du\setup.exe" %_Nul3%
  if %_build% geq 26052 if exist "!mountdir!\sources\setuphost.exe" if exist "!_cabdir!\du\setuphost.exe" del /f /q "!_cabdir!\du\setuphost.exe" %_Nul3%
  )
  xcopy /CRUY "!_cabdir!\du" "!cmd_source!\" %_Nul3%
  if exist "!_cabdir!\du\*.ini" xcopy /CRY "!_cabdir!\du\*.ini" "!cmd_source!\" %_Nul3%
  for /f %%# in ('dir /b /ad "!_cabdir!\du\*-*" %_Nul6%') do if exist "!cmd_source!\%%#\*.mui" copy /y "!_cabdir!\du\%%#\*" "!cmd_source!\%%#\" %_Nul3%
  if exist "!_cabdir!\du\replacementmanifests\" xcopy /CERY "!_cabdir!\du\replacementmanifests" "!cmd_source!\replacementmanifests\" %_Nul3%
)
if exist "!mountdir!\sources\setup.exe" if not exist "!mountdir!\Windows\Servicing\Packages\WinPE-Setup-Package~*.mum" (
  if not exist "!_cabdir!\du\" (
  mkdir "!_cabdir!\du" %_Nul3%
  for %%i in (!isoupdate!) do expand.exe -r -f:* "!repo!\%%~i" "!_cabdir!\du" %_Nul1%
  )
  robocopy "!_cabdir!\du" "!mountdir!\sources" /XL /XX /XO %_Nul3%
  if exist "!_cabdir!\du\*.ini" xcopy /CRY "!_cabdir!\du\*.ini" "!mountdir!\sources\" %_Nul3%
)
goto :fin

:igwim
if %wim%==0 goto :igdvd
if "%indices%"=="*" set "indices="&for /L %%# in (1,1,!imgcount!) do set "indices=!indices! %%#"
call :mount "%targetname%"
if /i not "%targetname%"=="winre.wim" (if exist "!_work!\winre.wim" del /f /q "!_work!\winre.wim" %_Nul1%)
goto :fin

:igdvd
if %dvd%==0 goto :fin
if exist "%SystemRoot%\temp\UpdateAgent.dll" del /f /q "%SystemRoot%\temp\UpdateAgent.dll" %_Nul3%
if exist "%SystemRoot%\temp\Facilitator.dll" del /f /q "%SystemRoot%\temp\Facilitator.dll" %_Nul3%
if "%indices%"=="*" set "indices="&for /L %%# in (1,1,!imgcount!) do set "indices=!indices! %%#"
call :mount sources\install.wim
if exist "!_work!\winre.wim" del /f /q "!_work!\winre.wim" %_Nul1%
set keep=0&set imgcount=%bootimg%&set "indices="&for /L %%# in (1,1,!imgcount!) do set "indices=!indices! %%#"
call :mount sources\boot.wim
if not defined isoupdate goto :dvdproceed
echo.
echo ============================================================
echo Adding setup dynamic update^(s^)...
echo ============================================================
echo.
mkdir "!_cabdir!\du" %_Nul3%
for %%i in (!isoupdate!) do (
echo %%~i
expand.exe -r -f:* "!repo!\%%~i" "!_cabdir!\du" %_Nul1%
)
if %uupboot%==0 (
if exist "!_cabdir!\du\setup.exe" del /f /q "!_cabdir!\du\setup.exe" %_Nul3%
if %_build% geq 26052 if exist "!_cabdir!\du\setuphost.exe" del /f /q "!_cabdir!\du\setuphost.exe" %_Nul3%
)
if %uupboot%==1 xcopy /CRUY "!_cabdir!\du" "!target!\sources\" %_Nul3%
if %uupboot%==0 xcopy /CDRUY "!_cabdir!\du" "!target!\sources\" %_Nul3%
if %uupboot%==0 for /f %%# in ('dir /b /a:-d "!_cabdir!\du\*.*" %_Nul6%') do call :du_fix %%#
if exist "!_cabdir!\du\*.ini" xcopy /CRY "!_cabdir!\du\*.ini" "!target!\sources\" %_Nul3%
for /f %%# in ('dir /b /ad "!_cabdir!\du\*-*" %_Nul6%') do if exist "!target!\sources\%%#\*.mui" copy /y "!_cabdir!\du\%%#\*" "!target!\sources\%%#\" %_Nul3%
if exist "!_cabdir!\du\replacementmanifests\" xcopy /CERY "!_cabdir!\du\replacementmanifests" "!target!\sources\replacementmanifests\" %_Nul3%
rmdir /s /q "!_cabdir!\du\" %_Nul3%

:dvdproceed
xcopy /CRY "!target!\efi\microsoft\boot\fonts" "!target!\boot\fonts\" %_Nul1%
if %_DNF%==1 if exist "!target!\sources\sxs\*netfx3*.cab" (del /f /q "!target!\sources\sxs\*netfx3*.cab" %_Nul1%)
cd /d "!target!\sources"
for /f %%# in ('dir /b /a:-d install.wim') do set "_size=000000%%~z#"
cd /d "!_work!"
if "%_size%" lss "0000004194304000" set wim2swm=0
if %wim2esd%==0 if %wim2swm%==0 goto :fin
if %wim2esd%==0 if %wim2swm%==1 goto :swm
echo.
echo ============================================================
echo Converting install.wim to install.esd ...
echo ============================================================
cd /d "!target!"
for /f "tokens=2 delims=: " %%# in ('dism.exe /english /get-wiminfo /wimfile:"sources\install.wim" ^| find /i "Index"') do set imgcount=%%#
if %_wlib% equ 1 (
echo.
!_wimlib! export sources\install.wim all sources\install.esd --compress=LZMS --solid
call set errcode=!errorlevel!
) else (
if %_all% equ 0 for /L %%# in (1,1,%imgcount%) do %_dism2%:"!_cabdir!" /Export-Image /SourceImageFile:sources\install.wim /SourceIndex:%%# /DestinationImageFile:sources\install.esd /Compress:Recovery
if %_all% equ 1 %_dism2%:"!_cabdir!" /Export-Image /SourceImageFile:sources\install.wim /All /DestinationImageFile:sources\install.esd /Compress:Recovery
call set errcode=!errorlevel!
)
if %errcode% equ 0 (if exist "sources\install.esd" del /f /q sources\install.wim %_Nul1%) else (del /f /q sources\install.esd %_Nul3%)
cd /d "!_work!"
goto :fin

:swm
echo.
echo ============================================================
echo Splitting install.wim into install.swm^(s^)...
echo ============================================================
cd /d "!target!"
if %_wlib% equ 1 (
echo.
!_wimlib! split sources\install.wim sources\install.swm 3500
call set errcode=!errorlevel!
) else (
%_dism2%:"!_cabdir!" /Split-Image /ImageFile:sources\install.wim /SWMFile:sources\install.swm /FileSize:3500
call set errcode=!errorlevel!
)
if %errcode% equ 0 (if exist "sources\install*.swm" del /f /q sources\install.wim %_Nul1%) else (del /f /q sources\install*.swm %_Nul3%)
cd /d "!_work!"
goto :fin

:du_fix
if /i not %~x1==.dll if /i not %~x1==.exe if /i not %~x1==.sys goto :eof
set "_fil1=!_cabdir!\du\%1"
set "_fil2=!target!\sources\%1"
if not exist "!_fil2!" goto :eof
set _ver1s=0&set _ver2s=0
set "cfil1=!_fil1:\=\\!"
set "cfil2=!_fil2:\=\\!"
if %_cwmi% equ 1 (
for /f "tokens=5 delims==." %%a in ('wmic datafile where "name='!cfil1!'" get Version /value ^| find "="') do set /a "_ver1s=%%a"
for /f "tokens=5 delims==." %%a in ('wmic datafile where "name='!cfil2!'" get Version /value ^| find "="') do set /a "_ver2s=%%a"
)
if %_cwmi% equ 0 (
for /f "tokens=4 delims=." %%a in ('%_psc% "([WMI]'CIM_DataFile.Name=''!cfil1!''').Version"') do set /a "_ver1s=%%a"
for /f "tokens=4 delims=." %%a in ('%_psc% "([WMI]'CIM_DataFile.Name=''!cfil2!''').Version"') do set /a "_ver2s=%%a"
)
if %_ver1s% gtr %_ver2s% copy /y "!_fil1!" "!target!\sources\" %_Nul3%
goto :eof

:extract
if /i %arch%==x86 (set efifile=bootia32.efi&set sss=x86) else if /i %arch%==x64 (set efifile=bootx64.efi&set sss=amd64) else (set efifile=bootaa64.efi&set sss=arm64)
if %_embd% equ 0 call :cleaner
if not exist "!_cabdir!\" mkdir "!_cabdir!"
if not exist "!_cabdir!\LCUmum\" mkdir "!_cabdir!\LCUmum"
if not exist "!_cabdir!\LCUall\" mkdir "!_cabdir!\LCUall"
if %online%==0 if %stcexp%==0 if %_build% geq 22000 if exist "%SysPath%\ucrtbase.dll" call :get_dll dpx
if %online%==0 if %LCUmsuExpand% neq 0 if %_build% geq 26052 if %winbuild% geq 9600 (
if exist "%SysPath%\UpdateCompression.dll" (set psfwim=1) else (call :get_dll UpdateCompression)
)
if exist "!_cabdir!\UpdateCompression.dll" if %LCUmsuExpand% neq 0 (
set "_delta=!_cabdir!\UpdateCompression.dll"
set psfwim=1
)
if %psfnet% equ 0 set psfwim=0
call :detector
if %_cab% neq 0 (
set msuchk=0&set count=0
if %online%==0 if exist "!repo!\*defender-dism*%_bit%*.cab" for /f "tokens=* delims=" %%# in ('dir /b "!repo!\*defender-dism*%_bit%*.cab"') do (set "package=%%#"&call :cab0)
if exist "!repo!\*Windows1*-KB*%arch%*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!repo!\*Windows1*-KB*%arch%*.cab"') do (set "package=%%#"&set "dest=%%~n#"&call :cab1)
)
if %_msu% neq 0 (
echo.
if %_embd% equ 0 (
echo ============================================================
echo Extracting .cab files from .msu files...
echo ============================================================
echo.
)
set msuchk=1&set count=0&set msucab=&set uuppkg=
for /f "tokens=* delims=" %%# in ('dir /b /on "!repo!\*Windows1*-KB*%arch%*.msu"') do (set "package=%%#"&set "dest=%%~n#"&call :cab1)
)
if %_sum%==0 (echo.&echo All applicable updates are detected as installed&goto :eof)
echo.
if %_embd% equ 0 (
echo ============================================================
echo Extracting files from update containers ^(cab/wim^)...
echo *** This will require some disk space, please be patient ***
echo ============================================================
echo.
)
cd /d "!_cabdir!"
set _sum=0
if %online%==0 if exist "!repo!\*defender-dism*%_bit%*.cab" for /f "tokens=* delims=" %%# in ('dir /b "!repo!\*defender-dism*%_bit%*.cab"') do (call set /a _sum+=1)
if exist "!repo!\*Windows1*-KB*%arch%*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!repo!\*Windows1*-KB*%arch%*.cab"') do (call set /a _sum+=1)
if %psfwim% equ 1 if exist "!_cabdir!\*Windows1*-KB*%arch%*.wim" for /f "tokens=* delims=" %%# in ('dir /b /on "!_cabdir!\*Windows1*-KB*%arch%*.wim"') do (call set /a _sum+=1)
set count=0&set isoupdate=&set tmpcmp=
if %online%==0 if exist "!repo!\*defender-dism*%_bit%*.cab" for /f "tokens=* delims=" %%# in ('dir /b "!repo!\*defender-dism*%_bit%*.cab"') do (set "package=%%#"&set "dest=%%~n#"&call :cab2)
if exist "!repo!\*Windows1*-KB*%arch%*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!repo!\*Windows1*-KB*%arch%*.cab" ^| findstr /i /v /c:"_inout.cab"') do (set "pkgn=%%~n#"&set "package=%%#"&set "dest=%%~n#"&call :cab2)
if exist "!repo!\Windows1*-KB*%arch%_inout.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!repo!\Windows1*-KB*%arch%_inout.cab"') do (set "pkgn=%%~n#"&set "package=%%#"&set "dest=%%~n#"&call :cab2)
if %psfwim% equ 1 if exist "!_cabdir!\*Windows1*-KB*%arch%*.wim" for /f "tokens=* delims=" %%# in ('dir /b /on "!_cabdir!\*Windows1*-KB*%arch%*.wim"') do (set "pkgn=%%~n#"&set "package=%%#"&set "dest=%%~n#"&call :psfx2)
goto :eof

:cab0
if %wimfiles% equ 1 goto :eof
set "mumtarget=!target!"
call :defender_check
if %_skpp% equ 1 if %_skpd% equ 1 (set /a _cab-=1)
goto :eof

:cab1
:: for /f "tokens=2 delims=-" %%V in ('echo "!package!"') do set kb=%%V
set kb=
set tn=2
:startcabLoop
for /f "tokens=%tn% delims=-" %%A in ('echo !package!') do (
  if not errorlevel 1 (
    echo %%A|findstr /i /b KB %_Nul1% && (set kb=%%A&goto :endcabLoop)
    set /a tn+=1
    goto :startcabLoop
  ) else (
    goto :endcabLoop
  )
)
:endcabLoop
if "%kb%"=="" goto :eof
if %wimfiles% equ 1 goto :cabproceed
for %%# in (
Package_for_%kb%~
%mumpkgs%
) do if exist "!target!\Windows\Servicing\packages\%%#*.mum" (
set "mumcheck=!target!\Windows\Servicing\packages\%%#*.mum"
set "pkgcheck=%%#"
call :mumversion !pkgcheck:~0,14!
if !skip!==1 (set /a _sum-=1&if %msuchk% equ 1 (set /a _msu-=1&goto :eof) else (set /a _cab-=1&goto :eof))
)
:cabproceed
if %msuchk% equ 0 goto :eof
set uupmsu=0
set msuwim=0
cd /d "!repo!"
expand.exe -d -f:*Windows*.psf !package! %_Nul2% | findstr /i %arch%\.psf %_Nul3% && (set uupmsu=1&set msuwim=2)
if %uupmsu% equ 0 if %_build% geq 21382 (
dism.exe /English /List-Image /ImageFile:!package! /Index:1 %_Nul2% | findstr /i %arch%\.psf %_Nul3% && (set uupmsu=1&set msuwim=1)
)
set kbcab=
if %uupmsu% equ 0 for /f "tokens=2 delims=: " %%# in ('expand.exe -d -f:*Windows*.cab !package! %_Nul6% ^| findstr /i %kb%') do set kbcab=%%#
if /i "%kbcab%"=="No" if %uupmsu% equ 0 for /f "tokens=2 delims=: " %%# in ('expand.exe -d -f:SSU-*.cab !package! %_Nul6% ^| findstr /i %kb%') do set kbcab=%%#
cd /d "!_work!"
set /a count+=1
if %uupmsu% equ 1 (
goto :msu1
)
if %_embd% equ 0 (
set "msucab=!msucab! %kbcab%"
) else (
findstr /i /m "%kbcab%" cabmsu.txt %_Nul3% || echo %kbcab%>>cabmsu.txt
if exist "!repo!\%kbcab%" goto :eof
)
echo %count%/%_msu%: %package%
%_exp% -f:*Windows*.cab "!repo!\!package!" "!repo!" %_Null%
set _sfn=%package:~0,-4%.cab
if not exist "!repo!\%kbcab%" (
mkdir "!_cabdir!\check"
%_exp% -f:SSU-*%arch%*.cab "!repo!\!package!" "!_cabdir!\check" %_Null%
for /f %%# in ('dir /b "!_cabdir!\check\*.cab"') do move /y "!_cabdir!\check\%%#" "!repo!\%_sfn%" %_Nul3%
set "tmpssu=!tmpssu! %_sfn%"
rmdir /s /q "!_cabdir!\check\"
)
goto :eof

:msu1
cd /d "!_cabdir!"
if %_embd% equ 0 if exist "%dest%\" rmdir /s /q "%dest%\" %_Nul3%
if not exist "%dest%\chck\" mkdir "%dest%\chck"
if %msuwim% equ 1 if %_build% geq 26052 if %online%==0 (
for /f "tokens=1 delims=\" %%# in ('dism.exe /English /List-Image /ImageFile:"!repo!\!package!" /Index:1 ^| findstr /i /r ".*AggregatedMetadata\.cab"') do %_psc% "$f=[IO.File]::ReadAllText('!_batp!') -split ':wimmsu\:.*';iex ($f[1]);E '!repo!\!package!' '%%#' '%dest%\chck\%%#'"
if not exist "%dest%\chck\*AggregatedMetadata.cab" dism.exe /English /Apply-Image /ImageFile:"!repo!\!package!" /Index:1 /ApplyDir:"%dest%\chck" /NoAcl:all %_Null%
for /f "tokens=* delims=" %%# in ('dir /b /on "%dest%\chck\*AggregatedMetadata.cab" %_Nul6%') do (%_exp% -f:HotpatchCompDB*.cab "%dest%\chck\%%#" "%dest%\chck" %_Null%)
)
if exist "%dest%\chck\HotpatchCompDB*.cab" (
echo Not Supported: %package% [HotPatchUpdate]
rmdir /s /q "%dest%\chck\" %_Nul3%
goto :eof
)
echo %count%/%_msu%: %package% [Combined UUP]
if %msuwim% equ 2 (
%_exp% -f:*Windows*.cab "!repo!\!package!" "%dest%\chck" %_Null%
%_exp% -f:SSU-*%arch%*.cab "!repo!\!package!" "%dest%\chck" %_Null%
)
if %msuwim% equ 1 if not exist "%dest%\chck\*.wim" (
for /f "tokens=1 delims=\" %%# in ('dism.exe /English /List-Image /ImageFile:"!repo!\!package!" /Index:1 ^| findstr /i /r "SSU-.* %arch%\.wim"') do %_psc% "$f=[IO.File]::ReadAllText('!_batp!') -split ':wimmsu\:.*';iex ($f[1]);E '!repo!\!package!' '%%#' '%dest%\chck\%%#'"
if not exist "%dest%\chck\*.wim" dism.exe /English /Apply-Image /ImageFile:"!repo!\!package!" /Index:1 /ApplyDir:"%dest%\chck" /NoAcl:all %_Null%
)
if %msuwim% equ 1 if %psfwim% equ 1 if not exist "%dest%\chck\*.psf" (
for /f "tokens=1 delims=\" %%# in ('dism.exe /English /List-Image /ImageFile:"!repo!\!package!" /Index:1 ^| findstr /i /r "%arch%\.psf"') do %_psc% "$f=[IO.File]::ReadAllText('!_batp!') -split ':wimmsu\:.*';iex ($f[1]);E '!repo!\!package!' '%%#' '%dest%\chck\%%#'"
if not exist "%dest%\chck\*.psf" dism.exe /English /Apply-Image /ImageFile:"!repo!\!package!" /Index:1 /ApplyDir:"%dest%\chck" /NoAcl:all %_Null%
)
if exist "%dest%\chck\*.psf" (
if %psfwim% equ 1 move /y "%dest%\chck\*.psf" "!_cabdir!\" %_Nul3%
del /f /q "%dest%\chck\*.psf" %_Null%
)
for /f "tokens=* delims=" %%# in ('dir /b /on "%dest%\chck\*Windows1*-KB*.*"') do set "compkg=%%#
if %msuwim% equ 2 (
%_exp% -f:update.mum "%dest%\chck\%compkg%" "%dest%" %_Null%
%_exp% -f:%sss%_microsoft-updatetargeting-*os_*.manifest "%dest%\chck\%compkg%" "%dest%" %_Null%
)
if %msuwim% equ 1 (
for /f "tokens=1 delims=\" %%# in ('dism.exe /English /List-Image /ImageFile:"%dest%\chck\%compkg%" /Index:1 ^| findstr /i /r "update.mum %sss%_microsoft-updatetargeting-.*os_"') do %_psc% "$f=[IO.File]::ReadAllText('!_batp!') -split ':wimmsu\:.*';iex ($f[1]);E '%dest%\chck\%compkg%' '%%#' '%dest%\%%#'"
)
if %msuwim% equ 1 if not exist "%dest%\update.mum" (
mkdir %_drv%\_tWIM %_Nul3%
dism.exe /English /Apply-Image /ImageFile:"%dest%\chck\%compkg%" /Index:1 /ApplyDir:"%_drv%\_tWIM" /NoAcl:all %_Null%
copy /y "%_drv%\_tWIM\update.mum" "%dest%\" %_Nul3%
copy /y "%_drv%\_tWIM\%sss%_microsoft-updatetargeting-*os_*.manifest" "%dest%\" %_Nul3%
rmdir /s /q %_drv%\_tWIM\ %_Nul3%
)
if exist "%_drv%\_tWIM\" (
mkdir %_drv%\_del286 %_Null%
robocopy %_drv%\_del286 %_drv%\_tWIM /MIR %_Null%
rmdir /s /q %_drv%\_del286\ %_Null%
rmdir /s /q %_drv%\_tWIM\ %_Nul3%
)
if exist "%dest%\chck\SSU-*%arch%*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "%dest%\chck\SSU-*%arch%*.cab"') do (set "compkg=%%#"&call :uupssu)
if %msuwim% equ 1 if %psfwim% equ 1 (
move /y "%dest%\chck\*.wim" "!_cabdir!\" %_Nul3%
)
rmdir /s /q "%dest%\chck\" %_Nul3%
set msu_%dest%=1
findstr /i /m "Package_for_RollupFix" "%dest%\update.mum" %_Nul3% && (
call :chklcu "%dest%"
)
cd /d "!_work!"
goto :eof

:cab2
if %_embd% equ 0 if exist "%dest%\" rmdir /s /q "%dest%\" %_Nul3%
if not exist "%dest%\" mkdir "%dest%"
set /a count+=1
mkdir "checker"
%_exp% -f:update.mum "!repo!\!package!" "checker" %_Null%
if not exist "checker\update.mum" (
%_exp% -f:*defender*.xml "!repo!\!package!" "checker" %_Null%
if exist "checker\*defender*.xml" (
  echo %count%/%_sum%: %package%
  %_exp% -f:* "!repo!\!package!" "%dest%" %_Null%
) else (
  echo %count%/%_sum%: %package% [Setup DU]
  set isoupdate=!isoupdate! !package!
  )
rmdir /s /q "checker\" %_Nul3%
goto :eof
)
for /f "tokens=2 delims=-" %%V in ('echo %pkgn%') do set pkgid=%%V
%_exp% -f:*.psf.cix.xml "!repo!\!package!" "checker" %_Null%
if exist "checker\*.psf.cix.xml" (
if not exist "!repo!\%pkgn%.psf" if not exist "!repo!\*%pkgid%*%arch%*.psf" (
  echo %count%/%_sum%: %package% / PSF file is missing
  rmdir /s /q "checker\" %_Nul3%
  goto :eof
  )
if %psfnet% equ 0 if %psfcpp% equ 0 (
  echo %count%/%_sum%: %package% / PSFExtractor is not available
  rmdir /s /q "checker\" %_Nul3%
  goto :eof
  )
set psf_%pkgn%=1
)
findstr /i /m "Package_for_RollupFix" "checker\update.mum" %_Nul3% && (
call :chklcu "checker"
)
%_exp% -f:toc.xml "!repo!\!package!" "checker" %_Null%
if exist "checker\toc.xml" (
echo %count%/%_sum%: %package% [Combined]
%_exp% -f:* "!repo!\!package!" "%dest%" %_Null%
if exist "%dest%\SSU-*%arch%*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "%dest%\SSU-*%arch%*.cab"') do (set "compkg=%%#"&call :inrenssu)
if exist "%dest%\Windows1*-KB*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "%dest%\Windows1*-KB*.cab"') do (set "compkg=%%#"&call :inrenupd)
rmdir /s /q "%dest%\" %_Nul3%
rmdir /s /q "checker\" %_Nul3%
goto :eof
)
set _extsafe=0
set "_type="
findstr /i /m "Package_for_SafeOSDU" "checker\update.mum" %_Nul3% && set "_type=[SafeOS DU]"
if not defined _type if %_build% geq 17763 findstr /i /m "WinPE" "checker\update.mum" %_Nul3% && (
%_Nul3% findstr /i /m "Edition\"" "checker\update.mum"
if errorlevel 1 (set "_type=[WinPE]"&set _extsafe=1)
)
if not defined _type set _extsafe=1
if %_extsafe%==1 if not defined _type (
%_exp% -f:*_microsoft-windows-sysreset_*.manifest "!repo!\!package!" "checker" %_Null%
if exist "checker\*_microsoft-windows-sysreset_*.manifest" findstr /i /m "Package_for_RollupFix" "checker\update.mum" %_Nul3% || set "_type=[SafeOS DU]"
)
if %_extsafe%==1 if not defined _type (
%_exp% -f:*_microsoft-windows-winpe_tools_*.manifest "!repo!\!package!" "checker" %_Null%
if exist "checker\*_microsoft-windows-winpe_tools_*.manifest" findstr /i /m "Package_for_RollupFix" "checker\update.mum" %_Nul3% || set "_type=[SafeOS DU]"
)
if %_extsafe%==1 if not defined _type (
%_exp% -f:*_microsoft-windows-winre-tools_*.manifest "!repo!\!package!" "checker" %_Null%
if exist "checker\*_microsoft-windows-winre-tools_*.manifest" findstr /i /m "Package_for_RollupFix" "checker\update.mum" %_Nul3% || set "_type=[SafeOS DU]"
)
if %_extsafe%==1 if not defined _type (
%_exp% -f:*_microsoft-windows-i..dsetup-rejuvenation_*.manifest "!repo!\!package!" "checker" %_Null%
if exist "checker\*_microsoft-windows-i..dsetup-rejuvenation_*.manifest" findstr /i /m "Package_for_RollupFix" "checker\update.mum" %_Nul3% || set "_type=[SafeOS DU]"
)
if not defined _type (
findstr /i /m "Package_for_RollupFix" "checker\update.mum" %_Nul3% && set "_type=[LCU]"
)
if not defined _type (
findstr /i /m "Package_for_WindowsExperienceFeaturePack" "checker\update.mum" %_Nul3% && set "_type=[UX FeaturePack]"
)
if not defined _type (
%_exp% -f:*_microsoft-windows-servicingstack_*.manifest "!repo!\!package!" "checker" %_Null%
if exist "checker\*_microsoft-windows-servicingstack_*.manifest" (
  set "_type=[SSU]"
  call :chkssu "checker"
  )
)
if not defined _type (
%_exp% -f:*_netfx4*.manifest "!repo!\!package!" "checker" %_Null%
if exist "checker\*_netfx4*.manifest" findstr /i /m "Package_for_RollupFix" "checker\update.mum" %_Nul3% || set "_type=[NetFx]"
)
if not defined _type (
%_exp% -f:*_microsoft-windows-s..boot-firmwareupdate_*.manifest "!repo!\!package!" "checker" %_Null%
if exist "checker\*_microsoft-windows-s..boot-firmwareupdate_*.manifest" findstr /i /m "Package_for_RollupFix" "checker\update.mum" %_Nul3% || set "_type=[SecureBoot]"
)
set /a _fixSV=%_build%+1
if not defined _type if %_build% geq 18362 (
%_exp% -f:microsoft-windows-*enablement-package~*.mum "!repo!\!package!" "checker" %_Null%
call :EKB1 "checker" _type [Enablement]
)
call :EKB2 "checker"
if %_build% geq 18362 if exist "checker\*enablement-package*.mum" (
%_exp% -f:*_microsoft-windows-e..-firsttimeinstaller_*.manifest "!repo!\!package!" "checker" %_Null%
if exist "checker\*_microsoft-windows-e..-firsttimeinstaller_*.manifest" set "_type=[Enablement / EdgeChromium]"
)
if not defined _type (
%_exp% -f:*_microsoft-windows-e..-firsttimeinstaller_*.manifest "!repo!\!package!" "checker" %_Null%
if exist "checker\*_microsoft-windows-e..-firsttimeinstaller_*.manifest" set "_type=[EdgeChromium]"
)
if not defined _type (
%_exp% -f:*_adobe-flash-for-windows_*.manifest "!repo!\!package!" "checker" %_Null%
if exist "checker\*_adobe-flash-for-windows_*.manifest" findstr /i /m "Package_for_RollupFix" "checker\update.mum" %_Nul3% || set "_type=[Flash]"
)
echo %count%/%_sum%: %package% %_type%
if not exist "%dest%\update.mum" %_exp% -f:* "!repo!\!package!" "%dest%" %_Null% || (
  rmdir /s /q "%dest%\" %_Nul3%
  set directcab=!directcab! !package!
)
if exist "%dest%\*cablist.ini" %_exp% -f:* "%dest%\*.cab" "%dest%" %_Null% || (
  rmdir /s /q "%dest%\" %_Nul3%
  set directcab=!directcab! !package!
)
if exist "%dest%\*cablist.ini" (
  del /f /q "%dest%\*cablist.ini" %_Nul3%
  del /f /q "%dest%\*.cab" %_Nul3%
)
set _sbst=0
if defined psf_%pkgn% (
if not exist "%dest%\express.psf.cix.xml" for /f %%# in ('dir /b /a:-d "%dest%\*.psf.cix.xml"') do rename "%dest%\%%#" express.psf.cix.xml %_Nul3%
subst %_sdr% "!_cabdir!" %_Nul3% && set _sbst=1
if !_sbst! equ 1 pushd %_sdr%
if not exist "!package!" (
  copy /y "!repo!\%pkgn%.*" . %_Nul3%
  if not exist "%pkgn%.psf" for /f %%# in ('dir /b /a:-d "!repo!\*%pkgid%*%arch%*.psf"') do copy /y "!repo!\%%#" %pkgn%.psf %_Nul3%
  )
if %psfcpp% equ 0 (
  %_Nul3% %_psc% "$f=[IO.File]::ReadAllText('!_batp!') -split ':cabpsf\:.*';iex ($f[1]);P '%package%'"
  )
if %psfcpp% equ 1 (
  copy /y "!_exe!" . %_Nul3%
  PSFExtractor.exe !package! %_Null%
  )
dir /b /ad "%dest%\*_microsoft*" %_Null% || (
  echo Error: failed to extract PSF update
  rmdir /s /q "%dest%\" %_Nul3%
  set psf_%pkgn%=
  )
if !_sbst! equ 1 popd
if !_sbst! equ 1 subst %_sdr% /d %_Nul3%
)
rmdir /s /q "checker\" %_Nul3%
goto :eof

:psfx2
if %_embd% equ 0 if exist "%dest%\" rmdir /s /q "%dest%\" %_Nul3%
if not exist "%dest%\" mkdir "%dest%"
for /f "tokens=* delims=" %%# in ('dir /b /on "!repo!\*%pkgn%*.msu"') do (set "pkgm=%%~n#")
set msu_%pkgm%=
set psfx_%pkgn%=1
set /a count+=1
echo %count%/%_sum%: %package% [LCU]
dism.exe /English /Apply-Image /ImageFile:"!_cabdir!\%package%" /Index:1 /ApplyDir:"%dest%" /NoAcl:all %_Null%
if not exist "%dest%\express.psf.cix.xml" for /f %%# in ('dir /b /a:-d "%dest%\*.psf.cix.xml"') do rename "%dest%\%%#" express.psf.cix.xml %_Nul3%
set _sbst=0
subst %_sdr% "!_cabdir!" %_Nul3% && set _sbst=1
if !_sbst! equ 1 pushd %_sdr%
%_Nul3% %_psc% "$f=[IO.File]::ReadAllText('!_batp!') -split ':cabpsf\:.*';iex ($f[1]);P '%package%' '%_delta%'"
dir /b /ad "%dest%\*_microsoft*" %_Null% || (
  echo Error: failed to extract PSF WIM update
  copy /y "%dest%\update.mum" . %_Nul3%
  copy /y "%dest%\%sss%_microsoft-updatetargeting-*os_*.manifest" . %_Nul3%
  rmdir /s /q "%dest%\" %_Nul3%
  mkdir "%dest%" %_Nul3%
  move /y "update.mum" "%dest%\" %_Nul3%
  move /y "%sss%_microsoft-updatetargeting-*os_*.manifest" "%dest%\" %_Nul3%
  set psfx_%pkgn%=
  set msu_%pkgm%=1
  )
if !_sbst! equ 1 popd
if !_sbst! equ 1 subst %_sdr% /d %_Nul3%
for /f "tokens=5-8 delims==. " %%H in ('findstr /i Package_for_RollupFix "%dest%\update.mum"') do set "cver=%%~H.%%I.%%J.%%K
for /f "tokens=2 delims=-" %%V in ('echo %dest%') do set kbn=%%V
findstr /i Baseline "%dest%\update.mum" %_Nul1% && (
set "basekbn=!basekbn! %kbn%"
set "basepkg=!basepkg! Package_for_RollupFix~%_Pkt%~%sss%~~%cver%"
)
:: if exist "!_cabdir!\LCUall\*%pkgm%*.msu" del /f /q "!_cabdir!\LCUall\*%pkgm%*.msu" %_Nul3%
goto :eof

:vrpad
set cuvr=%1
       if %cuvr% lss 10 (set cuvr=0000%cuvr%
) else if %cuvr% lss 100 (set cuvr=000%cuvr%
) else if %cuvr% lss 1000 (set cuvr=00%cuvr%
) else if %cuvr% lss 10000 (set cuvr=0%cuvr%
)
goto :eof

:chklcu
set /a c_num+=1
set kbvr=0
for /f "tokens=5-8 delims==. " %%H in ('findstr /i Package_for_RollupFix "%~1\update.mum"') do set "kbvr=%%I"&set "cver=%%~H.%%I.%%J.%%K
if %_build% geq 22621 (
if not exist "!_cabdir!\LCUmum\Package_for_RollupFix~%_Pkt%~%sss%~~%cver%.mum" copy /y "%~1\update.mum" "!_cabdir!\LCUmum\Package_for_RollupFix~%_Pkt%~%sss%~~%cver%.mum" %_Nul1%
)
call :vrpad %kbvr%
if %_build% geq 26052 (
if not exist "!_cabdir!\LCUall\%cuvr%-!package!" copy /y "!repo!\!package!" "!_cabdir!\LCUall\%cuvr%-!package!" %_Nul1%
)
if %kbvr% geq %c_ver% (
set "c_ver=%kbvr%"
set "c_pkg=%package%"
) else (
goto :eof
)
copy /y "%~1\update.mum" %SystemRoot%\temp\ %_Nul1%
call :datemum isodate isotime
goto :eof

:chkssu
set latest=0
set chvr_aa=0
set chvr_bl=0
set chvr_mj=0
set chvr_mn=0
for /f "tokens=5-8 delims==. " %%H in ('findstr /i Package_for_ "%~1\update.mum"') do set "chvr_aa=%%~H"&set "chvr_bl=%%I"&set "chvr_mj=%%J"&set "chvr_mn=%%K
if %chvr_aa% gtr %ssvr_aa% set latest=1
if %chvr_aa% equ %ssvr_aa% if %chvr_bl% gtr %ssvr_bl% set latest=1
if %chvr_aa% equ %ssvr_aa% if %chvr_bl% equ %ssvr_bl% if %chvr_mj% gtr %ssvr_mj% set latest=1
if %chvr_aa% equ %ssvr_aa% if %chvr_bl% equ %ssvr_bl% if %chvr_mj% equ %ssvr_mj% if %chvr_mn% gtr %ssvr_mn% set latest=1
if %latest% equ 1 (
set "s_pkg=%package%"
set ssvr_aa=%chvr_aa%
set ssvr_bl=%chvr_bl%
set ssvr_mj=%chvr_mj%
set ssvr_mn=%chvr_mn%
)
goto :eof

:uupssu
if exist "!repo!\%compkg:~0,-4%*.cab" goto :eof
set kbupd=
%_exp% -f:update.mum "%dest%\chck\%compkg%" "%dest%\chck" %_Null%
if not exist "%dest%\chck\update.mum" goto :eof
for /f "tokens=3 delims== " %%# in ('findstr /i releaseType "%dest%\chck\update.mum"') do set kbupd=%%~#
if "%kbupd%"=="" goto :eof
set _ufn=Windows10.0-%kbupd%-%arch%_inout.cab
dir /b /on "%dest%\chck\*Windows1*-KB*.*" %_Nul2% | findstr /i "Windows11\." %_Nul1% && set _ufn=Windows11.0-%kbupd%-%arch%_inout.cab
dir /b /on "%dest%\chck\*Windows1*-KB*.*" %_Nul2% | findstr /i "Windows12\." %_Nul1% && set _ufn=Windows12.0-%kbupd%-%arch%_inout.cab
if not exist "!repo!\%_ufn%" (
move /y "%dest%\chck\%compkg%" "!repo!\%_ufn%" %_Nul3%
)
if %_embd% equ 0 (
set "uuppkg=!uuppkg! %_ufn%"
) else (
findstr /i /m "%_ufn%" cmpcab.txt %_Nul3% || echo %_ufn%>>cmpcab.txt
if exist "!repo!\%_ufn%" if exist "%dest%\chck\%compkg%" del /f /q "%dest%\chck\%compkg%"
)
goto :eof

:inrenssu
if exist "!repo!\%compkg:~0,-4%*.cab" goto :eof
set kbupd=
%_exp% -f:update.mum "%dest%\%compkg%" "%dest%" %_Null%
if not exist "%dest%\update.mum" goto :eof
for /f "tokens=3 delims== " %%# in ('findstr /i releaseType "%dest%\update.mum"') do set kbupd=%%~#
if "%kbupd%"=="" goto :eof
set _ufn=Windows10.0-%kbupd%-%arch%_inout.cab
dir /b /on "%dest%\Windows1*-KB*.*" %_Nul2% | findstr /i "Windows11\." %_Nul1% && set _ufn=Windows11.0-%kbupd%-%arch%_inout.cab
dir /b /on "%dest%\Windows1*-KB*.*" %_Nul2% | findstr /i "Windows12\." %_Nul1% && set _ufn=Windows12.0-%kbupd%-%arch%_inout.cab
if not exist "!repo!\%_ufn%" (
call set /a _sum+=1
move /y "%dest%\%compkg%" "!repo!\%_ufn%" %_Nul3%
)
if %_embd% equ 0 (
set "tmpcmp=!tmpcmp! %_ufn%"
) else (
findstr /i /m "%_ufn%" cmpcab.txt %_Nul3% || echo %_ufn%>>cmpcab.txt
if exist "!repo!\%_ufn%" if exist "%dest%\%compkg%" del /f /q "%dest%\%compkg%"
)
goto :eof

:inrenupd
for /f "tokens=2 delims=-" %%V in ('echo %compkg%') do set kbupd=%%V
set _ufn=Windows10.0-%kbupd%-%arch%_inout.cab
echo %compkg%| findstr /i "Windows11\." %_Nul1% && set _ufn=Windows11.0-%kbupd%-%arch%_inout.cab
echo %compkg%| findstr /i "Windows12\." %_Nul1% && set _ufn=Windows12.0-%kbupd%-%arch%_inout.cab
if not exist "!repo!\%_ufn%" (
call set /a _sum+=1
move /y "%dest%\%compkg%" "!repo!\%_ufn%" %_Nul3%
)
if %_embd% equ 0 (
set "tmpcmp=!tmpcmp! %_ufn%"
) else (
findstr /i /m "%_ufn%" cmpcab.txt %_Nul3% || echo %_ufn%>>cmpcab.txt
if exist "!repo!\%_ufn%" if exist "%dest%\%compkg%" del /f /q "%dest%\%compkg%"
)
goto :eof

:datemum
set "mumfile=%SystemRoot%\temp\update.mum"
set "chkfile=!mumfile:\=\\!"
if %_cwmi% equ 1 for /f "tokens=2 delims==" %%# in ('wmic datafile where "name='!chkfile!'" get LastModified /value') do set "mumdate=%%#"
if %_cwmi% equ 0 for /f %%# in ('%_psc% "([WMI]'CIM_DataFile.Name=''!chkfile!''').LastModified"') do set "mumdate=%%#"
set "%1=!mumdate:~2,2!!mumdate:~4,2!!mumdate:~6,2!-!mumdate:~8,4!"
set "%2=!mumdate:~4,2!/!mumdate:~6,2!/!mumdate:~0,4!,!mumdate:~8,2!:!mumdate:~10,2!:!mumdate:~12,2!"
exit /b

:doupdate
set verb=1
set "mumtarget=!mountdir!"
if not "%1"=="" (
set verb=0
set "mumtargeb=!mountdir!"
set "mumtarget=!winremount!"
set dismtarget=/image:"!winremount!"
)
if %verb%==1 if exist "!mumtarget!\Windows\System32\winpeshl.ini" (
find /i "recenv" "!mumtarget!\Windows\System32\winpeshl.ini" %_Nul3% && set verb=0
)
if %verb%==1 (
echo.
echo ============================================================
echo Checking Updates...
echo ============================================================
)
if %online%==1 (
set SOFTWARE=SOFTWARE
set COMPONENTS=COMPONENTS
) else (
set SOFTWARE=uiSOFTWARE
set COMPONENTS=uiCOMPONENTS
)
set "_Wnn=HKLM\%SOFTWARE%\Microsoft\Windows\CurrentVersion\SideBySide\Winners"
set "_Cmp=HKLM\%COMPONENTS%\DerivedData\Components"
if exist "!mumtarget!\Windows\Servicing\Packages\*~arm64~~*.mum" (
set "xBT=arm64"
set "_EsuCom=arm64_%_EsuCmp%_%_Pkt%_%_OurVer%_none_e55ca6c027a999a2"
set "_SupCom=arm64_%_SupCmp%_%_Pkt%_%_OurVer%_none_8b15303df56a09af"
set "_CedCom=arm64_%_CedCmp%_%_Pkt%_%_OurVer%_none_7cb088037a42a80b"
set "_EwvCom=arm64_%_EwvCmp%_%_Pkt%_%_OurVer%_none_0fff064ea926e049"
set "_EsuKey=%_Wnn%\arm64_%_EsuCmp%_%_Pkt%_none_0e8b3f09ce2fa7ce"
set "_SupKey=%_Wnn%\arm64_%_SupCmp%_%_Pkt%_none_0a035f900ca87ee9"
set "_EdgKey=%_Wnn%\arm64_%_EdgCmp%_%_Pkt%_none_1e5e2b2c8adcf701"
set "_CedKey=%_Wnn%\arm64_%_CedCmp%_%_Pkt%_none_df3eefecc502346d"
set "_EwvKey=%_Wnn%\arm64_%_EwvCmp%_%_Pkt%_none_b46fca614e054a9f"
) else if exist "!mumtarget!\Windows\Servicing\Packages\*~amd64~~*.mum" (
set "xBT=amd64"
set "_EsuCom=amd64_%_EsuCmp%_%_Pkt%_%_OurVer%_none_e55c9e8627a9a506"
set "_SupCom=amd64_%_SupCmp%_%_Pkt%_%_OurVer%_none_8b152803f56a1513"
set "_CedCom=amd64_%_CedCmp%_%_Pkt%_%_OurVer%_none_7cb07fc97a42b36f"
set "_EwvCom=amd64_%_EwvCmp%_%_Pkt%_%_OurVer%_none_0ffefe14a926ebad"
set "_EsuKey=%_Wnn%\amd64_%_EsuCmp%_%_Pkt%_none_0e8b36cfce2fb332"
set "_SupKey=%_Wnn%\amd64_%_SupCmp%_%_Pkt%_none_0a0357560ca88a4d"
set "_EdgKey=%_Wnn%\amd64_%_EdgCmp%_%_Pkt%_none_1e5e22f28add0265"
set "_CedKey=%_Wnn%\amd64_%_CedCmp%_%_Pkt%_none_df3ee7b2c5023fd1"
set "_EwvKey=%_Wnn%\amd64_%_EwvCmp%_%_Pkt%_none_b46fc2274e055603"
) else (
set "xBT=x86"
set "_EsuCom=x86_%_EsuCmp%_%_Pkt%_%_OurVer%_none_893e03026f4c33d0"
set "_SupCom=x86_%_SupCmp%_%_Pkt%_%_OurVer%_none_2ef68c803d0ca3dd"
set "_CedCom=x86_%_CedCmp%_%_Pkt%_%_OurVer%_none_2091e445c1e54239"
set "_EwvCom=x86_%_EwvCmp%_%_Pkt%_%_OurVer%_none_b3e06290f0c97a77"
set "_EsuKey=%_Wnn%\x86_%_EsuCmp%_%_Pkt%_none_b26c9b4c15d241fc"
set "_SupKey=%_Wnn%\x86_%_SupCmp%_%_Pkt%_none_ade4bbd2544b1917"
set "_EdgKey=%_Wnn%\x86_%_EdgCmp%_%_Pkt%_none_c23f876ed27f912f"
set "_CedKey=%_Wnn%\x86_%_CedCmp%_%_Pkt%_none_83204c2f0ca4ce9b"
set "_EwvKey=%_Wnn%\x86_%_EwvCmp%_%_Pkt%_none_585126a395a7e4cd"
)
for /f "tokens=4,5,6 delims=_" %%H in ('dir /b "!mumtarget!\Windows\WinSxS\Manifests\%xBT%_microsoft-windows-foundation_*.manifest"') do set "_Fnd=microsoft-w..-foundation_%_Pkt%_%%H_%%~nJ"
if %_build% geq 14393 if %_build% lss 19041 if not exist "!mumtarget!\Windows\WinSxS\Manifests\%_SupCom%.manifest" call :Latent _Sup %_Nul3%
if %_build% geq 17763 if %_build% lss 20348 if not exist "!mumtarget!\Windows\WinSxS\Manifests\%_EsuCom%.manifest" call :Latent _Esu %_Nul3%
if %_build% geq 17134 if %_build% lss 20348 if not exist "!mumtarget!\Windows\WinSxS\Manifests\%_CedCom%.manifest" if not exist "!mumtarget!\Windows\WinSxS\Manifests\%xBT%_%_CedCmp%_*.manifest" if not exist "!mumtarget!\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" if %SkipEdge% equ 1 call :Latent _Ced %_Nul3%
if %_build% geq 19041 if %_build% lss 26080 if not exist "!mumtarget!\Windows\WinSxS\Manifests\%_EwvCom%.manifest" if not exist "!mumtarget!\Windows\WinSxS\Manifests\%xBT%_%_EwvCmp%_*.manifest" if not exist "!mumtarget!\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" if %SkipWebView% equ 1 call :Latent _Ewv %_Nul3%
set lcuall=
set lcumsu=
set mpamfe=
set servicingstack=
set cumulative=
set netupdt=
set netpack=
set netroll=
set netlcu=
set netmsu=
set secureboot=
set edge=
set safeos=
set callclean=
set fupdt=
set supdt=
set cupdt=
set dupdt=
set overall=
set lcupkg=
set discard=0
set discardre=0
set ldr=&set listc=0&set list=1&set AC=100
set _sum=0
if exist "!repo!\*Windows1*-KB*%arch%*.cab" (for /f "tokens=* delims=" %%# in ('dir /b /on "!repo!\*Windows1*-KB*%arch%*.cab"') do (call set /a _sum+=1))
if %_build% geq 21382 if exist "!repo!\*Windows1*-KB*%arch%*.msu" (for /f "tokens=* delims=" %%# in ('dir /b /on "!repo!\*Windows1*-KB*%arch%*.msu"') do if defined msu_%%~n# (call set /a _sum+=1))
if %psfwim% equ 1 if exist "!_cabdir!\*Windows1*-KB*%arch%*.wim" (for /f "tokens=* delims=" %%# in ('dir /b /on "!_cabdir!\*Windows1*-KB*%arch%*.wim"') do if defined psfx_%%~n# (call set /a _sum+=1))
if not exist "!mumtarget!\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" if %online%==0 if exist "!repo!\*defender-dism*%_bit%*.cab" (for /f "tokens=* delims=" %%# in ('dir /b "!repo!\*defender-dism*%_bit%*.cab"') do (call set /a _sum+=1))
if exist "!repo!\*Windows1*-KB*%arch%*.cab" (for /f "tokens=* delims=" %%# in ('dir /b /on "!repo!\*Windows1*-KB*%arch%*.cab"') do (set "packx=%%~x#"&set "package=%%#"&set "dest=%%~n#"&call :procmum))
if %_build% geq 21382 if exist "!repo!\*Windows1*-KB*%arch%*.msu" (for /f "tokens=* delims=" %%# in ('dir /b /on "!repo!\*Windows1*-KB*%arch%*.msu"') do if defined msu_%%~n# (set "packx=%%~x#"&set "package=%%#"&set "dest=%%~n#"&call :procmum))
if %psfwim% equ 1 if exist "!_cabdir!\*Windows1*-KB*%arch%*.wim" (for /f "tokens=* delims=" %%# in ('dir /b /on "!_cabdir!\*Windows1*-KB*%arch%*.wim"') do if defined psfx_%%~n# (set "packx=%%~x#"&set "package=%%#"&set "dest=%%~n#"&call :procmum))
if not exist "!mumtarget!\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" if %online%==0 if exist "!repo!\*defender-dism*%_bit%*.cab" (for /f "tokens=* delims=" %%# in ('dir /b "!repo!\*defender-dism*%_bit%*.cab"') do (set "packx=%%~x#"&set "package=%%#"&set "dest=%%~n#"&call :procmum))
if %verb%==1 if %_sum%==0 if exist "!mountdir!\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (echo.&echo All applicable updates are detected as installed&call set discard=1&goto :eof)
if %verb%==1 if %_sum%==0 (echo.&echo All applicable updates are detected as installed&goto :eof)
if %verb%==0 if %_sum%==0 (echo.&echo All applicable updates are detected as installed&call set discardre=1&goto :eof)
set dowinre=0
set doboot=0
set doinstall=0
if defined cumulative if exist "!mumtarget!\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
if %verb%==0 if %LCUwinre%==1 set dowinre=1
if %verb%==1 set doboot=1
)
if defined cumulative if not exist "!mumtarget!\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
if %verb%==1 set doinstall=1
)
if defined lcumsu if exist "!mumtarget!\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
if %verb%==0 if %LCUwinre%==1 set dowinre=1
if %verb%==1 set doboot=1
)
if defined lcumsu if not exist "!mumtarget!\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
if %verb%==1 set doinstall=1
)
if %verb%==0 if %dowinre%==0 if not defined safeos (echo.&echo No other updates are detected, skipping servicing stack update&call set discardre=1&goto :eof)
if %listc% lss %ac% set "ldr%list%=%ldr%"
if %online%==0 if %_build% geq 22621 if %winbuild% lss 10240 reg.exe query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentMajorVersionNumber %_Nul3% || (
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentMajorVersionNumber /t REG_DWORD /d 10 /f
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentMinorVersionNumber /t REG_DWORD /d 0 /f
)
if %online%==0 if %_build% geq 19041 if %winbuild% lss 17133 if not exist "%SysPath%\ext-ms-win-security-slc-l1-1-0.dll" (
copy /y %SysPath%\slc.dll %SysPath%\ext-ms-win-security-slc-l1-1-0.dll %_Nul1%
if /i not %xOS%==x86 copy /y %SystemRoot%\SysWOW64\slc.dll %SystemRoot%\SysWOW64\ext-ms-win-security-slc-l1-1-0.dll %_Nul1%
)
if %online%==0 if not exist "!mumtarget!\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
reg.exe load HKLM\%SOFTWARE% "!mumtarget!\Windows\System32\Config\SOFTWARE" %_Nul1%
if %winbuild% lss 15063 if /i %arch%==arm64 reg.exe add HKLM\%SOFTWARE%\Microsoft\Windows\CurrentVersion\SideBySide /v AllowImproperDeploymentProcessorArchitecture /t REG_DWORD /d 1 /f %_Nul1%
if %winbuild% lss 9600 reg.exe add HKLM\%SOFTWARE%\Microsoft\Windows\CurrentVersion\SideBySide /v AllowImproperDeploymentProcessorArchitecture /t REG_DWORD /d 1 /f %_Nul1%
reg.exe save HKLM\%SOFTWARE% "!mumtarget!\Windows\System32\Config\SOFTWARE2" /y %_Nul1%
reg.exe unload HKLM\%SOFTWARE% %_Nul1%
move /y "!mumtarget!\Windows\System32\Config\SOFTWARE2" "!mumtarget!\Windows\System32\Config\SOFTWARE" %_Nul1%
)
if %online%==0 if exist "!mumtarget!\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" if /i not %arch%==arm64 (
reg.exe load HKLM\%SOFTWARE% "!mumtarget!\Windows\System32\Config\SOFTWARE" %_Nul1%
reg.exe add HKLM\%SOFTWARE%\%_sbs% /v DisableComponentBackups /t REG_DWORD /d 1 /f %_Nul1%
reg.exe unload HKLM\%SOFTWARE% %_Nul1%
)
if defined netpack set "ldr=!netpack! !ldr!"
for %%# in (dupdt,cupdt,supdt,fupdt,safeos,secureboot,edge,ldr,cumulative,lcumsu) do if defined %%# set overall=1
if defined servicingstack (
if %verb%==1 (
echo.
echo ============================================================
echo Installing servicing stack update...
echo ============================================================
)
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismSSU.log" /Add-Package %servicingstack%
if not defined overall call :cleanup
)
if not defined overall if not defined mpamfe goto :eof
if %verb%==1 (
echo.
echo ============================================================
echo Installing updates...
echo ============================================================
)
if defined safeos (
set callclean=1
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismWinPE.log" /Add-Package %safeos%
if !errorlevel! equ 1726 %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNUL.log" /Get-Packages %_Nul3%
)
if defined secureboot (
set callclean=1
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismSecureBoot.log" /Add-Package %secureboot%
if !errorlevel! equ 1726 %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNUL.log" /Get-Packages %_Nul3%
)
if defined ldr (
set callclean=1
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismUpdt.log" /Add-Package %ldr%
if !errorlevel! equ 1726 %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNUL.log" /Get-Packages %_Nul3%
)
if defined fupdt (
set "_SxsKey=%_EdgKey%"
set "_SxsCmp=%_EdgCmp%"
set "_SxsIdn=%_EdgIdn%"
set "_SxsCF=256"
set "_DsmLog=DismEdge.log"
for %%# in (%fupdt%) do (set "dest=%%~n#"&call :pXML)
)
if defined supdt (
set "_SxsKey=%_SupKey%"
set "_SxsCmp=%_SupCmp%"
set "_SxsIdn=%_SupIdn%"
set "_SxsCF=64"
set "_DsmLog=DismSupSvc.log"
for %%# in (%supdt%) do (set "dest=%%~n#"&call :pXML)
)
if defined cupdt (
set "_SxsKey=%_CedKey%"
set "_SxsCmp=%_CedCmp%"
set "_SxsIdn=%_CedIdn%"
set "_SxsCF=256"
set "_DsmLog=DismLCUs.log"
for %%# in (%cupdt%) do (set "dest=%%~n#"&call :pXML)
)
set _dualSxS=
if defined dupdt (
set _dualSxS=1
set "_SxsKey=%_SupKey%"
set "_SxsCmp=%_SupCmp%"
set "_SxsIdn=%_SupIdn%"
set "_SxsCF=64"
set "_DsmLog=DismLCUs.log"
for %%# in (%dupdt%) do (set "dest=%%~n#"&call :pXML)
)
if %dowinre%==0 goto :cuboot
set callclean=1
if defined cumulative (
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismLCU_winre.log" /Add-Package %cumulative%
if !errorlevel! equ 1726 %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNUL.log" /Get-Packages %_Nul3%
)
if defined lcumsu for %%# in (%lcumsu%) do (
echo.&echo %%~nx#
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismLCU_winre.log" /Add-Package /PackagePath:%%#
if !errorlevel! equ 1726 %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNUL.log" /Get-Packages %_Nul3%
)
:cuboot
if %doboot%==0 goto :cuinstall
set callclean=1
if defined lcumsu if %_build% geq 26052 if exist "!mumtarget!\Windows\Servicing\Packages\WinPE-Rejuv-Package~*.mum" for /f "delims=" %%# in ('dir /b /a:-d "!mumtarget!\Windows\Servicing\Packages\WinPE-Rejuv-Package~*.mum"') do (
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNUL.log" /Remove-Package /PackageName:%%~n#
)
if defined cumulative (
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismLCU_boot.log" /Add-Package %cumulative%
if !errorlevel! equ 1726 %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNUL.log" /Get-Packages %_Nul3%
)
if defined lcumsu for %%# in (%lcumsu%) do (
echo.&echo %%~nx#
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismLCU_boot.log" /Add-Package /PackagePath:%%#
if !errorlevel! equ 1726 %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNUL.log" /Get-Packages %_Nul3%
)
:cuinstall
if %doinstall%==0 goto :cuwd
set callclean=1
if defined cumulative (
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismLCU.log" /Add-Package %cumulative%
if !errorlevel! equ 1726 %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNUL.log" /Get-Packages %_Nul3%
)
if defined lcumsu for %%# in (%lcumsu%) do (
echo.&echo %%~nx#
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismLCU.log" /Add-Package /PackagePath:%%#
if !errorlevel! equ 1726 %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNUL.log" /Get-Packages %_Nul3%
)
if %_build% equ 14393 if %wimfiles% equ 1 call :MeltdownSpectre
if not exist "!mumtarget!\Windows\Servicing\Packages\Package_for_RollupFix*.mum" goto :cuwd
if %online%==1 goto :cuwd
if not defined lcumsu goto :cuwd
:: if %_build% geq 26052 goto :cuwd
if not exist "!_cabdir!\LCUmum\*.mum" goto :cuwd
for /f %%# in ('dir /b /a:-d /od "!mumtarget!\Windows\Servicing\Packages\Package_for_RollupFix*.mum" %_Nul6%') do if exist "!_cabdir!\LCUmum\%%#" (
%_Nul3% icacls "!mumtarget!\Windows\Servicing\Packages\%%#" /save "!_cabdir!\acl.txt"
%_Nul3% takeown /f "!mumtarget!\Windows\Servicing\Packages\%%#" /A
%_Nul3% icacls "!mumtarget!\Windows\Servicing\Packages\%%#" /grant *S-1-5-32-544:F
%_Nul3% copy /y "!_cabdir!\LCUmum\%%#" "!mumtarget!\Windows\Servicing\Packages\%%#"
%_Nul3% icacls "!mumtarget!\Windows\Servicing\Packages\%%#" /setowner *S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464
%_Nul3% icacls "!mumtarget!\Windows\Servicing\Packages" /restore "!_cabdir!\acl.txt"
%_Nul3% del /f /q "!_cabdir!\acl.txt"
)
:cuwd
if defined basekbn if %verb%==1 call :regBase
if defined lcupkg call :ReLCU
if defined callclean call :cleanup
if defined mpamfe (
echo.
echo ============================================================
echo Adding Defender update...
echo ============================================================
call :defender_update
)
if not defined edge goto :eof
if defined edge (
echo.
echo ============================================================
echo Installing EdgeChromium update...
echo ============================================================
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismEdge.log" /Add-Package %edge%
if !errorlevel! equ 1726 %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNUL.log" /Get-Packages %_Nul3%
)
goto :eof

:regBase
if not exist "!mumtarget!\Windows\Servicing\Packages\Package_for_RollupFix*.mum" goto :eof
if exist "!_cabdir!\W10UI*.*" del /f /q "!_cabdir!\W10UI*.*" %_Nul3%
set "_k_=HKEY_LOCAL_MACHINE\%SOFTWARE%\%_CBS%"
set "_p_=HKLM:\%SOFTWARE%\%_CBS%"
reg.exe load HKLM\%SOFTWARE% "!mumtarget!\Windows\System32\Config\SOFTWARE" %_Nul1%

reg.exe query "%_k_%" /s /v Baseline | findstr /i HKEY_LOCAL_MACHINE | findstr /i /v Package_for_RollupFix >>"!_cabdir!\W10UIbaseline.txt"
type nul>"!_cabdir!\W10UIsimilar.txt"
if exist "!_cabdir!\W10UIbaseline.txt" for /f "usebackq tokens=8 delims=\." %%G in ("!_cabdir!\W10UIbaseline.txt") do (
findstr /i "%%G" "!_cabdir!\W10UIsimilar.txt" %_Null% || reg.exe query "%_k_%" /k /f "%%G" %_Nul2% | findstr /i HKEY_LOCAL_MACHINE >>"!_cabdir!\W10UIsimilar.txt"
)
if exist "!mumtarget!\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" for %%G in (Microsoft-Windows-WinPE-LanguagePack-Package~ Microsoft-Windows-WinPE-Package~) do (
findstr /i "%%G" "!_cabdir!\W10UIsimilar.txt" %_Null% || reg.exe query "%_k_%" /k /f "%%G" %_Nul2% | findstr /i HKEY_LOCAL_MACHINE >>"!_cabdir!\W10UIsimilar.txt"
)
findstr /i HKEY_LOCAL_MACHINE "!_cabdir!\W10UIsimilar.txt" %_Null% && for %%# in (%basekbn%) do (
for /f "usebackq tokens=8 delims=\" %%G in ("!_cabdir!\W10UIsimilar.txt") do reg.exe query "%_k_%\%%G" /v InstallLocation %_Nul2% | findstr /i %%# %_Nul1% && echo %%G >>"!_cabdir!\W10UImatched.txt"
)
if exist "!_cabdir!\W10UImatched.txt" for /f "usebackq tokens=1 delims= " %%G in ("!_cabdir!\W10UImatched.txt") do (
(echo New-ItemProperty '%_p_%\%%G' Baseline -Value 1 -Force -EA 0)>>"!_cabdir!\W10UIreg.txt"
)
for %%# in (%basepkg%) do (
(echo New-ItemProperty '%_p_%\%%#' Baseline -Value 1 -Force -EA 0)>>"!_cabdir!\W10UIreg.txt"
)
%_Nul3% %_psc% "$r='!_cabdir!\W10UIreg.txt'; $f=[IO.File]::ReadAllText('!_batp!') -split ':cbsreg\:.*';iex ($f[1])"

if /i %xOS%==x86 if /i not %arch%==x86 reg.exe save HKLM\%SOFTWARE% "!mumtarget!\Windows\System32\Config\SOFTWARE2" /y %_Nul1%
reg.exe unload HKLM\%SOFTWARE% %_Nul1%
if /i %xOS%==x86 if /i not %arch%==x86 move /y "!mumtarget!\Windows\System32\Config\SOFTWARE2" "!mumtarget!\Windows\System32\Config\SOFTWARE" %_Nul1%
goto :eof

:ReLCU
if exist "%lcudir%\update.mum" if exist "%lcudir%\*.manifest" goto :eof
rem echo.
rem echo 1/1: %lcupkg% [LCU]
if not exist "%lcudir%\" mkdir "%lcudir%"
%_exp% -f:* "!repo!\%lcupkg%" "%lcudir%" %_Null%
if exist "%lcudir%\*cablist.ini" (
  %_exp% -f:* "%lcudir%\*.cab" "%lcudir%" %_Null%
  del /f /q "%lcudir%\*cablist.ini" %_Nul3%
  del /f /q "%lcudir%\*.cab" %_Nul3%
)
set _sbst=0
if exist "%lcudir%\*.psf.cix.xml" (
if not exist "%lcudir%\express.psf.cix.xml" for /f %%# in ('dir /b /a:-d "%lcudir%\*.psf.cix.xml"') do rename "%lcudir%\%%#" express.psf.cix.xml %_Nul3%
subst %_sdr% "!_cabdir!" %_Nul3% && set _sbst=1
if !_sbst! equ 1 pushd %_sdr%
if not exist "%lcupkg%" (
  copy /y "!repo!\%lcupkg:~0,-4%.*" . %_Nul3%
  if not exist "%lcupkg:~0,-4%.psf" for /f %%# in ('dir /b /a:-d "!repo!\%lcupkg:~0,-12%*.psf"') do copy /y "!repo!\%%#" %lcupkg:~0,-4%.psf %_Nul3%
  )
if %psfcpp% equ 0 (
  %_Nul3% %_psc% "$f=[IO.File]::ReadAllText('!_batp!') -split ':cabpsf\:.*';iex ($f[1]);P '%lcupkg%'"
  )
if %psfcpp% equ 1 (
  copy /y "!_exe!" . %_Nul3%
  PSFExtractor.exe %lcupkg% %_Null%
  )
if !_sbst! equ 1 popd
if !_sbst! equ 1 subst %_sdr% /d %_Nul3%
)
goto :eof

:procmum
if %listc% geq %ac% (set /a AC+=100&set /a list+=1&set "ldr%list%=%ldr%"&set "ldr=")
set /a listc+=1
if exist "%dest%\*defender*.xml" (
if exist "!mumtarget!\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (set /a _sum-=1&goto :eof)
call :defender_check
goto :eof
)
if not exist "%dest%\update.mum" (
if /i "%lcupkg%"=="!package!" call :ReLCU
)
set _dcu=0
if not exist "%dest%\update.mum" (
for %%# in (%directcab%) do if /i "!package!"=="%%~#" set _dcu=1
if "!_dcu!"=="0" (set /a _sum-=1&goto :eof)
)
set xmsu=0
if /i "%packx%"==".msu" set xmsu=1
:: for /f "tokens=2 delims=-" %%V in ('echo "!package!"') do set kb=%%V
set kb=
set tn=2
:startmumLoop
for /f "tokens=%tn% delims=-" %%A in ('echo !package!') do (
  if not errorlevel 1 (
    echo %%A|findstr /i /b KB %_Nul1% && (set kb=%%A&goto :endmumLoop)
    set /a tn+=1
    goto :startmumLoop
  ) else (
    goto :endmumLoop
  )
)
:endmumLoop
if "%kb%"=="" (set /a _sum-=1&goto :eof)
if %_build% geq 20348 if exist "%dest%\update.mum" if not exist "!mumtarget!\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
findstr /i /m "Package_for_RollupFix" "%dest%\update.mum" %_Nul3% || (findstr /i /m "Microsoft-Windows-NetFx" "%dest%\package_1_for*.mum" %_Nul3% && (
  if exist "%dest%\*_microsoft-windows-n..35wpfcomp.resources*.manifest" (set "netupdt=!netupdt! /PackagePath:%dest%\update.mum"&set /a _sum-=1&goto :eof)
  ))
)
if %_build% geq 17763 if exist "%dest%\update.mum" if not exist "!mumtarget!\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
findstr /i /m "Package_for_RollupFix" "%dest%\update.mum" %_Nul3% || (findstr /i /m "Microsoft-Windows-NetFx" "%dest%\*.mum" %_Nul3% && (
  if not exist "%dest%\*_microsoft-windows-servicingstack_*.manifest" if not exist "%dest%\*_netfx4clientcorecomp.resources*.manifest" if not exist "%dest%\*_netfx4-netfx_detectionkeys_extended*.manifest" if not exist "%dest%\*_microsoft-windows-n..35wpfcomp.resources*.manifest" (if exist "%dest%\*_*10.0.*.manifest" (set "netroll=!netroll! /PackagePath:%dest%\update.mum") else (if exist "%dest%\*_*11.0.*.manifest" set "netroll=!netroll! /PackagePath:%dest%\update.mum"))
  ))
findstr /i /m "Package_for_OasisAsset" "%dest%\update.mum" %_Nul3% && (if not exist "!mumtarget!\Windows\Servicing\packages\*OasisAssets-Package*.mum" (set /a _sum-=1&goto :eof))
findstr /i /m "WinPE" "%dest%\update.mum" %_Nul3% && (
  %_Nul3% findstr /i /m "Edition\"" "%dest%\update.mum"
  if errorlevel 1 (set /a _sum-=1&goto :eof)
  )
)
if %_build% geq 19041 if exist "%dest%\update.mum" if not exist "!mumtarget!\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
findstr /i /m "Package_for_WindowsExperienceFeaturePack" "%dest%\update.mum" %_Nul3% && (
  if not exist "!mumtarget!\Windows\Servicing\packages\Microsoft-Windows-UserExperience-Desktop*.mum" (set /a _sum-=1&goto :eof)
  set fxupd=0
  for /f "tokens=3 delims== " %%# in ('findstr /i "Edition" "%dest%\update.mum" %_Nul6%') do if exist "!mumtarget!\Windows\Servicing\packages\%%~#*.mum" set fxupd=1
  if "!fxupd!"=="0" (set /a _sum-=1&goto :eof)
  )
)
set "wnt=%_Pkt%_10"
if exist "%dest%\%sss%_microsoft-updatetargeting-*os_%_Pkt%_11.*.manifest" set "wnt=%_Pkt%_11"
if exist "%dest%\%sss%_microsoft-updatetargeting-*os_%_Pkt%_12.*.manifest" set "wnt=%_Pkt%_12"
if exist "%dest%\%sss%_microsoft-updatetargeting-*os_%wnt%.%_fixEP%*.manifest" if not defined uupmaj (
for /f "tokens=5-7 delims=_." %%I in ('dir /b /a:-d /on "%dest%\%sss%_microsoft-updatetargeting-*os_%wnt%.%_fixEP%*.manifest"') do (set uupver=%%I.%%K&set uupmaj=%%I&set uupmin=%%K)
if %_fixEP% equ 0 for /f "tokens=5-7 delims=_." %%I in ('dir /b /a:-d /on "%dest%\%sss%_microsoft-updatetargeting-*os_%wnt%.%_fixEP%*.manifest"') do (set uupver=%%J.%%K&set uupmaj=%%J&set uupmin=%%K)
for /f "tokens=8 delims== " %%# in ('findstr /i Branch "%dest%\%sss%_microsoft-updatetargeting-*os_%wnt%.%_fixEP%*.manifest"') do set uuplab=%%~#
for /f "tokens=8 delims== " %%# in ('findstr /i Branch "%dest%\%sss%_microsoft-updatetargeting-*os_%wnt%.%_fixEP%*.manifest"') do set isolab=%%~#
)
for %%# in (
Package_for_%kb%~
%mumpkgs%
) do if exist "!mumtarget!\Windows\Servicing\packages\%%#*.mum" (
set "mumcheck=!mumtarget!\Windows\Servicing\packages\%%#*.mum"
set "pkgcheck=%%#"
call :mumversion !pkgcheck:~0,14!
if !skip!==1 (set /a _sum-=1&goto :eof)
)
if exist "%dest%\*_microsoft-windows-servicingstack_*.manifest" (
if /i "!package!"=="%s_pkg%" set "servicingstack=/PackagePath:%dest%\update.mum"
if not defined s_pkg set "servicingstack=!servicingstack! /PackagePath:%dest%\update.mum"
goto :eof
)
if exist "%dest%\*_netfx4-netfx_detectionkeys_extended*.manifest" (
if exist "!mumtarget!\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (set /a _sum-=1&goto :eof)
set "netpack=!netpack! /PackagePath:%dest%\update.mum"
goto :eof
)
if exist "%dest%\*_%_EdgCmp%_*.manifest" findstr /i /m "Package_for_RollupFix" "%dest%\update.mum" %_Nul3% || (
if exist "!mumtarget!\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (set /a _sum-=1&goto :eof)
if exist "%dest%\*enablement-package*.mum" if %SkipEdge% neq 1 (
  for /f %%# in ('dir /b /a:-d "%dest%\*enablement-package~*.mum"') do set "ldr=!ldr! /PackagePath:%dest%\%%#"
  set "edge=!edge! /PackagePath:%dest%\update.mum"
  )
if exist "%dest%\*enablement-package*.mum" if %SkipEdge% equ 1 (set "fupdt=!fupdt! !package!")
if not exist "%dest%\*enablement-package*.mum" set "edge=!edge! /PackagePath:%dest%\update.mum"
goto :eof
)
if exist "%dest%\update.mum" findstr /i /m "Package_for_SafeOSDU" "%dest%\update.mum" %_Nul3% && (
if %_build% geq 26052 if not exist "!mumtarget!\Windows\Servicing\Packages\WinPE-Rejuv-Package~*.mum" (set /a _sum-=1&goto :eof)
if %_build% lss 26052 if not exist "!mumtarget!\Windows\Servicing\Packages\WinPE-Rejuv-Package~*.mum" if not exist "!mumtarget!\Windows\Servicing\Packages\WinPE-SRT-Package~*.mum" if not exist "!mumtarget!\Windows\Servicing\Packages\WinPE-Setup-Package~*.mum" (set /a _sum-=1&goto :eof)
if %verb%==1 (set /a _sum-=1&goto :eof)
set "safeos=!safeos! /PackagePath:%dest%\update.mum"
goto :eof
)
if exist "%dest%\*_microsoft-windows-sysreset_*.manifest" findstr /i /m "Package_for_RollupFix" "%dest%\update.mum" %_Nul3% || (
if not exist "!mumtarget!\Windows\Servicing\Packages\WinPE-SRT-Package~*.mum" (set /a _sum-=1&goto :eof)
if %verb%==1 (set /a _sum-=1&goto :eof)
set "safeos=!safeos! /PackagePath:%dest%\update.mum"
goto :eof
)
if exist "%dest%\*_microsoft-windows-winpe_tools_*.manifest" if not exist "%dest%\*_microsoft-windows-sysreset_*.manifest" findstr /i /m "Package_for_RollupFix" "%dest%\update.mum" %_Nul3% || (
if not exist "!mumtarget!\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (set /a _sum-=1&goto :eof)
if %verb%==1 (set /a _sum-=1&goto :eof)
set "safeos=!safeos! /PackagePath:%dest%\update.mum"
goto :eof
)
if exist "%dest%\*_microsoft-windows-winre-tools_*.manifest" if not exist "%dest%\*_microsoft-windows-sysreset_*.manifest" if not exist "%dest%\*_microsoft-windows-winpe_tools_*.manifest" findstr /i /m "Package_for_RollupFix" "%dest%\update.mum" %_Nul3% || (
if not exist "!mumtarget!\Windows\Servicing\Packages\WinPE-SRT-Package~*.mum" (set /a _sum-=1&goto :eof)
if %verb%==1 (set /a _sum-=1&goto :eof)
set "safeos=!safeos! /PackagePath:%dest%\update.mum"
goto :eof
)
if exist "%dest%\*_microsoft-windows-i..dsetup-rejuvenation_*.manifest" if not exist "%dest%\*_microsoft-windows-sysreset_*.manifest" if not exist "%dest%\*_microsoft-windows-winpe_tools_*.manifest" if not exist "%dest%\*_microsoft-windows-winre-tools_*.manifest" findstr /i /m "Package_for_RollupFix" "%dest%\update.mum" %_Nul3% || (
if not exist "!mumtarget!\Windows\Servicing\Packages\WinPE-Rejuv-Package~*.mum" (set /a _sum-=1&goto :eof)
if %verb%==1 (set /a _sum-=1&goto :eof)
set "safeos=!safeos! /PackagePath:%dest%\update.mum"
goto :eof
)
if exist "%dest%\*_microsoft-windows-s..boot-firmwareupdate_*.manifest" findstr /i /m "Package_for_RollupFix" "%dest%\update.mum" %_Nul3% || (
if exist "!mumtarget!\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (set /a _sum-=1&goto :eof)
if %winbuild% lss 9600 (set /a _sum-=1&goto :eof)
set "secureboot=!secureboot! /PackagePath:"!repo!\!package!""
goto :eof
)
if exist "%dest%\update.mum" if exist "!mumtarget!\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
findstr /i /m "WinPE" "%dest%\update.mum" %_Nul3% || (findstr /i /m "Package_for_RollupFix" "%dest%\update.mum" %_Nul3% || (set /a _sum-=1&goto :eof))
findstr /i /m "WinPE-NetFx-Package" "%dest%\update.mum" %_Nul3% && (findstr /i /m "Package_for_RollupFix" "%dest%\update.mum" %_Nul3% || (set /a _sum-=1&goto :eof))
)
if exist "%dest%\*_adobe-flash-for-windows_*.manifest" if not exist "%dest%\*enablement-package*.mum" findstr /i /m "Package_for_RollupFix" "%dest%\update.mum" %_Nul3% || (
if not exist "!mumtarget!\Windows\Servicing\packages\Adobe-Flash-For-Windows-Package*.mum" if not exist "!mumtarget!\Windows\Servicing\packages\Microsoft-Windows-Client-Desktop-Required-Package*.mum" (set /a _sum-=1&goto :eof)
if %_build% geq 16299 (
  set flash=0
  for /f "tokens=3 delims== " %%# in ('findstr /i "Edition" "%dest%\update.mum" %_Nul6%') do if exist "!mumtarget!\Windows\Servicing\packages\%%~#*.mum" set flash=1
  if "!flash!"=="0" (set /a _sum-=1&goto :eof)
  )
)
if exist "%dest%\*enablement-package*.mum" (
  set epkb=0
  for /f "tokens=3 delims== " %%# in ('findstr /i "Edition" "%dest%\update.mum" %_Nul6%') do if exist "!mumtarget!\Windows\Servicing\packages\%%~#*.mum" set epkb=1
  if exist "!mumtarget!\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" if %verb%==1 findstr /i /m "WinPE" "%dest%\update.mum" %_Nul3% && set epkb=1
  if "!epkb!"=="0" (set /a _sum-=1&goto :eof)
)
for %%# in (%directcab%) do (
if /i "!package!"=="%%~#" (
  set "cumulative=!cumulative! /PackagePath:"!repo!\!package!""
  goto :eof
  )
)
if exist "%dest%\update.mum" findstr /i /m "Package_for_RollupFix" "%dest%\update.mum" %_Nul3% && (
goto :proclcu
)
if exist "!mumtarget!\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
if %verb%==1 set "ldr=!ldr! /PackagePath:%dest%\update.mum"
goto :eof
)
if exist "%dest%\*_%_CedCmp%_*.manifest" if %SkipEdge% equ 1 if not exist "!mumtarget!\Windows\WinSxS\Manifests\%_CedCom%.manifest" (set "cupdt=!cupdt! !package!"&goto :eof)
if exist "%dest%\*_%_CedCmp%_*.manifest" if %SkipEdge% equ 2 call :deEdge
set "ldr=!ldr! /PackagePath:%dest%\update.mum"
goto :eof

:proclcu
if %_build% geq 20231 if %_build% lss 26052 if %xmsu% equ 0 (
  set "lcudir=%dest%"
  set "lcupkg=!package!"
)
if exist "!mumtarget!\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
if %xmsu% equ 1 (
  call :setlcu
  goto :eof
  )
set "cumulative=!cumulative! /PackagePath:%dest%\update.mum"
goto :eof
)
if %xmsu% equ 1 (
  call :setlcu
  goto :eof
)
set "netlcu=!netlcu! /PackagePath:%dest%\update.mum"
if exist "%dest%\*_%_CedCmp%_*.manifest" if %SkipEdge% equ 1 if not exist "!mumtarget!\Windows\WinSxS\Manifests\%_CedCom%.manifest" (set "cupdt=!cupdt! !package!"&goto :eof)
if exist "%dest%\*_%_CedCmp%_*.manifest" if %SkipEdge% equ 2 call :deEdge
set "cumulative=!cumulative! /PackagePath:%dest%\update.mum"
goto :eof

:setlcu
if exist "!_cabdir!\LCUall\*.msu" (
if defined lcuall goto :eof
for /f "tokens=* delims=" %%# in ('dir /b /a:-d "!_cabdir!\LCUall\*.msu"') do set "lcumsu=!lcumsu! "!_cabdir!\LCUall\%%#""
set lcuall=1
) else (
set "lcumsu=!lcumsu! "!repo!\!package!""
)
set "netmsu=!lcumsu!"
goto :eof

:deEdge
  mkdir "!mumtarget!\Program Files\Microsoft\Edge\Application" %_Nul3%
  mkdir "!mumtarget!\Program Files\Microsoft\EdgeUpdate" %_Nul3%
  type nul>"!mumtarget!\Program Files\Microsoft\Edge\Edge.dat" 2>&1
  type nul>"!mumtarget!\Program Files\Microsoft\Edge\Edge.LCU.dat" 2>&1
  type nul>"!mumtarget!\Program Files\Microsoft\EdgeUpdate\EdgeUpdate.dat" 2>&1
  if exist "!mumtarget!\Windows\SysWOW64\*.dll" (
    mkdir "!mumtarget!\Program Files (x86)\Microsoft\Edge\Application" %_Nul3%
    mkdir "!mumtarget!\Program Files (x86)\Microsoft\EdgeUpdate" %_Nul3%
    type nul>"!mumtarget!\Program Files (x86)\Microsoft\Edge\Edge.dat" 2>&1
    type nul>"!mumtarget!\Program Files (x86)\Microsoft\Edge\Edge.LCU.dat" 2>&1
    type nul>"!mumtarget!\Program Files (x86)\Microsoft\EdgeUpdate\EdgeUpdate.dat" 2>&1
    )
goto :eof

:mumversion
set skip=0
findstr /i /m "%kb%" "!mumcheck!" %_Nul1% || goto :eof
if %_build% geq 26052 findstr /i /m "Package_for_RollupFix" "!mumcheck!" %_Nul1% && goto :eof
if %_embd% neq 0 goto :eof
for %%# in (inver_aa inver_bl inver_mj inver_mn kbver_aa kbver_bl kbver_mj kbver_mn) do set %%#=0
for /f %%I in ('dir /b /od "!mumcheck!"') do set _pkg=%%~nI
for /f "tokens=4-7 delims=~." %%H in ('echo %_pkg%') do set "inver_aa=%%H"&set "inver_bl=%%I"&set "inver_mj=%%J"&set "inver_mn=%%K"
mkdir "!_cabdir!\check"
if exist "%dest%\update.mum" copy /y "%dest%\update.mum" "!_cabdir!\check\" %_Nul1%
if not exist "!_cabdir!\check\*.mum" (
if /i "%package:~-4%"==".msu" (
%_exp% -f:*Windows*.cab "!repo!\!package!" "!_cabdir!\check" %_Nul3%
if not exist "!_cabdir!\check\*.cab" %_exp% -f:SSU-*%arch%*.cab "!repo!\!package!" "!_cabdir!\check" %_Nul3%
) else (
copy /y "!repo!\!package!" "!_cabdir!\check" %_Nul3%
)
%_exp% -f:update.mum "!_cabdir!\check\*.cab" "!_cabdir!\check" %_Null%
)
if not exist "!_cabdir!\check\*.mum" (set skip=1&rmdir /s /q "!_cabdir!\check\"&goto :eof)
:: self note: do not add " at the end
for /f "tokens=5-8 delims==. " %%H in ('findstr /i %1 "!_cabdir!\check\update.mum"') do set "kbver_aa=%%~H"&set "kbver_bl=%%I"&set "kbver_mj=%%J"&set "kbver_mn=%%K
rmdir /s /q "!_cabdir!\check\"
if %inver_aa% gtr %kbver_aa% set skip=1
if %inver_aa% equ %kbver_aa% if %inver_bl% gtr %kbver_bl% set skip=1
if %inver_aa% equ %kbver_aa% if %inver_bl% equ %kbver_bl% if %inver_mj% gtr %kbver_mj% set skip=1
if %inver_aa% equ %kbver_aa% if %inver_bl% equ %kbver_bl% if %inver_mj% equ %kbver_mj% if %inver_mn% geq %kbver_mn% set skip=1
if %skip%==1 if %online%==1 reg.exe query "HKLM\SOFTWARE\%_CBS%\%_pkg%" /v CurrentState %_Nul2% | find /i "0x70" %_Nul1% || set skip=0
goto :eof

:defender_check
if %_skpp% equ 1 if %_skpd% equ 1 (set /a _sum-=1&goto :eof)
set "_MWD=ProgramData\Microsoft\Windows Defender"
if not exist "!mumtarget!\%_MWD%\Definition Updates\Updates\*.vdm" (set "mpamfe=%dest%"&goto :eof)
if %_skpp% equ 0 dir /b /ad "!mumtarget!\%_MWD%\Platform\*.*.*.*" %_Nul3% && (
if not exist "!_cabdir!\*defender*.xml" expand.exe -f:*defender*.xml "!repo!\!package!" "!_cabdir!" %_Null%
for /f %%i in ('dir /b /a:-d "!_cabdir!\*defender*.xml"') do for /f "tokens=3 delims=<> " %%# in ('type "!_cabdir!\%%i" ^| find /i "platform"') do (
  dir /b /ad "!mumtarget!\%_MWD%\Platform\%%#*" %_Nul3% && set _skpp=1
  )
)
set "_ver1j=0"&set "_ver1n=0"
set "_ver2j=0"&set "_ver2n=0"
set "_fil1=!mumtarget!\%_MWD%\Definition Updates\Updates\mpavdlta.vdm"
set "_fil2=!_cabdir!\mpavdlta.vdm"
set "cfil1=!_fil1:\=\\!"
set "cfil2=!_fil2:\=\\!"
if %_skpd% equ 0 if exist "!_fil1!" (
if %_cwmi% equ 1 for /f "tokens=3,4 delims==." %%a in ('wmic datafile where "name='!cfil1!'" get Version /value ^| find "="') do set "_ver1j=%%a"&set "_ver1n=%%b"
if %_cwmi% equ 0 for /f "tokens=2,3 delims=." %%a in ('%_psc% "([WMI]'CIM_DataFile.Name=''!cfil1!''').Version"') do set "_ver1j=%%a"&set "_ver1n=%%b"
expand.exe -i -f:mpavdlta.vdm "!repo!\!package!" "!_cabdir!" %_Null%
)
if exist "!_fil2!" (
if %_cwmi% equ 1 for /f "tokens=3,4 delims==." %%a in ('wmic datafile where "name='!cfil2!'" get Version /value ^| find "="') do set "_ver2j=%%a"&set "_ver2n=%%b"
if %_cwmi% equ 0 for /f "tokens=2,3 delims=." %%a in ('%_psc% "([WMI]'CIM_DataFile.Name=''!cfil2!''').Version"') do set "_ver2j=%%a"&set "_ver2n=%%b"
)
if %_ver1j% gtr %_ver2j% set _skpd=1
if %_ver1j% equ %_ver2j% if %_ver1n% geq %_ver2n% set _skpd=1
if %_skpp% equ 1 if %_skpd% equ 1 (set /a _sum-=1&goto :eof)
set "mpamfe=%dest%"
goto :eof

:defender_update
echo.
if exist "%dest%\*defender*.xml" for /f %%i in ('dir /b /a:-d "%dest%\*defender*.xml"') do (
for /f "tokens=3 delims=<> " %%# in ('type "%dest%\%%i" ^| find /i "platform"') do echo Platform  : %%#
for /f "tokens=3 delims=<> " %%# in ('type "%dest%\%%i" ^| find /i "engine"') do echo Engine    : %%#
for /f "tokens=3 delims=<> " %%# in ('type "%dest%\%%i" ^| find /i "signatures"') do echo Signatures: %%#
)
xcopy /CIRY "%mpamfe%\Definition Updates\Updates" "!mumtarget!\%_MWD%\Definition Updates\Updates\" %_Nul3%
if exist "!mumtarget!\%_MWD%\Definition Updates\Updates\MpSigStub.exe" del /f /q "!mumtarget!\%_MWD%\Definition Updates\Updates\MpSigStub.exe" %_Nul3%
xcopy /ECIRY "%mpamfe%\Platform" "!mumtarget!\%_MWD%\Platform\" %_Nul3%
for /f %%# in ('dir /b /ad "%mpamfe%\Platform\*.*.*.*"') do set "_wdplat=%%#"
if exist "!mumtarget!\%_MWD%\Platform\%_wdplat%\MpSigStub.exe" del /f /q "!mumtarget!\%_MWD%\Platform\%_wdplat%\MpSigStub.exe" %_Nul3%
if not exist "%mpamfe%\Platform\%_wdplat%\ConfigSecurityPolicy.exe" copy /y "!mumtarget!\Program Files\Windows Defender\ConfigSecurityPolicy.exe" "!mumtarget!\%_MWD%\Platform\%_wdplat%\" %_Nul3%
if not exist "%mpamfe%\Platform\%_wdplat%\MpAsDesc.dll" copy /y "!mumtarget!\Program Files\Windows Defender\MpAsDesc.dll" "!mumtarget!\%_MWD%\Platform\%_wdplat%\" %_Nul3%
if not exist "%mpamfe%\Platform\%_wdplat%\MpEvMsg.dll" copy /y "!mumtarget!\Program Files\Windows Defender\MpEvMsg.dll" "!mumtarget!\%_MWD%\Platform\%_wdplat%\" %_Nul3%
if not exist "%mpamfe%\Platform\%_wdplat%\ProtectionManagement.dll" copy /y "!mumtarget!\Program Files\Windows Defender\ProtectionManagement.dll" "!mumtarget!\%_MWD%\Platform\%_wdplat%\" %_Nul3%
if not exist "%mpamfe%\Platform\%_wdplat%\MpUxAgent.dll" copy /y "!mumtarget!\Program Files\Windows Defender\MpUxAgent.dll" "!mumtarget!\%_MWD%\Platform\%_wdplat%\" %_Nul3%
for /f %%A in ('dir /b /ad "!mumtarget!\Program Files\Windows Defender\*-*"') do (
if not exist "!mumtarget!\%_MWD%\Platform\%_wdplat%\%%A\" mkdir "!mumtarget!\%_MWD%\Platform\%_wdplat%\%%A" %_Nul3%
if not exist "%mpamfe%\Platform\%_wdplat%\%%A\MpAsDesc.dll.mui" copy /y "!mumtarget!\Program Files\Windows Defender\%%A\MpAsDesc.dll.mui" "!mumtarget!\%_MWD%\Platform\%_wdplat%\%%A\" %_Nul3%
if not exist "%mpamfe%\Platform\%_wdplat%\%%A\MpEvMsg.dll.mui" copy /y "!mumtarget!\Program Files\Windows Defender\%%A\MpEvMsg.dll.mui" "!mumtarget!\%_MWD%\Platform\%_wdplat%\%%A\" %_Nul3%
if not exist "%mpamfe%\Platform\%_wdplat%\%%A\ProtectionManagement.dll.mui" copy /y "!mumtarget!\Program Files\Windows Defender\%%A\ProtectionManagement.dll.mui" "!mumtarget!\%_MWD%\Platform\%_wdplat%\%%A\" %_Nul3%
if not exist "%mpamfe%\Platform\%_wdplat%\%%A\MpUxAgent.dll.mui" copy /y "!mumtarget!\Program Files\Windows Defender\%%A\MpUxAgent.dll.mui" "!mumtarget!\%_MWD%\Platform\%_wdplat%\%%A\" %_Nul3%
)
if /i %arch%==x86 goto :eof
if not exist "%mpamfe%\Platform\%_wdplat%\x86\MpAsDesc.dll" copy /y "!mumtarget!\Program Files (x86)\Windows Defender\MpAsDesc.dll" "!mumtarget!\%_MWD%\Platform\%_wdplat%\x86\" %_Nul3%
for /f %%A in ('dir /b /ad "!mumtarget!\Program Files (x86)\Windows Defender\*-*"') do (
if not exist "!mumtarget!\%_MWD%\Platform\%_wdplat%\x86\%%A\" mkdir "!mumtarget!\%_MWD%\Platform\%_wdplat%\x86\%%A" %_Nul3%
if not exist "%mpamfe%\Platform\%_wdplat%\x86\%%A\MpAsDesc.dll.mui" copy /y "!mumtarget!\Program Files (x86)\Windows Defender\%%A\MpAsDesc.dll.mui" "!mumtarget!\%_MWD%\Platform\%_wdplat%\x86\%%A\" %_Nul3%
)
goto :eof

:pXML
if %_build% neq 18362 (
call :cXML stage
echo.
echo Processing 1 of 1 - Staging %dest%
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\%_DsmLog%" /Apply-Unattend:stage.xml
if !errorlevel! neq 0 if !errorlevel! neq 3010 goto :eof
)
if %_build% neq 18362 (call :Winner) else (call :Suppress)
if defined _dualSxS (
set "_SxsKey=%_CedKey%"
set "_SxsCmp=%_CedCmp%"
set "_SxsIdn=%_CedIdn%"
set "_SxsCF=256"
if %_build% neq 18362 (call :Winner) else (call :Suppress)
)
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\%_DsmLog%" /Add-Package /PackagePath:"%dest%\update.mum"
if %_build% neq 18362 (del /f /q stage.xml %_Nul3%)
goto :eof

:cXML
(
echo.^<?xml version="1.0" encoding="utf-8"?^>
echo.^<unattend xmlns="urn:schemas-microsoft-com:unattend"^>
echo.    ^<servicing^>
echo.        ^<package action="%1"^>
)>%1.xml
findstr /i Package_for_RollupFix "%dest%\update.mum" %_Nul3% && (
findstr /i Package_for_RollupFix "%dest%\update.mum" >>%1.xml
)
findstr /i Package_for_RollupFix "%dest%\update.mum" %_Nul3% || (
findstr /i Package_for_KB "%dest%\update.mum" | findstr /i /v _RTM >>%1.xml
)
(
echo.            ^<source location="%dest%\update.mum" /^>
echo.        ^</package^>
echo.     ^</servicing^>
echo.^</unattend^>
)>>%1.xml
goto :eof

:Latent
set "_InCom=!%1Com!"
set "_InKey=!%1Key!"
set "_InIdn=!%1Idn!"
if not exist "!_CabDir!\" mkdir "!_CabDir!"
if not exist "!_CabDir!\%_InCom%.manifest" (
(echo ^<?xml version="1.0" encoding="UTF-8" standalone="yes"?^>
echo ^<assembly xmlns="urn:schemas-microsoft-com:asm.v3" manifestVersion="1.0" copyright="Copyright (c) Microsoft Corporation. All Rights Reserved."^>
echo   ^<assemblyIdentity name="%_InIdn%" version="%_OurVer%" processorArchitecture="%xBT%" language="neutral" buildType="release" publicKeyToken="%_Pkt%" versionScope="nonSxS" /^>
echo ^</assembly^>)>"!_CabDir!\%_InCom%.manifest"
)
set "_InIdt="
set "_psin=%_InIdn%, Culture=neutral, Version=%_OurVer%, PublicKeyToken=%_Pkt%, ProcessorArchitecture=%xBT%, versionScope=NonSxS"
for /f "tokens=* delims=" %%# in ('%_psc% "[BitConverter]::ToString([Text.Encoding]::ASCII.GetBytes($env:_psin)) -replace '-'"') do set "_InIdt=%%#"
if not defined _InIdt exit /b
set "_InHsh="
for /f "tokens=* delims=" %%# in ('%_psc% "[BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash(([IO.StreamReader]'!_CabDir!\%_InCom%.manifest').BaseStream)) -replace '-'"') do set "_InHsh=%%#"
if not defined _InHsh exit /b
icacls "!mumtarget!\Windows\WinSxS\Manifests" /save "!_CabDir!\acl.txt"
takeown /f "!mumtarget!\Windows\WinSxS\Manifests" /A
icacls "!mumtarget!\Windows\WinSxS\Manifests" /grant:r "*S-1-5-32-544:(OI)(CI)(F)"
copy /y "!_CabDir!\%_InCom%.manifest" "!mumtarget!\Windows\WinSxS\Manifests\"
icacls "!mumtarget!\Windows\WinSxS\Manifests" /setowner *S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464
icacls "!mumtarget!\Windows\WinSxS" /restore "!_CabDir!\acl.txt"
del /f /q "!_CabDir!\acl.txt"
if %online%==0 reg.exe load HKLM\%SOFTWARE% "!mumtarget!\Windows\System32\Config\SOFTWARE"
reg.exe query HKLM\%COMPONENTS% %_Null% || reg.exe load HKLM\%COMPONENTS% "!mumtarget!\Windows\System32\Config\COMPONENTS"
reg.exe delete "%_Cmp%\%_InCom%" /f %_Null%
reg.exe add "%_Cmp%\%_InCom%" /f /v "c^!%_Fnd%" /t REG_BINARY /d ""
reg.exe add "%_Cmp%\%_InCom%" /f /v identity /t REG_BINARY /d "%_InIdt%"
reg.exe add "%_Cmp%\%_InCom%" /f /v S256H /t REG_BINARY /d "%_InHsh%"
reg.exe add "%_Cmp%\%_InCom%" /f /v CF /t REG_DWORD /d "64"
reg.exe add "%_InKey%" /f /ve /d %_OurVer:~0,5%
reg.exe add "%_InKey%\%_OurVer:~0,5%" /f /ve /d %_OurVer%
reg.exe add "%_InKey%\%_OurVer:~0,5%" /f /v %_OurVer% /t REG_BINARY /d 01
for /f "tokens=* delims=" %%# in ('reg.exe query HKLM\%COMPONENTS%\DerivedData\VersionedIndex %_Nul6% ^| findstr /i VersionedIndex') do reg.exe delete "%%#" /f
goto :EndChk

:Suppress
for /f %%# in ('dir /b /a:-d "%dest%\%xBT%_%_SxsCmp%_*.manifest"') do set "_SxsCom=%%~n#"
for /f "tokens=4 delims=_" %%# in ('echo %_SxsCom%') do set "_SxsVer=%%#"
if not exist "!mumtarget!\Windows\WinSxS\Manifests\%_SxsCom%.manifest" (
%_Nul3% icacls "!mumtarget!\Windows\WinSxS\Manifests" /save "!_cabdir!\acl.txt"
%_Nul3% takeown /f "!mumtarget!\Windows\WinSxS\Manifests" /A
%_Nul3% icacls "!mumtarget!\Windows\WinSxS\Manifests" /grant:r "*S-1-5-32-544:(OI)(CI)(F)"
%_Nul3% copy /y "%dest%\%_SxsCom%.manifest" "!mumtarget!\Windows\WinSxS\Manifests\"
%_Nul3% icacls "!mumtarget!\Windows\WinSxS\Manifests" /setowner *S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464
%_Nul3% icacls "!mumtarget!\Windows\WinSxS" /restore "!_cabdir!\acl.txt"
%_Nul3% del /f /q "!_cabdir!\acl.txt"
)
reg.exe query HKLM\%COMPONENTS% %_Null% || reg.exe load HKLM\%COMPONENTS% "!mumtarget!\Windows\System32\Config\COMPONENTS" %_Nul3%
reg.exe query "%_Cmp%\%_SxsCom%" %_Nul3% && goto :Winner
for /f "skip=1 tokens=* delims=" %%# in ('certutil -hashfile "%dest%\%_SxsCom%.manifest" SHA256^|findstr /i /v CertUtil') do set "_SxsSha=%%#"
set "_SxsSha=%_SxsSha: =%"
set "_psin=%_SxsIdn%, Culture=neutral, Version=%_SxsVer%, PublicKeyToken=%_Pkt%, ProcessorArchitecture=%xBT%, versionScope=NonSxS"
for /f "tokens=* delims=" %%# in ('%_psc% "$str = '%_psin%'; [BitConverter]::ToString([Text.Encoding]::ASCII.GetBytes($str)) -replace '-'" %_Nul6%') do set "_SxsHsh=%%#"
%_Nul3% reg.exe add "%_Cmp%\%_SxsCom%" /f /v "c^!%_Fnd%" /t REG_BINARY /d ""
%_Nul3% reg.exe add "%_Cmp%\%_SxsCom%" /f /v identity /t REG_BINARY /d "%_SxsHsh%"
%_Nul3% reg.exe add "%_Cmp%\%_SxsCom%" /f /v S256H /t REG_BINARY /d "%_SxsSha%"
%_Nul3% reg.exe add "%_Cmp%\%_SxsCom%" /f /v CF /t REG_DWORD /d "%_SxsCF%"
for /f "tokens=* delims=" %%# in ('reg.exe query HKLM\%COMPONENTS%\DerivedData\VersionedIndex %_Nul6% ^| findstr /i VersionedIndex') do reg.exe delete "%%#" /f %_Nul3%

:Winner
for /f "tokens=4 delims=_" %%# in ('dir /b /a:-d "%dest%\%xBT%_%_SxsCmp%_*.manifest"') do (
set "pv_al=%%#"
)
for /f "tokens=1-4 delims=." %%G in ('echo %pv_al%') do (
set "pv_os=%%G.%%H"
set "pv_mj=%%G"&set "pv_mn=%%H"&set "pv_bl=%%I"&set "pv_dl=%%J"
)
set kv_al=
if %online%==0 reg.exe load HKLM\%SOFTWARE% "!mumtarget!\Windows\System32\Config\SOFTWARE" %_Nul3%
if not exist "!mumtarget!\Windows\WinSxS\Manifests\%xBT%_%_SxsCmp%_*.manifest" goto :SkipChk
reg.exe query "%_SxsKey%" %_Nul3% || goto :SkipChk
reg.exe query HKLM\%COMPONENTS% %_Null% || reg.exe load HKLM\%COMPONENTS% "!mumtarget!\Windows\System32\Config\COMPONENTS" %_Nul3%
reg.exe query "%_Cmp%" /f "%xBT%_%_SxsCmp%_*" /k %_Nul2% | find /i "HKEY_LOCAL_MACHINE" %_Nul1% || goto :SkipChk
call :ChkESUver %_Nul3%
set "wv_bl=0"&set "wv_dl=0"
reg.exe query "%_SxsKey%\%pv_os%" /ve %_Nul2% | findstr \( | findstr \. %_Nul1% || goto :SkipChk
for /f "tokens=2*" %%a in ('reg.exe query "%_SxsKey%\%pv_os%" /ve ^| findstr \(') do set "wv_al=%%b"
for /f "tokens=1-4 delims=." %%G in ('echo %wv_al%') do (
set "wv_mj=%%G"&set "wv_mn=%%H"&set "wv_bl=%%I"&set "wv_dl=%%J"
)

:SkipChk
reg.exe add "%_SxsKey%\%pv_os%" /f /v %pv_al% /t REG_BINARY /d 01 %_Nul3%
set skip_pv=0
if "%kv_al%"=="" (
reg.exe add "%_SxsKey%\%pv_os%" /f /ve /d %pv_al% %_Nul3%
reg.exe add "%_SxsKey%" /f /ve /d %pv_os% %_Nul3%
goto :EndChk
)
if %pv_mj% lss %kv_mj% (
set skip_pv=1
if %pv_bl% geq %wv_bl% if %pv_dl% geq %wv_dl% reg.exe add "%_SxsKey%\%pv_os%" /f /ve /d %pv_al% %_Nul3%
)
if %pv_mj% equ %kv_mj% if %pv_mn% lss %kv_mn% (
set skip_pv=1
if %pv_bl% geq %wv_bl% if %pv_dl% geq %wv_dl% reg.exe add "%_SxsKey%\%pv_os%" /f /ve /d %pv_al% %_Nul3%
)
if %pv_mj% equ %kv_mj% if %pv_mn% equ %kv_mn% if %pv_bl% lss %kv_bl% (
set skip_pv=1
)
if %pv_mj% equ %kv_mj% if %pv_mn% equ %kv_mn% if %pv_bl% equ %kv_bl% if %pv_dl% lss %kv_dl% (
set skip_pv=1
)
if %skip_pv% equ 0 (
reg.exe add "%_SxsKey%\%pv_os%" /f /ve /d %pv_al% %_Nul3%
reg.exe add "%_SxsKey%" /f /ve /d %pv_os% %_Nul3%
)

:EndChk
if %online%==0 (
if /i %xOS%==x86 if /i not %arch%==x86 (
  reg.exe save HKLM\%SOFTWARE% "!mumtarget!\Windows\System32\Config\SOFTWARE2" /y %_Nul1%
  reg.exe query HKLM\%COMPONENTS% %_Null% && reg.exe save HKLM\%COMPONENTS% "!mumtarget!\Windows\System32\Config\COMPONENTS2" /y %_Nul1%
  )
reg.exe unload HKLM\%SOFTWARE% %_Nul3%
reg.exe unload HKLM\%COMPONENTS% %_Nul3%
if /i %xOS%==x86 if /i not %arch%==x86 (
  move /y "!mumtarget!\Windows\System32\Config\SOFTWARE2" "!mumtarget!\Windows\System32\Config\SOFTWARE" %_Nul1%
  if exist "!mumtarget!\Windows\System32\Config\COMPONENTS2" move /y "!mumtarget!\Windows\System32\Config\COMPONENTS2" "!mumtarget!\Windows\System32\Config\COMPONENTS" %_Nul1%
  )
)
goto :eof

:ChkESUver
set kv_os=
reg.exe query "%_SxsKey%" /ve | findstr \( | findstr \. || goto :eof
for /f "tokens=2*" %%a in ('reg.exe query "%_SxsKey%" /ve ^| findstr \(') do set "kv_os=%%b"
if "%kv_os%"=="" goto :eof
set kv_al=
reg.exe query "%_SxsKey%\%kv_os%" /ve | findstr \( | findstr \. || goto :eof
for /f "tokens=2*" %%a in ('reg.exe query "%_SxsKey%\%kv_os%" /ve ^| findstr \(') do set "kv_al=%%b"
if "%kv_al%"=="" goto :eof
reg.exe query "%_Cmp%" /f "%xBT%_%_SxsCmp%_%_Pkt%_%kv_al%_*" /k %_Nul2% | find /i "%kv_al%" %_Nul1% || (
set kv_al=
goto :eof
)
for /f "tokens=1-4 delims=." %%G in ('echo %kv_al%') do (
set "kv_mj=%%G"&set "kv_mn=%%H"&set "kv_bl=%%I"&set "kv_dl=%%J"
)
goto :eof

:enablenet35
if exist "!mumtarget!\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" goto :eof
if exist "!mumtarget!\Windows\Microsoft.NET\Framework\v2.0.50727\ngen.exe" (echo.&echo .NET 3.5 feature: already enabled&goto :eof)
if not defined net35source call :sourcenet35
if not defined net35source (echo.&echo .NET 3.5 feature: source folder not defined or detected&goto :eof)
if not exist "!net35source!\*netfx3*.cab" (echo.&echo .NET 3.5 feature: source cab file not found or detected&goto :eof)
echo.
echo ============================================================
echo Adding .NET Framework 3.5 feature...
echo ============================================================
cd /d "!net35source!"
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNetFx3.log" /Enable-Feature /FeatureName:NetFx3 /All /LimitAccess /Source:.
if %errorlevel% neq 0 if %errorlevel% neq 3010 (
cd /d "!_cabdir!"
set _DNF=1
call :cleanup
goto :eof
)
cd /d "!_cabdir!"
set _DNF=1
if defined netupdt (
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNetFx3.log" /Add-Package %netupdt%
)
if not defined netroll if not defined netlcu if not defined netmsu if not defined cumulative (
call :cleanup
goto :eof
)
if not defined netupdt if %_build% geq 20231 dir /b /ad "!mumtarget!\Windows\Servicing\LCU\Package_for_RollupFix*" %_Nul3% && (
call :cleanup
goto :eof
)
echo.
echo ============================================================
echo Reinstalling cumulative update^(s^)...
echo ============================================================
set netxtr=
if defined netroll set "netxtr=%netroll%"
if defined netlcu set "netxtr=%netxtr% %netlcu%"
if defined netmsu if defined netxtr (
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNetFx3.log" /Add-Package %netxtr%
)
if defined netmsu for %%# in (%netmsu%) do (
echo.&echo %%~nx#
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNetFx3.log" /Add-Package /PackagePath:%%#
)
if not defined netmsu if defined netlcu (
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNetFx3.log" /Add-Package %netroll% %netlcu%
)
if not defined netmsu if not defined netlcu (
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNetFx3.log" /Add-Package %netroll% %cumulative%
)
if defined lcupkg call :ReLCU
call :cleanup
goto :eof

:sourcenet35
for %%# in (D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do if not defined net35source (if exist "%%#:\sources\sxs\*netfx3*.cab" set "net35source=%%#:\sources\sxs")
if %dvd%==1 if exist "!target!\sources\sxs\*netfx3*.cab" set "net35source=!target!\sources\sxs"
if %wim%==1 if not defined net35source for %%# in ("!target!") do (
  set "_wimpath=%%~dp#"
  if exist "!_wimpath!\sxs\*netfx3*.cab" set "net35source=!_wimpath!\sxs"
)
if not defined net35source if exist "!_work!\sxs\*netfx3*.cab" set "net35source=!_work!\sxs"
if not defined net35source if exist "!repo!\sxs\*netfx3*.cab" set "net35source=!repo!\sxs"
goto :eof

:detector
set _msu=0
set _cab=0
set _sum=0
cd /d "!repo!"
if not defined tmpssu if exist "SSU-*-%arch%*.msu" for /f "tokens=* delims=" %%# in ('dir /b /on "SSU-*-%arch%*.msu"') do (set "ssupkg=%%#"&call :tmprenssu)
if not defined tmpssu if exist "SSU-*-%arch%*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "SSU-*-%arch%*.cab"') do (set "ssupkg=%%#"&call :tmprenssu)
if exist "*Windows1*-KB*%arch%*.msu" for /f "tokens=* delims=" %%# in ('dir /b /on "*Windows1*-KB*%arch%*.msu"') do call set /a _msu+=1
if exist "*Windows1*-KB*%arch%*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "*Windows1*-KB*%arch%*.cab"') do call set /a _cab+=1
if %online%==0 if exist "*defender-dism*%_bit%*.cab" for /f "tokens=* delims=" %%# in ('dir /b "*defender-dism*%_bit%*.cab"') do call set /a _cab+=1
cd /d "!_work!"
set /a _sum=%_msu%+%_cab%
goto :eof

:counter
set _msu=0
set _cab=0
set _sum=0
cd /d "!repo!"
if exist "SSU-*-%arch%*.msu" for /f "tokens=* delims=" %%# in ('dir /b /on "SSU-*-%arch%*.msu"') do (set "ssupkg=%%#"&call :tmprenssu)
if exist "SSU-*-%arch%*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "SSU-*-%arch%*.cab"') do (set "ssupkg=%%#"&call :tmprenssu)
if exist "*Windows1*-KB*%arch%*.msu" (
for /f "tokens=* delims=" %%# in ('dir /b /on "*Windows1*-KB*%arch%*.msu"') do (
  call set /a _msu+=1
  set "_name=%%#"
  if not "!_name!"=="!_name: =!" ren "!_name!" "!_name: =!"
  if /i "!_name:~0,18!"=="AMD64_X86_ARM-all-" ren "!_name!" "!_name:~18!"
  if /i "!_name:~0,14!"=="AMD64_X86-all-" ren "!_name!" "!_name:~14!"
  if /i "!_name:~0,10!"=="AMD64-all-" ren "!_name!" "!_name:~10!"
  if /i "!_name:~0,10!"=="ARM64-all-" ren "!_name!" "!_name:~10!"
  if /i "!_name:~0,8!"=="X86-all-" ren "!_name!" "!_name:~8!"
  )
)
if exist "*Windows1*-KB*%arch%*.cab" (
for /f "tokens=* delims=" %%# in ('dir /b /on "*Windows1*-KB*%arch%*.cab"') do (
  call set /a _cab+=1
  set "_name=%%#"
  if not "!_name!"=="!_name: =!" ren "!_name!" "!_name: =!"
  if /i "!_name:~0,18!"=="AMD64_X86_ARM-all-" ren "!_name!" "!_name:~18!"
  if /i "!_name:~0,14!"=="AMD64_X86-all-" ren "!_name!" "!_name:~14!"
  if /i "!_name:~0,10!"=="AMD64-all-" ren "!_name!" "!_name:~10!"
  if /i "!_name:~0,10!"=="ARM64-all-" ren "!_name!" "!_name:~10!"
  if /i "!_name:~0,8!"=="X86-all-" ren "!_name!" "!_name:~8!"
  )
)
if %online%==0 if exist "*defender-dism*%_bit%*.cab" (
for /f "tokens=* delims=" %%# in ('dir /b "*defender-dism*%_bit%*.cab"') do (
  call set /a _cab+=1
  set "_name=%%#"
  if not "!_name!"=="!_name: =!" ren "!_name!" "!_name: =!"
  )
)
cd /d "!_work!"
set /a _sum=%_msu%+%_cab%
goto :eof

:tmprenssu
set kbssu=
mkdir "!_cabdir!\check"
if /i "%ssupkg:~-4%"==".msu" (%_exp% -f:*.txt "%ssupkg%" "!_cabdir!\check" %_Null%) else (%_exp% -f:update.mum "%ssupkg%" "!_cabdir!\check" %_Null%)
if not exist "!_cabdir!\check\*.txt" if not exist "!_cabdir!\check\*.mum" (rmdir /s /q "!_cabdir!\check\"&goto :eof)
if exist "!_cabdir!\check\*.txt" (
for /f "tokens=2 delims==" %%# in ('findstr /i /c:"KB Article" "!_cabdir!\check\*.txt"') do set kbssu=KB%%~#
)
if exist "!_cabdir!\check\update.mum" (
for /f "tokens=3 delims== " %%# in ('findstr /i releaseType "!_cabdir!\check\update.mum"') do set kbssu=%%~#
)
if "%kbssu%"=="" (rmdir /s /q "!_cabdir!\check\"&goto :eof)
set _sfn=Windows10.0-%kbssu%-%arch%.cab
if %_build% geq 22563 set _sfn=Windows11.0-%kbssu%-%arch%.cab
if exist "!repo!\*Windows11.0-KB*.cab" set _sfn=Windows11.0-%kbssu%-%arch%.cab
if exist "!repo!\*Windows12.0-KB*.cab" set _sfn=Windows12.0-%kbssu%-%arch%.cab
if /i "%ssupkg:~-4%"==".msu" (
%_exp% -f:*%arch%*.cab "%ssupkg%" "!_cabdir!\check" %_Null%
for /f %%# in ('dir /b "!_cabdir!\check\*.cab"') do copy /y "!_cabdir!\check\%%#" %_sfn% %_Nul3%
) else (
copy /y %ssupkg% %_sfn% %_Nul3%
)
set "tmpssu=!tmpssu! %_sfn%"
rmdir /s /q "!_cabdir!\check\"
goto :eof

:cleaner
cd /d "!_work!"
if defined msucab (
  for %%# in (%msucab%) do del /f /q "!repo!\%%~#" %_Nul3%
  set msucab=
)
if defined tmpcmp (
  for %%# in (%tmpcmp%) do del /f /q "!repo!\%%~#" %_Nul3%
  set tmpcmp=
)
if defined uuppkg (
  for %%# in (%uuppkg%) do del /f /q "!repo!\%%~#" %_Nul3%
  set uuppkg=
)
if %_keep% neq 0 goto :eof
if exist "cabmsu.txt" (
  for /f %%# in (cabmsu.txt) do del /f /q "!repo!\%%~#" %_Nul3%
  del /f /q cabmsu.txt
)
if exist "!_cabdir!\cmpcab.txt" (
  cd /d "!_cabdir!"
  for /f %%# in (cmpcab.txt) do del /f /q "!repo!\%%~#" %_Nul3%
  del /f /q cmpcab.txt
  cd /d "!_work!"
)
if %_embd% neq 0 goto :eof
if exist "!_cabdir!\" (
echo.
echo ============================================================
echo Removing temporary extracted files...
echo ============================================================
echo.
rmdir /s /q "!_cabdir!\" %_Nul1%
)
if exist "!_cabdir!\" (
mkdir %_drv%\_del286 %_Null%
robocopy %_drv%\_del286 "!_cabdir!" /MIR %_Null%
rmdir /s /q %_drv%\_del286\ %_Null%
rmdir /s /q "!_cabdir!\" %_Nul3%
)
goto :eof

:mount
set "_wimfile=%~1"
if %wim%==1 set "_wimpath=!targetpath!"
if %dvd%==1 set "_wimpath=!target!"
if exist "!mountdir!\" rmdir /s /q "!mountdir!\" %_Nul1%
if not exist "!mountdir!\" mkdir "!mountdir!"
for %%# in (%indices%) do (
echo.
echo ============================================================
echo Mounting %_wimfile% - index %%#/%imgcount%
echo ============================================================
cd /d "!_wimpath!"
%_dism2%:"!_cabdir!" /Mount-Wim /Wimfile:%_wimfile% /Index:%%# /MountDir:"!mountdir!"
if !errorlevel! neq 0 goto :E_MOUNT
cd /d "!_cabdir!"
call :doupdate
if %net35%==1 call :enablenet35
if %dvd%==1 (
if not defined isolab if not exist "!mountdir!\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
if %_build% geq 15063 (call :detectLab isolab) else (call :legacyLab isolab)
if %UpdtBootFiles% equ 1 (
  if exist "!mountdir!\Windows\Boot\EFI\winsipolicy.p7b" if exist "!target!\efi\microsoft\boot\winsipolicy.p7b" copy /y "!mountdir!\Windows\Boot\EFI\winsipolicy.p7b" "!target!\efi\microsoft\boot\" %_Nul3%
  if exist "!mountdir!\Windows\Boot\EFI\CIPolicies\" if exist "!target!\efi\microsoft\boot\cipolicies\" xcopy /CERY "!mountdir!\Windows\Boot\EFI\CIPolicies" "!target!\efi\microsoft\boot\cipolicies\" %_Nul3%
  )
)
if not defined isomaj (
for /f "tokens=6,7 delims=_." %%i in ('dir /b /a:-d /od "!mountdir!\Windows\WinSxS\Manifests\%sss%_microsoft-windows-coreos-revision*.manifest"') do (set isover=%%i.%%j&set isomaj=%%i&set isomin=%%j)
if %_build% geq 15063 (call :detectRev)
)
if %_actEP% equ 0 if exist "!mountdir!\Windows\Servicing\Packages\microsoft-windows-*enablement-package~*.mum" if not exist "!mountdir!\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" call :detectEP
if exist "!mountdir!\Windows\Servicing\Packages\Microsoft-Windows-Server*Edition~*.mum" set _SrvEdt=1
if exist "!mountdir!\sources\setup.exe" call :boots
if exist "!mountdir!\Windows\system32\UpdateAgent.dll" if not exist "%SystemRoot%\temp\UpdateAgent.dll" copy /y "!mountdir!\Windows\system32\UpdateAgent.dll" %SystemRoot%\temp\ %_Nul3%
if exist "!mountdir!\Windows\system32\Facilitator.dll" if not exist "%SystemRoot%\temp\Facilitator.dll" copy /y "!mountdir!\Windows\system32\Facilitator.dll" %SystemRoot%\temp\ %_Nul3%
)
if %wim%==1 if exist "!_wimpath!\setup.exe" (
if exist "!mountdir!\sources\setup.exe" copy /y "!mountdir!\sources\setup.exe" "!_wimpath!" %_Nul3%
if %_build% geq 26052 if exist "!mountdir!\sources\setuphost.exe" copy /y "!mountdir!\sources\setuphost.exe" "!_wimpath!" %_Nul3%
if defined isoupdate if not exist "!mountdir!\sources\setup.exe" if not exist "!_cabdir!\du\" (
  echo.
  echo ============================================================
  echo Adding setup dynamic update^(s^)...
  echo ============================================================
  echo.
  mkdir "!_cabdir!\du" %_Nul3%
  for %%i in (!isoupdate!) do (
  echo %%~i
  expand.exe -r -f:* "!repo!\%%~i" "!_cabdir!\du" %_Nul1%
  )
  xcopy /CRUY "!_cabdir!\du" "!target!\sources\" %_Nul3%
  if exist "!_cabdir!\du\*.ini" xcopy /CRY "!_cabdir!\du\*.ini" "!target!\sources\" %_Nul3%
  for /f %%# in ('dir /b /ad "!_cabdir!\du\*-*" %_Nul6%') do if exist "!target!\sources\%%#\*.mui" copy /y "!_cabdir!\du\%%#\*" "!target!\sources\%%#\" %_Nul3%
  if exist "!_cabdir!\du\replacementmanifests\" xcopy /CERY "!_cabdir!\du\replacementmanifests" "!target!\sources\replacementmanifests\" %_Nul3%
  )
)
if exist "!mountdir!\Windows\System32\Recovery\winre.wim" (
attrib -S -H -I "!mountdir!\Windows\System32\Recovery\winre.wim" %_Nul3%
if %winre%==1 if not exist "!_work!\winre.wim" call :winre
)
if exist "!mountdir!\Windows\System32\Recovery\winre.wim" if exist "!_work!\winre.wim" (
echo.
echo ============================================================
echo Adding updated winre.wim ...
echo ============================================================
echo.
copy /y "!_work!\winre.wim" "!mountdir!\Windows\System32\Recovery\"
)
if %AddDrivers%==1 call :doDrv
echo.
echo ============================================================
echo Unmounting %_wimfile% - index %%#/%imgcount%
echo ============================================================
if !discard!==1 (
%_dism2%:"!_cabdir!" /Unmount-Wim /MountDir:"!mountdir!" /Discard
) else (
%_dism2%:"!_cabdir!" /Unmount-Wim /MountDir:"!mountdir!" /Commit
)
if !errorlevel! neq 0 goto :E_MOUNT
)
if %keep%==0 if %wim2esd%==1 if %dvd%==1 if /i "%_wimfile%"=="sources\install.wim" goto :eof
echo.
echo ============================================================
echo Rebuilding %_wimfile% ...
echo ============================================================
cd /d "!_wimpath!"
if %keep%==1 for %%# in (%indices%) do (
if %_wlib% equ 1 (
    echo.
    !_wimlib! export %_wimfile% %%# temp.wim --compress=LZX
    call set errcode=!errorlevel!
  ) else (
    %_dism2%:"!_cabdir!" /Export-Image /SourceImageFile:%_wimfile% /SourceIndex:%%# /DestinationImageFile:temp.wim
    call set errcode=!errorlevel!
  )
)
if %keep%==0 (
if %_wlib% equ 1 (
    echo.
    !_wimlib! optimize %_wimfile%
    call set errcode=!errorlevel!
  ) else (
    if %_all% equ 0 for /L %%# in (1,1,%imgcount%) do %_dism2%:"!_cabdir!" /Export-Image /SourceImageFile:%_wimfile% /SourceIndex:%%# /DestinationImageFile:temp.wim
    if %_all% equ 1 %_dism2%:"!_cabdir!" /Export-Image /SourceImageFile:%_wimfile% /All /DestinationImageFile:temp.wim
    call set errcode=!errorlevel!
  )
)
if %errcode% equ 0 (if exist "temp.wim" move /y temp.wim %_wimfile% %_Nul1%) else (del /f /q temp.wim %_Nul3%)
cd /d "!_cabdir!"
goto :eof

:detectEP
set uupmaj=
set _actEP=1
if %_fixEP% equ 0 (
call :EKB1 "!mountdir!\Windows\Servicing\Packages" _actEP 1
call :EKB2 "!mountdir!\Windows\Servicing\Packages"
)
set "wnt=%_Pkt%_10"
if exist "!mountdir!\Windows\WinSxS\Manifests\%sss%_microsoft-updatetargeting-*os_%_Pkt%_11.*.manifest" set "wnt=%_Pkt%_11"
if exist "!mountdir!\Windows\WinSxS\Manifests\%sss%_microsoft-updatetargeting-*os_%_Pkt%_12.*.manifest" set "wnt=%_Pkt%_12"
if exist "!mountdir!\Windows\WinSxS\Manifests\%sss%_microsoft-updatetargeting-*os_%wnt%.%_fixEP%*.manifest" (
for /f "tokens=5-7 delims=_." %%I in ('dir /b /a:-d /od "!mountdir!\Windows\WinSxS\Manifests\%sss%_microsoft-updatetargeting-*os_%wnt%.%_fixEP%*.manifest"') do (set uupver=%%I.%%K&set uupmaj=%%I&set uupmin=%%K)
if %_fixEP% equ 0 for /f "tokens=5-7 delims=_." %%I in ('dir /b /a:-d /od "!mountdir!\Windows\WinSxS\Manifests\%sss%_microsoft-updatetargeting-*os_%wnt%.%_fixEP%*.manifest"') do (set uupver=%%J.%%K&set uupmaj=%%J&set uupmin=%%K)
)
if not defined uupmaj goto :eof
if not defined uuplab (if defined isolab (set "uuplab=%isolab%") else (call :detectLab uuplab))
call :fixLab %uupmaj% %uuplab% uuplab
goto :eof

:EKB1
if not exist "%~1\microsoft-windows-*enablement-package~*.mum" goto :eof
set "%2=%3"
if exist "%~1\Microsoft-Windows-1909Enablement-Package~*.mum" set "_fixEP=18363"
if exist "%~1\Microsoft-Windows-20H2Enablement-Package~*.mum" set "_fixEP=19042"
if exist "%~1\Microsoft-Windows-21H1Enablement-Package~*.mum" set "_fixEP=19043"
if exist "%~1\Microsoft-Windows-21H2Enablement-Package~*.mum" set "_fixEP=19044"
if exist "%~1\Microsoft-Windows-22H2Enablement-Package~*.mum" set "_fixEP=19045"
if exist "%~1\Microsoft-Windows-ASOSFe22H2Enablement-Package~*.mum" set "_fixEP=20349"
if exist "%~1\Microsoft-Windows-SV*Enablement-Package~*.mum" set "_fixEP=%_fixSV%"
if exist "%~1\Microsoft-Windows-SV2Moment*Enablement-Package~*.mum" for /f "tokens=3 delims=-" %%a in ('dir /b /a:-d /od "%~1\Microsoft-Windows-SV2Moment*Enablement-Package~*.mum"') do (
  for /f "tokens=3 delims=eEtT" %%i in ('echo %%a') do (
    set /a _fixSV=%_build%+%%i
    set /a _fixEP=%_build%+%%i
  )
)
goto :eof

:EKB2
if not exist "%~1\microsoft-windows-*enablement-package~*.mum" goto :eof
if exist "%~1\Microsoft-Windows-SV2Moment4Enablement-Package~*.mum" set "_fixSV=22631"&set "_fixEP=22631"
if exist "%~1\Microsoft-Windows-23H2Enablement-Package~*.mum" set "_fixSV=22631"&set "_fixEP=22631"
if exist "%~1\Microsoft-Windows-SV2BetaEnablement-Package~*.mum" set "_fixSV=22635"&set "_fixEP=22635"
if exist "%~1\Microsoft-Windows-Ge-Client-Server-Beta-Version-Enablement-Package~*.mum" set "_fixSV=26120"&set "_fixEP=26120"
goto :eof

:fixLab
set "_tl=%2"
if %1==18363 if /i "%_tl:~0,4%"=="19h1" set _tl=19h2%_tl:~4%
if %1==19042 if /i "%_tl:~0,2%"=="vb" set _tl=20h2%_tl:~2%
if %1==19043 if /i "%_tl:~0,2%"=="vb" set _tl=21h1%_tl:~2%
if %1==19044 if /i "%_tl:~0,2%"=="vb" set _tl=21h2%_tl:~2%
if %1==19045 if /i "%_tl:~0,2%"=="vb" set _tl=22h2%_tl:~2%
if %1==20349 if /i "%_tl:~0,2%"=="fe" set _tl=22h2%_tl:~2%
if %1==22631 if /i "%_tl:~0,2%"=="ni" (echo %_tl% | find /i "beta" %_Nul1% || set _tl=23h2_ni%_tl:~2%)
set "%3=%_tl%"
goto :eof

:detectRev
set _fixEP=0
set /a _fixSV=%_build%+1
set "_tikey=HKLM\uiSOFTWARE\Microsoft\Windows NT\CurrentVersion\Update\TargetingInfo\Installed"
reg.exe load HKLM\uiSOFTWARE "!mountdir!\Windows\system32\config\SOFTWARE" %_Nul1%
for /f "tokens=* delims=" %%# in ('reg.exe query "%_tikey%" ^| findstr /i /r ".*\.OS"') do set "_oskey=%%#"
for /f "skip=2 tokens=5,6 delims=. " %%A in ('reg.exe query "%_oskey%" /v Version') do if %%A gtr !isomaj! (
  set isover=%%A.%%B
  set isomaj=%%A
  set isomin=%%B
  set "_fixSV=!isomaj!"&set "_fixEP=!isomaj!"
  for /f "skip=2 tokens=2*" %%I in ('reg.exe query "%_oskey%" /v Branch') do set "isolab=%%J"
  call :fixLab !isomaj! !isolab! isolab
)
reg.exe save HKLM\uiSOFTWARE "!mountdir!\Windows\System32\Config\SOFTWARE2" /y %_Nul1%
reg.exe unload HKLM\uiSOFTWARE %_Nul1%
move /y "!mountdir!\Windows\System32\Config\SOFTWARE2" "!mountdir!\Windows\System32\Config\SOFTWARE" %_Nul1%
goto :eof

:detectLab
set "_tikey=HKLM\uiSOFTWARE\Microsoft\Windows NT\CurrentVersion\Update\TargetingInfo\Installed"
reg.exe load HKLM\uiSOFTWARE "!mountdir!\Windows\system32\config\SOFTWARE" %_Nul1%
for /f "tokens=* delims=" %%# in ('reg.exe query "%_tikey%" ^| findstr /i /r ".*\.OS"') do set "_oskey=%%#"
for /f "skip=2 tokens=2*" %%A in ('reg.exe query "%_oskey%" /v Branch') do set "%1=%%B"
reg.exe save HKLM\uiSOFTWARE "!mountdir!\Windows\System32\Config\SOFTWARE2" /y %_Nul1%
reg.exe unload HKLM\uiSOFTWARE %_Nul1%
move /y "!mountdir!\Windows\System32\Config\SOFTWARE2" "!mountdir!\Windows\System32\Config\SOFTWARE" %_Nul1%
goto :eof

:legacyLab
for /f "tokens=5 delims=.( " %%# in ('%_psc% "(gi '!mountdir!\Windows\system32\ntoskrnl.exe').VersionInfo.FileVersion" %_Nul6%') do set "%1=%%#"
:: reg.exe load HKLM\uiSOFTWARE "!mountdir!\Windows\system32\config\SOFTWARE" %_Nul1%
:: for /f "skip=2 tokens=6 delims=. " %%# in ('"reg.exe query "HKLM\uiSOFTWARE\Microsoft\Windows NT\CurrentVersion" /v BuildLabEx" %_Nul6%') do set "%1=%%#"
:: reg.exe save HKLM\uiSOFTWARE "!mountdir!\Windows\System32\Config\SOFTWARE2" /y %_Nul1%
:: reg.exe unload HKLM\uiSOFTWARE %_Nul1%
:: move /y "!mountdir!\Windows\System32\Config\SOFTWARE2" "!mountdir!\Windows\System32\Config\SOFTWARE" %_Nul1%
goto :eof

:boots
if exist "!mountdir!\Windows\Servicing\Packages\WinPE-Setup-Package~*.mum" xcopy /CRUY "!mountdir!\sources" "!target!\sources\" %_Nul3%
del /f /q "!target!\sources\background.bmp" %_Nul3%
del /f /q "!target!\sources\xmllite.dll" %_Nul3%
if %UpdtBootFiles% equ 1 (
for %%i in (efisys.bin,efisys_noprompt.bin) do if exist "!mountdir!\Windows\Boot\DVD\EFI\en-US\%%i" (copy /y "!mountdir!\Windows\Boot\DVD\EFI\en-US\%%i" "!target!\efi\microsoft\boot\" %_Nul1%)
if /i not %arch%==arm64 (
  copy /y "!mountdir!\Windows\Boot\PCAT\bootmgr" "!target!\" %_Nul1%
  copy /y "!mountdir!\Windows\Boot\EFI\memtest.efi" "!target!\efi\microsoft\boot\" %_Nul1%
  copy /y "!mountdir!\Windows\Boot\PCAT\memtest.exe" "!target!\boot\" %_Nul1%
  )
)
if exist "!target!\efi\boot\bootmgfw.efi" copy /y "!mountdir!\Windows\Boot\EFI\bootmgfw.efi" "!target!\efi\boot\bootmgfw.efi" %_Nul1%
copy /y "!mountdir!\Windows\Boot\EFI\bootmgfw.efi" "!target!\efi\boot\%efifile%" %_Nul1%
copy /y "!mountdir!\Windows\Boot\EFI\bootmgr.efi" "!target!\" %_Nul1%
if exist "!target!\setup.exe" copy /y "!mountdir!\setup.exe" "!target!\" %_Nul3%
if defined isoupdate if not exist "!mountdir!\Windows\Servicing\Packages\WinPE-Setup-Package~*.mum" (
  set uupboot=1
  mkdir "!_cabdir!\du" %_Nul3%
  for %%i in (!isoupdate!) do expand.exe -r -f:* "!repo!\%%~i" "!_cabdir!\du" %_Nul1%
  robocopy "!_cabdir!\du" "!mountdir!\sources" /XL /XX /XO %_Nul3%
  if exist "!_cabdir!\du\*.ini" xcopy /CRY "!_cabdir!\du\*.ini" "!mountdir!\sources\" %_Nul3%
  xcopy /CRUY "!mountdir!\sources" "!target!\sources\" %_Nul3%
  if exist "!_cabdir!\du\*.ini" xcopy /CRY "!_cabdir!\du\*.ini" "!target!\sources\" %_Nul3%
  rmdir /s /q "!_cabdir!\du\" %_Nul3%
)
if not defined uupmaj goto :eof
if %_actEP% equ 0 goto :eof
if %isomaj% gtr %uupmaj% goto :eof
set isover=%uupver%
set isolab=%uuplab%
goto :eof

:winre
  echo.
  echo ============================================================
  echo Updating winre.wim ...
  echo ============================================================
  if exist "!winremount!\" rmdir /s /q "!winremount!\" %_Nul1%
  if not exist "!winremount!\" mkdir "!winremount!"
  copy /y "!mountdir!\Windows\System32\Recovery\winre.wim" "!_work!\winre.wim" %_Nul1%
  cd /d "!_work!"
  %_dism2%:"!_cabdir!" /Mount-Wim /Wimfile:winre.wim /Index:1 /MountDir:"!winremount!"
  if %errorlevel% neq 0 goto :E_MOUNT
  cd /d "!_cabdir!"
  call :doupdate winre
  if %AddDrivers%==1 call :reDrv
  if !discardre!==1 (
  %_dism2%:"!_cabdir!" /Unmount-Wim /MountDir:"!winremount!" /Discard
  if !errorlevel! neq 0 goto :E_MOUNT
  ) else (
  %_dism2%:"!_cabdir!" /Unmount-Wim /MountDir:"!winremount!" /Commit
  if !errorlevel! neq 0 goto :E_MOUNT
  cd /d "!_work!"
  if %_wlib% equ 1 (
    echo.
    !_wimlib! optimize winre.wim
  ) else (
    %_dism2%:"!_cabdir!" /Export-Image /SourceImageFile:winre.wim /SourceIndex:1 /DestinationImageFile:temp.wim
  )
  if exist "temp.wim" move /y temp.wim winre.wim %_Nul1%
  cd /d "!_cabdir!"
  )
  set "mumtarget=!mumtargeb!"
  set dismtarget=/image:"!mountdir!"
goto :eof

:doDrv
if exist "!mountdir!\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
if not defined DrvSrcALL if not defined DrvSrcPE goto :eof
) else (
if not defined DrvSrcALL if not defined DrvSrcOS goto :eof
)
echo.
echo ============================================================
echo Adding drivers...
echo ============================================================
if exist "!mountdir!\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
if defined DrvSrcALL %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DrvWinPE.log" /Add-Driver /Driver:"!DrvSrcALL!" /Recurse
if defined DrvSrcPE %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DrvWinPE.log" /Add-Driver /Driver:"!DrvSrcPE!" /Recurse
) else (
if defined DrvSrcALL %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DrvOS.log" /Add-Driver /Driver:"!DrvSrcALL!" /Recurse
if defined DrvSrcOS %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DrvOS.log" /Add-Driver /Driver:"!DrvSrcOS!" /Recurse
)
if !discard!==1 (
%_dism2%:"!_cabdir!" /Commit-Wim /MountDir:"!mountdir!"
)
goto :eof

:reDrv
if not defined DrvSrcALL if not defined DrvSrcPE goto :eof
if defined DrvSrcALL %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DrvWinRE.log" /Add-Driver /Driver:"!DrvSrcALL!" /Recurse
if defined DrvSrcPE %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DrvWinRE.log" /Add-Driver /Driver:"!DrvSrcPE!" /Recurse
if !discardre!==1 (
%_dism2%:"!_cabdir!" /Commit-Wim /MountDir:"!winremount!"
)
goto :eof

:cleanup
set savc=0&set savr=1&set rbvr=0
if %_build% geq 18362 (set savc=3&set savr=3)
if %_build% geq 25380 (set rbvr=1)
if exist "!mumtarget!\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
if %verb%==1 (
echo.
echo ============================================================
echo Resetting WinPE image base...
echo ============================================================
)
call :MeltdownSpectre
if %_build% geq 16299 if /i not %arch%==arm64 (
set ksub=SOFTWIM
reg.exe load HKLM\!ksub! "!mumtarget!\Windows\System32\Config\SOFTWARE" %_Nul1%
reg.exe add HKLM\!ksub!\%_sbs% /v SupersededActions /t REG_DWORD /d %savr% /f %_Nul1%
reg.exe add HKLM\!ksub!\%_sbs% /v DisableComponentBackups /t REG_DWORD /d 1 /f %_Nul1%
reg.exe unload HKLM\!ksub! %_Nul1%
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismCleanup_pe.log" /Cleanup-Image /StartComponentCleanup
if !errorlevel! equ 1726 %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNUL.log" /Get-Packages %_Nul3%
)
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismCleanup_pe.log" /Cleanup-Image /StartComponentCleanup /ResetBase
if !errorlevel! equ 1726 %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNUL.log" /Get-Packages %_Nul3%
call :cleanmanual
goto :eof
)
if %cleanup%==0 call :cleanmanual&goto :eof
if exist "!mumtarget!\Windows\WinSxS\pending.xml" (
if %online%==1 call :onlinepending&goto :eof
call :cleanmanual&goto :eof
)
set "_Nul8="
if %_build% geq 25380 if %_build% lss 26000 (
set "_Nul8=1>nul 2>nul"
)
if %online%==0 (
set ksub=SOFTWIM
reg.exe load HKLM\!ksub! "!mumtarget!\Windows\System32\Config\SOFTWARE" %_Nul1%
) else (
set ksub=SOFTWARE
)
if %resetbase%==0 (
echo.
echo ============================================================
echo Cleaning up OS image...
echo ============================================================
if /i not %arch%==arm64 (
reg.exe add HKLM\%ksub%\%_sbs% /v DisableResetbase /t REG_DWORD /d 1 /f %_Nul1%
reg.exe add HKLM\%ksub%\%_sbs% /v SupersededActions /t REG_DWORD /d %savc% /f %_Nul1%
)
if %online%==0 (
if /i %xOS%==x86 if /i not %arch%==x86 reg.exe save HKLM\%ksub% "!mumtarget!\Windows\System32\Config\SOFTWARE2" /y %_Nul1%
reg.exe unload HKLM\!ksub! %_Nul1%
if /i %xOS%==x86 if /i not %arch%==x86 move /y "!mumtarget!\Windows\System32\Config\SOFTWARE2" "!mumtarget!\Windows\System32\Config\SOFTWARE" %_Nul1%
)
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismCleanup.log" /Cleanup-Image /StartComponentCleanup %_Nul8%
if !errorlevel! equ 1726 %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNUL.log" /Get-Packages %_Nul3%
) else (
echo.
echo ============================================================
echo Resetting OS image base...
echo ============================================================
if /i not %arch%==arm64 (
reg.exe add HKLM\%ksub%\%_sbs% /v DisableResetbase /t REG_DWORD /d %rbvr% /f %_Nul1%
reg.exe add HKLM\%ksub%\%_sbs% /v SupersededActions /t REG_DWORD /d %savr% /f %_Nul1%
)
if %online%==0 (
if /i %xOS%==x86 if /i not %arch%==x86 reg.exe save HKLM\%ksub% "!mumtarget!\Windows\System32\Config\SOFTWARE2" /y %_Nul1%
reg.exe unload HKLM\!ksub! %_Nul1%
if /i %xOS%==x86 if /i not %arch%==x86 move /y "!mumtarget!\Windows\System32\Config\SOFTWARE2" "!mumtarget!\Windows\System32\Config\SOFTWARE" %_Nul1%
)
if %online%==0 if %_build% geq 16299 %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismCleanup.log" /Cleanup-Image /StartComponentCleanup %_Nul8%
if !errorlevel! equ 1726 %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNUL.log" /Get-Packages %_Nul3%
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismCleanup.log" /Cleanup-Image /StartComponentCleanup /ResetBase
if !errorlevel! equ 1726 %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNUL.log" /Get-Packages %_Nul3%
)
call :cleanmanual
goto :eof

:cleanmanual
if %online%==1 goto :eof
if exist "!mumtarget!\Windows\WinSxS\ManifestCache\*.bin" (
takeown /f "!mumtarget!\Windows\WinSxS\ManifestCache\*.bin" /A %_Nul3%
icacls "!mumtarget!\Windows\WinSxS\ManifestCache\*.bin" /grant *S-1-5-32-544:F %_Nul3%
del /f /q "!mumtarget!\Windows\WinSxS\ManifestCache\*.bin" %_Nul3%
)
if exist "!mumtarget!\Windows\WinSxS\Temp\PendingDeletes\*" (
takeown /f "!mumtarget!\Windows\WinSxS\Temp\PendingDeletes\*" /A %_Null%
icacls "!mumtarget!\Windows\WinSxS\Temp\PendingDeletes\*" /grant *S-1-5-32-544:F %_Null%
del /f /q "!mumtarget!\Windows\WinSxS\Temp\PendingDeletes\*" %_Nul3%
)
if exist "!mumtarget!\Windows\WinSxS\Temp\TransformerRollbackData\*" (
takeown /f "!mumtarget!\Windows\WinSxS\Temp\TransformerRollbackData\*" /R /A %_Null%
icacls "!mumtarget!\Windows\WinSxS\Temp\TransformerRollbackData\*" /grant *S-1-5-32-544:F /T %_Null%
del /s /f /q "!mumtarget!\Windows\WinSxS\Temp\TransformerRollbackData\*" %_Null%
)
if exist "!mumtarget!\Windows\inf\*.log" (
del /f /q "!mumtarget!\Windows\inf\*.log" %_Nul3%
)
for /f "tokens=* delims=" %%# in ('dir /b /ad "!mumtarget!\Windows\CbsTemp\" %_Nul6%') do rmdir /s /q "!mumtarget!\Windows\CbsTemp\%%#\" %_Nul3%
del /s /f /q "!mumtarget!\Windows\CbsTemp\*" %_Nul3%
for /f "tokens=* delims=" %%# in ('dir /b /ad "!mumtarget!\Windows\Temp\" %_Nul6%') do rmdir /s /q "!mumtarget!\Windows\Temp\%%#\" %_Nul3%
del /s /f /q "!mumtarget!\Windows\Temp\*" %_Nul3%
if exist "!mumtarget!\Windows\WinSxS\pending.xml" goto :eof
for /f "tokens=* delims=" %%# in ('dir /b /ad "!mumtarget!\Windows\WinSxS\Temp\InFlight\" %_Nul6%') do (
takeown /f "!mumtarget!\Windows\WinSxS\Temp\InFlight\%%#" /A %_Null%
icacls "!mumtarget!\Windows\WinSxS\Temp\InFlight\%%#" /grant:r "*S-1-5-32-544:(OI)(CI)(F)" %_Null%
rmdir /s /q "!mumtarget!\Windows\WinSxS\Temp\InFlight\%%#\" %_Nul3%
)
if exist "!mumtarget!\Windows\WinSxS\Temp\PendingRenames\*" (
takeown /f "!mumtarget!\Windows\WinSxS\Temp\PendingRenames\*" /A %_Null%
icacls "!mumtarget!\Windows\WinSxS\Temp\PendingRenames\*" /grant *S-1-5-32-544:F %_Null%
del /f /q "!mumtarget!\Windows\WinSxS\Temp\PendingRenames\*" %_Nul3%
)
goto :eof

:onlinepending
if exist "!_dsk!\RunOnce_AfterRestart_DismCleanup.cmd" goto :eof
if %resetbase%==0 (set rValue=W10UIclean) else (set rValue=W10UIrebase)
reg.exe add %_SxS% /v !rValue! /t REG_DWORD /d 1 /f %_Nul1%
(
echo @echo off
echo reg.exe query "HKU\S-1-5-19" 1^>nul 2^>nul ^|^| ^(echo Run the script as administrator^&pause^&exit^)
echo if exist "%%SystemRoot%%\winsxs\pending.xml" ^(echo Restart the system first^&pause^&exit^)
echo set "_sbs=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\SideBySide\Configuration"
echo set _build=%_build%
echo set resetbase=%resetbase%
echo set savc=0^&set savr=1^&set rbvr=0
echo if %%_build%% geq 18362 ^(set savc=3^&set savr=3^)
echo if %%_build%% geq 25380 ^(set rbvr=1^)
echo net stop trustedinstaller 1^>nul 2^>nul
echo net stop wuauserv 1^>nul 2^>nul
echo del /f /q %%SystemRoot%%\Logs\CBS\* 2^>nul
echo reg.exe delete %%_sbs%% /v W10UIclean /f 1^>nul 2^>nul
echo reg.exe delete %%_sbs%% /v W10UIrebase /f 1^>nul 2^>nul
echo if %%resetbase%%==0 ^(
echo echo.
echo echo ============================================================
echo echo Cleaning up OS image...
echo echo ============================================================
echo reg.exe add %%_sbs%% /v DisableResetbase /t REG_DWORD /d 1 /f 1^>nul 2^>nul
echo reg.exe add %%_sbs%% /v SupersededActions /t REG_DWORD /d %%savc%% /f 1^>nul 2^>nul
echo dism.exe /Online /Cleanup-Image /StartComponentCleanup
echo ^) else ^(
echo echo.
echo echo ============================================================
echo echo Resetting OS image base...
echo echo ============================================================
echo reg.exe add %%_sbs%% /v DisableResetbase /t REG_DWORD /d %%rbvr%% /f 1^>nul 2^>nul
echo reg.exe add %%_sbs%% /v SupersededActions /t REG_DWORD /d %%savr%% /f 1^>nul 2^>nul
echo dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase
echo ^)
echo ^(goto^) 2^>nul ^&del /f /q %%0 ^&exit /b
)>"W10Cln.cmd"
move /y "W10Cln.cmd" "!_dsk!\RunOnce_AfterRestart_DismCleanup.cmd" %_Nul1%
goto :eof

:MeltdownSpectre
reg.exe load HKLM\TEMP "!mumtarget!\Windows\System32\Config\SYSTEM" %_Nul1%
reg.exe add "HKLM\TEMP\ControlSet001\Control\Session Manager\Kernel" /v DisableTsx /t REG_DWORD /d 1 /f %_Nul1%
reg.exe add "HKLM\TEMP\ControlSet001\Control\Session Manager\Memory Management" /v FeatureSettings /t REG_DWORD /d 3 /f %_Nul1%
reg.exe add "HKLM\TEMP\ControlSet001\Control\Session Manager\Memory Management" /v FeatureSettingsOverride /t REG_DWORD /d 3 /f %_Nul1%
reg.exe add "HKLM\TEMP\ControlSet001\Control\Session Manager\Memory Management" /v FeatureSettingsOverrideMask /t REG_DWORD /d 3 /f %_Nul1%
reg.exe unload HKLM\TEMP %_Nul1%
goto :eof

:get_dll
set "_f_=%1.dll"
set _ddc=DesktopDeployment.cab
set _dsp=System32
set _wow=0
set _nat=0
if /i %arch%==%xOS% set _nat=1
if /i %arch%==x64 if /i %xOS%==amd64 set _nat=1
if %_nat% equ 0 (
set _ddc=DesktopDeployment_x86.cab
set _dsp=SysWOW64
set _wow=1
)
if exist "!_cabdir!\%_f_%" goto :get_end
if %_embd% equ 0 (
echo.
echo ============================================================
echo Extracting %_f_% file...
echo ============================================================
)

if exist "!repo!\*%_ddc%" (
for /f "tokens=* delims=" %%# in ('dir /b /on "!repo!\*%_ddc%"') do expand.exe -f:%_f_% "!repo!\%%#" "!_cabdir!" %_Nul3%
if exist "!_cabdir!\%_f_%" goto :get_end
)

set msuwim=0
set "uupmsu="
if exist "!repo!\*Windows1*-KB*%arch%*.msu" for /f "tokens=* delims=" %%# in ('dir /b /on "!repo!\*Windows1*-KB*%arch%*.msu"') do (
expand.exe -d -f:*Windows*.psf "!repo!\%%#" %_Nul2% | findstr /i %arch%\.psf %_Nul3% && (set "uupmsu=%%#"&set msuwim=2)
dism.exe /English /List-Image /ImageFile:"!repo!\%%#" /Index:1 %_Nul2% | findstr /i %arch%\.psf %_Nul3% && (set "uupmsu=%%#"&set msuwim=1)
)

if defined uupmsu if not exist "!_cabdir!\%_ddc%" (
if %msuwim% equ 2 expand.exe -f:%_ddc% "!repo!\%uupmsu%" "!_cabdir!" %_Nul3%
if %msuwim% equ 1 %_psc% "$f=[IO.File]::ReadAllText('!_batp!') -split ':wimmsu\:.*';iex ($f[1]);E '!repo!\%uupmsu%' '%_ddc%' '!_cabdir!\%_ddc%'"
)
if %msuwim% equ 1 if not exist "!_cabdir!\%_ddc%" (
mkdir %_drv%\_tWIM %_Nul3%
dism.exe /English /Apply-Image /ImageFile:"!repo!\%uupmsu%" /Index:1 /ApplyDir:"%_drv%\_tWIM" /NoAcl:all %_Null%
copy /y "%_drv%\_tWIM\%_ddc%" "!_cabdir!\" %_Nul3%
rmdir /s /q %_drv%\_tWIM\ %_Nul3%
)

set _w_=install.wim
if %wim%==1 set "_w_=!target!"
if %dvd%==1 set "_w_=!target!\sources\install.wim"
if exist "!_cabdir!\%_ddc%" (
  expand.exe -f:%_f_% "!_cabdir!\%_ddc%" "!_cabdir!" %_Nul3%
) else (
  if %offline%==1 copy /y "!mountdir!\Windows\%_dsp%\%_f_%" "!_cabdir!\" %_Nul3%
  if %wimfiles%==1 %_psc% "$f=[IO.File]::ReadAllText('!_batp!') -split ':wimmsu\:.*';iex ($f[1]);E '!_w_!' 'Windows\%_dsp%\%_f_%' '!_cabdir!\%_f_%'"
)

:get_end
if exist "!_cabdir!\%_f_%" if "%_f_%"=="dpx.dll" (
  copy /y %SystemRoot%\%_dsp%\expand.exe "!_cabdir!\" %_Nul3%
  set _exp="!_cabdir!\expand.exe"
)
exit /b

:E_Target
echo.
echo ============================================================
echo ERROR: %MESSAGE%
echo ============================================================
echo.
echo Press any key to continue...
%_Pause%
set "target=%SystemDrive%"
%_Goto%

:E_MOUNT
call :cleaner
if defined tmpssu (
  for %%# in (%tmpssu%) do del /f /q "!repo!\%%~#" %_Nul3%
  set tmpssu=
)
dism.exe /Image:"!winremount!" /LogPath:"%_dLog%\DismNUL.log" /Get-Packages %_Null%
dism.exe /Image:"!mountdir!" /LogPath:"%_dLog%\DismNUL.log" /Get-Packages %_Null%
dism.exe /Unmount-Wim /MountDir:"!winremount!" /Discard %_Nul3%
dism.exe /Unmount-Wim /MountDir:"!mountdir!" /Discard
dism.exe /Cleanup-Mountpoints %_Nul3%
dism.exe /Cleanup-Wim %_Nul3%
if %wimfiles% equ 1 (if exist "!mountdir!\" if not exist "!mountdir!\Windows\" rmdir /s /q "!mountdir!\" %_Nul3%)
if exist "!winremount!\" if not exist "!winremount!\Windows\" rmdir /s /q "!winremount!\" %_Nul3%
if exist "!_cabdir!\" (
echo.
echo ============================================================
echo Removing temporary extracted files...
echo ============================================================
rmdir /s /q "!_cabdir!\" %_Nul1%
)
echo.
echo ============================================================
echo ERROR: Could not mount or unmount WIM image
echo ============================================================
if %_Debug% neq 0 goto :EndDebug
echo.
echo Press 9 or q to exit.
choice /c 9Q /n
if errorlevel 1 (exit) else (rem.)

:E_Admin
echo %_err%
echo This script require administrator privileges.
echo To do so, right click on this script and select 'Run as administrator'
goto :E_Exit

:E_PWS
echo %_err%
echo Windows PowerShell is not detected or not working correctly.
echo It is required for this script to work.
goto :E_Exit

:checkadk
set regKeyPathFound=1
set wowRegKeyPathFound=1
reg.exe query "HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 %_Nul3% || set wowRegKeyPathFound=0
reg.exe query "HKLM\Software\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 %_Nul3% || set regKeyPathFound=0
if %wowRegKeyPathFound% equ 0 (
  if %regKeyPathFound% equ 0 (
    goto :mainmenu
  ) else (
    set regKeyPath=HKLM\Software\Microsoft\Windows Kits\Installed Roots
  )
) else (
    set regKeyPath=HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots
)
for /f "skip=2 tokens=2*" %%i in ('reg.exe query "%regKeyPath%" /v KitsRoot10') do set "KitsRoot=%%j"
set "DandIRoot=%KitsRoot%Assessment and Deployment Kit\Deployment Tools"
if exist "%DandIRoot%\%xOS%\DISM\dism.exe" (
set _ADK=1
set "showdism=Windows NT 10.0 ADK"
set "Path=%DandIRoot%\%xOS%\DISM;%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
set "dsv=%DandIRoot%\%xOS%\DISM\dism.exe"
set "dsv=!dsv:\=\\!"
call :DismVer
)
if exist "%DandIRoot%\%xOS%\Oscdimg\oscdimg.exe" (
set "_oscdimg=%DandIRoot%\%xOS%\Oscdimg\oscdimg.exe"
)
goto :mainmenu

:DismVer
set "dsmver=10240"
if %_cwmi% equ 1 for /f "tokens=4 delims==." %%# in ('wmic datafile where "name='!dsv!'" get Version /value') do set "dsmver=%%#" 
if %_cwmi% equ 0 for /f "tokens=3 delims=." %%# in ('%_psc% "([WMI]'CIM_DataFile.Name=''!dsv!''').Version"') do set "dsmver=%%#"
set _all=1
if %dsmver% geq 25115 set _all=0
exit /b

:targetmenu
@cls
set _pp=
echo ============================================================
echo Enter the path for one of supported targets:
echo - Distribution ^(extracted folder, mounted iso/dvd/usb drive^)
echo - WIM file ^(not mounted^)
echo - Mounted directory, offline image drive letter
if %winbuild% geq 10240 echo - Current OS / Enter %SystemDrive%
echo.
echo or just press 'Enter' to return to options menu
echo ============================================================
echo.
set /p _pp=
if not defined _pp goto :mainmenu
set "_pp=%_pp:"=%"
if "%_pp:~-1%"=="\" set "_pp=!_pp:~0,-1!"
set "target=!_pp!"
set _init=0
if defined brep set "repo=!brep!"
goto :checktarget

:repomenu
@cls
set _pp=
echo ============================================================
echo Enter the Updates location path
echo.
echo or just press 'Enter' to return to options menu
echo ============================================================
echo.
set /p _pp=
if not defined _pp goto :mainmenu
set "_pp=%_pp:"=%"
if "%_pp:~-1%"=="\" set "_pp=!_pp:~0,-1!"
if not exist "!_pp!\*Windows1*-KB*.msu" if not exist "!_pp!\*Windows1*-KB*.cab" if not exist "!_pp!\SSU-*-*.cab" if not exist "!_pp!\SSU-*-*.msu" (echo.&echo ERROR: Specified location is not valid&pause&goto :repomenu)
set "repo=!_pp!"
goto :mainmenu

:dismmenu
@cls
set _pp=
echo.
echo If current OS is lower than Windows NT 10.0
echo you must install Windows ADK
echo or specify a manual Windows NT 10.0 dism.exe for integration
echo you can select dism.exe located in the distribution "sources" folder
echo.
echo.
echo Enter the full path for dism.exe
echo.
echo or just press 'Enter' to return to options menu
echo ============================================================
echo.
set /p _pp=
if not defined _pp goto :mainmenu
set "_pp=%_pp:"=%"
if not exist "!_pp!" (echo.&echo ERROR: DISM path not found&pause&goto :dismmenu)
set "dsv=!_pp:\=\\!"
call :DismVer
if %dsmver% lss 10240 (echo.&echo ERROR: DISM version is lower than 10.0.10240.16384&pause&goto :dismmenu)
set "dismroot=%_pp%"
set "showdism=%_pp%"
set _dism2="%_pp%" /English /NoRestart /ScratchDir
set _ADK=1
goto :mainmenu

:extractmenu
@cls
set _pp=
echo ============================================================
echo Enter the directory path for extracting updates
echo make sure the drive has enough free space ^(at least 10 GB^)
echo.
echo or just press 'Enter' to return to options menu
echo ============================================================
echo.
set /p _pp=
if not defined _pp goto :mainmenu
set "_pp=%_pp:"=%"
set "_pp=%_pp: =%"
if "%_pp:~-1%"=="\" set "_pp=!_pp:~0,-1!"
if "%_pp:~-1%"==":" set "_pp=!_pp!\"
set "_cabdir=!_pp!_%random%"
goto :mainmenu

:mountmenu
@cls
set _pp=
echo ============================================================
echo Enter the directory path for mounting install.wim
echo make sure the drive has enough free space ^(at least 10 GB^)
echo it must be on NTFS formatted partition
echo.
echo or just press 'Enter' to return to options menu
echo ============================================================
echo.
set /p _pp=
if not defined _pp goto :mainmenu
set "_pp=%_pp:"=%"
set "_pp=%_pp: =%"
if "%_pp:~-1%"=="\" set "_pp=!_pp:~0,-1!"
if "%_pp:~-1%"==":" set "_pp=!_pp!\"
set "mountdir=!_pp!_%random%"
goto :mainmenu

:indexmenu
@cls
set _pp=
echo ============================================================
for /L %%# in (1,1,%imgcount%) do (
echo. %%#. !name%%#!
)
echo.
echo ============================================================
echo Enter indexes numbers to update separated with space^(s^)
echo Enter * to select all indexes
echo examples: 1 3 4 or 5 1 or *
echo.
echo or just press 'Enter' to return to options menu
echo ============================================================
echo.
set /p _pp=
if not defined _pp goto :mainmenu
if "%_pp%"=="*" set "indices=%_pp%"&set keep=0&goto :mainmenu
for %%# in (%_pp%) do (
if %%# gtr %imgcount% (echo.&echo %%# is higher than available indexes&pause&goto :indexmenu)
if %%# equ 0 (echo.&echo 0 is not a valid index&pause&goto :indexmenu)
)
set "indices=%_pp%"
set keep=1
goto :mainmenu

:mainmenu
if %autostart% neq 0 goto :mainboard
@cls
echo ====================== W10UI %uiv% =======================
if /i "!target!"=="%SystemDrive%" (
if %winbuild% lss 10240 (echo [1] Select offline target) else (echo [1] Target ^(%arch%^): Current OS)
) else (
if /i "!target!"=="" (echo [1] Select offline target) else (echo [1] Target ^(%arch%^): "!target!")
)
echo.
if "!repo!"=="" (echo [2] Select updates location) else (echo [2] Updates: "!repo!")
echo.
if %winbuild% lss 10240 (
if %_ADK% equ 0 (echo [3] Select Windows NT 10.0 dism.exe) else (echo [3] DISM: "!showdism!")
) else (
echo [3] DISM: "!showdism!"
)
echo.
if %net35%==1 (echo [4] Enable .NET 3.5: YES) else (echo [4] Enable .NET 3.5: NO)
echo.
if %cleanup%==0 (
echo [5] Cleanup System Image: NO
) else (
if %resetbase%==0 (echo [5] Cleanup System Image: YES      [6] Reset Image Base: NO) else (echo [5] Cleanup System Image: YES      [6] Reset Image Base: YES)
)
if %wimfiles%==1 (
if /i "%targetname%"=="install.wim" (echo.&if %winre%==1 (echo [7] Update WinRE.wim: YES) else (echo [7] Update WinRE.wim: NO))
if %imgcount% gtr 1 (
echo.
if "%indices%"=="*" echo [8] %targetname% selected indexes: ALL ^(%imgcount%^)
if not "%indices%"=="*" (if %keep%==1 (echo [8] %targetname% selected indexes: %indices% / [K] Keep indexes: Selected) else (if %keep%==0 echo [8] %targetname% selected indexes: %indices% / [K] Keep indexes: ALL))
)
echo.
echo [M] Mount Directory: "!mountdir!"
)
echo.
echo [E] Extraction Directory: "!_cabdir!"
echo.
echo ============================================================
choice /c 1234567890KEM /n /m "Change a menu option, press 0 to start the process, or 9 to exit: "
if errorlevel 13 goto :mountmenu
if errorlevel 12 goto :extractmenu
if errorlevel 11 (if %keep%==1 (set keep=0) else (set keep=1))&goto :mainmenu
if errorlevel 10 goto :mainboard
if errorlevel 9 goto :eof
if errorlevel 8 goto :indexmenu
if errorlevel 7 (if %winre%==1 (set winre=0) else (set winre=1))&goto :mainmenu
if errorlevel 6 (if %resetbase%==1 (set resetbase=0) else (set resetbase=1))&goto :mainmenu
if errorlevel 5 (if %cleanup%==1 (set cleanup=0) else (set cleanup=1))&goto :mainmenu
if errorlevel 4 (if %net35%==1 (set net35=0) else (set net35=1))&goto :mainmenu
if errorlevel 3 goto :dismmenu
if errorlevel 2 goto :repomenu
if errorlevel 1 goto :targetmenu
goto :mainmenu

:ISO
set imapi=0
if not exist "!_oscdimg!" if not exist "!_work!\oscdimg.exe" if not exist "!_work!\bin\oscdimg.exe" if not exist "!_work!\cdimage.exe" if not exist "!_work!\bin\cdimage.exe" set imapi=1
if %imapi%==1 if %_pwsh% equ 0 goto :eof
if "!isodir!"=="" set "isodir=!_work!"
call :DATEISO
if %_cwmi% equ 1 for /f "tokens=2 delims==." %%# in ('wmic os get localdatetime /value') do set "_date=%%#"
if %_cwmi% equ 0 for /f "tokens=1 delims=." %%# in ('%_psc% "([WMI]'Win32_OperatingSystem=@').LocalDateTime"') do set "_date=%%#"
if not defined _date set "_date=000000-0000"
if not defined isodate set "isodate=%_date:~2,6%-%_date:~8,4%"
for %%# in (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do (
set isolab=!isolab:%%#=%%#!
)
set _label=%isover%.%isodate%.%isolab%
if %_SrvEdt% equ 1 (set _label=%_label%_SERVER) else (set _label=%_label%_CLIENT)
if /i %arch%==x86 set archl=X86
if /i %arch%==x64 set archl=X64
if /i %arch%==arm64 set archl=A64
if exist "!target!\sources\lang.ini" call :LANGISO
if defined _mui (set "isofile=%_label%_%archl%FRE_%_mui%.iso") else (set "isofile=%_label%_%archl%FRE.iso")
set /a rnd=%random%
if exist "!isodir!\%isofile%" ren "!isodir!\%isofile%" "%rnd%_%isofile%"
echo.
echo ============================================================
echo Creating updated ISO file...
echo ============================================================
echo.
echo ISO Location:
echo "!isodir!"
if exist "!_oscdimg!" (set _ff="!_oscdimg!") else if exist "!_work!\oscdimg.exe" (set _ff="!_work!\oscdimg.exe") else if exist "!_work!\bin\oscdimg.exe" (set _ff="!_work!\bin\oscdimg.exe") else if exist "!_work!\cdimage.exe" (set _ff="!_work!\cdimage.exe") else (set _ff="!_work!\bin\cdimage.exe")
cd /d "!target!"
if %imapi%==0 if /i not %arch%==arm64 (
!_ff! -bootdata:2#p0,e,b".\boot\etfsboot.com"#pEF,e,b".\efi\microsoft\boot\efisys.bin" -o -m -u2 -udfver102 -l"%isover%" . "%isofile%"
call set errcode=!errorlevel!
)
if %imapi%==0 if /i %arch%==arm64 (
!_ff! -bootdata:1#pEF,e,b".\efi\microsoft\boot\efisys.bin" -o -m -u2 -udfver102 -l"%isover%" . "%isofile%"
call set errcode=!errorlevel!
)
if %imapi%==1 if /i not %arch%==arm64 (
call :DIR2ISO . "%isofile%" 0 "%isover%"
call set errcode=!errorlevel!
)
if %imapi%==1 if /i %arch%==arm64 (
call :DIR2ISO . "%isofile%" 1 "%isover%"
call set errcode=!errorlevel!
)
if not exist "%isofile%" set errcode=1
if %errcode% equ 0 move /y "%isofile%" "!isodir!\" %_Nul3%
cd /d "!_work!"
if %errcode% equ 0 if %delete_source% equ 1 rmdir /s /q "!target!\" %_Nul1%
if %errcode% equ 0 if exist "!_work!\DVD10UI\" rmdir /s /q "!_work!\DVD10UI\" %_Nul1%
goto :eof

:LANGISO
cd /d "!target!"
for %%a in (3 2 1) do (for /f "tokens=1 delims== " %%b in ('findstr %%a "sources\lang.ini"') do echo %%b>>"isolang.txt")
if exist "isolang.txt" for /f "usebackq tokens=1" %%a in ("isolang.txt") do (
if defined _mui (set "_mui=!_mui!_%%a") else (set "_mui=%%a")
)
if defined _mui for %%# in (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do (
set _mui=!_mui:%%#=%%#!
)
del /f /q "isolang.txt" %_Nul3%
cd /d "!_work!"
goto :eof

:DATEISO
if %_pwsh% equ 0 goto :eof
copy /y "!target!\sources\setuphost.exe" %SystemRoot%\temp\ %_Nul3%
copy /y "!target!\sources\setupprep.exe" %SystemRoot%\temp\ %_Nul3%
set _svr1=0&set _svr2=0&set _svr3=0&set _svr4=0
set "_fvr1=%SystemRoot%\temp\UpdateAgent.dll"
set "_fvr2=%SystemRoot%\temp\setuphost.exe"
set "_fvr3=%SystemRoot%\temp\setupprep.exe"
set "_fvr4=%SystemRoot%\temp\Facilitator.dll"
set "cfvr1=!_fvr1:\=\\!"
set "cfvr2=!_fvr2:\=\\!"
set "cfvr3=!_fvr3:\=\\!"
set "cfvr4=!_fvr4:\=\\!"
if %_cwmi% equ 1 (
if exist "!_fvr1!" for /f "tokens=5 delims==." %%a in ('wmic datafile where "name='!cfvr1!'" get Version /value ^| find "="') do set /a "_svr1=%%a"
if exist "!_fvr2!" for /f "tokens=5 delims==." %%a in ('wmic datafile where "name='!cfvr2!'" get Version /value ^| find "="') do set /a "_svr2=%%a"
if exist "!_fvr3!" for /f "tokens=5 delims==." %%a in ('wmic datafile where "name='!cfvr3!'" get Version /value ^| find "="') do set /a "_svr3=%%a"
if exist "!_fvr4!" for /f "tokens=5 delims==." %%a in ('wmic datafile where "name='!cfvr4!'" get Version /value ^| find "="') do set /a "_svr4=%%a"
)
if %_cwmi% equ 0 (
if exist "!_fvr1!" for /f "tokens=4 delims=." %%a in ('%_psc% "([WMI]'CIM_DataFile.Name=''!cfvr1!''').Version"') do set /a "_svr1=%%a"
if exist "!_fvr2!" for /f "tokens=4 delims=." %%a in ('%_psc% "([WMI]'CIM_DataFile.Name=''!cfvr2!''').Version"') do set /a "_svr2=%%a"
if exist "!_fvr3!" for /f "tokens=4 delims=." %%a in ('%_psc% "([WMI]'CIM_DataFile.Name=''!cfvr3!''').Version"') do set /a "_svr3=%%a"
if exist "!_fvr4!" for /f "tokens=4 delims=." %%a in ('%_psc% "([WMI]'CIM_DataFile.Name=''!cfvr4!''').Version"') do set /a "_svr4=%%a"
)
if %isomin% neq %_svr1% if %isomin% neq %_svr2% if %isomin% neq %_svr3% if %isomin% neq %_svr4% goto :eof
if %isomin% equ %_svr1% set "_chk=!_fvr1!"
if %isomin% equ %_svr2% set "_chk=!_fvr2!"
if %isomin% equ %_svr3% set "_chk=!_fvr3!"
if %isomin% equ %_svr4% set "_chk=!_fvr4!"
for /f "tokens=6 delims=.) " %%# in ('%_psc% "(gi '!_chk!').VersionInfo.FileVersion" %_Nul6%') do set "_ddd=%%#"
if defined _ddd (
if /i not "%_ddd%"=="winpbld" set "isodate=%_ddd%"
)
del /f /q "!_fvr1!" "!_fvr2!" "!_fvr3!" "!_fvr4!" %_Nul3%
goto :eof

:fin
if %online%==0 if %_build% geq 19041 if %winbuild% lss 17133 if exist "%SysPath%\ext-ms-win-security-slc-l1-1-0.dll" (
del /f /q %SysPath%\ext-ms-win-security-slc-l1-1-0.dll %_Nul3%
if /i not %xOS%==x86 del /f /q %SystemRoot%\SysWOW64\ext-ms-win-security-slc-l1-1-0.dll %_Nul3%
)
call :cleaner
if defined tmpssu (
  for %%# in (%tmpssu%) do del /f /q "!repo!\%%~#" %_Nul3%
  set tmpssu=
)
if %wimfiles% equ 1 if exist "!mountdir!\" rmdir /s /q "!mountdir!\" %_Nul1%
if exist "!winremount!\" rmdir /s /q "!winremount!\" %_Nul1%
if %dvd%==1 if %iso%==1 call :ISO
if %_embd% equ 0 (
echo.
echo ============================================================
echo    Finished
echo ============================================================
echo.
)
if %online%==1 if exist "%SystemRoot%\winsxs\pending.xml" (
echo.
echo ============================================================
echo System restart is required to complete installation
echo ============================================================
echo.
)

:E_Exit
if %_embd% neq 0 goto :eof
if %autostart% neq 0 goto :eof
if %_Debug% neq 0 goto :eof
echo.
echo Press 9 or q to exit.
choice /c 9Q /n
if errorlevel 1 (goto :eof) else (rem.)

$:DIR2ISO: #,# [PARAMS] directory file.iso
set ^ #=& set 1=%*& powershell -nop -c "$f0=[io.file]::ReadAllText('!_batp!');$0=($f0-split'\$%0:.*')[1];$1=$env:1-replace'([`@$])','`$1';iex(\"$0 `r`n %0 $1\")"& exit /b !errorlevel!
[Environment]::CurrentDirectory = (Get-Location -PSProvider FileSystem).ProviderPath
function :DIR2ISO ($dir, $iso, $efi=0, $vol='DVD_ROM') { if (!(test-path -Path $dir -pathtype Container)) {"[ERR] $dir\ :DIR2ISO";exit 1}; $dir2iso=@"
 using System; using System.IO; using System.Runtime.Interop`Services; using System.Runtime.Interop`Services.ComTypes;
 public class dir2iso {public int AveYo=2021; [Dll`Import("shlwapi",CharSet=CharSet.Unicode,PreserveSig=false)]
 internal static extern void SHCreateStreamOnFileEx(string f,uint m,uint d,bool b,IStream r,out IStream s);
 public static void Create(string file, ref object obj, int bs, int tb) { IStream dir=(IStream)obj, iso;
 try {SHCreateStreamOnFileEx(file,0x1001,0x80,true,null,out iso);} catch(Exception e) {Console.WriteLine(e.Message); return;}
 int d=tb>1024 ? 1024 : 1, pad=tb%d, block=bs*d, total=(tb-pad)/d, c=total>100 ? total/100 : total, i=1, MB=(bs/1024)*tb/1024;
 Console.Write("{0,3}%  {1}MB {2}",0,MB,file); if (pad > 0) dir.CopyTo(iso, pad * block, Int`Ptr.Zero, Int`Ptr.Zero);
 while (total-- > 0) {dir.CopyTo(iso, block, Int`Ptr.Zero, Int`Ptr.Zero); if (total % c == 0) {Console.Write("\r{0,3}%",i++);}}
 iso.Commit(0); Console.WriteLine("\r{0,3}%  {1}MB {2}", 100, MB, file); } }
"@; & { $cs=new-object CodeDom.Compiler.CompilerParameters; $cs.GenerateInMemory=1 #,# no`warnings
 $compile=(new-object Microsoft.CSharp.CSharpCodeProvider).CompileAssemblyFromSource($cs, $dir2iso)
 $BOOT=@(); $bootable=0; if ($efi) {$idx=0; $mbr_efi=@(0xEF); $images=@('efi\microsoft\boot\efisys.bin')} else {$idx=0,1; $mbr_efi=@(0,0xEF); $images=@('boot\etfsboot.com','efi\microsoft\boot\efisys.bin')}
 $idx|% { $bootimage=join-path $dir -child $images[$_]; if (test-path -Path $bootimage -pathtype Leaf) {
 $bin=new-object -ComObject ADODB.Stream; $bin.Open(); $bin.Type=1; $bin.LoadFromFile($bootimage)
 $opt=new-object -ComObject IMAPI2FS.BootOptions; $opt.AssignBootImage($bin.psobject.BaseObject); $opt.Manufacturer='Microsoft'
 $opt.PlatformId=$mbr_efi[$_]; $opt.Emulation=0; $bootable=1; $BOOT += $opt.psobject.BaseObject } }
 $fsi=new-object -ComObject IMAPI2FS.MsftFileSystemImage; $fsi.FileSystemsToCreate=4; $fsi.FreeMediaBlocks=0; $fsi.UDFRevision=0x102
 if ($bootable) {$fsi.BootImageOptionsArray=$BOOT}; $CONTENT=$fsi.Root; $CONTENT.AddTree($dir,$false); $fsi.VolumeName=$vol
 $obj=$fsi.CreateResultImage(); [dir2iso]::Create($iso,[ref]$obj.ImageStream,$obj.BlockSize,$obj.TotalBlocks) };[GC]::Collect()
} $:DIR2ISO: #,# export directory as (bootable) udf iso - lean and mean snippet by AveYo, 2021

:cabpsf:
function Native($DllFile)
{
$Lib = [IO.Path]::GetFileName($DllFile)
$Marshal = [System.Runtime.InteropServices.Marshal]
$Module = [AppDomain]::CurrentDomain.DefineDynamicAssembly((Get-Random), 'Run').DefineDynamicModule((Get-Random))
$Struct = $Module.DefineType('DI', 1048841, [ValueType], 0)
[void]$Struct.DefineField('lpStart', [IntPtr], 6)
[void]$Struct.DefineField('uSize', [UIntPtr], 6)
[void]$Struct.DefineField('Editable', [Boolean], 6)
$DELTA_INPUT = $Struct.CreateType()
$Struct = $Module.DefineType('DO', 1048841, [ValueType], 0)
[void]$Struct.DefineField('lpStart', [IntPtr], 6)
[void]$Struct.DefineField('uSize', [UIntPtr], 6)
$DELTA_OUTPUT = $Struct.CreateType()
$Class = $Module.DefineType('PSFE', 1048961, [Object], 0)
[void]$Class.DefinePInvokeMethod('LoadLibraryW', 'kernel32.dll', 22, 1, [IntPtr], @([String]), 1, 3).SetImplementationFlags(128)
[void]$Class.DefinePInvokeMethod('ApplyDeltaB', $Lib, 22, 1, [Int32], @([Int64], [Type]$DELTA_INPUT, [Type]$DELTA_INPUT, [Type]$DELTA_OUTPUT.MakeByRefType()), 1, 3)
[void]$Class.DefinePInvokeMethod('DeltaFree', $Lib, 22, 1, [Int32], @([IntPtr]), 1, 3)
$Win32 = $Class.CreateType()
}
function ApplyDelta($dBuffer, $dFile)
{
$trg = [Activator]::CreateInstance($DELTA_OUTPUT)
$src = [Activator]::CreateInstance($DELTA_INPUT)
$dlt = [Activator]::CreateInstance($DELTA_INPUT)
$dlt.lpStart = $Marshal::AllocHGlobal($dBuffer.Length)
$dlt.uSize = [Activator]::CreateInstance([UIntPtr], @([UInt32]$dBuffer.Length))
$dlt.Editable = $true
$Marshal::Copy($dBuffer, 0, $dlt.lpStart, $dBuffer.Length)
[void]$Win32::ApplyDeltaB(0, $src, $dlt, [ref]$trg)
if ($trg.lpStart -eq [IntPtr]::Zero) {return}
$out = New-Object byte[] $trg.uSize.ToUInt32()
$Marshal::Copy($trg.lpStart, $out, 0, $out.Length)
[IO.File]::WriteAllBytes($dFile, $out)
if ($dlt.lpStart -ne [IntPtr]::Zero) {$Marshal::FreeHGlobal($dlt.lpStart)}
if ($trg.lpStart -ne [IntPtr]::Zero) {[void]$Win32::DeltaFree($trg.lpStart)}
}
function G($DirectoryName)
{
$DeltaList = [ordered] @{}
$doc = New-Object xml
$doc.Load($DirectoryName + "\express.psf.cix.xml")
$child = $doc.FirstChild.NextSibling.FirstChild
while (!$child.LocalName.Equals("Files")) {$child = $child.NextSibling}
$FileList = $child.ChildNodes
foreach ($file in $FileList)
{
$fileChild = $file.FirstChild
while (!$fileChild.LocalName.Equals("Delta")) {$fileChild = $fileChild.NextSibling}
$deltaChild = $fileChild.FirstChild
while (!$deltaChild.LocalName.Equals("Source")) {$deltaChild = $deltaChild.NextSibling}
$DeltaList[$($file.id)] = @{name=$file.name; time=$file.time; stype=$deltaChild.type; offset=$deltaChild.offset; length=$deltaChild.length};
}
return $DeltaList
}
function P($CabFile, $DllFile = 'msdelta.dll')
{
if ($DllFile -eq 'msdelta.dll' -and (Test-Path "$env:SystemRoot\System32\UpdateCompression.dll")) {$DllFile = "$env:SystemRoot\System32\UpdateCompression.dll"}
. Native($DllFile)
[void]$Win32::LoadLibraryW($DllFile)
$DirectoryName = $CabFile.Substring(0, $CabFile.LastIndexOf('.'))
$PSFFile = $DirectoryName + ".psf"
$null = [IO.Directory]::CreateDirectory($DirectoryName)
$DeltaList = G  $DirectoryName
$PSFFileStream = [IO.File]::OpenRead([IO.Path]::GetFullPath($PSFFile))
$cwd = [IO.Path]::GetFullPath($DirectoryName)
[Environment]::CurrentDirectory = $cwd
$null = [IO.Directory]::CreateDirectory("000")
foreach ($DeltaFile in $DeltaList.Values)
{
$FullFileName = $DeltaFile.name
if (Test-Path $FullFileName) {continue}
$ShortFold = [IO.Path]::GetDirectoryName($FullFileName)
$ShortFile = [IO.Path]::GetFileName($FullFileName)
[bool]$UseRobo = (($cwd + '\' + $FullFileName).Length -gt 255) -or (($cwd + '\' + $ShortFold).Length -gt 248)
if ($UseRobo -eq 0 -and $ShortFold.IndexOf("_") -ne -1) {$null = [IO.Directory]::CreateDirectory($ShortFold)}
if ($UseRobo -eq 0) {$WhereFile = $FullFileName}
Else {$WhereFile = "000\" + $ShortFile}
try {[void]$PSFFileStream.Seek($DeltaFile.offset, 0)} catch {}
$Buffer = New-Object byte[] $DeltaFile.length
try {[void]$PSFFileStream.Read($Buffer, 0, $DeltaFile.length)} catch {}
$OutputFileStream = [IO.File]::Create($WhereFile)
try {[void]$OutputFileStream.Write($Buffer, 0, $DeltaFile.length)} catch {}
[void]$OutputFileStream.Close()
if ($DeltaFile.stype -eq "PA30" -or $DeltaFile.stype -eq "PA31") {ApplyDelta $Buffer $WhereFile}
$null = [IO.File]::SetLastWriteTimeUtc($WhereFile, [DateTime]::FromFileTimeUtc($DeltaFile.time))
if ($UseRobo -eq 0) {continue}
Start-Process robocopy.exe -NoNewWindow -Wait -ArgumentList ('"' + $cwd + '\000' + '"' + ' ' + '"' + $cwd + '\' + $ShortFold + '"' + ' ' + $ShortFile + ' /MOV /R:1 /W:1 /NS /NC /NFL /NDL /NP /NJH /NJS')
}
[void]$PSFFileStream.Close()
$null = [IO.Directory]::Delete("000", $True)
}
:cabpsf:
:: ============

:wimmsu:
function E($WimPath, $InnFile, $OutFile) {
$DllPath = 'wimgapi.dll'
$TB = [AppDomain]::CurrentDomain.DefineDynamicAssembly(4, 1).DefineDynamicModule(2, $False).DefineType(0)
$FN = @(
'WIMCreateFile;IntPtr;String, UInt32, Int32, Int32, Int32, Int32#Ref;128',
'WIMLoadImage;IntPtr;IntPtr, Int32;128',
'WIMSetTemporaryPath;int;IntPtr, String;0',
'WIMExtractImagePath;int;IntPtr, String, String, Int32;0',
'WIMCloseHandle;int;IntPtr;0'
)
foreach ($str in $FN) {
$m=$str -split ';'
$r=$m[1] -as [Type]
$f=$m[3] -as [int]
$p = [Collections.ArrayList]@()
$m[2] -split ', ' | % { $i = $_ -split '#'; if ($null -eq $i[1]) {$p += ($_ -as [type])} else {$p += (($i[0] -as [type]).MakeByRefType())} }
[void]$TB.DefinePInvokeMethod($m[0], $DllPath, 22, 1, $r, $p, 1, 3).SetImplementationFlags($f)
}
$WIMG = $TB.CreateType()
$hWim = 0
$hImage = 0
$hWim = $WIMG::WIMCreateFile($WimPath, "0x80000000", 3, "0x20000000", 0, [ref]$null)
[void]$WIMG::WIMSetTemporaryPath($hWim, [Environment]::GetEnvironmentVariable('SystemDrive'))
$hImage = $WIMG::WIMLoadImage($hWim, 1)
[void]$WIMG::WIMExtractImagePath($hImage, $InnFile, $OutFile, 0)
[void]$WIMG::WIMCloseHandle($hImage)
[void]$WIMG::WIMCloseHandle($hWim)
}
:wimmsu:
:: ============

:cbsreg:
$Class = [AppDomain]::CurrentDomain.DefineDynamicAssembly(4, 1).DefineDynamicModule(2, $False).DefineType(0)
[void]$Class.DefinePInvokeMethod('OpenProcessToken', 'advapi32.dll', 22, 1, [Boolean], @([IntPtr], [UInt32], [IntPtr].MakeByRefType()), 1, 3)
[void]$Class.DefinePInvokeMethod('DuplicateToken', 'advapi32.dll', 22, 1, [Boolean], @([IntPtr], [Int32], [IntPtr].MakeByRefType()), 1, 3)
[void]$Class.DefinePInvokeMethod('SetThreadToken', 'advapi32.dll', 22, 1, [Boolean], @([IntPtr], [IntPtr]), 1, 3)
$Win32 = $Class.CreateType()
$sysProc = [Diagnostics.Process]::GetProcessById(([WMI]'Win32_Service.Name=''SamSs''').ProcessId)
$sysTkn = 0; $dupTkn = 0
[void]$Win32::OpenProcessToken($sysProc.Handle, 6, [ref]$sysTkn)
[void]$Win32::DuplicateToken($sysTkn, 2, [ref]$dupTkn)
[void]$Win32::SetThreadToken(0, $dupTkn)
Start-Service TrustedInstaller
$tiProc = [Diagnostics.Process]::GetProcessById(([WMI]'Win32_Service.Name=''TrustedInstaller''').ProcessId)
$tiTkn = 0; $dupTkn = 0
[void]$Win32::OpenProcessToken($tiProc.Handle, 46, [ref]$tiTkn)
[void]$Win32::DuplicateToken($tiTkn, 2, [ref]$dupTkn)
[void]$Win32::SetThreadToken(0, $dupTkn)
iex ([IO.File]::ReadAllText($r)) | Out-Null
:cbsreg:
:: ============

:EndDebug
cmd /u /c type "!_log!_tmp.log">"!_log!_Debug.log"
(goto) &del "!_log!_tmp.log"
exit
