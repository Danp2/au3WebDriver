#Region - include files
; standard UDF's
#include <ButtonConstants.au3>
#include <ColorConstants.au3>
#include <Date.au3>
#include <Debug.au3>
#include <GuiComboBoxEx.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>

; non standard UDF's
#include "wd_helper.au3"
#include "wd_capabilities.au3"
#EndRegion - include files

#Tidy_Parameters=/tcb=-1

#Region - Global's declarations
Global Const $sElementSelector = "//input[@name='q']"
Global Const $aBrowsers[][2] = _
		[ _
		["Firefox", SetupGecko], _
		["Chrome", SetupChrome], _
		["Chrome_Legacy", SetupChrome], _
		["MSEdge", SetupEdge], _
		["Opera", SetupOpera], _
		["MSEdgeIE", SetupEdgeIEMode] _
		]

; Column 0 - Function Name
; Column 1 - Selected at start or selected manually by user
; Column 2 - Pass browser name as parameter to called function
Global $aDemoSuite[][3] = _
		[ _
		["DemoTimeouts", False, False], _
		["DemoNavigation", True, False], _
		["DemoElements", False, False], _
		["DemoScript", False, False], _
		["DemoCookies", False, False], _
		["DemoAlerts", False, False], _
		["DemoFrames", False, False], _
		["DemoActions", False, False], _
		["DemoDownload", False, False], _
		["DemoWindows", False, False], _
		["DemoUpload", False, False], _
		["DemoPrint", False, True], _
		["DemoSleep", False, False], _
		["DemoSelectOptions", False, False], _
		["DemoStyles", False, False], _
		["UserTesting", False, False], _
		["UserFile", False, False] _
		]

Global Const $aDebugLevel[][2] = _
		[ _
		["None", $_WD_DEBUG_None], _
		["Error", $_WD_DEBUG_Error], _
		["Info", $_WD_DEBUG_Info], _
		["Full", $_WD_DEBUG_Full] _
		]

Global $sSession
Global $__g_idButton_Abort
Global $_VAR[50] ; used in UserFile(), __SetVAR()
#EndRegion - Global's declarations

_WD_Demo()
Exit

Func _WD_Demo()
	Local $nMsg
	Local $iSpacing = 25
	Local $iPos
	Local $iCount = UBound($aDemoSuite)
	Local $aButtons[$iCount]

	Local $hGUI = GUICreate("Webdriver Demo", 200, 100, 100, 200, BitXOR($GUI_SS_DEFAULT_GUI, $WS_MINIMIZEBOX))
	GUISetBkColor($CLR_SILVER)

	#Region - browsers
	$iPos += $iSpacing
	GUICtrlCreateLabel("Browser", 15, $iPos + 2)
	Local $idBrowsers = GUICtrlCreateCombo("", 75, $iPos, 100, 20, $CBS_DROPDOWNLIST)
	Local $sData = _ArrayToString($aBrowsers, Default, Default, Default, "|", 0, 0)
	GUICtrlSetData($idBrowsers, $sData)
	GUICtrlSetData($idBrowsers, $aBrowsers[0][0])
	#EndRegion - browsers

	#Region - debug
	$iPos += $iSpacing
	GUICtrlCreateLabel("Debug", 15, $iPos + 2)
	Local $idDebugging = GUICtrlCreateCombo("", 75, $iPos, 100, 20, $CBS_DROPDOWNLIST)
	$sData = _ArrayToString($aDebugLevel, Default, Default, Default, "|", 0, 0)
	GUICtrlSetData($idDebugging, $sData)
	GUICtrlSetData($idDebugging, "Info")
	#EndRegion - debug

	#Region - update
	$iPos += $iSpacing
	GUICtrlCreateLabel("Update", 15, $iPos + 2)
	Local $idUpdate = GUICtrlCreateCombo("Report only", 75, $iPos, 100, 20, $CBS_DROPDOWNLIST)
	GUICtrlSetData($idUpdate, "Current|32bit|32bit+Force|64Bit|64Bit+Force", "Report only")
	#EndRegion - update

	#Region - Headless
	$iPos += $iSpacing
	GUICtrlCreateLabel("Headless", 15, $iPos + 2)
	Local $idHeadless = GUICtrlCreateCombo("No", 75, $iPos, 100, 20, $CBS_DROPDOWNLIST)
	GUICtrlSetData($idHeadless, "Yes", "No")
	#EndRegion - Headless

	#Region - Output
	$iPos += $iSpacing
	GUICtrlCreateLabel("ConsoleOut", 15, $iPos + 2)
	Local $idOutput = GUICtrlCreateCombo("ConsoleWrite", 75, $iPos, 100, 20, $CBS_DROPDOWNLIST)
	GUICtrlSetData($idOutput, "WD_Console.log|_DebugOut|Null", "ConsoleWrite")
	#EndRegion - Output

	#Region - demos
	$iPos += $iSpacing
	GUICtrlCreateLabel("Demos", 15, $iPos + $iSpacing + 2)
	For $i = 0 To $iCount - 1
		$iPos += $iSpacing
		$aButtons[$i] = GUICtrlCreateButton($aDemoSuite[$i][0], 75, $iPos, 100, 20)
		If $aDemoSuite[$i][1] Then GUICtrlSetBkColor($aButtons[$i], $COLOR_AQUA)
	Next
	#EndRegion - demos

	#Region - run / abort
	$iPos += $iSpacing * 2
	Local $idButton_Run = GUICtrlCreateButton("Run Demo!", 10, $iPos, 85, 25)
	$__g_idButton_Abort = GUICtrlCreateButton("Abort", 100, $iPos, 85, 25)
	GUICtrlSetState($__g_idButton_Abort, $GUI_DISABLE)
	#EndRegion - run / abort

	; Resize window
	WinMove($hGUI, "", 100, 200, 200, $iPos + 3 * $iSpacing)

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
				_RunDemo_GUISwitcher($GUI_DISABLE, $idBrowsers, $idDebugging, $idUpdate, $idHeadless, $idOutput, $idButton_Run, $aButtons)
				RunDemo($idDebugging, $idBrowsers, $idUpdate, $idHeadless, $idOutput)
				_RunDemo_GUISwitcher($GUI_ENABLE, $idBrowsers, $idDebugging, $idUpdate, $idHeadless, $idOutput, $idButton_Run, $aButtons)

			Case Else
				For $i = 0 To $iCount - 1
					If $aButtons[$i] = $nMsg Then
						$aDemoSuite[$i][1] = Not $aDemoSuite[$i][1]
						GUICtrlSetBkColor($aButtons[$i], $aDemoSuite[$i][1] ? $COLOR_AQUA : $COLOR_WHITE)
						_ArraySearch($aDemoSuite, True, Default, Default, Default, Default, Default, 1)
						GUICtrlSetState($idButton_Run, @error ? $GUI_DISABLE : $GUI_ENABLE)
					EndIf
				Next

		EndSwitch
	WEnd

	GUIDelete($hGUI)
EndFunc   ;==>_WD_Demo

