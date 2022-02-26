#include-once
; standard UDF's
#include <File.au3> ; Needed For _WD_UpdateDriver
#include <InetConstants.au3>
#include <Misc.au3> ; Needed For _WD_UpdateDriver >> _VersionCompare
#include <WinAPIFiles.au3> ; Needed For _WD_UpdateDriver >> _WinAPI_GetBinaryType and _WD_DownloadFile >> _WinAPI_FileInUse

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
	- Jonathan Bennett (@Jon) and the AutoIt Team
	- Thorsten Willert (@Stilgar), author of FF.au3, which I've used as a model
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

Global Enum _
		$_WD_BUTTON_Left = 0, _
		$_WD_BUTTON_Middle = 1, _
		$_WD_BUTTON_Right = 2
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
;                  $sSelector - Indicates how the WebDriver should traverse through the HTML DOM to locate the desired element(s).
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
; Description ...: Returns the number of frames/iframes in the current document context.
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
; Description ...: Returns a boolean of the session being at the top level, or in a frame(s).
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
; Description ...: Enter the specified frame.
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
; Description ...: Leave the current frame, to its parent.
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
; Description ...: Highlights the specified element. <B>[Deprecated]</B>
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
; Modified ......: mLipok, Danp2
; Remarks .......: This function will be removed in a future release. Update your code to use _WD_HighlightElements instead.
; Related .......: _WD_HighlightElements
; Link ..........: https://www.autoitscript.com/forum/topic/192730-webdriver-udf-help-support/?do=findComment&comment=1396643
; Example .......: No
; ===============================================================================================================================
Func _WD_HighlightElement($sSession, $sElement, $iMethod = Default)
	Local Const $sFuncName = "_WD_HighlightElement"

	Local $bResult = _WD_HighlightElements($sSession, $sElement, $iMethod)
	Local $iErr = @error

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & $bResult & @CRLF)
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr), $_WD_HTTPRESULT, $bResult)
EndFunc   ;==>_WD_HighlightElement

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_HighlightElements
; Description ...: Highlights the specified elements.
; Syntax ........: _WD_HighlightElements($sSession, $vElements[, $iMethod = Default])
; Parameters ....: $sSession  - Session ID from _WD_CreateSession
;                  $vElements - Element ID from _WD_FindElement (single element as string; multiple elements as array)
;                  $iMethod   - [optional] an integer value to set the style (default = 1)
;                  0 - Remove highlight
;                  1 - Highlight border dotted red
;                  2 - Highlight yellow rounded box
;                  3 - Highlight yellow rounded box + border  dotted red
; Return values .: Success - True
;                  Failure - False and sets @error to _WD_ERROR_InvalidArgue or the error code from _WD_ExecuteScript()
; Author ........: Danyfirex
; Modified ......: mLipok, Danp2
; Remarks .......:
; Related .......:
; Link ..........: https://www.autoitscript.com/forum/topic/192730-webdriver-udf-help-support/?do=findComment&comment=1396643
; Example .......: No
; ===============================================================================================================================
Func _WD_HighlightElements($sSession, $vElements, $iMethod = Default)
	Local Const $sFuncName = "_WD_HighlightElements"
	Local Const $aMethod[] = _
			[ _
			"border: 0px;", _
			"border: 2px dotted red;", _
			"background: #FFFF66; border-radius: 5px; padding-left: 3px;", _
			"border: 2px dotted red; background: #FFFF66; border-radius: 5px; padding-left: 3px;" _
			]
	Local $sScript, $sResult, $iErr, $sElements

	If $iMethod = Default Then $iMethod = 1
	If $iMethod < 0 Or $iMethod > 3 Then $iMethod = 1

	If IsString($vElements) Then
		$sScript = "arguments[0].style='" & $aMethod[$iMethod] & "'; return true;"
		$sResult = _WD_ExecuteScript($sSession, $sScript, __WD_JsonElement($vElements), Default, $_WD_JSON_Value)
		$iErr = @error

	ElseIf IsArray($vElements) And UBound($vElements) > 0 Then
		For $i = 0 To UBound($vElements) - 1
			$vElements[$i] = __WD_JsonElement($vElements[$i])
		Next

		$sElements = "[" & _ArrayToString($vElements, ",") & "]"
		$sScript = "for (var i = 0, max = arguments[0].length; i < max; i++) { arguments[0][i].style = '" & $aMethod[$iMethod] & "'; }; return true;"
		$sResult = _WD_ExecuteScript($sSession, $sScript, $sElements, Default, $_WD_JSON_Value)
		$iErr = @error
	Else
		$iErr = $_WD_ERROR_InvalidArgue
	EndIf

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & $sResult & @CRLF)
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr), $_WD_HTTPRESULT, ($iErr = $_WD_ERROR_Success))
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
; Syntax ........: _WD_Screenshot($sSession[, $sElement = Default[, $iOutputType = Default]])
; Parameters ....: $sSession    - Session ID from _WD_CreateSession
;                  $sElement    - [optional] Element ID from _WD_FindElement
;                  $iOutputType - [optional] One of the following output types:
;                  |1 - String (Default)
;                  |2 - Binary
;                  |3 - Base64
; Return values .: Success - Output of specified type (PNG format).
;                  Failure - "" (empty string) and sets @error to one of the following values:
;                  - $_WD_ERROR_NoMatch
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_GeneralError
;                  - $_WD_ERROR_InvalidDataType
;                  - $_WD_ERROR_InvalidExpression
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......:
; Related .......: _WD_Window, _WD_ElementAction
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_Screenshot($sSession, $sElement = Default, $iOutputType = Default)
	Local Const $sFuncName = "_WD_Screenshot"
	Local $sResponse, $vResult = "", $iErr, $dBinary

	If $sElement = Default Then $sElement = ""
	If $iOutputType = Default Then $iOutputType = 1

	If $sElement = '' Then
		$sResponse = _WD_Window($sSession, 'Screenshot')
	Else
		$sResponse = _WD_ElementAction($sSession, $sElement, 'Screenshot')
	EndIf
	$iErr = @error

	If $iErr = $_WD_ERROR_Success Then
		If $iOutputType < 3 Then
			$dBinary = __WD_Base64Decode($sResponse)
			If @error Then $iErr = $_WD_ERROR_GeneralError
		EndIf
		If $iErr = $_WD_ERROR_Success Then ; Recheck after __WD_Base64Decode() usage
			Switch $iOutputType
				Case 1 ; String
					$vResult = BinaryToString($dBinary)
				Case 2 ; Binary
					$vResult = $dBinary
				Case 3 ; Base64
					$vResult = $sResponse
			EndSwitch
		EndIf
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr), 0, $vResult)
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
;                  $sSelector     - Indicates how the WebDriver should traverse through the HTML DOM to locate the desired element(s).  Should point to <option> in element of type '<select>'
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
; Description ...: Perform action on desginated <select> element.
; Syntax ........: _WD_ElementSelectAction($sSession, $sSelectElement, $sCommand)
; Parameters ....: $sSession       - Session ID from _WD_CreateSession
;                  $sSelectElement - Element ID of <select> element from _WD_FindElement
;                  $sCommand       - Action to be performed. Can be one of the following:
;                  |OPTIONS        - Retrieves all <option> elements as 2D array containing 4 columns (value, label, index and selected status)
;                  |SELECTEDINDEX  - Retrieves 0-based index of the first selected <option> element
;                  |VALUE          - Retrieves value of the first selected <option> element
; Return values .: Success - Requested data returned by web driver.
;                  Failure - "" (empty string) and sets @error to one of the following values:
;                  - $_WD_ERROR_NoMatch
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_InvalidDataType
;                  - $_WD_ERROR_InvalidExpression
;                  - $_WD_ERROR_InvalidArgue
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......: If no option is selected, SELECTEDINDEX will return -1
; Related .......: _WD_FindElement, _WD_ExecuteScript
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_ElementSelectAction($sSession, $sSelectElement, $sCommand)
	Local Const $sFuncName = "_WD_ElementSelectAction"
	Local $sNodeName, $vResult, $sScript
	$sNodeName = _WD_ElementAction($sSession, $sSelectElement, 'property', 'nodeName')
	Local $iErr = @error

	If $iErr = $_WD_ERROR_Success Then
		If $sNodeName = 'select' Then ; check if designated element is <select> element
			Switch $sCommand
				Case 'options'
					$sScript = "var result ='' ; var options = arguments[0].options; for (let i = 0; i < options.length; i++) {result += options[i].value + '|' + options[i].label + '|' + options[i].index + '|' + options[i].selected + '\n'} return result;"
					$vResult = _WD_ExecuteScript($sSession, $sScript, __WD_JsonElement($sSelectElement), Default, $_WD_JSON_Value)
					$iErr = @error

					If $iErr = $_WD_ERROR_Success Then
						Local $aAllOptions[0][4]
						_ArrayAdd($aAllOptions, StringStripWS($vResult, $STR_STRIPTRAILING), 0, Default, @LF, $ARRAYFILL_FORCE_SINGLEITEM)
						$vResult = $aAllOptions
					EndIf

				Case 'selectedIndex'
					$sScript = "return arguments[0].selectedIndex"
					$vResult = _WD_ExecuteScript($sSession, $sScript, __WD_JsonElement($sSelectElement), Default, $_WD_JSON_Value)
					$iErr = @error

				Case 'value'
					$sScript = "return arguments[0].value"
					$vResult = _WD_ExecuteScript($sSession, $sScript, __WD_JsonElement($sSelectElement), Default, $_WD_JSON_Value)
					$iErr = @error

				Case Else
					Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(options|selectedIndex|value) $sCommand=>" & $sCommand), 0, "")

			EndSwitch
		Else
			$iErr = $_WD_ERROR_InvalidArgue
		EndIf
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
;                  $sSelector     - Indicates how the WebDriver should traverse through the HTML DOM to locate the desired element(s).
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
;                  $sSelector - Indicates how the WebDriver should traverse through the HTML DOM to locate the desired element(s). Should point to element of type '< input type="file" >'.
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

	Local $sResult = "0", $sSavedEscape
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
			$sResult = _WD_ExecuteScript($sSession, "return arguments[0].files.length", __WD_JsonElement($sElement), Default, $_WD_JSON_Value)
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
	Local Const $sGitURL = "https://github.com/Danp2/au3WebDriver/releases/latest"
	Local $bResult = Null
	Local $iErr = $_WD_ERROR_Success
	Local $sRegex = '<a.*href="\/Danp2\/au3WebDriver\/releases\/tag\/(.*?)"'

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
; Parameters ....: $sBrowser    - Browser name or full path to browser executable
;                  $sInstallDir - [optional] Install directory. Default is @ScriptDir
;                  $bFlag64     - [optional] Install 64bit version? Default is current driver architecture or False
;                  $bForce      - [optional] Force update? Default is False
; Return values .: Success - True (Driver was updated).
;                  Failure - False (Driver was not updated) and sets @error to one of the following values:
;                  - $_WD_ERROR_InvalidValue
;                  - $_WD_ERROR_GeneralError
;                  - $_WD_ERROR_NotFound
;                  - $_WD_ERROR_FileIssue
;                  - $_WD_ERROR_UserAbort
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
	Local $iErr = $_WD_ERROR_Success, $iExt = 0, $sDriverEXE, $sBrowserVersion, $bResult = False
	Local $sDriverCurrent, $sVersionShort, $sDriverLatest, $sURLNewDriver
	Local $sTempFile, $oShell, $FilesInZip, $sResult, $iStartPos, $iConversion
	Local $bKeepArch = False

	If $sInstallDir = Default Then $sInstallDir = @ScriptDir
	If $bForce = Default Then $bForce = False
	If $bFlag64 = Default Then
		$bFlag64 = False
		$bKeepArch = True
	EndIf

	$sInstallDir = StringRegExpReplace($sInstallDir, '(?i)(\\)\Z', '') & '\' ; prevent double \\ on the end of directory
	Local $bNoUpdate = (IsKeyword($bForce) = $KEYWORD_NULL) ; Flag to track if updates should be performed

	; If the Install directory doesn't exist and it can't be created, then set error
	If (Not FileExists($sInstallDir)) And (Not DirCreate($sInstallDir)) Then
		$iErr = $_WD_ERROR_InvalidValue
	Else
		; Save current debug level and set to none
		Local $WDDebugSave = $_WD_DEBUG
		$_WD_DEBUG = $_WD_DEBUG_None

		$sBrowserVersion = _WD_GetBrowserVersion($sBrowser)
		$iErr = @error

		If @error And FileExists($sBrowser) Then
			; Directly retrieve file version if full path was supplied
			$sBrowserVersion = FileGetVersion($sBrowser)

			If Not @error Then
				; Extract filename and confirm match in list of supported browsers
				$sBrowser = StringRegExpReplace($sBrowser, "^.*\\|\..*$", "")
				If _ArraySearch($_WD_SupportedBrowsers, $sBrowser, Default, Default, Default, Default, Default, $_WD_BROWSER_Name) <> -1 Then _
					$iErr = $_WD_ERROR_Success
			EndIf
		EndIf

		If $iErr = $_WD_ERROR_Success Then
			Local $iIndex = _ArraySearch($_WD_SupportedBrowsers, $sBrowser, Default, Default, Default, Default, Default, $_WD_BROWSER_Name)
			$sDriverEXE = $_WD_SupportedBrowsers[$iIndex][$_WD_BROWSER_DriverName]

			; Determine current local webdriver Architecture
			If FileExists($sInstallDir & $sDriverEXE) Then
				_WinAPI_GetBinaryType($sInstallDir & $sDriverEXE)
				Local $bDriverIs64Bit = (@extended = $SCS_64BIT_BINARY)
				If $bKeepArch Then $bFlag64 = $bDriverIs64Bit
				If $_WD_SupportedBrowsers[$iIndex][$_WD_BROWSER_64Bit] And $bDriverIs64Bit <> $bFlag64 Then
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

				Case 'opera'
					$sResult = BinaryToString(InetRead("https://github.com/operasoftware/operachromiumdriver/releases/latest"))

					If @error = $_WD_ERROR_Success Then
						$sDriverLatest = StringRegExp($sResult, '<a.*href="\/operasoftware\/operachromiumdriver\/releases\/tag\/(.*?)"', 1)[0]
						If StringLeft($sDriverLatest, 1) = 'v' Then $sDriverLatest = StringMid($sDriverLatest, 3)

						$sURLNewDriver = "https://github.com/operasoftware/operachromiumdriver/releases/download/v." & $sDriverLatest & "/operadriver_"
						$sURLNewDriver &= ($bFlag64) ? "win64.zip" : "win32.zip"
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

				If $bNoUpdate Then
					; Set return value to indicate if newer driver is available
					$bResult = $bUpdateAvail
				ElseIf $bUpdateAvail Or $bForce Then
					; @TempDir should be used to avoid potential AV problems, for example by downloading stuff to @DesktopDir
					$sTempFile = _TempFile(@TempDir, "webdriver_", ".zip")
					_WD_DownloadFile($sURLNewDriver, $sTempFile)
					If @error Then
						$iErr = @error
					Else
						; Close any instances of webdriver
						__WD_CloseDriver($sDriverEXE)

						#Region - Extract new instance of webdriver
						; Handle COM Errors
						Local $oErr = ObjEvent("AutoIt.Error", __WD_ErrHnd)
						#forceref $oErr
						$oShell = ObjCreate("Shell.Application")
						If @error Then
							$iErr = $_WD_ERROR_GeneralError
						ElseIf FileGetSize($sTempFile) = 0 Or IsObj($oShell.NameSpace($sTempFile)) = 0 Then
							$iErr = $_WD_ERROR_FileIssue
						Else
							Local $oNameSpace = $oShell.NameSpace($sTempFile)
							$FilesInZip = $oNameSpace.items
							If @error Then
								$iErr = $_WD_ERROR_GeneralError
							Else
								; delete webdriver from disk before unpacking to avoid potential problems
								FileDelete($sInstallDir & $sDriverEXE)
								Local $bEXEWasFound = False
								For $FileItem In $FilesInZip ; Check the files in the archive separately
									; https://docs.microsoft.com/en-us/windows/win32/shell/folderitem
									If StringRight($FileItem.Name, 4) = ".exe" Or StringRight($FileItem.Path, 4) = ".exe" Then ; extract only EXE files
										$bEXEWasFound = True
										$oShell.NameSpace($sInstallDir).CopyHere($FileItem, 20) ; 20 = (4) Do not display a progress dialog box. + (16) Respond with "Yes to All" for any dialog box that is displayed.
									EndIf
								Next
								If @error Then
									$iErr = $_WD_ERROR_GeneralError
								ElseIf Not $bEXEWasFound Then
									$iErr = $_WD_ERROR_FileIssue
									$iExt = 11
								Else
									$iErr = $_WD_ERROR_Success
									$bResult = True
								EndIf
							EndIf
						EndIf
						#EndRegion - Extract new instance of webdriver
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
		__WD_ConsoleWrite($sFuncName & ': Error = ' & $iErr & ' : Extended = ' & $iExt & ' : Result = ' & $bResult & @CRLF)
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr), $iExt, $bResult)
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
	Local $iErr = $_WD_ERROR_Success
	Local $sBrowserVersion = "0"

	Local $sPath = _WD_GetBrowserPath($sBrowser)
	If @error Then
		$iErr = $_WD_ERROR_NotFound
	ElseIf Not FileExists($sPath) Then
		$iErr = $_WD_ERROR_FileIssue
	Else
		$sBrowserVersion = FileGetVersion($sPath)
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr), 0, $sBrowserVersion)
EndFunc   ;==>_WD_GetBrowserVersion

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_GetBrowserPath
; Description ...: Retrieve path to browser executable from registry
; Syntax ........: _WD_GetBrowserPath($sBrowser)
; Parameters ....: $sBrowser - Name of browser
; Return values .: Success - Full path to browser executable
;                  Failure - "" and sets @error to one of the following values:
;                  - $_WD_ERROR_InvalidValue
;                  - $_WD_ERROR_NotFound
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_GetBrowserPath($sBrowser)
	Local Const $sFuncName = "_WD_GetBrowserPath"
	Local Const $sRegKeyCommon = '\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\'
	Local $iErr = $_WD_ERROR_Success
	Local $sEXE, $sPath = ""

	Local $iIndex = _ArraySearch($_WD_SupportedBrowsers, $sBrowser, Default, Default, Default, Default, Default, $_WD_BROWSER_Name)
	If @error Then
		$iErr = $_WD_ERROR_InvalidValue
	Else
		$sEXE = $_WD_SupportedBrowsers[$iIndex][$_WD_BROWSER_ExeName]

		; check HKLM or in case of error HKCU
		$sPath = RegRead("HKLM" & $sRegKeyCommon & $sEXE, "")
		If @error Then $sPath = RegRead("HKCU" & $sRegKeyCommon & $sEXE, "")

		; Generate $_WD_ERROR_NotFound if neither key is found
		If @error Then
			$iErr = $_WD_ERROR_NotFound
		Else
			$sPath = StringRegExpReplace($sPath, '["'']', '') ; Remove quotation marks
			$sPath = StringRegExpReplace($sPath, '(.+\\)(.*exe)', '$1' & $sEXE) ; Registry entries can contain "Launcher.exe" instead "opera.exe"
		EndIf
	EndIf
	Return SetError(__WD_Error($sFuncName, $iErr), 0, $sPath)
