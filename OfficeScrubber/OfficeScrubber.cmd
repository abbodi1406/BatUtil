<!-- : Begin batch script
@setlocal DisableDelayedExpansion
@echo off
set _elev=
set _args=
set _args=%*
if not defined _args goto :NoProgArgs
for %%A in (%_args%) do (
if /i "%%A"=="-elevated" set _elev=1
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
set "Path=%SystemRoot%\System32;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
if exist "%SystemRoot%\Sysnative\reg.exe" (
set "SysPath=%SystemRoot%\Sysnative"
set "Path=%SystemRoot%\Sysnative;%SystemRoot%\Sysnative\Wbem;%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\;%Path%"
)
set "_psc=powershell -nop -c"

1>nul 2>nul reg query HKU\S-1-5-19 && (
  goto :Passed
  ) || (
  if defined _elev goto :E_Admin
)

set _PSarg="""%~f0""" %_args% -elevated
set _PSarg=%_PSarg:'=''%

(1>nul 2>nul cscript //NoLogo "%~f0?.wsf" //job:ELAV /File:"%~f0" %_args% -elevated) && (
  exit /b
  ) || (
  call setlocal EnableDelayedExpansion
  1>nul 2>nul %SysPath%\WindowsPowerShell\v1.0\%_psc% "start cmd.exe -arg '/c \"!_PSarg!\"' -verb runas" && (
    exit /b
    ) || (
    goto :E_Admin
  )
)

:Passed
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G
if %winbuild% LSS 7601 (
set "msg=ERROR: Windows 7 SP1 is the minimum supported OS"
goto :TheEnd
)
set _cwmi=0
for %%# in (wmic.exe) do @if not "%%~$PATH:#"=="" (
wmic path Win32_ComputerSystem get CreationClassName /value 2>nul | find /i "ComputerSystem" 1>nul && set _cwmi=1
)
set _pwsh=1
for %%# in (powershell.exe) do @if "%%~$PATH:#"=="" set _pwsh=0
set "_csq=cscript.exe //NoLogo //Job:WmiQuery "%~nx0?.wsf""
set "_csm=cscript.exe //NoLogo //Job:WmiMethod "%~nx0?.wsf""
set WMI_VBS=0
if %_cwmi% EQU 0 set WMI_VBS=1
set _WSH=1
reg query "HKCU\SOFTWARE\Microsoft\Windows Script Host\Settings" /v Enabled 2>nul | find /i "0x0" 1>nul && (set _WSH=0)
reg query "HKLM\SOFTWARE\Microsoft\Windows Script Host\Settings" /v Enabled 2>nul | find /i "0x0" 1>nul && (set _WSH=0)
set "_oApp=0ff1ce15-a989-479d-af46-f275c6370663"
set "_oA14=59a52881-a989-479d-af46-f275c6370663"
set "OPPk=SOFTWARE\Microsoft\OfficeSoftwareProtectionPlatform"
set "SPPk=SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform"
set "_para=ALL /QUIET /OSE /NOCANCEL /FORCE /ENDCURRENTINSTALLS /DELETEUSERSETTINGS /CLEARADDINREG /REMOVELYNC"
if /i "%PROCESSOR_ARCHITECTURE%"=="amd64" set "xBit=x64"&set "xOS=x64"
if /i "%PROCESSOR_ARCHITECTURE%"=="arm64" set "xBit=x86"&set "xOS=A64"
if /i "%PROCESSOR_ARCHITECTURE%"=="x86" if "%PROCESSOR_ARCHITEW6432%"=="" set "xBit=x86"&set "xOS=x86"
if /i "%PROCESSOR_ARCHITEW6432%"=="amd64" set "xBit=x64"&set "xOS=x64"
if /i "%PROCESSOR_ARCHITEW6432%"=="arm64" set "xBit=x86"&set "xOS=A64"
set "_Common=%CommonProgramFiles%"
if defined PROCESSOR_ARCHITEW6432 set "_Common=%CommonProgramW6432%"
set "_file=%_Common%\Microsoft Shared\ClickToRun\OfficeClickToRun.exe"
set "_fil2=%CommonProgramFiles(x86)%\Microsoft Shared\ClickToRun\OfficeClickToRun.exe"
set "_work=%~dp0bin"
set "_Local=%LocalAppData%"
set "_cscript=cscript //Nologo //B"
setlocal EnableDelayedExpansion
pushd "!_work!"
if not exist "%xBit%\cleanospp.exe" (
set "msg=ERROR: required file cleanospp.exe is missing"
goto :TheEnd
)
for %%# in (OffScrubC2R,OffScrub_O16msi,OffScrub_O15msi,OffScrub10,OffScrub07,OffScrub03) do (
if not exist ".\%%#.vbs" (set "msg=ERROR: required file %%# is missing"&goto :TheEnd)
)
set "_Nul1=1>nul"
set "_Nul2=2>nul"
set "_Nul6=2^>nul"
set "_Nul3=1>nul 2>nul"

