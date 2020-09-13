#include "wd_core.au3"
#include "wd_helper.au3"
#include <GuiComboBoxEx.au3>
#include <GUIConstantsEx.au3>
#include <ButtonConstants.au3>
#include <WindowsConstants.au3>

Local Const $sElementSelector = "//input[@name='q']"

Local $sDesiredCapabilities, $iIndex, $sSession
Local $nMsg, $lProcess = False

Local $aBrowsers[][2] = [["Firefox", SetupGecko], _
						["Chrome", SetupChrome], _
						["Edge", SetupEdge]]

Local $aDemoSuite[][2] = [["DemoTimeouts", False], _
						["DemoNavigation", True], _
						["DemoElements", False], _
						["DemoScript", False], _
						["DemoCookies", False], _
						["DemoAlerts", False], _
						["DemoFrames", False], _
						["DemoActions", False], _
						["DemoDownload", False], _
						["DemoWindows", False], _
						["DemoUpload", False]]

Local $aDebugLevel[][2] = [["None", $_WD_DEBUG_None], _
							["Error", $_WD_DEBUG_Error], _
							["Full", $_WD_DEBUG_Info]]

Local $iSpacing = 50
Local $iCount = UBound($aDemoSuite)
Local $aCheckboxes[$iCount]

Local $hGUI = GUICreate("Webdriver Demo", 200, 150 + (20 * $iCount), 100, 200, BitXOR($GUI_SS_DEFAULT_GUI, $WS_MINIMIZEBOX))

GUICtrlCreateLabel("Browser", 15, 12)
Local $idBrowsers = GUICtrlCreateCombo("", 75, 10, 100, 20, $CBS_DROPDOWNLIST)
Local $sData = _ArrayToString($aBrowsers, Default, Default, Default, "|", 0, 0)
GUICtrlSetData($idBrowsers, $sData)
GUICtrlSetData($idBrowsers, $aBrowsers[0][0])

GUICtrlCreateLabel("Demos", 15, 52)
For $i = 0 To $iCount - 1
    $aCheckboxes[$i] = GUICtrlCreateCheckbox($aDemoSuite[$i][0], 70, $iSpacing + (20 * $i), 100, 17, BitOR($GUI_SS_DEFAULT_CHECKBOX, $BS_PUSHLIKE))
	If $aDemoSuite[$i][1] Then GUICtrlSetState($aCheckboxes[$i], $GUI_CHECKED)
Next

Local $iPos = $iSpacing + 20 * ($iCount + 1)
GUICtrlCreateLabel("Debug", 15, $iPos + 2)
Local $idDebugging = GUICtrlCreateCombo("", 75, $iPos, 100, 20, $CBS_DROPDOWNLIST)
$sData = _ArrayToString($aDebugLevel, Default, Default, Default, "|", 0, 0)
GUICtrlSetData($idDebugging, $sData)
GUICtrlSetData($idDebugging, "Full")
Local $idButton = GUICtrlCreateButton("Run Demo!", 60, $iPos + 40, 85, 25)

GUISetState(@SW_SHOW)

    While 1
		$nMsg = GUIGetMsg()
		Switch $nMsg
            Case $GUI_EVENT_CLOSE
                ExitLoop

			Case $idBrowsers

			Case $idDebugging

            Case $idButton
                $lProcess = True
				ExitLoop

		   Case Else
				For $i = 0 To $iCount - 1
					If $aCheckboxes[$i] = $nMsg Then
						$aDemoSuite[$i][1] = Not $aDemoSuite[$i][1]
						ExitLoop

					EndIf

				Next
        EndSwitch
    WEnd

; Set debug level
$_WD_DEBUG = $aDebugLevel[_GUICtrlComboBox_GetCurSel($idDebugging)][1]

; Execute browser setup routine for user's browser selection
Call($aBrowsers[_GUICtrlComboBox_GetCurSel($idBrowsers)][1])

GUIDelete($hGUI)
If Not $lProcess Then Exit

_WD_Startup()

If @error <> $_WD_ERROR_Success Then
	Exit -1
EndIf

$sSession = _WD_CreateSession($sDesiredCapabilities)

