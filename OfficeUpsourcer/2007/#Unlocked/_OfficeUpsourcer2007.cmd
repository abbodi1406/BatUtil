@setlocal DisableDelayedExpansion
@set uvr=v6 Unlocked
@echo off

set "Location_for_Extracted_OfficeSetupFiles="
set "Location_for_Extracted_ServicePack="
set "Location_for_Extracted_Updates="

set Pause_After_Each_Step=1

set Remove_Backups_When_Finished=1

set Use_LZX_CAB_Compression=1

set Insert_PatchAdd_VBScript=1

set Add_Patched_MSO_DLL=1

:: ###################################################################

set _vrn=12.0.6812.1000
set _vrn=12.0.6612.1000

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
for %%# in (WiAddAdmin WiCodepage WiExport WiImport WiFilVer WiMakCabs WiRunSQL WiSumInf XmlMod XmlGroove ZZZ rePatchesCA rePatchesmui rePatchesww) do (
if not exist ".\%%#.vbs" (set "msg=ERROR: required file _bin\%%#.vbs is missing"&goto :TheEnd)
)
for %%# in (install.exe osetup.dll psetup.dll setup.exe) do (
if not exist "x86\%%#" (set "msg=ERROR: required file _bin\x86\%%# is missing"&goto :TheEnd)
)
%_cscript% ZZZ.vbs
if %errorlevel% neq 48 goto :E_WSH
popd

title Office 2007 MSI Upsourcer %uvr%

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
set "_ssm=1"
set "_ssm=%Add_Patched_MSO_DLL%"

rem if not exist "!_tgt!\setup.exe" (set "msg=ERROR: no setup.exe is detected in Location_for_Extracted_OfficeSetupFiles"&goto :TheEnd)
set doSvpk=1
if not exist "!_svc!\*clientsharedmuisp3*.msp" set doSvpk=0
set doUpdt=1
if not exist "!_upd!\*-x-none*.msp" set doUpdt=0
if %doSvpk% equ 0 if %doUpdt% equ 0 (set "msg=ERROR: no msp files detected in either ServicePack or Updates locations"&goto :TheEnd)
if not exist "!_upd!\*targetdir*.msp" (
echo.
echo Warning: recommended update KB967642 targetdir.msp is not detected
)

:Detection
pushd "!_tgt!"
for /r %%# in (IME*.msi *MUI*.msi *Proof.msi *Proofing.msi *WW.msi) do (
set _offmsi=1
)
if not defined _offmsi (set "msg=ERROR: could not Office msi files"&goto :TheEnd)

for %%A in (Office Office32 Office64 Proofing ProofMUI) do (
if not defined _lng for /f "tokens=2 delims=." %%# in ('dir /b /ad %%A.*-* 2^>nul') do set "_lng=%%#"
)
if not defined _lng (set "msg=ERROR: could not detect Office language"&goto :TheEnd)

set _bit=x86
dir /b /ad Office32.*-* 1>nul 2>nul && set _bit=x64
if not exist "!_work!\%_bit%\mso.dll" set "_ssm=0"

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
for /r %%# in (IME*.xml *MUI*.xml *Proof.xml *Proofing.xml *WW.xml) do (
pushd "%%~dp#"
ren %%~nx# %%~n#.lmx
findstr /i /v "\-\-_" %%~n#.lmx>%%~nx#
%_cscript% "!_work!\XmlMod.vbs" %%~nx# %_vrn%
if /i "%%~n#"=="GrooveMUISet" call :grvsvc %%~nx#
popd
)
call :Unattend

