@setlocal DisableDelayedExpansion
@echo off
:: ### Unattended Options ###

:: language
:: https://docs.microsoft.com/en-us/deployedge/microsoft-edge-supported-languages
set "uLang="

:: channel: internal, canary, dev, beta, stable
set "uChannel="

:: installation level: system wide or current user
:: you must set one of them to 1
:: system level takes precedence if both are 1
:: system level require administrator privileges, otherwise it will be reverted to user
set uSystem=0
set uUser=0

:: ###################################################################
:: # NORMALLY THERE IS NO NEED TO CHANGE ANYTHING BELOW THIS COMMENT #
:: ###################################################################

set "_args=%*"
if not defined _args goto :NoProgArgs
if "%~1"=="" set "_args="&goto :NoProgArgs

set uSystem=1&set uUser=0
set sLang=0
for %%A in (%_args%) do (
if /i "%%A"=="/L" (set sLang=1
) else if /i "%%A"=="/Dev" (set uChannel=Dev
) else if /i "%%A"=="/Beta" (set uChannel=Beta
) else if /i "%%A"=="/Stable" (set uChannel=Stable
) else if /i "%%A"=="/Canary" (set uChannel=Canary
) else if /i "%%A"=="/Internal" (set uChannel=Internal
) else if /i "%%A"=="/CD" (set uChannel=Dev
) else if /i "%%A"=="/CB" (set uChannel=Beta
) else if /i "%%A"=="/CS" (set uChannel=Stable
) else if /i "%%A"=="/CC" (set uChannel=Canary
) else if /i "%%A"=="/CI" (set uChannel=Internal
) else if /i "%%A"=="/System" (set uSystem=1&set uUser=0
) else if /i "%%A"=="/User" (set uUser=1&set uSystem=0
) else if /i "%%A"=="/S" (set uSystem=1&set uUser=0
) else if /i "%%A"=="/U" (set uUser=1&set uSystem=0
) else (set "uLang=%%A")
)
if %sLang%==0 set uLang=

:NoProgArgs
set "SysPath=%SystemRoot%\System32"
if exist "%SystemRoot%\Sysnative\reg.exe" (set "SysPath=%SystemRoot%\Sysnative")
set "Path=%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
set "_Null=1>nul 2>nul"

reg query HKU\S-1-5-19 %_Null% || (if %uSystem%==1 set uUser=1&set uSystem=0)
if %uSystem%==0 if %uUser%==0 set uLang=
if not defined uChannel set uChannel=Stable
if /i %uChannel%==Canary set uUser=1&set uSystem=0
if not defined uLang set uSystem=0&set uUser=0&set uChannel=

set "_err===== ERROR ===="
set "_updu=%LocalAppData%\Microsoft\EdgeUpdate"
set "_updm=%ProgramFiles(x86)%\Microsoft\EdgeUpdate"
set "_regm=HKLM\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate"
set "_regu=HKCU\SOFTWARE\Microsoft\EdgeUpdate"
set "xOS=%PROCESSOR_ARCHITECTURE%"
if /i %PROCESSOR_ARCHITECTURE%==x86 (if defined PROCESSOR_ARCHITEW6432 (
  set "xOS=%PROCESSOR_ARCHITEW6432%"
  ) else (
  set "_updm=%ProgramFiles%\Microsoft\EdgeUpdate"
  set "_regm=HKLM\SOFTWARE\Microsoft\EdgeUpdate"
  )
)
if /i %xOS%==AMD64 set "xOS=x64"
set "_work=%~dp0"
set "_work=%_work:~0,-1%"
setlocal EnableDelayedExpansion
pushd "!_work!"
for %%# in (a,r,m,x) do (
set xOS=!xOS:%%#=%%#!
)
set "_stp="
set "_edg86="
set "_edg64="
if exist "MicrosoftEdge*Setup*.exe" for /f "tokens=* delims=" %%# in ('dir /b MicrosoftEdge*Setup*.exe') do set "_stp=%%#"
if exist "MicrosoftEdge_X86_*.exe" for /f "tokens=* delims=" %%# in ('dir /b MicrosoftEdge_X86_*.exe') do set "_edg86=%%#"
if /i not %xOS%==x86 if exist "MicrosoftEdge_%xOS%_*.exe" for /f "tokens=* delims=" %%# in ('dir /b MicrosoftEdge_%xOS%_*.exe') do set "_edg64=%%#"

if not defined _stp (
echo %_err%
echo Microsoft Edge Update Setup is not detected.
goto :TheEnd
)
if /i not %xOS%==x86 if not defined _edg86 if not defined _edg64 (
echo %_err%
echo Microsoft Edge Offline Installer is not detected.
goto :TheEnd
)
if /i %xOS%==x86 if not defined _edg86 (
echo %_err%
echo Microsoft Edge Offline Installer is not detected.
goto :TheEnd
)

