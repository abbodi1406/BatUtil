@echo off
cd /d "%~dp0"
set uiv=v5.3
:: when changing below options, recommended to set the new values between = and " marks

:: target image or wim file
:: leave it blank to automatically detect wim file next to the script, or current online os
set "target="

:: updates location, remember to set the parent "Updates" directory for WHD repository
set "repo=%~dp0Updates"

:: dism.exe tool path (default is system)
set "dismroot=%windir%\system32\dism.exe"

:: updates to process by default
set LDRbranch=ON
set IE11=ON
set RDP=ON
set Hotfix=ON
set Features=OFF
set WAT=OFF
set WMF=OFF
set Windows10=OFF
set win10u=ON
set ADLDS=OFF
set RSAT=OFF
set onlinelimit=75

:: update winre.wim if detected inside install.wim, set to 0 to skip it
set winre=1

:: create new iso file if the target is a distribution folder
:: require ADK installed, or placing oscdimg.exe or cdimage.exe next to the script
set iso=1

:: set this to 1 to delete DVD distribution folder after creating updated ISO
set delete_source=0

:: set this to 1 to start the process directly once you execute the script
:: make sure you set the above options correctly first
set autostart=0

:: optional, set directory for temporary extracted files
set "cab_dir=%~d0\W7UItemp"

:: optional, set mount directory for updating wim files
set "mountdir=%SystemDrive%\W7UImount"
set "winremount=%SystemDrive%\W7UImountre"

:: ##################################################################
:: # NORMALY THERE IS NO NEED TO CHANGE ANYTHING BELOW THIS COMMENT #
:: ##################################################################

:: Technical options for updates
set sha2cs=KB4474419
set ssu1st=KB4490628
set ssu2nd=KB4523206
set rollup=KB3125574
set gdrlist=(KB2574819,KB2685811,KB2685813)
set rdp8=(KB2984976,KB3020387,KB3075222)
set hv_integ_kb=hypervintegrationservices
set hv_integ_vr=9600.18692

title Installer for Windows 7 Updates
set oscdimgroot=%windir%\system32\oscdimg.exe
set _reg=%windir%\system32\reg.exe
%_reg% query "HKU\S-1-5-19" 1>nul 2>nul || goto :E_Admin

:detect
if exist "%cab_dir%" (
echo.
echo ============================================================
echo Removing temporary extracted files...
echo ============================================================
echo.
rmdir /s /q "%cab_dir%" >nul
)
setlocal enableextensions
setLocal EnableDelayedExpansion
set dvd=0
set wim=0
set offline=0
set online=0
set _wim=0
set copytarget=0
set imgcount=0
if exist "*.wim" (for /f "delims=" %%i in ('dir /b /a:-d *.wim') do (call set /a _wim+=1))
if "%target%"=="" if %_wim%==1 (for %%i in ("*.wim") do set "target=%%~fi"&set "targetname=%%i")
if "%target%"=="" set "target=%SystemDrive%"
if "%target:~-1%"=="\" set "target=%target:~0,-1%"
if /i "%target%"=="%SystemDrive%" goto :check
echo %target%| findstr /E /I "\.wim" >nul
if %errorlevel%==0 (
set wim=1
for /f %%i in ('dir /b "%target%"') do set "targetname=%%i"
) else (
if exist "%target%\sources\boot.wim" set dvd=1 
if exist "%target%\Windows\regedit.exe" set offline=1
)
if %offline%==0 if %wim%==0 if %dvd%==0 (set "target=%SystemDrive%"&goto :check)
if %offline%==1 (
dir /b "%target%\Windows\servicing\Version\6.1.7601.*" 1>nul 2>nul || (set "MESSAGE=Detected target offline image is not Windows 7"&goto :E_Target)
set "mountdir=%target%"
if exist "%target%\Windows\SysWOW64\*" (set arch=x64) else (set arch=x86)
)
if %dvd%==1 (
echo.
echo ============================================================
echo Please wait...
echo ============================================================
dir /b /s /adr "%target%" 1>nul 2>nul && set copytarget=1
dism /english /get-wiminfo /wimfile:"%target%\sources\install.wim" /index:1 | find /i "Version : 6.1.7601" >nul || (set "MESSAGE=Detected install.wim version is not Windows 10"&goto :E_Target)
for /f "tokens=2 delims=: " %%i in ('dism /english /get-wiminfo /wimfile:"%target%\sources\install.wim" /index:1 ^| find /i "Architecture"') do set arch=%%i
for /f "tokens=2 delims=: " %%i in ('dism /english /get-wiminfo /wimfile:"%target%\sources\install.wim" ^| findstr "Index"') do set imgcount=%%i
for /L %%i in (1,1,!imgcount!) do (
  for /f "tokens=1* delims=: " %%a in ('dism /english /get-wiminfo /wimfile:"%target%\sources\install.wim" /index:%%i ^| findstr /b /c:"Name"') do set name%%i="%%b"
  )
set "indices=*"
)
if %wim%==1 (
echo.
echo ============================================================
echo Please wait...
echo ============================================================
dism /english /get-wiminfo /wimfile:"%target%" /index:1 | find /i "Version : 6.1.7601" >nul || (set "MESSAGE=Detected wim version is not Windows 7"&goto :E_Target)
for /f "tokens=2 delims=: " %%i in ('dism /english /get-wiminfo /wimfile:"%target%" /index:1 ^| find /i "Architecture"') do set arch=%%i
for /f "tokens=2 delims=: " %%i in ('dism /english /get-wiminfo /wimfile:"%target%" ^| findstr "Index"') do set imgcount=%%i
for /L %%i in (1,1,!imgcount!) do (
  for /f "tokens=1* delims=: " %%a in ('dism /english /get-wiminfo /wimfile:"%target%" /index:%%i ^| findstr /b /c:"Name"') do set name%%i="%%b"
  )
set "indices=*"
)

:check
if /i "%target%"=="%SystemDrive%" (if exist "%target%\Windows\SysWOW64\*" (set arch=x64) else (set arch=x86))
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G
rem if %winbuild% geq 9600 goto :mainmenu
if /i not "%dismroot%"=="%windir%\system32\dism.exe" goto :mainmenu
goto :checkadk

:mainboard
if %winbuild% neq 7601 (
if /i "%target%"=="%SystemDrive%" (goto :mainmenu)
)
if "%repo%"=="" (goto :mainmenu)
if "%repo:~-1%"=="\" set "repo=%repo:~0,-1%"
set "repo=%repo%\Windows7-%arch%"
if /i "%target%"=="%SystemDrive%" (set dismtarget=/online&set "mountdir=%target%"&set online=1) else (set dismtarget=/image:"%mountdir%")
cls
echo ============================================================
echo Running WHD-W7UI_WithoutKB3125574 %uiv%
echo ============================================================
if %online%==1 (
net stop trustedinstaller >nul 2>&1
net stop wuauserv >nul 2>&1
DEL /F /Q %systemroot%\Logs\CBS\* >nul 2>&1
)
DEL /F /Q %systemroot%\Logs\DISM\* >nul 2>&1
if %dvd%==1 if %copytarget%==1 (
echo.
echo ============================================================
echo Copying DVD contents to work directory
echo ============================================================
robocopy "%target%" "%~dp0DVD" /E /A-:R >nul
set "target=%~dp0DVD"
)
if %online%==1 call :update
if %offline%==1 (
call :update
call :cleanupmanual
)
if %wim%==1 (
if "%indices%"=="*" set "indices="&for /L %%i in (1,1,%imgcount%) do set "indices=!indices! %%i"
call :mount "%target%"
if /i "%targetname%" neq "winre.wim" (if exist "%~dp0winre.wim" del /f /q "%~dp0winre.wim" >nul)
)
if %dvd%==1 (
if "%indices%"=="*" set "indices="&for /L %%i in (1,1,%imgcount%) do set "indices=!indices! %%i"
call :mount "%target%\sources\install.wim"
if exist "%~dp0winre.wim" del /f /q "%~dp0winre.wim" >nul
set "indices="&set imgcount=2&for /L %%i in (1,1,!imgcount!) do set "indices=!indices! %%i"
call :mount "%target%\sources\boot.wim"
xcopy /CRY "%target%\efi\microsoft\boot\fonts" "%target%\boot\fonts" >nul
)
goto :fin

:update
set verb=1
if not "%1"=="" (
set "mountdir_b=%mountdir%"
set "mountdir=%winremount%"
set dismtarget=/image:"%winremount%"
set verb=0
)
if %online%==1 (
for /f "skip=2 tokens=3 delims= " %%i in ('%_reg% query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v EditionID') do set CEdition=%%i
) else if not exist "%mountdir%\sources\recovery\RecEnv.exe" (
%_reg% load HKLM\OFFSOFT "%mountdir%\Windows\System32\config\SOFTWARE" >nul
for /f "skip=2 tokens=3 delims= " %%i in ('%_reg% query "HKLM\OFFSOFT\Microsoft\Windows NT\CurrentVersion" /v EditionID') do set CEdition=%%i
%_reg% unload HKLM\OFFSOFT >nul
)
set allcount=0
set IEcab=0
if exist "%mountdir%\sources\recovery\RecEnv.exe" (
call :ssu
call :csu
call :esu
call :pesecurity
"%dismroot%" %dismtarget% /Set-ScratchSpace:64 >nul
goto :eof
)
call :ssu
call :csu
call :esu
call :general
if /i %IE11% equ ON (call :ie11) else (call :ie9)
if /i %RDP% equ ON call :rdp
if /i %ADLDS% equ ON call :adlds
if /i %RSAT% equ ON call :rsat
if /i %WMF% equ ON call :wmf
if /i %Hotfix% equ ON call :hotfix
if /i %Features% equ ON call :features
if /i %Windows10% equ ON call :windows10
rem if /i %Windows10% equ ON if /i %win10u% equ ON call :win10u
if /i %Hotfix% equ ON call :regfix
call :online
call :security
goto :eof

