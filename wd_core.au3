#include-once
; standard UDF's
#include <MsgBoxConstants.au3> ; used in __WD_Error
#include <WinAPIFiles.au3> ; used in _WD_Startup
#include <WinAPIProc.au3> ; used in __WD_CloseDriver

; WebDriver related UDF's
#include "JSON.au3" ; https://www.autoitscript.com/forum/topic/148114-a-non-strict-json-udf-jsmn
#include "WinHttp.au3" ; https://www.autoitscript.com/forum/topic/84133-winhttp-functions/

#Region Copyright
#cs
	* WD_Core.au3
	*
	* MIT License
	*
	* Copyright (c) 2023 Dan Pollak (@Danp2)
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
#Tidy_Parameters=/tcb=-1

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
;                  Chrome WebDriver https://sites.google.com/chromium.org/driver/
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
Global Const $__WDVERSION = "1.3.0"

Global Const $_WD_ELEMENT_ID = "element-6066-11e4-a52e-4f735466cecf"
Global Const $_WD_SHADOW_ID = "shadow-6066-11e4-a52e-4f735466cecf"
Global Const $_WD_EmptyDict = "{}"
Global Const $_WD_EmptyCaps = '{"capabilities":{}}'

Global Const $_WD_LOCATOR_ByCSSSelector = "css selector"
Global Const $_WD_LOCATOR_ByXPath = "xpath"
Global Const $_WD_LOCATOR_ByLinkText = "link text"
Global Const $_WD_LOCATOR_ByPartialLinkText = "partial link text"
Global Const $_WD_LOCATOR_ByTagName = "tag name"

Global Const $_WD_JSON_Value = "[value]"
Global Const $_WD_JSON_Element = "[value][" & $_WD_ELEMENT_ID & "]"
Global Const $_WD_JSON_Shadow = "[value][" & $_WD_SHADOW_ID & "]"
Global Const $_WD_JSON_Error = "[value][error]"
Global Const $_WD_JSON_Message = "[value][message]"

#Tidy_ILC_Pos=32
Global Enum _
		$_WD_DEBUG_None = 0, _ ; No logging
		$_WD_DEBUG_Error, _    ; logging in case of Error
		$_WD_DEBUG_Info, _     ; logging with additional information
		$_WD_DEBUG_Full        ; logging with full details for developers

#Tidy_ILC_Pos=42
Global Enum _
		$_WD_ERROR_Success = 0, _        ; No error
		$_WD_ERROR_GeneralError, _       ; General error
		$_WD_ERROR_SocketError, _        ; No socket
		$_WD_ERROR_InvalidDataType, _    ; Invalid data type (IP, URL, Port ...)
		$_WD_ERROR_InvalidValue, _       ; Invalid value in function-call
		$_WD_ERROR_InvalidArgue, _       ; Invalid argument in function-call
		$_WD_ERROR_SendRecv, _           ; Send / Recv Error
		$_WD_ERROR_Timeout, _            ; Connection / Send / Recv timeout
		$_WD_ERROR_NoMatch, _            ; No match for _WDAction-find/search _WDGetElement...
		$_WD_ERROR_RetValue, _           ; Error echo from Repl e.g. _WDAction("fullscreen","true") <> "true"
		$_WD_ERROR_Exception, _          ; Exception from web driver
		$_WD_ERROR_InvalidExpression, _  ; Invalid expression in XPath query, CSSSelector query or RegEx
		$_WD_ERROR_NoAlert, _            ; No alert present when calling _WD_Alert
		$_WD_ERROR_NotFound, _           ; File or registry key not found
		$_WD_ERROR_ElementIssue, _       ; Problem interacting with element (click intercepted, etc)
		$_WD_ERROR_SessionNotCreated, _  ; Session not created
		$_WD_ERROR_SessionInvalid, _     ; Invalid session ID was submitted to webdriver
		$_WD_ERROR_ContextInvalid, _     ; Invalid browsing context
		$_WD_ERROR_UnknownCommand, _     ; Unknown command submitted to webdriver
		$_WD_ERROR_UserAbort, _          ; In case when user abort when @error occurs and $_WD_ERROR_MSGBOX was set
		$_WD_ERROR_FileIssue, _          ; Errors related to WebDriver EXE File
		$_WD_ERROR_NotSupported, _       ; When user try to use unsupported browser or capability
		$_WD_ERROR_AlreadyDefined, _     ; Capability previously defined
		$_WD_ERROR_Javascript, _         ; Javascript error
		$_WD_ERROR_Mismatch, _           ; Version mismatch
		$_WD_ERROR__COUNTER              ; Defines row count for $aWD_ERROR_DESC
#Tidy_ILC_Pos=0

Global Const $aWD_ERROR_DESC[$_WD_ERROR__COUNTER] = [ _
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
		"Session not created", _
		"Invalid session ID", _
		"Invalid Browsing Context", _
		"Unknown Command", _
		"User Aborted", _
		"File issue", _
		"Browser or feature not supported", _
		"Capability or value already defined", _
		"Javascript Exception", _
		"Version mismatch" _
		]

Global Const $_WD_ErrorInvalidSession = "invalid session id"
Global Const $_WD_ErrorUnknownCommand = "unknown command"
Global Const $_WD_ErrorTimeout = "timeout"
Global Const $_WD_ErrorJavascript = "javascript error"
Global Const $_WD_ErrorNoSuchAlert = "no such alert"
Global Const $_WD_ErrorInvalidSelector = "invalid selector"
Global Const $_WD_ErrorElementNotFound = "no such element"
Global Const $_WD_ErrorShadowRootNotFound = "no such shadow root"
Global Const $_WD_ErrorElementStale = "stale element reference"
Global Const $_WD_ErrorElementInvalid = "invalid argument"
Global Const $_WD_ErrorElementIntercept = "element click intercepted"
Global Const $_WD_ErrorElementNotInteract = "element not interactable"
Global Const $_WD_ErrorWindowNotFound = "no such window"
Global Const $_WD_ErrorFrameNotFound = "no such frame"
Global Const $_WD_ErrorSessionNotCreated = "session not created"

Global Const $_WD_WinHTTPTimeoutMsg = "WinHTTP request timed out before Webdriver"

Global Enum _ ; Column positions of $_WD_SupportedBrowsers
		$_WD_BROWSER_Name, _
		$_WD_BROWSER_ExeName, _
		$_WD_BROWSER_DriverName, _
		$_WD_BROWSER_64Bit, _
		$_WD_BROWSER_OptionsKey, _
		$_WD_BROWSER_LatestReleaseURL, _
		$_WD_BROWSER_LatestReleaseRegex, _
		$_WD_BROWSER_NewDriverURL, _
		$_WD_BROWSER__COUNTER

