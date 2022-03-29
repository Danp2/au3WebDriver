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
; Date ..........: 2022/03/21
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
		$_WD_CAPS__STANDARD__CURRENT, _
		$_WD_CAPS__SPECIFICVENDOR__ObjectName, _
		$_WD_CAPS__SPECIFICVENDOR__OPTS, _
		$_WD_CAPS__COUNTER

Global $_WD_CAPS__API[0][$_WD_CAPS__COUNTER]

Global $_WD_CAPS__LISTOF_STANDARD = _ ; this should be RegExpPattern
		'(?i)\A(acceptInsecureCerts|browserName|browserVersion|platformName|pageLoadStrategy|setWindowRect|strictFileInteractability|unhandledPromptBehavior)\Z'

Global $_WD_CAPS__LISTOF_STANDARD_OBJECT = _ ; this should be RegExpPattern
		'(?i)\A(proxy|timeouts)\Z'

Global $_WD_CAPS__LISTOF_STANDARD_OBJECT_ARRAY = _ ; this should be RegExpPattern
		'(?i)\A(noproxy)\Z'

Global $_WD_CAPS__LISTOF_SPECIFICVENDOR_STRING = _ ; this should be RegExpPattern
		'(?i)\A(binary|debuggerAddress|minidumpPath)\Z'

Global $_WD_CAPS__LISTOF_SPECIFICVENDOR_BOOLEAN = _ ; this should be RegExpPattern
		'(?i)\A(w3c|detach)\Z'

Global $_WD_CAPS__LISTOF_SPECIFICVENDOR_ARRAY = _ ; this should be RegExpPattern
		'(?i)\A(args|extensions|excludeSwitches|windowTypes)\Z'

Global $_WD_CAPS__LISTOF_SPECIFICVENDOR_OBJECT = _ ; this should be RegExpPattern
		'(?i)\A(env|log|prefs|perfLoggingPrefs|mobileEmulation|localState)\Z'

Global Const $_WD_CAPS__ARRAY_HEADER_NAMES = _
		"STANDARD__Type" & "|" & _
		"STANDARD__FirstIdx" & "|" & _
		"STANDARD__CURRENT" & "|" & _
		"SPECIFICVENDOR__ObjectName" & "|" & _
		"SPECIFICVENDOR__OPTS" & "|" & _
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
;                               | 'timeouts'
;                               |
;                               | Additional:
;                               | 'args'
;                               | 'env'
;                               | 'excludeSwitches'
;                               | 'logs'
;                               | 'prefs'
;                               |
;                               | '' an empty string
;                  $value1              - [optional] a variant value. Default is ''.
;                  $value2              - [optional] a variant value. Default is ''.
; Return values .: None
; Author ........: mLipok
; Modified ......:
; Remarks .......: Parameters $value1 and $value2 depend on the $key value, take a look on example link
; Related .......:
; Link ..........:
; Example .......: https://www.autoitscript.com/wiki/WebDriver#Advanced_Capabilities_example
; ===============================================================================================================================
Func _WD_CapabilitiesAdd($key, $value1 = '', $value2 = '')
	If $value1 = Default Then $value1 = 'default'
	If $value2 = Default Then $value2 = 'default'
	Local Const $s_Parameters_Info = '     $key = ' & $key & '     $value1 = ' & $value1 & '     $value2 = ' & $value2

	If StringInStr('alwaysMatch|firstMatch', $key) Then
		If Not @Compiled Then ConsoleWrite("! IFNC: TESTING NEW FEATURES #" & @ScriptLineNumber & $s_Parameters_Info & @CRLF)
		Local $iResult = __WD_CapabilitiesInitialize($key, $value1)
		If Not @error Then $_WD_CAPS__CURRENTIDX = $iResult
		Return SetError(@error, @extended, $_WD_CAPS__CURRENTIDX)
	EndIf
	If $_WD_CAPS__CURRENTIDX = -1 Then Return SetError(1) ; must be properly initialized