Func RunDemo($idDebugging, $idBrowsers, $idUpdate, $idHeadless, $idOutput)
	; Check selected debugging option and set desired debug level
	$_WD_DEBUG = $aDebugLevel[_GUICtrlComboBox_GetCurSel($idDebugging)][1]

	; Get selected browser
	Local $sBrowserName = $aBrowsers[_GUICtrlComboBox_GetCurSel($idBrowsers)][0]

	; Check and set desired output for __WD_ConsoleWrite()
	_RunDemo_Output($idOutput)

	; This following 2 options setting is for "compability" with au3WebDriver UDF "0.7.0", because in later versions this feature was disabled by default
	_WD_Option("errormsgbox", (@Compiled = 1))
	_WD_Option("OutputDebug", (@Compiled = 1))

	; Check & update WebDriver per user setting
	_RunDemo_Update($idUpdate, $sBrowserName)

	; Check and set desired headless mode
	Local $bHeadless = _RunDemo_Headless($idHeadless)

	; Execute browser setup routine for user's browser selection
	Local $sCapabilities = Call($aBrowsers[_GUICtrlComboBox_GetCurSel($idBrowsers)][1], $bHeadless)
	If @error Then Return SetError(@error, @extended, 0)

	ConsoleWrite("> wd_demo.au3: _WD_Startup" & @CRLF)
	Local $iWebDriver_PID = _WD_Startup()
	If _RunDemo_ErrorHander((@error <> $_WD_ERROR_Success), @error, @extended, $iWebDriver_PID, $sSession) Then Return

	ConsoleWrite("> wd_demo.au3: _WD_CreateSession" & @CRLF)
	$sSession = _WD_CreateSession($sCapabilities)
	If _RunDemo_ErrorHander((@error <> $_WD_ERROR_Success), @error, @extended, $iWebDriver_PID, $sSession) Then Return

	Local $iError, $sDemoName
	For $iIndex = 0 To UBound($aDemoSuite, $UBOUND_ROWS) - 1
		$sDemoName = $aDemoSuite[$iIndex][0]
		If Not $aDemoSuite[$iIndex][1] Then
			ConsoleWrite("> wd_demo.au3: Bypass: " & $sDemoName & @CRLF)
			ContinueLoop
		EndIf

		_WD_CheckContext($sSession, False)
		$iError = @error
		If @error Then ExitLoop ; return if session is NOT OK

		ConsoleWrite("+ wd_demo.au3: Running: " & $sDemoName & @CRLF)
		If $aDemoSuite[$iIndex][2] Then
			Call($sDemoName, $sBrowserName)
		Else
			Call($sDemoName)
		EndIf
		$iError = @error
		If $iError <> $_WD_ERROR_Success Then ExitLoop
		ConsoleWrite("+ wd_demo.au3: Finished: " & $sDemoName & @CRLF)
	Next

	_RunDemo_ErrorHander(True, $iError, @extended, $iWebDriver_PID, $sSession, $sDemoName)
EndFunc   ;==>RunDemo

Func _RunDemo_Update($idUpdate, $sBrowserName)
	Local $sUpdate
	_GUICtrlComboBox_GetLBText($idUpdate, _GUICtrlComboBox_GetCurSel($idUpdate), $sUpdate)

	Local $bFlag64 = (StringInStr($sUpdate, '64') > 0)
	If StringInStr($sUpdate, 'Current') Then $bFlag64 = Default

	Local $bForce = (StringInStr($sUpdate, 'Force') > 0)
	If $sUpdate = 'Report only' Then $bForce = Null

	Local $bUpdateResult = _WD_UpdateDriver($sBrowserName, @ScriptDir, $bFlag64, $bForce)
	ConsoleWrite('> UpdateResult = ' & $bUpdateResult & @CRLF)
EndFunc   ;==>_RunDemo_Update

Func _RunDemo_Headless($idHeadless)
	Local $sHeadless
	_GUICtrlComboBox_GetLBText($idHeadless, _GUICtrlComboBox_GetCurSel($idHeadless), $sHeadless)
	Return ($sHeadless = 'Yes')
EndFunc   ;==>_RunDemo_Headless

Func _RunDemo_Output($idOutput)
	Local $sOutput
	_GUICtrlComboBox_GetLBText($idOutput, _GUICtrlComboBox_GetCurSel($idOutput), $sOutput)

	Switch $sOutput
		Case 'ConsoleWrite'
			_WD_Option('console', ConsoleWrite)
		Case 'WD_Console.log'
			_WD_Option('console', @ScriptDir & '\WD_Console.log')
		Case '_DebugOut'
			_DebugSetup('wd_demo - console log output')
			_WD_Option('console', _DebugOut)
		Case 'Null'
			_WD_Option('console', Null)
	EndSwitch

	Return $sOutput
EndFunc   ;==>_RunDemo_Output

Func _RunDemo_GUISwitcher($iState, $idBrowsers, $idDebugging, $idUpdate, $idHeadless, $idOutput, $idButton_Run, $aCheckboxes)
	GUICtrlSetState($idBrowsers, $iState)
	GUICtrlSetState($idDebugging, $iState)
	GUICtrlSetState($idUpdate, $iState)
	GUICtrlSetState($idHeadless, $iState)
	GUICtrlSetState($idOutput, $iState)
	GUICtrlSetState($idButton_Run, $iState)
	For $i = 0 To UBound($aCheckboxes, $UBOUND_ROWS) - 1 Step 1
		GUICtrlSetState($aCheckboxes[$i], $iState)
	Next
EndFunc   ;==>_RunDemo_GUISwitcher

Func _RunDemo_ErrorHander($bForceDispose, $iError, $iExtended, $iWebDriver_PID, $sSession, $sDemoName = 'Demo')
	If Not $bForceDispose Then Return SetError($iError, $iExtended, $bForceDispose)

	Switch $iError
		Case $_WD_ERROR_Success
			MsgBox($MB_ICONINFORMATION + $MB_TOPMOST, 'Demo complete!', 'Click "Ok" button to shutdown the browser and console')
		Case $_WD_ERROR_UserAbort
			ConsoleWrite("! wd_demo.au3: (" & @ScriptLineNumber & ") : Aborted: " & $sDemoName & @CRLF)
			MsgBox($MB_ICONINFORMATION, $sDemoName & ' aborted!', 'Click "Ok" button to shutdown the browser and console')
		Case Else
			ConsoleWrite("! Error = " & $iError & " occurred on: " & $sDemoName & @CRLF)
			ConsoleWrite("! _WD_LastHTTPResult = " & _WD_LastHTTPResult() & @CRLF)
			ConsoleWrite("! _WD_LastHTTPResponse = " & _WD_LastHTTPResponse() & @CRLF)
			ConsoleWrite("! _WD_GetSession = " & _WD_GetSession($sSession) & @CRLF)
			MsgBox($MB_ICONERROR + $MB_TOPMOST, $sDemoName & ' error!', 'Check logs')
	EndSwitch

	If $sSession Then _WD_DeleteSession($sSession)
	If $iWebDriver_PID Then _WD_Shutdown()

	If FuncName(_WD_Option('console')) = '_DebugOut' Then
		; Close debug window and reset environment for next run
		Local $hWndReportWindow = WinGetHandle($__g_sReportTitle_Debug, $__g_sReportWindowText_Debug)
		GUIDelete($hWndReportWindow)
		$__g_bReportWindowWaitClose_Debug = True
		$__g_bReportWindowClosed_Debug = True
		$__g_iReportType_Debug = 2 ; Prevents window from appearing during script exit
	EndIf

	Return SetError($iError, $iExtended, $bForceDispose)
EndFunc   ;==>_RunDemo_ErrorHander

Func DemoTimeouts()
	; Retrieve current settings and save
	Local $sResponse = _WD_Timeouts($sSession)
	Local $oJSON = Json_Decode($sResponse)
	Local $sTimouts = Json_Encode(Json_Get($oJSON, "[value]"))

	_Demo_NavigateCheckBanner($sSession, "https://google.com", '//body/div[1][@aria-hidden="true"]')
	If @error Then Return SetError(@error, @extended)

	; Set page load timeout
	_WD_Timeouts($sSession, '{"pageLoad":2000}')

	; Retrieve current settings
	_WD_Timeouts($sSession)

	; This should timeout
	_Demo_NavigateCheckBanner($sSession, "https://yahoo.com", '//body[contains(@class, "blur-preview-tpl")]')
	If @error Then Return SetError(@error, @extended)

	; Restore initial settings
	_WD_Timeouts($sSession, $sTimouts)
EndFunc   ;==>DemoTimeouts

