<!-- : Begin batch script
@setlocal DisableDelayedExpansion
@set uivr=v12
@echo off
set uac=-elevated
for %%# in (All,C2R,UWP,M16,M15,M14,M12,M11) do set _u%%#=0
set Unattend=0
set qerel=
set _elev=
set _args=
set _args=%*
if not defined _args goto :NoProgArgs
if "%~1"=="" set "_args="&goto :NoProgArgs
set "_args="
for %%# in (%*) do (
if /i "%%~#"=="%uac%" set _elev=1
if /i "%%~#"=="-wow" set _rel1=1
if /i "%%~#"=="-arm" set _rel2=1
if /i "%%~#"=="-qedit" set qerel=1
if /i "%%~#"=="/A" set _uAll=1&set Unattend=1
if /i "%%~#"=="/C" set _uC2R=1&set Unattend=1
if /i "%%~#"=="/P" set _uUWP=1&set Unattend=1
if /i "%%~#"=="/M6" set _uM16=1&set Unattend=1
if /i "%%~#"=="/M5" set _uM15=1&set Unattend=1
if /i "%%~#"=="/M4" set _uM14=1&set Unattend=1
if /i "%%~#"=="/M2" set _uM12=1&set Unattend=1
if /i "%%~#"=="/M1" set _uM11=1&set Unattend=1
)

:NoProgArgs
set "_cmdf=%~f0"
if exist "%SystemRoot%\Sysnative\cmd.exe" if not defined _rel1 (
setlocal EnableDelayedExpansion
start %SystemRoot%\Sysnative\cmd.exe /c ""!_cmdf!" -wow %*"
exit /b
)
if exist "%SystemRoot%\SysArm32\cmd.exe" if /i %PROCESSOR_ARCHITECTURE%==AMD64 if not defined _rel2 (
setlocal EnableDelayedExpansion
start %SystemRoot%\SysArm32\cmd.exe /c ""!_cmdf!" -arm %*"
exit /b
)
set "SysPath=%SystemRoot%\System32"
set "Path=%SystemRoot%\System32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
if exist "%SystemRoot%\Sysnative\reg.exe" (
set "SysPath=%SystemRoot%\Sysnative"
set "Path=%SystemRoot%\Sysnative;%SystemRoot%;%SystemRoot%\Sysnative\Wbem;%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\;%Path%"
)
set "_psc=powershell -nop -c"
set "_err===== ERROR ===="
set "_ln============================================================="
set "_sr=************************************************************"

set _leg=0
ver|findstr /C:" 5." >nul && set _leg=1
set winmaj=0
for /f "tokens=2 delims=[]" %%G in ('ver') do for /f "tokens=2,3 delims=. " %%H in ("%%~G") do set "winmaj=%%H"
if %winmaj% lss 6 set _leg=1
set _wxp=0
if %_leg% equ 1 reg.exe query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuildNumber |findstr /C:"2600" >nul && set _wxp=1
set _sk=2
if %_wxp% equ 1 set _sk=4
set winbuild=1
if %_leg% equ 0 for /f "tokens=6 delims=[]. " %%# in ('ver') do set winbuild=%%#
if %_leg% equ 1 for /f "skip=%_sk% tokens=1,2,3 delims=. " %%i in ('reg.exe query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v BuildLab 2^>nul') do (if /i "%%i"=="BuildLab" if not "%%~k"=="" set "winbuild=%%~k")

set _cwmi=0
for %%# in (wmic.exe) do @if not "%%~$PATH:#"=="" (
wmic path Win32_ComputerSystem get CreationClassName /value 2>nul | find /i "ComputerSystem" 1>nul && set _cwmi=1
)
set _pwsh=1
for %%# in (powershell.exe) do @if "%%~$PATH:#"=="" set _pwsh=0
if not exist "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" set _pwsh=0

if %_leg% equ 1 goto :Passed

1>nul 2>nul reg.exe query HKU\S-1-5-19 && (
  goto :Passed
  ) || (
  if defined _elev goto :E_Admin
)

set _PSarg="""%~f0""" %* %uac%
set _PSarg=%_PSarg:'=''%

