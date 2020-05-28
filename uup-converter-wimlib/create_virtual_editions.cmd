<!-- : Begin batch script
@setlocal DisableDelayedExpansion
@set uivr=v45
@echo off
:: Change to 1 to start the process directly
:: it will create editions specified in AutoEditions if possible
set AutoStart=0

:: Specify target editions to auto create separated with space or comma ,
:: leave it empty to create *all* possible editions
:: allowed: Enterprise,Education,ProfessionalEducation,ProfessionalWorkstation,EnterpriseN,EducationN,ProfessionalEducationN,ProfessionalWorkstationN,CoreSingleLanguage,ServerRdsh,IoTEnterprise
:: example: set "AutoEditions=Enterprise,ProfessionalWorkstation,Education"
:: example: set "AutoEditions=Enterprise ServerRdsh"
set "AutoEditions="

:: Change to 1 to delete source edition index (example: create Enterprise and delete Pro)
set DeleteSource=0

:: 0 - source distribution folder will be directly modified
:: 1 - source distribution folder will be copied then modified
:: if source distribution is .ISO file, this option has no affect
set Preserve=0

:: Change to 1 to convert install.wim to install.esd
set wim2esd=0

:: Change to 1 for not creating ISO file, result distribution folder will be kept
set SkipISO=0

:: script:     abbodi1406
:: new method: mkuba50
:: wimlib:     synchronicity
:: offlinereg: erwan.l

:: ###################################################################

set "_Const=1>nul 2>nul"

set _Debug=0
set _elev=
set _args=%*
if not defined _args goto :NoProgArgs
if "%~1"=="" set "_args="&goto :NoProgArgs
if "%~1"=="-elevated" set _elev=1&set "_args="&goto :NoProgArgs
if "%~5"=="-elevated" set _elev=1

:NoProgArgs
set "SysPath=%SystemRoot%\System32"
if exist "%SystemRoot%\Sysnative\reg.exe" (set "SysPath=%SystemRoot%\Sysnative")
set "xDS=bin\bin64;bin"
if /i %PROCESSOR_ARCHITECTURE%==x86 (if not defined PROCESSOR_ARCHITEW6432 (
  set "xDS=bin"
  )
)
set "Path=%xDS%;%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
set "_err===== ERROR ===="

%_Const% reg query HKU\S-1-5-19 && (
  goto :Passed
  ) || (
  if defined _elev goto :E_Admin
)

set _PSarg="""%~f0""" -elevated
if defined _args set _PSarg="""%~f0""" %_args:"="""% -elevated
set _PSarg=%_PSarg:'=''%

(%_Const% cscript //NoLogo "%~f0?.wsf" //job:ELAV /File:"%~f0" %* -elevated) && (
  exit /b
  ) || (
  call setlocal EnableDelayedExpansion
  %_Const% powershell -noprofile -exec bypass -c "start cmd.exe -Arg '/c \"!_PSarg!\"' -verb runas" && (
    exit /b
    ) || (
    goto :E_Admin
  )
)

:Passed
set "_work=%~dp0"
set "_work=%_work:~0,-1%"
setlocal EnableDelayedExpansion
pushd "!_work!"
if exist "convert-UUP.cmd" for /f "tokens=2 delims==" %%# in ('findstr /i /b /c:"set _Debug" "convert-UUP.cmd"') do if not defined _udbg set _udbg=%%#
if defined _udbg set _Debug=%_udbg%

if %_Debug% equ 0 (
  set "_Nul1=1>nul"
  set "_Nul2=2>nul"
  set "_Nul6=2^>nul"
  set "_Nul3=1>nul 2>nul"
  set "_Pause=pause >nul"
  set "_Contn=echo Press any key to continue..."
  set "_Exit=echo Press any key to exit."
  set "_Supp="
  goto :Begin
)
  set "_Nul1="
  set "_Nul2="
  set "_Nul6="
  set "_Nul3="
  set "_Pause=rem."
  set "_Contn=rem."
  set "_Exit=rem."
  set "_Supp=1>nul"
@echo on
@prompt $G

:Begin
title Virtual Editions %uivr%
set "vEditions=Enterprise,Education,ProfessionalEducation,ProfessionalWorkstation,EnterpriseN,EducationN,ProfessionalEducationN,ProfessionalWorkstationN,CoreSingleLanguage,ServerRdsh,IoTEnterprise,IoTEnterpriseS"
set ERRORTEMP=
set _all=0
set _dir=0
set _dvd=0
set _iso=0
set "line============================================================="
if defined _args (
if /i "%~1"=="autowim" set AutoStart=1&set Preserve=0&set _Debug=1&set wim2esd=0
if /i "%~1"=="autoesd" set AutoStart=1&set Preserve=0&set _Debug=1&set wim2esd=1
if /i "%~1"=="manuwim" set wim2esd=0
if /i "%~1"=="manuesd" set wim2esd=1
if /i not "%~2"=="" set "eLabel=%~2"
if /i not "%~3"=="" set "eTime=%~3,%~4"
)
set _file=(7z.dll,7z.exe,cdimage.exe,imagex.exe,libwim-15.dll,offlinereg.exe,offreg.dll,wimlib-imagex.exe)
for %%# in %_file% do (
if not exist ".\bin\%%#" (set _bin=%%#&goto :E_Bin)
)
if not exist "ConvertConfig.ini" goto :proceed
findstr /i \[create_virtual_editions\] ConvertConfig.ini %_Nul1% || goto :proceed
for %%# in (
AutoStart
DeleteSource
Preserve
SkipISO
wim2esd
) do (
call :ReadINI %%#
)
findstr /b /i vAutoEditions ConvertConfig.ini %_Nul1% && for /f "tokens=1* delims==" %%A in ('findstr /b /i vAutoEditions ConvertConfig.ini') do set "AutoEditions=%%B"
goto :proceed

:ReadINI
findstr /b /i v%1 ConvertConfig.ini %_Nul1% && for /f "tokens=2 delims==" %%# in ('findstr /b /i v%1 ConvertConfig.ini') do set "%1=%%#"
goto :eof

:proceed
dir /b /ad . %_Nul3% || goto :checkdvd
for /f "tokens=* delims=" %%# in ('dir /b /ad .') do (
if exist "%%~#\sources\install.wim" set _dir=1&set "ISOdir=%%~#"
if exist "%%~#\sources\install.esd" set _dir=1&set "ISOdir=%%~#"
)
if %_dir% neq 1 goto :checkdvd
goto :dCheck

:checkdvd
for %%# in (D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do (
if exist "%%#:\sources\install.wim" set _dvd=1&set "ISOdir=%%#:"
if exist "%%#:\sources\install.esd" set _dvd=1&set "ISOdir=%%#:"
)
if %_dvd% neq 1 goto :checkiso
goto :dCheck

:checkiso
if exist "*.iso" for /f "tokens=* delims=" %%# in ('dir /b /a:-d *.iso') do (
set _iso+=1
set "ISOfile=%%~#"
)
if %_iso% equ 1 (
set Preserve=0
goto :dISO
)
if %_Debug% neq 0 goto :dCheck

