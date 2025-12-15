' Windows Installer utility to generate file cabinets from MSI database
' For use with Windows Scripting Host, CScript.exe or WScript.exe
' Copyright (c) Microsoft Corporation. All rights reserved.
' Demonstrates the access to install engine and actions
'
Option Explicit

' FileSystemObject.CreateTextFile and FileSystemObject.OpenTextFile
Const OpenAsASCII   = 0 
Const OpenAsUnicode = -1

' FileSystemObject.CreateTextFile
Const OverwriteIfExist = -1
Const FailIfExist      = 0

' FileSystemObject.OpenTextFile
Const OpenAsDefault    = -2
Const CreateIfNotExist = -1
Const FailIfNotExist   = 0
Const ForReading = 1
Const ForWriting = 2
Const ForAppending = 8

Const msiOpenDatabaseModeReadOnly = 0
Const msiOpenDatabaseModeTransact = 1

Const msiViewModifyInsert         = 1
Const msiViewModifyUpdate         = 2
Const msiViewModifyAssign         = 3
Const msiViewModifyReplace        = 4
Const msiViewModifyDelete         = 6

Const msiUILevelNone = 2

Const msiRunModeSourceShortNames = 9

Const msidbFileAttributesNoncompressed = &h00002000
Const msidbFileAttributesReadOnly = &h00000001

Dim argCount:argCount = Wscript.Arguments.Count
Dim iArg:iArg = 0
If argCount > 0 Then If InStr(1, Wscript.Arguments(0), "?", vbTextCompare) > 0 Then argCount = 0
If (argCount < 2) Then
	Wscript.Echo "Windows Installer utility to generate compressed file cabinets from MSI database" &_
		vbNewLine & " The 1st argument is the path to MSI database, at the source file root" &_
		vbNewLine & " The 2nd argument is the base name used for the generated files (DDF, INF, RPT)" &_
		vbNewLine & " The 3rd argument can optionally specify separate source location from the MSI" &_
		vbNewLine & " The following options may be specified at any point on the command line" &_
		vbNewLine & "  /L to use LZX compression instead of MSZIP" &_
		vbNewLine & "  /F to limit cabinet size to 1.44 MB floppy size rather than CD" &_
		vbNewLine & "  /C to run compression, else only generates the .DDF file" &_
		vbNewLine & "  /U to update the MSI database to reference the generated cabinet" &_
		vbNewLine & "  /E to embed the cabinet file in the installer package as a stream" &_
		vbNewLine & "  /S to sequence number file table, ordered by directories" &_
		vbNewLine & "  /R to revert to non-cabinet install, removes cabinet if /E specified" &_
		vbNewLine & " Notes:" &_
		vbNewLine & "  In order to generate a cabinet, MAKECAB.EXE must be on the PATH" &_
		vbNewLine & "  base name used for files and cabinet stream is case-sensitive" &_
		vbNewLine & "  If source type set to compressed, all files will be opened at the root" &_
		vbNewLine & "  (The /R option removes the compressed bit - SummaryInfo property 15 & 2)" &_
		vbNewLine & "  To replace an embedded cabinet, include the options: /R /C /U /E" &_
		vbNewLine & "  Does not handle updating of Media table to handle multiple cabinets" &_
		vbNewLine &_
		vbNewLine & "Copyright (C) Microsoft Corporation.  All rights reserved."
	Wscript.Quit 1
End If

' Get argument values, processing any option flags
Dim compressType : compressType = "MSZIP"
Dim cabSize      : cabSize      = "CDROM"
Dim makeCab      : makeCab      = False
Dim embedCab     : embedCab     = False
Dim updateMsi    : updateMsi    = False
Dim sequenceFile : sequenceFile = False
Dim removeCab    : removeCab    = False
Dim databasePath : databasePath = NextArgument
Dim baseName     : baseName     = NextArgument
Dim sourceFolder : sourceFolder = NextArgument
If Not IsEmpty(NextArgument) Then Fail "More than 3 arguments supplied" ' process any trailing options
If Len(baseName) < 1 Or Len(baseName) > 8 Then Fail "Base file name must be from 1 to 8 characters"
If Not IsEmpty(sourceFolder) And Right(sourceFolder, 1) <> "\" Then sourceFolder = sourceFolder & "\"
Dim cabFile : cabFile = baseName & ".cab"
Dim cabName : cabName = cabFile : If embedCab Then cabName = "#" & cabName

