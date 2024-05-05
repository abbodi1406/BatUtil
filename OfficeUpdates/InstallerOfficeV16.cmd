@setlocal EnableExtensions DisableDelayedExpansion
@echo off
:: change to 1 to enable debug mode
set _Debug=0

set "_Null=1>nul 2>nul"
set "_args=%*"
if not defined _args goto :NoProgArgs
if "%~1"=="" set "_args="&goto :NoProgArgs
set _args=%_args:"=%
for %%A in (%_args%) do (
if /i "%%A"=="-wow" (set _rel1=1
) else if /i "%%A"=="-arm" (set _rel2=1
) else (set "_loc=%%A")
)

:NoProgArgs
set "_cf=%~f0"
if exist "%SystemRoot%\Sysnative\cmd.exe" if not defined _rel1 (
setlocal EnableDelayedExpansion
start %SystemRoot%\Sysnative\cmd.exe /c ""!_cf!" -wow %*"
exit /b
)
if exist "%SystemRoot%\SysArm32\cmd.exe" if /i %PROCESSOR_ARCHITECTURE%==AMD64 if not defined _rel2 (
setlocal EnableDelayedExpansion
start %SystemRoot%\SysArm32\cmd.exe /c ""!_cf!" -arm %*"
exit /b
)
set "SysPath=%SystemRoot%\System32"
set "Path=%SystemRoot%\System32;%SystemRoot%\System32\Wbem"
if exist "%SystemRoot%\Sysnative\reg.exe" (
set "SysPath=%SystemRoot%\Sysnative"
set "Path=%SystemRoot%\Sysnative;%SystemRoot%\Sysnative\Wbem;%Path%"
)
set "_err===== ERROR ===="

SET _down=0
VER|FINDSTR /C:" 5." >NUL && SET _down=1
SET WINMAJ=0
FOR /F "TOKENS=2 DELIMS=[]" %%G IN ('VER') DO FOR /F "TOKENS=2,3 DELIMS=. " %%H IN ("%%~G") DO SET "WINMAJ=%%H"
IF %WINMAJ% LSS 6 SET _down=1
SET _xp=0
REG.EXE QUERY "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuildNumber |FINDSTR /C:"2600" >NUL && SET _xp=1
set _sk=2
if %_xp% equ 1 set _sk=4

if %_down% equ 0 reg.exe query "HKU\S-1-5-19" %_Null% || (
echo ==== ERROR ====
echo This script require administrator privileges.
echo To do so, right click on this script and select 'Run as administrator'
echo.
echo Press any key to exit.
pause >nul
goto :eof
)

set "arch=x64"
if /i "%PROCESSOR_ARCHITECTURE%"=="x86" if "%PROCESSOR_ARCHITEW6432%"=="" set "arch=x86"

set "_temp=%temp%"
set "_log=%~dpn0"
set "_work=%~dp0"
set "_work=%_work:~0,-1%"
if %_down% equ 0 (
for /f "skip=2 tokens=2*" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop') do call set "_dsk=%%b"
if exist "%PUBLIC%\Desktop\desktop.ini" set "_dsk=%PUBLIC%\Desktop"
)
if %_down% equ 1 (
if exist "%USERPROFILE%\Desktop\" (
set "_log=%USERPROFILE%\Desktop\%~n0"
) else if exist "%ALLUSERSPROFILE%\Desktop\" (
set "_log=%ALLUSERSPROFILE%\Desktop\%~n0"
) else (
set "_log=%SystemDrive%\%~n0"
)
)

setlocal EnableDelayedExpansion
copy /y nul "!_work!\#.rw" %_Null% && (
if exist "!_work!\#.rw" del /f /q "!_work!\#.rw"
) || (
set "_log=!_dsk!\%~n0"
if %_down% equ 1 set "_log=!_temp!\%~n0"
)
cd /d "!_work!"

if %_Debug% EQU 0 (
  set "_Nul1=1>nul"
  set "_Nul2=2>nul"
  set "_Nul6=2^>nul"
  set "_Nul3=1>nul 2>nul"
  set "_Pause=pause >nul"
  goto :Begin
)
  set "_Nul1="
  set "_Nul2="
  set "_Nul6="
  set "_Nul3="
  set "_Pause="
