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

#Region Many thanks to:
#cs
	- Jonathan Bennett (@Jon) and the AutoIt Team
	- Thorsten Willert (@Stilgar), author of FF.au3, which I've used as a model
	- Michał Lipok (@mLipok) for all his contribution
#ce
#EndRegion Many thanks to:

#Tidy_Parameters=/tcb=-1

#Region Global Constants
Global Enum _
		$_WD_OPTION_None = 0, _
		$_WD_OPTION_Visible = 1, _
		$_WD_OPTION_Enabled = 2, _
		$_WD_OPTION_Element = 4, _
		$_WD_OPTION_NoMatch = 8, _
		$_WD_OPTION_Hidden = 16

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

Global Enum _
		$_WD_STORAGE_Local = 0, _
		$_WD_STORAGE_Session = 1

Global Enum _ ; _WD_FrameList() , _WD_FrameListFindElement()
		$_WD_FRAMELIST_Absolute = 0, _
		$_WD_FRAMELIST_Relative = 1, _
		$_WD_FRAMELIST_Attributes = 2, _
		$_WD_FRAMELIST_URL = 3, _
		$_WD_FRAMELIST_BodyID = 4, _
		$_WD_FRAMELIST_FrameVisibility = 5, _
		$_WD_FRAMELIST_MatchedElements = 6, _ ; array of matched element from _WD_FrameListFindElement()
		$_WD_FRAMELIST__COUNTER

#Tidy_ILC_Pos=42
Global Enum _                            ; https://www.w3schools.com/jsref/prop_doc_readystate.asp
		$_WD_READYSTATE_Uninitialized, _ ; Has not started loading
		$_WD_READYSTATE_Loading, _       ; Is loading
		$_WD_READYSTATE_Loaded, _        ; Has been loaded
		$_WD_READYSTATE_Interactive, _   ; Has loaded enough to interact with
		$_WD_READYSTATE_Complete, _      ; Fully loaded
		$_WD_READYSTATE__COUNTER
#Tidy_ILC_Pos=0

Global Const $aWD_READYSTATE[$_WD_READYSTATE__COUNTER][2] = [ _
		["uninitialized", "Has not started loading"], _
		["loading", "Is loading"], _
		["loaded", "Has been loaded"], _
		["interactive", "Has loaded enough to interact with"], _
		["complete", "Fully loaded"] _
		]

Global Enum _ ; Column positions of $aWD_READYSTATE
		$_WD_READYSTATE_State, _
		$_WD_READYSTATE_Desc

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
; Remarks .......: Specifying any features other than noopener or noreferrer, also has the effect of requesting a popup.
;                  See the link below for further details and a list of available features.
; Related .......: _WD_Window, _WD_LastHTTPResult
; Link ..........: https://developer.mozilla.org/en-US/docs/Web/API/Window/open#window_features
; Example .......: No
; ===============================================================================================================================
Func _WD_NewTab($sSession, $bSwitch = Default, $iTimeout = Default, $sURL = Default, $sFeatures = Default)
	Local Const $sFuncName = "_WD_NewTab"
	Local Const $sParameters = 'Parameters:    Switch=' & $bSwitch & '    Timeout=' & $iTimeout & '    URL=' & $sURL & '    Features=' & $sFeatures
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
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception, $sParameters), 0, $sTabHandle)
		EndIf
	Else
		Local $aHandles = _WD_Window($sSession, 'handles')

		If @error <> $_WD_ERROR_Success Or Not IsArray($aHandles) Then
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception, $sParameters), 0, $sTabHandle)
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
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_Exception, $sParameters), 0, $sTabHandle)
		EndIf

		$hWaitTimer = TimerInit()

		While 1
			$aTemp = _WD_Window($sSession, 'handles')

			If UBound($aTemp) > $iTabCount Then
				$sTabHandle = $aTemp[$iTabIndex + 1]
				ExitLoop
			EndIf

			If TimerDiff($hWaitTimer) > $iTimeout Then Return SetError(__WD_Error($sFuncName, $_WD_ERROR_Timeout, $sParameters), 0, $sTabHandle)

			__WD_Sleep(10)
			If @error Then Return SetError(__WD_Error($sFuncName, @error, $sParameters), 0, $sTabHandle)
		WEnd

		If $bSwitch Then
			_WD_Window($sSession, 'Switch', '{"handle":"' & $sTabHandle & '"}')
		Else
			_WD_Window($sSession, 'Switch', '{"handle":"' & $sCurrentTabHandle & '"}')
		EndIf
	EndIf

	Return SetError(__WD_Error($sFuncName, $_WD_ERROR_Success, $sParameters), 0, $sTabHandle)
EndFunc   ;==>_WD_NewTab

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_Attach
; Description ...: Attach to existing browser tab.
; Syntax ........: _WD_Attach($sSession, $sSearch[, $sMode = Default])
; Parameters ....: $sSession - Session ID from _WD_CreateSession
;                  $sSearch  - String to search for
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
; Related .......: _WD_Window, _WD_LastHTTPResult
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_Attach($sSession, $sSearch, $sMode = Default)
	Local Const $sFuncName = "_WD_Attach"
	Local Const $sParameters = 'Parameters:    Search=' & $sSearch & '    Mode=' & $sMode
	Local $sTabHandle = '', $bFound = False, $sCurrentTab = '', $aHandles
	Local $iErr = $_WD_ERROR_Success

	If $sMode = Default Then $sMode = 'title'

	$aHandles = _WD_Window($sSession, 'handles')
	$iErr = @error

	If $iErr = $_WD_ERROR_Success Then
		$sCurrentTab = _WD_Window($sSession, 'window')

		For $sHandle In $aHandles

			_WD_Window($sSession, 'Switch', '{"handle":"' & $sHandle & '"}')

			Switch $sMode
				Case "title", "url"
					If StringInStr(_WD_Action($sSession, $sMode), $sSearch) > 0 Then
						$bFound = True
						$sTabHandle = $sHandle
						ExitLoop
					EndIf

				Case 'html'
					If StringInStr(_WD_GetSource($sSession), $sSearch) > 0 Then
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

			$iErr = $_WD_ERROR_NoMatch
		EndIf
	ElseIf Not $_WD_DetailedErrors Then
		$iErr = $_WD_ERROR_GeneralError
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters), 0, $sTabHandle)
EndFunc   ;==>_WD_Attach

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_LinkClickByText
; Description ...: Simulate a mouse click on a link with text matching the provided string.
; Syntax ........: _WD_LinkClickByText($sSession, $sText[, $bPartial = Default[, $sStartNodeID = Default]])
; Parameters ....: $sSession      - Session ID from _WD_CreateSession
;                  $sText         - Text to find in link
;                  $bPartial      - [optional] Search by partial text? Default is True
;                  $sStartNodeID  - [optional] Element ID to use as starting HTML node. Default is ""
; Return values .: Success - None.
;                  Failure - "" (empty string) and sets @error to one of the following values:
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_NoMatch
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......: _WD_FindElement, _WD_ElementAction, _WD_LastHTTPResult
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_LinkClickByText($sSession, $sText, $bPartial = Default, $sStartNodeID = Default)
	Local Const $sFuncName = "_WD_LinkClickByText"
	Local Const $sParameters = 'Parameters:   Text=' & $sText & '   Partial=' & $bPartial & '   StartElement=' & $sStartNodeID

	If $bPartial = Default Then $bPartial = True
	If $sStartNodeID = Default Then $sStartNodeID = ""

	Local $sElement = _WD_FindElement($sSession, ($bPartial) ? $_WD_LOCATOR_ByPartialLinkText : $_WD_LOCATOR_ByLinkText, $sText, $sStartNodeID)
	Local $iErr = @error

	If $iErr = $_WD_ERROR_Success Then
		_WD_ElementAction($sSession, $sElement, 'click')
		$iErr = @error

		If $iErr <> $_WD_ERROR_Success And Not $_WD_DetailedErrors Then
			$iErr = $_WD_ERROR_Exception
		EndIf
	Else
		$iErr = $_WD_ERROR_NoMatch
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters), 0, "")
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
;                  |$_WD_OPTION_NoMatch (8) = Confirm element is not found
;                  |$_WD_OPTION_Hidden (16) = Confirm element is not visible
; Return values .: Success - Element ID returned by web driver.
;                  Failure - "" (empty string) and sets @error to one of the following values:
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_InvalidArgue
;                  - $_WD_ERROR_Timeout
;                  - $_WD_ERROR_UserAbort
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......:
; Related .......: _WD_FindElement, _WD_ElementAction, _WD_LastHTTPResult
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_WaitElement($sSession, $sStrategy, $sSelector, $iDelay = Default, $iTimeout = Default, $iOptions = Default)
	Local Const $sFuncName = "_WD_WaitElement"
	Local Const $sParameters = 'Parameters:   Strategy=' & $sStrategy & '   Selector=' & $sSelector & '   Delay=' & $iDelay & '   Timeout=' & $iTimeout & '   Options=' & $iOptions
	Local $iErr, $sElement, $bIsVisible = True, $bIsEnabled = True
	$_WD_HTTPRESULT = 0
	$_WD_HTTPRESPONSE = ''

	If $iDelay = Default Then $iDelay = 0
	If $iTimeout = Default Then $iTimeout = $_WD_DefaultTimeout
	If $iOptions = Default Then $iOptions = $_WD_OPTION_None

	Local Const $bVisible = BitAND($iOptions, $_WD_OPTION_Visible)
	Local Const $bEnabled = BitAND($iOptions, $_WD_OPTION_Enabled)
	Local Const $bNoMatch = BitAND($iOptions, $_WD_OPTION_NoMatch)
	Local Const $bHidden = BitAND($iOptions, $_WD_OPTION_Hidden)

	; Other options aren't valid if No Match or Hidden option is supplied
	If ($bNoMatch And $iOptions <> $_WD_OPTION_NoMatch) Or _
			($bHidden And $iOptions <> $_WD_OPTION_Hidden) Then
		$iErr = $_WD_ERROR_InvalidArgue
	Else
		__WD_Sleep($iDelay)
		$iErr = @error

		; prevent multiple errors https://github.com/Danp2/au3WebDriver/pull/290#issuecomment-1100707095
		Local $_WD_DEBUG_Saved = $_WD_DEBUG ; save current DEBUG level

		; Prevent logging from _WD_FindElement if not in Full debug mode
		If $_WD_DEBUG <> $_WD_DEBUG_Full Then $_WD_DEBUG = $_WD_DEBUG_None

		Local $hWaitTimer = TimerInit()
		While 1
			If $iErr Then ExitLoop

			$sElement = _WD_FindElement($sSession, $sStrategy, $sSelector)
			$iErr = @error

			If $iErr <> $_WD_ERROR_Success And $iErr <> $_WD_ERROR_NoMatch Then
				; Exit loop if unexpected error occurs
				ExitLoop

			ElseIf $iErr = $_WD_ERROR_NoMatch And $bNoMatch Then
				; if element wasn't found and "no match" option is active
				; exit loop indicating success
				$iErr = $_WD_ERROR_Success
				ExitLoop

			ElseIf $iErr = $_WD_ERROR_Success And Not $bNoMatch Then
				; if element was found and "no match" option isn't active
				; check other options
				If $bVisible Or $bHidden Then
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

				Select
					Case $bHidden
						If Not $bIsVisible Then ExitLoop

					Case $bIsVisible And $bIsEnabled
						ExitLoop

					Case Else
						$sElement = ''
				EndSelect
			EndIf

			If (TimerDiff($hWaitTimer) > $iTimeout) Then
				$iErr = $_WD_ERROR_Timeout
				ExitLoop
			EndIf

			__WD_Sleep(10)
			$iErr = @error
		WEnd
		$_WD_DEBUG = $_WD_DEBUG_Saved ; restore DEBUG level
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters), 0, $sElement)
EndFunc   ;==>_WD_WaitElement

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_WaitScript
; Description ...: Wait for a JavaScript snippet to return true.
; Syntax ........: _WD_WaitScript($sSession, $sJavaScript[, $iDelay = Default[, $iTimeout = Default[, $iOptions = Default]]])
; Parameters ....: $sSession  - Session ID from _WD_CreateSession
;                  $sJavaScript - JavaScript to run
;                  $iDelay    - [optional] Milliseconds to wait before initially checking status
;                  $iTimeout  - [optional] Period of time (in milliseconds) to wait before exiting function
; Return values .: Success - True
;                  Failure - False and sets @error to one of the following values:
;                  - $_WD_ERROR_InvalidArgue
;                  - $_WD_ERROR_RetValue
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_Timeout
;                  - $_WD_ERROR_UserAbort
; Author ........: yehiaserag
; Modified ......:
; Remarks .......: The Javascript needs to return either True or False.
; Related .......: _WD_ExecuteScript
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_WaitScript($sSession, $sJavaScript, $iDelay = Default, $iTimeout = Default)
	Local Const $sFuncName = "_WD_WaitScript"
	Local Const $sParameters = 'Parameters:   JavaScript=' & $sJavaScript & '   Delay=' & $iDelay & '   Timeout=' & $iTimeout
	Local $iErr
	Local $bValue = False

	If $iDelay = Default Then $iDelay = 0
	If $iTimeout = Default Then $iTimeout = $_WD_DefaultTimeout

	If StringLeft($sJavaScript, 6) <> "return" Then
		$iErr = $_WD_ERROR_InvalidArgue
	Else
		__WD_Sleep($iDelay)
		$iErr = @error

		; prevent multiple errors https://github.com/Danp2/au3WebDriver/pull/290#issuecomment-1100707095
		Local $_WD_DEBUG_Saved = $_WD_DEBUG ; save current DEBUG level

		; Prevent logging from _WD_ExecuteScript if not in Full debug mode
		If $_WD_DEBUG <> $_WD_DEBUG_Full Then $_WD_DEBUG = $_WD_DEBUG_None

		Local $hWaitTimer = TimerInit()
		While 1
			If $iErr Then ExitLoop

			$bValue = _WD_ExecuteScript($sSession, 'return !!((function(){' & $sJavaScript & '})())', Default, Default, $_WD_JSON_Value)
			$iErr = @error

			If $iErr <> $_WD_ERROR_Success Then
				; Exit loop if unexpected error occurs
				ExitLoop
			ElseIf $bValue = False Then
				If (TimerDiff($hWaitTimer) > $iTimeout) Then
					$iErr = $_WD_ERROR_Timeout
					ExitLoop
				EndIf

				__WD_Sleep(10)
				$iErr = @error
			Else
				$iErr = $_WD_ERROR_Success
				ExitLoop
			EndIf
		WEnd
		$_WD_DEBUG = $_WD_DEBUG_Saved ; restore DEBUG level
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters), 0, $bValue)
EndFunc   ;==>_WD_WaitScript

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_DebugSwitch
; Description ...: Switch to new debug level or switch back to saved debug level
; Syntax ........: _WD_DebugSwitch([$vMode = Default])
; Parameters ....: $vMode - [optional] Set new $_WD_DEBUG level. When not specified (Default) restore saved debug level.
; Return values .: Success - current stack size
;                  Failure - negative values indicate an error
; Author ........: mLipok
; Modified ......:
; Remarks .......: @error and @extended values are preserved by this function and did not originate within it
; Related .......:
; Link ..........:
; Example .......: _WD_DebugSwitch($_WD_DEBUG_Full)
; ===============================================================================================================================
Func _WD_DebugSwitch($vMode = Default, $iErr = @error, $iExt = @extended)
	Local Const $sFuncName = "_WD_DebugSwitch"
	Local Static $a_WD_DEBUG_SavedStack[0] ; first usage - empty stack array
	Local $iStackSize = UBound($a_WD_DEBUG_SavedStack)
	Local $sMessage = ''

	If $vMode = Default Then ; restoring saved debug level
		If $iStackSize Then
			$_WD_DEBUG = $a_WD_DEBUG_SavedStack[$iStackSize - 1] ; restore previous debug level from last element on the stack
			$iStackSize -= 1 ; decrease stack size
			ReDim $a_WD_DEBUG_SavedStack[$iStackSize] ; trim array - stack last element
		Else
			$iStackSize = -1
			$sMessage = 'There are no saved debug levels'
		EndIf
	ElseIf IsInt($vMode) And $vMode >= $_WD_DEBUG_None And $vMode <= $_WD_DEBUG_Full Then ; setting new debug level
		$iStackSize += 1 ; increase stack size
		ReDim $a_WD_DEBUG_SavedStack[$iStackSize] ; resize array - add new position to the stack
		$a_WD_DEBUG_SavedStack[$iStackSize - 1] = $_WD_DEBUG ; store current debug level to the stack
		$_WD_DEBUG = $vMode ; set new debug level
	Else
		$iStackSize = -2
		$sMessage = 'Invalid argument in function-call'
	EndIf

	$sMessage &= " / " & (($iStackSize < 0) ? (" error code: ") : (" stack size: ")) & $iStackSize
	__WD_ConsoleWrite($sFuncName & ": " & $sMessage, $_WD_DEBUG_Info)
	Return SetError($iErr, $iExt, $iStackSize) ; do not use __WD_Error() here as $iErr and $iExt are preserved and not belongs to this function
