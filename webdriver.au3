#Include-once
#include <array.au3>
#include <JSON.au3> ; https://www.autoitscript.com/forum/topic/148114-a-non-strict-json-udf-jsmn

#Region Copyright
#cs
	* WebDriver.au3
	*
	* This program is free software; you can redistribute it and/or
	* modify it under the terms of the GNU General Public License
	* as published by the Free Software Foundation; either version 2
	* of the License, or any later version.
	*
	* This program is distributed in the hope that it will be useful,
	* but WITHOUT ANY WARRANTY; without even the implied warranty of
	* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	* GNU General Public License for more details.
	*
	* You should have received a copy of the GNU General Public License
	* along with this program; if not, see <https://www.gnu.org/licenses/>.
#ce
#EndRegion Copyright

#Region Many thanks to:
#cs
	- Jonathan Bennett and the AutoIt Team
	- Thorsten Willert, author of FF.au3, which I've used as a model
#ce
#EndRegion Many thanks to:

#Region Global Constants
Global Const $__WDVERSION = "0.1.0.2"

Global Const $_WD_LOCATOR_ByID 					= "id"
Global Const $_WD_LOCATOR_ByName 				= "name"
Global Const $_WD_LOCATOR_ByClassName 			= "class name"
Global Const $_WD_LOCATOR_ByCSSSelector 		= "css selector"
Global Const $_WD_LOCATOR_ByXPath 				= "xpath"
Global Const $_WD_LOCATOR_ByLinkText			= "link text"
Global Const $_WD_LOCATOR_ByPartialLinkText		= "partial link text"
Global Const $_WD_LOCATOR_ByTagName				= "tag name"

Global Enum _
        $_WD_ERROR_Success = 0, _        ; No error
        $_WD_ERROR_GeneralError, _       ; General error
        $_WD_ERROR_SocketError, _        ; No socket
        $_WD_ERROR_InvalidDataType, _    ; Invalid data type (IP, URL, Port ...)
        $_WD_ERROR_InvalidValue, _       ; Invalid value in function-call
        $_WD_ERROR_SendRecv, _           ; Send / Recv Error
        $_WD_ERROR_Timeout, _            ; Connection / Send / Recv timeout
        $_WD_ERROR___UNUSED, _           ;
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
        "Timeout", _
        "No match", _
        "Error return value", _
        "Error TCPSend / TCPRecv", _
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
; Name ..........: _WDCreateSession
; Description ...: Request new session from web driver
; Syntax ........: _WDCreateSession([$sDesiredCapabilities = '{}'])
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
Func _WDCreateSession($sDesiredCapabilities='{}')
	Local Const $sFuncName = "_WDCreateSession"
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
; Name ..........: _WDDeleteSession
; Description ...:  Delete existing session
; Syntax ........: _WDDeleteSession($sSession)
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
Func _WDDeleteSession($sSession)
	Local Const $sFuncName = "_WDDeleteSession"

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
; Name ..........: _WDStatus
; Description ...: Get current web driver state
; Syntax ........: _WDStatus()
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
Func _WDStatus()
	Local Const $sFuncName = "_WDStatus"
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
EndFunc   ;==>_WDStatus


; #FUNCTION# ====================================================================================================================
; Name ..........: _WDTimeouts
; Description ...:  Set or retrieve the session timeout parameters
; Syntax ........: _WDTimeouts($sSession[, $sTimeouts = ''])
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
Func _WDTimeouts($sSession, $sTimeouts = '')
	Local Const $sFuncName = "_WDTimeouts"
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
; Name ..........: _WDNavigate
; Description ...: Navigate to the designated URL
; Syntax ........: _WDNavigate($sSession, $sURL)
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
Func _WDNavigate($sSession, $sURL)
	Local Const $sFuncName = "_WDNavigate"
	Local $sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/url", '{"url":"' & $sURL & '"}')

	Local $iErr = @error

	If $_WD_DEBUG Then
		ConsoleWrite($sFuncName & ': ' & $sResponse & @CRLF)
	EndIf

	If $iErr Then
		SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception, "HTTP status = " & $_WD_HTTPRESULT), $_WD_HTTPRESULT)
		Return 0
	EndIf

	Return 1
EndFunc   ;==>_WDNavigate