:ssu
if not exist "%repo%\General\*%ssu1st%*-%arch%.msu" goto :eof
if exist "%mountdir%\Windows\servicing\packages\package_for_%ssu1st%*.mum" goto :eof
if %online%==1 if exist "%windir%\winsxs\pending.xml" (call set "ssulmt=ssu1st"&goto :stacklimit)
call :cleaner
cd General\
if %verb%==1 (
echo.
echo ============================================================
echo *** Servicing Stack Update ***
echo ============================================================
)
set "dest=%cab_dir%\SSU"
if not exist "%dest%\*%ssu1st%*.mum" (
expand.exe -f:*Windows*.cab "*%ssu1st%*%arch%.msu" "%cab_dir%" >nul
md "%dest%"
expand.exe -f:* "%cab_dir%\*%ssu1st%*.cab" "%dest%" 1>nul 2>nul || (echo Error: cannot extract cab file&rd /s /q "%dest%"&timeout /t 5 /nobreak >nul&goto :eof)
)
"%dismroot%" %dismtarget% /NoRestart /Add-Package /packagepath:"%dest%\update.mum"
goto :eof

:esu
set ssuver=0
set shaupd=0
for /f %%i in ('dir /b "%mountdir%\Windows\servicing\Version"') do set ssuver=%%i
if not exist "%repo%\Security\*%ssu2nd%*-%arch%.msu" goto :eof
if exist "%mountdir%\Windows\servicing\packages\package_for_%ssu2nd%*.mum" goto :eof
if %ssuver:~9% lss 24383 goto :eof
if %online%==1 (set ksub1=SOFTWARE) else (set ksub1=OFFSOFT&%_reg% load HKLM\!ksub1! "%mountdir%\Windows\System32\config\SOFTWARE" >nul)
%_reg% query HKLM\%ksub1%\Microsoft\Windows\CurrentVersion\Servicing\Codesigning\SHA2 /v SHA2-Codesigning-Support 1>nul 2>nul && set shaupd=1
if %online%==0 %_reg% unload HKLM\%ksub1% >nul
if %shaupd% neq 1 goto :eof
if %online%==1 if exist "%windir%\winsxs\pending.xml" (call set "ssulmt=ssu2nd"&goto :stacklimit)
call :cleaner
cd Security\
if %verb%==1 (
echo.
echo ============================================================
echo *** Extended Servicing Stack Update ***
echo ============================================================
)
set "dest=%cab_dir%\ESU"
if not exist "%dest%\*%ssu2nd%*.mum" (
expand.exe -f:*Windows*.cab "*%ssu2nd%*%arch%.msu" "%cab_dir%" >nul
md "%dest%"
expand.exe -f:* "%cab_dir%\*%ssu2nd%*.cab" "%dest%" 1>nul 2>nul || (echo Error: cannot extract cab file&rd /s /q "%dest%"&timeout /t 5 /nobreak >nul&goto :eof)
)
"%dismroot%" %dismtarget% /NoRestart /Add-Package /packagepath:"%dest%\update.mum"
goto :eof

:csu
if not exist "%repo%\Security\*%sha2cs%*-%arch%.msu" goto :eof
if exist "%mountdir%\Windows\servicing\packages\package_for_%sha2cs%*6.1.3.2.mum" goto :eof
call :cleaner
cd Security\
if %verb%==1 (
echo.
echo ============================================================
echo *** SHA2 Code Signing Support Update ***
echo ============================================================
)
set "dest=%cab_dir%\SHA"
if not exist "%dest%\*%sha2cs%*.mum" (
expand.exe -f:*Windows*.cab "*%sha2cs%*%arch%.msu" "%cab_dir%" >nul
md "%dest%"
expand.exe -f:* "%cab_dir%\*%sha2cs%*.cab" "%dest%" 1>nul 2>nul || (echo Error: cannot extract cab file&rd /s /q "%dest%"&timeout /t 5 /nobreak >nul&goto :eof)
)
"%dismroot%" %dismtarget% /NoRestart /Add-Package /packagepath:"%dest%\update.mum"
goto :eof

:general
if not exist "%repo%\General\*.msu" goto :eof
call :cleaner
echo.
echo ============================================================
echo *** General Updates ***
echo ============================================================
set cat=General Updates
md "%cab_dir%\General"
if /i %WAT% equ ON if exist "Additional\WAT\*%arch%*.msu" (expand.exe -f:*Windows*.cab Additional\WAT\*%arch%*.msu "%cab_dir%\General" >nul)
if /i %RDP% neq ON if not exist "%target%\Windows\servicing\packages\*RDP-*-Package*.mum" if exist "Extra\WithoutKB3125574\WithoutRDP\*%arch%*.msu" (expand.exe -f:*Windows*.cab Extra\WithoutKB3125574\WithoutRDP\*%arch%*.msu "%cab_dir%\General" >nul)
robocopy General "%cab_dir%\General" *%arch%*.msu /XF *%rollup%* 1>nul 2>nul
copy /y General\*%arch%*.cab "%cab_dir%\General\" 1>nul 2>nul
copy /y Extra\WithoutKB3125574\#General\*%arch%*.msu "%cab_dir%\General\" 1>nul 2>nul
copy /y Extra\WithoutKB3125574\#General\*%arch%*.cab "%cab_dir%\General\" 1>nul 2>nul
cd /d "%cab_dir%\General"
call :counter
call :cab
cd /d "%repo%"
rd /s /q "%cab_dir%\General"
if %_sum% equ 0 goto :eof
call :mum
if %_sum% equ 0 goto :eof
goto :listdone

:security
set ssuver=0
set shaupd=0
for /f %%i in ('dir /b "%mountdir%\Windows\servicing\Version"') do set ssuver=%%i
if %online%==1 if %allcount% geq %onlinelimit% (goto :countlimit)
if not exist "%repo%\Security\*.msu" goto :eof
if %online%==1 (set ksub1=SOFTWARE) else (set ksub1=OFFSOFT&%_reg% load HKLM\!ksub1! "%mountdir%\Windows\System32\config\SOFTWARE" >nul)
%_reg% query HKLM\%ksub1%\Microsoft\Windows\CurrentVersion\Servicing\Codesigning\SHA2 /v SHA2-Codesigning-Support 1>nul 2>nul && set shaupd=1
if %online%==0 %_reg% unload HKLM\%ksub1% >nul
call :cleaner
if %verb%==1 (
echo.
echo ============================================================
echo *** Security Updates ***
echo ============================================================
)
set cat=Security Updates
md "%cab_dir%\Security"
copy /y Security\*%arch%*.msu "%cab_dir%\Security\" 1>nul 2>nul
copy /y Security\*%arch%*.cab "%cab_dir%\Security\" 1>nul 2>nul
copy /y Extra\WithoutKB3125574\#Security\*%arch%*.msu "%cab_dir%\Security\" 1>nul 2>nul
copy /y Extra\WithoutKB3125574\#Security\*%arch%*.cab "%cab_dir%\Security\" 1>nul 2>nul
cd /d "%cab_dir%\Security"
call :counter
call :cab
cd /d "%repo%"
rd /s /q "%cab_dir%\Security"
if %_sum% equ 0 goto :eof
call :mum
if %_sum% equ 0 goto :eof
goto :listdone

:pesecurity
set ssuver=0
set shaupd=0
for /f %%i in ('dir /b "%mountdir%\Windows\servicing\Version"') do set ssuver=%%i
if not exist "%repo%\Security\*.msu" goto :eof
if %online%==1 (set ksub1=SOFTWARE) else (set ksub1=OFFSOFT&%_reg% load HKLM\!ksub1! "%mountdir%\Windows\System32\config\SOFTWARE" >nul)
%_reg% query HKLM\%ksub1%\Microsoft\Windows\CurrentVersion\Servicing\Codesigning\SHA2 /v SHA2-Codesigning-Support 1>nul 2>nul && set shaupd=1
if %online%==0 %_reg% unload HKLM\%ksub1% >nul
call :cleaner
if %verb%==1 (
echo.
echo ============================================================
echo *** Security Updates ***
echo ============================================================
)
set cat=Security Updates
cd Security\
call :counter
call :cab
if %_sum% equ 0 goto :eof
call :mum
if %_sum% equ 0 goto :eof
goto :listdone

:hotfix
if %online%==1 if %allcount% geq %onlinelimit% (goto :countlimit)
if not exist "%repo%\Hotfix\*.msu" goto :eof
call :cleaner
echo.
echo ============================================================
echo *** Hotfixes ***
echo ============================================================
set cat=Hotfixes
md "%cab_dir%\Hotfix"
if /i "%CEdition%"=="Enterprise" if exist "%target%\Windows\fr-fr\explorer.exe.mui" if exist "Extra\WithoutKB3125574\SL\French.Enterprise\*%arch%*.msu" (copy Extra\WithoutKB3125574\SL\French.Enterprise\*%arch%*.msu "%cab_dir%\Hotfix" >nul)
if exist "%target%\Windows\pl-pl\explorer.exe.mui" if exist "Extra\WithoutKB3125574\SL\Polish\*%arch%*.msu" (copy Extra\WithoutKB3125574\SL\Polish\*%arch%*.msu "%cab_dir%\Hotfix" >nul)
copy /y Hotfix\*%arch%*.msu "%cab_dir%\Hotfix\" 1>nul 2>nul
copy /y Hotfix\*%arch%*.cab "%cab_dir%\Hotfix\" 1>nul 2>nul
copy /y Extra\WithoutKB3125574\#Hotfix\*%arch%*.msu "%cab_dir%\Hotfix\" 1>nul 2>nul
copy /y Extra\WithoutKB3125574\#Hotfix\*%arch%*.cab "%cab_dir%\Hotfix\" 1>nul 2>nul
cd /d "%cab_dir%\Hotfix"
call :counter
call :cab
cd /d "%repo%"
rd /s /q "%cab_dir%\Hotfix"
if %_sum% equ 0 goto :eof
call :mum
if %_sum% equ 0 goto :eof
goto :listdone

:rdp
if %online%==1 if %allcount% geq %onlinelimit% (goto :countlimit)
if not exist "%repo%\Additional\RDP\*.msu" goto :eof
call :cleaner
echo.
echo ============================================================
echo *** RDP Updates ***
echo ============================================================
set cat=RDP Updates
md "%cab_dir%\RDP"
copy /y Additional\RDP\*%arch%*.msu "%cab_dir%\RDP\" 1>nul 2>nul
copy /y Additional\RDP\*%arch%*.cab "%cab_dir%\RDP\" 1>nul 2>nul
copy /y Extra\WithoutKB3125574\_RDP\*%arch%*.msu "%cab_dir%\RDP\" 1>nul 2>nul
copy /y Extra\WithoutKB3125574\_RDP\*%arch%*.cab "%cab_dir%\RDP\" 1>nul 2>nul
cd /d "%cab_dir%\RDP"
call :counter
call :cab
cd /d "%repo%"
rd /s /q "%cab_dir%\RDP"
if %_sum% equ 0 goto :eof
call :mum
if %_sum% equ 0 goto :eof
goto :listdone

