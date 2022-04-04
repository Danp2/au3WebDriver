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
	_WD_CapabilitiesDefine()

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

Global $_WD_CAPS_TYPES__STANDARD = _ ; this should be RegExpPattern
		'(?i)\A(acceptInsecureCerts|browserName|browserVersion|platformName|pageLoadStrategy|setWindowRect|strictFileInteractability|unhandledPromptBehavior)\Z'

Global $_WD_CAPS_TYPES__STANDARD_OBJECT = _ ; this should be RegExpPattern
		'(?i)\A(proxy|timeouts)\Z'

Global $_WD_CAPS_TYPES__STANDARD_OBJECT_ARRAY = _ ; this should be RegExpPattern
		'(?i)\A(noproxy)\Z'

Global $_WD_CAPS_TYPES__SPECIFICVENDOR_STRING = _ ; this should be RegExpPattern
		'(?i)\A(binary|debuggerAddress|minidumpPath)\Z'

Global $_WD_CAPS_TYPES__SPECIFICVENDOR_BOOLEAN = _ ; this should be RegExpPattern
		'(?i)\A(w3c|detach)\Z'

Global $_WD_CAPS_TYPES__SPECIFICVENDOR_ARRAY = _ ; this should be RegExpPattern
		'(?i)\A(args|extensions|excludeSwitches|windowTypes)\Z'

Global $_WD_CAPS_TYPES__SPECIFICVENDOR_OBJECT = _ ; this should be RegExpPattern
		'(?i)\A(env|log|prefs|perfLoggingPrefs|mobileEmulation|localState)\Z'

Global Const $_WD_CAPS__ARRAY_HEADER_NAMES = _
		"STANDARD__Type" & "|" & _
		"STANDARD__FirstIdx" & "|" & _
		"STANDARD__CURRENT" & "|" & _
		"SPECIFICVENDOR__ObjectName" & "|" & _
		"SPECIFICVENDOR__OPTS" & "|" & _
		""

