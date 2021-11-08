# Introduction
This UDF will allow you to interact with any browser that supports the [W3C WebDriver specifications](https://www.w3.org/TR/webdriver/). Supporting multiple browsers via the same code base is now possible with just a few configuration settings.

# Requirements
- [JSON UDF](https://www.autoitscript.com/forum/topic/148114-a-non-strict-json-udf-jsmn)
- [WinHTTP UDF](https://www.autoitscript.com/forum/topic/84133-winhttp-functions/)
- [HtmlTable2Array UDF](https://www.autoitscript.com/forum/topic/167679-read-data-from-html-tables-from-raw-html-source/) (optional)
- [WinHttp_WebSocket UDF](https://github.com/Danp2/autoit-websocket) (optional; needed for websocket CDP functionality)

- WebDriver for desired browser
	- Chrome	[[download](https://sites.google.com/a/chromium.org/chromedriver/downloads)]	[[status](https://chromium.googlesource.com/chromium/src/+/master/docs/chromedriver_status.md)]
	- FireFox	[[download](https://github.com/mozilla/geckodriver/releases)]	[[status](https://developer.mozilla.org/en-US/docs/Mozilla/QA/Marionette/WebDriver/status)]
	- Edge	[[download](https://developer.microsoft.com/en-us/microsoft-edge/tools/webdriver/)]	[[status](https://docs.microsoft.com/en-us/microsoft-edge/webdriver#w3c-webdriver-specification-supporthttpsw3cgithubiowebdriverwebdriver-spechtml)]


# Function List

## Core Functions

- _WD_Action($sSession, $sCommand, $sOption = Default)
- _WD_Alert($sSession, $sCommand, $sOption = Default)
- _WD_Cookies($sSession, $sCommand, $sOption = Default)
- _WD_CreateSession($sDesiredCapabilities = Default)
- _WD_DeleteSession($sSession)
- _WD_ElementAction($sSession, $sElement, $sCommand, $sOption = Default)
- _WD_ExecuteScript($sSession, $sScript, $sArguments = Default, $bAsync = Default)
- _WD_FindElement($sSession, $sStrategy, $sSelector, $sStartNodeID = Default, $bMultiple = Default, $bShadowRoot = Default)
- _WD_GetSession($sSession)
- _WD_GetSource($sSession)
- _WD_Navigate($sSession, $sURL)
- _WD_Option($sOption, $vValue = Default)
- _WD_Shutdown($vDriver = Default)
- _WD_Startup()
- _WD_Status()
- _WD_Timeouts($sSession, $sTimeouts = Default)
- _WD_Window($sSession, $sCommand, $sOption = Default)

## Helper Functions

- _WD_Attach($sSession, $sString, $sMode = Default)
- _WD_ConsoleVisible($bVisible = Default)
- _WD_DownloadFile($sURL, $sDest, $iOptions = Default)
- _WD_ElementActionEx($sSession, $sElement, $sCommand, $iXOffset = Default, $iYOffset = Default, $iButton = Default, $iHoldDelay = Default, $sModifier = Default)
- _WD_ElementOptionSelect($sSession, $sStrategy, $sSelector, $sStartElement = Default)
- _WD_ElementSelectAction($sSession, $sSelectElement, $sCommand)
- _WD_FrameEnter($sSession, $vIdentifier)
- _WD_FrameLeave($sSession)
- _WD_GetMouseElement($sSession)
- _WD_GetElementFromPoint($sSession, $iX, $iY)
- _WD_GetBrowserVersion($sBrowser)
- _WD_GetWebDriverVersion($sInstallDir, $sDriverEXE)
- _WD_GetElementById($sSession, $sID)
- _WD_GetElementByName($sSession, $sName)
- _WD_GetTable($sSession, $sBaseElement)
- _WD_GetFrameCount($sSession)
- _WD_GetShadowRoot($sSession, $sStrategy, $sSelector, $sStartElement = Default)
- _WD_HighlightElement($sSession, $sElement, $iMethod = Default)
- _WD_HighlightElements($sSession, $aElements, $iMethod = Default)
- _WD_IsFullScreen($sSession)
- _WD_IsLatestRelease()
- _WD_IsWindowTop($sSession)
- _WD_jQuerify($sSession, $sjQueryFile = Default, $iTimeout = Default)
- _WD_LastHTTPResult()
- _WD_LinkClickByText($sSession, $sText, $bPartial = Default)
- _WD_LoadWait($sSession, $iDelay = Default, $iTimeout = Default, $sElement = Default)
- _WD_NewTab($sSession, $bSwitch = Default, $iTimeout = Default, $sURL = Default, $sFeatures = Default)
- _WD_PrintToPDF($sSession, $sOptions = Default)
- _WD_Screenshot($sSession, $sElement = Default, $nOutputType = Default)
- _WD_SelectFiles($sSession, $sStrategy, $sSelector, $sFilename)
- _WD_SetTimeouts($sSession, $iPageLoad = Default, $iScript = Default, $iImplicitWait = Default)
- _WD_SetElementValue($sSession, $sElement, $sValue, $iStyle = Default)
- _WD_UpdateDriver($sBrowser, $sInstallDir = Default, $bFlag64 = Default, $bForce = Default)
- _WD_WaitElement($sSession, $sStrategy, $sSelector, $iDelay = Default, $iTimeout = Default, $iOptions = Default)

## CDP functions

- _WD_CDPExecuteCommand($sSession, $sCommand, $oParams, $sWebSocketURL = Default)
- _WD_CDPGetSettings($sSession, $sOption)

## Source Code
You will always be able to find the latest version in the GitHub Repo  https://github.com/Danp2/WebDriver

## Additional Resources
### [Webdriver Wiki](https://www.autoitscript.com/wiki/WebDriver)

### Discussion Threads on Autoit Forums
- [WebDriver UDF Help & Support part 1](https://www.autoitscript.com/forum/topic/192730-webdriver-udf-help-support/)
- [WebDriver UDF Help & Support part 2](https://www.autoitscript.com/forum/topic/201106-webdriver-udf-help-support-ii/)
- [WebDriver UDF Help & Support part 3](https://www.autoitscript.com/forum/topic/205553-webdriver-udf-help-support-iii/)
