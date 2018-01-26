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
#ce
#EndRegion Many thanks to:


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
;                               | HTML
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

	For $sHandle In $aHandles

		_WDWindow($sSession, 'Switch', '{"handle":"' & $sHandle & '"}')

		Switch $sMode
			Case "title", "url"
				If StringInStr(_WDAction($sSession, $sMode), $sString) > 0 Then
					$lFound = True
					$sTabHandle = $sHandle
					ExitLoop
				EndIf

			Case 'html'
				If StringInStr(_WDGetSource($sSession), $sString) > 0 Then
					$lFound = True
					$sTabHandle = $sHandle
					ExitLoop
				EndIf

			Case Else
				SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(Title|URL|HTML) $sOption=>" & $sMode))
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