EndFunc   ;==>_WD_DebugSwitch

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
; Related .......: _WD_ExecuteScript, _WD_LastHTTPResult
; Link ..........: https://stackoverflow.com/questions/24538450/get-element-currently-under-mouse-without-using-mouse-events
; Example .......: No
; ===============================================================================================================================
Func _WD_GetMouseElement($sSession)
	Local Const $sFuncName = "_WD_GetMouseElement"
	Local $sScript = "return Array.from(document.querySelectorAll(':hover')).pop()"
	Local $sElement = _WD_ExecuteScript($sSession, $sScript, '', Default, $_WD_JSON_Element)
	Local $iErr = @error

	Return SetError(__WD_Error($sFuncName, $iErr, $sElement), 0, $sElement)
EndFunc   ;==>_WD_GetMouseElement

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_GetElementFromPoint
; Description ...: Retrieves reference to element at specified point.
; Syntax ........: _WD_GetElementFromPoint($sSession, $iX, $iY)
; Parameters ....: $sSession - Session ID from _WD_CreateSession
;                  $iX       - an integer value
;                  $iY       - an integer value
; Return values .: Success - Element ID returned by web driver.
;                  Failure - "" (empty string) and @error is set to one of the following values:
;                  - $_WD_ERROR_RetValue
;                  - $_WD_ERROR_InvalidArgue
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......: @extended is set to 1 if the browsing context changed during the function call
; Related .......: _WD_ExecuteScript, _WD_LastHTTPResult
; Link ..........: https://stackoverflow.com/questions/31910534/executing-javascript-elementfrompoint-through-selenium-driver/32574543#32574543
; Example .......: No
; ===============================================================================================================================
Func _WD_GetElementFromPoint($sSession, $iX, $iY)
	Local Const $sFuncName = "_WD_GetElementFromPoint"
	Local Const $sParameters = 'Parameters:    X=' & $iX & '    Y=' & $iY
	Local $sResponse, $oJSON, $sElement = ""
	Local $sTagName, $sParams, $aCoords, $iFrame = 0, $oERect
	Local $sScript1 = "return document.elementFromPoint(arguments[0], arguments[1]);"
	Local $sScript2 = "return new Array(window.pageXOffset, window.pageYOffset);"
	Local $iErr = $_WD_ERROR_Success, $sResult, $bIsNull

	; https://developer.mozilla.org/en-US/docs/Web/API/Document/elementFromPoint
	; If the specified point is outside the visible bounds of the document or either
	; coordinate is negative, the result is null
	If $iX < 0 Or $iY < 0 Then
		$iErr = $_WD_ERROR_InvalidArgue
	EndIf

	While $iErr = $_WD_ERROR_Success
		$sParams = $iX & ", " & $iY
		$sResponse = _WD_ExecuteScript($sSession, $sScript1, $sParams)
		If @error Then
			$iErr = $_WD_ERROR_RetValue
			ExitLoop
		EndIf

		$oJSON = Json_Decode($sResponse)
		$sElement = Json_Get($oJSON, $_WD_JSON_Element)

		If @error Then
			$sResult = Json_Get($oJSON, $_WD_JSON_Value)
			$bIsNull = (IsKeyword($sResult) = $KEYWORD_NULL)

			If Not $bIsNull Then
				$iErr = $_WD_ERROR_RetValue
			EndIf

			ExitLoop
		Else
			$sTagName = _WD_ElementAction($sSession, $sElement, "Name")
			If Not StringInStr($sTagName, "frame") Then ; check <iframe> and <frame> element
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
		EndIf
	WEnd

	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters, $iFrame), $iFrame, $sElement)
EndFunc   ;==>_WD_GetElementFromPoint

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
; Related .......: _WD_ExecuteScript, _WD_LastHTTPResult
; Link ..........: https://www.w3schools.com/jsref/prop_win_length.asp
; Example .......: No
; ===============================================================================================================================
Func _WD_GetFrameCount($sSession)
	Local Const $sFuncName = "_WD_GetFrameCount"
	Local $iValue = _WD_ExecuteScript($sSession, "return window.frames.length", Default, Default, $_WD_JSON_Value)
	Local $iErr = @error
	If $iErr Then $iValue = 0
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
; Related .......: _WD_ExecuteScript, _WD_LastHTTPResult
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
;                  $vIdentifier - Target frame identifier. Can be any of the following:
;                  |Null    - Return to top-most browsing context
;                  |String  - Element ID from _WD_FindElement or path like 'null/2/0'
;                  |Integer - 0-based index of frames
; Return values .: Success - True.
;                  Failure - WD Response error message (E.g. "no such frame") and sets @error to one of the following values:
;                  - $_WD_ERROR_Exception
; Author ........: Decibel
; Modified ......: Danp2, mLipok, jchd
; Remarks .......: You can drill-down into nested frames by calling this function repeatedly or use identifier like 'null/2/0'
; Related .......: _WD_Window, _WD_LastHTTPResult
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_FrameEnter($sSession, $vIdentifier)
	Local Const $sFuncName = "_WD_FrameEnter"
	If String($vIdentifier) = 'null' Then $vIdentifier = Null ; String must be used because checking 0 = 'null' is True
	Local Const $bIsIdentifierNull = (IsKeyword($vIdentifier) = $KEYWORD_NULL)
	Local Const $sParameters = 'Parameters:    Identifier=' & ($bIsIdentifierNull ? ("Null") : ($vIdentifier))
	Local $sValue, $sMessage = '', $sOption, $sResponse, $oJSON
	Local $iErr = $_WD_ERROR_Success

	; must start with null or digit, must have at least one slash (may have many slashes but should not be followed one per other), must end with digit
	Local Const $bIdentifierAsPath = StringRegExp($vIdentifier, "(?i)\A(?:Null|\d+)(?:\/\d+)+\Z", $STR_REGEXPMATCH)

	If $bIdentifierAsPath Then
		; will be processed below
	ElseIf $bIsIdentifierNull Then
		$sOption = '{"id":null}'
	ElseIf IsInt($vIdentifier) Then
		$sOption = '{"id":' & $vIdentifier & '}'
	Else
		$sOption = '{"id":' & __WD_JsonElement($vIdentifier) & '}'
	EndIf

	If Not $bIdentifierAsPath Then
		$sResponse = _WD_Window($sSession, "frame", $sOption)
		$iErr = @error
	Else
		Local $aIdentifiers = StringSplit($vIdentifier, '/')
		For $i = 1 To $aIdentifiers[0]
			If String($aIdentifiers[$i]) = 'null' Then
				$aIdentifiers[$i] = '{"id":null}'
			Else
				$aIdentifiers[$i] = '{"id":' & $aIdentifiers[$i] & '}'
			EndIf
			$sResponse = _WD_Window($sSession, "frame", $aIdentifiers[$i])
			If Not @error Then ContinueLoop

			$iErr = @error
			$sMessage = ' Error on ID#' & $i & ' > ' & $aIdentifiers[$i]
			ExitLoop
		Next
	EndIf

	If $iErr = $_WD_ERROR_Success Then
		$oJSON = Json_Decode($sResponse)
		$sValue = Json_Get($oJSON, $_WD_JSON_Value)

		;*** Evaluate the response
		If $sValue <> Null Then
			$sValue = Json_Get($oJSON, $_WD_JSON_Error)
		Else
			$sValue = True
		EndIf
	ElseIf Not $_WD_DetailedErrors Then
		$iErr = $_WD_ERROR_Exception
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters & $sMessage), 0, $sValue)
EndFunc   ;==>_WD_FrameEnter

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_FrameLeave
; Description ...: Leave the current frame, to its parent.
; Syntax ........: _WD_FrameLeave($sSession)
; Parameters ....: $sSession - Session ID from _WD_CreateSession
; Return values .: Success - True.
;                  Failure - WD Response error message (E.g. "chrome not reachable") and sets @error to one of the following values:
;                  - $_WD_ERROR_Exception
; Author ........: Decibel
; Modified ......: Danp2
; Remarks .......:
; Related .......: _WD_Window, _WD_LastHTTPResult
; Link ..........: https://www.w3.org/TR/webdriver/#switch-to-parent-frame
; Example .......: No
; ===============================================================================================================================
Func _WD_FrameLeave($sSession)
	Local Const $sFuncName = "_WD_FrameLeave"
	Local $sValue, $oJSON, $sOption = '{}'

	Local $sResponse = _WD_Window($sSession, "parent", $sOption)
	Local $iErr = @error

	If $iErr = $_WD_ERROR_Success Then
		$oJSON = Json_Decode($sResponse)
		$sValue = Json_Get($oJSON, $_WD_JSON_Value)

		;*** Evaluate the response
		If $sValue <> Null Then
			$sValue = Json_Get($oJSON, $_WD_JSON_Error)
		Else
			$sValue = True
		EndIf
	ElseIf Not $_WD_DetailedErrors Then
		$iErr = $_WD_ERROR_Exception
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr), 0, $sValue)
EndFunc   ;==>_WD_FrameLeave

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_FrameList
; Description ...: Retrieves a detailed list of the main document and all associated frames
; Syntax ........: _WD_FrameList($sSession[, $bReturnAsArray = True[, $iDelay = 1000[, $iTimeout = Default]]])
; Parameters ....: $sSession            - Session ID from _WD_CreateSession
;                  $bReturnAsArray      - [optional] Return result as array? Default is True.
;                  $iDelay              - [optional] Single delay before checking first frame. Default is 1000 ms
;                  $iTimeout            - [optional] Timeout for _WD_LoadWait() calls for each frame. Default is $_WD_DefaultTimeout
; Return values .: Success - 2D array (with 7 cols) or string ( delimited with | and @CRLF ) @extended contains information about frame count
;                  Failure - "" (empty string) and sets @error to one of the following values:
;                  - $_WD_ERROR_GeneralError
;                  - $_WD_ERROR_Timeout
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_NotFound
;                  - $_WD_ERROR_RetValue
;                  - $_WD_ERROR_UserAbort
; Author ........: mLipok
; Modified ......: Danp2
; Remarks .......: The returned list of frames can depend on many factors, including geolocation, as well as problems with the local Internet
; Related .......: _WD_GetFrameCount, _WD_FrameEnter, _WD_FrameLeave
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_FrameList($sSession, $bReturnAsArray = True, $iDelay = 1000, $iTimeout = Default)
	Local Const $sFuncName = "_WD_FrameList"
	Local Const $sParameters = 'Parameters:    ReturnAsArray=' & $bReturnAsArray & '    iDelay=' & $iDelay & '    iTimeout=' & $iTimeout
	Local $a_Result[0][$_WD_FRAMELIST__COUNTER], $sStartLocation = '', $sMessage = ''
	Local $vResult = '', $iErr = $_WD_ERROR_Success, $iFrameCount = 0

	Local Const $sElement_CallingFrameBody = _WD_ExecuteScript($sSession, "return window.document.body;", Default, Default, $_WD_JSON_Element)
	If Not @error Then
		__WD_Sleep($iDelay)
	EndIf
	If Not @error Then
		$vResult = __WD_FrameList_Internal($sSession, 'null', '', False, $iTimeout)
	EndIf
	$iErr = @error
	#Region - post processing
	If $iErr = $_WD_ERROR_Success Then
		; Strip last @CRLF
		$vResult = StringTrimRight($vResult, 2)

		; create array of frames from string returned from __WD_FrameList_Internal
		_ArrayAdd($a_Result, $vResult)

		; check the results
		For $i = 0 To UBound($a_Result) - 1
			; find "calling frame" location - set $sStartLocation
			If $a_Result[$i][$_WD_FRAMELIST_BodyID] = $sElement_CallingFrameBody Then $sStartLocation = $a_Result[$i][$_WD_FRAMELIST_Absolute]

			; recalculate locations from absolute path on COL0 to relative path on COL1
			$a_Result[$i][$_WD_FRAMELIST_Relative] = StringRegExpReplace($a_Result[$i][$_WD_FRAMELIST_Absolute], '\A' & $sStartLocation & '\/?', '')
		Next

	ElseIf $iErr <> $_WD_ERROR_Timeout And $iErr <> $_WD_ERROR_UserAbort And Not $_WD_DetailedErrors Then
		$iErr = $_WD_ERROR_GeneralError
	EndIf

	$iFrameCount = UBound($a_Result, $UBOUND_ROWS)
	If $iFrameCount < 1 Then $sMessage &= 'List of frames is empty. '

	; select desired DataType for the $vResult - usually string is option for testing and asking support, thus Array is returned by default
	If $bReturnAsArray Then
		$vResult = $a_Result
	Else
		$vResult = _ArrayToString($a_Result) ; getting string with recalculated locations (relative path)
		If @error Then
			$iErr = $_WD_ERROR_RetValue
			$sMessage = 'ArrayToString conversion failed. '
			$vResult = ''
		EndIf
	EndIf

	If $sStartLocation Then ; Back to "calling frame"
		_WD_FrameEnter($sSession, $sStartLocation)
		$iErr = @error
		If $iErr Then
			$sMessage &= 'Was not able back to "calling frame".'
			If Not $_WD_DetailedErrors Then $iErr = $_WD_ERROR_Exception
		EndIf
	Else
		$sMessage &= 'Was not able to check "calling frame".'
		$iErr = $_WD_ERROR_NotFound
	EndIf

	#EndRegion - post processing

	$sMessage = ($sMessage And $_WD_DEBUG > $_WD_DEBUG_Error) ? ('	Information: ' & $sMessage) : ("")
	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters & $sMessage, $iFrameCount), $iFrameCount, $vResult)
