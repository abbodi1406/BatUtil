<!-- : Begin batch script
@setlocal DisableDelayedExpansion
@set uivr=v65
@echo off
:: Change to 1 to start the process directly, and create ISO with install.wim
:: Change to 2 to start the process directly, and create ISO with install.esd
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

:: Change to 1 for not creating ISO file, result distribution folder will be kept
set SkipISO=0

:: Change to 1 for not adding winre.wim into install.wim/install.esd
set SkipWinRE=0

:: Change to 1 to use dism.exe for creating boot.wim
set ForceDism=0

:: Change to 1 to keep converted Reference ESDs
set RefESD=0

:: change to 1 for not integrating EdgeChromium with Enablement Package or Cumulative Update
:: change to 2 for alternative workaround to avoid EdgeChromium with Cumulative Update only
set SkipEdge=0

:: change to 1 to enable debug mode
set _Debug=0

:: script:	     abbodi1406, @rgadguard
:: wimlib:	     synchronicity
:: PSFExtractor: th1r5bvn23 - www.betaworld.cn
:: SxSExpand:    SuperBubble - Melinda Bellemore
:: offlinereg:   erwan.l
:: Thanks to:    whatever127, Windows_Addict, @Ratiborus58, @NecrosoftCore, @DiamondMonday, @WzorNET

:: ###################################################################

set "FullExit=exit /b"
set "_Null=1>nul 2>nul"

set _UUP=
set _elev=
set "_args="
set "_args=%~1"
if not defined _args goto :NoProgArgs
if "%~1"=="" set "_args="&goto :NoProgArgs
if "%~1"=="-elevated" set _elev=1&set "_args="&goto :NoProgArgs
if "%~2"=="-elevated" set _elev=1

:NoProgArgs
set "SysPath=%SystemRoot%\System32"
if exist "%SystemRoot%\Sysnative\reg.exe" (set "SysPath=%SystemRoot%\Sysnative")
set "_ComSpec=%SystemRoot%\System32\cmd.exe"
set "xOS=%PROCESSOR_ARCHITECTURE%"
if /i %PROCESSOR_ARCHITECTURE%==x86 (if defined PROCESSOR_ARCHITEW6432 (
  set "_ComSpec=%SystemRoot%\Sysnative\cmd.exe"
  set "xOS=%PROCESSOR_ARCHITEW6432%"
  )
)
set "xDS=bin\bin64;bin"
if /i not %xOS%==amd64 set "xDS=bin"
set "Path=%xDS%;%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
set "_err===== ERROR ===="

%_Null% reg.exe query HKU\S-1-5-19 && (
  goto :Passed
  ) || (
  if defined _elev goto :E_Admin
)

set _PSarg="""%~f0""" -elevated
if defined _args set _PSarg="""%~f0""" %_args:"="""% -elevated
set _PSarg=%_PSarg:'=''%

(%_Null% cscript //NoLogo "%~f0?.wsf" //job:ELAV /File:"%~f0" %1 -elevated) && (
  exit /b
  ) || (
  call setlocal EnableDelayedExpansion
  %_Null% powershell -noprofile -c "start cmd.exe -Arg '/c \"!_PSarg!\"' -verb runas" && (
    exit /b
    ) || (
    goto :E_Admin
  )
)

:Passed
set "_log=%~dpn0"
set "_work=%~dp0"
set "_work=%_work:~0,-1%"
set _drv=%~d0
set "_cabdir=%_drv%\W10UIuup"
if "%_work:~0,2%"=="\\" set "_cabdir=%~dp0temp\W10UIuup"
for /f "skip=2 tokens=2*" %%a in ('reg.exe query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop') do call set "_dsk=%%b"
if exist "%PUBLIC%\Desktop\desktop.ini" set "_dsk=%PUBLIC%\Desktop"
setlocal EnableDelayedExpansion
if exist "!_work!\UUPs\*.esd" set "_UUP=!_work!\UUPs"
if defined _args if exist "!_args!\*.esd" set "_UUP=%~1"

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
@call :Begin >"!_log!_tmp.log" 2>&1 &cmd /u /c type "!_log!_tmp.log">"!_log!_Debug.log"&del "!_log!_tmp.log"
@color 07
@title %ComSpec%
@exit /b

:Begin
title UUP -^> ISO %uivr%
:: checkadk
set psfnet=0
if exist "%SystemRoot%\Microsoft.NET\Framework\v4.0.30319\ngen.exe" set psfnet=1
if exist "%SystemRoot%\Microsoft.NET\Framework\v2.0.50727\ngen.exe" set psfnet=1
set /a _cdr=0
for /f "tokens=2 delims==:" %%# in ('"wmic path Win32_Volume where (DriveLetter is not NULL) get DriveLetter /value" ^| findstr ^=') do (
set /a _cdr+=1
set "_udr!_cdr!=%%#"
)
for /L %%j in (1,1,%_cdr%) do for %%# in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
if not defined _sdr (if /i not "!_udr%%j!"=="%%#" set "_sdr=%%#:")
)
if not defined _sdr set psfnet=0
set "_dLog=%SystemRoot%\Logs\DISM"
set _dism1=dism.exe /English
set _dism2=dism.exe /English /ScratchDir
set _ADK=0
set regKeyPathFound=1
set wowRegKeyPathFound=1
reg.exe query "HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 %_Nul3% || set wowRegKeyPathFound=0
reg.exe query "HKLM\Software\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 %_Nul3% || set regKeyPathFound=0
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
set _ADK=1
set "Path=%xDS%;%DandIRoot%\%xOS%\DISM;%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
)

:precheck
for /f "tokens=6 delims=[]. " %%# in ('ver') do set winbuild=%%#
set W10UI=0
if %winbuild% geq 10240 (
set W10UI=1
) else (
if %_ADK% equ 1 set W10UI=1
)
set "_wsr=Windows Server 2022"
set ksub=SOFTWIM
set ERRORTEMP=
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
set _initial=0
set "_mount=%_drv%\MountUUP"
set "_ntf=NTFS"
if /i not "%_drv%"=="%SystemDrive%" for /f "tokens=2 delims==" %%# in ('"wmic volume where DriveLetter='%_drv%' get FileSystem /value"') do set "_ntf=%%#"
if /i not "%_ntf%"=="NTFS" (
set "_mount=%SystemDrive%\MountUUP"
)
set "line============================================================="
if defined _UUP goto :check
if %_Debug% neq 0 goto :check
setlocal DisableDelayedExpansion

:prompt
@cls
set _UUP=
echo %line%
echo Enter / Paste the path to UUP files directory
echo %line%
echo.
set /p _UUP=
if not defined _UUP set _Debug=1&goto :QUIT
set "_UUP=%_UUP:"=%"
if "%_UUP:~-1%"=="\" set "_UUP=%_UUP:~0,-1%"
if not exist "%_UUP%\*.esd" (
echo.
echo %_err%
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
set _file=(7z.dll,7z.exe,bcdedit.exe,bfi.exe,bootmui.txt,bootwim.txt,cdimage.exe,imagex.exe,libwim-15.dll,offlinereg.exe,offreg.dll,wimlib-imagex.exe,PSFExtractor.exe,SxSExpand.exe,cabarc.exe)
for %%# in %_file% do (
if not exist ".\bin\%%#" (set _bin=%%#&goto :E_Bin)
)
if not defined _UUP exit /b
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
wim2esd
ForceDism
RefESD
SkipEdge
) do (
call :ReadINI %%#
)
goto :proceed

:ReadINI
findstr /b /i %1 ConvertConfig.ini %_Nul1% && for /f "tokens=2 delims==" %%# in ('findstr /b /i %1 ConvertConfig.ini') do set "%1=%%#"
goto :eof

:proceed
color 1F
if %_Debug% neq 0 if %AutoStart% equ 0 set AutoStart=2
set _configured=0
if exist bin\temp\ rmdir /s /q bin\temp\
if exist temp\ rmdir /s /q temp\
mkdir bin\temp
mkdir temp
set _updexist=0
if exist "!_UUP!\*Windows10*KB*.cab" set _updexist=1
if exist "!_UUP!\SSU-*-*.cab" set _updexist=1
dir /b /ad "!_UUP!\*Package*" %_Nul3% && set EXPRESS=1
for %%# in (
Core,CoreN,CoreSingleLanguage,CoreCountrySpecific
Professional,ProfessionalN,ProfessionalEducation,ProfessionalEducationN,ProfessionalWorkstation,ProfessionalWorkstationN
Education,EducationN,Enterprise,EnterpriseN,EnterpriseG,EnterpriseGN,EnterpriseS,EnterpriseSN,ServerRdsh
PPIPro,IoTEnterprise,IoTEnterpriseS
Cloud,CloudN,CloudE,CloudEN,CloudEdition,CloudEditionN,CloudEditionL,CloudEditionLN
Starter,StarterN,ProfessionalCountrySpecific,ProfessionalSingleLanguage
ServerStandardCore,ServerStandard,ServerDatacenterCore,ServerDatacenter,ServerAzureStackHCICor,ServerTurbineCor,ServerTurbine,ServerStandardACor,ServerDatacenterACor,ServerStandardWSCor,ServerDatacenterWSCor
) do (
if exist "!_UUP!\%%#_*.esd" dir /b /a:-d "!_UUP!\%%#_*.esd">>temp\uups_esd.txt %_Nul2%
)
for /f "tokens=3 delims=: " %%# in ('find /v /c "" temp\uups_esd.txt %_Nul6%') do set uups_esd_num=%%#
if %uups_esd_num% equ 0 goto :E_ESD
for /L %%# in (1,1,%uups_esd_num%) do call :uups_esd %%#
if defined E_WIMLIB goto :QUIT
if %uups_esd_num% gtr 1 goto :MULTIMENU
set "MetadataESD=!_UUP!\%uups_esd1%"&set "_flg=%edition1%"&set "arch=%arch1%"&set "langid=%langid1%"&set "editionid=%edition1%"&set "_oName=%_oname1%"&set "_Srvr=%_ESDSrv1%"
goto :MAINMENU

:MULTIMENU
if %AutoStart% equ 1 (set AIO=1&set WIMFILE=install.wim&goto :ISO)
if %AutoStart% equ 2 (set AIO=1&set WIMFILE=install.esd&goto :ISO)
@cls
set _index=
echo %line%
echo       UUP directory contains multiple editions files:
echo %line%
for /L %%# in (1,1,%uups_esd_num%) do (
echo %%#. !_name%%#!
)
echo.
echo %line%
echo Enter zero '0' to create AIO
echo Enter individual edition number to create solely
echo Enter multiple editions numbers to create, separated with spaces
echo %line%
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
@cls
set userinp=
echo %line%
echo.       0 - Exit
echo.       1 - Create%_tag% ISO with install.wim
echo.       2 - Create%_tag% install.wim
echo.       3 - UUP Edition info
if %EXPRESS% equ 0 (
echo.       4 - Create%_tag% ISO with install.esd
echo.       5 - Create%_tag% install.esd
)
echo.       6 - Configuration Options
echo.
echo %line%
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
echo %line%
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
if %wim2esd% neq 0 (echo. 5 - WIM2ESD     : Yes) else (echo. 5 - WIM2ESD     : No)
if %SkipISO% neq 0 (echo. 6 - SkipISO     : Yes) else (echo. 6 - SkipISO     : No)
if %SkipWinRE% neq 0 (echo. 7 - SkipWinRE   : Yes) else (echo. 7 - SkipWinRE   : No)
if %W10UI% neq 0 (
if %ForceDism% neq 0 (echo. 8 - ForceDism   : Yes) else (echo. 8 - ForceDism   : No)
)
if %RefESD% neq 0 (echo. 9 - RefESD      : Yes) else (echo. 9 - RefESD      : No)
if %_updexist% equ 1 if %W10UI% neq 0 (
if %AddUpdates% equ 1 (
  if %SkipEdge% neq 0 (echo. E - SkipEdge    : Yes) else (echo. E - SkipEdge    : No)
  )
)
echo.
echo %line%
set /p userinp= ^> Enter your option and press "Enter": 
if not defined userinp goto :MAINMENU
set userinp=%userinp:~0,1%
if %userinp% equ 0 goto :MAINMENU
if /i %userinp%==E if %AddUpdates% equ 1 (if %SkipEdge% equ 0 (set SkipEdge=1) else if %SkipEdge% equ 1 (set SkipEdge=2) else (set SkipEdge=0))&goto :CONFMENU
if %userinp% equ 9 (if %RefESD% equ 0 (set RefESD=1) else (set RefESD=0))&goto :CONFMENU
if %userinp% equ 8 (if %W10UI% neq 0 (if %ForceDism% equ 0 (set ForceDism=1) else (set ForceDism=0)))&goto :CONFMENU
if %userinp% equ 7 (if %SkipWinRE% equ 0 (set SkipWinRE=1) else (set SkipWinRE=0))&goto :CONFMENU
if %userinp% equ 6 (if %SkipISO% equ 0 (set SkipISO=1) else (set SkipISO=0))&goto :CONFMENU
if %userinp% equ 5 (if %wim2esd% equ 0 (set wim2esd=1) else (set wim2esd=0))&goto :CONFMENU
if %userinp% equ 4 (if %StartVirtual% equ 0 (set StartVirtual=1) else (set StartVirtual=0))&goto :CONFMENU
if %userinp% equ 3 if %AddUpdates% neq 0 (if %NetFx3% equ 0 (set NetFx3=1) else (set NetFx3=0))&goto :CONFMENU
if %userinp% equ 2 if %AddUpdates% equ 1 (if %Cleanup% equ 1 (set Cleanup=0) else (set Cleanup=1&if %ResetBase% equ 0 (set ResetBase=1) else (set ResetBase=0)))&goto :CONFMENU
if %userinp% equ 1 (if %AddUpdates% equ 0 (set AddUpdates=1) else if %AddUpdates% equ 1 (set AddUpdates=2) else (set AddUpdates=0))&goto :CONFMENU
goto :CONFMENU

