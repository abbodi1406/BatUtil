@echo off

set WIMPATH=
set WINPE=1
set SLIM=1

set DEFAULTLANGUAGE=
set MOUNTDIR=

rem ##################################################################
rem # NORMALY THERE IS NO NEED TO CHANGE ANYTHING BELOW THIS COMMENT #
rem ##################################################################

%windir%\system32\reg.exe query "HKU\S-1-5-19" 1>nul 2>nul || goto :E_ADMIN
cd /d "%~dp0"
set NET35=1
set WORKDIR=%cd%
set TEMPDIR=%WORKDIR%\TEMP
if "%MOUNTDIR%"=="" set MOUNTDIR=%WORKDIR%\MOUNT
set DISMTEMPDIR=%TEMPDIR%\scratch
set EXTRACTDIR=%TEMPDIR%\extract
set INSTALLMOUNTDIR=%MOUNTDIR%\install
set WINREMOUNTDIR=%MOUNTDIR%\winre
set EAlang=(ja-jp,ko-kr,zh-cn,zh-hk,zh-tw)

set _wim=0
if exist "*.wim" (for /f "delims=" %%i in ('dir /b *.wim') do (call set /a _wim+=1))
if "%WIMPATH%"=="" (
if %_wim%==0 goto :prompt
for /f "delims=" %%i in ('dir /b *.wim') do set "WIMPATH=%%i"
)
goto :check

:prompt
echo.
echo ============================================================
echo Enter the install.wim path ^(without quotes marks ""^)
echo ============================================================
echo.
set /p WIMPATH=
if [%WIMPATH%]==[] set MESSAGE=ERROR: no source specified&goto :END
goto :check

:check
SET regKeyPathFound=1
SET wowRegKeyPathFound=1
REG QUERY "HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots" /v KitsRoot81 1>NUL 2>NUL || SET wowRegKeyPathFound=0
REG QUERY "HKLM\Software\Microsoft\Windows Kits\Installed Roots" /v KitsRoot81 1>NUL 2>NUL || SET regKeyPathFound=0
if %wowRegKeyPathFound% EQU 0 (
  if %regKeyPathFound% EQU 0 (
    goto :skip
  ) else (
    SET regKeyPath=HKLM\Software\Microsoft\Windows Kits\Installed Roots
  )
) else (
    SET regKeyPath=HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots
)
FOR /F "skip=2 tokens=2*" %%i IN ('REG QUERY "%regKeyPath%" /v KitsRoot81') DO (SET "KitsRoot=%%j")
SET "WinPERoot=%KitsRoot%Assessment and Deployment Kit\Windows Preinstallation Environment"
SET "DandIRoot=%KitsRoot%Assessment and Deployment Kit\Deployment Tools"
SET "DISMRoot=%DandIRoot%\%PROCESSOR_ARCHITECTURE%\DISM\dism.exe"
if not exist "%DISMRoot%" goto :skip
goto :prepare

:skip
set "DISMRoot=%~dp0dism\dism.exe"
%windir%\system32\reg.exe query "HKLM\System\CurrentControlSet\Control\Session Manager\Environment" /v PROCESSOR_ARCHITECTURE | find /i "amd64" 1>nul && set "DISMRoot=%~dp0dism\dism64\dism.exe"

:prepare
if not exist "%WinPERoot%\copype.cmd" set WINPE=0
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G
if %winbuild% GEQ 9600 SET DISMRoot=%windir%\system32\dism.exe
SET "_7z=%~dp0dism\7z.exe"
if not exist "%_7z%" goto :E_BIN
if not exist "%WIMPATH%" goto :E_DVD
if not exist .\dotNetFx35_W8.1_x86_x64.exe set NET35=0
setlocal EnableDelayedExpansion
echo.
echo ============================================================
echo Prepare work directories
echo ============================================================
echo.
if exist "%TEMPDIR%" (rmdir /s /q "%TEMPDIR%" 1>nul 2>nul || goto :E_DELDIR)
if exist "%MOUNTDIR%" (rmdir /s /q "%MOUNTDIR%" 1>nul 2>nul || goto :E_DELDIR)
mkdir "%TEMPDIR%" || goto :E_MKDIR
mkdir "%DISMTEMPDIR%" || goto :E_MKDIR
mkdir "%EXTRACTDIR%" || goto :E_MKDIR
mkdir "%MOUNTDIR%" || goto :E_MKDIR
mkdir "%INSTALLMOUNTDIR%" || goto :E_MKDIR
mkdir "%WINREMOUNTDIR%" || goto :E_MKDIR
goto :start