EndFunc   ;==>_WD_FrameList

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_FrameList_Internal
; Description ...: function that is used internally in _WD_FrameList, even recursively when nested frames are available
; Syntax ........: __WD_FrameList_Internal($sSession, $sLevel, $sFrameAttributes, $bIsHidden, $iTimeout)
; Parameters ....: $sSession            - Session ID from _WD_CreateSession
;                  $sLevel              - frame location level path
;                  $sFrameAttributes    - frame attributes in HTML format
;                  $bIsHidden           - information about visibility of frame - taken by WebDriver
;                  $iTimeout            - Timeout for _WD_LoadWait() calls for each frame
; Return values .: Success - string
;                  Failure - "" (empty string) and sets @error returned from related functions
; Author ........: mLipok
; Modified ......: Danp2
; Remarks .......:
; Related .......: _WD_FrameEnter, _WD_LoadWait, _WD_ExecuteScript, _WD_GetFrameCount, _WD_ElementAction, _WD_FrameLeave
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WD_FrameList_Internal($sSession, $sLevel, $sFrameAttributes, $bIsHidden, $iTimeout)
	Local Const $sFuncName = "__WD_FrameList_Internal"
	Local Const $sParameters = 'Parameters:    Level=' & $sLevel & '    IsHidden=' & $bIsHidden & '    Timeout=' & $iTimeout ; intentionally $sFrameAttributes is not listed here to not put too many data into the log
	Local $iErr = $_WD_ERROR_Success, $sMessage = '', $vResult = ''
	Local $s_URL = '', $sCurrentBody_ElementID = ''

	#Region ; this region is prevented from redundant logging if not in Full debug mode - https://github.com/Danp2/au3WebDriver/pull/362#issuecomment-1220962556
	Local Static $_WD_DEBUG_Saved = Null ; this is static because this function will be run recurrently and we need to keep outer debug level
	If $_WD_DEBUG_Saved = Null Then
		$_WD_DEBUG_Saved = $_WD_DEBUG ; save current DEBUG level
		If $_WD_DEBUG_Saved <> $_WD_DEBUG_Full Then $_WD_DEBUG = $_WD_DEBUG_None ; Prevent logging multiple errors from __WD_FrameList_Internal
	EndIf

	_WD_FrameEnter($sSession, $sLevel)
	$iErr = @error
	If $iErr Then
		$sMessage = 'Error occurred on "' & $sLevel & '" level when trying to entering frame'
	Else
		_WD_LoadWait($sSession, 0, $iTimeout, Default, $_WD_READYSTATE_Complete) ; wait until current frame is fully loaded
		$iErr = @error
		If $iErr And $iErr <> $_WD_ERROR_Timeout Then
			$sMessage = 'Error occurred on "' & $sLevel & '" level when waiting for a browser page load to complete'
		Else
			$sCurrentBody_ElementID = _WD_ExecuteScript($sSession, "return window.document.body;", Default, Default, $_WD_JSON_Element)
			$iErr = @error
			If $iErr Then
				$sMessage = 'Error occurred on "' & $sLevel & '" level when checking "document.body" ElementID'
			Else
				$s_URL = _WD_ExecuteScript($sSession, "return window.location.href", Default, Default, $_WD_JSON_Value)
				$iErr = @error
				If $iErr Then
					$sMessage = 'Error occurred on "' & $sLevel & '" level when checking URL'
				EndIf
			EndIf
		EndIf
	EndIf
	$vResult = $sLevel & '|' & $sLevel & '|' & $sFrameAttributes & '|' & $s_URL & '|' & $sCurrentBody_ElementID & '|' & $bIsHidden & '|' & @CRLF

	If Not $iErr Then
		Local $iFrameCount = _WD_GetFrameCount($sSession)
		$iErr = @error
		If $iErr Then
			$sMessage = 'Error occurred on "' & $sLevel & '" level when trying to check frames count'
		Else
			Local $sFrameElementID
			Local Const $sJavaScript_FrameAttributes = "function FrameAttributes(FrameIDX) { let nodes = document.querySelectorAll('iframe');    if (nodes.length)   { return nodes[FrameIDX].outerHTML; }   else   { return window.frames[FrameIDX].frameElement.outerHTML; } }; return FrameAttributes(%s);"
			Local Const $sJavaScript_FrameElementID = "function FrameElementID(FrameIDX) { let nodes = document.querySelectorAll('iframe');    if (nodes.length)   { return nodes[FrameIDX]; }   else   { return document.querySelectorAll('frame')[FrameIDX]; } }; return FrameElementID(%s);"
			For $iFrame = 0 To $iFrameCount - 1
				If $sMessage Or $iErr Then ; message from last subframe is logged in the end of this function - not within For To Next loop
					$_WD_DEBUG = $_WD_DEBUG_Saved ; turn off prevention for a moment
					__WD_Error($sFuncName, $iErr, $sParameters & '	Information: ' & $sMessage) ; log messages which comes from loop processing
					If $_WD_DEBUG <> $_WD_DEBUG_Full Then $_WD_DEBUG = $_WD_DEBUG_None ; again turn on prevention
				EndIf
				$sMessage = '' ; clear recent/previous message
				$sFrameAttributes = _WD_ExecuteScript($sSession, StringFormat($sJavaScript_FrameAttributes, $iFrame), Default, Default, $_WD_JSON_Value)
				$iErr = @error
				If $iErr Then
					$sMessage = 'Error occurred on "' & $sLevel & '" level when trying to check attributes of subframe "' & $sLevel & '/' & $iFrame & '"'
					ContinueLoop
				Else
					$sFrameAttributes = StringRegExpReplace($sFrameAttributes, '\R', '')
					$sFrameElementID = _WD_ExecuteScript($sSession, StringFormat($sJavaScript_FrameElementID, $iFrame), Default, Default, $_WD_JSON_Element)
					$iErr = @error
					If $iErr Then
						$sMessage = 'Error occurred on "' & $sLevel & '" level when trying to get ElementID of subframe "' & $sLevel & '/' & $iFrame & '"'
						ContinueLoop
					Else
						$bIsHidden = Not (_WD_ElementAction($sSession, $sFrameElementID, 'DISPLAYED'))
						$iErr = @error
						If $iErr Then
							$sMessage = 'Error occurred on "' & $sLevel & '" level when trying to check visibility of subframe "' & $sLevel & '/' & $iFrame & '"'
							ContinueLoop
						Else
							$vResult &= __WD_FrameList_Internal($sSession, $sLevel & '/' & $iFrame, $sFrameAttributes, $bIsHidden, $iTimeout)
							$iErr = @error
							If $iErr Then
								$sMessage = 'Error occurred on "' & $sLevel & '" level after processing subframe "' & $sLevel & '/' & $iFrame & '"'
								ContinueLoop
							Else
								_WD_FrameLeave($sSession)
								$iErr = @error
								If $iErr Then
									$sMessage = 'Error occurred on "' & $sLevel & '" level when trying to leave subframe "' & $sLevel & '/' & $iFrame & '"'
									ExitLoop
								EndIf
							EndIf
						EndIf
					EndIf
				EndIf
			Next
		EndIf
	EndIf

	If $sLevel = 'null' Then ; checking if exiting main (top level) __WD_FrameList_Internal() call
		$_WD_DEBUG = $_WD_DEBUG_Saved ; restore DEBUG level
		$_WD_DEBUG_Saved = Null ; reset staticly defined saved debug level in order to get new one when function will be called from user script
	EndIf
	#EndRegion ; this region is prevented from redundant logging if not in Full debug mode - https://github.com/Danp2/au3WebDriver/pull/362#issuecomment-1220962556

	$sMessage = ($sMessage And $_WD_DEBUG > $_WD_DEBUG_Error) ? ('	Information: ' & $sMessage) : ("")
	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters & $sMessage), 0, $vResult)
EndFunc   ;==>__WD_FrameList_Internal

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
; Related .......: _WD_LastHTTPResult
; Link ..........: https://www.autoitscript.com/forum/topic/192730-webdriver-udf-help-support/?do=findComment&comment=1396643
; Example .......: No
; ===============================================================================================================================
Func _WD_HighlightElements($sSession, $vElements, $iMethod = Default)
	Local Const $sFuncName = "_WD_HighlightElements"
	Local Const $sParameters = 'Parameters:    Element=' & (IsArray($vElements) ? "<array>" : $vElements) & '    Method=' & $iMethod
	Local Const $aMethod[] = _
			[ _
			"border: 0px;", _
			"border: 2px dotted red;", _
			"background: #FFFF66; border-radius: 5px; padding-left: 3px;", _
			"border: 2px dotted red; background: #FFFF66; border-radius: 5px; padding-left: 3px;" _
			]
	Local $sScript, $iErr, $sElements
	$_WD_HTTPRESULT = 0
	$_WD_HTTPRESPONSE = ''

	If $iMethod = Default Then $iMethod = 1
	If $iMethod < 0 Or $iMethod > 3 Then $iMethod = 1

	If IsString($vElements) Then
		$sScript = "arguments[0].style='" & $aMethod[$iMethod] & "'; return true;"
		_WD_ExecuteScript($sSession, $sScript, __WD_JsonElement($vElements), Default, $_WD_JSON_Value)
		$iErr = @error

	ElseIf IsArray($vElements) And UBound($vElements) > 0 Then
		For $i = 0 To UBound($vElements) - 1
			$vElements[$i] = __WD_JsonElement($vElements[$i])
		Next

		$sElements = "[" & _ArrayToString($vElements, ",") & "]"
		$sScript = "for (var i = 0, max = arguments[0].length; i < max; i++) { arguments[0][i].style = '" & $aMethod[$iMethod] & "'; }; return true;"
		_WD_ExecuteScript($sSession, $sScript, $sElements, Default, $_WD_JSON_Value)
		$iErr = @error
	Else
		$iErr = $_WD_ERROR_InvalidArgue
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters), 0, ($iErr = $_WD_ERROR_Success))
EndFunc   ;==>_WD_HighlightElements

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_LoadWait
; Description ...: Wait for a browser page load to complete before returning.
; Syntax ........: _WD_LoadWait($sSession[, $iDelay = Default[, $iTimeout = Default[, $sElement = Default[, $iState = Default]]]])
; Parameters ....: $sSession - Session ID from _WD_CreateSession
;                  $iDelay   - [optional] Milliseconds to wait before initially checking status
;                  $iTimeout - [optional] Period of time (in milliseconds) to wait before exiting function
;                  $sElement - [optional] Element ID (from _WD_FindElement or _WD_WaitElement) to confirm DOM invalidation
;                  $iState   - [optional] Minimal desired ReadyState that is expected. Default is $_WD_READYSTATE_Complete.
; Return values .: Success - 1.
;                  Failure - 0 and sets @error to one of the following values:
;                  - $_WD_ERROR_ContextInvalid
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_RetValue
;                  - $_WD_ERROR_Timeout
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......: Only the current document context is checked (frames must be checked individually)
; Related .......: _WD_LastHTTPResult
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_LoadWait($sSession, $iDelay = Default, $iTimeout = Default, $sElement = Default, $iState = Default)
	Local Const $sFuncName = "_WD_LoadWait"
	If $iState = Default Then $iState = $_WD_READYSTATE_Complete ; Fully loaded
	If Not (IsInt($iState) And $iState > 0 And $iState < $_WD_READYSTATE__COUNTER) Then $iState = $_WD_READYSTATE_Complete  ; Fully loaded
	Local Const $sDesiredState = _ArrayToString($aWD_READYSTATE, '', $iState, $_WD_READYSTATE__COUNTER - 1, '|', $_WD_READYSTATE_State, $_WD_READYSTATE_State)
	Local Const $sParameters = 'Parameters:    Delay=' & $iDelay & '    Timeout=' & $iTimeout & '    Element=' & $sElement & '    DesiredState=' & $sDesiredState
	Local $iErr, $iExt = 0, $sReadyState, $iIndex = -1
	$_WD_HTTPRESULT = 0
	$_WD_HTTPRESPONSE = ''

	If $iDelay = Default Then $iDelay = 0
	If $iTimeout = Default Then $iTimeout = $_WD_DefaultTimeout
	If $sElement = Default Then $sElement = ""

	__WD_Sleep($iDelay)
	$iErr = @error

	Local $hLoadWaitTimer = TimerInit()

	Local $_WD_DEBUG_Saved = $_WD_DEBUG ; save current DEBUG level to prevent multiple errors
	If $_WD_DEBUG <> $_WD_DEBUG_Full Then $_WD_DEBUG = $_WD_DEBUG_None ; Prevent logging from _WD_ElementAction if not in Full debug mode

	While True
		If $iErr Then ExitLoop

		If $sElement <> '' Then
			_WD_ElementAction($sSession, $sElement, 'name')

			Switch @error
				Case $_WD_ERROR_NoMatch
					$sElement = ''

				Case $_WD_ERROR_ContextInvalid
					$iErr = @error
					ExitLoop

				Case $_WD_ERROR_Success

				Case Else
					$iErr = $_WD_ERROR_Exception
					ExitLoop
			EndSwitch

			If $_WD_HTTPRESULT = $HTTP_STATUS_NOT_FOUND Then $sElement = ''
		Else
			$sReadyState = _WD_ExecuteScript($sSession, 'return document.readyState', '', Default, $_WD_JSON_Value)
			$iErr = @error

			If $iErr Then
				If $iErr <> $_WD_ERROR_ContextInvalid Then
					$iErr = $_WD_ERROR_Exception
				EndIf

				$sReadyState = ''
				ExitLoop
			EndIf

			If StringInStr($sDesiredState, $sReadyState) Then
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
	$_WD_DEBUG = $_WD_DEBUG_Saved ; restore DEBUG level

	If $sReadyState Then
		$iIndex = _ArraySearch($aWD_READYSTATE, $sReadyState, Default, Default, Default, Default, Default, $_WD_READYSTATE_State)
		If @error Then
			$iErr = $_WD_ERROR_RetValue
		Else
			$iExt = $iIndex
			$sReadyState &= ' (' & $aWD_READYSTATE[$iIndex][$_WD_READYSTATE_Desc] & ')'
		EndIf
	EndIf

	Local $iReturn = ($iErr) ? (0) : (1)
	Local $sMessage = $sParameters & '    : ReadyState= ' & $sReadyState
	Return SetError(__WD_Error($sFuncName, $iErr, $sMessage, $iExt), $iExt, $iReturn)
