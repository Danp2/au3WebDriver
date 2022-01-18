#include-once
; standard UDF's
#include <File.au3> ; Needed For _WD_UpdateDriver
#include <InetConstants.au3>
#include <Misc.au3> ; Needed For _WD_UpdateDriver >> _VersionCompare
#include <WinAPIFiles.au3> ; Needed For _WD_UpdateDriver >> _WinAPI_GetBinaryType

; WebDriver related UDF's
#include "wd_core.au3"

#Region Copyright
#cs
	* WD_Helper.au3
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

#Region Many thanks to:
#cs
	- Jonathan Bennett and the AutoIt Team
	- Thorsten Willert, author of FF.au3, which I've used as a model
	- Michał Lipok (@mLipok) for all his contribution
#ce
#EndRegion Many thanks to:

#ignorefunc _HtmlTableGetWriteToArray

#Region Global Constants
Global Enum _
		$_WD_OPTION_None = 0, _
		$_WD_OPTION_Visible = 1, _
		$_WD_OPTION_Enabled = 2, _
		$_WD_OPTION_Element = 4, _
		$_WD_OPTION_NoMatch = 8

Global Enum _
		$_WD_OPTION_Standard, _
		$_WD_OPTION_Advanced

Global Enum _
		$_WD_STATUS_Invalid, _
		$_WD_STATUS_Valid, _
		$_WD_STATUS_Reconnect

Global Enum _
		$_WD_TARGET_FirstTab, _
		$_WD_TARGET_LastTab

#EndRegion Global Constants

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_NewTab
; Description ...: Create new tab in current browser session.
; Syntax ........: _WD_NewTab($sSession[, $bSwitch = Default[, $iTimeout = Default[, $sURL = Default[, $sFeatures = Default]]]])
; Parameters ....: $sSession  - Session ID from _WD_CreateSession
;                  $bSwitch   - [optional] Switch session context to new tab? Default is True
;                  $iTimeout  - [optional] Period of time (in milliseconds) to wait before exiting function
;                  $sURL      - [optional] URL to be loaded in new tab
;                  $sFeatures - [optional] Comma-separated list of requested features of the new tab
; Return values .: Success - String representing handle of new tab.
;                  Failure - "" (empty string) and sets @error to one of the following values:
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_Timeout
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......: For list of $sFeatures take a look in the following link
; Related .......: _WD_Window
; Link ..........: https://developer.mozilla.org/en-US/docs/Web/API/Window/open#window_features
; Example .......: No
; ===============================================================================================================================
Func _WD_NewTab($sSession, $bSwitch = Default, $iTimeout = Default, $sURL = Default, $sFeatures = Default)
	Local Const $sFuncName = "_WD_NewTab"
	Local $sTabHandle = '', $sLastTabHandle, $hWaitTimer, $iTabIndex, $aTemp

	If $bSwitch = Default Then $bSwitch = True
	If $iTimeout = Default Then $iTimeout = $_WD_DefaultTimeout
	If $sURL = Default Then $sURL = ''
	If $sFeatures = Default Then $sFeatures = ''

	; Get handle for current tab
	Local $sCurrentTabHandle = _WD_Window($sSession, 'window')

	If $sFeatures = '' Then
		$sTabHandle = _WD_Window($sSession, 'new', '{"type":"tab"}')

		If @error = $_WD_ERROR_Success Then
			_WD_Window($sSession, 'Switch', '{"handle":"' & $sTabHandle & '"}')

			If $sURL Then _WD_Navigate($sSession, $sURL)

			If Not $bSwitch Then _WD_Window($sSession, 'Switch', '{"handle":"' & $sCurrentTabHandle & '"}')
		Else
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception), 0, $sTabHandle)
		EndIf
	Else
		Local $aHandles = _WD_Window($sSession, 'handles')

		If @error <> $_WD_ERROR_Success Or Not IsArray($aHandles) Then
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception), 0, $sTabHandle)
		EndIf

		Local $iTabCount = UBound($aHandles)

		; Get handle to current last tab
		$sLastTabHandle = $aHandles[$iTabCount - 1]

		If $sCurrentTabHandle Then
			; Search for current tab handle in array of tab handles. If not found,
			; then make the current tab handle equal to the last tab
			$iTabIndex = _ArraySearch($aHandles, $sCurrentTabHandle)

			If @error Then
				$sCurrentTabHandle = $sLastTabHandle
				$iTabIndex = $iTabCount - 1
			EndIf
		Else
			_WD_Window($sSession, 'Switch', '{"handle":"' & $sLastTabHandle & '"}')
			$sCurrentTabHandle = $sLastTabHandle
			$iTabIndex = $iTabCount - 1
		EndIf

		_WD_ExecuteScript($sSession, "window.open(arguments[0], '', arguments[1])", '"' & $sURL & '","' & $sFeatures & '"')
		If @error <> $_WD_ERROR_Success Then
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception), 0, $sTabHandle)
		EndIf

		$hWaitTimer = TimerInit()

		While 1
			$aTemp = _WD_Window($sSession, 'handles')

			If UBound($aTemp) > $iTabCount Then
				$sTabHandle = $aTemp[$iTabIndex + 1]
				ExitLoop
			EndIf

			If TimerDiff($hWaitTimer) > $iTimeout Then Return SetError(__WD_Error($sFuncName, $_WD_ERROR_Timeout), 0, $sTabHandle)

			__WD_Sleep(10)
			If @error Then Return SetError(__WD_Error($sFuncName, @error), 0, $sTabHandle)
		WEnd

		If $bSwitch Then
			_WD_Window($sSession, 'Switch', '{"handle":"' & $sTabHandle & '"}')
		Else
			_WD_Window($sSession, 'Switch', '{"handle":"' & $sCurrentTabHandle & '"}')
		EndIf
	EndIf

	Return SetError($_WD_ERROR_Success, 0, $sTabHandle)
EndFunc   ;==>_WD_NewTab

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_Attach
; Description ...: Attach to existing browser tab.
; Syntax ........: _WD_Attach($sSession, $sString[, $sMode = Default])
; Parameters ....: $sSession - Session ID from _WD_CreateSession
;                  $sString  - String to search for
;                  $sMode    - [optional] One of the following search modes:
;                  |Title (default)
;                  |URL
;                  |HTML
; Return values .: Success - String representing handle of matching tab.
;                  Failure - "" (empty string) and sets @error to one of the following values:
;                  - $_WD_ERROR_InvalidDataType
;                  - $_WD_ERROR_NoMatch
;                  - $_WD_ERROR_GeneralError
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......: _WD_Window
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_Attach($sSession, $sString, $sMode = Default)
	Local Const $sFuncName = "_WD_Attach"
	Local $sTabHandle = '', $bFound = False, $sCurrentTab = '', $aHandles

	If $sMode = Default Then $sMode = 'title'

	$aHandles = _WD_Window($sSession, 'handles')

	If @error = $_WD_ERROR_Success Then
		$sCurrentTab = _WD_Window($sSession, 'window')

		For $sHandle In $aHandles

			_WD_Window($sSession, 'Switch', '{"handle":"' & $sHandle & '"}')

			Switch $sMode
				Case "title", "url"
					If StringInStr(_WD_Action($sSession, $sMode), $sString) > 0 Then
						$bFound = True
						$sTabHandle = $sHandle
						ExitLoop
					EndIf

				Case 'html'
					If StringInStr(_WD_GetSource($sSession), $sString) > 0 Then
						$bFound = True
						$sTabHandle = $sHandle
						ExitLoop
					EndIf

				Case Else
					Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(Title|URL|HTML) $sMode=>" & $sMode), 0, $sTabHandle)
			EndSwitch
		Next

		If Not $bFound Then
			; Restore prior active tab
			If $sCurrentTab <> '' Then
				_WD_Window($sSession, 'Switch', '{"handle":"' & $sCurrentTab & '"}')
			EndIf

			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_NoMatch), 0, $sTabHandle)
		EndIf
	Else
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_GeneralError), 0, $sTabHandle)
	EndIf

	Return SetError($_WD_ERROR_Success, 0, $sTabHandle)
EndFunc   ;==>_WD_Attach

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_LinkClickByText
; Description ...: Simulate a mouse click on a link with text matching the provided string.
; Syntax ........: _WD_LinkClickByText($sSession, $sText[, $bPartial = Default])
; Parameters ....: $sSession - Session ID from _WD_CreateSession
;                  $sText    - Text to find in link
;                  $bPartial - [optional] Search by partial text? Default is True
; Return values .: Success - None.
;                  Failure - "" (empty string) and sets @error to one of the following values:
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_NoMatch
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......: _WD_FindElement, _WD_ElementAction
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_LinkClickByText($sSession, $sText, $bPartial = Default)
	Local Const $sFuncName = "_WD_LinkClickByText"

	If $bPartial = Default Then $bPartial = True

	Local $sElement = _WD_FindElement($sSession, ($bPartial) ? $_WD_LOCATOR_ByPartialLinkText : $_WD_LOCATOR_ByLinkText, $sText)
	Local $iErr = @error

	If $iErr = $_WD_ERROR_Success Then
		_WD_ElementAction($sSession, $sElement, 'click')
		$iErr = @error

		If $iErr <> $_WD_ERROR_Success Then
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception), $_WD_HTTPRESULT)
		EndIf
	Else
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_NoMatch), $_WD_HTTPRESULT)
	EndIf

	Return SetError($_WD_ERROR_Success)
