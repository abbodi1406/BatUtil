@setlocal DisableDelayedExpansion
@echo off
set "_cmdf=%~f0"
if exist "%SystemRoot%\Sysnative\cmd.exe" (
setlocal EnableDelayedExpansion
start %SystemRoot%\Sysnative\cmd.exe /c ""!_cmdf!" "
exit /b
)
if exist "%SystemRoot%\SysArm32\cmd.exe" if /i %PROCESSOR_ARCHITECTURE%==AMD64 (
setlocal EnableDelayedExpansion
start %SystemRoot%\SysArm32\cmd.exe /c ""!_cmdf!" "
exit /b
)
set "SysPath=%SystemRoot%\System32"
if exist "%SystemRoot%\Sysnative\reg.exe" (set "SysPath=%SystemRoot%\Sysnative")
set "Path=%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
set "_err===== ERROR ===="

ver|findstr /c:" 5." >nul
if %errorlevel% equ 0 (
echo %_err%
echo This script require Windows Vista or later.
echo.
echo Press any key to exit.
pause >nul
goto :eof
)

reg.exe query "HKU\S-1-5-19" 1>nul 2>nul || (
echo %_err%
echo This script require administrator privileges.
echo To do so, right click on this script and select 'Run as administrator'
echo.
echo Press any key to exit.
pause >nul
goto :eof
)

title Microsoft Office Updates Installer v15 by Burf
set "_temp=%temp%"
set arch=x64
if /i %PROCESSOR_ARCHITECTURE%==x86 if not defined PROCESSOR_ARCHITEW6432 set arch=x86

set "_work=%~dp0"
set "_work=%_work:~0,-1%"
setlocal EnableDelayedExpansion
cd /d "!_work!"
if exist "!_temp!\*.burf" del /f /q "!_temp!\*.burf"
if exist "!_temp!\*.msp" del /f /q "!_temp!\*.msp"
set prodver2010=0
set prodver2013=0
set prodver2016=0
set sp2010=2
set sp2013=1
set z=0

:office2010check
for /f "skip=2 tokens=2*" %%a in ('"reg.exe query HKLM\SOFTWARE\Microsoft\Office\14.0\Common\InstallRoot /v Path" 2^>nul') do if exist "%%b\OSPP.VBS" (
set off2010reg=HKLM\SOFTWARE\Microsoft\Office\14.0\Common
if %arch% equ x64 (set office2010=x64&set /a z+=1&set office2010b=64-bit {x64}) else (set office2010=x86&set /a z+=1&set office2010b=32-bit {x86})
goto :office2013check
)
if %arch% equ x64 for /f "skip=2 tokens=2*" %%a in ('"reg.exe query HKLM\SOFTWARE\Wow6432Node\Microsoft\Office\14.0\Common\InstallRoot /v Path" 2^>nul') do if exist "%%b\OSPP.VBS" (
set off2010reg=HKLM\SOFTWARE\Wow6432Node\Microsoft\Office\14.0\Common
set office2010=x86&set /a z+=1&set office2010b=32-bit {x86}
goto :office2013check
)

:office2013check
for /f "skip=2 tokens=2*" %%a in ('"reg.exe query HKLM\SOFTWARE\Microsoft\Office\15.0\Common\InstallRoot /v Path" 2^>nul') do if exist "%%b\OSPP.VBS" (
set off2013reg=HKLM\SOFTWARE\Microsoft\Office\15.0\Common
if %arch% equ x64 (set office2013=x64&set /a z+=1&set office2013b=64-bit {x64}) else (set office2013=x86&set /a z+=1&set office2013b=32-bit {x86})
goto :office2016check
)
if %arch% equ x64 for /f "skip=2 tokens=2*" %%a in ('"reg.exe query HKLM\SOFTWARE\Wow6432Node\Microsoft\Office\15.0\Common\InstallRoot /v Path" 2^>nul') do if exist "%%b\OSPP.VBS" (
set off2013reg=HKLM\SOFTWARE\Wow6432Node\Microsoft\Office\15.0\Common
set office2013=x86&set /a z+=1&set office2013b=32-bit {x86}
goto :office2016check
)

