@echo off
:: Change to 1 to start the process directly
:: it will create editions specified in AutoEditions if possible
set AutoStart=0

:: Specify editions to auto create separated with comma ,
:: allowed: Enterprise,Education,ProfessionalEducation,ProfessionalWorkstation,EnterpriseN,EducationN,ProfessionalEducationN,ProfessionalWorkstationN,CoreSingleLanguage,ServerRdsh
:: example: set AutoEditions=Enterprise,ProfessionalWorkstation,Education
set AutoEditions=Enterprise

rem Change to 1 to delete source edition index (example: create Enterprise and delete Pro)
set DeleteSource=0

rem 0 - source distribution folder will be directly modified
rem 1 - source distribution folder will be copied then modified
rem if source distribution is .ISO file, this option has no affect
set Preserve=0

rem Change to 1 for not creating ISO file, setup media folder will be kept
set SkipISO=0

rem script:     abbodi1406
rem wimlib:     synchronicity
rem offlinereg: erwan.l

if exist "%Windir%\Sysnative\reg.exe" (set "SysPath=%Windir%\Sysnative") else (set "SysPath=%Windir%\System32")
set "Path=%SysPath%;%Windir%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
set xOS=x64
if /i %PROCESSOR_ARCHITECTURE%==x86 (if "%PROCESSOR_ARCHITEW6432%"=="" set xOS=x86)
set "params=%*"
if not "%~1"=="" (
set "params=%params:"=%"
)
cd /d "%~dp0" && ( if exist "%temp%\getadmin.vbs" del "%temp%\getadmin.vbs" ) && fsutil dirty query %systemdrive% 1>nul 2>nul || (  cmd /u /c echo set UAC = CreateObject^("Shell.Application"^) : UAC.ShellExecute "cmd.exe", "/k cd ""%~dp0"" && ""%~dpnx0"" ""%params%""", "", "runas", 1 >> "%temp%\getadmin.vbs" && "%temp%\getadmin.vbs" 1>nul 2>nul && exit /B )

title Virtual Editions
for %%a in (wimlib-imagex,7z,imagex,offlinereg) do (
if not exist "%~dp0bin\%%a.exe" (echo Error: required %%a.exe is missing&pause&exit)
)
if /i "%xOS%" equ "x64" (set "wimlib=%~dp0bin\bin64\wimlib-imagex.exe") else (set "wimlib=%~dp0bin\wimlib-imagex.exe")
cd /d "%~dp0"
setlocal EnableExtensions
setlocal EnableDelayedExpansion
if exist bin\temp\ rmdir /s /q bin\temp\
set ERRORTEMP=
set _dir=0
set _iso=0
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G
set "dismroot=dism.exe"
set "mountdir=%SystemDrive%\MountUUP"
set "line============================================================="

:checkadk
set regKeyPathFound=1
set wowRegKeyPathFound=1
reg query "HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 1>nul 2>nul || set wowRegKeyPathFound=0
reg query "HKLM\Software\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 1>nul 2>nul || set regKeyPathFound=0
if %wowRegKeyPathFound% equ 0 (
  if %regKeyPathFound% equ 0 (
    set ADK=0&goto :precheck
  ) else (
    set regKeyPath=HKLM\Software\Microsoft\Windows Kits\Installed Roots
  )
) else (
    set regKeyPath=HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots
)
for /f "skip=2 tokens=2*" %%i in ('reg query "%regKeyPath%" /v KitsRoot10') do (set "KitsRoot=%%j")
set "DandIRoot=%KitsRoot%Assessment and Deployment Kit\Deployment Tools"
set "dismroot=%DandIRoot%\%PROCESSOR_ARCHITECTURE%\DISM\dism.exe"
set ADK=1
if not exist "%dismroot%" set ADK=0&set "dismroot=dism.exe"

