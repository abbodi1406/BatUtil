@setlocal DisableDelayedExpansion
@set uiv=v7.7
@echo off
:: enable debug mode, you must also set target and repo (if updates folder is not beside the script)
set _Debug=0

:: when changing below options, recommended to set the new values between = and " marks

:: target distribution, wim file or offline image
:: leave it blank to update current online os, or automatically detect wim file next to the script
set "Target="

:: location for WHD repository "Updates" directory (default is next to the script)
set "Repo=Updates"

:: dism.exe tool custom path (if Host OS Win7 and no Win ADK installed)
set "DismRoot=dism.exe"

:: updates processing options
set OnlineLimit=75
set LDRbranch=YES
set Hotfix=YES
set WUSatisfy=YES
set Windows10=NO
set WMF=NO
set RSAT=NO

:: enable .NET 3.5 feature
set Net35=1

:: Cleanup OS images to "compress" superseded components
set Cleanup=1

:: Rebase OS images to "remove" superseded components
:: require first to set Cleanup=1
set ResetBase=1

:: update winre.wim if detected inside install.wim
set WinRE=1

:: set directory for temporary extracted files (default is on the same drive as the script)
set "Cab_Dir=W81UItemp"

:: set mount directory for updating wim files (default is on the same drive as the script)
set "MountDir=W81UImount"
set "WinreMount=W81UImountre"

:: start the process directly once you execute the script, as long as the other options are correctly set
set AutoStart=0

:: # Options for wim or distribution target only #

:: change install.wim image creation time to match last modification time (require wimlib-imagex.exe)
set WimCreateTime=0

:: # Options for distribution target only #

:: convert install.wim to install.esd
:: warning: the process will consume very high amount of CPU and RAM resources
set wim2esd=0

:: create new iso file
:: require Win ADK, or place oscdimg.exe or cdimage.exe next to the script
set ISO=1

:: folder path for iso file, leave it blank to create in the script current directory
set "ISODir="

:: delete DVD distribution folder after creating updated ISO
set Delete_Source=0

:: ###################################################################
:: # NORMALLY THERE IS NO NEED TO CHANGE ANYTHING BELOW THIS COMMENT #
:: ###################################################################

:: Technical options for updates
set ssu1=KB3021910
set baselinelist=KB2919355,KB3000850,KB2932046,KB2934018,KB2937592,KB2938439,KB2938772,KB3003057,KB3014442
set gdrlist=KB3023219,KB3037576,KB3074545,KB3097992,KB3127222
set hv_integ_kb=hypervintegrationservices
set hv_integ_vr=9600.19984

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
set _blue=0
if %winbuild% geq 9600 if %winbuild% lss 9606 set _blue=1
reg.exe query HKU\S-1-5-19 %_Null% || goto :E_Admin
set "_SbS=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\SideBySide\Configuration"
set "_CBS=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing"
set "_Pkt=31bf3856ad364e35"
set "_OurVer=6.3.9603.30600"
set "_oscdimg=%SysPath%\oscdimg.exe"
set "_log=%~dpn0"
set "_work=%~dp0"
set "_work=%_work:~0,-1%"
for /f "skip=2 tokens=2*" %%a in ('reg.exe query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop') do call set "_dsk=%%b"
if exist "%PUBLIC%\Desktop\desktop.ini" set "_dsk=%PUBLIC%\Desktop"
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
echo.
echo Running WHD-W81UI %uiv% in Debug Mode...
echo The window will be closed when finished
@echo on
@prompt $G
@call :Begin >"!_log!_tmp.log" 2>&1 &cmd /u /c type "!_log!_tmp.log">"!_log!_Debug.log"&del "!_log!_tmp.log"
@title %ComSpec%
@exit /b

:Begin
title Installer for Windows 8.1 Updates
cd /d "!_work!"
if not exist "WHD-W81UI.ini" goto :proceed
find /i "[W81UI-Configuration]" WHD-W81UI.ini %_Nul1% || goto :proceed
setlocal DisableDelayedExpansion
for %%# in (
target
repo
dismroot
net35
cleanup
resetbase
winre
cab_dir
mountdir
winremount
wim2esd
iso
isodir
delete_source
autostart
wimcreatetime
OnlineLimit
LDRbranch
Hotfix
WUSatisfy
Windows10
WMF
RSAT
) do (
call :ReadINI %%#
)
setlocal EnableDelayedExpansion
goto :proceed

:ReadINI
find /i "%1 " WHD-W81UI.ini >nul || goto :eof
for /f "skip=2 tokens=1* delims==" %%A in ('find /i "%1 " WHD-W81UI.ini') do set "%1=%%~B"
goto :eof

:proceed
if %_Debug% neq 0 set autostart=1
if "!repo!"=="" set "repo=Updates"
if "!dismroot!"=="" set "DismRoot=dism.exe"
if "!cab_dir!"=="" set "Cab_Dir=W81UItemp"
if "!mountdir!"=="" set "MountDir=W81UImount"
if "!winremount!"=="" set "WinreMount=W81UImountre"
if "%Net35%"=="" set Net35=1
if "%Cleanup%"=="" set Cleanup=0
if "%ResetBase%"=="" set ResetBase=0
if "%WinRE%"=="" set WinRE=1
if "%ISO%"=="" set ISO=1
if "%AutoStart%"=="" set AutoStart=0
if "%WimCreateTime%"=="" set WimCreateTime=0
if "%Delete_Source%"=="" set Delete_Source=0
if "%wim2esd%"=="" set wim2esd=0
if "%OnlineLimit%"=="" set OnlineLimit=75
for %%# in (LDRbranch Hotfix WUSatisfy) do if "!%%#!"=="" set "%%#=YES"
for %%# in (Windows10 WMF RSAT) do if "!%%#!"=="" set "%%#=NO"
set _wimlib=
set _wlib=0
for %%# in (wimlib-imagex.exe) do @if not "%%~$PATH:#"=="" (
set _wimlib=wimlib-imagex.exe
)
if not defined _wimlib (
if exist "wimlib-imagex.exe" set _wimlib="!_work!\wimlib-imagex.exe"
if exist "bin\wimlib-imagex.exe" set _wimlib="!_work!\bin\wimlib-imagex.exe"
if /i %xOS%==amd64 if exist "bin\bin64\wimlib-imagex.exe" set _wimlib="!_work!\bin\bin64\wimlib-imagex.exe"
)
if defined _wimlib (
set _wlib=1
) else (
set WimCreateTime=0
)
set _ADK=0
set "showdism=Host OS"
set "_dism2=%dismroot% /NoRestart /ScratchDir"
if /i not "!dismroot!"=="dism.exe" (
set _ADK=1
set "showdism=%dismroot%"
set _dism2="%dismroot%" /NoRestart /ScratchDir
set "dsv=!dismroot:\=\\!"
call :DismVer
) else (
set "dsv=%SysPath%\dism.exe"
set "dsv=!dsv:\=\\!"
call :DismVer
)
if /i "!repo!"=="Updates" (if exist "!_work!\Updates\Windows8.1-*" (set "repo=!_work!\Updates") else (set "repo="))
for %%# in (LDRbranch Hotfix WUSatisfy Windows10 WMF RSAT) do if /i "!%%#!"=="NO" set "%%#=NO "
set _drv=%~d0
if /i "%cab_dir:~0,5%"=="W81UI" set "cab_dir=%_drv%\W81UItemp"
set _ntf=NTFS
if /i not "%_drv%"=="%SystemDrive%" if %_cwmi% equ 1 for /f "tokens=2 delims==" %%# in ('"wmic volume where DriveLetter='%_drv%' get FileSystem /value"') do set "_ntf=%%#"
if /i not "%_drv%"=="%SystemDrive%" if %_cwmi% equ 0 for /f %%# in ('%_psc% "(([WMISEARCHER]'Select * from Win32_Volume where DriveLetter=\"%_drv%\"').Get()).FileSystem"') do set "_ntf=%%#"
if /i not "%_ntf%"=="NTFS" set _drv=%SystemDrive%
if /i "%mountdir:~0,5%"=="W81UI" set "mountdir=%_drv%\W81UImount"
if /i "%winremount:~0,5%"=="W81UI" set "winremount=%_drv%\W81UImountre"
if "%cab_dir:~-1%"=="\" set "cab_dir=!cab_dir:~0,-1!"
if "%cab_dir:~-1%"==":" set "cab_dir=!cab_dir!\"
if not "!cab_dir!"=="!cab_dir: =!" set "cab_dir=!cab_dir: =!"
if "%mountdir:~-1%"=="\" set "mountdir=!mountdir:~0,-1!"
if "%mountdir:~-1%"==":" set "mountdir=!mountdir!\"
if not "!mountdir!"=="!mountdir: =!" set "mountdir=!mountdir: =!"
set "mountdir=!mountdir!_%random%"
set "winremount=!winremount!_%random%"
set "cab_dir=!cab_dir!_%random%"
if exist "!cab_dir!\" (
echo.
echo ============================================================
echo Cleaning temporary extraction folder...
echo ============================================================
echo.
rmdir /s /q "!cab_dir!\" %_Nul1%
)
set _init=1

:checktarget
set isomin=0
set _SrvEdt=0
set _DNF=0
set dvd=0
set wim=0
set offline=0
set online=0
set copytarget=0
set imgcount=0
set wimfiles=0
set keep=0
set targetname=0
if not defined _all set _all=1
if %_init%==1 if "!target!"=="" if exist "*.wim" (for /f "tokens=* delims=" %%# in ('dir /b /a:-d "*.wim" ^| findstr /i /v "Windows1.*\-KB"') do set "target=!_work!\%%~nx#")
if "!target!"=="" set "target=%SystemDrive%"
if "%target:~-1%"=="\" set "target=!target:~0,-1!"
if /i "!target!"=="%SystemDrive%" (
if /i %xOS%==amd64 (set arch=x64) else (set arch=x86)
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
dir /b /ad "!target!\Windows\servicing\Version\6.3.960*" %_Nul3% || (set "MESSAGE=Detected target offline image is not Windows 8.1"&goto :E_Target)
set "mountdir=!target!"
set arch=x86
if exist "!target!\Windows\Servicing\Packages\*~amd64~~*.mum" set arch=x64
)
if %wim%==1 (
echo.
echo ============================================================
echo Please wait...
echo ============================================================
cd /d "!targetpath!"
dism.exe /english /get-wiminfo /wimfile:"%targetname%" /index:1 | find /i "Version : 6.3.960" %_Nul1% || (set "MESSAGE=Detected wim version is not Windows 8.1"&goto :E_Target)
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
dism.exe /english /get-wiminfo /wimfile:"sources\install.wim" /index:1 | find /i "Version : 6.3.960" %_Nul1% || (set "MESSAGE=Detected install.wim version is not Windows 8.1"&goto :E_Target)
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
if /i %xOS%==amd64 (set arch=x64) else (set arch=x86)
reg.exe query %_SbS% /v W81UIclean %_Nul3% && (set onlineclean=1)
reg.exe query %_SbS% /v W81UIrebase %_Nul3% && (set onlineclean=1)
)
if not defined onlineclean goto :main1board

:main0board
set _elr=0
@cls
echo ===================== WHD-W81UI %uiv% =======================
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
reg.exe delete %_SbS% /v W81UIclean /f %_Nul3%
reg.exe delete %_SbS% /v W81UIrebase /f %_Nul3%
goto :main1board
)
if %_elr%==1 (
reg.exe query %_SbS% /v W81UIclean %_Nul3% && (set online=1&set cleanup=1)
reg.exe query %_SbS% /v W81UIrebase %_Nul3% && (set online=1&set cleanup=1&set resetbase=1)
goto :main2board
)
goto :main0board

