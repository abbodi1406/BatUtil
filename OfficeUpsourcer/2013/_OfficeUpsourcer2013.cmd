@setlocal DisableDelayedExpansion
@set uvr=v5
@echo off

set "Location_for_Extracted_OfficeSetupFiles="
set "Location_for_Extracted_ServicePack="
set "Location_for_Extracted_Updates="

set Pause_After_Each_Step=1

set Remove_Backups_When_Finished=1

set Use_LZX_CAB_Compression=1

set Insert_PatchAdd_VBScript=1

:: ###################################################################

set _vrn=15.0.5599.1000
set _vrn=15.0.4569.1506

set _elev=
set _args=
set _args=%*
if not defined _args goto :NoProgArgs
for %%A in (%_args%) do (
if /i "%%A"=="-elevated" set _elev=1
if /i "%%A"=="-wow" set _rel1=1
if /i "%%A"=="-arm" set _rel2=1
)
:NoProgArgs
set "_cmdf=%~f0"
if exist "%SystemRoot%\Sysnative\cmd.exe" if not defined _rel1 (
setlocal EnableDelayedExpansion
start %SystemRoot%\Sysnative\cmd.exe /c ""!_cmdf!" -wow"
exit /b
)
if exist "%SystemRoot%\SysArm32\cmd.exe" if /i %PROCESSOR_ARCHITECTURE%==AMD64 if not defined _rel2 (
setlocal EnableDelayedExpansion
start %SystemRoot%\SysArm32\cmd.exe /c ""!_cmdf!" -arm"
exit /b
)
set "Path=%SystemRoot%\System32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
if exist "%SystemRoot%\Sysnative\reg.exe" (
set "Path=%SystemRoot%\Sysnative;%SystemRoot%;%SystemRoot%\Sysnative\Wbem;%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\;%Path%"
)

ver|findstr /c:" 5." >nul && goto :Passed
set WINBLD=99999
for /f "tokens=2 delims=[]" %%# in ('ver') do for /f "tokens=4 delims=. " %%A in ("%%~#") do set "WINBLD=%%A"
if %WINBLD% lss 6000 goto :Passed

whoami /groups 2>nul | findstr /i /c:"S-1-16-16384" /c:"S-1-16-12288" 1>nul || (set "msg=ERROR: This script requires administrator privileges."&goto :TheEnd)

:Passed
set _WSH=1
reg query "HKCU\SOFTWARE\Microsoft\Windows Script Host\Settings" /v Enabled 2>nul | find /i "0x0" 1>nul && (set _WSH=0)
reg query "HKLM\SOFTWARE\Microsoft\Windows Script Host\Settings" /v Enabled 2>nul | find /i "0x0" 1>nul && (set _WSH=0)
if %_WSH% equ 0 goto :E_WSH

if not defined Location_for_Extracted_OfficeSetupFiles set "Location_for_Extracted_OfficeSetupFiles=%~dp0"
if "%Location_for_Extracted_OfficeSetupFiles:~-1%"=="\" set "Location_for_Extracted_OfficeSetupFiles=%Location_for_Extracted_OfficeSetupFiles:~0,-1%"
set "_work=%~dp0_bin"
set "_cscript=cscript.exe //NoLogo"
setlocal EnableDelayedExpansion
pushd "!_work!"
for %%# in (WiAddAdmin WiCodepage WiFilVer WiMakCabs WiRunSQL WiSumInf XmlMod ZZZ rePatchesCA rePatchesmui rePatchesww) do (
if not exist ".\%%#.vbs" (set "msg=ERROR: required file _bin\%%#.vbs is missing"&goto :TheEnd)
)
for %%# in (install.exe ose.exe osetup.dll setup.dll setup.exe) do (
if not exist "x64\%%#" (set "msg=ERROR: required file _bin\x64\%%# is missing"&goto :TheEnd)
if not exist "x86\%%#" (set "msg=ERROR: required file _bin\x86\%%# is missing"&goto :TheEnd)
)
%_cscript% ZZZ.vbs
if %errorlevel% neq 48 goto :E_WSH
popd

title Office 2013 MSI Upsourcer %uvr%

if not defined Location_for_Extracted_ServicePack set "Location_for_Extracted_ServicePack=!Location_for_Extracted_OfficeSetupFiles!\Updates"
if not defined Location_for_Extracted_Updates set "Location_for_Extracted_Updates=!Location_for_Extracted_OfficeSetupFiles!\Updates"
set "_tgt=!Location_for_Extracted_OfficeSetupFiles!"
set "_svc=!Location_for_Extracted_ServicePack!"
set "_upd=!Location_for_Extracted_Updates!"
set "_sst=1"
set "_sst=%Pause_After_Each_Step%"
set "_ssr=1"
set "_ssr=%Remove_Backups_When_Finished%"
set "_ssc=1"
set "_ssc=%Use_LZX_CAB_Compression%"
set "_ssv=1"
set "_ssv=%Insert_PatchAdd_VBScript%"

set Unified_Setup_EXE=0
set "_ssd=0"
set "_ssd=%Unified_Setup_EXE%"

rem if not exist "!_tgt!\setup.exe" (set "msg=ERROR: no setup.exe is detected in Location_for_Extracted_OfficeSetupFiles"&goto :TheEnd)
set doSvpk=1
if not exist "!_svc!\*Clientsharedmuisp*.msp" if not exist "!_svc!\*Proofingsp*.msp" set doSvpk=0
set doUpdt=1
if not exist "!_upd!\*-x-none*.msp" set doUpdt=0
if %doSvpk% equ 0 if %doUpdt% equ 0 (set "msg=ERROR: no msp files detected in either ServicePack or Updates locations"&goto :TheEnd)
if not exist "!_upd!\*ocfxca-x-none*.msp" (
echo.
echo Warning: Important update KB3039720 ocfxca-x-none.msp is not detected
)

