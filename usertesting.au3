; The contents of this file are read & executed by the UserFile function in wd_demo.au3
;
; Changes can be made to this file and quickly tested without having to exit and 
; relaunch wd_demo.au3
ConsoleWrite("! Code now executing from usertesting.au3" & @CRLF)

_WD_Navigate($sSession, 'https://www.google.com')
_WD_LoadWait($sSession)

ConsoleWrite("- Test 1:" & @CRLF)
_WD_NewTab($sSession, False, Default, "https://www.chrome.com", "noreferrer")
_WD_Attach($sSession, "Chrome")
_WD_LoadWait($sSession, 1000)
_WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//input[@title='Search']")

ConsoleWrite("- Test 2:" & @CRLF)
_WD_WaitElement($sSession, $_WD_LOCATOR_ByCSSSelector, '#fake', 1000, 3000, $_WD_OPTION_NoMatch)