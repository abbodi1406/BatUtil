Option Explicit

If Wscript.Arguments.Count = 0 Then Wscript.Quit 1

'On Error Resume Next

Const msiOpenDatabaseModeReadOnly = 0
Const msiOpenDatabaseModeTransact = 1
Const OFFICEID      = "000000FF1CE}"
Const PRODLEN       = 12
Const HKCR          = &H80000000
Const HKCU          = &H80000001
Const HKLM          = &H80000002

Dim oFso, oReg, oWSh, oMsi, MsiDb, sMsiFile, dbView, record, sProductCode

sMsiFile = Wscript.Arguments(0)
Set oMsi      = CreateObject("WindowsInstaller.Installer")
Set MsiDb = oMsi.OpenDatabase(sMsiFile, msiOpenDatabaseModeReadOnly) : CheckError

sProductCode = GetMsiProductCode
If NOT UCase(Right(sProductCode, PRODLEN)) = OFFICEID Then Wscript.Quit 1
If NOT Mid(sProductCode, 4, 2) = "16" Then Wscript.Quit 1

Set oReg      = GetObject("winmgmts:\\.\root\default:StdRegProv")
Set oWSh      = CreateObject("WScript.Shell")
Set oFso      = CreateObject("Scripting.FileSystemObject")

Dim sPatchCode, sProductCC, sPatchCC, sRegPatch1, sRegPatch2, sRegClasses, sRegCurrent, sRegPatches, sPatchesCC, sPatchProperty, aSubKeys, sSubKey, OutVal

sPatchesCC = Array()
sProductCC = ""
sProductCC = GetCompressedGuid(sProductCode)
sRegClasses = "Installer\Products\"&sProductCC&"\Patches"
sRegCurrent = "Software\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\"&sProductCC&"\Patches"
sRegPatches = "Software\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Patches"

If oReg.EnumKey(HKLM, sRegCurrent, aSubKeys) = 0 And Not IsNull(aSubKeys) Then
	Wscript.Echo "Processing: " & sMsiFile
	For Each sSubKey In aSubKeys
		RemPatch sSubKey
	Next
	oReg.SetStringValue HKLM, sRegCurrent , "AllPatches", ""
End If

If oReg.EnumKey(HKCR, sRegClasses, OutVal) = 0 Then oReg.DeleteKey HKCR, sRegClasses

Wscript.Quit 0

Sub RemPatch(sPatchCC)
	sRegPatch1 = sRegCurrent&"\"&sPatchCC
	If oReg.EnumKey(HKLM, sRegPatch1, OutVal) = 0 Then oReg.DeleteKey HKLM, sRegPatch1
	sRegPatch2 = sRegPatches&"\"&sPatchCC
	If oReg.EnumKey(HKLM, sRegPatch2, OutVal) = 0 Then oReg.DeleteKey HKLM, sRegPatch2
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

Function GetMsiProductCode
	GetMsiProductCode = ""
	Dim qView
	Set qView = MsiDb.OpenView("SELECT `Value` FROM Property WHERE `Property` = 'ProductCode'") : CheckError
	qView.Execute : CheckError
	Set record = qView.Fetch : CheckError
	GetMsiProductCode = record.StringData(1)
	qView.Close
End Function

Function GetCompressedGuid(sGuid)
	If NOT Len(sGuid) = 38 Then Exit Function
	Dim sCompGUID
	Dim i
	sCompGUID = StrReverse(Mid(sGuid, 2, 8))  & _
				StrReverse(Mid(sGuid, 11, 4)) & _
				StrReverse(Mid(sGuid, 16, 4)) 
	For i = 21 To 24
		If i Mod 2 Then
			sCompGUID = sCompGUID & Mid(sGuid, (i + 1), 1)
		Else
			sCompGUID = sCompGUID & Mid(sGuid, (i - 1), 1)
		End If
	Next
	For i = 26 To 37
		If i Mod 2 Then
			sCompGUID = sCompGUID & Mid(sGuid, (i - 1), 1)
		Else
			sCompGUID = sCompGUID & Mid(sGuid, (i + 1), 1)
		End If
	Next
	GetCompressedGuid = sCompGUID
End Function