title Office Scrubber
echo.
echo ============================================================
echo Detecting Office versions, please wait...

set OsppHook=1
sc query osppsvc %_Nul3%
if %ERRORLEVEL% EQU 1060 set OsppHook=0

for %%A in (11,12,14,15,16) do call :officeMSI %%A

set _O16CTR=0
sc query ClickToRunSvc %_Nul3% && set _O16CTR=1
reg query HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Configuration /v ProductReleaseIds %_Nul3% && (
set _O16CTR=1
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Configuration /v Platform" %_Nul6%') do set "_plat=%%b"
)
if not %xOS%==x86 if %_O16CTR% EQU 0 reg query HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration /v ProductReleaseIds %_Nul3% && (
set _O16CTR=1
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration /v Platform" %_Nul6%') do set "_plat=%%b"
)
if exist "!_file!" set _O16CTR=1
if exist "!_fil2!" if /i "%PROCESSOR_ARCHITECTURE%"=="arm64" set _O16CTR=1
if %_O16CTR% EQU 1 if not defined _plat (
if exist "%ProgramFiles(x86)%\Microsoft Office\Office16\OSPP.VBS" (set "_plat=x86") else (set "_plat=%xBit%")
)

set _O15CTR=0
sc query OfficeSvc %_Nul3% && set _O15CTR=1
reg query HKLM\SOFTWARE\Microsoft\Office\15.0\ClickToRun /v InstallPath %_Nul3% && (
set _O15CTR=1
)
if %_O15CTR% EQU 0 reg query HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\15.0\ClickToRun /v InstallPath %_Nul3% && (
set _O15CTR=1
)
if %_O15CTR% EQU 0 reg query HKLM\SOFTWARE\Microsoft\Office\15.0\ClickToRun\propertyBag /v productreleaseid %_Nul3% && (
set _O15CTR=1
)
if %_O15CTR% EQU 0 reg query HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\15.0\ClickToRun\propertyBag /v productreleaseid %_Nul3% && (
set _O15CTR=1
)

set _O14CTR=0
if %xOS%==x86 reg query HKLM\SOFTWARE\Microsoft\Office\14.0\CVH /f Click2run /k %_Nul3% && set _O14CTR=1
if not %xOS%==x86 reg query HKLM\SOFTWARE\Wow6432Node\Microsoft\Office\14.0\CVH /f Click2run /k %_Nul3% && set _O14CTR=1

set _O16UWP=0
if %winbuild% GEQ 10240 reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msoxmled.exe" %_Nul3% && (
dir /b "%ProgramFiles%\WindowsApps\Microsoft.Office.Desktop*" %_Nul3% && set _O16UWP=1
if not %xOS%==x86 dir /b "%ProgramW6432%\WindowsApps\Microsoft.Office.Desktop*" %_Nul3% && set _O16UWP=1
if not %xOS%==x86 dir /b "%ProgramFiles(x86)%\WindowsApps\Microsoft.Office.Desktop*" %_Nul3% && set _O16UWP=1
)

