@setlocal DisableDelayedExpansion
@set uiv=v0.4
@echo off
:: enable debug mode, you must also set target and repo (if updates are not beside the script)
set _Debug=0

:: when changing below options, recommended to set the new values between = and " marks

:: target distribution, wim file or offline image
:: leave it blank to update current online os, or automatically detect wim file next to the script
set "Target="

:: updates location
:: leave it blank to automatically detect the current script directory
set "Repo="

:: dism.exe tool custom path
set "DismRoot=dism.exe"

:: update winre.wim if detected inside install.wim
set WinRE=1

:: set directory for temporary extracted files (default is on the same drive as the script)
set "Cab_Dir=W7ESUItemp"

:: set mount directory for updating wim files (default is on the same drive as the script)
set "MountDir=W7ESUImount"
set "WinreMount=W7ESUImountre"

:: start the process directly once you execute the script, as long as the other options are correctly set
set AutoStart=0

:: # Options for distribution target only #

:: create new iso file
:: require Win ADK, or place oscdimg.exe or cdimage.exe next to the script
set ISO=1

:: folder path for iso file, leave it blank to create in the script current directory
set "ISODir="

:: delete DVD distribution folder after creating updated ISO
set Delete_Source=0

:: ###################################################################
:: # NORMALLY THERE IS NO NEED TO CHANGE ANYTHING BELOW THIS COMMENT #
:: ###################################################################

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
set "SysPath=%SystemRoot%\System32"
if exist "%SystemRoot%\Sysnative\reg.exe" (set "SysPath=%SystemRoot%\Sysnative")
set "Path=%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
set "xOS=amd64"
if /i "%PROCESSOR_ARCHITECTURE%"=="arm64" set "xOS=arm64"
if /i "%PROCESSOR_ARCHITECTURE%"=="x86" if "%PROCESSOR_ARCHITEW6432%"=="" set "xOS=x86"
if /i "%PROCESSOR_ARCHITEW6432%"=="amd64" set "xOS=amd64"
if /i "%PROCESSOR_ARCHITEW6432%"=="arm64" set "xOS=arm64"
@cls
set "_Null=1>nul 2>nul"
reg.exe query HKU\S-1-5-19 %_Null% || goto :E_Admin
set "_CBS=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing"
set "_Pkt=31bf3856ad364e35"
set "_OurVer=6.3.9603.30600"
set "_oscdimg=%SysPath%\oscdimg.exe"
set "_imagex=%SysPath%\imagex.exe"
set "_log=%~dpn0"
set "_work=%~dp0"
set "_work=%_work:~0,-1%"
for /f "skip=2 tokens=2*" %%a in ('reg.exe query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop') do call set "_dsk=%%b"
if exist "%PUBLIC%\Desktop\desktop.ini" set "_dsk=%PUBLIC%\Desktop"
setlocal EnableDelayedExpansion

if %_Debug% equ 0 (
  set "_Nul1=1>nul"
  set "_Nul2=2>nul"
  set "_Nul6=2^>nul"
  set "_Nul3=1>nul 2>nul"
  set "_Pause=pause >nul"
  set "_Goto=goto :mainmenu"
  goto :Begin
)
  set "_Nul1="
  set "_Nul2="
  set "_Nul6="
  set "_Nul3="
  set "_Pause="
  set "_Goto=exit /b"
copy /y nul "!_work!\#.rw" %_Null% && (if exist "!_work!\#.rw" del /f /q "!_work!\#.rw") || (set "_log=!_dsk!\%~n0")
echo.
echo Running in Debug Mode...
echo The window will be closed when finished
@echo on
@prompt $G
@call :Begin >"!_log!_tmp.log" 2>&1 &cmd /u /c type "!_log!_tmp.log">"!_log!_Debug.log"&del "!_log!_tmp.log"
@title %ComSpec%
@exit /b

:Begin
title Standalone Installer for Windows 7 ESU Updates
cd /d "!_work!"
if not exist "W7ESUI.ini" goto :proceed
findstr /i "W7ESUI-Configuration" W7ESUI.ini %_Nul1% || goto :proceed
setlocal DisableDelayedExpansion
for %%# in (
Target
Repo
DismRoot
WinRE
Cab_Dir
MountDir
WinreMount
ISO
ISODir
Delete_Source
AutoStart
) do (
call :ReadINI %%#
)
setlocal EnableDelayedExpansion
goto :proceed

:ReadINI
findstr /i "%1 " W7ESUI.ini >nul || goto :eof
for /f "tokens=1* delims==" %%A in ('findstr /i /c:"%1 " W7ESUI.ini') do call set "%1=%%~B"
goto :eof

:proceed
if %_Debug% neq 0 set autostart=1
for /f "tokens=6 delims=[]. " %%# in ('ver') do set winbuild=%%#
set win7=0
if %winbuild% geq 7600 if %winbuild% lss 9200 set win7=1
if exist "!_work!\imagex.exe" set "_imagex=!_work!\imagex.exe"
if "!repo!"=="" set "repo=!_work!"
if "!dismroot!"=="" set "DismRoot=dism.exe"
if "!cab_dir!"=="" set "Cab_Dir=W7ESUItemp"
if "!mountdir!"=="" set "MountDir=W7ESUImount"
if "!winremount!"=="" set "WinreMount=W7ESUImountre"
if "%WinRE%"=="" set WinRE=1
if "%ISO%"=="" set ISO=1
if "%AutoStart%"=="" set AutoStart=0
if "%Delete_Source%"=="" set Delete_Source=0
set _ADK=0
set "ShowDism=Host OS"
set "_dism2=%DismRoot% /NoRestart /ScratchDir"
if /i not "!DismRoot!"=="dism.exe" (
set "ShowDism=%DismRoot%"
set _dism2="%DismRoot%" /NoRestart /ScratchDir
)
set _drv=%~d0
if /i "%cab_dir:~0,6%"=="W7ESUI" set "cab_dir=%_drv%\W7ESUItemp"
set _ntf=NTFS
if /i not "%_drv%"=="%SystemDrive%" for /f "tokens=2 delims==" %%# in ('"wmic volume where DriveLetter='%_drv%' get FileSystem /value"') do set "_ntf=%%#"
if /i not "%_ntf%"=="NTFS" set _drv=%SystemDrive%
if /i "%mountdir:~0,6%"=="W7ESUI" set "mountdir=%_drv%\W7ESUImount"
if /i "%winremount:~0,6%"=="W7ESUI" set "winremount=%_drv%\W7ESUImountre"
if "%cab_dir:~-1%"=="\" set "cab_dir=!cab_dir:~0,-1!"
if "%cab_dir:~-1%"==":" set "cab_dir=!cab_dir!\"
if not "!cab_dir!"=="!cab_dir: =!" set "cab_dir=!cab_dir: =!"
if "%mountdir:~-1%"=="\" set "mountdir=!mountdir:~0,-1!"
if "%mountdir:~-1%"==":" set "mountdir=!mountdir!\"
if not "!mountdir!"=="!mountdir: =!" set "mountdir=!mountdir: =!"
set "mountdir=!mountdir!_%random%"
set "winremount=!winremount!_%random%"
set "cab_dir=!cab_dir!_%random%"
if exist "!cab_dir!\" (
echo.
echo ============================================================
echo Cleaning temporary extraction folder...
echo ============================================================
echo.
rmdir /s /q "!cab_dir!\" %_Nul1%
)
set _init=1

:checktarget
set verbuild=0
set svcbuild=0
set esuready=0
set dvd=0
set wim=0
set offline=0
set online=0
set copytarget=0
set imgcount=0
set wimfiles=0
set keep=0
set targetname=0
if %_init%==1 if "!target!"=="" if exist "*.wim" (for /f "tokens=* delims=" %%# in ('dir /b /a:-d "*.wim"') do set "target=!_work!\%%~nx#")
if "!target!"=="" set "target=%SystemDrive%"
if "%target:~-1%"=="\" set "target=!target:~0,-1!"
if /i "!target!"=="%SystemDrive%" (
if %xOS%==amd64 (set arch=x64) else (set arch=x86)
if %_init%==1 (goto :check) else (goto :mainmenu)
)
if /i "%target:~-4%"==".wim" (
if exist "!target!" (
  set wim=1
  for %%# in ("!target!") do set "targetname=%%~nx#"&setlocal DisableDelayedExpansion&set "targetpath=%%~dp#"&setlocal EnableDelayedExpansion
  )
) else (
if exist "!target!\sources\install.wim" set dvd=1
if exist "!target!\Windows\regedit.exe" set offline=1
)
if %offline%==0 if %wim%==0 if %dvd%==0 (if %_init%==1 (set "target=%SystemDrive%"&goto :check) else (set "MESSAGE=Specified location is not valid"&goto :E_Target))
if %offline%==1 (
dir /b /ad "!target!\Windows\servicing\Version\6.1.760*" %_Nul3% || (set "MESSAGE=Detected target offline image is not Windows NT 6.1"&goto :E_Target)
set "mountdir=!target!"
if exist "!target!\Windows\SysWOW64\cmd.exe" (set arch=x64) else (set arch=x86)
)
if %wim%==1 (
echo.
echo ============================================================
echo Please wait...
echo ============================================================
cd /d "!targetpath!"
dism.exe /english /get-wiminfo /wimfile:"%targetname%" /index:1 | find /i "Version : 6.1.760" %_Nul1% || (set "MESSAGE=Detected wim version is not Windows NT 6.1"&goto :E_Target)
for /f "tokens=4 delims=:. " %%# in ('dism.exe /english /get-wiminfo /wimfile:"%targetname%" /index:1 ^| find /i "Version :"') do set "verbuild=%%#"
for /f "tokens=3 delims=: " %%# in ('dism.exe /english /get-wiminfo /wimfile:"%targetname%" /index:1 ^| findstr /i /c:"ServicePack Build"') do set "svcbuild=%%#"
for /f "tokens=2 delims=: " %%# in ('dism.exe /english /get-wiminfo /wimfile:"%targetname%" /index:1 ^| find /i "Architecture"') do set arch=%%#
for /f "tokens=2 delims=: " %%# in ('dism.exe /english /get-wiminfo /wimfile:"%targetname%" ^| find /i "Index"') do set imgcount=%%#
for /L %%# in (1,1,!imgcount!) do (
  for /f "tokens=1* delims=: " %%i in ('dism.exe /english /get-wiminfo /wimfile:"%targetname%" /index:%%# ^| findstr /b /c:"Name"') do set name%%#="%%j"
  )
set "indices=*"
set wimfiles=1
cd /d "!_work!"
)
if %dvd%==1 (
echo.
echo ============================================================
echo Please wait...
echo ============================================================
copy /y nul "!target!\#.rw" %_Nul3% && (del /f /q "!target!\#.rw" %_Nul3%) || (set copytarget=1)
cd /d "!target!"
dism.exe /english /get-wiminfo /wimfile:"sources\install.wim" /index:1 | find /i "Version : 6.1.760" %_Nul1% || (set "MESSAGE=Detected install.wim version is not Windows NT 6.1"&goto :E_Target)
for /f "tokens=4 delims=:. " %%# in ('dism.exe /english /get-wiminfo /wimfile:"sources\install.wim" /index:1 ^| find /i "Version :"') do set "verbuild=%%#"
for /f "tokens=3 delims=: " %%# in ('dism.exe /english /get-wiminfo /wimfile:"sources\install.wim" /index:1 ^| findstr /i /c:"ServicePack Build"') do set "svcbuild=%%#"
for /f "tokens=2 delims=: " %%# in ('dism.exe /english /get-wiminfo /wimfile:"sources\install.wim" /index:1 ^| find /i "Architecture"') do set arch=%%#
for /f "tokens=2 delims=: " %%# in ('dism.exe /english /get-wiminfo /wimfile:"sources\install.wim" ^| find /i "Index"') do set imgcount=%%#
for /f "tokens=2 delims=: " %%# in ('dism.exe /english /get-wiminfo /wimfile:"sources\boot.wim" ^| find /i "Index"') do set bootimg=%%#
for /L %%# in (1,1,!imgcount!) do (
  for /f "tokens=1* delims=: " %%i in ('dism.exe /english /get-wiminfo /wimfile:"sources\install.wim" /index:%%# ^| findstr /b /c:"Name"') do set name%%#="%%j"
  )