:prompt
cls
set ISOfile=
echo %line%
echo Enter / Paste the complete path to ISO file
echo %line%
echo.
set /p ISOfile=
if not defined ISOfile set _Debug=1&goto :QUIT
set "ISOfile=%ISOfile:"=%"
if not exist "%ISOfile%" (
echo.
echo %_err%
echo Specified path is not a valid ISO file
echo.
%_Contn%&%_Pause%
goto :prompt
)
if /i not "%ISOfile:~-4%"==".iso" (
echo.
echo %_err%
echo Specified path is not a valid ISO file
echo.
%_Contn%&%_Pause%
goto :prompt
)
set _iso=1
set Preserve=0

:dISO
color 1F
cls
echo.
echo %line%
echo Extracting ISO file . . .
echo %line%
echo.
echo "!ISOfile!"
set "ISOdir=ISOUUP"
if exist %ISOdir%\ rmdir /s /q %ISOdir%\
7z.exe x "!ISOfile!" -o%ISOdir% * -r %_Const%

:dCheck
if defined _Supp (
if defined _args echo "!_args!"
echo "!_work!"
)
if %_Debug% neq 0 (
if %AutoStart% equ 0 set AutoStart=1
)
if not defined ISOdir exit /b
if exist bin\temp\ rmdir /s /q bin\temp\
color 1F
set _configured=0
for %%# in (
AutoStart
DeleteSource
Preserve
SkipISO
wim2esd
) do (
if !%%#! equ 1 set _configured=1
)
echo.
echo %line%
echo Checking Distribution Info . . .
echo %line%
if %_dvd% equ 1 set Preserve=1
goto :dInfo

:AUTOMENU
if %AutoStart% equ 0 goto :MULTIMENU
if not defined AutoEditions set "AutoEditions=%vEditions%"
for %%# in (%AutoEditions%) do (
if /i %%#==Enterprise if %EditionPro% equ 1 (set Enterprise=1)
if /i %%#==Education if %EditionPro% equ 1 (set Education=1)
if /i %%#==ProfessionalEducation if %EditionPro% equ 1 (set ProfessionalEducation=1)
if /i %%#==ProfessionalWorkstation if %EditionPro% equ 1 (set ProfessionalWorkstation=1)
if /i %%#==EnterpriseN if %EditionProN% equ 1 (set EnterpriseN=1)
if /i %%#==EducationN if %EditionProN% equ 1 (set EducationN=1)
if /i %%#==ProfessionalEducationN if %EditionProN% equ 1 (set ProfessionalEducationN=1)
if /i %%#==ProfessionalWorkstationN if %EditionProN% equ 1 (set ProfessionalWorkstationN=1)
if /i %%#==CoreSingleLanguage if %EditionHome% equ 1 (set CoreSingleLanguage=1)
if /i %%#==ServerRdsh if %EditionPro% equ 1 (set ServerRdsh=1)
if /i %%#==IoTEnterprise if %EditionPro% equ 1 if %_build% geq 18277 (set IoTEnterprise=1)
if /i %%#==IoTEnterpriseS if %EditionLTSC% equ 1 if %_build% geq 18298 (set IoTEnterpriseS=1)
)
goto :CREATEMENU

:SHWOINFO
for %%# in (%vEditions%) do (
set %%#=0
)
for %%# in (%vEditions%) do (
find /i "<EDITIONID>%%#</EDITIONID>" bin\infoall.txt %_Nul1% && set %%#=1
)
if %EditionPro% equ 1 (
if %Enterprise% equ 0 echo. 1. Enterprise
if %Education% equ 0 echo. 2. Education
if %ProfessionalEducation% equ 0 echo. 3. Pro Education
if %ProfessionalWorkstation% equ 0 echo. 4. Pro for Workstations
)
if %EditionProN% equ 1 (
if %EnterpriseN% equ 0 echo. 5. Enterprise N
if %EducationN% equ 0 echo. 6. Education N
if %ProfessionalEducationN% equ 0 echo. 7. Pro Education N
if %ProfessionalWorkstationN% equ 0 echo. 8. Pro N for Workstations
)
if %EditionHome% equ 1 (
if %CoreSingleLanguage% equ 0 echo. 9. Home Single Language
)
if %EditionPro% equ 1 (
if %ServerRdsh% equ 0 echo 10. Enterprise for Virtual Desktops
if %IoTEnterprise% equ 0 if %_build% geq 18277 echo 11. IoT Enterprise {OEM}
)
if %EditionLTSC% equ 1 (
if %IoTEnterpriseS% equ 0 if %_build% geq 18298 echo 12. IoT Enterprise LTSC {OEM}
)
exit /b

:MULTIMENU
cls
echo %line%
echo Available Target Editions:
call :SHWOINFO
echo.
echo %line%
echo Options:
echo. 1 - Create all editions
echo. 2 - Create one edition
if %_sum% gtr 2 echo. 3 - Create randomly selected editions
echo %line%
echo.
choice /c 1230 /n /m "Choose a menu option, or press 0 to quit: "
if errorlevel 4 (set _Debug=1&goto :QUIT)
if errorlevel 3 goto :RANDOMMENU
if errorlevel 2 goto :SINGLEMENU
if errorlevel 1 goto :ALLMENU
goto :MULTIMENU

:ALLMENU
for %%# in (Enterprise,Education,ProfessionalEducation,ProfessionalWorkstation,ServerRdsh) do (
if %EditionPro% equ 1 set %%#=1
)
for %%# in (EnterpriseN,EducationN,ProfessionalEducationN,ProfessionalWorkstationN) do (
if %EditionProN% equ 1 set %%#=1
)
if %EditionHome% equ 1 set CoreSingleLanguage=1
if %EditionPro% equ 1 if %_build% geq 18277 set IoTEnterprise=1
if %EditionLTSC% equ 1 if %_build% geq 18298 set IoTEnterpriseS=1
goto :CREATEMENU

:SINGLEMENU
cls
set verify=0
set _single=
echo %line%
call :SHWOINFO
echo.
echo %line%
echo Enter edition number to create, or zero '0' to return
echo %line%
set /p _single= ^> Enter your option and press "Enter": 
if not defined _single (set _Debug=1&goto :QUIT)
if "%_single%"=="0" (set "_single="&goto :MULTIMENU)
if %_single% equ 1 if %EditionPro% equ 1 if %Enterprise% equ 0 (set Enterprise=1&set verify=1)
if %_single% equ 2 if %EditionPro% equ 1 if %Education% equ 0 (set Education=1&set verify=1)
if %_single% equ 3 if %EditionPro% equ 1 if %ProfessionalEducation% equ 0 (set ProfessionalEducation=1&set verify=1)
if %_single% equ 4 if %EditionPro% equ 1 if %ProfessionalWorkstation% equ 0 (set ProfessionalWorkstation=1&set verify=1)
if %_single% equ 5 if %EditionProN% equ 1 if %EnterpriseN% equ 0 (set EnterpriseN=1&set verify=1)
if %_single% equ 6 if %EditionProN% equ 1 if %EducationN% equ 0 (set EducationN=1&set verify=1)
if %_single% equ 7 if %EditionProN% equ 1 if %ProfessionalEducationN% equ 0 (set ProfessionalEducationN=1&set verify=1)
if %_single% equ 8 if %EditionProN% equ 1 if %ProfessionalWorkstationN% equ 0 (set ProfessionalWorkstationN=1&set verify=1)
if %_single% equ 9 if %EditionHome% equ 1 if %CoreSingleLanguage% equ 0 (set CoreSingleLanguage=1&set verify=1)
if %_single% equ 10 if %EditionPro% equ 1 if %ServerRdsh% equ 0 (set ServerRdsh=1&set verify=1)
if %_single% equ 11 if %EditionPro% equ 1 if %IoTEnterprise% equ 0 if %_build% geq 18277 (set IoTEnterprise=1&set verify=1)
if %_single% equ 12 if %EditionLTSC% equ 1 if %IoTEnterpriseS% equ 0 if %_build% geq 18298 (set IoTEnterpriseS=1&set verify=1)
if %verify% equ 1 goto :CREATEMENU
set _single=
goto :SINGLEMENU

