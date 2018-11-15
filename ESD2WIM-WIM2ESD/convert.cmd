@echo off
rem script:     abbodi1406
rem wimlib:     synchronicity
title ESD ^<^> WIM
if not exist "%~dp0bin\wimlib-imagex.exe" goto :eof
IF /I "%PROCESSOR_ARCHITECTURE%" EQU "AMD64" (SET "wimlib=%~dp0bin\bin64\wimlib-imagex.exe") ELSE (SET "wimlib=%~dp0bin\wimlib-imagex.exe")
%windir%\system32\reg.exe query "HKU\S-1-5-19" 1>nul 2>nul && (set _admin=1) || (set _admin=0)
setlocal EnableDelayedExpansion
cd /d "%~dp0"
if not "%1"=="" (set "WIMFILE=%~1"&goto :check)
if exist install.esd (set WIMFILE=install.esd&goto :check)
if exist install.wim (set WIMFILE=install.wim&goto :check)
set _esd=0
if exist "*.esd" (for /f "delims=" %%i in ('dir /b "*.esd"') do (call set /a _esd+=1))
if !_esd! NEQ 1 goto :prompt
for /f "delims=" %%i in ('dir /b "*.esd"') do (set "WIMFILE=%%i"&goto :check)

:prompt
echo.
echo ===============================================================================
echo Enter / Paste the complete path to install.esd or install.wim
echo ^(without quotes marks "" even if the path contains spaces^)
echo ===============================================================================
echo.
set /p "WIMFILE="
if "%WIMFILE%"=="" goto :QUIT

:check
color 1f
bin\wimlib-imagex.exe info "%WIMFILE%" 1>nul 2>nul
IF %ERRORLEVEL% EQU 74 (
cls
echo.
echo ===============================================================================
echo ERROR: ESD file is encrypted.
echo ===============================================================================
echo.
echo Press any key to exit.
pause >nul
goto :eof
)
IF %ERRORLEVEL% NEQ 0 (
cls
echo.
echo ===============================================================================
echo ERROR: Specified file is not found or damaged.
echo ===============================================================================
echo.
echo Press any key to exit.
pause >nul
goto :eof
)
for /f "tokens=3 delims=: " %%i in ('bin\wimlib-imagex.exe info "%WIMFILE%" ^| findstr /c:"Image Count"') do set images=%%i
for /L %%i in (1,1,%images%) do call :setcount %%i

bin\wimlib-imagex.exe info "%WIMFILE%" | findstr /C:"LZMS" >nul && (
	set _target=install.wim
	set _source=ESD
	set _compress=LZX
) || (
	set _target=install.esd
	set _source=WIM
	set _compress=LZMS --solid
)
GOTO :MENU
exit

:setcount
set /a count+=1
for /f "tokens=1* delims=: " %%i in ('bin\wimlib-imagex.exe info "%WIMFILE%" %1 ^| findstr /b /c:"Name"') do set name%count%="%%j"
goto :eof

:MENU
cls
set userinp=
echo ===============================================================================
echo.                   Detected %_source% file contains %images% indexes:
echo.
for /L %%i in (1, 1, %images%) do (
echo. %%i. !name%%i!
)
if %_source%==ESD if exist "%CD%\install.wim" goto :E_WIM
echo ===============================================================================
echo.                                  Options:
echo. 0 - Quit
echo. 1 - Export single index
if %images% gtr 1 echo. 2 - Export all indexes
if %images% gtr 2 echo. 3 - Export consecutive range of indexes
if %images% gtr 2 echo. 4 - Export randomly selected indexes
if %_admin% equ 1 echo. 5 - Apply single index to another drive
echo ===============================================================================
set /p userinp= ^> Enter your option and press "Enter": 
set userinp=%userinp:~0,1%
if %userinp%==0 goto :QUIT
if %userinp%==1 goto :SINGLE
if %userinp%==2 if %images% gtr 1 goto :ALL
if %userinp%==3 if %images% gtr 2 goto :RANGE
if %userinp%==4 if %images% gtr 3 goto :RANDOM
if %userinp%==5 if %_admin% equ 1 goto :DEPLOY
GOTO :MENU

:ALL
cls
echo ===============================================================================
echo Exporting all %_source% indexes to %_target%...
echo ===============================================================================
call :ESD_WARN
echo.
"%wimlib%" export "%WIMFILE%" all %_target% --compress=%_compress%
set ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (echo.&echo Errors were reported during export.&PAUSE&GOTO :QUIT)
echo.
echo Done.
echo.
echo Press any key to exit.
pause >nul
GOTO :QUIT

:SINGLE
cls
set _index=
if "%images%"=="1" set _index=1&goto :SINGLEproceed
echo ===============================================================================
echo.                   Detected %_source% file contains %images% indexes:
echo.
for /L %%i in (1, 1, %images%) do (
echo. %%i. !name%%i!
)
echo ===============================================================================
echo Enter index number to export, or zero '0' to return to Main Menu
echo ===============================================================================
set /p _index= ^> 
if "%_index%"=="" goto :SINGLE
if "%_index%"=="0" goto :MENU
if %_index% GTR %images% echo.&echo Selected number is higher than available indexes&echo.&PAUSE&goto :SINGLE
:SINGLEproceed
cls
echo ===============================================================================
echo Exporting %_source% index %_index% to %_target%...
echo ===============================================================================
call :ESD_WARN
echo.
"%wimlib%" export "%WIMFILE%" %_index% %_target% --compress=%_compress%
set ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (echo.&echo Errors were reported during export.&PAUSE&GOTO :QUIT)
echo.
echo Done.
echo.
echo Press any key to exit.
pause >nul
GOTO :QUIT