EndFunc   ;==>_WD_LinkClickByText

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_WaitElement
; Description ...: Wait for an element in the current tab before returning.
; Syntax ........: _WD_WaitElement($sSession, $sStrategy, $sSelector[, $iDelay = Default[, $iTimeout = Default[, $iOptions = Default]]])
; Parameters ....: $sSession  - Session ID from _WD_CreateSession
;                  $sStrategy - Locator strategy. See defined constant $_WD_LOCATOR_* for allowed values
;                  $sSelector - Value to find
;                  $iDelay    - [optional] Milliseconds to wait before initially checking status
;                  $iTimeout  - [optional] Period of time (in milliseconds) to wait before exiting function
;                  $iOptions  - [optional] Binary flags to perform additional actions:
;                  |$_WD_OPTION_None    (0) = No optional feature processing
;                  |$_WD_OPTION_Visible (1) = Confirm element is visible
;                  |$_WD_OPTION_Enabled (2) = Confirm element is enabled
;                  |$_WD_OPTION_NoMatch (8) = Confirm element not found
; Return values .: Success - Element ID returned by web driver.
;                  Failure - "" (empty string) and sets @error to one of the following values:
;                  - $_WD_ERROR_Timeout
;                  - $_WD_ERROR_InvalidArgue
;                  - $_WD_ERROR_UserAbort
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......:
; Related .......: _WD_FindElement, _WD_ElementAction
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_WaitElement($sSession, $sStrategy, $sSelector, $iDelay = Default, $iTimeout = Default, $iOptions = Default)
	Local Const $sFuncName = "_WD_WaitElement"
	Local $iErr, $sElement, $bIsVisible = True, $bIsEnabled = True

	If $iDelay = Default Then $iDelay = 0
	If $iTimeout = Default Then $iTimeout = $_WD_DefaultTimeout
	If $iOptions = Default Then $iOptions = $_WD_OPTION_None

	Local $bVisible = BitAND($iOptions, $_WD_OPTION_Visible)
	Local $bEnabled = BitAND($iOptions, $_WD_OPTION_Enabled)
	Local $bCheckNoMatch = BitAND($iOptions, $_WD_OPTION_NoMatch)

	; Other options aren't valid if No Match option is supplied
	If $bCheckNoMatch And $iOptions <> $_WD_OPTION_NoMatch Then
		$iErr = $_WD_ERROR_InvalidArgue
	Else
		__WD_Sleep($iDelay)
		$iErr = @error

		Local $hWaitTimer = TimerInit()
		While 1
			If $iErr Then ExitLoop

			$sElement = _WD_FindElement($sSession, $sStrategy, $sSelector)
			$iErr = @error

			If $iErr = $_WD_ERROR_NoMatch And $bCheckNoMatch Then
				$iErr = $_WD_ERROR_Success
				ExitLoop

			ElseIf $iErr = $_WD_ERROR_Success Then
				If $bVisible Then
					$bIsVisible = _WD_ElementAction($sSession, $sElement, 'displayed')

					If @error Then
						$bIsVisible = False
					EndIf

				EndIf

				If $bEnabled Then
					$bIsEnabled = _WD_ElementAction($sSession, $sElement, 'enabled')

					If @error Then
						$bIsEnabled = False
					EndIf
				EndIf

				If $bIsVisible And $bIsEnabled Then
					ExitLoop
				Else
					$sElement = ''
				EndIf
			EndIf

			If (TimerDiff($hWaitTimer) > $iTimeout) Then
				$iErr = $_WD_ERROR_Timeout
				ExitLoop
			EndIf

			__WD_Sleep(10)
			$iErr = @error
		WEnd
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr), 0, $sElement)

EndFunc   ;==>_WD_WaitElement

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_GetMouseElement
; Description ...: Retrieves reference to element below mouse pointer.
; Syntax ........: _WD_GetMouseElement($sSession)
; Parameters ....: $sSession - Session ID from _WD_CreateSession
; Return values .: Success - Element ID returned by web driver.
;                  Failure - Response from web driver and sets @error returned from _WD_ExecuteScript()
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......:
; Related .......: _WD_ExecuteScript
; Link ..........: https://stackoverflow.com/questions/24538450/get-element-currently-under-mouse-without-using-mouse-events
; Example .......: No
; ===============================================================================================================================
Func _WD_GetMouseElement($sSession)
	Local Const $sFuncName = "_WD_GetMouseElement"
	Local $sScript = "return Array.from(document.querySelectorAll(':hover')).pop()"
	Local $sElement = _WD_ExecuteScript($sSession, $sScript, '', Default, $_WD_JSON_Element)
	Local $iErr = @error

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & $sElement & @CRLF)
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr), 0, $sElement)
EndFunc   ;==>_WD_GetMouseElement

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_GetElementFromPoint
; Description ...: Retrieves reference to element at specified point.
; Syntax ........: _WD_GetElementFromPoint($sSession, $iX, $iY)
; Parameters ....: $sSession - Session ID from _WD_CreateSession
;                  $iX       - an integer value
;                  $iY       - an integer value
; Return values .: Success - Element ID returned by web driver.
;                  Failure - "" (empty string) and @error is set to $_WD_ERROR_RetValue
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......: @extended is set to 1 if the browsing context changed during the function call
; Related .......: _WD_ExecuteScript
; Link ..........: https://stackoverflow.com/questions/31910534/executing-javascript-elementfrompoint-through-selenium-driver/32574543#32574543
; Example .......: No
; ===============================================================================================================================
Func _WD_GetElementFromPoint($sSession, $iX, $iY)
	Local Const $sFuncName = "_WD_GetElementFromPoint"
	Local $sElement, $sTagName, $sParams, $aCoords, $iFrame = 0, $oERect
	Local $sScript1 = "return document.elementFromPoint(arguments[0], arguments[1]);"
	Local $sScript2 = "return new Array(window.pageXOffset, window.pageYOffset);"
	Local $iErr = $_WD_ERROR_Success

	While True
		$sParams = $iX & ", " & $iY
		$sElement = _WD_ExecuteScript($sSession, $sScript1, $sParams, Default, $_WD_JSON_Element)
		If @error Then
			$iErr = $_WD_ERROR_RetValue
			ExitLoop
		EndIf

		$sTagName = _WD_ElementAction($sSession, $sElement, "Name")
		If Not StringInStr("iframe", $sTagName) Then
			ExitLoop
		EndIf

		$aCoords = _WD_ExecuteScript($sSession, $sScript2, $_WD_EmptyDict, Default, $_WD_JSON_Value)
		If @error Then
			$iErr = $_WD_ERROR_RetValue
			ExitLoop
		EndIf

		$oERect = _WD_ElementAction($sSession, $sElement, 'rect')

		; changing the coordinates in relation to left top corner of frame
		$iX -= ($oERect.Item('x') - Int($aCoords[0]))
		$iY -= ($oERect.Item('y') - Int($aCoords[1]))

		_WD_FrameEnter($sSession, $sElement)
		$iFrame = 1
	WEnd

	Return SetError(__WD_Error($sFuncName, $iErr), $iFrame, $sElement)
EndFunc   ;==>_WD_GetElementFromPoint

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_LastHTTPResult
; Description ...: Return the result of the last WinHTTP request.
; Syntax ........: _WD_LastHTTPResult()
; Parameters ....: None
; Return values .: Result of last WinHTTP request
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_LastHTTPResult()
	Return $_WD_HTTPRESULT
EndFunc   ;==>_WD_LastHTTPResult

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_GetFrameCount
; Description ...: This will return the number of frames/iframes in the current document context
; Syntax ........: _WD_GetFrameCount($sSession)
; Parameters ....: $sSession - Session ID from _WD_CreateSession
; Return values .: Success - Number of frames
;                  Failure - 0 and sets @error to $_WD_ERROR_Exception
; Author ........: Decibel, Danp2
; Modified ......: mLipok
; Remarks .......: Nested frames are not included in the frame count
; Related .......: _WD_ExecuteScript
; Link ..........: https://www.w3schools.com/jsref/prop_win_length.asp
; Example .......: No
; ===============================================================================================================================
Func _WD_GetFrameCount($sSession)
	Local Const $sFuncName = "_WD_GetFrameCount"
	Local $iValue = _WD_ExecuteScript($sSession, "return window.frames.length", Default, Default, $_WD_JSON_Value)
	Local $iErr = @error
	If @error Then $iValue = 0
	Return SetError(__WD_Error($sFuncName, $iErr), 0, Number($iValue))
EndFunc   ;==>_WD_GetFrameCount

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_IsWindowTop
; Description ...: This will return a boolean of the session being at the top level, or in a frame(s).
; Syntax ........: _WD_IsWindowTop($sSession)
; Parameters ....: $sSession - Session ID from _WD_CreateSession
; Return values .: Success - Boolean response.
;                  Failure - Response from webdriver and sets @error returned from _WD_ExecuteScript()
; Author ........: Decibel
; Modified ......: mLipok
; Remarks .......:
; Related .......: _WD_ExecuteScript
; Link ..........: https://www.w3schools.com/jsref/prop_win_top.asp
; Example .......: No
; ===============================================================================================================================
Func _WD_IsWindowTop($sSession)
	Local Const $sFuncName = "_WD_IsWindowTop"
	Local $blnResult = _WD_ExecuteScript($sSession, "return window.top == window.self", Default, Default, $_WD_JSON_Value)
	Local $iErr = @error
	Return SetError(__WD_Error($sFuncName, $iErr), 0, $blnResult)
EndFunc   ;==>_WD_IsWindowTop

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_FrameEnter
; Description ...: This will enter the specified frame for subsequent WebDriver operations.
; Syntax ........: _WD_FrameEnter($sSession, $vIdentifier)
; Parameters ....: $sSession    - Session ID from _WD_CreateSession
;                  $vIdentifier - Index (as 0-based Integer) or Element ID (as String) or Null (Keyword)
; Return values .: Success - True.
;                  Failure - WD Response error message (E.g. "no such frame") and sets @error to $_WD_ERROR_Exception
; Author ........: Decibel
; Modified ......: mLipok
; Remarks .......: You can drill-down into nested frames by calling this function repeatedly with the correct parameters
; Related .......: _WD_Window
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_FrameEnter($sSession, $vIdentifier)
	Local Const $sFuncName = "_WD_FrameEnter"
	Local $sOption
	Local $sResponse, $oJSON
	Local $sValue

	;*** Encapsulate the value if it's an integer, assuming that it's supposed to be an Index, not ID attrib value.
	If (IsKeyword($vIdentifier) = $KEYWORD_NULL) Then
		$sOption = '{"id":null}'
	ElseIf IsInt($vIdentifier) Then
		$sOption = '{"id":' & $vIdentifier & '}'
	Else
		$sOption = '{"id":' & __WD_JsonElement($vIdentifier) & '}'
	EndIf

	$sResponse = _WD_Window($sSession, "frame", $sOption)

	If @error <> $_WD_ERROR_Success Then
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception), "")
	EndIf

	$oJSON = Json_Decode($sResponse)
	$sValue = Json_Get($oJSON, $_WD_JSON_Value)

	;*** Evaluate the response
	If $sValue <> Null Then
		$sValue = Json_Get($oJSON, $_WD_JSON_Error)
	Else
		$sValue = True
	EndIf

	Return SetError($_WD_ERROR_Success, 0, $sValue)