:ie11
if %online%==1 if %allcount% geq %onlinelimit% (goto :countlimit)
if not exist "%repo%\Additional\_IE11\*.cab" goto :eof
call :cleaner
echo.
echo ============================================================
echo *** IE11 Updates ***
echo ============================================================
set cat=IE11 Updates
cd Additional\_IE11\
call :counter
set IEcab=1
call :cab
set IEcab=0
if %_sum% equ 0 goto :eof
call :mum
if %_sum% equ 0 goto :eof
goto :listdone

:ie9
if %online%==1 if %allcount% geq %onlinelimit% (goto :countlimit)
if exist "%mountdir%\Windows\servicing\packages\*InternetExplorer*11.2.*.mum" goto :eof
if not exist "%repo%\Extra\IE9\*.msu" if not exist "%repo%\Extra\IE8\*.msu" goto :eof
call :cleaner
echo.
echo ============================================================
echo *** IE9/IE8 Updates ***
echo ============================================================
set cat=IE Updates
if exist "Extra\IE9\*.msu" (
if not exist "%cab_dir%\IE9" (
md "%cab_dir%\IE9"
cd Extra\IE9\
for /f "delims=" %%a in ('"dir /b /s *%arch%*.msu" 2^>nul') do copy "%%a" "%cab_dir%\IE9" >nul
)
cd /d "%cab_dir%\IE9"
set IEcab=1
) else (
cd Extra\IE8
)
call :counter
call :cab
set IEcab=0
if %_sum% equ 0 goto :eof
call :mum
if %_sum% equ 0 goto :eof
goto :listdone

:features
if %online%==1 if %allcount% geq %onlinelimit% (goto :countlimit)
if not exist "%repo%\Extra\WithoutKB3125574\_Features\*" goto :eof
call :cleaner
echo.
echo ============================================================
echo *** Features Hotfixes ***
echo ============================================================
set cat=Features Hotfixes
cd Extra\WithoutKB3125574\_Features\
call :counter
call :cab
if %_sum% equ 0 goto :eof
call :mum
if %_sum% equ 0 goto :eof
goto :listdone

:windows10
if %online%==1 if %allcount% geq %onlinelimit% (goto :countlimit)
if not exist "%repo%\Additional\Windows10\*.msu" goto :eof
call :cleaner
echo.
echo ============================================================
echo *** Windows10/Telemetry Updates ***
echo ============================================================
set cat=Win10/Tel Updates
md "%cab_dir%\Windows10"
copy /y Additional\Windows10\*%arch%*.msu "%cab_dir%\Windows10\" 1>nul 2>nul
copy /y Additional\Windows10\*%arch%*.cab "%cab_dir%\Windows10\" 1>nul 2>nul
copy /y Extra\WithoutKB3125574\_Windows10\*%arch%*.msu "%cab_dir%\Windows10\" 1>nul 2>nul
copy /y Extra\WithoutKB3125574\_Windows10\*%arch%*.cab "%cab_dir%\Windows10\" 1>nul 2>nul
cd /d "%cab_dir%\Windows10"
call :counter
call :cab
cd /d "%repo%"
rd /s /q "%cab_dir%\Windows10"
if %_sum% equ 0 goto :eof
call :mum
if %_sum% equ 0 goto :eof
goto :listdone

:wmf
if %online%==1 if %allcount% geq %onlinelimit% (goto :countlimit)
if not exist "%repo%\Additional\WMF\*.msu" goto :eof
if not exist "%mountdir%\Windows\Microsoft.NET\Framework\v4.0.30319\ngen.exe" goto :eof
call :cleaner
echo.
echo ============================================================
echo *** WMF Updates ***
echo ============================================================
set cat=WMF Updates
cd Additional\WMF\
call :counter
call :cab
if %_sum% equ 0 goto :eof
call :mum
if %_sum% equ 0 goto :eof
goto :listdone

:adlds
if %online%==1 if %allcount% geq %onlinelimit% (goto :countlimit)
if exist "%mountdir%\Windows\servicing\packages\*DirectoryServices-ADAM-Package-Client*7601*.mum" goto :eof
call :cleaner
if exist "%mountdir%\Windows\servicing\packages\*DirectoryServices-ADAM-Package-Client*.mum" (
call :adldsu
goto :eof
)
if not exist "%repo%\Extra\AD_LDS\*.msu" goto :eof
echo.
echo ============================================================
echo *** AD LDS KB975541 ***
echo ============================================================
cd Extra\AD_LDS\
expand.exe -f:*Windows*.cab *%arch%*.msu "%cab_dir%" >nul
"%dismroot%" %dismtarget% /NoRestart /Add-Package /packagepath:"%cab_dir%"
del /f /q "%cab_dir%\*KB975541*.cab"
call :adldsu
goto :eof

:adldsu
if not exist "%repo%\Extra\AD_LDS\Updates\*.msu" goto :eof
echo.
echo ============================================================
echo *** AD LDS Updates ***
echo ============================================================
set cat=AD LDS Updates
cd /d "%repo%"
cd Extra\AD_LDS\Updates\
call :counter
call :cab
if %_sum% equ 0 goto :eof
call :mum
if %_sum% equ 0 goto :eof
goto :listdone

:rsat
if %online%==1 if %allcount% geq %onlinelimit% (goto :countlimit)
if exist "%mountdir%\Windows\servicing\packages\*RemoteServerAdministrationTools*7601*.mum" goto :eof
call :cleaner
if exist "%mountdir%\Windows\servicing\packages\*RemoteServerAdministrationTools*.mum" (
call :rsatu
goto :eof
)
if not exist "%repo%\Extra\RSAT\*.msu" goto :eof
echo.
echo ============================================================
echo *** RSAT KB958830 ***
echo ============================================================
cd Extra\RSAT\
expand.exe -f:*Windows*.cab *%arch%*.msu "%cab_dir%" >nul
"%dismroot%" %dismtarget% /NoRestart /Add-Package /packagepath:"%cab_dir%"
del /f /q "%cab_dir%\*KB958830*.cab"
call :rsatu
goto :eof

:rsatu
if not exist "%repo%\Extra\WithoutKB3125574\RSAT\*.msu" goto :eof
echo.
echo ============================================================
echo *** RSAT Updates ***
echo ============================================================
set cat=RSAT Updates
cd /d "%repo%"
md "%cab_dir%\RSAT"
copy /y Extra\RSAT\Updates\*%arch%*.msu "%cab_dir%\RSAT\" 1>nul 2>nul
copy /y Extra\RSAT\Updates\*%arch%*.cab "%cab_dir%\RSAT\" 1>nul 2>nul
copy /y Extra\WithoutKB3125574\RSAT\*%arch%*.msu "%cab_dir%\RSAT\" 1>nul 2>nul
copy /y Extra\WithoutKB3125574\RSAT\*%arch%*.cab "%cab_dir%\RSAT\" 1>nul 2>nul
cd /d "%cab_dir%\RSAT"
call :counter
call :cab
cd /d "%repo%"
rd /s /q "%cab_dir%\RSAT"
if %_sum% equ 0 goto :eof
call :mum
if %_sum% equ 0 goto :eof
goto :listdone

:online
if not exist "%repo%\Additional\_NotAllowedOffline\*.msu" goto :eof
call :cleaner
echo.
echo ============================================================
echo *** Online Updates ***
echo ============================================================
cd Additional\_NotAllowedOffline\
for /f %%G in ('dir /b *%arch%*.msu') do (set package=%%G&call :online2)
goto :eof

:online2
for /f "tokens=2 delims=-" %%V in ('dir /b %package%') do set kb=%%V
if exist "%mountdir%\Windows\servicing\packages\package_for_%kb%~*6.1*.mum" goto :eof
if /i %kb%==KB947821 goto :eof
if /i %kb%==KB2603229 (
call :KB2603229
goto :eof
)
if /i %kb%==KB2646060 (
call :KB2646060
goto :eof
)
if /i %kb%==KB3177467 if %online%==0 (
call :KB3177467
goto :eof
)
if /i %kb%==KB4099950 if %online%==0 (
call :cabonline
goto :eof
)
if %online%==1 (
%package% /quiet /norestart
call :cabonline
)
goto :eof

:KB2603229
(echo @echo off
echo reg.exe query "HKU\S-1-5-19" 1^>nul 2^>nul ^|^| ^(echo Run the script as administrator^&pause^&exit^)
echo for /f "skip=2 tokens=2*" %%%%i in ^('%%windir%%\system32\reg.exe query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v RegisteredOwner'^) do %%windir%%\system32\reg.exe add "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion" /v RegisteredOwner /d "%%%%j" /f
echo for /f "skip=2 tokens=2*" %%%%i in ^('%%windir%%\system32\reg.exe query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v RegisteredOrganization'^) do %%windir%%\system32\reg.exe add "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion" /v RegisteredOrganization /d "%%%%j" /f
echo start /b "" cmd /c del "%%~f0"^&exit /b
)>"%cd%\%kb%.cmd"
if %online%==1 (
1>nul 2>nul call "%cd%\%kb%.cmd"
) else (
move /y "%cd%\%kb%.cmd" "%mountdir%\Users\Public\Desktop\RunOnce_KB2603229_Fix.cmd" >nul
)
call :cabonline
goto :eof

