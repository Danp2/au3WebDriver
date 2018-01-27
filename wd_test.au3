#include "wd_core.au3"
#include "wd_helper.au3"

Local Enum $eFireFox = 0, _
			$eChrome

Local $aTestSuite[][2] = [["TestTimeouts", False], ["TestNavigation", False], ["TestElements", True], ["TestScript", False], ["TestCookies", False], ["TestAlerts", False]]

Local Const $_TestType = $eChrome
Local $sDesiredCapabilities
Local $iIndex
Local $sSession

$_WD_DEBUG = True

Switch $_TestType
	Case $eFireFox
		SetupGecko()

	Case $eChrome
		SetupChrome()

EndSwitch

_WD_Startup()

$sSession = _WD_CreateSession($sDesiredCapabilities)


For $iIndex = 0 To UBound($aTestSuite, $UBOUND_ROWS) - 1
	If $aTestSuite[$iIndex][1] Then
		ConsoleWrite("Running: " & $aTestSuite[$iIndex][0] & @CRLF)
		Call($aTestSuite[$iIndex][0])
	Else
		ConsoleWrite("Bypass: " & $aTestSuite[$iIndex][0] & @CRLF)
	EndIf
Next

_WD_DeleteSession($sSession)
_WD_Shutdown()


Func TestTimeouts()
	_WD_Timeouts($sSession)
	_WD_Timeouts($sSession, '{"pageLoad":2000}')
	_WD_Timeouts($sSession)
EndFunc

Func TestNavigation()
	_WD_Navigate($sSession, "http://google.com")
	ConsoleWrite("URL=" & _WD_Action($sSession, 'url') & @CRLF)
	_WD_Action($sSession, "back")
	ConsoleWrite("URL=" & _WD_Action($sSession, 'url') & @CRLF)
	_WD_Action($sSession, "forward")
	ConsoleWrite("URL=" & _WD_Action($sSession, 'url') & @CRLF)
	ConsoleWrite("Title=" & _WD_Action($sSession, 'title') & @CRLF)
EndFunc

;_WDWindow($sSession, 'frame', '{"id":nullelse
Func TestElements()
	_WD_Navigate($sSession, "http://google.com")
	$sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//input[@id='lst-ib1']")

	If @error = $_WD_ERROR_NoMatch Then
		$sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//input[@id='lst-ib']")
	EndIf

	$aElements = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//div/input", '', True)

	_ArrayDisplay($aElements)

	_WD_ElementAction($sSession, $sElement, 'value', "testing 123")
	_WD_ElementAction($sSession, $sElement, 'text')
	_WD_ElementAction($sSession, $sElement, 'clear')
	_WD_ElementAction($sSession, $sElement, 'value', "abc xyz")
	_WD_ElementAction($sSession, $sElement, 'text')
	_WD_ElementAction($sSession, $sElement, 'clear')
	_WD_ElementAction($sSession, $sElement, 'value', "fujimo")
	_WD_ElementAction($sSession, $sElement, 'text')
	_WD_ElementAction($sSession, $sElement, 'click')

	_WD_ElementAction($sSession, $sElement, 'Attribute', 'text')

	$sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//input[@id='lst-ib']")
	$sValue = _WD_ElementAction($sSession, $sElement, 'property', 'value')

	ConsoleWrite('value = ' & $sValue & @CRLF)

EndFunc

Func TestScript()
	_WD_ExecuteScript($sSession, "return arguments[0].second;", '{"first": "1st", "second": "2nd", "third": "3rd"}')
	_WD_Alert($sSession, 'Dismiss')
EndFunc

Func TestCookies()
	_WD_Navigate($sSession, "http://google.com")
	_WD_Cookies($sSession, 'Get', 'NID')
EndFunc

Func TestAlerts()
	ConsoleWrite('Alert Detected => ' & _WD_Alert($sSession, 'status') & @CRLF)
	_WD_ExecuteScript($sSession, "alert('testing 123')")
	ConsoleWrite('Alert Detected => ' & _WD_Alert($sSession, 'status') & @CRLF)
	ConsoleWrite('Text Detected => ' & _WD_Alert($sSession, 'gettext') & @CRLF)
	_WD_Alert($sSession, 'sendtext', 'new text')
	ConsoleWrite('Text Detected => ' & _WD_Alert($sSession, 'gettext') & @CRLF)
	_WD_Alert($sSession, 'Dismiss')

EndFunc


Func SetupGecko()
_WD_Option('Driver', 'geckodriver.exe')
_WD_Option('DriverParams', '--log trace')
_WD_Option('Port', 4444)

$sDesiredCapabilities = '{"desiredCapabilities":{"javascriptEnabled":true,"nativeEvents":true,"acceptInsecureCerts":true}}'
EndFunc

Func SetupChrome()
_WD_Option('Driver', 'chromedriver.exe')
_WD_Option('Port', 9515)
_WD_Option('DriverParams', '--log-path=' & @ScriptDir & '\chrome.log')

$sDesiredCapabilities = '{"capabilities": {"alwaysMatch": {"chromeOptions": {"w3c": true }}}}'
EndFunc