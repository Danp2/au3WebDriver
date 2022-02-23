#include-once
#include <WinAPIProc.au3>
#include "JSON.au3" ; https://www.autoitscript.com/forum/topic/148114-a-non-strict-json-udf-jsmn
#include "WinHttp.au3" ; https://www.autoitscript.com/forum/topic/84133-winhttp-functions/

#Region Copyright
#cs
	* WD_Core.au3
	*
	* MIT License
	*
	* Copyright (c) 2022 Dan Pollak (@Danp2)
	*
	* Permission is hereby granted, free of charge, to any person obtaining a copy
	* of this software and associated documentation files (the "Software"), to deal
	* in the Software without restriction, including without limitation the rights
	* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	* copies of the Software, and to permit persons to whom the Software is
	* furnished to do so, subject to the following conditions:
	*
	* The above copyright notice and this permission notice shall be included in all
	* copies or substantial portions of the Software.
	*
	* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	* SOFTWARE.
#ce
#EndRegion Copyright

#ignorefunc _WD_IsLatestRelease
#Region Description
; ==============================================================================
; UDF ...........: WD_Core.au3
; Description ...: A UDF for Web Driver automation
; Requirement ...: JSON UDF
;                  https://www.autoitscript.com/forum/topic/148114-a-non-strict-json-udf-jsmn
;                  WinHTTP UDF
;                  https://www.autoitscript.com/forum/topic/84133-winhttp-functions/
;
;                  WebDriver for desired browser
;                  Chrome WebDriver https://sites.google.com/a/chromium.org/chromedriver/downloads
;                  FireFox WebDriver https://github.com/mozilla/geckodriver/releases
;                  Edge WebDriver https://developer.microsoft.com/en-us/microsoft-edge/tools/webdriver/
;
;                  Discussion Thread on Autoit Forums
;                  https://www.autoitscript.com/forum/topic/191990-webdriver-udf-w3c-compliant-version
;
; Author(s) .....: Dan Pollak
; AutoIt Version : v3.3.14.5
; ==============================================================================
#EndRegion Description

#Region Many thanks to:
#cs
	- Jonathan Bennett (@Jon) and the AutoIt Team
	- Thorsten Willert (@Stilgar), author of FF.au3, which I've used as a model
	- Michał Lipok (@mLipok) for all his feedback / suggestions
	- @water for his work on the help file
#ce
#EndRegion Many thanks to:

#Region Global Constants
Global Const $__WDVERSION = "0.6.0"

Global Const $_WD_ELEMENT_ID = "element-6066-11e4-a52e-4f735466cecf"
Global Const $_WD_SHADOW_ID = "shadow-6066-11e4-a52e-4f735466cecf"
Global Const $_WD_EmptyDict = "{}"

Global Const $_WD_LOCATOR_ByCSSSelector = "css selector"
Global Const $_WD_LOCATOR_ByXPath = "xpath"
Global Const $_WD_LOCATOR_ByLinkText = "link text"
Global Const $_WD_LOCATOR_ByPartialLinkText = "partial link text"
Global Const $_WD_LOCATOR_ByTagName = "tag name"

Global Const $_WD_JSON_Value = "[value]"
Global Const $_WD_JSON_Element = "[value][" & $_WD_ELEMENT_ID & "]"
Global Const $_WD_JSON_Shadow = "[value][" & $_WD_SHADOW_ID & "]"
Global Const $_WD_JSON_Error = "[value][error]"

Global Enum _
		$_WD_DEBUG_None = 0, _ ; No logging to console
		$_WD_DEBUG_Error, _    ; Error logging to console
		$_WD_DEBUG_Info        ; Full logging to console

Global Enum _
		$_WD_ERROR_Success = 0, _ ; No error
		$_WD_ERROR_GeneralError, _ ; General error
		$_WD_ERROR_SocketError, _ ; No socket
		$_WD_ERROR_InvalidDataType, _ ; Invalid data type (IP, URL, Port ...)
		$_WD_ERROR_InvalidValue, _ ; Invalid value in function-call
		$_WD_ERROR_InvalidArgue, _ ; Invalid argument in function-call
		$_WD_ERROR_SendRecv, _ ; Send / Recv Error
		$_WD_ERROR_Timeout, _ ; Connection / Send / Recv timeout
		$_WD_ERROR_NoMatch, _ ; No match for _WDAction-find/search _WDGetElement...
		$_WD_ERROR_RetValue, _ ; Error echo from Repl e.g. _WDAction("fullscreen","true") <> "true"
		$_WD_ERROR_Exception, _ ; Exception from web driver
		$_WD_ERROR_InvalidExpression, _ ; Invalid expression in XPath query or RegEx
		$_WD_ERROR_NoAlert, _ ; No alert present when calling _WD_Alert
		$_WD_ERROR_NotFound, _ ;
		$_WD_ERROR_ElementIssue, _ ;
		$_WD_ERROR_SessionInvalid, _ ;
		$_WD_ERROR_UnknownCommand, _ ;
		$_WD_ERROR_UserAbort, _ ;
		$_WD_ERROR_FileIssue, _ ;
		$_WD_ERROR_COUNTER ;

Global Enum _
		$_WD_BROWSER_Name, _
		$_WD_BROWSER_ExeName, _
		$_WD_BROWSER_DriverName, _
		$_WD_BROWSER_64Bit, _
		$_WD_BROWSER_OptionsKey, _
		$_WD_BROWSER__COUNTER

Global Const $aWD_ERROR_DESC[$_WD_ERROR_COUNTER] = [ _
		"Success", _
		"General Error", _
		"Socket Error", _
		"Invalid data type", _
		"Invalid value", _
		"Invalid argument", _
		"Send / Recv error", _
		"Timeout", _
		"No match", _
		"Error return value", _
		"Webdriver Exception", _
		"Invalid Expression", _
		"No alert present", _
		"Not found", _
		"Element interaction issue", _
		"Invalid session ID", _
		"Unknown Command", _
		"User Aborted", _
		"File issue" _
		]

Global Const $WD_ErrorInvalidSession = "invalid session id"
Global Const $WD_ErrorUnknownCommand = "unknown command"
Global Const $WD_ErrorTimeout = "timeout"
Global Const $WD_NoSuchAlert = "no such alert"

Global Const $WD_Element_NotFound = "no such element"
Global Const $WD_Element_Stale = "stale element reference"
Global Const $WD_Element_Invalid = "invalid argument"
Global Const $WD_Element_Intercept = "element click intercepted"
Global Const $WD_Element_NotInteract = "element not interactable"

Global Const $WD_WinHTTPTimeoutMsg = "WinHTTP request timed out before Webdriver"
#EndRegion Global Constants

#Region Global Variables
Global $_WD_DRIVER = "" ; Path to web driver executable
Global $_WD_DRIVER_PARAMS = "" ; Parameters to pass to web driver executable
Global $_WD_BASE_URL = "HTTP://127.0.0.1"
Global $_WD_PORT = 0 ; Port used for web driver communication
Global $_WD_OHTTP = ObjCreate("winhttp.winhttprequest.5.1")
Global $_WD_HTTPRESULT ; Result of last WinHTTP request
Global $_WD_SESSION_DETAILS = "" ; Response from _WD_CreateSession
Global $_WD_BFORMAT = $SB_UTF8 ; Binary format
Global $_WD_ESCAPE_CHARS = '\\"' ; Characters to escape
Global $_WD_DRIVER_CLOSE = True ; Close prior driver instances before launching new one
Global $_WD_DRIVER_DETECT = True ; Don't launch new driver instance if one already exists
Global $_WD_RESPONSE_TRIM = 100 ; Trim response string to given value for debug output
Global $_WD_ERROR_MSGBOX = True ; Shows in compiled scripts error messages in msgboxes
Global $_WD_DEBUG = $_WD_DEBUG_Info ; Trace to console and show web driver app
Global $_WD_CONSOLE = ConsoleWrite ; Destination for console output
Global $_WD_IFILTER = 16 ; Passed to _HtmlTableGetWriteToArray to control filtering
Global $_WD_Sleep = Sleep ; Default to calling standard Sleep function
Global $_WD_DefaultTimeout = 10000 ; 10 seconds
Global $_WD_WINHTTP_TIMEOUTS = True
Global $_WD_HTTPTimeOuts[4] = [0, 60000, 30000, 30000]
Global $_WD_HTTPContentType = "Content-Type: application/json"