(1>nul 2>nul cscript //NoLogo "%~f0?.wsf" //job:ELAV /File:"%~f0" %* %uac%) && (
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
set _WSH=1
reg.exe query "HKCU\SOFTWARE\Microsoft\Windows Script Host\Settings" /v Enabled 2>nul | find /i "0x0" 1>nul && (set _WSH=0)
reg.exe query "HKLM\SOFTWARE\Microsoft\Windows Script Host\Settings" /v Enabled 2>nul | find /i "0x0" 1>nul && (set _WSH=0)
if %_WSH% EQU 0 goto :E_WSH
if not exist "%SysPath%\vbscript.dll" goto :E_VBS
set WMI_VBS=0
if %_cwmi% EQU 0 set WMI_VBS=1
if %_leg% equ 1 set WMI_VBS=1
set "_csq=cscript.exe //NoLogo //Job:WmiQuery "%~nx0?.wsf""
set "_csm=cscript.exe //NoLogo //Job:WmiMethod "%~nx0?.wsf""

if %winbuild% LSS 10586 (
reg.exe query HKCU\Console /v QuickEdit 2>nul | find /i "0x0" >nul && set qerel=1
)
if defined qerel goto :skipQE
if %_pwsh% EQU 0 goto :skipQE
if %winbuild% GEQ 17763 (
set "launchcmd=start conhost.exe %_psc%"
) else (
set "launchcmd=%_psc%"
)
set _PSarg="""%~f0""" %* -qedit
set _PSarg=%_PSarg:'=''%
set "d1=$t=[AppDomain]::CurrentDomain.DefineDynamicAssembly(4, 1).DefineDynamicModule(2, $False).DefineType(0);"
set "d2=$t.DefinePInvokeMethod('GetStdHandle', 'kernel32.dll', 22, 1, [IntPtr], @([Int32]), 1, 3).SetImplementationFlags(128);"
set "d3=$t.DefinePInvokeMethod('SetConsoleMode', 'kernel32.dll', 22, 1, [Boolean], @([IntPtr], [Int32]), 1, 3).SetImplementationFlags(128);"
set "d4=$k=$t.CreateType(); $b=$k::SetConsoleMode($k::GetStdHandle(-10), 0x0080);"
if %_uAll% EQU 1 set "d5=$B=$Host.UI.RawUI.BufferSize;$B.Height=3000;$Host.UI.RawUI.BufferSize=$B;"
setlocal EnableDelayedExpansion
%launchcmd% "!d1! !d2! !d3! !d4! !d5! & cmd.exe '/c' '!_PSarg!'" &exit /b
exit /b

:skipQE
set "_oApp=0ff1ce15-a989-479d-af46-f275c6370663"
set "_oA14=59a52881-a989-479d-af46-f275c6370663"
set "OPPk=SOFTWARE\Microsoft\OfficeSoftwareProtectionPlatform"
set "SPPk=SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform"
set "_para=ALL /OSE /NOCANCEL /FORCE /ENDCURRENTINSTALLS /DELETEUSERSETTINGS /CLEARADDINREG /REMOVELYNC"
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
set "_cscript=cscript //Nologo"
set kO16=HKCU\SOFTWARE\Microsoft\Office\16.0
setlocal EnableDelayedExpansion
pushd "!_work!"
for %%# in (OffScrubC2R.vbs,OffScrub_O16msi.vbs,OffScrub_O15msi.vbs,OffScrub10.vbs,OffScrub07.vbs,OffScrub03.vbs,CleanOffice.txt) do (
if not exist ".\%%#" (set "msg=ERROR: required file %%# is missing"&goto :TheEnd)
)
set "_Nul1=1>nul"
set "_Nul2=2>nul"
set "_Nul6=2^>nul"
set "_Nul3=1>nul 2>nul"

@title Office Scrubber %uivr%
echo.
echo %_ln%
echo Detecting Office versions, please wait . . .

set OsppHook=1
sc query osppsvc %_Nul3%
if %ERRORLEVEL% EQU 1060 set OsppHook=0

for %%A in (11,12,14,15,16) do call :officeMSI %%A

call :officeCTR

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

