@setlocal DisableDelayedExpansion
@set uivr=v0.5
@echo off
:: Change to 0 to skip adding SSU to the msu file
set IncludeSSU=1

set _Debug=0

set "_cmdf=%~f0"
if exist "%SystemRoot%\Sysnative\cmd.exe" (
setlocal EnableDelayedExpansion
start %SystemRoot%\Sysnative\cmd.exe /c ""!_cmdf!" %*"
exit /b
)
if exist "%SystemRoot%\SysArm32\cmd.exe" if /i %PROCESSOR_ARCHITECTURE%==AMD64 (
setlocal EnableDelayedExpansion
start %SystemRoot%\SysArm32\cmd.exe /c ""!_cmdf!" %*"
exit /b
)
set _dpx=0
set _exd=0
set "_MSUdll=dpx.dll ReserveManager.dll TurboStack.dll UpdateAgent.dll UpdateCompression.dll wcp.dll"
set "_MSUonf=onepackage.AggregatedMetadata.cab"
set "_Null=1>nul 2>nul"
set "_err===== ERROR ===="
set "_ntc===== NOTICE ===="
set "_repo="
set "_args="
set "_args=%~1"
if not defined _args goto :NoProgArgs
if "%~1"=="" set "_args="&goto :NoProgArgs

:NoProgArgs
set "SysPath=%SystemRoot%\System32"
set "Path=%SystemRoot%\System32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
if exist "%SystemRoot%\Sysnative\reg.exe" (
set "SysPath=%SystemRoot%\Sysnative"
set "Path=%SystemRoot%\Sysnative;%SystemRoot%;%SystemRoot%\Sysnative\Wbem;%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\;%Path%"
)
set "xBT=x64"
if /i "%PROCESSOR_ARCHITECTURE%"=="arm64" set "xBT=x86"
if /i "%PROCESSOR_ARCHITECTURE%"=="x86" if "%PROCESSOR_ARCHITEW6432%"=="" set "xBT=x86"
if /i "%PROCESSOR_ARCHITEW6432%"=="amd64" set "xBT=x64"
if /i "%PROCESSOR_ARCHITEW6432%"=="arm64" set "xBT=x86"
set "line============================================================="
set "WowPath=%SystemRoot%\SysWOW64"
set "_log=%~dpn0"
set "_work=%~dp0"
set "_work=%_work:~0,-1%"
set "_temp=%TEMP%"
for /f "skip=2 tokens=2*" %%a in ('reg.exe query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop') do call set "_dsk=%%b"
if exist "%PUBLIC%\Desktop\desktop.ini" set "_dsk=%PUBLIC%\Desktop"
setlocal EnableDelayedExpansion

set "_loc=!_work!"
if defined _args set "_loc=!_args!"
if not exist "!_loc!\*.AggregatedMetadata*.cab" (
echo.
echo No AggregatedMetadata file detected in the source directory
goto :continue
) else if not exist "!_loc!\*Windows1*-KB*.psf" (
echo.
echo No psf file detected in the source directory
goto :continue
)
if not exist "!_loc!\*Windows1*-KB*.cab" if not exist "!_loc!\*Windows1*-KB*.wim" (
echo No cab or wim file detected in the source directory
goto :continue
)
if exist "!_loc!\*DesktopDeployment*.cab" set "_repo=!_loc!"
if exist "!_loc!\SSU-*-*.cab" set "_repo=!_loc!"
goto :continue

:continue
if %_Debug% equ 0 (
  set "_Nul1=1>nul"
  set "_Nul2=2>nul"
  set "_Nul6=2^>nul"
  set "_Nul3=1>nul 2>nul"
  set "_Pause=pause >nul"
  set "_Exit=echo Press any key to exit."
  set "_Supp="
  goto :Begin
)
  set "_Nul1="
  set "_Nul2="
  set "_Nul6="
  set "_Nul3="
  set "_Pause=rem."
  set "_Exit=rem."
  set "_Supp=1>nul"
