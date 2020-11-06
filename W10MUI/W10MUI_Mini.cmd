@echo off

set WIMPATH=
set WINPE=1
set SLIM=0

set WINPEPATH=

set DEFAULTLANGUAGE=
set MOUNTDIR=

rem ##################################################################
rem # NORMALY THERE IS NO NEED TO CHANGE ANYTHING BELOW THIS COMMENT #
rem ##################################################################

title Windows 10 LangPacks Integrator
set "SysPath=%Windir%\System32"
if exist "%Windir%\Sysnative\reg.exe" (set "SysPath=%Windir%\Sysnative")
set "Path=%SysPath%;%Windir%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
reg query HKU\S-1-5-19 1>nul 2>nul || goto :E_ADMIN
cd /d "%~dp0"
set "WORKDIR=%cd%"
set "TEMPDIR=%WORKDIR%\TEMP"
if "%MOUNTDIR%"=="" set "MOUNTDIR=%SystemDrive%\W10MUIMOUNT"
set "DISMTEMPDIR=%TEMPDIR%\scratch"
set "EXTRACTDIR=%TEMPDIR%\extract"
set "INSTALLMOUNTDIR=%MOUNTDIR%\install"
set "WINREMOUNTDIR=%MOUNTDIR%\winre"
set EAlang=(ja-jp,ko-kr,zh-cn,zh-hk,zh-tw)

if not "%WIMPATH%"=="" goto :check
set _wim=0
if exist "*.wim" (for /f "delims=" %%i in ('dir /b *.wim') do (call set /a _wim+=1))
if not %_wim%==1 goto :prompt
for /f "delims=" %%i in ('dir /b *.wim') do set "WIMPATH=%%i"
goto :check

:prompt
echo.
echo ============================================================
echo Enter the install.wim path ^(without quotes marks ""^)
echo ============================================================
echo.
set /p "WIMPATH="
if "%WIMPATH%"=="" set MESSAGE=ERROR: no source specified&goto :END
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
if not exist "%WIMPATH%" goto :E_DVD
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
for /f "tokens=2 delims=: " %%i in ('dism\dism.exe /english /get-wiminfo /wimfile:"%WIMPATH%" /index:%1 ^| find /i "Architecture"') do set "WIMARCH%count%=%%i"
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
dism\imagex.exe /info "%WIMPATH%" | findstr /c:"LZMS" >nul && goto :E_ESD
for /f "tokens=2 delims=: " %%i in ('dism\dism.exe /english /get-wiminfo /wimfile:"%WIMPATH%" ^| findstr "Index"') do set VERSIONS=%%i
for /f "tokens=4 delims=:. " %%i in ('dism\dism.exe /english /get-wiminfo /wimfile:"%WIMPATH%" /index:1 ^| find /i "Version :"') do set build=%%i
for /L %%j in (1, 1, %LANGUAGES%) do (
if not !LPBUILD%%j!==%build% set "ERRFILE=!LPFILE%%j!"&goto :E_VER
)
if %WINPE%==1 for /L %%j in (1, 1, %LANGUAGES%) do (
"%_7z%" e "!WinpeOC%%j!\!LANGUAGE%%j!\lp.cab" -o"%EXTRACTDIR%" Microsoft-Windows-Common-Foundation-Package*%build%*.mum 1>nul 2>nul
if not exist "%EXTRACTDIR%\*.mum" set WINPE=0
)
if "%DEFAULTLANGUAGE%"=="" (
for /f "tokens=1" %%i in ('dism\dism.exe /english /get-wiminfo /wimfile:"%WIMPATH%" /index:1 ^| find /i "Default"') do set "DEFAULTLANGUAGE=%%i"
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
echo Build: %build%
echo Count: %VERSIONS% Image^(s^)
if %wimbit%==dual (echo Arch : Multi) else (echo Arch : %wimbit%-bit)

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
"%_7z%" x ".\langs\!LPFILE%%j!" -o"%TEMPDIR%\!LPARCH%%j!\!LANGUAGE%%j!" * -r >nul
call set _PP86=!_PP86! /packagepath:"%TEMPDIR%\!LPARCH%%j!\!LANGUAGE%%j!\update.mum"
)
)
if %wimbit%==64 for /L %%j in (1, 1, %LANGUAGES%) do (
if /i !LPARCH%%j!==amd64 (
echo !LANGUAGE%%j! / 64-bit
"%_7z%" e ".\langs\!LPFILE%%j!" -o"%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" vofflps.rtf -r -aos >nul
"%_7z%" x ".\langs\!LPFILE%%j!" -o"%TEMPDIR%\!LPARCH%%j!\!LANGUAGE%%j!" * -r >nul
call set _PP64=!_PP64! /packagepath:"%TEMPDIR%\!LPARCH%%j!\!LANGUAGE%%j!\update.mum"
)
)
if %wimbit%==dual for /L %%j in (1, 1, %LANGUAGES%) do (
if /i !LPARCH%%j!==x86 (
echo !LANGUAGE%%j! / 32-bit
"%_7z%" e ".\langs\!LPFILE%%j!" -o"%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" vofflps.rtf -r -aos >nul
"%_7z%" x ".\langs\!LPFILE%%j!" -o"%TEMPDIR%\!LPARCH%%j!\!LANGUAGE%%j!" * -r >nul
call set _PP86=!_PP86! /packagepath:"%TEMPDIR%\!LPARCH%%j!\!LANGUAGE%%j!\update.mum"
) else (
echo !LANGUAGE%%j! / 64-bit
"%_7z%" e ".\langs\!LPFILE%%j!" -o"%EXTRACTDIR%\!LPARCH%%j!\!LANGUAGE%%j!" vofflps.rtf -r -aos >nul
"%_7z%" x ".\langs\!LPFILE%%j!" -o"%TEMPDIR%\!LPARCH%%j!\!LANGUAGE%%j!" * -r >nul
call set _PP64=!_PP64! /packagepath:"%TEMPDIR%\!LPARCH%%j!\!LANGUAGE%%j!\update.mum"
)
)
if %wimbit%==32 if not defined _PP86 goto :E_ARCH
if %wimbit%==64 if not defined _PP64 goto :E_ARCH

