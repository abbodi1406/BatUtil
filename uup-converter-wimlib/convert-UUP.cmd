<!-- : Begin batch script
@echo off

:: Change to 1 to start the process directly, it will create ISO with install.wim by default
set AutoStart=0

:: Change to 1 to integrate updates (if detected) into install.wim/winre.wim
set AddUpdates=0

:: Change to 1 to rebase OS image and remove superseded components with updates (faster than default delta-compress)
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

:: script:	   abbodi1406, @rgadguard
:: wimlib:	   synchronicity
:: offlinereg: erwan.l
:: Thanks to: @Ratiborus58, @NecrosoftCore, @DiamondMonday, @WzorNET

:: #################################################################

:: Internal Debug Mode, do not use
set "_Debug=0"
set "_Const=1>nul 2>nul"
if %_Debug% equ 0 (
  set "_Nul1=1>nul"
  set "_Nul2=2>nul"
  set "_Nul6=2^>nul"
  set "_Nul3=1>nul 2>nul"
  set "_Pause=pause >nul"
  set "_Contn=echo Press any key to continue..."
  set "_Exit=echo Press any key to exit."
  set "_Supp="
) else (
  set "_Nul1="
  set "_Nul2="
  set "_Nul6="
  set "_Nul3="
  set "_Pause=rem."
  set "_Contn=rem."
  set "_Exit=rem."
  set "_Supp=1>nul"
  @echo on
  @prompt $G
)

setlocal DisableDelayedExpansion
set UUP=
set _args=%1
if defined _args (
if "%~1"=="" set _args=
)
set _PSarg="""%~f0"""
if exist "%~dp0UUPs\*.esd" set "UUP=%~dp0UUPs"
if defined _args (
set _PSarg="""%~f0""" %_args:"="""%
if exist "%~1\*.esd" set "UUP=%~1"
)
set _PSarg=%_PSarg:'=''%
set "_workdir=%~dp0"
set "_workdir=%_workdir:~0,-1%"
set "_cabdir=%~d0\W10UItemp"
if "%_workdir:~0,2%"=="\\" set "_cabdir=%~dp0temp\W10UItemp"
set "SysPath=%Windir%\System32"
if exist "%Windir%\Sysnative\reg.exe" (set "SysPath=%Windir%\Sysnative")
set "Path=%SysPath%;%Windir%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
set "xOS=amd64"
set "_ComSpec=%Windir%\System32\cmd.exe"
set "_wimlib=%~dp0bin\bin64\wimlib-imagex.exe"
if /i %PROCESSOR_ARCHITECTURE%==x86 (
if defined PROCESSOR_ARCHITEW6432 (
  set "_ComSpec=%Windir%\Sysnative\cmd.exe"
  ) else (
  set "xOS=x86"
  set "_wimlib=%~dp0bin\wimlib-imagex.exe"
  )
)
fsutil dirty query %systemdrive% %_Const% && goto :Begin
(%_Const% cscript //NoLogo "%~f0?.wsf" //job:ELAV /File:"%~f0" %1 ) && (
  exit /b
  ) || (
  call setlocal EnableDelayedExpansion
  %_Const% powershell -NoLogo -NoProfile -ExecutionPolicy Bypass Start-Process -FilePath '!_ComSpec!' -ArgumentList '/c \"!_PSarg! \"' -Verb RunAs && (
    exit /b
    ) || (
    goto :E_Admin
  )
)

:Begin
title UUP -^> ISO
:: checkadk
set regKeyPathFound=1
set wowRegKeyPathFound=1
reg query "HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 %_Nul3% || set wowRegKeyPathFound=0
reg query "HKLM\Software\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 %_Nul3% || set regKeyPathFound=0
if %wowRegKeyPathFound% equ 0 (
  if %regKeyPathFound% equ 0 (
    set ADK=0
    set _dism=dism.exe /English
    goto :precheck
  ) else (
    set regKeyPath=HKLM\Software\Microsoft\Windows Kits\Installed Roots
  )
) else (
    set regKeyPath=HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots
)
for /f "skip=2 tokens=2*" %%i in ('reg query "%regKeyPath%" /v KitsRoot10') do set "KitsRoot=%%j"
set "DandIRoot=%KitsRoot%Assessment and Deployment Kit\Deployment Tools"
set "dismroot=%DandIRoot%\%xOS%\DISM\dism.exe"
set _dism="%dismroot%" /English
set ADK=1
if not exist "%dismroot%" (
set ADK=0
set _dism=dism.exe /English
)

:precheck
for /f "tokens=6 delims=[]. " %%# in ('ver') do set winbuild=%%#
set W10UI=0
if %winbuild% geq 10240 (
set W10UI=1
) else (
if %ADK% equ 1 set W10UI=1
)
pushd "%~dp0"
if not exist "ConvertConfig.ini" goto :proceed
findstr /i \[convert-UUP\] ConvertConfig.ini %_Nul1% || goto :proceed
for %%# in (
AutoStart
AddUpdates
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
set ERRORTEMP=
set PREPARED=0
set VOL=0
set EXPRESS=0
set AIO=0
set FixDisplay=0
set uups_esd_num=0
set _drv=%~d0
set "mountdir=%_drv%\MountUUP"
set "_ntf=NTFS"
if /i not "%_drv%"=="%SystemDrive%" for /f "tokens=2 delims==" %%# in ('"wmic volume where DriveLetter='%_drv%' get FileSystem /value"') do set "_ntf=%%#"
if /i not "%_ntf%"=="NTFS" (
set "mountdir=%SystemDrive%\MountUUP"
)
set "line============================================================="
set "_err===== ERROR ===="
set _file=(7z.dll,7z.exe,bcdedit.exe,bfi.exe,bootmui.txt,bootwim.txt,cdimage.exe,imagex.exe,libwim-15.dll,offlinereg.exe,offreg.dll,wimlib-imagex.exe)
for %%# in %_file% do (
if not exist ".\bin\%%#" (set _bin=%%#&goto :E_Bin)
)
if defined UUP goto :check

:prompt
cls
set UUP=
echo %line%
echo Enter / Paste the path to UUP files directory
echo %line%
echo.
set /p UUP=
if not defined UUP set _Debug=1&goto :QUIT
set "UUP=%UUP:"=%"
if "%UUP:~-1%"=="\" set "UUP=%UUP:~0,-1%"
if not exist "%UUP%\*.esd" (
echo.
echo %_err%
echo Specified path is not a valid UUP source
echo.
%_Contn%&%_Pause%
goto :prompt
)