Global Const $_WD_CAPS_MATCHTYPES = _ ; this should be RegExpPattern
		'(?i)\A(alwaysMatch|firstMatch)\Z'

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
; Return values .: Success - none.
;                  Failure - none and sets @error to one of the following values:
;                  - $_WD_ERROR_GeneralError
;                  - $_WD_ERROR_NotSupported
; Author ........: mLipok
; Modified ......:
; Remarks .......: Parameters $value1 and $value2 depend on the $key value, take a look on example link
; Related .......:
; Link ..........:
; Example .......: https://www.autoitscript.com/wiki/WebDriver#Advanced_Capabilities_example
; ===============================================================================================================================
Func _WD_CapabilitiesAdd($key, $value1 = '', $value2 = '')
	Local Const $sFuncName = "_WD_CapabilitiesAdd"

	If $value1 = Default Then $value1 = 'default'
	If $value2 = Default Then $value2 = 'default'
	Local Const $s_Parameters_Info = '     $key = ' & $key & '     $value1 = ' & $value1 & '     $value2 = ' & $value2

	If StringRegExp($key, $_WD_CAPS_MATCHTYPES) Then ; check if alwaysMatch|firstMatch
		Local $iResult = __WD_CapabilitiesInitialize($key, $value1)
		If Not @Compiled Then __WD_ConsoleWrite($sFuncName & ": IFNC: TESTING #" & @ScriptLineNumber & $s_Parameters_Info & "  :: DEBUG")
		If Not @error Then $_WD_CAPS__CURRENTIDX = $iResult
		Return SetError(@error, @extended, $_WD_CAPS__CURRENTIDX)
	EndIf
	If $_WD_CAPS__CURRENTIDX = -1 Then _
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_GeneralError, "Must be properly initialized"))

	Local $s_SpecificOptions_KeyName = $_WD_CAPS__API[$_WD_CAPS__CURRENTIDX][$_WD_CAPS__SPECIFICVENDOR__ObjectName]
	Local $v_WatchPoint
	Local $s_Notation = ''

	If StringRegExp($key, $_WD_CAPS_TYPES__STANDARD, $STR_REGEXPMATCH) Then ; for adding string/boolean value type in standard capability
		If $value2 <> '' Then
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_NotSupported, "Not supported: $value2 must be empty string. " & $s_Parameters_Info))
		EndIf
		$v_WatchPoint = @ScriptLineNumber
		$s_Notation = __WD_CapabilitiesNotation($_WD_CAPS__STANDARD__CURRENT) & '[' & $key & ']'

	ElseIf StringRegExp($key, $_WD_CAPS_TYPES__STANDARD_OBJECT, $STR_REGEXPMATCH) Then ; for adding JSON Object type in standard capability
		$s_Notation = __WD_CapabilitiesNotation($_WD_CAPS__STANDARD__CURRENT)
		If Not StringRegExp($value1, $_WD_CAPS_TYPES__STANDARD_OBJECT_ARRAY, $STR_REGEXPMATCH) Then ; if $value1 (child of the $key JSON OBJECT) should be treated as String or Boolean
			$v_WatchPoint = @ScriptLineNumber
			$s_Notation &= '[' & $key & ']' & '[' & $value1 & ']'
		Else ; if $value1 (child of the $key JSON OBJECT) should be treated as JSON ARRAY
			If $value2 <> '' Then ; $value2 an element of $value1 JSON ARRAY must be defined
				$v_WatchPoint = @ScriptLineNumber
				$s_Notation &= '[' & $key & ']' & '[' & $value1 & ']'
				Local $iCurrent1 = UBound(Json_Get($_WD_CAPS__OBJECT, $s_Notation))
				SetError(0) ; for any case because UBound() can set @error
				$s_Notation &= '[' & $iCurrent1 & ']' ; here is specified which one of JSON ARRAY element should be used
			Else ; not supported option
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_NotSupported, "Not supported: $value2 must be set. " & $s_Parameters_Info))
			EndIf
		EndIf
		$value1 = $value2 ; switch

	ElseIf StringRegExp($key, $_WD_CAPS_TYPES__SPECIFICVENDOR_ARRAY, $STR_REGEXPMATCH) Then ; for adding JSON ARRAY type in specific/vendor capabilities
		$v_WatchPoint = @ScriptLineNumber
		$s_Notation = __WD_CapabilitiesNotation($_WD_CAPS__SPECIFICVENDOR__OPTS)
		$s_Notation &= '[' & $key & ']'
		Local $iCurrent2 = UBound(Json_Get($_WD_CAPS__OBJECT, $s_Notation))
		SetError(0) ; for any case because UBound() can set @error
		$s_Notation &= '[' & $iCurrent2 & ']' ; here is specified which one of JSON ARRAY element should be used
		If $value2 Then
			$v_WatchPoint = @ScriptLineNumber
			$value1 &= '=' & $value2
		EndIf

	ElseIf StringRegExp($key, $_WD_CAPS_TYPES__SPECIFICVENDOR_OBJECT, $STR_REGEXPMATCH) Then ; for adding JSON OBJECT capability in specific/vendor capabilities
		$v_WatchPoint = @ScriptLineNumber
		$s_Notation = __WD_CapabilitiesNotation($_WD_CAPS__SPECIFICVENDOR__OPTS)
		$s_Notation &= '[' & $key & ']' & '[' & $value1 & ']'
		$value1 = $value2 ; switch

	ElseIf StringRegExp($key, $_WD_CAPS_TYPES__SPECIFICVENDOR_STRING, $STR_REGEXPMATCH) And $s_SpecificOptions_KeyName <> '' Then ; for adding string value type in specific/vendor capability
		$v_WatchPoint = @ScriptLineNumber
		$s_Notation = __WD_CapabilitiesNotation($_WD_CAPS__SPECIFICVENDOR__OPTS)
		If $value1 <> '' Then $s_Notation &= '[' & $key & ']'

	ElseIf StringRegExp($key, $_WD_CAPS_TYPES__SPECIFICVENDOR_BOOLEAN, $STR_REGEXPMATCH) And $s_SpecificOptions_KeyName <> '' Then ; for adding boolean value type in specific/vendor capability
		$v_WatchPoint = @ScriptLineNumber
		$s_Notation = __WD_CapabilitiesNotation($_WD_CAPS__SPECIFICVENDOR__OPTS)
		If $value1 <> '' Then $s_Notation &= '[' & $key & ']'

	Else ; not supported option
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_NotSupported, "Not supported KEY parameter ( must be defined in $_WD_CAPS_TYPES__*** ). " & $s_Parameters_Info))
	EndIf
	If Not @Compiled Then __WD_ConsoleWrite($sFuncName & ": IFNC: TESTING #" & $v_WatchPoint & '/' & @ScriptLineNumber & ' ' & $s_Parameters_Info & '    $s_Notation = ' & $s_Notation & '   <<<<  ' & $value1 & "  :: DEBUG")
	If @error Then Return SetError(__WD_Error($sFuncName, $_WD_ERROR_GeneralError, "" & $s_Parameters_Info))
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
; Name ..........: _WD_CapabilitiesDefine
; Description ...: Define new capability type and name
; Syntax ........: _WD_CapabilitiesDefine(Byref $sCapabilityType, $sCapabilityName)
; Parameters ....: $sCapabilityType - reference to $_WD_CAPS_TYPES__* value that should be suplemented for supporting new capability name
;                  $sCapabilityName  - Name of new capability that should be supported
; Return values .: Success - none.
;                  Failure - none and sets @error to one of the following values:
;                  - $_WD_ERROR_InvalidDataType
;                  - $_WD_ERROR_InvalidValue
;                  - $_WD_ERROR_NotSupported
;                  - $_WD_ERROR_InvalidArgue
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_CapabilitiesDefine(ByRef $sCapabilityType, $sCapabilityName)
	Local Const $sFuncName = "_WD_CapabilitiesDefine"
	Local $sMessage = ''
	If Not IsString($sCapabilityName) Then
		$sMessage = 'NewCapability must be string'
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, $sMessage))
	ElseIf StringLen($sCapabilityName) = 0 Then
		$sMessage = 'NewCapability must be non empty string'
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidValue, $sMessage))
	ElseIf _
			$sCapabilityType <> $_WD_CAPS_TYPES__STANDARD And _
			$sCapabilityType <> $_WD_CAPS_TYPES__STANDARD_OBJECT And _
			$sCapabilityType <> $_WD_CAPS_TYPES__STANDARD_OBJECT_ARRAY And _
			$sCapabilityType <> $_WD_CAPS_TYPES__SPECIFICVENDOR_STRING And _
			$sCapabilityType <> $_WD_CAPS_TYPES__SPECIFICVENDOR_BOOLEAN And _
			$sCapabilityType <> $_WD_CAPS_TYPES__SPECIFICVENDOR_ARRAY And _
			$sCapabilityType <> $_WD_CAPS_TYPES__SPECIFICVENDOR_OBJECT _
			Then
		$sMessage = 'Unsupported capability type: ' & $sCapabilityType
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_NotSupported, $sMessage))
	ElseIf _
			StringRegExp($sCapabilityName, $_WD_CAPS_TYPES__STANDARD, $STR_REGEXPMATCH) Or _
			StringRegExp($sCapabilityName, $_WD_CAPS_TYPES__STANDARD_OBJECT, $STR_REGEXPMATCH) Or _
			StringRegExp($sCapabilityName, $_WD_CAPS_TYPES__STANDARD_OBJECT_ARRAY, $STR_REGEXPMATCH) Or _
			StringRegExp($sCapabilityName, $_WD_CAPS_TYPES__SPECIFICVENDOR_STRING, $STR_REGEXPMATCH) Or _
			StringRegExp($sCapabilityName, $_WD_CAPS_TYPES__SPECIFICVENDOR_BOOLEAN, $STR_REGEXPMATCH) Or _
			StringRegExp($sCapabilityName, $_WD_CAPS_TYPES__SPECIFICVENDOR_ARRAY, $STR_REGEXPMATCH) Or _
			StringRegExp($sCapabilityName, $_WD_CAPS_TYPES__SPECIFICVENDOR_OBJECT, $STR_REGEXPMATCH) _
			Then
		$sMessage = 'New capability already exists: ' & $sCapabilityName
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidArgue, $sMessage))
	EndIf
	$sCapabilityType = StringTrimRight($sCapabilityType, 3) & '|' & $sCapabilityName & ')\Z'