for /L %%i in (1, 1, %VERSIONS%) do (
echo.
echo ============================================================
echo Mount install.wim - index %%i/%VERSIONS%
echo ============================================================
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Mount-Wim /Wimfile:"%WIMPATH%" /Index:%%i /MountDir:"%INSTALLMOUNTDIR%"
if errorlevel 1 goto :E_MOUNT
echo.
echo ============================================================
echo Add LPs to install.wim - index %%i/%VERSIONS%
echo ============================================================
if defined _PP64 if /i !WIMARCH%%i!==amd64 (
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Image:"%INSTALLMOUNTDIR%" /Add-Package !_PP64!
)
if defined _ODbasic64 if /i !WIMARCH%%i!==amd64 (
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Image:"%INSTALLMOUNTDIR%" /Add-Package !_ODbasic64!
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Image:"%INSTALLMOUNTDIR%" /Add-Package !_ODfont64! !_ODtts64! !_ODhand64! !_ODocr64! !_ODspeech64! !_ODintl64!
)
if defined _PP86 if /i !WIMARCH%%i!==x86 (
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Image:"%INSTALLMOUNTDIR%" /Add-Package !_PP86!
)
if defined _ODbasic86 if /i !WIMARCH%%i!==x86 (
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Image:"%INSTALLMOUNTDIR%" /Add-Package !_ODbasic86!
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Image:"%INSTALLMOUNTDIR%" /Add-Package !_ODfont86! !_ODtts86! !_ODhand86! !_ODocr86! !_ODspeech86! !_ODintl86!
)
echo.
echo ============================================================
echo Update language settings
echo ============================================================
echo.
"%DISMRoot%" /Quiet /ScratchDir:"%DISMTEMPDIR%" /Image:"%INSTALLMOUNTDIR%" /Set-AllIntl:%DEFAULTLANGUAGE%
"%DISMRoot%" /Quiet /ScratchDir:"%DISMTEMPDIR%" /Image:"%INSTALLMOUNTDIR%" /Set-SKUIntlDefaults:%DEFAULTLANGUAGE%
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
  if defined _PEM64 if /i !WIMARCH%%i!==amd64 (
    "!DISMRoot!" /ScratchDir:"!DISMTEMPDIR!" /Image:"!WINREMOUNTDIR!" /Add-Package !_PEM64! !_PER64! !_PEF64!
    if !SLIM! NEQ 1 "!DISMRoot!" /ScratchDir:"!DISMTEMPDIR!" /Image:"!WINREMOUNTDIR!" /Add-Package !_PEX64!
  )
  if defined _PEM86 if /i !WIMARCH%%i!==x86 (
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
echo Rebuild install.wim
echo ============================================================
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Export-Image /SourceImageFile:"%WIMPATH%" /All /DestinationImageFile:"%TEMPDIR%\install.wim"
if exist "%TEMPDIR%\install.wim" move /y "%TEMPDIR%\install.wim" "%WIMPATH%" >nul
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
set MESSAGE=ERROR: Could not find the specified install.wim
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
if exist "%~1\Windows\WinSxS\Temp\TransformerRollbackData\*" (
takeown /f "%~1\Windows\WinSxS\Temp\TransformerRollbackData\*" /R /A >nul 2>&1
icacls "%~1\Windows\WinSxS\Temp\TransformerRollbackData\*" /grant *S-1-5-32-544:F /T >nul 2>&1
del /s /f /q "%~1\Windows\WinSxS\Temp\TransformerRollbackData\*" >nul 2>&1
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