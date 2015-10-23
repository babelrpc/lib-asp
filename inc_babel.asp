<%
' BABEL Runtime Library for ASP
' Copyright (C) 2015 The Babel RPC Authors
%><!--#include file="errorModel.asp"-->
<!--#include file="inc_json2_func.asp"--><%

' *** WARNING: This code is generated by a tool and deployed with BABEL. ***
' *** Please see Michael Lore if you believe it needs changes.           ***

' REQUIRES errorModel and inc_json2_func

const BabelXmlDomProgID = "MSXML2.DOMDocument.6.0" 
const BabelXmlHttpProgID = "Msxml2.ServerXMLHTTP.6.0"
const BABEL_SXH_SERVER_CERT_IGNORE_ALL_SERVER_ERRORS = 13056

' *** HTTP Utility functions used in Babel clients ***

function BabelMakeXMLDoc()
	dim objDoc : set objDoc = CreateObject(BabelXmlDomProgID)
	objDoc.async = false
	objDoc.setProperty "SelectionLanguage", "XPath"
	objDoc.validateOnParse = false
	set BabelMakeXMLDoc = objDoc
end function

function BabelCreateServerXMLHTTP(byval timeoutInSeconds)
	dim tmpObj

	timeoutInSeconds = intCheck(timeoutInSeconds)
	if timeoutInSeconds = 0 then timeoutInSeconds = 60

	set tmpObj = createObject(BabelXmlHttpProgID)

	'                  (resolveTimeout, connectTimeout, sendTimeout, receiveTimeout);
	tmpObj.setTimeouts 10 * 1000,        10 * 1000,      20 * 1000,  (timeoutInSeconds * 1000)

	set BabelCreateServerXMLHTTP = tmpObj
end function

function BabelMakeHttpRequest(httpmethod, url, SendData, ContentType, isAsync, headerDict, timeoutSeconds)
	dim xmlHttp
	dim item
	dim ignoreCertificateErrors
	dim ErrorDescription
	
	if url = "" then err.Raise 500, "BabelHttpRequest", "URL cannot be empty"

	ignoreCertificateErrors = false
	if isobject(eval("application")) then
		if application("prodstatus") = "dev" then
			if instr(1, url, "https://localhost", vbTextCompare) then
				ignoreCertificateErrors = true
			end if
		end if
	end if
	
	on error resume next
	Set xmlHttp = BabelCreateServerXMLHTTP(timeoutSeconds)
	if ignoreCertificateErrors = true then
		xmlHttp.setOption(2) = BABEL_SXH_SERVER_CERT_IGNORE_ALL_SERVER_ERRORS
	end if

	xmlHttp.open httpmethod, url, isAsync

	if contenttype <> "" then
		xmlhttp.setRequestHeader "Content-Type", contenttype
	end if

	if isObject(headerDict) then
		for each item in headerDict
			if headerDict(item) <> "" then
				xmlhttp.setRequestHeader item, BabelUrlEncode(headerDict(item))
			end if
		next
	end if

	xmlHttp.send SendData

	if err then
		if ignoreCertificateErrors = false and err.number = -2147012858 then
			ErrorDescription = err.Description
			on error goto 0
			call err.Raise(500, "System|Invalid Certificate!", "URL=[" & url & "]" & vbCrLf & ErrorDescription)
		else
			ErrorDescription = err.Description
			on error goto 0
			err.Raise 500, "BabelMakeHttpRequest", "URL=[" & url & "] -- " & ErrorDescription
		end if
	end if

	set BabelMakeHttpRequest = xmlHttp
end function

