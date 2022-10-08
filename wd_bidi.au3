#include-once
#include "wd_core.au3"

; Requires Websocat, which can be downloaded from https://github.com/vi/websocat

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_BidiGetWebsocketURL
; Description ...: Obtain websocket URL from webdriver session data
; Syntax ........: _WD_BidiGetWebsocketURL($sSession)
; Parameters ....: $sSession - Session ID from _WD_CreateSession
; Return values .: Success - string containing Websocket URL
;                  Failure - "" and sets @error to $_WD_ERROR_NotFound
; Author ........: Danp2
; Modified ......:
; Remarks .......: This functionality depends on the webdriver session being initiated with a Capabilities string that 
;                  includes the directive "webSocketUrl":true
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
EndFunc   ;==>_WD_BidiGetWebsocketURL

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_BidiConnect
; Description ...: Open connection to bidirectional websocket
; Syntax ........: _WD_BidiConnect($sWebSocketURL)
; Parameters ....: $sSession - Session ID from _WD_CreateSession
; Return values .: Success - None
;                  Failure - Sets @error
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_BidiConnect($sSession)
	Local Const $sFuncName = "_WD_BidiConnect"
	Local Const $sParameters = 'Parameters:   Session=' & $sSession
	Local $iErr = $_WD_ERROR_Success

	__WD_BidiActions('open', $sSession)
	If @error Then $iErr = $_WD_ERROR_Exception

	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters), 0)
EndFunc   ;==>_WD_BidiConnect

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
	Local $iErr = $_WD_ERROR_Success

	__WD_BidiActions('close')

	Return SetError(__WD_Error($sFuncName, $iErr))
EndFunc   ;==>_WD_BidiDisconnect

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_BidiIsConnected
; Description ...: Return a boolean indicating if the Bidi session is connected.
; Syntax ........: _WD_BidiIsConnected()
; Parameters ....: None
; Return values .: Boolean response indicating connection status
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_BidiIsConnected()
	Local Const $sFuncName = "_WD_BidiIsConnected"
	Local $iErr = $_WD_ERROR_Success

	Local $bResult = __WD_BidiActions('status')

	Return SetError(__WD_Error($sFuncName, $iErr), 0, $bResult)
EndFunc   ;==>_WD_BidiIsConnected

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_BidiExecute
; Description ...: Execute a Webdriver BiDi command
; Syntax ........: _WD_BidiExecute($sCommand,  $oParams)
; Parameters ....: $sCommand - Command to execute
;                  $oParams  - Parameters for command
;                  $bAsync   - Perform request asyncronously? Default is False
; Return values .: Success - Response in JSON format (sync) or ID of request (async)
;                  Failure - "" and sets @error
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_BidiExecute($sCommand, $oParams, $bAsync = Default)
	Local Const $sFuncName = "_WD_BidiExecute"
	Local Const $sParameters = 'Parameters:   Command=' & $sCommand & '   Params=' & (($oParams = Default) ? $oParams : Json_Encode($oParams, $Json_UNQUOTED_STRING))
	Local $_WD_DEBUG_Saved = $_WD_DEBUG ; save current DEBUG level

	If $bAsync = Default Then $bAsync = False

	; Prevent logging from __WD_BidiActions if not in Full debug mode
	If $_WD_DEBUG <> $_WD_DEBUG_Full Then $_WD_DEBUG = $_WD_DEBUG_None

	Local $vResult = __WD_BidiActions('send', $sCommand, $oParams)
	Local $iErr = @error

	If $iErr = $_WD_ERROR_Success And Not $bAsync Then
		$vResult = _WD_BidiGetResult($vResult)
		$iErr = @error
	EndIf

	$_WD_DEBUG = $_WD_DEBUG_Saved ; restore DEBUG level

	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters), 0, $vResult)
EndFunc   ;==>_WD_BidiExecute

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_BidiGetResult
; Description ...: Retrieve results from prior call to _WD_BidiExecute with $bAsyc = True
; Syntax ........: _WD_BidiGetResult($iID)
; Parameters ....: $iID                 - Identifier previously returned by _WD_BidiExecute
; Return values .: Success - Result in JSON format
;                  Failure - "" and sets @error
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_BidiGetResult($iID)
	Local Const $sFuncName = "_WD_BidiGetResult"
	Local Const $sParameters = 'Parameters:   ID=' & $iID
	Local $oParams = Json_ObjCreate()
	Json_ObjPut($oParams, 'id', $iID)

	Local $vResult = __WD_BidiActions('receive', 'result', $oParams)
	Local $iErr = @error

	Return SetError(__WD_Error($sFuncName, $iErr, $sParameters), 0, $vResult)
