#include-once
; standard UDF's
#include <Array.au3>
#include <MsgBoxConstants.au3>
; WebDriver related UDF's
#include "JSON.au3" ; https://www.autoitscript.com/forum/topic/148114-a-non-strict-json-udf-jsmn
#include "wd_core.au3"

#Region wd_capabilities.au3 - UDF Header
; #INDEX# ========================================================================
; Title .........: wd_capabilities.au3
; AutoIt Version : v3.3.14.5
; Language ......: English
; Description ...: A collection of functions used to dynamically build the Capabilities string required to create a WebDriver session
; Author ........: mLipok
; Modified ......:
; URL ...........:
; Date ..........: 2022/03/17
; ================================================================================

#Region - wd_capabilities.au3 - Copyright
#CS
	* wd_capabilities.au3
	*
	* MIT License
	*
	* Copyright (c) 2022 Michał Lipok - @mLipok
	*
	* Permission is hereby granted, free of charge, to any person obtaining a copy
	* of this software and associated documentation files (the "Software"), to deal
	* in the Software without restriction, including without limitation the rights
	* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	* copies of the Software, and to permit persons to whom the Software is
	* furnished to do so, subject to the following conditions:
	*
	* The above copyright notice and this permission notice shall be included in all
	* copies or substantial portions of the Software.
	*
	* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	* SOFTWARE.
	*
#CE
#EndRegion - wd_capabilities.au3 - Copyright

#Region - wd_capabilities.au3 - thanks, remarks, comments:
#CS
; Author(s) .....: Michał Lipok - @mLipok
; AutoIt Version : v3.3.14.5
	- Jonathan Bennett and the AutoIt Team
	- Dan Pollak (@Danp2) for all his work on https://github.com/Danp2/WebDriver/
	- @trancexx for https://github.com/dragana-r/autoit-winhttp and https://www.autoitscript.com/forum/topic/84133-winhttp-functions/
	- @Ward for  https://www.autoitscript.com/forum/topic/148114-a-non-strict-json-udf-jsmn

	wd_capabilities.au3 UDF was originally designed by Michał Lipok : https://www.autoitscript.com/forum/topic/206576-wd_capabilitiesau3-support-topic-early-beta-version-work-in-progress/
	By mutual consent (mLipok + Danp2) for the sake of the entire project, it was decided that: first official release will be published on https://github.com/Danp2/WebDriver/
	Future project management will remain in the hands of Danp2
	mLipok will remain an active contributor to this project
#CE
#EndRegion - wd_capabilities.au3 - thanks, remarks, comments:

#Region - wd_capabilities.au3 - function list
#CS
	Core functions:
	_WD_CapabilitiesStartup()
	_WD_CapabilitiesAdd()
	_WD_CapabilitiesGet()

	Internal functions:
	__WD_CapabilitiesInitialize()
	__WD_CapabilitiesSwitch()
	__WD_CapabilitiesNotation()

	Helper Functions:
	_WD_CapabilitiesDump()
	_WD_CapabilitiesDisplay()
#CE

#EndRegion - wd_capabilities.au3 - function list

#EndRegion wd_capabilities.au3 - UDF Header

#Region - wd_capabilities.au3 UDF - Global's declarations
Global Enum _
		$_WD_CAPS__STANDARD__Type, _
		$_WD_CAPS__STANDARD__FirstIdx, _
		$_WD_CAPS__STANDARD__STRINGORBOOL, _
		$_WD_CAPS__STANDARD__PROXY, _
		$_WD_CAPS__STANDARD__TIMEOUTS, _
		$_WD_CAPS__SPECIFICVENDOR__ObjectName, _
		$_WD_CAPS__SPECIFICVENDOR__OPTS, _
		$_WD_CAPS__SPECIFICVENDOR__ARGS, _
		$_WD_CAPS__SPECIFICVENDOR__PREFS, _
		$_WD_CAPS__SPECIFICVENDOR__LOG, _
		$_WD_CAPS__SPECIFICVENDOR__ENV, _
		$_WD_CAPS__SPECIFICVENDOR__EXCSWITCH, _
		$_WD_CAPS__COUNTER

