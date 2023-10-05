#include-once
#include "wd_core.au3"
#include "WinHttp_WebSocket.au3" ; https://github.com/Danp2/autoit-websocket
#include <APIErrorsConstants.au3>

#Tidy_Parameters=/tcb=-1

#Region Copyright
#cs
	* WD_CDP.au3
	*
	* MIT License
	*
	* Copyright (c) 2023 Dan Pollak
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

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_CDPExecuteCommand
; Description ...: Execute CDP command.
; Syntax ........: _WD_CDPExecuteCommand($sSession, $sCommand, $oParams[, $sWebSocketURL = Default])
; Parameters ....: $sSession      - Session ID from _WD_CreateSession
;                  $sCommand      - Name of the command
;                  $oParams       - Parameters of the command as an object
;                  $sWebSocketURL - [optional] Websocket URL
; Return values .: Success - Raw return value from web driver in JSON format.
;                  Failure - "" (empty string) and sets @error to $_WD_ERROR_Exception
; Author ........: Damon Harris (TheDcoder)
; Modified ......: Danp2
; Remarks .......: The original version of this function is specific to ChromeDriver, you can execute "Chrome DevTools Protocol"
;                  commands by using this function, for all available commands see: https://chromedevtools.github.io/devtools-protocol/tot/
;
;                  The revised version uses websockets to provide CDP access for all compatible browsers. However, it
;                  will only work with an OS that natively supports WebSockets (Windows 8, Windows Server 2012, or newer)
; Related .......: _WD_LastHTTPResult
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_CDPExecuteCommand($sSession, $sCommand, $oParams, $sWebSocketURL = Default)
	Local Const $sFuncName = "_WD_ExecuteCDPCommand"
	Local $iErr = 0, $vData = Json_ObjCreate()
	$_WD_HTTPRESULT = 0

	If $sWebSocketURL = Default Then $sWebSocketURL = ''

	; Original version (Chrome only)
	If Not $sWebSocketURL Then
		Json_ObjPut($vData, 'cmd', $sCommand)
		Json_ObjPut($vData, 'params', $oParams)
		$vData = Json_Encode($vData)

		Local $sResponse = __WD_Post($_WD_BASE_URL & ":" & $_WD_PORT & "/session/" & $sSession & '/goog/cdp/execute', $vData)
		$iErr = @error

		__WD_ConsoleWrite($sFuncName & ': ' & $sResponse, $_WD_DEBUG_Info)

		Return SetError(__WD_Error($sFuncName, $iErr), 0, $sResponse)
	EndIf

	; Websocket version
	Local $hOpen = 0, $hConnect = 0, $hRequest = 0, $hWebSocket = 0
	Local $aURL, $fStatus, $sErrText, $sMessage = ""
	Local $iBufferLen = 1024, $tBuffer = 0, $bRecv = Binary(""), $sRecv
	Local $iBytesRead = 0, $iBufferType = 0
	Local $iStatus = 0, $iReasonLengthConsumed = 0
	Local $tCloseReasonBuffer = DllStructCreate("byte[123]")
	Local $sWSSRegex = '^((ws[s]?):\/\/)([^:\/\s]+)(?::([0-9]+))?(.*)$'
	Local Static $iID = 0

	$aURL = StringRegExp($sWebSocketURL, $sWSSRegex, 3)

	If Not IsArray($aURL) Or UBound($aURL) < 5 Then
		$iErr = $_WD_ERROR_InvalidValue
		$sErrText = "URL invalid"
	Else
		; Initialize and get session handle
		$hOpen = _WinHttpOpen()

		If $_WD_WINHTTP_TIMEOUTS Then
			_WinHttpSetTimeouts($hOpen, $_WD_HTTPTimeOuts[0], $_WD_HTTPTimeOuts[1], $_WD_HTTPTimeOuts[2], $_WD_HTTPTimeOuts[3])
		EndIf

		; Get connection handle
		$hConnect = _WinHttpConnect($hOpen, $aURL[2], $aURL[3])

		$hRequest = _WinHttpOpenRequest($hConnect, "GET", $aURL[4], "")

		; Request protocol upgrade from http to websocket.
		$fStatus = _WinHttpSetOptionNoParams($hRequest, $WINHTTP_OPTION_UPGRADE_TO_WEB_SOCKET)

		If Not $fStatus Then
			$iErr = $_WD_ERROR_SocketError
			$sErrText = "SetOption error"
		Else
			; Perform websocket handshake by sending a request and receiving server's response.
			; Application may specify additional headers if needed.
			$fStatus = _WinHttpSendRequest($hRequest)

			If Not $fStatus Then
				$iErr = $_WD_ERROR_SocketError
				$sErrText = "SendRequest error"
			Else
				$fStatus = _WinHttpReceiveResponse($hRequest)

				If Not $fStatus Then
					$iErr = $_WD_ERROR_SocketError
					$sErrText = "ReceiveResponse error"
				Else
					; Application should check what is the HTTP status code returned by the server and behave accordingly.
					; WinHttpWebSocketCompleteUpgrade will fail if the HTTP status code is different than 101.
					$iStatus = _WinHttpQueryHeaders($hRequest, $WINHTTP_QUERY_STATUS_CODE)

					If $iStatus = $HTTP_STATUS_SWITCH_PROTOCOLS Then
						$hWebSocket = _WinHttpWebSocketCompleteUpgrade($hRequest, 0)

						If $hWebSocket = 0 Then
							$iErr = $_WD_ERROR_SocketError
							$sErrText = "WebSocketCompleteUpgrade error"
						EndIf
					Else
						$iErr = $_WD_ERROR_SocketError
						$sErrText = "ReceiveResponse Status <> $HTTP_STATUS_SWITCH_PROTOCOLS"
					EndIf
				EndIf
			EndIf
		EndIf

		If Not $iErr Then
			_WinHttpCloseHandle($hRequest)

			$iID += 1
			Json_ObjPut($vData, 'id', $iID)
			Json_ObjPut($vData, 'method', $sCommand)
			Json_ObjPut($vData, 'params', $oParams)
			$vData = Json_Encode($vData)

			; Send and receive data on the websocket protocol.

			$fStatus = _WinHttpWebSocketSend($hWebSocket, _
					$WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE, _
					$vData)

			If @error Or $fStatus <> 0 Then
				$iErr = $_WD_ERROR_SocketError
				$sErrText = "WebSocketSend error"
			Else
				Do
					If $iBufferLen = 0 Then
						$iErr = $_WD_ERROR_GeneralError
						$sErrText = "Not enough memory"
						ExitLoop
					EndIf

					$tBuffer = DllStructCreate("byte[" & $iBufferLen & "]")

					$fStatus = _WinHttpWebSocketReceive($hWebSocket, _
							$tBuffer, _
							$iBytesRead, _
							$iBufferType)

					If @error Or $fStatus <> 0 Then
						$iErr = $_WD_ERROR_SocketError
						$sErrText = "WebSocketReceive error"
						ExitLoop
					EndIf

					; If we receive just part of the message restart the receive operation.
					$bRecv &= BinaryMid(DllStructGetData($tBuffer, 1), 1, $iBytesRead)
					$tBuffer = 0

					$iBufferLen -= $iBytesRead
				Until $iBufferType <> $WINHTTP_WEB_SOCKET_UTF8_FRAGMENT_BUFFER_TYPE

				If Not $iErr Then
					; We expected server just to echo single UTF8 message.
					If $iBufferType <> $WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE Then
						$iErr = $_WD_ERROR_SocketError
						$sErrText = "Unexpected buffer type"
					EndIf

					$sRecv = BinaryToString($bRecv)
				EndIf

				; Gracefully close the connection.
