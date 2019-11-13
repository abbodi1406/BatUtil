@setlocal
@set uiv=v7.4
@echo off
:: set to 1 to enable debug mode (you must also set target, and repo if updates are not beside the script)
set _Debug=0

cd /d "%~dp0"
:: when changing below options, be sure to set the new values between = and " marks

:: target image or wim file
:: leave it blank to automatically detect wim file next to the script, or current online os
set "target="

:: updates location, leave it blank to automatically detect the current script directory
set "repo="

:: dism.exe tool path (default is the system's if the host os is win10)
set "dismroot=dism.exe"

:: enable .NET 3.5 feature, set to 0 to skip it
set net35=1

:: optional, specify custom "folder" path for microsoft-windows-netfx3-ondemand-package.cab
set "net35source="

:: Cleanup OS images to "compress" superseded components (might take long time to complete)
set cleanup=0

:: Rebase OS images to "remove" superseded components (warning: break "Reset this PC" feature)
:: require first to set cleanup=1
set resetbase=0

:: update winre.wim if detected inside install.wim, set to 0 to skip it
set winre=1

:: optional, set directory for temporary extracted files, default on same drive as the script
set "_cabdir=W10UItemp"

:: optional, set mount directory for updating wim files, default on same drive as the script
set "mountdir=W10UImount"
set "winremount=W10UImountre"

:: # Manual options #

:: create new iso file if the target is a distribution folder
:: require ADK installed, or placing oscdimg.exe or cdimage.exe next to the script
set iso=1

:: folder path for iso file, leave it blank to create in the current script directory
set "isodir="

:: set this to 1 to delete DVD distribution folder after creating updated ISO
set delete_source=0

:: set this to 1 to start the process directly once you execute the script
:: make sure you set the above options correctly first
set autostart=0

:: ##################################################################
:: # NORMALY THERE IS NO NEED TO CHANGE ANYTHING BELOW THIS COMMENT #
:: ##################################################################

title Installer for Windows 10 Updates
set rSxS=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\SideBySide\Configuration
set "SysPath=%Windir%\System32"
if exist "%Windir%\Sysnative\reg.exe" (set "SysPath=%Windir%\Sysnative")
set "Path=%SysPath%;%Windir%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
set "xOS=amd64"
set "oscdimgroot=%SysPath%\oscdimg.exe"
if /i %PROCESSOR_ARCHITECTURE%==x86 (
  if not defined PROCESSOR_ARCHITEW6432 set "xOS=x86"
)
reg query HKU\S-1-5-19 1>nul 2>nul || goto :E_Admin
set "_logpath=%~dpn0"
set "_workdir=%~dp0"
set "_workdir=%_workdir:~0,-1%"

if not exist "W10UI.ini" goto :proceed
findstr /i \[W10UI-Configuration\] W10UI.ini 1>nul || goto :proceed
for %%# in (
target
repo
dismroot
net35
net35source
cleanup
resetbase
winre
_cabdir
mountdir
winremount
iso
isodir
delete_source
autostart
) do (
call :ReadINI %%#
)
goto :proceed

:ReadINI
findstr /b /i /c:"%1 " W10UI.ini 1>nul && for /f "tokens=2 delims==" %%# in ('findstr /b /i /c:"%1 " W10UI.ini') do set "%1=%%#"
goto :eof

:proceed
setlocal EnableDelayedExpansion

if %_Debug% neq 0 set autostart=1
if %_Debug% equ 0 (
  set "_Nul1=1>nul"
  set "_Nul2=2>nul"
  set "_Nul6=2^>nul"
  set "_Nul3=1>nul 2>nul"
  set "_Pause=pause >nul"
  set "_Goto=goto :mainmenu"
  call :Begin
) else (
  set "_Nul1="
  set "_Nul2="
  set "_Nul6="
  set "_Nul3="
  set "_Pause="
  set "_Goto=exit /b"
  echo.
  echo Running in Debug Mode...
  echo The window will be closed when finished
  copy /y nul "!_workdir!\#.rw" 1>nul 2>nul && (if exist "!_workdir!\#.rw" del /f /q "!_workdir!\#.rw") || (set "_logpath=!_tempdir!\%~n0"&set "_cabdir=%~dp0temp\W10UItemp")
  @echo on
  @prompt $G
  @call :Begin >"!_logpath!.tmp" 2>&1 &cmd /u /c type "!_logpath!.tmp">"!_logpath!_Debug.log"&del "!_logpath!.tmp"
)
@exit /b

