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
; Modified ......: Danp2
; URL ...........: https://w3c.github.io/webdriver/#capabilities
; Date ..........: 2022/04/08
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
	By mutual consent (mLipok + Danp2) for the sake of the entire project, it was decided that: first official release will be published on https://github.com/Danp2/au3WebDriver/
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

	Helper Functions:
	_WD_CapabilitiesDump()
#CE

#EndRegion - wd_capabilities.au3 - function list

#EndRegion wd_capabilities.au3 - UDF Header

#Region - wd_capabilities.au3 UDF - Global's declarations
Global $_WD_CAPS__OBJECT
Global $_WD_NOTATION__MATCHTYPE = '' ; $_WD_CAPS__STANDARD__Type
Global $_WD_NOTATION__SPECIFICVENDOR = '' ; $s_SpecificOptions_KeyName

; $_WD_KEYS__MATCHTYPES should be RegExpPattern of possible "Match Types"
Global Const $_WD_KEYS__MATCHTYPES = _
		'(?i)\A(alwaysMatch|firstMatch)\Z'

; $_WD_KEYS__STANDARD_PRIMITIVE should be RegExpPattern of "JSON_PRIMITIVE" - "a boolean/string/number/null element" that
; should be placed in STANDARD part of Capabilities JSON structure
Global $_WD_KEYS__STANDARD_PRIMITIVE = _
		'(?i)\A(acceptInsecureCerts|browserName|browserVersion|platformName|pageLoadStrategy|setWindowRect|strictFileInteractability|unhandledPromptBehavior)\Z'

; $_WD_KEYS__STANDARD_OBJECT should be RegExpPattern of "JSON_OBJECT" - "a dictionary element" that
; should be placed in STANDARD part of Capabilities JSON structure
Global $_WD_KEYS__STANDARD_OBJECT = _
		'(?i)\A(proxy|timeouts)\Z'

; $_WD_KEYS__STANDARD_OBJECT_ARRAY should be RegExpPattern of "JSON_ARRAY" - "a list of primitive elements" that
; should be placed in $_WD_KEYS__STANDARD_OBJECT .... as an inner element of "JSON_OBJECT" - "a dictionary element" in STANDARD part of Capabilities JSON structure
Global $_WD_KEYS__STANDARD_OBJECT_ARRAY = _
		'(?i)\A(noproxy)\Z'

; $_WD_KEYS__SPECIFICVENDOR_PRIMITIVE should be RegExpPattern of "JSON_PRIMITIVE" - "a boolean/string/number/null element" that
; should be placed in SPECIFICVENDOR part of Capabilities JSON structure
Global $_WD_KEYS__SPECIFICVENDOR_PRIMITIVE = _
		'(?i)\A(binary|debuggerAddress|detach|minidumpPath|w3c)\Z'

; $_WD_KEYS__SPECIFICVENDOR_ARRAY should be RegExpPattern of "JSON_ARRAY" - "a list of primitive elements" that
; should be placed in SPECIFICVENDOR part of Capabilities JSON structure
Global $_WD_KEYS__SPECIFICVENDOR_ARRAY = _
		'(?i)\A(args|extensions|excludeSwitches|windowTypes)\Z'

; $_WD_KEYS__SPECIFICVENDOR_OBJECT should be RegExpPattern of "JSON_OBJECT" - "a dictionary element" that
; should be placed in SPECIFICVENDOR part of Capabilities JSON structure
Global $_WD_KEYS__SPECIFICVENDOR_OBJECT = _
		'(?i)\A(env|log|prefs|perfLoggingPrefs|mobileEmulation|localState)\Z'

#EndRegion - wd_capabilities.au3 UDF - Global's declarations

#Region - wd_capabilities.au3 UDF - core functions
; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_CapabilitiesStartup
; Description ...: Clear $_WD_CAPS__OBJECT - start creating new JSON string for WebDriver Capabilities
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
	Local Const $sFuncName = "_WD_CapabilitiesStartup"

	$_WD_CAPS__OBJECT = ''
	__WD_ConsoleWrite($sFuncName & ': #' & @ScriptLineNumber, $_WD_DEBUG_Full)