if %_uAll% EQU 1 (
if %winbuild% GEQ 7600 set tOCTR=1
if %winbuild% GEQ 7600 set tOM16=1
if %winbuild% LSS 7600 set tOM14=1
if %_uM15% EQU 1 if %winbuild% GEQ 7600 set tOM15=1
if %_uM14% EQU 1 set tOM14=1
if %_uM12% EQU 1 set tOM12=1
if %_uM11% EQU 1 set tOM11=1
if %_uUWP% EQU 1 if %winbuild% GEQ 10240 set tOUWP=1
goto :sOALL
)
if %_uC2R% EQU 1 if %winbuild% GEQ 7600 goto :sOCTR
if %_uM16% EQU 1 if %winbuild% GEQ 7600 goto :sOM16
if %_uM15% EQU 1 if %winbuild% GEQ 7600 goto :sOM15
if %_uM14% EQU 1 goto :sOM14
if %_uM12% EQU 1 goto :sOM12
if %_uM11% EQU 1 goto :sOM11
if %_uUWP% EQU 1 if %winbuild% GEQ 10240 goto :sOUWP

:Menu
set _er=0
set _pt=
call :Hdr
echo [1] Scrub ALL
if %winbuild% GEQ 7600 (
echo [2] Scrub Office C2R  %dOCTR%
echo [3] Scrub Office 2016 %dOM16%
echo [4] Scrub Office 2013 %dOM15%
)
echo [5] Scrub Office 2010 %dOM14%
echo [6] Scrub Office 2007 %dOM12%
echo [7] Scrub Office 2003 %dOM11%
if %winbuild% GEQ 10240 echo [8] Scrub Office UWP  %dOUWP%
if %winbuild% GEQ 7600 (
echo.
echo. --- Office 2016 and later ---
echo [C] Clean vNext Licenses %dONXT%
echo [R] Remove all Licenses
echo [T] Reset C2R Licenses
echo [U] Uninstall all Keys
)
echo.
echo %_ln%
if %_wxp% equ 0 (
choice /c 12345678CRTU0 /n /m "Choose a menu option, or press 0 to Exit: "
set _er=!ERRORLEVEL!
) else (
set /p _pt="Input a menu option and press Enter, or 0 to Exit: "
)
if defined _pt (
if /i "%_pt%"=="0" set _pt=13
if /i "%_pt%"=="U" set _pt=12
if /i "%_pt%"=="T" set _pt=11
if /i "%_pt%"=="R" set _pt=10
if /i "%_pt%"=="C" set _pt=9
set _er=!_pt!
)
if "%_er%"=="13" goto :eof
if %winbuild% GEQ 7600 (
if "%_er%"=="12" goto :KeysU
if "%_er%"=="11" goto :LcnsT
if "%_er%"=="10" goto :LcnsR
if "%_er%"=="9" goto :LcnsC
)
if "%_er%"=="8" if %winbuild% GEQ 10240 goto :sOUWP
if "%_er%"=="7" goto :sOM11
if "%_er%"=="6" goto :sOM12
if "%_er%"=="5" goto :sOM14
if %winbuild% GEQ 7600 (
if "%_er%"=="4" goto :sOM15
if "%_er%"=="3" goto :sOM16
if "%_er%"=="2" goto :sOCTR
if "%_er%"=="1" set tOCTR=1&set tOM16=1&goto :mALL
)
if %winbuild% LSS 7600 (
if "%_er%"=="1" set tOM14=1&goto :mALL
)
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
set _pt=
call :Hdr
echo [1] Start the operation
if %winbuild% GEQ 7600 (
echo [2] Office C2R : %aOCTR%
echo [3] Office 2016: %aOM16%
echo [4] Office 2013: %aOM15%
)
echo [5] Office 2010: %aOM14%
echo [6] Office 2007: %aOM12%
echo [7] Office 2003: %aOM11%
if %winbuild% GEQ 10240 echo [8] Office UWP : %aOUWP%
echo.
echo -------
echo Notice:
echo Manually selecting all is not necessary and will take a long time.
echo.
echo %_ln%
if %_wxp% equ 0 (
choice /c 123456780 /n /m "Change menu options, or press 0 to Exit: "
set _er=!ERRORLEVEL!
) else (
set /p _pt="Input a menu option and press Enter, or 0 to Exit: "
)
if defined _pt (
if /i "%_pt%"=="0" set _pt=9
set _er=!_pt!
)
if "%_er%"=="9" goto :eof
if "%_er%"=="8" if %winbuild% GEQ 10240 (if %tOUWP% EQU 1 (set tOUWP=0) else (set tOUWP=1)&goto :mALL)
if "%_er%"=="7" (if %tOM11% EQU 1 (set tOM11=0) else (set tOM11=1)&goto :mALL)
if "%_er%"=="6" (if %tOM12% EQU 1 (set tOM12=0) else (set tOM12=1)&goto :mALL)
if "%_er%"=="5" (if %tOM14% EQU 1 (set tOM14=0) else (set tOM14=1)&goto :mALL)
if %winbuild% GEQ 7600 (
if "%_er%"=="4" (if %tOM15% EQU 1 (set tOM15=0) else (set tOM15=1)&goto :mALL)
if "%_er%"=="3" (if %tOM16% EQU 1 (set tOM16=0) else (set tOM16=1)&goto :mALL)
if "%_er%"=="2" (if %tOCTR% EQU 1 (set tOCTR=0) else (set tOCTR=1)&goto :mALL)
)
if "%_er%"=="1" goto :sOALL
goto :mALL