If @error = $_WD_ERROR_Success Then
	For $iIndex = 0 To UBound($aDemoSuite, $UBOUND_ROWS) - 1
		If $aDemoSuite[$iIndex][1] Then
			ConsoleWrite("+Running: " & $aDemoSuite[$iIndex][0] & @CRLF)
			Call($aDemoSuite[$iIndex][0])
			ConsoleWrite("+Finished: " & $aDemoSuite[$iIndex][0] & @CRLF)
		Else
			ConsoleWrite("Bypass: " & $aDemoSuite[$iIndex][0] & @CRLF)
		EndIf
	Next
EndIf

MsgBox($MB_ICONINFORMATION, "Demo complete!", "Click ok to shutdown the browser and console")

_WD_DeleteSession($sSession)
_WD_Shutdown()


Func DemoTimeouts()
	; Retrieve current settings and save
	Local $sResponse = _WD_Timeouts($sSession)
	Local $oJSON = Json_Decode($sResponse)
	Local $sTimouts = Json_Encode(Json_Get($oJSON, "[value]"))

	_WD_Navigate($sSession, "http://google.com")

	; Set page load timeout
	_WD_Timeouts($sSession, '{"pageLoad":2000}')

	; Retrieve current settings
	_WD_Timeouts($sSession)

	; This should timeout
	_WD_Navigate($sSession, "http://yahoo.com")

	; Restore initial settings
	_WD_Timeouts($sSession, $sTimouts)
EndFunc

Func DemoNavigation()
	_WD_Navigate($sSession, "http://google.com")
	_WD_NewTab($sSession)
	_WD_Navigate($sSession, "http://yahoo.com")
	_WD_NewTab($sSession, True, -1, 'http://bing.com', 'width=200,height=200')

	ConsoleWrite("URL=" & _WD_Action($sSession, 'url') & @CRLF)
	_WD_Attach($sSession, "google.com", "URL")
	ConsoleWrite("URL=" & _WD_Action($sSession, 'url') & @CRLF)
	_WD_Attach($sSession, "yahoo.com", "URL")
	ConsoleWrite("URL=" & _WD_Action($sSession, 'url') & @CRLF)
EndFunc

Func DemoElements()
	Local $sElement, $aElements, $sValue, $sButton, $sResponse, $bDecode, $sDecode, $hFileOpen

	_WD_Navigate($sSession, "http://google.com")

	; Locate a single element
	$sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, $sElementSelector)

	; Get element's coordinates
	$oERect = _WD_ElementAction($sSession, $sElement, 'rect')

	If IsObj($oERect) Then
		ConsoleWrite("Element Coords = " & $oERect.Item('x') & " / " & $oERect.Item('y') & " / " & $oERect.Item('width') & " / " & $oERect.Item('height') & @CRLF)
	EndIf

	; Locate multiple matching elements
	$aElements = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//div/input", Default, True)
	_ArrayDisplay($aElements, "Found Elements")

	; Set element's contents
	_WD_ElementAction($sSession, $sElement, 'value', "testing 123")
	Sleep(500)

	; Retrieve then clear contents
	$sValue = _WD_ElementAction($sSession, $sElement, 'property', 'value')
	_WD_ElementAction($sSession, $sElement, 'clear')
	Sleep(500)

	_WD_ElementAction($sSession, $sElement, 'value', "abc xyz")
	Sleep(500)

	$sValue = _WD_ElementAction($sSession, $sElement, 'property', 'value')
	_WD_ElementAction($sSession, $sElement, 'clear')
	Sleep(500)

	_WD_ElementAction($sSession, $sElement, 'value', "fujimo")
	Sleep(500)
	$sValue1 = _WD_ElementAction($sSession, $sElement, 'property', 'value')
	$sValue2 = _WD_ElementAction($sSession, $sElement, 'value')
	MsgBox(0, 'result', $sValue1 & " / " & $sValue2)

	; Click input element
	_WD_ElementAction($sSession, $sElement, 'click')

	; Click search button
    $sButton = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//input[@name='btnK']")
    _WD_ElementAction($sSession, $sButton, 'click')
    _WD_LoadWait($sSession, 2000)

	$sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, $sElementSelector)
	$sValue = _WD_ElementAction($sSession, $sElement, 'property', 'value')
	ConsoleWrite('value = ' & $sValue & @CRLF)

	; Take element screenshot
	$sResponse = _WD_ElementAction($sSession, $sElement, 'screenshot')
	$bDecode = _Base64Decode($sResponse)
	$sDecode = BinaryToString($bDecode)

	$hFileOpen = FileOpen("Element.png", $FO_BINARY + $FO_OVERWRITE)
	FileWrite($hFileOpen, $sDecode)
	FileClose($hFileOpen)