Global $_WD_SupportedBrowsers[][$_WD_BROWSER__COUNTER] = _
		[ _
		["chrome", "chrome.exe", "chromedriver.exe", False, "goog:chromeOptions"], _
		["firefox", "firefox.exe", "geckodriver.exe", True, "moz:firefoxOptions"], _
		["msedge", "msedge.exe", "msedgedriver.exe", True, "ms:edgeOptions"], _
		["opera", "opera.exe", "operadriver.exe", True, "operaOptions"] _
		]
#EndRegion Global Variables

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_CreateSession
; Description ...: Request new session from web driver.
; Syntax ........: _WD_CreateSession([$sCapabilities = Default])
; Parameters ....: $sCapabilities - [optional] Requested features in JSON format. Default is "{}"
; Return values .: Success - Session ID to be used in future requests to web driver session.
;                  Failure - "" (empty string) and sets @error to $_WD_ERROR_Exception.
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......: _WD_DeleteSession
; Link ..........: https://www.w3.org/TR/webdriver#new-session
; Example .......: No
; ===============================================================================================================================
Func _WD_CreateSession($sCapabilities = Default)
	Local Const $sFuncName = "_WD_CreateSession"
	Local $sSession = ""

	If $sCapabilities = Default Then $sCapabilities = $_WD_EmptyDict

	Local $sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session", $sCapabilities)
	Local $iErr = @error

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & $sResponse & @CRLF)
	EndIf

	If $iErr = $_WD_ERROR_Success Then
		Local $oJSON = Json_Decode($sResponse)
		$sSession = Json_Get($oJSON, "[value][sessionId]")

		If @error Then
			Local $sMessage = Json_Get($oJSON, "[value][message]")

			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception, $sMessage), $_WD_HTTPRESULT, "")
		EndIf
	Else
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception, "HTTP status = " & $_WD_HTTPRESULT), $_WD_HTTPRESULT, "")
	EndIf

	; Save response details for future use
	$_WD_SESSION_DETAILS = $sResponse

	Return SetError($_WD_ERROR_Success, $_WD_HTTPRESULT, $sSession)
EndFunc   ;==>_WD_CreateSession

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_DeleteSession
; Description ...:  Delete existing session.
; Syntax ........: _WD_DeleteSession($sSession)
; Parameters ....: $sSession - Session ID from _WD_CreateSession
; Return values .: Success - 1
;                  Failure - 0 and sets @error to $_WD_ERROR_Exception
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......: _WD_CreateSession
; Link ..........: https://www.w3.org/TR/webdriver#delete-session
; Example .......: No
; ===============================================================================================================================
Func _WD_DeleteSession($sSession)
	Local Const $sFuncName = "_WD_DeleteSession"

	Local $sResponse = __WD_Delete($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession)
	Local $iErr = @error

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & $sResponse & @CRLF)
	EndIf

	If $iErr Then
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception, "HTTP status = " & $_WD_HTTPRESULT), $_WD_HTTPRESULT, 0)
	EndIf

	Return SetError($_WD_ERROR_Success, $_WD_HTTPRESULT, 1)
EndFunc   ;==>_WD_DeleteSession

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_Status
; Description ...: Get current web driver state.
; Syntax ........: _WD_Status()
; Parameters ....: None
; Return values .: Success - Dictionary object with "message" and "ready" properties.
;                  Failure - "" (empty string) and sets @error to $_WD_ERROR_Exception
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........: https://www.w3.org/TR/webdriver#status
; Example .......: No
; ===============================================================================================================================
Func _WD_Status()
	Local Const $sFuncName = "_WD_Status"
	Local $sResponse = __WD_Get($_WD_BASE_URL & ":" & $_WD_PORT & "/status")
	Local $iErr = @error, $oResult = Null

	If $iErr = $_WD_ERROR_Success Then
		Local $oJSON = Json_Decode($sResponse)
		$oResult = Json_Get($oJSON, $_WD_JSON_Value)
	EndIf

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & $sResponse & @CRLF)
	EndIf

	If $iErr Then
		Return SetError(__WD_Error($sFuncName, $iErr, "HTTP status = " & $_WD_HTTPRESULT), $_WD_HTTPRESULT, 0)
	EndIf

	Return SetError($_WD_ERROR_Success, $_WD_HTTPRESULT, $oResult)
EndFunc   ;==>_WD_Status

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_GetSession
; Description ...:  Get details on existing session.
; Syntax ........: _WD_GetSession($sSession)
; Parameters ....: $sSession - Session ID from _WD_CreateSession
; Return values .: Success - Dictionary object with "sessionId" and "capabilities" items.
;                  Failure - "" (empty string) and sets @error to $_WD_ERROR_Exception
; Author ........: Danp2
; Modified ......:
; Remarks .......: The Get Session functionality was added and then removed from the W3C draft spec, so the code is commented
;                  until they determine how this should function. See w3c/webdriver@35df53a for details. Meanwhile, I temporarily
;                  changed the code to return the information that is available
; Related .......: _WD_CreateSession
; Link ..........: https://www.w3.org/TR/webdriver#get-session
; Example .......: No
; ===============================================================================================================================
Func _WD_GetSession($sSession)
	Local Const $sFuncName = "_WD_GetSession"
	Local $sResult
	#forceref $sSession, $sFuncName

	#cs See remarks in header
	Local $sResponse = __WD_Get($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession)
	Local $iErr = @error, $sResult = ''

	If $iErr = $_WD_ERROR_Success Then
		Local $oJSON = Json_Decode($sResponse)
		$sResult = Json_Get($oJSON, $_WD_JSON_Value)
	EndIf

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & $sResponse & @CRLF)
	EndIf

	If $iErr Then
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception, "HTTP status = " & $_WD_HTTPRESULT), $_WD_HTTPRESULT, $sResult)
	EndIf
	#ce See remarks in header

	$sResult = $_WD_SESSION_DETAILS

	Return SetError($_WD_ERROR_Success, $_WD_HTTPRESULT, $sResult)
EndFunc   ;==>_WD_GetSession

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_Timeouts
; Description ...:  Set or retrieve the session timeout parameters.
; Syntax ........: _WD_Timeouts($sSession[, $sTimeouts = Default])
; Parameters ....: $sSession  - Session ID from _WD_CreateSession
;                  $sTimeouts - [optional] Requested timouts in JSON format. Default is ""
; Return values .: Success - Return value from web driver in JSON format.
;                  Failure - 0 and sets @error to $_WD_ERROR_Exception
; Author ........: Danp2
; Modified ......:
; Remarks .......: Separate timeouts can be set for "script", "pageLoad", and "implicit"
; Related .......:
; Link ..........: https://www.w3.org/TR/webdriver#get-timeouts
;                  https://www.w3.org/TR/webdriver#set-timeouts
; Example .......: No
; ===============================================================================================================================
Func _WD_Timeouts($sSession, $sTimeouts = Default)
	Local Const $sFuncName = "_WD_Timeouts"
	Local $sResponse, $sURL

	If $sTimeouts = Default Then $sTimeouts = ''

	$sURL = $_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/timeouts"

	If $sTimeouts = '' Then
		$sResponse = __WD_Get($sURL)
	Else
		$sResponse = __WD_Post($sURL, $sTimeouts)
	EndIf

	Local $iErr = @error

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & $sResponse & @CRLF)
	EndIf

	If $iErr Then
		Return SetError(__WD_Error($sFuncName, $iErr, "HTTP status = " & $_WD_HTTPRESULT), $_WD_HTTPRESULT, 0)
	EndIf

	Return SetError($_WD_ERROR_Success, $_WD_HTTPRESULT, $sResponse)
EndFunc   ;==>_WD_Timeouts

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_Navigate
; Description ...: Navigate to the designated URL.
; Syntax ........: _WD_Navigate($sSession, $sURL)
; Parameters ....: $sSession - Session ID from _WD_CreateSession
;                  $sURL     - Destination URL
; Return values .: Success - 1.
;                  Failure - 0 and sets @error to one of the following values:
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_Timeout
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........: https://www.w3.org/TR/webdriver#navigate-to
; Example .......: No
; ===============================================================================================================================
Func _WD_Navigate($sSession, $sURL)
	Local Const $sFuncName = "_WD_Navigate"
	Local $sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/url", '{"url":"' & $sURL & '"}')

	Local $iErr = @error

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & $sResponse & @CRLF)
	EndIf

	If $iErr Then
		Return SetError(__WD_Error($sFuncName, $iErr, "HTTP status = " & $_WD_HTTPRESULT), $_WD_HTTPRESULT, 0)
	EndIf

	Return SetError($_WD_ERROR_Success, $_WD_HTTPRESULT, 1)
