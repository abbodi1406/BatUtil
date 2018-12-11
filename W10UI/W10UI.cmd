@echo off
:: set to 1 to enable debug mode (you must also set target, and repo if updates are not beside the script)
set _Debug=0

cd /d "%~dp0"
set uiv=v5.6
:: when changing below options, be sure to set the new values between = and " marks

:: target image or wim file
:: leave it blank to automatically detect wim file next to the script, or current online os
set "target="

:: updates location, %cd% represent the current script directory
set "repo=%cd%"

:: dism.exe tool path (default is system's if the host os is win10)
set "dismroot=%windir%\system32\dism.exe"

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

:: # Manual options #

:: create new iso file if the target is a distribution folder
:: require ADK installed, or placing oscdimg.exe or cdimage.exe next to the script
set iso=1

:: set this to 1 to delete DVD distribution folder after creating updated ISO
set delete_source=0

:: set this to 1 to start the process directly once you execute the script
:: make sure you set the above options correctly first
set autostart=0

:: optional, set directory for temporary extracted files
set "cab_dir=%~d0\W10UItemp"

:: optional, set mount directory for updating wim files
set "mountdir=%SystemDrive%\W10UImount"
set "winremount=%SystemDrive%\W10UImountre"

:: ##################################################################
:: # NORMALY THERE IS NO NEED TO CHANGE ANYTHING BELOW THIS COMMENT #
:: ##################################################################

title Installer for Windows 10 Updates
set oscdimgroot=%windir%\system32\oscdimg.exe
set _reg=%windir%\system32\reg.exe
%_reg% query "HKU\S-1-5-19" 1>nul 2>nul || goto :E_Admin

if %_Debug% EQU 1 set autostart=1
if %_Debug% EQU 0 (
  set "_Nul_1=1>nul"
  set "_Nul_2=2>nul"
  set "_Nul_2e=2^>nul"
  set "_Nul_1_2=1>nul 2>nul"
  call :Begin
) else (
  set "_Nul_1="
  set "_Nul_2="
  set "_Nul_2e="
  set "_Nul_1_2="
  echo.
  echo Running in Debug Mode...
  echo The window will be closed when finished
  @echo on
  @prompt $G
  @call :Begin >"%~dpn0.tmp" 2>&1 &cmd /u /c type "%~dpn0.tmp">"%~dpn0_Debug.log"&del "%~dpn0.tmp"
)
exit /b

:Begin
if exist "%cab_dir%" (
echo.
echo ============================================================
echo Removing temporary extracted files...
echo ============================================================
echo.
rmdir /s /q "%cab_dir%" %_Nul_1%
)
setlocal enableextensions
setLocal EnableDelayedExpansion
set directcab=0
set dvd=0
set wim=0
set offline=0
set online=0
set _wim=0
set copytarget=0
set imgcount=0
if exist "*.wim" (for /f "delims=" %%i in ('dir /b /a:-d *.wim') do (call set /a _wim+=1))
if "%target%"=="" if %_wim%==1 (for %%i in ("*.wim") do set "target=%%~fi"&set "targetname=%%i")
if "%target%"=="" set "target=%SystemDrive%"
if "%target:~-1%"=="\" set "target=%target:~0,-1%"
if /i "%target%"=="%SystemDrive%" goto :check
echo %target%| findstr /E /I "\.wim" %_Nul_1%
if %errorlevel%==0 (
set wim=1
for /f %%i in ('dir /b "%target%"') do set "targetname=%%i"
) else (
if exist "%target%\sources\boot.wim" set dvd=1 
if exist "%target%\Windows\regedit.exe" set offline=1
)
if %offline%==0 if %wim%==0 if %dvd%==0 (set "target=%SystemDrive%"&goto :check)
if %offline%==1 (
dir /b "%target%\Windows\servicing\Version\10.0.*" %_Nul_1_2% || (set "MESSAGE=Detected target offline image is not Windows 10"&goto :E_Target)
for /f "tokens=3 delims=." %%i in ('dir /b "%target%\Windows\servicing\Version\10.0.*"') do set build=%%i
set "mountdir=%target%"
if exist "%target%\Windows\SysWOW64\*" (set arch=x64) else (set arch=x86)
)
if %dvd%==1 (
echo.
echo ============================================================
echo Please wait...
echo ============================================================
dir /b /s /adr "%target%" %_Nul_1_2% && set copytarget=1
dism /english /get-wiminfo /wimfile:"%target%\sources\install.wim" /index:1 | find /i "Version : 10.0" %_Nul_1% || (set "MESSAGE=Detected install.wim version is not Windows 10"&goto :E_Target)
for /f "tokens=4 delims=:. " %%i in ('dism /english /get-wiminfo /wimfile:"%target%\sources\install.wim" /index:1 ^| find /i "Version :"') do set build=%%i
for /f "tokens=2 delims=: " %%i in ('dism /english /get-wiminfo /wimfile:"%target%\sources\install.wim" /index:1 ^| find /i "Architecture"') do set arch=%%i
for /f "tokens=2 delims=: " %%i in ('dism /english /get-wiminfo /wimfile:"%target%\sources\install.wim" ^| findstr "Index"') do set imgcount=%%i
for /f "tokens=2 delims=: " %%i in ('dism /english /get-wiminfo /wimfile:"%target%\sources\boot.wim" ^| findstr "Index"') do set bootimg=%%i
for /L %%i in (1,1,!imgcount!) do (
  for /f "tokens=1* delims=: " %%a in ('dism /english /get-wiminfo /wimfile:"%target%\sources\install.wim" /index:%%i ^| findstr /b /c:"Name"') do set name%%i="%%b"
  )
set "indices=*"
)
if %wim%==1 (
echo.
echo ============================================================
echo Please wait...
echo ============================================================
dism /english /get-wiminfo /wimfile:"%target%" /index:1 | find /i "Version : 10.0" %_Nul_1% || (set "MESSAGE=Detected wim version is not Windows 10"&goto :E_Target)
for /f "tokens=4 delims=:. " %%i in ('dism /english /get-wiminfo /wimfile:"%target%" /index:1 ^| find /i "Version :"') do set build=%%i
for /f "tokens=2 delims=: " %%i in ('dism /english /get-wiminfo /wimfile:"%target%" /index:1 ^| find /i "Architecture"') do set arch=%%i
for /f "tokens=2 delims=: " %%i in ('dism /english /get-wiminfo /wimfile:"%target%" ^| findstr "Index"') do set imgcount=%%i
for /L %%i in (1,1,!imgcount!) do (
  for /f "tokens=1* delims=: " %%a in ('dism /english /get-wiminfo /wimfile:"%target%" /index:%%i ^| findstr /b /c:"Name"') do set name%%i="%%b"
  )
set "indices=*"
)

:check
if /i "%target%"=="%SystemDrive%" (if exist "%target%\Windows\SysWOW64\*" (set arch=x64) else (set arch=x86))
call :counter
if %_sum%==0 set "repo="

for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G
rem if %winbuild% geq 10240 goto :mainmenu
if /i "%dismroot%" neq "%windir%\system32\dism.exe" goto :mainmenu
goto :checkadk

:mainboard
if %winbuild% lss 10240 (
if /i "%target%"=="%SystemDrive%" (goto :mainmenu)
if /i "%dismroot%"=="%windir%\system32\dism.exe" (goto :mainmenu)
)
if "%cab_dir%"=="" (goto :mainmenu)
if "%cab_dir:~-1%"=="\" set "cab_dir=%cab_dir:~0,-1%"
if "%repo%"=="" (goto :mainmenu)
if "%repo:~-1%"=="\" set "repo=%repo:~0,-1%"
if "%mountdir%"=="" (goto :mainmenu)
if "%mountdir:~-1%"=="\" set "mountdir=%mountdir:~0,-1%"
if /i "%target%"=="%SystemDrive%" (set dismtarget=/online&set "mountdir=%target%"&set online=1&set build=%winbuild%) else (set dismtarget=/image:"%mountdir%")
cls
echo ============================================================
echo Running W10UI %uiv%
echo ============================================================
if %online%==1 (
net stop trustedinstaller %_Nul_1_2%
net stop wuauserv %_Nul_1_2%
DEL /F /Q %systemroot%\Logs\CBS\* %_Nul_1_2%
)
DEL /F /Q %systemroot%\Logs\DISM\* %_Nul_1_2%
if %dvd%==1 if %copytarget%==1 (
echo.
echo ============================================================
echo Copying DVD contents to work directory
echo ============================================================
robocopy "%target%" "%~dp0DVD" /E /A-:R %_Nul_1%
set "target=%~dp0DVD"
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
if "%indices%"=="*" set "indices="&for /L %%i in (1,1,%imgcount%) do set "indices=!indices! %%i"
call :mount "%target%"
if /i "%targetname%" neq "winre.wim" (if exist "%~dp0winre.wim" del /f /q "%~dp0winre.wim" %_Nul_1%)
)
if %dvd%==1 (
if "%indices%"=="*" set "indices="&for /L %%i in (1,1,%imgcount%) do set "indices=!indices! %%i"
call :mount "%target%\sources\install.wim"
if exist "%~dp0winre.wim" del /f /q "%~dp0winre.wim" %_Nul_1%
set "indices="&set imgcount=%bootimg%&for /L %%i in (1,1,!imgcount!) do set "indices=!indices! %%i"
call :mount "%target%\sources\boot.wim"
if defined isoupdate (
  for %%a in (%isoupdate%) do (expand.exe -f:* "%repo%\%%a" "%target%\sources" %_Nul_1%)
)
xcopy /CRY "%target%\efi\microsoft\boot\fonts" "%target%\boot\fonts" %_Nul_1%
if %net35%==1 if exist "%target%\sources\sxs" (rmdir /s /q "%target%\sources\sxs" %_Nul_1%)
)
goto :fin

:extract
call :cleaner
if not exist "%cab_dir%" mkdir "%cab_dir%"
call :counter
if %_cab% neq 0 (set msu=0&for /f %%G in ('dir /b *Windows10*%arch%*.cab') do (set package=%%G&call :cab1))
if %_msu% neq 0 (
echo.
echo ============================================================
echo Extracting .cab files from .msu files
echo ============================================================
echo.
set msucab=&set msu=1&set count=0
for /f %%G in ('dir /b *Windows10*%arch%*.msu') do (set package=%%G&call :cab1)
)
if %_sum%==0 (echo.&echo All applicable updates are detected as installed&goto :eof)
echo.
echo ============================================================
echo Extracting files from update cabinets ^(.cab^)
echo *** This will require some disk space, please be patient ***
echo ============================================================
echo.
set count=0&set isoupdate=
rem cd /d "%cab_dir%"
for /f %%G in ('dir /b *Windows10*%arch%*.cab') do (call :cab2 %%G)
goto :eof

:cab1
for /f "tokens=2 delims=-" %%V in ('dir /b %package%') do set kb=%%V
set "mumcheck=package_*_for_%kb%~*.mum"
if %online%==1 if exist "%target%\Windows\servicing\packages\%mumcheck%" (
call :mumversion "%target%"
if !skip!==1 set /a _sum-=1&if %msu% equ 1 (set /a _msu-=1&goto :eof) else (set /a _cab-=1&goto :eof)
)
if %offline%==1 if exist "%target%\Windows\servicing\packages\%mumcheck%" (
call :mumversion "%target%"
if !skip!==1 set /a _sum-=1&if %msu% equ 1 (set /a _msu-=1&goto :eof) else (set /a _cab-=1&goto :eof)
)
if %msu% equ 0 goto :eof
set "msucab=!msucab! %kb%"
set /a count+=1
echo %count%/%_msu%: %package%
expand.exe -f:*Windows*.cab %package% "%repo%" 1>nul 2>nul
goto :eof

:cab2
set "package=%1"
set "dest=%cab_dir%\%~n1"
set /a count+=1
echo %count%/%_sum%: %package%
if exist "%dest%" rmdir /s /q "%dest%" %_Nul_1_2%
mkdir "%dest%"
expand.exe -f:* "%package%" "%dest%" 1>nul 2>nul || (set "directcab=!directcab! %package%")
if not exist "%dest%\update.mum" (set "isoupdate=!isoupdate! %package%"&goto :eof)
if not exist "%dest%\*cablist.ini" goto :eof
expand.exe -f:* "%dest%\*.cab" "%dest%" 1>nul 2>nul || (set "directcab=!directcab! %package%")
del /f /q "%dest%\*cablist.ini" %_Nul_1_2%
del /f /q "%dest%\*.cab" %_Nul_1_2%
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
set netfx=
set discard=0
set discardre=0
set ldr=&set listc=0&set list=1&set AC=100
rem cd /d "%cab_dir%"
set _sum=0
if exist "*.cab" (for /f %%G in ('dir /b *Windows10*%arch%*.cab') do (call set /a _sum+=1))
if exist "*.cab" (for /f %%G in ('dir /b *Windows10*%arch%*.cab') do (call :mum %%G))
if %verb%==1 if %_sum%==0 if exist "%mountdir%\sources\recovery\RecEnv.exe" (echo.&echo All applicable updates are detected as installed&call set discard=1&goto :eof)
if %verb%==1 if %_sum%==0 (echo.&echo All applicable updates are detected as installed&goto :eof)
if %verb%==0 if %_sum%==0 (echo.&echo All applicable updates are detected as installed&call set discardre=1&goto :eof)
if %listc% lss %ac% (set ldr%list%=%ldr%)
if defined servicingstack (
if %verb%==1 (
echo.
echo ============================================================
echo Installing servicing stack update...
echo ============================================================
)
"%dismroot%" %dismtarget% /NoRestart /Add-Package %servicingstack%
if not defined ldr if not defined cumulative call :cleanup
)
if not defined ldr if not defined cumulative goto :eof
if %verb%==1 (
echo.
echo ============================================================
echo Installing updates...
echo ============================================================
)
if defined ldr "%dismroot%" %dismtarget% /NoRestart /Add-Package %ldr%
if defined cumulative "%dismroot%" %dismtarget% /NoRestart /Add-Package %cumulative%
if %errorlevel% equ 1726 (
echo.
echo retrying..
"%dismroot%" %dismtarget% /Get-Packages %_Nul_1%
if defined cumulative "%dismroot%" %dismtarget% /NoRestart /Add-Package %cumulative%
)
call :cleanup
goto :eof

:mum
if %listc% geq %ac% (set /a AC+=100&set /a list+=1&set ldr%list%=%ldr%&set ldr=)
set /a listc+=1
set "package=%1"
set "dest=%cab_dir%\%~n1"
if not exist "%dest%\update.mum" (set /a _sum-=1&goto :eof)
if "%build%" geq "17763" if not exist "%mumtarget%\sources\recovery\RecEnv.exe" (
findstr /i /m "WinPE-NetFx-Package" "%dest%\update.mum" %_Nul_1_2% && (if exist "%dest%\*_*10.0.*.manifest" if not exist "%dest%\*_netfx4clientcorecomp*.manifest" (set "netfx=!netfx! /packagepath:%dest%\update.mum"))
)
for /f "tokens=2 delims=-" %%V in ('dir /b %package%') do set kb=%%V
set "mumcheck=package_*_for_%kb%~*.mum"
if exist "%mumtarget%\Windows\servicing\packages\%mumcheck%" (
call :mumversion "%mumtarget%"
if !skip!==1 set /a _sum-=1&goto :eof
)
if exist "%mumtarget%\sources\recovery\RecEnv.exe" (
findstr /i /m "WinPE" "%dest%\update.mum" %_Nul_1_2% || (findstr /i /m "Package_for_RollupFix" "%dest%\update.mum" %_Nul_1_2% || (set /a _sum-=1&goto :eof))
findstr /i /m "WinPE-NetFx-Package" "%dest%\update.mum" %_Nul_1_2% && (findstr /i /m "Package_for_RollupFix" "%dest%\update.mum" %_Nul_1_2% || (set /a _sum-=1&goto :eof))
)
if exist "%dest%\*_adobe-flash-for-windows_*.manifest" (
if not exist "%mumtarget%\Windows\servicing\packages\Adobe-Flash-For-Windows-Package*.mum" if not exist "%mumtarget%\Windows\servicing\packages\Microsoft-Windows-Client-Desktop-Required-Package*.mum" (set /a _sum-=1&goto :eof)
if "%build%" geq "16299" (
  set flash=0
  for /f "tokens=3 delims=<= " %%a in ('findstr /i "Edition" "%dest%\update.mum" %_Nul_2e%') do if exist "%mumtarget%\Windows\servicing\packages\%%~a*.mum" set flash=1
  if "!flash!"=="0" (set /a _sum-=1&goto :eof)
  )
)
if exist "%dest%\*_microsoft-windows-servicingstack_*.manifest" (set "servicingstack=!servicingstack! /packagepath:%dest%\update.mum"&goto :eof)
for %%a in (%directcab%) do (
if /i !package!==%%a (set "ldr=!ldr! /packagepath:!package!"&goto :eof)
)
findstr /i /m "Package_for_RollupFix" "%dest%\update.mum" %_Nul_1_2% && (set "cumulative=!cumulative! /packagepath:%dest%\update.mum"&goto :eof)
set ldr=!ldr! /packagepath:%dest%\update.mum
goto :eof

:mumversion
set skip=0
set inver=0
set kbver=0
for /f "tokens=4-7 delims=~." %%i in ('dir /b /od "%~1\Windows\servicing\packages\%mumcheck%"') do set inver=%%i%%j%%k%%l
mkdir "%cab_dir%\check"
if %msu% equ 1 (expand.exe -f:*Windows*.cab %package% "%cab_dir%\check" >nul) else (copy %package% "%cab_dir%\check" >nul)
expand.exe -f:package_1_for_*.mum "%cab_dir%\check\*.cab" "%cab_dir%\check" 1>nul 2>nul
if not exist "%cab_dir%\check\*.mum" (set skip=1&rmdir /s /q "%cab_dir%\check"&goto :eof)
for /f "tokens=4-7 delims=~." %%i in ('dir /b "%cab_dir%\check\%mumcheck%"') do set kbver=%%i%%j%%k%%l
if %inver% geq %kbver% set skip=1
rmdir /s /q "%cab_dir%\check"
goto :eof

:enablenet35
if exist "%mumtarget%\sources\recovery\RecEnv.exe" goto :eof
if exist "%mumtarget%\Windows\Microsoft.NET\Framework\v2.0.50727\ngen.exe" goto :eof
if not defined net35source (
for %%b in (D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do if exist "%%b:\sources\sxs\*netfx3*.cab" set "net35source=%%b:\sources\sxs"
if %dvd%==1 if exist "%target%\sources\sxs\*netfx3*.cab" (set "net35source=%target%\sources\sxs")
if %wim%==1 for %%i in ("%target%") do if exist "%%~dpisxs\*netfx3*.cab" set "net35source=%%~dpisxs"
)
if not defined net35source goto :eof
if not exist "%net35source%" goto :eof
echo.
echo ============================================================
echo Adding .NET Framework 3.5 feature
echo ============================================================
"%dismroot%" %dismtarget% /NoRestart /Enable-Feature /FeatureName:NetFx3 /All /LimitAccess /Source:"%net35source%"
if "%build%" lss "17763" if defined cumulative (
echo.
echo ============================================================
echo Reinstalling cumulative update...
echo ============================================================
"%dismroot%" %dismtarget% /NoRestart /Add-Package %cumulative%
)
if "%build%" geq "17763" if defined netfx (
echo.
echo ============================================================
echo Reinstalling .NET cumulative update...
echo ============================================================
"%dismroot%" %dismtarget% /NoRestart /Add-Package %netfx%
)
call :cleanup
goto :eof

:counter
set _msu=0
set _cab=0
set _sum=0
cd /d "%repo%"
if exist "*Windows10*%arch%*.msu" (for /f %%a in ('dir /b *Windows10*%arch%*.msu') do (call set /a _msu+=1))
if exist "*Windows10*%arch%*.cab" (for /f %%a in ('dir /b *Windows10*%arch%*.cab') do (call set /a _cab+=1))
set /a _sum=%_msu%+%_cab%
goto :eof

:cleaner
cd /d "%~dp0"
if exist "%cab_dir%\*" (
echo.
echo ============================================================
echo Removing temporary extracted files...
echo ============================================================
echo.
rmdir /s /q "%cab_dir%" %_Nul_1%
)
if defined msucab (
  for %%a in (%msucab%) do (del /f /q "%repo%\*%%a*.cab" %_Nul_1_2%)
  set msucab=
)
goto :eof

:mount
if exist "%mountdir%" rmdir /s /q "%mountdir%" >nul
if exist "%winremount%" rmdir /s /q "%winremount%" >nul
if not exist "%mountdir%" mkdir "%mountdir%"
for %%i in (%indices%) do (
echo.
echo ============================================================
echo Mounting %~nx1 - index %%i/%imgcount%
echo ============================================================
"%dismroot%" /Mount-Wim /Wimfile:%1 /Index:%%i /MountDir:"%mountdir%"
if %errorlevel% neq 0 goto :E_MOUNT
call :update
if %net35%==1 call :enablenet35
if %dvd%==1 if exist "%mountdir%\sources\setup.exe" (
xcopy /CDRY "%mountdir%\sources" "%target%\sources" %_Nul_1_2%
del /f /q "%target%\sources\background.bmp" %_Nul_1_2%
del /f /q "%target%\sources\xmllite.dll" %_Nul_1_2%
del /f /q "%target%\efi\microsoft\boot\*noprompt.*" %_Nul_1_2%
if /i %arch%==x64 (set efifile=bootx64.efi&set sss=amd64) else (set efifile=bootia32.efi&set sss=x86)
copy /y "%mountdir%\Windows\Boot\DVD\EFI\en-US\efisys.bin" "%target%\efi\microsoft\boot\" %_Nul_1%
copy /y "%mountdir%\Windows\Boot\EFI\memtest.efi" "%target%\efi\microsoft\boot\" %_Nul_1%
copy /y "%mountdir%\Windows\Boot\EFI\bootmgfw.efi" "%target%\efi\boot\!efifile!" %_Nul_1%
copy /y "%mountdir%\Windows\Boot\EFI\bootmgr.efi" "%target%\" %_Nul_1%
copy /y "%mountdir%\Windows\Boot\PCAT\bootmgr" "%target%\" %_Nul_1%
copy /y "%mountdir%\Windows\Boot\PCAT\memtest.exe" "%target%\boot\" %_Nul_1%
for /f "tokens=6,7 delims=_." %%i in ('dir /b /a:-d /od "%mountdir%\Windows\WinSxS\Manifests\!sss!_microsoft-windows-coreos-revision*.manifest"') do set isover=%%i.%%j
)
if %wim%==1 if exist "%mountdir%\sources\setup.exe" if exist "%~dp1setup.exe" (
xcopy /CDRY "%mountdir%\sources\setup.exe" "%~dp1" %_Nul_1_2%
)
attrib -S -H -I "%mountdir%\Windows\System32\Recovery\winre.wim" %_Nul_1_2%
if %winre%==1 if exist "%mountdir%\Windows\System32\Recovery\winre.wim" if not exist "%~dp0winre.wim" (
  echo.
  echo ============================================================
  echo Updating winre.wim
  echo ============================================================
  mkdir "!winremount!"
  copy "!mountdir!\Windows\System32\Recovery\winre.wim" "%~dp0winre.wim" %_Nul_1%
  "!dismroot!" /Mount-Wim /Wimfile:"%~dp0winre.wim" /Index:1 /MountDir:"!winremount!"
  if %errorlevel% neq 0 goto :E_MOUNT
  call :update winre
  if !discardre!==1 (
  "!dismroot!" /Unmount-Wim /MountDir:"!winremount!" /Discard
  if !errorlevel! neq 0 goto :E_MOUNT
  ) else (
  "!dismroot!" /Unmount-Wim /MountDir:"!winremount!" /Commit
  if !errorlevel! neq 0 goto :E_MOUNT
  "!dismroot!" /Export-Image /SourceImageFile:"%~dp0winre.wim" /All /DestinationImageFile:"%~dp0temp.wim"
  move /y "%~dp0temp.wim" "%~dp0winre.wim" %_Nul_1%
  )
  set "mumtarget=!mumtarget_b!"
  set dismtarget=/image:"!mountdir!"
)
if exist "%mountdir%\Windows\System32\Recovery\winre.wim" if exist "%~dp0winre.wim" (
echo.
echo ============================================================
echo Adding updated winre.wim
echo ============================================================
echo.
copy /y "%~dp0winre.wim" "%mountdir%\Windows\System32\Recovery"
)
echo.
echo ============================================================
echo Unmounting %~nx1 - index %%i/%imgcount%
echo ============================================================
if !discard!==1 (
"%dismroot%" /Unmount-Wim /MountDir:"%mountdir%" /Discard
) else (
"%dismroot%" /Unmount-Wim /MountDir:"%mountdir%" /Commit
)
if %errorlevel% neq 0 goto :E_MOUNT
)
echo.
echo ============================================================
echo Rebuilding %~nx1
echo ============================================================
"%dismroot%" /Export-Image /SourceImageFile:%1 /All /DestinationImageFile:"%~dp0temp.wim"
move /y "%~dp0temp.wim" %1 %_Nul_1%
goto :eof

:cleanup
if exist "%mumtarget%\sources\recovery\RecEnv.exe" (
if %verb%==1 (
echo.
echo ============================================================
echo Resetting WinPE image base
echo ============================================================
)
if "%build%" geq "16299" (
set ksub=SOFTWIM
%_reg% load HKLM\!ksub! "%mumtarget%\Windows\System32\Config\SOFTWARE" %_Nul_1%
%_reg% add HKLM\!ksub!\Microsoft\Windows\CurrentVersion\SideBySide\Configuration /v SupersededActions /t REG_DWORD /d 1 /f %_Nul_1%
%_reg% unload HKLM\!ksub! %_Nul_1%
"%dismroot%" %dismtarget% /Cleanup-Image /StartComponentCleanup
if !errorlevel! equ 1726 "%dismroot%" %dismtarget% /Get-Packages %_Nul_1%
)
"%dismroot%" %dismtarget% /Cleanup-Image /StartComponentCleanup /ResetBase
if !errorlevel! equ 1726 "%dismroot%" %dismtarget% /Get-Packages %_Nul_1%
call :cleanupmanual
goto :eof
)
if %cleanup%==0 call :cleanupmanual&goto :eof
if exist "%mumtarget%\Windows\WinSxS\pending.xml" call :cleanupmanual&goto :eof
if %online%==0 (
set ksub=SOFTWIM
%_reg% load HKLM\!ksub! "%mumtarget%\Windows\System32\Config\SOFTWARE" %_Nul_1%
) else (
set ksub=SOFTWARE
)
if %resetbase%==0 (
echo.
echo ============================================================
echo Cleaning up OS image
echo ============================================================
%_reg% add HKLM\%ksub%\Microsoft\Windows\CurrentVersion\SideBySide\Configuration /v DisableResetbase /t REG_DWORD /d 1 /f %_Nul_1%
%_reg% add HKLM\%ksub%\Microsoft\Windows\CurrentVersion\SideBySide\Configuration /v SupersededActions /t REG_DWORD /d 0 /f %_Nul_1%
if %online%==0 %_reg% unload HKLM\%ksub% %_Nul_1%
"%dismroot%" %dismtarget% /NoRestart /Cleanup-Image /StartComponentCleanup
if !errorlevel! equ 1726 "%dismroot%" %dismtarget% /Get-Packages %_Nul_1%
) else (
echo.
echo ============================================================
echo Resetting OS image base
echo ============================================================
%_reg% add HKLM\%ksub%\Microsoft\Windows\CurrentVersion\SideBySide\Configuration /v DisableResetbase /t REG_DWORD /d 0 /f %_Nul_1%
%_reg% add HKLM\%ksub%\Microsoft\Windows\CurrentVersion\SideBySide\Configuration /v SupersededActions /t REG_DWORD /d 1 /f %_Nul_1%
if %online%==0 %_reg% unload HKLM\%ksub% %_Nul_1%
if %online%==0 if "%build%" geq "16299" "%dismroot%" %dismtarget% /NoRestart /Cleanup-Image /StartComponentCleanup
if !errorlevel! equ 1726 "%dismroot%" %dismtarget% /Get-Packages %_Nul_1%
"%dismroot%" %dismtarget% /NoRestart /Cleanup-Image /StartComponentCleanup /ResetBase
if !errorlevel! equ 1726 "%dismroot%" %dismtarget% /Get-Packages %_Nul_1%
)
call :cleanupmanual
goto :eof

:cleanupmanual
if %online%==1 goto :eof
if exist "%mumtarget%\Windows\WinSxS\ManifestCache\*.bin" (
takeown /f "%mumtarget%\Windows\WinSxS\ManifestCache\*.bin" /A %_Nul_1_2%
icacls "%mumtarget%\Windows\WinSxS\ManifestCache\*.bin" /grant *S-1-5-32-544:F %_Nul_1_2%
del /f /q "%mumtarget%\Windows\WinSxS\ManifestCache\*.bin" %_Nul_1_2%
)
if exist "%mumtarget%\Windows\WinSxS\Temp\PendingDeletes\*" (
takeown /f "%mumtarget%\Windows\WinSxS\Temp\PendingDeletes\*" /A 1>nul 2>nul
icacls "%mumtarget%\Windows\WinSxS\Temp\PendingDeletes\*" /grant *S-1-5-32-544:F 1>nul 2>nul
del /f /q "%mumtarget%\Windows\WinSxS\Temp\PendingDeletes\*" %_Nul_1_2%
)
if exist "%mumtarget%\Windows\WinSxS\Temp\TransformerRollbackData\*" (
takeown /f "%mumtarget%\Windows\WinSxS\Temp\TransformerRollbackData\*" /R /A %_Nul_1_2%
icacls "%mumtarget%\Windows\WinSxS\Temp\TransformerRollbackData\*" /grant *S-1-5-32-544:F /T %_Nul_1_2%
del /s /f /q "%mumtarget%\Windows\WinSxS\Temp\TransformerRollbackData\*" %_Nul_1_2%
)
if exist "%mumtarget%\Windows\inf\*.log" (
del /f /q "%mumtarget%\Windows\inf\*.log" %_Nul_1_2%
)
if exist "%mumtarget%\Windows\CbsTemp\*" (
for /f %%i in ('"dir /s /b /ad %mumtarget%\Windows\CbsTemp\*" %_Nul_2e%') do (RD /S /Q %%i %_Nul_1_2%)
del /s /f /q "%mumtarget%\Windows\CbsTemp\*" %_Nul_1_2%
)
goto :eof

:E_Target
echo.
echo ============================================================
echo ERROR: %MESSAGE%
echo ============================================================
echo.
echo Press any key to continue.
if %_Debug% EQU 0 pause >nul
set "target=%SystemDrive%"
goto :mainmenu

:E_Repo
echo.
echo ============================================================
echo ERROR: Specified location is not valid
echo ============================================================
echo.
echo Press any key to continue.
if %_Debug% EQU 0 pause >nul
set "repo=%cd%"
call :counter
if %_sum%==0 set "repo="
goto :mainmenu

:E_MOUNT
echo.
echo ============================================================
echo ERROR: Could not mount or unmount WIM image
echo ============================================================
echo.
echo Press any key to exit.
if %_Debug% EQU 0 pause >nul
exit

:E_Admin
echo.
echo ============================================================
echo ERROR: right click on the script and 'Run as administrator'
echo ============================================================
echo.
echo Press any key to exit.
if %_Debug% EQU 0 pause >nul
goto :eof

:checkadk
SET regKeyPathFound=1
SET wowRegKeyPathFound=1
REG QUERY "HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 %_Nul_1_2% || SET wowRegKeyPathFound=0
REG QUERY "HKLM\Software\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 %_Nul_1_2% || SET regKeyPathFound=0
if %wowRegKeyPathFound% EQU 0 (
  if %regKeyPathFound% EQU 0 (
    goto :mainmenu
  ) else (
    SET regKeyPath=HKLM\Software\Microsoft\Windows Kits\Installed Roots
  )
) else (
    SET regKeyPath=HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots
)
FOR /F "skip=2 tokens=2*" %%i IN ('REG QUERY "%regKeyPath%" /v KitsRoot10') DO (SET "KitsRoot=%%j")
SET "DandIRoot=%KitsRoot%Assessment and Deployment Kit\Deployment Tools"
SET "oscdimgroot=%DandIRoot%\%PROCESSOR_ARCHITECTURE%\Oscdimg\oscdimg.exe"
SET "dismroot=%DandIRoot%\%PROCESSOR_ARCHITECTURE%\DISM\dism.exe"
if not exist "%dismroot%" set "dismroot=%windir%\system32\dism.exe"
goto :mainmenu

:targetmenu
cls
echo ============================================================
echo Enter the path for one of supported targets:
echo - Distribution folder ^(extracted iso, copied dvd/usb^)
echo - WIM file
echo - Mounted directory, offline image drive letter
echo - Current OS / Enter %SystemDrive%
echo.
echo or just press 'Enter' to return to options menu
echo ============================================================
echo.
set /p "_pp="
if "%_pp%"=="" goto :mainmenu
if "%_pp:~-1%"=="\" set "_pp=%_pp:~0,-1%"
set dvd=0
set wim=0
set offline=0
set online=0
set copytarget=0
set img=0
set "target=%_pp%"
if /i "%target%"=="%SystemDrive%" set online=1&goto :mainmenu
echo %target%| findstr /E /I "\.wim" %_Nul_1%
if %errorlevel%==0 (
set wim=1
for /f %%i in ('dir /b "%target%"') do set "targetname=%%i"
) else (
if exist "%target%\sources\boot.wim" set dvd=1 
if exist "%target%\Windows\regedit.exe" set offline=1
)
if %offline%==0 if %wim%==0 if %dvd%==0 (set "MESSAGE=Specified location is not valid"&goto :E_Target)
if %offline%==1 (
dir /b "%target%\Windows\servicing\Version\10.0.*" %_Nul_1_2% || (set "MESSAGE=Detected target offline image is not Windows 10"&goto :E_Target)
for /f "tokens=3 delims=." %%i in ('dir /b "%target%\Windows\servicing\Version\10.0.*"') do set build=%%i
set "mountdir=%target%"
if exist "%target%\Windows\SysWOW64\*" (set arch=x64) else (set arch=x86)
)
if %dvd%==1 (
echo.
echo ============================================================
echo Please wait...
echo ============================================================
dir /b /s /adr "%target%" %_Nul_1_2% && set copytarget=1
dism /english /get-wiminfo /wimfile:"%target%\sources\install.wim" /index:1 | find /i "Version : 10.0" %_Nul_1% || (set "MESSAGE=Detected install.wim version is not Windows 10"&goto :E_Target)
for /f "tokens=4 delims=:. " %%i in ('dism /english /get-wiminfo /wimfile:"%target%\sources\install.wim" /index:1 ^| find /i "Version :"') do set build=%%i
for /f "tokens=2 delims=: " %%i in ('dism /english /get-wiminfo /wimfile:"%target%\sources\install.wim" /index:1 ^| find /i "Architecture"') do set arch=%%i
for /f "tokens=2 delims=: " %%i in ('dism /english /get-wiminfo /wimfile:"%target%\sources\install.wim" ^| findstr "Index"') do set imgcount=%%i
for /f "tokens=2 delims=: " %%i in ('dism /english /get-wiminfo /wimfile:"%target%\sources\boot.wim" ^| findstr "Index"') do set bootimg=%%i
for /L %%i in (1,1,!imgcount!) do (
  for /f "tokens=1* delims=: " %%a in ('dism /english /get-wiminfo /wimfile:"%target%\sources\install.wim" /index:%%i ^| findstr /b /c:"Name"') do set name%%i="%%b"
  )
set "indices=*"
)
if %wim%==1 (
echo.
echo ============================================================
echo Please wait...
echo ============================================================
dism /english /get-wiminfo /wimfile:"%target%" /index:1 | find /i "Version : 10.0" %_Nul_1% || (set "MESSAGE=Detected wim version is not Windows 10"&goto :E_Target)
for /f "tokens=4 delims=:. " %%i in ('dism /english /get-wiminfo /wimfile:"%target%" /index:1 ^| find /i "Version :"') do set build=%%i
for /f "tokens=2 delims=: " %%i in ('dism /english /get-wiminfo /wimfile:"%target%" /index:1 ^| find /i "Architecture"') do set arch=%%i
for /f "tokens=2 delims=: " %%i in ('dism /english /get-wiminfo /wimfile:"%target%" ^| findstr "Index"') do set imgcount=%%i
for /L %%i in (1,1,!imgcount!) do (
  for /f "tokens=1* delims=: " %%a in ('dism /english /get-wiminfo /wimfile:"%target%" /index:%%i ^| findstr /b /c:"Name"') do set name%%i="%%b"
  )
set "indices=*"
)
set "repo=%cd%"
call :counter
if %_sum%==0 set "repo="
goto :mainmenu

:repomenu
cls
echo ============================================================
echo Enter the Updates location path
echo.
echo or just press 'Enter' to return to options menu
echo ============================================================
echo.
set /p "_pp="
if "%_pp%"=="" goto :mainmenu
if "%_pp:~-1%"=="\" set "_pp=%_pp:~0,-1%"
set "repo=%_pp%"
if not exist "%repo%\*Windows10*.msu" if not exist "%repo%\*Windows10*.cab" (goto :E_Repo)
goto :mainmenu

:dismmenu
cls
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
set /p "_pp="
if "%_pp%"=="" goto :mainmenu
set "dismroot=%_pp%"
if not exist "%dismroot%" (
echo not found: "%dismroot%"
if %_Debug% EQU 0 pause
set "dismroot=%windir%\system32\dism.exe"
)
"%dismroot%" | findstr /I /B "Version" >dismver.txt
for /f "tokens=4 delims=:. " %%i in (dismver.txt) do set _ver=%%i
del /f /q dismver.txt
if %_ver% lss 10240 (
echo.
echo ERROR: DISM version is lower than 10.0.10240.16384
if %_Debug% EQU 0 pause
set "dismroot=%windir%\system32\dism.exe"
)
goto :mainmenu

:extractmenu
cls
echo ============================================================
echo Enter the directory path for extracting updates
echo make sure the drive has enough free space ^(at least 10 GB^)
echo.
echo or just press 'Enter' to return to options menu
echo ============================================================
echo.
set /p "_pp="
if "%_pp%"=="" goto :mainmenu
if "%_pp:~-1%"=="\" set "_pp=%_pp:~0,-1%"
set "cab_dir=%_pp%"
goto :mainmenu

:mountmenu
cls
echo ============================================================
echo Enter the directory path for mounting install.wim
echo make sure the drive has enough free space ^(at least 10 GB^)
echo it must be on NTFS formatted partition
echo.
echo or just press 'Enter' to return to options menu
echo ============================================================
echo.
set /p "_pp="
if "%_pp%"=="" goto :mainmenu
if "%_pp:~-1%"=="\" set "_pp=%_pp:~0,-1%"
set "mountdir=%_pp%"
goto :mainmenu

:indexmenu
cls
echo ============================================================
for /L %%i in (1,1,%imgcount%) do (
echo. %%i. !name%%i!
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
set /p "_pp="
if "%_pp%"=="" goto :mainmenu
if "%_pp%"=="*" set "indices=%_pp%"&goto :mainmenu
for %%i in (%_pp%) do (
if %%i gtr %imgcount% echo.&echo %%i is higher than available indexes&pause&set _pp=&goto :indexmenu
if %%i equ 0 echo.&echo 0 is not valid index&pause&set _pp=&goto :indexmenu
)
set "indices=%_pp%"
goto :mainmenu

:mainmenu
if %autostart%==1 goto :mainboard
set _pp=
cls
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
if /i "%dismroot%"=="%windir%\system32\dism.exe" (echo 3. Select Windows 10 dism.exe) else (echo 3. DISM: "%dismroot%")
) else (
echo 3. DISM: "%dismroot%"
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
if %dvd%==1 (
if %winre%==1 (echo 7. Update WinRE.wim: YES) else (echo 7. Update WinRE.wim: NO)
echo.
if %imgcount% gtr 1 (if "%indices%"=="*" (echo 8. Install.wim selected indexes: All ^(%imgcount%^)) else (echo 8. Install.wim selected indexes: %indices%))
echo.
echo M. Mount Directory: "%mountdir%"
echo.
)
if %wim%==1 (
if %winre%==1 (echo 7. Update WinRE.wim: YES) else (echo 7. Update WinRE.wim: NO)
echo.
if %imgcount% gtr 1 (if "%indices%"=="*" (echo 8. Selected Install.wim indexes: All ^(%imgcount%^)) else (echo 8. Selected Install.wim indexes: %indices%))
echo.
echo M. Mount Directory: "%mountdir%"
echo.
)
echo E. Extraction Directory: "%cab_dir%"
echo ============================================================
echo 0. Start the process
echo ============================================================
echo.
choice /c 1234567890EM /n /m "Change a menu option, press 0 to start, or 9 to exit: "
if errorlevel 12 goto :mountmenu
if errorlevel 11 goto :extractmenu
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
if not exist "%oscdimgroot%" if not exist "%~dp0cdimage.exe" if not exist "%~dp0oscdimg.exe" goto :eof
for /f "skip=1" %%x in ('wmic os get localdatetime') do if not defined MyDate set MyDate=%%x
set isodate=%MyDate:~0,4%-%MyDate:~4,2%-%MyDate:~6,2%
set isofile=Win10_%isover%_%arch%_%isodate%.iso
if exist "%isofile%" (echo %isofile% already exist in current directory&goto :eof)
echo.
echo ============================================================
echo Creating updated ISO file...
echo ============================================================
if exist "%oscdimgroot%" (set _ff="%oscdimgroot%") else if exist "%~dp0cdimage.exe" (set _ff=cdimage.exe) else (set _ff=oscdimg.exe)
%_ff% -m -o -u2 -udfver102 -bootdata:2#p0,e,b"%target%\boot\etfsboot.com"#pEF,e,b"%target%\efi\microsoft\boot\efisys.bin" -l"%isover%" "%target%" %isofile%
if %errorlevel% equ 0 if %delete_source% equ 1 rmdir /s /q "%target%" %_Nul_1%
if exist "%~dp0DVD" rmdir /s /q "%~dp0DVD" %_Nul_1%
goto :eof

:fin
call :cleaner
if %dvd%==1 (if exist "%mountdir%" rmdir /s /q "%mountdir%" %_Nul_1%)
if %wim%==1 (if exist "%mountdir%" rmdir /s /q "%mountdir%" %_Nul_1%)
if exist "%winremount%" rmdir /s /q "%winremount%" %_Nul_1%
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
echo Press any key to exit.
if %_Debug% EQU 0 pause >nul
goto :eof
