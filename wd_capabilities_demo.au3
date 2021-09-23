#include <MsgBoxConstants.au3>
#include "wd_capabilities.au3"

Global Const $_EXAMPLE_DRIVER_FIREFOX = @ScriptDir & '\geckodriver.exe' ; CHANGE TO PROPER FILE FULL PATH
Global Const $_EXAMPLE_DRIVER_CHROME = @ScriptDir & '\chromedriver.exe' ; CHANGE TO PROPER FILE FULL PATH
Global Const $_EXAMPLE_DRIVER_EDGE = @ScriptDir & '\msedgedriver.exe' ; CHANGE TO PROPER FILE FULL PATH

Global Const $_EXAMPLE_PROFILE_FIREFOX = @LocalAppDataDir & '\Mozilla\Firefox\Profiles\WD_Testing_Profile' ; CHANGE TO PROPER DIRECTORY PATH
Global Const $_EXAMPLE_PROFILE_CHROME = @LocalAppDataDir & '\Google\Chrome\User Data\WD_Testing_Profile' ; CHANGE TO PROPER DIRECTORY PATH
Global Const $_EXAMPLE_PROFILE_EDGE = @LocalAppDataDir & '\MicrosoftEdge\User\\WD_Testing_Profile' ; CHANGE TO PROPER DIRECTORY PATH

Global Const $_EXAMPLE_DOWNLOAD_DIR = @UserProfileDir & '\Downloads\WD_Testing_download' ; CHANGE TO PROPER DIRECTORY PATH

Global Const $_EXAMPLE_OPTION_RUN_BROWSER = ( _
		$IDYES = MsgBox($MB_YESNO + $MB_TOPMOST + $MB_ICONQUESTION + $MB_DEFBUTTON1, 'Question', _
		'Do you want to test with running browsers ?' & @CRLF & _
		'' & @CRLF & _
		' [YES] = Run browser' & @CRLF & _
		' [NO] = only put $s_Capabilities_JSON to console') _
		)

Global Const $_EXAMPLE_OPTION_CHOOSEN_DRIVER = (($_EXAMPLE_OPTION_RUN_BROWSER) ? (_WD_Capabilities_Example_ChooseDriver()) : (''))

Global Const $_EXAMPLE_OPTION_HEADLESS = ($_EXAMPLE_OPTION_RUN_BROWSER And _
		($IDYES = MsgBox($MB_YESNO + $MB_TOPMOST + $MB_ICONQUESTION + $MB_DEFBUTTON1, 'Question', _
		'Do you want to test with headless mode ?' & @CRLF & _
		'' & @CRLF & _
		' [YES] = Run browser in headless mode' & @CRLF & _
		' [NO] = Run browser in "visible" mode') _
		) _
		)

Global Const $_EXAMPLE_OPTION_PROXY = _
		($IDYES = MsgBox($MB_YESNO + $MB_TOPMOST + $MB_ICONQUESTION + $MB_DEFBUTTON1, 'Question', _
		'Do you want to test with connection buffered via Proxy server ?' & @CRLF & _
		'' & @CRLF & _
		' [YES] = use Proxy' & @CRLF & _
		' [NO] = direct coonection') _
		)

Global Const $_EXAMPLE_OPTION_ALLCAPS = _
		($IDYES = MsgBox($MB_YESNO + $MB_TOPMOST + $MB_ICONQUESTION + $MB_DEFBUTTON1, 'Question', _
		'Do you want to test with Capabilities for all "firstMatch" ?' & @CRLF & _
		'' & @CRLF & _
		' [YES] = test "firstMatch" Capabilites for all browser toogether' & @CRLF & _
		' [NO] = test only "firstMatch" desired for specified browser') _
		)

_WD_Capabilities_Example()
Exit

