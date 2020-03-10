<!-- : Begin batch script
@setlocal DisableDelayedExpansion
@set uivr=v44
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

:: Change to 1 for not adding winre.wim to install.wim/install.esd
set SkipWinRE=0

:: Change to 1 to use dism.exe for creating boot.wim
set ForceDism=0

:: Change to 1 to keep converted Reference ESDs
set RefESD=0

:: change to 1 to enable debug mode
set _Debug=0

:: script:	   abbodi1406, @rgadguard
:: wimlib:	   synchronicity
:: offlinereg: erwan.l
:: Thanks to:  whatever127, Windows_Addict, @Ratiborus58, @NecrosoftCore, @DiamondMonday, @WzorNET

:: ###################################################################

set "FullExit=exit /b"
set "_Const=1>nul 2>nul"

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
set "xOS=amd64"
set "xDS=bin\bin64;bin"
set "_ComSpec=%SystemRoot%\System32\cmd.exe"
if /i %PROCESSOR_ARCHITECTURE%==x86 (if defined PROCESSOR_ARCHITEW6432 (
  set "_ComSpec=%SystemRoot%\Sysnative\cmd.exe"
  ) else (
  set "xOS=x86"
  set "xDS=bin"
  )
)
set "Path=%xDS%;%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
set "_err===== ERROR ===="

%_Const% reg query HKU\S-1-5-19 && (
  goto :Passed
  ) || (
  if defined _elev goto :E_Admin
)

set _PSarg="""%~f0""" -elevated
if defined _args set _PSarg="""%~f0""" %_args:"="""% -elevated
set _PSarg=%_PSarg:'=''%

(%_Const% cscript //NoLogo "%~f0?.wsf" //job:ELAV /File:"%~f0" %1 -elevated) && (
  exit /b
  ) || (
  call setlocal EnableDelayedExpansion
  %_Const% powershell -noprofile -exec bypass -c "start cmd.exe -Arg '/c \"!_PSarg!\"' -verb runas" && (
    exit /b
    ) || (
    goto :E_Admin
  )
)

:Passed
set "_log=%~dpn0"
set "_work=%~dp0"
set "_work=%_work:~0,-1%"
set "_cabdir=%~d0\W10UItemp"
if "%_work:~0,2%"=="\\" set "_cabdir=%~dp0temp\W10UItemp"
for /f "skip=2 tokens=2*" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop') do call set "_dsk=%%b"
if exist "%SystemDrive%\Users\Public\Desktop\desktop.ini" set "_dsk=%SystemDrive%\Users\Public\Desktop"
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
copy /y nul "!_work!\#.rw" 1>nul 2>nul && (if exist "!_work!\#.rw" del /f /q "!_work!\#.rw") || (set "_log=!_dsk!\%~n0")
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
set ksub=SOFTWIM
set ERRORTEMP=
set PREPARED=0
set VOL=0
set EXPRESS=0
set AIO=0
set FixDisplay=0
set uups_esd_num=0
set _count=0
set _Enable=0
set _drv=%~d0
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
cls
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
set _file=(7z.dll,7z.exe,bcdedit.exe,bfi.exe,bootmui.txt,bootwim.txt,cdimage.exe,imagex.exe,libwim-15.dll,offlinereg.exe,offreg.dll,wimlib-imagex.exe)
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
dir /b /ad "!_UUP!\*Package*" %_Nul3% && set EXPRESS=1
for %%# in (
Core,CoreSingleLanguage,CoreCountrySpecific
Professional,ProfessionalEducation,ProfessionalWorkstation
Education,Enterprise,EnterpriseG,Cloud,CloudE
CoreN
ProfessionalN,ProfessionalEducationN,ProfessionalWorkstationN
EducationN,EnterpriseN,EnterpriseGN,CloudN,CloudEN
Starter,StarterN,ProfessionalCountrySpecific,ProfessionalSingleLanguage,ServerRdsh,IoTEnterprise,PPIPro
) do (
if exist "!_UUP!\*%%#_*.esd" dir /b /a:-d "!_UUP!\*%%#_*.esd">>temp\uups_esd.txt %_Nul2%
)
for /f "tokens=3 delims=: " %%# in ('find /v /n /c "" temp\uups_esd.txt') do set uups_esd_num=%%#
if %uups_esd_num% equ 0 goto :E_ESD
for /L %%# in (1,1,%uups_esd_num%) do call :uups_esd %%#
if defined E_WIMLIB goto :QUIT
if %uups_esd_num% gtr 1 goto :MULTIMENU
set "MetadataESD=!_UUP!\%uups_esd1%"&set "arch=%arch1%"&set "langid=%langid1%"&set "editionid=%edition1%"
goto :MAINMENU