:Begin
set "showdism=%dismroot%"
if "%repo%"=="" set "repo=!_workdir!"
if "%isodir%"=="" set "isodir=!_workdir!"
set _drv=%~d0
set _ntf=NTFS
if /i not "%_drv%"=="%SystemDrive%" for /f "tokens=2 delims==" %%# in ('"wmic volume where DriveLetter='%_drv%' get FileSystem /value"') do set "_ntf=%%#"
if /i not "%_ntf%"=="NTFS" set _drv=%SystemDrive%
if /i "%_cabdir%"=="W10UItemp" set "_cabdir=%_drv%\W10UItemp"
if /i "%mountdir%"=="W10UImount" set "mountdir=%_drv%\W10UImount"
if /i "%winremount%"=="W10UImountre" set "winremount=%_drv%\W10UImountre"
set /a rnd=%random%
set "mountdir=%mountdir%_%rnd%"
set "winremount=%winremount%_%rnd%"
set "_cabdir=%_cabdir%_%rnd%"
if exist "%_cabdir%" (
echo.
echo ============================================================
echo Cleaning temporary extraction folder...
echo ============================================================
echo.
rmdir /s /q "%_cabdir%" %_Nul1%
)
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
set _Enable=0
set _wim=0
if exist "*.wim" (for %%# in ("*.wim") do (call set /a _wim+=1))
if "%target%"=="" if %_wim%==1 (for %%# in ("*.wim") do set "target=%%~f#"&set "targetname=%%#")
if "%target%"=="" set "target=%SystemDrive%"
if "%target:~-1%"=="\" set "target=%target:~0,-1%"
if /i "%target%"=="%SystemDrive%" goto :check
echo %target%| findstr /E /I "\.wim" %_Nul1%
if %errorlevel%==0 (
set wim=1
for %%# in ("%target%") do set "targetname=%%~nx#"
) else (
if exist "%target%\sources\boot.wim" set dvd=1 
if exist "%target%\Windows\regedit.exe" set offline=1
)
if %offline%==0 if %wim%==0 if %dvd%==0 (set "target=%SystemDrive%"&goto :check)
if %offline%==1 (
dir /b "%target%\Windows\servicing\Version\10.0.*" %_Nul3% || (set "MESSAGE=Detected target offline image is not Windows 10"&goto :E_Target)
for /f "tokens=3 delims=." %%# in ('dir /b "%target%\Windows\servicing\Version\10.0.*"') do set build=%%#
set "mountdir=%target%"
if exist "%target%\Windows\SysWOW64\cmd.exe" (set arch=x64) else (set arch=x86)
)
if %dvd%==1 (
echo.
echo ============================================================
echo Please wait...
echo ============================================================
dir /b /s /adr "%target%\boot" %_Nul3% && set copytarget=1
dism /english /get-wiminfo /wimfile:"%target%\sources\install.wim" /index:1 | find /i "Version : 10.0" %_Nul1% || (set "MESSAGE=Detected install.wim version is not Windows 10"&goto :E_Target)
for /f "tokens=4 delims=:. " %%# in ('dism /english /get-wiminfo /wimfile:"%target%\sources\install.wim" /index:1 ^| find /i "Version :"') do set build=%%#
for /f "tokens=2 delims=: " %%# in ('dism /english /get-wiminfo /wimfile:"%target%\sources\install.wim" /index:1 ^| find /i "Architecture"') do set arch=%%#
for /f "tokens=2 delims=: " %%# in ('dism /english /get-wiminfo /wimfile:"%target%\sources\install.wim" ^| findstr "Index"') do set imgcount=%%#
for /f "tokens=2 delims=: " %%# in ('dism /english /get-wiminfo /wimfile:"%target%\sources\boot.wim" ^| findstr "Index"') do set bootimg=%%#
for /L %%# in (1,1,!imgcount!) do (
  for /f "tokens=1* delims=: " %%i in ('dism /english /get-wiminfo /wimfile:"%target%\sources\install.wim" /index:%%# ^| findstr /b /c:"Name"') do set name%%#="%%j"
  )
set "indices=*"
set "targetname=install.wim"
set wimfiles=1
)
if %wim%==1 (
echo.
echo ============================================================
echo Please wait...
echo ============================================================
dism /english /get-wiminfo /wimfile:"%target%" /index:1 | find /i "Version : 10.0" %_Nul1% || (set "MESSAGE=Detected wim version is not Windows 10"&goto :E_Target)
for /f "tokens=4 delims=:. " %%# in ('dism /english /get-wiminfo /wimfile:"%target%" /index:1 ^| find /i "Version :"') do set build=%%#
for /f "tokens=2 delims=: " %%# in ('dism /english /get-wiminfo /wimfile:"%target%" /index:1 ^| find /i "Architecture"') do set arch=%%#
for /f "tokens=2 delims=: " %%# in ('dism /english /get-wiminfo /wimfile:"%target%" ^| findstr "Index"') do set imgcount=%%#
for /L %%# in (1,1,!imgcount!) do (
  for /f "tokens=1* delims=: " %%i in ('dism /english /get-wiminfo /wimfile:"%target%" /index:%%# ^| findstr /b /c:"Name"') do set name%%#="%%j"
  )
set "indices=*"
set wimfiles=1
)

:check
if /i "%target%"=="%SystemDrive%" (
if %xOS%==amd64 (set arch=x64) else (set arch=x86)
reg.exe query %rSxS% /v W10UIclean %_Nul3% && (set onlineclean=1&set online=1&set cleanup=1)
reg.exe query %rSxS% /v W10UIrebase %_Nul3% && (set onlineclean=1&set online=1&set cleanup=1&set resetbase=1)
)
for /f "tokens=6 delims=[]. " %%# in ('ver') do set winbuild=%%#
if defined onlineclean goto :mainboard2
call :counter
if %_sum%==0 set "repo="
if /i not "%dismroot%"=="dism.exe" if exist "!dismroot!" goto :mainmenu
goto :checkadk

:mainboard
if %winbuild% lss 10240 (
if /i "%target%"=="%SystemDrive%" (%_Goto%)
if /i "%dismroot%"=="dism.exe" (%_Goto%)
)
if "%repo%"=="" (%_Goto%)
if "%repo:~-1%"=="\" set "repo=%repo:~0,-1%"
if "%_cabdir%"=="" (%_Goto%)
if "%_cabdir:~-1%"=="\" set "_cabdir=%_cabdir:~0,-1%"
if "%_cabdir:~-1%"==":" set "_cabdir=%_cabdir%"
if not "!_cabdir!"=="!_cabdir: =!" set "_cabdir=!_cabdir: =!"
if "%mountdir%"=="" (%_Goto%)
if "%mountdir:~-1%"=="\" set "mountdir=%mountdir:~0,-1%"
if "%mountdir:~-1%"==":" set "mountdir=%mountdir%\"
if not "!mountdir!"=="!mountdir: =!" set "mountdir=!mountdir: =!"
if /i "%target%"=="%SystemDrive%" (set dismtarget=/online&set "mountdir=%target%"&set online=1&set build=%winbuild%) else (set dismtarget=/image:"%mountdir%")

:mainboard2
if %_Debug% neq 0 set "
@cls
echo ============================================================
echo Running W10UI %uiv%
echo ============================================================
if %online%==1 (
net stop trustedinstaller %_Nul3%
net stop wuauserv %_Nul3%
del /f /q %systemroot%\Logs\CBS\* %_Nul3%
)
del /f /q %systemroot%\Logs\DISM\* %_Nul3%
if defined onlineclean (
if exist "%windir%\WinSxS\pending.xml" (
  echo.
  echo ============================================================
  echo ERROR: you must restart the system first before cleaning up
  echo ============================================================
  echo.
  echo.
  echo Press any key to exit.
  %_Pause%
  endlocal
  goto :eof
  )
set verb=0
set dismtarget=/online
set build=%winbuild%
call :cleanup
reg.exe delete %rSxS% /v W10UIclean /f %_Nul3%
reg.exe delete %rSxS% /v W10UIrebase /f %_Nul3%
goto :fin
)
if %dvd%==1 if %copytarget%==1 (
echo.
echo ============================================================
echo Copying DVD Drive contents to work directory
echo ============================================================
robocopy "%target%" "!_workdir!\DVD" /E /A-:R >nul
set "target=!_workdir!\DVD"
)
call :extract
if %_sum%==0 goto :fin
if %online%==1 (
call :update
if %net35%==1 call :enablenet35
)
if %offline%==1 (
call :update
if %net35%==1 call :enablenet35
)
if %wim%==1 (
if "%indices%"=="*" set "indices="&for /L %%# in (1,1,%imgcount%) do set "indices=!indices! %%#"
call :mount "%target%"
if /i "%targetname%" neq "winre.wim" (if exist "!_workdir!\winre.wim" del /f /q "!_workdir!\winre.wim" %_Nul1%)
)
if %dvd%==1 (
if "%indices%"=="*" set "indices="&for /L %%# in (1,1,%imgcount%) do set "indices=!indices! %%#"
call :mount "%target%\sources\install.wim"
if exist "!_workdir!\winre.wim" del /f /q "!_workdir!\winre.wim" %_Nul1%
set "indices="&set imgcount=%bootimg%&for /L %%# in (1,1,!imgcount!) do set "indices=!indices! %%#"
call :mount "%target%\sources\boot.wim"
if defined isoupdate (
  mkdir "%_cabdir%\du" %_Nul3%
  for %%i in (!isoupdate!) do expand.exe -r -f:* "%repo%\%%~i" "%_cabdir%\du" %_Nul1%
  xcopy /CEDRUY "%_cabdir%\du" "%target%\sources\" %_Nul3%
  if exist "%_cabdir%\du\replacementmanifests" xcopy /CERY "%_cabdir%\du\replacementmanifests" "%target%\sources\replacementmanifests\" %_Nul3%
  rmdir /s /q "%_cabdir%\du" %_Nul3%
)
xcopy /CRY "%target%\efi\microsoft\boot\fonts" "%target%\boot\fonts" %_Nul1%
if %net35%==1 if exist "%target%\sources\sxs" (rmdir /s /q "%target%\sources\sxs" %_Nul1%)
if exist "%target%\sources\uup" (rmdir /s /q "%target%\sources\uup" %_Nul1%)
)
goto :fin