EndFunc   ;==>_WD_Navigate

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_Action
; Description ...: Perform various interactions with the web driver session.
; Syntax ........: _WD_Action($sSession, $sCommand[, $sOption = Default])
; Parameters ....: $sSession - Session ID from _WD_CreateSession
;                  $sCommand - One of the following actions:
;                  |
;                  |ACTIONS - Performs the action specified in $sOption. If $sOption = "" then all the keys and pointer buttons that are currently depressed will be released. This causes events to be fired as if the state was released by an explicit series of actions
;                  |BACK    - Causes the browser to traverse one step backward in the joint session history of the current top-level browsing context
;                  |FORWARD - Causes the browser to traverse one step forwards in the joint session history of the current top-level browsing context
;                  |REFRESH - Causes the browser to reload the page in current top-level browsing context
;                  |TITLE   - Returns the document title of the current top-level browsing context
;                  |URL     - Protocol binding to load the URL of the browser. If a baseUrl is specified in the config, it will be prepended to the url parameter. Calling this function with the same url as last time will trigger a page reload
;                  $sOption  - [optional] a JSON string of actions to perform. Default is ""
; Return values .: Success - Return value from web driver (could be an empty string).
;                  Failure - "" (empty string) and sets @error to one of the following values:
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_InvalidDataType
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........: https://www.w3.org/TR/webdriver#navigation
;                  https://www.w3.org/TR/webdriver#actions
; Example .......: No
; ===============================================================================================================================
Func _WD_Action($sSession, $sCommand, $sOption = Default)
	Local Const $sFuncName = "_WD_Action"
	Local $sResponse, $sResult = "", $iErr, $oJSON, $sURLCommand

	If $sOption = Default Then $sOption = ''

	$sCommand = StringLower($sCommand)
	$sURLCommand = $_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/" & $sCommand

	Switch $sCommand
		Case 'actions'
			If $sOption <> '' Then
				$sResponse = __WD_Post($sURLCommand, $sOption)
			Else
				$sResponse = __WD_Delete($sURLCommand)
			EndIf

			$iErr = @error

		Case 'back', 'forward', 'refresh'
			$sResponse = __WD_Post($sURLCommand, $_WD_EmptyDict)
			$iErr = @error

		Case 'title', 'url'
			$sResponse = __WD_Get($sURLCommand)
			$iErr = @error

			If $iErr = $_WD_ERROR_Success Then
				$oJSON = Json_Decode($sResponse)
				$sResult = Json_Get($oJSON, $_WD_JSON_Value)
			EndIf

		Case Else
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(Actions|Back|Forward|Refresh|Title|Url) $sCommand=>" & $sCommand), 0, "")

	EndSwitch

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & $sResponse & @CRLF)
	EndIf

	If $iErr Then
		Return SetError(__WD_Error($sFuncName, $iErr, "HTTP status = " & $_WD_HTTPRESULT), $_WD_HTTPRESULT, "")
	EndIf

	Return SetError($_WD_ERROR_Success, $_WD_HTTPRESULT, $sResult)
EndFunc   ;==>_WD_Action

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_Window
; Description ...: Perform interactions related to the current window.
; Syntax ........: _WD_Window($sSession, $sCommand[, $sOption = Default])
; Parameters ....: $sSession - Session ID from _WD_CreateSession
;                  $sCommand - One of the following actions:
;                  |
;                  |CLOSE      - Close current tab
;                  |FRAME      - Switch to frame
;                  |FULLSCREEN - Set window to fullscreen
;                  |HANDLES    - Get all window handles
;                  |MAXIMIZE   - Maximize window
;                  |MINIMIZE   - Minimize window
;                  |NEW        - Create a new window
;                  |PARENT     - Switch to parent frame
;                  |PRINT      - Generate PDF representation of the paginated document
;                  |RECT       - Get or set the window's size & position
;                  |SCREENSHOT - Take screenshot of window
;                  |SWITCH     - Switch to designated tab
;                  |WINDOW     - Get or set the current window
;                  $sOption  - [optional] a string value. Default is ""
; Return values .: Success - Return value from web driver (could be an empty string).
;                  Failure - "" (empty string) and sets @error to one of the following values:
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_InvalidDataType
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........: https://www.w3.org/TR/webdriver/#contexts
; Example .......: No
; ===============================================================================================================================
Func _WD_Window($sSession, $sCommand, $sOption = Default)
	Local Const $sFuncName = "_WD_Window"
	Local $sResponse, $oJSON, $sResult = "", $iErr

	If $sOption = Default Then $sOption = ''

	$sCommand = StringLower($sCommand)
	Local $sURLSession = $_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/"
	Switch $sCommand
		Case 'close'
			$sResponse = __WD_Delete($sURLSession & "window")
			$iErr = @error

		Case 'fullscreen', 'maximize', 'minimize'
			$sResponse = __WD_Post($sURLSession & "window/" & $sCommand, $_WD_EmptyDict)
			$iErr = @error

		Case 'handles'
			$sResponse = __WD_Get($sURLSession & "window/" & $sCommand)
			$iErr = @error

		Case 'new'
			$sResponse = __WD_Post($sURLSession & "window/" & $sCommand, $sOption)
			$iErr = @error

		Case 'frame', 'print'
			$sResponse = __WD_Post($sURLSession & $sCommand, $sOption)
			$iErr = @error

		Case 'parent'
			$sResponse = __WD_Post($sURLSession & "frame/parent", $sOption)
			$iErr = @error

		Case 'rect'
			If $sOption = '' Then
				$sResponse = __WD_Get($sURLSession & "window/" & $sCommand)
			Else
				$sResponse = __WD_Post($sURLSession & "window/" & $sCommand, $sOption)
			EndIf

			$iErr = @error

		Case 'screenshot'
			If $sOption = '' Then
				$sResponse = __WD_Get($sURLSession & $sCommand)
			Else
				$sResponse = __WD_Get($sURLSession & $sCommand & '/' & $sOption)
			EndIf

			$iErr = @error

		Case 'switch'
			$sResponse = __WD_Post($sURLSession & "window", $sOption)
			$iErr = @error

		Case 'window'
			If $sOption = '' Then
				$sResponse = __WD_Get($sURLSession & $sCommand)
			Else
				$sResponse = __WD_Post($sURLSession & $sCommand, $sOption)
			EndIf

			$iErr = @error

		Case Else
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(Close|Frame|Fullscreen|Handles|Maximize|Minimize|New|Parent|Print|Rect|Screenshot|Switch|Window) $sCommand=>" & $sCommand), 0, "")

	EndSwitch

	If $iErr = $_WD_ERROR_Success Then
		If $_WD_HTTPRESULT = $HTTP_STATUS_OK Then

			Switch $sCommand
				Case 'close', 'frame', 'fullscreen', 'maximize', 'minimize', 'parent', 'switch'
					$sResult = $sResponse

				Case 'new'
					$oJSON = Json_Decode($sResponse)
					$sResult = Json_Get($oJSON, "[value][handle]")

				Case Else
					$oJSON = Json_Decode($sResponse)
					$sResult = Json_Get($oJSON, $_WD_JSON_Value)
			EndSwitch
		Else
			$iErr = $_WD_ERROR_Exception
		EndIf
	EndIf

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & StringLeft($sResponse, $_WD_RESPONSE_TRIM) & "..." & @CRLF)
	EndIf

	If $iErr Then
		Return SetError(__WD_Error($sFuncName, $iErr, "HTTP status = " & $_WD_HTTPRESULT), $_WD_HTTPRESULT, "")
	EndIf

	Return SetError($_WD_ERROR_Success, $_WD_HTTPRESULT, $sResult)
