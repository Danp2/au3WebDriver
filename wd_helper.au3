#Include-once
#include "wd_core.au3"

#Region Copyright
#cs
	* WD_Helper.au3
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

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_LinkClickByText
; Description ...: Simulate a mouse click on a link with text matching the provided string
; Syntax ........: _WD_LinkClickByText($sSession, $sText[, $lPartial = True])
; Parameters ....: $sSession            - Session ID from _WDCreateSession
;                  $sText               - a string value.
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

	Local $sElement = _WDFindElement($sSession, ($lPartial) ? $_WD_LOCATOR_ByPartialLinkText : $_WD_LOCATOR_ByLinkText, $sText)

	Local $iErr = @error

	If $iErr = $_WD_ERROR_Success Then
		_WDElementAction($sSession, $sElement, 'click')
	Else
		SetError(__WD_Error($sFuncName, $_WD_ERROR_NoMatch), $_WD_HTTPRESULT)
	EndIf
EndFunc
