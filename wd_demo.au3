#Region - include files
; standard UDF's
#include <ButtonConstants.au3>
#include <ColorConstants.au3>
#include <GuiComboBoxEx.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
; non standard UDF's
#include "wd_helper.au3"
#include "wd_capabilities.au3"
#EndRegion - include files

#Region - Global's declarations
Global Const $sElementSelector = "//input[@name='q']"
Global Const $aBrowsers[][2] = _
		[ _
		["Firefox", SetupGecko], _
		["Chrome", SetupChrome], _
		["Edge", SetupEdge] _
		]

Global $aDemoSuite[][2] = _
		[ _
		["DemoTimeouts", False], _
		["DemoNavigation", True], _
		["DemoElements", False], _
		["DemoScript", False], _
		["DemoCookies", False], _
		["DemoAlerts", False], _
		["DemoFrames", False], _
		["DemoActions", False], _
		["DemoDownload", False], _
		["DemoWindows", False], _
		["DemoUpload", False], _
		["DemoSleep", False] _
		]

Global Const $aDebugLevel[][2] = _
		[ _
		["None", $_WD_DEBUG_None], _
		["Error", $_WD_DEBUG_Error], _
		["Full", $_WD_DEBUG_Info] _
		]

Global $sSession
Global $__g_idButton_Abort
#EndRegion - Global's declarations

_WD_Demo()
Exit

Func _WD_Demo()
	Local $nMsg
	Local $iSpacing = 50
	Local $iCount = UBound($aDemoSuite)
	Local $aCheckboxes[$iCount]

	Local $hGUI = GUICreate("Webdriver Demo", 200, 150 + (20 * $iCount), 100, 200, BitXOR($GUI_SS_DEFAULT_GUI, $WS_MINIMIZEBOX))
	GUISetBkColor($CLR_SILVER)
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
	Local $idButton_Run = GUICtrlCreateButton("Run Demo!", 10, $iPos + 40, 85, 25)
	$__g_idButton_Abort = GUICtrlCreateButton("Abort", 100, $iPos + 40, 85, 25)
	GUICtrlSetState($__g_idButton_Abort, $GUI_DISABLE)

	GUISetState(@SW_SHOW)
	While 1
		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_NONE
				; do nothing
			Case $GUI_EVENT_CLOSE
				ExitLoop

			Case $idBrowsers

			Case $idDebugging

			Case $idButton_Run
				GUICtrlSetState($idButton_Run, $GUI_DISABLE)
				RunDemo($idDebugging, $idBrowsers)
				GUICtrlSetState($idButton_Run, $GUI_ENABLE)

			Case Else
				For $i = 0 To $iCount - 1
					If $aCheckboxes[$i] = $nMsg Then
						$aDemoSuite[$i][1] = Not $aDemoSuite[$i][1]
					EndIf
				Next

		EndSwitch
	WEnd

	GUIDelete($hGUI)
EndFunc   ;==>_WD_Demo

Func RunDemo($idDebugging, $idBrowsers)
	; Set debug level
	$_WD_DEBUG = $aDebugLevel[_GUICtrlComboBox_GetCurSel($idDebugging)][1]

	; Execute browser setup routine for user's browser selection
	Local $sDesiredCapabilities = Call($aBrowsers[_GUICtrlComboBox_GetCurSel($idBrowsers)][1])

	_WD_Startup()
	If @error <> $_WD_ERROR_Success Then Return

	$sSession = _WD_CreateSession($sDesiredCapabilities)

	Local $iError
	If @error = $_WD_ERROR_Success Then
		For $iIndex = 0 To UBound($aDemoSuite, $UBOUND_ROWS) - 1
			If $aDemoSuite[$iIndex][1] Then
				ConsoleWrite("+Running: " & $aDemoSuite[$iIndex][0] & @CRLF)
				Call($aDemoSuite[$iIndex][0])
				$iError = @error
				If $iError = $_WD_ERROR_UserAbort Then
					ConsoleWrite("- Aborted: " & $aDemoSuite[$iIndex][0] & @CRLF)
					ExitLoop
				EndIf
				ConsoleWrite("+Finished: " & $aDemoSuite[$iIndex][0] & @CRLF)
			Else
				ConsoleWrite("Bypass: " & $aDemoSuite[$iIndex][0] & @CRLF)
			EndIf
		Next
	EndIf

	If $iError = $_WD_ERROR_UserAbort Then
		MsgBox($MB_ICONINFORMATION, 'Demo aborted!', 'Click "Ok" button to shutdown the browser and console')
	Else
		MsgBox($MB_ICONINFORMATION, 'Demo complete!', 'Click "Ok" button to shutdown the browser and console')
	EndIf

	_WD_DeleteSession($sSession)
	_WD_Shutdown()
EndFunc   ;==>RunDemo

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
EndFunc   ;==>DemoTimeouts