:RANDOMMENU
cls
set verify=0
set _count=
set _index=
echo %line%
call :SHWOINFO
echo.
echo %line%
echo Enter editions numbers to create separated with spaces
echo examples: 1 3 4 or 5 1 or 4 2 10
echo Enter zero '0' to return
echo %line%
set /p _index= ^> Enter your option and press "Enter": 
if not defined _index (set _Debug=1&goto :QUIT)
if "%_index%"=="0" (set "_index="&goto :MULTIMENU)
for %%# in (%_index%) do (
if %%# equ 1 if %EditionPro% equ 1 if %Enterprise% equ 0 (set Enterprise=1&set verify=1)
if %%# equ 2 if %EditionPro% equ 1 if %Education% equ 0 (set Education=1&set verify=1)
if %%# equ 3 if %EditionPro% equ 1 if %ProfessionalEducation% equ 0 (set ProfessionalEducation=1&set verify=1)
if %%# equ 4 if %EditionPro% equ 1 if %ProfessionalWorkstation% equ 0 (set ProfessionalWorkstation=1&set verify=1)
if %%# equ 5 if %EditionProN% equ 1 if %EnterpriseN% equ 0 (set EnterpriseN=1&set verify=1)
if %%# equ 6 if %EditionProN% equ 1 if %EducationN% equ 0 (set EducationN=1&set verify=1)
if %%# equ 7 if %EditionProN% equ 1 if %ProfessionalEducationN% equ 0 (set ProfessionalEducationN=1&set verify=1)
if %%# equ 8 if %EditionProN% equ 1 if %ProfessionalWorkstationN% equ 0 (set ProfessionalWorkstationN=1&set verify=1)
if %%# equ 9 if %EditionHome% equ 1 if %CoreSingleLanguage% equ 0 (set CoreSingleLanguage=1&set verify=1)
if %%# equ 10 if %EditionPro% equ 1 if %ServerRdsh% equ 0 (set ServerRdsh=1&set verify=1)
if %%# equ 11 if %EditionPro% equ 1 if %IoTEnterprise% equ 0 if %_build% geq 18277 (set IoTEnterprise=1&set verify=1)
if %%# equ 12 if %EditionLTSC% equ 1 if %IoTEnterpriseS% equ 0 if %_build% geq 18298 (set IoTEnterpriseS=1&set verify=1)
)
if %verify% equ 1 goto :CREATEMENU
set _index=
goto :RANDOMMENU

:CREATEMENU
if %AutoStart% equ 1 (echo.) else (cls)
if %_configured% equ 1 (
echo %line%
echo Configured Virtual Options . . .
echo %line%
echo.
  for %%# in (
  AutoStart
  DeleteSource
  Preserve
  SkipISO
  wim2esd
  ) do (
  if !%%#! equ 1 echo %%#
  )
if %AutoStart% equ 1 if defined AutoEditions echo AutoEditions: %AutoEditions%
echo.
)

if %Preserve% equ 1 (
echo %line%
echo Copying Distribution source . . .
echo %line%
echo.
echo "%ISOdir%"
echo.
robocopy "%ISOdir%" "ISOFOLDER" /E /A-:R %_Const%
) else (
move "%ISOdir%" ISOFOLDER %_Const%
)
for %%# in (%vEditions%) do (
find /i "<EDITIONID>%%#</EDITIONID>" bin\infoall.txt %_Nul1% && set %%#=0
)
for %%# in (%vEditions%) do (
if !%%#! equ 1 set /a _all+=1
)
if %_all% equ 0 goto :E_None
set modified=0
set /a index=0
if %DeleteSource% neq 1 (
echo %line%
echo Copying %WimFile% . . .
echo %line%
echo.
copy /y ISOFOLDER\sources\%WimFile% ISOFOLDER\sources\temp.wim %_Nul1%
set /a index=%images%
)
for %%# in (%vEditions%) do (
if !%%#! equ 1 call :%%# %%#
)
if %modified% equ 1 (goto :ISOCREATE) else (goto :E_None)

:WIM
echo %line%
echo Creating Edition: %desc%
echo %line%
echo.
if %DeleteSource% equ 1 (
  if %_all% equ 1 (
    if %images% equ 1 (
    ren ISOFOLDER\sources\%WimFile% temp.wim
    wimlib-imagex.exe info ISOFOLDER\sources\temp.wim 1 "Windows 10 %desc%" "Windows 10 %desc%" %_Const%
    )
    if %images% neq 1 (
    wimlib-imagex.exe export ISOFOLDER\sources\%WimFile% %source% ISOFOLDER\sources\temp.wim "Windows 10 %desc%" "Windows 10 %desc%" %_Supp%
    )
  )
  if %_all% neq 1 (
  wimlib-imagex.exe export ISOFOLDER\sources\%WimFile% %source% ISOFOLDER\sources\temp.wim "Windows 10 %desc%" "Windows 10 %desc%" %_Supp%
  )
)
if %DeleteSource% neq 1 (
wimlib-imagex.exe export ISOFOLDER\sources\%WimFile% %source% ISOFOLDER\sources\temp.wim "Windows 10 %desc%" "Windows 10 %desc%" %_Supp%
)
set /a index+=1
wimlib-imagex.exe extract ISOFOLDER\sources\temp.wim %index% \Windows\System32\config\SOFTWARE \Windows\System32\config\SYSTEM \Windows\servicing\Editions\%EditionID%Edition.xml --dest-dir=.\bin\temp --no-acls --no-attributes %_Const%
%_Nul3% reg load HKLM\SOF .\bin\temp\SOFTWARE
%_Nul3% reg load HKLM\SYS .\bin\temp\SYSTEM
for %%# in (EditionID,ProductId) do (
%_Nul3% reg add "HKLM\SOF\Microsoft\Windows NT\CurrentVersion" /f /v %%# /t REG_SZ /d !%%#!
%_Nul3% reg add "HKLM\SOF\Microsoft\Windows NT\CurrentVersion\DefaultProductKey2" /f /v %%# /t REG_SZ /d !%%#!
)
for %%# in (DigitalProductId,DigitalProductId4) do (
%_Nul3% reg add "HKLM\SOF\Microsoft\Windows NT\CurrentVersion" /f /v %%# /t REG_BINARY /d !%%#!
%_Nul3% reg add "HKLM\SOF\Microsoft\Windows NT\CurrentVersion\DefaultProductKey2" /f /v %%# /t REG_BINARY /d !%%#!
)
for %%# in (OSProductContentId,OSProductPfn) do (
%_Nul3% reg add "HKLM\SOF\Microsoft\Windows NT\CurrentVersion\DefaultProductKey2" /f /v %%# /t REG_SZ /d !%%#!
%_Nul3% reg add "HKLM\SYS\ControlSet001\Control\ProductOptions" /f /v %%# /t REG_SZ /d !%%#!
)
%_Nul3% reg add "HKLM\SYS\ControlSet001\Services\LanmanWorkstation\Parameters" /f /v AllowInsecureGuestAuth /t REG_DWORD /d !Insecure!
%_Nul3% reg add "HKLM\SOF\Microsoft\Windows NT\CurrentVersion\Print" /f /v DoNotInstallCompatibleDriverFromWindowsUpdate /t REG_DWORD /d !Print!
%_Nul3% reg add "HKLM\SOF\Microsoft\Windows\CurrentVersion\Setup\OOBE" /f /v SetupDisplayedProductKey /t REG_DWORD /d 1
if /i %EditionID%==ServerRdsh (
%_Nul3% reg add "HKLM\SYS\Setup\FirstBoot\PreOobe" /f /v 00 /t REG_SZ /d "cmd.exe /c WMIC /NAMESPACE:\\ROOT\CIMV2 PATH Win32_UserAccount WHERE \"SID like 'S-1-5-21-%%-500'\" SET Disabled=FALSE &exit /b 0 "
)
%_Nul3% reg unload HKLM\SOF
%_Nul3% reg unload HKLM\SYS
type nul>bin\temp\virtual.txt
>>bin\temp\virtual.txt echo add 'bin^\temp^\SOFTWARE' '^\Windows^\System32^\config^\SOFTWARE'
>>bin\temp\virtual.txt echo add 'bin^\temp^\SYSTEM' '^\Windows^\System32^\config^\SYSTEM'
>>bin\temp\virtual.txt echo add 'bin^\temp^\%EditionID%Edition.xml' '^\Windows^\%EditionID%.xml'
wimlib-imagex.exe update ISOFOLDER\sources\temp.wim %index% < bin\temp\virtual.txt %_Const%
rmdir /s /q bin\temp\
echo.
wimlib-imagex.exe info ISOFOLDER\sources\temp.wim %index% --image-property WINDOWS/EDITIONID=%EditionID% --image-property FLAGS=%EditionID% --image-property DISPLAYNAME="Windows 10 %desc%" --image-property DISPLAYDESCRIPTION="Windows 10 %desc%"
echo.
set modified=1
exit /b