:KB2646060
(echo [Version]
echo Signature=$Windows NT$
echo.
echo [DefaultInstall]
echo RunPostSetupCommands=%kb%:1
echo SmartReboot=N
echo Cleanup=1
echo.
echo [%kb%]
echo %%11%%\powercfg.exe /attributes sub_processor 0cc5b647-c1df-4637-891a-dec35c318583 -ATTRIB_HIDE
echo %%11%%\powercfg.exe /attributes sub_processor ea062031-0e34-4ff1-9b6d-eb1059334028 -ATTRIB_HIDE
echo %%11%%\powercfg.exe /setacvalueindex scheme_current sub_processor 0cc5b647-c1df-4637-891a-dec35c318583 100
echo %%11%%\powercfg.exe /setacvalueindex scheme_current sub_processor ea062031-0e34-4ff1-9b6d-eb1059334028 100
echo %%11%%\powercfg.exe /setactive scheme_current
)>"%mountdir%\Windows\inf\%kb%.inf"
if %online%==1 (
%windir%\system32\rundll32.exe advpack.dll,LaunchINFSection %windir%\inf\%kb%.inf,DefaultInstall 1>nul 2>nul
) else (
%_reg% load HKLM\OFFSOFT "%mountdir%\Windows\System32\config\SOFTWARE" >nul
%_reg% add HKLM\OFFSOFT\Microsoft\Windows\CurrentVersion\RunOnce /v 0%kb% /t REG_EXPAND_SZ /d "rundll32.exe advpack.dll,LaunchINFSection %%windir%%\inf\%kb%.inf,DefaultInstall" /f 1>nul 2>nul
%_reg% unload HKLM\OFFSOFT >nul
)
call :cabonline
goto :eof

:cabonline
expand.exe -f:*Windows*.cab %package% "%cab_dir%" >nul
"%dismroot%" %dismtarget% /NoRestart /Add-Package /packagepath:"%cab_dir%"
del /f /q "%cab_dir%\*%kb%*.cab"
goto :eof

rem ##################################################################

:cab
if %verb%==1 (
echo.
echo ============================================================
echo Checking Applicable Updates
echo ============================================================
echo.
)
set count=0
if %_cab% neq 0 (set msu=0&for /f %%G in ('dir /b *%arch%*.cab') do (set package=%%G&call :cab2))
if %_msu% neq 0 (set msu=1&for /f %%G in ('dir /b *%arch%*.msu') do (set package=%%G&call :cab2))
goto :eof

:cab2
if %online%==1 if %count% equ %onlinelimit% goto :eof
for /f "tokens=2 delims=-" %%V in ('dir /b %package%') do set kb=%%V
if %IEcab% equ 1 for /f "tokens=3 delims=-" %%V in ('dir /b %package%') do set kb=%%V
if /i %kb%==SelfUpdate for /f "tokens=3 delims=-" %%V in ('dir /b %package%') do set kb=%%V
if /i %kb%==%rollup% (set /a _sum-=1&set /a _msu-=1&goto :eof)
if /i %kb%==%ssu1st% (set /a _sum-=1&set /a _msu-=1&goto :eof)
if /i %kb%==%ssu2nd% (set /a _sum-=1&set /a _msu-=1&goto :eof)
if /i %kb%==%sha2cs% (set /a _sum-=1&set /a _msu-=1&goto :eof)
if /i %kb%==KB917607 (if exist "%mountdir%\Windows\servicing\packages\*Winhelp-Update-Client*.mum" set /a _sum-=1&set /a _msu-=1&goto :eof)
if /i %kb%==KB971033 (if exist "%mountdir%\Windows\servicing\packages\*WindowsActivationTechnologies*.mum" set /a _sum-=1&set /a _msu-=1&goto :eof)
if /i %kb%==KB2670838 (if exist "%mountdir%\Windows\servicing\packages\*PlatformUpdate-Win7-SRV08R2*.mum" set /a _sum-=1&set /a _msu-=1&goto :eof)
if /i %kb%==KB2592687 (if exist "%mountdir%\Windows\servicing\packages\*RDP-WinIP-Package*.mum" set /a _sum-=1&set /a _msu-=1&goto :eof)
if /i %kb%==KB2830477 (if exist "%mountdir%\Windows\servicing\packages\*RDP-BlueIP-Package*.mum" set /a _sum-=1&set /a _msu-=1&goto :eof)
if /i %kb%==KB982861 (if exist "%mountdir%\Windows\servicing\packages\*InternetExplorer*9.4.*.mum" set /a _sum-=1&set /a _msu-=1&goto :eof)
if /i %kb%==KB2841134 (if exist "%mountdir%\Windows\servicing\packages\*InternetExplorer*11.2.*.mum" set /a _sum-=1&set /a _cab-=1&goto :eof)
if /i %kb%==KB2849696 (if exist "%mountdir%\Windows\servicing\packages\*IE-Spelling-Parent-Package-English*11.2.*.mum" set /a _sum-=1&set /a _msu-=1&goto :eof)
if /i %kb%==KB2849697 (if exist "%mountdir%\Windows\servicing\packages\*IE-Hyphenation-Parent-Package-English*11.2.*.mum" set /a _sum-=1&set /a _msu-=1&goto :eof)
if /i %kb%==KB3191566 (if exist "%mountdir%\Windows\servicing\packages\*WinMan-WinIP*7.3.7601.16384.mum" set /a _sum-=1&set /a _msu-=1&goto :eof)
if /i %kb%==KB2872035 (if exist "%mountdir%\Windows\servicing\packages\Package_for_KB2872035*.mum" set /a _sum-=1&set /a _cab-=1&goto :eof)
if /i %kb%==ActiveX (if exist "%mountdir%\Windows\servicing\packages\WUClient-SelfUpdate-ActiveX*7.6.7600.320.mum" set /a _sum-=1&set /a _cab-=1&goto :eof)
if /i %kb%==Aux (if exist "%mountdir%\Windows\servicing\packages\WUClient-SelfUpdate-Aux*7.6.7600.320.mum" set /a _sum-=1&set /a _cab-=1&goto :eof)
if /i %kb%==Core (if exist "%mountdir%\Windows\servicing\packages\WUClient-SelfUpdate-Core*7.6.7600.320.mum" set /a _sum-=1&set /a _cab-=1&goto :eof)
for %%G in %rdp8% do (
  if /i !kb!==%%G (call set /a _sum-=1&call set /a _msu-=1&goto :eof)
)
if /i "%cat%"=="Security Updates" (
if exist "%cab_dir%\check\" rd /s /q "%cab_dir%\check"
md "%cab_dir%\check"
if %msu% equ 1 (expand.exe -f:*Windows*.xml %package% "%cab_dir%\check" >nul) else (expand.exe -f:update.mum %package% "%cab_dir%\check" >nul)
findstr /i /m "Package_for_RollupFix" "%cab_dir%\check\*" 1>nul 2>nul && (
  if %ssuver:~9% lss 24383 goto :eof
  if %shaupd% neq 1 goto :eof
  ) || (
  if exist "%mountdir%\sources\recovery\RecEnv.exe" (set /a _sum-=1&if %msu% equ 1 (set /a _msu-=1&goto :eof) else (set /a _cab-=1&goto :eof))
  )
)
set inver=0
if /i %kb%==%hv_integ_kb% if exist "%mountdir%\Windows\servicing\packages\*Hyper-V-Integration-Services*.mum" (
for /f "tokens=6,7 delims=~." %%i in ('dir /b /od "%mountdir%\Windows\servicing\packages\*Hyper-V-Integration-Services*.mum"') do set inver=%%i%%j
if !inver! GEQ !hv_integ_vr! (set /a _sum-=1&set /a _cab-=1&goto :eof)
)
set "mumcheck=package_*_for_%kb%*6.1*.mum"
if /i %LDRbranch% neq ON set "mumcheck=package_*_for_%kb%~*6.1*.mum"
if %IEcab% equ 1 set "mumcheck=package_for_%kb%*.mum"
if /i %LDRbranch% neq ON if %IEcab% equ 1 set "mumcheck=package_for_%kb%~*.mum"
for %%G in %gdrlist% do (
  if /i !kb!==%%G call set "mumcheck=package_for_%kb%~*6.1*.mum"
)
set inver=0
if /i %kb%==KB2952664 if exist "%mountdir%\Windows\servicing\packages\%mumcheck%" (
for /f "tokens=6,7 delims=~." %%i in ('dir /b /od "%mountdir%\Windows\servicing\packages\%mumcheck%"') do set inver=%%i%%j
md "%cab_dir%\check"
if %msu% equ 1 (expand.exe -f:*Windows*.cab %package% "%cab_dir%\check" >nul) else (copy %package% "%cab_dir%\check" >nul)
expand.exe -f:package_for_%kb%*.mum "%cab_dir%\check\*.cab" "%cab_dir%\check" >nul
for /f "tokens=6,7 delims=~." %%i in ('dir /b "%cab_dir%\check\package_for_%kb%*.mum"') do set kbver=%%i%%j
rd /s /q "%cab_dir%\check"
if !inver! GEQ !kbver! (set /a _sum-=1&if %msu% equ 1 (set /a _msu-=1&goto :eof) else (set /a _cab-=1&goto :eof))
)
if /i not %kb%==KB2952664 if exist "%mountdir%\Windows\servicing\packages\%mumcheck%" (set /a _sum-=1&if %msu% equ 1 (set /a _msu-=1&goto :eof) else (set /a _cab-=1&goto :eof))
set /a count+=1
if %verb%==1 (
echo %count%: %package%
)
if %msu% equ 1 (expand.exe -f:*Windows*.cab %package% "%cab_dir%" >nul) else (copy %package% "%cab_dir%" >nul)
if /i %kb%==KB2849696 ren "%cab_dir%\Windows6.3-KB2849696-x86.cab" IE11-Windows6.1-KB2849696-%arch%.cab
if /i %kb%==KB2849697 ren "%cab_dir%\Windows6.3-KB2849697-x86.cab" IE11-Windows6.1-KB2849697-%arch%.cab
goto :eof

:mum
if %verb%==1 (
echo.
echo ============================================================
echo Extracting files from update cabinets ^(.cab^)
echo *** This will require some disk space, please be patient ***
echo ============================================================
echo.
)
set ldr=&set listc=0&set list=1&set AC=100&set count=0
cd /d "%cab_dir%"
if /i "%cat%"=="WMF Updates" for %%G in (2872035,2872047,2809215,3033929) do (if exist "*%%G*.cab" del /f /q "*%%G*.cab" >nul)
for /f %%G in ('dir /b *.cab') do (call :mum2 %%G)
goto :eof