echo.
echo Running in Debug Mode...
echo The window will be closed when finished
@echo on
@prompt $G
@call :Begin >"!_log!_tmp.log" 2>&1 &cmd /u /c type "!_log!_tmp.log">"!_log!_Debug.log"&del "!_log!_tmp.log"
@title %ComSpec%
@echo off
@exit /b

:Begin
title Microsoft Office Updates Installer v16 by Burf
if exist "!_temp!\*.burf" del /f /q "!_temp!\*.burf"
if exist "!_temp!\*.msp" del /f /q "!_temp!\*.msp"
set prodver2007=12.0.4518.1014
set prodver2010=14.0.4763.1000
set prodver2013=15.0.4420.1017
set prodver2016=16.0.4266.1001
set sp2007=3
set sp2010=2
set sp2013=1
set _z=0

:office2007check
if %arch%==x86 for /f "skip=%_sk% tokens=1,2*" %%i in ('"reg.exe query HKLM\SOFTWARE\Microsoft\Office\12.0\Common\InstallRoot /v Path" %_Nul6%') do if /i "%%i"=="Path" if not "%%~k"=="" if exist "%%~k\addins\otkloadr*.dll" (
set off2007reg=HKLM\SOFTWARE\Microsoft\Office\12.0\Common
set office2007=x86&set /a _z+=1&set office2007b=32-bit {x86}
goto :office2010check
)
if %arch%==x64 for /f "skip=2 tokens=2*" %%a in ('"reg.exe query HKLM\SOFTWARE\Wow6432Node\Microsoft\Office\12.0\Common\InstallRoot /v Path" %_Nul6%') do if exist "%%b\addins\otkloadr*.dll" (
set off2007reg=HKLM\SOFTWARE\Wow6432Node\Microsoft\Office\12.0\Common
set office2007=x86&set /a _z+=1&set office2007b=32-bit {x86}
goto :office2010check
)

:office2010check
for /f "skip=%_sk% tokens=1,2*" %%i in ('"reg.exe query HKLM\SOFTWARE\Microsoft\Office\14.0\Common\InstallRoot /v Path" %_Nul6%') do if /i "%%i"=="Path" if not "%%~k"=="" if exist "%%~k\OSPP.VBS" (
set off2010reg=HKLM\SOFTWARE\Microsoft\Office\14.0\Common
if %arch%==x64 (set office2010=x64&set /a _z+=1&set office2010b=64-bit {x64}) else (set office2010=x86&set /a _z+=1&set office2010b=32-bit {x86})
goto :office2013check
)
if %arch%==x64 for /f "skip=2 tokens=2*" %%a in ('"reg.exe query HKLM\SOFTWARE\Wow6432Node\Microsoft\Office\14.0\Common\InstallRoot /v Path" %_Nul6%') do if exist "%%b\OSPP.VBS" (
set off2010reg=HKLM\SOFTWARE\Wow6432Node\Microsoft\Office\14.0\Common
set office2010=x86&set /a _z+=1&set office2010b=32-bit {x86}
goto :office2013check
)

:office2013check
if %_down% equ 1 goto :checkdone
for /f "skip=2 tokens=2*" %%a in ('"reg.exe query HKLM\SOFTWARE\Microsoft\Office\15.0\Common\InstallRoot /v Path" %_Nul6%') do if exist "%%b\OSPP.VBS" (
set off2013reg=HKLM\SOFTWARE\Microsoft\Office\15.0\Common
if %arch%==x64 (set office2013=x64&set /a _z+=1&set office2013b=64-bit {x64}) else (set office2013=x86&set /a _z+=1&set office2013b=32-bit {x86})
goto :office2016check
)
if %arch%==x64 for /f "skip=2 tokens=2*" %%a in ('"reg.exe query HKLM\SOFTWARE\Wow6432Node\Microsoft\Office\15.0\Common\InstallRoot /v Path" %_Nul6%') do if exist "%%b\OSPP.VBS" (
set off2013reg=HKLM\SOFTWARE\Wow6432Node\Microsoft\Office\15.0\Common
set office2013=x86&set /a _z+=1&set office2013b=32-bit {x86}
goto :office2016check
)