#Tidy_Off
Global Const $_WD_SupportedBrowsers[][$_WD_BROWSER__COUNTER] = _
		[ _
			[ _
				"chrome", _
				"chrome.exe", _
				"chromedriver.exe", _
				True,  _
				"goog:chromeOptions", _
				"https://googlechromelabs.github.io/chrome-for-testing/latest-versions-per-milestone-with-downloads.json", _
				'{"milestone":"%s","version":"(\d+.\d+.\d+.\d+)"', _
				'"https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/" & $sDriverLatest & (($bFlag64) ? "/win64/chromedriver-win64.zip" : "/win32/chromedriver-win32.zip")' _
			], _
			[ _
				"chrome_legacy", _ ; Prior to v115
				"chrome.exe", _
				"chromedriver.exe", _
				False, _
				"goog:chromeOptions", _
				"'https://chromedriver.storage.googleapis.com/LATEST_RELEASE_' & StringLeft($sBrowserVersion, StringInStr($sBrowserVersion, '.') - 1)", _
				"", _
				'"https://chromedriver.storage.googleapis.com/" & $sDriverLatest & "/chromedriver_win32.zip"' _
			], _
			[ _
				"firefox", _
				"firefox.exe", _
				"geckodriver.exe", _
				True,  _
				"moz:firefoxOptions", _
				"https://github.com/mozilla/geckodriver/releases/latest", _
				'<a.*href="\/mozilla\/geckodriver\/releases\/tag\/(?:v)(.*?)"', _
				'"https://github.com/mozilla/geckodriver/releases/download/v" & $sDriverLatest & "/geckodriver-v" & $sDriverLatest & (($bFlag64) ? "-win64.zip" : "-win32.zip")' _
			], _
			[ _
				"msedge", _
				"msedge.exe", _
				"msedgedriver.exe", _
				True,  _
				"ms:edgeOptions", _
				"'https://msedgedriver.azureedge.net/LATEST_RELEASE_' & StringLeft($sBrowserVersion, StringInStr($sBrowserVersion, '.') - 1) & '_WINDOWS'", _
				"", _
				'"https://msedgedriver.azureedge.net/" & $sDriverLatest & "/edgedriver_" & (($bFlag64) ? "win64.zip" : "win32.zip")' _
			], _
			[ _
				"opera", _
				"opera.exe", _
				"operadriver.exe", _
				True,  _
				"goog:chromeOptions", _
				"https://github.com/operasoftware/operachromiumdriver/releases/latest", _
				'<a.*href="\/operasoftware\/operachromiumdriver\/releases\/tag\/(?:v\.)(.*?)"',  _
				'"https://github.com/operasoftware/operachromiumdriver/releases/download/v." & $sDriverLatest & "/operadriver_" & (($bFlag64) ? "win64.zip" : "win32.zip")' _
			], _
			[ _
				"msedgeie", _
				"msedge.exe", _
				"IEDriverServer.exe", _
				True,  _
				"se:ieOptions", _
				"https://github.com/SeleniumHQ/selenium/blob/trunk/cpp/iedriverserver/CHANGELOG", _
				'(?s)(?:major.minor.build.revision.*?v)(\d+\.\d+\.\d+)', _
				'"https://github.com/SeleniumHQ/selenium/releases/download/selenium-" & StringRegExpReplace($sDriverLatest, "(\d+\.\d+)(\.\d+)", "$1") & ".0/IEDriverServer_" & (($bFlag64) ? "x64" : "Win32") & "_" & $sDriverLatest & ".zip"' _
			] _
		]
#Tidy_On

#EndRegion Global Constants

#Region Global Variables
#Tidy_ILC_Pos=44
Global $_WD_DRIVER = ""                    ; Path to web driver executable
Global $_WD_DRIVER_PARAMS = ""             ; Parameters to pass to web driver executable
Global $_WD_BASE_URL = "HTTP://127.0.0.1"
Global $_WD_PORT = 0                       ; Port used for web driver communication
Global $_WD_HTTPRESULT = 0                 ; Result of last WinHTTP request
Global $_WD_HTTPRESPONSE = ''              ; Response of last WinHTTP request
Global $_WD_SESSION_DETAILS = ""           ; Response from _WD_CreateSession
Global $_WD_BFORMAT = $SB_UTF8             ; Binary format
Global $_WD_DRIVER_CLOSE = True            ; Close prior driver instances before launching new one
Global $_WD_DRIVER_DETECT = True           ; Don't launch new driver instance if one already exists
Global $_WD_RESPONSE_TRIM = -1             ; Trim response string to given value for debug output
Global $_WD_ERROR_MSGBOX = False           ; Shows in compiled scripts error messages in msgboxes
Global $_WD_ERROR_OUTPUTDEBUG = False      ; Log errors to "OutputDebugString"
Global $_WD_DEBUG = $_WD_DEBUG_Info        ; Trace to console and show web driver app
Global $_WD_CONSOLE = ConsoleWrite         ; Destination for console output
Global $_WD_CONSOLE_Suffix = @CRLF         ; Suffix added to the end of Message in $_WD_CONSOLE function
Global $_WD_Sleep = Sleep                  ; Default to calling standard Sleep function
Global $_WD_DefaultTimeout = 10000         ; 10 seconds
Global $_WD_WINHTTP_TIMEOUTS = True
Global $_WD_HTTPTimeOuts[4] = [0, 60000, 30000, 30000]
Global $_WD_HTTPContentType = "Content-Type: application/json"
Global $_WD_DetailedErrors = False
#Tidy_ILC_Pos=0

