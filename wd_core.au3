#Include-once
#include <array.au3>
#include <JSON.au3> ; https://www.autoitscript.com/forum/topic/148114-a-non-strict-json-udf-jsmn
#include <WinHttp.au3> ; https://www.autoitscript.com/forum/topic/84133-winhttp-functions/

#Region Description
; ==============================================================================
; UDF ...........: WD_Core.au3
; Description ...: A UDF for Web Driver automation
; Requirement ...: JSON UDF
;                  https://www.autoitscript.com/forum/topic/148114-a-non-strict-json-udf-jsmn
;
;                  WebDriver for desired browser
;                  Chrome WebDriver https://sites.google.com/a/chromium.org/chromedriver/downloads
;                  FireFox WebDriver https://github.com/mozilla/geckodriver/releases
;
; Author(s) .....: Dan Pollak
; AutoIt Version : v3.3.14.2
; ==============================================================================
#cs
	V0.1.0.5
	- Changed: Switched to using _WinHttp functions

	V0.1.0.4
	- Changed: Renamed core UDF functions
	- Changed: _WD_FindElement now returns multiple elements as an array instead of raw JSON

	V0.1.0.3
	- Fixed: Error constants
	- Changed: Renamed UDF files
	- Changed: Expanded _WDAlert functionality
	- Changed: Check for timeout in __WD_Post
	- Changed: Support parameters in _WDExecuteScript
	- Added: _WD_Attach function

	V0.1.0.2
	- Fixed: _WDWindow
	- Changed: Error constants (mLipok)
	- Added: Links to W3C documentation
	- Added: _WD_NewTab function

	V0.1.0.1
	- Initial release
#ce
#EndRegion Description

#Region Copyright
#cs
 	* WD_Core.au3
	*
	* MIT License
	*
	* Copyright (c) 2018 Dan Pollak
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
#ce
#EndRegion Many thanks to:


#Region Global Constants
Global Const $__WDVERSION = "0.1.0.5"

Global Const $_WD_LOCATOR_ByID 					= "id"
Global Const $_WD_LOCATOR_ByName 				= "name"
Global Const $_WD_LOCATOR_ByClassName 			= "class name"
Global Const $_WD_LOCATOR_ByCSSSelector 		= "css selector"
Global Const $_WD_LOCATOR_ByXPath 				= "xpath"
Global Const $_WD_LOCATOR_ByLinkText			= "link text"
Global Const $_WD_LOCATOR_ByPartialLinkText		= "partial link text"
Global Const $_WD_LOCATOR_ByTagName				= "tag name"

Global Const $_WD_DefaultTimeout				= 300000 ; 5 Minutes

Global Enum _
        $_WD_ERROR_Success = 0, _        ; No error
        $_WD_ERROR_GeneralError, _       ; General error
        $_WD_ERROR_SocketError, _        ; No socket
        $_WD_ERROR_InvalidDataType, _    ; Invalid data type (IP, URL, Port ...)
        $_WD_ERROR_InvalidValue, _       ; Invalid value in function-call
        $_WD_ERROR_SendRecv, _           ; Send / Recv Error
        $_WD_ERROR_Timeout, _            ; Connection / Send / Recv timeout
        $_WD_ERROR_NoMatch, _            ; No match for _WDAction-find/search _WDGetElement...
        $_WD_ERROR_RetValue, _           ; Error echo from Repl e.g. _WDAction("fullscreen","true") <> "true"
        $_WD_ERROR_Exception, _          ; Exception from web driver
        $_WD_ERROR_InvalidExpression, _  ; Invalid expression in XPath query or RegEx
        $_WD_ERROR_COUTNER ;

Global Const $aWD_ERROR_DESC[$_WD_ERROR_COUTNER] = [ _
        "Success", _
        "General Error", _
        "Socket Error", _
        "Invalid data type", _
        "Invalid value", _
        "Send / Recv error", _
        "Timeout", _
        "No match", _
        "Error return value", _
        "Webdriver Exception", _
        "Invalid Expression" _
        ]
#EndRegion Global Constants


#Region Global Variables
Global $_WD_DRIVER = "" 		; Path to web driver executable
Global $_WD_DRIVER_PARAMS = "" 	; Parameters to pass to web driver executable
Global $_WD_BASE_URL = "HTTP://127.0.0.1"
Global $_WD_PORT = 0 			; Port used for web driver communication
Global $_WD_OHTTP = ObjCreate("winhttp.winhttprequest.5.1")
Global $_WD_HTTPRESULT			; Result of last WinHTTP request

