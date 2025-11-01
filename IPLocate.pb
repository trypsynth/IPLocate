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
	Query.s
	Status.s
	Continent.s
	ContinentCode.s
	Country.s
	CountryCode.s
	Region.s
	RegionName.s
	City.s
	District.s
	Zip.s
	Lat.f
	Lon.f
	Timezone.s
	Offset.i
	Currency.s
	ISP.s
	Org.s
	As.s
	AsName.s
	Reverse.s
	Mobile.i
	Proxy.i
	Hosting.i
EndStructure

Procedure.s AskForIP()
	Protected IP.s
	If CountProgramParameters() > 0
		IP = ProgramParameter(0)
	Else
		IP = InputRequester("IP Address", "Enter the IP address to geolocate.", "")
	EndIf
	ProcedureReturn IP
EndProcedure

Procedure.i GetIPInfo(IP.s, *Info.IPInfo)
	Protected Request.i, Success.i, Response.s, Status.s
	Request = HTTPRequest(#PB_HTTP_Get, "http://ip-api.com/json/" + IP+ "?fields=status,message,continent,continentCode,country,countryCode,region,regionName,city,district,zip,lat,lon,timezone,offset,currency,isp,org,as,asname,reverse,query")
	If Not Request
		ProcedureReturn #False
	EndIf
	Response = HTTPInfo(Request, #PB_HTTP_Response)
	FinishHTTP(Request)
	If Not ParseJSON(0, Response, #PB_JSON_NoCase)
		ProcedureReturn #False
	EndIf
	ExtractJSONStructure(JSONValue(0), *Info, IPInfo)
	Success = Bool(*Info\Status = "success")
	If Not Success
		; If we failed, we won't still need the JSON around to query.
		FreeJSON(0)
		ProcedureReturn #False
	EndIf
	ProcedureReturn #True
EndProcedure

Procedure.s FriendlyInfo(*Info.IPInfo)
	Protected Res.s, Key.s, JSONVal.i
	ExamineJSONMembers(JSONValue(0))
	While NextJSONMember(JSONValue(0))
		Key = JSONMemberKey(JSONValue(0))
		If Key = "status" Or Key = "query"
			Continue
		EndIf
		JSONVal = JSONMemberValue(JSONValue(0))
		Res + Key + ": "
		Select JSONType(JSONVal)
			Case #PB_JSON_String
				Res + GetJSONString(JSONVal)
			Case #PB_JSON_Number
				Res + GetJSONFloat(JSONVal)
			Default
				Res + "Unknown."
		EndSelect
		Res + "." + #LF$
	Wend
	ProcedureReturn RTrim(Res, #LF$)
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

Procedure ShowResults(Title.s, Results.s)
	OpenWindow(#Window_Results, #PB_Ignore, #PB_Ignore, 640, 480, Title)
	TextGadget(#Gadget_InfoLabel, 5, 5, 30, 5, "Results")
	EditorGadget(#Gadget_InfoField, 5, 15, 400, 250, #PB_Editor_ReadOnly)
	ButtonGadget(#Gadget_CloseButton, 500, 50, 30, 30, "Close")
	AddKeyboardShortcut(#Window_Results, #PB_Shortcut_Escape, #Shortcut_CloseWindow)
	SetGadgetText(#Gadget_InfoField, Results)
	SetActiveGadget(#Gadget_InfoField)
	BindEvent(#PB_Event_Gadget, @ResultsGadgetEvents())
	BindEvent(#PB_Event_Menu, @ResultsMenuEvents())
EndProcedure

Define IP.s, Info.IPInfo
IP = AskForIP()
If Not GetIPInfo(IP, @Info)
	MessageRequester("Error", "An error occured while looking up the IP address information.", #PB_MessageRequester_Error)
	End 1
EndIf
ShowResults(Info\Query, FriendlyInfo(@Info))
FreeJSON(0)
Repeat
Until WaitWindowEvent(1) = #PB_Event_CloseWindow