#EndRegion Global Variables

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_CreateSession
; Description ...: Request new session from web driver.
; Syntax ........: _WD_CreateSession([$sCapabilities = Default])
; Parameters ....: $sCapabilities - [optional] Requested features in JSON format. Default is '{"capabilities":{}}'
; Return values .: Success - Session ID to be used in future requests to web driver session.
;                  Failure - "" (empty string) and sets @error to one of the following values:
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_SessionNotCreated
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......:
; Related .......: _WD_DeleteSession, _WD_LastHTTPResult
; Link ..........: https://www.w3.org/TR/webdriver#new-session
; Example .......: No
; ===============================================================================================================================
Func _WD_CreateSession($sCapabilities = Default)
	Local Const $sFuncName = "_WD_CreateSession"
	Local $sSession = "", $sMessage = ''

	If $sCapabilities = Default Then $sCapabilities = $_WD_EmptyCaps

	$_WD_SESSION_DETAILS = '' ; resetting saved response details before making new request
	Local $sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session", $sCapabilities)
	Local $iErr = @error
	Local $oJSON = Json_Decode($sResponse)

	If $iErr = $_WD_ERROR_Success Then
		$sSession = Json_Get($oJSON, "[value][sessionId]")

		If @error Then
			$sMessage = Json_Get($oJSON, $_WD_JSON_Message)
			$iErr = $_WD_ERROR_Exception
		Else
			$sMessage = $sSession

			; Save response details for future use
			$_WD_SESSION_DETAILS = $sResponse
		EndIf
	Else
		If $iErr = $_WD_ERROR_SessionNotCreated Then
			$sMessage = Json_Get($oJSON, $_WD_JSON_Message)
		ElseIf Not $_WD_DetailedErrors Then
			$iErr = $_WD_ERROR_Exception
		EndIf
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr, $sMessage), 0, $sSession)
EndFunc   ;==>_WD_CreateSession

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_DeleteSession
; Description ...:  Delete existing session.
; Syntax ........: _WD_DeleteSession($sSession)
; Parameters ....: $sSession - Session ID from _WD_CreateSession
; Return values .: Success - 1
;                  Failure - 0 and sets @error to $_WD_ERROR_Exception
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......:
; Related .......: _WD_CreateSession, _WD_LastHTTPResult
; Link ..........: https://www.w3.org/TR/webdriver#delete-session
; Example .......: No
; ===============================================================================================================================
Func _WD_DeleteSession($sSession)
	Local Const $sFuncName = "_WD_DeleteSession"
	__WD_Delete($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession)
	Local $iErr = @error

	If $iErr <> $_WD_ERROR_Success And Not $_WD_DetailedErrors Then $iErr = $_WD_ERROR_Exception

	Local $sMessage = ($iErr) ? ('Error occurs when trying to delete session') : ('WebDriver session deleted')
	Local $iReturn = ($iErr) ? (0) : (1)
	Return SetError(__WD_Error($sFuncName, $iErr, $sMessage), 0, $iReturn)
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
; Related .......: _WD_LastHTTPResult
; Link ..........: https://www.w3.org/TR/webdriver#status
; Example .......: No
; ===============================================================================================================================
Func _WD_Status()
	Local Const $sFuncName = "_WD_Status"
	Local $sResponse = __WD_Get($_WD_BASE_URL & ":" & $_WD_PORT & "/status")
	Local $iErr = @error, $oResult = ""

	If $iErr = $_WD_ERROR_Success Then
		Local $oJSON = Json_Decode($sResponse)
		$oResult = Json_Get($oJSON, $_WD_JSON_Value)
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr), 0, $oResult)
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
; Related .......: _WD_CreateSession, _WD_LastHTTPResult
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

	__WD_ConsoleWrite($sFuncName & ": " & $sResponse, $_WD_DEBUG_Info)

	If $iErr Then
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception), 0, $sResult)
	EndIf
	#ce See remarks in header

	$sResult = $_WD_SESSION_DETAILS

	Return SetError(__WD_Error($sFuncName, $_WD_ERROR_Success), 0, $sResult)
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
; Remarks .......: Separate timeouts can be set for "script", "pageLoad", and "implicit".
; Related .......: _WD_LastHTTPResult
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

	If $iErr Then $sResponse = 0
	Return SetError(__WD_Error($sFuncName, $iErr), 0, $sResponse)
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
; Related .......: _WD_LastHTTPResult
; Link ..........: https://www.w3.org/TR/webdriver#navigate-to
; Example .......: No
; ===============================================================================================================================
Func _WD_Navigate($sSession, $sURL)
	Local Const $sFuncName = "_WD_Navigate"
	Local Const $sParameters = 'Parameters:   URL=' & $sURL
	__WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/url", '{"url":"' & $sURL & '"}')
	Local $iErr = @error

	Local $iReturn = ($iErr) ? (0) : (1)
	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters), 0, $iReturn)
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
; Related .......: _WD_LastHTTPResult
; Link ..........: https://www.w3.org/TR/webdriver#navigation
;                  https://www.w3.org/TR/webdriver#actions
; Example .......: No
; ===============================================================================================================================
Func _WD_Action($sSession, $sCommand, $sOption = Default)
	Local Const $sFuncName = "_WD_Action"
	Local Const $sParameters = 'Parameters:   Command=' & $sCommand & '   Option=' & $sOption
	Local $sResponse, $sResult = "", $iErr, $oJSON, $sURLCommand
	$_WD_HTTPRESULT = 0

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

	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters), 0, $sResult)
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
; Related .......: _WD_LastHTTPResult
; Link ..........: https://www.w3.org/TR/webdriver/#contexts
; Example .......: No
; ===============================================================================================================================
Func _WD_Window($sSession, $sCommand, $sOption = Default)
	Local Const $sFuncName = "_WD_Window"
	Local Const $sParameters = 'Parameters:   Command=' & $sCommand & '   Option=' & $sOption
	Local $sResponse, $oJSON, $sResult = "", $iErr
	$_WD_HTTPRESULT = 0

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
			$sOption = __WD_JsonHandle($sOption)
			$sResponse = __WD_Post($sURLSession & "window", $sOption)
			$iErr = @error

		Case 'window'
			If $sOption = '' Then
				$sResponse = __WD_Get($sURLSession & $sCommand)
			Else
				$sOption = __WD_JsonHandle($sOption)
				$sResponse = __WD_Post($sURLSession & $sCommand, $sOption)
			EndIf

			$iErr = @error

		Case Else
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(Close|Frame|Fullscreen|Handles|Maximize|Minimize|New|Parent|Print|Rect|Screenshot|Switch|Window) $sCommand=>" & $sCommand), 0, "")

	EndSwitch

	If $iErr = $_WD_ERROR_Success Then
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
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters), 0, $sResult)
EndFunc   ;==>_WD_Window

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_FindElement
; Description ...: Find element(s) by designated strategy.
; Syntax ........: _WD_FindElement($sSession, $sStrategy, $sSelector[, $sStartNodeID = Default[, $bMultiple = Default[,
;                  $bShadowRoot = Default]]])
; Parameters ....: $sSession     - Session ID from _WD_CreateSession
;                  $sStrategy    - Locator strategy. See defined constant $_WD_LOCATOR_* for allowed values
;                  $sSelector    - Indicates how the WebDriver should traverse through the HTML DOM to locate the desired element(s).
;                  $sStartNodeID - [optional] Element ID to use as starting HTML node. Default is ""
;                  $bMultiple    - [optional] Return multiple matching elements? Default is False
;                  $bShadowRoot  - [optional] Starting HTML node is a shadow root? Default is False
; Return values .: Success - Element ID(s) returned by web driver.
;                  Failure - "" (empty string) and sets @error to one of the following values:
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_NoMatch
;                  - $_WD_ERROR_InvalidExpression
; Author ........: Danp2
; Modified ......:
; Remarks .......: An array of matching elements is returned when $bMultiple is True.
; Related .......: _WD_LastHTTPResult
; Link ..........: https://www.w3.org/TR/webdriver#element-retrieval
; Example .......: No
; ===============================================================================================================================
Func _WD_FindElement($sSession, $sStrategy, $sSelector, $sStartNodeID = Default, $bMultiple = Default, $bShadowRoot = Default)
	Local Const $sFuncName = "_WD_FindElement"
	Local Const $sParameters = 'Parameters:   Strategy=' & $sStrategy & '   Selector=' & $sSelector & '   StartNodeID=' & $sStartNodeID & '   Multiple=' & $bMultiple & '   ShadowRoot=' & $bShadowRoot
	Local $sCmd, $sBaseCmd = '', $sResponse, $sResult, $iErr = $_WD_ERROR_Success
	Local $oJSON, $oValues, $sKey, $iRow, $aElements[0]
	$_WD_HTTPRESULT = 0

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
	EndIf

	Local $vResult = ($bMultiple) ? $aElements : $sResult
	If $iErr Then $vResult = ""
	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters), 0, $vResult)
