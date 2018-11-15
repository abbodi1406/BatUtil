@echo off

set DVDPATH=
set ISO=1
set WINPE=1
set SLIM=0

set DEFAULTLANGUAGE=
set MOUNTDIR=

rem ##################################################################
rem # NORMALY THERE IS NO NEED TO CHANGE ANYTHING BELOW THIS COMMENT #
rem ##################################################################

%windir%\system32\reg.exe query "HKU\S-1-5-19" 1>nul 2>nul || goto :E_ADMIN
cd /d "%~dp0"
set WORKDIR=%cd%
set DVDDIR=%WORKDIR%\DVD
set TEMPDIR=%WORKDIR%\TEMP
if "%MOUNTDIR%"=="" set MOUNTDIR=%WORKDIR%\MOUNT
set DISMTEMPDIR=%TEMPDIR%\scratch
set EXTRACTDIR=%TEMPDIR%\extract
set INSTALLMOUNTDIR=%MOUNTDIR%\install
set WINREMOUNTDIR=%MOUNTDIR%\winre
set BOOTMOUNTDIR=%MOUNTDIR%\boot
set EAlang=(ja-jp,ko-kr,zh-cn,zh-hk,zh-tw)
set _mui=(arunres.dll.mui,cmisetup.dll.mui,compatprovider.dll.mui,dism.exe.mui,dismcore.dll.mui,dismprov.dll.mui,folderprovider.dll.mui,input.dll.mui,logprovider.dll.mui,msxml6r.dll.mui,nlsbres.dll.mui,pnpibs.dll.mui,rollback.exe.mui,setup.exe.mui,smiengine.dll.mui,spwizres.dll.mui,upgloader.dll.mui,uxlibres.dll.mui,w32uires.dll.mui,wdsclient.dll.mui,wdsimage.dll.mui,winsetup.dll.mui)

set _winpe=0
if exist ".\winpe\*supplement*.iso" (
set _winpe=1
for /f "delims=" %%i in ('dir /b ".\winpe\*supplement*.iso"') do set WinPERoot=.\winpe\%%i
)
if %_winpe%==0 set WINPE=0

set _iso=0
if exist "*.iso" (for /f "delims=" %%i in ('dir /b *.iso') do (call set /a _iso+=1))
if "%DVDPATH%"=="" (
if %_iso%==0 goto :prompt
for /f "delims=" %%i in ('dir /b *.iso') do set "DVDPATH=%%i"
)
goto :check

:prompt
echo.
echo ============================================================
echo Enter the distribution path ^(without quotes marks ""^):
echo ISO file^, Extracted ISO folder^, DVD/USB drive letter
echo ============================================================
echo.
set /p DVDPATH=
if [%DVDPATH%]==[] set MESSAGE=ERROR: no source distribution specified&goto :END
goto :check

:check
for /d %%G in (7z.exe,7z.dll,cdimage.exe,imagex.exe) do (
if not exist "%~dp0bin\%%G" set ERRFILE=%%G&goto :E_BIN
)
set "_7z=%~dp0bin\7z.exe"
if not exist "%DVDPATH%" goto :E_DVD
setlocal EnableDelayedExpansion
echo.
echo ============================================================
echo Prepare work directories
echo ============================================================
echo.
if exist "%DVDDIR%" (rmdir /s /q "%DVDDIR%" 1>nul 2>nul || goto :E_DELDIR)
if exist "%TEMPDIR%" (rmdir /s /q "%TEMPDIR%" 1>nul 2>nul || goto :E_DELDIR)
if exist "%MOUNTDIR%" (rmdir /s /q "%MOUNTDIR%" 1>nul 2>nul || goto :E_DELDIR)
mkdir "%DVDDIR%" || goto :E_MKDIR
mkdir "%TEMPDIR%" || goto :E_MKDIR
mkdir "%DISMTEMPDIR%" || goto :E_MKDIR
mkdir "%EXTRACTDIR%" || goto :E_MKDIR
mkdir "%MOUNTDIR%" || goto :E_MKDIR
mkdir "%INSTALLMOUNTDIR%" || goto :E_MKDIR
mkdir "%WINREMOUNTDIR%" || goto :E_MKDIR
mkdir "%BOOTMOUNTDIR%" || goto :E_MKDIR
goto :start

:setcount
set /a count+=1
set LPFILE%count%=%1
goto :eof

:setarch
set /a count+=1
for /f "tokens=2 delims=: " %%i in ('dism.exe /english /get-wiminfo /wimfile:"%DVDDIR%\sources\install.wim" /index:%1 ^| find /i "Architecture"') do set WIMARCH%count%=%%i
goto :eof

:start
echo.
echo ============================================================
echo Detect language packs details
echo ============================================================
echo.
set _c=0
if exist ".\langs\*.exe" (for /f %%i in ('dir /b ".\langs\*.exe"') do (call set /a _c+=1))
if exist ".\langs\*.cab" (for /f %%i in ('dir /b ".\langs\*.cab"') do (call set /a _c+=1))
if %_c% equ 0 goto :E_FILES
set LANGUAGES=%_c%
if exist ".\langs\*.exe" (for /f %%i in ('dir /b /o:n ".\langs\*.exe"') do call :setcount %%i)
if exist ".\langs\*.cab" (for /f %%i in ('dir /b /o:n ".\langs\*.cab"') do call :setcount %%i)

