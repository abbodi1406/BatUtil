@echo off
:: Licenses used for converting Office 365 ProPlus:
:: set _O365asO2019=0 -> use Office 2016 Mondo (if you want Office 365 features)
:: set _O365asO2019=1 -> use Office 2019 ProPlus (should only be for Windows 7 and 8.1)
set _O365asO2019=0


set _Debug=0
%windir%\system32\reg.exe query "HKU\S-1-5-19" >nul 2>&1 || (
set "msg=ERROR: right click on the script and 'Run as administrator'"
goto :end
)

if %_Debug% EQU 0 (
  set "_Nul_1=1>nul"
  set "_Nul_2=2>nul"
  set "_Nul_2e=2^>nul"
  set "_Nul_1_2=1>nul 2>nul"
  call :Begin
  exit /b
) else (
  set "_Nul_1="
  set "_Nul_2="
  set "_Nul_2e="
  set "_Nul_1_2="
  echo.
  echo Running in Debug Mode...
  echo The window will be closed when finished
  @echo on
  @prompt $G
  @call :Begin >"%~dpn0.tmp" 2>&1 &cmd /u /c type "%~dpn0.tmp">"%~dpn0_Debug.log"&del "%~dpn0.tmp"
)
exit /b

:Begin
color 1F
title Office Click-to-Run Retail-to-Volume
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G
if /i "%PROCESSOR_ARCHITECTURE%" equ "AMD64" (set arch=x64) else (set arch=x86)
set "_SLMGR=%SystemRoot%\System32\slmgr.vbs"

if %winbuild% LSS 7601 (
set "msg=Windows 7 SP1 is the minimum supported OS..."
goto :end
)
sc query ClickToRunSvc %_Nul_1_2%
set error1=%errorlevel%
sc query OfficeSvc %_Nul_1_2%
set error2=%errorlevel%
if %error1% equ 1060 if %error2% equ 1060 (
set "msg=Could not detect Office ClickToRun service..."
goto :end
)

set _Office16=0
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\ClickToRun /v InstallPath" %_Nul_2e%') do if exist "%%b\Office16\OSPP.VBS" (
  set _Office16=1&set "_OSPP=%%b\Office16\OSPP.VBS"
)
if exist "%ProgramFiles%\Microsoft Office\Office16\OSPP.VBS" (
  set _Office16=1&set "_OSPP=%ProgramFiles%\Microsoft Office\Office16\OSPP.VBS"
) else if exist "%ProgramFiles(x86)%\Microsoft Office\Office16\OSPP.VBS" (
  set _Office16=1&set "_OSPP=%ProgramFiles(x86)%\Microsoft Office\Office16\OSPP.VBS"
)
if %_Office16% equ 0 (
set "msg=No installed Office 2016/2019 product detected..."
goto :end
)

for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\ClickToRun /v InstallPath" %_Nul_2e%') do if not errorlevel 1 (set "_InstallRoot=%%b\root")
if "%_InstallRoot%" neq "" (
  for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\ClickToRun /v PackageGUID" %_Nul_2e%') do if not errorlevel 1 (set "_GUID=%%b")
  for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Configuration /v ProductReleaseIds" %_Nul_2e%') do if not errorlevel 1 (set "ProductIds=%%b")
  set "_Config=HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
  set "_PRIDs=HKLM\SOFTWARE\Microsoft\Office\ClickToRun\ProductReleaseIDs"
) else (
  for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun /v InstallPath" %_Nul_2e%') do if not errorlevel 1 (set "_InstallRoot=%%b\root")
  for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun /v PackageGUID" %_Nul_2e%') do if not errorlevel 1 (set "_GUID=%%b")
  for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration /v ProductReleaseIds" %_Nul_2e%') do if not errorlevel 1 (set "ProductIds=%%b")
  set "_Config=HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration"
  set "_PRIDs=HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\ProductReleaseIDs"
)
set "_LicensesPath=%_InstallRoot%\Licenses16"
set "_Integrator=%_InstallRoot%\integration\integrator.exe"
for /f "skip=2 tokens=2*" %%a in ('"reg query %_PRIDs% /v ActiveConfiguration" %_Nul_2e%') do set "_PRIDs=%_PRIDs%\%%b"

if "%ProductIds%" equ "" (
set "msg=Could not detect Office ProductIDs..."
goto :end
)
if not exist "%_LicensesPath%\*.xrm-ms" (
set "msg=Could not detect Office Licenses files..."
goto :end
)
if not exist "%_Integrator%" (
set "msg=Could not detect Office Licenses Integrator..."
goto :end
)
if %winbuild% lss 9200 if not exist "%_OSPP%" (
set "msg=Could not detect Licensing tool OSPP.vbs..."
goto :end
)