:check
color 1F
setlocal EnableDelayedExpansion
set _configured=0
for %%# in (
AutoStart
AddUpdates
ResetBase
NetFx3
StartVirtual
SkipISO
SkipWinRE
wim2esd
ForceDism
RefESD
) do (
if !%%#! equ 1 set _configured=1
)
if exist bin\temp\ rmdir /s /q bin\temp\
if exist temp\ rmdir /s /q temp\
mkdir bin\temp
mkdir temp
dir /b /ad "!UUP!\*Package*" %_Nul3% && set EXPRESS=1
del /f /q temp\uups_esd.txt %_Nul3%
for %%# in (
Core,CoreSingleLanguage,CoreCountrySpecific
Professional,ProfessionalEducation,ProfessionalWorkstation
Education,Enterprise,EnterpriseG,Cloud,CloudE
CoreN
ProfessionalN,ProfessionalEducationN,ProfessionalWorkstationN
EducationN,EnterpriseN,EnterpriseGN,CloudN,CloudEN
Starter,StarterN,ProfessionalCountrySpecific,ProfessionalSingleLanguage,ServerRdsh,IoTEnterprise,PPIPro
) do (
if exist "!UUP!\*%%#_*.esd" dir /b /a:-d "!UUP!\*%%#_*.esd">>temp\uups_esd.txt %_Nul2%
)
for /f "tokens=3 delims=: " %%# in ('find /v /n /c "" temp\uups_esd.txt') do set uups_esd_num=%%#
if %uups_esd_num% equ 0 goto :E_ESD
if %uups_esd_num% gtr 1 (
for /L %%# in (1, 1, %uups_esd_num%) do call :uups_esd %%#
goto :MULTIMENU
)
call :uups_esd 1
set "MetadataESD=!UUP!\%uups_esd1%"&set "arch=%arch1%"&set "editionid=%edition1%"&set "langid=%langid1%"
goto :MAINMENU

:MULTIMENU
if %AutoStart% equ 1 (set AIO=1&set WIMFILE=install.wim&goto :ISO)
if %AutoStart% equ 2 (set AIO=1&set WIMFILE=install.esd&goto :ISO)
cls
set userinp=
echo %line%
echo       UUP directory contains multiple editions files:
echo %line%
for /L %%# in (1, 1, %uups_esd_num%) do (
echo %%#. !name%%#!
)
echo %line%
echo Enter edition number to create, or zero '0' to create AIO
echo %line%
set /p userinp= ^> Enter your option and press "Enter": 
if not defined userinp set _Debug=1&goto :QUIT
set userinp=%userinp:~0,2%
if %userinp% equ 0 (set "_tag= AIO"&set "_ta2=AIO"&set AIO=1&goto :MAINMENU)
for /L %%# in (1, 1, %uups_esd_num%) do (
if %userinp% equ %%# set "MetadataESD=!UUP!\!uups_esd%%#!"&set "arch=!arch%%#!"&set "editionid=!edition%%#!"&set "langid=!langid%%#!"&goto :MAINMENU
)
goto :MULTIMENU

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
if exist "!UUP!\*Windows10*KB*.cab" if %W10UI% equ 1 (
if %AddUpdates% equ 1 (echo. 1 - AddUpdates  : Yes) else (echo. 1 - AddUpdates  : No)
if %AddUpdates% equ 1 (
  if %ResetBase% equ 1 (echo. 2 - ResetBase   : Yes) else (echo. 2 - ResetBase   : No)
  if %NetFx3% equ 1 (echo. 3 - NetFx3      : Yes) else (echo. 3 - NetFx3      : No)
  )
)
if %StartVirtual% equ 1 (echo. 4 - StartVirtual: Yes) else (echo. 4 - StartVirtual: No)
if %wim2esd% equ 1 (echo. 5 - WIM2ESD     : Yes) else (echo. 5 - WIM2ESD     : No)
if %SkipISO% equ 1 (echo. 6 - SkipISO     : Yes) else (echo. 6 - SkipISO     : No)
if %SkipWinRE% equ 1 (echo. 7 - SkipWinRE   : Yes) else (echo. 7 - SkipWinRE   : No)
if %W10UI% equ 1 (
if %ForceDism% equ 1 (echo. 8 - ForceDism   : Yes) else (echo. 8 - ForceDism   : No)
)
if %RefESD% equ 1 (echo. 9 - RefESD      : Yes) else (echo. 9 - RefESD      : No)
echo.
echo %line%
set /p userinp= ^> Enter your option and press "Enter": 
if not defined userinp goto :MAINMENU
set userinp=%userinp:~0,1%
if %userinp% equ 0 goto :MAINMENU
if %userinp% equ 9 (if %RefESD% equ 0 (set RefESD=1) else (set RefESD=0))&goto :CONFMENU
if %userinp% equ 8 if %W10UI% equ 1 (if %ForceDism% equ 0 (set ForceDism=1) else (set ForceDism=0))&goto :CONFMENU
if %userinp% equ 7 (if %SkipWinRE% equ 0 (set SkipWinRE=1) else (set SkipWinRE=0))&goto :CONFMENU
if %userinp% equ 6 (if %SkipISO% equ 0 (set SkipISO=1) else (set SkipISO=0))&goto :CONFMENU
if %userinp% equ 5 (if %wim2esd% equ 0 (set wim2esd=1) else (set wim2esd=0))&goto :CONFMENU
if %userinp% equ 4 (if %StartVirtual% equ 0 (set StartVirtual=1) else (set StartVirtual=0))&goto :CONFMENU
if %userinp% equ 3 if %AddUpdates% equ 1 (if %NetFx3% equ 0 (set NetFx3=1) else (set NetFx3=0))&goto :CONFMENU
if %userinp% equ 2 if %AddUpdates% equ 1 (if %ResetBase% equ 0 (set ResetBase=1) else (set ResetBase=0))&goto :CONFMENU
if %userinp% equ 1 (if %AddUpdates% equ 0 (set AddUpdates=1) else (set AddUpdates=0))&goto :CONFMENU
goto :CONFMENU

