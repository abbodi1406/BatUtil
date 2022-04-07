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
start %SystemRoot%\Sysnative\cmd.exe /c ""!_cmdf!" -wow"
exit /b
)
if exist "%SystemRoot%\SysArm32\cmd.exe" if /i %PROCESSOR_ARCHITECTURE%==AMD64 if not defined _rel2 (
setlocal EnableDelayedExpansion
start %SystemRoot%\SysArm32\cmd.exe /c ""!_cmdf!" -arm"
exit /b
)
set "SysPath=%SystemRoot%\System32"
if exist "%SystemRoot%\Sysnative\reg.exe" (set "SysPath=%SystemRoot%\Sysnative")
set "Path=%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
reg query HKU\S-1-5-19 >nul 2>&1 || (
set "msg=ERROR: right click on the script and 'Run as administrator'"
goto :end
)
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G
if %winbuild% LSS 7601 (
set "msg=ERROR: Windows 7 SP1 is the minimum supported OS"
goto :end
)
set "_Common=%CommonProgramFiles%"
if defined PROCESSOR_ARCHITEW6432 set "_Common=%CommonProgramW6432%"
if /i "%PROCESSOR_ARCHITECTURE%"=="amd64" set "xBit=x64"
if /i "%PROCESSOR_ARCHITECTURE%"=="arm64" set "xBit=x86"
if /i "%PROCESSOR_ARCHITECTURE%"=="x86" if "%PROCESSOR_ARCHITEW6432%"=="" set "xBit=x86"
if /i "%PROCESSOR_ARCHITEW6432%"=="amd64" set "xBit=x64"
if /i "%PROCESSOR_ARCHITEW6432%"=="arm64" set "xBit=x86"
set "_file=%_Common%\Microsoft Shared\ClickToRun\OfficeClickToRun.exe"
set "_fil2=%CommonProgramFiles(x86)%\Microsoft Shared\ClickToRun\OfficeClickToRun.exe"
set "_work=%~dp0bin"
setlocal EnableDelayedExpansion
pushd "!_work!"
if not exist "%xBit%\cleanospp.exe" (
set "msg=ERROR: required file cleanospp.exe is missing"
goto :end
)
set "_Nul1=1>nul"
set "_Nul2=2>nul"
set "_Nul6=2^>nul"
set "_Nul3=1>nul 2>nul"

title Reset Office C2R Licenses
set OfficeC2R=0
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\ClickToRun /v InstallPath" %_Nul6%') do if exist "%%b\root\Licenses16\ProPlus*.xrm-ms" set OfficeC2R=1
if %OfficeC2R% equ 0 for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun /v InstallPath" %_Nul6%') do if exist "%%b\root\Licenses16\ProPlus*.xrm-ms" set OfficeC2R=1
if exist "!_file!" set OfficeC2R=1
if exist "!_fil2!" if /i "%PROCESSOR_ARCHITECTURE%"=="arm64" set OfficeC2R=1
if %OfficeC2R% equ 0 (
set "msg=No installed Office ClickToRun detected"
goto :end
)

:main
set "_InstallRoot="
set "_ProductIds="
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\ClickToRun /v InstallPath" %_Nul6%') do (set "_InstallRoot=%%b\root")
if not "%_InstallRoot%"=="" (
  for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\ClickToRun /v PackageGUID" %_Nul6%') do (set "_GUID=%%b")
  for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Configuration /v ProductReleaseIds" %_Nul6%') do (set "_ProductIds=%%b")
  set "_Config=HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
  set "_PRIDs=HKLM\SOFTWARE\Microsoft\Office\ClickToRun\ProductReleaseIDs"
) else (
  for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun /v InstallPath" %_Nul6%') do (set "_InstallRoot=%%b\root")
  for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun /v PackageGUID" %_Nul6%') do (set "_GUID=%%b")
  for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration /v ProductReleaseIds" %_Nul6%') do (set "_ProductIds=%%b")
  set "_Config=HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration"
  set "_PRIDs=HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\ProductReleaseIDs"
)
set "_Integrator=%_InstallRoot%\integration\integrator.exe"
for /f "skip=2 tokens=2*" %%a in ('"reg query %_PRIDs% /v ActiveConfiguration" %_Nul6%') do set "_PRIDs=%_PRIDs%\%%b"
if not exist "%_Integrator%" (
set "msg=ERROR: Could not detect Office Licenses Integrator.exe"
goto :end
)
for /f "tokens=8 delims=\" %%a in ('reg query "%_PRIDs%" /f ".16" /k %_Nul6% ^| find /i "ClickToRun"') do (
if not defined _SKUs (set "_SKUs=%%a") else (set "_SKUs=!_SKUs!,%%a")
)
if not defined _SKUs (
set "msg=ERROR: Could not detect originally installed Office Products"
goto :end
)
cls
echo.
echo ============================================================
echo Cleaning Office Licenses...
echo ============================================================
echo.
%xBit%\cleanospp.exe -Licenses %_Nul3%
if exist "%SysPath%\spp\store_test\2.0\tokens.dat" (
echo.
echo ============================================================
echo Refreshing Windows Insider Preview Licenses...
echo ============================================================
echo.
cscript //Nologo //B %SysPath%\slmgr.vbs /rilc
if !ERRORLEVEL! NEQ 0 cscript //Nologo //B %SysPath%\slmgr.vbs /rilc
)
echo.
echo ============================================================
echo Installing Office C2R Licenses...
echo ============================================================
echo.
for %%a in (%_SKUs%) do (
"!_Integrator!" /R /License PRIDName=%%a.16 PackageGUID="%_GUID%" PackageRoot="!_InstallRoot!" %_Nul1%
)
set "msg=Finished."
goto :end

:end
echo.
echo ============================================================
echo %msg%
echo ============================================================
echo.
echo Press any key to exit.
pause >nul
goto :eof