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
reg.exe query HKU\S-1-5-19 %_Null% || (echo.&echo This script require administrator privileges.&goto :TheEnd)
set _drv=%~d0
set "xOS=%PROCESSOR_ARCHITECTURE%"
if /i %PROCESSOR_ARCHITECTURE%==x86 (if defined PROCESSOR_ARCHITEW6432 set "xOS=%PROCESSOR_ARCHITEW6432%")
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
echo.
echo.
choice /C YN /N /M "Detect and cleanup any mounted directories? [y/n]: "
if errorlevel 2 goto :eof
if errorlevel 1 goto :ALL

:ALL
@cls
for /f "tokens=3*" %%a in ('reg.exe query "%_key%" /s /v "Mount Path" 2^>nul ^| findstr /i /c:"Mount Path"') do (set "_mount=%%b"&call :CLN)
dism.exe /English /Cleanup-Wim
dism.exe /English /Cleanup-Mountpoints
goto :TheEnd

:CLN
dism.exe /English /Image:"%_mount%" /Get-Packages %_Null%
dism.exe /English /Unmount-Wim /MountDir:"%_mount%" /Discard
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