:extract
if %build% gtr 18362 set _Enable=1 
if /i %arch%==x64 (set efifile=bootx64.efi&set sss=amd64) else (set efifile=bootia32.efi&set sss=x86)
for /f "delims= " %%T in ('robocopy /L . . /njh /njs') do set "TAB=%%T"
call :cleaner
if not exist "%_cabdir%" mkdir "%_cabdir%"
call :counter
if %_cab% neq 0 (set msu=0&for /f "delims=" %%# in ('dir /b "*Windows10*%arch%*.cab"') do (set "package=%%#"&call :cab1))
if %_msu% neq 0 (
echo.
echo ============================================================
echo Extracting .cab files from .msu files
echo ============================================================
echo.
set msucab=&set msu=1&set count=0
for /f "delims=" %%# in ('dir /b "*Windows10*%arch%*.msu"') do (set "package=%%#"&call :cab1)
)
if %_sum%==0 (echo.&echo All applicable updates are detected as installed&goto :eof)
echo.
echo ============================================================
echo Extracting files from update cabinets ^(.cab^)
echo *** This will require some disk space, please be patient ***
echo ============================================================
echo.
set count=0&set isoupdate=
for /f "delims=" %%# in ('dir /b "*Windows10*%arch%*.cab"') do (set "package=%%#"&set "dest=%_cabdir%\%%~n#"&call :cab2)
goto :eof

:cab1
for /f "tokens=2 delims=-" %%V in ('dir /b "%package%"') do set kb=%%V
set "mumcheck=package_for_%kb%~*.mum"
if %dvd%==0 if %wim%==0 if exist "%target%\Windows\servicing\packages\%mumcheck%" (
call :mumversion "%target%"
if !skip!==1 set /a _sum-=1&if %msu% equ 1 (set /a _msu-=1&goto :eof) else (set /a _cab-=1&goto :eof)
)
set "mumcheck=Package_for_RollupFix*.mum"
if %dvd%==0 if %wim%==0 if exist "%target%\Windows\servicing\packages\%mumcheck%" (
call :rollversion "%target%"
if !skip!==1 set /a _sum-=1&if %msu% equ 1 (set /a _msu-=1&goto :eof) else (set /a _cab-=1&goto :eof)
)
if %msu% equ 0 goto :eof
set "msucab=!msucab! %kb%"
set /a count+=1
echo %count%/%_msu%: !package!
expand.exe -f:*Windows*.cab "%package%" "%repo%" 1>nul 2>nul
goto :eof

:cab2
set /a count+=1
echo %count%/%_sum%: !package!
if exist "%dest%" rmdir /s /q "%dest%" %_Nul3%
mkdir "%dest%"
expand.exe -f:* "%package%" "%dest%" 1>nul 2>nul || (
  set directcab=!directcab! "!package!"
)
if not exist "%dest%\update.mum" (
  set isoupdate=!isoupdate! "!package!"
  goto :eof
)
if not exist "%dest%\*cablist.ini" goto :eof
expand.exe -f:* "%dest%\*.cab" "%dest%" 1>nul 2>nul || (
  set directcab=!directcab! "!package!"
)
del /f /q "%dest%\*cablist.ini" %_Nul3%
del /f /q "%dest%\*.cab" %_Nul3%
goto :eof

:update
set verb=1
set "mumtarget=%mountdir%"
if not "%1"=="" (
set "mumtarget_b=%mountdir%"
set "mumtarget=%winremount%"
set dismtarget=/image:"%winremount%"
set verb=0
)
if %verb%==1 (
echo.
echo ============================================================
echo Checking Updates...
echo ============================================================
)
set servicingstack=
set cumulative=
set netroll=
set discard=0
set discardre=0
set ldr=&set listc=0&set list=1&set AC=100
set _sum=0
if exist "*Windows10*%arch%*.cab" (for /f "delims=" %%# in ('dir /b "*Windows10*%arch%*.cab"') do (call set /a _sum+=1))
if exist "*Windows10*%arch%*.cab" (for /f "delims=" %%# in ('dir /b "*Windows10*%arch%*.cab"') do (set "package=%%#"&set "dest=%_cabdir%\%%~n#"&call :mum))
if %verb%==1 if %_sum%==0 if exist "%mountdir%\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" (echo.&echo All applicable updates are detected as installed&call set discard=1&goto :eof)
if %verb%==1 if %_sum%==0 (echo.&echo All applicable updates are detected as installed&goto :eof)
if %verb%==0 if %_sum%==0 (echo.&echo All applicable updates are detected as installed&call set discardre=1&goto :eof)
if %listc% lss %ac% (set "ldr%list%=%ldr%")
if defined servicingstack (
if %verb%==1 (
echo.
echo ============================================================
echo Installing servicing stack update...
echo ============================================================
)
"!dismroot!" %dismtarget% /NoRestart /Add-Package %servicingstack%
if not defined ldr if not defined cumulative call :cleanup
)
if not defined ldr if not defined cumulative goto :eof
if %verb%==1 (
echo.
echo ============================================================
echo Installing updates...
echo ============================================================
)
if defined ldr "!dismroot!" %dismtarget% /NoRestart /Add-Package %ldr%
if defined cumulative "!dismroot!" %dismtarget% /NoRestart /Add-Package %cumulative%
if %errorlevel% equ 1726 (
"!dismroot!" %dismtarget% /Get-Packages %_Nul1%
if defined cumulative "!dismroot!" %dismtarget% /NoRestart /Add-Package %cumulative%
)
call :cleanup
goto :eof

:mum
if %listc% geq %ac% (set /a AC+=100&set /a list+=1&set "ldr%list%=%ldr%"&set "ldr=")
set /a listc+=1
if not exist "%dest%\update.mum" (set /a _sum-=1&goto :eof)
if %build% geq 17763 if not exist "%mumtarget%\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" (
findstr /i /m "Package_for_RollupFix" "%dest%\update.mum" %_Nul3% || (findstr /i /m "Microsoft-Windows-NetFx" "%dest%\*.mum" %_Nul3% && (if exist "%dest%\*_*10.0.*.manifest" if not exist "%dest%\*_netfx4clientcorecomp*.manifest" (set "netroll=!netroll! /packagepath:%dest%\update.mum")))
findstr /i /m "Package_for_OasisAsset" "%dest%\update.mum" %_Nul3% && (if not exist "%mumtarget%\Windows\servicing\packages\*OasisAssets-Package*.mum" set /a _sum-=1&goto :eof)
findstr /i /m "WinPE" "%dest%\update.mum" %_Nul3% && (
  %_Nul3% findstr /i /m "Edition\"" "%dest%\update.mum"
  if errorlevel 1 (set /a _sum-=1&goto :eof)
  )
)
if exist "%dest%\%sss%_microsoft-updatetargeting-clientos*.manifest" if not defined vermajor (
for /f "tokens=5,6,7 delims=_." %%I in ('dir /b /a:-d /on "%dest%\%sss%_microsoft-updatetargeting-clientos*.manifest"') do set updtver=%%I.%%K&set vermajor=%%I
)
for /f "tokens=2 delims=-" %%V in ('dir /b "%package%"') do set kb=%%V
set "mumcheck=package_for_%kb%~*.mum"
if exist "%mumtarget%\Windows\servicing\packages\%mumcheck%" (
call :mumversion "%mumtarget%"
if !skip!==1 set /a _sum-=1&goto :eof
)
set "mumcheck=Package_for_RollupFix*.mum"
if exist "%mumtarget%\Windows\servicing\packages\%mumcheck%" (
call :rollversion "%mumtarget%"
if !skip!==1 set /a _sum-=1&goto :eof
)
if exist "%dest%\*_microsoft-windows-servicingstack_*.manifest" (set "servicingstack=!servicingstack! /packagepath:%dest%\update.mum"&goto :eof)
if exist "%mumtarget%\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" (
findstr /i /m "WinPE" "%dest%\update.mum" %_Nul3% || (findstr /i /m "Package_for_RollupFix" "%dest%\update.mum" %_Nul3% || (set /a _sum-=1&goto :eof))
findstr /i /m "WinPE-NetFx-Package" "%dest%\update.mum" %_Nul3% && (findstr /i /m "Package_for_RollupFix" "%dest%\update.mum" %_Nul3% || (set /a _sum-=1&goto :eof))
)
if exist "%dest%\*_adobe-flash-for-windows_*.manifest" (
if not exist "%mumtarget%\Windows\servicing\packages\Adobe-Flash-For-Windows-Package*.mum" if not exist "%mumtarget%\Windows\servicing\packages\Microsoft-Windows-Client-Desktop-Required-Package*.mum" (set /a _sum-=1&goto :eof)
if %build% geq 16299 (
  set flash=0
  for /f "tokens=3 delims=<= " %%# in ('findstr /i "Edition" "%dest%\update.mum" %_Nul6%') do if exist "%mumtarget%\Windows\servicing\packages\%%~#*.mum" set flash=1
  if "!flash!"=="0" (set /a _sum-=1&goto :eof)
  )
)
for %%# in (%directcab%) do (
if /i "!package!"=="%%~#" (
  set ldr=!ldr! /packagepath:"!package!"
  goto :eof
  )
)
findstr /i /m "Package_for_RollupFix" "%dest%\update.mum" %_Nul3% && (set "cumulative=!cumulative! /packagepath:%dest%\update.mum"&goto :eof)
set "ldr=!ldr! /packagepath:%dest%\update.mum"
goto :eof

:mumversion
set skip=0
set inver=0
set kbver=0
for /f "tokens=5-7 delims=~." %%i in ('dir /b /od "%~1\Windows\servicing\packages\%mumcheck%"') do set inver=%%i%%j%%k
mkdir "%_cabdir%\check"
echo %package%| findstr /E /I "\.msu" %_Nul1% && (expand.exe -f:*Windows*.cab %package% "%_cabdir%\check" >nul) || (copy %package% "%_cabdir%\check" >nul)
expand.exe -f:update.mum "%_cabdir%\check\*.cab" "%_cabdir%\check" 1>nul 2>nul
if not exist "%_cabdir%\check\*.mum" (set skip=1&rmdir /s /q "%_cabdir%\check"&goto :eof)
rem self note: do not remove " from set "kbver or add " at end
for /f "tokens=5-7 delims==<. %TAB%" %%i in ('findstr /i Package_for_ "%_cabdir%\check\update.mum"') do set "kbver=%%i%%j%%k
if %inver% geq %kbver% set skip=1
rmdir /s /q "%_cabdir%\check"
goto :eof

:rollversion
set skip=0
set inver=0
set kbver=0
findstr /i /m "%kb%" "%~1\Windows\servicing\packages\%mumcheck%" %_Nul1% || goto :eof
for /f "tokens=5-7 delims=~." %%i in ('dir /b /od "%~1\Windows\servicing\packages\%mumcheck%"') do set inver=%%i%%j%%k
mkdir "%_cabdir%\check"
echo %package%| findstr /E /I "\.msu" %_Nul1% && (expand.exe -f:*Windows*.cab %package% "%_cabdir%\check" >nul) || (copy %package% "%_cabdir%\check" >nul)
expand.exe -f:update.mum "%_cabdir%\check\*.cab" "%_cabdir%\check" 1>nul 2>nul
if not exist "%_cabdir%\check\*.mum" (set skip=1&rmdir /s /q "%_cabdir%\check"&goto :eof)
rem self note: do not remove " from set "kbver or add " at end
for /f "tokens=5-7 delims==<. %TAB%" %%i in ('findstr /i Package_for_RollupFix "%_cabdir%\check\update.mum"') do set "kbver=%%i%%j%%k
if %inver% geq %kbver% set skip=1
rmdir /s /q "%_cabdir%\check"
goto :eof

:enablenet35
if exist "%mumtarget%\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" goto :eof
if exist "%mumtarget%\Windows\Microsoft.NET\Framework\v2.0.50727\ngen.exe" goto :eof
if not defined net35source (
for %%# in (D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do if exist "%%#:\sources\sxs\*netfx3*.cab" set "net35source=%%#:\sources\sxs"
if %dvd%==1 if exist "%target%\sources\sxs\*netfx3*.cab" (set "net35source=%target%\sources\sxs")
if %wim%==1 for %%# in ("%target%") do if exist "%%~dp#sxs\*netfx3*.cab" set "net35source=%%~dp#sxs"
)
if not defined net35source goto :eof
if not exist "%net35source%\*.cab" goto :eof
echo.
echo ============================================================
echo Adding .NET Framework 3.5 feature
echo ============================================================
"!dismroot!" %dismtarget% /NoRestart /Enable-Feature /FeatureName:NetFx3 /All /LimitAccess /Source:"%net35source%"
if not defined netroll if not defined cumulative call :cleanup&goto :eof
echo.
echo ============================================================
echo Reinstalling cumulative update...
echo ============================================================
"!dismroot!" %dismtarget% /NoRestart /Add-Package %netroll% %cumulative%
call :cleanup
goto :eof

:counter
set _msu=0
set _cab=0
set _sum=0
cd /d "%repo%"
if exist "*Windows10*%arch%*.msu" (
for /f "delims=" %%# in ('dir /b "*Windows10*%arch%*.msu"') do (
  call set /a _msu+=1
  set "_tempname=%%#"
  if not "!_tempname!"=="!_tempname: =!" ren "!_tempname!" "!_tempname: =!"
  )
)
if exist "*Windows10*%arch%*.cab" (
for /f "delims=" %%# in ('dir /b "*Windows10*%arch%*.cab"') do (
  call set /a _cab+=1
  set "_tempname=%%#"
  if not "!_tempname!"=="!_tempname: =!" ren "!_tempname!" "!_tempname: =!"
  )
)
set /a _sum=%_msu%+%_cab%
goto :eof