Global $_WD_CAPS__API[0][$_WD_CAPS__COUNTER]

Global Const $_WD_CAPS__STANDARD_LIST = _ ; this should be RegExpPattern
		'(?i)\A(browserName|browserVersion|platformName|acceptInsecureCerts|pageLoadStrategy|setWindowRect|strictFileInteractability|unhandledPromptBehavior)\Z'

Global Const $_WD_CAPS__ARRAY_HEADER_NAMES = _
		"STANDARD__Type" & "|" & _
		"STANDARD__FirstIdx" & "|" & _
		"STANDARD__STRINGORBOOL" & "|" & _
		"STANDARD__PROXY" & "|" & _
		"STANDARD__TIMEOUTS" & "|" & _
		"SPECIFICVENDOR__ObjectName" & "|" & _
		"SPECIFICVENDOR__OPTS" & "|" & _
		"SPECIFICVENDOR__ARGS" & "|" & _
		"SPECIFICVENDOR__PREFS" & "|" & _
		"SPECIFICVENDOR__LOG" & "|" & _
		"SPECIFICVENDOR__ENV" & "|" & _
		"SPECIFICVENDOR__EXCSWITCH" & "|" & _
		""

Global $_WD_CAPS__OBJECT
Global $_WD_CAPS__CURRENTIDX = -1
#EndRegion - wd_capabilities.au3 UDF - Global's declarations

#Region - wd_capabilities.au3 UDF - core functions
; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_CapabilitiesStartup
; Description ...: Clear Object and API $_WD_CAPS__API start creating new JSON string for WebDriver Capabilities
; Syntax ........: _WD_CapabilitiesStartup()
; Parameters ....: None
; Return values .: None
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_CapabilitiesStartup()
	$_WD_CAPS__OBJECT = ''
	ReDim $_WD_CAPS__API[0][$_WD_CAPS__COUNTER]