:ISO
@cls
echo.
echo %line%
echo Running UUP -^> ISO %uivr%
echo %line%
echo.
set _initial=1
if %_updexist% equ 0 set AddUpdates=0
if %PREPARED% equ 0 call :PREPARE
if /i %arch%==arm64 if %winbuild% lss 9600 if %AddUpdates% equ 1 (
if %_build% geq 17763 (set AddUpdates=2) else (set AddUpdates=0)
)
if %Cleanup% equ 0 set ResetBase=0
if %_build% lss 17063 (set StartVirtual=0)
if %_build% lss 17763 if %AddUpdates% equ 2 (set AddUpdates=1)
if %_build% lss 17763 if %AddUpdates% equ 1 if %W10UI% equ 0 (set AddUpdates=0)
if %_build% geq 17763 if %AddUpdates% equ 1 if %W10UI% equ 0 (set AddUpdates=2)
if %_build% lss 17763 if %AddUpdates% equ 1 (set Cleanup=1)
if %WIMFILE%==install.wim (
if %AddUpdates% neq 1 if %wim2esd% equ 1 (set WIMFILE=install.esd)
)
if %WIMFILE%==install.esd (
set wim2esd=0
if %AddUpdates% equ 1 (set WIMFILE=install.wim&set wim2esd=1)
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
wim2esd
ForceDism
RefESD
SkipEdge
) do (
if !%%#! neq 0 set _configured=1
)
if %_configured% equ 1 (
echo.
echo %line%
echo Configured Options . . .
echo %line%
echo.
if %AutoStart% neq 0 echo AutoStart %AutoStart%
if %AddUpdates% neq 0 echo AddUpdates %AddUpdates%
if %AddUpdates% equ 1 (
if %Cleanup% neq 0 echo Cleanup
if %Cleanup% neq 0 if %ResetBase% neq 0 echo ResetBase
)
if %AddUpdates% neq 0 if %NetFx3% neq 0 echo NetFx3
if %StartVirtual% neq 0 echo StartVirtual
  for %%# in (
  SkipISO
  SkipWinRE
  wim2esd
  ForceDism
  RefESD
  ) do (
  if !%%#! neq 0 echo %%#
  )
)
if %_build% geq 18362 if %AddUpdates% equ 1 if %SkipEdge% neq 0 echo SkipEdge %SkipEdge%
call :uups_ref
echo.
echo %line%
echo Creating Setup Media Layout . . .
echo %line%
echo.
if exist ISOFOLDER\ rmdir /s /q ISOFOLDER\
mkdir ISOFOLDER
wimlib-imagex.exe apply "!MetadataESD!" 1 ISOFOLDER\ --no-acls --no-attributes %_Null%
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_Apply
if exist ISOFOLDER\MediaMeta.xml del /f /q ISOFOLDER\MediaMeta.xml %_Nul3%
:: rmdir /s /q ISOFOLDER\sources\uup\ %_Nul3%
if %_build% geq 18890 (
wimlib-imagex.exe extract "!MetadataESD!" 3 Windows\Boot\Fonts\* --dest-dir=ISOFOLDER\boot\fonts --no-acls --no-attributes %_Nul3%
xcopy /CRY ISOFOLDER\boot\fonts\* ISOFOLDER\efi\microsoft\boot\fonts\ %_Nul3%
)
if exist ISOFOLDER\sources\ei.cfg (
if %AIO% equ 1 del /f /q ISOFOLDER\sources\ei.cfg %_Nul3%
if %_count% gtr 1 del /f /q ISOFOLDER\sources\ei.cfg %_Nul3%
)
for /f "tokens=5-10 delims=: " %%G in ('wimlib-imagex.exe info "!MetadataESD!" 3 ^| find /i "Last Modification Time"') do (set mmm=%%G&set "isotime=%%H/%%L,%%I:%%J:%%K")
call :setdate %mmm%
set _file=ISOFOLDER\sources\%WIMFILE%
set _rtrn=RetISO
goto :InstallWim
:RetISO
if %_Debug% neq 0 if %WIMFILE%==install.esd set SkipWinRE=1
set _rtrn=BakISO
goto :WinreWim
:BakISO
echo.
echo %line%
echo Creating boot.wim . . .
echo %line%
echo.
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
if %StartVirtual% neq 0 (
  if %RefESD% neq 0 call :uups_backup
  ren ISOFOLDER %DVDISO%
  if %AutoStart% neq 0 (goto :V_Auto) else (goto :V_Manu)
)
if %wim2esd% neq 0 (
echo.
echo %line%
echo Converting install.wim to install.esd . . .
echo %line%
echo.
wimlib-imagex.exe export ISOFOLDER\sources\install.wim all ISOFOLDER\sources\install.esd --compress=LZMS --solid %_Supp%
call set ERRORTEMP=!ERRORLEVEL!
if !ERRORTEMP! neq 0 (echo.&echo Errors were reported during export. Discarding install.esd&del /f /q ISOFOLDER\sources\install.esd %_Nul3%)
if exist ISOFOLDER\sources\install.esd del /f /q ISOFOLDER\sources\install.wim
)
if %SkipISO% neq 0 (
  if %RefESD% neq 0 call :uups_backup
  ren ISOFOLDER %DVDISO%
  echo.
  echo %line%
  echo Done. You chose not to create iso file.
  echo %line%
  echo.
  goto :QUIT
)
echo.
echo %line%
echo Creating ISO . . .
echo %line%
if /i not %arch%==arm64 (
cdimage.exe -bootdata:2#p0,e,b"ISOFOLDER\boot\etfsboot.com"#pEF,e,b"ISOFOLDER\efi\Microsoft\boot\efisys.bin" -o -m -u2 -udfver102 -t%isotime% -l%DVDLABEL% ISOFOLDER %DVDISO%.ISO
) else (
cdimage.exe -bootdata:1#pEF,e,b"ISOFOLDER\efi\Microsoft\boot\efisys.bin" -o -m -u2 -udfver102 -t%isotime% -l%DVDLABEL% ISOFOLDER %DVDISO%.ISO
)
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_ISO
if %RefESD% neq 0 call :uups_backup&echo Finished
echo.
goto :QUIT

:Single
@cls
echo.
echo %line%
echo Running UUP -^> %WIMFILE% %uivr%
echo %line%
echo.
set _initial=1
if %_updexist% equ 0 set AddUpdates=0
if %PREPARED% equ 0 call :PREPARE
if %W10UI% equ 0 (set AddUpdates=0)
if /i %arch%==arm64 if %winbuild% lss 9600 if %AddUpdates% equ 1 (set AddUpdates=0)
if %Cleanup% equ 0 set ResetBase=0
if %_build% lss 17763 if %AddUpdates% equ 1 (set Cleanup=1)
if %WIMFILE%==install.wim (
if %AddUpdates% neq 1 if %wim2esd% equ 1 (set WIMFILE=install.esd)
)
if %WIMFILE%==install.esd (
set wim2esd=0
if %AddUpdates% equ 1 (set WIMFILE=install.wim&set wim2esd=1)
)
if %_Debug% neq 0 set wim2esd=0
if exist "!_work!\%WIMFILE%" (
echo.
echo %line%
echo An %WIMFILE% file is already present in the current folder
echo %line%
echo.
goto :QUIT
)
for %%# in (
AddUpdates
Cleanup
ResetBase
SkipWinRE
wim2esd
RefESD
) do (
if !%%#! neq 0 set _configured=1
)
if %_configured% equ 1 (
echo.
echo %line%
echo Configured Options . . .
echo %line%
echo.
if %AddUpdates% equ 1 (
  echo AddUpdates %AddUpdates%
  if %Cleanup% neq 0 echo Cleanup
  if %Cleanup% neq 0 if %ResetBase% neq 0 echo ResetBase
  )
  for %%# in (
  SkipWinRE
  wim2esd
  RefESD
  ) do (
  if !%%#! neq 0 echo %%#
  )
)
call :uups_ref
if %AIO% equ 1 set "MetadataESD=!_UUP!\%uups_esd1%"&set "_flg=%edition1%"&set "_Srvr=%_ESDSrv1%"
if %_count% gtr 1 set "MetadataESD=!_UUP!\!uups_esd%_index1%!"&set "_flg=!edition%_index1%!"&set "_Srvr=!_ESDSrv%_index1%!"
set _file=%WIMFILE%
set _rtrn=RetWIM
goto :InstallWim
:RetWIM
if %_Debug% neq 0 if %WIMFILE%==install.esd set SkipWinRE=1
set _rtrn=BakWIM
if %SkipWinRE% equ 0 goto :WinreWim
:BakWIM
if %wim2esd% neq 0 (
echo.
echo %line%
echo Converting install.wim to install.esd . . .
echo %line%
echo.
wimlib-imagex.exe export install.wim all install.esd --compress=LZMS --solid %_Supp%
call set ERRORTEMP=!ERRORLEVEL!
if !ERRORTEMP! neq 0 (echo.&echo Errors were reported during export. Discarding install.esd&del /f /q install.esd %_Nul3%)
if exist install.esd del /f /q install.wim
)
if %RefESD% neq 0 call :uups_backup
echo.
echo Done.
echo.
goto :QUIT

:InstallWim
echo.
echo %line%
echo Creating %WIMFILE% . . .
echo %line%
echo.
if exist "temp\*.ESD" (set _rrr=--ref="temp\*.esd") else (set "_rrr=")
if %WIMFILE%==install.wim set _rrr=%_rrr% --compress=LZX
wimlib-imagex.exe export "!MetadataESD!" 3 %_file% --ref="!_UUP!\*.esd" %_rrr% %_Supp%
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_Export
if !_Srvr! equ 1 (
wimlib-imagex.exe info %_file% 1 "%_wsr% %_flg%" "%_wsr% %_flg%" --image-property DISPLAYNAME="!_dName!" --image-property DISPLAYDESCRIPTION="!_dDesc!" --image-property FLAGS=%_flg% %_Nul3%
) else if !FixDisplay! equ 1 (
wimlib-imagex.exe info %_file% 1 "!_os!" "!_os!" --image-property DISPLAYNAME="!_dName!" --image-property DISPLAYDESCRIPTION="!_dDesc!" --image-property FLAGS=%_flg% %_Nul3%
) else (
wimlib-imagex.exe info %_file% 1 --image-property FLAGS=%_flg% %_Nul3%
)
set _img=1
if %_count% gtr 1 for /L %%i in (2,1,%_count%) do (
for /L %%# in (1,1,%uups_esd_num%) do if !_index%%i! equ %%# (
  wimlib-imagex.exe export "!_UUP!\!uups_esd%%#!" 3 %_file% --ref="!_UUP!\*.esd" %_rrr% %_Supp%
  call set ERRORTEMP=!ERRORLEVEL!
  if !ERRORTEMP! neq 0 goto :E_Export
  set /a _img+=1
  if !_ESDSrv%%#! equ 1 (
    wimlib-imagex.exe info %_file% !_img! "%_wsr% !edition%%#!" "%_wsr% !edition%%#!" --image-property DISPLAYNAME="!_dName%%#!" --image-property DISPLAYDESCRIPTION="!_dDesc%%#!" --image-property FLAGS=!edition%%#! %_Nul3%
    ) else if !FixDisplay! equ 1 (
    wimlib-imagex.exe info %_file% !_img! "!_os%%#!" "!_os%%#!" --image-property DISPLAYNAME="!_dName%%#!" --image-property DISPLAYDESCRIPTION="!_dDesc%%#!" --image-property FLAGS=!edition%%#! %_Nul3%
    ) else (
    wimlib-imagex.exe info %_file% !_img! --image-property FLAGS=!edition%%#! %_Nul3%
    )
  )
)
if %AIO% equ 1 for /L %%# in (2,1,%uups_esd_num%) do (
wimlib-imagex.exe export "!_UUP!\!uups_esd%%#!" 3 %_file% --ref="!_UUP!\*.esd" %_rrr% %_Supp%
call set ERRORTEMP=!ERRORLEVEL!
if !ERRORTEMP! neq 0 goto :E_Export
if !_ESDSrv%%#! equ 1 (
  wimlib-imagex.exe info %_file% %%# "%_wsr% !edition%%#!" "%_wsr% !edition%%#!" --image-property DISPLAYNAME="!_dName%%#!" --image-property DISPLAYDESCRIPTION="!_dDesc%%#!" --image-property FLAGS=!edition%%#! %_Nul3%
  ) else if !FixDisplay! equ 1 (
  wimlib-imagex.exe info %_file% %%# "!_os%%#!" "!_os%%#!" --image-property DISPLAYNAME="!_dName%%#!" --image-property DISPLAYDESCRIPTION="!_dDesc%%#!" --image-property FLAGS=!edition%%#! %_Nul3%
  ) else (
  wimlib-imagex.exe info %_file% %%# --image-property FLAGS=!edition%%#! %_Nul3%
  )
)
if %AddUpdates% equ 1 if %_updexist% equ 1 (
if exist "!_cabdir!\" rmdir /s /q "!_cabdir!\"
DEL /F /Q %_dLog%\* %_Nul3%
if not exist "%_dLog%\" mkdir "%_dLog%" %_Nul3%
if %_file%==%WIMFILE% (call :uups_update %WIMFILE%) else (call :uups_update)
)
if %_file%==%WIMFILE% goto :%_rtrn%
if %AddUpdates% equ 2 if %_updexist% equ 1 (
call :uups_external
)
goto :%_rtrn%

:WinreWim
echo.
echo %line%
echo Creating winre.wim . . .
echo %line%
echo.
wimlib-imagex.exe export "!MetadataESD!" 2 temp\winre.wim --compress=LZX --boot %_Supp%
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_Export
if %uwinpe% equ 1 if %AddUpdates% equ 1 if %_updexist% equ 1 (
call :uups_update temp\winre.wim
)
if %relite% neq 0 (
ren temp\winre.wim boot.wim
wimlib-imagex.exe export temp\boot.wim 2 temp\winre.wim --compress=LZX --boot %_Supp%
wimlib-imagex.exe delete temp\boot.wim 2 --soft %_Nul3%
)
if %SkipWinRE% neq 0 goto :%_rtrn%
echo.
echo %line%
echo Adding winre.wim to %WIMFILE% . . .
echo %line%
echo.
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
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 (
%_dism1% /Image:"%_mount%" /Get-Packages %_Null%
%_dism1% /Unmount-Wim /MountDir:"%_mount%" /Discard %_Nul3%
%_dism1% /Cleanup-Wim %_Nul3%
rmdir /s /q "%_mount%\"
goto :BootPE
)
%_dism1% /Quiet /Image:"%_mount%" /Set-TargetPath:X:\$windows.~bt\
%_dism1% /Quiet /Unmount-Wim /MountDir:"%_mount%" /Commit
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
for %%# in (background_cli.bmp, background_svr.bmp) do if exist "ISOFOLDER\sources\%%#" (
>>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\%%#' '^\Windows^\system32^\winre.jpg'
)
wimlib-imagex.exe update ISOFOLDER\sources\boot.wim 1 < bin\boot-wim.txt %_Null%
rmdir /s /q bin\temp\

:BootST
wimlib-imagex.exe extract "!MetadataESD!" 3 Windows\system32\xmllite.dll --dest-dir=ISOFOLDER\sources --no-acls --no-attributes %_Nul3%
type nul>bin\boot-wim.txt
>>bin\boot-wim.txt echo delete '^\Windows^\system32^\winpeshl.ini'
>>bin\boot-wim.txt echo add 'ISOFOLDER^\setup.exe' '^\setup.exe'
>>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\inf^\setup.cfg' '^\sources^\inf^\setup.cfg'
for %%# in (background_cli.bmp, background_svr.bmp) do if exist "ISOFOLDER\sources\%%#" (
>>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\%%#' '^\Windows^\system32^\winre.jpg'
>>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\%%#' '^\sources^\background.bmp'
)
for /f %%# in (bin\bootwim.txt) do if exist "ISOFOLDER\sources\%%#" (
>>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\%%#' '^\sources^\%%#'
)
for /f %%# in (bin\bootmui.txt) do if exist "ISOFOLDER\sources\%langid%\%%#" (
>>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\%langid%^\%%#' '^\sources^\%langid%^\%%#'
)
wimlib-imagex.exe export %_srcwim% 1 ISOFOLDER\sources\boot.wim "Microsoft Windows Setup (%arch%)" "Microsoft Windows Setup (%arch%)" --boot %_Supp%
wimlib-imagex.exe update ISOFOLDER\sources\boot.wim 2 < bin\boot-wim.txt %_Null%
wimlib-imagex.exe info ISOFOLDER\sources\boot.wim 2 --image-property FLAGS=2 %_Nul3%
if %relite% neq 0 wimlib-imagex.exe optimize ISOFOLDER\sources\boot.wim %_Supp%
del /f /q bin\boot-wim.txt %_Nul3%
del /f /q ISOFOLDER\sources\xmllite.dll %_Nul3%
exit /b