EndFunc   ;==>_WD_Window

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_FindElement
; Description ...: Find element(s) by designated strategy.
; Syntax ........: _WD_FindElement($sSession, $sStrategy, $sSelector[, $sStartNodeID = Default[, $bMultiple = Default[,
;                  $bShadowRoot = Default]]])
; Parameters ....: $sSession     - Session ID from _WD_CreateSession
;                  $sStrategy    - Locator strategy. See defined constant $_WD_LOCATOR_* for allowed values
;                  $sSelector    - Value to find
;                  $sStartNodeID - [optional] Element ID to use as starting node. Default is ""
;                  $bMultiple    - [optional] Return multiple matching elements? Default is False
;                  $bShadowRoot  - [optional] Starting node is a shadow root? Default is False
; Return values .: Success - Element ID(s) returned by web driver.
;                  Failure - "" (empty string) and sets @error to one of the following values:
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_NoMatch
;                  - $_WD_ERROR_InvalidExpression
; Author ........: Danp2
; Modified ......: 01/10/2021
; Remarks .......: An array of matching elements is returned when $bMultiple is True
; Related .......:
; Link ..........: https://www.w3.org/TR/webdriver#element-retrieval
; Example .......: No
; ===============================================================================================================================
Func _WD_FindElement($sSession, $sStrategy, $sSelector, $sStartNodeID = Default, $bMultiple = Default, $bShadowRoot = Default)
	Local Const $sFuncName = "_WD_FindElement"
	Local $sCmd, $sBaseCmd = '', $sResponse, $sResult, $iErr
	Local $oJSON, $oValues, $sKey, $iRow, $aElements[0]

	If $sStartNodeID = Default Then $sStartNodeID = ""
	If $bMultiple = Default Then $bMultiple = False
	If $bShadowRoot = Default Then $bShadowRoot = False

	If $sStartNodeID Then
		$sBaseCmd = ($bShadowRoot) ? "/shadow/" : "/element/"
		$sBaseCmd &= $sStartNodeID

		; Make sure using a relative selector if using xpath strategy
		If $sStrategy = $_WD_LOCATOR_ByXPath And StringLeft($sSelector, 1) <> '.' Then
			$iErr = $_WD_ERROR_InvalidExpression
			$sResponse = "Selector must be relative when supplying a starting element"
		EndIf
	EndIf

	If $iErr = $_WD_ERROR_Success Then
		$sCmd = '/element' & (($bMultiple) ? 's' : '')
		$sSelector = __WD_EscapeString($sSelector)

		$sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & $sBaseCmd & $sCmd, '{"using":"' & $sStrategy & '","value":"' & $sSelector & '"}')
		$iErr = @error
	EndIf

	If $iErr = $_WD_ERROR_Success Then
		If $_WD_HTTPRESULT = $HTTP_STATUS_OK Then
			If $bMultiple Then

				$oJSON = Json_Decode($sResponse)
				$oValues = Json_Get($oJSON, $_WD_JSON_Value)

				If UBound($oValues) > 0 Then
					$sKey = "[" & $_WD_ELEMENT_ID & "]"

					Dim $aElements[UBound($oValues)]

					For $oValue In $oValues
						$aElements[$iRow] = Json_Get($oValue, $sKey)
						$iRow += 1
					Next
				Else
					$iErr = $_WD_ERROR_NoMatch
				EndIf
			Else
				$oJSON = Json_Decode($sResponse)

				$sResult = Json_Get($oJSON, $_WD_JSON_Element)
			EndIf

		Else
			$iErr = $_WD_ERROR_Exception
		EndIf
	EndIf

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & $sResponse & @CRLF)
	EndIf

	If $iErr Then
		Return SetError(__WD_Error($sFuncName, $iErr, "HTTP status = " & $_WD_HTTPRESULT), $_WD_HTTPRESULT, "")
	EndIf

	Return SetError($_WD_ERROR_Success, $_WD_HTTPRESULT, ($bMultiple) ? $aElements : $sResult)
EndFunc   ;==>_WD_FindElement

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_ElementAction
; Description ...: Perform action on desginated element.
; Syntax ........: _WD_ElementAction($sSession, $sElement, $sCommand[, $sOption = Default])
; Parameters ....: $sSession - Session ID from _WD_CreateSession
;                  $sElement - Element ID from _WD_FindElement
;                  $sCommand - One of the following actions:
;                  |
;                  |ACTIVE     - Get active element
;                  |ATTRIBUTE  - Get element's attribute
;                  |CLEAR      - Clear element's value
;                  |CLICK      - Click element
;                  |COMPLABEL  - Get element's computed label
;                  |COMPROLE   - Get element's computed role
;                  |CSS        - Get element's CSS value
;                  |DISPLAYED  - Get element's visibility
;                  |ENABLED    - Get element's enabled status
;                  |NAME       - Get element's tag name
;                  |PROPERTY   - Get element's property
;                  |RECT       - Get element's dimensions / coordinates
;                  |SCREENSHOT - Take element screenshot
;                  |SELECTED   - Get element's selected status
;                  |SHADOW     - Get element's shadow root
;                  |TEXT       - Get element's rendered text
;                  |VALUE      - Get or set element's value. If $sOption = "" the value of the element is returned, else set
;                  $sOption  - [optional] a string value. Default is ""
; Return values .: Success - Requested data returned by web driver.
;                  Failure - "" (empty string) and sets @error to one of the following values:
;                  - $_WD_ERROR_NoMatch
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_InvalidDataType
;                  - $_WD_ERROR_InvalidExpression
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........: https://www.w3.org/TR/webdriver/#state
;                  https://www.w3.org/TR/webdriver#element-interaction
;                  https://www.w3.org/TR/webdriver/#take-element-screenshot
;                  https://www.w3.org/TR/webdriver/#element-displayedness
; Example .......: No
; ===============================================================================================================================
Func _WD_ElementAction($sSession, $sElement, $sCommand, $sOption = Default)
	Local Const $sFuncName = "_WD_ElementAction"
	Local $sResponse, $sResult = '', $iErr, $oJSON

	If $sOption = Default Then $sOption = ''

	$sCommand = StringLower($sCommand)

	Local $sURLElement = $_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/element/"
	Switch $sCommand
		Case 'complabel', 'comprole', 'displayed', 'enabled', 'name', 'rect', 'selected', 'shadow', 'screenshot', 'text'
			$sResponse = __WD_Get($sURLElement & $sElement & "/" & $sCommand)
			$iErr = @error

		Case 'active'
			$sResponse = __WD_Get($sURLElement & $sCommand)
			$iErr = @error

		Case 'attribute', 'css', 'property'
			$sResponse = __WD_Get($sURLElement & $sElement & "/" & $sCommand & "/" & $sOption)
			$iErr = @error

		Case 'clear', 'click'
			$sResponse = __WD_Post($sURLElement & $sElement & "/" & $sCommand, '{"id":"' & $sElement & '"}')
			$iErr = @error

		Case 'value'
			If $sOption Then
				$sResponse = __WD_Post($sURLElement & $sElement & "/" & $sCommand, '{"id":"' & $sElement & '", "text":"' & __WD_EscapeString($sOption) & '"}')
			Else
				$sResponse = __WD_Get($sURLElement & $sElement & "/property/value")
			EndIf

			$iErr = @error

		Case Else
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(Active|Attribute|CompRole|CompLabel|Clear|Click|CSS|Displayed|Enabled|Name|Property|Rect|Selected|Shadow|Screenshot|Text|Value) $sCommand=>" & $sCommand), 0, "")

	EndSwitch

	If $iErr = $_WD_ERROR_Success Then
		Switch $_WD_HTTPRESULT
			Case $HTTP_STATUS_OK
				Switch $sCommand
					Case 'clear', 'click', 'shadow'
						$sResult = $sResponse

					Case 'value'
						If $sOption Then
							$sResult = $sResponse
						Else
							$oJSON = Json_Decode($sResponse)
							$sResult = Json_Get($oJSON, $_WD_JSON_Value)
						EndIf

					Case Else
						$oJSON = Json_Decode($sResponse)
						$sResult = Json_Get($oJSON, $_WD_JSON_Value)
				EndSwitch

			Case Else
				$iErr = $_WD_ERROR_Exception
		EndSwitch
	EndIf

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & StringLeft($sResponse, $_WD_RESPONSE_TRIM) & "..." & @CRLF)
	EndIf

	If $iErr Then
		Return SetError(__WD_Error($sFuncName, $iErr, $sResponse), $_WD_HTTPRESULT, "")
	EndIf

	Return SetError($_WD_ERROR_Success, $_WD_HTTPRESULT, $sResult)