:Detection
pushd "!_tgt!"
for /r %%# in (*MUI*.msi *Proof.msi *Proofing.msi *WW.msi) do (
set _offmsi=1
)
if not defined _offmsi (set "msg=ERROR: could not Office msi files"&goto :TheEnd)

for %%A in (Office Office32 Office64 Proofing ProofMUI) do (
if not defined _lng for /f "tokens=2 delims=." %%# in ('dir /b /ad %%A.*-* 2^>nul') do set "_lng=%%#"
)
if not defined _lng (set "msg=ERROR: could not detect Office language"&goto :TheEnd)

set _bit=x86
dir /b /ad Office32.*-* 1>nul 2>nul && set _bit=x64

:SingularizeWOW
echo.
echo - Move Office WOW files to a single folder
if not exist "Office64.WW\*.msi" (
md Office64.WW 2>nul
for /r %%# in (*Office64WW.msi) do (
  move /y "%%~dp#\Office64WW.*" "Office64.WW\" >nul
  move /y "%%~dp#\OWOW64WW.cab" "Office64.WW\" >nul
  )
)
if not exist "Office32.WW\*.msi" (
md Office32.WW 2>nul
for /r %%# in (*Office32WW.msi) do (
  move /y "%%~dp#\Office32WW.*" "Office32.WW\" >nul
  move /y "%%~dp#\OWOW32WW.cab" "Office32.WW\" >nul
  )
)
if not exist "Office64.WW\*.msi" (
rd /s /q Office64.WW 2>nul
)
if not exist "Office32.WW\*.msi" (
rd /s /q Office32.WW 2>nul
)
call :Unattend

:ModifyXML
echo.
echo - Modify Setup and Package xml files
for /r %%# in (*setup.xml) do (
pushd "%%~dp#"
ren %%~nx# %%~n#.lmx
findstr /i /v "\-\-_" %%~n#.lmx>%%~nx#
%_cscript% "!_work!\XmlMod.vbs" %%~nx#
popd
)
for /r %%# in (*MUI*.xml *Proof.xml *Proofing.xml *WW.xml) do (
pushd "%%~dp#"
ren %%~nx# %%~n#.lmx
findstr /i /v "\-\-_" %%~n#.lmx>%%~nx#
%_cscript% "!_work!\XmlMod.vbs" %%~nx# %_vrn%
popd
)
call :Unattend

:AdminMSI
echo.
echo - Restore administrative installation table
rem. echo.
for /r %%# in (*MUI*.msi *Proof.msi *Proofing.msi *WW.msi) do (
pushd "%%~dp#"
rem. echo %%~nx#
copy /y %%~nx# %%~n#.ism >nul
%_cscript% "!_work!\WiAddAdmin.vbs" %%~nx#
popd
)
call :Unattend

:AddServicePack
if %doSvpk% equ 0 goto :AddUpdates
echo.
echo - Slipstream Service Pack
echo.
call :MsiMsp 1

for /f "tokens=2 delims=." %%# in ('dir /b /ad ProofKit.WW\ 2^>nul') do (
if defined svcproof%%# call :prfsvc "ProofKit.WW\Proof.%%#" "proofkit.ww\proof.%%#\proof.msi" %%#
)
for /f "tokens=2 delims=." %%I in ('dir /b /ad Proofing.* 2^>nul') do for /f "tokens=2 delims=." %%# in ('dir /b /ad Proofing.%%I\ 2^>nul') do (
if defined svcproof%%# call :prfsvc "Proofing.%%I\Proof.%%#" "%%I\proof.%%#\proof.msi" %%#
)

for /r %%# in (*MUI*.msi *Proofing.msi) do (
pushd "%%~dp#"
call :muisvc %%~nx#
popd
)

for /r %%# in (*ProofMUI.msi *ProofKitWW.msi) do (
pushd "%%~dp#"
rem. echo %%~nx#
%_cscript% "!_work!\WiRunSQL.vbs" %%~nx# "UPDATE `Property` SET `Value` = '%_vrn%' WHERE `Property` = 'ProductVersion'"
popd
)

for /r %%# in (*WW.msi) do if /i not %%~n#==ProofKitWW (
pushd "%%~dp#"
call set "_ptc="
if defined %%~n# for %%A in (!%%~n#!) do if defined svc%%A (
  set "_ptc=!_svc!\!svc%%A!;!_ptc!"
  )
if not defined _ptc if defined svcww set "_ptc=!svcww!"
if defined _ptc (
  echo %%~nx#
  start /wait msiexec.exe /a %%~nx# /quiet SHORTFILENAMES=1 TARGETDIR="!cd!" PATCH="!_ptc!"
  %_cscript% "!_work!\WiSumInf.vbs" %%~nx# Words=1
  )
popd
)

call :Unattend
goto :AddUpdates