:INFO
if %PREPARED% equ 0 call :PREPARE
@cls
echo %line%
echo                     UUP Contents Info
echo %line%
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
echo %line%
echo                     UUP Contents Info
echo %line%
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
echo %line%
echo Checking UUP Info . . .
echo %line%
set PREPARED=1
if %AIO% equ 1 set "MetadataESD=!_UUP!\%uups_esd1%"&set "_flg=%edition1%"&set "arch=%arch1%"&set "langid=%langid1%"&set "_oName=%_oname1%"&set "_Srvr=%_ESDSrv1%"
if %_count% gtr 1 set "MetadataESD=!_UUP!\!uups_esd%_index1%!"&set "_flg=!edition%_index1%!"&set "arch=!arch%_index1%!"&set "langid=!langid%_index1%!"&set "_oName=!_oname%_index1%!"&set "_Srvr=!_ESDSrv%_index1%!"
imagex /info "!MetadataESD!" 3 >bin\info.txt 2>&1
for /f "tokens=3 delims=<>" %%# in ('find /i "<MAJOR>" bin\info.txt') do set ver1=%%#
for /f "tokens=3 delims=<>" %%# in ('find /i "<MINOR>" bin\info.txt') do set ver2=%%#
for /f "tokens=3 delims=<>" %%# in ('find /i "<BUILD>" bin\info.txt') do set _build=%%#
for /f "tokens=3 delims=<>" %%# in ('find /i "<SPBUILD>" bin\info.txt') do set svcbuild=%%#
for /f "tokens=3 delims=<>" %%# in ('imagex /info "!MetadataESD!" 3 ^| find /i "<DISPLAYNAME>" %_Nul6%') do if /i "%%#"=="/DISPLAYNAME" (set FixDisplay=1)
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
wimlib-imagex.exe extract "!MetadataESD!" 1 sources\ei.cfg --dest-dir=.\bin\temp --no-acls --no-attributes %_Nul3%
if exist "bin\temp\ei.cfg" type .\bin\temp\ei.cfg %_Nul2% | find /i "Volume" %_Nul1% && set VOL=1
wimlib-imagex.exe extract "!MetadataESD!" 1 sources\setuphost.exe --dest-dir=.\bin\temp --no-acls --no-attributes %_Nul3%
7z.exe l .\bin\temp\setuphost.exe >.\bin\temp\version.txt 2>&1
for /f "tokens=4-7 delims=.() " %%i in ('"findstr /i /b "FileVersion" .\bin\temp\version.txt" %_Nul6%') do (set version=%%i.%%j&set vermajor=%%i&set verminor=%%j&set branch=%%k&set labeldate=%%l)
set revision=%version%&set revmajor=%vermajor%&set revminor=%verminor%
set "tok=6,7"&set "toe=5,6,7"
if /i %arch%==x86 (set _ss=x86) else if /i %arch%==x64 (set _ss=amd64) else (set _ss=arm64)
wimlib-imagex.exe extract "!MetadataESD!" 3 Windows\WinSxS\Manifests\%_ss%_microsoft-windows-coreos-revision*.manifest --dest-dir=.\bin\temp --no-acls --no-attributes --ref="!_UUP!\*.esd" %_Nul3%
if exist "bin\temp\*_microsoft-windows-coreos-revision*.manifest" for /f "tokens=%tok% delims=_." %%A in ('dir /b /a:-d /od .\bin\temp\*_microsoft-windows-coreos-revision*.manifest') do set revision=%%A.%%B&set revmajor=%%A&set revminor=%%B
if %_build% geq 15063 (
wimlib-imagex.exe extract "!MetadataESD!" 3 Windows\System32\config\SOFTWARE --dest-dir=.\bin\temp --no-acls --no-attributes %_Null%
set "isokey=Microsoft\Windows NT\CurrentVersion\Update\TargetingInfo\Installed"
for /f %%i in ('"offlinereg.exe .\bin\temp\SOFTWARE "!isokey!" enumkeys %_Nul6% ^| findstr /i /r ".*\.OS""') do if not errorlevel 1 (
  for /f "tokens=3 delims==:" %%A in ('"offlinereg.exe .\bin\temp\SOFTWARE "!isokey!\%%i" getvalue Branch %_Nul6%"') do set "isobranch=%%~A"
  for /f "tokens=5,6 delims==:." %%A in ('"offlinereg.exe .\bin\temp\SOFTWARE "!isokey!\%%i" getvalue Version %_Nul6%"') do if %%A gtr !revmajor! (
    set "revision=%%~A.%%B
    set revmajor=%%~A
    set "revminor=%%B
    )
  )
)
if defined isobranch set branch=%isobranch%
if %revmajor%==18363 if /i "%branch:~0,4%"=="19h1" set branch=19h2%branch:~4%
if %revmajor%==19042 if /i "%branch:~0,2%"=="vb" set branch=20h2%branch:~2%
if %revmajor%==19043 if /i "%branch:~0,2%"=="vb" set branch=21h1%branch:~2%
if %revmajor%==19044 if /i "%branch:~0,2%"=="vb" set branch=21h2%branch:~2%
if %verminor% lss %revminor% (
set version=%revision%
set verminor=%revminor%
if not exist "%SystemRoot%\temp\" mkdir "%SystemRoot%\temp" %_Nul3%
wimlib-imagex.exe extract "!MetadataESD!" 3 Windows\Servicing\Packages\Package_for_RollupFix*.mum --dest-dir=%SystemRoot%\temp --no-acls --no-attributes %_Nul3%
for /f %%# in ('dir /b /a:-d /od %SystemRoot%\temp\Package_for_RollupFix*.mum') do set "mumfile=%SystemRoot%\temp\%%#"
for /f "tokens=2 delims==" %%# in ('wmic datafile where "name='!mumfile:\=\\!'" get LastModified /value') do set "mumdate=%%#"
del /f /q %SystemRoot%\temp\*.mum
set "labeldate=!mumdate:~2,2!!mumdate:~4,2!!mumdate:~6,2!-!mumdate:~8,4!"
)
set _label2=
if /i "%branch%"=="WinBuild" (
wimlib-imagex.exe extract "!MetadataESD!" 3 Windows\System32\config\SOFTWARE --dest-dir=.\bin\temp --no-acls --no-attributes %_Null%
for /f "tokens=3 delims==:" %%# in ('"offlinereg.exe .\bin\temp\SOFTWARE "Microsoft\Windows NT\CurrentVersion" getvalue BuildLabEx" %_Nul6%') do if not errorlevel 1 (for /f "tokens=1-5 delims=." %%i in ('echo %%~#') do set _label2=%%i.%%j.%%m.%%l&set branch=%%l)
)
if defined _label2 (set _label=%_label2%) else (set _label=%version%.%labeldate%.%branch%)
rmdir /s /q bin\temp\

:setlabel
if %_SrvESD% equ 1 (set _label=%_label%_SERVER) else (set _label=%_label%_CLIENT)
if /i %arch%==x86 set archl=X86
if /i %arch%==x64 set archl=X64
if /i %arch%==arm64 set archl=A64
for %%# in (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do (
set _label=!_label:%%#=%%#!
set branch=!branch:%%#=%%#!
set langid=!langid:%%#=%%#!
set editionid=!editionid:%%#=%%#!
)

if %_SrvESD% equ 1 (
if %AIO% equ 1 set DVDLABEL=SSS_%archl%FRE_%langid%_DV9&set DVDISO=%_label%_%archl%FRE_%langid%&exit /b
if %_count% gtr 1 set DVDLABEL=SSS_%archl%FRE_%langid%_DV9&set DVDISO=%_label%_%archl%FRE_%langid%&exit /b
)
if %AIO% equ 1 set DVDLABEL=CCSA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%MULTI_%archl%FRE_%langid%&exit /b
if %_count% gtr 1 set DVDLABEL=CCSA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%MULTI_%archl%FRE_%langid%&exit /b

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
if /i %editionid%==ServerAzureStackHCICor set DVDLABEL=SASH_%archl%FRE_%langid%_DV5&set DVDISO=%_label%AZURESTACKHCI_RET_%archl%FRE_%langid%&exit /b
if /i %editionid%==ServerTurbine (if %VOL% equ 1 (set DVDLABEL=SADC_%archl%FREV_%langid%_DV5&set DVDISO=%_label%TURBINE_VOL_%archl%FRE_%langid%) else (set DVDLABEL=SADC_%archl%FRE_%langid%_DV5&set DVDISO=%_label%TURBINE_OEMRET_%archl%FRE_%langid%))&exit /b
if /i %editionid%==ServerTurbineCor (if %VOL% equ 1 (set DVDLABEL=SADC_%archl%FREV_%langid%_DV5&set DVDISO=%_label%TURBINECOR_VOL_%archl%FRE_%langid%) else (set DVDLABEL=SADC_%archl%FRE_%langid%_DV5&set DVDISO=%_label%TURBINECOR_OEMRET_%archl%FRE_%langid%))&exit /b
exit /b

:uups_ref
echo.
echo %line%
echo Preparing Reference ESDs . . .
echo %line%
echo.
if %RefESD% neq 0 (set _level=LZX) else (set _level=XPRESS)
if exist "!_UUP!\*.xml.cab" if exist "!_UUP!\Metadata\*" move /y "!_UUP!\*.xml.cab" "!_UUP!\Metadata\" %_Nul3%
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
if /i "%~1"=="Metadata" exit /b
echo %~1| find /i "RetailDemo" %_Nul1% && exit /b
echo %~1| find /i "Holographic-Desktop-FOD" %_Nul1% && exit /b
echo %~1| find /i "Windows10.0-KB" %_Nul1% && exit /b
echo %~1| find /i "SSU-" %_Nul1% && exit /b
set pack=%~1
if exist "!_work!\temp\%pack%.ESD" exit /b
echo DIR-^>ESD: %pack%
rmdir /s /q "!_UUP!\%~1\$dpx$.tmp\" %_Nul3%
wimlib-imagex.exe capture "!_UUP!\%~1" "temp\%pack%.ESD" --compress=%_level% --check --no-acls --norpfix "Edition Package" "Edition Package" %_Null%
exit /b

:uups_cab
echo %~1| find /i "RetailDemo" %_Nul1% && exit /b
echo %~1| find /i "Holographic-Desktop-FOD" %_Nul1% && exit /b
echo %~1| find /i "Windows10.0-KB" %_Nul1% && exit /b
echo %~1| find /i "SSU-" %_Nul1% && exit /b
set pack=%~n1
if exist "!_work!\temp\%pack%.ESD" exit /b
echo CAB-^>ESD: %pack%
set /a _ref+=1
set /a _rnd=%random%
set _dst=%_drv%\_tmp%_ref%
if exist "%_dst%" (set _dst=%_drv%\_tmp%_rnd%)
mkdir %_dst% %_Nul3%
expand.exe -f:* "!_UUP!\%pack%.cab" %_dst%\ %_Null%
wimlib-imagex.exe capture "%_dst%" "temp\%pack%.ESD" --compress=%_level% --check --no-acls --norpfix "Edition Package" "Edition Package" %_Null%
rmdir /s /q %_dst%\ %_Nul3%
if exist "%_dst%\" (
mkdir %_drv%\_del %_Null%
robocopy %_drv%\_del %_dst% /MIR %_Null%
rmdir /s /q %_drv%\_del\ %_Null%
rmdir /s /q %_dst%\ %_Null%
)
exit /b

:uups_esd
set _ESDSrv%1=0
for /f "tokens=2 delims=]" %%# in ('find /v /n "" temp\uups_esd.txt ^| find "[%1]"') do set uups_esd=%%#
set "uups_esd%1=%uups_esd%"
wimlib-imagex.exe info "!_UUP!\%uups_esd%" 3 %_Nul3%
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% equ 73 (
echo %_err%
echo %uups_esd% file is corrupted
echo.
set E_WIMLIB=1
exit /b
)
if %ERRORTEMP% neq 0 (
echo %_err%
echo Could not parse info from %uups_esd%
echo.
set E_WIMLIB=1
exit /b
)
imagex /info "!_UUP!\%uups_esd%" 3 >bin\info.txt 2>&1
for /f "tokens=3 delims=<>" %%# in ('find /i "<DEFAULT>" bin\info.txt') do set "langid%1=%%#"
for /f "tokens=3 delims=<>" %%# in ('find /i "<EDITIONID>" bin\info.txt') do set "edition%1=%%#"
for /f "tokens=3 delims=<>" %%# in ('find /i "<ARCH>" bin\info.txt') do (if %%# equ 0 (set "arch%1=x86") else if %%# equ 9 (set "arch%1=x64") else (set "arch%1=arm64"))
for /f "tokens=3 delims=<>" %%# in ('find /i "<NAME>" bin\info.txt') do set "_oname%1=%%#"
set "_wtx=Windows 10"
find /i "<NAME>" bin\info.txt %_Nul2% | find /i "Windows 11" %_Nul1% && (set "_wtx=Windows 11")
find /i "<NAME>" bin\info.txt %_Nul2% | find /i "Windows 12" %_Nul1% && (set "_wtx=Windows 12")
echo !edition%1!|findstr /i /b "Server" %_Nul3% && (set _SrvESD=1&set _ESDSrv%1=1)
if !_ESDSrv%1! equ 1 findstr /i /c:"Server Core" bin\info.txt %_Nul3% && (
if /i "!edition%1!"=="ServerStandard" set "edition%1=ServerStandardCore"
if /i "!edition%1!"=="ServerDatacenter" set "edition%1=ServerDatacenterCore"
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
"ServerRdsh:%_wtx% Enterprise multi-session"
"Starter:%_wtx% Starter"
"StarterN:%_wtx% Starter N"
"ServerStandardCore:%_wsr% Standard"
"ServerStandard:%_wsr% Standard (Desktop Experience)"
"ServerDatacenterCore:%_wsr% Datacenter"
"ServerDatacenter:%_wsr% Datacenter (Desktop Experience)"
"ServerAzureStackHCICor:Azure Stack HCI"
"ServerTurbineCor:%_wsr% Datacenter Azure Edition"
"ServerTurbine:%_wsr% Datacenter Azure Edition (Desktop Experience)"
"ServerStandardACor:%_wsr% Standard (SAC)"
"ServerDatacenterACor:%_wsr% Datacenter (SAC)"
"ServerStandardWSCor:%_wsr% Standard (WS)"
"ServerDatacenterWSCor:%_wsr% Datacenter (WS)"
) do for /f "tokens=1,2 delims=:" %%A in ("%%~#") do (
if !edition%1!==%%A set "_oname%1=%%B"
)
set "_name%1=!_oname%1! [!arch%1! / !langid%1!]"
del /f /q bin\info*.txt %_Nul3%
exit /b

