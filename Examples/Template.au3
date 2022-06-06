; this is template for creating examples
#include "StartUp.au3"

Example()

Func Example()
	Local $sSession = _WDEx_SetupWrapper('firefox')
	If @error Then Return SetError(@error, @extended, $sSession)

	Local $sURL = "https://google.com"
	Local $sXpath = '//body/div[1][@aria-hidden="true"]'
	_WDEx_NavigateCheckBanner($sSession, $sURL, $sXpath)

	; here example should start

EndFunc   ;==>Example
