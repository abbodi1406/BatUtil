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

set _vrn=14.0.7270.1000
set _vrn=14.0.7015.1000

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
for %%# in (install.exe osetup.dll psetup.dll setup.exe ose.exe) do (
if not exist "x64\%%#" (set "msg=ERROR: required file _bin\x64\%%# is missing"&goto :TheEnd)
if not exist "x86\%%#" (set "msg=ERROR: required file _bin\x86\%%# is missing"&goto :TheEnd)
)
%_cscript% ZZZ.vbs
if %errorlevel% neq 48 goto :E_WSH
popd

title Office 2010 MSI Upsourcer %uvr%

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
if not exist "!_svc!\*clientsharedmui*.msp" if not exist "!_svc!\*proofing*.msp" set doSvpk=0
set doUpdt=1
if not exist "!_upd!\*-x-none*.msp" set doUpdt=0
if %doSvpk% equ 0 if %doUpdt% equ 0 (set "msg=ERROR: no msp files detected in either ServicePack or Updates locations"&goto :TheEnd)
if not exist "!_upd!\*ocfxca-x-none*.msp" (
echo.
echo Warning: Important update KB2553347 ocfxca-x-none.msp is not detected
)
if not exist "!_upd!\*rmaddlocal-x-none*.msp" (
echo.
echo Warning: recommended update KB2879953 rmaddlocal-x-none.msp is not detected
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

for /r %%# in (*MUI*.msi *Proofing.msi) do (
pushd "%%~dp#"
call :muisvc %%~nx#
popd
)

for /r %%# in (*WW.msi) do (
pushd "%%~dp#"
call set "_ptc="
if defined svcrmaddlocal set "_ptc=!svcrmaddlocal!"
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
if defined svcrmaddlocal (if defined updocfxca (set "_ptc=!svcrmaddlocal!;!_upd!\!updocfxca!") else (set "_ptc=!svcrmaddlocal!")) else if defined updocfxca (set "_ptc=!_upd!\!updocfxca!")
if defined updproof%3 (set "_ptc=!_svc!\!svcproof%3!;!_upd!\!updproof%3!;!_ptc!") else (set "_ptc=!_svc!\!svcproof%3!;!_ptc!")
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
if defined svcrmaddlocal (if defined updocfxca (set "_ptc=!svcrmaddlocal!;!_upd!\!updocfxca!") else (set "_ptc=!svcrmaddlocal!")) else if defined updocfxca (set "_ptc=!_upd!\!updocfxca!")
if defined updime%3 (set "_ptc=!_svc!\!svc%%A%3!;!_upd!\!updime%3!;!_ptc!") else (set "_ptc=!_svc!\!svc%%A%3!;!_ptc!")
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
set "_pc="
for /f "tokens=2 delims==" %%Q in ('%_cscript% "!_work!\WiCodepage.vbs" %1') do call set _cp=%%Q
if "%_cp%"=="65001" set "_pc=1"
call set "_ptc="
if defined svcrmaddlocal set "_ptc=!svcrmaddlocal!"
if defined %~n1 for %%A in (!%~n1!) do if defined %_d%_svc%%A (
  set "_ptc=!_svc!\!%_d%_svc%%A!;!_ptc!"
  )
if defined _ptc (
  echo %_d%\%1
  if defined _pc %_cscript% "!_work!\WiCodepage.vbs" %1 0
  start /wait msiexec.exe /a %1 /quiet SHORTFILENAMES=1 TARGETDIR="!cd!" PATCH="!_ptc!"
  if defined _pc %_cscript% "!_work!\WiCodepage.vbs" %1 !_cp!
  %_cscript% "!_work!\WiSumInf.vbs" %1 Words=1
)
exit /b

