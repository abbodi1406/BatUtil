@echo off
if exist "%Windir%\Sysnative\reg.exe" (set "SysPath=%Windir%\Sysnative") else (set "SysPath=%Windir%\System32")
set "Path=%SysPath%;%Windir%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
reg query "HKU\S-1-5-19" 1>nul 2>nul || (set MESSAGE=ERROR: Run %~nx0 as administrator&goto :END)
if exist "%windir%\winsxs\pending.xml" (set MESSAGE=pending update operation detected, restart the system first to clear it&goto :END)
for /f "tokens=4,5,6,7 delims=~." %%i in ('dir /b %windir%\servicing\Packages\Microsoft-Windows-Foundation-Package*~~*.mum') do set version=%%i.%%j.%%k.%%l&set build=%%k
if %build% lss 7601 (set MESSAGE=ERROR: Only Windows 7 SP1 or later is supported&goto :END)
echo ============================================================
echo Loading System Information
echo ============================================================
echo.
setlocal EnableDelayedExpansion
set "arch=64-bit"&set "cbsarch=amd64"
if /i %PROCESSOR_ARCHITECTURE%==x86 (
if "%PROCESSOR_ARCHITEW6432%"=="" set "arch=32-bit"&set "cbsarch=x86"
)
for /f "skip=2 tokens=2*" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName') do set "product=%%j"
for /f "tokens=3 delims=: " %%i in ('dism /English /Online /Get-CurrentEdition ^| find /i "Current Edition :"') do set "edition=%%i"
for /f "tokens=5 delims=: " %%i in ('dism /English /Online /Get-Intl ^| findstr /I /C:"UI language :"') do set "uilang=%%i"
for /f %%i in ('dir /b %windir%\servicing\Packages\Microsoft-Windows-Client-LanguagePack-Package~*.mum') do (call set /a _l+=1)
if %_l% gtr 1 for /f "tokens=4 delims=~" %%i in ('dir /b %windir%\servicing\Packages\Microsoft-Windows-Client-LanguagePack-Package~*.mum') do (
if defined uilangs (call set "uilangs=!uilangs! %%i") else (call set "uilangs=%%i")
call :setcount %%i
)
for %%i in (Starter,HomeBasic,HomePremium,StarterN,HomeBasicN,HomePremiumN,CoreSingleLanguage) do (
if /i %edition%==%%i goto :Supported
)
if %build%==7601 for %%i in (Professional,ProfessionalN) do (
if /i %edition%==%%i goto :Supported
)

:NotSupported
cls
echo ============================================================
echo Operating System Information
echo ============================================================
echo Version           : %version%
echo Architecture      : %arch%
echo Edition ID        : %edition%
echo Name              : %product%
if %_l% gtr 1 (
echo Display Languages : %uilangs%
echo Primary Language  : %uilang%
) else (
echo Display Language  : %uilang%
)
echo.
echo ============================================================
echo This script supports the following Editions:
echo.
echo Windows 7 (Starter, Home Basic, Home Premium, Professional)
echo Windows 8 Single Language
echo Windows 8.1 Single Language
echo Windows 10 Home Single Language
echo.
echo.
echo For other Editions you can run lpksetup.exe to install language packs
echo.
echo Press any key to exit.
pause >nul
goto :eof

:setcount
set /a count+=1
set UIL%count%=%1
goto :eof

:Supported
cd /d "%~dp0"
set _c=0
if %build% equ 7601 if exist "LangPack\*kb2483139*.exe" for /f "delims=" %%i in ('dir /b LangPack\*kb2483139*.exe') do (call set /a _c+=1)
if exist "LangPack\*.cab" for /f "delims=" %%i in ('dir /b LangPack\*.cab') do (call set /a _c+=1)
if %build% gtr 14393 if exist "LangPack\*.esd" for /f "delims=" %%i in ('dir /b LangPack\*.esd') do (call set /a _c+=1)
if %_c% neq 1 goto :Info
if %build% equ 7601 if exist "LangPack\*kb2483139*.exe" for /f "delims=" %%i in ('dir /b LangPack\*kb2483139*.exe') do (set "LangFile=LangPack\%%i"&goto :Check)
if exist "LangPack\*.cab" for /f "delims=" %%i in ('dir /b LangPack\*.cab') do (set "LangFile=LangPack\%%i")
if %build% gtr 14393 if exist "LangPack\*.esd" for /f "delims=" %%i in ('dir /b LangPack\*.esd') do (set "LangFile=LangPack\%%i")

