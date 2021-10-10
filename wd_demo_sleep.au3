#include <ButtonConstants.au3>
#include <GuiComboBoxEx.au3>
#include <GUIConstantsEx.au3>
#include <MsgBoxConstants.au3>
#include <WindowsConstants.au3>
#include "wd_helper.au3"

Global $idAbortTest
_Example()

Func _Example()
	_WD_Startup()
	Local $sCapabilities = SetupChrome()
	Local $WD_SESSION = _WD_CreateSession($sCapabilities)
	_WD_Timeouts($WD_SESSION, 40000)

	; Create a GUI with various controls.
	Local $hGUI = GUICreate("Example")
	Local $idTest = GUICtrlCreateButton("Test", 10, 370, 85, 25)
	$idAbortTest = GUICtrlCreateButton("Abort", 150, 370, 85, 25)

	; Display the GUI.
	GUISetState(@SW_SHOW, $hGUI)

	ConsoleWrite("- TESTING" & @CRLF)

	_WD_Option("Sleep", _My_Sleep)
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

Func _My_Sleep($v_Parameter)
	Local $hTimer = TimerInit() ; Begin the timer and store the handle in a variable.
	Do
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE
				ConsoleWrite("! USER EXIT" & @CRLF)
				Exit
			Case $idAbortTest
				Return SetError($_WD_ERROR_UserAbort)
		EndSwitch
	Until TimerDiff($hTimer) > $v_Parameter
EndFunc   ;==>_My_Sleep

Func _WriteTestHtml($sFilePath = @ScriptDir & "\TestFile.html")
	FileDelete($sFilePath)
	Local Const $sHtml = _
			'<html lang="en">' & @CRLF & _
			'    <head>' & @CRLF & _
			'        <meta charset="utf-8">' & @CRLF & _
			'        <title>TESTING</title>' & @CRLF & _
			'    </head>' & @CRLF & _
			'    <body>' & @CRLF & _
			'        <div id="MyLink">Waiting</div>' & @CRLF & _
			'    </body>' & @CRLF & _
			'    <script type="text/javascript">' & @CRLF & _
			'    setTimeout(function()' & @CRLF & _
			'    {' & @CRLF & _
			'        // Delayed code in here' & @CRLF & _
			'        document.getElementById("MyLink").innerHTML="<a>TESTING</a>";' & @CRLF & _
			'    }, 20000); // 20000 = 20 seconds' & @CRLF & _
			'    </script>' & @CRLF & _
			'</html>'
	FileWrite($sFilePath, $sHtml)
	Return "file:///" & StringReplace($sFilePath, "\", "/")
EndFunc   ;==>_WriteTestHtml

Func SetupChrome()
	_WD_Option('Driver', 'chromedriver.exe')
	_WD_Option('Port', 9515)
	_WD_Option('HTTPTimeouts', 40000)
	_WD_Option('DefaultTimeout', 40000)
	_WD_Option('DriverParams', '--verbose --log-path="' & @ScriptDir & '\chrome.log"')

	Return '{"capabilities": {"alwaysMatch": {"goog:chromeOptions": {"w3c": true, "excludeSwitches": [ "enable-automation"]}}}}'
EndFunc   ;==>SetupChrome