EndFunc   ;==>_WD_FrameEnter

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_FrameLeave
; Description ...: This will leave the current frame, to its parent, not necessarily the Top, for subsequent WebDriver operations.
; Syntax ........: _WD_FrameLeave($sSession)
; Parameters ....: $sSession - Session ID from _WD_CreateSession
; Return values .: Success - True.
;                  Failure - WD Response error message (E.g. "chrome not reachable") and sets @error to $_WD_ERROR_Exception
; Author ........: Decibel
; Modified ......: 2018-04-27
; Remarks .......: ChromeDriver and GeckoDriver respond differently for a successful operation
; Related .......: _WD_Window
; Link ..........: https://www.w3.org/TR/webdriver/#switch-to-parent-frame
; Example .......: No
; ===============================================================================================================================
Func _WD_FrameLeave($sSession)
	Local Const $sFuncName = "_WD_FrameLeave"
	Local $sOption
	Local $sResponse, $oJSON, $asJSON
	Local $sValue

	$sOption = '{}'

	$sResponse = _WD_Window($sSession, "parent", $sOption)

	If @error <> $_WD_ERROR_Success Then
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception), "")
	EndIf

	;Chrome--
	;   Good: '{"value":null}'
	;   Bad: '{"value":{"error":"chrome not reachable"....
	;Firefox--
	;   Good: '{"value": {}}'
	;   Bad: '{"value":{"error":"unknown error","message":"Failed to decode response from marionette","stacktrace":""}}'

	$oJSON = Json_Decode($sResponse)
	$sValue = Json_Get($oJSON, $_WD_JSON_Value)

	;*** Is this something besides a Chrome PASS?
	If $sValue <> Null Then
		;*** Check for a nested JSON object
		If Json_IsObject($sValue) = True Then
			$asJSON = Json_ObjGetKeys($sValue)

			;*** Is this an empty nested object
			If UBound($asJSON) = 0 Then ;Firefox PASS
				$sValue = True
			Else ;Chrome and Firefox FAIL
				$sValue = $asJSON[0] & ":" & Json_Get($oJSON, "[value][" & $asJSON[0] & "]")
			EndIf
		EndIf
	Else ;Chrome PASS
		$sValue = True
	EndIf

	Return SetError($_WD_ERROR_Success, 0, $sValue)
EndFunc   ;==>_WD_FrameLeave

; #FUNCTION# ===========================================================================================================
; Name ..........: _WD_HighlightElement
; Description ...: Highlights the specified element.
; Syntax ........: _WD_HighlightElement($sSession, $sElement[, $iMethod = Default])
; Parameters ....: $sSession - Session ID from _WD_CreateSession
;                  $sElement - Element ID from _WD_FindElement
;                  $iMethod  - [optional] an integer value to set the style (default = 1)
;                  0 - Remove highlight
;                  1 - Highlight border dotted red
;                  2 - Highlight yellow rounded box
;                  3 - Highlight yellow rounded box + border  dotted red
; Return values .: Success - True.
;                  Failure - False and sets @error returned from _WD_ExecuteScript()
; Author ........: Danyfirex
; Modified ......: mLipok
; Remarks .......:
; Related .......: _WD_HighlightElements
; Link ..........: https://www.autoitscript.com/forum/topic/192730-webdriver-udf-help-support/?do=findComment&comment=1396643
; Example .......: No
; ===============================================================================================================================
Func _WD_HighlightElement($sSession, $sElement, $iMethod = Default)
	Local Const $aMethod[] = _
			[ _
			"border: 0px", _
			"border: 2px dotted red", _
			"background: #FFFF66; border-radius: 5px; padding-left: 3px;", _
			"border: 2px dotted red; background: #FFFF66; border-radius: 5px; padding-left: 3px;" _
			]

	If $iMethod = Default Then $iMethod = 1
	If $iMethod < 0 Or $iMethod > 3 Then $iMethod = 1

	Local $sScript = "arguments[0].style='" & $aMethod[$iMethod] & "'; return true;"
	Local $sJsonElement = __WD_JsonElement($sElement)
	Local $sResult = _WD_ExecuteScript($sSession, $sScript, $sJsonElement, Default, $_WD_JSON_Value)
	Local $iErr = @error
	Return ($sResult = "true" ? SetError(0, 0, True) : SetError($iErr, 0, False))
EndFunc   ;==>_WD_HighlightElement

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_HighlightElements
; Description ...: Highlights the specified elements.
; Syntax ........: _WD_HighlightElements($sSession, $aElements[, $iMethod = Default])
; Parameters ....: $sSession  - Session ID from _WD_CreateSession
;                  $aElements - an array of Elements ID from _WD_FindElement
;                  $iMethod   - [optional] an integer value to set the style (default = 1)
;                  0 - Remove highlight
;                  1 - Highlight border dotted red
;                  2 - Highlight yellow rounded box
;                  3 - Highlight yellow rounded box + border  dotted red
; Return values .: Success - True. @extended is set to the number of highlighted elements
;                  Failure - False and sets @error to $_WD_ERROR_GeneralError
; Author ........: Danyfirex
; Modified ......: mLipok
; Remarks .......:
; Related .......: _WD_HighlightElement
; Link ..........: https://www.autoitscript.com/forum/topic/192730-webdriver-udf-help-support/?do=findComment&comment=1396643
; Example .......: No
; ===============================================================================================================================
Func _WD_HighlightElements($sSession, $aElements, $iMethod = Default)
	Local $iHighlightedElements = 0

	If $iMethod = Default Then $iMethod = 1

	For $i = 0 To UBound($aElements) - 1
		$iHighlightedElements += (_WD_HighlightElement($sSession, $aElements[$i], $iMethod) = True ? 1 : 0)
	Next
	Return ($iHighlightedElements > 0 ? SetError(0, $iHighlightedElements, True) : SetError($_WD_ERROR_GeneralError, 0, False))
EndFunc   ;==>_WD_HighlightElements

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_LoadWait
; Description ...: Wait for a browser page load to complete before returning.
; Syntax ........: _WD_LoadWait($sSession[, $iDelay = Default[, $iTimeout = Default[, $sElement = Default]]])
; Parameters ....: $sSession - Session ID from _WD_CreateSession
;                  $iDelay   - [optional] Milliseconds to wait before initially checking status
;                  $iTimeout - [optional] Period of time (in milliseconds) to wait before exiting function
;                  $sElement - [optional] Element ID to confirm DOM invalidation
; Return values .: Success - 1.
;                  Failure - 0 and sets @error to $_WD_ERROR_Timeout
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_LoadWait($sSession, $iDelay = Default, $iTimeout = Default, $sElement = Default)
	Local Const $sFuncName = "_WD_LoadWait"
	Local $iErr, $sReadyState

	If $iDelay = Default Then $iDelay = 0
	If $iTimeout = Default Then $iTimeout = $_WD_DefaultTimeout
	If $sElement = Default Then $sElement = ""

	__WD_Sleep($iDelay)
	$iErr = @error

	Local $hLoadWaitTimer = TimerInit()
	While True
		If $iErr Then ExitLoop

		If $sElement <> '' Then
			_WD_ElementAction($sSession, $sElement, 'name')

			If $_WD_HTTPRESULT = $HTTP_STATUS_NOT_FOUND Then $sElement = ''
		Else
			$sReadyState = _WD_ExecuteScript($sSession, 'return document.readyState', '', Default, $_WD_JSON_Value)
			$iErr = @error
			If $iErr Or $sReadyState = 'complete' Then
				ExitLoop
			EndIf
		EndIf

		If (TimerDiff($hLoadWaitTimer) > $iTimeout) Then
			$iErr = $_WD_ERROR_Timeout
			ExitLoop
		EndIf

		__WD_Sleep(10)
		$iErr = @error
	WEnd

	If $iErr Then
		Return SetError(__WD_Error($sFuncName, $iErr, ""), 0, 0)
	EndIf

	Return SetError($_WD_ERROR_Success, 0, 1)