:ISO
if %W10UI% equ 0 (set AddUpdates=0)
if %WIMFILE%==install.wim (
if %AddUpdates% equ 0 if %wim2esd% equ 1 (set WIMFILE=install.esd)
)
if %WIMFILE%==install.esd (
set wim2esd=0
if %AddUpdates% equ 1 (set WIMFILE=install.wim&set wim2esd=1)
)
cls
if %PREPARED% equ 0 call :PREPARE
if %build% lss 17063 (set StartVirtual=0)
if %_configured% equ 1 (
echo.
echo %line%
echo Configured Options . . .
echo %line%
echo.
if %AutoStart% neq 0 echo AutoStart %AutoStart%
if %AddUpdates% equ 1 (
  echo AddUpdates
  if %ResetBase% equ 1 echo ResetBase
  if %NetFx3% equ 1 echo NetFx3
  )
if %StartVirtual% equ 1 echo StartVirtual
  for %%# in (
  SkipISO
  SkipWinRE
  wim2esd
  ForceDism
  RefESD
  ) do (
  if !%%#! equ 1 echo %%#
  )
)
if %RefESD% equ 1 (set _level=maximum) else (set _level=fast)
call :uups_ref
echo.
echo %line%
echo Creating Setup Media Layout . . .
echo %line%
echo.
if exist ISOFOLDER\ rmdir /s /q ISOFOLDER\
mkdir ISOFOLDER
"!_wimlib!" apply "!MetadataESD!" 1 ISOFOLDER\ --no-acls --no-attributes %_Const%
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_Apply
del /f /q ISOFOLDER\MediaMeta.xml %_Nul3%
rmdir /s /q ISOFOLDER\sources\uup\ %_Nul3%
if %AIO% equ 1 del /f /q ISOFOLDER\sources\ei.cfg %_Nul3%
echo.
echo %line%
echo Creating %WIMFILE% . . .
echo %line%
echo.
for /f "tokens=5-10 delims=: " %%G in ('bin\wimlib-imagex info "!MetadataESD!" 3 ^| find /i "Last Modification Time"') do (set mmm=%%G&set "isotime=%%H/%%L,%%I:%%J:%%K")
call :setdate %mmm%
if exist "temp\*.ESD" (set _rrr=--ref="temp\*.esd") else (set "_rrr=")
if %WIMFILE%==install.wim set _rrr=%_rrr% --compress=maximum
"!_wimlib!" export "!MetadataESD!" 3 ISOFOLDER\sources\%WIMFILE% --ref="!UUP!\*.esd" %_rrr% %_Supp%
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_Export
if %FixDisplay% equ 1 (
  "!_wimlib!" info ISOFOLDER\sources\%WIMFILE% 1 "%_os%" "%_os%" --image-property DISPLAYNAME="%_os%" --image-property DISPLAYDESCRIPTION="%_os%" %_Nul3%
)
if %AIO% equ 1 for /L %%# in (2, 1, %uups_esd_num%) do (
"!_wimlib!" export "!UUP!\!uups_esd%%#!" 3 ISOFOLDER\sources\%WIMFILE% --ref="!UUP!\*.esd" %_rrr% %_Supp%
call set ERRORTEMP=!ERRORLEVEL!
if !ERRORTEMP! neq 0 goto :E_Export
if %FixDisplay% equ 1 (
  "!_wimlib!" info ISOFOLDER\sources\%WIMFILE% %%# "!_os%%#!" "!_os%%#!" --image-property DISPLAYNAME="!_os%%#!" --image-property DISPLAYDESCRIPTION="!_os%%#!" %_Nul3%
  )
)
if %AddUpdates% equ 1 if exist "!UUP!\*Windows10*KB*.cab" (
if exist "!_cabdir!" rmdir /s /q "!_cabdir!"
DEL /F /Q %systemroot%\Logs\DISM\* %_Nul3%
call :uups_update
"!_wimlib!" optimize ISOFOLDER\sources\%WIMFILE% %_Supp%
)
echo.
echo %line%
echo Creating winre.wim . . .
echo %line%
echo.
"!_wimlib!" export "!MetadataESD!" 2 temp\winre.wim --compress=maximum --boot %_Supp%
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_Export
if %AddUpdates% equ 1 if exist "!UUP!\*Windows10*KB*.cab" (
call :uups_update "!_workdir!\temp\winre.wim"
"!_wimlib!" optimize temp\winre.wim %_Supp%
)
if %SkipWinRE% equ 1 goto :Iproceed
echo.
echo %line%
echo Adding winre.wim to %WIMFILE% . . .
echo %line%
echo.
"!_wimlib!" update ISOFOLDER\sources\%WIMFILE% 1 --command="add 'temp\winre.wim' '\windows\system32\recovery\winre.wim'" %_Const%
if %AIO% equ 1 for /L %%# in (2, 1, %uups_esd_num%) do (
  "!_wimlib!" update ISOFOLDER\sources\%WIMFILE% %%# --command="add 'temp\winre.wim' '\windows\system32\recovery\winre.wim'" %_Const%
)
:Iproceed
echo.
echo %line%
echo Creating boot.wim . . .
echo %line%
echo.
if %AddUpdates% equ 0 if exist "!UUP!\*Windows10*KB*.cab" (
call :uups_du
)
copy /y temp\winre.wim ISOFOLDER\sources\boot.wim %_Nul1%
"!_wimlib!" info ISOFOLDER\sources\boot.wim 1 "Microsoft Windows PE (%arch%)" "Microsoft Windows PE (%arch%)" --image-property FLAGS=9 %_Nul3%
"!_wimlib!" update ISOFOLDER\sources\boot.wim 1 --command="delete '\Windows\system32\winpeshl.ini'" %_Nul3%
if %ForceDism% equ 0 (
call :BootPE
) else (
call :BootADK
)
if %build% geq 18890 (
set "bcde=bin\bcdedit.exe"
set "BCDBIOS=ISOFOLDER\boot\bcd"
set "BCDUEFI=ISOFOLDER\efi\microsoft\boot\bcd"
!bcde! /store !BCDBIOS! /set {default} bootmenupolicy legacy %_Nul3%
!bcde! /store !BCDUEFI! /set {default} bootmenupolicy legacy %_Nul3%
attrib -s -h -a "!BCDBIOS!.LOG*" %_Nul3%
attrib -s -h -a "!BCDUEFI!.LOG*" %_Nul3%
del /f /q "!BCDBIOS!.LOG*" %_Nul3%
del /f /q "!BCDUEFI!.LOG*" %_Nul3%
)
if %StartVirtual% equ 1 (
  if %RefESD% equ 1 call :uups_backup
  ren ISOFOLDER %DVDISO%
  if %AutoStart% neq 0 (goto :V_Auto) else (goto :V_Manu)
)
if %wim2esd% equ 1 (
echo.
echo %line%
echo Converting install.wim to install.esd . . .
echo %line%
echo.
"!_wimlib!" export ISOFOLDER\sources\install.wim all ISOFOLDER\sources\install.esd --compress=LZMS --solid %_Supp%
call set ERRORTEMP=!ERRORLEVEL!
if !ERRORTEMP! neq 0 goto :E_Export
if exist ISOFOLDER\sources\install.esd del /f /q ISOFOLDER\sources\install.wim
)
if %SkipISO% equ 1 (
  if %RefESD% equ 1 call :uups_backup
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
bin\cdimage.exe -bootdata:2#p0,e,b"ISOFOLDER\boot\etfsboot.com"#pEF,e,b"ISOFOLDER\efi\Microsoft\boot\efisys.bin" -o -m -u2 -udfver102 -t%isotime% -g -l%DVDLABEL% ISOFOLDER %DVDISO%.ISO
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_ISO
if %RefESD% equ 1 call :uups_backup&echo Finished
echo.
goto :QUIT

:Single
if %W10UI% equ 0 (set AddUpdates=0)
if %WIMFILE%==install.wim (
if %AddUpdates% equ 0 if %wim2esd% equ 1 (set WIMFILE=install.esd)
)
if %WIMFILE%==install.esd (
set wim2esd=0
if %AddUpdates% equ 1 (set WIMFILE=install.wim&set wim2esd=1)
)
cls
if exist "!_workdir!\%WIMFILE%" (
echo.
echo %line%
echo An %WIMFILE% file is already present in the current folder
echo %line%
echo.
goto :QUIT
)
if %PREPARED% equ 0 call :PREPARE
if %_configured% equ 1 (
echo.
echo %line%
echo Configured Options . . .
echo %line%
echo.
if %AddUpdates% equ 1 (
  echo AddUpdates
  if %ResetBase% equ 1 echo ResetBase
  )
  for %%# in (
  SkipWinRE
  wim2esd
  RefESD
  ) do (
  if !%%#! equ 1 echo %%#
  )
)
if %RefESD% equ 1 (set _level=maximum) else (set _level=fast)
call :uups_ref
echo.
echo %line%
echo Creating %WIMFILE% . . .
echo %line%
echo.
if %AIO% equ 1 set "MetadataESD=!UUP!\%uups_esd1%"
if exist "temp\*.ESD" (set _rrr=--ref="temp\*.esd") else (set "_rrr=")
if %WIMFILE%==install.wim set _rrr=%_rrr% --compress=maximum
"!_wimlib!" export "!MetadataESD!" 3 %WIMFILE% --ref="!UUP!\*.esd" %_rrr% %_Supp%
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_Export
if %FixDisplay% equ 1 (
  "!_wimlib!" info %WIMFILE% 1 "%_os%" "%_os%" --image-property DISPLAYNAME="%_os%" --image-property DISPLAYDESCRIPTION="%_os%" %_Nul3%
)
if %AIO% equ 1 for /L %%# in (2, 1, %uups_esd_num%) do (
"!_wimlib!" export "!UUP!\!uups_esd%%#!" 3 %WIMFILE% --ref="!UUP!\*.esd" %_rrr% %_Supp%
call set ERRORTEMP=!ERRORLEVEL!
if !ERRORTEMP! neq 0 goto :E_Export
if %FixDisplay% equ 1 (
  "!_wimlib!" info %WIMFILE% %%# "!_os%%#!" "!_os%%#!" --image-property DISPLAYNAME="!_os%%#!" --image-property DISPLAYDESCRIPTION="!_os%%#!" %_Nul3%
  )
)
if %AddUpdates% equ 1 if exist "!UUP!\*Windows10*KB*.cab" (
if exist "!_cabdir!" rmdir /s /q "!_cabdir!"
DEL /F /Q %systemroot%\Logs\DISM\* %_Nul3%
call :uups_update "!_workdir!\%WIMFILE%"
"!_wimlib!" optimize %WIMFILE% %_Supp%
)
if %SkipWinRE% equ 1 goto :Sproceed
echo.
echo %line%
echo Creating winre.wim . . .
echo %line%
echo.
"!_wimlib!" export "!MetadataESD!" 2 temp\winre.wim --compress=maximum --boot %_Supp%
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_Export
if %AddUpdates% equ 1 if exist "!UUP!\*Windows10*KB*.cab" (
call :uups_update "!_workdir!\temp\winre.wim"
"!_wimlib!" optimize temp\winre.wim %_Supp%
)
echo.
echo %line%
echo Adding winre.wim to %WIMFILE% . . .
echo %line%
echo.
"!_wimlib!" update %WIMFILE% 1 --command="add 'temp\winre.wim' '\windows\system32\recovery\winre.wim'" %_Const%
if %AIO% equ 1 for /L %%# in (2, 1, %uups_esd_num%) do (
  "!_wimlib!" update %WIMFILE% %%# --command="add 'temp\winre.wim' '\windows\system32\recovery\winre.wim'" %_Const%
)
:Sproceed
if %wim2esd% equ 1 (
echo.
echo %line%
echo Converting install.wim to install.esd . . .
echo %line%
echo.
"!_wimlib!" export install.wim all install.esd --compress=LZMS --solid %_Supp%
call set ERRORTEMP=!ERRORLEVEL!
if !ERRORTEMP! neq 0 goto :E_Export
if exist install.esd del /f /q install.wim
)
if %RefESD% equ 1 call :uups_backup
echo.
echo Done.
echo.
goto :QUIT