set /a cc=0
if not defined uLang for %%A in (
en ar bg cs da de el es et fi 
fr he hr hu it ja ko lt lv nb 
nl pl ro ru sk sl sv th tr uk 
af am sw fa az kk ky tk ca eu 
hi gu pa ta ur bn bs be ka nn 
id ms fil vi lb mt is ga gd mi 
en-gb fr-ca es-mx pt-br pt-pt zh-cn zh-tw sr-latn-rs sr-cyrl-rs sr-cyrl-ba
) do (
set /a cc+=1
set _lng!cc!=%%A
)
set /a cc=0
for %%A in (
56EB18F8-B008-4CBD-B6D2-8C97FE7E9062
2CD8A007-E189-409D-A2C8-9AF4EF3C72AA
0D50BFEC-CD6A-4F9A-964C-C7416E3ACB10
65C35B14-6C1D-4122-AC46-7148CC9D6497
BE59E8FD-089A-411B-A3B0-051D9E417818
) do (
set /a cc+=1
set _gud!cc!=%%A
)
set /a cc=0
for %%A in (
Stable Beta Dev Canary Internal
) do (
set /a cc+=1
set _chn!cc!=%%A
)
set "line=============================================================="

echo>filever.vbs Set objFSO = CreateObject^("Scripting.FileSystemObject"^) : Wscript.Echo objFSO.GetFileVersion^(WScript.arguments^(0^)^)
if defined _edg86 (
for /f "skip=1 tokens=* delims=" %%# in ('certutil -hashfile %_edg86% SHA256^|findstr /i /v CertUtil') do set "_hsh86=%%#"
for /f "tokens=* delims=" %%# in ('dir /b %_edg86%') do set "_sze86=%%~z#"
for /f "tokens=* delims=" %%# in ('cscript //nologo filever.vbs "!_work!\%_edg86%"') do set "_ver86=%%#"
)
if defined _edg64 (
for /f "skip=1 tokens=* delims=" %%# in ('certutil -hashfile %_edg64% SHA256^|findstr /i /v CertUtil') do set "_hsh64=%%#"
for /f "tokens=* delims=" %%# in ('dir /b %_edg64%') do set "_sze64=%%~z#"
for /f "tokens=* delims=" %%# in ('cscript //nologo filever.vbs "!_work!\%_edg64%"') do set "_ver64=%%#"
)
if exist filever.vbs del /f /q filever.vbs

if defined uChannel (
set "_chan=%uChannel%"
for /L %%# in (1,1,4) do (if /i !uChannel!==!_chn%%#! set "_guid=!_gud%%#!")
)

if defined uLang (
set "_lang=%uLang%"
set "_ntag="
if /i not !_chan!==Stable set "_ntag=%%20%_chan%"
if %uSystem%==1 (
set "_levl= --system-level"
set "_admn=true"
set "_updt=!_updm!"
set "_regk=%_regm%"
set "_rtag= /machine"
) else (
set "_levl="
set "_admn=false"
set "_updt=!_updu!"
set "_regk=%_regu%"
set "_rtag="
)
)

if /i %xOS%==x86 (
set "_arch=%xOS%"
set "_hash=%_hsh86: =%"
set "_size=%_sze86%"
set "_vern=%_ver86%"
set "_edge=%_edg86%"
if defined uLang goto :DoInstall
goto :M_Chan
)
if defined _edg64 if defined _edg86 if not defined uLang goto :M_Arch
if defined _edg64 (
set "_arch=%xOS%"
set "_hash=%_hsh64: =%"
set "_size=%_sze64%"
set "_vern=%_ver64%"
set "_edge=%_edg64%"
) else (
set "_arch=x86"
set "_hash=%_hsh86: =%"
set "_size=%_sze86%"
set "_vern=%_ver86%"
set "_edge=%_edg86%"
)
if defined uLang goto :DoInstall
goto :M_Chan

:M_Arch
@cls
title ^>Choose Architecture^<
set inpt=
set verified=0
echo %line%
echo.
echo. 1. [%xOS%] / %_edg64%
echo. 2. [x86] / %_edg86%
echo.
echo %line%
set /p inpt= ^> Enter Installer option number, and press "Enter": 
if "%inpt%"=="" goto :eof
for /l %%i in (1,1,2) do (if %inpt%==%%i set verified=1)
if %verified%==0 goto :M_Arch
if %inpt%==1 (
set "_arch=%xOS%"
set "_hash=%_hsh64: =%"
set "_size=%_sze64%"
set "_vern=%_ver64%"
set "_edge=%_edg64%"
) else (
set "_arch=x86"
set "_hash=%_hsh86: =%"
set "_size=%_sze86%"
set "_vern=%_ver86%"
set "_edge=%_edg86%"
)

