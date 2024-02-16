<!-- : Begin batch script
@setlocal DisableDelayedExpansion
@set uivr=v100
@echo off
:: Change to 1 to enable debug mode
set _Debug=0

:: ### Auto processing option ###
:: 1 - create ISO with install.wim
:: 2 - create ISO with install.esd
:: 3 - create install.wim only
:: 4 - create install.esd only
set AutoStart=0

:: Change to 1 to integrate updates (if detected) into install.wim/winre.wim
:: Change to 2 to add updates externally to iso distribution
set AddUpdates=0

:: Change to 1 to cleanup images to delta-compress superseded components (Warning: on 18362 and later, this removes the base RTM Edition packages)
set Cleanup=0

:: Change to 1 to rebase image and remove superseded components (faster than default delta-compress)
:: require first to set Cleanup=1
set ResetBase=0

:: Change to 1 to enable .NET 3.5 feature with updates
set NetFx3=0

:: Change to 1 to start create_virtual_editions.cmd directly after conversion
set StartVirtual=0

:: Change to 1 to convert install.wim to install.esd
set wim2esd=0

:: Change to 1 to split install.wim into multiple install.swm
:: note: if both options are 1, install.esd takes precedence
set wim2swm=0

:: Change to 1 for not creating ISO file, result distribution folder will be kept
set SkipISO=0

:: Change to 1 for not adding winre.wim into install.wim/install.esd
set SkipWinRE=0

:: Change to 1 to force updating winre.wim with Cumulative Update regardless if SafeOS update detected
:: auto enabled for builds 22000 and later, change to 2 to disable
set LCUwinre=0

:: Change to 1 to disable updating process optimization by using editions upgrade (Home>Pro / ServerStandard>ServerDatacenter)
:: auto enabled for builds 26000 and later, change to 2 to disable
set DisableUpdatingUpgrade=0

:: Change to 1 to update ISO boot files bootmgr/memtest/efisys.bin from Cumulative Update
set UpdtBootFiles=0

:: Change to 1 to use dism.exe for creating boot.wim
set ForceDism=0

:: Change to 1 to keep converted Reference ESDs
set RefESD=0

:: Change to 1 to skip creating Cumulative Update MSU for builds 21382 - 25330
set SkipLCUmsu=0

:: Change to 1 for not integrating EdgeChromium with Enablement Package or Cumulative Update
:: Change to 2 for alternative workaround to avoid EdgeChromium with Cumulative Update only
set SkipEdge=0

:: Change to 1 to exit the process on completion without prompt
set AutoExit=0

:: ### Drivers Options ###

:: Change to 1 to add drivers to install.wim and boot.wim / winre.wim
set AddDrivers=0

:: custom folder path for drivers - default is "Drivers" folder next to the script
:: the folder must contain subfolder for each drivers target:
:: ALL   / drivers will be added to all wim files
:: OS    / drivers will be added to install.wim only
:: WinPE / drivers will be added to boot.wim / winre.wim only
set "Drv_Source=\Drivers"

:: ### Store Apps for builds 22563 and later ###

:: Change to 1 for not integrating store apps into install.wim
set SkipApps=0

:: # Control added Apps for Client editions (except Team)
:: 0 / all referenced Apps
:: 1 / only Store, Security Health
:: 2 / level 1 + Photos, Camera, Notepad, Paint
:: 3 / level 2 + Terminal, App Installer, Widgets, Mail
:: 4 / level 3 + Media apps (Music, Video, Codecs, Phone Link) / not for N editions
set AppsLevel=0

:: # Control preference for Apps which are available as stubs
:: 0 / install as stub app
:: 1 / install as full app
set StubAppsFull=0

:: Enable using CustomAppsList.txt or CustomAppsList2.txt to pick and choose added Apps (takes precedence over AppsLevel)
:: CustomAppsList2.txt will be used if detected
set CustomList=0

:: ###################################################################

set DeleteSource=0

set "_Null=1>nul 2>nul"
set DisableWimRebuilds=0
set "_wrb="
if %DisableWimRebuilds% equ 1 set "_wrb=rem."

set _UUP=
set qerel=
set _elev=
set "_args="
set "_args=%~1"
if not defined _args goto :NoProgArgs
if "%~1"=="" set "_args="&goto :NoProgArgs
set "_args="
for %%# in (%*) do (
if /i "%%~#"=="-elevated" (set _elev=1
) else if /i "%%~#"=="-qedit" (set qerel=1
) else (set "_args=%%~#")
)

:NoProgArgs
@color 07
set "xOS=amd64"
if /i "%PROCESSOR_ARCHITECTURE%"=="arm64" set "xOS=arm64"
if /i "%PROCESSOR_ARCHITECTURE%"=="x86" if "%PROCESSOR_ARCHITEW6432%"=="" set "xOS=x86"
if /i "%PROCESSOR_ARCHITEW6432%"=="amd64" set "xOS=amd64"
if /i "%PROCESSOR_ARCHITEW6432%"=="arm64" set "xOS=arm64"
set "xDS=bin\bin64;bin;temp"
if /i not %xOS%==amd64 set "xDS=bin;temp"
set "SysPath=%SystemRoot%\System32"
set "Path=%xDS%;%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
if exist "%SystemRoot%\Sysnative\reg.exe" (
set "SysPath=%SystemRoot%\Sysnative"
set "Path=%xDS%;%SystemRoot%\Sysnative;%SystemRoot%\Sysnative\Wbem;%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\;%Path%"
)
set "_err=echo: &echo ==== ERROR ===="
set "_psc=powershell -nop -c"
set winbuild=1
for /f "tokens=6 delims=[]. " %%# in ('ver') do set winbuild=%%#
set _cwmi=0
for %%# in (wmic.exe) do @if not "%%~$PATH:#"=="" (
wmic path Win32_ComputerSystem get CreationClassName /value 2>nul | find /i "ComputerSystem" 1>nul && set _cwmi=1
)
set _pwsh=1
for %%# in (powershell.exe) do @if "%%~$PATH:#"=="" set _pwsh=0
if not exist "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" set _pwsh=0
call :pr_color
if %_cwmi% equ 0 if %_pwsh% EQU 0 goto :E_PWS

set _uac=-elevated
%_Null% reg.exe query HKU\S-1-5-19 && (
  goto :Passed
  ) || (
  if defined _elev goto :E_Admin
)

set _PSarg="""%~f0""" %_uac%
if defined _args set _PSarg="""%~f0""" """%_args%""" %_uac%
set _PSarg=%_PSarg:'=''%

(%_Null% cscript //NoLogo "%~f0?.wsf" //job:ELAV /File:"%~f0" %* %_uac%) && (
  exit /b
  ) || (
  call setlocal EnableDelayedExpansion
  %_Null% %_psc% "start cmd.exe -Arg '/c \"!_PSarg!\"' -verb runas" && (
    exit /b
    ) || (
    goto :E_Admin
  )
)

:Passed
if %winbuild% LSS 10586 (
reg.exe query HKCU\Console /v QuickEdit 2>nul | find /i "0x0" >nul && set qerel=1
)
if defined qerel goto :skipQE
if %_pwsh% EQU 0 goto :skipQE
set _PSarg="""%~f0""" -qedit
if defined _args set _PSarg="""%~f0""" """%_args%""" -qedit
set _PSarg=%_PSarg:'=''%
set "d1=$t=[AppDomain]::CurrentDomain.DefineDynamicAssembly(4, 1).DefineDynamicModule(2, $False).DefineType(0);"
set "d2=$t.DefinePInvokeMethod('GetStdHandle', 'kernel32.dll', 22, 1, [IntPtr], @([Int32]), 1, 3).SetImplementationFlags(128);"
set "d3=$t.DefinePInvokeMethod('SetConsoleMode', 'kernel32.dll', 22, 1, [Boolean], @([IntPtr], [Int32]), 1, 3).SetImplementationFlags(128);"
set "d4=$k=$t.CreateType(); $b=$k::SetConsoleMode($k::GetStdHandle(-10), 0x0080);"
setlocal EnableDelayedExpansion
%_psc% "!d1! !d2! !d3! !d4! & cmd.exe '/c' '!_PSarg!'" &exit /b
exit /b

:skipQE
set "logerr=%~dp0ErrorLog_%random%.txt"
set "_batf=%~f0"
set "_log=%~dpn0"
set "_work=%~dp0"
set "_work=%_work:~0,-1%"
set _drv=%~d0
set "_cabdir=%_drv%\W10UIuup"
set _UNC=0
if "%_work:~0,2%"=="\\" (
set _UNC=1
) else (
net use %_drv% %_Null%
if not errorlevel 1 set _UNC=1
)
if %_UNC% EQU 1 set "_cabdir=%~dp0temp\W10UIuup"
for /f "skip=2 tokens=2*" %%a in ('reg.exe query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop') do call set "_dsk=%%b"
if exist "%PUBLIC%\Desktop\desktop.ini" set "_dsk=%PUBLIC%\Desktop"
call :preVars
setlocal EnableDelayedExpansion
if exist "!_work!\UUPs\*.esd" set "_UUP=!_work!\UUPs"
if defined _args if exist "!_args!\*.esd" set "_UUP=!_args!"

if %_Debug% equ 0 (
  set "_Nul1=1>nul"
  set "_Nul2=2>nul"
  set "_Nul6=2^>nul"
  set "_Nul3=1>nul 2>nul"
  set "_Pause=pause >nul"
  set "_Contn=echo Press any key to continue..."
  set "_Exit=echo Press any key to exit."
  set "_Supp="
  goto :Begin
)
  set "_Nul1="
  set "_Nul2="
  set "_Nul6="
  set "_Nul3="
  set "_Pause=rem."
  set "_Contn=rem."
  set "_Exit=rem."
  set "_Supp=1>nul"
copy /y nul "!_work!\#.rw" %_Null% && (if exist "!_work!\#.rw" del /f /q "!_work!\#.rw") || (set "_log=!_dsk!\%~n0")
echo.
echo Running in Debug Mode...
echo The window will be closed when finished
@echo on
@prompt $G
@call :Begin >"!_log!_tmp.log" 2>&1 &cmd /u /c type "!_log!_tmp.log">"!_log!_Debug.log"&del /f /q "!_log!_tmp.log"
@color 07
@title %ComSpec%
@exit /b

:Begin
title UUP -^> ISO %uivr%
set "_dLog=%SystemRoot%\Logs\DISM"
call :checkadk
set W10UI=0
if %winbuild% geq 10240 (
set W10UI=1
) else (
if %_ADK% equ 1 set W10UI=1
)
call :postVars
if defined _UUP goto :check
if %_Debug% neq 0 goto :check
setlocal DisableDelayedExpansion

:prompt
@cls
set _UUP=
echo.
echo Enter the path to UUP source directory
echo %_ln1%
echo.
set /p _UUP=
if not defined _UUP set _Debug=1&goto :QUIT
set "_UUP=%_UUP:"=%"
if "%_UUP:~-1%"=="\" set "_UUP=%_UUP:~0,-1%"
if not exist "%_UUP%\*.esd" (
%_err%
echo Specified path is not a valid UUP source
echo.
%_Contn%&%_Pause%
goto :prompt
)
setlocal EnableDelayedExpansion

:check
if %_Debug% neq 0 (
if defined _args echo "!_args!"
echo "!_work!"
)
pushd "!_work!"
set _fils=(7z.dll,7z.exe,bcdedit.exe,bfi.exe,bootmui.txt,bootwim.txt,cdimage.exe,imagex.exe,libwim-15.dll,offlinereg.exe,offreg.dll,wimlib-imagex.exe,PSFExtractor.exe,cabarc.exe)
for %%# in %_fils% do (
if not exist ".\bin\%%#" (set _bin=%%#&goto :E_Bin)
)
if not defined _UUP (
(echo.&echo UUP source directory is not specified, or valid)>>"!logerr!"
exit /b
)
if not exist "ConvertConfig.ini" goto :proceed
findstr /i \[convert-UUP\] ConvertConfig.ini %_Nul1% || goto :proceed
for %%# in (
AutoStart
AddUpdates
Cleanup
ResetBase
NetFx3
StartVirtual
SkipISO
SkipWinRE
LCUwinre
DisableUpdatingUpgrade
UpdtBootFiles
wim2esd
wim2swm
ForceDism
RefESD
SkipLCUmsu
SkipEdge
AutoExit
AddDrivers
Drv_Source
SkipApps
AppsLevel
StubAppsFull
CustomList
) do (
call :ReadINI %%#
)
findstr /b /i vDeleteSource ConvertConfig.ini %_Nul1% && for /f "tokens=2 delims==" %%# in ('findstr /b /i vDeleteSource ConvertConfig.ini') do set "DeleteSource=%%#"
goto :proceed

:ReadINI
findstr /b /i %1 ConvertConfig.ini %_Nul1% && for /f "tokens=2 delims==" %%# in ('findstr /b /i %1 ConvertConfig.ini') do set "%1=%%#"
goto :eof

:proceed
:: @color 1F
echo.
echo === Detecting UUP editions files
echo.
if %_Debug% neq 0 (
if %AutoStart% equ 0 set AutoStart=2
)
set _configured=0
if exist bin\temp\ rmdir /s /q bin\temp\
if exist temp\ rmdir /s /q temp\
if exist bin\expand.exe if not exist bin\dpx.dll del /f /q bin\expand.exe
mkdir bin\temp
mkdir temp
if %CustomList% neq 0 if exist "CustomAppsList*.txt" set _appsCustom=1
set _updexist=0
if exist "!_UUP!\*Windows1*-KB*.msu" set _updexist=1
if exist "!_UUP!\*Windows1*-KB*.cab" set _updexist=1
if exist "!_UUP!\SSU-*-*.cab" set _updexist=1
set _pmcppc=0
if exist "!_UUP!\*Microsoft-Windows-Printing-PMCPPC-FoD-Package*.cab" set _pmcppc=1
if exist "!_UUP!\*Microsoft-Windows-Printing-PMCPPC-FoD-Package*.esd" set _pmcppc=1
dir /b /ad "!_UUP!\*Package*" %_Nul3% && set EXPRESS=1
if "!Drv_Source!"=="\Drivers" set "Drv_Source=!_work!\Drivers"
set "DrvSrcALL="
set "DrvSrcOS="
set "DrvSrcPE="
if %AddDrivers% neq 0 if %W10UI% neq 0 if exist "!Drv_Source!\" (
pushd "!Drv_Source!"
if exist ALL\ dir /b /s "ALL\*.inf" %_Nul3% && set "DrvSrcALL=!Drv_Source!\ALL"
if exist OS\ dir /b /s "OS\*.inf" %_Nul3% && set "DrvSrcOS=!Drv_Source!\OS"
if exist WinPE\ dir /b /s "WinPE\*.inf" %_Nul3% && set "DrvSrcPE=!Drv_Source!\WinPE"
popd
)
for %%# in (
Core,CoreN,CoreSingleLanguage,CoreCountrySpecific
Professional,ProfessionalN,ProfessionalEducation,ProfessionalEducationN,ProfessionalWorkstation,ProfessionalWorkstationN
Education,EducationN,Enterprise,EnterpriseN,EnterpriseG,EnterpriseGN,EnterpriseS,EnterpriseSN,ServerRdsh
PPIPro,IoTEnterprise,IoTEnterpriseK,IoTEnterpriseS,IoTEnterpriseSK
Cloud,CloudN,CloudE,CloudEN,CloudEdition,CloudEditionN,CloudEditionL,CloudEditionLN
Starter,StarterN,ProfessionalCountrySpecific,ProfessionalSingleLanguage
ServerStandardCore,ServerStandard,ServerDatacenterCore,ServerDatacenter,ServerTurbineCore,ServerTurbine,ServerAzureStackHCICor
WNC
) do (
if exist "!_UUP!\%%#_*.esd" (dir /b /a:-d "!_UUP!\%%#_*.esd">>temp\uups_esd.txt %_Nul2%) else if exist "!_UUP!\MetadataESD_%%#_*.esd" (dir /b /a:-d "!_UUP!\MetadataESD_%%#_*.esd">>temp\uups_esd.txt %_Nul2%)
)
for /f "tokens=3 delims=: " %%# in ('find /v /c "" temp\uups_esd.txt %_Nul6%') do set uups_esd_num=%%#
if %uups_esd_num% equ 0 goto :E_ESD
for /L %%# in (1,1,%uups_esd_num%) do call :uups_esd %%#
if defined eWIMLIB goto :QUIT
if %uups_esd_num% gtr 1 goto :MULTIMENU
set "MetadataESD=!_UUP!\%uups_esd1%"&set "_flg=%edition1%"&set "arch=%arch1%"&set "langid=%langid1%"&set "editionid=%edition1%"&set "_oName=%_oname1%"&set "_Srvr=%_ESDSrv1%"
goto :MAINMENU

:MULTIMENU
if %AutoStart% equ 1 (set AIO=1&set WIMFILE=install.wim&goto :ISO)
if %AutoStart% equ 2 (set AIO=1&set WIMFILE=install.esd&goto :ISO)
if %AutoStart% equ 3 (set AIO=1&set WIMFILE=install.wim&goto :Single)
if %AutoStart% equ 4 (set AIO=1&set WIMFILE=install.esd&goto :Single)
@cls
set _index=
echo.
echo       UUP source contains multiple editions:
echo %_ln2%
echo.
for /L %%# in (1,1,%uups_esd_num%) do (
echo %%#. !_name%%#!
)
echo %_ln2%
echo.
echo Enter zero '0' to create AIO
echo Enter individual edition number to create solely
echo Enter multiple editions numbers to create, separated with spaces
echo %_ln1%
echo.
set /p _index= ^> Enter your option and press "Enter": 
if not defined _index set _Debug=1&goto :QUIT
if "%_index%"=="0" (set "_tag= AIO"&set "_ta2=AIO"&set AIO=1&goto :MAINMENU)
for %%# in (%_index%) do call :setindex %%#
if %_count% equ 1 for /L %%# in (1,1,%uups_esd_num%) do (
if %_index1% equ %%# set "MetadataESD=!_UUP!\!uups_esd%%#!"&set "_flg=!edition%%#!"&set "arch=!arch%%#!"&set "langid=!langid%%#!"&set "editionid=!edition%%#!"&set "_oName=!_oname%%#!"&set "_Srvr=!_ESDSrv%%#!"&goto :MAINMENU
)
set "_ta2=AIO"
goto :MAINMENU

:setindex
set /a _count+=1
set _index%_count%=%1
goto :eof

:MAINMENU
if %AutoStart% equ 1 (set WIMFILE=install.wim&goto :ISO)
if %AutoStart% equ 2 (set WIMFILE=install.esd&goto :ISO)
if %AutoStart% equ 3 (set WIMFILE=install.wim&goto :Single)
if %AutoStart% equ 4 (set WIMFILE=install.esd&goto :Single)
@cls
set userinp=
echo %_ln2%
echo.
echo.       0 - Exit
echo.       1 - Create%_tag% ISO with install.wim
echo.       2 - Create%_tag% install.wim
echo.       3 - UUP Edition info
if %EXPRESS% equ 0 (
echo.       4 - Create%_tag% ISO with install.esd
echo.       5 - Create%_tag% install.esd
)
echo.       6 - Configuration Options
echo %_ln1%
echo.
set /p userinp= ^> Enter your option and press "Enter": 
if not defined userinp set _Debug=1&goto :QUIT
set userinp=%userinp:~0,1%
if %userinp% equ 0 (set _Debug=1&goto :QUIT)
if %userinp% equ 6 goto :CONFMENU
if %userinp% equ 5 if %EXPRESS% equ 0 (set WIMFILE=install.esd&goto :Single)
if %userinp% equ 4 if %EXPRESS% equ 0 (set WIMFILE=install.esd&goto :ISO)
if %userinp% equ 3 goto :INFO%_ta2%
if %userinp% equ 2 (set WIMFILE=install.wim&goto :Single)
if %userinp% equ 1 (set WIMFILE=install.wim&goto :ISO)
goto :MAINMENU

:CONFMENU
@cls
set userinp=
echo %_ln2%
echo.
echo. 0 - Return to Main Menu
if %_updexist% equ 1 if %W10UI% equ 0 (
if %AddUpdates% equ 2 (echo. 1 - AddUpdates  : Yes {External}) else if %AddUpdates% equ 1 (echo. 1 - AddUpdates  : No  {ADK missing}) else (echo. 1 - AddUpdates  : No)
)
if %_updexist% equ 1 if %W10UI% neq 0 (
if %AddUpdates% equ 2 (echo. 1 - AddUpdates  : Yes {External}) else if %AddUpdates% equ 1 (echo. 1 - AddUpdates  : Yes {Integrate}) else (echo. 1 - AddUpdates  : No)
if %AddUpdates% equ 1 (
  if %Cleanup% equ 0 (echo. 2 - Cleanup     : No) else (if %ResetBase% equ 0 (echo. 2 - Cleanup     : Yes {ResetBase: No}) else (echo. 2 - Cleanup     : Yes {ResetBase: Yes}))
  )
if %AddUpdates% neq 0 (
  if %NetFx3% neq 0 (echo. 3 - NetFx3      : Yes) else (echo. 3 - NetFx3      : No)
  )
)
if %StartVirtual% neq 0 (echo. 4 - StartVirtual: Yes) else (echo. 4 - StartVirtual: No)
if %wim2esd% neq 0 (echo. 5 - WIM2ESD     : Yes) else (if %wim2swm% neq 0 (echo. 5 - WIM2SWM     : Yes) else (echo. 5 - WIM2ESD/SWM : No))
if %SkipISO% neq 0 (echo. 6 - SkipISO     : Yes) else (echo. 6 - SkipISO     : No)
if %SkipWinRE% neq 0 (echo. 7 - SkipWinRE   : Yes) else (echo. 7 - SkipWinRE   : No)
if %W10UI% neq 0 (
if %ForceDism% neq 0 (echo. 8 - ForceDism   : Yes) else (echo. 8 - ForceDism   : No)
)
if %RefESD% neq 0 (echo. 9 - RefESD      : Yes) else (echo. 9 - RefESD      : No)
if %W10UI% neq 0 (
  if %DisableUpdatingUpgrade% neq 0 (echo. U - DisableUpdatingUpgrade: Yes) else (echo. U - DisableUpdatingUpgrade: No)
)
if %_updexist% equ 1 if %W10UI% neq 0 (
if %AddUpdates% equ 1 (
  if %LCUwinre% equ 1 (echo. R - LCUwinre    : Yes) else (echo. R - LCUwinre    : No  {%LCUwinre%})
  if %SkipEdge% neq 0 (echo. E - SkipEdge    : Yes {%SkipEdge%}) else (echo. E - SkipEdge    : No)
  )
)
if %SkipLCUmsu% neq 0 (echo. M - SkipLCUmsu  : Yes) else (echo. M - SkipLCUmsu  : No)
if %W10UI% neq 0 (
  echo.
  if %SkipApps% neq 0 (echo. A - SkipApps    : Yes) else (echo. A - SkipApps    : No)
)
if %W10UI% neq 0 if %SkipApps% equ 0 (
  if %StubAppsFull% neq 0 (echo. S - StubAppsFull: Yes) else (echo. S - StubAppsFull: No)
  if %CustomList% neq 0 (echo. C - CustomList  : Yes) else (echo. C - CustomList  : No)
  echo. L - AppsLevel   : %AppsLevel%
)
echo %_ln1%
echo.
set /p userinp= ^> Enter your option and press "Enter": 
if not defined userinp goto :MAINMENU
set userinp=%userinp:~0,1%
if %userinp%==0 goto :MAINMENU
if /i %userinp%==U (if %W10UI% neq 0 (if %DisableUpdatingUpgrade% equ 0 (set DisableUpdatingUpgrade=1) else (set DisableUpdatingUpgrade=0)))&goto :CONFMENU
if /i %userinp%==L (if %W10UI% neq 0 if %SkipApps% equ 0 (if %AppsLevel% equ 0 (set AppsLevel=1) else if %AppsLevel% equ 1 (set AppsLevel=2) else if %AppsLevel% equ 2 (set AppsLevel=3) else if %AppsLevel% equ 3 (set AppsLevel=4) else (set AppsLevel=0)))&goto :CONFMENU
if /i %userinp%==C (if %W10UI% neq 0 if %SkipApps% equ 0 (if %CustomList% equ 0 (set CustomList=1) else (set CustomList=0)))&goto :CONFMENU
if /i %userinp%==S (if %W10UI% neq 0 if %SkipApps% equ 0 (if %StubAppsFull% equ 0 (set StubAppsFull=1) else (set StubAppsFull=0)))&goto :CONFMENU
if /i %userinp%==A (if %W10UI% neq 0 (if %SkipApps% equ 0 (set SkipApps=1) else (set SkipApps=0)))&goto :CONFMENU
if /i %userinp%==M (if %SkipLCUmsu% equ 0 (set SkipLCUmsu=1) else (set SkipLCUmsu=0))&goto :CONFMENU
if /i %userinp%==E (if %AddUpdates% equ 1 (if %SkipEdge% equ 0 (set SkipEdge=1) else if %SkipEdge% equ 1 (set SkipEdge=2) else (set SkipEdge=0)))&goto :CONFMENU
if /i %userinp%==R (if %AddUpdates% equ 1 (if %LCUwinre% equ 0 (set LCUwinre=1) else if %LCUwinre% equ 1 (set LCUwinre=2) else (set LCUwinre=0)))&goto :CONFMENU
if %userinp%==9 (if %RefESD% equ 0 (set RefESD=1) else (set RefESD=0))&goto :CONFMENU
if %userinp%==8 (if %W10UI% neq 0 (if %ForceDism% equ 0 (set ForceDism=1) else (set ForceDism=0)))&goto :CONFMENU
if %userinp%==7 (if %SkipWinRE% equ 0 (set SkipWinRE=1) else (set SkipWinRE=0))&goto :CONFMENU
if %userinp%==6 (if %SkipISO% equ 0 (set SkipISO=1) else (set SkipISO=0))&goto :CONFMENU
if %userinp%==5 (if %wim2esd% equ 1 (set wim2esd=0) else (set wim2esd=1&if %wim2swm% equ 0 (set wim2swm=1) else (set wim2swm=0)))&goto :CONFMENU
if %userinp%==4 (if %StartVirtual% equ 0 (set StartVirtual=1) else (set StartVirtual=0))&goto :CONFMENU
if %userinp%==3 if %AddUpdates% neq 0 (if %NetFx3% equ 0 (set NetFx3=1) else (set NetFx3=0))&goto :CONFMENU
if %userinp%==2 if %AddUpdates% equ 1 (if %Cleanup% equ 1 (set Cleanup=0) else (set Cleanup=1&if %ResetBase% equ 0 (set ResetBase=1) else (set ResetBase=0)))&goto :CONFMENU
if %userinp%==1 (if %AddUpdates% equ 0 (set AddUpdates=1) else if %AddUpdates% equ 1 (set AddUpdates=2) else (set AddUpdates=0))&goto :CONFMENU
goto :CONFMENU

:ISO
@cls
call :dk_color1 %Gray% "=== Running UUP Converter %uivr% ===" 4 5
call :checkQE
set _initial=1
if %_updexist% equ 0 set AddUpdates=0
if %PREPARED% equ 0 call :PREPARE
if %_IPA% equ 1 if %SkipApps% equ 0 set _runIPA=1
if /i %arch%==arm64 if %winbuild% lss 9600 if %AddUpdates% equ 1 (
if %_build% geq 17763 (set AddUpdates=2) else (set AddUpdates=0)
)
if %Cleanup% equ 0 set ResetBase=0
if %AIO% neq 1 if %_count% leq 1 if /i "%editionid%"=="PPIPro" (set StartVirtual=0)
if %_build% lss 17063 (set StartVirtual=0)
if %_build% lss 17763 if %AddUpdates% equ 2 (set AddUpdates=1)
if %_build% lss 17763 if %AddUpdates% equ 1 if %W10UI% equ 0 (set AddUpdates=0)
if %_build% geq 17763 if %AddUpdates% equ 1 if %W10UI% equ 0 (set AddUpdates=2)
if %_build% lss 17763 if %AddUpdates% equ 1 (set Cleanup=1)
if %_build% geq 22000 (
if %LCUwinre% equ 2 (set LCUwinre=0) else (set LCUwinre=1)
)
if %_build% geq 25380 (
if %Cleanup% equ 0 set DisableUpdatingUpgrade=1
)
if %_build% geq 26000 (
if %DisableUpdatingUpgrade% equ 2 (set DisableUpdatingUpgrade=0) else (set DisableUpdatingUpgrade=1)
)
if %WIMFILE%==install.wim (
if %AddUpdates% neq 1 if %wim2esd% equ 1 (set WIMFILE=install.esd)
)
if %WIMFILE%==install.esd (
set wim2esd=0
if %AddUpdates% equ 1 (set WIMFILE=install.wim&set wim2esd=1)
if %_runIPA% equ 1 (set WIMFILE=install.wim&set wim2esd=1)
)
if %_Debug% neq 0 set wim2esd=0
for %%# in (
AutoStart
AddUpdates
Cleanup
ResetBase
NetFx3
StartVirtual
SkipISO
SkipWinRE
LCUwinre
DisableUpdatingUpgrade
UpdtBootFiles
wim2esd
wim2swm
ForceDism
RefESD
SkipLCUmsu
SkipEdge
AutoExit
AddDrivers
SkipApps
AppsLevel
StubAppsFull
CustomList
DeleteSource
) do (
if !%%#! neq 0 set _configured=1
)
if %_configured% equ 1 (
call :dk_color1 %Blue% "=== Configured Options . . ." 4 5
  if %AutoStart% neq 0 echo AutoStart %AutoStart%
  if %AddUpdates% neq 0 echo AddUpdates %AddUpdates%
  if %AddUpdates% equ 1 (
  if %Cleanup% neq 0 echo Cleanup
  if %Cleanup% neq 0 if %ResetBase% neq 0 echo ResetBase
  if %LCUwinre% neq 0 echo LCUwinre
  if %DisableUpdatingUpgrade% neq 0 echo DisableUpdatingUpgrade
  )
  if %AddUpdates% neq 0 if %NetFx3% neq 0 echo NetFx3
  if %StartVirtual% neq 0 (
  echo StartVirtual
  if %DeleteSource% neq 0 echo DeleteSource
  )
  for %%# in (
  SkipISO
  SkipWinRE
  UpdtBootFiles
  wim2esd
  wim2swm
  ForceDism
  RefESD
  AutoExit
  AddDrivers
  ) do (
  if !%%#! neq 0 echo %%#
  )
)
if %_build% geq 21382 if %SkipLCUmsu% neq 0 echo SkipLCUmsu
if %_build% geq 18362 if %AddUpdates% equ 1 if %SkipEdge% neq 0 echo SkipEdge %SkipEdge%
if %_build% geq 22563 if %W10UI% neq 0 (
if %SkipApps% neq 0 echo SkipApps
if %AppsLevel% neq 0 echo AppsLevel %AppsLevel%
if %StubAppsFull% neq 0 echo StubAppsFull
if %_appsCustom% neq 0 echo CustomAppsList
)
if %_runIPA% equ 1 call :appx_sort
if %_IPA% equ 1 if %SkipApps% equ 1 (
if exist "!_UUP!\*.*xbundle" (call :appx_sort) else if exist "!_UUP!\*.appx" (call :appx_sort)
)
call :uups_ref
call :dk_color1 %Blue% "=== Creating Setup Media Layout . . ." 4
if exist ISOFOLDER\ rmdir /s /q ISOFOLDER\
mkdir ISOFOLDER
wimlib-imagex.exe apply "!MetadataESD!" 1 ISOFOLDER\ --no-acls --no-attributes %_Null%
set ERRTEMP=%ERRORLEVEL%
if %ERRTEMP% neq 0 goto :E_Apply
if exist ISOFOLDER\MediaMeta.xml del /f /q ISOFOLDER\MediaMeta.xml %_Nul3%
:: rmdir /s /q ISOFOLDER\sources\uup\ %_Nul3%
if %_build% geq 18890 (
wimlib-imagex.exe extract "!MetadataESD!" 3 Windows\Boot\Fonts\* --dest-dir=ISOFOLDER\boot\fonts --no-acls --no-attributes %_Nul3%
xcopy /CRY ISOFOLDER\boot\fonts\* ISOFOLDER\efi\microsoft\boot\fonts\ %_Nul3%
)
if %_build% lss 17063 if exist ISOFOLDER\sources\ei.cfg (
if %AIO% equ 1 del /f /q ISOFOLDER\sources\ei.cfg %_Nul3%
if %_count% gtr 1 del /f /q ISOFOLDER\sources\ei.cfg %_Nul3%
)
if %_build% geq 17063 (
if exist "!_UUP!\ei.cfg" (copy /y "!_UUP!\ei.cfg" ISOFOLDER\sources\ei.cfg %_Nul3%) else if exist "ei.cfg" (copy /y "ei.cfg" ISOFOLDER\sources\ei.cfg %_Nul3%) 
if exist "!_UUP!\pid.txt" (copy /y "!_UUP!\pid.txt" ISOFOLDER\sources\pid.txt %_Nul3%) else if exist "pid.txt" (copy /y "pid.txt" ISOFOLDER\sources\pid.txt %_Nul3%) 
)
if %AIO% neq 1 if %_count% leq 1 if /i "%editionid%"=="PPIPro" (
(
echo [PID]
echo Value=XKCNC-J26Q9-KFHD2-FKTHY-KD72Y
)>ISOFOLDER\sources\pid.txt
)
for /f "tokens=5-10 delims=: " %%G in ('wimlib-imagex.exe info "!MetadataESD!" 3 ^| find /i "Last Modification Time"') do (set mmm=%%G&set "isotime=%%H/%%L,%%I:%%J:%%K")
for %%# in (Jan:01 Feb:02 Mar:03 Apr:04 May:05 Jun:06 Jul:07 Aug:08 Sep:09 Oct:10 Nov:11 Dec:12) do for /f "tokens=1,2 delims=:" %%A in ("%%#") do (
if /i %mmm%==%%A set "isotime=%%B/%isotime%"
)
set _file=ISOFOLDER\sources\%WIMFILE%
set _rtrn=RetISO
goto :InstallWim
:RetISO
if %WIMFILE%==install.esd (
set wim2swm=0
if %_Debug% neq 0 set SkipWinRE=1
)
set _rtrn=BakISO
goto :WinreWim
:BakISO
call :dk_color1 %Blue% "=== Creating boot.wim . . ." 4
if %AddUpdates% equ 2 if %_updexist% equ 1 (
call :uups_du
)
if %relite% equ 0 (set _srcwim=temp\winre.wim) else (set _srcwim=temp\boot.wim)
copy /y %_srcwim% ISOFOLDER\sources\boot.wim %_Nul1%
wimlib-imagex.exe info ISOFOLDER\sources\boot.wim 1 "Microsoft Windows PE (%arch%)" "Microsoft Windows PE (%arch%)" --image-property FLAGS=9 %_Nul3%
wimlib-imagex.exe update ISOFOLDER\sources\boot.wim 1 --command="delete '\Windows\system32\winpeshl.ini'" %_Nul3%
if %ForceDism% equ 0 (
call :BootPE
) else (
call :BootADK
)
if %RefESD% neq 0 call :uups_backup
if exist "!_cabdir!\" (
if %AddUpdates% equ 1 if %_updexist% equ 1 call :dk_color1 %Blue% "=== Removing temporary files . . ." 4
rmdir /s /q "!_cabdir!\" %_Nul3%
)
if %_extVirt% equ 1 if %DeleteSource% neq 1 (
set DVDLABEL=CCSA_%archl%FRE_%langid%_%_ddv%&set DVDISO=%_label%MULTI_%archl%FRE_%langid%
)
if %StartVirtual% neq 0 if %_SrvESD% equ 0 if %_extVirt% equ 0 (
  ren ISOFOLDER %DVDISO%
  if %SkipISO% neq 0 (set qmsg=Finished. You chose not to create iso file.) else (set qmsg=Finished.)
  if %AutoStart% neq 0 (goto :V_Auto) else (goto :V_Manu)
)
set isiso=1
set _rtrn=finISO
goto :esdSWM
:finISO
if %SkipISO% neq 0 (
  ren ISOFOLDER %DVDISO%
  set qmsg=Finished. You chose not to create iso file.
  goto :QUIT
)
call :dk_color1 %Blue% "=== Creating ISO . . ." 4
if /i not %arch%==arm64 (
cdimage.exe -bootdata:2#p0,e,b"ISOFOLDER\boot\etfsboot.com"#pEF,e,b"ISOFOLDER\efi\Microsoft\boot\efisys.bin" -o -m -u2 -udfver102 -t%isotime% -l%DVDLABEL% ISOFOLDER %DVDISO%.ISO %_Supp%
) else (
cdimage.exe -bootdata:1#pEF,e,b"ISOFOLDER\efi\Microsoft\boot\efisys.bin" -o -m -u2 -udfver102 -t%isotime% -l%DVDLABEL% ISOFOLDER %DVDISO%.ISO %_Supp%
)
set ERRTEMP=%ERRORLEVEL%
if %ERRTEMP% neq 0 goto :E_ISO
set qmsg=Finished.
goto :QUIT