:office2016check
for /f "skip=2 tokens=2*" %%a in ('"reg.exe query HKLM\SOFTWARE\Microsoft\Office\16.0\Common\InstallRoot /v Path" 2^>nul') do if exist "%%b\OSPP.VBS" (
set off2016reg=HKLM\SOFTWARE\Microsoft\Office\16.0\Common
if %arch% equ x64 (set office2016=x64&set /a z+=1&set office2016b=64-bit {x64}) else (set office2016=x86&set /a z+=1&set office2016b=32-bit {x86})
goto :checkdone
)
if %arch% equ x64 for /f "skip=2 tokens=2*" %%a in ('"reg.exe query HKLM\SOFTWARE\Wow6432Node\Microsoft\Office\16.0\Common\InstallRoot /v Path" 2^>nul') do if exist "%%b\OSPP.VBS" (
set off2016reg=HKLM\SOFTWARE\Wow6432Node\Microsoft\Office\16.0\Common
set office2016=x86&set /a z+=1&set office2016b=32-bit {x86}
goto :checkdone
)

:checkdone
@cls
if %z% equ 0 goto :notinstalled

:vercheck
if not defined office2010 goto :office2013ver
for /f "skip=2 tokens=2*" %%a in ('reg.exe query %off2010reg%\ProductVersion /v LastProduct') do (set prodver2010=%%b)
if not defined office2013 if not defined office2016 if not defined spinst goto :top

:office2013ver
if not defined office2013 goto :office2016ver
for /f "skip=2 tokens=2*" %%a in ('reg.exe query %off2013reg%\ProductVersion /v LastProduct') do (set prodver2013=%%b)
if not defined office2016 if not defined spinst goto :top

:office2016ver
for /f "skip=2 tokens=2*" %%a in ('reg.exe query %off2016reg%\ProductVersion /v LastProduct') do (set prodver2016=%%b)
if defined spinst goto :spdone

:top
if defined _loc cd /d "%_loc%"

echo If this message appears for an extended period of time, it is 
echo recommended that you close this script.
echo.
echo Please move the script to a folder that is closer to the location
echo of the Office updates.
echo.
echo If using WHDownloader, it is recommended that you place this script
echo in the same location as the WHDownloader.exe file

if defined office2010 (
for /f "delims=" %%G in ('dir /b /s *2010*%office2010%*.exe 2^>nul') do (echo %%G>>"!_temp!\update1.burf")
for /f "delims=" %%G in ('dir /b /s *2010*%office2010%*.cab 2^>nul') do (echo %%G>>"!_temp!\update1.burf")
for /f "delims=" %%G in ('dir /b /s *2010*%office2010%*.msp 2^>nul') do (echo %%G>>"!_temp!\update1.burf")
pushd "!_temp!"
findstr /i /v "kb2687455" "update1.burf" >"update1a.burf"
findstr /i /v "superseded" "update1a.burf" >"filelist1.burf"
for /f %%G in ('type "filelist1.burf"') do (call set /a _c+=1)
popd
)

if defined office2013 (
for /f "delims=" %%G in ('dir /b /s *2013*%office2013%*.exe 2^>nul') do (echo %%G>>"!_temp!\update2.burf")
for /f "delims=" %%G in ('dir /b /s *2013*%office2013%*.cab 2^>nul') do (echo %%G>>"!_temp!\update2.burf")
pushd "!_temp!"
findstr /i /v "kb2817430" "update2.burf" >"update2a.burf"
findstr /i /v "superseded" "update2a.burf" >"filelist2.burf"
for /f %%G in ('type "filelist2.burf"') do (call set /a _c+=1)
popd
)