:Check
echo.
echo ============================================================
echo Loading Language Pack Information
echo ============================================================
echo.
if %build% equ 7601 if /i "%LangFile:~-3%" equ "exe" (
   LangPack\exe2cab.exe -q "%LangFile%" "LangPack\%build%_%cbsarch%.cab"
   set "LangFile=LangPack\%build%_%cbsarch%.cab"
)
for /f "tokens=9 delims=:~. " %%i in ('dism /English /Online /Get-PackageInfo /PackagePath:%LangFile% ^| findstr /I /C:"Package Identity"') do set "LangBuild=%%i"
if %build% neq %LangBuild% (set MESSAGE=ERROR: Lang Pack is not compatible with current OS version&goto :END)
for /f "tokens=5 delims=:~ " %%i in ('dism /English /Online /Get-PackageInfo /PackagePath:%LangFile% ^| findstr /I /C:"Package Identity"') do set "LangArch=%%i"
if /i %cbsarch% neq %LangArch% (set MESSAGE=ERROR: Lang Pack is not compatible with current OS architecture&goto :END)
for /f "tokens=6 delims=:~ " %%i in ('dism /English /Online /Get-PackageInfo /PackagePath:%LangFile% ^| findstr /I /C:"Package Identity"') do set "LangCode=%%i"
set "LangType=92"&set "Fallback="&set "Fallbac2="&call :%LangCode%

:Info
cls
set userinp=
echo ============================================================
echo Operating System Information
echo ============================================================
echo Version           : %version%
echo Architecture      : %arch%
echo Edition ID        : %edition%
echo Name              : %product%
if %_l% gtr 1 (
echo Display Languages : %uilangs%
echo Primary Language  : %uilang%
) else (
echo Display Language  : %uilang%
)
if defined LangFile if not exist "%windir%\servicing\Packages\Microsoft-Windows-Client-LanguagePack-Package~*%LangCode%*.mum" (
echo.
echo ============================================================
echo Language Pack     : %LangCode% / %LangName%
echo ============================================================
echo.
choice /C 10 /N /M "Press 1 to install (%LangCode%) as primary language, or 0 to exit: "
if errorlevel 2 set MESSAGE=End&goto :END
if errorlevel 1 goto :Install
)
if %_l% gtr 1 (
echo.
echo ============================================================
echo Installed Display Languages:
for /L %%i in (1, 1, %_l%) do (
echo %%i. !UIL%%i!
)
echo.
set /p userinp= ^Enter a language number to set as primary, or 0 to exit: 
if "!userinp!"=="" goto :Info
if "!userinp!"=="0" set MESSAGE=End&goto :END
for /L %%i in (1, 1, %_l%) do (
if "!userinp!"=="%%i" set "LangCode=!UIL%%i!"&set "LangType=92"&set "Fallback="&set "Fallbac2="&call :!UIL%%i!&goto :Change
)
goto :Info
)
echo.
echo.
echo Press any key to exit.
pause >nul
goto :eof

:Install
set InstLP=1
cls
echo ============================================================
echo Installing %LangName% Language Pack
echo ============================================================
Dism /Online /NoRestart /Add-Package /PackagePath:"%LangFile%"
if %errorlevel% neq 0 if %errorlevel% neq 3010 (set MESSAGE=ERROR: Installation failed&goto :END)

if %build% gtr 9600 if exist "%cd%\FOD\*.cab" (
echo.
echo ============================================================
echo Installing %LangCode% Language Features On Demand Packs
echo ============================================================
Dism /Online /NoRestart /Add-Package /PackagePath:"%cd%\FOD"
if %errorlevel% neq 0 if %errorlevel% neq 3010 (set MESSAGE=ERROR: Installation failed&goto :END)
)

