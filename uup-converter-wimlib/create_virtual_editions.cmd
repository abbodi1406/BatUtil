@echo off
rem 0 - source distribution folder will be directly modified
rem 1 - source distribution folder will be copied then modified
rem if source distribution is .ISO file, this option has no affect
set Preserve=0

rem Change to 1 to delete source edition index (example: create Enterprise and delete Pro)
set DeleteSource=0

rem Change to 1 for not creating ISO file, setup media folder will be preserved
set SkipISO=0

rem script:     abbodi1406
rem wimlib:     synchronicity
rem offlinereg: erwan.l

set "params=%*"
cd /d "%~dp0" && ( if exist "%temp%\getadmin.vbs" del "%temp%\getadmin.vbs" ) && fsutil dirty query %systemdrive% 1>nul 2>nul || (  cmd /u /c echo Set UAC = CreateObject^("Shell.Application"^) : UAC.ShellExecute "cmd.exe", "/k cd ""%~dp0"" && ""%~dpnx0"" ""%params%""", "", "runas", 1 >> "%temp%\getadmin.vbs" && "%temp%\getadmin.vbs" && exit /B )

title Virtual Editions
for %%a in (wimlib-imagex,7z,imagex,offlinereg) do (
if not exist "%~dp0bin\%%a.exe" (echo Error: required %%a.exe is missing&pause&exit)
)
if /I "%PROCESSOR_ARCHITECTURE%" equ "AMD64" (set "wimlib=%~dp0bin\bin64\wimlib-imagex.exe") else (set "wimlib=%~dp0bin\wimlib-imagex.exe")
cd /d "%~dp0"
setlocal EnableExtensions
setlocal EnableDelayedExpansion
if exist bin\temp\ rmdir /s /q bin\temp\
set ERRORTEMP=
set _dir=0
set _iso=0
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G
set "dismroot=%windir%\system32\dism.exe"
set "mountdir=%SystemDrive%\MountUUP"

:checkadk
SET regKeyPathFound=1
SET wowRegKeyPathFound=1
REG QUERY "HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 1>NUL 2>NUL || SET wowRegKeyPathFound=0
REG QUERY "HKLM\Software\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 1>NUL 2>NUL || SET regKeyPathFound=0
if %wowRegKeyPathFound% EQU 0 (
  if %regKeyPathFound% EQU 0 (
    SET ADK=0&goto :precheck
  ) else (
    SET regKeyPath=HKLM\Software\Microsoft\Windows Kits\Installed Roots
  )
) else (
    SET regKeyPath=HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots
)
FOR /F "skip=2 tokens=2*" %%i IN ('REG QUERY "%regKeyPath%" /v KitsRoot10') DO (SET "KitsRoot=%%j")
SET "DandIRoot=%KitsRoot%Assessment and Deployment Kit\Deployment Tools"
SET "dismroot=%DandIRoot%\%PROCESSOR_ARCHITECTURE%\DISM\dism.exe"
SET ADK=1
IF NOT EXIST "%dismroot%" SET ADK=0&SET "dismroot=%windir%\system32\dism.exe"

:precheck
if %winbuild% lss 10240 if %ADK% equ 0 (set "MESSAGE=Host OS is not compatible, and Windows 10 ADK is not detected"&goto :E_MSG)

:checkdir
dir /b /ad . 1>nul 2>nul || goto :checkiso
for /f "delims=" %%i in ('dir /b /ad .') do if exist "%%i\sources\install.wim" (
set _dir=1
set "ISOdir=%%~i"
)
if %_dir% equ 1 (bin\imagex.exe /info "%ISOdir%\sources\install.wim" | findstr /i /c:"LZMS" >nul) else (goto :checkiso)
if %errorlevel% equ 0 (set _dir=0) else (goto :dCheck)

