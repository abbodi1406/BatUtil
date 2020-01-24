@setlocal DisableDelayedExpansion
@set uiv=v6.2
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
set IE11=YES
set RDP=YES
set Hotfix=NO
set WAT=NO
set WMF=NO
set Windows10=NO
set ADLDS=NO
set RSAT=NO

:: update winre.wim if detected inside install.wim
set WinRE=1

:: set directory for temporary extracted files (default is on the same drive as the script)
set "Cab_Dir=W7UItemp"

:: set mount directory for updating wim files (default is on the same drive as the script)
set "MountDir=W7UImount"
set "WinreMount=W7UImountre"

:: start the process directly once you execute the script, as long as the other options are correctly set
set AutoStart=0

:: # Options for distribution target only #

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
set ssu2nd=KB4536952
set ssu1st=KB4490628
set sha2cs=KB4474419
set rollup=KB3125574
set gdrlist=(KB2574819,KB2685811,KB2685813)
set rdp8=(0)
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
set "_imagex=%SysPath%\imagex.exe"
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
title Installer for Windows 7 Updates
cd /d "!_work!"
if not exist "WHD-W7UI.ini" goto :proceed
find /i "[W7UI-Configuration]" WHD-W7UI.ini %_Nul1% || goto :proceed
setlocal DisableDelayedExpansion
for %%# in (
target
repo
dismroot
winre
cab_dir
mountdir
winremount
iso
isodir
delete_source
autostart
OnlineLimit
LDRbranch
IE11
RDP
Hotfix
Windows10
WAT
WMF
ADLDS
RSAT
) do (
call :ReadINI %%#
)
setlocal EnableDelayedExpansion
goto :proceed

:ReadINI
find /i "%1 " WHD-W7UI.ini >nul || goto :eof
for /f "tokens=1* delims==" %%A in ('find /i "%1 " WHD-W7UI.ini') do set "%1=%%~B"
goto :eof

