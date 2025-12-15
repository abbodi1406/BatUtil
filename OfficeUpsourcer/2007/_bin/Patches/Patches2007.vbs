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

Dim oFso, oReg, oWSh, oMsi, MsiDb, sMsiFile, dbView, record, sProductCode, sWI, fMSP

sMsiFile = Wscript.Arguments(0)
Set oMsi      = CreateObject("WindowsInstaller.Installer")
Set MsiDb = oMsi.OpenDatabase(sMsiFile, msiOpenDatabaseModeReadOnly) : CheckError

sProductCode = GetMsiProductCode
If NOT UCase(Right(sProductCode, PRODLEN)) = OFFICEID Then Wscript.Quit 1
If NOT Mid(sProductCode, 4, 2) = "12" Then Wscript.Quit 1

Set oReg      = GetObject("winmgmts:\\.\root\default:StdRegProv")
Set oWSh      = CreateObject("WScript.Shell")
Set oFso      = CreateObject("Scripting.FileSystemObject")

Dim sPatchCode, sProductCC, sPatchCC, sRegPatch1, sRegPatch2, sRegClasses, sRegCurrent, sPatchesCC, sPatchProperty, foundPatches, arrUpper, arrLower

' applied patches to check against
arrUpper = Array()
AddItem arrUpper, "7C3337E5_1294_4270_A64F_DCEF812159E5" ' KB2965286 fm20
AddItem arrUpper, "8C829BE5_F60C_417A_89E3_9A1B427320F2" ' KB3115461 outlfltr
AddItem arrUpper, "8C829BE5_F60C_417A_89E3_9A1B427320F2" ' KB3115461 outlfltr
AddItem arrUpper, "962B4B3F_E8E5_4E11_B64B_1885D7F41BAA" ' KB4011203 publisher
AddItem arrUpper, "D37A5B38_870F_4B82_A7C9_FB056BBBF83F" ' KB4092465 mso
AddItem arrUpper, "8B3849F5_2C5E_42E3_9887_8AC3B1FE5D31" ' KB4092444 ogl
AddItem arrUpper, "DE92D01A_C9E9_487C_85F7_4710C08336DE" ' KB4461607 xlconv

' superseded patches to register
arrLower = Array()
AddItem arrLower, "2A3B9143_BE46_4784_A88F_655833F0AE18" ' KB2596927 fm20
AddItem arrLower, "9492511E_2CE0_4904_9400_203F44E1DC0D" ' KB2825642 outlfltr
AddItem arrLower, "2720451F_5D04_43EC_AB1F_26D948FD971B" ' KB2880505 outlfltr
AddItem arrLower, "B2EC175F_19B8_48F7_9196_ABFDADD98EDF" ' KB3114428 publisher
AddItem arrLower, "8711951B_FD11_4309_BD11_8A19551CEBC9" ' KB4011715 mso
AddItem arrLower, "F5E44FF6_5802_4FCC_B0CA_6C2C0C455CA3" ' KB3213641 ogl
AddItem arrLower, "5C007116_E724_483B_BE67_870B5DB121A5" ' KB4011717 xlconv

sPatchesCC = Array()
sProductCC = ""
sProductCC = GetCompressedGuid(sProductCode)
'sRegClasses = "Installer\Products\"&sProductCC&"\Patches"
sRegCurrent = "Software\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\"&sProductCC&"\Patches"

sWI = oWSh.ExpandEnvironmentStrings("%SYSTEMROOT%\Installer") & "\"
fMSP = LCase(Mid(sProductCC,5,2) & Mid(sProductCC,9,3) & Mid(sProductCC,13,3)) & ".msp"

oReg.CreateKey HKLM, sRegCurrent

foundPatches = False
Set dbView = MsiDb.OpenView("SELECT `Property` FROM `Property`") : CheckError
dbView.Execute : CheckError
Do
	Set record = dbView.Fetch : CheckError
	If record Is Nothing Then Exit Do
	sPatchProperty = ""
	sPatchProperty = record.StringData(1)
	If InStr(1, sPatchProperty, "Patch._", vbTextCompare) > 0 Then
		foundPatches = True
		AddPatch Mid(sPatchProperty, 8, 36)
		AddExtra Mid(sPatchProperty, 8, 36)
	End If
Loop
dbView.Close

If foundPatches Then
	Wscript.Echo "Processing: " & sMsiFile
'	oReg.CreateKey HKCR, sRegClasses
'	oReg.SetMultiStringValue HKCR, sRegClasses , "Patches", sPatchesCC
	oReg.SetMultiStringValue HKLM, sRegCurrent , "AllPatches", sPatchesCC
	If Not oFso.FileExists(sWI & fMSP) Then
		If oFso.FileExists(sWI & "fffff.msp") Then
			oFso.CopyFile sWI & "fffff.msp", sWI & fMSP, True
		End If
	End If
End If

Wscript.Quit 0

Sub AddPatch(sPatchProperty)
	sPatchCode = ""
	sPatchCode = "{" & Replace(sPatchProperty, "_", "-") & "}"
	sPatchCC = ""
	sPatchCC = GetCompressedGuid(sPatchCode)
	sRegPatch1 = sRegCurrent&"\"&sPatchCC
	sRegPatch2 = "Software\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Patches\"&sPatchCC
	AddItem sPatchesCC, sPatchCC

	oReg.CreateKey HKLM, sRegPatch1
	oReg.CreateKey HKLM, sRegPatch2
	oReg.SetDWordValue  HKLM, sRegPatch1, "State", 1
	oReg.SetDWordValue  HKLM, sRegPatch1, "Uninstallable", 1
	oReg.SetDWordValue  HKLM, sRegPatch1, "MSI3", 1
	oReg.SetDWordValue  HKLM, sRegPatch1, "PatchType", 0
	oReg.SetDWordValue  HKLM, sRegPatch1, "LUAEnabled", 0
	oReg.SetStringValue HKLM, sRegPatch2, "LocalPackage", sWI & fMSP
End Sub

Sub AddExtra(sPatchProperty)
	Dim i
	For i = 0 To UBound(arrUpper)
	  If UCase(sPatchProperty) = arrUpper(i) Then AddPatch arrLower(i)
	Next
End Sub

Sub AddItem(arr, val)
	ReDim Preserve arr(UBound(arr) + 1)
	arr(UBound(arr)) = val
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
