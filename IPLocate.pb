EnableExplicit

Enumeration Windows
	#Window_Results
EndEnumeration

Enumeration Gadgets
	#Gadget_InfoLabel
	#Gadget_InfoField
	#Gadget_CloseButton
EndEnumeration

Enumeration Shortcuts
	#Shortcut_CloseWindow
EndEnumeration

Structure IPInfo
	Query$
	Status$
	Continent$
	ContinentCode$
	Country$
	CountryCode$
	Region$
	RegionName$
	City$
	District$
	Zip$
	Lat.d
	Lon.d
	Timezone$
	Offset.i
	Currency$
	ISP$
	Org$
	As$
	AsName$
	Reverse$
	Mobile.i
	Proxy.i
	Hosting.i
EndStructure

Structure FieldMapping
	JSONKey$
	FriendlyName$
EndStructure

Procedure$ AskForIP()
	Protected IP$
	If CountProgramParameters() > 0
		IP$ = ProgramParameter(0)
	Else
		IP$ = InputRequester("IP Address", "Enter the IP address to geolocate.", "")
	EndIf
	ProcedureReturn IP$
EndProcedure

Procedure.i GetIPInfo(IP$, *Info.IPInfo)
	Protected Request.i, Success.i, Response$, Status$
	Request = HTTPRequest(#PB_HTTP_Get, "http://ip-api.com/json/" + IP$ + "?fields=status,message,continent,continentCode,country,countryCode,region,regionName,city,district,zip,lat,lon,timezone,offset,currency,isp,org,as,asname,reverse,query")
	If Not Request
		ProcedureReturn #False
	EndIf
	Response$ = HTTPInfo(Request, #PB_HTTP_Response)
	FinishHTTP(Request)
	If Not ParseJSON(0, Response$, #PB_JSON_NoCase)
		ProcedureReturn #False
	EndIf
	ExtractJSONStructure(JSONValue(0), *Info, IPInfo)
	Success = Bool(*Info\Status$ = "success")
	If Not Success
		; If we failed, we won't still need the JSON around to query.
		FreeJSON(0)
		ProcedureReturn #False
	EndIf
	ProcedureReturn #True
EndProcedure

Procedure$ FriendlyInfo(*Info.IPInfo)
	Protected Res$, Value$, JSONVal.i, i.i
	Protected Dim Fields.FieldMapping(19)
	Fields(0)\JSONKey$ = "query"
	Fields(0)\FriendlyName$ = "IP Address"
	Fields(1)\JSONKey$ = "continent"
	Fields(1)\FriendlyName$ = "Continent"
	Fields(2)\JSONKey$ = "continentCode"
	Fields(2)\FriendlyName$ = "Continent Code"
	Fields(3)\JSONKey$ = "country"
	Fields(3)\FriendlyName$ = "Country"
	Fields(4)\JSONKey$ = "countryCode"
	Fields(4)\FriendlyName$ = "Country Code"
	Fields(5)\JSONKey$ = "regionName"
	Fields(5)\FriendlyName$ = "Region"
	Fields(6)\JSONKey$ = "region"
	Fields(6)\FriendlyName$ = "Region Code"
	Fields(7)\JSONKey$ = "city"
	Fields(7)\FriendlyName$ = "City"
	Fields(8)\JSONKey$ = "district"
	Fields(8)\FriendlyName$ = "District"
	Fields(9)\JSONKey$ = "zip"
	Fields(9)\FriendlyName$ = "Zip Code"
	Fields(10)\JSONKey$ = "lat"
	Fields(10)\FriendlyName$ = "Latitude"
	Fields(11)\JSONKey$ = "lon"
	Fields(11)\FriendlyName$ = "Longitude"
	Fields(12)\JSONKey$ = "timezone"
	Fields(12)\FriendlyName$ = "Timezone"
	Fields(13)\JSONKey$ = "offset"
	Fields(13)\FriendlyName$ = "UTC Offset"
	Fields(14)\JSONKey$ = "currency"
	Fields(14)\FriendlyName$ = "Currency"
	Fields(15)\JSONKey$ = "isp"
	Fields(15)\FriendlyName$ = "ISP"
	Fields(16)\JSONKey$ = "org"
	Fields(16)\FriendlyName$ = "Organization"
	Fields(17)\JSONKey$ = "as"
	Fields(17)\FriendlyName$ = "AS Number"
	Fields(18)\JSONKey$ = "asname"
	Fields(18)\FriendlyName$ = "AS Name"
	Fields(19)\JSONKey$ = "reverse"
	Fields(19)\FriendlyName$ = "Reverse DNS"
	For i = 0 To 19
		JSONVal = GetJSONMember(JSONValue(0), Fields(i)\JSONKey$)
		If JSONVal
			Select JSONType(JSONVal)
				Case #PB_JSON_String
					Value$ = GetJSONString(JSONVal)
				Case #PB_JSON_Number
					Value$ = StrD(GetJSONDouble(JSONVal))
			EndSelect
			If Value$ <> ""
				If Mid(Value$, Len(Value$)) <> "."
					Value$ + "."
				EndIf
				Res$ + Fields(i)\FriendlyName$ + ": " + Value$ + #LF$
			EndIf
		EndIf
	Next
	
	ProcedureReturn RTrim(Res$, #LF$)
EndProcedure

Procedure ResultsGadgetEvents()
	If EventGadget() = #Gadget_CloseButton
		PostEvent(#PB_Event_CloseWindow)
	EndIf
EndProcedure

Procedure ResultsMenuEvents()
	If EventMenu() = #Shortcut_CloseWindow
		PostEvent(#PB_Event_CloseWindow)
	EndIf
EndProcedure

Procedure ShowResults(Title$, Results$)
	OpenWindow(#Window_Results, #PB_Ignore, #PB_Ignore, 640, 480, Title$)
	TextGadget(#Gadget_InfoLabel, 5, 5, 30, 5, "Results")
	EditorGadget(#Gadget_InfoField, 5, 15, 400, 250, #PB_Editor_ReadOnly)
	ButtonGadget(#Gadget_CloseButton, 500, 50, 30, 30, "Close")
	AddKeyboardShortcut(#Window_Results, #PB_Shortcut_Escape, #Shortcut_CloseWindow)
	SetGadgetText(#Gadget_InfoField, Results$)
	SetActiveGadget(#Gadget_InfoField)
	BindEvent(#PB_Event_Gadget, @ResultsGadgetEvents())
	BindEvent(#PB_Event_Menu, @ResultsMenuEvents())
EndProcedure

Define IP$, Info.IPInfo
IP$ = AskForIP()
If Not GetIPInfo(IP$, @Info)
	MessageRequester("Error", "An error occured while looking up the IP address information.", #PB_MessageRequester_Error)
	End 1
EndIf
ShowResults(Info\Query$ + " - IPLocate", FriendlyInfo(@Info))
FreeJSON(0)
Repeat
Until WaitWindowEvent(1) = #PB_Event_CloseWindow