function BabelCall(baseUrl, endPoint, moreHeaders, timeOutSecs, argsDict, returnType)
	dim url         : url = baseUrl & endpoint
	dim method      : method = "POST"
	dim contentType : contentType = "application/json"
	dim data        : data = BabelToJson(empty, empty, argsDict)
	dim headers     : set headers = CreateObject("Scripting.Dictionary")
	dim item
	headers("Accept") = "application/json"

	if isObject(moreHeaders) and Not moreHeaders is Nothing then
		for each item in moreHeaders
			headers(item) = moreHeaders(item)
		next
	end if

	dim http : set http = BabelMakeHttpRequest("POST", url, data, contentType, false, headers, timeOutSecs)
	if http is nothing or not isobject(http) then
		err.raise 500, "BABEL|HTTP!", "Unexpected result on " & endPoint
	end if
	if http.Status <> 200 then
		err.raise http.Status, replace(endPoint, "/", "|"), http.responsetext
	end if

	dim text : text = cstr(http.ResponseText)
	if returnType = "" or returnType = "void" then
		BabelCall = empty
	elseif trim(text) = "" then
		if BabelIsObject(returnType) then
			set BabelCall = Nothing
		elseif left(returnType, 4) = "list" then
			BabelCall = Array()
		elseif left(returnType, 3) = "map" then
			set BabelCall = CreateObject("Scripting.Dictionary")
		else
			BabelCall = empty
		end if
	else
		dim jsObj, z
		set z = new BabelJSONProtocol
		if BabelIsObject(returnType) then
			set jsObj = JSON.parse(text)
			set BabelCall = z.Read(jsObj, returnType, empty, nothing, empty)
		else
			if left(returnType, 4) = "list" then
				set jsObj = JSON.parse(text)
			else
				jsObj = JSON.parse(text)
			end if
			BabelCall = z.Read(jsObj, returnType, empty, empty, empty)
		end if
		set z = Nothing
	end if
end function

' *** Function to process error json ***

function BabelParseError(text)
	dim svcError, z, jsObj
	set z = new BabelJSONProtocol
	on error resume next
	set jsObj = JSON.parse(text)
	if err then
		on error goto 0
		set BabelParseError = nothing
		exit function
	end if
	set svcError = z.Read(jsObj, "BabelServiceError", empty, nothing, empty)
	if err then
		on error goto 0
		set BabelParseError = nothing
		exit function
	end if
	on error goto 0
	set BabelParseError = svcError
	set z = nothing
	set jsObj = nothing
end function

' *** Conversion utility functions ***

function BabelToJson(t, n, o)
	dim z : set z = new BabelJSONProtocol
	dim s : set s = CreateObject("Strcat.Catter")
	call z.Write(s, t, n, o, empty, 0)
	BabelToJson = s.Dump()
	set z = Nothing
	set s = Nothing
end function

function BabelToXml(t, n, o)
	dim z : set z = new BabelXMLProtocol
	dim x : set x = BabelMakeXMLDoc()
	call z.Write(x, t, n, o, empty, 0)
	set BabelToXml = x
	set z = Nothing
end function

' *** Date utility functions ***

sub BabelDateToJson(s, o)
	if isempty(o) then 
		s.Append "null"
	else
		o = cdate(o)
		dim tzc : set tzc = CreateObject("Concur.TimezoneConverter")
		dim t : t = tzc.OTConvertLocalToUTC(o, BabelTZID())
		s.Append("""" & BabelPad(year(t), 4) & "-" & BabelPad(month(t), 2) & "-" & BabelPad(day(t), 2))
		s.Append("T" & BabelPad(hour(t), 2) & ":" & BabelPad(minute(t), 2) & ":" & BabelPad(second(t), 2) & ".000Z""")
	end if
end sub

function BabelTZID()
	BabelTZID = 25 ' assuming eastern :-(
end function