set "indices=*"
set "targetname=install.wim"
set wimfiles=1
cd /d "!_work!"
)
if %_init%==1 (goto :check) else (goto :mainmenu)

:check
call :counter
if %_sum%==0 set "repo="
if /i not "!DismRoot!"=="dism.exe" if exist "!DismRoot!" (set _ADK=1&goto :mainmenu)
goto :checkadk

:mainboard
if %win7% neq 1 if /i "!target!"=="%SystemDrive%" (%_Goto%)
if "!target!"=="" (%_Goto%)
if "!repo!"=="" (%_Goto%)
if "%repo:~-1%"=="\" set "repo=!repo:~0,-1!"
if "!cab_dir!"=="" (%_Goto%)
if "!mountdir!"=="" (%_Goto%)
if /i "!target!"=="%SystemDrive%" (set dismtarget=/online&set "mountdir=!target!"&set online=1) else (set dismtarget=/image:"!mountdir!")
set ssuver=6.1.7601.17514
set shaupd=0
if %wimfiles% equ 0 (
for /f %%# in ('dir /b "!target!\Windows\servicing\Version"') do set "ssuver=%%#"
if exist "!target!\Windows\Servicing\Packages\Package_for_KB4474419*.mum" set shaupd=1
)
if %ssuver:~4,4% equ 7601 if %ssuver:~9,5% geq 24383 if %shaupd% equ 1 set esuready=1
if %ssuver:~4,4% geq 7602 if %shaupd% equ 1 set esuready=1
if %verbuild% equ 7601 if %svcbuild% geq 24384 set esuready=1
if %verbuild% geq 7602 set esuready=1
if %esuready% equ 0 (
if %wimfiles% equ 0 if %ssuver:~4,4% equ 7601 if %ssuver:~9,5% lss 24383 if not exist "!repo!\*Windows6.1-KB4490628*%arch%*.*" goto :E_ESU
if %wimfiles% equ 0 if %shaupd% equ 0 if not exist "!repo!\*Windows6.1-KB4474419*%arch%*.*" goto :E_ESU
if %wimfiles% equ 1 if not exist "!repo!\*Windows6.1-KB4474419*%arch%*.*" goto :E_ESU
)

:mainboard2
:: if %_Debug% neq 0 set "
@cls
echo ============================================================
echo Running W7ESUI %uiv%
echo ============================================================
if %online%==1 (
net stop trustedinstaller %_Nul3%
net stop wuauserv %_Nul3%
del /f /q %systemroot%\Logs\CBS\* %_Nul3%
)
del /f /q %systemroot%\Logs\DISM\* %_Nul3%
if %dvd%==1 if %copytarget%==1 (
echo.
echo ============================================================
echo Copying DVD Drive contents to work directory
echo ============================================================
if exist "!_work!\DVD7UI\" rmdir /s /q "!_work!\DVD7UI\" %_Nul1%
robocopy "!target!" "!_work!\DVD7UI" /E /A-:R >nul
set "target=!_work!\DVD7UI"
)
call :extract
if %_sum%==0 goto :fin
if %online%==1 (
call :doupdate
goto :fin
)
if %offline%==1 (
call :doupdate
goto :fin
)
if %wim%==1 (
if "%indices%"=="*" set "indices="&for /L %%# in (1,1,!imgcount!) do set "indices=!indices! %%#"
call :mount "%targetname%"
if /i not "%targetname%"=="winre.wim" (if exist "!_work!\winre.wim" del /f /q "!_work!\winre.wim" %_Nul1%)
goto :fin
)
if %dvd%==0 goto :fin
if "%indices%"=="*" set "indices="&for /L %%# in (1,1,!imgcount!) do set "indices=!indices! %%#"
call :mount sources\install.wim
if exist "!_work!\winre.wim" del /f /q "!_work!\winre.wim" %_Nul1%
xcopy /CRY "!target!\efi\microsoft\boot\fonts" "!target!\boot\fonts\" %_Nul1%
for /f "tokens=3 delims=: " %%# in ('dism.exe /english /get-wiminfo /wimfile:"!target!\sources\boot.wim" /index:1 ^| findstr /i /c:"ServicePack Build"') do if %%# lss 24384 goto :fin
set imgcount=%bootimg%&set "indices="&for /L %%# in (1,1,!imgcount!) do set "indices=!indices! %%#"
call :mount sources\boot.wim
goto :fin

:extract
if /i %arch%==x64 (set efifile=bootx64.efi&set sss=amd64) else (set efifile=bootia32.efi&set sss=x86)
for /f "delims= " %%T in ('robocopy /L . . /njh /njs') do set "TAB=%%T"
call :cleaner
if not exist "!cab_dir!\" mkdir "!cab_dir!"
call :counter
if %_cab% neq 0 (
set msu=0&set count=0
for /f "tokens=* delims=" %%# in ('dir /b "!repo!\*Windows6.1*%arch%*.cab"') do (set "package=%%#"&call :cab1)
)
if %_msu% neq 0 (
echo.
echo ============================================================
echo Extracting .cab files from .msu files
echo ============================================================
echo.
set msu=1&set count=0&set msucab=
for /f "tokens=* delims=" %%# in ('dir /b "!repo!\*Windows6.1*%arch%*.msu"') do (set "package=%%#"&call :cab1)
)
if %_sum%==0 (echo.&echo All applicable updates are detected as installed&goto :eof)
echo.
echo ============================================================
echo Extracting files from update cabinets ^(.cab^)
echo *** This will require some disk space, please be patient ***
echo ============================================================
echo.
cd /d "!cab_dir!"
set count=0&set isoupdate=
for /f "tokens=* delims=" %%# in ('dir /b "!repo!\*Windows6.1*%arch%*.cab"') do (set "package=%%#"&set "dest=%%~n#"&call :cab2)
goto :eof

:cab1
:: for /f "tokens=2 delims=-" %%V in ('echo "!package!"') do set kb=%%V
set kb=
set tn=2
:startcabLoop
for /f "tokens=%tn% delims=-" %%A in ('echo !package!') do (
  if not errorlevel 1 (
    echo %%A|findstr /i /b KB %_Nul1% && (set kb=%%A&goto :endcabLoop)
    set /a tn+=1
    goto :startcabLoop
  ) else (
    goto :endcabLoop
  )
)
:endcabLoop
if "%kb%"=="" goto :eof
if %wimfiles% equ 1 goto :cab1proceed
for %%# in (
Package_for_%kb%~
Package_for_RollupFix
) do if exist "!target!\Windows\servicing\packages\%%#*.mum" (
set "mumcheck=!target!\Windows\servicing\packages\%%#*.mum"
set "pkgcheck=%%#"
call :mumversion !pkgcheck:~0,14!
if !skip!==1 (set /a _sum-=1&if %msu% equ 1 (set /a _msu-=1&goto :eof) else (set /a _cab-=1&goto :eof))
)
:cab1proceed
if %msu% equ 0 goto :eof
set "msucab=!msucab! %kb%"
set /a count+=1
echo %count%/%_msu%: %package%
expand.exe -f:*Windows*.cab "!repo!\!package!" "!repo!" %_Null%
goto :eof

:cab2
set /a count+=1
echo %count%/%_sum%: %package%
if exist "%dest%\" rmdir /s /q "%dest%\" %_Nul3%
mkdir "%dest%"
expand.exe -f:* "!repo!\!package!" "%dest%" %_Null%
if not exist "%dest%\update.mum" rmdir /s /q "%dest%\" %_Nul3% &goto :eof
if exist "%dest%\*cablist.ini" expand.exe -f:* "%dest%\*.cab" "%dest%" %_Null%
if exist "%dest%\*cablist.ini" del /f /q "%dest%\*cablist.ini" %_Nul3% &del /f /q "%dest%\*.cab" %_Nul3%
goto :eof

