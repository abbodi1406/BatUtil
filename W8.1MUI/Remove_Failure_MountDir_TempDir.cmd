@setlocal DisableDelayedExpansion
@echo off
set _args=
set _args=%*
if not defined _args goto :NoProgArgs
for %%A in (%_args%) do (
if /i "%%A"=="-wow" set _rel1=1
if /i "%%A"=="-arm" set _rel2=1
)
:NoProgArgs
set "_cmdf=%~f0"
if exist "%SystemRoot%\Sysnative\cmd.exe" if not defined _rel1 (
setlocal EnableDelayedExpansion
start %SystemRoot%\Sysnative\cmd.exe /c ""!_cmdf!" -wow "
exit /b
)
if exist "%SystemRoot%\SysArm32\cmd.exe" if /i %PROCESSOR_ARCHITECTURE%==AMD64 if not defined _rel2 (
setlocal EnableDelayedExpansion
start %SystemRoot%\SysArm32\cmd.exe /c ""!_cmdf!" -arm "
exit /b
)
set "_Null=1>nul 2>nul"
set "SysPath=%SystemRoot%\System32"
if exist "%SystemRoot%\Sysnative\reg.exe" (set "SysPath=%SystemRoot%\Sysnative")
set "Path=%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
whoami /groups | findstr /i /c:"S-1-16-16384" /c:"S-1-16-12288" %_Null% || (echo.&echo This script require administrator privileges.&goto :TheEnd)
set _drv=%~d0
set "xOS=%PROCESSOR_ARCHITECTURE%"
if /i %PROCESSOR_ARCHITECTURE%==x86 (if defined PROCESSOR_ARCHITEW6432 set "xOS=%PROCESSOR_ARCHITEW6432%")
set _m=0
set _t=0
set "_key=HKLM\SOFTWARE\Microsoft\WIMMount\Mounted Images"
set regKeyPathFound=1
set wowRegKeyPathFound=1
reg.exe query "HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 %_Null% || set wowRegKeyPathFound=0
reg.exe query "HKLM\Software\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 %_Null% || set regKeyPathFound=0
if %wowRegKeyPathFound% equ 0 (
  if %regKeyPathFound% equ 0 (
    goto :precheck
  ) else (
    set regKeyPath=HKLM\Software\Microsoft\Windows Kits\Installed Roots
  )
) else (
    set regKeyPath=HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots
)
for /f "skip=2 tokens=2*" %%i in ('reg.exe query "%regKeyPath%" /v KitsRoot10') do set "KitsRoot=%%j"
set "DandIRoot=%KitsRoot%Assessment and Deployment Kit\Deployment Tools"
if exist "%DandIRoot%\%xOS%\DISM\dism.exe" (
set "Path=%DandIRoot%\%xOS%\DISM;%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
cd \
)

:precheck
set _er=0
echo.
echo.
choice /C YN /N /M "Detect and cleanup any mounted directories? [y/n]: "
set _er=%ERRORLEVEL%
if %_er% EQU 2 goto :check2
if %_er% EQU 1 set _m=1&goto :check2
goto :precheck

:check2
set _er=0
echo.
echo.
choice /C YN /N /M "Detect and remove any W10/W81/W7-UI/MUI temporary directories? [y/n]: "
set _er=%ERRORLEVEL%
if %_er% EQU 2 (if %_m% EQU 1 (goto :ALL) else (goto :eof))
if %_er% EQU 1 set _t=1&goto :ALL
goto :check2

:ALL
@cls
if %_m% EQU 0 goto :TEMP
for /f "tokens=3*" %%a in ('reg.exe query "%_key%" /s /v "Mount Path" 2^>nul ^| findstr /i /c:"Mount Path"') do (set "_mount=%%b"&call :CLN)
dism.exe /English /Cleanup-Wim
dism.exe /English /Cleanup-Mountpoints
if %_t% EQU 1 goto :TEMP
goto :TheEnd

:TEMP
echo.
echo Removing W10/W81/W7-UI/MUI directories
for %%# in (C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do (
if exist "%%#:\W10UIuup\" (set "_mount=%%#:\W10UIuup"&call :TMP)
if exist "%%#:\W10MUITEMP\" (set "_mount=%%#:\W10MUITEMP"&call :TMP)
if exist "%%#:\W81MUITEMP\" (set "_mount=%%#:\W81MUITEMP"&call :TMP)
if exist "%%#:\W7MUITEMP\" (set "_mount=%%#:\W7MUITEMP"&call :TMP)
if exist "%%#:\W10UItemp\" (set "_mount=%%#:\W10UItemp"&call :TMP)
if exist "%%#:\W81UItemp\" (set "_mount=%%#:\W81UItemp"&call :TMP)
if exist "%%#:\W7UItemp\" (set "_mount=%%#:\W7UItemp"&call :TMP)
for /f %%A in ('dir /b /ad "%%#:\W10UItemp_*" 2^>nul') do (set "_mount=%%#:\%%A"&call :TMP)
for /f %%A in ('dir /b /ad "%%#:\W81UItemp_*" 2^>nul') do (set "_mount=%%#:\%%A"&call :TMP)
for /f %%A in ('dir /b /ad "%%#:\W7UItemp_*" 2^>nul') do (set "_mount=%%#:\%%A"&call :TMP)
)
goto :TheEnd

:CLN
dism.exe /English /Image:"%_mount%" /Get-Packages %_Null%
dism.exe /English /Unmount-Wim /MountDir:"%_mount%" /Discard
:TMP
if exist "%_mount%\" rmdir /s /q "%_mount%\" %_Null%
if exist "%_mount%" (
mkdir %_drv%\_del286 %_Null%
robocopy %_drv%\_del286 "%_mount%" /MIR /R:1 /W:1 /NFL /NDL /NP /NJH /NJS %_Null%
rmdir /s /q %_drv%\_del286\ %_Null%
rmdir /s /q "%_mount%" %_Null%
)
exit /b

:TheEnd
echo.
echo Press any key to exit.
pause >nul
goto :eof