; #FUNCTION# ====================================================================================================================
; Name ..........: _WDAction
; Description ...: Perform various interactions with the web driver session
; Syntax ........: _WDAction($sSession, $sCommand)
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
Func _WDAction($sSession, $sCommand)
	Local Const $sFuncName = "_WDAction"
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
; Name ..........: _WDWindow
; Description ...:
; Syntax ........: _WDWindow($sSession, $sCommand, $sOption)
; Parameters ....: $sSession            - Session ID from _WDCreateSession
;                  $sCommand            - a string value.
;                  $sOption             - a string value.
; Return values .: Success      - Return value from web driver (could be an empty string)
;                  Failure      - ""
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_Exception
;                  				- $_WD_ERROR_InvalidDataType
;                  @EXTENDED    - WinHTTP status code; Return values .: None
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........: https://w3c.github.io/webdriver/webdriver-spec.html#command-contexts
; Example .......: No
; ===============================================================================================================================
Func _WDWindow($sSession, $sCommand, $sOption = '')
	Local Const $sFuncName = "_WDWindow"
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
; Name ..........: _WDFindElement
; Description ...: Find element(s) by designated strategy
; Syntax ........: _WDFindElement($sSession, $sStrategy, $sSelector[, $sStartElement = ""[, $lMultiple = False]])
; Parameters ....: $sSession            - Session ID from _WDCreateSession
;                  $sStrategy           - a string value.
;                  $sSelector           - a string value.
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
Func _WDFindElement($sSession, $sStrategy, $sSelector, $sStartElement = "", $lMultiple = False)
	Local Const $sFuncName = "_WDGetElement"
	Local $sCmd, $sElement, $sResponse, $sResult, $iErr, $Obj, $Obj2, $sKey, $sErr

	$sCmd = ($lMultiple) ? 'elements' : 'element'
	$sElement = ($sStartElement == "") ? "" : "/element/" & $sStartElement

	$sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & $sElement & "/" & $sCmd, '{"using":"' & $sStrategy & '","value":"' & $sSelector & '"}')
	$iErr = @error

	If $iErr = $_WD_ERROR_Success Then
		If $lMultiple Then
			$sResult = $sResponse
		Else
			$Obj = Json_Decode($sResponse)
			$Obj2 = Json_Get($Obj, "[value]")
			$sKey = Json_ObjGetKeys($Obj2)[0]

			$sResult = Json_Get($Obj, "[value][" & $sKey & "]")
		EndIf
	EndIf

	If $_WD_DEBUG Then
		ConsoleWrite($sFuncName & ': ' & $sResponse & @CRLF)
	EndIf

	If $iErr Then
		If $_WD_HTTPRESULT = 404 Then
			$Obj = Json_Decode($sResponse)
			$sErr = Json_Get($Obj, "[value][error]")

			SetError(__WD_Error($sFuncName, $_WD_ERROR_NoMatch, $sErr), $_WD_HTTPRESULT)
		Else
			SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception, "HTTP status = " & $_WD_HTTPRESULT), $_WD_HTTPRESULT)
		EndIf
	EndIf

	Return $sResult
EndFunc   ;==>_WDFindElement