Func _WD_Capabilities_Example()
	_WD_CapabilitiesStartup()
	ConsoleWrite("! @ScriptLineNumber = " & @ScriptLineNumber & @CRLF)
	#Region - 	_WD_Capabilities_Example() ... "alwaysMatch" section
	_WD_CapabilitiesAdd('alwaysMatch')
	_WD_CapabilitiesAdd('acceptInsecureCerts', True)
	_WD_CapabilitiesAdd('timeouts', 'script', 300) ; https://www.w3.org/TR/webdriver/#timeouts
	_WD_CapabilitiesAdd('timeouts', 'pageLoad', 30000) ; https://www.w3.org/TR/webdriver/#timeouts
	_WD_CapabilitiesAdd('timeouts', 'implicit', 4) ; https://www.w3.org/TR/webdriver/#timeouts
	If $_EXAMPLE_OPTION_PROXY Then
		_WD_CapabilitiesAdd('proxy', 'proxyType', 'manual')
		_WD_CapabilitiesAdd('proxy', 'proxyAutoconfigUrl', '127.0.0.1') ; change '127.0.0.1' to your own 'proxyAutoconfigUrl' host
		_WD_CapabilitiesAdd('proxy', 'ftpProxy', '127.0.0.1') ; change '127.0.0.1' to your own 'ftpProxy' host
		_WD_CapabilitiesAdd('proxy', 'httpProxy', '127.0.0.1') ; change '127.0.0.1' to your own 'httpProxy' host
		_WD_CapabilitiesAdd('proxy', 'noProxy', 'www.w3.org') ; an example url which should not to bo opened via proxy server
		_WD_CapabilitiesAdd('proxy', 'noProxy', 'www.autoitscript.com') ; an example url which should not to bo opened via proxy server
		_WD_CapabilitiesAdd('proxy', 'noProxy', 'www.google.com') ; an example url which should not to bo opened via proxy server
		_WD_CapabilitiesAdd('proxy', 'noProxy', 'www.google.pl') ; an example url which should not to bo opened via proxy server
		_WD_CapabilitiesAdd('proxy', 'sslProxy', '127.0.0.1') ; change '127.0.0.1' to your own 'sslProxy' host
		_WD_CapabilitiesAdd('proxy', 'socksProxy', '127.0.0.1') ; change '127.0.0.1' to your own 'socksProxy' host
		_WD_CapabilitiesAdd('proxy', 'socksVersion', 1)
	EndIf
	#TODO check why 'WIN10' have issue when using FireFox - with the commented following line
;~ 	_WD_CapabilitiesAdd('platformName', 'WIN10') ; https://stackoverflow.com/a/45621125/5314940
	_WD_CapabilitiesDump(@ScriptLineNumber)
	#EndRegion - 	_WD_Capabilities_Example() ... "alwaysMatch" section

	#Region - 	_WD_Capabilities_Example() ... "firstMatch" section for Microsoft Edge
	If $_EXAMPLE_OPTION_ALLCAPS Or $_EXAMPLE_OPTION_CHOOSEN_DRIVER = $_EXAMPLE_DRIVER_EDGE Then
		; https://docs.microsoft.com/en-us/microsoft-edge/webdriver-chromium/capabilities-edge-options
		ConsoleWrite("! @ScriptLineNumber = " & @ScriptLineNumber & @CRLF)
		_WD_CapabilitiesAdd('firstMatch', 'edge')
		_WD_CapabilitiesDump(@ScriptLineNumber)
		#TODO CHECK .... "invalid argument: entry 0 of 'firstMatch' is invalid\nfrom invalid argument: unrecognized capability: browsername"
;~ 		_WD_CapabilitiesAdd('browsername', 'edge')
		#TODO CHECK .... How to use 'WIN10'
;~ 		_WD_CapabilitiesAdd('platformName', 'WIN10')
		_WD_CapabilitiesAdd('w3c', True)
		#TODO CHECK .... How to use 'maxInstances'
