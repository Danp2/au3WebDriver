#include "wd_helper.au3"
#include "wd_capabilities.au3"

_Example()

Func _Example()
	Local $sSession = _Attach()
	_WD_Navigate($sSession, "https://www.autoitscript.com/forum")
EndFunc   ;==>_Example

Func _Attach()
	Local $sBrowser = $CmdLine[1]
	Local $sCapabilities = ''
	Switch $sBrowser
		Case 'firefox'
			$sCapabilities = SetupGecko()
		Case 'chrome'
			$sCapabilities = SetupChrome()
		Case 'msedge'
			$sCapabilities = SetupEdge()
	EndSwitch

	Local $sSession = _WD_CreateSession($sCapabilities)
	Return $sSession
EndFunc   ;==>_Attach


Func SetupGecko()
	_WD_Option('Driver', 'geckodriver.exe')
	_WD_Option('DriverParams', '--log trace --connect-existing  --marionette-port 2828')
	_WD_Option('Port', 4444)

	_WD_CapabilitiesStartup()
	_WD_CapabilitiesAdd('alwaysMatch', 'firefox')
	_WD_CapabilitiesAdd('browserName', 'firefox')
	_WD_CapabilitiesAdd('acceptInsecureCerts', True)
	Local $sCapabilities = _WD_CapabilitiesGet()
	Return $sCapabilities
EndFunc   ;==>SetupGecko

Func SetupChrome()
	_WD_Option('Driver', 'chromedriver.exe')
	_WD_Option('Port', 9515)
	_WD_Option('DriverParams', '--verbose --log-path="' & @ScriptDir & '\chrome.log" --connect-existing  --marionette-port 2828')

	_WD_CapabilitiesStartup()
	_WD_CapabilitiesAdd('alwaysMatch', 'chrome')
	_WD_CapabilitiesAdd('w3c', True)
	_WD_CapabilitiesAdd('excludeSwitches', 'enable-automation')
	Local $sCapabilities = _WD_CapabilitiesGet()
	Return $sCapabilities
EndFunc   ;==>SetupChrome

Func SetupEdge()
	_WD_Option('Driver', 'msedgedriver.exe')
	_WD_Option('Port', 9515)
	_WD_Option('DriverParams', '--verbose --log-path="' & @ScriptDir & '\msedge.log" --connect-existing  --marionette-port 2828')

	_WD_CapabilitiesStartup()
	_WD_CapabilitiesAdd('alwaysMatch', 'edge')
	_WD_CapabilitiesAdd('excludeSwitches', 'enable-automation')
	Local $sCapabilities = _WD_CapabilitiesGet()
	Return $sCapabilities
EndFunc   ;==>SetupEdge
