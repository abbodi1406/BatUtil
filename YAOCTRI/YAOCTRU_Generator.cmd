@setlocal DisableDelayedExpansion
@echo off
:: ### Unattended Options ###

:: language
:: run script without it to see supported langs
set "uLanguage="

:: channel
:: InsiderFast, MonthlyPreview, Monthly
:: MonthlyEnterprise, SemiAnnualPreview, SemiAnnual
:: DogfoodDevMain, MicrosoftElite
:: PerpetualVL2019, MicrosoftLTSC
:: PerpetualVL2021, MicrosoftLTSC2021
:: PerpetualVL2024, MicrosoftLTSC2024
set "uChannel="

:: level
:: Win7, Win81, Default (Win 11/10)
set "uLevel="

:: bitness
:: x86, x64, x86x64, x86arm64, x64arm64
set "uBitness="

:: type
:: Full, Lang, Proof
set "uType="

:: output
:: aria, wget, curl, text
set "uOutput="

:: ###################################################################
:: # NORMALLY THERE IS NO NEED TO CHANGE ANYTHING BELOW THIS COMMENT #
:: ###################################################################

set "_cmdf=%~f0"
if exist "%SystemRoot%\Sysnative\cmd.exe" (
setlocal EnableDelayedExpansion
start %SystemRoot%\Sysnative\cmd.exe /c ""!_cmdf!" "
exit /b
)
if exist "%SystemRoot%\SysArm32\cmd.exe" if /i %PROCESSOR_ARCHITECTURE%==AMD64 (
setlocal EnableDelayedExpansion
start %SystemRoot%\SysArm32\cmd.exe /c ""!_cmdf!" "
exit /b
)
set "SysPath=%SystemRoot%\System32"
if exist "%SystemRoot%\Sysnative\reg.exe" (set "SysPath=%SystemRoot%\Sysnative")
set "Path=%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
for /f "tokens=6 delims=[]. " %%# in ('ver') do set winbuild=%%#
set "_psc=$Tls12 = [Enum]::ToObject([System.Net.SecurityProtocolType], 3072); [System.Net.ServicePointManager]::SecurityProtocol = $Tls12;"
set "_temp=%temp%"
set "_work=%~dp0"
set "_work=%_work:~0,-1%"
setlocal EnableDelayedExpansion
pushd "!_work!"
set /a cc=0
for %%A in (en-US,ar-SA,bg-BG,cs-CZ,da-DK,de-DE,el-GR,es-ES,et-EE) do (
set /a cc+=1
set lang0!cc!=%%A
)
for %%A in (fi-FI,fr-FR,he-IL,hr-HR,hu-HU,it-IT,ja-JP,ko-KR,lt-LT,lv-LV,nb-NO,nl-NL,pl-PL,pt-BR,pt-PT,ro-RO,ru-RU,sk-SK,sl-SI,sr-Latn-RS,sv-SE,th-TH,tr-TR,uk-UA,zh-CN,zh-TW,hi-IN,id-ID,kk-KZ,MS-MY,vi-VN,en-GB,es-MX,fr-CA) do (
set /a cc+=1
set lang!cc!=%%A
)
set /a cc=0
for %%A in (1033,1025,1026,1029,1030,1031,1032,3082,1061) do (
set /a cc+=1
set lcid0!cc!=%%A
)
for %%A in (1035,1036,1037,1050,1038,1040,1041,1042,1063,1062,1044,1043,1045,1046,2070,1048,1049,1051,1060,9242,1053,1054,1055,1058,2052,1028,1081,1057,1087,1086,1066,2057,2058,3084) do (
set /a cc+=1
set lcid!cc!=%%A
)

set /a cc=0
for %%A in (
5440fd1f-7ecb-4221-8110-145efaa6372f
64256afe-f5d9-4f86-8936-8840a6a4f5be
492350f6-3a01-4f97-b9c0-c7c6ddf67d60
55336b82-a18d-4dd6-b5f6-9e5095c314a6
b8f9b850-328d-4355-9145-c59439a0c4cf
7ffbc6bf-bc32-4f92-8982-f9dd17fd3114
ea4a4090-de26-49d7-93c1-91bff9e53fc3
b61285dd-d9f7-41f2-9757-8f61cba4e9c8
f2e724c1-748f-4b47-8fb8-8e0d210e9208
1d2d2ea6-1680-4c56-ac58-a441c8c24ff9
5030841d-c919-4594-8d2d-84ae4f96e58e
86752282-5841-4120-ac80-db03ae6b5fdb
7983bac0-e531-40cf-be00-fd24fe66619c
c02d8fe6-5242-4da8-972f-82ee55e00671
) do (
set /a cc+=1
set ffn!cc!=%%A
)
set /a cc=0
for %%A in (
InsiderFast
MonthlyPreview
Monthly
MonthlyEnterprise
SemiAnnualPreview
SemiAnnual
DogfoodDevMain
MicrosoftElite
PerpetualVL2019
MicrosoftLTSC
PerpetualVL2021
MicrosoftLTSC2021
PerpetualVL2024
MicrosoftLTSC2024
) do (
set /a cc+=1
set chn!cc!=%%A
)