EndFunc   ;==>_WD_GetBrowserPath

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
;                  - $_WD_ERROR_NotFound
;                  - $_WD_ERROR_FileIssue
;                  - $_WD_ERROR_Timeout
;                  - $_WD_ERROR_GeneralError
;                  - $_WD_ERROR_UserAbort
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_DownloadFile($sURL, $sDest, $iOptions = Default)
	Local Const $sFuncName = "_WD_DownloadFile"
	Local $bResult = False, $hWaitTimer
	Local $iErr = $_WD_ERROR_Success, $iExt = 0

	If $iOptions = Default Then $iOptions = $INET_FORCERELOAD + $INET_IGNORESSL + $INET_BINARYTRANSFER

	Local $sData = InetRead($sURL, $iOptions)
	If @error Then $iErr = $_WD_ERROR_NotFound

	If $iErr = $_WD_ERROR_Success Then
		Local $hFile = FileOpen($sDest, $FO_OVERWRITE + $FO_BINARY)

		If $hFile <> -1 Then
			FileWrite($hFile, $sData)
			FileClose($hFile)

			$hWaitTimer = TimerInit()
			; make sure that file is not used after download, for example by AV software scanning procedure
			While 1
				__WD_Sleep(100)
				If @error Then
					$iErr = @error
					ExitLoop
				ElseIf Not _WinAPI_FileInUse($sDest) Then
					If @error Then
						$iErr = $_WD_ERROR_FileIssue
						$iExt = 1
					Else
						$bResult = True
					EndIf
					ExitLoop
				ElseIf TimerDiff($hWaitTimer) > $_WD_DefaultTimeout Then
					$iErr = $_WD_ERROR_FileIssue
					$iExt = 2
					ExitLoop
				EndIf
			WEnd
		Else
			$iErr = $_WD_ERROR_GeneralError
		EndIf
	EndIf

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': Error = ' & $iErr & ' : Extended = ' & $iExt & @CRLF)
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr), $iExt, $bResult)
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
	Local $sResult, $iErr, $sScript

	If $iStyle = Default Then $iStyle = $_WD_OPTION_Standard
	If $iStyle < $_WD_OPTION_Standard Or $iStyle > $_WD_OPTION_Advanced Then $iStyle = $_WD_OPTION_Standard

	Switch $iStyle
		Case $_WD_OPTION_Standard
			$sResult = _WD_ElementAction($sSession, $sElement, 'value', $sValue)
			$iErr = @error

		Case $_WD_OPTION_Advanced
			$sScript = "Object.getOwnPropertyDescriptor(arguments[0].__proto__, 'value').set.call(arguments[0], arguments[1]);arguments[0].dispatchEvent(new Event('input', { bubbles: true }));"
			$sResult = _WD_ExecuteScript($sSession, $sScript, __WD_JsonElement($sElement) & ',"' & $sValue & '"')
			$iErr = @error

	EndSwitch

	Return SetError(__WD_Error($sFuncName, $iErr), 0, $sResult)