:doupdate
set verb=1
set "mumtarget=!mountdir!"
if not "%1"=="" (
set verb=0
set "mumtargeb=!mountdir!"
set "mumtarget=!winremount!"
set dismtarget=/image:"!winremount!"
)
if %verb%==1 (
echo.
echo ============================================================
echo Checking Updates...
echo ============================================================
)
if %online%==1 (
set SOFTWARE=SOFTWARE
set COMPONENTS=COMPONENTS
) else (
set SOFTWARE=uiSOFTWARE
set COMPONENTS=uiCOMPONENTS
)
set "_SxS=HKLM\%SOFTWARE%\Microsoft\Windows\CurrentVersion\SideBySide\Winners"
set "_Cmp=HKLM\%COMPONENTS%\DerivedData\Components"
if exist "!mumtarget!\Windows\Servicing\Packages\*~amd64~~*.mum" (
set "xBT=amd64"
set "_EsuKey=%_SxS%\amd64_microsoft-windows-s..edsecurityupdatesai_%_Pkt%_none_0e8b36cfce2fb332"
set "_EsuCom=amd64_microsoft-windows-s..edsecurityupdatesai_%_Pkt%_%_OurVer%_none_6022b34506a8b67a"
set "_EsuIdn=4D6963726F736F66742D57696E646F77732D534C432D436F6D706F6E656E742D457874656E64656453656375726974795570646174657341492C2043756C747572653D6E65757472616C2C2056657273696F6E3D362E332E393630332E33303630302C205075626C69634B6579546F6B656E3D333162663338353661643336346533352C2050726F636573736F724172636869746563747572653D616D6436342C2076657273696F6E53636F70653D4E6F6E537853"
set "_EsuHsh=423FEE4BEB5BCA64D89C7BCF0A69F494288B9A2D947C76A99C369A378B79D411"
) else (
set "xBT=x86"
set "_EsuKey=%_SxS%\x86_microsoft-windows-s..edsecurityupdatesai_%_Pkt%_none_b26c9b4c15d241fc"
set "_EsuCom=x86_microsoft-windows-s..edsecurityupdatesai_%_Pkt%_%_OurVer%_none_040417c14e4b4544"
set "_EsuIdn=4D6963726F736F66742D57696E646F77732D534C432D436F6D706F6E656E742D457874656E64656453656375726974795570646174657341492C2043756C747572653D6E65757472616C2C2056657273696F6E3D362E332E393630332E33303630302C205075626C69634B6579546F6B656E3D333162663338353661643336346533352C2050726F636573736F724172636869746563747572653D7838362C2076657273696F6E53636F70653D4E6F6E537853"
set "_EsuHsh=70FC6E62A198F5D98FDDE11A6E8D6C885E17C53FCFE1D927496351EADEB78E42"
)
set _EsuPkg=0
if exist "!mumtarget!\Windows\WinSxS\Manifests\%_EsuCom%.manifest"  set _EsuPkg=1
set _SrvrC=0
if exist "!mumtarget!\Windows\WinSxS\Manifests\%xBT%_windowsserverfoundation_*.manifest" set _SrvrC=1
set _Embed=0
if exist "!mumtarget!\Windows\Servicing\Packages\*Winemb-*.mum" set _Embed=1
set _WinPE=0
if exist "!mumtarget!\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" set _WinPE=1
set sha2ss=
set sha2cs=
set servicingstack=
set cumulative=
set eupdates=
set IEembed=0
set discard=0
set discardre=0
set ldr=&set listc=0&set list=1&set AC=100
set _sum=0
if exist "!repo!\*Windows6.1*%arch%*.cab" (for /f "tokens=* delims=" %%# in ('dir /b "!repo!\*Windows6.1*%arch%*.cab"') do (call set /a _sum+=1))
if exist "!repo!\*Windows6.1*%arch%*.cab" (for /f "tokens=* delims=" %%# in ('dir /b "!repo!\*Windows6.1*%arch%*.cab"') do (set "package=%%#"&set "dest=%%~n#"&call :procmum))
if %verb%==1 if %_sum%==0 if exist "!mountdir!\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" (echo.&echo All applicable updates are detected as installed&call set discard=1&goto :eof)
if %verb%==1 if %_sum%==0 (echo.&echo All applicable updates are detected as installed&goto :eof)
if %verb%==0 if %_sum%==0 (echo.&echo All applicable updates are detected as installed&call set discardre=1&goto :eof)
if %_EsuPkg% equ 0 call :ESUadd %_Nul3%
if %listc% lss %ac% set "ldr%list%=%ldr%"
if defined sha2ss (
if %verb%==1 (
echo.
echo ============================================================
echo Installing servicing stack update...
echo ============================================================
)
%_dism2%:"!cab_dir!" %dismtarget% /Add-Package %sha2ss%
)
if defined sha2cs (
if %verb%==1 (
echo.
echo ============================================================
echo Installing SHA2 support update...
echo ============================================================
)
%_dism2%:"!cab_dir!" %dismtarget% /Add-Package %sha2cs%
if %online%==1 goto :eof
)
if defined servicingstack (
if %verb%==1 (
echo.
echo ============================================================
echo Installing extended servicing stack update...
echo ============================================================
)
%_dism2%:"!cab_dir!" %dismtarget% /Add-Package %servicingstack%
if not defined eupdates if not defined ldr if not defined cumulative call :cleanmanual
)
if not defined eupdates if not defined ldr if not defined cumulative goto :eof
if %verb%==1 (
echo.
echo ============================================================
echo Installing updates...
echo ============================================================
)
if defined ldr %_dism2%:"!cab_dir!" %dismtarget% /Add-Package %ldr%
if defined eupdates for %%# in (%eupdates%) do (set "dest=%%~n#"&call :pXML)
if defined eupdates call :KillEOS %_Nul3%
if defined cumulative for %%# in (%cumulative%) do (set "dest=%%~n#"&call :pXML)
if defined cumulative call :diagtrack %_Nul3%
if defined eupdates if not defined cumulative call :diagtrack %_Nul3%
if %IEembed%==1 call :iembedded %_Nul3%
call :cleanmanual
goto :eof

:procmum
if %listc% geq %ac% (set /a AC+=100&set /a list+=1&set "ldr%list%=%ldr%"&set "ldr=")
set /a listc+=1
:: for /f "tokens=2 delims=-" %%V in ('echo "!package!"') do set kb=%%V
set kb=
set tn=2
:startmumLoop
for /f "tokens=%tn% delims=-" %%A in ('echo !package!') do (
  if not errorlevel 1 (
    echo %%A|findstr /i /b KB %_Nul1% && (set kb=%%A&goto :endmumLoop)
    set /a tn+=1
    goto :startmumLoop
  ) else (
    goto :endmumLoop
  )
)
:endmumLoop
if "%kb%"=="" (set /a _sum-=1&goto :eof)
if not exist "%dest%\update.mum" (set /a _sum-=1&goto :eof)
for %%# in (
Package_for_%kb%~
Package_for_RollupFix
) do if exist "!mumtarget!\Windows\servicing\packages\%%#*.mum" (
set "mumcheck=!mumtarget!\Windows\servicing\packages\%%#*.mum"
set "pkgcheck=%%#"
call :mumversion !pkgcheck:~0,14!
if !skip!==1 (set /a _sum-=1&goto :eof)
)
if /i %kb%==KB4490628 (
set "sha2ss=/packagepath:%dest%\update.mum"
goto :eof
)
if /i %kb%==KB4474419 (
set "sha2cs=/packagepath:%dest%\update.mum"
goto :eof
)
if exist "%dest%\*_microsoft-windows-servicingstack_*.manifest" if not exist "%dest%\*_microsoft-windows-s..edsecurityupdatesai*.manifest" (
set "servicingstack=!servicingstack! /packagepath:%dest%\update.mum"
goto :eof
)
if exist "!mumtarget!\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" (
findstr /i /m "WinPE" "%dest%\update.mum" %_Nul3% || (findstr /i /m "Package_for_RollupFix" "%dest%\update.mum" %_Nul3% || (set /a _sum-=1&goto :eof))
findstr /i /m "VistaPlus" "%dest%\update.mum" %_Nul3% && (findstr /i /m "Package_for_RollupFix" "%dest%\update.mum" %_Nul3% || (set /a _sum-=1&goto :eof))
)
if exist "%dest%\*_microsoft-windows-ie-versioninfo*11.2.*.manifest" if not exist "%dest%\*_microsoft-windows-rollup-version*.manifest" (
if not exist "!mumtarget!\Windows\servicing\Packages\*InternetExplorer*11.2.*.mum" (set /a _sum-=1&goto :eof)
if exist "!mumtarget!\Windows\servicing\Packages\*InternetExplorer*11.2.*.mum" if exist "!mountdir!\Windows\servicing\packages\Microsoft-Windows-EmbeddedCore-Package*amd64*.mum" set IEembed=1
)
findstr /i /m "Package_for_RollupFix" "%dest%\update.mum" %_Nul3% && (
if exist "!mumtarget!\Windows\servicing\Packages\*InternetExplorer*11.2.*.mum" if exist "!mountdir!\Windows\servicing\packages\Microsoft-Windows-EmbeddedCore-Package*amd64*.mum" set IEembed=1
set "cumulative=!cumulative! !package!"
goto :eof
)
if exist "%dest%\*_microsoft-windows-s..edsecurityupdatesai*.manifest" (
set "eupdates=!eupdates! !package!"
goto :eof
)
set "ldr=!ldr! /packagepath:%dest%\update.mum"
goto :eof

:mumversion
set skip=0
findstr /i /m "%kb%" "!mumcheck!" %_Nul1% || goto :eof
for %%# in (inver_aa inver_bl inver_mj inver_mn kbver_aa kbver_bl kbver_mj kbver_mn) do set %%#=0
for /f %%I in ('dir /b /od "!mumcheck!"') do set _pkg=%%~nI
for /f "tokens=4-7 delims=~." %%H in ('echo %_pkg%') do set "inver_aa=%%H"&set "inver_bl=%%I"&set "inver_mj=%%J"&set "inver_mn=%%K"
mkdir "!Cab_Dir!\check"
if /i "%package:~-4%"==".msu" (expand.exe -f:*Windows*.cab "!repo!\!package!" "!Cab_Dir!\check" %_Nul3%) else (copy /y "!repo!\!package!" "!Cab_Dir!\check" %_Nul3%)
expand.exe -f:update.mum "!Cab_Dir!\check\*.cab" "!Cab_Dir!\check" %_Null%
if not exist "!Cab_Dir!\check\*.mum" (set skip=1&rmdir /s /q "!Cab_Dir!\check\"&goto :eof)
:: self note: do not add " at the end
for /f "tokens=5-8 delims==. " %%H in ('findstr /i %1 "!Cab_Dir!\check\update.mum"') do set "kbver_aa=%%~H"&set "kbver_bl=%%I"&set "kbver_mj=%%J"&set "kbver_mn=%%K
rmdir /s /q "!Cab_Dir!\check\"
if %inver_aa% gtr %kbver_aa% set skip=1
if %inver_aa% equ %kbver_aa% if %inver_bl% gtr %kbver_bl% set skip=1
if %inver_aa% equ %kbver_aa% if %inver_bl% equ %kbver_bl% if %inver_mj% gtr %kbver_mj% set skip=1
if %inver_aa% equ %kbver_aa% if %inver_bl% equ %kbver_bl% if %inver_mj% equ %kbver_mj% if %inver_mn% geq %kbver_mn% set skip=1
if %skip%==1 if %online%==1 reg query "%_CBS%\Packages\%_pkg%" /v CurrentState %_Nul2% | find /i "0x70" %_Nul1% || set skip=0
goto :eof

:pXML
set ssureq=0.0
set ssuver=7601.17514
for /f "tokens=3,4 delims=." %%i in ('dir /b "!mumtarget!\Windows\servicing\Version"') do set "ssuver=%%i.%%j"
for /f "tokens=6,7 delims==<. %TAB%" %%i in ('findstr /i installerAssembly "%dest%\update.mum"') do set "ssureq=%%i.%%j
if %ssureq%==0.0 set ssureq=%ssuver%
if %ssuver:~0,4% lss %ssureq:~0,4% goto :E_REQSSU
if %ssuver:~0,4% equ %ssureq:~0,4% if %ssuver:~5,5% lss %ssureq:~5,5% goto :E_REQSSU
call :cXML stage
call :cXML install
echo.
echo Processing 1 of 1 - Adding %dest%
%_dism2%:"!cab_dir!" %dismtarget% /Apply-Unattend:stage.xml
if %errorlevel% neq 0 if %errorlevel% neq 3010 goto :eof
call :SbS
%_dism2%:"!cab_dir!" %dismtarget% /Apply-Unattend:install.xml
del /f /q stage.xml install.xml %_Nul3%
goto :eof

:cXML
(
echo.^<?xml version="1.0" encoding="utf-8"?^>
echo.^<unattend xmlns="urn:schemas-microsoft-com:unattend"^>
echo.    ^<servicing^>
echo.        ^<package action="%1"^>
)>%1.xml
findstr /i Package_for_RollupFix "%dest%\update.mum" %_Nul3% && (
findstr /i Package_for_RollupFix "%dest%\update.mum" >>%1.xml
) || (
findstr /i _for_KB "%dest%\update.mum" | findstr /i /v _RTM | findstr /i /v _SP >>%1.xml
)
(
if "%~1"=="stage" echo.            ^<source location="%dest%\update.mum" /^>
echo.        ^</package^>
echo.     ^</servicing^>
echo.^</unattend^>
)>>%1.xml
goto :eof

:E_REQSSU
echo.
echo ==== Error ====
echo %dest% require SSU version 6.1.%ssureq% ^(at least^)
goto :eof

:SbS
for /f "tokens=4 delims=_" %%# in ('dir /b "%dest%\%xBT%_microsoft-windows-s..edsecurityupdatesai*.manifest"') do (
set "pv_al=%%#"
)
for /f "tokens=1-4 delims=." %%G in ('echo %pv_al%') do (
set "pv_os=%%G.%%H"
set "pv_mj=%%G"&set "pv_mn=%%H"&set "pv_bl=%%I"&set "pv_dl=%%J"
)
set kv_al=
if %online%==0 reg load HKLM\%SOFTWARE% "!mumtarget!\Windows\System32\Config\SOFTWARE" %_Nul3%
if not exist "!mumtarget!\Windows\WinSxS\Manifests\%xBT%_microsoft-windows-s..edsecurityupdatesai*.manifest" goto :SkipChk
reg query "%_EsuKey%" %_Nul3% || goto :SkipChk
reg load HKLM\%COMPONENTS% "!mumtarget!\Windows\System32\Config\COMPONENTS" %_Nul3%
reg query "%_Cmp%" /f "%xBT%_microsoft-windows-s..edsecurityupdatesai_*" /k %_Nul2% | find /i "edsecurityupdatesai" %_Nul1% || goto :SkipChk
call :ChkESUver %_Nul3%
set "wv_bl=0"&set "wv_dl=0"
reg query "%_EsuKey%\%pv_os%" /ve %_Nul2% | findstr \( | findstr \. %_Nul1% || goto :SkipChk
for /f "tokens=2*" %%a in ('reg query "%_EsuKey%\%pv_os%" /ve ^| findstr \(') do set "wv_al=%%b"
for /f "tokens=1-4 delims=." %%G in ('echo %wv_al%') do (
set "wv_mj=%%G"&set "wv_mn=%%H"&set "wv_bl=%%I"&set "wv_dl=%%J"
)

:SkipChk
reg add "%_EsuKey%\%pv_os%" /f /v %pv_al% /t REG_BINARY /d 01 %_Nul3%
set skip_pv=0
if "%kv_al%"=="" (
reg add "%_EsuKey%" /f /ve /d %pv_os% %_Nul3%
reg add "%_EsuKey%\%pv_os%" /f /ve /d %pv_al% %_Nul3%
goto :EndChk
)
if %pv_mj% lss %kv_mj% (
set skip_pv=1
if %pv_bl% geq %wv_bl% if %pv_dl% geq %wv_dl% reg add "%_EsuKey%\%pv_os%" /f /ve /d %pv_al% %_Nul3%
)
if %pv_mj% equ %kv_mj% if %pv_mn% lss %kv_mn% (
set skip_pv=1
if %pv_bl% geq %wv_bl% if %pv_dl% geq %wv_dl% reg add "%_EsuKey%\%pv_os%" /f /ve /d %pv_al% %_Nul3%
)
if %pv_mj% equ %kv_mj% if %pv_mn% equ %kv_mn% if %pv_bl% lss %kv_bl% (
set skip_pv=1
)
if %pv_mj% equ %kv_mj% if %pv_mn% equ %kv_mn% if %pv_bl% equ %kv_bl% if %pv_dl% lss %kv_dl% (
set skip_pv=1
)
if %skip_pv% equ 0 (
reg add "%_EsuKey%" /f /ve /d %pv_os% %_Nul3%
reg add "%_EsuKey%\%pv_os%" /f /ve /d %pv_al% %_Nul3%
)

:EndChk
if %online%==0 (
reg unload HKLM\%SOFTWARE% %_Nul3%
reg unload HKLM\%COMPONENTS% %_Nul3%
)
goto :eof

:ChkESUver
set kv_os=
reg query "%_EsuKey%" /ve | findstr \( | findstr \. || goto :eof
for /f "tokens=2*" %%a in ('reg query "%_EsuKey%" /ve ^| findstr \(') do set "kv_os=%%b"
if "%kv_os%"=="" goto :eof
set kv_al=
reg query "%_EsuKey%\%kv_os%" /ve | findstr \( | findstr \. || goto :eof
for /f "tokens=2*" %%a in ('reg query "%_EsuKey%\%kv_os%" /ve ^| findstr \(') do set "kv_al=%%b"
if "%kv_al%"=="" goto :eof
reg query "%_Cmp%" /f "%xBT%_microsoft-windows-s..edsecurityupdatesai_%_Pkt%_%kv_al%_*" /k %_Nul2% | find /i "%kv_al%" %_Nul1% || (
set kv_al=
goto :eof
)
for /f "tokens=1-4 delims=." %%G in ('echo %kv_al%') do (
set "kv_mj=%%G"&set "kv_mn=%%H"&set "kv_bl=%%I"&set "kv_dl=%%J"
)
goto :eof

:ESUadd
set "_EsuFnd=windowsfoundation_%_Pkt%_6.1.7601.17514_615fdfe2a739474c"
if %_WinPE% equ 1 set "_EsuFnd=winpe_%_Pkt%_6.1.7601.17514_b103c6caf44fb2e9"
if %_Embed% equ 1 set "_EsuFnd=windowsembe..dfoundation_%_Pkt%_6.1.7601.17514_b791db78a3ca92ca"
if %_SrvrC% equ 1 set "_EsuFnd=windowsserverfoundation_%_Pkt%_6.1.7601.17514_1767904420c89fad"
if /i "%xBT%"=="x86" (
set "_EsuFnd=windowsfoundation_%_Pkt%_6.1.7601.17514_0541445eeedbd616"
if %_WinPE% equ 1 set "_EsuFnd=winpe_%_Pkt%_6.1.7601.17514_54e52b473bf241b3"
if %_Embed% equ 1 set "_EsuFnd=windowsembe..dfoundation_%_Pkt%_6.1.7601.17514_5b733ff4eb6d2194"
)
if not exist "!Cab_Dir!\%_EsuCom%.manifest" (
(echo ^<?xml version="1.0" encoding="UTF-8"?^>
echo ^<assembly xmlns="urn:schemas-microsoft-com:asm.v3" manifestVersion="1.0" copyright="Copyright (c) Microsoft Corporation. All Rights Reserved."^>
echo   ^<assemblyIdentity name="Microsoft-Windows-SLC-Component-ExtendedSecurityUpdatesAI" version="%_OurVer%" processorArchitecture="%xBT%" language="neutral" buildType="release" publicKeyToken="%_Pkt%" versionScope="nonSxS" /^>
echo ^</assembly^>)>"!Cab_Dir!\%_EsuCom%.manifest"
)
icacls "!mumtarget!\Windows\WinSxS\Manifests" /save "!Cab_Dir!\acl.txt"
takeown /f "!mumtarget!\Windows\WinSxS\Manifests" /A
icacls "!mumtarget!\Windows\WinSxS\Manifests" /grant:r "*S-1-5-32-544:(OI)(CI)(F)"
copy /y "!Cab_Dir!\%_EsuCom%.manifest" "!mumtarget!\Windows\WinSxS\Manifests\"
icacls "!mumtarget!\Windows\WinSxS\Manifests" /setowner *S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464
icacls "!mumtarget!\Windows\WinSxS" /restore "!Cab_Dir!\acl.txt"
del /f /q "!Cab_Dir!\acl.txt"

if %online%==0 reg load HKLM\%SOFTWARE% "!mumtarget!\Windows\System32\Config\SOFTWARE"
reg query HKLM\%COMPONENTS% 1>nul 2>nul || reg load HKLM\%COMPONENTS% "!mumtarget!\Windows\System32\Config\COMPONENTS"
reg delete "%_Cmp%\%_EsuCom%" /f
reg add "%_Cmp%\%_EsuCom%" /f /v "c^!%_EsuFnd%" /t REG_BINARY /d ""
reg add "%_Cmp%\%_EsuCom%" /f /v identity /t REG_BINARY /d "%_EsuIdn%"
reg add "%_Cmp%\%_EsuCom%" /f /v S256H /t REG_BINARY /d "%_EsuHsh%"
reg add "%_EsuKey%" /f /ve /d %_OurVer:~0,3%
reg add "%_EsuKey%\%_OurVer:~0,3%" /f /ve /d %_OurVer%
reg add "%_EsuKey%\%_OurVer:~0,3%" /f /v %_OurVer% /t REG_BINARY /d 01
for /f "tokens=* delims=" %%# in ('reg query HKLM\%COMPONENTS%\DerivedData\VersionedIndex 2^>nul ^| findstr /i VersionedIndex') do reg delete "%%#" /f
if %online%==0 (
reg unload HKLM\%COMPONENTS%
reg unload HKLM\%SOFTWARE%
)
exit /b

:counter
set _msu=0
set _cab=0
set _sum=0
cd /d "!repo!"
if exist "*Windows6.1*%arch%*.msu" (
for /f "tokens=* delims=" %%# in ('dir /b /a:-d "*Windows6.1*%arch%*.msu"') do (
  call set /a _msu+=1
  set "_name=%%#"
  if not "!_name!"=="!_name: =!" ren "!_name!" "!_name: =!" %_Nul3%
  if /i "!_name:~0,18!"=="AMD64_X86_ARM-all-" ren "!_name!" "!_name:~18!" %_Nul3%
  if /i "!_name:~0,14!"=="AMD64_X86-all-" ren "!_name!" "!_name:~14!" %_Nul3%
  if /i "!_name:~0,10!"=="AMD64-all-" ren "!_name!" "!_name:~10!" %_Nul3%
  if /i "!_name:~0,8!"=="X86-all-" ren "!_name!" "!_name:~8!" %_Nul3%
  )
)
if exist "*Windows6.1*%arch%*.cab" (
for /f "tokens=* delims=" %%# in ('dir /b /a:-d "*Windows6.1*%arch%*.cab"') do (
  call set /a _cab+=1
  set "_name=%%#"
  if not "!_name!"=="!_name: =!" ren "!_name!" "!_name: =!" %_Nul3%
  if /i "!_name:~0,18!"=="AMD64_X86_ARM-all-" ren "!_name!" "!_name:~18!" %_Nul3%
  if /i "!_name:~0,14!"=="AMD64_X86-all-" ren "!_name!" "!_name:~14!" %_Nul3%
  if /i "!_name:~0,10!"=="AMD64-all-" ren "!_name!" "!_name:~10!" %_Nul3%
  if /i "!_name:~0,8!"=="X86-all-" ren "!_name!" "!_name:~8!" %_Nul3%
  )
)
cd /d "!_work!"
set /a _sum=%_msu%+%_cab%
goto :eof

:cleaner
cd /d "!_work!"
if exist "!cab_dir!\" (
echo.
echo ============================================================
echo Removing temporary extracted files...
echo ============================================================
echo.
rmdir /s /q "!cab_dir!\" %_Nul1%
)
if defined msucab (
  for %%# in (%msucab%) do (del /f /q "!repo!\*%%~#*%arch%*.cab" %_Nul3%)
  set msucab=
)
goto :eof

:iembedded
if %online%==1 (
set ksub1=SOFTWARE
) else (
set ksub1=OFFSOFT
reg.exe load HKLM\!ksub1! "!mountdir!\Windows\System32\config\SOFTWARE"
)
reg.exe delete "HKLM\%ksub1%\Wow6432Node\Microsoft\Active Setup\Installed Components\{89820200-ECBD-11cf-8B85-00AA005B4383}" /f
reg.exe add "HKLM\%ksub1%\Wow6432Node\Microsoft\Active Setup\Installed Components\{89820200-ECBD-11cf-8B85-00AA005B4383}" /f /v IsInstalled /t REG_DWORD /d 0
if %online%==0 (
reg.exe unload HKLM\%ksub1%
)
goto :eof

:KillEOS
if exist "!mountdir!\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" goto :eof
if %online%==0 reg load HKLM\%SOFTWARE% "!mumtarget!\Windows\System32\Config\SOFTWARE"
reg add HKLM\%SOFTWARE%\Microsoft\Windows\CurrentVersion\EOSNotify /f /v DiscontinueEOS /t REG_DWORD /d 1
reg add HKLM\%SOFTWARE%\Microsoft\Windows\CurrentVersion\EOSNotify /f /v DontRemindMe /t REG_DWORD /d 1
reg add HKLM\%SOFTWARE%\Microsoft\Windows\CurrentVersion\EOSNotify /f /v RemindMeAfterEndOfSupport /t REG_DWORD /d 1
reg add HKLM\%SOFTWARE%\Microsoft\Windows\CurrentVersion\EOSNotify /f /v TimestampOverride /t REG_DWORD /d 1
reg add HKLM\%SOFTWARE%\Microsoft\Windows\CurrentVersion\EOSNotify /f /v LastRunTimestamp /t REG_QWORD /d 0x0
reg add HKLM\%SOFTWARE%\Microsoft\Windows\CurrentVersion\SipNotify /f /v DontRemindMe /t REG_DWORD /d 1
reg add HKLM\%SOFTWARE%\Microsoft\Windows\CurrentVersion\SipNotify /f /v DateModified /t REG_QWORD /d 0x0
reg add HKLM\%SOFTWARE%\Microsoft\Windows\CurrentVersion\SipNotify /f /v LastShown /t REG_QWORD /d 0x0
if %online%==0 reg unload HKLM\%SOFTWARE%
goto :eof

:diagtrack
if %online%==1 (
set ksub1=SOFTWARE&set ksub2=SYSTEM
) else (
set ksub1=OFFSOFT&set ksub2=OFFSYST
reg.exe load HKLM\!ksub1! "!mountdir!\Windows\System32\config\SOFTWARE"
reg.exe load HKLM\!ksub2! "!mountdir!\Windows\System32\config\SYSTEM"
)
reg.exe add HKLM\%ksub1%\Policies\Microsoft\Windows\Gwx /v DisableGwx /t REG_DWORD /d 1 /f
reg.exe add HKLM\%ksub1%\Policies\Microsoft\Windows\WindowsUpdate /v DisableOSUpgrade /t REG_DWORD /d 1 /f
reg.exe delete HKLM\%ksub1%\Microsoft\Windows\CurrentVersion\WindowsUpdate\OSUpgrade /f
reg.exe add HKLM\%ksub1%\Microsoft\Windows\CurrentVersion\WindowsUpdate\OSUpgrade /v AllowOSUpgrade /t REG_DWORD /d 0 /f
reg.exe delete HKLM\%ksub1%\Policies\Microsoft\Windows\DataCollection /f
reg.exe delete HKLM\%ksub1%\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack /f
reg.exe add HKLM\%ksub1%\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack /v DiagTrackAuthorization /t REG_DWORD /d 0 /f
reg.exe add HKLM\%ksub1%\Microsoft\SQMClient\IE /v CEIPEnable /t REG_DWORD /d 0 /f
reg.exe add HKLM\%ksub1%\Microsoft\SQMClient\IE /v SqmLoggerRunning /t REG_DWORD /d 0 /f
reg.exe add HKLM\%ksub1%\Microsoft\SQMClient\Reliability /v CEIPEnable /t REG_DWORD /d 0 /f
reg.exe add HKLM\%ksub1%\Microsoft\SQMClient\Reliability /v SqmLoggerRunning /t REG_DWORD /d 0 /f
reg.exe add HKLM\%ksub1%\Microsoft\SQMClient\Windows /v CEIPEnable /t REG_DWORD /d 0 /f
reg.exe add HKLM\%ksub1%\Microsoft\SQMClient\Windows /v SqmLoggerRunning /t REG_DWORD /d 0 /f
reg.exe add HKLM\%ksub1%\Microsoft\SQMClient\Windows /v DisableOptinExperience /t REG_DWORD /d 1 /f
reg.exe add HKLM\%ksub2%\ControlSet001\Services\DiagTrack /v Start /t REG_DWORD /d 4 /f
reg.exe delete HKLM\%ksub2%\ControlSet001\Control\WMI\AutoLogger\AutoLogger-Diagtrack-Listener /f
reg.exe delete HKLM\%ksub2%\ControlSet001\Control\WMI\AutoLogger\Diagtrack-Listener /f
rem reg.exe delete HKLM\%ksub2%\ControlSet001\Control\WMI\AutoLogger\SQMLogger /f
icacls "!mountdir!\ProgramData\Microsoft\Diagnosis" /grant:r *S-1-5-32-544:(OI)(CI)(IO)(F) /T /C
del /f /q "!mountdir!\ProgramData\Microsoft\Diagnosis\*.rbs"
del /f /q /s "!mountdir!\ProgramData\Microsoft\Diagnosis\ETLLogs\*"
if %online%==0 (
reg.exe unload HKLM\%ksub1%
reg.exe unload HKLM\%ksub2%
)

if exist "!mountdir!\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" goto :eof
if exist "!mountdir!\Users\Public\Desktop\RunOnce_W10_Telemetry_Tasks.cmd" goto :eof

if %online%==1 (
schtasks /query /tn "\Microsoft\Windows\Application Experience\ProgramDataUpdater" || goto :eof
)
if %online%==1 (
set ksub1=SOFTWARE&set ksub2=SYSTEM
) else (
set ksub1=OFFSOFT&set ksub2=OFFSYST
reg.exe load HKLM\!ksub1! "!mountdir!\Windows\System32\config\SOFTWARE"
)
reg.exe delete "HKLM\%ksub1%\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Appraiser" /f
reg.exe add "HKLM\%ksub1%\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Appraiser" /v HaveUploadedForTarget /t REG_DWORD /d 1 /f
reg.exe add "HKLM\%ksub1%\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\AIT" /v AITEnable /t REG_DWORD /d 0 /f
reg.exe delete "HKLM\%ksub1%\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\ClientTelemetry" /f
reg.exe add "HKLM\%ksub1%\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\ClientTelemetry" /v DontRetryOnError /t REG_DWORD /d 1 /f
reg.exe add "HKLM\%ksub1%\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\ClientTelemetry" /v IsCensusDisabled /t REG_DWORD /d 1 /f
reg.exe add "HKLM\%ksub1%\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\ClientTelemetry" /v TaskEnableRun /t REG_DWORD /d 1 /f
for %%i in (InstallInfoCheck,ARPInfoCheck,MediaInfoCheck,FileInfoCheck) do reg add "HKLM\%ksub1%\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Compatibility Assistant\Tracing" /v %%i /t REG_DWORD /d 0 /f
reg.exe delete "HKLM\%ksub1%\Microsoft\Windows NT\CurrentVersion\AppCompatFlags" /v UpgradeEligible /f
reg.exe delete "HKLM\%ksub1%\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\TelemetryController" /f
reg.exe delete HKLM\%ksub1%\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack /f
reg.exe add HKLM\%ksub1%\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack /v DiagTrackAuthorization /t REG_DWORD /d 0 /f
reg.exe add HKLM\%ksub1%\Microsoft\Windows\CurrentVersion\EOSNotify /f /v DiscontinueEOS /t REG_DWORD /d 1

set "T_USR=HKCU\Software\Microsoft\Windows\CurrentVersion"
set "T_US2=HKLM\OFFUSR\Software\Microsoft\Windows\CurrentVersion"
set "T_Win=Microsoft\Windows"
set "T_App=Microsoft\Windows\Application Experience"
set "T_CEIP=Microsoft\Windows\Customer Experience Improvement Program"
(
echo @echo off
echo reg.exe query "HKU\S-1-5-19" 1^>nul 2^>nul ^|^| ^(echo Run the script as administrator^&pause^&exit^)
echo reg.exe add %T_USR%\EOSNotify /f /v DiscontinueEOS /t REG_DWORD /d 1
echo reg.exe add %T_USR%\EOSNotify /f /v DontRemindMe /t REG_DWORD /d 1
echo reg.exe add %T_USR%\EOSNotify /f /v RemindMeAfterEndOfSupport /t REG_DWORD /d 1
echo reg.exe add %T_USR%\EOSNotify /f /v TimestampOverride /t REG_DWORD /d 1
echo reg.exe add %T_USR%\EOSNotify /f /v LastRunTimestamp /t REG_QWORD /d 0x0
echo reg.exe add %T_USR%\SipNotify /f /v DontRemindMe /t REG_DWORD /d 1
echo reg.exe add %T_USR%\SipNotify /f /v DateModified /t REG_QWORD /d 0x0
echo reg.exe add %T_USR%\SipNotify /f /v LastShown /t REG_QWORD /d 0x0
echo reg.exe delete HKLM\SYSTEM\CurrentControlSet\Control\WMI\AutoLogger\AutoLogger-Diagtrack-Listener /f
echo reg.exe delete HKLM\SYSTEM\CurrentControlSet\Control\WMI\AutoLogger\Diagtrack-Listener /f
echo rem reg.exe delete HKLM\SYSTEM\CurrentControlSet\Control\WMI\AutoLogger\SQMLogger /f
echo icacls "%%ProgramData%%\Microsoft\Diagnosis" /grant:r *S-1-5-32-544:^(OI^)^(CI^)^(IO^)^(F^) /T /C
echo del /f /q "%%ProgramData%%\Microsoft\Diagnosis\*.rbs"
echo del /f /q /s "%%ProgramData%%\Microsoft\Diagnosis\ETLLogs\*"
echo sc.exe config DiagTrack start= disabled
echo sc.exe stop DiagTrack
echo schtasks.exe /Change /DISABLE /TN "%T_Win%\Setup\EOSNotify"
echo schtasks.exe /Change /DISABLE /TN "%T_Win%\Setup\EOSNotify2"
echo schtasks.exe /Change /DISABLE /TN "%T_Win%\End Of Support\Notify1"
echo schtasks.exe /Change /DISABLE /TN "%T_Win%\End Of Support\Notify2"
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
echo schtasks.exe /Delete /TN "%T_Win%\Setup\EOSNotify" /F
echo schtasks.exe /Delete /TN "%T_Win%\Setup\EOSNotify2" /F
echo schtasks.exe /Delete /TN "%T_Win%\End Of Support\Notify1" /F
echo schtasks.exe /Delete /TN "%T_Win%\End Of Support\Notify2" /F
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
echo ^(goto^) 2^>nul ^&del /f /q %%0 ^&exit /b
)>"W10Tel.cmd"

if %online%==1 (
if exist "%SystemRoot%\winsxs\pending.xml" (move /y "W10Tel.cmd" "%PUBLIC%\Desktop\RunOnce_W10_Telemetry_Tasks.cmd") else (cmd.exe /c "W10Tel.cmd")
) else (
move /y "W10Tel.cmd" "!mountdir!\Users\Public\Desktop\RunOnce_W10_Telemetry_Tasks.cmd"
reg.exe unload HKLM\%ksub1%
)

if %online%==1 (
reg.exe add %T_USR%\EOSNotify /f /v DiscontinueEOS /t REG_DWORD /d 1
reg.exe add %T_USR%\EOSNotify /f /v DontRemindMe /t REG_DWORD /d 1
reg.exe add %T_USR%\EOSNotify /f /v RemindMeAfterEndOfSupport /t REG_DWORD /d 1
reg.exe add %T_USR%\EOSNotify /f /v TimestampOverride /t REG_DWORD /d 1
reg.exe add %T_USR%\EOSNotify /f /v LastRunTimestamp /t REG_QWORD /d 0x0
reg.exe add %T_USR%\SipNotify /f /v DontRemindMe /t REG_DWORD /d 1
reg.exe add %T_USR%\SipNotify /f /v DateModified /t REG_QWORD /d 0x0
reg.exe add %T_USR%\SipNotify /f /v LastShown /t REG_QWORD /d 0x0
) else (
reg.exe load HKLM\OFFUSR "!mountdir!\Users\Default\ntuser.dat"
reg.exe add %T_US2%\EOSNotify /f /v DiscontinueEOS /t REG_DWORD /d 1
reg.exe add %T_US2%\EOSNotify /f /v DontRemindMe /t REG_DWORD /d 1
reg.exe add %T_US2%\EOSNotify /f /v RemindMeAfterEndOfSupport /t REG_DWORD /d 1
reg.exe add %T_US2%\EOSNotify /f /v TimestampOverride /t REG_DWORD /d 1
reg.exe add %T_US2%\EOSNotify /f /v LastRunTimestamp /t REG_QWORD /d 0x0
reg.exe add %T_US2%\SipNotify /f /v DontRemindMe /t REG_DWORD /d 1
reg.exe add %T_US2%\SipNotify /f /v DateModified /t REG_QWORD /d 0x0
reg.exe add %T_US2%\SipNotify /f /v LastShown /t REG_QWORD /d 0x0
reg.exe unload HKLM\OFFUSR
)
goto :eof

:mount
set "_wimfile=%~1"
if %wim%==1 set "_wimpath=!targetpath!"
if %dvd%==1 set "_wimpath=!target!"
if exist "!mountdir!\" rmdir /s /q "!mountdir!\" %_Nul1%
if not exist "!mountdir!\" mkdir "!mountdir!"
for %%# in (%indices%) do (
echo.
echo ============================================================
echo Mounting %_wimfile% - index %%#/%imgcount%
echo ============================================================
cd /d "!_wimpath!"
%_dism2%:"!cab_dir!" /Mount-Wim /Wimfile:%_wimfile% /Index:%%# /MountDir:"!mountdir!"
if !errorlevel! neq 0 goto :E_MOUNT
cd /d "!cab_dir!"
call :doupdate
if %dvd%==1 if exist "!mountdir!\sources\setup.exe" call :boots
if %dvd%==1 if not defined isover (
  if exist "!mountdir!\Windows\WinSxS\Manifests\%sss%_microsoft-windows-rollup-version*.manifest" for /f "tokens=6,7 delims=_." %%i in ('dir /b /a:-d /od "!mountdir!\Windows\WinSxS\Manifests\%sss%_microsoft-windows-rollup-version*.manifest"') do set isover=%%i.%%j
)
if %wim%==1 if exist "!_wimpath!\setup.exe" (
  if exist "!mountdir!\sources\setup.exe" copy /y "!mountdir!\sources\setup.exe" "!_wimpath!" %_Nul3%
)
if exist "!mountdir!\Windows\System32\Recovery\winre.wim" (
attrib -S -H -I "!mountdir!\Windows\System32\Recovery\winre.wim" %_Nul3%
if %%#==1 for /f "tokens=3 delims=: " %%# in ('dism.exe /english /get-wiminfo /wimfile:"!mountdir!\Windows\System32\Recovery\winre.wim" /index:1 ^| findstr /i /c:"ServicePack Build"') do if %%# lss 24384 call set winre=0
)
if %WinRE%==1 if exist "!mountdir!\Windows\System32\Recovery\winre.wim" if not exist "!_work!\winre.wim" call :winre
if exist "!mountdir!\Windows\System32\Recovery\winre.wim" if exist "!_work!\winre.wim" (
echo.
echo ============================================================
echo Adding updated winre.wim
echo ============================================================
echo.
copy /y "!_work!\winre.wim" "!mountdir!\Windows\System32\Recovery\"
)
echo.
echo ============================================================
echo Unmounting %_wimfile% - index %%#/%imgcount%
echo ============================================================
if !discard!==1 (
%_dism2%:"!cab_dir!" /Unmount-Wim /MountDir:"!mountdir!" /Discard
) else (
%_dism2%:"!cab_dir!" /Unmount-Wim /MountDir:"!mountdir!" /Commit
)
if !errorlevel! neq 0 goto :E_MOUNT
)
cd /d "!cab_dir!"
if %winbuild% lss 9600 if %_ADK% equ 0 if /i "!DismRoot!"=="dism.exe" if not exist "!_imagex!" goto :eof
if /i "%_wimfile%"=="sources\boot.wim" (call :pebuild) else (call :rebuild)
cd /d "!cab_dir!"
goto :eof