:INFO
if %PREPARED% equ 0 call :PREPARE
cls
echo %line%
echo                     UUP Contents Info
echo %line%
echo      Arch: %arch%
echo  Language: %langid%
echo   Version: %ver1%.%ver2%.%build%.%svcbuild%
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
echo   Version: %ver1%.%ver2%.%build%.%svcbuild%
echo    Branch: %branch%
echo  Editions:
for /L %%# in (1, 1, %uups_esd_num%) do (
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
if %AIO% equ 1 set "MetadataESD=!UUP!\%uups_esd1%"&set "arch=%arch1%"&set "langid=%langid1%"
bin\wimlib-imagex info "!MetadataESD!" 3 >bin\info.txt 2>&1
for /f "tokens=1* delims=: " %%A in ('findstr /b "Name" bin\info.txt') do set "_os=%%B"
for /f "tokens=2 delims=: " %%# in ('findstr /b "Build" bin\info.txt') do set build=%%#
for /f "tokens=4 delims=: " %%# in ('findstr /i /c:"Service Pack Build" bin\info.txt') do set svcbuild=%%#
for /f "tokens=3 delims=: " %%# in ('findstr /i "Major" bin\info.txt') do set ver1=%%#
for /f "tokens=3 delims=: " %%# in ('findstr /i "Minor" bin\info.txt') do set ver2=%%#
del /f /q bin\info.txt %_Nul3%
for /f "tokens=3 delims=<>" %%# in ('bin\imagex /info "!MetadataESD!" 3 ^| find /i "<DISPLAYNAME>" %_Nul6%') do if /i "%%#"=="/DISPLAYNAME" (set FixDisplay=1)
if %FixDisplay% equ 1 if %AIO% equ 1 for /L %%# in (2, 1, %uups_esd_num%) do (
for /f "tokens=1* delims=: " %%A in ('bin\wimlib-imagex info "!UUP!\!uups_esd%%#!" 3 ^| findstr /b "Name"') do set "_os%%#=%%B"
)
"!_wimlib!" extract "!MetadataESD!" 1 sources\ei.cfg --dest-dir=.\bin\temp --no-acls --no-attributes %_Nul3%
if exist "bin\temp\ei.cfg" type .\bin\temp\ei.cfg %_Nul2% | find /i "Volume" %_Nul1% && set VOL=1
"!_wimlib!" extract "!MetadataESD!" 1 sources\setuphost.exe --dest-dir=.\bin\temp --no-acls --no-attributes %_Nul3%
bin\7z.exe l .\bin\temp\setuphost.exe >.\bin\temp\version.txt 2>&1
for /f "tokens=4-7 delims=.() " %%i in ('"findstr /i /b "FileVersion" .\bin\temp\version.txt" %_Nul6%') do (set version=%%i.%%j&set branch=%%k&set labeldate=%%l)
if /i %arch%==x86 (set _ss=x86) else if /i %arch%==x64 (set _ss=amd64) else (set _ss=arm64)
"!_wimlib!" extract "!MetadataESD!" 3 Windows\WinSxS\Manifests\%_ss%_microsoft-windows-coreos-revision*.manifest --dest-dir=.\bin\temp --no-acls --no-attributes %_Nul3%
for /f "tokens=6,7 delims=_." %%A in ('dir /b /a:-d /od .\bin\temp\*.manifest') do set revision=%%A.%%B
if %version:.=% lss %revision:.=% (
set version=%revision%
"!_wimlib!" extract "!MetadataESD!" 3 Windows\servicing\Packages\Package_for_RollupFix*.mum --dest-dir=%windir%\temp --no-acls --no-attributes %_Nul3%
for /f %%# in ('dir /b /a:-d /od %windir%\temp\Package_for_RollupFix*.mum') do set "mumfile=%windir%\temp\%%#"
for /f "tokens=2 delims==" %%# in ('wmic datafile where "name='!mumfile:\=\\!'" get LastModified /value') do set "mumdate=%%#"
del /f /q %windir%\temp\*.mum
set "labeldate=!mumdate:~2,2!!mumdate:~4,2!!mumdate:~6,2!-!mumdate:~8,4!"
)
set _label2=
if /i "%branch%"=="WinBuild" (
"!_wimlib!" extract "!MetadataESD!" 3 \Windows\System32\config\SOFTWARE --dest-dir=.\bin\temp --no-acls --no-attributes %_Const%
for /f "tokens=3 delims==:" %%# in ('"bin\offlinereg.exe .\bin\temp\SOFTWARE "Microsoft\Windows NT\CurrentVersion" getvalue BuildLabEx" %_Nul6%') do if not errorlevel 1 (for /f "tokens=1-5 delims=." %%i in ('echo %%~#') do set _label2=%%i.%%j.%%m.%%l_CLIENT&set branch=%%l)
)
if defined _label2 (set _label=%_label2%) else (set _label=%version%.%labeldate%.%branch%_CLIENT)
rmdir /s /q .\bin\temp