:prfsvc
pushd %1
echo %~2
call set "_ptc="
if defined updproof%3 (set "_ptc=!_svc!\!svcproof%3!;!_upd!\!updproof%3!") else (set "_ptc=!_svc!\!svcproof%3!")
call set "doneproof%3=1"
for /f "tokens=2 delims==" %%Q in ('%_cscript% "!_work!\WiCodepage.vbs" Proof.msi') do call set _cp=%%Q
%_cscript% "!_work!\WiCodepage.vbs" Proof.msi 0
if defined updocfxca (
  start /wait msiexec.exe /a Proof.msi /quiet SHORTFILENAMES=1 TARGETDIR="!cd!\Q" PATCH="!_upd!\!updocfxca!"
  if exist "Q\FILES\" rd /s /q "\\?\!cd!\Q\"
  %_cscript% "!_work!\WiCodepage.vbs" Proof.msi 0
  )
start /wait msiexec.exe /a Proof.msi /quiet SHORTFILENAMES=1 TARGETDIR="!cd!" PATCH="!_ptc!"
%_cscript% "!_work!\WiCodepage.vbs" Proof.msi !_cp!
%_cscript% "!_work!\WiSumInf.vbs" Proof.msi Words=1
popd
exit /b

:muisvc
set "_d="
set "_d=%cd:~-5%"
if /i "%_d%"=="tn-cs" set "_d=sr-latn-cs"
for /f "tokens=2 delims==" %%Q in ('%_cscript% "!_work!\WiCodepage.vbs" %1') do call set _cp=%%Q
call set "_ptc="
if defined %~n1 for %%A in (!%~n1!) do if defined %_d%_svc%%A (
  set "_ptc=!_svc!\!%_d%_svc%%A!;!_ptc!"
  )
if defined _ptc (
  echo %_d%\%1
  %_cscript% "!_work!\WiCodepage.vbs" %1 0 
  start /wait msiexec.exe /a %1 /quiet SHORTFILENAMES=1 TARGETDIR="!cd!" PATCH="!_ptc!"
  %_cscript% "!_work!\WiCodepage.vbs" %1 !_cp!
  %_cscript% "!_work!\WiSumInf.vbs" %1 Words=1
)
exit /b

:AddUpdates
if %doUpdt% equ 0 goto :AddModdedFiles
echo.
echo - Slipstream Updates
echo.
call :MsiMsp 2

for /f "tokens=2 delims=." %%# in ('dir /b /ad ProofKit.WW\ 2^>nul') do (
if defined updproof%%# call :prfupd "ProofKit.WW\Proof.%%#" "proofkit.ww\proof.%%#\proof.msi" %%#
)
for /f "tokens=2 delims=." %%I in ('dir /b /ad Proofing.* 2^>nul') do for /f "tokens=2 delims=." %%# in ('dir /b /ad Proofing.%%I\ 2^>nul') do (
if defined updproof%%# call :prfupd "Proofing.%%I\Proof.%%#" "%%I\proof.%%#\proof.msi" %%#
)

for /r %%# in (*MUI*.msi *Proofing.msi) do (
pushd "%%~dp#"
call :muiupd %%~nx#
popd
)

for /r %%# in (*WW.msi) do (
pushd "%%~dp#"
call set "_px="
for /f "tokens=1 delims=|" %%X in ('%_cscript% "!_work!\WiRunSQL.vbs" %%~nx# "SELECT `FileName` FROM `File` WHERE `Component_` = 'Setupexe_PackageXml'"') do call set "_px=%%X"
call set "_xtrn="
if defined _px (for /r %%G in (*!_px!) do if /i not "%%~dpG"=="!cd!\" set "_xtrn=1") else (for /r "FILES" %%G in (*.xml) do if /i not "%%~nG"=="branding" set "_xtrn=1")
call set "_ptc="
if defined %%~n# for %%A in (!%%~n#!) do if defined upd%%A (
  set "_ptc=!_upd!\!upd%%A!;!_ptc!"
  )
if defined _ptc (
  echo %%~nx#
  copy /y %%~nx# %%~n#.svc >nul
  for /f "tokens=2 delims==" %%Q in ('%_cscript% "!_work!\WiCodepage.vbs" %%~nx#') do call set _cp=%%Q
  %_cscript% "!_work!\WiCodepage.vbs" %%~nx# 0
  if defined _xtrn (
  start /wait msiexec.exe /a %%~nx# /quiet SHORTFILENAMES=1 TARGETDIR="!cd!\Z" /p "!_ptc!"
  xcopy /CIDERY "!cd!\Z\*" "!cd!\" >nul
  rd /s /q "\\?\!cd!\Z\"
  ) else (
  start /wait msiexec.exe /a %%~nx# /quiet SHORTFILENAMES=1 TARGETDIR="!cd!" /p "!_ptc!"
  )
  %_cscript% "!_work!\WiCodepage.vbs" %%~nx# !_cp!
)
popd
)

call :Unattend
goto :AddModdedFiles