; #FUNCTION# ====================================================================================================================
; Name ..........: _WDElementAction
; Description ...: Perform action on desginated element
; Syntax ........: _WDElementAction($sSession, $sElement, $sCommand[, $sOption = ''])
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
Func _WDElementAction($sSession, $sElement, $sCommand, $sOption='')
	Local Const $sFuncName = "_WDElementAction"
	Local $sResponse, $sResult = '', $iErr

	$sCommand = StringLower($sCommand)

	Switch $sCommand
		Case 'name', 'rect', 'text', 'selected', 'enabled'
			$sResponse = __WD_Get($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/element/" & $sElement & "/" & $sCommand)
			$iErr = @error

			If $iErr = $_WD_ERROR_Success Then
				$sResult = Json_Get($sResponse, "[value]")
			EndIf

		Case 'active'
			$sResponse = __WD_Get($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/element/" & $sCommand)
			$iErr = @error

			If $iErr = $_WD_ERROR_Success Then
				$sResult = Json_Get($sResponse, "[value]")
			EndIf

		Case 'attribute', 'property', 'css'
			$sResponse = __WD_Get($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & "/element/" & $sElement & "/" & $sCommand & "/" & $sOption)
			$iErr = @error

			If $iErr = $_WD_ERROR_Success Then
				$sResult = Json_Get($sResponse, "[value]")
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
EndFunc   ;==>_WDElementAction


; #FUNCTION# ====================================================================================================================
; Name ..........: _WDExecuteScript
; Description ...: Execute Javascipt commands
; Syntax ........: _WDExecuteScript($sSession, $sScript, $aArguments)
; Parameters ....: $sSession            - Session ID from _WDCreateSession
;                  $sScript             - a string value.
;                  $aArguments          - an array of unknowns.
; Return values .: None
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........: https://w3c.github.io/webdriver/webdriver-spec.html#executing-script
; Example .......: No
; ===============================================================================================================================
Func _WDExecuteScript($sSession, $sScript, $aArguments)
	Local Const $sFuncName = "_WDExecuteScript"
	Local $sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession &  "/execute/sync", '{"script":"' & $sScript & '", "args":[]}')

	If $_WD_DEBUG Then
		ConsoleWrite($sFuncName & ': ' & $sResponse & @CRLF)
	EndIf

	Return $sResponse
EndFunc   ;==>_WDExecuteScript


; #FUNCTION# ====================================================================================================================
; Name ..........: _WDAlert
; Description ...: Respond to user prompt
; Syntax ........: _WDAlert($sSession, $sCommand)
; Parameters ....: $sSession            - Session ID from _WDCreateSession
;                  $sCommand            - one of the following actions:
;                               | dismiss
;                               | accept
; Return values .: None
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
Func _WDAlert($sSession, $sCommand)
	Local Const $sFuncName = "_WDAlert"
	Local $iErr

	$sCommand = StringLower($sCommand)

	Switch $sCommand
		Case 'dismiss', 'accept'
			Local $sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession &  "/alert/" & $sCommand, '{}')
			$iErr = @error

		Case Else
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(Dismiss|Accept) $sCommand=>" & $sCommand), 0, "")
	EndSwitch

	If $_WD_DEBUG Then
		ConsoleWrite($sFuncName & ': ' & $sResponse & @CRLF)
	EndIf

	If $iErr Then
		SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception, $sResponse), $_WD_HTTPRESULT)
	EndIf

	Return ""
EndFunc   ;==>_WDAlert


; #FUNCTION# ====================================================================================================================
; Name ..........: _WDGetSource
; Description ...: Get page source
; Syntax ........: _WDGetSource($sSession)
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
Func _WDGetSource($sSession)
	Local Const $sFuncName = "_WDGetSource"
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
EndFunc   ;==>_WDGetSource

; #FUNCTION# ====================================================================================================================
; Name ..........: _WDCookies
; Description ...:
; Syntax ........: _WDCookies($sSession, $sCommand[, $sOption = ''])
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
Func _WDCookies($sSession,  $sCommand, $sOption = '')
	Local Const $sFuncName = "_WDGetCookies"

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
EndFunc   ;==>_WDCookies



; #FUNCTION# ====================================================================================================================
; Name ..........: _WDOption
; Description ...: Sets and get options for the webdriver.au3
; Syntax ........: _WDOption($sOption[, $vValue = ""])
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
Func _WDOption($sOption, $vValue = "")
	Local Const $sFuncName = "_WDOption"

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
EndFunc   ;==>_WDOption

