#Include-once
#include "wd_core.au3"

#Region Copyright
#cs
	* WD_Helper.au3
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
	- Michał Lipok for all his feedback / suggestions
#ce
#EndRegion Many thanks to:


; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_NewTab
; Description ...: Helper function to create new tab using Javascript
; Syntax ........: _WD_NewTab($sSession[, $lSwitch = True[, $iTimeout = -1]])
; Parameters ....: $sSession            - Session ID from _WDCreateSession
;                  $lSwitch             - [optional] Switch session context to new tab? Default is True.
;                  $iTimeout            - [optional] Period of time to wait before exiting function
; Return values .: Success      - String representing handle of new tab
;                  Failure      - blank string
;                  @ERROR       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_GeneralError
;                  				- $_WD_ERROR_Timeout
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_NewTab($sSession, $lSwitch = True, $iTimeout = -1)
	Local Const $sFuncName = "_WD_NewTab"
	Local $sTabHandle = '', $iErr, $sLastTabHandle, $hWaitTimer, $sTempHandle

	If $iTimeout = -1 Then $iTimeout = $_WD_DefaultTimeout

	; Get handle to current last tab
	Local $aHandles = _WD_Window($sSession, 'handles')

	If @error <> $_WD_ERROR_Success Then
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception), 0, $sTabHandle)
	EndIf

	$sLastTabHandle = $aHandles[UBound($aHandles) - 1]

	If @error <> $_WD_ERROR_Success Then
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception), 0, $sTabHandle)
	EndIf

	_WD_ExecuteScript($sSession, 'window.open()', '{}')

	If @error <> $_WD_ERROR_Success Then
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception), 0, $sTabHandle)
	EndIf

	$hWaitTimer = TimerInit()

	While 1
		$aHandles = _WD_Window($sSession, 'handles')
		$sTempHandle = $aHandles[UBound($aHandles) - 1]

		If $sTempHandle <> $sLastTabHandle Then
			$sTabHandle = $sTempHandle
			ExitLoop
		EndIf

		If TimerDiff($hWaitTimer) > $iTimeout Then Return SetError(__WD_Error($sFuncName, $_WD_ERROR_Timeout), 0, $sTabHandle)

		Sleep(10)
	WEnd

	If $lSwitch Then
		_WD_Window($sSession, 'Switch', '{"handle":"' & $sTabHandle & '"}')
	EndIf

	Return SetError($_WD_ERROR_Success, 0, $sTabHandle)
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
Func _WD_Attach($sSession, $sString, $sMode = 'title')
	Local Const $sFuncName = "_WD_Attach"
	Local $sTabHandle = '', $lFound = False, $sCurrentTab, $aHandles

	$sCurrentTab = _WD_Window($sSession, 'window')

	If @error <> $_WD_ERROR_Success Then
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_GeneralError), 0, $sTabHandle)
	Else
		$aHandles = _WD_Window($sSession, 'handles')

		If @error = $_WD_ERROR_Success Then
			$sMode = StringLower($sMode)

			For $sHandle In $aHandles

				_WD_Window($sSession, 'Switch', '{"handle":"' & $sHandle & '"}')

				Switch $sMode
					Case "title", "url"
						If StringInStr(_WD_Action($sSession, $sMode), $sString) > 0 Then
							$lFound = True
							$sTabHandle = $sHandle
							ExitLoop
						EndIf

					Case 'html'
						If StringInStr(_WD_GetSource($sSession), $sString) > 0 Then
							$lFound = True
							$sTabHandle = $sHandle
							ExitLoop
						EndIf

					Case Else
						Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(Title|URL|HTML) $sOption=>" & $sMode), 0, $sTabHandle)
				EndSwitch
			Next

			If Not $lFound Then
				; Restore prior active tab
				_WD_Window($sSession, 'Switch', '{"handle":"' & $sCurrentTab & '"}')
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_NoMatch), 0, $sTabHandle)
			EndIf
		Else
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_GeneralError), 0, $sTabHandle)
		EndIf
	EndIf

	Return SetError($_WD_ERROR_Success, 0, $sTabHandle)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_LinkClickByText