:Single
@cls
call :dk_color1 %Gray% "=== Running UUP Converter %uivr% ===" 4 5
call :checkQE
set _initial=1
if %_updexist% equ 0 set AddUpdates=0
if %PREPARED% equ 0 call :PREPARE
if %_IPA% equ 1 if %SkipApps% equ 0 set _runIPA=1
if %W10UI% equ 0 (set AddUpdates=0)
if /i %arch%==arm64 if %winbuild% lss 9600 if %AddUpdates% equ 1 (set AddUpdates=0)
if %Cleanup% equ 0 set ResetBase=0
if %_build% lss 17763 if %AddUpdates% equ 1 (set Cleanup=1)
if %_build% geq 22000 (
if %LCUwinre% equ 2 (set LCUwinre=0) else (set LCUwinre=1)
)
if %_build% geq 25380 (
if %Cleanup% equ 0 set DisableUpdatingUpgrade=1
)
if %_build% geq 26000 (
if %DisableUpdatingUpgrade% equ 2 (set DisableUpdatingUpgrade=0) else (set DisableUpdatingUpgrade=1)
)
if %WIMFILE%==install.wim (
if %AddUpdates% neq 1 if %wim2esd% equ 1 (set WIMFILE=install.esd)
)
if %WIMFILE%==install.esd (
set wim2esd=0
if %AddUpdates% equ 1 (set WIMFILE=install.wim&set wim2esd=1)
if %_runIPA% equ 1 (set WIMFILE=install.wim&set wim2esd=1)
)
if %_Debug% neq 0 set wim2esd=0
if exist "!_work!\%WIMFILE%" (
call :dk_color1 %Red% "An %WIMFILE% file is already present in the current folder" 4 5
(echo.&echo An %WIMFILE% file is already present in the current folder)>>"!logerr!"
goto :QUIT
)
for %%# in (
AutoStart
AddUpdates
Cleanup
ResetBase
SkipWinRE
LCUwinre
DisableUpdatingUpgrade
wim2esd
wim2swm
RefESD
SkipLCUmsu
SkipEdge
AutoExit
AddDrivers
SkipApps
AppsLevel
StubAppsFull
CustomList
) do (
if !%%#! neq 0 set _configured=1
)
if %_configured% equ 1 (
call :dk_color1 %Blue% "=== Configured Options . . ." 4 5
  if %AutoStart% neq 0 echo AutoStart %AutoStart%
  if %AddUpdates% equ 1 (
  echo AddUpdates %AddUpdates%
  if %Cleanup% neq 0 echo Cleanup
  if %Cleanup% neq 0 if %ResetBase% neq 0 echo ResetBase
  if %LCUwinre% neq 0 echo LCUwinre
  if %DisableUpdatingUpgrade% neq 0 echo DisableUpdatingUpgrade
  )
  for %%# in (
  SkipWinRE
  wim2esd
  wim2swm
  RefESD
  AutoExit
  AddDrivers
  ) do (
  if !%%#! neq 0 echo %%#
  )
)
if %_build% geq 21382 if %SkipLCUmsu% neq 0 echo SkipLCUmsu
if %_build% geq 18362 if %AddUpdates% equ 1 if %SkipEdge% neq 0 echo SkipEdge %SkipEdge%
if %_build% geq 22563 if %W10UI% neq 0 (
if %SkipApps% neq 0 echo SkipApps
if %AppsLevel% neq 0 echo AppsLevel %AppsLevel%
if %StubAppsFull% neq 0 echo StubAppsFull
if %_appsCustom% neq 0 echo CustomAppsList
)
if %_runIPA% equ 1 call :appx_sort
if %_IPA% equ 1 if %SkipApps% equ 1 (
if exist "!_UUP!\*.*xbundle" (call :appx_sort) else if exist "!_UUP!\*.appx" (call :appx_sort)
)
call :uups_ref
if %AIO% equ 1 set "MetadataESD=!_UUP!\%uups_esd1%"&set "_flg=%edition1%"&set "_Srvr=%_ESDSrv1%"
if %_count% gtr 1 set "MetadataESD=!_UUP!\!uups_esd%_index1%!"&set "_flg=!edition%_index1%!"&set "_Srvr=!_ESDSrv%_index1%!"
set _file=%WIMFILE%
set _rtrn=RetWIM
goto :InstallWim
:RetWIM
if %WIMFILE%==install.esd (
set wim2swm=0
if %_Debug% neq 0 set SkipWinRE=1
)
set _rtrn=BakWIM
if %SkipWinRE% equ 0 goto :WinreWim
:BakWIM
if %RefESD% neq 0 call :uups_backup
if exist "!_cabdir!\" (
if %AddUpdates% equ 1 if %_updexist% equ 1 call :dk_color1 %Blue% "=== Removing temporary files . . ." 4
rmdir /s /q "!_cabdir!\" %_Nul3%
)
set isiso=0
set _rtrn=finWIM
goto :esdSWM
:finWIM
set qmsg=Finished.
goto :QUIT

:esdSWM
set cnvrt=%_file:~0,-4%
if %isiso% equ 1 pushd "ISOFOLDER\sources"
for /f %%# in ('dir /b /a:-d %WIMFILE%') do set "_size=000000%%~z#"
if %isiso% equ 1 popd
if "%_size%" lss "0000004194304000" set wim2swm=0
if %wim2esd% equ 0 if %wim2swm% equ 0 goto :%_rtrn%
if %wim2esd% equ 0 if %wim2swm% equ 1 goto :swmESD
call :dk_color1 %Blue% "=== Converting install.wim to install.esd . . ." 4 5
wimlib-imagex.exe export %cnvrt%.wim all %cnvrt%.esd --compress=LZMS --solid %_Supp%
set ERRTEMP=%ERRORLEVEL%
if %ERRTEMP% neq 0 (
call :dk_color1 %Red% "Errors were reported during export. Discarding install.esd" 4
(echo.&echo Errors were reported during export. Discarding install.esd)>>"!logerr!"
del /f /q %cnvrt%.esd %_Nul3%
)
if exist %cnvrt%.esd del /f /q %cnvrt%.wim
goto :%_rtrn%
:swmESD
call :dk_color1 %Blue% "=== Splitting install.wim into install*.swm . . ." 4 5
wimlib-imagex.exe split %cnvrt%.wim %cnvrt%.swm 3500 %_Supp%
set ERRTEMP=%ERRORLEVEL%
if %ERRTEMP% neq 0 (
call :dk_color1 %Red% "Errors were reported during split. Discarding install*.swm" 4
(echo.&echo Errors were reported during split. Discarding install*.swm)>>"!logerr!"
del /f /q %cnvrt%*.swm %_Nul3%
)
if exist %cnvrt%*.swm del /f /q %cnvrt%.wim
goto :%_rtrn%

:InstallWim
call :dk_color1 %Blue% "=== Creating %WIMFILE% . . ." 4 5
if exist "temp\*.ESD" (set _rrr=--ref="temp\*.esd") else (set "_rrr=")
if %WIMFILE%==install.wim set _rrr=%_rrr% --compress=LZX
wimlib-imagex.exe export "!MetadataESD!" 3 %_file% --ref="!_UUP!\*.esd" %_rrr% %_Supp%
set ERRTEMP=%ERRORLEVEL%
if %ERRTEMP% neq 0 goto :E_Export
if !_Srvr! equ 1 (
wimlib-imagex.exe info %_file% 1 "%_wsr% %_flg%" "%_wsr% %_flg%" --image-property DISPLAYNAME="!_dName!" --image-property DISPLAYDESCRIPTION="!_dDesc!" --image-property FLAGS=%_flg% %_Nul3%
) else if !FixDisplay! equ 1 (
wimlib-imagex.exe info %_file% 1 "!_os!" "!_os!" --image-property DISPLAYNAME="!_dName!" --image-property DISPLAYDESCRIPTION="!_dDesc!" --image-property FLAGS=%_flg% %_Nul3%
) else (
wimlib-imagex.exe info %_file% 1 --image-property DISPLAYNAME="!_dName!" --image-property DISPLAYDESCRIPTION="!_dDesc!" --image-property FLAGS=%_flg% %_Nul3%
)
set _img=1
if %_count% gtr 1 for /L %%i in (2,1,%_count%) do (
for /L %%# in (1,1,%uups_esd_num%) do if !_index%%i! equ %%# (
  wimlib-imagex.exe export "!_UUP!\!uups_esd%%#!" 3 %_file% --ref="!_UUP!\*.esd" %_rrr% %_Supp%
  call set ERRTEMP=!ERRORLEVEL!
  if !ERRTEMP! neq 0 goto :E_Export
  set /a _img+=1
  if !_ESDSrv%%#! equ 1 (
    wimlib-imagex.exe info %_file% !_img! "%_wsr% !edition%%#!" "%_wsr% !edition%%#!" --image-property DISPLAYNAME="!_dName%%#!" --image-property DISPLAYDESCRIPTION="!_dDesc%%#!" --image-property FLAGS=!edition%%#! %_Nul3%
    ) else if !FixDisplay! equ 1 (
    wimlib-imagex.exe info %_file% !_img! "!_os%%#!" "!_os%%#!" --image-property DISPLAYNAME="!_dName%%#!" --image-property DISPLAYDESCRIPTION="!_dDesc%%#!" --image-property FLAGS=!edition%%#! %_Nul3%
    ) else (
    wimlib-imagex.exe info %_file% !_img! --image-property DISPLAYNAME="!_dName%%#!" --image-property DISPLAYDESCRIPTION="!_dDesc%%#!" --image-property FLAGS=!edition%%#! %_Nul3%
    )
  )
)
if %AIO% equ 1 for /L %%# in (2,1,%uups_esd_num%) do (
wimlib-imagex.exe export "!_UUP!\!uups_esd%%#!" 3 %_file% --ref="!_UUP!\*.esd" %_rrr% %_Supp%
call set ERRTEMP=!ERRORLEVEL!
if !ERRTEMP! neq 0 goto :E_Export
if !_ESDSrv%%#! equ 1 (
  wimlib-imagex.exe info %_file% %%# "%_wsr% !edition%%#!" "%_wsr% !edition%%#!" --image-property DISPLAYNAME="!_dName%%#!" --image-property DISPLAYDESCRIPTION="!_dDesc%%#!" --image-property FLAGS=!edition%%#! %_Nul3%
  ) else if !FixDisplay! equ 1 (
  wimlib-imagex.exe info %_file% %%# "!_os%%#!" "!_os%%#!" --image-property DISPLAYNAME="!_dName%%#!" --image-property DISPLAYDESCRIPTION="!_dDesc%%#!" --image-property FLAGS=!edition%%#! %_Nul3%
  ) else (
  wimlib-imagex.exe info %_file% %%# --image-property DISPLAYNAME="!_dName%%#!" --image-property DISPLAYDESCRIPTION="!_dDesc%%#!" --image-property FLAGS=!edition%%#! %_Nul3%
  )
)
if %_updexist% equ 1 if %_build% geq 22000 if exist "%SysPath%\ucrtbase.dll" if not exist "bin\dpx.dll" if not exist "temp\dpx.dll" call :uups_dpx
if %_reMSU% equ 1 if %SkipLCUmsu% equ 0 call :uups_msu
if exist "!_cabdir!\" rmdir /s /q "!_cabdir!\"
del /f /q %_dLog%\* %_Nul3%
if not exist "%_dLog%\" mkdir "%_dLog%" %_Nul3%
if %AddUpdates% neq 1 if %W10UI% neq 0 if %_runIPA% equ 1 (
if %_file%==%WIMFILE% (call :uups_update %WIMFILE% appx) else (call :uups_update install.iso appx)
)
if %AddUpdates% equ 1 if %_updexist% equ 1 (
if %_file%==%WIMFILE% (call :uups_update %WIMFILE%) else (call :uups_update install.iso)
)
if %_file%==%WIMFILE% goto :%_rtrn%
if %AddUpdates% equ 2 if %_updexist% equ 1 (
call :uups_external
)
goto :%_rtrn%

:WinreWim
call :dk_color1 %Blue% "=== Creating winre.wim . . ." 4 5
wimlib-imagex.exe export "!MetadataESD!" 2 temp\winre.wim --compress=LZX --boot %_Supp%
set ERRTEMP=%ERRORLEVEL%
if %ERRTEMP% neq 0 goto :E_Export
if %uwinpe% equ 1 if %AddUpdates% equ 1 if %_updexist% equ 1 (
call :uups_update temp\winre.wim
)
if %relite% neq 0 (
ren temp\winre.wim boot.wim
wimlib-imagex.exe export temp\boot.wim 2 temp\winre.wim --compress=LZX --boot %_Supp%
wimlib-imagex.exe delete temp\boot.wim 2 --soft %_Nul3%
)
if %SkipWinRE% neq 0 goto :%_rtrn%
call :dk_color1 %Blue% "=== Adding winre.wim to %WIMFILE% . . ." 4
for /f "tokens=3 delims=: " %%# in ('wimlib-imagex.exe info %_file% ^| findstr /c:"Image Count"') do set imgcount=%%#
for /L %%# in (1,1,%imgcount%) do (
  wimlib-imagex.exe update %_file% %%# --command="add 'temp\winre.wim' '\windows\system32\recovery\winre.wim'" %_Null%
)
goto :%_rtrn%

:BootADK
if %W10UI% equ 0 goto :BootPE
if exist "%_mount%\" rmdir /s /q "%_mount%\"
if not exist "%_mount%\" mkdir "%_mount%"
%_dism1% /Quiet /Mount-Wim /Wimfile:ISOFOLDER\sources\boot.wim /Index:1 /MountDir:"%_mount%" %_Nul3%
set ERRTEMP=%ERRORLEVEL%
if %ERRTEMP% neq 0 (
%_dism1% /Image:"%_mount%" /LogPath:"%_dLog%\DismNUL.log" /Get-Packages %_Null%
%_dism1% /Unmount-Wim /MountDir:"%_mount%" /Discard %_Nul3%
%_dism1% /Cleanup-Wim %_Nul3%
rmdir /s /q "%_mount%\"
(echo.&echo Failed mounting boot.wim)>>"!logerr!"
goto :BootPE
)
%_dism1% /Quiet /Image:"%_mount%" /Set-TargetPath:X:\$windows.~bt\
if !errorlevel! neq 0 (
  (echo.&echo Dism.exe Set-TargetPath for boot.wim failed)>>"!logerr!"
  )
%_dism1% /Quiet /Unmount-Wim /MountDir:"%_mount%" /Commit
set ERRTEMP=%ERRORLEVEL%
if %ERRTEMP% neq 0 (
%_dism1% /Image:"%_mount%" /LogPath:"%_dLog%\DismNUL.log" /Get-Packages %_Null%
%_dism1% /Unmount-Wim /MountDir:"%_mount%" /Discard %_Nul3%
%_dism1% /Cleanup-Wim %_Nul3%
rmdir /s /q "%_mount%\"
(echo.&echo Failed unmounting boot.wim)>>"!logerr!"
goto :BootPE
)
rmdir /s /q "%_mount%\"
goto :BootST

:BootPE
wimlib-imagex.exe extract ISOFOLDER\sources\boot.wim 1 Windows\System32\config\SOFTWARE --dest-dir=.\bin\temp --no-acls --no-attributes %_Null%
offlinereg.exe .\bin\temp\SOFTWARE "Microsoft\Windows NT\CurrentVersion\WinPE" setvalue InstRoot X:\$windows.~bt\ %_Nul3%
offlinereg.exe .\bin\temp\SOFTWARE.new "Microsoft\Windows NT\CurrentVersion" setvalue SystemRoot X:\$windows.~bt\Windows %_Nul3%
del /f /q .\bin\temp\SOFTWARE
ren .\bin\temp\SOFTWARE.new SOFTWARE
type nul>bin\boot-wim.txt
>>bin\boot-wim.txt echo add 'bin^\temp^\SOFTWARE' '^\Windows^\System32^\config^\SOFTWARE'
set "_bkimg="
wimlib-imagex.exe extract ISOFOLDER\sources\boot.wim 1 Windows\System32\winpe.jpg --dest-dir=ISOFOLDER\sources --no-acls --no-attributes --nullglob %_Null%
for %%# in (background_cli.bmp, background_svr.bmp, background_cli.png, background_svr.png, winpe.jpg) do if exist "ISOFOLDER\sources\%%#" set "_bkimg=%%#"
if defined _bkimg (
>>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\%_bkimg%' '^\Windows^\system32^\winpe.jpg'
>>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\%_bkimg%' '^\Windows^\system32^\winre.jpg'
)
wimlib-imagex.exe update ISOFOLDER\sources\boot.wim 1 < bin\boot-wim.txt %_Null%
rmdir /s /q bin\temp\

:BootST
wimlib-imagex.exe extract "!MetadataESD!" 3 Windows\system32\xmllite.dll --dest-dir=ISOFOLDER\sources --no-acls --no-attributes %_Nul3%
type nul>bin\boot-wim.txt
>>bin\boot-wim.txt echo delete '^\Windows^\system32^\winpeshl.ini'
>>bin\boot-wim.txt echo add 'ISOFOLDER^\setup.exe' '^\setup.exe'
>>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\inf^\setup.cfg' '^\sources^\inf^\setup.cfg'
if not defined _bkimg (
wimlib-imagex.exe extract ISOFOLDER\sources\boot.wim 1 Windows\System32\winpe.jpg --dest-dir=ISOFOLDER\sources --no-acls --no-attributes --nullglob %_Null%
for %%# in (background_cli.bmp, background_svr.bmp, background_cli.png, background_svr.png, winpe.jpg) do if exist "ISOFOLDER\sources\%%#" set "_bkimg=%%#"
)
if defined _bkimg (
>>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\%_bkimg%' '^\sources^\background.bmp'
>>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\%_bkimg%' '^\Windows^\system32^\setup.bmp'
>>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\%_bkimg%' '^\Windows^\system32^\winpe.jpg'
>>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\%_bkimg%' '^\Windows^\system32^\winre.jpg'
)
for /f %%# in (bin\bootwim.txt) do if exist "ISOFOLDER\sources\%%#" @(
>>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\%%#' '^\sources^\%%#'
)
for /f %%# in (bin\bootmui.txt) do if exist "ISOFOLDER\sources\%langid%\%%#" @(
>>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\%langid%^\%%#' '^\sources^\%langid%^\%%#'
)
wimlib-imagex.exe export %_srcwim% 1 ISOFOLDER\sources\boot.wim "Microsoft Windows Setup (%arch%)" "Microsoft Windows Setup (%arch%)" --boot %_Supp%
wimlib-imagex.exe update ISOFOLDER\sources\boot.wim 2 < bin\boot-wim.txt %_Null%
wimlib-imagex.exe info ISOFOLDER\sources\boot.wim 2 --image-property FLAGS=2 %_Nul3%
if %relite% neq 0 (
call :dk_color1 %Blue% "=== Rebuilding boot.wim . . ." 4 5
%_wrb% wimlib-imagex.exe optimize ISOFOLDER\sources\boot.wim %_Supp%
)
del /f /q bin\boot-wim.txt %_Nul3%
del /f /q ISOFOLDER\sources\xmllite.dll %_Nul3%
del /f /q ISOFOLDER\sources\winpe.jpg %_Nul3%
exit /b

:INFO
if %PREPARED% equ 0 call :PREPARE
@cls
call :dk_color2 %_White% "                " %Blue% "=== UUP Contents Info ===" 0 8
echo      Arch: %arch%
echo  Language: %langid%
echo   Version: %ver1%.%ver2%.%_build%.%svcbuild%
echo    Branch: %branch%
echo        OS: %_os%
echo.
%_Contn%&%_Pause%
goto :MAINMENU

:INFOAIO
if %PREPARED% equ 0 call :PREPARE
@cls
call :dk_color2 %_White% "                " %Blue% "=== UUP Contents Info ===" 0 8
echo      Arch: %arch%
echo   Version: %ver1%.%ver2%.%_build%.%svcbuild%
echo    Branch: %branch%
echo  Editions:
for /L %%# in (1,1,%uups_esd_num%) do (
echo %%#. !_name%%#!
)
echo.
%_Contn%&%_Pause%
goto :MAINMENU

:PREPARE
if %_initial% equ 0 @cls
call :dk_color1 %Blue% "=== Checking UUP Info . . ."
set PREPARED=1
if %AIO% equ 1 set "MetadataESD=!_UUP!\%uups_esd1%"&set "_flg=%edition1%"&set "arch=%arch1%"&set "langid=%langid1%"&set "_oName=%_oname1%"&set "_Srvr=%_ESDSrv1%"
if %_count% gtr 1 set "MetadataESD=!_UUP!\!uups_esd%_index1%!"&set "_flg=!edition%_index1%!"&set "arch=!arch%_index1%!"&set "langid=!langid%_index1%!"&set "_oName=!_oname%_index1%!"&set "_Srvr=!_ESDSrv%_index1%!"
imagex /info "!MetadataESD!" 3 >bin\info.txt 2>&1
for /f "tokens=3 delims=<>" %%# in ('find /i "<MAJOR>" bin\info.txt') do set ver1=%%#
for /f "tokens=3 delims=<>" %%# in ('find /i "<MINOR>" bin\info.txt') do set ver2=%%#
for /f "tokens=3 delims=<>" %%# in ('find /i "<BUILD>" bin\info.txt') do set _build=%%#
for /f "tokens=3 delims=<>" %%# in ('find /i "<SPBUILD>" bin\info.txt') do set svcbuild=%%#
for /f "tokens=3 delims=<>" %%# in ('imagex /info "!MetadataESD!" 3 ^| find /i "<DISPLAYNAME>" %_Nul6%') do if /i "%%#"=="/DISPLAYNAME" (set FixDisplay=1)
set /a _fixSV=%_build%+1
if %uups_esd_num% gtr 1 for /L %%A in (2,1,%uups_esd_num%) do (
imagex /info "!_UUP!\!uups_esd%%A!" 3 >bin\info%%A.txt 2>&1
)
for /f "tokens=*" %%A in ('chcp') do for %%B in (%%A) do set "oemcp=%%~nB"
>nul chcp 65001
cmd.exe /u /c type bin\info.txt>bin\infou.txt
if %uups_esd_num% gtr 1 for /L %%A in (2,1,%uups_esd_num%) do (
cmd.exe /u /c type bin\info%%A.txt>bin\info%%Au.txt
)
for /f "tokens=3 delims=<>" %%# in ('find /i "<NAME>" bin\infou.txt') do (set "_dName=%%#"&set "_os=%%#")
for /f "tokens=3 delims=<>" %%# in ('find /i "<DESCRIPTION>" bin\infou.txt') do set "_dDesc=%%#"
for %%# in (ru-ru,zh-cn,zh-tw,zh-hk) do if /i %langid%==%%# set "_os=!_oName!"
if %uups_esd_num% gtr 1 for /L %%A in (2,1,%uups_esd_num%) do (
for /f "tokens=3 delims=<>" %%# in ('find /i "<NAME>" bin\info%%Au.txt') do (set "_dName%%A=%%#"&set "_os%%A=%%#")
for /f "tokens=3 delims=<>" %%# in ('find /i "<DESCRIPTION>" bin\info%%Au.txt') do set "_dDesc%%A=%%#"
for %%# in (ru-ru,zh-cn,zh-tw,zh-hk) do if /i !langid%%A!==%%# set "_os%%A=!_oName%%A!"
)
>nul chcp %oemcp%
del /f /q bin\info*.txt
if %_build% geq 21382 if exist "!_UUP!\*.AggregatedMetadata*.cab" if exist "!_UUP!\*Windows1*-KB*.cab" if exist "!_UUP!\*Windows1*-KB*.psf" set _reMSU=1
if %_build% geq 22563 if exist "!_UUP!\*.AggregatedMetadata*.cab" (
if exist "!_UUP!\*.*xbundle" set _IPA=1
if exist "!_UUP!\*.appx" set _IPA=1
if exist "!_UUP!\Apps\*_8wekyb3d8bbwe" set _IPA=1
)
if %_build% geq 22621 if exist "!_UUP!\*Edge*.wim" (
set _wimEdge=1
if not exist "!_UUP!\Edge.wim" for /f %%# in ('dir /b /a:-d "!_UUP!\*Edge*.wim"') do rename "!_UUP!\%%#" Edge.wim %_Nul3%
)
set _dpx=0
if %_updexist% equ 1 if %_build% geq 22000 if exist "%SysPath%\ucrtbase.dll" if exist "!_UUP!\*DesktopDeployment*.cab" (
if /i %arch%==%xOS% set _dpx=1
if /i %arch%==x64 if /i %xOS%==amd64 set _dpx=1
)
if %_dpx% equ 1 (
for /f "delims=" %%# in ('dir /b /a:-d "!_UUP!\*DesktopDeployment*.cab"') do expand.exe -f:dpx.dll "!_UUP!\%%#" .\temp %_Null%
copy /y %SysPath%\expand.exe temp\ %_Nul3%
)
wimlib-imagex.exe extract "!MetadataESD!" 1 sources\ei.cfg --dest-dir=.\bin\temp --no-acls --no-attributes %_Nul3%
if exist "bin\temp\ei.cfg" type .\bin\temp\ei.cfg %_Nul2% | find /i "Volume" %_Nul1% && set VOL=1
wimlib-imagex.exe extract "!MetadataESD!" 1 sources\setuphost.exe --dest-dir=.\bin\temp --no-acls --no-attributes %_Nul3%
7z.exe l .\bin\temp\setuphost.exe >.\bin\temp\version.txt 2>&1
if %_build% geq 22478 (
wimlib-imagex.exe extract "!MetadataESD!" 3 Windows\System32\UpdateAgent.dll --dest-dir=.\bin\temp --no-acls --no-attributes --ref="!_UUP!\*.esd" %_Nul3%
if exist "bin\temp\UpdateAgent.dll" 7z.exe l .\bin\temp\UpdateAgent.dll >.\bin\temp\version.txt 2>&1
)
for /f "tokens=4-7 delims=.() " %%i in ('"findstr /i /b "FileVersion" .\bin\temp\version.txt" %_Nul6%') do (set uupver=%%i.%%j&set uupmaj=%%i&set uupmin=%%j&set branch=%%k&set uupdate=%%l)
set revver=%uupver%&set revmaj=%uupmaj%&set revmin=%uupmin%
set "tok=6,7"&set "toe=5,6,7"
if /i %arch%==x86 (set _ss=x86) else if /i %arch%==x64 (set _ss=amd64) else (set _ss=arm64)
wimlib-imagex.exe extract "!MetadataESD!" 3 Windows\WinSxS\Manifests\%_ss%_microsoft-windows-coreos-revision*.manifest --dest-dir=.\bin\temp --no-acls --no-attributes --ref="!_UUP!\*.esd" %_Nul3%
if exist "bin\temp\*_microsoft-windows-coreos-revision*.manifest" for /f "tokens=%tok% delims=_." %%i in ('dir /b /a:-d /od .\bin\temp\*_microsoft-windows-coreos-revision*.manifest') do (set revver=%%i.%%j&set revmaj=%%i&set revmin=%%j)
if %_build% geq 15063 (
wimlib-imagex.exe extract "!MetadataESD!" 3 Windows\System32\config\SOFTWARE --dest-dir=.\bin\temp --no-acls --no-attributes %_Null%
set "isokey=Microsoft\Windows NT\CurrentVersion\Update\TargetingInfo\Installed"
for /f %%i in ('"offlinereg.exe .\bin\temp\SOFTWARE "!isokey!" enumkeys %_Nul6% ^| findstr /i /r ".*\.OS""') do if not errorlevel 1 (
  for /f "tokens=3 delims==:" %%A in ('"offlinereg.exe .\bin\temp\SOFTWARE "!isokey!\%%i" getvalue Branch %_Nul6%"') do set "revbranch=%%~A"
  for /f "tokens=5,6 delims==:." %%A in ('"offlinereg.exe .\bin\temp\SOFTWARE "!isokey!\%%i" getvalue Version %_Nul6%"') do if %%A gtr !revmaj! (
    set "revver=%%~A.%%B
    set revmaj=%%~A
    set "revmin=%%B
    )
  )
)
if defined revbranch set branch=%revbranch%
call :fixBranch %revmaj%
if %uupmin% lss %revmin% (
set uupver=%revver%
set uupmin=%revmin%
if not exist "%SystemRoot%\temp\" mkdir "%SystemRoot%\temp" %_Nul3%
wimlib-imagex.exe extract "!MetadataESD!" 3 Windows\Servicing\Packages\Package_for_RollupFix*.mum --dest-dir=.\bin\temp --no-acls --no-attributes %_Nul3%
for /f %%# in ('dir /b /a:-d /od bin\temp\Package_for_RollupFix*.mum') do copy /y "bin\temp\%%#" %SystemRoot%\temp\update.mum %_Nul1%
call :datemum uupdate placebo
)
set _legacy=
set _useold=0
if /i "%branch%"=="WinBuild" set _useold=1
if /i "%branch%"=="GitEnlistment" set _useold=1
if /i "%uupdate%"=="winpbld" set _useold=1
if %_useold% equ 1 (
wimlib-imagex.exe extract "!MetadataESD!" 3 Windows\System32\config\SOFTWARE --dest-dir=.\bin\temp --no-acls --no-attributes %_Null%
for /f "tokens=3 delims==:" %%# in ('"offlinereg.exe .\bin\temp\SOFTWARE "Microsoft\Windows NT\CurrentVersion" getvalue BuildLabEx" %_Nul6%') do if not errorlevel 1 (for /f "tokens=1-5 delims=." %%i in ('echo %%~#') do set _legacy=%%i.%%j.%%m.%%l&set branch=%%l)
)
if defined _legacy (set _label=%_legacy%) else (set _label=%uupver%.%uupdate%.%branch%)
rmdir /s /q bin\temp\
set "apiver=%winbuild%"
if %_ADK% equ 1 (
7z.exe l "%DandIRoot%\%xOS%\DISM\dismapi.dll" >.\bin\version.txt 2>&1
for /f "tokens=3 delims=." %%i in ('"findstr /i /b "FileVersion" .\bin\version.txt" %_Nul6%') do set "apiver=%%i"
del /f /q .\bin\version.txt %_Nul3%
)