for /L %%j in (1, 1, %LANGUAGES%) do (
"%_7z%" e ".\langs\!LPFILE%%j!" -o"%EXTRACTDIR%" langcfg.ini >nul
for /f "tokens=2 delims==" %%i in ('type "%EXTRACTDIR%\langcfg.ini" ^| findstr /i "Language"') do set LANGUAGE%%j=%%i
del /f /q "%EXTRACTDIR%\langcfg.ini"
"%_7z%" e ".\langs\!LPFILE%%j!" -o"%EXTRACTDIR%" microsoft-windows-client-languagepack-package*7601*.mum 1>nul 2>nul
if not exist "%EXTRACTDIR%\*.mum" set ERRFILE=!LPFILE%%j!&goto :E_SP1
for /f "tokens=3 delims=~" %%V in ('"dir "%EXTRACTDIR%\*.mum" /b" 2^>nul') do set LPARCH%%j=%%V
del /f /q "%EXTRACTDIR%\*.mum" 1>nul 2>nul
)
for /L %%j in (1, 1, %LANGUAGES%) do (
if /i !LPARCH%%j!==amd64 (echo !LANGUAGE%%j!: 64-bit {x64}) else (echo !LANGUAGE%%j!: 32-bit {x86})
set "WinpeOC%%j=%EXTRACTDIR%\WINPE\!LPARCH%%j!\WINPE_FPS"
)
echo.
echo ============================================================
echo Copy Distribution contents to work directory
echo ============================================================
echo.
echo Source Path:
echo "%DVDPATH%"
echo %DVDPATH%| findstr /E /I "\.iso" >nul
if %errorlevel%==0 (
   "%_7z%" x "%DVDPATH%" -o"%DVDDIR%" * -r >nul
) else (
   %windir%\system32\robocopy.exe "%DVDPATH%" "%DVDDIR%" /E /A-:R >nul
)
if not exist "%DVDDIR%\sources\install.wim" goto :E_WIM
for /f "tokens=2 delims=: " %%i in ('dism.exe /english /get-wiminfo /wimfile:"%DVDDIR%\sources\install.wim" ^| findstr "Index"') do set VERSIONS=%%i
if %VERSIONS% gtr 1 if exist "%DVDDIR%\sources\ei.cfg" (
del /f /q "%DVDDIR%\sources\ei.cfg" >nul
)
if "%DEFAULTLANGUAGE%"=="" (
for /f "tokens=1" %%i in ('dism.exe /english /get-wiminfo /wimfile:"%DVDDIR%\sources\install.wim" /index:1 ^| find /i "Default"') do set DEFAULTLANGUAGE=%%i
)
for /f "tokens=2 delims=: " %%i in ('dism.exe /english /get-wiminfo /wimfile:"%DVDDIR%\sources\boot.wim" /index:1 ^| find /i "Architecture"') do set BOOTARCH=%%i
if /i %BOOTARCH%==x64 set BOOTARCH=amd64
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
if %errorlevel%==0 (set wimbit=32&set DVDISO=mu_windows_7_with_sp1_x86_dvd.iso&set DVDLABEL=GSP1RM_X86FRE_MUI_DVD&set _label86=1)