:prfupd
if defined doneproof%3 exit /b
pushd %1
echo %~2
copy /y Proof.msi Proof.svc >nul
call set "_px="
for /f "tokens=1 delims=|" %%X in ('%_cscript% "!_work!\WiRunSQL.vbs" Proof.msi "SELECT `FileName` FROM `File` WHERE `Component_` = 'Setupexe_PackageXml'"') do call set "_px=%%X"
call set "_xtrn="
if defined _px (for /r %%G in (*!_px!) do if /i not "%%~dpG"=="!cd!\" set "_xtrn=1") else (for /r "FILES" %%G in (*.xml) do if /i not "%%~nG"=="branding" set "_xtrn=1")
call set "_ptc="
set "_ptc=!_upd!\!updproof%3!"
for /f "tokens=2 delims==" %%Q in ('%_cscript% "!_work!\WiCodepage.vbs" Proof.msi') do call set _cp=%%Q
%_cscript% "!_work!\WiCodepage.vbs" Proof.msi 0
if defined updocfxca (
  start /wait msiexec.exe /a Proof.msi /quiet SHORTFILENAMES=1 TARGETDIR="!cd!\Q" /p "!_upd!\!updocfxca!"
  if exist "Q\FILES\" rd /s /q "\\?\!cd!\Q\"
  %_cscript% "!_work!\WiCodepage.vbs" Proof.msi 0
  )
if defined _xtrn (
  start /wait msiexec.exe /a Proof.msi /quiet SHORTFILENAMES=1 TARGETDIR="!cd!\Z" /p "!_ptc!"
  xcopy /CIDERY "!cd!\Z\*" "!cd!\" >nul
  rd /s /q "\\?\!cd!\Z\"
  ) else (
  start /wait msiexec.exe /a Proof.msi /quiet SHORTFILENAMES=1 TARGETDIR="!cd!" /p "!_ptc!"
  )
%_cscript% "!_work!\WiCodepage.vbs" Proof.msi !_cp!
popd
exit /b

:muiupd
set "_d="
set "_d=%cd:~-5%"
if /i "%_d%"=="tn-cs" set "_d=sr-latn-cs"
call set "_px="
for /f "tokens=1 delims=|" %%X in ('%_cscript% "!_work!\WiRunSQL.vbs" %1 "SELECT `FileName` FROM `File` WHERE `Component_` = 'Setupexe_PackageXml'"') do call set "_px=%%X"
call set "_xtrn="
if defined _px (for /r %%G in (*!_px!) do if /i not "%%~dpG"=="!cd!\" set "_xtrn=1") else (for /r "FILES" %%G in (*.xml) do if /i not "%%~nG"=="branding" set "_xtrn=1")
call set "_ptc="
if defined %~n1 for %%A in (!%~n1!) do if defined %_d%_upd%%A (
  set "_ptc=!_upd!\!%_d%_upd%%A!;!_ptc!"
  )
if not defined updocfxca if not defined _ptc exit /b
for /f "tokens=2 delims==" %%Q in ('%_cscript% "!_work!\WiCodepage.vbs" %1') do call set _cp=%%Q
%_cscript% "!_work!\WiCodepage.vbs" %1 0
if defined updocfxca (
  if defined _ptc (
  start /wait msiexec.exe /a %1 /quiet SHORTFILENAMES=1 TARGETDIR="!cd!\Q" /p "!_upd!\!updocfxca!"
  if exist "Q\FILES\" rd /s /q "\\?\!cd!\Q\"
  %_cscript% "!_work!\WiCodepage.vbs" %1 0
  ) else (
  echo %_d%\%1
  start /wait msiexec.exe /a %1 /quiet SHORTFILENAMES=1 TARGETDIR="!cd!\Z" /p "!_upd!\!updocfxca!"
  xcopy /CIDERY "!cd!\Z\*" "!cd!\" >nul
  rd /s /q "\\?\!cd!\Z\"
  )
)
if defined _ptc (
  echo %_d%\%1
  copy /y %1 %~n1.svc >nul
  if defined _xtrn (
  start /wait msiexec.exe /a %1 /quiet SHORTFILENAMES=1 TARGETDIR="!cd!\Z" /p "!_ptc!"
  xcopy /CIDERY "!cd!\Z\*" "!cd!\" >nul
  rd /s /q "\\?\!cd!\Z\"
  ) else (
  start /wait msiexec.exe /a %1 /quiet SHORTFILENAMES=1 TARGETDIR="!cd!" /p "!_ptc!"
  )
)
%_cscript% "!_work!\WiCodepage.vbs" %1 !_cp!
exit /b

:AddModdedFiles
echo.
echo - Replace original osetup.dll, setup.dll and setup.exe
for /r %%# in (*WW.msi OMUI*.msi PMUI*.msi VisMUI*.msi *ProofMUI.msi) do (
pushd "%%~dp#"
call set "_ver="
if exist "osetup.dll" if not exist "osetup.lld" (
  copy /y osetup.dll osetup.lld >nul
  copy /y ose.exe ose.xex >nul
  copy /y "!_work!\%_bit%\osetup.dll" . >nul
  copy /y "!_work!\%_bit%\ose.exe" . >nul
  copy /y "!_work!\%_bit%\setup.exe" .\setup.exe >nul
  )
if exist "psetup.dll" if not exist "psetup.lld" (
  copy /y psetup.dll psetup.lld >nul
  copy /y ose.exe ose.xex >nul
  copy /y "!_work!\%_bit%\osetup.dll" .\psetup.dll >nul
  copy /y "!_work!\%_bit%\osetup.dll" . >nul
  copy /y "!_work!\%_bit%\ose.exe" . >nul
  copy /y "!_work!\%_bit%\setup.exe" .\setup.exe >nul
  )
if exist "osetupui.dll" (
  copy /y "!_work!\%_bit%\osetup.dll" . >nul
  copy /y "!_work!\%_bit%\setup.exe" .\setup.exe >nul
  )
if exist "psetupui.dll" (
  copy /y "!_work!\%_bit%\psetup.dll" . >nul
  copy /y "!_work!\%_bit%\setup.exe" .\setup.exe >nul
  )
for /r %%A in (*osetup.dll) do if /i not "%%~dpA"=="%%~dp#" (
  copy /y "!cd!\osetup.dll" "%%A" >nul
  set "_ver=1"
  )
for /r %%A in (*psetup.dll) do if /i not "%%~dpA"=="%%~dp#" (
  copy /y "!cd!\psetup.dll" "%%A" >nul
  set "_ver=1"
  )
for /r %%A in (*setup.exe) do if /i not "%%~dpA"=="%%~dp#" (
  copy /y "!cd!\setup.exe" "%%A" >nul
  set "_ver=1"
  )
if defined _ver %_cscript% "!_work!\WiFilVer.vbs" %%~nx# /U
if exist "setup.exe" del /f /q setup.exe
if exist "osetup.dll" if not exist "osetup.lld" del /f /q osetup.dll
if exist "psetup.dll" if not exist "psetup.lld" del /f /q psetup.dll
popd
)
if exist "setup.dll" (
move /y setup.dll setup.lld >nul
copy /y "!_work!\%_bit%\setup.dll" .\setup.dll >nul
)
if exist "setup.exe" if %_ssd% equ 1 (
move /y setup.exe setup.xex >nul
copy /y "!_work!\%_bit%\install.exe" .\setup.exe >nul
)
call :Unattend

:PatchesCA
if %_ssv% neq 1 goto :MakeDDF
echo.
echo - Insert PatchAdd vbscript into MSIs
for /r %%# in (*MUI*.msi *Proof.msi *Proofing.msi) do (
pushd "%%~dp#"
%_cscript% "!_work!\rePatchesCA.vbs" %%~nx# rePatchesmui.vbs
popd
)
for /r %%# in (*WW.msi) do (
pushd "%%~dp#"
%_cscript% "!_work!\rePatchesCA.vbs" %%~nx# rePatchesww.vbs
popd
)
call :Unattend