:Change
if /i "%uilang%"=="%LangCode%" (set MESSAGE=ERROR: %LangCode% is already the primary language&goto :END)
if not defined InstLP cls
echo.
echo ============================================================
echo Updating Language Settings
echo ============================================================
echo.
set "LangHexL=0000%LangHex%"
set "LangScheme=%LangHex:~2,2%%LangHex:~0,2%"

reg delete HKLM\SYSTEM\CurrentControlSet\Control\CMF\SqmData\BootLanguages /v %uilang% /f >nul

reg delete HKLM\SYSTEM\CurrentControlSet\Control\FileSystem /v NtfsAllowExtendedCharacterIn8dot3Name /f 1>nul 2>nul

if not defined InstLP (
reg add HKLM\SYSTEM\CurrentControlSet\Control\MUI\UILanguages\%LangCode% /v LCID /t REG_DWORD /d 0x%LangHex% /f >nul
reg add HKLM\SYSTEM\CurrentControlSet\Control\MUI\UILanguages\%LangCode% /v Type /t REG_DWORD /d 0x%LangType% /f >nul
if defined Fallback reg add HKLM\SYSTEM\CurrentControlSet\Control\MUI\UILanguages\%LangCode% /v DefaultFallback /d %Fallback% /f >nul
if defined Fallback reg add HKLM\SYSTEM\CurrentControlSet\Control\MUI\UILanguages\%LangCode% /v %Fallback% /t REG_MULTI_SZ /d \0 /f >nul
if defined Fallbac2 reg add HKLM\SYSTEM\CurrentControlSet\Control\MUI\UILanguages\%LangCode% /v %Fallbac2% /t REG_MULTI_SZ /d \0 /f >nul
)

set key=HKLM\SYSTEM\CurrentControlSet\Control\MUI\UILanguages
FOR /F "tokens=7 delims=\" %%a IN ('reg query %key% /s /f LCID ^| find /i "UILanguages"') DO (
if /i "%%a" neq "%LangCode%" reg delete %key%\%%a /f >nul 2>&1
)

reg add HKLM\SYSTEM\CurrentControlSet\Control\Nls\Language /v InstallLanguage /d %LangHex% /f >nul
if defined Fallback (
reg add HKLM\SYSTEM\CurrentControlSet\Control\Nls\Language /v InstallLanguageFallback /t REG_MULTI_SZ /d %Fallback%\0%Fallbac2% /f >nul
) else (
reg delete HKLM\SYSTEM\CurrentControlSet\Control\Nls\Language /v InstallLanguageFallback /f 1>nul 2>nul
)

reg add HKLM\SYSTEM\CurrentControlSet\Control\Nls\Locale /d %LangHexL% /f >nul

reg add "HKEY_USERS\.DEFAULT\Control Panel\Desktop" /v PreferredUILanguages /t REG_MULTI_SZ /d %LangCode% /f >nul
reg add "HKEY_USERS\.DEFAULT\Control Panel\Desktop\MuiCached" /v MachinePreferredUILanguages /t REG_MULTI_SZ /d %LangCode% /f >nul
reg add "HKEY_USERS\S-1-5-18\Control Panel\Desktop\MuiCached" /v MachinePreferredUILanguages /t REG_MULTI_SZ /d %LangCode% /f >nul
reg add "HKCU\Control Panel\Appearance" /v SchemeLangID /t REG_BINARY /d %LangScheme% /f >nul
reg add "HKCU\Control Panel\Desktop" /v PreferredUILanguages /t REG_MULTI_SZ /d %LangCode% /f >nul
reg add "HKCU\Control Panel\Desktop\MuiCached" /v MachinePreferredUILanguages /t REG_MULTI_SZ /d %LangCode% /f >nul
if %build% geq 9600 (
reg add "HKCU\Control Panel\International\User Profile" /v Languages /t REG_MULTI_SZ /d %LangCode% /f >nul
reg add "HKCU\Control Panel\International\User Profile System Backup" /v Languages /t REG_MULTI_SZ /d %LangCode% /f >nul
reg add "HKCU\Control Panel\International\User Profile System Backup\%LangCode%" /v "%LangHex%:%LangHexL%" /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Control Panel\International\User Profile\%LangCode%" /v "%LangHex%:%LangHexL%" /t REG_DWORD /d 1 /f >nul
)

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ThemeManager" /v LastUserLangID /d %LangLCID% /f >nul