set /a cc=0
for %%A in (x86,x64,x86x64,x86arm64,x64arm64) do (
set /a cc+=1
set arc!cc!=%%A
)
set /a cc=0
for %%A in (32,64,00,32) do (
set /a cc+=1
set bit!cc!=%%A
)
set /a cc=0
for %%A in (aria, wget, curl, text) do (
set /a cc+=1
set ott!cc!=%%A
)

set _ext=1
set _a64=1
set _a86=1
set full=1
set proof=0
set "line=============================================================="

if not exist "YAOCTRU.ini" goto :proceed
findstr /i "YAOCTRU-Configuration" YAOCTRU.ini 1>nul 2>nul || goto :proceed
for %%# in (
uLanguage
uChannel
uLevel
uBitness
uType
uOutput
) do (
call :ReadINI %%#
)
goto :proceed

:ReadINI
findstr /i "%1 " YAOCTRU.ini >nul || goto :eof
for /f "tokens=1* delims==" %%A in ('findstr /i /c:"%1 " YAOCTRU.ini') do call set "%1=%%~B"
goto :eof

:proceed
if not defined uLanguage (
set "uChannel="
set "uLevel="
set "uBitness="
set "uType="
set "uOutput="
goto :CHANNEL
)

for /L %%# in (1,1,9) do if /i "!uLanguage!"=="!lang0%%#!" (set "lang=!lang0%%#!"&set "lcid=!lcid0%%#!")
for /L %%# in (10,1,43) do if /i "!uLanguage!"=="!lang%%#!" (set "lang=!lang%%#!"&set "lcid=!lcid%%#!")

set "chn=!chn3!"&set "ffn=!ffn3!"
if defined uChannel (
for /L %%# in (1,1,14) do if /i "!uChannel!"=="!chn%%#!" (set "chn=!chn%%#!"&set "ffn=!ffn%%#!")
)

set "arc=!arc3!"&set "bit=!bit3!"
if defined uBitness (
for /L %%# in (1,1,5) do if /i "!uBitness!"=="!arc%%#!" (set "arc=!arc%%#!"&set "bit=!bit%%#!")
)

if not defined uLevel set "uLevel=Default"

if defined uType (
if /i "!uType!"=="Lang" set full=0
if /i "!uType!"=="Proof" set proof=1
)

set otpt=1
if defined uOutput (
for /L %%# in (1,1,4) do if /i "!uOutput!"=="!ott%%#!" (set "otpt=%%#")
)
goto :MRO

:CHANNEL
cls
title ^>Choose Channel^<
set inpt=
set verified=0
echo %line%
echo.
echo. 1. Beta    / Insider Fast              ^|   Insiders::DevMain
echo. 2. Current / Monthly Preview           ^|   Insiders::CC
echo. 3. Current / Monthly                   ^| Production::CC
echo.
echo. 4. Monthly Enterprise                  ^| Production::MEC
echo. 5. Semi-Annual Preview                 ^|   Insiders::FRDC
echo. 6. Semi-Annual                         ^| Production::DC
echo.
echo. 7. DevMain Channel                     ^|    Dogfood::DevMain
echo. 8. Microsoft Elite                     ^|  Microsoft::DevMain
echo.
echo. 9. Perpetual2019 VL                    ^| Production::LTSC
echo 10. Microsoft2019 VL                    ^|  Microsoft::LTSC
echo.
echo 11. Perpetual2021 VL                    ^| Production::LTSC2021
echo 12. Microsoft2021 VL                    ^|  Microsoft::LTSC2021
echo.
echo 13. Perpetual2024 VL                    ^| Production::LTSC2024
echo 14. Microsoft2024 VL                    ^|  Microsoft::LTSC2024
echo.
echo %line%
set /p inpt= ^> Enter Channel option number, and press "Enter": 
if "%inpt%"=="" goto :eof
for /l %%i in (1,1,14) do (if %inpt%==%%i set verified=1)
if %verified%==0 goto :CHANNEL
set "ffn=!ffn%inpt%!"
set "chn=!chn%inpt%!"

