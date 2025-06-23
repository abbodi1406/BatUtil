@setlocal DisableDelayedExpansion
@echo off

:: ###################################################################
:: # Script Settings - Adjust these as needed                      #
:: ###################################################################

:: --- Source ---
:: Set the path to your Windows ISO, extracted folder, or drive letter
:: Leave blank to be prompted.
set "DVDPATH=" 

:: --- Options ---
:: Create a new ISO file at the end? (1 = Yes, 0 = No) 
set ISO=1
:: Integrate updates into WinPE/WinRE images? (1 = Yes, 0 = No) 
:: Requires Updates\W10UI.cmd to support WinPE/WinRE targets.
set INTEGRATE_WINPE_UPDATES=1
:: Enable .NET Framework 3.5? (1 = Yes, 0 = No) 
:: Requires the original sources\sxs folder in your DVDPATH.
set NET35=0 

:: --- Paths ---
:: Optional: Set a specific mount directory
set "MOUNTDIR="
:: Optional: dism.exe tool custom path
set "DismRoot=dism.exe"

:: --- Debug ---
:: Enable debug mode (outputs detailed log) (1 = Yes, 0 = No)
set _Debug=0

:: ###################################################################
:: # DO NOT CHANGE ANYTHING BELOW THIS COMMENT                       #
:: ###################################################################

set "_cmdf=%~f0"
if exist "%SystemRoot%\Sysnative\cmd.exe" (
    setlocal EnableDelayedExpansion
    start %SystemRoot%\Sysnative\cmd.exe /c ""!_cmdf!" "
    exit /b
)
if exist "%SystemRoot%\SysArm32\cmd.exe" if /i %PROCESSOR_ARCHITECTURE%==AMD64 (
    setlocal EnableDelayedExpansion
    start %SystemRoot%\SysArm32\cmd.exe /c ""!_cmdf!" " 
    exit /b
)

set "SysPath=%SystemRoot%\System32"
set "Path=%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
if exist "%SystemRoot%\Sysnative\reg.exe" (
    set "SysPath=%SystemRoot%\Sysnative"
    set "Path=%SystemRoot%\Sysnative;%SystemRoot%;%SystemRoot%\Sysnative\Wbem;%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\;%Path%"
)
set "xOS=amd64"
if /i "%PROCESSOR_ARCHITECTURE%"=="arm64" set "xOS=arm64"
if /i "%PROCESSOR_ARCHITECTURE%"=="x86" if "%PROCESSOR_ARCHITEW6432%"=="" set "xOS=x86"
if /i "%PROCESSOR_ARCHITEW6432%"=="amd64" set "xOS=amd64"
if /i "%PROCESSOR_ARCHITEW6432%"=="arm64" set "xOS=arm64"
set "_Null=1>nul 2>nul"
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
reg.exe query HKU\S-1-5-19 %_Null% || goto :E_ADMIN
set "_log=%~dpn0"
set "WORKDIR=%~dp0"
set "WORKDIR=%WORKDIR:~0,-1%"
set "DVDDIR=%WORKDIR%\_DVD10"
set "TEMPDIR=%~d0\W10MUITEMP"
set "TMPDISM=%TEMPDIR%\scratch"
set "TMPUPDT=%TEMPDIR%\updtemp"
set "_7z=%WORKDIR%\dism\7z.exe"
for /f "skip=2 tokens=2*" %%a in ('reg.exe query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop') do call set "_dsk=%%b"
if exist "%PUBLIC%\Desktop\desktop.ini" set "_dsk=%PUBLIC%\Desktop"

setlocal EnableDelayedExpansion

if %_Debug% equ 0 ( 
  set "_Nul1=1>nul"
  set "_Nul2=2>nul"
  set "_Nul6=2^>nul"
  set "_Nul3=1>nul 2>nul"
  goto :Begin
)
  set "_Nul1="
  set "_Nul2="
  set "_Nul6="
  set "_Nul3="
