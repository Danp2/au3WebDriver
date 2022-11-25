#include-once

; WebDriver related UDF's
#include "wd_core.au3"
#include "jq.au3"

#Region Copyright
#cs
	* WD_BiDi.au3
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

#Region Description
; ==============================================================================
; UDF ...........: WD_BiDi.au3
; Description ...: A UDF for bidirectional webdriver automation
; Requirement ...: jq UDF from @TheXman
;                  https://www.autoitscript.com/forum/files/file/502-jq-udf-a-powerful-flexible-json-processor/
;
;				   One of the following websocket clients --
;                  websocat   			https://github.com/vi/websocat/releases
;                  sgcWebSocketClient	https://www.esegece.com/products/apps
;
; Author(s) .....: Dan Pollak
; AutoIt Version : v3.3.16.1
; ==============================================================================
#EndRegion Description

#Region Global Constants
Global Enum _ ; Column positions of JQ array
		$_WD_JQ_WSEvent, _
		$_WD_JQ_WDEvent, _
		$_WD_JQ_Code, _
		$_WD_JQ_Data, _
		$_WD_JQ__COUNTER

Global Enum _ ; Column positions of $_WD_BidiClients
		$_WD_BIDICLIENT_Name, _
		$_WD_BIDICLIENT_ExeName, _
		$_WD_BIDICLIENT_ExeParams, _
		$_WD_BIDICLIENT_OpenWS, _
		$_WD_BIDICLIENT_Message, _
		$_WD_BIDICLIENT__COUNTER

Global $_WD_BidiClients[][$_WD_BIDICLIENT__COUNTER] = _
		[ _
		["sgcwebsocket", "sgcWebSocketClient.exe", " -server -server.ip %s -server.port %s", '{"message":"open", "params":{"url": "%s"}}', '{"message":"write", "params":{"text":%s}}'], _
		["websocat", "websocat.exe", " -tv -E tcp-l:%s:%s %s", '', '%s'] _
		]
#EndRegion Global Constants

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

	__WD_BidiActions('close', $sSession)
	__WD_BidiActions('open', $sSession)
	If @error Then
		$iErr = $_WD_ERROR_Exception
	Else
		_jqInit()
		If @error Then $iErr = $_WD_ERROR_SocketError
	EndIf

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
; Name ..........: _WD_BidiSetClient
; Description ...: Set the websocket client
; Syntax ........: _WD_BidiSetClient($sClient)
; Parameters ....: $sClient             - Name of desired websocket client
; Return values .: None
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......: Clients are defined in $_WD_BidiClients
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_BidiSetClient($sClient)
	Local Const $sFuncName = "_WD_BidiSetClient"
	__WD_BidiActions('init', $sClient)
	Local $iErr = @error

	Return SetError(__WD_Error($sFuncName, $iErr))