:MULTIMENU
if %AutoStart% equ 1 (set AIO=1&set WIMFILE=install.wim&goto :ISO)
if %AutoStart% equ 2 (set AIO=1&set WIMFILE=install.esd&goto :ISO)
cls
set _index=
echo %line%
echo       UUP directory contains multiple editions files:
echo %line%
for /L %%# in (1,1,%uups_esd_num%) do (
echo %%#. !name%%#!
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
if %_index1% equ %%# set "MetadataESD=!_UUP!\!uups_esd%%#!"&set "arch=!arch%%#!"&set "langid=!langid%%#!"&set "editionid=!edition%%#!"&goto :MAINMENU
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
cls
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
cls
set userinp=
echo %line%
echo. 0 - Return to Main Menu
if exist "!_UUP!\*Windows10*KB*.cab" if %W10UI% equ 0 (
if %AddUpdates% equ 2 (echo. 1 - AddUpdates  : Yes {External}) else if %AddUpdates% equ 1 (echo. 1 - AddUpdates  : No  {ADK missing}) else (echo. 1 - AddUpdates  : No)
)
if exist "!_UUP!\*Windows10*KB*.cab" if %W10UI% neq 0 (
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
echo.
echo %line%
set /p userinp= ^> Enter your option and press "Enter": 
if not defined userinp goto :MAINMENU
set userinp=%userinp:~0,1%
if %userinp% equ 0 goto :MAINMENU
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
cls
echo.
echo %line%
echo Running UUP -^> ISO %uivr%
echo %line%
echo.
if not exist "!_UUP!\*Windows10*KB*.cab" set AddUpdates=0
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
call :uups_ref
echo.
echo %line%
echo Creating Setup Media Layout . . .
echo %line%
echo.
if exist ISOFOLDER\ rmdir /s /q ISOFOLDER\
mkdir ISOFOLDER
wimlib-imagex.exe apply "!MetadataESD!" 1 ISOFOLDER\ --no-acls --no-attributes %_Const%
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_Apply
if exist ISOFOLDER\MediaMeta.xml del /f /q ISOFOLDER\MediaMeta.xml %_Nul3%
rem rmdir /s /q ISOFOLDER\sources\uup\ %_Nul3%
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
if %AddUpdates% neq 1 if exist "!_UUP!\*Windows10*KB*.cab" (
call :uups_du
)
copy /y temp\winre.wim ISOFOLDER\sources\boot.wim %_Nul1%
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
if !ERRORTEMP! neq 0 goto :E_Export
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
cls
echo.
echo %line%
echo Running UUP -^> %WIMFILE% %uivr%
echo %line%
echo.
if not exist "!_UUP!\*Windows10*KB*.cab" set AddUpdates=0
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
  echo AddUpdates
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
if %AIO% equ 1 set "MetadataESD=!_UUP!\%uups_esd1%"
if %_count% gtr 1 set "MetadataESD=!_UUP!\!uups_esd%_index1%!"
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
if !ERRORTEMP! neq 0 goto :E_Export
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
if %FixDisplay% equ 1 wimlib-imagex.exe info %_file% 1 "!_os!" "!_os!" --image-property DISPLAYNAME="!_os!" --image-property DISPLAYDESCRIPTION="!_os!" %_Nul3%
set _img=1
if %_count% gtr 1 for /L %%i in (2,1,%_count%) do (
for /L %%# in (1,1,%uups_esd_num%) do if !_index%%i! equ %%# (
  wimlib-imagex.exe export "!_UUP!\!uups_esd%%#!" 3 %_file% --ref="!_UUP!\*.esd" %_rrr% %_Supp%
  call set ERRORTEMP=!ERRORLEVEL!
  if !ERRORTEMP! neq 0 goto :E_Export
  set /a _img+=1
  if %FixDisplay% equ 1 wimlib-imagex.exe info %_file% !_img! "!_os%%#!" "!_os%%#!" --image-property DISPLAYNAME="!_os%%#!" --image-property DISPLAYDESCRIPTION="!_os%%#!" %_Nul3%
  )
)
if %AIO% equ 1 for /L %%# in (2,1,%uups_esd_num%) do (
wimlib-imagex.exe export "!_UUP!\!uups_esd%%#!" 3 %_file% --ref="!_UUP!\*.esd" %_rrr% %_Supp%
call set ERRORTEMP=!ERRORLEVEL!
if !ERRORTEMP! neq 0 goto :E_Export
if %FixDisplay% equ 1 wimlib-imagex.exe info %_file% %%# "!_os%%#!" "!_os%%#!" --image-property DISPLAYNAME="!_os%%#!" --image-property DISPLAYDESCRIPTION="!_os%%#!" %_Nul3%
)
if %AddUpdates% equ 1 if exist "!_UUP!\*Windows10*KB*.cab" (
if exist "!_cabdir!\" rmdir /s /q "!_cabdir!\"
DEL /F /Q %systemroot%\Logs\DISM\* %_Nul3%
if not exist "%systemroot%\Logs\DISM\" mkdir "%systemroot%\Logs\DISM" %_Nul3%
if %_file%==%WIMFILE% (call :uups_update %WIMFILE%) else (call :uups_update)
wimlib-imagex.exe optimize %_file% %_Supp%
)
if %_file%==%WIMFILE% goto :%_rtrn%
if %AddUpdates% equ 2 if exist "!_UUP!\*Windows10*KB*.cab" (
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
if %AddUpdates% equ 1 if exist "!_UUP!\*Windows10*KB*.cab" (
call :uups_update temp\winre.wim
wimlib-imagex.exe optimize temp\winre.wim %_Supp%
)
if %SkipWinRE% neq 0 goto :%_rtrn%
echo.
echo %line%
echo Adding winre.wim to %WIMFILE% . . .
echo %line%
echo.
for /f "tokens=3 delims=: " %%# in ('wimlib-imagex.exe info %_file% ^| findstr /c:"Image Count"') do set imgcount=%%#
for /L %%# in (1,1,%imgcount%) do (
  wimlib-imagex.exe update %_file% %%# --command="add 'temp\winre.wim' '\windows\system32\recovery\winre.wim'" %_Const%
)
goto :%_rtrn%

:BootADK
if %W10UI% equ 0 goto :BootPE
if exist "%_mount%\" rmdir /s /q "%_mount%\"
if not exist "%_mount%\" mkdir "%_mount%"
%_dism1% /Quiet /Mount-Wim /Wimfile:ISOFOLDER\sources\boot.wim /Index:1 /MountDir:"%_mount%" %_Nul3%
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 (
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
wimlib-imagex.exe extract ISOFOLDER\sources\boot.wim 1 Windows\System32\config\SOFTWARE --dest-dir=.\bin\temp --no-acls --no-attributes %_Const%
offlinereg.exe .\bin\temp\SOFTWARE "Microsoft\Windows NT\CurrentVersion\WinPE" setvalue InstRoot X:\$windows.~bt\ %_Nul3%
offlinereg.exe .\bin\temp\SOFTWARE.new "Microsoft\Windows NT\CurrentVersion" setvalue SystemRoot X:\$windows.~bt\Windows %_Nul3%
del /f /q .\bin\temp\SOFTWARE
ren .\bin\temp\SOFTWARE.new SOFTWARE
type nul>bin\boot-wim.txt
>>bin\boot-wim.txt echo add 'bin^\temp^\SOFTWARE' '^\Windows^\System32^\config^\SOFTWARE'
>>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\background_cli.bmp' '^\Windows^\system32^\winre.jpg'
wimlib-imagex.exe update ISOFOLDER\sources\boot.wim 1 < bin\boot-wim.txt %_Const%
rmdir /s /q bin\temp\

:BootST
wimlib-imagex.exe extract "!MetadataESD!" 3 Windows\system32\xmllite.dll --dest-dir=ISOFOLDER\sources --no-acls --no-attributes %_Nul3%
type nul>bin\boot-wim.txt
>>bin\boot-wim.txt echo delete '^\Windows^\system32^\winpeshl.ini'
>>bin\boot-wim.txt echo add 'ISOFOLDER^\setup.exe' '^\setup.exe'
>>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\inf^\setup.cfg' '^\sources^\inf^\setup.cfg'
>>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\background_cli.bmp' '^\sources^\background.bmp'
>>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\background_cli.bmp' '^\Windows^\system32^\winre.jpg'
for /f %%# in (bin\bootwim.txt) do if exist "ISOFOLDER\sources\%%#" (
>>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\%%#' '^\sources^\%%#'
)
for /f %%# in (bin\bootmui.txt) do if exist "ISOFOLDER\sources\%langid%\%%#" (
>>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\%langid%^\%%#' '^\sources^\%langid%^\%%#'
)
wimlib-imagex.exe export temp\winre.wim 1 ISOFOLDER\sources\boot.wim "Microsoft Windows Setup (%arch%)" "Microsoft Windows Setup (%arch%)" --boot %_Supp%
wimlib-imagex.exe update ISOFOLDER\sources\boot.wim 2 < bin\boot-wim.txt %_Const%
wimlib-imagex.exe info ISOFOLDER\sources\boot.wim 2 --image-property FLAGS=2 %_Nul3%
wimlib-imagex.exe optimize ISOFOLDER\sources\boot.wim %_Supp%
del /f /q bin\boot-wim.txt %_Nul3%
del /f /q ISOFOLDER\sources\xmllite.dll %_Nul3%
exit /b