copy /y nul "!WORKDIR!\#.rw" %_Null% && (if exist "!WORKDIR!\#.rw" del /f /q "!WORKDIR!\#.rw") || (set "_log=!_dsk!\%~n0")
echo.
echo  Running in debug mode... 
echo  The window will close upon completion. 
@echo on 
@prompt $G
@call :Begin >"!_log!_tmp.log" 2>&1 &cmd /u /c type "!_log!_tmp.log">"!_log!_Debug.log"&del "!_log!_tmp.log" 
@title %ComSpec%
@exit /b

:Begin
title ISO Update Integrator
set "_dLog=%SystemRoot%\Logs\DISM"
set _drv=%~d0
set _ntf=NTFS
if /i not "%_drv%"=="%SystemDrive%" if %_cwmi% equ 1 for /f "tokens=2 delims==" %%# in ('"wmic volume where DriveLetter='%_drv%' get FileSystem /value"') do set "_ntf=%%#"
if /i not "%_drv%"=="%SystemDrive%" if %_cwmi% equ 0 for /f %%# in ('%_psc% "(([WMISEARCHER]'Select * from Win32_Volume where DriveLetter=\"%_drv%\"').Get()).FileSystem"') do set "_ntf=%%#"
if /i not "%_ntf%"=="NTFS" set _drv=%SystemDrive%
if "!MOUNTDIR!"=="" set "MOUNTDIR=%_drv%\WIM_UPDATER_MOUNT"
set "MOUNTDIR=%MOUNTDIR:"=%"
if "%MOUNTDIR:~-1%"=="\" set "MOUNTDIR=%MOUNTDIR:~0,-1%"
set "INSTALLMOUNTDIR=%MOUNTDIR%\install"
set "WINREMOUNTDIR=%MOUNTDIR%\winre"
set "BOOTMOUNTDIR=%MOUNTDIR%\boot"

goto :adk10

:DismVer
set _all=0
set "dsmver=10240"
if %_cwmi% equ 1 for /f "tokens=4 delims==." %%# in ('wmic datafile where "name='!dsv!'" get Version /value') do set "dsmver=%%#" 
if %_cwmi% equ 0 for /f "tokens=3 delims=." %%# in ('%_psc% "([WMI]'CIM_DataFile.Name=''!dsv!''').Version"') do set "dsmver=%%#"
if %dsmver% lss 25115 set _all=1
exit /b

:adk10
if /i not "!dismroot!"=="dism.exe" (
    goto :check
)
set regKeyPathFound=1
set wowRegKeyPathFound=1
reg.exe query "HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 %_Nul3% || set wowRegKeyPathFound=0 
reg.exe query "HKLM\Software\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 %_Nul3% || set regKeyPathFound=0 
if %wowRegKeyPathFound% equ 0 (
  if %regKeyPathFound% equ 0 (
    goto :skipadk
  ) else (
    set regKeyPath=HKLM\Software\Microsoft\Windows Kits\Installed Roots
  )
) else (
    set regKeyPath=HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots
)
for /f "skip=2 tokens=2*" %%i in ('reg.exe query "%regKeyPath%" /v KitsRoot10') do set "KitsRoot=%%j"
set "DandIRoot=%KitsRoot%Assessment and Deployment Kit\Deployment Tools"
if exist "%DandIRoot%\x86\DISM\dism.exe" if /i %xOS%==arm64 (
    set "DismRoot=%DandIRoot%\x86\DISM\dism.exe"
    goto :check
)
if exist "%DandIRoot%\%xOS%\DISM\dism.exe" (
    set "DismRoot=%DandIRoot%\%xOS%\DISM\dism.exe"
    goto :check
)

:skipadk
set "DismRoot=!WORKDIR!\dism\dism.exe"
if /i %xOS%==amd64 set "DismRoot=!WORKDIR!\dism\dism64\dism.exe"
if %winbuild% GEQ 10240 set "DismRoot=%SysPath%\dism.exe"