:setlabel
set archl=%arch%
for %%# in (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do (
set _label=!_label:%%#=%%#!
set branch=!branch:%%#=%%#!
set langid=!langid:%%#=%%#!
set editionid=!editionid:%%#=%%#!
set archl=!archl:%%#=%%#!
)

if %AIO% equ 1 set DVDLABEL=CCSA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%MULTI_UUP_%archl%FRE_%langid%&exit /b

set DVDLABEL=CCSA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%%editionid%_RET_%archl%FRE_%langid%
if /i %editionid%==Core set DVDLABEL=CCRA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%CORE_OEMRET_%archl%FRE_%langid%
if /i %editionid%==CoreN set DVDLABEL=CCRNA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%COREN_OEMRET_%archl%FRE_%langid%
if /i %editionid%==CoreSingleLanguage set DVDLABEL=CSLA_%archl%FREO_%langid%_DV5&set DVDISO=%_label%SINGLELANGUAGE_OEM_%archl%FRE_%langid%
if /i %editionid%==CoreCountrySpecific set DVDLABEL=CCHA_%archl%FREO_%langid%_DV5&set DVDISO=%_label%CHINA_OEM_%archl%FRE_%langid%
if /i %editionid%==Professional (if %VOL% equ 1 (set DVDLABEL=CPRA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%PROFESSIONALVL_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CPRA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%PRO_OEMRET_%archl%FRE_%langid%))
if /i %editionid%==ProfessionalN (if %VOL% equ 1 (set DVDLABEL=CPRNA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%PROFESSIONALNVL_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CPRNA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%PRON_OEMRET_%archl%FRE_%langid%))
if /i %editionid%==Education (if %VOL% equ 1 (set DVDLABEL=CEDA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%EDUCATION_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CEDA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%EDUCATION_RET_%archl%FRE_%langid%))
if /i %editionid%==EducationN (if %VOL% equ 1 (set DVDLABEL=CEDNA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%EDUCATIONN_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CEDNA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%EDUCATIONN_RET_%archl%FRE_%langid%))
if /i %editionid%==Enterprise set DVDLABEL=CENA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%ENTERPRISE_VOL_%archl%FRE_%langid%
if /i %editionid%==EnterpriseN set DVDLABEL=CENNA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%ENTERPRISEN_VOL_%archl%FRE_%langid%
if /i %editionid%==Cloud set DVDLABEL=CWCA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%CLOUD_OEMRET_%archl%FRE_%langid%
if /i %editionid%==CloudN set DVDLABEL=CWCNNA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%CLOUDN_OEMRET_%archl%FRE_%langid%
exit /b

:BootADK
if %W10UI% equ 0 goto :BootPE
if exist "%mountdir%" rmdir /s /q "%mountdir%"
if not exist "%mountdir%" mkdir "%mountdir%"
!_dism! /Quiet /Mount-Wim /Wimfile:ISOFOLDER\sources\boot.wim /Index:1 /MountDir:"%mountdir%" %_Nul3%
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 (
!_dism! /Unmount-Wim /MountDir:"%mountdir%" /Discard %_Nul3%
!_dism! /Cleanup-Wim %_Nul3%
rmdir /s /q "%mountdir%"
goto :BootPE
)
!_dism! /Quiet /Image:"%mountdir%" /Set-TargetPath:X:\$windows.~bt\
!_dism! /Quiet /Unmount-Wim /MountDir:"%mountdir%" /Commit
rmdir /s /q "%mountdir%"
goto :BootST

:BootPE
"!_wimlib!" extract ISOFOLDER\sources\boot.wim 1 \Windows\System32\config\SOFTWARE --dest-dir=.\bin\temp --no-acls --no-attributes %_Const%
bin\offlinereg .\bin\temp\SOFTWARE "Microsoft\Windows NT\CurrentVersion\WinPE" setvalue InstRoot X:\$windows.~bt\ %_Nul3%
bin\offlinereg .\bin\temp\SOFTWARE.new "Microsoft\Windows NT\CurrentVersion" setvalue SystemRoot X:\$windows.~bt\Windows %_Nul3%
del /f /q .\bin\temp\SOFTWARE
ren .\bin\temp\SOFTWARE.new SOFTWARE
type nul>bin\boot-wim.txt
>>bin\boot-wim.txt echo add 'bin^\temp^\SOFTWARE' '^\Windows^\System32^\config^\SOFTWARE'
>>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\background_cli.bmp' '^\Windows^\system32^\winre.jpg'
"!_wimlib!" update ISOFOLDER\sources\boot.wim 1 < bin\boot-wim.txt %_Const%
rmdir /s /q .\bin\temp

:BootST
"!_wimlib!" extract "!MetadataESD!" 3 Windows\system32\xmllite.dll --dest-dir=ISOFOLDER\sources --no-acls --no-attributes %_Nul3%
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
"!_wimlib!" export temp\winre.wim 1 ISOFOLDER\sources\boot.wim "Microsoft Windows Setup (%arch%)" "Microsoft Windows Setup (%arch%)" --boot %_Supp%
"!_wimlib!" update ISOFOLDER\sources\boot.wim 2 < bin\boot-wim.txt %_Const%
"!_wimlib!" info ISOFOLDER\sources\boot.wim 2 --image-property FLAGS=2 %_Nul3%
"!_wimlib!" optimize ISOFOLDER\sources\boot.wim %_Supp%
del /f /q bin\boot-wim.txt %_Nul3%
del /f /q ISOFOLDER\sources\xmllite.dll %_Nul3%
exit /b