;~ 	https://www.w3.org/TR/webdriver/#dfn-page-load-strategy
;~ 	https://www.w3.org/TR/webdriver/#dfn-table-of-page-load-strategies

	Local $s_SpecificOptions_KeyName = $_WD_CAPS__API[$_WD_CAPS__CURRENTIDX][$_WD_CAPS__SPECIFICVENDOR__ObjectName]
	Local $v_WatchPoint
	Local $s_Notation = ''


	If StringRegExp($key, $_WD_CAPS__LISTOF_STANDARD, $STR_REGEXPMATCH) Then ; for string/boolean value type in standard capability : https://www.w3.org/TR/webdriver/#capabilities
		If $value2 <> '' Then
			If Not @Compiled Then ConsoleWrite("! IFNC: TESTING NEW FEATURES #" & @ScriptLineNumber & $s_Parameters_Info & @CRLF)
			If Not @Compiled Then MsgBox($MB_OK + $MB_TOPMOST + $MB_ICONERROR, "ERROR #" & @ScriptLineNumber, $s_Parameters_Info)
			Return SetError($_WD_ERROR_NotSupported)
		EndIf
		$v_WatchPoint = @ScriptLineNumber
		$s_Notation = __WD_CapabilitiesNotation($_WD_CAPS__STANDARD__CURRENT) & '[' & $key & ']'

	ElseIf StringRegExp($key, $_WD_CAPS__LISTOF_STANDARD_OBJECT, $STR_REGEXPMATCH) Then ; for string/boolean value type in standard capability : https://www.w3.org/TR/webdriver/#capabilities
		$s_Notation = __WD_CapabilitiesNotation($_WD_CAPS__STANDARD__CURRENT)
		If Not StringRegExp($value1, $_WD_CAPS__LISTOF_STANDARD_OBJECT_ARRAY, $STR_REGEXPMATCH) Then ; if arrays ($value1) is child of the object ($key)
			$v_WatchPoint = @ScriptLineNumber
			$s_Notation &= '[' & $key & ']' & '[' & $value1 & ']'
		Else
			If $value2 <> '' Then
				$v_WatchPoint = @ScriptLineNumber
				$s_Notation &= '[' & $key & ']' & '[' & $value1 & ']'
				Local $iCurrent1 = UBound(Json_Get($_WD_CAPS__OBJECT, $s_Notation))
				SetError(0)
				$s_Notation &= '[' & $iCurrent1 & ']' ; here is specified which one of JSON ARRAY element should be used
			Else ; not supported option
				If Not @Compiled Then ConsoleWrite("! IFNC: TESTING NEW FEATURES #" & @ScriptLineNumber & $s_Parameters_Info & @CRLF)
				Return SetError($_WD_ERROR_NotSupported)
			EndIf
		EndIf
		$value1 = $value2 ; switch

	ElseIf StringRegExp($key, $_WD_CAPS__LISTOF_SPECIFICVENDOR_ARRAY, $STR_REGEXPMATCH) Then ; for string/boolean value type in standard capability : https://www.w3.org/TR/webdriver/#capabilities
		$v_WatchPoint = @ScriptLineNumber
		$s_Notation = __WD_CapabilitiesNotation($_WD_CAPS__SPECIFICVENDOR__OPTS)
		$s_Notation &= '[' & $key & ']'
		Local $iCurrent2 = UBound(Json_Get($_WD_CAPS__OBJECT, $s_Notation))
		SetError(0)
		$s_Notation &= '[' & $iCurrent2 & ']' ; here is specified which one of JSON ARRAY element should be used
		If $value2 Then
			$v_WatchPoint = @ScriptLineNumber
			$value1 &= '=' & $value2
		EndIf

	ElseIf StringRegExp($key, $_WD_CAPS__LISTOF_SPECIFICVENDOR_OBJECT, $STR_REGEXPMATCH) Then ; for string/boolean value type in standard capability : https://www.w3.org/TR/webdriver/#capabilities
		$v_WatchPoint = @ScriptLineNumber
		$s_Notation = __WD_CapabilitiesNotation($_WD_CAPS__SPECIFICVENDOR__OPTS)
		$s_Notation &= '[' & $key & ']' & '[' & $value1 & ']'
		$value1 = $value2 ; switch

	ElseIf StringRegExp($key, $_WD_CAPS__LISTOF_SPECIFICVENDOR_STRING, $STR_REGEXPMATCH) And $s_SpecificOptions_KeyName <> '' Then ; for adding capability in specific/vendor capabilities for example: goog:chromeOptions
		$v_WatchPoint = @ScriptLineNumber
		$s_Notation = __WD_CapabilitiesNotation($_WD_CAPS__SPECIFICVENDOR__OPTS)
		If $value1 <> '' Then $s_Notation &= '[' & $key & ']'

	ElseIf StringRegExp($key, $_WD_CAPS__LISTOF_SPECIFICVENDOR_BOOLEAN, $STR_REGEXPMATCH) And $s_SpecificOptions_KeyName <> '' Then ; for adding capability in specific/vendor capabilities for example: goog:chromeOptions
		$v_WatchPoint = @ScriptLineNumber
		$s_Notation = __WD_CapabilitiesNotation($_WD_CAPS__SPECIFICVENDOR__OPTS)
		If $value1 <> '' Then $s_Notation &= '[' & $key & ']'

	Else ; not supported option
		If Not @Compiled Then ConsoleWrite("! IFNC: TESTING NEW FEATURES #" & @ScriptLineNumber & $s_Parameters_Info & @CRLF)
		If Not @Compiled Then MsgBox($MB_OK + $MB_TOPMOST + $MB_ICONERROR, "ERROR #" & @ScriptLineNumber, $s_Parameters_Info)
		Return SetError($_WD_ERROR_NotSupported)
	EndIf
	If @error Then Return SetError(@error, @extended, $s_Notation)
	If Not @Compiled Then ConsoleWrite("! IFNC: TESTING NEW FEATURES #" & $v_WatchPoint & '/' & @ScriptLineNumber & ' ' & $s_Parameters_Info & '    $s_Notation = ' & $s_Notation & '   <<<<  ' & $value1 & @CRLF)
	Json_Put($_WD_CAPS__OBJECT, $s_Notation, $value1)
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
	Local $Data1 = Json_Encode($_WD_CAPS__OBJECT)
	
	Local $Data2 = Json_Decode($Data1)
	Local $Json2 = Json_Encode($Data2, $Json_UNQUOTED_STRING)
	
	Local $Data3 = Json_Decode($Json2)
	Local $Json3 = Json_Encode($Data3, $Json_PRETTY_PRINT, "    ", ",\n", ",\n", ":")
	
	Return $Json3