:checkiso
if not exist "*.iso" goto :prompt
for /f "delims=" %%i in ('dir /b /a:-d *.iso') do (
set _iso=1
set "ISOfile=%%~i"
)
if %_iso% equ 1 (bin\7z.exe l "%ISOfile%" 2>nul | findstr /i install.wim 1>nul) else (goto :prompt)
if %errorlevel% neq 0 (set _iso=0&goto :prompt) else (set Preserve=0&goto :dISO)

:prompt
cls
set ISOfile=
echo ============================================================
echo Enter / Paste the complete path to ISO file
echo ============================================================
echo.
set /p "ISOfile="
if "%ISOfile%"=="" goto :QUIT
echo %ISOfile%| findstr /E /I "\.iso" >nul || (echo.&echo Error: Path do not represent an ISO file&pause&goto :prompt)
bin\7z.exe l "%ISOfile%" 2>nul | findstr /i install.wim 1>nul
if %errorlevel% neq 0 (echo.&echo Error: ISO file do not contain install.wim&pause&goto :prompt)
set _iso=1
set Preserve=0

:dISO
color 1f
cls
echo.
echo ============================================================
echo Extracting ISO file . . .
echo ============================================================
echo.
set "ISOdir=ISOUUP"
echo "%ISOfile%"
if exist %ISOdir%\ rmdir /s /q %ISOdir%\
bin\7z.exe x "%ISOfile%" -o%ISOdir% * -r >nul
bin\imagex.exe /info "%ISOdir%\sources\install.wim" | findstr /i /c:"LZMS" >nul && (set "MESSAGE=Detected install.wim file is actually .esd file"&if %_iso%==1 rmdir /s /q "%ISOdir%"&goto :E_MSG)

:dCheck
color 1f
echo.
echo ============================================================
echo Checking distribution Info . . .
echo ============================================================
CALL :dInfo
if %Preserve%==1 (
echo.
echo ============================================================
echo Copying distribution folder. . .
echo ============================================================
xcopy "%ISOdir%\*" ISOFOLDER\ /cheriky >nul 2>&1
) else (
move "%ISOdir%" ISOFOLDER >nul
)

:MULTIMENU
for %%i in (Enterprise,Education,ProfessionalEducation,ProfessionalWorkstation,EnterpriseN,EducationN,ProfessionalEducationN,ProfessionalWorkstationN,CoreSingleLanguage,ServerRdsh) do (
set %%i=0
)
for %%i in (Enterprise,Education,ProfessionalEducation,ProfessionalWorkstation,EnterpriseN,EducationN,ProfessionalEducationN,ProfessionalWorkstationN,CoreSingleLanguage,ServerRdsh) do (
find /i "%%i</EDITIONID>" bin\infoall.txt 1>nul && set %%i=1
)
cls
echo ============================================================
echo Available Target Editions:
if %EditionPro%==1 (
if %Enterprise%==0 echo. 1. Enterprise
if %Education%==0 echo. 2. Education
if %ProfessionalEducation%==0 echo. 3. Pro Education
if %ProfessionalWorkstation%==0 echo. 4. Pro for Workstations
)
if %EditionProN%==1 (
if %EnterpriseN%==0 echo. 5. Enterprise N
if %EducationN%==0 echo. 6. Education N
if %ProfessionalEducationN%==0 echo. 7. Pro Education N
if %ProfessionalWorkstationN%==0 echo. 8. Pro N for Workstations
)
if %EditionHome%==1 (
if %CoreSingleLanguage%==0 echo. 9. Home Single Language
)
if %EditionPro%==1 (
if %ServerRdsh%==0 echo. 10. Enterprise for Virtual Desktops
)
echo.
echo ============================================================
echo Options:
echo. 1 - Create all editions
echo. 2 - Create one edition
if %_sum% gtr 2 (echo. 3 - Create randomly selected editions)
echo ============================================================
echo.
choice /c 1230 /n /m "Choose a menu option, or press 0 to quit: "
if errorlevel 4 goto :QUIT
if errorlevel 3 if %_sum% gtr 2 goto :RANDOMMENU
if errorlevel 2 goto :SINGLEMENU
if errorlevel 1 goto :ALLMENU
goto :MULTIMENU