:MakeDDF
echo.
echo - Create MakeCAB DDF directives
echo.
for /r %%# in (*.ddf) do (
del /f /q "%%#"
)

for /f "tokens=2 delims=." %%# in ('dir /b /ad ProofKit.WW\ 2^>nul') do (
pushd "ProofKit.WW\Proof.%%#"
for %%A in (proof) do if exist "%%A.msi" (
call :doDDF %%A.msi "proofkit.ww\proof.%%#\%%A.msi"
)
popd
)

for /f "tokens=2 delims=." %%I in ('dir /b /ad Proofing.* 2^>nul') do for /f "tokens=2 delims=." %%# in ('dir /b /ad Proofing.%%I\ 2^>nul') do (
pushd "Proofing.%%I\Proof.%%#"
for %%A in (proof) do if exist "%%A.msi" (
call :doDDF %%A.msi "%%I\proof.%%#\%%A.msi"
)
popd
)

for /r %%# in (*MUI*.msi *Proofing.msi) do (
pushd "%%~dp#"
call set "_d="
set "_d=!cd:~-5!"
if /i "!_d!"=="tn-cs" set "_d=sr-latn-cs"
call :doDDF %%~nx# "!_d!\%%~nx#"
popd
)

for /r %%# in (*WW.msi) do (
pushd "%%~dp#"
call :doDDF %%~nx# "%%~nx#"
popd
)

call :Unattend
goto :MakCabs

:doDDF
call set "_px="
for /f "tokens=1 delims=|" %%X in ('%_cscript% "!_work!\WiRunSQL.vbs" %1 "SELECT `FileName` FROM `File` WHERE `Component_` = 'Setupexe_PackageXml'"') do call set "_px=%%X"
call set "_xtrn="
if defined _px (for /r %%G in (*!_px!) do if /i not "%%~dpG"=="!cd!\" set "_xtrn=1") else (for /r "FILES" %%G in (*.xml) do if /i not "%%~nG"=="branding" set "_xtrn=1")
if not defined _xtrn exit /b
echo %~2 |findstr /i /v Proofing\.msi
copy /y %1 %~n1.upd >nul
%_cscript% "!_work!\WiSumInf.vbs" %1 Words=1
%_cscript% "!_work!\WiMakCabs.vbs" %1 netfx /U /L
%_cscript% "!_work!\WiSumInf.vbs" %1 Words=2
for %%A in (*.cab) do if exist "%%~nA.ddf" if not exist "%%~nA.bac" (ren %%~nxA %%~nA.bac)
exit /b

:MakCabs
echo.
echo - Create new CAB files
echo.
set _cmp=LZX
if %_ssc% neq 1 set _cmp=MSZIP

for /f "tokens=2 delims=." %%# in ('dir /b /ad ProofKit.WW\ 2^>nul') do (
pushd "ProofKit.WW\Proof.%%#"
for %%A in (*.ddf) do if not exist "%%~nA.cab" (
echo proofkit.ww\proof.%%#\%%~nA.cab
makecab.exe /V0 /D CabinetNameTemplate=%%~nA.cab /D CompressionType=%_cmp% /F "!_work!\directive.txt" /F %%~nxA >nul
)
popd
)

for /f "tokens=2 delims=." %%I in ('dir /b /ad Proofing.* 2^>nul') do for /f "tokens=2 delims=." %%# in ('dir /b /ad Proofing.%%I\ 2^>nul') do (
pushd "Proofing.%%I\Proof.%%#"
for %%A in (*.ddf) do if not exist "%%~nA.cab" (
echo %%I\proof.%%#\%%~nA.cab
makecab.exe /V0 /D CabinetNameTemplate=%%~nA.cab /D CompressionType=%_cmp% /F "!_work!\directive.txt" /F %%~nxA >nul
)
popd
)

