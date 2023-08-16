#####

<p align="center">
    <img src="images/icon.png" width="176" />
    <h2 align="center">Welcome to <code>au3WebDriver</code></h2>
</p>

[![license](https://img.shields.io/badge/license-MIT-ff69b4.svg?style=flat-square&logo=spdx)][license]
[![contributors](https://img.shields.io/github/contributors/Danp2/au3WebDriver.svg?style=flat-square&logo=github)][Contributors]
![repo size](https://img.shields.io/github/repo-size/Danp2/au3WebDriver.svg?style=flat-square&logo=github)
[![last commit](https://img.shields.io/github/last-commit/Danp2/au3WebDriver.svg?style=flat-square&logo=github)](https://github.com/Danp2/au3WebDriver/commits/master)
[![release](https://img.shields.io/github/release/Danp2/au3WebDriver.svg?style=flat-square&logo=github)](https://github.com/Danp2/au3WebDriver/releases/latest)
![os](https://img.shields.io/badge/os-windows-yellow.svg?style=flat-square&logo=windows)
![stars](https://img.shields.io/github/stars/Danp2/au3WebDriver?color=blueviolet&logo=reverbnation&logoColor=white&style=flat-square)

[Description](#description) | [Documentation](#documentation) | [Features](#features) | [Getting started](#getting-started) | [Configuration](#configuration) | [Contributing](#contributing) | [License](#license) | [Acknowledgements](#acknowledgements)

## Description

This au3WebDriver UDF (project) allows to interact with any browser that supports the [W3C WebDriver specifications][W3C Webdriver].  Supporting multiple browsers via the same code base is now possible with just a few configuration settings.

## Documentation

|                                                                                                                      | Reference                                                     | Description                                                                                            |
| :---:                                                                                                                | :---                                                          | :---                                                                                                   |
| <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/W3C_icon.svg/212px-W3C_icon.svg.png" width="20"> | [W3C WebDriver]             | Official W3C WebDriver standard/specification.                                                         |
| 📚                                                                                                                   | [WebDriver Wiki] | Further information about this UDF (project) like big picture, capabilities, troubleshooting and more. |
| 📖                                                                                                                   | au3WebDriver.chm                                              | Help file that comes with this UDF (project) download.                                    |
| 📙                                                                                                                   | [Change Log]                                              | Record of all notable changes to the project                                |

## Features

### *Browser support*

| Chrome      | Edge    | Firefox        | Opera      |
|-------------|---------|----------------|------------|
| ![Chrome48] | ![Edge48] | ![Firefox48] | ![Opera48] |

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
| _WD_ElementAction | Perform action on designated element.                     |
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

| Name                    | Description                                                                     |
|-------------------------|---------------------------------------------------------------------------------|
| _WD_Attach              | Attach to existing browser tab.                                                 |
| _WD_CheckContext        | Check if browser context is still valid.                                        |
| _WD_ConsoleVisible      | Control visibility of the webdriver console app.                                |
| _WD_DebugSwitch         | Switch to new debug level or switch back to saved debug level.                  |
| _WD_DispatchEvent       | Create and dispatch events.                                                     |
| _WD_DownloadFile        | Download file and save to disk.                                                 |
| _WD_ElementActionEx     | Perform advanced action on designated element.                                  |
| _WD_ElementOptionSelect | Find and click on an option from a Select element.                              |
| _WD_ElementSelectAction | Perform action on designated Select element.                                    |
| _WD_ElementStyle        | Set/Get element style property.                                                 |
| _WD_FrameEnter          | Enter the specified frame.                                                      |
| _WD_FrameLeave          | Leave the current frame, to its parent.                                         |
| _WD_FrameList           | Retrieves a detailed list of the main document and all associated frames.       |
| _WD_FrameListFindElement| Search the current document and return locations of matching elements.          |
| _WD_GetBrowserPath      | Retrieve path to browser executable from registry.                              |
| _WD_GetBrowserVersion   | Get version number of specified browser.                                        |
| _WD_GetContext          | Retrieve the element ID of the current browsing context.                        |
| _WD_GetDevicePixelRatio | Returns an integer indicating the DevicePixelRatio.                             |
| _WD_GetElementById      | Locate element by id.                                                           |
| _WD_GetElementByName    | Locate element by name.                                                         |
| _WD_GetElementByRegEx   | Find element by matching attributes values using Javascript regular expression. |
| _WD_GetElementFromPoint | Retrieves reference to element at specified point.                              |
| _WD_GetFrameCount       | Returns the number of frames/iframes in the current document context.           |
| _WD_GetFreePort         | Locate and return an available TCP port within a defined range.                 |
| _WD_GetMouseElement     | Retrieves reference to element below mouse pointer.                             |
| _WD_GetShadowRoot       | Retrieves the shadow root of an element.                                        |
| _WD_GetTable            | Return all elements of a table.                                                 |
| _WD_GetWebDriverVersion | Get version number of specifed webdriver.                                       |
| _WD_HighlightElements   | Highlights the specified elements.                                              |
| _WD_IsFullScreen        | Return a boolean indicating if the session is in full screen mode.              |
| _WD_IsLatestRelease     | Compares local UDF version to latest release on Github.                         |
| _WD_IsWindowTop         | Returns a boolean of the session being at the top level, or in a frame(s).      |
| _WD_JsonActionKey       | Formats keyboard "action" strings for use in _WD_Action                         |
| _WD_JsonActionPause     | Formats pause "action" strings for use in _WD_Action                            |
| _WD_JsonActionPointer   | Formats pointer "action" strings for use in _WD_Action                          |
| _WD_JsonCookie          | Formats "cookie" JSON strings for use in _WD_Cookies.                           |
| _WD_LastHTTPResponse    | Return the response of the last WinHTTP request.                                |
| _WD_LastHTTPResult      | Return the result of the last WinHTTP request.                                  |
| _WD_LinkClickByText     | Simulate a mouse click on a link with text matching the provided string.        |
| _WD_LoadWait            | Wait for a browser page load to complete before returning.                      |
| _WD_NewTab              | Create new tab in current browser session.                                      |
| _WD_PrintToPDF          | Print the current tab in paginated PDF format.                                  |
| _WD_Screenshot          | Takes a screenshot of the Window or Element.                                    |
| _WD_SelectFiles         | Select files for uploading to a website.                                        |
| _WD_SetElementValue     | Set value of designated element.                                                |
| _WD_SetTimeouts         | User friendly function to set webdriver session timeouts.                       |
| _WD_Storage             | Provide access to the browser's localStorage and sessionStorage objects.        |
| _WD_UpdateDriver        | Replace web driver with newer version, if available.                            |
| _WD_WaitElement         | Wait for an element in the current tab before returning.                        |
| _WD_WaitScript          | Wait for a JavaScript snippet to return true.                                   |
| _WD_jQuerify            | Inject jQuery library into current session.                                     |

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
| _WD_CapabilitiesDefine  | Define a new capability by selecting a type and specifying a name      |

<p>
</details>

## Getting started

#### *Preconditions*

Download and add the following mandatory Third-Party UDFs to your project folder (independent of the browser you want to automate).

- Mandatory ✔
  - [Json UDF] - Archive includes *Json.au3* & *BinaryCall.au3*.
  - [WinHTTP UDF] - Archive includes *WinHttp.au3* & *WinHttpConstants.au3*.
- Optional ⚠
  - [WinHttp_WebSocket UDF] - Needed for websocket CDP functionality.

Download and install one of the following WebDrivers (depending on the browser type and version you want to automate).

|    Browser   | Download             | Implementation status        |
|:------------:|----------------------|------------------------------|
|  ![Chrome16] | [Chrome][ChromeDL]   | [Status][ChromeStatus]       |
|   ![Edge16]  | [Edge][EdgeDL]       | [Status][EdgeStatus]         |
| ![Firefox16] | [Firefox][FirefoxDL] | [Status][FirefoxStatus] [^1] |
|  ![Opera16]  | [Opera][OperaDL]     | [^2]                         |

Limitation notice. [^3]

[^1]: Login Required
[^2]: Derived from ChromeDriver per project [ReadMe][Opera ReadMe]
[^3]: Not all WebDriver functions have been fully implemented by each browser. Keep that in mind and check the "Implementation status" for your desired WebDriver of choice.

#### *Installation*

To automate your browser, follow the following steps.

1. Download at least the mandatory [Third-Party UDFs](#preconditions).
2. Move the UDFs to your project folder or to a directory where AutoIt can find them.
    - All *wd_\*.au3* files and the Third-Party UDFs *\*.au3* should be placed in the same directory.
    - Otherwise you have to adjust the `#include` statements in the files.
3. Move your desired WebDriver of choice to the directory containing the *wd_\*.au3* files.

#### *Usage*

Run `wd_demo.au3`, choose your "Browser" from the dropdown and press the "Run Demo!" button that will perform the "DemoNavigation" demo to validate your installation.

## Configuration

Useful information about possible configurations following soon.<br>

#### Github Integration

To ensure your GitHub project always has the latest version of the UDF --

1. Open your prefered shell (cmd, powershell, bash, zsh)
2. Navigate to your GitHub Autoit repository
3. Run `git submodule add https://github.com/Danp2/au3WebDriver`
4. (OPTIONALLY) Run `git mv au3WebDriver Includes\au3WebDriver` to relocate the UDF into an Includes folder

## Contributing

Just look at [CONTRIBUTING], thank you!

## License

Distributed under the MIT License. See [LICENSE] for more information.

## Acknowledgements

- Opportunity by [GitHub](https://github.com)
- Badges by [Shields](https://shields.io)
- Thanks to the authors of the Third-Party UDFs
  - *Json UDF* by @Ward and @Jos
  - *WinHTTP UDF* by @trancexx/[@dragana-r](https://github.com/dragana-r)
  - *WinHttp_WebSocket UDF* by @Danp2
- Thanks to the maintainers
  - Thanks to [@Danp2](https://github.com/Danp2) for the project idea, creation and maintenance
  - Thanks to [@mLipok](https://github.com/mLipok) for his *wd_capabilities.au3*
  - Thanks to [@Sven-Seyfert](https://github.com/Sven-Seyfert) for the project logo
  - **Big thanks** to all the hard-working [contributors]

##

[To the top](#)

[Chrome48]: https://raw.githubusercontent.com/alrra/browser-logos/main/src/chrome/chrome_48x48.png
[Chrome16]: https://raw.githubusercontent.com/alrra/browser-logos/main/src/chrome/chrome_16x16.png
[Edge48]: https://raw.githubusercontent.com/alrra/browser-logos/main/src/edge/edge_48x48.png
[Edge16]: https://raw.githubusercontent.com/alrra/browser-logos/main/src/edge/edge_16x16.png
[Firefox48]: https://raw.githubusercontent.com/alrra/browser-logos/main/src/firefox/firefox_48x48.png
[Firefox16]: https://raw.githubusercontent.com/alrra/browser-logos/main/src/firefox/firefox_16x16.png
[Opera48]: https://raw.githubusercontent.com/alrra/browser-logos/main/src/opera/opera_48x48.png
[Opera16]: https://raw.githubusercontent.com/alrra/browser-logos/main/src/opera/opera_16x16.png
[ChromeDL]: https://sites.google.com/chromium.org/driver/downloads
[ChromeStatus]: https://chromium.googlesource.com/chromium/src/+/master/docs/chromedriver_status.md
[EdgeStatus]: https://docs.microsoft.com/en-us/microsoft-edge/webdriver-chromium/
[EdgeDL]: https://developer.microsoft.com/en-us/microsoft-edge/tools/webdriver/
[FirefoxStatus]: https://developer.mozilla.org/en-US/docs/Mozilla/QA/Marionette/WebDriver/status
[FirefoxDL]: https://github.com/mozilla/geckodriver/releases/latest
[OperaDL]: https://github.com/operasoftware/operachromiumdriver/releases/latest
[License]: https://github.com/Danp2/au3WebDriver/blob/master/LICENSE
[Contributors]: https://github.com/Danp2/au3WebDriver/graphs/contributors
[W3C WebDriver]: https://www.w3.org/TR/webdriver/
[WebDriver Wiki]: https://www.autoitscript.com/wiki/WebDriver
[Opera ReadMe]: https://github.com/operasoftware/operachromiumdriver/blob/master/README.md
[Json UDF]: https://www.autoitscript.com/forum/topic/148114-a-non-strict-json-udf-jsmn
[WinHTTP UDF]: https://github.com/dragana-r/autoit-winhttp/releases/latest
[WinHttp_WebSocket UDF]: https://github.com/Danp2/autoit-websocket
[CONTRIBUTING]: https://github.com/Danp2/au3WebDriver/blob/master/docs/CONTRIBUTING.md
[Change Log]: https://github.com/Danp2/au3WebDriver/blob/master/CHANGELOG.md