EndFunc   ;==>_WD_LoadWait

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_Screenshot
; Description ...: Takes a screenshot of the Window or Element.
; Syntax ........: _WD_Screenshot($sSession[, $sElement = Default[, $nOutputType = Default]])
; Parameters ....: $sSession    - Session ID from _WD_CreateSession
;                  $sElement    - [optional] Element ID from _WD_FindElement
;                  $nOutputType - [optional] One of the following output types:
;                  |1 - String (Default)
;                  |2 - Binary
;                  |3 - Base64
; Return values .: Success - Output of specified type (PNG format).
;                  Failure - "" (empty string) and sets @error to one of the following values:
;                  - $_WD_ERROR_NoMatch
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_InvalidDataType
;                  - $_WD_ERROR_InvalidExpression
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......: _WD_Window, _WD_ElementAction
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_Screenshot($sSession, $sElement = Default, $nOutputType = Default)
	Local Const $sFuncName = "_WD_Screenshot"
	Local $sResponse, $sResult, $iErr

	If $sElement = Default Then $sElement = ""
	If $nOutputType = Default Then $nOutputType = 1

	If $sElement = '' Then
		$sResponse = _WD_Window($sSession, 'Screenshot')
		$iErr = @error
	Else
		$sResponse = _WD_ElementAction($sSession, $sElement, 'Screenshot')
		$iErr = @error
	EndIf

	If $iErr = $_WD_ERROR_Success Then
		Switch $nOutputType
			Case 1 ; String
				$sResult = BinaryToString(__WD_Base64Decode($sResponse))
			Case 2 ; Binary
				$sResult = __WD_Base64Decode($sResponse)
			Case 3 ; Base64
				$sResult = $sResponse
		EndSwitch
	Else
		$sResult = ''
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr), 0, $sResult)
EndFunc   ;==>_WD_Screenshot

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_PrintToPDF
; Description ...: Print the current tab in paginated PDF format.
; Syntax ........: _WD_PrintToPDF($sSession[, $sOptions = Default]])
; Parameters ....: $sSession - Session ID from _WD_CreateSession
;                  $sOptions - [optional] JSON string of formatting directives
; Return values .: Success - String containing PDF contents.
;                  Failure - "" (empty string) and sets @error to one of the following values:
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_InvalidDataType
; Author ........: Danp2
; Modified ......:
; Remarks .......: Chromedriver currently requires headless mode (https://bugs.chromium.org/p/chromedriver/issues/detail?id=3517)
; Related .......: _WD_Window
; Link ..........: https://www.w3.org/TR/webdriver/#print-page
; Example .......: No
; ===============================================================================================================================
Func _WD_PrintToPDF($sSession, $sOptions = Default)
	Local Const $sFuncName = "_WD_PrintToPDF"
	Local $sResponse, $sResult, $iErr

	If $sOptions = Default Then $sOptions = $_WD_EmptyDict

	$sResponse = _WD_Window($sSession, 'print', $sOptions)
	$iErr = @error

	If $iErr = $_WD_ERROR_Success Then
		$sResult = __WD_Base64Decode($sResponse)
	Else
		$sResult = ''
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr), 0, $sResult)
EndFunc   ;==>_WD_PrintToPDF

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_jQuerify
; Description ...: Inject jQuery library into current session.
; Syntax ........: _WD_jQuerify($sSession[, $sjQueryFile = Default[, $iTimeout = Default]])
; Parameters ....: $sSession    - Session ID from _WD_CreateSession
;                  $sjQueryFile - [optional] Path or URL to jQuery source file
;                  $iTimeout    - [optional] Period of time (in milliseconds) to wait before exiting function
; Return values .: Success - None.
;                  Failure - None and sets @error to one of the following values:
;                  - $_WD_ERROR_Timeout
;                  - $_WD_ERROR_GeneralError
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......:
; Related .......: _WD_ExecuteScript
; Link ..........: https://sqa.stackexchange.com/questions/2921/webdriver-can-i-inject-a-jquery-script-for-a-page-that-isnt-using-jquery
; Example .......: No
; ===============================================================================================================================
Func _WD_jQuerify($sSession, $sjQueryFile = Default, $iTimeout = Default)
	Local Const $sFuncName = "_WD_jQuerify"

	If $sjQueryFile = Default Then
		$sjQueryFile = ""
	Else
		$sjQueryFile = '"' & StringReplace($sjQueryFile, "\", "/") & '"' ; wrap in double quotes and replace backslashes
	EndIf

	If $iTimeout = Default Then $iTimeout = $_WD_DefaultTimeout

	Local $jQueryLoader = _
			"(function(jqueryUrl, callback) {" & _
			"    if (typeof jqueryUrl != 'string') {" & _
			"        jqueryUrl = 'https://ajax.googleapis.com/ajax/libs/jquery/3.4.1/jquery.min.js';" & _
			"    }" & _
			"    if (typeof jQuery == 'undefined') {" & _
			"        var script = document.createElement('script');" & _
			"        var head = document.getElementsByTagName('head')[0];" & _
			"        var done = false;" & _
			"        script.onload = script.onreadystatechange = (function() {" & _
			"            if (!done && (!this.readyState || this.readyState == 'loaded' " & _
			"                    || this.readyState == 'complete')) {" & _
			"                done = true;" & _
			"                script.onload = script.onreadystatechange = null;" & _
			"                head.removeChild(script);" & _
			"                callback();" & _
			"            }" & _
			"        });" & _
			"        script.src = jqueryUrl;" & _
			"        head.appendChild(script);" & _
			"    }" & _
			"    else {" & _
			"        jQuery.noConflict();" & _
			"        callback();" & _
			"    }" & _
			"})(arguments[0], arguments[arguments.length - 1]);"

	_WD_ExecuteScript($sSession, $jQueryLoader, $sjQueryFile, True)

	If @error = $_WD_ERROR_Success Then
		Local $hWaitTimer = TimerInit()

		Do
			__WD_Sleep(10)
			If @error Then ExitLoop

			If TimerDiff($hWaitTimer) > $iTimeout Then
				SetError($_WD_ERROR_Timeout)
				ExitLoop
			EndIf

			_WD_ExecuteScript($sSession, "jQuery")
		Until @error = $_WD_ERROR_Success
	EndIf

	Local $iErr = @error

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & $iErr & @CRLF)
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr))

EndFunc   ;==>_WD_jQuerify

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_ElementOptionSelect
; Description ...: Find and click on an option from a Select element.
; Syntax ........: _WD_ElementOptionSelect($sSession, $sStrategy, $sSelector[, $sStartElement = Default])
; Parameters ....: $sSession      - Session ID from _WD_CreateSession
;                  $sStrategy     - Locator strategy. See defined constant $_WD_LOCATOR_* for allowed values
;                  $sSelector     - Value to find
;                  $sStartElement - [optional] Element ID of element to use as starting point
; Return values .: Success - None.
;                  Failure - None and sets @error to one of the following values:
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_NoMatch
;                  - $_WD_ERROR_InvalidDataType
;                  - $_WD_ERROR_InvalidExpression
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......: _WD_FindElement, _WD_ElementAction
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_ElementOptionSelect($sSession, $sStrategy, $sSelector, $sStartElement = Default)
	If $sStartElement = Default Then $sStartElement = ""

	Local $sElement = _WD_FindElement($sSession, $sStrategy, $sSelector, $sStartElement)

	If @error = $_WD_ERROR_Success Then
		_WD_ElementAction($sSession, $sElement, 'click')
	EndIf

	Return SetError(@error, @extended)

EndFunc   ;==>_WD_ElementOptionSelect

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_ElementSelectAction
; Description ...: Perform action on desginated Select element.
; Syntax ........: _WD_ElementSelectAction($sSession, $sSelectElement, $sCommand)
; Parameters ....: $sSession       - Session ID from _WD_CreateSession
;                  $sSelectElement - Element ID of Select element from _WD_FindElement
;                  $sCommand       - Action to be performed. Can be one of the following:
;                  |OPTIONS - Retrieve array containing value / label attributes from the Select element's options
;                  |VALUE - Retrieve current value
; Return values .: Success - Requested data returned by web driver.
;                  Failure - "" (empty string) and sets @error to one of the following values:
;                  - $_WD_ERROR_NoMatch
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_InvalidDataType
;                  - $_WD_ERROR_InvalidExpression
;                  - $_WD_ERROR_InvalidArgue
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......:
; Related .......: _WD_FindElement, _WD_ExecuteScript
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_ElementSelectAction($sSession, $sSelectElement, $sCommand)
	Local Const $sFuncName = "_WD_ElementSelectAction"
	Local $sNodeName, $sJsonElement, $vResult
	Local $sText, $aOptions

	$sNodeName = _WD_ElementAction($sSession, $sSelectElement, 'property', 'nodeName')
	Local $iErr = @error

	If $iErr = $_WD_ERROR_Success And $sNodeName = 'select' Then

		Switch $sCommand
			Case 'value'
				; Retrieve current value of designated Select element
				$sJsonElement = __WD_JsonElement($sSelectElement)
				$vResult = _WD_ExecuteScript($sSession, "return arguments[0].value", $sJsonElement, Default, $_WD_JSON_Value)
				$iErr = @error

			Case 'options'
				; Retrieve array containing value / label attributes from the Select element's options
				$aOptions = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "./option", $sSelectElement, True)
				$iErr = @error

				If $iErr = $_WD_ERROR_Success Then
					$sText = ""
					For $sElement In $aOptions
						$sJsonElement = __WD_JsonElement($sElement)
						$sText &= (($sText <> "") ? @CRLF : "") & _WD_ExecuteScript($sSession, "return arguments[0].value + '|' + arguments[0].label", $sJsonElement, Default, $_WD_JSON_Value)
						$iErr = @error
					Next

					Local $aOut[0][2]
					_ArrayAdd($aOut, $sText, 0, Default, @CRLF, 1)
					$vResult = $aOut
				EndIf
			Case Else
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(Value|Options) $sCommand=>" & $sCommand), 0, "")

		EndSwitch
	Else
		$iErr = $_WD_ERROR_InvalidArgue
	EndIf

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & ((IsArray($vResult)) ? "(array)" : $vResult) & @CRLF)
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr), $_WD_HTTPRESULT, $vResult)
EndFunc   ;==>_WD_ElementSelectAction

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_ConsoleVisible
; Description ...: Control visibility of the webdriver console app.
; Syntax ........: _WD_ConsoleVisible([$bVisible = Default])
; Parameters ....: $bVisible - [optional] Set to true to show the console. Default is False.
; Return values .: Success - None
;                  Failure - None
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: _WD_ConsoleVisible(False)
; ===============================================================================================================================
Func _WD_ConsoleVisible($bVisible = Default)
	Local $sFile = __WD_StripPath($_WD_DRIVER)
	Local $pid, $pid2, $hWnd = 0, $aWinList

	If $bVisible = Default Then $bVisible = False

	$pid = ProcessExists($sFile)

	If $pid Then
		$aWinList = WinList("[CLASS:ConsoleWindowClass]")

		For $i = 1 To $aWinList[0][0]
			$pid2 = WinGetProcess($aWinList[$i][1])

			If $pid2 = $pid Then
				$hWnd = $aWinList[$i][1]
				ExitLoop
			EndIf
		Next

		If $hWnd <> 0 Then
			WinSetState($hWnd, "", $bVisible ? @SW_SHOW : @SW_HIDE)
		EndIf
	EndIf

