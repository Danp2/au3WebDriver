#include-once
#include <File.au3> ; Needed For _WD_UpdateDriver
#include <InetConstants.au3>
#include "wd_core.au3"

#Region Copyright
#cs
	* WD_Helper.au3
	*
	* MIT License
	*
	* Copyright (c) 2021 Dan Pollak
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

#EndRegion Global Constants

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_NewTab
; Description ...: Helper function to create new tab using Javascript
; Syntax ........: _WD_NewTab($sSession[, $bSwitch = Default[, $iTimeout = Default[, $sURL = Default[, $sFeatures = Default]]]])
; Parameters ....: $sSession            - Session ID from _WD_CreateSession
;                  $bSwitch             - [optional] Switch session context to new tab? Default is True.
;                  $iTimeout            - [optional] Period of time (in milliseconds) to wait before exiting function
;                  $sURL                - [optional] URL to be loaded in new tab
;                  $sFeatures           - [optional] Comma-separated list of requested features of the new tab
; Return values .: Success      - String representing handle of new tab
;                  Failure      - blank string
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_GeneralError
;                  				- $_WD_ERROR_Timeout
; Author ........: Dan Pollak
; Modified ......: 01/12/2019
; Remarks .......: For list of $sFeatures take a look in the following link
; Related .......:
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
; Description ...: Helper function to attach to existing browser tab
; Syntax ........: _WD_Attach($sSession, $sString[, $sMode = Default])
; Parameters ....: $sSession            - Session ID from _WD_CreateSession
;                  $sString             - String to search for
;                  $sMode               - [optional] One of the following search modes:
;                               | Title (Default)
;                               | URL
;                               | HTML
; Return values .: Success      - String representing handle of matching tab
;                  Failure      - blank string
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_InvalidDataType
;                  				- $_WD_ERROR_NoMatch
;                  				- $_WD_ERROR_GeneralError
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
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
; Description ...: Simulate a mouse click on a link with text matching the provided string
; Syntax ........: _WD_LinkClickByText($sSession, $sText[, $bPartial = Default])
; Parameters ....: $sSession            - Session ID from _WD_CreateSession
;                  $sText               - Text to find in link
;                  $bPartial            - [optional] Search by partial text? Default is True.
; Return values .: Success      - None
;                  Failure      - Sets @error to non-zero
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_Exception
;                  				- $_WD_ERROR_NoMatch
;                  @EXTENDED    - WinHTTP status code
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
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
; Description ...: Wait for an element in the current tab before returning
; Syntax ........: _WD_WaitElement($sSession, $sStrategy, $sSelector[, $iDelay = Default[, $iTimeout = Default[, $iOptions = Default]]])
; Parameters ....: $sSession            - Session ID from _WD_CreateSession
;                  $sStrategy           - Locator strategy. See defined constant $_WD_LOCATOR_* for allowed values
;                  $sSelector           - Value to find
;                  $iDelay              - [optional] Milliseconds to wait before checking status
;                  $iTimeout            - [optional] Period of time (in milliseconds) to wait before exiting function
;                  $iOptions            - [optional] Binary flags to perform addtional actions
;
;                                         $_WD_OPTION_None    (0) = No optional feature processing
;                                         $_WD_OPTION_Visible (1) = Confirm element is visible
;                                         $_WD_OPTION_Enabled (2) = Confirm element is enabled
;                                         $_WD_OPTION_NoMatch (8) = Confirm element not found
;
; Return values .: Success      - Element ID returned by web driver
;                  Failure      - "" and sets the @error flag to non-zero
;
;                  @error       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_Timeout
;                  				- $_WD_ERROR_InvalidArgue
;                  				- $_WD_ERROR_UserAbort
;
; Author ........: Dan Pollak
; Modified ......: mLipok
; Remarks .......:
; Related .......:
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

		If @error Then
			$iErr = $_WD_ERROR_UserAbort
		Else
			Local $hWaitTimer = TimerInit()

			While 1
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

				__WD_Sleep(1000)

				If @error Then
					$iErr = $_WD_ERROR_UserAbort
					ExitLoop
				EndIf
			WEnd
		EndIf
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr), 0, $sElement)

EndFunc   ;==>_WD_WaitElement

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_GetMouseElement
; Description ...: Retrieves reference to element below mouse pointer
; Syntax ........: _WD_GetMouseElement($sSession)
; Parameters ....: $sSession            - Session ID from _WD_CreateSession
; Return values .: Element ID returned by web driver
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........: https://stackoverflow.com/questions/24538450/get-element-currently-under-mouse-without-using-mouse-events
; Example .......: No
; ===============================================================================================================================
Func _WD_GetMouseElement($sSession)
	Local Const $sFuncName = "_WD_GetMouseElement"
	Local $sResponse, $oJSON, $sElement
	Local $sScript = "return Array.from(document.querySelectorAll(':hover')).pop()"

	$sResponse = _WD_ExecuteScript($sSession, $sScript, '')
	$oJSON = Json_Decode($sResponse)
	$sElement = Json_Get($oJSON, "[value][" & $_WD_ELEMENT_ID & "]")

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & $sElement & @CRLF)
		__WD_ConsoleWrite($sFuncName & ': ' & IsObj($sElement) & @CRLF)
	EndIf

	Return SetError($_WD_ERROR_Success, 0, $sElement)
