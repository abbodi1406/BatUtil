' script by dumpydooby (modded by ricktendo64)
Option Explicit
Dim installer, fs, db, view, record, x
Set fs = CreateObject("Scripting.FileSystemObject")
Set installer = WScript.CreateObject("WindowsInstaller.Installer") : CheckError
Dim dir : dir = Mid(WScript.ScriptFullName, 1, (Len(WScript.ScriptFullName) - Len(WScript.ScriptName)))
If WScript.Arguments.Count <> 0 Then
	For each x in WScript.Arguments
		ProcessMSI x
	Next
End If
'**********************************************************************
'** Function; Query MSI database                                     **
'**********************************************************************
Function QueryDatabase(arrOpts)
	On Error Resume Next
	Dim query, file, binary : binary = false
	If LCase(TypeName(arrOpts)) = "string" Then
		query = arrOpts
	Else
		If fs.FileExists(arrOpts(0)) Then
			file = arrOpts(0)
			query = arrOpts(1)
		Else
			query = arrOpts(0)
			file = arrOpts(1)
		End If
		binary = true
	End If
'	WScript.Echo query
	If binary Then
		Set record = installer.CreateRecord(1)
		record.SetStream 1, file
	End If
	Set view = db.OpenView (query) : CheckError
	If binary Then
		view.Execute record : CheckError
	Else
		view.Execute : CheckError
	End If
	view.close
	Set view = nothing
	If binary Then Set record = nothing
	binary = false
'	db.commit : CheckError
End Function
'**********************************************************************
'** Subroutine; Check errors in most recently executed MSI command   **
'**********************************************************************
Sub CheckError
	Dim message, errRec
	If Err = 0 Then Exit Sub
	message = Err.Source & " " & Hex(Err) & ": " & Err.Description
	If Not installer Is Nothing Then
		Set errRec = installer.LastErrorRecord
		If Not errRec Is Nothing Then message = message & vbNewLine & errRec.FormatText
	End If
	Wscript.Echo "" : Wscript.Echo message : Wscript.Echo ""
	Wscript.Quit 2
End Sub
'**********************************************************************
'** Function; Push changes to MSI                                    **
'**********************************************************************
Function ProcessMSI(file)
	Set db = installer.OpenDatabase(file, 1) : CheckError
	On Error Resume Next
	QueryDatabase("CREATE TABLE `AdminExecuteSequence` (`Action` CHAR(72) NOT NULL, `Condition` CHAR(255), `Sequence` INTEGER PRIMARY KEY `Action`)") 
	QueryDatabase("INSERT INTO `AdminExecuteSequence` (`Action`,`Condition`,`Sequence`) VALUES ('CostInitialize',NULL,800)") 
	QueryDatabase("INSERT INTO `AdminExecuteSequence` (`Action`,`Condition`,`Sequence`) VALUES ('CostFinalize',NULL,900)") 
	QueryDatabase("INSERT INTO `AdminExecuteSequence` (`Action`,`Condition`,`Sequence`) VALUES ('FileCost',NULL,1000)") 
	QueryDatabase("INSERT INTO `AdminExecuteSequence` (`Action`,`Condition`,`Sequence`) VALUES ('InstallValidate',NULL,1300)") 
	QueryDatabase("INSERT INTO `AdminExecuteSequence` (`Action`,`Condition`,`Sequence`) VALUES ('InstallInitialize',NULL,1400)") 
	QueryDatabase("INSERT INTO `AdminExecuteSequence` (`Action`,`Condition`,`Sequence`) VALUES ('InstallAdminPackage',NULL,3900)") 
	QueryDatabase("INSERT INTO `AdminExecuteSequence` (`Action`,`Condition`,`Sequence`) VALUES ('InstallFiles',NULL,4000)") 
	QueryDatabase("INSERT INTO `AdminExecuteSequence` (`Action`,`Condition`,`Sequence`) VALUES ('InstallFinalize',NULL,8000)") 
	db.commit : CheckError
	Set db = nothing
End Function