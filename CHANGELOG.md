#####

# Changelog

All notable changes to "au3WebDriver" will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Go to [legend](#legend---types-of-changes) for further information about the types of changes.

## [1.3.0]

### Changed

_WD_GetTable - Add parameter for selection strategy. `Script breaking change`

### Project

- Improved Tidy support
- Fix Au3Check issues
- Standardize naming of internal functions

## [1.2.0] 2023-08-17

### Changed

- _WD_GetTable
	- Support for non-standard table markers
	- Improve performance

- _WD_GetElementFromPoint: Added error checking for negative coordinates

### Fixed

- _WD_GetTable: Revise existing xpaths to include header elements in results

### Project

- Eliminate usage of _HtmlTableGetWriteToArray

## [1.1.1] 2023-08-01

### Fixed

- _WD_ExecuteScript: Eliminate reformatting of JS code

## [1.1.0] 2023-07-17

### Changed

- _WD_UpdateDriver
	- Added ability to downgrade the webdriver to the correct version
	- Added ability to check if webdriver downgrade is needed
	- Added error code to indicate a version mismatch between the browser and webdriver
- _WD_IsLatestRelease: Use _VersionCompare()

### Project

-  Enhanced chromedriver support
	- New download location
	- Enable 64 bit support
	- Temporarily added `chrome_legacy` to support older versions (pre v115) of Chrome

## [1.0.3] 2023-05-29

### Fixed

- _WD_GetElementFromPoint
	- Correct frame identification
	- Handle Null result from `document.elementFromPoint`

## [1.0.2] 2023-05-24

### Fixed

- Correct UDF version number

## [1.0.1] 2023-05-23

### Fixed

- _WD_FrameEnter: Remove GUID validation

### Project

- Improve string encoding by using existing function from JSON UDF

## [1.0.0] - 2023-04-28

### Added

- Support for MSEdge browser in IE mode (@mlipok)
- _WD_FrameListFindElement (@mlipok)
- _WD_GetContext
- _WD_Option: Support for `DetailErrors` option
- _WD_WaitScript (@ye7iaserag)

### Changed
- _WD_FrameList (@mlipok)
	- Refactored for better performance
	- Improved frame support
	- Improved logging
	- Optional parameters to control initial delay and timeout
- _WD_GetFreePort
	- New error code to indicate internal error
	- Returns starting port number instead of 0 when an error occurs
	- Improved logging
- _WD_SetElementValue: Masking value in $sParameters
- _WD_Startup: Improve logging when error occurs in _WD_GetFreePort
- Enable optional detailed error reporting
	- _WD_Attach
	- _WD_CreateSession
	- _WD_DeleteSession
	- _WD_FrameEnter
	- _WD_FrameLeave
	- _WD_FrameList
	- _WD_LinkClickByText
- wd_demo: Improvements to "userfile" option

### Fixed

_WD_GetElementFromPoint: Frame support

## [ 0.13.0] - 2023-03-26

### Added

- _WD_ElementActionEx: Support for `remove` command (@Sven-Seyfert)

### Changed

- _WD_LoadWait: Invalid context detection
- _WD_CheckContext: Invalid context detection
- _WD_Window: Accept unformatted handles (@seadoggie01)
- _WD_CreateSession: Improved error handling (@mlipok)
- __WD_DetectError
	- Detect session not created errors
	- Detect shadow root not found errors
	- Detect frame not found errors
- _WD_DebugSwitch: Refactored to allow returning current stack size (@mlipok)
- _WD_FrameList: Added frame visibility information (@mlipok)
- _WD_ExecuteScript: Improved logging messages
- _WD_Shutdown: Add delay before closing webdriver
- wd_demo
	- Set `binary` capability for geckodriver & operadriver
	- Added UserFile demo to allow execution of code from file

### Fixed

- _WD_FrameLeave: Error reporting (@mlipok)
- Remove leftover $_WD_HTTPRESULT checks (_WD_Window, _WD_ElementAction, _WD_FindElement)

## [ 0.12.0] - 2023-02-15

### Added

- _WD_DebugSwitch (@mLipok)
- _WD_GetFreePort

### Changed

- _WD_CreateSession: Revise default capabilities
- _WD_ElementActionEx: Scroll element into view by default

## [ 0.11.0] - 2022-10-03

### Added

- _WD_FrameList (@mLipok)
- _WD_DispatchEvent

### Changed

- _WD_CapabilitiesAdd: Support `mobileEmulation>deviceMetrics` capability
- _WD_ElementSelectAction
	- Added `singleSelect` command
	- Revised columns returned by `options` and `selectedOptions` commands
	- Refactored Javascript coding
- _WD_FrameEnter: Added support for _WD_FrameList style paths
- _WD_FrameLeave: Refactored for improved functionality
- _WD_LinkClickByText: Added ability to specify the starting element
- _WD_LoadWait
	- Improved error handling / logging
	- Added ability to specify minimally acceptable page loading status 

### Fixed

- _WD_Alert: Set correct error code when 'status' no alert present
- Improved error detection in winhttp routines

## [0.10.1] - 2022-07-29

### Added

- _WD_CapabilitiesAdd: Support `webSocketUrl` capability

### Changed

- _WD_ElementSelectAction: Hidden option detection

### Fixed

- _WD_CDPExecuteCommand: Missing $ prefix in variable name
- _WD_CapabilitiesAdd: Support keys containing colons
- _WD_ElementSelectAction: Altering selection now triggers Change event

## [0.10.0] - 2022-07-13

### Added

- _WD_GetElementByRegEx (@TheDcoder)
- _WD_ElementStyle 	(@mLipok)
- _WD_Storage

### Changed

- __WD_DetectError: Detect Javascript and Invalid Selector errors
- _WD_SetElementValue: Advanced mode now triggers Change event
- _WD_Startup: Improve logging when existing webdriver instance is reused
- _WD_ElementSelectAction: Disabled option detection
- Logging
	- Reduced detail of messages associated with $_WD_DEBUG_Info
	- Webdriver responses are now only shown with $__WD_DEBUG_Full and they are no longer trimmed by default
- wd_demo
	- Added DemoStyles(), DemoSelectOptions(), UserTesting()
	- Improved demo selection

### Fixed

- _WD_UpdateDriver: Revise URL used to determine latest matching version of Edgedriver

### Removed

- _WD_HighlightElement

## [0.9.1] - 2022-06-04

### Fixed

- _WD_ElementAction: Correct action names (CompRole >> ComputedRole & CompLabel >> ComputedLabel)
- _WD_GetWebDriverVersion: Update regex for extracting version number
- Help file search functionality

## [0.9.0] - 2022-05-02

### Added

- _WD_LastHTTPResponse
- _WD_CapabilitiesDefine

### Removed

_WD_CapabilitiesDisplay

### Fixed

- _WD_WaitElement: Prevent premature exit when $_WD_OPTION_NoMatch is True
- __WD_GetLatestWebdriverInfo: Log correct function name
- __WD_UpdateExtractor: Correct detection of executable located in subfolder
- _WD_Startup: Check result of _WinAPI_GetBinaryType

### Changed

- _WD_Startup: Detect missing webdriver executable
- __WD_ConsoleWrite: Added conditional logging via new optional $iDebugLevel parameter
- Support additional debugging level ($_WD_DEBUG_Full)
- _WD_CapabilitiesAdd
	- Support browser specific / vendor capabilities
	- Capability names are case sensitive
- wd_demo
	- Detect / abort on failure to approve cookies
	- Update DemoScript() examples + descriptions

### Project

- Remove unused WinHTTP request object

## [0.8.1] - 2022-03-29

### Fixed

- Rerelease with correct version number and updated help file

## [0.8.0] - 2022-03-28

### Added

- _WD_Option: Support for "ConsoleSuffix", "ErrorMsgbox", "OutputDebug", and "Version" options
- _WD_ElementSelectAction: Added Multiselect functionality

### Changed

- __WD_ConsoleWrite: Utilize new ConsoleSuffix setting
- __WD_Error: Refactored for improved functionality
- _WD_CapabilitiesDump: Adhere to debug level settings
- _WD_Startup: Additional logging when error detected

### Fixed

- _WD_Startup: Display of webdriver bit level (32 / 64)
- _WD_UpdateDriver: Set @extended correctly
- _WD_GetBrowserVersion: Binary type checking
- _WD_Cookies: Deletion corrected
- wd_capabilities: Validate initialization result
- wd_demo: Updated routines to ensure proper functionality

### Project

- Scripts should use _WD_LastHTTPResult() to obtain the result of the most recent HTTP request as Webdriver functions no longer set @extended to last HTTP request result.
- Improved logging / error reporting by making sure that functions call __WD_Error.

## [0.7.0] - 2022-03-03

### Added

- Support for Opera browser
- _WD_GetBrowserPath

### Changed

- __WD_ConsoleWrite: Updated to preserve @error and @extended.
- _WD_Startup: Added display of webdriver bit level (32 / 64).
- _WD_UpdateDriver: Support alternate browser location.
- _WD_UpdateDriver: Extract webdriver executable located in a subfolder
- _WD_CapabilitiesAdd: Must use 'msedge' instead of 'edge' when for browser name. `Script breaking change`

### Fixed

- _WD_UpdateDriver: Unpacking webdriver executable failed on some workstations; Better error handling
- _WD_GetWebDriverVersion: Resolve error `Subscript used on non-accessible variable`

## [0.6.0] - 2022-02-22

### Added

- _WD_JsonCookie (mLipok)
- _WD_GetDevicePixelRatio (mLipok)
- _WD_Cookies: Added DeleteAll option (mLipok)
- _WD_ElementSelectAction: Added SelectedIndex option (mLipok)

### Changed

- _WD_ElementSelectAction: Options array expanded to include additional columns (index, selected) (mLipok)
- _WD_Option: Logging can use a custom function or be completely disabled (mLipok)
- wd_capabilities.au3 now uses internal function __WD_ConsoleWrite
- wd_demo.au3
	- Updated DemoCookies
	- Enhanced logging options

### Fixed

- _WD_UpdateDriver: Detect error during download and additional error handling

### Project

- Rename project (repository) to au3WebDriver
- README.md restructuring
- Added files to fulfill the community standards
	- bug_report.md and feature_request.md
	- CODE_OF_CONDUCT.md file
	- PULL_REQUEST_TEMPLATE.md file
- CONTRIBUTING.md file now contains references to bug report template and feature request template

## [0.5.2] - 2022-02-11

### Changed

- _WD_HighlightElements: Refactored for speed; now supports single or multiple elements
- _WD_UpdateDriver: Adjusted URL to match revised Github repo name

### Deprecated

- _WD_HighlightElement: Flagged as Deprecated and will be removed in a future release

### Project

- REVISIONS.md renamed to CHANGELOG.md and format updated

## [0.5.1.1] - 2022-01-31

### Added

- _WD_JsonActionKey, _WD_JsonActionPause, and _WD_JsonActionPointer functions
- _WD_ElementActionEx: Support for 'click' action
- wd_demo.au3
	- "update" option
	- "headless" option
	- DemoPrint routine

### Changed

- _WD_UpdateDriver: Attempts to identify current architecture if $bFlag64 is Default.
- __WD_DetectError: Detect "no such alert"
- _WD_ElementSelectAction: Performance of "Options" significantly improved by reducing Webdriver calls
- wd_demo.au3
	- Improved console output in DemoScript
	- Display screenshots in DemoWindows
	- Improved console output & in DemoAlerts
	- Corrected 'sendtext' coding in DemoAlerts

### Fixed

- _WD_Alert: Improve alert detection
- _WD_UpdateDriver: $bForce / $KEYWORD_NULL implementation (again)

## [0.5.1.0] - 2022-01-19

### Added

- $_WD_JSON\_* constants
- _WD_UpdateDriver: Checks for valid installation directory
- _WD_UpdateDriver: Check for existing 32/64 bit driver

### Changed

- _WD_GetElementFromPoint: Sets @Extended to shown context changed
- _WD_GetElementFromPoint: Additional error checking
- _WD_ExecuteScript: Add support for return of additional subnodes
- Update various functions to use $_WD_JSON\_* constants
- _WD_GetBrowserVersion: Returns "0" on failure instead of "" `Script breaking change`
- _WD_GetWebDriverVersion: Returns "0" on failure instead of "None" `Script breaking change`
- _WD_UpdateDriver: Improved version comparison
- _WD_UpdateDriver: Improved zip extraction
- _WD_Screenshot: Improved error handling

### Fixed

- _WD_UpdateDriver: $bForce / $KEYWORD_NULL implementation
- _WD_UpdateDriver: Regex used with geckodriver
- _WD_GetShadowRoot, _WD_SelectFiles, _WD_SetTimeouts: Correctly initialize return value

## [0.5.0.3] - 2021-12-27

### Added

- _WD_ElementActionEx: Support for "check" and "uncheck" commands (TheDcoder)

### Changed

- _WD_ExecuteScript: Optionally return value node instead of entire JSON response (mLipok)
- _WD_GetElementFromPoint: Added support for frames

### Fixed

- _WD_ElementAction: Return raw response for 'shadow' command
- _WD_GetShadowRoot: Use shadow root identifier

## [0.5.0.2] - 2021-12-16

### Added

- _WD_Capabilities: Support for "binary" option (mLipok)
- CHM help file (water)
- wd_demo.au3: DemoSleep routine (mLipok)

### Changed

- _WD_Startup: Detect webdriver console exiting with error when launched

### Fixed

- Updated function headers (water)
- wd_demo.au3
	- Changed GUI background color for better visibility in Windows 11
	- Disable "Run Demo" button during demo execution

## [0.5.0.1] - 2021-12-03

### Added

- _WD_Capabilities functions (mLipok)
- _WD_UpdateDriver: Ability to check for newer webdriver without performing update

### Changed

- __WD_Sleep: Set @error to $_WD_ERROR_UserAbort in case of error (mLipok)
- Updated wd_demo.au3 (mLipok)
	- Au3Check compatibility
	- Script no longer exits after running selected demos
	- Demonstrate usage of new _WD_Capabilities functions

## [0.4.1.2] - 2021-10-25

### Added

- _WD_CheckContext

### Changed

- _WD_ExecuteCDPCommand: Added http status check
- __WD_DetectError: Detect unknown end point
- wd_cdp.au3: Rename functions so that they begin with _WD_CDP

### Fixed

- _WD_NewTab: Return error on _WD_Window failure
- _WD_IsLatestRelease
	- Update regex
	- Return $_WD_ERROR_Exception if regex fails


## [0.4.1.1] - 2021-08-31

### Added

- __WD_Sleep
- _WD_Option: Support for "Sleep" option

### Changed

- _WD_UpdateDriver: Improve error handling (seadoggie01)
- _WD_GetSession: Remark to
- Use __WD_Sleep instead of Sleep in "helper" functions
- wd_demo.au3: Call correct Base64 decode function
- wd_demo.au3: Remove "binary" portion of MS Edge Capabilities string

### Fixed

- _WD_NewTab: Properly detect $sCurrentTabHandle retrieval


## [0.4.1.0] - 2021-07-28

### Added

- _WD_GetCDPSettings
- _WD_Option: Support for "DefaultTimeout" option (mLipok)

### Changed

- Moved CDP-related functions to separate file (wd_cdp.au3)
- _WD_ExecuteCDPCommand: Now supports additional browsers via WebSockets

## [0.4.0.5] - 2021-07-09

### Changed

- _WD_WaitElement: Added support for $_WD_OPTION_NoMatch (mLipok)
- _WD_WaitElement: Always return Element ID
- Expose _WD_GetBrowserVersion and _WD_GetWebDriverVersion (mLipok)
- Renamed _Base64Decode to __WD_Base64Decode

### Fixed

- InetRead() @error handling (mLipok)

## [0.4.0.4] - 2021-05-20

### Added

- _WD_IsFullScreen

### Changed

- _WD_SetElementValue: Advanced option now works with more element types

### Fixed

- _WD_ElementSelectAction: Use relative xpath when calling _WD_FindElement

## [0.4.0.3] - 2021-04-28

### Changed

- _WD_HighlightElement: Option to remove highlight

### Fixed

- _WD_SetElementValue: Corrected leftover $iMethod reference
- _WD_FrameEnter: Properly handle Null index (mLipok)
- _WD_SelectFiles: Properly set value of $sFuncName (mLipok)
- _WD_ElementActionEx: Properly terminate JSON string

### Removed

- _WD_IsLatestRelease: Remove unneeded code for saving debug level (seadoggie01)
- _WD_GetShadowRoot: Remove unused variable (seadoggie01)

## [0.4.0.2] - 2021-04-02

### Added

- _WD_GetSession
- _WD_ElementActionEx: modifierclick option
- _WD_ElementActionEx: childCount action
- _WD_SetElementValue: Added "advanced" option

### Changed

- _WD_FrameEnter: Allow Null as valid index value
- _WD_WaitElement: Switch to single parameter for options `Script breaking change`

### Fixed

- _WD_ElementActionEx: doubleclick and clickandhold now honor button parameter

## [0.4.0.1] - 2021-01-17

### Added

- _WD_PrintToPDF
- _WD_ElementActionEx: 'hide' and 'show' options
- _WD_ElementAction: Shadow, CompRole & CompLabel actions

### Changed

- _WD_GetShadowRoot: Use _WD_ElementAction instead of _WD_ExecuteScript
- _WD_NewTab: Use native Webdriver commands when Javascript isn't required
- _WD_FindElement: Support shadow roots
- _WD_Window: Support 'full' option for screenshots

### Fixed

- _WD_Window: Properly handle 'print' result

## [0.3.1.1] - 2021-01-09

### Changed

- wd_demo.au3: Update DemoFrames example

### Fixed

- _WD_ElementOptionSelect: Correctly capture and re-throw errors (seadoggie01)
- __WD_CloseDriver: Call ProcessWaitClose to ensure each process closes

## [0.3.1.0] - 2020-10-28

### Added

- _WD_WaitElement: Optional parameter to return element instead of 0/1

### Changed

- _WD_DownloadFile Cleanup
	- Revise error list in header
	- Remove leftover $_WD_HTTPRESULT coding
	- Return $_WD_ERROR_NotFound instead of $_WD_ERROR_InvalidValue
- Update function headers (Danp2 and seadoggie01)

### Fixed

- _WD_Screenshot: Edit return value for Base64 screenshots (seadoggie01)
- _WD_WaitElement: Clear variable holding element ID if visibility or enabled check fails

## [0.3.0.9] - 2020-09-13

### Changed

- _WD_GetTable: Filter html elements by default when using _HtmlTableGetWriteToArray
- _WD_DownloadFile: Add $iOptions parameter
- wd_demo.au3
	- Update binary location of Edge browser
	- Update DemoDownload example
	- Misc updates

### Fixed

- _WD_DownloadFile: Handle error from InetRead

## [0.3.0.8] - 2020-08-28

### Added

- _WD_WaitElement: Optional parameter to check elements enabled status
- _WD_GetTable: Optionally support faster _HtmlTableGetWriteToArray

### Changed

- _WD_ElementAction: Allow retrieving element value with the 'value' command
- Modified #include usage

## [0.3.0.7] - 2020-08-21

### Added

- _WD_Option: "console" option

### Changed

- Allow logging to file instead of default console

### Fixed

- __WD_CloseDriver: Properly close webdriver console

## [0.3.0.6] - 2020-08-04

### Changed

- __WD_Get: Eliminated optional $iMode parameter

### Fixed

- __WD_Get, __WD_Post, __WD_Delete: Correctly pass detected errors to calling routine

## [0.3.0.5] - 2020-07-30

### Added

- _WD_GetTable (danylarson / water)

### Changed

- Use InetRead instead of __WD_Get (_WD_IsLatestRelease & _WD_UpdateDriver)
- Pass Content-Type header in HTTP request

### Fixed

- _WD_FindElement: Enforce relative xpath when utilizing a starting element

## [0.3.0.4] - 2020-07-07

### Added

- _WD_ExecuteCdpCommand (TheDcoder)

### Changed

- _WD_UpdateDriver: Add support for MSEdge (Chromium)
- _WD_Shutdown: Allow shutdown of specific module by name or PID
- _WD_Startup: Notify if WinHTTP UDF needs updated
- Improved error handling / HTTP timeout detection

## [0.3.0.3] - 2020-06-16

### Added

- _WD_SetTimeouts
- _WD_GetElementById
- _WD_GetElementByName
- _WD_SetElementValue
- _WD_ElementActionEx

## [0.3.0.2] - 2020-06-13

### Changed

- _WD_Option: Add support for DriverDetect option
- _WD_Startup: Respect DriverDetect setting

### Fixed

- WinHTTP timeout coding

## [0.3.0.1] - 2020-05-25

### Added

- Unknown Command error detection

### Changed

- _WD_Window: Add support for New option
- _WD_Window: Add support for Print option
- _WD_Window: Window option can now be used to switch tabs (ala existing 'switch' option)

## [0.2.0.9] - 2020-05-12

### Added

- Generic error detection routine

### Changed

- _WD_Status now returns Dictionary object instead of raw JSON string
- Add support for DebugTrim option to _WD_Option
- Remove check for $HTTP_STATUS_SERVER_ERROR (chromedriver relic)
- Improved output from _WD_IsLatestRelease

### Fixed

- Default arguments for _WD_ExecuteScript should be empty string
- Removed unneeded string conversion

## [0.2.0.8] - 2020-05-01

### Changed

- Add support for DriverClose option to _WD_Option
- _WD_Startup no longer closes existing driver consoles if DriverClose option (_WD_Option) is False
- Add support for HTTPTimeouts option to _WD_Option
- Set timeouts for WinHTTP requests if HTTPTimeouts option (_WD_Option) is True

### Fixed

- Error handling in _WD_IsLatestRelease

## [0.2.0.7] - 2020-04-19

### Added

- _WD_ElementSelectAction
- Check for UDF update in _WD_Startup

### Changed

- _WD_Alert: Remove check for invalid status codes
- _WD_IsLatestRelease: Hide debug output
- _WD_ElementAction: Expanded error handling

### Fixed

- _WD_ElementOptionSelect: Default variable initialization

## [0.2.0.6] - 2020-02-19

### Added

- wd_demo.au3: DemoUpload

### Changed

- _WD_ElementAction: Handling of return status codes
- _WD_SelectFiles: File separator is now @LF
- _WD_ConsoleVisible: Update description of parameters

### Fixed

- _WD_SelectFiles: Proper string escaping

## [0.2.0.5] - 2020-01-18

### Fixed

- __WD_CloseDriver regression
- __WD_Get, __WD_Put & __WD_Delete pass additional URL components

## [0.2.0.4] - 2020-01-10

### Added

- _WD_DownloadFile
- Global variable to hold session details
- wd_demo.au3
	- GUI front-end
	- DemoDownload

### Changed

- wd_demo.au3: DemoWindows, DemoTimeouts, DemoElements

### Fixed

- __WD_CloseDriver now closes child console processes

## [0.2.0.3] - 2019-12-24

### Fixed

- Missing include file
- _WD_Execute timeout detection / handling

## [0.2.0.2] - 2019-12-24

### Added

- _WD_IsLatestRelease
- _WD_UpdateDriver

### Changed

- __WD_Get and __WD_Put updated to detect invalid URL
- __WD_Get and __WD_Put updated to handle both HTTP and HTTPS requests
- __WD_CloseDriver - Optional parameter to indicate driver to close

### Fixed

- __WD_Put and __WD_Delete use correct port
- _WD_Navigate timeout detection / handling

## [0.2.0.1] - 2019-12-13

### Added

- _WD_GetShadowRoot
- _WD_SelectFiles

### Changed

- Added backslash to list of characters to escape
- _WD_jQuerify: Additional parameters for timeout / alternate jQuery source

### Fixed

- _WD_WaitElement: Additional error checking
- Standardize coding of frame related functions

## [0.1.0.21] - 2019-09-10

### Fixed

- _WD_Window: 'maximize', 'minimize', 'fullscreen' options now work correctly
- Prevent runtime error dialog from appearing when function call succeeded

## [0.1.0.20] - 2019-07-14

### Fixed

- _WD_ElementAction: Escape string when setting element's value
- _WD_Window: Return value should be "" on error
- _WD_Attach: Current tab handling

## [0.1.0.19] - 2019-05-13

### Added

- _WD_ConsoleVisible
- __WD_EscapeString

### Changed

- Escape double quotes in string passed to _WD_FindElement, _WD_ExecuteScript
- _WD_Window with 'rect' command now returns Dictionary object instead of raw JSON string

## [0.1.0.18.1] - 2019-04-30

### Changed

- Correct version number

## [0.1.0.18] - 2019-04-30

### Added

- _WD_jQuerify
- _WD_ElementOptionSelect

### Changed

- Add optional parameters to _WD_NewTab for URL and Features

## [0.1.0.17] - 2019-01-15

### Added

- _WD_Screenshot
- _WD_ElementAction: Add 'Screenshot' option

### Changed

- _WD_Window: Extract JSON value when taking screenshot
- _WD_ElementAction: Rework coding

### Fixed

- Error handling in __WD_Get
- _WD_NewTab failed in some situations
- _WD_Window error handling

## [0.1.0.16] - 2018-11-21

### Added

- _WD_ExecuteScript: Add async support

### Changed

- _WD_GetMouseElement: Add debug info

### Fixed

- _WD_ElementAction: Set element value
- _WD_WaitElement: Prevent premature exit
- ChromeDriver now uses goog:chromeOptions

## [0.1.0.15] - 2018-09-15

### Added

- _WD_LoadWait
- _WD_Option: Add support for BinaryFormat option

### Changed

- _WD_ElementAction: Add support for Unicode text to "value" option

### Fixed

- __WD_Post now suppports Unicode text

## [0.1.0.14] - 2018-09-13

### Fixed

- _WD_NewTab: Improve error handling
- _WD_Window: Screenshot option
- Close handles in __WD_Get, __WD_Post, __WD_Delete

## [0.1.0.13] - 2018-08-06

### Added

- _WD_ElementAction: Add support for 'displayed' option (BigDaddyO)

### Changed

- _WD_WaitElement: Add $lVisible parameter
- $_WD_DEBUG now defaults to $_WD_DEBUG_Info

### Fixed

- Remove unsupported locator constants
- _WD_WaitElement: Correct return value

## [0.1.0.12] - 2018-07-12

### Added

- _WD_HighlightElement (Danyfirex)
- _WD_HighlightElements (Danyfirex)
- _WD_NewTab: Timeout parameter

### Fixed

- _WD_ExecuteScript: Correctly set @error

## [0.1.0.11] - 2018-06-28

### Added

- _WD_GetFrameCount (Decibel)
- _WD_IsWindowTop   (Decibel)
- _WD_FrameEnter    (Decibel)
- _WD_FrameLeave    (Decibel)

### Changed

- _WD_FindElement: Use new global constant

### Fixed

- _WD_GetMouseElement: JSON processing
- _WD_GetElementFromPoint: JSON processing

## [0.1.0.10] - 2018-05-13

### Added

- _WD_LastHTTPResult

### Changed

- _WD_Alert: Add support for non-standard error codes
- _WD_Alert: Detect non-present alert
- __WD_Error coding

### Fixed

- Correctly set function error codes

## [0.1.0.9] - 2018-02-20

### Added

- _WD_GetMouseElement
- _WD_GetElementFromPoint

### Changed

- _WD_Action: Force command parameter to lowercase
- _WD_FindElement: Enhanced error checking

## [0.1.0.8] - 2018-02-11

### Added

- Reference to Edge driver
- Rect option to _WD_Window

### Changed

- _WD_Attach: Improve error handling

### Fixed

- _WD_Window: Missing "window" in URL
- _WD_Option: Header entry
- _WD_Window: Implementation of Maximize, Minimize, Fullscreen, & Screenshot

### Removed

- Normal option from _WD_Window

## [0.1.0.7] - 2018-02-04

### Added

- _WD_WaitElement
- _WD_Action: Implemented "Actions" command

### Changed

- _WD_Action: Add $sOption parameter
- _WD_FindElement: Improved error handling

## [0.1.0.6] - 2018-02-01

### Changed

- _WD_Attach: Error handling

### Fixed

- Missing variable declarations

## [0.1.0.5] - 2018-01-31

### Added

- _WD_LinkClickByText

### Changed

- Switched to using _WinHttp functions

## [0.1.0.4] - 2018-01-27

### Changed

- Renamed core UDF functions
- _WD_FindElement: Returns multiple elements as an array instead of raw JSON

## [0.1.0.3] - 2018-01-25

### Added

- _WD_Attach function

### Changed

- _WDAlert: Expanded functionality
- _WDExecuteScript: Support parameters
- Check for timeout in __WD_Post
- Renamed UDF files

### Fixed

- Error constants

## [0.1.0.2] - 2018-01-22

### Added

- Links to W3C documentation
- _WD_NewTab function

### Changed

- Error constants (mLipok)

### Fixed

- _WDWindow

## [0.1.0.1] - 2018-01-18

### Added

- Initial release


[Unreleased]: https://github.com/Danp2/au3WebDriver/compare/1.3.0...HEAD
[1.3.0]:     https://github.com/Danp2/au3WebDriver/compare/1.2.0...1.3.0
[1.2.0]:     https://github.com/Danp2/au3WebDriver/compare/1.1.1...1.2.0
[1.1.1]:     https://github.com/Danp2/au3WebDriver/compare/1.1.0...1.1.1
[1.1.0]:     https://github.com/Danp2/au3WebDriver/compare/1.0.3...1.1.0
[1.0.3]:     https://github.com/Danp2/au3WebDriver/compare/1.0.2...1.0.3
[1.0.2]:     https://github.com/Danp2/au3WebDriver/compare/1.0.1...1.0.2
[1.0.1]:     https://github.com/Danp2/au3WebDriver/compare/1.0.0...1.0.1
[1.0.0]:     https://github.com/Danp2/au3WebDriver/compare/0.13.0...1.0.0
[0.13.0]:     https://github.com/Danp2/au3WebDriver/compare/0.12.0...0.13.0
[0.12.0]:     https://github.com/Danp2/au3WebDriver/compare/0.11.0...0.12.0
[0.11.0]:     https://github.com/Danp2/au3WebDriver/compare/0.10.1...0.11.0
[0.10.1]:     https://github.com/Danp2/au3WebDriver/compare/0.10.0...0.10.1
[0.10.0]:     https://github.com/Danp2/au3WebDriver/compare/0.9.1...0.10.0
[0.9.1]:      https://github.com/Danp2/au3WebDriver/compare/0.9.0...0.9.1
[0.9.0]:      https://github.com/Danp2/au3WebDriver/compare/0.8.1...0.9.0
[0.8.1]:      https://github.com/Danp2/au3WebDriver/compare/0.8.0...0.8.1
[0.8.0]:      https://github.com/Danp2/au3WebDriver/compare/0.7.0...0.8.0
[0.7.0]:      https://github.com/Danp2/au3WebDriver/compare/0.6.0...0.7.0
[0.6.0]:      https://github.com/Danp2/au3WebDriver/compare/0.5.2...0.6.0
[0.5.2]:      https://github.com/Danp2/au3WebDriver/compare/0.5.1.1...0.5.2
[0.5.1.1]:    https://github.com/Danp2/au3WebDriver/compare/0.5.1.0...0.5.1.1
[0.5.1.0]:    https://github.com/Danp2/au3WebDriver/compare/0.5.0.3...0.5.1.0
[0.5.0.3]:    https://github.com/Danp2/au3WebDriver/compare/0.5.0.2...0.5.0.3
[0.5.0.2]:    https://github.com/Danp2/au3WebDriver/compare/0.5.0.1...0.5.0.2
[0.5.0.1]:    https://github.com/Danp2/au3WebDriver/compare/0.4.1.2...0.5.0.1
[0.4.1.2]:    https://github.com/Danp2/au3WebDriver/compare/0.4.1.1...0.4.1.2
[0.4.1.1]:    https://github.com/Danp2/au3WebDriver/compare/0.4.1.0...0.4.1.1
[0.4.1.0]:    https://github.com/Danp2/au3WebDriver/compare/0.4.0.5...0.4.1.0
[0.4.0.5]:    https://github.com/Danp2/au3WebDriver/compare/0.4.0.4...0.4.0.5
[0.4.0.4]:    https://github.com/Danp2/au3WebDriver/compare/0.4.0.3...0.4.0.4
[0.4.0.3]:    https://github.com/Danp2/au3WebDriver/compare/0.4.0.2...0.4.0.3
[0.4.0.2]:    https://github.com/Danp2/au3WebDriver/compare/0.4.0.1...0.4.0.2
[0.4.0.1]:    https://github.com/Danp2/au3WebDriver/compare/0.3.1.1...0.4.0.1
[0.3.1.1]:    https://github.com/Danp2/au3WebDriver/compare/0.3.1.0...0.3.1.1
[0.3.1.0]:    https://github.com/Danp2/au3WebDriver/compare/0.3.0.9...0.3.1.0
[0.3.0.9]:    https://github.com/Danp2/au3WebDriver/compare/0.3.0.8...0.3.0.9
[0.3.0.8]:    https://github.com/Danp2/au3WebDriver/compare/0.3.0.7...0.3.0.8
[0.3.0.7]:    https://github.com/Danp2/au3WebDriver/compare/0.3.0.6...0.3.0.7
[0.3.0.6]:    https://github.com/Danp2/au3WebDriver/compare/0.3.0.5...0.3.0.6
[0.3.0.5]:    https://github.com/Danp2/au3WebDriver/compare/0.3.0.4...0.3.0.5
[0.3.0.4]:    https://github.com/Danp2/au3WebDriver/compare/0.3.0.3...0.3.0.4
[0.3.0.3]:    https://github.com/Danp2/au3WebDriver/compare/0.3.0.2...0.3.0.3
[0.3.0.2]:    https://github.com/Danp2/au3WebDriver/compare/0.3.0.1...0.3.0.2
[0.3.0.1]:    https://github.com/Danp2/au3WebDriver/compare/0.2.0.9...0.3.0.1
[0.2.0.9]:    https://github.com/Danp2/au3WebDriver/compare/0.2.0.8...0.2.0.9
[0.2.0.8]:    https://github.com/Danp2/au3WebDriver/compare/0.2.0.7...0.2.0.8
[0.2.0.7]:    https://github.com/Danp2/au3WebDriver/compare/0.2.0.6...0.2.0.7
[0.2.0.6]:    https://github.com/Danp2/au3WebDriver/compare/0.2.0.5...0.2.0.6
[0.2.0.5]:    https://github.com/Danp2/au3WebDriver/compare/0.2.0.4...0.2.0.5
[0.2.0.4]:    https://github.com/Danp2/au3WebDriver/compare/0.2.0.3...0.2.0.4
[0.2.0.3]:    https://github.com/Danp2/au3WebDriver/compare/0.2.0.2...0.2.0.3
[0.2.0.2]:    https://github.com/Danp2/au3WebDriver/compare/0.2.0.1...0.2.0.2
[0.2.0.1]:    https://github.com/Danp2/au3WebDriver/compare/0.1.0.21...0.2.0.1
[0.1.0.21]:   https://github.com/Danp2/au3WebDriver/compare/0.1.0.20...0.1.0.21
[0.1.0.20]:   https://github.com/Danp2/au3WebDriver/compare/0.1.0.19...0.1.0.20
[0.1.0.19]:   https://github.com/Danp2/au3WebDriver/compare/0.1.0.18...0.1.0.19
[0.1.0.18.1]: https://github.com/Danp2/au3WebDriver/compare/0.1.0.18...0.1.0.18.1
[0.1.0.18]:   https://github.com/Danp2/au3WebDriver/compare/0.1.0.17...0.1.0.18
[0.1.0.17]:   https://github.com/Danp2/au3WebDriver/compare/0.1.0.16...0.1.0.17
[0.1.0.16]:   https://github.com/Danp2/au3WebDriver/compare/0.1.0.15...0.1.0.16
[0.1.0.15]:   https://github.com/Danp2/au3WebDriver/compare/0.1.0.14...0.1.0.15
[0.1.0.14]:   https://github.com/Danp2/au3WebDriver/compare/0.1.0.13...0.1.0.14
[0.1.0.13]:   https://github.com/Danp2/au3WebDriver/compare/0.1.0.12...0.1.0.13
[0.1.0.12]:   https://github.com/Danp2/au3WebDriver/compare/0.1.0.11...0.1.0.12
[0.1.0.11]:   https://github.com/Danp2/au3WebDriver/compare/0.1.0.10...0.1.0.11
[0.1.0.10]:   https://github.com/Danp2/au3WebDriver/compare/0.1.0.9...0.1.0.10
[0.1.0.9]:    https://github.com/Danp2/au3WebDriver/compare/0.1.0.8...0.1.0.9
[0.1.0.8]:    https://github.com/Danp2/au3WebDriver/compare/0.1.0.7...0.1.0.8
[0.1.0.7]:    https://github.com/Danp2/au3WebDriver/compare/0.1.0.6...0.1.0.7
[0.1.0.6]:    https://github.com/Danp2/au3WebDriver/compare/0.1.0.5...0.1.0.6
[0.1.0.5]:    https://github.com/Danp2/au3WebDriver/compare/0.1.0.4...0.1.0.5
[0.1.0.4]:    https://github.com/Danp2/au3WebDriver/compare/0.1.0.3...0.1.0.4
[0.1.0.3]:    https://github.com/Danp2/au3WebDriver/compare/0.1.0.2...0.1.0.3
[0.1.0.2]:    https://github.com/Danp2/au3WebDriver/compare/0.1.0.1...0.1.0.2
[0.1.0.1]:    https://github.com/Danp2/au3WebDriver/releases/tag/0.1.0.1

---

### Legend - Types of changes

- `Added` for new features.
- `Changed` for changes in existing functionality.
- `Deprecated` for soon-to-be removed features.
- `Fixed` for any bug fixes.
- `Removed` for now removed features.
- `Security` in case of vulnerabilities.
- `Project` for documentation or contribution improvements.

##

[To the top](#)