:Hdr
@cls
echo %_ln%
goto :eof

:sOALL
call :Hdr
echo.
echo Uninstalling Product Keys . . .
call :cKMS %_Nul3%
if %winbuild% GEQ 7600 (
if %tOCTR% EQU 1 echo.&echo %_sr%&call :rOCTR
if %tOM16% EQU 1 echo.&echo %_sr%&call :rOM16
if %tOM15% EQU 1 echo.&echo %_sr%&call :rOM15
)
if %tOM14% EQU 1 echo.&echo %_sr%&call :rOM14
if %tOM12% EQU 1 echo.&echo %_sr%&call :rOM12
if %tOM11% EQU 1 echo.&echo %_sr%&call :rOM11
if %tOUWP% EQU 1 if %winbuild% GEQ 10240 if %_pwsh% EQU 1 echo.&echo %_sr%&call :rOUWP
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
echo Executing OfficeClickToRun.exe . . .
%_Nul3% call :CloseC2R
%_Nul3% start "" /WAIT "!_file!" platform=%_plat% productstoremove=AllProducts displaylevel=False
)
if exist "!_fil2!" if /i "%PROCESSOR_ARCHITECTURE%"=="arm64" (
echo.
echo Executing OfficeClickToRun.exe . . .
%_Nul3% call :CloseC2R
%_Nul3% start "" /WAIT "!_fil2!" platform=%_plat% productstoremove=AllProducts displaylevel=False
)
echo.
echo Scrubbing Office C2R . . .
for %%A in (16,19,21,24) do call :cKpp %%A
if %_O15CTR% EQU 1 call :cKpp 15
%_cscript% OffScrubC2R.vbs ALL /OFFLINE
%_Nul3% call :vNextDir
%_Nul3% call :officeREG 16
goto :eof

:CloseC2R
net stop OfficeSvc /y
net stop ClickToRunSvc /y
for %%# in (
appvshnotify
integratedoffice
integrator
firstrun
communicator
msosync
OneNoteM
iexplore
mavinject32
werfault
perfboost
roamingoffice
officeclicktorun
officeondemand
OfficeC2RClient
msaccess
excel
groove
lync
onenote
outlook
powerpnt
mspub
winword
winproj
visio
mstore
setlang
msouc
ois
graph
) do (
tasklist /FI "IMAGENAME eq %%#.exe" | find /i "%%#.exe" && taskkill /t /f /IM %%#.exe
)
net start OfficeSvc /y
net start ClickToRunSvc /y
goto :eof

:rOUWP
echo.
echo Removing Office UWP Apps . . .
%_Nul3% %_psc% "Get-AppXPackage -Name '*Microsoft.Office.Desktop*' | Foreach {Remove-AppxPackage $_.PackageFullName}"
%_Nul3% %_psc% "Get-AppXProvisionedPackage -Online | Where DisplayName -Like '*Microsoft.Office.Desktop*' | Remove-AppXProvisionedPackage -Online"
@title Office Scrubber %uivr%
goto :eof