:mum2
if %listc% geq %ac% (set /a AC+=100&set /a list+=1&set ldr%list%=%ldr%&set ldr=)
set package=%1
set dest=%~n1
if not exist "%dest%" mkdir "%dest%"
set /a count+=1
set /a allcount+=1
set /a listc+=1
for /f "tokens=2 delims=-" %%V in ('dir /b %package%') do set kb=%%V
if not exist "%dest%\*.manifest" (
if %verb%==1 echo %count%/%_sum%: %package%
expand.exe -f:* "%package%" "%dest%" 1>nul 2>nul || (set "ldr=!ldr! /packagepath:%package%"&goto :eof)
)
if /i %LDRbranch% neq ON (set "ldr=!ldr! /packagepath:%dest%\update.mum"&goto :eof)
for %%G in %gdrlist% do (
  if /i !kb!==%%G call set "ldr=!ldr! /packagepath:%dest%\update.mum"&goto :eof
)
if exist "%dest%\update-bf.mum" (set "ldr=!ldr! /packagepath:%dest%\update-bf.mum") else (set "ldr=!ldr! /packagepath:%dest%\update.mum")
if not exist "%dest%\*cablist.ini" goto :eof
expand.exe -f:* "%dest%\*.cab" "%dest%" 1>nul 2>nul || (set "ldr=!ldr! /packagepath:%package%")
del /f /q "%dest%\*cablist.ini" 1>nul 2>nul
del /f /q "%dest%\*.cab" 1>nul 2>nul
goto :eof

:listdone
if %listc% leq %ac% (set ldr%list%=%ldr%)
set lc=1

:PP
if %lc% gtr %list% (
if /i "%cat%"=="Security Updates" call :diagtrack
goto :eof
)
call set ldr=%%ldr%lc%%%
set ldr%lc%=
if %verb%==1 (
echo.
echo ============================================================
echo Installing %listc% %cat%, session %lc%/%list%
echo ============================================================
)
"%dismroot%" %dismtarget% /NoRestart /Add-Package %ldr%
set /a lc+=1
goto :PP

:counter
set _msu=0
set _cab=0
set _sum=0
if exist "*%arch%*.msu" (for /f %%a in ('dir /b *%arch%*.msu') do (call set /a _msu+=1))
if exist "*%arch%*.cab" (for /f %%a in ('dir /b *%arch%*.cab') do (call set /a _cab+=1))
set /a _sum=%_msu%+%_cab%
goto :eof

:cleaner
cd /d "%repo%"
if %wim%==1 (
if exist "%cab_dir%\*.cab" del /f /q "%cab_dir%\*.cab" >nul
) else if %dvd%==1 (
if exist "%cab_dir%\*.cab" del /f /q "%cab_dir%\*.cab" >nul
) else (
  if exist "%cab_dir%" (
  echo.
  echo ============================================================
  echo Removing temporary extracted files...
  echo ============================================================
  rmdir /s /q "%cab_dir%" >nul
  )
)
if not exist "%cab_dir%" mkdir "%cab_dir%"
goto :eof

rem ##################################################################

:diagtrack
if %online%==1 (
set ksub1=SOFTWARE&set ksub2=SYSTEM
) else (
set ksub1=OFFSOFT&set ksub2=OFFSYST
%_reg% load HKLM\!ksub1! "%mountdir%\Windows\System32\config\SOFTWARE" >nul
%_reg% load HKLM\!ksub2! "%mountdir%\Windows\System32\config\SYSTEM" >nul
)
%_reg% add HKLM\%ksub1%\Policies\Microsoft\Windows\Gwx /v DisableGwx /t REG_DWORD /d 1 /f 1>nul 2>nul
%_reg% add HKLM\%ksub1%\Policies\Microsoft\Windows\WindowsUpdate /v DisableOSUpgrade /t REG_DWORD /d 1 /f 1>nul 2>nul
%_reg% delete HKLM\%ksub1%\Microsoft\Windows\CurrentVersion\WindowsUpdate\OSUpgrade /f 1>nul 2>nul
%_reg% add HKLM\%ksub1%\Microsoft\Windows\CurrentVersion\WindowsUpdate\OSUpgrade /v AllowOSUpgrade /t REG_DWORD /d 0 /f 1>nul 2>nul
%_reg% delete HKLM\%ksub1%\Policies\Microsoft\Windows\DataCollection /f 1>nul 2>nul
%_reg% delete HKLM\%ksub1%\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack /f 1>nul 2>nul
%_reg% add HKLM\%ksub1%\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack /v DiagTrackAuthorization /t REG_DWORD /d 0 /f 1>nul 2>nul
%_reg% add HKLM\%ksub1%\Microsoft\SQMClient\IE /v CEIPEnable /t REG_DWORD /d 0 /f 1>nul 2>nul
%_reg% add HKLM\%ksub1%\Microsoft\SQMClient\IE /v SqmLoggerRunning /t REG_DWORD /d 0 /f 1>nul 2>nul
%_reg% add HKLM\%ksub1%\Microsoft\SQMClient\Reliability /v CEIPEnable /t REG_DWORD /d 0 /f 1>nul 2>nul
%_reg% add HKLM\%ksub1%\Microsoft\SQMClient\Reliability /v SqmLoggerRunning /t REG_DWORD /d 0 /f 1>nul 2>nul
%_reg% add HKLM\%ksub1%\Microsoft\SQMClient\Windows /v CEIPEnable /t REG_DWORD /d 0 /f 1>nul 2>nul
%_reg% add HKLM\%ksub1%\Microsoft\SQMClient\Windows /v SqmLoggerRunning /t REG_DWORD /d 0 /f 1>nul 2>nul
%_reg% add HKLM\%ksub1%\Microsoft\SQMClient\Windows /v DisableOptinExperience /t REG_DWORD /d 1 /f 1>nul 2>nul
%_reg% add HKLM\%ksub2%\ControlSet001\Services\DiagTrack /v Start /t REG_DWORD /d 4 /f 1>nul 2>nul
%_reg% delete HKLM\%ksub2%\ControlSet001\Control\WMI\AutoLogger\AutoLogger-Diagtrack-Listener /f 1>nul 2>nul
%_reg% delete HKLM\%ksub2%\ControlSet001\Control\WMI\AutoLogger\Diagtrack-Listener /f 1>nul 2>nul
%_reg% delete HKLM\%ksub2%\ControlSet001\Control\WMI\AutoLogger\SQMLogger /f 1>nul 2>nul
icacls "%mountdir%\ProgramData\Microsoft\Diagnosis" /grant:r *S-1-5-32-544:(OI)(CI)(IO)(F) /T /C 1>nul 2>nul
del /f /q "%mountdir%\ProgramData\Microsoft\Diagnosis\*.rbs" 1>nul 2>nul
del /f /q /s "%mountdir%\ProgramData\Microsoft\Diagnosis\ETLLogs\*" 1>nul 2>nul
if %online%==0 (
%_reg% unload HKLM\%ksub1% >nul
%_reg% unload HKLM\%ksub2% >nul
)
call :win10u
goto :eof

:win10u
if exist "%mountdir%\sources\recovery\RecEnv.exe" goto :eof
if exist "%mountdir%\Users\Public\Desktop\RunOnce_W10_Telemetry_Tasks.cmd" goto :eof
if %online%==1 (
schtasks /query /tn "\Microsoft\Windows\Application Experience\ProgramDataUpdater" 1>nul 2>nul || goto :eof
)
echo.
echo ============================================================
echo Processing Windows10/Telemetry block tweaks
echo ============================================================
if %online%==1 (
set ksub1=SOFTWARE&set ksub2=SYSTEM
) else (
set ksub1=OFFSOFT&set ksub2=OFFSYST
%_reg% load HKLM\!ksub1! "%mountdir%\Windows\System32\config\SOFTWARE" >nul
)
%_reg% delete "HKLM\%ksub1%\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Appraiser" /f 1>nul 2>nul
%_reg% add "HKLM\%ksub1%\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Appraiser" /v HaveUploadedForTarget /t REG_DWORD /d 1 /f 1>nul 2>nul
%_reg% add "HKLM\%ksub1%\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\AIT" /v AITEnable /t REG_DWORD /d 0 /f 1>nul 2>nul
%_reg% delete "HKLM\%ksub1%\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\ClientTelemetry" /f 1>nul 2>nul
%_reg% add "HKLM\%ksub1%\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\ClientTelemetry" /v DontRetryOnError /t REG_DWORD /d 1 /f 1>nul 2>nul
%_reg% add "HKLM\%ksub1%\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\ClientTelemetry" /v IsCensusDisabled /t REG_DWORD /d 1 /f 1>nul 2>nul
%_reg% add "HKLM\%ksub1%\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\ClientTelemetry" /v TaskEnableRun /t REG_DWORD /d 1 /f 1>nul 2>nul
%_reg% delete "HKLM\%ksub1%\Microsoft\Windows NT\CurrentVersion\AppCompatFlags" /v UpgradeEligible /f 1>nul 2>nul
%_reg% delete "HKLM\%ksub1%\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\TelemetryController" /f 1>nul 2>nul
%_reg% delete HKLM\%ksub1%\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack /f 1>nul 2>nul
%_reg% add HKLM\%ksub1%\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack /v DiagTrackAuthorization /t REG_DWORD /d 0 /f 1>nul 2>nul