for /r %%# in (*MUI*.msi *Proofing.msi) do (
pushd "%%~dp#"
call set "_d="
set "_d=!cd:~-5!"
if /i "!_d!"=="tn-cs" set "_d=sr-latn-cs"
for %%A in (*.ddf) do if not exist "%%~nA.cab" (
echo !_d!\%%~nA.cab
makecab.exe /V0 /D CabinetNameTemplate=%%~nA.cab /D CompressionType=%_cmp% /F "!_work!\directive.txt" /F %%~nxA >nul
)
popd
)

for /r %%# in (*WW.msi) do (
pushd "%%~dp#"
for %%A in (*.ddf) do if not exist "%%~nA.cab" (
echo %%~nA.cab
makecab.exe /V0 /D CabinetNameTemplate=%%~nA.cab /D CompressionType=%_cmp% /F "!_work!\directive.txt" /F %%~nxA >nul
)
popd
)

call :Unattend

:RemoveExternalDirs
echo.
echo - Remove administrative installation directories
for /r %%# in (*MUI*.msi *Proof.msi *Proofing.msi *WW.msi) do (
pushd "%%~dp#"
rd /s /q "FILES\" 2>nul
rd /s /q "GAC_MSIL\" 2>nul
rd /s /q "PFiles\" 2>nul
rd /s /q "PFiles32\" 2>nul
rd /s /q "Program Files\" 2>nul
rd /s /q "Program Files (x86)\" 2>nul
rd /s /q "IDE\" 2>nul
rd /s /q "COMMON\" 2>nul
rd /s /q "GlobalAssemblyCache\" 2>nul
rd /s /q "GLOBAL_1\" 2>nul
rd /s /q "ALLUSE_1\" 2>nul
rd /s /q "USERPR_1\" 2>nul
rd /s /q "Windows\" 2>nul
rd /s /q "Win\" 2>nul
rd /s /q "swidtags\" 2>nul
rd /s /q "System\" 2>nul
rd /s /q "System64\" 2>nul
if exist "FILES\" rd /s /q "\\?\!cd!\FILES\" 2>nul
if exist "PFiles\" rd /s /q "\\?\!cd!\PFiles\" 2>nul
if exist "PFiles32\" rd /s /q "\\?\!cd!\PFiles32\" 2>nul
if exist "Program Files\" rd /s /q "\\?\!cd!\Program Files\" 2>nul
if exist "Program Files (x86)\" rd /s /q "\\?\!cd!\Program Files (x86)\" 2>nul
popd
)
call :Unattend

:RestoreWOW
echo.
echo - Restore Office WOW files to the original folder^(s^)
if exist "Office64.WW\*.msi" (
for /r %%# in (*WW.msi) do if /i not %%~n#==Office64WW if /i not %%~n#==Office32WW if /i not %%~n#==ProofKitWW (copy /y Office64.WW\* "%%~dp#" >nul)
rd /s /q "Office64.WW\"
) else if exist "Office32.WW\*.msi" (
for /r %%# in (*WW.msi) do if /i not %%~n#==Office64WW if /i not %%~n#==Office32WW if /i not %%~n#==ProofKitWW (copy /y Office32.WW\* "%%~dp#" >nul)
rd /s /q "Office32.WW\"
)
call :Unattend

:RemoveBackups
if %_ssr% neq 1 goto :Finished
echo.
echo - Remove original files backups
for /r %%# in (*.ism *.svc *.upd *.xex *.lld *.lmx *.bac *.ddf) do (
del /f /q %%#
)

:Finished
set "msg=Finished."
goto :TheEnd

:MsiMsp
for %%A in (
AccessMUISet Office64MUISet OfficeMUISet Proofing 
) do (
set "%%A="
)
for %%A in (
Office32 Office64 Office 
Access Excel Groove InfoPath OneNote Outlook PowerPoint Publisher Word 
Project Visio SharePointDesigner O X P Vis 
) do (
set "%%AMUI="
)
for %%A in (
Office32 Office64 
Access Excel Groove InfoPath OneNote Outlook PowerPoint Publisher Word 
PrjPro PrjStd VisPro VisStd SharePointDesigner 
Standard SmallBusBasics ProPlus Pro Personal Essentials HomeStudent 
) do (
set "%%AWW="
set "%%ArWW="
)
if %1 equ 2 goto :MspUpd

