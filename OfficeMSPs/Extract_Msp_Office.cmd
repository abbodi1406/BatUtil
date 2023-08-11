<!-- : Begin batch script
@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
mode con cols=180 lines=777

WHOAMI /Groups | FINDSTR /I /C:"S-1-16-16384" /C:"S-1-16-12288" >NUL || (
   ECHO(*************************************
   ECHO(Invoking UAC for Privilege Escalation
   ECHO(*************************************
   CSCRIPT //nologo "%~f0?.wsf" //job:ELAV /File:"%~f0" %*
   EXIT /B
)


SET "dirOfEXE=W:\Data\WU\Updates\Office2010-x86"
SET "dirOfMSP=%~dp0MSPs"
SET "OldMSPdir=!dirOfMSP!\OLD"
SET "langOfMSP=en-us"
SET "ProofLang=es-es,fr-fr"


:EvalOpt
FOR %%A in ( "h|Help" "e|dirOfEXE" "m|dirOfMSP" "o|OldMSPdir" "l|langOfMSP" "p|ProofLang" ) do (
   FOR /f "delims=| tokens=1-2" %%B in ( "%%~A" ) do (
       SET "optShort=%%B"
       SET "optLong=%%C"
       SET "TEST=;-!optShort!;--!optLong!;"
       IF not "!TEST:;%~1;=!"=="!TEST!" (
           IF "!optLong!"=="Help" (
                   ECHO(Recursively extracts MSP files from Office KB packages to a folder with meaningful names
                   ECHO(
                   ECHO(Options:
                   ECHO( -e   --dirOfEXE   [Folder to execute EXE]
                   ECHO( -m   --dirOfMSP   [Folder to extract MSP]
                   ECHO( -o   --OldMSPdir   [Folder to move old MSP versions]
                   ECHO( -l   --langOfMSP   [KB Language]
                   ECHO( -p   --ProofLang   [Proof Language's]
                   ECHO( -h   --Help       ^(Will display help text^)
                   ECHO(
                   ECHO(Example:
                   ECHO( "file.cmd" -e "D:\WHDownloader\Updates\Office2010-x64" --dirOfMSP "E:\MSPs" -o "E:\oldMSPs" --langOfMSP "en-us" -p "fr-fr,es-es"
                   ECHO(
                   ECHO(Proofing package has additional companion languages.
                   ECHO(To find out which you need, check out the link below which fit with your office version.
                   ECHO( Office 2010:                 "technet.microsoft.com/en-us/library/ee942198(v=office.14).aspx"
                   ECHO( Office 2013/365 ProPlus:  "technet.microsoft.com/en-us/library/ee942198(v=office.15).aspx"
                   ECHO( Office 2016:                 Not needed, all packages are language neutral or automatically chosen.
                   PAUSE
                   EXIT /B
           ) else (
                   SET "!optLong!=%~2"
                   SHIFT /1
           )
           GOTO :breakEvalOpt
       )
   )
)
:breakEvalOpt
IF not "%~1"=="" (
   SHIFT /1
   GOTO :EvalOpt
)
FOR %%A in ( "dirOfEXE" "dirOfMSP" "OldMSPdir" ) do (
       SET "optVital=%%~A"
       IF not defined !optVital! (
           ECHO(Please enter data for '!optVital!' of your Office Updates"
           SET /p "!optVital!=!optVital!:"
           ECHO(
       )
       If "!%%~A!"=="" (
           ECHO(Error: Can't continue because of empty var: '!optVital!'^^!
           PAUSE
           EXIT /b
       )
   )
)


DIR /a-d /s "!dirOfEXE!\*-*-*-x*-*.exe" >NUL 2>&1 || SET "ERREXE=1"
DIR /a-d /s "!dirOfEXE!\*-*-*-x*-*.cab" >NUL 2>&1 || SET "ERRCAB=1"
IF defined ERREXE IF defined ERRCAB (
   ECHO(ERROR: Folder or valid named Office update files could not be found at "!dirOfEXE!\"^^!
   GOTO :EndOfFile
)
   CD /d "!dirOfEXE!\"
   IF not exist "!dirOfMSP!\" ( MKDIR "!dirOfMSP!" )
   FOR /r %%A in ("*-*-*-x*-*.exe") do (
       PUSHD "%%~dpA"
       SET "fileOfEXE=%%~nA"
       ECHO(Extracting "!fileOfEXE!.exe"
       "!fileOfEXE!.exe" /quiet /extract:"!dirOfMSP!\!fileOfEXE!"
       IF not exist "!dirOfMSP!\!fileOfEXE!\" (
           SET "ercFailEXE=!ERRORLEVEL!"
           SET /a "cntFailEXE+=1"
           SET "excFailEXE!cntFailEXE!=%%~fA"
           SET "ercFailEXE!cntFailEXE!=!ercFailEXE!"
           ECHO(ERROR: No folder was made after executing "!fileOfEXE!.exe"^^!
       ) else (
           CALL :doMSP
       )
       POPD
       ECHO(
       ECHO(
   )
   FOR /r %%A in ("*-*-*-x*-*.cab") do (
       PUSHD "%%~dpA"
       SET "fileOfEXE=%%~nA"
       ECHO(Extracting "!fileOfEXE!.cab"
       mkdir "!dirOfMSP!\!fileOfEXE!" 2>NUL
       expand.exe -r -f:*.msp "!fileOfEXE!.cab" "!dirOfMSP!\!fileOfEXE!" >NUL
       IF not exist "!dirOfMSP!\!fileOfEXE!\*.msp" (
           SET "ercFailEXE=!ERRORLEVEL!"
           SET /a "cntFailEXE+=1"
           SET "excFailEXE!cntFailEXE!=%%~fA"
           SET "ercFailEXE!cntFailEXE!=!ercFailEXE!"
           ECHO(ERROR: No folder was made after extracting "!fileOfEXE!.cab"^^!
       ) else (
           CALL :doMSP
       )
       POPD
       ECHO(
       ECHO(
   )
   ECHO(
   IF defined ercFailEXE (
       ECHO(A number of !cntFailEXE! executables have failed to extract folders.
       ECHO(The following have failed:
       FOR /L %%A in (1,1,!cntFailEXE!) Do (
           ECHO(
           ECHO(File: "!excFailEXE%%A!"
           ECHO(Errorcode: "!ercFailEXE%%A!"
       )
   ) else (
       ECHO(Dinner is ready^^!
   )

:EndOfFile
ECHO(
ECHO(
ECHO(Written and maintained by Hearlywarlot
ECHO(For updates on the script or other nice things visit our awesome Forum at:
ECHO(forums.mydigitallife.net/threads/64028/
ECHO(

DEL /F /Q "!TEMP!\opatchinstall*.log" >NUL 2>&1
ENDLOCAL
PAUSE
EXIT /b

:doMSP
           PUSHD "!dirOfMSP!\!fileOfEXE!\"
           ECHO(=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
           FOR /r %%B in ("*.msp") do (
               SET "fileOfMSP=%%~nB"
               FOR /f "delims=-" %%C in ( "!fileOfMSP!" ) do (
                   SET "nameOfMSP=%%C"
                   SET "TRUE="
                   IF "!langOfMSP!"=="" (
                       SET "TRUE=1"
                   ) else (
                       IF /I "!fileOfMSP!"=="!nameOfMSP!-x-none" (
                           SET "TRUE=1"
                       ) ELSE IF /I "!fileOfMSP!"=="!nameOfMSP!" (
                           SET "TRUE=1"
                       ) ELSE (
                           IF "!ProofLang!"=="" (
                               IF /I "!nameOfMSP!"=="proof" ( SET "TRUE=1" )
                           )
                           IF not "!ProofLang!"=="" FOR %%D in ( !ProofLang! ) do (
                               IF /I "!fileOfMSP!"=="proof-%%D" ( SET "TRUE=1" )
                           )
                           IF not "!langOfMSP!"=="" FOR %%D in ( !langOfMSP! ) do (
                               IF /I "!fileOfMSP!"=="!nameOfMSP!-%%D" ( SET "TRUE=1" )
                           )
                       )
                   )
                   IF defined TRUE (
                       FOR /f "tokens=1-2,4 delims=-" %%D in ( "!fileOfEXE!" ) do (
                           SET "nameOfEXE=%%D"
                           SET "kbOfEXE=%%E"
                           SET "archOfEXE=%%F"
                       )
                       SET "_I=Y"
                       ECHO !fileOfMSP! | FINDSTR /I /V "x-none" | FINDSTR /I /R ".*-.*-.*" >NUL && (
                           SET "_I=Z"
                       )
                       SET "NewMSPpath=!_I!_!nameOfEXE!_!kbOfEXE!_!archOfEXE!_!fileOfMSP!.msp"
                       ECHO(Moving "!fileOfMSP!.msp" to "!NewMSPpath!"
                       IF not exist "!dirOfMSP!\!NewMSPpath!" (
                           MOVE "!fileOfMSP!.msp" "!dirOfMSP!\!NewMSPpath!" >NUL
                       ) else (
                           ECHO( ^<= File already exists, skipping =^>
                       )
                   )
               )
           )
           IF defined NewMSPpath (
               FOR /F "tokens=1-5 delims=_" %%D in ('DIR /B /A:-D "!dirOfMSP!\!_I!_!nameOfEXE!_kb*_!archOfEXE!_*.msp"') do (
                   IF /I not "%%F" == "!kbOfEXE!" IF /I "%%H" == "!fileOfMSP!.msp" (
                       IF not exist "!OldMSPdir!\" ( MKDIR "!OldMSPdir!" )
                       SET "OldMSPfile=%%D_%%E_%%F_%%G_%%H"
                       ECHO( ^<= Moving older version " !OldMSPfile!" =^>
                       MOVE "!dirOfMSP!\!OldMSPfile!" "!OldMSPdir!\" >NUL
                   )
               )
               Set "NewMSPpath="
           ) else (
               ECHO( ^<= Oh my, It appears none of the MSP files were applicable to your given languages =^>
           )
           ECHO(=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
           POPD
           rem. ECHO(Removing folder "!dirOfMSP!\!fileOfEXE!\"
           RD /s /q "!dirOfMSP!\!fileOfEXE!\"
EXIT /b

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

           CreateObject("Shell.Application").ShellExecute "cmd", "/c " & chr(34) & chr(34) & strArg("File") & chr(34) & " " & strLine & chr(34), "", "runas", 1
       </script>
   </job>
</package>