EndFunc   ;==>_WD_CapabilitiesStartup

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_CapabilitiesAdd
; Description ...: Add capablitities to JSON string
; Syntax ........: _WD_CapabilitiesAdd($key[, $value1 = ''[, $value2 = '']])
; Parameters ....: $key                 - one of the following
;                               | Standard:
;                               | 'browserName'
;                               | 'browserVersion'
;                               | 'platformName'
;                               | 'acceptInsecureCerts'
;                               | 'pageLoadStrategy'
;                               | 'setWindowRect'
;                               | 'strictFileInteractability'
;                               | 'unhandledPromptBehavior'
;                               | 'proxy'
;                               |
;                               | Additional:
;                               | 'args'
;                               | 'env'
;                               | 'excludeSwitches'
;                               | 'logs'
;                               | 'prefs'
;                               | 'timeouts'
;                               |
;                               | Special:
;                               | True (boolean) for specific vendor capabilities
;                               |
;                               | '' an empty string
;                  $value1              - [optional] a variant value. Default is ''.
;                  $value2              - [optional] a variant value. Default is ''.
; Return values .: None
; Author ........: mLipok
; Modified ......:
; Remarks .......: parameters $value1 and $value2 depend on the $key value, take a look on example link
; Related .......:
; Link ..........:
; Example .......: https://www.autoitscript.com/wiki/WebDriver#Advanced_Capabilities_example
; ===============================================================================================================================
Func _WD_CapabilitiesAdd($key, $value1 = '', $value2 = '')
	If $value1 = Default Then $value1 = 'default'
	If $value2 = Default Then $value2 = 'default'
	If StringInStr('alwaysMatch|firstMatch', $key) Then
		Local $iResult = __WD_CapabilitiesInitialize($key, $value1)
		If Not @error Then $_WD_CAPS__CURRENTIDX = $iResult
		Return SetError(@error, @extended, $_WD_CAPS__CURRENTIDX)
	EndIf
	If $_WD_CAPS__CURRENTIDX = -1 Then Return SetError(1) ; must be properly initialized

	#TODO use $value2 for "noProxy"  https://www.w3.org/TR/webdriver/#dfn-page-load-strategy
	Local $s_SpecificOptions_KeyName = $_WD_CAPS__API[$_WD_CAPS__CURRENTIDX][$_WD_CAPS__SPECIFICVENDOR__ObjectName]
	Local $s_Notation = ''
	If IsBool($key) And $key = True And $s_SpecificOptions_KeyName <> '' Then ; for adding capability in specific/vendor capabilities for example: goog:chromeOptions
		#REMARK here is support for => 'goog:chromeOptions' And 'ms:edgeOptions' And 'moz:firefoxOptions'
		#DOCUMENTATION goog:chromeOptions => ; https://sites.google.com/a/chromium.org/chromedriver/capabilities#TOC-Recognized-capabilities
		$s_Notation = __WD_CapabilitiesNotation($_WD_CAPS__SPECIFICVENDOR__OPTS)
		__WD_CapabilitiesSwitch($key, $value1, $value2)
		If $value1 <> '' Then
			$s_Notation &= '[' & $key & ']'
		EndIf
	ElseIf $key = 'excludeSwitches' Then ; for adding "excludeSwitches" capability in specific/vendor capabilities : ........
		$s_Notation = __WD_CapabilitiesNotation($_WD_CAPS__SPECIFICVENDOR__EXCSWITCH)
	ElseIf $key = 'timeouts' Then ; for adding "proxy" capability in standard capability : https://www.w3.org/TR/webdriver/#capabilities
		$s_Notation = __WD_CapabilitiesNotation($_WD_CAPS__STANDARD__TIMEOUTS)
		$s_Notation &= '[' & $value1 & ']' ; here is specified keyName in {timeouts} JSON OBJECT
		__WD_CapabilitiesSwitch($key, $value1, $value2)
	ElseIf $key = 'proxy' Then ; for adding "proxy" capability in standard capabilities : https://www.w3.org/TR/webdriver/#dfn-proxy-configuration
		$s_Notation = __WD_CapabilitiesNotation($_WD_CAPS__STANDARD__PROXY)
		If $value1 = 'noProxy' Then ; for add string to "noProxy" JSON ARRAY in standard capabilities : https://www.w3.org/TR/webdriver/#dfn-proxy-configuration
			$_WD_CAPS__API[$_WD_CAPS__CURRENTIDX][$_WD_CAPS__STANDARD__PROXY] += 1 ; default is -1 so first should be 0
			Local $i_Current_noProxy = $_WD_CAPS__API[$_WD_CAPS__CURRENTIDX][$_WD_CAPS__STANDARD__PROXY]
			$s_Notation &= '[noProxy][' & $i_Current_noProxy & ']' ; here is specified which one of [noProxy] JSON ARRAY element should be used
		Else
			$s_Notation &= '[' & $value1 & ']' ; here is specified keyName in {proxy} JSON OBJECT
		EndIf
		__WD_CapabilitiesSwitch($key, $value1, $value2)
;~ 		If Not @Compiled Then __WD_ConsoleWrite("- IFNC: " & @ScriptLineNumber & ' $s_Notation =' & $s_Notation)
	ElseIf $key = 'args' Then ; for adding "args" capability in specific/vendor capabilities
		$s_Notation = __WD_CapabilitiesNotation($_WD_CAPS__SPECIFICVENDOR__ARGS)
		__WD_CapabilitiesSwitch($key, $value1, $value2)
		If $value1 Then
			$value1 = $key & '=' & $value1
		Else
			$value1 = $key
		EndIf
;~ 		If Not @Compiled Then __WD_ConsoleWrite("- IFNC: " & @ScriptLineNumber & ' $s_Notation =' & $s_Notation)
;~ 		If Not @Compiled Then __WD_ConsoleWrite("- IFNC: " & @ScriptLineNumber & ' $s_Notation =' & $s_Notation & ' = ' & $value1)
	ElseIf $key = 'prefs' Then ; for adding "prefs" capability in specific/vendor capabilities
		$s_Notation = __WD_CapabilitiesNotation($_WD_CAPS__SPECIFICVENDOR__PREFS)
		__WD_CapabilitiesSwitch($key, $value1, $value2)
		$s_Notation &= '[' & $key & ']'
