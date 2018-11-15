@echo off
rem by @rgadguard
color 1f
set "url=https://s1.rg-adguard.net/dl/decrypt"
for /f "tokens=3 delims=:. " %%f in ('bitsadmin.exe /CREATE /DOWNLOAD "Update esd-decrypter-wimlib" ^| findstr "Created job"') do set GUID=%%f
echo.
echo Downloading latest key.cmd database
bitsadmin>nul /transfer %GUID% /download /priority foreground %url%/key.txt "%~dp0bin\key.cmd"
bitsadmin>nul /complete %GUID%
echo.
echo.
echo Done
echo Press any key to exit.
pause >nul
goto :eof