Func DemoNavigation()
	_Demo_NavigateCheckBanner($sSession, "https://google.com", '//body/div[1][@aria-hidden="true"]')
	If @error Then Return SetError(@error, @extended)

	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : URL=" & _WD_Action($sSession, 'url') & @CRLF)

	_WD_NewTab($sSession)
	_Demo_NavigateCheckBanner($sSession, "https://yahoo.com", '//body[contains(@class, "blur-preview-tpl")]')
	If @error Then Return SetError(@error, @extended)
	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : URL=" & _WD_Action($sSession, 'url') & @CRLF)

	_WD_NewTab($sSession, True, Default, 'https://bing.com', 'width=200,height=200')
	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : URL=" & _WD_Action($sSession, 'url') & @CRLF)

	_WD_Attach($sSession, "google.com", "URL")
	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : URL=" & _WD_Action($sSession, 'url') & @CRLF)

	_WD_Attach($sSession, "yahoo.com", "URL")
	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : URL=" & _WD_Action($sSession, 'url') & @CRLF)

EndFunc   ;==>DemoNavigation

Func DemoElements()
	Local $sElement, $aElements, $sValue, $sButton, $sResponse, $bDecode, $hFileOpen

	_Demo_NavigateCheckBanner($sSession, "https://google.com", '//body/div[1][@aria-hidden="true"]')
	If @error Then Return SetError(@error, @extended)

	; Locate a single element
	$sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, $sElementSelector)

	; Get element's coordinates
	Local $oERect = _WD_ElementAction($sSession, $sElement, 'rect')

	If IsObj($oERect) Then
		ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : Element Coords = " & $oERect.Item('x') & " / " & $oERect.Item('y') & " / " & $oERect.Item('width') & " / " & $oERect.Item('height') & @CRLF)
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
	MsgBox($MB_ICONINFORMATION + $MB_TOPMOST, 'result #' & @ScriptLineNumber, $sValue1 & " / " & $sValue2)

	; Click input element
	_WD_ElementAction($sSession, $sElement, 'click')

	; Click search button
	$sButton = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//input[@name='btnK']")
	_WD_ElementAction($sSession, $sButton, 'click')
	_WD_LoadWait($sSession, 2000)

	$sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, $sElementSelector)
	$sValue = _WD_ElementAction($sSession, $sElement, 'property', 'value')
	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : ERROR=" & @error & " $sValue = " & $sValue & @CRLF)

	; Take element screenshot
	$sResponse = _WD_ElementAction($sSession, $sElement, 'screenshot')
	$bDecode = __WD_Base64Decode($sResponse)

	$hFileOpen = FileOpen("Element.png", $FO_BINARY + $FO_OVERWRITE)
	FileWrite($hFileOpen, $bDecode)
	FileClose($hFileOpen)

	_Demo_NavigateCheckBanner($sSession, "https://demo.guru99.com/test/simple_context_menu.html", '//div[@id="gdpr-consent-tool-wrapper" and @aria-hidden="true"]')
	If @error Then Return SetError(@error, @extended)

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
	Local $sValue

	; JavaScript example with arguments
	$sValue = _WD_ExecuteScript($sSession, "return arguments[0].second;", '{"first": "1st", "second": "2nd", "third": "3rd"}', Default, $_WD_JSON_Value)
	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : ERROR=" & @error & " $sValue = " & $sValue & " _WD_LastHTTPResult = " & _WD_LastHTTPResult() & @CRLF)

	; JavaScript example that fires error because of unknown function
	$sValue = _WD_ExecuteScript($sSession, "dslfkjsdklfj;", Default, Default, $_WD_JSON_Value)
	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : ERROR=" & @error & " $sValue = " & $sValue & " _WD_LastHTTPResult = " & _WD_LastHTTPResult() & @CRLF)

	; JavaScript example that writes to BrowserConsole
	$sValue = _WD_ExecuteScript($sSession, "console.log('Hello world! (from DemoScript: Line #" & @ScriptLineNumber & ")');", Default, Default, $_WD_JSON_Value)
	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : ERROR=" & @error & " $sValue = " & $sValue & " _WD_LastHTTPResult = " & _WD_LastHTTPResult() & @CRLF)

	; JavaScript example with SyntaxError: string literal contains an unescaped line break
	$sValue = _WD_ExecuteScript($sSession, "console.log('Hello world", Default, Default, $_WD_JSON_Value)
	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : ERROR=" & @error & " $sValue = " & $sValue & " _WD_LastHTTPResult = " & _WD_LastHTTPResult() & @CRLF)

	; 2022-03-23 This website no longer exists
	;$sValue = _WD_ExecuteScript($sSession, "return $.ajax({url:'https://hosting105782.a2f0c.netcup.net/test.php',type:'post',dataType: 'text', data:'getaccount=1',success : function(text){return text;}});", Default, $_WD_JSON_Value)
	;ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : ERROR=" & @error & " $sValue = " & $sValue & " _WD_LastHTTPResult = " & _WD_LastHTTPResult() & @CRLF)
EndFunc   ;==>DemoScript

Func DemoCookies()
	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : WD: Navigating:" & @CRLF)
	_Demo_NavigateCheckBanner($sSession, "https://google.com", '//body/div[1][@aria-hidden="true"]')
	If @error Then Return SetError(@error, @extended)

	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : WD: Get all cookies:" & @CRLF)
	Local $sAllCookies = _WD_Cookies($sSession, 'getall')
	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : Cookies (obtained at start after navigate) : " & $sAllCookies & @CRLF)

	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : WD: Get 'NID' cookie:" & @CRLF)
	Local $hTimer = TimerInit()
	Local $sNID
	While 1
		$sNID = _WD_Cookies($sSession, 'Get', 'NID')
		If Not @error Or TimerDiff($hTimer) > 5 * 1000 Then ExitLoop
		Sleep(100) ; this cookie may not exist at start, may appear later when website will be estabilished, so there is need to wait on @error and try again
	WEnd
	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : Cookie obtained 'NID' : " & $sNID & @CRLF)

	Local $sName = "TestName"
	Local $sValue = "TestValue"

	; calculate UNIX EPOCH time
	Local $sNowPlus2Years = _DateAdd('Y', 2, _NowCalc())
	Local $iDateCalc = Int(_DateDiff('s', "1970/01/01 00:00:00", $sNowPlus2Years))

	; create JSON string for cookie
	Local $sCookie = _WD_JsonCookie($sName, $sValue, Default, 'www.google.com', True, False, $iDateCalc, "None")

	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : WD: Add cookie:" & @CRLF)
	_WD_Cookies($sSession, 'add', $sCookie)

	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : WD: Check cookie:" & @CRLF)
	Local $sResult = _WD_Cookies($sSession, 'get', $sName)

	; compare results in console
	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : Cookie added    : " & $sCookie & @CRLF)
	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : Cookie obtained : " & $sResult & @CRLF)

	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : WD: Get all cookies:" & @CRLF)
	$sAllCookies = _WD_Cookies($sSession, 'getall')
	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : Cookies (obtained before 'deleteall') : " & $sAllCookies & @CRLF)

	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : WD: Delete all cookies:" & @CRLF)
	_WD_Cookies($sSession, 'deleteall')

	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : WD: Get all cookies:" & @CRLF)
	$sAllCookies = _WD_Cookies($sSession, 'getall')
	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : Cookies (obtained after 'deleteall') : " & $sAllCookies & @CRLF)

EndFunc   ;==>DemoCookies

