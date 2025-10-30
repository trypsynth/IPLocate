EnableExplicit

Enumeration Gadgets
	#Gadget_InfoLabel
	#Gadget_InfoField
	#Gadget_CloseButton
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
	Protected Request.i, Response.s, Status.s
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
	ProcedureReturn Bool(*Info\Status = "success")
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
		Res + JSONMemberKey(JSONValue(0)) + ": "
		Select JSONType(JSONVal)
			Case #PB_JSON_String
				Res + GetJSONString(JSONVal)
			Case #PB_JSON_Number
				Res + GetJSONFloat(JSONVal)
			Default
				Res + "Unknown."
		EndSelect
		Res + #LF$
	Wend
	FreeJSON(0)
	ProcedureReturn Res
EndProcedure

Define IP.s, Result.s, Info.IPInfo
IP = AskForIP()
If Not GetIPInfo(IP, @Info)
	MessageRequester("Error", "An error occured while looking up the IP address information.", #PB_MessageRequester_Error)
	End 1
EndIf
Result = FriendlyInfo(@Info)
MessageRequester("Results for " + Info\Query, Result, #PB_MessageRequester_Info)
