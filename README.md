# Introduction
This UDF will allow you to interact with any browser that supports the [W3C WebDriver specifications](https://www.w3.org/TR/webdriver/). Supporting multiple browsers via the same code base is now possible with just a few configuration settings.

# Requirements
- [JSON UDF](https://www.autoitscript.com/forum/topic/148114-a-non-strict-json-udf-jsmn)
- [WinHTTP UDF](https://www.autoitscript.com/forum/topic/84133-winhttp-functions/)
- [HtmlTable2Array UDF](https://www.autoitscript.com/forum/topic/167679-read-data-from-html-tables-from-raw-html-source/) (optional)
- [WinHttp_WebSocket UDF](https://github.com/Danp2/autoit-websocket) (optional; needed for websocket CDP functionality)

- WebDriver for desired browser
	- Chrome	[[download](https://sites.google.com/chromium.org/driver/)]	[[status](https://chromium.googlesource.com/chromium/src/+/master/docs/chromedriver_status.md)]
	- FireFox	[[download](https://github.com/mozilla/geckodriver/releases)]	[[status](https://developer.mozilla.org/en-US/docs/Mozilla/QA/Marionette/WebDriver/status)]
	- Edge	[[download](https://developer.microsoft.com/en-us/microsoft-edge/tools/webdriver/)]	[[status](https://docs.microsoft.com/en-us/microsoft-edge/webdriver#w3c-webdriver-specification-supporthttpsw3cgithubiowebdriverwebdriver-spechtml)]
	- Opera	[[https://github.com/operasoftware/operachromiumdriver/releases)]	[[status](https://github.com/operasoftware/operachromiumdriver/releases)]


# Function List

### Core Functions

| Name              | Description                                               |
|-------------------|-----------------------------------------------------------|
| _WD_CreateSession | Request new session from web driver.                      |
| _WD_DeleteSession | Delete existing session.                                  |
| _WD_Status        | Get current web driver state.                             |
| _WD_GetSession    | Get details on existing session.                          |
| _WD_Timeouts      | Set or retrieve the session timeout parameters.           |
| _WD_Navigate      | Navigate to the designated URL.                           |
| _WD_Action        | Perform various interactions with the web driver session. |
| _WD_Window        | Perform interactions related to the current window.       |
| _WD_FindElement   | Find element(s) by designated strategy.                   |
| _WD_ElementAction | Perform action on desginated element.                     |
| _WD_ExecuteScript | Execute Javascipt commands.                               |
| _WD_Alert         | Respond to user prompt.                                   |
| _WD_GetSource     | Get page source.                                          |
| _WD_Cookies       | Gets, sets, or deletes the session's cookies.             |
| _WD_Option        | Sets and get options for the web driver UDF.              |
| _WD_Startup       | Launch the designated web driver console app.             |
| _WD_Shutdown      | Kill the web driver console app.                          |

### Helper Functions

| Name                    | Description                                                                |
|-------------------------|----------------------------------------------------------------------------|
| _WD_NewTab              | Create new tab in current browser session.                                 |
| _WD_Attach              | Attach to existing browser tab.                                            |
| _WD_LinkClickByText     | Simulate a mouse click on a link with text matching the provided string.   |
| _WD_WaitElement         | Wait for an element in the current tab before returning.                   |
| _WD_GetMouseElement     | Retrieves reference to element below mouse pointer.                        |
| _WD_GetElementFromPoint | Retrieves reference to element at specified point.                         |
| _WD_LastHTTPResult      | Return the result of the last WinHTTP request.                             |
| _WD_GetFrameCount       | Returns the number of frames/iframes in the current document context.      |
| _WD_IsWindowTop         | Returns a boolean of the session being at the top level, or in a frame(s). |
| _WD_FrameEnter          | Enter the specified frame.                                                 |
| _WD_FrameLeave          | Leave the current frame, to its parent.                                    |
| _WD_HighlightElement    | Highlights the specified element.                                          |
| _WD_HighlightElements   | Highlights the specified elements.                                         |
| _WD_LoadWait            | Wait for a browser page load to complete before returning.                 |
| _WD_Screenshot          | Takes a screenshot of the Window or Element.                               |
| _WD_PrintToPDF          | Print the current tab in paginated PDF format.                             |
| _WD_jQuerify            | Inject jQuery library into current session.                                |
| _WD_ElementOptionSelect | Find and click on an option from a Select element.                         |
| _WD_ElementSelectAction | Perform action on desginated Select element.                               |
| _WD_ConsoleVisible      | Control visibility of the webdriver console app.                           |
| _WD_GetShadowRoot       | Retrieves the shadow root of an element.                                   |
| _WD_SelectFiles         | Select files for uploading to a website.                                   |
| _WD_IsLatestRelease     | Compares local UDF version to latest release on Github.                    |
| _WD_UpdateDriver        | Replace web driver with newer version, if available.                       |
| _WD_GetBrowserVersion   | Get version number of specified browser.                                   |
| _WD_GetWebDriverVersion | Get version number of specifed webdriver.                                  |
| _WD_DownloadFile        | Download file and save to disk.                                            |
| _WD_SetTimeouts         | User friendly function to set webdriver session timeouts.                  |
| _WD_GetElementById      | Locate element by id.                                                      |
| _WD_GetElementByName    | Locate element by name.                                                    |
| _WD_SetElementValue     | Set value of designated element.                                           |
| _WD_ElementActionEx     | Perform advanced action on desginated element.                             |
| _WD_GetTable            | Return all elements of a table.                                            |
| _WD_IsFullScreen        | Return a boolean indicating if the session is in full screen mode.         |
| _WD_CheckContext        | Check if browser context is still valid.                                   |                                                                      |

### CDP functions

| Name                    | Description                                         |
|-------------------------|-----------------------------------------------------|
| _WD_CDPExecuteCommand   | Execute CDP command.                                |
| _WD_CDPGetSettings      | Retrieve CDP related settings from the browser.     |

### Capabilities functions

| Name                    | Description                      |
|-------------------------|----------------------------------|
| _WD_CapabilitiesStartup | Start new Capabilities build     |
| _WD_CapabilitiesAdd     | Add capablitities to JSON string |
| _WD_CapabilitiesGet     | Get the JSON string              |
| _WD_CapabilitiesDump    | Dump to console                  |
| _WD_CapabilitiesDisplay | Display the current content      |

## Source Code
You will always be able to find the latest version in the GitHub Repo  https://github.com/Danp2/WebDriver

## Additional Resources

### [Webdriver Wiki](https://www.autoitscript.com/wiki/WebDriver)

### Discussion Threads on Autoit Forums
- [WebDriver UDF Help & Support part 1](https://www.autoitscript.com/forum/topic/192730-webdriver-udf-help-support/)
- [WebDriver UDF Help & Support part 2](https://www.autoitscript.com/forum/topic/201106-webdriver-udf-help-support-ii/)
- [WebDriver UDF Help & Support part 3](https://www.autoitscript.com/forum/topic/205553-webdriver-udf-help-support-iii/)