:cleaner
cd /d "%~dp0"
if exist "%_cabdir%\*" (
echo.
echo ============================================================
echo Removing temporary extracted files...
echo ============================================================
echo.
rmdir /s /q "%_cabdir%" %_Nul1%
)
if defined msucab (
  for %%# in (%msucab%) do (del /f /q "%repo%\*%%~#*.cab" %_Nul3%)
  set msucab=
)
goto :eof

:mount
if exist "%mountdir%" rmdir /s /q "%mountdir%" >nul
if exist "%winremount%" rmdir /s /q "%winremount%" >nul
if not exist "%mountdir%" mkdir "%mountdir%"
for %%# in (%indices%) do (
echo.
echo ============================================================
echo Mounting %~nx1 - index %%#/%imgcount%
echo ============================================================
"!dismroot!" /Mount-Wim /Wimfile:%1 /Index:%%# /MountDir:"%mountdir%"
if !errorlevel! neq 0 goto :E_MOUNT
call :update
if %net35%==1 call :enablenet35
if %dvd%==1 if exist "%mountdir%\sources\setup.exe" call :boots
if %wim%==1 if exist "%~dp1setup.exe" (
if exist "%mountdir%\sources\setup.exe" copy /y "%mountdir%\sources\setup.exe" "%~dp1" %_Nul3%
if not exist "%mountdir%\sources\setup.exe" if defined isoupdate (
  mkdir "%_cabdir%\du" %_Nul3%
  for %%i in (!isoupdate!) do expand.exe -r -f:* "%repo%\%%~i" "%_cabdir%\du" %_Nul1%
  xcopy /CERUY "%_cabdir%\du" "%target%\sources\" %_Nul3%
  if exist "%_cabdir%\du\replacementmanifests" xcopy /CERY "%_cabdir%\du\replacementmanifests" "%target%\sources\replacementmanifests\" %_Nul3%
  rmdir /s /q "%_cabdir%\du" %_Nul3%
  )
)
if exist "%mountdir%\Windows\System32\Recovery\winre.wim" attrib -S -H -I "%mountdir%\Windows\System32\Recovery\winre.wim" %_Nul3%
if %winre%==1 if exist "%mountdir%\Windows\System32\Recovery\winre.wim" if not exist "!_workdir!\winre.wim" call :winre
if exist "%mountdir%\Windows\System32\Recovery\winre.wim" if exist "!_workdir!\winre.wim" (
echo.
echo ============================================================
echo Adding updated winre.wim
echo ============================================================
echo.
copy /y "!_workdir!\winre.wim" "%mountdir%\Windows\System32\Recovery"
)
echo.
echo ============================================================
echo Unmounting %~nx1 - index %%#/%imgcount%
echo ============================================================
if !discard!==1 (
"!dismroot!" /Unmount-Wim /MountDir:"%mountdir%" /Discard
) else (
"!dismroot!" /Unmount-Wim /MountDir:"%mountdir%" /Commit
)
if !errorlevel! neq 0 goto :E_MOUNT
)
if %_Debug% neq 0 goto :eof
echo.
echo ============================================================
echo Rebuilding %~nx1
echo ============================================================
if %keep%==1 (
for %%# in (%indices%) do "!dismroot!" /Export-Image /SourceImageFile:%1 /SourceIndex:%%# /DestinationImageFile:"!_workdir!\temp.wim"
) else (
"!dismroot!" /Export-Image /SourceImageFile:%1 /All /DestinationImageFile:"!_workdir!\temp.wim"
)
move /y "!_workdir!\temp.wim" %1 %_Nul1%
goto :eof

