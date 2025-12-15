Option Explicit

If Wscript.Arguments.Count <= 1 Then Wscript.Quit 1

'On Error Resume Next
Dim oMsi : Set oMsi = Nothing
Set oMsi = Wscript.CreateObject("WindowsInstaller.Installer") : CheckError

Dim MsiDb, arrMSP, i, sPatchProperty
Set MsiDb = oMsi.OpenDatabase(Wscript.Arguments(0), 1) : CheckError
arrMSP = Split(Wscript.Arguments(1), ";")

For i = 0 To UBound(arrMSP)
	If Len(arrMSP(i)) > 0 Then
		AddProperty oMsi.SummaryInformation(arrMSP(i), 0).Property(9)
	End If
Next

MsiDb.Commit : CheckError
Wscript.Quit 0

Sub AddProperty(sPatchCode)
	If Not Len(sPatchCode) = 38 Then Exit Sub
	sPatchProperty = ""
	sPatchProperty = "Patch._" & Replace(Mid(sPatchCode, 2, 36), "-", "_") & "_.isMinorUpgrade"
	QueryDatabase "INSERT INTO `Property` (`Property`,`Value`) VALUES ('"&sPatchProperty&"','0')"
End Sub

Sub QueryDatabase(query)
	On Error Resume Next
	Dim dbView
	Set dbView = MsiDb.OpenView(query) : CheckError
	dbView.Execute : CheckError
	'dbView.Close
	'Set dbView = Nothing
End Sub

Sub CheckError
	Dim message, errRec
	If Err = 0 Then Exit Sub
	message = Err.Source & " " & Hex(Err) & ": " & Err.Description
	If Not oMsi Is Nothing Then
		Set errRec = oMsi.LastErrorRecord
		If Not errRec Is Nothing Then message = message & vbNewLine & errRec.FormatText
	End If
	Fail message
End Sub

Sub Fail(message)
	Wscript.Echo message
	Wscript.Quit 2
End Sub