:MRO
cls
title ^>Office Click-to-Run URL Generator^<
echo %line%
echo Channel : %chn%
echo %line%
echo.
echo %line%
echo Checking available version . . .
echo %line%
echo.
set "dms=https://mrodevicemgr.officeapps.live.com/mrodevicemgrsvc/api/v2/C2RReleaseData"
pushd "!_temp!"
if exist "C2R*.json" del /f /q "C2R*.json"
if /i "!uLevel!"=="Win7" (
set "ulvl=_W7"
1>nul 2>nul powershell -nop -c "%_psc% (New-Object Net.WebClient).DownloadFile('%dms%?audienceFFN=%ffn%&osver=Client|6.1','C2R0.json')"
) else if /i "!uLevel!"=="Win81" (
set "ulvl=_W81"
1>nul 2>nul powershell -nop -c "%_psc% (New-Object Net.WebClient).DownloadFile('%dms%?audienceFFN=%ffn%&osver=Client|6.3','C2R0.json')"
) else (
1>nul 2>nul powershell -nop -c "%_psc% (New-Object Net.WebClient).DownloadFile('%dms%?audienceFFN=%ffn%','C2R0.json'); (New-Object Net.WebClient).DownloadFile('%dms%?audienceFFN=%ffn%&osver=Client|6.1','C2R7.json'); (New-Object Net.WebClient).DownloadFile('%dms%?audienceFFN=%ffn%&osver=Client|6.3','C2R8.json')"
)
if /i "!uLevel!"=="Default" (
if exist "C2R7.json" del /f /q "C2R7.json"
if exist "C2R8.json" del /f /q "C2R8.json"
)
if not exist "C2R0.json" (
echo.
echo %line%
echo ERROR:
echo could not check available version online, possible reasons:
echo.
echo - internet connection not working
echo - Windows Powershell is disabled
echo - .NET Framework is not updated to support TLS 1.2 connection protocol
echo %line%
echo.
echo Press any key to exit.
pause >nul
goto :eof
)
for /f "tokens=2 delims=:, " %%G in ('findstr /i AvailableBuild C2R0.json') do set "vvv0=%%~G"
for /f "tokens=2-6 delims=:/ " %%G in ('findstr /i TimestampUtc C2R0.json') do set "utc0=%%I-%%~G-%%H %%J:%%K
if exist "C2R7.json" findstr /i /c:"Custom Win" C2R7.json 1>nul && (
for /f "tokens=2 delims=:, " %%G in ('findstr /i AvailableBuild C2R7.json') do set "vvv7=%%~G"
for /f "tokens=2-6 delims=:/ " %%G in ('findstr /i TimestampUtc C2R7.json') do set "utc7=%%I-%%~G-%%H %%J:%%K
)
if exist "C2R8.json" findstr /i /c:"Custom Win" C2R8.json 1>nul && (
for /f "tokens=2 delims=:, " %%G in ('findstr /i AvailableBuild C2R8.json') do set "vvv8=%%~G"
for /f "tokens=2-6 delims=:/ " %%G in ('findstr /i TimestampUtc C2R8.json') do set "utc8=%%I-%%~G-%%H %%J:%%K
)
if not defined vvv0 (
echo.
echo %line%
echo ERROR: could not detect available version
echo %line%
echo.
echo Press any key to exit.
pause >nul
goto :eof
)
if exist "C2R*.json" del /f /q "C2R*.json"
popd
for /L %%# in (9,1,10) do if /i "!chn!"=="!chn%%#!" set _a86=0
if %vvv0:~5,5% lss 14026 set _a64=0
if %vvv0:~5,5% lss 14326 set _ext=0
if defined uLevel set "vvv=%vvv0%"&set "utc=%utc0%"&set "inpt=%otpt%"&goto :POSTout
if not defined vvv7 if not defined vvv8 set "vvv=%vvv0%"&set "utc=%utc0%"&goto :BITNESS
:: set _a86=0&set _a64=0
if not defined vvv7 goto :skip7
if %vvv7:~5,5% gtr %vvv0:~5,5% set "vvv0=%vvv7%"&set "utc0=%utc7%"
if not defined vvv8 if "%vvv0%" equ "%vvv7%" set "vvv=%vvv0%"&set "utc=%utc0%"&goto :BITNESS
if defined vvv8 if "%vvv0%" equ "%vvv7%" if "%vvv0%" equ "%vvv8%" (set "vvv=%vvv0%"&set "utc=%utc0%"&goto :BITNESS)
:skip7
if not defined vvv8 goto :WIN
if %vvv8:~5,5% gtr %vvv0:~5,5% set "vvv0=%vvv8%"&set "utc0=%utc8%"

