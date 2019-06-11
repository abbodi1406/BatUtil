@echo off
:: set version choice to always latest available online
set latest=1

:: set specific valid version
set version=

set "_tempdir=%temp%"
set "_workdir=%~dp0"
if "%_workdir:~-1%"=="\" set "_workdir=%_workdir:~0,-1%"
setlocal EnableDelayedExpansion
set /a cc=0
for %%A in (en-US,ar-SA,bg-BG,cs-CZ,da-DK,de-DE,el-GR,es-ES,et-EE) do (
set /a cc+=1
set lang0!cc!=%%A
)
for %%A in (fi-FI,fr-FR,he-IL,hr-HR,hu-HU,it-IT,ja-JP,ko-KR,lt-LT,lv-LV,nb-NO,nl-NL,pl-PL,pt-BR,pt-PT,ro-RO,ru-RU,sk-SK,sl-SI,sr-Latn-RS,sv-SE,th-TH,tr-TR,uk-UA,zh-CN,zh-TW,hi-IN,id-ID,kk-KZ,MS-MY,vi-VN) do (
set /a cc+=1
set lang!cc!=%%A
)
set /a cc=0
for %%A in (1033,1025,1026,1029,1030,1031,1032,3082,1061) do (
set /a cc+=1
set lcid0!cc!=%%A
)
for %%A in (1035,1036,1037,1050,1038,1040,1041,1042,1063,1062,1044,1043,1045,1046,2070,1048,1049,1051,1060,9242,1053,1054,1055,1058,2052,1028,1081,1057,1087,1086,1066) do (
set /a cc+=1
set lcid!cc!=%%A
)

set /a cc=0
for %%A in (
5440fd1f-7ecb-4221-8110-145efaa6372f
64256afe-f5d9-4f86-8936-8840a6a4f5be
492350f6-3a01-4f97-b9c0-c7c6ddf67d60
b8f9b850-328d-4355-9145-c59439a0c4cf
7ffbc6bf-bc32-4f92-8982-f9dd17fd3114
2e148de9-61c8-4051-b103-4af54baffbb4
f2e724c1-748f-4b47-8fb8-8e0d210e9208
ea4a4090-de26-49d7-93c1-91bff9e53fc3
b61285dd-d9f7-41f2-9757-8f61cba4e9c8
) do (
set /a cc+=1
set ffn!cc!=%%A
)
set /a cc=0
for %%A in (Insiders,MonthlyTargeted,Monthly,SemiAnnualTargeted,SemiAnnual,PerpetualVL2019Targeted,PerpetualVL2019,DogfoodDevMain,MicrosoftElite) do (
set /a cc+=1
set chn!cc!=%%A
)

set /a cc=0
for %%A in (x86,x64,x86x64) do (
set /a cc+=1
set arc!cc!=%%A
)
set /a cc=0
for %%A in (32,64,00) do (
set /a cc+=1
set bit!cc!=%%A
)

set full=1
set proof=0
set "line=============================================================="

:CHANNEL
cls
title ^>Choose Channel^<
set inpt=
set verified=0
echo %line%
echo.
echo Official CDNs:
echo. 1. Insiders                            ^|   Insiders::DevMain
echo. 2. Monthly / Targeted                  ^|   Insiders::CC
echo. 3. Monthly                             ^| Production::CC
echo. 4. Semi-Annual / Targeted              ^|   Insiders::FRDC
echo. 5. Semi-Annual                         ^| Production::DC
echo. 6. Perpetual2019 VL / Targeted         ^|   Insiders::LTSC
echo. 7. Perpetual2019 VL                    ^| Production::LTSC
echo.
echo Testing CDNs:
echo. 8. DevMain Channel                     ^|    Dogfood::DevMain
echo. 9. Microsoft Elite                     ^|  Microsoft::DevMain
echo %line%
echo.
set /p inpt= ^> Enter Channel option number, and press "Enter": 
if "%inpt%"=="" goto :eof
for /l %%i in (1,1,9) do (if %inpt%==%%i set verified=1)
if %verified%==0 goto :CHANNEL
set "ffn=!ffn%inpt%!"
set "chn=!chn%inpt%!"

if %latest%==1 goto :MRO
if defined version set "vvv=%version%"&goto :BITNESS