:RANGE
cls
set _range=
set _start=
set _end=
echo ===============================================================================
echo.                   Detected %_source% file contains %images% indexes:
echo.
for /L %%i in (1, 1, %images%) do (
echo. %%i. !name%%i!
)
echo ===============================================================================
echo Enter consecutive range of indexes to export: Start-End
echo examples: 2-4 or 1-7 or 3-4
echo ===============================================================================
echo Enter zero '0' to return to Main Menu
echo ===============================================================================
set /p _range= ^> 
if "%_range%"=="" goto :RANGE
if "%_range%"=="0" goto :MENU
for /f "tokens=1,2 delims=-" %%i in ('echo %_range%') do set _start=%%i&set _end=%%j
if %_end% GTR %images% echo.&echo Range End is higher than available indexes&echo.&PAUSE&goto :RANGE
if %_start% GTR %_end% echo.&echo Range Start is higher than Range End&echo.&PAUSE&goto :RANGE
if %_start% EQU %_end% echo.&echo Range Start and End are equal&echo.&PAUSE&goto :RANGE
if %_start% GTR %images% echo.&echo Range Start is higher than available indexes&echo.&PAUSE&goto :RANGE
cls
echo ===============================================================================
echo Exporting %_source% %_start% -^> %_end% indexes to %_target%...
echo ===============================================================================
call :ESD_WARN
echo.
for /L %%i in (%_start%, 1, %_end%) do (
"%wimlib%" export "%WIMFILE%" %%i %_target% --compress=%_compress%
)
set ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (echo.&echo Errors were reported during export.&PAUSE&GOTO :QUIT)
echo.
echo Done.
echo.
echo Press any key to exit.
pause >nul
GOTO :QUIT

:RANDOM
cls
set _count=0
set _index=
echo ===============================================================================
echo.                   Detected %_source% file contains %images% indexes:
echo.
for /L %%i in (1, 1, %images%) do (
echo. %%i. !name%%i!
)
echo ===============================================================================
echo Enter indexes numbers to export separated with space^(s^)
echo examples: 1 3 4 or 5 1 or 4 2 9
echo ===============================================================================
echo Enter zero '0' to return to Main Menu
echo ===============================================================================
set /p _index= ^> 
if "%_index%"=="" goto :RANDOM
if "%_index%"=="0" goto :MENU
for %%i in (%_index%) do call :setindex %%i
for /L %%i in (1,1,%_count%) do (
if !_index%%i! GTR %images% echo.&echo !_index%%i! is higher than available indexes&echo.&PAUSE&goto :RANDOM
)
cls
echo ===============================================================================
echo Exporting %_source% "%_index%" indexes to %_target%...
echo ===============================================================================
call :ESD_WARN
echo.
for /L %%i in (1,1,%_count%) do (
"%wimlib%" export "%WIMFILE%" !_index%%i! %_target% --compress=%_compress%
)
set ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (echo.&echo Errors were reported during export.&PAUSE&GOTO :QUIT)
echo.
echo Done.
echo.
echo Press any key to exit.
pause >nul
GOTO :QUIT

:setindex
set /a _count+=1
set _index%_count%=%1
goto :eof

:DEPLOY
cls
set _index=
if "%images%"=="1" set _index=1&goto :APPLY
echo ===============================================================================
echo.                   Detected %_source% file contains %images% indexes:
echo.
for /L %%i in (1, 1, %images%) do (
echo. %%i. !name%%i!
)
echo ===============================================================================
echo Enter desired index number to apply, or zero '0' to return to Main Menu
echo ===============================================================================
set /p _index= ^> 
if "%_index%"=="" goto :DEPLOY
if "%_index%"=="0" goto :MENU
if %_index% GTR %images% echo.&echo Selected number is higher than available indexes&echo.&PAUSE&goto :DEPLOY
goto :APPLY

:APPLY
cls
set _ltr=
echo ===============================================================================
echo Enter the Drive Letter to apply the image to, example F:
echo make sure the drive is valid, properly formatted and ready to use
echo ===============================================================================
echo.
set /p _ltr= ^> 
if "%_ltr%"=="" goto :QUIT
echo %_ltr%| findstr /B /E /I "[D-Z]:" >NUL 2>&1
if %errorlevel% neq 0 (echo.&echo ERROR: Destination needs to be a drive letter&echo.&PAUSE&goto :APPLY)
if not exist "%_ltr%" (echo.&echo ERROR: Destination drive %_ltr% does not exist&echo.&PAUSE&goto :APPLY)
cls
echo ===============================================================================
echo Applying index %_index% to drive %_ltr%
echo ===============================================================================
echo.
"%wimlib%" apply "%WIMFILE%" %_index% %_ltr% 2>nul
set ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (echo.&echo Errors were reported during apply.&PAUSE&GOTO :QUIT)
echo.
echo Press any key to exit.
pause >nul
GOTO :QUIT

:E_WIM
echo.
echo ===============================================================================
echo ERROR: An install.wim file is already present in the current folder.
echo ===============================================================================
echo.
echo Press any key to exit.
pause >nul
GOTO :QUIT

:ESD_WARN
if %_source%==WIM (echo.&echo *** This will require some time, high CPU and RAM usage, please be patient ***)
goto :eof

:QUIT
goto :eof