:M_Chan
@cls
title ^>Choose Channel^<
set inpt=
set verified=0
echo %line%
echo Installer: %_edge%
echo Arch     : %_arch%
echo %line%
echo.
echo. 1. Stable
echo. 2. Beta
echo. 3. Dev
echo. 4. Canary
echo. 5. Internal
echo.
echo %line%
set /p inpt= ^> Enter Channel option number, and press "Enter": 
if "%inpt%"=="" goto :eof
for /l %%i in (1,1,5) do (if %inpt%==%%i set verified=1)
if %verified%==0 goto :M_Chan
set "_guid=!_gud%inpt%!"
set "_chan=!_chn%inpt%!"
set "_ntag="
if /i not %_chan%==Stable set "_ntag=%%20%_chan%"

:M_Lang
@cls
title ^>Choose Language^<
set inpt=
set verified=0
echo %line%
echo Installer: %_edge%
echo Arch     : %_arch%
echo Channel  : %_chan%
echo Version  : %_vern%
echo %line%
echo.
echo.  1. en   11. fr   21. nl   31. af   41. hi   51. id   61. en-GB
echo.  2. ar   12. he   22. pl   32. am   42. gu   52. ms   62. fr-CA
echo.  3. bg   13. hr   23. ro   33. sw   43. pa   53. fil  63. es-MX
echo.  4. cs   14. hu   24. ru   34. fa   44. ta   54. vi   64. pt-BR
echo.  5. da   15. it   25. sk   35. az   45. ur   55. lb   65. pt-PT
echo.  6. de   16. ja   26. sl   36. kk   46. bn   56. mt   66. zh-CN
echo.  7. el   17. ko   27. sv   37. ky   47. bs   57. is   67. zh-TW
echo.  8. es   18. lt   28. th   38. tk   48. be   58. ga   68. sr-Latn-RS
echo.  9. et   19. lv   29. tr   39. ca   49. ka   59. gd   69. sr-Cyrl-RS
echo. 10. fi   20. nb   30. uk   40. eu   50. nn   60. mi   70. sr-Cyrl-BA
echo.
echo %line%
set /p inpt= ^> Enter Language option number, and press "Enter": 
if "%inpt%"=="" goto :eof
for /l %%i in (1,1,70) do (if %inpt%==%%i set verified=1)
if %verified%==0 goto :M_Lang
set "_lang=!_lng%inpt%!"

set "_lvel=Current User"
set "_levl="
set "_admn=false"
set "_updt=!_updu!"
set "_regk=%_regu%"
set "_rtag="
if /i %_chan%==Canary goto :M_Setup
reg query HKU\S-1-5-19 %_Null% || goto :M_Setup

:M_Level
@cls
title ^>Choose Installation Type^<
set inpt=
set verified=0
echo %line%
echo Installer: %_edge%
echo Arch     : %_arch%
echo Channel  : %_chan%
echo Version  : %_vern%
echo Language : %_lang%
echo %line%
echo.
echo. 1. System Level [ALL Users]
echo. 2. User Level   [Current User]
echo.
echo %line%
set /p inpt= ^> Enter Installation option number, and press "Enter": 
if "%inpt%"=="" goto :eof
for /l %%i in (1,1,2) do (if %inpt%==%%i set verified=1)
if %verified%==0 goto :M_Level
if %inpt%==1 (
set "_lvel=ALL Users"
set "_levl= --system-level"
set "_admn=true"
set "_updt=!_updm!"
set "_regk=%_regm%"
set "_rtag= /machine"
) else (
set "_lvel=Current User"
set "_levl="
set "_admn=false"
set "_updt=!_updu!"
set "_regk=%_regu%"
set "_rtag="
)

:M_Setup
@cls
title ^>MS Edge Offline Installer^<
set inpt=
set verified=0
echo %line%
echo Installer: %_edge%
echo Arch     : %_arch%
echo Channel  : %_chan%
echo Version  : %_vern%
echo Language : %_lang%
echo Level    : %_lvel%
echo %line%
echo.
echo. 1. Start Installation
echo. 2. Exit
echo.
echo %line%
echo.
set /p inpt= ^> Enter option number, and press "Enter": 
if "%inpt%"=="" goto :eof
for /l %%i in (1,1,2) do (if %inpt%==%%i set verified=1)
if %verified%==0 goto :M_Setup
if %inpt%==2 goto :eof

@cls
echo.
echo %line%
echo Running installation... 
echo %line%
echo.

:DoInstall
for %%# in (s,t,a,b,l,e,d,v,c,n,r,y,i) do (
set _chan=!_chan:%%#=%%#!
)