EndFunc   ;==>_WD_FindElement

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_ElementAction
; Description ...: Perform action on designated element.
; Syntax ........: _WD_ElementAction($sSession, $sElement, $sCommand[, $sOption = Default])
; Parameters ....: $sSession - Session ID from _WD_CreateSession
;                  $sElement - Element ID from _WD_FindElement
;                  $sCommand - One of the following actions:
;                  |
;                  |ACTIVE        - Get active element
;                  |ATTRIBUTE     - Get element's attribute
;                  |CLEAR         - Clear element's value
;                  |CLICK         - Click element
;                  |COMPUTEDLABEL - Get element's computed label
;                  |COMPUTEDROLE  - Get element's computed role
;                  |CSS           - Get element's CSS value
;                  |DISPLAYED     - Get element's visibility
;                  |ENABLED       - Get element's enabled status
;                  |NAME          - Get element's tag name
;                  |PROPERTY      - Get element's property
;                  |RECT          - Get element's dimensions / coordinates
;                  |SCREENSHOT    - Take element screenshot
;                  |SELECTED      - Get element's selected status
;                  |SHADOW        - Get element's shadow root
;                  |TEXT          - Get element's rendered text
;                  |VALUE         - Get or set element's value. If $sOption = "" the value of the element is returned, else set
;                  $sOption  - [optional] a string value. Default is ""
; Return values .: Success - Requested data returned by web driver.
;                  Failure - "" (empty string) and sets @error to one of the following values:
;                  - $_WD_ERROR_NoMatch
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_InvalidDataType
;                  - $_WD_ERROR_InvalidExpression
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......:
; Related .......: _WD_LastHTTPResult
; Link ..........: https://www.w3.org/TR/webdriver/#state
;                  https://www.w3.org/TR/webdriver#element-interaction
;                  https://www.w3.org/TR/webdriver/#take-element-screenshot
;                  https://www.w3.org/TR/webdriver/#element-displayedness
; Example .......: No
; ===============================================================================================================================
Func _WD_ElementAction($sSession, $sElement, $sCommand, $sOption = Default)
	Local Const $sFuncName = "_WD_ElementAction"
	; because $sOption can contain sensitive data, mask value unless $_WD_DEBUG_Full is used (refers to the case when VALUE will be set)
	Local $bParameters_Option = ($_WD_DEBUG = $_WD_DEBUG_Full Or Not ($sCommand = 'VALUE' And $sOption))
	Local Const $sParameters = "Parameters:   Command=" & $sCommand & "   Option=" & (($bParameters_Option Or Not $sOption) ? ($sOption) : ("<masked>"))
	Local $sResponse, $sResult = '', $iErr, $oJSON
	$_WD_HTTPRESULT = 0

	If $sOption = Default Then $sOption = ''

	$sCommand = StringLower($sCommand)

	Local $sURLElement = $_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/element/"
	Switch $sCommand
		Case 'computedlabel', 'computedrole', 'displayed', 'enabled', 'name', 'rect', 'selected', 'shadow', 'screenshot', 'text'
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
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(Active|Attribute|ComputedRole|ComputedLabel|Clear|Click|CSS|Displayed|Enabled|Name|Property|Rect|Selected|Shadow|Screenshot|Text|Value) $sCommand=>" & $sCommand), 0, "")

	EndSwitch

	If $iErr = $_WD_ERROR_Success Then
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
	EndIf

	If $iErr Then $sResult = ""
	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters), 0, $sResult)