EndFunc   ;==>_WD_GetMouseElement

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_GetElementFromPoint
; Description ...: Retrieves reference to element at specified point
; Syntax ........: _WD_GetElementFromPoint($sSession, $iX, $iY)
; Parameters ....: $sSession            - Session ID from _WD_CreateSession
;                  $iX                  - an integer value.
;                  $iY                  - an integer value.
; Return values .: Success      - Element ID returned by web driver
;                  Failure      - blank string
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_GetElementFromPoint($sSession, $iX, $iY)
	Local $sResponse, $sElement, $oJSON
	Local $sScript = "return document.elementFromPoint(arguments[0], arguments[1]);"
	Local $sParams = $iX & ", " & $iY

	$sResponse = _WD_ExecuteScript($sSession, $sScript, $sParams)
	$oJSON = Json_Decode($sResponse)
	$sElement = Json_Get($oJSON, "[value][" & $_WD_ELEMENT_ID & "]")

	Return SetError($_WD_ERROR_Success, 0, $sElement)
EndFunc   ;==>_WD_GetElementFromPoint

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_LastHTTPResult
; Description ...: Return the result of the last WinHTTP request
; Syntax ........: _WD_LastHTTPResult()
; Parameters ....: None
; Return values .: Result of last WinHTTP request
; Author ........: Dan Pollak
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
; Description ...: This will return how many frames/iframes are in your current window/frame. It will not traverse to nested frames.
; Syntax ........: _WD_GetFrameCount($sSession)
; Parameters ....: $sSession            - Session ID from _WD_CreateSession
; Return values .: Success      - Numeric count of frames, 0 or positive number
;                  Failure      - blank string
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_Exception
; Author ........: Decibel, Danp2
; Modified ......: 2018-04-27
; Remarks .......:
; Related .......:
; Link ..........: https://www.w3schools.com/jsref/prop_win_length.asp
; Example .......: No
; ===============================================================================================================================
Func _WD_GetFrameCount($sSession)
	Local Const $sFuncName = "_WD_GetFrameCount"
	Local $sResponse, $oJSON, $iValue

	$sResponse = _WD_ExecuteScript($sSession, "return window.frames.length")

	If @error <> $_WD_ERROR_Success Then
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception), "")
	EndIf

	$oJSON = Json_Decode($sResponse)
	$iValue = Json_Get($oJSON, "[value]")

	Return SetError($_WD_ERROR_Success, 0, Number($iValue))
EndFunc   ;==>_WD_GetFrameCount

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_IsWindowTop
; Description ...: This will return a boolean of the session being at the top level, or in a frame(s).
; Syntax ........: _WD_IsWindowTop($sSession)
; Parameters ....: $sSession            - Session ID from _WD_CreateSession
; Return values .: Success      - Boolean response
;                  Failure      - ""
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_Exception
; Author ........: Decibel
; Modified ......: 2018-04-27
; Remarks .......:
; Related .......:
; Link ..........: https://www.w3schools.com/jsref/prop_win_top.asp
; Example .......: No
; ===============================================================================================================================
Func _WD_IsWindowTop($sSession)
	Local Const $sFuncName = "_WD_IsWindowTop"
	Local $sResponse, $oJSON
	Local $blnResult

	$sResponse = _WD_ExecuteScript($sSession, "return window.top == window.self")

	If @error <> $_WD_ERROR_Success Then
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception), "")
	EndIf

	$oJSON = Json_Decode($sResponse)
	$blnResult = Json_Get($oJSON, "[value]")

	Return SetError($_WD_ERROR_Success, 0, $blnResult)
EndFunc   ;==>_WD_IsWindowTop

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_FrameEnter
; Description ...: This will enter the specified frame for subsequent WebDriver operations.
; Syntax ........: _WD_FrameEnter($sSession, $vIdentifier)
; Parameters ....: $sSession            - Session ID from _WD_CreateSession
;                  $vIdentifier         - Index (as 0-based Integer) or HTMLElement @ID (as String) or Null (Keyword)
; Return values .: Success      - True
;                  Failure      - WD Response error message (E.g. "no such frame")
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_Exception
; Author ........: Decibel
; Modified ......: mLipok
; Remarks .......: You can drill-down into nested frames by calling this function repeatedly with the correct parameters
; Related .......:
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
		$sOption = '{"id":{"' & $_WD_ELEMENT_ID & '":"' & $vIdentifier & '"}}'
	EndIf

	$sResponse = _WD_Window($sSession, "frame", $sOption)

	If @error <> $_WD_ERROR_Success Then
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception), "")
	EndIf

	$oJSON = Json_Decode($sResponse)
	$sValue = Json_Get($oJSON, "[value]")

	;*** Evaluate the response
	If $sValue <> Null Then
		$sValue = Json_Get($oJSON, "[value][error]")
	Else
		$sValue = True
	EndIf

	Return SetError($_WD_ERROR_Success, 0, $sValue)