:main1board
if /i not "!dismroot!"=="dism.exe" if exist "!dismroot!" goto :mainmenu
goto :checkadk

:mainboard
if %_blue% neq 1 if /i "!target!"=="%SystemDrive%" (%_Goto%)
if %winbuild% lss 9600 if %_ADK% equ 0 (%_Goto%)
if "!target!"=="" (%_Goto%)
if "!repo!"=="" (%_Goto%)
if "%repo:~-1%"=="\" set "repo=!repo:~0,-1!"
if exist "!repo!\Windows8.1-Update3-%arch%\Security\*" (set "repo=!repo!\Windows8.1-Update3-%arch%") else (set "repo=!repo!\Windows8.1-%arch%")
if "!cab_dir!"=="" (%_Goto%)
if "!mountdir!"=="" (%_Goto%)
if /i "!target!"=="%SystemDrive%" (set dismtarget=/online&set "mountdir=!target!"&set online=1) else (set dismtarget=/image:"!mountdir!")

:main2board
@cls
echo ============================================================
echo Running WHD-W81UI %uiv%
echo ============================================================
if %online%==1 (
net stop trustedinstaller %_Nul3%
net stop wuauserv %_Nul3%
del /f /q %systemroot%\Logs\CBS\* %_Nul3%
)
del /f /q %systemroot%\Logs\DISM\* %_Nul3%
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
set dismtarget=/online
reg.exe delete %_SbS% /v W81UIclean /f %_Nul3%
reg.exe delete %_SbS% /v W81UIrebase /f %_Nul3%
if not exist "!Cab_Dir!\" mkdir "!Cab_Dir!"
call :cleanup
goto :fin
)
if %dvd%==1 if %copytarget%==1 (
echo.
echo ============================================================
echo Copying DVD Drive contents to work directory
echo ============================================================
if exist "!_work!\DVD81UI\" rmdir /s /q "!_work!\DVD81UI\" %_Nul1%
robocopy "!target!" "!_work!\DVD81UI" /E /A-:R >nul
set "target=!_work!\DVD81UI"
)
if /i %arch%==x64 (set efifile=bootx64.efi&set sss=amd64) else (set efifile=bootia32.efi&set sss=x86)

:igonline
if %online%==0 goto :igoffline
call :doupdate
call :cleanup
goto :fin

:igoffline
if %offline%==0 goto :igwim
call :doupdate
call :cleanup
goto :fin

:igwim
if %wim%==0 goto :igdvd
if "%indices%"=="*" set "indices="&for /L %%# in (1,1,!imgcount!) do set "indices=!indices! %%#"
call :domount "%targetname%"
if /i not "%targetname%"=="winre.wim" (if exist "!_work!\winre.wim" del /f /q "!_work!\winre.wim" %_Nul1%)
if %WimCreateTime% equ 1 (
cd /d "!targetpath!"
call :wimTime "%targetname%"
)
goto :fin

:igdvd
if %dvd%==0 goto :fin
if "%indices%"=="*" set "indices="&for /L %%# in (1,1,!imgcount!) do set "indices=!indices! %%#"
call :domount sources\install.wim
if exist "!_work!\winre.wim" del /f /q "!_work!\winre.wim" %_Nul1%
if %WimCreateTime% equ 1 (
cd /d "!target!\sources"
call :wimTime install.wim
)
set keep=0&set imgcount=%bootimg%&set "indices="&for /L %%# in (1,1,!imgcount!) do set "indices=!indices! %%#"
call :domount sources\boot.wim
xcopy /CRY "!target!\efi\microsoft\boot\fonts" "!target!\boot\fonts\" %_Nul1%
if %_DNF%==1 if exist "!target!\sources\sxs\msil_microsoft.build.engine*3.5.9600.16384*" (rmdir /s /q "!target!\sources\sxs\" %_Nul1%)
if %wim2esd%==0 goto :fin
echo.
echo ============================================================
echo Converting install.wim to install.esd ...
echo ============================================================
cd /d "!target!"
for /f "tokens=2 delims=: " %%# in ('dism.exe /english /get-wiminfo /wimfile:"sources\install.wim" ^| find /i "Index"') do set imgcount=%%#
for /L %%# in (1,1,%imgcount%) do %_dism2%:"!cab_dir!" /Export-Image /SourceImageFile:sources\install.wim /SourceIndex:%%# /DestinationImageFile:sources\install.esd /Compress:Recovery
if %errorlevel% neq 0 del /f /q sources\install.esd %_Nul3%
if exist sources\install.esd del /f /q sources\install.wim
cd /d "!_work!"
goto :fin

:wimTime
if %_pwsh% equ 0 goto :eof
set "_wimfile=%~1"
if exist "wim.xml" del /f /q wim.xml
!_wimlib! info "%_wimfile%" --extract-xml wim.xml
if not exist "wim.xml" goto :eof
echo.
echo ============================================================
echo Modifying %_wimfile% image creation time ...
echo ============================================================
echo.
for %%# in (%indices%) do (
  for /f "tokens=1,2" %%A in ('%_psc% "$x = [xml](Get-Content 'wim.xml'); $d = ($x.WIM.IMAGE | where { $_.INDEX -eq %%# }).LASTMODIFICATIONTIME; echo ($d.HIGHPART+' '+$d.LOWPART)"') do (call set "HIGHPART=%%A"&call set "LOWPART=%%B")
  !_wimlib! info "%_wimfile%" %%# --image-property CREATIONTIME/HIGHPART=!HIGHPART! --image-property CREATIONTIME/LOWPART=!LOWPART! %_Nul1%
)
if exist "wim.xml" del /f /q wim.xml
goto :eof

:doupdate
set verb=1
if not "%1"=="" (
set verb=0
set "mountdib=!mountdir!"
set "mountdir=!winremount!"
set dismtarget=/image:"!winremount!"
)
if %online%==1 (
for /f "skip=2 tokens=2*" %%a in ('reg.exe query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v EditionID') do set "CEdition=%%b"
) else if not exist "!mountdir!\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" (
reg.exe load HKLM\OFFSOFT "!mountdir!\Windows\System32\config\SOFTWARE" %_Nul1%
for /f "skip=2 tokens=2*" %%a in ('reg.exe query "HKLM\OFFSOFT\Microsoft\Windows NT\CurrentVersion" /v EditionID') do set "CEdition=%%b"
reg.exe unload HKLM\OFFSOFT %_Nul1%
)
set _KB3179574=0
echo %CEdition% | findstr /i /b Enterprise %_Nul1% && set _KB3179574=1
echo %CEdition% | findstr /i /b Server %_Nul1% && set _KB3179574=1
if %online%==1 (
set SOFTWARE=SOFTWARE
set COMPONENTS=COMPONENTS
) else (
set SOFTWARE=uiSOFTWARE
set COMPONENTS=uiCOMPONENTS
)
set "_SxS=HKLM\%SOFTWARE%\Microsoft\Windows\CurrentVersion\SideBySide\Winners"
set "_Cmp=HKLM\%COMPONENTS%\DerivedData\Components"
if exist "!mountdir!\Windows\Servicing\Packages\*~amd64~~*.mum" (
set "xBT=amd64"
set "_EsuKey=%_SxS%\amd64_microsoft-windows-s..edsecurityupdatesai_%_Pkt%_none_0e8b36cfce2fb332"
set "_EsuCom=amd64_microsoft-windows-s..edsecurityupdatesai_%_Pkt%_%_OurVer%_none_6022b34506a8b67a"
set "_EsuIdn=4D6963726F736F66742D57696E646F77732D534C432D436F6D706F6E656E742D457874656E64656453656375726974795570646174657341492C2043756C747572653D6E65757472616C2C2056657273696F6E3D362E332E393630332E33303630302C205075626C69634B6579546F6B656E3D333162663338353661643336346533352C2050726F636573736F724172636869746563747572653D616D6436342C2076657273696F6E53636F70653D4E6F6E537853"
set "_EsuHsh=423FEE4BEB5BCA64D89C7BCF0A69F494288B9A2D947C76A99C369A378B79D411"
) else (
set "xBT=x86"
set "_EsuKey=%_SxS%\x86_microsoft-windows-s..edsecurityupdatesai_%_Pkt%_none_b26c9b4c15d241fc"
set "_EsuCom=x86_microsoft-windows-s..edsecurityupdatesai_%_Pkt%_%_OurVer%_none_040417c14e4b4544"
set "_EsuIdn=4D6963726F736F66742D57696E646F77732D534C432D436F6D706F6E656E742D457874656E64656453656375726974795570646174657341492C2043756C747572653D6E65757472616C2C2056657273696F6E3D362E332E393630332E33303630302C205075626C69634B6579546F6B656E3D333162663338353661643336346533352C2050726F636573736F724172636869746563747572653D7838362C2076657273696F6E53636F70653D4E6F6E537853"
set "_EsuHsh=70FC6E62A198F5D98FDDE11A6E8D6C885E17C53FCFE1D927496351EADEB78E42"
)
if not exist "!mountdir!\Windows\WinSxS\Manifests\%_EsuCom%.manifest" call :ESUadd %_Nul3%
if not exist "!mountdir!\Windows\WinSxS\Manifests\%_EsuCom%.manifest"  (
echo.
echo %_err%
echo Failed installing ESU Suppressor
)
set allcount=0
set _GDR=0
set winpe=0
if exist "!mountdir!\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" goto :wpe
call :ssup
call :baseline
call :general
call :online
if %net35%==1 call :enablenet35
call :net35
if /i "%WMF%"=="YES" call :wmf
if /i "%Hotfix%"=="YES" call :hotfix
if /i "%WUSatisfy%"=="YES" call :wusatisfy
if /i "%RSAT%"=="YES" call :rsat
if /i "%Windows10%"=="YES" call :windows10
call :security
goto :eof

:wpe
call :ssup
call :baseline
call :security
set winpe=1
call :winpe
set winpe=0
goto :eof

:ssup
if %online%==1 if exist "%SystemRoot%\winsxs\pending.xml" (goto :stacklimit)
if not exist "!repo!\Baseline\*%arch%*.msu" goto :eof
call :cleaner
cd Baseline\
if not exist "!mountdir!\Windows\servicing\packages\package_for_KB2919355_rtm*.mum" (set "package=%ssu1%"&set "dest=%ssu1%"&call :ssus)
for /f "tokens=2 delims=-" %%# in ('dir /b /a:-d "*%arch%*.msu"') do (set "package=%%#"&set "dest=%%~n#"&call :ssul)
set "package=%ssu1%"&set "dest=%ssu1%"&call :ssus
goto :eof

:ssul
for %%j in (%ssu1%,%baselinelist%) do if /i %%j==%package% goto :eof