;~ 		If Not @Compiled Then __WD_ConsoleWrite("- IFNC: " & @ScriptLineNumber & ' $s_Notation =' & $s_Notation)
	ElseIf $key = 'log' Then ; for adding "log" capability in specific/vendor capabilities
		$s_Notation = __WD_CapabilitiesNotation($_WD_CAPS__SPECIFICVENDOR__LOG)
		__WD_CapabilitiesSwitch($key, $value1, $value2)
		$s_Notation &= '[' & $key & ']'
;~ 		If Not @Compiled Then __WD_ConsoleWrite("- IFNC: " & @ScriptLineNumber & ' $s_Notation =' & $s_Notation)
	ElseIf $key = 'env' Then ; for adding "env" capability in specific/vendor capabilities
		$s_Notation = __WD_CapabilitiesNotation($_WD_CAPS__SPECIFICVENDOR__ENV)
		__WD_CapabilitiesSwitch($key, $value1, $value2)
		$s_Notation &= '[' & $key & ']'
;~ 		If Not @Compiled Then __WD_ConsoleWrite("- IFNC: " & @ScriptLineNumber & ' $s_Notation =' & $s_Notation)
	ElseIf $value2 = '' And StringRegExp($key, $_WD_CAPS__STANDARD_LIST, $STR_REGEXPMATCH) Then ; for string/boolean value type in standard capability : https://www.w3.org/TR/webdriver/#capabilities
		$s_Notation = __WD_CapabilitiesNotation($_WD_CAPS__STANDARD__STRINGORBOOL)
		$s_Notation &= '[' & $key & ']'
	Else ; not supported option
		Return SetError(1)
	EndIf
	If @error Then Return SetError(@error, @extended, $s_Notation)
	Json_Put($_WD_CAPS__OBJECT, $s_Notation, $value1)
;~ 	If Not @compiled Then __WD_ConsoleWrite("> $s_Notation - " & $s_Notation)
EndFunc   ;==>_WD_CapabilitiesAdd

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_CapabilitiesGet
; Description ...: Get the JSON string
; Syntax ........: _WD_CapabilitiesGet()
; Parameters ....: None
; Return values .: JSON string
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_CapabilitiesGet()
	Local $Data2 = Json_Encode($_WD_CAPS__OBJECT)
	Local $Data1 = Json_Decode($Data2)
	Local $Json2 = Json_Encode($Data1, $Json_UNQUOTED_STRING)
	Local $Data3 = Json_Decode($Json2)
	Local $Json3 = Json_Encode($Data3, $Json_PRETTY_PRINT, "    ", ",\n", ",\n", ":")
	Return $Json3
EndFunc   ;==>_WD_CapabilitiesGet
#EndRegion - wd_capabilities.au3 UDF - core functions

#Region - wd_capabilities.au3 UDF - internal functions
; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_CapabilitiesInitialize
; Description ...: Initialize $_WD_CAPS__API and presets for 'alwaysMatch' Or 'firstMatch'
; Syntax ........: __WD_CapabilitiesInitialize($s_MatchType[, $s_BrowserName = ''])
; Parameters ....: $s_MatchType         - a string value. 'alwaysMatch' Or 'firstMatch'.
;                  $s_BrowserName - [optional] The browser name as defined in $_WD_SupportedBrowsers. Default is ''
; Return values .: None, or set @error
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WD_CapabilitiesInitialize($s_MatchType, $s_BrowserName = '') ; $s_MatchType = 'alwaysMatch' Or 'firstMatch'
	#Region - parameters validation
	If Not StringInStr('alwaysMatch|firstMatch', $s_MatchType) Then _
			Return SetError(1)

	Local $s_SpecificOptions_KeyName = ''

	If $s_BrowserName <> '' Then
		Local $iIndex = _ArraySearch($_WD_SupportedBrowsers, StringLower($s_BrowserName), Default, Default, Default, Default, Default, $_WD_BROWSER_Name)
		If @error Then
			Return SetError(2) ; $_WD_ERROR_NotSupported
		EndIf
		$s_SpecificOptions_KeyName = $_WD_SupportedBrowsers[$iIndex][$_WD_BROWSER_OptionsKey]
	ElseIf $s_MatchType = 'alwaysMatch' And $s_BrowserName = '' Then
		$s_SpecificOptions_KeyName = ''
	ElseIf $s_MatchType = 'firstMatch' And $s_BrowserName = '' Then
		Return SetError(3)
