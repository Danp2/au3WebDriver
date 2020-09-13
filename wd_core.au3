#include-once
#include <WinAPIProc.au3>
#include <JSON.au3> ; https://www.autoitscript.com/forum/topic/148114-a-non-strict-json-udf-jsmn
#include <WinHttp.au3> ; https://www.autoitscript.com/forum/topic/84133-winhttp-functions/

#Region Copyright
#cs
	* WD_Core.au3
	*
	* MIT License
	*
	* Copyright (c) 2020 Dan Pollak
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

#Region Copyright
#cs
	* WD_Core.au3
	*
	* MIT License
	*
	* Copyright (c) 2020 Dan Pollak
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

#Region Many thanks to:
#cs
	- Jonathan Bennett and the AutoIt Team
	- Thorsten Willert, author of FF.au3, which I've used as a model
	- Michał Lipok for all his feedback / suggestions
#ce
#EndRegion Many thanks to:


#Region Global Constants
Global Const $__WDVERSION = "0.3.0.9"

Global Const $_WD_ELEMENT_ID = "element-6066-11e4-a52e-4f735466cecf"
Global Const $_WD_EmptyDict  = "{}"

Global Const $_WD_LOCATOR_ByCSSSelector = "css selector"
Global Const $_WD_LOCATOR_ByXPath = "xpath"
Global Const $_WD_LOCATOR_ByLinkText = "link text"
Global Const $_WD_LOCATOR_ByPartialLinkText = "partial link text"
Global Const $_WD_LOCATOR_ByTagName = "tag name"

Global Const $_WD_DefaultTimeout = 10000 ; 10 seconds

Global Enum _
		$_WD_DEBUG_None = 0, _ ; No logging to console
		$_WD_DEBUG_Error,    _ ; Error logging to console
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
		$_WD_ERROR_COUNTER ;

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
		"Unknown Command" _
		]

Global Const $WD_ErrorInvalidSession = "invalid session id"
Global Const $WD_ErrorUnknownCommand = "unknown command"
Global Const $WD_ErrorTimeout = "timeout"

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
Global $_WD_CONSOLE = Default ; Destination for console output
Global $_WD_IFILTER = 16 ; Passed to _HtmlTableGetWriteToArray to control filtering

Global $_WD_WINHTTP_TIMEOUTS = True
Global $_WD_HTTPTimeOuts[4] = [0, 60000, 30000, 30000]
Global $_WD_HTTPContentType = "Content-Type: application/json"
#EndRegion Global Variables

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_CreateSession
; Description ...: Request new session from web driver
; Syntax ........: _WD_CreateSession([$sDesiredCapabilities = Default])
; Parameters ....: $sDesiredCapabilities- [optional] a string value. Default is '{}'.
; Return values .: Success      - Session ID to be used in future requests to web driver session
;                  Failure      - Empty string
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_Exception
;                  @EXTENDED    - WinHTTP status code
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........: https://www.w3.org/TR/webdriver#new-session
; Example .......: No
; ===============================================================================================================================
Func _WD_CreateSession($sDesiredCapabilities = Default)
	Local Const $sFuncName = "_WD_CreateSession"
	Local $sSession = ""

	If $sDesiredCapabilities = Default Then $sDesiredCapabilities = $_WD_EmptyDict

	Local $sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session", $sDesiredCapabilities)
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
; Description ...:  Delete existing session
; Syntax ........: _WD_DeleteSession($sSession)
; Parameters ....: $sSession            - Session ID from _WDCreateSession
; Return values .: Success      - 1
;                  Failure      - 0
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_Exception
;                  @EXTENDED    - WinHTTP status code
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
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
; Description ...: Get current web driver state
; Syntax ........: _WD_Status()
; Parameters ....:
; Return values .: Success      - Dictionary object with "message" and "ready" items
;                  Failure      - ''
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_Exception
;                  @EXTENDED    - WinHTTP status code
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........: https://www.w3.org/TR/webdriver#status
; Example .......: No
; ===============================================================================================================================
Func _WD_Status()
	Local Const $sFuncName = "_WD_Status"
	Local $sResponse = __WD_Get($_WD_BASE_URL & ":" & $_WD_PORT & "/status")
	Local $iErr = @error, $sResult = ''

	If $iErr = $_WD_ERROR_Success Then
		Local $oJSON = Json_Decode($sResponse)
		$sResult = Json_Get($oJSON, "[value]")
	EndIf

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & $sResponse & @CRLF)
	EndIf

	If $iErr Then
		Return SetError(__WD_Error($sFuncName, $iErr, "HTTP status = " & $_WD_HTTPRESULT), $_WD_HTTPRESULT, 0)
	EndIf

	Return SetError($_WD_ERROR_Success, $_WD_HTTPRESULT, $sResult)
