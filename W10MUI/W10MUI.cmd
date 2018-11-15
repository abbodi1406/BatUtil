@echo off

set DVDPATH=
set ISO=1
set WINPE=1
set SLIM=1
set NET35=0

set WINPEPATH=

set DEFAULTLANGUAGE=
set MOUNTDIR=

rem ##################################################################
rem # NORMALY THERE IS NO NEED TO CHANGE ANYTHING BELOW THIS COMMENT #
rem ##################################################################

title Windows 10 LangPacks Integrator
%windir%\system32\reg.exe query "HKU\S-1-5-19" 1>nul 2>nul || goto :E_ADMIN
cd /d "%~dp0"
set "WORKDIR=%cd%"
set "DVDDIR=%WORKDIR%\_DVD"
set "TEMPDIR=%WORKDIR%\TEMP"
if "%MOUNTDIR%"=="" set "MOUNTDIR=%SystemDrive%\W10MUIMOUNT"
set "DISMTEMPDIR=%TEMPDIR%\scratch"
set "EXTRACTDIR=%TEMPDIR%\extract"
set "INSTALLMOUNTDIR=%MOUNTDIR%\install"
set "WINREMOUNTDIR=%MOUNTDIR%\winre"
set "BOOTMOUNTDIR=%MOUNTDIR%\boot"
set EAlang=(ja-jp,ko-kr,zh-cn,zh-hk,zh-tw)
set _mui=(appraiser.dll.mui,arunres.dll.mui,cmisetup.dll.mui,compatctrl.dll.mui,compatprovider.dll.mui,diagtrack.dll.mui,dism.exe.mui,dismapi.dll.mui,dismcore.dll.mui,dismprov.dll.mui,folderprovider.dll.mui,imagingprovider.dll.mui,input.dll.mui,logprovider.dll.mui,mediasetupuimgr.dll.mui,nlsbres.dll.mui,pnpibs.dll.mui,reagent.adml,reagent.dll.mui,rollback.exe.mui,setup.exe.mui,setupcompat.dll.mui,setupcore.dll.mui,setupplatform.exe.mui,setupprep.exe.mui,smiengine.dll.mui,spwizres.dll.mui,upgloader.dll.mui,uxlibres.dll.mui,vhdprovider.dll.mui,w32uires.dll.mui,wdsclient.dll.mui,wdsimage.dll.mui,wimprovider.dll.mui,windlp.dll.mui,winsetup.dll.mui)

if not "%DVDPATH%"=="" goto :check
set _iso=0
if exist "*.iso" (for /f "delims=" %%i in ('dir /b *.iso') do (call set /a _iso+=1))
if not %_iso%==1 goto :prompt
for /f "delims=" %%i in ('dir /b *.iso') do set "DVDPATH=%%i"
goto :check

:prompt
echo.
echo ============================================================
echo Enter the distribution path ^(without quotes marks ""^):
echo ISO file^, Extracted ISO folder^, DVD/USB drive letter
echo ============================================================
echo.
set /p "DVDPATH="
if "%DVDPATH%"=="" set MESSAGE=ERROR: no source distribution specified&goto :END
goto :check

:check
SET regKeyPathFound=1
SET wowRegKeyPathFound=1
REG QUERY "HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 1>NUL 2>NUL || SET wowRegKeyPathFound=0
REG QUERY "HKLM\Software\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 1>NUL 2>NUL || SET regKeyPathFound=0
if %wowRegKeyPathFound% EQU 0 (
  if %regKeyPathFound% EQU 0 (
    goto :skip
  ) else (
    SET regKeyPath=HKLM\Software\Microsoft\Windows Kits\Installed Roots
  )
) else (
    SET regKeyPath=HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots
)
FOR /F "skip=2 tokens=2*" %%i IN ('REG QUERY "%regKeyPath%" /v KitsRoot10') DO (SET "KitsRoot=%%j")
SET "WinPERoot=%KitsRoot%Assessment and Deployment Kit\Windows Preinstallation Environment"
SET "DandIRoot=%KitsRoot%Assessment and Deployment Kit\Deployment Tools"
SET "DISMRoot=%DandIRoot%\%PROCESSOR_ARCHITECTURE%\DISM\dism.exe"
if not exist "%DISMRoot%" goto :skip
goto :prepare

:skip
set "DISMRoot=%~dp0dism\dism.exe"
if /i "%PROCESSOR_ARCHITECTURE%" equ "AMD64" set "DISMRoot=%~dp0dism\dism64\dism.exe"
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G
if %winbuild% GEQ 10240 SET "DISMRoot=%windir%\system32\dism.exe"

:prepare
if not "%WINPEPATH%"=="" SET "WinPERoot=%WINPEPATH%"
if not exist "%WinPERoot%\amd64\WinPE_OCs\*" if not exist "%WinPERoot%\x86\WinPE_OCs\*" set WINPE=0
SET "_7z=%~dp0dism\7z.exe"
if not exist "%_7z%" goto :E_BIN
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
set "LPFILE%count%=%1"
goto :eof

:setcounta
set /a count+=1
set "OAFILE%count%=%1"
goto :eof

:setcountb
set /a count+=1
set "OBFILE%count%=%1"
goto :eof

:setarch
set /a count+=1
for /f "tokens=2 delims=: " %%i in ('dism\dism.exe /english /get-wiminfo /wimfile:"%DVDDIR%\sources\install.wim" /index:%1 ^| find /i "Architecture"') do set "WIMARCH%count%=%%i"
goto :eof

:start
echo.
echo ============================================================
echo Detect language packs details
echo ============================================================
echo.
set _c=0
if exist ".\langs\*.cab" (for /f %%i in ('dir /b ".\langs\*.cab"') do (call set /a _c+=1))
if exist ".\langs\*.esd" (for /f %%i in ('dir /b ".\langs\*.esd"') do (call set /a _c+=1))
if %_c% equ 0 goto :E_FILES
set LANGUAGES=%_c%
if exist ".\langs\*.cab" (for /f %%i in ('dir /b /o:n ".\langs\*.cab"') do call :setcount %%i)
if exist ".\langs\*.esd" (for /f %%i in ('dir /b /o:n ".\langs\*.esd"') do call :setcount %%i)

set /a count=0
set _oa=0
if exist ".\ondemand\x86\*.cab" (for /f %%i in ('dir /b ".\ondemand\x86\*.cab"') do (call set /a _oa+=1))
if %_oa% neq 0 (for /f %%i in ('dir /b /o:n ".\ondemand\x86\*.cab"') do (call :setcounta %%i))

set /a count=0
set _ob=0
if exist ".\ondemand\x64\*.cab" (for /f %%i in ('dir /b ".\ondemand\x64\*.cab"') do (call set /a _ob+=1))
if %_ob% neq 0 (for /f %%i in ('dir /b /o:n ".\ondemand\x64\*.cab"') do (call :setcountb %%i))

