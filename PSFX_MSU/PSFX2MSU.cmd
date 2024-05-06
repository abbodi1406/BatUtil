@setlocal DisableDelayedExpansion
@set uivr=v0.4
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
set _fail=0
set DD64create=0
set DD86create=0
set "sdl=dpx.dll ReserveManager.dll TurboStack.dll UpdateAgent.dll UpdateCompression.dll wcp.dll"
set "onf=onepackage.AggregatedMetadata.cab"
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
set "_log=%~dpn0"
set "_work=%~dp0"
set "_work=%_work:~0,-1%"
set "_temp=%TEMP%"
for /f "skip=2 tokens=2*" %%a in ('reg.exe query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop') do call set "_dsk=%%b"
if exist "%PUBLIC%\Desktop\desktop.ini" set "_dsk=%PUBLIC%\Desktop"
setlocal EnableDelayedExpansion

if defined _args goto :chkarg
if not exist "!_work!\*.AggregatedMetadata*.cab" (goto :continue
) else if not exist "!_work!\Windows1*-KB*.psf" (goto :continue
)
if not exist "!_work!\Windows1*-KB*.cab" if not exist "!_work!\Windows1*-KB*.wim" goto :continue
if exist "!_work!\*DesktopDeployment*.cab" set "_repo=!_work!"
if exist "!_work!\SSU-*-*.cab" set "_repo=!_work!"
if not defined _repo goto :continue
if exist "!_work!\Windows1*-KB*.cab" (set xmf=cab
) else if exist "!_work!\Windows1*-KB*.wim" (set xmf=wim
)
goto :continue

:chkarg
if not exist "!_args!\*.AggregatedMetadata*.cab" (goto :continue
) else if not exist "!_args!\Windows1*-KB*.psf" (goto :continue
)
if not exist "!_args!\Windows1*-KB*.cab" if not exist "!_args!\Windows1*-KB*.wim" goto :continue
if exist "!_args!\*DesktopDeployment*.cab" set "_repo=!_args!"
if exist "!_args!\SSU-*-*.cab" set "_repo=!_args!"
if not defined _repo goto :continue
if exist "!_args!\Windows1*-KB*.cab" (set xmf=cab
) else if exist "!_args!\Windows1*-KB*.wim" (set xmf=wim
)
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
echo The window will be closed when finished
@echo on
@prompt $G
@call :Begin >"!_log!_tmp.log" 2>&1 &cmd /u /c type "!_log!_tmp.log">"!_log!_Debug.log"&del "!_log!_tmp.log"
@color 07
@title %ComSpec%
@exit /b

