Option Explicit

If Wscript.Arguments.Count = 0 Then Wscript.Quit 1

'On Error Resume Next
Dim oMsi : Set oMsi = Nothing
Set oMsi = Wscript.CreateObject("WindowsInstaller.Installer") : If CheckError("MSI.DLL not registered") Then Wscript.Quit 2

Dim propList(19)
propList( 3) = "Subject"
propList( 6) = "Comments"
propList( 9) = "Revision"

Dim sumInfo, iProp, value
Set sumInfo = oMsi.SummaryInformation(Wscript.Arguments(0), 0) : If CheckError(Empty) Then Wscript.Quit 2
For iProp = 3 to 9 Step 3
	value = sumInfo.Property(iProp) : CheckError(Empty)
	If Not IsEmpty(value) Then Wscript.Echo propList(iProp) & "=" & value
Next
Wscript.Quit 0

Function CheckError(message)
	If Err = 0 Then Exit Function
	If IsEmpty(message) Then message = Err.Source & " " & Hex(Err) & ": " & Err.Description
	If Not installer Is Nothing Then
		Dim errRec : Set errRec = installer.LastErrorRecord
		If Not errRec Is Nothing Then message = message & vbNewLine & errRec.FormatText
	End If
	Wscript.Echo message
	CheckError = True
	Err.Clear
End Function