:setlabel
if %_SrvESD% equ 1 (set _label=%_label%_SERVER) else (set _label=%_label%_CLIENT)
for %%# in (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do (
set _label=!_label:%%#=%%#!
set branch=!branch:%%#=%%#!
set langid=!langid:%%#=%%#!
set editionid=!editionid:%%#=%%#!
)
if /i %arch%==x86 set archl=X86
if /i %arch%==x64 set archl=X64
if /i %arch%==arm64 set archl=A64

if %_SrvESD% equ 1 (
if %AIO% equ 1 set DVDLABEL=SSS_%archl%FRE_%langid%_DV9&set DVDISO=%_label%_%archl%FRE_%langid%&exit /b
if %_count% gtr 1 set DVDLABEL=SSS_%archl%FRE_%langid%_DV9&set DVDISO=%_label%_%archl%FRE_%langid%&exit /b
)
set _ddv=DV5
if %_build% geq 22621 set _ddv=DV9
if %AIO% equ 1 set DVDLABEL=CCSA_%archl%FRE_%langid%_%_ddv%&set DVDISO=%_label%MULTI_%archl%FRE_%langid%&exit /b
if %_count% gtr 1 set DVDLABEL=CCSA_%archl%FRE_%langid%_%_ddv%&set DVDISO=%_label%MULTI_%archl%FRE_%langid%&exit /b

:virtlabel
set DVDLABEL=CCSA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%%editionid%_RET_%archl%FRE_%langid%
if %_SrvESD% equ 1 set DVDLABEL=SSS_%archl%FRE_%langid%_DV5&set DVDISO=%_label%-%editionid%_RET_%archl%FRE_%langid%
if /i %editionid%==Core set DVDLABEL=CCRA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%CORE_OEMRET_%archl%FRE_%langid%&exit /b
if /i %editionid%==CoreN set DVDLABEL=CCRNA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%COREN_OEMRET_%archl%FRE_%langid%&exit /b
if /i %editionid%==CoreSingleLanguage set DVDLABEL=CSLA_%archl%FREO_%langid%_DV5&set DVDISO=%_label%SINGLELANGUAGE_OEM_%archl%FRE_%langid%&exit /b
if /i %editionid%==CoreCountrySpecific set DVDLABEL=CCHA_%archl%FREO_%langid%_DV5&set DVDISO=%_label%CHINA_OEM_%archl%FRE_%langid%&exit /b
if /i %editionid%==Professional (if %VOL% equ 1 (set DVDLABEL=CPRA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%PROFESSIONALVL_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CPRA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%PRO_OEMRET_%archl%FRE_%langid%))&exit /b
if /i %editionid%==ProfessionalN (if %VOL% equ 1 (set DVDLABEL=CPRNA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%PROFESSIONALNVL_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CPRNA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%PRON_OEMRET_%archl%FRE_%langid%))&exit /b
if /i %editionid%==Education (if %VOL% equ 1 (set DVDLABEL=CEDA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%EDUCATION_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CEDA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%EDUCATION_RET_%archl%FRE_%langid%))&exit /b
if /i %editionid%==EducationN (if %VOL% equ 1 (set DVDLABEL=CEDNA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%EDUCATIONN_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CEDNA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%EDUCATIONN_RET_%archl%FRE_%langid%))&exit /b
if /i %editionid%==Enterprise set DVDLABEL=CENA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%ENTERPRISE_VOL_%archl%FRE_%langid%&exit /b
if /i %editionid%==EnterpriseN set DVDLABEL=CENNA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%ENTERPRISEN_VOL_%archl%FRE_%langid%&exit /b
if /i %editionid%==Cloud set DVDLABEL=CWCA_%archl%FREO_%langid%_DV5&set DVDISO=%_label%CLOUD_OEM_%archl%FRE_%langid%&exit /b
if /i %editionid%==CloudN set DVDLABEL=CWCNNA_%archl%FREO_%langid%_DV5&set DVDISO=%_label%CLOUDN_OEM_%archl%FRE_%langid%&exit /b
if /i %editionid%==PPIPro set DVDLABEL=CPPIA_%archl%FREO_%langid%_DV5&set DVDISO=%_label%PPIPRO_OEM_%archl%FRE_%langid%&exit /b
if /i %editionid%==EnterpriseG set DVDLABEL=CEGA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%ENTERPRISEG_VOL_%archl%FRE_%langid%&exit /b
if /i %editionid%==EnterpriseGN set DVDLABEL=CEGNA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%ENTERPRISEGN_VOL_%archl%FRE_%langid%&exit /b
if /i %editionid%==EnterpriseS set DVDLABEL=CES_%archl%FREV_%langid%_DV5&set DVDISO=%_label%ENTERPRISES_VOL_%archl%FRE_%langid%&exit /b
if /i %editionid%==EnterpriseSN set DVDLABEL=CESNN_%archl%FREV_%langid%_DV5&set DVDISO=%_label%ENTERPRISESN_VOL_%archl%FRE_%langid%&exit /b
if /i %editionid%==ProfessionalEducation (if %VOL% equ 1 (set DVDLABEL=CPREA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%PROEDUCATION_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CPREA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%PROEDUCATION_OEMRET_%archl%FRE_%langid%))&exit /b
if /i %editionid%==ProfessionalEducationN (if %VOL% equ 1 (set DVDLABEL=CPRENA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%PROEDUCATIONN_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CPRENA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%PROEDUCATIONN_OEMRET_%archl%FRE_%langid%))&exit /b
if /i %editionid%==ProfessionalWorkstation (if %VOL% equ 1 (set DVDLABEL=CPRWA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%PROWORKSTATION_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CPRWA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%PROWORKSTATION_OEMRET_%archl%FRE_%langid%))&exit /b
if /i %editionid%==ProfessionalWorkstationN (if %VOL% equ 1 (set DVDLABEL=CPRWNA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%PROWORKSTATIONN_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CPRWNA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%PROWORKSTATIONN_OEMRET_%archl%FRE_%langid%))&exit /b
if /i %editionid%==ProfessionalSingleLanguage set DVDLABEL=CPRSLA_%archl%FREO_%langid%_DV5&set DVDISO=%_label%PROSINGLELANGUAGE_OEM_%archl%FRE_%langid%&exit /b
if /i %editionid%==ProfessionalCountrySpecific set DVDLABEL=CPRCHA_%archl%FREO_%langid%_DV5&set DVDISO=%_label%PROCHINA_OEM_%archl%FRE_%langid%&exit /b
if /i %editionid%==CloudEdition (if %VOL% equ 1 (set DVDLABEL=CWCA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%CLOUD_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CWCA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%CLOUD_OEMRET_%archl%FRE_%langid%))&exit /b
if /i %editionid%==CloudEditionN (if %VOL% equ 1 (set DVDLABEL=CWCNNA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%CLOUDN_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CWCNNA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%CLOUDN_OEMRET_%archl%FRE_%langid%))&exit /b
if /i %editionid%==ServerStandard (if %VOL% equ 1 (set DVDLABEL=SSS_%archl%FREV_%langid%_DV5&set DVDISO=%_label%STANDARD_VOL_%archl%FRE_%langid%) else (set DVDLABEL=SSS_%archl%FRE_%langid%_DV5&set DVDISO=%_label%STANDARD_OEMRET_%archl%FRE_%langid%))&exit /b
if /i %editionid%==ServerStandardCore (if %VOL% equ 1 (set DVDLABEL=SSS_%archl%FREV_%langid%_DV5&set DVDISO=%_label%STANDARDCORE_VOL_%archl%FRE_%langid%) else (set DVDLABEL=SSS_%archl%FRE_%langid%_DV5&set DVDISO=%_label%STANDARDCORE_OEMRET_%archl%FRE_%langid%))&exit /b
if /i %editionid%==ServerDatacenter (if %VOL% equ 1 (set DVDLABEL=SSS_%archl%FREV_%langid%_DV5&set DVDISO=%_label%DATACENTER_VOL_%archl%FRE_%langid%) else (set DVDLABEL=SSS_%archl%FRE_%langid%_DV5&set DVDISO=%_label%DATACENTER_OEMRET_%archl%FRE_%langid%))&exit /b
if /i %editionid%==ServerDatacenterCore (if %VOL% equ 1 (set DVDLABEL=SSS_%archl%FREV_%langid%_DV5&set DVDISO=%_label%DATACENTERCORE_VOL_%archl%FRE_%langid%) else (set DVDLABEL=SSS_%archl%FRE_%langid%_DV5&set DVDISO=%_label%DATACENTERCORE_OEMRET_%archl%FRE_%langid%))&exit /b
if /i %editionid%==ServerTurbine (if %VOL% equ 1 (set DVDLABEL=SADC_%archl%FREV_%langid%_DV5&set DVDISO=%_label%TURBINE_VOL_%archl%FRE_%langid%) else (set DVDLABEL=SADC_%archl%FRE_%langid%_DV5&set DVDISO=%_label%TURBINE_OEMRET_%archl%FRE_%langid%))&exit /b
if /i %editionid%==ServerTurbineCore (if %VOL% equ 1 (set DVDLABEL=SADC_%archl%FREV_%langid%_DV5&set DVDISO=%_label%TURBINECOR_VOL_%archl%FRE_%langid%) else (set DVDLABEL=SADC_%archl%FRE_%langid%_DV5&set DVDISO=%_label%TURBINECOR_OEMRET_%archl%FRE_%langid%))&exit /b
if /i %editionid%==ServerAzureStackHCICor set DVDLABEL=SASH_%archl%FRE_%langid%_DV5&set DVDISO=%_label%AZURESTACKHCI_RET_%archl%FRE_%langid%&exit /b
exit /b

:fixBranch
if %1==18363 if /i "%branch:~0,4%"=="19h1" set branch=19h2%branch:~4%
if %1==19042 if /i "%branch:~0,2%"=="vb" set branch=20h2%branch:~2%
if %1==19043 if /i "%branch:~0,2%"=="vb" set branch=21h1%branch:~2%
if %1==19044 if /i "%branch:~0,2%"=="vb" set branch=21h2%branch:~2%
if %1==19045 if /i "%branch:~0,2%"=="vb" set branch=22h2%branch:~2%
if %1==20349 if /i "%branch:~0,2%"=="fe" set branch=22h2%branch:~2%
if %1==22631 if /i "%branch:~0,2%"=="ni" (echo %branch% | find /i "beta" %_Nul1% || set branch=23h2_ni%branch:~2%)
exit /b

:fixVerBrn
set "_ti=!%2!"
set "_tv=!%3!"
set "_tb=!%4!"
if %1==18363 (
if /i "%_ti:~0,4%"=="19h1" set _ti=19h2%_ti:~4%
if %_tv:~0,5%==18362 set _tv=18363%_tv:~5%
if /i "%_tb:~0,4%"=="19h1" set _tb=19h2%_tb:~4%
)
if %1==19042 (
if /i "%_ti:~0,2%"=="vb" set _ti=20h2%_ti:~2%
if %_tv:~0,5%==19041 set _tv=19042%_tv:~5%
if /i "%_tb:~0,2%"=="vb" set _tb=20h2%_tb:~2%
)
if %1==19043 (
if /i "%_ti:~0,2%"=="vb" set _ti=21h1%_ti:~2%
if %_tv:~0,5%==19041 set _tv=19043%_tv:~5%
if /i "%_tb:~0,2%"=="vb" set _tb=21h1%_tb:~2%
)
if %1==19044 (
if /i "%_ti:~0,2%"=="vb" set _ti=21h2%_ti:~2%
if %_tv:~0,5%==19041 set _tv=19044%_tv:~5%
if /i "%_tb:~0,2%"=="vb" set _tb=21h2%_tb:~2%
)
if %1==19045 (
if /i "%_ti:~0,2%"=="vb" set _ti=22h2%_ti:~2%
if %_tv:~0,5%==19041 set _tv=19045%_tv:~5%
if /i "%_tb:~0,2%"=="vb" set _tb=22h2%_tb:~2%
)
if %1==20349 (
if /i "%_ti:~0,2%"=="fe" set _ti=22h2%_ti:~2%
if %_tv:~0,5%==20348 set _tv=20349%_tv:~5%
if /i "%_tb:~0,2%"=="fe" set _tb=22h2%_tb:~2%
)
if %1==%_fixSV% if %_build% geq 21382 (
if %_tv:~0,5%==%_build% set _tv=%_fixSV%%_tv:~5%
)
if %1==22631 (
if /i "%_ti:~0,2%"=="ni" (echo %_ti% | find /i "beta" %_Nul1% || set _ti=23h2_ni%_ti:~2%)
if %_tv:~0,5%==22621 set _tv=22631%_tv:~5%
if /i "%_tb:~0,2%"=="ni" (echo %_tb% | find /i "beta" %_Nul1% || set _tb=23h2_ni%_tb:~2%)
)
set "%2=%_ti%"
set "%3=%_tv%"
set "%4=%_tb%"
exit /b

:datemum
set "mumfile=%SystemRoot%\temp\update.mum"
set "chkfile=!mumfile:\=\\!"
if %_cwmi% equ 1 for /f "tokens=2 delims==" %%# in ('wmic datafile where "name='!chkfile!'" get LastModified /value') do set "mumdate=%%#"
if %_cwmi% equ 0 for /f %%# in ('%_psc% "([WMI]'CIM_DataFile.Name=''!chkfile!''').LastModified"') do set "mumdate=%%#"
del /f /q %SystemRoot%\temp\*.mum
set "%1=!mumdate:~2,2!!mumdate:~4,2!!mumdate:~6,2!-!mumdate:~8,4!"
set "%2=!mumdate:~4,2!/!mumdate:~6,2!/!mumdate:~0,4!,!mumdate:~8,2!:!mumdate:~10,2!:!mumdate:~12,2!"
exit /b

:uups_ref
call :dk_color1 %Blue% "=== Preparing Reference ESDs . . ." 4
if %RefESD% neq 0 (set _level=LZX) else (set _level=XPRESS)
if exist "!_UUP!\*.xml.cab" if exist "!_UUP!\Metadata\*" move /y "!_UUP!\*.xml.cab" "!_UUP!\Metadata\" %_Nul3%
set _doEcho=
if exist "!_UUP!\*.cab" (
for /f "tokens=* delims=" %%# in ('dir /b /a:-d "!_UUP!\*.cab"') do (
	del /f /q temp\update.mum %_Null%
	expand.exe -f:update.mum "!_UUP!\%%#" .\temp %_Null%
	if exist "temp\update.mum" call :uups_cab "%%#"
	)
)
if %EXPRESS% equ 1 (
for /f "tokens=* delims=" %%# in ('dir /b /a:d /o:-n "!_UUP!\"') do call :uups_dir "%%#"
)
if exist "!_UUP!\Metadata\*.xml.cab" copy /y "!_UUP!\Metadata\*.xml.cab" "!_UUP!\" %_Nul3%
exit /b

:uups_dir
set cbsp=%~1
if exist "!_work!\temp\%cbsp%.ESD" exit /b
echo %cbsp%| findstr /i /r "Windows.*-KB SSU-.* RetailDemo Holographic-Desktop-FOD" %_Nul1% && exit /b
if /i "%cbsp%"=="Metadata" exit /b
if not defined _doEcho echo.
echo DIR-^>ESD: %cbsp%
rmdir /s /q "!_UUP!\%~1\$dpx$.tmp\" %_Nul3%
wimlib-imagex.exe capture "!_UUP!\%~1" "temp\%cbsp%.ESD" --compress=%_level% --check --no-acls --norpfix "Edition Package" "Edition Package" %_Null%
set _doEcho=1
exit /b

:uups_cab
set cbsp=%~n1
if exist "!_work!\temp\%cbsp%.ESD" exit /b
echo %cbsp%| findstr /i /r "Windows.*-KB SSU-.* RetailDemo Holographic-Desktop-FOD" %_Nul1% && exit /b
if not defined _doEcho echo.
echo %cbsp%
set /a _ref+=1
set /a _rnd=%random%
set _dst=%_drv%\_tmp%_ref%
if exist "%_dst%" (set _dst=%_drv%\_tmp%_rnd%)
mkdir %_dst% %_Nul3%
expand.exe -f:* "!_UUP!\%cbsp%.cab" %_dst%\ %_Null%
wimlib-imagex.exe capture "%_dst%" "temp\%cbsp%.ESD" --compress=%_level% --check --no-acls --norpfix "Edition Package" "Edition Package" %_Null%
rmdir /s /q %_dst%\ %_Nul3%
if exist "%_dst%\" (
mkdir %_drv%\_del %_Null%
robocopy %_drv%\_del %_dst% /MIR /R:1 /W:1 /NFL /NDL /NP /NJH /NJS %_Null%
rmdir /s /q %_drv%\_del\ %_Null%
rmdir /s /q %_dst%\ %_Null%
)
set _doEcho=1
exit /b

:uups_esd
set _ESDSrv%1=0
for /f "tokens=2 delims=]" %%# in ('find /v /n "" temp\uups_esd.txt ^| find "[%1]"') do set uups_esd=%%#
set "uups_esd%1=%uups_esd%"
wimlib-imagex.exe info "!_UUP!\%uups_esd%" 3 %_Nul3%
set ERRTEMP=%ERRORLEVEL%
if %ERRTEMP% equ 73 (
%_err%
echo %uups_esd% file is corrupted
echo.
(echo.&echo %uups_esd% file is corrupted)>>"!logerr!"
set eWIMLIB=1
exit /b
)
if %ERRTEMP% neq 0 (
%_err%
echo Could not parse info from %uups_esd%
echo.
(echo.&echo Could not parse info from %uups_esd%)>>"!logerr!"
set eWIMLIB=1
exit /b
)
imagex /info "!_UUP!\%uups_esd%" 3 >bin\info.txt 2>&1
for /f "tokens=3 delims=<>" %%# in ('find /i "<DEFAULT>" bin\info.txt') do set "langid%1=%%#"
for /f "tokens=3 delims=<>" %%# in ('find /i "<EDITIONID>" bin\info.txt') do set "edition%1=%%#"
for /f "tokens=3 delims=<>" %%# in ('find /i "<ARCH>" bin\info.txt') do (if %%# equ 0 (set "arch%1=x86") else if %%# equ 9 (set "arch%1=x64") else (set "arch%1=arm64"))
for /f "tokens=3 delims=<>" %%# in ('find /i "<NAME>" bin\info.txt') do set "_oname%1=%%#"
for /f "tokens=3 delims=<>" %%# in ('find /i "<BUILD>" bin\info.txt') do set _obuild%1=%%#
set "_wtx=Windows 10"
find /i "<NAME>" bin\info.txt %_Nul2% | find /i "Windows 11" %_Nul1% && (set "_wtx=Windows 11")
find /i "<NAME>" bin\info.txt %_Nul2% | find /i "Windows 12" %_Nul1% && (set "_wtx=Windows 12")
echo !edition%1!|findstr /i /b "Server" %_Nul3% && (set _SrvESD=1&set _ESDSrv%1=1)
set "_wsr=Windows Server 2022"
if !_ESDSrv%1! equ 1 (
find /i "<NAME>" bin\info.txt %_Nul2% | find /i " 2025" %_Nul1% && (set "_wsr=Windows Server 2025")
if !_obuild%1! geq 26010 (set "_wsr=Windows Server 2025")
)
if !_ESDSrv%1! equ 1 findstr /i /c:"Server Core" bin\info.txt %_Nul3% && (
if /i "!edition%1!"=="ServerStandard" set "edition%1=ServerStandardCore"
if /i "!edition%1!"=="ServerDatacenter" set "edition%1=ServerDatacenterCore"
if /i "!edition%1!"=="ServerTurbine" set "edition%1=ServerTurbineCore"
)
set uLang=0
for %%# in (ru-ru,zh-cn,zh-tw,zh-hk) do if /i !langid%1!==%%# set uLang=1
if %uLang% equ 1 for %%# in (
"Cloud:%_wtx% S"
"CloudN:%_wtx% S N"
"CloudE:%_wtx% Lean"
"CloudEN:%_wtx% Lean N"
"CloudEdition:%_wtx% SE"
"CloudEditionN:%_wtx% SE N"
"CloudEditionL:%_wtx% LE"
"CloudEditionLN:%_wtx% LE N"
"Core:%_wtx% Home"
"CoreN:%_wtx% Home N"
"CoreSingleLanguage:%_wtx% Home Single Language"
"CoreCountrySpecific:%_wtx% Home China"
"Professional:%_wtx% Pro"
"ProfessionalN:%_wtx% Pro N"
"ProfessionalEducation:%_wtx% Pro Education"
"ProfessionalEducationN:%_wtx% Pro Education N"
"ProfessionalWorkstation:%_wtx% Pro for Workstations"
"ProfessionalWorkstationN:%_wtx% Pro N for Workstations"
"ProfessionalSingleLanguage:%_wtx% Pro Single Language"
"ProfessionalCountrySpecific:%_wtx% Pro China Only"
"PPIPro:%_wtx% Team"
"Education:%_wtx% Education"
"EducationN:%_wtx% Education N"
"Enterprise:%_wtx% Enterprise"
"EnterpriseN:%_wtx% Enterprise N"
"EnterpriseG:%_wtx% Enterprise G"
"EnterpriseGN:%_wtx% Enterprise G N"
"EnterpriseS:%_wtx% Enterprise LTSC"
"EnterpriseSN:%_wtx% Enterprise N LTSC"
"IoTEnterprise:%_wtx% IoT Enterprise"
"IoTEnterpriseS:%_wtx% IoT Enterprise LTSC"
"IoTEnterpriseK:%_wtx% IoT Enterprise Subscription"
"IoTEnterpriseSK:%_wtx% IoT Enterprise LTSC Subscription"
"ServerRdsh:%_wtx% Enterprise multi-session"
"Starter:%_wtx% Starter"
"StarterN:%_wtx% Starter N"
"ServerStandardCore:%_wsr% Standard"
"ServerStandard:%_wsr% Standard (Desktop Experience)"
"ServerDatacenterCore:%_wsr% Datacenter"
"ServerDatacenter:%_wsr% Datacenter (Desktop Experience)"
"ServerTurbineCore:%_wsr% Datacenter Azure Edition"
"ServerTurbine:%_wsr% Datacenter Azure Edition (Desktop Experience)"
"ServerAzureStackHCICor:Azure Stack HCI"
) do for /f "tokens=1,2 delims=:" %%A in ("%%~#") do (
if !edition%1!==%%A set "_oname%1=%%B"
)
set "_name%1=!_oname%1! [!arch%1! / !langid%1!]"
del /f /q bin\info*.txt
exit /b

:uups_dpx
set _nat=0
set _wow=0
if /i %arch%==%xOS% set _nat=1
if /i %arch%==x64 if /i %xOS%==amd64 set _nat=1
if %_nat% equ 0 set _wow=1
set msuwim=0
set "uupmsu="
if exist "!_UUP!\*Windows1*-KB*.msu" for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\*Windows1*-KB*.msu"') do (
expand.exe -d -f:*Windows*.psf "!_UUP!\%%#" %_Nul2% | findstr /i %arch%\.psf %_Nul3% && (set "uupmsu=%%#")
wimlib-imagex.exe dir "!_UUP!\%%#" %_Nul2% | findstr /i %arch%\.psf %_Nul3% && (set "uupmsu=%%#"&set msuwim=1)
)
if defined uupmsu if %msuwim% equ 0 (
if %_wow% equ 1 expand.exe -f:DesktopDeployment_x86.cab "!_UUP!\%uupmsu%" .\temp %_Null%
if %_nat% equ 1 expand.exe -f:DesktopDeployment.cab "!_UUP!\%uupmsu%" .\temp %_Null%
)
if defined uupmsu if %msuwim% equ 1 (
if %_wow% equ 1 wimlib-imagex.exe extract "!_UUP!\%uupmsu%" 1 DesktopDeployment_x86.cab --dest-dir=.\temp %_Nul3%
if %_nat% equ 1 wimlib-imagex.exe extract "!_UUP!\%uupmsu%" 1 DesktopDeployment.cab --dest-dir=.\temp %_Nul3%
)
if %_wow% equ 1 (
if exist "temp\DesktopDeployment_x86.cab" (expand.exe -f:dpx.dll "temp\DesktopDeployment_x86.cab" .\temp %_Null%) else (wimlib-imagex.exe extract %_file% 1 Windows\SysWOW64\dpx.dll --dest-dir=.\temp --no-acls --no-attributes %_Nul3%)
if exist "temp\dpx.dll" copy /y %SystemRoot%\SysWOW64\expand.exe temp\ %_Nul3%
)
if %_nat% equ 1 (
if exist "temp\DesktopDeployment.cab" (expand.exe -f:dpx.dll "temp\DesktopDeployment.cab" .\temp %_Null%) else (wimlib-imagex.exe extract %_file% 1 Windows\System32\dpx.dll --dest-dir=.\temp --no-acls --no-attributes %_Nul3%)
if exist "temp\dpx.dll" copy /y %SysPath%\expand.exe temp\ %_Nul3%
)
exit /b

:uups_msu
call :dk_color1 %Blue% "=== Creating Cumulative Update MSU . . ." 4
pushd "!_UUP!"
set "_MSUdll=dpx.dll ReserveManager.dll TurboStack.dll UpdateAgent.dll UpdateCompression.dll wcp.dll"
set "_MSUonf=onepackage.AggregatedMetadata.cab"
set "_MSUssu="
set IncludeSSU=1
set _mcfail=0
for /f "delims=" %%# in ('dir /b /a:-d "*.AggregatedMetadata*.cab"') do set "_MSUmeta=%%#"
if exist "_tMSU\" rmdir /s /q "_tMSU\" %_Nul3%
mkdir "_tMSU"
expand.exe -f:LCUCompDB*.xml.cab "%_MSUmeta%" "_tMSU" %_Null%
if not exist "_tMSU\LCUCompDB*.xml.cab" (
echo.
echo LCUCompDB file is missing from AggregatedMetadata, skip operation.
(echo.&echo LCUCompDB file is missing from AggregatedMetadata)>>"!logerr!"
goto :msu_uups
)
for /f %%# in ('dir /b /a:-d "_tMSU\LCUCompDB*.xml.cab"') do set "_MSUcdb=%%#"
for /f "tokens=2 delims=_." %%# in ('echo %_MSUcdb%') do set "_MSUkbn=%%#"
if exist "*Windows1*%_MSUkbn%*%arch%*.msu" (
echo.
echo LCU %_MSUkbn% msu file already exist, skip operation.
goto :msu_uups
)
if not exist "*Windows1*%_MSUkbn%*%arch%*.cab" (
echo.
echo LCU %_MSUkbn% cab file is missing, skip operation.
(echo.&echo LCU %_MSUkbn% cab file is missing)>>"!logerr!"
goto :msu_uups
)
if not exist "*Windows1*%_MSUkbn%*%arch%*.psf" (
echo.
echo LCU %_MSUkbn% psf file is missing, skip operation.
(echo.&echo LCU %_MSUkbn% psf file is missing)>>"!logerr!"
goto :msu_uups
)
for /f "delims=" %%# in ('dir /b /a:-d "*Windows1*%_MSUkbn%*%arch%*.cab"') do set "_MSUcab=%%#"
for /f "delims=" %%# in ('dir /b /a:-d "*Windows1*%_MSUkbn%*%arch%*.psf"') do set "_MSUpsf=%%#"
set "_MSUkbf=Windows10.0-%_MSUkbn%-%arch%"
echo %_MSUcab%| findstr /i "Windows11\." %_Nul1% && set "_MSUkbf=Windows11.0-%_MSUkbn%-%arch%"
echo %_MSUcab%| findstr /i "Windows12\." %_Nul1% && set "_MSUkbf=Windows12.0-%_MSUkbn%-%arch%"
if exist "SSU-*%arch%*.cab" (
for /f "tokens=2 delims=-" %%# in ('dir /b /a:-d "SSU-*%arch%*.cab"') do set "_MSUtsu=SSU-%%#-%arch%.cab"
for /f "delims=" %%# in ('dir /b /a:-d "SSU-*%arch%*.cab"') do set "_MSUssu=%%#"
expand.exe -f:SSUCompDB*.xml.cab "%_MSUmeta%" "_tMSU" %_Null%
if exist "_tMSU\SSU*-express.xml.cab" del /f /q "_tMSU\SSU*-express.xml.cab"
if not exist "_tMSU\SSUCompDB*.xml.cab" set IncludeSSU=0
) else (
set IncludeSSU=0
)
if %IncludeSSU% equ 1 for /f %%# in ('dir /b /a:-d "_tMSU\SSUCompDB*.xml.cab"') do set "_MSUsdb=%%#"
set "_MSUddd=DesktopDeployment_x86.cab"
if exist "*DesktopDeployment*.cab" (
for /f "delims=" %%# in ('dir /b /a:-d "*DesktopDeployment*.cab" ^|find /i /v "%_MSUddd%"') do set "_MSUddc=%%#"
) else (
call set "_MSUddc=_tMSU\DesktopDeployment.cab"
call set "_MSUddd=_tMSU\DesktopDeployment_x86.cab"
call :DDCAB
)
if %_mcfail% equ 1 goto :msu_uups
if /i not %arch%==x86 if not exist "DesktopDeployment_x86.cab" if not exist "_tMSU\DesktopDeployment_x86.cab" (
call set "_MSUddd=_tMSU\DesktopDeployment_x86.cab"
call :DDC86
)
if %_mcfail% equ 1 goto :msu_uups
call :crDDF _tMSU\%_MSUonf%
(echo "_tMSU\%_MSUcdb%" "%_MSUcdb%"
if %IncludeSSU% equ 1 echo "_tMSU\%_MSUsdb%" "%_MSUsdb%"
)>>zzz.ddf
%_Null% makecab.exe /F zzz.ddf /D Compress=ON /D CompressionType=MSZIP
if %ERRORLEVEL% neq 0 (
call :dk_color1 %Red% "makecab.exe %_MSUonf% failed, skip operation." 4
(echo.&echo makecab.exe %_MSUonf% failed)>>"!logerr!"
goto :msu_uups
)
call :crDDF %_MSUkbf%.msu
(echo "%_MSUddc%" "DesktopDeployment.cab"
if /i not %arch%==x86 echo "%_MSUddd%" "DesktopDeployment_x86.cab"
echo "_tMSU\%_MSUonf%" "%_MSUonf%"
if %IncludeSSU% equ 1 echo "%_MSUssu%" "%_MSUtsu%"
echo "%_MSUcab%" "%_MSUkbf%.cab"
echo "%_MSUpsf%" "%_MSUkbf%.psf"
)>>zzz.ddf
%_Null% makecab.exe /F zzz.ddf /D Compress=OFF
if %ERRORLEVEL% neq 0 (
call :dk_color1 %Red% "makecab.exe %_MSUkbf%.msu failed, skip operation." 4
(echo.&echo makecab.exe %_MSUkbf%.msu failed)>>"!logerr!"
goto :msu_uups
)