:setcount
set /a count+=1
set LPFILE%count%=%1
goto :eof

:setarch
set /a count+=1
for /f "tokens=2 delims=: " %%i in ('dism\dism.exe /english /get-wiminfo /wimfile:"%WIMPATH%" /index:%1 ^| find /i "Architecture"') do set WIMARCH%count%=%%i
goto :eof

:start
echo.
echo ============================================================
echo Detect language packs details
echo ============================================================
echo.
set _c=0
if exist ".\langs\*.cab" (for /f %%i in ('dir /b ".\langs\*.cab"') do (call set /a _c+=1))
if %_c% equ 0 goto :E_FILES
set LANGUAGES=%_c%
if %_c% neq 0 (for /f %%i in ('dir /b /o:n ".\langs\*.cab"') do call :setcount %%i)

for /L %%j in (1, 1, %LANGUAGES%) do (
"%_7z%" e ".\langs\!LPFILE%%j!" -o"%EXTRACTDIR%" langcfg.ini >nul
for /f "tokens=2 delims==" %%i in ('type "%EXTRACTDIR%\langcfg.ini" ^| findstr /i "Language"') do set LANGUAGE%%j=%%i
del /f /q "%EXTRACTDIR%\langcfg.ini"
"%_7z%" e ".\langs\!LPFILE%%j!" -o"%EXTRACTDIR%" Microsoft-Windows-CommonFoundation-LanguagePack-Package*9600*.mum 1>nul 2>nul
if not exist "%EXTRACTDIR%\*.mum" set ERRFILE=!LPFILE%%j!&goto :E_LP
for /f "tokens=3 delims=~" %%V in ('"dir "%EXTRACTDIR%\*.mum" /b" 2^>nul') do set LPARCH%%j=%%V
del /f /q "%EXTRACTDIR%\*.mum" 1>nul 2>nul
)
for /L %%j in (1, 1, %LANGUAGES%) do (
"%_7z%" e ".\langs\!LPFILE%%j!" -o"%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" RLP-GM-Package_for_KB2919355*.mum 1>nul 2>nul
if exist "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!\RLP-GM-Package_for_KB2919355*.mum" (set LPLevel%%j=S14) else (set LPLevel%%j=RTM)
)
for /L %%j in (1, 1, %LANGUAGES%) do (
if /i !LPARCH%%j!==amd64 (echo !LANGUAGE%%j!: 64-bit {x64}) else (echo !LANGUAGE%%j!: 32-bit {x86})
set "WinpeOC%%j=%WinPERoot%\!LPARCH%%j!\WinPE_OCs"
)
for /f "tokens=2 delims=: " %%i in ('dism\dism.exe /english /get-wiminfo /wimfile:"%WIMPATH%" ^| findstr "Index"') do set VERSIONS=%%i
for /f "tokens=3 delims=: " %%i in ('dism\dism.exe /english /get-wiminfo /wimfile:"%WIMPATH%" /index:1 ^| find /i "ServicePack Build"') do set svcbuild=%%i
if %svcbuild% GEQ 17031 for /L %%j in (1, 1, %LANGUAGES%) do (
if /i !LPLevel%%j! NEQ S14 set ERRFILE=!LPFILE%%j!&goto :E_RTM
)
if "%DEFAULTLANGUAGE%"=="" (
for /f "tokens=1" %%i in ('dism\dism.exe /english /get-wiminfo /wimfile:"%WIMPATH%" /index:1 ^| find /i "Default"') do set DEFAULTLANGUAGE=%%i
)
echo.
echo ============================================================
echo Detect install.wim details
echo ============================================================
echo.
set /a count=0
for /L %%i in (1, 1, %VERSIONS%) do call :setarch %%i
for /L %%i in (1, 1, %VERSIONS%) do (
if /i !WIMARCH%%i!==x64 (call set WIMARCH%%i=amd64)
)
for /L %%i in (1, 1, %VERSIONS%) do (
echo !WIMARCH%%i!>>"%TEMPDIR%\WIMARCH.txt"
)
set _label86=0
%windir%\system32\findstr.exe /i /v "amd64" "%TEMPDIR%\WIMARCH.txt" >nul
if %errorlevel%==0 (set wimbit=32&set _label86=1)