set kO16=HKCU\SOFTWARE\Microsoft\Office\16.0
set _O16NXT=0
dir /b /s /a:-d "!_Local!\Microsoft\Office\Licenses\*1*" %_Nul3% && set _O16NXT=1
dir /b /s /a:-d "!ProgramData!\Microsoft\Office\Licenses\*1*" %_Nul3% && set _O16NXT=1
reg query "%kO16%\Common\Licensing\LicensingNext" /v MigrationToV5Done %_Nul2% | find /i "0x1" %_Nul1% && set _O16NXT=1

set tOCTR=0&set "dOCTR="
set tOM16=0&set "dOM16="
set tOM15=0&set "dOM15="
set tOM14=0&set "dOM14="
set tOM12=0&set "dOM12="
set tOM11=0&set "dOM11="
set tOUWP=0&set "dOUWP="
set "dONXT="
if %_O15CTR% EQU 1 set tOCTR=1&set "dOCTR={*} / 2013"
if %_O16CTR% EQU 1 set tOCTR=1&set "dOCTR={*}"
if %_O16MSI% EQU 1 set tOM16=1&set "dOM16={*}"
if %_O15MSI% EQU 1 set tOM15=1&set "dOM15={*}"
if %_O14CTR% EQU 1 set tOM14=1&set "dOM14={*} / C2R"
if %_O14MSI% EQU 1 set tOM14=1&set "dOM14={*}"
if %_O12MSI% EQU 1 set tOM12=1&set "dOM12={*}"
if %_O11MSI% EQU 1 set tOM11=1&set "dOM11={*}"
if %_O16UWP% EQU 1 set tOUWP=1&set "dOUWP={*}"
if %_O16NXT% EQU 1 set "dONXT={*}"

:Menu
set _er=0
call :Hdr
echo [1] Scrub ALL
echo [2] Scrub Office C2R  %dOCTR%
echo [3] Scrub Office 2016 %dOM16%
echo [4] Scrub Office 2013 %dOM15%
echo [5] Scrub Office 2010 %dOM14%
echo [6] Scrub Office 2007 %dOM12%
echo [7] Scrub Office 2003 %dOM11%
if %winbuild% GEQ 10240 echo [8] Scrub Office UWP  %dOUWP%
echo.
echo. --- Office 2016 and later ---
echo [C] Clean vNext Licenses %dONXT%
echo [R] Remove all Licenses
echo [T] Reset C2R Licenses
echo [U] Uninstall all Keys
echo.
echo ============================================================
choice /c 12345678CRTU0 /n /m "Choose a menu option, or press 0 to Exit: "
set _er=%ERRORLEVEL%
if %_er% EQU 13 goto :eof
if %_er% EQU 12 goto :KeysU
if %_er% EQU 11 goto :LcnsT
if %_er% EQU 10 goto :LcnsR
if %_er% EQU 9 goto :LcnsC
if %_er% EQU 8 (if %winbuild% GEQ 10240 (goto :sOUWP) else (goto :Menu))
if %_er% EQU 7 goto :sOM11
if %_er% EQU 6 goto :sOM12
if %_er% EQU 5 goto :sOM14
if %_er% EQU 4 goto :sOM15
if %_er% EQU 3 goto :sOM16
if %_er% EQU 2 goto :sOCTR
if %_er% EQU 1 goto :mALL
goto :Menu