:ALLMENU
for %%i in (Enterprise,Education,ProfessionalEducation,ProfessionalWorkstation,ServerRdsh) do (
if %EditionPro%==1 set %%i=1
)
for %%i in (EnterpriseN,EducationN,ProfessionalEducationN,ProfessionalWorkstationN) do (
if %EditionProN%==1 set %%i=1
)
if %EditionHome%==1 set CoreSingleLanguage=1
goto :MAINMENU

:SINGLEMENU
cls
for %%i in (Enterprise,Education,ProfessionalEducation,ProfessionalWorkstation,EnterpriseN,EducationN,ProfessionalEducationN,ProfessionalWorkstationN,CoreSingleLanguage,ServerRdsh) do (
set %%i=0
)
for %%i in (Enterprise,Education,ProfessionalEducation,ProfessionalWorkstation,EnterpriseN,EducationN,ProfessionalEducationN,ProfessionalWorkstationN,CoreSingleLanguage,ServerRdsh) do (
find /i "%%i</EDITIONID>" bin\infoall.txt 1>nul && set %%i=1
)
set _single=
echo ============================================================
if %EditionPro%==1 (
if %Enterprise%==0 echo. 1. Enterprise
if %Education%==0 echo. 2. Education
if %ProfessionalEducation%==0 echo. 3. Pro Education
if %ProfessionalWorkstation%==0 echo. 4. Pro for Workstations
)
if %EditionProN%==1 (
if %EnterpriseN%==0 echo. 5. Enterprise N
if %EducationN%==0 echo. 6. Education N
if %ProfessionalEducationN%==0 echo. 7. Pro Education N
if %ProfessionalWorkstationN%==0 echo. 8. Pro N for Workstations
)
if %EditionHome%==1 (
if %CoreSingleLanguage%==0 echo. 9. Home Single Language
)
if %EditionPro%==1 (
if %ServerRdsh%==0 echo. 10. Enterprise for Virtual Desktops
)
echo.
echo ============================================================
echo Enter edition number to create, or zero '0' to return
echo ============================================================
set /p _single= ^> Enter your option and press "Enter": 
if "%_single%"=="" goto :QUIT
if "%_single%"=="0" (set "_single="&goto :MULTIMENU)
if %_single%==1 if %EditionPro%==1 if %Enterprise%==0 (set Enterprise=1&goto :MAINMENU)
if %_single%==2 if %EditionPro%==1 if %Education%==0 (set Education=1&goto :MAINMENU)
if %_single%==3 if %EditionPro%==1 if %ProfessionalEducation%==0 (set ProfessionalEducation=1&goto :MAINMENU)
if %_single%==4 if %EditionPro%==1 if %ProfessionalWorkstation%==0 (set ProfessionalWorkstation=1&goto :MAINMENU)
if %_single%==5 if %EditionProN%==1 if %EnterpriseN%==0 (set EnterpriseN=1&goto :MAINMENU)
if %_single%==6 if %EditionProN%==1 if %EducationN%==0 (set EducationN=1&goto :MAINMENU)
if %_single%==7 if %EditionProN%==1 if %ProfessionalEducationN%==0 (set ProfessionalEducationN=1&goto :MAINMENU)
if %_single%==8 if %EditionProN%==1 if %ProfessionalWorkstationN%==0 (set ProfessionalWorkstationN=1&goto :MAINMENU)
if %_single%==9 if %EditionHome%==1 if %CoreSingleLanguage%==0 (set CoreSingleLanguage=1&goto :MAINMENU)
if %_single%==10 if %EditionPro%==1 if %ServerRdsh%==0 (set ServerRdsh=1&goto :MAINMENU)
set "_single="
goto :SINGLEMENU