:precheck
if %winbuild% lss 10240 if %ADK% equ 0 (set "MESSAGE=Host OS is not compatible, and Windows 10 ADK is not detected"&goto :E_MSG)
if /i "%dismroot%"=="dism.exe" (set _dism=dism.exe /English) else (set _dism="%dismroot%" /English)
if /i "%params%"=="auto" (set AutoStart=1&set Preserve=0)

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
echo %line%
echo Enter / Paste the complete path to ISO file
echo %line%
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
echo %line%
echo Extracting ISO file . . .
echo %line%
echo.
set "ISOdir=ISOUUP"
echo "%ISOfile%"
if exist %ISOdir%\ rmdir /s /q %ISOdir%\
bin\7z.exe x "%ISOfile%" -o%ISOdir% * -r >nul
bin\imagex.exe /info "%ISOdir%\sources\install.wim" | findstr /i /c:"LZMS" >nul && (set "MESSAGE=Detected install.wim file is actually .esd file"&if %_iso%==1 rmdir /s /q "%ISOdir%"&goto :E_MSG)

:dCheck
color 1f
echo.
echo %line%
echo Checking distribution Info . . .
echo %line%
call :dInfo
if %Preserve%==1 (
echo.
echo %line%
echo Copying distribution folder. . .
echo %line%
xcopy "%ISOdir%\*" ISOFOLDER\ /cheriky >nul 2>&1
) else (
move "%ISOdir%" ISOFOLDER >nul
)
if %AutoStart%==1 (
if not defined AutoEditions (set "MESSAGE=No editions specified for auto creation"&goto :E_MSG)
for %%i in (%AutoEditions%) do (
  if /i %%i==Enterprise if %EditionPro%==1 (set Enterprise=1)
  if /i %%i==Education if %EditionPro%==1 (set Education=1)
  if /i %%i==ProfessionalEducation if %EditionPro%==1 (set ProfessionalEducation=1)
  if /i %%i==ProfessionalWorkstation if %EditionPro%==1 (set ProfessionalWorkstation=1)
  if /i %%i==EnterpriseN if %EditionProN%==1 (set EnterpriseN=1)
  if /i %%i==EducationN if %EditionProN%==1 (set EducationN=1)
  if /i %%i==ProfessionalEducationN if %EditionProN%==1 (set ProfessionalEducationN=1)
  if /i %%i==ProfessionalWorkstationN if %EditionProN%==1 (set ProfessionalWorkstationN=1)
  if /i %%i==CoreSingleLanguage if %EditionHome%==1 (set CoreSingleLanguage=1)
  if /i %%i==ServerRdsh if %EditionPro%==1 (set ServerRdsh=1)
  )
goto :MAINMENU
)