:check
if not exist "!DismRoot!" goto :E_BIN 
set _dism2="!DismRoot!" /English /ScratchDir
set "dsv=!dismroot:\=\\!"
call :DismVer
cd /d "!WORKDIR!"
if not exist "!_7z!" goto :E_BIN 
if not exist ".\Updates\W10UI.cmd" goto :E_UPDATER_SCRIPT

if not "!DVDPATH!"=="" goto :prepare
set _iso=0
if exist "*.iso" (for /f "delims=" %%i in ('dir /b /a:-d *.iso') do (call set /a _iso+=1))
if %_iso% neq 1 goto :prompt
for /f "delims=" %%i in ('dir /b /a:-d *.iso') do set "DVDPATH=%%i"
goto :prepare

:prompt
if %_Debug% neq 0 (
    set MESSAGE=ERROR: You must auto set DVDPATH in Debug mode
    goto :END
)
@cls
set DVDPATH=
echo.
echo ============================================================== 
echo  Enter the Windows distribution path (without quotation marks " "): 
echo  ISO file, Extracted ISO folder, DVD/USB drive letter 
echo ================================================================= 
echo.
set /p DVDPATH= 
if not defined DVDPATH exit /b
set "DVDPATH=%DVDPATH:"=%"
if "%DVDPATH:~-1%"=="\" set "DVDPATH=!DVDPATH:~0,-1!"

:prepare
if not exist "!DVDPATH!" goto :E_DVD
echo ==============================================================
echo  Running WIM update script
echo ================================================================
echo.
echo ===============================================================
echo  Preparing working directories
echo ===============================================================
echo.
if exist "!DVDDIR!\" rmdir /s /q "!DVDDIR!\" %_Nul3%
if exist "!TEMPDIR!\" rmdir /s /q "!TEMPDIR!\" %_Nul3%
if exist "!MOUNTDIR!\" rmdir /s /q "!MOUNTDIR!\" %_Nul3%
mkdir "!DVDDIR!" || goto :E_MKDIR
mkdir "!TEMPDIR!" || goto :E_MKDIR
mkdir "!TMPDISM!" || goto :E_MKDIR
mkdir "!TMPUPDT!" || goto :E_MKDIR
mkdir "%MOUNTDIR%" || goto :E_MKDIR
mkdir "%INSTALLMOUNTDIR%" || goto :E_MKDIR
mkdir "%WINREMOUNTDIR%" || goto :E_MKDIR
mkdir "%BOOTMOUNTDIR%" || goto :E_MKDIR 

echo.
echo ============================================================ 
echo  Copying distribution contents to the working directory 
echo ============================================================ 
echo.
echo  Source: 
echo  "!DVDPATH!"
del /f /q %_dLog%\* %_Nul3%
if not exist "%_dLog%\" mkdir "%_dLog%" %_Nul3%
if /i "%DVDPATH:~-4%"==".iso" (
   "!_7z!" x "!DVDPATH!" -o"!DVDDIR!" * -r %_Nul1%
) else (
   robocopy "!DVDPATH!" "!DVDDIR!" /E /A-:R /R:1 /W:1 /NFL /NDL /NP %_Nul1%
)
if %NET35% == 1 if not exist "!DVDDIR!\sources\sxs\*netfx3*.cab" (
    echo WARNING: .NET 3.5 integration enabled, but sources\sxs folder not found or missing netfx3 cab. Disabling NET35.
    set NET35=0
)
if not exist "!DVDDIR!\sources\install.wim" goto :E_WIM
dism\dism.exe /info "!DVDDIR!\sources\install.wim" | findstr /c:"LZMS" %_Nul1% && goto :E_ESD 

echo.
echo ============================================================
echo  Analyzing WIM files
echo ============================================================
echo.
for /f "tokens=2 delims=: " %%i in ('dism\dism.exe /english /get-wiminfo /wimfile:"!DVDDIR!\sources\install.wim" ^| findstr "Index"') do set imgcount=%%i 
for /f "tokens=4 delims=:. " %%i in ('dism\dism.exe /english /get-wiminfo /wimfile:"!DVDDIR!\sources\install.wim" /index:1 ^| find /i "Version :"') do set _build=%%i
echo  install.wim Build: %_build%
echo  install.wim Images: %imgcount%