:boots
xcopy /CDRY "!mountdir!\sources" "!target!\sources\" %_Nul3%
del /f /q "!target!\sources\background.bmp" %_Nul3%
del /f /q "!target!\sources\testplugin.dll" %_Nul3%
copy /y "!mountdir!\Windows\Boot\PCAT\bootmgr" "!target!\" %_Nul1%
copy /y "!mountdir!\Windows\Boot\PCAT\memtest.exe" "!target!\boot\" %_Nul1%
if exist "!target!\setup.exe" copy /y "!mountdir!\setup.exe" "!target!\" %_Nul3%
goto :eof

:winre
if !WinRE!==0 goto :eof
  echo.
  echo ============================================================
  echo Updating winre.wim
  echo ============================================================
  if exist "!winremount!\" rmdir /s /q "!winremount!\" %_Nul1%
  if not exist "!winremount!\" mkdir "!winremount!"
  copy /y "!mountdir!\Windows\System32\Recovery\winre.wim" "!_work!\winre.wim" %_Nul1%
  cd /d "!_work!"
  %_dism2%:"!cab_dir!" /Mount-Wim /Wimfile:winre.wim /Index:1 /MountDir:"!winremount!"
  if %errorlevel% neq 0 goto :E_MOUNT
  cd /d "!cab_dir!"
  call :doupdate winre
  if !discardre!==1 (
  %_dism2%:"!cab_dir!" /Unmount-Wim /MountDir:"!winremount!" /Discard
  if !errorlevel! neq 0 goto :E_MOUNT
  goto :eof
  )
  %_dism2%:"!cab_dir!" /Unmount-Wim /MountDir:"!winremount!" /Commit
  if !errorlevel! neq 0 goto :E_MOUNT
  cd /d "!_work!"
  set "mumtarget=!mumtargeb!"
  set dismtarget=/image:"!mountdir!"
  if %winbuild% lss 9600 if %_ADK% equ 0 if /i "!DismRoot!"=="dism.exe" if not exist "!_imagex!" goto :eof
  call :pebuild winre
  set "_wimfile=!_wimfilb!"
  set "_wimpath=!_wimpatb!"