EndFunc   ;==>_WD_BidiGetResult

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_BidiGetEvent
; Description ...: Retrieve next avail event
; Syntax ........: _WD_BidiGetEvent()
; Parameters ....: None
; Return values .: Success - Result in JSON format
;                  Failure - "" and sets @error
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_BidiGetEvent()
	Local Const $sFuncName = "_WD_BidiGetEvent"
	Local $vResult = __WD_BidiActions('receive', 'event')
	Local $iErr = @error

	Return SetError(__WD_Error($sFuncName, $iErr), 0, $vResult)
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
EndFunc   ;==>_WD_BidiGetContextID

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_BidiActions
; Description ...: Perform designated Bidi action
; Syntax ........: __WD_BidiActions($sAction[,  $sArgument = Default[,  $oParams = Default]])
; Parameters ....: $sAction - One of the following actions:
;                  |
;                  |CLOSE       - Close the current websocket connection
;                  |COUNT       - Get count of pending results / events
;                  |OPEN        - Open a websocket connection
;                  |RECEIVE     - Receive results / events via websocket
;                  |SEND        - Send Bidi command via websocket
;                  |STATUS      - Check status of bidi connection
;
;                  $sArgument   - [optional] URL or BiDi method. Default is "".
;                  $oParams     - [optional] Parameters for BiDi method. Default is {}.
; Return values .: Success - result of requested action
;                  Failure - "" and sets @error
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WD_BidiActions($sAction, $sArgument = Default, $oParams = Default)
	Local Const $sFuncName = "__WD_BidiActions"
	Local $sMessage = 'Parameters:   Action=' & $sAction & '   Argument=' & $sArgument & '   Params=' & (($oParams = Default) ? $oParams : Json_Encode($oParams, $Json_UNQUOTED_STRING))
	Local Static $iSocket = 0, $iPID = 0, $iID = 0
	Local Static $mEvents[], $mResults[]
	Local $iErr = 0, $sErrText, $vTransmit = Json_ObjCreate()
	Local $bRecv = Binary(""), $vResult = "", $oJSON, $aKeys, $iKey, $iResult, $sRecv

	If $sArgument = Default Then $sArgument = ''
	If $oParams = Default Then $oParams = Json_ObjCreate()

	$sAction = StringLower($sAction)
	Switch $sAction
		Case 'close' ; close websocket
			TCPCloseSocket($iSocket)
			TCPShutdown()
			ProcessClose($iPID)

			$iSocket = 0
			$iPID = 0

		Case 'open' ; open websocket
			If Not $iPID And Not $iSocket Then
				Local $_WD_DEBUG_Saved = $_WD_DEBUG ; save current DEBUG level

				; Prevent logging if not in Full debug mode
				If $_WD_DEBUG <> $_WD_DEBUG_Full Then $_WD_DEBUG = $_WD_DEBUG_None

				Local $sIPAddress = "127.0.0.1" ; local host
				Local $iPort = Random(60000, 65000, 1) ; Port used for the connection.

				Local $sWSUrl = _WD_BidiGetWebsocketURL($sArgument)
				Local $sCmd = "websocat.exe -tv -E tcp-l:" & $sIPAddress & ":" & $iPort & " " & $sWSUrl
				$iPID = Run(@ComSpec & " /c " & $sCmd)

				If $iPID Then
					For $i = 0 To 10 Step 1
						Sleep(100)
						$iSocket = TCPConnect($sIPAddress, $iPort)
						If Not @error Then ExitLoop
					Next

					If @error Then $iErr = $_WD_ERROR_SocketError
				Else
					$iErr = $_WD_ERROR_FileIssue
				EndIf

				$_WD_DEBUG = $_WD_DEBUG_Saved ; restore DEBUG level
			EndIf

			$vResult = ($iSocket) ? $iSocket : 0

		Case 'send' ; send command
			$iID += 1
			Json_ObjPut($vTransmit, 'id', $iID)
			Json_ObjPut($vTransmit, 'method', $sArgument)
			Json_ObjPut($vTransmit, 'params', $oParams)
			$vTransmit = Json_Encode($vTransmit)

			; Send and receive data on the websocket protocol.
			__TCPSendLine($iSocket, $vTransmit)

			If @error Then
				$iErr = $_WD_ERROR_SocketError
				$sErrText = "WebSocketSend error"
			Else
				$vResult = $iID
			EndIf

		Case 'receive' ; receive response
			$bRecv = __TCPRecvLine($iSocket)

			If @error Then
				$iErr = $_WD_ERROR_SendRecv
			Else	
				If BinaryLen($bRecv) Then
					$sRecv = BinaryToString($bRecv)

					$oJSON = Json_Decode($sRecv)
					If Json_IsObject($oJSON) Then
						If Json_ObjExists($oJSON, 'id') And _
						(Json_ObjExists($oJSON, 'result') or Json_ObjExists($oJSON, 'error')) Then
							$iResult = Json_ObjGet($oJSON, 'id')
							$mResults[$iResult] = $sRecv
						Else
							MapAppend($mEvents, $sRecv)
						EndIf
					Else
						$iErr = $_WD_ERROR_UnknownCommand
						$sErrText = "Non-JSON response from webdriver"
					EndIf
				EndIf

				Switch $sArgument
					Case 'event' ; request first event
						$aKeys = MapKeys($mEvents)

						If Not @error Then
							$vResult = $mEvents[$aKeys[0]]
							MapRemove($mEvents, $aKeys[0])
						EndIf
					Case 'result' ; request result
						$iKey = Json_ObjGet($oParams, 'id')

						If Not @error Then
							If MapExists($mResults, $iKey) Then
								$vResult = $mResults[$iKey]
								MapRemove($mResults, $iKey)
							Else
								$iErr = $_WD_ERROR_NotFound
							EndIf
						EndIf
				EndSwitch
			EndIf
		Case 'count'
			Switch $sArgument
				Case 'event' ; request event count
					$vResult = UBound(MapKeys($mEvents))
				Case 'result' ; request result count
					$vResult = UBound(MapKeys($mResults))
			EndSwitch

		Case 'maps'
			Switch $sArgument
				Case 'event' ; request event count
					$vResult = $mEvents
				Case 'result' ; request result count
					$vResult = $mResults
			EndSwitch
		
		Case 'status'
			$vResult = ($iSocket And $iPID And ProcessExists($iPID))

		Case Else
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, "(Close|Count|Maps|Open|Receive|Send|Status) $sAction=>" & $sAction), 0, "")
	EndSwitch

	If $iErr Then
		$vResult = ""
		$sMessage = $sErrText
	EndIf

	Return SetError(__WD_Error($sFuncName, $iErr, $sMessage), 0, $vResult)