%windir%\system32\findstr.exe /i /v "x86" "%TEMPDIR%\WIMARCH.txt" >nul
if %errorlevel%==0 (
if %_label86%==1 (set wimbit=dual&set DVDISO=mu_windows_7_with_sp1_x86_x64_dvd.iso&set DVDLABEL=GSP1RM_X86X64FRE_MUI_DVD) else (set wimbit=64&set DVDISO=mu_windows_7_with_sp1_x64_dvd.iso&set DVDLABEL=GSP1RM_X64FRE_MUI_DVD)
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
echo Extract WinPE language packs
echo ============================================================
echo.
if %wimbit%==32 for /L %%j in (1, 1, %LANGUAGES%) do (
if /i !LPARCH%%j!==x86 (
echo !LANGUAGE%%j! / 32-bit
"%_7z%" x "%WinPERoot%" -o"%EXTRACTDIR%\WINPE" *!LPARCH%%j!\WINPE_FPS\!LANGUAGE%%j! -r >nul
 for /d %%G in %EAlang% do (
 if /i !LANGUAGE%%j!==%%G "%_7z%" x "%WinPERoot%" -o"%EXTRACTDIR%\WINPE" !LPARCH%%j!\WINPE_FPS\WinPE-FontSupport-%%G.cab >nul
 if /i !LANGUAGE%%j!==%%G call set _PEF86=!_PEF86! /PackagePath:"!WinpeOC%%j!\WinPE-FontSupport-%%G.cab"
 )
call set _PEM86=!_PEM86! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\lp_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-SRT_!LANGUAGE%%j!.cab"
call set _PES86=!_PES86! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Setup_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Setup-Client_!LANGUAGE%%j!.cab"
call set _PEX86=!_PEX86! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Scripting_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-WDS-Tools_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-WMI_!LANGUAGE%%j!.cab"
)
)
if %wimbit%==64 for /L %%j in (1, 1, %LANGUAGES%) do (
if /i !LPARCH%%j!==amd64 (
echo !LANGUAGE%%j! / 64-bit
"%_7z%" x "%WinPERoot%" -o"%EXTRACTDIR%\WINPE" *!LPARCH%%j!\WINPE_FPS\!LANGUAGE%%j! -r >nul
 for /d %%G in %EAlang% do (
 if /i !LANGUAGE%%j!==%%G "%_7z%" x "%WinPERoot%" -o"%EXTRACTDIR%\WINPE" !LPARCH%%j!\WINPE_FPS\WinPE-FontSupport-%%G.cab >nul
 if /i !LANGUAGE%%j!==%%G call set _PEF64=!_PEF64! /PackagePath:"!WinpeOC%%j!\WinPE-FontSupport-%%G.cab"
 )
call set _PEM64=!_PEM64! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\lp_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-SRT_!LANGUAGE%%j!.cab"
call set _PES64=!_PES64! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Setup_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Setup-Client_!LANGUAGE%%j!.cab"
call set _PEX64=!_PEx64! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Scripting_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-WDS-Tools_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-WMI_!LANGUAGE%%j!.cab"
)
)
if %wimbit%==dual for /L %%j in (1, 1, %LANGUAGES%) do (
if /i !LPARCH%%j!==x86 (
echo !LANGUAGE%%j! / 32-bit
"%_7z%" x "%WinPERoot%" -o"%EXTRACTDIR%\WINPE" *!LPARCH%%j!\WINPE_FPS\!LANGUAGE%%j! -r >nul
 for /d %%G in %EAlang% do (
 if /i !LANGUAGE%%j!==%%G "%_7z%" x "%WinPERoot%" -o"%EXTRACTDIR%\WINPE" !LPARCH%%j!\WINPE_FPS\WinPE-FontSupport-%%G.cab >nul
 if /i !LANGUAGE%%j!==%%G call set _PEF86=!_PEF86! /PackagePath:"!WinpeOC%%j!\WinPE-FontSupport-%%G.cab"
 )
call set _PEM86=!_PEM86! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\lp_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-SRT_!LANGUAGE%%j!.cab"
call set _PES86=!_PES86! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Setup_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Setup-Client_!LANGUAGE%%j!.cab"
call set _PEX86=!_PEX86! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Scripting_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-WDS-Tools_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-WMI_!LANGUAGE%%j!.cab"
) else (
echo !LANGUAGE%%j! / 64-bit
"%_7z%" x "%WinPERoot%" -o"%EXTRACTDIR%\WINPE" *!LPARCH%%j!\WINPE_FPS\!LANGUAGE%%j! -r >nul
 for /d %%G in %EAlang% do (
 if /i !LANGUAGE%%j!==%%G "%_7z%" x "%WinPERoot%" -o"%EXTRACTDIR%\WINPE" !LPARCH%%j!\WINPE_FPS\WinPE-FontSupport-%%G.cab >nul
 if /i !LANGUAGE%%j!==%%G call set _PEF64=!_PEF64! /PackagePath:"!WinpeOC%%j!\WinPE-FontSupport-%%G.cab"
 )
call set _PEM64=!_PEM64! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\lp_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-SRT_!LANGUAGE%%j!.cab"
call set _PES64=!_PES64! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Setup_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Setup-Client_!LANGUAGE%%j!.cab"
call set _PEX64=!_PEx64! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Scripting_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-WDS-Tools_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-WMI_!LANGUAGE%%j!.cab"
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
copy ".\langs\!LPFILE%%j!" "%TEMPDIR%\!LANGUAGE%%j!-!LPARCH%%j!.cab" /y >nul
"%_7z%" x "%TEMPDIR%\!LANGUAGE%%j!-!LPARCH%%j!.cab" -o"%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" *sp1\setup\sources\!LANGUAGE%%j! -r >nul
"%_7z%" x "%TEMPDIR%\!LANGUAGE%%j!-!LPARCH%%j!.cab" -o"%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" *sp1\sources\license\!LANGUAGE%%j! -r >nul
"%_7z%" x "%TEMPDIR%\!LANGUAGE%%j!-!LPARCH%%j!.cab" -o"%TEMPDIR%\!LPARCH%%j!\!LANGUAGE%%j!" * -r >nul
call set _PP86=!_PP86! /packagepath:"%TEMPDIR%\!LPARCH%%j!\!LANGUAGE%%j!\update.mum"
)
)
if %wimbit%==64 for /L %%j in (1, 1, %LANGUAGES%) do (
if /i !LPARCH%%j!==amd64 (
echo !LANGUAGE%%j! / 64-bit
copy ".\langs\!LPFILE%%j!" "%TEMPDIR%\!LANGUAGE%%j!-!LPARCH%%j!.cab" /y >nul
"%_7z%" x "%TEMPDIR%\!LANGUAGE%%j!-!LPARCH%%j!.cab" -o"%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" *sp1\setup\sources\!LANGUAGE%%j! -r >nul
"%_7z%" x "%TEMPDIR%\!LANGUAGE%%j!-!LPARCH%%j!.cab" -o"%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" *sp1\sources\license\!LANGUAGE%%j! -r >nul
"%_7z%" x "%TEMPDIR%\!LANGUAGE%%j!-!LPARCH%%j!.cab" -o"%TEMPDIR%\!LPARCH%%j!\!LANGUAGE%%j!" * -r >nul
call set _PP64=!_PP64! /packagepath:"%TEMPDIR%\!LPARCH%%j!\!LANGUAGE%%j!\update.mum"
)
)
if %wimbit%==dual for /L %%j in (1, 1, %LANGUAGES%) do (
if /i !LPARCH%%j!==x86 (
echo !LANGUAGE%%j! / 32-bit
copy ".\langs\!LPFILE%%j!" "%TEMPDIR%\!LANGUAGE%%j!-!LPARCH%%j!.cab" /y >nul
"%_7z%" x "%TEMPDIR%\!LANGUAGE%%j!-!LPARCH%%j!.cab" -o"%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" *sp1\setup\sources\!LANGUAGE%%j! -r >nul
"%_7z%" x "%TEMPDIR%\!LANGUAGE%%j!-!LPARCH%%j!.cab" -o"%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" *sp1\sources\license\!LANGUAGE%%j! -r >nul
"%_7z%" x "%TEMPDIR%\!LANGUAGE%%j!-!LPARCH%%j!.cab" -o"%TEMPDIR%\!LPARCH%%j!\!LANGUAGE%%j!" * -r >nul
call set _PP86=!_PP86! /packagepath:"%TEMPDIR%\!LPARCH%%j!\!LANGUAGE%%j!\update.mum"
) else (
echo !LANGUAGE%%j! / 64-bit
copy ".\langs\!LPFILE%%j!" "%TEMPDIR%\!LANGUAGE%%j!-!LPARCH%%j!.cab" /y >nul
"%_7z%" x "%TEMPDIR%\!LANGUAGE%%j!-!LPARCH%%j!.cab" -o"%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" *sp1\setup\sources\!LANGUAGE%%j! -r >nul
"%_7z%" x "%TEMPDIR%\!LANGUAGE%%j!-!LPARCH%%j!.cab" -o"%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" *sp1\sources\license\!LANGUAGE%%j! -r >nul
"%_7z%" x "%TEMPDIR%\!LANGUAGE%%j!-!LPARCH%%j!.cab" -o"%TEMPDIR%\!LPARCH%%j!\!LANGUAGE%%j!" * -r >nul
call set _PP64=!_PP64! /packagepath:"%TEMPDIR%\!LPARCH%%j!\!LANGUAGE%%j!\update.mum"
)
)
if %wimbit%==32 if "!_PP86!"=="" goto :E_ARCH
if %wimbit%==64 if "!_PP64!"=="" goto :E_ARCH

if %SLIM%==1 goto :proceed
:dvdmui
echo.
echo ============================================================
echo Add language files to distribution
echo ============================================================
echo.
if /i %BOOTARCH%==x86 for /L %%j in (1, 1, %LANGUAGES%) do (
if /i !LPARCH%%j!==x86 (
echo !LANGUAGE%%j! / 32-bit
call :ISOmui %%j
)
)
if /i %BOOTARCH%==amd64 for /L %%j in (1, 1, %LANGUAGES%) do (
if /i !LPARCH%%j!==amd64 (
echo !LANGUAGE%%j! / 64-bit
call :ISOmui %%j
)
)

:proceed
for /L %%i in (1, 1, %VERSIONS%) do (
echo.
echo ============================================================
echo Mount install.wim - index %%i/%VERSIONS%
echo ============================================================
dism.exe /ScratchDir:"%DISMTEMPDIR%" /Mount-Wim /Wimfile:"%DVDDIR%\sources\install.wim" /Index:%%i /MountDir:"%INSTALLMOUNTDIR%"
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
  dism.exe /ScratchDir:"!DISMTEMPDIR!" /Mount-Wim /Wimfile:"!TEMPDIR!\WR\!WIMARCH%%i!\winre.wim" /Index:1 /MountDir:"!WINREMOUNTDIR!"
  if errorlevel 1 goto :E_MOUNT
  if exist .\bin\Windows6.1-KB2883457-!WIMARCH%%i!.cab if not exist "!WINREMOUNTDIR!\Windows\servicing\packages\package_for_kb2883457*.mum" (
  echo.
  echo ============================================================
  echo Update Recovery Tools
  echo ============================================================
    dism.exe /ScratchDir:"!DISMTEMPDIR!" /Image:"!WINREMOUNTDIR!" /Add-Package /PackagePath:".\bin\Windows6.1-KB2883457-!WIMARCH%%i!.cab"
  )
  echo.
  echo ============================================================
  echo Add LPs to winre.wim
  echo ============================================================
  if "!_PEM64!" NEQ "" if /i !WIMARCH%%i!==amd64 (
    dism.exe /ScratchDir:"!DISMTEMPDIR!" /Image:"!WINREMOUNTDIR!" /Add-Package !_PEM64! !_PES64! !_PEF64!
    if !SLIM! NEQ 1 dism.exe /ScratchDir:"!DISMTEMPDIR!" /Image:"!WINREMOUNTDIR!" /Add-Package !_PEX64!
  )
  if "!_PEM86!" NEQ "" if /i !WIMARCH%%i!==x86 (
    dism.exe /ScratchDir:"!DISMTEMPDIR!" /Image:"!WINREMOUNTDIR!" /Add-Package !_PEM86! !_PES86! !_PEF86!
    if !SLIM! NEQ 1 dism.exe /ScratchDir:"!DISMTEMPDIR!" /Image:"!WINREMOUNTDIR!" /Add-Package !_PEX86!
  )
  echo.
  echo ============================================================
  echo Update language settings
  echo ============================================================
  echo.
  dism.exe /Quiet /ScratchDir:"!DISMTEMPDIR!" /Image:"!WINREMOUNTDIR!" /Set-AllIntl:!DEFAULTLANGUAGE!
  dism.exe /Quiet /ScratchDir:"!DISMTEMPDIR!" /Image:"!WINREMOUNTDIR!" /Set-SKUIntlDefaults:!DEFAULTLANGUAGE!
  dism.exe /Quiet /ScratchDir:"!DISMTEMPDIR!" /Image:"!WINREMOUNTDIR!" /Gen-LangINI /Distribution:"!WINREMOUNTDIR!"
  dism.exe /Quiet /ScratchDir:"!DISMTEMPDIR!" /Image:"!WINREMOUNTDIR!" /Set-SetupUILang:!DEFAULTLANGUAGE! /Distribution:"!WINREMOUNTDIR!"
  call :cleanup "!WINREMOUNTDIR!"
  echo.
  echo ============================================================
  echo Unmount winre.wim
  echo ============================================================
  dism.exe /ScratchDir:"!DISMTEMPDIR!" /Unmount-Wim /MountDir:"!WINREMOUNTDIR!" /Commit
  if errorlevel 1 goto :E_UNMOUNT
  echo.
  echo ============================================================
  echo Rebuild winre.wim
  echo ============================================================
  echo.
  "%~dp0bin\imagex.exe" /BOOT /EXPORT "!TEMPDIR!\WR\!WIMARCH%%i!\winre.wim" 1 "!EXTRACTDIR!\winre.wim" >nul
  if exist "!EXTRACTDIR!\winre.wim" move /y "!EXTRACTDIR!\winre.wim" "!TEMPDIR!\WR\!WIMARCH%%i!" >nul
)
echo.
echo ============================================================
echo Add LPs to install.wim - index %%i/%VERSIONS%
echo ============================================================
if "!_PP64!" NEQ "" if /i !WIMARCH%%i!==amd64 (
dism.exe /ScratchDir:"%DISMTEMPDIR%" /Image:"%INSTALLMOUNTDIR%" /Add-Package !_PP64!
)
if "!_PP86!" NEQ "" if /i !WIMARCH%%i!==x86 (
dism.exe /ScratchDir:"%DISMTEMPDIR%" /Image:"%INSTALLMOUNTDIR%" /Add-Package !_PP86!
)
if %%i==%VERSIONS% for /L %%j in (1, 1, %LANGUAGES%) do (
if /i !LANGUAGE%%j!==ja-jp copy /y "%INSTALLMOUNTDIR%\Windows\Boot\Fonts\jpn_boot.ttf" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" >nul&copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\meiryo.ttc" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" >nul&copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\msgothic.ttc" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" >nul
if /i !LANGUAGE%%j!==ko-kr copy /y "%INSTALLMOUNTDIR%\Windows\Boot\Fonts\kor_boot.ttf" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" >nul&copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\malgun.ttf" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" >nul&copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\gulim.ttc" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" >nul
if /i !LANGUAGE%%j!==zh-cn copy /y "%INSTALLMOUNTDIR%\Windows\Boot\Fonts\chs_boot.ttf" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" >nul&copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\msyh.ttf" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" >nul&copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\mingliu.ttc" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" >nul&copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\simsun.ttc" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" >nul
if /i !LANGUAGE%%j!==zh-hk copy /y "%INSTALLMOUNTDIR%\Windows\Boot\Fonts\cht_boot.ttf" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" >nul&copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\msjh.ttf" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" >nul&copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\mingliu.ttc" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" >nul&copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\simsun.ttc" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" >nul
if /i !LANGUAGE%%j!==zh-tw copy /y "%INSTALLMOUNTDIR%\Windows\Boot\Fonts\cht_boot.ttf" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" >nul&copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\msjh.ttf" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" >nul&copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\mingliu.ttc" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" >nul&copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\simsun.ttc" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" >nul
)
echo.
echo ============================================================
echo Update language settings
echo ============================================================
echo.
dism.exe /Quiet /ScratchDir:"%DISMTEMPDIR%" /Image:"%INSTALLMOUNTDIR%" /Set-AllIntl:%DEFAULTLANGUAGE%
dism.exe /Quiet /ScratchDir:"%DISMTEMPDIR%" /Image:"%INSTALLMOUNTDIR%" /Set-SKUIntlDefaults:%DEFAULTLANGUAGE%
if %%i==%VERSIONS% (
dism.exe /Quiet /ScratchDir:"%DISMTEMPDIR%" /Image:"%INSTALLMOUNTDIR%" /Gen-LangINI /Distribution:"%DVDDIR%"
dism.exe /Quiet /ScratchDir:"%DISMTEMPDIR%" /Image:"%INSTALLMOUNTDIR%" /Set-SetupUILang:%DEFAULTLANGUAGE% /Distribution:"%DVDDIR%"
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
dism.exe /ScratchDir:"%DISMTEMPDIR%" /Unmount-Wim /MountDir:"%INSTALLMOUNTDIR%" /Commit
if errorlevel 1 goto :E_UNMOUNT
)
echo.
echo ============================================================
echo Mount boot.wim - index 1/2
echo ============================================================
dism.exe /ScratchDir:"%DISMTEMPDIR%" /Mount-Wim /WimFile:"%DVDDIR%\sources\boot.wim" /Index:1 /MountDir:"%BOOTMOUNTDIR%"
if errorlevel 1 goto :E_MOUNT

if exist .\bin\Windows6.1-KB2883457-%BOOTARCH%.cab if not exist "%BOOTMOUNTDIR%\Windows\servicing\packages\package_for_kb2883457*.mum" (
echo.
echo ============================================================
echo Update Recovery Tools
echo ============================================================
dism.exe /ScratchDir:"%DISMTEMPDIR%" /Image:"%BOOTMOUNTDIR%" /Add-Package /PackagePath:".\bin\Windows6.1-KB2883457-%BOOTARCH%.cab"
)
if %WINPE%==1 (
  echo.
  echo ============================================================
  echo Add LPs to boot.wim - index 1/2
  echo ============================================================
  if "!_PEM64!" NEQ "" if /i !BOOTARCH!==amd64 (
    dism.exe /ScratchDir:"!DISMTEMPDIR!" /Image:"!BOOTMOUNTDIR!" /Add-Package !_PEM64! !_PEF64!
    if !SLIM! NEQ 1 dism.exe /ScratchDir:"!DISMTEMPDIR!" /Image:"!BOOTMOUNTDIR!" /Add-Package !_PEX64!
  )
  if "!_PEM86!" NEQ "" if /i !BOOTARCH!==x86 (
    dism.exe /ScratchDir:"!DISMTEMPDIR!" /Image:"!BOOTMOUNTDIR!" /Add-Package !_PEM86! !_PEF86!
    if !SLIM! NEQ 1 dism.exe /ScratchDir:"!DISMTEMPDIR!" /Image:"!BOOTMOUNTDIR!" /Add-Package !_PEX86!
  )
) else (
  for /L %%j in (1, 1, %LANGUAGES%) do (
   if /i !LPARCH%%j!==!BOOTARCH! (
    mkdir "!BOOTMOUNTDIR!\sources\!LANGUAGE%%j!"
    call :EAfonts %%j
   )
  )
)
if %WINPE%==1 (
echo.
echo ============================================================
echo Update language settings
echo ============================================================
echo.
dism.exe /Quiet /ScratchDir:"%DISMTEMPDIR%" /Image:"%BOOTMOUNTDIR%" /Set-AllIntl:%DEFAULTLANGUAGE%
dism.exe /Quiet /ScratchDir:"%DISMTEMPDIR%" /Image:"%BOOTMOUNTDIR%" /Set-SKUIntlDefaults:%DEFAULTLANGUAGE%
)
call :cleanup "%BOOTMOUNTDIR%"
echo.
echo ============================================================
echo Unmount boot.wim - index 1/2
echo ============================================================
dism.exe /ScratchDir:"%DISMTEMPDIR%" /Unmount-Wim /MountDir:"%BOOTMOUNTDIR%" /Commit
if errorlevel 1 goto :E_UNMOUNT
echo.
echo ============================================================
echo Mount boot.wim - index 2/2
echo ============================================================
dism.exe /ScratchDir:"%DISMTEMPDIR%" /Mount-Wim /WimFile:"%DVDDIR%\sources\boot.wim" /Index:2 /MountDir:"%BOOTMOUNTDIR%"
if errorlevel 1 goto :E_MOUNT

if exist .\bin\Windows6.1-KB2883457-%BOOTARCH%.cab if not exist "%BOOTMOUNTDIR%\Windows\servicing\packages\package_for_kb2883457*.mum" (
echo.
echo ============================================================
echo Update Recovery Tools
echo ============================================================
dism.exe /ScratchDir:"%DISMTEMPDIR%" /Image:"%BOOTMOUNTDIR%" /Add-Package /PackagePath:".\bin\Windows6.1-KB2883457-%BOOTARCH%.cab"
)
if %WINPE%==1 (
  echo.
  echo ============================================================
  echo Add LPs to boot.wim - index 2/2
  echo ============================================================
  if "!_PEM64!" NEQ "" if /i !BOOTARCH!==amd64 (
    dism.exe /ScratchDir:"!DISMTEMPDIR!" /Image:"!BOOTMOUNTDIR!" /Add-Package !_PEM64! !_PES64! !_PEF64!
    if !SLIM! NEQ 1 dism.exe /ScratchDir:"!DISMTEMPDIR!" /Image:"!BOOTMOUNTDIR!" /Add-Package !_PEX64!
  )
  if "!_PEM86!" NEQ "" if /i !BOOTARCH!==x86 (
    dism.exe /ScratchDir:"!DISMTEMPDIR!" /Image:"!BOOTMOUNTDIR!" /Add-Package !_PEM86! !_PES86! !_PEF86!
    if !SLIM! NEQ 1 dism.exe /ScratchDir:"!DISMTEMPDIR!" /Image:"!BOOTMOUNTDIR!" /Add-Package !_PEX86!
  )
  if /i !wimbit! NEQ dual for /L %%j in (1, 1, %LANGUAGES%) do (
    xcopy "!BOOTMOUNTDIR!\sources\!LANGUAGE%%j!\*.rtf" "!DVDDIR!\sources\!LANGUAGE%%j!\" /chryi 1>nul 2>nul
  )
) else (
  copy "!DVDDIR!\sources\lang.ini" "!BOOTMOUNTDIR!\sources" /y >nul
    echo.
    echo ============================================================
    echo Copy language files to boot.wim - index 2
    echo ============================================================
    echo.
  for /L %%j in (1, 1, %LANGUAGES%) do (
   if /i !LPARCH%%j!==!BOOTARCH! (
    echo !LANGUAGE%%j!
    xcopy "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\sp1\sources\license\!LANGUAGE%%j!\*" "!BOOTMOUNTDIR!\sources\License\!LANGUAGE%%j!" /cheryi >nul
    del /f /q "!BOOTMOUNTDIR!\sources\License\!LANGUAGE%%j!\_default\lipeula.rtf" >nul
    del /f /q "!BOOTMOUNTDIR!\sources\License\!LANGUAGE%%j!\_default\lpeula.rtf" >nul
    mkdir "!BOOTMOUNTDIR!\sources\!LANGUAGE%%j!"
    copy "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\help_what_is_activation.rtf" "!BOOTMOUNTDIR!\sources\!LANGUAGE%%j!" /y >nul
    copy "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\vofflps.rtf" "!BOOTMOUNTDIR!\sources\!LANGUAGE%%j!" /y >nul
    for /d %%G in %_mui% do (
    copy "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\sp1\setup\sources\!LANGUAGE%%j!\%%G" "!BOOTMOUNTDIR!\sources\!LANGUAGE%%j!" /y >nul 2>&1
    )
    attrib -A -S -H -I "!BOOTMOUNTDIR!\sources\!LANGUAGE%%j!" /S /D >nul
    attrib -A -S -H -I "!BOOTMOUNTDIR!\sources\license\!LANGUAGE%%j!" /S /D >nul
    call :EAfonts %%j
   )
  )
)
if %WINPE%==1 (
echo.
echo ============================================================
echo Update language settings
echo ============================================================
echo.
dism.exe /Quiet /ScratchDir:"%DISMTEMPDIR%" /Image:"%BOOTMOUNTDIR%" /Set-AllIntl:%DEFAULTLANGUAGE%
dism.exe /Quiet /ScratchDir:"%DISMTEMPDIR%" /Image:"%BOOTMOUNTDIR%" /Set-SKUIntlDefaults:%DEFAULTLANGUAGE%
dism.exe /Quiet /ScratchDir:"%DISMTEMPDIR%" /Image:"%BOOTMOUNTDIR%" /Gen-LangINI /Distribution:"%BOOTMOUNTDIR%"
dism.exe /Quiet /ScratchDir:"%DISMTEMPDIR%" /Image:"%BOOTMOUNTDIR%" /Set-SetupUILang:%DEFAULTLANGUAGE% /Distribution:"%BOOTMOUNTDIR%"
)
call :cleanup "%BOOTMOUNTDIR%"
echo.
echo ============================================================
echo Unmount boot.wim - index 2/2
echo ============================================================
dism.exe /ScratchDir:"%DISMTEMPDIR%" /Unmount-Wim /MountDir:"%BOOTMOUNTDIR%" /Commit
if errorlevel 1 goto :E_UNMOUNT
echo.
echo ============================================================
echo Rebuild boot.wim
echo ============================================================
"%~dp0bin\imagex.exe" /BOOT /EXPORT "%DVDDIR%\sources\boot.wim" * "%DVDDIR%\boot.wim"
if exist "%DVDDIR%\boot.wim" move /y "%DVDDIR%\boot.wim" "%DVDDIR%\sources" >nul
echo.
echo ============================================================
echo Rebuild install.wim
echo ============================================================
"%~dp0bin\imagex.exe" /EXPORT "%DVDDIR%\sources\install.wim" * "%DVDDIR%\install.wim"
if exist "%DVDDIR%\install.wim" move /y "%DVDDIR%\install.wim" "%DVDDIR%\sources" >nul
if exist "%DVDDIR%\sources\*.clg" del /f /q "%DVDDIR%\sources\*.clg" >nul
if %SLIM%==1 (
echo.
echo ============================================================
echo Clean ISO payload
echo ============================================================
echo.
del /f /s /q "%DVDDIR%\ch*_boot.ttf" >nul 2>&1
del /f /s /q "%DVDDIR%\jpn_boot.ttf" >nul 2>&1
del /f /s /q "%DVDDIR%\kor_boot.ttf" >nul 2>&1
del /f /q "%DVDDIR%\efi\microsoft\boot\cdboot_noprompt.efi" >nul 2>&1
del /f /q "%DVDDIR%\efi\microsoft\boot\efisys_noprompt.bin" >nul 2>&1
del /f /q "%DVDDIR%\autorun.inf" >nul 2>&1
del /f /q "%DVDDIR%\setup.exe" >nul 2>&1
if exist "%DVDDIR%\sources\ei.cfg" move /y "%DVDDIR%\sources\ei.cfg" "%DVDDIR%" >nul 2>&1
if exist "%DVDDIR%\sources\pid.txt" move /y "%DVDDIR%\sources\pid.txt" "%DVDDIR%" >nul 2>&1
move /y "%DVDDIR%\sources\boot.wim" "%DVDDIR%" >nul 2>&1
move /y "%DVDDIR%\sources\install.wim" "%DVDDIR%" >nul 2>&1
move /y "%DVDDIR%\sources\lang.ini" "%DVDDIR%" >nul 2>&1
move /y "%DVDDIR%\sources\setup.exe" "%DVDDIR%" >nul 2>&1
rmdir /s /q "%DVDDIR%\sources" >nul 2>&1
rmdir /s /q "%DVDDIR%\support" >nul 2>&1
rmdir /s /q "%DVDDIR%\upgrade" >nul 2>&1
mkdir "%DVDDIR%\sources" >nul 2>&1
if exist "%DVDDIR%\ei.cfg" move /y "%DVDDIR%\ei.cfg" "%DVDDIR%\sources" >nul 2>&1
if exist "%DVDDIR%\pid.txt" move /y "%DVDDIR%\pid.txt" "%DVDDIR%\sources" >nul 2>&1
move /y "%DVDDIR%\boot.wim" "%DVDDIR%\sources" >nul 2>&1
move /y "%DVDDIR%\install.wim" "%DVDDIR%\sources" >nul 2>&1
move /y "%DVDDIR%\lang.ini" "%DVDDIR%\sources" >nul 2>&1
move /y "%DVDDIR%\setup.exe" "%DVDDIR%\sources" >nul 2>&1
)
if %ISO%==0 (set MESSAGE=Done. You need to create iso file yourself&goto :E_CREATEISO)
echo.
echo ============================================================
echo Create ISO file
echo ============================================================
if exist "%DVDDIR%\efi\microsoft\boot\efisys.bin" (
   "%~dp0bin\cdimage.exe" -bootdata:2#p0,e,b"%DVDDIR%\boot\etfsboot.com"#pEF,e,b"%DVDDIR%\efi\microsoft\boot\efisys.bin" -o -h -u2 -udfver102 -m -l"%DVDLABEL%" "%DVDDIR%" "%DVDISO%"
) else (
   "%~dp0bin\cdimage.exe" -b"%DVDDIR%\boot\etfsboot.com" -o -h -u2 -udfver102 -m -l"%DVDLABEL%" "%DVDDIR%" "%DVDISO%"
)
if errorlevel 1 (set MESSAGE=ERROR: Could not create "%DVDISO%"&goto :E_CREATEISO)
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
set MESSAGE=ERROR: Required %ERRFILE% is missing in "bin" folder
goto :END

:E_DVD
call :remove
set MESSAGE=ERROR: Could not find the distribution
goto :END

:E_WIM
call :remove
set MESSAGE=ERROR: Could not find install.wim file in \sources folder
goto :END

:E_FILES
call :remove
set MESSAGE=ERROR: Could not detect any file in "langs" folder
goto :END

:E_ARCH
call :remove
set MESSAGE=ERROR: None of detected LangPacks match any of WIM images architecture
goto :END

:E_SP1
call :remove
set MESSAGE=ERROR: %ERRFILE% is not a valid Windows 7 SP1 LangPack
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

:E_CREATEISO
echo.
echo ============================================================
echo Remove temporary directories
echo ============================================================
echo.
if exist "%TEMPDIR%" (rmdir /s /q "%TEMPDIR%" 1>nul 2>nul || goto :E_DELDIR)
if exist "%MOUNTDIR%" (rmdir /s /q "%MOUNTDIR%" 1>nul 2>nul || goto :E_DELDIR)
goto :END

:remove
if exist "%DVDDIR%" (rmdir /s /q "%DVDDIR%" 1>nul 2>nul || goto :E_DELDIR)
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

:ISOmui
"%_7z%" e "%TEMPDIR%\!LANGUAGE%1!-!LPARCH%1!.cab" -o"%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!" erofflps.txt -r -aos >nul 2>&1
"%_7z%" e "%TEMPDIR%\!LANGUAGE%1!-!LPARCH%1!.cab" -o"%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!" oobe_help_opt_in_details.rtf -r -aos >nul 2>&1
"%_7z%" e "%TEMPDIR%\!LANGUAGE%1!-!LPARCH%1!.cab" -o"%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!" privacy.rtf -r -aos >nul 2>&1
"%_7z%" e "%TEMPDIR%\!LANGUAGE%1!-!LPARCH%1!.cab" -o"%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\mig" migautoplay.exe.mui -r -aos >nul 2>&1
"%_7z%" e "%TEMPDIR%\!LANGUAGE%1!-!LPARCH%1!.cab" -o"%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\mig" migres.dll.mui -r -aos >nul 2>&1
"%_7z%" e "%TEMPDIR%\!LANGUAGE%1!-!LPARCH%1!.cab" -o"%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\mig" migsetup.exe.mui -r -aos >nul 2>&1
"%_7z%" e "%TEMPDIR%\!LANGUAGE%1!-!LPARCH%1!.cab" -o"%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\mig" migwiz.exe.mui -r -aos >nul 2>&1
"%_7z%" e "%TEMPDIR%\!LANGUAGE%1!-!LPARCH%1!.cab" -o"%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\mig" postmig.exe.mui -r -aos >nul 2>&1
"%_7z%" e "%TEMPDIR%\!LANGUAGE%1!-!LPARCH%1!.cab" -o"%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\mig" wet.dll.mui -r -aos >nul 2>&1
xcopy "%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\sp1\setup\sources\!LANGUAGE%1!\*" "%DVDDIR%\sources\!LANGUAGE%1!" /cheryi >nul 2>&1
xcopy "%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\sp1\sources\license\!LANGUAGE%1!\*" "%DVDDIR%\sources\license\!LANGUAGE%1!" /cheryi >nul 2>&1
rmdir /s /q "%DVDDIR%\sources\!LANGUAGE%1!\dlmanifests" >nul 2>&1
rmdir /s /q "%DVDDIR%\sources\!LANGUAGE%1!\etwproviders" >nul 2>&1
rmdir /s /q "%DVDDIR%\sources\!LANGUAGE%1!\replacementmanifests" >nul 2>&1
mkdir "%DVDDIR%\sources\dlmanifests\!LANGUAGE%1!"
mkdir "%DVDDIR%\sources\replacementmanifests\!LANGUAGE%1!"
xcopy "%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\sp1\setup\sources\!LANGUAGE%1!\dlmanifests\microsoft-windows-iasserver-migplugin\*" "%DVDDIR%\sources\dlmanifests\microsoft-windows-iasserver-migplugin\!LANGUAGE%1!\" /chryi >nul 2>&1
xcopy "%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\sp1\setup\sources\!LANGUAGE%1!\dlmanifests\microsoft-windows-storagemigration\*" "%DVDDIR%\sources\dlmanifests\microsoft-windows-storagemigration\!LANGUAGE%1!\" /chryi >nul 2>&1
xcopy "%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\sp1\setup\sources\!LANGUAGE%1!\etwproviders\*" "%DVDDIR%\sources\etwproviders\!LANGUAGE%1!\" /chryi >nul 2>&1
xcopy "%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\sp1\setup\sources\!LANGUAGE%1!\etwproviders\*" "%DVDDIR%\support\logging\!LANGUAGE%1!\" /chryi >nul 2>&1
xcopy "%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\sp1\setup\sources\!LANGUAGE%1!\replacementmanifests\microsoft-windows-offlinefiles-core\*" "%DVDDIR%\sources\replacementmanifests\microsoft-windows-offlinefiles-core\!LANGUAGE%1!\" /chryi >nul 2>&1
copy "%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\erofflps.txt" "%DVDDIR%\sources\!LANGUAGE%1!" >nul 2>&1
copy "%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\oobe_help_opt_in_details.rtf" "%DVDDIR%\sources\!LANGUAGE%1!" >nul 2>&1
copy "%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\privacy.rtf" "%DVDDIR%\sources\!LANGUAGE%1!" >nul 2>&1
xcopy "%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\mig\*" "%DVDDIR%\support\migwiz\!LANGUAGE%1!" /chryi >nul 2>&1
copy "%DVDDIR%\sources\!LANGUAGE%1!\input.dll.mui" "%DVDDIR%\support\migwiz\!LANGUAGE%1!" >nul 2>&1
attrib -A -S -H -I "%DVDDIR%\sources\!LANGUAGE%1!" /S /D >nul 2>&1
attrib -A -S -H -I "%DVDDIR%\sources\license\!LANGUAGE%1!" /S /D >nul 2>&1
attrib -A -S -H -I "%DVDDIR%\support\migwiz\!LANGUAGE%1!" /S /D >nul 2>&1
goto :eof

:EAfonts
    if /i !LANGUAGE%1!==ja-jp (
    echo.
    echo ============================================================
    echo Add Font Support: !LANGUAGE%1!
    echo ============================================================
    echo.
    copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\jpn_boot.ttf" "!BOOTMOUNTDIR!\Windows\Boot\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\meiryo.ttc" "!BOOTMOUNTDIR!\Windows\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\msgothic.ttc" "!BOOTMOUNTDIR!\Windows\Fonts" >nul&reg load HKLM\OFFLINE "!BOOTMOUNTDIR!\Windows\System32\config\SOFTWARE" >nul&reg import "%~dp0bin\EA\ja-jp.reg" >nul&reg unload HKLM\OFFLINE >nul
    )
    if /i !LANGUAGE%1!==ko-kr (
    echo.
    echo ============================================================
    echo Add Font Support: !LANGUAGE%1!
    echo ============================================================
    echo.
    copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\kor_boot.ttf" "!BOOTMOUNTDIR!\Windows\Boot\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\malgun.ttf" "!BOOTMOUNTDIR!\Windows\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\gulim.ttc" "!BOOTMOUNTDIR!\Windows\Fonts" >nul&reg load HKLM\OFFLINE "!BOOTMOUNTDIR!\Windows\System32\config\SOFTWARE" >nul&reg import "%~dp0bin\EA\ko-kr.reg" >nul&reg unload HKLM\OFFLINE >nul
    )
    if /i !LANGUAGE%1!==zh-cn (
    echo.
    echo ============================================================
    echo Add Font Support: !LANGUAGE%1!
    echo ============================================================
    echo.
    copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\chs_boot.ttf" "!BOOTMOUNTDIR!\Windows\Boot\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\msyh.ttf" "!BOOTMOUNTDIR!\Windows\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\mingliu.ttc" "!BOOTMOUNTDIR!\Windows\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\simsun.ttc" "!BOOTMOUNTDIR!\Windows\Fonts" >nul&reg load HKLM\OFFLINE "!BOOTMOUNTDIR!\Windows\System32\config\SOFTWARE" >nul&reg import "%~dp0bin\EA\zh-cn.reg" >nul&reg unload HKLM\OFFLINE >nul
    )
    if /i !LANGUAGE%1!==zh-hk (
    echo.
    echo ============================================================
    echo Add Font Support: !LANGUAGE%1!
    echo ============================================================
    echo.
    copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\cht_boot.ttf" "!BOOTMOUNTDIR!\Windows\Boot\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\msjh.ttf" "!BOOTMOUNTDIR!\Windows\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\mingliu.ttc" "!BOOTMOUNTDIR!\Windows\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\simsun.ttc" "!BOOTMOUNTDIR!\Windows\Fonts" >nul&reg load HKLM\OFFLINE "!BOOTMOUNTDIR!\Windows\System32\config\SOFTWARE" >nul&reg import "%~dp0bin\EA\zh-hk.reg" >nul&reg unload HKLM\OFFLINE >nul
    )
    if /i !LANGUAGE%1!==zh-tw (
    echo.
    echo ============================================================
    echo Add Font Support: !LANGUAGE%1!
    echo ============================================================
    echo.
    copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\cht_boot.ttf" "!BOOTMOUNTDIR!\Windows\Boot\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\msjh.ttf" "!BOOTMOUNTDIR!\Windows\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\mingliu.ttc" "!BOOTMOUNTDIR!\Windows\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\simsun.ttc" "!BOOTMOUNTDIR!\Windows\Fonts" >nul&reg load HKLM\OFFLINE "!BOOTMOUNTDIR!\Windows\System32\config\SOFTWARE" >nul&reg import "%~dp0bin\EA\zh-tw.reg" >nul&reg unload HKLM\OFFLINE >nul
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