:office2016check
for /f "skip=2 tokens=2*" %%a in ('"reg.exe query HKLM\SOFTWARE\Microsoft\Office\16.0\Common\InstallRoot /v Path" %_Nul6%') do if exist "%%b\OSPP.VBS" (
set off2016reg=HKLM\SOFTWARE\Microsoft\Office\16.0\Common
if %arch%==x64 (set office2016=x64&set /a _z+=1&set office2016b=64-bit {x64}) else (set office2016=x86&set /a _z+=1&set office2016b=32-bit {x86})
goto :checkdone
)
if %arch%==x64 for /f "skip=2 tokens=2*" %%a in ('"reg.exe query HKLM\SOFTWARE\Wow6432Node\Microsoft\Office\16.0\Common\InstallRoot /v Path" %_Nul6%') do if exist "%%b\OSPP.VBS" (
set off2016reg=HKLM\SOFTWARE\Wow6432Node\Microsoft\Office\16.0\Common
set office2016=x86&set /a _z+=1&set office2016b=32-bit {x86}
goto :checkdone
)

:checkdone
@cls
if %_z% equ 0 goto :notinstalled

:vercheck
if not defined office2007 goto :office2010ver
for /f "skip=%_sk% tokens=1,2*" %%i in ('reg.exe query %off2007reg%\ProductVersion /v LastProduct') do if /i "%%i"=="LastProduct" if not "%%~k"=="" set "prodver2007=%%~k"
if not defined office2010 if not defined office2013 if not defined office2016 if not defined spinstglb goto :top

:office2010ver
if not defined office2010 goto :office2013ver
for /f "skip=%_sk% tokens=1,2*" %%i in ('reg.exe query %off2010reg%\ProductVersion /v LastProduct') do if /i "%%i"=="LastProduct" if not "%%~k"=="" set "prodver2010=%%~k"
if not defined office2013 if not defined office2016 if not defined spinstglb goto :top

:office2013ver
if %_down% equ 1 goto :officespchk
if not defined office2013 goto :office2016ver
for /f "skip=2 tokens=2*" %%a in ('reg.exe query %off2013reg%\ProductVersion /v LastProduct') do (set prodver2013=%%b)
if not defined office2016 if not defined spinstglb goto :top

:office2016ver
if not defined office2016 goto :officespchk
for /f "skip=2 tokens=2*" %%a in ('reg.exe query %off2016reg%\ProductVersion /v LastProduct') do (set prodver2016=%%b)

:officespchk
if defined spinstglb goto :spdone

:top
if defined _loc cd /d "%_loc%"

if %_Debug% EQU 0 (
echo If this message appears for an extended period of time, it is 
echo recommended that you close this script.
echo.
echo Please move the script to a folder that is closer to the location
echo of the Office updates.
echo.
echo If using WHDownloader, it is recommended that you place this script
echo in the same location as the WHDownloader.exe file
)

if defined office2007 (
for /f "delims=" %%G in ('dir /b /s *2007*kb*fullfile*.exe %_Nul6%') do (echo %%G>>"!_temp!\update4.burf")
for /f "delims=" %%G in ('dir /b /s *2007*kb*fullfile*.cab %_Nul6%') do (echo %%G>>"!_temp!\update4.burf")
if exist "!_temp!\update4.burf" (
pushd "!_temp!"
findstr /i /v "kb2526086 kb2526091 kb2526291 kb2526293 kb2526089" "update4.burf" >"update4a.burf"
findstr /i /v "superseded" "update4a.burf" >"filelist4.burf"
for /f %%G in ('type "filelist4.burf"') do (call set /a _c+=1)
popd
)
)