EndFunc   ;==>__WD_BidiActions

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __TCPRecvLine
; Description ...: Receive binary data from a connected socket 
; Syntax ........: __TCPRecvLine($iSocket[,  $bEOLChar = 0x0A])
; Parameters ....: $iSocket             - Socket identifier
;                  $bEOLChar            - [optional] Character designating end of line. Default is 0x0A
; Return values .: Success - String in binary format
;                  Failure - "" and sets @error
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __TCPRecvLine($iSocket, $bEOLChar = 0x0A)
	Local Static $bReceived = Binary("")     ; Buffer for received data
	Local $bResult = Binary("")
	Local $bData = TCPRecv($iSocket, 4096, $TCP_DATA_BINARY)
	If @error Then
		Return SetError(1, 0, $bResult)
	EndIf

	$bReceived = $bReceived & $bData
	Local $iLength = BinaryLen($bReceived)

	If $iLength Then
		For $i = 1 To $iLength
			If BinaryMid($bReceived, $i, 1) = $bEOLChar Then
				$bResult = BinaryMid($bReceived, 1, $i)    ; Save the found line and
				$bReceived = BinaryMid($bReceived, $i + 1) ; remove it from the buffer
				ExitLoop
			EndIf
		Next
	EndIf

	Return $bResult
EndFunc   ;==>__TCPRecvLine

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __TCPSendLine
; Description ...: Sends data on a connected socket
; Syntax ........: __TCPSendLine($iSocket,  $sData)
; Parameters ....: $iSocket             - Socket identifier
;                  $sData               - Data to send
; Return values .: None
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __TCPSendLine($iSocket, $sData)
	If StringRight($sData, 2) <> @CRLF Then
		$sData &= @CRLF
	EndIf

	TCPSend($iSocket, $sData)
EndFunc   ;==>__TCPSendLine