EndFunc   ;==>_WD_FrameEnter

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_FrameLeave
; Description ...: This will leave the current frame, to its parent, not necessarily the Top, for subsequent WebDriver operations.
; Syntax ........: _WD_FrameLeave($sSession)
; Parameters ....: $sSession            - Session ID from _WD_CreateSession
; Return values .: Success      True
;                  Failure      - WD Response error message (E.g. "chrome not reachable")
; Author ........: Decibel
; Modified ......: 2018-04-27
; Remarks .......: ChromeDriver and GeckoDriver respond differently for a successful operation
; Related .......:
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
	$sValue = Json_Get($oJSON, "[value]")

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
; Description ...: Highlights the specified element
; Syntax ........: _WD_HighlightElement($sSession, $sElement[, $iMethod = Default])
; Parameters ....: $sSession            - Session ID from _WD_CreateSession
;                  $sElement            - Element ID from _WD_FindElement
;                  $iMethod             - [optional] an integer value. Default is 1.
;                  0=style -> Remove highlight
;                  1=style -> Highlight border dotted red
;                  2=style -> Highlight yellow rounded box
;                  3=style -> Highlight yellow rounded box + border  dotted red
; Return values .: Success      - True
;                  Failure      - False
; Author ........: Danyfirex
; Modified ......: 04/03/2021
; Remarks .......:
; Related .......:
; Link ..........: https://www.autoitscript.com/forum/topic/192730-webdriver-udf-help-support/?do=findComment&comment=1396643
; Example .......: No
; ===============================================================================================================================
Func _WD_HighlightElement($sSession, $sElement, $iMethod = Default)
	Local Const $aMethod[] = ["border: 0px", _
			"border: 2px dotted red", _
			"background: #FFFF66; border-radius: 5px; padding-left: 3px;", _
			"border:2px dotted  red;background: #FFFF66; border-radius: 5px; padding-left: 3px;"]

	If $iMethod = Default Then $iMethod = 1
	If $iMethod < 0 Or $iMethod > 3 Then $iMethod = 1

	Local $sJsonElement = '{"' & $_WD_ELEMENT_ID & '":"' & $sElement & '"}'
	Local $sResponse = _WD_ExecuteScript($sSession, "arguments[0].style='" & $aMethod[$iMethod] & "'; return true;", $sJsonElement)
	Local $oJSON = Json_Decode($sResponse)
	Local $sResult = Json_Get($oJSON, "[value]")
	Return ($sResult = "true" ? SetError(0, 0, $sResult) : SetError(1, 0, False))
EndFunc   ;==>_WD_HighlightElement

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_HighlightElements
; Description ...: Highlights the specified elements
; Syntax ........: _WD_HighlightElements($sSession, $aElements[, $iMethod = Default])
; Parameters ....: $sSession            - Session ID from _WD_CreateSession
;                  $aElements           - an array of Elements ID from _WD_FindElement
;                  $iMethod             - [optional] an integer value. Default is 1.
;                  1=style -> Highlight border dotted red
;                  2=style -> Highlight yellow rounded box
;                  3=style -> Highlight yellow rounded box + border  dotted red
; Return values .: Success      - True
;                  Failure      - False
;                  @Extended Number of Highlighted Elements
; Author ........: Danyfirex
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........: https://www.autoitscript.com/forum/topic/192730-webdriver-udf-help-support/?do=findComment&comment=1396643
; Example .......: No
; ===============================================================================================================================
Func _WD_HighlightElements($sSession, $aElements, $iMethod = Default)
	Local $iHighlightedElements = 0

	If $iMethod = Default Then $iMethod = 1

	For $i = 0 To UBound($aElements) - 1
		$iHighlightedElements += (_WD_HighlightElement($sSession, $aElements[$i], $iMethod) = True ? 1 : 0)
	Next
	Return ($iHighlightedElements > 0 ? SetError(0, $iHighlightedElements, True) : SetError(1, 0, False))
EndFunc   ;==>_WD_HighlightElements

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_LoadWait
; Description ...: Wait for a browser page load to complete before returning
; Syntax ........: _WD_LoadWait($sSession[, $iDelay = Default[, $iTimeout = Default[, $sElement = Default]]])
; Parameters ....: $sSession            - Session ID from _WD_CreateSession
;                  $iDelay              - [optional] Milliseconds to wait before checking status
;                  $iTimeout            - [optional] Period of time (in milliseconds) to wait before exiting function
;                  $sElement            - [optional] Element ID to confirm DOM invalidation
; Return values .: Success      - 1
;                  Failure      - 0 and sets the @error flag to non-zero
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_LoadWait($sSession, $iDelay = Default, $iTimeout = Default, $sElement = Default)
	Local Const $sFuncName = "_WD_LoadWait"
	Local $iErr, $sResponse, $oJSON, $sReadyState

	If $iDelay = Default Then $iDelay = 0
	If $iTimeout = Default Then $iTimeout = $_WD_DefaultTimeout
	If $sElement = Default Then $sElement = ""

	If $iDelay Then __WD_Sleep($iDelay)

	If @error Then
		$iErr = $_WD_ERROR_UserAbort
	Else
		Local $hLoadWaitTimer = TimerInit()

		While True
			If $sElement <> '' Then
				_WD_ElementAction($sSession, $sElement, 'name')

				If $_WD_HTTPRESULT = $HTTP_STATUS_NOT_FOUND Then $sElement = ''
			Else
				$sResponse = _WD_ExecuteScript($sSession, 'return document.readyState', '')
				$iErr = @error

				If $iErr Then
					ExitLoop
				EndIf

				$oJSON = Json_Decode($sResponse)
				$sReadyState = Json_Get($oJSON, "[value]")

				If $sReadyState = 'complete' Then ExitLoop
			EndIf

			If (TimerDiff($hLoadWaitTimer) > $iTimeout) Then
				$iErr = $_WD_ERROR_Timeout
				ExitLoop
			EndIf

			__WD_Sleep(100)

			If @error Then
				$iErr = $_WD_ERROR_UserAbort
				ExitLoop
			EndIf
		WEnd
	EndIf

	If $iErr Then
		Return SetError(__WD_Error($sFuncName, $iErr, ""), 0, 0)
	EndIf

	Return SetError($_WD_ERROR_Success, 0, 1)
