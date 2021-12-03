@echo off
title Installing Updates . . .
cd /d "%~dp0"
if not exist "*Windows10*KB*.msu" if not exist "*Windows10*KB*.cab" if not exist "*SSU-*-*.cab" exit /b 0
if exist "1SSU-*-*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "1SSU-*-*.cab"') do (
call dism.exe /Online /NoRestart /Add-Package /PackagePath:%%#
)
if exist "1Windows10*KB*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "1Windows10*KB*.cab"') do (
call dism.exe /Online /NoRestart /Add-Package /PackagePath:%%#
)
if exist "*NetFx3*.cab" if not exist "%SystemRoot%\Microsoft.NET\Framework\v2.0.50727\ngen.exe" (
call dism.exe /Online /NoRestart /Enable-Feature /FeatureName:NetFx3 /All /LimitAccess /Source:%cd%
)
if exist "2Windows10*KB*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "2Windows10*KB*.cab"') do (
call dism.exe /Online /NoRestart /Add-Package /PackagePath:%%#
)
if exist "3Windows10*KB*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "3Windows10*KB*.cab"') do (
call dism.exe /Online /NoRestart /Add-Package /PackagePath:%%#
)
if exist "3Windows10*KB*.msu" for /f "tokens=* delims=" %%# in ('dir /b /on "3Windows10*KB*.msu"') do (
call dism.exe /Online /NoRestart /Add-Package /PackagePath:%%#
)
cd \
(goto) 2>nul&rd /s /q "%~dp0"