:msu_uups
if exist "zzz.ddf" del /f /q "zzz.ddf"
if exist "_tSSU\" rmdir /s /q "_tSSU\" %_Nul3%
rmdir /s /q "_tMSU\" %_Nul3%
popd
exit /b

:DDCAB
echo.
echo Extracting required files...
if exist "_tSSU\" rmdir /s /q "_tSSU\" %_Nul3%
mkdir "_tSSU\000"
if not defined _MSUssu goto :ssuinner64
expand.exe -f:* "%_MSUssu%" "_tSSU" %_Null% || goto :ssuinner64
goto :ssuouter64
:ssuinner64
popd
for /f %%# in ('wimlib-imagex.exe dir %_file% 1 --path=Windows\WinSxS\Manifests ^| find /i "_microsoft-windows-servicingstack_"') do (
wimlib-imagex.exe extract %_file% 1 Windows\WinSxS\%%~n# --dest-dir="!_UUP!\_tSSU" --no-acls --no-attributes %_Nul3%
)
pushd "!_UUP!"
:ssuouter64
set btx=%arch%
if /i %arch%==x64 set btx=amd64
for /f %%# in ('dir /b /ad "_tSSU\%btx%_microsoft-windows-servicingstack_*"') do set "src=%%#"
for %%# in (%_MSUdll%) do if exist "_tSSU\%src%\%%#" (move /y "_tSSU\%src%\%%#" "_tSSU\000\%%#" %_Nul1%)
call :crDDF %_MSUddc%
call :apDDF _tSSU\000
%_Null% makecab.exe /F zzz.ddf /D Compress=ON /D CompressionType=MSZIP
if %ERRORLEVEL% neq 0 (
call :dk_color1 %Red% "makecab.exe %_MSUddc% failed, skip operation." 4
(echo.&echo makecab.exe %_MSUddc% failed)>>"!logerr!"
set _mcfail=1
exit /b
)
mkdir "_tSSU\111"
if /i not %arch%==x86 if not exist "DesktopDeployment_x86.cab" goto :DDCdual
rmdir /s /q "_tSSU\" %_Nul3%
exit /b

:DDC86
echo.
echo Extracting required files...
if exist "_tSSU\" rmdir /s /q "_tSSU\" %_Nul3%
mkdir "_tSSU\111"
if not defined _MSUssu goto :ssuinner86
expand.exe -f:* "%_MSUssu%" "_tSSU" %_Null% || goto :ssuinner86
goto :ssuouter86
:ssuinner86
popd
for /f %%# in ('wimlib-imagex.exe dir %_file% 1 --path=Windows\WinSxS\Manifests ^| find /i "x86_microsoft-windows-servicingstack_"') do (
wimlib-imagex.exe extract %_file% 1 Windows\WinSxS\%%~n# --dest-dir="!_UUP!\_tSSU" --no-acls --no-attributes %_Nul3%
)
pushd "!_UUP!"
:ssuouter86
:DDCdual
for /f %%# in ('dir /b /ad "_tSSU\x86_microsoft-windows-servicingstack_*"') do set "src=%%#"
for %%# in (%_MSUdll%) do if exist "_tSSU\%src%\%%#" (move /y "_tSSU\%src%\%%#" "_tSSU\111\%%#" %_Nul1%)
call :crDDF %_MSUddd%
call :apDDF _tSSU\111
%_Null% makecab.exe /F zzz.ddf /D Compress=ON /D CompressionType=MSZIP
if %ERRORLEVEL% neq 0 (
call :dk_color1 %Red% "makecab.exe %_MSUddd% failed, skip operation." 4
(echo.&echo makecab.exe %_MSUddd% failed)>>"!logerr!"
set _mcfail=1
exit /b
)
rmdir /s /q "_tSSU\" %_Nul3%
exit /b

:crDDF
echo.
echo Creating: %~nx1
(echo .Set DiskDirectoryTemplate="."
echo .Set CabinetNameTemplate="%1"
echo .Set MaxCabinetSize=0
echo .Set MaxDiskSize=0
echo .Set FolderSizeThreshold=0
echo .Set RptFileName=nul
echo .Set InfFileName=nul
echo .Set Cabinet=ON
)>zzz.ddf
exit /b

:apDDF
(echo .Set SourceDir="%1"
echo "dpx.dll"
echo "ReserveManager.dll"
echo "TurboStack.dll"
echo "UpdateAgent.dll"
echo "wcp.dll"
if exist "%1\UpdateCompression.dll" echo "UpdateCompression.dll"
)>>zzz.ddf
exit /b

:uups_backup
if not exist "!_work!\temp\*.ESD" exit /b
call :dk_color1 %Blue% "=== Backing up Reference ESDs . . ." 4
if %EXPRESS% equ 1 (
mkdir "!_work!\CanonicalUUP" %_Nul3%
move /y "!_work!\temp\*.ESD" "!_work!\CanonicalUUP\" %_Nul3%
for /L %%# in (1,1,%uups_esd_num%) do copy /y "!_UUP!\!uups_esd%%#!" "!_work!\CanonicalUUP\" %_Nul3%
for /f %%# in ('dir /b /a:-d "!_UUP!\*Package*.ESD" %_Nul6%') do if not exist "!_work!\CanonicalUUP\%%#" (copy /y "!_UUP!\%%#" "!_work!\CanonicalUUP\" %_Nul3%)
exit /b
)
mkdir "!_UUP!\Original" %_Nul3%
move /y "!_work!\temp\*.ESD" "!_UUP!\" %_Nul3%
for /f %%# in ('dir /b /a:-d "!_UUP!\*.CAB"') do (
echo %%#| findstr /i /r "Windows.*-KB SSU-.* DesktopDeployment AggregatedMetadata" %_Nul1% || move /y "!_UUP!\%%#" "!_UUP!\Original\" %_Nul3%
)
exit /b

:uups_du
set isoupdate=
for /f "tokens=* delims=" %%# in ('dir /b /a:-d "!_UUP!\*Windows1*-KB*.cab"') do (
	del /f /q temp\update.mum %_Null%
	expand.exe -f:update.mum "!_UUP!\%%#" .\temp %_Null%
	if not exist "temp\update.mum" set isoupdate=!isoupdate! "%%#"
)
if not defined isoupdate goto :undu
call :dk_color1 %Blue% "=== Adding setup dynamic update{s} . . ." 4 5
mkdir "%_cabdir%\du" %_Nul3%
for %%# in (!isoupdate!) do (
echo %%~#
expand.exe -r -f:* "!_UUP!\%%~#" "%_cabdir%\du" %_Nul1%
)
xcopy /CDRUY "%_cabdir%\du" "ISOFOLDER\sources\" %_Nul3%
if exist "%_cabdir%\du\*.ini" xcopy /CDRY "%_cabdir%\du\*.ini" "ISOFOLDER\sources\" %_Nul3%
for /f %%# in ('dir /b /ad "%_cabdir%\du\*-*" %_Nul6%') do if exist "ISOFOLDER\sources\%%#\*.mui" copy /y "%_cabdir%\du\%%#\*" "ISOFOLDER\sources\%%#\" %_Nul3%
if exist "%_cabdir%\du\replacementmanifests\" xcopy /CERY "%_cabdir%\du\replacementmanifests" "ISOFOLDER\sources\replacementmanifests\" %_Nul3%
rmdir /s /q "%_cabdir%\du\" %_Nul3%

:undu
if not exist "%SystemRoot%\temp\" mkdir "%SystemRoot%\temp" %_Nul3%
copy /y ISOFOLDER\sources\UpdateAgent.dll %SystemRoot%\temp\ %_Nul1%
copy /y ISOFOLDER\sources\Facilitator.dll %SystemRoot%\temp\ %_Nul1%
set chkmin=%uupmin%
call :setuphostprep
for /f "tokens=4-7 delims=.() " %%i in ('"findstr /i /b "FileVersion" .\bin\version.txt" %_Nul6%') do (set xduver=%%i.%%j&set xdumaj=%%i&set xdumin=%%j&set xdubranch=%%k&set xdudate=%%l)
del /f /q .\bin\version.txt %_Nul3%
if %uupmin% neq %xdumin% exit /b
if /i "%xdubranch%"=="WinBuild" exit /b
if /i "%xdubranch%"=="GitEnlistment" exit /b
if /i "%xdudate%"=="winpbld" exit /b
set tmpval=tmpval
call :fixVerBrn %uupmaj% xdubranch xduver tmpval
set _label=%xduver%.%xdudate%.%xdubranch%
call :setlabel
exit /b

:uups_external
call :dk_color1 %Blue% "=== Adding updates files to ISO distribution . . ." 4 5
if not exist "!_cabdir!\" mkdir "!_cabdir!"
set "_dest=ISOFOLDER\sources\$OEM$\$1\UUP"
if not exist "!_dest!\" mkdir "!_dest!"
copy /y bin\Updates.bat "!_dest!\" %_Nul3%
if %_build% geq 18362 for /f "tokens=* delims=" %%# in ('dir /b /os "!_UUP!\*Windows1*-KB*.cab"') do (
expand.exe -f:microsoft-windows-*enablement-package~*.mum "!_UUP!\%%#" "!_cabdir!" %_Nul3%
call :EKB1 "!_cabdir!" _actEP 1
)
call :EKB2 "!_cabdir!"
set tmpcmp=
if %_build% geq 21382 if exist "!_UUP!\*Windows1*-KB*.msu" for /f "tokens=* delims=" %%# in ('dir /b /os "!_UUP!\*Windows1*-KB*.msu"') do (set "packn=%%~n#"&set "packf=%%#"&call :external_msu)
if exist "!_UUP!\SSU-*-*.cab" for /f "tokens=* delims=" %%# in ('dir /b /os "!_UUP!\SSU-*-*.cab"') do (set "packn=%%~n#"&set "packf=%%#"&call :external_cab)
if exist "!_UUP!\*Windows1*-KB*.cab" for /f "tokens=* delims=" %%# in ('dir /b /os "!_UUP!\*Windows1*-KB*.cab"') do (set "packn=%%~n#"&set "packf=%%#"&call :external_cab)
if defined tmpcmp if exist "!_UUP!\Windows1?.?-*%arch%_inout.cab" for /f "tokens=* delims=" %%# in ('dir /b /os "!_UUP!\Windows1?.?-*%arch%_inout.cab"') do (set "packn=%%~n#"&set "packf=%%#"&call :external_cab)
if not exist "!_dest!\*Windows1*-KB*.msu" if not exist "!_dest!\*Windows1*-KB*.cab" if not exist "!_dest!\*SSU-*-*.cab" (
rmdir /s /q "ISOFOLDER\sources\$OEM$\"
exit /b
)
if %NetFx3% equ 1 if exist "ISOFOLDER\sources\sxs\*NetFx3*.cab" call :external_netfx
call :dk_color1 %Blue% "=== Updating %WIMFILE% registry . . ." 4
for /f "tokens=3 delims=: " %%# in ('wimlib-imagex.exe info ISOFOLDER\sources\%WIMFILE% ^| findstr /c:"Image Count"') do set imgcount=%%#
for /L %%# in (1,1,%imgcount%) do (
wimlib-imagex.exe extract ISOFOLDER\sources\%WIMFILE% %%# Windows\System32\config\SYSTEM --dest-dir=.\bin\temp --no-acls --no-attributes %_Null%
%_Nul3% offlinereg.exe .\bin\temp\SYSTEM Setup createkey FirstBoot
%_Nul3% offlinereg.exe .\bin\temp\SYSTEM.new Setup\FirstBoot createkey PostSysprep
%_Nul3% offlinereg.exe .\bin\temp\SYSTEM.new Setup\FirstBoot\PostSysprep setvalue uup "cmd.exe /c %%systemdrive%%\$WINDOWS.~BT\Sources\SetupPlatform.exe /postsysprep 2>nul&%%systemdrive%%\UUP\Updates.bat &reg delete HKLM\SYSTEM\Setup\FirstBoot\PostSysprep /v 0 /f 2>nul&reg delete HKLM\SYSTEM\Setup\FirstBoot\PostSysprep /v uup /f &exit /b 0 "
del /f /q .\bin\temp\SYSTEM
ren .\bin\temp\SYSTEM.new SYSTEM
type nul>bin\install-wim.txt
>>bin\install-wim.txt echo add 'bin^\temp^\SYSTEM' '^\Windows^\System32^\config^\SYSTEM'
wimlib-imagex.exe update ISOFOLDER\sources\%WIMFILE% %%# < bin\install-wim.txt %_Null%
del /f /q bin\install-wim.txt
rmdir /s /q bin\temp\
)
if %imgcount% gtr 1 if %WIMFILE%==install.wim (
call :dk_color1 %Blue% "=== Rebuilding %WIMFILE% . . ." 4 5
%_wrb% wimlib-imagex.exe optimize ISOFOLDER\sources\%WIMFILE% %_Supp%
)
exit /b

:external_cab
for /f "tokens=2 delims=-" %%V in ('echo %packn%') do set packid=%%V
set "uupmsu="
if %_build% geq 21382 if exist "!_UUP!\*Windows1*%packid%*%arch%*.msu" for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\*Windows1*%packid%*%arch%*.msu"') do (
set "uupmsu=%%#"
)
if defined uupmsu (
expand.exe -d -f:*Windows*.psf "!_UUP!\%uupmsu%" %_Nul2% | findstr /i %arch%\.psf %_Nul3% && goto :eof
wimlib-imagex.exe dir "!_UUP!\%uupmsu%" %_Nul2% | findstr /i %arch%\.psf %_Nul3% && goto :eof
)
if exist "!_cabdir!\*.manifest" del /f /q "!_cabdir!\*.manifest" %_Nul3%
if exist "!_cabdir!\*.mum" del /f /q "!_cabdir!\*.mum" %_Nul3%
if exist "!_cabdir!\*.xml" del /f /q "!_cabdir!\*.xml" %_Nul3%
:: expand.exe -f:update.mum "!_UUP!\%packf%" "!_cabdir!" %_Null%
7z.exe e "!_UUP!\%packf%" -o"!_cabdir!" update.mum -aoa %_Null%
if not exist "!_cabdir!\update.mum" exit /b
expand.exe -f:*.psf.cix.xml "!_UUP!\%packf%" "!_cabdir!" %_Null%
if exist "!_cabdir!\*.psf.cix.xml" (
if not exist "!_UUP!\%packn%.psf" if not exist "!_UUP!\*%packid%*%arch%*.psf" (
  call :dk_color1 %Red% "PSFX: %packf% / PSF file is missing"
  (echo.&echo %packf% / PSF file is missing)>>"!logerr!"
  exit /b
  )
if %psfnet% equ 0 (
  call :dk_color1 %Red% "PSFX: %packf% / PSFExtractor is not available"
  (echo.&echo %packf% / PSFExtractor is not available)>>"!logerr!"
  exit /b
  )
set psf_%packn%=1
)
findstr /i /m "Package_for_OasisAsset" "!_cabdir!\update.mum" %_Nul3% && (
wimlib-imagex.exe extract ISOFOLDER\sources\%WIMFILE% 1 Windows\Servicing\Packages\*OasisAssets-Package*.mum --dest-dir="!_cabdir!" --no-acls --no-attributes %_Null%
if not exist "!_cabdir!\*OasisAssets-Package*.mum" exit /b
)
expand.exe -f:toc.xml "!_UUP!\%packf%" "!_cabdir!" %_Null%
if exist "!_cabdir!\toc.xml" (
echo LCU: %packf% [Combined]
mkdir "!_cabdir!\lcu" %_Nul3%
expand.exe -f:* "!_UUP!\%packf%" "!_cabdir!\lcu" %_Null%
if exist "!_cabdir!\lcu\SSU-*%arch%*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_cabdir!\lcu\SSU-*%arch%*.cab"') do (set "compkg=%%#"&call :inrenssu)
if exist "!_cabdir!\lcu\*Windows1*-KB*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_cabdir!\lcu\*Windows1*-KB*.cab"') do (set "compkg=%%#"&call :inrenupd)
rmdir /s /q "!_cabdir!\lcu\" %_Nul3%
exit /b
)
if %_build% geq 17763 findstr /i /m "WinPE" "!_cabdir!\update.mum" %_Nul3% && (
%_Nul3% findstr /i /m "Edition\"" "!_cabdir!\update.mum"
if errorlevel 1 exit /b
)
expand.exe -f:*_microsoft-windows-servicingstack_*.manifest "!_UUP!\%packf%" "!_cabdir!" %_Null%
if exist "!_cabdir!\*servicingstack_*.manifest" (
echo SSU: %packf%
copy /y "!_UUP!\%packf%" "!_dest!\1%packf%" %_Nul3%
exit /b
)
set lculabel=1
findstr /i /m "Package_for_RollupFix" "!_cabdir!\update.mum" %_Nul3% && (
if defined psf_%packn% (
  echo LCU: %packf% / Repacking PSF update
  call :external_psf
  ) else (
  echo LCU: %packf%
  copy /y "!_UUP!\%packf%" "!_dest!\3%packf%" %_Nul3%
  )
if !lculabel! equ 1 call :external_label
exit /b
)
echo UPD: %packf%
copy /y "!_UUP!\%packf%" "!_dest!\2%packf%" %_Nul3%
exit /b

:external_msu
if exist "!_cabdir!\*.manifest" del /f /q "!_cabdir!\*.manifest" %_Nul3%
if exist "!_cabdir!\*.mum" del /f /q "!_cabdir!\*.mum" %_Nul3%
if exist "!_cabdir!\*.xml" del /f /q "!_cabdir!\*.xml" %_Nul3%
set msuwim=0
expand.exe -d -f:*Windows*.psf "!_UUP!\%packf%" %_Nul2% | findstr /i %arch%\.psf %_Nul3% || (
wimlib-imagex.exe dir "!_UUP!\%packf%" %_Nul2% | findstr /i %arch%\.psf %_Nul3% && (set msuwim=1) || (goto :eof)
)
echo LCU: %packf% [Combined UUP]
copy /y "!_UUP!\%packf%" "!_dest!\3%packf%" %_Nul3%
mkdir "!_cabdir!\lcu" %_Nul3%
if %msuwim% equ 0 (
expand.exe -f:*Windows*.cab "!_UUP!\%packf%" "!_cabdir!\lcu" %_Null%
expand.exe -f:SSU-*%arch%*.cab "!_UUP!\%packf%" "!_cabdir!\lcu" %_Null%
) else (
wimlib-imagex.exe extract "!_UUP!\%packf%" 1 *Windows*.wim --dest-dir="!_cabdir!\lcu" %_Nul3%
wimlib-imagex.exe extract "!_UUP!\%packf%" 1 SSU-*%arch%*.cab --dest-dir="!_cabdir!\lcu" %_Nul3%
)
for /f "tokens=* delims=" %%# in ('dir /b /on "!_cabdir!\lcu\*Windows1*-KB*.*"') do set "compkg=%%#"
7z.exe e "!_cabdir!\lcu\%compkg%" -o"!_cabdir!" update.mum -aoa %_Null%
7z.exe e "!_cabdir!\lcu\%compkg%" -o"!_cabdir!" %_ss%_microsoft-windows-coreos-revision*.manifest -aoa %_Null%
7z.exe e "!_cabdir!\lcu\%compkg%" -o"!_cabdir!" %_ss%_microsoft-updatetargeting-*os_*.manifest -aoa %_Null%
if exist "!_cabdir!\lcu\SSU-*%arch%*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_cabdir!\lcu\SSU-*%arch%*.cab"') do (set "compkg=%%#"&call :inrenssu)
rmdir /s /q "!_cabdir!\lcu\" %_Nul3%
call :external_label
exit /b

:external_netfx
for /f %%# in ('dir /b /os "ISOFOLDER\sources\sxs\*NetFx3*.cab"') do set "ndp=%%#"
echo DNF: %ndp%
copy /y "ISOFOLDER\sources\sxs\%ndp%" "!_dest!\" %_Nul3%
exit /b

:external_label
if not exist "%SystemRoot%\temp\" mkdir "%SystemRoot%\temp" %_Nul3%
copy /y "!_cabdir!\update.mum" %SystemRoot%\temp\ %_Nul1%
call :datemum isodate isotime

if exist "!_cabdir!\*cablist.ini" del /f /q "!_cabdir!\*cablist.ini" %_Nul3%
expand.exe -f:*cablist.ini "!_UUP!\%packf%" "!_cabdir!" %_Null%
if not exist "!_cabdir!\*_microsoft-windows-coreos-revision*.manifest" if exist "!_cabdir!\*cablist.ini" (
expand.exe -f:*.cab "!_UUP!\%packf%" "!_cabdir!" %_Null%
expand.exe -f:%_ss%_microsoft-windows-coreos-revision*.manifest "!_cabdir!\Cab*.cab" "!_cabdir!" %_Null%
)
if not exist "!_cabdir!\*_microsoft-windows-coreos-revision*.manifest" if not exist "!_cabdir!\*cablist.ini" (
expand.exe -f:%_ss%_microsoft-windows-coreos-revision*.manifest "!_UUP!\%packf%" "!_cabdir!" %_Null%
)
if exist "!_cabdir!\*_microsoft-windows-coreos-revision*.manifest" for /f "tokens=%tok% delims=_." %%i in ('dir /b /a:-d /od "!_cabdir!\*_microsoft-windows-coreos-revision*.manifest"') do (set uupver=%%i.%%j&set uupmaj=%%i&set uupmin=%%j)
if exist "!_cabdir!\Cab*.cab" del /f /q "!_cabdir!\Cab*.cab" %_Nul3%

if not exist "!_cabdir!\*_microsoft-updatetargeting-*os_*.manifest" (
expand.exe -f:%_ss%_microsoft-updatetargeting-*os_*.manifest "!_UUP!\%packf%" "!_cabdir!" %_Null%
)
if %_build% geq 21382 if exist "!_cabdir!\*_microsoft-updatetargeting-*os_*.manifest" (
mkdir bin\sxs
for /f %%a in ('dir /b /a:-d "!_cabdir!\*_microsoft-updatetargeting-*os_*.manifest"') do SxSExpand.exe "!_cabdir!\%%a" "bin\sxs\%%a" %_Nul3%
if exist "bin\sxs\*.manifest" move /y "bin\sxs\*" "!_cabdir!\" %_Nul1%
rmdir /s /q bin\sxs\
)
if exist "!_cabdir!\*_microsoft-updatetargeting-*os_*.manifest" for /f "tokens=8 delims== " %%# in ('findstr /i Branch "!_cabdir!\*_microsoft-updatetargeting-*os_*.manifest"') do if not defined regbranch set regbranch=%%~#
if defined regbranch set branch=%regbranch%
set "wnt=%_Pkt%_10"
if exist "!_cabdir!\*_microsoft-updatetargeting-*os_%_Pkt%_11.*.manifest" set "wnt=%_Pkt%_11"
if exist "!_cabdir!\*_microsoft-updatetargeting-*os_%_Pkt%_12.*.manifest" set "wnt=%_Pkt%_12"
if %_actEP% equ 1 if exist "!_cabdir!\*_microsoft-updatetargeting-*os_%wnt%.%_fixEP%*.manifest" (
for /f "tokens=8 delims== " %%# in ('findstr /i Branch "!_cabdir!\*_microsoft-updatetargeting-*os_%wnt%.%_fixEP%*.manifest"') do set branch=%%~#
for /f "tokens=%toe% delims=_." %%I in ('dir /b /a:-d /on "!_cabdir!\*_microsoft-updatetargeting-*os_%wnt%.%_fixEP%*.manifest"') do if %%I gtr !uupmaj! (
  set uupver=%%I.%%K
  set uupmaj=%%I
  set uupmin=%%K
  set "_fixSV=!uupmaj!"&set "_fixEP=!uupmaj!"
  )
)
call :fixBranch %uupmaj%
set _label=%uupver%.%isodate%.%branch%
call :setlabel
exit /b

:external_psf
set "lcuext=!_cabdir!\%packn%"
if not exist "!lcuext!\" mkdir "!lcuext!"
expand.exe -f:* "!_UUP!\%packf%" "!lcuext!" %_Null%
7z.exe e "!_UUP!\%packf%" -o"!lcuext!" update.mum -aoa %_Null%
if exist "!lcuext!\*cablist.ini" (
  expand.exe -f:* "!lcuext!\*.cab" "!lcuext!" %_Null%
  del /f /q "!lcuext!\*cablist.ini" %_Nul3%
  del /f /q "!lcuext!\*.cab" %_Nul3%
)
if not exist "!lcuext!\express.psf.cix.xml" for /f %%# in ('dir /b /a:-d "!lcuext!\*.psf.cix.xml"') do rename "!lcuext!\%%#" express.psf.cix.xml %_Nul3%
set _sbst=0
subst %_sdr% "!_cabdir!" %_Nul3% && set _sbst=1
if !_sbst! equ 1 pushd %_sdr%
if not exist "%packf%" (
copy /y "!_UUP!\%packn%.*" . %_Nul3%
if not exist "%packn%.psf" for /f %%# in ('dir /b /a:-d "!_UUP!\*%packid%*%arch%*.psf"') do copy /y "!_UUP!\%%#" %packn%.psf %_Nul3%
)
if not exist "PSFExtractor.exe" copy /y "!_work!\bin\PSFExtractor.*" . %_Nul3%
if not exist "cabarc.exe" copy /y "!_work!\bin\cabarc.exe" . %_Nul3%
PSFExtractor.exe %packf% %_Null%
if %errorlevel% neq 0 (
  set lculabel=0
  call :dk_color1 %Red% "Error: failed to extract %packn%.psf"
  (echo.&echo failed to extract %packn%.psf)>>"!logerr!"
  rmdir /s /q %packn% %_Nul3%
  if !_sbst! equ 1 popd
  if !_sbst! equ 1 subst %_sdr% /d %_Nul3%
  exit /b
  )
cd %packn%
del /f /q *.psf.cix.xml %_Nul3%
..\cabarc.exe -m LZX:21 -r -p N ..\3psf.cab *.* %_Null%
if %errorlevel% neq 0 (
  set lculabel=0
  call :dk_color1 %Red% "Error: failed to create %packf%"
  (echo.&echo failed to create %packf%)>>"!logerr!"
  cd..
  rmdir /s /q %packn% %_Nul3%
  if !_sbst! equ 1 popd
  if !_sbst! equ 1 subst %_sdr% /d %_Nul3%
  exit /b
  )
cd..
rmdir /s /q %packn% %_Nul3%
if !_sbst! equ 1 popd
if !_sbst! equ 1 subst %_sdr% /d %_Nul3%
move /y "!_cabdir!\3psf.cab" "!_dest!\3%packf%" %_Nul3%
exit /b

:uups_update
if %W10UI% equ 0 exit /b
set wim=0
set dvd=0
set _tgt=%1
set _upx=
set _upx=%2
if /i "%_tgt:~-4%"==".wim" (
set wim=1
set _target=%1
set _imgchk=%1
set _wimtrg=%~nx1
) else (
set dvd=1
set _target=ISOFOLDER
set _imgchk=ISOFOLDER\sources\%WIMFILE%
set _wimtrg=install.wim
)
for /f "tokens=3 delims=: " %%# in ('wimlib-imagex.exe info %_imgchk% ^| findstr /c:"Image Count"') do set imgcount=%%#
call :dk_color1 %Blue% "=== Updating %_wimtrg% / %imgcount% image{s} . . ." 4
if not defined _upx goto :noappx

::appx_update
if %wim% equ 1 call :updt_mount "%_target%" appx
if %dvd% equ 1 call :updt_mount "%_target%\sources\install.wim" appx
if exist "%_mount%\" rmdir /s /q "%_mount%\"
if %wim2esd% equ 1 exit /b
goto :rbldwim

:noappx
set directcab=0
call :extract
if %wim% equ 0 goto :dvdup
call :updt_mount "%_target%"

:dvdup
if %dvd% equ 0 goto :nodvd
if not exist "%SystemRoot%\temp\" mkdir "%SystemRoot%\temp" %_Nul3%
if exist "%SystemRoot%\temp\UpdateAgent.dll" del /f /q "%SystemRoot%\temp\UpdateAgent.dll" %_Nul3%
if exist "%SystemRoot%\temp\Facilitator.dll" del /f /q "%SystemRoot%\temp\Facilitator.dll" %_Nul3%
call :updt_mount "%_target%\sources\install.wim"

:nodvd
if exist "%_mount%\" rmdir /s /q "%_mount%\"
if %_build% geq 19041 if %winbuild% lss 17133 if exist "%SysPath%\ext-ms-win-security-slc-l1-1-0.dll" (
del /f /q %SysPath%\ext-ms-win-security-slc-l1-1-0.dll %_Nul3%
if /i not %xOS%==x86 del /f /q %SystemRoot%\SysWOW64\ext-ms-win-security-slc-l1-1-0.dll %_Nul3%
)

:rbldwim
set _wimopt=0
if %wim% equ 1 (
if /i %_target%==install.wim (if %wim2esd% equ 0 set _wimopt=1) else (if not defined _upx if %relite% equ 0 set _wimopt=1)
)
if %dvd% equ 1 if %wim2esd% equ 0 (
set _wimopt=1
if %AddUpdates% equ 2 if %_updexist% equ 1 for /f "tokens=3 delims=: " %%# in ('wimlib-imagex.exe info %_imgchk% ^| findstr /c:"Image Count"') do if %%# gtr 1 set _wimopt=0
)
if %_wimopt% equ 1 (
call :dk_color1 %Blue% "=== Rebuilding %_wimtrg% . . ." 4 5
)
if %wim% equ 1 (
%_wrb% if %_wimopt% equ 1 wimlib-imagex.exe optimize "%_target%" %_Supp%
exit /b
)
%_wrb% if %_wimopt% equ 1 wimlib-imagex.exe optimize "%_target%\sources\install.wim" %_Supp%
if defined _upx exit /b

for /f "tokens=3 delims=: " %%# in ('wimlib-imagex.exe info "%_target%\sources\install.wim" ^| findstr /c:"Image Count"') do set imgcount=%%#
for /L %%# in (1,1,%imgcount%) do (
  for /f "tokens=3 delims=<>" %%A in ('imagex /info "%_target%\sources\install.wim" %%# ^| find /i "<HIGHPART>"') do call set "HIGHPART=%%A"
  for /f "tokens=3 delims=<>" %%A in ('imagex /info "%_target%\sources\install.wim" %%# ^| find /i "<LOWPART>"') do call set "LOWPART=%%A"
  wimlib-imagex.exe info "%_target%\sources\install.wim" %%# --image-property CREATIONTIME/HIGHPART=!HIGHPART! --image-property CREATIONTIME/LOWPART=!LOWPART! %_Nul1%
)
if not defined isoupdate goto :nodu
call :dk_color1 %Blue% "=== Adding setup dynamic update{s} . . ." 4 5
mkdir "%_cabdir%\du" %_Nul3%
for %%# in (!isoupdate!) do (
echo %%~#
expand.exe -r -f:* "!_UUP!\%%~#" "%_cabdir%\du" %_Nul1%
)
xcopy /CDRUY "%_cabdir%\du" "ISOFOLDER\sources\" %_Nul3%
if exist "%_cabdir%\du\*.ini" xcopy /CDRY "%_cabdir%\du\*.ini" "ISOFOLDER\sources\" %_Nul3%
for /f %%# in ('dir /b /ad "%_cabdir%\du\*-*" %_Nul6%') do if exist "ISOFOLDER\sources\%%#\*.mui" copy /y "%_cabdir%\du\%%#\*" "ISOFOLDER\sources\%%#\" %_Nul3%
if exist "%_cabdir%\du\replacementmanifests\" xcopy /CERY "%_cabdir%\du\replacementmanifests" "ISOFOLDER\sources\replacementmanifests\" %_Nul3%
rmdir /s /q "%_cabdir%\du\" %_Nul3%

:nodu
if not defined isover exit /b
set chkmin=%isomin%
call :setuphostprep
for /f "tokens=4-7 delims=.() " %%i in ('"findstr /i /b "FileVersion" .\bin\version.txt" %_Nul6%') do (set iduver=%%i.%%j&set idumaj=%%i&set idumin=%%j&set branch=%%k&set idudate=%%l)
del /f /q .\bin\version.txt %_Nul3%
call :fixVerBrn %isomaj% isobranch iduver branch
set _label=%isover%.%isodate%.%isobranch%
if /i not "%branch%"=="WinBuild" if /i not "%branch%"=="GitEnlistment" if /i not "%idudate%"=="winpbld" (set _label=%iduver%.%idudate%.%branch%)
if %isomin% neq %idumin% (set _label=%isover%.%isodate%.%isobranch%)
call :setlabel
exit /b