:AdminMSI
echo.
echo - Restore administrative installation table
rem. echo.
for /r %%# in (IME*.msi *MUI*.msi *Proof.msi *Proofing.msi *WW.msi) do (
pushd "%%~dp#"
rem. echo %%~nx#
copy /y %%~nx# %%~n#.ism >nul
%_cscript% "!_work!\WiAddAdmin.vbs" %%~nx#
if /i %%~n#==OfficeMUISet (
%_cscript% "!_work!\WiRunSQL.vbs" %%~nx# "UPDATE `File` SET `FileName` = 'OffSetLR.XML|OfficeMUISet.XML' WHERE `Component_` = 'Setupexe_PackageXml'"
%_cscript% "!_work!\WiRunSQL.vbs" %%~nx# "UPDATE `Media` SET `Cabinet` = 'OffSetLR.CAB' WHERE `DiskId` = 1"
)
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
if defined svcproof%%# call :prfsvc "ProofKit.WW\Proof.%%#" "ProofKit.WW\Proof.%%#\Proof.msi" %%#
if exist "ProofKit.WW\Proof.%%#\IME*.msi" call :imesvc "ProofKit.WW\Proof.%%#" "ProofKit.WW\Proof.%%#" %%#
)
for /f "tokens=2 delims=." %%I in ('dir /b /ad Proofing.* 2^>nul') do for /f "tokens=2 delims=." %%# in ('dir /b /ad Proofing.%%I\ 2^>nul') do (
if defined svcproof%%# call :prfsvc "Proofing.%%I\Proof.%%#" "%%I\Proof.%%#\Proof.msi" %%#
if exist "Proofing.%%I\Proof.%%#\IME*.msi" call :imesvc "Proofing.%%I\Proof.%%#" "%%I\Proof.%%#" %%#
)

for /r %%# in (*MUI*.msi) do (
pushd "%%~dp#"
call :muisvc %%~nx#
popd
)

for /r %%# in (*WW.msi) do if /i not %%~n#==ProofKitWW (
pushd "%%~dp#"
if defined svcdirtarget if /i not %%~n#==Office64WW if /i not %%~n#==Office32WW (
  start /wait msiexec.exe /a %%~nx# /quiet SHORTFILENAMES=1 TARGETDIR="!cd!\Z" PATCH="!svcdirtarget!"
  if exist "Z\FILES\" rd /s /q "\\?\!cd!\Z\"
  )
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
for /f "tokens=2 delims==" %%Q in ('%_cscript% "!_work!\WiCodepage.vbs" Proof.msi') do call set _cp=%%Q
%_cscript% "!_work!\WiCodepage.vbs" Proof.msi 0
start /wait msiexec.exe /a Proof.msi /quiet SHORTFILENAMES=1 TARGETDIR="!cd!" PATCH="!_ptc!"
%_cscript% "!_work!\WiCodepage.vbs" Proof.msi !_cp!
%_cscript% "!_work!\WiSumInf.vbs" Proof.msi Words=1
popd
exit /b

:imesvc
pushd %1
for %%A in (IME32 IME64) do if exist "%%A.msi" if defined svc%%A%3 (
echo %~2\%%A.msi
call set "_ptc="
if defined upd%%A%3 (set "_ptc=!_svc!\!svc%%A%3!;!_upd!\!upd%%A%3!") else (set "_ptc=!_svc!\!svc%%A%3!")
call set "_unb="
if %WINBLD% geq 9200 if exist "!_work!\%%A-%3.tsm" (
  set "_unb=TRANSFORMS=%%A.mst"
  copy /y "!_work!\%%A-%3.tsm" %%A.mst >nul
  )
for /f "tokens=2 delims==" %%Q in ('%_cscript% "!_work!\WiCodepage.vbs" %%A.msi') do call set _cp=%%Q
%_cscript% "!_work!\WiCodepage.vbs" %%A.msi 0
start /wait msiexec.exe /a %%A.msi /quiet SHORTFILENAMES=1 TARGETDIR="!cd!" !_unb! PATCH="!_ptc!"
%_cscript% "!_work!\WiCodepage.vbs" %%A.msi !_cp!
%_cscript% "!_work!\WiSumInf.vbs" %%A.msi Words=1
)
if exist "*.mst" del /f /q "*.mst" >nul
popd
exit /b

