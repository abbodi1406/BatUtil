If Wscript.Arguments.Count = 0 Then Wscript.Quit 1

'On Error Resume Next
Dim oXML, sXPath, ndFnd, ndObj, ndNew, sXmlFile, lcid
Set oXML = CreateObject("Msxml2.DOMDocument.6.0")

sXmlFile = Wscript.Arguments(0)

lcid = "1033"
If Wscript.Arguments.Count >= 2 Then lcid = Wscript.Arguments(1)

oXML.load(sXmlFile)

If UCase(sXmlFile) = "SETUP.XML" Then
	sXPath = "/Setup/LocalCache/File"
	Set ndFnd = oXML.selectNodes(sXPath)
	For Each ndObj in ndFnd
		If ndObj.getAttribute("Id") = "GrooveMUISet.msi" Then
			Set ndNew = ndObj.cloneNode(False)
			ndNew.setAttribute "Id", "GrMUISet.cab"
			ndNew.setAttribute "RelativeCachePath", "GrMUISet.cab"
			ndNew.setAttribute "RelativeSourcePath", "GrMUISet.cab"
			ndObj.parentNode.insertBefore ndNew, ndObj.nextSibling
		End If
	Next
Else
	sXPath = "/Package/Feature"
	Set ndFnd = oXML.selectNodes(sXPath)
	For Each ndObj in ndFnd
		If ndObj.getAttribute("Id") = "SetupControllerFiles" Then
			Set ndNew = ndObj.cloneNode(True)
			ndNew.setAttribute "Id", "GrooveFilesIntl_" & lcid
			ndNew.setAttribute "Cost", "3390081"
			ndNew.firstChild.setAttribute "Id", "GrooveFiles"
			ndObj.parentNode.insertBefore ndNew, ndObj.nextSibling
		End If
	Next
End If

oXML.save sXmlFile
