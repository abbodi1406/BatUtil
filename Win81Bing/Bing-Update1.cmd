@echo off
%windir%\system32\reg.exe query "HKU\S-1-5-19" 1>nul 2>nul || goto :eof
cd /d "%~dp0"

:: Create final new iso? set 1 or 0
set ISO=1

:: Optional, set mount directory on another partition if available to speed integration, or leave it blank
set MOUNTDIR=

rem ##################################################################
rem # NORMALY THERE IS NO NEED TO CHANGE ANYTHING BELOW THIS COMMENT #
rem ##################################################################

set _img=0
if exist "*.img" (for /f "delims=:" %%i in ('dir /b "*.img"') do (call set /a _img+=1))
if %_img% equ 0 set MESSAGE=ERROR: no source .IMG file found&goto :END
if %_img% gtr 1 set MESSAGE=ERROR: Detected more than one source IMG file&goto :END
for /f "delims=:" %%i in ('dir /b "*.img"') do set _source=%%i

set _iso=0
if exist "*.iso" (for /f "delims=:" %%i in ('dir /b "*.iso"') do (call set /a _iso+=1))
if %_iso% equ 0 set MESSAGE=ERROR: no target .ISO file found&goto :END
if %_iso% gtr 1 set MESSAGE=ERROR: Detected more than one target ISO file&goto :END
for /f "delims=:" %%i in ('dir /b "*.iso"') do set DVDPATH=%%i

set _cab=0
if exist "*.cab" (for /f "delims=:" %%i in ('dir /b "*.cab"') do (call set /a _cab+=1))
if %_cab% equ 0 set MESSAGE=ERROR: no Lang Pack .CAB file found&goto :END
if %_cab% gtr 1 set MESSAGE=ERROR: Detected more than one Lang Pack file&goto :END
for /f "delims=:" %%i in ('dir /b "*.cab"') do set LPFILE=%%i

set WORKDIR=%~dp0
set WORKDIR=%WORKDIR:~0,-1%
set DVDDIR=%WORKDIR%\DVD
set TEMPDIR=%WORKDIR%\TEMP
if "%MOUNTDIR%"=="" set MOUNTDIR=%WORKDIR%\MOUNT
set DISMTEMPDIR=%TEMPDIR%\scratch
set EXTRACTDIR=%TEMPDIR%\extract
set INSTALLMOUNTDIR=%MOUNTDIR%\install
set SECMOUNTDIR=%MOUNTDIR%\offline

for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G
if %winbuild% GEQ 9600 (
SET DISMRoot=%windir%\system32\dism.exe
goto :prepare
)

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
FOR /F "skip=2 tokens=2*" %%i IN ('REG QUERY "%regKeyPath%" /v KitsRoot81') DO (SET KitsRoot=%%j)
SET DandIRoot=%KitsRoot%Assessment and Deployment Kit\Deployment Tools
SET DISMRoot=%DandIRoot%\%PROCESSOR_ARCHITECTURE%\DISM\dism.exe
if not exist "%DISMRoot%" goto :skip
goto :prepare

:skip
SET DISMRoot=%~dp0dism\dism.exe

:prepare
if not exist "%~dp0dism\7z.exe" goto :E_BIN
setlocal EnableDelayedExpansion
echo.
echo ============================================================
echo Remove temporary directories if exist
echo ============================================================
echo.
if exist "%DVDDIR%" rmdir /s /q "%DVDDIR%" >nul
if errorlevel 1 goto :E_DELDIR
if exist "%TEMPDIR%" rmdir /s /q "%TEMPDIR%" >nul
if errorlevel 1 goto :E_DELDIR
if exist "%MOUNTDIR%" rmdir /s /q "%MOUNTDIR%" >nul
if errorlevel 1 goto :E_DELDIR
echo.
echo ============================================================
echo Create work directories
echo ============================================================
echo.
mkdir "%DVDDIR%"
if errorlevel 1 goto :E_MKDIR
mkdir "%TEMPDIR%"
if errorlevel 1 goto :E_MKDIR
mkdir "%DISMTEMPDIR%"
if errorlevel 1 goto :E_MKDIR
mkdir "%EXTRACTDIR%"
if errorlevel 1 goto :E_MKDIR
mkdir "%MOUNTDIR%"
if errorlevel 1 goto :E_MKDIR
mkdir "%INSTALLMOUNTDIR%"
if errorlevel 1 goto :E_MKDIR
mkdir "%SECMOUNTDIR%"
if errorlevel 1 goto :E_MKDIR

"%~dp0dism\7z.exe" e "%LPFILE%" -o"%EXTRACTDIR%" langcfg.ini >nul
FOR /F "tokens=2 delims==" %%i IN ('type "%EXTRACTDIR%\langcfg.ini" ^| findstr /i "Language"') DO set LANGUAGE=%%i
set lang=%LANGUAGE:~0,2%

