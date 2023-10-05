; The contents of this file are read & executed by the UserFile() function in wd_demo.au3
; Changes can be made to this file and quickly tested without having to exit or even close browser
ConsoleWrite("! Code now executing from usertesting.au3" & @CRLF)

ConsoleWrite("- Test 1:" & @CRLF)
_WD_NewTab($sSession, False, Default, "https://www.chrome.com", "noreferrer")
_WD_Attach($sSession, "Chrome")
_WD_LoadWait($sSession, 1000)

ConsoleWrite("- Test 2:" & @CRLF)
_WD_NewTab($sSession, True)
_WD_Navigate($sSession, 'https://www.google.com')
_WD_LoadWait($sSession)
MsgBox($MB_OK + $MB_TOPMOST + $MB_ICONWARNING, "Warning #" & @ScriptLineNumber, "If you see COOKIE accept panel close them before you will continue.")

ConsoleWrite("- Test 3:" & @CRLF)
; REMARK:  __SetVAR($IDX_VAR, $value) will set  $_VAR[$IDX_VAR] = $value
__SetVAR(0, _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//textarea[@name='q']"))

ConsoleWrite("- Test 4:" & @CRLF)
_WD_ElementAction($sSession, $_VAR[0], "VALUE", 'AutoIt Forum')

ConsoleWrite("- Test 5:" & @CRLF)
_WD_WaitElement($sSession, $_WD_LOCATOR_ByCSSSelector, '#fake', 1000, 3000, $_WD_OPTION_NoMatch)

ConsoleWrite("! End of processing usertesting.au3" & @CRLF)
