<!-- : Begin batch script
@setlocal DisableDelayedExpansion
@set uivr=v14-aio
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
if /i "%PROCESSOR_ARCHITECTURE%"=="amd64" set "xBit=x64"&set "xOS=x64"
if /i "%PROCESSOR_ARCHITECTURE%"=="arm64" set "xBit=x86"&set "xOS=A64"
if /i "%PROCESSOR_ARCHITECTURE%"=="x86" if "%PROCESSOR_ARCHITEW6432%"=="" set "xBit=x86"&set "xOS=x86"
if /i "%PROCESSOR_ARCHITEW6432%"=="amd64" set "xBit=x64"&set "xOS=x64"
if /i "%PROCESSOR_ARCHITEW6432%"=="arm64" set "xBit=x86"&set "xOS=A64"

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

reg query HKLM\SYSTEM\CurrentControlSet\Services\WinMgmt /v Start 2>nul | find /i "0x4" 1>nul && (goto :E_WMS)

set _cwmi=0
for %%# in (wmic.exe) do @if not "%%~$PATH:#"=="" (
cmd /c "wmic path Win32_ComputerSystem get CreationClassName /value" 2>nul | find /i "ComputerSystem" 1>nul && set _cwmi=1
)

if not defined qerel if not defined _elev (
echo.
echo Checking Windows Powershell, please wait . . .
)
set _pwsh=1
for %%# in (powershell.exe) do @if "%%~$PATH:#"=="" set _pwsh=0
2>nul %_psc% $ExecutionContext.SessionState.LanguageMode | find /i "Full" 1>nul || set _pwsh=0
@cls
if %_pwsh% equ 0 goto :E_PWS

if %_leg% equ 1 goto :Passed

1>nul 2>nul reg.exe query HKU\S-1-5-19 && (
  goto :Passed
  ) || (
  if defined _elev goto :E_Admin
)