' Connect to Windows Installer object
'On Error Resume Next
Dim installer : Set installer = Nothing
Set installer = Wscript.CreateObject("WindowsInstaller.Installer") : CheckError

' Open database
Dim database, openMode, view, record, updateMode, sumInfo, sequence, lastSequence
If updateMsi Or sequenceFile Or removeCab Then openMode = msiOpenDatabaseModeTransact Else openMode = msiOpenDatabaseModeReadOnly
Set database = installer.OpenDatabase(databasePath, openMode) : CheckError

Set view = database.OpenView("SELECT DiskId, LastSequence, Cabinet FROM Media ORDER BY DiskId") : CheckError
view.Execute : CheckError
Set record = view.Fetch : CheckError
cabFile    = record.StringData(3)

Set sumInfo = database.SummaryInformation(3) : CheckError
sumInfo.Property(15) = sumInfo.Property(15) And Not 2
sumInfo.Persist
Set sumInfo = Nothing

' Remove existing cabinet(s) and revert to source tree install if options specified
If removeCab Then
	Set view = database.OpenView("SELECT DiskId, LastSequence, Cabinet FROM Media ORDER BY DiskId") : CheckError
	view.Execute : CheckError
	updateMode = msiViewModifyUpdate
	Set record = view.Fetch : CheckError
	If Not record Is Nothing Then ' Media table not empty
		If Not record.IsNull(3) Then
			If record.StringData(3) <> cabName Then Wscript.Echo "Warning, cabinet name in media table, " & record.StringData(3) & " does not match " & cabName
			record.StringData(3) = Empty
		End If
		record.IntegerData(2) = 9999 ' in case of multiple cabinets, force all files from 1st media
		view.Modify msiViewModifyUpdate, record : CheckError
		Do
			Set record = view.Fetch : CheckError
			If record Is Nothing Then Exit Do
			view.Modify msiViewModifyDelete, record : CheckError 'remove other cabinet records
		Loop
	End If
	Set sumInfo = database.SummaryInformation(3) : CheckError
	sumInfo.Property(11) = Now
	sumInfo.Property(13) = Now
	sumInfo.Property(15) = sumInfo.Property(15) And Not 2
	sumInfo.Persist
	Set view = database.OpenView("SELECT `Name`,`Data` FROM _Streams WHERE `Name`= '" & cabFile & "'") : CheckError
	view.Execute : CheckError
	Set record = view.Fetch
	If record Is Nothing Then
		Wscript.Echo "Warning, cabinet stream not found in package: " & cabFile
	Else
		view.Modify msiViewModifyDelete, record : CheckError
	End If
	Set sumInfo = Nothing ' must release stream
	database.Commit : CheckError
	If Not updateMsi Then Wscript.Quit 0
End If

' Create an install session and execute actions in order to perform directory resolution
installer.UILevel = msiUILevelNone
Dim session : Set session = installer.OpenPackage(database,1) : If Err <> 0 Then Fail "Database: " & databasePath & ". Invalid installer package format"
Dim shortNames : shortNames = session.Mode(msiRunModeSourceShortNames) : CheckError
If Not IsEmpty(sourceFolder) Then session.Property("OriginalDatabase") = sourceFolder : CheckError
Dim stat : stat = session.DoAction("CostInitialize") : CheckError
If stat <> 1 Then Fail "CostInitialize failed, returned " & stat

' Check for non-cabinet files to avoid sequence number collisions
lastSequence = 0
If sequenceFile Then
	Set view = database.OpenView("SELECT Sequence,Attributes FROM File") : CheckError
	view.Execute : CheckError
	Do
		Set record = view.Fetch : CheckError
		If record Is Nothing Then Exit Do
		sequence = record.IntegerData(1)
		If (record.IntegerData(2) And msidbFileAttributesNoncompressed) <> 0 And sequence > lastSequence Then lastSequence = sequence
	Loop