; Description ...: Simulate a mouse click on a link with text matching the provided string
; Syntax ........: _WD_LinkClickByText($sSession, $sText[, $lPartial = True])
; Parameters ....: $sSession            - Session ID from _WDCreateSession
;                  $sText               - Text to find in link
;                  $lPartial            - [optional] Search by partial text? Default is True.
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
Func _WD_LinkClickByText($sSession, $sText, $lPartial = True)
	Local Const $sFuncName = "_WD_LinkClickByText"

	Local $sElement = _WD_FindElement($sSession, ($lPartial) ? $_WD_LOCATOR_ByPartialLinkText : $_WD_LOCATOR_ByLinkText, $sText)

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
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_WaitElement
; Description ...: Wait for a element to be found  in the current tab before returning
; Syntax ........: _WD_WaitElement($sSession, $sStrategy, $sSelector[, $iDelay = 0[, $iTimeout = -1[, $lVisible = False]]])
; Parameters ....: $sSession            - Session ID from _WDCreateSession
;                  $sStrategy           - Locator strategy. See defined constant $_WD_LOCATOR_* for allowed values
;                  $sSelector           - Value to find
;                  $iDelay              - [optional] Milliseconds to wait before checking status
;                  $iTimeout            - [optional] Period of time to wait before exiting function
;                  $lVisible            - [optional] Check visibility of element?
; Return values .: Success      - 1
;                  Failure      - 0 and sets the @error flag to non-zero
;                  @error       - $_WD_ERROR_Success
;                  				- $_WD_ERROR_Timeout
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_WaitElement($sSession, $sStrategy, $sSelector, $iDelay = 0, $iTimeout = -1, $lVisible = False)
	Local Const $sFuncName = "_WD_WaitElement"
	Local $bAbort = False, $iErr, $iResult = 0, $sElement, $lIsVisible = True

	If $iTimeout = -1 Then $iTimeout = $_WD_DefaultTimeout

	Sleep($iDelay)

	Local $hWaitTimer = TimerInit()

	While 1
		$sElement = _WD_FindElement($sSession, $sStrategy, $sSelector)
		$iErr = @error

		If $iErr = $_WD_ERROR_Success Then
			If $lVisible Then
				$lIsVisible = _WD_ElementAction($sSession, $sElement, 'displayed')
			EndIf

			If $lIsVisible = True Then
				$iResult = 1
				ExitLoop
			EndIf

		ElseIf $iErr <> $_WD_ERROR_NoMatch Then
			ExitLoop
		EndIf

		If (TimerDiff($hWaitTimer) > $iTimeout) Then
			$iErr = $_WD_ERROR_Timeout
			ExitLoop
		EndIf

		Sleep(1000)
	WEnd

	Return SetError(__WD_Error($sFuncName, $iErr), 0, $iResult)
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_GetMouseElement
; Description ...: Retrieves reference to element below mouse pointer
; Syntax ........: _WD_GetMouseElement($sSession)
; Parameters ....: $sSession            - Session ID from _WDCreateSession
; Return values .: Element ID returned by web driver
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........: https://stackoverflow.com/questions/24538450/get-element-currently-under-mouse-without-using-mouse-events
; Example .......: No
; ===============================================================================================================================
Func _WD_GetMouseElement($sSession)
	Local $sResponse, $sJSON, $sElement
	Local $sScript = "return Array.from(document.querySelectorAll(':hover')).pop()"

	$sResponse = _WD_ExecuteScript($sSession, $sScript, '')
	$sJSON = Json_Decode($sResponse)
	$sElement = Json_Get($sJSON, "[value][" & $_WD_ELEMENT_ID & "]")

	Return SetError($_WD_ERROR_Success, 0, $sElement)
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_GetElementFromPoint
; Description ...:
; Syntax ........: _WD_GetElementFromPoint($sSession, $iX, $iY)
; Parameters ....: $sSession            - Session ID from _WDCreateSession
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
	Local $sResponse, $sElement, $sJSON
    Local $sScript = "return document.elementFromPoint(arguments[0], arguments[1]);"
	Local $sParams = $iX & ", " & $iY

	$sResponse = _WD_ExecuteScript($sSession, $sScript, $sParams)
	$sJSON = Json_Decode($sResponse)
	$sElement = Json_Get($sJSON, "[value][" & $_WD_ELEMENT_ID & "]")

	Return SetError($_WD_ERROR_Success, 0, $sElement)