;~ 				$fStatus = _WinHttpWebSocketShutdown($hWebSocket, _
;~ 						$WINHTTP_WEB_SOCKET_SUCCESS_CLOSE_STATUS)

				$fStatus = _WinHttpWebSocketClose($hWebSocket, _
						$WINHTTP_WEB_SOCKET_SUCCESS_CLOSE_STATUS)

				If @error Or ($fStatus And $fStatus <> $ERROR_WINHTTP_CONNECTION_ERROR) Then
					$iErr = $_WD_ERROR_SocketError
					$sErrText = "WebSocketClose error (" & $fStatus & ")"
				Else
					; Check close status returned by the server.
					$fStatus = _WinHttpWebSocketQueryCloseStatus($hWebSocket, _
							$iStatus, _
							$iReasonLengthConsumed, _
							$tCloseReasonBuffer)

					If @error Or ($fStatus And $fStatus <> $ERROR_INVALID_OPERATION) Then
						$iErr = $_WD_ERROR_SocketError
						$sErrText = "QueryCloseStatus error (" & $fStatus & ")"
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf

	If $iErr Then
		Return SetError(__WD_Error($sFuncName, $iErr, $sErrText), 0, "")
	EndIf

	If ($sRecv) Then
		If $_WD_RESPONSE_TRIM <> -1 And StringLen($sRecv) > $_WD_RESPONSE_TRIM Then
			$sMessage &= " ResponseText=" & StringLeft($sRecv, $_WD_RESPONSE_TRIM) & "..."
		Else
			$sMessage &= " ResponseText=" & $sRecv
		EndIf
	EndIf
	Return SetError(__WD_Error($sFuncName, $_WD_ERROR_Success, $sMessage), 0, $sRecv)