Func DemoAlerts()
	Local $sStatus, $sText

	; check status before displaying Alert
	$sStatus = _WD_Alert($sSession, 'status')
	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : " & 'Alert Detected => ' & $sStatus & @CRLF)

	; show Alert for testing
	_WD_ExecuteScript($sSession, "alert('testing 123')")

	; get/check Alert status and text
	$sStatus = _WD_Alert($sSession, 'status')
	$sText = _WD_Alert($sSession, 'gettext')
	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : " & 'Alert Detected => ' & $sStatus & @CRLF)
	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : " & 'Text Detected => ' & $sText & @CRLF)

	Sleep(5000)
	; close Alert by rejection
	_WD_Alert($sSession, 'Dismiss')

	; show Prompt for testing
	_WD_ExecuteScript($sSession, "prompt('User Prompt 1', 'Default value')")
	Sleep(2000)

	; Set value of text field
	_WD_Alert($sSession, 'sendtext', 'new text')

	Sleep(5000)
	; close Alert by acceptance
	_WD_Alert($sSession, 'Accept')

	Sleep(1000)
	; show Prompt for testing
	_WD_ExecuteScript($sSession, "prompt('User Prompt 2', 'Default value')")

	Sleep(5000)
	; close Alert by rejection
	_WD_Alert($sSession, 'Dismiss')


	_WD_Navigate($sSession, 'https://www.quanzhanketang.com/jsref/tryjsref_prompt.html?filename=tryjsref_prompt')
	_WD_LoadWait($sSession)

	_WD_FrameEnter($sSession, 0)

	Local $sButton = _WD_FindElement($sSession, $_WD_LOCATOR_ByCSSSelector, "button[onclick='myFunction()']")

	_WD_ElementAction($sSession, $sButton, 'CLICK')

	Sleep(2000)
	; Set value of text field
	_WD_Alert($sSession, 'sendtext', 'AutoIt user')

	Sleep(2000)
	; close Alert by acceptance
	_WD_Alert($sSession, 'Accept')

	; Validate if prompt was properly filled up by _WD_Alert()
	MsgBox($MB_OK + $MB_TOPMOST + $MB_ICONINFORMATION, "Information", "Check website resposne")

EndFunc   ;==>DemoAlerts

Func DemoFrames()
	Local $sElement, $bIsWindowTop
	Local Const $sArrayHeader = 'Absolute Identifiers > _WD_FrameEnter|Relative Identifiers > _WD_FrameEnter|FRAME attributes|URL|Body ElementID|IsHidden|MatchedElements'

	#Region - Testing how to manage frames
	_Demo_NavigateCheckBanner($sSession, "https://www.w3schools.com/tags/tryit.asp?filename=tryhtml_iframe", '//*[@id="snigel-cmp-framework" and @class="snigel-cmp-framework"]')
	If @error Then Return SetError(@error, @extended)

	Local $iFrameCount = _WD_GetFrameCount($sSession)
	If @error Then Return SetError(@error, @extended)
	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : Frames=" & $iFrameCount & @CRLF)

	$bIsWindowTop = _WD_IsWindowTop($sSession)
	If @error Then Return SetError(@error, @extended)
	; just after navigate current context should be on top level Window
	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : TopWindow = " & $bIsWindowTop & @CRLF)

	$sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//iframe[@id='iframeResult']")
	; changing context to first frame
	_WD_FrameEnter($sSession, $sElement)
	If @error Then Return SetError(@error, @extended)

	$bIsWindowTop = _WD_IsWindowTop($sSession)
	; after changing context to first frame the current context is not on top level Window
	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : TopWindow = " & $bIsWindowTop & @CRLF)

	; changing context to first sub frame using iframe element specified ByXPath
	$sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//iframe")
	_WD_FrameEnter($sSession, $sElement)
	If @error Then Return SetError(@error, @extended)

	; Leaving sub frame
	_WD_FrameLeave($sSession)
	If @error Then Return SetError(@error, @extended)

	$bIsWindowTop = _WD_IsWindowTop($sSession)
	; after leaving sub frame, the current context is back to first frame but still is not on top level Window
	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : TopWindow = " & $bIsWindowTop & @CRLF)

	; Leaving first frame
	_WD_FrameLeave($sSession)
	If @error Then Return SetError(@error, @extended)
	#EndRegion - Testing how to manage frames

	#Region - Testing _WD_FrameList() usage

	#Region - Example 1 ; from 'https://www.w3schools.com' get frame list as string
	$bIsWindowTop = _WD_IsWindowTop($sSession)
	; after leaving first frame, the current context should back on top level Window
	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : TopWindow = " & $bIsWindowTop & @CRLF)

	; now lets try to check frame list and using locations as path 'null/0'
	; firstly go to website
	_WD_Navigate($sSession, 'https://www.w3schools.com/tags/tryit.asp?filename=tryhtml_iframe')
	_WD_LoadWait($sSession)

	Local $sResult = _WD_FrameList($sSession, False)
	ConsoleWrite("! ---> @error=" & @error & "  @extended=" & @extended & " : Example 1" & @CRLF)
	ConsoleWrite($sResult & @CRLF)
	#EndRegion - Example 1 ; from 'https://www.w3schools.com' get frame list as string

	#Region - Example 2 ; from 'https://www.w3schools.com' get frame list as array
	Local $aFrameList = _WD_FrameList($sSession, True)
	ConsoleWrite("! ---> @error=" & @error & "  @extended=" & @extended & " : Example 2" & @CRLF)
	_ArrayDisplay($aFrameList, 'Example 2 - w3schools.com - get frame list as array', 0, 0, Default, $sArrayHeader)

	#EndRegion - Example 2 ; from 'https://www.w3schools.com' get frame list as array

	#Region - Example 3 ; from 'https://www.w3schools.com' get frame list as array, while current location is "null/0"
	; check if document context location is Top Window - should be as we are after navigation
	ConsoleWrite("> " & @ScriptLineNumber & " IsWindowTop = " & _WD_IsWindowTop($sSession) & @CRLF)

	; change document context location by path 'null/0'
	_WD_FrameEnter($sSession, 'null/0')

	; check if document context location is Top Window - should not be as we enter to frame 'null/0'
	ConsoleWrite("> " & @ScriptLineNumber & " IsWindowTop = " & _WD_IsWindowTop($sSession) & @CRLF)

	$aFrameList = _WD_FrameList($sSession, True)
	ConsoleWrite("! ---> @error=" & @error & "  @extended=" & @extended & " : Example 3" & @CRLF)
	_ArrayDisplay($aFrameList, 'Example 3 - w3schools.com - relative to "null/0"', 0, 0, Default, $sArrayHeader)
	#EndRegion - Example 3 ; from 'https://www.w3schools.com' get frame list as array, while current location is "null/0"

	#Region - Example 4 ; from 'https://stackoverflow.com' get frame list as string
	; go to another website
	_WD_Navigate($sSession, 'https://stackoverflow.com/questions/19669786/check-if-element-is-visible-in-dom')
	_WD_LoadWait($sSession)

	$sResult = _WD_FrameList($sSession, False)
	ConsoleWrite("! ---> @error=" & @error & "  @extended=" & @extended & " : Example 4" & @CRLF)
	ConsoleWrite($sResult & @CRLF)
	#EndRegion - Example 4 ; from 'https://stackoverflow.com' get frame list as string

	#Region - Example 5 ; from 'https://stackoverflow.com' get frame list as array
	$aFrameList = _WD_FrameList($sSession, True)
	ConsoleWrite("! ---> @error=" & @error & "  @extended=" & @extended & " : Example 5" & @CRLF)
	_ArrayDisplay($aFrameList, 'Example 5 - stackoverflow.com - get frame list as array', 0, 0, Default, $sArrayHeader)
	#EndRegion - Example 5 ; from 'https://stackoverflow.com' get frame list as array

	#Region - Example 6v1 ; from 'https://stackoverflow.com' get frame list as array, while is current location is "null/2"
	; check if document context location is Top Window - should be as we are after navigation
	ConsoleWrite("> " & @ScriptLineNumber & " IsWindowTop = " & _WD_IsWindowTop($sSession) & @CRLF)

	; change document context location by path 'null/2'
	_WD_FrameEnter($sSession, 'null/2')

	; check if document context location is Top Window - should not be as we enter to frame 'null/2'
	ConsoleWrite("> " & @ScriptLineNumber & " IsWindowTop = " & _WD_IsWindowTop($sSession) & @CRLF)

	$aFrameList = _WD_FrameList($sSession, True)
	ConsoleWrite("! ---> @error=" & @error & "  @extended=" & @extended & " : Example 6v1" & @CRLF)
	_ArrayDisplay($aFrameList, 'Example 6v1 - stackoverflow.com - relative to "null/2"', 0, 0, Default, $sArrayHeader)
	#EndRegion - Example 6v1 ; from 'https://stackoverflow.com' get frame list as array, while is current location is "null/2"

	#Region - Example 6v2 ; from 'https://stackoverflow.com' get frame list as array, check if it is still relative to the same location as it was before recent _WD_FrameList() was used - still should be "null/2"
	; check if document context location is Top Window
	ConsoleWrite("> " & @ScriptLineNumber & " IsWindowTop = " & _WD_IsWindowTop($sSession) & @CRLF)

	$aFrameList = _WD_FrameList($sSession, True)
	ConsoleWrite("! ---> @error=" & @error & "  @extended=" & @extended & " : Example 6v2" & @CRLF)
	_ArrayDisplay($aFrameList, 'Example 6v2 - stackoverflow.com - check if it is still relative to "null/2"', 0, 0, Default, $sArrayHeader)
	#EndRegion - Example 6v2 ; from 'https://stackoverflow.com' get frame list as array, check if it is still relative to the same location as it was before recent _WD_FrameList() was used - still should be "null/2"

	#EndRegion - Testing _WD_FrameList() usage

	#Region - Testing element location in frame set and iframe collecion
	; go to website
	_WD_Navigate($sSession, 'https://www.tutorialspoint.com/html/html_frames.htm#')
	_WD_LoadWait($sSession)

	; check if document context location is Top Window
	ConsoleWrite("> " & @ScriptLineNumber & " IsWindowTop = " & _WD_IsWindowTop($sSession) & @CRLF)

	MsgBox($MB_TOPMOST, "", 'Before checking location of multiple elements on multiple frames' & @CRLF & 'Try the same example with and without waiting about 30 seconds in order to see that many frames should be fully loaded, and to check the differences')

	$aFrameList = _WD_FrameList($sSession, True, 5000, Default)
	ConsoleWrite("! ---> @error=" & @error & "  @extended=" & @extended & " : Example : Testing element location in frame set - after pre-checking list of frames" & @CRLF)
	_ArrayDisplay($aFrameList, @ScriptLineNumber & ' Before _WD_FrameListFindElement - www.tutorialspoint.com - get frame list as array', 0, 0, Default, $sArrayHeader)

	Local $aLocationOfElement = _WD_FrameListFindElement($sSession, $_WD_LOCATOR_ByCSSSelector, "li.nav-item[data-bs-original-title='Home Page'] a.nav-link[href='https://www.tutorialspoint.com/index.htm']")
	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : $aLocationOfElement (" & UBound($aLocationOfElement) & ")=" & @CRLF & _ArrayToString($aLocationOfElement) & @CRLF)
	_ArrayDisplay($aLocationOfElement, @ScriptLineNumber & ' $aLocationOfElement', 0, 0, Default, $sArrayHeader)

	#EndRegion - Testing element location in frame set and iframe collecion