if exist "!DVDDIR!\sources\boot.wim" (
    for /f "tokens=2 delims=: " %%i in ('dism\dism.exe /english /get-wiminfo /wimfile:"!DVDDIR!\sources\boot.wim" ^| findstr "Index"') do set BOOTCOUNT=%%i
    echo  boot.wim Images: %BOOTCOUNT%
) else (
    echo WARNING: boot.wim not found. Skipping boot.wim processing.
    set BOOTCOUNT=0
    set INTEGRATE_WINPE_UPDATES=0
)

set isomin=0
set errMOUNT=0

:: Process install.wim 
for /L %%i in (1,1,%imgcount%) do (
    if %errMOUNT% equ 0 set "_i=%%i" & call :doinstall
)
if %errMOUNT% neq 0 goto :END

:: Process boot.wim (optional)
if %BOOTCOUNT% gtr 0 if %INTEGRATE_WINPE_UPDATES% equ 1 (
    for /L %%i in (1,1,%BOOTCOUNT%) do (
        if %errMOUNT% equ 0 set "_i=%%i" & call :doboot
    )
)
if %errMOUNT% neq 0 goto :END

goto :rebuild

:: ###################################################################
:: # Subroutines                                                   # 
:: ###################################################################

:doinstall
echo.
echo ============================================================ 
echo  Mounting install.wim - index %_i%/%imgcount% 
echo ============================================================ 
!_dism2!:"!TMPDISM!" /Mount-Wim /Wimfile:"!DVDDIR!\sources\install.wim" /Index:%_i% /MountDir:"%INSTALLMOUNTDIR%"
if !errorlevel! neq 0 goto :E_MOUNT

echo.
echo ============================================================ 
echo  Applying updates (install.wim index %_i%)... 
echo ============================================================ 
call Updates\W10UI.cmd 1 "%INSTALLMOUNTDIR%" "!TMPUPDT!" "!DVDDIR!\sources" 
if %_Debug% neq 0 (@echo on) else (@echo off)
cd /d "!WORKDIR!" 
:: Get WIM version details (needed for ISO naming)
if not defined isomaj for /f "tokens=6,7 delims=_." %%a in ('dir /b /a:-d /od "%INSTALLMOUNTDIR%\Windows\WinSxS\Manifests\*_microsoft-windows-coreos-revision*.manifest" 2^>nul') do (set isover=%%a.%%b&set isomaj=%%a&set isomin=%%b) 

if %NET35%==1 if not exist "%INSTALLMOUNTDIR%\Windows\Microsoft.NET\Framework\v2.0.50727\ngen.exe" (
    echo.
    echo ============================================================
    echo  Enabling .NET Framework 3.5 - index %_i%/%imgcount%
    echo ============================================================
    !_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /LogPath:"%_dLog%\InstallNetFx3_%_i%.log" /Enable-Feature /Featurename:NetFx3 /All /LimitAccess /Source:"!DVDDIR!\sources\sxs"
)

:: Process WinRE (optional)
if exist "%INSTALLMOUNTDIR%\Windows\System32\Recovery\winre.wim" (
    if %INTEGRATE_WINPE_UPDATES% equ 1 if not exist "!TEMPDIR!\WR\winre_%_i%.wim" (
        call :wimre %_i%
        if %errMOUNT% neq 0 goto :unmount_install
        if exist "!TEMPDIR!\WR\winre_%_i%.wim" ( 
            echo.
            echo ============================================================ 
            echo  Applying updated winre.wim to install.wim - index %_i%/%imgcount% 
            echo ============================================================ 
            echo.
            attrib -S -H -I "%INSTALLMOUNTDIR%\Windows\System32\Recovery\winre.wim" %_Nul3% 
            copy /y "!TEMPDIR!\WR\winre_%_i%.wim" "%INSTALLMOUNTDIR%\Windows\System32\Recovery\winre.wim"
        )
    )
)