EndFunc   ;==>_WD_CapabilitiesStartup

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_CapabilitiesAdd
; Description ...: Add capablitities to JSON string
; Syntax ........: _WD_CapabilitiesAdd($key[, $value1 = ''[, $value2 = '']])
; Parameters ....: $key                 - Capability or Match type defined in $_WD_KEYS__*
;                  $value1              - [optional] a variant value. Default is ''.
;                  $value2              - [optional] a variant value. Default is ''.
; Return values .: None
; Return values .: Success - none.
;                  Failure - none and sets @error to one of the following values:
;                  - $_WD_ERROR_InvalidValue
;                  - $_WD_ERROR_GeneralError
;                  - $_WD_ERROR_NotSupported
; Author ........: mLipok
; Modified ......:
; Remarks .......: Parameters $value1 and $value2 depend on the $key value, take a look on example link
; Related .......:
; Link ..........:
; Example .......: https://www.autoitscript.com/wiki/WebDriver#Advanced_Capabilities_example
; ===============================================================================================================================
Func _WD_CapabilitiesAdd($key, $value1 = Default, $value2 = Default)
	Local Const $sFuncName = "_WD_CapabilitiesAdd"

	If $value1 = Default Then $value1 = ''
	If $value2 = Default Then $value2 = ''
	Local Const $s_Parameters_Info = '     $key = ' & $key & '     $value1 = ' & $value1 & '     $value2 = ' & $value2

	If StringRegExp($key, $_WD_KEYS__MATCHTYPES, $STR_REGEXPMATCH) Then ; check if alwaysMatch|firstMatch
		__WD_CapabilitiesInitialize($key, $value1)
		__WD_ConsoleWrite($sFuncName & ': #' & @ScriptLineNumber & $s_Parameters_Info, $_WD_DEBUG_Full)
		Return SetError(@error, @extended)
	EndIf

	Local $bAlwaysMatch_exist = Json_ObjExists($_WD_CAPS__OBJECT, 'capabilities.alwaysMatch')
	SetError(0) ; for any case because Json_ObjExists() can set @error
	__WD_ConsoleWrite($sFuncName & ': #' & @ScriptLineNumber & '   $bAlwaysMatch_exist = ' & $bAlwaysMatch_exist, $_WD_DEBUG_Full)
	If $bAlwaysMatch_exist = 0 Then _
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_GeneralError, 'Must be properly initialized'))

	Local $v_WatchPoint
	Local $s_Notation = ''

	If StringRegExp($key, $_WD_KEYS__STANDARD_PRIMITIVE, $STR_REGEXPMATCH) Then ; add JSON STRING/BOOLEAN value in STANDARD part of Capabilities JSON Structure
		If $value2 <> '' Then
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_NotSupported, "Not supported: $value2 must be empty string. " & $s_Parameters_Info))
		EndIf
		$v_WatchPoint = @ScriptLineNumber
		$s_Notation = $_WD_NOTATION__MATCHTYPE & '[' & $key & ']'

	ElseIf StringRegExp($key, $_WD_KEYS__STANDARD_OBJECT, $STR_REGEXPMATCH) Then ; add "JSON_OBJECT" in STANDARD part of Capabilities JSON Structure
		$s_Notation = $_WD_NOTATION__MATCHTYPE
		If Not StringRegExp($value1, $_WD_KEYS__STANDARD_OBJECT_ARRAY, $STR_REGEXPMATCH) Then ; if $value1 (child of the $key "JSON_OBJECT") should be treated as "JSON_STRING" value or "JSON_BOOLEAN" value
			$v_WatchPoint = @ScriptLineNumber
			$s_Notation &= '[' & $key & ']' & '[' & $value1 & ']'
		Else ; if $value1 (child of the $key "JSON_OBJECT") should be treated as "JSON_ARRAY"
			If $value2 <> '' Then ; $value2 an element of $value1 "JSON_ARRAY" must be defined
				$v_WatchPoint = @ScriptLineNumber
				$s_Notation &= '[' & $key & ']' & '[' & $value1 & ']'
				Local $iCurrent1 = UBound(Json_Get($_WD_CAPS__OBJECT, $s_Notation))
				SetError(0) ; for any case because UBound() can set @error
				$s_Notation &= '[' & $iCurrent1 & ']' ; here is specified which one of "JSON ARRAY" element should be used
			Else ; not supported option
				Return SetError(__WD_Error($sFuncName, $_WD_ERROR_NotSupported, "Not supported: $value2 must be set. " & $s_Parameters_Info))
			EndIf
		EndIf
		$value1 = $value2 ; switch

	ElseIf StringRegExp($key, $_WD_KEYS__SPECIFICVENDOR_ARRAY, $STR_REGEXPMATCH) And $_WD_NOTATION__SPECIFICVENDOR <> '' Then ; add "JSON_ARRAY" capability in SPECIFIC/VENDOR part of Capabilities JSON Structure
		$v_WatchPoint = @ScriptLineNumber
		$s_Notation = $_WD_NOTATION__MATCHTYPE & $_WD_NOTATION__SPECIFICVENDOR
		$s_Notation &= '[' & $key & ']'
		Local $iCurrent2 = UBound(Json_Get($_WD_CAPS__OBJECT, $s_Notation))
		SetError(0) ; for any case because UBound() can set @error
		$s_Notation &= '[' & $iCurrent2 & ']' ; here is specified which one of "JSON_ARRAY" element should be used
		If $value2 Then
			$v_WatchPoint = @ScriptLineNumber
			$value1 &= '=' & $value2
		EndIf

	ElseIf StringRegExp($key, $_WD_KEYS__SPECIFICVENDOR_OBJECT, $STR_REGEXPMATCH) And $_WD_NOTATION__SPECIFICVENDOR <> '' Then ; add "JSON_OBJECT" capability in SPECIFIC/VENDOR part of Capabilities JSON Structure
		$v_WatchPoint = @ScriptLineNumber
		$s_Notation = $_WD_NOTATION__MATCHTYPE & $_WD_NOTATION__SPECIFICVENDOR
		$s_Notation &= '[' & $key & ']' & '[' & $value1 & ']'
		$value1 = $value2 ; switch

	ElseIf StringRegExp($key, $_WD_KEYS__SPECIFICVENDOR_PRIMITIVE, $STR_REGEXPMATCH) And $_WD_NOTATION__SPECIFICVENDOR <> '' Then ; add "JSON_BOOLEAN" value type in SPECIFIC/VENDOR part of Capabilities JSON Structure
		$v_WatchPoint = @ScriptLineNumber
		$s_Notation = $_WD_NOTATION__MATCHTYPE & $_WD_NOTATION__SPECIFICVENDOR
		If $value1 <> '' Then $s_Notation &= '[' & $key & ']'

	Else ; not supported option
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_NotSupported, "Not supported KEY parameter ( must be defined in $_WD_KEYS__*** ). " & $s_Parameters_Info))
	EndIf
	__WD_ConsoleWrite($sFuncName & ": #" & $v_WatchPoint & '/' & @ScriptLineNumber & ' ' & $s_Parameters_Info & '    $s_Notation = ' & $s_Notation & '   <<<<  ' & $value1, $_WD_DEBUG_Full)
	If @error Then Return SetError(__WD_Error($sFuncName, $_WD_ERROR_GeneralError, $s_Parameters_Info))
	Json_Put($_WD_CAPS__OBJECT, $s_Notation, $value1)