:boots
if exist "%mountdir%\Windows\servicing\Packages\WinPE-Setup-Package~*.mum" xcopy /CDRY "%mountdir%\sources" "%target%\sources" %_Nul3%
del /f /q "%target%\sources\background.bmp" %_Nul3%
del /f /q "%target%\sources\xmllite.dll" %_Nul3%
del /f /q "%target%\efi\microsoft\boot\*noprompt.*" %_Nul3%
copy /y "%mountdir%\Windows\Boot\DVD\EFI\en-US\efisys.bin" "%target%\efi\microsoft\boot\" %_Nul1%
copy /y "%mountdir%\Windows\Boot\EFI\memtest.efi" "%target%\efi\microsoft\boot\" %_Nul1%
copy /y "%mountdir%\Windows\Boot\EFI\bootmgfw.efi" "%target%\efi\boot\%efifile%" %_Nul1%
copy /y "%mountdir%\Windows\Boot\EFI\bootmgr.efi" "%target%\" %_Nul1%
copy /y "%mountdir%\Windows\Boot\PCAT\bootmgr" "%target%\" %_Nul1%
copy /y "%mountdir%\Windows\Boot\PCAT\memtest.exe" "%target%\boot\" %_Nul1%
copy /y "%mountdir%\setup.exe" "%target%\" %_Nul3%
for /f "tokens=6,7 delims=_." %%i in ('dir /b /a:-d /od "%mountdir%\Windows\WinSxS\Manifests\%sss%_microsoft-windows-coreos-revision*.manifest"') do set isover=%%i.%%j&set isomajor=%%i
if %build% equ 18362 if exist "%mountdir%\Windows\servicing\Packages\microsoft-windows-*enablement-package*.mum" set _Enable=1
if not exist "%mountdir%\Windows\servicing\Packages\WinPE-Setup-Package~*.mum" if defined isoupdate (
  mkdir "%_cabdir%\du" %_Nul3%
  for %%i in (!isoupdate!) do expand.exe -r -f:* "%repo%\%%~i" "%_cabdir%\du" %_Nul1%
  robocopy "%_cabdir%\du" "%mountdir%\sources" /XL /XX /XO %_Nul3%
  rmdir /s /q "%_cabdir%\du" %_Nul3%
)
if not defined vermajor goto :eof
if %_Enable% equ 0 goto :eof
if %vermajor% gtr %isomajor% set isover=%updtver%
goto :eof