Func DemoNavigation()
	_WD_Navigate($sSession, "http://google.com")
	_WD_NewTab($sSession, Default, Default, "http://yahoo.com")
	;	_WD_Navigate($sSession, "http://yahoo.com")
	_WD_NewTab($sSession, True, Default, 'http://bing.com', 'width=200,height=200')

	ConsoleWrite("URL=" & _WD_Action($sSession, 'url') & @CRLF)
	_WD_Attach($sSession, "google.com", "URL")
	ConsoleWrite("URL=" & _WD_Action($sSession, 'url') & @CRLF)
	_WD_Attach($sSession, "yahoo.com", "URL")
	ConsoleWrite("URL=" & _WD_Action($sSession, 'url') & @CRLF)
EndFunc   ;==>DemoNavigation

Func DemoElements()
	Local $sElement, $aElements, $sValue, $sButton, $sResponse, $bDecode, $hFileOpen

	_WD_Navigate($sSession, "http://google.com")

	; Locate a single element
	$sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, $sElementSelector)

	; Get element's coordinates
	Local $oERect = _WD_ElementAction($sSession, $sElement, 'rect')

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
	Local $sValue1 = _WD_ElementAction($sSession, $sElement, 'property', 'value')
	Local $sValue2 = _WD_ElementAction($sSession, $sElement, 'value')
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
	$bDecode = __WD_Base64Decode($sResponse)

	$hFileOpen = FileOpen("Element.png", $FO_BINARY + $FO_OVERWRITE)
	FileWrite($hFileOpen, $bDecode)
	FileClose($hFileOpen)

	_WD_Navigate($sSession, "http://demo.guru99.com/test/simple_context_menu.html")

	Sleep(2000)

	$sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//button[contains(text(),'Double-Click Me To See Alert')]")

	If @error = $_WD_ERROR_Success Then
		_WD_ElementActionEx($sSession, $sElement, "doubleclick")
	EndIf

	Sleep(2000)
	_WD_Alert($sSession, 'accept')

	_WD_ElementActionEx($sSession, $sElement, "hide")
	Sleep(5000)
	_WD_ElementActionEx($sSession, $sElement, "show")

	$sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//span[@class='context-menu-one btn btn-neutral']")

	If @error = $_WD_ERROR_Success Then
		_WD_ElementActionEx($sSession, $sElement, "rightclick")
	EndIf
EndFunc   ;==>DemoElements

Func DemoScript()
	_WD_ExecuteScript($sSession, "return arguments[0].second;", '{"first": "1st", "second": "2nd", "third": "3rd"}')
	ConsoleWrite(@error & @CRLF & $_WD_HTTPRESULT & @CRLF)
	_WD_ExecuteScript($sSession, "dslfkjsdklfj;", '{}')
	ConsoleWrite(@error & @CRLF & $_WD_HTTPRESULT & @CRLF)
	_WD_ExecuteScript($sSession, "return $.ajax({url:'http://hosting105782.a2f0c.netcup.net/test.php',type:'post',dataType: 'text', data:'getaccount=1',success : function(text){return text;}});")
	ConsoleWrite(@error & @CRLF & $_WD_HTTPRESULT & @CRLF)
EndFunc   ;==>DemoScript

Func DemoCookies()
	_WD_Navigate($sSession, "http://google.com")
	_WD_Cookies($sSession, 'Get', 'NID')

	Local $sName = "Testname"
	Local $sValue = "TestValue"
	Local $sCookie = '{"cookie": {"name":"' & $sName & '","value":"' & $sValue & '"}}'
	_WD_Cookies($sSession, 'add', $sCookie)
	_WD_Cookies($sSession, 'Get', $sName)
EndFunc   ;==>DemoCookies

Func DemoAlerts()
	Local $sStatus, $sText

	; show Alert for testing
	_WD_ExecuteScript($sSession, "alert('testing 123')")

	; get/check Alert status and text
	$sStatus = _WD_Alert($sSession, 'status')
	$sText = _WD_Alert($sSession, 'gettext')
	ConsoleWrite("- " & 'Alert Detected => ' & $sStatus & @CRLF)
	ConsoleWrite("- " & 'Text Detected => ' & $sText & @CRLF)

	; change Alert text
	_WD_Alert($sSession, 'sendtext', 'new text')
	$sText = _WD_Alert($sSession, 'gettext')
	ConsoleWrite(@CRLF)
	ConsoleWrite("- " & 'Text Detected => ' & $sText & @CRLF)

	Sleep(5000)
	; close Alert
	_WD_Alert($sSession, 'Dismiss')

EndFunc   ;==>DemoAlerts