EndFunc   ;==>_WD_LoadWait

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_Screenshot
; Description ...: Takes a screenshot of the Window or Element
; Syntax ........: _WD_Screenshot($sSession[, $sElement = Default[, $nOutputType = Default]])
; Parameters ....: $sSession            - Session ID from _WD_CreateSession
;                  $sElement            - [optional] Element ID from _WD_FindElement
;                  $nOutputType         - [optional] One of the following output types:
;                               | 1 - String (Default)
;                               | 2 - Binary
;                               | 3 - Base64
; Return values .: Success      - output of specified type (PNG format)
;                  Failure      - empty string
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_NoMatch
;                  				- $_WD_ERROR_Exception
;                  				- $_WD_ERROR_InvalidDataType
;                  				- $_WD_ERROR_InvalidExpression
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
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
; Description ...: Print the current tab in paginated PDF format
; Syntax ........: _WD_PrintToPDF($sSession[, $sOptions = Default]])
; Parameters ....: $sSession            - Session ID from _WD_CreateSession
;                : $sOptions            - [optional] JSON string of formatting directives
; Return values .: Success      - String containing PDF contents
;                  Failure      - empty string
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_Exception
;                  				- $_WD_ERROR_InvalidDataType
;
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......: Chromedriver currently requires headless mode (https://bugs.chromium.org/p/chromedriver/issues/detail?id=3517)
; Related .......:
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
; Description ...: Inject jQuery library into current session
; Syntax ........: _WD_jQuerify($sSession[, $sjQueryFile = Default[, $iTimeout = Default]])
; Parameters ....: $sSession            - Session ID from _WD_CreateSession
;                : $sjQueryFile         - [optional] Path or URL to jQuery source file
;                  $iTimeout            - [optional] Period of time (in milliseconds) to wait before exiting function
; Return values .: None
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_Timeout
;                  				- $_WD_ERROR_GeneralError
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
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
			If TimerDiff($hWaitTimer) > $iTimeout Then
				SetError($_WD_ERROR_Timeout)
				ExitLoop
			EndIf

			__WD_Sleep(250)
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
; Description ...: Find and click on an option from a Select element
; Syntax ........: _WD_ElementOptionSelect($sSession, $sStrategy, $sSelector[, $sStartElement = Default])
; Parameters ....: $sSession            - Session ID from _WD_CreateSession
;                  $sStrategy           - Locator strategy. See defined constant $_WD_LOCATOR_* for allowed values
;                  $sSelector           - Value to find
;                  $sStartElement       - [optional] Element ID of element to use as starting point
; Return values .: None
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_Exception
;                  				- $_WD_ERROR_NoMatch
;                  				- $_WD_ERROR_InvalidDataType
;                  				- $_WD_ERROR_InvalidExpression
;                  @EXTENDED    - WinHTTP status code
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
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
; Description ...: Perform action on desginated Select element
; Syntax ........: _WD_ElementSelectAction($sSession, $sSelectElement, $sCommand)
; Parameters ....: $sSession            - Session ID from _WD_CreateSession
;                  $sSelectElement      - Element ID of Select element from _WD_FindElement
;                  $sCommand            - Action to be performed
; Return values .: Success      - Requested data returned by web driver
;                  Failure      - ""
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_NoMatch
;                  				- $_WD_ERROR_Exception
;                  				- $_WD_ERROR_InvalidDataType
;                  				- $_WD_ERROR_InvalidExpression
;                  				- $_WD_ERROR_InvalidArgue
;                  @EXTENDED    - WinHTTP status code
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_ElementSelectAction($sSession, $sSelectElement, $sCommand)
	Local Const $sFuncName = "_WD_ElementSelectAction"
	Local $sNodeName, $sJsonElement, $sResponse, $oJSON, $vResult
	Local $sText, $aOptions

	$sNodeName = _WD_ElementAction($sSession, $sSelectElement, 'property', 'nodeName')
	Local $iErr = @error

	If $iErr = $_WD_ERROR_Success And $sNodeName = 'select' Then

		Switch $sCommand
			Case 'value'
				; Retrieve current value of designated Select element
				$sJsonElement = '{"' & $_WD_ELEMENT_ID & '":"' & $sSelectElement & '"}'
				$sResponse = _WD_ExecuteScript($sSession, "return arguments[0].value", $sJsonElement)
				$iErr = @error

				If $iErr = $_WD_ERROR_Success Then
					$oJSON = Json_Decode($sResponse)
					$vResult = Json_Get($oJSON, "[value]")
				EndIf

			Case 'options'
				; Retrieve array containing value / label attributes from the Select element's options
				$aOptions = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "./option", $sSelectElement, True)

				$iErr = @error

				If $iErr = $_WD_ERROR_Success Then
					$sText = ""
					For $sElement In $aOptions
						$sJsonElement = '{"' & $_WD_ELEMENT_ID & '":"' & $sElement & '"}'
						$sResponse = _WD_ExecuteScript($sSession, "return arguments[0].value + '|' + arguments[0].label", $sJsonElement)

						$iErr = @error

						If $iErr = $_WD_ERROR_Success Then
							$oJSON = Json_Decode($sResponse)
							$sText &= (($sText <> "") ? @CRLF : "") & Json_Get($oJSON, "[value]")
						EndIf
					Next

					Local $aOut[0][2]
					_ArrayAdd($aOut, $sText, 0, Default, Default, 1)
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
; Description ...: Control visibility of the webdriver console app
; Syntax ........: _WD_ConsoleVisible([$bVisible = Default])
; Parameters ....: $bVisible            - [optional] Set to true to show the console
; Return values .: None
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
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
; Description ...: Retrieves the shadow root of an element
; Syntax ........: _WD_GetShadowRoot($sSession, $sStrategy, $sSelector[, $sStartElement = Default])
; Parameters ....: $sSession            - Session ID from _WD_CreateSession
;                  $sStrategy           - Locator strategy. See defined constant $_WD_LOCATOR_* for allowed values
;                  $sSelector           - Value to find
;                  $sStartElement       - [optional] a string value. Default is "".
; Return values .: Success      - Element ID returned by web driver
;                  Failure      - ""
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_Exception
;                  				- $_WD_ERROR_NoMatch
;                  @EXTENDED    - WinHTTP status code
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_GetShadowRoot($sSession, $sStrategy, $sSelector, $sStartElement = Default)
	Local Const $sFuncName = "_WD_GetShadowRoot"
	Local $sResponse, $sResult, $oJSON

	If $sStartElement = Default Then $sStartElement = ""

	Local $sElement = _WD_FindElement($sSession, $sStrategy, $sSelector, $sStartElement)
	Local $iErr = @error

	If $iErr = $_WD_ERROR_Success Then
		$sResponse = _WD_ElementAction($sSession, $sElement, 'shadow')

		$oJSON = Json_Decode($sResponse)
		$sResult = Json_Get($oJSON, "[value][" & $_WD_ELEMENT_ID & "]")
	EndIf

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & $sResult & @CRLF)
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr), $_WD_HTTPRESULT, $sResult)
EndFunc   ;==>_WD_GetShadowRoot

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_SelectFiles
; Description ...: Select files for uploading to a website
; Syntax ........: _WD_SelectFiles($sSession, $sStrategy, $sSelector, $sFilename)
; Parameters ....: $sSession            - Session ID from _WD_CreateSession
;                  $sStrategy           - Locator strategy. See defined constant $_WD_LOCATOR_* for allowed values
;                  $sSelector           - Value to find. Should point to element of type <input type="file">
;                  $sFilename           - Full path of file(s) to upload (use newline character [@LF] to separate files)
;
; Return values .: Number of selected files
;
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_Exception
;                  				- $_WD_ERROR_NoMatch
;                  @EXTENDED    - WinHTTP status code
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......: If $sFilename is empty, then prior selection is cleared
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_SelectFiles($sSession, $sStrategy, $sSelector, $sFilename)
	Local Const $sFuncName = "_WD_SelectFiles"

	Local $sResponse, $sResult, $sJsonElement, $oJSON, $sSavedEscape
	Local $sElement = _WD_FindElement($sSession, $sStrategy, $sSelector)
	Local $iErr = @error

	If $iErr = $_WD_ERROR_Success Then
		If $sFilename <> "" Then
			$sSavedEscape = $_WD_ESCAPE_CHARS
			; Convert file string into proper format
			$sFilename = StringReplace(__WD_EscapeString($sFilename), @LF, "\n")
			; Prevent further string escaping
			$_WD_ESCAPE_CHARS = ""
			$sResponse = _WD_ElementAction($sSession, $sElement, 'value', $sFilename)
			$iErr = @error
			; Restore setting
			$_WD_ESCAPE_CHARS = $sSavedEscape
		Else
			$sResponse = _WD_ElementAction($sSession, $sElement, 'clear')
			$iErr = @error
		EndIf

		If $iErr = $_WD_ERROR_Success Then
			$sJsonElement = '{"' & $_WD_ELEMENT_ID & '":"' & $sElement & '"}'
			$sResponse = _WD_ExecuteScript($sSession, "return arguments[0].files.length", $sJsonElement)
			$oJSON = Json_Decode($sResponse)
			$sResult = Json_Get($oJSON, "[value]")
		Else
			$sResult = "0"
		EndIf
	EndIf

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & $sResult & " file(s) selected" & @CRLF)
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr), $_WD_HTTPRESULT, $sResult)
EndFunc   ;==>_WD_SelectFiles

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_IsLatestRelease
; Description ...: Compares local UDF version to latest release on Github
; Syntax ........: _WD_IsLatestRelease()
; Parameters ....: None
; Return values .: Success      - True if values match, otherwise False
;                  Failure      - Null
;
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_Exception
;                  				- $_WD_ERROR_InvalidValue
;                  				- $_WD_ERROR_InvalidDataType
; Author ........: Dan Pollak
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

	Local $sResult = InetRead($sGitURL)
	If @error Then $iErr = $_WD_ERROR_GeneralError

	If $iErr = $_WD_ERROR_Success Then
		Local $aLatestWDVersion = StringRegExp(BinaryToString($sResult), '<a href="/Danp2/WebDriver/releases/tag/(.*)">', $STR_REGEXPARRAYMATCH)

		If Not @error Then
			Local $sLatestWDVersion = $aLatestWDVersion[0]
			$bResult = ($__WDVERSION == $sLatestWDVersion)
		EndIf
	EndIf

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & $bResult & @CRLF)
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr), $_WD_HTTPRESULT, $bResult)