EndFunc

Func DemoScript()
	_WD_ExecuteScript($sSession, "return arguments[0].second;", '{"first": "1st", "second": "2nd", "third": "3rd"}')
	_WD_Alert($sSession, 'Dismiss')
EndFunc

Func DemoCookies()
	_WD_Navigate($sSession, "http://google.com")
	_WD_Cookies($sSession, 'Get', 'NID')

	Local $sName = "Testname"
	Local $sValue ="TestValue"
	Local $sCookie = '{"cookie": {"name":"' & $sName & '","value":"' & $sValue & '"}}'
	_WD_Cookies($sSession, 'add', $sCookie)
	_WD_Cookies($sSession, 'Get', $sName)
EndFunc

Func DemoAlerts()
	ConsoleWrite('Alert Detected => ' & _WD_Alert($sSession, 'status') & @CRLF)
	_WD_ExecuteScript($sSession, "alert('testing 123')")
	ConsoleWrite('Alert Detected => ' & _WD_Alert($sSession, 'status') & @CRLF)
	ConsoleWrite('Text Detected => ' & _WD_Alert($sSession, 'gettext') & @CRLF)
	_WD_Alert($sSession, 'sendtext', 'new text')
	ConsoleWrite('Text Detected => ' & _WD_Alert($sSession, 'gettext') & @CRLF)
	Sleep(5000)
	_WD_Alert($sSession, 'Dismiss')

EndFunc

Func DemoFrames()
	Local $sElement

	_WD_Navigate($sSession, "https://www.w3schools.com/tags/tryit.asp?filename=tryhtml_frame_cols")
	ConsoleWrite("Frames=" & _WD_GetFrameCount($sSession) & @CRLF)
	ConsoleWrite("TopWindow=" & _WD_IsWindowTop($sSession) & @CRLF)
	$sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//iframe[@id='iframeResult']")
	_WD_FrameEnter($sSession, $sElement)
	ConsoleWrite("TopWindow=" & _WD_IsWindowTop($sSession) & @CRLF)
	_WD_FrameLeave($sSession)
	ConsoleWrite("TopWindow=" & _WD_IsWindowTop($sSession) & @CRLF)

EndFunc

Func DemoActions()
	Local $sElement, $aElements, $sValue, $sAction

	_WD_Navigate($sSession, "http://google.com")
	$sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, $sElementSelector)

ConsoleWrite("$sElement = " & $sElement & @CRLF)

	$sAction = '{"actions":[{"id":"default mouse","type":"pointer","parameters":{"pointerType":"mouse"},"actions":[{"duration":100,"x":0,"y":0,"type":"pointerMove","origin":{"ELEMENT":"'
	$sAction &= $sElement & '","' & $_WD_ELEMENT_ID & '":"' & $sElement & '"}},{"button":2,"type":"pointerDown"},{"button":2,"type":"pointerUp"}]}]}'

ConsoleWrite("$sAction = " & $sAction & @CRLF)

	_WD_Action($sSession, "actions", $sAction)
	sleep(2000)
	Send("Q")
	sleep(2000)

	_WD_Action($sSession, "actions")
	sleep(2000)
EndFunc

Func DemoDownload()
	_WD_Navigate($sSession, "http://google.com")

	; Get the website's URL
	$sUrl = _WD_Action($sSession, 'url')

	; Find the element
	$sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//img[@id='hplogo']")

	If @error <> $_WD_ERROR_Success Then
		; Try alternate element
		$sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//div[@id='hplogo']//img")
	EndIf

	If @error = $_WD_ERROR_Success Then
		;  Retrieve it's source attribute
		$sSource  = _WD_ElementAction($sSession, $sElement, "Attribute", "src")

		; Combine the URL and element link
		$sURL = _WinAPI_UrlCombine($sUrl, $sSource)

		; Download the file
		_WD_DownloadFile($sUrl, @ScriptDir & "\testimage.png")

		_WD_DownloadFile("http://www.google.com/notexisting.jpg", @ScriptDir & "\testimage2.jpg")
	EndIf