:RANDOMMENU
cls
for %%i in (Enterprise,Education,ProfessionalEducation,ProfessionalWorkstation,EnterpriseN,EducationN,ProfessionalEducationN,ProfessionalWorkstationN,CoreSingleLanguage,ServerRdsh) do (
set %%i=0
)
for %%i in (Enterprise,Education,ProfessionalEducation,ProfessionalWorkstation,EnterpriseN,EducationN,ProfessionalEducationN,ProfessionalWorkstationN,CoreSingleLanguage,ServerRdsh) do (
find /i "%%i</EDITIONID>" bin\infoall.txt 1>nul && set %%i=1
)
set _count=
set _index=
echo ============================================================
if %EditionPro%==1 (
if %Enterprise%==0 echo. 1. Enterprise
if %Education%==0 echo. 2. Education
if %ProfessionalEducation%==0 echo. 3. Pro Education
if %ProfessionalWorkstation%==0 echo. 4. Pro for Workstations
)
if %EditionProN%==1 (
if %EnterpriseN%==0 echo. 5. Enterprise N
if %EducationN%==0 echo. 6. Education N
if %ProfessionalEducationN%==0 echo. 7. Pro Education N
if %ProfessionalWorkstationN%==0 echo. 8. Pro N for Workstations
)
if %EditionHome%==1 (
if %CoreSingleLanguage%==0 echo. 9. Home Single Language
)
if %EditionPro%==1 (
if %ServerRdsh%==0 echo. 10. Enterprise for Virtual Desktops
)
echo.
echo ============================================================
echo Enter editions numbers to create separated with spaces
echo examples: 1 3 4 or 5 1 or 4 2 9
echo Enter zero '0' to return
echo ============================================================
set /p _index= ^> Enter your option and press "Enter": 
if "%_index%"=="" goto :QUIT
if "%_index%"=="0" set "_index="&goto :MULTIMENU
for %%i in (%_index%) do (
if %%i==1 if %EditionPro%==1 if %Enterprise%==0 (set Enterprise=1)
if %%i==2 if %EditionPro%==1 if %Education%==0 (set Education=1)
if %%i==3 if %EditionPro%==1 if %ProfessionalEducation%==0 (set ProfessionalEducation=1)
if %%i==4 if %EditionPro%==1 if %ProfessionalWorkstation%==0 (set ProfessionalWorkstation=1)
if %%i==5 if %EditionProN%==1 if %EnterpriseN%==0 (set EnterpriseN=1)
if %%i==6 if %EditionProN%==1 if %EducationN%==0 (set EducationN=1)
if %%i==7 if %EditionProN%==1 if %ProfessionalEducationN%==0 (set ProfessionalEducationN=1)
if %%i==8 if %EditionProN%==1 if %ProfessionalWorkstationN%==0 (set ProfessionalWorkstationN=1)
if %%i==9 if %EditionHome%==1 if %CoreSingleLanguage%==0 (set CoreSingleLanguage=1)
if %%i==10 if %EditionPro%==1 if %ServerRdsh%==0 (set ServerRdsh=1)
)
goto :MAINMENU

:MAINMENU
cls
for %%i in (Enterprise,Education,ProfessionalEducation,ProfessionalWorkstation,EnterpriseN,EducationN,ProfessionalEducationN,ProfessionalWorkstationN,CoreSingleLanguage,ServerRdsh) do (
find /i "%%i</EDITIONID>" bin\infoall.txt 1>nul && set %%i=0
)
set modified=0
set /a index=%images%
for %%i in (Enterprise,Education,ProfessionalEducation,ProfessionalWorkstation,EnterpriseN,EducationN,ProfessionalEducationN,ProfessionalWorkstationN,CoreSingleLanguage,ServerRdsh) do (
if !%%i!==1 call :%%i %%i
)
if %modified%==1 (goto :ISOCREATE) else (
  echo.
  echo ============================================================
  echo No operation performed.
  echo ============================================================
  echo.
  echo Press any key to exit.
  pause >nul
  GOTO :QUIT
)

:ServerRdsh
set "name=%1"
set "desc=Enterprise for Virtual Desktops"
set "source=%IndexPro%"
set "channel=Volume"
call :WIM
exit /b

