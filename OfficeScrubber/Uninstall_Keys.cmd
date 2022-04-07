<!-- : Begin batch script
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
set _cwmi=0
for %%# in (wmic.exe) do @if not "%%~$PATH:#"=="" (
wmic path Win32_ComputerSystem get CreationClassName /value 2>nul | find /i "ComputerSystem" 1>nul && set _cwmi=1
)
set "_csq=cscript.exe //NoLogo //Job:WmiQuery "%~nx0?.wsf""
set "_csm=cscript.exe //NoLogo //Job:WmiMethod "%~nx0?.wsf""
set WMI_VBS=0
if %_cwmi% EQU 0 set WMI_VBS=1
set _WSH=1
reg query "HKCU\SOFTWARE\Microsoft\Windows Script Host\Settings" /v Enabled 2>nul | find /i "0x0" 1>nul && (set _WSH=0)
reg query "HKLM\SOFTWARE\Microsoft\Windows Script Host\Settings" /v Enabled 2>nul | find /i "0x0" 1>nul && (set _WSH=0)
set "_oApp=0ff1ce15-a989-479d-af46-f275c6370663"
set "_oA14=59a52881-a989-479d-af46-f275c6370663"
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

title Uninstall Office Keys
set OfficeC2R=0
sc query ClickToRunSvc %_Nul3% && set OfficeC2R=1
sc query OfficeSvc %_Nul3% && set OfficeC2R=1
reg query HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Configuration /v ProductReleaseIds %_Nul3% && (
set OfficeC2R=1
)
reg query HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration /v ProductReleaseIds %_Nul3% && (
set OfficeC2R=1
)
if exist "!_file!" set OfficeC2R=1
if exist "!_fil2!" if /i "%PROCESSOR_ARCHITECTURE%"=="arm64" set OfficeC2R=1
set OfficeMSI=0
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\16.0\Common\InstallRoot /v Path" %_Nul6%') do if exist "%%b\OSPP.VBS" set OfficeMSI=1
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Wow6432Node\Microsoft\Office\16.0\Common\InstallRoot /v Path" %_Nul6%') do if exist "%%b\OSPP.VBS" set OfficeMSI=1
set OfficeUWP=0
if %winbuild% GEQ 10240 reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msoxmled.exe" %_Nul3% && (
dir /b "%ProgramFiles%\WindowsApps\Microsoft.Office.Desktop*" %_Nul3% && set OfficeUWP=1
dir /b "%ProgramW6432%\WindowsApps\Microsoft.Office.Desktop*" %_Nul3% && set OfficeUWP=1
dir /b "%ProgramFiles(x86)%\WindowsApps\Microsoft.Office.Desktop*" %_Nul3% && set OfficeUWP=1
)

if %OfficeC2R% equ 0 if %OfficeMSI% equ 0 if %OfficeUWP% equ 0 (
echo.
echo ============================================================
echo No installed Office ClickToRun or Office 2016 MSI detected
echo.
echo.
choice /C YN /N /M "Continue with uninstalling Office keys anyway? [y/n]: "
if errorlevel 2 goto :eof
if errorlevel 1 goto :main
)
echo.
echo ============================================================
if %OfficeC2R% equ 1 echo Detected Office C2R
if %OfficeMSI% equ 1 echo Detected Office 2016 MSI
if %OfficeUWP% equ 1 echo Detected Office UWP Apps
echo.
echo.
choice /C YN /N /M "Continue with uninstalling detected Office keys? [y/n]: "
if errorlevel 2 goto :eof
if errorlevel 1 goto :main

:main
cls
echo.
echo ============================================================
echo Uninstalling Product Key^(s)
echo ============================================================
echo.
%xBit%\cleanospp.exe -PKey %_Nul3%
call :cKMS %_Nul3%
if %WMI_VBS% NEQ 0 cd bin
if exist "%SysPath%\spp\store_test\2.0\tokens.dat" (
echo.
echo ============================================================
echo Refreshing Windows Insider Preview Licenses...
echo ============================================================
echo.
cscript //Nologo //B %SysPath%\slmgr.vbs /rilc
if !ERRORLEVEL! NEQ 0 cscript //Nologo //B %SysPath%\slmgr.vbs /rilc
)
set "msg=Finished."
goto :end

:cKMS
set "OPPk=SOFTWARE\Microsoft\OfficeSoftwareProtectionPlatform"
set "SPPk=SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform"
if %winbuild% geq 9200 (
set spp=SoftwareLicensingProduct
reg delete "HKLM\%SPPk%\0ff1ce15-a989-479d-af46-f275c6370663" /f
reg delete "HKEY_USERS\S-1-5-20\%SPPk%\0ff1ce15-a989-479d-af46-f275c6370663" /f
) else (
set spp=OfficeSoftwareProtectionProduct
reg delete "HKLM\%OPPk%\0ff1ce15-a989-479d-af46-f275c6370663" /f
reg delete "HKEY_USERS\S-1-5-20\%OPPk%" /f
)
if %_WSH% EQU 0 if %WMI_VBS% NEQ 0 goto :eof
if %WMI_VBS% NEQ 0 cd ..
set "_ocq=Name LIKE 'Office%%' AND PartialProductKey is not NULL"
set "_qr="wmic path %spp% where (%_ocq%) get ID /VALUE""
if %WMI_VBS% NEQ 0 set "_qr=%_csq% %spp% "%_ocq%" ID"
for /f "tokens=2 delims==" %%G in ('%_qr% %_Nul6%') do (set app=%%G&call :cAPP %_Nul3%)
goto :eof

:cAPP
if %winbuild% geq 9200 (
reg delete "HKLM\%SPPk%\%_oApp%\%app%" /f %_Null%
) else (
reg delete "HKLM\%OPPk%\%_oA14%\%app%" /f %_Null%
reg delete "HKLM\%OPPk%\%_oApp%\%app%" /f %_Null%
)
set "_qr=wmic path %spp% where ID='%app%' call UninstallProductKey"
if %WMI_VBS% NEQ 0 set "_qr=%_csm% "%spp%.ID='%app%'" UninstallProductKey"
%_qr%
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

----- Begin wsf script --->
<package>
   <job id="WmiQuery">
      <script language="VBScript">
         If WScript.Arguments.Count = 3 Then
            wExc = "Select " & WScript.Arguments.Item(2) & " from " & WScript.Arguments.Item(0) & " where " & WScript.Arguments.Item(1)
            wGet = WScript.Arguments.Item(2)
         Else
            wExc = "Select " & WScript.Arguments.Item(1) & " from " & WScript.Arguments.Item(0)
            wGet = WScript.Arguments.Item(1)
         End If
         Set objCol = GetObject("winmgmts:\\.\root\CIMV2").ExecQuery(wExc,,48)
         For Each objItm in objCol
            For each Prop in objItm.Properties_
               If LCase(Prop.Name) = LCase(wGet) Then
                  WScript.Echo Prop.Name & "=" & Prop.Value
                  Exit For
               End If
            Next
         Next
      </script>
   </job>
   <job id="WmiMethod">
      <script language="VBScript">
         On Error Resume Next
         wPath = WScript.Arguments.Item(0)
         wMethod = WScript.Arguments.Item(1)
         Set objCol = GetObject("winmgmts:\\.\root\CIMV2:" & wPath)
         objCol.ExecMethod_(wMethod)
         WScript.Quit Err.Number
      </script>
   </job>
</package>