:ssus
if not exist "*%package%*%arch%*.msu" goto :eof
if exist "!mountdir!\Windows\servicing\packages\package_for_%package%~*.mum" goto :eof
:: if /i not %package%==%ssu1% (
:: if not exist "!mountdir!\Windows\servicing\packages\package_for_KB2919355_rtm*.mum" goto :eof
:: if not exist "!mountdir!\Windows\servicing\packages\package_for_KB2975061_rtm*.mum" if not exist "!mountdir!\Windows\servicing\packages\package_for_%ssu1%_rtm*.mum" goto :eof
:: )
set ssuver=9600.16384
for /f "tokens=3,4 delims=." %%i in ('dir /b "!mountdir!\Windows\servicing\Version"') do set "ssuver=%%i.%%j"
if /i %package%==%ssu1% (
if %ssuver:~0,4% equ 9600 if %ssuver:~5,5% gtr 17709 goto :eof
if %ssuver:~0,4% gtr 9600 goto :eof
)
if %verb%==1 (
echo.
echo ============================================================
echo *** Servicing Stack Update ***
echo ============================================================
)
cd /d "!cab_dir!"
if not exist "%dest%\*.manifest" (
expand.exe -f:*Windows*.cab "!repo!\Baseline\*%package%*%arch%*.msu" . %_Null%
mkdir "%dest%"
expand.exe -f:* "*%package%*.cab" "%dest%" %_Null% || (
  rmdir /s /q "%dest%\" %_Nul3%
  %_dism2%:"!cab_dir!" %dismtarget% /Add-Package /packagepath:.
  del /f /q "*%package%*.cab"
  cd /d "!repo!\Baseline"
  goto :eof
  )
)
%_dism2%:"!cab_dir!" %dismtarget% /Add-Package /packagepath:"%dest%\update.mum"
cd /d "!repo!\Baseline"
goto :eof

:baseline
if not exist "!repo!\Baseline\*%arch%*.msu" goto :eof
call :cleaner
if %verb%==1 (
echo.
echo ============================================================
echo *** Baseline Updates ***
echo ============================================================
)
cd Baseline\
if %verb%==1 (
echo.
echo ============================================================
echo Checking and Extracting Applicable Updates
echo *** This will require some disk space, please be patient ***
echo ============================================================
echo.
)
set ldr=
for %%# in (%baselinelist%) do (set "package=%%#"&set "dest=%%~n#"&call :base2line)
if not defined ldr goto :eof
if %verb%==1 (
echo.
echo ============================================================
echo Installing %count% Baseline Updates
echo ============================================================
)
cd /d "!cab_dir!"
%_dism2%:"!cab_dir!" %dismtarget% /Add-Package %ldr%
goto :eof

:base2line
if exist "!mountdir!\Windows\servicing\packages\package_for_%package%_rtm*.mum" goto :eof
if exist "!mountdir!\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" (
if /i %package%==KB3003057 goto :eof
if /i %package%==KB3014442 goto :eof
)
if not exist "*%package%*%arch%*" if not exist "RTM\*%package%*%arch%*" goto :eof
set /a count+=1
if not exist "!cab_dir!\%dest%\*.manifest" (
echo %count%: %package%
if exist "*%package%*%arch%*.cab" copy /y *%package%*%arch%*.cab "!cab_dir!\" %_Nul1%
if exist "RTM\*%package%*%arch%*.cab" copy /y RTM\*%package%*%arch%*.cab "!cab_dir!\" %_Nul1%
if exist "*%package%*%arch%*.msu" expand.exe -f:*Windows*.cab "*%package%*%arch%*.msu" "!cab_dir!" %_Null%
if exist "RTM\*%package%*%arch%*.msu" expand.exe -f:*Windows*.cab "RTM\*%package%*%arch%*.msu" "!cab_dir!" %_Null%
mkdir "!cab_dir!\%dest%"
expand.exe -f:* "!cab_dir!\*%package%*.cab" "!cab_dir!\%dest%" %_Null% || (
  rmdir /s /q "!cab_dir!\%dest%\" %_Nul3%
  for /f "tokens=* delims=" %%# in ('dir /b /a:-d "!cab_dir!\*%package%*.cab"') do set "ldr=!ldr! /packagepath:%%~#"
  goto :eof
  )
)
set "ldr=!ldr! /packagepath:%dest%\update.mum"
if %online%==1 if /i %package%==KB2919355 (
cd /d "!cab_dir!"
%_dism2%:"!cab_dir!" %dismtarget% /Add-Package /packagepath:"%dest%\update.mum"
goto :cumulativelimit
)
if %online%==1 if /i %package%==KB3000850 (
cd /d "!cab_dir!"
%_dism2%:"!cab_dir!" %dismtarget% /Add-Package /packagepath:"%dest%\update.mum"
goto :cumulativelimit
)
goto :eof

:general
if not exist "!repo!\General\*.msu" goto :eof
call :cleaner
echo.
echo ============================================================
echo *** General Updates ***
echo ============================================================
set "cat=General Updates"
cd General\
call :counter
call :cab1
if %_sum% equ 0 goto :eof
call :mum1
if %_sum% equ 0 goto :eof
goto :listdone

:security
if %online%==1 if %allcount% geq %onlinelimit% goto :countlimit
if not exist "!repo!\Security\*.msu" goto :eof
call :cleaner
if %verb%==1 (
echo.
echo ============================================================
echo *** Security Updates ***
echo ============================================================
)
set "cat=Security Updates"
cd Security\
if not exist "!mountdir!\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" if /i "%CEdition%"=="ProfessionalWMC" if exist "ProWMC\*%arch%*.msu" (expand.exe -f:*Windows*.cab ProWMC\*%arch%*.msu .\ %_Null%)
call :counter
call :cab1
if exist "!repo!\Security\*.cab" (del /f /q "!repo!\Security\*.cab" %_Nul1%)
if %_sum% equ 0 goto :eof
call :mum1
if %_sum% equ 0 goto :eof
goto :listdone

:net35
if %online%==1 if %allcount% geq %onlinelimit% goto :countlimit
if not exist "!repo!\Additional\NET35\*.msu" goto :eof
if not exist "!mountdir!\Windows\Microsoft.NET\Framework\v2.0.50727\ngen.exe" goto :eof
call :cleaner
echo.
echo ============================================================
echo *** .NET 3.5 Updates ***
echo ============================================================
set "cat=.NET 3.5 Updates"
cd Additional\NET35\
call :counter
call :cab1
if %_sum% equ 0 goto :eof
call :mum1
if %_sum% equ 0 goto :eof
goto :listdone

:hotfix
if %online%==1 if %allcount% geq %onlinelimit% goto :countlimit
if not exist "!repo!\Hotfix\*.msu" goto :eof
call :cleaner
echo.
echo ============================================================
echo *** Hotfixes ***
echo ============================================================
set "cat=Hotfixes"
cd Hotfix\
call :counter
call :cab1
if %_sum% equ 0 goto :eof
call :mum1
if %_sum% equ 0 goto :eof
goto :listdone

:wusatisfy
if %online%==1 if %allcount% geq %onlinelimit% goto :countlimit
if not exist "!repo!\Additional\WU.Satisfy\*.msu" goto :eof
call :cleaner
echo.
echo ============================================================
echo *** WU Satisfy Updates ***
echo ============================================================
set "cat=WU Satisfy Updates"
set _GDR=1
if /i "%LDRbranch%"=="YES" if exist "!mountdir!\Windows\Microsoft.NET\Framework\v2.0.50727\ngen.exe" (for %%# in (%gdrlist%) do expand.exe -f:*Windows*.cab Additional\NET35\*%%#*%arch%*.msu Additional\WU.Satisfy\ %_Null%)
cd Additional\WU.Satisfy\
if /i "%CEdition%"=="ProfessionalWMC" if exist "ProfessionalWMC\*%arch%*.msu" (expand.exe -f:*Windows*.cab ProfessionalWMC\*%arch%*.msu .\ %_Null%)
call :counter
call :cab1
if exist "!repo!\Additional\WU.Satisfy\*.cab" (del /f /q "!repo!\Additional\WU.Satisfy\*.cab" %_Nul1%)
if %_sum% equ 0 set _GDR=0&goto :eof
call :mum1
set _GDR=0
if %_sum% equ 0 goto :eof
goto :listdone

:windows10
if %online%==1 if %allcount% geq %onlinelimit% goto :countlimit
if not exist "!repo!\Additional\Windows10\*.msu" goto :eof
call :cleaner
echo.
echo ============================================================
echo *** Windows10/Telemetry Updates ***
echo ============================================================
set "cat=Win10/Tel Updates"
cd Additional\Windows10\
call :counter
call :cab1
if %_sum% equ 0 goto :eof
call :mum1
if %_sum% equ 0 goto :eof
goto :listdone

:wmf
if %online%==1 if %allcount% geq %onlinelimit% goto :countlimit
if not exist "!repo!\Additional\WMF\*.msu" goto :eof
if not exist "!mountdir!\Windows\Microsoft.NET\Framework\v4.0.30319\ngen.exe" goto :eof
call :cleaner
echo.
echo ============================================================
echo *** WMF Updates ***
echo ============================================================
set "cat=WMF Updates"
cd Additional\WMF\
call :counter
call :cab1
if %_sum% equ 0 goto :eof
call :mum1
if %_sum% equ 0 goto :eof
goto :listdone

:winpe
if not exist "!repo!\Additional\WinPE\*Windows*%arch%*" goto :eof
call :cleaner
if %verb%==1 (
echo.
echo ============================================================
echo *** WinPE Updates ***
echo ============================================================
)
set "cat=WinPE Updates"
if not exist "!cab_dir!\WinPE\" (
mkdir "!cab_dir!\WinPE"
if exist "Additional\WinPE\*%arch%*.msu" copy /y Additional\WinPE\*%arch%*.msu "!cab_dir!\WinPE\" %_Nul1%
if exist "General\*KB3084905*%arch%*.msu" copy /y General\*KB3084905*%arch%*.msu "!cab_dir!\WinPE\" %_Nul1%
if exist "General\*KB3115224*%arch%*.msu" copy /y General\*KB3115224*%arch%*.msu "!cab_dir!\WinPE\" %_Nul1%
)
if exist "!mountdir!\sources\setup.exe" if exist "Additional\WinPE\*%arch%*.cab" if not exist "!cab_dir!\WinPE\*%arch%*.cab" copy /y Additional\WinPE\*%arch%*.cab "!cab_dir!\WinPE\" %_Nul1%
cd /d "!cab_dir!\WinPE"
call :counter
call :cab1
if %_sum% equ 0 goto :eof
call :mum1
if %_sum% equ 0 goto :eof
goto :listdone

:rsat
if %online%==1 if %allcount% geq %onlinelimit% goto :countlimit
call :cleaner
if exist "!mountdir!\Windows\servicing\packages\*RemoteServerAdministrationTools*.mum" goto :rsatu
if not exist "!repo!\Extra\RSAT\*.msu" goto :eof
echo.
echo ============================================================
echo *** RSAT KB2693643 ***
echo ============================================================
cd Extra\RSAT\
expand.exe -f:*Windows*.cab *%arch%*.msu "!cab_dir!" %_Null%
cd /d "!cab_dir!"
%_dism2%:"!cab_dir!" %dismtarget% /Add-Package /packagepath:.
del /f /q "*KB2693643*.cab"
cd /d "!repo!"

