<!-- : Begin batch script
@setlocal DisableDelayedExpansion
@set uivr=v53
@echo off
:: Change to 1 to get ISO name similar to ESD name (ESD name must be the original, with or without sha1 hash suffix)
set ISOnameESD=0

:: Enable menu to choose from multiple editions ESDs
set MultiChoice=1

:: Check and unify different winre.wim in multiple editions ESDs
set CheckWinre=1

:: Skip creating ISO file, distribution folder will be kept
set SkipISO=0

:: script:     abbodi1406
:: initial:    @rgadguard
:: esddecrypt: qad, whatever127
:: wimlib:     synchronicity
:: rawcopy:    whatever127
:: offlinereg: erwan.l
:: aio efisys: cdob
:: cryptokey:  MrMagic, Chris123NT, mohitbajaj143, Superwzt, timster

:: #################################################################

:: Internal Debug Mode, do not use
set _Debug=0

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

set "_Const=1>nul 2>nul"

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
set "Path=%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
set "_ComSpec=%SystemRoot%\System32\cmd.exe"
set "_wimlib=%~dp0bin\bin64\wimlib-imagex.exe"
if /i %PROCESSOR_ARCHITECTURE%==x86 (if defined PROCESSOR_ARCHITEW6432 (
  set "_ComSpec=%SystemRoot%\Sysnative\cmd.exe"
  ) else (
  set "_wimlib=%~dp0bin\wimlib-imagex.exe"
  )
)

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
set "_work=%~dp0"
if "%_work:~-1%"=="\" set "_work=%_work:~0,-1%"

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
@echo on
@prompt $G

:Begin
if %_Debug% neq 0 if defined _args echo %_args%
title ESD -^> ISO %uivr%
for /f "tokens=6 delims=[]. " %%# in ('ver') do set winbuild=%%#
pushd "%~dp0"
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
set "_err===== ERROR ===="
set _file=(7z.dll,7z.exe,bcdedit.exe,bfi.exe,rawcopy.exe,cdimage.exe,esddecrypt.exe,imagex.exe,libwim-15.dll,offlinereg.exe,offreg.dll,wimlib-imagex.exe,wim-update.txt)
for %%# in %_file% do (
if not exist ".\bin\%%#" (set _bin=%%#&goto :E_Bin)
)
if defined ENCRYPTEDESD goto :check
set _esd=0
if exist "*.esd" (for /f "delims=" %%# in ('dir /b /a:-d "*.esd"') do (call set /a _esd+=1))
if %_esd% equ 2 goto :dCheck
if %_esd% equ 0 goto :prompt1
if %_esd% gtr 1 goto :prompt2
for /f "delims=" %%# in ('dir /b /a:-d "*.esd"') do (set "ENCRYPTEDESD=%%#"&set "ENCRYPTEDESDN=%%#"&goto :check)

:prompt1
if %_Debug% neq 0 exit /b
cls
set ENCRYPTEDESD=
echo %line%
echo Enter / Paste the complete path to the ESD file
echo %line%
echo.
set /p ENCRYPTEDESD=
if not defined ENCRYPTEDESD set _Debug=1&goto :QUIT
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
goto :check

:prompt2
if %_Debug% neq 0 exit /b
cls
set ENCRYPTEDESD=
echo %line%
echo Found more than one ESD file in the current directory
echo Enter the name of the desired file to process
echo You may use "Tab" button to ease the selection
echo %line%
echo.
set /p ENCRYPTEDESD=
if not defined ENCRYPTEDESD set _Debug=1&goto :QUIT
set "ENCRYPTEDESD=%ENCRYPTEDESD:"=%"
set "ENCRYPTEDESDN=%ENCRYPTEDESD%"
goto :check

:check
color 1F
setlocal EnableDelayedExpansion
set ENCRYPTED=0
set "ENCRYPTEDESDN=%ENCRYPTEDESDN: =%"
if /i "%ENCRYPTEDESDN%"=="install.esd" (ren "!ENCRYPTEDESD!" %ENCRYPTEDESDN%.orig&set "ENCRYPTEDESD=!ENCRYPTEDESD!.orig")
bin\wimlib-imagex.exe info "!ENCRYPTEDESD!" 4 %_Nul3%
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% equ 18 goto :E_ESD
if %ERRORTEMP% equ 74 set ENCRYPTED=1&goto :PRE_INFO
if %ERRORTEMP% neq 0 goto :E_File

:PRE_INFO
bin\imagex.exe /info "!ENCRYPTEDESD!">bin\infoall.txt 2>&1
find /i "Professional</EDITIONID>" bin\infoall.txt %_Nul1% && (set editionida=1) || (set editionida=0)
find /i "ProfessionalN</EDITIONID>" bin\infoall.txt %_Nul1% && (set editionidn=1) || (set editionidn=0)
find /i "CoreSingleLanguage</EDITIONID>" bin\infoall.txt %_Nul1% && (set editionids=1) || (set editionids=0)
find /i "CoreCountrySpecific</EDITIONID>" bin\infoall.txt %_Nul1% && (set editionidc=1) || (set editionidc=0)
bin\imagex.exe /info "!ENCRYPTEDESD!" 4 >bin\info.txt 2>&1
for /f "tokens=3 delims=<>" %%# in ('find /i "<BUILD>" bin\info.txt') do set build=%%#
for /f "tokens=3 delims=<>" %%# in ('find /i "<MAJOR>" bin\info.txt') do set ver1=%%#
for /f "tokens=3 delims=<>" %%# in ('find /i "<MINOR>" bin\info.txt') do set ver2=%%#
for /f "tokens=3 delims=<>" %%# in ('find /i "<DEFAULT>" bin\info.txt') do set langid=%%#
for /f "tokens=3 delims=<>" %%# in ('find /i "<EDITIONID>" bin\info.txt') do set editionid=%%#
for /f "tokens=3 delims=<>" %%# in ('find /i "<ARCH>" bin\info.txt') do (if %%# equ 0 (set arch=x86) else if %%# equ 9 (set arch=x64) else (set arch=arm64))
for /f "tokens=3 delims=: " %%# in ('findstr /i /b /c:"Image Count" bin\infoall.txt') do (if %%# geq 5 set MULTI=%%#)
if %build% leq 9600 goto :E_W81
find /i "<DISPLAYNAME>" bin\info.txt %_Nul1% && (
for /f "tokens=3 delims=<>" %%# in ('find /i "<DISPLAYNAME>" bin\info.txt') do set "_os=%%#"
) || (
for /f "tokens=3 delims=<>" %%# in ('find /i "<NAME>" bin\info.txt') do set "_os=%%#"
)
if %MULTI% neq 0 for /L %%A in (4,1,%MULTI%) do (
bin\imagex.exe info "!ENCRYPTEDESD!" %%A | find /i "<DISPLAYNAME>" %_Nul1% && (
for /f "tokens=3 delims=<>" %%# in ('bin\imagex.exe /info "!ENCRYPTEDESD!" %%A ^| find /i "<DISPLAYNAME>"') do set "_os%%A=%%#"
) || (
for /f "tokens=3 delims=<>" %%# in ('bin\imagex.exe /info "!ENCRYPTEDESD!" %%A ^| find /i "<NAME>"') do set "_os%%A=%%#"
)
)
del /f /q bin\info*.txt
if %MULTI% neq 0 (set /a images=%MULTI%-3) else (goto :MAINMENU)
if %MultiChoice% neq 1 goto :MAINMENU

:MULTIMENU
if %_Debug% neq 0 goto :MAINMENU
cls
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
cls
set _single=
echo %line%
for /L %%# in (4,1,%MULTI%) do (
call set /a osnum=%%#-3
echo. !osnum!. !_os%%#!
)
echo %line%
echo Enter edition number to include, or zero '0' to return
echo %line%
set /p _single= ^> Enter your option and press "Enter": 
if not defined _single set _Debug=1&goto :QUIT
if "%_single%"=="0" set _single=&goto :MULTIMENU
if %_single% gtr %images% echo.&echo %_single% is higher than available editions&%_Contn%&%_Pause%&goto :SINGLEMENU
set /a _single+=3&goto :MAINMENU