:muisvc
set "_d="
set "_d=%cd:~-5%"
if /i "%_d%"=="tn-cs" set "_d=sr-latn-cs"
if not defined %_d%_%~n1hlp if not defined %_d%_svcmui exit /b
set "_pc="
for /f "tokens=2 delims==" %%Q in ('%_cscript% "!_work!\WiCodepage.vbs" %1') do call set _cp=%%Q
if "%_cp%"=="65001" set "_pc=1"
if defined _pc %_cscript% "!_work!\WiCodepage.vbs" %1 0
if defined %_d%_%~n1hlp (
  start /wait msiexec.exe /a %1 /quiet SHORTFILENAMES=1 TARGETDIR="!cd!" PATCH="!%_d%_%~n1hlp!"
)
call set "_px="
for /f "tokens=1 delims=|" %%X in ('%_cscript% "!_work!\WiRunSQL.vbs" %1 "SELECT `FileName` FROM `File` WHERE `Component_` = 'Setupexe_PackageXml'"') do call set "_px=%%X"
call set "_xtrn="
if defined _px (for /r %%G in (*!_px!) do if /i not "%%~dpG"=="!cd!\" set "_xtrn=1") else (for /r "FILES" %%G in (*.xml) do if /i not "%%~nG"=="branding" set "_xtrn=1")
if defined %_d%_svcmui (
  echo %_d%\%1
  if defined _xtrn (
  %_cscript% "!_work!\WiSumInf.vbs" %1 Words=1
  start /wait msiexec.exe /a %1 /quiet SHORTFILENAMES=1 TARGETDIR="!cd!\Z" PATCH="!%_d%_svcmui!"
  xcopy /CIDERY "!cd!\Z\*" "!cd!\" >nul
  rd /s /q "\\?\!cd!\Z\"
  ) else (
  start /wait msiexec.exe /a %1 /quiet SHORTFILENAMES=1 TARGETDIR="!cd!" PATCH="!%_d%_svcmui!"
  %_cscript% "!_work!\WiSumInf.vbs" %1 Words=1
  )
)
if defined _pc %_cscript% "!_work!\WiCodepage.vbs" %1 !_cp!
exit /b

:grvsvc
set "_d="
set "_d=%cd:~-5%"
for %%# in (
zh-cn:2052
zh-hk:3076
zh-tw:1028
ko-kr:1042
) do for /f "tokens=1,2 delims=:" %%A in ("%%#") do (
if "%_d%"=="%%A" (
    %_cscript% "!_work!\XmlGroove.vbs" %1 "%%B"
    %_cscript% "!_work!\XmlGroove.vbs" setup.xml
  )
)
exit /b

:AddUpdates
if %doUpdt% equ 0 goto :AddModdedFiles
echo.
echo - Slipstream Updates
echo.
call :MsiMsp 2

for /r %%# in (*MUI*.msi) do (
pushd "%%~dp#"
call :muiupd %%~nx#
popd
)

for /r %%# in (*WW.msi) do if /i not %%~n#==Office64WW if /i not %%~n#==Office32WW if defined updww (
pushd "%%~dp#"
call set "_px="
for /f "tokens=1 delims=|" %%X in ('%_cscript% "!_work!\WiRunSQL.vbs" %%~nx# "SELECT `FileName` FROM `File` WHERE `Component_` = 'Setupexe_PackageXml'"') do call set "_px=%%X"
call set "_xtrn="
if defined _px (for /r %%G in (*!_px!) do if /i not "%%~dpG"=="!cd!\" set "_xtrn=1") else (for /r "FILES" %%G in (*.xml) do if /i not "%%~nG"=="branding" set "_xtrn=1")
echo %%~nx#
copy /y %%~nx# %%~n#.svc >nul
if defined updniceclass if /i not %%~n#==ProofKitWW (
  %_cscript% "!_work!\WiExport.vbs" %%~nx# "!cd!" Class Extension 2>nul
  start /wait msiexec.exe /a %%~nx# /quiet SHORTFILENAMES=1 TARGETDIR="!cd!\Z" /p "!updniceclass!"
  if exist "Z\FILES\" rd /s /q "\\?\!cd!\Z\"
  %_cscript% "!_work!\WiImport.vbs" %%~nx# "!cd!" *.idt 2>nul
  if exist "*.idt" del /f /q "*.idt"
  %_cscript% "!_work!\WiRunSQL.vbs" %%~nx# "UPDATE `InstallExecuteSequence` SET `Condition` = '(VersionNT > 600)' WHERE `Action` = 'NiceClassCA'" 2>nul
  )