:unmount_install
call :cleanmanual "%INSTALLMOUNTDIR%"
echo.
echo ============================================================ 
echo  Unmounting install.wim - index %_i%/%imgcount% 
echo ============================================================ 
!_dism2!:"!TMPDISM!" /Unmount-Wim /MountDir:"%INSTALLMOUNTDIR%" /Commit
if !errorlevel! neq 0 goto :E_UNMOUNT
goto :eof

:wimre
echo.
echo ============================================================ 
echo  Processing winre.wim from install.wim index %1 
echo ============================================================ 
echo.
mkdir "!TEMPDIR!\WR" %_Nul3%
copy "%INSTALLMOUNTDIR%\Windows\System32\Recovery\winre.wim" "!TEMPDIR!\WR\winre_base_%1.wim"
echo.
echo ============================================================ 
echo  Mounting winre.wim 
echo ============================================================ 
!_dism2!:"!TMPDISM!" /Mount-Wim /Wimfile:"!TEMPDIR!\WR\winre_base_%1.wim" /Index:1 /MountDir:"%WINREMOUNTDIR%"
if !errorlevel! neq 0 ( 
    echo WARNING: Could not mount winre.wim for index %1. Skipping WinRE update.
    goto :eof
)

echo.
echo ============================================================ 
echo  Integrating updates (winre.wim from index %1)... 
echo ============================================================ 
call Updates\W10UI.cmd 1 "%WINREMOUNTDIR%" "!TMPUPDT!"
if %_Debug% neq 0 (@echo on) else (@echo off) 
cd /d "!WORKDIR!"

call :cleanmanual "%WINREMOUNTDIR%"
echo.
echo ============================================================
echo  Unmounting winre.wim
echo ============================================================
!_dism2!:"!TMPDISM!" /Unmount-Wim /MountDir:"%WINREMOUNTDIR%" /Commit 
if !errorlevel! neq 0 (
    echo WARNING: Could not unmount winre.wim for index %1. WinRE might not be updated.
    del /f /q "!TEMPDIR!\WR\winre_base_%1.wim" %_Nul3%
    goto :eof
)
echo.
echo ============================================================ 
echo  Rebuilding winre.wim 
echo ============================================================ 
!_dism2!:"!TMPDISM!" /Export-Image /SourceImageFile:"!TEMPDIR!\WR\winre_base_%1.wim" /SourceIndex:1 /DestinationImageFile:"!TEMPDIR!\WR\winre_%1.wim"
del /f /q "!TEMPDIR!\WR\winre_base_%1.wim" %_Nul3%
if not exist "!TEMPDIR!\WR\winre_%1.wim" echo WARNING: Failed to export updated winre.wim for index %1.
goto :eof 


:doboot
echo.
echo ============================================================
echo  Mounting boot.wim - index %_i%/%BOOTCOUNT%
echo ============================================================
!_dism2!:"!TMPDISM!" /Mount-Wim /WimFile:"!DVDDIR!\sources\boot.wim" /Index:%_i% /MountDir:"%BOOTMOUNTDIR%"
if !errorlevel! neq 0 goto :E_MOUNT

echo.
echo ============================================================ 
echo  Applying updates (boot.wim index %_i%)... 
echo ============================================================ 
set _keep=1
if %_i%==%BOOTCOUNT% set _keep=0
call Updates\W10UI.cmd %_keep% "%BOOTMOUNTDIR%" "!TMPUPDT!"
if %_Debug% neq 0 (@echo on) else (@echo off) 
cd /d "!WORKDIR!"

call :cleanmanual "%BOOTMOUNTDIR%"
echo.
echo ============================================================ 
echo  Unmounting boot.wim - index %_i%/%BOOTCOUNT% 
echo ============================================================ 
!_dism2!:"!TMPDISM!" /Unmount-Wim /MountDir:"%BOOTMOUNTDIR%" /Commit
if !errorlevel! neq 0 goto :E_UNMOUNT
goto :eof