:rsatu
if not exist "!repo!\Extra\RSAT\Updates\*.msu" goto :eof
echo.
echo ============================================================
echo *** RSAT Updates ***
echo ============================================================
set "cat=RSAT Updates"
cd Extra\RSAT\Updates\
call :counter
call :cab1
if %_sum% equ 0 goto :eof
call :mum1
if %_sum% equ 0 goto :eof
goto :listdone

:online
if not exist "!repo!\Additional\Do.Not.Integrate\*.msu" goto :eof
call :cleaner
echo.
echo ============================================================
echo *** Online Updates ***
echo ============================================================
cd Additional\Do.Not.Integrate\
for /f "tokens=* delims=" %%# in ('dir /b /a:-d *%arch%*.msu') do (set "package=%%#"&call :online2)
goto :eof

:online2
for /f "tokens=2 delims=-" %%V in ('echo "%package%"') do set kb=%%V
if exist "!mountdir!\Windows\servicing\packages\package_for_%kb%_rtm*.mum" goto :eof
if %online%==1 (
%package% /quiet /norestart
)
if /i %kb%==KB2990967 if %online%==0 (
reg.exe load HKLM\OFFUSR "!mountdir!\Users\Default\ntuser.dat" %_Nul1%
reg.exe add HKLM\OFFUSR\Software\Microsoft\Skydrive /v EnableTeamTier /t REG_DWORD /d 1 /f %_Nul1%
reg.exe unload HKLM\OFFUSR %_Nul1%
)
expand.exe -f:*Windows*.cab %package% "!cab_dir!" %_Null%
cd /d "!cab_dir!"
%_dism2%:"!cab_dir!" %dismtarget% /Add-Package /packagepath:.
del /f /q "*%kb%*.cab"
cd /d "!repo!\Additional\Do.Not.Integrate"
goto :eof

:enablenet35
if exist "!mountdir!\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" goto :eof
if exist "!mountdir!\Windows\Microsoft.NET\Framework\v2.0.50727\ngen.exe" (echo.&echo .NET 3.5 feature: already enabled&goto :eof)
call :cleaner
if not defined net35source (
for %%# in (D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do if not defined net35source (if exist "%%#:\sources\sxs\msil_microsoft.build.engine*3.5.9600.16384*" set "net35source=%%#:\sources\sxs")
if %dvd%==1 if exist "!target!\sources\sxs\msil_microsoft.build.engine*3.5.9600.16384*" set "net35source=!target!\sources\sxs"
if %wim%==1 if not defined net35source for %%# in ("!target!") do (
  set "_wimpath=%%~dp#"
  if exist "!_wimpath!\sxs\msil_microsoft.build.engine*3.5.9600.16384*" set "net35source=!_wimpath!\sxs"
  )
)
if not defined net35source (echo.&echo .NET 3.5 feature: source folder not defined or detected&goto :eof)
if not exist "!net35source!\msil_microsoft.build.engine*3.5.9600.16384*" (echo.&echo .NET 3.5 feature: source folder not defined or detected&goto :eof)
echo.
echo ============================================================
echo *** .NET 3.5 Feature ***
echo ============================================================
cd /d "!net35source!"
%_dism2%:"!cab_dir!" %dismtarget% /Enable-Feature /FeatureName:NetFx3 /All /LimitAccess /Source:.
cd /d "!repo!"
set _DNF=1
goto :eof

:: ###################################################################