;~ 	Else
;~ 		Return SetError(4) ; this should be tested/reviewed later (@mLipok 23-02-2022)
	EndIf
	#EndRegion - parameters validation

	#Region - reindexing API
	Local $i_API_Recent_Size = UBound($_WD_CAPS__API), $i_API_New_Size = $i_API_Recent_Size + 1, $i_API_New_IDX = $i_API_New_Size - 1
	ReDim $_WD_CAPS__API[$i_API_New_Size][$_WD_CAPS__COUNTER]
	#EndRegion - reindexing API

	#Region - new "MATCH" Initialization
	$_WD_CAPS__API[$i_API_New_IDX][$_WD_CAPS__STANDARD__Type] = $s_MatchType
	Local Static $i_FirstMatch_Counter = -1
	If $s_MatchType = 'firstMatch' Then
		$i_FirstMatch_Counter += 1 ; default is -1 so first should be 0
		$_WD_CAPS__API[$i_API_New_IDX][$_WD_CAPS__STANDARD__FirstIdx] = $i_FirstMatch_Counter
	EndIf
	$_WD_CAPS__API[$i_API_New_IDX][$_WD_CAPS__STANDARD__STRINGORBOOL] = Null
	$_WD_CAPS__API[$i_API_New_IDX][$_WD_CAPS__STANDARD__PROXY] = -1 ; used for indexing ......  "noProxy" : [JSON ARRRAY]
	$_WD_CAPS__API[$i_API_New_IDX][$_WD_CAPS__SPECIFICVENDOR__ObjectName] = $s_SpecificOptions_KeyName
	$_WD_CAPS__API[$i_API_New_IDX][$_WD_CAPS__SPECIFICVENDOR__OPTS] = Null
	$_WD_CAPS__API[$i_API_New_IDX][$_WD_CAPS__SPECIFICVENDOR__ARGS] = -1 ; used for indexing ......  "args" : [JSON ARRRAY]
	$_WD_CAPS__API[$i_API_New_IDX][$_WD_CAPS__SPECIFICVENDOR__PREFS] = Null
	$_WD_CAPS__API[$i_API_New_IDX][$_WD_CAPS__SPECIFICVENDOR__LOG] = Null
	$_WD_CAPS__API[$i_API_New_IDX][$_WD_CAPS__SPECIFICVENDOR__ENV] = Null
	$_WD_CAPS__API[$i_API_New_IDX][$_WD_CAPS__SPECIFICVENDOR__EXCSWITCH] = -1 ; used for indexing ......  "excludeSwitches" : [JSON ARRRAY]
	$_WD_CAPS__CURRENTIDX = $i_API_New_IDX ; set last API IDX as CURRENT API IDX
	#EndRegion - new "MATCH" Initialization
	Return $_WD_CAPS__CURRENTIDX ; return current API IDX

	#Region - FOR TESTING ONLY
	Local $s_Information = _
			"$s_BrowserName = " & $s_BrowserName & @CRLF & _
			"$s_MatchType = " & $s_MatchType & @CRLF & _
			"$s_SpecificOptions_KeyName = " & $s_SpecificOptions_KeyName & @CRLF & _
			"$i_FirstMatch_Counter = " & $i_FirstMatch_Counter & @CRLF & _
			"$_WD_CAPS__CURRENTIDX = " & $_WD_CAPS__CURRENTIDX & @CRLF & _
			''
	If Not @Compiled Then MsgBox($MB_OK + $MB_TOPMOST + $MB_ICONINFORMATION, "Information #" & @ScriptLineNumber, $s_Information)
	#EndRegion - FOR TESTING ONLY