set "T_Win=Microsoft\Windows"
set "T_App=Microsoft\Windows\Application Experience"
set "T_CEIP=Microsoft\Windows\Customer Experience Improvement Program"
(echo @echo off
echo reg.exe query "HKU\S-1-5-19" 1^>nul 2^>nul ^|^| ^(echo Run the script as administrator^&pause^&exit^)
echo reg.exe delete HKLM\SYSTEM\CurrentControlSet\Control\WMI\AutoLogger\AutoLogger-Diagtrack-Listener /f
echo reg.exe delete HKLM\SYSTEM\CurrentControlSet\Control\WMI\AutoLogger\Diagtrack-Listener /f
echo reg.exe delete HKLM\SYSTEM\CurrentControlSet\Control\WMI\AutoLogger\SQMLogger /f
echo icacls "%%ProgramData%%\Microsoft\Diagnosis" /grant:r *S-1-5-32-544:^(OI^)^(CI^)^(IO^)^(F^) /T /C
echo del /f /q "%%ProgramData%%\Microsoft\Diagnosis\*.rbs"
echo del /f /q /s "%%ProgramData%%\Microsoft\Diagnosis\ETLLogs\*"
echo sc.exe config DiagTrack start= disabled
echo sc.exe stop DiagTrack
echo schtasks.exe /Change /DISABLE /TN "%T_Win%\PerfTrack\BackgroundConfigSurveyor"
echo schtasks.exe /Change /DISABLE /TN "%T_Win%\SetupSQMTask"
echo schtasks.exe /Change /DISABLE /TN "%T_CEIP%\BthSQM"
echo schtasks.exe /Change /DISABLE /TN "%T_CEIP%\Consolidator"
echo schtasks.exe /Change /DISABLE /TN "%T_CEIP%\KernelCeipTask"
echo schtasks.exe /Change /DISABLE /TN "%T_CEIP%\TelTask"
echo schtasks.exe /Change /DISABLE /TN "%T_CEIP%\UsbCeip"
echo schtasks.exe /Change /DISABLE /TN "%T_App%\AitAgent"
echo schtasks.exe /Change /DISABLE /TN "%T_App%\Microsoft Compatibility Appraiser"
echo schtasks.exe /Change /DISABLE /TN "%T_App%\ProgramDataUpdater"
echo schtasks.exe /Delete /TN "%T_Win%\PerfTrack\BackgroundConfigSurveyor" /F
echo schtasks.exe /Delete /TN "%T_Win%\SetupSQMTask" /F
echo schtasks.exe /Delete /TN "%T_CEIP%\BthSQM" /F
echo schtasks.exe /Delete /TN "%T_CEIP%\Consolidator" /F
echo schtasks.exe /Delete /TN "%T_CEIP%\KernelCeipTask" /F
echo schtasks.exe /Delete /TN "%T_CEIP%\TelTask" /F
echo schtasks.exe /Delete /TN "%T_CEIP%\UsbCeip" /F
echo schtasks.exe /Delete /TN "%T_App%\AitAgent" /F
echo schtasks.exe /Delete /TN "%T_App%\Microsoft Compatibility Appraiser" /F
echo schtasks.exe /Delete /TN "%T_App%\ProgramDataUpdater" /F
echo start /b "" cmd /c del "%%~f0"^&exit /b
)>"%cd%\W10Tel.cmd"

if %online%==1 (
1>nul 2>nul call "%cd%\W10Tel.cmd"
) else (
move /y "%cd%\W10Tel.cmd" "%mountdir%\Users\Public\Desktop\RunOnce_W10_Telemetry_Tasks.cmd" >nul
%_reg% unload HKLM\%ksub1% >nul
)
goto :eof

:regfix
if exist "%mountdir%\Windows\WHD-regfix.txt" goto :eof
echo.
echo ============================================================
echo Processing Hotfixes registry tweaks
echo ============================================================
if %online%==1 (
set ksub1=SOFTWARE&set ksub2=SYSTEM
) else (
set ksub1=OFFSOFT&set ksub2=OFFSYST
%_reg% load HKLM\!ksub1! "%mountdir%\Windows\System32\config\SOFTWARE" >nul
%_reg% load HKLM\!ksub2! "%mountdir%\Windows\System32\config\SYSTEM" >nul
)
%_reg% add "HKLM\%ksub1%\Microsoft\Cryptography\Calais" /f /v "TransactionTimeoutDelay" /t REG_DWORD /d 5 >nul
%_reg% add "HKLM\%ksub1%\Microsoft\Cryptography\OID\EncodingType 0\CertDllCreateCertificateChainEngine\Config" /f /v "MinRsaPubKeyBitLength" /t REG_DWORD /d 512 >nul
%_reg% add "HKLM\%ksub1%\Microsoft\Cryptography\OID\EncodingType 0\CertDllCreateCertificateChainEngine\Config" /f /v "EnableWeakSignatureFlags" /t REG_DWORD /d 2 >nul
%_reg% add "HKLM\%ksub1%\Microsoft\MSMQ\Parameters" /f /v "IgnoreOSNameValidationForReceive" /t REG_DWORD /d 1 >nul
%_reg% add "HKLM\%ksub1%\Microsoft\Windows\CurrentVersion\Policies\System" /f /v "EnableLinkedConnections" /t REG_DWORD /d 1 >nul
%_reg% add "HKLM\%ksub1%\Microsoft\Windows\CurrentVersion\Policies\System" /f /v "InteractiveLogonFirst" /t REG_DWORD /d 1 >nul
%_reg% add "HKLM\%ksub1%\Microsoft\Windows NT\CurrentVersion\Windows" /f /v "UMPDSecurityLevel" /t REG_DWORD /d 2 >nul
%_reg% add "HKLM\%ksub1%\Policies\Group Policy" /f /v "PurgeRSOP" /t REG_DWORD /d 1 >nul
%_reg% add "HKLM\%ksub1%\Policies\Microsoft\Netlogon\Parameters" /f /v "AddressLookupOnPingBehavior" /t REG_DWORD /d 2 >nul
%_reg% add "HKLM\%ksub1%\Policies\Microsoft\Windows\Group Policy" /f /v "EnableLocalStoreOverride" /t REG_DWORD /d 1 >nul
%_reg% add "HKLM\%ksub1%\Policies\Microsoft\Windows\Installer" /f /v "NoUACforHashMissing" /t REG_DWORD /d 1 >nul
%_reg% add "HKLM\%ksub1%\Policies\Microsoft\Windows\SmartCardCredentialProvider" /f /v "AllowVirtualSmartCardPinChangeAndUnlock" /t REG_DWORD /d 1 >nul
%_reg% add "HKLM\%ksub2%\ControlSet001\Services\BFE\Parameters" /f /v "MaxEndpointCountMult" /t REG_DWORD /d 10 >nul
%_reg% add "HKLM\%ksub2%\ControlSet001\Services\CSC\Parameters" /f /v "FormatDatabase" /t REG_DWORD /d 1 >nul
%_reg% add "HKLM\%ksub2%\ControlSet001\Services\LanmanServer\Parameters" /f /v "ABELevel" /t REG_DWORD /d 2 >nul
%_reg% add "HKLM\%ksub2%\ControlSet001\Services\LanmanServer\Parameters" /f /v "AsynchronousCredits" /t REG_DWORD /d 4132 >nul
%_reg% add "HKLM\%ksub2%\ControlSet001\Services\LanmanServer\Parameters" /f /v "DisableStrictNameChecking" /t REG_DWORD /d 1 >nul
%_reg% add "HKLM\%ksub2%\ControlSet001\Services\LanmanServer\Parameters" /f /v "OptionalNames" /t REG_SZ /d aliasname >nul
%_reg% add "HKLM\%ksub2%\ControlSet001\Services\LanmanWorkstation\Parameters" /f /v "ExtendedSessTimeout" /t REG_DWORD /d 1152 >nul
%_reg% add "HKLM\%ksub2%\ControlSet001\Services\MRxDAV\Parameters" /f /v "FsCtlRequestTimeoutInSec" /t REG_DWORD /d 3600 >nul
%_reg% add "HKLM\%ksub2%\ControlSet001\Services\WebClient\Parameters" /f /v "EnableCTLFiltering" /t REG_DWORD /d 1 >nul
%_reg% add "HKLM\%ksub2%\ControlSet001\Services\WebClient\Parameters" /f /v "EnableAutoCertSelection" /t REG_DWORD /d 1 >nul
%_reg% add "HKLM\%ksub2%\ControlSet001\Services\RemoteAccess\Parameters\Ip" /f /v "DisableMulticastForwarding" /t REG_DWORD /d 0 >nul
%_reg% add "HKLM\%ksub2%\ControlSet001\Services\usbhub\HubG" /f /v "DisableOnSoftRemove" /t REG_DWORD /d 1 >nul
%_reg% add "HKLM\%ksub2%\ControlSet001\Control\CrashControl" /f /v "MaxSecondaryDataDumpSize" /t REG_DWORD /d 4294967295 >nul
%_reg% add "HKLM\%ksub2%\ControlSet001\Control\Print" /f /v "DnsOnWire" /t REG_DWORD /d 1 >nul
%_reg% add "HKLM\%ksub2%\ControlSet001\Control\Print" /f /v "SplWOW64TimeOutSeconds" /t REG_DWORD /d 576 >nul
%_reg% add "HKLM\%ksub2%\ControlSet001\Control\Pnp" /f /v "BootOptions" /t REG_DWORD /d 0 >nul
%_reg% add "HKLM\%ksub2%\ControlSet001\Control\Pnp" /f /v "DisableCDDB" /t REG_DWORD /d 0 >nul
%_reg% add "HKLM\%ksub2%\ControlSet001\Control\Pnp" /f /v "DontStartRawDevices" /t REG_DWORD /d 0 >nul
%_reg% add "HKLM\%ksub2%\ControlSet001\Control\PnP" /f /v "PollBootPartitionTimeout" /t REG_DWORD /d 120000 >nul
%_reg% add "HKLM\%ksub2%\ControlSet001\Control\usbstor\054C00C1" /f /v "MaximumTransferLength" /t REG_DWORD /d 2097120 >nul
if %online%==0 (
%_reg% unload HKLM\%ksub1% >nul
%_reg% unload HKLM\%ksub2% >nul
)
for %%a in (ServiceProfiles\LocalService,ServiceProfiles\NetworkService,System32\config\systemprofile) do if exist "%mountdir%\Windows\%%a\AppData\LocalLow\*" (
attrib -S -I "%mountdir%\Windows\%%a\AppData\LocalLow\Microsoft\CryptnetUrlCache" 1>nul 2>nul
for /f %%i in ('dir /b /s /as "%mountdir%\Windows\%%a\AppData\LocalLow\Microsoft\CryptnetUrlCache\*"') do (attrib -S -I "%%i" 1>nul 2>nul)
del /s /f /q "%mountdir%\Windows\%%a\AppData\LocalLow\Microsoft\CryptnetUrlCache\Content\*" 1>nul 2>nul
del /s /f /q "%mountdir%\Windows\%%a\AppData\LocalLow\Microsoft\CryptnetUrlCache\MetaData\*" 1>nul 2>nul
for /f %%i in ('dir /b /s "%mountdir%\Windows\%%a\AppData\LocalLow\Microsoft\CryptnetUrlCache\*"') do (attrib +S "%%i" 1>nul 2>nul)
attrib +S "%mountdir%\Windows\%%a\AppData\LocalLow\Microsoft\CryptnetUrlCache" 1>nul 2>nul
)
echo cookie>"%mountdir%\Windows\WHD-regfix.txt"
goto :eof

:stacklimit
echo ============================================================
echo *** ATTENTION ***
echo ============================================================
echo.
echo Installing servicing stack update %ssulmt%
echo require no pending update operation.
echo.
echo please restart the system, then run the script again.
echo.
echo Press 9 to exit.
choice /c 9 /n
if errorlevel 1 (exit) else (rem.)