EndFunc   ;==>_WD_ConsoleVisible

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_GetShadowRoot
; Description ...: Retrieves the shadow root of an element.
; Syntax ........: _WD_GetShadowRoot($sSession, $sStrategy, $sSelector[, $sStartElement = Default])
; Parameters ....: $sSession      - Session ID from _WD_CreateSession
;                  $sStrategy     - Locator strategy. See defined constant $_WD_LOCATOR_* for allowed values
;                  $sSelector     - Value to find
;                  $sStartElement - [optional] a string value. Default is ""
; Return values .: Success - Element ID returned by web driver.
;                  Failure - "" (empty string) and sets @error to one of the following values:
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_NoMatch
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......: _WD_FindElement, _WD_ElementAction
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_GetShadowRoot($sSession, $sStrategy, $sSelector, $sStartElement = Default)
	Local Const $sFuncName = "_WD_GetShadowRoot"
	Local $sResponse, $sResult = "", $oJSON

	If $sStartElement = Default Then $sStartElement = ""

	Local $sElement = _WD_FindElement($sSession, $sStrategy, $sSelector, $sStartElement)
	Local $iErr = @error

	If $iErr = $_WD_ERROR_Success Then
		$sResponse = _WD_ElementAction($sSession, $sElement, 'shadow')
		$iErr = @error

		If $iErr = $_WD_ERROR_Success Then
			$oJSON = Json_Decode($sResponse)
			$sResult = Json_Get($oJSON, $_WD_JSON_Shadow)
		EndIf
	EndIf

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & $sResult & @CRLF)
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr), $_WD_HTTPRESULT, $sResult)
EndFunc   ;==>_WD_GetShadowRoot

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_SelectFiles
; Description ...: Select files for uploading to a website.
; Syntax ........: _WD_SelectFiles($sSession, $sStrategy, $sSelector, $sFilename)
; Parameters ....: $sSession  - Session ID from _WD_CreateSession
;                  $sStrategy - Locator strategy. See defined constant $_WD_LOCATOR_* for allowed values
;                  $sSelector - Value to find. Should point to element of type '< input type="file" >'
;                  $sFilename - Full path of file(s) to upload (use newline character [@LF] to separate files)
; Return values .: Success - Number of selected files.
;                  Failure - "0" and sets @error to one of the following values:
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_NoMatch
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......: If $sFilename is empty, then prior selection is cleared
; Related .......: _WD_FindElement, _WD_ElementAction
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_SelectFiles($sSession, $sStrategy, $sSelector, $sFilename)
	Local Const $sFuncName = "_WD_SelectFiles"

	Local $sResult = "0", $sJsonElement, $sSavedEscape
	Local $sElement = _WD_FindElement($sSession, $sStrategy, $sSelector)
	Local $iErr = @error

	If $iErr = $_WD_ERROR_Success Then
		If $sFilename <> "" Then
			$sSavedEscape = $_WD_ESCAPE_CHARS
			; Convert file string into proper format
			$sFilename = StringReplace(__WD_EscapeString($sFilename), @LF, "\n")
			; Prevent further string escaping
			$_WD_ESCAPE_CHARS = ""
			_WD_ElementAction($sSession, $sElement, 'value', $sFilename)
			$iErr = @error
			; Restore setting
			$_WD_ESCAPE_CHARS = $sSavedEscape
		Else
			_WD_ElementAction($sSession, $sElement, 'clear')
			$iErr = @error
		EndIf

		If $iErr = $_WD_ERROR_Success Then
			$sJsonElement = __WD_JsonElement($sElement)
			$sResult = _WD_ExecuteScript($sSession, "return arguments[0].files.length", $sJsonElement, Default, $_WD_JSON_Value)
			$iErr = @error
			If @error Then $sResult = "0"
		EndIf
	EndIf

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & $sResult & " file(s) selected" & @CRLF)
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr), $_WD_HTTPRESULT, $sResult)
EndFunc   ;==>_WD_SelectFiles

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_IsLatestRelease
; Description ...: Compares local UDF version to latest release on Github.
; Syntax ........: _WD_IsLatestRelease()
; Parameters ....: None
; Return values .: Success - True if the local UDF version is the latest, otherwise False
;                  Failure - Null and sets @error to one of the following values:
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_GeneralError
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_IsLatestRelease()
	Local Const $sFuncName = "_WD_IsLatestRelease"
	Local Const $sGitURL = "https://github.com/Danp2/WebDriver/releases/latest"
	Local $bResult = Null
	Local $iErr = $_WD_ERROR_Success
	Local $sRegex = '<a.*href="\/Danp2\/WebDriver\/releases\/tag\/(.*?)"'

	Local $sResult = InetRead($sGitURL)
	If @error Then $iErr = $_WD_ERROR_GeneralError

	If $iErr = $_WD_ERROR_Success Then
		Local $aLatestWDVersion = StringRegExp(BinaryToString($sResult), $sRegex, $STR_REGEXPARRAYMATCH)

		If Not @error Then
			Local $sLatestWDVersion = $aLatestWDVersion[0]
			$bResult = ($__WDVERSION == $sLatestWDVersion)
		Else
			$iErr = $_WD_ERROR_Exception
		EndIf
	EndIf

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & $bResult & @CRLF)
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr), $_WD_HTTPRESULT, $bResult)

EndFunc   ;==>_WD_IsLatestRelease

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_UpdateDriver
; Description ...: Replace web driver with newer version, if available.
; Syntax ........: _WD_UpdateDriver($sBrowser[, $sInstallDir = Default[, $bFlag64 = Default[, $bForce = Default]]])
; Parameters ....: $sBrowser    - Name of browser
;                  $sInstallDir - [optional] Install directory. Default is @ScriptDir
;                  $bFlag64     - [optional] Install 64bit version? Default is False
;                  $bForce      - [optional] Force update? Default is False
; Return values .: Success - True (Driver was updated).
;                  Failure - False (Driver was not updated) and sets @error to one of the following values:
;                  - $_WD_ERROR_NoMatch
;                  - $_WD_ERROR_InvalidValue
;                  - $_WD_ERROR_GeneralError
; Author ........: Danp2, CyCho
; Modified ......: mLipok
; Remarks .......: When $bForce = Null, then the function will check for an updated webdriver without actually performing the update.
;                  In this scenario, the return value indicates if an update is available.
; Related .......: _WD_GetBrowserVersion, _WD_GetWebDriverVersion
; Link ..........:
; Example .......: Local $bResult = _WD_UpdateDriver('FireFox')
; ===============================================================================================================================
Func _WD_UpdateDriver($sBrowser, $sInstallDir = Default, $bFlag64 = Default, $bForce = Default)
	Local Const $sFuncName = "_WD_UpdateDriver"
	Local $iErr = $_WD_ERROR_Success, $sDriverEXE, $sBrowserVersion, $bResult = False
	Local $sDriverCurrent, $sVersionShort, $sDriverLatest, $sURLNewDriver
	Local $sTempFile, $oShell, $FilesInZip, $sResult, $iStartPos, $iConversion

	If $sInstallDir = Default Then $sInstallDir = @ScriptDir
	If $bFlag64 = Default Then $bFlag64 = False
	If $bForce = Default Then $bForce = False

	$sInstallDir = StringRegExpReplace($sInstallDir, '(?i)(\\)\Z', '') & '\' ; prevent double \\ on the end of directory

	; If the Install directory doesn't exist and it can't be created, then set error
	If (Not FileExists($sInstallDir)) And (Not DirCreate($sInstallDir)) Then
		$iErr = $_WD_ERROR_InvalidValue
	Else
		; Save current debug level and set to none
		Local $WDDebugSave = $_WD_DEBUG
		$_WD_DEBUG = $_WD_DEBUG_None

		$sBrowserVersion = _WD_GetBrowserVersion($sBrowser)
		$iErr = @error

		If $iErr = $_WD_ERROR_Success Then
			Switch $sBrowser
				Case 'chrome'
					$sDriverEXE = "chromedriver.exe"
				Case 'firefox'
					$sDriverEXE = "geckodriver.exe"
				Case 'msedge'
					$sDriverEXE = "msedgedriver.exe"
			EndSwitch

			; Determine current local webdriver Architecture
			If FileExists($sInstallDir & $sDriverEXE) Then
				_WinAPI_GetBinaryType($sInstallDir & $sDriverEXE)
				Local $bDriverIs64Bit = (@extended = $SCS_64BIT_BINARY)
				If $sBrowser <> 'chrome' And $bDriverIs64Bit <> $bFlag64 Then
					$bForce = True