if defined office2010 (
for /f "delims=" %%G in ('dir /b /s *2010*%office2010%*.exe %_Nul6%') do (echo %%G>>"!_temp!\update1.burf")
for /f "delims=" %%G in ('dir /b /s *2010*%office2010%*.cab %_Nul6%') do (echo %%G>>"!_temp!\update1.burf")
if exist "!_temp!\update1.burf" (
pushd "!_temp!"
findstr /i /v "kb2687455 kb2687449 kb2687457 kb2687468 kb2687458 kb2687463" "update1.burf" >"update1a.burf"
findstr /i /v "superseded" "update1a.burf" >"filelist1.burf"
for /f %%G in ('type "filelist1.burf"') do (call set /a _c+=1)
popd
)
)

if defined office2013 (
for /f "delims=" %%G in ('dir /b /s *2013*%office2013%*.exe %_Nul6%') do (echo %%G>>"!_temp!\update2.burf")
for /f "delims=" %%G in ('dir /b /s *2013*%office2013%*.cab %_Nul6%') do (echo %%G>>"!_temp!\update2.burf")
if exist "!_temp!\update2.burf" (
pushd "!_temp!"
findstr /i /v "kb2817430 kb2817427 kb2817433 kb2817443 kb2817435 kb2817441" "update2.burf" >"update2a.burf"
findstr /i /v "superseded" "update2a.burf" >"filelist2.burf"
for /f %%G in ('type "filelist2.burf"') do (call set /a _c+=1)
popd
)
)

if defined office2016 (
for /f "delims=" %%G in ('dir /b /s *2016*%office2016%*.exe %_Nul6%') do (echo %%G>>"!_temp!\update3.burf")
for /f "delims=" %%G in ('dir /b /s *2016*%office2016%*.cab %_Nul6%') do (echo %%G>>"!_temp!\update3.burf")
if exist "!_temp!\update3.burf" (
pushd "!_temp!"
findstr /i /v "kb923618" "update3.burf" >"update3a.burf"
findstr /i /v "superseded" "update3a.burf" >"filelist3.burf"
for /f %%G in ('type "filelist3.burf"') do (call set /a _c+=1)
popd
)
)

if defined office2007 if %prodver2007:~5,4% lss 6612 set sp2007=0
if defined office2010 if %prodver2010:~5,4% lss 7015 set sp2010=0
if defined office2013 if %prodver2013:~5,4% lss 4569 set sp2013=0

set /a _sp=sp2007+sp2010+sp2013 %_Nul1%
if %_sp% neq 6 (goto :spinstall)

if not defined _c (goto :nofiles)