EndFunc   ;==>_WD_Status


; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_Timeouts
; Description ...:  Set or retrieve the session timeout parameters
; Syntax ........: _WD_Timeouts($sSession[, $sTimeouts = Default])
; Parameters ....: $sSession            - Session ID from _WDCreateSession
;                  $sTimeouts           - [optional] a string value. Default is ''.
; Return values .: Success      - Raw return value from web driver in JSON format
;                  Failure      - 0
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_Exception
;                  @EXTENDED    - WinHTTP status code
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
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
; Description ...: Navigate to the designated URL
; Syntax ........: _WD_Navigate($sSession, $sURL)
; Parameters ....: $sSession            - Session ID from _WDCreateSession
;                  $sURL                - Destination URL
; Return values .: Success      - 1
;                  Failure      - 0
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_Exception
;                  				- $_WD_ERROR_Timeout
;                  @EXTENDED    - WinHTTP status code
; Author ........: Dan Pollak
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
; Description ...: Perform various interactions with the web driver session
; Syntax ........: _WD_Action($sSession, $sCommand[, $sOption = Default])
; Parameters ....: $sSession            - Session ID from _WDCreateSession
;                  $sCommand            - one of the following actions:
;                               | refresh
;                               | back
;                               | forward
;                               | url
;                               | title
;                               | actions
;                  $sOption             - [optional] a string value. Default is ''.
; Return values .: Success      - Return value from web driver (could be an empty string)
;                  Failure      - ""
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_Exception
;                  				- $_WD_ERROR_InvalidDataType
;                  @EXTENDED    - WinHTTP status code
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........: https://www.w3.org/TR/webdriver#navigation
;                  https://www.w3.org/TR/webdriver#actions
; Example .......: No
; ===============================================================================================================================
Func _WD_Action($sSession, $sCommand, $sOption = Default)
	Local Const $sFuncName = "_WD_Action"
	Local $sResponse, $sResult = "", $iErr, $oJSON, $sURL

	If $sOption = Default Then $sOption = ''

	$sCommand = StringLower($sCommand)
	$sURL = $_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/" & $sCommand

	Switch $sCommand
		Case 'back', 'forward', 'refresh'
			$sResponse = __WD_Post($sURL, $_WD_EmptyDict)
			$iErr = @error

		Case 'url', 'title'
			$sResponse = __WD_Get($sURL)
			$iErr = @error

			If $iErr = $_WD_ERROR_Success Then
				$oJSON = Json_Decode($sResponse)
				$sResult = Json_Get($oJSON, "[value]")
			EndIf

		Case 'actions'
			If $sOption <> '' Then
				$sResponse = __WD_Post($sURL, $sOption)
			Else
				$sResponse = __WD_Delete($sURL)
			EndIf

			$iErr = @error

		Case Else
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(Back|Forward|Refresh|Url|Title|Actions) $sCommand=>" & $sCommand), 0, "")

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
; Description ...: Perform interactions related to the current window
; Syntax ........: _WD_Window($sSession, $sCommand[, $sOption = Default])
; Parameters ....: $sSession            - Session ID from _WDCreateSession
;
;                  $sCommand  - one of the following actions:
;                               | Window - Get or set the current window
;                               | Handles - Get all window handles
;                               | Maximize - Maximize window
;                               | Minimize - Minimize window
;                               | Fullscreen - Set window to fullscreen
;                               | New - Create a new window
;                               | Rect - Get or set the window's size & position
;                               | Screenshot - Take screenshot of window
;                               | Close - Close current tab
;                               | Switch - Switch to designated tab
;                               | Frame - Switch to frame
;                               | Parent - Switch to parent frame
;                               | Print - Generate PDF representation of the paginated document