EndFunc

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
; Description ...: Retrieve results from prior call to _WD_BidiExecute with $bAsync = True
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
; Description ...: Retrieve next available event
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
EndFunc   ;==>_WD_BidiGetEvent

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
	Local Static $iSocket = 0, $iPID = 0, $iID = 0, $iClient = 0
	Local Static $mEvents[], $mResults[]

	Local $iErr = 0, $sErrText, $vTransmit = Json_ObjCreate()
	Local $vResult = "", $oJSON, $aKeys, $iKey
	Local $aResults

	If $sArgument = Default Then $sArgument = ''
	If $oParams = Default Then $oParams = Json_ObjCreate()

	$sAction = StringLower($sAction)
	Switch $sAction
		Case 'close' ; close websocket
			If $iSocket Then TCPCloseSocket($iSocket)
			TCPShutdown()
			If $iPID Then ProcessClose($iPID)

			$iSocket = 0
			$iPID = 0

		Case 'open' ; open websocket
			If Not $iPID And Not $iSocket Then
				Local $_WD_DEBUG_Saved = $_WD_DEBUG ; save current DEBUG level

				; Prevent logging if not in Full debug mode
				If $_WD_DEBUG <> $_WD_DEBUG_Full Then $_WD_DEBUG = $_WD_DEBUG_None

				Local $sIPAddress = "127.0.0.1" ; local host
				Local $iPort = __WD_GetFreePort(60000, 65000) ; Port used for the connection.

				Local $sWSUrl = _WD_BidiGetWebsocketURL($sArgument)

				Local $sCmd = $_WD_BidiClients[$iClient][$_WD_BIDICLIENT_ExeName] & $_WD_BidiClients[$iClient][$_WD_BIDICLIENT_ExeParams]
				$sCmd = StringFormat($sCmd, $sIPAddress, $iPort, $sWSUrl)
				$iPID = Run(@ComSpec & " /c " & $sCmd, @ScriptDir)

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

			If $_WD_BidiClients[$iClient][$_WD_BIDICLIENT_OpenWS] Then
				$sCmd = $_WD_BidiClients[$iClient][$_WD_BIDICLIENT_OpenWS]
				$sCmd = StringFormat($sCmd, $sWSUrl)
				__TCPSendLine($iSocket, $sCmd)
			EndIf

			$vResult = ($iSocket) ? $iSocket : 0

		Case 'send' ; send command
			$iID += 1
			Json_ObjPut($vTransmit, 'id', $iID)
			Json_ObjPut($vTransmit, 'method', $sArgument)
			Json_ObjPut($vTransmit, 'params', $oParams)
			$vTransmit = StringFormat($_WD_BidiClients[$iClient][$_WD_BIDICLIENT_Message], Json_Encode($vTransmit))

			; Send and receive data on the websocket protocol.
			__TCPSendLine($iSocket, $vTransmit)

			If @error Then
				$iErr = $_WD_ERROR_SocketError
				$sErrText = "WebSocketSend error"
			Else
				$vResult = $iID
			EndIf

		Case 'receive' ; receive responses / events
			$aResults = __WD_BidiGetData($iSocket, 250)

			If Not @error Then
				For $i = 0 To UBound($aResults) - 1

					Switch $aResults[$i][$_WD_JQ_WSEvent]
						Case 'message'
							Switch $aResults[$i][$_WD_JQ_WDEvent]
								Case 'response'
									$mResults[Number($aResults[$i][$_WD_JQ_Code])] = $aResults[$i][$_WD_JQ_Data]

								Case 'event'
									MapAppend($mEvents, $aResults[$i][$_WD_JQ_Data])

							EndSwitch

						Case 'connected', 'disconnected', 'error'
							MapAppend($mEvents, $aResults[$i][$_WD_JQ_Data])
					EndSwitch
				Next
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

		Case 'count'
			Switch $sArgument
				Case 'event' ; request event count
					$vResult = UBound(MapKeys($mEvents))

				Case 'result' ; request result count
					$vResult = UBound(MapKeys($mResults))
			EndSwitch

		Case 'maps'
			Switch $sArgument
				Case 'event'
					$vResult = $mEvents

				Case 'result'
					$vResult = $mResults
			EndSwitch

		Case 'status'
			$vResult = ($iSocket And $iPID And ProcessExists($iPID))

		Case 'init'
			Local $iIndex = _ArraySearch($_WD_BidiClients, StringLower($sArgument), Default, Default, Default, Default, Default, $_WD_BIDICLIENT_Name)
			If @error Then 
				$iErr = $_WD_ERROR_NotFound
				$sErrText = 'Unsupported client'
			Else
				$iClient = $iIndex
			EndIf

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
; Name ..........: __WD_BidiGetData
; Description ...: Receive data from a connected TCP socket
; Syntax ........:__WD_BidiGetData($iSocket[,  $iTimeout = 500])
; Parameters ....: $iSocket             - Socket identifier
;                  $iTimeout            - [optional] Max time to wait for data to arrive
; Return values .: Success - Array containing received data
;                  Failure - "" and sets @error
; Author ........: Danp2
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WD_BidiGetData($iSocket, $iTimeout = 500)
	Local $sReceived = ""    ; Buffer for received data
	Local $iPrevDataLen = 0
	Local $aEventQueue[0][$_WD_JQ__COUNTER]
	Local $sResult
	Local $hTimeoutTimer = TimerInit()    ; Initialize timeout timer

	; Receive until timeout or data received
	Do
		Sleep(10)
		$sReceived &= TCPRecv($iSocket, 2048)
	Until $sReceived Or TimerDiff($hTimeoutTimer) >= $iTimeout

	; Timeout occurred waiting for events or user aborted
	If StringLen($sReceived) = 0 Then Return SetError(1, 0, "")

	Do
		Sleep(10)
		$iPrevDataLen = StringLen($sReceived)
		$sReceived &= TCPRecv($iSocket, 2048)
	Until StringLen($sReceived) = $iPrevDataLen

	Local Const $JQ_PARSE_EVENTS = _
			'[' & _
			'	if has("event") then' & _
			'		.event, ' & _
			'		if .event == "message" then' & _
			'			if .text|has("id") then' & _
			'			  "response", .text.id,.text|tostring' & _
			'			else' & _
			'			  "event", "",.text|tostring' & _
			'			end' & _
			'		elif .event == "error" then .description, "", .|tostring' & _
			'		elif .event == "connected" then "", "", .|tostring' & _
			'		elif .event == "disconnected" then "", .code, .|tostring' & _
			'		else' & _
			'		""' & _
			'		end' & _
			'	else ' & _
			'		if has("id") then "message", "response", .id, .|tostring' & _
			'		else "message", "event", "", .|tostring' & _
			'		end' & _
			'	end' & _
			'  ]' & _
			'|@tsv'

	; Strip excess quotation marks
	$sReceived = StringReplace($sReceived, '"{', '{')
	$sReceived = StringReplace($sReceived, '}"', '}')

	; Parse JSON events into the event queue
	$sResult = _jqExec($sReceived, $JQ_PARSE_EVENTS)
	If @error Then Return SetError(2, 0, "")

	_ArrayAdd($aEventQueue, $sResult, 0, @TAB)
	If @error Then Return SetError(3, 0, @error)

	Return $aEventQueue
EndFunc   ;==>__WD_BidiGetData

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

Func __WD_GetFreePort($iMinPort, $iMaxPort)
	Local $aPorts = _WinAPI_GetTcpTable()

	If Not @error Then
		For $iPort = $iMinPort To $iMaxPort
			_ArraySearch($aPorts, $iPort, Default, Default, Default, Default, Default, 3)
			If @error = 6 Then Return $iPort
		Next
	Endif

	Return 0
EndFunc   ;==>__WD_GetFreePort

Func _WinAPI_GetTcpTable()
    ;funkey 2012.12.14
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
EndFunc   ;==>_WinAPI_GetTcpTable