:rebuild
echo.
echo ============================================================ 
echo  Rebuilding install.wim 
echo ============================================================ 
echo This step can take a long time...
if %_all% equ 1 !_dism2!:"!TMPDISM!" /Export-Image /SourceImageFile:"!DVDDIR!\sources\install.wim" /All /DestinationImageFile:"!DVDDIR!\install_updated.wim" /Compress:max 
if %_all% equ 0 for /L %%i in (1,1,%imgcount%) do !_dism2!:"!TMPDISM!" /Export-Image /SourceImageFile:"!DVDDIR!\sources\install.wim" /SourceIndex:%%i /DestinationImageFile:"!DVDDIR!\install_updated.wim" /Compress:max /CheckIntegrity 
if exist "!DVDDIR!\install_updated.wim" (
    del /f /q "!DVDDIR!\sources\install.wim" %_Nul3%
    move /y "!DVDDIR!\install_updated.wim" "!DVDDIR!\sources\install.wim" %_Nul1%
) else (
    echo WARNING: Failed to export install.wim. Original file kept.
)

if %BOOTCOUNT% gtr 0 if %INTEGRATE_WINPE_UPDATES% equ 1 (
    echo.
    echo ============================================================
    echo  Rebuilding boot.wim
    echo ============================================================
    if %_all% equ 1 !_dism2!:"!TMPDISM!" /Export-Image /SourceImageFile:"!DVDDIR!\sources\boot.wim" /All /DestinationImageFile:"!DVDDIR!\boot_updated.wim" /Compress:max
    if %_all% equ 0 for /L %%i in (1,1,%BOOTCOUNT%) do !_dism2!:"!TMPDISM!" /Export-Image /SourceImageFile:"!DVDDIR!\sources\boot.wim" /SourceIndex:%%i /DestinationImageFile:"!DVDDIR!\boot_updated.wim" /Compress:max /CheckIntegrity 
    if exist "!DVDDIR!\boot_updated.wim" (
        del /f /q "!DVDDIR!\sources\boot.wim" %_Nul3%
        move /y "!DVDDIR!\boot_updated.wim" "!DVDDIR!\sources\boot.wim" %_Nul1%
    ) else (
        echo WARNING: Failed to export boot.wim. Original file kept. 
    )
)

if %NET35%==1 if exist "!DVDDIR!\sources\sxs\*netfx3*.cab" (
    echo NOTE: Removing original netfx3 cab from sources\sxs as it should now be integrated.
    del /f /q "!DVDDIR!\sources\sxs\*netfx3*.cab" %_Nul3%
)

if %ISO%==0 (
    set MESSAGE=Finished processing WIMs. ISO was not requested. Source files are in !DVDDIR!
    goto :remove
)

:: Prepare for ISO creation
call :DATEISO
set "WinVerPrefix=Win_10"(
    if %_build% GEQ 22000 set "WinVerPrefix=Win_11"
)

:: Determine Architecture for Label
set archl=UNK
for /f "tokens=2 delims=: " %%# in ('dism\dism.exe /english /get-wiminfo /wimfile:"!DVDDIR!\sources\install.wim" /index:1 ^| find /i "Architecture"') do set archl=%%# 
if /i %archl%==x64 set archl=X64
if /i %archl%==x86 set archl=X86
if /i %archl%==arm64 set archl=ARM64

set DVDLABEL=%isover%_%archl%_CLIENT
set DVDISO=%WinVerPrefix%_%DVDLABEL%_Updated.iso

echo.
echo ============================================================ 
echo  Creating ISO file: %DVDISO% 
echo ============================================================ 
pushd "!DVDDIR!"
if not exist "!WORKDIR!\dism\cdimage.exe" (
    popd
    set MESSAGE=ERROR: cdimage.exe not found in dism folder. Cannot create ISO. Files are in !DVDDIR!
    goto :remove_no_iso
)

set /a rnd=%random%
if exist "!WORKDIR!\%DVDISO%" ren "!WORKDIR!\%DVDISO%" "%rnd%_%DVDISO%"