:mALL
set "aOCTR=NO  %dOCTR%"
set "aOM16=NO  %dOM16%"
set "aOM15=NO  %dOM15%"
set "aOM14=NO  %dOM14%"
set "aOM12=NO  %dOM12%"
set "aOM11=NO  %dOM11%"
set "aOUWP=NO  %dOUWP%"
if %tOCTR% EQU 1 set "aOCTR=YES %dOCTR%"
if %tOM16% EQU 1 set "aOM16=YES %dOM16%"
if %tOM15% EQU 1 set "aOM15=YES %dOM15%"
if %tOM14% EQU 1 set "aOM14=YES %dOM14%"
if %tOM12% EQU 1 set "aOM12=YES %dOM12%"
if %tOM11% EQU 1 set "aOM11=YES %dOM11%"
if %tOUWP% EQU 1 set "aOUWP=YES %dOUWP%"
set _er=0
call :Hdr
echo [1] Start the operation
echo [2] Office C2R : %aOCTR%
echo [3] Office 2016: %aOM16%
echo [4] Office 2013: %aOM15%
echo [5] Office 2010: %aOM14%
echo [6] Office 2007: %aOM12%
echo [7] Office 2003: %aOM11%
if %winbuild% GEQ 10240 echo [8] Office UWP : %aOUWP%
echo.
echo -------
echo Notice:
echo It's recommended to only scrub detected versions {*}
echo selecting all is not necessary and will take a long time.
echo.
echo ============================================================
choice /c 123456780 /n /m "Change menu options, or press 0 to Exit: "
set _er=%ERRORLEVEL%
if %_er% EQU 9 goto :eof
if %_er% EQU 8 (if %tOUWP% EQU 1 (set tOUWP=0) else (set tOUWP=1)&goto :mALL)
if %_er% EQU 7 (if %tOM11% EQU 1 (set tOM11=0) else (set tOM11=1)&goto :mALL)
if %_er% EQU 6 (if %tOM12% EQU 1 (set tOM12=0) else (set tOM12=1)&goto :mALL)
if %_er% EQU 5 (if %tOM14% EQU 1 (set tOM14=0) else (set tOM14=1)&goto :mALL)
if %_er% EQU 4 (if %tOM15% EQU 1 (set tOM15=0) else (set tOM15=1)&goto :mALL)
if %_er% EQU 3 (if %tOM16% EQU 1 (set tOM16=0) else (set tOM16=1)&goto :mALL)
if %_er% EQU 2 (if %tOCTR% EQU 1 (set tOCTR=0) else (set tOCTR=1)&goto :mALL)
if %_er% EQU 1 goto :sOALL
goto :mALL

:Hdr
cls
echo ============================================================
goto :eof

:sOALL
call :Hdr
echo.
echo Uninstall Product Keys
%xBit%\cleanospp.exe -PKey %_Nul3%
call :cKMS %_Nul3%
if %tOCTR% EQU 1 call :rOCTR
if %tOUWP% EQU 1 if %_pwsh% EQU 1 call :rOUWP
if %tOM16% EQU 1 call :rOM16
if %tOM15% EQU 1 call :rOM15
if %tOM14% EQU 1 call :rOM14
if %tOM12% EQU 1 call :rOM12
if %tOM11% EQU 1 call :rOM11
call :cSPP
goto :Fin

:sOCTR
call :Hdr
call :rOCTR
if %_O15MSI% EQU 0 call :cSPP
goto :Fin

:sOM16
call :Hdr
call :rOM16
if %_O15MSI% EQU 0 call :cSPP
goto :Fin

:sOM15
call :Hdr
call :rOM15
if %_O16MSI% EQU 0 if %_O16CTR% EQU 0 if %_O16UWP% EQU 0 call :cSPP
goto :Fin

:sOM14
call :Hdr
call :rOM14
goto :Fin

:sOM12
call :Hdr
call :rOM12
goto :Fin

:sOM11
call :Hdr
call :rOM11
goto :Fin

:sOUWP
call :Hdr
if %_pwsh% EQU 0 (
set "msg=ERROR: Windows Powershell is not detected."
goto :TheEnd
)
call :rOUWP
set "msg=Done."
goto :TheEnd