bcdedit /set {current} locale %LangCode% >nul
%windir%\system32\mcbuilder.exe /s >nul
rem SCHTASKS /Change /TN "Microsoft\Windows\MUI\LPRemove" /ENABLE 1>nul 2>nul

if exist "LangPack\%build%_%cbsarch%.cab" del /f /q LangPack\%build%_%cbsarch%.cab >nul

echo.
echo ============================================================
echo Finished
echo ============================================================
echo.
if exist "%windir%\servicing\Packages\Package_for*.mum" (
echo.
echo Detected installed updates in the system
echo this may cause booting failure due missing resources
echo you should reinstall the updates before restarting
echo either manually, or check Windows Update now.
)
echo.
echo You must restart the system to complete the display language change
echo.
choice /C 10 /N /M "Press 1 to restart now, or 0 to exit: "
if errorlevel 2 goto :eof
if errorlevel 1 SHUTDOWN /R /T 00

:ar-SA
set "LangName=Arabic"
set "LangLCID=1025"
set "LangHex=0401"
set "Fallback=en-US"
set "Fallbac2=fr-FR"
goto :eof

:bg-BG
set "LangName=Bulgarian"
set "LangLCID=1026"
set "LangHex=0402"
set "Fallback=en-US"
goto :eof

:cs-CZ
set "LangName=Czech"
set "LangLCID=1029"
set "LangHex=0405"
set "Fallback=en-US"
goto :eof

:da-DK
set "LangName=Danish"
set "LangLCID=1030"
set "LangHex=0406"
set "Fallback=en-US"
goto :eof

:de-DE
set "LangName=German"
set "LangLCID=1031"
set "LangHex=0407"
if %build% lss 9600 set "LangType=91"
if %build% geq 9600 set "Fallback=en-US"
goto :eof

:el-GR
set "LangName=Greek"
set "LangLCID=1032"
set "LangHex=0408"
set "Fallback=en-US"
goto :eof

:en-GB
set "LangName=English ^(United Kingdom^)"
set "LangLCID=2057"
set "LangHex=0809"
if %build% lss 9600 (set "LangType=92") else (set "LangType=112")
set "Fallback=en-US"
goto :eof

:en-US
set "LangName=English"
set "LangLCID=1033"
set "LangHex=0409"
if %build% lss 9600 (set "LangType=91") else (set "LangType=111")
goto :eof

:es-ES
set "LangName=Spanish"
set "LangLCID=3082"
set "LangHex=0C0A"
if %build% lss 9600 set "LangType=91"
if %build% geq 9600 set "Fallback=en-US"
goto :eof

:es-MX
set "LangName=Spanish ^(Mexico^)"
set "LangLCID=2058"
set "LangHex=080A"
set "LangType=112"
set "Fallback=es-ES"
goto :eof

:et-EE
set "LangName=Estonian"
set "LangLCID=1061"
set "LangHex=0425"
set "Fallback=en-US"
goto :eof

:fi-FI
set "LangName=Finnish"
set "LangLCID=1035"
set "LangHex=040B"
set "Fallback=en-US"
goto :eof

:fr-CA
set "LangName=French ^(Canada^)"
set "LangLCID=3084"
set "LangHex=0C0C"
set "LangType=112"
set "Fallback=fr-fr"
goto :eof

:fr-FR
set "LangName=French"
set "LangLCID=1036"
set "LangHex=040C"
if %build% lss 9600 set "LangType=91"
if %build% geq 9600 set "Fallback=en-US"
goto :eof

:he-il
set "LangName=Hebrew"
set "LangLCID=1037"
set "LangHex=040D"
set "Fallback=en-US"
goto :eof

:hr-HR
set "LangName=Croatian"
set "LangLCID=1050"
set "LangHex=041A"
set "Fallback=en-US"
goto :eof

:hu-HU
set "LangName=Hungarian"
set "LangLCID=1038"
set "LangHex=040E"
set "Fallback=en-US"
goto :eof

:it-IT
set "LangName=Italian"
set "LangLCID=1040"
set "LangHex=0410"
if %build% lss 9600 set "LangType=91"
if %build% geq 9600 set "Fallback=en-US"
goto :eof

