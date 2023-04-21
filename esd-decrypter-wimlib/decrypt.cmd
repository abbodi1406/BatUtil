<!-- : Begin batch script
@setlocal DisableDelayedExpansion
@set uivr=v63
@echo off
:: ### Auto processing option ###
:: 1 - create ISO with install.wim
:: 2 - create ISO with install.esd
:: 3 - create install.wim only
:: 4 - create install.esd only
set AutoStart=0

:: Change to 1 to get ISO name similar to ESD name (ESD name must be the original, with or without sha1 hash suffix)
set ISOnameESD=0

:: Change to 1 for not creating ISO file, result distribution folder will be kept
set SkipISO=0

:: Enable menu to choose from multiple editions ESDs
set MultiChoice=1

:: Check and unify different winre.wim in multiple editions ESDs
set CheckWinre=1

:: change to 1 to enable debug mode
set _Debug=0

:: script:     abbodi1406
:: initial:    @rgadguard
:: esddecrypt: qad, whatever127
:: wimlib:     synchronicity
:: rawcopy:    whatever127
:: offlinereg: erwan.l
:: aio efisys: cdob
:: cryptokey:  MrMagic, Chris123NT, mohitbajaj143, Superwzt, timster

:: #################################################################

set "_Null=1>nul 2>nul"