for /L %%j in (1, 1, %LANGUAGES%) do (
"%_7z%" e ".\langs\!LPFILE%%j!" -o"%EXTRACTDIR%" langcfg.ini >nul
for /f "tokens=2 delims==" %%i in ('type "%EXTRACTDIR%\langcfg.ini" ^| findstr /i "Language"') do set "LANGUAGE%%j=%%i"
del /f /q "%EXTRACTDIR%\langcfg.ini"
"%_7z%" e ".\langs\!LPFILE%%j!" -o"%EXTRACTDIR%" Microsoft-Windows-Common-Foundation-Package*10.*.mum 1>nul 2>nul
if not exist "%EXTRACTDIR%\*.mum" set "ERRFILE=!LPFILE%%j!"&goto :E_LP
for /f "tokens=7 delims=~." %%g in ('"dir "%EXTRACTDIR%\*.mum" /b" 2^>nul') do set "LPBUILD%%j=%%g"
for /f "tokens=3 delims=~" %%V in ('"dir "%EXTRACTDIR%\*.mum" /b" 2^>nul') do set "LPARCH%%j=%%V"
del /f /q "%EXTRACTDIR%\*.mum" 1>nul 2>nul
)
for /L %%j in (1, 1, %LANGUAGES%) do (
if /i !LPARCH%%j!==amd64 (echo !LANGUAGE%%j!: 64-bit {x64} - !LPBUILD%%j!) else (echo !LANGUAGE%%j!: 32-bit {x86} - !LPBUILD%%j!)
set "WinpeOC%%j=%WinPERoot%\!LPARCH%%j!\WinPE_OCs"
)
for /L %%j in (1, 1, %LANGUAGES%) do (
if not exist "!WinpeOC%%j!\!LANGUAGE%%j!\lp.cab" set WINPE=0
)
set _ODbasic86=
set _ODfont86=
set _ODhand86=
set _ODocr86=
set _ODspeech86=
set _ODtts86=
set _ODintl86=
if %_oa% neq 0 for /L %%j in (1, 1, %_oa%) do (
"%_7z%" x ".\ondemand\x86\!OAFILE%%j!" -o"%TEMPDIR%\FOD86\OAFILE%%j" * -r >nul
findstr /i /m "Microsoft-Windows-LanguageFeatures-Basic" "%TEMPDIR%\FOD86\OAFILE%%j\update.mum" 1>nul 2>nul && call set _ODbasic86=!_ODbasic86! /PackagePath:"%TEMPDIR%\FOD86\OAFILE%%j\update.mum"
findstr /i /m "Microsoft-Windows-LanguageFeatures-Fonts" "%TEMPDIR%\FOD86\OAFILE%%j\update.mum" 1>nul 2>nul && call set _ODfont86=!_ODfont86! /PackagePath:"%TEMPDIR%\FOD86\OAFILE%%j\update.mum"
findstr /i /m "Microsoft-Windows-LanguageFeatures-Handwriting" "%TEMPDIR%\FOD86\OAFILE%%j\update.mum" 1>nul 2>nul && call set _ODhand86=!_ODhand86! /PackagePath:"%TEMPDIR%\FOD86\OAFILE%%j\update.mum"
findstr /i /m "Microsoft-Windows-LanguageFeatures-OCR" "%TEMPDIR%\FOD86\OAFILE%%j\update.mum" 1>nul 2>nul && call set _ODocr86=!_ODocr86! /PackagePath:"%TEMPDIR%\FOD86\OAFILE%%j\update.mum"
findstr /i /m "Microsoft-Windows-LanguageFeatures-Speech" "%TEMPDIR%\FOD86\OAFILE%%j\update.mum" 1>nul 2>nul && call set _ODspeech86=!_ODspeech86! /PackagePath:"%TEMPDIR%\FOD86\OAFILE%%j\update.mum"
findstr /i /m "Microsoft-Windows-LanguageFeatures-TextToSpeech" "%TEMPDIR%\FOD86\OAFILE%%j\update.mum" 1>nul 2>nul && call set _ODtts86=!_ODtts86! /PackagePath:"%TEMPDIR%\FOD86\OAFILE%%j\update.mum"
findstr /i /m "Microsoft-Windows-InternationalFeatures" "%TEMPDIR%\FOD86\OAFILE%%j\update.mum" 1>nul 2>nul && call set _ODintl86=!_ODintl86! /PackagePath:"%TEMPDIR%\FOD86\OAFILE%%j\update.mum"
)
set _ODbasic64=
set _ODfont64=
set _ODhand64=
set _ODocr64=
set _ODspeech64=
set _ODtts64=
set _ODintl64=
if %_ob% neq 0 for /L %%j in (1, 1, %_ob%) do (
"%_7z%" x ".\ondemand\x64\!OBFILE%%j!" -o"%TEMPDIR%\FOD64\OBFILE%%j" * -r >nul
findstr /i /m "Microsoft-Windows-LanguageFeatures-Basic" "%TEMPDIR%\FOD64\OBFILE%%j\update.mum" 1>nul 2>nul && call set _ODbasic64=!_ODbasic64! /PackagePath:"%TEMPDIR%\FOD64\OBFILE%%j\update.mum"
findstr /i /m "Microsoft-Windows-LanguageFeatures-Fonts" "%TEMPDIR%\FOD64\OBFILE%%j\update.mum" 1>nul 2>nul && call set _ODfont64=!_ODfont64! /PackagePath:"%TEMPDIR%\FOD64\OBFILE%%j\update.mum"
findstr /i /m "Microsoft-Windows-LanguageFeatures-Handwriting" "%TEMPDIR%\FOD64\OBFILE%%j\update.mum" 1>nul 2>nul && call set _ODhand64=!_ODhand64! /PackagePath:"%TEMPDIR%\FOD64\OBFILE%%j\update.mum"
findstr /i /m "Microsoft-Windows-LanguageFeatures-OCR" "%TEMPDIR%\FOD64\OBFILE%%j\update.mum" 1>nul 2>nul && call set _ODocr64=!_ODocr64! /PackagePath:"%TEMPDIR%\FOD64\OBFILE%%j\update.mum"
findstr /i /m "Microsoft-Windows-LanguageFeatures-Speech" "%TEMPDIR%\FOD64\OBFILE%%j\update.mum" 1>nul 2>nul && call set _ODspeech64=!_ODspeech64! /PackagePath:"%TEMPDIR%\FOD64\OBFILE%%j\update.mum"
findstr /i /m "Microsoft-Windows-LanguageFeatures-TextToSpeech" "%TEMPDIR%\FOD64\OBFILE%%j\update.mum" 1>nul 2>nul && call set _ODtts64=!_ODtts64! /PackagePath:"%TEMPDIR%\FOD64\OBFILE%%j\update.mum"
findstr /i /m "Microsoft-Windows-InternationalFeatures" "%TEMPDIR%\FOD64\OBFILE%%j\update.mum" 1>nul 2>nul && call set _ODintl64=!_ODintl64! /PackagePath:"%TEMPDIR%\FOD64\OBFILE%%j\update.mum"
)
echo.
echo ============================================================
echo Copy Distribution contents to work directory
echo ============================================================
echo.
echo Source Path:
echo "%DVDPATH%"
echo %DVDPATH%| findstr /E /I "\.iso" >nul && (
   "%_7z%" x "%DVDPATH%" -o"%DVDDIR%" * -r >nul
) || (
   %windir%\system32\robocopy.exe "%DVDPATH%" "%DVDDIR%" /E /A-:R >nul
)
if not exist "%DVDDIR%\sources\sxs\*netfx3*.cab" set NET35=0
if not exist "%DVDDIR%\sources\install.wim" goto :E_WIM
dism\imagex.exe /info "%DVDDIR%\sources\install.wim" | findstr /c:"LZMS" >nul && goto :E_ESD
for /f "tokens=2 delims=: " %%i in ('dism\dism.exe /english /get-wiminfo /wimfile:"%DVDDIR%\sources\install.wim" ^| findstr "Index"') do set VERSIONS=%%i
for /f "tokens=4 delims=:. " %%i in ('dism\dism.exe /english /get-wiminfo /wimfile:"%DVDDIR%\sources\install.wim" /index:1 ^| find /i "Version :"') do set build=%%i
for /L %%j in (1, 1, %LANGUAGES%) do (
if not !LPBUILD%%j!==%build% set "ERRFILE=!LPFILE%%j!"&goto :E_VER
)
if %WINPE%==1 for /L %%j in (1, 1, %LANGUAGES%) do (
"%_7z%" e "!WinpeOC%%j!\!LANGUAGE%%j!\lp.cab" -o"%EXTRACTDIR%" Microsoft-Windows-Common-Foundation-Package*%build%*.mum 1>nul 2>nul
if not exist "%EXTRACTDIR%\*.mum" set WINPE=0
)
if "%DEFAULTLANGUAGE%"=="" (
for /f "tokens=1" %%i in ('dism\dism.exe /english /get-wiminfo /wimfile:"%DVDDIR%\sources\install.wim" /index:1 ^| find /i "Default"') do set "DEFAULTLANGUAGE=%%i"
)
for /f "tokens=2 delims=: " %%i in ('dism\dism.exe /english /get-wiminfo /wimfile:"%DVDDIR%\sources\boot.wim" ^| findstr "Index"') do set BOOTCOUNT=%%i
for /f "tokens=2 delims=: " %%i in ('dism\dism.exe /english /get-wiminfo /wimfile:"%DVDDIR%\sources\boot.wim" /index:1 ^| find /i "Architecture"') do set BOOTARCH=%%i
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
if %errorlevel%==0 (set wimbit=32&set DVDISO=mu_windows_10_%build%_x86&set DVDLABEL=CCSA_X86FRE_MUI_DV5&set _label86=1)

