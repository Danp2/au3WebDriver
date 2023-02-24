
_WD_Navigate($sSession, 'https://www.google.com')
_WD_LoadWait($sSession)

ConsoleWrite("- Test 1:" & @CRLF)
_WD_NewTab($sSession, False, Default, "https://www.chrome.com", "noreferrer")
_WD_LoadWait($sSession, 1000)
_WD_Attach($sSession, "Chrome")
_WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//input[@title='Search']")

ConsoleWrite("- Test 2:" & @CRLF)
_WD_WaitElement($sSession, $_WD_LOCATOR_ByCSSSelector, '#fake', 1000, 3000, $_WD_OPTION_NoMatch)
