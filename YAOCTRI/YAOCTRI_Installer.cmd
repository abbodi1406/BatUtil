@cls
@echo off
set "SysPath=%Windir%\System32"
if exist "%Windir%\Sysnative\reg.exe" (set "SysPath=%Windir%\Sysnative")
set "Path=%SysPath%;%Windir%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
set "xOS=x64"
set "_ComSpec=%Windir%\System32\cmd.exe"
set "_Common=%CommonProgramFiles%"
set "_Program=%ProgramFiles%"
if /i %PROCESSOR_ARCHITECTURE%==x86 (
if not defined PROCESSOR_ARCHITEW6432 set "xOS=x86"
if defined PROCESSOR_ARCHITEW6432 (
  set "_ComSpec=%Windir%\Sysnative\cmd.exe"
  set "_Common=%CommonProgramW6432%"
  set "_Program=%ProgramW6432%"
  )
)
set "_target=%_Common%\Microsoft Shared\ClickToRun"
set "_file=%_target%\OfficeClickToRun.exe"
set "_tempdir=%temp%"
set "_workdir=%~dp0"
if "%_workdir:~-1%"=="\" set "_workdir=%_workdir:~0,-1%"
setlocal EnableDelayedExpansion
fsutil dirty query %systemdrive% >nul 2>&1 || goto :E_Admin
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G
if %winbuild% lss 7601 goto :E_Win
title Office Click-to-Run Installer - Volume
set _updt=True
set _eula=True
set _icon=False
set _shut=True
set _disp=True
set _actv=False
set _tele=True
set _unattend=False
set "line=============================================================="
if exist "!_workdir!\C2R*.ini" for /f %%# in ('dir /b "!_workdir!\C2R*.ini"') do (set "C2Rconfig=%%#"&goto :check)

:prompt
cls
set "C2Rconfig="
echo %line%
echo Enter C2R_Config ini file path
echo %line%
echo.
set /p "C2Rconfig="
if "%C2Rconfig%"=="" goto :eof
goto :check

:check
findstr /i \[configuration\] "!C2Rconfig!" 1>nul 2>nul || goto :prompt
call :ReadINI SourcePath CTRsource
call :ReadINI Type CTRtype
call :ReadINI Version CTRver
call :ReadINI Architecture CTRarc
call :ReadINI O32W64 wow64
call :ReadINI Language CTRlng
call :ReadINI LCID CTRcul
call :ReadINI Channel CTRchn
call :ReadINI CDN CTRffn
call :ReadINI UpdatesEnabled _updt
call :ReadINI AcceptEULA _eula
call :ReadINI PinIconsToTaskbar _icon
call :ReadINI ForceAppShutdown _shut
call :ReadINI DisplayLevel _disp
call :ReadINI AutoActivate _actv
call :ReadINI DisableTelemetry _tele
call :ReadINI AutoInstallation _unattend
call :ReadINI2 "Suite=" _suite
call :ReadINI2 Suite2 _suit2
call :ReadINI2 ExcludedApps _excluded
call :ReadINI2 SKUs _skus
set CTRstp=%CTRlng%
findstr /b /i "Primary" "!C2Rconfig!" 1>nul 2>nul && for /f "tokens=2,3 delims==," %%A in ('findstr /b /i "Primary" "!C2Rconfig!" 2^>nul') do (
set "CTRstp=%%A"
set "CTRcul=%%B"
)
goto :check2

:ReadINI
for /f "tokens=1* delims==" %%A in ('findstr /b /i "%1" "!C2Rconfig!" 2^>nul') do set "%2=%%~B"
goto :eof

:ReadINI2
findstr /b /i "%~1" "!C2Rconfig!" 1>nul 2>nul && for /f "tokens=1* delims==" %%A in ('findstr /b /i "%~1" "!C2Rconfig!" 2^>nul') do set "%2=%%~B"
goto :eof