EndFunc   ;==>_WD_CapabilitiesGet

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_CapabilitiesNewType
; Description ...: Suplement $_WD_CAPS__LISTOF_* by adding new capability type
; Syntax ........: _WD_CapabilitiesNewType(Byref $s_LISTOF_CAPS, $sNewType)
; Parameters ....: $s_LISTOF_CAPS       - refrence to $_WD_CAPS__LISTOF_* value that should be suplemented by supporting new capability type
;                  $sNewType            - Name of new capbility type that should be supported
; Return values .: None
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_CapabilitiesNewType(ByRef $s_LISTOF_CAPS, $sNewType)
	Local Const $sFuncName = "_WD_CapabilitiesNewType"
	Local $sMessage = ''
	If _
			StringRegExp($sNewType, $_WD_CAPS__LISTOF_STANDARD, $STR_REGEXPMATCH) Or _
			StringRegExp($sNewType, $_WD_CAPS__LISTOF_STANDARD_OBJECT, $STR_REGEXPMATCH) Or _
			StringRegExp($sNewType, $_WD_CAPS__LISTOF_STANDARD_OBJECT_ARRAY, $STR_REGEXPMATCH) Or _
			StringRegExp($sNewType, $_WD_CAPS__LISTOF_SPECIFICVENDOR_STRING, $STR_REGEXPMATCH) Or _
			StringRegExp($sNewType, $_WD_CAPS__LISTOF_SPECIFICVENDOR_BOOLEAN, $STR_REGEXPMATCH) Or _
			StringRegExp($sNewType, $_WD_CAPS__LISTOF_SPECIFICVENDOR_ARRAY, $STR_REGEXPMATCH) Or _
			StringRegExp($sNewType, $_WD_CAPS__LISTOF_SPECIFICVENDOR_OBJECT, $STR_REGEXPMATCH) _
			Then
		$sMessage = 'Name of new capbility is already supported: ' & $sNewType
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidArgue, $sMessage, 0), 0)
	EndIf
	If _
			$s_LISTOF_CAPS <> $_WD_CAPS__LISTOF_STANDARD And _
			$s_LISTOF_CAPS <> $_WD_CAPS__LISTOF_STANDARD_OBJECT And _
			$s_LISTOF_CAPS <> $_WD_CAPS__LISTOF_STANDARD_OBJECT_ARRAY And _
			$s_LISTOF_CAPS <> $_WD_CAPS__LISTOF_SPECIFICVENDOR_STRING And _
			$s_LISTOF_CAPS <> $_WD_CAPS__LISTOF_SPECIFICVENDOR_BOOLEAN And _
			$s_LISTOF_CAPS <> $_WD_CAPS__LISTOF_SPECIFICVENDOR_ARRAY And _
			$s_LISTOF_CAPS <> $_WD_CAPS__LISTOF_SPECIFICVENDOR_OBJECT _
			Then
		$sMessage = 'Not supported type of capbility: ' & $s_LISTOF_CAPS
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_NotSupported, $sMessage, 0), 0)
	EndIf
	$s_LISTOF_CAPS = StringTrimRight($s_LISTOF_CAPS, 3) & '|' & $sNewType & ')\Z'