Global $_WD_ERROR_MSGBOX = True ; Shows in compiled scripts error messages in msgboxes
Global $_WD_DEBUG = True 		; Trace to console and show web driver app

#EndRegion Global Variables

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_CreateSession
; Description ...: Request new session from web driver
; Syntax ........: _WD_CreateSession([$sDesiredCapabilities = '{}'])
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
; Link ..........: https://w3c.github.io/webdriver/webdriver-spec.html#new-session
; Example .......: No
; ===============================================================================================================================
Func _WD_CreateSession($sDesiredCapabilities='{}')
	Local Const $sFuncName = "_WD_CreateSession"
	Local $sSession = ""

	Local $sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session", $sDesiredCapabilities)
	Local $iErr = @error

	If $_WD_DEBUG Then
		ConsoleWrite($sFuncName & ': ' & $sResponse & @CRLF)
	EndIf

	If $iErr = $_WD_ERROR_Success Then
		Local $sJSON = Json_Decode($sResponse)
		$sSession = Json_Get($sJSON, "[value][sessionId]")

		If @error Then
			Local $sMessage = Json_Get($sJSON, "[value][message]")

			SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception, $sMessage))
		EndIf
	Else
		SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception, "HTTP status = " & $_WD_HTTPRESULT), $_WD_HTTPRESULT)
	EndIf

	Return $sSession
EndFunc   ;==>_WDCreateSession


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
; Link ..........: https://w3c.github.io/webdriver/webdriver-spec.html#delete-session
; Example .......: No
; ===============================================================================================================================
Func _WD_DeleteSession($sSession)
	Local Const $sFuncName = "_WD_DeleteSession"

	Local $sResponse = __WD_Delete($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession)
	Local $iErr = @error

	If $_WD_DEBUG Then
		ConsoleWrite($sFuncName & ': ' & $sResponse & @CRLF)
	EndIf

	If $iErr Then
		SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception, "HTTP status = " & $_WD_HTTPRESULT), $_WD_HTTPRESULT)
		Return 0
	EndIf

	Return 1
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_Status
; Description ...: Get current web driver state
; Syntax ........: _WD_Status()
; Parameters ....:
; Return values .: Success      - Raw JSON response from web driver
;                  Failure      - 0
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_Exception
;                  @EXTENDED    - WinHTTP status code
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........: https://w3c.github.io/webdriver/webdriver-spec.html#status
; Example .......: No
; ===============================================================================================================================
Func _WD_Status()
	Local Const $sFuncName = "_WD_Status"
	Local $sResponse = __WD_Get($_WD_BASE_URL & ":" & $_WD_PORT & "/status")
	Local $iErr = @error

	If $_WD_DEBUG Then
		ConsoleWrite($sFuncName & ': ' & $sResponse & @CRLF)
	EndIf

	If $iErr Then
		SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception, "HTTP status = " & $_WD_HTTPRESULT), $_WD_HTTPRESULT)
		Return 0
	EndIf

	Return $sResponse
EndFunc   ;==>_WD_Status


; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_Timeouts
; Description ...:  Set or retrieve the session timeout parameters
; Syntax ........: _WD_Timeouts($sSession[, $sTimeouts = ''])
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
; Link ..........: https://w3c.github.io/webdriver/webdriver-spec.html#get-timeouts
;                  https://w3c.github.io/webdriver/webdriver-spec.html#set-timeouts
; Example .......: No
; ===============================================================================================================================
Func _WD_Timeouts($sSession, $sTimeouts = '')
	Local Const $sFuncName = "_WD_Timeouts"
	Local $sResponse, $sURL

	$sURL = $_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/timeouts"

	If $sTimeouts = '' Then
		$sResponse = __WD_Get($sURL)
	Else
		$sResponse = __WD_Post($sURL, $sTimeouts)
	EndIf

	Local $iErr = @error

	If $_WD_DEBUG Then
		ConsoleWrite($sFuncName & ': ' & $sResponse & @CRLF)
	EndIf

	If $iErr Then
		SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception, "HTTP status = " & $_WD_HTTPRESULT), $_WD_HTTPRESULT)
		Return 0
	EndIf

	Return $sResponse