EndFunc   ;==>_WD_ElementAction

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_ExecuteScript
; Description ...: Execute Javascipt commands.
; Syntax ........: _WD_ExecuteScript($sSession, $sScript[, $sArguments = Default[, $bAsync = Default[, $vSubNode = Default]]])
; Parameters ....: $sSession   - Session ID from _WD_CreateSession
;                  $sScript    - Javascript command(s) to run
;                  $sArguments - [optional] String of arguments in JSON format
;                  $bAsync     - [optional] Perform request asyncronously? Default is False
;                  $vSubNode   - [optional] Return the designated JSON node instead of the entire JSON string. Default is "" (entire response is returned)
; Return values .: Success - Response from web driver in JSON format or value requested by given $vSubNode
;                  Failure - Response from web driver in JSON format and maintains @error value originally set by __WD_Post()
;                            If script is executed successfully but $vSubNode isn't found, then "" (empty string) and sets @error to $_WD_ERROR_RetValue
;                            If $vSubNode isn't valid, then "" (empty string) and sets @error to _WD_ERROR_InvalidArgue
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......:
; Related .......: _WD_LastHTTPResult
; Link ..........: https://www.w3.org/TR/webdriver#executing-script
; Example .......: No
; ===============================================================================================================================
Func _WD_ExecuteScript($sSession, $sScript, $sArguments = Default, $bAsync = Default, $vSubNode = Default)
	Local Const $sFuncName = "_WD_ExecuteScript"
	Local $sResponse, $sData, $sCmd, $sMessage = ""
	$_WD_HTTPRESULT = 0

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
		Local $oJSON = Json_Decode($sResponse)

		If $iErr = $_WD_ERROR_Success Then
			If StringLen($vSubNode) Then
				$sResponse = Json_Get($oJSON, $vSubNode)
				If @error Then
					$iErr = $_WD_ERROR_RetValue
					$sMessage = "Subnode '" & $vSubNode & "' not found."
				EndIf
			EndIf
		Else
			$sMessage = Json_Get($oJSON, $_WD_JSON_Message)
		EndIf
	Else
		$iErr = $_WD_ERROR_InvalidArgue
		$sResponse = ""
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr, $sMessage), 0, $sResponse)
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
; Return values .: Success - True/False or requested data returned by web driver.
;                  Failure - "" (empty string) and sets @error to one of the following values:
;                  - $_WD_ERROR_NoAlert
;                  - $_WD_ERROR_InvalidDataType
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......:
; Related .......: _WD_LastHTTPResult
; Link ..........: https://www.w3.org/TR/webdriver#user-prompts
; Example .......: No
; ===============================================================================================================================
Func _WD_Alert($sSession, $sCommand, $sOption = Default)
	Local Const $sFuncName = "_WD_Alert"
	Local Const $sParameters = 'Parameters:   Command=' & $sCommand & '   Option=' & $sOption
	Local $sResponse, $iErr, $oJSON, $sResult = ''
	$_WD_HTTPRESULT = 0

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
			If $iErr = $_WD_ERROR_NoAlert Then $iErr = $_WD_ERROR_Success

		Case Else
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(Accept|Dismiss|GetText|SendText|Status) $sCommand=>" & $sCommand), 0, "")
	EndSwitch

	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters), 0, $sResult)
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
; Related .......: _WD_LastHTTPResult
; Link ..........: https://www.w3.org/TR/webdriver#get-page-source
; Example .......: No
; ===============================================================================================================================
Func _WD_GetSource($sSession)
	Local Const $sFuncName = "_WD_GetSource"
	Local $iErr, $sResult = "", $oJSON
	Local $sResponse = __WD_Get($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/source")
	$iErr = @error

	If $iErr = $_WD_ERROR_Success Then
		$oJSON = Json_Decode($sResponse)
		$sResult = Json_Get($oJSON, $_WD_JSON_Value)
	EndIf

	If $iErr Then $sResult = ""
	Return SetError(__WD_Error($sFuncName, $iErr), 0, $sResult)
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
; Remarks .......: Please have a look at wd_demo.au3 > DemoCookies function for how to add a new cookie.
; Related .......: _WD_JsonCookie, _WD_LastHTTPResult
; Link ..........: https://www.w3.org/TR/webdriver#cookies
; Example .......: No
; ===============================================================================================================================
Func _WD_Cookies($sSession, $sCommand, $sOption = Default)
	Local Const $sFuncName = "_WD_Cookies"
	Local Const $sParameters = 'Parameters:   Command=' & $sCommand & '   Option=' & $sOption
	Local $sResult, $sResponse, $iErr = $_WD_ERROR_Success
	If $sOption = Default Then $sOption = ''
	$_WD_HTTPRESULT = 0

	Local $sURLSession = $_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/"
	Switch $sCommand
		Case 'add'
			$sResponse = __WD_Post($sURLSession & "cookie", $sOption)
			$iErr = @error

		Case 'delete', 'deleteall'
			If $sCommand = 'delete' And IsString($sOption) = 0 Then $iErr = $_WD_ERROR_InvalidArgue
			If $sCommand = 'deleteall' And $sOption <> '' Then $iErr = $_WD_ERROR_InvalidArgue
			If $iErr = $_WD_ERROR_Success Then
				$sResponse = __WD_Delete($sURLSession & "cookie" & (($sOption <> '') ? "/" & $sOption : ""))
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

	If $iErr Then $sResult = ""
	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters), 0, $sResult)
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
;                  |CONSOLESUFFIX  - Suffix for console output
;                  |DEBUGTRIM      - Length of response text written to the debug cocnsole
;                  |DEFAULTTIMEOUT - Default timeout (in miliseconds) used by other functions if no other value is supplied
;                  |DETAILERRORS   - Return detailed error codes? (Boolean)
;                  |DRIVER         - Full path name to web driver executable
;                  |DRIVERCLOSE    - Close prior driver instances before launching new one (Boolean)
;                  |DRIVERDETECT   - Use existing driver instance if it exists (Boolean)
;                  |DRIVERPARAMS   - Parameters to pass to web driver executable
;                  |ERRORMSGBOX    - Enable/Disable reporting errors to MsgBox() (Boolean)
;                  |OUTPUTDEBUG    - Enable/Disable reporting errors to OutputDebugString (Boolean)
;                  |HTTPTIMEOUTS   - Set WinHTTP timeouts on each Get, Post, Delete request (Boolean)
;                  |PORT           - Port used for web driver communication
;                  |SLEEP          - Function to be called when UDF pauses the script execution
;                  |VERSION        - Version number of UDF library (read only)
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
	Local Const $sParameters = 'Parameters:   Option=' & $sOption & '   Value=' & ((IsFunc($vValue)) ? (FuncName($vValue)) : ($vValue))

	If $vValue = Default Then $vValue = ''

	Switch $sOption
		Case "baseurl"
			If $vValue == "" Then Return $_WD_BASE_URL
			If Not IsString($vValue) Then
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, $sParameters & " (Required $vValue type: string)"), 0, 0)
			EndIf
			$_WD_BASE_URL = $vValue

		Case "binaryformat"
			If $vValue == "" Then Return $_WD_BFORMAT
			If Not IsInt($vValue) Then
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, $sParameters & " (Required $vValue type: int)"), 0, 0)
			EndIf
			$_WD_BFORMAT = $vValue

		Case "console"
			If $vValue == "" Then Return $_WD_CONSOLE
			If Not (IsString($vValue) Or IsInt($vValue) Or IsFunc($vValue) Or $vValue = Null) Then
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, $sParameters & " (Required $vValue type: func/int/null/string)"), 0, 0)
			EndIf
			$_WD_CONSOLE = $vValue

		Case "consolesuffix"
			If $vValue == "" Then Return $_WD_CONSOLE_Suffix
			$_WD_CONSOLE_Suffix = $vValue

		Case "debugtrim"
			If $vValue == "" Then Return $_WD_RESPONSE_TRIM
			If Not IsInt($vValue) Then
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, $sParameters & " (Required $vValue type: int)"), 0, 0)
			EndIf
			$_WD_RESPONSE_TRIM = $vValue

		Case "DefaultTimeout"
			If $vValue == "" Then Return $_WD_DefaultTimeout
			If Not IsInt($vValue) Then
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, $sParameters & " (Required $vValue type: int)"), 0, 0)
			EndIf
			$_WD_DefaultTimeout = $vValue

		Case "detailerrors"
			If $vValue == "" Then Return $_WD_DetailedErrors
			If Not IsBool($vValue) Then
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, $sParameters & " (Required $vValue type: bool)"), 0, 0)
			EndIf
			$_WD_DetailedErrors = $vValue

		Case "driver"
			If $vValue == "" Then Return $_WD_DRIVER
			If Not IsString($vValue) Then
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, $sParameters & " (Required $vValue type: string)"), 0, 0)
			EndIf
			$_WD_DRIVER = $vValue

		Case "driverclose"
			If $vValue == "" Then Return $_WD_DRIVER_CLOSE
			If Not IsBool($vValue) Then
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, $sParameters & " (Required $vValue type: bool)"), 0, 0)
			EndIf
			$_WD_DRIVER_CLOSE = $vValue

		Case "driverdetect"
			If $vValue == "" Then Return $_WD_DRIVER_DETECT
			If Not IsBool($vValue) Then
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, $sParameters & " (Required $vValue type: bool)"), 0, 0)
			EndIf
			$_WD_DRIVER_DETECT = $vValue

		Case "driverparams"
			If $vValue == "" Then Return $_WD_DRIVER_PARAMS
			If Not IsString($vValue) Then
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, $sParameters & " (Required $vValue type: string)"), 0, 0)
			EndIf
			$_WD_DRIVER_PARAMS = $vValue

		Case "httptimeouts"
			If $vValue == "" Then Return $_WD_WINHTTP_TIMEOUTS
			If Not IsBool($vValue) Then
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, $sParameters & " (Required $vValue type: bool)"), 0, 0)
			EndIf
			$_WD_WINHTTP_TIMEOUTS = $vValue

		Case "errormsgbox"
			If $vValue == "" Then Return $_WD_ERROR_MSGBOX
			If Not IsBool($vValue) Then
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, $sParameters & " (Required $vValue type: bool)"), 0, 0)
			EndIf
			$_WD_ERROR_MSGBOX = $vValue

		Case "OutputDebug"
			If $vValue == "" Then Return $_WD_ERROR_OUTPUTDEBUG
			If Not IsBool($vValue) Then
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, $sParameters & " (Required $vValue type: bool)"), 0, 0)
			EndIf
			$_WD_ERROR_OUTPUTDEBUG = $vValue

		Case "port"
			If $vValue == "" Then Return $_WD_PORT
			If Not IsInt($vValue) Then
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, $sParameters & " (Required $vValue type: int)"), 0, 0)
			EndIf
			$_WD_PORT = $vValue

		Case "Sleep"
			If $vValue == "" Then Return $_WD_Sleep
			If Not IsFunc($vValue) Then
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, $sParameters & " (Required $vValue type: func)"), 0, 0)
			EndIf
			$_WD_Sleep = $vValue

		Case "version"
			If $vValue == "" Then Return $__WDVERSION
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, $sParameters & " (Required $vValue type: none)"), 0, 0)

		Case Else
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, $sParameters & " (Required $sOption: BaseURL|BinaryFormat|Console|ConsoleSuffix|DebugTrim|DefaultTimeout|DetailErrors|Driver|DriverClose|DriverDetect|DriverParams|ErrorMsgBox|HTTPTimeouts|OutputDebug|Port|Sleep|Version)"), 0, 0)
	EndSwitch

	Return SetError(__WD_Error($sFuncName, $_WD_ERROR_Success, $sParameters), 0, 1)
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
;                  - $_WD_ERROR_FileIssue
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......:
; Related .......: _WD_Shutdown
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_Startup()
	Local Const $sFuncName = "_WD_Startup"
	Local $sFunction, $bLatest, $sUpdate, $sFile, $iPID, $iErr = $_WD_ERROR_Success
	Local $sDriverBitness = "", $sExistingDriver = "", $sPortAvailable = ""

	If $_WD_DRIVER = "" Then
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidValue, "Location for Web Driver not set."), 0, 0)
	ElseIf Not FileExists($_WD_DRIVER) Then
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_FileIssue, "Non-existent Web Driver: " & $_WD_DRIVER), 0, 0)
	EndIf

	If $_WD_DRIVER_CLOSE Then __WD_CloseDriver()

	; Attempt to determine the availability of designated port
	; so that this information can be shown in the logs
	$sFunction = "_WD_GetFreePort"
	Call($sFunction, $_WD_PORT)

	Select
		Case @error = 0xDEAD And @extended = 0xBEEF
			; function not available

		Case @error = $_WD_ERROR_GeneralError
			; unable to obtain port status
			$sPortAvailable = " (Unknown)"

		Case @error = $_WD_ERROR_NotFound
			; requested port is unavailable
			$sPortAvailable = " (Unavailable)"
	EndSelect

	Local $sCommand = StringFormat('"%s" %s ', $_WD_DRIVER, $_WD_DRIVER_PARAMS)

	$sFile = __WD_StripPath($_WD_DRIVER)
	$iPID = ProcessExists($sFile)

	If $_WD_DRIVER_DETECT And $iPID Then
		$sExistingDriver = "Existing instance of " & $sFile & " detected! (PID=" & $iPID & ")"
	Else
		$iPID = Run($sCommand, "", ($_WD_DEBUG >= $_WD_DEBUG_Info) ? @SW_SHOW : @SW_HIDE)
		If @error Or ProcessWaitClose($iPID, 1) Then $iErr = $_WD_ERROR_GeneralError
	EndIf

	If $_WD_DEBUG >= $_WD_DEBUG_Info Or ($iErr <> $_WD_ERROR_Success And $_WD_DEBUG = $_WD_DEBUG_Error) Then
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

		If _WinAPI_GetBinaryType($_WD_DRIVER) Then _
				$sDriverBitness = ((@extended = $SCS_64BIT_BINARY) ? (" (64 Bit)") : (" (32 Bit)"))

		__WD_ConsoleWrite($sFuncName & ": OS:" & @TAB & @OSVersion & " " & @OSArch & " " & @OSBuild & " " & @OSServicePack)
		__WD_ConsoleWrite($sFuncName & ": AutoIt:" & @TAB & @AutoItVersion)
		__WD_ConsoleWrite($sFuncName & ": Webdriver UDF:" & @TAB & $__WDVERSION & $sUpdate)
		__WD_ConsoleWrite($sFuncName & ": WinHTTP:" & @TAB & $sWinHttpVer)
		__WD_ConsoleWrite($sFuncName & ": Driver:" & @TAB & $_WD_DRIVER & $sDriverBitness)
		__WD_ConsoleWrite($sFuncName & ": Params:" & @TAB & $_WD_DRIVER_PARAMS)
		__WD_ConsoleWrite($sFuncName & ": Port:" & @TAB & $_WD_PORT & $sPortAvailable)
		__WD_ConsoleWrite($sFuncName & ": Command:" & @TAB & (($sExistingDriver) ? $sExistingDriver : $sCommand))
	EndIf

	Local $sMessage = ($iErr) ? ("Error launching WebDriver!") : ("")
	Return SetError(__WD_Error($sFuncName, $iErr, $sMessage), 0, $iPID)
