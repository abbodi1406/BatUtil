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
If NOT Mid(sProductCode, 4, 2) = "16" Then Wscript.Quit 1

Set oReg      = GetObject("winmgmts:\\.\root\default:StdRegProv")
Set oWSh      = CreateObject("WScript.Shell")
Set oFso      = CreateObject("Scripting.FileSystemObject")

Dim sPatchCode, sProductCC, sPatchCC, sRegPatch1, sRegPatch2, sRegClasses, sRegCurrent, sPatchesCC, sPatchProperty, foundPatches, arrUpper, arrLower

' applied patches to check against
arrUpper = Array()
AddItem arrUpper, "B8286A7D_6B6F_4F1C_8625_BE29AD5F6B69" : AddItem arrUpper, "AC7565EF_E108_49D4_9F46_5A1AEC72B27B" ' lync_kb5002567
AddItem arrUpper, "89269927_54F4_4298_88B5_1D443B817591" : AddItem arrUpper, "EC09F6B2_325C_4E28_B51D_967F010140BE" ' onenote_kb5002761
AddItem arrUpper, "641B1AD9_C24A_4E5A_840B_A44F9AA5F64D" : AddItem arrUpper, "6457D29F_8B18_4085_8512_3BFFC9815A29" ' outlook_kb5002747
AddItem arrUpper, "CDB13E57_DC07_4DD1_99A6_1F1B89F3671F" : AddItem arrUpper, "FC118D77_E399_4BD1_BA89_03675D9E7CE8" ' osetup_kb4032254
AddItem arrUpper, "3A63F354_2C57_4D83_8393_8F35675B68FE" : AddItem arrUpper, "99F237BE_40BE_48F7_B7F9_86D8393BF294" ' riched20_kb5002466
AddItem arrUpper, "612503BC_1C5B_4AC2_9503_681BC48087E6" : AddItem arrUpper, "81D6DC5B_D707_4D4F_9B80_D780D6E292CF" ' vbe7_kb5002251

' superseded patches to register
arrLower = Array()
AddItem arrLower, "88C3EC32_7F1A_4A1D_A685_B3C892A7B615" : AddItem arrLower, "D1030839_331B_4847_B3E8_BA9F9CB19037" ' lync_kb5002181
AddItem arrLower, "E8C31778_563F_4015_9E7C_DACCF7926F43" : AddItem arrLower, "BE062AE4_F1BC_4ABB_97EE_899DE28978BA" ' onenote_kb5002622
AddItem arrLower, "1DD87E8E_4984_4379_B2C7_9742F035BEC9" : AddItem arrLower, "C5521F8D_6209_415B_AAA4_34A64E7F95DF" ' outlook_kb5002683
AddItem arrLower, "DCB15A3A_EB74_4172_B603_AC35A788BB7D" : AddItem arrLower, "9CF53FC4_FDC8_46D4_980F_AF8851E5EA57" ' osetup_kb4022172
AddItem arrLower, "C43707D1_EB3E_4337_A72A_4E0871542C8B" : AddItem arrLower, "786E845F_3515_4ACE_9BAF_A42AD1A6FFFF" ' riched20_kb5002058
AddItem arrLower, "C2D7565B_C52D_4D86_89CE_93C2236EF4A7" : AddItem arrLower, "0D9929D7_8E8C_43E1_86C0_6A68A8DA4638" ' vbe7_kb5002112

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
