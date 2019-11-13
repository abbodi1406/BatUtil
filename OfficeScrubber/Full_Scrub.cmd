@echo off
set "SysPath=%Windir%\System32"
if exist "%Windir%\Sysnative\reg.exe" (set "SysPath=%Windir%\Sysnative")
set "Path=%SysPath%;%Windir%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
reg query HKU\S-1-5-19 >nul 2>&1 || (
set "msg=ERROR: right click on the script and 'Run as administrator'"
goto :end
)
if not exist "%~dp0bin\x86\cleanospp.exe" (
set "msg=ERROR: required file cleanospp.exe is missing"
goto :end
)
for %%a in (OffScrub_O16msi.vbs,OffScrubC2R.vbs) do (
if not exist "%~dp0bin\%%a" (set "msg=ERROR: required file %%a is missing"&goto :end)
)
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G
if %winbuild% LSS 7601 (
set "msg=ERROR: Windows 7 SP1 is the minimum supported OS"
goto :end
)
set xOS=x64
if /i "%PROCESSOR_ARCHITECTURE%"=="x86" (if not defined PROCESSOR_ARCHITEW6432 set xOS=x86)
set "_work=%~dp0"
if "%_work:~-1%"=="\" set "_work=%_work:~0,-1%"
setlocal EnableExtensions EnableDelayedExpansion
title Office Scrubber
set OfficeC2R=0
sc query ClickToRunSvc 1>nul 2>nul && set OfficeC2R=1
sc query OfficeSvc 1>nul 2>nul && set OfficeC2R=1
reg query HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Configuration /v ProductReleaseIds 1>nul 2>nul && (
set OfficeC2R=1
for /f "tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Configuration /v Platform" 2^>nul') do set "plat=%%b"
)
reg query HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration /v ProductReleaseIds 1>nul 2>nul && set OfficeC2R=1
if exist "%CommonProgramFiles%\Microsoft Shared\ClickToRun\OfficeClickToRun.exe" set OfficeC2R=1
if %OfficeC2R% equ 1 if not defined plat (
if exist "%ProgramFiles(x86)%\Microsoft Office\Office16\OSPP.VBS" (set "plat=x86") else (set "plat=%xOS%")
)
set OfficeMSI=0
for /f "tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\16.0\Common\InstallRoot /v Path" 2^>nul') do if exist "%%b\OSPP.VBS" set OfficeMSI=1
for /f "tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Wow6432Node\Microsoft\Office\16.0\Common\InstallRoot /v Path" 2^>nul') do if exist "%%b\OSPP.VBS" set OfficeMSI=1

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
if exist "%CommonProgramFiles%\Microsoft Shared\ClickToRun\OfficeClickToRun.exe" (
echo.
echo ============================================================
echo Executing OfficeClickToRun.exe
echo ============================================================
1>nul 2>nul start "" /WAIT "%CommonProgramFiles%\Microsoft Shared\ClickToRun\OfficeClickToRun.exe" platform=%plat% productstoremove=AllProducts displaylevel=False
)
echo.
echo ============================================================
echo Executing OffScrubC2R.vbs
echo ============================================================
1>nul 2>nul cscript //Nologo //B "!_work!\bin\OffScrubC2R.vbs" ALL /OSE /QUIET /NOCANCEL
echo.
echo ============================================================
echo Executing OffScrub_O16msi.vbs
echo ============================================================
1>nul 2>nul cscript //Nologo //B "!_work!\bin\OffScrub_O16msi.vbs" ALL /OSE /QUIET /NOCANCEL /NOREBOOT /FORCE /DELETEUSERSETTINGS /ECI

reg delete HKCU\Software\Microsoft\Office /f 1>nul 2>nul
reg delete HKLM\SOFTWARE\Microsoft\Office /f 1>nul 2>nul
reg delete HKLM\SOFTWARE\Wow6432Node\Microsoft\Office /f 1>nul 2>nul
for /f %%a in ('"dir /b %windir%\temp\ose*.exe" 2^>nul') do taskkill /t /f /IM %%a 1>nul 2>nul
del /f /q "%windir%\temp\*" 1>nul 2>nul
del /f /q "%windir%\temp\*.log" 1>nul 2>nul
del /f /q "%temp%\*.log" 1>nul 2>nul

if exist "%SystemRoot%\System32\spp\store_test\2.0\tokens.dat" (
echo.
echo ============================================================
echo Refreshing Windows Insider Preview Licenses...
echo ============================================================
echo.
cscript //Nologo //B %SystemRoot%\System32\slmgr.vbs /rilc
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
for /f "tokens=2 delims==" %%G in ('"wmic path %spp% where (Name LIKE 'Office%%' AND PartialProductKey is not NULL) get ID /VALUE" 2^>nul') do (set app=%%G&call :Clear)
if /i %spp% EQU SoftwareLicensingProduct (
reg delete "HKLM\%SPPk%\0ff1ce15-a989-479d-af46-f275c6370663" /f 1>nul 2>nul
reg delete "HKEY_USERS\S-1-5-20\%SPPk%\0ff1ce15-a989-479d-af46-f275c6370663" /f 1>nul 2>nul
) else (
reg delete "HKLM\%OSPP%\0ff1ce15-a989-479d-af46-f275c6370663" /f 1>nul 2>nul
reg delete "HKEY_USERS\S-1-5-20\%OSPP%" /f 1>nul 2>nul
)
goto :eof

:Clear
wmic path %spp% where ID='%app%' call ClearKeyManagementServiceMachine 1>nul 2>nul
wmic path %spp% where ID='%app%' call ClearKeyManagementServicePort 1>nul 2>nul
wmic path %spp% where ID='%app%' call UninstallProductKey 1>nul 2>nul
goto :eof

:end
echo.
echo ============================================================
echo %msg%
echo ============================================================
echo.
echo Press any key to exit...
pause >nul
goto :eof