:winre
  echo.
  echo ============================================================
  echo Updating winre.wim
  echo ============================================================
  mkdir "!winremount!"
  copy "!mountdir!\Windows\System32\Recovery\winre.wim" "!_workdir!\winre.wim" %_Nul1%
  "!dismroot!" /Mount-Wim /Wimfile:"!_workdir!\winre.wim" /Index:1 /MountDir:"!winremount!"
  if %errorlevel% neq 0 goto :E_MOUNT
  call :update winre
  if !discardre!==1 (
  "!dismroot!" /Unmount-Wim /MountDir:"!winremount!" /Discard
  if !errorlevel! neq 0 goto :E_MOUNT
  ) else (
  "!dismroot!" /Unmount-Wim /MountDir:"!winremount!" /Commit
  if !errorlevel! neq 0 goto :E_MOUNT
  "!dismroot!" /Export-Image /SourceImageFile:"!_workdir!\winre.wim" /All /DestinationImageFile:"!_workdir!\temp.wim"
  move /y "!_workdir!\temp.wim" "!_workdir!\winre.wim" %_Nul1%
  )
  set "mumtarget=!mumtarget_b!"
  set dismtarget=/image:"!mountdir!"
goto :eof

:cleanup
set savc=0&set savr=1
if %build% geq 18362 (set savc=3&set savr=3)
if exist "%mumtarget%\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" (
if %verb%==1 (
echo.
echo ============================================================
echo Resetting WinPE image base
echo ============================================================
)
if %build% geq 16299 (
set ksub=SOFTWIM
reg.exe load HKLM\!ksub! "%mumtarget%\Windows\System32\Config\SOFTWARE" %_Nul1%
reg.exe add HKLM\!ksub!\Microsoft\Windows\CurrentVersion\SideBySide\Configuration /v SupersededActions /t REG_DWORD /d %savr% /f %_Nul1%
reg.exe unload HKLM\!ksub! %_Nul1%
"!dismroot!" %dismtarget% /Cleanup-Image /StartComponentCleanup
if !errorlevel! equ 1726 "!dismroot!" %dismtarget% /Get-Packages %_Nul1%
)
"!dismroot!" %dismtarget% /Cleanup-Image /StartComponentCleanup /ResetBase
if !errorlevel! equ 1726 "!dismroot!" %dismtarget% /Get-Packages %_Nul1%
call :cleanmanual
goto :eof
)
if %cleanup%==0 call :cleanmanual&goto :eof
if exist "%mumtarget%\Windows\WinSxS\pending.xml" (
if %online%==1 (
  if %resetbase%==0 (set rValue=W10UIclean) else (set rValue=W10UIrebase)
  reg.exe add %rSxS% /v !rValue! /t REG_DWORD /d 1 /f %_Nul1%
  goto :eof
  )
call :cleanmanual&goto :eof
)
if %online%==0 (
set ksub=SOFTWIM
reg.exe load HKLM\!ksub! "%mumtarget%\Windows\System32\Config\SOFTWARE" %_Nul1%
) else (
set ksub=SOFTWARE
)
if %resetbase%==0 (
echo.
echo ============================================================
echo Cleaning up OS image
echo ============================================================
reg.exe add HKLM\%ksub%\Microsoft\Windows\CurrentVersion\SideBySide\Configuration /v DisableResetbase /t REG_DWORD /d 1 /f %_Nul1%
reg.exe add HKLM\%ksub%\Microsoft\Windows\CurrentVersion\SideBySide\Configuration /v SupersededActions /t REG_DWORD /d %savc% /f %_Nul1%
if %online%==0 reg.exe unload HKLM\%ksub% %_Nul1%
"!dismroot!" %dismtarget% /NoRestart /Cleanup-Image /StartComponentCleanup
if !errorlevel! equ 1726 "!dismroot!" %dismtarget% /Get-Packages %_Nul1%
) else (
echo.
echo ============================================================
echo Resetting OS image base
echo ============================================================
reg.exe add HKLM\%ksub%\Microsoft\Windows\CurrentVersion\SideBySide\Configuration /v DisableResetbase /t REG_DWORD /d 0 /f %_Nul1%
reg.exe add HKLM\%ksub%\Microsoft\Windows\CurrentVersion\SideBySide\Configuration /v SupersededActions /t REG_DWORD /d %savr% /f %_Nul1%
if %online%==0 reg.exe unload HKLM\%ksub% %_Nul1%
if %online%==0 if %build% geq 16299 "!dismroot!" %dismtarget% /NoRestart /Cleanup-Image /StartComponentCleanup
if !errorlevel! equ 1726 "!dismroot!" %dismtarget% /Get-Packages %_Nul1%
"!dismroot!" %dismtarget% /NoRestart /Cleanup-Image /StartComponentCleanup /ResetBase
if !errorlevel! equ 1726 "!dismroot!" %dismtarget% /Get-Packages %_Nul1%
)
call :cleanmanual
goto :eof

:cleanmanual
if %online%==1 goto :eof
if exist "%mumtarget%\Windows\WinSxS\ManifestCache\*.bin" (
takeown /f "%mumtarget%\Windows\WinSxS\ManifestCache\*.bin" /A %_Nul3%
icacls "%mumtarget%\Windows\WinSxS\ManifestCache\*.bin" /grant *S-1-5-32-544:F %_Nul3%
del /f /q "%mumtarget%\Windows\WinSxS\ManifestCache\*.bin" %_Nul3%
)
if exist "%mumtarget%\Windows\WinSxS\Temp\PendingDeletes\*" (
takeown /f "%mumtarget%\Windows\WinSxS\Temp\PendingDeletes\*" /A %_Nul3%
icacls "%mumtarget%\Windows\WinSxS\Temp\PendingDeletes\*" /grant *S-1-5-32-544:F %_Nul3%
del /f /q "%mumtarget%\Windows\WinSxS\Temp\PendingDeletes\*" %_Nul3%
)
if exist "%mumtarget%\Windows\WinSxS\Temp\TransformerRollbackData\*" (
takeown /f "%mumtarget%\Windows\WinSxS\Temp\TransformerRollbackData\*" /R /A %_Nul3%
icacls "%mumtarget%\Windows\WinSxS\Temp\TransformerRollbackData\*" /grant *S-1-5-32-544:F /T %_Nul3%
del /s /f /q "%mumtarget%\Windows\WinSxS\Temp\TransformerRollbackData\*" %_Nul3%
)
if exist "%mumtarget%\Windows\inf\*.log" (
del /f /q "%mumtarget%\Windows\inf\*.log" %_Nul3%
)
for /f "delims=" %%# in ('dir /b /ad "%mumtarget%\Windows\CbsTemp\" %_Nul6%') do rmdir /s /q "%mumtarget%\Windows\CbsTemp\%%#" %_Nul3%
del /s /f /q "%mumtarget%\Windows\CbsTemp\*" %_Nul3%
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