:rOCTR
if exist "!_file!" (
echo.
echo Execute OfficeClickToRun.exe
%_Nul3% start "" /WAIT "!_file!" platform=%_plat% productstoremove=AllProducts displaylevel=False
)
if exist "!_fil2!" if /i "%PROCESSOR_ARCHITECTURE%"=="arm64" (
echo.
echo Execute OfficeClickToRun.exe
%_Nul3% start "" /WAIT "!_fil2!" platform=%_plat% productstoremove=AllProducts displaylevel=False
)
echo.
echo Scrub Office C2R
for %%A in (16,19,21) do call :cKpp %%A
if %_O15CTR% EQU 1 call :cKpp 15
%_Nul3% %_cscript% OffScrubC2R.vbs ALL /QUIET /OFFLINE
%_Nul3% call :vNextDir
%_Nul3% call :officeREG 16
goto :eof

:rOUWP
echo.
echo Remove Office UWP Apps
%_Nul3% %_psc% "Get-AppXPackage -Name '*Microsoft.Office.Desktop*' | Foreach {Remove-AppxPackage $_.PackageFullName}"
%_Nul3% %_psc% "Get-AppXProvisionedPackage -Online | Where DisplayName -Like '*Microsoft.Office.Desktop*' | Remove-AppXProvisionedPackage -Online"
goto :eof

:rOM16
echo.
echo Scrub Office 2016 MSI
call :cKpp 16
%_Nul3% %_cscript% OffScrub_O16msi.vbs %_para%
%_Nul3% call :officeREG 16
goto :eof

:rOM15
echo.
echo Scrub Office 2013 MSI
call :cKpp 15
%_Nul3% %_cscript% OffScrub_O15msi.vbs %_para%
%_Nul3% call :officeREG 15
goto :eof

:rOM14
echo.
echo Scrub Office 2010
call :cK14
%_Nul3% %_cscript% OffScrub10.vbs %_para%
%_Nul3% call :officeREG 14
goto :eof

:rOM12
echo.
echo Scrub Office 2007
%_Nul3% %_cscript% OffScrub07.vbs %_para%
%_Nul3% call :officeREG 12
goto :eof

:rOM11
echo.
echo Scrub Office 2003
%_Nul3% %_cscript% OffScrub03.vbs %_para%
%_Nul3% call :officeREG 11
goto :eof

:cSPP
%xBit%\cleanospp.exe %_Nul3%
call :slmgr
goto :eof

:slmgr
if exist "%SysPath%\spp\store_test\2.0\tokens.dat" (
echo.
echo Refresh Windows Insider Preview Licenses
%_cscript% %SysPath%\slmgr.vbs /rilc %_Nul3%
if !ERRORLEVEL! NEQ 0 %_cscript% %SysPath%\slmgr.vbs /rilc %_Nul3%
)
goto :eof

:Fin
for /f %%# in ('"dir /b %SystemRoot%\temp\ose*.exe" %_Nul6%') do taskkill /t /f /IM %%# %_Nul3%
del /f /q "%SystemRoot%\temp\ose*.exe" %_Nul3%
set "msg=Finished. It's recommended to restart the system."
goto :TheEnd

:officeMSI
set _O%1MSI=0
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\%1.0\Common\InstallRoot /v Path" %_Nul6%') do if exist "%%b\*.dll" set _O%1MSI=1
if exist "%ProgramFiles%\Microsoft Office\Office%1\*.dll" set _O%1MSI=1
if %xOS%==x86 goto :eof
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Wow6432Node\Microsoft\Office\%1.0\Common\InstallRoot /v Path" %_Nul6%') do if exist "%%b\*.dll" set _O%1MSI=1
if exist "%ProgramW6432%\Microsoft Office\Office%1\*.dll" set _O%1MSI=1
if exist "%ProgramFiles(x86)%\Microsoft Office\Office%1\*.dll" set _O%1MSI=1
goto :eof