:AddUpdates
if %doUpdt% equ 0 goto :AddModdedFiles
echo.
echo - Slipstream Updates
echo.
call :MsiMsp 2

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
  if defined _xtrn (
  start /wait msiexec.exe /a %%~nx# /quiet SHORTFILENAMES=1 TARGETDIR="!cd!\Z" /p "!_ptc!"
  xcopy /CIDERY "!cd!\Z\*" "!cd!\" >nul
  rd /s /q "\\?\!cd!\Z\"
  ) else (
  start /wait msiexec.exe /a %%~nx# /quiet SHORTFILENAMES=1 TARGETDIR="!cd!" /p "!_ptc!"
  )
)
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
  copy /y "!_work!\%_bit%\psetup.dll" . >nul
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
if %_ssm% equ 1 for /r %%A in (mso.dll*) do (
  if /i %%~n#==Office32WW (copy /y "!_work!\x86\mso.dll" "%%A" >nul) else (copy /y "!_work!\%_bit%\mso.dll" "%%A" >nul)
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
for /r %%# in (IME*.msi *MUI*.msi *Proof.msi *Proofing.msi) do if /i not %%~n#==RosebudMUI (
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
for %%A in (
AccessMUISet Office64MUISet OfficeMUISet Proofing 
) do (
set "%%A="
)
for %%A in (
Office32 Office64 Office Rosebud 
Access Excel Groove InfoPath OneNote Outlook PowerPoint Publisher Word 
Project Visio SharePointDesigner O X P Vis 
) do (
set "%%AMUI="
)
for %%A in (
Office32 Office64 
Access Excel Groove InfoPath OneNote Outlook PowerPoint Publisher Word 
PrjPro PrjStd Visio SharePointDesigner 
Standard SmallBusBasics ProPlus SingleImage Pro Personal Essentials HomeStudent Consumer 
) do (
set "%%AWW="
set "%%ArWW="
)
if %1 equ 2 goto :MspUpd

:MspSvc
set "svcww="
set "IMEWW=imeww"
set "Office32MUI=clientshared32mui"
set "Office64MUISet=clientshared64mui"
set "Office64MUI=clientshared64mui"
set "OfficeMUISet=clientsharedmui"
set "OfficeMUI=clientsharedmui"
set "RosebudMUI=clientsharedmui"
set "AccessMUISet=officesuitemui"
set "AccessMUI=officesuitemui"
set "ExcelMUI=officesuitemui"
set "GrooveMUI=officesuitemui"
set "InfoPathMUI=officesuitemui"
set "OneNoteMUI=officesuitemui"
set "OutlookMUI=officesuitemui"
set "PowerPointMUI=officesuitemui"
set "PublisherMUI=officesuitemui"
set "WordMUI=officesuitemui"
set "ProjectMUI=projectmui"
set "VisioMUI=visiomui"
set "SharePointDesignerMUI=sharepointdesignermui"
set "XMUI=xmui"
set "OMUI=omui"
set "PMUI=pmui"
set "VisMUI=vismui"
set "ProofMUI=proofmui"
set "Proofing=proofing"
set "ProofKitWW=proofkitww"
set "Office32WW=clientshared32ww"
set "Office64WW=clientshared64ww"
set "AccessWW=officesuiteww"
set "ExcelWW=officesuiteww"
set "GrooveWW=officesuiteww"
set "InfoPathWW=officesuiteww"
set "OneNoteWW=officesuiteww"
set "OutlookWW=officesuiteww"
set "PowerPointWW=officesuiteww"
set "PublisherWW=officesuiteww"
set "WordWW=officesuiteww"
set "PrjProWW=projectww"
set "PrjStdWW=projectww"
set "VisProWW=visioww"
set "VisStdWW=visioww"
set "VisioWW=visioww"
set "SharePointDesignerWW=sharepointdesignerww"
set "StandardWW=officesuiteww"
set "SmallBusBasicsWW=officesuiteww"
set "ProPlusWW=officesuiteww"
set "SingleImageWW=officesuiteww"
set "ProWW=officesuiteww"
set "PersonalrWW=officesuiteww"
set "EssentialsrWW=officesuiteww"
set "HomeStudentrWW=officesuiteww"
set "ConsumerrWW=officesuiteww"
for %%A in (
Access Excel Groove InfoPath OneNote Outlook PowerPoint Publisher Word 
PrjPro PrjStd VisPro VisStd Visio 
Standard SmallBusBasics Pro ProPlus 
) do (
set "%%ArWW=!%%AWW!"
)

pushd "!_svc!"
for %%A in (
clientshared32ww clientshared64ww officesuiteww
projectww visioww sharepointdesignerww imeww proofkitww
) do (
for /f "tokens=* delims=" %%# in ('dir /b /od *%%A-x-none*.msp 2^>nul') do (set "svc%%A=%%#"&set "svcww=!_svc!\%%#;!svcww!")
)
for %%A in (
ar-sa bg-bg cs-cz da-dk de-de el-gr en-us es-es et-ee fi-fi 
fr-fr he-il hi-in hr-hr hu-hu it-it ja-jp kk-kz ko-kr lt-lt 
lv-lv nb-no nl-nl pl-pl pt-br pt-pt ro-ro ru-ru sk-sk sl-si 
sv-se th-th tr-tr uk-ua zh-cn zh-hk zh-tw sr-latn-cs 
) do (
for %%I in (
clientshared32mui clientshared64mui officesuitemui clientsharedmui
projectmui visiomui sharepointdesignermui proofing proofmui xmui pmui vismui
) do (
for /f "tokens=* delims=" %%# in ('dir /b /od *%%I-%%A*.msp 2^>nul') do set "%%A_svc%%I=%%#"
)
for /f "tokens=* delims=" %%# in ('dir /b /od *omui-%%A*.msp 2^>nul ^|findstr /i /v visiomui') do set "%%A_svcomui=%%#"
)
popd

for /f "tokens=* delims=" %%# in ('dir /b /od "!_upd!\*rmaddlocal-x-none*.msp" 2^>nul') do set "svcrmaddlocal=!_upd!\%%#"
for /f "tokens=* delims=" %%# in ('dir /b /od "!_upd!\*ocfxca-x-none*.msp" 2^>nul') do set "updocfxca=%%#"

for /f "tokens=2 delims=." %%# in ('dir /b /ad ProofKit.WW\ 2^>nul') do call :MspPrf %%#
for /f "tokens=2 delims=." %%I in ('dir /b /ad Proofing.* 2^>nul') do for /f "tokens=2 delims=." %%# in ('dir /b /ad Proofing.%%I\ 2^>nul') do call :MspPrf %%#
goto :eof

:MspUpd
set "_ppp=excel filterpack gfonts gkall graph ipeditor oartconv onenote osc otkruntimertl outexum outlook powerpoint publisher stslist wce word"
set "_all=ocfxca ace csi eurotool exppdf fm20 gfx ieawsdc lobi msaddndr mscomctlocx mshelp mso msocf msohevi msores msptls mstore mtextra oart offowc ogl oleo ose osetup ospp outlfltr owssupp riched20 usp10 vbe7 wec"
set "Office32MUI=ocfxca excelintl"
set "Office64MUI=ocfxca"
set "Office64MUISet=ocfxca"
set "OfficeMUISet=ocfxca"
set "OfficeMUI=ocfxca mstore ose eqnedt32 convintl excelintl msointl"
set "AccessMUI=ocfxca"
set "AccessMUISet=ocfxca"
set "ExcelMUI=ocfxca analys32 excelintl excel"
set "GrooveMUI=ocfxca"
set "InfoPathMUI=ocfxca targetdir"
set "OneNoteMUI=ocfxca onenoteintl"
set "OutlookMUI=ocfxca outlookintl wordintl"
set "PowerPointMUI=ocfxca powerpointintl excelintl"
set "PublisherMUI=ocfxca"
set "WordMUI=ocfxca wordintl excelintl"
set "ProjectMUI=ocfxca pjintl"
set "VisioMUI=ocfxca visiointl"
set "SharePointDesignerMUI=ocfxca convintl"
set "OMUI=ocfxca osetup ospp"
set "PMUI=ocfxca osetup ospp"
set "VisMUI=ocfxca osetup ospp"
set "XMUI=ocfxca"
set "ProofMUI=ocfxca"
set "Proofing=ocfxca"
set "ProofKitWW=ocfxca osetup ospp"
set "Office32WW=ocfxca access csi excel groove ieawsdc infopath mso msohevi msores ogl oleo onenote owssupp powerpoint project publisher visio wce wec word"
set "Office64WW=ocfxca csi filterpack groove ieawsdc infopath msohevi oleo onenote"
set "AccessWW=!_all! access accessolkaddin graph stslist"
set "ExcelWW=!_all! excel filterpack gkall graph ipeditor otkruntimertl stslist"
set "GrooveWW=!_all! groove ipeditor targetdir"
set "InfoPathWW=!_all! infopath ipeditor"
set "OneNoteWW=!_all! filterpack onenote wce"
set "OutlookWW=!_all! filterpack osc otkruntimertl outexum outlook word"
set "PowerPointWW=!_all! excel filterpack gfonts gkall graph ipeditor oartconv powerpoint stslist word"
set "PublisherWW=!_all! gfonts gkall oartconv publisher word"
set "WordWW=!_all! excel filterpack gfonts gkall graph ipeditor oartconv otkruntimertl stslist word"
set "PrjProWW=!_all! mscomct2 project stslist"
set "PrjStdWW=!_all! mscomct2 project"
set "VisioWW=!_all! filterpack stslist visio"
set "SharePointDesignerWW=!_all! gkall ipeditor oartconv spd stslist word"
set "StandardWW=!_all! !_ppp!"
set "SmallBusBasicsWW=!_all! !_ppp!"
set "ProPlusWW=!_all! !_ppp! access accessolkaddin visio vviewer groove infopath targetdir"
set "SingleImageWW=!_all! !_ppp! access accessolkaddin visio vviewer"
set "ProWW=!_all! !_ppp! access accessolkaddin visio vviewer"
set "PersonalrWW=!_all! !_ppp! vviewer"
set "EssentialsrWW=!_all! !_ppp!"
set "HomeStudentrWW=!_all! !_ppp!"
set "ConsumerrWW=!_all! !_ppp!"
for %%A in (
Access Excel Groove InfoPath OneNote Outlook PowerPoint Publisher Word 
PrjPro PrjStd VisPro VisStd Visio 
Standard SmallBusBasics Pro ProPlus 
) do (
set "%%ArWW=!%%AWW!"
)

pushd "!_upd!"
for %%A in (
access accessolkaddin ace csi 
eurotool excel exppdf filterpack fm20 
gfonts gfx gkall graph groove 
ieawsdc infopath ipeditor lobi 
msaddndr mscomct2 mscomctlocx mshelp 
mso msocf msohevi msores msptls mstore mtextra 
oart oartconv offowc ogl olc oleo 
onenote osc ose osetup ospp 
otkruntimertl outexum outlfltr outlook owssupp 
powerpoint project publisher riched20 spd stslist 
targetdir usp10 vbe7 visio vviewer wce wec word
) do (
for /f "tokens=* delims=" %%# in ('dir /b /od *%%A-x-none*.msp 2^>nul') do set "upd%%A=%%#"
)
for %%A in (
ar-sa bg-bg cs-cz da-dk de-de el-gr en-us es-es et-ee fi-fi 
fr-fr he-il hi-in hr-hr hu-hu it-it ja-jp kk-kz ko-kr lt-lt 
lv-lv nb-no nl-nl pl-pl pt-br pt-pt ro-ro ru-ru sk-sk sl-si 
sv-se th-th tr-tr uk-ua zh-cn zh-hk zh-tw sr-latn-cs 
) do (
for %%I in (
analys32 eqnedt32 convintl excelintl msointl onenoteintl 
outlookintl powerpointintl pjintl visiointl wordintl
) do (
for /f "tokens=* delims=" %%# in ('dir /b /od *%%I-%%A*.msp 2^>nul') do set "%%A_upd%%I=%%#"
)
for %%I in (
excel ocfxca mstore ose targetdir
) do (
for /f "tokens=* delims=" %%# in ('dir /b /od *%%I-x-none*.msp 2^>nul') do set "%%A_upd%%I=%%#"
)
)
popd

goto :eof

:MspPrf
set "_l=%1"
if /i "%_l%"=="ms" set "_l=ms-my"
if /i "%_l%"=="pt" set "_l=pt-pt"
if /i "%_l%"=="sr" set "_l=sr-latn-cs"
if exist "!_svc!\*proof-%_l%*.msp" for /f "tokens=* delims=" %%A in ('dir /b /od "!_svc!\*proof-%_l%*.msp" 2^>nul ^|findstr /i /v proofloc') do set "svcproof%1=%%A"
if exist "!_svc!\*ime32-%_l%*.msp" for /f "tokens=* delims=" %%A in ('dir /b /od "!_svc!\*ime32-%_l%*.msp" 2^>nul') do set "svcime32%1=%%A"
if exist "!_svc!\*ime64-%_l%*.msp" for /f "tokens=* delims=" %%A in ('dir /b /od "!_svc!\*ime64-%_l%*.msp" 2^>nul') do set "svcime64%1=%%A"
if exist "!_upd!\*proofloc*proof-%_l%*.msp" for /f "tokens=* delims=" %%A in ('dir /b /od "!_upd!\*proofloc*proof-%_l%*.msp" 2^>nul') do set "updproof%1=%%A"
if exist "!_upd!\*ime-%_l%*.msp" for /f "tokens=* delims=" %%A in ('dir /b /od "!_upd!\*ime-%_l%*.msp" 2^>nul') do set "updime%1=%%A"
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