;~ 		_WD_CapabilitiesAdd('maxInstances', 1) ; https://stackoverflow.com/a/45621125/5314940
		If $_EXAMPLE_OPTION_HEADLESS Then _
				_WD_CapabilitiesAdd('args', '--headless')
		_WD_CapabilitiesAdd('prefs', 'plugins.always_open_pdf_externally', True) ; https://www.autoitscript.com/forum/topic/205553-webdriver-udf-help-support-iii/?do=findComment&comment=1482786
		_WD_CapabilitiesAdd('prefs', 'edge.sleeping_tabs.enabled', False) ; https://www.autoitscript.com/forum/topic/205553-webdriver-udf-help-support-iii/?do=findComment&comment=1482798
		_WD_CapabilitiesDump(@ScriptLineNumber)
	EndIf
	#EndRegion - 	_WD_Capabilities_Example() ... "firstMatch" section for Microsoft Edge

	#Region - 	_WD_Capabilities_Example() ... "firstMatch" section for Microsoft Google Chrome
	If $_EXAMPLE_OPTION_ALLCAPS Or $_EXAMPLE_OPTION_CHOOSEN_DRIVER = $_EXAMPLE_DRIVER_CHROME Then
		ConsoleWrite("! @ScriptLineNumber = " & @ScriptLineNumber & @CRLF)
		_WD_CapabilitiesAdd('firstMatch', 'chrome')
		#TODO ADD REMARK about:   "firstMatch key shadowed a value in alwaysMatch"
		_WD_CapabilitiesAdd('browserName', 'chrome')
;~ 		_WD_CapabilitiesAdd('platformName', 'WIN10')
		_WD_CapabilitiesAdd('w3c', True)
		#TODO check how to use 'binary'
		# _WD_CapabilitiesAdd('binary', 'c:\Program Files (x86)\Mozilla Firefox\firefox.exe')
		If $_EXAMPLE_OPTION_HEADLESS Then _
				_WD_CapabilitiesAdd('args', '--headless')
		_WD_CapabilitiesAdd('args', 'start-maximized')
		_WD_CapabilitiesAdd('args', 'disable-infobars')
		_WD_CapabilitiesAdd('args', 'user-data-dir', $_EXAMPLE_PROFILE_CHROME)
		_WD_CapabilitiesAdd('args', '--profile-directory', Default)
		_WD_CapabilitiesAdd('excludeSwitches', 'disable-popup-blocking') ; https://help.applitools.com/hc/en-us/articles/360007189411--Chrome-is-being-controlled-by-automated-test-software-notification
		_WD_CapabilitiesAdd('excludeSwitches', 'enable-automation')
		_WD_CapabilitiesAdd('excludeSwitches', 'load-extension')
		_WD_CapabilitiesDump(@ScriptLineNumber)
	EndIf
	#EndRegion - 	_WD_Capabilities_Example() ... "firstMatch" section for Microsoft Google Chrome

	#Region - 	_WD_Capabilities_Example() ... "firstMatch" section for FireFox
	If $_EXAMPLE_OPTION_ALLCAPS Or $_EXAMPLE_OPTION_CHOOSEN_DRIVER = $_EXAMPLE_DRIVER_FIREFOX Then
		ConsoleWrite("! @ScriptLineNumber = " & @ScriptLineNumber & @CRLF)
		_WD_CapabilitiesAdd('firstMatch', 'firefox')
		_WD_CapabilitiesAdd('browserName', 'firefox')

		If $_EXAMPLE_OPTION_HEADLESS Then _
				_WD_CapabilitiesAdd('args', '--headless')
		_WD_CapabilitiesAdd('args', '-profile')
		_WD_CapabilitiesAdd('args', $_EXAMPLE_PROFILE_FIREFOX)
		_WD_CapabilitiesAdd('prefs', 'download.default_directory', @ScriptDir)
		_WD_CapabilitiesAdd('prefs', 'dom.ipc.processCount', 8)
		_WD_CapabilitiesAdd('prefs', 'javascript.options.showInConsole', False)
		_WD_CapabilitiesAdd('prefs', 'browser.toolbars.bookmarks.visibility', 'always') ; check    about:config
		_WD_CapabilitiesAdd('prefs', 'app.update.download.attempts', 0) ; check    about:config
		_WD_CapabilitiesAdd('prefs', 'browser.safebrowsing.downloads.enabled', False) ; check    about:config
		_WD_CapabilitiesAdd('prefs', 'browser.safebrowsing.downloads.enabled', False) ; check    about:config
		; https://tarunlalwani.com/post/change-profile-settings-at-runtime-firefox-selenium/
		# 0 means to download to the desktop, 1 means to download to the default "Downloads" directory, 2 means to use the directory
		_WD_CapabilitiesAdd('prefs', 'browser.download.folderList', 2)
		_WD_CapabilitiesAdd('prefs', 'browser.download.manager.showWhenStarting', False)
		_WD_CapabilitiesAdd('prefs', 'browser.download.dir', $_EXAMPLE_DOWNLOAD_DIR)
		_WD_CapabilitiesAdd('prefs', 'browser.helperApps.neverAsk.saveToDisk', 'application/x-gzip')
		_WD_CapabilitiesAdd('prefs', 'browser.helperApps.neverAsk.saveToDisk', 'application/zip')

		_WD_CapabilitiesAdd('log', 'level', 'trace')

		_WD_CapabilitiesAdd('env', 'MOZ_LOG', 'nsHttp:5')
		_WD_CapabilitiesAdd('env', 'MOZ_LOG_FILE', $_EXAMPLE_PROFILE_FIREFOX & '\log')
		_WD_CapabilitiesDump(@ScriptLineNumber)
	EndIf
	#EndRegion - 	_WD_Capabilities_Example() ... "firstMatch" section for FireFox

	_WD_CapabilitiesDisplay(@ScriptLineNumber)

	If Not $_EXAMPLE_OPTION_RUN_BROWSER Then Return

	_WD_Option('Driver', $_EXAMPLE_OPTION_CHOOSEN_DRIVER)
	If $_EXAMPLE_OPTION_CHOOSEN_DRIVER = $_EXAMPLE_DRIVER_FIREFOX Then _WD_Option('Port', 4444)
	If $_EXAMPLE_OPTION_CHOOSEN_DRIVER = $_EXAMPLE_DRIVER_CHROME Then _WD_Option('Port', 9515)
	If $_EXAMPLE_OPTION_CHOOSEN_DRIVER = $_EXAMPLE_DRIVER_EDGE Then _WD_Option('Port', 9515)
	_WD_Startup()

	Local $s_Capabilities_JSON = _WD_CapabilitiesGet()