End If

' Join File table to Component table in order to find directories
Dim orderBy : If sequenceFile Then orderBy = "Directory_" Else orderBy = "Sequence"
Set view = database.OpenView("SELECT File,FileName,Directory_,Sequence,File.Attributes FROM File,Component WHERE Component_=Component ORDER BY " & orderBy) : CheckError
view.Execute : CheckError

Do
	Set record = view.Fetch : CheckError
	If record Is Nothing Then Exit Do
	lastSequence = record.IntegerData(4)
Loop

Dim ddfFile, ddfView, ddfRecord, arrDisks, numDisks, lastDisk, SeqLast, SeqLasts(4), cabFiles(4)
If updateMsi Then UndupSequence
If updateMsi Then UndupSequence
MediaSequence
lastSequence = 0

Set ddfView = database.OpenView("SELECT DiskId, LastSequence, Cabinet FROM Media ORDER BY DiskId") : CheckError
ddfView.Execute : CheckError
arrDisks = 0
numDisks = 0
Do
	Set ddfRecord = ddfView.Fetch : CheckError
	If ddfRecord Is Nothing Then Exit Do
	SeqLasts(arrDisks) = ddfRecord.IntegerData(2)
	cabFiles(arrDisks) = ddfRecord.StringData(3)
	arrDisks = arrDisks + 1
	numDisks = numDisks + 1
Loop
arrDisks = 0
SeqLast = SeqLasts(arrDisks)
cabFile = cabFiles(arrDisks)
ddfFile = Left(cabFile, InstrRev(cabFile, ".")-1)
Dim FSO : Set FSO = CreateObject("Scripting.FileSystemObject") : CheckError
If FSO.FileExists(ddfFile & ".ddf") Then
	ddfFile = ddfFile & "_2"
End If

Set view = database.OpenView("SELECT File,FileName,Directory_,Sequence,File.Attributes FROM File,Component WHERE Component_=Component ORDER BY " & orderBy) : CheckError
view.Execute : CheckError

' Create DDF file and write header properties
Dim FileSys, outStream
outFileDDF

' Fetch each file and request the source path, then verify the source path
Dim fileKey, fileName, folder, sourcePath, delim, message, attributes, compressedFiles
compressedFiles = False
Do
	Set record = view.Fetch : CheckError
	If record Is Nothing Then Exit Do
	fileKey    = record.StringData(1)
	fileName   = record.StringData(2)
	folder     = record.StringData(3)
	sequence   = record.IntegerData(4)
	attributes = record.IntegerData(5)
	If sequence > SeqLast And numDisks > 1 Then
		outStream.Close
		If Not compressedFiles Then FSO.DeleteFile(ddfFile & ".ddf")
		compressedFiles = False
		arrDisks = arrDisks + 1
		SeqLast = SeqLasts(arrDisks)
		cabFile = cabFiles(arrDisks)
		ddfFile = Left(cabFile, InstrRev(cabFile, ".")-1)
		If FSO.FileExists(ddfFile & ".ddf") Then
			ddfFile = ddfFile & "_2"
		End If
		outFileDDF
	End If
	If (attributes And msidbFileAttributesNoncompressed) = 0 Then
		If sequence <= lastSequence Then
			If Not sequenceFile Then
				Wscript.Echo fileKey
				Fail "Duplicate sequence numbers in File table, use /S option"
			End If
			sequence = lastSequence + 1
			record.IntegerData(4) = sequence
			view.Modify msiViewModifyUpdate, record
		End If
		lastSequence = sequence
		delim = InStr(1, fileName, "|", vbBinaryCompare)
		If delim <> 0 Then
			If shortNames Then fileName = Left(fileName, delim-1) Else fileName = Right(fileName, Len(fileName) - delim)
		End If
		sourcePath = session.SourcePath(folder) & fileName
		outStream.WriteLine """" & sourcePath & """" & " " & fileKey
		If installer.FileAttributes(sourcePath) = -1 Then message = message & vbNewLine & sourcePath
		compressedFiles = True
	End If
