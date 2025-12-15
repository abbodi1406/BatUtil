If Wscript.Arguments.Count = 0 Then Wscript.Quit 1

'On Error Resume Next
Dim oXML, sXPath, ndFnd, ndObj, sXmlFile, vMSI
Set oXML = CreateObject("Msxml2.DOMDocument.6.0")

sXmlFile = Wscript.Arguments(0)

vMSI = "14.0.7015.1000"
If Wscript.Arguments.Count >= 2 Then vMSI = Wscript.Arguments(1)

oXML.load(sXmlFile)

If UCase(sXmlFile) = "SETUP.XML" Then
	sXPath = "/Setup/LocalCache/File"
	Set ndFnd = oXML.selectNodes(sXPath)
	For Each ndObj in ndFnd
		ndObj.getAttributeNode("MD5").value = ""
		ndObj.getAttributeNode("Size").value = ""
	Next
Else
	sXPath = "/Package"
	Set ndFnd = oXML.selectSingleNode(sXPath)
	ndFnd.setAttribute "MSIVersion", vMSI
End If

oXML.save sXmlFile