:check2
for %%# in (
CTRtype
CTRver
CTRarc
CTRlng
CTRcul
CTRffn
) do if not defined %%# (
echo.
echo ==== ERROR ====
echo Could not detect %%# in the specified config file
echo.
echo Press any key to exit...
pause >nul
goto :eof
)
if not defined _suite if not defined _skus (
echo.
echo ==== ERROR ====
echo Could not detect products in the specified config file
echo.
echo Press any key to exit...
pause >nul
goto :eof
)
if defined CTRsource if exist "!CTRsource!\Office\Data\*.cab" (
goto :check3
) else (
set "CTRsource="
)
if exist "!_workdir!\Office\Data\*.cab" (
for /f %%# in ('dir /b /ad "!_workdir!\Office\Data\" 2^>nul') do if exist "!_workdir!\Office\Data\%%#\stream*.dat" (
  set "CTRsource=%_workdir%"
  )
)
if defined CTRsource goto :check3
if exist "!_workdir!\Data\*.cab" (
for /f %%# in ('dir /b /ad "!_workdir!\Data\" 2^>nul') do if exist "!_workdir!\Data\%%#\stream*.dat" (
  call :get_path "!_workdir!\..\"
  )
)
if defined CTRsource goto :check3
for %%# in (C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do (
if exist "%%#:\Office\Data\*.cab" set "CTRsource=%%#:\"
)
if defined CTRsource goto :check3

echo ==== ERROR ====
echo Could not detect C2R source in the specified config file
echo.
echo Press any key to exit...
pause >nul
goto :eof

:get_path
endlocal
set "CTRsource=%~dp1"
exit /b

:check3
setlocal EnableDelayedExpansion
if "!CTRsource:~-1!"=="\" set "CTRsource=!CTRsource:~0,-1!"
copy /y nul "!CTRsource!\Office\#.rw" 1>nul 2>nul && (
set CTRtype=Local
if exist "!CTRsource!\Office\#.rw" del /f /q "!CTRsource!\Office\#.rw"
) || (
set CTRtype=DVD
)
if "!CTRsource:~0,2!"=="\\" set CTRtype=UNC

if /i %CTRarc%==x86 (set CTRbit=32) else (set CTRbit=64)
set CTRvcab=v%CTRbit%_%CTRver%.cab
set CTRicab=i%CTRbit%0.cab
set CTRscab=s%CTRbit%0.cab
set CTRicabr=i%CTRbit%%CTRcul%.cab
set CTRscabr=s%CTRbit%%CTRcul%.cab
if %wow64%==1 (
set CTRicab=i640.cab
set CTRicabr=i64%CTRcul%.cab
)
if not exist "!CTRsource!\Office\Data\%CTRvcab%" set "ERRFILE=%CTRvcab%"&goto :E_FILE
for %%# in (
%CTRicab%
%CTRscab%
%CTRicabr%
%CTRscabr%
stream.%CTRarc%.x-none.dat
stream.%CTRarc%.%CTRstp%.dat
) do (
if not exist "!CTRsource!\Office\Data\%CTRver%\%%#" set "ERRFILE=%%#"&goto :E_FILE
)

if defined _suite (
set "_products=%_suite%.16_%CTRlng%_x-none"
if /i "%_suite%"=="ProPlus2019Volume" set _pkey0=NMMKJ-6RK4F-KMJVX-8D9MJ-6MWKP
if /i "%_suite%"=="Standard2019Volume" set _pkey0=6NWWJ-YQWMR-QKGCB-6TMB3-9D9HK
if /i "%_suite%"=="MondoVolume" set _pkey0=HFTND-W9MK4-8B7MJ-B6C4G-XQBR2
)
if defined _suit2 (
set "_licenses=%_suit2%"
if /i "%_suit2%"=="ProPlus2019Volume" set _pkey0=NMMKJ-6RK4F-KMJVX-8D9MJ-6MWKP
if /i "%_suit2%"=="Standard2019Volume" set _pkey0=6NWWJ-YQWMR-QKGCB-6TMB3-9D9HK
if /i "%_suit2%"=="MondoVolume" set _pkey0=HFTND-W9MK4-8B7MJ-B6C4G-XQBR2
)
set _OneDrive=ON
if defined _excluded (
echo %_excluded%| findstr /i "OneDrive" 1>nul && set _OneDrive=OFF
)
if defined _pkey0 set "_keys=%_pkey0%"

