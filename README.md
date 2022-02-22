#####

<p align="center">
    <img src="images/icon.png" width="176" />
    <h2 align="center">Welcome to <code>au3WebDriver</code></h2>
</p>

[![license](https://img.shields.io/badge/license-MIT-ff69b4.svg?style=flat-square&logo=spdx)](https://github.com/Danp2/au3WebDriver/blob/master/LICENSE)
[![contributors](https://img.shields.io/github/contributors/Danp2/au3WebDriver.svg?style=flat-square&logo=github)](https://github.com/Danp2/au3WebDriver/graphs/contributors)
![repo size](https://img.shields.io/github/repo-size/Danp2/au3WebDriver.svg?style=flat-square&logo=github)
[![last commit](https://img.shields.io/github/last-commit/Danp2/au3WebDriver.svg?style=flat-square&logo=github)](https://github.com/Danp2/au3WebDriver/commits/master)
[![release](https://img.shields.io/github/release/Danp2/au3WebDriver.svg?style=flat-square&logo=github)](https://github.com/Danp2/au3WebDriver/releases/latest)
![os](https://img.shields.io/badge/os-windows-yellow.svg?style=flat-square&logo=windows)
![stars](https://img.shields.io/github/stars/Danp2/au3WebDriver?color=blueviolet&logo=reverbnation&logoColor=white&style=flat-square)

[Description](#description) | [Documentation](#documentation) | [Features](#features) | [Getting started](#getting-started) | [Configuration](#configuration) | [Contributing](#contributing) | [License](#license) | [Acknowledgements](#acknowledgements)

## Description

This au3WebDriver UDF (project) allows to interact with any browser that supports the [W3C WebDriver specifications](https://www.w3.org/TR/webdriver/).  Supporting multiple browsers via the same code base is now possible with just a few configuration settings.

## Documentation

|                                                                                                                      | Reference                                                     | Description                                                                                            |
| :---:                                                                                                                | :---                                                          | :---                                                                                                   |
| <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/W3C_icon.svg/212px-W3C_icon.svg.png" width="20"> | [W3C WebDriver](https://www.w3.org/TR/webdriver/)             | Official W3C WebDriver standard/specification.                                                         |
| 📚                                                                                                                   | [WebDriver Wiki](https://www.autoitscript.com/wiki/WebDriver) | Further information about this UDF (project) like big picture, capabilities, troubleshooting and more. |
| 📖                                                                                                                   | Webdriver.chm                                                 | Function CHM help file that comes with this UDF (project) download.                                    |

## Features

### *Browser support*

| Chrome                                                                                            | Edge                                                                                        | Firefox                                                                                              |
| :---                                                                                              | :---                                                                                        | :---                                                                                                 |
| ![Chrome48] | ![Edge48] | ![Firefox48] |


### *Functions*

<details>
<summary><i>Core Functions</i></summary>
<p>

| Name              | Description                                               |
| :---              | :---                                                      |
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

<p>
</details>

<details>
<summary><i>Helper Functions</i></summary>
<p>

| Name                    | Description                                                                |
| :---                    | :---                                                                       |
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
| _WD_GetDevicePixelRatio | Returns an integer indicating the DevicePixelRatio.                        |
| _WD_CheckContext        | Check if browser context is still valid.                                   |
| _WD_JsonActionKey       | Formats keyboard "action" strings for use in _WD_Action                    |
| _WD_JsonActionPointer   | Formats pointer "action" strings for use in _WD_Action                     |
| _WD_JsonActionPause     | Formats pause "action" strings for use in _WD_Action                       |
| _WD_JsonCookie          | Formats "cookie" JSON strings for use in _WD_Cookies.                      |

<p>
</details>

<details>
<summary><i>CDP Functions</i></summary>
<p>

| Name                  | Description                                     |
| :---                  | :---                                            |
| _WD_CDPExecuteCommand | Execute CDP command.                            |
| _WD_CDPGetSettings    | Retrieve CDP related settings from the browser. |

<p>
</details>

<details>
<summary><i>Capabilities Functions</i></summary>
<p>

| Name                    | Description                      |
| :---                    | :---                             |
| _WD_CapabilitiesStartup | Start new Capabilities build     |
| _WD_CapabilitiesAdd     | Add capablitities to JSON string |
| _WD_CapabilitiesGet     | Get the JSON string              |
| _WD_CapabilitiesDump    | Dump to console                  |
| _WD_CapabilitiesDisplay | Display the current content      |

<p>
</details>

## Getting started

#### *Preconditions*

Download and add the following mandatory Third-Party UDFs to your project folder (independent of the browser you want to automate).

- Mandatory ✔
  - [Json UDF](https://www.autoitscript.com/forum/topic/148114-a-non-strict-json-udf-jsmn) - Archive includes *Json.au3* & *BinaryCall.au3*.
  - [WinHTTP UDF](https://github.com/dragana-r/autoit-winhttp/releases/latest) - Archive includes *WinHttp.au3* & *WinHttpConstants.au3*.
- Optional ⚠
  - [HtmlTable2Array UDF](https://www.autoitscript.com/forum/topic/167679-read-data-from-html-tables-from-raw-html-source/) - Extraction of data from HTML tables to an array.
  - [WinHttp_WebSocket UDF](https://github.com/Danp2/autoit-websocket) - Needed for websocket CDP functionality.

Download and install one of the following WebDriver (depending on the browser type and version you want to automate).

| Browser                                                                                              | Download                                                                      | WebDriver specification status                                                                                   |
| :---:                                                                                                | :---                                                                          | :---                                                                                                             |
| ![Chrome16]    | [Chrome](https://sites.google.com/chromium.org/driver/downloads)              | [Status](https://chromium.googlesource.com/chromium/src/+/master/docs/chromedriver_status.md)                    |
| ![Edge16]          | [Edge](https://developer.microsoft.com/en-us/microsoft-edge/tools/webdriver/) | [Status](https://chromium.googlesource.com/chromium/src/+/master/docs/chromedriver_status.md) [^1] |
| ![Firefox16] | [Firefox](https://github.com/mozilla/geckodriver/releases/latest)             | [Status](https://developer.mozilla.org/en-US/docs/Mozilla/QA/Marionette/WebDriver/status) [^2]                                  |

Limitation notice. [^3]

[^1]: "Microsoft Edge" (is chromium based) which means it's a WebDriver implementation derived from ChromeDriver. The status or limitations are at least the same as for ChromeDriver.
[^2]: Login Required
[^3]: Not all WebDriver functions have been implemented by each browser. Keep that in mind and check the "WebDriver specification status" for your desired WebDriver of choice.

#### *Installation*

To automate your browser, follow the following steps.

1. Download at least the mandatory [Third-Party UDFs](#preconditions).
2. Move the UDFs to your project folder or to a directory where AutoIt can find them.
    - All *wd_\*.au3* files and the Third-Party UDFs *\*.au3* should be placed in the same directory.
    - Otherwise you have to adjust the `#include` statements in the files.
3. Move your desired WebDriver of choice to directory of the *wd_\*.au3* files.
    - chromedriver.exe (Chrome)
    - geckodriver.exe (Firefox)
    - msedgedriver.exe (Edge, chromium based)

#### *Usage*

Run [wd_demo.au3](https://github.com/Danp2/au3WebDriver/blob/master/wd_demo.au3), choose your "Browser" from the dropdown and press the "Run Demo!" button that will perform the "DemoNavigation" demo to validate your installation.

<details>
<summary><i>Result example</i></summary>

In case you use Firefox, the result should look similar to this:

``` log
1577745813519   geckodriver     DEBUG   Listening on 127.0.0.1:4444
1577745813744   webdriver::server       DEBUG   -> POST /session {"capabilities": {"alwaysMatch": {"browserName": "firefox", "acceptInsecureCerts":true}}}
1577745813746   geckodriver::capabilities       DEBUG   Trying to read firefox version from ini files
1577745813747   geckodriver::capabilities       DEBUG   Found version 71.0
1577745813757   mozrunner::runner       INFO    Running command: "C:\\Program Files\\Mozilla Firefox\\firefox.exe" "-marionette" "-foreground" "-no-remote" "-profile" "C:\\ ...
1577745813783   geckodriver::marionette DEBUG   Waiting 60s to connect to browser on 127.0.0.1:55184
1577745817392   geckodriver::marionette DEBUG   Connection to Marionette established on 127.0.0.1:55184.
1577745817464   webdriver::server       DEBUG   <- 200 OK {"value":{"sessionId":"925641bf-6c5d-4fe2-a985-02de9b1c7c74","capabilities":"acceptInsecureCerts":true,"browserName":"firefox", ...
```

</details>

More useful information following soon.

## Configuration

Useful information about possible configurations following soon.<br>

## Contributing

Just look at [CONTRIBUTING](https://github.com/Danp2/au3WebDriver/blob/master/docs/CONTRIBUTING.md), thank you!

## License

Distributed under the MIT License. See [LICENSE](https://github.com/Danp2/au3WebDriver/blob/master/LICENSE) for more information.

## Acknowledgements

- Opportunity by [GitHub](https://github.com)
- Badges by [Shields](https://shields.io)
- Thanks to the authors of the Third-Party UDFs
  - *Json UDF* by @Ward and @Jos
  - *WinHTTP UDF* by @trancexx/[@dragana-r](https://github.com/dragana-r)
  - *HtmlTable2Array UDF* by @Chimp
  - *WinHttp_WebSocket UDF* by @Danp2
- Thanks to the maintainers
  - Thanks to [@Danp2](https://github.com/Danp2) for the project idea, creation and maintenance
  - Thanks to [@mLipok](https://github.com/mLipok) for his *wd_capabilities.au3*
  - Thanks to [@Sven-Seyfert](https://github.com/Sven-Seyfert) for the project logo
  - **Big thanks** to all the hard-working [contributors](https://github.com/Danp2/au3WebDriver/graphs/contributors)

##

[To the top](#)

[Chrome48]: https://raw.githubusercontent.com/alrra/browser-logos/main/src/chrome/chrome_48x48.png
[Chrome16]: https://raw.githubusercontent.com/alrra/browser-logos/main/src/chrome/chrome_16x16.png
[Edge48]: https://raw.githubusercontent.com/alrra/browser-logos/main/src/edge/edge_48x48.png
[Edge16]: https://raw.githubusercontent.com/alrra/browser-logos/main/src/edge/edge_16x16.png
[Firefox48]: https://raw.githubusercontent.com/alrra/browser-logos/main/src/firefox/firefox_48x48.png
[Firefox16]: https://raw.githubusercontent.com/alrra/browser-logos/main/src/firefox/firefox_16x16.png