%windir%\system32\findstr.exe /i /v "x86" "%TEMPDIR%\WIMARCH.txt" >nul
if %errorlevel%==0 (
if %_label86%==1 (set wimbit=dual) else (set wimbit=64)
)
echo Count: %VERSIONS% Image^(s^)
if %wimbit%==dual (echo Arch : Multi) else (echo Arch : %wimbit%-bit)

if %WINPE% NEQ 1 goto :extract
set _PEM86=
set _PES86=
set _PEX86=
set _PEF86=
set _PEM64=
set _PES64=
set _PEX64=
set _PEF64=
echo.
echo ============================================================
echo Set WinPE language packs paths
echo ============================================================
echo.
if %wimbit%==32 for /L %%j in (1, 1, %LANGUAGES%) do (
if /i !LPARCH%%j!==x86 (
echo !LANGUAGE%%j! / 32-bit
call set _PEM86=!_PEM86! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\lp.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-SRT_!LANGUAGE%%j!.cab"
call set _PES86=!_PES86! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Setup_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Setup-Client_!LANGUAGE%%j!.cab"
call set _PEX86=!_PEX86! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-EnhancedStorage_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Scripting_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-SecureStartup_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-WDS-Tools_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-WMI_!LANGUAGE%%j!.cab"
 for /d %%G in %EAlang% do (
 if /i !LANGUAGE%%j!==%%G call set _PEF86=!_PEF86! /PackagePath:"!WinpeOC%%j!\WinPE-FontSupport-%%G.cab"
 )
)
)
if %wimbit%==64 for /L %%j in (1, 1, %LANGUAGES%) do (
if /i !LPARCH%%j!==amd64 (
echo !LANGUAGE%%j! / 64-bit
call set _PEM64=!_PEM64! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\lp.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-SRT_!LANGUAGE%%j!.cab"
call set _PES64=!_PES64! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Setup_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Setup-Client_!LANGUAGE%%j!.cab"
call set _PEX64=!_PEX64! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-EnhancedStorage_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Scripting_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-SecureStartup_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-WDS-Tools_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-WMI_!LANGUAGE%%j!.cab"
 for /d %%G in %EAlang% do (
 if /i !LANGUAGE%%j!==%%G call set _PEF64=!_PEF64! /PackagePath:"!WinpeOC%%j!\WinPE-FontSupport-%%G.cab"
 )
)
)
if %wimbit%==dual for /L %%j in (1, 1, %LANGUAGES%) do (
if /i !LPARCH%%j!==x86 (
echo !LANGUAGE%%j! / 32-bit
call set _PEM86=!_PEM86! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\lp.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-SRT_!LANGUAGE%%j!.cab"
call set _PES86=!_PES86! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Setup_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Setup-Client_!LANGUAGE%%j!.cab"
call set _PEX86=!_PEX86! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-EnhancedStorage_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Scripting_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-SecureStartup_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-WDS-Tools_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-WMI_!LANGUAGE%%j!.cab"
 for /d %%G in %EAlang% do (
 if /i !LANGUAGE%%j!==%%G call set _PEF86=!_PEF86! /PackagePath:"!WinpeOC%%j!\WinPE-FontSupport-%%G.cab"
 )
) else (
echo !LANGUAGE%%j! / 64-bit
call set _PEM64=!_PEM64! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\lp.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-SRT_!LANGUAGE%%j!.cab"
call set _PES64=!_PES64! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Setup_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Setup-Client_!LANGUAGE%%j!.cab"
call set _PEX64=!_PEX64! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-EnhancedStorage_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Scripting_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-SecureStartup_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-WDS-Tools_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-WMI_!LANGUAGE%%j!.cab"
 for /d %%G in %EAlang% do (
 if /i !LANGUAGE%%j!==%%G call set _PEF64=!_PEF64! /PackagePath:"!WinpeOC%%j!\WinPE-FontSupport-%%G.cab"
 )
)
)