EndFunc   ;==>_WD_LoadWait

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_FrameListFindElement
; Description ...: Search the current document (including frames) and return locations of matching elements
; Syntax ........: _WD_FrameListFindElement($sSession, $sStrategy, $sSelector)
; Parameters ....: $sSession     - Session ID from _WD_CreateSession
;                  $sStrategy    - Locator strategy. See defined constant $_WD_LOCATOR_* for allowed values
;                  $sSelector    - $sSelector - Indicates how the WebDriver should traverse through the HTML DOM to locate the desired element(s).
; Return values .: Success - array of matching frames (format like in _WD_FrameList)
;                  Failure - "" (empty string) and sets @error to one of the following values:
;                  - $_WD_ERROR_GeneralError
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_NoMatch
; Author ........: mLipok
; Modified ......:
; Remarks .......: Returned location (path like 'null/2/0') can be used with _WD_FrameEnter before _WD_FindElement or _WD_WaitElement will be used.
;                  In case when $_WD_ERROR_Exception is set returned location is valid, but was not able back to calling frame,
;                  	or some frames have become inaccessible during processing
; Related .......: _Wd_FrameList, _WD_FindElement
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_FrameListFindElement($sSession, $sStrategy, $sSelector)
	Local Const $sFuncName = "_WD_FrameListFindElement"
	Local Const $sParameters = 'Parameters:   Strategy=' & $sStrategy & '   Selector=' & $sSelector
	Local $iErr = $_WD_ERROR_Success
	Local $sStartLocation = '', $sMessage = ''

	Local $aFrameList = _WD_FrameList($sSession, True)
	$iErr = @error
	If $iErr Then
		If Not $_WD_DetailedErrors Then $iErr = $_WD_ERROR_GeneralError
		$sMessage = ' > Issue with getting list of frames'
	Else
		Local $iFrameCount = UBound($aFrameList, $UBOUND_ROWS)
		For $i = 0 To $iFrameCount - 1
			If $aFrameList[$i][$_WD_FRAMELIST_Relative] = '' Then $sStartLocation = $aFrameList[$i][$_WD_FRAMELIST_Absolute]
		Next

		#Region ; this region is prevented from redundant logging ( _WD_FrameEnter and _WD_FindElement ) if not in Full debug mode > https://github.com/Danp2/au3WebDriver/pull/290#issuecomment-1100707095
		Local $_WD_DEBUG_Saved = $_WD_DEBUG ; save current DEBUG level
		If $_WD_DEBUG <> $_WD_DEBUG_Full Then $_WD_DEBUG = $_WD_DEBUG_None

		For $i = $iFrameCount - 1 To 0 Step -1
			_WD_FrameEnter($sSession, $aFrameList[$i][$_WD_FRAMELIST_Absolute])
			$iErr = @error
			If $iErr Then
				If Not $_WD_DetailedErrors Then $iErr = $_WD_ERROR_Exception
				$sMessage = ' > Issue with entering frame=' & $aFrameList[$i][$_WD_FRAMELIST_Absolute] & '  URL=' & $aFrameList[$i][$_WD_FRAMELIST_URL]
				ExitLoop
			Else
				$aFrameList[$i][$_WD_FRAMELIST_MatchedElements] = _WD_FindElement($sSession, $sStrategy, $sSelector, Default, True, Default)
				$iErr = @error
				If $iErr = $_WD_ERROR_Success Then
					ContinueLoop ; keep the frame in the list and continue searching in next frame
				ElseIf $iErr = $_WD_ERROR_NoMatch Then ; element was not found on location: ' & $aFrameList[$i][$_WD_FRAMELIST_Absolute]
					_ArrayDelete($aFrameList, $i) ; delete frame from the list because the searched element do not exist within the frame
					ContinueLoop
				Else
					If Not $_WD_DetailedErrors Then $iErr = $_WD_ERROR_Exception
					$sMessage = ' > Issue with finding element in frame=' & $aFrameList[$i][$_WD_FRAMELIST_Absolute] & '  URL=' & $aFrameList[$i][$_WD_FRAMELIST_URL]
					$aFrameList[$i][$_WD_FRAMELIST_MatchedElements] = ''
					ExitLoop
				EndIf
			EndIf
		Next

		If $i = -1 Then ; all frames was checked
			If UBound($aFrameList) Then
				$iErr = $_WD_ERROR_Success
			Else
				$iErr = $_WD_ERROR_NoMatch
			EndIf
		EndIf

		If $sStartLocation Then ; Back to "calling frame"
			_WD_FrameEnter($sSession, $sStartLocation)
			$iErr = @error
			If $iErr Then
				$sMessage &= ' > Was not able to back to "calling frame" : StartLocation=' & $sStartLocation
				If Not $_WD_DetailedErrors Then $iErr = $_WD_ERROR_Exception
			EndIf
		EndIf

		$_WD_DEBUG = $_WD_DEBUG_Saved ; restore DEBUG level
		$sMessage = $sParameters & $sMessage
		#EndRegion ; this region is prevented from redundant logging ( _WD_FrameEnter and _WD_FindElement ) if not in Full debug mode > https://github.com/Danp2/au3WebDriver/pull/290#issuecomment-1100707095
	EndIf

	Local $iExt = UBound($aFrameList, $UBOUND_ROWS)
	If $iErr Or $iExt = 0 Then $aFrameList = ''
	Return SetError(__WD_Error($sFuncName, $iErr, $sMessage, $iExt), $iExt, $aFrameList)
EndFunc   ;==>_WD_FrameListFindElement

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
; Related .......: _WD_Window, _WD_ElementAction, _WD_LastHTTPResult
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_Screenshot($sSession, $sElement = Default, $iOutputType = Default)
	Local Const $sFuncName = "_WD_Screenshot"
	Local Const $sParameters = 'Parameters:    Element=' & $sElement & '    OutputType=' & $iOutputType
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

	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters), 0, $vResult)
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
; Remarks .......: Chromedriver currently requires headless mode (https://bugs.chromium.org/p/chromedriver/issues/detail?id=3517).
; Related .......: _WD_Window, _WD_LastHTTPResult
; Link ..........: https://www.w3.org/TR/webdriver/#print-page
; Example .......: No
; ===============================================================================================================================
Func _WD_PrintToPDF($sSession, $sOptions = Default)
	Local Const $sFuncName = "_WD_PrintToPDF"
	Local Const $sParameters = 'Parameters:    Options=' & $sOptions
	Local $sResponse, $sResult, $iErr

	If $sOptions = Default Then $sOptions = $_WD_EmptyDict

	$sResponse = _WD_Window($sSession, 'print', $sOptions)
	$iErr = @error

	If $iErr = $_WD_ERROR_Success Then
		$sResult = __WD_Base64Decode($sResponse)
	Else
		$sResult = ''
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters), 0, $sResult)
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
; Related .......: _WD_ExecuteScript, _WD_LastHTTPResult
; Link ..........: https://sqa.stackexchange.com/questions/2921/webdriver-can-i-inject-a-jquery-script-for-a-page-that-isnt-using-jquery
; Example .......: No
; ===============================================================================================================================
Func _WD_jQuerify($sSession, $sjQueryFile = Default, $iTimeout = Default)
	Local Const $sFuncName = "_WD_jQuerify"
	Local Const $sParameters = 'Parameters:    File=' & $sjQueryFile & '    Timeout=' & $iTimeout

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

	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters))
EndFunc   ;==>_WD_jQuerify

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_ElementOptionSelect
; Description ...: Find and click on an option from a Select element.
; Syntax ........: _WD_ElementOptionSelect($sSession, $sStrategy, $sSelector[, $sStartNodeID = Default])
; Parameters ....: $sSession      - Session ID from _WD_CreateSession
;                  $sStrategy     - Locator strategy. See defined constant $_WD_LOCATOR_* for allowed values
;                  $sSelector     - Indicates how the WebDriver should traverse through the HTML DOM to locate the desired element(s).  Should point to <option> in element of type '<select>'
;                  $sStartNodeID  - [optional] Element ID to use as starting HTML node. Default is ""
; Return values .: Success - None.
;                  Failure - None and sets @error to one of the following values:
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_NoMatch
;                  - $_WD_ERROR_InvalidDataType
;                  - $_WD_ERROR_InvalidExpression
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......: _WD_FindElement, _WD_ElementAction, _WD_LastHTTPResult
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_ElementOptionSelect($sSession, $sStrategy, $sSelector, $sStartNodeID = Default)
	Local Const $sFuncName = "_WD_ElementOptionSelect"
	Local Const $sParameters = 'Parameters:    Strategy=' & $sStrategy & '    Selector=' & $sSelector & '    StartElement=' & $sStartNodeID
	If $sStartNodeID = Default Then $sStartNodeID = ""

	Local $sElement = _WD_FindElement($sSession, $sStrategy, $sSelector, $sStartNodeID)

	If @error = $_WD_ERROR_Success Then
		_WD_ElementAction($sSession, $sElement, 'click')
	EndIf

	Return SetError(__WD_Error($sFuncName, @error, $sParameters))
EndFunc   ;==>_WD_ElementOptionSelect

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_ElementSelectAction
; Description ...: Perform action on designated <select> element.
; Syntax ........: _WD_ElementSelectAction($sSession, $sSelectElement, $sCommand[, $vLabels = Default])
; Parameters ....: $sSession       - Session ID from _WD_CreateSession
;                  $sSelectElement - Element ID of <select> element from _WD_FindElement
;                  $sCommand       - Action to be performed. Can be one of the following:
;                  |DESELECTALL    - Clear all selections
;                  |MULTISELECT    - Select <option> elements given in 1D array of labels
;                  |OPTIONS        - Retrieves all <option> elements as 2D array
;                  |SELECTALL      - Select all <option> elements
;                  |SELECTEDINDEX  - Retrieves 0-based index of the first selected <option> element
;                  |SELECTEDLABELS - Retrieves labels of selected <option> elements as 1D array
;                  |SELECTEDOPTIONS- Retrieves selected <option> elements as 2D array
;                  |SINGLESELECT   - Select <option> element given as string and deselect all others
;                  |VALUE          - Retrieves value of the first selected <option> element
;                  $vLabels        - [optional] List of labels (depending on chosen $sCommand)
; Return values .: Success - Requested data returned by web driver.
;                  Failure - "" (empty string) and sets @error to one of the following values:
;                  - $_WD_ERROR_ElementIssue
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_GeneralError
;                  - $_WD_ERROR_InvalidArgue
;                  - $_WD_ERROR_InvalidDataType
;                  - $_WD_ERROR_InvalidExpression
;                  - $_WD_ERROR_NoMatch
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......: If no option is selected, SELECTEDINDEX will return -1.
; Related .......: _WD_FindElement, _WD_ExecuteScript
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_ElementSelectAction($sSession, $sSelectElement, $sCommand, $vLabels = Default)
	Local Const $sFuncName = "_WD_ElementSelectAction"
	Local $sLabelsTemp = ($_WD_DEBUG = $_WD_DEBUG_Full) ? ($vLabels) : ("(string)")
	Local Const $sParameters = 'Parameters:    Command=' & $sCommand & '    Labels=' & ((IsArray($vLabels)) ? ("(array)") : ($sLabelsTemp))
	Local $vResult, $sScript
	Local Static $sScript_MultiSelectTemplate = StringReplace( _ ; it is declared as static to optimize AutoIt processing speed - this line will be processed once per script run
			"function MultiSelectOption(SelectElement, LabelsToSelect, AllowMultiple) {" & _
			"	if (AllowMultiple && SelectElement.multiple == false) {" & _
			"		return '';" & _
			"	}" & _
			"	const LabelsUpperCased = LabelsToSelect.map( function(value) { return value.toUpperCase(); } );" & _ ; https://stackoverflow.com/a/24718430/5314940
			"	const options = SelectElement.options;" & _
			"	let result = false;" & _
			"	for (let i = 0, o, IsDisabled, IsHidden, Matching; i < options.length; i++) {" & _
			"		o = options[i];" & _
			"		Matching = ( LabelsUpperCased.indexOf( o.label.toUpperCase() ) != -1 );" & _
			"		if (Matching) {" & _
			"			IsDisabled =	( o.disabled	|| (o.parentNode.nodeName == 'OPTGROUP' && o.parentNode.disabled) );" & _
			"			IsHidden =		( o.hidden		|| (o.parentNode.nodeName == 'OPTGROUP' && o.parentNode.hidden) );" & _
			"			if (AllowMultiple) {" & _
			"				if (!(IsDisabled || IsHidden)) {" & _
			"					o.selected = true;" & _
			"					result = true;" & _
			"				}" & _
			"			} else {" & _
			"				if (IsDisabled || IsHidden) {" & _
			"					result = '';" & _
			"				} else {" & _
			"					SelectElement.selectedIndex = -1;" & _
			"					o.selected = true;" & _
			"					result = true;" & _
			"				}" & _
			"				break;" & _
			"			}" & _
			"		}" & _
			"	}" & _
			"	if (result == true) {" & _
			"		SelectElement.dispatchEvent(new Event('change', {bubbles: true}));" & _
			"	}" & _
			"	return result;" & _
			"};" & _
			"var SelectElement = arguments[0];" & _
			"var LabelsToSplit = arguments[1];" & _ ; Label1||Label2
			"var LabelsToSelect = LabelsToSplit.split('||');" & _ ; ['Label1', 'Label2']
			"var AllowMultiple = arguments[2];" & _ ; true or false
			"return MultiSelectOption(SelectElement, LabelsToSelect, AllowMultiple);" & _
			"", @TAB, '')

	; Save current debug level and set to none to reduce excessive logging
	Local $WDDebugSave = $_WD_DEBUG
	If $_WD_DEBUG <> $_WD_DEBUG_Full Then $_WD_DEBUG = $_WD_DEBUG_None

	Local $sNodeName = _WD_ElementAction($sSession, $sSelectElement, 'property', 'nodeName')
	Local $iErr = @error, $iExt = 0

	If $iErr <> $_WD_ERROR_Success Then
		$iErr = $_WD_ERROR_GeneralError
	Else
		If $sNodeName = 'select' Then ; check if designated element is <select> element
			Switch $sCommand
				Case 'deselectAll'
					$sScript = _
							"var SelectElement = arguments[0];" & _
							"SelectElement.selectedIndex = -1;" & _
							"SelectElement.dispatchEvent(new Event('change', {bubbles: true}));" & _
							"return true;"
					$vResult = _WD_ExecuteScript($sSession, $sScript, __WD_JsonElement($sSelectElement), Default, $_WD_JSON_Value)
					$iErr = @error

				Case 'multiSelect' ; https://stackoverflow.com/a/1296068/5314940
					; Should be a single dimensional, non-empty array
					If UBound($vLabels, $UBOUND_DIMENSIONS) <> 1 Or UBound($vLabels, $UBOUND_ROWS) = 0 Then
						$iErr = $_WD_ERROR_InvalidArgue
						$iExt = 41 ; $iExt from 41 to 49 are related to _WD_ElementSelectAction()
					Else
						$vLabels = StringReplace(_ArrayToString($vLabels, "||"), '"', '\"') ; labels can contains double quotation marks
						$vLabels = __WD_JsonElement($sSelectElement) & ',"' & $vLabels & '", true'
						$vResult = _WD_ExecuteScript($sSession, $sScript_MultiSelectTemplate, $vLabels, Default, $_WD_JSON_Value)
						$iErr = @error
						If Not @error Then
							If $vResult == '' Then
								$iErr = $_WD_ERROR_ElementIssue
							ElseIf $vResult = False Then
								$iErr = $_WD_ERROR_NoMatch
							EndIf
						EndIf
					EndIf

				Case 'singleSelect'
					; Should be a non empty string
					If Not (IsString($vLabels) And StringLen($vLabels)) Then
						$iErr = $_WD_ERROR_InvalidArgue
						$iExt = 42 ; $iExt from 41 to 49 are related to _WD_ElementSelectAction()
					Else
						$vLabels = StringReplace($vLabels, '"', '\"') ; labels can contains double quotation marks
						$vLabels = __WD_JsonElement($sSelectElement) & ',"' & $vLabels & '", false'
						$vResult = _WD_ExecuteScript($sSession, $sScript_MultiSelectTemplate, $vLabels, Default, $_WD_JSON_Value)
						$iErr = @error
						If Not @error Then
							If $vResult == '' Then
								$iErr = $_WD_ERROR_ElementIssue
							ElseIf $vResult = False Then
								$iErr = $_WD_ERROR_NoMatch
							EndIf
						EndIf
					EndIf

				Case 'options' ; 7 columns (value, label, index, selected status, disabled status, hidden status and group name)
					Local Static $sScript_OptionsTemplate = StringReplace( _
							"function GetOptions(SelectElement) {" & _
							"	let result ='';" & _
							"	const options = SelectElement.options;" & _
							"	for (let i = 0, o, IsDisabled, IsHidden, GroupName; i < options.length; i++) {" & _
							"		o = options[i];" & _
							"		IsDisabled =	( o.disabled	|| (o.parentNode.nodeName == 'OPTGROUP' && o.parentNode.disabled) );" & _
							"		IsHidden =		( o.hidden		|| (o.parentNode.nodeName == 'OPTGROUP' && o.parentNode.hidden) );" & _
							"		GroupName = (o.parentNode.nodeName == 'OPTGROUP' ? o.parentNode.label : '');" & _
							"		result += o.value + '|' + o.label + '|' + o.index + '|' + o.selected + '|' + IsDisabled + '|' + IsHidden + '|' + GroupName + '\n';" & _
							"	}" & _
							"	return result;" & _
							"}" & _
							"var SelectElement = arguments[0];" & _
							"return GetOptions(SelectElement);" & _
							"", @TAB, '')

					$vResult = _WD_ExecuteScript($sSession, $sScript_OptionsTemplate, __WD_JsonElement($sSelectElement), Default, $_WD_JSON_Value)
					$iErr = @error

					If $iErr = $_WD_ERROR_Success Then
						Local $aAllOptions[0][7]
						_ArrayAdd($aAllOptions, StringStripWS($vResult, $STR_STRIPTRAILING), 0, Default, @LF, $ARRAYFILL_FORCE_SINGLEITEM)
						$vResult = $aAllOptions
					EndIf

				Case 'selectAll'
					Local Static $sScript_SelectAllTemplate = StringReplace( _
							"function SelectAll(SelectElement) {" & _
							"	if (SelectElement.multiple == false) {" & _
							"		return '';" & _
							"	};" & _
							"	const options = SelectElement.options;" & _
							"	let waschanged = false;" & _
							"	for (let i = 0, o, IsDisabled, IsHidden; i < options.length; i++) {" & _
							"		o = options[i];" & _
							"		IsDisabled =	( o.disabled	|| (o.parentNode.nodeName == 'OPTGROUP' && o.parentNode.disabled) );" & _
							"		IsHidden =		( o.hidden		|| (o.parentNode.nodeName == 'OPTGROUP' && o.parentNode.hidden) );" & _
							"		if ( !(IsDisabled || IsHidden || o.selected) ) {" & _
							"			o.selected = true;" & _
							"			waschanged = true;" & _
							"		};" & _
							"	};" & _
							"	if (waschanged==true) {" & _
							"		SelectElement.dispatchEvent(new Event('change', {bubbles: true}));" & _
							"	};" & _
							"	return waschanged;" & _
							"};" & _
							"var SelectElement = arguments[0];" & _
							"return SelectAll(SelectElement);" & _
							"", @TAB, '')
					$vResult = _WD_ExecuteScript($sSession, $sScript_SelectAllTemplate, __WD_JsonElement($sSelectElement), Default, $_WD_JSON_Value)
					$iErr = @error
					If Not @error And $vResult == '' Then
						$iErr = $_WD_ERROR_ElementIssue
					ElseIf $vResult = False Then
						$iErr = $_WD_ERROR_NoMatch
					EndIf

				Case 'selectedIndex'
					$sScript = "return arguments[0].selectedIndex"
					$vResult = _WD_ExecuteScript($sSession, $sScript, __WD_JsonElement($sSelectElement), Default, $_WD_JSON_Value)
					$iErr = @error

				Case 'selectedLabels'
					Local Static $sScript_SelectedLabelsTemplate = StringReplace( _
							"function GetSelecteLabels(SelectElement) {" & _
							"	let result ='';" & _
							"	const options = SelectElement.selectedOptions;" & _
							"	for (let i = 0, o; i < options.length; i++)	{" & _
							"		o = options[i];" & _
							"		result += o.label + '\n';" & _
							"	};" & _
							"	return result;" & _
							"};" & _
							"var SelectElement = arguments[0];" & _
							"return GetSelecteLabels(SelectElement);" & _
							"", @TAB, '')
					$vResult = _WD_ExecuteScript($sSession, $sScript_SelectedLabelsTemplate, __WD_JsonElement($sSelectElement), Default, $_WD_JSON_Value)
					$iErr = @error

					If $iErr = $_WD_ERROR_Success Then
						Local $aSelectedLabels[0]
						_ArrayAdd($aSelectedLabels, StringStripWS($vResult, $STR_STRIPTRAILING), 0, @LF, "", $ARRAYFILL_FORCE_DEFAULT)
						$vResult = $aSelectedLabels
					EndIf

				Case 'selectedOptions' ; 4 columns (value, label, index and group name)
					Local Static $sScript_SelectedOptionsTemplate = StringReplace( _
							"function GetSelectedOptions(SelectElement) {" & _
							"	let result ='';" & _
							"	const options = SelectElement.selectedOptions;" & _
							"	for (let i = 0, o, GroupName; i < options.length; i++) {" & _
							"		o = options[i];" & _
							"		GroupName = (o.parentNode.nodeName == 'OPTGROUP' ? o.parentNode.label : '');" & _
							"		result += o.value + '|' + o.label + '|' + o.index + '|' + GroupName + '\n';" & _
							"	};" & _
							"	return result;" & _
							"}" & _
							"var SelectElement = arguments[0];" & _
							"return GetSelectedOptions(SelectElement);" & _
							"", @TAB, '')
					$vResult = _WD_ExecuteScript($sSession, $sScript_SelectedOptionsTemplate, __WD_JsonElement($sSelectElement), Default, $_WD_JSON_Value)
					$iErr = @error

					If $iErr = $_WD_ERROR_Success Then
						Local $aSelectedOptions[0][4]
						_ArrayAdd($aSelectedOptions, StringStripWS($vResult, $STR_STRIPTRAILING), 0, Default, @LF, $ARRAYFILL_FORCE_SINGLEITEM)
						$vResult = $aSelectedOptions
					EndIf

				Case 'value'
					$sScript = "return arguments[0].value"
					$vResult = _WD_ExecuteScript($sSession, $sScript, __WD_JsonElement($sSelectElement), Default, $_WD_JSON_Value)
					$iErr = @error

				Case Else
					Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(deselectAll|multiSelect|options|selectAll|selectedIndex|selectedLabels|selectedOptions|singleSelect|value) $sCommand=>" & $sCommand), 0, "")

			EndSwitch
		Else
			$iErr = $_WD_ERROR_InvalidArgue
			$iExt = 49 ; $iExt from 41 to 49 are related to _WD_ElementSelectAction()
		EndIf
	EndIf

	; Restore prior setting
	$_WD_DEBUG = $WDDebugSave

	Local $sMessage = $sParameters & '    : Result = ' & ((IsArray($vResult)) ? ("(array)") : ($vResult))
	Return SetError(__WD_Error($sFuncName, $iErr, $sMessage, $iExt), $iExt, $vResult)
