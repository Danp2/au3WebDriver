#include-once
#include "wd_core.au3"
#include "WinHttp_WebSocket.au3" ; https://github.com/Danp2/autoit-websocket
#include <APIErrorsConstants.au3>

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_BidiGetWebsocketURL
; Description ...: Obtain websocket URL from webdriver session data
; Syntax ........: _WD_BidiGetWebsocketURL($sSession)
; Parameters ....: $sSession - Session ID from _WD_CreateSession
; Return values .: Success - string containing Websocket URL
;                  Failure - "" and sets @error to $_WD_ERROR_NotFound
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_BidiGetWebsocketURL($sSession)
	Local Const $sFuncName = "_WD_BidiGetWebsocketURL"
	Local $iErr = $_WD_ERROR_Success
	Local $sSessDetails = _WD_GetSession($sSession)
	Local $oJSON = Json_Decode($sSessDetails)
	Local $sKey = '[value][capabilities][webSocketUrl]'
	Local $sURL = Json_Get($oJSON, $sKey)

	If @error Then $iErr = $_WD_ERROR_NotFound
	Return SetError(__WD_Error($sFuncName, $iErr, $sURL), 0, $sURL)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_BidiConnect
; Description ...: Open connection to bidirectional websocket
; Syntax ........: _WD_BidiConnect($sWebSocketURL)
; Parameters ....: $sWebSocketURL - URL from _WD_BidiGetWebsocketURL
; Return values .: Success - handle for websocket connection
;                  Failure - 0 and sets @error
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_BidiConnect($sWebSocketURL)
	Local Const $sFuncName = "_WD_BidiConnect"
	Local Const $sParameters = 'Parameters:   URL=' & $sWebSocketURL
	Local $hSocket = __WD_BidiCommands('open', $sWebSocketURL)
	Local $iErr = @error

	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters), 0, $hSocket)	
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_BidiDisconnect
; Description ...: Close connection to bidirectional websocket
; Syntax ........: _WD_BidiDisconnect()
; Parameters ....: None
; Return values .: 
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_BidiDisconnect()
	Local Const $sFuncName = "_WD_BidiDisconnect"
	Local $sResult = __WD_BidiCommands('close')
	Local $iErr = @error

	Return SetError(__WD_Error($sFuncName, $iErr), 0, $sResult)	
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_BidiExecute
; Description ...:
; Syntax ........: _WD_BidiExecute($sCommand,  $oParams)
; Parameters ....: $sCommand - Command to execute
;                  $oParams  - Parameters for command
; Return values .: Success - Response in JSON format
;                  Failure - "" and sets @error
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_BidiExecute($sCommand, $oParams)
	Local Const $sFuncName = "_WD_BidiExecute"

	Local $vResult = __WD_BidiCommands('send', $sCommand, $oParams)
	Local $iErr = @error

	Return SetError(__WD_Error($sFuncName, $iErr), 0, $vResult)	
EndFunc

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_BidiCommands
; Description ...: Perform designated Bidi command
; Syntax ........: __WD_BidiCommands($sCommand[,  $vData = Default[,  $oParams = Default]])
; Parameters ....: $sCommand - One of the following actions:
;                  |
;                  |CLOSE       - Close the current websocket connection
;                  |OPEN        - Open a websocket connection
;                  |HANDLE      - Retrieve the current websocket connection handle
;                  |SEND        - Send Bidi command via websocket
;                  $vData               - [optional] 
;                  $oParams             - [optional] 
; Return values .: None
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WD_BidiCommands($sCommand, $vData = Default, $oParams = Default)
	Local Const $sFuncName = "__WD_BidiCommands"
	Local $sMessage = 'Parameters:   Command=' & $sCommand & '   Data=' & $vData & '   Params=' & $oParams
	Local Static $hWebSocket = 0, $iID = 0
	Local $iErr = 0, $sErrText, $vTransmit = Json_ObjCreate()
	Local $fStatus, $iStatus = 0, $iReasonLengthConsumed = 0
	Local $iBufferLen = 1024, $tBuffer = 0, $bRecv = Binary("")
	Local $iBytesRead = 0, $iBufferType = 0
	Local $tCloseReasonBuffer = DllStructCreate("byte[123]")
	Local $sWSSRegex = '^((ws[s]?):\/\/)([^:\/\s]+)(?::([0-9]+))?(.*)$'
	Local $vResult 

	If $vData = Default Then $vData = ''
	If $oParams = Default Then $oParams = Json_ObjCreate()

	$sCommand = StringLower($sCommand)
	Switch $sCommand
		Case 'close' ; close websocket
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

			$hWebSocket = 0

		Case 'open' ; open websocket
			Local $hOpen = 0, $hConnect = 0, $hRequest = 0
			Local $aURL = StringRegExp($vData, $sWSSRegex, 3)

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
			EndIf

			$vResult = ($iErr) ? 0 : $hWebSocket


		Case 'handle' ; return websocket handle
			$vResult = $hWebSocket

		Case 'send' ; send command
			$iID += 1
			Json_ObjPut($vTransmit, 'id', $iID)
			Json_ObjPut($vTransmit, 'method', $vData)
			Json_ObjPut($vTransmit, 'params', $oParams)
			$vTransmit = Json_Encode($vTransmit)

			; Send and receive data on the websocket protocol.

			$fStatus = _WinHttpWebSocketSend($hWebSocket, _
					$WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE, _
					$vTransmit)

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

					$vResult = BinaryToString($bRecv)
				EndIf
			EndIf
		Case Else
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(Close|Open|Handle|Send) $sCommand=>" & $sCommand), 0, "")
	EndSwitch

	If $iErr Then 
		$vResult = ""
		$sMessage = $sErrText
	EndIf
	
	Return SetError(__WD_Error($sFuncName, $iErr, $sMessage), 0, $vResult)		
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_BidiGetContextID
; Description ...: Retrieve browsing context ID
; Syntax ........: _WD_BidiGetContextID()
; Parameters ....: None
; Return values .: Success - string containing browsing context ID
;                  Failure - "" and sets @error to one of the following values:
;                  - $_WD_ERROR_Exception
;                  - $_WD_ERROR_NotFound
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_BidiGetContextID()
	Local Const $sFuncName = "_WD_BidiGetContextID"
	Local $iErr = $_WD_ERROR_Success, $sContext = ''
	Local $oParams = Json_ObjCreate()

	Local $sResult = _WD_BidiExecute('browsingContext.getTree', $oParams)
	If @error Then 
		$iErr = $_WD_ERROR_Exception
	Else
		Local $oJSON = Json_Decode($sResult)
		Local $sKey = '[result][contexts][0][context]'
		$sContext = Json_Get($oJSON, $sKey)
		If @error Then $iErr = $_WD_ERROR_NotFound
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr, $sContext), 0, $sContext)
EndFunc