:INFO
if %PREPARED% equ 0 call :PREPARE
cls
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
cls
echo %line%
echo                     UUP Contents Info
echo %line%
echo      Arch: %arch%
echo   Version: %ver1%.%ver2%.%_build%.%svcbuild%
echo    Branch: %branch%
echo  Editions:
for /L %%# in (1,1,%uups_esd_num%) do (
echo %%#. !name%%#!
)
echo.
%_Contn%&%_Pause%
goto :MAINMENU

:PREPARE
cls
echo %line%
echo Checking UUP Info . . .
echo %line%
set PREPARED=1
if %AIO% equ 1 set "MetadataESD=!_UUP!\%uups_esd1%"&set "arch=%arch1%"&set "langid=%langid1%"
if %_count% gtr 1 set "MetadataESD=!_UUP!\!uups_esd%_index1%!"&set "arch=!arch%_index1%!"&set "langid=!langid%_index1%!"
wimlib-imagex.exe info "!MetadataESD!" 3 >bin\info.txt 2>&1
for /f "tokens=1* delims=: " %%A in ('findstr /b "Name" bin\info.txt') do set "_os=%%B"
for /f "tokens=2 delims=: " %%# in ('findstr /b "Build" bin\info.txt') do set _build=%%#
for /f "tokens=4 delims=: " %%# in ('findstr /i /c:"Service Pack Build" bin\info.txt') do set svcbuild=%%#
for /f "tokens=3 delims=: " %%# in ('findstr /i "Major" bin\info.txt') do set ver1=%%#
for /f "tokens=3 delims=: " %%# in ('findstr /i "Minor" bin\info.txt') do set ver2=%%#
del /f /q bin\info.txt %_Nul3%
for /f "tokens=3 delims=<>" %%# in ('imagex /info "!MetadataESD!" 3 ^| find /i "<DISPLAYNAME>" %_Nul6%') do if /i "%%#"=="/DISPLAYNAME" (set FixDisplay=1)
if %FixDisplay% equ 1 if %uups_esd_num% gtr 1 for /L %%# in (2,1,%uups_esd_num%) do (
for /f "tokens=1* delims=: " %%A in ('wimlib-imagex.exe info "!_UUP!\!uups_esd%%#!" 3 ^| findstr /b "Name"') do set "_os%%#=%%B"
)
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
wimlib-imagex.exe extract "!MetadataESD!" 3 Windows\System32\config\SOFTWARE --dest-dir=.\bin\temp --no-acls --no-attributes %_Const%
set "isokey=Microsoft\Windows NT\CurrentVersion\Update\TargetingInfo\Installed"
for /f %%i in ('"offlinereg.exe .\bin\temp\SOFTWARE "!isokey!" enumkeys %_Nul6% ^| find /i "Client.OS""') do if not errorlevel 1 (
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
if %verminor% lss %revminor% (
set version=%revision%
set verminor=%revminor%
wimlib-imagex.exe extract "!MetadataESD!" 3 Windows\servicing\Packages\Package_for_RollupFix*.mum --dest-dir=%SystemRoot%\temp --no-acls --no-attributes %_Nul3%
for /f %%# in ('dir /b /a:-d /od %SystemRoot%\temp\Package_for_RollupFix*.mum') do set "mumfile=%SystemRoot%\temp\%%#"
for /f "tokens=2 delims==" %%# in ('wmic datafile where "name='!mumfile:\=\\!'" get LastModified /value') do set "mumdate=%%#"
del /f /q %SystemRoot%\temp\*.mum
set "labeldate=!mumdate:~2,2!!mumdate:~4,2!!mumdate:~6,2!-!mumdate:~8,4!"
)
set _label2=
if /i "%branch%"=="WinBuild" (
wimlib-imagex.exe extract "!MetadataESD!" 3 Windows\System32\config\SOFTWARE --dest-dir=.\bin\temp --no-acls --no-attributes %_Const%
for /f "tokens=3 delims==:" %%# in ('"offlinereg.exe .\bin\temp\SOFTWARE "Microsoft\Windows NT\CurrentVersion" getvalue BuildLabEx" %_Nul6%') do if not errorlevel 1 (for /f "tokens=1-5 delims=." %%i in ('echo %%~#') do set _label2=%%i.%%j.%%m.%%l_CLIENT&set branch=%%l)
)
if defined _label2 (set _label=%_label2%) else (set _label=%version%.%labeldate%.%branch%_CLIENT)
rmdir /s /q bin\temp\

:setlabel
if /i %arch%==x86 set archl=X86
if /i %arch%==x64 set archl=X64
if /i %arch%==arm64 set archl=A64
for %%# in (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do (
set _label=!_label:%%#=%%#!
set branch=!branch:%%#=%%#!
set langid=!langid:%%#=%%#!
set editionid=!editionid:%%#=%%#!
)

if %AIO% equ 1 set DVDLABEL=CCSA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%MULTI_%archl%FRE_%langid%&exit /b
if %_count% gtr 1 set DVDLABEL=CCSA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%MULTI_%archl%FRE_%langid%&exit /b

set DVDLABEL=CCSA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%%editionid%_RET_%archl%FRE_%langid%
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
	del /f /q temp\update.mum %_Const%
	expand.exe -f:update.mum "!_UUP!\%%#" .\temp %_Const%
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
set pack=%~1
if exist "!_work!\temp\%pack%.ESD" exit /b
echo DIR-^>ESD: %pack%
rmdir /s /q "!_UUP!\%~1\$dpx$.tmp\" %_Nul3%
wimlib-imagex.exe capture "!_UUP!\%~1" "temp\%pack%.ESD" --compress=%_level% --check --no-acls --norpfix "Edition Package" "Edition Package" %_Const%
exit /b