:WIN
cls
title ^>Choose Build Level^<
set inpt=
set verified=0
echo %line%
echo Channel : %chn%
echo %line%
echo.
echo Selected channel offer different builds per OS level:
echo.
if defined vvv8 (
echo. 1. build: %vvv0% [Windows 11/10]
echo. 2. build: %vvv8% [Windows 8.1]
) else (
echo. 1. build: %vvv0% [Windows 11/10/8.1]
)
echo. 3. build: %vvv7% [Windows 7]
echo %line%
echo.
set /p inpt= ^> Enter Build option number, and press "Enter": 
if "%inpt%"=="" goto :eof
if %inpt%==1 set verified=1
if defined vvv8 if %inpt%==2 set verified=1
if %inpt%==3 set verified=1
if %verified%==0 goto :WIN
if %inpt%==1 (set "vvv=%vvv0%"&set "utc=%utc0%"&set "ulvl=")
if defined vvv8 if %inpt%==2 (set "vvv=%vvv8%"&set "utc=%utc8%"&set "ulvl=_W81"&set _a86=0&set _a64=0)
if %inpt%==3 (set "vvv=%vvv7%"&set "utc=%utc7%"&set "ulvl=_W7"&set _a86=0&set _a64=0)

:BITNESS
cls
title ^>Choose Bitness^<
set inpt=
set verified=0
echo %line%
echo Channel : %chn%
echo Version : %vvv%
if defined utc echo Updated : %utc%
echo %line%
echo.
echo. 1. 32-bit [x86]
echo. 2. 64-bit [x64]
echo. 3. Dual   [x64 and x86]
if %_a86%==1 echo.
if %_a86%==1 echo. 4. Windows 11/10 ARM64 [x86 Emulation]
if %_a64%==1 echo. 5. Windows 11/10 ARM64 [x64 Emulation]
echo %line%
echo.
set /p inpt= ^> Enter Bitness option number, and press "Enter": 
if "%inpt%"=="" goto :eof
for /l %%i in (1,1,3) do (if %inpt%==%%i set verified=1)
if %_a86%==1 if %inpt%==4 set verified=1
if %_a64%==1 if %inpt%==5 set verified=1
if %verified%==0 goto :BITNESS
set "arc=!arc%inpt%!"
set "bit=!bit%inpt%!"

:LANGUAGE
cls
title ^>Choose Language^<
set inpt=
set verified=0
echo %line%
echo Channel : %chn%
echo Version : %vvv%
if defined utc echo Updated : %utc%
echo Bitness : %arc%
echo %line%
echo.
echo. 01 en-US         11 fr-FR         21 nl-NL         31 th-TH
echo. 02 ar-SA         12 he-IL         22 pl-PL         32 tr-TR
echo. 03 bg-BG         13 hr-HR         23 pt-BR         33 uk-UA
echo. 04 cs-CZ         14 hu-HU         24 pt-PT         34 zh-CN
echo. 05 da-DK         15 it-IT         25 ro-RO         35 zh-TW
echo. 06 de-DE         16 ja-JP         26 ru-RU         36 hi-IN
echo. 07 el-GR         17 ko-KR         27 sk-SK         37 id-ID
echo. 08 es-ES         18 lt-LT         28 sl-SI         38 kk-KZ
echo. 09 et-EE         19 lv-LV         29 sr-Latn-RS    39 MS-MY
echo. 10 fi-FI         20 nb-NO         30 sv-SE         40 vi-VN
if %_ext%==1 echo. 41 en-GB         42 es-MX         43 fr-CA
echo %line%
echo.
set /p inpt= ^> Enter Language option number, and press "Enter": 
if "%inpt%"=="" goto :eof
for /l %%i in (1,1,9) do (if %inpt%==%%i set verified=1)
for /l %%i in (1,1,9) do (if %inpt%==0%%i set verified=1)
for /l %%i in (10,1,40) do (if %inpt%==%%i set verified=1)
if %_ext%==1 for /l %%i in (41,1,43) do (if %inpt%==%%i set verified=1)
if %verified%==0 goto :LANGUAGE
for /l %%i in (1,1,9) do (if %inpt%==%%i set inpt=0%%i)
set "lang=!lang%inpt%!"
set "lcid=!lcid%inpt%!"

:PRODUCT
cls
title ^>Choose Download Type^<
set inpt=
set verified=0
echo %line%
echo Channel : %chn%
echo Version : %vvv%
if defined utc echo Updated : %utc%
echo Bitness : %arc%
echo Language: %lang%
echo %line%
echo.
echo. 1. Full Office Source
echo. 2. Language Pack
echo. 3. Proofing Tools
echo %line%
echo.
set /p inpt= ^> Enter Download option number, and press "Enter": 
if "%inpt%"=="" goto :eof
for /l %%i in (1,1,3) do (if %inpt%==%%i set verified=1)
if %verified%==0 goto :PRODUCT
if %inpt%==2 set full=0
if %inpt%==3 set proof=1