:ja-JP
set "LangName=Japanese"
set "LangLCID=1041"
set "LangHex=0411"
if %build% lss 9600 set "LangType=91"
if %build% geq 9600 set "Fallback=en-US"
goto :eof

:ko-KR
set "LangName=Korean"
set "LangLCID=1042"
set "LangHex=0412"
set "Fallback=en-US"
goto :eof

:lt-LT
set "LangName=Lithuanian"
set "LangLCID=1063"
set "LangHex=0427"
set "Fallback=en-US"
goto :eof

:lv-LV
set "LangName=Latvian"
set "LangLCID=1062"
set "LangHex=0426"
set "Fallback=en-US"
goto :eof

:nb-NO
set "LangName=Norwegian ^(Bokmal^)"
set "LangLCID=1044"
set "LangHex=0414"
set "Fallback=en-US"
goto :eof

:nl-NL
set "LangName=Dutch"
set "LangLCID=1043"
set "LangHex=0413"
if %build% lss 9600 set "LangType=91"
if %build% geq 9600 set "Fallback=en-US"
goto :eof

:pl-PL
set "LangName=Polish"
set "LangLCID=1045"
set "LangHex=0415"
set "Fallback=en-US"
goto :eof

:pt-BR
set "LangName=Portuguese ^(Brazil^)"
set "LangLCID=1046"
set "LangHex=0416"
set "LangType=112"
set "Fallback=en-US"
goto :eof

:pt-PT
set "LangName=Portuguese ^(Portugal^)"
set "LangLCID=2070"
set "LangHex=0816"
set "LangType=112"
set "Fallback=en-US"
goto :eof

:ro-RO
set "LangName=Romanian"
set "LangLCID=1048"
set "LangHex=0418"
set "Fallback=en-US"
goto :eof

:ru-RU
set "LangName=Russian"
set "LangLCID=1049"
set "LangHex=0419"
set "Fallback=en-US"
goto :eof

:sk-SK
set "LangName=Slovak"
set "LangLCID=1051"
set "LangHex=041B"
set "Fallback=en-US"
goto :eof

:sl-SI
set "LangName=Slovenian"
set "LangLCID=1060"
set "LangHex=0424"
set "Fallback=en-US"
goto :eof

:sr-Latn-CS
set "LangName=Serbian ^(Latin^)"
set "LangLCID=2074"
set "LangHex=081A"
set "Fallback=en-US"
goto :eof

:sr-Latn-RS
set "LangName=Serbian ^(Latin^)"
set "LangLCID=9242"
set "LangHex=241A"
set "Fallback=en-US"
goto :eof

:sv-SE
set "LangName=Swedish"
set "LangLCID=1053"
set "LangHex=041D"
set "Fallback=en-US"
goto :eof

:th-TH
set "LangName=Thai"
set "LangLCID=1054"
set "LangHex=041E"
set "Fallback=en-US"
goto :eof

:tr-TR
set "LangName=Turkish"
set "LangLCID=1055"
set "LangHex=041F"
set "Fallback=en-US"
goto :eof

:uk-UA
set "LangName=Ukrainian"
set "LangLCID=1058"
set "LangHex=0422"
set "Fallback=en-US"
goto :eof

:zh-CN
set "LangName=Chinese ^(Simplified^)"
set "LangLCID=2052"
set "LangHex=0804"
set "Fallback=en-US"
goto :eof

:zh-HK
set "LangName=Chinese ^(Hong Kong SAR^)"
set "LangLCID=3076"
set "LangHex=0C04"
set "Fallback=zh-TW"
set "Fallbac2=en-US"
goto :eof

:zh-TW
set "LangName=Chinese ^(Traditional^)"
set "LangLCID=1028"
set "LangHex=0404"
if %build% lss 14393 set "LangType=112"
set "Fallback=en-US"
goto :eof

:END
if exist "LangPack\%build%_%cbsarch%.cab" del /f /q LangPack\%build%_%cbsarch%.cab >nul
if %MESSAGE%==End goto :eof
echo.
echo ============================================================
echo %MESSAGE%
echo ============================================================
echo.
echo Press any Key to Exit.
pause >nul
goto :eof