EndFunc   ;==>__WD_CapabilitiesInitialize

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_CapabilitiesSwitch
; Description ...: switching parameters position to the left
; Syntax ........: __WD_CapabilitiesSwitch(Byref $key, Byref $value1, Byref $value2)
; Parameters ....: $key                 - [in/out] an unknown value.
;                  $value1              - [in/out] a variant value.
;                  $value2              - [in/out] a variant value.
; Return values .: None
; Author ........: mLipok
; Modified ......:
; Remarks .......: When notation is modified in most cases parameters need to be switched for further processing
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WD_CapabilitiesSwitch(ByRef $key, ByRef $value1, ByRef $value2)
	$key = $value1
	$value1 = $value2
	$value2 = ''
EndFunc   ;==>__WD_CapabilitiesSwitch

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_CapabilitiesNotation
; Description ...: get desired notation prefix for specitfied JSON object
; Syntax ........: __WD_CapabilitiesNotation($i_BUILDER_TYPE)
; Parameters ....: $i_BUILDER_TYPE      - an integer value. One of $_WD_CAPS__** enums
; Return values .: notation prefix in Json.au3 format
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WD_CapabilitiesNotation($i_BUILDER_TYPE)
;~ 	MsgBox($MB_OK + $MB_TOPMOST + $MB_ICONINFORMATION, "Information #" & @ScriptLineNumber, "$_WD_CAPS__CURRENTIDX = " & $_WD_CAPS__CURRENTIDX &  ' Ubound = ' & UBound($_WD_CAPS__API))
	Local $s_CurrentMatch_Type = '[' & $_WD_CAPS__API[$_WD_CAPS__CURRENTIDX][$_WD_CAPS__STANDARD__Type] & ']'
	If $s_CurrentMatch_Type = '[firstMatch]' Then
		$s_CurrentMatch_Type &= '[' & $_WD_CAPS__API[$_WD_CAPS__CURRENTIDX][$_WD_CAPS__STANDARD__FirstIdx] & ']'
	EndIf

	Local $s_SpecificOptions_KeyName = $_WD_CAPS__API[$_WD_CAPS__CURRENTIDX][$_WD_CAPS__SPECIFICVENDOR__ObjectName]
	If $s_SpecificOptions_KeyName Then $s_SpecificOptions_KeyName = '["' & $s_SpecificOptions_KeyName & '"]'

	If $s_SpecificOptions_KeyName = '' And $i_BUILDER_TYPE >= $_WD_CAPS__SPECIFICVENDOR__ARGS Then _
			Return SetError(1, 0, '') ; ARGS, PREFS, LOG, ENV and any further are possible only when Specific/Vendor Capability was specified

	Local $s_Notation = ''
	Switch $i_BUILDER_TYPE
		Case $_WD_CAPS__STANDARD__STRINGORBOOL
			$s_Notation = '[capabilities]' & $s_CurrentMatch_Type
		Case $_WD_CAPS__STANDARD__PROXY
			$s_Notation = '[capabilities]' & $s_CurrentMatch_Type & '[proxy]' ; here is specified the name for {proxy} JSON OBJECT
		Case $_WD_CAPS__STANDARD__TIMEOUTS
			$s_Notation = '[capabilities]' & $s_CurrentMatch_Type & '[timeouts]' ; here is specified the name for {timeout} JSON OBJECT
		Case $_WD_CAPS__SPECIFICVENDOR__OPTS
			$s_Notation = '[capabilities]' & $s_CurrentMatch_Type & $s_SpecificOptions_KeyName ; here is specified the name for {SPECIFIC VENDOR NAME} JSON OBJECT
		Case $_WD_CAPS__SPECIFICVENDOR__ARGS
			$_WD_CAPS__API[$_WD_CAPS__CURRENTIDX][$_WD_CAPS__SPECIFICVENDOR__ARGS] += 1 ; default is -1 so first should be 0
			Local $i_Current_Arg = $_WD_CAPS__API[$_WD_CAPS__CURRENTIDX][$_WD_CAPS__SPECIFICVENDOR__ARGS]
			$s_Notation = '[capabilities]' & $s_CurrentMatch_Type & $s_SpecificOptions_KeyName & '[args][' & $i_Current_Arg & ']' ; here is specified which one of [args] JSON ARRAY element should be used
		Case $_WD_CAPS__SPECIFICVENDOR__PREFS
			$s_Notation = '[capabilities]' & $s_CurrentMatch_Type & $s_SpecificOptions_KeyName & '[prefs]' ; here is specified the name for {prefs} JSON OBJECT
		Case $_WD_CAPS__SPECIFICVENDOR__LOG
			$s_Notation = '[capabilities]' & $s_CurrentMatch_Type & $s_SpecificOptions_KeyName & '[log]' ; here is specified the name for {log} JSON OBJECT
		Case $_WD_CAPS__SPECIFICVENDOR__ENV
			$s_Notation = '[capabilities]' & $s_CurrentMatch_Type & $s_SpecificOptions_KeyName & '[env]' ; here is specified the name for {env} JSON OBJECT
		Case $_WD_CAPS__SPECIFICVENDOR__EXCSWITCH
			$_WD_CAPS__API[$_WD_CAPS__CURRENTIDX][$_WD_CAPS__SPECIFICVENDOR__EXCSWITCH] += 1 ; default is -1 so first should be 0
			Local $i_Current_ExcSwitch = $_WD_CAPS__API[$_WD_CAPS__CURRENTIDX][$_WD_CAPS__SPECIFICVENDOR__EXCSWITCH]
			$s_Notation = '[capabilities]' & $s_CurrentMatch_Type & $s_SpecificOptions_KeyName & '[excludeSwitches][' & $i_Current_ExcSwitch & ']' ; here is specified which one of [excluedSwitches] JSON ARRAY element should be used
	EndSwitch