:Enterprise
set "name=%1"
set "desc=Enterprise"
set "source=%IndexPro%"
set "channel=Volume"
call :WIM
exit /b

:Education
set "name=%1"
set "desc=Education"
set "source=%IndexPro%"
set "channel=Retail"
call :WIM
exit /b

:ProfessionalEducation
set "name=%1"
set "desc=Pro Education"
set "source=%IndexPro%"
set "channel=Retail"
call :WIM
exit /b

:ProfessionalWorkstation
set "name=%1"
set "desc=Pro for Workstations"
set "source=%IndexPro%"
set "channel=Retail"
call :WIM
exit /b

:EnterpriseN
set "name=%1"
set "desc=Enterprise N"
set "source=%IndexProN%"
set "channel=Volume"
call :WIM
exit /b

:EducationN
set "name=%1"
set "desc=Education N"
set "source=%IndexProN%"
set "channel=Retail"
call :WIM
exit /b

:ProfessionalEducationN
set "name=%1"
set "desc=Pro Education N"
set "source=%IndexProN%"
set "channel=Retail"
call :WIM
exit /b

:ProfessionalWorkstationN
set "name=%1"
set "desc=Pro N for Workstations"
set "source=%IndexProN%"
set "channel=Retail"
call :WIM
exit /b

:CoreSingleLanguage
set "name=%1"
set "desc=Home Single Language"
set "source=%IndexHome%"
set "channel=Retail"
call :WIM
exit /b

:WIM
echo ============================================================
echo Creating Edition: %desc%
echo ============================================================
set modified=1
if exist "%mountdir%" (
"%dismroot%" /English /Unmount-Wim /MountDir:"%mountdir%" /Discard 1>nul 2>nul
"%dismroot%" /English /Cleanup-Wim 1>nul 2>nul
rmdir /s /q "%mountdir%" 1>nul 2>nul
)
if not exist "%mountdir%" mkdir "%mountdir%"
"%dismroot%" /English /Mount-Image /ImageFile:ISOFOLDER\sources\install.wim /Index:%source% /MountDir:"%mountdir%"
SET ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (
"%dismroot%" /English /Unmount-Image /MountDir:"%mountdir%" /Discard 1>nul 2>nul
"%dismroot%" /English /Cleanup-Mountpoints 1>nul 2>nul
"%dismroot%" /English /Cleanup-Wim 1>nul 2>nul
rmdir /s /q "%mountdir%" 1>nul 2>nul
set "MESSAGE=Could not mount image"&goto :E_MSG
)
"%dismroot%" /English /Image:"%mountdir%" /Set-Edition:%name% /Channel:%channel%
SET ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (
"%dismroot%" /English /Unmount-Image /MountDir:"%mountdir%" /Discard 1>nul 2>nul
"%dismroot%" /English /Cleanup-Mountpoints 1>nul 2>nul
"%dismroot%" /English /Cleanup-Wim 1>nul 2>nul
rmdir /s /q "%mountdir%" 1>nul 2>nul
set "MESSAGE=Could not set required edition"&goto :E_MSG
)
"%dismroot%" /English /Unmount-Image /MountDir:"%mountdir%" /Commit /Append
SET ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (
"%dismroot%" /English /Unmount-Image /MountDir:"%mountdir%" /Discard 1>nul 2>nul
"%dismroot%" /English /Cleanup-Mountpoints 1>nul 2>nul
"%dismroot%" /English /Cleanup-Wim 1>nul 2>nul
rmdir /s /q "%mountdir%" 1>nul 2>nul
set "MESSAGE=Could not unmount image"&goto :E_MSG
)
set /a index+=1
bin\imagex.exe /FLAGS %name% /INFO ISOFOLDER\sources\install.wim %index% "Windows 10 %desc%" "Windows 10 %desc%"
rmdir /s /q "%mountdir%" 1>nul 2>nul
exit /b