EndFunc   ;==>_WD_IsLatestRelease

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_UpdateDriver
; Description ...: Replace web driver with newer version, if available
; Syntax ........: _WD_UpdateDriver($sBrowser[, $sInstallDir = Default[, $bFlag64 = Default[, $bForce = Default]]])
; Parameters ....: $sBrowser            - Name of browser
;                  $sInstallDir         - [optional] Install directory. Default is @ScriptDir
;                  $bFlag64             - [optional] Install 64bit version? Default is False
;                  $bForce              - [optional] Force update? Default is False
;
; Return values .: True      - Driver was updated
;                  False     - Driver not updated
;
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_NoMatch
;                  				- $_WD_ERROR_InvalidValue
;                  				- $_WD_ERROR_GeneralError
;
; Author ........: Dan Pollak, CyCho
; Modified ......: mLipok
; Remarks .......:
; Related .......: _WD_GetBrowserVersion, _WD_GetWebDriverVersion
; Link ..........:
; Example .......: Local $bResult = _WD_UpdateDriver('FireFox')
; ===============================================================================================================================
Func _WD_UpdateDriver($sBrowser, $sInstallDir = Default, $bFlag64 = Default, $bForce = Default)
	Local Const $sFuncName = "_WD_UpdateDriver"
	Local $iErr = $_WD_ERROR_Success, $sDriverEXE, $sBrowserVersion, $bResult = False
	Local $sDriverVersion, $sVersionShort, $sDriverLatest, $sURLNewDriver
	Local $sReturned, $sTempFile, $hFile, $oShell, $FilesInZip, $sResult, $iStartPos, $iConversion

	If $sInstallDir = Default Then $sInstallDir = @ScriptDir
	If $bFlag64 = Default Then $bFlag64 = False
	If $bForce = Default Then $bForce = False

	; If the Install directory doesn't exist and it can't be created, then set error
	If (Not FileExists($sInstallDir)) And (Not DirCreate($sInstallDir)) Then $iErr = $_WD_ERROR_InvalidValue

	; Save current debug level and set to none
	Local $WDDebugSave = $_WD_DEBUG
	$_WD_DEBUG = $_WD_DEBUG_None

	Switch $sBrowser
		Case 'chrome'
			$sDriverEXE = "chromedriver.exe"
		Case 'firefox'
			$sDriverEXE = "geckodriver.exe"
		Case 'msedge'
			$sDriverEXE = "msedgedriver.exe"
		Case Else
			$iErr = $_WD_ERROR_InvalidValue
	EndSwitch

	If $iErr = $_WD_ERROR_Success Then
		$sBrowserVersion = _WD_GetBrowserVersion($sBrowser)
		If @error Then $iErr = @error

		$sDriverVersion = _WD_GetWebDriverVersion($sInstallDir, $sDriverEXE)
		If @error Then $iErr = @error

		; Determine latest available webdriver version
		; for the designated browser
		Switch $sBrowser
			Case 'chrome'
				$sVersionShort = StringLeft($sBrowserVersion, StringInStr($sBrowserVersion, ".", 0, -1) - 1)
				$sDriverLatest = BinaryToString(InetRead('https://chromedriver.storage.googleapis.com/LATEST_RELEASE_' & $sVersionShort))
				$sURLNewDriver = "https://chromedriver.storage.googleapis.com/" & $sDriverLatest & "/chromedriver_win32.zip"

			Case 'firefox'
				$sResult = BinaryToString(InetRead("https://github.com/mozilla/geckodriver/releases/latest"))

				If @error = $_WD_ERROR_Success Then
					$sDriverLatest = StringRegExp($sResult, '<a href="/mozilla/geckodriver/releases/tag/(.*)">', 1)[0]
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

		If ($iErr = $_WD_ERROR_Success And $sDriverLatest > $sDriverVersion) Or $bForce Then
			$sReturned = InetRead($sURLNewDriver)

			$sTempFile = _TempFile($sInstallDir, "webdriver_", ".zip")
			$hFile = FileOpen($sTempFile, 18)
			FileWrite($hFile, $sReturned)
			FileClose($hFile)

			; Close any instances of webdriver and delete from disk
			__WD_CloseDriver($sDriverEXE)
			FileDelete($sInstallDir & "\" & $sDriverEXE)

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
					$oShell.NameSpace($sInstallDir).CopyHere($FilesInZip, 20)
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

	; Restore prior setting
	$_WD_DEBUG = $WDDebugSave

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & $iErr & @CRLF)
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr), 0, $bResult)
EndFunc   ;==>_WD_UpdateDriver

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_GetBrowserVersion
; Description ...: Get version number of specifed browser
; Syntax ........: _WD_GetBrowserVersion($sBrowser)
; Parameters ....: $sBrowser            - a string value. 'chrome', 'firefox', 'msedge'
; Return values .: $sBrowserVersion
;                  Failure      - blank string
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_InvalidValue
;                  				- $_WD_ERROR_NotFound
; Author ........: Dan Pollak, mLipok
; Modified ......: 18/06/2021
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: MsgBox(0, "", _WD_GetBrowserVersion('chrome'))
; ===============================================================================================================================
Func _WD_GetBrowserVersion($sBrowser)
	Local Const $sFuncName = "_WD_GetBrowserVersion"
	Local Const $cRegKey = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\'
	Local $sEXE, $sBrowserVersion = ''
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
; Description ...: Get version number of specifed webdriver
; Syntax ........: _WD_GetWebDriverVersion($sInstallDir, $sDriverEXE)
; Parameters ....: $sInstallDir         - a string value. Directory where $sDriverEXE is located
;                  $sDriverEXE          - a string value. File name of "WebDriver.exe"
; Return values .: $sDriverVersion
;                  Failure      - blank string
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_InvalidValue
;                  				- $_WD_ERROR_NotFound
; Author ........: Dan Pollak, mLipok
; Modified ......: 18/06/2021
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: MsgBox(0, "", _WD_GetWebDriverVersion(@ScriptDir,'chromedriver.exe'))
; ===============================================================================================================================
Func _WD_GetWebDriverVersion($sInstallDir, $sDriverEXE)
	Local Const $sFuncName = "_WD_GetWebDriverVersion"
	Local $sDriverVersion = "None"
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
			$iErr = $_WD_ERROR_Success
		EndIf
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr), 0, $sDriverVersion)
EndFunc   ;==>_WD_GetWebDriverVersion

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_DownloadFile
; Description ...: Download file and save to disk
; Syntax ........: _WD_DownloadFile($sURL, $sDest[, $iOptions = Default])
; Parameters ....: $sURL                - URL representing file to be downloaded
;                  $sDest               - Full path, including filename, of destination file
;                  $iOptions            - [optional] Download options
;
; Return values .: True      - Download succeeded
;                  False     - Download failed
;
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_GeneralError
;                  				- $_WD_ERROR_NotFound
;
; Author ........: Dan Pollak
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
		Local $hFile = FileOpen($sDest, 18)

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
; Description ...: User friendly function to set webdriver session timeouts
; Syntax ........: _WD_SetTimeouts($sSession[, $iPageLoad = Default[, $iScript = Default[, $iImplicitWait = Default]]])
; Parameters ....: $sSession            - Session ID from _WD_CreateSession
;                  $iPageLoad           - [optional] Page load timeout in milliseconds
;                  $iScript             - [optional] Script timeout in milliseconds
;                  $iImplicitWait       - [optional] Implicit wait timeout in milliseconds
; Return values .: Success      - Raw return value from web driver in JSON format
;                  Failure      - 0
;
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_InvalidArgue
;                  				- $_WD_ERROR_Exception
;                  				- $_WD_ERROR_InvalidDataType
;
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......: $iScript parameter can be null, implies that scripts should never be interrupted, but instead run indefinitely
;				 : When setting page load timeout, WinHTTP receive timeout is automatically adjusted as well
;
; Related .......: _WD_Timeouts
; Link ..........: https://www.w3.org/TR/webdriver/#set-timeouts
; Example .......: _WD_SetTimeouts($sSession, 50000)
; ===============================================================================================================================
Func _WD_SetTimeouts($sSession, $iPageLoad = Default, $iScript = Default, $iImplicitWait = Default)
	Local Const $sFuncName = "_WD_SetTimeouts"
	Local $sTimeouts = '', $sResult = '', $bIsNull

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
		Local $iErr = @error

		If $iErr = $_WD_ERROR_Success And $iPageLoad <> Default Then
			; Adjust WinHTTP receive timeouts to prevent send/recv errors
			$_WD_HTTPTimeOuts[3] = $iPageLoad + 1000
		EndIf
	Else
		$iErr = $_WD_ERROR_InvalidArgue
		$sResult = 0
	EndIf

	If $_WD_DEBUG = $_WD_DEBUG_Info Then
		__WD_ConsoleWrite($sFuncName & ': ' & $iErr & @CRLF)
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr), 0, $sResult)
EndFunc   ;==>_WD_SetTimeouts

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_GetElementById
; Description ...: Locate element by id
; Syntax ........: _WD_GetElementById($sSession, $sID)
; Parameters ....: $sSession            - Session ID from _WD_CreateSession
;                  $sID                 - ID of desired element
; Return values .: Success      - Element ID returned by web driver
;                  Failure      - ""
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_Exception
;                  				- $_WD_ERROR_NoMatch
;                  @EXTENDED    - WinHTTP status code
; Author ........: Dan Pollak
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
; Description ...: Locate element by name
; Syntax ........: _WD_GetElementByName($sSession, $sName)
; Parameters ....: $sSession            - Session ID from _WD_CreateSession
;                  $sName               - Name of desired element
; Return values .: Success      - Element ID returned by web driver
;                  Failure      - ""
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_Exception
;                  				- $_WD_ERROR_NoMatch
;                  @EXTENDED    - WinHTTP status code
; Author ........: Dan Pollak
;
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
; Description ...: Set value of designated element
; Syntax ........: _WD_SetElementValue($sSession, $sElement, $sValue[, $iStyle = Default])
; Parameters ....: $sSession            - Session ID from _WD_CreateSession
;                  $sElement            - Element ID from _WD_FindElement
;                  $sValue              - New value for element
;                  $iStyle              - [optional] Update style. Default is $_WD_OPTION_Standard.
;
;                                         $_WD_OPTION_Standard (0) = Set value using _WD_ElementAction
;                                         $_WD_OPTION_Advanced (1) = set value using _WD_ExecuteScript
;
; Return values .: Success      - Requested data returned by web driver
;                  Failure      - ""
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_NoMatch
;                  				- $_WD_ERROR_Exception
;                  				- $_WD_ERROR_InvalidDataType
;                  				- $_WD_ERROR_InvalidExpression
;                  @EXTENDED    - WinHTTP status code
;
; Author ........: Dan Pollak
; Modified ......: 03/31/2021
; Remarks .......:
; Related .......:
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
			$sJsonElement = '{"' & $_WD_ELEMENT_ID & '":"' & $sElement & '"}'
			$sResult = _WD_ExecuteScript($sSession, $sScript, $sJsonElement & ',"' & $sValue & '"')
			$iErr = @error

	EndSwitch

	Return SetError(__WD_Error($sFuncName, $iErr), 0, $sResult)
