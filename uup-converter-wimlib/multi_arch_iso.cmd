<!-- : Begin batch script
@setlocal DisableDelayedExpansion
@echo off
:: 0 - source distributions folders will be directly modified
:: 1 - source distributions folders will be copied then modified
:: if source distributions are .ISO files, this option has no affect
set Preserve=0

:: script:     abbodi1406
:: wimlib:     synchronicity
:: offlinereg: erwan.l
:: aio efisys: cdob

:: ###################################################################

set "_Nul3=1>nul 2>nul"

set _elev=
set _args=%1
if defined _args if "%~1"=="-elevated" set _elev=1

set "SysPath=%SystemRoot%\System32"
if exist "%SystemRoot%\Sysnative\reg.exe" (set "SysPath=%SystemRoot%\Sysnative")
set "xDS=bin\bin64;bin"
if /i %PROCESSOR_ARCHITECTURE%==x86 (if not defined PROCESSOR_ARCHITEW6432 (
  set "xDS=bin"
  )
)
set "Path=%xDS%;%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
set "_err===== ERROR ===="

%_Nul3% reg query HKU\S-1-5-19 && (
  goto :Passed
  ) || (
  if defined _elev goto :E_Admin
)

set _PSarg="""%~f0""" -elevated
set _PSarg=%_PSarg:'=''%

(%_Nul3% cscript //NoLogo "%~f0?.wsf" //job:ELAV /File:"%~f0" -elevated) && (
  exit /b
  ) || (
  call setlocal EnableDelayedExpansion
  %_Nul3% powershell -noprofile -exec bypass -c "start cmd.exe -Arg '/c \"!_PSarg!\"' -verb runas" && (
    exit /b
    ) || (
    goto :E_Admin
  )
)

:Passed
set "_work=%~dp0"
setlocal EnableDelayedExpansion
pushd "!_work!"
set _file=(7z.dll,7z.exe,bcdedit.exe,bfi.exe,cdimage.exe,libwim-15.dll,offlinereg.exe,offreg.dll,wimlib-imagex.exe)
for %%# in %_file% do (
if not exist ".\bin\%%#" (set _bin=%%#&goto :E_Bin)
)

:Begin
title Multi-Architecture ISO
set ERRORTEMP=
set "ramdiskoptions={7619dcc8-fafe-11d9-b411-000476eba25f}"
set combine=0
set custom=0
set winx=1
set "line============================================================="

set _dir64=0
set _dir86=0
set _iso64=0
set _iso86=0

