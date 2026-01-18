local addonInfo, privateVars = ...

---------- init namespace ---------

if not LibEKL then LibEKL = {} else return end
if not LibEKL.manager then LibEKL.UI = {} end

if not LibEKL.eventHandlers then LibEKL.eventHandlers = {} end
if not LibEKL.Events then LibEKL.Events = {} end
if not LibEKL.internal then LibEKL.internal = {} end -- sobald nkRadial umgebaut ist das hier komplett auf internal umbauen

privateVars.internalFunc = {}
privateVars.data = {}
privateVars.oFuncs = {}

local internalFunc  = privateVars.internalFunc
local data          = privateVars.data

---------- init local variables ---------

local _libInit = false

---------- local function block ---------

local function settingsHandler(_, addon)
	
	if _libInit == true then return end
	
	if LibEKL.Events.CheckEvents ("LibEKL.internal", true) == false then return nil end

    LibEKL.UI.setupBoundCheck()

	LibEKL.UI.registerFont(addonInfo.id, "Montserrat", "fonts/Montserrat-Regular.ttf")
	LibEKL.UI.registerFont(addonInfo.id, "MontserratSemiBold", "fonts/LibEKL-Montserrat-SemiBold.ttf")
	LibEKL.UI.registerFont(addonInfo.id, "MontserratBold", "fonts/Montserrat-Bold.ttf")

	LibEKL.UI.registerFont(addonInfo.id, "FiraMonoBold", "fonts/FiraMono-Bold.ttf")
	LibEKL.UI.registerFont(addonInfo.id, "FiraMonoMedium", "fonts/FiraMono-Medium.ttf")
	LibEKL.UI.registerFont(addonInfo.id, "FiraMono", "fonts/FiraMono-Regular.ttf")	

	LibEKL.eventHandlers["LibEKL.internal"]["gcChanged"], LibEKL.Events["LibEKL.internal"]["gcChanged"] = Utility.Event.Create(addonInfo.identifier, "LibEKL.internal.gcChanged")

	LibEKL.Events.CheckEvents ("LibEKL.Map", true)
	LibEKL.Events.CheckEvents ("LibEKL.waypoint", true)
	
	LibEKL.eventHandlers["LibEKL.Map"]["add"], LibEKL.Events["LibEKL.Map"]["add"] = Utility.Event.Create(addonInfo.identifier, "LibEKL.Map.mapAdd")
	LibEKL.eventHandlers["LibEKL.Map"]["change"], LibEKL.Events["LibEKL.Map"]["change"] = Utility.Event.Create(addonInfo.identifier, "LibEKL.Map.mapChange")
	LibEKL.eventHandlers["LibEKL.Map"]["remove"], LibEKL.Events["LibEKL.Map"]["remove"] = Utility.Event.Create(addonInfo.identifier, "LibEKL.Map.mapRemove")
	LibEKL.eventHandlers["LibEKL.Map"]["coord"], LibEKL.Events["LibEKL.Map"]["coord"] = Utility.Event.Create(addonInfo.identifier, "LibEKL.Map.mapCoord")	
	LibEKL.eventHandlers["LibEKL.Map"]["zone"], LibEKL.Events["LibEKL.Map"]["zone"] = Utility.Event.Create(addonInfo.identifier, "LibEKL.Map.mapZone")
	LibEKL.eventHandlers["LibEKL.Map"]["shard"], LibEKL.Events["LibEKL.Map"]["shard"] = Utility.Event.Create(addonInfo.identifier, "LibEKL.Map.mapShard")
	LibEKL.eventHandlers["LibEKL.Map"]["unitAdd"], LibEKL.Events["LibEKL.Map"]["unitAdd"] = Utility.Event.Create(addonInfo.identifier, "LibEKL.Map.unitAdd")
	LibEKL.eventHandlers["LibEKL.Map"]["unitChange"], LibEKL.Events["LibEKL.Map"]["unitChange"] = Utility.Event.Create(addonInfo.identifier, "LibEKL.Map.unitChange")
	LibEKL.eventHandlers["LibEKL.Map"]["unitRemove"], LibEKL.Events["LibEKL.Map"]["unitRemove"] = Utility.Event.Create(addonInfo.identifier, "LibEKL.Map.unitRemove")
	LibEKL.eventHandlers["LibEKL.waypoint"]["change"], LibEKL.Events["LibEKL.waypoint"]["change"] = Utility.Event.Create(addonInfo.identifier, "LibEKL.waypoint.change")
	LibEKL.eventHandlers["LibEKL.waypoint"]["add"], LibEKL.Events["LibEKL.waypoint"]["add"] = Utility.Event.Create(addonInfo.identifier, "LibEKL.waypoint.add")
	LibEKL.eventHandlers["LibEKL.waypoint"]["remove"], LibEKL.Events["LibEKL.waypoint"]["remove"] = Utility.Event.Create(addonInfo.identifier, "LibEKL.waypoint.remove")

	_libInit = true
		
end

-------------------- STARTUP EVENTS --------------------

Command.Event.Attach(Event.Addon.SavedVariables.Load.End, settingsHandler, "LibEKL.settingsHandler.SavedVariables.Load.End")