EndFunc   ;==>_WD_SetElementValue

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_ElementActionEx
; Description ...: Perform advanced action on designated element.
; Syntax ........: _WD_ElementActionEx($sSession, $sElement, $sCommand[, $iXOffset = Default[, $iYOffset = Default[, $iButton = Default[, $iHoldDelay = Default[, $sModifier = Default]]]]])
; Parameters ....: $sSession   - Session ID from _WD_CreateSession
;                  $sElement   - Element ID from _WD_FindElement
;                  $sCommand   - one of the following actions:
;                  |
;                  |CHECK - Checks a checkbox input element
;                  |CHILDCOUNT - Returns the number of child elements
;                  |CLICK - Clicks on the target element
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
;                  $iButton    - [optional] Mouse button. Default is $_WD_BUTTON_Left
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
	Local $sAction, $sJavascript, $iErr, $sResult, $iActionType = 1

	If $iXOffset = Default Then $iXOffset = 0
	If $iYOffset = Default Then $iYOffset = 0
	If $iButton = Default Then $iButton = $_WD_BUTTON_Left
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

		Case 'click'
			$sPostHoverAction = _
					',' & _WD_JsonActionPointer("pointerDown", $iButton) & _
					',' & _WD_JsonActionPointer("pointerUp", $iButton) & _
					''
		Case 'doubleclick'
			$sPostHoverAction = _
					',' & _WD_JsonActionPointer("pointerDown", $iButton) & _
					',' & _WD_JsonActionPointer("pointerUp", $iButton) & _
					',' & _WD_JsonActionPointer("pointerDown", $iButton) & _
					',' & _WD_JsonActionPointer("pointerUp", $iButton) & _
					''
		Case 'rightclick'
			$sPostHoverAction = _
					',' & _WD_JsonActionPointer("pointerDown", $_WD_BUTTON_Right) & _
					',' & _WD_JsonActionPointer("pointerUp", $_WD_BUTTON_Right) & _
					''
		Case 'clickandhold'
			$sPostHoverAction = _
					',' & _WD_JsonActionPointer("pointerDown", $iButton) & _
					',' & _WD_JsonActionPause($iHoldDelay) & _
					',' & _WD_JsonActionPointer("pointerUp", $iButton) & _
					''
		Case 'modifierclick'
			; Hold modifier key down
			$sPreAction = _
					_WD_JsonActionKey("keyDown", $sModifier) & _
					','

			; Perform click
			$sPostHoverAction = _
					',' & _WD_JsonActionPointer("pointerDown", $iButton) & _
					',' & _WD_JsonActionPointer("pointerUp", $iButton) & _
					''

			; Release modifier key
			$sPostAction = _
					',' & _WD_JsonActionKey("keyUp", $sModifier, 2) & _
					''

		Case 'hide'
			$iActionType = 2
			$sJavascript = "arguments[0].style='display: none'; return true;"

		Case 'show'
			$iActionType = 2
			$sJavascript = "arguments[0].style='display: normal'; return true;"

		Case 'childcount'
			$iActionType = 2
			$sJavascript = "return arguments[0].children.length;"

		Case 'check', 'uncheck'
			$iActionType = 2
			$sJavascript = "Object.getOwnPropertyDescriptor(arguments[0].__proto__, 'checked').set.call(arguments[0], " & ($sCommand = "check" ? 'true' : 'false') & ");arguments[0].dispatchEvent(new Event('change', { bubbles: true }));"

		Case Else
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(Hover|RightClick|DoubleClick|Click|ClickAndHold|Hide|Show|ChildCount|ModifierClick|Check|Uncheck) $sCommand=>" & $sCommand), 0, "")

	EndSwitch

	#Region - JSON builder
	; $sActionTemplate declaration is outside the switch to not pollute simplicity of the >Switch ... EndSwitch< - for better code maintenance
	; StringFormat() usage is significantly faster than building JSON string each time from scratch
	; StringReplace() removes all possible @TAB's because they was used only for indentation and are not needed in JSON string
	; This line in compilation process will be linearized, and will be processed once, thus next usage will be significantly faster
	Local Static $sActionTemplate = StringReplace( _
			'{' & _
			'	"actions":[' & _ ; Open main action
			'		%s' & _ ; %s > $sPreAction
			'		{' & _ ; Start of default "hover" action
			'			"id":"hover"' & _
			'			,"type":"pointer"' & _
			'			,"parameters":{"pointerType":"mouse"}' & _
			'			,"actions":[' & _ ; Open mouse actions
			'				{' & _
			'					"type":"pointerMove"' & _
			'					,"duration":100' & _
			'					,"x":%s' & _ ; %s > $iXOffset
			'					,"y":%s' & _ ; %s > $iYOffset
			'					,"origin":{' & _
			'						"ELEMENT":"%s"' & _ ; %s > $sElement
			'						,"' & $_WD_ELEMENT_ID & '":"%s"' & _ ; %s > $sElement
			'					}' & _
			'				}' & _
			'				%s' & _ ; %s > $sPostHoverAction
			'			]' & _ ; Close mouse actions
			'		}' & _ ; End of default 'hover' action
			'		%s' & _ ; %s > $sPostAction
			'	]' & _ ; Close main action
			'}', @TAB, '')
	#EndRegion - JSON builder

	Switch $iActionType
		Case 1
			$sAction = StringFormat($sActionTemplate, $sPreAction, $iXOffset, $iYOffset, $sElement, $sElement, $sPostHoverAction, $sPostAction)
			$sResult = _WD_Action($sSession, 'actions', $sAction)
			$iErr = @error

		Case 2
			$sResult = _WD_ExecuteScript($sSession, $sJavascript, __WD_JsonElement($sElement), Default, $_WD_JSON_Value)
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
; Name ..........: _WD_GetDevicePixelRatio
; Description ...: Returns an integer indicating the DevicePixelRatio
; Syntax ........: _WD_GetDevicePixelRatio($sSession)
; Parameters ....: $sSession - Session ID from _WD_CreateSession
; Return values .: Success - DevicePixelRatio
;                  Failure - Response from webdriver and sets @error returned from _WD_ExecuteScript()
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........: https://developer.mozilla.org/en-US/docs/Web/API/Window/devicePixelRatio
; Example .......: No
; ===============================================================================================================================
Func _WD_GetDevicePixelRatio($sSession)
	Local Const $sFuncName = "_WD_GetDevicePixelRatio"
	Local $sResponse = _WD_ExecuteScript($sSession, "return window.devicePixelRatio", Default, Default, $_WD_JSON_Value)
	Local $iErr = @error
	Return SetError(__WD_Error($sFuncName, $iErr), 0, $sResponse)