:rOM16
echo.
echo Scrubbing Office 2016 MSI . . .
call :cKpp 16
%_cscript% OffScrub_O16msi.vbs %_para%
%_Nul3% call :officeREG 16
goto :eof

:rOM15
echo.
echo Scrubbing Office 2013 MSI . . .
call :cKpp 15
%_cscript% OffScrub_O15msi.vbs %_para%
%_Nul3% call :officeREG 15
goto :eof

:rOM14
echo.
echo Scrubbing Office 2010 . . .
call :cK14
%_cscript% OffScrub10.vbs %_para%
%_Nul3% call :officeREG 14
goto :eof

:rOM12
echo.
echo Scrubbing Office 2007 . . .
%_cscript% OffScrub07.vbs %_para%
%_Nul3% call :officeREG 12
goto :eof

:rOM11
echo.
echo Scrubbing Office 2003 . . .
%_cscript% OffScrub03.vbs %_para%
%_Nul3% call :officeREG 11
goto :eof

:cSPP
echo.
echo Removing Office Licenses . . .
call :oppcln
call :slmgr
goto :eof

:oppcln
%_Nul3% %_psc% "cd -Lit ($env:__CD__); $f=[IO.File]::ReadAllText('.\CleanOffice.txt') -split ':embed\:.*'; iex ($f[1])"
@title Office Scrubber %uivr%
goto :eof

:slmgr
if exist "%SysPath%\spp\store_test\2.0\tokens.dat" (
echo.
echo Refresh Windows Insider Preview Licenses . . .
%_cscript% //B %SysPath%\slmgr.vbs /rilc %_Nul3%
if !ERRORLEVEL! NEQ 0 %_cscript% //B %SysPath%\slmgr.vbs /rilc %_Nul3%
)
goto :eof

:Fin
for /f %%# in ('"dir /b %SystemRoot%\temp\ose*.exe" %_Nul6%') do taskkill /t /f /IM %%# %_Nul3%
del /f /q "%SystemRoot%\temp\ose*.exe" %_Nul3%
set "msg=Finished. It's recommended to restart the system."
goto :TheEnd

:officeCTR
set _O16CTR=0
set _O15CTR=0
set _O14CTR=0
set _O16UWP=0
set _O16NXT=0
if %_wxp% equ 0 (
if %xOS%==x86 reg.exe query HKLM\SOFTWARE\Microsoft\Office\14.0\CVH /f Click2run /k %_Nul3% && set _O14CTR=1
if not %xOS%==x86 reg.exe query HKLM\SOFTWARE\Wow6432Node\Microsoft\Office\14.0\CVH /f Click2run /k %_Nul3% && set _O14CTR=1
) else (
reg.exe query HKLM\SOFTWARE\Microsoft\Office\14.0\CVH %_Nul2% | findstr /I "Click2run" %_Nul1% && set _O14CTR=1
)
if %winbuild% LSS 7600 goto :eof

:: sc query ClickToRunSvc %_Nul3% && set _O16CTR=1
reg.exe query HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Configuration /v ProductReleaseIds %_Nul3% && (
set _O16CTR=1
for /f "skip=2 tokens=2*" %%a in ('"reg.exe query HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Configuration /v Platform" %_Nul6%') do set "_plat=%%b"
)
if not %xOS%==x86 if %_O16CTR% EQU 0 reg.exe query HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration /v ProductReleaseIds %_Nul3% && (
set _O16CTR=1
for /f "skip=2 tokens=2*" %%a in ('"reg.exe query HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration /v Platform" %_Nul6%') do set "_plat=%%b"
)
if exist "!_file!" set _O16CTR=1
if exist "!_fil2!" if /i "%PROCESSOR_ARCHITECTURE%"=="arm64" set _O16CTR=1
if %_O16CTR% EQU 1 if not defined _plat (
if exist "%ProgramFiles(x86)%\Microsoft Office\Office16\OSPP.VBS" (set "_plat=x86") else (set "_plat=%xBit%")
)