:MspSvc
set "svcww="
set "Office32MUI=Clientshared32muisp"
set "Office64MUISet=Clientshared64muisp"
set "Office64MUI=Clientshared64muisp"
set "OfficeMUISet=Clientsharedmuisp"
set "OfficeMUI=Clientsharedmuisp"
set "AccessMUISet=Officesuitemuisp"
set "AccessMUI=Officesuitemuisp"
set "ExcelMUI=Officesuitemuisp"
set "GrooveMUI=Officesuitemuisp"
set "InfoPathMUI=Officesuitemuisp"
set "OneNoteMUI=Officesuitemuisp"
set "OutlookMUI=Officesuitemuisp"
set "PowerPointMUI=Officesuitemuisp"
set "PublisherMUI=Officesuitemuisp"
set "WordMUI=Officesuitemuisp"
set "ProjectMUI=Projectmuisp"
set "VisioMUI=Visiomuisp"
set "SharePointDesignerMUI=Sharepointdesignermuisp"
set "LyncMUI=Officesuitemuisp"
set "DCFMUI=Officesuitemuisp"
set "OSMMUI=Officesuitemuisp"
set "OSMUXMUI=Officesuitemuisp"
set "XMUI=Officesuitemuisp"
set "OMUI=Officesuitemuisp"
set "PMUI=Officesuitemuisp"
set "VisMUI=Vismuisp"
set "Proofing=Proofingsp"
:: set "ProofMUI=Proofmuisp"
:: set "ProofKitWW=Proofkitwwsp"
set "Office32WW=Clientshared32wwsp"
set "Office64WW=Clientshared64wwsp"
set "AccessWW=Officesuitewwsp"
set "ExcelWW=Officesuitewwsp"
set "GrooveWW=Officesuitewwsp"
set "InfoPathWW=Officesuitewwsp"
set "OneNoteWW=Officesuitewwsp"
set "OutlookWW=Officesuitewwsp"
set "PowerPointWW=Officesuitewwsp"
set "PublisherWW=Officesuitewwsp"
set "WordWW=Officesuitewwsp"
set "PrjProWW=Projectwwsp"
set "PrjStdWW=Projectwwsp"
set "VisProWW=Visiowwsp"
set "VisStdWW=Visiowwsp"
set "SharePointDesignerWW=Sharepointdesignerwwsp"
set "LyncWW=Officesuitewwsp"
set "LyncEntryWW=Officesuitewwsp"
set "StandardWW=Officesuitewwsp"
set "ProPlusWW=Officesuitewwsp"
set "ProWW=Officesuitewwsp"
set "PersonalrWW=Officesuitewwsp"
set "EssentialsrWW=Officesuitewwsp"
set "HomeStudentrWW=Officesuitewwsp"
for %%A in (
Access Excel Groove InfoPath OneNote Outlook PowerPoint Publisher Word 
PrjPro PrjStd VisPro VisStd
Standard SmallBusBasics Pro ProPlus 
) do (
set "%%ArWW=!%%AWW!"
)

pushd "!_svc!"
for %%A in (
Clientshared32wwsp Clientshared64wwsp Officesuitewwsp
Projectwwsp Visiowwsp Sharepointdesignerwwsp
) do (
for /f "tokens=* delims=" %%# in ('dir /b /od *%%A-x-none*.msp 2^>nul') do (set "svc%%A=%%#"&set "svcww=!_svc!\%%#;!svcww!")
)
for %%A in (
ar-sa bg-bg cs-cz da-dk de-de el-gr en-us es-es et-ee fi-fi 
fr-fr he-il hi-in hr-hr hu-hu id-id it-it ja-jp kk-kz ko-kr 
lt-lt lv-lv ms-my nb-no nl-nl pl-pl pt-br pt-pt ro-ro ru-ru 
sk-sk sl-si sv-se th-th tr-tr uk-ua vi-vn zh-cn zh-tw sr-latn-cs
) do (
for %%I in (
Clientshared32muisp Clientshared64muisp Clientsharedmuisp Officesuitemuisp
Projectmuisp Visiomuisp Sharepointdesignermuisp Vismuisp Proofingsp
) do (
for /f "tokens=* delims=" %%# in ('dir /b /od *%%I-%%A*.msp 2^>nul') do set "%%A_svc%%I=%%#"
)
)
popd

for /f "tokens=* delims=" %%# in ('dir /b /od "!_upd!\*ocfxca-x-none*.msp" 2^>nul') do set "updocfxca=%%#"

for /f "tokens=2 delims=." %%# in ('dir /b /ad ProofKit.WW\ 2^>nul') do call :MspPrf %%#
for /f "tokens=2 delims=." %%I in ('dir /b /ad Proofing.* 2^>nul') do for /f "tokens=2 delims=." %%# in ('dir /b /ad Proofing.%%I\ 2^>nul') do call :MspPrf %%#
goto :eof

:MspUpd
set "_ppp=excel excelpp filterpack gfonts gkall graph infopathpc ipeditor msqry32 nlgmsfad onenote osc oscfb otkruntimertl outexum powerpoint ppaddin stslist visio wordpia word"
set "_all=ocfxca ace airspacewer clview csi csisyncclient eurotool exppdf fm20 ieawsdc mscomctlocx msmipc mso msohevi msptls mtextra oart ocr oleo orgidcrl ose osetup osfclient ospp outlfltr outlook peopledatahandler protocolhandler riched20 seguiemj vbe7 vviewer wec wxpcore wxpnse xmleditverbhandler"
set "Office32MUI=groove excel"
set "Office64MUI=groove"
set "Office64MUISet="
set "OfficeMUISet="
set "OfficeMUI=ace conv eqnedt32 excel fm20 infopath mso ose osfclient vviewer"
set "AccessMUI=access"
set "AccessMUISet="
set "ExcelMUI=analys32 dcf excel excelpp"
set "GrooveMUI=groove"
set "InfoPathMUI=infopath"
set "OneNoteMUI=onenote"
set "OutlookMUI=outlook osc word"
set "PowerPointMUI=powerpoint excel"
set "PublisherMUI=publisher"
set "WordMUI=word excel"
set "ProjectMUI=project"
set "VisioMUI=visio"
set "SharePointDesignerMUI=conv spd"
set "LyncMUI=lync lynchelp word"
set "DCFMUI=dcf"
set "OSMMUI="
set "OSMUXMUI="
set "XMUI="
set "OMUI=osetup ospp"
set "PMUI=osetup ospp"
set "VisMUI=osetup ospp"
set "ProofMUI=osetup"
set "Proofing="
set "ProofKitWW=ocfxca osetup ospp"
set "Office32WW=ocfxca access csi excel groove ieawsdc infopath lync mso msohevi oleo onenote osfclient powerpoint project publisher visio wec word"
set "Office64WW=ocfxca csi filterpack groove ieawsdc infopath lync msohevi oleo onenote project visio xmleditverbhandler"
set "AccessWW=!_all! access dcf graph stslist"
set "ExcelWW=!_all! dcf excel excelpp filterpack gkall graph infopathpc ipeditor msqry32 otkruntimertl ppaddin stslist"
set "GrooveWW=!_all! groove infopathpc ipeditor"
set "InfoPathWW=!_all! infopath infopathpc ipeditor ipdmctrl"
set "OneNoteWW=!_all! filterpack onenote"
set "OutlookWW=!_all! filterpack nlgmsfad osc oscfb otkruntimertl outexum word"
set "PowerPointWW=!_all! excel filterpack gfonts gkall graph infopathpc ipeditor msqry32 powerpoint stslist word"
set "PublisherWW=!_all! gfonts gkall publisher word"
set "WordWW=!_all! excel filterpack gfonts gkall graph infopathpc ipeditor msqry32 otkruntimertl stslist wordpia word"
set "PrjProWW=!_all! mscomct2 project stslist"
set "PrjStdWW=!_all! mscomct2 project"
set "VisProWW=!_all! filterpack visio stslist"
set "VisStdWW=!_all! filterpack visio stslist"
set "SharePointDesignerWW=!_all! gkall infopathpc ipeditor spd stslist word"
set "LyncWW=!_all! lync"
set "LyncEntryWW=!_all! lync"
set "StandardWW=!_all! !_ppp! groove publisher"
set "ProPlusWW=!_all! !_ppp! access dcf groove infopath ipdmctrl lync publisher"
set "ProWW=!_all! !_ppp! access publisher"
set "SmallBusBasicsWW=!_all! !_ppp!"
set "PersonalrWW=!_all! !_ppp!"
set "EssentialsrWW=!_all! !_ppp!"
set "HomeStudentrWW=!_all! !_ppp!"
for %%A in (
Access Excel Groove InfoPath OneNote Outlook PowerPoint Publisher Word 
PrjPro PrjStd VisPro VisStd
Standard SmallBusBasics Pro ProPlus 
) do (
set "%%ArWW=!%%AWW!"
)