function BabelDateFromJson(jsObj)
	'call OTAspLogMessage("Babel", "date", JSON.stringify(jsObj))
	dim tzc
	' 12345678901234567890123456789
	' YYYY-MM-DDTHH:MM:SS.NNN-00:00
	' 2013-10-15T14:37:31.4984277-04:00
	dim str : str = trim(cstr(jsObj))
	dim y : y = clng(left(str, 4))
	dim m : m = clng(mid(str, 6, 2))
	dim d : d = clng(mid(str, 9, 2))
	dim h : h = clng(mid(str, 12, 2))
	dim n : n = clng(mid(str, 15, 2))
	dim s : s = clng(mid(str, 18, 2))
	dim o : o = right(str, 1)
	if o <> "Z" then
		dim wh : wh = instrrev(str, "+")
		if wh = 0 then wh = instrrev(str, "-")
		o = mid(str, wh, 6)
	end if
	dim dt : dt = cdate(BabelPad(m, 2) & "-" & BabelPad(d, 2) & "-" & BabelPad(y, 4) & " " & BabelPad(h, 2) & ":" & BabelPad(n, 2) & ":" & BabelPad(s, 2))
	set tzc = CreateObject("Concur.TimezoneConverter")
	if o <> "Z" then
		dim arr : arr = split(o, ":")
		dim o_h : o_h = clng(arr(0))
		dim o_n : o_n = clng(arr(1))
		if o_h < 0 then o_n = -o_n
		dt = dateadd("n", -(o_h * 60 + o_n), dt)
	end if
	dt = tzc.OTConvertUTCToLocal(dt, BabelTZID())
	BabelDateFromJson = dt
	'call OTAspLogMessage("Babel", "date-final", dt)
	set tzc = nothing
end function

' ***  Other utility functions ***

function BabelPad(s, c)
	BabelPad = string(c - len(s), "0") & s
end function

function BabelIsObject(typ)
	select case typ
	case "bool", "int8", "int16", "int32", "int64", "byte", "float32", "float64", "string", "char", "enum", "datetime", "decimal", "binary"
		BabelIsObject = false
	case else
		if left(typ, 4) = "map<" then
			BabelIsObject = true
		elseif left(typ, 5) = "list<" then
			BabelIsObject = false
		else
			BabelIsObject = true
		end if
	end select
end function