EndFunc


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
;                  @EXTENDED    - WinHTTP status code
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........: https://w3c.github.io/webdriver/webdriver-spec.html#navigate-to
; Example .......: No
; ===============================================================================================================================
Func _WD_Navigate($sSession, $sURL)
	Local Const $sFuncName = "_WD_Navigate"
	Local $sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/url", '{"url":"' & $sURL & '"}')

	Local $iErr = @error

	If $_WD_DEBUG Then
		ConsoleWrite($sFuncName & ': ' & $sResponse & @CRLF)
	EndIf

	If $iErr Then
		SetError(__WD_Error($sFuncName, $iErr, "HTTP status = " & $_WD_HTTPRESULT), $_WD_HTTPRESULT)
		Return 0
	EndIf

	Return 1
EndFunc   ;==>_WDNavigate


; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_Action
; Description ...: Perform various interactions with the web driver session
; Syntax ........: _WD_Action($sSession, $sCommand)
; Parameters ....: $sSession            - Session ID from _WDCreateSession
;                  $sCommand            - one of the following actions:
;                               | refresh
;                               | back
;                               | forward
;                               | url
;                               | title
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
; Link ..........: https://w3c.github.io/webdriver/webdriver-spec.html#navigation
; Example .......: No
; ===============================================================================================================================
Func _WD_Action($sSession, $sCommand)
	Local Const $sFuncName = "_WD_Action"
	Local $sResponse, $sResult = "", $iErr, $sJSON

	$sCommand = StringLower($sCommand)

	Switch $sCommand
		Case 'back', 'forward', 'refresh'
			$sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/" & $sCommand, '{}')
			$iErr = @error

		Case 'url', 'title'
			$sResponse = __WD_Get($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/" & $sCommand)
			$iErr = @error

			If $iErr = $_WD_ERROR_Success Then
				$sJSON = Json_Decode($sResponse)
				$sResult = Json_Get($sJSON, "[value]")
			EndIf

		case Else
			SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(Back|Forward|Refresh|Url|Title) $sCommand=>" & $sCommand))
			Return ""

	EndSwitch

	If $_WD_DEBUG Then
		ConsoleWrite($sFuncName & ': ' & $sResponse & @CRLF)
	EndIf

	If $iErr Then
		SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception, "HTTP status = " & $_WD_HTTPRESULT), $_WD_HTTPRESULT)
	EndIf

	Return $sResult
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_Window
; Description ...:
; Syntax ........: _WD_Window($sSession, $sCommand, $sOption)
; Parameters ....: $sSession            - Session ID from _WDCreateSession
;                  $sCommand            - one of the following actions:
;                               | Window
;                               | Handles
;                               | Maximize
;                               | Minimize
;                               | Fullscreen
;                  $sOption             - a string value.
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
; Link ..........: https://w3c.github.io/webdriver/webdriver-spec.html#command-contexts
; Example .......: No
; ===============================================================================================================================
Func _WD_Window($sSession, $sCommand, $sOption = '')
	Local Const $sFuncName = "_WD_Window"
	Local $sResponse, $sJSON, $sResult = ""

	$sCommand = StringLower($sCommand)

	Switch $sCommand
		Case 'window'
			$sResponse = __WD_Get($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/" & $sCommand)
			$iErr = @error

			If $iErr = $_WD_ERROR_Success Then
				$sJSON = Json_Decode($sResponse)
				$sResult = Json_Get($sJSON, "[value]")
			EndIf

		Case 'handles'
			$sResponse = __WD_Get($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/window/" & $sCommand)
			$iErr = @error

			If $iErr = $_WD_ERROR_Success Then
				$sJSON = Json_Decode($sResponse)
				$sResult = Json_Get($sJSON, "[value]")
			EndIf

		Case 'maximize', 'minimize', 'fullscreen', 'normal', 'screenshot'
			$sResponse = __WD_Get($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/" & $sCommand)
			$iErr = @error

			If $iErr = $_WD_ERROR_Success Then
				$sResult = $sResponse
			EndIf

		Case 'close'
			$sResponse = __WD_Delete($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/window")
			$iErr = @error

			If $iErr = $_WD_ERROR_Success Then
				$sResult = $sResponse
			EndIf

		Case 'switch'
			$sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/window", $sOption)
			$iErr = @error

			If $iErr = $_WD_ERROR_Success Then
				$sResult = $sResponse
			EndIf

		Case 'frame'
			$sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/frame", $sOption)

			If $iErr = $_WD_ERROR_Success Then
				$sResult = $sResponse
			EndIf

		Case 'parent'
			$sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/frame/parent", $sOption)

			If $iErr = $_WD_ERROR_Success Then
				$sResult = $sResponse
			EndIf

		case Else
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(Window|Handles|Maximize|Minimize|Fullscreen) $sCommand=>" & $sCommand), 0, "")

	EndSwitch

	If $_WD_DEBUG Then
		ConsoleWrite($sFuncName & ': ' & $sResponse & @CRLF)
	EndIf

	If $iErr Then
		SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception, "HTTP status = " & $_WD_HTTPRESULT), $_WD_HTTPRESULT)
	EndIf

	Return $sResult
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_FindElement
; Description ...: Find element(s) by designated strategy
; Syntax ........: _WD_FindElement($sSession, $sStrategy, $sSelector[, $sStartElement = ""[, $lMultiple = False]])
; Parameters ....: $sSession            - Session ID from _WDCreateSession
;                  $sStrategy           - Locator strategy. See defined constant $_WD_LOCATOR_* for allowed values
;                  $sSelector           - Value to find
;                  $sStartElement       - [optional] a string value. Default is "".
;                  $lMultiple           - [optional] an unknown value. Default is False.
; Return values .: Success      - Element ID(s) returned by web driver
;                  Failure      - ""
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_Exception
;                  				- $_WD_ERROR_NoMatch
;                  @EXTENDED    - WinHTTP status code
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........: https://w3c.github.io/webdriver/webdriver-spec.html#element-retrieval
; Example .......: No
; ===============================================================================================================================
Func _WD_FindElement($sSession, $sStrategy, $sSelector, $sStartElement = "", $lMultiple = False)
	Local Const $sFuncName = "_WD_FindElement"
	Local $sCmd, $sElement, $sResponse, $sResult, $iErr, $Obj2, $sErr
	Local $oJson, $oValues, $sKey, $iRow, $aElements[0]

	$sCmd = ($lMultiple) ? 'elements' : 'element'
	$sElement = ($sStartElement == "") ? "" : "/element/" & $sStartElement

	$sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & $sElement & "/" & $sCmd, '{"using":"' & $sStrategy & '","value":"' & $sSelector & '"}')
	$iErr = @error

	If $iErr = $_WD_ERROR_Success And $_WD_HTTPRESULT = $HTTP_STATUS_OK Then
		If $lMultiple Then

			$oJson = Json_Decode($sResponse)
			$oValues = Json_Get($oJson, '[value]')
			$sKey = "[" & Json_ObjGetKeys($oValues[0])[0] & "]"

			Dim $aElements[UBound($oValues)]

			For $oValue In $oValues
				$aElements[$iRow] = Json_Get($oValue, $sKey)
				$iRow += 1
			Next
		Else
			$oJson = Json_Decode($sResponse)
			$Obj2 = Json_Get($oJson, "[value]")
			$sKey = Json_ObjGetKeys($Obj2)[0]

			$sResult = Json_Get($oJson, "[value][" & $sKey & "]")
		EndIf
	EndIf

	If $_WD_DEBUG Then
		ConsoleWrite($sFuncName & ': ' & $sResponse & @CRLF)
	EndIf

	If $_WD_HTTPRESULT = $HTTP_STATUS_NOT_FOUND Then
		$oJson = Json_Decode($sResponse)
		$sErr = Json_Get($oJson, "[value][error]")

		SetError(__WD_Error($sFuncName, $_WD_ERROR_NoMatch, $sErr), $_WD_HTTPRESULT)

	ElseIf $iErr Then
		SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception, "HTTP status = " & $_WD_HTTPRESULT), $_WD_HTTPRESULT)
	EndIf

	Return ($lMultiple) ? $aElements : $sResult