pushd "!_upd!"
for %%A in (
access ace airspacewer clview csi csisyncclient 
dcf eurotool excel excelpp exppdf filterpack fm20 
gfonts gkall graph groove ieawsdc infopath infopathpc 
ipeditor ipdmctrl lync mscomct2 mscomctlocx msmipc 
mso msohevi msptls msqry32 mtextra nlgmsfad 
oart ocfxca ocr oleo onenote orgidcrl osc oscfb ose osetup 
osfclient ospp otkruntimertl outexum outlfltr outlook 
peopledatahandler powerpoint ppaddin project protocolhandler 
publisher riched20 seguiemj spd stslist vbe7 visio vviewer 
wec wordpia word wxpcore wxpnse xmleditverbhandler 
) do (
for /f "tokens=* delims=" %%# in ('dir /b /od *%%A-x-none*.msp 2^>nul') do set "upd%%A=%%#"
)
for %%A in (
ar-sa bg-bg cs-cz da-dk de-de el-gr en-us es-es et-ee fi-fi 
fr-fr he-il hi-in hr-hr hu-hu id-id it-it ja-jp kk-kz ko-kr 
lt-lt lv-lv ms-my nb-no nl-nl pl-pl pt-br pt-pt ro-ro ru-ru 
sk-sk sl-si sv-se th-th tr-tr uk-ua vi-vn zh-cn zh-tw sr-latn-cs
) do (
for %%I in (
lynchelp
) do (
for /f "tokens=* delims=" %%# in ('dir /b /od *%%I-%%A*.msp 2^>nul') do set "%%A_upd%%I=%%#"
)
for %%I in (
analys32 eqnedt32 conv access ace dcf excel excelpp fm20 groove mso infopath 
lync ocfxca onenote osc ose osetup ospp osfclient outlook 
powerpoint project publisher spd visio vviewer word 
) do (
for /f "tokens=* delims=" %%# in ('dir /b /od *%%I-x-none*.msp 2^>nul') do set "%%A_upd%%I=%%#"
)
)
popd

for /f "tokens=2 delims=." %%# in ('dir /b /ad ProofKit.WW\ 2^>nul') do call :MspPrf %%#
for /f "tokens=2 delims=." %%I in ('dir /b /ad Proofing.* 2^>nul') do for /f "tokens=2 delims=." %%# in ('dir /b /ad Proofing.%%I\ 2^>nul') do call :MspPrf %%#
goto :eof

:MspPrf
set "_l=%1"
if /i "%_l%"=="ms" set "_l=ms-my"
if /i "%_l%"=="pt" set "_l=pt-pt"
if /i "%_l%"=="sr" set "_l=sr-latn-cs"
if exist "!_svc!\*proofsp-%_l%*.msp" for /f "tokens=* delims=" %%A in ('dir /b /od "!_svc!\*proofsp-%_l%*.msp" 2^>nul ^|findstr /i /v proofloc') do set "svcproof%1=%%A"
if exist "!_upd!\*proof-%_l%*.msp" for /f "tokens=* delims=" %%A in ('dir /b /od "!_upd!\*proof-%_l%*.msp" 2^>nul') do set "updproof%1=%%A"
goto :eof

:Unattend
if %_sst% neq 1 goto :eof
echo.
echo Press any key to continue...
pause >nul
goto :eof

:E_WSH
set "msg=ERROR: Windows Script Host is disabled or is not functional."
goto :TheEnd

:TheEnd
echo.
echo ============================================================
echo %msg%
echo.
echo Press any key to exit.
pause >nul
goto :eof