;~ 					If $WDDebugSave = $_WD_DEBUG_Info Then
;~ 						__WD_ConsoleWrite($sFuncName & ': ' & $sDriverEXE & ' = ' & (($bDriverIs64Bit) ? ("switching 64>32 Bit") : ("switching 32>64 Bit")) & @CRLF)
;~ 					EndIf
				EndIf
			EndIf

			$sDriverCurrent = _WD_GetWebDriverVersion($sInstallDir, $sDriverEXE)

			; Determine latest available webdriver version for the designated browser
			Switch $sBrowser
				Case 'chrome'
					$sVersionShort = StringLeft($sBrowserVersion, StringInStr($sBrowserVersion, ".", 0, -1) - 1)
					$sDriverLatest = BinaryToString(InetRead('https://chromedriver.storage.googleapis.com/LATEST_RELEASE_' & $sVersionShort))
					$sURLNewDriver = "https://chromedriver.storage.googleapis.com/" & $sDriverLatest & "/chromedriver_win32.zip"

				Case 'firefox'
					$sResult = BinaryToString(InetRead("https://github.com/mozilla/geckodriver/releases/latest"))

					If @error = $_WD_ERROR_Success Then
						$sDriverLatest = StringRegExp($sResult, '<a.*href="\/mozilla\/geckodriver\/releases\/tag\/(.*?)"', 1)[0]
						If StringLeft($sDriverLatest, 1) = 'v' Then $sDriverLatest = StringMid($sDriverLatest, 2)

						$sURLNewDriver = "https://github.com/mozilla/geckodriver/releases/download/v" & $sDriverLatest & "/geckodriver-v" & $sDriverLatest
						$sURLNewDriver &= ($bFlag64) ? "-win64.zip" : "-win32.zip"
					Else
						$iErr = $_WD_ERROR_GeneralError
					EndIf

				Case 'msedge'
					$sVersionShort = StringLeft($sBrowserVersion, StringInStr($sBrowserVersion, ".") - 1)
					$sDriverLatest = InetRead('https://msedgedriver.azureedge.net/LATEST_RELEASE_' & $sVersionShort)

					If @error = $_WD_ERROR_Success Then
						Select
							Case BinaryMid($sDriverLatest, 1, 4) = '0x0000FEFF'                   ; UTF-32 BE
								$iStartPos = 5
								$iConversion = $SB_UTF16LE
							Case BinaryMid($sDriverLatest, 1, 4) = '0xFFFE0000'                   ; UTF-32 LE
								$iStartPos = 5
								$iConversion = $SB_UTF16LE
							Case BinaryMid($sDriverLatest, 1, 2) = '0xFEFF'                       ; UTF-16 BE
								$iStartPos = 3
								$iConversion = $SB_UTF16BE
							Case BinaryMid($sDriverLatest, 1, 2) = '0xFFFE'                       ; UTF-16 LE
								$iStartPos = 3
								$iConversion = $SB_UTF16LE
							Case BinaryMid($sDriverLatest, 1, 3) = '0xEFBBBF'                     ; UTF-8
								$iStartPos = 4
								$iConversion = $SB_UTF8
							Case Else
								$iStartPos = 1
								$iConversion = $SB_ANSI
						EndSelect

						$sDriverLatest = StringStripWS(BinaryToString(BinaryMid($sDriverLatest, $iStartPos), $iConversion), $STR_STRIPTRAILING)
						$sURLNewDriver = "https://msedgedriver.azureedge.net/" & $sDriverLatest & "/edgedriver_"
						$sURLNewDriver &= ($bFlag64) ? "win64.zip" : "win32.zip"
					Else
						$iErr = $_WD_ERROR_GeneralError
					EndIf
			EndSwitch

			If $iErr = $_WD_ERROR_Success Then
				Local $bUpdateAvail = (_VersionCompare($sDriverCurrent, $sDriverLatest) < 0) ; 0 - Both versions equal ; 1 - Version1 greater ; -1 - Version2 greater

				; When $bForce parameter equals Null, then return True if newer driver is available
				If IsKeyword($bForce) = $KEYWORD_NULL And $bUpdateAvail Then
					$bResult = True
				ElseIf $bUpdateAvail Or $bForce Then
					$sTempFile = _TempFile($sInstallDir, "webdriver_", ".zip")
					_WD_DownloadFile($sURLNewDriver, $sTempFile)

					; Close any instances of webdriver and delete from disk
					__WD_CloseDriver($sDriverEXE)
					FileDelete($sInstallDir & $sDriverEXE)

					; Handle COM Errors
					Local $oErr = ObjEvent("AutoIt.Error", __WD_ErrHnd)
					#forceref $oErr

					; Extract new instance of webdriver
					$oShell = ObjCreate("Shell.Application")
					If @error Then
						$iErr = $_WD_ERROR_GeneralError
					Else
						$FilesInZip = $oShell.NameSpace($sTempFile).items
						If @error Then
							$iErr = $_WD_ERROR_GeneralError
						Else
							For $FileItem In $FilesInZip ; Check the files in the archive separately
								If StringRight($FileItem.Name, 4) = ".exe" Then ; extract only EXE files
									$oShell.NameSpace($sInstallDir).CopyHere($FileItem, 20) ; 20 = (4) Do not display a progress dialog box. + (16) Respond with "Yes to All" for any dialog box that is displayed.
								EndIf
							Next
							If @error Then
								$iErr = $_WD_ERROR_GeneralError
							Else
								$iErr = $_WD_ERROR_Success
								$bResult = True
							EndIf
						EndIf
					EndIf

					FileDelete($sTempFile)
				EndIf
			EndIf
		EndIf

		; Restore prior setting
		$_WD_DEBUG = $WDDebugSave
	EndIf

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
;~ 		__WD_ConsoleWrite($sFuncName & ': Local File = ' & $sInstallDir & $sDriverEXE & @CRLF)
;~ 		__WD_ConsoleWrite($sFuncName & ': URLNewDriver = ' & $sURLNewDriver & @CRLF)
		__WD_ConsoleWrite($sFuncName & ': DriverCurrent = ' & $sDriverCurrent & ' : DriverLatest = ' & $sDriverLatest & @CRLF)
		__WD_ConsoleWrite($sFuncName & ': Error = ' & $iErr & ' : Result = ' & $bResult & @CRLF)
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr), 0, $bResult)
EndFunc   ;==>_WD_UpdateDriver

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_GetBrowserVersion
; Description ...: Get version number of specified browser.
; Syntax ........: _WD_GetBrowserVersion($sBrowser)
; Parameters ....: $sBrowser - a string value. 'chrome', 'firefox', 'msedge'
; Return values .: Success - Version number ("#.#.#.#" format) returned by FileGetVersion for the browser exe
;                  Failure - "0" and sets @error to one of the following values:
;                  - $_WD_ERROR_InvalidValue
;                  - $_WD_ERROR_NotFound
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......:
; Related .......: _WD_GetWebDriverVersion
; Link ..........:
; Example .......: MsgBox(0, "", _WD_GetBrowserVersion('chrome'))
; ===============================================================================================================================
Func _WD_GetBrowserVersion($sBrowser)
	Local Const $sFuncName = "_WD_GetBrowserVersion"
	Local Const $cRegKey = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\'
	Local $sEXE, $sBrowserVersion = "0"
	Local $iErr = $_WD_ERROR_Success
	Switch $sBrowser
		Case 'chrome'
			$sEXE = "chrome.exe"
		Case 'firefox'
			$sEXE = "firefox.exe"
		Case 'msedge'
			$sEXE = "msedge.exe"
		Case Else
			$iErr = $_WD_ERROR_InvalidValue
	EndSwitch

	If $iErr = $_WD_ERROR_Success Then
		Local $sPath = RegRead($cRegKey & $sEXE, "")
		If @error Then
			$iErr = $_WD_ERROR_NotFound
		Else
			$sBrowserVersion = FileGetVersion($sPath)
		EndIf
	EndIf
	Return SetError(__WD_Error($sFuncName, $iErr), 0, $sBrowserVersion)
EndFunc   ;==>_WD_GetBrowserVersion

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_GetWebDriverVersion
; Description ...: Get version number of specifed webdriver.
; Syntax ........: _WD_GetWebDriverVersion($sInstallDir, $sDriverEXE)
; Parameters ....: $sInstallDir - a string value. Directory where $sDriverEXE is located
;                  $sDriverEXE  - a string value. File name of "WebDriver.exe"
; Return values .: Success - The value you get when you call WebDriver with the --version parameter
;                  Failure - "0" and sets @error to one of the following values:
;                  - $_WD_ERROR_NotFound
;                  - $_WD_ERROR_GeneralError
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......:
; Related .......: _WD_GetBrowserVersion
; Link ..........:
; Example .......: MsgBox(0, "", _WD_GetWebDriverVersion(@ScriptDir,'chromedriver.exe'))
; ===============================================================================================================================
Func _WD_GetWebDriverVersion($sInstallDir, $sDriverEXE)
	Local Const $sFuncName = "_WD_GetWebDriverVersion"
	Local $sDriverVersion = "0"
	Local $iErr = $_WD_ERROR_Success

	$sInstallDir = StringRegExpReplace($sInstallDir, '(?i)(\\)\Z', '') & '\' ; prevent double \\ on the end of directory
	If Not FileExists($sInstallDir & $sDriverEXE) Then
		$iErr = $_WD_ERROR_NotFound
	Else
		Local $sCmd = $sInstallDir & $sDriverEXE & " --version"
		Local $iPID = Run($sCmd, $sInstallDir, @SW_HIDE, $STDOUT_CHILD)
		If @error Then $iErr = $_WD_ERROR_GeneralError

		If $iPID Then
			ProcessWaitClose($iPID)
			Local $sOutput = StdoutRead($iPID)
			$sDriverVersion = StringRegExp($sOutput, "\s+([^\s]+)", 1)[0]
		EndIf
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr), 0, $sDriverVersion)
EndFunc   ;==>_WD_GetWebDriverVersion

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_DownloadFile
; Description ...: Download file and save to disk.
; Syntax ........: _WD_DownloadFile($sURL, $sDest[, $iOptions = Default])
; Parameters ....: $sURL     - URL representing file to be downloaded
;                  $sDest    - Full path, including filename, of destination file
;                  $iOptions - [optional] Download options
; Return values .: Success - True (Download succeeded).
;                  Failure - False (Download failed) and sets @error to one of the following values:
;                  - $_WD_ERROR_GeneralError
;                  - $_WD_ERROR_NotFound
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_DownloadFile($sURL, $sDest, $iOptions = Default)
	Local Const $sFuncName = "_WD_DownloadFile"
	Local $bResult = False
	Local $iErr = $_WD_ERROR_Success

	If $iOptions = Default Then $iOptions = $INET_FORCERELOAD + $INET_IGNORESSL + $INET_BINARYTRANSFER

	Local $sData = InetRead($sURL, $iOptions)
	If @error Then $iErr = $_WD_ERROR_GeneralError

	If $iErr = $_WD_ERROR_Success Then
		Local $hFile = FileOpen($sDest, $FO_OVERWRITE + $FO_BINARY)

		If $hFile <> -1 Then
			FileWrite($hFile, $sData)
			FileClose($hFile)

			$bResult = True
		Else
			$iErr = $_WD_ERROR_GeneralError
		EndIf
	Else
		$iErr = $_WD_ERROR_NotFound
	EndIf

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & $iErr & @CRLF)
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr), 0, $bResult)
EndFunc   ;==>_WD_DownloadFile

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_SetTimeouts
; Description ...: User friendly function to set webdriver session timeouts.
; Syntax ........: _WD_SetTimeouts($sSession[, $iPageLoad = Default[, $iScript = Default[, $iImplicitWait = Default]]])
; Parameters ....: $sSession      - Session ID from _WD_CreateSession
;                  $iPageLoad     - [optional] Page load timeout in milliseconds
;                  $iScript       - [optional] Script timeout in milliseconds
;                  $iImplicitWait - [optional] Implicit wait timeout in milliseconds
; Return values .: Success - Return value from web driver in JSON format.
;                  Failure - 0 and sets @error to one of the following values:
;                  - $_WD_ERROR_InvalidArgue
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_InvalidDataType
; Author ........: Danp2
; Modified ......:
; Remarks .......: $iScript parameter can be null, implies that scripts should never be interrupted, but instead run indefinitely
;                  When setting page load timeout, WinHTTP receive timeout is automatically adjusted as well
; Related .......: _WD_Timeouts
; Link ..........: https://www.w3.org/TR/webdriver/#set-timeouts
; Example .......: _WD_SetTimeouts($sSession, 50000)
; ===============================================================================================================================
Func _WD_SetTimeouts($sSession, $iPageLoad = Default, $iScript = Default, $iImplicitWait = Default)
	Local Const $sFuncName = "_WD_SetTimeouts"
	Local $sTimeouts = '', $sResult = 0, $bIsNull, $iErr

	; Build string to pass to _WD_Timeouts
	If $iPageLoad <> Default Then
		If Not IsInt($iPageLoad) Then
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(int) $vValue: " & $iPageLoad), 0, 0)
		EndIf

		$sTimeouts &= '"pageLoad":' & $iPageLoad
	EndIf

	If $iScript <> Default Then
		$bIsNull = (IsKeyword($iScript) = $KEYWORD_NULL)
		If Not IsInt($iScript) And Not $bIsNull Then
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(int) $vValue: " & $iScript), 0, 0)
		EndIf

		If StringLen($sTimeouts) Then $sTimeouts &= ", "
		$sTimeouts &= '"script":'
		$sTimeouts &= ($bIsNull) ? "null" : $iScript
	EndIf

	If $iImplicitWait <> Default Then
		If Not IsInt($iImplicitWait) Then
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(int) $vValue: " & $iImplicitWait), 0, 0)
		EndIf

		If StringLen($sTimeouts) Then $sTimeouts &= ", "
		$sTimeouts &= '"implicit":' & $iImplicitWait
	EndIf

	If StringLen($sTimeouts) Then
		$sTimeouts = "{" & $sTimeouts & "}"

		; Set webdriver timeouts
		$sResult = _WD_Timeouts($sSession, $sTimeouts)
		$iErr = @error

		If $iErr = $_WD_ERROR_Success And $iPageLoad <> Default Then
			; Adjust WinHTTP receive timeouts to prevent send/recv errors
			$_WD_HTTPTimeOuts[3] = $iPageLoad + 1000
		EndIf
	Else
		$iErr = $_WD_ERROR_InvalidArgue
	EndIf

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & $iErr & @CRLF)
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr), 0, $sResult)
EndFunc   ;==>_WD_SetTimeouts

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_GetElementById
; Description ...: Locate element by id.
; Syntax ........: _WD_GetElementById($sSession, $sID)
; Parameters ....: $sSession - Session ID from _WD_CreateSession
;                  $sID      - ID of desired element
; Return values .: Success - Element ID returned by web driver.
;                  Failure - "" (empty string) and sets @error to one of the following values:
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_NoMatch
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......: _WD_FindElement
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_GetElementById($sSession, $sID)
	Local Const $sFuncName = "_WD_GetElementById"

	Local $sXpath = '//*[@id="' & $sID & '"]'
	Local $sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, $sXpath)
	Local $iErr = @error

	Return SetError(__WD_Error($sFuncName, $iErr), 0, $sElement)