:E_Repo
echo.
echo ============================================================
echo ERROR: Specified location is not valid
echo ============================================================
echo.
echo Press any key to continue...
%_Pause%
set "repo=!_workdir!"
call :counter
if %_sum%==0 set "repo="
goto :mainmenu

:E_MOUNT
echo.
echo ============================================================
echo ERROR: Could not mount or unmount WIM image
echo ============================================================
echo.
echo Press 9 to exit.
endlocal
if %_Debug% neq 0 exit
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
endlocal
goto :eof

:checkadk
set regKeyPathFound=1
set wowRegKeyPathFound=1
reg query "HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 %_Nul3% || set wowRegKeyPathFound=0
reg query "HKLM\Software\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 %_Nul3% || set regKeyPathFound=0
if %wowRegKeyPathFound% equ 0 (
  if %regKeyPathFound% equ 0 (
    goto :mainmenu
  ) else (
    set regKeyPath=HKLM\Software\Microsoft\Windows Kits\Installed Roots
  )
) else (
    set regKeyPath=HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots
)
for /f "skip=2 tokens=2*" %%i in ('reg query "%regKeyPath%" /v KitsRoot10') do set "KitsRoot=%%j"
set "DandIRoot=%KitsRoot%Assessment and Deployment Kit\Deployment Tools"
set "oscdimgroot=%DandIRoot%\%xOS%\Oscdimg\oscdimg.exe"
set "dismroot=%DandIRoot%\%xOS%\DISM\dism.exe"
set "showdism=Windows 10 ADK"
if not exist "!dismroot!" set "dismroot=dism.exe"&set "showdism=dism.exe"
goto :mainmenu

:targetmenu
@cls
echo ============================================================
echo Enter the path for one of supported targets:
echo - Distribution ^(extracted folder, mounted iso/dvd/usb drive^)
echo - WIM file
echo - Mounted directory, offline image drive letter
if %winbuild% geq 10240 echo - Current OS / Enter %SystemDrive%
echo.
echo or just press 'Enter' to return to options menu
echo ============================================================
echo.
set /p _pp=
if not defined _pp goto :mainmenu
set "_pp=%_pp:"=%"
if "%_pp:~-1%"=="\" set "_pp=%_pp:~0,-1%"
set dvd=0
set wim=0
set offline=0
set online=0
set copytarget=0
set imgcount=0
set wimfiles=0
set keep=0
set targetname=0
set _Enable=0
set "target=%_pp%"
if /i "%target%"=="%SystemDrive%" (
set online=1
if %xOS%==amd64 (set arch=x64) else (set arch=x86)
goto :mainmenu
)
echo %target%| findstr /E /I "\.wim" %_Nul1%
if %errorlevel%==0 (
set wim=1
for %%# in ("%target%") do set "targetname=%%~nx#"
) else (
if exist "%target%\sources\boot.wim" set dvd=1 
if exist "%target%\Windows\regedit.exe" set offline=1
)
if %offline%==0 if %wim%==0 if %dvd%==0 (set "MESSAGE=Specified location is not valid"&goto :E_Target)
if %offline%==1 (
dir /b "%target%\Windows\servicing\Version\10.0.*" %_Nul3% || (set "MESSAGE=Detected target offline image is not Windows 10"&goto :E_Target)
for /f "tokens=3 delims=." %%# in ('dir /b "%target%\Windows\servicing\Version\10.0.*"') do set build=%%#
set "mountdir=%target%"
if exist "%target%\Windows\SysWOW64\cmd.exe" (set arch=x64) else (set arch=x86)
)
if %dvd%==1 (
echo.
echo ============================================================
echo Please wait...
echo ============================================================
dir /b /s /adr "%target%\boot" %_Nul3% && set copytarget=1
dism /english /get-wiminfo /wimfile:"%target%\sources\install.wim" /index:1 | find /i "Version : 10.0" %_Nul1% || (set "MESSAGE=Detected install.wim version is not Windows 10"&goto :E_Target)
for /f "tokens=4 delims=:. " %%# in ('dism /english /get-wiminfo /wimfile:"%target%\sources\install.wim" /index:1 ^| find /i "Version :"') do set build=%%#
for /f "tokens=2 delims=: " %%# in ('dism /english /get-wiminfo /wimfile:"%target%\sources\install.wim" /index:1 ^| find /i "Architecture"') do set arch=%%#
for /f "tokens=2 delims=: " %%# in ('dism /english /get-wiminfo /wimfile:"%target%\sources\install.wim" ^| findstr "Index"') do set imgcount=%%#
for /f "tokens=2 delims=: " %%# in ('dism /english /get-wiminfo /wimfile:"%target%\sources\boot.wim" ^| findstr "Index"') do set bootimg=%%#
for /L %%# in (1,1,!imgcount!) do (
  for /f "tokens=1* delims=: " %%i in ('dism /english /get-wiminfo /wimfile:"%target%\sources\install.wim" /index:%%# ^| findstr /b /c:"Name"') do set name%%#="%%j"
  )
set "indices=*"
set "targetname=install.wim"
set wimfiles=1
)
if %wim%==1 (
echo.
echo ============================================================
echo Please wait...
echo ============================================================
dism /english /get-wiminfo /wimfile:"%target%" /index:1 | find /i "Version : 10.0" %_Nul1% || (set "MESSAGE=Detected wim version is not Windows 10"&goto :E_Target)
for /f "tokens=4 delims=:. " %%# in ('dism /english /get-wiminfo /wimfile:"%target%" /index:1 ^| find /i "Version :"') do set build=%%#
for /f "tokens=2 delims=: " %%# in ('dism /english /get-wiminfo /wimfile:"%target%" /index:1 ^| find /i "Architecture"') do set arch=%%#
for /f "tokens=2 delims=: " %%# in ('dism /english /get-wiminfo /wimfile:"%target%" ^| findstr "Index"') do set imgcount=%%#
for /L %%# in (1,1,!imgcount!) do (
  for /f "tokens=1* delims=: " %%i in ('dism /english /get-wiminfo /wimfile:"%target%" /index:%%# ^| findstr /b /c:"Name"') do set name%%#="%%j"
  )
set "indices=*"
set wimfiles=1
)
set "repo=!_workdir!"
call :counter
if %_sum%==0 set "repo="
goto :mainmenu