:extract
if not exist "!_cabdir!\" mkdir "!_cabdir!"
set _cab=0
if %_build% geq 21382 if exist "!_UUP!\*Windows1*-KB*.msu" for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\*Windows1*-KB*.msu"') do (set "package=%%#"&call :sum2msu)
if exist "!_UUP!\*defender-dism*%arch%*.cab" for /f "tokens=* delims=" %%# in ('dir /b "!_UUP!\*defender-dism*%arch%*.cab"') do (call set /a _cab+=1)
if exist "!_UUP!\SSU-*-*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\SSU-*-*.cab"') do (call set /a _cab+=1)
if exist "!_UUP!\*Windows1*-KB*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\*Windows1*-KB*.cab"') do (set "pkgn=%%~n#"&call :sum2cab)
:: if %_cab% gtr 0 call :dk_color1 %Gray% "=== Extracting updates files . . ." 4 5
set count=0&set isoupdate=&set tmpcmp=
if %_build% geq 21382 if exist "!_UUP!\*Windows1*-KB*.msu" for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\*Windows1*-KB*.msu"') do (set "pkgn=%%~n#"&set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :msu2)
if exist "!_UUP!\*defender-dism*%arch%*.cab" for /f "tokens=* delims=" %%# in ('dir /b "!_UUP!\*defender-dism*%arch%*.cab"') do (set "pkgn=%%~n#"&set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :cab2)
if exist "!_UUP!\SSU-*-*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\SSU-*-*.cab"') do (set "pkgn=%%~n#"&set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :cab2)
if exist "!_UUP!\*Windows1*-KB*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\*Windows1*-KB*.cab"') do (set "pkgn=%%~n#"&set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :cab2)
if defined tmpcmp if exist "!_UUP!\Windows1?.?-*%arch%_inout.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\Windows1?.?-*%arch%_inout.cab"') do (set "pkgn=%%~n#"&set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :cab2)
goto :eof

:sum2msu
expand.exe -d -f:*Windows*.psf "!_UUP!\%package%" %_Nul2% | findstr /i %arch%\.psf %_Nul3% || (
wimlib-imagex.exe dir "!_UUP!\%package%" %_Nul2% | findstr /i %arch%\.psf %_Nul3% || goto :eof
)
call set /a _cab+=1
goto :eof

:sum2cab
for /f "tokens=2 delims=-" %%V in ('echo %pkgn%') do set pkgid=%%V
set "uupmsu="
if %_build% geq 21382 if exist "!_UUP!\*Windows1*%pkgid%*%arch%*.msu" for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\*Windows1*%pkgid%*%arch%*.msu"') do (
set "uupmsu=%%#"
)
if defined uupmsu (
expand.exe -d -f:*Windows*.psf "!_UUP!\%uupmsu%" %_Nul2% | findstr /i %arch%\.psf %_Nul3% && goto :eof
wimlib-imagex.exe dir "!_UUP!\%uupmsu%" %_Nul2% | findstr /i %arch%\.psf %_Nul3% && goto :eof
)
call set /a _cab+=1
goto :eof

:cab2
for /f "tokens=2 delims=-" %%V in ('echo %pkgn%') do set pkgid=%%V
set "uupmsu="
if %_build% geq 21382 if exist "!_UUP!\*Windows1*%pkgid%*%arch%*.msu" for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\*Windows1*%pkgid%*%arch%*.msu"') do (
set "uupmsu=%%#"
)
if defined uupmsu (
expand.exe -d -f:*Windows*.psf "!_UUP!\%uupmsu%" %_Nul2% | findstr /i %arch%\.psf %_Nul3% && goto :eof
wimlib-imagex.exe dir "!_UUP!\%uupmsu%" %_Nul2% | findstr /i %arch%\.psf %_Nul3% && goto :eof
)
if defined cab_%pkgn% goto :eof
if exist "!dest!\" rmdir /s /q "!dest!\"
mkdir "!dest!"
set /a count+=1
if %count% equ 1 echo.
:: expand.exe -f:update.mum "!_UUP!\%package%" "!dest!" %_Null%
7z.exe e "!_UUP!\%package%" -o"!dest!" update.mum -aoa %_Null%
if not exist "!dest!\update.mum" (
expand.exe -f:*defender*.xml "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\*defender*.xml" (
  if /i not "%_target%"=="temp\winre.wim" echo %count%/%_cab%: %package%
  if /i not "%_target%"=="temp\winre.wim" expand.exe -f:* "!_UUP!\%package%" "!dest!" %_Null%
  if /i "%_target%"=="temp\winre.wim" rmdir /s /q "!dest!\" %_Nul3%
) else (
  if not defined cab_%pkgn% echo %count%/%_cab%: %package% [Setup DU]
  set isoupdate=!isoupdate! "%package%"
  set cab_%pkgn%=1
  rmdir /s /q "!dest!\" %_Nul3%
  )
goto :eof
)
expand.exe -f:*.psf.cix.xml "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\*.psf.cix.xml" (
if not exist "!_UUP!\%pkgn%.psf" if not exist "!_UUP!\*%pkgid%*%arch%*.psf" (
  call :dk_color1 %Red% "%count%/%_cab%: %package% / PSF file is missing"
  (echo.&echo %package% / PSF file is missing)>>"!logerr!"
  goto :eof
  )
if %psfnet% equ 0 (
  call :dk_color1 %Red% "%count%/%_cab%: %package% / PSFExtractor is not available"
  (echo.&echo %package% / PSFExtractor is not available)>>"!logerr!"
  goto :eof
  )
set psf_%pkgn%=1
)
if not defined isodate findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% && (
call :chklcu
)
expand.exe -f:toc.xml "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\toc.xml" (
echo %count%/%_cab%: %package% [Combined]
mkdir "!_cabdir!\lcu" %_Nul3%
expand.exe -f:* "!_UUP!\%package%" "!_cabdir!\lcu" %_Null%
if exist "!_cabdir!\lcu\SSU-*%arch%*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_cabdir!\lcu\SSU-*%arch%*.cab"') do (set "compkg=%%#"&call :inrenssu)
if exist "!_cabdir!\lcu\*Windows1*-KB*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_cabdir!\lcu\*Windows1*-KB*.cab"') do (set "compkg=%%#"&call :inrenupd)
rmdir /s /q "!_cabdir!\lcu\" %_Nul3%
rmdir /s /q "!dest!\" %_Nul3%
goto :eof
)
set _extsafe=0
set "_type="
if %_build% geq 17763 findstr /i /m "WinPE" "!dest!\update.mum" %_Nul3% && (
%_Nul3% findstr /i /m "Edition\"" "!dest!\update.mum"
if errorlevel 1 (set "_type=[WinPE]"&set _extsafe=1&set uwinpe=1)
)
if not defined _type set _extsafe=1
if %_extsafe% equ 1 (
expand.exe -f:*_microsoft-windows-sysreset_*.manifest "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\*_microsoft-windows-sysreset_*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (set "_type=[SafeOS DU]"&set uwinpe=1)
)
if %_extsafe% equ 1 if not defined _type (
expand.exe -f:*_microsoft-windows-winpe_tools_*.manifest "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\*_microsoft-windows-winpe_tools_*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (set "_type=[SafeOS DU]"&set uwinpe=1)
)
if %_extsafe% equ 1 if not defined _type (
expand.exe -f:*_microsoft-windows-winre-tools_*.manifest "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\*_microsoft-windows-winre-tools_*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (set "_type=[SafeOS DU]"&set uwinpe=1)
)
if %_extsafe% equ 1 if not defined _type (
expand.exe -f:*_microsoft-windows-i..dsetup-rejuvenation_*.manifest "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\*_microsoft-windows-i..dsetup-rejuvenation_*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (set "_type=[SafeOS DU]"&set uwinpe=1)
)
if not defined _type (
findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% && (set "_type=[LCU]"&set uwinpe=1)
)
if not defined _type (
findstr /i /m "Package_for_WindowsExperienceFeaturePack" "!dest!\update.mum" %_Nul3% && set "_type=[UX FeaturePack]"
)
if not defined _type (
expand.exe -f:*_microsoft-windows-servicingstack_*.manifest "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\*_microsoft-windows-servicingstack_*.manifest" (
  set "_type=[SSU]"&set uwinpe=1
  findstr /i /m /c:"Microsoft-Windows-CoreEdition" "!dest!\update.mum" %_Nul3% || set _eosC=1
  findstr /i /m /c:"Microsoft-Windows-ProfessionalEdition" "!dest!\update.mum" %_Nul3% || set _eosP=1
  findstr /i /m /c:"Microsoft-Windows-PPIProEdition" "!dest!\update.mum" %_Nul3% || set _eosT=1
  )
)
if not defined _type (
expand.exe -f:*_netfx4*.manifest "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\*_netfx4*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || set "_type=[NetFx]"
)
if not defined _type (
expand.exe -f:*_microsoft-windows-s..boot-firmwareupdate_*.manifest "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\*_microsoft-windows-s..boot-firmwareupdate_*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || set "_type=[SecureBoot]"
)
if not defined _type if %_build% geq 18362 (
expand.exe -f:microsoft-windows-*enablement-package~*.mum "!_UUP!\%package%" "!dest!" %_Null%
call :EKB1 "!dest!" _type [Enablement]
)
call :EKB2 "!dest!"
if %_build% geq 18362 if exist "!dest!\*enablement-package*.mum" (
expand.exe -f:*_microsoft-windows-e..-firsttimeinstaller_*.manifest "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\*_microsoft-windows-e..-firsttimeinstaller_*.manifest" set "_type=[Enablement / EdgeChromium]"
)
if not defined _type (
expand.exe -f:*_microsoft-windows-e..-firsttimeinstaller_*.manifest "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\*_microsoft-windows-e..-firsttimeinstaller_*.manifest" set "_type=[EdgeChromium]"
)
if not defined _type (
expand.exe -f:*_adobe-flash-for-windows_*.manifest "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\*_adobe-flash-for-windows_*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || set "_type=[Flash]"
)
echo %count%/%_cab%: %package% %_type%
set cab_%pkgn%=1
expand.exe -f:* "!_UUP!\%package%" "!dest!" %_Null% || (
  rmdir /s /q "!dest!\" %_Nul3%
  set directcab=!directcab! %package%
  goto :eof
)
7z.exe e "!_UUP!\%package%" -o"!dest!" update.mum -aoa %_Null%
if exist "!dest!\*cablist.ini" expand.exe -f:* "!dest!\*.cab" "!dest!" %_Null% || (
  rmdir /s /q "!dest!\" %_Nul3%
  set directcab=!directcab! %package%
  goto :eof
)
if exist "!dest!\*cablist.ini" (
  del /f /q "!dest!\*cablist.ini" %_Nul3%
  del /f /q "!dest!\*.cab" %_Nul3%
)
set _sbst=0
if defined psf_%pkgn% (
if not exist "!dest!\express.psf.cix.xml" for /f %%# in ('dir /b /a:-d "!dest!\*.psf.cix.xml"') do rename "!dest!\%%#" express.psf.cix.xml %_Nul3%
subst %_sdr% "!_cabdir!" %_Nul3% && set _sbst=1
if !_sbst! equ 1 pushd %_sdr%
if not exist "%package%" (
copy /y "!_UUP!\%pkgn%.*" . %_Nul3%
if not exist "%pkgn%.psf" for /f %%# in ('dir /b /a:-d "!_UUP!\*%pkgid%*%arch%*.psf"') do copy /y "!_UUP!\%%#" %pkgn%.psf %_Nul3%
)
if not exist "PSFExtractor.exe" copy /y "!_work!\bin\PSFExtractor.*" . %_Nul3%
PSFExtractor.exe %package% %_Null%
if !errorlevel! neq 0 (
  call :dk_color1 %Red% "Error: failed to extract %pkgn%.psf"
  (echo.&echo failed to extract %pkgn%.psf)>>"!logerr!"
  rmdir /s /q "%pkgn%\" %_Nul3%
  set psf_%pkgn%=
  )
if !_sbst! equ 1 popd
if !_sbst! equ 1 subst %_sdr% /d %_Nul3%
)
goto :eof

:msu2
if defined msu_%pkgn% goto :eof
if exist "!dest!\" rmdir /s /q "!dest!\"
mkdir "!dest!"
set msuwim=0
expand.exe -d -f:*Windows*.psf "!_UUP!\%package%" %_Nul2% | findstr /i %arch%\.psf %_Nul3% || (
wimlib-imagex.exe dir "!_UUP!\%package%" %_Nul2% | findstr /i %arch%\.psf %_Nul3% && (set msuwim=1) || (goto :eof)
)
set /a count+=1
if %count% equ 1 echo.
echo %count%/%_cab%: %package% [Combined UUP]
mkdir "!_cabdir!\lcu" %_Nul3%
if %msuwim% equ 0 (
expand.exe -f:*Windows*.cab "!_UUP!\%package%" "!_cabdir!\lcu" %_Null%
expand.exe -f:SSU-*%arch%*.cab "!_UUP!\%package%" "!_cabdir!\lcu" %_Null%
) else (
wimlib-imagex.exe extract "!_UUP!\%package%" 1 *Windows*.wim --dest-dir="!_cabdir!\lcu" %_Nul3%
wimlib-imagex.exe extract "!_UUP!\%package%" 1 SSU-*%arch%*.cab --dest-dir="!_cabdir!\lcu" %_Nul3%
)
for /f "tokens=* delims=" %%# in ('dir /b /on "!_cabdir!\lcu\*Windows1*-KB*.*"') do set "compkg=%%#"
7z.exe e "!_cabdir!\lcu\%compkg%" -o"!dest!" update.mum -aoa %_Null%
if exist "!_cabdir!\lcu\SSU-*%arch%*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_cabdir!\lcu\SSU-*%arch%*.cab"') do (set "compkg=%%#"&call :inrenssu)
rmdir /s /q "!_cabdir!\lcu\" %_Nul3%
set msu_%pkgn%=1
if not defined isodate findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% && (
call :chklcu
)
goto :eof

:chklcu
findstr /i /m /c:"Microsoft-Windows-CoreEdition" "!dest!\update.mum" %_Nul3% || set _eosC=1
findstr /i /m /c:"Microsoft-Windows-ProfessionalEdition" "!dest!\update.mum" %_Nul3% || set _eosP=1
findstr /i /m /c:"Microsoft-Windows-PPIProEdition" "!dest!\update.mum" %_Nul3% || set _eosT=1
if not exist "%SystemRoot%\temp\" mkdir "%SystemRoot%\temp" %_Nul3%
copy /y "!dest!\update.mum" %SystemRoot%\temp\ %_Nul1%
if %_build% geq 22621 copy /y "!dest!\update.mum" "!_cabdir!\LCU.mum" %_Nul1%
call :datemum isodate isotime
goto :eof

:EKB1
if exist "%~1\microsoft-windows-*enablement-package~*.mum" set "%2=%3"
if exist "%~1\Microsoft-Windows-1909Enablement-Package~*.mum" set "_fixEP=18363"
if exist "%~1\Microsoft-Windows-20H2Enablement-Package~*.mum" set "_fixEP=19042"
if exist "%~1\Microsoft-Windows-21H1Enablement-Package~*.mum" set "_fixEP=19043"
if exist "%~1\Microsoft-Windows-21H2Enablement-Package~*.mum" set "_fixEP=19044"
if exist "%~1\Microsoft-Windows-22H2Enablement-Package~*.mum" set "_fixEP=19045"
if exist "%~1\Microsoft-Windows-ASOSFe22H2Enablement-Package~*.mum" set "_fixEP=20349"
if exist "%~1\Microsoft-Windows-SV*Enablement-Package~*.mum" set "_fixEP=%_fixSV%"
if exist "%~1\Microsoft-Windows-SV2Moment*Enablement-Package~*.mum" for /f "tokens=3 delims=-" %%a in ('dir /b /a:-d /od "%~1\Microsoft-Windows-SV2Moment*Enablement-Package~*.mum"') do (
  for /f "tokens=3 delims=eEtT" %%i in ('echo %%a') do (
    set /a _fixSV=%_build%+%%i
    set /a _fixEP=%_build%+%%i
  )
)
goto :eof

:EKB2
if exist "%~1\Microsoft-Windows-SV2Moment4Enablement-Package~*.mum" set "_fixSV=22631"&set "_fixEP=22631"
if exist "%~1\Microsoft-Windows-23H2Enablement-Package~*.mum" set "_fixSV=22631"&set "_fixEP=22631"
if exist "%~1\Microsoft-Windows-SV2BetaEnablement-Package~*.mum" set "_fixSV=22635"&set "_fixEP=22635"
goto :eof

:inrenupd
for /f "tokens=2 delims=-" %%V in ('echo %compkg%') do set kbupd=%%V
set _ufn=Windows10.0-%kbupd%-%arch%_inout.cab
echo %compkg%| findstr /i "Windows11\." %_Nul1% && set _ufn=Windows11.0-%kbupd%-%arch%_inout.cab
echo %compkg%| findstr /i "Windows12\." %_Nul1% && set _ufn=Windows12.0-%kbupd%-%arch%_inout.cab
if exist "!_UUP!\%_ufn%" goto :eof
call set /a _cab+=1
set "tmpcmp=!tmpcmp! %_ufn%"
move /y "!_cabdir!\lcu\%compkg%" "!_UUP!\%_ufn%" %_Nul3%
goto :eof

:inrenssu
if exist "!_UUP!\%compkg:~0,-4%*.cab" goto :eof
set kbupd=
expand.exe -f:update.mum "!_cabdir!\lcu\%compkg%" "!_cabdir!\lcu" %_Null%
if not exist "!_cabdir!\lcu\update.mum" goto :eof
for /f "tokens=3 delims== " %%# in ('findstr /i releaseType "!_cabdir!\lcu\update.mum"') do set kbupd=%%~#
if "%kbupd%"=="" goto :eof
set _ufn=Windows10.0-%kbupd%-%arch%_inout.cab
dir /b /on "!_cabdir!\lcu\*Windows1*-KB*.cab" %_Nul2% | findstr /i "Windows11\." %_Nul1% && set _ufn=Windows11.0-%kbupd%-%arch%_inout.cab
dir /b /on "!_cabdir!\lcu\*Windows1*-KB*.cab" %_Nul2% | findstr /i "Windows12\." %_Nul1% && set _ufn=Windows12.0-%kbupd%-%arch%_inout.cab
if exist "!_UUP!\%_ufn%" goto :eof
call set /a _cab+=1
set "tmpcmp=!tmpcmp! %_ufn%"
move /y "!_cabdir!\lcu\%compkg%" "!_UUP!\%_ufn%" %_Nul3%
goto :eof

:updatewim
set mumtarget=%_mount%
set dismtarget=/Image:"%_mount%"
set SOFTWARE=uiSOFTWARE
set COMPONENTS=uiCOMPONENTS
set "_Wnn=HKLM\%SOFTWARE%\Microsoft\Windows\CurrentVersion\SideBySide\Winners"
set "_Cmp=HKLM\%COMPONENTS%\DerivedData\Components"
if exist "%mumtarget%\Windows\Servicing\Packages\*~arm64~~*.mum" (
set "xBT=arm64"
set "_EsuKey=%_Wnn%\arm64_%_EsuCmp%_%_Pkt%_none_0a035f900ca87ee9"
set "_EdgKey=%_Wnn%\arm64_%_EdgCmp%_%_Pkt%_none_1e5e2b2c8adcf701"
set "_CedKey=%_Wnn%\arm64_%_CedCmp%_%_Pkt%_none_df3eefecc502346d"
) else if exist "%mumtarget%\Windows\Servicing\Packages\*~amd64~~*.mum" (
set "xBT=amd64"
set "_EsuKey=%_Wnn%\amd64_%_EsuCmp%_%_Pkt%_none_0a0357560ca88a4d"
set "_EdgKey=%_Wnn%\amd64_%_EdgCmp%_%_Pkt%_none_1e5e22f28add0265"
set "_CedKey=%_Wnn%\amd64_%_CedCmp%_%_Pkt%_none_df3ee7b2c5023fd1"
) else (
set "xBT=x86"
set "_EsuKey=%_Wnn%\x86_%_EsuCmp%_%_Pkt%_none_ade4bbd2544b1917"
set "_EdgKey=%_Wnn%\x86_%_EdgCmp%_%_Pkt%_none_c23f876ed27f912f"
set "_CedKey=%_Wnn%\x86_%_CedCmp%_%_Pkt%_none_83204c2f0ca4ce9b"
)
for /f "tokens=4,5,6 delims=_" %%H in ('dir /b "%mumtarget%\Windows\WinSxS\Manifests\%xBT%_microsoft-windows-foundation_*.manifest"') do set "_Fnd=microsoft-w..-foundation_%_Pkt%_%%H_%%~nJ"
set lcumsu=
set mpamfe=
set servicingstack=
set cumulative=
set netupdt=
set netpack=
set netroll=
set netlcu=
set netmsu=
set secureboot=
set edge=
set safeos=
set callclean=
set fupdt=
set supdt=
set cupdt=
set dupdt=
set overall=
set lcupkg=
set ldr=
set mounterr=
set idpkg=
set _clnwinpe=0
set LTSC=0
if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
if %_build% neq 14393 if exist "%mumtarget%\Windows\Servicing\Packages\Microsoft-Windows-PPIProEdition~*.mum" set LTSC=1
if exist "%mumtarget%\Windows\Servicing\Packages\Microsoft-Windows-EnterpriseS*Edition~*.mum" set LTSC=1
if exist "%mumtarget%\Windows\Servicing\Packages\Microsoft-Windows-IoTEnterpriseS*Edition~*.mum" set LTSC=1
if exist "%mumtarget%\Windows\Servicing\Packages\Microsoft-Windows-Server*Edition~*.mum" set LTSC=1
if exist "%mumtarget%\Windows\Servicing\Packages\Microsoft-Windows-Server*ACorEdition~*.mum" set LTSC=0
if exist "%mumtarget%\Windows\Servicing\Packages\Microsoft-Windows-Server*NanoEdition~*.mum" set LTSC=0
if exist "%mumtarget%\Windows\Servicing\Packages\Microsoft-Windows-ServerAzureStackHCI*Edition~*.mum" set LTSC=0
)
if exist "!_UUP!\SSU-*-*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\SSU-*-*.cab"') do (set "pckn=%%~n#"&set "packx=%%~x#"&set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :procmum)
if exist "!_UUP!\*Windows1*-KB*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\*Windows1*-KB*.cab"') do (set "pckn=%%~n#"&set "packx=%%~x#"&set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :procmum)
if %_build% geq 21382 if exist "!_UUP!\*Windows1*-KB*.msu" (for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\*Windows1*-KB*.msu"') do if defined msu_%%~n# (set "pckn=%%~n#"&set "packx=%%~x#"&set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :procmum))
if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" if exist "!_UUP!\*defender-dism*%arch%*.cab" (for /f "tokens=* delims=" %%# in ('dir /b "!_UUP!\*defender-dism*%arch%*.cab"') do (set "pckn=%%~n#"&set "packx=%%~x#"&set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :procmum))
if %_build% geq 19041 if %winbuild% lss 17133 if not exist "%SysPath%\ext-ms-win-security-slc-l1-1-0.dll" (
copy /y %SysPath%\slc.dll %SysPath%\ext-ms-win-security-slc-l1-1-0.dll %_Nul1%
if /i not %xOS%==x86 copy /y %SystemRoot%\SysWOW64\slc.dll %SystemRoot%\SysWOW64\ext-ms-win-security-slc-l1-1-0.dll %_Nul1%
)
if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
reg.exe load HKLM\%SOFTWARE% "%mumtarget%\Windows\System32\Config\SOFTWARE" %_Nul1%
if %winbuild% lss 15063 if /i %arch%==arm64 reg.exe add HKLM\%SOFTWARE%\Microsoft\Windows\CurrentVersion\SideBySide /v AllowImproperDeploymentProcessorArchitecture /t REG_DWORD /d 1 /f %_Nul1%
if %winbuild% lss 9600 reg.exe add HKLM\%SOFTWARE%\Microsoft\Windows\CurrentVersion\SideBySide /v AllowImproperDeploymentProcessorArchitecture /t REG_DWORD /d 1 /f %_Nul1%
reg.exe save HKLM\%SOFTWARE% "%mumtarget%\Windows\System32\Config\SOFTWARE2" %_Nul1%
reg.exe unload HKLM\%SOFTWARE% %_Nul1%
move /y "%mumtarget%\Windows\System32\Config\SOFTWARE2" "%mumtarget%\Windows\System32\Config\SOFTWARE" %_Nul1%
)
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" if /i not %arch%==arm64 (
reg.exe load HKLM\%SOFTWARE% "%mumtarget%\Windows\System32\Config\SOFTWARE" %_Nul1%
reg.exe add HKLM\%SOFTWARE%\%_SxsCfg% /v DisableComponentBackups /t REG_DWORD /d 1 /f %_Nul1%
reg.exe unload HKLM\%SOFTWARE% %_Nul1%
)
if defined netpack set "ldr=!netpack! !ldr!"
for %%# in (dupdt,cupdt,supdt,fupdt,safeos,secureboot,edge,ldr,cumulative,lcumsu) do if defined %%# set overall=1
if not defined overall if not defined mpamfe if not defined servicingstack goto :eof
if defined servicingstack (
set idpkg=ServicingStack
set callclean=1
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismSSU.log" /Add-Package %servicingstack%
cmd /c exit /b !errorlevel!
call :chkEC "!=ExitCode!"
if !_ec!==1 goto :errmount
if not defined overall call :cleanup
)
if not defined overall if not defined mpamfe goto :eof
if defined safeos if %SkipWinRE% equ 0 (
set idpkg=SafeOS
set callclean=1
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismWinPE.log" /Add-Package %safeos%
cmd /c exit /b !errorlevel!
call :chkEC "!=ExitCode!"
if !_ec!==1 goto :errmount
)
if defined safeos if %SkipWinRE% equ 0 if %LCUwinre% equ 0 (
set relite=1
if not defined lcumsu call :cleanup
%_wrb% if not defined lcumsu if %ResetBase% equ 0 %_dism2%:"!_cabdir!" %dismtarget% /Cleanup-Image /StartComponentCleanup /ResetBase %_Null%
%_dism2%:"!_cabdir!" /Commit-Image /MountDir:"%_mount%" /Append %_Supp%
)
if not defined cumulative if not defined lcumsu goto :scbt
set _gobk=scbt
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" goto :updtlcu
:scbt
if defined secureboot (
set idpkg=SecureBoot
set callclean=1
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismSecureBoot.log" /Add-Package %secureboot%
cmd /c exit /b !errorlevel!
call :chkEC "!=ExitCode!"
if !_ec!==1 goto :errmount
)
if defined ldr (
set idpkg=General
set callclean=1
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismUpdt.log" /Add-Package %ldr%
cmd /c exit /b !errorlevel!
call :chkEC "!=ExitCode!"
if !_ec!==1 if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" goto :errmount
)
if defined fupdt (
set "_SxsKey=%_EdgKey%"
set "_SxsCmp=%_EdgCmp%"
set "_SxsIdn=%_EdgIdn%"
set "_SxsCF=256"
set "_DsmLog=DismEdge.log"
for %%# in (%fupdt%) do (set "cbsn=%%~n#"&set "dest=!_cabdir!\%%~n#"&call :pXML)
)
if defined supdt (
set "_SxsKey=%_EsuKey%"
set "_SxsCmp=%_EsuCmp%"
set "_SxsIdn=%_EsuIdn%"
set "_SxsCF=64"
set "_DsmLog=DismLCUs.log"
for %%# in (%supdt%) do (set "cbsn=%%~n#"&set "dest=!_cabdir!\%%~n#"&call :pXML)
)
if defined cupdt (
set "_SxsKey=%_CedKey%"
set "_SxsCmp=%_CedCmp%"
set "_SxsIdn=%_CedIdn%"
set "_SxsCF=256"
set "_DsmLog=DismLCUs.log"
for %%# in (%cupdt%) do (set "cbsn=%%~n#"&set "dest=!_cabdir!\%%~n#"&call :pXML)
)
set _dualSxS=
if defined dupdt (
set _dualSxS=1
set "_SxsKey=%_EsuKey%"
set "_SxsCmp=%_EsuCmp%"
set "_SxsIdn=%_EsuIdn%"
set "_SxsCF=64"
set "_DsmLog=DismLCUs.log"
for %%# in (%dupdt%) do (set "cbsn=%%~n#"&set "dest=!_cabdir!\%%~n#"&call :pXML)
)
if not defined cumulative if not defined lcumsu goto :cuwd
set _gobk=cuwd
if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" goto :updtlcu
:cuwd
if defined lcupkg call :ReLCU
if defined callclean if %_clnwinpe% equ 0 call :cleanup
if defined mpamfe (
call :dk_color1 %Gray% "=== Adding Defender update . . ." 4
call :defender_update
)
if not defined edge goto :eof
if defined edge (
set idpkg=Edge
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismEdge.log" /Add-Package %edge%
cmd /c exit /b !errorlevel!
call :chkEC "!=ExitCode!"
if !_ec!==1 goto :errmount
)
goto :eof

:updtlcu
set "_wpeLCU=boot.wim"
if %SkipWinRE% equ 0 if %LCUwinre% equ 1 set "_wpeLCU=winre.wim/boot.wim"
set "_DsmLog=DismLCU.log"
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
set "_DsmLog=DismLCU_winpe.log"
call :dk_color1 %Gray% "=== Adding LCU for %_wpeLCU% . . ." 4
)
set idpkg=LCU
set callclean=1
if defined cumulative %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\%_DsmLog%" /Add-Package %cumulative%
if defined lcumsu for %%# in (%lcumsu%) do (
call :dk_color1 %_Yellow% "=== Adding LCU %%#" 4
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\%_DsmLog%" /Add-Package /PackagePath:"!_UUP!\%%#"
)
cmd /c exit /b !errorlevel!
call :chkEC "!=ExitCode!"
if !_ec!==1 if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" goto :errmount
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" if %SkipWinRE% equ 0 if %LCUwinre% equ 1 (
set _clnwinpe=1
set relite=1
call :cleanup
%_dism2%:"!_cabdir!" /Commit-Image /MountDir:"%_mount%" /Append %_Supp%
)
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" goto :%_gobk%
if not exist "%mumtarget%\Windows\Servicing\Packages\Package_for_RollupFix*.mum" goto :%_gobk%
for /f %%# in ('dir /b /a:-d /od "%mumtarget%\Windows\Servicing\Packages\Package_for_RollupFix*.mum"') do set "lcumum=%%#"
if defined lcumsu if %_build% geq 22621 if exist "!_cabdir!\LCU.mum" (
%_Nul3% icacls "%mumtarget%\Windows\Servicing\Packages\%lcumum%" /save "!_cabdir!\acl.txt"
%_Nul3% takeown /f "%mumtarget%\Windows\Servicing\Packages\%lcumum%" /A
%_Nul3% icacls "%mumtarget%\Windows\Servicing\Packages\%lcumum%" /grant *S-1-5-32-544:F
%_Nul3% copy /y "!_cabdir!\LCU.mum" "%mumtarget%\Windows\Servicing\Packages\%lcumum%"
%_Nul3% icacls "%mumtarget%\Windows\Servicing\Packages\%lcumum%" /setowner *S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464
%_Nul3% icacls "%mumtarget%\Windows\Servicing\Packages" /restore "!_cabdir!\acl.txt"
%_Nul3% del /f /q "!_cabdir!\acl.txt"
)
goto :%_gobk%

:chkEC
set _ec=0
set "_ic=%~1"
if /i not "!_ic!"=="00000000" if /i not "!_ic!"=="800f081e" if /i not "!_ic!"=="800706be" if /i not "!_ic!"=="800706ba" set _ec=1
if /i not "!_ic!"=="00000000" if /i not "!_ic!"=="800f081e" if !_ec!==0 %_dism1% %dismtarget% /LogPath:"%_dLog%\DismNUL.log" /Get-Packages %_Null%
goto :eof

:errmount
set mounterr=1
set "msgerr=Dism.exe operation failed"
call :dk_color1 %Red% "%msgerr%. Discarding . . ." 4
if defined idpkg set "msgerr=Dism.exe failed adding %idpkg% update{s}"
(echo.&echo %msgerr%)>>"!logerr!"
%_dism1% %dismtarget% /LogPath:"%_dLog%\DismNUL.log" /Get-Packages %_Null%
%_dism1% /Unmount-Wim /MountDir:"%_mount%" /Discard
%_dism1% /Cleanup-Wim %_Nul3%
goto :eof
rmdir /s /q "%_mount%\" %_Nul3%
set AddUpdates=0
set FullExit=exit
goto :%_rtrn%