:extract
set _PP86=
set _PP64=
echo.
echo ============================================================
echo Extract language packs
echo ============================================================
echo.
if %wimbit%==32 for /L %%j in (1, 1, %LANGUAGES%) do (
if /i !LPARCH%%j!==x86 (
echo !LANGUAGE%%j! / 32-bit
copy ".\langs\!LPFILE%%j!" "%TEMPDIR%\!LANGUAGE%%j!_!LPARCH%%j!.cab" /y >nul
"%_7z%" e "%TEMPDIR%\!LANGUAGE%%j!_!LPARCH%%j!.cab" -o"%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" vofflps.rtf -r -aos >nul
"%_7z%" x "%TEMPDIR%\!LANGUAGE%%j!_!LPARCH%%j!.cab" -o"%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" *setup\sources\!LANGUAGE%%j! -r >nul
"%_7z%" x "%TEMPDIR%\!LANGUAGE%%j!_!LPARCH%%j!.cab" -o"%TEMPDIR%\!LPARCH%%j!\!LANGUAGE%%j!" * -r >nul
call set _PP86=!_PP86! /packagepath:"%TEMPDIR%\!LPARCH%%j!\!LANGUAGE%%j!\update.mum"
)
)
if %wimbit%==64 for /L %%j in (1, 1, %LANGUAGES%) do (
if /i !LPARCH%%j!==amd64 (
echo !LANGUAGE%%j! / 64-bit
copy ".\langs\!LPFILE%%j!" "%TEMPDIR%\!LANGUAGE%%j!_!LPARCH%%j!.cab" /y >nul
"%_7z%" e "%TEMPDIR%\!LANGUAGE%%j!_!LPARCH%%j!.cab" -o"%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" vofflps.rtf -r -aos >nul
"%_7z%" x "%TEMPDIR%\!LANGUAGE%%j!_!LPARCH%%j!.cab" -o"%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" *setup\sources\!LANGUAGE%%j! -r >nul
"%_7z%" x "%TEMPDIR%\!LANGUAGE%%j!_!LPARCH%%j!.cab" -o"%TEMPDIR%\!LPARCH%%j!\!LANGUAGE%%j!" * -r >nul
call set _PP64=!_PP64! /packagepath:"%TEMPDIR%\!LPARCH%%j!\!LANGUAGE%%j!\update.mum"
)
)
if %wimbit%==dual for /L %%j in (1, 1, %LANGUAGES%) do (
if /i !LPARCH%%j!==x86 (
echo !LANGUAGE%%j! / 32-bit
copy ".\langs\!LPFILE%%j!" "%TEMPDIR%\!LANGUAGE%%j!_!LPARCH%%j!.cab" /y >nul
"%_7z%" e "%TEMPDIR%\!LANGUAGE%%j!_!LPARCH%%j!.cab" -o"%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" vofflps.rtf -r -aos >nul
"%_7z%" x "%TEMPDIR%\!LANGUAGE%%j!_!LPARCH%%j!.cab" -o"%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" *setup\sources\!LANGUAGE%%j! -r >nul
"%_7z%" x "%TEMPDIR%\!LANGUAGE%%j!_!LPARCH%%j!.cab" -o"%TEMPDIR%\!LPARCH%%j!\!LANGUAGE%%j!" * -r >nul
call set _PP86=!_PP86! /packagepath:"%TEMPDIR%\!LPARCH%%j!\!LANGUAGE%%j!\update.mum"
) else (
echo !LANGUAGE%%j! / 64-bit
copy ".\langs\!LPFILE%%j!" "%TEMPDIR%\!LANGUAGE%%j!_!LPARCH%%j!.cab" /y >nul
"%_7z%" e "%TEMPDIR%\!LANGUAGE%%j!_!LPARCH%%j!.cab" -o"%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" vofflps.rtf -r -aos >nul
"%_7z%" x "%TEMPDIR%\!LANGUAGE%%j!_!LPARCH%%j!.cab" -o"%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" *setup\sources\!LANGUAGE%%j! -r >nul
"%_7z%" x "%TEMPDIR%\!LANGUAGE%%j!_!LPARCH%%j!.cab" -o"%TEMPDIR%\!LPARCH%%j!\!LANGUAGE%%j!" * -r >nul
call set _PP64=!_PP64! /packagepath:"%TEMPDIR%\!LPARCH%%j!\!LANGUAGE%%j!\update.mum"
)
)
if %wimbit%==32 if "!_PP86!"=="" goto :E_ARCH
if %wimbit%==64 if "!_PP64!"=="" goto :E_ARCH