:uups_cab
echo %~1| find /i "RetailDemo" %_Nul1% && exit /b
echo %~1| find /i "Holographic-Desktop-FOD" %_Nul1% && exit /b
echo %~1| find /i "Windows10.0-KB" %_Nul1% && exit /b
set pack=%~n1
if exist "!_work!\temp\%pack%.ESD" exit /b
echo CAB-^>ESD: %pack%
set /a _ref+=1
set /a _rnd=%random%
set _dst=%_drv%\_tmp%_ref%
if exist "%_dst%" (set _dst=%_drv%\_tmp%_rnd%)
mkdir %_dst% %_Nul3%
expand.exe -f:* "!_UUP!\%pack%.cab" %_dst%\ %_Const%
wimlib-imagex.exe capture "%_dst%" "temp\%pack%.ESD" --compress=%_level% --check --no-acls --norpfix "Edition Package" "Edition Package" %_Const%
rmdir /s /q %_dst%\ %_Nul3%
if exist "%_dst%\" (
mkdir %_drv%\_del %_Const%
robocopy %_drv%\_del %_dst% /MIR %_Const%
rmdir /s /q %_drv%\_del\ %_Const%
rmdir /s /q %_dst%\ %_Const%
)
exit /b

:uups_esd
for /f "usebackq  delims=" %%# in (`find /n /v "" temp\uups_esd.txt ^| find "[%1]"`) do set uups_esd=%%#
if %1 geq 1 set uups_esd=%uups_esd:~3%
if %1 geq 10 set uups_esd=%uups_esd:~1%
set "uups_esd%1=%uups_esd%"
wimlib-imagex.exe info "!_UUP!\%uups_esd%" 3 >bin\info.txt 2>&1
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 (
echo %_err%
echo Could not execute wimlib-imagex.exe
echo Use simple work path without special characters
echo.
del /f /q bin\info.txt %_Nul3%
set E_WIMLIB=1
exit /b
)
for /f "tokens=1* delims=: " %%A in ('findstr /b "Name" bin\info.txt') do set "name=%%B"
for /f "tokens=3 delims=: " %%# in ('findstr /b "Edition" bin\info.txt') do set "edition%1=%%#"
for /f "tokens=3 delims=: " %%# in ('findstr /i "Default" bin\info.txt') do set "langid%1=%%#"
for /f "tokens=2 delims=: " %%# in ('findstr /i "Architecture" bin\info.txt') do set "arch%1=%%#"
if /i !arch%1!==x86_64 set "arch%1=x64"
set "name%1=!name! (!arch%1! / !langid%1!)"
del /f /q bin\info.txt %_Nul3%
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
	del /f /q temp\update.mum %_Const%
	expand.exe -f:update.mum "!_UUP!\%%#" .\temp %_Const%
	if not exist "temp\update.mum" set isoupdate=!isoupdate! "%%#"
)
if defined isoupdate (
  mkdir "%_cabdir%\du" %_Nul3%
  for %%# in (!isoupdate!) do expand.exe -r -f:* "!_UUP!\%%~#" "%_cabdir%\du" %_Nul1%
  xcopy /CERUY "%_cabdir%\du" "ISOFOLDER\sources\" %_Nul3%
  if exist "%_cabdir%\du\replacementmanifests" xcopy /CERY "%_cabdir%\du\replacementmanifests" "ISOFOLDER\sources\replacementmanifests\" %_Nul3%
  rmdir /s /q "%_cabdir%\du\" %_Nul3%
)
7z.exe l "ISOFOLDER\sources\setuphost.exe" >.\bin\version.txt 2>&1
for /f "tokens=4-7 delims=.() " %%i in ('"findstr /i /b "FileVersion" .\bin\version.txt" %_Nul6%') do (set isover=%%i.%%j&set isomajor=%%i&set isominor=%%j&set isobranch=%%k&set isodate=%%l)
del /f /q .\bin\version.txt %_Nul3%
if %vermajor%==18363 (
if /i "%isobranch:~0,4%"=="19h1" set isobranch=19h2%isobranch:~4%
if %isover:~0,5%==18362 set isover=18363%isover:~5%
)
if /i not "%isobranch%"=="WinBuild" (set isolabel=%isover%.%isodate%.%isobranch%_CLIENT)
if not defined isolabel exit /b
if %isominor% lss %verminor% exit /b
set _label=%isolabel%
call :setlabel
exit /b

:uups_external
echo.
echo %line%
echo Adding updates files to ISO distribution . . .
echo %line%
echo.
if %_build% gtr 18362 set _Enable=1 
if exist "!_cabdir!\" rmdir /s /q "!_cabdir!\"
if not exist "!_cabdir!\" mkdir "!_cabdir!"
set "_dest=ISOFOLDER\sources\$OEM$\$1\UUP"
if not exist "!_dest!\" mkdir "!_dest!"
copy /y bin\Updates.bat "!_dest!\" %_Nul3%
for /f "tokens=* delims=" %%# in ('dir /b /os "!_UUP!\*Windows10*KB*.cab"') do (set "pack=%%#"&call :external_cab)
if not exist "!_dest!\*Windows10*KB*.cab" (
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
wimlib-imagex.exe extract ISOFOLDER\sources\%WIMFILE% %%# Windows\System32\config\SYSTEM --dest-dir=.\bin\temp --no-acls --no-attributes %_Const%
%_Nul3% offlinereg.exe .\bin\temp\SYSTEM Setup createkey FirstBoot
%_Nul3% offlinereg.exe .\bin\temp\SYSTEM.new Setup\FirstBoot createkey PostSysprep
%_Nul3% offlinereg.exe .\bin\temp\SYSTEM.new Setup\FirstBoot\PostSysprep setvalue uup "cmd.exe /c %%systemdrive%%\$WINDOWS.~BT\Sources\SetupPlatform.exe /postsysprep 2>nul&%%systemdrive%%\UUP\Updates.bat &reg delete HKLM\SYSTEM\Setup\FirstBoot\PostSysprep /v 0 /f 2>nul&reg delete HKLM\SYSTEM\Setup\FirstBoot\PostSysprep /v uup /f &exit /b 0 "
del /f /q .\bin\temp\SYSTEM
ren .\bin\temp\SYSTEM.new SYSTEM
type nul>bin\install-wim.txt
>>bin\install-wim.txt echo add 'bin^\temp^\SYSTEM' '^\Windows^\System32^\config^\SYSTEM'
wimlib-imagex.exe update ISOFOLDER\sources\%WIMFILE% %%# < bin\install-wim.txt %_Const%
del /f /q bin\install-wim.txt
rmdir /s /q bin\temp\
)
if %imgcount% gtr 1 wimlib-imagex.exe optimize ISOFOLDER\sources\%WIMFILE% %_Supp%
exit /b