EndFunc   ;==>_WDFindElement


; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_ElementAction
; Description ...: Perform action on desginated element
; Syntax ........: _WD_ElementAction($sSession, $sElement, $sCommand[, $sOption = ''])
; Parameters ....: $sSession            - Session ID from _WDCreateSession
;                  $sElement            - Element ID from _WDFindElement
;                  $sCommand            - Action to be performed
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
; Link ..........: https://w3c.github.io/webdriver/webdriver-spec.html#element-state
;                  https://w3c.github.io/webdriver/webdriver-spec.html#element-interaction
; Example .......: No
; ===============================================================================================================================
Func _WD_ElementAction($sSession, $sElement, $sCommand, $sOption='')
	Local Const $sFuncName = "_WD_ElementAction"
	Local $sResponse, $sResult = '', $iErr

	$sCommand = StringLower($sCommand)

	Switch $sCommand
		Case 'name', 'rect', 'text', 'selected', 'enabled'
			$sResponse = __WD_Get($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/element/" & $sElement & "/" & $sCommand)
			$iErr = @error

			If $iErr = $_WD_ERROR_Success Then
				$oJson = Json_Decode($sResponse)
				$sResult = Json_Get($oJson, "[value]")
			EndIf

		Case 'active'
			$sResponse = __WD_Get($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/element/" & $sCommand)
			$iErr = @error

			If $iErr = $_WD_ERROR_Success Then
				$oJson = Json_Decode($sResponse)
				$sResult = Json_Get($oJson, "[value]")
			EndIf

		Case 'attribute', 'property', 'css'
			$sResponse = __WD_Get($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/element/" & $sElement & "/" & $sCommand & "/" & $sOption)
			$iErr = @error

			If $iErr = $_WD_ERROR_Success Then
				$oJson = Json_Decode($sResponse)
				$sResult = Json_Get($oJson, "[value]")
			EndIf

		Case 'clear', 'click'
			$sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession &  "/element/" & $sElement & "/" & $sCommand, '{"id":"' & $sElement & '"}')
			$iErr = @error

			If $iErr = $_WD_ERROR_Success Then
				$sResult = $sResponse
			EndIf

		Case 'value'
			Local $sSplitValue = "[" & StringTrimRight(StringRegExpReplace($sOption, '.', '"$0",'), 1) & "]"

			$sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/element/" & $sElement & "/" & $sCommand, '{"id":"' & $sElement & '", "text":"' & $sOption & '", "value":' & $sSplitValue &'}')
			$iErr = @error

			If $iErr = $_WD_ERROR_Success Then
				$sResult = $sResponse
			EndIf

		case Else
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(Name|Rect|Text|Selected|Enabled|Active|Attribute|Property|CSS|Clear|Click|Value) $sCommand=>" & $sCommand), 0, "")

	EndSwitch

	If $_WD_DEBUG Then
		ConsoleWrite($sFuncName & ': ' & $sResponse & @CRLF)
	EndIf

	If $iErr Then
		SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception, $sResponse), $_WD_HTTPRESULT)
	EndIf

	Return $sResult