EndFunc   ;==>_WD_ElementAction

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_ExecuteScript
; Description ...: Execute Javascipt commands.
; Syntax ........: _WD_ExecuteScript($sSession, $sScript[, $sArguments = Default[, $bAsync = Default[, $vSubNode = Default]]])
; Parameters ....: $sSession   - Session ID from _WD_CreateSession
;                  $sScript    - Javascript command(s) to run
;                  $sArguments - [optional] String of arguments in JSON format
;                  $bAsync     - [optional] Perform request asyncronously? Default is False
;                  $vSubNode  - [optional] Return the designated JSON node instead of the entire JSON string. Default is "" (entire response is returned)
; Return values .: Success - Response from web driver in JSON format or value requested by given $vSubNode
;                  Failure - Response from web driver in JSON format and sets @error to value returned from __WD_Post()
;                            If script is executed successfully but $vSubNode isn't found, then "" (empty string) and sets @error to $_WD_ERROR_RetValue
;                            If $vSubNode isn't valid, then "" (empty string) and sets @error to _WD_ERROR_InvalidArgue
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......:
; Related .......:
; Link ..........: https://www.w3.org/TR/webdriver#executing-script
; Example .......: No
; ===============================================================================================================================
Func _WD_ExecuteScript($sSession, $sScript, $sArguments = Default, $bAsync = Default, $vSubNode = Default)
	Local Const $sFuncName = "_WD_ExecuteScript"
	Local $sResponse, $sData, $sCmd

	If $sArguments = Default Then $sArguments = ""
	If $bAsync = Default Then $bAsync = False
	If $vSubNode = Default Then $vSubNode = ""
	If IsBool($vSubNode) Then $vSubNode = ($vSubNode) ? $_WD_JSON_Value : "" ; True = the JSON value node is returned , False = entire JSON response is returned

	If IsString($vSubNode) Then
		$sScript = __WD_EscapeString($sScript)

		$sData = '{"script":"' & $sScript & '", "args":[' & $sArguments & ']}'
		$sCmd = ($bAsync) ? 'async' : 'sync'

		$sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/execute/" & $sCmd, $sData)
		Local $iErr = @error

		If $_WD_DEBUG = $_WD_DEBUG_Info Then
			__WD_ConsoleWrite($sFuncName & ': ' & StringLeft($sResponse, $_WD_RESPONSE_TRIM) & "..." & @CRLF)
		EndIf

		If $iErr = $_WD_ERROR_Success Then
			If StringLen($vSubNode) Then
				Local $oJSON = Json_Decode($sResponse)
				$sResponse = Json_Get($oJSON, $vSubNode)
				If @error Then
					$iErr = $_WD_ERROR_RetValue
				EndIf
			EndIf
		EndIf
	Else
		$iErr = $_WD_ERROR_InvalidArgue
		$sResponse = ""
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr, "HTTP status = " & $_WD_HTTPRESULT), $_WD_HTTPRESULT, $sResponse)
EndFunc   ;==>_WD_ExecuteScript

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_Alert
; Description ...: Respond to user prompt.
; Syntax ........: _WD_Alert($sSession, $sCommand[, $sOption = Default])
; Parameters ....: $sSession - Session ID from _WD_CreateSession
;                  $sCommand - One of the following actions:
;                  |
;                  |ACCEPT   - Accept the current user prompt as if the user would have clicked the OK button
;                  |DISMISS  - Dismiss the current user prompt as if the user would have clicked the Cancel or OK button, whichever is present, in that order
;                  |GETTEXT  - Return the text message associated with the current user prompt or null
;                  |SENDTEXT - Set the text field of the current user prompt to the given value
;                  |STATUS   - Return logical value indicating the presence or absence of an alert
;                  $sOption  - [optional] a string value. Default is ""
; Return values .: Success - Requested data returned by web driver.
;                  Failure - "" (empty string) and sets @error to one of the following values:
;                  - $_WD_ERROR_NoAlert
;                  - $_WD_ERROR_InvalidDataType
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........: https://www.w3.org/TR/webdriver#user-prompts
; Example .......: No
; ===============================================================================================================================
Func _WD_Alert($sSession, $sCommand, $sOption = Default)
	Local Const $sFuncName = "_WD_Alert"
	Local $sResponse, $iErr, $oJSON, $sResult = ''

	If $sOption = Default Then $sOption = ''

	$sCommand = StringLower($sCommand)

	Local $sURLSession = $_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/"
	Switch $sCommand
		Case 'accept', 'dismiss'
			$sResponse = __WD_Post($sURLSession & "alert/" & $sCommand, $_WD_EmptyDict)
			$iErr = @error

		Case 'gettext'
			$sResponse = __WD_Get($sURLSession & "alert/text")
			$iErr = @error

			If $iErr = $_WD_ERROR_Success Then
				$oJSON = Json_Decode($sResponse)
				$sResult = Json_Get($oJSON, $_WD_JSON_Value)
			EndIf

		Case 'sendtext'
			$sResponse = __WD_Post($sURLSession & "alert/text", '{"text":"' & $sOption & '"}')
			$iErr = @error

		Case 'status'
			$sResponse = __WD_Get($sURLSession & "alert/text")
			$iErr = @error

			$sResult = ($iErr = $_WD_ERROR_NoAlert) ? False : True

		Case Else
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(Accept|Dismiss|GetText|SendText|Status) $sCommand=>" & $sCommand), 0, "")
	EndSwitch

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & $sResponse & @CRLF)
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr, $sResponse), $_WD_HTTPRESULT, $sResult)
EndFunc   ;==>_WD_Alert

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_GetSource
; Description ...: Get page source.
; Syntax ........: _WD_GetSource($sSession)
; Parameters ....: $sSession - Session ID from _WD_CreateSession
; Return values .: Success - HTML source code from page.
;                  Failure - "" (empty string) and sets @error to one of the following values:
;                  - $_WD_ERROR_Exception
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........: https://www.w3.org/TR/webdriver#get-page-source
; Example .......: No
; ===============================================================================================================================
Func _WD_GetSource($sSession)
	Local Const $sFuncName = "_WD_GetSource"
	Local $sResponse, $iErr, $sResult = "", $oJSON

	$sResponse = __WD_Get($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/source")
	$iErr = @error

	If $iErr = $_WD_ERROR_Success Then
		$oJSON = Json_Decode($sResponse)
		$sResult = Json_Get($oJSON, $_WD_JSON_Value)
	EndIf

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & $sResponse & @CRLF)
	EndIf

	If $iErr Then
		Return SetError(__WD_Error($sFuncName, $iErr, $sResponse), $_WD_HTTPRESULT, "")
	EndIf

	Return SetError($_WD_ERROR_Success, $_WD_HTTPRESULT, $sResult)
EndFunc   ;==>_WD_GetSource

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_Cookies
; Description ...: Gets, sets, or deletes the session's cookies.
; Syntax ........: _WD_Cookies($sSession, $sCommand[, $sOption = Default])
; Parameters ....: $sSession - Session ID from _WD_CreateSession
;                  $sCommand - One of the following actions:
;                  |
;                  |ADD       - Create a new cookie. $sOption has to be a JSON string
;                  |DELETE    - Delete a single cookie. The name of the cookie to delete is specified in $sOption
;                  |DELETEALL - Delete all cookies
;                  |GET       - Retrieve the value of a single cookie. The name of the cookie to retrieve has to be specified in $sOption
;                  |GETALL    - Retrieve the values of all cookies
;                  $sOption  - [optional] a string value. Default is ""
; Return values .: Success - Requested data returned by web driver.
;                  Failure - "" (empty string) and sets @error to one of the following values:
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_InvalidDataType
;                  - $_WD_ERROR_InvalidArgue
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......: Please have a look at wd_demo.au3 > DemoCookies function for how to add a new cookie
; Related .......: _WD_JsonCookie
; Link ..........: https://www.w3.org/TR/webdriver#cookies
; Example .......: No
; ===============================================================================================================================
Func _WD_Cookies($sSession, $sCommand, $sOption = Default)
	Local Const $sFuncName = "_WD_Cookies"
	Local $sResult, $sResponse, $iErr = $_WD_ERROR_Success
	If $sOption = Default Then $sOption = ''

	Local $sURLSession = $_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/"
	Switch $sCommand
		Case 'add'
			$sResponse = __WD_Post($sURLSession & "cookie", $sOption)
			$iErr = @error

		Case 'delete', 'deleteall'
			If $sCommand = 'delete' And IsString($sOption) = 0 Then $iErr = $_WD_ERROR_InvalidArgue
			If $sCommand = 'deleteall' And $sOption <> '' Then $iErr = $_WD_ERROR_InvalidArgue
			If $iErr = $_WD_ERROR_Success Then
				$sResponse = __WD_Delete($sURLSession & "cookie" & ($sOption <> '') ? "/" & $sOption : "")
				$iErr = @error
			EndIf

		Case 'get'
			$sResponse = __WD_Get($sURLSession & "cookie/" & $sOption)
			$iErr = @error

			If $iErr = $_WD_ERROR_Success Then
				$sResult = $sResponse
			EndIf

		Case 'getall'
			$sResponse = __WD_Get($sURLSession & "cookie")
			$iErr = @error

			If $iErr = $_WD_ERROR_Success Then
				$sResult = $sResponse
			EndIf

		Case Else
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(Add|Delete|DeleteAll|Get|GetAll) $sCommand=>" & $sCommand), 0, "")
	EndSwitch

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & $sResponse & @CRLF)
	EndIf

	If $iErr Then
		Return SetError(__WD_Error($sFuncName, $iErr, $sResponse), $_WD_HTTPRESULT, "")
	EndIf

	Return SetError($_WD_ERROR_Success, $_WD_HTTPRESULT, $sResult)