:uups_ref
echo.
echo %line%
echo Preparing Reference ESDs . . .
echo %line%
echo.
if exist "!UUP!\*.xml.cab" if exist "!UUP!\Metadata\*" move /y "!UUP!\*.xml.cab" "!UUP!\Metadata\" %_Nul3%
if exist "!UUP!\*.cab" (
for /f "delims=" %%# in ('dir /b /a:-d "!UUP!\*.cab"') do (
	del /f /q temp\update.mum %_Const%
	expand.exe -f:update.mum "!UUP!\%%#" .\temp %_Const%
	if exist "temp\update.mum" call :uups_cab "%%#"
	)
)
if %EXPRESS% equ 1 (
for /f "delims=" %%# in ('dir /b /a:d /o:-n "!UUP!\"') do call :uups_dir "%%#"
)
if exist "!UUP!\Metadata\*.xml.cab" copy /y "!UUP!\Metadata\*.xml.cab" "!UUP!\" %_Nul3%
exit /b

:uups_dir
if /i "%~1"=="Metadata" exit /b
echo %~1| find /i "RetailDemo" %_Nul1% && exit /b
echo %~1| find /i "Holographic-Desktop-FOD" %_Nul1% && exit /b
echo %~1| find /i "Windows10.0-KB" %_Nul1% && exit /b
for /f "tokens=2 delims=_~" %%# in ('echo %~1') do set pack=%%#
if exist "!_workdir!\temp\%pack%.ESD" exit /b
echo DIR-^>ESD: %pack%
rmdir /s /q "!UUP!\%~1\$dpx$.tmp" %_Nul3%
"!_wimlib!" capture "!UUP!\%~1" "temp\%pack%.ESD" --compress=%_level% --check --no-acls --norpfix "%pack%" "%pack%" %_Const%
exit /b

:uups_cab
echo %~1| find /i "RetailDemo" %_Nul1% && exit /b
echo %~1| find /i "Holographic-Desktop-FOD" %_Nul1% && exit /b
echo %~1| find /i "Windows10.0-KB" %_Nul1% && exit /b
set pack=%~n1
if exist "!_workdir!\temp\%pack%.ESD" exit /b
echo CAB-^>ESD: %pack%
mkdir temp\%pack%
expand.exe -f:* "!UUP!\%pack%.cab" temp\%pack%\ %_Const%
"!_wimlib!" capture "temp\%pack%" "temp\%pack%.ESD" --compress=%_level% --check --no-acls --norpfix "%pack%" "%pack%" %_Const%
rmdir /s /q temp\%pack%
exit /b

:uups_esd
for /f "usebackq  delims=" %%# in (`find /n /v "" temp\uups_esd.txt ^| find "[%1]"`) do set uups_esd=%%#
if %1 geq 1 set uups_esd=%uups_esd:~3%
if %1 geq 10 set uups_esd=%uups_esd:~1%
if %1 geq 100 set uups_esd=%uups_esd:~1%
set "uups_esd%1=%uups_esd%"
bin\wimlib-imagex info "!UUP!\%uups_esd%" 3 >bin\info.txt 2>&1
for /f "tokens=1* delims=: " %%A in ('findstr /b "Name" bin\info.txt') do set "name=%%B"
for /f "tokens=3 delims=: " %%# in ('findstr /b "Edition" bin\info.txt') do set "edition%1=%%#"
for /f "tokens=3 delims=: " %%# in ('findstr /i "Default" bin\info.txt') do set "langid%1=%%#"
for /f "tokens=2 delims=: " %%# in ('findstr /i "Architecture" bin\info.txt') do set "arch%1=%%#"
if /i !arch%1!==x86_64 set "arch%1=x64"
set "name%1=!name! (!arch%1! / !langid%1!)"
del /f /q bin\info.txt %_Nul3%
exit /b

:uups_backup
echo.
echo %line%
echo Backing up Reference ESDs . . .
echo %line%
echo.
if %EXPRESS% equ 1 (
mkdir "!_workdir!\CanonicalUUP" %_Nul3%
move /y "!_workdir!\temp\*.ESD" "!_workdir!\CanonicalUUP\" %_Nul3%
for /L %%# in (1, 1, %uups_esd_num%) do (copy /y "!UUP!\!uups_esd%%#!" "!_workdir!\CanonicalUUP\" %_Nul3%)
) else (
mkdir "!UUP!\Original" %_Nul3%
move /y "!_workdir!\temp\*.ESD" "!UUP!\" %_Nul3%
for /f %%# in ('dir /b "!UUP!\*.CAB"') do (echo %%#| find /i "Windows10.0-KB" %_Nul1% || move /y "!UUP!\%%#" "!UUP!\Original\")
)
exit /b

:uups_du
set isoupdate=
for /f "delims=" %%# in ('dir /b /a:-d "!UUP!\*Windows10*KB*.cab"') do (
	del /f /q temp\update.mum %_Const%
	expand.exe -f:update.mum "!UUP!\%%#" .\temp %_Const%
	if not exist "temp\update.mum" set isoupdate=!isoupdate! "%%#"
)
if defined isoupdate (for %%# in (!isoupdate!) do (expand.exe -r -f:* "!UUP!\%%~#" "ISOFOLDER\sources" %_Nul1%))
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
set "target=%~1"
) else (
set dvd=1
set "target=!_workdir!\ISOFOLDER"
)
echo.
echo %line%
if %dvd% equ 1 (
for /f "tokens=3 delims=: " %%# in ('bin\wimlib-imagex info "!target!\sources\install.wim" ^| findstr /c:"Image Count"') do set imgcount=%%#
echo Updating install.wim / !imgcount! image^(s^) . . .
)
if %wim% equ 1 (
for /f "tokens=3 delims=: " %%# in ('bin\wimlib-imagex info "!target!" ^| findstr /c:"Image Count"') do set imgcount=%%#
echo Updating %~nx1 / !imgcount! image^(s^) . . .
)
echo %line%
echo.
call :extract
if %wim% equ 1 (
call :mount "!target!"
)
if %dvd% equ 1 (
call :mount "!target!\sources\install.wim"
)
popd
if exist "%mountdir%" rmdir /s /q "%mountdir%"
echo.
if %wim% equ 1 exit /b