:Check
echo.
echo ============================================================
echo Checking Office Licenses...
echo ============================================================
if %winbuild% geq 9200 (
set spp=SoftwareLicensingProduct
set sps=SoftwareLicensingService
) else (
set spp=OfficeSoftwareProtectionProduct
set sps=OfficeSoftwareProtectionService
)
for /f "tokens=2 delims==" %%a in ('"wmic path %sps% get version /value" %_Nul_2e%') do set ver=%%a
wmic path %spp% where (Description like '%%KMSCLIENT%%' AND not LicenseFamily='Office16MondoR_KMS_Automation') get LicenseFamily %_Nul_2% | findstr /i /C:"Office" %_Nul_1% && (set _KMS=1) || (set _KMS=0)
wmic path %spp% where (Description like '%%TIMEBASED%%') get LicenseFamily %_Nul_2% | findstr /i /C:"Office" %_Nul_1% && (set _Time=1) || (set _Time=0)
wmic path %spp% where (Description like '%%Grace%%') get LicenseFamily %_Nul_2% | findstr /i /C:"Office" %_Nul_1% && (set _Grace=1) || (set _Grace=0)
if %_Time% equ 0 if %_Grace% equ 0 if %_KMS% equ 1 (
set "msg=No Conversion or Cleanup Required..."
goto :end
)

:Retail2Volume
echo.
echo ============================================================
echo Cleaning Current Office Licenses...
echo ============================================================
cd /d "%~dp0"
%arch%\cleanospp.exe -Licenses %_Nul_1_2%
echo.
echo ============================================================
echo Installing Office Volume Licenses...
echo ============================================================
echo.
set O19Ids=ProPlus2019,ProjectPro2019,VisioPro2019,Standard2019,ProjectStd2019,VisioStd2019
set O16Ids=ProjectPro,VisioPro,Standard,ProjectStd,VisioStd
set A19Ids=Excel2019,Outlook2019,PowerPoint2019,Publisher2019,Word2019
set A16Ids=Excel,OneNote,Outlook,PowerPoint,Publisher,Word

echo %ProductIds%> "%temp%\ProductIds.txt"
for %%a in (Mondo,%O19Ids%,%A19Ids%,Access2019,SkypeforBusiness2019,Professional2019,HomeBusiness2019,HomeStudent2019,O365ProPlus,O365Business,O365SmallBusPrem,O365HomePrem,O365EduCloud,Professional,HomeBusiness,HomeStudent,%O16Ids%,%A16Ids%,Access,SkypeforBusiness,ProPlus) do (
set _%%a=0
)
for %%a in (Mondo,%O19Ids%,%A19Ids%,Access2019,SkypeforBusiness2019,Professional2019,HomeBusiness2019,HomeStudent2019,O365ProPlus,O365Business,O365SmallBusPrem,O365HomePrem,O365EduCloud,Professional,HomeBusiness,HomeStudent,%O16Ids%,%A16Ids%,Access,SkypeforBusiness) do (
findstr /I /C:"%%aRetail" "%temp%\ProductIds.txt" %_Nul_1% && set _%%a=1
)
wmic path %spp% get LicenseFamily > "%temp%\sppchk.txt" 2>&1
for %%a in (Mondo,%O19Ids%,%A19Ids%,Access2019,SkypeforBusiness2019,%O16Ids%,%A16Ids%,Access,SkypeforBusiness) do (
findstr /I /C:"%%aVolume" "%temp%\ProductIds.txt" %_Nul_1% && (
  find /i "%%aVL_KMS_Client" "%temp%\sppchk.txt" %_Nul_1% && (set _%%a=0) || (set _%%a=1)
  )
)
reg query %_PRIDs%\ProPlusRetail.16 %_Nul_1_2% && set _ProPlus=1
reg query %_PRIDs%\ProPlusVolume.16 %_Nul_1_2% && (
find /i "Office16ProPlusVL_KMS_Client" "%temp%\sppchk.txt" %_Nul_1% && (set _ProPlus=0) || (set _ProPlus=1)
)
del /f /q "%temp%\sppchk.txt" >nul 2>&1
del /f /q "%temp%\ProductIds.txt" >nul 2>&1

