EnableExplicit

#FieldCount = 20

Enumeration Windows
	#Window_Results
EndEnumeration

Enumeration Gadgets
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
	Protected Request.i, Success.i, Response$
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
	Protected Dim Fields.FieldMapping(#FieldCount - 1)
	Restore FieldMappings
	For i = 0 To #FieldCount - 1
		Read.s Fields(i)\JSONKey$
		Read.s Fields(i)\FriendlyName$
	Next
	For i = 0 To #FieldCount - 1
		JSONVal = GetJSONMember(JSONValue(0), Fields(i)\JSONKey$)
		If JSONVal
			Select JSONType(JSONVal)
				Case #PB_JSON_String
					Value$ = GetJSONString(JSONVal)
				Case #PB_JSON_Number
					Value$ = StrD(GetJSONDouble(JSONVal))
			EndSelect
			If Value$ <> ""
				If Right(Value$, 1) <> "."
					Value$ + "."
				EndIf
				If Res$ <> ""
					Res$ + #LF$
				EndIf
				Res$ + Fields(i)\FriendlyName$ + ": " + Value$
			EndIf
		EndIf
	Next
	ProcedureReturn Res$
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
	EditorGadget(#Gadget_InfoField, 10, 10, 620, 420, #PB_Editor_ReadOnly)
	ButtonGadget(#Gadget_CloseButton, 270, 440, 100, 30, "Close")
	AddKeyboardShortcut(#Window_Results, #PB_Shortcut_Escape, #Shortcut_CloseWindow)
	SetGadgetText(#Gadget_InfoField, Results$)
	SetActiveGadget(#Gadget_InfoField)
	BindEvent(#PB_Event_Gadget, @ResultsGadgetEvents())
	BindEvent(#PB_Event_Menu, @ResultsMenuEvents())
EndProcedure

Define IP$, Info.IPInfo
IP$ = AskForIP()
If Not GetIPInfo(IP$, @Info)
	MessageRequester("Error", "An error occurred while looking up the IP address information.", #PB_MessageRequester_Error)
	End 1
EndIf
ShowResults(Info\Query$ + " - IPLocate", FriendlyInfo(@Info))
FreeJSON(0)
Repeat
Until WaitWindowEvent(1) = #PB_Event_CloseWindow

DataSection
	FieldMappings:
	Data.s "query", "IP Address"
	Data.s "continent", "Continent"
	Data.s "continentCode", "Continent Code"
	Data.s "country", "Country"
	Data.s "countryCode", "Country Code"
	Data.s "regionName", "Region"
	Data.s "region", "Region Code"
	Data.s "city", "City"
	Data.s "district", "District"
	Data.s "zip", "Zip Code"
	Data.s "lat", "Latitude"
	Data.s "lon", "Longitude"
	Data.s "timezone", "Timezone"
	Data.s "offset", "UTC Offset"
	Data.s "currency", "Currency"
	Data.s "isp", "ISP"
	Data.s "org", "Organization"
	Data.s "as", "AS Number"
	Data.s "asname", "AS Name"
	Data.s "reverse", "Reverse DNS"
EndDataSection
