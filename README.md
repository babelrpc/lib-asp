ASP Runtime Library
===================

Babel supports ASP and WScript _clients_. The following files are deployed for ASP:

* inc_json2_func.asp
* inc_babel.asp
* errorModel.asp

And, for WScript:

* inc_json2_func.js
* inc_babel.vbs
* errorModel.vbs

Do not edit `inc_json2_func.asp` or `inc_babel.asp`!!!

These files are considered part of the Babel deployment - don't modify them directly because the changes need to be incorporated into the distribution. As a reminder, the files include this header:

	' *** WARNING: This code is generated by a tool and deployed with BABEL. ***
	' *** Please see the Babel Team if you believe it needs changes.         ***

For ASP, you only need to include `inc_babel.asp`:

	<!--#include file="../Scripts/inc_babel.asp"-->

For WScript, you'll need to include all three in your WScript (.wsf) file:

	<script language="VBScript" src="..\includes\errorModel.vbs" />
	<script language="JavaScript" src="..\includes\inc_json2_func.js" />
	<script language="VBScript" src="..\includes\inc_babel.vbs" />

Code Generation
---------------

Babel has additional options to specificy the kind of file to generate:

	babel -lang asp -output dir -options ext=vbs file.babel

The `ext` options can be set to `vbs` or `asp`, and defaults to `asp`.

Babel will generate model files and client files. The models include VBScript classes for each `struct`, as well as constants defined for `const` and `enum` declarations. There are helper functions to convert between the enumeration's string value and integer value.

Generated files have the following header as a reminder not to touch them:

	' AUTO-GENERATED FILE - DO NOT MODIFY
	' Generated from dir/somefile.babel

Using the Babel Client
----------------------

A client is a generated VBScript class that you can easily create and initialize with the base URL and timeout for the service:

	dim client : set client = new CoolClient
	call client.InitHttp("http://localhost/CoolService", 30)

If needed, HTTP headers can be set:

	call client.SetHeader("UserId", 4)

Methods on the client class can now be invoked to use the client.

### Notes on calling conventions

Because VBScript has the `set` keyword, it can be a little confusing to figure out how to call a method.

<table><thead><tr><th>Babel Method Definition</th><th>VBScript Return Type</th><th>Example</th></tr></thead>
<tbody>
<tr><td><code>void SayHello();</code></td><td><em>None</em></td><td><code>call client.SayHello()</code></td></tr>
<tr><td><code>string GetData();</code></td><td>String</td><td><code>dim s : s = client.GetData()</code></td></tr>
<tr><td><code>list&lt;string&gt; GetData();</code></td><td>Array</td><td><code>dim arr : arr = client.GetData()</code></td></tr>
<tr><td><code>map&lt;string, string&gt; GetData();</code></td><td>Scripting.Dictionary</td><td><code>dim obj : set obj = client.GetData()</td></tr>
<tr><td><code>MyStruct GetData();</code></td><td>Object</td><td><code>dim obj : set obj = client.GetData()<br/>if not obj is nothing then<br/>' do something<br/>end if</code></td></tr>
</tbody>
</table>

Babel tries to ensure that lists and maps will always be returned as non-null.

Models
------

Models are implemented as VBScript classes. Each model will have the following methods:

* Class_Initialize - constructor
* Class_Terminate - destructor
* Write - internal function for writing the object to the stream
* Read - internal function for reading the object from the stream
* ToJSON - convert to a JSON string (Babel format)
* ToXML - convert to an XML document (**USE WITH CAUTION!!** this format is ever-changing as Babel does not officially support XML)

A Babel `list` is implemented as a VBScript array. A `map` is implemented as a `Scripting.Dictionary` object. Lists and maps are initialized in `Class_Initialize`, so it's safe to assume they exist.

A `null` value for a primitive type (and enumerations) is equivalent to the VBScript `empty` keyword. Where possible, Babel's VBScript code tries to treat the VBScript `null` keyword the same way, but in reality VBScript uses this for database values.

A `null` value for a `struct` type is represented as `nothing` in VBScript. `nothing` is for objects; `empty` is for non-objects.

