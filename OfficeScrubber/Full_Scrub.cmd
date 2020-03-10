@setlocal DisableDelayedExpansion
@echo off
set "SysPath=%SystemRoot%\System32"
if exist "%SystemRoot%\Sysnative\reg.exe" (set "SysPath=%SystemRoot%\Sysnative")
set "Path=%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
set "xOS=x64"
set "_Common=%CommonProgramFiles%"
if /i %PROCESSOR_ARCHITECTURE%==x86 (if defined PROCESSOR_ARCHITEW6432 (
  set "_Common=%CommonProgramW6432%"
  ) else (
  set "xOS=x86"
  )
)
set "_target=%_Common%\Microsoft Shared\ClickToRun"
set "_file=%_target%\OfficeClickToRun.exe"
set "_work=%~dp0bin"
reg query HKU\S-1-5-19 >nul 2>&1 || (
set "msg=ERROR: right click on the script and 'Run as administrator'"
goto :end
)
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G
if %winbuild% LSS 7601 (
set "msg=ERROR: Windows 7 SP1 is the minimum supported OS"
goto :end
)
setlocal EnableDelayedExpansion
if not exist "!_work!\!xOS!\cleanospp.exe" (
set "msg=ERROR: required file cleanospp.exe is missing"
goto :end
)
for %%a in (OffScrub_O16msi.vbs,OffScrubC2R.vbs) do (
if not exist "!_work!\%%a" (set "msg=ERROR: required file %%a is missing"&goto :end)
)
set "_Nul1=1>nul"
set "_Nul2=2>nul"
set "_Nul6=2^>nul"
set "_Nul3=1>nul 2>nul"

title Office Scrubber
set OfficeC2R=0
sc query ClickToRunSvc %_Nul3% && set OfficeC2R=1
sc query OfficeSvc %_Nul3% && set OfficeC2R=1
reg query HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Configuration /v ProductReleaseIds %_Nul3% && (
set OfficeC2R=1
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Configuration /v Platform" %_Nul6%') do set "plat=%%b"
)
reg query HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration /v ProductReleaseIds %_Nul3% && set OfficeC2R=1
if exist "!_file!" set OfficeC2R=1
set OfficeMSI=0
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\16.0\Common\InstallRoot /v Path" %_Nul6%') do if exist "%%b\OSPP.VBS" set OfficeMSI=1
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Wow6432Node\Microsoft\Office\16.0\Common\InstallRoot /v Path" %_Nul6%') do if exist "%%b\OSPP.VBS" set OfficeMSI=1
if %OfficeC2R% equ 1 if not defined plat (
if exist "%ProgramFiles(x86)%\Microsoft Office\Office16\OSPP.VBS" (set "plat=x86") else (set "plat=%xOS%")
)

if %OfficeC2R% equ 0 if %OfficeMSI% equ 0 (
echo.
echo ============================================================
echo No installed Office ClickToRun or Office 2016 MSI detected
echo.
echo.
choice /C YN /N /M "Continue with scrubbing Office anyway? [y/n]: "
if errorlevel 2 goto :eof
if errorlevel 1 goto :main
)
echo.
echo ============================================================
if %OfficeC2R% equ 1 echo Detected Office C2R
if %OfficeMSI% equ 1 echo Detected Office 2016 MSI
echo.
echo.
choice /C YN /N /M "Continue with scrubbing detected Office? [y/n]: "
if errorlevel 2 goto :eof
if errorlevel 1 goto :main

:main
cls
if %OfficeC2R% equ 0 if %OfficeMSI% equ 0 goto :proceed
echo.
echo ============================================================
echo Uninstalling Product Key^(s)
echo ============================================================
call :cKMS

:proceed
if exist "!_file!" (
echo.
echo ============================================================
echo Executing OfficeClickToRun.exe
echo ============================================================
%_Nul3% start "" /WAIT "!_file!" platform=%plat% productstoremove=AllProducts displaylevel=False
)
echo.
echo ============================================================
echo Executing OffScrubC2R.vbs
echo ============================================================
%_Nul3% cscript //Nologo //B "!_work!\OffScrubC2R.vbs" ALL /OSE /QUIET /NOCANCEL
echo.
echo ============================================================
echo Executing OffScrub_O16msi.vbs
echo ============================================================
%_Nul3% cscript //Nologo //B "!_work!\OffScrub_O16msi.vbs" ALL /OSE /QUIET /NOCANCEL /NOREBOOT /FORCE /DELETEUSERSETTINGS /ECI

reg delete HKCU\Software\Microsoft\Office /f %_Nul3%
reg delete HKLM\SOFTWARE\Microsoft\Office /f %_Nul3%
reg delete HKLM\SOFTWARE\Wow6432Node\Microsoft\Office /f %_Nul3%
for /f %%a in ('"dir /b %SystemRoot%\temp\ose*.exe" %_Nul6%') do taskkill /t /f /IM %%a %_Nul3%
del /f /q "%SystemRoot%\temp\*" %_Nul3%
del /f /q "%SystemRoot%\temp\*.log" %_Nul3%
del /f /q "%temp%\*.log" %_Nul3%

if exist "%SysPath%\spp\store_test\2.0\tokens.dat" (
echo.
echo ============================================================
echo Refreshing Windows Insider Preview Licenses...
echo ============================================================
echo.
cscript //Nologo //B %SysPath%\slmgr.vbs /rilc
)
set "msg=Finished. Recommended to reboot the system."
goto :end

:cKMS
set "OSPP=SOFTWARE\Microsoft\OfficeSoftwareProtectionPlatform"
set "SPPk=SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform"
if %winbuild% geq 9200 (
set spp=SoftwareLicensingProduct
) else (
set spp=OfficeSoftwareProtectionProduct
)
for /f "tokens=2 delims==" %%G in ('"wmic path %spp% where (Name LIKE 'Office%%' AND PartialProductKey is not NULL) get ID /VALUE" %_Nul6%') do (set app=%%G&call :Clear)
if /i %spp% EQU SoftwareLicensingProduct (
reg delete "HKLM\%SPPk%\0ff1ce15-a989-479d-af46-f275c6370663" /f %_Nul3%
reg delete "HKEY_USERS\S-1-5-20\%SPPk%\0ff1ce15-a989-479d-af46-f275c6370663" /f %_Nul3%
) else (
reg delete "HKLM\%OSPP%\0ff1ce15-a989-479d-af46-f275c6370663" /f %_Nul3%
reg delete "HKEY_USERS\S-1-5-20\%OSPP%" /f %_Nul3%
)
goto :eof

:Clear
wmic path %spp% where ID='%app%' call ClearKeyManagementServiceMachine %_Nul3%
wmic path %spp% where ID='%app%' call ClearKeyManagementServicePort %_Nul3%
wmic path %spp% where ID='%app%' call UninstallProductKey %_Nul3%
goto :eof

:end
echo.
echo ============================================================
echo %msg%
echo ============================================================
echo.
echo Press any key to exit.
pause >nul
goto :eof