copy /y nul "!_work!\#.rw" %_Null% && (if exist "!_work!\#.rw" del /f /q "!_work!\#.rw") || (set "_log=!_dsk!\%~n0")
echo.
echo Running in Debug Mode...
if not defined _args (echo The window will be closed when finished) else (echo please wait)
@echo on
@prompt $G
@call :Begin >"!_log!_tmp.log" 2>&1 &cmd /u /c type "!_log!_tmp.log">"!_log!_Debug.log"&del "!_log!_tmp.log"
@color 07
@title %ComSpec%
@exit /b

:Begin
if not defined _repo goto :N_PT
if not exist "!_work!\bin\imagex_%xBT%.exe" goto :E_Bin
title PSFXv2 MSU Maker %uivr%
if %_Debug% equ 0 if not defined _args @cls
set /a _ref+=1
set /a _rnd=%random%
pushd "!_repo!"
for /f "delims=" %%# in ('dir /b /a:-d "*.AggregatedMetadata*.cab"') do if /i "%%#"=="%_MSUonf%" (
set /a _rnd+=1
ren "%%#" "org!_rnd!_%%#"
)
for /f "delims=" %%# in ('dir /b /a:-d "*.AggregatedMetadata*.cab"') do (set "metaf=%%#"&call :doMSU)
echo.
echo Finished
goto :TheEnd

:doMSU
echo.
echo %line%
echo %metaf%
echo %line%
set "_MSUssu="
set optSSU=%IncludeSSU%
set _mcfail=0
if exist "_tMSU\" rmdir /s /q "_tMSU\" %_Nul3%
mkdir "_tMSU"
expand.exe -f:LCUCompDB*.xml.cab "%metaf%" "_tMSU" %_Null%
expand.exe -f:SSUCompDB*.xml.cab "%metaf%" "_tMSU" %_Null%
expand.exe -f:*.AggregatedMetadata*.cab "%metaf%" "_tMSU" %_Null%
if not exist "_tMSU\LCUCompDB*.xml.cab" if not exist "_tMSU\*.AggregatedMetadata*.cab" (
echo.
echo LCUCompDB file is missing
goto :eof
)
if exist "_tMSU\SSU*-express.xml.cab" del /f /q "_tMSU\SSU*-express.xml.cab"

set xtn=cab
if not exist "_tMSU\*.AggregatedMetadata*.cab" goto :skpwim
set xtn=wim
for /f %%# in ('dir /b /a:-d "_tMSU\*.AggregatedMetadata*.cab"') do expand.exe -f:*.xml "_tMSU\%%#" "_tMSU" %_Null%
if not exist "_tMSU\LCUCompDB*.xml" (
echo.
echo LCUCompDB file is missing
goto :eof
)
for /f %%# in ('dir /b /a:-d "_tMSU\LCUCompDB*.xml"') do (
%_Null% makecab.exe /D Compress=ON /D CompressionType=MSZIP "_tMSU\%%~n#.xml" "_tMSU\%%~n#.xml.cab"
)
if exist "_tMSU\SSUCompDB*.xml" for /f %%# in ('dir /b /a:-d "_tMSU\SSUCompDB*.xml"') do (
%_Null% makecab.exe /D Compress=ON /D CompressionType=MSZIP "_tMSU\%%~n#.xml" "_tMSU\%%~n#.xml.cab"
)
if not exist "_tMSU\LCUCompDB*.xml.cab" (
echo.
echo makecab.exe LCUCompDB file failed
goto :eof
)
del /f /q "_tMSU\*.xml" %_Nul3%

:skpwim
set "_MSUkbn="
for /f "tokens=2 delims=_." %%# in ('dir /b /a:-d "_tMSU\LCUCompDB*.xml.cab"') do (
set "_MSUkbn=%%#"
)
if exist "*Windows1*%_MSUkbn%*.msu" (
echo.
echo %_MSUkbn% msu file already exist
goto :eof
)
if not exist "*Windows1*%_MSUkbn%*.psf" (
echo.
echo %_MSUkbn% psf file is missing
goto :eof
)
if exist "*Windows1*%_MSUkbn%*.cab" (
set xmf=cab
) else if exist "*Windows1*%_MSUkbn%*.wim" (
set xmf=wim
) else (
echo.
echo %_MSUkbn% %xtn% file is missing
goto :eof
)