EndFunc   ;==>_WD_Cookies

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_Option
; Description ...: Sets and get options for the web driver UDF.
; Syntax ........: _WD_Option($sOption[, $vValue = Default])
; Parameters ....: $sOption - One of the following options:
;                  |
;                  |BASEURL        - IP address used for web driver communication
;                  |BINARYFORMAT   - Format used to store binary data
;                  |CONSOLE        - Destination for console output
;                  |DEBUGTRIM      - Length of response text written to the debug cocnsole
;                  |DEFAULTTIMEOUT - Default timeout (in miliseconds) used by other functions if no other value is supplied
;                  |DRIVER         - Full path name to web driver executable
;                  |DRIVERCLOSE    - Close prior driver instances before launching new one (Boolean)
;                  |DRIVERDETECT   - Use existing driver instance if it exists (Boolean)
;                  |DRIVERPARAMS   - Parameters to pass to web driver executable
;                  |HTTPTIMEOUTS   - Set WinHTTP timeouts on each Get, Post, Delete request (Boolean)
;                  |PORT           - Port used for web driver communication
;                  |SLEEP          - Function to be called when UDF pauses the script execution
;                  $vValue  - [optional] if no value is given, the current value is returned (default = "")
; Return values .: Success - 1 or current value.
;                  Failure - 0 or "" (empty string) and sets @error to $_WD_ERROR_InvalidDataType
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_Option($sOption, $vValue = Default)
	Local Const $sFuncName = "_WD_Option"

	If $vValue = Default Then $vValue = ''

	Switch $sOption
		Case "baseurl"
			If $vValue == "" Then Return $_WD_BASE_URL
			If Not IsString($vValue) Then
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(string) $vValue: " & $vValue), 0, 0)
			EndIf
			$_WD_BASE_URL = $vValue

		Case "binaryformat"
			If $vValue == "" Then Return $_WD_BFORMAT
			If Not IsInt($vValue) Then
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(int) $vValue: " & $vValue), 0, 0)
			EndIf
			$_WD_BFORMAT = $vValue

		Case "console"
			If $vValue == "" Then Return $_WD_CONSOLE
			If Not (IsString($vValue) Or IsInt($vValue) Or IsFunc($vValue) Or $vValue = Null) Then
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(func/int/null/string) $vValue: " & $vValue), 0, 0)
			EndIf
			$_WD_CONSOLE = $vValue

		Case "debugtrim"
			If $vValue == "" Then Return $_WD_RESPONSE_TRIM
			If Not IsInt($vValue) Then
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(int) $vValue: " & $vValue), 0, 0)
			EndIf
			$_WD_RESPONSE_TRIM = $vValue

		Case "DefaultTimeout"
			If $vValue == "" Then Return $_WD_DefaultTimeout
			If Not IsInt($vValue) Then
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(int) $vValue: " & $vValue), 0, 0)
			EndIf
			$_WD_DefaultTimeout = $vValue

		Case "driver"
			If $vValue == "" Then Return $_WD_DRIVER
			If Not IsString($vValue) Then
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(string) $vValue: " & $vValue), 0, 0)
			EndIf
			$_WD_DRIVER = $vValue

		Case "driverclose"
			If $vValue == "" Then Return $_WD_DRIVER_CLOSE
			If Not IsBool($vValue) Then
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(bool) $vValue: " & $vValue), 0, 0)
			EndIf
			$_WD_DRIVER_CLOSE = $vValue

		Case "driverdetect"
			If $vValue == "" Then Return $_WD_DRIVER_DETECT
			If Not IsBool($vValue) Then
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(bool) $vValue: " & $vValue), 0, 0)
			EndIf
			$_WD_DRIVER_DETECT = $vValue

		Case "driverparams"
			If $vValue == "" Then Return $_WD_DRIVER_PARAMS
			If Not IsString($vValue) Then
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(string) $vValue: " & $vValue), 0, 0)
			EndIf
			$_WD_DRIVER_PARAMS = $vValue

		Case "httptimeouts"
			If $vValue == "" Then Return $_WD_WINHTTP_TIMEOUTS
			If Not IsBool($vValue) Then
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(bool) $vValue: " & $vValue), 0, 0)
			EndIf
			$_WD_WINHTTP_TIMEOUTS = $vValue

		Case "port"
			If $vValue == "" Then Return $_WD_PORT
			If Not IsInt($vValue) Then
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(int) $vValue: " & $vValue), 0, 0)
			EndIf
			$_WD_PORT = $vValue

		Case "Sleep"
			If $vValue == "" Then Return $_WD_Sleep
			If Not IsFunc($vValue) Then
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(func) $vValue: " & $vValue), 0, 0)
			EndIf
			$_WD_Sleep = $vValue

		Case Else
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(BaseURL|BinaryFormat|Console|DebugTrim|DefaultTimeout|Driver|DriverClose|DriverDetect|DriverParams|HTTPTimeouts|Port|Sleep) $sOption=>" & $sOption), 0, 0)
	EndSwitch

	Return 1
EndFunc   ;==>_WD_Option

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_Startup
; Description ...: Launch the designated web driver console app.
; Syntax ........: _WD_Startup()
; Parameters ....: None
; Return values .: Success - PID for the WD console.
;                  Failure - 0 and sets @error to one of the following values:
;                  - $_WD_ERROR_GeneralError
;                  - $_WD_ERROR_InvalidValue
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......: _WD_Shutdown
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_Startup()
	Local Const $sFuncName = "_WD_Startup"
	Local $sFunction, $bLatest, $sUpdate, $sFile, $iPID

	If $_WD_DRIVER = "" Then
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidValue, "Location for Web Driver not set." & @CRLF), 0, 0)
	EndIf

	If $_WD_DRIVER_CLOSE Then __WD_CloseDriver()

	Local $sCommand = StringFormat('"%s" %s ', $_WD_DRIVER, $_WD_DRIVER_PARAMS)

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		$sFunction = "_WD_IsLatestRelease"
		$bLatest = Call($sFunction)

		Select
			Case @error = 0xDEAD And @extended = 0xBEEF
				$sUpdate = "" ; update check not performed

			Case @error
				$sUpdate = " (Update status unknown [" & @error & "])"

			Case $bLatest
				$sUpdate = " (Up to date)"

			Case Not $bLatest
				$sUpdate = " (Update available)"

		EndSelect

		Local $sWinHttpVer = __WinHttpVer()
		If $sWinHttpVer < "1.6.4.2" Then
			$sWinHttpVer &= " (Download latest source at <https://raw.githubusercontent.com/dragana-r/autoit-winhttp/master/WinHttp.au3>)"
		EndIf

		__WD_ConsoleWrite($sFuncName & ": OS:" & @TAB & @OSVersion & " " & @OSType & " " & @OSBuild & " " & @OSServicePack & @CRLF)
		__WD_ConsoleWrite($sFuncName & ": AutoIt:" & @TAB & @AutoItVersion & @CRLF)
		__WD_ConsoleWrite($sFuncName & ": au3WD UDF:" & @TAB & $__WDVERSION & $sUpdate & @CRLF)
		__WD_ConsoleWrite($sFuncName & ": WinHTTP:" & @TAB & $sWinHttpVer & @CRLF)
		__WD_ConsoleWrite($sFuncName & ": Driver:" & @TAB & $_WD_DRIVER & @CRLF)
		__WD_ConsoleWrite($sFuncName & ": Params:" & @TAB & $_WD_DRIVER_PARAMS & @CRLF)
		__WD_ConsoleWrite($sFuncName & ": Port:" & @TAB & $_WD_PORT & @CRLF)
	Else
		__WD_ConsoleWrite($sFuncName & ': ' & $sCommand & @CRLF)
	EndIf

	$sFile = __WD_StripPath($_WD_DRIVER)
	$iPID = ProcessExists($sFile)

	If $_WD_DRIVER_DETECT And $iPID Then
		__WD_ConsoleWrite($sFuncName & ": Existing instance of " & $sFile & " detected!" & @CRLF)
	Else
		$iPID = Run($sCommand, "", ($_WD_DEBUG = $_WD_DEBUG_Info) ? @SW_SHOW : @SW_HIDE)

		If @error Or ProcessWaitClose($iPID, 1) Then
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_GeneralError, "Error launching web driver!"), 0, 0)
		EndIf
	EndIf

	Return SetError($_WD_ERROR_Success, 0, $iPID)