EndFunc   ;==>_WD_CDPExecuteCommand

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_CDPGetSettings
; Description ...: Retrieve CDP related settings from the browser.
; Syntax ........: _WD_CDPGetSettings($sSession, $sOption)
; Parameters ....: $sSession - Session ID from _WD_CreateSession
;                  $sOption  - one of the following:
;                  |DEBUGGER - Returns the Websocket target originally returned by _WD_CreateSession
;                  |LIST - Lists websocket targets
;                  |VERSION - Returns an array containing version metadata
; Return values .: Success - The returned value depends on the selected $sOption.
;                  |DEBUGGER: Websocket target originally returned by _WD_CreateSession
;                  |LIST: Array containing websocket targets
;                  |VERSION: Array containing version metadata
;                  Failure - "" (empty string) and sets @error to one of the following values:
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_GeneralError
; Author ........: Dan Pollak
; Modified ......:
; Remarks .......:
; Related .......: _WD_LastHTTPResult
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_CDPGetSettings($sSession, $sOption)
	Local Const $sFuncName = "_WD_GetCDPSettings"
	Local $sJSON, $oJSON, $sDebuggerAddress, $iEntries, $aKeys, $iKeys, $aResults, $iErr
	Local $sKey, $vResult, $sBrowser
	$_WD_HTTPRESULT = 0

	$sJSON = _WD_GetSession($sSession)
	$oJSON = Json_Decode($sJSON)
	$sBrowser = Json_Get($oJSON, '[value][capabilities][browserName]')

	Switch $sBrowser
		Case 'firefox'
			$sKey = '[value][capabilities]["moz:debuggerAddress"]'

		Case 'chrome'
			$sKey = '[value][capabilities]["goog:chromeOptions"][debuggerAddress]'

		Case 'msedge'
			$sKey = '[value][capabilities]["ms:edgeOptions"][debuggerAddress]'

	EndSwitch

	$sDebuggerAddress = Json_Get($oJSON, $sKey)

	If @error Then
		$iErr = $_WD_ERROR_GeneralError
	Else
		$sOption = StringLower($sOption)

		Switch $sOption
			Case 'debugger'
				$vResult = $sDebuggerAddress

			Case 'list', 'version'
				$sJSON = __WD_Get("http://" & $sDebuggerAddress & "/json/" & $sOption)
				$iErr = @error

				If $iErr = $_WD_ERROR_Success Then
					$oJSON = Json_Decode($sJSON)
					$iEntries = UBound($oJSON)

					If $iEntries Then
						$aKeys = Json_ObjGetKeys($oJSON[0])
						$iKeys = UBound($aKeys)

						Dim $aResults[$iKeys][$iEntries + 1]

						For $i = 0 To $iKeys - 1
							$aResults[$i][0] = $aKeys[$i]

							For $j = 0 To $iEntries - 1
								$sKey = "[" & $j & "]." & $aKeys[$i]
								$aResults[$i][$j + 1] = Json_Get($oJSON, "[" & $j & "]." & $aKeys[$i])
							Next
						Next
					Else
						$aKeys = Json_ObjGetKeys($oJSON)
						$iKeys = UBound($aKeys)

						Dim $aResults[$iKeys][2]
						For $i = 0 To $iKeys - 1
							$aResults[$i][0] = $aKeys[$i]

							$aResults[$i][1] = Json_Get($oJSON, "." & $aKeys[$i])
						Next
					EndIf

					$vResult = $aResults
				EndIf

			Case Else
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(Debugger|List|Version) $sCommand=>" & $sOption), 0, "")
		EndSwitch

	EndIf

	If $iErr Then
		Return SetError(__WD_Error($sFuncName, $iErr), 0, "")
	EndIf
	Return SetError(__WD_Error($sFuncName, $_WD_ERROR_Success), 0, $vResult)
EndFunc   ;==>_WD_CDPGetSettings