for /f %%# in ('dir /b /a:-d "_tMSU\LCUCompDB_%_MSUkbn%*.xml.cab"') do set "_MSUcdb=%%#"
for /f "tokens=3 delims=-_" %%# in ('dir /b /a:-d "*Windows1*%_MSUkbn%*.psf"') do set "arch=%%~n#"
for /f "delims=" %%# in ('dir /b /a:-d "*Windows1*%_MSUkbn%*%arch%*.%xmf%"') do set "_MSUcab=%%#"
for /f "delims=" %%# in ('dir /b /a:-d "*Windows1*%_MSUkbn%*%arch%*.psf"') do set "_MSUpsf=%%#"
set "_MSUkbf=Windows10.0-%_MSUkbn%-%arch%"
echo %_MSUcab%| findstr /i "Windows11\." %_Nul1% && set "_MSUkbf=Windows11.0-%_MSUkbn%-%arch%"
echo %_MSUcab%| findstr /i "Windows12\." %_Nul1% && set "_MSUkbf=Windows12.0-%_MSUkbn%-%arch%"

if not exist "SSU-*%arch%*.cab" set optSSU=0&goto :skpssu
for /f "delims=" %%# in ('dir /b /a:-d "SSU-*%arch%*.cab"') do (set "_chk=%%#"&call :doSSU)
if not defined _MSUssu set optSSU=0&goto :skpssu
goto :skpssu

:doSSU
if defined _MSUssu goto :eof
if exist "_tMSU\update.mum" del /f /q "_tMSU\update.mum"
expand.exe -f:update.mum "%_chk%" "_tMSU" %_Null%
set "_SSUkbn="
if exist "_tMSU\update.mum" for /f "tokens=3 delims== " %%# in ('findstr /i releaseType "_tMSU\update.mum"') do set _SSUkbn=%%~#
if "%_SSUkbn%"=="" goto :eof
if not exist "_tMSU\SSUCompDB_%_SSUkbn%*.xml.cab" goto :eof
for /f %%# in ('dir /b /a:-d "_tMSU\SSUCompDB_%_SSUkbn%*.xml.cab"') do set "_MSUsdb=%%#"
for /f "tokens=2 delims=-" %%# in ('dir /b /a:-d "%_chk%"') do set "_MSUtsu=SSU-%%#-%arch%.cab"
set "_MSUssu=%_chk%"
goto :eof

:skpssu
set "_MSUddc="
set "_MSUddd=DesktopDeployment_x86.cab"
if exist "*DesktopDeployment*.cab" (
for /f "delims=" %%# in ('dir /b /a:-d "*DesktopDeployment*.cab" ^|find /i /v "%_MSUddd%"') do set "_MSUddc=%%#"
)
if exist "%SysPath%\ucrtbase.dll" call :dodpx
if not defined _MSUddc (
call set "_MSUddc=_tMSU\DesktopDeployment.cab"
call set "_MSUddd=_tMSU\DesktopDeployment_x86.cab"
call :DDCAB
)
if %_mcfail% equ 1 goto :eof
if /i not %arch%==x86 if not exist "DesktopDeployment_x86.cab" if not exist "_tMSU\DesktopDeployment_x86.cab" if defined _MSUtsu (
call set "_MSUddd=_tMSU\DesktopDeployment_x86.cab"
call :DDC86
)
:: if %_mcfail% equ 1 goto :eof
call :crDDF _tMSU\%_MSUonf%
(echo "_tMSU\%_MSUcdb%" "%_MSUcdb%"
if %optSSU% equ 1 echo "_tMSU\%_MSUsdb%" "%_MSUsdb%"
)>>zzz.ddf
%_Null% makecab.exe /F zzz.ddf /D Compress=ON /D CompressionType=MSZIP
if %ERRORLEVEL% neq 0 (
echo.
echo makecab.exe %_MSUonf% failed
goto :eof
)
if %xmf%==wim goto :msu_wim
call :crDDF %_MSUkbf%.msu
(echo "%_MSUddc%" "DesktopDeployment.cab"
if exist "%_MSUddd%" echo "%_MSUddd%" "DesktopDeployment_x86.cab"
echo "_tMSU\%_MSUonf%" "%_MSUonf%"
if %optSSU% equ 1 echo "%_MSUssu%" "%_MSUtsu%"
echo "%_MSUcab%" "%_MSUkbf%.cab"
echo "%_MSUpsf%" "%_MSUkbf%.psf"
)>>zzz.ddf
%_Null% makecab.exe /F zzz.ddf /D Compress=OFF
if %ERRORLEVEL% neq 0 (
echo.
echo makecab.exe %_MSUkbf%.msu failed
goto :eof
)
call :undpx
goto :eof