if exist "efi\microsoft\boot\efisys.bin" (
    "!WORKDIR!\dism\cdimage.exe" -bootdata:2#p0,e,b".\boot\etfsboot.com"#pEF,e,b".\efi\microsoft\boot\efisys.bin" -o -m -u2 -udfver102 -l"%DVDLABEL%" . "%DVDISO%"
    call set errcode=!errorlevel!
) else (
    "!WORKDIR!\dism\cdimage.exe" -b".\boot\etfsboot.com" -o -m -u2 -udfver102 -l"%DVDLABEL%" . "%DVDISO%"
    call set errcode=!errorlevel!
)
if not exist "%DVDISO%" set errcode=1
if %errcode% equ 0 (
    move /y "%DVDISO%" "!WORKDIR!\" %_Nul3% 
    popd
    set MESSAGE=Completed successfully. ISO created: %DVDISO%
    goto :remove
) else (
    popd
    del /f /q "!DVDDIR!\%DVDISO%" %_Nul3%
    set MESSAGE=ERROR: Could not create ISO file. Source files are in !DVDDIR!
    goto :remove_no_iso 
)

:DATEISO
:: Attempt to get a more precise date based on updated components if available
if %_pwsh% equ 0 goto :eof
set _svr1=0 & set _svr2=0
set "_fvr1=%SystemRoot%\temp\UpdateAgent.dll"
set "_fvr2=%SystemRoot%\temp\Facilitator.dll"
if exist "%INSTALLMOUNTDIR%\Windows\system32\UpdateAgent.dll" copy /y "%INSTALLMOUNTDIR%\Windows\system32\UpdateAgent.dll" %SystemRoot%\temp\ %_Nul3%
if exist "%INSTALLMOUNTDIR%\Windows\system32\Facilitator.dll" copy /y "%INSTALLMOUNTDIR%\Windows\system32\Facilitator.dll" %SystemRoot%\temp\ %_Nul3%
set "cfvr1=!_fvr1:\=\\!"
set "cfvr2=!_fvr2:\=\\!" 
if %_cwmi% equ 1 (
    if exist "!_fvr1!" for /f "tokens=5 delims==." %%a in ('wmic datafile where "name='!cfvr1!'" get Version /value ^| find "="') do set /a "_svr1=%%a"
    if exist "!_fvr2!" for /f "tokens=5 delims==." %%a in ('wmic datafile where "name='!cfvr2!'" get Version /value ^| find "="') do set /a "_svr2=%%a"
) else (
    if exist "!_fvr1!" for /f "tokens=4 delims=." %%a in ('%_psc% "([WMI]'CIM_DataFile.Name=''!cfvr1!''').Version"') do set /a "_svr1=%%a"
    if exist "!_fvr2!" for /f "tokens=4 delims=." %%a in ('%_psc% "([WMI]'CIM_DataFile.Name=''!cfvr2!''').Version"') do set /a "_svr2=%%a"
)
if %isomin% neq %_svr1% if %isomin% neq %_svr2% goto :cleanup_dateiso 
if %isomin% equ %_svr1% set "_chk=!_fvr1!"
if %isomin% equ %_svr2% set "_chk=!_fvr2!"
if exist "!_chk!" for /f "tokens=6 delims=.) " %%# in ('%_psc% "(gi '!_chk!').VersionInfo.FileVersion" %_Nul6%') do set "_ddd=%%#" 
if defined _ddd if /i not "%_ddd%"=="winpbld" set "isodate=%_ddd%"
:cleanup_dateiso
del /f /q "!_fvr1!" "!_fvr2!" %_Nul3% 
goto :eof