EndFunc   ;==>_WD_GetDevicePixelRatio

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

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_JsonActionKey
; Description ...: Formats keyboard "action" strings for use in _WD_Action
; Syntax ........: _WD_JsonActionKey($sType, $sKey[, $iSuffix = 1])
; Parameters ....: $sType      - Type of action (Ex: keyDown, keyUp)
;                  $sKey       - Keystroke to simulate
;                  $iSuffix  - [optional] Value to append to the "id" property. Default is 1.
; Return values .: Requested JSON string
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......: _WD_Action
; Link ..........: https://www.w3.org/TR/webdriver/#actions
; Example .......: No
; ===============================================================================================================================
Func _WD_JsonActionKey($sType, $sKey, $iSuffix = Default)
	Local Const $sFuncName = "_WD_JsonActionKey"

	If $iSuffix = Default Then $iSuffix = 1

	Local $vData = Json_ObjCreate()
	Json_Put($vData, '.type', 'key')
	Json_Put($vData, '.id', 'keyboard_' & $iSuffix)
	Json_Put($vData, '.actions[0].type', $sType)
	Json_Put($vData, '.actions[0].value', $sKey)
	Local $sJSON = Json_Encode($vData)

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & $sJSON & @CRLF)
	EndIf

	Return $sJSON