if defined office2016 (
for /f "delims=" %%G in ('dir /b /s *2016*%office2016%*.exe 2^>nul') do (echo %%G>>"!_temp!\update3.burf")
pushd "!_temp!"
findstr /i /v "kb2817430" "update3.burf" >"update3a.burf"
findstr /i /v "superseded" "update3a.burf" >"filelist3.burf"
for /f %%G in ('type "filelist3.burf"') do (call set /a _c+=1)
popd
)

if defined office2010 if %prodver2010% lss 14.0.7015.1000 set sp2010=0
if defined office2013 if %prodver2013% lss 15.0.4569.1506 set sp2013=0

set /a sp=sp2010+sp2013 >nul
if %sp% neq 3 (goto :spinstall)

if not defined _c (goto :nofiles)

pushd "!_temp!"
reg.exe query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products" /f "(KB" /s /d 1>"installed.burf" 2>nul
find.exe /i "Update" "installed.burf" >"installed2.burf"
find.exe /i "Hotfix" "installed.burf" >>"installed2.burf
for /f "delims=() tokens=2" %%G in ('type "installed2.burf"') do (echo %%G) >>"installed3.burf"

if not exist "installed3.burf" set fullinstall=1&set count=&set c=&goto :fullinstall
if defined office2010 findstr /i /v /g:"installed3.burf" "filelist1.burf" >"installer1.burf"
if defined office2013 findstr /i /v /g:"installed3.burf" "filelist2.burf" >"installer2.burf"
if defined office2016 findstr /i /v /g:"installed3.burf" "filelist3.burf" >"installer3.burf"

:fullinstall
if defined fullinstall (
if exist "filelist1.burf" copy /y "filelist1.burf" "installer1.burf" >nul
if exist "filelist2.burf" copy /y "filelist2.burf" "installer2.burf" >nul
if exist "filelist3.burf" copy /y "filelist3.burf" "installer3.burf" >nul
)

if exist "installer1.burf" (for /f %%G in ('type "installer1.burf"') do (call set /a C2010+=1))
if exist "installer2.burf" (for /f %%G in ('type "installer2.burf"') do (call set /a C2013+=1))
if exist "installer3.burf" (for /f %%G in ('type "installer3.burf"') do (call set /a C2016+=1))
if defined office2010 if not defined C2010 del /f /q "installer1.burf"
if defined office2013 if not defined C2013 del /f /q "installer2.burf"
if defined office2016 if not defined C2016 del /f /q "installer3.burf"
popd
set /a _c=C2010+C2013+C2016 >nul

if %_c% equ 0 (set alreadyinstalled=1&goto :finished)

:instupdates
pushd "!_temp!"
if exist "installer1.burf" (
call :title
echo.
echo Installing updates for Microsoft Office 2010 %office2010b%
echo.
echo Installation of all updates may take considerable time.
echo Please be patient!
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
echo Please be patient!
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
echo Please be patient!
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
"%installer%" /quiet /norestart
goto :eof
)
if /i "%instname:~-4%"==".msp" (
"%installer%" /qn /norestart
goto :eof
)
expand.exe -f:*.msp "%installer%" .\ >nul
for /f %%# in ('dir /b /a:-d *.msp') do (call %%# /qn /norestart)
del /f /q *.msp >nul
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
if defined C2010 (echo %C2010% updates for Micorosft Office 2010.)
if defined C2013 (echo %C2013% updates for Microsoft Office 2013.)
if defined C2016 (echo %C2016% updates for Microsoft Office 2016.)
)

echo.
echo.
if not defined fullinstall (goto :installprompt)
echo.
echo.
echo Press any key to exit.
pause >nul
goto :cleanup

:installprompt
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
choice /c YNX /N /M "Please enter your selection> "
if errorlevel 3 goto :cleanup
if errorlevel 2 goto :cleanup
if errorlevel 1 (pushd "!_temp!"&set fullinstall=1&set count=&set c=&goto :fullinstall)
goto :installprompt

