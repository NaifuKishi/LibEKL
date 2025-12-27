local addonInfo, privateVars = ...

---------- init namespace ---------

if not LibEKL then LibEKL = {} end
if not LibEKL.cdManager then LibEKL.cdManager = {} end

local internalFunc	= privateVars.internalFunc
local data        	= privateVars.data

local inspectAbilityNewDetail	= Inspect.Ability.New.Detail
local inspectAbilityNewList		= Inspect.Ability.New.List
local inspectAddonCurrent		= Inspect.Addon.Current
local inspectTimeFrame			= Inspect.Time.Frame
local inspectTimeReal			= Inspect.Time.Real
local inspectItemDetail			= Inspect.Item.Detail

local stringUpper				= string.upper

---------- init local variables ---------

local _cdManager		= false
local _cdSubscriptions	= {}
local _cdStore			= { ABILITY = {} , ITEM = {} }
local _gcd				= 1.5

--local _lastUpdate = nil

---------- local function block ---------

local function isSubscribed(cdType, key)

	local retList = {}

	for addon, details in pairs (_cdSubscriptions) do
	
		for thisKey, _ in pairs(details[cdType]) do
			if thisKey == "*" or thisKey == key then table.insert(retList, addon) end
		end
	end
	
	if #retList > 0 then return true, retList end
	
	return false, nil

end

local function processAbilityCooldown (_, info)

	local adds, hasAdds = {}, false
	local stops, hasStops = {}, false  
	
	for key, data in pairs(info) do

		if data <= 0 then
			_cdStore.ABILITY[key] = nil

			local flag, addonList = isSubscribed("ABILITY", key)
			if flag then
				for _, addon in pairs(addonList) do
					if stops[addon] == nil then stops[addon] = {} end
					stops[addon][key] = { type = "ABILITY" }
					hasStops = true
				end
			end
		elseif data > _gcd then -- only check cd > 1 so we don't process all the standard cooldowns
		--else

			_cdStore.ABILITY[key] = { type = "ABILITY", duration = data, begin = inspectTimeFrame(), remaining = data }
			
			local flag, addonList = isSubscribed("ABILITY", key)
			if flag then
				for _, addon in pairs(addonList) do
					if adds[addon] == nil then adds[addon] = {} end
					adds[addon][key] = _cdStore.ABILITY[key]
					hasAdds = true
				end
			end
		end
	end

	if hasAdds == true then 
		for addon, addList in pairs(adds) do
			LibEKL.eventHandlers["LibEKL.CDManager"]["Start"](addon, addList) 
		end
	end

	if hasStops == true then
		for addon, stopList in pairs(stops) do
			LibEKL.eventHandlers["LibEKL.CDManager"]["Stop"](addon, stopList) 
		end
	end

end


---------- library public function block ---------

function LibEKL.cdManager.GetCooldowns()

	return _cdSubscriptions

end

function LibEKL.cdManager.init()

  _cdSubscriptions[inspectAddonCurrent()] = { ITEM = {}, ABILITY = {} }

  if _cdManager == true then return end
  
  if LibEKL.events.checkEvents ("LibEKL.CDManager", true) == false then return nil end
  
  Command.Event.Attach(Event.Ability.New.Cooldown.Begin , processAbilityCooldown, "LibEKL.cdManager.Ability.New.Cooldown.Begin")
  Command.Event.Attach(Event.Ability.New.Cooldown.End , processAbilityCooldown, "LibEKL.cdManager.Ability.New.Cooldown.End")
  
  LibEKL.eventHandlers["LibEKL.CDManager"]["Start"], LibEKL.events["LibEKL.CDManager"]["Start"] = Utility.Event.Create(addonInfo.identifier, "LibEKL.CDManager.Start")
  LibEKL.eventHandlers["LibEKL.CDManager"]["Update"], LibEKL.events["LibEKL.CDManager"]["Update"] = Utility.Event.Create(addonInfo.identifier, "LibEKL.CDManager.Update")
  LibEKL.eventHandlers["LibEKL.CDManager"]["Stop"], LibEKL.events["LibEKL.CDManager"]["Stop"] = Utility.Event.Create(addonInfo.identifier, "LibEKL.CDManager.Stop")
  
  _cdManager = true

end

function LibEKL.cdManager.subscribe(sType, id)

	sType = stringUpper(sType)

	if _cdSubscriptions[inspectAddonCurrent()] == nil then
		_cdSubscriptions[inspectAddonCurrent()] = { ITEM = {}, ABILITY = {} }
	end

	if _cdSubscriptions[inspectAddonCurrent()][sType] == nil then
		_cdSubscriptions[inspectAddonCurrent()][sType] = {}
	end

	_cdSubscriptions[inspectAddonCurrent()][sType][id] = true
	
	if sType == 'ABILITY' then
		local list
	
		if id == "*" then
			list = inspectAbilityNewList()
		else
			list = { [id] = true }
		end
		
		local flag, detailList = pcall (inspectAbilityNewDetail, list)
		if flag and detailList ~= nil then
			for key, details in pairs(detailList) do
				if details.currentCooldownRemaining ~= nil then
					processAbilityCooldown (_, {[key] = details.currentCooldownRemaining })
				end
			end
		end
	end

end

function LibEKL.cdManager.unsubscribe(type, id)

	if _cdSubscriptions[inspectAddonCurrent()] ~= nil and _cdSubscriptions[inspectAddonCurrent()][type] ~= nil and _cdSubscriptions[inspectAddonCurrent()][type][id] ~= nil then
		_cdSubscriptions[inspectAddonCurrent()][type][id] = nil
	end

end

function LibEKL.cdManager.getAllCooldowns (cdType) return _cdStore[stringUpper(cdType)] end