:officeREG
reg delete HKCU\Software\Microsoft\Office\%1.0 /f
reg delete HKCU\Software\Policies\Microsoft\Office\%1.0 /f
reg delete HKLM\SOFTWARE\Microsoft\Office\%1.0 /f
reg delete HKLM\SOFTWARE\Policies\Microsoft\Office\%1.0 /f
reg delete HKLM\SOFTWARE\Microsoft\Office\%1.0 /f /reg:32
reg delete HKLM\SOFTWARE\Policies\Microsoft\Office\%1.0 /f /reg:32
goto :eof

:cK14
if %_WSH% EQU 0 if %WMI_VBS% NEQ 0 goto :eof
if %WMI_VBS% NEQ 0 cd ..
set _spp=OfficeSoftwareProtectionProduct
if %OsppHook% NEQ 0 (
call :cKEY 14
)
if %WMI_VBS% NEQ 0 cd bin
goto :eof

:cKpp
if %_WSH% EQU 0 if %WMI_VBS% NEQ 0 goto :eof
if %WMI_VBS% NEQ 0 cd ..
set _spp=SoftwareLicensingProduct
if %winbuild% GEQ 9200 (
call :cKEY %1
)
set _spp=OfficeSoftwareProtectionProduct
if %winbuild% LSS 9200 if %OsppHook% NEQ 0 (
call :cKEY %1
)
if %WMI_VBS% NEQ 0 cd bin
goto :eof

:cKMS
if %_WSH% EQU 0 if %WMI_VBS% NEQ 0 goto :eof
if %WMI_VBS% NEQ 0 cd ..
set _spp=SoftwareLicensingProduct
if %winbuild% GEQ 9200 (
reg delete "HKLM\%SPPk%\%_oApp%" /f
reg delete "HKLM\%SPPk%\%_oApp%" /f /reg:32
reg delete "HKEY_USERS\S-1-5-20\%SPPk%\%_oApp%" /f
for %%A in (15,16,19,21) do call :cKEY %%A
)
set _spp=OfficeSoftwareProtectionProduct
if %winbuild% GEQ 9200 if %OsppHook% NEQ 0 (
call :cKEY 14
)
if %winbuild% LSS 9200 if %OsppHook% NEQ 0 (
reg delete "HKLM\%OPPk%\%_oApp%" /f
reg delete "HKLM\%OPPk%\%_oApp%" /f /reg:32
for %%A in (14,15,16,19,21) do call :cKEY %%A
)
reg delete "HKLM\%OPPk%\%_oA14%" /f
reg delete "HKEY_USERS\S-1-5-20\%OPPk%" /f
if %WMI_VBS% NEQ 0 cd bin
goto :eof

:cKEY
set "_ocq=Name LIKE 'Office %~1%%' AND PartialProductKey is not NULL"
set "_qr="wmic path %_spp% where (%_ocq%) get ID /VALUE""
if %WMI_VBS% NEQ 0 set "_qr=%_csq% %_spp% "%_ocq%" ID"
for /f "tokens=2 delims==" %%# in ('%_qr% %_Nul6%') do (set "aID=%%#"&call :cAPP)
goto :eof

:cAPP
set "_qr=wmic path %_spp% where ID='%aID%' call UninstallProductKey"
if %WMI_VBS% NEQ 0 set "_qr=%_csm% "%_spp%.ID='%aID%'" UninstallProductKey"
%_qr% %_Nul3%
goto :eof

:vNextDir
attrib -R "!ProgramData!\Microsoft\Office\Licenses"
attrib -R "!_Local!\Microsoft\Office\Licenses"
rd /s /q "!ProgramData!\Microsoft\Office\Licenses\"
rd /s /q "!_Local!\Microsoft\Office\Licenses\"
goto :eof

:vNextREG
reg delete "%kO16%\Common\Licensing" /f
reg delete "%kO16%\Registration" /f
goto :eof