EndFunc   ;==>DemoFrames

Func DemoActions()
	Local $sElement, $sAction

	_Demo_NavigateCheckBanner($sSession, "https://google.com", '//body/div[1][@aria-hidden="true"]')
	If @error Then Return SetError(@error, @extended)

	$sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, $sElementSelector)
	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : $sElement = " & $sElement & @CRLF)

	$sAction = StringReplace( _
			'{' & _
			'	"actions":[' & _
			'		{' & _
			'			"id":"default mouse",' & _
			'			"type":"pointer",' & _
			'			"parameters":{"pointerType":"mouse"},' & _
			'			"actions":[' & _
			_WD_JsonActionPointer("pointerMove", Default, $sElement, 0, 0, 100) & ',' & _
			_WD_JsonActionPointer("pointerDown", $_WD_BUTTON_Right) & ',' & _
			_WD_JsonActionPointer("pointerUp", $_WD_BUTTON_Right) & _
			'			]' & _
			'		}' & _
			'	]' & _
			'}' & _
			'', @TAB, '')

	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : $sAction = " & $sAction & @CRLF)

	; perform Action
	_WD_Action($sSession, "actions", $sAction)
	Sleep(2000)
	Send("Q")
	Sleep(2000)

	_WD_Action($sSession, "actions")
	Sleep(2000)
EndFunc   ;==>DemoActions

Func DemoDownload()
	_Demo_NavigateCheckBanner($sSession, "https://google.com", '//body/div[1][@aria-hidden="true"]')
	If @error Then Return SetError(@error, @extended)

	; Get the website's URL
	Local $sURL = _WD_Action($sSession, 'url')

	; Find the element
	Local $sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//img[@alt='Google']")

	If @error <> $_WD_ERROR_Success Then
		; Try alternate element
		$sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//div[@id='hplogo']//img")
	EndIf

	If @error = $_WD_ERROR_Success Then
		; Retrieve it's source attribute
		Local $sSource = _WD_ElementAction($sSession, $sElement, "Attribute", "src")

		; Combine the URL and element link
		$sURL = _WinAPI_UrlCombine($sURL, $sSource)

		; Download the file
		_WD_DownloadFile($sURL, @ScriptDir & "\testimage.png")

		_WD_DownloadFile("https://www.google.com/notexisting.jpg", @ScriptDir & "\testimage2.jpg")
	EndIf
EndFunc   ;==>DemoDownload

Func DemoWindows()
	Local $sResponse, $hFileOpen, $sHnd1, $sHnd2, $bDecode, $oWRect

	_Demo_NavigateCheckBanner($sSession, "https://google.com", '//body/div[1][@aria-hidden="true"]')
	If @error Then Return SetError(@error, @extended)

	$sHnd1 = '{"handle":"' & _WD_Window($sSession, "window") & '"}'

	_WD_NewTab($sSession)
	$sHnd2 = '{"handle":"' & _WD_Window($sSession, "window") & '"}'
	_Demo_NavigateCheckBanner($sSession, "https://yahoo.com", '//body[contains(@class, "blur-preview-tpl")]')
	If @error Then Return SetError(@error, @extended)

	; Get window coordinates
	$oWRect = _WD_Window($sSession, 'rect')
	ConsoleWrite("wd_demo.au3: (" & @ScriptLineNumber & ") : Window Coords = " & $oWRect.Item('x') & " / " & $oWRect.Item('y') & " / " & $oWRect.Item('width') & " / " & $oWRect.Item('height') & @CRLF)

	; Take screenshot
	_WD_Window($sSession, "switch", $sHnd1)
	$sResponse = _WD_Window($sSession, 'screenshot')
	$bDecode = __WD_Base64Decode($sResponse)

	$hFileOpen = FileOpen("Screen1.png", $FO_BINARY + $FO_OVERWRITE)
	FileWrite($hFileOpen, $bDecode)
	FileClose($hFileOpen)

	; show the result in default viewer
	ShellExecute("Screen1.png")

	; Take another one
	_WD_Window($sSession, "switch", $sHnd2)
	$sResponse = _WD_Window($sSession, 'screenshot')
	$bDecode = __WD_Base64Decode($sResponse)

	$hFileOpen = FileOpen("Screen2.png", $FO_BINARY + $FO_OVERWRITE)
	FileWrite($hFileOpen, $bDecode)
	FileClose($hFileOpen)

	; show the result in default viewer
	ShellExecute("Screen2.png")

EndFunc   ;==>DemoWindows

Func DemoUpload()
	; REMARK This example uses PNG files created in DemoWindows

	; navigate to "file storing" website
	_WD_Navigate($sSession, "https://www.htmlquick.com/reference/tags/input-file.html")

	; select single file
	_WD_SelectFiles($sSession, $_WD_LOCATOR_ByXPath, "//section[@id='examples']//input[@name='uploadedfile']", @ScriptDir & "\Screen1.png")

	; select two files at once
	_WD_SelectFiles($sSession, $_WD_LOCATOR_ByXPath, "//p[contains(text(),'Upload files:')]//input[@name='uploadedfiles[]']", @ScriptDir & "\Screen1.png" & @LF & @ScriptDir & "\Screen2.png")

	; accept/start uploading
	Local $sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//p[contains(text(),'Upload files:')]//input[2]")
	_WD_ElementAction($sSession, $sElement, 'click')
