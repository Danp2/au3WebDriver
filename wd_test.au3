#AutoIt3Wrapper_Version=B
#include "webdriver.au3"

Local Enum $eFireFox = 0, _
			$eChrome

Local $aTestSuite[5][2] = [["TestTimeouts", True], ["TestNavigation", True], ["TestElements", True], ["TestScript", True], ["TestCookies", True]]

Local Const $_TestType = $eChrome
Local $sDesiredCapabilities
Local $iIndex

$_WD_DEBUG = True

Switch $_TestType
	Case $eFireFox
		SetupGecko()

	Case $eChrome
		SetupChrome()

EndSwitch

_WDStartup()

$sSession = _WDCreateSession($sDesiredCapabilities)
$sStatus = _WDStatus()

For $iIndex = 0 To UBound($aTestSuite, $UBOUND_ROWS) - 1
	If $aTestSuite[$iIndex][1] Then
		ConsoleWrite("Running: " & $aTestSuite[$iIndex][0] & @CRLF)
		Call($aTestSuite[$iIndex][0])
	Else
		ConsoleWrite("Bypass: " & $aTestSuite[$iIndex][0] & @CRLF)
	EndIf
Next

Exit

_WDDeleteSession($sSession)
_WDShutdown()



Func TestTimeouts()
	_WDTimeouts($sSession)
	_WDTimeouts($sSession, '{"script":10000,"pageLoad":200000,"implicit":30}')
	_WDTimeouts($sSession)
EndFunc

Func TestNavigation()
	_WDNavigate($sSession, "http://google.com")
	ConsoleWrite("URL=" & _WDAction($sSession, 'url') & @CRLF)
	_WDAction($sSession, "back")
	ConsoleWrite("URL=" & _WDAction($sSession, 'url') & @CRLF)
	_WDAction($sSession, "forward")
	ConsoleWrite("URL=" & _WDAction($sSession, 'url') & @CRLF)
	ConsoleWrite("Title=" & _WDAction($sSession, 'title') & @CRLF)
EndFunc

;_WDWindow($sSession, 'frame', '{"id":null}')

Func TestElements()
	_WDNavigate($sSession, "http://google.com")
	$sElement = _WDFindElement($sSession, $_WD_LOCATOR_ByXPath, "//input[@id='lst-ib1']")

	If @error = $_WD_ERROR_NoMatch Then
		$sElement = _WDFindElement($sSession, $_WD_LOCATOR_ByXPath, "//input[@id='lst-ib']")
	EndIf

	$sElement2 = _WDFindElement($sSession, $_WD_LOCATOR_ByXPath, "//div/input", '', True)

	;ConsoleWrite("$selement = " & $selement & @CRLF)

	_WDElementAction($sSession, $sElement, 'value', "testing 123")
	_WDElementAction($sSession, $sElement, 'text')
	_WDElementAction($sSession, $sElement, 'clear')
	_WDElementAction($sSession, $sElement, 'value', "abc xyz")
	_WDElementAction($sSession, $sElement, 'text')
	_WDElementAction($sSession, $sElement, 'clear')
	_WDElementAction($sSession, $sElement, 'value', "fujimo")
	_WDElementAction($sSession, $sElement, 'text')
	_WDElementAction($sSession, $sElement, 'click')

	_WDElementAction($sSession, $sElement, 'Attribute', 'test')

	$sElement = _WDFindElement($sSession, $_WD_LOCATOR_ByXPath, "//input[@id='lst-ib']")
	$sValue = _WDElementAction($sSession, $sElement, 'property', 'value')

	ConsoleWrite('value = ' & $sValue & @CRLF)
EndFunc

Func TestScript()
	_WDExecuteScript($sSession, 'alert()', "")
	_WDAlert($sSession, 'Dismiss')
EndFunc

Func TestCookies()
	_WDNavigate($sSession, "http://google.com")
	_WDCookies($sSession, 'Get', 'NID')
	_WDCookies($sSession, 'Delete', 'NID1')
EndFunc


Func SetupGecko()
_WDOption('Driver', 'geckodriver.exe')
_WDOption('DriverParams', '--log trace')
;_WDOption('DriverParams', "--connect-existing --marionette-port 2828")
_WDOption('Port', 4444)

$sDesiredCapabilities = '{"desiredCapabilities":{"javascriptEnabled":true,"nativeEvents":true,"acceptInsecureCerts":true}}'
EndFunc



Func SetupChrome()
_WDOption('Driver', 'chromedriver.exe')
_WDOption('Port', 9515)
_WDOption('DriverParams', '--log-path=' & @ScriptDir & '\chrome.log')

$sDesiredCapabilities = '{"capabilities": {"alwaysMatch": {"chromeOptions": {"w3c": true }}}}'
EndFunc