set "param=%~f0"
cmd /v:on /c echo(^^!param^^!| findstr /R "[| ` ~ ! @ %% \^ & ( ) \[ \] { } + = ; ' , |]*^"
if %errorlevel% EQU 0 (
echo.
echo ==== ERROR ====
echo Disallowed special characters detected in file path name.
echo Make sure the path does not contain the following special characters
echo ^` ^~ ^! ^@ %% ^^ ^& ^( ^) [ ] { } ^+ ^= ^; ^' ^,
echo.
echo Press any key to exit.
pause >nul
goto :eof
)

set ENCRYPTEDESD=
set _elev=
set "_args="
set "_args=%~1"
if not defined _args goto :NoProgArgs
if "%~1"=="" set "_args="&goto :NoProgArgs
if "%~1"=="-elevated" set _elev=1&set "_args="&goto :NoProgArgs
if "%~2"=="-elevated" set _elev=1
if /i "%~x1"==".esd" set "ENCRYPTEDESD=%~1"&set "ENCRYPTEDESDN=%~nx1"

:NoProgArgs
set "SysPath=%SystemRoot%\System32"
if exist "%SystemRoot%\Sysnative\reg.exe" (set "SysPath=%SystemRoot%\Sysnative")
set "xOS=%PROCESSOR_ARCHITECTURE%"
if /i %PROCESSOR_ARCHITECTURE%==x86 (if defined PROCESSOR_ARCHITEW6432 (
  set "xOS=%PROCESSOR_ARCHITEW6432%"
  )
)
set "xDS=bin\bin64;bin"
if /i not %xOS%==amd64 set "xDS=bin"
set "Path=%xDS%;%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
set "_err===== ERROR ===="
for /f "tokens=6 delims=[]. " %%# in ('ver') do set winbuild=%%#
set _cwmi=0
for %%# in (wmic.exe) do @if not "%%~$PATH:#"=="" (
wmic path Win32_ComputerSystem get CreationClassName /value 2>nul | find /i "ComputerSystem" 1>nul && set _cwmi=1
)
set _pwsh=1
for %%# in (powershell.exe) do @if "%%~$PATH:#"=="" set _pwsh=0
if %_cwmi% equ 0 if %_pwsh% EQU 0 goto :E_PS

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
  %_Null% powershell -nop -c "start cmd.exe -Arg '/c \"!_PSarg!\"' -verb runas" && (
    exit /b
    ) || (
    goto :E_Admin
  )
)

:Passed
set "_log=%~dpn0"
set "_work=%~dp0"
set "_work=%_work:~0,-1%"
for /f "skip=2 tokens=2*" %%a in ('reg.exe query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop') do call set "_dsk=%%b"
if exist "%PUBLIC%\Desktop\desktop.ini" set "_dsk=%PUBLIC%\Desktop"
setlocal EnableDelayedExpansion

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
title ESD -^> ISO %uivr%
pushd "!_work!"
set _file=(7z.dll,7z.exe,bcdedit.exe,bfi.exe,rawcopy.exe,cdimage.exe,esddecrypt.exe,imagex.exe,libwim-15.dll,offlinereg.exe,offreg.dll,wimlib-imagex.exe,wim-update.txt)
for %%# in %_file% do (
if not exist ".\bin\%%#" (set _bin=%%#&goto :E_Bin)
)
set Backup=OFF
set ERRORTEMP=
set ENCRYPTED=0
set MULTI=0
set PREPARED=0
set VOL=0
set UnifyWinre=0
set SINGLE=0
set newkeys=0
set "_ram={7619dcc8-fafe-11d9-b411-000476eba25f}"
set "line============================================================="
set "lin2=%line%================"
set _initial=0
set _configured=0
if not exist "DecryptConfig.ini" goto :proceed
findstr /i \[decrypt-ESD\] DecryptConfig.ini %_Nul1% || goto :proceed
for %%# in (
AutoStart
ISOnameESD
SkipISO
MultiChoice
CheckWinre
) do (
call :ReadINI %%#
)
goto :proceed

:ReadINI
findstr /b /i %1 DecryptConfig.ini %_Nul1% && for /f "tokens=2 delims==" %%# in ('findstr /b /i %1 DecryptConfig.ini') do set "%1=%%#"
goto :eof

:proceed
if %_Debug% neq 0 if %AutoStart% equ 0 set AutoStart=2
if defined ENCRYPTEDESD goto :check
set _esd=0
if exist "*.esd" (for /f "delims=" %%# in ('dir /b /a:-d "*.esd"') do (call set /a _esd+=1))
if %_esd% equ 0 goto :prompt1
if exist "*x64*.esd" if exist "*x86*.esd" if %_esd% equ 2 goto :dCheck
if %_esd% gtr 1 goto :prompt2
for /f "delims=" %%# in ('dir /b /a:-d "*.esd"') do (set "ENCRYPTEDESD=%%#"&set "ENCRYPTEDESDN=%%#"&goto :check)

:prompt1
if %_Debug% neq 0 exit /b
setlocal DisableDelayedExpansion
@cls
set ENCRYPTEDESD=
echo %line%
echo Enter / Paste the complete path to the ESD file
echo %line%
echo.
set /p ENCRYPTEDESD=
if not defined ENCRYPTEDESD (set _Debug=1&goto :QUIT)
set "ENCRYPTEDESD=%ENCRYPTEDESD:"=%"
if not exist "%ENCRYPTEDESD%" (
echo.
echo %_err%
echo Specified path is not a valid ESD file
echo.
%_Contn%&%_Pause%
goto :prompt1
)
for %%# in ("%ENCRYPTEDESD%") do set "ENCRYPTEDESDN=%%~nx#"
setlocal EnableDelayedExpansion
goto :check

:prompt2
if %_Debug% neq 0 exit /b
@cls
set ENCRYPTEDESD=
echo %line%
echo Found more than one ESD file in the current directory
echo Enter the name of the desired file to process
echo You may use "Tab" button to ease the selection
echo %line%
echo.
set /p ENCRYPTEDESD=
if not defined ENCRYPTEDESD (set _Debug=1&goto :QUIT)
set "ENCRYPTEDESD=%ENCRYPTEDESD:"=%"
set "ENCRYPTEDESDN=%ENCRYPTEDESD%"
goto :check

:check
color 1F
set ENCRYPTED=0
if /i "%ENCRYPTEDESDN%"=="install.esd" (ren "!ENCRYPTEDESD!" %ENCRYPTEDESDN%.orig&set "ENCRYPTEDESD=!ENCRYPTEDESD!.orig")
wimlib-imagex.exe info "!ENCRYPTEDESD!" 4 %_Nul3%
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% equ 18 goto :E_ESD
if %ERRORTEMP% equ 74 set ENCRYPTED=1&goto :PRE_INFO
if %ERRORTEMP% neq 0 goto :E_File

:PRE_INFO
set _nnn=DISPLAYNAME
set _SrvESD=0
imagex /info "!ENCRYPTEDESD!">bin\infoall.txt 2>&1
find /i "Professional</EDITIONID>" bin\infoall.txt %_Nul1% && (set aedtn=1) || (set aedtn=0)
find /i "ProfessionalN</EDITIONID>" bin\infoall.txt %_Nul1% && (set nedtn=1) || (set nedtn=0)
find /i "CoreSingleLanguage</EDITIONID>" bin\infoall.txt %_Nul1% && (set sedtn=1) || (set sedtn=0)
find /i "CoreCountrySpecific</EDITIONID>" bin\infoall.txt %_Nul1% && (set cedtn=1) || (set cedtn=0)
findstr /i "<EDITIONID>Server" bin\infoall.txt %_Nul2% | findstr /i /v ServerRdsh %_Nul1% && (set _SrvESD=1)
imagex /info "!ENCRYPTEDESD!" 4 >bin\info.txt 2>&1
for /f "tokens=3 delims=<>" %%# in ('find /i "<MAJOR>" bin\info.txt') do set ver1=%%#
for /f "tokens=3 delims=<>" %%# in ('find /i "<MINOR>" bin\info.txt') do set ver2=%%#
for /f "tokens=3 delims=<>" %%# in ('find /i "<BUILD>" bin\info.txt') do set _build=%%#
for /f "tokens=3 delims=<>" %%# in ('find /i "<DEFAULT>" bin\info.txt') do set langid=%%#
for /f "tokens=3 delims=<>" %%# in ('find /i "<EDITIONID>" bin\info.txt') do set editionid=%%#
for /f "tokens=3 delims=<>" %%# in ('find /i "<ARCH>" bin\info.txt') do (if %%# equ 0 (set arch=x86) else if %%# equ 9 (set arch=x64) else (set arch=arm64))
for /f "tokens=3 delims=: " %%# in ('findstr /i /b /c:"Image Count" bin\infoall.txt') do (if %%# geq 5 set MULTI=%%#)
if %_build% leq 9600 goto :E_W81
set /a _fixSV=%_build%+1
for %%# in (ru-ru,zh-cn,zh-tw,zh-hk) do if /i %langid%==%%# set _nnn=NAME
find /i "<DISPLAYNAME>" bin\info.txt %_Nul1% && (
for /f "tokens=3 delims=<>" %%# in ('find /i "<%_nnn%>" bin\info.txt') do set "_os=%%#"
) || (
for /f "tokens=3 delims=<>" %%# in ('find /i "<NAME>" bin\info.txt') do set "_os=%%#"
)
if %MULTI% neq 0 for /L %%A in (4,1,%MULTI%) do (
imagex /info "!ENCRYPTEDESD!" %%A >bin\info%%A.txt 2>&1
)
if %MULTI% neq 0 for /L %%A in (4,1,%MULTI%) do (
find /i "<DISPLAYNAME>" bin\info%%A.txt %_Nul1% && (
for /f "tokens=3 delims=<>" %%# in ('find /i "<%_nnn%>" bin\info%%A.txt') do set "_os%%A=%%#"
) || (
for /f "tokens=3 delims=<>" %%# in ('find /i "<NAME>" bin\info%%A.txt') do set "_os%%A=%%#"
)
)
del /f /q bin\info*.txt
set images=4
if %MULTI% neq 0 (set /a images=%MULTI%-3) else (goto :MAINMENU)
if %MultiChoice% neq 1 goto :MAINMENU

:MULTIMENU
if %AutoStart% neq 0 goto :MAINMENU
@cls
echo %line%
echo                ESD file contains %images% editions:
echo %line%
for /L %%# in (4,1,%MULTI%) do (
echo. !_os%%#!
)
echo.
echo %line%
echo. Options:
echo. 1 - Continue including all editions
echo. 2 - Include one edition
if %MULTI% gtr 5 echo. 3 - Include consecutive range of editions
if %MULTI% gtr 5 echo. 4 - Include randomly selected editions
echo %line%
echo.
choice /c 12340 /n /m "Choose a menu option, or press 0 to exit: "
if errorlevel 5 (set _Debug=1&goto :QUIT)
if errorlevel 4 if %MULTI% gtr 5 goto :RANDOMMENU
if errorlevel 3 if %MULTI% gtr 5 goto :RANGEMENU
if errorlevel 2 goto :SINGLEMENU
if errorlevel 1 goto :MAINMENU
goto :MULTIMENU

:SINGLEMENU
@cls
set _single=
echo %line%
for /L %%# in (4,1,%MULTI%) do (
call set /a osnum=%%#-3
echo. !osnum!: !_os%%#!
)
echo %line%
echo Enter edition number to include, or zero '0' to return
echo %line%
set /p _single= ^> Enter your option and press "Enter": 
if not defined _single (set _Debug=1&goto :QUIT)
if "%_single%"=="0" set _single=&goto :MULTIMENU
if %_single% gtr %images% echo.&echo %_single% is higher than available editions&%_Contn%&%_Pause%&goto :SINGLEMENU
set /a _single+=3&goto :MAINMENU

:RANGEMENU
@cls
set _range=
set _start=
set _end=
echo %line%
for /L %%# in (4,1,%MULTI%) do (
call set /a osnum=%%#-3
echo. !osnum!: !_os%%#!
)
echo %line%
echo Enter consecutive range for editions to include: Start-End
echo examples: 2-4 or 1-3 or 3-9
echo Enter zero '0' to return
echo %line%
set /p _range= ^> Enter your option and press "Enter": 
if not defined _range (set _Debug=1&goto :QUIT)
if "%_range%"=="0" set _start=&goto :MULTIMENU
for /f "tokens=1,2 delims=-" %%A in ('echo %_range%') do set _start=%%A&set _end=%%B
if %_end% gtr %images% echo.&echo Range End is higher than available editions&%_Contn%&%_Pause%&goto :RANGEMENU
if %_start% gtr %_end% echo.&echo Range Start is higher than Range End&%_Contn%&%_Pause%&goto :RANGEMENU
if %_start% equ %_end% echo.&echo Range Start and End are equal&%_Contn%&%_Pause%&goto :RANGEMENU
if %_start% gtr %images% echo.&echo Range Start is higher than available editions&%_Contn%&%_Pause%&goto :RANGEMENU
set /a _start+=3&set /a _end+=3&goto :MAINMENU

:RANDOMMENU
@cls
set _count=
set _index=
echo %line%
for /L %%# in (4,1,%MULTI%) do (
call set /a osnum=%%#-3
echo. !osnum!: !_os%%#!
)
echo %line%
echo Enter editions numbers to include separated with spaces
echo examples: 1 3 4 or 5 1 or 4 2 9
echo Enter zero '0' to return
echo %line%
set /p _index= ^> Enter your option and press "Enter": 
if not defined _index (set _Debug=1&goto :QUIT)
if "%_index%"=="0" set _index=&goto :MULTIMENU
for %%# in (%_index%) do call :setindex %%#
if %_count% equ 1 echo.&echo Only one edition number is entered&%_Contn%&%_Pause%&goto :RANDOMMENU
for /L %%# in (1,1,%_count%) do (
if !_index%%#! gtr %images% echo.&echo !_index%%#! is higher than available editions&%_Contn%&%_Pause%&goto :RANDOMMENU
)
for /L %%# in (1,1,%_count%) do (
set /a _index%%#+=3
)
goto :MAINMENU

:setindex
set /a _count+=1
set _index%_count%=%1
goto :eof

:MAINMENU
if %AutoStart% equ 1 (set WIMFILE=install.wim&goto :ESDISO)
if %AutoStart% equ 2 (set WIMFILE=install.esd&goto :ESDISO)
if %AutoStart% equ 3 (set WIMFILE=install.wim&goto :ESDWIM)
if %AutoStart% equ 4 (set WIMFILE=install.esd&goto :ESDWIM)
@cls
echo %line%
echo.       1 - Create ISO with install.wim
echo.       2 - Create ISO with install.esd
echo.       3 - Create install.wim
echo.       4 - Create install.esd
if %ENCRYPTED% equ 1 (
echo.       5 - Decrypt ESD file only
echo ____________________________________________________________
echo Encrypted ESD Backup is %Backup%. Press 9 to toggle
) else (
echo.       5 - ESD file info
echo ____________________________________________________________
echo ESD is not encrypted.
)
echo %line%
echo.
choice /c 1234590 /n /m "Choose a menu option, or press 0 to exit: "
if errorlevel 7 (set _Debug=1&goto :QUIT)
if errorlevel 6 (if /i %Backup%==OFF (set Backup=ON) else (set Backup=OFF))&goto :MAINMENU
if errorlevel 5 (if %ENCRYPTED%==1 (goto :DDECRYPT) else (goto :INFO))
if errorlevel 4 (set WIMFILE=install.esd&goto :ESDWIM)
if errorlevel 3 (set WIMFILE=install.wim&goto :ESDWIM)
if errorlevel 2 (set WIMFILE=install.esd&goto :ESDISO)
if errorlevel 1 (set WIMFILE=install.wim&goto :ESDISO)
goto :MAINMENU

:ESDISO
@cls
echo.
echo %line%
echo Running ESD -^> ISO %uivr%
echo %line%
echo.
set _initial=1
for %%# in (
AutoStart
ISOnameESD
SkipISO
) do (
if !%%#! neq 0 set _configured=1
)
for %%# in (
MultiChoice
CheckWinre
) do (
if !%%#! neq 1 set _configured=1
)
if %_configured% equ 1 (
echo.
echo %line%
echo Non-default Options . . .
echo %line%
echo.
if %AutoStart% neq 0 echo AutoStart %AutoStart%
if %ISOnameESD% neq 0 echo ISOnameESD 1
if %SkipISO% neq 0 echo SkipISO 1
if %MultiChoice% neq 1 echo MultiChoice 0
if %CheckWinre% neq 1 echo CheckWinre 0
)
if %ENCRYPTED% equ 1 call :DECRYPT
if %PREPARED% equ 0 call :PREPARE
echo.
echo %line%
echo Creating Setup Media Layout . . .
echo %line%
echo.
if exist ISOFOLDER\ rmdir /s /q ISOFOLDER\
mkdir ISOFOLDER
wimlib-imagex.exe apply "!ENCRYPTEDESD!" 1 ISOFOLDER\ --no-acls --no-attributes %_Null%
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_Apply
if exist ISOFOLDER\MediaMeta.xml del /f /q ISOFOLDER\MediaMeta.xml %_Nul3%
:: rmdir /s /q ISOFOLDER\sources\uup\ %_Nul3%
echo.
echo %line%
echo Creating boot.wim . . .
echo %line%
echo.
wimlib-imagex.exe export "!ENCRYPTEDESD!" 2 ISOFOLDER\sources\boot.wim --compress=LZX %_Supp%
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_Export
echo.
wimlib-imagex.exe export "!ENCRYPTEDESD!" 3 ISOFOLDER\sources\boot.wim --boot %_Supp%
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_Export
wimlib-imagex.exe extract ISOFOLDER\sources\boot.wim 2 sources\dism.exe --dest-dir=.\bin\temp --no-acls --no-attributes %_Nul3%
if not exist "bin\temp\dism.exe" (
wimlib-imagex.exe update ISOFOLDER\sources\boot.wim 2 <bin\wim-update.txt %_Null%
)
if exist bin\temp\ rmdir /s /q bin\temp\
set _file=ISOFOLDER\sources\%WIMFILE%
set _rtrn=RetISO
goto :InstallWim
:RetISO
:CREATEISO
if %SkipISO% neq 0 (
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
cdimage.exe -bootdata:2#p0,e,b"ISOFOLDER\boot\etfsboot.com"#pEF,e,b"ISOFOLDER\efi\Microsoft\boot\efisys.bin" -o -m -u2 -udfver102 -t%isotime% -l%DVDLABEL% ISOFOLDER %DVDISO%.ISO %_Supp%
) else (
cdimage.exe -bootdata:1#pEF,e,b"ISOFOLDER\efi\Microsoft\boot\efisys.bin" -o -m -u2 -udfver102 -t%isotime% -l%DVDLABEL% ISOFOLDER %DVDISO%.ISO %_Supp%
)
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_ISO
echo.
goto :QUIT

:ESDWIM
@cls
set /a _rnd=%random%
if %WIMFILE%==install.wim if exist "install.wim" ren install.wim install-bak%_rnd%.wim
echo.
echo %line%
echo Running ESD -^> %WIMFILE% %uivr%
echo %line%
echo.
set _initial=1
for %%# in (
AutoStart
) do (
if !%%#! neq 0 set _configured=1
)
for %%# in (
MultiChoice
CheckWinre
) do (
if !%%#! neq 1 set _configured=1
)
if %_configured% equ 1 (
echo.
echo %line%
echo Non-default Options . . .
echo %line%
echo.
if %AutoStart% neq 0 echo AutoStart %AutoStart%
if %MultiChoice% neq 1 echo MultiChoice 0
if %CheckWinre% neq 1 echo CheckWinre 0
)
if %ENCRYPTED% equ 1 call :DECRYPT
if %PREPARED% equ 0 call :PREPARE
set _file=%WIMFILE%
set _rtrn=RetWIM
goto :InstallWim
:RetWIM
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
set _src=4
if defined _single set _src=%_single%
if defined _start set _src=%_start%&set /a _start+=1
if defined _index set _src=%_index1%
if %WIMFILE%==install.wim set _rrr=%_rrr% --compress=LZX
wimlib-imagex.exe export "!ENCRYPTEDESD!" %_src% %_file% %_rrr% %_Supp%
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_Export
if defined _single (
if %_file%==%WIMFILE% %_Nul3% call :GUID %_file% 2
if %_file%==%WIMFILE% goto :%_rtrn%
for /f "tokens=3 delims=<>" %%# in ('imagex /info %_file% 1 ^| find /i "<EDITIONID>"') do set editionid=%%#
call :SINGLEINFO
%_Nul3% call :GUID %_file% 1
goto :%_rtrn%
)
if defined _start for /L %%# in (%_start%,1,%_end%) do (
echo.&wimlib-imagex.exe export "!ENCRYPTEDESD!" %%# %_file% %_Supp%
)
if defined _index for /L %%# in (2,1,%_count%) do (
echo.&wimlib-imagex.exe export "!ENCRYPTEDESD!" !_index%%#! %_file% %_Supp%
)
if not defined _start if not defined _index if %MULTI% neq 0 for /L %%# in (5,1,%MULTI%) do (
echo.&wimlib-imagex.exe export "!ENCRYPTEDESD!" %%# %_file% %_Supp%
)
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_Export
if %UnifyWinre% equ 1 call :WINRE %_file%
if %_file%==%WIMFILE% (%_Nul3% call :GUID %_file% 2) else (%_Nul3% call :GUID %_file% 1)
goto :%_rtrn%

:INFO
if %PREPARED% equ 0 call :PREPARE
@cls
echo %line%
echo                     ESD Contents Info
echo %line%
echo     Arch: %arch%
echo Language: %langid%
echo  Version: %ver1%.%ver2%.%revver%
if defined branch echo   Branch: %branch%
if %MULTI% equ 0 echo       OS: %_os%
if %MULTI% neq 0 for /L %%# in (4,1,%MULTI%) do (
call set /a osnum=%%#-3
echo     OS !osnum!: !_os%%#!
)
echo.
%_Contn%&%_Pause%
goto :MAINMENU

:PREPARE
if %_initial% equ 0 @cls
echo.
echo %line%
echo Checking ESD Info . . .
echo %line%
set PREPARED=1
if %CheckWinre% equ 1 for /f "tokens=2 delims== " %%# in ('wimlib-imagex.exe dir "!ENCRYPTEDESD!" 4 --path=Windows\System32\Recovery\winre.wim --detailed %_Nul6% ^| findstr /b Hash') do call set "WinreHash=%%#"
if %MULTI% neq 0 for /L %%A in (5,1,%MULTI%) do (
if %CheckWinre% equ 1 for /f "tokens=2 delims== " %%# in ('wimlib-imagex.exe dir "!ENCRYPTEDESD!" %%A --path=Windows\System32\Recovery\winre.wim --detailed %_Nul6% ^| findstr /b Hash') do if /i not "%%#"=="!WinreHash!" (call set UnifyWinre=1)
)
wimlib-imagex.exe extract "!ENCRYPTEDESD!" 1 sources\ei.cfg --dest-dir=.\bin\temp --no-acls --no-attributes %_Nul3%
if exist "bin\temp\ei.cfg" type .\bin\temp\ei.cfg %_Nul2% | find /i "Volume" %_Nul1% && set VOL=1
if %MULTI% equ 0 (set _stm=4) else (set _stm=%MULTI%)
call :setdate

:setlabel
if %_build% geq 16299 (
wimlib-imagex.exe extract "!ENCRYPTEDESD!" 1 sources\setuphost.exe --dest-dir=.\bin\temp --no-acls --no-attributes %_Null%
7z.exe l .\bin\temp\setuphost.exe >.\bin\temp\version.txt 2>&1
) else (
wimlib-imagex.exe extract "!ENCRYPTEDESD!" 3 Windows\System32\ntoskrnl.exe --dest-dir=.\bin\temp --no-acls --no-attributes %_Null%
7z.exe l .\bin\temp\ntoskrnl.exe >.\bin\temp\version.txt 2>&1
)
if %_build% geq 22478 (
wimlib-imagex.exe extract "!ENCRYPTEDESD!" 3 Windows\System32\UpdateAgent.dll --dest-dir=.\bin\temp --no-acls --no-attributes %_Nul3%
if exist "bin\temp\UpdateAgent.dll" 7z.exe l .\bin\temp\UpdateAgent.dll >.\bin\temp\version.txt 2>&1
)
for /f "tokens=4-7 delims=.() " %%i in ('"findstr /i /b "FileVersion" .\bin\temp\version.txt" %_Nul6%') do (set uupver=%%i.%%j&set uupmaj=%%i&set uupmin=%%j&set branch=%%k&set uupdate=%%l)
set revver=%uupver%&set revmaj=%uupmaj%&set revmin=%uupmin%
set "tok=6,7"&set "toe=5,6,7"
if /i %arch%==x86 (set _ss=x86) else if /i %arch%==x64 (set _ss=amd64) else (set _ss=arm64)
wimlib-imagex.exe extract "!ENCRYPTEDESD!" 4 Windows\WinSxS\Manifests\%_ss%_microsoft-windows-coreos-revision*.manifest --dest-dir=.\bin\temp --no-acls --no-attributes %_Nul3%
if exist "bin\temp\*_microsoft-windows-coreos-revision*.manifest" for /f "tokens=%tok% delims=_." %%A in ('dir /b /a:-d /od .\bin\temp\*_microsoft-windows-coreos-revision*.manifest') do set revver=%%A.%%B&set revmaj=%%A&set revmin=%%B
if %_build% geq 15063 (
wimlib-imagex.exe extract "!ENCRYPTEDESD!" 4 Windows\System32\config\SOFTWARE --dest-dir=.\bin\temp --no-acls --no-attributes %_Null%
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
if %revmaj%==18363 (
if /i "%branch:~0,4%"=="19h1" set branch=19h2%branch:~4%
if %uupver:~0,5%==18362 set uupver=18363%uupver:~5%
)
if %revmaj%==19042 (
if /i "%branch:~0,2%"=="vb" set branch=20h2%branch:~2%
if %uupver:~0,5%==19041 set uupver=19042%uupver:~5%
)
if %revmaj%==19043 (
if /i "%branch:~0,2%"=="vb" set branch=21h1%branch:~2%
if %uupver:~0,5%==19041 set uupver=19043%uupver:~5%
)
if %revmaj%==19044 (
if /i "%branch:~0,2%"=="vb" set branch=21h2%branch:~2%
if %uupver:~0,5%==19041 set uupver=19044%uupver:~5%
)
if %revmaj%==19045 (
if /i "%branch:~0,2%"=="vb" set branch=22h2%branch:~2%
if %uupver:~0,5%==19041 set uupver=19045%uupver:~5%
)
if %revmaj%==19046 (
if /i "%branch:~0,2%"=="vb" set branch=23h2%branch:~2%
if %uupver:~0,5%==19041 set uupver=19046%uupver:~5%
)
if %uupmaj%==%_fixSV% if %_build% geq 21382 (
if %uupver:~0,5%==%_build% set uupver=%_fixSV%%uupver:~5%
)
if %uupmin% lss %revmin% (
set uupver=%revver%
set uupmin=%revmin%
if not exist "%SystemRoot%\temp\" mkdir "%SystemRoot%\temp" %_Nul3%
wimlib-imagex.exe extract "!ENCRYPTEDESD!" 4 Windows\servicing\Packages\Package_for_RollupFix*.mum --dest-dir=%SystemRoot%\temp --no-acls --no-attributes %_Nul3%
for /f %%# in ('dir /b /a:-d /od %SystemRoot%\temp\Package_for_RollupFix*.mum') do set "mumfile=%SystemRoot%\temp\%%#"
set "chkfile=!mumfile:\=\\!"
if %_cwmi% equ 1 for /f "tokens=2 delims==" %%# in ('wmic datafile where "name='!chkfile!'" get LastModified /value') do set "mumdate=%%#"
if %_cwmi% equ 0 for /f %%# in ('powershell -nop -c "([WMI]'CIM_DataFile.Name=\"!chkfile!\"').LastModified"') do set "mumdate=%%#"
del /f /q %SystemRoot%\temp\*.mum
set "uupdate=!mumdate:~2,2!!mumdate:~4,2!!mumdate:~6,2!-!mumdate:~8,4!"
)
set _legacy=
set _useold=0
if /i "%branch%"=="WinBuild" set _useold=1
if /i "%branch%"=="GitEnlistment" set _useold=1
if /i "%uupdate%"=="winpbld" set _useold=1
if %_useold% equ 1 (
wimlib-imagex.exe extract "!ENCRYPTEDESD!" 4 Windows\System32\config\SOFTWARE --dest-dir=.\bin\temp --no-acls --no-attributes %_Null%
for /f "tokens=3 delims==:" %%# in ('"offlinereg.exe .\bin\temp\SOFTWARE "Microsoft\Windows NT\CurrentVersion" getvalue BuildLabEx" %_Nul6%') do if not errorlevel 1 (for /f "tokens=1-5 delims=." %%i in ('echo %%~#') do set _legacy=%%i.%%j.%%m.%%l&set branch=%%l)
)
if defined _legacy (set _label=%_legacy%) else (set _label=%uupver%.%uupdate%.%branch%)
rmdir /s /q bin\temp\

set _rfr=refresh
set _rsr=release_svc_%_rfr%
if %revmaj%==22626 (set _label=%revver%.%_time%.ni_%_rsr%&set branch=ni_%_rsr%)
if %revmaj%==22625 (set _label=%revver%.%_time%.ni_%_rsr%&set branch=ni_%_rsr%)
if %revmaj%==22624 (set _label=%revver%.%_time%.ni_%_rsr%&set branch=ni_%_rsr%)
if %revmaj%==22623 (set _label=%revver%.%_time%.ni_%_rsr%&set branch=ni_%_rsr%)
if %revmaj%==22622 (set _label=%revver%.%_time%.ni_%_rsr%&set branch=ni_%_rsr%)
if %revver%==22621.525 (set _label=22621.525.220925-0207.ni_%_rsr%&set branch=ni_%_rsr%&set ISOnameESD=0)
if %revver%==22621.382 (set _label=22621.382.220806-0833.ni_%_rsr%&set branch=ni_%_rsr%&set ISOnameESD=0)
if %revver%==22000.318 (set _label=22000.318.211104-1236.co_%_rsr%&set branch=co_%_rsr%&set ISOnameESD=0)
if %revver%==22000.258 (set _label=22000.258.211007-1642.co_%_rsr%&set branch=co_%_rsr%&set ISOnameESD=0)
if %revver%==22000.194 (set _label=22000.194.210913-1444.co_%_rsr%&set branch=co_%_rsr%&set ISOnameESD=0)
if %revver%==22000.132 (set _label=22000.132.210809-2349.co_%_rsr%&set branch=co_%_rsr%&set ISOnameESD=0)
if %revmaj%==19045 (set _label=%revver%.%_time%.22h2_%_rsr%&set branch=22h2_%_rsr%)
if %revver%==19045.2006 (set _label=19045.2006.220908-0225.22h2_%_rsr%&set branch=22h2_%_rsr%&set ISOnameESD=0)
if %revver%==19045.1826 (set _label=19045.1826.220707-2303.22h2_%_rsr%&set branch=22h2_%_rsr%&set ISOnameESD=0)
if %revmaj%==19044 (set _label=%revver%.%_time%.21h2_%_rsr%&set branch=21h2_%_rsr%)
if %revver%==19044.1706 (set _label=19044.1706.220505-0136.21h2_%_rsr%&set branch=21h2_%_rsr%&set ISOnameESD=0)
if %revver%==19044.1586 (set _label=19044.1586.220303-0721.21h2_%_rsr%&set branch=21h2_%_rsr%&set ISOnameESD=0)
if %revver%==19044.1288 (set _label=19044.1288.211006-0501.21h2_%_rsr%&set branch=21h2_%_rsr%&set ISOnameESD=0)
if %revver%==19044.1165 (set _label=19044.1165.210806-1742.21h2_%_rsr%&set branch=21h2_%_rsr%&set ISOnameESD=0)
if %revmaj%==19043 (set _label=%revver%.%_time%.21h1_%_rsr%&set branch=21h1_%_rsr%)
if %revver%==19043.1706 (set _label=19043.1706.220505-1151.21h1_%_rsr%&set branch=21h1_%_rsr%&set ISOnameESD=0)
if %revver%==19043.1348 (set _label=19043.1348.211103-2252.21h1_%_rsr%&set branch=21h1_%_rsr%&set ISOnameESD=0)
if %revver%==19043.1288 (set _label=19043.1288.211006-0459.21h1_%_rsr%&set branch=21h1_%_rsr%&set ISOnameESD=0)
if %revver%==19043.928 (set _label=19043.928.210409-1212.21h1_%_rsr%&set branch=21h1_%_rsr%&set ISOnameESD=0)
if %revver%==19043.867 (set _label=19043.867.210305-1751.21h1_%_rsr%&set branch=21h1_%_rsr%&set ISOnameESD=0)
if %revmaj%==19042 (set _label=%revver%.%_time%.20h2_%_rsr%&set branch=20h2_%_rsr%)
if %revver%==19042.1706 (set _label=19042.1706.220513-0540.20h2_%_rsr%&set branch=20h2_%_rsr%&set ISOnameESD=0)
if %revver%==19042.1348 (set _label=19042.1348.211103-2005.20h2_%_rsr%&set branch=20h2_%_rsr%&set ISOnameESD=0)
if %revver%==19042.1052 (set _label=19042.1052.210606-1844.20h2_%_rsr%&set branch=20h2_%_rsr%&set ISOnameESD=0)
if %revver%==19042.631 (set _label=19042.631.201119-0144.20h2_%_rsr%&set branch=20h2_%_rsr%&set ISOnameESD=0)
if %revver%==19042.630 (set _label=19042.630.201106-1636.20h2_%_rsr%&set branch=20h2_%_rsr%&set ISOnameESD=0)
if %revver%==19042.572 (set _label=19042.572.201009-1947.20h2_%_rsr%&set branch=20h2_%_rsr%&set ISOnameESD=0)
if %revver%==19042.508 (set _label=19042.508.200927-1902.20h2_%_rsr%&set branch=20h2_%_rsr%&set ISOnameESD=0)
if %revver%==19042.450 (set _label=19042.450.200814-0345.20h2_%_rsr%&set branch=20h2_%_rsr%&set ISOnameESD=0)
if %revver%==19041.572 (set _label=19041.572.201009-1946.vb_%_rsr%&set branch=vb_%_rsr%&set ISOnameESD=0)
if %revver%==19041.508 (set _label=19041.508.200907-0256.vb_%_rsr%&set branch=vb_%_rsr%&set ISOnameESD=0)
if %revver%==19041.450 (set _label=19041.450.200808-0726.vb_%_rsr%&set branch=vb_%_rsr%&set ISOnameESD=0)
if %revver%==19041.388 (set _label=19041.388.200710-1729.vb_%_rsr%&set branch=vb_%_rsr%&set ISOnameESD=0)
if %revver%==19041.264 (set _label=19041.264.200511-0456.vb_%_rsr%&set branch=vb_%_rsr%&set ISOnameESD=0)
if %revver%==19041.84  (set _label=19041.84.200218-1143.vb_%_rsr%&set branch=vb_%_rsr%&set ISOnameESD=0)
if %revmaj%==18363 (set _label=%revver%.%_time%.19h2_%_rsr%&set branch=19h2_%_rsr%)
if %revver%==18363.1139 (set _label=18363.1139.201008-0514.19h2_%_rsr%&set branch=19h2_%_rsr%&set ISOnameESD=0)
if %revver%==18363.592 (set _label=18363.592.200109-2016.19h2_%_rsr%&set branch=19h2_%_rsr%&set ISOnameESD=0)
if %revver%==18363.418 (set _label=18363.418.191007-0143.19h2_%_rsr%&set branch=19h2_%_rsr%&set ISOnameESD=0)
if %revver%==18363.356 (set _label=18363.356.190918-2052.19h2_%_rsr%&set branch=19h2_%_rsr%&set ISOnameESD=0)
if %revver%==18362.356 (set _label=18362.356.190909-1636.19h1_%_rsr%&set branch=19h1_%_rsr%&set ISOnameESD=0)
if %revver%==18362.295 (set _label=18362.295.190809-2228.19h1_%_rsr%&set branch=19h1_%_rsr%&set ISOnameESD=0)
if %revver%==18362.239 (set _label=18362.239.190709-0052.19h1_%_rsr%&set branch=19h1_%_rsr%&set ISOnameESD=0)
if %revver%==18362.175 (set _label=18362.175.190612-0046.19h1_%_rsr%&set branch=19h1_%_rsr%&set ISOnameESD=0)
if %revver%==18362.30  (set _label=18362.30.190401-1528.19h1_%_rsr%&set branch=19h1_%_rsr%&set ISOnameESD=0)
if %revver%==17763.379 (set _label=17763.379.190312-0539.rs5_%_rsr%&set branch=rs5_%_rsr%&set ISOnameESD=0)
if %revver%==17763.253 (set _label=17763.253.190108-0006.rs5_%_rsr%&set branch=rs5_%_rsr%&set ISOnameESD=0)
if %revver%==17763.107 (set _label=17763.107.181029-1455.rs5_%_rsr%&set branch=rs5_%_rsr%&set ISOnameESD=0)
if %revver%==17134.112 (set _label=17134.112.180619-1212.rs4_%_rsr%&set branch=rs4_%_rsr%&set ISOnameESD=0)
if %revver%==16299.125 (set _label=16299.125.171213-1220.rs3_%_rsr%&set branch=rs3_%_rsr%&set ISOnameESD=0)
if %revver%==16299.64  (set _label=16299.15.171109-1522.rs3_%_rsr%&set branch=rs3_%_rsr%&set ISOnameESD=0)
if %revver%==15063.483 (set _label=15063.0.170710-1358.rs2_%_rsr%&set branch=rs2_%_rsr%&set ISOnameESD=0)
if %revver%==15063.473 (set _label=15063.0.170705-1042.rs2_%_rsr%&set branch=rs2_%_rsr%&set ISOnameESD=0)
if %revver%==15063.413 (set _label=15063.0.170607-1447.rs2_%_rsr%&set branch=rs2_%_rsr%&set ISOnameESD=0)
if %revver%==14393.447 (set _label=14393.0.161119-1705.rs1_%_rfr%&set branch=rs1_%_rfr%&set ISOnameESD=0)
if %revver%==10586.164 (set _label=10586.0.160426-1409.th2_%_rfr%&set branch=th2_%_rfr%&set ISOnameESD=0)
if %revver%==10586.104 (set _label=10586.0.160212-2000.th2_%_rfr%&set branch=th2_%_rfr%&set ISOnameESD=0)
if %revver%==10240.16487 (set _label=10240.16393.150909-1450.th1_%_rfr%&set branch=th1_%_rfr%&set ISOnameESD=0)

if /i "%editionid%"=="PPIPro" if %revver%==19042.572 (set _label=19042.572.201012-1221.20h2_%_rsr%&set branch=20h2_%_rsr%&set ISOnameESD=0)
if /i "%ESDedition1%"=="PPIPro" if %revver%==19042.572 (set _label=19042.572.201012-1221.20h2_%_rsr%&set branch=20h2_%_rsr%&set ISOnameESD=0)

if %ISOnameESD% neq 0 call :setloop "%ENCRYPTEDESDN%"
if %_SrvESD% equ 1 (set _label=%_label%_SERVER) else (set _label=%_label%_CLIENT)
for %%# in (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do (
set _label=!_label:%%#=%%#!
set branch=!branch:%%#=%%#!
set langid=!langid:%%#=%%#!
set editionid=!editionid:%%#=%%#!
)
if not "%1"=="" exit /b

if /i %arch%==x86 set archl=X86
if /i %arch%==x64 set archl=X64
if /i %arch%==arm64 set archl=A64

if %MULTI% geq 5 (
if %nedtn% equ 1 set DVDLABEL=CCSNA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%COMBINEDN_OEMRET_%archl%FRE_%langid%
if %aedtn% equ 1 set DVDLABEL=CCSA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%COMBINED_OEMRET_%archl%FRE_%langid%
if %sedtn% equ 1 set DVDLABEL=CCSA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%COMBINEDSL_OEMRET_%archl%FRE_%langid%
if %cedtn% equ 1 set DVDLABEL=CCCHA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%COMBINEDCHINA_OEMRET_%archl%FRE_%langid%
if %_build% geq 16299 (if %VOL% equ 1 (set DVDLABEL=CCSA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%BUSINESS_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CCSA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%CONSUMER_OEMRET_%archl%FRE_%langid%))
if %_SrvESD% equ 1 (if %VOL% equ 1 (set DVDLABEL=SSS_%archl%FREV_%langid%_DV9&set DVDISO=%_label%_VOL_%archl%FRE_%langid%) else (set DVDLABEL=SSS_%archl%FRE_%langid%_DV9&set DVDISO=%_label%_OEMRET_%archl%FRE_%langid%))
if defined branch exit /b
)

:SINGLEINFO
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

:setloop
for /f "tokens=1-3 delims=." %%i in ("%~n1") do (set uupver=%%i.%%j&set uupmaj=%%i&set uupmin=%%j&set uupdate=%%k)
set _tn=4
:startLoop
for /f "tokens=%_tn% delims=._" %%A in ("%~n1") do (
  echo %%A|find /i "client" >nul && goto :endLoop
  echo %%A|find /i "server" >nul && goto :endLoop
  set "_tv%_tn%=%%A"
  set /a _tn+=1
  goto startLoop
)
:endLoop
set _esdb=
set /a _tn-=1
for /l %%B in (4,1,%_tn%) do (
  if defined _esdb (set "_esdb=!_esdb!_!_tv%%B!") else (set "_esdb=!_tv%%B!")
)
set branch=%_esdb%
set _label=%uupver%.%uupdate%.%branch%
exit /b

:setdate
for /f "tokens=5-10 delims=: " %%G in ('wimlib-imagex.exe info "!ENCRYPTEDESD!" %_stm% ^| find /i "Last Modification Time"') do (set mmm=%%G&set "isotime=%%H/%%L,%%I:%%J:%%K"&set _year=%%L&set _month=%%G&set _day=%%H&set _hour=%%I&set _mint=%%J)
for %%# in (Jan:01 Feb:02 Mar:03 Apr:04 May:05 Jun:06 Jul:07 Aug:08 Sep:09 Oct:10 Nov:11 Dec:12) do for /f "tokens=1,2 delims=:" %%A in ("%%#") do (
if /i %mmm%==%%A (set "isotime=%%B/%isotime%"&set "_month=%%B")
)
set "_time=%_year:~2,2% %_month% %_day% - %_hour% %_mint%"
set "_time=%_time: =%
exit /b

:GUID
(rawcopy.exe 24 14 "%ENCRYPTEDESD%" "" & echo i1) | rawcopy.exe -o:24 16 "" %1
if %2 equ 2 exit /b
(rawcopy.exe 24 14 "%ENCRYPTEDESD%" "" & echo b1) | rawcopy.exe -o:24 16 "" ISOFOLDER\sources\boot.wim
exit /b

:WINRE
echo.
echo %line%
echo Unifying winre.wim . . .
echo %line%
echo.
for /f "tokens=3 delims=<>" %%# in ('imagex /info "!ENCRYPTEDESD!" 4 ^| findstr /i HIGHPART') do set "installhigh=%%#"
for /f "tokens=3 delims=<>" %%# in ('imagex /info "!ENCRYPTEDESD!" 4 ^| findstr /i LOWPART') do set "installlow=%%#"
wimlib-imagex.exe extract %1 1 Windows\System32\Recovery\winre.wim --dest-dir=.\bin\temp --no-acls --no-attributes %_Supp%
echo.
echo Updating winre.wim in different indexes . . .
for /L %%A in (5,1,%MULTI%) do (
call set /a inum=%%A-3
for /f "skip=1 delims=" %%# in ('wimlib-imagex.exe dir %1 !inum! --path=Windows\WinSxS\ManifestCache %_Nul6%') do wimlib-imagex.exe update %1 !inum! --command="delete '%%#'" %_Null%
wimlib-imagex.exe update %1 !inum! --command="add 'bin\temp\winre.wim' '\windows\system32\recovery\winre.wim'" %_Null%
wimlib-imagex.exe info %1 !inum! --image-property LASTMODIFICATIONTIME/HIGHPART=%installhigh% --image-property LASTMODIFICATIONTIME/LOWPART=%installlow% %_Nul3%
)
for /f "skip=1 delims=" %%# in ('wimlib-imagex.exe dir %1 1 --path=Windows\WinSxS\ManifestCache %_Nul6%') do wimlib-imagex.exe update %1 1 --command="delete '%%#'" %_Null%
wimlib-imagex.exe info %1 1 --image-property LASTMODIFICATIONTIME/HIGHPART=%installhigh% --image-property LASTMODIFICATIONTIME/LOWPART=%installlow% %_Nul3%
echo.
wimlib-imagex.exe optimize %1 %_Supp%
rmdir /s /q bin\temp\
exit /b

:DDECRYPT
@cls
echo.
call :DECRYPT
ren "!ENCRYPTEDESD!" Decrypted-%ENCRYPTEDESDN%
echo.
goto :QUIT

:DECRYPT
if /i %Backup%==ON (
echo %line%
echo Backing up encrypted esd file . . .
echo %line%
copy /y "!ENCRYPTEDESD!" "!ENCRYPTEDESD!.bak" %_Nul3%
)
echo.
echo %line%
echo Running Decryption program . . .
echo %line%
echo.
esddecrypt.exe "!ENCRYPTEDESD!" %_Nul2% && (echo Done&exit /b)
echo.&echo Errors were reported during ESD decryption.&echo.&goto :QUIT

:: #################################################################

:dCheck
echo.
echo %line%
echo Please wait . . .
echo %line%
set merge=0
set _cust=0
set count=0
for /L %%# in (1,1,2) do (
set ESDmulti%%#=0
set ESDenc%%#=0
set ESDvol%%#=0
set ESDarch%%#=0
set ESDver%%#=0
set ESDlang%%#=0
)
for /f "delims=" %%# in ('dir /b /a:-d "*.esd"') do call :dCount %%#
set _SrvESD=0
call :dInfo 1
call :dInfo 2
if /i "%ESDarch1%"=="%ESDarch2%" goto :prompt2
if /i not "%ESDlang1%"=="%ESDlang2%" goto :prompt2
if /i %ESDver1% neq %ESDver2% goto :prompt2

:DUALMENU
if %AutoStart% equ 1 (set WIMFILE=install.wim&goto :ESDDual)
if %AutoStart% equ 2 (set WIMFILE=install.esd&goto :ESDDual)
color 1F
@cls
echo %lin2%
echo Detected 2 similar ESD files: ^(x64/x86^) / Build: %ESDver1% / Lang: %ESDlang1%
echo create a multi-architecture ISO for both?
echo %lin2%
echo.
echo 0 - No, continue for prompt to process one file only
echo.
echo 1 - ISO with 2 separate install.esd              ^(same as MediaCreationTool^)
echo 2 - ISO with 2 separate install.wim              ^(similar to 1, bigger size^)
echo 3 - ISO with 1 combined install.wim                             ^(Custom AIO^)
if %ENCRYPTED% equ 1 (
echo ____________________________________________________________________________
echo Encrypted ESD Backup is %Backup%. Press 9 to toggle
)
echo %lin2%
echo.
choice /c 12309 /n /m "Choose a menu option: "
if errorlevel 5 (if /i %Backup%==OFF (set Backup=ON) else (set Backup=OFF))&goto :DUALMENU
if errorlevel 4 goto :prompt2
if errorlevel 3 (set WIMFILE=install.wim&set merge=1&set _cust=1&goto :ESDDual)
if errorlevel 2 (set WIMFILE=install.wim&goto :ESDDual)
if errorlevel 1 (set WIMFILE=install.esd&goto :ESDDual)
goto :DUALMENU

:ESDDual
@cls
if exist ISOFOLDER\ rmdir /s /q ISOFOLDER\
mkdir ISOFOLDER
call :dISO 1
call :dISO 2
set archl=X86-X64
if /i "%DVDLABEL1%"=="%DVDLABEL2%" (
set "DVDLABEL=%DVDLABEL1%_%archl%FRE_%langid%_DV9"
set "DVDISO=%_label%%DVDISO1%_%archl%FRE_%langid%"
) else (
set "DVDLABEL=CCSA_%archl%FRE_%langid%_DV9"
set "DVDISO=%_label%%DVDISO1%_%ESDarch1%FRE-%DVDISO2%_%ESDarch2%FRE_%langid%"
)
if %merge% equ 0 goto :BCD
echo.
echo %line%
echo Unifying install.wim . . .
echo %line%
echo.
for /f "tokens=3 delims=: " %%# in ('wimlib-imagex.exe info ISOFOLDER\x86\sources\install.wim ^| findstr /c:"Image Count"') do set imagesi=%%#
for /f "tokens=3 delims=: " %%# in ('wimlib-imagex.exe info ISOFOLDER\x64\sources\install.wim ^| findstr /c:"Image Count"') do set imagesx=%%#
for /f "tokens=1* delims=: " %%A in ('wimlib-imagex.exe info ISOFOLDER\x86\sources\install.wim 1 ^| findstr /b "Name"') do set "_osi=%%B x86"
for /f "tokens=1* delims=: " %%A in ('wimlib-imagex.exe info ISOFOLDER\x64\sources\install.wim 1 ^| findstr /b "Name"') do set "_osx=%%B x64"
if %imagesi% neq 1 for /L %%# in (2,1,%imagesi%) do (
for /f "tokens=1* delims=: " %%A in ('wimlib-imagex.exe info ISOFOLDER\x86\sources\install.wim %%# ^| findstr /b "Name"') do set "_osi%%#=%%B x86"
)
if %imagesx% neq 1 for /L %%# in (2,1,%imagesx%) do (
for /f "tokens=1* delims=: " %%A in ('wimlib-imagex.exe info ISOFOLDER\x64\sources\install.wim %%# ^| findstr /b "Name"') do set "_osx%%#=%%B x64"
)
wimlib-imagex.exe info ISOFOLDER\x86\sources\install.wim 1 "%_osi%" "%_osi%" --image-property DISPLAYNAME="%_osi%" --image-property DISPLAYDESCRIPTION="%_osi%" %_Nul3%
if %imagesi% neq 1 for /L %%# in (2,1,%imagesi%) do (
wimlib-imagex.exe info ISOFOLDER\x86\sources\install.wim %%# "!_osi%%#!" "!_osi%%#!" --image-property DISPLAYNAME="!_osi%%#!" --image-property DISPLAYDESCRIPTION="!_osi%%#!" %_Nul3%
)
wimlib-imagex.exe info ISOFOLDER\x64\sources\install.wim 1 "%_osx%" "%_osx%" --image-property DISPLAYNAME="%_osx%" --image-property DISPLAYDESCRIPTION="%_osx%" %_Nul3%
wimlib-imagex.exe export ISOFOLDER\x64\sources\install.wim 1 ISOFOLDER\x86\sources\install.wim %_Supp%
if %imagesx% neq 1 for /L %%# in (2,1,%imagesx%) do (
wimlib-imagex.exe info ISOFOLDER\x64\sources\install.wim %%# "!_osx%%#!" "!_osx%%#!" --image-property DISPLAYNAME="!_osx%%#!" --image-property DISPLAYDESCRIPTION="!_osx%%#!" %_Nul3%
wimlib-imagex.exe export ISOFOLDER\x64\sources\install.wim %%# ISOFOLDER\x86\sources\install.wim %_Supp%
)

:BCD
echo.
echo %line%
echo Preparing boot configuration settings . . .
echo %line%
echo.
xcopy ISOFOLDER\x64\boot\* ISOFOLDER\boot\ /cheriky %_Nul3%
xcopy ISOFOLDER\x64\efi\* ISOFOLDER\efi\ /cheriky %_Nul3%
copy /y ISOFOLDER\x64\bootmgr* ISOFOLDER\ %_Nul3%
copy /y ISOFOLDER\x86\boot\bootsect.exe ISOFOLDER\boot\ %_Nul3%
set "bcde=bin\bcdedit.exe"
set "BCDBIOS=ISOFOLDER\boot\bcd"
set "BCDUEFI=ISOFOLDER\efi\microsoft\boot\bcd"
if %_cust% equ 0 (
copy /y ISOFOLDER\x86\setup.exe ISOFOLDER\ %_Nul3%
set "entry64=[boot]\x64\sources\boot.wim,%_ram%"
set "entry86=[boot]\x86\sources\boot.wim,%_ram%"
(echo [AutoRun.Amd64]
echo open=x64\setup.exe
echo icon=x64\setup.exe,0
echo.
echo [AutoRun]
echo open=x86\setup.exe
echo icon=x86\setup.exe,0
echo.)>ISOFOLDER\autorun.inf
) else (
set "entry64=[boot]\sources\bootx64.wim,%_ram%"
set "entry86=[boot]\sources\bootx86.wim,%_ram%"
)
%bcde% /store %BCDBIOS% /set {default} description "Windows 10 Setup (64-bit) - BIOS" %_Nul3%
%bcde% /store %BCDBIOS% /set {default} device ramdisk=%entry64% %_Nul3%
%bcde% /store %BCDBIOS% /set {default} osdevice ramdisk=%entry64% %_Nul3%
%bcde% /store %BCDBIOS% /set {default} bootmenupolicy Legacy %_Nul3%
for /f "tokens=2 delims={}" %%# in ('%bcde% /store %BCDBIOS% /copy {default} /d "Windows 10 Setup (32-bit) - BIOS"') do set "guid={%%#}"
%bcde% /store %BCDBIOS% /set %guid% device ramdisk=%entry86% %_Nul3%
%bcde% /store %BCDBIOS% /set %guid% osdevice ramdisk=%entry86% %_Nul3%
%bcde% /store %BCDBIOS% /timeout 30 %_Nul3%
attrib -s -h -a "%BCDBIOS%.LOG*" %_Nul3%
del /f /q "%BCDBIOS%.LOG*" %_Nul3%
%bcde% /store %BCDUEFI% /set {default} description "Windows 10 Setup (64-bit) - UEFI" %_Nul3%
%bcde% /store %BCDUEFI% /set {default} device ramdisk=%entry64% %_Nul3%
%bcde% /store %BCDUEFI% /set {default} osdevice ramdisk=%entry64% %_Nul3%
%bcde% /store %BCDUEFI% /set {default} isolatedcontext Yes %_Nul3%
attrib -s -h -a "%BCDUEFI%.LOG*" %_Nul3%
del /f /q "%BCDUEFI%.LOG*" %_Nul3%
if %_cust% equ 0 goto :CREATEISO
echo.
echo %line%
echo Preparing Custom AIO settings . . .
echo %line%
echo.
copy /y ISOFOLDER\x86\efi\boot\bootia32.efi ISOFOLDER\efi\boot\ %_Nul3%
copy /y ISOFOLDER\x86\efi\microsoft\boot\memtest.efi ISOFOLDER\efi\microsoft\boot\memtestx86.efi %_Nul3%
rename ISOFOLDER\efi\microsoft\boot\memtest.efi memtestx64.efi
mkdir ISOFOLDER\sources
move /y ISOFOLDER\x64\sources\boot.wim ISOFOLDER\sources\bootx64.wim %_Nul3%
move /y ISOFOLDER\x86\sources\boot.wim ISOFOLDER\sources\bootx86.wim %_Nul3%
move /y ISOFOLDER\x86\sources\install.wim ISOFOLDER\sources\install.wim %_Nul3%
move /y ISOFOLDER\x86\sources\lang.ini ISOFOLDER\sources\lang.ini %_Nul3%
rmdir /s /q ISOFOLDER\x64
rmdir /s /q ISOFOLDER\x86
%bcde% /store %BCDUEFI% /set {default} bootmenupolicy Legacy %_Nul3%
for /f "tokens=2 delims={}" %%# in ('%bcde% /store %BCDUEFI% /copy {default} /d "Windows 10 Setup (32-bit) - UEFI"') do set "guid={%%#}"
%bcde% /store %BCDUEFI% /set %guid% device ramdisk=%entry86% %_Nul3%
%bcde% /store %BCDUEFI% /set %guid% osdevice ramdisk=%entry86% %_Nul3%
%bcde% /store %BCDUEFI% /timeout 30 %_Nul3%
%bcde% /store %BCDUEFI% /set {memdiag} description "Windows Memory Diagnostic (64-bit)" %_Nul3%
%bcde% /store %BCDUEFI% /set {memdiag} path \efi\microsoft\boot\memtestx64.efi %_Nul3%
for /f "tokens=2 delims={}" %%# in ('%bcde% /store %BCDUEFI% /copy {memdiag} /d "Windows Memory Diagnostic (32-bit)"') do set "guid={%%#}"
%bcde% /store %BCDUEFI% /set %guid% path \efi\microsoft\boot\memtestx86.efi %_Nul3%
%bcde% /store %BCDUEFI% /toolsdisplayorder %guid% /addlast %_Nul3%
attrib -s -h -a "%BCDUEFI%.LOG*" %_Nul3%
del /f /q "%BCDUEFI%.LOG*" %_Nul3%
call :dSETUP x64
call :dSETUP x86
7z.exe x ISOFOLDER\efi\microsoft\boot\efisys.bin -o.\bin\temp\ %_Nul3%
copy /y ISOFOLDER\efi\boot\bootia32.efi bin\temp\EFI\Boot\BOOTIA32.EFI %_Nul3%
bfi.exe -t=288 -l=EFISECTOR -f=bin\efisys.ima bin\temp %_Nul3%
move /y bin\efisys.ima ISOFOLDER\efi\microsoft\boot\efisys.bin %_Nul3%
del /f /q ISOFOLDER\efi\microsoft\boot\*noprompt.* %_Nul3%
rmdir /s /q bin\temp\
goto :CREATEISO

:dSETUP
(echo [LaunchApps]
echo ^%%SystemRoot^%%\system32\wpeinit.exe
echo ^%%SystemDrive^%%\sources\setup%1.exe)>bin\winpeshl.ini
for /f %%# in ('wimlib-imagex.exe dir ISOFOLDER\sources\boot%1.wim 2 --path=\sources ^| find /i "setup.exe.mui"') do wimlib-imagex.exe update ISOFOLDER\sources\boot%1.wim 2 --command="rename '%%#' '%%~pisetup%1.exe.mui'" %_Null%
wimlib-imagex.exe update ISOFOLDER\sources\boot%1.wim 2 --command="rename 'sources\setup.exe' 'sources\setup%1.exe'" %_Null%
wimlib-imagex.exe update ISOFOLDER\sources\boot%1.wim 2 --command="add 'bin\winpeshl.ini' '\Windows\system32\winpeshl.ini'" %_Null%
wimlib-imagex.exe extract ISOFOLDER\sources\boot%1.wim 2 sources\setup%1.exe --dest-dir=.\ISOFOLDER\sources --no-acls --no-attributes %_Null%
del /f /q bin\winpeshl.ini %_Nul3%
exit /b

:dISO
echo.
set "ENCRYPTEDESD=!ESDfile%1!"
set "ENCRYPTEDESDN=%~nx1"
if !ESDenc%1! equ 1 call :DECRYPT
call :dPREPARE %1
set UnifyWinre=0
set WinreHash=
if %CheckWinre% equ 1 for /f "tokens=2 delims== " %%# in ('wimlib-imagex.exe dir "!ENCRYPTEDESD!" 4 --path=Windows\System32\Recovery\winre.wim --detailed %_Nul6% ^| findstr /b Hash') do call set "WinreHash=%%#"
echo.
echo %line%
echo Creating Setup Media Layout ^(!ESDarch%1!^) . . .
echo %line%
echo.
wimlib-imagex.exe apply "!ENCRYPTEDESD!" 1 ISOFOLDER\!ESDarch%1!\ %_Null%
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_Apply
if exist ISOFOLDER\!ESDarch%1!\MediaMeta.xml del /f /q ISOFOLDER\!ESDarch%1!\MediaMeta.xml %_Nul3%
:: rmdir /s /q ISOFOLDER\!ESDarch%1!\sources\uup\ %_Nul3%
echo.
echo %line%
echo Creating boot.wim ^(!ESDarch%1!^) . . .
echo %line%
echo.
wimlib-imagex.exe export "!ENCRYPTEDESD!" 2 ISOFOLDER\!ESDarch%1!\sources\boot.wim --compress=LZX %_Supp%
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_Export
echo.
wimlib-imagex.exe export "!ENCRYPTEDESD!" 3 ISOFOLDER\!ESDarch%1!\sources\boot.wim --boot %_Supp%
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_Export
echo.
echo %line%
echo Creating %WIMFILE% ^(!ESDarch%1!^) . . .
echo %line%
echo.
if %WIMFILE%==install.wim set _rrr=%_rrr% --compress=LZX
wimlib-imagex.exe export "!ENCRYPTEDESD!" 4 ISOFOLDER\!ESDarch%1!\sources\%WIMFILE% %_rrr% %_Supp%
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_Export
if !ESDmulti%1! neq 0 for /L %%A in (5,1,!ESDmulti%1!) do (
echo.
if %CheckWinre% equ 1 for /f "tokens=2 delims== " %%# in ('wimlib-imagex.exe dir "!ENCRYPTEDESD!" %%A --path=Windows\System32\Recovery\winre.wim --detailed %_Nul6% ^| findstr /b Hash') do if /i not "%%#"=="!WinreHash!" (call set UnifyWinre=1)
wimlib-imagex.exe export "!ENCRYPTEDESD!" %%A ISOFOLDER\!ESDarch%1!\sources\%WIMFILE% %_Supp%
)
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_Export
if %UnifyWinre% equ 1 (
echo.
echo %line%
echo Unifying winre.wim ^(!ESDarch%1!^) . . .
echo %line%
echo.
wimlib-imagex.exe extract ISOFOLDER\!ESDarch%1!\sources\%WIMFILE% 1 Windows\System32\Recovery\winre.wim --dest-dir=.\bin\temp --no-acls --no-attributes %_Supp%
echo.
echo Updating winre.wim in different indexes . . .
for /L %%A in (5,1,!ESDmulti%1!) do (
call set /a inum=%%A-3
for /f "skip=1 delims=" %%# in ('wimlib-imagex.exe dir ISOFOLDER\!ESDarch%1!\sources\%WIMFILE% !inum! --path=Windows\WinSxS\ManifestCache') do wimlib-imagex.exe update ISOFOLDER\!ESDarch%1!\sources\%WIMFILE% !inum! --command="delete '%%#'" %_Null%
wimlib-imagex.exe update ISOFOLDER\!ESDarch%1!\sources\%WIMFILE% !inum! --command="add 'bin\temp\winre.wim' '\windows\system32\recovery\winre.wim'" %_Null%
)
for /f "skip=1 delims=" %%# in ('wimlib-imagex.exe dir ISOFOLDER\!ESDarch%1!\sources\%WIMFILE% 1 --path=Windows\WinSxS\ManifestCache') do wimlib-imagex.exe update ISOFOLDER\!ESDarch%1!\sources\%WIMFILE% 1 --command="delete '%%#'" %_Null%
echo.
wimlib-imagex.exe optimize ISOFOLDER\!ESDarch%1!\sources\%WIMFILE% %_Supp%
rmdir /s /q bin\temp\
)
if /i !ESDarch%1!==x86 (set ESDarch%1=X86) else (set ESDarch%1=X64)
exit /b

:dCount
set /a count+=1
set "ESDfile%count%=%1"
exit /b

:dInfo
imagex /info "!ESDfile%1!">bin\infoall.txt 2>&1
find /i "Professional</EDITIONID>" bin\infoall.txt %_Nul1% && (set ESDedta%1=1) || (set ESDedta%1=0)
find /i "ProfessionalN</EDITIONID>" bin\infoall.txt %_Nul1% && (set ESDedtn%1=1) || (set ESDedtn%1=0)
find /i "CoreSingleLanguage</EDITIONID>" bin\infoall.txt %_Nul1% && (set ESDedts%1=1) || (set ESDedts%1=0)
find /i "CoreCountrySpecific</EDITIONID>" bin\infoall.txt %_Nul1% && (set ESDedtc%1=1) || (set ESDedtc%1=0)
findstr /i "<EDITIONID>Server" bin\infoall.txt %_Nul2% | findstr /i /v ServerRdsh %_Nul1% && (set _SrvESD=1)
imagex /info "!ESDfile%1!" 4 >bin\info.txt 2>&1
for /f "tokens=3 delims=<>" %%# in ('find /i "<BUILD>" bin\info.txt') do set ESDver%1=%%#
for /f "tokens=3 delims=<>" %%# in ('find /i "<EDITIONID>" bin\info.txt') do set ESDedition%1=%%#
for /f "tokens=3 delims=<>" %%# in ('find /i "<DEFAULT>" bin\info.txt') do set ESDlang%1=%%#
for /f "tokens=3 delims=<>" %%# in ('find /i "<ARCH>" bin\info.txt') do (if %%# equ 0 (set ESDarch%1=x86) ELSE (set ESDarch%1=x64))
for /f "tokens=3 delims=: " %%# in ('findstr /i /b /c:"Image Count" bin\infoall.txt') do (if %%# geq 5 set ESDmulti%1=%%#)
wimlib-imagex.exe info "!ESDfile%1!" 4 %_Nul3%
if %ERRORLEVEL% equ 74 set ESDenc%1=1&set ENCRYPTED=1
del /f /q bin\info*.txt
exit /b

:dPREPARE
echo.
echo %line%
echo Checking ESD Info ^(!ESDarch%1!^) . . .
echo %line%
echo.
wimlib-imagex.exe extract "!ENCRYPTEDESD!" 1 sources\ei.cfg --dest-dir=.\bin --no-acls --no-attributes %_Nul3%
if exist "bin\ei.cfg" (
type .\bin\ei.cfg %_Nul2% | find /i "Volume" %_Nul1% && set ESDvol%1=1
del bin\ei.cfg %_Nul3%
)
set DVDLABEL%1=CCSA&set DVDISO%1=OEM
if /i !ESDedition%1!==Core set DVDLABEL%1=CCRA&set DVDISO%1=CORE_OEMRET
if /i !ESDedition%1!==CoreN set DVDLABEL%1=CCRNA&set DVDISO%1=COREN_OEMRET
if /i !ESDedition%1!==CoreSingleLanguage set DVDLABEL%1=CSLA&set DVDISO%1=SINGLELANGUAGE_OEM
if /i !ESDedition%1!==CoreCountrySpecific set DVDLABEL%1=CCHA&set DVDISO%1=CHINA_OEM
if /i !ESDedition%1!==Professional (if !ESDvol%1! equ 1 (set DVDLABEL%1=CPRA&set DVDISO%1=PROFESSIONALVL_VOL) else (set DVDLABEL%1=CPRA&set DVDISO%1=PRO_OEMRET))
if /i !ESDedition%1!==ProfessionalN (if !ESDvol%1! equ 1 (set DVDLABEL%1=CPRNA&set DVDISO%1=PROFESSIONALNVL_VOL) else (set DVDLABEL%1=CPRNA&set DVDISO%1=PRON_OEMRET))
if /i !ESDedition%1!==Education (if !ESDvol%1! equ 1 (set DVDLABEL%1=CEDA&set DVDISO%1=EDUCATION_VOL) else (set DVDLABEL%1=CEDA&set DVDISO%1=EDUCATION_RET))
if /i !ESDedition%1!==EducationN (if !ESDvol%1! equ 1 (set DVDLABEL%1=CEDNA&set DVDISO%1=EDUCATIONN_VOL) else (set DVDLABEL%1=CEDNA&set DVDISO%1=EDUCATIONN_RET))
if /i !ESDedition%1!==Enterprise set DVDLABEL%1=CENA&set DVDISO%1=ENTERPRISE_VOL
if /i !ESDedition%1!==EnterpriseN set DVDLABEL%1=CENNA&set DVDISO%1=ENTERPRISEN_VOL
if /i !ESDedition%1!==Cloud set DVDLABEL%1=CWCA&set DVDISO%1=CLOUD_OEM
if /i !ESDedition%1!==CloudN set DVDLABEL%1=CWCNNA&set DVDISO%1=CLOUDN_OEM
if /i !ESDedition%1!==PPIPro set DVDLABEL%1=CPPIA&set DVDISO%1=PPIPRO_OEM
if /i !ESDedition%1!==EnterpriseG set DVDLABEL%1=CEGA&set DVDISO%1=ENTERPRISEG_VOL
if /i !ESDedition%1!==EnterpriseGN set DVDLABEL%1=CEGNA&set DVDISO%1=ENTERPRISEGN_VOL
if /i !ESDedition%1!==EnterpriseS set DVDLABEL%1=CES&set DVDISO%1=ENTERPRISES_VOL
if /i !ESDedition%1!==EnterpriseSN set DVDLABEL%1=CESNN&set DVDISO%1=ENTERPRISESN_VOL
if /i !ESDedition%1!==ProfessionalEducation (if !ESDvol%1! equ 1 (set DVDLABEL%1=CPREA&set DVDISO%1=PROEDUCATION_VOL) else (set DVDLABEL%1=CPREA&set DVDISO%1=PROEDUCATION_OEMRET))
if /i !ESDedition%1!==ProfessionalEducationN (if !ESDvol%1! equ 1 (set DVDLABEL%1=CPRENA&set DVDISO%1=PROEDUCATIONN_VOL) else (set DVDLABEL%1=CPRENA&set DVDISO%1=PROEDUCATIONN_OEMRET))
if /i !ESDedition%1!==ProfessionalWorkstation (if !ESDvol%1! equ 1 (set DVDLABEL%1=CPRWA&set DVDISO%1=PROWORKSTATION_VOL) else (set DVDLABEL%1=CPRWA&set DVDISO%1=PROWORKSTATION_OEMRET))
if /i !ESDedition%1!==ProfessionalWorkstationN (if !ESDvol%1! equ 1 (set DVDLABEL%1=CPRWNA&set DVDISO%1=PROWORKSTATIONN_VOL) else (set DVDLABEL%1=CPRWNA&set DVDISO%1=PROWORKSTATIONN_OEMRET))
if /i !ESDedition%1!==ProfessionalSingleLanguage set DVDLABEL%1=CPRSLA&set DVDISO%1=PROSINGLELANGUAGE_OEM
if /i !ESDedition%1!==ProfessionalCountrySpecific set DVDLABEL%1=CPRCHA&set DVDISO%1=PROCHINA_OEM
if /i !ESDedition%1!==CloudEdition (if !ESDvol%1! equ 1 (set DVDLABEL%1=CWCA&set DVDISO%1=CLOUD_VOL) else (set DVDLABEL%1=CWCA&set DVDISO%1=CLOUD_OEMRET))
if /i !ESDedition%1!==CloudEditionN (if !ESDvol%1! equ 1 (set DVDLABEL%1=CWCNNA&set DVDISO%1=CLOUDN_VOL) else (set DVDLABEL%1=CWCNNA&set DVDISO%1=CLOUDN_OEMRET))
if !ESDmulti%1! geq 5 (
if !ESDedtn%1! equ 1 set DVDLABEL%1=CCSNA&set DVDISO%1=MULTIN_OEMRET
if !ESDedts%1! equ 1 set DVDLABEL%1=CCSA&set DVDISO%1=MULTISL_OEMRET
if !ESDedta%1! equ 1 set DVDLABEL%1=CCSA&set DVDISO%1=MULTI_OEMRET
if !ESDedtc%1! equ 1 set DVDLABEL%1=CCCHA&set DVDISO%1=MULTICHINA_OEMRET
if !ESDver%1! geq 16299 (if !ESDvol%1! equ 1 (set DVDLABEL%1=CCSA&set DVDISO%1=BUSINESS_VOL) else (set DVDLABEL%1=CCSA&set DVDISO%1=CONSUMER_OEMRET))
)
if %1 equ 2 exit /b

if !ESDmulti%1! equ 0 (set _stm=4) else (set _stm=!ESDmulti%1!)
call :setdate

set arch=!ESDarch%1!
set _build=!ESDver%1!
set langid=!ESDlang%1!
set /a _fixSV=%_build%+1
call :setlabel %1
exit /b

:E_Admin
echo %_err%
echo This script require administrator privileges.
echo To do so, right click on this script and select 'Run as administrator'
echo.
if %_Debug% neq 0 exit /b
echo Press any key to exit.
pause >nul
exit /b

:E_PS
echo %_err%
echo Windows PowerShell is required for this script to work.
echo.
if %_Debug% neq 0 exit /b
echo Press any key to exit.
pause >nul
exit /b

:E_W81
@cls
echo %_err%
echo This script supports Windows NT 10.0 ESDs only.
echo you may use script version 8 to convert Windows 8.1 ESDs.
echo.
goto :QUIT

:E_ESD
@cls
echo %_err%
echo ESD file contain less than 4 images.
echo.
goto :QUIT

:E_File
@cls
echo %_err%
echo ESD file is damaged, blocked or not found.
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
ren ISOFOLDER %DVDISO%
echo.&echo Errors were reported during ISO creation.&echo.&goto :QUIT

:QUIT
if exist ISOFOLDER\ rmdir /s /q ISOFOLDER\
if exist bin\temp\ rmdir /s /q bin\temp\
if exist "!ENCRYPTEDESD!.bak" (
del /f /q "!ENCRYPTEDESD!" %_Nul3%
ren "!ENCRYPTEDESD!.bak" %ENCRYPTEDESDN%
)
popd
if %_Debug% neq 0 exit /b
if %AutoStart% neq 0 exit /b
echo Press 0 to exit.
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
          CreateObject("Shell.Application").ShellExecute "cmd.exe", "/c " & chr(34) & chr(34) & strArg("File") & chr(34) & strLine & chr(34), "", "runas", 1
       </script>
   </job>
</package>
