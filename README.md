# Introduction
This UDF will allow you to interact with any browser that supports the [W3C WebDriver specifications](https://www.w3.org/TR/webdriver/). Supporting multiple browsers via the same code base is now possible with just a few configuration settings.

# Requirements
- JSON UDF https://www.autoitscript.com/forum/topic/148114-a-non-strict-json-udf-jsmn
- WinHTTP UDF https://www.autoitscript.com/forum/topic/84133-winhttp-functions/

- WebDriver for desired browser
	- Chrome	[[download](https://sites.google.com/a/chromium.org/chromedriver/downloads)]	[[status](https://chromium.googlesource.com/chromium/src/+/master/docs/chromedriver_status.md)]
	- FireFox	[[download](https://github.com/mozilla/geckodriver/releases)]	[[status](https://developer.mozilla.org/en-US/docs/Mozilla/QA/Marionette/WebDriver/status)]
	- Edge	[[download](https://developer.microsoft.com/en-us/microsoft-edge/tools/webdriver/)]	[[status](https://docs.microsoft.com/en-us/microsoft-edge/webdriver#w3c-webdriver-specification-supporthttpsw3cgithubiowebdriverwebdriver-spechtml)]


# Function List

## Core Functions

- _WD_CreateSession($sDesiredCapabilities='{}')
- _WD_DeleteSession($sSession)
- _WD_Status()
- _WD_Timeouts($sSession, $sTimeouts = '')
- _WD_Navigate($sSession, $sURL)
- _WD_Action($sSession, $sCommand)
- _WD_Window($sSession, $sCommand, $sOption = '')
- _WD_FindElement($sSession, $sStrategy, $sSelector, $sStartElement = "", $lMultiple = False)
- _WD_ElementAction($sSession, $sElement, $sCommand, $sOption='')
- _WD_ExecuteScript($sSession, $sScript, $sArguments="[]")
- _WD_Alert($sSession, $sCommand, $sOption = '')
- _WD_GetSource($sSession)
- _WD_Cookies($sSession,  $sCommand, $sOption = '')
- _WD_Option($sOption, $vValue = "")
- _WD_Startup()
- _WD_Shutdown()

## Helper Functions

- _WD_NewTab($sSession, $lSwitch = True, $iTimeout = -1, $sURL = "", $sFeatures = "")
- _WD_Attach($sSession, $sString, $sMode = 'title')
- _WD_LinkClickByText($sSession, $sText, $lPartial = True)
- _WD_WaitElement($sSession, $sElement, $sStrategy, $sSelector[, $iDelay = 0[, $iTimeout = -1]])
- _WD_GetMouseElement($sSession)
- _WD_GetElementFromPoint($sSession, $iX, $iY)
- _WD_LastHTTPResult()
- _WD_GetFrameCount()
- _WD_IsWindowTop()
- _WD_FrameEnter($sIndexOrID)
- _WD_FrameLeave()
- _WD_HighlightElement($sSession, $sElement[, $iMethod = 1])
- _WD_HighlightElements($sSession, $aElements[, $iMethod = 1])
- _WD_jQuerify($sSession)
- WD_ElementOptionSelect($sSession, $sStrategy, $sSelector, $sStartElement = "")

# Source Code
You will always be able to find the latest version in the GitHub Repo  https://github.com/Danp2/WebDriver


# Discussion Thread on Autoit Forums
https://www.autoitscript.com/forum/topic/191990-webdriver-udf-w3c-compliant-version