EndFunc   ;==>_WD_Startup

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_Shutdown
; Description ...: Kill the web driver console app.
; Syntax ........: _WD_Shutdown([$vDriver = Default[,  $iDelay = Default]])
; Parameters ....: $vDriver - [optional] The name or PID of Web driver console to shutdown
;                  $iDelay  - [optional] Time (in milliseconds) to pause before beginning console shutdown
; Return values .: None
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......: _WD_Startup
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_Shutdown($vDriver = Default, $iDelay = Default)
	If $iDelay = Default Then $iDelay = 2000
	If IsInt($iDelay) And $iDelay > 0 Then __WD_Sleep($iDelay)

	; Not checking @error here because we aren't concerned
	; with user abort during execution of shutdown

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
;                  - $_WD_ERROR_SendRecv
;                  - $_WD_ERROR_SocketError
;                  - $_WD_ERROR_Timeout
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......:
; Related .......: _WD_LastHTTPResult
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WD_Get($sURL)
	Local Const $sFuncName = "__WD_Get"
	Local $iResult = $_WD_ERROR_Success, $sResponseText, $iErr
	$_WD_HTTPRESULT = 0
	$_WD_HTTPRESPONSE = ''

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
					$iResult = $_WD_ERROR_InvalidValue
			EndSwitch

			If $iResult = $_WD_ERROR_Success Then
				$iErr = @error
				$_WD_HTTPRESULT = @extended
				$_WD_HTTPRESPONSE = $sResponseText

				If $iErr Then
					$iResult = $_WD_ERROR_SendRecv
					$sResponseText = $_WD_WinHTTPTimeoutMsg
				Else
					__WD_DetectError($iErr, $sResponseText)
					$iResult = $iErr
				EndIf
			EndIf
		EndIf

		_WinHttpCloseHandle($hConnect)
		_WinHttpCloseHandle($hOpen)
	Else
		$iResult = $_WD_ERROR_InvalidValue
	EndIf

	Local $sMessage = __WD_MessageCreator($sFuncName, $sURL, $sResponseText)
	Return SetError(__WD_Error($sFuncName, $iResult, $sMessage), 0, $sResponseText)
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
;                  - $_WD_ERROR_InvalidValue
;                  - $_WD_ERROR_SendRecv
;                  - $_WD_ERROR_SocketError
;                  - $_WD_ERROR_Timeout
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......:
; Related .......: _WD_LastHTTPResult
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WD_Post($sURL, $sData)
	Local Const $sFuncName = "__WD_Post"
	Local $iResult = $_WD_ERROR_Success, $sResponseText, $iErr
	$_WD_HTTPRESULT = 0
	$_WD_HTTPRESPONSE = ''

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
					$iResult = $_WD_ERROR_InvalidValue
			EndSwitch

			If $iResult = $_WD_ERROR_Success Then
				$iErr = @error
				$_WD_HTTPRESULT = @extended
				$_WD_HTTPRESPONSE = $sResponseText

				If $iErr Then
					$iResult = $_WD_ERROR_SendRecv
					$sResponseText = $_WD_WinHTTPTimeoutMsg
				Else
					__WD_DetectError($iErr, $sResponseText)
					$iResult = $iErr
				EndIf
			EndIf
		EndIf

		_WinHttpCloseHandle($hConnect)
		_WinHttpCloseHandle($hOpen)
	EndIf

	Local $sMessage = __WD_MessageCreator($sFuncName, $sURL, $sResponseText, $sData)
	Return SetError(__WD_Error($sFuncName, $iResult, $sMessage), 0, $sResponseText)
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
;                  - $_WD_ERROR_SendRecv
;                  - $_WD_ERROR_SocketError
;                  - $_WD_ERROR_Timeout
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......:
; Related .......: _WD_LastHTTPResult
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WD_Delete($sURL)
	Local Const $sFuncName = "__WD_Delete"
	Local $iResult = $_WD_ERROR_Success, $sResponseText, $iErr
	$_WD_HTTPRESULT = 0
	$_WD_HTTPRESPONSE = ''

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
					$iResult = $_WD_ERROR_InvalidValue
			EndSwitch

			If $iResult = $_WD_ERROR_Success Then
				$iErr = @error
				$_WD_HTTPRESULT = @extended
				$_WD_HTTPRESPONSE = $sResponseText

				If $iErr Then
					$iResult = $_WD_ERROR_SendRecv
					$sResponseText = $_WD_WinHTTPTimeoutMsg
				Else
					__WD_DetectError($iErr, $sResponseText)
					$iResult = $iErr
				EndIf
			EndIf
		EndIf

		_WinHttpCloseHandle($hConnect)
		_WinHttpCloseHandle($hOpen)
	EndIf

	Local $sMessage = __WD_MessageCreator($sFuncName, $sURL, $sResponseText)
	Return SetError(__WD_Error($sFuncName, $iResult, $sMessage), 0, $sResponseText)