:cleanup
del /f /q "!_temp!\*.burf" 1>nul 2>nul
del /f /q "!_temp!\*_MSPLOG.LOG" 1>nul 2>nul
del /f /q "!_temp!\opatchinstall*.log" 1>nul 2>nul
@cls
goto :eof

:nofiles
call :title
echo There are no updates for Office found in the current folder or its
echo subfolders. Please run this script from the same location as the
echo update files, or enter the location of the update files by selecting
echo option 'A' in the menu below.
echo.
echo The update files must be Office update files.
echo They also must be for the correct version of Office (2010/2013/2016)
echo and be for the correct architecture (x86/x64).
echo This is listed below the installer title at the top of the page.
echo.
echo A. Select location of updates
echo.
echo X. Exit
echo.
echo.
choice /c AX /N /M "Please enter your selection> "
if errorlevel 2 goto :cleanup

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
echo It appears you do not have Microsoft Office 2010/2013/2016 installed on
echo this system. This installer supports the traditional MSI versions of
echo Microsoft Office. ClickToRun versions are not supported.
echo.
echo If you do have Microsoft Office 2010/2013/2016 installed, please re-run
echo the Office setup and choose to repair the installation.
echo.
echo.
echo Press any key to exit.
pause >nul
goto :cleanup

:title
@cls
echo -----------------------------------------------------
echo Microsoft Office Automated Updates Install Script v15 by Burf
echo -----------------------------------------------------
if defined office2010 (echo Microsoft Office 2010 %office2010b% %prodver2010%)
if defined office2013 (echo Microsoft Office 2013 %office2013b% %prodver2013%)
if defined office2016 (echo Microsoft Office 2016 %office2016b% %prodver2016%)
echo.
goto :eof

:spinstall
set spinst2010=0
set spinst2013=0
call :title

pushd "!_temp!"
if %sp2010% neq 2 (
findstr /i "kb2687455" "update1.burf" >"spinst2010.burf" && set spinst2010=1
)
if %sp2013% neq 1 (
findstr /i "kb2817430" "update2.burf" >"spinst2013.burf" && set spinst2013=1
)
popd

set /a spinst=spinst2010+spinst2013 >nul

if %spinst% neq 0 (
echo The following service pack{s} were not found:
if %spinst2010% neq 0 (echo Microsoft Office 2010 %office2010b% Service Pack 2 {KB2687455})
if %spinst2013% neq 0 (echo Microsoft Office 2013 %office2013b% Serivce Pack 1 {KB2817430})
echo.
echo Relevant service packs must be installed before the other updates.
echo Please download and install the relevant service packs, and rerun
echo this script to install remaining updates.
echo.
echo.
echo.
echo Press any key to exit.
pause >nul
goto :cleanup
)

if %sp2010% neq 2 if %spinst2010% equ 0 (
set year=2010&set office=%office2010b%
for /f "delims=" %%G in ('type "!_temp!\spinst2010.burf"') do (set "installer=%%G"&call :spinstall2)
)
if %sp2013% neq 1 if %spinst2013% equ 0 (
set year=2013&set office=%office2013b%
for /f "delims=" %%G in ('type "!_temp!\spinst2013.burf"') do (set "installer=%%G"&call :spinstall2)
)

goto :spdone

:spinstall2
echo.
echo Please be patient during the install process, as it may take some time...
echo.
echo Installing service pack for Microsoft Office %year% %office%
"%installer%" /quiet /norestart
goto :eof

:spdone
goto :vercheck
if defined office2010 if %prodver2010% lss 14.0.7015.1000 goto :fail
if defined office2013 if %prodver2013% lss 15.0.4569.1506 goto :fail

call :title
echo.
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
pause >nul
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
pause >nul
goto :cleanup