goto :eof

:pebuild
set verb=1
if not "%1"=="" (
set verb=0
set "_wimfilb=!_wimfile!"
set "_wimfile=winre.wim"
set "_wimpatb=!_wimpath!"
set "_wimpath=!_work!"
)
if %verb%==1 (
echo.
echo ============================================================
echo Rebuilding %_wimfile%
echo ============================================================
)
cd /d "!_wimpath!"
if %winbuild% geq 9600 (
%_dism2%:"!cab_dir!" /Export-Image /SourceImageFile:%_wimfile% /All /DestinationImageFile:temp.wim
if !errorlevel! equ 0 (move /y temp.wim %_wimfile% %_Nul1%) else (del /f /q temp.wim %_Nul3%)
goto :eof
)
if not exist "!_imagex!" goto :eof
"!_imagex!" /TEMP "!cab_dir!" /EXPORT %_wimfile% * temp.wim
if !errorlevel! equ 0 (move /y temp.wim %_wimfile% %_Nul1%) else (del /f /q temp.wim %_Nul3%)
goto :eof

:rebuild
set verb=1
if %verb%==1 (
echo.
echo ============================================================
echo Rebuilding %_wimfile%
echo ============================================================
)
cd /d "!_wimpath!"
if %winbuild% geq 9600 (
if %keep%==1 (
for %%# in (%indices%) do %_dism2%:"!cab_dir!" /Export-Image /SourceImageFile:%_wimfile% /SourceIndex:%%# /DestinationImageFile:temp.wim
) else (
%_dism2%:"!cab_dir!" /Export-Image /SourceImageFile:%_wimfile% /All /DestinationImageFile:temp.wim
)
if !errorlevel! equ 0 (move /y temp.wim %_wimfile% %_Nul1%) else (del /f /q temp.wim %_Nul3%)
goto :eof
)
if not exist "!_imagex!" goto :eof
if %keep%==1 (
for %%# in (%indices%) do "!_imagex!" /TEMP "!cab_dir!" /EXPORT %_wimfile% %%# temp.wim
) else (
"!_imagex!" /TEMP "!cab_dir!" /EXPORT %_wimfile% * temp.wim
)
if !errorlevel! equ 0 (move /y temp.wim %_wimfile% %_Nul1%) else (del /f /q temp.wim %_Nul3%)
goto :eof

