@setlocal DisableDelayedExpansion
@echo off
set "_work=%~dp0"
setlocal EnableDelayedExpansion
pushd "!_work!"
for /r %%# in (IME*.msi *MUI*.msi *Proof.msi *Proofing.msi *WW.msi) do (
set _offmsi=1
)
if not defined _offmsi (
echo ERROR: could not Office msi files
goto :TheEnd
)
for /r %%# in (IME*.msi *MUI*.msi *Proof.msi *Proofing.msi *WW.msi) do (
pushd "%%~dp#"
echo %%~nx#
move /y %%~n#.ism %%~nx# 1>nul 2>nul
for /f %%A in ('dir /b /a:-d *.lmx 2^>nul') do move /y %%~nxA %%~nA.xml >nul
for /f %%A in ('dir /b /a:-d *.bac 2^>nul') do move /y %%~nxA %%~nA.cab >nul
move /y psetup.lld psetup.dll 1>nul 2>nul
move /y osetup.lld osetup.dll 1>nul 2>nul
move /y ose.xex ose.exe 1>nul 2>nul
del /f /q "setup.exe" 2>nul
del /f /q "*.svc" 2>nul
del /f /q "*.upd" 2>nul
del /f /q "*.ddf" 2>nul
rd /s /q "\\?\!cd!\FILES\" 2>nul
rd /s /q "\\?\!cd!\GAC_MSIL\" 2>nul
rd /s /q "\\?\!cd!\PFiles\" 2>nul
rd /s /q "\\?\!cd!\PFiles32\" 2>nul
rd /s /q "\\?\!cd!\Program Files\" 2>nul
rd /s /q "\\?\!cd!\Program Files (x86)\" 2>nul
rd /s /q "\\?\!cd!\IDE\" 2>nul
rd /s /q "\\?\!cd!\COMMON\" 2>nul
rd /s /q "\\?\!cd!\GlobalAssemblyCache\" 2>nul
rd /s /q "\\?\!cd!\GLOBAL_1\" 2>nul
rd /s /q "\\?\!cd!\ALLUSE_1\" 2>nul
rd /s /q "\\?\!cd!\USERPR_1\" 2>nul
rd /s /q "\\?\!cd!\Windows\" 2>nul
rd /s /q "\\?\!cd!\Win\" 2>nul
rd /s /q "\\?\!cd!\swidtags\" 2>nul
rd /s /q "\\?\!cd!\System\" 2>nul
rd /s /q "\\?\!cd!\System64\" 2>nul
popd
)
move /y setup.xex setup.exe 1>nul 2>nul
move /y setup.lld setup.dll 1>nul 2>nul
if exist "Office64.WW\*.msi" (
for /r %%# in (*WW.msi) do if /i not %%~n#==Office64WW if /i not %%~n#==Office32WW (copy /y Office64.WW\* "%%~dp#" >nul)
rd /s /q "Office64.WW\"
) else if exist "Office32.WW\*.msi" (
for /r %%# in (*WW.msi) do if /i not %%~n#==Office64WW if /i not %%~n#==Office32WW (copy /y Office32.WW\* "%%~dp#" >nul)
rd /s /q "Office32.WW\"
)

:TheEnd
echo.
echo Press any key to exit.
pause >nul
goto :eof