:ReLCU
if exist "!lcudir!\update.mum" if exist "!lcudir!\*.manifest" goto :eof
if not exist "!lcudir!\" mkdir "!lcudir!"
expand.exe -f:* "!_UUP!\%lcupkg%" "!lcudir!" %_Null%
7z.exe e "!_UUP!\%lcupkg%" -o"!lcudir!" update.mum -aoa %_Null%
if exist "!lcudir!\*cablist.ini" (
  expand.exe -f:* "!lcudir!\*.cab" "!lcudir!" %_Null%
  del /f /q "!lcudir!\*cablist.ini" %_Nul3%
  del /f /q "!lcudir!\*.cab" %_Nul3%
)
set _sbst=0
for /f "tokens=2 delims=-" %%V in ('echo %lcupkg%') do set lcuid=%%V
if exist "!lcudir!\*.psf.cix.xml" (
if not exist "!lcudir!\express.psf.cix.xml" for /f %%# in ('dir /b /a:-d "!lcudir!\*.psf.cix.xml"') do rename "!lcudir!\%%#" express.psf.cix.xml %_Nul3%
subst %_sdr% "!_cabdir!" %_Nul3% && set _sbst=1
if !_sbst! equ 1 pushd %_sdr%
if not exist "%lcupkg%" (
copy /y "!_UUP!\%lcupkg:~0,-4%.*" . %_Nul3%
if not exist "%lcupkg:~0,-4%.psf" for /f %%# in ('dir /b /a:-d "!_UUP!\*%lcuid%*%arch%*.psf"') do copy /y "!_UUP!\%%#" %lcupkg:~0,-4%.psf %_Nul3%
)
if not exist "PSFExtractor.exe" copy /y "!_work!\bin\PSFExtractor.*" . %_Nul3%
PSFExtractor.exe %lcupkg% %_Null%
if !_sbst! equ 1 popd
if !_sbst! equ 1 subst %_sdr% /d %_Nul3%
)
goto :eof

:procmum
if exist "!dest!\*.psf.cix.xml" if not defined psf_%pckn% goto :eof
if exist "!dest!\*defender*.xml" (
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" goto :eof
call :defender_check
goto :eof
)
if not exist "!dest!\update.mum" (
if /i "!lcupkg!"=="%package%" call :ReLCU
)
set _dcu=0
if not exist "!dest!\update.mum" (
for %%# in (%directcab%) do if /i "%package%"=="%%~#" set _dcu=1
if "!_dcu!"=="0" goto :eof
)
set xmsu=0
if /i "%packx%"==".msu" set xmsu=1
for /f "tokens=2 delims=-" %%V in ('echo %pckn%') do set pckid=%%V
set "uupmsu="
if %xmsu% equ 0 if %_build% geq 21382 if exist "!_UUP!\*Windows1*%pckid%*%arch%*.msu" for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\*Windows1*%pckid%*%arch%*.msu"') do (
set "uupmsu=%%#"
)
if defined uupmsu (
expand.exe -d -f:*Windows*.psf "!_UUP!\%uupmsu%" %_Nul2% | findstr /i %arch%\.psf %_Nul3% && goto :eof
wimlib-imagex.exe dir "!_UUP!\%uupmsu%" %_Nul2% | findstr /i %arch%\.psf %_Nul3% && goto :eof
)
if %_build% geq 20348 if exist "!dest!\update.mum" if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (findstr /i /m "Microsoft-Windows-NetFx" "!dest!\package_1_for*.mum" %_Nul3% && (
  if exist "!dest!\*_microsoft-windows-n..35wpfcomp.resources*.manifest" (set "netupdt=!netupdt! /PackagePath:!dest!\update.mum"&goto :eof)
  ))
)
if %_build% geq 17763 if exist "!dest!\update.mum" if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (findstr /i /m "Microsoft-Windows-NetFx" "!dest!\*.mum" %_Nul3% && (
  if not exist "!dest!\*_netfx4clientcorecomp.resources*.manifest" if not exist "!dest!\*_netfx4-netfx_detectionkeys_extended*.manifest" if not exist "!dest!\*_microsoft-windows-n..35wpfcomp.resources*.manifest" (if exist "!dest!\*_*10.0.*.manifest" (set "netroll=!netroll! /PackagePath:!dest!\update.mum") else (if exist "!dest!\*_*11.0.*.manifest" set "netroll=!netroll! /PackagePath:!dest!\update.mum"))
  ))
findstr /i /m "Package_for_OasisAsset" "!dest!\update.mum" %_Nul3% && (if not exist "%mumtarget%\Windows\Servicing\packages\*OasisAssets-Package*.mum" goto :eof)
findstr /i /m "WinPE" "!dest!\update.mum" %_Nul3% && (
  %_Nul3% findstr /i /m "Edition\"" "!dest!\update.mum"
  if errorlevel 1 goto :eof
  )
)
if %_build% geq 19041 if exist "!dest!\update.mum" if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
findstr /i /m "Package_for_WindowsExperienceFeaturePack" "!dest!\update.mum" %_Nul3% && (
  if not exist "%mumtarget%\Windows\Servicing\packages\Microsoft-Windows-UserExperience-Desktop*.mum" goto :eof
  set fxupd=0
  for /f "tokens=3 delims== " %%# in ('findstr /i "Edition" "!dest!\update.mum" %_Nul6%') do if exist "%mumtarget%\Windows\Servicing\packages\%%~#*.mum" set fxupd=1
  if "!fxupd!"=="0" goto :eof
  )
)
if exist "!dest!\*_microsoft-windows-servicingstack_*.manifest" (
set "servicingstack=!servicingstack! /PackagePath:!dest!\update.mum"
goto :eof
)
if exist "!dest!\*_netfx4-netfx_detectionkeys_extended*.manifest" (
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" goto :eof
set "netpack=!netpack! /PackagePath:!dest!\update.mum"
goto :eof
)
if exist "!dest!\*_%_EdgCmp%_*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" goto :eof
if exist "!dest!\*enablement-package*.mum" if %SkipEdge% neq 1 (
  for /f %%# in ('dir /b /a:-d "!dest!\*enablement-package~*.mum"') do set "ldr=!ldr! /PackagePath:!dest!\%%#"
  set "edge=!edge! /PackagePath:!dest!\update.mum"
  )
if exist "!dest!\*enablement-package*.mum" if %SkipEdge% equ 1 (set "fupdt=!fupdt! %package%")
if not exist "!dest!\*enablement-package*.mum" set "edge=!edge! /PackagePath:!dest!\update.mum"
goto :eof
)
if exist "!dest!\*_microsoft-windows-sysreset_*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (
if not exist "%mumtarget%\Windows\Servicing\Packages\WinPE-SRT-Package~*.mum" goto :eof
set "safeos=!safeos! /PackagePath:!dest!\update.mum"
goto :eof
)
if exist "!dest!\*_microsoft-windows-winpe_tools_*.manifest" if not exist "!dest!\*_microsoft-windows-sysreset_*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (
set "safeos=!safeos! /PackagePath:!dest!\update.mum"
goto :eof
)
if exist "!dest!\*_microsoft-windows-winre-tools_*.manifest" if not exist "!dest!\*_microsoft-windows-sysreset_*.manifest" if not exist "!dest!\*_microsoft-windows-winpe_tools_*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (
if not exist "!mumtarget!\Windows\Servicing\Packages\WinPE-SRT-Package~*.mum" goto :eof
set "safeos=!safeos! /PackagePath:!dest!\update.mum"
goto :eof
)
if exist "!dest!\*_microsoft-windows-i..dsetup-rejuvenation_*.manifest" if not exist "!dest!\*_microsoft-windows-sysreset_*.manifest" if not exist "!dest!\*_microsoft-windows-winpe_tools_*.manifest" if not exist "!dest!\*_microsoft-windows-winre-tools_*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (
if not exist "%mumtarget%\Windows\Servicing\Packages\WinPE-Rejuv-Package~*.mum" goto :eof
set "safeos=!safeos! /PackagePath:!dest!\update.mum"
goto :eof
)
if exist "!dest!\*_microsoft-windows-s..boot-firmwareupdate_*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" goto :eof
if %winbuild% lss 9600 goto :eof
set secureboot=!secureboot! /PackagePath:"!_UUP!\%package%"
goto :eof
)
if exist "!dest!\update.mum" if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
findstr /i /m "WinPE" "!dest!\update.mum" %_Nul3% || (findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (goto :eof))
findstr /i /m "WinPE-NetFx-Package" "!dest!\update.mum" %_Nul3% && (findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (goto :eof))
)
if exist "!dest!\*_adobe-flash-for-windows_*.manifest" if not exist "!dest!\*enablement-package*.mum" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (
if not exist "%mumtarget%\Windows\Servicing\packages\Adobe-Flash-For-Windows-Package*.mum" if not exist "%mumtarget%\Windows\Servicing\packages\Microsoft-Windows-Client-Desktop-Required-Package*.mum" goto :eof
if %_build% geq 16299 (
  set flash=0
  for /f "tokens=3 delims== " %%# in ('findstr /i "Edition" "!dest!\update.mum" %_Nul6%') do if exist "%mumtarget%\Windows\Servicing\packages\%%~#*.mum" set flash=1
  if "!flash!"=="0" goto :eof
  )
)
if exist "!dest!\*enablement-package*.mum" (
  set epkb=0
  for /f "tokens=3 delims== " %%# in ('findstr /i "Edition" "!dest!\update.mum" %_Nul6%') do if exist "%mumtarget%\Windows\Servicing\packages\%%~#*.mum" set epkb=1
  if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" findstr /i /m "WinPE" "!dest!\update.mum" %_Nul3% && set epkb=1
  if "!epkb!"=="0" goto :eof
)
for %%# in (%directcab%) do (
if /i "%package%"=="%%~#" (
  set "cumulative=!cumulative! /PackagePath:"!_UUP!\%package%""
  goto :eof
  )
)
if exist "!dest!\update.mum" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% && (
if %_build% geq 20231 if %xmsu% equ 0 (
  set "lcudir=!dest!"
  set "lcupkg=%package%"
  )
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
  if %xmsu% equ 1 (set "lcumsu=!lcumsu! %package%") else (set "cumulative=!cumulative! /PackagePath:!dest!\update.mum")
  goto :eof
  )
if %xmsu% equ 1 (
  set "lcumsu=!lcumsu! %package%"
  set "netmsu=!netmsu! %package%"
  goto :eof
  ) else (
  set "netlcu=!netlcu! /PackagePath:!dest!\update.mum"
  )
if exist "!dest!\*_%_EsuCmp%_*.manifest" if not exist "!dest!\*_%_CedCmp%_*.manifest" if %LTSC% equ 0 (set "supdt=!supdt! %package%"&goto :eof)
if exist "!dest!\*_%_CedCmp%_*.manifest" if not exist "!dest!\*_%_EsuCmp%_*.manifest" if %SkipEdge% equ 1 (set "cupdt=!cupdt! %package%"&goto :eof)
if exist "!dest!\*_%_CedCmp%_*.manifest" if %SkipEdge% equ 2 call :deEdge
if exist "!dest!\*_%_EsuCmp%_*.manifest" if exist "!dest!\*_%_CedCmp%_*.manifest" (
  if %SkipEdge% neq 1 if %LTSC% equ 0 (set "supdt=!supdt! %package%"&goto :eof)
  if %SkipEdge% equ 1 if %LTSC% equ 0 (set "dupdt=!dupdt! %package%"&goto :eof)
  if %SkipEdge% equ 1 if %LTSC% equ 1 (set "cupdt=!cupdt! %package%"&goto :eof)
  )
set "cumulative=!cumulative! /PackagePath:!dest!\update.mum"
goto :eof
)
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
set "ldr=!ldr! /PackagePath:!dest!\update.mum"
goto :eof
)
if exist "!dest!\*_%_EsuCmp%_*.manifest" if %LTSC% equ 0 (set "supdt=!supdt! %package%"&goto :eof)
if exist "!dest!\*_%_CedCmp%_*.manifest" if %SkipEdge% equ 1 (set "cupdt=!cupdt! %package%"&goto :eof)
if exist "!dest!\*_%_CedCmp%_*.manifest" if %SkipEdge% equ 2 call :deEdge
set "ldr=!ldr! /PackagePath:!dest!\update.mum"
goto :eof

:deEdge
  mkdir "%mumtarget%\Program Files\Microsoft\Edge\Application" %_Nul3%
  mkdir "%mumtarget%\Program Files\Microsoft\EdgeUpdate" %_Nul3%
  type nul>"%mumtarget%\Program Files\Microsoft\Edge\Edge.dat" 2>&1
  type nul>"%mumtarget%\Program Files\Microsoft\Edge\Edge.LCU.dat" 2>&1
  type nul>"%mumtarget%\Program Files\Microsoft\EdgeUpdate\EdgeUpdate.dat" 2>&1
  if exist "%mumtarget%\Windows\SysWOW64\*.dll" (
    mkdir "%mumtarget%\Program Files (x86)\Microsoft\Edge\Application" %_Nul3%
    mkdir "%mumtarget%\Program Files (x86)\Microsoft\EdgeUpdate" %_Nul3%
    type nul>"%mumtarget%\Program Files (x86)\Microsoft\Edge\Edge.dat" 2>&1
    type nul>"%mumtarget%\Program Files (x86)\Microsoft\Edge\Edge.LCU.dat" 2>&1
    type nul>"%mumtarget%\Program Files (x86)\Microsoft\EdgeUpdate\EdgeUpdate.dat" 2>&1
    )
goto :eof

:defender_check
if %_skpp% equ 1 if %_skpd% equ 1 (set /a _sum-=1&goto :eof)
set "_MWD=ProgramData\Microsoft\Windows Defender"
if not exist "%mumtarget%\%_MWD%\Definition Updates\Updates\*.vdm" (set "mpamfe=!dest!"&goto :eof)
if %_skpp% equ 0 dir /b /ad "%mumtarget%\%_MWD%\Platform\*.*.*.*" %_Nul3% && (
if not exist "!_cabdir!\*defender*.xml" expand.exe -f:*defender*.xml "!_UUP!\%package%" "!_cabdir!" %_Null%
for /f %%i in ('dir /b /a:-d "!_cabdir!\*defender*.xml"') do for /f "tokens=3 delims=<> " %%# in ('type "!_cabdir!\%%i" ^| find /i "platform"') do (
  dir /b /ad "%mumtarget%\%_MWD%\Platform\%%#*" %_Nul3% && set _skpp=1
  )
)
set "_ver1j=0"&set "_ver1n=0"
set "_ver2j=0"&set "_ver2n=0"
set "_fil1=%mumtarget%\%_MWD%\Definition Updates\Updates\mpavdlta.vdm"
set "_fil2=!_cabdir!\mpavdlta.vdm"
set "cfil1=!_fil1:\=\\!"
set "cfil2=!_fil2:\=\\!"
if %_skpd% equ 0 if exist "!_fil1!" (
if %_cwmi% equ 1 for /f "tokens=3,4 delims==." %%a in ('wmic datafile where "name='!cfil1!'" get Version /value ^| find "="') do set "_ver1j=%%a"&set "_ver1n=%%b"
if %_cwmi% equ 0 for /f "tokens=2,3 delims=." %%a in ('%_psc% "([WMI]'CIM_DataFile.Name=''!cfil1!''').Version"') do set "_ver1j=%%a"&set "_ver1n=%%b"
expand.exe -i -f:mpavdlta.vdm "!_UUP!\%package%" "!_cabdir!" %_Null%
)
if exist "!_fil2!" (
if %_cwmi% equ 1 for /f "tokens=3,4 delims==." %%a in ('wmic datafile where "name='!cfil2!'" get Version /value ^| find "="') do set "_ver2j=%%a"&set "_ver2n=%%b"
if %_cwmi% equ 0 for /f "tokens=2,3 delims=." %%a in ('%_psc% "([WMI]'CIM_DataFile.Name=''!cfil2!''').Version"') do set "_ver2j=%%a"&set "_ver2n=%%b"
)
if %_ver1j% gtr %_ver2j% set _skpd=1
if %_ver1j% equ %_ver2j% if %_ver1n% geq %_ver2n% set _skpd=1
if %_skpp% equ 1 if %_skpd% equ 1 (set /a _sum-=1&goto :eof)
set "mpamfe=!dest!"
goto :eof

:defender_update
xcopy /CIRY "!mpamfe!\Definition Updates\Updates" "%mumtarget%\%_MWD%\Definition Updates\Updates\" %_Nul3%
if exist "%mumtarget%\%_MWD%\Definition Updates\Updates\MpSigStub.exe" del /f /q "%mumtarget%\%_MWD%\Definition Updates\Updates\MpSigStub.exe" %_Nul3%
xcopy /ECIRY "!mpamfe!\Platform" "%mumtarget%\%_MWD%\Platform\" %_Nul3%
for /f %%# in ('dir /b /ad "!mpamfe!\Platform\*.*.*.*"') do set "_wdplat=%%#"
if exist "%mumtarget%\%_MWD%\Platform\%_wdplat%\MpSigStub.exe" del /f /q "%mumtarget%\%_MWD%\Platform\%_wdplat%\MpSigStub.exe" %_Nul3%
if not exist "!mpamfe!\Platform\%_wdplat%\ConfigSecurityPolicy.exe" copy /y "%mumtarget%\Program Files\Windows Defender\ConfigSecurityPolicy.exe" "%mumtarget%\%_MWD%\Platform\%_wdplat%\" %_Nul3%
if not exist "!mpamfe!\Platform\%_wdplat%\MpAsDesc.dll" copy /y "%mumtarget%\Program Files\Windows Defender\MpAsDesc.dll" "%mumtarget%\%_MWD%\Platform\%_wdplat%\" %_Nul3%
if not exist "!mpamfe!\Platform\%_wdplat%\MpEvMsg.dll" copy /y "%mumtarget%\Program Files\Windows Defender\MpEvMsg.dll" "%mumtarget%\%_MWD%\Platform\%_wdplat%\" %_Nul3%
if not exist "!mpamfe!\Platform\%_wdplat%\ProtectionManagement.dll" copy /y "%mumtarget%\Program Files\Windows Defender\ProtectionManagement.dll" "%mumtarget%\%_MWD%\Platform\%_wdplat%\" %_Nul3%
for /f %%A in ('dir /b /ad "%mumtarget%\Program Files\Windows Defender\*-*"') do (
if not exist "%mumtarget%\%_MWD%\Platform\%_wdplat%\%%A\" mkdir "%mumtarget%\%_MWD%\Platform\%_wdplat%\%%A" %_Nul3%
if not exist "!mpamfe!\Platform\%_wdplat%\%%A\MpAsDesc.dll.mui" copy /y "%mumtarget%\Program Files\Windows Defender\%%A\MpAsDesc.dll.mui" "%mumtarget%\%_MWD%\Platform\%_wdplat%\%%A\" %_Nul3%
if not exist "!mpamfe!\Platform\%_wdplat%\%%A\MpEvMsg.dll.mui" copy /y "%mumtarget%\Program Files\Windows Defender\%%A\MpEvMsg.dll.mui" "%mumtarget%\%_MWD%\Platform\%_wdplat%\%%A\" %_Nul3%
if not exist "!mpamfe!\Platform\%_wdplat%\%%A\ProtectionManagement.dll.mui" copy /y "%mumtarget%\Program Files\Windows Defender\%%A\ProtectionManagement.dll.mui" "%mumtarget%\%_MWD%\Platform\%_wdplat%\%%A\" %_Nul3%
)
if /i %arch%==x86 goto :eof
if not exist "!mpamfe!\Platform\%_wdplat%\x86\MpAsDesc.dll" copy /y "%mumtarget%\Program Files (x86)\Windows Defender\MpAsDesc.dll" "%mumtarget%\%_MWD%\Platform\%_wdplat%\x86\" %_Nul3%
for /f %%A in ('dir /b /ad "%mumtarget%\Program Files (x86)\Windows Defender\*-*"') do (
if not exist "%mumtarget%\%_MWD%\Platform\%_wdplat%\x86\%%A\" mkdir "%mumtarget%\%_MWD%\Platform\%_wdplat%\x86\%%A" %_Nul3%
if not exist "!mpamfe!\Platform\%_wdplat%\x86\%%A\MpAsDesc.dll.mui" copy /y "%mumtarget%\Program Files (x86)\Windows Defender\%%A\MpAsDesc.dll.mui" "%mumtarget%\%_MWD%\Platform\%_wdplat%\x86\%%A\" %_Nul3%
)
goto :eof

:pXML
if %_build% neq 18362 (
call :cXML stage
echo.
echo Processing 1 of 1 - Staging %cbsn%
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\%_DsmLog%" /Apply-Unattend:"!_cabdir!\stage.xml"
if !errorlevel! neq 0 if !errorlevel! neq 3010 (
  (echo.&echo Failed staging %cbsn%)>>"!logerr!"
  goto :eof
  )
)
if %_build% neq 18362 (call :Winner) else (call :Suppress)
if defined _dualSxS (
set "_SxsKey=%_CedKey%"
set "_SxsCmp=%_CedCmp%"
set "_SxsIdn=%_CedIdn%"
set "_SxsCF=256"
if %_build% neq 18362 (call :Winner) else (call :Suppress)
)
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\%_DsmLog%" /Add-Package /PackagePath:"!dest!\update.mum"
if !errorlevel! neq 0 (
  (echo.&echo Failed installing %cbsn%)>>"!logerr!"
  )
if %_build% neq 18362 (del /f /q "!_cabdir!\stage.xml" %_Nul3%)
goto :eof

:cXML
(
echo.^<?xml version="1.0" encoding="utf-8"?^>
echo.^<unattend xmlns="urn:schemas-microsoft-com:unattend"^>
echo.    ^<servicing^>
echo.        ^<package action="%1"^>
)>"!_cabdir!\%1.xml"
findstr /i Package_for_RollupFix "!dest!\update.mum" %_Nul3% && (
findstr /i Package_for_RollupFix "!dest!\update.mum" >>"!_cabdir!\%1.xml"
)
findstr /i Package_for_RollupFix "!dest!\update.mum" %_Nul3% || (
findstr /i Package_for_KB "!dest!\update.mum" | findstr /i /v _RTM >>"!_cabdir!\%1.xml"
)
(
echo.            ^<source location="!dest!\update.mum" /^>
echo.        ^</package^>
echo.     ^</servicing^>
echo.^</unattend^>
)>>"!_cabdir!\%1.xml"
goto :eof

:Suppress
for /f %%# in ('dir /b /a:-d "!dest!\%xBT%_%_SxsCmp%_*.manifest"') do set "_SxsCom=%%~n#"
for /f "tokens=4 delims=_" %%# in ('echo %_SxsCom%') do set "_SxsVer=%%#"
if not exist "%mumtarget%\Windows\WinSxS\Manifests\%_SxsCom%.manifest" (
%_Nul3% icacls "%mumtarget%\Windows\WinSxS\Manifests" /save "!_cabdir!\acl.txt"
%_Nul3% takeown /f "%mumtarget%\Windows\WinSxS\Manifests" /A
%_Nul3% icacls "%mumtarget%\Windows\WinSxS\Manifests" /grant:r "*S-1-5-32-544:(OI)(CI)(F)"
%_Nul3% copy /y "!dest!\%_SxsCom%.manifest" "%mumtarget%\Windows\WinSxS\Manifests\"
%_Nul3% icacls "%mumtarget%\Windows\WinSxS\Manifests" /setowner *S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464
%_Nul3% icacls "%mumtarget%\Windows\WinSxS" /restore "!_cabdir!\acl.txt"
%_Nul3% del /f /q "!_cabdir!\acl.txt"
)
reg.exe query HKLM\%COMPONENTS% %_Nul3% || reg.exe load HKLM\%COMPONENTS% "%mumtarget%\Windows\System32\Config\COMPONENTS" %_Nul3%
reg.exe query "%_Cmp%\%_SxsCom%" %_Nul3% && goto :Winner
for /f "skip=1 tokens=* delims=" %%# in ('certutil -hashfile "!dest!\%_SxsCom%.manifest" SHA256^|findstr /i /v CertUtil') do set "_SxsSha=%%#"
set "_SxsSha=%_SxsSha: =%"
set "_psin=%_SxsIdn%, Culture=neutral, Version=%_SxsVer%, PublicKeyToken=%_Pkt%, ProcessorArchitecture=%xBT%, versionScope=NonSxS"
for /f "tokens=* delims=" %%# in ('%_psc% "$str = '%_psin%'; [BitConverter]::ToString([Text.Encoding]::ASCII.GetBytes($str))-replace'-'" %_Nul6%') do set "_SxsHsh=%%#"
%_Nul3% reg.exe add "%_Cmp%\%_SxsCom%" /f /v "c^!%_Fnd%" /t REG_BINARY /d ""
%_Nul3% reg.exe add "%_Cmp%\%_SxsCom%" /f /v identity /t REG_BINARY /d "%_SxsHsh%"
%_Nul3% reg.exe add "%_Cmp%\%_SxsCom%" /f /v S256H /t REG_BINARY /d "%_SxsSha%"
%_Nul3% reg.exe add "%_Cmp%\%_SxsCom%" /f /v CF /t REG_DWORD /d "%_SxsCF%"
for /f "tokens=* delims=" %%# in ('reg.exe query HKLM\%COMPONENTS%\DerivedData\VersionedIndex %_Nul6% ^| findstr /i VersionedIndex') do reg.exe delete "%%#" /f %_Nul3%