:ISOCREATE
if exist ISOFOLDER\sources\ei.cfg del /f /q ISOFOLDER\sources\ei.cfg
if exist ISOFOLDER\sources\%WimFile% del /f /q ISOFOLDER\sources\%WimFile%
ren ISOFOLDER\sources\temp.wim %WimFile%
echo %line%
echo Rebuilding %WimFile% . . .
echo %line%
echo.
wimlib-imagex.exe optimize ISOFOLDER\sources\%WimFile% %_Supp%
if %DeleteSource% equ 1 (
call :dPREPARE
)
if %wim2esd% equ 1 (
echo.
echo %line%
echo Converting install.wim to install.esd . . .
echo %line%
echo.
wimlib-imagex.exe export ISOFOLDER\sources\install.wim all ISOFOLDER\sources\install.esd --compress=LZMS --solid %_Supp%
call set ERRORTEMP=!ERRORLEVEL!
if !ERRORTEMP! neq 0 goto :E_Export
if exist ISOFOLDER\sources\install.esd del /f /q ISOFOLDER\sources\install.wim
)
if %SkipISO% equ 1 (
  ren ISOFOLDER %DVDISO%
  echo.
  echo %line%
  echo Done. You chose not to create iso file.
  echo %line%
  echo.
  goto :QUIT
)
echo.
echo %line%
echo Creating ISO . . .
echo %line%
if defined eTime set isotime=%eTime%
if /i not %arch%==arm64 (
cdimage.exe -bootdata:2#p0,e,b"ISOFOLDER\boot\etfsboot.com"#pEF,e,b"ISOFOLDER\efi\Microsoft\boot\efisys.bin" -o -m -u2 -udfver102 -t%isotime% -l%DVDLABEL% ISOFOLDER %DVDISO%.ISO
) else (
cdimage.exe -bootdata:1#pEF,e,b"ISOFOLDER\efi\Microsoft\boot\efisys.bin" -o -m -u2 -udfver102 -t%isotime% -l%DVDLABEL% ISOFOLDER %DVDISO%.ISO
)
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 goto :E_ISO
echo.
goto :QUIT