start "" /w %_stp% /recover%_rtag%
for /f %%# in ('dir /b /ad "!_updt!" ^| find "."') do set _etv=%%#
(
echo.^<?xml version="1.0" encoding="UTF-8"?^>
echo.^<response protocol="3.0"^>
echo.  ^<app appid="{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}" status="ok"^>
echo.    ^<updatecheck status="ok"^>
echo.      ^<manifest version="%_vern%"^>
echo.        ^<packages^>
echo.          ^<package name="%_edge%" hash_sha256="%_hash%" size="%_size%" required="true"/^>
echo.        ^</packages^>
echo.        ^<actions^>
echo.          ^<action event="install" run="%_edge%" arguments="--verbose-logging --do-not-launch-msedge --do-not-register-for-update-launch%_levl%" needsadmin="%_admn%"/^>
echo.        ^</actions^>
echo.       ^</manifest^>
echo.    ^</updatecheck^>
echo.  ^</app^>
echo.  ^<app appid="{2CD8A007-E189-409D-A2C8-9AF4EF3C72AA}" status="ok"^>
echo.    ^<updatecheck status="ok"^>
echo.      ^<manifest version="%_vern%"^>
echo.        ^<packages^>
echo.          ^<package name="%_edge%" hash_sha256="%_hash%" size="%_size%" required="true"/^>
echo.        ^</packages^>
echo.        ^<actions^>
echo.          ^<action event="install" run="%_edge%" arguments="--msedge-beta --verbose-logging --do-not-launch-msedge --do-not-register-for-update-launch%_levl%" needsadmin="%_admn%"/^>
echo.        ^</actions^>
echo.       ^</manifest^>
echo.    ^</updatecheck^>
echo.  ^</app^>
echo.  ^<app appid="{0D50BFEC-CD6A-4F9A-964C-C7416E3ACB10}" status="ok"^>
echo.    ^<updatecheck status="ok"^>
echo.      ^<manifest version="%_vern%"^>
echo.        ^<packages^>
echo.          ^<package name="%_edge%" hash_sha256="%_hash%" size="%_size%" required="true"/^>
echo.        ^</packages^>
echo.        ^<actions^>
echo.          ^<action event="install" run="%_edge%" arguments="--msedge-dev --verbose-logging --do-not-launch-msedge --do-not-register-for-update-launch%_levl%" needsadmin="%_admn%"/^>
echo.        ^</actions^>
echo.       ^</manifest^>
echo.    ^</updatecheck^>
echo.  ^</app^>
echo.  ^<app appid="{65C35B14-6C1D-4122-AC46-7148CC9D6497}" status="ok"^>
echo.    ^<updatecheck status="ok"^>
echo.      ^<manifest version="%_vern%"^>
echo.        ^<packages^>
echo.          ^<package name="%_edge%" hash_sha256="%_hash%" size="%_size%" required="true"/^>
echo.        ^</packages^>
echo.        ^<actions^>
echo.          ^<action event="install" run="%_edge%" arguments="--msedge-sxs --verbose-logging --do-not-launch-msedge --do-not-register-for-update-launch" needsadmin="false"/^>
echo.        ^</actions^>
echo.       ^</manifest^>
echo.    ^</updatecheck^>
echo.  ^</app^>
echo.  ^<app appid="{BE59E8FD-089A-411B-A3B0-051D9E417818}" status="ok"^>
echo.    ^<updatecheck status="ok"^>
echo.      ^<manifest version="%_vern%"^>
echo.        ^<packages^>
echo.          ^<package name="%_edge%" hash_sha256="%_hash%" size="%_size%" required="true"/^>
echo.        ^</packages^>
echo.        ^<actions^>
echo.          ^<action event="install" run="%_edge%" arguments="--msedge-internal --verbose-logging --do-not-launch-msedge --do-not-register-for-update-launch%_levl%" needsadmin="%_admn%"/^>
echo.        ^</actions^>
echo.       ^</manifest^>
echo.    ^</updatecheck^>
echo.  ^</app^>
echo.^</response^>
)>"!_updt!\%_etv%\OfflineManifest.gup"
%_Null% copy /y "%_edge%" "!_updt!\%_etv%\%_edge%.{%_guid%}"
%_Null% reg add "%_regk%\Clients\{%_guid%}" /f /v lang /d %_lang%
%_Null% reg add "%_regk%\ClientState\{%_guid%}" /f /v lang /d %_lang%
start "" /w "!_updt!\MicrosoftEdgeUpdate.exe" /install "appguid={%_guid%}&appname=Microsoft%%20Edge%_ntag%&needsadmin=%_admn%&usagestats=0&ap=%_chan%-arch_%_arch%-full&lang=%_lang%" /silent /enterprise /installsource offline
%_Null% del /f /q "!_updt!\%_etv%\OfflineManifest.gup"
%_Null% del /f /q "!_updt!\%_etv%\%_edge%.{%_guid%}"
if defined uLang goto :eof
echo Finished.

:TheEnd
if defined uLang goto :eof
echo.
echo Press any key to exit.
pause >nul
goto :eof