:MULTIMENU
for %%i in (Enterprise,Education,ProfessionalEducation,ProfessionalWorkstation,EnterpriseN,EducationN,ProfessionalEducationN,ProfessionalWorkstationN,CoreSingleLanguage,ServerRdsh) do (
set %%i=0
)
for %%i in (Enterprise,Education,ProfessionalEducation,ProfessionalWorkstation,EnterpriseN,EducationN,ProfessionalEducationN,ProfessionalWorkstationN,CoreSingleLanguage,ServerRdsh) do (
find /i "<EDITIONID>%%i</EDITIONID>" bin\infoall.txt 1>nul && set %%i=1
)
cls
echo %line%
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
echo %line%
echo Options:
echo. 1 - Create all editions
echo. 2 - Create one edition
if %_sum% gtr 2 (echo. 3 - Create randomly selected editions)
echo %line%
echo.
choice /c 1230 /n /m "Choose a menu option, or press 0 to quit: "
if errorlevel 4 goto :QUIT
if errorlevel 3 goto :RANDOMMENU
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
find /i "<EDITIONID>%%i</EDITIONID>" bin\infoall.txt 1>nul && set %%i=1
)
set _single=
echo %line%
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
echo %line%
echo Enter edition number to create, or zero '0' to return
echo %line%
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
find /i "<EDITIONID>%%i</EDITIONID>" bin\infoall.txt 1>nul && set %%i=1
)
set _count=
set _index=
echo %line%
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
echo %line%
echo Enter editions numbers to create separated with spaces
echo examples: 1 3 4 or 5 1 or 4 2 10
echo Enter zero '0' to return
echo %line%
set /p _index= ^> Enter your option and press "Enter": 
if "%_index%"=="" goto :QUIT
if "%_index%"=="0" (set "_index="&goto :MULTIMENU)
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
find /i "<EDITIONID>%%i</EDITIONID>" bin\infoall.txt 1>nul && set %%i=0
)
set modified=0
set /a index=%images%
for %%i in (Enterprise,Education,ProfessionalEducation,ProfessionalWorkstation,EnterpriseN,EducationN,ProfessionalEducationN,ProfessionalWorkstationN,CoreSingleLanguage,ServerRdsh) do (
if !%%i!==1 call :%%i %%i
)
if %modified%==1 (goto :ISOCREATE) else (
  echo.
  echo %line%
  echo No operation performed.
  echo %line%
  echo.
  echo Press any key to exit.
  pause >nul
  goto :QUIT
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
set "channel=Volume"
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
set "channel=Volume"
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
echo %line%
echo Creating Edition: %desc%
echo %line%
set modified=1
if exist "%mountdir%" rmdir /s /q "%mountdir%" 1>nul 2>nul
if not exist "%mountdir%" mkdir "%mountdir%"
%_dism% /Mount-Image /ImageFile:ISOFOLDER\sources\install.wim /Index:%source% /MountDir:"%mountdir%"
set ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% neq 0 (
%_dism% /Unmount-Image /MountDir:"%mountdir%" /Discard 1>nul 2>nul
%_dism% /Cleanup-Mountpoints 1>nul 2>nul
%_dism% /Cleanup-Wim 1>nul 2>nul
rmdir /s /q "%mountdir%" 1>nul 2>nul
set "MESSAGE=Could not mount the image"&goto :E_MSG
)
%_dism% /Image:"%mountdir%" /Set-Edition:%name% /Channel:%channel%
set ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% neq 0 (
%_dism% /Unmount-Image /MountDir:"%mountdir%" /Discard 1>nul 2>nul
%_dism% /Cleanup-Mountpoints 1>nul 2>nul
%_dism% /Cleanup-Wim 1>nul 2>nul
rmdir /s /q "%mountdir%" 1>nul 2>nul
set "MESSAGE=Could not set required edition"&goto :E_MSG
)
%_dism% /Unmount-Image /MountDir:"%mountdir%" /Commit /Append
set ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% neq 0 (
%_dism% /Unmount-Image /MountDir:"%mountdir%" /Discard 1>nul 2>nul
%_dism% /Cleanup-Mountpoints 1>nul 2>nul
%_dism% /Cleanup-Wim 1>nul 2>nul
rmdir /s /q "%mountdir%" 1>nul 2>nul
set "MESSAGE=Could not unmount the image"&goto :E_MSG
)
set /a index+=1
bin\imagex.exe /FLAGS %name% /INFO ISOFOLDER\sources\install.wim %index% "Windows 10 %desc%" "Windows 10 %desc%"
rmdir /s /q "%mountdir%" 1>nul 2>nul
exit /b

:ISOCREATE
if %DeleteSource%==1 (
echo.
echo %line%
echo Deleting Source Edition^(s^) . . .
echo %line%
if %EditionHome%==1 %_dism% /Delete-Image /ImageFile:ISOFOLDER\sources\install.wim /Index:%IndexHome%
if %EditionPro%==1 %_dism% /Delete-Image /ImageFile:ISOFOLDER\sources\install.wim /Index:%IndexPro%
if %EditionProN%==1 %_dism% /Delete-Image /ImageFile:ISOFOLDER\sources\install.wim /Index:%IndexProN%
echo.
echo %line%
echo Rebuilding install.wim . . .
echo %line%
%_dism% /Export-Image /SourceImageFile:ISOFOLDER\sources\install.wim /All /DestinationImageFile:"%~dp0temp.wim"
move /y "%~dp0temp.wim" ISOFOLDER\sources\install.wim >nul
)
if exist "ISOFOLDER\sources\ei.cfg" del /f /q  "ISOFOLDER\sources\ei.cfg" >nul
if %SkipISO%==1 (
  ren ISOFOLDER %DVDISO%
  echo.
  echo %line%
  echo Done. You chose not to create iso file.
  echo %line%
  echo.
  echo Press any key to exit.
  pause >nul
  goto :QUIT
)
echo.
echo %line%
echo Creating ISO . . .
echo %line%
if %DeleteSource%==1 call :dPREPARE
bin\cdimage.exe -bootdata:2#p0,e,b"ISOFOLDER\boot\etfsboot.com"#pEF,e,b"ISOFOLDER\efi\Microsoft\boot\efisys.bin" -o -m -u2 -udfver102 -t%isotime% -l%DVDLABEL% ISOFOLDER %DVDISO%.ISO
set ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% neq 0 (
  ren ISOFOLDER %DVDISO%
  echo.
  echo Errors were reported during ISO creation.
  echo.
  echo Press any key to exit.
  pause >nul
  goto :QUIT
)
rmdir /s /q ISOFOLDER\
echo.
echo Press any key to exit.
pause >nul
goto :QUIT

:dInfo
bin\imagex.exe /info "%ISOdir%\sources\install.wim">bin\infoall.txt 2>&1
find /i "Core</EDITIONID>" bin\infoall.txt 1>nul && (set EditionHome=1) || (set EditionHome=0)
find /i "Professional</EDITIONID>" bin\infoall.txt 1>nul && (set EditionPro=1) || (set EditionPro=0)
find /i "ProfessionalN</EDITIONID>" bin\infoall.txt 1>nul && (set EditionProN=1) || (set EditionProN=0)
bin\wimlib-imagex.exe info "%ISOdir%\sources\install.wim" 1 >bin\info.txt 2>&1
for /f "tokens=2 delims=: " %%i in ('findstr /i /b "Build" bin\info.txt') do set build=%%i
for /f "tokens=3 delims=: " %%i in ('find /i "Default" bin\info.txt') do set langid=%%i
for /f "tokens=2 delims=: " %%i in ('find /i "Architecture" bin\info.txt') do (if /i %%i equ x86 (set arch=x86) else if /i %%i equ x86_64 (set arch=x64) else (set arch=arm64))
for /f "tokens=3 delims=: " %%i in ('findstr /i /b /c:"Image Count" bin\infoall.txt') do set images=%%i
del /f /q bin\info.txt >nul
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
"%wimlib%" extract "%ISOdir%\sources\boot.wim" 2 sources\setuphost.exe --dest-dir=.\bin\temp --no-acls --no-attributes >nul 2>&1
bin\7z.exe l .\bin\temp\setuphost.exe >.\bin\temp\version.txt 2>&1
for /f "tokens=4-7 delims=.() " %%i in ('"findstr /i /b "FileVersion" .\bin\temp\version.txt" 2^>nul') do (set version=%%i.%%j&set branch=%%k&set labeldate=%%l)
set "isotime=!labeldate:~2,2!/!labeldate:~4,2!/20!labeldate:~0,2!,!labeldate:~7,2!:!labeldate:~9,2!:10"
if /i %arch%==x86 (set _ss=x86) else if /i %arch%==x64 (set _ss=amd64) else (set _ss=arm64)
"%wimlib%" extract "%ISOdir%\sources\install.wim" 1 Windows\WinSxS\Manifests\%_ss%_microsoft-windows-coreos-revision* --dest-dir=.\bin\temp --no-acls --no-attributes >nul 2>&1
for /f "tokens=6,7 delims=_." %%i in ('dir /b /od .\bin\temp\*.manifest') do set revision=%%i.%%j
if not "%version%"=="%revision%" (
set version=%revision%
"%wimlib%" extract "%ISOdir%\sources\install.wim" 1 Windows\servicing\Packages\Package_for_RollupFix*.mum --dest-dir=.\bin\temp --no-acls --no-attributes >nul 2>&1
for /f %%i in ('dir /b /a:-d /od .\bin\temp\Package_for_RollupFix*.mum') do set "mumfile=%~dp0bin\temp\%%i"
for /f "tokens=2 delims==" %%i in ('wmic datafile where "name='!mumfile:\=\\!'" get LastModified /value') do set "mumdate=%%i"
set "labeldate=!mumdate:~2,2!!mumdate:~4,2!!mumdate:~6,2!-!mumdate:~8,4!"
set "isotime=!mumdate:~4,2!/!mumdate:~6,2!/!mumdate:~0,4!,!mumdate:~8,2!:!mumdate:~10,2!:!mumdate:~12,2!"
)
set _label2=
if /i "%branch%"=="WinBuild" (
"%wimlib%" extract "%ISOdir%\sources\install.wim" 1 \Windows\System32\config\SOFTWARE --dest-dir=.\bin\temp --no-acls --no-attributes >nul
for /f "tokens=3 delims==:" %%a in ('"bin\offlinereg.exe .\bin\temp\SOFTWARE "Microsoft\Windows NT\CurrentVersion" getvalue BuildLabEx" 2^>nul') do if not errorlevel 1 (for /f "tokens=1-5 delims=." %%i in ('echo %%~a') do set _label2=%%i.%%j.%%m.%%l_CLIENT&set branch=%%l)
)
if defined _label2 (set _label=%_label2%) else (set _label=%version%.%labeldate%.%branch%_CLIENT)
rmdir /s /q .\bin\temp >nul 2>&1
for %%b in (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do (
set _label=!_label:%%b=%%b!
set branch=!branch:%%b=%%b!
set langid=!langid:%%b=%%b!
set archl=!arch:%%b=%%b!
)
set "DVDLABEL=CCSA_%archl%FRE_%langid%_DV5"
set "DVDISO=%_label%MULTI_%archl%FRE_%langid%"
if exist "%DVDISO%.ISO" set "DVDISO=%DVDISO%_r"
exit /b

:dPREPARE
for /f "tokens=3 delims=: " %%i in ('bin\imagex.exe /info ISOFOLDER\sources\install.wim ^|findstr /i /b /c:"Image Count"') do set finalimages=%%i
if %finalimages% gtr 1 exit /b
set _VL=0
for /f "tokens=3 delims=<>" %%i in ('bin\imagex.exe /info ISOFOLDER\sources\install.wim 1 ^| find /i "<EDITIONID>"') do set editionid=%%i
if /i %editionid%==CoreSingleLanguage set DVDLABEL=CSLA_%archl%FREO_%langid%_DV5&set DVDISO=%_label%SINGLELANGUAGE_OEM_%archl%FRE_%langid%
if /i %editionid%==Enterprise set DVDLABEL=CENA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%ENTERPRISE_VOL_%archl%FRE_%langid%&set _VL=1
if /i %editionid%==EnterpriseN set DVDLABEL=CENNA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%ENTERPRISEN_VOL_%archl%FRE_%langid%&set _VL=1
if /i %editionid%==Education set DVDLABEL=CEDA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%EDUCATION_RET_%archl%FRE_%langid%&set _VL=1
if /i %editionid%==EducationN set DVDLABEL=CEDNA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%EDUCATIONN_RET_%archl%FRE_%langid%&set _VL=1
if /i %editionid%==ProfessionalWorkstation set DVDLABEL=CPRWA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%PROWORKSTATION_OEMRET_%archl%FRE_%langid%
if /i %editionid%==ProfessionalWorkstationN set DVDLABEL=CPRWNA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%PROWORKSTATIONN_OEMRET_%archl%FRE_%langid%
if /i %editionid%==ProfessionalEducation set DVDLABEL=CPREA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%PROEDUCATION_OEMRET_%archl%FRE_%langid%
if /i %editionid%==ProfessionalEducationN set DVDLABEL=CPRENA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%PROEDUCATIONN_OEMRET_%archl%FRE_%langid%
if /i %editionid%==ServerRdsh set DVDLABEL=CRDSHA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%ENTREMOTESESSIONS_VOL_%archl%FRE_%langid%&set _VL=1
if %_VL%==0 exit /b
(
echo [EditionID]
echo %editionid%
echo.
echo [Channel]
echo Volume
echo.
echo [VL]
echo 1
)>ISOFOLDER\sources\EI.CFG
exit /b

:E_MSG
echo.
echo %line%
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