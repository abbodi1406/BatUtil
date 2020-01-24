@setlocal DisableDelayedExpansion
@set uiv=v6.1
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
set ssu2=KB4524445
set ssu1=KB3021910
set baselinelist=(KB2919355,KB3000850,KB2932046,KB2934018,KB2937592,KB2938439,KB2938772,KB3003057,KB3014442)
set gdrlist=(KB3023219,KB3037576,KB3074545,KB3097992,KB3127222)
set hv_integ_kb=hypervintegrationservices
set hv_integ_vr=9600.18692

set "SysPath=%SystemRoot%\System32"
if exist "%SystemRoot%\Sysnative\reg.exe" (set "SysPath=%SystemRoot%\Sysnative")
set "Path=%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
set "xOS=amd64"
if /i %PROCESSOR_ARCHITECTURE%==x86 (if not defined PROCESSOR_ARCHITEW6432 (
  set "xOS=x86"
  )
)
set "_Null=1>nul 2>nul"
reg.exe query HKU\S-1-5-19 %_Null% || goto :E_Admin
set "_oscdimg=%SysPath%\oscdimg.exe"
set "_SxS=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\SideBySide\Configuration"
set "_log=%~dpn0"
set "_work=%~dp0"
if "%_work:~-1%"=="\" set "_work=%_work:~0,-1%"
for /f "skip=2 tokens=2*" %%a in ('reg.exe query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop') do call set "_dsk=%%b"
if exist "%SystemDrive%\Users\Public\Desktop\desktop.ini" set "_dsk=%SystemDrive%\Users\Public\Desktop"
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
echo Running in Debug Mode...
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
for /f "tokens=1* delims==" %%A in ('find /i "%1 " WHD-W81UI.ini') do set "%1=%%~B"
goto :eof