if defined _xtrn (
  start /wait msiexec.exe /a %%~nx# /quiet SHORTFILENAMES=1 TARGETDIR="!cd!\Z" /p "!updww!"
  xcopy /CIDERY "!cd!\Z\*" "!cd!\" >nul
  rd /s /q "\\?\!cd!\Z\"
  ) else (
  start /wait msiexec.exe /a %%~nx# /quiet SHORTFILENAMES=1 TARGETDIR="!cd!" /p "!updww!"
  )
popd
)

for /r %%# in (*Office32WW.msi *Office64WW.msi) do if defined updmsxml5 (
pushd "%%~dp#"
call set "_px="
for /f "tokens=1 delims=|" %%X in ('%_cscript% "!_work!\WiRunSQL.vbs" %%~nx# "SELECT `FileName` FROM `File` WHERE `Component_` = 'Setupexe_PackageXml'"') do call set "_px=%%X"
call set "_xtrn="
if defined _px (for /r %%G in (*!_px!) do if /i not "%%~dpG"=="!cd!\" set "_xtrn=1") else (for /r "FILES" %%G in (*.xml) do if /i not "%%~nG"=="branding" set "_xtrn=1")
echo %%~nx#
copy /y %%~nx# %%~n#.svc >nul
if defined _xtrn (
  start /wait msiexec.exe /a %%~nx# /quiet SHORTFILENAMES=1 TARGETDIR="!cd!\Z" /p "!updmsxml5!"
  xcopy /CIDERY "!cd!\Z\*" "!cd!\" >nul
  rd /s /q "\\?\!cd!\Z\"
  ) else (
  start /wait msiexec.exe /a %%~nx# /quiet SHORTFILENAMES=1 TARGETDIR="!cd!" /p "!updmsxml5!"
  )
popd
)

for /r %%# in (*Proofing.msi *ProofMUI.msi *ProofKitWW.msi) do (
pushd "%%~dp#"
rem. echo %%~nx#
%_cscript% "!_work!\WiRunSQL.vbs" %%~nx# "UPDATE `Property` SET `Value` = '%_vrn%' WHERE `Property` = 'ProductVersion'"
popd
)

call :Unattend
goto :AddModdedFiles