:uups_backup
if not exist "!_work!\temp\*.ESD" exit /b
echo.
echo %line%
echo Backing up Reference ESDs . . .
echo %line%
echo.
if %EXPRESS% equ 1 (
mkdir "!_work!\CanonicalUUP" %_Nul3%
move /y "!_work!\temp\*.ESD" "!_work!\CanonicalUUP\" %_Nul3%
for /L %%# in (1,1,%uups_esd_num%) do copy /y "!_UUP!\!uups_esd%%#!" "!_work!\CanonicalUUP\" %_Nul3%
) else (
mkdir "!_UUP!\Original" %_Nul3%
move /y "!_work!\temp\*.ESD" "!_UUP!\" %_Nul3%
for /f %%# in ('dir /b "!_UUP!\*.CAB"') do (echo %%#| find /i "Windows10.0-KB" %_Nul1% || move /y "!_UUP!\%%#" "!_UUP!\Original\")
)
exit /b

:uups_du
set isoupdate=
for /f "tokens=* delims=" %%# in ('dir /b /a:-d "!_UUP!\*Windows10*KB*.cab"') do (
	del /f /q temp\update.mum %_Null%
	expand.exe -f:update.mum "!_UUP!\%%#" .\temp %_Null%
	if not exist "temp\update.mum" set isoupdate=!isoupdate! "%%#"
)
if defined isoupdate (
  echo.
  echo %line%
  echo Adding setup dynamic update^(s^) . . .
  echo %line%
  echo.
  mkdir "%_cabdir%\du" %_Nul3%
  for %%# in (!isoupdate!) do (
  echo %%~#
  expand.exe -r -f:* "!_UUP!\%%~#" "%_cabdir%\du" %_Nul1%
  )
  xcopy /CDRUY "%_cabdir%\du" "ISOFOLDER\sources\" %_Nul3%
  for /f %%# in ('dir /b /ad "%_cabdir%\du\*-*" %_Nul6%') do if exist "ISOFOLDER\sources\%%#\*.mui" copy /y "%_cabdir%\du\%%#\*" "ISOFOLDER\sources\%%#\" %_Nul3%
  if exist "%_cabdir%\du\replacementmanifests\" xcopy /CERY "%_cabdir%\du\replacementmanifests" "ISOFOLDER\sources\replacementmanifests\" %_Nul3%
  rmdir /s /q "%_cabdir%\du\" %_Nul3%
  echo.
)
call :setuphostprep
7z.exe l "ISOFOLDER\sources\%_setup%" >.\bin\version.txt 2>&1
for /f "tokens=4-7 delims=.() " %%i in ('"findstr /i /b "FileVersion" .\bin\version.txt" %_Nul6%') do (set isover=%%i.%%j&set isomajor=%%i&set isominor=%%j&set isobranch=%%k&set isodate=%%l)
del /f /q .\bin\version.txt %_Nul3%
if %vermajor%==18363 (
if /i "%isobranch:~0,4%"=="19h1" set isobranch=19h2%isobranch:~4%
if %isover:~0,5%==18362 set isover=18363%isover:~5%
)
if %vermajor%==19042 (
if /i "%isobranch:~0,2%"=="vb" set isobranch=20h2%isobranch:~2%
if %isover:~0,5%==19041 set isover=19042%isover:~5%
)
if %vermajor%==19043 (
if /i "%isobranch:~0,2%"=="vb" set isobranch=21h1%isobranch:~2%
if %isover:~0,5%==19041 set isover=19043%isover:~5%
)
if %vermajor%==19044 (
if /i "%isobranch:~0,2%"=="vb" set isobranch=21h2%isobranch:~2%
if %isover:~0,5%==19041 set isover=19044%isover:~5%
)
if /i not "%isobranch%"=="WinBuild" (set isolabel=%isover%.%isodate%.%isobranch%)
if not defined isolabel exit /b
if %isominor% neq %verminor% exit /b
set _label=%isolabel%
call :setlabel
exit /b

:uups_external
echo.
echo %line%
echo Adding updates files to ISO distribution . . .
echo %line%
echo.
if exist "!_cabdir!\" rmdir /s /q "!_cabdir!\"
if not exist "!_cabdir!\" mkdir "!_cabdir!"
set "_dest=ISOFOLDER\sources\$OEM$\$1\UUP"
if not exist "!_dest!\" mkdir "!_dest!"
copy /y bin\Updates.bat "!_dest!\" %_Nul3%
if %_build% geq 18362 for /f "tokens=* delims=" %%# in ('dir /b /os "!_UUP!\*Windows10*KB*.cab"') do (
expand.exe -f:microsoft-windows-*enablement-package~*.mum "!_UUP!\%%#" "!_cabdir!" %_Nul3%
if exist "!_cabdir!\microsoft-windows-*enablement-package~*.mum" set _actEP=1
if exist "!_cabdir!\Microsoft-Windows-20H2Enablement-Package~*.mum" set "_fixEP=19042"
if exist "!_cabdir!\Microsoft-Windows-21H1Enablement-Package~*.mum" set "_fixEP=19043"
if exist "!_cabdir!\Microsoft-Windows-21H2Enablement-Package~*.mum" set "_fixEP=19044"
)
set tmpcmp=
if exist "!_UUP!\SSU-*-*.cab" for /f "tokens=* delims=" %%# in ('dir /b /os "!_UUP!\SSU-*-*.cab"') do (set "pack=%%#"&call :external_cab)
for /f "tokens=* delims=" %%# in ('dir /b /os "!_UUP!\*Windows10*KB*.cab"') do (set "pack=%%#"&call :external_cab)
if defined tmpcmp if exist "!_UUP!\Windows10.0-*%arch%_inout.cab" for /f "tokens=* delims=" %%# in ('dir /b /os "!_UUP!\Windows10.0-*%arch%_inout.cab"') do (set "pack=%%#"&call :external_cab)
if not exist "!_dest!\*Windows10*KB*.cab" if not exist "!_dest!\*SSU-*-*.cab" (
rmdir /s /q "ISOFOLDER\sources\$OEM$\"
exit /b
)
if %NetFx3% equ 1 if exist "ISOFOLDER\sources\sxs\*NetFx3*.cab" call :external_netfx
echo.
echo %line%
echo Updating %WIMFILE% registry . . .
echo %line%
echo.
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
if %imgcount% gtr 1 if %WIMFILE%==install.wim wimlib-imagex.exe optimize ISOFOLDER\sources\%WIMFILE% %_Supp%
exit /b

:external_cab
del /f /q "!_cabdir!\*.manifest" %_Nul3%
del /f /q "!_cabdir!\*.mum" %_Nul3%
del /f /q "!_cabdir!\*.xml" %_Nul3%
:: expand.exe -f:update.mum "!_UUP!\%pack%" "!_cabdir!" %_Null%
7z.exe e "!_UUP!\%pack%" -o"!_cabdir!" update.mum %_Null%
if not exist "!_cabdir!\update.mum" exit /b
expand.exe -f:*.psf.cix.xml "!_UUP!\%pack%" "!_cabdir!" %_Null%
if exist "!_cabdir!\*.psf.cix.xml" (
findstr /i /m "PSFXVersion" "!_cabdir!\update.mum" %_Nul3% || exit /b
if not exist "!_UUP!\%pack:~0,-4%.psf" exit /b
if %psfnet% equ 0 exit /b
)
findstr /i /m "Package_for_OasisAsset" "!_cabdir!\update.mum" %_Nul3% && (
wimlib-imagex.exe extract ISOFOLDER\sources\%WIMFILE% 1 Windows\Servicing\Packages\*OasisAssets-Package*.mum --dest-dir="!_cabdir!" --no-acls --no-attributes %_Null%
if not exist "!_cabdir!\*OasisAssets-Package*.mum" exit /b
)
expand.exe -f:toc.xml "!_UUP!\%pack%" "!_cabdir!" %_Null%
if exist "!_cabdir!\toc.xml" (
echo LCU: %pack% [Combined]
mkdir "!_cabdir!\lcu" %_Nul3%
expand.exe -f:* "!_UUP!\%pack%" "!_cabdir!\lcu" %_Null%
if exist "!_cabdir!\lcu\Windows10*KB*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_cabdir!\lcu\Windows10*KB*.cab"') do (set "compkg=%%#"&call :inrenupd)
if exist "!_cabdir!\lcu\*%arch%*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_cabdir!\lcu\SSU-*.cab"') do (set "compkg=%%#"&call :inrenssu)
rmdir /s /q "!_cabdir!\lcu\" %_Nul3%
exit /b
)
if %_build% geq 17763 findstr /i /m "WinPE" "!_cabdir!\update.mum" %_Nul3% && (
%_Nul3% findstr /i /m "Edition\"" "!_cabdir!\update.mum"
if errorlevel 1 exit /b
)
expand.exe -f:*_microsoft-windows-servicingstack_*.manifest "!_UUP!\%pack%" "!_cabdir!" %_Null%
if exist "!_cabdir!\*servicingstack_*.manifest" (
echo SSU: %pack%
copy /y "!_UUP!\%pack%" "!_dest!\1%pack%" %_Nul3%
exit /b
)
set lculabel=1
findstr /i /m "Package_for_RollupFix" "!_cabdir!\update.mum" %_Nul3% && (
echo LCU: %pack%
if exist "!_cabdir!\*.psf.cix.xml" (call :external_psf) else (copy /y "!_UUP!\%pack%" "!_dest!\3%pack%" %_Nul3%)
if !lculabel! equ 1 call :external_label
exit /b
)
echo UPD: %pack%
copy /y "!_UUP!\%pack%" "!_dest!\2%pack%" %_Nul3%
exit /b

:external_netfx
for /f %%# in ('dir /b /os "ISOFOLDER\sources\sxs\*NetFx3*.cab"') do set "pack=%%#"
echo DNF: %pack%
copy /y "ISOFOLDER\sources\sxs\%pack%" "!_dest!\" %_Nul3%
exit /b

:external_label
if not exist "%SystemRoot%\temp\" mkdir "%SystemRoot%\temp" %_Nul3%
copy /y "!_cabdir!\update.mum" %SystemRoot%\temp\ %_Nul1%
set "mumfile=%SystemRoot%\temp\update.mum"
for /f "tokens=2 delims==" %%# in ('wmic datafile where "name='!mumfile:\=\\!'" get LastModified /value') do set "mumdate=%%#"
del /f /q %SystemRoot%\temp\*.mum
set "labeldate=!mumdate:~2,2!!mumdate:~4,2!!mumdate:~6,2!-!mumdate:~8,4!"
set "isotime=!mumdate:~4,2!/!mumdate:~6,2!/!mumdate:~0,4!,!mumdate:~8,2!:!mumdate:~10,2!:!mumdate:~12,2!"

expand.exe -f:*cablist.ini "!_UUP!\%pack%" "!_cabdir!" %_Null%
if exist "!_cabdir!\*cablist.ini" (
expand.exe -f:*.cab "!_UUP!\%pack%" "!_cabdir!" %_Null%
expand.exe -f:%_ss%_microsoft-windows-coreos-revision*.manifest "!_cabdir!\Cab*.cab" "!_cabdir!" %_Null%
) else (
expand.exe -f:%_ss%_microsoft-windows-coreos-revision*.manifest "!_UUP!\%pack%" "!_cabdir!" %_Null%
)
if exist "!_cabdir!\*_microsoft-windows-coreos-revision*.manifest" for /f "tokens=%tok% delims=_." %%A in ('dir /b /a:-d /od "!_cabdir!\*_microsoft-windows-coreos-revision*.manifest"') do set version=%%A.%%B&set vermajor=%%A&set verminor=%%B

expand.exe -f:%_ss%_microsoft-updatetargeting-*os_*.manifest "!_UUP!\%pack%" "!_cabdir!" %_Null%

if exist "!_cabdir!\*_microsoft-updatetargeting-*os_*.manifest" for /f "tokens=8 delims== " %%# in ('findstr /i Branch "!_cabdir!\*_microsoft-updatetargeting-*os_*.manifest"') do if not defined regbranch set regbranch=%%~#
if defined regbranch set branch=%regbranch%
if %_actEP% equ 1 if exist "!_cabdir!\*_microsoft-updatetargeting-*os_*10.%_fixEP%*.manifest" (
for /f "tokens=8 delims== " %%# in ('findstr /i Branch "!_cabdir!\*_microsoft-updatetargeting-*os_*10.%_fixEP%*.manifest"') do set branch=%%~#
for /f "tokens=%toe% delims=_." %%I in ('dir /b /a:-d /on "!_cabdir!\*_microsoft-updatetargeting-*os_*10.%_fixEP%*.manifest"') do if %%I gtr !vermajor! (set version=%%I.%%K&set vermajor=%%I&set verminor=%%K)
)

if %vermajor%==18363 if /i "%branch:~0,4%"=="19h1" set branch=19h2%branch:~4%
if %vermajor%==19042 if /i "%branch:~0,2%"=="vb" set branch=20h2%branch:~2%
if %vermajor%==19043 if /i "%branch:~0,2%"=="vb" set branch=21h1%branch:~2%
if %vermajor%==19044 if /i "%branch:~0,2%"=="vb" set branch=21h2%branch:~2%

set _label=%version%.%labeldate%.%branch%
call :setlabel
exit /b

:external_psf
subst %_sdr% "!_cabdir!"
pushd %_sdr%
copy /y "!_UUP!\%pack:~0,-4%.*" . %_Nul3%
if not exist "PSFExtractor.exe" (
  copy /y "!_work!\bin\PSFExtractor.*" . %_Nul3%
  copy /y "!_work!\bin\SxSExpand.exe" . %_Nul3%
  copy /y "!_work!\bin\cabarc.exe" . %_Nul3%
  )
PSFExtractor.exe %pack% %_Null%
if !errorlevel! neq 0 (
  set lculabel=0
  echo Error: failed to extract PSF update
  rmdir /s /q %pack:~0,-4% %_Nul3%
  popd
  subst %_sdr% /d
  exit /b
  )
cd %pack:~0,-4%
del /f /q *.psf.cix.xml %_Nul3%
..\cabarc.exe -m LZX:21 -r -p N ..\3psf.cab *.* %_Null%
cd..
rmdir /s /q %pack:~0,-4% %_Nul3%
popd
subst %_sdr% /d
move /y "!_cabdir!\3psf.cab" "!_dest!\3%pack%" %_Nul3%
exit /b