EndFunc   ;==>_WD_ElementAction


; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_ExecuteScript
; Description ...: Execute Javascipt commands
; Syntax ........: _WD_ExecuteScript($sSession, $sScript, $aArguments)
; Parameters ....: $sSession            - Session ID from _WDCreateSession
;                  $sScript             - Javascript command(s) to run
;                  $aArguments          - String of arguments in JSON format
; Return values .: None
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........: https://w3c.github.io/webdriver/webdriver-spec.html#executing-script
; Example .......: No
; ===============================================================================================================================
Func _WD_ExecuteScript($sSession, $sScript, $sArguments="[]")
	Local Const $sFuncName = "_WD_ExecuteScript"
	Local $sResponse, $sData

	$sData = '{"script":"' & $sScript & '", "args":[' & $sArguments & ']}'

	$sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession &  "/execute/sync", $sData)

	If $_WD_DEBUG Then
		ConsoleWrite($sFuncName & ': ' & $sResponse & @CRLF)
	EndIf

	Return $sResponse
EndFunc   ;==>_WD_ExecuteScript


; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_Alert
; Description ...: Respond to user prompt
; Syntax ........: _WD_Alert($sSession, $sCommand)
; Parameters ....: $sSession            - Session ID from _WDCreateSession
;                  $sCommand            - one of the following actions:
;                               | dismiss
;                               | accept
;                               | gettext
;                               | sendtext
;                               | status
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
; Link ..........: https://w3c.github.io/webdriver/webdriver-spec.html#user-prompts
; Example .......: No
; ===============================================================================================================================
Func _WD_Alert($sSession, $sCommand, $sOption = '')
	Local Const $sFuncName = "_WD_Alert"
	Local $sResponse, $iErr, $sJSON, $sResult = ''

	$sCommand = StringLower($sCommand)

	Switch $sCommand
		Case 'dismiss', 'accept'
			$sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession &  "/alert/" & $sCommand, '{}')
			$iErr = @error

		Case 'gettext'
			$sResponse = __WD_Get($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession &  "/alert/text")
			$iErr = @error

			If $iErr = $_WD_ERROR_Success Then
				$sJSON = Json_Decode($sResponse)
				$sResult = Json_Get($sJSON, "[value]")
			EndIf

		Case 'sendtext'
			$sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession &  "/alert/text", '{"text":"' & $sOption & '"}')
			$iErr = @error

		Case 'status'
			$sResponse = __WD_Get($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession &  "/alert/text")
			$iErr = @error

			If $iErr = $_WD_ERROR_Success Then
				$sResult = ($_WD_HTTPRESULT = $HTTP_STATUS_NOT_FOUND) ? False : True
			EndIf

		Case Else
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(Dismiss|Accept|GetText|SendText|Status) $sCommand=>" & $sCommand), 0, "")
	EndSwitch

	If $_WD_DEBUG Then
		ConsoleWrite($sFuncName & ': ' & $sResponse & @CRLF)
	EndIf

	If $iErr Then
		SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception, $sResponse), $_WD_HTTPRESULT)
	EndIf

	Return $sResult
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
; Link ..........: https://w3c.github.io/webdriver/webdriver-spec.html#getting-page-source
; Example .......: No
; ===============================================================================================================================
Func _WD_GetSource($sSession)
	Local Const $sFuncName = "_WD_GetSource"
	Local $sResponse, $iErr, $sResult = "", $sJSON

	$sResponse = __WD_Get($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/source")
	$iErr = @error

	If $iErr = $_WD_ERROR_Success Then
		$sJSON = Json_Decode($sResponse)
		$sResult = Json_Get($sJSON, "[value]")
	EndIf

	If $_WD_DEBUG Then
		ConsoleWrite($sFuncName & ': ' & $sResponse & @CRLF)
	EndIf

	If $iErr Then
		SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception, $sResponse), $_WD_HTTPRESULT)
	EndIf

	Return $sResult