:proceed
if %_Debug% neq 0 set autostart=1
for /f "tokens=6 delims=[]. " %%# in ('ver') do set winbuild=%%#
set _ADK=0
set "showdism=Host OS"
set "_dism2=%dismroot% /NoRestart /ScratchDir"
if /i not "!dismroot!"=="dism.exe" (
set "showdism=%dismroot%"
set _dism2="%dismroot%" /NoRestart /ScratchDir
)
if /i "!repo!"=="Updates" (if exist "!_work!\Updates\Windows8.1-*" (set "repo=!_work!\Updates") else (set "repo="))
for %%# in (LDRbranch Hotfix WUSatisfy Windows10 WMF RSAT) do if /i "!%%#!"=="NO" set "%%#=NO "
set _drv=%~d0
if /i "%cab_dir:~0,5%"=="W81UI" set "cab_dir=%_drv%\W81UItemp"
set _ntf=NTFS
if /i not "%_drv%"=="%SystemDrive%" for /f "tokens=2 delims==" %%# in ('"wmic volume where DriveLetter='%_drv%' get FileSystem /value"') do set "_ntf=%%#"
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
if %_init%==1 if "!target!"=="" if exist "*.wim" (for /f "tokens=* delims=" %%# in ('dir /b /a:-d "*.wim"') do set "target=!_work!\%%~nx#")
if "!target!"=="" set "target=%SystemDrive%"
if "%target:~-1%"=="\" set "target=!target:~0,-1!"
if /i "!target!"=="%SystemDrive%" (
if %xOS%==amd64 (set arch=x64) else (set arch=x86)
if %_init%==1 (goto :check) else (goto :mainmenu)
)
if "%target:~-4%"==".wim" (
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
dir /b /ad "!target!\Windows\servicing\Version\6.3.9600.*" %_Nul3% || (set "MESSAGE=Detected target offline image is not Windows 8.1"&goto :E_Target)
set "mountdir=!target!"
if exist "!target!\Windows\SysWOW64\cmd.exe" (set arch=x64) else (set arch=x86)
)
if %wim%==1 (
echo.
echo ============================================================
echo Please wait...
echo ============================================================
cd /d "!targetpath!"
dism.exe /english /get-wiminfo /wimfile:"%targetname%" /index:1 | find /i "Version : 6.3.9600" %_Nul1% || (set "MESSAGE=Detected wim version is not Windows 8.1"&goto :E_Target)
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
dism.exe /english /get-wiminfo /wimfile:"sources\install.wim" /index:1 | find /i "Version : 6.3.9600" %_Nul1% || (set "MESSAGE=Detected install.wim version is not Windows 8.1"&goto :E_Target)
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
reg.exe query %_SxS% /v W81UIclean %_Nul3% && (set onlineclean=1&set online=1&set cleanup=1)
reg.exe query %_SxS% /v W81UIrebase %_Nul3% && (set onlineclean=1&set online=1&set cleanup=1&set resetbase=1)
)
if defined onlineclean goto :mainboard2
if /i not "!dismroot!"=="dism.exe" if exist "!dismroot!" (set _ADK=1&goto :mainmenu)
goto :checkadk

:mainboard
if %winbuild% neq 9600 if /i "!target!"=="%SystemDrive%" (%_Goto%)
if %winbuild% lss 9600 if %_ADK% equ 0 (%_Goto%)
if "!target!"=="" (%_Goto%)
if "!repo!"=="" (%_Goto%)
if "%repo:~-1%"=="\" set "repo=!repo:~0,-1!"
if exist "!repo!\Windows8.1-Update3-%arch%\Security\*" (set "repo=!repo!\Windows8.1-Update3-%arch%") else (set "repo=!repo!\Windows8.1-%arch%")
if "!cab_dir!"=="" (%_Goto%)
if "!mountdir!"=="" (%_Goto%)
if /i "!target!"=="%SystemDrive%" (set dismtarget=/online&set "mountdir=!target!"&set online=1) else (set dismtarget=/image:"!mountdir!")

:mainboard2
if %_Debug% neq 0 set "
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
call :cleanup
reg.exe delete %_SxS% /v W81UIclean /f %_Nul3%
reg.exe delete %_SxS% /v W81UIrebase /f %_Nul3%
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
if %online%==1 (
call :update
goto :fin
)
if %offline%==1 (
call :update
call :cleanup
goto :fin
)
if %wim%==1 (
if "%indices%"=="*" set "indices="&for /L %%# in (1,1,!imgcount!) do set "indices=!indices! %%#"
call :mount "%targetname%"
if /i not "%targetname%"=="winre.wim" (if exist "!_work!\winre.wim" del /f /q "!_work!\winre.wim" %_Nul1%)
goto :fin
)
if %dvd%==0 goto :fin
if "%indices%"=="*" set "indices="&for /L %%# in (1,1,!imgcount!) do set "indices=!indices! %%#"
call :mount sources\install.wim
if exist "!_work!\winre.wim" del /f /q "!_work!\winre.wim" %_Nul1%
set imgcount=%bootimg%&set "indices="&for /L %%# in (1,1,!imgcount!) do set "indices=!indices! %%#"
call :mount sources\boot.wim
xcopy /CRY "!target!\efi\microsoft\boot\fonts" "!target!\boot\fonts\" %_Nul1%
if %_DNF%==1 if exist "!target!\sources\sxs\msil_microsoft.build.engine*3.5.9600.16384*" (rmdir /s /q "!target!\sources\sxs\" %_Nul1%)
if %wim2esd%==0 goto :fin
echo.
echo ============================================================
echo Converting install.wim to install.esd
echo ============================================================
cd /d "!target!"
%_dism2%:"!cab_dir!" /Export-Image /SourceImageFile:sources\install.wim /All /DestinationImageFile:sources\install.esd /Compress:Recovery
if %errorlevel% equ 0 (del /f /q sources\install.wim %_Nul3%) else (del /f /q sources\install.esd %_Nul3%)
cd /d "!_work!"
goto :fin

:update
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
set allcount=0
set _GDR=0
set winpe=0
if exist "!mountdir!\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" (
call :ssup
call :baseline
call :security
set winpe=1
call :winpe
set winpe=0
goto :eof
)
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

:ssup
if %online%==1 if exist "%SystemRoot%\winsxs\pending.xml" (goto :stacklimit)
call :cleaner
cd Baseline\
set package=%ssu2%&call :ssus
set package=%ssu1%&call :ssus
goto :eof

:ssus
if not exist "!repo!\Baseline\*%package%*%arch%.msu" goto :eof
if exist "!mountdir!\Windows\servicing\packages\package_for_%package%_rtm*6.3*.mum" goto :eof
if /i %package%==%ssu2% if not exist "!mountdir!\Windows\servicing\packages\package_for_KB2919355_rtm*6.3*.mum" goto :eof
if /i %package%==%ssu2% if not exist "!mountdir!\Windows\servicing\packages\package_for_KB2975061_rtm*6.3*.mum" if not exist "!mountdir!\Windows\servicing\packages\package_for_%ssu1%_rtm*6.3*.mum" goto :eof
if /i %package%==%ssu1% if exist "!mountdir!\Windows\servicing\packages\package_for_%ssu2%_rtm*6.3*.mum" goto :eof
if %verb%==1 (
echo.
echo ============================================================
echo *** Servicing Stack Update ***
echo ============================================================
)
cd /d "!cab_dir!"
set "dest=%package%"
if not exist "%dest%\*.manifest" (
expand.exe -f:*Windows*.cab "!repo!\Baseline\*%package%*%arch%.msu" . %_Null%
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
for %%# in %baselinelist% do (set "package=%%#"&call :baseline2)
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

:baseline2
if exist "!mountdir!\Windows\servicing\packages\package_for_%package%_rtm*6.3*.mum" goto :eof
if exist "!mountdir!\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" (
if /i %package%==KB3003057 goto :eof
if /i %package%==KB3014442 goto :eof
)
if not exist "*%package%*%arch%*" if not exist "RTM\*%package%*%arch%*" goto :eof
set /a count+=1
set "dest=%package%"
if not exist "!cab_dir!\%dest%\*.manifest" (
echo %count%: %package%
if /i %package%==KB2938772 (
  copy /y RTM\*%package%*%arch%.cab "!cab_dir!\" %_Nul1%
  ) else (
  if exist "*%package%*%arch%.msu" for /f "tokens=* delims=" %%# in ('dir /b /a:-d "*%package%*%arch%.msu"') do expand.exe -f:*Windows*.cab "%%~#" "!cab_dir!" %_Null%
  if exist "RTM\*%package%*%arch%.msu" for /f "tokens=* delims=" %%# in ('dir /b /a:-d "RTM\*%package%*%arch%.msu"') do expand.exe -f:*Windows*.cab "%%~#" "!cab_dir!" %_Null%
  )
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
if /i "%LDRbranch%"=="YES" if exist "!mountdir!\Windows\Microsoft.NET\Framework\v2.0.50727\ngen.exe" (for %%# in %gdrlist% do expand.exe -f:*Windows*.cab Additional\NET35\*%%#*%arch%.msu Additional\WU.Satisfy\ %_Null%)
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
if exist "!mountdir!\Windows\servicing\packages\package_for_%kb%_rtm*6.3*.mum" goto :eof
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
if exist "!mountdir!\Windows\Microsoft.NET\Framework\v2.0.50727\ngen.exe" goto :eof
call :cleaner
if not defined net35source (
for %%# in (D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do if exist "%%#:\sources\sxs\msil_microsoft.build.engine*3.5.9600.16384*" set "net35source=%%#:\sources\sxs"
if %dvd%==1 if exist "!target!\sources\sxs\msil_microsoft.build.engine*3.5.9600.16384*" set "net35source=!target!\sources\sxs"
if %wim%==1 for %%# in ("!target!") do (
  set "_wimpath=%%~dp#"
  if exist "!_wimpath!\sxs\msil_microsoft.build.engine*3.5.9600.16384*" set "net35source=!_wimpath!\sxs"
  )
)
if not defined net35source goto :eof
if not exist "!net35source!\msil_microsoft.build.engine*3.5.9600.16384*" goto :eof
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
if /i %kb%==KB3172729 (if %winbuild% lss 9600 set /a _sum-=1&set /a _msu-=1&goto :eof)
if exist "!mountdir!\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" if %winpe% equ 0 (
mkdir "!cab_dir!\check"
if %msu% equ 1 (expand.exe -f:*Windows*.cab "%package%" "!cab_dir!\check" %_Null%) else (copy /y "%package%" "!cab_dir!\check\" %_Nul1%)
expand.exe -f:update.mum "!cab_dir!\check\*.cab" . %_Null%
findstr /i /m "Package_for_RollupFix" "update.mum" %_Nul3% || (del /f /q "update.mum"&rd /s /q "!cab_dir!\check\"&set /a _sum-=1&if %msu% equ 1 (set /a _msu-=1&goto :eof) else (set /a _cab-=1&goto :eof))
del /f /q "update.mum"
rd /s /q "!cab_dir!\check\"
)
set inver=0
if /i %kb%==%hv_integ_kb% if exist "!mountdir!\Windows\servicing\packages\*Hyper-V-Integration-Services*.mum" (
for /f "tokens=6,7 delims=~." %%i in ('dir /b /a:-d /od "!mountdir!\Windows\servicing\packages\*Hyper-V-Integration-Services*.mum"') do set inver=%%i%%j
if !inver! geq !hv_integ_vr! (set /a _sum-=1&set /a _cab-=1&goto :eof)
)
set "mumcheck=package_for_%kb%_rtm*6.3*.mum"
if %_GDR% equ 1 set "mumcheck=package_for_%kb%_rtm~*6.3*.mum"
set inver=0
if /i %kb%==KB2976978 if exist "!mountdir!\Windows\servicing\packages\%mumcheck%" (
for /f "tokens=6,7 delims=~." %%i in ('dir /b /a:-d /od "!mountdir!\Windows\servicing\packages\%mumcheck%"') do set inver=%%i%%j
mkdir "!cab_dir!\check"
if %msu% equ 1 (expand.exe -f:*Windows*.cab "%package%" "!cab_dir!\check" %_Null%) else (copy /y "%package%" "!cab_dir!\check\" %_Nul1%)
expand.exe -f:package_for_%kb%_rtm~*.mum "!cab_dir!\check\*.cab" "!cab_dir!\check" %_Null%
for /f "tokens=6,7 delims=~." %%i in ('dir /b /a:-d "!cab_dir!\check\package_for_%kb%_rtm*6.3*.mum"') do call set kbver=%%i%%j
rd /s /q "!cab_dir!\check\"
if !inver! geq !kbver! (set /a _sum-=1&if %msu% equ 1 (set /a _msu-=1&goto :eof) else (set /a _cab-=1&goto :eof))
)
if /i not %kb%==KB2976978 if exist "!mountdir!\Windows\servicing\packages\%mumcheck%" (set /a _sum-=1&if %msu% equ 1 (set /a _msu-=1&goto :eof) else (set /a _cab-=1&goto :eof))
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
if %wimfiles%==1 (
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

set "T_Win=Microsoft\Windows"
set "T_App=Microsoft\Windows\Application Experience"
set "T_CEIP=Microsoft\Windows\Customer Experience Improvement Program"
(
echo @echo off
echo reg.exe query "HKU\S-1-5-19" 1^>nul 2^>nul ^|^| ^(echo Run the script as administrator^&pause^&exit^)
echo reg.exe delete HKLM\SYSTEM\CurrentControlSet\Control\WMI\AutoLogger\AutoLogger-Diagtrack-Listener /f
echo reg.exe delete HKLM\SYSTEM\CurrentControlSet\Control\WMI\AutoLogger\Diagtrack-Listener /f
echo rem reg.exe delete HKLM\SYSTEM\CurrentControlSet\Control\WMI\AutoLogger\SQMLogger /f
echo icacls "%%ProgramData%%\Microsoft\Diagnosis" /grant:r *S-1-5-32-544:^(OI^)^(CI^)^(IO^)^(F^) /T /C
echo del /f /q "%%ProgramData%%\Microsoft\Diagnosis\*.rbs"
echo del /f /q /s "%%ProgramData%%\Microsoft\Diagnosis\ETLLogs\*"
echo sc.exe config DiagTrack start= disabled
echo sc.exe stop DiagTrack
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
goto :eof

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

:mount
set "_wimfile=%~1"
if %wim%==1 set "_wimpath=!targetpath!"
if %dvd%==1 set "_wimpath=!target!"
if exist "!mountdir!\" rmdir /s /q "!mountdir!\" %_Nul1%
if not exist "!mountdir!\" mkdir "!mountdir!"
if not exist "!cab_dir!\" mkdir "!cab_dir!"
for %%# in (%indices%) do (
echo.
echo ============================================================
echo Mounting %_wimfile% - index %%#/%imgcount%
echo ============================================================
cd /d "!_wimpath!"
%_dism2%:"!cab_dir!" /Mount-Wim /Wimfile:%_wimfile% /Index:%%# /MountDir:"!mountdir!"
if !errorlevel! neq 0 goto :E_MOUNT
cd /d "!_work!"
call :update
call :cleanup
if %dvd%==1 if exist "!mountdir!\sources\setup.exe" call :boots
if %dvd%==1 if not defined isover (
  if exist "!mountdir!\Windows\WinSxS\Manifests\%sss%_microsoft-windows-rollup-version*.manifest" for /f "tokens=6,7 delims=_." %%i in ('dir /b /a:-d /od "!mountdir!\Windows\WinSxS\Manifests\%sss%_microsoft-windows-rollup-version*.manifest"') do set isover=%%i.%%j
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
echo Unmounting %_wimfile% - index %%#/%imgcount%
echo ============================================================
%_dism2%:"!cab_dir!" /Unmount-Wim /MountDir:"!mountdir!" /Commit
if !errorlevel! neq 0 goto :E_MOUNT
)
cd /d "!_work!"
echo.
echo ============================================================
echo Rebuilding %_wimfile%
echo ============================================================
cd /d "!_wimpath!"
if %keep%==1 (
for %%# in (%indices%) do %_dism2%:"!cab_dir!" /Export-Image /SourceImageFile:%_wimfile% /SourceIndex:%%# /DestinationImageFile:temp.wim
) else (
%_dism2%:"!cab_dir!" /Export-Image /SourceImageFile:%_wimfile% /All /DestinationImageFile:temp.wim
)
if %errorlevel% equ 0 (move /y temp.wim %_wimfile% %_Nul1%) else (del /f /q temp.wim %_Nul3%)
cd /d "!_work!"
goto :eof

:boots
  xcopy /CDRY "!mountdir!\sources" "!target!\sources\" %_Nul3%
  del /f /q "!target!\sources\background.bmp" %_Nul3%
  del /f /q "!target!\sources\xmllite.dll" %_Nul3%
  del /f /q "!target!\efi\microsoft\boot\*noprompt.*" %_Nul3%
  rem copy /y "!mountdir!\Windows\Boot\DVD\EFI\en-US\efisys.bin" "!target!\efi\microsoft\boot\" %_Nul1%
  copy /y "!mountdir!\Windows\Boot\EFI\memtest.efi" "!target!\efi\microsoft\boot\" %_Nul1%
  copy /y "!mountdir!\Windows\Boot\EFI\bootmgfw.efi" "!target!\efi\boot\%efifile%" %_Nul1%
  copy /y "!mountdir!\Windows\Boot\EFI\bootmgr.efi" "!target!\" %_Nul1%
  copy /y "!mountdir!\Windows\Boot\PCAT\bootmgr" "!target!\" %_Nul1%
  copy /y "!mountdir!\Windows\Boot\PCAT\memtest.exe" "!target!\boot\" %_Nul1%
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
  call :update winre
  %_dism2%:"!cab_dir!" %dismtarget% /Cleanup-Image /StartComponentCleanup /ResetBase
  call :cleanmanual
  %_dism2%:"!cab_dir!" /Unmount-Wim /MountDir:"!winremount!" /Commit
  if %errorlevel% neq 0 goto :E_MOUNT
  cd /d "!_work!"
  %_dism2%:"!cab_dir!" /Export-Image /SourceImageFile:winre.wim /All /DestinationImageFile:temp.wim
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
if %resetbase%==0 (set rValue=W81UIclean) else (set rValue=W81UIrebase)
if exist "!mountdir!\Windows\WinSxS\pending.xml" (
if %online%==1 reg.exe add %_SxS% /v %rValue% /t REG_DWORD /d 1 /f %_Nul1%&goto :eof
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
takeown /f "!mountdir!\Windows\WinSxS\Temp\PendingDeletes\*" /A %_Nul3%
icacls "!mountdir!\Windows\WinSxS\Temp\PendingDeletes\*" /grant *S-1-5-32-544:F %_Nul3%
del /f /q "!mountdir!\Windows\WinSxS\Temp\PendingDeletes\*" %_Nul3%
)
if exist "!mountdir!\Windows\WinSxS\Temp\TransformerRollbackData\*" (
takeown /f "!mountdir!\Windows\WinSxS\Temp\TransformerRollbackData\*" /R /A %_Nul3%
icacls "!mountdir!\Windows\WinSxS\Temp\TransformerRollbackData\*" /grant *S-1-5-32-544:F /T %_Nul3%
del /s /f /q "!mountdir!\Windows\WinSxS\Temp\TransformerRollbackData\*" %_Nul3%
)
if exist "!mountdir!\Windows\inf\*.log" (
del /f /q "!mountdir!\Windows\inf\*.log" %_Nul3%
)
for /f "tokens=* delims=" %%# in ('dir /b /ad "!mountdir!\Windows\CbsTemp\" %_Nul6%') do rmdir /s /q "!mountdir!\Windows\CbsTemp\%%#\" %_Nul3%
del /s /f /q "!mountdir!\Windows\CbsTemp\*" %_Nul3%
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
if %wimfiles%==1 (if exist "!mountdir!\" if not exist "!mountdir!\Windows\" rmdir /s /q "!mountdir!\" %_Nul3%)
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
echo.
echo Press 9 to exit.
if %_Debug% neq 0 goto :EndDebug
choice /c 9 /n
if errorlevel 1 (exit) else (rem.)

:E_Admin
echo.
echo ============================================================
echo ERROR: right click on the script and 'Run as administrator'
echo ============================================================
echo.
echo Press any key to exit.
pause >nul
goto :eof

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
if exist "%DandIRoot%\%xOS%\DISM\dism.exe" (
set _ADK=1
if %winbuild% lss 9600 set "showdism=Windows 8.1 ADK"
if %winbuild% lss 9600 set "Path=%DandIRoot%\%xOS%\DISM;%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
)
if exist "%DandIRoot%\%xOS%\Oscdimg\oscdimg.exe" (
set "_oscdimg=%DandIRoot%\%xOS%\Oscdimg\oscdimg.exe"
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
if exist "%DandIRoot%\%xOS%\DISM\dism.exe" (
set _ADK=1
if %winbuild% lss 9600 set "showdism=Windows 10 ADK"
if %winbuild% lss 9600 set "Path=%DandIRoot%\%xOS%\DISM;%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
)
if exist "%DandIRoot%\%xOS%\Oscdimg\oscdimg.exe" (
set "_oscdimg=%DandIRoot%\%xOS%\Oscdimg\oscdimg.exe"
)
goto :mainmenu

:targetmenu
@cls
set _pp=
echo ============================================================
echo Enter the path for one of supported targets:
echo - Distribution ^(extracted folder, mounted iso/dvd/usb drive^)
echo - WIM file ^(not mounted^)
echo - Mounted directory, offline image drive letter
if %winbuild% equ 9600 echo - Current OS / Enter %SystemDrive%
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
for /f "tokens=4 delims==." %%# in ('wmic datafile where "name='!_pp:\=\\!'" get Version /value') do if %%# lss 9600 (echo.&echo ERROR: DISM version is lower than 6.3.9600&pause&goto :dismmenu)
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
if %winbuild% neq 9600 (set "target="&echo [1] Select offline target) else (echo [1] Target ^(%arch%^): Current Online OS)
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
if %wimfiles%==1 (
if /i "%targetname%"=="install.wim" (echo.&if %winre%==1 (echo [U] Update WinRE.wim: YES) else (echo [U] Update WinRE.wim: NO))
if %imgcount% gtr 1 (
echo.
if "%indices%"=="*" echo [I] Install.wim selected indexes: All ^(%imgcount%^)
if not "%indices%"=="*" (if %keep%==1 (echo [I] Install.wim selected indexes: %indices% / [K] Keep indexes: Selected) else (if %keep%==0 echo [I] Install.wim selected indexes: %indices% / [K] Keep indexes: ALL))
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
if errorlevel 18 (if %wimfiles%==1 (if %winre%==1 (set winre=0) else (set winre=1)))&goto :mainmenu
if errorlevel 17 (if %net35%==1 (set net35=0) else (set net35=1))&goto :mainmenu
if errorlevel 16 (if %wimfiles%==1 (goto :mountmenu))&goto :mainmenu
if errorlevel 15 (if %wimfiles%==1 if %imgcount% gtr 1 (if %keep%==1 (set keep=0) else (set keep=1)))&goto :mainmenu
if errorlevel 14 (if %wimfiles%==1 if %imgcount% gtr 1 (goto :indexmenu))&goto :mainmenu
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
for /f "tokens=2 delims==." %%# in ('wmic os get localdatetime /value') do set "_date=%%#"
set "isodate=%_date:~0,4%-%_date:~4,2%-%_date:~6,2%"
if defined isover (set isofile=Win8.1_%isover%_%arch%_%isodate%.iso) else (set isofile=Win8.1_%arch%_%isodate%.iso)
set /a rnd=%random%
if exist "!isodir!\%isofile%" ren "!isodir!\%isofile%" "%rnd%_%isofile%"
echo.
echo ============================================================
echo Creating updated ISO file...
echo ============================================================
if exist "!_oscdimg!" (set _ff="!_oscdimg!") else if exist "!_work!\oscdimg.exe" (set _ff="!_work!\oscdimg.exe") else (set _ff="!_work!\cdimage.exe")
cd /d "!target!"
!_ff! -m -o -u2 -udfver102 -bootdata:2#p0,e,b".\boot\etfsboot.com"#pEF,e,b".\efi\microsoft\boot\efisys.bin" -l"%isover%u" . "%isofile%"
set errcode=%errorlevel%
if %errcode% equ 0 move /y "%isofile%" "!isodir!\" %_Nul3%
cd /d "!_work!"
if %errcode% equ 0 if %delete_source% equ 1 rmdir /s /q "!target!\" %_Nul1%
if %errcode% equ 0 if exist "!_work!\DVD81UI\" rmdir /s /q "!_work!\DVD81UI\" %_Nul1%
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
if %wimfiles%==1 if exist "!mountdir!\" rmdir /s /q "!mountdir!\" %_Nul1%
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
echo.
echo Press 9 to exit.
if %_Debug% neq 0 goto :eof
choice /c 9 /n
if errorlevel 1 (goto :eof) else (rem.)

:EndDebug
cmd /u /c type "!_log!_tmp.log">"!_log!_Debug.log"
(goto) &del "!_log!_tmp.log"
exit