EndFunc   ;==>_WD_ElementSelectAction

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_ElementStyle
; Description ...: Set/Get element style CSSProperty
; Syntax ........: _WD_ElementStyle($sSession, $sElement, $sCSSProperty, $sValue)
; Parameters ....: $sSession - Session ID from _WD_CreateSession
;                  $sElement - Element ID from _WD_FindElement
;                  $sCSSProperty - Style property name to be set or retrieved
;                  $sValue - New value to be set; current value will be retrieved when not supplied (Default)
; Return values .: Success - Requested style value(s) returned by the webdriver
;                  Failure - Response from webdriver and sets @error returned from _WD_ExecuteScript() or $_WD_ERROR_NotSupported or $_WD_ERROR_NoMatch
; Author ........: mLipok
; Modified ......: Danp2
; Remarks .......: An array of current styles and their values will be returned when $sCSSProperty is not defined (Default)
; Related .......:
; Link ..........:
; Example .......: _WD_ElementStyle($sSession, $sElement, 'fontFamily', '"Lucida Console", "Courier New", monospace')
; ===============================================================================================================================
Func _WD_ElementStyle($sSession, $sElement, $sCSSProperty = Default, $sValue = Default)
	Local Const $sFuncName = "_WD_ElementStyle"
	Local $vResult, $iErr = $_WD_ERROR_Success
	Local $sJavaScript = ''

	If IsString($sCSSProperty) And $sValue <> Default Then ; set property value
		$sJavaScript = _
				"var element = arguments[0];" & _
				"element.style." & $sCSSProperty & " = '" & $sValue & "';"
		$vResult = _WD_ExecuteScript($sSession, $sJavaScript, __WD_JsonElement($sElement), Default, Default)
		$iErr = @error
	ElseIf IsString($sCSSProperty) And $sValue = Default Then ; get specific property value
		$sJavaScript = _
				"var myelement = arguments[0];" & _
				"return GetPropertyValue(myelement);" & _
				"" & _
				"function GetPropertyValue(element) {" & _
				"   var search = '" & $sCSSProperty & "';" & _
				"   var propertyname = '';" & _
				"   for (let i = 0; i < element.style.length; i++) {" & _
				"      propertyname = element.style.item(i);" & _
				"      if (propertyname == search) {return element.style.getPropertyValue(propertyname);}" & _
				"   }" & _
				"   return '';" & _
				"}"
		$vResult = _WD_ExecuteScript($sSession, $sJavaScript, __WD_JsonElement($sElement), Default, $_WD_JSON_Value)
		$iErr = @error
	ElseIf $sCSSProperty = Default And $sValue = Default Then ; get list of properties and their values
		$sJavaScript = _
				"var myelement = arguments[0];" & _
				"return GetProperties(myelement);" & _
				"" & _
				"function GetProperties(element) {" & _
				"   var result = '';" & _
				"   var propertyname = '';" & _
				"   for (let i = 0; i < element.style.length; i++) {" & _
				"      propertyname = element.style.item(i);" & _
				"      result += propertyname + ':' + element.style.getPropertyValue(propertyname) + ';'" & _
				"   }" & _
				"   return result.slice(0, result.length -1);" & _
				"}"
		$sJavaScript = StringReplace($sJavaScript, @TAB, '')
		$vResult = _WD_ExecuteScript($sSession, $sJavaScript, __WD_JsonElement($sElement), Default, $_WD_JSON_Value)
		$iErr = @error
		If $iErr = $_WD_ERROR_Success And $vResult == '' Then
			$iErr = $_WD_ERROR_NoMatch
		ElseIf $iErr = $_WD_ERROR_Success Then
			Local $aProperties[0][2]
			_ArrayAdd($aProperties, StringStripWS($vResult, $STR_STRIPTRAILING), 0, ':', ';', $ARRAYFILL_FORCE_SINGLEITEM)
			$vResult = $aProperties
		EndIf
	Else
		$iErr = $_WD_ERROR_NotSupported
	EndIf
	Return SetError(__WD_Error($sFuncName, $iErr), 0, $vResult)