EndFunc   ;==>_WD_SetElementValue

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_ElementActionEx
; Description ...: Perform advanced action on desginated element
; Syntax ........: _WD_ElementActionEx($sSession, $sElement, $sCommand[, $iXOffset = Default[, $iYOffset = Default[,
;                  $iButton = Default[, $iHoldDelay = Default[, $sModifier = Default]]]]])
; Parameters ....: $sSession            - Session ID from _WD_CreateSession
;                  $sElement            - Element ID from _WD_FindElement
;                  $sCommand            - one of the following actions:
;                                           | hover
;                                           | doubleclick
;                                           | rightclick
;                                           | clickandhold
;                                           | hide
;                                           | show
;                                           | childcount
;                                           | modifierclick
;
;                  $iXOffset            - [optional] X Offset. Default is 0
;                  $iYOffset            - [optional] Y Offset. Default is 0
;                  $iButton             - [optional] Mouse button. Default is 0
;                  $iHoldDelay          - [optional] Hold time in ms. Default is 1000
;                  $sModifier           - [optional] Modifier key. Default is "\uE008" (shift key)
;
; Return values .: Success      - Return value from web driver (could be an empty string)
;                  Failure      - ""
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_Exception
;                  				- $_WD_ERROR_InvalidDataType
;                  @EXTENDED    - WinHTTP status code
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......: _WD_ElementAction, _WD_Action
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_ElementActionEx($sSession, $sElement, $sCommand, $iXOffset = Default, $iYOffset = Default, $iButton = Default, $iHoldDelay = Default, $sModifier = Default)
	Local Const $sFuncName = "_WD_ElementActionEx"
	Local $sAction, $sJavascript, $iErr, $sResult, $sJsonElement, $sResponse, $oJSON, $iActionType = 1

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
			$sJsonElement = '{"' & $_WD_ELEMENT_ID & '":"' & $sElement & '"}'
			$sResponse = _WD_ExecuteScript($sSession, $sJavascript, $sJsonElement)
			$iErr = @error
			$oJSON = Json_Decode($sResponse)
			$sResult = Json_Get($oJSON, "[value]")
	EndSwitch

	Return SetError(__WD_Error($sFuncName, $iErr), 0, $sResult)