:external_cab
del /f /q "!_cabdir!\*.manifest" %_Nul3%
del /f /q "!_cabdir!\*.mum" %_Nul3%
del /f /q "!_cabdir!\*.xml" %_Nul3%
expand.exe -f:*.psf.cix.xml "%pack%" "!_cabdir!" %_Const%
if exist "!_cabdir!\*.psf.cix.xml" exit /b
rem expand.exe -f:update.mum "!_UUP!\%pack%" "!_cabdir!" %_Const%
7z.exe e "!_UUP!\%pack%" -o"!_cabdir!" update.mum %_Const%
if not exist "!_cabdir!\update.mum" exit /b
expand.exe -f:*_microsoft-windows-servicingstack_*.manifest "!_UUP!\%pack%" "!_cabdir!" %_Const%
if exist "!_cabdir!\*servicingstack_*.manifest" (
echo SSU: %pack%
copy /y "!_UUP!\%pack%" "!_dest!\1%pack%" %_Nul3%
exit /b
)
findstr /i /m "Package_for_OasisAsset" "!_cabdir!\update.mum" %_Nul3% && (
wimlib-imagex.exe extract ISOFOLDER\sources\%WIMFILE% 1 Windows\servicing\Packages\*OasisAssets-Package*.mum --dest-dir="!_cabdir!" --no-acls --no-attributes %_Const%
if not exist "!_cabdir!\*OasisAssets-Package*.mum" exit /b
)
if %_build% geq 17763 findstr /i /m "WinPE" "!_cabdir!\update.mum" %_Nul3% && (
%_Nul3% findstr /i /m "Edition\"" "!_cabdir!\update.mum"
if errorlevel 1 exit /b
)
findstr /i /m "Package_for_RollupFix" "!_cabdir!\update.mum" %_Nul3% && (
echo LCU: %pack%
copy /y "!_UUP!\%pack%" "!_dest!\3%pack%" %_Nul3%
call :external_label
exit /b
)
echo UPD: %pack%
copy /y "!_UUP!\%pack%" "!_dest!\2%pack%" %_Nul3%
if %_build% geq 18362 (
expand.exe -f:microsoft-windows-*enablement-package*.mum "!_UUP!\%pack%" "!_cabdir!" %_Nul3%
if exist "!_cabdir!\microsoft-windows-*enablement-package*.mum" set _Enable=1
)
exit /b

:external_netfx
for /f %%# in ('dir /b /os "ISOFOLDER\sources\sxs\*NetFx3*.cab"') do set "pack=%%#"
echo DNF: %pack%
copy /y "ISOFOLDER\sources\sxs\%pack%" "!_dest!\" %_Nul3%
exit /b

:external_label
copy /y "!_cabdir!\update.mum" %SystemRoot%\temp\ %_Nul1%
set "mumfile=%SystemRoot%\temp\update.mum"
for /f "tokens=2 delims==" %%# in ('wmic datafile where "name='!mumfile:\=\\!'" get LastModified /value') do set "mumdate=%%#"
del /f /q %SystemRoot%\temp\*.mum
set "labeldate=!mumdate:~2,2!!mumdate:~4,2!!mumdate:~6,2!-!mumdate:~8,4!"
set "isotime=!mumdate:~4,2!/!mumdate:~6,2!/!mumdate:~0,4!,!mumdate:~8,2!:!mumdate:~10,2!:!mumdate:~12,2!"
expand.exe -f:%_ss%_microsoft-windows-coreos-revision*.manifest "!_UUP!\%pack%" "!_cabdir!" %_Const%

for /f "tokens=%tok% delims=_." %%A in ('dir /b /a:-d /od "!_cabdir!\*_microsoft-windows-coreos-revision*.manifest"') do set version=%%A.%%B&set vermajor=%%A&set verminor=%%B

expand.exe -f:%_ss%_microsoft-updatetargeting-clientos*.manifest "!_UUP!\%pack%" "!_cabdir!" %_Const%

if exist "!_cabdir!\*_microsoft-updatetargeting-clientos*.manifest" for /f "tokens=8 delims== " %%# in ('findstr /i Branch "!_cabdir!\*_microsoft-updatetargeting-clientos*.manifest"') do if not defined regbranch set regbranch=%%~#
if defined regbranch set branch=%regbranch%
if %_Enable% equ 1 if exist "!_cabdir!\*_microsoft-updatetargeting-clientos*.manifest" (
for /f "tokens=8 delims== " %%# in ('findstr /i Branch "!_cabdir!\*_microsoft-updatetargeting-clientos*.manifest"') do set branch=%%~#
for /f "tokens=%toe% delims=_." %%I in ('dir /b /a:-d /on "!_cabdir!\*_microsoft-updatetargeting-clientos*.manifest"') do if %%I gtr !vermajor! (set version=%%I.%%K&set vermajor=%%I&set verminor=%%K)
)

if %vermajor%==18363 if /i "%branch:~0,4%"=="19h1" set branch=19h2%branch:~4%

set _label=%version%.%labeldate%.%branch%_CLIENT
call :setlabel
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
if %wim% equ 1 exit /b