:repomenu
@cls
echo ============================================================
echo Enter the Updates location path
echo.
echo or just press 'Enter' to return to options menu
echo ============================================================
echo.
set /p _pp=
if not defined _pp goto :mainmenu
set "_pp=%_pp:"=%"
if "%_pp:~-1%"=="\" set "_pp=%_pp:~0,-1%"
set "repo=%_pp%"
if not exist "%repo%\*Windows10*.msu" if not exist "%repo%\*Windows10*.cab" (goto :E_Repo)
goto :mainmenu

:dismmenu
@cls
echo.
echo If current OS is lower than Windows 10, and Windows 10 ADK is not detected
echo you must install it, or specify a manual Windows 10 dism.exe for integration
echo you can select dism.exe located in Windows 10 distribution "sources" folder
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
if not exist "!_pp!" (
echo.
echo ERROR: not found
echo Press any key to continue...
%_Pause%
goto :mainmenu
)
for /f "tokens=4 delims==." %%# in ('wmic datafile where "name='!_pp:\=\\!'" get Version /value') do if %%# lss 10240 (
echo.
echo ERROR: DISM version is lower than 10.0.10240.16384
echo Press any key to continue...
%_Pause%
goto :mainmenu
)
set "dismroot=%_pp%"
set "showdism=%_pp%"
goto :mainmenu

:extractmenu
@cls
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
if "%_pp:~-1%"=="\" set "_pp=%_pp:~0,-1%"
if "%_pp:~-1%"==":" set "_pp=%_pp%\"
set /a rnd=%random%
set "_cabdir=%_pp%_%rnd%"
goto :mainmenu

:mountmenu
@cls
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
if "%_pp:~-1%"=="\" set "_pp=%_pp:~0,-1%"
if "%_pp:~-1%"==":" set "_pp=%_pp%\"
set /a rnd=%random%
set "mountdir=%_pp%_%rnd%"
goto :mainmenu

:indexmenu
@cls
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
set "_pp=%_pp:"=%"
if "%_pp%"=="*" set "indices=%_pp%"&goto :mainmenu
for %%# in (%_pp%) do (
if %%# gtr %imgcount% echo.&echo %%# is higher than available indexes&pause&set _pp=&goto :indexmenu
if %%# equ 0 echo.&echo 0 is not valid index&pause&set _pp=&goto :indexmenu
)
set "indices=%_pp%"
set keep=1
goto :mainmenu

:mainmenu
if %autostart%==1 goto :mainboard
set _pp=
:: mode con lines=3000
@cls
echo ============================================================
if /i "%target%"=="%SystemDrive%" (
if %winbuild% lss 10240 (echo 1. Select offline target) else (echo 1. Target ^(%arch%^): Current OS)
) else (
if /i "%target%"=="" (echo 1. Select offline target) else (echo 1. Target ^(%arch%^): "%target%")
)
echo.
if "%repo%"=="" (echo 2. Select updates location) else (echo 2. Updates: "%repo%")
echo.
if %winbuild% lss 10240 (
if /i "!dismroot!"=="dism.exe" (echo 3. Select Windows 10 dism.exe) else (echo 3. DISM: "%showdism%")
) else (
echo 3. DISM: "%showdism%"
)
echo.
if %net35%==1 (echo 4. Enable .NET 3.5: YES) else (echo 4. Enable .NET 3.5: NO)
echo.
if %cleanup%==0 (
echo 5. Cleanup System Image: NO
) else (
if %resetbase%==0 (echo 5. Cleanup System Image: YES      6. Reset Image Base: NO) else (echo 5. Cleanup System Image: YES      6. Reset Image Base: YES)
)
echo.
if %wimfiles%==1 (
if /i "%targetname%" equ "install.wim" (if %winre%==1 (echo 7. Update WinRE.wim: YES) else (echo 7. Update WinRE.wim: NO))
if %imgcount% gtr 1 (
echo.
if "%indices%"=="*" echo 8. Install.wim selected indexes: ALL ^(%imgcount%^)
if not "%indices%"=="*" (if %keep%==1 (echo 8. Install.wim selected indexes: %indices% / K. Keep indexes: Selected) else (if %keep%==0 echo 8. Install.wim selected indexes: %indices% / K. Keep indexes: ALL))
)
echo.
echo M. Mount Directory: "%mountdir%"
echo.
)
echo E. Extraction Directory: "%_cabdir%"
echo ============================================================
echo 0. Start the process
echo ============================================================
echo.
choice /c 1234567890KEM /n /m "Change a menu option, press 0 to start, or 9 to exit: "
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
if not exist "!oscdimgroot!" if not exist "!_workdir!\oscdimg.exe" if not exist "!_workdir!\cdimage.exe" goto :eof
for /f "skip=1" %%x in ('wmic os get localdatetime') do if not defined MyDate set "MyDate=%%x"
set "isodate=%MyDate:~0,4%-%MyDate:~4,2%-%MyDate:~6,2%"
set "isofile=Win10_%isover%_%arch%_%isodate%.iso"
set /a rnd=%random%
if exist "!isodir!\%isofile%" ren "!isodir!\%isofile%" "%rnd%_%isofile%"
echo.
echo ============================================================
echo Creating updated ISO file...
echo ============================================================
if exist "!oscdimgroot!" (set _ff="%oscdimgroot%") else if exist "!_workdir!\oscdimg.exe" (set _ff="!_workdir!\oscdimg.exe") else (set _ff="!_workdir!\cdimage.exe")
%_ff% -m -o -u2 -udfver102 -bootdata:2#p0,e,b"%target%\boot\etfsboot.com"#pEF,e,b"%target%\efi\microsoft\boot\efisys.bin" -l"%isover%" "%target%" "!isodir!\%isofile%"
if %errorlevel% equ 0 if %delete_source% equ 1 rmdir /s /q "%target%" %_Nul1%
if exist "!_workdir!\DVD" rmdir /s /q "!_workdir!\DVD" %_Nul1%
goto :eof

:fin
call :cleaner
if %dvd%==1 (if exist "%mountdir%" rmdir /s /q "%mountdir%" %_Nul1%)
if %wim%==1 (if exist "%mountdir%" rmdir /s /q "%mountdir%" %_Nul1%)
if exist "%winremount%" rmdir /s /q "%winremount%" %_Nul1%
if %dvd%==1 if %iso%==1 call :ISO
echo.
echo ============================================================
echo    Finished
echo ============================================================
echo.
if %online%==1 if exist "%windir%\winsxs\pending.xml" (
echo.
echo ============================================================
echo System restart is required to complete installation
echo ============================================================
echo.
)
echo.
echo Press 9 to exit.
endlocal
if %_Debug% neq 0 goto :eof
choice /c 9 /n
if errorlevel 1 (goto :eof) else (rem.)