dir /b /ad *amd64* %_Nul3% && (for /f "tokens=* delims=" %%# in ('dir /b /ad *amd64*') do if exist "%%~#\sources\*.wim" (set _dir64=1&set "ISOdir1=%%#"))
dir /b /ad *x64* %_Nul3% && (for /f "tokens=* delims=" %%# in ('dir /b /ad *x64*') do if exist "%%~#\sources\*.wim" (set _dir64=1&set "ISOdir1=%%#"))
dir /b /ad *x32* %_Nul3% && (for /f "tokens=* delims=" %%# in ('dir /b /ad *x32*') do if exist "%%~#\sources\*.wim" (set _dir86=1&set "ISOdir2=%%#"))
dir /b /ad *x86* %_Nul3% && (for /f "tokens=* delims=" %%# in ('dir /b /ad *x86*') do if exist "%%~#\sources\*.wim" (set _dir86=1&set "ISOdir2=%%#"))
if %_dir64% equ 1 if %_dir86% equ 1 goto :DUALMENU

dir /b /a:-d *_amd64*.iso %_Nul3% && (set _iso64=1&for /f "tokens=* delims=" %%# in ('dir /b /a:-d *_amd64*.iso') do set "ISOfile1=%%#")
dir /b /a:-d *_x64*.iso %_Nul3% && (set _iso64=1&for /f "tokens=* delims=" %%# in ('dir /b /a:-d *_x64*.iso') do set "ISOfile1=%%#")
dir /b /a:-d *_x32*.iso %_Nul3% && (set _iso86=1&for /f "tokens=* delims=" %%# in ('dir /b /a:-d *_x32*.iso') do set "ISOfile2=%%#")
dir /b /a:-d *_x86*.iso %_Nul3% && (set _iso86=1&for /f "tokens=* delims=" %%# in ('dir /b /a:-d *_x86*.iso') do set "ISOfile2=%%#")
if %_iso64% equ 1 if %_iso86% equ 1 goto :DUALMENU

:prompt1
cls
set _iso1=
echo %line%
echo Enter / Paste the complete path to 1st ISO file
echo %line%
echo.
set /p _iso1=
if not defined _iso1 goto :QUIT
set "_iso1=%_iso1:"=%"
if not exist "%_iso1%" (
echo.
echo %_err%
echo Specified path is not a valid ISO file
echo.
echo Press any key to continue...
pause >nul
goto :prompt1
)
if /i not "%_iso1:~-4%"==".iso" (
echo.
echo %_err%
echo Specified path is not a valid ISO file
echo.
echo Press any key to continue...
pause >nul
goto :prompt1
)
echo "%_iso1%"| findstr /I /C:"amd64" 1>nul && (set _iso64=1&set "ISOfile1=%_iso1%")
echo "%_iso1%"| findstr /I /C:"x64" 1>nul && (set _iso64=1&set "ISOfile1=%_iso1%")
echo "%_iso1%"| findstr /I /C:"x32" 1>nul && (set _iso86=1&set "ISOfile2=%_iso1%")
echo "%_iso1%"| findstr /I /C:"x86" 1>nul && (set _iso86=1&set "ISOfile2=%_iso1%")

:prompt2
set _iso2=
echo.
echo %line%
echo Enter / Paste the complete path to 2nd ISO file
echo %line%
echo.
set /p _iso2=
if not defined _iso2 goto :QUIT
set "_iso2=%_iso2:"=%"
if not exist "%_iso2%" (
echo.
echo %_err%
echo Specified path is not a valid ISO file
echo.
echo Press any key to continue...
pause >nul
goto :prompt2
)
if /i not "%_iso2:~-4%"==".iso" (
echo.
echo %_err%
echo Specified path is not a valid ISO file
echo.
echo Press any key to continue...
pause >nul
cls
goto :prompt2
)
echo "%_iso2%"| findstr /I /C:"amd64" 1>nul && (set _iso64=1&set "ISOfile1=%_iso2%")
echo "%_iso2%"| findstr /I /C:"x64" 1>nul && (set _iso64=1&set "ISOfile1=%_iso2%")
echo "%_iso2%"| findstr /I /C:"x32" 1>nul && (set _iso86=1&set "ISOfile2=%_iso2%")
echo "%_iso2%"| findstr /I /C:"x86" 1>nul && (set _iso86=1&set "ISOfile2=%_iso2%")

if %_iso64% equ 1 if %_iso86% equ 1 goto :DUALMENU
if %_iso64% equ 0 if %_iso86% equ 0 (set "MESSAGE=could not detect architecture tags"&goto :E_MSG)
if %_iso64% equ 1 if %_iso86% equ 0 (set "MESSAGE=both ISO files are x64"&goto :E_MSG)
if %_iso64% equ 0 if %_iso86% equ 1 (set "MESSAGE=both ISO files are x86"&goto :E_MSG)

:DUALMENU
color 1F
cls
echo %line%
echo. Sources:
echo.
if %_iso64% equ 1 (set Preserve=0&echo "!ISOfile1!"&echo "!ISOfile2!") else (echo "!ISOdir1!"&echo "!ISOdir2!")
echo.
echo %line%
echo. Options:
echo.
echo. 0 - Exit
echo. 1 - Create ISO with 1 combined install.wim/.esd
echo. 2 - Create ISO with 2 separate install.wim/.esd ^(Win 10^)
echo %line%
echo.
choice /c 120 /n /m "Choose a menu option: "
if errorlevel 3 goto :QUIT
if errorlevel 2 (if %_iso64% equ 1 (goto :dISO) else (goto :dCheck))
if errorlevel 1 (set combine=1&set custom=1&if %_iso64% equ 1 (goto :dISO) else (goto :dCheck))
goto :DUALMENU

:dISO
cls
echo.
echo %line%
echo Extracting ISO files . . .
echo %line%
echo.
set "ISOdir1=ISOx64"
set "ISOdir2=ISOx86"
echo "!ISOfile1!"
if exist %ISOdir1%\ rmdir /s /q %ISOdir1%\
7z.exe x "!ISOfile1!" -o%ISOdir1% * -r >nul
echo.
echo "!ISOfile2!"
if exist %ISOdir2%\ rmdir /s /q %ISOdir2%\
7z.exe x "!ISOfile2!" -o%ISOdir2% * -r >nul

:dCheck
if %_iso64% equ 0 cls
echo.
echo %line%
echo Checking distributions Info . . .
echo %line%
for /L %%# in (1,1,2) do (
set ISOmulti%%#=0
set ISOvol%%#=0
set ISOarch%%#=0
set ISOver%%#=0
set ISOlang%%#=0
set BOOTver%%#=0
set WIMFILE%%#=0
)
call :dInfo 1
call :dInfo 2
if /i "%ISOarch1%" equ "%ISOarch2%" (set "MESSAGE=ISO distributions have the same architecture."&goto :E_MSG)
if /i "%ISOver1%" neq "%ISOver2%"   (set "MESSAGE=ISO distributions have different Windows versions."&goto :E_MSG)
if /i "%ISOlang1%" neq "%ISOlang2%" (set "MESSAGE=ISO distributions have different languages."&goto :E_MSG)
if /i "%WIMFILE1%" neq "%WIMFILE2%" (set "MESSAGE=ISO distributions have different install file format."&goto :E_MSG)
if %combine% equ 0 if %winx% equ 0  (set "MESSAGE=ISO with 2 separate install files require Windows 10 setup files"&goto :E_MSG)
set WIMFILE=%WIMFILE1%
echo.
echo %line%
echo Preparing ISO Info . . .
echo %line%
call :dPREPARE 1
call :dPREPARE 2
if exist ISOFOLDER\ rmdir /s /q ISOFOLDER\
mkdir ISOFOLDER
if %Preserve%==1 (
echo.
echo %line%
echo Copying distributions folders . . .
echo %line%
robocopy "!ISOdir1!" "ISOFOLDER\x64" /E /A-:R %_Nul3%
robocopy "!ISOdir2!" "ISOFOLDER\x86" /E /A-:R %_Nul3%
) else (
move "!ISOdir1!" .\ISOFOLDER\x64 %_Nul3%
move "!ISOdir2!" .\ISOFOLDER\x86 %_Nul3%
)
set archl=X86-X64
if /i "%DVDLABEL1%" equ "%DVDLABEL2%" (
set DVDLABEL=%DVDLABEL1%_%archl%FRE_%langid%_DV9
set DVDISO=%_label%%DVDISO1%_%archl%FRE_%langid%
) else (
set DVDLABEL=CCSA_%archl%FRE_%langid%_DV9
set DVDISO=%_label%%DVDISO1%_%ISOarch1%FRE-%DVDISO2%_%ISOarch2%FRE_%langid%
)
if %combine% equ 0 goto :BCD
echo.
echo %line%
echo Unifying %WIMFILE% . . .
echo %line%
echo.
for /f "tokens=3 delims=: " %%# in ('wimlib-imagex.exe info ISOFOLDER\x86\sources\%WIMFILE% ^| findstr /c:"Image Count"') do set imagesi=%%#
for /f "tokens=3 delims=: " %%# in ('wimlib-imagex.exe info ISOFOLDER\x64\sources\%WIMFILE% ^| findstr /c:"Image Count"') do set imagesx=%%#
for /f "tokens=1* delims=: " %%i in ('wimlib-imagex.exe info ISOFOLDER\x86\sources\%WIMFILE% 1 ^| findstr /b "Name"') do set "_osi=%%j x86"
for /f "tokens=1* delims=: " %%i in ('wimlib-imagex.exe info ISOFOLDER\x64\sources\%WIMFILE% 1 ^| findstr /b "Name"') do set "_osx=%%j x64"
if not %imagesi%==1 for /L %%# in (2,1,%imagesi%) do (
for /f "tokens=1* delims=: " %%i in ('wimlib-imagex.exe info ISOFOLDER\x86\sources\%WIMFILE% %%# ^| findstr /b "Name"') do set "_osi%%#=%%j x86"
)
if not %imagesx%==1 for /L %%# in (2,1,%imagesx%) do (
for /f "tokens=1* delims=: " %%i in ('wimlib-imagex.exe info ISOFOLDER\x64\sources\%WIMFILE% %%# ^| findstr /b "Name"') do set "_osx%%#=%%j x64"
)
wimlib-imagex.exe info ISOFOLDER\x86\sources\%WIMFILE% 1 "%_osi%" "%_osi%" --image-property DISPLAYNAME="%_osi%" --image-property DISPLAYDESCRIPTION="%_osi%" %_Nul3%
if not %imagesi%==1 for /L %%# in (2,1,%imagesi%) do (
wimlib-imagex.exe info ISOFOLDER\x86\sources\%WIMFILE% %%# "!_osi%%#!" "!_osi%%#!" --image-property DISPLAYNAME="!_osi%%#!" --image-property DISPLAYDESCRIPTION="!_osi%%#!" %_Nul3%
)
wimlib-imagex.exe info ISOFOLDER\x64\sources\%WIMFILE% 1 "%_osx%" "%_osx%" --image-property DISPLAYNAME="%_osx%" --image-property DISPLAYDESCRIPTION="%_osx%" %_Nul3%
wimlib-imagex.exe export ISOFOLDER\x64\sources\%WIMFILE% 1 ISOFOLDER\x86\sources\%WIMFILE%
if not %imagesx%==1 for /L %%# in (2,1,%imagesx%) do (
wimlib-imagex.exe info ISOFOLDER\x64\sources\%WIMFILE% %%# "!_osx%%#!" "!_osx%%#!" --image-property DISPLAYNAME="!_osx%%#!" --image-property DISPLAYDESCRIPTION="!_osx%%#!" %_Nul3%
wimlib-imagex.exe export ISOFOLDER\x64\sources\%WIMFILE% %%# ISOFOLDER\x86\sources\%WIMFILE%
)

:BCD
echo.
echo %line%
echo Preparing boot configuration settings . . .
echo %line%
echo.
%_Nul3% xcopy ISOFOLDER\x64\boot\* ISOFOLDER\boot\ /cheriy
%_Nul3% xcopy ISOFOLDER\x64\efi\* ISOFOLDER\efi\ /cheriy
%_Nul3% copy /y ISOFOLDER\x64\bootmgr* ISOFOLDER\
%_Nul3% copy /y ISOFOLDER\x86\boot\bootsect.exe ISOFOLDER\boot\
set "BCDBIOS=ISOFOLDER\boot\bcd"
set "BCDUEFI=ISOFOLDER\efi\microsoft\boot\bcd"
if %custom%==0 (
%_Nul3% copy /y ISOFOLDER\x86\setup.exe ISOFOLDER\
set "entry64=[boot]\x64\sources\boot.wim,%ramdiskoptions%"
set "entry86=[boot]\x86\sources\boot.wim,%ramdiskoptions%"
(echo [AutoRun.Amd64]
echo open=x64\setup.exe
echo icon=x64\setup.exe,0
echo.
echo [AutoRun]
echo open=x86\setup.exe
echo icon=x86\setup.exe,0
echo.)>ISOFOLDER\autorun.inf
) else (
set "entry64=[boot]\sources\bootx64.wim,%ramdiskoptions%"
set "entry86=[boot]\sources\bootx86.wim,%ramdiskoptions%"
)
for /f "tokens=5-10 delims=: " %%G in ('wimlib-imagex.exe info ISOFOLDER\x64\sources\boot.wim 2 ^| find /i "Last Modification Time"') do (set mmm=%%G&set "isotime=%%H/%%L,%%I:%%J:%%K")
call :setdate %mmm%
%_Nul3% bcdedit /store %BCDBIOS% /set {bootmgr} nointegritychecks Yes
%_Nul3% bcdedit /store %BCDBIOS% /set {default} description "Windows Setup (64-bit) - BIOS"
%_Nul3% bcdedit /store %BCDBIOS% /set {default} device ramdisk=%entry64%
%_Nul3% bcdedit /store %BCDBIOS% /set {default} osdevice ramdisk=%entry64%
%_Nul3% bcdedit /store %BCDBIOS% /set {default} nointegritychecks Yes
%_Nul3% bcdedit /store %BCDBIOS% /set {default} nx OptIn
%_Nul3% bcdedit /store %BCDBIOS% /set {default} pae Default
%_Nul3% bcdedit /store %BCDBIOS% /set {default} ems No
%_Nul3% bcdedit /store %BCDBIOS% /deletevalue {default} bootmenupolicy
for /f "tokens=2 delims={}" %%# in ('bcdedit /store %BCDBIOS% /copy {default} /d "Windows Setup (32-bit) - BIOS"') do set "guid={%%#}"
%_Nul3% bcdedit /store %BCDBIOS% /set %guid% device ramdisk=%entry86%
%_Nul3% bcdedit /store %BCDBIOS% /set %guid% osdevice ramdisk=%entry86%
%_Nul3% bcdedit /store %BCDBIOS% /timeout 30
%_Nul3% attrib -s -h -a "%BCDBIOS%.LOG*"
%_Nul3% del /f /q "%BCDBIOS%.LOG*"
%_Nul3% bcdedit /store %BCDUEFI% /set {default} description "Windows Setup (64-bit) - UEFI"
%_Nul3% bcdedit /store %BCDUEFI% /set {default} device ramdisk=%entry64%
%_Nul3% bcdedit /store %BCDUEFI% /set {default} osdevice ramdisk=%entry64%
%_Nul3% bcdedit /store %BCDUEFI% /set {default} isolatedcontext Yes
%_Nul3% bcdedit /store %BCDUEFI% /set {default} nx OptIn
%_Nul3% bcdedit /store %BCDUEFI% /set {default} ems No
%_Nul3% attrib -s -h -a "%BCDUEFI%.LOG*"
%_Nul3% del /f /q "%BCDUEFI%.LOG*"
if not exist ISOFOLDER\efi\boot\bootx64.efi (
wimlib-imagex.exe extract ISOFOLDER\x64\sources\boot.wim 1 Windows\Boot\EFI\bootmgfw.efi --dest-dir=.\ISOFOLDER\efi\boot --no-acls --no-attribute %_Nul3%
rename ISOFOLDER\efi\boot\bootmgfw.efi bootx64.efi
)
if not exist ISOFOLDER\efi\microsoft\boot\memtest.efi (
wimlib-imagex.exe extract ISOFOLDER\x64\sources\boot.wim 1 Windows\Boot\EFI\memtest.efi --dest-dir=.\ISOFOLDER\efi\microsoft\boot --no-acls --no-attributes %_Nul3%
del /f /q ISOFOLDER\boot\memtest.efi %_Nul3%
bcdedit /store %BCDUEFI% /enum all | findstr /i {memdiag} 1>nul || (
  %_Nul3% bcdedit /store %BCDUEFI% /create {memdiag}
  %_Nul3% bcdedit /store %BCDUEFI% /set {memdiag} description "Windows Memory Diagnostic"
  %_Nul3% bcdedit /store %BCDUEFI% /set {memdiag} device boot
  %_Nul3% bcdedit /store %BCDUEFI% /set {memdiag} path \efi\microsoft\boot\memtest.efi
  %_Nul3% bcdedit /store %BCDUEFI% /set {memdiag} locale en-US
  %_Nul3% bcdedit /store %BCDUEFI% /set {memdiag} inherit {globalsettings}
  %_Nul3% bcdedit /store %BCDUEFI% /toolsdisplayorder {memdiag} /addlast
  )
)
if %custom%==0 goto :ISOCREATE
echo.
echo %line%
echo Preparing Custom AIO settings . . .
echo %line%
echo.
mkdir ISOFOLDER\sources
%_Nul3% move /y ISOFOLDER\x64\sources\boot.wim ISOFOLDER\sources\bootx64.wim
%_Nul3% move /y ISOFOLDER\x86\sources\boot.wim ISOFOLDER\sources\bootx86.wim
%_Nul3% move /y ISOFOLDER\x86\sources\%WIMFILE% ISOFOLDER\sources\
%_Nul3% move /y ISOFOLDER\x86\sources\lang.ini ISOFOLDER\sources\
call :dSETUP x64
call :dSETUP x86
if not exist "ISOFOLDER\x86\efi\boot\bootia32.efi" (
%_Nul3% rmdir /s /q ISOFOLDER\x64\
%_Nul3% rmdir /s /q ISOFOLDER\x86\
goto :ISOCREATE
)
%_Nul3% copy /y ISOFOLDER\x86\efi\boot\bootia32.efi ISOFOLDER\efi\boot\
%_Nul3% copy /y ISOFOLDER\x86\efi\microsoft\boot\memtest.efi ISOFOLDER\efi\microsoft\boot\memtestx86.efi
%_Nul3% rename ISOFOLDER\efi\microsoft\boot\memtest.efi memtestx64.efi
%_Nul3% bcdedit /store %BCDUEFI% /deletevalue {default} bootmenupolicy
for /f "tokens=2 delims={}" %%# in ('bcdedit /store %BCDUEFI% /copy {default} /d "Windows Setup (32-bit) - UEFI"') do set "guid={%%#}"
%_Nul3% bcdedit /store %BCDUEFI% /set %guid% device ramdisk=%entry86%
%_Nul3% bcdedit /store %BCDUEFI% /set %guid% osdevice ramdisk=%entry86%
%_Nul3% bcdedit /store %BCDUEFI% /timeout 30
%_Nul3% bcdedit /store %BCDUEFI% /set {memdiag} description "Windows Memory Diagnostic (64-bit)"
%_Nul3% bcdedit /store %BCDUEFI% /set {memdiag} path \efi\microsoft\boot\memtestx64.efi
for /f "tokens=2 delims={}" %%# in ('bcdedit /store %BCDUEFI% /copy {memdiag} /d "Windows Memory Diagnostic (32-bit)"') do set "guid={%%#}"
%_Nul3% bcdedit /store %BCDUEFI% /set %guid% path \efi\microsoft\boot\memtestx86.efi
%_Nul3% bcdedit /store %BCDUEFI% /toolsdisplayorder %guid% /addlast
%_Nul3% attrib -s -h -a "%BCDUEFI%.LOG*"
%_Nul3% del /f /q "%BCDUEFI%.LOG*"
%_Nul3% 7z.exe x ISOFOLDER\efi\microsoft\boot\efisys.bin -o.\bin\temp\
%_Nul3% copy /y ISOFOLDER\efi\boot\bootia32.efi bin\temp\EFI\Boot\BOOTIA32.EFI
%_Nul3% bfi.exe -t=288 -l=EFISECTOR -f=bin\efisys.ima bin\temp
%_Nul3% move /y bin\efisys.ima ISOFOLDER\efi\microsoft\boot\efisys.bin
%_Nul3% del /f /q ISOFOLDER\efi\microsoft\boot\*noprompt.*
%_Nul3% rmdir /s /q bin\temp\
%_Nul3% rmdir /s /q ISOFOLDER\x64\
%_Nul3% rmdir /s /q ISOFOLDER\x86\

:ISOCREATE
echo.
echo %line%
echo Creating ISO . . .
echo %line%
if exist "ISOFOLDER\efi\microsoft\boot\efisys.bin" (
cdimage.exe -bootdata:2#p0,e,b"ISOFOLDER\boot\etfsboot.com"#pEF,e,b"ISOFOLDER\efi\Microsoft\boot\efisys.bin" -o -m -u2 -udfver102 -t%isotime% -g -l%DVDLABEL% ISOFOLDER %DVDISO%.ISO
) else (
cdimage.exe -b"ISOFOLDER\boot\etfsboot.com" -o -m -u2 -udfver102 -t%isotime% -g -l%DVDLABEL% ISOFOLDER %DVDISO%.ISO
)
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 (
  ren ISOFOLDER %DVDISO%
  echo.
  echo Errors were reported during ISO creation.
  echo.
  echo Press any key to exit.
  pause >nul
  goto :QUIT
)
rmdir /s /q ISOFOLDER\
echo.
echo Press any key to exit.
pause >nul
goto :QUIT

:dSETUP
(
echo [LaunchApps]
echo ^%%SystemRoot^%%\system32\wpeinit.exe
echo ^%%SystemDrive^%%\sources\setup%1.exe
echo.
)>bin\winpeshl.ini
for /f %%# in ('wimlib-imagex.exe dir ISOFOLDER\sources\boot%1.wim 2 --path=\sources ^| find /i "setup.exe.mui"') do wimlib-imagex.exe update ISOFOLDER\sources\boot%1.wim 2 --command="rename '%%#' '%%~p#setup%1.exe.mui'" %_Nul3%
%_Nul3% wimlib-imagex.exe update ISOFOLDER\sources\boot%1.wim 2 --command="rename 'sources\setup.exe' 'sources\setup%1.exe'"
%_Nul3% wimlib-imagex.exe update ISOFOLDER\sources\boot%1.wim 2 --command="add 'bin\winpeshl.ini' '\Windows\system32\winpeshl.ini'"
%_Nul3% wimlib-imagex.exe extract ISOFOLDER\sources\boot%1.wim 2 sources\setup%1.exe --dest-dir=.\ISOFOLDER\sources --no-acls --no-attributes
%_Nul3% del /f /q bin\winpeshl.ini
exit /b

:dInfo
if not exist "!ISOdir%1!\sources\boot.wim" (set "MESSAGE=ISO %1 is missing boot.wim"&goto :E_MSG)
dir /b "!ISOdir%1!\sources\install.wim" %_Nul3% && (set WIMFILE%1=install.wim)
dir /b "!ISOdir%1!\sources\install.esd" %_Nul3% && (set WIMFILE%1=install.esd)
if /i !WIMFILE%1! equ 0 (set "MESSAGE=ISO %1 is missing install.wim/install.esd"&goto :E_MSG)
wimlib-imagex.exe info "!ISOdir%1!\sources\!WIMFILE%1!">bin\infoall.txt 2>&1
find /i "CoreCountrySpecific" bin\infoall.txt 1>nul && (set ISOeditionc%1=1) || (set ISOeditionc%1=0)
wimlib-imagex.exe info "!ISOdir%1!\sources\!WIMFILE%1!" 1 >bin\info.txt 2>&1
for /f "tokens=2 delims=: " %%# in ('findstr /i /b "Build" bin\info.txt') do set ISOver%1=%%#
for /f "tokens=3 delims=: " %%# in ('findstr /i /b "Edition" bin\info.txt') do set ISOedition%1=%%#
for /f "tokens=3 delims=: " %%# in ('findstr /i "Default" bin\info.txt') do set ISOlang%1=%%#
for /f "tokens=2 delims=: " %%# in ('findstr /i "Architecture" bin\info.txt') do (if /i %%# equ x86 (set ISOarch%1=x86) else if /i %%# equ x86_64 (set ISOarch%1=x64))
for /f "tokens=3 delims=: " %%# in ('findstr /i /b /c:"Image Count" bin\infoall.txt') do (if %%# geq 2 set ISOmulti%1=%%#)
for /f "tokens=2 delims=: " %%# in ('wimlib-imagex.exe info "!ISOdir%1!\sources\boot.wim" 1 ^| findstr /i /b "Build"') do set BOOTver%1=%%#
if /i !BOOTver%1! lss 10240 (set winx=0)
if /i !ISOarch%1! equ 0 (set "MESSAGE=ISO %1 architecture is not supported."&goto :E_MSG)
if exist "!ISOdir%1!\sources\ei.cfg" type "!ISOdir%1!\sources\ei.cfg" 2>nul | find /i "Volume" 1>nul && set ISOvol%1=1
del /f /q bin\info*.txt
exit /b

:dPREPARE
set DVDLABEL%1=CCSA&set DVDISO%1=!ISOedition%1!_OEMRET
if /i !ISOedition%1!==Core set DVDLABEL%1=CCRA&set DVDISO%1=CORE_OEMRET
if /i !ISOedition%1!==CoreN set DVDLABEL%1=CCRNA&set DVDISO%1=COREN_OEMRET
if /i !ISOedition%1!==CoreSingleLanguage set DVDLABEL%1=CSLA&set DVDISO%1=SINGLELANGUAGE_OEM
if /i !ISOedition%1!==CoreCountrySpecific set DVDLABEL%1=CCHA&set DVDISO%1=CHINA_OEM
if /i !ISOedition%1!==Professional (IF !ISOvol%1!==1 (set DVDLABEL%1=CPRA&set DVDISO%1=PROFESSIONALVL_VOL) else (set DVDLABEL%1=CPRA&set DVDISO%1=PRO_OEMRET))
if /i !ISOedition%1!==ProfessionalN (IF !ISOvol%1!==1 (set DVDLABEL%1=CPRNA&set DVDISO%1=PROFESSIONALNVL_VOL) else (set DVDLABEL%1=CPRNA&set DVDISO%1=PRON_OEMRET))
if /i !ISOedition%1!==Education (IF !ISOvol%1!==1 (set DVDLABEL%1=CEDA&set DVDISO%1=EDUCATION_VOL) else (set DVDLABEL%1=CEDA&set DVDISO%1=EDUCATION_RET))
if /i !ISOedition%1!==EducationN (IF !ISOvol%1!==1 (set DVDLABEL%1=CEDNA&set DVDISO%1=EDUCATIONN_VOL) else (set DVDLABEL%1=CEDNA&set DVDISO%1=EDUCATIONN_RET))
if /i !ISOedition%1!==Enterprise set DVDLABEL%1=CENA&set DVDISO%1=ENTERPRISE_VOL
if /i !ISOedition%1!==EnterpriseN set DVDLABEL%1=CENNA&set DVDISO%1=ENTERPRISEN_VOL
if /i !ISOedition%1!==PPIPro set DVDLABEL%1=CPPIA&set DVDISO%1=PPIPRO_OEM
if /i !ISOedition%1!==Cloud set DVDLABEL%1=CWCA&set DVDISO%1=CLOUD_OEM
if /i !ISOedition%1!==CloudN set DVDLABEL%1=CWCNNA&set DVDISO%1=CLOUDN_OEM
if /i !ISOedition%1!==EnterpriseG set DVDLABEL%1=CEGA&set DVDISO%1=ENTERPRISEG_VOL
if /i !ISOedition%1!==EnterpriseGN set DVDLABEL%1=CEGNA&set DVDISO%1=ENTERPRISEGN_VOL
if /i !ISOedition%1!==EnterpriseS set DVDLABEL%1=CES&set DVDISO%1=ENTERPRISES_VOL
if /i !ISOedition%1!==EnterpriseSN set DVDLABEL%1=CESNN&set DVDISO%1=ENTERPRISESN_VOL
if /i !ISOedition%1!==ProfessionalEducation (if !ISOvol%1!==1 (set DVDLABEL%1=CPREA&set DVDISO%1=PROEDUCATION_VOL) else (set DVDLABEL%1=CPREA&set DVDISO%1=PROEDUCATION_OEMRET))
if /i !ISOedition%1!==ProfessionalEducationN (if !ISOvol%1!==1 (set DVDLABEL%1=CPRENA&set DVDISO%1=PROEDUCATIONN_VOL) else (set DVDLABEL%1=CPRENA&set DVDISO%1=PROEDUCATIONN_OEMRET))
if /i !ISOedition%1!==ProfessionalWorkstation (if !ISOvol%1!==1 (set DVDLABEL%1=CPRWA&set DVDISO%1=PROWORKSTATION_VOL) else (set DVDLABEL%1=CPRWA&set DVDISO%1=PROWORKSTATION_OEMRET))
if /i !ISOedition%1!==ProfessionalWorkstationN (if !ISOvol%1!==1 (set DVDLABEL%1=CPRWNA&set DVDISO%1=PROWORKSTATIONN_VOL) else (set DVDLABEL%1=CPRWNA&set DVDISO%1=PROWORKSTATIONN_OEMRET))
if /i !ISOedition%1!==ProfessionalSingleLanguage set DVDLABEL%1=CPRSLA&set DVDISO%1=PROSINGLELANGUAGE_OEM
if /i !ISOedition%1!==ProfessionalCountrySpecific set DVDLABEL%1=CPRCHA&set DVDISO%1=PROCHINA_OEM
IF !ISOmulti%1! geq 2 (
set DVDLABEL%1=CCSA&set DVDISO%1=MULTI_OEMRET
if !ISOeditionc%1!==1 set DVDLABEL%1=CCCHA&set DVDISO%1=MULTICHINA_OEMRET
)
if /i !ISOarch%1!==x86 (set ISOarch%1=X86) else (set ISOarch%1=X64)
if %1==2 exit /b

wimlib-imagex.exe extract "!ISOdir%1!\sources\%WIMFILE%" 1 \Windows\System32\ntoskrnl.exe --dest-dir=.\bin\temp --no-acls --no-attributes %_Nul3%
7z.exe l .\bin\temp\ntoskrnl.exe >.\bin\temp\version.txt 2>&1
for /f "tokens=4-7 delims=.() " %%i in ('"findstr /i /b "FileVersion" .\bin\temp\version.txt" 2^>nul') do (set version=%%i.%%j&set vermajor=%%i&set verminor=%%j&set branch=%%k&set datetime=%%l)
set revision=%version%&set revmajor=%vermajor%&set revminor=%verminor%
if /i !ISOarch%1!==x86 (set _ss=x86) else if /i !ISOarch%1!==x64 (set _ss=amd64)
if !ISOver%1! geq 10240 (
wimlib-imagex.exe extract "!ISOdir%1!\sources\%WIMFILE%" 1 Windows\WinSxS\Manifests\%_ss%_microsoft-windows-coreos-revision* --dest-dir=.\bin\temp --no-acls --no-attributes %_Nul3%
for /f "tokens=6,7 delims=_." %%i in ('dir /b /od .\bin\temp\*.manifest') do set revision=%%i.%%j&set revmajor=%%i&set revminor=%%j
if !verminor! lss !revminor! (
  set version=!revision!
  for /f "tokens=5-10 delims=: " %%G in ('wimlib-imagex.exe info "!ISOdir%1!\sources\%WIMFILE%" 1 ^| find /i "Last Modification Time"') do (set mmm=%%G&set yyy=%%L&set ddd=%%H-%%I%%J)
  call :setmmm !mmm!
  )
)
set _label2=
if /i "%branch%"=="WinBuild" (
wimlib-imagex.exe extract "!ISOdir%1!\sources\%WIMFILE%" 1 Windows\System32\config\SOFTWARE --dest-dir=.\bin\temp --no-acls --no-attributes >nul
for /f "tokens=3 delims==:" %%# in ('"offlinereg.exe .\bin\temp\SOFTWARE "Microsoft\Windows NT\CurrentVersion" getvalue BuildLabEx" 2^>nul') do if not errorlevel 1 (for /f "tokens=1-5 delims=." %%i in ('echo %%~#') do set _label2=%%i.%%j.%%m.%%l_CLIENT&set branch=%%l)
)
if defined _label2 (set _label=%_label2%) else (set _label=%version%.%datetime%.%branch%_CLIENT)
rmdir /s /q bin\temp\

set langid=!ISOlang%1!
for %%# in (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do (
set _label=!_label:%%#=%%#!
set langid=!langid:%%#=%%#!
)
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

:setmmm
if /i %1==Jan set "datetime=%yyy:~2%01%ddd%"
if /i %1==Feb set "datetime=%yyy:~2%02%ddd%"
if /i %1==Mar set "datetime=%yyy:~2%03%ddd%"
if /i %1==Apr set "datetime=%yyy:~2%04%ddd%"
if /i %1==May set "datetime=%yyy:~2%05%ddd%"
if /i %1==Jun set "datetime=%yyy:~2%06%ddd%"
if /i %1==Jul set "datetime=%yyy:~2%07%ddd%"
if /i %1==Aug set "datetime=%yyy:~2%08%ddd%"
if /i %1==Sep set "datetime=%yyy:~2%09%ddd%"
if /i %1==Oct set "datetime=%yyy:~2%10%ddd%"
if /i %1==Nov set "datetime=%yyy:~2%11%ddd%"
if /i %1==Dec set "datetime=%yyy:~2%12%ddd%"
exit /b

:E_Admin
echo %_err%
echo This script require administrator privileges.
echo To do so, right click on this script and select 'Run as administrator'
echo.
echo Press any key to exit.
pause >nul
exit /b

:E_Bin
echo %_err%
echo Required file %_bin% is missing.
echo.
echo Press any key to exit.
pause >nul
exit /b

:E_MSG
echo.
echo %line%
echo %_err%
echo %MESSAGE%
echo.
echo.
echo Press any key to exit.
pause >nul

:QUIT
if exist bin\temp\ rmdir /s /q bin\temp\
if exist ISOFOLDER\ rmdir /s /q ISOFOLDER\
if exist ISOx64\ rmdir /s /q ISOx64\
if exist ISOx86\ rmdir /s /q ISOx86\
popd
echo Press 0 to exit.
choice /c 0 /n
if errorlevel 1 (exit) else (rem.)

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