EndFunc   ;==>_WD_CapabilitiesNewType

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
			Return SetError($_WD_ERROR_NotSupported)

	Local $s_SpecificOptions_KeyName = ''

	If $s_BrowserName <> '' Then
		Local $iIndex = _ArraySearch($_WD_SupportedBrowsers, StringLower($s_BrowserName), Default, Default, Default, Default, Default, $_WD_BROWSER_Name)
		If @error Then
			Return SetError($_WD_ERROR_NotSupported) ; $_WD_ERROR_NotSupported
		EndIf
		$s_SpecificOptions_KeyName = $_WD_SupportedBrowsers[$iIndex][$_WD_BROWSER_OptionsKey]
	ElseIf $s_MatchType = 'alwaysMatch' And $s_BrowserName = '' Then
		$s_SpecificOptions_KeyName = ''
	ElseIf $s_MatchType = 'firstMatch' And $s_BrowserName = '' Then
		Return SetError($_WD_ERROR_NotSupported)
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
	$_WD_CAPS__API[$i_API_New_IDX][$_WD_CAPS__STANDARD__CURRENT] = Null
	$_WD_CAPS__API[$i_API_New_IDX][$_WD_CAPS__SPECIFICVENDOR__ObjectName] = $s_SpecificOptions_KeyName
	$_WD_CAPS__API[$i_API_New_IDX][$_WD_CAPS__SPECIFICVENDOR__OPTS] = Null
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
	Local $s_CurrentMatch_Type = '[' & $_WD_CAPS__API[$_WD_CAPS__CURRENTIDX][$_WD_CAPS__STANDARD__Type] & ']'
	If $s_CurrentMatch_Type = '[firstMatch]' Then
		$s_CurrentMatch_Type &= '[' & $_WD_CAPS__API[$_WD_CAPS__CURRENTIDX][$_WD_CAPS__STANDARD__FirstIdx] & ']'
	EndIf

	Local $s_SpecificOptions_KeyName = $_WD_CAPS__API[$_WD_CAPS__CURRENTIDX][$_WD_CAPS__SPECIFICVENDOR__ObjectName]
	If $s_SpecificOptions_KeyName Then $s_SpecificOptions_KeyName = '["' & $s_SpecificOptions_KeyName & '"]'

	#TODO check
;~ 	If $s_SpecificOptions_KeyName = '' And $i_BUILDER_TYPE >= $_WD_CAPS__SPECIFICVENDOR__ARGS Then _
;~ 			Return SetError(1, 0, '') ; ARGS, PREFS, LOG, ENV and any further are possible only when Specific/Vendor Capability was specified

	Local $s_Notation = ''
	Switch $i_BUILDER_TYPE
		Case $_WD_CAPS__STANDARD__CURRENT
			$s_Notation = '[capabilities]' & $s_CurrentMatch_Type
		Case $_WD_CAPS__SPECIFICVENDOR__OPTS
			$s_Notation = '[capabilities]' & $s_CurrentMatch_Type & $s_SpecificOptions_KeyName ; here is specified the name for {SPECIFIC VENDOR NAME} JSON OBJECT
	EndSwitch
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