"%~dp0dism\7z.exe" e "%DVDPATH%" -o"%EXTRACTDIR%" sources\lang.ini >nul
for /f "skip=5 tokens=1 delims==" %%i in ('type "%EXTRACTDIR%\lang.ini"') do set langiso=%%i
if /i %LANGUAGE% neq %langiso% goto :E_LANG

"%~dp0dism\7z.exe" e "%LPFILE%" -o"%EXTRACTDIR%" Microsoft-Windows-CommonFoundation*amd64*.mum 1>nul 2>nul
if exist "%EXTRACTDIR%\*.mum" (
   set arch=amd64
   set archm=x64
   set archiso=X64
) else (
   set arch=x86
   set archm=x86
   set archiso=X86
)
echo.
echo ============================================================
echo Detected LP: %LANGUAGE% %archm%
echo ============================================================
echo.
"%~dp0dism\7z.exe" e "%_source%" -o"%EXTRACTDIR%" efi\boot\bootx64.efi 1>nul 2>nul
if exist "%EXTRACTDIR%\bootx64.efi" (set archwim=x64) else (set archwim=x86)
if /i %archwim% neq %archm% goto :E_ARCH
echo.
echo ============================================================
echo Extract target ISO contents
echo ============================================================
echo.
echo "%DVDPATH%"
echo.
"%~dp0dism\7z.exe" x "%DVDPATH%" -o"%DVDDIR%" * -r >nul
if exist "%DVDDIR%\sources\ei.cfg" DEL /F /Q "%DVDDIR%\sources\ei.cfg" >nul
echo.
echo ============================================================
echo Extract winre.wim of target ISO
echo ============================================================
echo.
"%~dp0dism\7z.exe" e "%DVDDIR%\sources\install.wim" -o"%TEMPDIR%" *Windows\System32\Recovery\winre.wim -r -aos >nul
attrib -S -H -I "%TEMPDIR%\winre.wim"
echo.
echo ============================================================
echo Extract install.wim of source IMG
echo ============================================================
echo.
echo "%_source%"
echo.
"%~dp0dism\7z.exe" e "%_source%" -o"%TEMPDIR%" sources\install.wim >nul
for /f "tokens=2 delims=: " %%i in ('dism\dism.exe /english /get-wiminfo /wimfile:"%TEMPDIR%\install.wim" /index:1 ^| find /i "Edition"') do set editionid=%%i
echo.
echo ============================================================
echo Mount install.wim of source IMG
echo ============================================================
echo.
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Mount-Wim /Wimfile:"%TEMPDIR%\install.wim" /Index:1 /MountDir:"%INSTALLMOUNTDIR%"
if errorlevel 1 goto :E_MOUNT
for /f %%i in ('dir /b "%INSTALLMOUNTDIR%\Windows\servicing\Packages\Microsoft-Windows-Client-LanguagePack-Package~31bf3856ad364e35*.mum"') do set OLP=%%i
set OLP=%OLP:~0,-4%
echo.
echo ============================================================
echo Add new language pack
echo ============================================================
echo.
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Image:"%INSTALLMOUNTDIR%" /Add-Package /PackagePath:"%LPFILE%"
echo.
echo ============================================================
echo Update default language settings
echo ============================================================
echo.
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Image:"%INSTALLMOUNTDIR%" /Set-AllIntl:%LANGUAGE%
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Image:"%INSTALLMOUNTDIR%" /Set-SKUIntlDefaults:%LANGUAGE%
echo.
echo ============================================================
echo Remove old language pack
echo ============================================================
echo.
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Image:"%INSTALLMOUNTDIR%" /Remove-Package /PackageName:%OLP%
echo.
if not exist "%INSTALLMOUNTDIR%\Windows\WinSxS\pending.xml" (
echo.
echo ============================================================
echo Cleanup the image
echo ============================================================
echo.
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Image:"%INSTALLMOUNTDIR%" /Cleanup-Image /StartComponentCleanup /ResetBase
)
takeown /f "%INSTALLMOUNTDIR%\Windows\WinSxS\ManifestCache\*.bin" >nul
icacls "%INSTALLMOUNTDIR%\Windows\WinSxS\ManifestCache\*.bin" /grant *S-1-5-32-544:F >nul
del /f /q "%INSTALLMOUNTDIR%\Windows\WinSxS\ManifestCache\*.bin" >nul
takeown /f "%INSTALLMOUNTDIR%\Windows\WinSxS\Temp\PendingDeletes\*" >nul
icacls "%INSTALLMOUNTDIR%\Windows\WinSxS\Temp\PendingDeletes\*" /grant *S-1-5-32-544:F >nul
del /f /q "%INSTALLMOUNTDIR%\Windows\WinSxS\Temp\PendingDeletes\*" >nul
if exist "%INSTALLMOUNTDIR%\Windows\inf\*.log" del /f /q "%INSTALLMOUNTDIR%\Windows\inf\*.log" >nul
echo.
echo ============================================================
echo Add extracted winre.wim
echo ============================================================
echo.
attrib -S -H -I "%INSTALLMOUNTDIR%\Windows\System32\Recovery\winre.wim"
copy /y "%TEMPDIR%\winre.wim" "%INSTALLMOUNTDIR%\Windows\System32\Recovery"
echo.
echo ============================================================
echo Mount install.wim of target ISO
echo ============================================================
echo.
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Mount-Wim /Wimfile:"%DVDDIR%\sources\install.wim" /Index:1 /MountDir:"%SECMOUNTDIR%"
if errorlevel 1 goto :E_MOUNT
echo.
echo ============================================================
echo Copy Store Apps language resources
echo ============================================================
echo.
dism\NSudoC.exe -U:T -P:E "%~dp0dism\hstart.exe /NOCONSOLE /WAIT /HIGH "%windir%\system32\robocopy.exe "%SECMOUNTDIR%\Program Files\WindowsApps" "%INSTALLMOUNTDIR%\Program Files\WindowsApps" /MIR /COPYALL"
:timer
timeout /t 10 >nul
tasklist /FI "IMAGENAME eq hstart.exe" | find /i "hstart.exe" >nul
if %errorlevel%==0 goto :timer
echo.
echo ============================================================
echo Discard install.wim of target ISO
echo ============================================================
echo.
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Unmount-Wim /MountDir:"%SECMOUNTDIR%" /Discard
if errorlevel 1 goto :E_UNMOUNT
DEL /F /Q "%DVDDIR%\sources\install.wim" >nul
echo.
echo ============================================================
echo Save install.wim of source IMG
echo ============================================================
echo.
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Unmount-Wim /MountDir:"%INSTALLMOUNTDIR%" /Commit
if errorlevel 1 goto :E_UNMOUNT
echo.
echo ============================================================
echo Rebuild new install.wim
echo ============================================================
echo.
"%DISMRoot%" /ScratchDir:"%DISMTEMPDIR%" /Export-Image /SourceImageFile:"%TEMPDIR%\install.wim" /SourceIndex:1 /DestinationImageFile:"%DVDDIR%\sources\install.wim" /CheckIntegrity
if errorlevel 1 goto :E_UNMOUNT
DEL /F /Q "%TEMPDIR%\install.wim" >nul
if %ISO% EQU 0 goto :E_OSCDIMG
echo.
echo ============================================================
echo Create ISO file
echo ============================================================
echo.
for %%b in (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do set LANGUAGE=!LANGUAGE:%%b=%%b!
if %editionid%==CoreConnected set DVDLABEL=IR3_CCONA_%archiso%FREO_%LANGUAGE%_DV9
if %editionid%==CoreConnectedSingleLanguage set DVDLABEL=IR3_CCSLA_%archiso%FREO_%LANGUAGE%_DV9
set DVDISO=%DVDLABEL%.iso
"%~dp0dism\oscdimg.exe" -bootdata:2#p0,e,b"%DVDDIR%\boot\etfsboot.com"#pEF,e,b"%DVDDIR%\efi\Microsoft\boot\efisys.bin" -o -h -u2 -udfver102 -m -t03/18/2014,08:25:28 -g -l"%DVDLABEL%" "%DVDDIR%" "%DVDISO%"
if errorlevel 1 goto :E_CREATEISO
echo.
echo ============================================================
echo Remove the temporary directories
echo ============================================================
echo.
rmdir /s /q "%DVDDIR%" 1>nul 2>nul
rmdir /s /q "%MOUNTDIR%" 1>nul 2>nul
rmdir /s /q "%TEMPDIR%" 1>nul 2>nul
if exist "%DVDDIR%" rmdir /s /q "%DVDDIR%" 1>nul 2>nul
if exist "%MOUNTDIR%" rmdir /s /q "%MOUNTDIR%" 1>nul 2>nul
if exist "%TEMPDIR%" rmdir /s /q "%TEMPDIR%" 1>nul 2>nul
set MESSAGE=Done
goto :END

:E_ARCH
set MESSAGE=ERROR: Detected iso architecture does not match Language Pack architecture
goto :END

:E_LANG
set MESSAGE=ERROR: Detected target iso language does not match Language Pack
goto :END

:E_BIN
set MESSAGE=ERROR: Could not find binaries folder
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

:E_CREATEISO
set MESSAGE=ERROR: Could not create "%DVDISO%"
goto :END

:E_OSCDIMG
echo.
echo ============================================================
echo Remove the temporary directories
echo ============================================================
echo.
rmdir /s /q "%MOUNTDIR%" 1>nul 2>nul
rmdir /s /q "%TEMPDIR%" 1>nul 2>nul
if exist "%MOUNTDIR%" rmdir /s /q "%MOUNTDIR%" 1>nul 2>nul
if exist "%TEMPDIR%" rmdir /s /q "%TEMPDIR%" 1>nul 2>nul
set MESSAGE=Done. You choose to create final iso file yourself
goto :END

:END
echo.
echo ============================================================
echo %MESSAGE%
echo ============================================================
echo.
echo Press any Key to Exit.
pause >nul
exit