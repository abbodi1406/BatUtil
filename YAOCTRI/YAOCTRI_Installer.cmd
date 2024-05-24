@setlocal DisableDelayedExpansion
@echo off
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
set _silent=0
set "_args=%*"
if not defined _args goto :NoProgArgs
if "%~1"=="" set "_args="&goto :NoProgArgs
set _args=%_args:"=%
for %%A in (%_args%) do (
if /i "%%A"=="/s" (set _silent=1
) else if /i "%%A"=="-s" (set _silent=1)
)

:NoProgArgs
set "SysPath=%SystemRoot%\System32"
set "Path=%SystemRoot%\System32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
if exist "%SystemRoot%\Sysnative\reg.exe" (
set "SysPath=%SystemRoot%\Sysnative"
set "Path=%SystemRoot%\Sysnative;%SystemRoot%;%SystemRoot%\Sysnative\Wbem;%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\;%Path%"
)
set "_err===== ERROR ===="
set winbuild=1
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G
if %winbuild% lss 7601 goto :E_Win
set _cwmi=0
for %%# in (wmic.exe) do @if not "%%~$PATH:#"=="" (
wmic path Win32_ComputerSystem get CreationClassName /value 2>nul | find /i "ComputerSystem" 1>nul && set _cwmi=1
)
set _pwsh=1
for %%# in (powershell.exe) do @if "%%~$PATH:#"=="" set _pwsh=0
if %_cwmi% equ 0 if %_pwsh% equ 0 goto :E_WMI
reg query HKU\S-1-5-19 >nul 2>&1 || goto :E_Admin
set "xOS=x64"
set "_ComSpec=%SystemRoot%\System32\cmd.exe"
set "_Common=%CommonProgramFiles%"
set "_Program=%ProgramFiles%"
if /i %PROCESSOR_ARCHITECTURE%==x86 (if defined PROCESSOR_ARCHITEW6432 (
  set "_ComSpec=%SystemRoot%\Sysnative\cmd.exe"
  set "_Common=%CommonProgramW6432%"
  set "_Program=%ProgramW6432%"
  ) else (
  set "xOS=x86"
  )
)
set "_target=%_Common%\Microsoft Shared\ClickToRun"
set "_file=%_target%\OfficeClickToRun.exe"
set "_temp=%temp%"
set "_work=%~dp0"
set "_work=%_work:~0,-1%"

@title Office Click-to-Run Installer - Volume
setlocal EnableDelayedExpansion
set _updt=True
set _eula=True
set _icon=False
set _shut=True
set _disp=True
set _actv=False
set _tele=True
set _unattend=False
set "line=============================================================="
if exist "!_work!\C2R_*.ini" for /f "tokens=* delims=" %%# in ('dir /b "!_work!\C2R_*.ini"') do set "C2Rconfig=!_work!\%%#"
if defined C2Rconfig goto :check

:prompt
cls
set C2Rconfig=
echo %line%
echo Enter C2R_Config ini file path
echo %line%
echo.
set /p C2Rconfig=
if not defined C2Rconfig goto :eof
set "C2Rconfig=%C2Rconfig:"=%"
if not exist "!C2Rconfig!" goto :eof

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
echo %_err%
echo Could not detect %%# in the specified config file
goto :TheEnd
)
if not defined _suite if not defined _skus (
echo.
echo %_err%
echo Could not detect products in the specified config file
goto :TheEnd
)
if defined CTRsource if exist "!CTRsource!\Office\Data\*.cab" (
goto :check3
) else (
set "CTRsource="
)
if exist "!_work!\Office\Data\*.cab" (
for /f %%# in ('dir /b /ad "!_work!\Office\Data\" 2^>nul') do if exist "!_work!\Office\Data\%%#\stream*.dat" (
  set "CTRsource=%~dp0"
  )
)
if defined CTRsource goto :check3
if exist "!_work!\Data\*.cab" (
for /f %%# in ('dir /b /ad "!_work!\Data\" 2^>nul') do if exist "!_work!\Data\%%#\stream*.dat" (
  for /D %%G in ("!_work!\..\") do set "CTRsource=%%~dpG"
  )
)
if defined CTRsource goto :check3
for %%# in (C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do (
if exist "%%#:\Office\Data\*.cab" set "CTRsource=%%#:\"
)
if defined CTRsource goto :check3