for /L %%# in (1,1,%imgcount%) do (
  for /f "tokens=3 delims=<>" %%A in ('bin\imagex /info "!target!\sources\install.wim" %%# ^| find /i "<HIGHPART>"') do call set "HIGHPART=%%A"
  for /f "tokens=3 delims=<>" %%A in ('bin\imagex /info "!target!\sources\install.wim" %%# ^| find /i "<LOWPART>"') do call set "LOWPART=%%A"
  bin\wimlib-imagex info "!target!\sources\install.wim" %%# --image-property CREATIONTIME/HIGHPART=!HIGHPART! --image-property CREATIONTIME/LOWPART=!LOWPART! %_Nul1%
)
if defined isoupdate (for %%# in (!isoupdate!) do (expand.exe -r -f:* "!UUP!\%%~#" "!target!\sources" %_Nul1%))
bin\7z.exe l "!target!\sources\setuphost.exe" >.\bin\version.txt 2>&1
for /f "tokens=4-7 delims=.() " %%i in ('"findstr /i /b "FileVersion" .\bin\version.txt" %_Nul6%') do (set version=%%i.%%j&set branch=%%k&set labeldate=%%l)
del /f /q .\bin\version.txt %_Nul3%
if /i not "%branch%"=="WinBuild" (set _label=%version%.%labeldate%.%branch%_CLIENT)
if not defined isover (call :setlabel&exit /b)
if %isover:.=% gtr %version:.=% (set _label=%isover%.%isodate%.%isobranch%_CLIENT)
call :setlabel
exit /b

:extract
if not exist "!_cabdir!" mkdir "!_cabdir!"
set _cab=0
pushd "!UUP!"
for /f "delims=" %%# in ('dir /b "*Windows10*KB*.cab"') do (call set /a _cab+=1)
set count=0&set isoupdate=
for /f "delims=" %%# in ('dir /b "*Windows10*KB*.cab"') do (set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :cab2)
goto :eof

:cab2
if defined %package% goto :eof
if exist "!dest!" rmdir /s /q "!dest!"
mkdir "!dest!"
expand.exe -f:update.mum "%package%" "!dest!" %_Const%
if not exist "!dest!\update.mum" (set isoupdate=!isoupdate! "!package!"&goto :eof)
expand.exe -f:*.psf.cix.xml "%package%" "!dest!" %_Const%
if exist "!dest!\*.psf.cix.xml" goto :eof
set /a count+=1
echo %count%/%_cab%: %package%
expand.exe -f:* "%package%" "!dest!" %_Const% || (set directcab=!directcab! "!package!"&goto :eof)
set %package%=1
if not exist "!dest!\*cablist.ini" goto :eof
expand.exe -f:* "!dest!\*.cab" "!dest!" %_Const% || (set directcab=!directcab! "!package!"&goto :eof)
del /f /q "!dest!\*cablist.ini" %_Nul3%
del /f /q "!dest!\*.cab" %_Nul3%
goto :eof

:update
set "mumtarget=%mountdir%"
set dismtarget=/image:"%mountdir%"
set servicingstack=
set cumulative=
set netroll=
set ldr=
for /f "delims=" %%# in ('dir /b "*Windows10*KB*.cab"') do (set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :mum)
if not defined ldr if not defined cumulative if not defined servicingstack goto :eof
if defined servicingstack (
!_dism! %dismtarget% /Add-Package %servicingstack% %_Supp%
if not defined ldr if not defined cumulative call :cleanup
)
if not defined ldr if not defined cumulative goto :eof
if defined ldr !_dism! %dismtarget% /Add-Package %ldr% %_Supp%
if defined cumulative !_dism! %dismtarget% /Add-Package %cumulative% %_Supp%
if %errorlevel% equ 1726 !_dism! %dismtarget% /Get-Packages %_Const%
call :cleanup
goto :eof

:mum
if not exist "!dest!\update.mum" goto :eof
if exist "!dest!\*.psf.cix.xml" goto :eof
if %build% geq 17763 if not exist "%mumtarget%\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" (
findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (findstr /i /m "Microsoft-Windows-NetFx" "!dest!\*.mum" %_Nul3% && (if exist "!dest!\*_*10.0.*.manifest" if not exist "!dest!\*_netfx4clientcorecomp*.manifest" (set "netroll=!netroll! /packagepath:!dest!\update.mum")))
findstr /i /m "Package_for_OasisAsset" "!dest!\update.mum" %_Nul3% && (if not exist "%mumtarget%\Windows\servicing\packages\*OasisAssets-Package*.mum" goto :eof)
)
if exist "!dest!\*_microsoft-windows-servicingstack_*.manifest" (set "servicingstack=!servicingstack! /packagepath:!dest!\update.mum"&goto :eof)
if exist "%mumtarget%\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" (
findstr /i /m "WinPE" "!dest!\update.mum" %_Nul3% || (findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (goto :eof))
findstr /i /m "WinPE-NetFx-Package" "!dest!\update.mum" %_Nul3% && (findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (goto :eof))
)
if exist "!dest!\*_adobe-flash-for-windows_*.manifest" (
if not exist "%mumtarget%\Windows\servicing\packages\Adobe-Flash-For-Windows-Package*.mum" if not exist "%mumtarget%\Windows\servicing\packages\Microsoft-Windows-Client-Desktop-Required-Package*.mum" goto :eof
if %build% geq 16299 (
  set flash=0
  for /f "tokens=3 delims=<= " %%# in ('findstr /i "Edition" "!dest!\update.mum" %_Nul6%') do if exist "%mumtarget%\Windows\servicing\packages\%%~#*.mum" set flash=1
  if "!flash!"=="0" goto :eof
  )
)
for %%# in (%directcab%) do (
if /i "!package!"=="%%~#" (
  set ldr=!ldr! /packagepath:"!package!"
  goto :eof
  )
)
findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% && (set "cumulative=!cumulative! /packagepath:!dest!\update.mum"&goto :eof)
set "ldr=!ldr! /packagepath:!dest!\update.mum"
goto :eof