:countlimit
call :cleaner
echo ============================================================
echo *** ATTENTION ***
echo ============================================================
echo.
echo %onlinelimit% or more updates had been installed
echo installing further more will make the process extremely slow.
echo.
echo please restart the system, then run the script again.
echo.
echo Press 9 to exit.
choice /c 9 /n
if errorlevel 1 (exit) else (rem.)

rem ##################################################################

:mount
if exist "%mountdir%" rmdir /s /q "%mountdir%" >nul
if exist "%winremount%" rmdir /s /q "%winremount%" >nul
if not exist "%mountdir%" mkdir "%mountdir%"
for %%b in (%indices%) do (
echo.
echo ============================================================
echo Mounting %~nx1 - index %%b/%imgcount%
echo ============================================================
"%dismroot%" /Mount-Wim /Wimfile:%1 /Index:%%b /MountDir:"%mountdir%"
if %errorlevel% neq 0 goto :E_MOUNT
call :update
call :cleanupmanual
if %dvd%==1 if exist "%mountdir%\sources\setup.exe" (
  xcopy /CDRY "%mountdir%\sources" "%target%\sources\" 1>nul 2>nul
  del /f /q "%target%\sources\background.bmp" 1>nul 2>nul
  del /f /q "%target%\sources\testplugin.dll" 1>nul 2>nul
  if /i %arch%==x64 if not exist "%target%\efi\boot\bootx64.efi" (
  mkdir "%target%\efi\boot" >nul
  copy /y "%mountdir%\Windows\Boot\EFI\bootmgfw.efi" "%target%\efi\boot\bootx64.efi" >nul
  copy /y "%mountdir%\Windows\Boot\EFI\bootmgr.efi" "%target%\" >nul
  )
  copy /y "%mountdir%\Windows\Boot\PCAT\bootmgr" "%target%\" >nul
  copy /y "%mountdir%\Windows\Boot\PCAT\memtest.exe" "%target%\boot\" >nul
)
if %dvd%==1 if not defined isover (
  if exist "%mountdir%\Windows\WinSxS\Manifests\*_microsoft-windows-rollup-version*.manifest" for /f "tokens=6,7 delims=_." %%i in ('dir /b /a:-d /od "%mountdir%\Windows\WinSxS\Manifests\*_microsoft-windows-rollup-version*.manifest"') do set isover=%%i.%%j
)
if %wim%==1 if exist "%mountdir%\sources\setup.exe" if exist "%~dp1setup.exe" (
  xcopy /CDRY "%mountdir%\sources\setup.exe" "%~dp1" 1>nul 2>nul
)
attrib -S -H -I "%mountdir%\Windows\System32\Recovery\winre.wim" 1>nul 2>nul
if %winre%==1 if exist "%mountdir%\Windows\System32\Recovery\winre.wim" if not exist "%~dp0winre.wim" (
  echo.
  echo ============================================================
  echo Updating winre.wim
  echo ============================================================
  mkdir "!winremount!"
  copy "!mountdir!\Windows\System32\Recovery\winre.wim" "%~dp0winre.wim" >nul
  "!dismroot!" /Mount-Wim /Wimfile:"%~dp0winre.wim" /Index:1 /MountDir:"!winremount!"
  if %errorlevel% neq 0 goto :E_MOUNT
  call :update winre
  call :cleanupmanual
  set "mountdir=!mountdir_b!"
  set dismtarget=/image:"!mountdir!"
  "!dismroot!" /Unmount-Wim /MountDir:"!winremount!" /Commit
  if !errorlevel! neq 0 goto :E_MOUNT
  call :rebuild "%~dp0winre.wim"
)
if exist "%mountdir%\Windows\System32\Recovery\winre.wim" if exist "%~dp0winre.wim" (
echo.
echo ============================================================
echo Adding updated winre.wim
echo ============================================================
echo.
copy /y "%~dp0winre.wim" "%mountdir%\Windows\System32\Recovery"
)
echo.
echo ============================================================
echo Unmounting %~nx1 - index %%b/%imgcount%
echo ============================================================
"%dismroot%" /Unmount-Wim /MountDir:"%mountdir%" /Commit
if %errorlevel% neq 0 goto :E_MOUNT
)
cd /d "%~dp0"
call :rebuild %1
goto :eof

:rebuild
if %winbuild% geq 9600 (
echo.
echo ============================================================
echo Rebuilding %~nx1
echo ============================================================
"%dismroot%" /Export-Image /SourceImageFile:%1 /All /DestinationImageFile:"%~dp0temp.wim"
move /y "%~dp0temp.wim" %1 >nul
goto :eof
)
if exist "%~dp0imagex.exe" (
echo.
echo ============================================================
echo Rebuilding %~nx1
echo ============================================================
"%~dp0imagex.exe" /EXPORT %1 * "%~dp0temp.wim"
move /y "%~dp0temp.wim" %1 >nul
goto :eof
)
if /i not "%dismroot%"=="%windir%\system32\dism.exe" (
echo.
echo ============================================================
echo Rebuilding %~nx1
echo ============================================================
"%dismroot%" /Export-Image /SourceImageFile:%1 /All /DestinationImageFile:"%~dp0temp.wim"
move /y "%~dp0temp.wim" %1 >nul
)
goto :eof

:cleanupmanual
if exist "%mountdir%\sources\recovery\RecEnv.exe" if exist "%mountdir%\Windows\WinSxS\Backup\*" (
del /f /q "%mountdir%\Windows\WinSxS\Backup\*" >nul 2>&1
)
if exist "%mountdir%\Windows\WinSxS\ManifestCache\*.bin" (
takeown /f "%mountdir%\Windows\WinSxS\ManifestCache\*.bin" /A >nul 2>&1
icacls "%mountdir%\Windows\WinSxS\ManifestCache\*.bin" /grant *S-1-5-32-544:F >nul 2>&1
del /f /q "%mountdir%\Windows\WinSxS\ManifestCache\*.bin" >nul 2>&1
)
if exist "%mountdir%\Windows\WinSxS\Temp\PendingDeletes\*" (
takeown /f "%mountdir%\Windows\WinSxS\Temp\PendingDeletes\*" /A >nul 2>&1
icacls "%mountdir%\Windows\WinSxS\Temp\PendingDeletes\*" /grant *S-1-5-32-544:F >nul 2>&1
del /f /q "%mountdir%\Windows\WinSxS\Temp\PendingDeletes\*" >nul 2>&1
)
if exist "%mountdir%\Windows\inf\*.log" (
del /f /q "%mountdir%\Windows\inf\*.log" >nul 2>&1
)
goto :eof

:E_Target
echo.
echo ============================================================
echo ERROR: %MESSAGE%
echo ============================================================
echo.
echo Press any key to continue.
pause >nul
set "target=%SystemDrive%"
goto :mainmenu

:E_Repo
echo.
echo ============================================================
echo ERROR: Specified repository location is not valid
echo ============================================================
echo.
echo Press any key to continue.
pause >nul
set "repo=%~dp0Updates"
goto :mainmenu

:E_MOUNT
echo.
echo ============================================================
echo ERROR: Could not mount or unmount WIM image
echo ============================================================
echo.
echo Press 9 to exit.
choice /c 9 /n
if errorlevel 1 (exit) else (rem.)

:E_Admin
echo.
echo ============================================================
echo ERROR: right click on the script and 'Run as administrator'
echo ============================================================
echo.
echo Press any key to exit.
pause >nul
goto :eof

:checkadk
SET regKeyPathFound=1
SET wowRegKeyPathFound=1
REG QUERY "HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots" /v KitsRoot81 1>NUL 2>NUL || SET wowRegKeyPathFound=0
REG QUERY "HKLM\Software\Microsoft\Windows Kits\Installed Roots" /v KitsRoot81 1>NUL 2>NUL || SET regKeyPathFound=0
if %wowRegKeyPathFound% EQU 0 (
  if %regKeyPathFound% EQU 0 (
    goto :mainmenu
  ) else (
    SET regKeyPath=HKLM\Software\Microsoft\Windows Kits\Installed Roots
  )
) else (
    SET regKeyPath=HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots
)
FOR /F "skip=2 tokens=2*" %%i IN ('REG QUERY "%regKeyPath%" /v KitsRoot81') DO (SET "KitsRoot=%%j")
SET "DandIRoot=%KitsRoot%Assessment and Deployment Kit\Deployment Tools"
SET "oscdimgroot=%DandIRoot%\%PROCESSOR_ARCHITECTURE%\Oscdimg\oscdimg.exe"
SET "dismroot=%DandIRoot%\%PROCESSOR_ARCHITECTURE%\DISM\dism.exe"
if not exist "%dismroot%" set "dismroot=%windir%\system32\dism.exe"
goto :mainmenu