:muiupd
set "_d="
set "_d=%cd:~-5%"
if /i "%_d%"=="tn-cs" set "_d=sr-latn-cs"
set "_pc="
for /f "tokens=2 delims==" %%Q in ('%_cscript% "!_work!\WiCodepage.vbs" %1') do call set _cp=%%Q
if "%_cp%"=="65001" set "_pc=1"
call set "_px="
for /f "tokens=1 delims=|" %%X in ('%_cscript% "!_work!\WiRunSQL.vbs" %1 "SELECT `FileName` FROM `File` WHERE `Component_` = 'Setupexe_PackageXml'"') do call set "_px=%%X"
call set "_xtrn="
if defined _px (for /r %%G in (*!_px!) do if /i not "%%~dpG"=="!cd!\" set "_xtrn=1") else (for /r "FILES" %%G in (*.xml) do if /i not "%%~nG"=="branding" set "_xtrn=1")
call set "_ptc="
if defined %~n1 for %%A in (!%~n1!) do if defined %_d%_upd%%A (
  set "_ptc=!_upd!\!%_d%_upd%%A!;!_ptc!"
  )
if defined _ptc (
  echo %_d%\%1
  copy /y %1 %~n1.svc >nul
  if defined _pc %_cscript% "!_work!\WiCodepage.vbs" %1 0
  if defined _xtrn (
  start /wait msiexec.exe /a %1 /quiet SHORTFILENAMES=1 TARGETDIR="!cd!\Z" /p "!_ptc!"
  xcopy /CIDERY "!cd!\Z\*" "!cd!\" >nul
  rd /s /q "\\?\!cd!\Z\"
  ) else (
  start /wait msiexec.exe /a %1 /quiet SHORTFILENAMES=1 TARGETDIR="!cd!" /p "!_ptc!"
  )
  if defined _pc %_cscript% "!_work!\WiCodepage.vbs" %1 !_cp!
)
exit /b

:AddModdedFiles
echo.
echo - Replace original files with patched files
for /r %%# in (*WW.msi OMUI*.msi PMUI*.msi VisMUI*.msi) do (
pushd "%%~dp#"
call set "_ver="
if exist "osetup.dll" if not exist "osetup.lld" (
  copy /y osetup.dll osetup.lld >nul
  copy /y "!_work!\%_bit%\osetup.dll" . >nul
  copy /y "!_work!\%_bit%\setup.exe" .\setup.exe >nul
  )
if exist "psetup.dll" if not exist "psetup.lld" (
  copy /y psetup.dll psetup.lld >nul
  copy /y "!_work!\%_bit%\psetup.dll" . >nul
  copy /y "!_work!\%_bit%\osetup.dll" . >nul
  copy /y "!_work!\%_bit%\setup.exe" .\setup.exe >nul
  )
if %_ssm% equ 1 for /r %%A in (mso.dll*) do (
  copy /y "!_work!\%_bit%\mso.dll" "%%A" >nul
  set "_ver=1"
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
if exist "mso.dll" if not exist "mso.lld" del /f /q mso.dll
popd
)
if exist "setup.exe" (
copy /y setup.exe setup.xex >nul
copy /y "!_work!\%_bit%\install.exe" .\setup.exe >nul
)
call :Unattend

:PatchesCA
if %_ssv% neq 1 goto :MakeDDF
echo.
echo - Insert PatchAdd vbscript into MSIs
for /r %%# in (IME*.msi *MUI*.msi *Proof.msi) do if /i not %%~n#==RosebudMUI (
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
for %%A in (IME32 IME64 Proof) do if exist "%%A.msi" (
echo ProofKit.WW\Proof.%%#\%%A.msi
call :doDDF %%A.msi
)
popd
)

for /f "tokens=2 delims=." %%I in ('dir /b /ad Proofing.* 2^>nul') do for /f "tokens=2 delims=." %%# in ('dir /b /ad Proofing.%%I\ 2^>nul') do (
pushd "Proofing.%%I\Proof.%%#"
for %%A in (IME32 IME64 Proof) do if exist "%%A.msi" (
echo %%I\Proof.%%#\%%A.msi
call :doDDF %%A.msi
)
popd
)

for /r %%# in (*MUI*.msi *Proofing.msi) do (
pushd "%%~dp#"
call set "_d="
set "_d=!cd:~-5!"
if /i "!_d!"=="tn-cs" set "_d=sr-latn-cs"
echo !_d!\%%~nx# |findstr /i /v Proofing\.msi
call :doDDF %%~nx#
popd
)

for /r %%# in (*WW.msi) do (
pushd "%%~dp#"
echo %%~nx#
call :doDDF %%~nx#
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
echo ProofKit.WW\Proof.%%#\%%~nA.cab
makecab.exe /V0 /D CabinetNameTemplate=%%~nA.cab /D CompressionType=%_cmp% /F "!_work!\directive.txt" /F %%~nxA >nul
)
popd
)