:RANGEMENU
cls
set _range=
set _start=
set _end=
echo %line%
for /L %%# in (4,1,%MULTI%) do (
call set /a osnum=%%#-3
echo. !osnum!. !_os%%#!
)
echo %line%
echo Enter consecutive range for editions to include: Start-End
echo examples: 2-4 or 1-3 or 3-9
echo Enter zero '0' to return
echo %line%
set /p _range= ^> Enter your option and press "Enter": 
if not defined _range set _Debug=1&goto :QUIT
if "%_range%"=="0" set _start=&goto :MULTIMENU
for /f "tokens=1,2 delims=-" %%A in ('echo %_range%') do set _start=%%A&set _end=%%B
if %_end% gtr %images% echo.&echo Range End is higher than available editions&%_Contn%&%_Pause%&goto :RANGEMENU
if %_start% gtr %_end% echo.&echo Range Start is higher than Range End&%_Contn%&%_Pause%&goto :RANGEMENU
if %_start% equ %_end% echo.&echo Range Start and End are equal&%_Contn%&%_Pause%&goto :RANGEMENU
if %_start% gtr %images% echo.&echo Range Start is higher than available editions&%_Contn%&%_Pause%&goto :RANGEMENU
set /a _start+=3&set /a _end+=3&goto :MAINMENU

:RANDOMMENU
cls
set _count=
set _index=
echo %line%
for /L %%# in (4,1,%MULTI%) do (
call set /a osnum=%%#-3
echo. !osnum!. !_os%%#!
)
echo %line%
echo Enter editions numbers to include separated with spaces
echo examples: 1 3 4 or 5 1 or 4 2 9
echo Enter zero '0' to return
echo %line%
set /p _index= ^> Enter your option and press "Enter": 
if not defined _index set _Debug=1&goto :QUIT
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
if %_Debug% neq 0 (set WIMFILE=install.wim&goto :ISO)
cls
echo %line%
echo.       1 - Create ISO with Standard install.wim
echo.       2 - Create ISO with Compressed install.esd
echo.       3 - Create Standard install.wim
echo.       4 - Create Compressed install.esd
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
if errorlevel 4 (set WIMFILE=install.esd&goto :WIM)
if errorlevel 3 (set WIMFILE=install.wim&goto :WIM)
if errorlevel 2 (set WIMFILE=install.esd&goto :ISO)
if errorlevel 1 (set WIMFILE=install.wim&goto :ISO)
goto :MAINMENU