:cleanmanual
if %online%==1 goto :eof
if exist "!mumtarget!\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" if exist "!mumtarget!\Windows\WinSxS\Backup\*" (
del /f /q "!mumtarget!\Windows\WinSxS\Backup\*" %_Nul3%
)
if exist "!mumtarget!\Windows\WinSxS\ManifestCache\*.bin" (
takeown /f "!mumtarget!\Windows\WinSxS\ManifestCache\*.bin" /A %_Nul3%
icacls "!mumtarget!\Windows\WinSxS\ManifestCache\*.bin" /grant *S-1-5-32-544:F %_Nul3%
del /f /q "!mumtarget!\Windows\WinSxS\ManifestCache\*.bin" %_Nul3%
)
if exist "!mumtarget!\Windows\WinSxS\Temp\PendingDeletes\*" (
takeown /f "!mumtarget!\Windows\WinSxS\Temp\PendingDeletes\*" /A %_Nul3%
icacls "!mumtarget!\Windows\WinSxS\Temp\PendingDeletes\*" /grant *S-1-5-32-544:F %_Nul3%
del /f /q "!mumtarget!\Windows\WinSxS\Temp\PendingDeletes\*" %_Nul3%
)
if exist "!mumtarget!\Windows\inf\*.log" (
del /f /q "!mumtarget!\Windows\inf\*.log" %_Nul3%
)
goto :eof