:ISOCREATE
if %DeleteSource%==1 (
echo.
echo ============================================================
echo Deleting Source Edition^(s^) . . .
echo ============================================================
if %EditionHome%==1 "%dismroot%" /English /Delete-Image /ImageFile:ISOFOLDER\sources\install.wim /Index:%IndexHome%
if %EditionPro%==1 "%dismroot%" /English /Delete-Image /ImageFile:ISOFOLDER\sources\install.wim /Index:%IndexPro%
if %EditionProN%==1 "%dismroot%" /English /Delete-Image /ImageFile:ISOFOLDER\sources\install.wim /Index:%IndexProN%
echo.
echo ============================================================
echo Rebuilding install.wim . . .
echo ============================================================
"%dismroot%" /English /Export-Image /SourceImageFile:ISOFOLDER\sources\install.wim /All /DestinationImageFile:"%~dp0temp.wim"
move /y "%~dp0temp.wim" ISOFOLDER\sources\install.wim >nul
)
if %SkipISO%==1 (
  ren ISOFOLDER %DVDISO%
  echo.
  echo ============================================================
  echo Done. You chose not to create iso file.
  echo ============================================================
  echo.
  echo Press any key to exit.
  pause >nul
  GOTO :QUIT
)
echo.
echo ============================================================
echo Creating ISO . . .
echo ============================================================
if %DeleteSource%==1 call :dPREPARE
for /f "tokens=4-9 delims=: " %%G in ('bin\wimlib-imagex.exe info ISOFOLDER\sources\boot.wim 1 ^| find /i "Creation Time"') do (set mmm=%%G&set "isotime=%%H/%%L,%%I:%%J:%%K")
call :setdate %mmm%
bin\cdimage.exe -bootdata:2#p0,e,b"ISOFOLDER\boot\etfsboot.com"#pEF,e,b"ISOFOLDER\efi\Microsoft\boot\efisys.bin" -o -m -u2 -udfver102 -t%isotime% -g -l%DVDLABEL% ISOFOLDER %DVDISO%.ISO
SET ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (
  ren ISOFOLDER %DVDISO%
  echo.
  echo Errors were reported during ISO creation.
  echo.
  echo Press any key to exit.
  pause >nul
  GOTO :QUIT
)
rmdir /s /q ISOFOLDER\
echo.
echo Press any key to exit.
pause >nul
GOTO :QUIT