:ISO
cls
echo.
echo %line%
echo Running ESD -^> ISO %uivr%
echo %line%
echo.
if %ENCRYPTED% equ 1 call :DECRYPT
if %PREPARED% equ 0 call :PREPARE
echo.
echo %line%
echo Creating Setup Media Layout . . .
echo %line%
echo.
if exist ISOFOLDER\ rmdir /s /q ISOFOLDER\
mkdir ISOFOLDER
"!_wimlib!" apply "!ENCRYPTEDESD!" 1 ISOFOLDER\ --no-acls --no-attributes %_Const%
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_Apply
if exist ISOFOLDER\MediaMeta.xml del /f /q ISOFOLDER\MediaMeta.xml %_Nul3%
rem rmdir /s /q ISOFOLDER\sources\uup\ %_Nul3%
echo.
echo %line%
echo Creating boot.wim . . .
echo %line%
echo.
"!_wimlib!" export "!ENCRYPTEDESD!" 2 ISOFOLDER\sources\boot.wim --compress=LZX %_Supp%
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_Export
echo.
"!_wimlib!" export "!ENCRYPTEDESD!" 3 ISOFOLDER\sources\boot.wim --boot %_Supp%
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_Export
"!_wimlib!" extract ISOFOLDER\sources\boot.wim 2 sources\dism.exe --dest-dir=.\bin\temp --no-acls --no-attributes %_Nul3%
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 (
"!_wimlib!" update ISOFOLDER\sources\boot.wim 2 <bin\wim-update.txt %_Const%
)
rmdir /s /q .\bin\temp %_Nul3%
echo.
echo %line%
echo Creating %WIMFILE% . . .
echo %line%
echo.
set source=4
if defined _single set source=%_single%
if defined _start set source=%_start%&set /a _start+=1
if defined _index set source=%_index1%
if %WIMFILE%==install.wim set _rrr=--compress=LZX
"!_wimlib!" export "!ENCRYPTEDESD!" %source% ISOFOLDER\sources\%WIMFILE% %_rrr% %_Supp%
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_Export
if defined _single (
for /f "tokens=3 delims=<>" %%# in ('bin\imagex.exe /info ISOFOLDER\sources\%WIMFILE% 1 ^| find /i "<EDITIONID>"') do set editionid=%%#
call :SINGLEINFO
%_Nul3% call :GUID ISOFOLDER\sources\%WIMFILE% 1
goto :CREATEISO
)
if defined _start for /L %%# in (%_start%,1,%_end%) do (
echo.&"!_wimlib!" export "!ENCRYPTEDESD!" %%# ISOFOLDER\sources\%WIMFILE% %_Supp%
)
if defined _index for /L %%# in (2,1,%_count%) do (
echo.&"!_wimlib!" export "!ENCRYPTEDESD!" !_index%%#! ISOFOLDER\sources\%WIMFILE% %_Supp%
)
if not defined _start if not defined _index if %MULTI% neq 0 for /L %%# in (5,1,%MULTI%) do (
echo.&"!_wimlib!" export "!ENCRYPTEDESD!" %%# ISOFOLDER\sources\%WIMFILE% %_Supp%
)
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_Export
if %UnifyWinre% equ 1 call :WINRE ISOFOLDER\sources\%WIMFILE%
%_Nul3% call :GUID ISOFOLDER\sources\%WIMFILE% 1

:CREATEISO
if %SkipISO% equ 1 (
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
bin\cdimage.exe -bootdata:2#p0,e,b"ISOFOLDER\boot\etfsboot.com"#pEF,e,b"ISOFOLDER\efi\Microsoft\boot\efisys.bin" -o -m -u2 -udfver102 -t%isotime% -g -l%DVDLABEL% ISOFOLDER %DVDISO%.ISO %_Supp%
) else (
bin\cdimage.exe -bootdata:1#pEF,e,b"ISOFOLDER\efi\Microsoft\boot\efisys.bin" -o -m -u2 -udfver102 -t%isotime% -g -l%DVDLABEL% ISOFOLDER %DVDISO%.ISO %_Supp%
)
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_ISO
echo.
goto :QUIT

:WIM
cls
if %WIMFILE%==install.wim if exist "!_work!\install.wim" (
echo.
echo %line%
echo An install.wim file is already present in the current folder
echo %line%
echo.
goto :QUIT
)
echo.
if %ENCRYPTED% equ 1 call :DECRYPT
if %PREPARED% equ 0 call :PREPARE
echo.
echo %line%
echo Creating %WIMFILE% . . .
echo %line%
echo.
set source=4
if defined _single set source=%_single%
if defined _start set source=%_start%&set /a _start+=1
if defined _index set source=%_index1%
if %WIMFILE%==install.wim set _rrr=--compress=LZX
"!_wimlib!" export "!ENCRYPTEDESD!" %source% %WIMFILE% %_rrr% %_Supp%
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_Export
if defined _single goto :WIMproceed
if defined _start for /L %%# in (%_start%,1,%_end%) do (
echo.&"!_wimlib!" export "!ENCRYPTEDESD!" %%# %WIMFILE% %_Supp%
)
if defined _index for /L %%# in (2,1,%_count%) do (
echo.&"!_wimlib!" export "!ENCRYPTEDESD!" !_index%%#! %WIMFILE% %_Supp%
)
if not defined _start if not defined _index if %MULTI% neq 0 for /L %%# in (5,1,%MULTI%) do (
echo.&"!_wimlib!" export "!ENCRYPTEDESD!" %%# %WIMFILE% %_Supp%
)
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_Export
if %UnifyWinre% equ 1 call :WINRE %WIMFILE%

:WIMproceed
%_Nul3% call :GUID %WIMFILE% 2
echo.
echo Done.
echo.
goto :QUIT

:INFO
cls
if %PREPARED% equ 0 call :PREPARE
cls
echo %line%
echo                     ESD Contents Info
echo %line%
echo     Arch: %arch%
echo Language: %langid%
echo  Version: %ver1%.%ver2%.%revision%
if defined branch echo   Branch: %branch%
if %MULTI% equ 0 echo       OS: %_os%
if %MULTI% neq 0 (
echo     OS 1: %_os%
for /L %%# in (5,1,%MULTI%) do (
call set /a osnum=%%#-3
echo     OS !osnum!: !_os%%#!
)
)
echo.
%_Contn%&%_Pause%
goto :MAINMENU