:uups_update
if %W10UI% equ 0 exit /b
set directcab=0
set wim=0
set dvd=0
set _tgt=
set _tgt=%1
if defined _tgt (
set wim=1
set _target=%1
) else (
set dvd=1
set _target=ISOFOLDER
)
echo.
echo %line%
if %dvd% equ 1 (
for /f "tokens=3 delims=: " %%# in ('wimlib-imagex.exe info "ISOFOLDER\sources\install.wim" ^| findstr /c:"Image Count"') do set imgcount=%%#
echo Updating install.wim / !imgcount! image^(s^) . . .
)
if %wim% equ 1 (
for /f "tokens=3 delims=: " %%# in ('wimlib-imagex.exe info "%_tgt%" ^| findstr /c:"Image Count"') do set imgcount=%%#
echo Updating %~nx1 / !imgcount! image^(s^) . . .
)
echo %line%
echo.
call :extract
if %wim% equ 1 (
call :mount "%_target%"
)
if %dvd% equ 1 (
call :mount "%_target%\sources\install.wim"
)
if exist "%_mount%\" rmdir /s /q "%_mount%\"
echo.
if %wim% equ 1 (
if /i %_target%==install.wim (if %wim2esd% equ 0 wimlib-imagex.exe optimize "%_target%" %_Supp%) else (if %relite% equ 0 wimlib-imagex.exe optimize "%_target%" %_Supp%)
exit /b
)
if %wim2esd% equ 0 wimlib-imagex.exe optimize "%_target%\sources\install.wim" %_Supp%

for /f "tokens=3 delims=: " %%# in ('wimlib-imagex.exe info "%_target%\sources\install.wim" ^| findstr /c:"Image Count"') do set imgcount=%%#
for /L %%# in (1,1,%imgcount%) do (
  for /f "tokens=3 delims=<>" %%A in ('imagex /info "%_target%\sources\install.wim" %%# ^| find /i "<HIGHPART>"') do call set "HIGHPART=%%A"
  for /f "tokens=3 delims=<>" %%A in ('imagex /info "%_target%\sources\install.wim" %%# ^| find /i "<LOWPART>"') do call set "LOWPART=%%A"
  wimlib-imagex.exe info "%_target%\sources\install.wim" %%# --image-property CREATIONTIME/HIGHPART=!HIGHPART! --image-property CREATIONTIME/LOWPART=!LOWPART! %_Nul1%
)
if defined isoupdate (
  echo.
  echo %line%
  echo Adding setup dynamic update^(s^) . . .
  echo %line%
  echo.
  mkdir "%_cabdir%\du" %_Nul3%
  for %%# in (!isoupdate!) do (
  echo %%~#
  expand.exe -r -f:* "!_UUP!\%%~#" "%_cabdir%\du" %_Nul1%
  )
  xcopy /CDRUY "%_cabdir%\du" "ISOFOLDER\sources\" %_Nul3%
  for /f %%# in ('dir /b /ad "%_cabdir%\du\*-*" %_Nul6%') do if exist "ISOFOLDER\sources\%%#\*.mui" copy /y "%_cabdir%\du\%%#\*" "ISOFOLDER\sources\%%#\" %_Nul3%
  if exist "%_cabdir%\du\replacementmanifests\" xcopy /CERY "%_cabdir%\du\replacementmanifests" "ISOFOLDER\sources\replacementmanifests\" %_Nul3%
  rmdir /s /q "%_cabdir%\du\" %_Nul3%
)
call :setuphostprep
7z.exe l "ISOFOLDER\sources\%_setup%" >.\bin\version.txt 2>&1
for /f "tokens=4-7 delims=.() " %%i in ('"findstr /i /b "FileVersion" .\bin\version.txt" %_Nul6%') do (set version=%%i.%%j&set vermajor=%%i&set verminor=%%j&set branch=%%k&set labeldate=%%l)
del /f /q .\bin\version.txt %_Nul3%
if /i not "%branch%"=="WinBuild" (set _label=%version%.%labeldate%.%branch%)
if not defined isover (call :setlabel&exit /b)
if %isomajor%==18363 (
if /i "%isobranch:~0,4%"=="19h1" set isobranch=19h2%isobranch:~4%
if /i "%branch:~0,4%"=="19h1" set branch=19h2%branch:~4%
if %version:~0,5%==18362 set version=18363%version:~5%
)
if %isomajor%==19042 (
if /i "%isobranch:~0,2%"=="vb" set isobranch=20h2%isobranch:~2%
if /i "%branch:~0,2%"=="vb" set branch=20h2%branch:~2%
if %version:~0,5%==19041 set version=19042%version:~5%
)
if %isomajor%==19043 (
if /i "%isobranch:~0,2%"=="vb" set isobranch=21h1%isobranch:~2%
if /i "%branch:~0,2%"=="vb" set branch=21h1%branch:~2%
if %version:~0,5%==19041 set version=19043%version:~5%
)
if %isomajor%==19044 (
if /i "%isobranch:~0,2%"=="vb" set isobranch=21h2%isobranch:~2%
if /i "%branch:~0,2%"=="vb" set branch=21h2%branch:~2%
if %version:~0,5%==19041 set version=19044%version:~5%
)
set _label=%version%.%labeldate%.%branch%
if %isominor% neq %verminor% (set _label=%isover%.%isodate%.%isobranch%)
call :setlabel
exit /b

:extract
if not exist "!_cabdir!\" mkdir "!_cabdir!"
set _cab=0
if exist "!_UUP!\*defender-dism*%arch%*.cab" for /f "tokens=* delims=" %%# in ('dir /b "!_UUP!\*defender-dism*%arch%*.cab"') do (call set /a _cab+=1)
if exist "!_UUP!\SSU-*-*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\SSU-*-*.cab"') do (call set /a _cab+=1)
for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\*Windows10*KB*.cab"') do (call set /a _cab+=1)
set count=0&set isoupdate=&set tmpcmp=
if exist "!_UUP!\*defender-dism*%arch%*.cab" for /f "tokens=* delims=" %%# in ('dir /b "!_UUP!\*defender-dism*%arch%*.cab"') do (set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :cab2)
if exist "!_UUP!\SSU-*-*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\SSU-*-*.cab"') do (set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :cab2)
for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\*Windows10*KB*.cab"') do (set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :cab2)
if defined tmpcmp if exist "!_UUP!\Windows10.0-*%arch%_inout.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\Windows10.0-*%arch%_inout.cab"') do (set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :cab2)
goto :eof

:cab2
if defined %package% goto :eof
if exist "!dest!\" rmdir /s /q "!dest!\"
mkdir "!dest!"
set /a count+=1
:: expand.exe -f:update.mum "!_UUP!\%package%" "!dest!" %_Null%
7z.exe e "!_UUP!\%package%" -o"!dest!" update.mum %_Null%
if not exist "!dest!\update.mum" (
expand.exe -f:*defender*.xml "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\*defender*.xml" (
  echo %count%/%_cab%: %package%
  expand.exe -f:* "!_UUP!\%package%" "!dest!" %_Null%
) else (
  if not defined %package% echo %count%/%_cab%: %package% [Setup DU]
  set isoupdate=!isoupdate! "%package%"
  set %package%=1
  rmdir /s /q "!dest!\" %_Nul3%
  )
goto :eof
)
expand.exe -f:*.psf.cix.xml "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\*.psf.cix.xml" (
findstr /i /m "PSFXVersion" "!dest!\update.mum" %_Nul3% || goto :eof
if not exist "!_UUP!\%package:~0,-4%.psf" goto :eof
if %psfnet% equ 0 goto :eof
set psf_%package%=1
)
if not defined isodate findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% && (
findstr /i /m /c:"Microsoft-Windows-CoreEdition" "!dest!\update.mum" %_Nul3% || set _eosC=1
findstr /i /m /c:"Microsoft-Windows-ProfessionalEdition" "!dest!\update.mum" %_Nul3% || set _eosP=1
findstr /i /m /c:"Microsoft-Windows-PPIProEdition" "!dest!\update.mum" %_Nul3% || set _eosT=1
if not exist "%SystemRoot%\temp\" mkdir "%SystemRoot%\temp" %_Nul3%
copy /y "!dest!\update.mum" %SystemRoot%\temp\ %_Nul1%
set "mumfile=%SystemRoot%\temp\update.mum"
for /f "tokens=2 delims==" %%# in ('wmic datafile where "name='!mumfile:\=\\!'" get LastModified /value') do set "mumdate=%%#"
del /f /q %SystemRoot%\temp\*.mum
set "isodate=!mumdate:~2,2!!mumdate:~4,2!!mumdate:~6,2!-!mumdate:~8,4!"
set "isotime=!mumdate:~4,2!/!mumdate:~6,2!/!mumdate:~0,4!,!mumdate:~8,2!:!mumdate:~10,2!:!mumdate:~12,2!"
)
expand.exe -f:toc.xml "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\toc.xml" (
echo %count%/%_cab%: %package% [Combined]
mkdir "!_cabdir!\lcu" %_Nul3%
expand.exe -f:* "!_UUP!\%package%" "!_cabdir!\lcu" %_Null%
if exist "!_cabdir!\lcu\Windows10*KB*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_cabdir!\lcu\Windows10*KB*.cab"') do (set "compkg=%%#"&call :inrenupd)
if exist "!_cabdir!\lcu\*%arch%*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_cabdir!\lcu\SSU-*.cab"') do (set "compkg=%%#"&call :inrenssu)
rmdir /s /q "!_cabdir!\lcu\" %_Nul3%
rmdir /s /q "!dest!\" %_Nul3%
goto :eof
)
set "_type="
if %_build% geq 17763 findstr /i /m "WinPE" "!dest!\update.mum" %_Nul3% && (
%_Nul3% findstr /i /m "Edition\"" "!dest!\update.mum"
if errorlevel 1 (set "_type=[WinPE]"&set uwinpe=1)
)
if not defined _type (
expand.exe -f:*_microsoft-windows-sysreset_*.manifest "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\*_microsoft-windows-sysreset_*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (set "_type=[WinPE]"&set uwinpe=1)
)
if not defined _type (
expand.exe -f:*_microsoft-windows-i..dsetup-rejuvenation_*.manifest "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\*_microsoft-windows-i..dsetup-rejuvenation_*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (set "_type=[WinPE]"&set uwinpe=1)
)
if not defined _type (
findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% && (set "_type=[LCU]"&set uwinpe=1)
)
if not defined _type (
findstr /i /m "Package_for_WindowsExperienceFeaturePack" "!dest!\update.mum" %_Nul3% && set "_type=[UX FeaturePack]"
)
if not defined _type (
expand.exe -f:*_microsoft-windows-servicingstack_*.manifest "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\*_microsoft-windows-servicingstack_*.manifest" (set "_type=[SSU]"&set uwinpe=1)
)
if not defined _type (
expand.exe -f:*_netfx4*.manifest "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\*_netfx4*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || set "_type=[NetFx]"
)
if not defined _type (
expand.exe -f:*_microsoft-windows-s..boot-firmwareupdate_*.manifest "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\*_microsoft-windows-s..boot-firmwareupdate_*.manifest" set "_type=[SecureBoot]"
)
if not defined _type if %_build% geq 18362 (
expand.exe -f:microsoft-windows-*enablement-package~*.mum "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\microsoft-windows-*enablement-package~*.mum" set "_type=[Enablement]"
if exist "!dest!\Microsoft-Windows-20H2Enablement-Package~*.mum" set "_fixEP=19042"
if exist "!dest!\Microsoft-Windows-21H1Enablement-Package~*.mum" set "_fixEP=19043"
if exist "!dest!\Microsoft-Windows-21H2Enablement-Package~*.mum" set "_fixEP=19044"
)
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
set %package%=1
:: if %_build% geq 20231 if /i "%_type%"=="[LCU]" goto :eof
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
if defined psf_%package% (
subst %_sdr% "!_cabdir!"
pushd %_sdr%
copy /y "!_UUP!\%package:~0,-4%.*" . %_Nul3%
if not exist "PSFExtractor.exe" (
  copy /y "!_work!\bin\PSFExtractor.*" . %_Nul3%
  copy /y "!_work!\bin\SxSExpand.exe" . %_Nul3%
  )
PSFExtractor.exe %package% %_Null%
if !errorlevel! neq 0 (
  echo Error: failed to extract PSF update
  rmdir /s /q %package:~0,-4% %_Nul3%
  set psf_%package%=
  )
popd
subst %_sdr% /d
)
goto :eof

:inrenupd
for /f "tokens=2 delims=-" %%V in ('echo %compkg%') do set kbupd=%%V
call set /a _cab+=1
set _ufn=Windows10.0-%kbupd%-%arch%_inout.cab
set "tmpcmp=!tmpcmp! %_ufn%"
move /y "!_cabdir!\lcu\%compkg%" "!_UUP!\%_ufn%" %_Nul3%
goto :eof