:VERSION
cls
title ^>Choose Version^<
set inpt=
set verified=0
echo %line%
echo Channel : %chn%
echo %line%
echo.
echo. 1. Latest Version
echo. 2. Specific Version
echo %line%
echo.
set /p inpt= ^> Enter Version option number, and press "Enter": 
if "%inpt%"=="" goto :eof
for /l %%i in (1,1,2) do (if %inpt%==%%i set verified=1)
if %verified%==0 goto :VERSION
if %inpt%==1 goto :MRO

:SPECIFIC
cls
title ^>Specific Version^<
set inpt=
echo %line%
echo Channel : %chn%
echo %line%
echo.
echo Enter the version number
echo make sure it is a valid version for the choosen channel
echo %line%
echo.
set /p inpt= ^> 
if "%inpt%"=="" goto :eof
if "%inpt:~0,5%"=="16.0." set "vvv=%inpt%"&goto :BITNESS
goto :SPECIFIC

:MRO
cls
title ^>Office Click-to-Run Generator^<
echo %line%
echo Channel : %chn%
echo %line%
echo.
echo %line%
echo Checking available version . . .
echo %line%
echo.
set "dms=https://mrodevicemgr.officeapps.live.com/mrodevicemgrsvc/api/v2/C2RReleaseData"
if exist "!_tempdir!\C2R.json" del /f /q "!_tempdir!\C2R.json"
1>nul 2>nul powershell -NoLogo -NoProfile -ExecutionPolicy Bypass (New-Object Net.WebClient).DownloadFile('%dms%?audienceFFN=%ffn%', '"!_tempdir!\C2R.json"')
if not exist "!_tempdir!\C2R.json" (
echo.
echo %line%
echo ERROR: could not check available version online
echo verify internet connection and powershell is not disabled
echo %line%
echo.
echo Press any key to exit.
pause >nul
goto :eof
)
for /f "usebackq tokens=2 delims=:, " %%G in (`findstr /i AvailableBuild "!_tempdir!\C2R.json"`) do set "vvv=%%~G"
for /f "usebackq tokens=2-6 delims=:/ " %%G in (`findstr /i TimestampUtc "!_tempdir!\C2R.json"`) do set "utc=%%I-%%~G-%%H %%J:%%K
del /f /q "!_tempdir!\C2R.json"
if not defined vvv (
echo.
echo %line%
echo ERROR: could not detect available version
echo %line%
echo.
echo Press any key to exit.
pause >nul
goto :eof
)

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
echo. 1. x86 ^(32-bit^)
echo. 2. x64 ^(64-bit^)
echo. 3. Both
echo %line%
echo.
set /p inpt= ^> Enter Bitness option number, and press "Enter": 
if "%inpt%"=="" goto :eof
for /l %%i in (1,1,3) do (if %inpt%==%%i set verified=1)
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
echo %line%
echo.
set /p inpt= ^> Enter Language option number, and press "Enter": 
if "%inpt%"=="" goto :eof
for /l %%i in (1,1,9) do (if %inpt%==%%i set verified=1)
for /l %%i in (1,1,9) do (if %inpt%==0%%i set verified=1)
for /l %%i in (10,1,40) do (if %inpt%==%%i set verified=1)
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

:OUTPUT
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
echo. 3. Text file
echo %line%
echo.
set /p inpt= ^> Enter Output option number, and press "Enter": 
if "%inpt%"=="" goto :eof
for /l %%i in (1,1,3) do (if %inpt%==%%i set verified=1)
if %verified%==0 goto :OUTPUT
setlocal DisableDelayedExpansion
set "url=http://officecdn.microsoft.com/pr/%ffn%/Office/Data"
set "stp=http://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/Office/Data"
set oar=%arc%
set "tag=%vvv%_%oar%_%lang%_%chn%"
if %full%==0 set "tag=%vvv%_%oar%_%lang%_LangPack_%chn%"
if %proof%==1 set "tag=%vvv%_%oar%_%lang%_Proofing_%chn%"
set dual=0
if /i %arc%==x86x64 (set "arc=x86"&set "bit=32"&set dual=1)
goto :OUTPUT%inpt%