:E_Target
echo.
echo ============================================================
echo ERROR: %MESSAGE%
echo ============================================================
echo.
echo Press any key to continue...
%_Pause%
set "target=%SystemDrive%"
%_Goto%

:E_MOUNT
call :cleaner
dism.exe /Unmount-Wim /MountDir:"!winremount!" /Discard %_Nul3%
dism.exe /Unmount-Wim /MountDir:"!mountdir!" /Discard
dism.exe /Cleanup-Mountpoints %_Nul3%
dism.exe /Cleanup-Wim %_Nul3%
if %wimfiles%==1 (if exist "!mountdir!\" if not exist "!mountdir!\Windows\" rmdir /s /q "!mountdir!\" %_Nul3%)
if exist "!winremount!\" if not exist "!winremount!\Windows\" rmdir /s /q "!winremount!\" %_Nul3%
if exist "!cab_dir!\" (
echo.
echo ============================================================
echo Removing temporary extracted files...
echo ============================================================
rmdir /s /q "!cab_dir!\" %_Nul1%
)
echo.
echo ============================================================
echo ERROR: Could not mount or unmount WIM image
echo ============================================================
echo.
echo Press 9 to exit.
if %_Debug% neq 0 goto :EndDebug
choice /c 9 /n
if errorlevel 1 (exit) else (rem.)

:E_ESU
if %wimfiles%==1 (if exist "!mountdir!\" if not exist "!mountdir!\Windows\" rmdir /s /q "!mountdir!\" %_Nul3%)
if exist "!winremount!\" if not exist "!winremount!\Windows\" rmdir /s /q "!winremount!\" %_Nul3%
if exist "!cab_dir!\" (
echo.
echo ============================================================
echo Removing temporary extracted files...
echo ============================================================
rmdir /s /q "!cab_dir!\" %_Nul1%
)
@cls
echo ==== ATTENTION ====
echo.
echo ESU updates require SHA2 support updates KB4490628 and KB4474419.
if %online%==1 (
echo install them first and restart the system, then run the script again.
) else (
echo integrate them first, then run the script again.
)
echo.
echo Press 9 to exit.
if %_Debug% neq 0 goto :EndDebug
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
set regKeyPathFound=1
set wowRegKeyPathFound=1
reg.exe query "HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots" /v KitsRoot81 %_Nul3% || set wowRegKeyPathFound=0
reg.exe query "HKLM\Software\Microsoft\Windows Kits\Installed Roots" /v KitsRoot81 %_Nul3% || set regKeyPathFound=0
if %wowRegKeyPathFound% equ 0 (
  if %regKeyPathFound% equ 0 (
    goto :check10adk
  ) else (
    set regKeyPath=HKLM\Software\Microsoft\Windows Kits\Installed Roots
  )
) else (
    set regKeyPath=HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots
)
for /f "skip=2 tokens=2*" %%i in ('reg.exe query "%regKeyPath%" /v KitsRoot81') do set "KitsRoot=%%j"
set "DandIRoot=%KitsRoot%Assessment and Deployment Kit\Deployment Tools"
if exist "%DandIRoot%\%xOS%\DISM\dism.exe" (
set _ADK=1
set "ShowDism=Windows 8.1 ADK"
set "Path=%DandIRoot%\%xOS%\DISM;%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
)
if exist "%DandIRoot%\%xOS%\Oscdimg\oscdimg.exe" (
set "_oscdimg=%DandIRoot%\%xOS%\Oscdimg\oscdimg.exe"
)
if exist "%DandIRoot%\%xOS%\DISM\imagex.exe" (
set "_imagex=%DandIRoot%\%xOS%\DISM\imagex.exe"
)
goto :mainmenu

