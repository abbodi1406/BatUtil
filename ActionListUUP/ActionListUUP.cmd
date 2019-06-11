@echo off
rem script:	   abbodi1406
title UUP Upgrade ActionList.xml
cd /d "%~dp0"
if not exist "*.esd" (
echo.
echo ============================================================
echo ERROR: UUP ESD files are not detected
echo ============================================================
echo.
echo Press any key to exit.
pause >nul
goto :QUIT
)
setlocal EnableDelayedExpansion
color 1f
del /f /q uups_esd.txt >nul 2>&1
set uups_esd_num=0
for %%# in (
Core,CoreSingleLanguage,CoreCountrySpecific
Professional,ProfessionalEducation,ProfessionalWorkstation
Education,Enterprise,EnterpriseG,Cloud,CloudE
CoreN
ProfessionalN,ProfessionalEducationN,ProfessionalWorkstationN
EducationN,EnterpriseN,EnterpriseGN,CloudN,CloudEN
Starter,StarterN,ProfessionalCountrySpecific,ProfessionalSingleLanguage,ServerRdsh,IoTEnterprise,PPIPro
) do (
if exist "*%%#_*.esd" dir /b /a:-d "*%%#_*.esd">>uups_esd.txt 2>nul
)
for /f "tokens=3 delims=: " %%i in ('find /v /n /c "" uups_esd.txt') do set uups_esd_num=%%i
if %uups_esd_num% equ 0 (
echo.
echo ============================================================
echo ERROR: UUP Edition file is not detected
echo ============================================================
echo.
echo Press any key to exit.
pause >nul
goto :QUIT
)
for /L %%i in (1,1,%uups_esd_num%) do call :uups_esd %%i
if exist "*.cab" for /f "delims=" %%i in ('dir /b /a:-d "*.cab"') do call :uups_ref "%%i"
if exist "*.esd" for /f "delims=" %%i in ('dir /b /a:-d "*.esd"') do call :uups_ref "%%i"
for /L %%i in (1,1,%uups_esd_num%) do call :uups_xml "!uups_esd_%%i!"
echo.
echo ============================================================
echo Finished
echo ============================================================
echo.
echo Press any key to exit.
pause >nul
goto :QUIT

:uups_esd
for /f "usebackq  delims=" %%b in (`find /n /v "" uups_esd.txt ^| find "[%1]"`) do set uups_esd=%%b
if %1 GEQ 1 set uups_esd=%uups_esd:~3%
if %1 GEQ 10 set uups_esd=%uups_esd:~2%
if %1 GEQ 100 set uups_esd=%uups_esd:~1%
set "uups_esd_%1=%uups_esd%"
exit /b

:uups_ref
echo %~1| find /i "RetailDemo" 1>nul && exit /b
echo %~1| find /i "Holographic-Desktop-FOD" 1>nul && exit /b
echo %~1| find /i "Windows10.0-KB" 1>nul && exit /b
for /L %%i in (1,1,%uups_esd_num%) do (
if /i "%~1" equ "!uups_esd_%%i!" exit /b
)
set /a ref+=1
set "file_%ref%=%~1"
set "name_%ref%=%~n1"
exit /b

:uups_xml
set "ActionList=ActionList_%~n1.xml"
if exist "%ActionList%" exit /b
echo ============================================================
echo Creating %ActionList%
echo ============================================================
echo.
(echo ^<ActionList xmlns^="urn:schemas-microsoft-com:os-update-actionlist" Revision^="1" BuildInfo^="" SessionId^="" SessionData^="MediaBasedUpgrade" Operation^="MediaBasedUpgrade"^>
echo     ^<Media Id^="%~n1" Path^="UUP" Name^="%~1"^>)>"%ActionList%"
for /L %%i in (1,1,%ref%) do (
(echo         ^<Package Id^="!name_%%i!" PackagePath^="!file_%%i!" PackageType^="Cab"/^>)>>"%ActionList%"
)
if not exist "Windows10.0-KB*.cab" (
(echo     ^</Media^>
echo     ^<Plan^>^</Plan^>
echo     ^<Actions^>^</Actions^>
echo ^</ActionList^>)>>"%ActionList%"
exit /b
)
(echo     ^</Media^>
echo     ^<Plan^>
echo         ^<InstallFeature Id="SetupDynamicUpdate" Group="Microsoft"/^>
echo         ^<InstallFeature Id="SafeOSUpdate" Group="Microsoft"/^>
echo         ^<InstallFeature Id="ServicingStackUpdate" Group="Microsoft"/^>
echo         ^<InstallFeature Id="CumulativeUpdate" Group="Microsoft"/^>
echo     ^</Plan^>
echo     ^<Actions^>)>>"%ActionList%"
for /f %%a in ('dir /b /os Windows10.0-KB*.cab') do call :Package %%a
(echo     ^</Actions^>
echo ^</ActionList^>)>>"%ActionList%"
exit /b

:Package
set "pack=%~1"
expand.exe -f:*_microsoft-windows-servicingstack_*.manifest %pack% .\ >nul 2>&1
if exist "*servicingstack_*.manifest" (
(echo         ^<InstallPackage Keyform^="" InstalledSize^="0" StagedSize^="0" FilePath^="%pack%" Reason^="ServicingStackUpdate" FeatureId="ServicingStackUpdate" Partition^="MainOS" BinaryPartition^="false"/^>)>>"%ActionList%"
del /f /q *.manifest >nul 2>&1
exit /b
)
expand.exe -f:update.mum %pack% .\ >nul 2>&1
if not exist "update.mum" (
(echo         ^<InstallPackage Keyform^="" InstalledSize^="0" StagedSize^="0" FilePath^="%pack%" Reason^="SetupDU" FeatureId="SetupDynamicUpdate" Partition^="MainOS" BinaryPartition^="false"/^>)>>"%ActionList%"
exit /b
)
findstr /i /m "Package_for_KB" update.mum 1>nul 2>nul && findstr /i /m "WinPE" update.mum 1>nul 2>nul && (
(echo         ^<InstallPackage Keyform^="" InstalledSize^="0" StagedSize^="0" FilePath^="%pack%" Reason^="SafeOSDU" FeatureId="SafeOSUpdate" Partition^="MainOS" BinaryPartition^="false"/^>)>>"%ActionList%"
del /f /q *.mum >nul 2>&1
exit /b
)
findstr /i /m "Package_for_RollupFix" update.mum 1>nul 2>nul && (
(echo         ^<InstallPackage Keyform^="" InstalledSize^="0" StagedSize^="0" FilePath^="%pack%" Reason^="CumulativeUpdate" FeatureId="CumulativeUpdate" Partition^="MainOS" BinaryPartition^="false"/^>)>>"%ActionList%"
)
del /f /q *.mum >nul 2>&1
del /f /q *.manifest >nul 2>&1
exit /b

:QUIT
del /f /q uups_esd.txt >nul 2>&1
exit