EndFunc   ;==>_WD_GetElementById

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_GetElementByName
; Description ...: Locate element by name.
; Syntax ........: _WD_GetElementByName($sSession, $sName)
; Parameters ....: $sSession - Session ID from _WD_CreateSession
;                  $sName    - Name of desired element
; Return values .: Success - Element ID returned by web driver
;                  Failure - "" (empty string) and sets @error to one of the following values:
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_NoMatch
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......: _WD_FindElement
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_GetElementByName($sSession, $sName)
	Local Const $sFuncName = "_WD_GetElementByName"

	Local $sXpath = '//*[@name="' & $sName & '"]'
	Local $sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, $sXpath)
	Local $iErr = @error

	Return SetError(__WD_Error($sFuncName, $iErr), 0, $sElement)
EndFunc   ;==>_WD_GetElementByName

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_SetElementValue
; Description ...: Set value of designated element.
; Syntax ........: _WD_SetElementValue($sSession, $sElement, $sValue[, $iStyle = Default])
; Parameters ....: $sSession - Session ID from _WD_CreateSession
;                  $sElement - Element ID from _WD_FindElement
;                  $sValue   - New value for element
;                  $iStyle   - [optional] Update style. Default is $_WD_OPTION_Standard
;                  |$_WD_OPTION_Standard (0) = Set value using _WD_ElementAction
;                  |$_WD_OPTION_Advanced (1) = Set value using _WD_ExecuteScript
; Return values .: Success - Requested data returned by web driver
;                  Failure - "" (empty string) and sets @error to one of the following values:
;                  - $_WD_ERROR_NoMatch
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_InvalidDataType
;                  - $_WD_ERROR_InvalidExpression
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......: _WD_ElementAction
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_SetElementValue($sSession, $sElement, $sValue, $iStyle = Default)
	Local Const $sFuncName = "_WD_SetElementValue"
	Local $sResult, $iErr, $sScript, $sJsonElement

	If $iStyle = Default Then $iStyle = $_WD_OPTION_Standard
	If $iStyle < $_WD_OPTION_Standard Or $iStyle > $_WD_OPTION_Advanced Then $iStyle = $_WD_OPTION_Standard

	Switch $iStyle
		Case $_WD_OPTION_Standard
			$sResult = _WD_ElementAction($sSession, $sElement, 'value', $sValue)
			$iErr = @error

		Case $_WD_OPTION_Advanced
			$sScript = "Object.getOwnPropertyDescriptor(arguments[0].__proto__, 'value').set.call(arguments[0], arguments[1]);arguments[0].dispatchEvent(new Event('input', { bubbles: true }));"
			$sJsonElement = __WD_JsonElement($sElement)
			$sResult = _WD_ExecuteScript($sSession, $sScript, $sJsonElement & ',"' & $sValue & '"')
			$iErr = @error

	EndSwitch

	Return SetError(__WD_Error($sFuncName, $iErr), 0, $sResult)
EndFunc   ;==>_WD_SetElementValue

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_ElementActionEx
; Description ...: Perform advanced action on desginated element.
; Syntax ........: _WD_ElementActionEx($sSession, $sElement, $sCommand[, $iXOffset = Default[, $iYOffset = Default[, $iButton = Default[, $iHoldDelay = Default[, $sModifier = Default]]]]])
; Parameters ....: $sSession   - Session ID from _WD_CreateSession
;                  $sElement   - Element ID from _WD_FindElement
;                  $sCommand   - one of the following actions:
;                  |
;                  |CHECK - Checks a checkbox input element
;                  |CHILDCOUNT - Returns the number of child elements
;                  |CLICKANDHOLD - Clicks on the target element and holds the button down for the designated timeframe ($iHoldDelay)
;                  |DOUBLECLICK - Do a double click on the selected element
;                  |HIDE - Change the element's style to 'display: none' to hide the element
;                  |HOVER - Move the mouse pointer so that it is located above the target element
;                  |MODIFIERCLICK - Holds down a modifier key on the keyboard before clicking on the target element. This can be used to perform advanced actions such as shift-clicking an element
;                  |RIGHTCLICK - Do a rightclick on the selected element
;                  |SHOW - Change the element's style to 'display: normal' to unhide/show the element
;                  |UNCHECK - Unchecks a checkbox input element
;                  $iXOffset   - [optional] X Offset. Default is 0
;                  $iYOffset   - [optional] Y Offset. Default is 0
;                  $iButton    - [optional] Mouse button. Default is 0
;                  $iHoldDelay - [optional] Hold time in ms. Default is 1000
;                  $sModifier  - [optional] Modifier key. Default is "\uE008" (shift key)
; Return values .: Success - Return value from web driver (could be an empty string)
;                  Failure - "" (empty string) and sets @error to one of the following values:
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_InvalidDataType
; Author ........: Danp2
; Modified ......: TheDcoder, mLipok
; Remarks .......: Moving the mouse pointer above the target element is the first thing to occur for every $sCommand before it gets executed.
;                  There are examples in DemoElements function in wd_demo
; Related .......: _WD_ElementAction, _WD_Action
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_ElementActionEx($sSession, $sElement, $sCommand, $iXOffset = Default, $iYOffset = Default, $iButton = Default, $iHoldDelay = Default, $sModifier = Default)
	Local Const $sFuncName = "_WD_ElementActionEx"
	Local $sAction, $sJavascript, $iErr, $sResult, $sJsonElement, $iActionType = 1

	If $iXOffset = Default Then $iXOffset = 0
	If $iYOffset = Default Then $iYOffset = 0
	If $iButton = Default Then $iButton = 0
	If $iHoldDelay = Default Then $iHoldDelay = 1000
	If $sModifier = Default Then $sModifier = "\uE008" ; shift

	If Not IsInt($iXOffset) Then
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(int) $iXOffset: " & $iXOffset), 0, "")
	EndIf

	If Not IsInt($iButton) Then
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(int) $iButton: " & $iButton), 0, "")
	EndIf

	If Not IsInt($iYOffset) Then
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(int) $iYOffset: " & $iYOffset), 0, "")
	EndIf

	If Not IsInt($iHoldDelay) Then
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(int) $iHoldDelay: " & $iHoldDelay), 0, "")
	EndIf

	Local $sPreAction = '', $sPostAction = '', $sPostHoverAction = ''

	Switch $sCommand
		Case 'hover'

		Case 'doubleclick'
			$sPostHoverAction = ',{"button":' & $iButton & ',"type":"pointerDown"},{"button":' & $iButton & ',"type":"pointerUp"},{"button":' & $iButton & ',"type":"pointerDown"},{"button":' & $iButton & ',"type":"pointerUp"}'

		Case 'rightclick'
			$sPostHoverAction = ',{"button":2,"type":"pointerDown"},{"button":2,"type":"pointerUp"}'

		Case 'clickandhold'
			$sPostHoverAction = ',{"button":' & $iButton & ',"type":"pointerDown"},{"type": "pause", "duration": ' & $iHoldDelay & '},{"button":' & $iButton & ',"type":"pointerUp"}'

		Case 'hide'
			$iActionType = 2
			$sJavascript = "arguments[0].style='display: none'; return true;"

		Case 'show'
			$iActionType = 2
			$sJavascript = "arguments[0].style='display: normal'; return true;"

		Case 'childcount'
			$iActionType = 2
			$sJavascript = "return arguments[0].children.length;"

		Case 'modifierclick'
			; Hold modifier key down
			$sPreAction = '{"type": "key", "id": "keyboard_1", "actions": [{"type": "keyDown", "value": "' & $sModifier & '"}]},'

			; Perform click
			$sPostHoverAction = ',{"button":' & $iButton & ',"type":"pointerDown"}, {"button":' & $iButton & ',"type":"pointerUp"}'

			; Release modifier key
			$sPostAction = ',{"type": "key", "id": "keyboard_2", "actions": [{"type": "keyUp", "value": "' & $sModifier & '"}]}'

		Case 'check'
			ContinueCase
		Case 'uncheck'
			$iActionType = 2
			$sJavascript = "Object.getOwnPropertyDescriptor(arguments[0].__proto__, 'checked').set.call(arguments[0], " & ($sCommand = "check" ? 'true' : 'false') & ");arguments[0].dispatchEvent(new Event('change', { bubbles: true }));"

		Case Else
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(Hover|RightClick|DoubleClick|ClickAndHold|Hide|Show|ChildCount|ModifierClick) $sCommand=>" & $sCommand), 0, "")

	EndSwitch

	Switch $iActionType
		Case 1
			; Build dynamic action string
			$sAction = '{"actions":['

			If $sPreAction Then
				$sAction &= $sPreAction
			EndIf

			; Default "hover" action
			$sAction &= '{"id":"hover","type":"pointer","parameters":{"pointerType":"mouse"},"actions":[{"duration":100,'
			$sAction &= '"x":' & $iXOffset & ',"y":' & $iYOffset & ',"type":"pointerMove","origin":{"ELEMENT":"'
			$sAction &= $sElement & '","' & $_WD_ELEMENT_ID & '":"' & $sElement & '"}}'

			If $sPostHoverAction Then
				$sAction &= $sPostHoverAction
			EndIf

			; Close mouse actions
			$sAction &= "]}"

			If $sPostAction Then
				$sAction &= $sPostAction
			EndIf

			; Close main action
			$sAction &= "]}"

			$sResult = _WD_Action($sSession, 'actions', $sAction)
			$iErr = @error
		Case 2
			$sJsonElement = __WD_JsonElement($sElement)
			$sResult = _WD_ExecuteScript($sSession, $sJavascript, $sJsonElement, Default, $_WD_JSON_Value)
			$iErr = @error
	EndSwitch

	Return SetError(__WD_Error($sFuncName, $iErr), 0, $sResult)