:dInfo
bin\imagex.exe /info "%ISOdir%\sources\install.wim">bin\infoall.txt 2>&1
find /i "Core</EDITIONID>" bin\infoall.txt 1>nul && (set EditionHome=1) || (set EditionHome=0)
find /i "Professional</EDITIONID>" bin\infoall.txt 1>nul && (set EditionPro=1) || (set EditionPro=0)
find /i "ProfessionalN</EDITIONID>" bin\infoall.txt 1>nul && (set EditionProN=1) || (set EditionProN=0)
bin\wimlib-imagex.exe info "%ISOdir%\sources\install.wim" 1 >bin\info.txt 2>&1
for /f "tokens=2 delims=: " %%i in ('findstr /i /b "Build" bin\info.txt') do set build=%%i
for /f "tokens=3 delims=: " %%i in ('find /i "Default" bin\info.txt') do set langid=%%i
for /f "tokens=2 delims=: " %%i in ('find /i "Architecture" bin\info.txt') do (IF /I %%i EQU x86 (SET arch=x86) ELSE IF /I %%i EQU x86_64 (SET arch=x64) ELSE (SET arch=arm64))
for /f "tokens=3 delims=: " %%i in ('findstr /i /b /c:"Image Count" bin\infoall.txt') do set images=%%i
del /f /q bin\info.txt
if "%build%" lss "17063" (set "MESSAGE=ISO build %build% do not support virtual editions"&if %_iso%==1 rmdir /s /q "%ISOdir%"&goto :E_MSG)
if %EditionHome%==0 if %EditionPro%==0 if %EditionProN%==0 (set "MESSAGE=No supported source edition detected"&if %_iso%==1 rmdir /s /q "%ISOdir%"&goto :E_MSG)
for /l %%j in (1,1,%images%) do (
if %EditionHome%==1 (bin\imagex.exe /info "%ISOdir%\sources\install.wim" %%j | find /i "Core</EDITIONID>" 1>nul && set IndexHome=%%j)
if %EditionPro%==1 (bin\imagex.exe /info "%ISOdir%\sources\install.wim" %%j | find /i "Professional</EDITIONID>" 1>nul && set IndexPro=%%j)
if %EditionProN%==1 (bin\imagex.exe /info "%ISOdir%\sources\install.wim" %%j | find /i "ProfessionalN</EDITIONID>" 1>nul && set IndexProN=%%j)
)
if %EditionHome%==1 set /a _sum+=1
if %EditionPro%==1 set /a _sum+=4
if %EditionProN%==1 set /a _sum+=4
del /f /q  "%ISOdir%\sources\ei.cfg" 1>nul 2>nul
"%wimlib%" extract "%ISOdir%\sources\install.wim" 1 \Windows\System32\ntoskrnl.exe --dest-dir=.\bin\temp --no-acls >nul 2>&1
bin\7z.exe l .\bin\temp\ntoskrnl.exe >.\bin\temp\version.txt 2>&1
for /f "tokens=4-7 delims=.() " %%i in ('"findstr /i /b "FileVersion" .\bin\temp\version.txt" 2^>nul') do (set version=%%i.%%j&set branch=%%k&set datetime=%%l)
if /i %arch%==x86 (set _ss=x86) else if /i %arch%==x64 (set _ss=amd64) else (set _ss=arm64)
"%wimlib%" extract "%ISOdir%\sources\install.wim" 1 Windows\WinSxS\Manifests\%_ss%_microsoft-windows-coreos-revision* --dest-dir=.\bin\temp --no-acls >nul 2>&1
for /f "tokens=6,7 delims=_." %%i in ('dir /b /od .\bin\temp\*.manifest') do set revision=%%i.%%j
if not "%version%"=="%revision%" (
set version=%revision%
for /f "tokens=5,6,7,8,9,10 delims=: " %%G in ('bin\wimlib-imagex.exe info "%ISOdir%\sources\install.wim" 1 ^| find /i "Last Modification Time"') do (set mmm=%%G&set yyy=%%L&set ddd=%%H-%%I%%J)
call :setmmm !mmm!
)
set _label2=
if /i "%branch%"=="WinBuild" (
"%wimlib%" extract "%ISOdir%\sources\install.wim" 1 \Windows\System32\config\SOFTWARE --dest-dir=.\bin\temp --no-acls >nul
for /f "tokens=3 delims==:" %%a in ('"bin\offlinereg.exe .\bin\temp\SOFTWARE "Microsoft\Windows NT\CurrentVersion" getvalue BuildLabEx" 2^>nul') do if not errorlevel 1 (for /f "tokens=1-5 delims=." %%i in ('echo %%~a') do set _label2=%%i.%%j.%%m.%%l_CLIENT&set branch=%%l)
)
if defined _label2 (set _label=%_label2%) else (set _label=%version%.%datetime%.%branch%_CLIENT)
rmdir /s /q .\bin\temp >nul 2>&1
for %%b in (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do (
set _label=!_label:%%b=%%b!
set branch=!branch:%%b=%%b!
set langid=!langid:%%b=%%b!
set archl=!arch:%%b=%%b!
)
set "DVDLABEL=CCSA_%archl%FRE_%langid%_DV5"
set "DVDISO=%_label%MULTI_UUP_%archl%FRE_%langid%"
if exist "%DVDISO%.ISO" set "DVDISO=%DVDISO%_r"
exit /b

:dPREPARE
for /f "tokens=3 delims=: " %%i in ('bin\imagex.exe /info ISOFOLDER\sources\install.wim ^|findstr /i /b /c:"Image Count"') do set finalimages=%%i
if %finalimages% gtr 1 exit /b
for /f "tokens=3 delims=<>" %%i in ('bin\imagex.exe /info ISOFOLDER\sources\install.wim 1 ^| find /i "<EDITIONID>"') do set editionid=%%i
if /i %editionid%==CoreSingleLanguage set DVDLABEL=CSLA_%archl%FREO_%langid%_DV5&set DVDISO=%_label%SINGLELANGUAGE_OEM_%archl%FRE_%langid%
if /i %editionid%==Enterprise set DVDLABEL=CENA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%ENTERPRISE_VOL_%archl%FRE_%langid%
if /i %editionid%==EnterpriseN set DVDLABEL=CENNA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%ENTERPRISEN_VOL_%archl%FRE_%langid%
if /i %editionid%==Education set DVDLABEL=CEDA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%EDUCATION_RET_%archl%FRE_%langid%
if /i %editionid%==EducationN set DVDLABEL=CEDNA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%EDUCATIONN_RET_%archl%FRE_%langid%
if /i %editionid%==ProfessionalWorkstation set DVDLABEL=CPRWA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%PROWORKSTATION_OEMRET_%archl%FRE_%langid%
if /i %editionid%==ProfessionalWorkstationN set DVDLABEL=CPRWNA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%PROWORKSTATIONN_OEMRET_%archl%FRE_%langid%
if /i %editionid%==ProfessionalEducation set DVDLABEL=CPREA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%PROEDUCATION_OEMRET_%archl%FRE_%langid%
if /i %editionid%==ProfessionalEducationN set DVDLABEL=CPRENA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%PROEDUCATIONN_OEMRET_%archl%FRE_%langid%
if /i %editionid%==ServerRdsh set DVDLABEL=CRDSHA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%ENTREMOTESESSIONS_VOL_%archl%FRE_%langid%
exit /b

:setdate
if /i %1==Jan set "isotime=01/%isotime%"
if /i %1==Feb set "isotime=02/%isotime%"
if /i %1==Mar set "isotime=03/%isotime%"
if /i %1==Apr set "isotime=04/%isotime%"
if /i %1==May set "isotime=05/%isotime%"
if /i %1==Jun set "isotime=06/%isotime%"
if /i %1==Jul set "isotime=07/%isotime%"
if /i %1==Aug set "isotime=08/%isotime%"
if /i %1==Sep set "isotime=09/%isotime%"
if /i %1==Oct set "isotime=10/%isotime%"
if /i %1==Nov set "isotime=11/%isotime%"
if /i %1==Dec set "isotime=12/%isotime%"
exit /b

:setmmm
if /i %1==Jan set "datetime=%yyy:~2%01%ddd%"
if /i %1==Feb set "datetime=%yyy:~2%02%ddd%"
if /i %1==Mar set "datetime=%yyy:~2%03%ddd%"
if /i %1==Apr set "datetime=%yyy:~2%04%ddd%"
if /i %1==May set "datetime=%yyy:~2%05%ddd%"
if /i %1==Jun set "datetime=%yyy:~2%06%ddd%"
if /i %1==Jul set "datetime=%yyy:~2%07%ddd%"
if /i %1==Aug set "datetime=%yyy:~2%08%ddd%"
if /i %1==Sep set "datetime=%yyy:~2%09%ddd%"
if /i %1==Oct set "datetime=%yyy:~2%10%ddd%"
if /i %1==Nov set "datetime=%yyy:~2%11%ddd%"
if /i %1==Dec set "datetime=%yyy:~2%12%ddd%"
exit /b

:E_MSG
echo.
echo ============================================================
echo Error:
echo %MESSAGE%
echo.
echo.
echo Press any key to exit.
pause >nul

:QUIT
if exist ISOFOLDER\ rmdir /s /q ISOFOLDER\
if exist bin\temp\ rmdir /s /q bin\temp\
if exist bin\infoall.txt del /f /q bin\infoall.txt
exit