EndFunc   ;==>_WD_JsonActionKey

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_JsonActionPointer
; Description ...: Formats pointer "action" strings for use in _WD_Action
; Syntax ........: _WD_JsonActionPointer($sType[, $iButton = Default[, $sOrigin = Default[, $iXOffset = Default[, $iYOffset = Default[,
;                  $iDuration = Default]]]]])
; Parameters ....: $sType     - Type of action (Ex: pointerDown, pointerUp, pointerMove)
;                  $iButton   - [optional] Mouse button to simulate. Default is $_WD_BUTTON_Left.
;                  $sOrigin   - [optional] Starting location. ('pointer', 'viewport', or Element ID). Default is 'viewport'.
;                  $iXOffset  - [optional] X offset. Default is 0.
;                  $iYOffset  - [optional] Y offset. Default is 0.
;                  $iDuration - [optional] Duration in ticks. Default is 100.
; Return values .: Requested JSON string
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......: _WD_Action
; Link ..........: https://www.w3.org/TR/webdriver/#actions
; Example .......: No
; ===============================================================================================================================
Func _WD_JsonActionPointer($sType, $iButton = Default, $sOrigin = Default, $iXOffset = Default, $iYOffset = Default, $iDuration = Default)
	Local Const $sFuncName = "_WD_JsonActionPointer"

	If $iButton = Default Then $iButton = $_WD_BUTTON_Left
	If $sOrigin = Default Then $sOrigin = 'viewport'
	If $iXOffset = Default Then $iXOffset = 0
	If $iYOffset = Default Then $iYOffset = 0
	If $iDuration = Default Then $iDuration = 100

	Local $vData = Json_ObjCreate()
	Json_Put($vData, '.type', $sType)

	Switch $sType
		Case 'pointerDown', 'pointerUp'
			Json_Put($vData, '.button', $iButton)

		Case 'pointerMove'
			Json_Put($vData, '.duration', $iDuration)

			Switch $sOrigin
				Case 'viewport', 'pointer'
					Json_Put($vData, '.origin', $sOrigin)
				Case Else
					Json_Put($vData, '.origin.ELEMENT', $sOrigin)
					Json_Put($vData, '.origin.' & $_WD_ELEMENT_ID, $sOrigin)
			EndSwitch

			Json_Put($vData, '.x', $iXOffset)
			Json_Put($vData, '.y', $iYOffset)
	EndSwitch

	Local $sJSON = Json_Encode($vData)

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & $sJSON & @CRLF)
	EndIf

	Return $sJSON