EndFunc   ;==>__WD_Delete

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_MessageCreator
; Description ...: Creates message for _WD_Post, _WD_Get, _WD_Delete
; Syntax ........: __WD_MessageCreator($sFuncName, $sURL, ByRef Const $sResponseText)
; Parameters ....: $sFuncName           - Calling function name.
;                  $sURL                - used URL
;                  $sResponseText       - Reference to ResposneText
; Return values .: $sMessage
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WD_Post, _WD_Get, _WD_Delete
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WD_MessageCreator($sFuncName, $sURL, ByRef Const $sResponseText, $sData = '')
	Local $sMessage = "HTTP status = " & $_WD_HTTPRESULT
	Switch $_WD_DEBUG
		Case $_WD_DEBUG_Full ; in case of $_WD_DEBUG_Full  >  Full $sResponseText
			__WD_ConsoleWrite($sFuncName & ": URL=" & $sURL & (($sData) ? ("; Data=" & $sData) : ("")))
			If $_WD_RESPONSE_TRIM <> -1 And StringLen($sResponseText) > $_WD_RESPONSE_TRIM Then
				$sMessage &= " ResponseText=" & StringLeft($sResponseText, $_WD_RESPONSE_TRIM) & "..."
			Else
				$sMessage &= " ResponseText=" & $sResponseText
			EndIf
	EndSwitch
	Return $sMessage