:PREPARE
echo.
echo %line%
echo Checking ESD Info . . .
echo %line%
set PREPARED=1
if %CheckWinre% equ 1 for /f "tokens=2 delims== " %%# in ('bin\wimlib-imagex.exe dir "!ENCRYPTEDESD!" 4 --path=Windows\System32\Recovery\winre.wim --detailed %_Nul6% ^| findstr /b Hash') do call set "WinreHash=%%#"
if %MULTI% neq 0 for /L %%A in (5,1,%MULTI%) do (
if !CheckWinre! equ 1 for /f "tokens=2 delims== " %%# in ('bin\wimlib-imagex.exe dir "!ENCRYPTEDESD!" %%A --path=Windows\System32\Recovery\winre.wim --detailed %_Nul6% ^| findstr /b Hash') do if /i not "%%#"=="!WinreHash!" (call set UnifyWinre=1)
)
"!_wimlib!" extract "!ENCRYPTEDESD!" 1 sources\ei.cfg --dest-dir=.\bin\temp --no-acls --no-attributes %_Nul3%
if exist "bin\temp\ei.cfg" type .\bin\temp\ei.cfg %_Nul2% | find /i "Volume" %_Nul1% && set VOL=1
if %MULTI% equ 0 (set sourcetime=4) else (set sourcetime=%MULTI%)
for /f "tokens=5-10 delims=: " %%G in ('bin\wimlib-imagex.exe info "!ENCRYPTEDESD!" %sourcetime% ^| find /i "Last Modification Time"') do (set mmm=%%G&set "isotime=%%H/%%L,%%I:%%J:%%K"&set _year=%%L&set _month=%%G&set _day=%%H&set _hour=%%I&set _mint=%%J)
call :setdate %mmm%
call :dateset %_month%

