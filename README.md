# Introduction
This UDF will allow you to interact with any browser that supports the [W3C WebDriver specifications](https://w3c.github.io/webdriver/webdriver-spec.html#new-session). Supporting multiple browsers via the same code base is now possible with just a few configuration settings.

# Requirements
- JSON UDF https://www.autoitscript.com/forum/topic/148114-a-non-strict-json-udf-jsmn

- WebDriver for desired browser
	- Chrome WebDriver https://sites.google.com/a/chromium.org/chromedriver/downloads
	- FireFox WebDriver  https://github.com/mozilla/geckodriver/releases

# Function List	
- _WDStartup()
- _WDShutdown()
- _WDStatus()
- _WDCreateSession($sDesiredCapabilities='{}')
- _WDDeleteSession($sSession)
- _WDNavigate($sSession, $sURL)
- _WDAction($sSession, $sCommand)
- _WDWindow($sSession, $sCommand, $sOption)
- _WDFindElement($sSession, $sStrategy, $sSelector, $sStartElement = "", $lMultiple = False)
- _WDElementAction($sSession, $sElement, $sCommand, $sOption='')
- _WDExecuteScript($sSession, $sScript, $aArguments)
- _WDAlert($sSession, $sCommand)
- _WDGetSource($sSession)
- _WDCookies($sSession,  $sCommand, $sOption = '')
- _WDTimeouts($sSession, $sTimeouts = '')
- _WDOption($sOption, $vValue = "")

 
 # Source Code
 You will always be able to find the latest version in the GitHub Repo  https://github.com/Danp2/WebDriver