set "_batf=%~f0"
set "_ttemp=%userprofile%\AppData\Local\Temp"
cmd /v:on /c echo(^^!_batf^^!| cmd /v:on /c find /i "!_ttemp!" 1>nul 2>nul
if %errorlevel% EQU 0 goto :E_Arv

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
if %xOS%==A64 %_psc% $env:PROCESSOR_ARCHITECTURE 2>nul | find /i "x86" 1>nul && goto :skipQE
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
set "_Common=%CommonProgramFiles%"
if defined PROCESSOR_ARCHITEW6432 set "_Common=%CommonProgramW6432%"
set "_file=%_Common%\Microsoft Shared\ClickToRun\OfficeClickToRun.exe"
set "_fil2=%CommonProgramFiles(x86)%\Microsoft Shared\ClickToRun\OfficeClickToRun.exe"
set "_cscript=cscript //Nologo"
set kO16=HKCU\SOFTWARE\Microsoft\Office\16.0
set kCTR=HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Configuration
set "_Local=%LocalAppData%"
set "_work=%~dp0"
set "_work=%_work:~0,-1%"
setlocal EnableDelayedExpansion
pushd "!_work!"
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

if %Unattend% EQU 1 (
call :getCAB
if not exist "bin\OffScrub*.vbs" goto :E_CAB
)
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
if not "%_er%"=="1" (
call :getCAB
if not exist "bin\OffScrub*.vbs" goto :E_CAB
)
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
if "%_er%"=="1" (
call :getCAB
if not exist "bin\OffScrub*.vbs" goto :E_CAB
goto :sOALL
)
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
%_cscript% bin\OffScrubC2R.vbs ALL /OFFLINE
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
%_cscript% bin\OffScrub_O16msi.vbs %_para%
%_Nul3% call :officeREG 16
goto :eof

:rOM15
echo.
echo Scrubbing Office 2013 MSI . . .
call :cKpp 15
%_cscript% bin\OffScrub_O15msi.vbs %_para%
%_Nul3% call :officeREG 15
goto :eof

:rOM14
echo.
echo Scrubbing Office 2010 . . .
call :cK14
%_cscript% bin\OffScrub10.vbs %_para%
%_Nul3% call :officeREG 14
goto :eof

:rOM12
echo.
echo Scrubbing Office 2007 . . .
%_cscript% bin\OffScrub07.vbs %_para%
%_Nul3% call :officeREG 12
goto :eof

:rOM11
echo.
echo Scrubbing Office 2003 . . .
%_cscript% bin\OffScrub03.vbs %_para%
%_Nul3% call :officeREG 11
goto :eof

:cSPP
echo.
echo Removing Office Licenses . . .
call :getCAB
if not exist "bin\CleanOffice.txt" goto :E_CAB
%_Nul3% %_psc% "cd -Lit ($env:__CD__); $f=[IO.File]::ReadAllText('.\bin\CleanOffice.txt') -split ':embed\:.*'; iex ($f[1])"
@title Office Scrubber %uivr%
call :slmgr
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
reg.exe query %kCTR% /v ProductReleaseIds %_Nul3% && (
set _O16CTR=1
for /f "skip=2 tokens=2*" %%a in ('"reg.exe query %kCTR% /v Platform" %_Nul6%') do set "_plat=%%b"
)
if not %xOS%==x86 if %_O16CTR% EQU 0 reg.exe query %kCTR% /v ProductReleaseIds /reg:32 %_Nul3% && (
set _O16CTR=1
for /f "skip=2 tokens=2*" %%a in ('"reg.exe query %kCTR% /v Platform /reg:32" %_Nul6%') do set "_plat=%%b"
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

if %winbuild% GEQ 10240 (
dir /b "%ProgramData%\Packages\Microsoft.Office.Desktop*" %_Nul3% && set _O16UWP=1
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
reg.exe delete HKCU\Software\Microsoft\Office\%1.0 /f
reg.exe delete HKCU\Software\Policies\Microsoft\Office\%1.0 /f
reg.exe delete HKCU\Software\Policies\Microsoft\Cloud\Office\%1.0 /f
reg.exe delete HKLM\SOFTWARE\Microsoft\Office\%1.0 /f
reg.exe delete HKLM\SOFTWARE\Policies\Microsoft\Office\%1.0 /f
reg.exe delete HKLM\SOFTWARE\Policies\Microsoft\Cloud\Office\%1.0 /f
reg.exe delete HKLM\SOFTWARE\Microsoft\Office\%1.0 /f /reg:32
reg.exe delete HKLM\SOFTWARE\Policies\Microsoft\Office\%1.0 /f /reg:32
reg.exe delete HKLM\SOFTWARE\Policies\Microsoft\Cloud\Office\%1.0 /f /reg:32
goto :eof

:cK14
set _spp=OfficeSoftwareProtectionProduct
if %OsppHook% NEQ 0 (
call :cKEY 14
)
goto :eof

:cKpp
set _spp=SoftwareLicensingProduct
if %winbuild% GEQ 9200 (
call :cKEY %1
)
set _spp=OfficeSoftwareProtectionProduct
if %winbuild% LSS 9200 if %OsppHook% NEQ 0 (
call :cKEY %1
)
goto :eof

:cKMS
set _spp=SoftwareLicensingProduct
if %winbuild% GEQ 9200 (
reg.exe delete "HKLM\%SPPk%\%_oApp%" /f
reg.exe delete "HKLM\%SPPk%\%_oApp%" /f /reg:32
reg.exe delete "HKU\S-1-5-20\%SPPk%\%_oApp%" /f
reg.exe delete "HKU\S-1-5-20\%SPPk%\Policies\%_oApp%" /f
for %%A in (15,16,19,21,24) do call :cKEY %%A
)
set _spp=OfficeSoftwareProtectionProduct
if %winbuild% GEQ 9200 if %OsppHook% NEQ 0 (
call :cKEY 14
)
if %winbuild% LSS 9200 if %OsppHook% NEQ 0 (
reg.exe delete "HKLM\%OPPk%\%_oApp%" /f
reg.exe delete "HKLM\%OPPk%\%_oApp%" /f /reg:32
for %%A in (14,15,16,19,21,24) do call :cKEY %%A
)
reg.exe delete "HKLM\%OPPk%\%_oA14%" /f
reg.exe delete "HKU\S-1-5-20\%OPPk%" /f
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
attrib -R "!ProgramData!\Microsoft\Licenses"
attrib -R "!_Local!\Microsoft\Office\Licenses"
attrib -R "!_Local!\Microsoft\Office\16.0\Licensing"
attrib -R "!_Local!\Microsoft\IdentityCache"
attrib -R "!_Local!\Microsoft\OneAuth"
rmdir /s /q "!ProgramData!\Microsoft\Office\Licenses\"
rmdir /s /q "!ProgramData!\Microsoft\Licenses\"
rmdir /s /q "!_Local!\Microsoft\Office\Licenses\"
rmdir /s /q "!_Local!\Microsoft\Office\16.0\Licensing\"
rmdir /s /q "!_Local!\Microsoft\IdentityCache\"
rmdir /s /q "!_Local!\Microsoft\OneAuth\"
goto :eof

:vNextREG
reg.exe delete "HKU\S-1-5-20\%SPPk%\Policies\%_oApp%" /f
reg.exe delete "%kO16%\Common\Licensing" /f
reg.exe delete "%kO16%\Common\Identity" /f
reg.exe delete "%kO16%\Registration" /f
reg.exe delete "%kCTR%" /f /v SharedComputerLicensing
reg.exe delete "%kCTR%" /f /v productkeys
for /f %%# in ('reg.exe query "%kCTR%" /f *.EmailAddress ^| findstr REG_') do reg.exe delete "%kCTR%" /f /v %%#
for /f %%# in ('reg.exe query "%kCTR%" /f *.TenantId ^| findstr REG_') do reg.exe delete "%kCTR%" /f /v %%#
for /f %%# in ('reg.exe query "%kCTR%" /f *.DeviceBasedLicensing ^| findstr REG_') do reg.exe delete "%kCTR%" /f /v %%#
reg.exe delete HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Updates /f
reg.exe delete HKLM\SOFTWARE\Microsoft\Office\16.0\Common\OEM /f
reg.exe delete HKLM\SOFTWARE\Microsoft\Office\16.0\Common\Licensing /f
reg.exe delete HKLM\SOFTWARE\Policies\Microsoft\Office\16.0\Common\Licensing /f
reg.exe delete HKLM\SOFTWARE\Microsoft\Office\16.0\Common\OEM /f /reg:32
reg.exe delete HKLM\SOFTWARE\Microsoft\Office\16.0\Common\Licensing /f /reg:32
reg.exe delete HKLM\SOFTWARE\Policies\Microsoft\Office\16.0\Common\Licensing /f /reg:32
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

:getCAB
if exist "bin\OffScrub*.vbs" if exist "bin\CleanOffice.txt" goto :eof
set "1=%~n0.cab" &set "0=%~f0" &%_psc% $f=[IO.File]::ReadAllText($env:0) -split ':embdbin\:.*';iex($f[1])
@title Office Scrubber %uivr%
if exist "bin\OffScrub*.vbs" if exist "bin\CleanOffice.txt" set embedded=1
goto :eof

:embdbin:
cd -Lit ($env:__CD__); [IO.File]::WriteAllBytes($env:1, ([Convert]::FromBase64String($f[2]))); expand -R $env:1 -F:* . >$nul; del $env:1 -force
:embdbin:
TVNDRgAAAAAPOwEAAAAAACwAAAAAAAAAAwEBAAcAAAAAAAAALQEAAEkAAxX5BAAA
AAAAAAAAJ1drOCAAYmluXENsZWFuT2ZmaWNlLnR4dADeuwUA+QQAAAAAFlvbeCAA
YmluXE9mZlNjcnViMDMudmJzAAQoBgDXwAUAAABpWDd5IABiaW5cT2ZmU2NydWIw
Ny52YnMAmqUGANvoCwAAAGlYOHkgAGJpblxPZmZTY3J1YjEwLnZicwCuIgUAdY4S
AAAAaVg4eSAAYmluXE9mZlNjcnViQzJSLnZicwDSQAYAI7EXAAAAaVg3eSAAYmlu
XE9mZlNjcnViX08xNW1zaS52YnMATIEGAPXxHQAAAGlYN3kgAGJpblxPZmZTY3J1
Yl9PMTZtc2kudmJzAApG1w9EGgCAW4CAjf0hNatZHnJSVEVQMwCAYAD4ifTewwsH
9xDjTzD27Wdn3a2y9f3/W+/ZOWXe9b43u5Kd2UuTbJx3Y522ZL3NLNm+vE2S3Jwg
6GKADiCfAb8YhjgICCuKK47gimKqLjiCIfECQ0UxPjEQBFJDRUczCUhpABgH/5rb
bn5qvM0tr6gqMQGRFQVPZlWyq56MzGJWzT/p1WiTOSkmKaqb7OqRyXucSLbkv0eT
2XxixJ6F93quj3Fz9CarnMz9Y3Gq5+gepz1upuI4R+O4L95THMWL8RaiWIuf3lhi
8N9+hMGPN5ZfC07tybvgcWpOVQHfn3ZiAMBfelWAv3otUACITwqw+Av4jBcKe8Qv
4rD+IQKMjNHQAGISAP/ub1/Xs6dvnqU3l9wsrrkjmZufbrfy9rbcveXMzJnJM5M7
Ozs7kSQcx69zsa3Yxhvj2waxTUOMGBGA0LBNQvhAEiQxgg2QDyaEfwKCjWFC8vFX
Rz9S31fb//3kV5Y7qumWgz8P/OVwffJJR8mT/3Lli7w6S7dl1Zx63LFb/pYr6qY9
sk8/Zc1ceuOfOhkfbNT2jb+y41c9wrDsHSv//47900O2dxZ3MLHxfFkvvdRTfmS+
C5f/6eW8OmPGjuC2q2rYnlzxU51MXS/Ilh/1e5xNFfFNdE92/YIO6XAm3Nd41De6
5J++gyfuniF7Zdck/+HDMz7k3/2UU2fJlf99v8UP+N7xLbcv+cmxefOOP/i+YD/x
5tf8lzuf+HPTWYfx0+mJiu85/X/wV35X3f7f/SsPvt748bd3fJhV/Ps3N/iRiz25
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
SlPZpNUgKm/LGZPnX57WrwTKHHOVSb98xaw8adD04cXnP7Vsl/r6qiq2Zh+fRElj
N3w2LR8wNzXa129bdm2pjqd95TvZ8CoSCGFZIvXuyarMZ08tTCJ3elabcWk0pV/O
GzL4Urn+lRY3lcfxjhxQWjBx/KU1J6Z9/3kA1bcGeuYhxILnC46UoUJ6hXgUQ2i4
ImHKNBX7ba4szSYKf29Ebu3gBNBcG3mwtrFoJ1gcd2WDhYERYRMiTyMKt16OfTjH
wlaDYnrp4tX/ms68Qk7YHdqbKtAKn73OhzKYWcVBSYhW4SJfXtiBDnuvplRcEKhJ
51UaKqLQFePlUNG6TtZt5qBi/UriR3TV4zrIFFlDZPaldbregJI9WEupd9lAx+WC
nCeZKmbH5ViPmULM0BYdXa/XLNIudqXkEFrO8iO/uHFfnEjpNlK6WUCdhGmJGBVM
i2ZoiUbH4ailO4aL7WiUpPolkJqFrzjBsw95wSLyMEiSTj1vsnSh2XfHSBVNZYRS
CDhXsq6irxRYG4XbUYah2xCKppFpRJ+YO478R0qrMReAop/uujHFOa8kJKhMq95Y
FZ1HCRGRmku7yVynIZcqqSZVR09nOirCcUnJlTlae0ftOncb/Sri2sT4139pw/4J
JQ49gYmSn8mRFW2mKll7uSGPZSGWYDaMkNyxtdvzy/VTVYBBRXLowvHKZlCVnhv6
yF/1rafFcNRCqk3310azleTv0qbdtNnzCjq1ykJrt+s1ntiK64GXrVIoROH1dlyB
6ujpTMrEaqbXxitwFKuWt8QEs2TZCK/LHeEgQvh5xPPxm/EMnyT3Hmh5NKvQ+yxH
FUya66loE6z4gspQN8O5jcvt42x0t4L7CPw0WY7YS3BUU+uTX5behE7CwrGOXaHn
arPLzSfehKNK61CUZqwjSqPNepILlFscSZ7yj1RwcwTJLsiRNKal7EwRMs2pUEmj
dtx1lUAdok8elGWdXDehGi1cBqi8NBpTRcNRK8yiJd4h7sDzcBWPD+XSwRQraJBp
VanY5E/M9HXZd7X1XbejI3uz3dAk4i2SU0K8RciTtX6aPpij+Y+RKglFytMJD9da
pc7lo7osmZKyMjFHvCR1XEJRHJLVTGtUy10kCqcTtWUqxGX/nIFZvCoVWSTyrzMi
KljYfAVJybFk8BjFrCdKL2yrTZiddnjlYXXPzk6yG/fuDj89hP87advHX6swqaiX
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
RADQIxnQMVMWjrAPsADu
:embdbin:

:E_Admin
echo %_err%
echo This script requires administrator privileges.
echo To do so, right-click on this script and select 'Run as administrator'
goto :E_Exit

:E_PWS
echo %_err%
echo Windows PowerShell is not installed or not working properly.
echo It is required for this script to work.
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

:E_WMS
echo %_err%
echo Windows Management Instrumentation [WinMgmt] service is disabled.
echo It is required for this script to work.
goto :E_Exit

:E_Arv
echo %_err%
echo The script was launched from the temp folder.
echo.
echo You are most likely running the script directly from the archive file.
echo Extract the archive file and launch the script from the extracted folder.
goto :E_Exit

:E_CAB
echo %_err%
echo Failed to extract embedded binary files.
echo Temporary suspend Antivirus protection if any, or exclude the current folder.
goto :E_Exit

:TheEnd
echo.
echo %_ln%
echo %msg%
:E_Exit
if defined embedded if exist "!_work!\bin\OffScrub*.vbs" rmdir /s /q "!_work!\bin\" 1>nul 2>nul
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