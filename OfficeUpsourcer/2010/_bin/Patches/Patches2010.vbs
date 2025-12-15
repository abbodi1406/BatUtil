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
If NOT Mid(sProductCode, 4, 2) = "14" Then Wscript.Quit 1

Set oReg      = GetObject("winmgmts:\\.\root\default:StdRegProv")
Set oWSh      = CreateObject("WScript.Shell")
Set oFso      = CreateObject("Scripting.FileSystemObject")

Dim sPatchCode, sProductCC, sPatchCC, sRegPatch1, sRegPatch2, sRegClasses, sRegCurrent, sPatchesCC, sPatchProperty, foundPatches, arrUpper, arrLower

' applied patches to check against
arrUpper = Array()
AddItem arrUpper, "9C9636BD_37A7_43F7_BB00_5C7606B42D27" : AddItem arrUpper, "75A4ACD6_A407_41B3_8889_8AB7862A9D9D" ' KB3054873 fm20
AddItem arrUpper, "0D1184D7_5508_4BB9_B1E8_9634D3151BA8" : AddItem arrUpper, "805D24CF_299F_4F85_ABBA_E0F8B41F2398" ' KB2760787 gfx
AddItem arrUpper, "D336721D_4E01_43A0_A10D_843A5D9382DD" : AddItem arrUpper, "34E3E597_14CF_46A5_B02C_E40F2C3FAEEF" ' KB4462187 oartconv
AddItem arrUpper, "32D844E0_6696_4FAC_AB73_7D9C459F929C" : AddItem arrUpper, "ED7A5337_C4D3_455F_8B84_E90FB9605977" ' KB4462172 oart
AddItem arrUpper, "81552592_6945_4622_8D53_341B6D95FF07" : AddItem arrUpper, "6E14E5FA_BB3A_4583_B77E_87284B73AD16" ' KB4461626 offowc
AddItem arrUpper, "C6943CC4_79E1_4B29_BFF7_8C4049C7DF61" : AddItem arrUpper, "2F7967D2_535C_4D3A_AEE8_CC9C204E7586" ' KB3115475 outlfltr
AddItem arrUpper, "BA610006_2C39_4419_9834_CF61AB24810A" : AddItem arrUpper, "43F59F4D_7179_497E_BE99_BC6F7D1DDCBA" ' KB2825640 targetdir
AddItem arrUpper, "FB885E93_253E_447A_86D9_F146A08532D2" : AddItem arrUpper, "6C7AE074_5411_4DB8_B9A3_8F7A6F046771" ' KB4504738 mso
AddItem arrUpper, "3BC4E4F4_8667_4CAA_B80C_3D524640261A" : AddItem arrUpper, "3935073D_AED7_4467_B884_CAA9680F90AB" ' KB4504702 powerpoint
AddItem arrUpper, "3BC4E4F4_8667_4CAA_B80C_3D524640261A" : AddItem arrUpper, "3935073D_AED7_4467_B884_CAA9680F90AB" ' KB4504702 powerpoint
AddItem arrUpper, "90AA654B_0DD6_4AA2_B5EF_46438BC152D4" : AddItem arrUpper, "46BA48B6_73B5_41AE_992B_5B073F035616" ' KB4484463 project
AddItem arrUpper, "212269AF_6D62_4C0D_BA42_531147FD7C9E" : AddItem arrUpper, "B9582F02_1DFC_4E97_AAE5_FD4F08527C15" ' KB4484376 visio
AddItem arrUpper, "59DC7294_A36A_4132_BFB5_84C6191BAC0F" : AddItem arrUpper, "565C3C1B_B400_4DB6_B58B_589C66433C23" ' KB4493218 word
AddItem arrUpper, "810163C2_A40C_46FA_98E8_82B2345A8713" : AddItem arrUpper, "DAE04899_878D_409E_80EE_20F307CEE5EE" ' KB2878231 groove
AddItem arrUpper, "2EBD57C2_A05E_45A0_9836_C30E95FA5498" : AddItem arrUpper, "5D24EA31_2228_4F0A_B054_754F7004A018" ' KB2881023 spd

' superseded patches to register
arrLower = Array()
AddItem arrLower, "D0D69BA5_4BD9_439E_804F_07DC80CF5408" : AddItem arrLower, "71124CBD_B674_47A1_BE96_31E50DED480F" ' KB2553154 fm20
AddItem arrLower, "DADF7E25_FFA4_4D02_BE84_1DAE62C18516" : AddItem arrLower, "79C725A1_3964_421C_A528_78C1C083C7C7" ' KB2589298 gfx
AddItem arrLower, "EB272A58_A562_4497_8ADB_8FEDFEF7D61C" : AddItem arrLower, "A175EF1A_A9B5_4FBB_A330_20865A1F53D2" ' KB3115248 oartconv
AddItem arrLower, "B555A082_6EFC_4557_9AA4_6B975B1F4D41" : AddItem arrLower, "AB19BB14_3EC4_4BD7_ACBC_39C6D1858344" ' KB3115197 oart
AddItem arrLower, "4B6D234B_CA9C_4E50_8708_C38FCA727BA0" : AddItem arrLower, "9F63074D_41CE_438C_B0C6_23661590CB15" ' KB3213636 offowc
AddItem arrLower, "6BDEB2BD_7C8B_4734_9E2F_E9EDC9D6C844" : AddItem arrLower, "B32293B8_7C13_4897_B155_0D71C0B60541" ' KB982726  outlfltr
AddItem arrLower, "7AC49FC8_F8D2_4DD8_9086_09E52385A21F" : AddItem arrLower, "E636FE63_842B_4F4B_9884_DA189ACC0B91" ' KB2553092 targetdir
AddItem arrLower, "79414F7A_FA37_401E_9B33_954D99EDA7D9" : AddItem arrLower, "7DBA8DD8_957E_413E_B530_1AFAF66D2F32" ' KB2956076 mso
AddItem arrLower, "3491A66B_D03B_491E_93CA_BC7EBBEA5299" : AddItem arrLower, "34F13650_374B_49C1_869E_9FEA28C2305A" ' KB4092435 powerpoint
AddItem arrLower, "2D51BC4D_6979_4591_B63E_BA25C1289D30" : AddItem arrLower, "78CF6761_122D_43E6_9019_7F8E538740C1" ' KB2920812 powerpoint
AddItem arrLower, "481D6E1A_7009_49DC_AE4B_A3680A6C8347" : AddItem arrLower, "AD67AEC5_63C4_4411_A8AC_1EB86BD76ED1" ' KB3054882 project
AddItem arrLower, "8764EC2A_9F51_483B_9E00_82806B6A6909" : AddItem arrLower, "1EEF18FB_974F_4D48_86D0_A91ADDE444A6" ' KB2881025 visio
AddItem arrLower, "944F46EC_64FF_4C06_9C15_99F2B2E6D774" : AddItem arrLower, "CBF017CD_1E86_44B0_A626_C65C1AD8031F" ' KB4461625 word
AddItem arrLower, "F9F5A080_AF38_4966_9A6B_C43DCA465035" : AddItem arrLower, "77374F16_2DC6_4EEF_AFAD_C59FDA2E010D" ' KB2760601 groove
AddItem arrLower, "51B8C53C_06B4_40C8_88EE_95B957970683" : AddItem arrLower, "6306282F_2999_4A25_A86E_35839B25E008" ' KB2810069 spd

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