EndFunc   ;==>_WD_ElementStyle

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
; Syntax ........: _WD_GetShadowRoot($sSession, $sStrategy, $sSelector[, $sStartNodeID = Default])
; Parameters ....: $sSession      - Session ID from _WD_CreateSession
;                  $sStrategy     - Locator strategy. See defined constant $_WD_LOCATOR_* for allowed values
;                  $sSelector     - Indicates how the WebDriver should traverse through the HTML DOM to locate the desired element(s).
;                  $sStartNodeID  - [optional] Element ID to use as starting HTML node. Default is ""
; Return values .: Success - Element ID returned by web driver.
;                  Failure - "" (empty string) and sets @error to one of the following values:
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_NoMatch
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......: _WD_FindElement, _WD_ElementAction, _WD_LastHTTPResult
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_GetShadowRoot($sSession, $sStrategy, $sSelector, $sStartNodeID = Default)
	Local Const $sFuncName = "_WD_GetShadowRoot"
	Local Const $sParameters = 'Parameters:    Strategy=' & $sStrategy & '    Selector=' & $sSelector & '    StartElement=' & $sStartNodeID
	Local $sResponse, $sResult = "", $oJSON

	If $sStartNodeID = Default Then $sStartNodeID = ""

	Local $sElement = _WD_FindElement($sSession, $sStrategy, $sSelector, $sStartNodeID)
	Local $iErr = @error

	If $iErr = $_WD_ERROR_Success Then
		$sResponse = _WD_ElementAction($sSession, $sElement, 'shadow')
		$iErr = @error

		If $iErr = $_WD_ERROR_Success Then
			$oJSON = Json_Decode($sResponse)
			$sResult = Json_Get($oJSON, $_WD_JSON_Shadow)
		EndIf
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters), 0, $sResult)
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
; Remarks .......: If $sFilename is empty, then prior selection is cleared.
; Related .......: _WD_FindElement, _WD_ElementAction, _WD_LastHTTPResult
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_SelectFiles($sSession, $sStrategy, $sSelector, $sFilename)
	Local Const $sFuncName = "_WD_SelectFiles"
	Local Const $sParameters = 'Parameters:    Strategy=' & $sStrategy & '    Selector=' & $sSelector & '    Filename=' & $sFilename
	Local $sResult = "0"
	Local $sElement = _WD_FindElement($sSession, $sStrategy, $sSelector)
	Local $iErr = @error

	If $iErr = $_WD_ERROR_Success Then
		If $sFilename <> "" Then
			_WD_ElementAction($sSession, $sElement, 'value', $sFilename)
			$iErr = @error
		Else
			_WD_ElementAction($sSession, $sElement, 'clear')
			$iErr = @error
		EndIf

		If $iErr = $_WD_ERROR_Success Then
			$sResult = _WD_ExecuteScript($sSession, "return arguments[0].files.length", __WD_JsonElement($sElement), Default, $_WD_JSON_Value)
			$iErr = @error
			If $iErr Then $sResult = "0"
		EndIf
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters), 0, $sResult)
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
			Local $nStatus = _VersionCompare($__WDVERSION, $sLatestWDVersion)  ; 0 - Both versions equal ; 1 - Version1 greater ; -1 - Version2 greater
			$bResult = ($nStatus >= 0)
		Else
			$iErr = $_WD_ERROR_Exception
		EndIf
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr, String($bResult)), 0, $bResult)
EndFunc   ;==>_WD_IsLatestRelease

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_UpdateDriver
; Description ...: Replace web driver with newer version, if available.
; Syntax ........: _WD_UpdateDriver($sBrowser[, $sInstallDir = Default[, $bFlag64 = Default[, $bForce = Default[, $bDowngrade = Default]]]])
; Parameters ....: $sBrowser    - Browser name or full path to browser executable
;                  $sInstallDir - [optional] Install directory. Default is @ScriptDir
;                  $bFlag64     - [optional] Install 64bit version? Default is current driver architecture or False
;                  $bForce      - [optional] Force update? Default is False
;                  $bDowngrade  - [optional] Downgrade to match browser version if needed? Default is False
; Return values .: Success - True (Driver was updated).
;                  Failure - False (Driver was not updated) and sets @error to one of the following values:
;                  - $_WD_ERROR_FileIssue
;                  - $_WD_ERROR_GeneralError
;                  - $_WD_ERROR_InvalidValue
;                  - $_WD_ERROR_Mismatch
;                  - $_WD_ERROR_NotFound
;                  - $_WD_ERROR_NotSupported
;                  - $_WD_ERROR_UserAbort
; Author ........: Danp2, CyCho
; Modified ......: mLipok
; Remarks .......: When $bForce = Null, then the function will check for an updated webdriver without actually performing the update.
;                  This can be used in conjunction with $bDowngrade to determine if the existing webdriver is too new for the browser.
;                  In this scenario, the return value indicates if an update / downgrade is available.
; Related .......: _WD_GetBrowserVersion, _WD_GetWebDriverVersion
; Link ..........:
; Example .......: Local $bResult = _WD_UpdateDriver('FireFox')
; ===============================================================================================================================
Func _WD_UpdateDriver($sBrowser, $sInstallDir = Default, $bFlag64 = Default, $bForce = Default, $bDowngrade = Default)
	Local Const $sFuncName = "_WD_UpdateDriver"
	Local $iErr = $_WD_ERROR_Success, $iExt = 0, $sDriverEXE, $sBrowserVersion, $bResult = False
	Local $sDriverCurrent, $sDriverLatest, $sURLNewDriver
	Local $sTempFile
	Local $bKeepArch = False

	If $sInstallDir = Default Then $sInstallDir = @ScriptDir
	If $bForce = Default Then $bForce = False
	If $bFlag64 = Default Then
		$bFlag64 = False
		$bKeepArch = True
	EndIf
	If $bDowngrade = Default Then $bDowngrade = False

	$sInstallDir = StringRegExpReplace($sInstallDir, '(?i)(\\)\Z', '') & '\' ; prevent double \\ on the end of directory
	Local Const $bNoUpdate = (IsKeyword($bForce) = $KEYWORD_NULL) ; Flag to track if updates should be performed

	; If the Install directory doesn't exist and it can't be created, then set error
	If (Not FileExists($sInstallDir)) And (Not DirCreate($sInstallDir)) Then
		$iErr = $_WD_ERROR_InvalidValue
	Else
		; Save current debug level and set to none
		Local $WDDebugSave = $_WD_DEBUG
		If $_WD_DEBUG <> $_WD_DEBUG_Full Then $_WD_DEBUG = $_WD_DEBUG_None

		$sBrowserVersion = _WD_GetBrowserVersion($sBrowser)
		$iErr = @error
		$iExt = @extended

		If $iErr = $_WD_ERROR_Success Then
			Local $iIndex = @extended
			; Match exe file name in list of supported browsers
			$sDriverEXE = $_WD_SupportedBrowsers[$iIndex][$_WD_BROWSER_DriverName]

			; Determine current local webdriver Architecture
			If FileExists($sInstallDir & $sDriverEXE) Then
				_WinAPI_GetBinaryType($sInstallDir & $sDriverEXE)
				Local $bDriverIs64Bit = (@extended = $SCS_64BIT_BINARY)
				If $bKeepArch Then $bFlag64 = $bDriverIs64Bit
				If $_WD_SupportedBrowsers[$iIndex][$_WD_BROWSER_64Bit] And $bDriverIs64Bit <> $bFlag64 Then
					$bForce = True
				EndIf
			EndIf

			$sDriverCurrent = _WD_GetWebDriverVersion($sInstallDir, $sDriverEXE)
			; Determine latest available webdriver version for the designated browser
			Local $aBrowser = _ArrayExtract($_WD_SupportedBrowsers, $iIndex, $iIndex)
			Local $aDriverInfo = __WD_GetLatestWebdriverInfo($aBrowser, $sBrowserVersion, $bFlag64)
			$iErr = @error
			$iExt = @extended
			$sDriverLatest = $aDriverInfo[1]
			$sURLNewDriver = $aDriverInfo[0]

			If $iErr = $_WD_ERROR_Success Then
				Local $nStatus = _VersionCompare($sDriverCurrent, $sDriverLatest)  ; 0 - Both versions equal ; 1 - Version1 greater ; -1 - Version2 greater
				Local $bUpdateAvail = ($nStatus < 0)
				Local $bDowngradable = ($nStatus > 0)

				If $bNoUpdate Then
					; Set return value to indicate if newer / downgradable driver is available
					$bResult = ($bDowngrade) ? $bDowngradable : $bUpdateAvail

				ElseIf $bUpdateAvail Or $bForce Or ($bDowngrade And $bDowngradable) Then
					; @TempDir should be used to avoid potential AV problems, for example by downloading stuff to @DesktopDir
					$sTempFile = _TempFile(@TempDir, "webdriver_", ".zip")
					_WD_DownloadFile($sURLNewDriver, $sTempFile)
					If @error Then
						$iErr = @error
						$iExt = @extended
					Else
						; Close any instances of webdriver
						__WD_CloseDriver($sDriverEXE)

						; Extract
						__WD_UpdateExtractor($sTempFile, $sInstallDir, $sDriverEXE)
						$iErr = @error
						$iExt = @extended
						If Not @error Then $bResult = True
					EndIf
					FileDelete($sTempFile)

				ElseIf $bDowngradable Then
					$iErr = $_WD_ERROR_Mismatch
				EndIf
			EndIf
		EndIf

		; Restore prior setting
		$_WD_DEBUG = $WDDebugSave
	EndIf

	Local $sMessage = 'DriverCurrent = ' & $sDriverCurrent & ' : DriverLatest = ' & $sDriverLatest
	Return SetError(__WD_Error($sFuncName, $iErr, $sMessage, $iExt), $iExt, $bResult)
EndFunc   ;==>_WD_UpdateDriver

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_UpdateExtractor
; Description ...: Extract webdriver executable from zip file
; Syntax ........: __WD_UpdateExtractor($sTempFile, $sInstallDir, $sDriverEXE[, $sSubDir = ""])
; Parameters ....: $sTempFile           - Full path to zip file.
;                  $sInstallDir         - Directory where extracted files are placed
;                  $sDriverEXE          - Name of webdriver executable
;                  $sSubDir             - [optional] Directory containing files to extract.
; Return values .: None
; Return values .: Success - None
;                  Failure - None and sets @error to one of the following values:
;                  - $_WD_ERROR_GeneralError
;                  - $_WD_ERROR_FileIssue
;                  - $_WD_ERROR_NotFound
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WD_UpdateExtractor($sTempFile, $sInstallDir, $sDriverEXE, $sSubDir = "")
	Local Const $sFuncName = "__WD_UpdateExtractor"
	Local $iErr = $_WD_ERROR_Success, $iExt = 0

	; Handle COM Errors
	Local $oErr = ObjEvent("AutoIt.Error", __WD_ErrHnd)
	#forceref $oErr

	Local $oShell = ObjCreate("Shell.Application")
	If @error Then
		$iErr = $_WD_ERROR_GeneralError
	ElseIf FileGetSize($sTempFile) = 0 Then
		$iErr = $_WD_ERROR_FileIssue
		$iExt = 11 ; $iExt from 11 to 19 are related to __WD_UpdateExtractor()
	ElseIf IsObj($oShell.NameSpace($sTempFile)) = 0 Then
		$iErr = $_WD_ERROR_FileIssue
		$iExt = 12
	ElseIf IsObj($oShell.NameSpace($sInstallDir)) = 0 Then
		$iErr = $_WD_ERROR_FileIssue
		$iExt = 13
	Else
		Local $oNameSpace_Temp = $oShell.NameSpace($sTempFile & $sSubDir)
		Local $FilesInZip = $oNameSpace_Temp.items
		If @error Then
			$iErr = $_WD_ERROR_GeneralError
			$iExt = 14
		Else
			Local $oNameSpace_Install = $oShell.NameSpace($sInstallDir)
			Local $bEXEWasFound = False
			For $FileItem In $FilesInZip     ; Check the files in the archive separately
				; https://docs.microsoft.com/en-us/windows/win32/shell/folderitem

				If $FileItem.IsFolder Then
					; try to Extract subdir content
					__WD_UpdateExtractor($sTempFile, $sInstallDir, $sDriverEXE, '\' & $FileItem.Name)
					If Not @error Then
						$bEXEWasFound = True
						ExitLoop
					EndIf
				Else
					If StringRight($FileItem.Name, 4) = ".exe" Or StringRight($FileItem.Path, 4) = ".exe" Then     ; extract only EXE files
						$bEXEWasFound = True
						; delete webdriver from disk before unpacking to avoid potential problems
						FileDelete($sInstallDir & $sDriverEXE)
						$oNameSpace_Install.CopyHere($FileItem, 20)     ; 20 = (4) Do not display a progress dialog box. + (16) Respond with "Yes to All" for any dialog box that is displayed.
						ExitLoop
					EndIf
				EndIf
			Next
			If @error Then
				$iErr = $_WD_ERROR_GeneralError
				$iExt = 15
			ElseIf Not $bEXEWasFound Then
				$iErr = $_WD_ERROR_NotFound
				$iExt = 19 ; $iExt from 11 to 19 are related to __WD_UpdateExtractor()
			Else
				$iErr = $_WD_ERROR_Success
			EndIf
		EndIf
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr, Default, $iExt), $iExt)
EndFunc   ;==>__WD_UpdateExtractor

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_GetBrowserVersion
; Description ...: Get version number of specified browser.
; Syntax ........: _WD_GetBrowserVersion($sBrowser)
; Parameters ....: $sBrowser - Browser name or full path to browser executable
; Return values .: Success - Version number ("#.#.#.#" format) and sets @extended to index of $_WD_SupportedBrowsers
;                  Failure - "0" and sets @error to one of the following values:
;                  - $_WD_ERROR_FileIssue
;                  - $_WD_ERROR_NotSupported
;                  - $_WD_ERROR_NotFound
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......:
; Related .......: _WD_GetBrowserPath, _WD_UpdateDriver
; Link ..........:
; Example .......: MsgBox(0, "", _WD_GetBrowserVersion('chrome'))
; ===============================================================================================================================
Func _WD_GetBrowserVersion($sBrowser)
	Local Const $sFuncName = "_WD_GetBrowserVersion"
	Local Const $sParameters = 'Parameters:    Browser=' & $sBrowser
	Local $iErr = $_WD_ERROR_Success, $iExt = 0
	Local $sBrowserVersion = "0"

	Local $sPath = _WD_GetBrowserPath($sBrowser)
	$iErr = @error
	$iExt = @extended
	If $iErr Then
		; as registry checks fails, now checking if file exist
		If FileExists($sBrowser) Then
			; Resetting as we are now checking file instead registry entries
			$iErr = $_WD_ERROR_Success
			$iExt = 0

			; Extract filename and confirm match in list of supported browsers
			Local $sBrowserName = StringRegExpReplace($sBrowser, "^.*\\|\..*$", "")
			Local $iIndex = _ArraySearch($_WD_SupportedBrowsers, $sBrowserName, Default, Default, Default, Default, Default, $_WD_BROWSER_Name)
			If @error Then
				$iErr = $_WD_ERROR_NotSupported
			Else
				$iExt = $iIndex
				$sPath = $sBrowser
			EndIf
		EndIf
	EndIf

	If $iErr = $_WD_ERROR_Success Then
		If _WinAPI_GetBinaryType($sPath) = 0 Then ; check if file is executable
			$iErr = $_WD_ERROR_FileIssue
			$iExt = 31 ; $iExt from 31 to 39 are related to _WD_GetBrowserVersion()
		Else
			$sBrowserVersion = FileGetVersion($sPath)
			If @error Then
				$iErr = $_WD_ERROR_FileIssue
				$iExt = 32
			EndIf
		EndIf
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters, $iExt), $iExt, $sBrowserVersion)
EndFunc   ;==>_WD_GetBrowserVersion

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_GetBrowserPath
; Description ...: Retrieve path to browser executable from registry
; Syntax ........: _WD_GetBrowserPath($sBrowser)
; Parameters ....: $sBrowser - Name of browser
; Return values .: Success - Full path to browser executable and sets @extended to index of $_WD_SupportedBrowsers
;                  Failure - "" and sets @error to one of the following values:
;                  - $_WD_ERROR_InvalidValue
;                  - $_WD_ERROR_NotSupported
;                  - $_WD_ERROR_NotFound
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......: Browser names are defined in $_WD_SupportedBrowsers
; Related .......: _WD_GetBrowserVersion, _WD_UpdateDriver
; Link ..........:
; Example .......: MsgBox(0, "", _WD_GetBrowserPath('firefox'))
; ===============================================================================================================================
Func _WD_GetBrowserPath($sBrowser)
	Local Const $sFuncName = "_WD_GetBrowserPath"
	Local Const $sParameters = 'Parameters:    Browser=' & $sBrowser
	Local Const $sRegKeyCommon = '\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\'
	Local $iErr = $_WD_ERROR_Success, $iExt = 0
	Local $sEXE, $sPath = ""

	; Confirm match in list of supported browsers
	Local $iIndex = _ArraySearch($_WD_SupportedBrowsers, $sBrowser, Default, Default, Default, Default, Default, $_WD_BROWSER_Name)
	If @error Then
		$iErr = $_WD_ERROR_NotSupported
		$iExt = 21 ; $iExt from 21 to 29 are related to _WD_GetBrowserPath()
	Else
		$sEXE = $_WD_SupportedBrowsers[$iIndex][$_WD_BROWSER_ExeName]

		; check HKLM or in case of error HKCU
		$sPath = RegRead("HKLM" & $sRegKeyCommon & $sEXE, "")
		If @error Then $sPath = RegRead("HKCU" & $sRegKeyCommon & $sEXE, "")

		; Generate $_WD_ERROR_NotFound if neither key is found
		If @error Then
			$iErr = $_WD_ERROR_NotFound
			$iExt = 22
		Else
			$sPath = StringRegExpReplace($sPath, '["'']', '') ; Remove quotation marks
			$sPath = StringRegExpReplace($sPath, '(.+\\)(.*exe)', '$1' & $sEXE) ; Registry entries can contain "Launcher.exe" instead "opera.exe"
			$iExt = $iIndex
		EndIf
	EndIf
	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters, $iExt), $iExt, $sPath)