;~ 	Local $s_Capabilities_JSON = _WD_CapabilitiesGet()
	ConsoleWrite("! $s_Capabilities_JSON = " & $s_Capabilities_JSON & @CRLF)

	Local $WD_SESSION = _WD_CreateSession($s_Capabilities_JSON)
	If Not @Compiled Then MsgBox($MB_OK + $MB_TOPMOST + $MB_ICONINFORMATION, "Information #" & @ScriptLineNumber, "Waiting before _WD_Shutdown()")
	_WD_DeleteSession($WD_SESSION)
	_WD_Shutdown()

EndFunc   ;==>_WD_Capabilities_Example

Func _WD_Capabilities_Example_ChooseDriver()
	Local $_CHOOSEN_DRIVER = ''
	If $IDYES = MsgBox($MB_YESNO + $MB_TOPMOST + $MB_ICONQUESTION + $MB_DEFBUTTON1, "Question", _
			"Do you want to use FireFox browser") Then
		$_CHOOSEN_DRIVER = $_EXAMPLE_DRIVER_FIREFOX
	ElseIf $IDYES = MsgBox($MB_YESNO + $MB_TOPMOST + $MB_ICONQUESTION + $MB_DEFBUTTON1, "Question", _
			"Do you want to use Google Chrome browser") Then
		$_CHOOSEN_DRIVER = $_EXAMPLE_DRIVER_CHROME
	ElseIf $IDYES = MsgBox($MB_YESNO + $MB_TOPMOST + $MB_ICONQUESTION + $MB_DEFBUTTON1, "Question", _
			"Do you want to use Miscrosoft Edge browser") Then
		$_CHOOSEN_DRIVER = $_EXAMPLE_DRIVER_EDGE
	EndIf
	If Not FileExists($_CHOOSEN_DRIVER) Then
		MsgBox($MB_OK + $MB_TOPMOST + $MB_ICONERROR, "! Error occurred", _
				"WebDriver file:" & @CRLF & _
				$_CHOOSEN_DRIVER & @CRLF & _
				"Not exist !" & @CRLF & _
				"")
		Exit
	EndIf
	ConsoleWrite("> USING: " & $_CHOOSEN_DRIVER & @CRLF)
	Return $_CHOOSEN_DRIVER
EndFunc   ;==>_WD_Capabilities_Example_ChooseDriver