EndFunc   ;==>DemoUpload

Func DemoPrint($sBrowser)
	; navigate to website
	_WD_Navigate($sSession, "https://www.w3.org/TR/webdriver/#print-page")

	; Wait for page will be fully load - max 10 seconds
	_WD_LoadWait($sSession, Default, 10 * 1000)

	; create Print Options
	Local $sOptions = StringReplace( _
			'{' & _
			'	"page": {' & _
			'			"width": 29.70' & _
			'			,"height": 42.00' & _
			'		}' & _
			'	,"margin": {' & _
			'			"top": 2' & _
			'			,"bottom": 2' & _
			'			,"left": 2' & _
			'			,"right": 2' & _
			'		}' & _
			'	,"scale": 0.5' & _
			'	,"orientation": "landscape"' & _
			'	,"shrinkToFit": true' & _
			'	,"background": true' & _
			'	,"pageRanges": ["1", "10-20"]' & _
			'}', @TAB, '')

	; print WebSite content to PDF as Binary
	Local $dBinaryData = _WD_PrintToPdf($sSession, $sOptions)
	If @error Then Return SetError(@error, @extended, $dBinaryData)

	; save PDF to file
	Local $sPDFFileFullPath = @ScriptDir & "\" & $sBrowser & " - DemoPrint.pdf"
	Local $hFile = FileOpen($sPDFFileFullPath, $FO_OVERWRITE + $FO_BINARY)
	FileWrite($hFile, $dBinaryData)
	FileClose($hFile)

	; open PDF in default viewer configured in Windows
	ShellExecute($sPDFFileFullPath)
EndFunc   ;==>DemoPrint

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

Func DemoSelectOptions()
	_WD_Navigate($sSession, 'https://developer.mozilla.org/en-US/docs/Web/HTML/Element/select#advanced_select_with_multiple_features')
	If @error Then Return SetError(@error, @extended, '')

	_WD_LoadWait($sSession)
	If @error Then Return SetError(@error, @extended, '')

	Local $sFrame = _WD_FindElement($sSession, $_WD_LOCATOR_ByCSSSelector, '#frame_advanced_select_with_multiple_features')
	If @error Then Return SetError(@error, @extended, '')

	; change the attributes of the frame to improve the visibility of the <select> element, on which the options will be indicated
	Local $sJavaScript = _
			"var element = arguments[0];" & _
			"element.setAttribute('height', '500');" & _
			"element.setAttribute('padding', '0');"
	_WD_ExecuteScript($sSession, $sJavaScript, __WD_JsonElement($sFrame), Default, Default)
	If @error Then Return SetError(@error, @extended, '')

	; entering to the frame
	_WD_FrameEnter($sSession, $sFrame)
	If @error Then Return SetError(@error, @extended, '')

	; get <select> element by it's name
	Local $sSelectElement = _WD_GetElementByName($sSession, 'pets')
	If @error Then Return SetError(@error, @extended, '')

	; change <select> element size, to see all <option> at once
	$sJavaScript = _
			"var element = arguments[0];" & _
			"element.setAttribute('size', '10')"
	_WD_ExecuteScript($sSession, $sJavaScript, __WD_JsonElement($sSelectElement), Default, Default)

	; select ALL options
	_WD_ElementSelectAction($sSession, $sSelectElement, 'SELECTALL')
	If @error Then Return SetError(@error, @extended, '')
	MsgBox($MB_OK + $MB_TOPMOST + $MB_ICONINFORMATION, "Information", "After SELECTALL")

	; deselect ALL options
	_WD_ElementSelectAction($sSession, $sSelectElement, 'DESELECTALL')
	If @error Then Return SetError(@error, @extended, '')
	MsgBox($MB_OK + $MB_TOPMOST + $MB_ICONINFORMATION, "Information", "After DESELECTALL")

	; select desired options
	Local $aOptionsToSelect[] = ['Cat', 'HAMSTER', 'parrot', 'albatroSS']
	_WD_ElementSelectAction($sSession, $sSelectElement, 'MULTISELECT', $aOptionsToSelect)
	If @error Then Return SetError(@error, @extended, '')
	MsgBox($MB_OK + $MB_TOPMOST + $MB_ICONINFORMATION, "Information", "After MULTISELECT: Cat / HAMSTER / parrot / albatroSS")

	; retrieves selected <option> elements as 2D array
	Local $aSelectedOptions = _WD_ElementSelectAction($sSession, $sSelectElement, 'selectedOptions')
	If @error Then Return SetError(@error, @extended, '')

	_ArrayDisplay($aSelectedOptions, '$aSelectedOptions')

	_WD_ElementSelectAction($sSession, $sSelectElement, 'SINGLESELECT', 'PARROT')
	If @error Then Return SetError(@error, @extended, '')
	MsgBox($MB_OK + $MB_TOPMOST + $MB_ICONINFORMATION, "Information", "After SINGLESELECT: PARROT (Parrot)")

	; retrieves all <option> elements as 2D array
	Local $aAllOptions = _WD_ElementSelectAction($sSession, $sSelectElement, 'OPTIONS')
	If @error Then Return SetError(@error, @extended, '')

	_ArrayDisplay($aAllOptions, '$aAllOptions')

	; deselect ALL options
	_WD_ElementSelectAction($sSession, $sSelectElement, 'DESELECTALL')
	If @error Then Return SetError(@error, @extended, '')

	; disable 'multiple' attribute for <select> element
	$sJavaScript = _
			"var element = arguments[0];" & _
			"element.multiple = false"
	_WD_ExecuteScript($sSession, $sJavaScript, __WD_JsonElement($sSelectElement), Default, Default)

	; this will set @error as <select> element does not have a 'multiple' attribute
	_WD_ElementSelectAction($sSession, $sSelectElement, 'MULTISELECT', $aOptionsToSelect)
	MsgBox($MB_OK + $MB_TOPMOST + $MB_ICONINFORMATION, "Information", "After MULTISELECT on <select> element with disabled 'multiple' attribute" & @CRLF & "@error=" & @error)

	; now will test enabled/disabled OPTGROUP
	_WD_Navigate($sSession, 'https://developer.mozilla.org/en-US/docs/Web/HTML/Element/optgroup#examples')
	If @error Then Return SetError(@error, @extended, '')

	_WD_LoadWait($sSession)
	If @error Then Return SetError(@error, @extended, '')

	Local $sFrame2 = _WD_FindElement($sSession, $_WD_LOCATOR_ByCSSSelector, '#frame_examples')
	If @error Then Return SetError(@error, @extended, '')

	; change the attributes of the frame to improve the visibility of the <select> element, on which the options will be indicated
	Local $sJavaScript2 = _
			"var element = arguments[0];" & _
			"element.setAttribute('height', '500');" & _
			"element.setAttribute('padding', '0');"
	_WD_ExecuteScript($sSession, $sJavaScript2, __WD_JsonElement($sFrame2), Default, Default)
	If @error Then Return SetError(@error, @extended, '')

	; entering to the frame
	_WD_FrameEnter($sSession, $sFrame2)
	If @error Then Return SetError(@error, @extended, '')

	; get <select> element
	Local $sSelectElement2 = _WD_FindElement($sSession, $_WD_LOCATOR_ByCSSSelector, "body > select")
	If @error Then Return SetError(@error, @extended, '')

	; change <select> element size, to see all <option> at once
	$sJavaScript2 = _
			"var element = arguments[0];" & _
			"element.setAttribute('size', '9')"
	_WD_ExecuteScript($sSession, $sJavaScript2, __WD_JsonElement($sSelectElement2), Default, Default)

	$sJavaScript2 = _
			"var element = arguments[0];" & _
			"element.setAttribute('multiple','')"
	_WD_ExecuteScript($sSession, $sJavaScript2, __WD_JsonElement($sSelectElement2), Default, Default)

	; select ALL options
	_WD_ElementSelectAction($sSession, $sSelectElement2, 'SELECTALL')
	If @error Then Return SetError(@error, @extended, '')
	MsgBox($MB_OK + $MB_TOPMOST + $MB_ICONINFORMATION, "Information", "After SELECTALL")

	; deselect ALL options
	_WD_ElementSelectAction($sSession, $sSelectElement2, 'DESELECTALL')
	If @error Then Return SetError(@error, @extended, '')
	MsgBox($MB_OK + $MB_TOPMOST + $MB_ICONINFORMATION, "Information", "After DESELECTALL")

	; select desired <option> elements one after other each separately
	Local $aOptions2[] = ['Option 1.1']
	_WD_ElementSelectAction($sSession, $sSelectElement2, 'MULTISELECT', $aOptions2)
	If @error Then Return SetError(@error, @extended, '')

	$aOptions2[0] = 'Option 2.1'
	_WD_ElementSelectAction($sSession, $sSelectElement2, 'MULTISELECT', $aOptions2)
	If @error Then Return SetError(@error, @extended, '')

	$aOptions2[0] = 'Option 3.1' ; this will set @error as 'Option 3.1' is disabled
	_WD_ElementSelectAction($sSession, $sSelectElement2, 'MULTISELECT', $aOptions2)
	MsgBox($MB_OK + $MB_TOPMOST + $MB_ICONINFORMATION, "Information", "After MULTISELECT: 1.1 / 2.1 / 3.1" & @CRLF & "<option> elements one after other each separately" & @CRLF & "@error=" & @error)

	; retrieves all <option> elements as 2D array
	Local $aAllOptions2 = _WD_ElementSelectAction($sSession, $sSelectElement2, 'OPTIONS')
	If @error Then Return SetError(@error, @extended, '')

	_ArrayDisplay($aAllOptions2, '$aAllOptions2')

	_WD_ElementSelectAction($sSession, $sSelectElement2, 'SINGLESELECT', 'Option 2.1')
	If @error Then Return SetError(@error, @extended, '')
	MsgBox($MB_OK + $MB_TOPMOST + $MB_ICONINFORMATION, "Information", "After SINGLESELECT: 2.1")

	; this will set @error as 'Option 3.2' is disabled
	_WD_ElementSelectAction($sSession, $sSelectElement2, 'SINGLESELECT', 'Option 3.2')
	MsgBox($MB_OK + $MB_TOPMOST + $MB_ICONINFORMATION, "Information", "After SINGLESELECT: 3.2 - disabled <option> element" & @CRLF & "@error=" & @error)

