local addonInfo, privateVars = ...

---------- init namespace ---------

if not LibEKL then LibEKL = {} end

if not LibEKL.eventHandlers then LibEKL.eventHandlers = {} end
if not LibEKL.Events then LibEKL.Events = {} end

local internalFunc	= privateVars.internalFunc
local data       	= privateVars.data

local inspectAddonCurrent	= Inspect.Addon.Current
local inspectSystemWatchdog	= Inspect.System.Watchdog
local inspectTimeFrame		= Inspect.Time.Frame
local inspectSystemSecure	= Inspect.System.Secure
local inspectTimeReal		= Inspect.Time.Real

local stringFormat			= string.format

---------- init local variables ---------

local _insecureEvents = {}
local _periodicEvents = {}

local _lastUpdate1, _lastUpdate2

---------- local function block ---------

local function processPeriodic()

	local debugId  
	if nkDebug then debugId = nkDebug.traceStart (inspectAddonCurrent(), "LibEKL processPeriodic") end

	local remainingEvents = false

	local currentTime = inspectTimeFrame()
	
	for k, eventDetails in pairs(_periodicEvents) do

		if eventDetails ~= false then -- event will be set to false to stop further processing
			if currentTime - eventDetails.timer > eventDetails.period then
				eventDetails.timer = currentTime
				if eventDetails.func() == true then _periodicEvents[k] = false end

				if eventDetails ~= false and eventDetails.tries ~= nil then
					eventDetails.currentTries = (eventDetails.currentTries or 0) + 1
					if eventDetails.currentTries >= eventDetails.tries then
						_periodicEvents[k] = false
					end
				end
				
			else
				remainingEvents = true
			end
			
		end
	end 

	if remainingEvents == false then _periodicEvents = {} end

	if nkDebug then nkDebug.traceEnd (inspectAddonCurrent(), "LibEKL processPeriodic", debugId) end	

end

local function processInsecure()

	local debugId  
	if nkDebug then debugId = nkDebug.traceStart (inspectAddonCurrent(), "LibEKL processInsecure") end

	if inspectSystemSecure() == true then return end

	local remainingEvents = false

	local currentTime = inspectTimeFrame()

	for k, v in pairs(_insecureEvents) do

		if v ~= false then

			if v.timer == nil or v.period == nil then
				local success, err = pcall(v.func)
                if not success then
                    -- Log the error if debugging is enabled
					LibEKL.Tools.Error.Display(addonInfo.id, err, FATAL_ERROR_LEVEL)

                    if nkDebug then
                        nkDebug.logEntry(inspectAddonCurrent(), "processInsecure", "Error in insecure event function", err)
                    end
                end
				_insecureEvents[k] = false
			else
				if currentTime - v.timer > v.period then
					local success, err = pcall(v.func)
                    if not success then
                        -- Log the error if debugging is enabled
						LibEKL.Tools.Error.Display(addonInfo.id, err, FATAL_ERROR_LEVEL)
                        if nkDebug then
                            nkDebug.logEntry(inspectAddonCurrent(), "processInsecure", "Error in insecure event function", err)
                        end
                    end
					_insecureEvents[k] = false
				else
					remainingEvents = true
				end
			end
		end
	end 

	if remainingEvents == false then _insecureEvents = {} end

	if nkDebug then nkDebug.traceEnd (inspectAddonCurrent(), "LibEKL processInsecure", debugId) end	

end

local _eventsP1Index = 1
local _eventsS1Index = 1
local _eventsRemIndex = 1

local function updateHandler()

	-- run always

	internalFunc.coRoutinesProcess()
	--internalFunc.processFX()
	processPeriodic()
		
	local _curTime = inspectTimeReal()

	local thisWatchDog = inspectSystemWatchdog()
	
	-- run every 1 second
	
	if (_lastUpdate2 == nil or _curTime - _lastUpdate2 >= 1) then
	
		if thisWatchDog >= 0.1 and _eventsS1Index == 1 then
			--internalFunc.processMap()
			_eventsS1Index = 2
		end
		
		if thisWatchDog >= 0.1 and _eventsS1Index == 2 then
			--internalFunc.checkShard()
			_eventsS1Index = 3
		end
		
		if thisWatchDog >= 0.1 and _eventsS1Index == 3 then
			--internalFunc.uiCheckTooltips()
			_eventsS1Index = 1
		end
		
		_lastUpdate2 = _curTime
	end
	
	-- run every 0.1 seconds
	
	if (_lastUpdate1 == nil or _curTime - _lastUpdate1 >= .1) then
	
		 if thisWatchDog >= 0.1 and _eventsP1Index == 1 then
			internalFunc.processAbilityCooldowns()
			_eventsP1Index = 2
		 end
		 
		 if thisWatchDog >= 0.1 and _eventsP1Index == 2 then
			internalFunc.processItemCooldowns()
			_eventsP1Index = 3
		 end
		 
		 if thisWatchDog >= 0.1 and _eventsP1Index == 3 then
			--internalFunc.processBuffs()
			_eventsP1Index = 1
		 end
	
		_lastUpdate1 = _curTime
	end
	
	-- run if there's processor time remaining
	
	if thisWatchDog >= 0.1 and _eventsRemIndex == 1 then
		processInsecure()
		_eventsRemIndex = 2
	end
	
	if thisWatchDog >= 0.1 and _eventsRemIndex == 2 then		
		_eventsRemIndex = 1
	end
	
	-- lowest priority is the performance queue
	
	internalFunc.processPerformanceQueue()

end

---------- library public function block ---------

function LibEKL.Events.AddPeriodic(func, period, tries) -- period is in seconds	
	local uuid = LibEKL.Tools.UUID ()
	_periodicEvents[uuid] = {func = func, timer = inspectTimeFrame(), period = (period or 0), tries = (tries or 1), currentTries = 0 }		
	return uuid
end

function LibEKL.Events.AddInsecure(func, timer, period)
	local uuid = LibEKL.Tools.UUID ()
	_insecureEvents[uuid] = {func = func, timer = timer, period = period }
	return uuid
end

function LibEKL.Events.RemoveInsecure(id) _insecureEvents[id] = false end

function LibEKL.Events.CheckEvents (name, init) -- radial muss umgebaut werden, dann kann diese function internalFunc gemacht werden
	if LibEKL.eventHandlers[name] == nil and init ~= false then
		LibEKL.eventHandlers[name] = {}
		LibEKL.Events[name] = {}
	elseif init ~= false then
		LibEKL.Tools.Error.Display (addonInfo.identifier, stringFormat("Duplicate name '%s' found!", name), 1)
		return false
	end
	
	return true
end

---------- addon internalFunc function block ---------

function internalFunc.deRegisterEvents (name)
  if LibEKL.eventHandlers[name] ~= nil then
    LibEKL.eventHandlers[name] = nil
    LibEKL.Events[name] = nil
  end
end

-------------------- EVENTS --------------------

Command.Event.Attach(Event.System.Update.Begin, updateHandler, "LibEKL.system.updateHandler")