:inrenssu
set kbupd=
mkdir "checkin"
expand.exe -f:update.mum "!_cabdir!\lcu\%compkg%" "checkin" %_Null%
if not exist "checkin\*.mum" (rmdir /s /q "checkin\"&goto :eof)
for /f "tokens=3 delims== " %%# in ('findstr /i releaseType "checkin\update.mum"') do set kbupd=%%~#
if "%kbupd%"=="" (rmdir /s /q "checkin\"&goto :eof)
rmdir /s /q "checkin\"
call set /a _cab+=1
set _ufn=Windows10.0-%kbupd%-%arch%_inout.cab
set "tmpcmp=!tmpcmp! %_ufn%"
move /y "!_cabdir!\lcu\%compkg%" "!_UUP!\%_ufn%" %_Nul3%
goto :eof

:updatewim
set mumtarget=%_mount%
set dismtarget=/image:"%_mount%"
set SOFTWARE=uiSOFTWARE
set COMPONENTS=uiCOMPONENTS
set "_Wnn=HKLM\%SOFTWARE%\Microsoft\Windows\CurrentVersion\SideBySide\Winners"
set "_Cmp=HKLM\%COMPONENTS%\DerivedData\Components"
set "_Pkt=31bf3856ad364e35"
set "_EsuCmp=microsoft-client-li..pplementalservicing"
set "_EdgCmp=microsoft-windows-e..-firsttimeinstaller"
set "_CedCmp=microsoft-windows-edgechromium"
set "_EsuIdn=Microsoft-Client-Licensing-SupplementalServicing"
set "_EdgIdn=Microsoft-Windows-EdgeChromium-FirstTimeInstaller"
set "_CedIdn=Microsoft-Windows-EdgeChromium"
if exist "%mumtarget%\Windows\Servicing\Packages\*arm64*.mum" (
set "xBT=arm64"
set "_EsuKey=%_Wnn%\arm64_%_EsuCmp%_%_Pkt%_none_0a0357560ca88a4d"
set "_EdgKey=%_Wnn%\arm64_%_EdgCmp%_%_Pkt%_none_1e5e2b2c8adcf701"
set "_CedKey=%_Wnn%\arm64_%_CedCmp%_%_Pkt%_none_df3eefecc502346d"
) else if exist "%mumtarget%\Windows\Servicing\Packages\*amd64*.mum" (
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
set mpamfe=
set servicingstack=
set cumulative=
set netpack=
set netroll=
set netlcu=
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
set LTSC=0
set ldr=
if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
if %_build% neq 14393 if exist "%mumtarget%\Windows\Servicing\Packages\Microsoft-Windows-PPIProEdition~*.mum" set LTSC=1
if exist "%mumtarget%\Windows\Servicing\Packages\Microsoft-Windows-EnterpriseS*Edition~*.mum" set LTSC=1
if exist "%mumtarget%\Windows\Servicing\Packages\Microsoft-Windows-IoTEnterpriseS*Edition~*.mum" set LTSC=1
if exist "%mumtarget%\Windows\Servicing\Packages\Microsoft-Windows-Server*Edition~*.mum" set LTSC=1
if exist "%mumtarget%\Windows\Servicing\Packages\Microsoft-Windows-Server*ACorEdition~*.mum" set LTSC=0
)
if exist "!_UUP!\SSU-*-*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\SSU-*-*.cab"') do (set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :procmum)
for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\*Windows10*KB*.cab"') do (set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :procmum)
if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" if exist "!_UUP!\*defender-dism*%arch%*.cab" (for /f "tokens=* delims=" %%# in ('dir /b "!_UUP!\*defender-dism*%arch%*.cab"') do (set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :procmum))
if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
reg.exe load HKLM\%SOFTWARE% "%mumtarget%\Windows\System32\Config\SOFTWARE" %_Nul1%
if %winbuild% lss 15063 if /i %arch%==arm64 reg.exe add HKLM\%SOFTWARE%\Microsoft\Windows\CurrentVersion\SideBySide /v AllowImproperDeploymentProcessorArchitecture /t REG_DWORD /d 1 /f %_Nul1%
if %winbuild% lss 9600 reg.exe add HKLM\%SOFTWARE%\Microsoft\Windows\CurrentVersion\SideBySide /v AllowImproperDeploymentProcessorArchitecture /t REG_DWORD /d 1 /f %_Nul1%
reg.exe save HKLM\%SOFTWARE% "%mumtarget%\Windows\System32\Config\SOFTWARE2" %_Nul1%
reg.exe unload HKLM\%SOFTWARE% %_Nul1%
move /y "%mumtarget%\Windows\System32\Config\SOFTWARE2" "%mumtarget%\Windows\System32\Config\SOFTWARE" %_Nul1%
)
if defined netpack set "ldr=!netpack! !ldr!"
for %%# in (dupdt,cupdt,supdt,fupdt,safeos,secureboot,edge,ldr,cumulative) do if defined %%# set overall=1
if not defined overall if not defined mpamfe if not defined servicingstack goto :eof
if defined servicingstack (
set callclean=1
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismSSU.log" /Add-Package %servicingstack%
if !errorlevel! neq 0 goto :errmount
if not defined overall call :cleanup
)
if not defined overall if not defined mpamfe goto :eof
if defined safeos (
set callclean=1
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismWinPE.log" /Add-Package %safeos%
cmd /c exit /b !errorlevel!
if /i "!=ExitCode!" neq "00000000" if /i "!=ExitCode!" neq "800f081e" goto :errmount
set relite=1
call :cleanup
if %ResetBase% equ 0 %_dism2%:"!_cabdir!" %dismtarget% /Cleanup-Image /StartComponentCleanup /ResetBase %_Null%
%_dism2%:"!_cabdir!" /Commit-Image /MountDir:"%_mount%" /Append
)
if defined secureboot (
set callclean=1
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismSecureBoot.log" /Add-Package %secureboot%
cmd /c exit /b !errorlevel!
if /i "!=ExitCode!" neq "00000000" if /i "!=ExitCode!" neq "800f081e" goto :errmount
)
if defined ldr (
set callclean=1
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismUpdt.log" /Add-Package %ldr%
cmd /c exit /b !errorlevel!
if /i "!=ExitCode!" neq "00000000" if /i "!=ExitCode!" neq "800f081e" if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" goto :errmount
)
if defined fupdt (
set "_SxsKey=%_EdgKey%"
set "_SxsCmp=%_EdgCmp%"
set "_SxsIdn=%_EdgIdn%"
set "_SxsCF=256"
set "_DsmLog=DismEdge.log"
for %%# in (%fupdt%) do (set "pkgn=%%~n#"&set "dest=!_cabdir!\%%~n#"&call :pXML)
)
if defined supdt (
set "_SxsKey=%_EsuKey%"
set "_SxsCmp=%_EsuCmp%"
set "_SxsIdn=%_EsuIdn%"
set "_SxsCF=64"
set "_DsmLog=DismLCUs.log"
for %%# in (%supdt%) do (set "pkgn=%%~n#"&set "dest=!_cabdir!\%%~n#"&call :pXML)
)
if defined cupdt (
set "_SxsKey=%_CedKey%"
set "_SxsCmp=%_CedCmp%"
set "_SxsIdn=%_CedIdn%"
set "_SxsCF=256"
set "_DsmLog=DismLCUs.log"
for %%# in (%cupdt%) do (set "pkgn=%%~n#"&set "dest=!_cabdir!\%%~n#"&call :pXML)
)
set _dualSxS=
if defined dupdt (
set _dualSxS=1
set "_SxsKey=%_EsuKey%"
set "_SxsCmp=%_EsuCmp%"
set "_SxsIdn=%_EsuIdn%"
set "_SxsCF=64"
set "_DsmLog=DismLCUs.log"
for %%# in (%dupdt%) do (set "pkgn=%%~n#"&set "dest=!_cabdir!\%%~n#"&call :pXML)
)
set "_DsmLog=DismLCU.log"
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" set "_DsmLog=DismLCU_winpe.log"
if defined cumulative (
set callclean=1
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\%_DsmLog%" /Add-Package %cumulative%
cmd /c exit /b !errorlevel!
if /i "!=ExitCode!" neq "00000000" if /i "!=ExitCode!" neq "800f081e" if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" goto :errmount
)
if defined lcupkg call :ReLCU
if defined callclean call :cleanup
if defined mpamfe (
echo.
echo Adding Defender update...
call :defender_update
)
if not defined edge goto :eof
if defined edge (
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismEdge.log" /Add-Package %edge%
cmd /c exit /b !errorlevel!
if /i "!=ExitCode!" neq "00000000" if /i "!=ExitCode!" neq "800f081e" goto :errmount
)
goto :eof

:errmount
%_dism1% %dismtarget% /Get-Packages %_Null%
%_dism1% /Unmount-Wim /MountDir:"%_mount%" /Discard
%_dism1% /Cleanup-Wim %_Nul3%
rmdir /s /q "%_mount%\" %_Nul3%
set AddUpdates=0
set FullExit=exit
goto :%_rtrn%

:ReLCU
if exist "!lcudir!\update.mum" if exist "!lcudir!\*.manifest" goto :eof
rem echo.
rem echo 1/1: %lcupkg% [LCU]
if not exist "!lcudir!\" mkdir "!lcudir!"
expand.exe -f:*.psf.cix.xml "!_UUP!\%lcupkg%" "!lcudir!" %_Null%
if exist "!lcudir!\*.psf.cix.xml" (
subst %_sdr% "!_cabdir!"
pushd %_sdr%
if not exist "%lcupkg%" (
  copy /y "!_UUP!\%lcupkg:~0,-4%.*" . %_Nul3%
  )
if not exist "PSFExtractor.exe" (
  copy /y "!_work!\bin\PSFExtractor.*" . %_Nul3%
  copy /y "!_work!\bin\SxSExpand.exe" . %_Nul3%
  )
PSFExtractor.exe %lcupkg% %_Null%
popd
subst %_sdr% /d
goto :eof
)
expand.exe -f:* "!_UUP!\%lcupkg%" "!lcudir!" %_Null%
7z.exe e "!_UUP!\%lcupkg%" -o"!lcudir!" update.mum -aoa %_Null%
if exist "!lcudir!\*cablist.ini" (
  expand.exe -f:* "!lcudir!\*.cab" "!lcudir!" %_Null%
  del /f /q "!lcudir!\*cablist.ini" %_Nul3%
  del /f /q "!lcudir!\*.cab" %_Nul3%
)
goto :eof

:procmum
if exist "!dest!\*.psf.cix.xml" if not defined psf_%package% goto :eof
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
if %_build% geq 17763 if exist "!dest!\update.mum" if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (findstr /i /m "Microsoft-Windows-NetFx" "!dest!\*.mum" %_Nul3% && (if exist "!dest!\*_*10.0.*.manifest" if not exist "!dest!\*_netfx4clientcorecomp.resources*.manifest" (set "netroll=!netroll! /packagepath:!dest!\update.mum")))
findstr /i /m "Package_for_OasisAsset" "!dest!\update.mum" %_Nul3% && (if not exist "%mumtarget%\Windows\Servicing\packages\*OasisAssets-Package*.mum" goto :eof)
findstr /i /m "WinPE" "!dest!\update.mum" %_Nul3% && (
  %_Nul3% findstr /i /m "Edition\"" "!dest!\update.mum"
  if errorlevel 1 goto :eof
  )
)
if %_build% geq 19041 if exist "!dest!\update.mum" if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
findstr /i /m "Package_for_WindowsExperienceFeaturePack" "!dest!\update.mum" %_Nul3% && (if not exist "%mumtarget%\Windows\Servicing\packages\Microsoft-Windows-UserExperience-Desktop*.mum" goto :eof)
)
if exist "!dest!\*_microsoft-windows-servicingstack_*.manifest" (
set "servicingstack=!servicingstack! /packagepath:!dest!\update.mum"
goto :eof
)
if exist "!dest!\*_netfx4-netfx_detectionkeys_extended*.manifest" if exist "!dest!\*_netfx4clientcorecomp.resources*_en-us_*.manifest" (
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" goto :eof
set "netpack=!netpack! /packagepath:!dest!\update.mum"
goto :eof
)
if exist "!dest!\*_%_EdgCmp%_*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" goto :eof
if exist "!dest!\*enablement-package*.mum" if %SkipEdge% neq 1 (
  for /f %%# in ('dir /b /a:-d "!dest!\*enablement-package~*.mum"') do set "ldr=!ldr! /packagepath:!dest!\%%#"
  set "edge=!edge! /packagepath:!dest!\update.mum"
  )
if exist "!dest!\*enablement-package*.mum" if %SkipEdge% equ 1 (set "fupdt=!fupdt! %package%")
if not exist "!dest!\*enablement-package*.mum" set "edge=!edge! /packagepath:!dest!\update.mum"
goto :eof
)
if exist "!dest!\*_microsoft-windows-sysreset_*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (
if not exist "%mumtarget%\Windows\Servicing\Packages\WinPE-SRT-Package~*.mum" goto :eof
set "safeos=!safeos! /packagepath:!dest!\update.mum"
goto :eof
)
if exist "!dest!\*_microsoft-windows-i..dsetup-rejuvenation_*.manifest" if not exist "!dest!\*_microsoft-windows-sysreset_*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (
if not exist "%mumtarget%\Windows\Servicing\Packages\WinPE-Rejuv-Package~*.mum" goto :eof
set "safeos=!safeos! /packagepath:!dest!\update.mum"
goto :eof
)
if exist "!dest!\*_microsoft-windows-s..boot-firmwareupdate_*.manifest" (
if %winbuild% lss 9600 goto :eof
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" goto :eof
set secureboot=!secureboot! /packagepath:"!_UUP!\%package%"
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
for %%# in (%directcab%) do (
if /i "%package%"=="%%~#" (
  set "cumulative=!cumulative! /packagepath:"!_UUP!\%package%""
  goto :eof
  )
)
if exist "!dest!\update.mum" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% && (
rem if %_build% geq 20231 (set "cumulative=!cumulative! /packagepath:"!_UUP!\%package%""&goto :eof)
if %_build% geq 20231 (
  set "lcudir=!dest!"
  set "lcupkg=%package%"
  )
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (set "cumulative=!cumulative! /packagepath:!dest!\update.mum"&goto :eof)
set "netlcu=!netlcu! /packagepath:!dest!\update.mum"
if exist "!dest!\*_%_EsuCmp%_*.manifest" if not exist "!dest!\*_%_CedCmp%_*.manifest" if %LTSC% equ 0 (set "supdt=!supdt! %package%"&goto :eof)
if exist "!dest!\*_%_CedCmp%_*.manifest" if not exist "!dest!\*_%_EsuCmp%_*.manifest" if %SkipEdge% equ 1 (set "cupdt=!cupdt! %package%"&goto :eof)
if exist "!dest!\*_%_CedCmp%_*.manifest" if %SkipEdge% equ 2 call :deEdge
if exist "!dest!\*_%_EsuCmp%_*.manifest" if exist "!dest!\*_%_CedCmp%_*.manifest" (
  if %SkipEdge% neq 1 if %LTSC% equ 0 (set "supdt=!supdt! %package%"&goto :eof)
  if %SkipEdge% equ 1 if %LTSC% equ 0 (set "dupdt=!dupdt! %package%"&goto :eof)
  if %SkipEdge% equ 1 if %LTSC% equ 1 (set "cupdt=!cupdt! %package%"&goto :eof)
  )
set "cumulative=!cumulative! /packagepath:!dest!\update.mum"
goto :eof
)
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (set "ldr=!ldr! /packagepath:!dest!\update.mum"&goto :eof)
if exist "!dest!\*_%_EsuCmp%_*.manifest" if %LTSC% equ 0 (set "supdt=!supdt! %package%"&goto :eof)
if exist "!dest!\*_%_CedCmp%_*.manifest" if %SkipEdge% equ 1 (set "cupdt=!cupdt! %package%"&goto :eof)
if exist "!dest!\*_%_CedCmp%_*.manifest" if %SkipEdge% equ 2 call :deEdge
set "ldr=!ldr! /packagepath:!dest!\update.mum"
goto :eof

:deEdge
  mkdir "%mumtarget%\Program Files\Microsoft\Edge\Application" %_Nul3%
  mkdir "%mumtarget%\Program Files\Microsoft\EdgeUpdate" %_Nul3%
  type nul>"%mumtarget%\Program Files\Microsoft\Edge\Edge.dat" 2>&1
  type nul>"%mumtarget%\Program Files\Microsoft\Edge\Edge.LCU.dat" 2>&1
  type nul>"%mumtarget%\Program Files\Microsoft\EdgeUpdate\EdgeUpdate.dat" 2>&1
  if exist "%mumtarget%\Windows\SysWOW64\cmd.exe" (
    mkdir "%mumtarget%\Program Files (x86)\Microsoft\Edge\Application" %_Nul3%
    mkdir "%mumtarget%\Program Files (x86)\Microsoft\EdgeUpdate" %_Nul3%
    type nul>"%mumtarget%\Program Files (x86)\Microsoft\Edge\Edge.dat" 2>&1
    type nul>"%mumtarget%\Program Files (x86)\Microsoft\Edge\Edge.LCU.dat" 2>&1
    type nul>"%mumtarget%\Program Files (x86)\Microsoft\EdgeUpdate\EdgeUpdate.dat" 2>&1
    )