EndFunc


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
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_GetFrameCount
; Description ...: This will return how many frames/iframes are in your current window/frame. It will not traverse to nested frames.
; Syntax ........: _WD_GetFrameCount()
; Parameters ....:
; Return values .: Success      - Numeric count of frames, 0 or positive number
;                  Failure      - ""
; Author ........: Decibel
; Modified ......: 2018-04-27
; Remarks .......:
; Related .......:
; Link ..........: https://www.w3schools.com/jsref/prop_win_length.asp
; Example .......: No
; ===============================================================================================================================
Func _WD_GetFrameCount($sSession)
    Local $sResponse, $sJSON, $iValue

    $sResponse = _WD_ExecuteScript($sSession, "return window.frames.length")
    $sJSON = Json_Decode($sResponse)
    $iValue = Json_Get($sJSON, "[value]")

    Return Number($iValue)
EndFunc ;==>_WD_GetFrameCount


; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_IsWindowTop
; Description ...: This will return a boolean of the session being at the top level, or in a frame(s).
; Syntax ........: _WD_IsWindowTop()
; Parameters ....:
; Return values .: Success      - Boolean response
;                  Failure      - ""
; Author ........: Decibel
; Modified ......: 2018-04-27
; Remarks .......:
; Related .......:
; Link ..........: https://www.w3schools.com/jsref/prop_win_top.asp
; Example .......: No
; ===============================================================================================================================
Func _WD_IsWindowTop($sSession)
    Local $sResponse, $sJSON
    Local $blnResult

    $sResponse = _WD_ExecuteScript($sSession, "return window.top == window.self")
    $sJSON = Json_Decode($sResponse)
    $blnResult = Json_Get($sJSON, "[value]")

    Return $blnResult
EndFunc ;==>_WD_IsWindowTop

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_FrameEnter
; Description ...: This will enter the specified frame for subsequent WebDriver operations.
; Syntax ........: _WD_FrameEnter($sSession, $sIndexOrID)
; Parameters ....:
; Return values .: Success      - True
;                  Failure      - WD Response error message (E.g. "no such frame")
; Author ........: Decibel
; Modified ......: 2018-04-27
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_FrameEnter($sSession, $sIndexOrID)
    Local $sOption
    Local $sResponse, $sJSON
    Local $sValue

    ;*** Encapsulate the value if it's an integer, assuming that it's supposed to be an Index, not ID attrib value.
    If IsInt($sIndexOrID) = True Then
        $sOption = '{"id":' & $sIndexOrID & '}'
    Else
		$sOption = '{"id":{"' & $_WD_ELEMENT_ID & '":"' & $sIndexOrID & '"}}'
    EndIf

    $sResponse = _WD_Window($sSession, "frame", $sOption)
    $sJSON = Json_Decode($sResponse)
    $sValue = Json_Get($sJSON, "[value]")

    ;*** Evaluate the response
    If $sValue <> Null Then
        $sValue = Json_Get($sJSON, "[value][error]")
    Else
        $sValue = True
    EndIf

    Return $sValue
EndFunc ;==>_WD_FrameEnter

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_FrameLeave
; Description ...: This will leave the current frame, to its parent, not necessarily the Top, for subsequent WebDriver operations.
; Syntax ........: _WD_FrameLeave()
; Parameters ....:
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
    Local $sOption
    Local $sResponse, $sJSON, $asJSON
    Local $sValue

    $sOption = '{}'

    $sResponse = _WD_Window($sSession, "parent", $sOption)
    ;Chrome--
    ;   Good: '{"value":null}'
    ;   Bad: '{"value":{"error":"chrome not reachable"....
    ;Firefox--
    ;   Good: '{"value": {}}'
    ;   Bad: '{"value":{"error":"unknown error","message":"Failed to decode response from marionette","stacktrace":""}}'

    $sJSON = Json_Decode($sResponse)
    $sValue = Json_Get($sJSON, "[value]")

    ;*** Is this something besides a Chrome PASS?
    If $sValue <> Null Then
        ;*** Check for a nested JSON object
        If Json_IsObject($sValue) = True Then
            $asJSON = Json_ObjGetKeys($sValue)

            ;*** Is this an empty nested object
            If UBound($asJSON) = 0 Then ;Firefox PASS
                $sValue = True
            Else ;Chrome and Firefox FAIL
                $sValue = $asJSON[0] & ":" & Json_Get($sJSON, "[value][" & $asJSON[0] & "]")
            EndIf
        EndIf
    Else ;Chrome PASS
        $sValue = True
    EndIf

    Return $sValue