pushd "!_temp!"
if %_down% equ 0 reg.exe query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products" /f "(KB" /s /d 1>"widb.burf" %_Nul2%
if %_down% equ 1 reg.exe query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products" /s | find /i " (KB" 1>"widb.burf" %_Nul2%
find /i "Update" "widb.burf" >"widb2.burf"
find /i "Hotfix" "widb.burf" >>"widb2.burf
for /f "delims=() tokens=2" %%G in ('type "widb2.burf"') do (echo %%G) >>"widb3.burf"

if not exist "widb3.burf" set fullinstall=1&set count=&set _c=&goto :fullinstall
if defined office2007 findstr /i /v /g:"widb3.burf" "filelist4.burf" >"installer4.burf"
if defined office2010 findstr /i /v /g:"widb3.burf" "filelist1.burf" >"installer1.burf"
if defined office2013 findstr /i /v /g:"widb3.burf" "filelist2.burf" >"installer2.burf"
if defined office2016 findstr /i /v /g:"widb3.burf" "filelist3.burf" >"installer3.burf"

:fullinstall
if defined fullinstall (
if exist "filelist4.burf" copy /y "filelist4.burf" "installer4.burf" %_Nul1%
if exist "filelist1.burf" copy /y "filelist1.burf" "installer1.burf" %_Nul1%
if exist "filelist2.burf" copy /y "filelist2.burf" "installer2.burf" %_Nul1%
if exist "filelist3.burf" copy /y "filelist3.burf" "installer3.burf" %_Nul1%
)

if exist "installer4.burf" (for /f %%G in ('type "installer4.burf"') do (call set /a C2007+=1))
if exist "installer1.burf" (for /f %%G in ('type "installer1.burf"') do (call set /a C2010+=1))
if exist "installer2.burf" (for /f %%G in ('type "installer2.burf"') do (call set /a C2013+=1))
if exist "installer3.burf" (for /f %%G in ('type "installer3.burf"') do (call set /a C2016+=1))
if defined office2007 if not defined C2007 del /f /q "installer4.burf"
if defined office2010 if not defined C2010 del /f /q "installer1.burf"
if defined office2013 if not defined C2013 del /f /q "installer2.burf"
if defined office2016 if not defined C2016 del /f /q "installer3.burf"
popd
set /a _c=C2007+C2010+C2013+C2016 %_Nul1%

if %_c% equ 0 (set alreadyinstalled=1&goto :finished)

:instupdates
pushd "!_temp!"
if exist "installer4.burf" (
call :title
echo.
echo Installing updates for Microsoft Office 2007 %office2007b%
echo.
echo Installation of all updates may take considerable time.
echo Please be patient^^!
echo.
echo. 
for /f "delims=" %%G in ('type "installer4.burf"') do (set "instname=%%~nxG"&set "installer=%%G"&call :updinstall)
)
if exist "installer1.burf" (
call :title
echo.
echo Installing updates for Microsoft Office 2010 %office2010b%
echo.
echo Installation of all updates may take considerable time.
echo Please be patient^^!
echo.
echo. 
for /f "delims=" %%G in ('type "installer1.burf"') do (set "instname=%%~nxG"&set "installer=%%G"&call :updinstall)
)
if exist "installer2.burf" (
call :title
echo.
echo Installing updates for Microsoft Office 2013 %office2013b%
echo.
echo Installation of all updates may take considerable time.
echo Please be patient^^!
echo.
echo. 
for /f "delims=" %%G in ('type "installer2.burf"') do (set "instname=%%~nxG"&set "installer=%%G"&call :updinstall)
)
if exist "installer3.burf" (
call :title
echo.
echo Installing updates for Microsoft Office 2016 %office2016b%
echo.
echo Installation of all updates may take considerable time.
echo Please be patient^^!
echo.
echo. 
for /f "delims=" %%G in ('type "installer3.burf"') do (set "instname=%%~nxG"&set "installer=%%G"&call :updinstall)
)
popd
goto :finished

:updinstall
set /a count+=1
echo %count%/%_c%: %instname%
if /i "%instname:~-4%"==".exe" (
if %_Debug% EQU 0 "%installer%" /quiet /norestart
goto :eof
)
if exist _msp\ rmdir /s /q _msp\
mkdir _msp
expand.exe -r -f:*.msp "%installer%" _msp %_Nul1%
for /f %%# in ('dir /b /a:-d _msp\*.msp') do (
if %_Debug% EQU 0 start /w _msp\%%# /qn /norestart
)
rmdir /s /q _msp\
goto :eof

:finished
call :title
echo.
if defined fullinstall (set alreadyinstalled=)
if defined alreadyinstalled (
echo All updates found are already installed.
) else (
echo Finished processing and installing:
echo.
if defined C2007 (echo %C2007% updates for Micorosft Office 2007)
if defined C2010 (echo %C2010% updates for Micorosft Office 2010)
if defined C2013 (echo %C2013% updates for Microsoft Office 2013)
if defined C2016 (echo %C2016% updates for Microsoft Office 2016)
)

echo.
echo.
if not defined fullinstall (goto :installprompt)
echo.
echo.
echo Press any key to exit.
%_Pause%
goto :cleanup

:installprompt
set _inp=
echo Would you like to reprocess all updates?
echo  Y.  Yes
echo  N.  Exit
echo  X.  Also exits
echo.
echo.
echo Please note that in almost all circumstances the reprocessing of
echo all updates is unnecessary.
echo.
echo.
if %_Debug% NEQ 0 goto :cleanup
if exist "%SystemRoot%\System32\choice.exe" (
choice /c YNX /N /M "Please enter your selection> "
if errorlevel 3 goto :cleanup
if errorlevel 2 goto :cleanup
if errorlevel 1 (pushd "!_temp!"&set fullinstall=1&set count=&set _c=&goto :fullinstall)
) else (
set /p _inp="Please enter your selection> "
)
if /i "%_inp%"=="x" goto :cleanup
if /i "%_inp%"=="n" goto :cleanup
if /i "%_inp%"=="y" (pushd "!_temp!"&set fullinstall=1&set count=&set _c=&goto :fullinstall)
goto :finished

:cleanup
del /f /q "!_temp!\*.burf" %_Nul3%
:: del /f /q "!_temp!\*MSPLOG.LOG" %_Nul3%
del /f /q "!_temp!\opatchinstall*.log" %_Nul3%
@cls
goto :eof

:nofiles
call :title
set _inp=
echo There are no updates for Office found in the current folder or its
echo subfolders. Please run this script from the same location as the
echo update files, or enter the location of the update files by selecting
echo option 'A' in the menu below.
echo.
echo The update files must be Office update files.
echo They also must be for the correct version of Office (2007/2010/2013/2016)
echo and be for the correct architecture (x86/x64).
echo This is listed below the installer title at the top of the page.
echo.
echo A. Select location of updates
echo.
echo X. Exit
echo.
echo.
if %_Debug% NEQ 0 goto :cleanup
if exist "%SystemRoot%\System32\choice.exe" (
choice /c AX /N /M "Please enter your selection> "
if errorlevel 2 goto :cleanup
if errorlevel 1 goto :dofiles
) else (
set /p _inp="Please enter your selection> "
)
if /i "%_inp%"=="x" goto :cleanup
if /i "%_inp%"=="a" goto :dofiles
goto :nofiles

:dofiles
call :title
echo Please enter the location where the updates reside.
echo.
echo For ease of navigation you can locate the folder in Windows Explorer.
echo To do this, click on the space at the end of the address bar which will
echo highlight the current folder location.  Copy the address to the clipboard
echo by pressing (ctrl-c) or click the right mouse button and selecting copy.
echo.
echo Paste the copied location into the script by clicking with the right mouse
echo button on this window and selecting paste.
echo --------------------------------------------------------------------------
echo.
echo Please enter location of updates then press enter:
set /P _loc=
goto :top

:notinstalled
call :title
echo It appears you do not have Microsoft Office 2007/2010/2013/2016 installed on
echo this system. This installer supports the traditional MSI versions of
echo Microsoft Office. ClickToRun versions are not supported.
echo.
echo If you do have Microsoft Office 2007/2010/2013/2016 installed, please re-run
echo the Office setup and choose to repair the installation.
echo.
echo.
echo Press any key to exit.
%_Pause%
goto :cleanup

:title
@cls
echo -----------------------------------------------------
echo Microsoft Office Automated Updates Install Script v16 by Burf
echo -----------------------------------------------------
if defined office2007 (echo Microsoft Office 2007 %office2007b% %prodver2007%)
if defined office2010 (echo Microsoft Office 2010 %office2010b% %prodver2010%)
if defined office2013 (echo Microsoft Office 2013 %office2013b% %prodver2013%)
if defined office2016 (echo Microsoft Office 2016 %office2016b% %prodver2016%)
echo.
goto :eof

:spinstall
set spinst2007=0
set spinst2010=0
set spinst2013=0
call :title

pushd "!_temp!"
if %sp2007% neq 3 (
findstr /i "kb2526086 kb2526091 kb2526291 kb2526293 kb2526089" "update4.burf" >"spinst2007.burf" || set spinst2007=1
)
if %sp2010% neq 2 (
findstr /i "kb2687455 kb2687449 kb2687457 kb2687468 kb2687458 kb2687463" "update1.burf" >"spinst2010.burf" || set spinst2010=1
)
if %sp2013% neq 1 (
findstr /i "kb2817430 kb2817427 kb2817433 kb2817443 kb2817435 kb2817441" "update2.burf" >"spinst2013.burf" || set spinst2013=1
)
popd

set /a spinstglb=spinst2007+spinst2010+spinst2013 %_Nul1%

if %spinstglb% neq 0 (
echo The following service pack{s} were not found:
if %spinst2007% neq 0 (echo Microsoft Office 2007 %office2007b% Service Pack 3 {KB2591039})
if %spinst2010% neq 0 (echo Microsoft Office 2010 %office2010b% Service Pack 2 {KB2687523})
if %spinst2013% neq 0 (echo Microsoft Office 2013 %office2013b% Serivce Pack 1 {KB2817457})
echo.
echo Relevant service packs must be installed before the other updates.
echo Please download and install the relevant service packs, and rerun
echo this script to install remaining updates.
echo.
echo.
echo.
echo Press any key to exit.
%_Pause%
goto :cleanup
)

echo.
echo Please be patient during the install process, as it may take some time...
echo.
if %sp2007% neq 3 if %spinst2007% equ 0 (
set year=2007&set office=%office2007b%
echo Installing service pack for Microsoft Office !year! !office!
for /f "delims=" %%G in ('type "!_temp!\spinst2007.burf"') do (set "instname=%%~nxG"&set "installer=%%G"&call :spexecute)
)
if %sp2010% neq 2 if %spinst2010% equ 0 (
set year=2010&set office=%office2010b%
echo Installing service pack for Microsoft Office !year! !office!
for /f "delims=" %%G in ('type "!_temp!\spinst2010.burf"') do (set "instname=%%~nxG"&set "installer=%%G"&call :spexecute)
)
if %sp2013% neq 1 if %spinst2013% equ 0 (
set year=2013&set office=%office2013b%
echo Installing service pack for Microsoft Office !year! !office!
for /f "delims=" %%G in ('type "!_temp!\spinst2013.burf"') do (set "instname=%%~nxG"&set "installer=%%G"&call :spexecute)
)

goto :vercheck
goto :spdone

:spexecute
echo.
echo %instname%
if /i "%instname:~-4%"==".exe" (
echo %instname:~0,-4%|findstr /i /c:"2007sp" %_Nul1% && goto :spmsp
if %_Debug% EQU 0 "%installer%" /quiet /norestart /log:"!_temp!\%instname:~0,-4%.log"
goto :eof
)
:spmsp
if exist _msp\ rmdir /s /q _msp\
mkdir _msp
if /i "%instname:~-4%"==".exe" (
"%installer%" /quiet /extract:.\_msp /log:"!_temp!\%instname:~0,-4%.log"
) else (
expand.exe -r -f:*.msp "%installer%" _msp %_Nul1%
)
for /f %%# in ('dir /b /a:-d _msp\*.msp') do (
if %_Debug% EQU 0 start /w _msp\%%# /qn /norestart
)
rmdir /s /q _msp\
goto :eof

:spdone
set _fl=0
if defined office2007 if %prodver2007:~5,4% lss 6612 set _fl=1
if defined office2010 if %prodver2010:~5,4% lss 7015 set _fl=1
if defined office2013 if %prodver2013:~5,4% lss 4569 set _fl=1
if %_fl% neq 0 goto :fail

call :title
echo.
if %sp2007% neq 3 (echo Service Pack 3 for Microsoft Office 2007 installed.)
if %sp2010% neq 2 (echo Service Pack 2 for Microsoft Office 2010 installed.)
if %sp2013% neq 1 (echo Service Pack 1 for Microsoft Office 2013 installed.)
echo.
echo Please restart the computer to finalise the service pack installation.
echo.
echo.
echo Please use WHDownloader to download and install remaining updates if
echo you have not already done so, and use this script to install them.
echo.
echo New updates come out monthly, so ensure you keep up to date!
echo.
echo.
echo.
echo Press any key to exit.
%_Pause%
goto :cleanup

:fail
call :title
echo.
echo Installation of service pack failed. Please try installing
echo this manually.
echo.
echo You may need to redownload the service pack installer, or
echo reinstall Microsoft Office.
echo.
echo.
echo.
echo Press any key to exit.
%_Pause%
goto :cleanup