EndFunc   ;==>DemoSelectOptions

Func DemoStyles()
	_WD_Navigate($sSession, 'https://github.com/Danp2/au3WebDriver/pull/310')
	_WD_LoadWait($sSession)

	; get element
	Local $sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByCSSSelector, '#repository-container-header')
	ConsoleWrite("! ---> @error=" & @error & "  @extended=" & @extended & @CRLF)
	MsgBox($MB_OK + $MB_TOPMOST + $MB_ICONINFORMATION, "Information", 'Focus on header (currently not changed)')

	; add new fontFamily style
	_WD_ElementStyle($sSession, $sElement, 'fontFamily', '"Lucida Console", "Courier New", monospace')
	ConsoleWrite("! ---> @error=" & @error & "  @extended=" & @extended & @CRLF)

	; check list of styles
	Local $aListof_CSSProperties_v1 = _WD_ElementStyle($sSession, $sElement)
	ConsoleWrite("! ---> @error=" & @error & "  @extended=" & @extended & @CRLF)
	_ArrayDisplay($aListof_CSSProperties_v1, '$aListof_CSSProperties_v1')

	; check out a single specific style
	Local $sFontFamily = _WD_ElementStyle($sSession, $sElement, "font-family")
	ConsoleWrite("! ---> @error=" & @error & "  @extended=" & @extended & @CRLF)
	MsgBox($MB_OK + $MB_TOPMOST + $MB_ICONINFORMATION, "Information", $sFontFamily)

	; remove 'fontFamily' style
	_WD_ElementStyle($sSession, $sElement, 'fontFamily', '')
	ConsoleWrite("! ---> @error=" & @error & "  @extended=" & @extended & @CRLF)

	; remove 'backgroundColor' style
	_WD_ElementStyle($sSession, $sElement, 'backgroundColor', '')
	ConsoleWrite("! ---> @error=" & @error & "  @extended=" & @extended & @CRLF)

	; again - check list of styles
	Local $aListof_CSSProperties_v2 = _WD_ElementStyle($sSession, $sElement)
	ConsoleWrite("! ---> @error=" & @error & "  @extended=" & @extended & @CRLF)
	_ArrayDisplay($aListof_CSSProperties_v2, '$aListof_CSSProperties_v2')

	; additional check
	If Not UBound($aListof_CSSProperties_v2) Then MsgBox($MB_OK + $MB_TOPMOST + $MB_ICONINFORMATION, "Information", 'All styles has been removed.')

EndFunc   ;==>DemoStyles

#Region - UserTesting
Func UserTesting()
	; if necessary, you can modify the following function content by replacing, adding any additional function required for testing within this function
	Local $vResult
	$vResult = _WD_Navigate($sSession, 'https://www.google.com')
	If @error Then Return SetError(@error, @extended, $vResult)

	$vResult = _WD_LoadWait($sSession, 10, Default, Default, $_WD_READYSTATE_Interactive)
	If @error Then Return SetError(@error, @extended, $vResult)

	ConsoleWrite("- Test 1:" & @CRLF)
	_WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, '')
	If @error Then Return SetError(@error, @extended, $vResult)

	ConsoleWrite("- Test 2:" & @CRLF)
	$vResult = _WD_WaitElement($sSession, $_WD_LOCATOR_ByCSSSelector, '#fake', 1000, 3000, $_WD_OPTION_NoMatch)
	If @error Then Return SetError(@error, @extended, $vResult)
EndFunc   ;==>UserTesting

; if necessary, add any additional function required for testing within this region here
#EndRegion - UserTesting

Func UserFile()
	; Modify the contents of UserTesting.au3 (or create new one) to change the code being executed.
	; Changes can be made and executed without restarting this script,
	;	you can even repeat "UserFile" processing without closing browser
	Local Const $aEmpty1D[UBound($_VAR)] = []
	Local $sScriptFileFullPath, $aCmds

	Do
		$_VAR = $aEmpty1D ; clean up the globally declared $_VAR to ensure repeatable test conditions
		$sScriptFileFullPath = FileOpenDialog('Choose testing script', @ScriptDir, 'AutoIt script file (*.au3)', $FD_FILEMUSTEXIST, 'UserTesting.au3')
		If @error Then Return SetError(@error, @extended)

		$aCmds = FileReadToArray($sScriptFileFullPath)
		If @error Then Return SetError(@error, @extended)

		For $sCmd In $aCmds
			; Strip comments
			; https://www.autoitscript.com/forum/topic/157255-regular-expression-challenge-for-stripping-single-comments/?do=findComment&comment=1138896
			$sCmd = StringRegExpReplace($sCmd, '(?m)^(?:[^;"'']|''[^'']*''|"[^"]*")*\K;.*', "")
			If $sCmd Then Execute($sCmd)
		Next

	Until $IDNO = MsgBox($MB_YESNO + $MB_TOPMOST + $MB_ICONQUESTION + $MB_DEFBUTTON2, 'Question', 'Do you want to process another file?')

EndFunc   ;==>UserFile

Func __SetVAR($IDX_VAR, $value)
	$_VAR[$IDX_VAR] = $value
	ConsoleWrite('- Setting $_VAR[' & $IDX_VAR & '] = ' & ((IsArray($value)) ? ('{array}') : ($value)) & @CRLF)
EndFunc   ;==>__SetVAR

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