:PREout
cls
title ^>Choose Output Type^<
set inpt=
set verified=0
echo %line%
echo Channel : %chn%
echo Version : %vvv%
if defined utc echo Updated : %utc%
echo Bitness : %arc%
echo Language: %lang%
echo %line%
echo.
echo. 1. Aria2 script ^| https://aria2.github.io/
echo. 2. Wget script  ^| https://eternallybored.org/misc/wget/
echo. 3. cURL script  ^| https://curl.se/windows/
echo. 4. Text file
echo %line%
echo.
set /p inpt= ^> Enter Output option number, and press "Enter": 
if "%inpt%"=="" goto :eof
for /l %%i in (1,1,4) do (if %inpt%==%%i set verified=1)
if %verified%==0 goto :PREout

:POSTout
if /i %arc%==x64arm64 if %_a64%==0 if %_a86%==1 set "arc=x86arm64"
if /i %arc%==x64arm64 if %_a64%==0 if %_a86%==0 (
echo.
echo %line%
echo ERROR: ARM64 is not supported for selected channel and version
echo %line%
echo.
echo Press any key to exit.
pause >nul
goto :eof
)
set "url=https://officecdn.microsoft.com/db/%ffn%/Office/Data"
set "stp=https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/Office/Data"
set oar=%arc%
set "tag=%vvv%_%oar%_%lang%_%chn%%ulvl%"
if %full%==0 set "tag=%vvv%_%oar%_%lang%_LangPack_%chn%%ulvl%"
if %proof%==1 set "tag=%vvv%_%oar%_%lang%_Proofing_%chn%%ulvl%"
set dual=0
if /i %arc%==x86x64 (set "arc=x86"&set "bit=32"&set dual=1)
set chpe=0
if /i %arc%==x86arm64 (set "arc=x86"&set "bit=32"&set chpe=1)
set xarm=0
if /i %arc%==x64arm64 (set "arc=x64"&set "bit=64"&set xarm=1)
goto :OUTPUT%inpt%

:uProof
for %%a in (
sp%bit%%lcid%.cab
i%bit%0.cab
s%bit%0.cab
stream.%arc%.%lang%.proof.dat
) do (
call :EC1HO%inpt% %%a
)
if %xarm%==0 if %chpe%==0 if %dual%==0 if %arc%==x86 for %%a in (
i640.cab
) do (
call :EC1HO%inpt% %%a
)
if %dual%==1 (
call :EC2HO%inpt% v64_%vvv%.cab
)
if %dual%==1 for %%a in (
sp64%lcid%.cab
i640.cab
s640.cab
stream.x64.%lang%.proof.dat
) do (
call :EC1HO%inpt% %%a
)
set "stp=https://officecdn.microsoft.com/db/wsus"
call :EC3HO%inpt% Setup.exe
(
echo.^<Configuration^>
echo.  ^<Add SourcePath="" OfficeClientEdition="%bit%"^>
echo.    ^<Product ID="ProofingTools"^>
echo.      ^<Language ID="%lang%"/^>
echo.    ^</Product^>
echo.  ^</Add^>
echo.^</Configuration^>
)>"%vvv%_%arc%_%lang%_Proofing.xml"
if %dual%==1 (
echo.^<Configuration^>
echo.  ^<Add SourcePath="" OfficeClientEdition="64"^>
echo.    ^<Product ID="ProofingTools"^>
echo.      ^<Language ID="%lang%"/^>
echo.    ^</Product^>
echo.  ^</Add^>
echo.^</Configuration^>
)>"%vvv%_x64_%lang%_Proofing.xml"
if not %inpt%==4 (
echo :TXinfo:]
echo exit /b
)>>"%output%"
exit /b

:uAll
for %%a in (
i%bit%%lcid%.cab
s%bit%%lcid%.cab
i%bit%0.cab
s%bit%0.cab
stream.%arc%.%lang%.dat
) do (
call :EC1HO%inpt% %%a
)
if %chpe%==1 for %%a in (
sc320.cab
stream.x86.x-none.chpe.dat
) do (
call :EC1HO%inpt% %%a
)
if %xarm%==1 for %%a in (
sa640.cab
stream.x64.x-none.arm64x.dat
) do (
call :EC1HO%inpt% %%a
)
if %xarm%==0 if %chpe%==0 if %dual%==0 if %arc%==x86 for %%a in (
i64%lcid%.cab
i640.cab
) do (
call :EC1HO%inpt% %%a
)
if %full%==1 for %%a in (
stream.%arc%.x-none.dat
) do (
call :EC1HO%inpt% %%a
)
if %full%==0 (
call :EC3HO%inpt% SetupLanguagePack.%arc%.%lang%.exe
)
if %dual%==1 (
call :EC2HO%inpt% v64_%vvv%.cab
)
if %dual%==1 for %%a in (
i64%lcid%.cab
s64%lcid%.cab
i640.cab
s640.cab
stream.x64.%lang%.dat
) do (
call :EC1HO%inpt% %%a
)
if %dual%==1 if %full%==1 for %%a in (
stream.x64.x-none.dat
) do (
call :EC1HO%inpt% %%a
)
if %dual%==1 if %full%==0 (
call :EC3HO%inpt% SetupLanguagePack.x64.%lang%.exe
)
if not %inpt%==4 (
echo :TXinfo:]
echo exit /b
)>>"%output%"
exit /b

