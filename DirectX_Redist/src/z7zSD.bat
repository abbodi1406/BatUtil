if "%~1"=="" exit /b
@copy /b "%~dp1z7zSD.sfx" + "%~dp1z7zSD.txt" + %1 "%~dpn1.exe"
exit