if not defined _skus goto :MenuFinal

set /a kk=0
for %%J in (%_skus%) do (
set _tmp=%%J
if /i "!_tmp:~-6!"=="Volume" (
  if defined _show (set "_show=!_show!,%%J") else (set "_show=%%J")
  )
if /i "!_tmp:~-6!"=="Volume" if %winbuild% lss 10240 (
  if defined _licenses (set "_licenses=!_licenses!,%%J") else (set "_licenses=%%J")
  )
if /i "!_tmp:~-6!"=="Volume" if %winbuild% geq 10240 (
  if defined _products (set "_products=!_products!^|%%J.16_%CTRlng%_x-none") else (set "_products=%%J.16_%CTRlng%_x-none")
  if %_OneDrive%==OFF (if defined _exclude1d (set "_exclude1d=!_exclude1d! %%J.excludedapps.16=onedrive") else (set "_exclude1d=%%J.excludedapps.16=onedrive"))
  )
if /i "!_tmp:~-6!"=="Retail" (
  if defined _products (set "_products=!_products!^|%%J.16_%CTRlng%_x-none") else (set "_products=%%J.16_%CTRlng%_x-none")
  if %_OneDrive%==OFF (if defined _exclude1d (set "_exclude1d=!_exclude1d! %%J.excludedapps.16=onedrive") else (set "_exclude1d=%%J.excludedapps.16=onedrive"))
  )
if /i "%%J"=="Access2019Volume" (set /a kk+=1&set _pkey!kk!=9N9PT-27V4Y-VJ2PD-YXFMF-YTFQT)
if /i "%%J"=="Excel2019Volume" (set /a kk+=1&set _pkey!kk!=TMJWT-YYNMB-3BKTF-644FC-RVXBD)
if /i "%%J"=="Outlook2019Volume" (set /a kk+=1&set _pkey!kk!=7HD7K-N4PVK-BHBCQ-YWQRW-XW4VK)
if /i "%%J"=="PowerPoint2019Volume" (set /a kk+=1&set _pkey!kk!=RRNCX-C64HY-W2MM7-MCH9G-TJHMQ)
if /i "%%J"=="Publisher2019Volume" (set /a kk+=1&set _pkey!kk!=G2KWX-3NW6P-PY93R-JXK2T-C9Y9V)
if /i "%%J"=="SkypeForBusiness2019Volume" (set /a kk+=1&set _pkey!kk!=NCJ33-JHBBY-HTK98-MYCV8-HMKHJ)
if /i "%%J"=="Word2019Volume" (set /a kk+=1&set _pkey!kk!=PBX3G-NWMT6-Q7XBW-PYJGG-WXD33)
if /i "%%J"=="OneNoteVolume" (set /a kk+=1&set _pkey!kk!=DR92N-9HTF2-97XKM-XW2WJ-XW3J6)
if /i "%%J"=="ProjectPro2019Volume" (set /a kk+=1&set _pkey!kk!=B4NPR-3FKK7-T2MBV-FRQ4W-PKD2B)
if /i "%%J"=="ProjectStd2019Volume" (set /a kk+=1&set _pkey!kk!=C4F7P-NCP8C-6CQPT-MQHV9-JXD2M)
if /i "%%J"=="VisioPro2019Volume" (set /a kk+=1&set _pkey!kk!=9BGNQ-K37YR-RQHF2-38RQ3-7VCBB)
if /i "%%J"=="VisioStd2019Volume" (set /a kk+=1&set _pkey!kk!=7TQNQ-K3YQQ-3PFH7-CCPPM-X4VQ2)
)