:check10adk
set regKeyPathFound=1
set wowRegKeyPathFound=1
reg.exe query "HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 %_Nul3% || set wowRegKeyPathFound=0
reg.exe query "HKLM\Software\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 %_Nul3% || set regKeyPathFound=0
if %wowRegKeyPathFound% equ 0 (
  if %regKeyPathFound% equ 0 (
    goto :mainmenu
  ) else (
    set regKeyPath=HKLM\Software\Microsoft\Windows Kits\Installed Roots
  )
) else (
    set regKeyPath=HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots
)
for /f "skip=2 tokens=2*" %%i in ('reg.exe query "%regKeyPath%" /v KitsRoot10') do set "KitsRoot=%%j"
set "DandIRoot=%KitsRoot%Assessment and Deployment Kit\Deployment Tools"
if exist "%DandIRoot%\%xOS%\DISM\dism.exe" (
set _ADK=1
set "ShowDism=Host OS / Windows 10 ADK detected"
if %winbuild% gtr 9600 set "ShowDism=Windows 10 ADK"
if %winbuild% gtr 9600 set "Path=%DandIRoot%\%xOS%\DISM;%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
)
if exist "%DandIRoot%\%xOS%\Oscdimg\oscdimg.exe" (
set "_oscdimg=%DandIRoot%\%xOS%\Oscdimg\oscdimg.exe"
)
if exist "%DandIRoot%\%xOS%\DISM\imagex.exe" (
set "_imagex=%DandIRoot%\%xOS%\DISM\imagex.exe"
)
goto :mainmenu

:targetmenu
@cls
set _pp=
echo ============================================================
echo Enter the path for one of supported targets:
echo - Distribution ^(extracted folder, mounted iso/dvd/usb drive^)
echo - WIM file ^(not mounted^)
echo - Mounted directory, offline image drive letter
if %win7% equ 1 echo - Current OS / Enter %SystemDrive%
echo.
echo or just press 'Enter' to return to options menu
echo ============================================================
echo.
set /p _pp=
if not defined _pp goto :mainmenu
set "_pp=%_pp:"=%"
if "%_pp:~-1%"=="\" set "_pp=!_pp:~0,-1!"
set "target=!_pp!"
set _init=0
goto :checktarget

:repomenu
@cls
set _pp=
echo ============================================================
echo Enter the Updates location path
echo.
echo or just press 'Enter' to return to options menu
echo ============================================================
echo.
set /p _pp=
if not defined _pp goto :mainmenu
set "_pp=%_pp:"=%"
if "%_pp:~-1%"=="\" set "_pp=!_pp:~0,-1!"
if not exist "!_pp!\*Windows6.1*.msu" if not exist "!_pp!\*Windows6.1*.cab" (echo.&echo ERROR: Specified location is not valid&pause&goto :repomenu)
set "repo=!_pp!"
goto :mainmenu

:dismmenu
@cls
set _pp=
echo ============================================================
echo Enter the full path for dism.exe
echo.
echo or just press 'Enter' to return to options menu
echo ============================================================
echo.
set /p _pp=
if not defined _pp goto :mainmenu
set "_pp=%_pp:"=%"
if not exist "!_pp!" (echo.&echo ERROR: DISM path not found&pause&goto :dismmenu)
set "DismRoot=%_pp%"
set "ShowDism=%_pp%"
set _dism2="%_pp%" /NoRestart /ScratchDir
set _ADK=1
goto :mainmenu

:extractmenu
@cls
set _pp=
echo ============================================================
echo Enter the directory path for extracting updates
echo make sure the drive has enough free space ^(at least 10 GB^)
echo.
echo or just press 'Enter' to return to options menu
echo ============================================================
echo.
set /p _pp=
if not defined _pp goto :mainmenu
set "_pp=%_pp:"=%"
set "_pp=%_pp: =%"
if "%_pp:~-1%"=="\" set "_pp=!_pp:~0,-1!"
if "%_pp:~-1%"==":" set "_pp=!_pp!\"
set "cab_dir=!_pp!_%random%"
goto :mainmenu

:mountmenu
@cls
set _pp=
echo ============================================================
echo Enter the directory path for mounting install.wim
echo make sure the drive has enough free space ^(at least 10 GB^)
echo it must be on NTFS formatted partition
echo.
echo or just press 'Enter' to return to options menu
echo ============================================================
echo.
set /p _pp=
if not defined _pp goto :mainmenu
set "_pp=%_pp:"=%"
set "_pp=%_pp: =%"
if "%_pp:~-1%"=="\" set "_pp=!_pp:~0,-1!"
if "%_pp:~-1%"==":" set "_pp=!_pp!\"
set "mountdir=!_pp!_%random%"
goto :mainmenu

:indexmenu
@cls
set _pp=
echo ============================================================
for /L %%# in (1,1,%imgcount%) do (
echo. %%#. !name%%#!
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
set /p _pp=
if not defined _pp goto :mainmenu
if "%_pp%"=="*" set "indices=%_pp%"&set keep=0&goto :mainmenu
for %%# in (%_pp%) do (
if %%# gtr %imgcount% (echo.&echo %%# is higher than available indexes&pause&goto :indexmenu)
if %%# equ 0 (echo.&echo 0 is not a valid index&pause&goto :indexmenu)
)
set "indices=%_pp%"
set keep=1
goto :mainmenu

:mainmenu
if %autostart%==1 goto :mainboard
@cls
echo ============================================================
if /i "!target!"=="%SystemDrive%" (
if %win7% neq 1 (set "target="&echo [1] Select offline target) else (echo [1] Target ^(%arch%^): Current Online OS)
) else (
if /i "!target!"=="" (echo [1] Select offline target) else (echo [1] Target ^(%arch%^): "!target!")
)
echo.
if "!repo!"=="" (echo [2] Select updates location) else (echo [2] Updates: "!repo!")
if /i not "!target!"=="%SystemDrive%" (
echo.
echo [D] DISM: "!ShowDism!"
)
if %wimfiles%==1 (
if /i "%targetname%"=="install.wim" (echo.&if %WinRE%==1 (echo [U] Update WinRE.wim: YES) else (echo [U] Update WinRE.wim: NO))
if %imgcount% gtr 1 (
echo.
if "%indices%"=="*" echo [I] Install.wim selected indexes: ALL ^(%imgcount%^)
if not "%indices%"=="*" (if %keep%==1 (echo [I] Install.wim selected indexes: %indices% / [K] Keep indexes: Selected) else (if %keep%==0 echo [I] Install.wim selected indexes: %indices% / [K] Keep indexes: ALL))
)
echo.
echo [M] Mount Directory: "!mountdir!"
)
echo.
echo [E] Extraction Directory: "!cab_dir!"
echo.
echo ============================================================
choice /c 1290DEMIKU /n /m "Change a menu option, press 0 to start the process, or 9 to exit: "
if errorlevel 10 (if %WinRE%==1 (set winre=0) else (set winre=1))&goto :mainmenu
if errorlevel 9 (if %keep%==1 (set keep=0) else (set keep=1))&goto :mainmenu
if errorlevel 8 goto :indexmenu
if errorlevel 7 goto :mountmenu
if errorlevel 6 goto :extractmenu
if errorlevel 5 goto :dismmenu
if errorlevel 4 goto :mainboard
if errorlevel 3 goto :eof
if errorlevel 2 goto :repomenu
if errorlevel 1 goto :targetmenu
goto :mainmenu

:ISO
if not exist "!_oscdimg!" if not exist "!_work!\oscdimg.exe" if not exist "!_work!\cdimage.exe" goto :eof
if "!isodir!"=="" set "isodir=!_work!"
for /f "tokens=2 delims==." %%# in ('wmic os get localdatetime /value') do set "_date=%%#"
set "isodate=%_date:~0,4%-%_date:~4,2%-%_date:~6,2%"
if defined isover (set isofile=Win7_%isover%_%arch%_%isodate%.iso) else (set isofile=Win7_%arch%_%isodate%.iso)
set /a rnd=%random%
if exist "!isodir!\%isofile%" ren "!isodir!\%isofile%" "%rnd%_%isofile%"
echo.
echo ============================================================
echo Creating updated ISO file...
echo ============================================================
if exist "!_oscdimg!" (set _ff="!_oscdimg!") else if exist "!_work!\oscdimg.exe" (set _ff="!_work!\oscdimg.exe") else (set _ff="!_work!\cdimage.exe")
cd /d "!target!"
if exist "efi\microsoft\boot\efisys.bin" (
!_ff! -m -o -u2 -udfver102 -bootdata:2#p0,e,b".\boot\etfsboot.com"#pEF,e,b".\efi\microsoft\boot\efisys.bin" -l"%isover%u" . "%isofile%"
) else (
!_ff! -m -o -u2 -udfver102 -b".\boot\etfsboot.com" -l"%isover%u" . "%isofile%"
)
set errcode=%errorlevel%
if %errcode% equ 0 move /y "%isofile%" "!isodir!\" %_Nul3%
cd /d "!_work!"
if %errcode% equ 0 if %delete_source% equ 1 rmdir /s /q "!target!\" %_Nul1%
if %errcode% equ 0 if exist "!_work!\DVD7UI\" rmdir /s /q "!_work!\DVD7UI\" %_Nul1%
goto :eof

:fin
call :cleaner
if %wimfiles%==1 if exist "!mountdir!\" rmdir /s /q "!mountdir!\" %_Nul1%
if exist "!winremount!\" rmdir /s /q "!winremount!\" %_Nul1%
if %dvd%==1 if %iso%==1 call :ISO
echo.
echo ============================================================
echo    Finished
echo ============================================================
echo.
if %online%==1 if exist "%SystemRoot%\winsxs\pending.xml" (
echo.
echo ============================================================
echo System restart is required to complete installation
echo ============================================================
echo.
)
if %_Debug% neq 0 goto :eof
echo.
echo Press 9 to exit.
choice /c 9 /n
if errorlevel 1 (goto :eof) else (rem.)

:EndDebug
cmd /u /c type "!_log!_tmp.log">"!_log!_Debug.log"
(goto) &del "!_log!_tmp.log"
exit