function BabelJSReplace(strText)
	dim tmpText
	tmpText = strText
	if isNull(strText) then
		tmpText = ""
	else
		if strText <> "" then
		' you MUST replace \ first, otherwise you escape your escape slashes for quotes and such
			tmpText = Replace(tmpText, "\", "\\")
			tmpText = Replace(tmpText, """", "\""")
			'tmpText = Replace(tmpText, "'", "\'")
			tmpText = Replace(tmpText, vbCr, "\r")
			tmpText = Replace(tmpText, vbLf, "\n")
			tmpText = Replace(tmpText, vbTab, "\t")
		end if
	end if
	BabelJSReplace = tmpText
end function

' work around ASP stupidity
function BabelIsNull(obj)
	dim r : r = false
	if isempty(obj) or isnull(obj) then
		r = true
	elseif isobject(obj) then
		if obj is nothing then
			r = true
		end if
	end if
	BabelIsNull = r
end function

' *** JSON PROTOCOL ***

class BabelJSONProtocol

	' s - strcatter object
	' t - Babel data type
	' n - field name
	' o - value
	' tl - list of renamed types for map/list
	' sepIndex - counter to track separator
	public sub Write(s, t, n, o, tl, byref sepIndex)
		dim itm, i, enc, si
		' shortcut rendering if field is empty (named fields only)
		if n <> "" then
			if BabelIsNull(o) then
				exit sub
			end if
		end if
		if sepIndex > 0 then
			s.Append(",")
		end if
		sepIndex = sepIndex + 1
		if n <> "" then
			s.Append("""" & n & """:")
		end if
		if IsEmpty(o) or IsNull(o) then
			s.Append("null")
		elseif IsArray(o) and lcase(typename(o)) <> "byte()" then
			s.Append("[")
			si = 0
			for i = 0 to ubound(o)
				call Write(s, empty, empty, o(i), empty, si)
			next
			s.Append("]")
		elseif IsObject(o) then
			if o is nothing then
				s.Append("null")
			elseif lcase(typename(o)) = "dictionary" then
				s.Append("{")
				si = 0
				for each itm in o
					call Write(s, empty, itm, o(itm), empty, si)
					si = si + 1
				next
				s.Append("}")
			else
				' Defined in the custom object
				s.Append("{")
				call o.Write(me, s)
				s.Append("}")
			end if
		else
			dim selector : selector = t
			if selector = "" then selector = lcase(typename(o))

			if o = "" and selector <> "string" and selector <> "char" and selector <> "empty" and selector <> "enum" then
				s.Append("null")
			else
				on error resume next

				select case selector
				case "bool", "boolean"
					s.Append(lcase(cbool(o)))
				case "byte"
					s.Append(cbyte(o))
				case "integer", "int8", "int16"
					s.Append(cint(o))
				case "long", "int32"
					s.Append(clng(o))
				case "int64"
					s.Append("""" & cstr(o) & """")
				case "float32", "float64", "single", "double"
					s.Append(cdbl(o))
				case "string", "char", "empty", "enum"
					s.Append("""" & BabelJsReplace(cstr(o)) & """")
				case "datetime", "date"
					call BabelDateToJson(s, o)
				case "decimal", "currency"
					s.Append("""" & ccur(o) & """")
				case "binary", "byte()"
					set enc = CreateObject("OTCrypt.Encoder")
					enc.Binary = o
					s.Append("""" & enc.Base64 & """")
				case else
					err.raise 500, "BABEL|JSON", "Unknown data type " & t
				end select

				if err then
					dim errDesc
					errDesc = err.Description
					on error goto 0
					err.raise 500, "BABEL|JSON", "Unable to cast to type " & t & " for key: [" & n & "]; value: [" & o & "]" & vbCrLf & errDesc
				end if

				on error goto 0
			end if
		end if
	end sub

	' jsParentObj - parent JS object
	' typ - Babel data type
	' n - name of field
	' defValue - default value
	' tl - list of renamed types for map/list
	public function Read(jsParentObj, typ, n, defValue, tl)
		'call OTAspLogMessage("Babel", "Read", typ & " --> " & JSON.stringify(jsObj))
		dim jsObj
		if n <> "" then
			if IsObject(jsParentObj.get(n)) then
				set jsObj = jsParentObj.get(n)
			else
				jsObj = jsParentObj.get(n)
			end if
		else
			if IsObject(jsParentObj) then
				set jsObj = jsParentObj
			else
				jsObj = jsParentObj
			end if
		end if

		' check for null values
		select case typ
		case "bool", "int8", "int16", "int32", "int64", "byte", "float32", "float64", "string", "char", "enum", "datetime", "decimal", "binary"
			if BabelIsNull(jsObj) then
				' we could empty this but that would override the defaults from the class
				Read = defValue
				exit function
			end if
		end select

		dim isObj, itm, newT, arr
		select case typ
		case "bool"
			Read = cbool(jsObj)
		case "int8", "int16"
			Read = cint(jsObj)
		case "int32"
			Read = clng(jsObj)
		case "int64"
			Read = cstr(jsObj)
		case "byte"
			Read = cbyte(jsObj)
		case "float32", "float64"
			Read = cdbl(jsObj)
		case "string", "char", "enum"
			Read = cstr(jsObj)
		case "datetime"
			Read = BabelDateFromJson(jsObj)
		case "decimal"
			Read = ccur(jsObj)
		case "binary"
			dim otc : set otc = createobject("OTCrypt.Encoder")
			otc.Base64 = cstr(jsObj)
			Read = otc.Binary
			set otc = nothing
		case else
			if left(typ, 4) = "map<" then
				dim m : set m = createobject("Scripting.Dictionary")
				arr = split(mid(typ, 5, len(typ)-5), ",", 2)
				newT = arr(1)
				isObj = BabelIsObject(newT)
				'call OTAspLogMessage("Babel", "type-map", newT)
				if not (BabelIsNull(jsObj)) then
					for each itm in jsObj.Keys()
						if isObj then
							set m(itm) = Read(jsObj, newT, itm, nothing, empty)
						else
							m(itm) = Read(jsObj, newT, itm, empty, empty)
						end if
					next
				end if
				set Read = m
			elseif left(typ, 5) = "list<" then
				newT = mid(typ, 6, len(typ)-6)
				'call OTAspLogMessage("Babel", "type-list", newT)
				isObj = BabelIsObject(newT)
				if not (BabelIsNull(jsObj)) then
					redim arr(ubound(jsObj.keys()))
					dim i : i = 0
					for each itm in jsObj.Keys()
						'call OTAspLogMessage("Babel", "array item", JSON.stringify(itm))
						if isObj then
							set arr(i) = Read(jsObj, newT, clng(itm), nothing, empty)
						else
							arr(i) = Read(jsObj, newT, clng(itm), empty, empty)
						end if
						i = i + 1
					next
					Read = arr
				else
					Read = array()
				end if
			else
				if BabelIsNull(jsObj) then
					set Read = nothing
				else
					'call OTAspLogMessage("Babel", "type-struct", typ)
					dim obj : set obj = eval("new " & typ)
					call obj.Read(me, jsObj)
					set Read = obj
				end if
			end if
		end select
	end function

end class

' *** XML PROTOCOL ***

class BabelXMLProtocol

	' x - xml document object
	' t - Babel data type
	' n - field name
	' o - value
	' tl - list of renamed types for map/list
	' sepIndex - counter to track separator
	public sub Write(x, t, n, o, tl, byref sepIndex)
		dim itm, i, si, el, nd, attr, tl2
		' shortcut rendering if field is empty (named fields only)
		if n <> "" then
			if BabelIsNull(o) then
				exit sub
			end if
		end if
		if sepIndex > 0 then
			's.Append(",")
		end if
		sepIndex = sepIndex + 1
		if n <> "" then
			if x.OwnerDocument is nothing then
				set el = x.CreateElement(n)
			else
				set el = x.OwnerDocument.CreateElement(n)
			end if
			call x.AppendChild(el)
		else
			set el = x
		end if
		if IsEmpty(o) or IsNull(o) then
			's.Append("null")
		elseif IsArray(o) and lcase(typename(o)) <> "byte()" then
			si = 0
			tl2 = split(tl, ",", 2)
			if tl2(0) = "" then tl2(0) = "Item"
			for i = 0 to ubound(o)
				set nd = el.OwnerDocument.CreateElement(tl2(0))
				call el.AppendChild(nd)
				call Write(nd, empty, empty, o(i), tl2(1), si)
			next
		elseif IsObject(o) then
			if o is nothing then
				's.Append("null")
			elseif lcase(typename(o)) = "dictionary" then
				si = 0
				tl2 = split(tl, ",", 3)
				if tl2(0) = "" then tl2(0) = "key"
				if tl2(1) = "" then tl2(1) = "Value"
				for each itm in o
					set nd = el.OwnerDocument.CreateElement(tl2(1))
					call el.AppendChild(nd)
					set attr = el.OwnerDocument.CreateAttribute(tl2(0))
					attr.Value = getPrimitiveValue(empty, itm)
					nd.attributes.setNamedItem(attr)
					call Write(nd, empty, empty, o(itm), tl2(2), si)
					si = si + 1
				next
			else
				' Defined in the custom object
				call o.Write(me, el)
			end if
		else
			el.text = getPrimitiveValue(t, o)
		end if
	end sub

	' xmlParentObj - parent XML object
	' typ - Babel data type
	' n - name of field
	' defValue - default value
	' tl - list of renamed types for map/list
	public function Read(xmlParentObj, typ, n, defValue, tl)
		err.raise 500, "BABEL|XML", "Read not supported yet"
	end function

	function getPrimitiveValue(t, o)
		dim v, scat, enc
		dim selector : selector = t
		if selector = "" then selector = lcase(typename(o))
		select case selector
		case "bool", "boolean"
			v = lcase(cbool(o))
		case "byte"
			v = cbyte(o)
		case "integer", "int8", "int16"
			v = cint(o)
		case "long", "int32"
			v = clng(o)
		case "int64"
			v = clng(o)
		case "float32", "float64", "single", "double"
			v = cdbl(o)
		case "string", "char", "empty", "enum"
			v = cstr(o)
		case "datetime", "date"
			set scat = CreateObject("StrCat.Catter")
			call BabelDateToJson(scat, o)
			v = replace(scat.Dump(), """", "")
			set scat = nothing
		case "decimal", "currency"
			v = ccur(o)
		case "binary", "byte()"
			set enc = CreateObject("OTCrypt.Encoder")
			enc.Binary = o
			v = enc.Base64
		case else
			err.raise 500, "BABEL|XML", "Unknown data type " & t
		end select
		getPrimitiveValue = v
	end function
end class
%>