EndFunc   ;==>_WD_CapabilitiesDefine

#EndRegion - wd_capabilities.au3 UDF - core functions

#Region - wd_capabilities.au3 UDF - internal functions
; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_CapabilitiesInitialize
; Description ...: Initialize $_WD_CAPS__API and presets for 'alwaysMatch' Or 'firstMatch'
; Syntax ........: __WD_CapabilitiesInitialize($s_MatchType[, $s_BrowserName = ''])
; Parameters ....: $s_MatchType   - 'alwaysMatch' Or 'firstMatch'.
;                  $s_BrowserName - [optional] The browser name as defined in $_WD_SupportedBrowsers. Default is ''
; Return values .: Success - None
;                  Failure - None and sets @error to one of the following values:
;                  - $_WD_ERROR_NotSupported
; Author ........: mLipok
; Modified ......:
; Remarks .......: $s_BrowserName can be set to '' only when 'alwaysMatch' is used
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __WD_CapabilitiesInitialize($s_MatchType, $s_BrowserName = '')
	Local Const $sFuncName = "__WD_CapabilitiesInitialize"
	#Region - parameters validation
	Local $s_SpecificOptions_KeyName = ''

	If $s_BrowserName <> '' Then
		Local $iIndex = _ArraySearch($_WD_SupportedBrowsers, StringLower($s_BrowserName), Default, Default, Default, Default, Default, $_WD_BROWSER_Name)
		If @error Then
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_NotSupported, "Not supported Browser Name: " & $s_BrowserName))
		EndIf
		$s_SpecificOptions_KeyName = $_WD_SupportedBrowsers[$iIndex][$_WD_BROWSER_OptionsKey]
	ElseIf $s_MatchType = 'alwaysMatch' And $s_BrowserName = '' Then
		$s_SpecificOptions_KeyName = ''
	ElseIf $s_MatchType = 'firstMatch' And $s_BrowserName = '' Then
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_NotSupported, "Not supported FirstMatch require defined BrowserName"))
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
EndFunc   ;==>__WD_CapabilitiesInitialize

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_CapabilitiesNotation
; Description ...: get desired notation prefix for specified JSON object
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
	Local Const $sFuncName = "_WD_CapabilitiesDump"
	If @Compiled Then Return ; because of GDRP (law act) reason do not throw nothing to console when compiled script

	If $_WD_DEBUG <> $_WD_DEBUG_None Then
		__WD_ConsoleWrite($sFuncName & ": _WD_Capabilities: API START: " & $s_Comment)
		__WD_ConsoleWrite($sFuncName & ": - $_WD_CAPS__API: Rows= " & UBound($_WD_CAPS__API, 1))
		__WD_ConsoleWrite($sFuncName & ": - $_WD_CAPS__API: Cols= " & UBound($_WD_CAPS__API, 2))

		__WD_ConsoleWrite('$_WD_CAPS__API' & ' : ' & _ArrayToString($_WD_CAPS__API))

		__WD_ConsoleWrite($sFuncName & ": _WD_Capabilities: API END: " & $s_Comment)

		__WD_ConsoleWrite($sFuncName & ": _WD_Capabilities: JSON START: " & $s_Comment)
		__WD_ConsoleWrite($sFuncName & ": " & _WD_CapabilitiesGet())
		__WD_ConsoleWrite($sFuncName & ": _WD_Capabilities: JSON END: " & $s_Comment)
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