:proceed
if %_Debug% neq 0 set autostart=1
for /f "tokens=6 delims=[]. " %%# in ('ver') do set winbuild=%%#
set win7=0
if %winbuild% equ 7601 set win7=1
if %winbuild% equ 7602 set win7=1
if exist "!_work!\imagex.exe" set "_imagex=!_work!\imagex.exe"
set _ADK=0
set "showdism=Host OS"
set "_dism2=%dismroot% /NoRestart /ScratchDir"
if /i not "!dismroot!"=="dism.exe" (
set "showdism=%dismroot%"
set _dism2="%dismroot%" /NoRestart /ScratchDir
)
if /i "!repo!"=="Updates" (if exist "!_work!\Updates\Windows7-*" (set "repo=!_work!\Updates") else (set "repo="))
for %%# in (LDRbranch IE11 RDP Hotfix Windows10 WAT WMF ADLDS RSAT) do if /i "!%%#!"=="NO" set "%%#=NO "
set _drv=%~d0
if /i "%cab_dir:~0,4%"=="W7UI" set "cab_dir=%_drv%\W7UItemp"
set _ntf=NTFS
if /i not "%_drv%"=="%SystemDrive%" for /f "tokens=2 delims==" %%# in ('"wmic volume where DriveLetter='%_drv%' get FileSystem /value"') do set "_ntf=%%#"
if /i not "%_ntf%"=="NTFS" set _drv=%SystemDrive%
if /i "%mountdir:~0,4%"=="W7UI" set "mountdir=%_drv%\W7UImount"
if /i "%winremount:~0,4%"=="W7UI" set "winremount=%_drv%\W7UImountre"
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
dir /b /ad "!target!\Windows\servicing\Version\6.1.760*" %_Nul3% || (set "MESSAGE=Detected target offline image is not Windows 7 SP1"&goto :E_Target)
set "mountdir=!target!"
if exist "!target!\Windows\SysWOW64\cmd.exe" (set arch=x64) else (set arch=x86)
)
if %wim%==1 (
echo.
echo ============================================================
echo Please wait...
echo ============================================================
cd /d "!targetpath!"
dism.exe /english /get-wiminfo /wimfile:"%targetname%" /index:1 | find /i "Version : 6.1.760" %_Nul1% || (set "MESSAGE=Detected wim version is not Windows 7 SP1"&goto :E_Target)
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
dism.exe /english /get-wiminfo /wimfile:"sources\install.wim" /index:1 | find /i "Version : 6.1.760" %_Nul1% || (set "MESSAGE=Detected install.wim version is not Windows 7 SP1"&goto :E_Target)
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
if /i not "!dismroot!"=="dism.exe" if exist "!dismroot!" (set _ADK=1&goto :mainmenu)
goto :checkadk

:mainboard
if %win7% neq 1 if /i "!target!"=="%SystemDrive%" (%_Goto%)
if "!target!"=="" (%_Goto%)
if "!repo!"=="" (%_Goto%)
if "%repo:~-1%"=="\" set "repo=!repo:~0,-1!"
set "repo=!repo!\Windows7-%arch%"
if "!cab_dir!"=="" (%_Goto%)
if "!mountdir!"=="" (%_Goto%)
if /i "!target!"=="%SystemDrive%" (set dismtarget=/online&set "mountdir=!target!"&set online=1) else (set dismtarget=/image:"!mountdir!")

:mainboard2
if %_Debug% neq 0 set "
@cls
echo ============================================================
echo Running WHD-W7UI %uiv%
echo ============================================================
if %online%==1 (
net stop trustedinstaller %_Nul3%
net stop wuauserv %_Nul3%
del /f /q %systemroot%\Logs\CBS\* %_Nul3%
)
del /f /q %systemroot%\Logs\DISM\* %_Nul3%
if %dvd%==1 if %copytarget%==1 (
echo.
echo ============================================================
echo Copying DVD Drive contents to work directory
echo ============================================================
if exist "!_work!\DVD7UI\" rmdir /s /q "!_work!\DVD7UI\" %_Nul1%
robocopy "!target!" "!_work!\DVD7UI" /E /A-:R >nul
set "target=!_work!\DVD7UI"
)
if /i %arch%==x64 (set efifile=bootx64.efi&set sss=amd64) else (set efifile=bootia32.efi&set sss=x86)
if %online%==1 (
call :update
goto :fin
)
if %offline%==1 (
call :update
call :cleanmanual
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
set IEcab=0
set ssucsuesu=0
if exist "!mountdir!\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" (
call :ssu
call :csu
call :esu
call :security
goto :eof
)
call :ssu
call :csu
call :esu
call :general
if /i "%IE11%"=="YES" (call :ie11) else (call :ie9)
if /i "%RDP%"=="YES" call :rdp
if /i "%ADLDS%"=="YES" call :adlds
if /i "%RSAT%"=="YES" call :rsat
if /i "%WMF%"=="YES" call :wmf
if /i "%Hotfix%"=="YES" call :hotfix
if /i "%Windows10%"=="YES" call :windows10
call :online
call :security
call :rollup
if /i "%Hotfix%"=="YES" call :regfix
goto :eof

:ssu
if not exist "!repo!\General\*%ssu1st%*-%arch%.msu" goto :eof
if exist "!mountdir!\Windows\servicing\packages\package_for_%ssu1st%*.mum" goto :eof
if %online%==1 if exist "%SystemRoot%\winsxs\pending.xml" (call set "ssulmt=ssu1st"&goto :stacklimit)
call :cleaner
if %verb%==1 (
echo.
echo ============================================================
echo *** Servicing Stack Update ***
echo ============================================================
)
cd General\
set "dest=SSU"
if not exist "!cab_dir!\%dest%\*%ssu1st%*.mum" (
expand.exe -f:*Windows*.cab "*%ssu1st%*%arch%.msu" "!cab_dir!" %_Null%
mkdir "!cab_dir!\%dest%"
expand.exe -f:* "!cab_dir!\*%ssu1st%*.cab" "!cab_dir!\%dest%" %_Null%
)
cd /d "!cab_dir!"
%_dism2%:"!cab_dir!" %dismtarget% /Add-Package /packagepath:"%dest%\update.mum"
goto :eof

:esu
if not exist "!repo!\Security\*%ssu2nd%*-%arch%.msu" goto :eof
if exist "!mountdir!\Windows\servicing\packages\package_for_%ssu2nd%*.mum" goto :eof
if %online%==1 if exist "%SystemRoot%\winsxs\pending.xml" (call set "ssulmt=ssu2nd"&goto :stacklimit)
set ssuver=0
set shaupd=0
for /f %%# in ('dir /b "!mountdir!\Windows\servicing\Version"') do set ssuver=%%#
if %ssuver:~9% lss 24383 goto :eof
if %online%==1 (set ksub1=SOFTWARE) else (set ksub1=OFFSOFT&reg.exe load HKLM\!ksub1! "!mountdir!\Windows\System32\config\SOFTWARE" %_Nul1%)
reg.exe query HKLM\%ksub1%\Microsoft\Windows\CurrentVersion\Servicing\Codesigning\SHA2 /v SHA2-Codesigning-Support %_Nul3% && set shaupd=1
if %online%==0 reg.exe unload HKLM\%ksub1% %_Nul1%
if %shaupd% neq 1 goto :eof
call :cleaner
if %verb%==1 (
echo.
echo ============================================================
echo *** Extended Servicing Stack Update ***
echo ============================================================
)
cd Security\
set "dest=ESU"
if not exist "!cab_dir!\%dest%\*%ssu2nd%*.mum" (
expand.exe -f:*Windows*.cab "*%ssu2nd%*%arch%.msu" "!cab_dir!" %_Null%
mkdir "!cab_dir!\%dest%"
expand.exe -f:* "!cab_dir!\*%ssu2nd%*.cab" "!cab_dir!\%dest%" %_Null%
)
cd /d "!cab_dir!"
%_dism2%:"!cab_dir!" %dismtarget% /Add-Package /packagepath:"%dest%\update.mum"
goto :eof

:csu
if not exist "!repo!\Security\*%sha2cs%*-%arch%.msu" goto :eof
if exist "!mountdir!\Windows\servicing\packages\package_for_%sha2cs%*6.1.3.2.mum" goto :eof
call :cleaner
if %verb%==1 (
echo.
echo ============================================================
echo *** SHA2 Code Signing Support Update ***
echo ============================================================
)
cd Security\
set "dest=SHA"
if not exist "!cab_dir!\%dest%\*%sha2cs%*.mum" (
expand.exe -f:*Windows*.cab "*%sha2cs%*%arch%.msu" "!cab_dir!" %_Null%
mkdir "!cab_dir!\%dest%"
expand.exe -f:* "!cab_dir!\*%sha2cs%*.cab" "!cab_dir!\%dest%" %_Null%
)
cd /d "!cab_dir!"
%_dism2%:"!cab_dir!" %dismtarget% /Add-Package /packagepath:"%dest%\update.mum"
goto :eof

:rollup
if not exist "!repo!\General\*%rollup%*%arch%.msu" goto :eof
if exist "!mountdir!\Windows\servicing\packages\package_for_%rollup%*6.1*.mum" goto :eof
call :cleaner
if %verb%==1 (
echo.
echo ============================================================
echo *** Convenience Rollup Update ***
echo ============================================================
)
cd General\
set "dest=CRU"
if not exist "!cab_dir!\%dest%\*%rollup%*.mum" (
if %verb%==1 (
echo.
echo ============================================================
echo Extracting files from %rollup% cabinet ^(.cab^)
echo *** This will require some disk space, please be patient ***
echo ============================================================
)
expand.exe -f:*Windows*.cab "*%rollup%*%arch%.msu" "!cab_dir!" %_Null%
mkdir "!cab_dir!\%dest%"
expand.exe -f:* "!cab_dir!\*%rollup%*.cab" "!cab_dir!\%dest%" %_Null%
)
if %verb%==1 (
echo.
echo ============================================================
echo Installing %rollup%
echo ============================================================
)
cd /d "!cab_dir!"
%_dism2%:"!cab_dir!" %dismtarget% /Add-Package /packagepath:"%dest%\update.mum"
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
goto :eof

:general
if not exist "!repo!\General\*.msu" goto :eof
call :cleaner
echo.
echo ============================================================
echo *** General Updates ***
echo ============================================================
set "cat=General Updates"
if /i not "%CEdition%"=="Enterprise" if /i not "%CEdition%"=="EnterpriseN" if /i not "%CEdition%"=="EnterpriseE" if /i "%WAT%"=="YES" if exist "Additional\WAT\*%arch%*.msu" (expand.exe -f:*Windows*.cab Additional\WAT\*%arch%*.msu .\General %_Null%)
cd General\
call :counter
call :cab1
if exist "!repo!\General\*KB971033*.cab" del /f /q "!repo!\General\*KB971033*.cab" %_Nul1%
if %_sum% equ 0 goto :eof
call :mum1
if %_sum% equ 0 goto :eof
goto :listdone

:security
if %online%==1 if %allcount% geq %onlinelimit% goto :countlimit
if not exist "!repo!\Security\*.msu" goto :eof
set ssuver=0
set shaupd=0
for /f %%# in ('dir /b "!mountdir!\Windows\servicing\Version"') do set ssuver=%%#
if %online%==1 (set ksub1=SOFTWARE) else (set ksub1=OFFSOFT&reg.exe load HKLM\!ksub1! "!mountdir!\Windows\System32\config\SOFTWARE" %_Nul1%)
reg.exe query HKLM\%ksub1%\Microsoft\Windows\CurrentVersion\Servicing\Codesigning\SHA2 /v SHA2-Codesigning-Support %_Nul3% && set shaupd=1
if %online%==0 reg.exe unload HKLM\%ksub1% %_Nul1%
if %ssuver:~9% geq 24516 if %shaupd% equ 1 set ssucsuesu=1
call :cleaner
if %verb%==1 (
echo.
echo ============================================================
echo *** Security Updates ***
echo ============================================================
)
set "cat=Security Updates"
cd Security\
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

:rdp
if %online%==1 if %allcount% geq %onlinelimit% goto :countlimit
if not exist "!repo!\Additional\RDP\*.msu" goto :eof
call :cleaner
echo.
echo ============================================================
echo *** RDP Updates ***
echo ============================================================
set "cat=RDP Updates"
cd Additional\RDP\
call :counter
call :cab1
if %_sum% equ 0 goto :eof
call :mum1
if %_sum% equ 0 goto :eof
goto :listdone

:ie11
if %online%==1 if %allcount% geq %onlinelimit% goto :countlimit
if not exist "!repo!\Additional\_IE11\*.cab" goto :eof
call :cleaner
echo.
echo ============================================================
echo *** IE11 Updates ***
echo ============================================================
set "cat=IE11 Updates"
cd Additional\_IE11\
set IEcab=1
call :counter
call :cab1
set IEcab=0
if %_sum% equ 0 goto :eof
call :mum1
if %_sum% equ 0 goto :eof
goto :listdone

:ie9
if %online%==1 if %allcount% geq %onlinelimit% goto :countlimit
if exist "!mountdir!\Windows\servicing\packages\*InternetExplorer*11.2.*.mum" goto :eof
if not exist "!repo!\Extra\IE9\*.msu" if not exist "!repo!\Extra\IE8\*.msu" goto :eof
call :cleaner
echo.
echo ============================================================
echo *** IE9/IE8 Updates ***
echo ============================================================
set "cat=IE Updates"
if exist "Extra\IE9\*.msu" (
if not exist "!cab_dir!\IE9\" (
mkdir "!cab_dir!\IE9"
copy /y Extra\IE9\*%arch%*.msu "!cab_dir!\IE9\" %_Nul3%
copy /y Extra\IE9\Updates\*%arch%*.msu "!cab_dir!\IE9\" %_Nul3%
)
cd /d "!cab_dir!\IE9"
set IEcab=1
) else (
cd Extra\IE8
)
call :counter
call :cab1
set IEcab=0
if %_sum% equ 0 goto :eof
call :mum1
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

:adlds
if %online%==1 if %allcount% geq %onlinelimit% goto :countlimit
if exist "!mountdir!\Windows\servicing\packages\*DirectoryServices-ADAM-Package-Client*7601*.mum" goto :eof
call :cleaner
if exist "!mountdir!\Windows\servicing\packages\*DirectoryServices-ADAM-Package-Client*.mum" goto :adldsu
if not exist "!repo!\Extra\AD_LDS\*.msu" goto :eof
echo.
echo ============================================================
echo *** AD LDS KB975541 ***
echo ============================================================
cd Extra\AD_LDS\
expand.exe -f:*Windows*.cab *%arch%*.msu "!cab_dir!" %_Null%
cd /d "!cab_dir!"
%_dism2%:"!cab_dir!" %dismtarget% /Add-Package /packagepath:.
del /f /q "*KB975541*.cab"
cd /d "!repo!"

:adldsu
if not exist "!repo!\Extra\AD_LDS\Updates\*.msu" goto :eof
echo.
echo ============================================================
echo *** AD LDS Updates ***
echo ============================================================
set "cat=AD LDS Updates"
cd Extra\AD_LDS\Updates\
call :counter
call :cab1
if %_sum% equ 0 goto :eof
call :mum1
if %_sum% equ 0 goto :eof
goto :listdone

:rsat
if %online%==1 if %allcount% geq %onlinelimit% goto :countlimit
if exist "!mountdir!\Windows\servicing\packages\*RemoteServerAdministrationTools*7601*.mum" goto :eof
call :cleaner
if exist "!mountdir!\Windows\servicing\packages\*RemoteServerAdministrationTools*.mum" goto :rsatu
if not exist "!repo!\Extra\RSAT\*.msu" goto :eof
echo.
echo ============================================================
echo *** RSAT KB958830 ***
echo ============================================================
cd Extra\RSAT\
expand.exe -f:*Windows*.cab *%arch%*.msu "!cab_dir!" %_Null%
cd /d "!cab_dir!"
%_dism2%:"!cab_dir!" %dismtarget% /Add-Package /packagepath:.
del /f /q "*KB958830*.cab"
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
if not exist "!repo!\Additional\_NotAllowedOffline\*.msu" goto :eof
call :cleaner
echo.
echo ============================================================
echo *** Online Updates ***
echo ============================================================
cd Additional\_NotAllowedOffline\
for /f "tokens=* delims=" %%# in ('dir /b /a:-d *%arch%*.msu') do (set "package=%%#"&call :online2)
goto :eof

:online2
for /f "tokens=2 delims=-" %%V in ('echo "%package%"') do set kb=%%V
if exist "!mountdir!\Windows\servicing\packages\package_for_%kb%~*6.1*.mum" goto :eof
if /i %kb%==KB947821 goto :eof
if /i %kb%==KB2603229 (
goto :KB2603229
)
if /i %kb%==KB2646060 (
goto :KB2646060
)
if /i %kb%==KB4099950 if %online%==0 (
goto :cabonline
)
if %online%==1 (
%package% /quiet /norestart
goto :cabonline
)
goto :eof

:KB2603229
set "_sreg=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
set "_treg=HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion"
if %online%==1 (
for /f "skip=2 tokens=2*" %%i in ('%SysPath%\reg.exe query "%_sreg%" /v RegisteredOwner') do %SysPath%\reg.exe add "%_treg%" /v RegisteredOwner /d "%%j" /f %_Nul3%
for /f "skip=2 tokens=2*" %%i in ('%SysPath%\reg.exe query "%_sreg%" /v RegisteredOrganization') do %SysPath%\reg.exe add "%_treg%" /v RegisteredOrganization /d "%%j" /f %_Nul3%
goto :cabonline
)
(
echo @echo off
echo reg.exe query "HKU\S-1-5-19" 1^>nul 2^>nul ^|^| ^(echo Run the script as administrator^&pause^&exit^)
echo for /f "skip=2 tokens=2*" %%%%i in ^('%%SystemRoot%%\system32\reg.exe query "%_sreg%" /v RegisteredOwner'^) do %%SystemRoot%%\system32\reg.exe add "%_treg%" /v RegisteredOwner /d "%%%%j" /f
echo for /f "skip=2 tokens=2*" %%%%i in ^('%%SystemRoot%%\system32\reg.exe query "%_sreg%" /v RegisteredOrganization'^) do %%SystemRoot%%\system32\reg.exe add "%_treg%" /v RegisteredOrganization /d "%%%%j" /f
echo ^(goto^) 2^>nul ^&del /f /q %%0 ^&exit /b
)>"%kb%.cmd"
move /y "%kb%.cmd" "!mountdir!\Users\Public\Desktop\RunOnce_KB2603229_Fix.cmd" %_Nul3%
goto :cabonline

:KB2646060
(
echo [Version]
echo Signature=$Windows NT$
echo.
echo [DefaultInstall]
echo RunPostSetupCommands=%kb%:1
echo SmartReboot=N
echo Cleanup=1
echo.
echo [%kb%]
echo %%11%%\powercfg.exe /attributes sub_processor 0cc5b647-c1df-4637-891a-dec35c318583 -ATTRIB_HIDE
echo %%11%%\powercfg.exe /attributes sub_processor ea062031-0e34-4ff1-9b6d-eb1059334028 -ATTRIB_HIDE
echo %%11%%\powercfg.exe /setacvalueindex scheme_current sub_processor 0cc5b647-c1df-4637-891a-dec35c318583 100
echo %%11%%\powercfg.exe /setacvalueindex scheme_current sub_processor ea062031-0e34-4ff1-9b6d-eb1059334028 100
echo %%11%%\powercfg.exe /setactive scheme_current
)>"%kb%.inf"
move /y "%kb%.inf" "!mountdir!\Windows\inf\%kb%.inf" %_Nul3%
if %online%==1 (
%_Nul3% %SysPath%\rundll32.exe advpack.dll,LaunchINFSection %SystemRoot%\inf\%kb%.inf,DefaultInstall
) else (
%_Nul3% reg.exe load HKLM\OFFSOFT "!mountdir!\Windows\System32\config\SOFTWARE"
%_Nul3% reg.exe add HKLM\OFFSOFT\Microsoft\Windows\CurrentVersion\RunOnce /v 0%kb% /t REG_EXPAND_SZ /d "rundll32.exe advpack.dll,LaunchINFSection %%SystemRoot%%\inf\%kb%.inf,DefaultInstall" /f
%_Nul3% reg.exe unload HKLM\OFFSOFT
)
goto :cabonline

:cabonline
expand.exe -f:*Windows*.cab %package% "!cab_dir!" %_Null%
cd /d "!cab_dir!"
%_dism2%:"!cab_dir!" %dismtarget% /Add-Package /packagepath:.
del /f /q "*%kb%*.cab"
cd /d "!repo!\Additional\_NotAllowedOffline"
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
if %IEcab% equ 1 for /f "tokens=3 delims=-" %%V in ('dir /b %package%') do set kb=%%V
if /i %kb%==%rollup% (set /a _sum-=1&set /a _msu-=1&goto :eof)
if /i %kb%==%ssu1st% (set /a _sum-=1&set /a _msu-=1&goto :eof)
if /i %kb%==%ssu2nd% (set /a _sum-=1&set /a _msu-=1&goto :eof)
if /i %kb%==%sha2cs% (set /a _sum-=1&set /a _msu-=1&goto :eof)
if /i %kb%==KB917607 (if exist "!mountdir!\Windows\servicing\packages\*Winhelp-Update-Client*.mum" set /a _sum-=1&set /a _msu-=1&goto :eof)
if /i %kb%==KB971033 (if exist "!mountdir!\Windows\servicing\packages\*WindowsActivationTechnologies*.mum" set /a _sum-=1&set /a _msu-=1&goto :eof)
if /i %kb%==KB2670838 (if exist "!mountdir!\Windows\servicing\packages\*PlatformUpdate-Win7-SRV08R2*.mum" set /a _sum-=1&set /a _msu-=1&goto :eof)
if /i %kb%==KB2592687 (if exist "!mountdir!\Windows\servicing\packages\*RDP-WinIP-Package*.mum" set /a _sum-=1&set /a _msu-=1&goto :eof)
if /i %kb%==KB2830477 (if exist "!mountdir!\Windows\servicing\packages\*RDP-BlueIP-Package*.mum" set /a _sum-=1&set /a _msu-=1&goto :eof)
if /i %kb%==KB982861 (if exist "!mountdir!\Windows\servicing\packages\*InternetExplorer*9.4.*.mum" set /a _sum-=1&set /a _msu-=1&goto :eof)
if /i %kb%==KB2841134 (if exist "!mountdir!\Windows\servicing\packages\*InternetExplorer*11.2.*.mum" set /a _sum-=1&set /a _cab-=1&goto :eof)
if /i %kb%==KB2849696 (if exist "!mountdir!\Windows\servicing\packages\*IE-Spelling-Parent-Package-English*11.2.*.mum" set /a _sum-=1&set /a _msu-=1&goto :eof)
if /i %kb%==KB2849697 (if exist "!mountdir!\Windows\servicing\packages\*IE-Hyphenation-Parent-Package-English*11.2.*.mum" set /a _sum-=1&set /a _msu-=1&goto :eof)
if /i %kb%==KB3191566 (if exist "!mountdir!\Windows\servicing\packages\*WinMan-WinIP*7.3.7601.16384.mum" set /a _sum-=1&set /a _msu-=1&goto :eof)
for %%G in %rdp8% do if /i !kb!==%%G (call set /a _sum-=1&call set /a _msu-=1&goto :eof)
if %ssucsuesu%==0 if /i "%cat%"=="Security Updates" if not exist "!mountdir!\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" (
if exist "!cab_dir!\check\" rd /s /q "!cab_dir!\check\"
mkdir "!cab_dir!\check"
if %msu% equ 1 (expand.exe -f:*Windows*.xml %package% "!cab_dir!\check" %_Null%) else (expand.exe -f:update.mum %package% "!cab_dir!\check" %_Null%)
findstr /i /m "Package_for_RollupFix" "!cab_dir!\check\*" %_Nul3% && goto :eof
)
if exist "!mountdir!\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" (
if exist "!cab_dir!\check\" rd /s /q "!cab_dir!\check\"
mkdir "!cab_dir!\check"
if %msu% equ 1 (expand.exe -f:*Windows*.xml %package% "!cab_dir!\check" %_Null%) else (expand.exe -f:update.mum %package% "!cab_dir!\check" %_Null%)
findstr /i /m "Package_for_RollupFix" "!cab_dir!\check\*" %_Nul3% && (if %ssucsuesu%==0 goto :eof) || (set /a _sum-=1&if %msu% equ 1 (set /a _msu-=1&goto :eof) else (set /a _cab-=1&goto :eof))
)
set inver=0
if /i %kb%==%hv_integ_kb% if exist "!mountdir!\Windows\servicing\packages\*Hyper-V-Integration-Services*.mum" (
for /f "tokens=6,7 delims=~." %%i in ('dir /b /a:-d /od "!mountdir!\Windows\servicing\packages\*Hyper-V-Integration-Services*.mum"') do set inver=%%i%%j
if !inver! geq !hv_integ_vr! (set /a _sum-=1&set /a _cab-=1&goto :eof)
)
set "mumcheck=package_*_for_%kb%*6.1*.mum"
if /i not "%LDRbranch%"=="YES" set "mumcheck=package_*_for_%kb%~*6.1*.mum"
if %IEcab% equ 1 set "mumcheck=package_for_%kb%*.mum"
if /i not "%LDRbranch%"=="YES" if %IEcab% equ 1 set "mumcheck=package_for_%kb%~*.mum"
for %%G in %gdrlist% do if /i !kb!==%%G (call set "mumcheck=package_for_%kb%~*6.1*.mum")
set inver=0
if /i %kb%==KB2952664 if exist "!mountdir!\Windows\servicing\packages\%mumcheck%" (
for /f "tokens=6,7 delims=~." %%i in ('dir /b /a:-d /od "!mountdir!\Windows\servicing\packages\%mumcheck%"') do set inver=%%i%%j
mkdir "!cab_dir!\check"
if %msu% equ 1 (expand.exe -f:*Windows*.cab "%package%" "!cab_dir!\check" %_Null%) else (copy /y "%package%" "!cab_dir!\check\" %_Nul1%)
expand.exe -f:package_for_%kb%*.mum "!cab_dir!\check\*.cab" "!cab_dir!\check" %_Null%
for /f "tokens=6,7 delims=~." %%i in ('dir /b /a:-d "!cab_dir!\check\package_for_%kb%*.mum"') do call set kbver=%%i%%j
rd /s /q "!cab_dir!\check\"
if !inver! geq !kbver! (set /a _sum-=1&if %msu% equ 1 (set /a _msu-=1&goto :eof) else (set /a _cab-=1&goto :eof))
)
if /i not %kb%==KB2952664 if exist "!mountdir!\Windows\servicing\packages\%mumcheck%" (set /a _sum-=1&if %msu% equ 1 (set /a _msu-=1&goto :eof) else (set /a _cab-=1&goto :eof))
set /a count+=1
if %verb%==1 (
echo %count%: %package%
)
if %msu% equ 1 (expand.exe -f:*Windows*.cab "%package%" "!cab_dir!" %_Null%) else (copy /y "%package%" "!cab_dir!\" %_Nul1%)
if /i %kb%==KB2849696 ren "!cab_dir!\Windows6.3-KB2849696-x86.cab" IE11-Windows6.1-KB2849696-%arch%.cab
if /i %kb%==KB2849697 ren "!cab_dir!\Windows6.3-KB2849697-x86.cab" IE11-Windows6.1-KB2849697-%arch%.cab
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
if /i "%cat%"=="WMF Updates" for %%G in (2872035,2872047,2809215,3033929) do (if exist "*%%G*.cab" del /f /q "*%%G*.cab" %_Nul1%)
for /f "tokens=* delims=" %%# in ('dir /b /a:-d *.cab') do (set "package=%%#"&set "dest=%%~n#"&call :mum2)
goto :eof

:mum2
if %listc% geq %ac% (set /a AC+=100&set /a list+=1&set ldr%list%=%ldr%&set ldr=)
if not exist "%dest%\" mkdir "%dest%"
set /a count+=1
set /a allcount+=1
set /a listc+=1
for /f "tokens=2 delims=-" %%V in ('echo "%package%"') do set kb=%%V
if not exist "%dest%\*.manifest" (
if %verb%==1 echo %count%/%_sum%: %package%
expand.exe -f:* "%package%" "%dest%" %_Null% || (set "ldr=!ldr! /packagepath:%package%"&goto :eof)
)
if /i not "%LDRbranch%"=="YES" (set "ldr=!ldr! /packagepath:%dest%\update.mum"&goto :eof)
for %%G in %gdrlist% do if /i !kb!==%%G (call set "ldr=!ldr! /packagepath:%dest%\update.mum"&goto :eof)
if exist "%dest%\update-bf.mum" (set "ldr=!ldr! /packagepath:%dest%\update-bf.mum") else (set "ldr=!ldr! /packagepath:%dest%\update.mum")
if not exist "%dest%\*cablist.ini" goto :eof
expand.exe -f:* "%dest%\*.cab" "%dest%" %_Null% || (set "ldr=!ldr! /packagepath:%package%")
del /f /q "%dest%\*cablist.ini" %_Nul3%
del /f /q "%dest%\*.cab" %_Nul3%
goto :eof

:listdone
if %listc% leq %ac% (set ldr%list%=%ldr%)
set lc=1

:PP
if %lc% gtr %list% (
if /i "%cat%"=="Security Updates" call :diagtrack %_Nul3%
if /i "%cat%"=="IE11 Updates" if exist "!mountdir!\Windows\servicing\packages\Microsoft-Windows-EmbeddedCore-Package*amd64*.mum" call :iembedded %_Nul3%
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

:iembedded
if %online%==1 (
set ksub1=SOFTWARE
) else (
set ksub1=OFFSOFT
reg.exe load HKLM\!ksub1! "!mountdir!\Windows\System32\config\SOFTWARE"
)
reg.exe delete "HKLM\%ksub1%\Wow6432Node\Microsoft\Active Setup\Installed Components\{89820200-ECBD-11cf-8B85-00AA005B4383}" /f
reg.exe add "HKLM\%ksub1%\Wow6432Node\Microsoft\Active Setup\Installed Components\{89820200-ECBD-11cf-8B85-00AA005B4383}" /f /v IsInstalled /t REG_DWORD /d 0
if %online%==0 (
reg.exe unload HKLM\%ksub1%
)
goto :eof

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
echo reg.exe add %T_USR%\EOSNotify /f /v DontRemindMe /t REG_DWORD /d 1
echo reg.exe add %T_USR%\EOSNotify /f /v DiscontinueEOS /t REG_DWORD /d 1
echo reg.exe add %T_USR%\EOSNotify /f /v LastRunTimestamp /t REG_QWORD /d 0x0
echo reg.exe add %T_USR%\EOSNotify /f /v TimestampOverride /t REG_QWORD /d 0x0
echo reg.exe add %T_USR%\SipNotify /f /v DontRemindMe /t REG_DWORD /d 1
echo reg.exe add %T_USR%\SipNotify /f /v DateModified /t REG_QWORD /d 0x0
echo reg.exe add %T_USR%\SipNotify /f /v LastShown /t REG_QWORD /d 0x0
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
echo schtasks.exe /Change /DISABLE /TN "%T_Win%\End Of Support\Notify1"
echo schtasks.exe /Change /DISABLE /TN "%T_Win%\End Of Support\Notify2"
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
echo schtasks.exe /Delete /TN "%T_Win%\End Of Support\Notify1" /F
echo schtasks.exe /Delete /TN "%T_Win%\End Of Support\Notify2" /F
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
reg.exe add %T_USR%\EOSNotify /f /v DontRemindMe /t REG_DWORD /d 1
reg.exe add %T_USR%\EOSNotify /f /v DiscontinueEOS /t REG_DWORD /d 1
reg.exe add %T_USR%\EOSNotify /f /v LastRunTimestamp /t REG_QWORD /d 0x0
reg.exe add %T_USR%\EOSNotify /f /v TimestampOverride /t REG_QWORD /d 0x0
reg.exe add %T_USR%\SipNotify /f /v DontRemindMe /t REG_DWORD /d 1
reg.exe add %T_USR%\SipNotify /f /v DateModified /t REG_QWORD /d 0x0
reg.exe add %T_USR%\SipNotify /f /v LastShown /t REG_QWORD /d 0x0
) else (
reg.exe load HKLM\OFFUSR "!mountdir!\Users\Default\ntuser.dat"
reg.exe add %T_US2%\EOSNotify /f /v DontRemindMe /t REG_DWORD /d 1
reg.exe add %T_US2%\EOSNotify /f /v DiscontinueEOS /t REG_DWORD /d 1
reg.exe add %T_US2%\EOSNotify /f /v LastRunTimestamp /t REG_QWORD /d 0x0
reg.exe add %T_US2%\EOSNotify /f /v TimestampOverride /t REG_QWORD /d 0x0
reg.exe add %T_US2%\SipNotify /f /v DontRemindMe /t REG_DWORD /d 1
reg.exe add %T_US2%\SipNotify /f /v DateModified /t REG_QWORD /d 0x0
reg.exe add %T_US2%\SipNotify /f /v LastShown /t REG_QWORD /d 0x0
reg.exe unload HKLM\OFFUSR
)
goto :eof

:regfix
if exist "!mountdir!\Windows\WHD-regfix.txt" goto :eof
echo.
echo ============================================================
echo Processing Hotfixes registry tweaks
echo ============================================================
call :regfixes %_Nul3%
goto :eof

:regfixes
if %online%==1 (
set ksub1=SOFTWARE&set ksub2=SYSTEM
) else (
set ksub1=OFFSOFT&set ksub2=OFFSYST
reg.exe load HKLM\!ksub1! "!mountdir!\Windows\System32\config\SOFTWARE"
reg.exe load HKLM\!ksub2! "!mountdir!\Windows\System32\config\SYSTEM"
)
reg.exe add "HKLM\%ksub1%\Microsoft\Cryptography\Calais" /f /v "TransactionTimeoutDelay" /t REG_DWORD /d 5
reg.exe add "HKLM\%ksub1%\Microsoft\Cryptography\OID\EncodingType 0\CertDllCreateCertificateChainEngine\Config" /f /v "MinRsaPubKeyBitLength" /t REG_DWORD /d 512
reg.exe add "HKLM\%ksub1%\Microsoft\Cryptography\OID\EncodingType 0\CertDllCreateCertificateChainEngine\Config" /f /v "EnableWeakSignatureFlags" /t REG_DWORD /d 2
reg.exe add "HKLM\%ksub1%\Microsoft\MSMQ\Parameters" /f /v "IgnoreOSNameValidationForReceive" /t REG_DWORD /d 1
reg.exe add "HKLM\%ksub1%\Microsoft\Windows\CurrentVersion\Policies\System" /f /v "EnableLinkedConnections" /t REG_DWORD /d 1
reg.exe add "HKLM\%ksub1%\Microsoft\Windows\CurrentVersion\Policies\System" /f /v "InteractiveLogonFirst" /t REG_DWORD /d 1
reg.exe add "HKLM\%ksub1%\Microsoft\Windows NT\CurrentVersion\Windows" /f /v "UMPDSecurityLevel" /t REG_DWORD /d 2
reg.exe add "HKLM\%ksub1%\Policies\Group Policy" /f /v "PurgeRSOP" /t REG_DWORD /d 1
reg.exe add "HKLM\%ksub1%\Policies\Microsoft\Netlogon\Parameters" /f /v "AddressLookupOnPingBehavior" /t REG_DWORD /d 2
reg.exe add "HKLM\%ksub1%\Policies\Microsoft\Windows\Group Policy" /f /v "EnableLocalStoreOverride" /t REG_DWORD /d 1
reg.exe add "HKLM\%ksub1%\Policies\Microsoft\Windows\Installer" /f /v "NoUACforHashMissing" /t REG_DWORD /d 1
reg.exe add "HKLM\%ksub1%\Policies\Microsoft\Windows\SmartCardCredentialProvider" /f /v "AllowVirtualSmartCardPinChangeAndUnlock" /t REG_DWORD /d 1
reg.exe add "HKLM\%ksub2%\ControlSet001\Services\BFE\Parameters" /f /v "MaxEndpointCountMult" /t REG_DWORD /d 10
reg.exe add "HKLM\%ksub2%\ControlSet001\Services\CSC\Parameters" /f /v "FormatDatabase" /t REG_DWORD /d 1
reg.exe add "HKLM\%ksub2%\ControlSet001\Services\LanmanServer\Parameters" /f /v "ABELevel" /t REG_DWORD /d 2
reg.exe add "HKLM\%ksub2%\ControlSet001\Services\LanmanServer\Parameters" /f /v "AsynchronousCredits" /t REG_DWORD /d 4132
reg.exe add "HKLM\%ksub2%\ControlSet001\Services\LanmanServer\Parameters" /f /v "DisableStrictNameChecking" /t REG_DWORD /d 1
reg.exe add "HKLM\%ksub2%\ControlSet001\Services\LanmanServer\Parameters" /f /v "OptionalNames" /t REG_SZ /d aliasname
reg.exe add "HKLM\%ksub2%\ControlSet001\Services\LanmanWorkstation\Parameters" /f /v "ExtendedSessTimeout" /t REG_DWORD /d 1152
reg.exe add "HKLM\%ksub2%\ControlSet001\Services\MRxDAV\Parameters" /f /v "FsCtlRequestTimeoutInSec" /t REG_DWORD /d 3600
reg.exe add "HKLM\%ksub2%\ControlSet001\Services\WebClient\Parameters" /f /v "EnableCTLFiltering" /t REG_DWORD /d 1
reg.exe add "HKLM\%ksub2%\ControlSet001\Services\WebClient\Parameters" /f /v "EnableAutoCertSelection" /t REG_DWORD /d 1
reg.exe add "HKLM\%ksub2%\ControlSet001\Services\RemoteAccess\Parameters\Ip" /f /v "DisableMulticastForwarding" /t REG_DWORD /d 0
reg.exe add "HKLM\%ksub2%\ControlSet001\Services\usbhub\HubG" /f /v "DisableOnSoftRemove" /t REG_DWORD /d 1
reg.exe add "HKLM\%ksub2%\ControlSet001\Control\CrashControl" /f /v "MaxSecondaryDataDumpSize" /t REG_DWORD /d 4294967295
reg.exe add "HKLM\%ksub2%\ControlSet001\Control\Print" /f /v "DnsOnWire" /t REG_DWORD /d 1
reg.exe add "HKLM\%ksub2%\ControlSet001\Control\Print" /f /v "SplWOW64TimeOutSeconds" /t REG_DWORD /d 576
reg.exe add "HKLM\%ksub2%\ControlSet001\Control\Pnp" /f /v "BootOptions" /t REG_DWORD /d 0
reg.exe add "HKLM\%ksub2%\ControlSet001\Control\Pnp" /f /v "DisableCDDB" /t REG_DWORD /d 0
reg.exe add "HKLM\%ksub2%\ControlSet001\Control\Pnp" /f /v "DontStartRawDevices" /t REG_DWORD /d 0
reg.exe add "HKLM\%ksub2%\ControlSet001\Control\PnP" /f /v "PollBootPartitionTimeout" /t REG_DWORD /d 120000
reg.exe add "HKLM\%ksub2%\ControlSet001\Control\usbstor\054C00C1" /f /v "MaximumTransferLength" /t REG_DWORD /d 2097120
if %online%==0 (
reg.exe unload HKLM\%ksub1%
reg.exe unload HKLM\%ksub2%
)
for %%a in (ServiceProfiles\LocalService,ServiceProfiles\NetworkService,System32\config\systemprofile) do if exist "!mountdir!\Windows\%%a\AppData\LocalLow\*" (
attrib -S -I "!mountdir!\Windows\%%a\AppData\LocalLow\Microsoft\CryptnetUrlCache"
for /f "tokens=* delims=" %%i in ('dir /b /as "!mountdir!\Windows\%%a\AppData\LocalLow\Microsoft\CryptnetUrlCache\*"') do (attrib -S -I "%%~i")
del /s /f /q "!mountdir!\Windows\%%a\AppData\LocalLow\Microsoft\CryptnetUrlCache\Content\*"
del /s /f /q "!mountdir!\Windows\%%a\AppData\LocalLow\Microsoft\CryptnetUrlCache\MetaData\*"
for /f "tokens=* delims=" %%i in ('dir /b /s "!mountdir!\Windows\%%a\AppData\LocalLow\Microsoft\CryptnetUrlCache\*"') do (attrib +S "%%~i")
attrib +S "!mountdir!\Windows\%%a\AppData\LocalLow\Microsoft\CryptnetUrlCache"
)
echo cookie>"!mountdir!\Windows\WHD-regfix.txt"
goto :eof

:stacklimit
echo ============================================================
echo *** ATTENTION ***
echo ============================================================
echo.
echo Installing servicing stack update %ssulmt%
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
call :cleanmanual
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
if %winbuild% lss 9600 if %_ADK% equ 0 if /i "!dismroot!"=="dism.exe" if not exist "!_imagex!" goto :eof
call :rebuild
cd /d "!_work!"
goto :eof

:rebuild
set verb=1
if not "%1"=="" (
set verb=0
set "_wimfilb=!_wimfile!"
set "_wimfile=winre.wim"
set "_wimpatb=!_wimpath!"
set "_wimpath=!_work!"
)
if %verb%==1 (
echo.
echo ============================================================
echo Rebuilding %_wimfile%
echo ============================================================
)
cd /d "!_wimpath!"
if %winbuild% geq 9600 (
if %keep%==1 (
for %%# in (%indices%) do %_dism2%:"!cab_dir!" /Export-Image /SourceImageFile:%_wimfile% /SourceIndex:%%# /DestinationImageFile:temp.wim
) else (
%_dism2%:"!cab_dir!" /Export-Image /SourceImageFile:%_wimfile% /All /DestinationImageFile:temp.wim
)
if !errorlevel! equ 0 (move /y temp.wim %_wimfile% %_Nul1%) else (del /f /q temp.wim %_Nul3%)
goto :eof
)
if not exist "!_imagex!" goto :eof
if %keep%==1 (
for %%# in (%indices%) do "!_imagex!" /TEMP "!cab_dir!" /EXPORT %_wimfile% %%# temp.wim
) else (
"!_imagex!" /TEMP "!cab_dir!" /EXPORT %_wimfile% * temp.wim
)
if !errorlevel! equ 0 (move /y temp.wim %_wimfile% %_Nul1%) else (del /f /q temp.wim %_Nul3%)
goto :eof

:boots
  xcopy /CDRY "!mountdir!\sources" "!target!\sources\" %_Nul3%
  del /f /q "!target!\sources\background.bmp" %_Nul3%
  del /f /q "!target!\sources\testplugin.dll" %_Nul3%
  if /i %arch%==x64 if not exist "!target!\efi\boot\%efifile%" (
  mkdir "%target%\efi\boot" %_Nul3%
  copy /y "!mountdir!\Windows\Boot\EFI\bootmgfw.efi" "!target!\efi\boot\%efifile%" %_Nul1%
  copy /y "!mountdir!\Windows\Boot\EFI\bootmgr.efi" "!target!\" %_Nul1%
  )
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
  call :cleanmanual
  %_dism2%:"!cab_dir!" /Unmount-Wim /MountDir:"!winremount!" /Commit
  if %errorlevel% neq 0 goto :E_MOUNT
  set "mountdir=!mountdib!"
  set dismtarget=/image:"!mountdib!"
  if %winbuild% lss 9600 if %_ADK% equ 0 if /i "!dismroot!"=="dism.exe" if not exist "!_imagex!" goto :eof
  call :rebuild winre
  set "_wimfile=!_wimfilb!"
  set "_wimpath=!_wimpatb!"
goto :eof

:cleanmanual
if %online%==1 goto :eof
if exist "!mountdir!\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" if exist "!mountdir!\Windows\WinSxS\Backup\*" (
del /f /q "!mountdir!\Windows\WinSxS\Backup\*" %_Nul3%
)
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
if exist "!mountdir!\Windows\inf\*.log" (
del /f /q "!mountdir!\Windows\inf\*.log" %_Nul3%
)
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
set "showdism=Windows 8.1 ADK"
set "Path=%DandIRoot%\%xOS%\DISM;%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
)
if exist "%DandIRoot%\%xOS%\Oscdimg\oscdimg.exe" (
set "_oscdimg=%DandIRoot%\%xOS%\Oscdimg\oscdimg.exe"
)
if exist "%DandIRoot%\%xOS%\DISM\imagex.exe" (
set "_imagex=%DandIRoot%\%xOS%\DISM\imagex.exe"
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
if %winbuild% gtr 9600 set "showdism=Windows 10 ADK"
if %winbuild% gtr 9600 set "Path=%DandIRoot%\%xOS%\DISM;%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
)
if exist "%DandIRoot%\%xOS%\Oscdimg\oscdimg.exe" (
set "_oscdimg=%DandIRoot%\%xOS%\Oscdimg\oscdimg.exe"
)
if exist "%DandIRoot%\%xOS%\DISM\imagex.exe" (
set "_imagex=%DandIRoot%\%xOS%\DISM\imagex.exe"
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
if %win7% equ 1 echo - Current OS / Enter %SystemDrive%
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
if not exist "!_pp!\Windows7-*" (echo.&echo ERROR: Specified location is not valid&pause&goto :repomenu)
set "repo=!_pp!"
goto :mainmenu

:dismmenu
@cls
set _pp=
echo ============================================================
echo Enter the full path for dism.exe
echo.
echo or just press 'Enter' to return to options menu
echo ============================================================
echo.
set /p _pp=
if not defined _pp goto :mainmenu
set "_pp=%_pp:"=%"
if not exist "!_pp!" (echo.&echo ERROR: DISM path not found&pause&goto :dismmenu)
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
if %win7% neq 1 (set "target="&echo [1] Select offline target) else (echo [1] Target ^(%arch%^): Current Online OS)
) else (
if /i "!target!"=="" (echo [1] Select offline target) else (echo [1] Target ^(%arch%^): "!target!")
)
echo.
if "!repo!"=="" (echo [2] Select updates location) else (echo [2] WHD Repo: "!repo!")
echo.
echo [3] LDR branch: %LDRbranch%     [4] IE11     : %IE11%     [5] RDP       : %RDP%
echo [6] Hotfixes  : %Hotfix%     [7] WMF      : %WMF%     [A] KB971033  : %WAT%
echo [W] Windows10 : %Windows10%     [S] ADLDS    : %ADLDS%     [R] RSAT      : %RSAT%
echo.
if /i "!target!"=="%SystemDrive%" (
echo [L] Online installation limit: %onlinelimit% updates
) else (
echo [D] DISM: "!showdism!"
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
choice /c 1234567890AWSRLDEMIKU /n /m "Change a menu option, press 0 to start the process, or 9 to exit: "
if errorlevel 21 (if %wimfiles%==1 (if %winre%==1 (set winre=0) else (set winre=1)))&goto :mainmenu
if errorlevel 20 (if %wimfiles%==1 if %imgcount% gtr 1 (if %keep%==1 (set keep=0) else (set keep=1)))&goto :mainmenu
if errorlevel 19 (if %wimfiles%==1 if %imgcount% gtr 1 (goto :indexmenu))&goto :mainmenu
if errorlevel 18 (if %wimfiles%==1 (goto :mountmenu))&goto :mainmenu
if errorlevel 17 goto :extractmenu
if errorlevel 16 goto :dismmenu
if errorlevel 15 goto :countmenu
if errorlevel 14 (if /i "%RSAT%"=="YES" (set "RSAT=NO ") else (set RSAT=YES))&goto :mainmenu
if errorlevel 13 (if /i "%ADLDS%"=="YES" (set "ADLDS=NO ") else (set ADLDS=YES))&goto :mainmenu
if errorlevel 12 (if /i "%Windows10%"=="YES" (set "Windows10=NO ") else (set Windows10=YES))&goto :mainmenu
if errorlevel 11 (if /i "%WAT%"=="YES" (set "WAT=NO ") else (set WAT=YES))&goto :mainmenu
if errorlevel 10 goto :mainboard
if errorlevel 9 goto :eof
if errorlevel 8 goto :mainmenu
if errorlevel 7 (if /i "%WMF%"=="YES" (set "WMF=NO ") else (set WMF=YES))&goto :mainmenu
if errorlevel 6 (if /i "%Hotfix%"=="YES" (set "Hotfix=NO ") else (set Hotfix=YES))&goto :mainmenu
if errorlevel 5 (if /i "%RDP%"=="YES" (set "RDP=NO ") else (set RDP=YES))&goto :mainmenu
if errorlevel 4 (if /i "%IE11%"=="YES" (set "IE11=NO ") else (set IE11=YES))&goto :mainmenu
if errorlevel 3 (if /i "%LDRbranch%"=="YES" (set "LDRbranch=NO ") else (set LDRbranch=YES))&goto :mainmenu
if errorlevel 2 goto :repomenu
if errorlevel 1 goto :targetmenu
goto :mainmenu

:ISO
if not exist "!_oscdimg!" if not exist "!_work!\oscdimg.exe" if not exist "!_work!\cdimage.exe" goto :eof
if "!isodir!"=="" set "isodir=!_work!"
for /f "tokens=2 delims==." %%# in ('wmic os get localdatetime /value') do set "_date=%%#"
set "isodate=%_date:~0,4%-%_date:~4,2%-%_date:~6,2%"
if defined isover (set isofile=Win7_%isover%_%arch%_%isodate%.iso) else (set isofile=Win7_%arch%_%isodate%.iso)
set /a rnd=%random%
if exist "!isodir!\%isofile%" ren "!isodir!\%isofile%" "%rnd%_%isofile%"
echo.
echo ============================================================
echo Creating updated ISO file...
echo ============================================================
if exist "!_oscdimg!" (set _ff="!_oscdimg!") else if exist "!_work!\oscdimg.exe" (set _ff="!_work!\oscdimg.exe") else (set _ff="!_work!\cdimage.exe")
cd /d "!target!"
if exist "efi\microsoft\boot\efisys.bin" (
!_ff! -m -o -u2 -udfver102 -bootdata:2#p0,e,b".\boot\etfsboot.com"#pEF,e,b".\efi\microsoft\boot\efisys.bin" -l"%isover%u" . "%isofile%"
) else (
!_ff! -m -o -u2 -udfver102 -b".\boot\etfsboot.com" -l"%isover%u" . "%isofile%"
)
set errcode=%errorlevel%
if %errcode% equ 0 move /y "%isofile%" "!isodir!\" %_Nul3%
cd /d "!_work!"
if %errcode% equ 0 if %delete_source% equ 1 rmdir /s /q "!target!\" %_Nul1%
if %errcode% equ 0 if exist "!_work!\DVD7UI\" rmdir /s /q "!_work!\DVD7UI\" %_Nul1%
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