EndFunc

Func DemoWindows()
	Local $sResponse, $hFileOpen, $sHnd1, $sHnd2, $bDecode, $sDecode, $oWRect

	$sHnd1 = '{"handle":"' & _WD_Window($sSession, "window") & '"}'
	_WD_Navigate($sSession, "http://google.com")

	_WD_NewTab($sSession)
	$sHnd2 = '{"handle":"' & _WD_Window($sSession, "window") & '"}'
	_WD_Navigate($sSession, "http://yahoo.com")

	; Get window coordinates
	$oWRect = _WD_Window($sSession, 'rect')
	ConsoleWrite("Window Coords = " & $oWRect.Item('x') & " / " & $oWRect.Item('y') & " / " & $oWRect.Item('width') & " / " & $oWRect.Item('height') & @CRLF)

	; Take screenshot
	_WD_Window($sSession, "switch", $sHnd1)
	$sResponse = _WD_Window($sSession, 'screenshot')
	$bDecode = _Base64Decode($sResponse)
	$sDecode = BinaryToString($bDecode)

	$hFileOpen = FileOpen("Screen1.png", $FO_BINARY + $FO_OVERWRITE)
	FileWrite($hFileOpen, $sDecode)
	FileClose($hFileOpen)

	; Take another one
	_WD_Window($sSession, "switch", $sHnd2)
	$sResponse = _WD_Window($sSession, 'screenshot')
	$bDecode = _Base64Decode($sResponse)
	$sDecode = BinaryToString($bDecode)

	$hFileOpen = FileOpen("Screen2.png", $FO_BINARY + $FO_OVERWRITE)
	FileWrite($hFileOpen, $sDecode)
	FileClose($hFileOpen)
EndFunc

Func DemoUpload()
	; Uses files created in DemoWindows
    _WD_Navigate($sSession, "https://www.htmlquick.com/reference/tags/input-file.html")
	_WD_SelectFiles($sSession, $_WD_LOCATOR_ByXPath, "//section[@id='examples']//input[@name='uploadedfile']", @ScriptDir & "\Screen1.png")
	_WD_SelectFiles($sSession, $_WD_LOCATOR_ByXPath, "//p[contains(text(),'Upload files:')]//input[@name='uploadedfiles[]']", @ScriptDir & "\Screen1.png" & @LF & @ScriptDir & "\Screen2.png")

	Local $sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//p[contains(text(),'Upload files:')]//input[2]")
	_WD_ElementAction($sSession, $sElement, 'click')
EndFunc

Func SetupGecko()
_WD_Option('Driver', 'geckodriver.exe')
_WD_Option('DriverParams', '--log trace')
_WD_Option('Port', 4444)

$sDesiredCapabilities = '{"capabilities": {"alwaysMatch": {"browserName": "firefox", "acceptInsecureCerts":true}}}'
EndFunc

Func SetupChrome()
_WD_Option('Driver', 'chromedriver.exe')
_WD_Option('Port', 9515)
_WD_Option('DriverParams', '--verbose --log-path="' & @ScriptDir & '\chrome.log"')

$sDesiredCapabilities = '{"capabilities": {"alwaysMatch": {"goog:chromeOptions": {"w3c": true, "excludeSwitches": [ "enable-automation"], "useAutomationExtension": false }}}}'
EndFunc

Func SetupEdge()
_WD_Option('Driver', 'msedgedriver.exe')
_WD_Option('Port', 9515)
_WD_Option('DriverParams', '--verbose')

$sDesiredCapabilities = '{"capabilities": {"alwaysMatch": {"ms:edgeOptions": {"binary": "' & StringReplace (@ProgramFilesDir, "\", "/") & '/Microsoft/Edge/Application/msedge.exe", "excludeSwitches": [ "enable-automation"], "useAutomationExtension": false}}}}'
EndFunc