for /l %%J in (1,1,%kk%) do (
if defined _keys (set "_keys=!_keys!,!_pkey%%J!") else (set "_keys=!_pkey%%J!")
)

:MenuFinal
if %_unattend%==True goto :MenuInstall
cls
echo %line%
echo Source  : "!CTRsource!"
echo Version : %CTRver% / Arch: %CTRarc% / Lang: %CTRlng%
echo Channel : %CTRchn%
echo CDN     : %CTRffn%
if defined _suite (
if defined _suit2 (
  if /i not "%_suit2%"=="MondoVolume" (echo Suite   : %_suit2%) else (echo Suite   : %_suite%)
  ) else (
  echo Suite   : %_suite%
  )
)
if defined _skus echo SKUs    : %_show%
if defined _excluded echo Excluded: %_excluded%
echo Updates : %_updt% / AcceptEULA : %_eula% / Display : %_disp%
echo PinIcons: %_icon% / AppShutdown: %_shut% / Activate: %_actv%
echo %line%
echo.
echo. 1. Install Now
echo. 2. Exit
echo.
echo %line%
choice /c 12 /n /m "Choose a menu option: "
if errorlevel 2 goto :eof
if errorlevel 1 goto :MenuInstall
goto :MenuFinal

:MenuInstall
cls
echo %line%
echo Preparing... 
echo %line%
echo.
if defined _excluded (
for %%# in (a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z) do set _excluded=!_excluded:%%#=%%#!
)
if %_actv%==True (set "_autoact=autoactivate=1"&set "_activate=Activate=1") else (set "_autoact="&set "_activate=")
set "_CTR=HKLM\SOFTWARE\Microsoft\Office\ClickToRun"
set "_Config=%_CTR%\Configuration"
set "_url=http://officecdn.microsoft.com/pr"

(
echo @echo off
echo reg.exe query "HKU\S-1-5-19" 1^>nul 2^>nul ^|^| ^(echo Run the script as administrator^&pause^&exit^)
echo reg.exe delete %_Config% /f /v UpdateUrl 1^>nul 2^>nul
echo reg.exe delete %_Config% /f /v UpdateToVersion 1^>nul 2^>nul
echo reg.exe delete %_CTR%\Updates /f /v UpdateToVersion 1^>nul 2^>nul
echo reg.exe delete HKLM\SOFTWARE\Policies\Microsoft\Office\16.0\Common\OfficeUpdate /f 1^>nul 2^>nul
echo start "" /WAIT "%%CommonProgramFiles%%\Microsoft Shared\ClickToRun\OfficeClickToRun.exe" ^^
echo deliverymechanism=%CTRffn% platform=%CTRarc% culture=%CTRstp% b= displaylevel=%_disp% ^^
echo forceappshutdown=%_shut% piniconstotaskbar=%_icon% acceptalleulas.16=%_eula% ^^
echo updatesenabled.16=%_updt% updatepromptuser=True ^^
echo updatebaseurl.16=%_url%/%CTRffn% ^^
echo cdnbaseurl.16=%_url%/%CTRffn% ^^
echo mediatype.16=%CTRtype% sourcetype.16=%CTRtype% version.16=%CTRver% ^^
echo baseurl.16="!CTRsource!" ^^^^
echo productstoadd="%_products%" ^^
if %winbuild% geq 10240 echo pidkeys=%_keys% %_autoact% ^^
if defined _suite echo %_suite%.excludedapps.16=%_excluded% ^^
if defined _exclude1d echo %_exclude1d% ^^
echo flt.useexptransportinplacepl=disabled flt.useofficehelperaddon=disabled flt.useoutlookshareaddon=disabled 1^>nul 2^>nul
echo reg.exe add %_Config% /f /v UpdateChannel /t REG_SZ /d "%_url%/%CTRffn%" 1^>nul 2^>nul
echo reg.exe add %_Config% /f /v UpdateChannelChanged /t REG_SZ /d True 1^>nul 2^>nul
echo exit /b
)>"!_tempdir!\C2R_Setup.bat"