EndFunc   ;==>_WD_ElementActionEx

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_GetTable
; Description ...: Return all elements of a table.
; Syntax ........: _WD_GetTable($sSession, $sBaseElement)
; Parameters ....: $sSession     - Session ID from _WD_CreateSession
;                  $sBaseElement - XPath of the table to return
; Return values .: Success - 2D array.
;                  Failure - "" (empty string) and sets @error to one of the following values:
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_NoMatch
; Author ........: danylarson
; Modified ......: water, danp2
; Remarks .......:
; Related .......: _WD_FindElement, _WD_ElementAction
; Link ..........: https://www.autoitscript.com/forum/topic/191990-webdriver-udf-w3c-compliant-version-01182020/page/18/?tab=comments#comment-1415164
; Example .......: No
; ===============================================================================================================================
Func _WD_GetTable($sSession, $sBaseElement)
	Local Const $sFuncName = "_WD_GetTable"
	Local $aElements, $iLines, $iColumns, $iRow, $iColumn
	Local $sElement, $sHTML

	; Determine if optional UDF is available
	Call("_HtmlTableGetWriteToArray", "")

	If @error = 0xDEAD And @extended = 0xBEEF Then
		$aElements = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, $sBaseElement & "/tbody/tr", "", True) ; Retrieve the number of table rows
		If @error <> $_WD_ERROR_Success Then Return SetError(__WD_Error($sFuncName, @error, "HTTP status = " & $_WD_HTTPRESULT), $_WD_HTTPRESULT, "")

		$iLines = UBound($aElements)
		$aElements = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, $sBaseElement & "/tbody/tr[1]/td", "", True) ; Retrieve the number of table columns by checking the first table row
		If @error <> $_WD_ERROR_Success Then Return SetError(__WD_Error($sFuncName, @error, "HTTP status = " & $_WD_HTTPRESULT), $_WD_HTTPRESULT, "")

		$iColumns = UBound($aElements)
		Local $aTable[$iLines][$iColumns] ; Create the AutoIt array to hold all cells of the table
		$aElements = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, $sBaseElement & "/tbody/tr/td", "", True) ; Retrieve all table cells
		If @error <> $_WD_ERROR_Success Then Return SetError(__WD_Error($sFuncName, @error, "HTTP status = " & $_WD_HTTPRESULT), $_WD_HTTPRESULT, "")

		For $i = 0 To UBound($aElements) - 1
			$iRow = Int($i / $iColumns) ; Calculate row/column of the AutoIt array where to store the cells value
			$iColumn = Mod($i, $iColumns)
			$aTable[$iRow][$iColumn] = _WD_ElementAction($sSession, $aElements[$i], "Text") ; Retrieve text of each table cell
			If @error <> $_WD_ERROR_Success Then Return SetError(__WD_Error($sFuncName, @error, "HTTP status = " & $_WD_HTTPRESULT), $_WD_HTTPRESULT, "")

		Next
	Else
		; Get the table element
		$sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, $sBaseElement)
		If @error <> $_WD_ERROR_Success Then Return SetError(__WD_Error($sFuncName, @error, "HTTP status = " & $_WD_HTTPRESULT), $_WD_HTTPRESULT, "")

		; Retrieve its HTML
		$sHTML = _WD_ElementAction($sSession, $sElement, "Property", "outerHTML")
		If @error <> $_WD_ERROR_Success Then Return SetError(__WD_Error($sFuncName, @error, "HTTP status = " & $_WD_HTTPRESULT), $_WD_HTTPRESULT, "")

		; Convert to array
		$aTable = _HtmlTableGetWriteToArray($sHTML, 1, False, $_WD_IFILTER)
	EndIf

	Return $aTable
EndFunc   ;==>_WD_GetTable

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_IsFullScreen
; Description ...: Return a boolean indicating if the session is in full screen mode.
; Syntax ........: _WD_IsFullScreen($sSession)
; Parameters ....: $sSession - Session ID from _WD_CreateSession
; Return values .: Success - True or False.
;                  Failure - Response from webdriver and sets @error returned from _WD_ExecuteScript()
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......:
; Related .......:
; Link ..........: https://www.autoitscript.com/forum/topic/205553-webdriver-udf-help-support-iii/?do=findComment&comment=1480527
; Example .......: No
; ===============================================================================================================================
Func _WD_IsFullScreen($sSession)
	Local Const $sFuncName = "_WD_IsFullScreen"
	Local $bResult = _WD_ExecuteScript($sSession, 'return screen.width == window.innerWidth and screen.height == window.innerHeight;', Default, Default, $_WD_JSON_Value)
	Local $iErr = @error
	Return SetError(__WD_Error($sFuncName, $iErr), 0, $bResult)
EndFunc   ;==>_WD_IsFullScreen

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_CheckContext
; Description ...: Check if browser context is still valid.
; Syntax ........: _WD_CheckContext($sSession[, $bReconnect = Default[, $vTarget = Default]])
; Parameters ....: $sSession   - Session ID from _WD_CreateSession
;                  $bReconnect - [optional] Auto reconnect? Default is True
;                  $vTarget    - [optional] Tab to target in reconnect attempt. Default is $_WD_TARGET_FirstTab. This can be the handle for an existing tab if known
; Return values .: Success - Returns one of the following values:
;                  |$_WD_STATUS_Valid (1) - Current browser context is valid
;                  |$_WD_STATUS_Reconnect (2) - Context was invalid; Successfully reconnected to existing tab
;                  Failure - $_WD_STATUS_Invalid (0) and sets @error to $_WD_ERROR_Exception
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......: _WD_Action, _WD_Window
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_CheckContext($sSession, $bReconnect = Default, $vTarget = Default)
	Local Const $sFuncName = "_WD_CheckContext"
	Local $iResult = $_WD_STATUS_Invalid

	If $bReconnect = Default Then $bReconnect = True
	If $vTarget = Default Then $vTarget = $_WD_TARGET_FirstTab

	_WD_Action($sSession, 'url')
	Local $iErr = @error

	If $iErr = $_WD_ERROR_Success Then
		$iResult = $_WD_STATUS_Valid

	ElseIf $iErr = $_WD_ERROR_Exception Then
		If $bReconnect Then
			If IsInt($vTarget) Then
				; To recover, get an array of window handles and use one
				Local $aHandles = _WD_Window($sSession, "handles")

				If @error = $_WD_ERROR_Success And IsArray($aHandles) Then
					Select
						Case $vTarget = $_WD_TARGET_FirstTab
							$vTarget = $aHandles[0]

						Case $vTarget = $_WD_TARGET_LastTab
							$vTarget = $aHandles[UBound($aHandles) - 1]

					EndSelect
				EndIf
			EndIf

			_WD_Window($sSession, "switch", '{"handle":"' & $vTarget & '"}')

			If @error = $_WD_ERROR_Success Then
				$iResult = $_WD_STATUS_Reconnect
			EndIf
		EndIf
	EndIf

	Return SetError(__WD_Error($sFuncName, ($iResult) ? $_WD_ERROR_Success : $_WD_ERROR_Exception), 0, $iResult)
EndFunc   ;==>_WD_CheckContext

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: __WD_Base64Decode
; Description ...: Decodes Base64 strings into binary.
; Syntax ........: __WD_Base64Decode($input_string)
; Parameters ....: $input_string - string to be decoded
; Return values .: Decoded string
; Author ........: trancexx
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........: https://www.autoitscript.com/forum/topic/81332-_base64encode-_base64decode/
; Example .......: No
; ===============================================================================================================================
Func __WD_Base64Decode($input_string)

	Local $struct = DllStructCreate("int")

	Local $a_Call = DllCall("Crypt32.dll", "int", "CryptStringToBinary", _
			"str", $input_string, _
			"int", 0, _
			"int", 1, _
			"ptr", 0, _
			"ptr", DllStructGetPtr($struct, 1), _
			"ptr", 0, _
			"ptr", 0)

	If @error Or Not $a_Call[0] Then
		Return SetError(1, 0, "") ; error calculating the length of the buffer needed
	EndIf

	Local $a = DllStructCreate("byte[" & DllStructGetData($struct, 1) & "]")

	$a_Call = DllCall("Crypt32.dll", "int", "CryptStringToBinary", _
			"str", $input_string, _
			"int", 0, _
			"int", 1, _
			"ptr", DllStructGetPtr($a), _
			"ptr", DllStructGetPtr($struct, 1), _
			"ptr", 0, _
			"ptr", 0)

	If @error Or Not $a_Call[0] Then
		Return SetError(2, 0, "") ; error decoding
	EndIf

	Return DllStructGetData($a, 1)

EndFunc   ;==>__WD_Base64Decode

Func __WD_ErrHnd()

EndFunc   ;==>__WD_ErrHnd

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_JsonElement
; Description ...: Convert Element ID into JSON string
; Syntax ........: __WD_JsonElement($sElement)
; Parameters ....: $sElement - Element ID from _WD_FindElement
; Return values .: Formatted JSON string
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WD_JsonElement($sElement)
	Return '{"' & $_WD_ELEMENT_ID & '":"' & $sElement & '"}'
EndFunc   ;==>__WD_JsonElement