EndFunc ;==>_WD_FrameLeave

; #FUNCTION# ===========================================================================================================
; Name ..........: _WD_HighlightElement
; Description ...:
; Syntax ........: _WD_HighlightElement($sSession, $sElement[, $iMethod = 1])
; Parameters ....: $sSession            - Session ID from _WDCreateSession
;                  $sElement            - Element ID from _WDFindElement
;                  $iMethod             - [optional] an integer value. Default is 1.
;                  1=style -> Highlight border dotted red
;                  2=style -> Highlight yellow rounded box
;                  3=style -> Highlight yellow rounded box + border  dotted red
; Return values .: Success      - True
;                  Failure      - False
; Author ........: Danyfirex
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........: https://www.autoitscript.com/forum/topic/192730-webdriver-udf-help-support/?do=findComment&comment=1396643
; Example .......: No
; ===============================================================================================================================
Func _WD_HighlightElement($sSession, $sElement, $iMethod = 1)
    Local Const $aMethod[] = ["border: 2px dotted red", _
            "background: #FFFF66; border-radius: 5px; padding-left: 3px;", _
            "border:2px dotted  red;background: #FFFF66; border-radius: 5px; padding-left: 3px;"]
    If $iMethod < 1 Or $iMethod > 3 Then $iMethod = 1
	Local $sJsonElement = '{"' & $_WD_ELEMENT_ID & '":"' & $sElement & '"}'
    Local $sResponse = _WD_ExecuteScript($sSession, "arguments[0].style='" & $aMethod[$iMethod - 1] & "'; return true;", $sJsonElement)
    Local $sJSON = Json_Decode($sResponse)
    Local $sResult = Json_Get($sJSON, "[value]")
    Return ($sResult = "true" ? SetError(0, 0, $sResult) : SetError(1, 0, False))
EndFunc   ;==>_WD_HighlightElement

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_HighlightElements
; Description ...:
; Syntax ........: _WD_HighlightElements($sSession, $aElements[, $iMethod = 1])
; Parameters ....: $sSession            - Session ID from _WDCreateSession
;                  $aElements           - an array of Elements ID from _WDFindElement
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
Func _WD_HighlightElements($sSession, $aElements, $iMethod = 1)
    Local $iHighlightedElements = 0
    For $i = 0 To UBound($aElements) - 1
        $iHighlightedElements += (_WD_HighlightElement($sSession, $aElements[$i], $iMethod) = True ? 1 : 0)
    Next
    Return ($iHighlightedElements > 0 ? SetError(0, $iHighlightedElements, True) : SetError(1, 0, False))
EndFunc   ;==>_WD_HighlightElements



; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_LoadWait
; Description ...: Wait for a browser page load to complete before returning
; Syntax ........: _WD_LoadWait($sSession[, $iDelay = 0[, $iTimeout = -1[, $sElement = '']]])
; Parameters ....: $sSession            - Session ID from _WDCreateSession
;                  $iDelay              - [optional] Milliseconds to wait before checking status
;                  $iTimeout            - [optional] Period of time to wait before exiting function
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
Func _WD_LoadWait($sSession, $iDelay = 0, $iTimeout = -1, $sElement = '')
	Local Const $sFuncName = "_WD_LoadWait"
	Local $iErr, $sResponse, $sJSON, $sReadyState

	If $iTimeout = -1 Then $iTimeout = $_WD_DefaultTimeout

	If $iDelay Then Sleep($iDelay)

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

			$sJSON = Json_Decode($sResponse)
			$sReadyState = Json_Get($sJSON, "[value]")

			If $sReadyState = 'complete' Then ExitLoop
		EndIf

		If (TimerDiff($hLoadWaitTimer) > $iTimeout) Then
			$iErr = $_WD_ERROR_Timeout
			ExitLoop
		EndIf

		Sleep(100)
	WEnd

	If $iErr Then
		Return SetError(__WD_Error($sFuncName, $iErr, ""), 0, 0)
	EndIf

	Return SetError($_WD_ERROR_Success, 0, 1)
EndFunc