goto :eof

:defender_check
if %_skpp% equ 1 if %_skpd% equ 1 goto :eof
set "_WDP=ProgramData\Microsoft\Windows Defender"
if not exist "%mumtarget%\%_WDP%\Definition Updates\Updates\*.vdm" (set "mpamfe=!dest!"&goto :eof)
if %_skpp% equ 0 dir /b /ad "%mumtarget%\%_WDP%\Platform\*.*.*.*" %_Nul3% && (
if not exist "!_cabdir!\*defender*.xml" expand.exe -f:*defender*.xml "!_UUP!\%package%" "!_cabdir!" %_Null%
for /f %%i in ('dir /b /a:-d "!_cabdir!\*defender*.xml"') do for /f "tokens=3 delims=<> " %%# in ('type "!_cabdir!\%%i" ^| find /i "platform"') do (
  dir /b /ad "%mumtarget%\%_WDP%\Platform\%%#*" %_Nul3% && set _skpp=1
  )
)
set "_ver1j="&set "_ver1n="
set "_ver2j="&set "_ver2n="
if %_skpd% equ 0 if exist "%mumtarget%\%_WDP%\Definition Updates\Updates\mpavdlta.vdm" (
set "_fil1=%mumtarget%\%_WDP%\Definition Updates\Updates\mpavdlta.vdm"
for /f "tokens=3,4 delims==." %%a in ('wmic datafile where "name='!_fil1:\=\\!'" get Version /value ^| find "="') do set "_ver1j=%%a"&set "_ver1n=%%b"
expand.exe -i -f:mpavdlta.vdm "!_UUP!\%package%" "!_cabdir!" %_Null%
)
if exist "!_cabdir!\mpavdlta.vdm" (
set "_fil2=!_cabdir!\mpavdlta.vdm"
for /f "tokens=3,4 delims==." %%a in ('wmic datafile where "name='!_fil2:\=\\!'" get Version /value ^| find "="') do set "_ver2j=%%a"&set "_ver2n=%%b"
)
if defined _ver1j if defined _ver2j (
if %_ver1j% gtr %_ver2j% set _skpd=1
if %_ver1j% equ %_ver2j% if %_ver1n% geq %_ver2n% set _skpd=1
)
if %_skpp% equ 1 if %_skpd% equ 1 goto :eof
set "mpamfe=!dest!"
goto :eof

:defender_update
xcopy /CIRY "!mpamfe!\Definition Updates\Updates" "%mumtarget%\%_WDP%\Definition Updates\Updates\" %_Nul3%
xcopy /ECIRY "!mpamfe!\Platform" "%mumtarget%\%_WDP%\Platform\" %_Nul3%
for /f %%# in ('dir /b /ad "!mpamfe!\Platform\*.*.*.*"') do set "_wdplat=%%#"
copy /y "%mumtarget%\Program Files\Windows Defender\ConfigSecurityPolicy.exe" "%mumtarget%\%_WDP%\Platform\%_wdplat%\" %_Nul3%
copy /y "%mumtarget%\Program Files\Windows Defender\MpAsDesc.dll" "%mumtarget%\%_WDP%\Platform\%_wdplat%\" %_Nul3%
for /f %%# in ('dir /b /ad "%mumtarget%\Program Files\Windows Defender\*-*"') do (
mkdir "%mumtarget%\%_WDP%\Platform\%_wdplat%\%%#" %_Nul3%
copy /y "%mumtarget%\Program Files\Windows Defender\%%#\MpAsDesc.dll.mui" "%mumtarget%\%_WDP%\Platform\%_wdplat%\%%#\" %_Nul3%
)
if /i not %arch%==x64 goto :eof
copy /y "%mumtarget%\Program Files (x86)\Windows Defender\MpAsDesc.dll" "%mumtarget%\%_WDP%\Platform\%_wdplat%\x86\" %_Nul3%
for /f %%# in ('dir /b /ad "%mumtarget%\Program Files (x86)\Windows Defender\*-*"') do (
mkdir "%mumtarget%\%_WDP%\Platform\%_wdplat%\x86\%%#" %_Nul3%
copy /y "%mumtarget%\Program Files (x86)\Windows Defender\%%#\MpAsDesc.dll.mui" "%mumtarget%\%_WDP%\Platform\%_wdplat%\x86\%%#\" %_Nul3%
)
goto :eof

:pXML
if %_build% neq 18362 (
call :cXML stage
echo.
echo Processing 1 of 1 - Staging %pkgn%
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\%_DsmLog%" /Apply-Unattend:"!_cabdir!\stage.xml"
if !errorlevel! neq 0 if !errorlevel! neq 3010 goto :eof
)
if %_build% neq 18362 (call :Winner) else (call :Suppress)
if defined _dualSxS (
set "_SxsKey=%_CedKey%"
set "_SxsCmp=%_CedCmp%"
set "_SxsIdn=%_CedIdn%"
set "_SxsCF=256"
if %_build% neq 18362 (call :Winner) else (call :Suppress)
)
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\%_DsmLog%" /Add-Package /packagepath:"!dest!\update.mum"
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
%_Nul3% icacls "%mumtarget%\Windows\WinSxS\Manifests" /setowner "NT SERVICE\TrustedInstaller"
%_Nul3% icacls "%mumtarget%\Windows\WinSxS" /restore "!_cabdir!\acl.txt"
%_Nul3% del /f /q "!_cabdir!\acl.txt"
)
reg.exe query HKLM\%COMPONENTS% %_Nul3% || reg.exe load HKLM\%COMPONENTS% "%mumtarget%\Windows\System32\Config\COMPONENTS" %_Nul3%
reg.exe query "%_Cmp%\%_SxsCom%" %_Nul3% && goto :Winner
for /f "skip=1 tokens=* delims=" %%# in ('certutil -hashfile "!dest!\%_SxsCom%.manifest" SHA256^|findstr /i /v CertUtil') do set "_SxsSha=%%#"
set "_SxsSha=%_SxsSha: =%"
set "_psin=%_SxsIdn%, Culture=neutral, Version=%_SxsVer%, PublicKeyToken=%_Pkt%, ProcessorArchitecture=%xBT%, versionScope=NonSxS"
for /f "tokens=* delims=" %%# in ('powershell -nop -c "$str = '%_psin%'; $bytes = [System.Text.Encoding]::ASCII.GetBytes($str); $hex = New-Object -TypeName System.Text.StringBuilder -ArgumentList ($bytes.Length * 2); foreach ($byte in $bytes) {$hex.AppendFormat('{0:x2}', $byte) > $null}; $hex.ToString()" %_Nul6%') do set "_SxsHsh=%%#"
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