:: sc query OfficeSvc %_Nul3% && set _O15CTR=1
reg.exe query HKLM\SOFTWARE\Microsoft\Office\15.0\ClickToRun /v InstallPath %_Nul3% && (
set _O15CTR=1
)
if %_O15CTR% EQU 0 reg.exe query HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\15.0\ClickToRun /v InstallPath %_Nul3% && (
set _O15CTR=1
)
if %_O15CTR% EQU 0 reg.exe query HKLM\SOFTWARE\Microsoft\Office\15.0\ClickToRun\propertyBag /v productreleaseid %_Nul3% && (
set _O15CTR=1
)
if %_O15CTR% EQU 0 reg.exe query HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\15.0\ClickToRun\propertyBag /v productreleaseid %_Nul3% && (
set _O15CTR=1
)

if %winbuild% GEQ 10240 reg.exe query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msoxmled.exe" %_Nul3% && (
dir /b "%ProgramFiles%\WindowsApps\Microsoft.Office.Desktop*" %_Nul3% && set _O16UWP=1
if not %xOS%==x86 dir /b "%ProgramW6432%\WindowsApps\Microsoft.Office.Desktop*" %_Nul3% && set _O16UWP=1
if not %xOS%==x86 dir /b "%ProgramFiles(x86)%\WindowsApps\Microsoft.Office.Desktop*" %_Nul3% && set _O16UWP=1
)

set kNxt=%kO16%\Common\Licensing\LicensingNext
dir /b /s /a:-d "!_Local!\Microsoft\Office\Licenses\*" %_Nul3% && set _O16NXT=1
dir /b /s /a:-d "!ProgramData!\Microsoft\Office\Licenses\*" %_Nul3% && set _O16NXT=1
reg.exe query %kNxt% %_Nul3% && (
reg.exe query %kNxt% /v MigrationToV5Done %_Nul2% | find /i "0x1" %_Nul1% && set _O16NXT=1
reg.exe query %kNxt% | findstr /i /r ".*retail" %_Nul3% && set _O16NXT=1
reg.exe query %kNxt% | findstr /i /r ".*volume" %_Nul3% && set _O16NXT=1
)

goto :eof

:officeMSI
set _O%1MSI=0
if %winbuild% LSS 7600 (
if %1 EQU 15 goto :eof
if %1 EQU 16 goto :eof
)
for /f "skip=%_sk% tokens=1,2*" %%i in ('"reg.exe query HKLM\SOFTWARE\Microsoft\Office\%1.0\Common\InstallRoot /v Path" %_Nul6%') do (if /i "%%i"=="Path" if not "%%~k"=="" if exist "%%~k\*.dll" set _O%1MSI=1)
if exist "%ProgramFiles%\Microsoft Office\Office%1\*.dll" set _O%1MSI=1
if %xOS%==x86 goto :eof
for /f "skip=2 tokens=2*" %%a in ('"reg.exe query HKLM\SOFTWARE\Wow6432Node\Microsoft\Office\%1.0\Common\InstallRoot /v Path" %_Nul6%') do if exist "%%b\*.dll" set _O%1MSI=1
if exist "%ProgramW6432%\Microsoft Office\Office%1\*.dll" set _O%1MSI=1
if exist "%ProgramFiles(x86)%\Microsoft Office\Office%1\*.dll" set _O%1MSI=1
goto :eof

:officeREG
reg delete HKCU\Software\Microsoft\Office\%1.0 /f
reg delete HKCU\Software\Policies\Microsoft\Office\%1.0 /f
reg delete HKCU\Software\Policies\Microsoft\Cloud\Office\%1.0 /f
reg delete HKLM\SOFTWARE\Microsoft\Office\%1.0 /f
reg delete HKLM\SOFTWARE\Policies\Microsoft\Office\%1.0 /f
reg delete HKLM\SOFTWARE\Microsoft\Office\%1.0 /f /reg:32
reg delete HKLM\SOFTWARE\Policies\Microsoft\Office\%1.0 /f /reg:32
goto :eof

:cK14
if %WMI_VBS% NEQ 0 cd ..
set _spp=OfficeSoftwareProtectionProduct
if %OsppHook% NEQ 0 (
call :cKEY 14
)
if %WMI_VBS% NEQ 0 cd bin
goto :eof