for /f "tokens=3 delims=: " %%# in ('wimlib-imagex.exe info "ISOFOLDER\sources\install.wim" ^| findstr /c:"Image Count"') do set imgcount=%%#
for /L %%# in (1,1,%imgcount%) do (
  for /f "tokens=3 delims=<>" %%A in ('imagex /info "ISOFOLDER\sources\install.wim" %%# ^| find /i "<HIGHPART>"') do call set "HIGHPART=%%A"
  for /f "tokens=3 delims=<>" %%A in ('imagex /info "ISOFOLDER\sources\install.wim" %%# ^| find /i "<LOWPART>"') do call set "LOWPART=%%A"
  wimlib-imagex.exe info "ISOFOLDER\sources\install.wim" %%# --image-property CREATIONTIME/HIGHPART=!HIGHPART! --image-property CREATIONTIME/LOWPART=!LOWPART! %_Nul1%
)
if defined isoupdate (
  mkdir "%_cabdir%\du" %_Nul3%
  for %%# in (!isoupdate!) do expand.exe -r -f:* "!_UUP!\%%~#" "%_cabdir%\du" %_Nul1%
  xcopy /CEDRUY "%_cabdir%\du" "ISOFOLDER\sources\" %_Nul3%
  if exist "%_cabdir%\du\replacementmanifests" xcopy /CERY "%_cabdir%\du\replacementmanifests" "ISOFOLDER\sources\replacementmanifests\" %_Nul3%
  rmdir /s /q "%_cabdir%\du\" %_Nul3%
)
7z.exe l "ISOFOLDER\sources\setuphost.exe" >.\bin\version.txt 2>&1
for /f "tokens=4-7 delims=.() " %%i in ('"findstr /i /b "FileVersion" .\bin\version.txt" %_Nul6%') do (set version=%%i.%%j&set vermajor=%%i&set verminor=%%j&set branch=%%k&set labeldate=%%l)
del /f /q .\bin\version.txt %_Nul3%
if /i not "%branch%"=="WinBuild" (set _label=%version%.%labeldate%.%branch%_CLIENT)
if not defined isover (call :setlabel&exit /b)
if %isomajor%==18363 (
if /i "%isobranch:~0,4%"=="19h1" set isobranch=19h2%isobranch:~4%
if /i "%branch:~0,4%"=="19h1" set branch=19h2%branch:~4%
if %version:~0,5%==18362 set version=18363%version:~5%
)
set _label=%version%.%labeldate%.%branch%_CLIENT
if %isominor% gtr %verminor% (set _label=%isover%.%isodate%.%isobranch%_CLIENT)
call :setlabel
exit /b

:extract
if not exist "!_cabdir!\" mkdir "!_cabdir!"
set _cab=0
for /f "tokens=* delims=" %%# in ('dir /b "!_UUP!\*Windows10*KB*.cab"') do (call set /a _cab+=1)
set count=0&set isoupdate=
for /f "tokens=* delims=" %%# in ('dir /b "!_UUP!\*Windows10*KB*.cab"') do (set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :cab2)
goto :eof

:cab2
if defined %package% goto :eof
if exist "!dest!\" rmdir /s /q "!dest!\"
mkdir "!dest!"
expand.exe -f:*.psf.cix.xml "!_UUP!\%package%" "!dest!" %_Const%
if exist "!dest!\*.psf.cix.xml" goto :eof
set /a count+=1
rem expand.exe -f:update.mum "!_UUP!\%package%" "!dest!" %_Const%
7z.exe e "!_UUP!\%package%" -o"!dest!" update.mum %_Const%
if not exist "!dest!\update.mum" (
if not defined %package% echo %count%/%_cab%: %package% ^(DU^)
set isoupdate=!isoupdate! "%package%"
set %package%=1
goto :eof
)
if not defined isodate findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% && (
copy /y "!dest!\update.mum" %SystemRoot%\temp\ %_Nul1%
set "mumfile=%SystemRoot%\temp\update.mum"
for /f "tokens=2 delims==" %%# in ('wmic datafile where "name='!mumfile:\=\\!'" get LastModified /value') do set "mumdate=%%#"
del /f /q %SystemRoot%\temp\*.mum
set "isodate=!mumdate:~2,2!!mumdate:~4,2!!mumdate:~6,2!-!mumdate:~8,4!"
set "isotime=!mumdate:~4,2!/!mumdate:~6,2!/!mumdate:~0,4!,!mumdate:~8,2!:!mumdate:~10,2!:!mumdate:~12,2!"
)
set "_winpe="
if %_build% geq 17763 findstr /i /m "WinPE" "!dest!\update.mum" %_Nul3% && (
%_Nul3% findstr /i /m "Edition\"" "!dest!\update.mum"
if errorlevel 1 set "_winpe=^(WinPE^)"
)
echo %count%/%_cab%: %package% %_winpe%
set %package%=1
expand.exe -f:* "!_UUP!\%package%" "!dest!" %_Const% || (set directcab=!directcab! "%package%"&goto :eof)
7z.exe e "!_UUP!\%package%" -o"!dest!" update.mum -aoa %_Const%
if not exist "!dest!\*cablist.ini" goto :eof
expand.exe -f:* "!dest!\*.cab" "!dest!" %_Const% || (set directcab=!directcab! "%package%"&goto :eof)
del /f /q "!dest!\*cablist.ini" %_Nul3%
del /f /q "!dest!\*.cab" %_Nul3%
goto :eof

:updatewim
set mumtarget=%_mount%
set dismtarget=/image:"%_mount%"
set servicingstack=
set cumulative=
set netroll=
set secureboot=
set ldr=
for /f "tokens=* delims=" %%# in ('dir /b "!_UUP!\*Windows10*KB*.cab"') do (set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :mum)
if not defined secureboot if not defined ldr if not defined cumulative if not defined servicingstack goto :eof
if defined servicingstack (
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%systemroot%\Logs\DISM\DismSSU.log" /Add-Package %servicingstack%
if !errorlevel! neq 0 goto :errmount
if not defined secureboot if not defined ldr if not defined cumulative call :cleanup
)
if not defined secureboot if not defined ldr if not defined cumulative goto :eof
if defined secureboot (
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%systemroot%\Logs\DISM\DismSBoot.log" /Add-Package %secureboot%
cmd /c exit /b !errorlevel!
if /i "!=ExitCode!" neq "00000000" if /i "!=ExitCode!" neq "800f081e" goto :errmount
)
if defined ldr (
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%systemroot%\Logs\DISM\DismUpdt.log" /Add-Package %ldr%
cmd /c exit /b !errorlevel!
if /i "!=ExitCode!" neq "00000000" if /i "!=ExitCode!" neq "800f081e" goto :errmount
)
if defined cumulative (
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%systemroot%\Logs\DISM\DismLCU.log" /Add-Package %cumulative%
cmd /c exit /b !errorlevel!
if /i "!=ExitCode!" neq "00000000" if /i "!=ExitCode!" neq "800f081e" goto :errmount
)
call :cleanup
goto :eof

:errmount
%_dism1% %dismtarget% /Get-Packages %_Const%
%_dism1% /Unmount-Wim /MountDir:"%_mount%" /Discard
%_dism1% /Cleanup-Wim %_Nul3%
rmdir /s /q "%_mount%\" %_Nul3%
popd
set AddUpdates=0
set FullExit=exit
goto :%_rtrn%