EndFunc   ;==>_WD_Startup

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_Shutdown
; Description ...: Kill the web driver console app.
; Syntax ........: _WD_Shutdown([$vDriver = Default])
; Parameters ....: $vDriver - [optional] The name or PID of Web driver console to shutdown
; Return values .: None
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......: _WD_Startup
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_Shutdown($vDriver = Default)
	__WD_CloseDriver($vDriver)
EndFunc   ;==>_WD_Shutdown

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_Get
; Description ...: Submit GET request to WD console app.
; Syntax ........: __WD_Get($sURL)
; Parameters ....: $sURL - Location to access via WinHTTP
; Return values..: Success - Response from web driver.
;                  Failure - Response from web driver and sets @error to one of the following values:
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_InvalidValue
;                  - $_WD_ERROR_InvalidDataType
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WD_Get($sURL)
	Local Const $sFuncName = "__WD_Get"
	Local $iResult = $_WD_ERROR_Success, $sResponseText, $iErr

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': URL=' & $sURL & @CRLF)
	EndIf

	$_WD_HTTPRESULT = 0

	Local $aURL = _WinHttpCrackUrl($sURL)

	If IsArray($aURL) Then
		; Initialize and get session handle
		Local $hOpen = _WinHttpOpen()

		If $_WD_WINHTTP_TIMEOUTS Then
			_WinHttpSetTimeouts($hOpen, $_WD_HTTPTimeOuts[0], $_WD_HTTPTimeOuts[1], $_WD_HTTPTimeOuts[2], $_WD_HTTPTimeOuts[3])
		EndIf

		; Get connection handle
		Local $hConnect = _WinHttpConnect($hOpen, $aURL[2], $aURL[3])

		If @error Then
			$iResult = $_WD_ERROR_SocketError
		Else
			Switch $aURL[1]
				Case $INTERNET_SCHEME_HTTP
					$sResponseText = _WinHttpSimpleRequest($hConnect, "GET", $aURL[6] & $aURL[7], Default, Default, $_WD_HTTPContentType)
				Case $INTERNET_SCHEME_HTTPS
					$sResponseText = _WinHttpSimpleSSLRequest($hConnect, "GET", $aURL[6] & $aURL[7], Default, Default, $_WD_HTTPContentType)
				Case Else
					SetError($_WD_ERROR_InvalidValue)
			EndSwitch

			$iErr = @error
			$_WD_HTTPRESULT = @extended

			If $iErr Then
				$iResult = $_WD_ERROR_SendRecv
				$sResponseText = $WD_WinHTTPTimeoutMsg
			Else
				__WD_DetectError($iErr, $sResponseText)
				$iResult = $iErr
			EndIf
		EndIf

		_WinHttpCloseHandle($hConnect)
		_WinHttpCloseHandle($hOpen)
	Else
		$iResult = $_WD_ERROR_InvalidValue
	EndIf

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': StatusCode=' & $_WD_HTTPRESULT & "; $iResult = " & $iResult & "; $sResponseText=" & StringLeft($sResponseText, $_WD_RESPONSE_TRIM) & "..." & @CRLF)
	EndIf

	If $iResult Then
		Return SetError(__WD_Error($sFuncName, $iResult, $sResponseText), $_WD_HTTPRESULT, $sResponseText)
	EndIf

	Return SetError($_WD_ERROR_Success, 0, $sResponseText)
EndFunc   ;==>__WD_Get

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_Post
; Description ...: Submit POST request to WD console app.
; Syntax ........: __WD_Post($sURL, $sData)
; Parameters ....: $sURL  - Location to access via WinHTTP
;                  $sData - String representing data to be sent
; Return values..: Success - Response from web driver in JSON format
;                  Failure - Response from web driver in JSON format and sets @error to one of the following values:
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_Timeout
;                  - $_WD_ERROR_SocketError
;                  - $_WD_ERROR_InvalidValue
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WD_Post($sURL, $sData)
	Local Const $sFuncName = "__WD_Post"
	Local $iResult, $sResponseText, $iErr

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': URL=' & $sURL & "; $sData=" & $sData & @CRLF)
	EndIf

	$_WD_HTTPRESULT = 0

	Local $aURL = _WinHttpCrackUrl($sURL)

	If @error Then
		$iResult = $_WD_ERROR_InvalidValue
	Else
		; Initialize and get session handle
		Local $hOpen = _WinHttpOpen()

		If $_WD_WINHTTP_TIMEOUTS Then
			_WinHttpSetTimeouts($hOpen, $_WD_HTTPTimeOuts[0], $_WD_HTTPTimeOuts[1], $_WD_HTTPTimeOuts[2], $_WD_HTTPTimeOuts[3])
		EndIf

		; Get connection handle
		Local $hConnect = _WinHttpConnect($hOpen, $aURL[2], $aURL[3])

		If @error Then
			$iResult = $_WD_ERROR_SocketError
		Else
			Switch $aURL[1]
				Case $INTERNET_SCHEME_HTTP
					$sResponseText = _WinHttpSimpleRequest($hConnect, "POST", $aURL[6] & $aURL[7], Default, StringToBinary($sData, $_WD_BFORMAT), $_WD_HTTPContentType)
				Case $INTERNET_SCHEME_HTTPS
					$sResponseText = _WinHttpSimpleSSLRequest($hConnect, "POST", $aURL[6] & $aURL[7], Default, StringToBinary($sData, $_WD_BFORMAT), $_WD_HTTPContentType)
				Case Else
					SetError($_WD_ERROR_InvalidValue)
			EndSwitch

			$iErr = @error
			$_WD_HTTPRESULT = @extended

			If $iErr Then
				$iResult = $_WD_ERROR_SendRecv
				$sResponseText = $WD_WinHTTPTimeoutMsg
			Else
				__WD_DetectError($iErr, $sResponseText)
				$iResult = $iErr
			EndIf
		EndIf

		_WinHttpCloseHandle($hConnect)
		_WinHttpCloseHandle($hOpen)
	EndIf

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': StatusCode=' & $_WD_HTTPRESULT & "; ResponseText=" & StringLeft($sResponseText, $_WD_RESPONSE_TRIM) & "..." & @CRLF)
	EndIf

	If $iResult Then
		Return SetError(__WD_Error($sFuncName, $iResult, $sResponseText), $_WD_HTTPRESULT, $sResponseText)
	EndIf

	Return SetError($_WD_ERROR_Success, $_WD_HTTPRESULT, $sResponseText)
EndFunc   ;==>__WD_Post

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_Delete
; Description ...: Submit DELETE request to WD console app.
; Syntax ........: __WD_Delete($sURL)
; Parameters ....: $sURL - Location to access via WinHTTP
; Return values..: Success - Response from web driver.
;                  Failure - Response from web driver and sets @error to one of the following values:
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_InvalidValue
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WD_Delete($sURL)
	Local Const $sFuncName = "__WD_Delete"

	Local $iResult, $sResponseText, $iErr

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': URL=' & $sURL & @CRLF)
	EndIf

	$_WD_HTTPRESULT = 0

	Local $aURL = _WinHttpCrackUrl($sURL)

	If @error Then
		$iResult = $_WD_ERROR_InvalidValue
	Else
		; Initialize and get session handle
		Local $hOpen = _WinHttpOpen()

		If $_WD_WINHTTP_TIMEOUTS Then
			_WinHttpSetTimeouts($hOpen, $_WD_HTTPTimeOuts[0], $_WD_HTTPTimeOuts[1], $_WD_HTTPTimeOuts[2], $_WD_HTTPTimeOuts[3])
		EndIf

		; Get connection handle
		Local $hConnect = _WinHttpConnect($hOpen, $aURL[2], $aURL[3])

		If @error Then
			$iResult = $_WD_ERROR_SocketError
		Else
			Switch $aURL[1]
				Case $INTERNET_SCHEME_HTTP
					$sResponseText = _WinHttpSimpleRequest($hConnect, "DELETE", $aURL[6] & $aURL[7], Default, Default, $_WD_HTTPContentType)
				Case $INTERNET_SCHEME_HTTPS
					$sResponseText = _WinHttpSimpleSSLRequest($hConnect, "DELETE", $aURL[6] & $aURL[7], Default, Default, $_WD_HTTPContentType)
				Case Else
					SetError($_WD_ERROR_InvalidValue)
			EndSwitch

			$iErr = @error
			$_WD_HTTPRESULT = @extended

			If $iErr Then
				$iResult = $_WD_ERROR_SendRecv
				$sResponseText = $WD_WinHTTPTimeoutMsg
			Else
				__WD_DetectError($iErr, $sResponseText)
				$iResult = $iErr
			EndIf
		EndIf

		_WinHttpCloseHandle($hConnect)
		_WinHttpCloseHandle($hOpen)
	EndIf

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': StatusCode=' & $_WD_HTTPRESULT & "; ResponseText=" & StringLeft($sResponseText, $_WD_RESPONSE_TRIM) & "..." & @CRLF)
	EndIf

	If $iResult Then
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception, $sResponseText), $_WD_HTTPRESULT, $sResponseText)
	EndIf

	Return SetError($_WD_ERROR_Success, 0, $sResponseText)
