#####

<p align="center">
    <img src="images/icon.png" width="176" />
    <h2 align="center">Welcome to <code>WebDriver</code> through AutoIt</h2>
</p>

[![license](https://img.shields.io/badge/license-MIT-ff69b4.svg?style=flat-square&logo=spdx)](https://github.com/Danp2/WebDriver/blob/master/LICENSE)
[![contributors](https://img.shields.io/github/contributors/Danp2/WebDriver.svg?style=flat-square&logo=github)](https://github.com/Danp2/WebDriver/graphs/contributors)
![repo size](https://img.shields.io/github/repo-size/Danp2/WebDriver.svg?style=flat-square&logo=github)
[![last commit](https://img.shields.io/github/last-commit/Danp2/WebDriver.svg?style=flat-square&logo=github)](https://github.com/Danp2/WebDriver/commits/master)
[![release](https://img.shields.io/github/release/Danp2/WebDriver.svg?style=flat-square&logo=github)](https://github.com/Danp2/WebDriver/releases/latest)
![os](https://img.shields.io/badge/os-windows-yellow.svg?style=flat-square&logo=windows)
![stars](https://img.shields.io/github/stars/danp2/webdriver?color=blueviolet&logo=reverbnation&logoColor=white&style=flat-square)

[![youtube](https://img.shields.io/badge/Solve%20Smart-D94D4A?style=for-the-badge&labelColor=black&logo=youtube&logoColor=D94D4A)](https://youtube.com/channel/UCjPiWdl_h1CoYhZXaEC_AwA)

[Description](#description) | [Documentation](#documentation) | [Features](#features) | [Getting started](#getting-started) | [Configuration](#configuration) | [FAQ](#faq) | [Contributing](#contributing) | [License](#license) | [Acknowledgements](#acknowledgements)

## Description

This WebDriver UDF (project) allows to interact with any browser that supports the [W3C WebDriver specifications](https://www.w3.org/TR/webdriver/).<br>
Supporting multiple browsers via the same code base is now possible with just a few configuration settings.

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
| ![Chrome](https://raw.githubusercontent.com/alrra/browser-logos/main/src/chrome/chrome_48x48.png) | ![Edge](https://raw.githubusercontent.com/alrra/browser-logos/main/src/edge/edge_48x48.png) | ![Firefox](https://raw.githubusercontent.com/alrra/browser-logos/main/src/firefox/firefox_48x48.png) |


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
| _WD_CheckContext        | Check if browser context is still valid.                                   |
| _WD_JsonActionKey       | Formats keyboard "action" strings for use in _WD_Action                    |
| _WD_JsonActionPointer   | Formats pointer "action" strings for use in _WD_Action                     |
| _WD_JsonActionPause     | Formats pause "action" strings for use in _WD_Action                       |

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
| ![Chrome](https://raw.githubusercontent.com/alrra/browser-logos/main/src/chrome/chrome_16x16.png)    | [Chrome](https://sites.google.com/chromium.org/driver/downloads)              | [Status](https://chromium.googlesource.com/chromium/src/+/master/docs/chromedriver_status.md)                    |
| ![Edge](https://raw.githubusercontent.com/alrra/browser-logos/main/src/edge/edge_16x16.png)          | [Edge](https://developer.microsoft.com/en-us/microsoft-edge/tools/webdriver/) | [Status](https://chromium.googlesource.com/chromium/src/+/master/docs/chromedriver_status.md) [^1] |
| ![Firefox](https://raw.githubusercontent.com/alrra/browser-logos/main/src/firefox/firefox_16x16.png) | [Firefox](https://github.com/mozilla/geckodriver/releases/latest)             | [Status](https://developer.mozilla.org/en-US/docs/Web/WebDriver#specifications)                                  |

Limitation notice. [^2]

[^1]: "Microsoft Edge" (is chromium based) which means it's a WebDriver implementation derived from ChromeDriver. The status or limitations are at least the same as for ChromeDriver.
[^2]: Not all WebDriver functions have been implemented by each browser. Keep that in mind and check the "WebDriver specification status" for your desired WebDriver of choice.

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

Run [wd_demo.au3](https://github.com/Danp2/WebDriver/blob/master/wd_demo.au3) and select "DemoNavigation" to validate your installation.

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

## FAQ

<details>
<summary><i>Frequently Asked Questions</i></summary><br>

  <details>
  <summary><code>1. How to connect to a running browser instance</code></summary><p>

  **Q:** How can I connect to a running browser instance?<br>
  **A:** That's described (for Firefox, but should work similar for other browsers) in this [post](https://www.autoitscript.com/forum/topic/201537-webdriver-example-scripts-collection/?tab=comments#comment-1495880).

  <br></p></details>

  <details>
  <summary><code>2. How to hide the webdriver console</code></summary><p>

  **Q:** How can I hide the webdriver console?<br>
  **A:** The console can be completely hidden from the start by adding the following line near the beginning of your script:

  ``` autoit
  $_WD_DEBUG = $_WD_DEBUG_None ; You could also use $_WD_DEBUG_Error
  ```

  You can also control the visibility of the console with the function _WD_ConsoleVisible.

  <br></p></details>

  <details>
  <summary><code>3. How to utilize an existing user profile</code></summary><p>

  **Q:** Can I use an existing user profile instead of the default behavior of using a new one?<br>
  **A:** This is controlled by your "capabilities" declaration, with each browser using a different method to implement. Here are some examples:

  *Chrome*

  ``` autoit
  $sDesiredCapabilities = '{"capabilities": {"alwaysMatch": {"goog:chromeOptions": {"w3c": true, "args":["--user-data-dir=C:\\Users\\' & @UserName & '\\AppData\\Local\\Google\\Chrome\\User Data\\", "--profile-directory=Default"]}}}}'
  ```

  *MS Edge*

  ``` autoit
  $sDesiredCapabilities = '{"capabilities": {"alwaysMatch": {"ms:edgeOptions": {"args": ["user-data-dir=C:\\Users\\' & @UserName & '\\AppData\\Local\\Microsoft\\Edge\\User Data\\", "profile-directory=Default"]}}}}'
  ```

  *Firefox*

  ``` autoit
  $sDesiredCapabilities = '{"capabilities":{"alwaysMatch": {"moz:firefoxOptions": {"args": ["-profile", "' & GetDefaultFFProfile() & '"],"log": {"level": "trace"}}}}}'

  Func GetDefaultFFProfile()
    Local $sDefault, $sProfilePath = ''

    Local $sProfilesPath = StringReplace(@AppDataDir, '\', '/') & "/Mozilla/Firefox/"
    Local $sFilename = $sProfilesPath & "profiles.ini"
    Local $aSections = IniReadSectionNames ($sFilename)

    If Not @error Then
      For $i = 1 To $aSections[0]
        $sDefault = IniRead($sFilename, $aSections[$i], 'Default', '0')

        If $sDefault = '1' Then
          $sProfilePath = $sProfilesPath & IniRead($sFilename, $aSections[$i], "Path", "")
          ExitLoop
        EndIf
      Next
    EndIf

    Return $sProfilePath
  EndFunc
  ```

  You will also likely need to specify the marionette port:

  ``` autoit
  _WD_Option('DriverParams', '--marionette-port 2828')
  ```

  <br></p></details>

  <details>
  <summary><code>4. How to specify location of browser executable</code></summary><p>

  **Q:** Is it possible to launch a browser installed in a non-standard location?<br>
  **A:** This is controlled by your "capabilities" declaration. Here are some examples:

  *Chrome*

  ``` autoit
  $sDesiredCapabilities = '{"capabilities": {"alwaysMatch": {"goog:chromeOptions": {"w3c": true, "binary":"C:\\Path\\To\\Alternate\\Browser\\chrome.exe" }}}}'
  ```

  *Firefox*

  ``` autoit
  $sDesiredCapabilities = '{"desiredCapabilities":{"javascriptEnabled":true,"nativeEvents":true,"acceptInsecureCerts":true,"moz:firefoxOptions":{"binary":"C:\\Path\\To\\Alternate\\Browser\\firefox.exe"}}}'
  ```

  *Alternate Firefox method:*

  ``` autoit
  _WD_Option('DriverParams', '--binary "C:\Program Files\Mozilla Firefox\firefox.exe" --log trace ')
  ```

  <br></p></details>

  <details>
  <summary><code>5. How to maximize the browser window</code></summary><p>

  **Q:** Is it possible to maximize the browser window?<br>
  **A:** Simply call the following function:

  ``` autoit
  _WD_Window($sSession, "Maximize")
  ```

  Make sure to call _WD_Window after the session has been created with _WD_CreateSession.

  <br></p></details>

  <details>
  <summary><code>6. How to specify location of WebDriver executable</code></summary><p>

  **Q:** Is it possible to launch the WebDriver executable from a specific location?<br>
  **A:** This is controlled by function "_WD_Option". Example:

  ``` autoit
  _WD_Option("Driver", "C:\local\WebDriver\WebDriver.exe")
  ```

  <br></p></details>

  <details>
  <summary><code>7. How to retrieve the values of a drop-down list</code></summary><p>

  **Q:** How to retrieve the values of a drop-down list ("\<Select\>" tag)?<br>
  **A:** Here's a simple way to do it:

  ``` autoit
  $sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//select[@name='placeholder']")
  $sText = _WD_ElementAction($sSession, $sElement, 'property', 'innerText')
  $aOptions = StringSplit ( $sText, @LF,  $STR_NOCOUNT)
  _ArrayDisplay($aOptions)
  ```

  'placeholder' is the name of the drop-down list.

  Or this can also be accomplished using the function _WD_ElementSelectAction:

  ``` autoit
  $sElement = _WD_FindElement($sSession, $_WD_LOCATOR_ByXPath, "//select[@name='placeholder']")
  $aOptions = _WD_ElementSelectAction ($sSession, $sElement, 'options')
  _ArrayDisplay($aOptions)
  ```

  <br></p></details>

  <details>
  <summary><code>8. How to run the browser in headless mode (hidden mode)</code></summary><p>

  **Q:** How do I run the browser in "headless" mode?<br>
  **A:** This is controlled by the Capabilities string that is passed to _WD_CreateSession. Example:

  ``` autoit
  $sDesiredCapabilities = '{"capabilities": {"alwaysMatch": {"goog:chromeOptions": {"w3c": true, "args": ["--headless", "--allow-running-insecure-content"] }}}}'
  ```

  <br></p></details>

  <details>
  <summary><code>9. How to configure the UDF to call a user-defined Sleep function</code></summary><p>

  **Q:** How to configure the UDF to call a user-defined Sleep function, and interact with _WD_WaitElement() and _WD_LoadWait() to make the script more responsive?<br>
  **A:** Try to use _WD_Option("Sleep"). Example:

  ``` autoit
  #include <ButtonConstants.au3>
  #include <GuiComboBoxEx.au3>
  #include <GUIConstantsEx.au3>
  #include <MsgBoxConstants.au3>
  #include <WindowsConstants.au3>
  #include "wd_helper.au3"

  Global $idAbortTest
  Global $WD_SESSION
  _Example()

  Func _Example()
      SetupChrome()

      ; Create a GUI with various controls.
      Local $hGUI = GUICreate("Example")
      Local $idTest = GUICtrlCreateButton("Test", 10, 370, 85, 25)
      $idAbortTest = GUICtrlCreateButton("Abort", 150, 370, 85, 25)

      ; Display the GUI.
      GUISetState(@SW_SHOW, $hGUI)

      ConsoleWrite("- TESTING" & @CRLF)

      Local $sFilePath = _WriteTestHtml()

      ; Loop until the user exits.
      While 1
          Switch GUIGetMsg()
              Case $idTest
                  _WD_Navigate($WD_SESSION, $sFilePath)
                  _WD_WaitElement($WD_SESSION, $_WD_LOCATOR_ByXPath, '//a[contains(text(),"TEST")]', 100, 30 * 1000) ; timeout = 50 seconds
                  ConsoleWrite("---> @error=" & @error & "  @extended=" & @extended & _
                          " : after _WD_WaitElement()" & @CRLF)

              Case $GUI_EVENT_CLOSE
                  ExitLoop

          EndSwitch
      WEnd

      ; Delete the previous GUI and all controls.
      GUIDelete($hGUI)

  EndFunc   ;==>_Example

  Func _My_Sleep($iDelay)
      Local $hTimer = TimerInit() ; Begin the timer and store the handle in a variable.
      Do
          Switch GUIGetMsg()
              Case $GUI_EVENT_CLOSE
                  ConsoleWrite("! USER EXIT" & @CRLF)
                  Exit
              Case $idAbortTest
                  Return SetError($_WD_ERROR_UserAbort)
          EndSwitch
      Until TimerDiff($hTimer) > $iDelay
  EndFunc   ;==>_My_Sleep

  Func _WriteTestHtml($sFilePath = @ScriptDir & "\TestFile.html")
      FileDelete($sFilePath)
      Local Const $sHtml = _
              "<html lang='en'>" & @CRLF & _
              "    <head>" & @CRLF & _
              "        <meta charset='utf-8'>" & @CRLF & _
              "        <title>TESTING</title>" & @CRLF & _
              "    </head>" & @CRLF & _
              "    <body>" & @CRLF & _
              "        <div id='MyLink'>Waiting</div>" & @CRLF & _
              "    </body>" & @CRLF & _
              "    <script type='text/javascript'>" & @CRLF & _
              "    setTimeout(function()" & @CRLF & _
              "    {" & @CRLF & _
              "        // Delayed code in here" & @CRLF & _
              "        document.getElementById('MyLink').innerHTML='<a>TESTING</a>';" & @CRLF & _
              "    }, 20000); // 20000 = 20 seconds" & @CRLF & _
              "    </script>" & @CRLF & _
              "</html>"
      FileWrite($sFilePath, $sHtml)
      Return "file:///" & StringReplace($sFilePath, "\", "/")
  EndFunc   ;==>_WriteTestHtml

  Func SetupChrome()
      _WD_Startup()
      _WD_Option('Driver', 'chromedriver.exe')
      _WD_Option('Port', 9515)
      _WD_Option('HTTPTimeouts', True)
      _WD_Option('DefaultTimeout', 40001)
      _WD_Option('DriverParams', '--verbose --log-path="' & @ScriptDir & '\chrome.log"')
      _WD_Option("Sleep", _My_Sleep)

      Local $sCapabilities = '{"capabilities": {"alwaysMatch": {"goog:chromeOptions": {"w3c": true, "excludeSwitches": [ "enable-automation"]}}}}'
      $WD_SESSION = _WD_CreateSession($sCapabilities)
      _WD_Timeouts($WD_SESSION, 40002)
  EndFunc   ;==>SetupChrome
  ```

  <br></p></details>

  <details>
  <summary><code>10. How to keep my WebDriver environment up-to-date</code></summary><p>

  **Q:** How can I keep my WebDriver environment up-to-date?<br>
  **A:** You have to check the following components:

  *WebDriver UDF:* Function _WD_IsLatestRelease compares local UDF version to latest release on Github. Returns True if the local UDF version is the latest, otherwise False. If you need to update the UDF you have to download it manually.

  *WebDriver Exe:* Function _WD_UpdateDriver checks or updates the Web Driver with newer version, if available.

  *Browser:* Function _WD_GetBrowserVersion returns the version number of the specified browser. If you need to update the Browser you have to download and install it by hand.

  <br></p></details>

  <details>
  <summary><code>11. What are "Locator strategy" and " Selector"?</code></summary><p>

  **Q:** What is a "Locator strategy"?<br>
  **A:** Location strategies are used as a way to find element in HTML DOM. They instruct the remote end which method to use to find an element using the provided locator. Location strategies are used in _WD_FindElement() from wd_core.au3 UDF and all functions form wd_helper.au3 which relates on them.

  **Q:** What is a Selector?<br>
  **A:** Selector is a string that describes how the chosen "Locator strategy" should find the element.

  **Q:** What kind of "Locator strategy" could be used with WebDriver UDF?<br>
  **A:** This UDF supports all locators defined in the Webdriver specifications. Below is a listing of predefined constants:

| Locator strategy               | Description how to use "Selector"                                                                                                                                                                                                                     |
| :---                           | :---                                                                                                                                                                                                                                                  |
| $_WD_LOCATOR_ByCSSSelector     | CSSSelector string (definded by [W3C](https://www.w3.org/TR/CSS21/selector.html)). In CSS, pattern matching rules determine which style rules apply to elements in the HTML DOM document tree.                                                        |
| $_WD_LOCATOR_ByXPath           | XPath string (definded by [W3C](https://www.w3.org/TR/1999/REC-xpath-19991116)) is a language for addressing parts of an XML document, designed to be used by both XSLT and XPointer, and is used to find element through the HTML DOM document tree. |
| $_WD_LOCATOR_ByLinkText        | String with exact text of `<a>` element, which should be used to locate the proper `<a>` element                                                                                                                                                      |
| $_WD_LOCATOR_ByPartialLinkText | String with partial text of `<a>` element, which should be used to locate the proper `<a>` element                                                                                                                                                    |
| $_WD_LOCATOR_ByTagName         | String which match the desired element tag name, for example "button" is tag name of this element: `<button name="ClickMe">`                                                                                                                          |

  **Q:** Where I can find information about "XPath" usage?<br>
  **A:** https://www.w3.org/TR/1999/REC-xpath-19991116<br>
  **A:** https://developer.mozilla.org/en-US/docs/Web/XPath

  **Q:** Where I can find information about "CSSSelector" usage?<br>
  **A:** https://www.w3.org/TR/CSS21/selector.html<br>
  **A:** https://www.w3schools.com/cssref/css_selectors.asp<br>
  **A:** https://developer.mozilla.org/en-US/docs/Learn/CSS/Building_blocks/Selectors

  **Q:** How I can check XPath and CSSSelector in browser?<br>
  **A:** Work in progress [...]

  **Q:** How I can improve my work with XPath and CSSSelector?<br>
  **A:** Take a look for additionall tools like [ChroPath](https://autonomiq.io/deviq-chropath.html) or [SelectorsHub](https://selectorshub.com/).

  <br></p></details>

</details>

## Contributing

Just look at [CONTRIBUTING](https://github.com/Danp2/WebDriver/blob/master/docs/CONTRIBUTING.md), thank you!

## License

Distributed under the MIT License. See [LICENSE](https://github.com/Danp2/WebDriver/blob/master/LICENSE) for more information.

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
  - **Big thanks** to all the hard-working [contributors](https://github.com/Danp2/WebDriver/graphs/contributors)

##

[To the top](#)