setlocal EnableDelayedExpansion
if !_Mondo! equ 1 (
echo Mondo Suite
echo.
call :InsLic Mondo
goto :GVLK
)
if !_O365ProPlus! equ 1 (
  if !_O365asO2019! equ 1 (
  echo O365ProPlus Suite -^> ProPlus2019 Licenses
  echo.
  call :InsLic ProPlus2019
  ) else (
  echo O365ProPlus Suite -^> Mondo Licenses
  echo.
  call :InsLic Mondo
  )
)
if !_O365Business! equ 1 if !_O365ProPlus! equ 0 (
set _O365ProPlus=1
echo O365Business Suite -^> Mondo Licenses
echo.
call :InsLic Mondo
)
if !_O365SmallBusPrem! equ 1 if !_O365Business! equ 0 if !_O365ProPlus! equ 0 (
set _O365ProPlus=1
echo O365SmallBusPrem Suite -^> Mondo Licenses
echo.
call :InsLic Mondo
)
if !_O365HomePrem! equ 1 if !_O365SmallBusPrem! equ 0 if !_O365Business! equ 0 if !_O365ProPlus! equ 0 (
set _O365ProPlus=1
echo O365HomePrem Suite -^> Mondo Licenses
echo.
call :InsLic Mondo
)
if !_O365EduCloud! equ 1 if !_O365HomePrem! equ 0 if !_O365SmallBusPrem! equ 0 if !_O365Business! equ 0 if !_O365ProPlus! equ 0 (
set _O365ProPlus=1
echo O365EduCloud Suite -^> Mondo Licenses
echo.
call :InsLic Mondo
)
if !_ProPlus2019! equ 1 if !_O365ProPlus! equ 0 (
echo ProPlus2019 Suite
echo.
call :InsLic ProPlus2019
)
if !_ProPlus! equ 1 if !_O365ProPlus! equ 0 if !_ProPlus2019! equ 0 (
echo ProPlus Suite -^> ProPlus2019 Licenses
echo.
call :InsLic ProPlus2019
)
if !_Professional2019! equ 1 if !_O365ProPlus! equ 0 if !_ProPlus2019! equ 0 if !_ProPlus! equ 0 (
echo Professional2019 Suite -^> ProPlus2019 Licenses
echo.
call :InsLic ProPlus2019
)
if !_Professional! equ 1 if !_O365ProPlus! equ 0 if !_ProPlus2019! equ 0 if !_ProPlus! equ 0 if !_Professional2019! equ 0 (
echo Professional Suite -^> ProPlus2019 Licenses
echo.
call :InsLic ProPlus2019
)
if !_Standard2019! equ 1 if !_O365ProPlus! equ 0 if !_ProPlus2019! equ 0 if !_ProPlus! equ 0 if !_Professional2019! equ 0 if !_Professional! equ 0 (
echo Standard2019 Suite
echo.
call :InsLic Standard2019
)
if !_Standard! equ 1 if !_O365ProPlus! equ 0 if !_ProPlus2019! equ 0 if !_ProPlus! equ 0 if !_Professional2019! equ 0 if !_Professional! equ 0 if !_Standard2019! equ 0 (
echo Standard Suite -^> Standard2019 Licenses
echo.
call :InsLic Standard2019
)
for %%a in (ProjectPro2019,VisioPro2019,ProjectStd2019,VisioStd2019) do if !_%%a! equ 1 (
echo %%a SKU
echo.
call :InsLic %%a
)
for %%a in (ProjectPro,ProjectStd,VisioPro,VisioStd) do if !_%%a! equ 1 (
if !_%%a2019! equ 0 (
  echo %%a SKU -^> %%a2019 Licenses
  echo.
  call :InsLic %%a2019
  )
)
for %%a in (HomeBusiness2019,HomeStudent2019) do if !_%%a! equ 1 (
if !_O365ProPlus! equ 0 if !_ProPlus2019! equ 0 if !_ProPlus! equ 0 if !_Professional2019! equ 0 if !_Professional! equ 0 if !_Standard2019! equ 0 if !_Standard! equ 0 (
  set _Standard2019=1
  echo %%a Suite -^> Standard2019 Licenses
  echo.
  call :InsLic Standard2019
  )
)
for %%a in (HomeBusiness,HomeStudent) do if !_%%a! equ 1 (
if !_O365ProPlus! equ 0 if !_ProPlus2019! equ 0 if !_ProPlus! equ 0 if !_Professional2019! equ 0 if !_Professional! equ 0 if !_Standard2019! equ 0 if !_Standard! equ 0 if !_%%a2019! equ 0 (
  set _Standard2019=1
  echo %%a Suite -^> Standard2019 Licenses
  echo.
  call :InsLic Standard2019
  )
)
for %%a in (%A19Ids%,OneNote) do if !_%%a! equ 1 (
if !_O365ProPlus! equ 0 if !_ProPlus2019! equ 0 if !_ProPlus! equ 0 if !_Professional2019! equ 0 if !_Professional! equ 0 if !_Standard2019! equ 0 if !_Standard! equ 0 (
  echo %%a App
  echo.
  call :InsLic %%a
  )
)
for %%a in (Excel,Outlook,PowerPoint,Publisher,Word) do if !_%%a! equ 1 (
if !_O365ProPlus! equ 0 if !_ProPlus2019! equ 0 if !_ProPlus! equ 0 if !_Professional2019! equ 0 if !_Professional! equ 0 if !_Standard2019! equ 0 if !_Standard! equ 0 if !_%%a2019! equ 0 (
  echo %%a App
  echo.
  call :InsLic %%a2019
  )
)
for %%a in (Access2019) do if !_%%a! equ 1 (
if !_O365ProPlus! equ 0 if !_ProPlus2019! equ 0 if !_ProPlus! equ 0 if !_Professional2019! equ 0 if !_Professional! equ 0 (
  echo %%a App
  echo.
  call :InsLic %%a
  )
)
for %%a in (Access) do if !_%%a! equ 1 (
if !_O365ProPlus! equ 0 if !_ProPlus2019! equ 0 if !_ProPlus! equ 0 if !_Professional2019! equ 0 if !_Professional! equ 0 if !_%%a2019! equ 0 (
  echo %%a App
  echo.
  call :InsLic %%a2019
  )
)
for %%a in (SkypeforBusiness2019) do if !_%%a! equ 1 (
if !_O365ProPlus! equ 0 if !_ProPlus2019! equ 0 if !_ProPlus! equ 0 (
  echo %%a App
  echo.
  call :InsLic %%a
  )
)
for %%a in (SkypeforBusiness) do if !_%%a! equ 1 (
if !_O365ProPlus! equ 0 if !_ProPlus2019! equ 0 if !_ProPlus! equ 0 if !_%%a2019! equ 0 (
  echo %%a App
  echo.
  call :InsLic %%a2019
  )
)
goto :GVLK