EndFunc   ;==>__WD_Delete

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_Error
; Description ...: Writes Error to the console and show message-boxes if the script is compiled.
; Syntax ........: __WD_Error($sWhere, $i_WD_ERROR[, $sMessage = Default])
; Parameters ....: $sWhere     - Name of calling routine
;                  $i_WD_ERROR - Error constant
;                  $sMessage   - [optional] Additional Information (default = "")
; Return values..: Success - Error Const from $i_WD_ERROR
;                  Failure - None
; Author ........: Thorsten Willert, Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WD_Error($sWhere, $i_WD_ERROR, $sMessage = Default)
	Local $sMsg

	If $sMessage = Default Then $sMessage = ''

	Switch $_WD_DEBUG
		Case $_WD_DEBUG_None

		Case $_WD_DEBUG_Error
			If $i_WD_ERROR <> $_WD_ERROR_Success Then ContinueCase

		Case $_WD_DEBUG_Info
			$sMsg = $sWhere & " ==> " & $aWD_ERROR_DESC[$i_WD_ERROR]

			If $sMessage <> "" Then
				$sMsg = $sMsg & ": " & $sMessage
			EndIf

			__WD_ConsoleWrite($sMsg & @CRLF)

			If @Compiled Then
				If $_WD_ERROR_MSGBOX And $i_WD_ERROR <> $_WD_ERROR_Success And $i_WD_ERROR < 6 Then MsgBox(16, "WD_Core.au3 Error:", $sMsg)
				DllCall("kernel32.dll", "none", "OutputDebugString", "str", $sMsg)
			EndIf
	EndSwitch

	Return $i_WD_ERROR
EndFunc   ;==>__WD_Error

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_CloseDriver
; Description ...: Shutdown web driver console if it exists.
; Syntax ........: __WD_CloseDriver([$sDriver = Default])
; Parameters ....: $vDriver - [optional] The name or PID of Web driver console to shutdown. Default is $_WD_DRIVER
; Return values .: None
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WD_CloseDriver($vDriver = Default)
	Local $sFile, $aData, $aProcessList[2][2]

	If $vDriver = Default Then $vDriver = $_WD_DRIVER

	; Did calling routine pass a single PID?
	If IsInt($vDriver) Then
		; Yes, so build array to close this single instance
		$aProcessList[0][0] = 1
		$aProcessList[1][1] = $vDriver
	Else
		; No, close all matching driver instances
		$sFile = __WD_StripPath($vDriver)
		$aProcessList = ProcessList($sFile)
	EndIf

	For $i = 1 To $aProcessList[0][0]
		$aData = _WinAPI_EnumChildProcess($aProcessList[$i][1])

		If IsArray($aData) Then
			For $j = 0 To UBound($aData) - 1
				If $aData[$j][1] == 'conhost.exe' Then
					ProcessClose($aData[$j][0])
					ProcessWaitClose($aData[$j][0], 5)
				EndIf
			Next
		EndIf

		ProcessClose($aProcessList[$i][1])
		ProcessWaitClose($aProcessList[$i][1], 5)
	Next

EndFunc   ;==>__WD_CloseDriver

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_EscapeString
; Description ...: Escapes designated characters in string.
; Syntax ........: __WD_EscapeString($sData)
; Parameters ....: $sData - the string to be escaped
; Return values..: Escaped string.
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WD_EscapeString($sData)
	Local $sRegEx = "([" & $_WD_ESCAPE_CHARS & "])"
	Local $sEscaped = StringRegExpReplace($sData, $sRegEx, "\\$1")
	Return SetError($_WD_ERROR_Success, 0, $sEscaped)
EndFunc   ;==>__WD_EscapeString

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_TranslateQuotes
; Description ...: Translate double quotes into single quotes
; Syntax ........: __WD_TranslateQuotes($sData)
; Parameters ....: $sData - The string to be translated
; Return values .: Translated string
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WD_TranslateQuotes($sData)
	Local $sResult = StringReplace($sData, '"', "'")
	Return SetError($_WD_ERROR_Success, 0, $sResult)
EndFunc   ;==>__WD_TranslateQuotes

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_DetectError
; Description ...: Evaluate results from webdriver to identify errors.
; Syntax ........: __WD_DetectError(Byref $iErr, $vResult)
; Parameters ....: $iErr    - [in/out] Error code
;                  $vResult - Result from webdriver
; Return values .: None
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WD_DetectError(ByRef $iErr, $vResult)
	; Don't perform any action if error condition is
	; already set or the webdriver result equals null
	If $iErr Or $vResult == Null Then Return

	; Extract "value" element from JSON string
	If Not IsObj($vResult) Then
		; Detect unknown end point
		If $_WD_HTTPRESULT = $HTTP_STATUS_BAD_METHOD Then
			$iErr = $_WD_ERROR_UnknownCommand
			Return
		EndIf

		Local $oJSON = Json_Decode($vResult)
		$vResult = Json_Get($oJSON, $_WD_JSON_Value)

		If @error Or $vResult == Null Then Return
	EndIf

	If (Not IsObj($vResult)) Or ObjName($vResult, $OBJ_STRING) <> 'Scripting.Dictionary' Then Return

	If $vResult.Exists('error') Then

		Switch $vResult.item('error')
			Case ""

			Case $WD_ErrorInvalidSession
				$iErr = $_WD_ERROR_SessionInvalid

			Case $WD_ErrorUnknownCommand
				$iErr = $_WD_ERROR_UnknownCommand

			Case $WD_ErrorTimeout
				$iErr = $_WD_ERROR_Timeout

			Case $WD_Element_NotFound, $WD_Element_Stale
				$iErr = $_WD_ERROR_NoMatch

			Case $WD_Element_Invalid
				$iErr = $_WD_ERROR_InvalidArgue

			Case $WD_Element_Intercept, $WD_Element_NotInteract
				$iErr = $_WD_ERROR_ElementIssue

			Case $WD_NoSuchAlert
				$iErr = $_WD_ERROR_NoAlert

			Case Else
				$iErr = $_WD_ERROR_Exception

		EndSwitch
	EndIf
EndFunc   ;==>__WD_DetectError

Func __WD_StripPath($sFilePath)
	Return StringRegExpReplace($sFilePath, "^.*\\(.*)$", "$1")
EndFunc   ;==>__WD_StripPath

Func __WD_ConsoleWrite($sMsg)
	If IsFunc($_WD_CONSOLE) Then
		Call($_WD_CONSOLE, $sMsg)
	ElseIf $_WD_CONSOLE = Null Then
		; do nothing
	Else
		FileWrite($_WD_CONSOLE, $sMsg)
	EndIf
EndFunc   ;==>__WD_ConsoleWrite

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_Sleep
; Description ...: Pause script execution for designated timeframe.
; Syntax ........: __WD_Sleep($iPause)
; Parameters ....: $iPause - Amount of time to pause (in milliseconds)
; Return values .: Success - None
;                  Failure - None and sets @error $_WD_ERROR_UserAbort
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......: Calls standard Sleep() by default. This can be overridden with _WD_Option so that a user supplied function
;                  gets called instead. User's function can throw error which will lead to $_WD_ERROR_UserAbort
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WD_Sleep($iPause)
	$_WD_Sleep($iPause)
	If @error Then Return SetError($_WD_ERROR_UserAbort)
EndFunc   ;==>__WD_Sleep