Func DemoFrames()
	Local $sElement

	_WD_Navigate($sSession, "https://www.w3schools.com/tags/tryit.asp?filename=tryhtml_iframe")
	ConsoleWrite("Frames=" & _WD_GetFrameCount($sSession) & @CRLF)
	ConsoleWrite("TopWindow=" & _WD_IsWindowTop($sSession) & @CRLF)
	$sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//iframe[@id='iframeResult']")
	_WD_FrameEnter($sSession, $sElement)
	ConsoleWrite("TopWindow=" & _WD_IsWindowTop($sSession) & @CRLF)
	$sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//iframe")
	_WD_FrameEnter($sSession, $sElement)
	Local $sButton = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//button[@id='w3loginbtn']")
	_WD_ElementAction($sSession, $sButton, 'click')
	_WD_LoadWait($sSession, 2000)
	_WD_FrameLeave($sSession)
	ConsoleWrite("TopWindow=" & _WD_IsWindowTop($sSession) & @CRLF)
	_WD_FrameLeave($sSession)
	ConsoleWrite("TopWindow=" & _WD_IsWindowTop($sSession) & @CRLF)
EndFunc   ;==>DemoFrames

Func DemoActions()
	Local $sElement, $aElements, $sValue, $sAction
	#forceref $aElements, $sValue

	_WD_Navigate($sSession, "http://google.com")
	$sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, $sElementSelector)

	ConsoleWrite("$sElement = " & $sElement & @CRLF)

	$sAction = '{"actions":[{"id":"default mouse","type":"pointer","parameters":{"pointerType":"mouse"},"actions":[{"duration":100,"x":0,"y":0,"type":"pointerMove","origin":{"ELEMENT":"'
	$sAction &= $sElement & '","' & $_WD_ELEMENT_ID & '":"' & $sElement & '"}},{"button":2,"type":"pointerDown"},{"button":2,"type":"pointerUp"}]}]}'

	ConsoleWrite("$sAction = " & $sAction & @CRLF)

	_WD_Action($sSession, "actions", $sAction)
	Sleep(2000)
	Send("Q")
	Sleep(2000)

	_WD_Action($sSession, "actions")
	Sleep(2000)
EndFunc   ;==>DemoActions

Func DemoDownload()
	_WD_Navigate($sSession, "http://google.com")

	; Get the website's URL
	Local $sUrl = _WD_Action($sSession, 'url')

	; Find the element
	Local $sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//img[@id='hplogo']")

	If @error <> $_WD_ERROR_Success Then
		; Try alternate element
		$sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//div[@id='hplogo']//img")
	EndIf

	If @error = $_WD_ERROR_Success Then
		;  Retrieve it's source attribute
		Local $sSource = _WD_ElementAction($sSession, $sElement, "Attribute", "src")

		; Combine the URL and element link
		$sUrl = _WinAPI_UrlCombine($sUrl, $sSource)

		; Download the file
		_WD_DownloadFile($sUrl, @ScriptDir & "\testimage.png")

		_WD_DownloadFile("http://www.google.com/notexisting.jpg", @ScriptDir & "\testimage2.jpg")
	EndIf
EndFunc   ;==>DemoDownload

Func DemoWindows()
	Local $sResponse, $hFileOpen, $sHnd1, $sHnd2, $bDecode, $oWRect

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
	$bDecode = __WD_Base64Decode($sResponse)

	$hFileOpen = FileOpen("Screen1.png", $FO_BINARY + $FO_OVERWRITE)
	FileWrite($hFileOpen, $bDecode)
	FileClose($hFileOpen)

	; Take another one
	_WD_Window($sSession, "switch", $sHnd2)
	$sResponse = _WD_Window($sSession, 'screenshot')
	$bDecode = __WD_Base64Decode($sResponse)

	$hFileOpen = FileOpen("Screen2.png", $FO_BINARY + $FO_OVERWRITE)
	FileWrite($hFileOpen, $bDecode)
	FileClose($hFileOpen)
EndFunc   ;==>DemoWindows

Func DemoUpload()
	; Uses files created in DemoWindows
	_WD_Navigate($sSession, "https://www.htmlquick.com/reference/tags/input-file.html")
	_WD_SelectFiles($sSession, $_WD_LOCATOR_ByXPath, "//section[@id='examples']//input[@name='uploadedfile']", @ScriptDir & "\Screen1.png")
	_WD_SelectFiles($sSession, $_WD_LOCATOR_ByXPath, "//p[contains(text(),'Upload files:')]//input[@name='uploadedfiles[]']", @ScriptDir & "\Screen1.png" & @LF & @ScriptDir & "\Screen2.png")

	Local $sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//p[contains(text(),'Upload files:')]//input[2]")
	_WD_ElementAction($sSession, $sElement, 'click')
EndFunc   ;==>DemoUpload