EndFunc   ;==>_WD_CapabilitiesAdd

; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_CapabilitiesGet
; Description ...: Get the Capabilities as string for use in session creation
; Syntax ........: _WD_CapabilitiesGet()
; Parameters ....: None
; Return values .: JSON as string
; Author ........: mLipok
; Modified ......:
; Remarks .......: Internally the Capabilities are processed in AutoIt object variable $_WD_CAPS__OBJECT
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
; Parameters ....: $sCapabilityType     - reference to $_WD_KEYS__* value that should be suplemented for supporting new capability name
;                  $sCapabilityName     - Name of new capability that should be supported
; Return values .: Success - none.
;                  Failure - none and sets @error to one of the following values:
;                  - $_WD_ERROR_InvalidDataType
;                  - $_WD_ERROR_InvalidValue
;                  - $_WD_ERROR_NotSupported
;                  - $_WD_ERROR_AlreadyDefined
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
		$sMessage = 'New CapabilityName must be string'
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidDataType, $sMessage))
	ElseIf StringLen($sCapabilityName) = 0 Then
		$sMessage = 'New CapabilityName must be non empty string'
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidValue, $sMessage))
	ElseIf _
			$sCapabilityType <> $_WD_KEYS__STANDARD_PRIMITIVE And _
			$sCapabilityType <> $_WD_KEYS__STANDARD_OBJECT And _
			$sCapabilityType <> $_WD_KEYS__STANDARD_OBJECT_ARRAY And _
			$sCapabilityType <> $_WD_KEYS__SPECIFICVENDOR_PRIMITIVE And _
			$sCapabilityType <> $_WD_KEYS__SPECIFICVENDOR_ARRAY And _
			$sCapabilityType <> $_WD_KEYS__SPECIFICVENDOR_OBJECT _
			Then
		$sMessage = 'Unsupported capability type: ' & $sCapabilityType
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_NotSupported, $sMessage))
	ElseIf _
			StringRegExp($sCapabilityName, $_WD_KEYS__STANDARD_PRIMITIVE, $STR_REGEXPMATCH) Or _
			StringRegExp($sCapabilityName, $_WD_KEYS__STANDARD_OBJECT, $STR_REGEXPMATCH) Or _
			StringRegExp($sCapabilityName, $_WD_KEYS__STANDARD_OBJECT_ARRAY, $STR_REGEXPMATCH) Or _
			StringRegExp($sCapabilityName, $_WD_KEYS__SPECIFICVENDOR_PRIMITIVE, $STR_REGEXPMATCH) Or _
			StringRegExp($sCapabilityName, $_WD_KEYS__SPECIFICVENDOR_ARRAY, $STR_REGEXPMATCH) Or _
			StringRegExp($sCapabilityName, $_WD_KEYS__SPECIFICVENDOR_OBJECT, $STR_REGEXPMATCH) _
			Then
		$sMessage = 'New capability already exists: ' & $sCapabilityName
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_AlreadyDefined, $sMessage))
	EndIf
	$sCapabilityType = StringTrimRight($sCapabilityType, 3) & '|' & $sCapabilityName & ')\Z'
	__WD_ConsoleWrite($sFuncName & ': #' & @ScriptLineNumber & '  :: DEBUG: Capbility: "' & $sCapabilityName & '"  Suplemented into: ' & $sCapabilityType, $_WD_DEBUG_Full)