:mount
if exist "%mountdir%" rmdir /s /q "%mountdir%"
if not exist "%mountdir%" mkdir "%mountdir%"
for /L %%# in (1,1,%imgcount%) do (
!_dism! /Mount-Wim /Wimfile:%1 /Index:%%# /MountDir:"%mountdir%" %_Supp%
if !errorlevel! neq 0 (
!_dism! /Unmount-Wim /MountDir:"%mountdir%" /Discard %_Supp%
!_dism! /Cleanup-Wim %_Nul3%
goto :eof
)
call :update
if %NetFx3% equ 1 if %dvd% equ 1 call :enablenet35
if %%# equ 1 if %dvd% equ 1 (
if /i %arch%==x86 (set efifile=bootia32.efi) else if /i %arch%==x64 (set efifile=bootx64.efi) else (set efifile=boota64.efi)
xcopy /cidry "%mountdir%\Windows\Boot\DVD\EFI\en-US\efisys.bin" "!target!\efi\microsoft\boot\" %_Nul1%
xcopy /cidry "%mountdir%\Windows\Boot\DVD\EFI\en-US\efisys_noprompt.bin" "!target!\efi\microsoft\boot\" %_Nul1%
xcopy /cidry "%mountdir%\Windows\Boot\EFI\memtest.efi" "!target!\efi\microsoft\boot\" %_Nul1%
xcopy /cidry "%mountdir%\Windows\Boot\EFI\bootmgfw.efi" "!target!\efi\boot\!efifile!" %_Nul1%
xcopy /cidry "%mountdir%\Windows\Boot\EFI\bootmgr.efi" "!target!\" %_Nul1%
xcopy /cidry "%mountdir%\Windows\Boot\PCAT\bootmgr" "!target!\" %_Nul1%
xcopy /cidry "%mountdir%\Windows\Boot\PCAT\memtest.exe" "!target!\boot\" %_Nul1%
)
if %%# equ 1 if %dvd% equ 1 if not exist "%mountdir%\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" if exist "%mountdir%\Windows\servicing\Packages\Package_for_RollupFix*.mum" (
for /f "tokens=6,7 delims=_." %%i in ('dir /b /a:-d /od "%mountdir%\Windows\WinSxS\Manifests\%_ss%_microsoft-windows-coreos-revision*.manifest"') do set "isover=%%i.%%j"
copy /y "%mountdir%\Windows\servicing\Packages\Package_for_RollupFix*.mum" %windir%\temp\ %_Nul1%
for /f %%i in ('dir /b /a:-d /od %windir%\temp\Package_for_RollupFix*.mum') do set "mumfile=%windir%\temp\%%i"
for /f "tokens=2 delims==" %%i in ('wmic datafile where "name='!mumfile:\=\\!'" get LastModified /value') do set "mumdate=%%i"
del /f /q %windir%\temp\*.mum
set "isodate=!mumdate:~2,2!!mumdate:~4,2!!mumdate:~6,2!-!mumdate:~8,4!"
set "isotime=!mumdate:~4,2!/!mumdate:~6,2!/!mumdate:~0,4!,!mumdate:~8,2!:!mumdate:~10,2!:!mumdate:~12,2!"
set "isokey=Microsoft\Windows NT\CurrentVersion\Update\TargetingInfo\Installed"
for /f %%i in ('""!_workdir!\bin\offlinereg.exe" "%mountdir%\Windows\system32\config\SOFTWARE" "!isokey!" enumkeys %_Nul6% ^| find /i "Client.OS""') do if not errorlevel 1 (
  for /f "tokens=3 delims==:" %%A in ('""!_workdir!\bin\offlinereg.exe" "%mountdir%\Windows\system32\config\SOFTWARE" "!isokey!\%%i" getvalue Branch %_Nul6%"') do set "isobranch=%%~A"
  )
)
!_dism! /Unmount-Wim /MountDir:"%mountdir%" /Commit %_Supp%
)
goto :eof

:cleanup
if exist "%mumtarget%\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" (
set ksub=SOFTWIM
reg load HKLM\!ksub! "%mumtarget%\Windows\System32\Config\SOFTWARE" %_Nul1%
reg add HKLM\!ksub!\Microsoft\Windows\CurrentVersion\SideBySide\Configuration /v SupersededActions /t REG_DWORD /d 1 /f %_Nul1%
reg unload HKLM\!ksub! %_Nul1%
!_dism! %dismtarget% /Cleanup-Image /StartComponentCleanup %_Supp%
if !errorlevel! equ 1726 !_dism! %dismtarget% /Get-Packages %_Const%
!_dism! %dismtarget% /Cleanup-Image /StartComponentCleanup /ResetBase %_Const%
if !errorlevel! equ 1726 !_dism! %dismtarget% /Get-Packages %_Const%
call :cleanupmanual
goto :eof
)
if exist "%mumtarget%\Windows\WinSxS\pending.xml" call :cleanupmanual&goto :eof
if %ResetBase% equ 1 (
set ksub=SOFTWIM
reg load HKLM\!ksub! "%mumtarget%\Windows\System32\Config\SOFTWARE" %_Nul1%
reg add HKLM\!ksub!\Microsoft\Windows\CurrentVersion\SideBySide\Configuration /v DisableResetbase /t REG_DWORD /d 0 /f %_Nul1%
reg add HKLM\!ksub!\Microsoft\Windows\CurrentVersion\SideBySide\Configuration /v SupersededActions /t REG_DWORD /d 1 /f %_Nul1%
reg unload HKLM\!ksub! %_Nul1%
)
!_dism! %dismtarget% /Cleanup-Image /StartComponentCleanup %_Supp%
if !errorlevel! equ 1726 !_dism! %dismtarget% /Get-Packages %_Const%
if %ResetBase% equ 1 (
!_dism! %dismtarget% /Cleanup-Image /StartComponentCleanup /ResetBase %_Const%
if !errorlevel! equ 1726 !_dism! %dismtarget% /Get-Packages %_Const%
)
call :cleanupmanual
goto :eof

:cleanupmanual
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
for /f "delims=" %%# in ('dir /b /ad "%mumtarget%\Windows\CbsTemp\" %_Nul6%') do rmdir /s /q "%mumtarget%\Windows\CbsTemp\%%#" %_Nul3%
del /s /f /q "%mumtarget%\Windows\CbsTemp\*" %_Nul3%
goto :eof

:enablenet35
if exist "%mumtarget%\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" goto :eof
if exist "%mumtarget%\Windows\Microsoft.NET\Framework\v2.0.50727\ngen.exe" goto :eof
if not exist "!target!\sources\sxs\*netfx3*.cab" goto :eof
set "net35source=!target!\sources\sxs"
!_dism! %dismtarget% /Enable-Feature /FeatureName:NetFx3 /All /LimitAccess /Source:"!net35source!" %_Supp%
if not defined netroll if not defined cumulative call :cleanup&goto :eof
!_dism! %dismtarget% /Add-Package %netroll% %cumulative% %_Supp%
call :cleanup
goto :eof

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
if %wim2esd% equ 0 (call create_virtual_editions.cmd autowim) else (call create_virtual_editions.cmd autoesd)
if /i "%_Exit%"=="rem." set _Debug=1
if %_Debug% neq 0 @echo on
title UUP -^> ISO
echo.
goto :QUIT

:V_Manu
if %wim2esd% equ 0 (start /i "" !_ComSpec! /c "create_virtual_editions.cmd manuwim") else (start /i "" !_ComSpec! /c "create_virtual_editions.cmd manuesd")
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
if %RefESD% equ 1 call :uups_backup
ren ISOFOLDER %DVDISO%
echo.&echo Errors were reported during ISO creation.&echo.&goto :QUIT

:QUIT
if exist ISOFOLDER\ rmdir /s /q ISOFOLDER\
if exist bin\temp\ rmdir /s /q bin\temp\
if exist temp\ rmdir /s /q temp\
popd
if %AddUpdates% equ 1 if exist "!_cabdir!\*" (
echo.
echo %line%
echo Removing temporary files . . .
echo %line%
echo.
rmdir /s /q "!_cabdir!"
)
if %_Debug% equ 0 (echo Press 0 to exit.) else (exit /b)
choice /c 0 /n
if errorlevel 1 (exit /b) else (rem.)

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
          CreateObject("Shell.Application").ShellExecute "cmd", "/c " & chr(34) & chr(34) & strArg("File") & chr(34) & " " & strLine & chr(34), "", "runas", 1
       </script>
   </job>
</package>