:setlabel
if %build% geq 16299 (
"!_wimlib!" extract "!ENCRYPTEDESD!" 1 sources\setuphost.exe --dest-dir=.\bin\temp --no-acls --no-attributes %_Const%
bin\7z.exe l .\bin\temp\setuphost.exe >.\bin\temp\version.txt 2>&1
) else (
"!_wimlib!" extract "!ENCRYPTEDESD!" 3 Windows\System32\ntoskrnl.exe --dest-dir=.\bin\temp --no-acls --no-attributes %_Const%
bin\7z.exe l .\bin\temp\ntoskrnl.exe >.\bin\temp\version.txt 2>&1
)
for /f "tokens=4-7 delims=.() " %%i in ('"findstr /i /b "FileVersion" .\bin\temp\version.txt" %_Nul6%') do (set version=%%i.%%j&set vermajor=%%i&set verminor=%%j&set branch=%%k&set labeldate=%%l)
set revision=%version%&set revmajor=%vermajor%&set revminor=%verminor%
set "tok=6,7"&set "toe=5,6,7"
if /i %arch%==x86 (set _ss=x86) else if /i %arch%==x64 (set _ss=amd64) else (set _ss=arm64)
"!_wimlib!" extract "!ENCRYPTEDESD!" 4 Windows\WinSxS\Manifests\%_ss%_microsoft-windows-coreos-revision*.manifest --dest-dir=.\bin\temp --no-acls --no-attributes %_Nul3%
if exist "bin\temp\*_microsoft-windows-coreos-revision*.manifest" for /f "tokens=%tok% delims=_." %%A in ('dir /b /a:-d /od .\bin\temp\*_microsoft-windows-coreos-revision*.manifest') do set revision=%%A.%%B&set revmajor=%%A&set revminor=%%B
if %build% geq 15063 (
"!_wimlib!" extract "!ENCRYPTEDESD!" 4 Windows\System32\config\SOFTWARE --dest-dir=.\bin\temp --no-acls --no-attributes %_Const%
set "isokey=Microsoft\Windows NT\CurrentVersion\Update\TargetingInfo\Installed"
for /f %%i in ('"bin\offlinereg.exe .\bin\temp\SOFTWARE "!isokey!" enumkeys %_Nul6% ^| find /i "Client.OS""') do if not errorlevel 1 (
  for /f "tokens=3 delims==:" %%A in ('"bin\offlinereg.exe .\bin\temp\SOFTWARE "!isokey!\%%i" getvalue Branch %_Nul6%"') do set "isobranch=%%~A"
  for /f "tokens=5,6 delims==:." %%A in ('"bin\offlinereg.exe .\bin\temp\SOFTWARE "!isokey!\%%i" getvalue Version %_Nul6%"') do if %%A gtr !revmajor! (
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
"!_wimlib!" extract "!ENCRYPTEDESD!" 4 Windows\servicing\Packages\Package_for_RollupFix*.mum --dest-dir=%SystemRoot%\temp --no-acls --no-attributes %_Nul3%
for /f %%# in ('dir /b /a:-d /od %SystemRoot%\temp\Package_for_RollupFix*.mum') do set "mumfile=%SystemRoot%\temp\%%#"
for /f "tokens=2 delims==" %%# in ('wmic datafile where "name='!mumfile:\=\\!'" get LastModified /value') do set "mumdate=%%#"
del /f /q %SystemRoot%\temp\*.mum
set "labeldate=!mumdate:~2,2!!mumdate:~4,2!!mumdate:~6,2!-!mumdate:~8,4!"
)
set _label2=
if /i "%branch%"=="WinBuild" (
"!_wimlib!" extract "!ENCRYPTEDESD!" 4 Windows\System32\config\SOFTWARE --dest-dir=.\bin\temp --no-acls --no-attributes %_Const%
for /f "tokens=3 delims==:" %%# in ('"bin\offlinereg.exe .\bin\temp\SOFTWARE "Microsoft\Windows NT\CurrentVersion" getvalue BuildLabEx" %_Nul6%') do if not errorlevel 1 (for /f "tokens=1-5 delims=." %%i in ('echo %%~#') do set _label2=%%i.%%j.%%m.%%l_CLIENT&set branch=%%l)
)
if defined _label2 (set _label=%_label2%) else (set _label=%version%.%labeldate%.%branch%_CLIENT)
rmdir /s /q .\bin\temp
set _rfr=refresh
set _rsr=release_svc_%_rfr%
if %revmajor%==18363 (set _label=%revision%.%_time%.19h2_%_rsr%_CLIENT&set branch=19h2_%_rsr%)
if %revision%==18363.418 (set _label=18363.418.191007-0143.19h2_%_rsr%_CLIENT&set branch=19h2_%_rsr%)
if %revision%==18363.356 (set _label=18363.356.190918-2052.19h2_%_rsr%_CLIENT&set branch=19h2_%_rsr%)
if %revision%==18362.356 (set _label=18362.356.190909-1636.19h1_%_rsr%_CLIENT&set branch=19h1_%_rsr%)
if %revision%==18362.295 (set _label=18362.295.190809-2228.19h1_%_rsr%_CLIENT&set branch=19h1_%_rsr%)
if %revision%==18362.239 (set _label=18362.239.190709-0052.19h1_%_rsr%_CLIENT&set branch=19h1_%_rsr%)
if %revision%==18362.175 (set _label=18362.175.190612-0046.19h1_%_rsr%_CLIENT&set branch=19h1_%_rsr%)
if %revision%==18362.30  (set _label=18362.30.190401-1528.19h1_%_rsr%_CLIENT&set branch=19h1_%_rsr%)
if %revision%==17763.379 (set _label=17763.379.190312-0539.rs5_%_rsr%_CLIENT&set branch=rs5_%_rsr%)
if %revision%==17763.253 (set _label=17763.253.190108-0006.rs5_%_rsr%_CLIENT&set branch=rs5_%_rsr%)
if %revision%==17763.107 (set _label=17763.107.181029-1455.rs5_%_rsr%_CLIENT&set branch=rs5_%_rsr%)
if %revision%==17134.112 (set _label=17134.112.180619-1212.rs4_%_rsr%_CLIENT&set branch=rs4_%_rsr%)
if %revision%==16299.125 (set _label=16299.125.171213-1220.rs3_%_rsr%_CLIENT&set branch=rs3_%_rsr%)
if %revision%==16299.64  (set _label=16299.15.171109-1522.rs3_%_rsr%_CLIENT&set branch=rs3_%_rsr%)
if %revision%==15063.483 (set _label=15063.0.170710-1358.rs2_%_rsr%_CLIENT&set branch=rs2_%_rsr%)
if %revision%==15063.413 (set _label=15063.0.170607-1447.rs2_%_rsr%_CLIENT&set branch=rs2_%_rsr%)
if %revision%==14393.447 (set _label=14393.0.161119-1705.rs1_%_rfr%_CLIENT&set branch=rs1_%_rfr%)
if %revision%==10586.164 (set _label=10586.0.160426-1409.th2_%_rfr%_CLIENT&set branch=th2_%_rfr%)
if %revision%==10586.104 (set _label=10586.0.160212-2000.th2_%_rfr%_CLIENT&set branch=th2_%_rfr%)
if %revision%==10240.16487 (set _label=10240.16393.150909-1450.th1_%_rfr%_CLIENT&set branch=th1_%_rfr%)

if %ISOnameESD% neq 0 call :setloop "%ENCRYPTEDESDN%"
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
if %editionidn% equ 1 set DVDLABEL=CCSNA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%COMBINEDN_OEMRET_%archl%FRE_%langid%
if %editionida% equ 1 set DVDLABEL=CCSA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%COMBINED_OEMRET_%archl%FRE_%langid%
if %editionids% equ 1 set DVDLABEL=CCSA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%COMBINEDSL_OEMRET_%archl%FRE_%langid%
if %editionidc% equ 1 set DVDLABEL=CCCHA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%COMBINEDCHINA_OEMRET_%archl%FRE_%langid%
if %build% geq 16299 (if %VOL% equ 1 (set DVDLABEL=CCSA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%BUSINESS_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CCSA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%CONSUMER_OEMRET_%archl%FRE_%langid%))
if defined branch exit /b
)

:SINGLEINFO
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

:setloop
for /f "tokens=1-3 delims=." %%i in ("%~n1") do (set version=%%i.%%j&set vermajor=%%i&set verminor=%%j&set labeldate=%%k)
set _tn=4
:startLoop
for /f "tokens=%_tn% delims=._" %%A in ("%~n1") do (
  echo %%A|find /i "client" >nul && goto :endLoop
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
set _label=%version%.%labeldate%.%branch%_CLIENT
exit /b

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

:dateset
if /i %1==Jan set _month=01
if /i %1==Feb set _month=02
if /i %1==Mar set _month=03
if /i %1==Apr set _month=04
if /i %1==May set _month=05
if /i %1==Jun set _month=06
if /i %1==Jul set _month=07
if /i %1==Aug set _month=08
if /i %1==Sep set _month=09
if /i %1==Oct set _month=10
if /i %1==Nov set _month=11
if /i %1==Dec set _month=12
set "_time=%_year:~2,2% %_month% %_day% - %_hour% %_mint%"
set "_time=%_time: =%
exit /b

:GUID
(bin\rawcopy.exe 24 14 "%ENCRYPTEDESD%" "" & echo i1) | bin\rawcopy.exe -o:24 16 "" %1
if %2 equ 2 exit /b
(bin\rawcopy.exe 24 14 "%ENCRYPTEDESD%" "" & echo b1) | bin\rawcopy.exe -o:24 16 "" ISOFOLDER\sources\boot.wim
exit /b

:WINRE
echo.
echo %line%
echo Unifying winre.wim . . .
echo %line%
echo.
for /f "tokens=3 delims=<>" %%# in ('bin\imagex.exe /info "!ENCRYPTEDESD!" 4 ^| findstr /i HIGHPART') do set "installhigh=%%#"
for /f "tokens=3 delims=<>" %%# in ('bin\imagex.exe /info "!ENCRYPTEDESD!" 4 ^| findstr /i LOWPART') do set "installlow=%%#"
"!_wimlib!" extract %1 1 Windows\System32\Recovery\winre.wim --dest-dir=.\bin\temp --no-acls --no-attributes %_Supp%
echo.
echo Updating winre.wim in different indexes . . .
for /L %%A in (5,1,%MULTI%) do (
call set /a inum=%%A-3
for /f "skip=1 delims=" %%# in ('bin\wimlib-imagex.exe dir %1 !inum! --path=Windows\WinSxS\ManifestCache %_Nul6%') do "!_wimlib!" update %1 !inum! --command="delete '%%#'" %_Const%
"!_wimlib!" update %1 !inum! --command="add 'bin\temp\winre.wim' '\windows\system32\recovery\winre.wim'" %_Const%
"!_wimlib!" info %1 !inum! --image-property LASTMODIFICATIONTIME/HIGHPART=%installhigh% --image-property LASTMODIFICATIONTIME/LOWPART=%installlow% %_Nul3%
)
for /f "skip=1 delims=" %%# in ('bin\wimlib-imagex.exe dir %1 1 --path=Windows\WinSxS\ManifestCache %_Nul6%') do "!_wimlib!" update %1 1 --command="delete '%%#'" %_Const%
"!_wimlib!" info %1 1 --image-property LASTMODIFICATIONTIME/HIGHPART=%installhigh% --image-property LASTMODIFICATIONTIME/LOWPART=%installlow% %_Nul3%
echo.
"!_wimlib!" optimize %1 %_Supp%
rmdir /s /q .\bin\temp
exit /b

:DDECRYPT
cls
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
bin\esddecrypt.exe "!ENCRYPTEDESD!" %_Nul2% && (echo Done&exit /b)
echo.&echo Errors were reported during ESD decryption.&echo.&goto :QUIT

:: #################################################################

:dCheck
setlocal EnableDelayedExpansion
echo.
echo %line%
echo Please wait . . .
echo %line%
set combine=0
set custom=0
set count=0
for /L %%# in (1,1,2) do (
set ESDmulti%%#=0
set ESDenc%%#=0
set ESDvol%%#=0
set ESDarch%%#=0
set ESDver%%#=0
set ESDlang%%#=0
)
for /f "delims=" %%# in ('dir /b /a:-d *.esd') do call :dCount %%#
call :dInfo 1
call :dInfo 2
if /i %ESDarch1% equ %ESDarch2% goto :prompt2
if /i %ESDlang1% neq %ESDlang2% goto :prompt2
if /i %ESDver1% neq %ESDver2% goto :prompt2

:DUALMENU
color 1F
cls
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
if errorlevel 3 (set WIMFILE=install.wim&set combine=1&set custom=1&goto :Dual)
if errorlevel 2 (set WIMFILE=install.wim&goto :Dual)
if errorlevel 1 (set WIMFILE=install.esd&goto :Dual)
goto :DUALMENU

:Dual
cls
if exist ISOFOLDER\ rmdir /s /q ISOFOLDER\
mkdir ISOFOLDER
call :dISO 1
call :dISO 2
set archl=X86-X64
if /i "%DVDLABEL1%" equ "%DVDLABEL2%" (
set "DVDLABEL=%DVDLABEL1%_%archl%FRE_%langid%_DV9"
set "DVDISO=%_label%%DVDISO1%_%archl%FRE_%langid%"
) else (
set "DVDLABEL=CCSA_%archl%FRE_%langid%_DV9"
set "DVDISO=%_label%%DVDISO1%_%ESDarch1%FRE-%DVDISO2%_%ESDarch2%FRE_%langid%"
)
if %combine% equ 0 goto :BCD
echo.
echo %line%
echo Unifying install.wim . . .
echo %line%
echo.
for /f "tokens=3 delims=: " %%# in ('bin\wimlib-imagex.exe info ISOFOLDER\x86\sources\install.wim ^| findstr /c:"Image Count"') do set imagesi=%%#
for /f "tokens=3 delims=: " %%# in ('bin\wimlib-imagex.exe info ISOFOLDER\x64\sources\install.wim ^| findstr /c:"Image Count"') do set imagesx=%%#
for /f "tokens=1* delims=: " %%A in ('bin\wimlib-imagex.exe info ISOFOLDER\x86\sources\install.wim 1 ^| findstr /b "Name"') do set "_osi=%%B x86"
for /f "tokens=1* delims=: " %%A in ('bin\wimlib-imagex.exe info ISOFOLDER\x64\sources\install.wim 1 ^| findstr /b "Name"') do set "_osx=%%B x64"
if %imagesi% neq 1 for /L %%# in (2,1,%imagesi%) do (
for /f "tokens=1* delims=: " %%A in ('bin\wimlib-imagex.exe info ISOFOLDER\x86\sources\install.wim %%# ^| findstr /b "Name"') do set "_osi%%#=%%B x86"
)
if %imagesx% neq 1 for /L %%# in (2,1,%imagesx%) do (
for /f "tokens=1* delims=: " %%A in ('bin\wimlib-imagex.exe info ISOFOLDER\x64\sources\install.wim %%# ^| findstr /b "Name"') do set "_osx%%#=%%B x64"
)
"!_wimlib!" info ISOFOLDER\x86\sources\install.wim 1 "%_osi%" "%_osi%" --image-property DISPLAYNAME="%_osi%" --image-property DISPLAYDESCRIPTION="%_osi%" %_Nul3%
if %imagesi% neq 1 for /L %%# in (2,1,%imagesi%) do (
"!_wimlib!" info ISOFOLDER\x86\sources\install.wim %%# "!_osi%%#!" "!_osi%%#!" --image-property DISPLAYNAME="!_osi%%#!" --image-property DISPLAYDESCRIPTION="!_osi%%#!" %_Nul3%
)
"!_wimlib!" info ISOFOLDER\x64\sources\install.wim 1 "%_osx%" "%_osx%" --image-property DISPLAYNAME="%_osx%" --image-property DISPLAYDESCRIPTION="%_osx%" %_Nul3%
"!_wimlib!" export ISOFOLDER\x64\sources\install.wim 1 ISOFOLDER\x86\sources\install.wim %_Supp%
if %imagesx% neq 1 for /L %%# in (2,1,%imagesx%) do (
"!_wimlib!" info ISOFOLDER\x64\sources\install.wim %%# "!_osx%%#!" "!_osx%%#!" --image-property DISPLAYNAME="!_osx%%#!" --image-property DISPLAYDESCRIPTION="!_osx%%#!" %_Nul3%
"!_wimlib!" export ISOFOLDER\x64\sources\install.wim %%# ISOFOLDER\x86\sources\install.wim %_Supp%
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
if %custom% equ 0 (
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
if %custom% equ 0 goto :CREATEISO
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
bin\7z.exe x ISOFOLDER\efi\microsoft\boot\efisys.bin -o.\bin\temp\ %_Nul3%
copy /y ISOFOLDER\efi\boot\bootia32.efi bin\temp\EFI\Boot\BOOTIA32.EFI %_Nul3%
bin\bfi.exe -t=288 -l=EFISECTOR -f=bin\efisys.ima bin\temp %_Nul3%
move /y bin\efisys.ima ISOFOLDER\efi\microsoft\boot\efisys.bin %_Nul3%
del /f /q ISOFOLDER\efi\microsoft\boot\*noprompt.* %_Nul3%
rmdir /s /q .\bin\temp
goto :CREATEISO

:dSETUP
(echo [LaunchApps]
echo ^%%SystemRoot^%%\system32\wpeinit.exe
echo ^%%SystemDrive^%%\sources\setup%1.exe)>bin\winpeshl.ini
for /f %%# in ('bin\wimlib-imagex.exe dir ISOFOLDER\sources\boot%1.wim 2 --path=\sources ^| find /i "setup.exe.mui"') do "!_wimlib!" update ISOFOLDER\sources\boot%1.wim 2 --command="rename '%%#' '%%~pisetup%1.exe.mui'" %_Const%
"!_wimlib!" update ISOFOLDER\sources\boot%1.wim 2 --command="rename 'sources\setup.exe' 'sources\setup%1.exe'" %_Const%
"!_wimlib!" update ISOFOLDER\sources\boot%1.wim 2 --command="add 'bin\winpeshl.ini' '\Windows\system32\winpeshl.ini'" %_Const%
"!_wimlib!" extract ISOFOLDER\sources\boot%1.wim 2 sources\setup%1.exe --dest-dir=.\ISOFOLDER\sources --no-acls --no-attributes %_Const%
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
if %CheckWinre% equ 1 for /f "tokens=2 delims== " %%# in ('bin\wimlib-imagex.exe dir "!ENCRYPTEDESD!" 4 --path=Windows\System32\Recovery\winre.wim --detailed %_Nul6% ^| findstr /b Hash') do call set "WinreHash=%%#"
echo.
echo %line%
echo Creating Setup Media Layout ^(!ESDarch%1!^) . . .
echo %line%
echo.
"!_wimlib!" apply "!ENCRYPTEDESD!" 1 ISOFOLDER\!ESDarch%1!\ %_Const%
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_Apply
del /f /q ISOFOLDER\!ESDarch%1!\MediaMeta.xml %_Nul3%
rmdir /s /q ISOFOLDER\!ESDarch%1!\sources\uup\ %_Nul3%
echo.
echo %line%
echo Creating boot.wim ^(!ESDarch%1!^) . . .
echo %line%
echo.
"!_wimlib!" export "!ENCRYPTEDESD!" 2 ISOFOLDER\!ESDarch%1!\sources\boot.wim --compress=LZX %_Supp%
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_Export
echo.
"!_wimlib!" export "!ENCRYPTEDESD!" 3 ISOFOLDER\!ESDarch%1!\sources\boot.wim --boot %_Supp%
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_Export
echo.
echo %line%
echo Creating %WIMFILE% ^(!ESDarch%1!^) . . .
echo %line%
echo.
if %WIMFILE%==install.wim set _rrr=--compress=LZX
"!_wimlib!" export "!ENCRYPTEDESD!" 4 ISOFOLDER\!ESDarch%1!\sources\%WIMFILE% %_rrr% %_Supp%
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_Export
if !ESDmulti%1! neq 0 for /L %%A in (5,1,!ESDmulti%1!) do (
echo.
if !CheckWinre! equ 1 for /f "tokens=2 delims== " %%# in ('bin\wimlib-imagex.exe dir "!ENCRYPTEDESD!" %%A --path=Windows\System32\Recovery\winre.wim --detailed %_Nul6% ^| findstr /b Hash') do if /i not "%%#"=="!WinreHash!" (call set UnifyWinre=1)
"!_wimlib!" export "!ENCRYPTEDESD!" %%A ISOFOLDER\!ESDarch%1!\sources\%WIMFILE% %_Supp%
)
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_Export
if %UnifyWinre% equ 1 (
echo.
echo %line%
echo Unifying winre.wim ^(!ESDarch%1!^) . . .
echo %line%
echo.
"!_wimlib!" extract ISOFOLDER\!ESDarch%1!\sources\%WIMFILE% 1 Windows\System32\Recovery\winre.wim --dest-dir=.\bin\temp --no-acls --no-attributes %_Supp%
echo.
echo Updating winre.wim in different indexes . . .
for /L %%A in (5,1,!ESDmulti%1!) do (
call set /a inum=%%A-3
for /f "skip=1 delims=" %%# in ('bin\wimlib-imagex.exe dir ISOFOLDER\!ESDarch%1!\sources\%WIMFILE% !inum! --path=Windows\WinSxS\ManifestCache') do "!_wimlib!" update ISOFOLDER\!ESDarch%1!\sources\%WIMFILE% !inum! --command="delete '%%#'" %_Const%
"!_wimlib!" update ISOFOLDER\!ESDarch%1!\sources\%WIMFILE% !inum! --command="add 'bin\temp\winre.wim' '\windows\system32\recovery\winre.wim'" %_Const%
)
for /f "skip=1 delims=" %%# in ('bin\wimlib-imagex.exe dir ISOFOLDER\!ESDarch%1!\sources\%WIMFILE% 1 --path=Windows\WinSxS\ManifestCache') do "!_wimlib!" update ISOFOLDER\!ESDarch%1!\sources\%WIMFILE% 1 --command="delete '%%#'" %_Const%
echo.
"!_wimlib!" optimize ISOFOLDER\!ESDarch%1!\sources\%WIMFILE% %_Supp%
rmdir /s /q .\bin\temp
)
if /i !ESDarch%1!==x86 (set ESDarch%1=X86) else (set ESDarch%1=X64)
exit /b

:dCount
set /a count+=1
set "ESDfile%count%=%1"
exit /b

:dInfo
bin\imagex.exe /info "!ESDfile%1!">bin\infoall.txt 2>&1
find /i "Professional</EDITIONID>" bin\infoall.txt %_Nul1% && (set ESDeditiona%1=1) || (set ESDeditiona%1=0)
find /i "ProfessionalN</EDITIONID>" bin\infoall.txt %_Nul1% && (set ESDeditionn%1=1) || (set ESDeditionn%1=0)
find /i "CoreSingleLanguage</EDITIONID>" bin\infoall.txt %_Nul1% && (set ESDeditions%1=1) || (set ESDeditions%1=0)
find /i "CoreCountrySpecific</EDITIONID>" bin\infoall.txt %_Nul1% && (set ESDeditionc%1=1) || (set ESDeditionc%1=0)
bin\imagex.exe /info "!ESDfile%1!" 4 >bin\info.txt 2>&1
for /f "tokens=3 delims=<>" %%# in ('find /i "<BUILD>" bin\info.txt') do set ESDver%1=%%#
for /f "tokens=3 delims=<>" %%# in ('find /i "<EDITIONID>" bin\info.txt') do set ESDedition%1=%%#
for /f "tokens=3 delims=<>" %%# in ('find /i "<DEFAULT>" bin\info.txt') do set ESDlang%1=%%#
for /f "tokens=3 delims=<>" %%# in ('find /i "<ARCH>" bin\info.txt') do (if %%# equ 0 (set ESDarch%1=x86) ELSE (set ESDarch%1=x64))
for /f "tokens=3 delims=: " %%# in ('findstr /i /b /c:"Image Count" bin\infoall.txt') do (if %%# geq 5 set ESDmulti%1=%%#)
bin\wimlib-imagex.exe info "!ESDfile%1!" 4 %_Nul3%
if %ERRORLEVEL% equ 74 set ESDenc%1=1&set ENCRYPTED=1
del /f /q bin\info*.txt
exit /b

:dPREPARE
echo.
echo %line%
echo Checking ESD Info ^(!ESDarch%1!^) . . .
echo %line%
echo.
"!_wimlib!" extract "!ENCRYPTEDESD!" 1 sources\ei.cfg --dest-dir=.\bin --no-acls --no-attributes %_Nul3%
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
if !ESDmulti%1! geq 5 (
if !ESDeditionn%1! equ 1 set DVDLABEL%1=CCSNA&set DVDISO%1=MULTIN_OEMRET
if !ESDeditions%1! equ 1 set DVDLABEL%1=CCSA&set DVDISO%1=MULTISL_OEMRET
if !ESDeditiona%1! equ 1 set DVDLABEL%1=CCSA&set DVDISO%1=MULTI_OEMRET
if !ESDeditionc%1! equ 1 set DVDLABEL%1=CCCHA&set DVDISO%1=MULTICHINA_OEMRET
if !ESDver%1! geq 16299 (if !ESDvol%1! equ 1 (set DVDLABEL%1=CCSA&set DVDISO%1=BUSINESS_VOL) else (set DVDLABEL%1=CCSA&set DVDISO%1=CONSUMER_OEMRET))
)
if %1 equ 2 exit /b

if !ESDmulti%1! equ 0 (set sourcetime=4) else (set sourcetime=!ESDmulti%1!)
for /f "tokens=5-10 delims=: " %%G in ('bin\wimlib-imagex.exe info "!ENCRYPTEDESD!" %sourcetime% ^| find /i "Last Modification Time"') do (set mmm=%%G&set "isotime=%%H/%%L,%%I:%%J:%%K"&set _year=%%L&set _month=%%G&set _day=%%H&set _hour=%%I&set _mint=%%J)
call :setdate %mmm%
call :dateset %_month%

set arch=!ESDarch%1!
set build=!ESDver%1!
set langid=!ESDlang%1!
call :setlabel %1
exit /b

:E_Admin
echo %_err%
echo This script require administrator privileges.
echo To do so, right click on this script and select 'Run as administrator'
echo.
%_Exit%&%_Pause%
exit /b

:E_W81
@cls
echo %_err%
echo This script supports Windows 10 ESDs only.
echo you may use older version 8 to convert Windows 8.1 ESDs.
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
if %_Debug% neq 0 (exit /b) else (echo Press 0 to exit.)
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