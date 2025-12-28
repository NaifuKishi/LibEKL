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
	
	if LibEKL.Events.CheckEvents ("EKL.internal", true) == false then return nil end

    LibEKL.UI.setupBoundCheck()	
	
	_libInit = true
		
end

-------------------- STARTUP EVENTS --------------------

Command.Event.Attach(Event.Addon.SavedVariables.Load.End, settingsHandler, "LibEKL.settingsHandler.SavedVariables.Load.End")