EndFunc   ;==>_WD_GetBrowserPath

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_GetWebDriverVersion
; Description ...: Get version number of specifed webdriver.
; Syntax ........: _WD_GetWebDriverVersion($sInstallDir, $sDriverEXE)
; Parameters ....: $sInstallDir - Directory where $sDriverEXE is located
;                  $sDriverEXE  - File name of "WebDriver.exe"
; Return values .: Success - The value you get when you call WebDriver with the --version parameter
;                  Failure - "0" and sets @error to one of the following values:
;                  - $_WD_ERROR_NotFound
;                  - $_WD_ERROR_GeneralError
; Author ........: Danp2
; Modified ......: mLipok
; Remarks .......:
; Related .......: _WD_UpdateDriver
; Link ..........:
; Example .......: MsgBox(0, "", _WD_GetWebDriverVersion(@ScriptDir,'chromedriver.exe'))
; ===============================================================================================================================
Func _WD_GetWebDriverVersion($sInstallDir, $sDriverEXE)
	Local Const $sFuncName = "_WD_GetWebDriverVersion"
	Local Const $sParameters = 'Parameters:    Dir=' & $sInstallDir & '    EXE=' & $sDriverEXE
	Local $sDriverVersion = "0"
	Local $iErr = $_WD_ERROR_Success
	Local $iExt = 0

	$sInstallDir = StringRegExpReplace($sInstallDir, '(?i)(\\)\Z', '') & '\' ; prevent double \\ on the end of directory
	If Not FileExists($sInstallDir & $sDriverEXE) Then
		$iErr = $_WD_ERROR_NotFound
	Else
		Local $sCmd = $sInstallDir & $sDriverEXE & " --version"
		Local $iPID = Run($sCmd, $sInstallDir, @SW_HIDE, $STDOUT_CHILD)
		If @error Then
			$iErr = $_WD_ERROR_GeneralError
			$iExt = 1
		EndIf

		If $iPID Then
			ProcessWaitClose($iPID)
			Local $sOutput = StdoutRead($iPID)
			Local $aMatches = StringRegExp($sOutput, "\d+(?:\.\d+){2,}", 1)
			If @error Then
				$iErr = $_WD_ERROR_GeneralError
				$iExt = 2
			Else
				$sDriverVersion = $aMatches[0]
			EndIf
		EndIf
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters, $iExt), $iExt, $sDriverVersion)
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
	Local Const $sParameters = 'Parameters:    URL=' & $sURL & '    Dest=' & $sDest & '    Options=' & $iOptions
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
						$iExt = 1 ; $iExt from 1 to 9 are related to _WD_DownloadFile()
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

	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters, $iExt), $iExt, $bResult)
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
; Related .......: _WD_Timeouts, _WD_LastHTTPResult
; Link ..........: https://www.w3.org/TR/webdriver/#set-timeouts
; Example .......: _WD_SetTimeouts($sSession, 50000)
; ===============================================================================================================================
Func _WD_SetTimeouts($sSession, $iPageLoad = Default, $iScript = Default, $iImplicitWait = Default)
	Local Const $sFuncName = "_WD_SetTimeouts"
	Local Const $bIsNull = (IsKeyword($iScript) = $KEYWORD_NULL)
	Local Const $sParameters = 'Parameters:    PageLoad=' & $iPageLoad & '    Script=' & ($bIsNull ? "Null" : $iScript) & '    Implicit=' & $iImplicitWait
	Local $sTimeouts = '', $sResult = 0, $iErr
	$_WD_HTTPRESULT = 0
	$_WD_HTTPRESPONSE = ''

	; Build string to pass to _WD_Timeouts
	If $iPageLoad <> Default Then
		If Not IsInt($iPageLoad) Then
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(int) $vValue: " & $iPageLoad), 0, 0)
		EndIf

		$sTimeouts &= '"pageLoad":' & $iPageLoad
	EndIf

	If $iScript <> Default Then
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

	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters), 0, $sResult)
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
; Related .......: _WD_FindElement, _WD_LastHTTPResult
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_GetElementById($sSession, $sID)
	Local Const $sFuncName = "_WD_GetElementById"
	Local Const $sParameters = 'Parameters:    ID=' & $sID

	Local $sXpath = '//*[@id="' & $sID & '"]'
	Local $sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, $sXpath)
	Local $iErr = @error

	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters), 0, $sElement)
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
; Related .......: _WD_FindElement, _WD_LastHTTPResult
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_GetElementByName($sSession, $sName)
	Local Const $sFuncName = "_WD_GetElementByName"
	Local Const $sParameters = 'Parameters:    Name=' & $sName

	Local $sXpath = '//*[@name="' & $sName & '"]'
	Local $sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, $sXpath)
	Local $iErr = @error

	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters), 0, $sElement)
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
; Modified ......: mLipok, TheDcoder
; Remarks .......: When using Advanced mode, translations or string encoding should occur prior to
;                  calling this function because the supplied value is used without modification.
; Related .......: _WD_ElementAction, _WD_LastHTTPResult
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_SetElementValue($sSession, $sElement, $sValue, $iStyle = Default)
	Local Const $sFuncName = "_WD_SetElementValue"
	Local Const $bParameters_Value = (($_WD_DEBUG = $_WD_DEBUG_Full) ? ($sValue) : ("<masked>"))
	Local Const $sParameters = 'Parameters:    Element=' & $sElement & '    Value=' & $bParameters_Value & '    Style=' & $iStyle
	Local $sResult, $iErr, $sScript

	If $iStyle = Default Then $iStyle = $_WD_OPTION_Standard
	If $iStyle < $_WD_OPTION_Standard Or $iStyle > $_WD_OPTION_Advanced Then $iStyle = $_WD_OPTION_Standard

	Switch $iStyle
		Case $_WD_OPTION_Standard
			$sResult = _WD_ElementAction($sSession, $sElement, 'value', $sValue)
			$iErr = @error

		Case $_WD_OPTION_Advanced
			$sScript = _
					"Object.getOwnPropertyDescriptor(arguments[0].__proto__, 'value').set.call(arguments[0], arguments[1]);" & _
					"arguments[0].dispatchEvent(new Event('input', {bubbles: true}));" & _
					"arguments[0].dispatchEvent(new Event('change', {bubbles: true}));" & _
					""
			$sResult = _WD_ExecuteScript($sSession, $sScript, __WD_JsonElement($sElement) & ',"' & $sValue & '"')
			$iErr = @error

	EndSwitch

	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters), 0, $sResult)
EndFunc   ;==>_WD_SetElementValue

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_ElementActionEx
; Description ...: Perform advanced action on designated element.
; Syntax ........: _WD_ElementActionEx($sSession, $sElement, $sCommand[, $iXOffset = Default[, $iYOffset = Default[, $iButton = Default[, $iHoldDelay = Default[, $sModifier = Default[, $bScrollView = Default]]]]]])
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
;                  |REMOVE - Removes the element from the DOM
;                  $iXOffset    - [optional] X Offset. Default is 0
;                  $iYOffset    - [optional] Y Offset. Default is 0
;                  $iButton     - [optional] Mouse button. Default is $_WD_BUTTON_Left
;                  $iHoldDelay  - [optional] Hold time in ms. Default is 1000
;                  $sModifier   - [optional] Modifier key. Default is "\uE008" (shift key)
;                  $bScrollView - [optional] Forcibly scroll element into view? Default is True
; Return values .: Success - Return value from web driver (could be an empty string)
;                  Failure - "" (empty string) and sets @error to one of the following values:
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_InvalidDataType
; Author ........: Danp2
; Modified ......: TheDcoder, mLipok
; Remarks .......: Moving the mouse pointer above the target element is the first thing to occur for every $sCommand before it gets executed.
;                  There are examples in DemoElements() function in wd_demo.au3
; Related .......: _WD_ElementAction, _WD_Action, _WD_LastHTTPResult
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_ElementActionEx($sSession, $sElement, $sCommand, $iXOffset = Default, $iYOffset = Default, $iButton = Default, $iHoldDelay = Default, $sModifier = Default, $bScrollView = Default)
	Local Const $sFuncName = "_WD_ElementActionEx"
	Local Const $sParameters = 'Parameters:    Element=' & $sElement & '    Command=' & $sCommand & '    XOffset=' & $iXOffset & '    YOffset=' & $iYOffset & '    Button=' & $iButton & '    HoldDelay=' & $iHoldDelay & '    Modifier=' & $sModifier & '    ScrollView=' & $bScrollView
	Local $sAction, $sJavaScript, $iErr, $sResult, $iActionType = 1
	$_WD_HTTPRESULT = 0
	$_WD_HTTPRESPONSE = ''

	If $iXOffset = Default Then $iXOffset = 0
	If $iYOffset = Default Then $iYOffset = 0
	If $iButton = Default Then $iButton = $_WD_BUTTON_Left
	If $iHoldDelay = Default Then $iHoldDelay = 1000
	If $sModifier = Default Then $sModifier = "\uE008" ; shift
	If $bScrollView = Default Then $bScrollView = True

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
			; No additional actions required for hover functionality

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
			$sJavaScript = "arguments[0].style='display: none'; return true;"

		Case 'show'
			$iActionType = 2
			$sJavaScript = "arguments[0].style='display: normal'; return true;"

		Case 'childcount'
			$iActionType = 2
			$sJavaScript = "return arguments[0].children.length;"

		Case 'check', 'uncheck'
			$iActionType = 2
			$sJavaScript = "Object.getOwnPropertyDescriptor(arguments[0].__proto__, 'checked').set.call(arguments[0], " & ($sCommand = "check" ? 'true' : 'false') & ");arguments[0].dispatchEvent(new Event('change', { bubbles: true }));"

		Case 'remove'
			$iActionType = 2
			$sJavaScript = "arguments[0].remove();"

		Case Else
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(Hover|RightClick|DoubleClick|Click|ClickAndHold|Hide|Show|ChildCount|ModifierClick|Check|Uncheck|Remove) $sCommand=>" & $sCommand), 0, "")

	EndSwitch

	#Region - JSON builder
	; $sActionTemplate declaration is outside the switch to not pollute simplicity of the >Switch ... EndSwitch< - for better code maintenance
	; StringFormat() usage is significantly faster than building JSON string each time from scratch
	; StringReplace() removes all possible @TAB's because they are used only for indentation and are not needed in JSON string
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

	If $bScrollView Then
		_WD_ExecuteScript($sSession, "arguments[0].scrollIntoView(false);", __WD_JsonElement($sElement))
		Sleep(500) ; short Sleep() outside of the loop so no need to use __WD_Sleep()
	EndIf

	Switch $iActionType
		Case 1
			$sAction = StringFormat($sActionTemplate, $sPreAction, $iXOffset, $iYOffset, $sElement, $sElement, $sPostHoverAction, $sPostAction)
			$sResult = _WD_Action($sSession, 'actions', $sAction)
			$iErr = @error

		Case 2
			$sResult = _WD_ExecuteScript($sSession, $sJavaScript, __WD_JsonElement($sElement), Default, $_WD_JSON_Value)
			$iErr = @error
	EndSwitch

	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters), 0, $sResult)
EndFunc   ;==>_WD_ElementActionEx

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_DispatchEvent
; Description ...: Create and dispatch events
; Syntax ........: _WD_DispatchEvent($sSession,  $sElement,  $sEvent[,  $sOptions = Default])
; Parameters ....: $sSession - Session ID from _WD_CreateSession.
;                  $sElement - Element ID from _WD_FindElement.
;                  $sEvent   - The event type.
;                  $sOptions  - [optional] Event options in JSON format. Default is "{bubbles: true}".
; Return values .: None
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......: _WD_ExecuteScript
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_DispatchEvent($sSession, $sElement, $sEvent, $sOptions = Default)
	Local Const $sFuncName = "_WD_DispatchEvent"
	Local $sScript, $sJsonElement, $sParameters

	If $sOptions = Default Or Not IsString($sOptions) Then $sOptions = "{bubbles: true}"

	$sScript = "arguments[0].dispatchEvent(new Event(arguments[1], arguments[2]));"
	$sJsonElement = __WD_JsonElement($sElement)
	$sParameters = '"' & $sJsonElement & '","' & $sEvent & '","' & $sOptions & '"'
	_WD_ExecuteScript($sSession, $sScript, $sParameters)

	Return SetError(__WD_Error($sFuncName, @error))
EndFunc   ;==>_WD_DispatchEvent

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_GetTable
; Description ...: Retrieve text from all matching elements of a table.
; Syntax ........: _WD_GetTable($sSession, $sStrategy, $sSelector[, $sRowsSelector = Default[, $sColsSelector = Default]])
; Parameters ....: $sSession      - Session ID from _WD_CreateSession
;                  $sStrategy     - Locator strategy. See defined constant $_WD_LOCATOR_* for allowed values
;                  $sSelector     - Indicates how the WebDriver should traverse through the HTML DOM to locate the desired <table> element.
;                  $sRowsSelector - [optional] Rows CSS selector. Default is "tr".
;                  $sColsSelector - [optional] Columns CSS selector. Default is "td, th".
; Return values .: Success - 2D array.
;                  Failure - "" (empty string) and sets @error to one of the following values:
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_NoMatch
; Author ........: danylarson
; Modified ......: water, danp2, mLipok
; Remarks .......: The CSS selectors can be overridden to control the included elements. For example, a modified $sRowsSelector of ":scope > tbody > tr" can be used to bypass nested tables.
; Related .......: _WD_FindElement, _WD_ElementAction, _WD_LastHTTPResult
; Link ..........: https://www.autoitscript.com/forum/topic/191990-webdriver-udf-w3c-compliant-version-01182020/page/18/?tab=comments#comment-1415164
; Example .......: No
; ===============================================================================================================================
Func _WD_GetTable($sSession, $sStrategy, $sSelector, $sRowsSelector = Default, $sColsSelector = Default)
	Local Const $sFuncName = "_WD_GetTable"
	Local Const $sParameters = 'Parameters:   Strategy=' & $sStrategy & '   Selector=' & $sSelector & '   RowsSelector=' & $sRowsSelector & '   ColsSelector=' & $sColsSelector
	Local $sElement, $aTable = ''
	$_WD_HTTPRESULT = 0
	$_WD_HTTPRESPONSE = ''

	If $sRowsSelector = Default Then $sRowsSelector = "tr"
	If $sColsSelector = Default Then $sColsSelector = "td, th"

	; Get the table element
	$sElement = _WD_FindElement($sSession, $sStrategy, $sSelector)
	Local $iErr = @error

	If $iErr = $_WD_ERROR_Success Then
		; https://stackoverflow.com/questions/64842157
		Local $sScript = "return [...arguments[0].querySelectorAll(arguments[1])]" & _
				".map(row => [...row.querySelectorAll(arguments[2])]" & _
				".map(cell => cell.textContent));"
		Local $sArgs = __WD_JsonElement($sElement) & ', "' & $sRowsSelector & '", "' & $sColsSelector & '"'
		Local $sResult = _WD_ExecuteScript($sSession, $sScript, $sArgs)
		$iErr = @error

		If $iErr = $_WD_ERROR_Success Then
			; Extract target data from results and convert to array
			Local $sStr = StringMid($sResult, 10, StringLen($sResult) - 10)
			$aTable = __WD_Make2Array($sStr)
		EndIf
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters), 0, $aTable)
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
; Related .......: _WD_LastHTTPResult
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
; Related .......: _WD_LastHTTPResult
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
; Related .......: _WD_Action, _WD_Window, _WD_LastHTTPResult
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

	Switch $iErr
		Case $_WD_ERROR_Success
			$iResult = $_WD_STATUS_Valid

		Case $_WD_ERROR_Exception, $_WD_ERROR_ContextInvalid
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
	EndSwitch

	Return SetError(__WD_Error($sFuncName, ($iResult) ? $_WD_ERROR_Success : $_WD_ERROR_Exception), 0, $iResult)
EndFunc   ;==>_WD_CheckContext

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_GetContext
; Description ...: Retrieve the element ID of the current browsing context
; Syntax ........: _WD_GetContext($sSession)
; Parameters ....: $sSession - Session ID from _WD_CreateSession
; Return values .: Success - Element ID of current frame / document
;                  Failure - "" and sets @error to value returned from _WD_ExecuteScript()
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_GetContext($sSession)
	Local Const $sFuncName = "_WD_GetContext"
	Local $sElement = _WD_ExecuteScript($sSession, "return window.document.body;", Default, Default, $_WD_JSON_Element)
	Local $iErr = @error

	If $iErr Then $sElement = ""
	Return SetError(__WD_Error($sFuncName, $iErr), 0, $sElement)