EndFunc   ;==>_WD_GetSource

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_Cookies
; Description ...:
; Syntax ........: _WD_Cookies($sSession, $sCommand[, $sOption = ''])
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
; Link ..........: https://w3c.github.io/webdriver/webdriver-spec.html#cookies
; Example .......: No
; ===============================================================================================================================
Func _WD_Cookies($sSession,  $sCommand, $sOption = '')
	Local Const $sFuncName = "_WD_Cookies"

	Local $sResult, $sResponse, $sJSON, $iErr

	$sCommand = StringLower($sCommand)

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

		case Else
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(GetAll|Get|Add|Delete) $sCommand=>" & $sCommand), "")
	EndSwitch

	If $_WD_DEBUG Then
		ConsoleWrite($sFuncName & ': ' & $sResponse & @CRLF)
	EndIf

	If $iErr Then
		SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception, $sResponse), $_WD_HTTPRESULT)
	EndIf

	Return $sResult
EndFunc   ;==>_WD_Cookies



; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_Option
; Description ...: Sets and get options for the web driver UDF
; Syntax ........: _WD_Option($sOption[, $vValue = ""])
; Parameters ....: $sOption             - a string value.
;                  $vValue              - [optional] a variant value. Default is "".
; Parameter(s): .: $sOption     - Driver
;                               |DriverParams
;                               |BaseURL
;                               |Port
;                  $vValue      - Optional: (Default = "") : if noe value is given, the current value is returned
;                               | SearchMode 0 = SubString, 1 = Compare
;                               | LoadWaitTimeOut (int / min. 1000)
;                               | LoadWaitStop (bool) stop loading after LoadWaitTimeOut
;                               | ComTrace (bool)
;                               | ErrorMsgBox (bool)
; Return Value ..: Success      - 1 / current value
;                  Failure      - 0
;                  Failure      - ""
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_InvalidDataType
;                  @EXTENDED    - WinHTTP status code
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_Option($sOption, $vValue = "")
	Local Const $sFuncName = "_WD_Option"

	Switch $sOption
		Case "Driver"
			If $vValue == "" Then Return $_WD_DRIVER
			If Not IsString($vValue) Then
				SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(string) $vValue: " & $vValue))
				Return 0
			EndIf
			$_WD_DRIVER = $vValue
		Case "DriverParams"
			If $vValue == "" Then Return $_WD_DRIVER_PARAMS
			If Not IsString($vValue) Then
				SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(string) $vValue: " & $vValue))
				Return 0
			EndIf
			$_WD_DRIVER_PARAMS = $vValue
		Case "BaseURL"
			If $vValue == "" Then Return $_WD_BASE_URL
			If Not IsString($vValue) Then
				SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(string) $vValue: " & $vValue))
				Return 0
			EndIf
			$_WD_BASE_URL = $vValue
		Case "Port"
			If $vValue == "" Then Return $_WD_PORT
			If Not IsInt($vValue) Then
				SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(int) $vValue: " & $vValue))
				Return 0
			EndIf
			$_WD_PORT = $vValue
		Case Else
			SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(Driver|DriverParams|BaseURL|Port) $sOption=>" & $sOption))
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

	If $_WD_DRIVER = "" Then
	   SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidValue, "Location for Web Driver not set." & @CRLF))
		Return 0
	EndIf

	__WD_CloseDriver()

	Local $sCommand = $_WD_DRIVER & " " & $_WD_DRIVER_PARAMS

	Local $sCommand = StringFormat('"%s" %s ', $_WD_DRIVER, $_WD_DRIVER_PARAMS)

	Local $lShow = $_WD_DEBUG ? @SW_SHOW : @SW_HIDE

	If $_WD_DEBUG Then
		ConsoleWrite("_WDStartup: OS:" & @TAB & @OSVersion & " " & @OSTYPE & " " & @OSBuild & " " & @OSServicePack & @CRLF)
		ConsoleWrite("_WDStartup: AutoIt:" & @TAB & @AutoItVersion & @CRLF)
		ConsoleWrite("_WDStartup: WD.au3:" & @TAB & $__WDVERSION & @CRLF)
		ConsoleWrite("_WDStartup: Driver:" & @TAB & $_WD_DRIVER & @CRLF)
		ConsoleWrite("_WDStartup: Params:" & @TAB & $_WD_DRIVER_PARAMS & @CRLF)
		ConsoleWrite("_WDStartup: Port:" & @TAB & $_WD_PORT & @CRLF)
	Else
		ConsoleWrite('_WDStartup: ' & $sCommand & @CRLF)
	EndIf

	Local $pid = Run($sCommand, "",$_WD_DEBUG ? @SW_SHOW : @SW_HIDE)

	If @error Then
		SetError(__WD_Error($sFuncName, $_WD_ERROR_GeneralError, "Error launching web driver!"))
	EndIf

	Return ($pid)
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_Shutdown
; Description ...: Kill the web driver console app
; Syntax ........: _WD_Shutdown()
; Parameters ....:
; Return values .: None
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_Shutdown()
	__WD_CloseDriver()