:LcnsC
call :Hdr
echo.
echo Clean vNext Licenses
%_Nul3% call :vNextDir
%_Nul3% call :vNextREG
set "msg=Done."
goto :TheEnd

:KeysU
call :Hdr
echo.
echo Uninstall Product Keys
%xBit%\cleanospp.exe -PKey %_Nul3%
for %%A in (15,16,19,21) do call :cKpp %%A
set "msg=Done."
goto :TheEnd

:LcnsR
call :Hdr
echo.
echo Remove Office Licenses
%xBit%\cleanospp.exe -Licenses %_Nul3%
call :slmgr
set "msg=Done."
goto :TheEnd

:LcnsT
call :Hdr
echo.
echo Reset Office C2R Licenses
if %_O16CTR% equ 0 (
set "msg=ERROR: No installed Office ClickToRun detected."
goto :TheEnd
)
set "_InstallRoot="
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\ClickToRun /v InstallPath" %_Nul6%') do (set "_InstallRoot=%%b\root")
if not "%_InstallRoot%"=="" (
  for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\ClickToRun /v PackageGUID" %_Nul6%') do (set "_GUID=%%b")
  set "_PRIDs=HKLM\SOFTWARE\Microsoft\Office\ClickToRun\ProductReleaseIDs"
) else (
  for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun /v InstallPath" %_Nul6%') do (set "_InstallRoot=%%b\root")
  for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun /v PackageGUID" %_Nul6%') do (set "_GUID=%%b")
  set "_PRIDs=HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\ProductReleaseIDs"
)
set "_Integrator=%_InstallRoot%\integration\integrator.exe"
for /f "skip=2 tokens=2*" %%a in ('"reg query %_PRIDs% /v ActiveConfiguration" %_Nul6%') do set "_PRIDs=%_PRIDs%\%%b"
if not exist "%_Integrator%" (
set "msg=ERROR: Could not detect Office Licenses Integrator.exe"
goto :TheEnd
)
for /f "tokens=8 delims=\" %%a in ('reg query "%_PRIDs%" /f ".16" /k %_Nul6% ^| find /i "ClickToRun"') do (
if not defined _SKUs (set "_SKUs=%%a") else (set "_SKUs=!_SKUs!,%%a")
)
if not defined _SKUs (
set "msg=ERROR: Could not detect originally installed Office Products."
goto :TheEnd
)
echo.
echo Remove Office Licenses
%xBit%\cleanospp.exe -Licenses %_Nul3%
call :slmgr
echo.
echo Install Office C2R Licenses
for %%a in (%_SKUs%) do (
"!_Integrator!" /R /License PRIDName=%%a.16 PackageGUID="%_GUID%" PackageRoot="!_InstallRoot!" %_Nul1%
)
set "msg=Done."
goto :TheEnd

:E_Admin
set "msg=ERROR: This script requires administrator privileges."
goto :TheEnd

:TheEnd
echo.
echo ============================================================
echo %msg%
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
   <job id="ELAV">
      <script language="VBScript">
         Set strArg=WScript.Arguments.Named
         Set strRdlproc = CreateObject("WScript.Shell").Exec("rundll32 kernel32,Sleep")
         With GetObject("winmgmts:\\.\root\CIMV2:Win32_Process.Handle='" & strRdlproc.ProcessId & "'")
            With GetObject("winmgmts:\\.\root\CIMV2:Win32_Process.Handle='" & .ParentProcessId & "'")
               If InStr (.CommandLine, WScript.ScriptName) <> 0 Then
                  strLine = Mid(.CommandLine, InStr(.CommandLine , "/File:") + Len(strArg("File")) + 8)
               End If
            End With
            .Terminate
         End With
         CreateObject("Shell.Application").ShellExecute "cmd.exe", "/c " & chr(34) & chr(34) & strArg("File") & chr(34) & strLine & chr(34), "", "runas", 1
      </script>
   </job>
</package>