:OUTPUT1
cls
set "output=%_workdir%\%tag%_aria2.bat"
(
echo @echo off
echo rem Limit the download speed, example: 1M, 500K "0 = unlimited"
echo set "speedLimit=0"
echo.
echo rem Set the number of parallel downloads
echo set "parallel=1"
echo.
echo set exist=0
echo if exist "%%~dp0aria2c.exe" set exist=1
echo for %%%%i in ^(aria2c.exe^) do @if NOT "%%%%~$PATH:i"=="" set exist=1
echo if %%exist%%==0 echo.^&echo Error: aria2c.exe is not detected^&echo.^&pause^&exit /b
echo set "destDir=C2R_%chn%"
echo set "uri=temp_aria2.txt"
echo echo Downloading...
echo echo.
echo pushd "%%~dp0"
echo setlocal EnableDelayedExpansion
echo if not exist "!uri!" call :GenTXT
echo aria2c.exe -x16 -s16 -j%%parallel%% -c -R --max-overall-download-limit=%%speedLimit%% -d"!destDir!" -i"!uri!"
echo if exist "!uri!" del /f /q "!uri!"
echo popd
echo echo.
echo pause
echo exit /b
echo.
echo :GenTXT
echo set "LN="
echo set "NC="
echo set "SN="
echo for /f "skip=1 delims=:" %%%%a in ^('findstr /N ^^:TXT "%%~f0"'^) do ^(
echo if not defined SN ^(set "SN=%%%%a"^) else ^(set /a NC=%%%%a-SN-1^)
echo ^)
echo ^<"%%~f0" ^(
echo for /L %%%%a in ^(1,1,%%SN%%^) do set /p =
echo for /L %%%%a in ^(1,1,%%NC%%^) do ^(
echo set LN=
echo set /p LN=
echo echo^(!LN!^)
echo ^)^>"!uri!"
echo goto TXTEnd
echo.
echo :TXTBegin
)>"%output%"

for %%a in (
v%bit%.cab
v%bit%_%vvv%.cab
) do (
(echo %url%/%%a&echo.  out=Office\Data\%%a&echo.)>>"%output%"
)

if %proof%==1 (
for %%a in (
  sp%bit%%lcid%.cab
  i%bit%0.cab
  s%bit%0.cab
  stream.%arc%.%lang%.proof.dat
  ) do (
  (echo %url%/%vvv%/%%a&echo.  out=Office\Data\%vvv%\%%a&echo.)>>"%output%"
  )
if %dual%==0 if %arc%==x86 for %%a in (
  i640.cab
  ) do (
  (echo %url%/%vvv%/%%a&echo.  out=Office\Data\%vvv%\%%a&echo.)>>"%output%"
  )
if %dual%==1 for %%a in (
  v64.cab
  v64_%vvv%.cab
  ) do (
  (echo %url%/%%a&echo.  out=Office\Data\%%a&echo.)>>"%output%"
  )
if %dual%==1 for %%a in (
  sp64%lcid%.cab
  i640.cab
  s640.cab
  stream.x64.%lang%.proof.dat
  ) do (
  (echo %url%/%vvv%/%%a&echo.  out=Office\Data\%vvv%\%%a&echo.)>>"%output%"
  )
  (
  echo :TXTEnd
  echo exit /b
  )>>"%output%"
goto :FIN
)

for %%a in (
i%bit%%lcid%.cab
s%bit%%lcid%.cab
i%bit%0.cab
s%bit%0.cab
stream.%arc%.%lang%.dat
) do (
(echo %url%/%vvv%/%%a&echo.  out=Office\Data\%vvv%\%%a&echo.)>>"%output%"
)
if %dual%==0 if %arc%==x86 for %%a in (
i64%lcid%.cab
i640.cab
) do (
(echo %url%/%vvv%/%%a&echo.  out=Office\Data\%vvv%\%%a&echo.)>>"%output%"
)
if %full%==1 for %%a in (
stream.%arc%.x-none.dat
) do (
(echo %url%/%vvv%/%%a&echo.  out=Office\Data\%vvv%\%%a&echo.)>>"%output%"
)
if %full%==0 for %%a in (
SetupLanguagePack.%arc%.%lang%.exe
) do (
(echo %stp%/%%a&echo.  out=%%a&echo.)>>"%output%"
)
if %dual%==1 for %%a in (
v64.cab
v64_%vvv%.cab
) do (
(echo %url%/%%a&echo.  out=Office\Data\%%a&echo.)>>"%output%"
)
if %dual%==1 for %%a in (
i64%lcid%.cab
s64%lcid%.cab
i640.cab
s640.cab
stream.x64.%lang%.dat
) do (
(echo %url%/%vvv%/%%a&echo.  out=Office\Data\%vvv%\%%a&echo.)>>"%output%"
)
if %dual%==1 if %full%==1 for %%a in (
stream.x64.x-none.dat
) do (
(echo %url%/%vvv%/%%a&echo.  out=Office\Data\%vvv%\%%a&echo.)>>"%output%"
)
if %dual%==1 if %full%==0 for %%a in (
SetupLanguagePack.x64.%lang%.exe
) do (
(echo %stp%/%%a&echo.  out=%%a&echo.)>>"%output%"
)

(
echo :TXTEnd
echo exit /b
)>>"%output%"
goto :FIN

:OUTPUT2
cls
set "output=%_workdir%\%tag%_wget.bat"
(
echo @echo off
echo rem Limit the download speed, example: 1M, 500K "0 = unlimited"
echo set "speedLimit=0"
echo.
echo set exist=0
echo if exist "%%~dp0wget.exe" set exist=1
echo for %%%%i in ^(wget.exe^) do @if NOT "%%%%~$PATH:i"=="" set exist=1
echo if %%exist%%==0 echo.^&echo Error: wget.exe is not detected^&echo.^&pause^&exit /b
echo set "destDir=C2R_%chn%"
echo set "uri=temp_wget.txt"
echo echo Downloading...
echo echo.
echo pushd "%%~dp0"
echo setlocal EnableDelayedExpansion
echo if not exist "!uri!" call :GenTXT
echo wget.exe --limit-rate=%%speedLimit%% --directory-prefix="!destDir!" --input-file="!uri!" --no-verbose --show-progress --progress=bar:force:noscroll --continue --retry-connrefused --tries=5 --content-disposition --trust-server-names --ignore-case --force-directories --no-host-directories --cut-dirs=2
echo if exist "!destDir!\Office\Data\SetupLanguagePack*.exe" move /y "!destDir!\Office\Data\SetupLanguagePack*.exe" "!destDir!\"
echo if exist "!uri!" del /f /q "!uri!"
echo popd
echo echo.
echo pause
echo exit /b
echo.
echo :GenTXT
echo set "LN="
echo set "NC="
echo set "SN="
echo for /f "skip=1 delims=:" %%%%a in ^('findstr /N ^^:TXT "%%~f0"'^) do ^(
echo if not defined SN ^(set "SN=%%%%a"^) else ^(set /a NC=%%%%a-SN-1^)
echo ^)
echo ^<"%%~f0" ^(
echo for /L %%%%a in ^(1,1,%%SN%%^) do set /p =
echo for /L %%%%a in ^(1,1,%%NC%%^) do ^(
echo set LN=
echo set /p LN=
echo echo^(!LN!^)
echo ^)^>"!uri!"
echo goto TXTEnd
echo.
echo :TXTBegin
)>"%output%"

for %%a in (
v%bit%.cab
v%bit%_%vvv%.cab
) do (
echo %url%/%%a>>"%output%"
)

if %proof%==1 (
for %%a in (
  sp%bit%%lcid%.cab
  i%bit%0.cab
  s%bit%0.cab
  stream.%arc%.%lang%.proof.dat
  ) do (
  echo %url%/%vvv%/%%a>>"%output%"
  )
if %dual%==0 if %arc%==x86 for %%a in (
  i640.cab
  ) do (
  echo %url%/%vvv%/%%a>>"%output%"
  )
if %dual%==1 for %%a in (
  v64.cab
  v64_%vvv%.cab
  ) do (
  echo %url%/%%a>>"%output%"
  )
if %dual%==1 for %%a in (
  sp64%lcid%.cab
  i640.cab
  s640.cab
  stream.x64.%lang%.proof.dat
  ) do (
  echo %url%/%vvv%/%%a>>"%output%"
  )
  (
  echo :TXTEnd
  echo exit /b
  )>>"%output%"
goto :FIN
)

for %%a in (
i%bit%%lcid%.cab
s%bit%%lcid%.cab
i%bit%0.cab
s%bit%0.cab
stream.%arc%.%lang%.dat
) do (
echo %url%/%vvv%/%%a>>"%output%"
)
if %dual%==0 if %arc%==x86 for %%a in (
i64%lcid%.cab
i640.cab
) do (
echo %url%/%vvv%/%%a>>"%output%"
)
if %full%==1 for %%a in (
stream.%arc%.x-none.dat
) do (
echo %url%/%vvv%/%%a>>"%output%"
)
if %full%==0 for %%a in (
SetupLanguagePack.%arc%.%lang%.exe
) do (
echo %stp%/%%a>>"%output%"
)
if %dual%==1 for %%a in (
v64.cab
v64_%vvv%.cab
) do (
echo %url%/%%a>>"%output%"
)
if %dual%==1 for %%a in (
i64%lcid%.cab
s64%lcid%.cab
i640.cab
s640.cab
stream.x64.%lang%.dat
) do (
echo %url%/%vvv%/%%a>>"%output%"
)
if %dual%==1 if %full%==1 for %%a in (
stream.x64.x-none.dat
) do (
echo %url%/%vvv%/%%a>>"%output%"
)
if %dual%==1 if %full%==0 for %%a in (
SetupLanguagePack.x64.%lang%.exe
) do (
echo %stp%/%%a>>"%output%"
)

(
echo :TXTEnd
echo exit /b
)>>"%output%"
goto :FIN

:OUTPUT3
cls
set "output=%_workdir%\%tag%_plain.txt"
if exist "%output%" del /f /q %output%
for %%a in (
v%bit%.cab
v%bit%_%vvv%.cab
) do (
echo %url%/%%a>>"%output%"
)

if %proof%==1 (
for %%a in (
  sp%bit%%lcid%.cab
  i%bit%0.cab
  s%bit%0.cab
  stream.%arc%.%lang%.proof.dat
  ) do (
  echo %url%/%vvv%/%%a>>"%output%"
  )
if %dual%==0 if %arc%==x86 for %%a in (
  i640.cab
  ) do (
  echo %url%/%vvv%/%%a>>"%output%"
  )
if %dual%==1 for %%a in (
  v64.cab
  v64_%vvv%.cab
  ) do (
  echo %url%/%%a>>"%output%"
  )
if %dual%==1 for %%a in (
  sp64%lcid%.cab
  i640.cab
  s640.cab
  stream.x64.%lang%.proof.dat
  ) do (
  echo %url%/%vvv%/%%a>>"%output%"
  )
goto :FIN
)

for %%a in (
i%bit%%lcid%.cab
s%bit%%lcid%.cab
i%bit%0.cab
s%bit%0.cab
stream.%arc%.%lang%.dat
) do (
echo %url%/%vvv%/%%a>>"%output%"
)
if %dual%==0 if %arc%==x86 for %%a in (
i64%lcid%.cab
i640.cab
) do (
echo %url%/%vvv%/%%a>>"%output%"
)
if %full%==1 for %%a in (
stream.%arc%.x-none.dat
) do (
echo %url%/%vvv%/%%a>>"%output%"
)
if %dual%==1 for %%a in (
v64.cab
v64_%vvv%.cab
) do (
echo %url%/%%a>>"%output%"
)
if %dual%==1 for %%a in (
i64%lcid%.cab
s64%lcid%.cab
i640.cab
s640.cab
stream.x64.%lang%.dat
) do (
echo %url%/%vvv%/%%a>>"%output%"
)
if %dual%==1 if %full%==1 for %%a in (
stream.x64.x-none.dat
) do (
echo %url%/%vvv%/%%a>>"%output%"
)
goto :FIN

:FIN
title ^>Office Click-to-Run URL Generator^<
echo %line%
echo Channel : %chn%
echo Version : %vvv%
if defined utc echo Updated : %utc%
echo Bitness : %arc%
echo Language: %lang%
echo Output  : %output%
echo %line%
echo.
echo Done.
echo Press any key to exit.
pause >nul
goto :eof