for /f "tokens=2 delims=." %%I in ('dir /b /ad Proofing.* 2^>nul') do for /f "tokens=2 delims=." %%# in ('dir /b /ad Proofing.%%I\ 2^>nul') do (
pushd "Proofing.%%I\Proof.%%#"
for %%A in (*.ddf) do if not exist "%%~nA.cab" (
echo %%I\Proof.%%#\%%~nA.cab
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
for /r %%# in (IME*.msi *MUI*.msi *Proof.msi *Proofing.msi *WW.msi) do (
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
if %1 equ 2 goto :MspUpd

:MspSvc
set "svcww="
set "IMEWW=imeww"
set "Office32WW=office32ww"
set "Office64WW=office64ww"
set "AccessWW=mainww"
set "ExcelWW=mainww"
set "GrooveWW=mainww"
set "InfoPathWW=mainww"
set "OneNoteWW=mainww"
set "OutlookWW=mainww"
set "PowerPointWW=mainww"
set "PublisherWW=mainww"
set "WordWW=mainww"
set "PrjProWW=projectww"
set "PrjStdWW=projectww"
set "VisProWW=visioww"
set "VisStdWW=visioww"
set "SharePointDesignerWW=sharepointdesignerww"
set "WebDesignerWW=sharepointdesignerww"
set "InterConnectWW=interconnectww"
set "StandardWW=mainww"
set "ProPlusWW=mainww"
set "EnterpriseWW=mainww"
set "UltimateWW=mainww"
set "ProWW=mainww"
set "SmallBusinessWW=mainww"
set "BasicWW=mainww"
set "PersonalrWW=mainww"
set "HomeStudentrWW=mainww"
set "ProHybridrWW=mainww"
for %%A in (
Access Excel Groove InfoPath OneNote Outlook PowerPoint Publisher Word 
PrjPro PrjStd VisPro VisStd 
Standard SmallBusiness Pro ProPlus Enterprise Ultimate Basic 
) do (
set "%%ArWW=!%%AWW!"
)

pushd "!_svc!"
for %%A in (
office32ww office64ww mainww
projectww visioww sharepointdesignerww imeww interconnectww
) do (
for /f "tokens=* delims=" %%# in ('dir /b /od *%%Asp3*.msp 2^>nul') do set "svc%%A=%%#"
)
for /f "tokens=* delims=" %%# in ('dir /b /od *mainwwsp3*.msp 2^>nul') do set "svcww=!_svc!\%%#;!svcww!"
for %%A in (
ar-sa bg-bg cs-cz da-dk de-de el-gr en-us es-es et-ee fi-fi 
fr-fr he-il hi-in hr-hr hu-hu it-it ja-jp kk-kz ko-kr lt-lt 
lv-lv nb-no nl-nl pl-pl pt-br pt-pt ro-ro ru-ru sk-sk sl-si 
sv-se th-th tr-tr uk-ua zh-cn zh-hk zh-tw sr-latn-cs 
) do (
set "%%A_svcmui="
for /f "tokens=* delims=" %%# in ('dir /b /on *muisp3-%%A*.msp 2^>nul') do set "%%A_svcmui=!_svc!\%%#;!%%A_svcmui!"
for %%I in (
Access Excel InfoPath OneNote Outlook PowerPoint Publisher Word Office Project Visio 
) do (
set "%%A_%%IMUIhlp="
for /f "tokens=* delims=" %%# in ('dir /b /od "!_upd!\*%%Ihelp-%%A*.msp" 2^>nul') do set "%%A_%%IMUIhlp=!_upd!\%%#"
)
for /f "tokens=* delims=" %%# in ('dir /b /od "!_upd!\*ribbonhelp-%%A*.msp" 2^>nul') do set "%%A_OfficeMUIhlp=!_upd!\%%#;!%%A_OfficeMUIhlp!"
for /f "tokens=* delims=" %%# in ('dir /b /od "!_upd!\*spdhelp-%%A*.msp" 2^>nul') do set "%%A_SharePointDesignerMUIhlp=!_upd!\%%#"
)
popd

for /f "tokens=* delims=" %%# in ('dir /b /od "!_upd!\*targetdir*.msp" 2^>nul') do set "svcdirtarget=!_upd!\%%#"

for /f "tokens=2 delims=." %%# in ('dir /b /ad ProofKit.WW\ 2^>nul') do call :MspPrf %%#
for /f "tokens=2 delims=." %%I in ('dir /b /ad Proofing.* 2^>nul') do for /f "tokens=2 delims=." %%# in ('dir /b /ad Proofing.%%I\ 2^>nul') do call :MspPrf %%#
goto :eof

:MspUpd
set "updww="
set "OfficeMUI=conv eqnedt32 mstore"
set "SharePointDesignerMUI=conv"
set "WebDesignerMUI=conv"
set "OutlookMUI=outlook"
set "OMUI=osetup"
set "PMUI=osetup"
set "VisMUI=osetup"

pushd "!_upd!"
for %%A in (
ar-sa bg-bg cs-cz da-dk de-de el-gr en-us es-es et-ee fi-fi 
fr-fr he-il hi-in hr-hr hu-hu it-it ja-jp kk-kz ko-kr lt-lt 
lv-lv nb-no nl-nl pl-pl pt-br pt-pt ro-ro ru-ru sk-sk sl-si 
sv-se th-th tr-tr uk-ua zh-cn zh-hk zh-tw sr-latn-cs 
) do (
for %%I in (
conv eqnedt32 outlook
) do (
for /f "tokens=* delims=" %%# in ('dir /b /od *%%I-%%A*.msp 2^>nul') do set "%%A_upd%%I=%%#"
)
for %%I in (
mstore osetup
) do (
for /f "tokens=* delims=" %%# in ('dir /b /od *%%I-x-none*.msp 2^>nul') do set "%%A_upd%%I=%%#"
)
)
for /f "tokens=* delims=" %%# in ('dir /b /on *-x-none*.msp 2^>nul ^|findstr /i /v niceclass') do set "updww=!_upd!\%%#;!updww!"
for /f "tokens=* delims=" %%# in ('dir /b /od *niceclass-x-none*.msp 2^>nul') do set "updniceclass=!_upd!\%%#"
for /f "tokens=* delims=" %%# in ('dir /b /od *msxml5-x-none*.msp 2^>nul') do set "updmsxml5=!_upd!\%%#"
popd

goto :eof

:MspPrf
set "_l=%1"
if /i "%_l%"=="ms" set "_l=ms-my"
if /i "%_l%"=="pt" set "_l=pt-pt"
if /i "%_l%"=="sr" set "_l=sr-latn-cs"
if exist "!_svc!\*proofsp3-%_l%*.msp" for /f "tokens=* delims=" %%A in ('dir /b /od "!_svc!\*proofsp3-%_l%*.msp" 2^>nul') do set "svcproof%1=%%A"
if exist "!_svc!\*ime32sp3-%_l%*.msp" for /f "tokens=* delims=" %%A in ('dir /b /od "!_svc!\*ime32sp3-%_l%*.msp" 2^>nul') do set "svcime32%1=%%A"
if exist "!_svc!\*ime64sp3-%_l%*.msp" for /f "tokens=* delims=" %%A in ('dir /b /od "!_svc!\*ime64sp3-%_l%*.msp" 2^>nul') do set "svcime64%1=%%A"
if exist "!_upd!\*proof-%_l%*.msp" for /f "tokens=* delims=" %%A in ('dir /b /od "!_upd!\*proof-%_l%*.msp" 2^>nul') do set "updproof%1=%%A"
if exist "!_upd!\*ime32-%_l%*.msp" for /f "tokens=* delims=" %%A in ('dir /b /od "!_upd!\*ime32-%_l%*.msp" 2^>nul') do set "updime32%1=%%A"
if exist "!_upd!\*ime64-%_l%*.msp" for /f "tokens=* delims=" %%A in ('dir /b /od "!_upd!\*ime64-%_l%*.msp" 2^>nul') do set "updime64%1=%%A"
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