Func _Demo_NavigateCheckBanner($sSession, $sURL, $sXpath)
	_WD_Navigate($sSession, $sURL)
	If @error Then Return SetError(@error, @extended, 0)

	_WD_LoadWait($sSession)
	If @error Then Return SetError(@error, @extended, 0)

	; Check if designated element is visible, as it can hide all sub elements in case when COOKIE aproval message is visible
	_WD_WaitElement($sSession, $_WD_LOCATOR_ByXPath, $sXpath, 0, 1000 * 60, $_WD_OPTION_NoMatch)
	If @error Then
		Local $iErr = @error, $iExt = @extended
		ConsoleWrite('wd_demo.au3: (' & @ScriptLineNumber & ') : "' & $sURL & '" page view is hidden - it is possible that the message about COOKIE files was not accepted')
		Return SetError($iErr, $iExt)
	EndIf

	_WD_LoadWait($sSession)
	Return SetError(@error, @extended, 0)
EndFunc   ;==>_Demo_NavigateCheckBanner

Func SetupGecko($bHeadless)
	_WD_Option('Driver', 'geckodriver.exe')
	_WD_Option('DriverParams', '--log trace')
	_WD_Option('Port', 4444)

;~ 	Local $sCapabilities = '{"capabilities": {"alwaysMatch": {"browserName": "firefox", "acceptInsecureCerts":true}}}'
	_WD_CapabilitiesStartup()
	_WD_CapabilitiesAdd('alwaysMatch', 'firefox')
	_WD_CapabilitiesAdd('browserName', 'firefox')
	_WD_CapabilitiesAdd('acceptInsecureCerts', True)
	; REMARKS
	; When using 32bit geckodriver.exe, you may need to set 'binary' option.
	; This shouldn't be needed when using 64bit geckodriver.exe,
	;  but at the same time setting it is not affecting the script.
	Local $sPath = _WD_GetBrowserPath("firefox")
	If Not @error Then
		_WD_CapabilitiesAdd('binary', $sPath)
		ConsoleWrite("wd_demo.au3: _WD_GetBrowserPath() > " & $sPath & @CRLF)
	EndIf

	If $bHeadless Then _WD_CapabilitiesAdd('args', '--headless')
	_WD_CapabilitiesDump(@ScriptLineNumber) ; dump current Capabilities setting to console - only for testing in this demo
	Local $sCapabilities = _WD_CapabilitiesGet()
	Return $sCapabilities
EndFunc   ;==>SetupGecko

Func SetupChrome($bHeadless)
	_WD_Option('Driver', 'chromedriver.exe')
	_WD_Option('Port', 9515)
	_WD_Option('DriverParams', '--verbose --log-path="' & @ScriptDir & '\chrome.log"')

;~ 	Local $sCapabilities = '{"capabilities": {"alwaysMatch": {"goog:chromeOptions": {"w3c": true, "excludeSwitches": [ "enable-automation"]}}}}'
	_WD_CapabilitiesStartup()
	_WD_CapabilitiesAdd('alwaysMatch', 'chrome')
	_WD_CapabilitiesAdd('w3c', True)
	_WD_CapabilitiesAdd('excludeSwitches', 'enable-automation')
	If $bHeadless Then _WD_CapabilitiesAdd('args', '--headless')
	_WD_CapabilitiesDump(@ScriptLineNumber) ; dump current Capabilities setting to console - only for testing in this demo
	Local $sCapabilities = _WD_CapabilitiesGet()
	Return $sCapabilities
EndFunc   ;==>SetupChrome

Func SetupEdge($bHeadless)
	_WD_Option('Driver', 'msedgedriver.exe')
	_WD_Option('Port', 9515)
	_WD_Option('DriverParams', '--verbose --log-path="' & @ScriptDir & '\msedge.log"')

;~ 	Local $sCapabilities = '{"capabilities": {"alwaysMatch": {"ms:edgeOptions": {"excludeSwitches": [ "enable-automation"]}}}}'
	_WD_CapabilitiesStartup()
	_WD_CapabilitiesAdd('alwaysMatch', 'msedge')
	_WD_CapabilitiesAdd('excludeSwitches', 'enable-automation')
	If $bHeadless Then _WD_CapabilitiesAdd('args', '--headless')
	_WD_CapabilitiesDump(@ScriptLineNumber) ; dump current Capabilities setting to console - only for testing in this demo
	Local $sCapabilities = _WD_CapabilitiesGet()
	Return $sCapabilities
EndFunc   ;==>SetupEdge

Func SetupOpera($bHeadless)
	_WD_Option('Driver', 'operadriver.exe')
	_WD_Option('Port', 9515)
	_WD_Option('DriverParams', '--verbose --log-path="' & @ScriptDir & '\opera.log"')

;~ 	Local $sCapabilities = '{"capabilities": {"alwaysMatch":{"goog:chromeOptions": {"w3c":true, "excludeSwitches":["enable-automation"], "binary":"C:\\Users\\......\\AppData\\Local\\Programs\\Opera\\opera.exe"}}}}'
	_WD_CapabilitiesStartup()
	_WD_CapabilitiesAdd('alwaysMatch', 'opera')
	_WD_CapabilitiesAdd('w3c', True)
	_WD_CapabilitiesAdd('excludeSwitches', 'enable-automation')
	; REMARKS
	; When using 32bit operadriver.exe, you may need to set 'binary' option.
	; This shouldn't be needed when using 64bit operadriver.exe,
	;  but at the same time setting it is not affecting the script.
	Local $sPath = _WD_GetBrowserPath("opera")
	If Not @error Then
		_WD_CapabilitiesAdd('binary', $sPath)
		ConsoleWrite("wd_demo.au3: _WD_GetBrowserPath() > " & $sPath & @CRLF)
	EndIf

	If $bHeadless Then _WD_CapabilitiesAdd('args', '--headless')
	_WD_CapabilitiesDump(@ScriptLineNumber) ; dump current Capabilities setting to console - only for testing in this demo
	Local $sCapabilities = _WD_CapabilitiesGet()
	Return $sCapabilities
EndFunc   ;==>SetupOpera

Func SetupEdgeIEMode() ; this is for MS Edge IE Mode
	; https://www.selenium.dev/documentation/ie_driver_server/#required-configuration
	Local $sTimeStamp = @YEAR & '-' & @MON & '-' & @MDAY & '_' & @HOUR & @MIN & @SEC
	_WD_Option('Driver', 'IEDriverServer.exe') ;
	Local $iPort = _WD_GetFreePort(5555, 5600)
	If @error Then Return SetError(@error, @extended, 0)
	_WD_Option('Port', $iPort)
	_WD_Option('DriverParams', '-log-file="' & @ScriptDir & '\log\' & $sTimeStamp & '_WebDriver_EdgeIEMode.log" -log-level=INFO' & " -port=" & $_WD_PORT & " -host=127.0.0.1")

;~ 	Local $sCapabilities = '{"capabilities": {"alwaysMatch": { "se:ieOptions" : { "ie.edgepath":"C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe", "ie.edgechromium":true, "ignoreProtectedModeSettings":true,"excludeSwitches": ["enable-automation"]}}}}'
	_WD_CapabilitiesStartup()
	_WD_CapabilitiesAdd('alwaysMatch', 'msedgeie')
	_WD_CapabilitiesAdd('w3c', True)
	Local $sPath = _WD_GetBrowserPath("msedge")
	If $sPath Then _WD_CapabilitiesAdd("ie.edgepath", $sPath)
	_WD_CapabilitiesAdd("ie.edgechromium", True)
	_WD_CapabilitiesAdd("ignoreProtectedModeSettings", True)
	_WD_CapabilitiesAdd("initialBrowserUrl", "https://google.com")
	_WD_CapabilitiesAdd('excludeSwitches', 'enable-automation')
	_WD_CapabilitiesDump(@ScriptLineNumber)
	Local $sCapabilities = _WD_CapabilitiesGet()
	Return $sCapabilities
EndFunc   ;==>SetupEdgeIEMode