:EC1HO1
(echo %url%/%vvv%/%1&echo.  out=Office\Data\%vvv%\%1&echo.)>>"%output%"
exit /b

:EC2HO1
(echo %url%/%1&echo.  out=Office\Data\%1&echo.&echo %url%/%1&echo.  out=Office\Data\v64.cab&echo.)>>"%output%"
exit /b

:EC3HO1
(echo %stp%/%1&echo.  out=%1&echo.)>>"%output%"
exit /b

:EC1HO2
:EC1HO4
echo %url%/%vvv%/%1>>"%output%"
exit /b

:EC2HO2
:EC2HO4
echo %url%/%1>>"%output%"
exit /b

:EC3HO2
:EC3HO4
echo %stp%/%1>>"%output%"
exit /b

:EC1HO3
(echo url %url%/%vvv%/%1&echo -o %destDir%\Office\Data\%vvv%\%1)>>"%output%"
exit /b

:EC2HO3
(echo url %url%/%1&echo -o %destDir%\Office\Data\%1&echo url %url%/%1&echo -o %destDir%\Office\Data\v64.cab)>>"%output%"
exit /b

:EC3HO3
(echo url %stp%/%1&echo -o %destDir%\%1)>>"%output%"
exit /b

:OUTPUT1
cls
set "output=%tag%_aria2.bat"
(
echo @echo off
echo :: Limit the download speed, example: 1M, 500K "0 = unlimited"
echo set "speedLimit=0"
echo.
echo :: Set the number of parallel downloads
echo set "parallel=1"
echo.
echo set "_work=%%~dp0"
echo set "_work=%%_work:~0,-1%%"
echo set "_batn=%%~nx0"
echo setlocal EnableDelayedExpansion
echo pushd "^!_work^!"
echo set exist=0
echo if exist "aria2c.exe" set exist=1
echo for %%%%i in ^(aria2c.exe^) do @if not "%%%%~$PATH:i"=="" set exist=1
echo if %%exist%%==0 echo.^&echo Error: aria2c.exe is not detected^&echo.^&popd^&pause^&exit /b
echo set "destDir=C2R_%chn%"
echo set "uri=temp_aria2.txt"
echo echo Downloading...
echo echo.
echo if exist "%%uri%%" del /f /q "%%uri%%"
echo call :GenTXT TXinfo ^> "%%uri%%"
echo aria2c.exe -x16 -s16 -j%%parallel%% -c -R --max-overall-download-limit=%%speedLimit%% -d"%%destDir%%" -i"%%uri%%"
echo if exist "%%uri%%" del /f /q "%%uri%%"
if %proof%==1 (
echo if exist "%vvv%_x86_%lang%_Proofing.xml" move /y "%vvv%_x86_%lang%_Proofing.xml" "%%destDir%%\Office\Proofing_%lang%_x86.xml"
echo if exist "%vvv%_x64_%lang%_Proofing.xml" move /y "%vvv%_x64_%lang%_Proofing.xml" "%%destDir%%\Office\Proofing_%lang%_x64.xml"
)
echo echo.
echo echo Done.
echo echo Press any key to exit.
echo popd
echo pause ^>nul
echo exit /b
echo.
echo :GenTXT
echo set [=^&for /f "delims=:" %%%%s in ^('findstr /nbrc:":%%~1:\[" /c:":%%~1:\]" "^!_batn^!"'^) do if defined [ ^(set /a ]=%%%%s-3^) else set /a [=%%%%s-1
echo ^<"^!_batn^!" ^(^(for /l %%%%i in ^(0 1 %%[%%^) do set /p =^)^&for /l %%%%i in ^(%%[%% 1 %%]%%^) do ^(set txt=^&set /p txt=^&echo^(^^!txt^^!^)^) ^&exit/b
echo.
echo :TXinfo:[
)>"%output%"

(echo %url%/v%bit%_%vvv%.cab&echo.  out=Office\Data\v%bit%.cab&echo.)>>"%output%"
(echo %url%/v%bit%_%vvv%.cab&echo.  out=Office\Data\v%bit%_%vvv%.cab&echo.)>>"%output%"

if %proof%==1 (
call :uProof
goto :FIN
)
call :uAll
goto :FIN

:OUTPUT2
cls
set "output=%tag%_wget.bat"
(
echo @echo off
echo :: Limit the download speed, example: 1M, 500K "0 = unlimited"
echo set "speedLimit=0"
echo.
echo set "_work=%%~dp0"
echo set "_work=%%_work:~0,-1%%"
echo set "_batn=%%~nx0"
echo setlocal EnableDelayedExpansion
echo pushd "^!_work^!"
echo set exist=0
echo if exist "wget.exe" set exist=1
echo for %%%%i in ^(wget.exe^) do @if not "%%%%~$PATH:i"=="" set exist=1
echo if %%exist%%==0 echo.^&echo Error: wget.exe is not detected^&echo.^&popd^&pause^&exit /b
echo set "destDir=C2R_%chn%"
echo set "uri=temp_wget.txt"
echo echo Downloading...
echo echo.
echo if exist "%%uri%%" del /f /q "%%uri%%"
echo call :GenTXT TXinfo ^> "%%uri%%"
echo wget.exe --limit-rate=%%speedLimit%% --directory-prefix="%%destDir%%" --input-file="%%uri%%" --no-verbose --show-progress --progress=bar:force:noscroll --continue --retry-connrefused --tries=5 --ignore-case --force-directories --no-host-directories --cut-dirs=2
echo if exist "%%destDir%%\Office\Data\v32_*.cab" xcopy /cqry %%destDir%%\Office\Data\v32_*.cab %%destDir%%\Office\Data\v32.cab*
echo if exist "%%destDir%%\Office\Data\v64_*.cab" xcopy /cqry %%destDir%%\Office\Data\v64_*.cab %%destDir%%\Office\Data\v64.cab*
echo if exist "%%destDir%%\Office\Data\SetupLanguagePack*.exe" move /y "%%destDir%%\Office\Data\SetupLanguagePack*.exe" "%%destDir%%\"
echo if exist "%%uri%%" del /f /q "%%uri%%"
if %proof%==1 (
echo if exist "%vvv%_x86_%lang%_Proofing.xml" move /y "%vvv%_x86_%lang%_Proofing.xml" "%%destDir%%\Office\Proofing_%lang%_x86.xml"
echo if exist "%vvv%_x64_%lang%_Proofing.xml" move /y "%vvv%_x64_%lang%_Proofing.xml" "%%destDir%%\Office\Proofing_%lang%_x64.xml"
)
echo echo.
echo echo Done.
echo echo Press any key to exit.
echo popd
echo pause ^>nul
echo exit /b
echo.
echo :GenTXT
echo set [=^&for /f "delims=:" %%%%s in ^('findstr /nbrc:":%%~1:\[" /c:":%%~1:\]" "^!_batn^!"'^) do if defined [ ^(set /a ]=%%%%s-3^) else set /a [=%%%%s-1
echo ^<"^!_batn^!" ^(^(for /l %%%%i in ^(0 1 %%[%%^) do set /p =^)^&for /l %%%%i in ^(%%[%% 1 %%]%%^) do ^(set txt=^&set /p txt=^&echo^(^^!txt^^!^)^) ^&exit/b
echo.
echo :TXinfo:[
)>"%output%"

echo %url%/v%bit%_%vvv%.cab>>"%output%"

if %proof%==1 (
call :uProof
goto :FIN
)
call :uAll
goto :FIN

:OUTPUT3
cls
set "output=%tag%_curl.bat"
set "destDir=C2R_%chn%"
(
echo @echo off
echo :: Limit the download speed, example: 1M, 500K "empty means unlimited"
echo set speedLimit=
echo.
echo set "_work=%%~dp0"
echo set "_work=%%_work:~0,-1%%"
echo set "_batn=%%~nx0"
echo setlocal EnableDelayedExpansion
echo pushd "^!_work^!"
echo set exist=0
echo if exist "curl.exe" set exist=1
echo for %%%%i in ^(curl.exe^) do @if not "%%%%~$PATH:i"=="" set exist=1
echo if %%exist%%==0 echo.^&echo Error: curl.exe is not detected^&echo.^&popd^&pause^&exit /b
echo set "uri=temp_curl.txt"
echo if defined speedLimit set "speedLimit=--limit-rate %%speedLimit%%"
echo echo Downloading...
echo echo.
echo if exist "%%uri%%" del /f /q "%%uri%%"
echo call :GenTXT TXinfo ^> "%%uri%%"
echo curl.exe -q --create-dirs --retry 5 --retry-connrefused %%speedLimit%% -k -L -C - -K "%%uri%%"
echo if exist "%%uri%%" del /f /q "%%uri%%"
if %proof%==1 (
echo if exist "%vvv%_x86_%lang%_Proofing.xml" move /y "%vvv%_x86_%lang%_Proofing.xml" "%destDir%\Office\Proofing_%lang%_x86.xml"
echo if exist "%vvv%_x64_%lang%_Proofing.xml" move /y "%vvv%_x64_%lang%_Proofing.xml" "%destDir%\Office\Proofing_%lang%_x64.xml"
)
echo echo.
echo echo Done.
echo echo Press any key to exit.
echo popd
echo pause ^>nul
echo exit /b
echo.
echo :GenTXT
echo set [=^&for /f "delims=:" %%%%s in ^('findstr /nbrc:":%%~1:\[" /c:":%%~1:\]" "^!_batn^!"'^) do if defined [ ^(set /a ]=%%%%s-3^) else set /a [=%%%%s-1
echo ^<"^!_batn^!" ^(^(for /l %%%%i in ^(0 1 %%[%%^) do set /p =^)^&for /l %%%%i in ^(%%[%% 1 %%]%%^) do ^(set txt=^&set /p txt=^&echo^(^^!txt^^!^)^) ^&exit/b
echo.
echo :TXinfo:[
)>"%output%"

(echo url %url%/v%bit%_%vvv%.cab&echo -o %destDir%\Office\Data\v%bit%.cab)>>"%output%"
(echo url %url%/v%bit%_%vvv%.cab&echo -o %destDir%\Office\Data\v%bit%_%vvv%.cab)>>"%output%"

if %proof%==1 (
call :uProof
goto :FIN
)
call :uAll
goto :FIN

:OUTPUT4
cls
set "output=%tag%.txt"
set "outpu3=%tag%_arrange.bat"
(
echo @echo off
echo set _ver=%vvv%
echo set _rot=C2R_%chn%
echo set _dst=C2R_%chn%\Office\Data
echo set _uri=%%_dst%%\%%_ver%%
echo set "_work=%%~dp0"
echo setlocal EnableDelayedExpansion
echo pushd "^!_work^!"
echo if not exist *.cab if not exist *.dat ^(
echo echo ==== ERROR ====
echo echo no cab or dat files detected
echo echo.
echo echo Press any key to exit.
echo popd
echo pause ^>nul
echo goto :eof
echo ^)
echo if not exist %%_uri%%\stream*.dat mkdir %%_uri%%
echo for %%%%i in ^(
echo i32*.cab
echo i64*.cab
echo s32*.cab
echo s64*.cab
echo sp32*.cab
echo sp64*.cab
echo sc32*.cab
echo sa64*.cab
echo stream*.dat
echo ^) do ^(
echo if exist "%%%%i" move /y %%%%i %%_uri%%\
echo ^)
echo for %%%%i in ^(
echo SetupLanguagePack*.exe
echo ^) do ^(
echo if exist "%%%%i" move /y %%%%i %%_rot%%\
echo ^)
echo for %%%%i in ^(
echo v32*.cab
echo v64*.cab
echo ^) do ^(
echo if exist "%%%%i" move /y %%%%i %%_dst%%\
echo ^)
echo if exist "%%_dst%%\v32_*.cab" xcopy /cqry %%_dst%%\v32_*.cab %%_dst%%\v32.cab*
echo if exist "%%_dst%%\v64_*.cab" xcopy /cqry %%_dst%%\v64_*.cab %%_dst%%\v64.cab*
if %proof%==1 (
echo if exist "%vvv%_x86_%lang%_Proofing.xml" move /y "%vvv%_x86_%lang%_Proofing.xml" "%%_rot%%\Office\Proofing_%lang%_x86.xml"
echo if exist "%vvv%_x64_%lang%_Proofing.xml" move /y "%vvv%_x64_%lang%_Proofing.xml" "%%_rot%%\Office\Proofing_%lang%_x64.xml"
)
echo echo.
echo echo Done.
echo echo Press any key to exit.
echo popd
echo pause ^>nul
echo goto :eof
)>"%outpu3%"

if exist "%output%" del /f /q %output%

echo %url%/v%bit%_%vvv%.cab>>"%output%"

if %proof%==1 (
call :uProof
goto :FIN
)
call :uAll
goto :FIN

:FIN
title ^>Office Click-to-Run URL Generator^<
echo %line%
echo Channel : %chn%
echo Version : %vvv%
if defined utc echo Updated : %utc%
echo Bitness : %oar%
echo Language: %lang%
echo Output  : %output%
if defined outpu3 echo           %outpu3%
echo %line%
echo.
echo Done.
echo Press any key to exit.
pause >nul
goto :eof