if %NET35% NEQ 1 goto :proceed
echo.
echo ============================================================
echo Extract files from .NET Framework 3.5 package
echo ============================================================
echo.
if %wimbit%==32 ("%_7z%" x .\dotNetFx35_W8.1_x86_x64.exe -o"%EXTRACTDIR%\NET35" x86\* -r >nul)
if %wimbit%==64 (
"%_7z%" x .\dotNetFx35_W8.1_x86_x64.exe -o"%EXTRACTDIR%\NET35" x64\* -r >nul
move "%EXTRACTDIR%\NET35\x64" "%EXTRACTDIR%\NET35\amd64" >nul
)
if %wimbit%==dual (
"%_7z%" x .\dotNetFx35_W8.1_x86_x64.exe -o"%EXTRACTDIR%\NET35" x86\* -r >nul
"%_7z%" x .\dotNetFx35_W8.1_x86_x64.exe -o"%EXTRACTDIR%\NET35" x64\* -r >nul
move "%EXTRACTDIR%\NET35\x64" "%EXTRACTDIR%\NET35\amd64" >nul
)

:proceed
for /L %%i in (1, 1, %VERSIONS%) do (
echo.
echo ============================================================
echo Mount install.wim - index %%i/%VERSIONS%
echo ============================================================
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Mount-Wim /Wimfile:"%WIMPATH%" /Index:%%i /MountDir:"%INSTALLMOUNTDIR%"
if errorlevel 1 goto :E_MOUNT

attrib -S -H -I "%INSTALLMOUNTDIR%\Windows\System32\Recovery\winre.wim" 1>nul 2>nul
if %WINPE%==1 if not exist "%TEMPDIR%\WR\!WIMARCH%%i!\winre.wim" (
  echo.
  echo ============================================================
  echo Update winre.wim / !WIMARCH%%i!
  echo ============================================================
  echo.
  mkdir "%TEMPDIR%\WR\!WIMARCH%%i!"
  copy "%INSTALLMOUNTDIR%\Windows\System32\Recovery\winre.wim" "%TEMPDIR%\WR\!WIMARCH%%i!"
  echo.
  echo ============================================================
  echo Mount winre.wim
  echo ============================================================
  "!DISMRoot!" /ScratchDir:"!DISMTEMPDIR!" /Mount-Wim /Wimfile:"!TEMPDIR!\WR\!WIMARCH%%i!\winre.wim" /Index:1 /MountDir:"!WINREMOUNTDIR!"
  if errorlevel 1 goto :E_MOUNT
  echo.
  echo ============================================================
  echo Add LPs to winre.wim
  echo ============================================================
  if "!_PEM64!" NEQ "" if /i !WIMARCH%%i!==amd64 (
    "!DISMRoot!" /ScratchDir:"!DISMTEMPDIR!" /Image:"!WINREMOUNTDIR!" /Add-Package !_PEM64! !_PEF64!
    if !SLIM! NEQ 1 "!DISMRoot!" /ScratchDir:"!DISMTEMPDIR!" /Image:"!WINREMOUNTDIR!" /Add-Package !_PEX64!
  )
  if "!_PEM86!" NEQ "" if /i !WIMARCH%%i!==x86 (
    "!DISMRoot!" /ScratchDir:"!DISMTEMPDIR!" /Image:"!WINREMOUNTDIR!" /Add-Package !_PEM86! !_PEF86!
    if !SLIM! NEQ 1 "!DISMRoot!" /ScratchDir:"!DISMTEMPDIR!" /Image:"!WINREMOUNTDIR!" /Add-Package !_PEX86!
  )
  echo.
  echo ============================================================
  echo Update language settings
  echo ============================================================
  echo.
  "!DISMRoot!" /Quiet /ScratchDir:"!DISMTEMPDIR!" /Image:"!WINREMOUNTDIR!" /Set-AllIntl:!DEFAULTLANGUAGE!
  "!DISMRoot!" /Quiet /ScratchDir:"!DISMTEMPDIR!" /Image:"!WINREMOUNTDIR!" /Set-SKUIntlDefaults:!DEFAULTLANGUAGE!
  if exist "!WINREMOUNTDIR!\Windows\System32\WimBootCompress.ini" (
  echo.
  echo ============================================================
  echo Cleanup the image
  echo ============================================================
  "!DISMRoot!" /ScratchDir:"!DISMTEMPDIR!" /Image:"!WINREMOUNTDIR!" /Cleanup-Image /StartComponentCleanup /ResetBase
  )
  call :cleanup "!WINREMOUNTDIR!"
  echo.
  echo ============================================================
  echo Unmount winre.wim
  echo ============================================================
  "!DISMRoot!" /ScratchDir:"!DISMTEMPDIR!" /Unmount-Wim /MountDir:"!WINREMOUNTDIR!" /Commit
  if errorlevel 1 goto :E_UNMOUNT
  echo.
  echo ============================================================
  echo Rebuild winre.wim
  echo ============================================================
  "!DISMRoot!" /ScratchDir:"!DISMTEMPDIR!" /Export-Image /SourceImageFile:"!TEMPDIR!\WR\!WIMARCH%%i!\winre.wim" /SourceIndex:1 /DestinationImageFile:"!EXTRACTDIR!\winre.wim" /Bootable
  if exist "!EXTRACTDIR!\winre.wim" move /y "!EXTRACTDIR!\winre.wim" "!TEMPDIR!\WR\!WIMARCH%%i!" >nul
)
echo.
echo ============================================================
echo Add LPs to install.wim - index %%i/%VERSIONS%
echo ============================================================
if "!_PP64!" NEQ "" if /i !WIMARCH%%i!==amd64 (
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Image:"%INSTALLMOUNTDIR%" /Add-Package !_PP64!
)
if "!_PP86!" NEQ "" if /i !WIMARCH%%i!==x86 (
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Image:"%INSTALLMOUNTDIR%" /Add-Package !_PP86!
)
echo.
echo ============================================================
echo Update language settings
echo ============================================================
echo.
"%DISMRoot%" /Quiet /ScratchDir:"%DISMTEMPDIR%" /Image:"%INSTALLMOUNTDIR%" /Set-AllIntl:%DEFAULTLANGUAGE%
"%DISMRoot%" /Quiet /ScratchDir:"%DISMTEMPDIR%" /Image:"%INSTALLMOUNTDIR%" /Set-SKUIntlDefaults:%DEFAULTLANGUAGE%
if %NET35%==1 if not exist "%INSTALLMOUNTDIR%\Windows\Microsoft.NET\Framework\v2.0.50727\ngen.exe" (
echo.
echo ============================================================
echo Enable .NET Framework 3.5 - index %%i/%VERSIONS%
echo ============================================================
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Image:"%INSTALLMOUNTDIR%" /Enable-Feature /Featurename:NetFx3 /All /LimitAccess /Source:"%EXTRACTDIR%\NET35\!WIMARCH%%i!"
)
if %WINPE%==1 if exist "%TEMPDIR%\WR\!WIMARCH%%i!\winre.wim" (
echo.
echo ============================================================
echo Add updated winre.wim to install.wim - index %%i/%VERSIONS%
echo ============================================================
echo.
copy "%TEMPDIR%\WR\!WIMARCH%%i!\winre.wim" "%INSTALLMOUNTDIR%\Windows\System32\Recovery" /y
)
call :cleanup "%INSTALLMOUNTDIR%"
echo.
echo ============================================================
echo Unmount install.wim - index %%i/%VERSIONS%
echo ============================================================
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Unmount-Wim /MountDir:"%INSTALLMOUNTDIR%" /Commit
if errorlevel 1 goto :E_UNMOUNT
)
echo.
echo ============================================================
echo Rebuild install.wim
echo ============================================================
for /L %%i in (1, 1, %VERSIONS%) do (
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Export-Image /SourceImageFile:"%WIMPATH%" /SourceIndex:%%i /DestinationImageFile:"%TEMPDIR%\install.wim"
)
if exist "%TEMPDIR%\install.wim" move /y "%TEMPDIR%\install.wim" "%WIMPATH%" >nul
echo.
echo ============================================================
echo Remove temporary directories
echo ============================================================
echo.
call :remove
set MESSAGE=Done
goto :END