echo %_err%
echo Could not detect C2R source in the specified config file
goto :TheEnd

:check3
if "!CTRsource:~-1!"=="\" set "CTRsource=!CTRsource:~0,-1!"
copy /y nul "!CTRsource!\Office\#.rw" 1>nul 2>nul && (
set CTRtype=Local
if exist "!CTRsource!\Office\#.rw" del /f /q "!CTRsource!\Office\#.rw"
) || (
set CTRtype=DVD
)
if "!CTRsource:~0,2!"=="\\" set CTRtype=UNC

if /i %xOS%==x86 (set CTRarc=x86) else (if /i %CTRarc%==x86 set wow64=1)
if /i %CTRarc%==x86 (set CTRbit=32) else (set CTRbit=64)
set CTRvcab=v%CTRbit%_%CTRver%.cab
set CTRicab=i%CTRbit%0.cab
set CTRscab=s%CTRbit%0.cab
set CTRicabr=i%CTRbit%%CTRcul%.cab
set CTRscabr=s%CTRbit%%CTRcul%.cab
if /i %xOS%==x64 (
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

set _Of365=0
set _OneDrive=ON
if defined _excluded (
echo %_excluded%| findstr /i "OneDrive" 1>nul && set _OneDrive=OFF
)

if not defined _suite goto :sku

if %winbuild% lss 10240 (
if /i "%_suite%"=="O365ProPlusRetail" set _suit2=MondoVolume
if /i "%_suite%"=="ProPlus2019Volume" (set _suite=O365ProPlusRetail&set _suit2=ProPlus2019Volume)
if /i "%_suite%"=="Standard2019Volume" (set _suite=StandardRetail&set _suit2=Standard2019Volume)
if /i "%_suite%"=="ProPlus2021Volume" (set _suite=O365ProPlusRetail&set _suit2=ProPlus2021Volume)
if /i "%_suite%"=="Standard2021Volume" (set _suite=StandardRetail&set _suit2=Standard2021Volume)
if /i "%_suite%"=="ProPlus2024Volume" (set _suite=O365ProPlusRetail&set _suit2=ProPlus2024Volume)
if /i "%_suite%"=="Standard2024Volume" (set _suite=StandardRetail&set _suit2=Standard2024Volume)
)
if %winbuild% geq 10240 (
if /i "%_suite%"=="O365ProPlusRetail" set _suit2=MondoVolume
)

set "_products=%_suite%.16_%CTRlng%_x-none"
if /i "%_suite%"=="MondoVolume" set _pkey0=HFTND-W9MK4-8B7MJ-B6C4G-XQBR2
if /i "%_suite%"=="ProPlus2019Volume" set _pkey0=NMMKJ-6RK4F-KMJVX-8D9MJ-6MWKP
if /i "%_suite%"=="Standard2019Volume" set _pkey0=6NWWJ-YQWMR-QKGCB-6TMB3-9D9HK
if /i "%_suite%"=="ProPlus2021Volume" set _pkey0=FXYTK-NJJ8C-GB6DW-3DYQT-6F7TH
if /i "%_suite%"=="Standard2021Volume" set _pkey0=KDX7X-BNVR8-TXXGX-4Q7Y8-78VT3
if /i "%_suite%"=="ProPlus2024Volume" set _pkey0=NBBBB-BBBBB-BBBBB-BBBJD-VXRPM
if /i "%_suite%"=="Standard2024Volume" set _pkey0=V28N4-JG22K-W66P8-VTMGK-H6HGR

if defined _suit2 (
set "_licenses=%_suit2%"
if /i "%_suit2%"=="MondoVolume" set "_pkey0=HFTND-W9MK4-8B7MJ-B6C4G-XQBR2,DRNV7-VGMM2-B3G9T-4BF84-VMFTK"&set _Of365=1
if /i "%_suit2%"=="ProPlus2019Volume" set _pkey0=NMMKJ-6RK4F-KMJVX-8D9MJ-6MWKP
if /i "%_suit2%"=="Standard2019Volume" set _pkey0=6NWWJ-YQWMR-QKGCB-6TMB3-9D9HK
if /i "%_suit2%"=="ProPlus2021Volume" set _pkey0=FXYTK-NJJ8C-GB6DW-3DYQT-6F7TH
if /i "%_suit2%"=="Standard2021Volume" set _pkey0=KDX7X-BNVR8-TXXGX-4Q7Y8-78VT3
if /i "%_suit2%"=="ProPlus2024Volume" set _pkey0=NBBBB-BBBBB-BBBBB-BBBJD-VXRPM
if /i "%_suit2%"=="Standard2024Volume" set _pkey0=V28N4-JG22K-W66P8-VTMGK-H6HGR
)
if defined _pkey0 set "_keys=%_pkey0%"

if not defined _skus goto :MenuFinal

:sku
set _base=0
set /a kk=0
for %%J in (%_skus%) do (
set _tmp=%%J
if /i "!_tmp:~-6!"=="Volume" if %winbuild% geq 10240 (
  if defined _show (set "_show=!_show!,%%J") else (set "_show=%%J")
  if defined _products (set "_products=!_products!^|%%J.16_%CTRlng%_x-none") else (set "_products=%%J.16_%CTRlng%_x-none")
  if %_OneDrive%==OFF (if defined _exclude1d (set "_exclude1d=!_exclude1d! %%J.excludedapps.16=onedrive") else (set "_exclude1d=%%J.excludedapps.16=onedrive"))
  )
if /i "!_tmp:~-6!"=="Volume" if %winbuild% lss 10240 (
  if defined _show (set "_show=!_show!,%%J") else (set "_show=%%J")
  if defined _licenses (set "_licenses=!_licenses!,%%J") else (set "_licenses=%%J")
  )
if /i "!_tmp:~-6!"=="Retail" if %winbuild% lss 10240 (
  if defined _products (set "_products=!_products!^|%%J.16_%CTRlng%_x-none") else (set "_products=%%J.16_%CTRlng%_x-none")
  if %_OneDrive%==OFF (if defined _exclude1d (set "_exclude1d=!_exclude1d! %%J.excludedapps.16=onedrive") else (set "_exclude1d=%%J.excludedapps.16=onedrive"))
  set _base=1
  )
if /i "%%J"=="OneNoteVolume" (set /a kk+=1&set _pkey!kk!=DR92N-9HTF2-97XKM-XW2WJ-XW3J6)
if /i "%%J"=="Access2019Volume" (set /a kk+=1&set _pkey!kk!=9N9PT-27V4Y-VJ2PD-YXFMF-YTFQT)
if /i "%%J"=="Excel2019Volume" (set /a kk+=1&set _pkey!kk!=TMJWT-YYNMB-3BKTF-644FC-RVXBD)
if /i "%%J"=="Outlook2019Volume" (set /a kk+=1&set _pkey!kk!=7HD7K-N4PVK-BHBCQ-YWQRW-XW4VK)
if /i "%%J"=="PowerPoint2019Volume" (set /a kk+=1&set _pkey!kk!=RRNCX-C64HY-W2MM7-MCH9G-TJHMQ)
if /i "%%J"=="Publisher2019Volume" (set /a kk+=1&set _pkey!kk!=G2KWX-3NW6P-PY93R-JXK2T-C9Y9V)
if /i "%%J"=="SkypeForBusiness2019Volume" (set /a kk+=1&set _pkey!kk!=NCJ33-JHBBY-HTK98-MYCV8-HMKHJ)
if /i "%%J"=="Word2019Volume" (set /a kk+=1&set _pkey!kk!=PBX3G-NWMT6-Q7XBW-PYJGG-WXD33)
if /i "%%J"=="ProjectPro2019Volume" (set /a kk+=1&set _pkey!kk!=B4NPR-3FKK7-T2MBV-FRQ4W-PKD2B)
if /i "%%J"=="ProjectStd2019Volume" (set /a kk+=1&set _pkey!kk!=C4F7P-NCP8C-6CQPT-MQHV9-JXD2M)
if /i "%%J"=="VisioPro2019Volume" (set /a kk+=1&set _pkey!kk!=9BGNQ-K37YR-RQHF2-38RQ3-7VCBB)
if /i "%%J"=="VisioStd2019Volume" (set /a kk+=1&set _pkey!kk!=7TQNQ-K3YQQ-3PFH7-CCPPM-X4VQ2)
if /i "%%J"=="Access2021Volume" (set /a kk+=1&set _pkey!kk!=WM8YG-YNGDD-4JHDC-PG3F4-FC4T4)
if /i "%%J"=="Excel2021Volume" (set /a kk+=1&set _pkey!kk!=NWG3X-87C9K-TC7YY-BC2G7-G6RVC)
if /i "%%J"=="Outlook2021Volume" (set /a kk+=1&set _pkey!kk!=C9FM6-3N72F-HFJXB-TM3V9-T86R9)
if /i "%%J"=="PowerPoint2021Volume" (set /a kk+=1&set _pkey!kk!=TY7XF-NFRBR-KJ44C-G83KF-GX27K)
if /i "%%J"=="Publisher2021Volume" (set /a kk+=1&set _pkey!kk!=2MW9D-N4BXM-9VBPG-Q7W6M-KFBGQ)
if /i "%%J"=="SkypeForBusiness2021Volume" (set /a kk+=1&set _pkey!kk!=HWCXN-K3WBT-WJBKY-R8BD9-XK29P)
if /i "%%J"=="Word2021Volume" (set /a kk+=1&set _pkey!kk!=TN8H9-M34D3-Y64V9-TR72V-X79KV)
if /i "%%J"=="ProjectPro2021Volume" (set /a kk+=1&set _pkey!kk!=FTNWT-C6WBT-8HMGF-K9PRX-QV9H8)
if /i "%%J"=="ProjectStd2021Volume" (set /a kk+=1&set _pkey!kk!=J2JDC-NJCYY-9RGQ4-YXWMH-T3D4T)
if /i "%%J"=="VisioPro2021Volume" (set /a kk+=1&set _pkey!kk!=KNH8D-FGHT4-T8RK3-CTDYJ-K2HT4)
if /i "%%J"=="VisioStd2021Volume" (set /a kk+=1&set _pkey!kk!=MJVNY-BYWPY-CWV6J-2RKRT-4M8QG)
if /i "%%J"=="Access2024Volume" (set /a kk+=1&set _pkey!kk!=82FTR-NCHR7-W3944-MGRHM-JMCWD)
if /i "%%J"=="Excel2024Volume" (set /a kk+=1&set _pkey!kk!=F4DYN-89BP2-WQTWJ-GR8YC-CKGJG)
if /i "%%J"=="Outlook2024Volume" (set /a kk+=1&set _pkey!kk!=D2F8D-N3Q3B-J28PV-X27HD-RJWB9)
if /i "%%J"=="PowerPoint2024Volume" (set /a kk+=1&set _pkey!kk!=CW94N-K6GJH-9CTXY-MG2VC-FYCWP)
if /i "%%J"=="SkypeForBusiness2024Volume" (set /a kk+=1&set _pkey!kk!=4NKHF-9HBQF-Q3B6C-7YV34-F64P3)
if /i "%%J"=="Word2024Volume" (set /a kk+=1&set _pkey!kk!=MQ84N-7VYDM-FXV7C-6K7CC-VFW9J)
if /i "%%J"=="ProjectPro2024Volume" (set /a kk+=1&set _pkey!kk!=NBBBB-BBBBB-BBBBB-BBBH4-GX3R4)
if /i "%%J"=="ProjectStd2024Volume" (set /a kk+=1&set _pkey!kk!=PD3TT-NTHQQ-VC7CY-MFXK3-G87F8)
if /i "%%J"=="VisioPro2024Volume" (set /a kk+=1&set _pkey!kk!=NBBBB-BBBBB-BBBBB-BBBCW-6MX6T)
if /i "%%J"=="VisioStd2024Volume" (set /a kk+=1&set _pkey!kk!=JMMVY-XFNQC-KK4HK-9H7R3-WQQTV)
)

if %winbuild% lss 10240 if %_base% equ 0 for %%J in (%_skus%) do (
set _tmp=%%J
if /i "!_tmp:~-10!"=="2019Volume" (call set _tmp=!_tmp:~0,-10!Retail) else if /i "!_tmp:~-10!"=="2021Volume" (call set _tmp=!_tmp:~0,-10!Retail) else if /i "!_tmp:~-10!"=="2024Volume" (call set _tmp=!_tmp:~0,-10!Retail) else (call set _tmp=!_tmp:~0,-6!Retail)
  if defined _products (set "_products=!_products!^|!_tmp!.16_%CTRlng%_x-none") else (set "_products=!_tmp!.16_%CTRlng%_x-none")
  if %_OneDrive%==OFF (if defined _exclude1d (set "_exclude1d=!_exclude1d! !_tmp!.excludedapps.16=onedrive") else (set "_exclude1d=!_tmp!.excludedapps.16=onedrive"))
)

for /l %%J in (1,1,%kk%) do (
if defined _keys (set "_keys=!_keys!,!_pkey%%J!") else (set "_keys=!_pkey%%J!")
)

:MenuFinal
if %_silent% EQU 1 (
set _disp=False
goto :MenuInstall
)
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
echo Disable Telemetry: %_tele%
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
set "_url=http://officecdn.microsoft.com/db"

(
echo @echo off
echo reg.exe query "HKU\S-1-5-19" 1^>nul 2^>nul ^|^| ^(echo Run the script as administrator^&pause^&exit^)
echo reg.exe delete %_Config% /f /v UpdateUrl 1^>nul 2^>nul
echo reg.exe delete %_Config% /f /v UpdateToVersion 1^>nul 2^>nul
echo reg.exe delete %_CTR%\Updates /f /v UpdateToVersion 1^>nul 2^>nul
echo reg.exe delete HKLM\SOFTWARE\Policies\Microsoft\Office\16.0\Common\OfficeUpdate /f 1^>nul 2^>nul
echo reg.exe add HKLM\SOFTWARE\Policies\Microsoft\Office\16.0\Common\OfficeUpdate /f /v PreventBingInstall /t REG_DWORD /d 1 1^>nul 2^>nul
echo reg.exe add HKCU\software\Policies\Microsoft\Office\16.0\Teams /f /v PreventFirstLaunchAfterInstall /t REG_DWORD /d 1 1^>nul 2^>nul
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
if %winbuild% lss 10240 if /i "%_suite%"=="MondoVolume" echo pidkeys=HFTND-W9MK4-8B7MJ-B6C4G-XQBR2 %_autoact% ^^
if defined _suite echo %_suite%.excludedapps.16=%_excluded% ^^
if defined _exclude1d echo %_exclude1d% ^^
echo flt.useexptransportinplacepl=disabled flt.useofficehelperaddon=disabled flt.useoutlookshareaddon=disabled ^^
echo flt.useteamsaddon=disabled flt.usebingaddononinstall=disabled flt.usebingaddononupdate=disabled 1^>nul 2^>nul
echo reg.exe add %_Config% /f /v UpdateChannel /t REG_SZ /d "%_url%/%CTRffn%" 1^>nul 2^>nul
echo reg.exe add %_Config% /f /v UpdateChannelChanged /t REG_SZ /d True 1^>nul 2^>nul
echo exit /b
)>"!_temp!\C2R_Setup.bat"

for /f "tokens=3 delims=." %%# in ('echo %CTRver%') do set verchk=%%#
set "CTRexe=1"
set "cfile=!_file:\=\\!"
if exist "!_file!" if %_cwmi% equ 1 for /f "tokens=4 delims==." %%i in ('wmic datafile where "name='!cfile!'" get Version /value ^| find "="') do (
  if %%i geq %verchk% (set CTRexe=0)
)
if exist "!_file!" if %_cwmi% equ 0 for /f "tokens=3 delims==." %%i in ('powershell -nop -c "([WMI]'CIM_DataFile.Name=''!cfile!''').Version"') do (
  if %%i geq %verchk% (set CTRexe=0)
)
call :StopService 1>nul 2>nul
if %CTRexe%==1 (
if exist "!_target!" rmdir /s /q "!_target!" 1>nul 2>nul
mkdir "!_target!" 1>nul 2>nul
expand -f:* "!CTRsource!\Office\Data\%CTRver%\%CTRicab%" "!_target!" 1>nul 2>nul
expand -f:* "!CTRsource!\Office\Data\%CTRver%\%CTRicabr%" "!_target!" 1>nul 2>nul
)
echo.
echo %line%
echo Running installation...
echo %line%
echo.
del /f /q "%SystemRoot%\temp\*.log" 1>nul 2>nul
del /f /q "!_temp!\*.log" 1>nul 2>nul
!_ComSpec! /c ""!_temp!\C2R_Setup.bat" "
del /f /q "!_temp!\C2R_Setup.bat" 1>nul 2>nul
if not exist "!_Program!\Microsoft Office\root\Office16\*.dll" if not exist "%ProgramFiles(x86)%\Microsoft Office\root\Office16\*.dll" (
echo.
echo %line%
echo Installation failed.
echo %line%
if %_unattend%==True goto :eof
goto :TheEnd
)
if defined _licenses (
echo.
echo %line%
echo Installing uplevel Licenses...
echo %line%
echo.
call :Licenses 1>nul 2>nul
)
if %_tele%==True (
call :Telemetry 1>nul 2>nul
)
call :Cleanup 1>nul 2>nul
echo.
echo %line%
echo Done.
echo %line%
echo.
if %_unattend%==True goto :eof
if %_silent% EQU 1 goto :eof
echo Press 9 or X to exit.
choice /c 9X /n
if errorlevel 1 (exit /b) else (rem.)
goto :eof

:StopService
sc query WSearch | find /i "STOPPED" || net stop WSearch /y
sc query WSearch | find /i "STOPPED" || sc stop WSearch
if not exist "!_file!" exit /b
sc query ClickToRunSvc | find /i "STOPPED" || net stop ClickToRunSvc /y
sc query ClickToRunSvc | find /i "STOPPED" || sc stop ClickToRunSvc
taskkill /t /f /IM OfficeC2RClient.exe
taskkill /t /f /IM OfficeClickToRun.exe
exit /b

:Cleanup
taskkill /t /f /IM OfficeC2RClient.exe
reg delete HKCU\Software\Microsoft\Office\Common /f
reg delete HKCU\Software\Microsoft\Office\16.0 /f
reg add HKCU\Software\Policies\Microsoft\Office\16.0\Teams /f /v PreventFirstLaunchAfterInstall /t REG_DWORD /d 1
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
set "_inter=SOFTWARE"
if "%xOS%"=="x64" if %wow64%==1 (set "_inter=SOFTWARE\Wow6432Node")
set "_rkey=HKLM\%_inter%\Microsoft\Office\16.0\User Settings\MyCustomUserSettings"
set "_skey=HKLM\%_inter%\Microsoft\Office\16.0\User Settings\MyCustomUserSettings\Create\Software\Microsoft\Office\16.0"
set "_tkey=HKLM\%_inter%\Microsoft\Office\16.0\User Settings\MyCustomUserSettings\Create\Software\Microsoft\Office\Common\ClientTelemetry"
for %%# in (Count,Order) do reg add "%_rkey%" /f /v %%# /t REG_DWORD /d 1
reg add "%_tkey%" /f /v SendTelemetry /t REG_DWORD /d 3
reg add "%_tkey%" /f /v DisableTelemetry /t REG_DWORD /d 1
if %_Of365%==0 (
for %%# in (disconnectedstate,usercontentdisabled,downloadcontentdisabled,controllerconnectedservicesenabled) do reg add "%_skey%\Common\Privacy" /f /v %%# /t REG_DWORD /d 2
)
for %%# in (disableboottoofficestart) do reg add "%_skey%\Common" /f /v %%# /t REG_DWORD /d 1
for %%# in (qmenable,sendcustomerdata,updatereliabilitydata) do reg add "%_skey%\Common" /f /v %%# /t REG_DWORD /d 0
for %%# in (disableboottoofficestart,optindisable,shownfirstrunoptin,ShownFileFmtPrompt) do reg add "%_skey%\Common\General" /f /v %%# /t REG_DWORD /d 1
for %%# in (skydrivesigninoption) do reg add "%_skey%\Common\General" /f /v %%# /t REG_DWORD /d 0
for %%# in (enabled,includescreenshot) do reg add "%_skey%\Common\Feedback" /f /v %%# /t REG_DWORD /d 0
for %%# in (disableboottoofficestart) do reg add "%_skey%\Common\Internet" /f /v %%# /t REG_DWORD /d 1
for %%# in (serviceleveloptions) do reg add "%_skey%\Common\Internet" /f /v %%# /t REG_DWORD /d 0
for %%# in (disableboottoofficestart) do reg add "%_skey%\Common\PTWatson" /f /v %%# /t REG_DWORD /d 1
for %%# in (PTWOptIn) do reg add "%_skey%\Common\PTWatson" /f /v %%# /t REG_DWORD /d 0
for %%# in (disablereporting) do reg add "%_skey%\Common\Security\FileValidation" /f /v %%# /t REG_DWORD /d 1
for %%# in (BootedRTM,disablemovie) do reg add "%_skey%\Firstrun" /f /v %%# /t REG_DWORD /d 1
for %%# in (disableautomaticsendtracing) do reg add "%_skey%\Lync" /f /v %%# /t REG_DWORD /d 1
for %%# in (EnableLogging) do reg add "%_skey%\Outlook\Options\Mail" /f /v %%# /t REG_DWORD /d 0
for %%# in (EnableLogging) do reg add "%_skey%\Word\Options" /f /v %%# /t REG_DWORD /d 0
for %%# in (EnableLogging,EnableUpload) do reg add "%_skey%\OSM" /f /v %%# /t REG_DWORD /d 0
for %%# in (accesssolution,olksolution,onenotesolution,pptsolution,projectsolution,publishersolution,visiosolution,wdsolution,xlsolution) do reg add "%_skey%\OSM\PreventedApplications" /f /v %%# /t REG_DWORD /d 1
for %%# in (agave,appaddins,comaddins,documentfiles,templatefiles) do reg add "%_skey%\OSM\PreventedSolutiontypes" /f /v %%# /t REG_DWORD /d 1
set "_schtasks=SCHTASKS /Change /DISABLE /TN"
set "_schedule=Microsoft\Office"
%_schtasks% "%_schedule%\OfficeInventoryAgentFallBack"
%_schtasks% "%_schedule%\OfficeTelemetryAgentFallBack"
%_schtasks% "%_schedule%\OfficeTelemetryAgentFallBack2016"
%_schtasks% "%_schedule%\OfficeInventoryAgentLogOn"
%_schtasks% "%_schedule%\OfficeTelemetryAgentLogOn"
%_schtasks% "%_schedule%\OfficeTelemetryAgentLogOn2016"
%_schtasks% "ServiceWatcherSchedule"
exit /b

:E_FILE
echo %_err%
echo %ERRFILE% is missing in the specified source
goto :TheEnd

:E_Admin
echo %_err%
echo This script require administrator privileges.
goto :TheEnd

:E_Win
echo %_err%
echo Windows 7 SP1 is the minimum supported OS.
goto :TheEnd

:E_WMI
echo %_err%
echo WMIC.exe or Windows PowerShell is required for this script to work.
goto :TheEnd

:TheEnd
if %_silent% EQU 1 goto :eof
echo.
echo Press 9 or X to exit.
choice /c 9X /n
if errorlevel 1 (exit /b) else (rem.)
goto :eof