:dInfo
if exist "%ISOdir%\sources\install.wim" (set WimFile=install.wim) else (set WimFile=install.esd&set wim2esd=0)
imagex /info "%ISOdir%\sources\%WimFile%" | findstr /i /c:"LZMS" %_Nul1% && (set wim2esd=0)
imagex /info "%ISOdir%\sources\%WimFile%">bin\infoall.txt 2>&1
find /i "Core</EDITIONID>" bin\infoall.txt %_Nul1% && (set EditionHome=1) || (set EditionHome=0)
find /i "Professional</EDITIONID>" bin\infoall.txt %_Nul1% && (set EditionPro=1) || (set EditionPro=0)
find /i "ProfessionalN</EDITIONID>" bin\infoall.txt %_Nul1% && (set EditionProN=1) || (set EditionProN=0)
wimlib-imagex.exe info "%ISOdir%\sources\%WimFile%" 1 >bin\info.txt 2>&1
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 (
echo %_err%
echo Could not execute wimlib-imagex.exe
echo Use simple work path without special characters
echo.
del /f /q bin\info.txt %_Nul3%
goto :QUIT
)
for /f "tokens=2 delims=: " %%# in ('findstr /i /b "Build" bin\info.txt') do set _build=%%#
for /f "tokens=3 delims=: " %%# in ('findstr /i "Default" bin\info.txt') do set langid=%%#
for /f "tokens=2 delims=: " %%# in ('findstr /i "Architecture" bin\info.txt') do (if /i %%# equ x86 (set arch=x86) else if /i %%# equ x86_64 (set arch=x64) else (set arch=arm64))
for /f "tokens=3 delims=: " %%# in ('findstr /i /b /c:"Image Count" bin\infoall.txt') do set images=%%#
del /f /q bin\info.txt %_Nul3%
if %_build% lss 17063 (
set "MESSAGE=ISO build %_build% do not support virtual editions"
if %_iso% equ 1 rmdir /s /q "%ISOdir%\"
goto :E_MSG
)
set EditionLTSC=0
if %_build% geq 18298 find /i "EnterpriseS</EDITIONID>" bin\infoall.txt %_Nul1% && (set EditionLTSC=1)
if %EditionHome% equ 0 if %EditionPro% equ 0 if %EditionProN% equ 0 if %EditionLTSC% equ 0 (
set "MESSAGE=No supported source edition detected"
if %_iso% equ 1 rmdir /s /q "%ISOdir%\"
goto :E_MSG
)
for /l %%# in (1,1,%images%) do (
if %EditionHome% equ 1 (imagex /info "%ISOdir%\sources\%WimFile%" %%# | find /i "Core</EDITIONID>" %_Nul1% && set IndexHome=%%#)
if %EditionPro% equ 1 (imagex /info "%ISOdir%\sources\%WimFile%" %%# | find /i "Professional</EDITIONID>" %_Nul1% && set IndexPro=%%#)
if %EditionProN% equ 1 (imagex /info "%ISOdir%\sources\%WimFile%" %%# | find /i "ProfessionalN</EDITIONID>" %_Nul1% && set IndexProN=%%#)
if %EditionLTSC% equ 1 (imagex /info "%ISOdir%\sources\%WimFile%" %%# | find /i "EnterpriseS</EDITIONID>" %_Nul1% && set IndexLTSC=%%#)
)
if %EditionPro% equ 1 if %_build% geq 18277 set /a _sum+=1
if %EditionPro% equ 1 set /a _sum+=5
if %EditionProN% equ 1 set /a _sum+=4
if %EditionHome% equ 1 set /a _sum+=1
if %EditionLTSC% equ 1 set /a _sum+=1
wimlib-imagex.exe extract "%ISOdir%\sources\boot.wim" 2 sources\setuphost.exe --dest-dir=.\bin\temp --no-acls --no-attributes %_Nul3%
7z.exe l .\bin\temp\setuphost.exe >.\bin\temp\version.txt 2>&1
for /f "tokens=4-7 delims=.() " %%i in ('"findstr /i /b "FileVersion" .\bin\temp\version.txt" %_Nul6%') do (set version=%%i.%%j&set vermajor=%%i&set verminor=%%j&set branch=%%k&set labeldate=%%l)
set revision=%version%&set revmajor=%vermajor%&set revminor=%verminor%
set "tok=6,7"&set "toe=5,6,7"
set "isotime=!labeldate:~2,2!/!labeldate:~4,2!/20!labeldate:~0,2!,!labeldate:~7,2!:!labeldate:~9,2!:10"
if /i %arch%==x86 (set _ss=x86) else if /i %arch%==x64 (set _ss=amd64) else (set _ss=arm64)
wimlib-imagex.exe extract "%ISOdir%\sources\%WimFile%" 1 Windows\WinSxS\Manifests\%_ss%_microsoft-windows-coreos-revision*.manifest --dest-dir=.\bin\temp --no-acls --no-attributes %_Nul3%
if exist "bin\temp\*_microsoft-windows-coreos-revision*.manifest" for /f "tokens=%tok% delims=_." %%A in ('dir /b /a:-d /od .\bin\temp\*_microsoft-windows-coreos-revision*.manifest') do set revision=%%A.%%B&set revmajor=%%A&set revminor=%%B
if %_build% geq 15063 (
wimlib-imagex.exe extract "%ISOdir%\sources\%WimFile%" 1 Windows\System32\config\SOFTWARE --dest-dir=.\bin\temp --no-acls --no-attributes %_Const%
set "isokey=Microsoft\Windows NT\CurrentVersion\Update\TargetingInfo\Installed"
for /f %%i in ('"offlinereg.exe .\bin\temp\SOFTWARE "!isokey!" enumkeys %_Nul6% ^| find /i "Client.OS""') do if not errorlevel 1 (
  for /f "tokens=3 delims==:" %%A in ('"offlinereg.exe .\bin\temp\SOFTWARE "!isokey!\%%i" getvalue Branch %_Nul6%"') do set "isobranch=%%~A"
  for /f "tokens=5,6 delims==:." %%A in ('"offlinereg.exe .\bin\temp\SOFTWARE "!isokey!\%%i" getvalue Version %_Nul6%"') do if %%A gtr !revmajor! (
    set "revision=%%~A.%%B
    set revmajor=%%~A
    set "revminor=%%B
    )
  )
)
if defined isobranch set branch=%isobranch%
if %revmajor%==18363 (
if /i "%branch:~0,4%"=="19h1" set branch=19h2%branch:~4%
if %version:~0,5%==18362 set version=18363%version:~5%
)
if %revmajor%==19042 (
if %version:~0,5%==19041 set version=19042%version:~5%
)
if %verminor% lss %revminor% (
set version=%revision%
set verminor=%revminor%
wimlib-imagex.exe extract "%ISOdir%\sources\%WimFile%" 1 Windows\servicing\Packages\Package_for_RollupFix*.mum --dest-dir=%SystemRoot%\temp --no-acls --no-attributes %_Nul3%
for /f %%# in ('dir /b /a:-d /od %SystemRoot%\temp\Package_for_RollupFix*.mum') do set "mumfile=%SystemRoot%\temp\%%#"
for /f "tokens=2 delims==" %%# in ('wmic datafile where "name='!mumfile:\=\\!'" get LastModified /value') do set "mumdate=%%#"
del /f /q %SystemRoot%\temp\*.mum
set "labeldate=!mumdate:~2,2!!mumdate:~4,2!!mumdate:~6,2!-!mumdate:~8,4!"
set "isotime=!mumdate:~4,2!/!mumdate:~6,2!/!mumdate:~0,4!,!mumdate:~8,2!:!mumdate:~10,2!:!mumdate:~12,2!"
)
if %verminor% gtr %revminor% (
wimlib-imagex.exe extract "%ISOdir%\sources\%WimFile%" 1 Windows\servicing\Packages\Package_for_RollupFix*.mum --dest-dir=%SystemRoot%\temp --no-acls --no-attributes %_Nul3%
if not exist "%SystemRoot%\temp\Package_for_RollupFix*.mum" set branch=WinBuild
)
set _label2=
if /i "%branch%"=="WinBuild" (
wimlib-imagex.exe extract "%ISOdir%\sources\%WimFile%" 1 \Windows\System32\config\SOFTWARE --dest-dir=.\bin\temp --no-acls --no-attributes %_Const%
for /f "tokens=3 delims==:" %%# in ('"offlinereg.exe .\bin\temp\SOFTWARE "Microsoft\Windows NT\CurrentVersion" getvalue BuildLabEx" %_Nul6%') do if not errorlevel 1 (for /f "tokens=1-5 delims=." %%i in ('echo %%~#') do set _label2=%%i.%%j.%%m.%%l_CLIENT&set branch=%%l)
)
if defined _label2 (set _label=%_label2%) else (set _label=%version%.%labeldate%.%branch%_CLIENT)
rmdir /s /q bin\temp\
if /i %arch%==x86 set archl=X86
if /i %arch%==x64 set archl=X64
if /i %arch%==arm64 set archl=A64
for %%# in (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do (
set _label=!_label:%%#=%%#!
set branch=!branch:%%#=%%#!
set langid=!langid:%%#=%%#!
)
set "DVDLABEL=CCSA_%archl%FRE_%langid%_DV5"
if defined eLabel set _label=%eLabel%
set "DVDISO=%_label%MULTI_%archl%FRE_%langid%"
if exist "%DVDISO%.ISO" set "DVDISO=%DVDISO%_r"
goto :AUTOMENU

:dPREPARE
for /f "tokens=3 delims=: " %%# in ('imagex /info ISOFOLDER\sources\%WimFile% ^|findstr /i /b /c:"Image Count"') do set finalimages=%%#
if %finalimages% gtr 1 exit /b
set _VL=0
for /f "tokens=3 delims=<>" %%# in ('imagex /info ISOFOLDER\sources\%WimFile% 1 ^| find /i "<EDITIONID>"') do set editionid=%%#
if /i %editionid%==Professional set DVDLABEL=CPRA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%PRO_OEMRET_%archl%FRE_%langid%
if /i %editionid%==ProfessionalN set DVDLABEL=CPRNA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%PRON_OEMRET_%archl%FRE_%langid%
if /i %editionid%==Core set DVDLABEL=CCRA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%CORE_OEMRET_%archl%FRE_%langid%
if /i %editionid%==CoreSingleLanguage set DVDLABEL=CSLA_%archl%FREO_%langid%_DV5&set DVDISO=%_label%SINGLELANGUAGE_OEM_%archl%FRE_%langid%
if /i %editionid%==Enterprise set DVDLABEL=CENA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%ENTERPRISE_VOL_%archl%FRE_%langid%&set _VL=1
if /i %editionid%==EnterpriseN set DVDLABEL=CENNA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%ENTERPRISEN_VOL_%archl%FRE_%langid%&set _VL=1
if /i %editionid%==Education set DVDLABEL=CEDA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%EDUCATION_RET_%archl%FRE_%langid%&set _VL=1
if /i %editionid%==EducationN set DVDLABEL=CEDNA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%EDUCATIONN_RET_%archl%FRE_%langid%&set _VL=1
if /i %editionid%==ProfessionalWorkstation set DVDLABEL=CPRWA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%PROWORKSTATION_OEMRET_%archl%FRE_%langid%
if /i %editionid%==ProfessionalWorkstationN set DVDLABEL=CPRWNA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%PROWORKSTATIONN_OEMRET_%archl%FRE_%langid%
if /i %editionid%==ProfessionalEducation set DVDLABEL=CPREA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%PROEDUCATION_OEMRET_%archl%FRE_%langid%
if /i %editionid%==ProfessionalEducationN set DVDLABEL=CPRENA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%PROEDUCATIONN_OEMRET_%archl%FRE_%langid%
if /i %editionid%==ServerRdsh set DVDLABEL=CEV_%archl%FREV_%langid%_DV5&set DVDISO=%_label%MULTISESSION_VOL_%archl%FRE_%langid%&set _VL=1
if /i %editionid%==IoTEnterprise set DVDLABEL=IOTE_%archl%FRE_%langid%_DV5&set DVDISO=%_label%IOTENTERPRISE_OEMRET_%archl%FRE_%langid%
if /i %editionid%==IoTEnterpriseS set DVDLABEL=IOTS_%archl%FRE_%langid%_DV5&set DVDISO=%_label%IOTENTERPRISES_OEMRET_%archl%FRE_%langid%
if %_VL% equ 0 exit /b
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

:IoTEnterpriseS
rem placebo for now
exit /b
if %_build% lss 18298 exit /b
set "EditionID=%1"
set "desc=IoT Enterprise LTSC"
set "source=%IndexLTSC%"
call :WIM
exit /b

:IoTEnterprise
if %_build% lss 18277 exit /b
set "EditionID=%1"
set "ProductId=00436-20000-00000-AAOEM"
set "OSProductContentId=4b1412af-12ad-0bbd-177e-6f7579c8600f"
set "OSProductPfn=Microsoft.Windows.188.X21-99378_8wekyb3d8bbwe"
set "DigitalProductId=A40000000300000030303433362D32303030302D30303030302D41414F454D000A1100005B313948315D5832312D3939333738000A1100000000C8BFC44ABE281573090000000000BA3FC65C79FBCEC902000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004E6597C1"
set "DigitalProductId4=F804000004000000350035003000340031002D00300034003300360032002D003000300030002D003000300030003000300030002D00300032002D0031003000320035002D0039003200300030002E0030003000300030002D0031003100390032003000310039000000000000000000000000000000000000000000000000000000000000000000380061006200390062006400640031002D0031006600360037002D0034003900390037002D0038003200640039002D0038003800370038003500320030003800330037006400390000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000049006F00540045006E0074006500720070007200690073006500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000A1100000000C8BFC44ABE2815730900C2586D4B3D14127A7AA589B597436B2B668BB57F03BBF64B34DADF82166ED03DAE567D1A43D2A5F01CBEFFA92C8D86415273F040C17EFE9C1A53F6D49DB0A54B5B0031003900480031005D005800320031002D003900390033003700380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004F0045004D003A0044004D0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004F0045004D000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
set "Print=1"
set "Insecure=0"
set "desc=IoT Enterprise"
set "source=%IndexPro%"
call :WIM
exit /b

:ServerRdsh
set "EditionID=%1"
set "ProductId=00432-70000-00001-AA701"
set "OSProductContentId=8e20e60b-0826-3084-51fe-cda9e1b184cd"
set "OSProductPfn=Microsoft.Windows.175.X21-83765_8wekyb3d8bbwe"
set "DigitalProductId=A40000000300000030303433322D37303030302D30303030312D414137303100E71000005B5253355D5832312D38333736350000E710100000000019E6ABC946E0F0090000000000A23EC65C05F0E66F0300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000651DE578"
set "DigitalProductId4=F804000004000000350035003000340031002D00300034003300320037002D003000300030002D003000300030003000300031002D00300033002D0031003000320035002D0039003200300030002E0030003000300030002D0031003100390032003000310039000000000000000000000000000000000000000000000000000000000000000000650063003800360038006500360035002D0066006100640066002D0034003700350039002D0062003200330065002D00390033006600650033003700660032006300630032003900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000530065007200760065007200520064007300680000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000E710100000000019E6ABC946E0F009002B11469E49D838FE3D68708FF122CB51C5BB3CB181B914B08DE8BFDDE9D3B495B852E47C048CEF48B76AA54F7352659895F9AA7B24F08092E3CA900D5B3DE7A15B005200530035005D005800320031002D00380033003700360035000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056006F006C0075006D0065003A00470056004C004B000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056006F006C0075006D0065000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
set "Print=1"
set "Insecure=0"
set "desc=Enterprise for Virtual Desktops"
set "source=%IndexPro%"
call :WIM
exit /b

:Enterprise
set "EditionID=%1"
set "ProductId=00329-00000-00003-AA163"
set "OSProductContentId=05ce649a-eed1-d14e-aa01-4045f35ca54d"
set "OSProductPfn=Microsoft.Windows.4.X19-98698_8wekyb3d8bbwe"
set "DigitalProductId=A40000000300000030303332392D30303030302D30303030332D414131363300DA0C00005B54485D5831392D3938363938000000DA0C30000000186367E01565BE190800000000006A3CC65C7B0355CF03000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001820E0CF"
set "DigitalProductId4=F804000004000000350035003000340031002D00300033003200390030002D003000300030002D003000300030003000300033002D00300033002D0031003000320035002D0039003200300030002E0030003000300030002D0031003100380032003000310039000000000000000000000000000000000000000000000000000000000000000000370033003100310031003100320031002D0035003600330038002D0034003000660036002D0062006300310031002D0066003100640037006200300064003600340033003000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000045006E007400650072007000720069007300650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000DA0C30000000186367E01565BE1908002F804AB2DB805EA13D7F55FE45580AACE318F8564D3FADB7415C2F5B04D68038B0CB8213C664AB77BE2BCA373C415436BC9DCF06233D14E08772FC1D4C4137145B00540048005D005800310039002D003900380036003900380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056006F006C0075006D0065003A00470056004C004B000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056006F006C0075006D0065000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
set "Print=1"
set "Insecure=0"
set "desc=Enterprise"
set "source=%IndexPro%"
call :WIM
exit /b

:Education
set "EditionID=%1"
set "ProductId=00328-10000-00001-AA343"
set "OSProductContentId=ce14a187-835c-7270-6fcb-602268e16063"
set "OSProductPfn=Microsoft.Windows.121.X19-98668_8wekyb3d8bbwe"
set "DigitalProductId=A40000000300000030303332382D31303030302D30303030312D414133343300D10C00005B54485D5831392D3938363638000000D10C10000000603EF693CD84A6280800000000003B3EC65CEFDEBD170300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000FBB56065"
set "DigitalProductId4=F804000004000000350035003000340031002D00300033003200380031002D003000300030002D003000300030003000300031002D00300033002D0031003000320035002D0039003200300030002E0030003000300030002D0031003100380032003000310039000000000000000000000000000000000000000000000000000000000000000000650030006300340032003200380038002D0039003800300063002D0034003700380038002D0061003000310034002D0063003000380030006400320065003100390032003600650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000045006400750063006100740069006F006E00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000D10C10000000603EF693CD84A628080097DF6CB8F7B0FE32CAD1D565E037D8EF8A2DD512CE70153460A140266ECEED293F9366CBE687D3DB1F6A8C152BBF06D2CF3526E15637F4CAD048E4FECFC139EC5B00540048005D005800310039002D003900380036003600380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056006F006C0075006D0065003A00470056004C004B000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056006F006C0075006D0065000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
set "Print=1"
set "Insecure=0"
set "desc=Education"
set "source=%IndexPro%"
call :WIM
exit /b

:ProfessionalEducation
set "EditionID=%1"
set "ProductId=00380-00000-00001-AA261"
set "OSProductContentId=3c88328a-7c1e-aa8a-72e7-edca5665b405"
set "OSProductPfn=Microsoft.Windows.164.X21-04955_8wekyb3d8bbwe"
set "DigitalProductId=A40000000300000030303338302D30303030302D30303030312D414132363100D80E00005B5253315D5832312D30343935350000D80E10000000B0D59918A63DEAC7090000000000F83EC65C8D0D82E800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003A8EA582"
set "DigitalProductId4=F804000004000000350035003000340031002D00300033003800300030002D003000300030002D003000300030003000300031002D00300030002D0031003000320035002D0039003200300030002E0030003000300030002D0031003100390032003000310039000000000000000000000000000000000000000000000000000000000000000000360032006600300063003100300030002D0039006300350033002D0034006500300032002D0062003800380036002D00610033003500320038006400640066006500370066003600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000500072006F00660065007300730069006F006E0061006C0045006400750063006100740069006F006E00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000D80E10000000B0D59918A63DEAC7090049CE26E216D5DA7CB7BCE6C212337CFD8DFFB4DF3542F3082038118C22F8F62AEB533B180E8C2EB103A53ADA9E058D80FE788F03A557C608FA26AF208C838F0B5B005200530031005D005800320031002D003000340039003500350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000520065007400610069006C000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000520065007400610069006C000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
set "Print=0"
set "Insecure=1"
set "desc=Pro Education"
set "source=%IndexPro%"
call :WIM
exit /b

:ProfessionalWorkstation
set "EditionID=%1"
set "ProductId=00391-70000-00000-AA825"
set "OSProductContentId=665f6f21-1692-5d08-17e4-934e0c638268"
set "OSProductPfn=Microsoft.Windows.161.X21-43626_8wekyb3d8bbwe"
set "DigitalProductId=A40000000300000030303339312D37303030302D30303030302D4141383235004D0F00005B5253335D5832312D343336323600004D0F00000000344DD4F276BB0150090000000000583FC65CE95A1CEA00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007DD61CA5"
set "DigitalProductId4=F804000004000000350035003000340031002D00300033003900310037002D003000300030002D003000300030003000300030002D00300030002D0031003000320035002D0039003200300030002E0030003000300030002D0031003100390032003000310039000000000000000000000000000000000000000000000000000000000000000000650062003600640033003400360066002D0031006300360030002D0034003600340033002D0062003900360030002D00340030006500630033003100350039003600630034003500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000500072006F00660065007300730069006F006E0061006C0057006F0072006B00730074006100740069006F006E0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004D0F00000000344DD4F276BB01500900DCA02A65542EDA7278AEE106EB6DBB25C6E2B84961296DB9FCF4F525C29FD0B4434023AD5574B64901101BC377CDE0346F5E7F97ED597050592F15D40B2F63C85B005200530033005D005800320031002D003400330036003200360000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000520065007400610069006C000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000520065007400610069006C000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
set "Print=0"
set "Insecure=1"
set "desc=Pro for Workstations"
set "source=%IndexPro%"
call :WIM
exit /b

:EnterpriseN
set "EditionID=%1"
set "ProductId=00329-90000-00000-AA065"
set "OSProductContentId=95bd2561-e54d-b969-789e-f7d12b386c67"
set "OSProductPfn=Microsoft.Windows.27.X19-98747_8wekyb3d8bbwe"
set "DigitalProductId=A40000000300000030303332392D39303030302D30303030302D414130363500E30C00005B54485D5831392D3938373437000000E30C0000000074483162F763DE2D090000000000B168C75CB909475F0300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000BBAF583E"
set "DigitalProductId4=F804000004000000350035003000340031002D00300033003200390039002D003000300030002D003000300030003000300030002D00300033002D0031003000320035002D0039003200300030002E0030003000300030002D0031003100390032003000310039000000000000000000000000000000000000000000000000000000000000000000650032003700320065003300650032002D0037003300320066002D0034006300360035002D0061003800660030002D0034003800340037003400370064003000640039003400370000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000045006E00740065007200700072006900730065004E000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000E30C0000000074483162F763DE2D0900013ACB6CFB7A43817B1886F4231F31CB9D9984E412F00E88D4AFC9BC29D6805A013BC42A03714918ED6F587A2424253F18375D7E42711D3553A7EF7BDAACB9B05B00540048005D005800310039002D003900380037003400370000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056006F006C0075006D0065003A00470056004C004B000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056006F006C0075006D0065000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
set "Print=1"
set "Insecure=0"
set "desc=Enterprise N"
set "source=%IndexProN%"
call :WIM
exit /b

:EducationN
set "EditionID=%1"
set "ProductId=00328-60000-00001-AA362"
set "OSProductContentId=70f4ccac-9a50-0c5b-9b8c-4fe0d6276cf1"
set "OSProductPfn=Microsoft.Windows.122.X19-98682_8wekyb3d8bbwe"
set "DigitalProductId=A40000000300000030303332382D36303030302D30303030312D414133363200D60C00005B54485D5831392D3938363832000000D60C10000000FC97E3F1CCDF3C370900000000004C69C75C1AA7E14A03000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002B44EB37"
set "DigitalProductId4=F804000004000000350035003000340031002D00300033003200380036002D003000300030002D003000300030003000300031002D00300033002D0031003000320035002D0039003200300030002E0030003000300030002D0031003100390032003000310039000000000000000000000000000000000000000000000000000000000000000000330063003100300032003300350035002D0064003000320037002D0034003200630036002D0061006400320033002D0032006500370065006600380061003000320035003800350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000045006400750063006100740069006F006E004E0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000D60C10000000FC97E3F1CCDF3C370900CDF1B541541FBEFA02F6D41F9D7F8F41203AAADAE64A2981E617D6F4E3439F1592B7C251D0024D513741D883801A4F2010CE63E9B65244FB1D641A4D8963A50E5B00540048005D005800310039002D003900380036003800320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056006F006C0075006D0065003A00470056004C004B000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056006F006C0075006D0065000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
set "Print=1"
set "Insecure=0"
set "desc=Education N"
set "source=%IndexProN%"
call :WIM
exit /b

:ProfessionalEducationN
set "EditionID=%1"
set "ProductId=00380-10000-00001-AA148"
set "OSProductContentId=3dc4d427-0e39-c53a-6b2c-a801a01f902b"
set "OSProductPfn=Microsoft.Windows.165.X21-04956_8wekyb3d8bbwe"
set "DigitalProductId=A40000000300000030303338302D31303030302D30303030312D414131343800D90E00005B5253315D5832312D30343935360000D90E1000000040E86D4ECFECBC12090000000000826BC75C947D897B0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000359333A5"
set "DigitalProductId4=F804000004000000350035003000340031002D00300033003800300031002D003000300030002D003000300030003000300031002D00300030002D0031003000320035002D0039003200300030002E0030003000300030002D0031003100390032003000310039000000000000000000000000000000000000000000000000000000000000000000310033006100330038003600390038002D0034006100340039002D0034006200390065002D0038006500380033002D00390038006600650035003100310031003000390035003300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000500072006F00660065007300730069006F006E0061006C0045006400750063006100740069006F006E004E0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000D90E1000000040E86D4ECFECBC12090004D5AD09CB250227EA46806F10551398C0BE8348C85D5056A4D7FDDC3D059E056747155A62192E948AA6815878A1A99C2C20655DFBB248ACDBD8A73DCC9979BB5B005200530031005D005800320031002D003000340039003500360000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000520065007400610069006C000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000520065007400610069006C000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
set "Print=0"
set "Insecure=1"
set "desc=Pro Education N"
set "source=%IndexProN%"
call :WIM
exit /b

:ProfessionalWorkstationN
set "EditionID=%1"
set "ProductId=00392-20000-00000-AA717"
set "OSProductContentId=0ec42cc5-2b09-a734-1bb9-ff00e4a52d46"
set "OSProductPfn=Microsoft.Windows.162.X21-43644_8wekyb3d8bbwe"
set "DigitalProductId=A40000000300000030303339322D32303030302D30303030302D414137313700520F00005B5253335D5832312D34333634340000520F00000000D8B84CE6055D81ED080000000000CA6BC75C6DA8F63B0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000619D9E2C"
set "DigitalProductId4=F804000004000000350035003000340031002D00300033003900320032002D003000300030002D003000300030003000300030002D00300030002D0031003000320035002D0039003200300030002E0030003000300030002D0031003100390032003000310039000000000000000000000000000000000000000000000000000000000000000000380039006500380037003500310030002D0062006100390032002D0034003500660036002D0038003300320039002D00330061006600610039003000350065003300650038003300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000500072006F00660065007300730069006F006E0061006C0057006F0072006B00730074006100740069006F006E004E00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000520F00000000D8B84CE6055D81ED0800088943EDD3CF7A8B08D896A5563ED4A52421E0D01861CB786C78E3CA17454B8912A965EB02684AC4AD00913D7997FA5432771B7FCD710600DE39FE61521B10F45B005200530033005D005800320031002D003400330036003400340000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000520065007400610069006C000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000520065007400610069006C000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
set "Print=0"
set "Insecure=1"
set "desc=Pro N for Workstations"
set "source=%IndexProN%"
call :WIM
exit /b

:CoreSingleLanguage
set "EditionID=%1"
set "ProductId=00327-60000-00000-AA157"
set "OSProductContentId=6fba12a6-3077-5301-cfde-f22f59f1e2a6"
set "OSProductPfn=Microsoft.Windows.100.X19-99661_8wekyb3d8bbwe"
set "DigitalProductId=A40000000300000030303332372D36303030302D30303030302D414131353700CC0C00005B54485D5831392D3939363631000000CC0C00000000A0DB36D6DC41C8CD090000000000B270C75CC5F629D50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100770A8"
set "DigitalProductId4=F804000004000000350035003000340031002D00300033003200370036002D003000300030002D003000300030003000300030002D00300030002D0031003000320035002D0039003200300030002E0030003000300030002D0031003100390032003000310039000000000000000000000000000000000000000000000000000000000000000000330061006500320063006300310034002D0061006200320064002D0034003100660034002D0039003700320066002D0035006500320030003100340032003700370031006400630000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000043006F0072006500530069006E0067006C0065004C0061006E0067007500610067006500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000CC0C00000000A0DB36D6DC41C8CD09002A9E0AB03607F36AE6CA609D0A54E68E58186B61A1D6A3C0BFDD6FC40AF2168D262581306BED0061DC0DDD8912031EE633FC7BB84B09C413ACAA627B3AABC92C5B00540048005D005800310039002D0039003900360036003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000520065007400610069006C000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000520065007400610069006C000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
set "Print=0"
set "Insecure=1"
set "desc=Home Single Language"
set "source=%IndexHome%"
call :WIM
exit /b

:E_Admin
echo %_err%
echo This script require administrator privileges.
echo To do so, right click on this script and select 'Run as administrator'
echo.
%_Exit%&%_Pause%
exit /b

:E_Bin
echo %_err%
echo Required file %_bin% is missing.
echo.
goto :QUIT

:E_MSG
echo.
echo %_err%
echo %MESSAGE%
echo.
goto :QUIT

:E_None
if exist ISOFOLDER\sources\temp.wim del /f /q ISOFOLDER\sources\temp.wim
call :dPREPARE
ren ISOFOLDER %DVDISO%
echo.
echo %line%
echo No operation performed.
echo %line%
echo.
goto :QUIT

:E_Export
echo.&echo Errors were reported during export.&echo.&goto :QUIT

:E_ISO
ren ISOFOLDER %DVDISO%
echo.&echo Errors were reported during ISO creation.&echo.&goto :QUIT

:QUIT
if exist ISOFOLDER\ rmdir /s /q ISOFOLDER\
if exist bin\temp\ rmdir /s /q bin\temp\
if exist bin\infoall.txt del /f /q bin\infoall.txt
popd
if %_Debug% neq 0 (exit /b) else (echo Press 0 to exit.)
choice /c 0 /n
if errorlevel 1 (exit /b) else (rem.)

----- Begin wsf script --->
<package>
   <job id="ELAV">
       <script language="VBScript">
           Set strArg=WScript.Arguments.Named
           If Not strArg.Exists("File") Then
               Wscript.Echo "Switch /File:<File> is missing."
               WScript.Quit 1
           End If
           Set strRdlproc = CreateObject("WScript.Shell").Exec("rundll32 kernel32,Sleep")
           With GetObject("winmgmts:\\.\root\CIMV2:Win32_Process.Handle='" & strRdlproc.ProcessId & "'")
               With GetObject("winmgmts:\\.\root\CIMV2:Win32_Process.Handle='" & .ParentProcessId & "'")
                   If InStr (.CommandLine, WScript.ScriptName) <> 0 Then
                       strLine = Mid(.CommandLine, InStr(.CommandLine , "/File:") + Len(strArg("File")) + 8)
                   End If
               End With
               .Terminate
           End With
          CreateObject("Shell.Application").ShellExecute "cmd.exe", "/c " & chr(34) & chr(34) & strArg("File") & chr(34) & strLine & chr(34), "", "runas", 1
       </script>
   </job>
</package>