	v0.4.1.2
	- Added: _WD_CheckContext
	- Fixed (_WD_NewTab): Return error on _WD_Window failure
	- Fixed (_WD_IsLatestRelease)
		- Update regex
		- Return $_WD_ERROR_Exception if regex fails
	- Changed (_WD_ExecuteCDPCommand): Added http status check
	- Changed (__WD_DetectError): Detect unknown end point
	- Chore: Updated wd_cdp.au3
		- Rename functions so that they begin with _WD_CDP
		- Tidy code

	v0.4.1.1
	- Fixed (_WD_NewTab): Properly detect $sCurrentTabHandle retrieval
	- Changed (_WD_UpdateDriver): Improve error handling (seadoggie01)
	- Added: __WD_Sleep
		- Changed (_WD_Option): Added support for "Sleep" option
		- Chore: Use __WD_Sleep instead of Sleep in "helper" functions
	- Chore: Updated wd_demo.au3
		- Call correct Base64 decode function
		- Remove "binary" portion of MS Edge Capabilities string
	- Chore: Add remark to _WD_GetSession

	v0.4.1.0
	- Changed: Moved CDP-related functions to separate file (wd_cdp.au3)
	- Changed (_WD_ExecuteCDPCommand): Now supports additional browsers via WebSockets
	- Added: _WD_GetCDPSettings
	- Changed (_WD_Option): Added support for "DefaultTimeout" option (mLipok)

	v0.4.0.5
	- Changed (_WD_WaitElement): Added support for $_WD_OPTION_NoMatch (mLipok)
	- Changed (_WD_WaitElement): Always return Element ID
	- Fixed: InetRead() @error handling (mLipok)
	- Changed: Expose _WD_GetBrowserVersion and _WD_GetWebDriverVersion (mLipok)
	- Changed: Renamed _Base64Decode to __WD_Base64Decode

	v0.4.0.4
	- Added: _WD_IsFullScreen
	- Changed (_WD_SetElementValue): Advanced option now works with more element types
	- Fixed (_WD_ElementSelectAction): Use relative xpath when calling _WD_FindElement

	v0.4.0.3
	- Changed (_WD_HighlightElement): Option to remove highlight
	- Fix (_WD_SetElementValue): Corrected leftover $iMethod reference
	- Fix (_WD_FrameEnter) Properly handle Null index (mLipok)
	- Fix (_WD_SelectFiles) Properly set value of $sFuncName (mLipok)
	- Fix (_WD_ElementActionEx) Properly terminate JSON string
	- Chore (_WD_IsLatestRelease) Remove unneeded code for saving debug level (seadoggie01)
	- Chore (_WD_GetShadowRoot) Remove unused variable (seadoggie01)

	v0.4.0.2
	- Added: _WD_GetSession
	- Changed (_WD_FrameEnter): Allow Null as valid index value
	- Changed (_WD_ElementActionEx): Added support for childCount action
	- Changed (_WD_WaitElement): Switch to single parameter for options 		*** Script breaking change ***
	- Changed: _WD_ElementActionEx
		- Fixed: doubleclick and clickandhold now honor button parameter
		- Added: modifierclick
	- Changed (_WD_SetElementValue): Added "advanced" option

	v0.4.0.1
	- Added: _WD_PrintToPDF
	- Fix (_WD_Window): Properly handle 'print' result
	- Changed (_WD_ElementActionEx): Added 'hide' and 'show' options
	- Changed (_WD_ElementAction): Added support for Shadow, CompRole & CompLabel actions
	- Changed (_WD_GetShadowRoot): Use _WD_ElementAction instead of _WD_ExecuteScript
	- Changed (_WD_NewTab): Use native Webdriver commands when Javascript isn't required
	- Changed (_WD_FindElement): Support shadow roots
	- Changed (_WD_Window): Support 'full' option for screenshots

	v0.3.1.1
	- Fix (_WD_ElementOptionSelect): Correctly capture and re-throw errors (seadoggie01)
	- Fix (__WD_CloseDriver): Call ProcessWaitClose to ensure each process closes
	- Chore: Updated wd_demo.au3
		- Update DemoFrames example

	v0.3.1.0
	- Changed: Cleanup _WD_DownloadFile
		- Revise error list in header
		- Remove leftover $_WD_HTTPRESULT coding
		- Return $_WD_ERROR_NotFound instead of $_WD_ERROR_InvalidValue
	- Changed (_WD_WaitElement): Added optional parameter to return element instead of 0/1
	- Chore: Update function headers (Danp2 and seadoggie01)
	- Fix (_WD_Screenshot): Edit return value for Base64 screenshots (seadoggie01)
	- Fix (_WD_WaitElement): Clear variable holding element ID if visibility or enabled check fails

	v0.3.0.9
	- Changed (_WD_GetTable): Filter html elements by default when using _HtmlTableGetWriteToArray
	- Fix (_WD_DownloadFile): Handle error from InetRead
	- Changed (_WD_DownloadFile): Add $iOptions parameter
	- Chore: Updated wd_demo.au3
		- Update binary location of Edge browser
		- Update DemoDownload example
		- Misc updates

	v0.3.0.8
	- Changed (_WD_WaitElement): Added optional parameter to check elements enabled status
	- Changed (_WD_GetTable): Optionally support faster _HtmlTableGetWriteToArray
	- Changed (_WD_ElementAction): Allow retrieving element value with the 'value' command
	- Chore: Modified #include usage

	v0.3.0.7
	- Fixed (__WD_CloseDriver): Properly close webdriver console
	- Changed (_WD_Option): Added support for "console" option
	- Changed: Allow logging to file instead of default console

	v0.3.0.6
	- Fixed (__WD_Get, __WD_Post, __WD_Delete): Correctly pass detected errors to calling routine
	- Changed (__WD_Get): Eliminated optional $iMode parameter

	v0.3.0.5
	- Added: _WD_GetTable (danylarson / water)
	- Fixed (_WD_FindElement): Enforce relative xpath when utilizing a starting element
	- Changed: Use InetRead instead of __WD_Get (_WD_IsLatestRelease & _WD_UpdateDriver)
	- Changed: Pass Content-Type header in HTTP request

	v0.3.0.4
	- Added: _WD_ExecuteCdpCommand (TheDcoder)
	- Changed (_WD_UpdateDriver): Add support for MSEdge (Chromium)
	- Changed (_WD_Shutdown): Allow shutdown of specific module by name or PID
	- Changed (_WD_Startup): Notify if WinHTTP UDF needs updated
	- Changed: Improved error handling / HTTP timeout detection

	v0.3.0.3
	- Added: _WD_SetTimeouts
	- Added: _WD_GetElementById
	- Added: _WD_GetElementByName
	- Added: _WD_SetElementValue
	- Added: _WD_ElementActionEx

	v0.3.0.2
	- Fixed: WinHTTP timeout coding
	- Changed (_WD_Option): Add support for DriverDetect option
	- Changed (_WD_Startup): Respect DriverDetect setting

	v0.3.0.1
	- Changed (_WD_Window): Add support for New option
	- Changed (_WD_Window): Add support for Print option
	- Changed (_WD_Window): Window option can now be used to switch tabs (ala existing 'switch' option)
	- Added: Unknown Command error detection

	v0.2.0.9
	- Changed: _WD_Status now returns Dictionary object instead of raw JSON string
	- Changed: Add support for DebugTrim option to _WD_Option
	- Changed: Remove check for $HTTP_STATUS_SERVER_ERROR (chromedriver relic)
	- Changed: Improved output from _WD_IsLatestRelease
	- Fixed: Default arguments for _WD_ExecuteScript should be empty string
	- Fixed: Removed unneeded string conversion
	- Added: Generic error detection routine

	v.0.2.0.8
	- Fixed: Error handling in _WD_IsLatestRelease
	- Changed: Add support for DriverClose option to _WD_Option
	- Changed: _WD_Startup no longer closes existing driver consoles if DriverClose option (_WD_Option) is False
	- Changed: Add support for HTTPTimeouts option to _WD_Option
	- Changed: Set timeouts for WinHTTP requests if HTTPTimeouts option (_WD_Option) is True

	v.0.2.0.7
	- Changed: Remove check for invalid status codes from _WD_Alert
	- Changed: Hide debug output in _WD_IsLatestRelease
	- Changed: Expanded error handling in _WD_ElementAction
	- Fixed: Default variable initialization in _WD_ElementOptionSelect
	- Added: _WD_ElementSelectAction
	- Added: Check for UDF update in _WD_Startup

	v0.2.0.6
	- Changed: _WD_ElementAction handling of return status codes
	- Changed: File separator is now @LF in _WD_SelectFiles
	- Changed: wd_demo
	- Added: DemoUpload
	- Chore: Update description of parameters in _WD_ConsoleVisible
	- Fixed: Proper string escaping in _WD_SelectFiles

	v0.2.0.5
	- Fixed: __WD_CloseDriver regression
	- Fixed: __WD_Get, __WD_Put & __WD_Delete pass additional URL components

	v0.2.0.4
	- Added: _WD_DownloadFile
	- Added: Global variable to hold session details
	- Changed: wd_demo
		- Added: GUI front-end
		- Added: DemoDownload
		- Changed: DemoWindows, DemoTimeouts, DemoElements
	- Fixed: __WD_CloseDriver now closes child console processes

	v0.2.0.3
	- Fixed: Missing include file
	- Fixed: _WD_Execute timeout detection / handling

	v0.2.0.2
	- Added: _WD_IsLatestRelease
	- Added: _WD_UpdateDriver
	- Changed: __WD_Get and __WD_Put updated to detect invalid URL
	- Changed: __WD_Get and __WD_Put updated to handle both HTTP and HTTPS requests
	- Changed: __WD_CloseDriver - Optional parameter to indicate driver to close
	- Fixed: __WD_Put and __WD_Delete use correct port
	- Fixed: _WD_Navigate timeout detection / handling

	v0.2.0.1
	- Added: _WD_GetShadowRoot
	- Added: _WD_SelectFiles
	- Fixed: Additional error checking in _WD_WaitElement
	- Fixed: Standardize coding of frame related functions
	- Changed: Added backslash to list of characters to escape
	- Changed: Modified _WD_jQuerify with additional parameters for timeout / alternate jQuery source

	v0.1.0.21
	- Fixed: 'maximize', 'minimize', 'fullscreen' options now work correctly in _WD_Window
	- Fixed: Prevent runtime error dialog from appearing when function call succeeded

	V0.1.0.20
	- Fixed: Escape string passed to _WD_ElementAction when setting element's value
	- Fixed: Return value from _WD_Window should be "" on error
	- Fixed: Current tab handling in _WD_Attach

	V0.1.0.19
	- Added: _WD_ConsoleVisible
	- Added: __WD_EscapeString
	- Changed: Escape double quotes in string passed to _WD_FindElement, _WD_ExecuteScript
	- Changed: _WD_Window with 'rect' command now returns Dictionary object instead of raw JSON string

	V0.1.0.18
	- Changed: Add optional parameters to _WD_NewTab for URL and Features
	- Added: _WD_jQuerify
	- Added: _WD_ElementOptionSelect

	V0.1.0.17
	- Changed: Add 'Screenshot' option to _WD_ElementAction
	- Changed: Extract JSON value when taking screenshot in _WD_Window
	- Changed: Rework coding of _WD_ElementAction
	- Fixed: Error handling in __WD_Get
	- Fixed: _WD_NewTab failed in some situations
	- Fixed: _WD_Window error handling
	- Added: _WD_Screenshot

	V0.1.0.16
	- Changed: Add async support to _WD_ExecuteScript
	- Changed: Add debug info to _WD_GetMouseElement
	- Fixed: Set element value in _WD_ElementAction
	- Fixed: Prevent premature exit in _WD_WaitElement
	- Fixed: ChromeDriver now uses goog:chromeOptions

	V0.1.0.15
	- Fixed: __WD_Post now suppports Unicode text
	- Changed: Add support for Unicode text to _WD_ElementAction's "value" option
	- Changed: Add support for BinaryFormat option to _WD_Option
	- Added: _WD_LoadWait

	V0.1.0.14
	- Fixed: Improve error handling in _WD_NewTab
	- Fixed: Screenshot option in _WD_Window
	- Fixed: Close handles in __WD_Get, __WD_Post, __WD_Delete

	V0.1.0.13
	- Fixed: Remove unsupported locator constants
	- Fixed: Return value of _WD_WaitElement
	- Changed: Add support for 'displayed' option in _WD_ElementAction (BigDaddyO)
	- Changed: Add $lVisible parameter to _WD_WaitElement
	- Changed: $_WD_DEBUG now defaults to $_WD_DEBUG_Info

	V0.1.0.12
	- Changed: Modified _WD_NewTab with timeout parameter
	- Fixed: Correctly set @error in _WD_ExecuteScript
	- Added: _WD_HighlightElement (Danyfirex)
	- Added: _WD_HighlightElements (Danyfirex)

	V0.1.0.11
	- Changed: Modified _WD_FindElement to use new global constant
	- Fixed: _WD_GetMouseElement JSON processing
	- Fixed: _WD_GetElementFromPoint JSON processing
	- Added: _WD_GetFrameCount (Decibel)
	- Added: _WD_IsWindowTop   (Decibel)
	- Added: _WD_FrameEnter    (Decibel)
	- Added: _WD_FrameLeave    (Decibel)

	V0.1.0.10
	- Changed: Add support for non-standard error codes in _WD_Alert
	- Changed: Detect non-present alert in _WD_Alert
	- Changed: __WD_Error coding
	- Fixed: Correctly set function error codes
	- Added: _WD_LastHTTPResult

	V0.1.0.9
	- Changed: Force command parameter to lowercase in _WD_Action
	- Changed: Enhanced error checking in _WD_FindElement
	- Added: _WD_GetMouseElement
	- Added: _WD_GetElementFromPoint

	V0.1.0.8
	- Changed: Improve error handling in _WD_Attach
	- Fixed: Missing "window" in URL for _WD_Window
	- Fixed: Header entry for _WD_Option
	- Added: Reference to Edge driver
	- Fixed: _WD_Window implementation of Maximize, Minimize, Fullscreen, & Screenshot
	- Removed: Normal option from _WD_Window
	- Added: Rect option to _WD_Window

	V0.1.0.7
	- Changed: Add $sOption parameter to _WD_Action
	- Changed: Implemented "Actions" command in _WD_Action
	- Changed: Improved error handling in _WD_FindElement
	- Added: _WD_WaitElement

	V0.1.0.6
	- Fixed: Missing variable declarations
	- Changed: _WD_Attach error handling

	V0.1.0.5
	- Changed: Switched to using _WinHttp functions
	- Added: _WD_LinkClickByText

	V0.1.0.4
	- Changed: Renamed core UDF functions
	- Changed: _WD_FindElement now returns multiple elements as an array instead of raw JSON

	V0.1.0.3
	- Fixed: Error constants
	- Changed: Renamed UDF files
	- Changed: Expanded _WDAlert functionality
	- Changed: Check for timeout in __WD_Post
	- Changed: Support parameters in _WDExecuteScript
	- Added: _WD_Attach function

	V0.1.0.2
	- Fixed: _WDWindow
	- Changed: Error constants (mLipok)
	- Added: Links to W3C documentation
	- Added: _WD_NewTab function

	V0.1.0.1
	- Initial release