:mount
if exist "%_mount%\" rmdir /s /q "%_mount%\"
if not exist "%_mount%\" mkdir "%_mount%"
set _wim=%~1
set handle1=0
set handle2=0
set eHome=0
set eHomN=0
set eProf=0
set eProN=0
set uProf=0
set uProN=0
set eSSC=0
set eSSD=0
set eSDC=0
set eSDD=0
set uSDC=0
set uSDD=0
set _upgr=0
if /i not %~nx1==winre.wim (
if %_build% geq 17063 if %imgcount% gtr 1 set _upgr=1
for /L %%# in (1,1,%imgcount%) do imagex /info "%_wim%" %%# >bin\info%%#.txt 2>&1
)
if %_upgr% equ 1 for /L %%# in (1,1,%imgcount%) do (
if %_eosC% equ 0 if not defined iHome (find /i "Core</EDITIONID>" bin\info%%#.txt %_Nul3% && (set eHome=1&set iHome=%%#))
if %_eosC% equ 0 if not defined iHomN (find /i "CoreN</EDITIONID>" bin\info%%#.txt %_Nul3% && (set eHomN=1&set iHomN=%%#))
if %_eosP% equ 0 if not defined iProf (find /i "Professional</EDITIONID>" bin\info%%#.txt %_Nul3% && (set eProf=1&set iProf=%%#))
if %_eosP% equ 0 if not defined iProN (find /i "ProfessionalN</EDITIONID>" bin\info%%#.txt %_Nul3% && (set eProN=1&set iProN=%%#))
if not defined iSSC (find /i "ServerStandard</EDITIONID>" bin\info%%#.txt %_Nul3% && (findstr /i /c:"Server Core" bin\info%%#.txt %_Nul3% && (set eSSC=1&set iSSC=%%#)))
if not defined iSSD (find /i "ServerStandard</EDITIONID>" bin\info%%#.txt %_Nul3% && (findstr /i /c:"Server Core" bin\info%%#.txt %_Nul3% || (set eSSD=1&set iSSD=%%#)))
if not defined iSDC (find /i "ServerDatacenter</EDITIONID>" bin\info%%#.txt %_Nul3% && (findstr /i /c:"Server Core" bin\info%%#.txt %_Nul3% && (set eSDC=1&set iSDC=%%#)))
if not defined iSDD (find /i "ServerDatacenter</EDITIONID>" bin\info%%#.txt %_Nul3% && (findstr /i /c:"Server Core" bin\info%%#.txt %_Nul3% || (set eSDD=1&set iSDD=%%#)))
)
if %eProf% equ 1 if %eHome% equ 1 set uProf=1
if %eProN% equ 1 if %eHomN% equ 1 set uProN=1
if %eSDD% equ 1 if %eSSD% equ 1 set uSDD=1
if %eSDC% equ 1 if %eSSC% equ 1 set uSDC=1
rem editions deleted in reverse order
if %uSDD% equ 1 (
set /a imgcount-=1
%_dism1% /Delete-Image /ImageFile:"%_wim%" /Index:%iSDD% %_Nul3%
)
if %uSDC% equ 1 (
set /a imgcount-=1
%_dism1% /Delete-Image /ImageFile:"%_wim%" /Index:%iSDC% %_Nul3%
)
if %uProN% equ 1 (
set /a imgcount-=1
%_dism1% /Delete-Image /ImageFile:"%_wim%" /Index:%iProN% %_Nul3%
)
if %uProf% equ 1 (
set /a imgcount-=1
%_dism1% /Delete-Image /ImageFile:"%_wim%" /Index:%iProf% %_Nul3%
)
set /a _imgi=%imgcount%
set iCore=0
set iCorN=0
set iCorS=0
set iCorC=0
set iEntr=0
set iEntN=0
set iTeam=0
if /i not %~nx1==winre.wim for /L %%# in (1,1,%imgcount%) do (
if !iCore! equ 0 (find /i "Core</EDITIONID>" bin\info%%#.txt %_Nul3% && set iCore=%%#)
if !iCorN! equ 0 (find /i "CoreN</EDITIONID>" bin\info%%#.txt %_Nul3% && set iCorN=%%#)
if !iCorS! equ 0 (find /i "CoreSingleLanguage</EDITIONID>" bin\info%%#.txt %_Nul3% && set iCorS=%%#)
if !iCorC! equ 0 (find /i "CoreCountrySpecific</EDITIONID>" bin\info%%#.txt %_Nul3% && set iCorC=%%#)
if !iEntr! equ 0 (find /i "Professional</EDITIONID>" bin\info%%#.txt %_Nul3% && set iEntr=%%#)
if !iEntN! equ 0 (find /i "ProfessionalN</EDITIONID>" bin\info%%#.txt %_Nul3% && set iEntN=%%#)
if !iTeam! equ 0 (find /i "PPIPro</EDITIONID>" bin\info%%#.txt %_Nul3% && set iTeam=%%#)
)
del /f /q bin\info*.txt %_Nul3%
if /i %~nx1==winre.wim set "indices=1"
if /i not %~nx1==winre.wim for /L %%# in (1,1,%imgcount%) do (
if %_eosT% equ 0 if %_eosP% equ 0 if %_eosC% equ 0 (if defined indices (set "indices=!indices!,%%#") else (set "indices=%%#"))
if %_eosT% equ 0 if %_eosP% equ 0 if %_eosC% equ 1 if %%# neq %iCore% if %%# neq %iCorN% if %%# neq %iCorS% if %%# neq %iCorC% (if defined indices (set "indices=!indices!,%%#") else (set "indices=%%#"))
if %_eosT% equ 0 if %_eosP% equ 1 if %_eosC% equ 1 if %%# neq %iEntr% if %%# neq %iEntN% if %%# neq %iCore% if %%# neq %iCorN% if %%# neq %iCorS% if %%# neq %iCorC% (if defined indices (set "indices=!indices!,%%#") else (set "indices=%%#"))
if %_eosT% equ 0 if %_eosP% equ 1 if %_eosC% equ 0 if %%# neq %iEntr% if %%# neq %iEntN% (if defined indices (set "indices=!indices!,%%#") else (set "indices=%%#"))
if %_eosT% equ 1 if %_eosP% equ 0 if %_eosC% equ 0 if %%# neq %iTeam% (if defined indices (set "indices=!indices!,%%#") else (set "indices=%%#"))
if %_eosT% equ 1 if %_eosP% equ 0 if %_eosC% equ 1 if %%# neq %iTeam% if %%# neq %iCore% if %%# neq %iCorN% if %%# neq %iCorS% if %%# neq %iCorC% (if defined indices (set "indices=!indices!,%%#") else (set "indices=%%#"))
if %_eosT% equ 1 if %_eosP% equ 1 if %_eosC% equ 0 if %%# neq %iTeam% if %%# neq %iEntr% if %%# neq %iEntN% (if defined indices (set "indices=!indices!,%%#") else (set "indices=%%#"))
if %_eosT% equ 1 if %_eosP% equ 1 if %_eosC% equ 1 if %%# neq %iTeam% if %%# neq %iEntr% if %%# neq %iEntN% if %%# neq %iCore% if %%# neq %iCorN% if %%# neq %iCorS% if %%# neq %iCorC% (if defined indices (set "indices=!indices!,%%#") else (set "indices=%%#"))
)
if not defined indices goto :eof
for %%# in (%indices%) do (
%_dism2%:"!_cabdir!" /Mount-Wim /Wimfile:"%_wim%" /Index:%%# /MountDir:"%_mount%"
if !errorlevel! neq 0 (
%_dism1% /Image:"%_mount%" /Get-Packages %_Null%
%_dism1% /Unmount-Wim /MountDir:"%_mount%" /Discard
%_dism1% /Cleanup-Wim %_Nul3%
goto :eof
)
call :updatewim
if %NetFx3% equ 1 if %dvd% equ 1 call :enablenet35
if !handle1! equ 0 if %dvd% equ 1 (
set handle1=1
if /i %arch%==x86 (set efifile=bootia32.efi) else if /i %arch%==x64 (set efifile=bootx64.efi) else (set efifile=bootaa64.efi)
for %%i in (efisys.bin,efisys_noprompt.bin) do if exist "%_mount%\Windows\Boot\DVD\EFI\en-US\%%i" (xcopy /CIDRY "%_mount%\Windows\Boot\DVD\EFI\en-US\%%i" "%_target%\efi\microsoft\boot\" %_Nul3%)
if /i not %arch%==arm64 (
xcopy /CIDRY "%_mount%\Windows\Boot\PCAT\bootmgr" "%_target%\" %_Nul3%
xcopy /CIDRY "%_mount%\Windows\Boot\PCAT\memtest.exe" "%_target%\boot\" %_Nul3%
xcopy /CIDRY "%_mount%\Windows\Boot\EFI\memtest.efi" "%_target%\efi\microsoft\boot\" %_Nul3%
)
xcopy /CIDRY "%_mount%\Windows\Boot\EFI\bootmgfw.efi" "%_target%\efi\boot\!efifile!" %_Nul3%
xcopy /CIDRY "%_mount%\Windows\Boot\EFI\bootmgr.efi" "%_target%\" %_Nul3%
)
if !handle2! equ 0 if %dvd% equ 1 if not exist "%_mount%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" if exist "%_mount%\Windows\Servicing\Packages\Package_for_RollupFix*.mum" (
set handle2=1
for /f "tokens=%tok% delims=_." %%A in ('dir /b /a:-d /od "%_mount%\Windows\WinSxS\Manifests\%_ss%_microsoft-windows-coreos-revision*.manifest"') do set isover=%%A.%%B&set isomajor=%%A&set isominor=%%B
set "isokey=Microsoft\Windows NT\CurrentVersion\Update\TargetingInfo\Installed"
for /f %%i in ('"offlinereg.exe "%_mount%\Windows\system32\config\SOFTWARE" "!isokey!" enumkeys %_Nul6% ^| findstr /i /r ".*\.OS""') do if not errorlevel 1 (
  for /f "tokens=3 delims==:" %%A in ('"offlinereg.exe "%_mount%\Windows\system32\config\SOFTWARE" "!isokey!\%%i" getvalue Branch %_Nul6%"') do set "isobranch=%%~A"
  for /f "tokens=5,6 delims==:." %%A in ('"offlinereg.exe "%_mount%\Windows\system32\config\SOFTWARE" "!isokey!\%%i" getvalue Version %_Nul6%"') do if %%A gtr !isomajor! (
    set "isover=%%~A.%%B
    set isomajor=%%~A
    set "isominor=%%B
    )
  )
)
%_dism2%:"!_cabdir!" /Unmount-Wim /MountDir:"%_mount%" /Commit
if !errorlevel! neq 0 (
%_dism1% /Cleanup-Wim %_Nul3%
%_dism1% /Image:"%_mount%" /Get-Packages %_Null%
%_dism1% /Unmount-Wim /MountDir:"%_mount%" /Discard
%_dism1% /Cleanup-Wim %_Nul3%
goto :eof
)
)
if /i %~nx1==winre.wim goto :eof
if %uProf% equ 1 (
%_dism2%:"!_cabdir!" /Mount-Wim /Wimfile:"%_wim%" /Index:%iHome% /MountDir:"%_mount%" %_Supp%
%_dism2%:"!_cabdir!" /Image:"%_mount%" /LogPath:"%_dLog%\DismCore2Pro.log" /Set-Edition:Professional /Channel:Retail
%_dism2%:"!_cabdir!" /Unmount-Image /MountDir:"%_mount%" /Commit /Append
call set /a _imgi+=1
call set ddesc="%_wtx% Pro"
wimlib-imagex.exe info "%_wim%" !_imgi! !ddesc! !ddesc! --image-property DISPLAYNAME=!ddesc! --image-property DISPLAYDESCRIPTION=!ddesc! --image-property FLAGS=Professional %_Nul3%
)
if %uProN% equ 1 (
%_dism2%:"!_cabdir!" /Mount-Wim /Wimfile:"%_wim%" /Index:%iHomN% /MountDir:"%_mount%" %_Supp%
%_dism2%:"!_cabdir!" /Image:"%_mount%" /LogPath:"%_dLog%\DismCoreN2ProN.log" /Set-Edition:ProfessionalN /Channel:Retail
%_dism2%:"!_cabdir!" /Unmount-Image /MountDir:"%_mount%" /Commit /Append 
call set /a _imgi+=1
call set ddesc="%_wtx% Pro N"
wimlib-imagex.exe info "%_wim%" !_imgi! !ddesc! !ddesc! --image-property DISPLAYNAME=!ddesc! --image-property DISPLAYDESCRIPTION=!ddesc! --image-property FLAGS=ProfessionalN %_Nul3%
)
if %uSDC% equ 1 (
%_dism2%:"!_cabdir!" /Mount-Wim /Wimfile:"%_wim%" /Index:%iSSC% /MountDir:"%_mount%" %_Supp%
%_dism2%:"!_cabdir!" /Image:"%_mount%" /LogPath:"%_dLog%\DismSrvSc2SrvDc.log" /Set-Edition:ServerDatacenterCor /Channel:Retail
%_dism2%:"!_cabdir!" /Unmount-Image /MountDir:"%_mount%" /Commit /Append 
call set /a _imgi+=1
call set cname="%_wsr% ServerDatacenterCore"
call set dname="%_wsr% Datacenter"
call set ddesc="(Recommended) This option omits most of the Windows graphical environment. Manage with a command prompt and PowerShell, or remotely with Windows Admin Center or other tools."
wimlib-imagex.exe info "%_wim%" !_imgi! !cname! !cname! --image-property DISPLAYNAME=!dname! --image-property DISPLAYDESCRIPTION=!ddesc! --image-property FLAGS=ServerDatacenterCore %_Nul3%
)
if %uSDD% equ 1 (
%_dism2%:"!_cabdir!" /Mount-Wim /Wimfile:"%_wim%" /Index:%iSSD% /MountDir:"%_mount%" %_Supp%
%_dism2%:"!_cabdir!" /Image:"%_mount%" /LogPath:"%_dLog%\DismSrvS2SrvD.log" /Set-Edition:ServerDatacenter /Channel:Retail
%_dism2%:"!_cabdir!" /Unmount-Image /MountDir:"%_mount%" /Commit /Append
call set /a _imgi+=1
call set cname="%_wsr% ServerDatacenter"
call set dname="%_wsr% Datacenter (Desktop Experience)"
call set ddesc="This option installs the full Windows graphical environment, consuming extra drive space. It can be useful if you want to use the Windows desktop or have an app that requires it."
wimlib-imagex.exe info "%_wim%" !_imgi! !cname! !cname! --image-property DISPLAYNAME=!dname! --image-property DISPLAYDESCRIPTION=!ddesc! --image-property FLAGS=ServerDatacenter %_Nul3%
)
goto :eof

:cleanup
set savc=0&set savr=1
if %_build% geq 18362 (set savc=3&set savr=3)
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
if /i not %arch%==arm64 (
reg.exe load HKLM\%ksub% "%mumtarget%\Windows\System32\Config\SOFTWARE" %_Nul1%
reg.exe add HKLM\%ksub%\Microsoft\Windows\CurrentVersion\SideBySide\Configuration /v SupersededActions /t REG_DWORD /d %savr% /f %_Nul1%
reg.exe add HKLM\%ksub%\Microsoft\Windows\CurrentVersion\SideBySide\Configuration /v DisableComponentBackups /t REG_DWORD /d 1 /f %_Nul1%
reg.exe unload HKLM\%ksub% %_Nul1%
)
%_dism2%:"!_cabdir!" %dismtarget% /Cleanup-Image /StartComponentCleanup
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
reg.exe add HKLM\%ksub%\Microsoft\Windows\CurrentVersion\SideBySide\Configuration /v DisableResetbase /t REG_DWORD /d 0 /f %_Nul1%
reg.exe add HKLM\%ksub%\Microsoft\Windows\CurrentVersion\SideBySide\Configuration /v SupersededActions /t REG_DWORD /d %savr% /f %_Nul1%
) else (
reg.exe add HKLM\%ksub%\Microsoft\Windows\CurrentVersion\SideBySide\Configuration /v DisableResetbase /t REG_DWORD /d 1 /f %_Nul1%
reg.exe add HKLM\%ksub%\Microsoft\Windows\CurrentVersion\SideBySide\Configuration /v SupersededActions /t REG_DWORD /d %savc% /f %_Nul1%
)
if /i %xOS%==x86 if /i not %arch%==x86 reg.exe save HKLM\%ksub% "%mumtarget%\Windows\System32\Config\SOFTWARE2" %_Nul1%
reg.exe unload HKLM\%ksub% %_Nul1%
if /i %xOS%==x86 if /i not %arch%==x86 move /y "%mumtarget%\Windows\System32\Config\SOFTWARE2" "%mumtarget%\Windows\System32\Config\SOFTWARE" %_Nul1%
) else (
%_Nul3% offlinereg.exe "%mumtarget%\Windows\System32\Config\SOFTWARE" Microsoft\Windows\CurrentVersion\SideBySide\Configuration setvalue SupersededActions 3 4
if exist "%mumtarget%\Windows\System32\Config\SOFTWARE.new" del /f /q "%mumtarget%\Windows\System32\Config\SOFTWARE"&ren "%mumtarget%\Windows\System32\Config\SOFTWARE.new" SOFTWARE
)
%_dism2%:"!_cabdir!" %dismtarget% /Cleanup-Image /StartComponentCleanup
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
if not defined netroll if not defined netlcu if not defined cumulative (call :cleanmanual&goto :eof)
if %_build% geq 20231 dir /b /ad "%mumtarget%\Windows\Servicing\LCU\Package_for_RollupFix*" %_Nul3% && (call :cleanmanual&goto :eof)
if defined netlcu (
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNetFx3.log" /Add-Package %netroll% %netlcu%
) else (
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNetFx3.log" /Add-Package %netroll% %cumulative%
)
if defined lcupkg call :ReLCU
call :cleanmanual&goto :eof

:setdate
if /i %1==Jan set "isotime=01/%isotime%"
if /i %1==Feb set "isotime=02/%isotime%"
if /i %1==Mar set "isotime=03/%isotime%"
if /i %1==Apr set "isotime=04/%isotime%"
if /i %1==May set "isotime=05/%isotime%"
if /i %1==Jun set "isotime=06/%isotime%"
if /i %1==Jul set "isotime=07/%isotime%"
if /i %1==Aug set "isotime=08/%isotime%"
if /i %1==Sep set "isotime=09/%isotime%"
if /i %1==Oct set "isotime=10/%isotime%"
if /i %1==Nov set "isotime=11/%isotime%"
if /i %1==Dec set "isotime=12/%isotime%"
exit /b

:setuphostprep
set _setup=setuphost.exe
set "_WSH=SOFTWARE\Microsoft\Windows Script Host\Settings"
reg.exe query "HKCU\%_WSH%" /v Enabled %_Nul2% | find /i "0x0" %_Nul1% && (set _vbscu=1&reg.exe delete "HKCU\%_WSH%" /v Enabled /f %_Nul3%)
reg.exe query "HKLM\%_WSH%" /v Enabled %_Nul2% | find /i "0x0" %_Nul1% && (set _vbslm=1&reg.exe delete "HKLM\%_WSH%" /v Enabled /f %_Nul3%)
 echo>bin\filever.vbs Set objFSO = CreateObject^("Scripting.FileSystemObject"^)
echo>>bin\filever.vbs Wscript.Echo objFSO.GetFileVersion^(WScript.arguments^(0^)^)
for /f "tokens=4 delims=." %%i in ('cscript //nologo bin\filever.vbs ISOFOLDER\sources\setuphost.exe') do (
for /f "tokens=4 delims=." %%a in ('cscript //nologo bin\filever.vbs ISOFOLDER\sources\setupprep.exe') do (
  if %%a gtr %%i set _setup=setupprep.exe
  )
)
del /f /q .\bin\filever.vbs %_Nul3%
if defined _vbscu reg.exe add "HKCU\%_WSH%" /v Enabled /t REG_DWORD /d 0 /f %_Nul3%
if defined _vbslm reg.exe add "HKLM\%_WSH%" /v Enabled /t REG_DWORD /d 0 /f %_Nul3%
exit /b

:V_Auto
if %wim2esd% equ 0 (call create_virtual_editions.cmd autowim %_label% %isotime%) else (call create_virtual_editions.cmd autoesd %_label% %isotime%)
if /i "%_Exit%"=="rem." set _Debug=1
if %_Debug% neq 0 @echo on
title UUP -^> ISO %uivr%
echo.
goto :QUIT

:V_Manu
if %wim2esd% equ 0 (start /i "" !_ComSpec! /c "create_virtual_editions.cmd manuwim %_label% %isotime%") else (start /i "" !_ComSpec! /c "create_virtual_editions.cmd manuesd %_label% %isotime%")
if exist temp\ rmdir /s /q temp\
popd
echo.
echo %line%
echo Done. You chose to start create_virtual_editions.cmd directly.
echo %line%
echo.
%_Exit%&%_Pause%
exit /b

:E_Admin
echo %_err%
echo This script require administrator privileges.
echo To do so, right click on this script and select 'Run as administrator'
echo.
%_Exit%&%_Pause%
exit /b

:E_ESD
@cls
echo %_err%
echo UUP Edition file is not found in specified directory
echo.
goto :QUIT

:E_Bin
echo %_err%
echo Required file %_bin% is missing.
echo.
goto :QUIT

:E_Apply
echo.&echo Errors were reported during apply.&echo.&goto :QUIT

:E_Export
echo.&echo Errors were reported during export.&echo.&goto :QUIT

:E_ISO
if %RefESD% neq 0 call :uups_backup
ren ISOFOLDER %DVDISO%
echo.&echo Errors were reported during ISO creation.&echo.&goto :QUIT

:QUIT
if exist ISOFOLDER\ rmdir /s /q ISOFOLDER\
if exist bin\temp\ rmdir /s /q bin\temp\
if exist temp\ rmdir /s /q temp\
popd
if defined tmpcmp (
  for %%# in (%tmpcmp%) do del /f /q "!_UUP!\%%~#" %_Nul3%
  set tmpcmp=
)
if exist "!_cabdir!\" (
if %AddUpdates% equ 1 (
echo.
echo %line%
echo Removing temporary files . . .
echo %line%
echo.
)
rmdir /s /q "!_cabdir!\" %_Nul3%
)
if exist "!_cabdir!\" (
mkdir %_drv%\_del286 %_Null%
robocopy %_drv%\_del286 "!_cabdir!" /MIR %_Null%
rmdir /s /q %_drv%\_del286\ %_Null%
rmdir /s /q "!_cabdir!\" %_Nul3%
)
if %_Debug% neq 0 (%FullExit%) else (echo Press 0 to exit.)
choice /c 0 /n
if errorlevel 1 (%FullExit%) else (rem.)

----- Begin wsf script --->
<package>
   <job id="ELAV">
       <script language="VBScript">
           Set strArg=WScript.Arguments.Named
           If Not strArg.Exists("File") Then
               Wscript.Echo "Switch /File:<File> is missing."
               WScript.Quit 1
           End If
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