EndFunc   ;==>_WD_ElementActionEx

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_GetTable
; Description ...: Return all elements of a table
; Syntax ........: _WD_GetTable($sSession, $sBaseElement)
; Parameters ....: $sSession     - Session ID from _WD_CreateSession
;                  $sBaseElement - XPath of the table to return
; Return values .: Success      - 2D array
;                  Failure      - ""
;                  @ERROR       - $_WD_ERROR_Success
;                               - $_WD_ERROR_Exception
;                               - $_WD_ERROR_NoMatch
;                  @EXTENDED    - WinHTTP status code
; Author ........: danylarson
; Modified ......: water, danp2
; Remarks .......:
; Related .......:
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
; Description ...: Return a boolean indicating if the session is in full screen mode
; Syntax ........: _WD_IsFullScreen($sSession)
; Parameters ....: $sSession            - Session ID from _WD_CreateSession
; Return values .: Success      - True or False
;                  Failure      - Raw response from webdriver
;                  @ERROR       - $_WD_ERROR_Success
;                               - $_WD_ERROR_Exception
;
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........: https://www.autoitscript.com/forum/topic/205553-webdriver-udf-help-support-iii/?do=findComment&comment=1480527
; Example .......: No
; ===============================================================================================================================
Func _WD_IsFullScreen($sSession)
	Local Const $sFuncName = "_WD_IsFullScreen"
	Local $sResponse = _WD_ExecuteScript($sSession, 'return screen.width == window.innerWidth and screen.height == window.innerHeight;')

	If @error <> $_WD_ERROR_Success Then
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception), 0, $sResponse)
	EndIf

	Local $oJSON = Json_Decode($sResponse)
	Local $bResult = Json_Get($oJSON, "[value]")

	Return SetError($_WD_ERROR_Success, 0, $bResult)
EndFunc   ;==>_WD_IsFullScreen

; #INTERNAL_USE_ONLY# ====================================================================================================================
; Name ..........: __WD_Base64Decode
; Description ...: Decodes Base64 strings into binary
; Syntax ........: __WD_Base64Decode($input_string)
; Parameters ....: $input_string        - string to be decoded
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

EndFunc