:Begin
title PSFXv2 MSU Maker %uivr%
if %_Debug% equ 0 if not defined _args @cls
if not defined _repo goto :N_PT
if %xmf%==wim if not exist "!_work!\bin\imagex_%xBT%.exe" goto :E_Bin
pushd "!_repo!"
for /f "delims=" %%# in ('dir /b /a:-d "*.AggregatedMetadata*.cab"') do set "metaf=%%#"
if /i "%metaf%"=="%onf%" (
ren "%metaf%" "org_%metaf%"
set "metaf=org_%metaf%"
)
if %xmf%==cab (
expand.exe -f:LCUCompDB*.xml.cab "%metaf%" . %_Null%
if not exist "LCUCompDB*.xml.cab" goto :E_DB
)
if %xmf%==wim (
if exist "_tMSU\" rmdir /s /q "_tMSU\" %_Nul3%
mkdir "_tMSU"
expand.exe -f:*.AggregatedMetadata*.cab "%metaf%" "_tMSU" %_Null%
if not exist "_tMSU\*.AggregatedMetadata*.cab" goto :E_DB
for /f %%# in ('dir /b /a:-d "_tMSU\*.AggregatedMetadata*.cab"') do expand.exe -f:*.xml "_tMSU\%%#" "_tMSU" %_Null%
if not exist "_tMSU\LCUCompDB*.xml" goto :E_DB
for /f %%# in ('dir /b /a:-d "_tMSU\LCUCompDB*.xml"') do (
%_Null% makecab.exe /D Compress=ON /D CompressionType=MSZIP "_tMSU\%%~n#.xml" "_tMSU\%%~n#.xml.cab"
)
if exist "_tMSU\SSUCompDB*.xml" for /f %%# in ('dir /b /a:-d "_tMSU\SSUCompDB*.xml"') do (
%_Null% makecab.exe /D Compress=ON /D CompressionType=MSZIP "_tMSU\%%~n#.xml" "_tMSU\%%~n#.xml.cab"
)
if not exist "_tMSU\LCUCompDB*.xml.cab" (echo makecab.exe LCUCompDB failed&goto :TheEnd)
del /f /q "_tMSU\*.AggregatedMetadata*.cab" %_Nul3%
copy /y "_tMSU\*.cab" . %_Nul3%
rmdir /s /q "_tMSU\" %_Nul3%
)
for /f %%# in ('dir /b /a:-d "LCUCompDB*.xml.cab"') do set "dblcu=%%#"
for /f "tokens=2 delims=_." %%# in ('echo %dblcu%') do set "kbn=%%#"
if not exist "Windows1*%kbn%*.%xmf%" set xtn=%xmf%&goto :E_KB
if not exist "Windows1*%kbn%*.psf" set xtn=psf&goto :E_KB
for /f "tokens=3 delims=-_" %%# in ('dir /b /a:-d "Windows1*%kbn%*.psf"') do set "bit=%%~n#"
if exist "Windows1*%kbn%*%bit%*.msu" goto :N_MS
for /f "delims=" %%# in ('dir /b /a:-d "Windows1*%kbn%*%bit%*.%xmf%"') do set "_sCAB=%%#"
for /f "delims=" %%# in ('dir /b /a:-d "Windows1*%kbn%*%bit%*.psf"') do set "_sPSF=%%#"
set "kbf=Windows10.0-%kbn%-%bit%"
if /i "%_sCAB:~0,10%"=="Windows11." set "kbf=Windows11.0-%kbn%-%bit%"
if /i "%_sCAB:~0,10%"=="Windows12." set "kbf=Windows12.0-%kbn%-%bit%"
if exist "SSU-*%bit%*.cab" (
for /f "tokens=2 delims=-" %%# in ('dir /b /a:-d "SSU-*%bit%*.cab"') do set "suf=SSU-%%#-%bit%.cab"
for /f "delims=" %%# in ('dir /b /a:-d "SSU-*%bit%*.cab"') do set "_sSSU=%%#"
) else (
set IncludeSSU=0
)
if %IncludeSSU% equ 1 if not exist "SSUCompDB*.xml.cab" (
expand.exe -f:SSUCompDB*.xml.cab "%metaf%" . %_Null%
if exist "SSU*-express.xml.cab" del /f /q "SSU*-express.xml.cab"
)
if exist "SSUCompDB*.xml.cab" (for /f %%# in ('dir /b /a:-d "SSUCompDB*.xml.cab"') do set "dbssu=%%#") else (set IncludeSSU=0)
set "_sDDD=DesktopDeployment_x86.cab"
if exist "*DesktopDeployment*.cab" (
for /f "delims=" %%# in ('dir /b /a:-d "*DesktopDeployment*.cab" ^|find /i /v "%_sDDD%"') do set "_sDDC=%%#"
)
if exist "%SysPath%\ucrtbase.dll" call :dodpx
if not defined _sDDC (
call set "_sDDC=DesktopDeployment.cab"
call :DDCAB
)
if %_fail% equ 1 goto :TheEnd
if defined suf if /i not %bit%==x86 if not exist "%_sDDD%" call :DDC86
call :DDF %onf%
(echo "%dblcu%"
if %IncludeSSU% equ 1 echo "%dbssu%"
)>>zzz.ddf
%_Null% makecab.exe /F zzz.ddf /D Compress=ON /D CompressionType=MSZIP
if %ERRORLEVEL% neq 0 (echo makecab.exe %onf% failed&goto :TheEnd)
if %xmf%==wim goto :DDWIM
call :DDF %kbf%.msu
(echo "%_sDDC%" "DesktopDeployment.cab"
if exist "%_sDDD%" echo "%_sDDD%" "DesktopDeployment_x86.cab"
echo "%onf%"
if %IncludeSSU% equ 1 echo "%_sSSU%" "%suf%"
echo "%_sCAB%" "%kbf%.cab"
echo "%_sPSF%" "%kbf%.psf"
)>>zzz.ddf
%_Null% makecab.exe /F zzz.ddf /D Compress=OFF
if %ERRORLEVEL% neq 0 (echo makecab.exe %kbf%.msu failed&goto :TheEnd)
echo.
echo Finished
echo.
goto :TheEnd

:DDWIM
echo.
echo Creating: %kbf%.msu
if exist "_tWIM\" rmdir /s /q "_tWIM\" %_Nul3%
mkdir "_tWIM"
copy /y "%_sDDC%" "_tWIM\DesktopDeployment.cab" %_Nul3%
if exist "%_sDDD%" copy /y "%_sDDD%" "_tWIM\DesktopDeployment_x86.cab" %_Nul3%
copy /y "%onf%" "_tWIM\%onf%" %_Nul3%
if %IncludeSSU% equ 1 copy /y "%_sSSU%" "_tWIM\%suf%" %_Nul3%
copy /y "%_sCAB%" "_tWIM\%kbf%.wim" %_Nul3%
copy /y "%_sPSF%" "_tWIM\%kbf%.psf" %_Nul3%
:: %_Nul3% dism.exe /Capture-Image /ImageFile:%kbf%.msu /CaptureDir:_tWIM\ /Name:content /Compress:none /noacl:all
%_Nul3% "!_work!\bin\imagex_%xBT%.exe" /CAPTURE _tWIM\ %kbf%.msu content /COMPRESS none /NOACL ALL /NOTADMIN /TEMP "!_temp!"
if %ERRORLEVEL% neq 0 (echo wim capture %kbf%.msu failed&goto :TheEnd)
echo.
echo Finished
echo.
goto :TheEnd

:DDCAB
echo.
echo Extracting: %_sSSU%
if exist "_tmpSSU\" rmdir /s /q "_tmpSSU\" %_Nul3%
mkdir "_tmpSSU\000"
expand.exe -f:* %_sSSU% _tmpSSU %_Null% || (
  rmdir /s /q "_tmpSSU\" %_Nul3%
  echo failed.
  echo.
  echo Provide ready DesktopDeployment.cab and try again
  echo.
  set _fail=1
  goto :eof
)
set xbt=%bit%
if /i %bit%==x64 set xbt=amd64
for /f %%# in ('dir /b /ad "_tmpSSU\%xbt%_microsoft-windows-servicingstack_*"') do set "src=%%#"
for %%# in (%sdl%) do if exist "_tmpSSU\%src%\%%#" (move /y "_tmpSSU\%src%\%%#" "_tmpSSU\000\%%#" %_Nul1%)
set DD64create=1
call :DDF %_sDDC%
call :ADD _tmpSSU\000
%_Null% makecab.exe /F zzz.ddf /D Compress=ON /D CompressionType=MSZIP
mkdir "_tmpSSU\111"
if /i not %bit%==x86 if not exist "DesktopDeployment_x86.cab" goto :DDCdu
rmdir /s /q "_tmpSSU\" %_Nul3%
exit /b

:DDC86
echo.
echo Extracting: %_sSSU%
if exist "_tmpSSU\" rmdir /s /q "_tmpSSU\" %_Nul3%
mkdir "_tmpSSU\111"
expand.exe -f:* %_sSSU% _tmpSSU %_Null% || (
  rmdir /s /q "_tmpSSU\" %_Nul3%
  echo failed.
  echo.
  echo Skipping DesktopDeployment_x86.cab
  echo see ReadMe.txt for more details
  goto :eof
)
:DDCdu
for /f %%# in ('dir /b /ad "_tmpSSU\x86_microsoft-windows-servicingstack_*"') do set "src=%%#"
for %%# in (%sdl%) do if exist "_tmpSSU\%src%\%%#" (move /y "_tmpSSU\%src%\%%#" "_tmpSSU\111\%%#" %_Nul1%)
set DD86create=1
call :DDF %_sDDD%
call :ADD _tmpSSU\111
%_Null% makecab.exe /F zzz.ddf /D Compress=ON /D CompressionType=MSZIP
rmdir /s /q "_tmpSSU\" %_Nul3%
exit /b

:DDF
echo.
echo Creating: %1
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

:ADD
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
if /i %bit%==%xBT% set _nat=1
if %_nat% equ 0 set _wow=1

if exist "!_repo!\dpx.dll" if not exist "!_repo!\expand.exe" (
  if %_wow% equ 1 copy /y %SystemRoot%\SysWOW64\expand.exe "!_repo!\" %_Nul3%
  if %_nat% equ 1 copy /y %SysPath%\expand.exe "!_repo!\" %_Nul3%
  set _exd=1
  exit /b
)
if %_wow% equ 1 if exist "%_sDDD%" (
expand.exe -f:dpx.dll "%_sDDD%" "!_repo!" %_Nul3%
if exist "!_repo!\dpx.dll" (
  copy /y %SystemRoot%\SysWOW64\expand.exe "!_repo!\" %_Nul3%
  set _dpx=1
  exit /b
  )
)
if %_nat% equ 1 if defined _sDDC (
expand.exe -f:dpx.dll "%_sDDC%" "!_repo!" %_Nul3%
if exist "!_repo!\dpx.dll" (
  copy /y %SysPath%\expand.exe "!_repo!\" %_Nul3%
  set _dpx=1
  exit /b
  )
)
exit /b

:E_Bin
echo.
echo %_err%
echo.
echo Required file "bin\imagex_%xBT%.exe" is missing
echo.
goto :TheEnd

:E_KB
echo.
echo %_err%
echo.
echo LCU %kbn% %xtn% file is missing
echo.
goto :TheEnd

:E_DB
echo.
echo %_err%
echo.
echo LCUCompDB file is missing from AggregatedMetadata
echo.
goto :TheEnd

:N_MS
echo.
echo %_ntc%
echo.
echo LCU %kbn% msu file already exist
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
if exist "LCUCompDB*.xml.cab" del /f /q "LCUCompDB*.xml.cab"
if exist "SSUCompDB*.xml.cab" del /f /q "SSUCompDB*.xml.cab"
if exist "%onf%" del /f /q "%onf%"
if %DD86create% equ 1 if exist "DesktopDeployment_x86.cab" del /f /q "DesktopDeployment_x86.cab"
if %DD64create% equ 1 if exist "DesktopDeployment.cab" del /f /q "DesktopDeployment.cab"
if %_exd% equ 1 (
if exist "expand.exe" del /f /q "expand.exe" %_Nul3%
)
if %_dpx% equ 1 (
if exist "dpx.dll" del /f /q "dpx.dll" %_Nul3%
if exist "expand.exe" del /f /q "expand.exe" %_Nul3%
)
if exist "_tWIM\" rmdir /s /q "_tWIM\" %_Nul3%
if exist "_tMSU\" rmdir /s /q "_tMSU\" %_Nul3%
%_Exit%
%_Pause%
goto :eof