:mum
if not exist "!dest!\update.mum" goto :eof
if exist "!dest!\*.psf.cix.xml" goto :eof
if %_build% geq 17763 if not exist "%mumtarget%\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" (
findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (findstr /i /m "Microsoft-Windows-NetFx" "!dest!\*.mum" %_Nul3% && (if exist "!dest!\*_*10.0.*.manifest" if not exist "!dest!\*_netfx4clientcorecomp.resources*.manifest" (set "netroll=!netroll! /packagepath:!dest!\update.mum")))
findstr /i /m "Package_for_OasisAsset" "!dest!\update.mum" %_Nul3% && (if not exist "%mumtarget%\Windows\servicing\packages\*OasisAssets-Package*.mum" goto :eof)
findstr /i /m "WinPE" "!dest!\update.mum" %_Nul3% && (
  %_Nul3% findstr /i /m "Edition\"" "!dest!\update.mum"
  if errorlevel 1 goto :eof
  )
)
if exist "!dest!\*_microsoft-windows-servicingstack_*.manifest" (set "servicingstack=!servicingstack! /packagepath:!dest!\update.mum"&goto :eof)
if exist "!dest!\*_microsoft-windows-s..boot-firmwareupdate_*.manifest" (
if %winbuild% lss 9600 goto :eof
if exist "%mumtarget%\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" goto :eof
set secureboot=!secureboot! /packagepath:"!_UUP!\%package%"
goto :eof
)
if exist "%mumtarget%\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" (
findstr /i /m "WinPE" "!dest!\update.mum" %_Nul3% || (findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (goto :eof))
findstr /i /m "WinPE-NetFx-Package" "!dest!\update.mum" %_Nul3% && (findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (goto :eof))
)
if exist "!dest!\*_adobe-flash-for-windows_*.manifest" (
if not exist "%mumtarget%\Windows\servicing\packages\Adobe-Flash-For-Windows-Package*.mum" if not exist "%mumtarget%\Windows\servicing\packages\Microsoft-Windows-Client-Desktop-Required-Package*.mum" goto :eof
if %_build% geq 16299 (
  set flash=0
  for /f "tokens=3 delims=<= " %%# in ('findstr /i "Edition" "!dest!\update.mum" %_Nul6%') do if exist "%mumtarget%\Windows\servicing\packages\%%~#*.mum" set flash=1
  if "!flash!"=="0" goto :eof
  )
)
for %%# in (%directcab%) do (
if /i "%package%"=="%%~#" (
  set ldr=!ldr! /packagepath:"!_UUP!\%%~#"
  goto :eof
  )
)
findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% && (set "cumulative=!cumulative! /packagepath:!dest!\update.mum"&goto :eof)
set "ldr=!ldr! /packagepath:!dest!\update.mum"
goto :eof

:mount
if exist "%_mount%\" rmdir /s /q "%_mount%\"
if not exist "%_mount%\" mkdir "%_mount%"
set _wim=%~1
set eHome=0
set eHomN=0
set eProf=0
set eProN=0
set uProf=0
set uProN=0
set _upgr=0
if /i not %~nx1==winre.wim if %_build% geq 17063 if %imgcount% gtr 1 set _upgr=1
if %_upgr% equ 1 (
imagex /info "%_wim%">infoall.txt 2>&1
find /i "Core</EDITIONID>" infoall.txt %_Nul1% && (set eHome=1)
find /i "CoreN</EDITIONID>" infoall.txt %_Nul1% && (set eHomN=1)
find /i "Professional</EDITIONID>" infoall.txt %_Nul1% && (set eProf=1)
find /i "ProfessionalN</EDITIONID>" infoall.txt %_Nul1% && (set eProN=1)
del /f /q infoall.txt %_Nul3%
)
if %eProf% equ 1 if %eHome% equ 1 set uProf=1
if %eProN% equ 1 if %eHomN% equ 1 set uProN=1
if %uProf% equ 1 for /L %%# in (1,1,%imgcount%) do (
if not defined iHome (imagex /info "%_wim%" %%# | find /i "Core</EDITIONID>" %_Nul1% && set iHome=%%#)
if not defined iProf (imagex /info "%_wim%" %%# | find /i "Professional</EDITIONID>" %_Nul1% && set iProf=%%#)
)
if %uProf% equ 1 (
set /a imgcount-=1
%_dism1% /Delete-Image /ImageFile:"%_wim%" /Index:%iProf% %_Nul3%
)
if %uProN% equ 1 for /L %%# in (1,1,%imgcount%) do (
if not defined iHomN (imagex /info "%_wim%" %%# | find /i "CoreN</EDITIONID>" %_Nul1% && set iHomN=%%#)
if not defined iProN (imagex /info "%_wim%" %%# | find /i "ProfessionalN</EDITIONID>" %_Nul1% && set iProN=%%#)
)
if %uProN% equ 1 (
set /a imgcount-=1
%_dism1% /Delete-Image /ImageFile:"%_wim%" /Index:%iProN% %_Nul3%
)
set /a _imgi=%imgcount%
for /L %%# in (1,1,%imgcount%) do (
%_dism2%:"!_cabdir!" /Mount-Wim /Wimfile:"%_wim%" /Index:%%# /MountDir:"%_mount%"
if !errorlevel! neq 0 (
%_dism1% /Unmount-Wim /MountDir:"%_mount%" /Discard
%_dism1% /Cleanup-Wim %_Nul3%
goto :eof
)
if %winbuild% lss 15063 if /i %arch%==arm64 (
reg.exe load HKLM\%ksub% "%_mount%\Windows\System32\Config\SOFTWARE" %_Nul1%
reg.exe add HKLM\%ksub%\Microsoft\Windows\CurrentVersion\SideBySide /v AllowImproperDeploymentProcessorArchitecture /t REG_DWORD /d 1 /f %_Nul1%
reg.exe unload HKLM\%ksub% %_Nul1%
)
if %winbuild% lss 9600 (
reg.exe load HKLM\%ksub% "%_mount%\Windows\System32\Config\SOFTWARE" %_Nul1%
reg.exe add HKLM\%ksub%\Microsoft\Windows\CurrentVersion\SideBySide /v AllowImproperDeploymentProcessorArchitecture /t REG_DWORD /d 1 /f %_Nul1%
reg.exe unload HKLM\%ksub% %_Nul1%
)
if /i %xOS%==x86 if /i %arch%==x64 if not exist "%_mount%\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" (
reg.exe load HKLM\%ksub% "%_mount%\Windows\System32\Config\SOFTWARE" %_Nul1%
reg.exe save HKLM\%ksub% "%_mount%\Windows\System32\Config\SOFTWARE2" %_Nul1%
reg.exe unload HKLM\%ksub% %_Nul1%
move /y "%_mount%\Windows\System32\Config\SOFTWARE2" "%_mount%\Windows\System32\Config\SOFTWARE" %_Nul1%
)
call :updatewim
if %NetFx3% equ 1 if %dvd% equ 1 call :enablenet35
if %%# equ 1 if %dvd% equ 1 (
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
if %%# equ 1 if %dvd% equ 1 if not exist "%_mount%\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" if exist "%_mount%\Windows\servicing\Packages\Package_for_RollupFix*.mum" (
for /f "tokens=%tok% delims=_." %%A in ('dir /b /a:-d /od "%_mount%\Windows\WinSxS\Manifests\%_ss%_microsoft-windows-coreos-revision*.manifest"') do set isover=%%A.%%B&set isomajor=%%A&set isominor=%%B
set "isokey=Microsoft\Windows NT\CurrentVersion\Update\TargetingInfo\Installed"
for /f %%i in ('"offlinereg.exe "%_mount%\Windows\system32\config\SOFTWARE" "!isokey!" enumkeys %_Nul6% ^| find /i "Client.OS""') do if not errorlevel 1 (
  for /f "tokens=3 delims==:" %%A in ('"offlinereg.exe "%_mount%\Windows\system32\config\SOFTWARE" "!isokey!\%%i" getvalue Branch %_Nul6%"') do set "isobranch=%%~A"
  for /f "tokens=5,6 delims==:." %%A in ('"offlinereg.exe "%_mount%\Windows\system32\config\SOFTWARE" "!isokey!\%%i" getvalue Version %_Nul6%"') do if %%A gtr !isomajor! (
    set "isover=%%~A.%%B
    set isomajor=%%~A
    set "isominor=%%B
    )
  )
)
%_dism2%:"!_cabdir!" /Unmount-Wim /MountDir:"%_mount%" /Commit %_Supp%
)
if /i %~nx1==winre.wim goto :eof
if %uProf% equ 1 (
%_dism2%:"!_cabdir!" /Mount-Wim /Wimfile:"%_wim%" /Index:%iHome% /MountDir:"%_mount%" %_Supp%
%_dism2%:"!_cabdir!" /Image:"%_mount%" /Set-Edition:Professional /Channel:Retail
%_dism2%:"!_cabdir!" /Unmount-Image /MountDir:"%_mount%" /Commit /Append %_Supp%
call set /a _imgi+=1
call set desc="Windows 10 Pro"
wimlib-imagex.exe info "%_wim%" !_imgi! !desc! !desc! --image-property FLAGS=Professional %_Nul3%
)
if %uProN% equ 1 (
%_dism2%:"!_cabdir!" /Mount-Wim /Wimfile:"%_wim%" /Index:%iHomN% /MountDir:"%_mount%" %_Supp%
%_dism2%:"!_cabdir!" /Image:"%_mount%" /Set-Edition:ProfessionalN /Channel:Retail
%_dism2%:"!_cabdir!" /Unmount-Image /MountDir:"%_mount%" /Commit /Append %_Supp%
call set /a _imgi+=1
call set desc="Windows 10 Pro N"
wimlib-imagex.exe info "%_wim%" !_imgi! !desc! !desc! --image-property FLAGS=ProfessionalN %_Nul3%
)
goto :eof

