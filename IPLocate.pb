EnableExplicit

Structure IPInfo
	Query.s
	Country.s
	Region.s
	City.s
	Zip.s
	Lat.f
	Lon.f
	Timezone.s
	ISP.s
EndStructure

Macro JSONString(_Value)
	GetJSONString(GetJSONMember(JSONValue(0), _Value))
EndMacro

Macro JSONFloat(_Value)
	GetJSONFloat(GetJSONMember(JSONValue(0), _Value))
EndMacro

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
	Request= HTTPRequest(#PB_HTTP_Get, "http://ip-api.com/json/" + IP)
	If Not Request
		ProcedureReturn #False
	EndIf
	Response = HTTPInfo(Request, #PB_HTTP_Response)
	FinishHTTP(Request)
	If Not ParseJSON(0, Response)
		ProcedureReturn #False
	EndIf
	Status = JSONString("status")
	If Status = "fail"
		ProcedureReturn #False
	EndIf
	With *Info
		\Query = JSONString("query")
		\Country = JSONString("country")
		\Region = JSONString("region")
		\City = JSONString("city")
		\Zip = JSONString("zip")
		\Lat = JSONFloat("lat")
		\Lon = JSONFloat("lon")
		\Timezone = JSONString("timezone")
		\ISP = RTrim(JSONString("isp"), ".")
	EndWith
	ProcedureReturn #True
EndProcedure

Procedure.s FriendlyInfo(*Info.IPInfo)
	Protected Res.s
	Res = "IP appears to be from "
	With *Info
		Res + \City + ", "
		Res + \Region + ", "
		Res + \Country
		Res + " (" + \Zip + ")."
		Res + #LF$ + "The latitude and longitude coordinates are "
		Res + StrF(\Lat) + ", "
		Res + StrF(\Lon) + "." + #LF$
		Res + "The ISP is " + \ISP + "." + #LF$
		Res + "The timezone is " + \Timezone + "."
	EndWith
	ProcedureReturn Res
EndProcedure

Define IP.s, Result.s, Info.IPInfo
IP = AskForIP()
If Not GetIPInfo(IP, @Info)
	MessageRequester("Error", "An error occured while looking up the IP address information.", #PB_MessageRequester_Error)
	End 1
EndIf
Result = FriendlyInfo(@info)
MessageRequester("Results for " + Info\Query, Result, #PB_MessageRequester_Info)