; #FUNCTION# ====================================================================================================================
; Name ..........: _WDStartup
; Description ...: Launch the designated web driver console app
; Syntax ........: _WDStartup()
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
Func _WDStartup()
	Local Const $sFuncName = "_WDStartup"

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
; Name ..........: _WDShutdown
; Description ...: Kill the web driver console app
; Syntax ........: _WDShutdown()
; Parameters ....:
; Return values .: None
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WDShutdown()
	__WD_CloseDriver()
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_NewTab
; Description ...: Helper function to create new tab using Javascript
; Syntax ........: _WD_NewTab($sSession[, $lSwitch = True])
; Parameters ....: $sSession            - Session ID from _WDCreateSession
;                  $lSwitch             - [optional] Switch session context to new tab? Default is True.
; Return values .: Success      - String representing handle of new tab
;                  Failure      - blank string
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_NewTab($sSession, $lSwitch = True)
	Local Const $sFuncName = "_WD_NewTab"
	Local $sTabHandle = ''

	_WDExecuteScript($sSession, 'window.open()', '{}')

	If @error = $_WD_ERROR_Success Then
		Local $aHandles = _WDWindow($sSession, 'handles', '')

		$sTabHandle = $aHandles[UBound($aHandles) - 1]

		If $lSwitch Then
			_WDWindow($sSession, 'Switch', '{"handle":"' & $sTabHandle & '"}')
		EndIf
	EndIf

	Return $sTabHandle
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_Attach
; Description ...: Helper function to attach to existing browser tab
; Syntax ........: _WD_Attach($sSession, $sString[, $sMode = 'title'])
; Parameters ....: $sSession            - Session ID from _WDCreateSession
;                  $sString             - String to search for
;                  $sMode               - [optional] One of the following search modes:
;                               | Title (Default)
;                               | URL
; Return values .: Success      - String representing handle of matching tab
;                  Failure      - blank string
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_Attach($sSession, $sString, $sMode = 'title')
	Local Const $sFuncName = "_WD_Attach"
	Local $sTabHandle = '', $lFound = False

	Local $sCurrentTab = _WDWindow($sSession, 'window')
	Local $aHandles = _WDWindow($sSession, 'handles')

	$sMode = StringLower($sMode)

	For $sTab In $aHandles

		_WDWindow($sSession, 'Switch', '{"handle":"' & $sTab & '"}')

		Switch $sMode
			Case "title", "url"
				If StringInStr(_WDAction($sSession, $sMode), $sString) > 0 Then
					$lFound = True
					$sTabHandle = $sTab
					ExitLoop
				EndIf

			Case Else
				SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(Title|URL) $sOption=>" & $sMode))
				Return ""
		EndSwitch
	Next

	If Not $lFound Then
		; Restore prior active tab
		_WDWindow($sSession, 'Switch', '{"handle":"' & $sCurrentTab & '"}')
		SetError(__WD_Error($sFuncName, $_WD_ERROR_NoMatch))
	EndIf

	Return $sTabHandle
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

	If $_WD_DEBUG Then
		ConsoleWrite($sFuncName & ': URL=' & $sURL & @CRLF)
	EndIf

	$_WD_OHTTP.Open("GET", $sURL, False)
	$_WD_OHTTP.SetRequestHeader("Content-Type", "application/json;charset=utf-8")
	$_WD_OHTTP.Send()

    ; wait until response is ready
    $_WD_OHTTP.WaitForResponse(5)

    $_WD_HTTPRESULT = $_WD_OHTTP.Status
    Local $sResponseText = $_WD_OHTTP.ResponseText

	If $_WD_DEBUG Then
		ConsoleWrite($sFuncName & ': StatusCode=' & $_WD_HTTPRESULT & "; $sResponseText=" & $sResponseText & @CRLF)
	EndIf

	If $_WD_HTTPRESULT <> 200 Then
		SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception, $sResponseText))
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
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WD_Post($sURL, $sData)
	Local Const $sFuncName = "__WD_Post"

	If $_WD_DEBUG Then
		ConsoleWrite($sFuncName & ': URL=' & $sURL & "; $sData=" & $sData & @CRLF)
	EndIf

	$_WD_OHTTP.Open("POST", $sURL, False)
	$_WD_OHTTP.SetRequestHeader("Content-Type", "application/json;charset=utf-8")
	$_WD_OHTTP.Send($sData)

    ; wait until response is ready
    $_WD_OHTTP.WaitForResponse(5)

	$_WD_HTTPRESULT = $_WD_OHTTP.Status
    Local $sResponseText = $_WD_OHTTP.ResponseText

	If $_WD_DEBUG Then
		ConsoleWrite($sFuncName & ': StatusCode=' & $_WD_HTTPRESULT & "; ResponseText=" & $sResponseText & @CRLF)
	EndIf

	If $_WD_HTTPRESULT <> 200 Then
		SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception, $sResponseText))
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
	$_WD_OHTTP.Open("DELETE", $sURL, False)
	$_WD_OHTTP.SetRequestHeader("Content-Type", "application/json;charset=utf-8")
	$_WD_OHTTP.Send()

    ; wait until response is ready
    $_WD_OHTTP.WaitForResponse(5)

    $_WD_HTTPRESULT = $_WD_OHTTP.Status
    Local $sResponseText = $_WD_OHTTP.ResponseText

	If $_WD_DEBUG Then
		ConsoleWrite($sFuncName & ': StatusCode=' & $_WD_HTTPRESULT & "; ResponseText=" & $sResponseText & @CRLF)
	EndIf

	If $_WD_HTTPRESULT <> 200 Then
		SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception, $sResponseText))
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