EndFunc   ;==>_WD_CapabilitiesDefine

#EndRegion - wd_capabilities.au3 UDF - core functions

#Region - wd_capabilities.au3 UDF - internal functions
; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __WD_CapabilitiesInitialize
; Description ...: Initialize $_WD_CAPS__OBJECT
; Syntax ........: __WD_CapabilitiesInitialize($s_MatchType[, $s_BrowserName = ''])
; Parameters ....: $s_MatchType         - 'alwaysMatch' Or 'firstMatch'.
;                  $s_BrowserName       - [optional] The browser name as defined in $_WD_SupportedBrowsers. Default is ''
; Return values .: Success - None
;                  Failure - None and sets @error to one of the following values:
;                  - $_WD_ERROR_GeneralError
;                  - $_WD_ERROR_AlreadyDefined
;                  - $_WD_ERROR_NotSupported
;                  - $_WD_ERROR_InvalidValue
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
	Local $bAlwaysMatch_exist = (IsObj($_WD_CAPS__OBJECT) And Json_ObjExists($_WD_CAPS__OBJECT, 'capabilities.alwaysMatch'))
	Local $iFirstMatch_count = UBound(Json_Get($_WD_CAPS__OBJECT, '[capabilities][firstMatch]'))
	SetError(0) ; for any case because UBound() can set @error
	__WD_ConsoleWrite($sFuncName & ': #' & @ScriptLineNumber & '   $bAlwaysMatch_exist = ' & $bAlwaysMatch_exist & '  $iFirstMatch_count = ' & $iFirstMatch_count, $_WD_DEBUG_Full)

	If $s_MatchType <> 'alwaysMatch' And Not $bAlwaysMatch_exist Then
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_GeneralError, '"alwaysMatch" must be set at first place'))
	ElseIf $s_MatchType = 'alwaysMatch' And $bAlwaysMatch_exist Then
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_AlreadyDefined, '"alwaysMatch" must be set only once'))
	ElseIf $s_BrowserName <> '' Then
		Local $iIndex = _ArraySearch($_WD_SupportedBrowsers, StringLower($s_BrowserName), Default, Default, Default, Default, Default, $_WD_BROWSER_Name)
		If @error Then
			Return SetError(__WD_Error($sFuncName, $_WD_ERROR_NotSupported, 'Not supported Browser Name: ' & $s_BrowserName))
		EndIf
		$_WD_NOTATION__SPECIFICVENDOR = '["' & $_WD_SupportedBrowsers[$iIndex][$_WD_BROWSER_OptionsKey] & '"]'
	ElseIf $s_MatchType = 'alwaysMatch' And $s_BrowserName = '' Then
		$_WD_NOTATION__SPECIFICVENDOR = ''
	ElseIf $s_MatchType = 'firstMatch' And $s_BrowserName = '' Then
		Return SetError(__WD_Error($sFuncName, $_WD_ERROR_InvalidValue, "FirstMatch requires BrowserName to be defined"))
	EndIf
	#EndRegion - parameters validation

	$_WD_NOTATION__MATCHTYPE = '[' & $s_MatchType & ']'
	If $_WD_NOTATION__MATCHTYPE = '[firstMatch]' Then
		$_WD_NOTATION__MATCHTYPE &= '[' & $iFirstMatch_count & ']' ; here is specified which one of JSON ARRAY element should be used
	EndIf

	$_WD_NOTATION__MATCHTYPE = '[capabilities]' & $_WD_NOTATION__MATCHTYPE
	Json_Put($_WD_CAPS__OBJECT, $_WD_NOTATION__MATCHTYPE, '{}')

	__WD_ConsoleWrite($sFuncName & ': #' & @ScriptLineNumber & '  $_WD_NOTATION__MATCHTYPE = ' & $_WD_NOTATION__MATCHTYPE, $_WD_DEBUG_Full)

	Local $bAlwaysMatch_exist2 = Json_ObjExists($_WD_CAPS__OBJECT, 'capabilities.alwaysMatch')
	Local $iFirstMatch_count2 = UBound(Json_Get($_WD_CAPS__OBJECT, '[capabilities][firstMatch]'))
	SetError(0) ; for any case because UBound() can set @error
	__WD_ConsoleWrite($sFuncName & ': #' & @ScriptLineNumber & '   $bAlwaysMatch_exist2 = ' & $bAlwaysMatch_exist2 & '  $iFirstMatch_count2 = ' & $iFirstMatch_count2, $_WD_DEBUG_Full)
EndFunc   ;==>__WD_CapabilitiesInitialize
#EndRegion - wd_capabilities.au3 UDF - internal functions

#Region - wd_capabilities.au3 UDF - helper functions
; #FUNCTION# ====================================================================================================================
; Name ..........: _WD_CapabilitiesDump
; Description ...: Dump JSON $_WD_CAPS__OBJECT as string to console
; Syntax ........: _WD_CapabilitiesDump([$s_Comment = ''])
; Parameters ....: $s_Comment           - Any comment that should be passed to console. Default is ''.
; Return values .: None
; Author ........: mLipok
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _WD_CapabilitiesDump($s_Comment = '')
	Local Const $sFuncName = "_WD_CapabilitiesDump"

	If $_WD_DEBUG <> $_WD_DEBUG_None Then
		__WD_ConsoleWrite($sFuncName & ": _WD_Capabilities: JSON START: " & $s_Comment)
		__WD_ConsoleWrite(_WD_CapabilitiesGet())
		__WD_ConsoleWrite($sFuncName & ": _WD_Capabilities: JSON END: " & $s_Comment)
	EndIf
EndFunc   ;==>_WD_CapabilitiesDump
#EndRegion - wd_capabilities.au3 UDF - helper functions