:Winner
for /f "tokens=4 delims=_" %%# in ('dir /b /a:-d "!dest!\%xBT%_%_SxsCmp%_*.manifest"') do (
set "pv_al=%%#"
)
for /f "tokens=1-4 delims=." %%G in ('echo %pv_al%') do (
set "pv_os=%%G.%%H"
set "pv_mj=%%G"&set "pv_mn=%%H"&set "pv_bl=%%I"&set "pv_dl=%%J"
)
set kv_al=
reg.exe load HKLM\%SOFTWARE% "%mumtarget%\Windows\System32\Config\SOFTWARE" %_Nul3%
if not exist "%mumtarget%\Windows\WinSxS\Manifests\%xBT%_%_SxsCmp%_*.manifest" goto :SkipChk
reg.exe query "%_SxsKey%" %_Nul3% || goto :SkipChk
reg.exe query HKLM\%COMPONENTS% %_Nul3% || reg.exe load HKLM\%COMPONENTS% "%mumtarget%\Windows\System32\Config\COMPONENTS" %_Nul3%
reg.exe query "%_Cmp%" /f "%xBT%_%_SxsCmp%_*" /k %_Nul2% | find /i "HKEY_LOCAL_MACHINE" %_Nul1% || goto :SkipChk
call :ChkESUver %_Nul3%
set "wv_bl=0"&set "wv_dl=0"
reg.exe query "%_SxsKey%\%pv_os%" /ve %_Nul2% | findstr \( | findstr \. %_Nul1% || goto :SkipChk
for /f "tokens=2*" %%a in ('reg.exe query "%_SxsKey%\%pv_os%" /ve ^| findstr \(') do set "wv_al=%%b"
for /f "tokens=1-4 delims=." %%G in ('echo %wv_al%') do (
set "wv_mj=%%G"&set "wv_mn=%%H"&set "wv_bl=%%I"&set "wv_dl=%%J"
)

:SkipChk
reg.exe add "%_SxsKey%\%pv_os%" /f /v %pv_al% /t REG_BINARY /d 01 %_Nul3%
set skip_pv=0
if "%kv_al%"=="" (
reg.exe add "%_SxsKey%\%pv_os%" /f /ve /d %pv_al% %_Nul3%
reg.exe add "%_SxsKey%" /f /ve /d %pv_os% %_Nul3%
goto :EndChk
)
if %pv_mj% lss %kv_mj% (
set skip_pv=1
if %pv_bl% geq %wv_bl% if %pv_dl% geq %wv_dl% reg.exe add "%_SxsKey%\%pv_os%" /f /ve /d %pv_al% %_Nul3%
)
if %pv_mj% equ %kv_mj% if %pv_mn% lss %kv_mn% (
set skip_pv=1
if %pv_bl% geq %wv_bl% if %pv_dl% geq %wv_dl% reg.exe add "%_SxsKey%\%pv_os%" /f /ve /d %pv_al% %_Nul3%
)
if %pv_mj% equ %kv_mj% if %pv_mn% equ %kv_mn% if %pv_bl% lss %kv_bl% (
set skip_pv=1
)
if %pv_mj% equ %kv_mj% if %pv_mn% equ %kv_mn% if %pv_bl% equ %kv_bl% if %pv_dl% lss %kv_dl% (
set skip_pv=1
)
if %skip_pv% equ 0 (
reg.exe add "%_SxsKey%\%pv_os%" /f /ve /d %pv_al% %_Nul3%
reg.exe add "%_SxsKey%" /f /ve /d %pv_os% %_Nul3%
)

:EndChk
if /i %xOS%==x86 if /i not %arch%==x86 (
  reg.exe save HKLM\%SOFTWARE% "%mumtarget%\Windows\System32\Config\SOFTWARE2" %_Nul1%
  reg.exe query HKLM\%COMPONENTS% %_Nul3% && reg.exe save HKLM\%COMPONENTS% "%mumtarget%\Windows\System32\Config\COMPONENTS2" %_Nul1%
)
reg.exe unload HKLM\%SOFTWARE% %_Nul3%
reg.exe unload HKLM\%COMPONENTS% %_Nul3%
if /i %xOS%==x86 if /i not %arch%==x86 (
  move /y "%mumtarget%\Windows\System32\Config\SOFTWARE2" "%mumtarget%\Windows\System32\Config\SOFTWARE" %_Nul1%
  if exist "%mumtarget%\Windows\System32\Config\COMPONENTS2" move /y "%mumtarget%\Windows\System32\Config\COMPONENTS2" "%mumtarget%\Windows\System32\Config\COMPONENTS" %_Nul1%
)
goto :eof

:ChkESUver
set kv_os=
reg.exe query "%_SxsKey%" /ve | findstr \( | findstr \. || goto :eof
for /f "tokens=2*" %%a in ('reg.exe query "%_SxsKey%" /ve ^| findstr \(') do set "kv_os=%%b"
if "%kv_os%"=="" goto :eof
set kv_al=
reg.exe query "%_SxsKey%\%kv_os%" /ve | findstr \( | findstr \. || goto :eof
for /f "tokens=2*" %%a in ('reg.exe query "%_SxsKey%\%kv_os%" /ve ^| findstr \(') do set "kv_al=%%b"
if "%kv_al%"=="" goto :eof
reg.exe query "%_Cmp%" /f "%xBT%_%_SxsCmp%_%_Pkt%_%kv_al%_*" /k %_Nul2% | find /i "%kv_al%" %_Nul1% || (
set kv_al=
goto :eof
)
for /f "tokens=1-4 delims=." %%G in ('echo %kv_al%') do (
set "kv_mj=%%G"&set "kv_mn=%%H"&set "kv_bl=%%I"&set "kv_dl=%%J"
)
goto :eof

:updt_mount
if not exist "!_cabdir!\" mkdir "!_cabdir!"
if exist "%_mount%\" rmdir /s /q "%_mount%\"
if not exist "%_mount%\" mkdir "%_mount%"
set _www=%~1
set _nnn=%~nx1
set isappx=
set isappx=%2
if defined isappx (
set _eosC=0
set _eosP=0
set _eosT=0
)
for %%# in (uProf,uProN,uSDC,uSDD,_upgr,handle1,handle2) do set %%#=0
for %%# in (iCore,iCorN,iCorS,iCorC,iTeam,iEntr,iEntN,iSRSC,iSRSD,iHome,iHomN,iProf,iProN,iSSC,iSSD,iSDC,iSDD) do set "%%#="
if /i not %_nnn%==winre.wim if %_build% geq 17063 if %imgcount% gtr 1 if %DisableUpdatingUpgrade% equ 0 set _upgr=1
for /L %%# in (1,1,%imgcount%) do imagex /info "%_www%" %%# >bin\info%%#.txt 2>&1
if /i not %_nnn%==winre.wim for /L %%# in (1,1,%imgcount%) do (
if not defined iHome if %_eosC% equ 0 (find /i "Core</EDITIONID>" bin\info%%#.txt %_Nul3% && set iHome=%%#)
if not defined iHomN if %_eosC% equ 0 (find /i "CoreN</EDITIONID>" bin\info%%#.txt %_Nul3% && set iHomN=%%#)
if not defined iProf if %_eosP% equ 0 (find /i "Professional</EDITIONID>" bin\info%%#.txt %_Nul3% && set iProf=%%#)
if not defined iProN if %_eosP% equ 0 (find /i "ProfessionalN</EDITIONID>" bin\info%%#.txt %_Nul3% && set iProN=%%#)
if not defined iSSC (find /i "ServerStandard</EDITIONID>" bin\info%%#.txt %_Nul3% && (findstr /i /c:"Server Core" bin\info%%#.txt %_Nul3% && set iSSC=%%#))
if not defined iSSD (find /i "ServerStandard</EDITIONID>" bin\info%%#.txt %_Nul3% && (findstr /i /c:"Server Core" bin\info%%#.txt %_Nul3% || set iSSD=%%#))
if not defined iSDC (find /i "ServerDatacenter</EDITIONID>" bin\info%%#.txt %_Nul3% && (findstr /i /c:"Server Core" bin\info%%#.txt %_Nul3% && set iSDC=%%#))
if not defined iSDD (find /i "ServerDatacenter</EDITIONID>" bin\info%%#.txt %_Nul3% && (findstr /i /c:"Server Core" bin\info%%#.txt %_Nul3% || set iSDD=%%#))
)
if %_upgr% equ 1 (
if defined iHome if defined iProf set uProf=1
if defined iHomN if defined iProN set uProN=1
if defined iSSC if defined iSDC set uSDC=1
if defined iSSD if defined iSDD set uSDD=1
)
del /f /q bin\info*.txt
rem editions deleted in reverse order
if %uSDD% equ 1 (
set /a imgcount-=1
wimlib-imagex.exe delete "%_www%" %iSDD% --soft %_Nul3%
)
if %uSDC% equ 1 (
set /a imgcount-=1
wimlib-imagex.exe delete "%_www%" %iSDC% --soft %_Nul3%
)
if %uProN% equ 1 (
if %_pmcppc% equ 1 if %_build% geq 19041 call :pmcppcpro %iProN%
set /a imgcount-=1
wimlib-imagex.exe delete "%_www%" %iProN% --soft %_Nul3%
)
if %uProf% equ 1 (
if %_pmcppc% equ 1 if %_build% geq 19041 call :pmcppcpro %iProf%
set /a imgcount-=1
wimlib-imagex.exe delete "%_www%" %iProf% --soft %_Nul3%
)
set _imgi=%imgcount%
for /L %%# in (1,1,%imgcount%) do imagex /info "%_www%" %%# >bin\info%%#.txt 2>&1
if /i not %_nnn%==winre.wim for /L %%# in (1,1,%imgcount%) do (
if not defined iCore (find /i "Core</EDITIONID>" bin\info%%#.txt %_Nul3% && set iCore=%%#)
if not defined iCorN (find /i "CoreN</EDITIONID>" bin\info%%#.txt %_Nul3% && set iCorN=%%#)
if not defined iCorS (find /i "CoreSingleLanguage</EDITIONID>" bin\info%%#.txt %_Nul3% && set iCorS=%%#)
if not defined iCorC (find /i "CoreCountrySpecific</EDITIONID>" bin\info%%#.txt %_Nul3% && set iCorC=%%#)
if not defined iEntr (find /i "Professional</EDITIONID>" bin\info%%#.txt %_Nul3% && set iEntr=%%#)
if not defined iEntN (find /i "ProfessionalN</EDITIONID>" bin\info%%#.txt %_Nul3% && set iEntN=%%#)
if not defined iTeam (find /i "PPIPro</EDITIONID>" bin\info%%#.txt %_Nul3% && set iTeam=%%#)
if not defined iSRSC (find /i "ServerStandard</EDITIONID>" bin\info%%#.txt %_Nul3% && (findstr /i /c:"Server Core" bin\info%%#.txt %_Nul3% && set iSRSC=%%#))
if not defined iSRSD (find /i "ServerStandard</EDITIONID>" bin\info%%#.txt %_Nul3% && (findstr /i /c:"Server Core" bin\info%%#.txt %_Nul3% || set iSRSD=%%#))
)
for %%# in (iCore,iCorN,iCorS,iCorC,iTeam,iEntr,iEntN,iSRSC,iSRSD,iHome,iHomN) do (
if not defined %%# set %%#=0
)
set "_wtx=Windows 10"
if %iCore% neq 0 (
find /i "<NAME>" bin\info%iCore%.txt %_Nul2% | find /i "Windows 11" %_Nul1% && (set "_wtx=Windows 11")
find /i "<NAME>" bin\info%iCore%.txt %_Nul2% | find /i "Windows 12" %_Nul1% && (set "_wtx=Windows 12")
)
if %iCorN% neq 0 (
find /i "<NAME>" bin\info%iCorN%.txt %_Nul2% | find /i "Windows 11" %_Nul1% && (set "_wtx=Windows 11")
find /i "<NAME>" bin\info%iCorN%.txt %_Nul2% | find /i "Windows 12" %_Nul1% && (set "_wtx=Windows 12")
)
set "_wsr=Windows Server 2022"
if %iSRSC% neq 0 (
find /i "<NAME>" bin\info%iSRSC%.txt %_Nul2% | find /i " 2025" %_Nul1% && (set "_wsr=Windows Server 2025")
if %_build% geq 26010 (set "_wsr=Windows Server 2025")
)
if %iSRSD% neq 0 (
find /i "<NAME>" bin\info%iSRSD%.txt %_Nul2% | find /i " 2025" %_Nul1% && (set "_wsr=Windows Server 2025")
if %_build% geq 26010 (set "_wsr=Windows Server 2025")
)
del /f /q bin\info*.txt
if /i %_nnn%==winre.wim (
set "_inx=1"&call :dowork
goto :eof
)
set "indices="
set "indexes="
if defined isappx (
for /L %%# in (1,1,%imgcount%) do (
if defined indexes (set "indexes=!indexes!,%%#") else (set "indexes=%%#")
)
goto :appxdo
)
for /L %%# in (1,1,%imgcount%) do (
set _oa%%#=0
if %_eosT% equ 0 if %_eosP% equ 0 if %_eosC% equ 0 (if defined indices (set "indices=!indices!,%%#") else (set "indices=%%#"))
if %_eosT% equ 0 if %_eosP% equ 0 if %_eosC% equ 1 if %%# neq %iCore% if %%# neq %iCorN% if %%# neq %iCorS% if %%# neq %iCorC% (if defined indices (set "indices=!indices!,%%#") else (set "indices=%%#"))
if %_eosT% equ 0 if %_eosP% equ 1 if %_eosC% equ 1 if %%# neq %iEntr% if %%# neq %iEntN% if %%# neq %iCore% if %%# neq %iCorN% if %%# neq %iCorS% if %%# neq %iCorC% (if defined indices (set "indices=!indices!,%%#") else (set "indices=%%#"))
if %_eosT% equ 0 if %_eosP% equ 1 if %_eosC% equ 0 if %%# neq %iEntr% if %%# neq %iEntN% (if defined indices (set "indices=!indices!,%%#") else (set "indices=%%#"))
if %_eosT% equ 1 if %_eosP% equ 0 if %_eosC% equ 0 if %%# neq %iTeam% (if defined indices (set "indices=!indices!,%%#") else (set "indices=%%#"))
if %_eosT% equ 1 if %_eosP% equ 0 if %_eosC% equ 1 if %%# neq %iTeam% if %%# neq %iCore% if %%# neq %iCorN% if %%# neq %iCorS% if %%# neq %iCorC% (if defined indices (set "indices=!indices!,%%#") else (set "indices=%%#"))
if %_eosT% equ 1 if %_eosP% equ 1 if %_eosC% equ 0 if %%# neq %iTeam% if %%# neq %iEntr% if %%# neq %iEntN% (if defined indices (set "indices=!indices!,%%#") else (set "indices=%%#"))
if %_eosT% equ 1 if %_eosP% equ 1 if %_eosC% equ 1 if %%# neq %iTeam% if %%# neq %iEntr% if %%# neq %iEntN% if %%# neq %iCore% if %%# neq %iCorN% if %%# neq %iCorS% if %%# neq %iCorC% (if defined indices (set "indices=!indices!,%%#") else (set "indices=%%#"))
)
if %_runIPA% equ 1 for /L %%# in (1,1,%imgcount%) do (
if %_eosC% equ 1 if %%# equ %iCore% set _oa%%#=1
if %_eosC% equ 1 if %%# equ %iCorN% set _oa%%#=1
if %_eosC% equ 1 if %%# equ %iCorS% set _oa%%#=1
if %_eosC% equ 1 if %%# equ %iCorC% set _oa%%#=1
if %_eosP% equ 1 if %%# equ %iEntr% set _oa%%#=1
if %_eosP% equ 1 if %%# equ %iEntN% set _oa%%#=1
if %_eosT% equ 1 if %%# equ %iTeam% set _oa%%#=1
)
if %_runIPA% equ 1 if defined indices for %%# in (%indices%) do (
set _oa%%#=0
)
if %_runIPA% equ 1 for /L %%# in (1,1,%imgcount%) do (
if !_oa%%#! equ 1 (if defined indexes (set "indexes=!indexes!,%%#") else (set "indexes=%%#"))
)
set _noCmpt=0
if %_runIPA% equ 0 if not defined indices set _noCmpt=1
if %_runIPA% equ 1 if not defined indices if not defined indexes set _noCmpt=1
if %_noCmpt% equ 1 (
call :dk_color1 %_Yellow% "No compatible editions found with applicable updates." 4
goto :eof
)
if defined indices for %%# in (%indices%) do (set "_inx=%%#"&call :dowork)
:appxdo
set isappx=1
if defined indexes for %%# in (%indexes%) do (set "_inx=%%#"&call :dowork)
if %_extVirt% equ 0 goto :eof
if %DeleteSource% neq 1 goto :eof
call :dk_color1 %Blue% "=== Deleting Source Edition{s} . . ." 4 5
if %_didProf% equ 1 call :dDelete Professional
if %_didProN% equ 1 call :dDelete ProfessionalN
if %_didHome% equ 1 call :dDelete Core
for /f "tokens=3 delims=: " %%# in ('imagex /info "%_www%" ^|findstr /i /b /c:"Image Count"') do set finalimages=%%#
if %finalimages% gtr 1 goto :eof
for /f "tokens=3 delims=<>" %%# in ('imagex /info "%_www%" 1 ^| find /i "<EDITIONID>"') do set editionid=%%#
set AIO=0&set _count=0
call :virtlabel
goto :eof

:dowork
if /i not %_nnn%==winre.wim call :dk_color1 %Gray% "=== Servicing Index: %_inx%" 4
%_dism2%:"!_cabdir!" /Mount-Wim /Wimfile:"%_www%" /Index:%_inx% /MountDir:"%_mount%"
if !errorlevel! neq 0 (
%_dism1% /Image:"%_mount%" /LogPath:"%_dLog%\DismNUL.log" /Get-Packages %_Null%
%_dism1% /Unmount-Wim /MountDir:"%_mount%" /Discard
%_dism1% /Cleanup-Wim %_Nul3%
goto :eof
)
if defined isappx goto :doappx

if /i not %_nnn%==winre.wim if %_wimEdge% equ 1 if %SkipEdge% equ 0 (
call :dk_color1 %Gray% "=== Adding Microsoft Edge . . ." 4
%_dism2%:"!_cabdir!" /Image:"%_mount%" /LogPath:"%_dLog%\DismEdgeWim.log" /Add-Edge /SupportPath:"!_UUP!"
if !errorlevel! neq 0 (
  (echo.&echo Failed adding Edge.wim)>>"!logerr!"
  )
)
if /i not %_nnn%==winre.wim if %_runIPA% equ 1 (
call :dk_color1 %Gray% "=== Adding Apps . . ." 4 5
call :appx_wim
%_dism2%:"!_cabdir!" /Commit-Wim /MountDir:"%_mount%"
call :dk_color1 %Gray% "=== Adding Updates . . ." 4
)
if /i not %_nnn%==winre.wim if %_build% geq 19041 if %_upgr% equ 1 if %_pmcppc% equ 1 if not exist "%_mount%\Windows\Servicing\Packages\Microsoft-Windows-Printing-PMCPPC-FoD-Package*.mum" call :pmcppcwim
call :updatewim
if defined mounterr goto :eof
if %NetFx3% equ 1 if %dvd% equ 1 call :enablenet35
if /i %arch%==x86 (set efifile=bootia32.efi) else if /i %arch%==x64 (set efifile=bootx64.efi) else (set efifile=bootaa64.efi)
if !handle1! equ 0 if %dvd% equ 1 (
set handle1=1
if %UpdtBootFiles% equ 1 (
for %%i in (efisys.bin,efisys_noprompt.bin) do if exist "%_mount%\Windows\Boot\DVD\EFI\en-US\%%i" (xcopy /CIDRY "%_mount%\Windows\Boot\DVD\EFI\en-US\%%i" "%_target%\efi\microsoft\boot\" %_Nul3%)
if /i not %arch%==arm64 (
xcopy /CIDRY "%_mount%\Windows\Boot\PCAT\bootmgr" "%_target%\" %_Nul3%
xcopy /CIDRY "%_mount%\Windows\Boot\PCAT\memtest.exe" "%_target%\boot\" %_Nul3%
xcopy /CIDRY "%_mount%\Windows\Boot\EFI\memtest.efi" "%_target%\efi\microsoft\boot\" %_Nul3%
)
if exist "%_mount%\Windows\Boot\EFI\winsipolicy.p7b" if exist "%_target%\efi\microsoft\boot\winsipolicy.p7b" xcopy /CIDRY "%_mount%\Windows\Boot\EFI\winsipolicy.p7b" "%_target%\efi\microsoft\boot\" %_Nul3%
if exist "%_mount%\Windows\Boot\EFI\CIPolicies\" if exist "%_target%\efi\microsoft\boot\cipolicies\" xcopy /CEDRY "%_mount%\Windows\Boot\EFI\CIPolicies" "%_target%\efi\microsoft\boot\cipolicies\" %_Nul3%
)
if exist "%_target%\efi\boot\bootmgfw.efi" xcopy /CIDRY "%_mount%\Windows\Boot\EFI\bootmgfw.efi" "%_target%\efi\boot\bootmgfw.efi" %_Nul3%
xcopy /CIDRY "%_mount%\Windows\Boot\EFI\bootmgfw.efi" "%_target%\efi\boot\!efifile!" %_Nul3%
xcopy /CIDRY "%_mount%\Windows\Boot\EFI\bootmgr.efi" "%_target%\" %_Nul3%
)
if !handle2! equ 0 if %dvd% equ 1 if not exist "%_mount%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" if exist "%_mount%\Windows\Servicing\Packages\Package_for_RollupFix*.mum" (
set handle2=1
set isomin=0
for /f "tokens=%tok% delims=_." %%i in ('dir /b /a:-d /od "%_mount%\Windows\WinSxS\Manifests\%_ss%_microsoft-windows-coreos-revision*.manifest"') do (set isover=%%i.%%j&set isomaj=%%i&set isomin=%%j)
set "isokey=Microsoft\Windows NT\CurrentVersion\Update\TargetingInfo\Installed"
for /f %%i in ('"offlinereg.exe "%_mount%\Windows\system32\config\SOFTWARE" "!isokey!" enumkeys %_Nul6% ^| findstr /i /r ".*\.OS""') do if not errorlevel 1 (
  for /f "tokens=3 delims==:" %%A in ('"offlinereg.exe "%_mount%\Windows\system32\config\SOFTWARE" "!isokey!\%%i" getvalue Branch %_Nul6%"') do set "isobranch=%%~A"
  for /f "tokens=5,6 delims==:." %%A in ('"offlinereg.exe "%_mount%\Windows\system32\config\SOFTWARE" "!isokey!\%%i" getvalue Version %_Nul6%"') do if %%A gtr !isomaj! (
    set "isover=%%~A.%%B
    set isomaj=%%~A
    set "isomin=%%B
    set "_fixSV=!isomaj!"&set "_fixEP=!isomaj!"
    )
  )
)
if exist "%_mount%\Windows\system32\UpdateAgent.dll" if not exist "%SystemRoot%\temp\UpdateAgent.dll" copy /y "%_mount%\Windows\system32\UpdateAgent.dll" %SystemRoot%\temp\ %_Nul1%
if exist "%_mount%\Windows\system32\Facilitator.dll" if not exist "%SystemRoot%\temp\Facilitator.dll" copy /y "%_mount%\Windows\system32\Facilitator.dll" %SystemRoot%\temp\ %_Nul1%
goto :doProceed

:doappx
if %_wimEdge% equ 1 if %SkipEdge% equ 0 (
call :dk_color1 %Gray% "=== Adding Microsoft Edge . . ." 4
%_dism2%:"!_cabdir!" /Image:"%_mount%" /LogPath:"%_dLog%\DismEdgeWim.log" /Add-Edge /SupportPath:"!_UUP!"
if !errorlevel! neq 0 (
  (echo.&echo Failed adding Edge.wim)>>"!logerr!"
  )
)
call :dk_color1 %Gray% "=== Adding Apps . . ." 4 5
call :appx_wim
if %_upgr% equ 1 if %_pmcppc% equ 1 if not exist "%_mount%\Windows\Servicing\Packages\Microsoft-Windows-Printing-PMCPPC-FoD-Package*.mum" call :pmcppcwim

:doProceed
if %AddDrivers% equ 0 goto :doCommit
if not defined DrvSrcALL if not defined DrvSrcPE if not defined DrvSrcOS goto :doCommit
if /i %_nnn%==winre.wim (
if defined DrvSrcALL %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DrvWinPE.log" /Add-Driver /Driver:"!DrvSrcALL!" /Recurse
if defined DrvSrcPE %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DrvWinPE.log" /Add-Driver /Driver:"!DrvSrcPE!" /Recurse
goto :doCommit
)
call :dk_color1 %Gray% "=== Adding Drivers . . ." 4
if defined DrvSrcALL %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DrvOS.log" /Add-Driver /Driver:"!DrvSrcALL!" /Recurse
if defined DrvSrcOS %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DrvOS.log" /Add-Driver /Driver:"!DrvSrcOS!" /Recurse

:doCommit
%_dism2%:"!_cabdir!" /Commit-Wim /MountDir:"%_mount%"
if !errorlevel! neq 0 (
%_dism1% /Image:"%_mount%" /LogPath:"%_dLog%\DismNUL.log" /Get-Packages %_Null%
%_dism1% /Unmount-Wim /MountDir:"%_mount%" /Discard
%_dism1% /Cleanup-Wim %_Nul3%
)
if /i %_nnn%==winre.wim goto :crDsc

:crHome
if %_inx% neq %iHome% goto :crProf
if %StartVirtual% equ 0 goto :crProf
set _didHome=1&call :V_Ext Home

:crProf
if %uProf% equ 0 goto :crProN
if %_inx% neq %iHome% goto :crProN
call :dk_color1 %Gray% "=== Creating Edition: Pro" 4
%_dism2%:"!_cabdir!" /Image:"%_mount%" /LogPath:"%_dLog%\DismCore2Pro.log" /Set-Edition:Professional /Channel:Retail
%_dism2%:"!_cabdir!" /Commit-Image /MountDir:"%_mount%" /Append %_Supp%
call set /a _imgi+=1
call set ddesc="%_wtx% Pro"
wimlib-imagex.exe info "%_www%" !_imgi! !ddesc! !ddesc! --image-property DISPLAYNAME=!ddesc! --image-property DISPLAYDESCRIPTION=!ddesc! --image-property FLAGS=Professional %_Nul3%
if %StartVirtual% equ 0 goto :crProN
set _didProf=1&call :V_Ext Prof

:crProN
if %uProN% equ 0 goto :crSDC
if %_inx% neq %iHomN% goto :crSDC
call :dk_color1 %Gray% "=== Creating Edition: Pro N" 4
%_dism2%:"!_cabdir!" /Image:"%_mount%" /LogPath:"%_dLog%\DismCoreN2ProN.log" /Set-Edition:ProfessionalN /Channel:Retail
%_dism2%:"!_cabdir!" /Commit-Image /MountDir:"%_mount%" /Append %_Supp%
call set /a _imgi+=1
call set ddesc="%_wtx% Pro N"
wimlib-imagex.exe info "%_www%" !_imgi! !ddesc! !ddesc! --image-property DISPLAYNAME=!ddesc! --image-property DISPLAYDESCRIPTION=!ddesc! --image-property FLAGS=ProfessionalN %_Nul3%
if %StartVirtual% equ 0 goto :crSDC
set _didProN=1&call :V_Ext ProN

:crSDC
if %uSDC% equ 0 goto :crSDD
if %_inx% neq %iSSC% goto :crSDD
call :dk_color1 %Gray% "=== Creating Edition: Datacenter Core" 4
%_dism2%:"!_cabdir!" /Image:"%_mount%" /LogPath:"%_dLog%\DismSrvSc2SrvDc.log" /Set-Edition:ServerDatacenterCor /Channel:Retail
%_dism2%:"!_cabdir!" /Commit-Image /MountDir:"%_mount%" /Append %_Supp%
call set /a _imgi+=1
call set cname="%_wsr% ServerDatacenterCore"
call set dname="%_wsr% Datacenter"
call set ddesc="(Recommended) This option omits most of the Windows graphical environment. Manage with a command prompt and PowerShell, or remotely with Windows Admin Center or other tools."
wimlib-imagex.exe info "%_www%" !_imgi! !cname! !cname! --image-property DISPLAYNAME=!dname! --image-property DISPLAYDESCRIPTION=!ddesc! --image-property FLAGS=ServerDatacenterCore %_Nul3%

:crSDD
if %uSDD% equ 0 goto :crEnd
if %_inx% neq %iSSD% goto :crEnd
call :dk_color1 %Gray% "=== Creating Edition: Datacenter" 4
%_dism2%:"!_cabdir!" /Image:"%_mount%" /LogPath:"%_dLog%\DismSrvSf2SrvDf.log" /Set-Edition:ServerDatacenter /Channel:Retail
%_dism2%:"!_cabdir!" /Commit-Image /MountDir:"%_mount%" /Append %_Supp%
call set /a _imgi+=1
call set cname="%_wsr% ServerDatacenter"
call set dname="%_wsr% Datacenter (Desktop Experience)"
call set ddesc="This option installs the full Windows graphical environment, consuming extra drive space. It can be useful if you want to use the Windows desktop or have an app that requires it."
wimlib-imagex.exe info "%_www%" !_imgi! !cname! !cname! --image-property DISPLAYNAME=!dname! --image-property DISPLAYDESCRIPTION=!ddesc! --image-property FLAGS=ServerDatacenter %_Nul3%

:crEnd
if %_SrvESD% equ 1 goto :crDsc
if %StartVirtual% equ 0 goto :crDsc
if %uProf% equ 0 if %_inx% equ %iEntr% (set _didProf=1&call :V_Ext Prof)
if %uProN% equ 0 if %_inx% equ %iEntN% (set _didProN=1&call :V_Ext ProN)

:crDsc
%_dism2%:"!_cabdir!" /Unmount-Wim /MountDir:"%_mount%" /Discard
goto :eof

:pmcppcpro
if exist "bin\temp\pmcppc\Microsoft-Windows-Printing-PMCPPC-FoD-Package*.mum" goto :eof
mkdir bin\temp\pmcppc %_Nul3%
for /f %%# in ('dir /b /a:-d "!_UUP!\*Microsoft-Windows-Printing-PMCPPC-FoD-Package*.*"') do (
if /i "%%~x#"==".cab" (expand.exe -f:* "!_UUP!\%%#" bin\temp\pmcppc\ %_Nul3%) else (wimlib-imagex.exe apply "!_UUP!\%%#" 1 bin\temp\pmcppc\ --no-acls --no-attributes %_Nul3%)
)
7z.exe e "%_www%" -o.\bin\temp\pmcppc %1\Windows\servicing\Packages\Microsoft-Windows-Printing-PMCPPC-FoD-Package~%_Pkt%~*~%langid%~*.* %1\Windows\WinSxS\Manifests\*_microsoft-windows-p..oyment-languagepack_*.manifest %1\Windows\WinSxS\Manifests\*_microsoft-windows-p..ui-pmcppc.resources_*.manifest -aoa %_Nul3%
for /f %%# in ('dir /b /a:-d "bin\temp\pmcppc\*_microsoft-windows-p..ui-pmcppc.resources_*.manifest"') do (
7z.exe e "%_www%" -o.\bin\temp\pmcppc\%%~n# %1\Windows\WinSxS\%%~n#\* -aoa %_Nul3%
)
mkdir bin\temp\sxs %_Nul3%
for /f %%a in ('dir /b /a:-d "bin\temp\pmcppc\*.manifest"') do SxSExpand.exe "!_work!\bin\temp\pmcppc\%%a" "bin\temp\sxs\%%a" %_Nul3%
if exist "bin\temp\sxs\*.manifest" move /y "bin\temp\sxs\*" "bin\temp\pmcppc\" %_Nul1%
rmdir /s /q bin\temp\sxs\
goto :eof

:pmcppcwim
for /f %%# in ('dir /b /a:-d "bin\temp\pmcppc\Microsoft-Windows-Printing-PMCPPC-FoD-Package~%_Pkt%~*~~*.mum" %_Nul6%') do (
%_dism2%:"!_cabdir!" /Image:"%_mount%" /LogPath:"%_dLog%\PMCPPC_FoD.log" /Add-Package /PackagePath:"bin\temp\pmcppc\%%#" %_Nul3%
if !errorlevel! neq 0 (
  (echo.&echo Failed installing %%~n#)>>"!logerr!"
  )
)
for /f %%# in ('dir /b /a:-d "bin\temp\pmcppc\Microsoft-Windows-Printing-PMCPPC-FoD-Package~%_Pkt%~*~%langid%~*.mum" %_Nul6%') do (
%_dism2%:"!_cabdir!" /Image:"%_mount%" /LogPath:"%_dLog%\PMCPPC_FoD.log" /Add-Package /PackagePath:"bin\temp\pmcppc\%%#" %_Nul3%
if !errorlevel! neq 0 (
  (echo.&echo Failed installing %%~n#)>>"!logerr!"
  )
)
goto :eof

:dDelete
for /f "tokens=3 delims=: " %%# in ('imagex /info "%_www%" ^|findstr /i /b /c:"Image Count"') do set vimages=%%#
for /l %%# in (1,1,%vimages%) do imagex /info "%_www%" %%# >bin\info%%#.txt 2>&1
for /L %%# in (1,1,%vimages%) do (
find /i "<EDITIONID>%1</EDITIONID>" bin\info%%#.txt %_Nul3% && (
  echo %1
  wimlib-imagex.exe delete "%_www%" %%# --soft %_Nul3%
  )
)
del /f /q bin\info*.txt %_Nul3%
goto :eof

:cleanup
set savc=0&set savr=1
if %_build% geq 18362 (set savc=3&set savr=3)
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
if /i not %arch%==arm64 (
reg.exe load HKLM\%ksub% "%mumtarget%\Windows\System32\Config\SOFTWARE" %_Nul1%
reg.exe add HKLM\%ksub%\%_SxsCfg% /v SupersededActions /t REG_DWORD /d %savr% /f %_Nul1%
reg.exe add HKLM\%ksub%\%_SxsCfg% /v DisableComponentBackups /t REG_DWORD /d 1 /f %_Nul1%
reg.exe unload HKLM\%ksub% %_Nul1%
)
%_wrb% %_dism2%:"!_cabdir!" %dismtarget% /Cleanup-Image /StartComponentCleanup
if %Cleanup% neq 0 (
if %ResetBase% neq 0 %_dism2%:"!_cabdir!" %dismtarget% /Cleanup-Image /StartComponentCleanup /ResetBase %_Null%
)
call :cleanmanual&goto :eof
)
if %Cleanup% equ 0 call :cleanmanual&goto :eof
if exist "%mumtarget%\Windows\WinSxS\pending.xml" call :cleanmanual&goto :eof
if /i not %arch%==arm64 (
reg.exe load HKLM\%ksub% "%mumtarget%\Windows\System32\Config\SOFTWARE" %_Nul1%
if %ResetBase% equ 1 (
reg.exe add HKLM\%ksub%\%_SxsCfg% /v DisableResetbase /t REG_DWORD /d 0 /f %_Nul1%
reg.exe add HKLM\%ksub%\%_SxsCfg% /v SupersededActions /t REG_DWORD /d %savr% /f %_Nul1%
) else (
reg.exe add HKLM\%ksub%\%_SxsCfg% /v DisableResetbase /t REG_DWORD /d 1 /f %_Nul1%
reg.exe add HKLM\%ksub%\%_SxsCfg% /v SupersededActions /t REG_DWORD /d %savc% /f %_Nul1%
)
if /i %xOS%==x86 if /i not %arch%==x86 reg.exe save HKLM\%ksub% "%mumtarget%\Windows\System32\Config\SOFTWARE2" %_Nul1%
reg.exe unload HKLM\%ksub% %_Nul1%
if /i %xOS%==x86 if /i not %arch%==x86 move /y "%mumtarget%\Windows\System32\Config\SOFTWARE2" "%mumtarget%\Windows\System32\Config\SOFTWARE" %_Nul1%
) else (
%_Nul3% offlinereg.exe "%mumtarget%\Windows\System32\Config\SOFTWARE" %_SxsCfg% setvalue SupersededActions 3 4
if exist "%mumtarget%\Windows\System32\Config\SOFTWARE.new" del /f /q "%mumtarget%\Windows\System32\Config\SOFTWARE"&ren "%mumtarget%\Windows\System32\Config\SOFTWARE.new" SOFTWARE
)
set "_Nul8="
if %_build% geq 25380 (
set "_Nul8=1>nul 2>nul"
call :dk_color1 %Gray% "=== Running DISM Cleanup . . ." 4
)
%_dism2%:"!_cabdir!" %dismtarget% /Cleanup-Image /StartComponentCleanup %_Nul8%
if %ResetBase% neq 0 %_dism2%:"!_cabdir!" %dismtarget% /Cleanup-Image /StartComponentCleanup /ResetBase %_Null%
call :cleanmanual&goto :eof

:cleanmanual
if exist "%mumtarget%\Windows\WinSxS\ManifestCache\*.bin" (
takeown /f "%mumtarget%\Windows\WinSxS\ManifestCache\*.bin" /A %_Nul3%
icacls "%mumtarget%\Windows\WinSxS\ManifestCache\*.bin" /grant *S-1-5-32-544:F %_Nul3%
del /f /q "%mumtarget%\Windows\WinSxS\ManifestCache\*.bin" %_Nul3%
)
if exist "%mumtarget%\Windows\WinSxS\Temp\PendingDeletes\*" (
takeown /f "%mumtarget%\Windows\WinSxS\Temp\PendingDeletes\*" /A %_Nul3%
icacls "%mumtarget%\Windows\WinSxS\Temp\PendingDeletes\*" /grant *S-1-5-32-544:F %_Nul3%
del /f /q "%mumtarget%\Windows\WinSxS\Temp\PendingDeletes\*" %_Nul3%
)
if exist "%mumtarget%\Windows\WinSxS\Temp\TransformerRollbackData\*" (
takeown /f "%mumtarget%\Windows\WinSxS\Temp\TransformerRollbackData\*" /R /A %_Nul3%
icacls "%mumtarget%\Windows\WinSxS\Temp\TransformerRollbackData\*" /grant *S-1-5-32-544:F /T %_Nul3%
del /s /f /q "%mumtarget%\Windows\WinSxS\Temp\TransformerRollbackData\*" %_Nul3%
)
if exist "%mumtarget%\Windows\inf\*.log" (
del /f /q "%mumtarget%\Windows\inf\*.log" %_Nul3%
)
for /f "tokens=* delims=" %%# in ('dir /b /ad "%mumtarget%\Windows\CbsTemp\" %_Nul6%') do rmdir /s /q "%mumtarget%\Windows\CbsTemp\%%#\" %_Nul3%
del /s /f /q "%mumtarget%\Windows\CbsTemp\*" %_Nul3%
goto :eof

:enablenet35
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" goto :eof
if exist "%mumtarget%\Windows\Microsoft.NET\Framework\v2.0.50727\ngen.exe" goto :eof
if not exist "%_target%\sources\sxs\*netfx3*.cab" goto :eof
set "net35source=%_target%\sources\sxs"
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNetFx3.log" /Enable-Feature /FeatureName:NetFx3 /All /LimitAccess /Source:"%net35source%"
if !errorlevel! neq 0 (
  (echo.&echo Failed enabling NetFx3 feature)>>"!logerr!"
  )
if defined netupdt (
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNetFx3.log" /Add-Package %netupdt%
if !errorlevel! neq 0 (
  (echo.&echo Failed installing NetFx3 update)>>"!logerr!"
  )
)
if not defined netroll if not defined netlcu if not defined netmsu if not defined cumulative (call :cleanmanual&goto :eof)
if not defined netupdt if %_build% geq 20231 dir /b /ad "%mumtarget%\Windows\Servicing\LCU\Package_for_RollupFix*" %_Nul3% && (call :cleanmanual&goto :eof)
set ERRTEMP=0
set netxtr=
if defined netroll set "netxtr=%netroll%"
if defined netlcu set "netxtr=%netxtr% %netlcu%"
if defined netmsu (
if defined netxtr %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNetFx3.log" /Add-Package %netxtr%
call set ERRTEMP=!ERRORLEVEL!
for %%# in (%netmsu%) do %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNetFx3.log" /Add-Package /PackagePath:"!_UUP!\%%#"
call set ERRTEMP=!ERRORLEVEL!
)
if not defined netmsu if defined netlcu (
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNetFx3.log" /Add-Package %netroll% %netlcu%
call set ERRTEMP=!ERRORLEVEL!
)
if not defined netmsu if not defined netlcu (
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNetFx3.log" /Add-Package %netroll% %cumulative%
call set ERRTEMP=!ERRORLEVEL!
)
if !ERRTEMP! neq 0 (
  (echo.&echo Failed reinstalling cumulative update{s})>>"!logerr!"
  )
if defined lcupkg call :ReLCU
call :cleanmanual&goto :eof

:setuphostprep
copy /y ISOFOLDER\sources\setuphost.exe %SystemRoot%\temp\ %_Nul1%
copy /y ISOFOLDER\sources\setupprep.exe %SystemRoot%\temp\ %_Nul1%
set _svr1=0&set _svr2=0&set _svr3=0&set _svr4=0
set "_fvr1=%SystemRoot%\temp\UpdateAgent.dll"
set "_fvr2=%SystemRoot%\temp\setuphost.exe"
set "_fvr3=%SystemRoot%\temp\setupprep.exe"
set "_fvr4=%SystemRoot%\temp\Facilitator.dll"
set "cfvr1=!_fvr1:\=\\!"
set "cfvr2=!_fvr2:\=\\!"
set "cfvr3=!_fvr3:\=\\!"
set "cfvr4=!_fvr4:\=\\!"
if %_cwmi% equ 1 (
if exist "!_fvr1!" for /f "tokens=5 delims==." %%a in ('wmic datafile where "name='!cfvr1!'" get Version /value ^| find "="') do set /a "_svr1=%%a"
if exist "!_fvr2!" for /f "tokens=5 delims==." %%a in ('wmic datafile where "name='!cfvr2!'" get Version /value ^| find "="') do set /a "_svr2=%%a"
if exist "!_fvr3!" for /f "tokens=5 delims==." %%a in ('wmic datafile where "name='!cfvr3!'" get Version /value ^| find "="') do set /a "_svr3=%%a"
if exist "!_fvr4!" for /f "tokens=5 delims==." %%a in ('wmic datafile where "name='!cfvr4!'" get Version /value ^| find "="') do set /a "_svr4=%%a"
)
if %_cwmi% equ 0 (
if exist "!_fvr1!" for /f "tokens=4 delims=." %%a in ('%_psc% "([WMI]'CIM_DataFile.Name=''!cfvr1!''').Version"') do set /a "_svr1=%%a"
if exist "!_fvr2!" for /f "tokens=4 delims=." %%a in ('%_psc% "([WMI]'CIM_DataFile.Name=''!cfvr2!''').Version"') do set /a "_svr2=%%a"
if exist "!_fvr3!" for /f "tokens=4 delims=." %%a in ('%_psc% "([WMI]'CIM_DataFile.Name=''!cfvr3!''').Version"') do set /a "_svr3=%%a"
if exist "!_fvr4!" for /f "tokens=4 delims=." %%a in ('%_psc% "([WMI]'CIM_DataFile.Name=''!cfvr4!''').Version"') do set /a "_svr4=%%a"
)
set "_chk=!_fvr1!"
if %chkmin% equ %_svr1% set "_chk=!_fvr1!"&goto :prephostsetup
if %chkmin% equ %_svr2% set "_chk=!_fvr2!"&goto :prephostsetup
if %chkmin% equ %_svr3% set "_chk=!_fvr3!"&goto :prephostsetup
if %chkmin% equ %_svr4% set "_chk=!_fvr4!"&goto :prephostsetup
if %_svr2% gtr %_svr1% (
if %_svr2% gtr %_svr3% if %_svr2% gtr %_svr4% set "_chk=!_fvr2!"
if %_svr3% gtr %_svr2% if %_svr3% gtr %_svr4% set "_chk=!_fvr3!"
if %_svr4% gtr %_svr2% if %_svr4% gtr %_svr3% set "_chk=!_fvr4!"
)
if %_svr3% gtr %_svr1% (
if %_svr2% gtr %_svr3% if %_svr2% gtr %_svr4% set "_chk=!_fvr2!"
if %_svr3% gtr %_svr2% if %_svr3% gtr %_svr4% set "_chk=!_fvr3!"
if %_svr4% gtr %_svr2% if %_svr4% gtr %_svr3% set "_chk=!_fvr4!"
)
if %_svr4% gtr %_svr1% (
if %_svr2% gtr %_svr3% if %_svr2% gtr %_svr4% set "_chk=!_fvr2!"
if %_svr3% gtr %_svr2% if %_svr3% gtr %_svr4% set "_chk=!_fvr3!"
if %_svr4% gtr %_svr2% if %_svr4% gtr %_svr3% set "_chk=!_fvr4!"
)

:prephostsetup
7z.exe l "%_chk%" >.\bin\version.txt 2>&1
del /f /q "!_fvr1!" "!_fvr2!" "!_fvr3!" "!_fvr4!" %_Nul3%
exit /b

:appx_sort
call :dk_color1 %Blue% "=== Parsing Apps CompDB . . ." 4
if %_pwsh% equ 0 (
echo.
echo Windows PowerShell is not detected, skip operation.
set _IPA=0
goto :eof
)
pushd "!_UUP!"
for /f "delims=" %%# in ('dir /b /a:-d "*.AggregatedMetadata*.cab"') do set "_mdf=%%#"
if exist "_tmpMD\" rmdir /s /q "_tmpMD\" %_Nul3%
mkdir "_tmpMD"
expand.exe -f:*TargetCompDB_* "%_mdf%" _tmpMD %_Null%
expand.exe -r -f:*.xml "_tmpMD\*.cab" _tmpMD %_Null%
if not exist "_tmpMD\*TargetCompDB_App_*.xml" (
echo.
echo CompDB_App.xml file is missing, skip operation.
rmdir /s /q "_tmpMD\" %_Nul3%
popd
set _IPA=0
goto :eof
)
type nul>AppsList.xml
>>AppsList.xml echo ^<Apps^>
>>AppsList.xml echo ^<Client^>
for %%# in (Core,CoreCountrySpecific,CoreSingleLanguage,Professional,ProfessionalEducation,ProfessionalWorkstation,Education,Enterprise,EnterpriseG,EnterpriseS,ServerRdsh,IoTEnterprise,IoTEnterpriseK,IoTEnterpriseS,IoTEnterpriseSK,CloudEdition,CloudEditionL) do if exist _tmpMD\*CompDB_%%#_*.xml (
>>AppsList.xml (find /i "PreinstalledApps" _tmpMD\*CompDB_%%#_*.xml | find /v "-")
)
for /f "delims=" %%# in ('dir /b /a:-d "_tmpMD\*TargetCompDB_App_Moment_*.xml" %_Nul6%') do (
>>AppsList.xml (find /i "PreinstalledApps" _tmpMD\%%# | find /i "Optional")
)
>>AppsList.xml echo ^</Client^>
>>AppsList.xml echo ^<CoreN^>
for %%# in (CoreN,ProfessionalN,ProfessionalEducationN,ProfessionalWorkstationN,EducationN,EnterpriseN,EnterpriseGN,EnterpriseSN,CloudEditionN,CloudEditionLN) do if exist _tmpMD\*CompDB_%%#_*.xml (
>>AppsList.xml (find /i "PreinstalledApps" _tmpMD\*CompDB_%%#_*.xml | find /v "-")
)
for /f "delims=" %%# in ('dir /b /a:-d "_tmpMD\*TargetCompDB_App_Moment_*.xml" %_Nul6%') do (
>>AppsList.xml (find /i "PreinstalledApps" _tmpMD\%%# | find /i "Optional")
)
>>AppsList.xml echo ^</CoreN^>
>>AppsList.xml echo ^<Team^>
for %%# in (PPIPro) do if exist _tmpMD\*CompDB_%%#_*.xml (
>>AppsList.xml (find /i "PreinstalledApps" _tmpMD\*CompDB_%%#_*.xml | find /v "-")
)
>>AppsList.xml echo ^</Team^>
>>AppsList.xml echo ^<ServerAzure^>
for %%# in (AzureStackHCICor) do if exist _tmpMD\*CompDB_Server%%#_*.xml (
>>AppsList.xml (find /i "PreinstalledApps" _tmpMD\*CompDB_Server%%#_*.xml | find /v "-")
)
>>AppsList.xml echo ^</ServerAzure^>
>>AppsList.xml echo ^<ServerCore^>
for %%# in (Standard,Datacenter,Turbine) do if exist _tmpMD\*CompDB_Server%%#Core_*.xml (
>>AppsList.xml (find /i "PreinstalledApps" _tmpMD\*CompDB_Server%%#Core_*.xml | find /v "-")
)
>>AppsList.xml echo ^</ServerCore^>
>>AppsList.xml echo ^<ServerFull^>
for %%# in (Standard,Datacenter,Turbine) do if exist _tmpMD\*CompDB_Server%%#_*.xml (
>>AppsList.xml (find /i "PreinstalledApps" _tmpMD\*CompDB_Server%%#_*.xml | find /v "-")
)
>>AppsList.xml echo ^</ServerFull^>
>>AppsList.xml echo ^</Apps^>
copy /y "!_work!\bin\CompDB_App.txt" . %_Nul3%
type nul>_AppsFilesList.csv
>>_AppsFilesList.csv echo File_Prefix;Target_Path
for /f "delims=" %%# in ('dir /b /a:-d "_tmpMD\*TargetCompDB_App_*.xml" %_Nul6%') do (
copy /y _tmpMD\%%# .\CompDB_App.xml %_Nul1%
%_Nul3% %_psc% "Set-Location -LiteralPath '!_UUP!'; $f=[IO.File]::ReadAllText('.\CompDB_App.txt') -split ':embed\:.*'; iex ($f[1])"
)
type nul>_AppsEditions.txt
%_Nul3% %_psc% "Set-Location -LiteralPath '!_UUP!'; $f=[IO.File]::ReadAllText('.\CompDB_App.txt') -split ':embed\:.*'; iex ($f[2])"
if exist "Apps\*_8wekyb3d8bbwe" move /y _AppsEditions.txt Apps\ %_Nul1%
del /f /q AppsList.xml CompDB_App.* %_Nul3%
rmdir /s /q "_tmpMD\" %_Nul3%
popd
goto :eof

:appx_wim
set mumtarget=%_mount%
set dismtarget=/Image:"%_mount%"
set _edtn=
for /f "tokens=3 delims==:" %%# in ('"offlinereg.exe "%mumtarget%\Windows\System32\config\SOFTWARE" "Microsoft\Windows NT\CurrentVersion" getvalue EditionID" %_Nul6%') do set "_edtn=%%~#"
if not defined _edtn (
reg.exe load HKLM\OFFSOFT "%mumtarget%\Windows\System32\config\SOFTWARE" %_Nul1%
for /f "skip=2 tokens=2*" %%a in ('reg.exe query "HKLM\OFFSOFT\Microsoft\Windows NT\CurrentVersion" /v EditionID') do set "_edtn=%%b"
if /i %xOS%==x86 reg.exe save HKLM\OFFSOFT "%mumtarget%\Windows\System32\Config\SOFTWARE2" %_Nul1%
reg.exe unload HKLM\OFFSOFT %_Nul1%
if /i %xOS%==x86 move /y "%mumtarget%\Windows\System32\Config\SOFTWARE2" "%mumtarget%\Windows\System32\Config\SOFTWARE" %_Nul1%
)
if exist "CustomAppsList2.txt" (set _appsFile=CustomAppsList2.txt) else (set _appsFile=CustomAppsList.txt)
if %_appsCustom% neq 0 for /f "eol=# tokens=*" %%a in ('type %_appsFile%') do set "cal_%%a=1"
set "_appProf=%_appBase%,%_appClnt%,%_appCodec%,%_appMedia%"
set "_appProN=%_appBase%,%_appClnt%"
set "_appTeam=%_appBase%,%_appCodec%,%_appPPIP%"
set "_appSFull=Microsoft.SecHealthUI%pub%,Microsoft.WindowsTerminal%pub%,Microsoft.DesktopAppInstaller%pub%,Microsoft.WindowsFeedbackHub%pub%"
set "_appSCore="
set "_appAzure="
pushd "!_UUP!\Apps"
if exist "_AppsEditions.txt" for /f "tokens=* delims=" %%# in ('type _AppsEditions.txt') do set "%%#"
if %_appsCustom% equ 0 if %AppsLevel% gtr 0 (
set "_appProf=%_appMin1%"
set "_appProN=%_appMin1%"
)
if %_appsCustom% equ 0 if %AppsLevel% gtr 1 (
set "_appProf=%_appProf%,%_appMin2%"
set "_appProN=%_appProN%,%_appMin2%"
)
if %_appsCustom% equ 0 if %AppsLevel% gtr 2 (
set "_appProf=%_appProf%,%_appMin3%"
set "_appProN=%_appProN%,%_appMin3%"
)
if %_appsCustom% equ 0 if %AppsLevel% gtr 3 (
set "_appProf=%_appProf%,%_appMin4%"
)
set "_appList="
for %%# in (Core,CoreCountrySpecific,CoreSingleLanguage,Professional,ProfessionalEducation,ProfessionalWorkstation,Education,Enterprise,EnterpriseG,EnterpriseS,ServerRdsh,IoTEnterprise,IoTEnterpriseK,IoTEnterpriseS,IoTEnterpriseSK,CloudEdition,CloudEditionL) do (
if /i "%_edtn%"=="%%#" set "_appList=%_appProf%"
)
for %%# in (CoreN,ProfessionalN,ProfessionalEducationN,ProfessionalWorkstationN,EducationN,EnterpriseN,EnterpriseGN,EnterpriseSN,CloudEditionN,CloudEditionLN) do (
if /i "%_edtn%"=="%%#" set "_appList=%_appProN%"
)
if /i "%_edtn%"=="PPIPro" set "_appList=%_appTeam%"
for %%# in (AzureStackHCICor) do (
if /i "%_edtn%"=="%%#" set "_appList=%_appAzure%"
)
for %%# in (ServerStandard,ServerDatacenter,ServerTurbine) do (
if /i "%_edtn%"=="%%#" (if exist "%mumtarget%\Windows\Servicing\Packages\Microsoft-Windows-Server*CorEdition~*.mum" (set "_appList=%_appSCore%") else (set "_appList=%_appSFull%"))
)
set _appWay=0
if %winbuild% geq 19040 set _appWay=1
if %_ADK% equ 1 if %apiver% geq 19040 set _appWay=1
if not exist "%SystemRoot%\Microsoft.NET\Framework\v4.0.30319\ngen.exe" set _appWay=0
if %winbuild% LSS 9600 if not exist "%SystemRoot%\servicing\Packages\Microsoft-Windows-PowerShell-WTR-Package~*.mum" set _appWay=0
if not exist "!_work!\bin\APAP.*" set _appWay=0
set _addFrmk=1
if exist "%mumtarget%\Windows\Servicing\Packages\Microsoft-Windows-Server*CorEdition~*.mum" if "%_appList%"=="" set _addFrmk=0
del /f /q AppsToAdd.txt %_Null%
if %_addFrmk% equ 1 if exist "MSIXFramework\*" for /f "tokens=* delims=" %%# in ('dir /b /a:-d "MSIXFramework\*.*x"') do (
  if %_appWay% equ 0 (
  echo %%~n#
  %_Nul1% %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismAppx.log" /Add-ProvisionedAppxPackage /PackagePath:"MSIXFramework\%%#" /SkipLicense
  ) else (
  >>AppsToAdd.txt echo MSIXFramework\%%#
  )
)
if defined _appList for %%# in (%_appList%) do call :appx_add "%%#"
if %_appWay% equ 0 goto :wimappx
if not exist "AppsToAdd.txt" goto :wimappx
copy /y "!_work!\bin\APAP.*" . %_Nul3%
copy /y "!_work!\bin\Microsoft.Dism.dll" . %_Nul3%
:: %_psc% "cd -Lit ($env:__CD__); $f=[IO.File]::ReadAllText('.\APAP.txt') -split ':embed\:.*'; iex ($f[1]); ATA '%_mount%' '%_dLog%\DismAppx.log' '!_cabdir!' %StubAppsFull%"
APAP.exe "%_mount%" "%_dLog%\DismAppx.log" "!_cabdir!" "%StubAppsFull%"
del /f /q AppsToAdd.txt APAP.* Microsoft.Dism.dll %_Nul3%
:wimappx
popd
if %_appsCustom% neq 0 for /f "eol=# tokens=*" %%a in ('type %_appsFile%') do set "cal_%%a="
%_dism1% /Image:"%_mount%" /LogPath:"%_dLog%\DismNUL.log" /Get-Packages %_Null%
goto :eof

:appx_add
set "_pfn=%~1"
if %_appsCustom% neq 0 if not defined cal_%_pfn% goto :eof
if not exist "%_pfn%\License.xml" goto :eof
if not exist "%_pfn%\*.appx*" if not exist "%_pfn%\*.msix*" goto :eof
set "_main="
if not defined _main if exist "%_pfn%\*.msixbundle" for /f "tokens=* delims=" %%# in ('dir /b /a:-d "%_pfn%\*.msixbundle"') do set "_main=%%#"
if not defined _main if exist "%_pfn%\*.appxbundle" for /f "tokens=* delims=" %%# in ('dir /b /a:-d "%_pfn%\*.appxbundle"') do set "_main=%%#"
if not defined _main if exist "%_pfn%\*.appx" for /f "tokens=* delims=" %%# in ('dir /b /a:-d "%_pfn%\*.appx"') do set "_main=%%#"
if not defined _main if exist "%_pfn%\*.msix" for /f "tokens=* delims=" %%# in ('dir /b /a:-d "%_pfn%\*.msix"') do set "_main=%%#"
if not defined _main (
(echo.&echo %_pfn% App main installer is not found)>>"!logerr!"
goto :eof
)
if %_appWay% neq 0 (
>>AppsToAdd.txt echo %_pfn%\%_main%
goto :eof
)
set "_stub="
if exist "%_pfn%\AppxMetadata\Stub\*.*x" (
set "_stub=/StubPackageOption:InstallStub"
if %StubAppsFull% neq 0 set "_stub=/StubPackageOption:InstallFull"
)
echo %_pfn%
%_Nul1% %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismAppx.log" /Add-ProvisionedAppxPackage /PackagePath:"%_pfn%\%_main%" /LicensePath:"%_pfn%\License.xml" /Region:all %_stub%
goto :eof

:V_Ext
set _extVirt=1
call create_virtual_editions.cmd extdism %1
if /i "%_Exit%"=="rem." set _Debug=1
if %_Debug% neq 0 @echo on
for /f "tokens=3 delims=: " %%# in ('wimlib-imagex.exe info "%_www%" ^| findstr /c:"Image Count"') do set _imgi=%%#
goto :eof

:V_Auto
if %wim2esd% equ 0 (
if %wim2swm% equ 0 (set virtag=autowim) else (set virtag=autoswm)
) else (
set virtag=autoesd
)
call create_virtual_editions.cmd %virtag% %_label% %isotime%
if /i "%_Exit%"=="rem." set _Debug=1
if %_Debug% neq 0 @echo on
title UUP -^> ISO %uivr%
goto :QUIT

:V_Manu
if %wim2esd% equ 0 (
if %wim2swm% equ 0 (set virtag=manuwim) else (set virtag=manuswm)
) else (
set virtag=manuesd
)
start /i "" %SysPath%\cmd.exe /c "create_virtual_editions.cmd %virtag% %_label% %isotime%"
if exist temp\ rmdir /s /q temp\
if exist bin\expand.exe if not exist bin\dpx.dll del /f /q bin\expand.exe
popd
call :dk_color2 %Green% "Finished." %_Yellow% " You chose to start create_virtual_editions.cmd independently." 7 8
Press 0 or q to exit.
choice /c 0Q /n
if errorlevel 1 (exit /b) else (rem.)
exit /b

:preVars
set psfnet=0
if exist "%SystemRoot%\Microsoft.NET\Framework\v4.0.30319\ngen.exe" set psfnet=1
if exist "%SystemRoot%\Microsoft.NET\Framework\v2.0.50727\ngen.exe" set psfnet=1
for %%# in (E F G H I J K L M N O P Q R S T U V W X Y Z) do (
set "_adr%%#=%%#"
)
if %_cwmi% equ 1 for /f "tokens=2 delims==:" %%# in ('"wmic path Win32_Volume where (DriveLetter is not NULL) get DriveLetter /value" ^| findstr ^=') do (
if defined _adr%%# set "_adr%%#="
)
if %_cwmi% equ 1 for /f "tokens=2 delims==:" %%# in ('"wmic path Win32_LogicalDisk where (DeviceID is not NULL) get DeviceID /value" ^| findstr ^=') do (
if defined _adr%%# set "_adr%%#="
)
if %_cwmi% equ 0 for /f "tokens=1 delims=:" %%# in ('%_psc% "(([WMISEARCHER]'Select * from Win32_Volume where DriveLetter is not NULL').Get()).DriveLetter; (([WMISEARCHER]'Select * from Win32_LogicalDisk where DeviceID is not NULL').Get()).DeviceID"') do (
if defined _adr%%# set "_adr%%#="
)
for %%# in (E F G H I J K L M N O P Q R S T U V W X Y Z) do (
if not defined _sdr (if defined _adr%%# set "_sdr=%%#:")
)
if not defined _sdr set psfnet=0
set "_Pkt=31bf3856ad364e35"
set "_EsuCmp=microsoft-client-li..pplementalservicing"
set "_EdgCmp=microsoft-windows-e..-firsttimeinstaller"
set "_CedCmp=microsoft-windows-edgechromium"
set "_EsuIdn=Microsoft-Client-Licensing-SupplementalServicing"
set "_EdgIdn=Microsoft-Windows-EdgeChromium-FirstTimeInstaller"
set "_CedIdn=Microsoft-Windows-EdgeChromium"
set "_SxsCfg=Microsoft\Windows\CurrentVersion\SideBySide\Configuration"
goto :eof