:targetmenu
cls
echo ============================================================
echo Enter the path for one of supported targets:
echo - Distribution folder ^(extracted iso, copied dvd/usb^)
echo - WIM file
echo - Mounted directory, offline image drive letter
echo - Current OS / Enter %SystemDrive%
echo.
echo or just press 'Enter' to return to options menu
echo ============================================================
echo.
set /p "_pp="
if "%_pp%"=="" goto :mainmenu
if "%_pp:~-1%"=="\" set "_pp=%_pp:~0,-1%"
set dvd=0
set wim=0
set offline=0
set online=0
set copytarget=0
set "target=%_pp%"
if /i "%target%"=="%SystemDrive%" set online=1&goto :mainmenu
echo %target%| findstr /E /I "\.wim" >nul
if %errorlevel%==0 (
set wim=1
for /f %%i in ('dir /b "%target%"') do set "targetname=%%i"
) else (
if exist "%target%\sources\boot.wim" set dvd=1 
if exist "%target%\Windows\regedit.exe" set offline=1
)
if %offline%==0 if %wim%==0 if %dvd%==0 (set "MESSAGE=Specified location is not valid"&goto :E_Target)
if %offline%==1 (
dir /b "%target%\Windows\servicing\Version\6.1.7601.*" 1>nul 2>nul || (set "MESSAGE=Detected target offline image is not Windows 7"&goto :E_Target)
set "mountdir=%target%"
if exist "%target%\Windows\SysWOW64\*" (set arch=x64) else (set arch=x86)
)
if %dvd%==1 (
echo.
echo ============================================================
echo Please wait...
echo ============================================================
dir /b /s /adr "%target%" 1>nul 2>nul && set copytarget=1
dism /english /get-wiminfo /wimfile:"%target%\sources\install.wim" /index:1 | find /i "Version : 6.1.7601" >nul || (set "MESSAGE=Detected install.wim version is not Windows 10"&goto :E_Target)
for /f "tokens=2 delims=: " %%i in ('dism /english /get-wiminfo /wimfile:"%target%\sources\install.wim" /index:1 ^| find /i "Architecture"') do set arch=%%i
for /f "tokens=2 delims=: " %%i in ('dism /english /get-wiminfo /wimfile:"%target%\sources\install.wim" ^| findstr "Index"') do set imgcount=%%i
for /L %%i in (1,1,!imgcount!) do (
  for /f "tokens=1* delims=: " %%a in ('dism /english /get-wiminfo /wimfile:"%target%\sources\install.wim" /index:%%i ^| findstr /b /c:"Name"') do set name%%i="%%b"
  )
set "indices=*"
)
if %wim%==1 (
echo.
echo ============================================================
echo Please wait...
echo ============================================================
dism /english /get-wiminfo /wimfile:"%target%" /index:1 | find /i "Version : 6.1.7601" >nul || (set "MESSAGE=Detected wim file version is not Windows 7"&goto :E_Target)
for /f "tokens=2 delims=: " %%i in ('dism /english /get-wiminfo /wimfile:"%target%" /index:1 ^| find /i "Architecture"') do set arch=%%i
for /f "tokens=2 delims=: " %%i in ('dism /english /get-wiminfo /wimfile:"%target%" ^| findstr "Index"') do set imgcount=%%i
for /L %%i in (1,1,!imgcount!) do (
  for /f "tokens=1* delims=: " %%a in ('dism /english /get-wiminfo /wimfile:"%target%" /index:%%i ^| findstr /b /c:"Name"') do set name%%i="%%b"
  )
set "indices=*"
)
goto :mainmenu

:repomenu
cls
echo ============================================================
echo Enter the location of WHD parent "Updates" folder
echo.
echo or just press 'Enter' to return to options menu
echo ============================================================
echo.
set /p "_pp="
if "%_pp%"=="" goto :mainmenu
if "%_pp:~-1%"=="\" set "_pp=%_pp:~0,-1%"
set "repo=%_pp%"
if not exist "%repo%\*" (goto :E_Repo)
goto :mainmenu

:countmenu
cls
echo ============================================================
echo Enter the updates count limit for online installation
echo.
echo or just press 'Enter' to return to options menu
echo ============================================================
echo.
set /p "_pp="
if "%_pp%"=="" goto :mainmenu
set onlinelimit=%_pp%
goto :mainmenu

:dismmenu
cls
echo ============================================================
echo Enter the full path for custom dism.exe
echo.
echo or just press 'Enter' to return to options menu
echo ============================================================
echo.
set /p "_pp="
if "%_pp%"=="" goto :mainmenu
set "dismroot=%_pp%"
if not exist "%dismroot%" (
echo not found: "%dismroot%"
pause
set "dismroot=%windir%\system32\dism.exe"
)
goto :mainmenu

:indexmenu
cls
echo ============================================================
for /L %%i in (1,1,%imgcount%) do (
echo. %%i. !name%%i!
)
echo.
echo ============================================================
echo Enter indexes numbers to update separated with space^(s^)
echo Enter * to select all indexes
echo examples: 1 3 4 or 5 1 or *
echo.
echo or just press 'Enter' to return to options menu
echo ============================================================
echo.
set /p "_pp="
if "%_pp%"=="" goto :mainmenu
if "%_pp%"=="*" set "indices=%_pp%"&goto :mainmenu
for %%i in (%_pp%) do (
if %%i gtr %imgcount% echo.&echo %%i is higher than available indexes&pause&set _pp=&goto :indexmenu
if %%i equ 0 echo.&echo 0 is not valid index&pause&set _pp=&goto :indexmenu
)
set "indices=%_pp%"
goto :mainmenu

:mainmenu
if %autostart%==1 goto :mainboard
set _pp=
cls
echo ==================================================================
echo.
if /i "%target%"=="%SystemDrive%" (
if %winbuild% neq 7601 (set "target="&echo 1. Select offline target) else (echo 1. Target   ^(%arch%^) : Current Online OS)
) else (
if /i "%target%"=="" (echo 1. Select offline target) else (echo 1. Target   ^(%arch%^) : "%target%")
)
echo 2. WHD Repository : "%repo%"
echo 3. LDR branch     : %LDRbranch%
echo 4. IE11           : %IE11%
echo 5. RDP            : %RDP%
echo 6. Hotfixes       : %Hotfix%
echo 7. Features       : %Features%
echo 8. WMF            : %WMF%
echo A. WAT ^(KB971033^) : %WAT%
if /i "%Windows10%"=="OFF" (echo W. Windows10      : %Windows10%) else (echo W. Windows10      : %Windows10%        / B. Block Windows10/Telemetry: %win10u%)
echo S. ADLDS          : %ADLDS%
echo R. RSAT           : %RSAT%
if /i not "%target%"=="%SystemDrive%" (echo D. DISM : "%dismroot%")
if /i "%target%"=="%SystemDrive%" (echo 9. Online installation limit: %onlinelimit% updates)
if %dvd%==1 (
if %winre%==1 (echo E. Update WinRE.wim: ON) else (echo E. Update WinRE.wim: OFF)
if %imgcount% gtr 1 (if "%indices%"=="*" (echo I. Install.wim selected indexes: All ^(%imgcount%^)) else (echo I. Install.wim selected indexes: %indices%))
)
if %wim%==1 (
if %winre%==1 (echo E. Update WinRE.wim: ON) else (echo E. Update WinRE.wim: OFF)
if %imgcount% gtr 1 (if "%indices%"=="*" (echo I. Install.wim selected indexes: All ^(%imgcount%^)) else (echo I. Install.wim selected indexes: %indices%))
)
echo.
echo ==================================================================
echo 0. Start the process
echo ==================================================================
echo.
choice /c 1234567890DAWSRBEIX /n /m "Change a menu option, press 0 to start, or X to exit: "
if errorlevel 19 goto :eof
if errorlevel 18 goto :indexmenu
if errorlevel 17 (if /i %winre% equ 1 (set winre=0) else (set winre=1))&goto :mainmenu
if errorlevel 16 (if /i %win10u% equ ON (set win10u=OFF) else (set win10u=ON))&goto :mainmenu
if errorlevel 15 (if /i %RSAT% equ ON (set RSAT=OFF) else (set RSAT=ON))&goto :mainmenu
if errorlevel 14 (if /i %ADLDS% equ ON (set ADLDS=OFF) else (set ADLDS=ON))&goto :mainmenu
if errorlevel 13 (if /i %Windows10% equ ON (set Windows10=OFF) else (set Windows10=ON))&goto :mainmenu
if errorlevel 12 (if /i %WAT% equ ON (set WAT=OFF) else (set WAT=ON))&goto :mainmenu
if errorlevel 11 goto :dismmenu
if errorlevel 10 goto :mainboard
if errorlevel 9 goto :countmenu
if errorlevel 8 (if /i %WMF% equ ON (set WMF=OFF) else (set WMF=ON))&goto :mainmenu
if errorlevel 7 (if /i %Features% equ ON (set Features=OFF) else (set Features=ON))&goto :mainmenu
if errorlevel 6 (if /i %Hotfix% equ ON (set Hotfix=OFF) else (set Hotfix=ON))&goto :mainmenu
if errorlevel 5 (if /i %RDP% equ ON (set RDP=OFF) else (set RDP=ON))&goto :mainmenu
if errorlevel 4 (if /i %IE11% equ ON (set IE11=OFF) else (set IE11=ON))&goto :mainmenu
if errorlevel 3 (if /i %LDRbranch% equ ON (set LDRbranch=OFF) else (set LDRbranch=ON))&goto :mainmenu
if errorlevel 2 goto :repomenu
if errorlevel 1 goto :targetmenu
goto :mainmenu

:ISO
if not exist "%oscdimgroot%" if not exist "%~dp0cdimage.exe" if not exist "%~dp0oscdimg.exe" goto :eof
for /f "skip=1" %%x in ('wmic os get localdatetime') do if not defined MyDate set MyDate=%%x
set isodate=%MyDate:~0,4%-%MyDate:~4,2%-%MyDate:~6,2%
if defined isover (set isofile=Win7_%isover%_%arch%_%isodate%.iso) else (set isofile=Win7_%arch%_%isodate%.iso)
if exist "%isofile%" (echo %isofile% already exist in current directory&goto :eof)
echo.
echo ============================================================
echo Creating updated ISO file...
echo ============================================================
if exist "%oscdimgroot%" (set _ff="%oscdimgroot%") else if exist "%~dp0cdimage.exe" (set _ff=cdimage.exe) else (set _ff=oscdimg.exe)
if exist "%target%\efi\microsoft\boot\efisys.bin" (
%_ff% -m -o -u2 -udfver102 -bootdata:2#p0,e,b"%target%\boot\etfsboot.com"#pEF,e,b"%target%\efi\microsoft\boot\efisys.bin" -l"%isover%u" "%target%" %isofile%
) else (
%_ff% -m -o -u2 -udfver102 -b"%target%\boot\etfsboot.com" -l"%isover%u" "%target%" %isofile%
)
if %errorlevel% equ 0 if %delete_source% equ 1 rmdir /s /q "%target%" >nul
goto :eof

:fin
cd /d "%~dp0"
if exist "%cab_dir%" (
echo.
echo ============================================================
echo Removing temporary extracted files...
echo ============================================================
rmdir /s /q "%cab_dir%" >nul
)
if %dvd%==1 (if exist "%mountdir%" rmdir /s /q "%mountdir%" >nul)
if %wim%==1 (if exist "%mountdir%" rmdir /s /q "%mountdir%" >nul)
if exist "%winremount%" rmdir /s /q "%winremount%" >nul
if %dvd%==1 if %iso%==1 call :ISO
echo.
echo ============================================================
echo    Finished
echo ============================================================
echo.
if %online%==1 if exist "%windir%\winsxs\pending.xml" (
echo.
echo ============================================================
echo System restart is required to complete installation
echo ============================================================
echo.
)
echo.
echo Press 9 to exit.
choice /c 9 /n
if errorlevel 1 (exit) else (rem.)
