@setlocal DisableDelayedExpansion
@echo off

ver|findstr /c:" 5." >nul && goto :Passed
whoami /groups 2>nul | findstr /i /c:"S-1-16-16384" /c:"S-1-16-12288" 1>nul || (
echo Error: Run as administrator
goto :TheEnd
)

:Passed
set _WSH=1
reg query "HKCU\SOFTWARE\Microsoft\Windows Script Host\Settings" /v Enabled 2>nul | find /i "0x0" 1>nul && (set _WSH=0)
reg query "HKLM\SOFTWARE\Microsoft\Windows Script Host\Settings" /v Enabled 2>nul | find /i "0x0" 1>nul && (set _WSH=0)
if %_WSH% equ 0 (
echo Error: Windows Script Host is disabled or is not functional
goto :TheEnd
)

cd /d "%~dp0"
if not exist "unPatches*.vbs" (
echo Error: unPatches VBScripts are missing
goto :TheEnd
)
if not exist "PatchAAA.msp" (
echo Error: PatchAAA.msp is missing
goto :TheEnd
)

echo Copying installed msi files to a temporary directory
echo.
if exist _wi\ rmdir /s /q _wi\
mkdir _wi
copy /y "%SYSTEMROOT%\Installer\*.msi" "_wi\" 1>nul 2>nul

if not exist "_wi\*.msi" (
rmdir /s /q _wi\
echo Notice: no msi files detected
goto :TheEnd
)

echo Checking msi files
echo.
if not exist "%SYSTEMROOT%\Installer\fffff.msp" copy /y "PatchAAA.msp" "%SYSTEMROOT%\Installer\fffff.msp" 1>nul 2>nul
copy /y "unPatches*.vbs" "_wi\" 1>nul 2>nul
cd _wi
ping 127.0.0.1 -n 5 >nul
for /f %%# in ('dir /b *.msi') do (
if exist unPatches2007.vbs cscript.exe //NoLogo unPatches2007.vbs %%#
if exist unPatches2010.vbs cscript.exe //NoLogo unPatches2010.vbs %%#
if exist unPatches2013.vbs cscript.exe //NoLogo unPatches2013.vbs %%#
if exist unPatches2016.vbs cscript.exe //NoLogo unPatches2016.vbs %%#
)
cd ..
rmdir /s /q _wi\
echo.
echo Finished.

:TheEnd
echo.
echo Press any key to exit.
pause >nul
exit /b
