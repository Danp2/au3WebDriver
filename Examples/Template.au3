; this is template for creating examples
#include "..\wd_helper.au3"
#include "StartUp.au3"

Example(False)

Func Example($b_Headless)
	Local $sSession = _WDEx_SetupWrapper('firefox', $_WD_DEBUG_Info, $b_Headless)
	If @error Then Return SetError(@error, @extended, $sSession)

	Local $sURL = "https://google.com"
	Local $sXpath = '//body/div[1][@aria-hidden="true"]'
	_WDEx_NavigateCheckBanner($sSession, $sURL, $sXpath)

	; here example should start

EndFunc   ;==>Example