set "CTRexe=1"
if exist "!_file!" for /f "tokens=2-5 delims==." %%i in ('wmic datafile where "name='!_file:\=\\!'" get Version /value') do (
  if %%i%%j%%k%%l geq %CTRver:.=% (set CTRexe=0)
)
call :StopService 1>nul 2>nul
if %CTRexe%==1 (
if exist "!_target!" rd /s /q "!_target!" 1>nul 2>nul
md "!_target!" 1>nul 2>nul
expand -f:* "!CTRsource!\Office\Data\%CTRver%\%CTRicab%" "!_target!" 1>nul 2>nul
expand -f:* "!CTRsource!\Office\Data\%CTRver%\%CTRicabr%" "!_target!" 1>nul 2>nul
)
echo.
echo %line%
echo Running installation... 
echo %line%
echo.
del /f /q "%windir%\temp\*.log" 1>nul 2>nul
del /f /q "!_tempdir!\*.log" 1>nul 2>nul
!_ComSpec! /c ""!_tempdir!\C2R_Setup.bat" "
del /f /q "!_tempdir!\C2R_Setup.bat" 1>nul 2>nul
if not exist "!_Program!\Microsoft Office\root\Office16\*.dll" if not exist "%ProgramFiles(x86)%\Microsoft Office\root\Office16\*.dll" (
echo.
echo %line%
echo Installation failed.
echo %line%
echo.
echo Press any key to exit.
pause >nul
goto :eof
)
if defined _licenses (
echo.
echo %line%
echo Installing Volume Licenses... 
echo %line%
echo.
call :Licenses 1>nul 2>nul
)
if %_tele%==True (
if defined _suit2 (
  if /i not "%_suit2%"=="MondoVolume" call :Telemetry 1>nul 2>nul
  ) else (
  call :Telemetry 1>nul 2>nul
  )
)
if %_unattend%==True goto :eof
echo.
echo %line%
echo Done.
echo %line%
echo.
echo Press any key to exit.
pause >nul
taskkill /t /f /IM OfficeC2RClient.exe 1>nul 2>nul
goto :eof

:StopService
sc query WSearch | find /i "STOPPED" || net stop WSearch /y
sc query WSearch | find /i "STOPPED" || sc stop WSearch
if exist "!_file!" (
sc query ClickToRunSvc | find /i "STOPPED" || net stop ClickToRunSvc /y
sc query ClickToRunSvc | find /i "STOPPED" || sc stop ClickToRunSvc
taskkill /t /f /IM OfficeC2RClient.exe
taskkill /t /f /IM OfficeClickToRun.exe
)
exit /b

:Licenses
for /f "skip=2 tokens=2*" %%A in ('reg query %_CTR% /v InstallPath') do set "_Root=%%B\root"
for /f "skip=2 tokens=2*" %%A in ('reg query %_CTR% /v PackageGUID') do set "_GUID=%%B"
for %%J in (%_licenses%) do (
if defined _ids (set "_ids=!_ids!,%%J.16") else (set "_ids=%%J.16")
reg delete %_Config% /f /v %%J.OSPPReady
)
"!_Root!\integration\integrator.exe" /I /License PRIDName=%_ids% PidKey=%_keys% %_activate% PackageGUID="%_GUID%" PackageRoot="!_Root!"
for %%J in (%_licenses%) do (
reg query %_Config% /v ProductReleaseIds | findstr /I "%%J" || (for /f "skip=2 tokens=2*" %%A in ('reg query %_Config% /v ProductReleaseIds') do reg add %_Config% /f /v ProductReleaseIds /t REG_SZ /d "%%J,%%B")
reg add %_Config% /f /v %%J.OSPPReady /t REG_SZ /d 1
)
exit /b