:cleanup
set savc=0&set savr=1
if %_build% geq 18362 (set savc=3&set savr=3)
if exist "%mumtarget%\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" (
if /i not %arch%==arm64 (
reg.exe load HKLM\%ksub% "%mumtarget%\Windows\System32\Config\SOFTWARE" %_Nul1%
reg.exe add HKLM\%ksub%\Microsoft\Windows\CurrentVersion\SideBySide\Configuration /v SupersededActions /t REG_DWORD /d %savr% /f %_Nul1%
reg.exe unload HKLM\%ksub% %_Nul1%
)
if %Cleanup% neq 0 (
%_dism2%:"!_cabdir!" %dismtarget% /Cleanup-Image /StartComponentCleanup
if %ResetBase% neq 0 %_dism2%:"!_cabdir!" %dismtarget% /Cleanup-Image /StartComponentCleanup /ResetBase %_Const%
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
if /i %xOS%==x86 if /i %arch%==x64 reg.exe save HKLM\%ksub% "%mumtarget%\Windows\System32\Config\SOFTWARE2" %_Nul1%
reg.exe unload HKLM\%ksub% %_Nul1%
if /i %xOS%==x86 if /i %arch%==x64 move /y "%mumtarget%\Windows\System32\Config\SOFTWARE2" "%mumtarget%\Windows\System32\Config\SOFTWARE" %_Nul1%
) else (
%_Nul3% offlinereg.exe "%mumtarget%\Windows\System32\Config\SOFTWARE" Microsoft\Windows\CurrentVersion\SideBySide\Configuration setvalue SupersededActions 3 4
if exist "%mumtarget%\Windows\System32\Config\SOFTWARE.new" del /f /q "%mumtarget%\Windows\System32\Config\SOFTWARE"&ren "%mumtarget%\Windows\System32\Config\SOFTWARE.new" SOFTWARE
)
%_dism2%:"!_cabdir!" %dismtarget% /Cleanup-Image /StartComponentCleanup
if %ResetBase% neq 0 %_dism2%:"!_cabdir!" %dismtarget% /Cleanup-Image /StartComponentCleanup /ResetBase %_Const%
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
for /f "delims=" %%# in ('dir /b /ad "%mumtarget%\Windows\CbsTemp\" %_Nul6%') do rmdir /s /q "%mumtarget%\Windows\CbsTemp\%%#\" %_Nul3%
del /s /f /q "%mumtarget%\Windows\CbsTemp\*" %_Nul3%
goto :eof

:enablenet35
if exist "%mumtarget%\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" goto :eof
if exist "%mumtarget%\Windows\Microsoft.NET\Framework\v2.0.50727\ngen.exe" goto :eof
if not exist "%_target%\sources\sxs\*netfx3*.cab" goto :eof
set "net35source=%_target%\sources\sxs"
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%systemroot%\Logs\DISM\DismNetFx3.log" /Enable-Feature /FeatureName:NetFx3 /All /LimitAccess /Source:"%net35source%"
if not defined netroll if not defined cumulative call :cleanmanual&goto :eof
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%systemroot%\Logs\DISM\DismNetFx3.log" /Add-Package %netroll% %cumulative%
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
if exist "!_cabdir!\" (
if %AddUpdates% equ 1 (
echo.
echo %line%
echo Removing temporary files . . .
echo %line%
echo.
)
rmdir /s /q "!_cabdir!\"
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