EndFunc   ;==>_WD_GetContext

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_GetElementByRegEx
; Description ...: Find element by matching attributes values using Javascript regular expression
; Syntax ........: _WD_GetElementByRegEx($sSession, $sMode, $sRegExPattern[, $sRegExFlags = ""[, $bAll = False]])
; Parameters ....: $sSession            - Session ID from _WD_CreateSession
;                  $sMode               - Attribute of the element which should be matched, e.g. `id`, `style`, `class` etc.
;                  $sRegExPattern       - JavaScript compatible regular expression
;                  $sRegExFlags         - [optional] RegEx Flags. Default is "".
;                  $bAll                - [optional] Return multiple matching elements? Default is False
; Return values .: Success - Matching Element ID(s)
;                  Failure - @error set to $_WD_ERROR_NoMatch if there are no matches OR
;                            Response from _WD_ExecuteScript() and sets @error to value returned from _WD_ExecuteScript()
; Author ........: TheDcoder
; Modified ......: mLipok, Danp2
; Remarks .......: The RegEx matching is done by the browser's JavaScript engine so AutoIt's RegEx rules may not accurately work
;                  in this function. You may refer to the following resources for further information:
;                  https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions/Cheatsheet
;                  https://regex101.com with FLAVOR set to: ECMAScript (JavaScript) to validate your RegEx
; Related .......:
; Link ..........:
; Example .......: _WD_GetElementByRegEx($sSession, 'class', 'button-[0-9]', 'i', True)
; ===============================================================================================================================
Func _WD_GetElementByRegEx($sSession, $sMode, $sRegExPattern, $sRegExFlags = "", $bAll = False)
	Local Const $sFuncName = "_WD_GetElementByRegEx"
	Local $iRow = 0, $iErr = 0, $vResult = ''
	Local Static $sJS_Static = _
			"return _JS_GetElementByRegEx('%s', '%s', '%s', %s) || '';" & _
			"" & _
			"function _JS_GetElementByRegEx(mode, pattern, flags = '', all = false) {" & _
			"   var regex = new RegExp(pattern, flags);" & _
			"   var elements;" & _
			"   elements = document.querySelectorAll(`[${mode}]`);" & _
			"   return Array.prototype[all ? 'filter' : 'find'].call(elements, x => regex.test(x.getAttribute(mode)));" & _
			"}" & _
			""

	Local $sJavaScript = StringFormat($sJS_Static, $sMode, $sRegExPattern, $sRegExFlags, StringLower($bAll))
	Local $oValues = _WD_ExecuteScript($sSession, $sJavaScript, Default, False, $_WD_JSON_Value)
	$iErr = @error
	If Not @error Then
		Local $sKey = "[" & $_WD_ELEMENT_ID & "]"

		If $bAll Then
			Local $aElements[UBound($oValues)]
			If UBound($aElements) < 1 Then
				$iErr = $_WD_ERROR_NoMatch
			Else
				For $oValue In $oValues
					$aElements[$iRow] = Json_Get($oValue, $sKey)
					$iRow += 1
				Next

				$vResult = $aElements
			EndIf
		Else
			$vResult = Json_Get($oValues, $sKey)
			If @error Then
				$iErr = $_WD_ERROR_NoMatch
			Else
				$iRow = 1
			EndIf
		EndIf
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr), $iRow, $vResult)
EndFunc   ;==>_WD_GetElementByRegEx

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_Storage
; Description ...: Provide access to the browser's localStorage and sessionStorage objects
; Syntax ........: _WD_Storage($sSession,  $sKey[,  $vValue = Default[,  $nType = Default]])
; Parameters ....: $sSession            - Session ID from _WD_CreateSession
;                  $vKey                - Key to manipulate.
;                  $vValue              - [optional] Value to store.
;                  $nType               - [optional] Storage type. Default is $_WD_STORAGE_Local
; Return values .: Success - Response from _WD_ExecuteScript() and sets @error to $_WD_ERROR_Success
;                  Failure - @error set to $_WD_ERROR_InvalidArgue if there are no matches OR
;                            Response from _WD_ExecuteScript() and sets @error to value returned from _WD_ExecuteScript()
; Author ........: Danp2
; Modified ......:
; Remarks .......:	Data is stored and retrieved without modification. Translations or string
;					encoding / decoding should occur outside of this function.
;
;					See below for special conditions --
;
;					| Parameter | Condition | Action                     |
;					|-----------|-----------|----------------------------|
;					| $vKey     | Numeric   | Return name of the Nth key |
;					| $vKey     | Null      | Clear storage              |
;					| $vValue   | Null      | Remove key from storage    |
;
; Related .......:
; Link ..........: https://developer.mozilla.org/en-US/docs/Web/API/Storage
; Example .......: No
; ===============================================================================================================================
Func _WD_Storage($sSession, $vKey, $vValue = Default, $nType = Default)
	Local Const $sFuncName = "_WD_Storage"
	Local $sParams, $vResult = '', $iErr = $_WD_ERROR_Success
	Local Const $bIsKeyNull = (IsKeyword($vKey) = $KEYWORD_NULL), $bIsValueNull = (IsKeyword($vValue) = $KEYWORD_NULL)
	Local Const $sParameters = 'Parameters:   Key=' & ($bIsKeyNull ? "Null" : $vKey) & '   Value=' & ($bIsValueNull ? "Null" : $vValue) & '   Type=' & $nType

	If $nType = Default Or $nType < $_WD_STORAGE_Local Or $nType > $_WD_STORAGE_Session Then $nType = $_WD_STORAGE_Local

	Local $sTarget = ($nType = $_WD_STORAGE_Local) ? "window.localStorage" : "window.sessionStorage"
	Local $sJavaScript = 'return ' & $sTarget

	Select
		Case $bIsKeyNull ; Empty storage
			If $vValue = Default Then
				$sJavaScript &= '.clear()'
				$sParams = $_WD_EmptyDict
			Else
				$iErr = $_WD_ERROR_InvalidArgue
			EndIf

		Case $vValue = Default ; Retrieve key
			If IsNumber($vKey) Then
				$sJavaScript &= '.key(arguments[0])'
				$sParams = String($vKey)
			Else
				$sJavaScript &= '.getItem(arguments[0])'
				$sParams = '"' & $vKey & '"'
			EndIf

		Case $bIsValueNull ; Remove key
			$sJavaScript &= '.removeItem(arguments[0])'
			$sParams = '"' & $vKey & '"'

		Case $vKey And $vValue ; Set key
			$sJavaScript &= '.setItem(arguments[0], arguments[1])'
			$sParams = '"' & $vKey & '","' & $vValue & '"'
	EndSelect

	If $iErr = $_WD_ERROR_Success Then
		$vResult = _WD_ExecuteScript($sSession, $sJavaScript, $sParams, Default, $_WD_JSON_Value)
		$iErr = @error
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters), 0, $vResult)
EndFunc   ;==>_WD_Storage

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
	Return SetError(__WD_Error($sFuncName, 0, $sJSON), 0, $sJSON)
EndFunc   ;==>_WD_JsonActionKey


; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_GetFreePort
; Description ...:  Locate and return an available TCP port within a defined range
; Syntax ........: _WD_GetFreePort([$iMinPort = Default[,  $iMaxPort = Default]])
; Parameters ....: $iMinPort - [optional] Starting port number. Default is 64000
;                  $iMaxPort - [optional] Ending port number. Default is $iMinPort or 65000
; Return values .: Success - Available TCP port number
;                  Failure - Value from $iMinPort and sets @error to one of the following values:
;                  - $_WD_ERROR_NotFound
;                  - $_WD_ERROR_GeneralError
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_GetFreePort($iMinPort = Default, $iMaxPort = Default)
	Local Const $sFuncName = "_WD_GetFreePort"
	Local Const $sParameters = 'Parameters:   MinPort=' & $iMinPort & '   MaxPort=' & $iMaxPort
	Local $sMessage = ' > No available ports found'

	If $iMaxPort = Default Then $iMaxPort = ($iMinPort = Default) ? 65000 : $iMinPort
	If $iMinPort = Default Then $iMinPort = 64000
	Local $iResult = $iMinPort, $iErr = $_WD_ERROR_NotFound
	Local $aPorts = __WinAPI_GetTcpTable()

	If @error Then
		$iErr = $_WD_ERROR_GeneralError
		$sMessage = ' > Error occurred in __WinAPI_GetTcpTable'
	Else
		For $iPort = $iMinPort To $iMaxPort
			_ArraySearch($aPorts, $iPort, Default, Default, Default, Default, Default, 3)
			If @error = 6 Then
				$iResult = $iPort
				$iErr = $_WD_ERROR_Success
				$sMessage = ''
				ExitLoop
			EndIf
		Next
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters & $sMessage, $iResult), 0, $iResult)
EndFunc   ;==>_WD_GetFreePort

Func __WinAPI_GetTcpTable()
	;funkey 2012.12.14
	;https://www.autoitscript.com/forum/topic/146671-getextendedtcptable-get-netstat-information/?tab=comments#comment-1038649
	Local Const $aConnState[12] = ["CLOSED", "LISTENING", "SYN_SENT", "SYN_RCVD", "ESTABLISHED", "FIN_WAIT1", _
			"FIN_WAIT2", "CLOSE_WAIT", "CLOSING", "LAST_ACK", "TIME_WAIT", "DELETE_TCB"]

	Local $tMIB_TCPTABLE = DllStructCreate("dword[6]")
	Local $aRet = DllCall("Iphlpapi.dll", "DWORD", "GetTcpTable", "struct*", $tMIB_TCPTABLE, "DWORD*", 0, "BOOL", True)
	Local $dwSize = $aRet[2]
	$tMIB_TCPTABLE = DllStructCreate("DWORD[" & $dwSize / 4 & "]")

	$aRet = DllCall("Iphlpapi.dll", "DWORD", "GetTcpTable", "struct*", $tMIB_TCPTABLE, "DWORD*", $dwSize, "BOOL", True)
	If $aRet[0] <> 0 Then Return SetError(1)
	Local $iNumEntries = DllStructGetData($tMIB_TCPTABLE, 1, 1)
	Local $aRes[$iNumEntries][6]

	For $i = 0 To $iNumEntries - 1
		$aRes[$i][0] = DllStructGetData($tMIB_TCPTABLE, 1, 2 + $i * 5 + 0)
		$aRes[$i][1] = $aConnState[$aRes[$i][0] - 1]
		$aRet = DllCall("ws2_32.dll", "str", "inet_ntoa", "uint", DllStructGetData($tMIB_TCPTABLE, 1, 2 + $i * 5 + 1)) ; local IP / translate
		$aRes[$i][2] = $aRet[0]
		$aRet = DllCall("ws2_32.dll", "ushort", "ntohs", "uint", DllStructGetData($tMIB_TCPTABLE, 1, 2 + $i * 5 + 2)) ; local port / translate
		$aRes[$i][3] = $aRet[0]
		$aRet = DllCall("ws2_32.dll", "str", "inet_ntoa", "uint", DllStructGetData($tMIB_TCPTABLE, 1, 2 + $i * 5 + 3)) ; remote IP / translate
		$aRes[$i][4] = $aRet[0]
		If $aRes[$i][0] <= 2 Then
			$aRes[$i][5] = 0
		Else
			$aRet = DllCall("ws2_32.dll", "ushort", "ntohs", "uint", DllStructGetData($tMIB_TCPTABLE, 1, 2 + $i * 5 + 4)) ; remote port / translate
			$aRes[$i][5] = $aRet[0]
		EndIf
	Next

	Return $aRes
EndFunc   ;==>__WinAPI_GetTcpTable

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
	Return SetError(__WD_Error($sFuncName, 0, $sJSON), 0, $sJSON)
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
	Return SetError(__WD_Error($sFuncName, 0, $sJSON), 0, $sJSON)
EndFunc   ;==>_WD_JsonActionPause

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_JsonCookie
; Description ...: Formats "cookie" strings for use in _WD_Cookies
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
	Return SetError(__WD_Error($sFuncName, 0, $sJSON), 0, $sJSON)
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

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_ErrHnd
; Description ...: Dummy error handler
; Syntax ........: __WD_ErrHnd()
; Parameters ....: None
; Return values .: None
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
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

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_GetLatestWebdriverInfo
; Description ...: Generates URL for downloading latest matching webdriver version
; Syntax ........: __WD_GetLatestWebdriverInfo($aBrowser, $sBrowserVersion, $bFlag64)
; Parameters ....: $aBrowser        - Row extracted from $_WD_SupportedBrowsers.
;                  $sBrowserVersion - Current browser version.
;                  $bFlag64         - Install 64bit version?
; Return values .: Success - Array containing [0] URL for downloading requested webdriver & [1] matching webdriver version
;                  Failure - Empty array and sets @error to $_WD_ERROR_GeneralError
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WD_GetLatestWebdriverInfo($aBrowser, $sBrowserVersion, $bFlag64)
	Local Const $sFuncName = "__WD_GetLatestWebdriverInfo"
	Local $iStartPos, $iConversion, $iErr = $_WD_ERROR_Success, $iExt = 0
	Local $aInfo[2] = ["", ""]
	Local $sURL = $aBrowser[0][$_WD_BROWSER_LatestReleaseURL]
	Local $sRegex = $aBrowser[0][$_WD_BROWSER_LatestReleaseRegex]
	Local $sNewURL = $aBrowser[0][$_WD_BROWSER_NewDriverURL]
	#forceref $sBrowserVersion, $bFlag64

	If StringRegExp($sURL, '["'']') Then
		$sURL = Execute($sURL)
	EndIf

	Local $sDriverLatest = InetRead($sURL)

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

		If StringLen($sRegex) Then
			; Incorporate major version number into regex
			$sRegex = StringFormat($sRegex, StringLeft($sBrowserVersion, StringInStr($sBrowserVersion, '.') - 1))
			Local $aResults = StringRegExp($sDriverLatest, $sRegex, $STR_REGEXPARRAYMATCH)

			If @error Then
				$iErr = $_WD_ERROR_GeneralError
				$iExt = 1
			Else
				$sDriverLatest = $aResults[0]
			EndIf
		EndIf

		If Not $iErr Then
			$aInfo[0] = Execute($sNewURL)
			$aInfo[1] = $sDriverLatest
		EndIf
	Else
		$iErr = $_WD_ERROR_GeneralError
		$iExt = 2
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr, Default, $iExt), $iExt, $aInfo)
EndFunc   ;==>__WD_GetLatestWebdriverInfo

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_Make2Array
; Description ...: Parse string to array
; Syntax ........: __WD_Make2Array($s)
; Parameters ....: $s - String to be parsed
; Return values .: Generated array
; Author ........: jguinch
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........: https://www.autoitscript.com/forum/topic/179113-is-there-a-easy-way-to-parse-string-to-array
; Example .......: No
; ===============================================================================================================================
Func __WD_Make2Array($s)
	Local $aLines = StringRegExp($s, "(?<=[\[,])\s*\[(.*?)\]\s*[,\]]", 3), $iCountCols = 0
	For $i = 0 To UBound($aLines) - 1
		$aLines[$i] = StringRegExp($aLines[$i], "(?:^|,)\s*(?|'([^']*)'|""([^""]*)""|(.*?))(?=\s*(?:,|$))", 3)
		If UBound($aLines[$i]) > $iCountCols Then $iCountCols = UBound($aLines[$i])
	Next
	Local $aRet[UBound($aLines)][$iCountCols]
	For $y = 0 To UBound($aLines) - 1
		For $x = 0 To UBound($aLines[$y]) - 1
			$aRet[$y][$x] = ($aLines[$y])[$x]
		Next
	Next
	Return $aRet
EndFunc   ;==>__WD_Make2Array