function LibEKL.cdManager.isCooldownActive(cdType, id) 

	if _cdStore[stringUpper(cdType)] == nil then return false end

	if _cdStore[stringUpper(cdType)][id] == nil then
		return false
	else 
		return true
	end
	
end

function LibEKL.cdManager.getCooldownDetails(cdType, id) 

	if _cdStore[stringUpper(cdType)] ~= nil then
		return _cdStore[stringUpper(cdType)][id] 
	end
	
	return nil
	
end

function LibEKL.cdManager.setGCD(newGCD) _gcd = newGCD end

---------- addon internalFunc function block ---------

function internalFunc.processAbilityCooldowns ()

	local debugId  
	if nkDebug then debugId = nkDebug.traceStart (inspectAddonCurrent(), "LibEKL internalFunc.processAbilityCooldowns") end

	if _cdManager == false then return end

	local updates, hasUpdates = {}, false
	local adds, hasAdds = {}, false
	local stops, hasStops = {}, false
	
	for key, details in pairs (_cdStore.ABILITY) do

		if _cdStore.ABILITY[key].lastChange == nil then
			local flag, details = inspectAbilityNewDetail(key)
			
			if flag and details ~= nil then
				_cdStore.ABILITY[key].remaining = details.currentCooldownRemaining
				_cdStore.ABILITY[key].duration = details.currentCooldownDuration
				_cdStore.ABILITY[key].begin = details.currentCooldownBegin
			else
				_cdStore.ABILITY[key].remaining = _cdStore.ABILITY[key].duration - (inspectTimeFrame() - _cdStore.ABILITY[key].begin)
			end
		else
			_cdStore.ABILITY[key].remaining = _cdStore.ABILITY[key].duration - (inspectTimeFrame() - _cdStore.ABILITY[key].begin)
		end
		
		local flag, addonList = isSubscribed("ABILITY", key)
		
		if flag then
			if _cdStore.ABILITY[key].remaining <= 1 or _cdStore.ABILITY[key].lastChange == nil or inspectTimeReal() - _cdStore.ABILITY[key].lastChange >= 1 then
				for _, addon in pairs(addonList) do
					if updates[addon] == nil then updates[addon] = {} end
					updates[addon][key] = _cdStore.ABILITY[key]
					_cdStore.ABILITY[key].lastChange = inspectTimeReal()
					hasUpdates = true
				end
			end
		end
	end

	if hasUpdates == true then 
		for addon, updateList in pairs(updates) do
			LibEKL.eventHandlers["LibEKL.CDManager"]["Update"](addon, updateList) 
		end
	end

	if nkDebug then nkDebug.traceEnd (inspectAddonCurrent(), "LibEKL internalFunc.processAbilityCooldowns", debugId) end

end

function internalFunc.processItemCooldowns ()

	local debugId  
	if nkDebug then debugId = nkDebug.traceStart (inspectAddonCurrent(), "LibEKL internalFunc.processItemCooldowns") end

	if _cdManager == false then return end

	local curTime = inspectTimeReal()

	local updates, hasUpdates = {}, false
	local adds, hasAdds = {}, false
	local stops, hasStops = {}, false
	
	--check item cooldowns - needs to be checked here as rift is not giving any event on item cooldowns
	
	local temp = {}
	
	for addon, details in pairs (_cdSubscriptions) do
		
		for thisKey, _ in pairs(details.ITEM) do

			if temp[thisKey] == nil then
			
				if _cdStore.ITEM[thisKey] == nil then
					local flag, details = pcall(inspectItemDetail, thisKey)

					if flag and details ~= nil and details.cooldownRemaining ~= nil then
						_cdStore.ITEM[thisKey] = { type = "ITEM", duration = details.cooldownDuration, begin = details.cooldownBegin, remaining = details.cooldownRemaining, lastChange = inspectTimeReal() }
						if adds[addon] == nil then adds[addon] = {} end
						adds[addon][thisKey] = _cdStore.ITEM[thisKey]
						hasAdds = true
					end
					
				else
				
					_cdStore.ITEM[thisKey].remaining = _cdStore.ITEM[thisKey].duration - (inspectTimeFrame() - _cdStore.ITEM[thisKey].begin)
					
					if _cdStore.ITEM[thisKey].remaining <= 0 then
						if stops[addon] == nil then stops[addon] = {} end
						stops[addon][thisKey] = { type = "ITEM" }
						hasStops = true
						_cdStore.ITEM[thisKey] = nil
					elseif _cdStore.ITEM[thisKey].remaining <= 1 or curTime - _cdStore.ITEM[thisKey].lastChange >= 1 then
						_cdStore.ITEM[thisKey].lastChange = inspectTimeReal()
						if updates[addon] == nil then updates[addon] = {} end
						updates[addon][thisKey] = _cdStore.ITEM[thisKey]
						hasUpdates = true
					end
					
				end
				
				temp[thisKey] = true
			end
		end
	end

	if hasAdds == true then 
		for addon, addList in pairs(adds) do
			LibEKL.eventHandlers["LibEKL.CDManager"]["Start"](addon, addList) 
		end
	end

	if hasStops == true then
		for addon, stopList in pairs(stops) do
			LibEKL.eventHandlers["LibEKL.CDManager"]["Stop"](addon, stopList) 
		end
	end

	if hasUpdates == true then 
		for addon, updateList in pairs(updates) do
			LibEKL.eventHandlers["LibEKL.CDManager"]["Update"](addon, updateList) 
		end
	end

	if nkDebug then nkDebug.traceEnd (inspectAddonCurrent(), "LibEKL internalFunc.processItemCooldowns", debugId) end

end