:InsLic
set "_ID=%1Volume"
reg delete %_Config% /f /v %_ID%.OSPPReady %_Nul_1_2%
"%_Integrator%" /I /License PRIDName=%_ID%.16 PackageGUID="%_GUID%" PackageRoot="%_InstallRoot%" %_Nul_1%
reg add %_Config% /f /v %_ID%.OSPPReady /t REG_SZ /d 1 %_Nul_1%
reg query %_Config% /v ProductReleaseIds | findstr /I "%_ID%" %_Nul_1%
if %errorlevel% neq 0 (
for /f "skip=2 tokens=2*" %%a in ('reg query %_Config% /v ProductReleaseIds') do reg add %_Config% /f /v ProductReleaseIds /t REG_SZ /d "%%b,%_ID%" %_Nul_1%
)
exit /b

:GVLK
echo ============================================================
echo Installing Missing KMS Client Keys...
echo ============================================================
echo.
for /f "tokens=2 delims==" %%G in ('"wmic path %spp% where (Description like '%%KMSCLIENT%%' AND LicenseFamily like 'Office%%' AND PartialProductKey=NULL) get ID /value" %_Nul_2e%') do (set app=%%G&call :InsKey)
if exist "%SystemRoot%\System32\spp\store_test\2.0\tokens.dat" (
echo.
echo ============================================================
echo Refreshing Windows Insider Preview Licenses...
echo ============================================================
echo.
cscript //Nologo //B %_SLMGR% /rilc
)
set "msg=Finished"
goto :end

:InsKey
if /i '%app%' equ 'e914ea6e-a5fa-4439-a394-a9bb3293ca09' exit /b
if /i '%app%' equ '0bc88885-718c-491d-921f-6f214349e79c' exit /b
if /i '%app%' equ 'fc7c4d0c-2e85-4bb9-afd4-01ed1476b5e9' exit /b
if /i '%app%' equ '500f6619-ef93-4b75-bcb4-82819998a3ca' exit /b
set "key="
for /f "tokens=2 delims==" %%A in ('"wmic path %spp% where ID='%app%' get LicenseFamily /value"') do echo %%A
for /f %%A in ('cscript //Nologo x86\key.vbs %app%') do set "key=%%A"
if "%key%" equ "" (echo Could not find matching gVLK&echo.&exit /b)
wmic path %sps% where version='%ver%' call InstallProductKey ProductKey="%key%" %_Nul_1_2%
echo.
exit /b

:end
echo.
echo ============================================================
echo %msg%
echo ============================================================
echo.
echo Press any key to exit...
if %_Debug% EQU 0 pause >nul
goto :eof