Loop
outStream.Close
If Not compressedFiles Then FSO.DeleteFile(ddfFile & ".ddf")
REM Wscript.Echo "SourceDir = " & session.Property("SourceDir")
' If Not IsEmpty(message) Then Fail "The following files were not available:" & message

' Generate compressed file cabinet
If makeCab Then
	Dim WshShell : Set WshShell = Wscript.CreateObject("Wscript.Shell") : CheckError
	Dim cabStat : cabStat = WshShell.Run("MakeCab.exe /f " & ddfFile & ".ddf", 7, True) : CheckError
	If cabStat <> 0 Then Fail "MAKECAB.EXE failed, possibly could not find source files, or invalid DDF format"
End If

' Update Media table and SummaryInformation if requested
If updateMsi Then
	Set view = database.OpenView("SELECT DiskId FROM Media ORDER BY DiskId") : CheckError
	view.Execute : CheckError
	Do
		Set record = view.Fetch : CheckError
		If record Is Nothing Then Exit Do
		lastDisk = record.IntegerData(1)
	Loop
	Set view = database.OpenView("SELECT DiskId, LastSequence, Cabinet FROM Media WHERE DiskId=" & lastDisk) : CheckError
	view.Execute : CheckError
	updateMode = msiViewModifyUpdate
	Set record = view.Fetch : CheckError
	If record Is Nothing Then ' Media table empty
		Set record = Installer.CreateRecord(3)
		record.IntegerData(1) = 1
		updateMode = msiViewModifyInsert
	End If
'	record.IntegerData(2) = lastSequence
'	record.StringData(3) = cabName
'	view.Modify updateMode, record
	Set sumInfo = database.SummaryInformation(3) : CheckError
'	sumInfo.Property(11) = Now
'	sumInfo.Property(13) = Now
	sumInfo.Property(15) = (shortNames And 1) + 2
	sumInfo.Persist
End If

' Embed cabinet if requested
If embedCab Then
	Set view = database.OpenView("SELECT `Name`,`Data` FROM _Streams") : CheckError
	view.Execute : CheckError
	Set record = Installer.CreateRecord(2)
	record.StringData(1) = cabFile
	record.SetStream 2, cabFile : CheckError
	view.Modify msiViewModifyAssign, record : CheckError 'replace any existing stream of that name
End If

' Commit database in case updates performed
database.Commit : CheckError
Wscript.Quit 0

' Extract argument value from command line, processing any option flags
Function NextArgument
	Dim arg
	Do  ' loop to pull in option flags until an argument value is found
		If iArg >= argCount Then Exit Function
		arg = Wscript.Arguments(iArg)
		iArg = iArg + 1
		If (AscW(arg) <> AscW("/")) And (AscW(arg) <> AscW("-")) Then Exit Do
		Select Case UCase(Right(arg, Len(arg)-1))
			Case "C" : makeCab      = True
			Case "E" : embedCab     = True
			Case "F" : cabSize      = "1.44M"
			Case "L" : compressType = "LZX"
			Case "R" : removeCab    = True
			Case "S" : sequenceFile = True
			Case "U" : updateMsi    = True
			Case Else: Wscript.Echo "Invalid option flag:", arg : Wscript.Quit 1
		End Select
	Loop
	NextArgument = arg
End Function

Sub CheckError
	Dim message, errRec
	If Err = 0 Then Exit Sub
	message = Err.Source & " " & Hex(Err) & ": " & Err.Description
	If Not installer Is Nothing Then
		Set errRec = installer.LastErrorRecord
		If Not errRec Is Nothing Then message = message & vbNewLine & errRec.FormatText
	End If
	Fail message
End Sub

Sub Fail(message)
	Wscript.Echo message
	Wscript.Quit 2
End Sub

Sub UndupSequence
	Set view = database.OpenView("SELECT Sequence,Attributes FROM File ORDER BY Sequence") : CheckError
	view.Execute : CheckError
	Do
		Set record = view.Fetch : CheckError
		If record Is Nothing Then Exit Do