EndFunc



; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_Get
; Description ...: Submit GET request to WD console app
; Syntax ........: __WD_Get($sURL)
; Parameters ....: $sURL        -
; Return Value ..: Success      - Response from web driver
;                  Failure      - Response from web driver and set @ERROR
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_Exception
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WD_Get($sURL)
	Local Const $sFuncName = "__WD_Get"
	Local $iResult, $sResponseText

	If $_WD_DEBUG Then
		ConsoleWrite($sFuncName & ': URL=' & $sURL & @CRLF)
	EndIf

	$_WD_HTTPRESULT = 0

	Local $aURL = _WinHttpCrackUrl($sURL)

	; Initialize and get session handle
	Local $hOpen = _WinHttpOpen()

	; Get connection handle
	Local $hConnect = _WinHttpConnect($hOpen, $aURL[2], $aURL[3])

	 If @error Then
		$iResult = $_WD_ERROR_SocketError
	 Else
		$sResponseText = _WinHttpSimpleRequest($hConnect, "GET", $aURL[6])
		$_WD_HTTPRESULT = @extended

		If @error Then
			$iResult = $_WD_ERROR_SendRecv
		EndIf
	 EndIf

	If $_WD_DEBUG Then
		ConsoleWrite($sFuncName & ': StatusCode=' & $_WD_HTTPRESULT & "; $sResponseText=" & $sResponseText & @CRLF)
	EndIf

	If $iResult Then
		If $_WD_HTTPRESULT = $HTTP_STATUS_REQUEST_TIMEOUT Then
			SetError(__WD_Error($sFuncName, $_WD_ERROR_Timeout, $sResponseText))
		Else
			SetError(__WD_Error($sFuncName, $iResult, $sResponseText))
		EndIf
	EndIf

	Return $sResponseText
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
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WD_Post($sURL, $sData)
	Local Const $sFuncName = "__WD_Post"
	Local $iResult, $sResponseText

	If $_WD_DEBUG Then
		ConsoleWrite($sFuncName & ': URL=' & $sURL & "; $sData=" & $sData & @CRLF)
	EndIf

	Local $aURL = _WinHttpCrackUrl($sURL)

	$_WD_HTTPRESULT = 0

	; Initialize and get session handle
	Local $hOpen = _WinHttpOpen()

	; Get connection handle
	Local $hConnect = _WinHttpConnect($hOpen, $aURL[2], $_WD_PORT)

	 If @error Then
		$iResult = $_WD_ERROR_SocketError
	 Else
		$sResponseText = _WinHttpSimpleRequest($hConnect, "POST", $aURL[6], -1, $sData)
		$_WD_HTTPRESULT = @extended

		If @error Then
			$iResult = (@extended = $HTTP_STATUS_REQUEST_TIMEOUT) ? $_WD_ERROR_Timeout : $_WD_ERROR_SendRecv
		EndIf
	 EndIf

	If $_WD_DEBUG Then
		ConsoleWrite($sFuncName & ': StatusCode=' & $_WD_HTTPRESULT & "; ResponseText=" & $sResponseText & @CRLF)
	EndIf

	If $iResult Then
		SetError(__WD_Error($sFuncName, $iResult, $sResponseText))
	EndIf

	Return $sResponseText
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
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WD_Delete($sURL)
	Local Const $sFuncName = "__WD_Delete"

	Local $iResult, $sResponseText

	If $_WD_DEBUG Then
		ConsoleWrite($sFuncName & ': URL=' & $sURL & @CRLF)
	EndIf

	Local $aURL = _WinHttpCrackUrl($sURL)

	$_WD_HTTPRESULT = 0

	; Initialize and get session handle
	Local $hOpen = _WinHttpOpen()

	; Get connection handle
	Local $hConnect = _WinHttpConnect($hOpen, $aURL[2], $_WD_PORT)

	 If @error Then
		$iResult = $_WD_ERROR_SocketError
	 Else
		$sResponseText = _WinHttpSimpleRequest($hConnect, "DELETE", $aURL[6])
		$_WD_HTTPRESULT = @extended

		If @error Then
			$iResult = $_WD_ERROR_SendRecv
		EndIf
	 EndIf

	If $_WD_DEBUG Then
		ConsoleWrite($sFuncName & ': StatusCode=' & $_WD_HTTPRESULT & "; ResponseText=" & $sResponseText & @CRLF)
	EndIf

	If $iResult Then
		If $_WD_HTTPRESULT = $HTTP_STATUS_REQUEST_TIMEOUT Then
			SetError(__WD_Error($sFuncName, $_WD_ERROR_Timeout, $sResponseText))
		Else
			SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception, $sResponseText))
		EndIf
	EndIf

	Return $sResponseText