Func DemoSleep()
	; enable Abort button
	GUICtrlSetState($__g_idButton_Abort, $GUI_ENABLE)

	; set up outer/user specific sleep function to take control
	_WD_Option("Sleep", _USER_WD_Sleep)

	_WD_Navigate($sSession, "https://commondatastorage.googleapis.com/chromium-browser-snapshots/index.html?prefix=Win/")
	Local $iError = @error
	If Not $iError Then
		; it can take a long time to load full content of this webpage
		; this following function is waiting to the progress spinner will hide
		_WD_WaitElement($sSession, $_WD_LOCATOR_ByXPath, '//img[@class="loader-spinner ng-hide" and @ng-show="loading"]', Default, 3 * 60 * 1000)
		$iError = @error

		; normaly it will wait as webpage will load full content (hidden spinner) or will end with TimeOut
		; but thanks to using _WD_Option("Sleep", _USER_WD_Sleep) you can abort waiting by clicking scecial Abourt button or by clicking X closing button on the "Webdriver Demo" GUI window
	EndIf

	; disable Abort button
	GUICtrlSetState($__g_idButton_Abort, $GUI_DISABLE)

	; set up internal sleep function - back to standard route
	_WD_Option("Sleep", Sleep)

	Return SetError($iError)
EndFunc   ;==>DemoSleep

Func _USER_WD_Sleep($iDelay)
	Local $hTimer = TimerInit() ; Begin the timer and store the handle in a variable.
	Do
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE ; in case when X closing button on the "Webdriver Demo" GUI window was clicked
				ConsoleWrite("! Abort by GUI Close button pressed." & @CRLF)
				Return SetError($_WD_ERROR_UserAbort) ; set specific error to end processing _WD_*** functions, without waiting for success or even for TimeOut
			Case $__g_idButton_Abort ; in case when Abort button was clicked
				ConsoleWrite("! Abort button pressed." & @CRLF)
				Return SetError($_WD_ERROR_UserAbort) ; set specific error to end processing _WD_*** functions, without waiting for success or even for TimeOut
		EndSwitch
	Until TimerDiff($hTimer) > $iDelay ; check TimeOut
EndFunc   ;==>_USER_WD_Sleep

Func SetupGecko()
	_WD_Option('Driver', 'geckodriver.exe')
	_WD_Option('DriverParams', '--log trace')
	_WD_Option('Port', 4444)

;~ 	Local $sDesiredCapabilities = '{"capabilities": {"alwaysMatch": {"browserName": "firefox", "acceptInsecureCerts":true}}}'
	_WD_CapabilitiesStartup()
	_WD_CapabilitiesAdd('alwaysMatch', 'firefox')
	_WD_CapabilitiesAdd('browserName', 'firefox')
	_WD_CapabilitiesAdd('acceptInsecureCerts', True)
	_WD_CapabilitiesDump(@ScriptLineNumber) ; dump current Capabilities setting to console - only for testing in this demo
	Local $sDesiredCapabilities = _WD_CapabilitiesGet()
	Return $sDesiredCapabilities
EndFunc   ;==>SetupGecko

Func SetupChrome()
	_WD_Option('Driver', 'chromedriver.exe')
	_WD_Option('Port', 9515)
	_WD_Option('DriverParams', '--verbose --log-path="' & @ScriptDir & '\chrome.log"')

;~ 	Local $sDesiredCapabilities = '{"capabilities": {"alwaysMatch": {"goog:chromeOptions": {"w3c": true, "excludeSwitches": [ "enable-automation"]}}}}'
	_WD_CapabilitiesStartup()
	_WD_CapabilitiesAdd('alwaysMatch', 'chrome')
	_WD_CapabilitiesAdd('w3c', True)
	_WD_CapabilitiesAdd('excludeSwitches', 'enable-automation')
	_WD_CapabilitiesDump(@ScriptLineNumber) ; dump current Capabilities setting to console - only for testing in this demo
	Local $sDesiredCapabilities = _WD_CapabilitiesGet()
	Return $sDesiredCapabilities
EndFunc   ;==>SetupChrome

Func SetupEdge()
	_WD_Option('Driver', 'msedgedriver.exe')
	_WD_Option('Port', 9515)
	_WD_Option('DriverParams', '--verbose --log-path="' & @ScriptDir & '\msedge.log"')

;~ 	Local $sDesiredCapabilities = '{"capabilities": {"alwaysMatch": {"ms:edgeOptions": {"excludeSwitches": [ "enable-automation"]}}}}'
	_WD_CapabilitiesStartup()
	_WD_CapabilitiesAdd('alwaysMatch', 'edge')
	_WD_CapabilitiesAdd('excludeSwitches', 'enable-automation')
	_WD_CapabilitiesDump(@ScriptLineNumber) ; dump current Capabilities setting to console - only for testing in this demo
	Local $sDesiredCapabilities = _WD_CapabilitiesGet()
	Return $sDesiredCapabilities
EndFunc   ;==>SetupEdge