:E_BIN
call :remove
set MESSAGE=ERROR: Could not find work binaries
goto :END

:E_DVD
call :remove
set MESSAGE=ERROR: Could not find the specified install.wim
goto :END

:E_FILES
call :remove
set MESSAGE=ERROR: Could not detect any cab file in "langs" folder
goto :END

:E_ARCH
call :remove
set MESSAGE=ERROR: None of detected LangPacks match any of WIM images architecture
goto :END

:E_LP
call :remove
set MESSAGE=ERROR: %ERRFILE% is not a valid Windows 8.1 LangPack
goto :END

:E_RTM
call :remove
set MESSAGE=ERROR: %ERRFILE% level ^(RTM^) does not match install.wim level ^(Update^)
goto :END

:E_DELDIR
set MESSAGE=ERROR: Could not delete temporary directory
goto :END

:E_MKDIR
set MESSAGE=ERROR: Could not create temporary directory
goto :END

:E_MOUNT
set MESSAGE=ERROR: Could not mount WIM image
goto :END

:E_UNMOUNT
set MESSAGE=ERROR: Could not unmount WIM image
goto :END

:E_ADMIN
set MESSAGE=ERROR: Run the script as administrator
goto :END

:remove
if exist "%TEMPDIR%" (rmdir /s /q "%TEMPDIR%" 1>nul 2>nul || goto :E_DELDIR)
if exist "%MOUNTDIR%" (rmdir /s /q "%MOUNTDIR%" 1>nul 2>nul || goto :E_DELDIR)
goto :eof

:cleanup
if exist "%~1\Windows\WinSxS\ManifestCache\*.bin" (
takeown /f "%~1\Windows\WinSxS\ManifestCache\*.bin" /A >nul 2>&1
icacls "%~1\Windows\WinSxS\ManifestCache\*.bin" /grant *S-1-5-32-544:F >nul 2>&1
del /f /q "%~1\Windows\WinSxS\ManifestCache\*.bin" >nul 2>&1
)
if exist "%~1\Windows\WinSxS\Temp\PendingDeletes\*" (
takeown /f "%~1\Windows\WinSxS\Temp\PendingDeletes\*" /A >nul 2>&1
icacls "%~1\Windows\WinSxS\Temp\PendingDeletes\*" /grant *S-1-5-32-544:F >nul 2>&1
del /f /q "%~1\Windows\WinSxS\Temp\PendingDeletes\*" >nul 2>&1
)
if exist "%~1\Windows\inf\*.log" (
del /f /q "%~1\Windows\inf\*.log" >nul 2>&1
)
goto :eof

:END
echo.
echo ============================================================
echo %MESSAGE%
echo ============================================================
echo.
echo Press any Key to Exit.
pause >nul
exit