EndFunc   ;==>__WD_MessageCreator

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_Error
; Description ...: Outputs error details to the configured destination(s)
; Syntax ........: __WD_Error($sWhere, $iErr[, $sMessage = Default[, $iExt = Default]])
; Parameters ....: $sWhere     - Name of calling routine
;                  $iErr       - The error number from the calling function
;                  $sMessage   - [optional] Message that will be passed to the console/output
;                  $iExt       - [optional] Extended information from the calling function
; Return values..: Success - $iErr
; Author ........: Stilgar, Danp2
; Modified ......: mLipok
; Remarks .......: If user cancels via MsgBox dialog, then  $iErr is changed to $_WD_ERROR_UserAbort
; Related .......: __WD_ConsoleWrite
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WD_Error($sWhere, $iErr, $sMessage = Default, $iExt = Default)
	Local Const $sFuncName = "__WD_Error"
	Local $sMsg

	If $sMessage = Default Then $sMessage = ''

	Switch $_WD_DEBUG
		Case $_WD_DEBUG_None

		Case $_WD_DEBUG_Error
			If $iErr <> $_WD_ERROR_Success Then ContinueCase

		Case $_WD_DEBUG_Info, $_WD_DEBUG_Full
			Local $sExtended = ($iExt <> Default) ? (" / " & $iExt) : ("")
			$sMsg = $sWhere & " ==> " & $aWD_ERROR_DESC[$iErr] & " [" & $iErr & $sExtended & "]"
			$sMsg &= ($sMessage) ? (" : " & $sMessage) : ("")
			__WD_ConsoleWrite($sMsg)

			If $iErr <> $_WD_ERROR_Success Then
				If $_WD_ERROR_MSGBOX Then
					Local $iAnswer = MsgBox($MB_ICONERROR + $MB_OKCANCEL + $MB_TOPMOST, "WebDriver UDF Error:", $sMsg)
					If $iAnswer = $IDCANCEL Then
						$iErr = $_WD_ERROR_UserAbort ; change $iErr to give a way to stop further processing by user interaction
						__WD_ConsoleWrite($sFuncName & ": User Abort", $_WD_DEBUG_Info)
					EndIf
				EndIf
				If $_WD_ERROR_OUTPUTDEBUG Then
					DllCall("kernel32.dll", "none", "OutputDebugString", "str", $sMsg)
				EndIf
			EndIf

	EndSwitch

	Return $iErr
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
; Syntax ........: __WD_EscapeString($sData[, $iOption = 0])
; Parameters ....: $sData   - the string to be escaped
;                  $iOption - [optional] Any combination of $JSON_* constants. Default is 0.
; Return values..: Success - Escaped string
;                  Failure - Response from JSON UDF and sets @error to $_WD_ERROR_GeneralError
; Author ........: Danp2
; Modified ......:
; Remarks .......:  See $JSON_* constants in json.au3 for the possible $iOption combinations.
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WD_EscapeString($sData, $iOption = 0)
	Local $iErr = $_WD_ERROR_Success
	$sData = Json_StringEncode($sData, $iOption) ; Escape JSON Strings

	If @error Then $iErr = $_WD_ERROR_GeneralError
	Return SetError($iErr, 0, $sData)
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
; Syntax ........: __WD_DetectError(ByRef $iErr, $vResult)
; Parameters ....: $iErr    - [in/out] Error code
;                  $vResult - Result from webdriver
; Return values .: None
; Author ........: Danp2
; Modified ......: mLipok
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

			Case $_WD_ErrorSessionNotCreated
				$iErr = $_WD_ERROR_SessionNotCreated

			Case $_WD_ErrorInvalidSession
				$iErr = $_WD_ERROR_SessionInvalid

			Case $_WD_ErrorUnknownCommand
				$iErr = $_WD_ERROR_UnknownCommand

			Case $_WD_ErrorTimeout
				$iErr = $_WD_ERROR_Timeout

			Case $_WD_ErrorElementNotFound, $_WD_ErrorElementStale, $_WD_ErrorShadowRootNotFound, $_WD_ErrorFrameNotFound
				$iErr = $_WD_ERROR_NoMatch

			Case $_WD_ErrorElementInvalid
				$iErr = $_WD_ERROR_InvalidArgue

			Case $_WD_ErrorElementIntercept, $_WD_ErrorElementNotInteract
				$iErr = $_WD_ERROR_ElementIssue

			Case $_WD_ErrorNoSuchAlert
				$iErr = $_WD_ERROR_NoAlert

			Case $_WD_ErrorJavascript
				If StringInStr($vResult.item('message'), 'expression') Then
					$iErr = $_WD_ERROR_InvalidExpression
				Else
					$iErr = $_WD_ERROR_Javascript
				EndIf

			Case $_WD_ErrorInvalidSelector
				$iErr = $_WD_ERROR_InvalidExpression

			Case $_WD_ErrorWindowNotFound
				$iErr = $_WD_ERROR_ContextInvalid

			Case Else
				$iErr = $_WD_ERROR_Exception

		EndSwitch
	EndIf
EndFunc   ;==>__WD_DetectError

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_StripPath
; Description ...: Remove path from supplied filename
; Syntax ........: __WD_StripPath($sFilePath)
; Parameters ....: $sFilePath                - Full path to target file
; Return values .: File name without path
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WD_StripPath($sFilePath)
	Return StringRegExpReplace($sFilePath, "^.*\\(.*)$", "$1")
EndFunc   ;==>__WD_StripPath

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_ConsoleWrite
; Description ...: Internal logging routine
; Syntax ........: __WD_ConsoleWrite($sMsg[,  $iDebugLevel = Default[,  $iError = @error[,  $iExtended = @extended]]])
; Parameters ....: $sMsg                - Message to write to log
;                  $iDebugLevel         - [optional] Minimum debug level for logging
;                  $iError              - [optional] Defaults to @error
;                  $iExtended           - [optional] Defaults to @extended
; Return values .: None
; Author ........: Danp2
; Modified ......:
; Remarks .......: The value of @error and @extended is preserved via the $iError and $iExended parameters. Therefore, the
;                  calling routine should *not* supply a value for these parameters.
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WD_ConsoleWrite($sMsg, $iDebugLevel = Default, $iError = @error, $iExtended = @extended)
	If $iDebugLevel = Default Or $_WD_DEBUG >= $iDebugLevel Then
		If IsFunc($_WD_CONSOLE) Then
			Call($_WD_CONSOLE, $sMsg & $_WD_CONSOLE_Suffix)
		ElseIf $_WD_CONSOLE = Null Then
			; do nothing
		Else
			FileWrite($_WD_CONSOLE, $sMsg & $_WD_CONSOLE_Suffix)
		EndIf
	EndIf
	Return SetError($iError, $iExtended)
EndFunc   ;==>__WD_ConsoleWrite

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_LastHTTPResult
; Description ...: Return the result of the last WinHTTP request.
; Syntax ........: _WD_LastHTTPResult()
; Parameters ....: None
; Return values .: Result of last WinHTTP request
; Author ........: Danp2
; Modified ......:
; Remarks .......: This is the HTTP result from the webdriver, which is different than the browser's HTTP status
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_LastHTTPResult()
	Return $_WD_HTTPRESULT
EndFunc   ;==>_WD_LastHTTPResult

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_LastHTTPResponse
; Description ...: Return the response of the last WinHTTP request.
; Syntax ........: _WD_LastHTTPResponse()
; Parameters ....: None
; Return values .: Response of last WinHTTP request
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_LastHTTPResponse()
	Return $_WD_HTTPRESPONSE
EndFunc   ;==>_WD_LastHTTPResponse

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

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_JsonHandle
; Description ...: Converts a handle into JSON string as needed
; Syntax ........: __WD_JsonHandle($sHandle)
; Parameters ....: $sHandle - Element ID from _WD_Window
; Return values .: Formatted JSON string
; Author ........: Seadoggie
; Modified ......:
; Remarks .......:
; Related .......: __WD_JsonElement
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WD_JsonHandle($sHandle)
	Return (StringLeft($sHandle, 1) <> '{') ? ('{"handle":"' & $sHandle & '"}') : ($sHandle)
EndFunc   ;==>__WD_JsonHandle