EndFunc   ;==>__WD_Delete


; #INTERNAL_USE_ONLY# ==========================================================
; Name ..........: __WD_Error
; Description ...: Writes Error to the console and show message-boxes if the script is compiled
; AutoIt Version : V3.3.0.0
; Syntax ........: __WD_Error($sWhere, ByRef $i_WD_ERROR[, $sMessage = ""])
; Parameter(s): .: $i_WD_ERROR  - Error Const
;                  $sMessage    - Optional: (Default = "") : Additional Information
; Return Value ..: Success      - Error Const from $i_WD_ERROR
; Author(s) .....: Thorsten Willert
; Date ..........: Sat Jul 18 11:52:36 CEST 2009
; ==============================================================================
Func __WD_Error($sWhere, $i_WD_ERROR, $sMessage = "")
	Local $sOut, $sMsg
	Sleep(200)

	If $sMessage = "" Then
		$sMsg = $sWhere & " ==> " & $aWD_ERROR_DESC[$i_WD_ERROR] & @CRLF
		ConsoleWrite($sMsg)
		If @Compiled Then
			If $_WD_ERROR_MSGBOX And $i_WD_ERROR < 6 Then MsgBox(16, "WebDriver.au3 Error:", $sMsg)
			DllCall("kernel32.dll", "none", "OutputDebugString", "str", $sMsg)
		EndIf

	Else
		$sMsg = $sWhere & " ==> " & $aWD_ERROR_DESC[$i_WD_ERROR] & ": " & $sMessage & @CRLF
		ConsoleWrite($sMsg)
		If @Compiled Then
			If $_WD_ERROR_MSGBOX And $i_WD_ERROR < 6 Then MsgBox(16, "WebDriver.au3 Error:", $sMsg)
			DllCall("kernel32.dll", "none", "OutputDebugString", "str", $sMsg)
		EndIf
	EndIf

	Return $i_WD_ERROR
EndFunc   ;==>__WD_Error

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_CloseDriver
; Description ...: Shutdown web driver console if it exists
; Syntax ........: __WDKillDriver()
; Parameters ....:
; Return values .: None
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WD_CloseDriver()
	Local $sFile = StringRegExpReplace($_WD_DRIVER, "^.*\\(.*)$", "$1")

	If ProcessExists($sFile) Then
		ProcessClose ($sFile)
	EndIf
EndFunc