EndFunc   ;==>_WD_JsonActionPointer

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_JsonActionPause
; Description ...: Formats pause "action" strings for use in _WD_Action
; Syntax ........: _WD_JsonActionPause($iDuration)
; Parameters ....: $iDuration - length of time to pause in ticks
; Return values .: Requested JSON string
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......: _WD_Action
; Link ..........: https://www.w3.org/TR/webdriver/#actions, https://www.w3.org/TR/webdriver/#ticks
; Example .......: No
; ===============================================================================================================================
Func _WD_JsonActionPause($iDuration)
	Local Const $sFuncName = "_WD_JsonActionPause"

	Local $vData = Json_ObjCreate()
	Json_Put($vData, '.type', 'pause')
	Json_Put($vData, '.duration', $iDuration)

	Local $sJSON = Json_Encode($vData)

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & $sJSON & @CRLF)
	EndIf

	Return $sJSON
EndFunc   ;==>_WD_JsonActionPause

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_JsonCookie
; Syntax ........: _WD_JsonCookie($sName, $sValue[, $sPath = Default[, $sDomain = Default[, $bSecure = Default [,
;                  $bHTTPOnly = Default[, $iExpiryTime = Default[, $sSameSite = Default]]]]]])
; Parameters ....: $sName               - The name of the cookie.
;                  $sValue              - The cookie value.
;                  $sPath               - [optional] This defines the cookie path.
;                  $sDomain             - [optional] This defines the domain the cookie is visible to.
;                  $bSecure             - [optional] This defines whether the cookie is a secure cookie.
;                  $bHTTPOnly           - [optional] This defines whether the cookie is an HTTP only cookie.
;                  $iExpiryTime         - [optional] This defines when the cookie expires, specified in seconds since Unix Epoch.
;                  $sSameSite           - [optional] This defines whether the cookie applies to a SameSite policy. One of the following modes can be used:
;                  |None
;                  |Lax
;                  |Strict
; Return values .: Cookie as formatted JSON strings
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......: _WD_Cookies
; Link ..........: https://www.w3.org/TR/webdriver/#dfn-table-for-cookie-conversion
; Example .......: No
; ===============================================================================================================================
Func _WD_JsonCookie($sName, $sValue, $sPath = Default, $sDomain = Default, $bSecure = Default, $bHTTPOnly = Default, $iExpiryTime = Default, $sSameSite = Default)
	Local Const $sFuncName = "_WD_JsonCookie"

	; Create JSON
	Local $vData = Json_ObjCreate()
	Json_Put($vData, '.cookie.name', $sName)
	Json_Put($vData, '.cookie.value', $sValue)
	If $sPath <> Default Then Json_Put($vData, '.cookie.path', $sPath)
	If $sDomain <> Default Then Json_Put($vData, '.cookie.domain', $sDomain)
	If $bSecure <> Default Then Json_Put($vData, '.cookie.secure', $bSecure)
	If $bHTTPOnly <> Default Then Json_Put($vData, '.cookie.httponly', $bHTTPOnly)
	If $iExpiryTime <> Default Then Json_Put($vData, '.cookie.expiry', $iExpiryTime)
	If $sSameSite <> Default Then Json_Put($vData, '.cookie.sameSite', $sSameSite)

	Local $sJSON = Json_Encode($vData)

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & $sJSON & @CRLF)
	EndIf

	Return $sJSON
EndFunc   ;==>_WD_JsonCookie

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