'		sequence = record.IntegerData(1)
		If (record.IntegerData(2) And msidbFileAttributesReadOnly) <> 0 Then
			lastSequence = lastSequence + 1
			record.IntegerData(1) = lastSequence
			view.Modify msiViewModifyUpdate, record
		End If
	Loop
	Dim loopSequence, loopAttributes, fileKey, attributes, pseudo
	loopSequence = 1
	fileKey = "pseudo"
	Set view = database.OpenView("SELECT File,Sequence,Attributes FROM File ORDER BY Sequence") : CheckError
	view.Execute : CheckError
	Do
		Set record = view.Fetch : CheckError
		If record Is Nothing Then Exit Do
		sequence = record.IntegerData(2)
		attributes = record.IntegerData(3)
		pseudo = record.StringData(1)
		If sequence = loopSequence Then
			lastSequence = lastSequence + 1
			If attributes >= loopAttributes Then
				record.IntegerData(2) = lastSequence
				view.Modify msiViewModifyUpdate, record
			Else
				updateSequence fileKey, lastSequence
			End If
		End If
		loopSequence = sequence
		loopAttributes = attributes
		fileKey = record.StringData(1)
	Loop
End Sub

Sub updateSequence(fileKey, fileSequence)
	Dim query
	query = "UPDATE `File` SET Sequence = " & fileSequence & " WHERE `File` = '" & fileKey & "'"
	Set ddfView = database.OpenView(query) : CheckError
	ddfView.Execute : CheckError
	ddfView.Close
End Sub

Sub MediaSequence
	Set ddfView = database.OpenView("SELECT DiskId FROM Media ORDER BY DiskId") : CheckError
	ddfView.Execute : CheckError
	Do
		Set ddfRecord = ddfView.Fetch : CheckError
		If ddfRecord Is Nothing Then Exit Do
		lastDisk = ddfRecord.IntegerData(1)
	Loop
	Set ddfView = database.OpenView("SELECT DiskId, LastSequence FROM Media WHERE DiskId=" & lastDisk) : CheckError
	ddfView.Execute : CheckError
	Set ddfRecord = ddfView.Fetch : CheckError
	ddfRecord.IntegerData(2) = lastSequence
	ddfView.Modify msiViewModifyUpdate, ddfRecord
	database.Commit : CheckError
End Sub

Sub outFileDDF
	Set FileSys = CreateObject("Scripting.FileSystemObject") : CheckError
	Set outStream = FileSys.CreateTextFile(ddfFile & ".ddf", OverwriteIfExist, OpenAsASCII) : CheckError
'	outStream.WriteLine ".Set Cabinet=ON"
'	outStream.WriteLine ".Set Compress=ON"
'	outStream.WriteLine ".Set CompressionType=" & compressType
'	outStream.WriteLine ".Set CompressionLevel=7"
'	outStream.WriteLine ".Set CompressionMemory=21"
'	outStream.WriteLine ".Set CabinetFileCountThreshold=0"
'	outStream.WriteLine ".Set FolderFileCountThreshold=0"
'	outStream.WriteLine ".Set FolderSizeThreshold=1000000"
'	outStream.WriteLine ".Set MaxCabinetSize=0"
'	outStream.WriteLine ".Set MaxDiskFileCount=0"
'	outStream.WriteLine ".Set MaxDiskSize=0"
'	outStream.WriteLine ".Set ReservePerCabinetSize=0"
'	outStream.WriteLine ".Set ReservePerDataBlockSize=0"
'	outStream.WriteLine ".Set ReservePerFolderSize=0"
'	outStream.WriteLine ".Set UniqueFiles=OFF"
'	outStream.WriteLine ".Set RptFileName=nul"
'	outStream.WriteLine ".Set InfFileName=nul"
'	outStream.WriteLine ".Set DiskDirectoryTemplate=."
'	outStream.WriteLine ".Set DiskDirectory1=."
'	outStream.WriteLine ".Set CabinetNameTemplate=" & cabFile
End Sub