;~ 	If Not @compiled Then __WD_ConsoleWrite("- IFNC: " & @ScriptLineNumber & ' $s_Notation =' & $s_Notation)
	Return $s_Notation
EndFunc   ;==>__WD_CapabilitiesNotation
#EndRegion - wd_capabilities.au3 UDF - internal functions

#Region - wd_capabilities.au3 UDF - helper functions
; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_CapabilitiesDump
; Description ...: Dump $_WD_CAPS__API and JSON string to console
; Syntax ........: _WD_CapabilitiesDump($s_Comment)
; Parameters ....: $s_Comment           - a string value.
; Return values .: None
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_CapabilitiesDump($s_Comment)
	If @Compiled Then Return ; because of GDRP reason do not throw nothing to console when compiled script
	If $_WD_DEBUG <> $_WD_DEBUG_None Then
		__WD_ConsoleWrite('! _WD_Capabilities: API START: ' & $s_Comment)
		__WD_ConsoleWrite("- $_WD_CAPS__API: Rows= " & UBound($_WD_CAPS__API, 1))
		__WD_ConsoleWrite("- $_WD_CAPS__API: Cols= " & UBound($_WD_CAPS__API, 2))
		__WD_ConsoleWrite(_ArrayToString($_WD_CAPS__API))
		__WD_ConsoleWrite('! _WD_Capabilities: API END: ' & $s_Comment)

		__WD_ConsoleWrite('! _WD_Capabilities: JSON START: ' & $s_Comment)
		__WD_ConsoleWrite(_WD_CapabilitiesGet())
		__WD_ConsoleWrite('! _WD_Capabilities: JSON END: ' & $s_Comment)
	EndIf
EndFunc   ;==>_WD_CapabilitiesDump

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_CapabilitiesDisplay
; Description ...: Display the current content of $_WD_CAPS__API
; Syntax ........: _WD_CapabilitiesDisplay($s_Comment)
; Parameters ....: $s_Comment           - a string value.
; Return values .: None
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_CapabilitiesDisplay($s_Comment)
	Local $s_Title = $s_Comment & ' $_WD_CAPS__API  Rows= ' & UBound($_WD_CAPS__API, 1) & ' Cols= ' & UBound($_WD_CAPS__API, 2) & @LF
	_ArrayDisplay($_WD_CAPS__API, $s_Title, "", Default, Default, $_WD_CAPS__ARRAY_HEADER_NAMES)
EndFunc   ;==>_WD_CapabilitiesDisplay
#EndRegion - wd_capabilities.au3 UDF - helper functions