:Telemetry
if %wow64%==1 (set "_inter=Software\Wow6432Node") else (set "_inter=Software")
set "_rkey=%_CTR%\REGISTRY\MACHINE\%_inter%\Microsoft\Office\16.0\User Settings\CustomSettings"
set "_skey=%_CTR%\REGISTRY\MACHINE\%_inter%\Microsoft\Office\16.0\User Settings\CustomSettings\Create\Software\Microsoft\Office\16.0"
set "_tkey=%_CTR%\REGISTRY\MACHINE\%_inter%\Microsoft\Office\16.0\User Settings\CustomSettings\Create\Software\Microsoft\Office\Common\ClientTelemetry"
for %%# in (Count,Order) do reg add "%_rkey%" /f /v %%# /t REG_DWORD /d 1
for %%# in (DisableTelemetry,SendTelemetry) do reg add "%_tkey%" /f /v %%# /t REG_DWORD /d 1
for %%# in (qmenable,sendcustomerdata,updatereliabilitydata) do reg add "%_skey%\Common" /f /v %%# /t REG_DWORD /d 0
for %%# in (disableboottoofficestart,optindisable,shownfirstrunoptin,ShownFileFmtPrompt) do reg add "%_skey%\Common\General" /f /v %%# /t REG_DWORD /d 1
for %%# in (BootedRTM,disablemovie) do reg add "%_skey%\Firstrun" /f /v %%# /t REG_DWORD /d 1
for %%# in (EnableLogging,EnableUpload) do reg add "%_skey%\OSM" /f /v %%# /t REG_DWORD /d 0
for %%# in (accesssolution,olksolution,onenotesolution,pptsolution,projectsolution,publishersolution,visiosolution,wdsolution,xlsolution) do reg add "%_skey%\OSM\PreventedApplications" /f /v %%# /t REG_DWORD /d 1
for %%# in (agave,appaddins,comaddins,documentfiles,templatefiles) do reg add "%_skey%\OSM\PreventedSolutiontypes" /f /v %%# /t REG_DWORD /d 1
reg add "%_skey%\Common\Security\FileValidation" /f /v disablereporting /t REG_DWORD /d 1
reg add "%_skey%\Common\PTWatson" /f /v PTWOptIn /t REG_DWORD /d 0
reg add "%_skey%\Lync" /f /v disableautomaticsendtracing /t REG_DWORD /d 1
reg add "%_skey%\Outlook\Options\Mail" /f /v EnableLogging /t REG_DWORD /d 0
reg add "%_skey%\Word\Options" /f /v EnableLogging /t REG_DWORD /d 0
set "_schtasks=SCHTASKS /Change /DISABLE /TN"
set "_schedule=Microsoft\Office"
%_schtasks% "%_schedule%\OfficeInventoryAgentFallBack"
%_schtasks% "%_schedule%\OfficeTelemetryAgentFallBack"
%_schtasks% "%_schedule%\OfficeTelemetryAgentFallBack2016"
%_schtasks% "%_schedule%\OfficeInventoryAgentLogOn"
%_schtasks% "%_schedule%\OfficeTelemetryAgentLogOn"
%_schtasks% "%_schedule%\OfficeTelemetryAgentLogOn2016"
exit /b

:E_FILE
echo ==== ERROR ====
echo %ERRFILE% is missing in the specified source
echo.
echo Press any key to exit...
pause >nul
goto :eof

:E_Admin
echo ==== ERROR ====
echo Right click on this script and select 'Run as administrator'
echo.
echo Press any key to exit...
pause >nul
goto :eof

:E_Win
echo ==== ERROR ====
echo Windows 7 SP1 is the minimum supported OS.
echo.
echo Press any key to exit...
pause >nul
goto :eof