:cKpp
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
if %WMI_VBS% NEQ 0 cd ..
set _spp=SoftwareLicensingProduct
if %winbuild% GEQ 9200 (
reg delete "HKLM\%SPPk%\%_oApp%" /f
reg delete "HKLM\%SPPk%\%_oApp%" /f /reg:32
reg delete "HKU\S-1-5-20\%SPPk%\%_oApp%" /f
for %%A in (15,16,19,21,24) do call :cKEY %%A
)
set _spp=OfficeSoftwareProtectionProduct
if %winbuild% GEQ 9200 if %OsppHook% NEQ 0 (
call :cKEY 14
)
if %winbuild% LSS 9200 if %OsppHook% NEQ 0 (
reg delete "HKLM\%OPPk%\%_oApp%" /f
reg delete "HKLM\%OPPk%\%_oApp%" /f /reg:32
for %%A in (14,15,16,19,21,24) do call :cKEY %%A
)
reg delete "HKLM\%OPPk%\%_oA14%" /f
reg delete "HKU\S-1-5-20\%OPPk%" /f
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
echo Cleaning vNext Licenses . . .
%_Nul3% call :vNextDir
%_Nul3% call :vNextREG
set "msg=Done."
goto :TheEnd

:KeysU
call :Hdr
echo.
echo Uninstalling Product Keys . . .
for %%A in (15,16,19,21,24) do call :cKpp %%A
set "msg=Done."
goto :TheEnd

:LcnsR
call :Hdr
call :cSPP
set "msg=Done."
goto :TheEnd

:LcnsT
call :Hdr
echo.
echo Resetting Office C2R Licenses . . .
if %_O16CTR% equ 0 (
set "msg=ERROR: No installed Office ClickToRun detected."
goto :TheEnd
)
set "_InstallRoot="
for /f "skip=2 tokens=2*" %%a in ('"reg.exe query HKLM\SOFTWARE\Microsoft\Office\ClickToRun /v InstallPath" %_Nul6%') do (set "_InstallRoot=%%b\root")
if not "%_InstallRoot%"=="" (
  for /f "skip=2 tokens=2*" %%a in ('"reg.exe query HKLM\SOFTWARE\Microsoft\Office\ClickToRun /v PackageGUID" %_Nul6%') do (set "_GUID=%%b")
  set "_PRIDs=HKLM\SOFTWARE\Microsoft\Office\ClickToRun\ProductReleaseIDs"
) else (
  for /f "skip=2 tokens=2*" %%a in ('"reg.exe query HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun /v InstallPath" %_Nul6%') do (set "_InstallRoot=%%b\root")
  for /f "skip=2 tokens=2*" %%a in ('"reg.exe query HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun /v PackageGUID" %_Nul6%') do (set "_GUID=%%b")
  set "_PRIDs=HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\ProductReleaseIDs"
)
set "_Integrator=%_InstallRoot%\integration\integrator.exe"
for /f "skip=2 tokens=2*" %%a in ('"reg.exe query %_PRIDs% /v ActiveConfiguration" %_Nul6%') do set "_PRIDs=%_PRIDs%\%%b"
if not exist "%_Integrator%" (
set "msg=ERROR: Could not detect Office Licenses Integrator.exe"
goto :TheEnd
)
for /f "tokens=8 delims=\" %%a in ('reg.exe query "%_PRIDs%" /f ".16" /k %_Nul6% ^| find /i "ClickToRun"') do (
if not defined _SKUs (set "_SKUs=%%a") else (set "_SKUs=!_SKUs!,%%a")
)
if not defined _SKUs (
set "msg=ERROR: Could not detect originally installed Office Products."
goto :TheEnd
)
call :cSPP
echo.
echo Installing Office C2R Licenses . . .
for %%a in (%_SKUs%) do (
"!_Integrator!" /R /License PRIDName=%%a.16 PackageGUID="%_GUID%" PackageRoot="!_InstallRoot!" %_Nul1%
)
set "msg=Done."
goto :TheEnd

:E_Admin
echo %_err%
echo This script requires administrator privileges.
echo To do so, right-click on this script and select 'Run as administrator'
goto :E_Exit

:E_VBS
echo %_err%
echo VBScript engine is not installed.
echo It is required for this script to work.
goto :E_Exit

:E_WSH
echo %_err%
echo Windows Script Host is disabled.
echo It is required for this script to work.
goto :E_Exit

:TheEnd
echo.
echo %_ln%
echo %msg%
:E_Exit
if %Unattend% EQU 1 goto :eof
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