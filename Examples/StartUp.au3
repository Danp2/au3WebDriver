#include-once
#include "..\wd_helper.au3"
#include "..\wd_capabilities.au3"

Func _WDEx_SetupWrapper($sBrowserName, $_WD_DEBUG_Level, $b_Headless)
	$_WD_DEBUG = $_WD_DEBUG_Level
	_WD_UpdateDriver($sBrowserName)
	If @error Then Return SetError(@error, @extended, '')

	Local $sCapabilities = ''
	Switch $sBrowserName
		Case "chrome"
			$sCapabilities = __WDEx_SetupChrome($b_Headless)
		Case "firefox"
			$sCapabilities = __WDEx_SetupGecko($b_Headless)
		Case "msedge"
			$sCapabilities = __WDEx_SetupEdge($b_Headless)
		Case "opera"
			$sCapabilities = __WDEx_SetupOpera($b_Headless)
		Case Else
			Return SetError($_WD_ERROR_NotSupported, @extended, '')
	EndSwitch

	Local $iWebDriver_PID = _WD_Startup()
	If @error Then Return SetError(@error, @extended, '')

	Local $sSession = _WD_CreateSession($sCapabilities)
	Return SetError(@error, $iWebDriver_PID, $sSession)

EndFunc   ;==>_WDEx_SetupWrapper

Func __WDEx_SetupGecko($bHeadless)
	_WD_Option('Driver', 'geckodriver.exe')
	_WD_Option('DriverParams', '--log trace')
	_WD_Option('Port', 4444)

;~ 	Local $sCapabilities = '{"capabilities": {"alwaysMatch": {"browserName": "firefox", "acceptInsecureCerts":true}}}'
	_WD_CapabilitiesStartup()
	_WD_CapabilitiesAdd('alwaysMatch', 'firefox')
	_WD_CapabilitiesAdd('browserName', 'firefox')
	_WD_CapabilitiesAdd('acceptInsecureCerts', True)
	If $bHeadless Then _WD_CapabilitiesAdd('args', '--headless')
	_WD_CapabilitiesDump(@ScriptLineNumber) ; dump current Capabilities setting to console - only for testing in this demo
	Local $sCapabilities = _WD_CapabilitiesGet()
	Return $sCapabilities
EndFunc   ;==>__WDEx_SetupGecko

Func __WDEx_SetupChrome($bHeadless)
	_WD_Option('Driver', 'chromedriver.exe')
	_WD_Option('Port', 9515)
	_WD_Option('DriverParams', '--verbose --log-path="' & @ScriptDir & '\chrome.log"')

;~ 	Local $sCapabilities = '{"capabilities": {"alwaysMatch": {"goog:chromeOptions": {"w3c": true, "excludeSwitches": [ "enable-automation"]}}}}'
	_WD_CapabilitiesStartup()
	_WD_CapabilitiesAdd('alwaysMatch', 'chrome')
	_WD_CapabilitiesAdd('w3c', True)
	_WD_CapabilitiesAdd('excludeSwitches', 'enable-automation')
	If $bHeadless Then _WD_CapabilitiesAdd('args', '--headless')
	_WD_CapabilitiesDump(@ScriptLineNumber) ; dump current Capabilities setting to console - only for testing in this demo
	Local $sCapabilities = _WD_CapabilitiesGet()
	Return $sCapabilities
EndFunc   ;==>__WDEx_SetupChrome

Func __WDEx_SetupEdge($bHeadless)
	_WD_Option('Driver', 'msedgedriver.exe')
	_WD_Option('Port', 9515)
	_WD_Option('DriverParams', '--verbose --log-path="' & @ScriptDir & '\msedge.log"')

;~ 	Local $sCapabilities = '{"capabilities": {"alwaysMatch": {"ms:edgeOptions": {"excludeSwitches": [ "enable-automation"]}}}}'
	_WD_CapabilitiesStartup()
	_WD_CapabilitiesAdd('alwaysMatch', 'msedge')
	_WD_CapabilitiesAdd('excludeSwitches', 'enable-automation')
	If $bHeadless Then _WD_CapabilitiesAdd('args', '--headless')
	_WD_CapabilitiesDump(@ScriptLineNumber) ; dump current Capabilities setting to console - only for testing in this demo
	Local $sCapabilities = _WD_CapabilitiesGet()
	Return $sCapabilities
EndFunc   ;==>__WDEx_SetupEdge

Func __WDEx_SetupOpera($bHeadless)
	_WD_Option('Driver', 'operadriver.exe')
	_WD_Option('Port', 9515)
	_WD_Option('DriverParams', '--verbose --log-path="' & @ScriptDir & '\opera.log"')

;~ 	Local $sCapabilities = '{"capabilities": {"alwaysMatch":{"goog:chromeOptions": {"w3c":true, "excludeSwitches":["enable-automation"], "binary":"C:\\Users\\......\\AppData\\Local\\Programs\\Opera\\opera.exe"}}}}'
	_WD_CapabilitiesStartup()
	_WD_CapabilitiesAdd('alwaysMatch', 'opera')
	_WD_CapabilitiesAdd('w3c', True)
	_WD_CapabilitiesAdd('excludeSwitches', 'enable-automation')
	; REMARK
	; using 32bit operadriver.exe requires to set 'binary' capabilities,
	; using 64bit operadriver.exe dosen't require to set this capability, but at the same time setting is not affecting the script
	; So this is good habit to setup for any case.
	_WD_CapabilitiesAdd('binary', _WD_GetBrowserPath("opera"))
	ConsoleWrite("wd_demo.au3: _WD_GetBrowserPath() > " & _WD_GetBrowserPath("opera") & @CRLF)

	If $bHeadless Then _WD_CapabilitiesAdd('args', '--headless')
	_WD_CapabilitiesDump(@ScriptLineNumber) ; dump current Capabilities setting to console - only for testing in this demo
	Local $sCapabilities = _WD_CapabilitiesGet()
	Return $sCapabilities
EndFunc   ;==>__WDEx_SetupOpera

Func _WDEx_NavigateCheckBanner($sSession, $sURL, $sXpath)
	_WD_Navigate($sSession, $sURL)
	_WD_LoadWait($sSession)

	; Check if designated element is visible, as it can hide all sub elements in case when COOKIE aproval message is visible
	_WD_WaitElement($sSession, $_WD_LOCATOR_ByXPath, $sXpath, 0, 1000 * 60, $_WD_OPTION_NoMatch)
	If @error Then
		ConsoleWrite('wd_demo.au3: (' & @ScriptLineNumber & ') : "' & $sURL & '" page view is hidden - it is possible that the message about COOKIE files was not accepted')
		Return SetError(@error, @extended)
	EndIf
EndFunc   ;==>_WDEx_NavigateCheckBanner