:postVars
set "_wsr=Windows Server 2022"
set "pub=_8wekyb3d8bbwe"
set "_appBase=Microsoft.WindowsStore%pub%,Microsoft.StorePurchaseApp%pub%,Microsoft.SecHealthUI%pub%,microsoft.windowscommunicationsapps%pub%,Microsoft.WindowsCalculator%pub%,Microsoft.Windows.Photos%pub%,Microsoft.WindowsMaps%pub%,Microsoft.WindowsCamera%pub%,Microsoft.WindowsFeedbackHub%pub%,Microsoft.Getstarted%pub%,Microsoft.WindowsAlarms%pub%"
set "_appClnt=Microsoft.WindowsNotepad%pub%,Microsoft.WindowsTerminal%pub%,Microsoft.DesktopAppInstaller%pub%,Microsoft.Paint%pub%,MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy,Microsoft.People%pub%,Microsoft.ScreenSketch%pub%,Microsoft.MicrosoftStickyNotes%pub%,Microsoft.XboxIdentityProvider%pub%,Microsoft.XboxSpeechToTextOverlay%pub%,Microsoft.XboxGameOverlay%pub%,OutlookForWindows%pub%,MicrosoftTeams%pub%"
set "_appCodec=Microsoft.WebMediaExtensions%pub%,Microsoft.RawImageExtension%pub%,Microsoft.HEIFImageExtension%pub%,Microsoft.HEVCVideoExtension%pub%,Microsoft.VP9VideoExtensions%pub%,Microsoft.WebpImageExtension%pub%,Microsoft.DolbyAudioExtension%pub%"
set "_appMedia=Microsoft.ZuneMusic%pub%,Microsoft.ZuneVideo%pub%,Microsoft.WindowsSoundRecorder%pub%,Microsoft.GamingApp%pub%,Microsoft.XboxGamingOverlay%pub%,Microsoft.Xbox.TCUI%pub%,Microsoft.YourPhone%pub%,Clipchamp.Clipchamp_yxz26nhyzhsrt,Microsoft.Windows.DevHome%pub%"
set "_appPPIP=Microsoft.MicrosoftPowerBIForWindows%pub%,microsoft.microsoftskydrive%pub%,Microsoft.MicrosoftTeamsforSurfaceHub%pub%,MicrosoftCorporationII.MailforSurfaceHub%pub%,Microsoft.Whiteboard%pub%,Microsoft.SkypeApp_kzf8qxf38zg5c"
set "_appMin1=Microsoft.WindowsStore%pub%,Microsoft.StorePurchaseApp%pub%,Microsoft.SecHealthUI%pub%"
set "_appMin2=Microsoft.Windows.Photos%pub%,Microsoft.WindowsCamera%pub%,Microsoft.WindowsNotepad%pub%,Microsoft.Paint%pub%"
set "_appMin3=Microsoft.WindowsTerminal%pub%,Microsoft.DesktopAppInstaller%pub%,microsoft.windowscommunicationsapps%pub%,MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy"
set "_appMin4=%_appCodec%,Microsoft.ZuneMusic%pub%,Microsoft.ZuneVideo%pub%,Microsoft.YourPhone%pub%"
set ksub=SOFTWIM
set ERRTEMP=
set PREPARED=0
set VOL=0
set EXPRESS=0
set AIO=0
set FixDisplay=0
set uups_esd_num=0
set uwinpe=0
set _count=0
set "_fixEP="
set _actEP=0
set _skpd=0
set _skpp=0
set _eosC=0
set _eosP=0
set _eosT=0
set relite=0
set _SrvESD=0
set _Srvr=0
set _reMSU=0
set _IPA=0
set _runIPA=0
set _appsCustom=0
set _initial=0
set _wimEdge=0
set "_mount=%_drv%\MountUUP"
set "_ntf=NTFS"
if /i not "%_drv%"=="%SystemDrive%" if %_cwmi% equ 1 for /f "tokens=2 delims==" %%# in ('"wmic volume where DriveLetter='%_drv%' get FileSystem /value"') do set "_ntf=%%#"
if /i not "%_drv%"=="%SystemDrive%" if %_cwmi% equ 0 for /f %%# in ('%_psc% "(([WMISEARCHER]'Select * from Win32_Volume where DriveLetter=\"%_drv%\"').Get()).FileSystem"') do set "_ntf=%%#"
if /i not "%_ntf%"=="NTFS" (
set "_mount=%SystemDrive%\MountUUP"
)
set "_ln2=____________________________________________________________"
set "_ln1=________________________________________________"
set _extVirt=0
set _didProf=0
set _didProN=0
set _didHome=0
goto :eof

:checkadk
set _dism1=dism.exe /English
set _dism2=dism.exe /English /ScratchDir
set _ADK=0
set regKeyPathFound=1
set wowRegKeyPathFound=1
reg.exe query "HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 %_Nul3% || set wowRegKeyPathFound=0
reg.exe query "HKLM\Software\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 %_Nul3% || set regKeyPathFound=0
if %wowRegKeyPathFound% equ 0 (
  if %regKeyPathFound% equ 0 (
    goto :eof
  ) else (
    set regKeyPath=HKLM\Software\Microsoft\Windows Kits\Installed Roots
  )
) else (
    set regKeyPath=HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots
)
for /f "skip=2 tokens=2*" %%i in ('reg.exe query "%regKeyPath%" /v KitsRoot10') do set "KitsRoot=%%j"
set "DandIRoot=%KitsRoot%Assessment and Deployment Kit\Deployment Tools"
if exist "%DandIRoot%\%xOS%\DISM\dism.exe" (
set _ADK=1
set "Path=%xDS%;%DandIRoot%\%xOS%\DISM;%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
)
goto :eof

:pr_color
set _NCS=1
if %winbuild% LSS 10586 set _NCS=0
if %winbuild% GEQ 10586 reg.exe query HKCU\Console /v ForceV2 %_Null% | find /i "0x0" %_Null% && (set _NCS=0)

if %_NCS% EQU 1 (
for /F %%a in ('echo prompt $E ^| cmd.exe') do set "_esc=%%a"
set     "Red="41;97m" "pad""
set    "Gray="100;97m" "pad""
set   "Green="42;97m" "pad""
set    "Blue="44;97m" "pad""
set  "_White="40;37m" "pad""
set  "_Green="40;92m" "pad""
set "_Yellow="40;93m" "pad""
) else (
set     "Red="Red" "white""
set    "Gray="DarkGray" "white""
set   "Green="DarkGreen" "white""
set    "Blue="Blue" "white""
set  "_White="Black" "Gray""
set  "_Green="Black" "Green""
set "_Yellow="Black" "Yellow""
)

set "_err=echo: &call :dk_color1 %Red% "==== ERROR ====" &echo:"
exit /b

:dk_color1
if /i "%_Exit%"=="rem." (
echo %~3
exit /b
)
if not "%4"=="" if "%4"=="4" echo:
if %_NCS% EQU 1 (
echo %_esc%[%~1%~3%_esc%[0m
) else if %_pwsh% EQU 1 (
%_psc% write-host -back '%1' -fore '%2' '%3'
) else (
echo %~3
)
if not "%5"=="" echo:
exit /b

:dk_color2
if /i "%_Exit%"=="rem." (
echo %~3 %~6
exit /b
)
if not "%7"=="" if "%7"=="7" echo:
if %_NCS% EQU 1 (
echo %_esc%[%~1%~3%_esc%[%~4%~6%_esc%[0m
) else if %_pwsh% EQU 1 (
%_psc% write-host -back '%1' -fore '%2' '%3' -NoNewline; write-host -back '%4' -fore '%5' '%6'
) else (
echo %~3 %~6
)
if not "%8"=="" echo:
exit /b

:checkQE
if not defined qerel reg.exe query HKCU\Console /v QuickEdit 2>nul | find /i "0x0" >nul || (
call :dk_color1 %Red% "### WARNING ###"
echo.
echo Console "Quick Edit Mode" is active.
echo Do not left-click with the mouse cursor inside the console window,
echo or else the operation execution will hang until a key is pressed.
echo.
)
exit /b

:E_Admin
%_err%
echo This script require administrator privileges.
echo To do so, right click on this script and select 'Run as administrator'
goto :E_Exit

:E_PWS
%_err%
echo Windows PowerShell is not detected or not properly responding.
echo It is required for this script to work.
goto :E_Exit

:E_Exit
if %AutoExit% neq 0 exit /b
if %_Debug% neq 0 exit /b
echo.
echo Press any key to exit.
pause >nul
exit /b

:E_Bin
%_err%
echo Required file %_bin% is missing.
echo.
goto :QUIT

:E_ESD
:: @color 0F
@cls
call :dk_color1 %Red% "No Edition file{s} found in the specified UUP source." 4 5
goto :QUIT

:E_Apply
:: @color 17
call :dk_color1 %Red% "Errors were reported during wim apply." 4 5
(echo.&echo Errors were reported during wim apply.)>>"!logerr!"
goto :QUIT

:E_Export
:: @color 17
call :dk_color1 %Red% "Errors were reported during wim export." 4 5
(echo.&echo Errors were reported during wim export.)>>"!logerr!"
goto :QUIT

:E_ISO
:: @color 17
ren ISOFOLDER %DVDISO%
call :dk_color1 %Red% "Errors were reported during ISO creation." 4 5
(echo.&echo Errors were reported during ISO creation.)>>"!logerr!"
goto :QUIT

:QUIT
if exist ISOFOLDER\ rmdir /s /q ISOFOLDER\
if exist bin\temp\ rmdir /s /q bin\temp\
if exist temp\ rmdir /s /q temp\
if exist bin\expand.exe if not exist bin\dpx.dll del /f /q bin\expand.exe
if exist bin\info*.txt del /f /q bin\info*.txt
popd
if defined tmpcmp (
  for %%# in (%tmpcmp%) do del /f /q "!_UUP!\%%~#" %_Nul3%
  set tmpcmp=
)
if exist "!_cabdir!\" (
rmdir /s /q "!_cabdir!\" %_Nul3%
)
if exist "!_cabdir!\" (
mkdir %_drv%\_del286 %_Null%
robocopy %_drv%\_del286 "!_cabdir!" /MIR /R:1 /W:1 /NFL /NDL /NP /NJH /NJS %_Null%
rmdir /s /q %_drv%\_del286\ %_Null%
rmdir /s /q "!_cabdir!\" %_Nul3%
)
if defined qmsg call :dk_color1 %Green% "%qmsg%" 4
if %AutoExit% neq 0 exit /b
if %_Debug% neq 0 exit /b
call :dk_color1 %_Yellow% "Press 0 or q to exit."
choice /c 0Q /n
if errorlevel 1 (exit /b) else (rem.)

----- Begin wsf script --->
<package>
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