:cab1
if %verb%==1 (
echo.
echo ============================================================
echo Checking Applicable Updates
echo ============================================================
echo.
)
set count=0
if %_cab% neq 0 (set msu=0&for /f "tokens=* delims=" %%# in ('dir /b /a:-d *%arch%*.cab') do (set "package=%%#"&call :cab2))
if %_msu% neq 0 (set msu=1&for /f "tokens=* delims=" %%# in ('dir /b /a:-d *%arch%*.msu') do (set "package=%%#"&call :cab2))
goto :eof

:cab2
if %online%==1 if %count% equ %onlinelimit% goto :eof
for /f "tokens=2 delims=-" %%V in ('echo "%package%"') do set kb=%%V
if /i %kb%==KB917607 (if exist "!mountdir!\Windows\WinSxS\Manifests\*microsoft-windows-winhstb*6.3.9600.20470*.manifest" set /a _sum-=1&set /a _msu-=1&goto :eof)
if /i %kb%==KB2899189 (if exist "!mountdir!\Windows\servicing\packages\*CameraCodec*6.3.9600.16453.mum" set /a _sum-=1&set /a _msu-=1&goto :eof)
if /i %kb%==KB3191564 (if exist "!mountdir!\Windows\servicing\packages\*WinMan-WinIP*7.2.9600.16384.mum" set /a _sum-=1&set /a _msu-=1&goto :eof)
if /i %kb%==KB3049443 (if exist "!mountdir!\Windows\servicing\packages\*WinMan-WinIP*7.2.9600.16384.mum" set /a _sum-=1&set /a _msu-=1&goto :eof)
if /i %kb%==KB3140185 (if not exist "!mountdir!\Windows\servicing\packages\Microsoft-Windows-Anytime-Upgrade-Package*.mum" set /a _sum-=1&set /a _msu-=1&goto :eof)
if /i %kb%==KB2894852 (if not exist "!mountdir!\Windows\Microsoft.NET\Framework\v2.0.50727\ngen.exe" set /a _sum-=1&set /a _msu-=1&goto :eof)
if /i %kb%==KB2973201 (if /i not "%CEdition%"=="ProfessionalWMC" set /a _sum-=1&set /a _msu-=1&goto :eof)
if /i %kb%==KB2978742 (if /i not "%CEdition%"=="ProfessionalWMC" set /a _sum-=1&set /a _msu-=1&goto :eof)
if /i %kb%==KB3179574 (if /i not "%_KB3179574%"=="1" set /a _sum-=1&set /a _msu-=1&goto :eof)
if /i %kb%==KB3172729 (if %winbuild% lss 9600 set /a _sum-=1&set /a _msu-=1&goto :eof)
if /i %kb%==KB4502496 (if %winbuild% lss 9600 set /a _sum-=1&set /a _msu-=1&goto :eof)
if exist "!mountdir!\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" if %winpe% equ 0 (
mkdir "!cab_dir!\check"
if %msu% equ 1 (expand.exe -f:*Windows*.cab "%package%" "!cab_dir!\check" %_Null%) else (copy /y "%package%" "!cab_dir!\check\" %_Nul1%)
expand.exe -f:%sss%_microsoft-windows-rollup-version*.manifest "!cab_dir!\check\*.cab" "!cab_dir!\check" %_Null%
if not exist "!cab_dir!\check\*.manifest" (rd /s /q "!cab_dir!\check\"&set /a _sum-=1&if %msu% equ 1 (set /a _msu-=1&goto :eof) else (set /a _cab-=1&goto :eof))
rd /s /q "!cab_dir!\check\"
)
:: old for above ^
:: expand.exe -f:update.mum "!cab_dir!\check\*.cab" . %_Null%
:: findstr /i /m "Package_for_RollupFix" "update.mum" %_Nul3% || (del /f /q "update.mum"&rd /s /q "!cab_dir!\check\"&set /a _sum-=1&if %msu% equ 1 (set /a _msu-=1&goto :eof) else (set /a _cab-=1&goto :eof))
:: del /f /q "update.mum"
set inver=0
if /i %kb%==%hv_integ_kb% if exist "!mountdir!\Windows\servicing\packages\*Hyper-V-Integration-Services*.mum" (
for /f "tokens=6,7 delims=~." %%i in ('dir /b /a:-d /od "!mountdir!\Windows\servicing\packages\*Hyper-V-Integration-Services*.mum"') do set inver=%%i%%j
if !inver! geq !hv_integ_vr! (set /a _sum-=1&set /a _cab-=1&goto :eof)
)
set "mumcheck=package_for_%kb%_rtm*.mum"
set "mumtest=package_*_for_%kb%~*.mum"
if %_GDR% equ 1 (
set "mumcheck=package_for_%kb%_rtm~*.mum"
set "mumtest=package_*_for_%kb%*.mum"
)
set inver=0
if /i %kb%==KB2976978 if exist "!mountdir!\Windows\servicing\packages\%mumcheck%" (
for /f "tokens=6,7 delims=~." %%i in ('dir /b /a:-d /od "!mountdir!\Windows\servicing\packages\%mumcheck%"') do set inver=%%i%%j
mkdir "!cab_dir!\check"
if %msu% equ 1 (expand.exe -f:*Windows*.cab "%package%" "!cab_dir!\check" %_Null%) else (copy /y "%package%" "!cab_dir!\check\" %_Nul1%)
expand.exe -f:package_for_%kb%_rtm~*.mum "!cab_dir!\check\*.cab" "!cab_dir!\check" %_Null%
for /f "tokens=6,7 delims=~." %%i in ('dir /b /a:-d "!cab_dir!\check\package_for_%kb%_rtm*.mum"') do call set kbver=%%i%%j
rd /s /q "!cab_dir!\check\"
if !inver! geq !kbver! (set /a _sum-=1&if %msu% equ 1 (set /a _msu-=1&goto :eof) else (set /a _cab-=1&goto :eof))
)
if /i not %kb%==KB2976978 (
if exist "!mountdir!\Windows\servicing\packages\%mumcheck%" (set /a _sum-=1&if %msu% equ 1 (set /a _msu-=1&goto :eof) else (set /a _cab-=1&goto :eof))
if exist "!mountdir!\Windows\servicing\packages\%mumtest%" (set /a _sum-=1&if %msu% equ 1 (set /a _msu-=1&goto :eof) else (set /a _cab-=1&goto :eof))
)
set /a count+=1
if %verb%==1 (
echo %count%: %package%
)
if %msu% equ 1 (expand.exe -f:*Windows*.cab "%package%" "!cab_dir!" %_Null%) else (copy /y "%package%" "!cab_dir!\" %_Nul1%)
goto :eof

:mum1
if %verb%==1 (
echo.
echo ============================================================
echo Extracting files from update cabinets ^(.cab^)
echo *** This will require some disk space, please be patient ***
echo ============================================================
echo.
)
set ldr=&set listc=0&set list=1&set AC=100&set count=0
cd /d "!cab_dir!"
for /f "tokens=* delims=" %%# in ('dir /b /a:-d *.cab') do (set "package=%%#"&set "dest=%%~n#"&call :mum2)
goto :eof

:mum2
if %listc% geq %ac% (set /a AC+=100&set /a list+=1&set ldr%list%=%ldr%&set ldr=)
if not exist "%dest%\" mkdir "%dest%"
set /a count+=1
set /a allcount+=1
set /a listc+=1
set ssureq=0.0
set ssuver=9600.16384
for /f "tokens=3,4 delims=." %%i in ('dir /b "!mountdir!\Windows\servicing\Version"') do set "ssuver=%%i.%%j"
expand.exe -f:update.mum "%package%" "%dest%" %_Null%
for /f "tokens=5,6 delims==." %%i in ('findstr /i installerAssembly "%dest%\update.mum" %_Nul6%') do set "ssureq=%%i.%%j
if %ssureq%==0.0 set ssureq=%ssuver%
if %ssuver:~0,4% lss %ssureq:~0,4% goto :E_REQSSU
if %ssuver:~5,5% lss %ssureq:~5,5% goto :E_REQSSU
if not exist "%dest%\*.manifest" (
if %verb%==1 echo %count%/%_sum%: %package%
expand.exe -f:* "%package%" "%dest%" %_Null% || (rmdir /s /q "%dest%\" %_Nul3%&set "ldr=!ldr! /packagepath:%package%"&goto :eof)
)
if exist "%dest%\*cablist.ini" expand.exe -f:* "%dest%\*.cab" "%dest%" %_Null% || (rmdir /s /q "%dest%\" %_Nul3%&set "ldr=!ldr! /packagepath:%package%"&goto :eof)
if exist "%dest%\*cablist.ini" (del /f /q "%dest%\*cablist.ini" %_Nul3%&del /f /q "%dest%\*.cab" %_Nul3%)
if /i not "%LDRbranch%"=="YES" (set "ldr=!ldr! /packagepath:%dest%\update.mum"&goto :eof)
if %_GDR% equ 1 (set "ldr=!ldr! /packagepath:%dest%\update.mum"&goto :eof)
if exist "%dest%\update-bf.mum" (set "ldr=!ldr! /packagepath:%dest%\update-bf.mum") else (set "ldr=!ldr! /packagepath:%dest%\update.mum")
goto :eof

:E_REQSSU
echo %_err%
echo %dest% require SSU version 6.3.%ssureq%
echo.
rmdir /s /q "%dest%\" %_Nul3%
goto :eof

:listdone
if %listc% leq %ac% (set ldr%list%=%ldr%)
set lc=1

:PP
if %lc% gtr %list% (
if /i "%cat%"=="Security Updates" call :diagtrack %_Nul3%
goto :eof
)
call set ldr=%%ldr%lc%%%
set ldr%lc%=
if %verb%==1 (
echo.
echo ============================================================
echo Installing %listc% %cat%, session %lc%/%list%
echo ============================================================
)
%_dism2%:"!cab_dir!" %dismtarget% /Add-Package %ldr%
set /a lc+=1
goto :PP

:counter
set _msu=0
set _cab=0
set _sum=0
if exist "*%arch%*.msu" (for /f "tokens=* delims=" %%# in ('dir /b /a:-d *%arch%*.msu') do (call set /a _msu+=1))
if exist "*%arch%*.cab" (for /f "tokens=* delims=" %%# in ('dir /b /a:-d *%arch%*.cab') do (call set /a _cab+=1))
set /a _sum=%_msu%+%_cab%
goto :eof

:cleaner
cd /d "!repo!"
if %wimfiles% equ 1 (
if exist "!cab_dir!\*.cab" del /f /q "!cab_dir!\*.cab" %_Nul1%
) else (
  if exist "!cab_dir!\" (
  echo.
  echo ============================================================
  echo Removing temporary extracted files...
  echo ============================================================
  rmdir /s /q "!cab_dir!\" %_Nul1%
  )
)
if not exist "!cab_dir!\" mkdir "!cab_dir!"
goto :eof

:: ###################################################################

:diagtrack
if %online%==1 (
set ksub1=SOFTWARE&set ksub2=SYSTEM
) else (
set ksub1=OFFSOFT&set ksub2=OFFSYST
reg.exe load HKLM\!ksub1! "!mountdir!\Windows\System32\config\SOFTWARE"
reg.exe load HKLM\!ksub2! "!mountdir!\Windows\System32\config\SYSTEM"
)
reg.exe add HKLM\%ksub1%\Policies\Microsoft\Windows\Gwx /v DisableGwx /t REG_DWORD /d 1 /f
reg.exe add HKLM\%ksub1%\Policies\Microsoft\Windows\WindowsUpdate /v DisableOSUpgrade /t REG_DWORD /d 1 /f
reg.exe delete HKLM\%ksub1%\Microsoft\Windows\CurrentVersion\WindowsUpdate\OSUpgrade /f
reg.exe add HKLM\%ksub1%\Microsoft\Windows\CurrentVersion\WindowsUpdate\OSUpgrade /v AllowOSUpgrade /t REG_DWORD /d 0 /f
reg.exe delete HKLM\%ksub1%\Policies\Microsoft\Windows\DataCollection /f
reg.exe delete HKLM\%ksub1%\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack /f
reg.exe add HKLM\%ksub1%\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack /v DiagTrackAuthorization /t REG_DWORD /d 0 /f
reg.exe add HKLM\%ksub1%\Microsoft\SQMClient\IE /v CEIPEnable /t REG_DWORD /d 0 /f
reg.exe add HKLM\%ksub1%\Microsoft\SQMClient\IE /v SqmLoggerRunning /t REG_DWORD /d 0 /f
reg.exe add HKLM\%ksub1%\Microsoft\SQMClient\Reliability /v CEIPEnable /t REG_DWORD /d 0 /f
reg.exe add HKLM\%ksub1%\Microsoft\SQMClient\Reliability /v SqmLoggerRunning /t REG_DWORD /d 0 /f
reg.exe add HKLM\%ksub1%\Microsoft\SQMClient\Windows /v CEIPEnable /t REG_DWORD /d 0 /f
reg.exe add HKLM\%ksub1%\Microsoft\SQMClient\Windows /v SqmLoggerRunning /t REG_DWORD /d 0 /f
reg.exe add HKLM\%ksub1%\Microsoft\SQMClient\Windows /v DisableOptinExperience /t REG_DWORD /d 1 /f
reg.exe add HKLM\%ksub2%\ControlSet001\Services\DiagTrack /v Start /t REG_DWORD /d 4 /f
reg.exe delete HKLM\%ksub2%\ControlSet001\Control\WMI\AutoLogger\AutoLogger-Diagtrack-Listener /f
reg.exe delete HKLM\%ksub2%\ControlSet001\Control\WMI\AutoLogger\Diagtrack-Listener /f
rem reg.exe delete HKLM\%ksub2%\ControlSet001\Control\WMI\AutoLogger\SQMLogger /f
icacls "!mountdir!\ProgramData\Microsoft\Diagnosis" /grant:r *S-1-5-32-544:(OI)(CI)(IO)(F) /T /C
del /f /q "!mountdir!\ProgramData\Microsoft\Diagnosis\*.rbs"
del /f /q /s "!mountdir!\ProgramData\Microsoft\Diagnosis\ETLLogs\*"
if %online%==0 (
reg.exe unload HKLM\%ksub1%
reg.exe unload HKLM\%ksub2%
)

if exist "!mountdir!\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" goto :eof
if exist "!mountdir!\Users\Public\Desktop\RunOnce_W10_Telemetry_Tasks.cmd" goto :eof

if %online%==1 (
schtasks /query /tn "\Microsoft\Windows\Application Experience\ProgramDataUpdater" || goto :eof
)
if %online%==1 (
set ksub1=SOFTWARE&set ksub2=SYSTEM
) else (
set ksub1=OFFSOFT&set ksub2=OFFSYST
reg.exe load HKLM\!ksub1! "!mountdir!\Windows\System32\config\SOFTWARE"
)
reg.exe delete "HKLM\%ksub1%\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Appraiser" /f
reg.exe add "HKLM\%ksub1%\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Appraiser" /v HaveUploadedForTarget /t REG_DWORD /d 1 /f
reg.exe add "HKLM\%ksub1%\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\AIT" /v AITEnable /t REG_DWORD /d 0 /f
reg.exe delete "HKLM\%ksub1%\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\ClientTelemetry" /f
reg.exe add "HKLM\%ksub1%\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\ClientTelemetry" /v DontRetryOnError /t REG_DWORD /d 1 /f
reg.exe add "HKLM\%ksub1%\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\ClientTelemetry" /v IsCensusDisabled /t REG_DWORD /d 1 /f
reg.exe add "HKLM\%ksub1%\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\ClientTelemetry" /v TaskEnableRun /t REG_DWORD /d 1 /f
reg.exe delete "HKLM\%ksub1%\Microsoft\Windows NT\CurrentVersion\AppCompatFlags" /v UpgradeEligible /f
reg.exe delete "HKLM\%ksub1%\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\TelemetryController" /f
reg.exe delete HKLM\%ksub1%\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack /f
reg.exe add HKLM\%ksub1%\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack /v DiagTrackAuthorization /t REG_DWORD /d 0 /f
reg.exe add HKLM\%ksub1%\Microsoft\Windows\CurrentVersion\EOSNotify /f /v DiscontinueEOS /t REG_DWORD /d 1

set "T_USR=HKCU\Software\Microsoft\Windows\CurrentVersion"
set "T_US2=HKLM\OFFUSR\Software\Microsoft\Windows\CurrentVersion"
set "T_Win=Microsoft\Windows"
set "T_App=Microsoft\Windows\Application Experience"
set "T_CEIP=Microsoft\Windows\Customer Experience Improvement Program"
(
echo @echo off
echo reg.exe query "HKU\S-1-5-19" 1^>nul 2^>nul ^|^| ^(echo Run the script as administrator^&pause^&exit^)
echo reg.exe add %T_USR%\EOSNotify /f /v RemindMeAfterEndOfSupport /t REG_DWORD /d 1
echo reg.exe add %T_USR%\EOSNotify /f /v DiscontinueEOS /t REG_DWORD /d 1
echo reg.exe add %T_USR%\EOSNotify /f /v TimestampOverride /t REG_DWORD /d 1
echo reg.exe add %T_USR%\EOSNotify /f /v LastRunTimestamp /t REG_QWORD /d 0x0
echo reg.exe delete HKLM\SYSTEM\CurrentControlSet\Control\WMI\AutoLogger\AutoLogger-Diagtrack-Listener /f
echo reg.exe delete HKLM\SYSTEM\CurrentControlSet\Control\WMI\AutoLogger\Diagtrack-Listener /f
echo rem reg.exe delete HKLM\SYSTEM\CurrentControlSet\Control\WMI\AutoLogger\SQMLogger /f
echo icacls "%%ProgramData%%\Microsoft\Diagnosis" /grant:r *S-1-5-32-544:^(OI^)^(CI^)^(IO^)^(F^) /T /C
echo del /f /q "%%ProgramData%%\Microsoft\Diagnosis\*.rbs"
echo del /f /q /s "%%ProgramData%%\Microsoft\Diagnosis\ETLLogs\*"
echo sc.exe config DiagTrack start= disabled
echo sc.exe stop DiagTrack
echo schtasks.exe /Change /DISABLE /TN "%T_Win%\Setup\EOSNotify"
echo schtasks.exe /Change /DISABLE /TN "%T_Win%\Setup\EOSNotify2"
echo schtasks.exe /Change /DISABLE /TN "%T_Win%\PerfTrack\BackgroundConfigSurveyor"
echo schtasks.exe /Change /DISABLE /TN "%T_Win%\SetupSQMTask"
echo schtasks.exe /Change /DISABLE /TN "%T_CEIP%\BthSQM"
echo schtasks.exe /Change /DISABLE /TN "%T_CEIP%\Consolidator"
echo schtasks.exe /Change /DISABLE /TN "%T_CEIP%\KernelCeipTask"
echo schtasks.exe /Change /DISABLE /TN "%T_CEIP%\TelTask"
echo schtasks.exe /Change /DISABLE /TN "%T_CEIP%\UsbCeip"
echo schtasks.exe /Change /DISABLE /TN "%T_App%\AitAgent"
echo schtasks.exe /Change /DISABLE /TN "%T_App%\Microsoft Compatibility Appraiser"
echo schtasks.exe /Change /DISABLE /TN "%T_App%\ProgramDataUpdater"
echo schtasks.exe /Delete /TN "%T_Win%\Setup\EOSNotify" /F
echo schtasks.exe /Delete /TN "%T_Win%\Setup\EOSNotify2" /F
echo schtasks.exe /Delete /TN "%T_Win%\PerfTrack\BackgroundConfigSurveyor" /F
echo schtasks.exe /Delete /TN "%T_Win%\SetupSQMTask" /F
echo schtasks.exe /Delete /TN "%T_CEIP%\BthSQM" /F
echo schtasks.exe /Delete /TN "%T_CEIP%\Consolidator" /F
echo schtasks.exe /Delete /TN "%T_CEIP%\KernelCeipTask" /F
echo schtasks.exe /Delete /TN "%T_CEIP%\TelTask" /F
echo schtasks.exe /Delete /TN "%T_CEIP%\UsbCeip" /F
echo schtasks.exe /Delete /TN "%T_App%\AitAgent" /F
echo schtasks.exe /Delete /TN "%T_App%\Microsoft Compatibility Appraiser" /F
echo schtasks.exe /Delete /TN "%T_App%\ProgramDataUpdater" /F
echo ^(goto^) 2^>nul ^&del /f /q %%0 ^&exit /b
)>"W10Tel.cmd"

if %online%==1 (
if exist "%SystemRoot%\winsxs\pending.xml" (move /y "W10Tel.cmd" "!mountdir!\Users\Public\Desktop\RunOnce_W10_Telemetry_Tasks.cmd") else (cmd.exe /c "W10Tel.cmd")
) else (
move /y "W10Tel.cmd" "!mountdir!\Users\Public\Desktop\RunOnce_W10_Telemetry_Tasks.cmd"
reg.exe unload HKLM\%ksub1%
)

if %online%==1 (
reg.exe add %T_USR%\EOSNotify /f /v RemindMeAfterEndOfSupport /t REG_DWORD /d 1
reg.exe add %T_USR%\EOSNotify /f /v DiscontinueEOS /t REG_DWORD /d 1
reg.exe add %T_USR%\EOSNotify /f /v TimestampOverride /t REG_DWORD /d 1
reg.exe add %T_USR%\EOSNotify /f /v LastRunTimestamp /t REG_QWORD /d 0x0
) else (
reg.exe load HKLM\OFFUSR "!mountdir!\Users\Default\ntuser.dat"
reg.exe add %T_US2%\EOSNotify /f /v RemindMeAfterEndOfSupport /t REG_DWORD /d 1
reg.exe add %T_US2%\EOSNotify /f /v DiscontinueEOS /t REG_DWORD /d 1
reg.exe add %T_US2%\EOSNotify /f /v TimestampOverride /t REG_DWORD /d 1
reg.exe add %T_US2%\EOSNotify /f /v LastRunTimestamp /t REG_QWORD /d 0x0
reg.exe unload HKLM\OFFUSR
)
goto :eof

:ESUadd
if not exist "!Cab_Dir!\" mkdir "!Cab_Dir!"
set "_EsuFnd=microsoft-w..-foundation_%_Pkt%_6.3.9600.16384_d1250fcb45c3a9e5"
if /i "%xBT%"=="x86" (
set "_EsuFnd=microsoft-w..-foundation_%_Pkt%_6.3.9600.16384_750674478d6638af"
)
if not exist "!Cab_Dir!\%_EsuCom%.manifest" (
(echo ^<?xml version="1.0" encoding="UTF-8"?^>
echo ^<assembly xmlns="urn:schemas-microsoft-com:asm.v3" manifestVersion="1.0" copyright="Copyright (c) Microsoft Corporation. All Rights Reserved."^>
echo   ^<assemblyIdentity name="Microsoft-Windows-SLC-Component-ExtendedSecurityUpdatesAI" version="%_OurVer%" processorArchitecture="%xBT%" language="neutral" buildType="release" publicKeyToken="%_Pkt%" versionScope="nonSxS" /^>
echo ^</assembly^>)>"!Cab_Dir!\%_EsuCom%.manifest"
)
icacls "!mountdir!\Windows\WinSxS\Manifests" /save "!Cab_Dir!\acl.txt"
takeown /f "!mountdir!\Windows\WinSxS\Manifests" /A
icacls "!mountdir!\Windows\WinSxS\Manifests" /grant:r "*S-1-5-32-544:(OI)(CI)(F)"
copy /y "!Cab_Dir!\%_EsuCom%.manifest" "!mountdir!\Windows\WinSxS\Manifests\"
icacls "!mountdir!\Windows\WinSxS\Manifests" /setowner *S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464
icacls "!mountdir!\Windows\WinSxS" /restore "!Cab_Dir!\acl.txt"
del /f /q "!Cab_Dir!\acl.txt"

if %online%==0 reg load HKLM\%SOFTWARE% "!mountdir!\Windows\System32\Config\SOFTWARE"
reg query HKLM\%COMPONENTS% 1>nul 2>nul || reg load HKLM\%COMPONENTS% "!mountdir!\Windows\System32\Config\COMPONENTS"
reg delete "%_Cmp%\%_EsuCom%" /f
reg add "%_Cmp%\%_EsuCom%" /f /v "c^!%_EsuFnd%" /t REG_BINARY /d ""
reg add "%_Cmp%\%_EsuCom%" /f /v identity /t REG_BINARY /d "%_EsuIdn%"
reg add "%_Cmp%\%_EsuCom%" /f /v S256H /t REG_BINARY /d "%_EsuHsh%"
reg add "%_EsuKey%" /f /ve /d %_OurVer:~0,3%
reg add "%_EsuKey%\%_OurVer:~0,3%" /f /ve /d %_OurVer%
reg add "%_EsuKey%\%_OurVer:~0,3%" /f /v %_OurVer% /t REG_BINARY /d 01
for /f "tokens=* delims=" %%# in ('reg query HKLM\%COMPONENTS%\DerivedData\VersionedIndex 2^>nul ^| findstr /i VersionedIndex') do reg delete "%%#" /f
if %online%==0 (
reg unload HKLM\%COMPONENTS%
reg unload HKLM\%SOFTWARE%
)
exit /b

:stacklimit
echo ============================================================
echo *** ATTENTION ***
echo ============================================================
echo.
echo Installing servicing stack update
echo require no pending update operation.
echo.
echo please restart the system, then run the script again.
echo.
echo Press 9 to exit.
if %_Debug% neq 0 goto :EndDebug
choice /c 9 /n
if errorlevel 1 (exit) else (rem.)

:countlimit
call :cleaner
echo ============================================================
echo *** ATTENTION ***
echo ============================================================
echo.
echo %onlinelimit% or more updates have been installed
echo installing further more will make the process extremely slow.
echo.
echo please restart the system, then run the script again.
echo.
echo Press 9 to exit.
if %_Debug% neq 0 goto :EndDebug
choice /c 9 /n
if errorlevel 1 (exit) else (rem.)

:cumulativelimit
call :cleaner
echo ============================================================
echo *** ATTENTION ***
echo ============================================================
echo.
echo Installing cumulative update %package%
echo require a system restart to complete.
echo.
echo please restart the system, then run the script again.
echo.
echo Press 9 to exit.
if %_Debug% neq 0 goto :EndDebug
choice /c 9 /n
if errorlevel 1 (exit) else (rem.)

:: ###################################################################

:domount
set "_wimfile=%~1"
if %wim%==1 set "_wimpath=!targetpath!"
if %dvd%==1 set "_wimpath=!target!"
if exist "!mountdir!\" rmdir /s /q "!mountdir!\" %_Nul1%
if not exist "!mountdir!\" mkdir "!mountdir!"
if not exist "!cab_dir!\" mkdir "!cab_dir!"
for %%# in (%indices%) do (set "_inx=%%#"&call :dowork)
cd /d "!_work!"
if %keep%==0 if %wim2esd%==1 if %dvd%==1 if /i "%_wimfile%"=="sources\install.wim" goto :eof
echo.
echo ============================================================
echo Rebuilding %_wimfile% ...
echo ============================================================
cd /d "!_wimpath!"
if %keep%==1 (
for %%# in (%indices%) do %_dism2%:"!cab_dir!" /Export-Image /SourceImageFile:%_wimfile% /SourceIndex:%%# /DestinationImageFile:temp.wim
) else (
for /L %%# in (1,1,%imgcount%) do %_dism2%:"!cab_dir!" /Export-Image /SourceImageFile:%_wimfile% /SourceIndex:%%# /DestinationImageFile:temp.wim
)
if %errorlevel% equ 0 (move /y temp.wim %_wimfile% %_Nul1%) else (del /f /q temp.wim %_Nul3%)
cd /d "!_work!"
goto :eof

:dowork
echo.
echo ============================================================
echo Mounting %_wimfile% - index %_inx%/%imgcount%
echo ============================================================
cd /d "!_wimpath!"
%_dism2%:"!cab_dir!" /Mount-Wim /Wimfile:%_wimfile% /Index:%_inx% /MountDir:"!mountdir!"
if !errorlevel! neq 0 goto :E_MOUNT
cd /d "!_work!"
call :doupdate
call :cleanup
if %dvd%==1 (
  if not defined isover if exist "!mountdir!\Windows\WinSxS\Manifests\%sss%_microsoft-windows-rollup-version*.manifest" for /f "tokens=6,7 delims=_." %%i in ('dir /b /a:-d /od "!mountdir!\Windows\WinSxS\Manifests\%sss%_microsoft-windows-rollup-version*.manifest"') do (set isover=%%i.%%j&set isomin=%%j)
  if not defined isolab if not exist "!mountdir!\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" call :legacyLab
  if not defined isodate if exist "!mountdir!\Windows\Servicing\Packages\Package_for_RollupFix*.mum" (
  if not exist "%SystemRoot%\temp\" mkdir "%SystemRoot%\temp" %_Nul3%
  for /f %%# in ('dir /b /a:-d /od "!mountdir!\Windows\Servicing\Packages\Package_for_RollupFix*.mum"') do copy /y "!mountdir!\Windows\Servicing\Packages\%%#" %SystemRoot%\temp\update.mum %_Nul1%
  call :datemum isodate isotime
  )
  if exist "!mountdir!\Windows\Servicing\Packages\Microsoft-Windows-Server*Edition~*.mum" set _SrvEdt=1
  if exist "!mountdir!\sources\setup.exe" call :boots
)
if %wim%==1 if exist "!_wimpath!\setup.exe" (
  if exist "!mountdir!\sources\setup.exe" copy /y "!mountdir!\sources\setup.exe" "!_wimpath!" %_Nul3%
)
if exist "!mountdir!\Windows\System32\Recovery\winre.wim" attrib -S -H -I "!mountdir!\Windows\System32\Recovery\winre.wim" %_Nul3%
if %winre%==1 if exist "!mountdir!\Windows\System32\Recovery\winre.wim" if not exist "!_work!\winre.wim" call :winre
if exist "!mountdir!\Windows\System32\Recovery\winre.wim" if exist "!_work!\winre.wim" (
echo.
echo ============================================================
echo Adding updated winre.wim
echo ============================================================
echo.
copy /y "!_work!\winre.wim" "!mountdir!\Windows\System32\Recovery\"
)
echo.
echo ============================================================
echo Unmounting %_wimfile% - index %_inx%/%imgcount%
echo ============================================================
%_dism2%:"!cab_dir!" /Unmount-Wim /MountDir:"!mountdir!" /Commit
if !errorlevel! neq 0 goto :E_MOUNT
goto :eof

:datemum
set "mumfile=%SystemRoot%\temp\update.mum"
set "chkfile=!mumfile:\=\\!"
if %_cwmi% equ 1 for /f "tokens=2 delims==" %%# in ('wmic datafile where "name='!chkfile!'" get LastModified /value') do set "mumdate=%%#"
if %_cwmi% equ 0 for /f %%# in ('%_psc% "([WMI]'CIM_DataFile.Name=''!chkfile!''').LastModified"') do set "mumdate=%%#"
del /f /q %SystemRoot%\temp\*.mum
set "%1=!mumdate:~2,2!!mumdate:~4,2!!mumdate:~6,2!-!mumdate:~8,4!"
set "%2=!mumdate:~4,2!/!mumdate:~6,2!/!mumdate:~0,4!,!mumdate:~8,2!:!mumdate:~10,2!:!mumdate:~12,2!"
goto :eof

:legacyLab
reg.exe load HKLM\uiSOFTWARE "!mountdir!\Windows\system32\config\SOFTWARE" %_Nul1%
for /f "skip=2 tokens=3-7 delims=. " %%i in ('"reg.exe query "HKLM\uiSOFTWARE\Microsoft\Windows NT\CurrentVersion" /v BuildLabEx" %_Nul6%') do (set regver=%%i.%%j&set regmin=%%j&set regdate=%%m&set reglab=%%l)
reg.exe unload HKLM\uiSOFTWARE %_Nul1%
for /f "tokens=3-6 delims=.() " %%i in ('%_psc% "(gi '!mountdir!\Windows\system32\ntoskrnl.exe').VersionInfo.FileVersion" %_Nul6%') do (set ntkver=%%i.%%j&set ntkmin=%%j&set ntkdate=%%l&set isolab=%%k)
goto :eof

:boots
xcopy /CDRY "!mountdir!\sources" "!target!\sources\" %_Nul3%
del /f /q "!target!\sources\background.bmp" %_Nul3%
del /f /q "!target!\sources\xmllite.dll" %_Nul3%
del /f /q "!target!\efi\microsoft\boot\*noprompt.*" %_Nul3%
rem copy /y "!mountdir!\Windows\Boot\DVD\EFI\en-US\efisys.bin" "!target!\efi\microsoft\boot\" %_Nul1%
copy /y "!mountdir!\Windows\Boot\PCAT\bootmgr" "!target!\" %_Nul1%
copy /y "!mountdir!\Windows\Boot\PCAT\memtest.exe" "!target!\boot\" %_Nul1%
copy /y "!mountdir!\Windows\Boot\EFI\memtest.efi" "!target!\efi\microsoft\boot\" %_Nul1%
copy /y "!mountdir!\Windows\Boot\EFI\bootmgfw.efi" "!target!\efi\boot\%efifile%" %_Nul1%
copy /y "!mountdir!\Windows\Boot\EFI\bootmgr.efi" "!target!\" %_Nul1%
if exist "!target!\setup.exe" copy /y "!mountdir!\setup.exe" "!target!\" %_Nul1%
goto :eof

:winre
  echo.
  echo ============================================================
  echo Updating winre.wim
  echo ============================================================
  if exist "!winremount!\" rmdir /s /q "!winremount!\" %_Nul1%
  if not exist "!winremount!\" mkdir "!winremount!"
  copy /y "!mountdir!\Windows\System32\Recovery\winre.wim" "!_work!\winre.wim" %_Nul1%
  cd /d "!_work!"
  %_dism2%:"!cab_dir!" /Mount-Wim /Wimfile:winre.wim /Index:1 /MountDir:"!winremount!"
  if %errorlevel% neq 0 goto :E_MOUNT
  cd /d "!cab_dir!"
  call :doupdate winre
  %_dism2%:"!cab_dir!" %dismtarget% /Cleanup-Image /StartComponentCleanup /ResetBase
  call :cleanmanual
  %_dism2%:"!cab_dir!" /Unmount-Wim /MountDir:"!winremount!" /Commit
  if %errorlevel% neq 0 goto :E_MOUNT
  cd /d "!_work!"
  %_dism2%:"!cab_dir!" /Export-Image /SourceImageFile:winre.wim /SourceIndex:1 /DestinationImageFile:temp.wim
  move /y temp.wim winre.wim %_Nul1%
  cd /d "!cab_dir!"
  set "mountdir=!mountdib!"
  set dismtarget=/image:"!mountdib!"
goto :eof

:cleanup
if exist "!mountdir!\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" (
echo.
echo ============================================================
echo Resetting WinPE image base
echo ============================================================
%_dism2%:"!cab_dir!" %dismtarget% /Cleanup-Image /StartComponentCleanup /ResetBase
call :cleanmanual
goto :eof
)
if %cleanup%==0 call :cleanmanual&goto :eof
if exist "!mountdir!\Windows\WinSxS\pending.xml" (
if %online%==1 call :onlinepending&goto :eof
call :cleanmanual&goto :eof
)
if %resetbase%==0 (
echo.
echo ============================================================
echo Cleaning up OS image
echo ============================================================
%_dism2%:"!cab_dir!" %dismtarget% /Cleanup-Image /StartComponentCleanup
) else (
echo.
echo ============================================================
echo Resetting OS image base
echo ============================================================
%_dism2%:"!cab_dir!" %dismtarget% /Cleanup-Image /StartComponentCleanup /ResetBase
)
call :cleanmanual
goto :eof

:cleanmanual
if %online%==1 goto :eof
if exist "!mountdir!\Windows\WinSxS\ManifestCache\*.bin" (
takeown /f "!mountdir!\Windows\WinSxS\ManifestCache\*.bin" /A %_Nul3%
icacls "!mountdir!\Windows\WinSxS\ManifestCache\*.bin" /grant *S-1-5-32-544:F %_Nul3%
del /f /q "!mountdir!\Windows\WinSxS\ManifestCache\*.bin" %_Nul3%
)
if exist "!mountdir!\Windows\WinSxS\Temp\PendingDeletes\*" (
takeown /f "!mountdir!\Windows\WinSxS\Temp\PendingDeletes\*" /A %_Null%
icacls "!mountdir!\Windows\WinSxS\Temp\PendingDeletes\*" /grant *S-1-5-32-544:F %_Null%
del /f /q "!mountdir!\Windows\WinSxS\Temp\PendingDeletes\*" %_Nul3%
)
if exist "!mountdir!\Windows\WinSxS\Temp\TransformerRollbackData\*" (
takeown /f "!mountdir!\Windows\WinSxS\Temp\TransformerRollbackData\*" /R /A %_Null%
icacls "!mountdir!\Windows\WinSxS\Temp\TransformerRollbackData\*" /grant *S-1-5-32-544:F /T %_Null%
del /s /f /q "!mountdir!\Windows\WinSxS\Temp\TransformerRollbackData\*" %_Null%
)
if exist "!mountdir!\Windows\inf\*.log" (
del /f /q "!mountdir!\Windows\inf\*.log" %_Nul3%
)
for /f "tokens=* delims=" %%# in ('dir /b /ad "!mountdir!\Windows\CbsTemp\" %_Nul6%') do rmdir /s /q "!mountdir!\Windows\CbsTemp\%%#\" %_Nul3%
del /s /f /q "!mountdir!\Windows\CbsTemp\*" %_Nul3%
goto :eof

:onlinepending
if %resetbase%==0 (set rValue=W81UIclean) else (set rValue=W81UIrebase)
reg.exe add %_SbS% /v !rValue! /t REG_DWORD /d 1 /f %_Nul1%
(
echo @echo off
echo reg.exe query "HKU\S-1-5-19" 1^>nul 2^>nul ^|^| ^(echo Run the script as administrator^&pause^&exit^)
echo if exist "%%SystemRoot%%\winsxs\pending.xml" ^(echo Restart the system first^&pause^&exit^)
echo set "_sbs=%_SbS%"
echo set resetbase=%resetbase%
echo net stop trustedinstaller 1^>nul 2^>nul
echo net stop wuauserv 1^>nul 2^>nul
echo del /f /q %%SystemRoot%%\Logs\CBS\* 2^>nul
echo reg.exe delete %%_sbs%% /v W81UIclean /f 1^>nul 2^>nul
echo reg.exe delete %%_sbs%% /v W81UIrebase /f 1^>nul 2^>nul
echo if %%resetbase%%==0 ^(
echo echo.
echo echo ============================================================
echo echo Cleaning up OS image...
echo echo ============================================================
echo dism.exe /Online /Cleanup-Image /StartComponentCleanup
echo ^) else ^(
echo echo.
echo echo ============================================================
echo echo Resetting OS image base...
echo echo ============================================================
echo dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase
echo ^)
echo ^(goto^) 2^>nul ^&del /f /q %%0 ^&exit /b
)>"W81Cln.cmd"
move /y "W81Cln.cmd" "!_dsk!\RunOnce_AfterRestart_DismCleanup.cmd"
goto :eof

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
cd /d "!_work!"
dism.exe /Unmount-Wim /MountDir:"!mountdir!" /Discard
dism.exe /Unmount-Wim /MountDir:"!winremount!" /Discard %_Nul3%
dism.exe /Cleanup-Mountpoints %_Nul3%
dism.exe /Cleanup-Wim %_Nul3%
if %wimfiles% equ 1 (if exist "!mountdir!\" if not exist "!mountdir!\Windows\" rmdir /s /q "!mountdir!\" %_Nul3%)
if exist "!winremount!\" if not exist "!winremount!\Windows\" rmdir /s /q "!winremount!\" %_Nul3%
if exist "!cab_dir!\" (
echo.
echo ============================================================
echo Removing temporary extracted files...
echo ============================================================
rmdir /s /q "!cab_dir!\" %_Nul1%
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
echo WMIC or Windows PowerShell is required for this script to work.
goto :E_Exit

:checkadk
set regKeyPathFound=1
set wowRegKeyPathFound=1
reg.exe query "HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots" /v KitsRoot81 %_Nul3% || set wowRegKeyPathFound=0
reg.exe query "HKLM\Software\Microsoft\Windows Kits\Installed Roots" /v KitsRoot81 %_Nul3% || set regKeyPathFound=0
if %wowRegKeyPathFound% equ 0 (
  if %regKeyPathFound% equ 0 (
    goto :check10adk
  ) else (
    set regKeyPath=HKLM\Software\Microsoft\Windows Kits\Installed Roots
  )
) else (
    set regKeyPath=HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots
)
for /f "skip=2 tokens=2*" %%i in ('reg.exe query "%regKeyPath%" /v KitsRoot81') do set "KitsRoot=%%j"
set "DandIRoot=%KitsRoot%Assessment and Deployment Kit\Deployment Tools"
if exist "%DandIRoot%\%xOS%\Oscdimg\oscdimg.exe" (
set "_oscdimg=%DandIRoot%\%xOS%\Oscdimg\oscdimg.exe"
)
if exist "%DandIRoot%\%xOS%\DISM\dism.exe" (
set _ADK=1
if %winbuild% lss 10240 set "showdism=Windows 8.1 ADK"
if %winbuild% lss 10240 set "Path=%DandIRoot%\%xOS%\DISM;%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
) else (
goto :check10adk
)
goto :mainmenu

:check10adk
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
if exist "%DandIRoot%\%xOS%\Oscdimg\oscdimg.exe" (
set "_oscdimg=%DandIRoot%\%xOS%\Oscdimg\oscdimg.exe"
)
if exist "%DandIRoot%\%xOS%\DISM\dism.exe" (
set _ADK=1
set "showdism=Windows NT 10.0 ADK"
set "Path=%DandIRoot%\%xOS%\DISM;%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
set "dsv=%DandIRoot%\%xOS%\DISM\dism.exe"
set "dsv=!dsv:\=\\!"
call :DismVer
)
goto :mainmenu

:DismVer
set "dsmver=9600"
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
if %_blue% equ 1 echo - Current OS / Enter %SystemDrive%
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
goto :checktarget

:repomenu
@cls
set _pp=
echo ============================================================
echo Enter the location of WHD parent "Updates" folder
echo.
echo or just press 'Enter' to return to options menu
echo ============================================================
echo.
set /p _pp=
if not defined _pp goto :mainmenu
set "_pp=%_pp:"=%"
if "%_pp:~-1%"=="\" set "_pp=!_pp:~0,-1!"
if not exist "!_pp!\Windows8.1-*" (echo.&echo ERROR: Specified location is not valid&pause&goto :repomenu)
set "repo=!_pp!"
goto :mainmenu

:dismmenu
@cls
set _pp=
echo.
echo If current OS is lower than Windows 8.1, and Windows ADK is not detected
echo you must install it, or specify a manual Windows 8.1 dism.exe for integration
echo you can select dism.exe located in Windows 8.1 distribution "sources" folder
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
if %dsmver% lss 9600 (echo.&echo ERROR: DISM version is lower than 6.3.9600&pause&goto :dismmenu)
set "dismroot=%_pp%"
set "showdism=%_pp%"
set _dism2="%_pp%" /NoRestart /ScratchDir
set _ADK=1
goto :mainmenu

:extractmenu
@cls
set _pp=
echo ============================================================
echo Enter the directory path for extracting updates
echo make sure the drive has enough free space ^(at least 15 GB^)
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
set "cab_dir=!_pp!_%random%"
goto :mainmenu

:mountmenu
@cls
set _pp=
echo ============================================================
echo Enter the directory path for mounting install.wim
echo make sure the drive has enough free space ^(at least 15 GB^)
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

:countmenu
@cls
set _pp=
echo ============================================================
echo Enter the updates count limit for online installation
echo.
echo or just press 'Enter' to return to options menu
echo ============================================================
echo.
set /p _pp=
if not defined _pp goto :mainmenu
set onlinelimit=%_pp%
goto :mainmenu

:mainmenu
if %autostart%==1 goto :mainboard
@cls
echo ==================================================================
if /i "!target!"=="%SystemDrive%" (
if %_blue% neq 1 (set "target="&echo [1] Select offline target) else (echo [1] Target ^(%arch%^): Current Online OS)
) else (
if /i "!target!"=="" (echo [1] Select offline target) else (echo [1] Target ^(%arch%^): "!target!")
)
echo.
if "!repo!"=="" (echo [2] Select updates location) else (echo [2] WHD Repo: "!repo!")
echo.
echo [3] LDR branch: %LDRbranch%     [4] Hotfixes: %Hotfix%     [5] WU Satisfy: %WUSatisfy%
echo [6] Windows10 : %Windows10%     [7] WMF     : %WMF%     [8] RSAT      : %RSAT%
echo.
if %net35%==1 (echo [N] Enable .NET 3.5: YES) else (echo [N] Enable .NET 3.5: NO)
if %cleanup%==0 (
echo [C] Cleanup System Image: NO
) else (
if %resetbase%==0 (echo [C] Cleanup System Image: YES                 [T] Reset Base: NO) else (echo [C] Cleanup System Image: YES                 [T] Reset Base: YES)
)
echo.
if /i "!target!"=="%SystemDrive%" (
echo [L] Online installation limit: %onlinelimit% updates
) else (
if %winbuild% lss 9600 (if %_ADK% equ 0 (echo [D] Select Windows 8.1 dism.exe) else (echo [D] DISM: "!showdism!")) else (echo [D] DISM: "!showdism!")
)
if %wimfiles% equ 1 (
if /i "%targetname%"=="install.wim" (echo.&if %winre%==1 (echo [U] Update WinRE.wim: YES) else (echo [U] Update WinRE.wim: NO))
if %imgcount% gtr 1 (
echo.
if "%indices%"=="*" echo [I] %targetname% selected indexes: ALL ^(%imgcount%^)
if not "%indices%"=="*" (if %keep%==1 (echo [I] %targetname% selected indexes: %indices% / [K] Keep indexes: Selected) else (if %keep%==0 echo [I] %targetname% selected indexes: %indices% / [K] Keep indexes: ALL))
)
echo.
echo [M] Mount Directory: "!mountdir!"
)
echo.
echo [E] Extraction Directory: "!cab_dir!"
echo.
echo ==================================================================
choice /c 1234567890DELIKMNUCT /n /m "Change a menu option, press 0 to start the process, or 9 to exit: "
if errorlevel 20 (if %resetbase%==1 (set resetbase=0) else (set resetbase=1))&goto :mainmenu
if errorlevel 19 (if %cleanup%==1 (set cleanup=0) else (set cleanup=1))&goto :mainmenu
if errorlevel 18 (if %wimfiles% equ 1 (if %winre%==1 (set winre=0) else (set winre=1)))&goto :mainmenu
if errorlevel 17 (if %net35%==1 (set net35=0) else (set net35=1))&goto :mainmenu
if errorlevel 16 (if %wimfiles% equ 1 (goto :mountmenu))&goto :mainmenu
if errorlevel 15 (if %wimfiles% equ 1 if %imgcount% gtr 1 (if %keep%==1 (set keep=0) else (set keep=1)))&goto :mainmenu
if errorlevel 14 (if %wimfiles% equ 1 if %imgcount% gtr 1 (goto :indexmenu))&goto :mainmenu
if errorlevel 13 goto :countmenu
if errorlevel 12 goto :extractmenu
if errorlevel 11 goto :dismmenu
if errorlevel 10 goto :mainboard
if errorlevel 9 goto :eof
if errorlevel 8 (if /i "%RSAT%"=="YES" (set "RSAT=NO ") else (set RSAT=YES))&goto :mainmenu
if errorlevel 7 (if /i "%WMF%"=="YES" (set "WMF=NO ") else (set WMF=YES))&goto :mainmenu
if errorlevel 6 (if /i "%Windows10%"=="YES" (set "Windows10=NO ") else (set Windows10=YES))&goto :mainmenu
if errorlevel 5 (if /i "%WUSatisfy%"=="YES" (set "WUSatisfy=NO ") else (set WUSatisfy=YES))&goto :mainmenu
if errorlevel 4 (if /i "%Hotfix%"=="YES" (set "Hotfix=NO ") else (set Hotfix=YES))&goto :mainmenu
if errorlevel 3 (if /i "%LDRbranch%"=="YES" (set "LDRbranch=NO ") else (set LDRbranch=YES))&goto :mainmenu
if errorlevel 2 goto :repomenu
if errorlevel 1 goto :targetmenu
goto :mainmenu

:ISO
if not exist "!_oscdimg!" if not exist "!_work!\oscdimg.exe" if not exist "!_work!\cdimage.exe" goto :eof
if "!isodir!"=="" set "isodir=!_work!"
call :DATEISO
if %_cwmi% equ 1 for /f "tokens=2 delims==." %%# in ('wmic os get localdatetime /value') do set "_date=%%#"
if %_cwmi% equ 0 for /f "tokens=1 delims=." %%# in ('%_psc% "([WMI]'Win32_OperatingSystem=@').LocalDateTime"') do set "_date=%%#"
if not defined isodate set "isodate=%_date:~2,6%-%_date:~8,4%"
for %%# in (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do (
set isolab=!isolab:%%#=%%#!
)
set _label=%isover%.%isodate%.%isolab%
if %_SrvEdt% equ 1 (set _label=%_label%_SERVER) else (set _label=%_label%_CLIENT)
if /i %arch%==x86 set archl=X86
if /i %arch%==x64 set archl=X64
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
if exist "!_oscdimg!" (set _ff="!_oscdimg!") else if exist "!_work!\oscdimg.exe" (set _ff="!_work!\oscdimg.exe") else (set _ff="!_work!\cdimage.exe")
cd /d "!target!"
!_ff! -bootdata:2#p0,e,b".\boot\etfsboot.com"#pEF,e,b".\efi\microsoft\boot\efisys.bin" -o -m -u2 -udfver102 -l"%isover%" . "%isofile%"
set errcode=%errorlevel%
if not exist "%isofile%" set errcode=1
if %errcode% equ 0 move /y "%isofile%" "!isodir!\" %_Nul3%
cd /d "!_work!"
if %errcode% equ 0 if %delete_source% equ 1 rmdir /s /q "!target!\" %_Nul1%
if %errcode% equ 0 if exist "!_work!\DVD81UI\" rmdir /s /q "!_work!\DVD81UI\" %_Nul1%
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
if not defined isover (if defined ntkver (set isover=%ntkver%) else if defined regver (set isover=%regver%) else (set isover=9600.16384))
if not defined isolab (if defined reglab (set isolab=%reglab%) else (set isolab=winblue_ltsb))
if not defined ntkmin goto :eof
if %isomin% gtr %ntkmin% goto :eof
set isover=%ntkver%
set isodate=%ntkdate%
goto :eof

:fin
cd /d "!_work!"
if exist "!cab_dir!\" (
echo.
echo ============================================================
echo Removing temporary extracted files...
echo ============================================================
rmdir /s /q "!cab_dir!\" %_Nul1%
)
if %wimfiles% equ 1 if exist "!mountdir!\" rmdir /s /q "!mountdir!\" %_Nul1%
if exist "!winremount!\" rmdir /s /q "!winremount!\" %_Nul1%
if %dvd%==1 if %iso%==1 call :ISO
echo.
echo ============================================================
echo    Finished
echo ============================================================
echo.
if %online%==1 if exist "%SystemRoot%\winsxs\pending.xml" (
echo.
echo ============================================================
echo System restart is required to complete installation
echo ============================================================
echo.
)

:E_Exit
if %autostart% neq 0 goto :eof
if %_Debug% neq 0 goto :eof
echo.
echo Press 9 or q to exit.
choice /c 9Q /n
if errorlevel 1 (goto :eof) else (rem.)

:EndDebug
cmd /u /c type "!_log!_tmp.log">"!_log!_Debug.log"
(goto) &del "!_log!_tmp.log"
exit
