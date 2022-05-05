; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_getDownloadProgress
; Description ...: Give the progression of the Download in firefox.
; Syntax ........: _WD_getDownloadProgress($sSession)
; Parameters ....: $sSession - Session ID from _WD_CreateSession
; Return values .: Success - $actualValue value in percentage
;                  Failure - Boolean False
; Author ........: AByGCreation
; Modified ......:
; Remarks .......:
; Related .......: elementWaiter
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_getDownloadProgress($sSession)

	Local Const $sFuncName = "_WD_getDownloadProgress"

	If not(_WD_Action($sSession, 'url') == "about:downloads" ) Then
		_WD_NewTab($sSession)
		_WD_Navigate($sSession, "about:downloads" )
	EndIf

	If elementWaiter($sSession,  '//*[@class="downloadProgress"]',  100) Then
			$sElement =  _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, '//*[@class="downloadProgress"]')
			$actualValue =  _WD_ElementAction($sSession, $sElement, "value")

			return $actualValue
	Else
			return false
	EndIf
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: elementWaiter
; Description ...: Give the progression of the Download in firefox.
; Syntax ........: elementWaiter($sSession, $xPath, $maxTry)
; Parameters ....: $sSession - Session ID from _WD_CreateSession
;~ 					$xPath 	- xPath syntax
;~ 					$maxTry - Number of retrying, equivalent to timeout
; Return values .: Success - Boolean true
;                  Failure - Boolean False
; Author ........: AByGCreation
; Modified ......:
; Remarks .......:
; Related .......: _WD_WaitElement
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func elementWaiter($sSession, $xPath, $maxTry = 20)
	Local Const $sFuncName = "elementWaiter"
	local $i = 0

	While _WD_WaitElement($sSession, $_WD_LOCATOR_ByXPath, $xPath, 500) = ""
		if($i < $maxTry) Then
			$i = $i + 1
		Else
			return false
		EndIf
	wend
	return true

EndFunc   ;==>elementWaiter