:msu_wim
echo.
echo Creating: %_MSUkbf%.msu
if exist "_tWIM\" rmdir /s /q "_tWIM\" %_Nul3%
mkdir "_tWIM"
copy /y "%_MSUddc%" "_tWIM\DesktopDeployment.cab" %_Nul3%
if exist "%_MSUddd%" if /i not %arch%==x86 copy /y "%_MSUddd%" "_tWIM\DesktopDeployment_x86.cab" %_Nul3%
copy /y "_tMSU\%_MSUonf%" "_tWIM\%_MSUonf%" %_Nul3%
if %optSSU% equ 1 copy /y "%_MSUssu%" "_tWIM\%_MSUtsu%" %_Nul3%
copy /y "%_MSUcab%" "_tWIM\%_MSUkbf%.wim" %_Nul3%
copy /y "%_MSUpsf%" "_tWIM\%_MSUkbf%.psf" %_Nul3%
%_Nul3% "!_work!\bin\imagex_%xBT%.exe" /CAPTURE _tWIM\ %_MSUkbf%.msu content /COMPRESS none /NOACL ALL /NOTADMIN /TEMP "!_temp!"
if %ERRORLEVEL% neq 0 (
echo.
echo wim capture %_MSUkbf%.msu failed
goto :eof
)
call :undpx
goto :eof

:DDCAB
echo.
echo Extracting: %_MSUssu%
if exist "_tSSU\" rmdir /s /q "_tSSU\" %_Nul3%
mkdir "_tSSU\000"
expand.exe -f:* "%_MSUssu%" "_tSSU" %_Null% || (
echo failed.
echo Provide ready DesktopDeployment.cab or dpx.dll and try again
set _mcfail=1
rmdir /s /q "_tSSU\" %_Nul3%
goto :eof
)
:ssuouter64
set btx=%arch%
if /i %arch%==x64 set btx=amd64
for /f %%# in ('dir /b /ad "_tSSU\%btx%_microsoft-windows-servicingstack_*"') do set "src=%%#"
for %%# in (%_MSUdll%) do if exist "_tSSU\%src%\%%#" (move /y "_tSSU\%src%\%%#" "_tSSU\000\%%#" %_Nul1%)
call :crDDF %_MSUddc%
call :apDDF _tSSU\000
%_Null% makecab.exe /F zzz.ddf /D Compress=ON /D CompressionType=MSZIP
if %ERRORLEVEL% neq 0 (
echo.
echo makecab.exe %_MSUddc% failed
set _mcfail=1
exit /b
)
mkdir "_tSSU\111"
if /i not %arch%==x86 if not exist "DesktopDeployment_x86.cab" goto :DDCdual
rmdir /s /q "_tSSU\" %_Nul3%
exit /b