:remove
echo.
echo ============================================================
echo  Removing temporary directories
echo ============================================================
echo.
if exist "!DVDDIR!\" rmdir /s /q "!DVDDIR!\" %_Nul3% 
:remove_no_iso
if exist "!TEMPDIR!\" rmdir /s /q "!TEMPDIR!\" %_Nul3%
if exist "!MOUNTDIR!\" rmdir /s /q "!MOUNTDIR!\" %_Nul3%
if exist "Updates\msucab.txt" (
  for /f %%# in (Updates\msucab.txt) do (
      if exist "Updates\*%%~#*x86*.msu" if exist "Updates\*%%~#*x86*.cab" del /f /q "Updates\*%%~#*x86*.cab" %_Nul3%
      if exist "Updates\*%%~#*x64*.msu" if exist "Updates\*%%~#*x64*.cab" del /f /q "Updates\*%%~#*x64*.cab" %_Nul3%
      if exist "Updates\*%%~#*arm64*.msu" if exist "Updates\*%%~#*arm64*.cab" del /f /q "Updates\*%%~#*arm64*.cab" %_Nul3%
  )
  del /f /q Updates\msucab.txt %_Nul3%
)
goto :END

:cleanmanual
:: Simplified cleanup focusing on common DISM leftovers
if exist "%~1\Windows\WinSxS\ManifestCache\*.bin" del /f /q "%~1\Windows\WinSxS\ManifestCache\*.bin" %_Nul3% 
if exist "%~1\Windows\WinSxS\Temp\PendingDeletes\*" del /f /q /s "%~1\Windows\WinSxS\Temp\PendingDeletes\*" %_Nul3%
if exist "%~1\Windows\WinSxS\Temp\PendingRenames\*" del /f /q /s "%~1\Windows\WinSxS\Temp\PendingRenames\*" %_Nul3%
if exist "%~1\Windows\inf\*.log" del /f /q "%~1\Windows\inf\*.log" %_Nul3%
if exist "%~1\Windows\Logs\CBS\*.log" del /f /q "%~1\Windows\Logs\CBS\*.log" %_Nul3%
if exist "%~1\Windows\Logs\DISM\*.log" del /f /q "%~1\Windows\Logs\DISM\*.log" %_Nul3%
if exist "%~1\Windows\Temp" for /f "tokens=*" %%# in ('dir /b /ad "%~1\Windows\Temp\" %_Nul6%') do rmdir /s /q "%~1\Windows\Temp\%%#\" %_Nul3%
if exist "%~1\Windows\Temp" del /s /f /q "%~1\Windows\Temp\*" %_Nul3%
goto :eof

:: ###################################################################
:: # Error Handling                                                # 
:: ###################################################################

:E_BIN
call :remove
set MESSAGE=ERROR: Could not find required binaries (dism.exe or 7z.exe in .\dism)
goto :END

:E_UPDATER_SCRIPT
call :remove
set MESSAGE=ERROR: Could not find the update script .\Updates\W10UI.cmd
goto :END

:E_DVD
call :remove
set MESSAGE=ERROR: Could not find the specified distribution path: !DVDPATH!
goto :END 

:E_WIM
call :remove
set MESSAGE=ERROR: Could not find install.wim file in \sources folder of !DVDPATH!
goto :END 

:E_ESD
call :remove
set MESSAGE=ERROR: Detected install.wim file is actually .esd file (not supported by this script)
goto :END

:E_MKDIR
set MESSAGE=ERROR: Could not create temporary directory. Check permissions or disk space. 
goto :END

:E_MOUNT
set MESSAGE=ERROR: Could not mount WIM image. Check logs in %_dLog%. Corrupted WIM or insufficient permissions? 
set errMOUNT=1
goto :END_NOWAIT

:E_UNMOUNT
set MESSAGE=ERROR: Could not unmount WIM image. Check logs in %_dLog%. Manual cleanup might be needed in %MOUNTDIR%. 
set errMOUNT=1
goto :END

:E_ADMIN
set MESSAGE=ERROR: Run the script as administrator
goto :END_NOWAIT

:E_PWS
set MESSAGE=ERROR: wmic.exe or Windows PowerShell is required for this script to work
goto :END_NOWAIT

:END
echo.
echo ============================================================ 
echo  %MESSAGE% 
echo ============================================================ 
echo.
:END_NOWAIT
if %_Debug% neq 0 goto :eof
echo.
echo  Press 0 to exit. 
choice /c 0 /n
if errorlevel 1 (goto :eof) else (rem.)