%windir%\system32\findstr.exe /i /v "x86" "%TEMPDIR%\WIMARCH.txt" >nul
if %errorlevel%==0 (
if %_label86%==1 (set wimbit=dual&set DVDISO=mu_windows_10_%build%_x86_x64&set DVDLABEL=CCSA_X86X64FRE_MUI_DV5) else (set wimbit=64&set DVDISO=mu_windows_10_%build%_x64&set DVDLABEL=CCSA_X64FRE_MUI_DV5)
)
echo Build: %build%
echo Count: %VERSIONS% Image^(s^)
if %wimbit%==dual (echo Arch : Multi) else (echo Arch : %wimbit%-bit)
if %wimbit%==dual set NET35=0

if %WINPE% NEQ 1 goto :extract
set _PEM86=
set _PES86=
set _PEX86=
set _PEF86=
set _PER86=
set _PEM64=
set _PES64=
set _PEX64=
set _PEF64=
set _PER64=
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
call set _PER86=!_PER86! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-HTA_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Rejuv_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-StorageWMI_!LANGUAGE%%j!.cab"
call set _PEX86=!_PEX86! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-EnhancedStorage_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Scripting_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-SecureStartup_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-WDS-Tools_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-WMI_!LANGUAGE%%j!.cab"
 for %%G in %EAlang% do (
 if /i !LANGUAGE%%j!==%%G call set _PEF86=!_PEF86! /PackagePath:"!WinpeOC%%j!\WinPE-FontSupport-%%G.cab"
 )
)
)
if %wimbit%==64 for /L %%j in (1, 1, %LANGUAGES%) do (
if /i !LPARCH%%j!==amd64 (
echo !LANGUAGE%%j! / 64-bit
call set _PEM64=!_PEM64! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\lp.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-SRT_!LANGUAGE%%j!.cab"
call set _PES64=!_PES64! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Setup_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Setup-Client_!LANGUAGE%%j!.cab"
call set _PER64=!_PER64! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-HTA_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Rejuv_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-StorageWMI_!LANGUAGE%%j!.cab"
call set _PEX64=!_PEX64! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-EnhancedStorage_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Scripting_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-SecureStartup_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-WDS-Tools_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-WMI_!LANGUAGE%%j!.cab"
 for %%G in %EAlang% do (
 if /i !LANGUAGE%%j!==%%G call set _PEF64=!_PEF64! /PackagePath:"!WinpeOC%%j!\WinPE-FontSupport-%%G.cab"
 )
)
)
if %wimbit%==dual for /L %%j in (1, 1, %LANGUAGES%) do (
if /i !LPARCH%%j!==x86 (
echo !LANGUAGE%%j! / 32-bit
call set _PEM86=!_PEM86! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\lp.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-SRT_!LANGUAGE%%j!.cab"
call set _PES86=!_PES86! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Setup_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Setup-Client_!LANGUAGE%%j!.cab"
call set _PER86=!_PER86! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-HTA_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Rejuv_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-StorageWMI_!LANGUAGE%%j!.cab"
call set _PEX86=!_PEX86! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-EnhancedStorage_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Scripting_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-SecureStartup_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-WDS-Tools_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-WMI_!LANGUAGE%%j!.cab"
 for %%G in %EAlang% do (
 if /i !LANGUAGE%%j!==%%G call set _PEF86=!_PEF86! /PackagePath:"!WinpeOC%%j!\WinPE-FontSupport-%%G.cab"
 )
) else (
echo !LANGUAGE%%j! / 64-bit
call set _PEM64=!_PEM64! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\lp.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-SRT_!LANGUAGE%%j!.cab"
call set _PES64=!_PES64! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Setup_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Setup-Client_!LANGUAGE%%j!.cab"
call set _PER64=!_PER64! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-HTA_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Rejuv_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-StorageWMI_!LANGUAGE%%j!.cab"
call set _PEX64=!_PEX64! /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-EnhancedStorage_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-Scripting_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-SecureStartup_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-WDS-Tools_!LANGUAGE%%j!.cab" /PackagePath:"!WinpeOC%%j!\!LANGUAGE%%j!\WinPE-WMI_!LANGUAGE%%j!.cab"
 for %%G in %EAlang% do (
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
"%_7z%" e ".\langs\!LPFILE%%j!" -o"%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" vofflps.rtf -r -aos >nul
"%_7z%" x ".\langs\!LPFILE%%j!" -o"%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" *setup\sources -r >nul
"%_7z%" x ".\langs\!LPFILE%%j!" -o"%TEMPDIR%\!LPARCH%%j!\!LANGUAGE%%j!" * -r >nul
if not exist "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\setup\sources\!LANGUAGE%%j!\*.mui" (robocopy "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\setup\sources" "!EXTRACTDIR!\TEMP\!LANGUAGE%%j!" /E /MOVE >nul&robocopy "!EXTRACTDIR!\TEMP\!LANGUAGE%%j!" "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\setup\sources\!LANGUAGE%%j!" /E /MOVE >nul) 
call set _PP86=!_PP86! /packagepath:"%TEMPDIR%\!LPARCH%%j!\!LANGUAGE%%j!\update.mum"
)
)
if %wimbit%==64 for /L %%j in (1, 1, %LANGUAGES%) do (
if /i !LPARCH%%j!==amd64 (
echo !LANGUAGE%%j! / 64-bit
"%_7z%" e ".\langs\!LPFILE%%j!" -o"%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" vofflps.rtf -r -aos >nul
"%_7z%" x ".\langs\!LPFILE%%j!" -o"%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" *setup\sources -r >nul
"%_7z%" x ".\langs\!LPFILE%%j!" -o"%TEMPDIR%\!LPARCH%%j!\!LANGUAGE%%j!" * -r >nul
if not exist "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\setup\sources\!LANGUAGE%%j!\*.mui" (robocopy "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\setup\sources" "!EXTRACTDIR!\TEMP\!LANGUAGE%%j!" /E /MOVE >nul&robocopy "!EXTRACTDIR!\TEMP\!LANGUAGE%%j!" "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\setup\sources\!LANGUAGE%%j!" /E /MOVE >nul) 
call set _PP64=!_PP64! /packagepath:"%TEMPDIR%\!LPARCH%%j!\!LANGUAGE%%j!\update.mum"
)
)
if %wimbit%==dual for /L %%j in (1, 1, %LANGUAGES%) do (
if /i !LPARCH%%j!==x86 (
echo !LANGUAGE%%j! / 32-bit
"%_7z%" e ".\langs\!LPFILE%%j!" -o"%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" vofflps.rtf -r -aos >nul
"%_7z%" x ".\langs\!LPFILE%%j!" -o"%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" *setup\sources -r >nul
"%_7z%" x ".\langs\!LPFILE%%j!" -o"%TEMPDIR%\!LPARCH%%j!\!LANGUAGE%%j!" * -r >nul
if not exist "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\setup\sources\!LANGUAGE%%j!\*.mui" (robocopy "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\setup\sources" "!EXTRACTDIR!\TEMP\!LANGUAGE%%j!" /E /MOVE >nul&robocopy "!EXTRACTDIR!\TEMP\!LANGUAGE%%j!" "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\setup\sources\!LANGUAGE%%j!" /E /MOVE >nul) 
call set _PP86=!_PP86! /packagepath:"%TEMPDIR%\!LPARCH%%j!\!LANGUAGE%%j!\update.mum"
) else (
echo !LANGUAGE%%j! / 64-bit
"%_7z%" e ".\langs\!LPFILE%%j!" -o"%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" vofflps.rtf -r -aos >nul
"%_7z%" x ".\langs\!LPFILE%%j!" -o"%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" *setup\sources -r >nul
"%_7z%" x ".\langs\!LPFILE%%j!" -o"%TEMPDIR%\!LPARCH%%j!\!LANGUAGE%%j!" * -r >nul
if not exist "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\setup\sources\!LANGUAGE%%j!\*.mui" (robocopy "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\setup\sources" "!EXTRACTDIR!\TEMP\!LANGUAGE%%j!" /E /MOVE >nul&robocopy "!EXTRACTDIR!\TEMP\!LANGUAGE%%j!" "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\setup\sources\!LANGUAGE%%j!" /E /MOVE >nul) 
call set _PP64=!_PP64! /packagepath:"%TEMPDIR%\!LPARCH%%j!\!LANGUAGE%%j!\update.mum"
)
)
if %wimbit%==32 if "!_PP86!"=="" goto :E_ARCH
if %wimbit%==64 if "!_PP64!"=="" goto :E_ARCH

for /L %%i in (1, 1, %VERSIONS%) do (
echo.
echo ============================================================
echo Mount install.wim - index %%i/%VERSIONS%
echo ============================================================
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Mount-Wim /Wimfile:"%DVDDIR%\sources\install.wim" /Index:%%i /MountDir:"%INSTALLMOUNTDIR%"
if errorlevel 1 goto :E_MOUNT
echo.
echo ============================================================
echo Add LPs to install.wim - index %%i/%VERSIONS%
echo ============================================================
if "!_PP64!" NEQ "" if /i !WIMARCH%%i!==amd64 (
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Image:"%INSTALLMOUNTDIR%" /Add-Package !_PP64!
)
if "!_ODbasic64!" NEQ "" if /i !WIMARCH%%i!==amd64 (
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Image:"%INSTALLMOUNTDIR%" /Add-Package !_ODbasic64! !_ODfont64! !_ODtts64! !_ODhand64! !_ODocr64! !_ODspeech64! !_ODintl64!
)
if "!_PP86!" NEQ "" if /i !WIMARCH%%i!==x86 (
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Image:"%INSTALLMOUNTDIR%" /Add-Package !_PP86!
)
if "!_ODbasic86!" NEQ "" if /i !WIMARCH%%i!==x86 (
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Image:"%INSTALLMOUNTDIR%" /Add-Package !_ODbasic86! !_ODfont86! !_ODtts86! !_ODhand86! !_ODocr86! !_ODspeech86! !_ODintl86!
)
echo.
echo ============================================================
echo Update language settings
echo ============================================================
echo.
"%DISMRoot%" /Quiet /ScratchDir:"%DISMTEMPDIR%" /Image:"%INSTALLMOUNTDIR%" /Set-AllIntl:%DEFAULTLANGUAGE%
"%DISMRoot%" /Quiet /ScratchDir:"%DISMTEMPDIR%" /Image:"%INSTALLMOUNTDIR%" /Set-SKUIntlDefaults:%DEFAULTLANGUAGE%
if %%i==%VERSIONS% (
"%DISMRoot%" /Quiet /ScratchDir:"%DISMTEMPDIR%" /Image:"%INSTALLMOUNTDIR%" /Gen-LangINI /Distribution:"%DVDDIR%"
"%DISMRoot%" /Quiet /ScratchDir:"%DISMTEMPDIR%" /Image:"%INSTALLMOUNTDIR%" /Set-SetupUILang:%DEFAULTLANGUAGE% /Distribution:"%DVDDIR%"
)
if %NET35%==1 if not exist "%INSTALLMOUNTDIR%\Windows\Microsoft.NET\Framework\v2.0.50727\ngen.exe" (
echo.
echo ============================================================
echo Enable .NET Framework 3.5 - index %%i/%VERSIONS%
echo ============================================================
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Image:"%INSTALLMOUNTDIR%" /Enable-Feature /Featurename:NetFx3 /All /LimitAccess /Source:"%DVDDIR%\sources\sxs"
)
if %%i==%VERSIONS% for /L %%j in (1, 1, %LANGUAGES%) do (
if /i !LANGUAGE%%j!==ja-jp xcopy "%INSTALLMOUNTDIR%\Windows\Boot\Fonts\*" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!\" /chryi >nul&if exist "%INSTALLMOUNTDIR%\Windows\Fonts\meiryo.ttc" (copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\meiryo.ttc" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" >nul)&if exist "%INSTALLMOUNTDIR%\Windows\Fonts\msgothic.ttc" (copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\msgothic.ttc" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" >nul)
if /i !LANGUAGE%%j!==ko-kr xcopy "%INSTALLMOUNTDIR%\Windows\Boot\Fonts\*" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!\" /chryi >nul&copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\malgun.ttf" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" >nul&if exist "%INSTALLMOUNTDIR%\Windows\Fonts\gulim.ttc" (copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\gulim.ttc" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" >nul)
if /i !LANGUAGE%%j!==zh-cn xcopy "%INSTALLMOUNTDIR%\Windows\Boot\Fonts\*" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!\" /chryi >nul&copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\msyh.ttc" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" >nul&copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\mingliub.ttc" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" >nul&copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\simsun.ttc" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" >nul&copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\msyhl.ttc" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" >nul
if /i !LANGUAGE%%j!==zh-hk xcopy "%INSTALLMOUNTDIR%\Windows\Boot\Fonts\*" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!\" /chryi >nul&copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\msjh.ttc" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" >nul&copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\mingliub.ttc" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" >nul&copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\simsun.ttc" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" >nul
if /i !LANGUAGE%%j!==zh-tw xcopy "%INSTALLMOUNTDIR%\Windows\Boot\Fonts\*" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!\" /chryi >nul&copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\msjh.ttc" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" >nul&copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\mingliub.ttc" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" >nul&copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\simsun.ttc" "%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" >nul
)
attrib -S -H -I "%INSTALLMOUNTDIR%\Windows\System32\Recovery\winre.wim" 1>nul 2>nul
if %WINPE%==1 if exist "%INSTALLMOUNTDIR%\Windows\System32\Recovery\winre.wim" if not exist "%TEMPDIR%\WR\!WIMARCH%%i!\winre.wim" (
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
  reg load HKLM\TEMPWIM "!WINREMOUNTDIR!\Windows\System32\Config\SOFTWARE" 1>nul 2>nul
  reg add HKLM\TEMPWIM\Microsoft\Windows\CurrentVersion\SideBySide\Configuration /v DisableComponentBackups /t REG_DWORD /d 1 /f 1>nul 2>nul
  reg add HKLM\TEMPWIM\Microsoft\Windows\CurrentVersion\SideBySide\Configuration /v SupersededActions /t REG_DWORD /d 1 /f 1>nul 2>nul
  reg unload HKLM\TEMPWIM 1>nul 2>nul
  if "!_PEM64!" NEQ "" if /i !WIMARCH%%i!==amd64 (
    "!DISMRoot!" /ScratchDir:"!DISMTEMPDIR!" /Image:"!WINREMOUNTDIR!" /Add-Package !_PEM64! !_PER64! !_PEF64!
    if !SLIM! NEQ 1 "!DISMRoot!" /ScratchDir:"!DISMTEMPDIR!" /Image:"!WINREMOUNTDIR!" /Add-Package !_PEX64!
  )
  if "!_PEM86!" NEQ "" if /i !WIMARCH%%i!==x86 (
    "!DISMRoot!" /ScratchDir:"!DISMTEMPDIR!" /Image:"!WINREMOUNTDIR!" /Add-Package !_PEM86! !_PER86! !_PEF86!
    if !SLIM! NEQ 1 "!DISMRoot!" /ScratchDir:"!DISMTEMPDIR!" /Image:"!WINREMOUNTDIR!" /Add-Package !_PEX86!
  )
  echo.
  echo ============================================================
  echo Update language settings
  echo ============================================================
  echo.
  "!DISMRoot!" /Quiet /ScratchDir:"!DISMTEMPDIR!" /Image:"!WINREMOUNTDIR!" /Set-AllIntl:!DEFAULTLANGUAGE!
  "!DISMRoot!" /Quiet /ScratchDir:"!DISMTEMPDIR!" /Image:"!WINREMOUNTDIR!" /Set-SKUIntlDefaults:!DEFAULTLANGUAGE!
  "!DISMRoot!" /Quiet /ScratchDir:"!DISMTEMPDIR!" /Image:"!WINREMOUNTDIR!" /Cleanup-Image /StartComponentCleanup
  "!DISMRoot!" /Quiet /ScratchDir:"!DISMTEMPDIR!" /Image:"!WINREMOUNTDIR!" /Cleanup-Image /StartComponentCleanup /ResetBase
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
  "!DISMRoot!" /ScratchDir:"!DISMTEMPDIR!" /Export-Image /SourceImageFile:"!TEMPDIR!\WR\!WIMARCH%%i!\winre.wim" /All /DestinationImageFile:"!EXTRACTDIR!\winre.wim"
  if exist "!EXTRACTDIR!\winre.wim" move /y "!EXTRACTDIR!\winre.wim" "!TEMPDIR!\WR\!WIMARCH%%i!" >nul
)
if %WINPE%==1 if exist "%TEMPDIR%\WR\!WIMARCH%%i!\winre.wim" (
  echo.
  echo ============================================================
  echo Add updated winre.wim to install.wim - index %%i/%VERSIONS%
  echo ============================================================
  echo.
  copy /y "%TEMPDIR%\WR\!WIMARCH%%i!\winre.wim" "%INSTALLMOUNTDIR%\Windows\System32\Recovery"
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
echo Mount boot.wim - index 1/%BOOTCOUNT%
echo ============================================================
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Mount-Wim /WimFile:"%DVDDIR%\sources\boot.wim" /Index:1 /MountDir:"%BOOTMOUNTDIR%"
if errorlevel 1 goto :E_MOUNT

if %BOOTCOUNT%==1 if not exist "%BOOTMOUNTDIR%\sources\setup.exe" set SLIM=0
if %WINPE%==1 (
  echo.
  echo ============================================================
  echo Add LPs to boot.wim - index 1/%BOOTCOUNT%
  echo ============================================================
  reg load HKLM\TEMPWIM "!BOOTMOUNTDIR!\Windows\System32\Config\SOFTWARE" 1>nul 2>nul
  reg add HKLM\TEMPWIM\Microsoft\Windows\CurrentVersion\SideBySide\Configuration /v DisableComponentBackups /t REG_DWORD /d 1 /f 1>nul 2>nul
  reg add HKLM\TEMPWIM\Microsoft\Windows\CurrentVersion\SideBySide\Configuration /v SupersededActions /t REG_DWORD /d 1 /f 1>nul 2>nul
  reg unload HKLM\TEMPWIM 1>nul 2>nul
  if "!_PEM64!" NEQ "" if /i !BOOTARCH!==amd64 (
    "!DISMRoot!" /ScratchDir:"!DISMTEMPDIR!" /Image:"!BOOTMOUNTDIR!" /Add-Package !_PEM64! !_PEF64!
    if exist "!BOOTMOUNTDIR!\Windows\servicing\Packages\WinPE-Rejuv-Package~31bf3856ad364e35~*.mum" "!DISMRoot!" /ScratchDir:"!DISMTEMPDIR!" /Image:"!BOOTMOUNTDIR!" /Add-Package !_PER64!
    if !SLIM! NEQ 1 "!DISMRoot!" /ScratchDir:"!DISMTEMPDIR!" /Image:"!BOOTMOUNTDIR!" /Add-Package !_PEX64!
  )
  if "!_PEM86!" NEQ "" if /i !BOOTARCH!==x86 (
    "!DISMRoot!" /ScratchDir:"!DISMTEMPDIR!" /Image:"!BOOTMOUNTDIR!" /Add-Package !_PEM86! !_PEF86!
    if exist "!BOOTMOUNTDIR!\Windows\servicing\Packages\WinPE-Rejuv-Package~31bf3856ad364e35~*.mum" "!DISMRoot!" /ScratchDir:"!DISMTEMPDIR!" /Image:"!BOOTMOUNTDIR!" /Add-Package !_PER86!
    if !SLIM! NEQ 1 "!DISMRoot!" /ScratchDir:"!DISMTEMPDIR!" /Image:"!BOOTMOUNTDIR!" /Add-Package !_PEX86!
  )
  echo.
  echo ============================================================
  echo Update language settings
  echo ============================================================
  echo.
  "%DISMRoot%" /Quiet /ScratchDir:"%DISMTEMPDIR%" /Image:"%BOOTMOUNTDIR%" /Set-AllIntl:%DEFAULTLANGUAGE%
  "%DISMRoot%" /Quiet /ScratchDir:"%DISMTEMPDIR%" /Image:"%BOOTMOUNTDIR%" /Set-SKUIntlDefaults:%DEFAULTLANGUAGE%
  "%DISMRoot%" /Quiet /ScratchDir:"%DISMTEMPDIR%" /Image:"%BOOTMOUNTDIR%" /Cleanup-Image /StartComponentCleanup
  "%DISMRoot%" /Quiet /ScratchDir:"%DISMTEMPDIR%" /Image:"%BOOTMOUNTDIR%" /Cleanup-Image /StartComponentCleanup /ResetBase
) else (
  for /L %%j in (1, 1, %LANGUAGES%) do (
   if /i !LPARCH%%j!==!BOOTARCH! (
    if not exist "!BOOTMOUNTDIR!\sources\!LANGUAGE%%j!" mkdir "!BOOTMOUNTDIR!\sources\!LANGUAGE%%j!"
    call :EAfonts %%j
   )
  )
)
call :cleanup "%BOOTMOUNTDIR%"
echo.
echo ============================================================
echo Unmount boot.wim - index 1/%BOOTCOUNT%
echo ============================================================
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Unmount-Wim /MountDir:"%BOOTMOUNTDIR%" /Commit
if errorlevel 1 goto :E_UNMOUNT

if %BOOTCOUNT%==1 goto :rebuild
echo.
echo ============================================================
echo Mount boot.wim - index 2/%BOOTCOUNT%
echo ============================================================
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Mount-Wim /WimFile:"%DVDDIR%\sources\boot.wim" /Index:2 /MountDir:"%BOOTMOUNTDIR%"
if errorlevel 1 goto :E_MOUNT

if %WINPE%==1 (
  echo.
  echo ============================================================
  echo Add LPs to boot.wim - index 2/%BOOTCOUNT%
  echo ============================================================
  reg load HKLM\TEMPWIM "!BOOTMOUNTDIR!\Windows\System32\Config\SOFTWARE" 1>nul 2>nul
  reg add HKLM\TEMPWIM\Microsoft\Windows\CurrentVersion\SideBySide\Configuration /v DisableComponentBackups /t REG_DWORD /d 1 /f 1>nul 2>nul
  reg add HKLM\TEMPWIM\Microsoft\Windows\CurrentVersion\SideBySide\Configuration /v SupersededActions /t REG_DWORD /d 1 /f 1>nul 2>nul
  reg unload HKLM\TEMPWIM 1>nul 2>nul
  if "!_PEM64!" NEQ "" if /i !BOOTARCH!==amd64 (
    "!DISMRoot!" /ScratchDir:"!DISMTEMPDIR!" /Image:"!BOOTMOUNTDIR!" /Add-Package !_PEM64! !_PES64! !_PEF64!
    if !SLIM! NEQ 1 "!DISMRoot!" /ScratchDir:"!DISMTEMPDIR!" /Image:"!BOOTMOUNTDIR!" /Add-Package !_PEX64!
  )
  if "!_PEM86!" NEQ "" if /i !BOOTARCH!==x86 (
    "!DISMRoot!" /ScratchDir:"!DISMTEMPDIR!" /Image:"!BOOTMOUNTDIR!" /Add-Package !_PEM86! !_PES86! !_PEF86!
    if !SLIM! NEQ 1 "!DISMRoot!" /ScratchDir:"!DISMTEMPDIR!" /Image:"!BOOTMOUNTDIR!" /Add-Package !_PEX86!
  )
  if /i !wimbit! NEQ dual for /L %%j in (1, 1, %LANGUAGES%) do (
    xcopy "!BOOTMOUNTDIR!\sources\!LANGUAGE%%j!\*.rtf" "!DVDDIR!\sources\!LANGUAGE%%j!\" /chryi 1>nul 2>nul
    xcopy "!BOOTMOUNTDIR!\sources\!LANGUAGE%%j!\*.rtf" "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\" /chryi 1>nul 2>nul
  )
  echo.
  echo ============================================================
  echo Update language settings
  echo ============================================================
  echo.
  "%DISMRoot%" /Quiet /ScratchDir:"%DISMTEMPDIR%" /Image:"%BOOTMOUNTDIR%" /Set-AllIntl:%DEFAULTLANGUAGE%
  "%DISMRoot%" /Quiet /ScratchDir:"%DISMTEMPDIR%" /Image:"%BOOTMOUNTDIR%" /Set-SKUIntlDefaults:%DEFAULTLANGUAGE%
  "%DISMRoot%" /Quiet /ScratchDir:"%DISMTEMPDIR%" /Image:"%BOOTMOUNTDIR%" /Gen-LangINI /Distribution:"%BOOTMOUNTDIR%"
  "%DISMRoot%" /Quiet /ScratchDir:"%DISMTEMPDIR%" /Image:"%BOOTMOUNTDIR%" /Set-SetupUILang:%DEFAULTLANGUAGE% /Distribution:"%BOOTMOUNTDIR%"
  "%DISMRoot%" /Quiet /ScratchDir:"%DISMTEMPDIR%" /Image:"%BOOTMOUNTDIR%" /Cleanup-Image /StartComponentCleanup
  "%DISMRoot%" /Quiet /ScratchDir:"%DISMTEMPDIR%" /Image:"%BOOTMOUNTDIR%" /Cleanup-Image /StartComponentCleanup /ResetBase
) else (
  copy /y "!DVDDIR!\sources\lang.ini" "!BOOTMOUNTDIR!\sources" >nul
  echo.
  echo ============================================================
  echo Add language files to boot.wim - index 2
  echo ============================================================
  echo.
  for /L %%j in (1, 1, %LANGUAGES%) do (
   if /i !LPARCH%%j!==!BOOTARCH! (
    echo !LANGUAGE%%j!
    if not exist "!BOOTMOUNTDIR!\sources\!LANGUAGE%%j!" mkdir "!BOOTMOUNTDIR!\sources\!LANGUAGE%%j!"
    copy /y "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\vofflps.rtf" "!BOOTMOUNTDIR!\sources\!LANGUAGE%%j!" >nul 2>&1
    for %%G in %_mui% do (
    copy /y "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\setup\sources\!LANGUAGE%%j!\%%G" "!BOOTMOUNTDIR!\sources\!LANGUAGE%%j!" >nul 2>&1
    )
    attrib -A -S -H -I "!BOOTMOUNTDIR!\sources\!LANGUAGE%%j!" /S /D >nul
    call :EAfonts %%j
   )
  )
)
call :cleanup "%BOOTMOUNTDIR%"
echo.
echo ============================================================
echo Unmount boot.wim - index 2/%BOOTCOUNT%
echo ============================================================
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Unmount-Wim /MountDir:"%BOOTMOUNTDIR%" /Commit
if errorlevel 1 goto :E_UNMOUNT

:rebuild
echo.
echo ============================================================
echo Rebuild boot.wim
echo ============================================================
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Export-Image /SourceImageFile:"%DVDDIR%\sources\boot.wim" /All /DestinationImageFile:"%DVDDIR%\boot.wim"
if exist "%DVDDIR%\boot.wim" move /y "%DVDDIR%\boot.wim" "%DVDDIR%\sources" >nul
echo.
echo ============================================================
echo Rebuild install.wim
echo ============================================================
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Export-Image /SourceImageFile:"%DVDDIR%\sources\install.wim" /All /DestinationImageFile:"%DVDDIR%\install.wim"
if exist "%DVDDIR%\install.wim" move /y "%DVDDIR%\install.wim" "%DVDDIR%\sources" >nul
if %NET35%==1 if exist "%DVDDIR%\sources\sxs\*netfx3*.cab" del /f /q "%DVDDIR%\sources\sxs\*netfx3*.cab" >nul 2>&1
xcopy "%DVDDIR%\efi\microsoft\boot\fonts\*" "%DVDDIR%\boot\fonts\" /chryi 1>nul 2>nul

if %SLIM%==1 goto :slim
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
goto :dvd

:slim
echo.
echo ============================================================
echo Cleanup ISO payload
echo ============================================================
echo.
del /f /s /q "%DVDDIR%\ch*_boot.ttf" >nul 2>&1
del /f /s /q "%DVDDIR%\jpn_boot.ttf" >nul 2>&1
del /f /s /q "%DVDDIR%\kor_boot.ttf" >nul 2>&1
del /f /s /q "%DVDDIR%\m*_boot.ttf" >nul 2>&1
del /f /s /q "%DVDDIR%\m*_console.ttf" >nul 2>&1
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
mkdir "%DVDDIR%\sources" >nul 2>&1
if exist "%DVDDIR%\ei.cfg" move /y "%DVDDIR%\ei.cfg" "%DVDDIR%\sources" >nul 2>&1
if exist "%DVDDIR%\pid.txt" move /y "%DVDDIR%\pid.txt" "%DVDDIR%\sources" >nul 2>&1
move /y "%DVDDIR%\boot.wim" "%DVDDIR%\sources" >nul 2>&1
move /y "%DVDDIR%\install.wim" "%DVDDIR%\sources" >nul 2>&1
move /y "%DVDDIR%\lang.ini" "%DVDDIR%\sources" >nul 2>&1
move /y "%DVDDIR%\setup.exe" "%DVDDIR%\sources" >nul 2>&1

:dvd
if exist "%DVDDIR%\sources\uup" rmdir /s /q "%DVDDIR%\sources\uup" >nul 2>&1
if %ISO%==0 (set MESSAGE=Done. You need to create iso file yourself&goto :E_CREATEISO)
del /f /q "%temp%\isolabel.txt" >nul 2>&1
for %%a in (3 2 1) do (for /f "tokens=1 delims== " %%b in ('findstr %%a "%DVDDIR%\sources\lang.ini"') do echo %%b>>"%temp%\isolabel.txt")
for /f "usebackq tokens=1" %%a in ("%temp%\isolabel.txt") do (
set langid=%%a
set lang=!langid:~0,2!
if /i !langid!==en-gb set lang=en-gb
if /i !langid!==es-mx set lang=es-mx
if /i !langid!==fr-ca set lang=fr-ca
if /i !langid!==pt-pt set lang=pp
if /i !langid!==sr-latn-rs set lang=sr-latn
if /i !langid!==zh-cn set lang=cn
if /i !langid!==zh-hk set lang=hk
if /i !langid!==zh-tw set lang=tw
if /i !langid!==zh-tw if !build! geq 14393 set lang=ct
if "!mulabel!" equ "" (set "mulabel=!lang!") else (set "mulabel=!mulabel!_!lang!")
)
del /f /q "%temp%\isolabel.txt" >nul 2>&1
set DVDISO=%DVDISO%_%mulabel%.iso
echo.
echo ============================================================
echo Create ISO file
echo ============================================================
if exist "%DVDDIR%\efi\microsoft\boot\efisys.bin" (
   "%~dp0dism\cdimage.exe" -bootdata:2#p0,e,b"%DVDDIR%\boot\etfsboot.com"#pEF,e,b"%DVDDIR%\efi\microsoft\boot\efisys.bin" -o -h -u2 -udfver102 -m -l"%DVDLABEL%" "%DVDDIR%" "%DVDISO%"
) else (
   "%~dp0dism\cdimage.exe" -b"%DVDDIR%\boot\etfsboot.com" -o -h -u2 -udfver102 -m -l"%DVDLABEL%" "%DVDDIR%" "%DVDISO%"
)
if errorlevel 1 (set MESSAGE=ERROR: Could not create "%DVDISO%"&goto :E_CREATEISO)
echo.
echo ============================================================
echo Remove temporary directories
echo ============================================================
echo.
call :remove
set MESSAGE=Finished
goto :END

:E_BIN
call :remove
set MESSAGE=ERROR: Could not find work binaries
goto :END

:E_DVD
call :remove
set MESSAGE=ERROR: Could not find the specified distribution
goto :END

:E_WIM
call :remove
set MESSAGE=ERROR: Could not find install.wim file in \sources folder
goto :END

:E_ESD
call :remove
set MESSAGE=ERROR: Detected install.wim file is actually .esd file
goto :END

:E_FILES
call :remove
set MESSAGE=ERROR: Could not detect any cab/esd files in "Langs" folder
goto :END

:E_ARCH
call :remove
set MESSAGE=ERROR: None of detected LangPacks match any of WIM images architecture
goto :END

:E_LP
call :remove
set MESSAGE=ERROR: %ERRFILE% is not a valid Windows 10 LangPack
goto :END

:E_VER
call :remove
set MESSAGE=ERROR: %ERRFILE% version does not match WIM version %build%
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
if exist "%~1\Windows\WinSxS\Temp\TransformerRollbackData\*" (
takeown /f "%~1\Windows\WinSxS\Temp\TransformerRollbackData\*" /R /A >nul 2>&1
icacls "%~1\Windows\WinSxS\Temp\TransformerRollbackData\*" /grant *S-1-5-32-544:F /T >nul 2>&1
del /s /f /q "%~1\Windows\WinSxS\Temp\TransformerRollbackData\*" >nul 2>&1
)
if exist "%~1\Windows\inf\*.log" (
del /f /q "%~1\Windows\inf\*.log" >nul 2>&1
)
goto :eof

:ISOmui
"%_7z%" e ".\langs\!LPFILE%1!" -o"%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!" bootsect.exe.mui -r -aos >nul 2>&1
"%_7z%" e ".\langs\!LPFILE%1!" -o"%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!" credits.rtf -r -aos >nul 2>&1
"%_7z%" e ".\langs\!LPFILE%1!" -o"%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!" oobe_help_opt_in_details.rtf -r -aos >nul 2>&1
if exist "%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\bootsect.exe.mui" (xcopy "%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\bootsect.exe.mui" "%DVDDIR%\boot\!LANGUAGE%1!\" /chryi >nul 2>&1)
xcopy "%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\setup\sources\!LANGUAGE%1!\*" "%DVDDIR%\sources\!LANGUAGE%1!\" /cheryi >nul 2>&1
if exist "%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\setup\sources\!LANGUAGE%1!\cli" xcopy "%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\setup\sources\!LANGUAGE%1!\cli\*" "%DVDDIR%\sources\!LANGUAGE%1!\" /chryi >nul 2>&1
if exist "%DVDDIR%\sources\!LANGUAGE%1!\cli" rmdir /s /q "%DVDDIR%\sources\!LANGUAGE%1!\cli" >nul 2>&1
rmdir /s /q "%DVDDIR%\sources\!LANGUAGE%1!\dlmanifests" >nul 2>&1
rmdir /s /q "%DVDDIR%\sources\!LANGUAGE%1!\etwproviders" >nul 2>&1
rmdir /s /q "%DVDDIR%\sources\!LANGUAGE%1!\replacementmanifests" >nul 2>&1
mkdir "%DVDDIR%\sources\dlmanifests\!LANGUAGE%1!"
mkdir "%DVDDIR%\sources\replacementmanifests\!LANGUAGE%1!"
xcopy "%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\setup\sources\!LANGUAGE%1!\dlmanifests\microsoft-windows-iasserver-migplugin\*" "%DVDDIR%\sources\dlmanifests\microsoft-windows-iasserver-migplugin\!LANGUAGE%1!\" /chryi 1>nul 2>nul
xcopy "%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\setup\sources\!LANGUAGE%1!\dlmanifests\microsoft-windows-shmig-dl\*" "%DVDDIR%\sources\dlmanifests\microsoft-windows-shmig-dl\!LANGUAGE%1!\" /chryi >nul 2>&1
xcopy "%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\setup\sources\!LANGUAGE%1!\dlmanifests\microsoft-windows-storagemigration\*" "%DVDDIR%\sources\dlmanifests\microsoft-windows-storagemigration\!LANGUAGE%1!\" /chryi >nul 2>&1
xcopy "%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\setup\sources\!LANGUAGE%1!\dlmanifests\microsoft-windows-sxs\*" "%DVDDIR%\sources\dlmanifests\microsoft-windows-sxs\!LANGUAGE%1!\" /chryi >nul 2>&1
xcopy "%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\setup\sources\!LANGUAGE%1!\replacementmanifests\microsoft-windows-offlinefiles-core\*" "%DVDDIR%\sources\replacementmanifests\microsoft-windows-offlinefiles-core\!LANGUAGE%1!\" /chryi >nul 2>&1
xcopy "%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\setup\sources\!LANGUAGE%1!\replacementmanifests\microsoft-windows-shmig\*" "%DVDDIR%\sources\replacementmanifests\microsoft-windows-shmig\!LANGUAGE%1!\" /chryi >nul 2>&1
xcopy "%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\setup\sources\!LANGUAGE%1!\replacementmanifests\microsoft-windows-storagemigration\*" "%DVDDIR%\sources\replacementmanifests\microsoft-windows-storagemigration\!LANGUAGE%1!\" /chryi >nul 2>&1
xcopy "%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\setup\sources\!LANGUAGE%1!\replacementmanifests\microsoft-windows-sxs\*" "%DVDDIR%\sources\replacementmanifests\microsoft-windows-sxs\!LANGUAGE%1!\" /chryi >nul 2>&1
xcopy "%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\setup\sources\!LANGUAGE%1!\etwproviders\*" "%DVDDIR%\sources\etwproviders\!LANGUAGE%1!\" /chryi >nul 2>&1
xcopy "%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\setup\sources\!LANGUAGE%1!\etwproviders\*" "%DVDDIR%\support\logging\!LANGUAGE%1!\" /chryi >nul 2>&1
copy /y "%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\credits.rtf" "%DVDDIR%\sources\!LANGUAGE%1!" >nul 2>&1
copy /y "%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\oobe_help_opt_in_details.rtf" "%DVDDIR%\sources\!LANGUAGE%1!" >nul 2>&1
copy /y "%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\vofflps.rtf" "%DVDDIR%\sources\!LANGUAGE%1!" >nul 2>&1
copy /y "%EXTRACTDIR%\!LPARCH%1!\!LANGUAGE%1!\vofflps.rtf" "%DVDDIR%\sources\!LANGUAGE%1!\privacy.rtf" >nul 2>&1
attrib -A -S -H -I "%DVDDIR%\sources\!LANGUAGE%1!" /S /D >nul 2>&1
goto :eof

:EAfonts
if /i !LANGUAGE%1!==ja-jp if exist "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\meiryo.ttc" (
echo.
echo ============================================================
echo Add Font Support: !LANGUAGE%1!
echo ============================================================
echo.
icacls "!BOOTMOUNTDIR!\Windows\Boot\Fonts" /save "!TEMPDIR!\AclFile" 1>nul 2>nul&takeown /f "!BOOTMOUNTDIR!\Windows\Boot\Fonts" 1>nul 2>nul&icacls "!BOOTMOUNTDIR!\Windows\Boot\Fonts" /grant *S-1-5-32-544:F 1>nul 2>nul
copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\jpn_boot.ttf" "!BOOTMOUNTDIR!\Windows\Boot\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\meiryo_boot.ttf" "!BOOTMOUNTDIR!\Windows\Boot\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\meiryon_boot.ttf" "!BOOTMOUNTDIR!\Windows\Boot\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\meiryo.ttc" "!BOOTMOUNTDIR!\Windows\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\msgothic.ttc" "!BOOTMOUNTDIR!\Windows\Fonts" >nul&reg load HKLM\OFFLINE "!BOOTMOUNTDIR!\Windows\System32\config\SOFTWARE" >nul&reg import "%~dp0dism\EA\ja-jp.reg" >nul&reg unload HKLM\OFFLINE >nul
icacls "!BOOTMOUNTDIR!\Windows\Boot\Fonts" /setowner "NT Service\TrustedInstaller" 1>nul 2>nul&icacls "!BOOTMOUNTDIR!\Windows\Boot" /restore "!TEMPDIR!\AclFile" 1>nul 2>nul
)
if /i !LANGUAGE%1!==ko-kr (
echo.
echo ============================================================
echo Add Font Support: !LANGUAGE%1!
echo ============================================================
echo.
icacls "!BOOTMOUNTDIR!\Windows\Boot\Fonts" /save "!TEMPDIR!\AclFile" 1>nul 2>nul&takeown /f "!BOOTMOUNTDIR!\Windows\Boot\Fonts" 1>nul 2>nul&icacls "!BOOTMOUNTDIR!\Windows\Boot\Fonts" /grant *S-1-5-32-544:F 1>nul 2>nul
copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\kor_boot.ttf" "!BOOTMOUNTDIR!\Windows\Boot\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\malgunn_boot.ttf" "!BOOTMOUNTDIR!\Windows\Boot\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\malgun_boot.ttf" "!BOOTMOUNTDIR!\Windows\Boot\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\malgun.ttf" "!BOOTMOUNTDIR!\Windows\Fonts" >nul&if exist "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\gulim.ttc" (copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\gulim.ttc" "!BOOTMOUNTDIR!\Windows\Fonts" >nul)&reg load HKLM\OFFLINE "!BOOTMOUNTDIR!\Windows\System32\config\SOFTWARE" >nul&reg import "%~dp0dism\EA\ko-kr.reg" >nul&reg unload HKLM\OFFLINE >nul
icacls "!BOOTMOUNTDIR!\Windows\Boot\Fonts" /setowner "NT Service\TrustedInstaller" 1>nul 2>nul&icacls "!BOOTMOUNTDIR!\Windows\Boot" /restore "!TEMPDIR!\AclFile" 1>nul 2>nul
)
if /i !LANGUAGE%1!==zh-cn (
echo.
echo ============================================================
echo Add Font Support: !LANGUAGE%1!
echo ============================================================
echo.
icacls "!BOOTMOUNTDIR!\Windows\Boot\Fonts" /save "!TEMPDIR!\AclFile" 1>nul 2>nul&takeown /f "!BOOTMOUNTDIR!\Windows\Boot\Fonts" 1>nul 2>nul&icacls "!BOOTMOUNTDIR!\Windows\Boot\Fonts" /grant *S-1-5-32-544:F 1>nul 2>nul
copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\chs_boot.ttf" "!BOOTMOUNTDIR!\Windows\Boot\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\msyhn_boot.ttf" "!BOOTMOUNTDIR!\Windows\Boot\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\msyh_boot.ttf" "!BOOTMOUNTDIR!\Windows\Boot\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\msyh.ttc" "!BOOTMOUNTDIR!\Windows\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\msyhl.ttc" "!BOOTMOUNTDIR!\Windows\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\mingliub.ttc" "!BOOTMOUNTDIR!\Windows\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\simsun.ttc" "!BOOTMOUNTDIR!\Windows\Fonts" >nul&reg load HKLM\OFFLINE "!BOOTMOUNTDIR!\Windows\System32\config\SOFTWARE" >nul&reg import "%~dp0dism\EA\zh-cn.reg" >nul&reg unload HKLM\OFFLINE >nul
icacls "!BOOTMOUNTDIR!\Windows\Boot\Fonts" /setowner "NT Service\TrustedInstaller" 1>nul 2>nul&icacls "!BOOTMOUNTDIR!\Windows\Boot" /restore "!TEMPDIR!\AclFile" 1>nul 2>nul
)
if /i !LANGUAGE%1!==zh-hk (
echo.
echo ============================================================
echo Add Font Support: !LANGUAGE%1!
echo ============================================================
echo.
icacls "!BOOTMOUNTDIR!\Windows\Boot\Fonts" /save "!TEMPDIR!\AclFile" 1>nul 2>nul&takeown /f "!BOOTMOUNTDIR!\Windows\Boot\Fonts" 1>nul 2>nul&icacls "!BOOTMOUNTDIR!\Windows\Boot\Fonts" /grant *S-1-5-32-544:F 1>nul 2>nul
copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\cht_boot.ttf" "!BOOTMOUNTDIR!\Windows\Boot\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\msjhn_boot.ttf" "!BOOTMOUNTDIR!\Windows\Boot\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\msjh_boot.ttf" "!BOOTMOUNTDIR!\Windows\Boot\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\msjh.ttc" "!BOOTMOUNTDIR!\Windows\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\mingliub.ttc" "!BOOTMOUNTDIR!\Windows\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\simsun.ttc" "!BOOTMOUNTDIR!\Windows\Fonts" >nul&reg load HKLM\OFFLINE "!BOOTMOUNTDIR!\Windows\System32\config\SOFTWARE" >nul&reg import "%~dp0dism\EA\zh-hk.reg" >nul&reg unload HKLM\OFFLINE >nul
icacls "!BOOTMOUNTDIR!\Windows\Boot\Fonts" /setowner "NT Service\TrustedInstaller" 1>nul 2>nul&icacls "!BOOTMOUNTDIR!\Windows\Boot" /restore "!TEMPDIR!\AclFile" 1>nul 2>nul
)
if /i !LANGUAGE%1!==zh-tw (
echo.
echo ============================================================
echo Add Font Support: !LANGUAGE%1!
echo ============================================================
echo.
icacls "!BOOTMOUNTDIR!\Windows\Boot\Fonts" /save "!TEMPDIR!\AclFile" 1>nul 2>nul&takeown /f "!BOOTMOUNTDIR!\Windows\Boot\Fonts" 1>nul 2>nul&icacls "!BOOTMOUNTDIR!\Windows\Boot\Fonts" /grant *S-1-5-32-544:F 1>nul 2>nul
copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\cht_boot.ttf" "!BOOTMOUNTDIR!\Windows\Boot\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\msjhn_boot.ttf" "!BOOTMOUNTDIR!\Windows\Boot\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\msjh_boot.ttf" "!BOOTMOUNTDIR!\Windows\Boot\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\msjh.ttc" "!BOOTMOUNTDIR!\Windows\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\mingliub.ttc" "!BOOTMOUNTDIR!\Windows\Fonts" >nul&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\simsun.ttc" "!BOOTMOUNTDIR!\Windows\Fonts" >nul&reg load HKLM\OFFLINE "!BOOTMOUNTDIR!\Windows\System32\config\SOFTWARE" >nul&reg import "%~dp0dism\EA\zh-tw.reg" >nul&reg unload HKLM\OFFLINE >nul
icacls "!BOOTMOUNTDIR!\Windows\Boot\Fonts" /setowner "NT Service\TrustedInstaller" 1>nul 2>nul&icacls "!BOOTMOUNTDIR!\Windows\Boot" /restore "!TEMPDIR!\AclFile" 1>nul 2>nul
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