:DDC86
echo.
echo Extracting: %_MSUssu%
if exist "_tSSU\" rmdir /s /q "_tSSU\" %_Nul3%
mkdir "_tSSU\111"
expand.exe -f:* "%_MSUssu%" "_tSSU" %_Null% || (
echo failed.
echo Skipping DesktopDeployment_x86.cab
echo see ReadMe.txt for more details
set _mcfail=1
rmdir /s /q "_tSSU\" %_Nul3%
goto :eof
)
:ssuouter86
:DDCdual
for /f %%# in ('dir /b /ad "_tSSU\x86_microsoft-windows-servicingstack_*"') do set "src=%%#"
for %%# in (%_MSUdll%) do if exist "_tSSU\%src%\%%#" (move /y "_tSSU\%src%\%%#" "_tSSU\111\%%#" %_Nul1%)
call :crDDF %_MSUddd%
call :apDDF _tSSU\111
%_Null% makecab.exe /F zzz.ddf /D Compress=ON /D CompressionType=MSZIP
if %ERRORLEVEL% neq 0 (
echo.
echo makecab.exe %_MSUddd% failed
set _mcfail=1
exit /b
)
rmdir /s /q "_tSSU\" %_Nul3%
exit /b

:crDDF
echo.
echo Creating: %~nx1
(echo .Set DiskDirectoryTemplate="."
echo .Set CabinetNameTemplate="%1"
echo .Set MaxCabinetSize=0
echo .Set MaxDiskSize=0
echo .Set FolderSizeThreshold=0
echo .Set RptFileName=nul
echo .Set InfFileName=nul
echo .Set Cabinet=ON
)>zzz.ddf
exit /b

:apDDF
(echo .Set SourceDir="%1"
echo "dpx.dll"
echo "ReserveManager.dll"
echo "TurboStack.dll"
echo "UpdateAgent.dll"
echo "wcp.dll"
if exist "%1\UpdateCompression.dll" echo "UpdateCompression.dll"
)>>zzz.ddf
exit /b

:dodpx
set _nat=0
set _wow=0
if /i %arch%==%xBT% set _nat=1
if %_nat% equ 0 set _wow=1
if %_dpx% equ 0 if exist "!_repo!\dpx.dll" if not exist "!_repo!\expand.exe" (
  if %_wow% equ 1 copy /y %WowPath%\expand.exe "!_repo!\" %_Nul3%
  if %_nat% equ 1 copy /y %SysPath%\expand.exe "!_repo!\" %_Nul3%
  set _exd=1
  exit /b
)
if %_wow% equ 1 if exist "%_MSUddd%" (
expand.exe -f:dpx.dll "%_MSUddd%" "!_repo!" %_Nul3%
if exist "!_repo!\dpx.dll" (
  copy /y %WowPath%\expand.exe "!_repo!\" %_Nul3%
  set _dpx=1
  exit /b
  )
)
if %_nat% equ 1 if defined _MSUddc (
expand.exe -f:dpx.dll "%_MSUddc%" "!_repo!" %_Nul3%
if exist "!_repo!\dpx.dll" (
  copy /y %SysPath%\expand.exe "!_repo!\" %_Nul3%
  set _dpx=1
  exit /b
  )
)
exit /b

:undpx
if %_exd% equ 1 (
if exist "expand.exe" del /f /q "expand.exe" %_Nul3%
)
if %_dpx% equ 1 (
if exist "dpx.dll" del /f /q "dpx.dll" %_Nul3%
if exist "expand.exe" del /f /q "expand.exe" %_Nul3%
)
exit /b

:E_Bin
echo.
echo %_err%
echo.
echo Required file "bin\imagex_%xBT%.exe" is missing
echo.
goto :TheEnd

:N_PT
echo.
echo %_ntc%
echo.
echo Could not find all required update files
echo.
goto :TheEnd

:TheEnd
if exist "zzz.ddf" del /f /q "zzz.ddf"
if exist "_tWIM\" rmdir /s /q "_tWIM\" %_Nul3%
if exist "_tSSU\" rmdir /s /q "_tSSU\" %_Nul3%
if exist "_tMSU\" rmdir /s /q "_tMSU\" %_Nul3%
call :undpx
%_Exit%
%_Pause%
goto :eof
