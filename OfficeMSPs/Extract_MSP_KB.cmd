@ECHO OFF
SET "EXEFOL=D:\WHDownloader\Updates\Office2010-x64"
SET "MSPFOL=%~dp0\MSPs"
SET "LANG=en-us"
SET "PROOFLANG=de-de,fr-fr"

:: credits: hearywarlot
:: https://forums.mydigitallife.net/threads/64028

SETLOCAL ENABLEDELAYEDEXPANSION

FSUTIL dirty query "!SYSTEMDRIVE!" >nul 2>&1
IF !ERRORLEVEL! neq 0 (
( ECHO SET UAC = CreateObject^("Shell.Application"^)
ECHO UAC.ShellExecute "%~dpf0", ELAV, "", "runas", 1
)> "!TEMP!\OEgetPrivileges.vbs"
"!TEMP!\OEgetPrivileges.vbs"
DEL "!TEMP!\OEgetPrivileges.vbs"
EXIT /B
)

IF not defined EXEFOL (
ECHO Please enter the path containing your Office Updates"
SET /P EXEFOL=
IF [!EXEFOL!]==[] EXIT /B
CLS
)
IF not defined MSPFOL (
ECHO Please enter the path where the MSP will be extracted to"
SET /P MSPFOL=
IF [!MSPFOL!]==[] EXIT /B
CLS
)
IF NOT EXIST "!EXEFOL!\" (
ECHO Could not find "!EXEFOL!\"
PAUSE
EXIT /B
)
CD /D "!EXEFOL!"
IF NOT EXIST "!MSPFOL!" MKDIR "!MSPFOL!"
For /R %%A in (*.exe) do (
PUSHD "%%~dpA"
ECHO Extracting %%~xnA
SET "KBFIL=%%~nA"
for /f "tokens=1 delims=-" %%V in ('dir /b %%~xnA') do set MSPNAM=%%V
"!KBFIL!.exe" /quiet /EXTRACT:"!KBFIL!"
IF EXIST "!KBFIL!\" (
PUSHD "!KBFIL!"
FOR /R %%B in (*.msp) do (
SETLOCAL
IF "!LANG!"=="" (
SET "TRUE=1"
) ELSE (
SET "RMLNG1=%%~nB"
CALL SET "RMLNG=%%RMLNG1:-!RMLNG1:*-=!=%%"
IF "!RMLNG1!"=="!RMLNG!-x-none" (
SET "TRUE=1"
) ELSE (
IF "!RMLNG!"=="proof" FOR %%L IN (!PROOFLANG!) DO IF "!RMLNG1!"=="proof-%%L" SET "TRUE=1"
IF "!RMLNG1!"=="!RMLNG!-!LANG!" (
SET "TRUE=1"
)
)
)
IF "!TRUE!"=="1" (
SET "MSPKB1=!KBFIL:*kb=kb!"
SET "MSPKB2=!MSPKB1:*-=!"
CALL SET "MSPKB=%%MSPKB1:-!MSPKB2!=%%"
SET "MSPARC1=!MSPKB2:*-=!"
SET "MSPARC=!MSPARC1:-glb=!"
IF "!RMLNG!"=="proof" SET "MSPKB=!MSPKB!-!RMLNG1:proof-=!"
MOVE /Y "%%~nxB" "!MSPFOL!\z_!MSPNAM!-!MSPKB!-!MSPARC!.msp" >nul
)
ENDLOCAL
)
POPD
)
RD /S /Q "!KBFIL!"
POPD
)
ECHO.
ECHO Dinner is ready^^!

PAUSE
EXIT /B