;
;                  $sOption   - [optional] a string value. Default is ''.
;
; Return values .: Success      - Return value from web driver (could be an empty string)
;                  Failure      - ""
;
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_Exception
;                  				- $_WD_ERROR_InvalidDataType
;                  @EXTENDED    - WinHTTP status code
;
; Author ........: Dan Pollak
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

	Switch $sCommand
		Case 'window'
			If $sOption = '' Then
				$sResponse = __WD_Get($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/" & $sCommand)
			Else
				$sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/" & $sCommand, $sOption)
			EndIf

			$iErr = @error

		Case 'handles'
			$sResponse = __WD_Get($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/window/" & $sCommand)
			$iErr = @error

		Case 'maximize', 'minimize', 'fullscreen'
			$sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/window/" & $sCommand, $_WD_EmptyDict)
			$iErr = @error

		Case 'new'
			$sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/window/" & $sCommand, $sOption)
			$iErr = @error

		Case 'rect'
			If $sOption = '' Then
				$sResponse = __WD_Get($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/window/" & $sCommand)
			Else
				$sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/window/" & $sCommand, $sOption)
			EndIf

			$iErr = @error

		Case 'screenshot'
			$sResponse = __WD_Get($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/" & $sCommand)
			$iErr = @error

		Case 'close'
			$sResponse = __WD_Delete($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/window")
			$iErr = @error

		Case 'switch'
			$sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/window", $sOption)
			$iErr = @error

		Case 'frame', 'print'
			$sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/" & $sCommand, $sOption)
			$iErr = @error

		Case 'parent'
			$sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/frame/parent", $sOption)
			$iErr = @error

		Case Else
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(Window|Handles|Maximize|Minimize|Fullscreen|New|Rect|Screenshot|Close|Switch|Frame|Parent|Print) $sCommand=>" & $sCommand), 0, "")

	EndSwitch

	If $iErr = $_WD_ERROR_Success Then
		If $_WD_HTTPRESULT = $HTTP_STATUS_OK Then

			Switch $sCommand
				Case 'maximize', 'minimize', 'fullscreen', 'close', 'switch', 'frame', 'parent', 'print'
					$sResult = $sResponse

				Case 'new'
					$oJson = Json_Decode($sResponse)
					$sResult = Json_Get($oJson, "[value][handle]")

				Case Else
					$oJson = Json_Decode($sResponse)
					$sResult = Json_Get($oJson, "[value]")
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
; Description ...: Find element(s) by designated strategy
; Syntax ........: _WD_FindElement($sSession, $sStrategy, $sSelector[, $sStartElement = Default[, $lMultiple = Default]])
; Parameters ....: $sSession            - Session ID from _WDCreateSession
;                  $sStrategy           - Locator strategy. See defined constant $_WD_LOCATOR_* for allowed values
;                  $sSelector           - Value to find
;                  $sStartElement       - [optional] Element ID to use as starting node. Devault is ""
;                  $lMultiple           - [optional] Return multiple matching elements? Default is False
; Return values .: Success      - Element ID(s) returned by web driver
;                  Failure      - ""
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_Exception
;                  				- $_WD_ERROR_NoMatch
;                  				- $_WD_ERROR_InvalidExpression
;                  @EXTENDED    - WinHTTP status code
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........: https://www.w3.org/TR/webdriver#element-retrieval
; Example .......: No
; ===============================================================================================================================
Func _WD_FindElement($sSession, $sStrategy, $sSelector, $sStartElement = Default, $lMultiple = Default)
	Local Const $sFuncName = "_WD_FindElement"
	Local $sCmd, $sElement, $sResponse, $sResult, $iErr
	Local $oJson, $oValues, $sKey, $iRow, $aElements[0]

	If $sStartElement = Default Then $sStartElement = ""
	If $lMultiple = Default Then $lMultiple = False

	If $sStartElement Then
		$sElement = "/element/" & $sStartElement

		; Make sure using a relative selector if using xpath strategy
		If $sStrategy = $_WD_LOCATOR_ByXPath And StringLeft($sSelector, 1) <> '.' Then
			$iErr = $_WD_ERROR_InvalidExpression
			$sResponse = "Selector must be relative when supplying a starting element"
		EndIf
	EndIf

	If $iErr = $_WD_ERROR_Success Then
		$sCmd = ($lMultiple) ? 'elements' : 'element'
		$sSelector = __WD_EscapeString($sSelector)

		$sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & $sElement & "/" & $sCmd, '{"using":"' & $sStrategy & '","value":"' & $sSelector & '"}')
		$iErr = @error
	EndIf

	If $iErr = $_WD_ERROR_Success Then
		If $_WD_HTTPRESULT = $HTTP_STATUS_OK Then
			If $lMultiple Then

				$oJson = Json_Decode($sResponse)
				$oValues = Json_Get($oJson, '[value]')

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
				$oJson = Json_Decode($sResponse)

				$sResult = Json_Get($oJson, "[value][" & $_WD_ELEMENT_ID & "]")
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

	Return SetError($_WD_ERROR_Success, $_WD_HTTPRESULT, ($lMultiple) ? $aElements : $sResult)
EndFunc   ;==>_WD_FindElement


; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_ElementAction
; Description ...: Perform action on desginated element
; Syntax ........: _WD_ElementAction($sSession, $sElement, $sCommand[, $sOption = Default])
; Parameters ....: $sSession            - Session ID from _WDCreateSession
;                  $sElement            - Element ID from _WDFindElement
;                  $sCommand            - Action to be performed
;                  $sOption             - [optional] a string value. Default is ''.
; Return values .: Success      - Requested data returned by web driver
;                  Failure      - ""
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_NoMatch
;                  				- $_WD_ERROR_Exception
;                  				- $_WD_ERROR_InvalidDataType
;                  				- $_WD_ERROR_InvalidExpression
;                  @EXTENDED    - WinHTTP status code
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........: https://www.w3.org/TR/webdriver/#state
;                  https://www.w3.org/TR/webdriver#element-interaction
; Example .......: No
; ===============================================================================================================================
Func _WD_ElementAction($sSession, $sElement, $sCommand, $sOption = Default)
	Local Const $sFuncName = "_WD_ElementAction"
	Local $sResponse, $sResult = '', $iErr, $oJson

	If $sOption = Default Then $sOption = ''

	$sCommand = StringLower($sCommand)

	Switch $sCommand
		Case 'name', 'rect', 'text', 'selected', 'enabled', 'displayed', 'screenshot'
			$sResponse = __WD_Get($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/element/" & $sElement & "/" & $sCommand)
			$iErr = @error

		Case 'active'
			$sResponse = __WD_Get($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/element/" & $sCommand)
			$iErr = @error

		Case 'attribute', 'property', 'css'
			$sResponse = __WD_Get($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/element/" & $sElement & "/" & $sCommand & "/" & $sOption)
			$iErr = @error

		Case 'clear', 'click'
			$sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/element/" & $sElement & "/" & $sCommand, '{"id":"' & $sElement & '"}')
			$iErr = @error

		Case 'value'
			If $sOption Then
				$sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/element/" & $sElement & "/" & $sCommand, '{"id":"' & $sElement & '", "text":"' & __WD_EscapeString($sOption) & '"}')
			Else
				$sResponse = __WD_Get($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/element/" & $sElement & "/property/value")
			EndIf

			$iErr = @error

		Case Else
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(Name|Rect|Text|Selected|Enabled|Displayed|Active|Attribute|Property|CSS|Clear|Click|Value|Screenshot) $sCommand=>" & $sCommand), 0, "")

	EndSwitch

	If $iErr = $_WD_ERROR_Success Then
		Switch $_WD_HTTPRESULT
			Case $HTTP_STATUS_OK
				Switch $sCommand
					Case 'clear', 'click'
						$sResult = $sResponse

					Case 'value'
						If $sOption Then
							$sResult = $sResponse
						Else
							$oJson = Json_Decode($sResponse)
							$sResult = Json_Get($oJson, "[value]")
						EndIf

					Case Else
						$oJson = Json_Decode($sResponse)
						$sResult = Json_Get($oJson, "[value]")
				EndSwitch

			Case Else
				$iErr = $_WD_ERROR_Exception
		EndSwitch
	EndIf

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & StringLeft($sResponse,$_WD_RESPONSE_TRIM) & "..." & @CRLF)
	EndIf

	If $iErr Then
		Return SetError(__WD_Error($sFuncName, $iErr, $sResponse), $_WD_HTTPRESULT, "")
	EndIf

	Return SetError($_WD_ERROR_Success, $_WD_HTTPRESULT, $sResult)
EndFunc   ;==>_WD_ElementAction


; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_ExecuteScript
; Description ...: Execute Javascipt commands
; Syntax ........: _WD_ExecuteScript($sSession, $sScript[, $sArguments = Default[, $lAsync = Default]])
; Parameters ....: $sSession            - Session ID from _WDCreateSession
;                  $sScript             - Javascript command(s) to run
;                  $sArguments          - [optional] String of arguments in JSON format
;                  $lAsync              - [optional] Perform request asyncronously? Default is False.
; Return values .: Raw response from web driver
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_Exception
;                  				- $_WD_ERROR_Timeout
;                  				- $_WD_ERROR_SocketError
;                  				- $_WD_ERROR_InvalidValue
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........: https://www.w3.org/TR/webdriver#executing-script
; Example .......: No
; ===============================================================================================================================
Func _WD_ExecuteScript($sSession, $sScript, $sArguments = Default, $lAsync = Default)
	Local Const $sFuncName = "_WD_ExecuteScript"
	Local $sResponse, $sData, $sCmd

	If $sArguments = Default Then $sArguments = ""
	If $lAsync = Default Then $lAsync = False

	$sScript = __WD_EscapeString($sScript)

	$sData = '{"script":"' & $sScript & '", "args":[' & $sArguments & ']}'
	$sCmd = ($lAsync) ? 'async' : 'sync'

	$sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/execute/" & $sCmd, $sData)

	Local $iErr = @error

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & StringLeft($sResponse,$_WD_RESPONSE_TRIM) & "..." & @CRLF)
	EndIf

	If $iErr Then
		Return SetError(__WD_Error($sFuncName, $iErr, "HTTP status = " & $_WD_HTTPRESULT), $_WD_HTTPRESULT, $sResponse)
	EndIf

	Return SetError($_WD_ERROR_Success, $_WD_HTTPRESULT, $sResponse)
EndFunc   ;==>_WD_ExecuteScript


; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_Alert
; Description ...: Respond to user prompt
; Syntax ........: _WD_Alert($sSession, $sCommand[, $sOption = Default])
; Parameters ....: $sSession            - Session ID from _WDCreateSession
;                  $sCommand            - one of the following actions:
;                               | dismiss
;                               | accept
;                               | gettext
;                               | sendtext
;                               | status
;                  $sOption             - [optional] a string value. Default is ''.
; Return values .: Success      - Requested data returned by web driver
;                  Failure      - ""
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_Exception
;                  				- $_WD_ERROR_InvalidDataType
;                  @EXTENDED    - WinHTTP status code
; Author ........: Dan Pollak
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

	Switch $sCommand
		Case 'dismiss', 'accept'
			$sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/alert/" & $sCommand, $_WD_EmptyDict)
			$iErr = @error

			If $iErr = $_WD_ERROR_Success And $_WD_HTTPRESULT = $HTTP_STATUS_NOT_FOUND Then
				$iErr = $_WD_ERROR_NoAlert
			EndIf

		Case 'gettext'
			$sResponse = __WD_Get($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/alert/text")
			$iErr = @error

			If $iErr = $_WD_ERROR_Success Then
				If $_WD_HTTPRESULT = $HTTP_STATUS_NOT_FOUND Then
					$sResult = ""
					$iErr = $_WD_ERROR_NoAlert
				Else
					$oJSON = Json_Decode($sResponse)
					$sResult = Json_Get($oJSON, "[value]")
				EndIf
			EndIf

		Case 'sendtext'
			$sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/alert/text", '{"text":"' & $sOption & '"}')
			$iErr = @error

			If $iErr = $_WD_ERROR_Success And $_WD_HTTPRESULT = $HTTP_STATUS_NOT_FOUND Then
				$iErr = $_WD_ERROR_NoAlert
			EndIf

		Case 'status'
			$sResponse = __WD_Get($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/alert/text")
			$iErr = @error

			If $iErr = $_WD_ERROR_Success Then
				$sResult = ($_WD_HTTPRESULT = $HTTP_STATUS_NOT_FOUND) ? False : True
			EndIf

		Case Else
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(Dismiss|Accept|GetText|SendText|Status) $sCommand=>" & $sCommand), 0, "")
	EndSwitch

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & $sResponse & @CRLF)
	EndIf

	If $iErr Then
		Return SetError(__WD_Error($sFuncName, $iErr, $sResponse), $_WD_HTTPRESULT, "")
	EndIf

	Return SetError($_WD_ERROR_Success, $_WD_HTTPRESULT, $sResult)
EndFunc   ;==>_WD_Alert


; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_GetSource
; Description ...: Get page source
; Syntax ........: _WD_GetSource($sSession)
; Parameters ....: $sSession            - Session ID from _WDCreateSession
; Return values .: Success      - Source code from page
;                  Failure      - ""
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_Exception
;                  @EXTENDED    - WinHTTP status code
; Author ........: Dan Pollak
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
		$sResult = Json_Get($oJSON, "[value]")
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
; Description ...: Gets, sets, or deletes the session's cookies
; Syntax ........: _WD_Cookies($sSession, $sCommand[, $sOption = Default])
; Parameters ....: $sSession            - Session ID from _WDCreateSession
;                  $sCommand            - one of the following actions:
;                               | Get
;                               | GetAll
;                               | Add
;                               | Delete
;                  $sOption             - [optional] a string value. Default is ''.
; Return values .: Success      - Requested data returned by web driver
;                  Failure      - ""
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_Exception
;                  				- $_WD_ERROR_InvalidDataType
;                  @EXTENDED    - WinHTTP status code
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........: https://www.w3.org/TR/webdriver#cookies
; Example .......: No
; ===============================================================================================================================
Func _WD_Cookies($sSession, $sCommand, $sOption = Default)
	Local Const $sFuncName = "_WD_Cookies"
	Local $sResult, $sResponse, $iErr

	If $sOption = Default Then $sOption = ''

	Switch $sCommand
		Case 'getall'
			$sResponse = __WD_Get($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/cookie")
			$iErr = @error

			If $iErr = $_WD_ERROR_Success Then
				$sResult = $sResponse
			EndIf

		Case 'get'
			$sResponse = __WD_Get($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/cookie/" & $sOption)
			$iErr = @error

			If $iErr = $_WD_ERROR_Success Then
				$sResult = $sResponse
			EndIf

		Case 'add'
			$sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/cookie", $sOption)
			$iErr = @error

		Case 'delete'
			$sResponse = __WD_Delete($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/cookie/" & $sOption)
			$iErr = @error

		Case Else
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(GetAll|Get|Add|Delete) $sCommand=>" & $sCommand), 0, "")
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
; Description ...: Sets and get options for the web driver UDF
; Syntax ........: _WD_Option($sOption[, $vValue = Default])
; Parameters ....: $sOption             - a string value.
;                  $vValue              - [optional] a variant value. Default is "".
; Parameter(s): .: $sOption     - Driver - Full path name to web driver executable
;                               |DriverParams - Parameters to pass to web driver executable
;                               |BaseURL - IP address used for web driver communication
;                               |Port - Port used for web driver communication
;                               |BinaryFormat - Format used to store binary data
;                               |DriverClose - Close prior driver instances before launching new one (Boolean)
;                               |DriverDetect - Use existing driver instance if it exists (Boolean)
;                               |HTTPTimeouts - Set WinHTTP timeouts on each Get, Post, Delete request (Boolean)
;                               |DebugTrim - Length of response text written to the debug cocnsole
;                               |Console - Destination for console output
;
;                  $vValue      - Optional: (Default = "") : if no value is given, the current value is returned
; Return Value ..: Success      - 1 / current value
;                  Failure      - 0
;                  Failure      - ""
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_InvalidDataType
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_Option($sOption, $vValue = Default)
	Local Const $sFuncName = "_WD_Option"

	If $vValue = Default Then $vValue = ''

	Switch $sOption
		Case "driver"
			If $vValue == "" Then Return $_WD_DRIVER
			If Not IsString($vValue) Then
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(string) $vValue: " & $vValue), 0, 0)
			EndIf
			$_WD_DRIVER = $vValue
		Case "driverparams"
			If $vValue == "" Then Return $_WD_DRIVER_PARAMS
			If Not IsString($vValue) Then
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(string) $vValue: " & $vValue), 0, 0)
			EndIf
			$_WD_DRIVER_PARAMS = $vValue
		Case "baseurl"
			If $vValue == "" Then Return $_WD_BASE_URL
			If Not IsString($vValue) Then
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(string) $vValue: " & $vValue), 0, 0)
			EndIf
			$_WD_BASE_URL = $vValue
		Case "port"
			If $vValue == "" Then Return $_WD_PORT
			If Not IsInt($vValue) Then
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(int) $vValue: " & $vValue), 0, 0)
			EndIf
			$_WD_PORT = $vValue
		Case "binaryformat"
			If $vValue == "" Then Return $_WD_BFORMAT
			If Not IsInt($vValue) Then
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(int) $vValue: " & $vValue), 0, 0)
			EndIf
			$_WD_BFORMAT = $vValue
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
		Case "httptimeouts"
			If $vValue == "" Then Return $_WD_WINHTTP_TIMEOUTS
			If Not IsBool($vValue) Then
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(bool) $vValue: " & $vValue), 0, 0)
			EndIf
			$_WD_WINHTTP_TIMEOUTS = $vValue
		Case "debugtrim"
			If $vValue == "" Then Return $_WD_RESPONSE_TRIM
			If Not IsInt($vValue) Then
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(int) $vValue: " & $vValue), 0, 0)
			EndIf
			$_WD_RESPONSE_TRIM = $vValue
		Case "console"
			If $vValue == "" Then Return $_WD_CONSOLE
			If Not (IsString($vValue) Or IsInt($vValue)) Then
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(string/int) $vValue: " & $vValue), 0, 0)
			EndIf
			$_WD_CONSOLE = $vValue
		Case Else
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(Driver|DriverParams|BaseURL|Port|BinaryFormat|DriverClose|DriverDetect|HTTPTimeouts|DebugTrim|Console) $sOption=>" & $sOption), 0, 0)
	EndSwitch

	Return 1
EndFunc   ;==>_WD_Option

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_Startup
; Description ...: Launch the designated web driver console app
; Syntax ........: _WD_Startup()
; Parameters ....: None
; Return values .: Success      - PID for the WD console
;                  Failure      - 0
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_GeneralError
;                  				- $_WD_ERROR_InvalidValue
;                  @EXTENDED    - WinHTTP status code
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_Startup()
	Local Const $sFuncName = "_WD_Startup"
	Local $sFunction, $lLatest, $sUpdate, $sFile, $pid

	If $_WD_DRIVER = "" Then
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidValue, "Location for Web Driver not set." & @CRLF), 0, 0)
	EndIf

	If $_WD_DRIVER_CLOSE Then __WD_CloseDriver()

	Local $sCommand = StringFormat('"%s" %s ', $_WD_DRIVER, $_WD_DRIVER_PARAMS)

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		$sFunction = "_WD_IsLatestRelease"
		$lLatest = Call($sFunction)

		Select
			Case @error = 0xDEAD And @extended = 0xBEEF
				$sUpdate = "" ; update check not performed

			Case @error
				$sUpdate = " (Update status unknown [" & @error & "])"

			Case $lLatest
				$sUpdate = " (Up to date)"

			Case Not $lLatest
				$sUpdate = " (Update available)"

		EndSelect

		Local $sWinHttpVer = __WinHttpVer()
		If $sWinHttpVer < "1.6.4.2" Then
			$sWinHttpVer &= " (Download latest source at <https://raw.githubusercontent.com/dragana-r/autoit-winhttp/master/WinHttp.au3>)"
		EndIf

		__WD_ConsoleWrite("_WDStartup: OS:" & @TAB & @OSVersion & " " & @OSType & " " & @OSBuild & " " & @OSServicePack & @CRLF)
		__WD_ConsoleWrite("_WDStartup: AutoIt:" & @TAB & @AutoItVersion & @CRLF)
		__WD_ConsoleWrite("_WDStartup: WD.au3:" & @TAB & $__WDVERSION & $sUpdate & @CRLF)
		__WD_ConsoleWrite("_WDStartup: WinHTTP:" & @TAB & $sWinHttpVer & @CRLF)
		__WD_ConsoleWrite("_WDStartup: Driver:" & @TAB & $_WD_DRIVER & @CRLF)
		__WD_ConsoleWrite("_WDStartup: Params:" & @TAB & $_WD_DRIVER_PARAMS & @CRLF)
		__WD_ConsoleWrite("_WDStartup: Port:" & @TAB & $_WD_PORT & @CRLF)
	Else
		__WD_ConsoleWrite('_WDStartup: ' & $sCommand & @CRLF)
	EndIf

	$sFile = __WD_StripPath($_WD_DRIVER)
	$pid = ProcessExists($sFile)

	If $_WD_DRIVER_DETECT And $pid Then
		__WD_ConsoleWrite("_WDStartup: Existing instance of " & $sFile & " detected!" & @CRLF)
	Else
		$pid = Run($sCommand, "", ($_WD_DEBUG = $_WD_DEBUG_Info) ? @SW_SHOW : @SW_HIDE)
	EndIf

	If @error Then
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_GeneralError, "Error launching web driver!"), 0, 0)
	EndIf

	Return SetError($_WD_ERROR_Success, 0, $pid)
EndFunc   ;==>_WD_Startup


; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_Shutdown
; Description ...: Kill the web driver console app
; Syntax ........: _WD_Shutdown([$vDriver = Default])
; Parameters ....: $vDriver             - - [optional] The name or PID of Web driver console to shutdown.
; Return values .: None
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_Shutdown($vDriver = Default)
	__WD_CloseDriver($vDriver)
EndFunc   ;==>_WD_Shutdown



; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_Get
; Description ...: Submit GET request to WD console app
; Syntax ........: __WD_Get($sURL)
; Parameters ....: $sURL        -
; Return Value ..: Success      - Response from web driver
;                  Failure      - Response from web driver and set @ERROR
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_Exception
;                  				- $_WD_ERROR_InvalidValue
;                  				- $_WD_ERROR_InvalidDataType
; Author ........: Dan Pollak
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
		__WD_ConsoleWrite($sFuncName & ': StatusCode=' & $_WD_HTTPRESULT & "; $iResult = " & $iResult & "; $sResponseText=" & StringLeft($sResponseText,$_WD_RESPONSE_TRIM) & "..." & @CRLF)
	EndIf

	If $iResult Then
		Return SetError(__WD_Error($sFuncName, $iResult, $sResponseText), $_WD_HTTPRESULT, $sResponseText)
	EndIf

	Return SetError($_WD_ERROR_Success, 0, $sResponseText)
EndFunc   ;==>__WD_Get


; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_Post
; Description ...: Submit POST request to WD console app
; Syntax ........: __WD_Post($sURL, $sData)
; Parameters ....: $sURL                - a string value.
;                  $sData               - a string value.
; Return Value ..: Success      - Response from web driver
;                  Failure      - Response from web driver and set @ERROR
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_Exception
;                  				- $_WD_ERROR_Timeout
;                  				- $_WD_ERROR_SocketError
;                  				- $_WD_ERROR_InvalidValue
; Author ........: Dan Pollak
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
		__WD_ConsoleWrite($sFuncName & ': StatusCode=' & $_WD_HTTPRESULT & "; ResponseText=" & StringLeft($sResponseText,$_WD_RESPONSE_TRIM) & "..." & @CRLF)
	EndIf

	If $iResult Then
		Return SetError(__WD_Error($sFuncName, $iResult, $sResponseText), $_WD_HTTPRESULT, $sResponseText)
	EndIf

	Return SetError($_WD_ERROR_Success, $_WD_HTTPRESULT, $sResponseText)
EndFunc   ;==>__WD_Post


; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_Delete
; Description ...: Submit DELETE request to WD console app
; Syntax ........: __WD_Delete($sURL)
; Parameters ....: $sURL        -
; Return Value ..: Success      - Response from web driver
;                  Failure      - Response from web driver and set @ERROR
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_Exception
;                  				- $_WD_ERROR_InvalidValue
; Author ........: Dan Pollak
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
		__WD_ConsoleWrite($sFuncName & ': StatusCode=' & $_WD_HTTPRESULT & "; ResponseText=" & StringLeft($sResponseText,$_WD_RESPONSE_TRIM) & "..." & @CRLF)
	EndIf

	If $iResult Then
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception, $sResponseText), $_WD_HTTPRESULT, $sResponseText)
	EndIf

	Return SetError($_WD_ERROR_Success, 0, $sResponseText)
EndFunc   ;==>__WD_Delete


; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_Error
; Description ...: Writes Error to the console and show message-boxes if the script is compiled
; Syntax ........: __WD_Error($sWhere, $i_WD_ERROR[, $sMessage = Default])
; Parameters ....: $sWhere              - Name of calling routine
;                  $i_WD_ERROR          - Error constant
;                  $sMessage            - [optional] (Default = "") : Additional Information
; Return values .: Success      - Error Const from $i_WD_ERROR
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
EndFunc ;==>__WD_Error


; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_CloseDriver
; Description ...: Shutdown web driver console if it exists
; Syntax ........: __WD_CloseDriver([$sDriver = Default])
; Parameters ....: $vDriver             - [optional] The name or PID of Web driver console to shutdown. Default is $_WD_DRIVER
; Return values .: None
; Author ........: Dan Pollak
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
				EndIf
			Next
		EndIf

		ProcessClose($aProcessList[$i][1])
    Next

EndFunc ;==>__WD_CloseDriver

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_EscapeString
; Description ...: Escapes designated characters in string
; Syntax ........: __WD_EscapeString($sData)
; Parameters ....: $sData               - the string to be escaped
; Return Value ..: Success      - Escaped string
;                  @ERROR       - $_WD_ERROR_Success
; Return values .: None
; Author ........: Dan Pollak
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
EndFunc

Func __WD_TranslateQuotes($sData)
	Local $sResult = StringReplace($sData, '"' , "'")
	Return SetError($_WD_ERROR_Success, 0, $sResult)
EndFunc

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_DetectError
; Description ...: Evaluate results from webdriver to identify errors
; Syntax ........: __WD_DetectError(Byref $iErr, $vResult)
; Parameters ....: $iErr                - [in/out] Error code
;                  $vResult             - Result from webdriver
; Return values .: None
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WD_DetectError(ByRef $iErr, $vResult)
	; Don't perform any action if error condition is
	; already set or the webdriver result equals null
	If $iErr or $vResult == Null Then Return

	; Extract "value" element from JSON string
	If Not IsObj($vResult) Then
		Local $oJSON = Json_Decode($vResult)
		$vResult = Json_Get($oJSON, "[value]")

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
				$iErr =  $_WD_ERROR_NoMatch

			Case $WD_Element_Invalid
				$iErr = $_WD_ERROR_InvalidArgue

			Case $WD_Element_Intercept, $WD_Element_NotInteract
				$iErr = $_WD_ERROR_ElementIssue

			Case Else
				$iErr = $_WD_ERROR_Exception

		EndSwitch
	EndIf
EndFunc

Func __WD_StripPath($sFilePath)
	Return StringRegExpReplace($sFilePath, "^.*\\(.*)$", "$1")
EndFunc

Func __WD_ConsoleWrite($sMsg)
	If $_WD_CONSOLE = Default Then
		ConsoleWrite($sMsg)
	Else
		FileWrite($_WD_CONSOLE, $sMsg)
	EndIf
EndFunc
