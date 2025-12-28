local addonInfo, privateVars = ...

---------- init namespace ---------

if not LibEKL then LibEKL = {} end
if not LibEKL.BuffManager then LibEKL.BuffManager = {} end

-- Initialize private variables

if not privateVars.buffManagerEvents then privateVars.buffManagerEvents = {} end
if not privateVars.buffManagerData then privateVars.buffManagerData = {} end

local internalFunc		= privateVars.internalFunc
local data        		= privateVars.data
local buffManagerData	= privateVars.buffManagerData
local buffManagerEvents = privateVars.buffManagerEvents

-- Cache frequently used functions and values

local inspectBuffList		= Inspect.Buff.List
local inspectBuffDetail		= Inspect.Buff.Detail
local inspectTimeReal		= Inspect.Time.Real
local inspectAddonCurrent	= Inspect.Addon.Current

local stringFind	= string.find
local stringUpper	= string.upper
local stringFormat	= string.format

local LibEKLUnitGetUnitIDByType

-- Initialize variables

buffManagerData.managerInit		= false
buffManagerData.combatUnits		= {}
buffManagerData.trackedUnits	= {}

buffManagerData.buffCache1st	= {} -- only maintained for a buff until remove event
buffManagerData.buffCache2nd	= {} -- maintend for the whole session
buffManagerData.bdList			= {} -- a list of all identified buffs of all units
buffManagerData.processBDList	= {} -- a list of active subscribed buffs
buffManagerData.bdByType		= {}
buffManagerData.combatCheck		= {}
buffManagerData.subscriptions	= {}


-- Initializes the buff manager and sets up event handlers.
-- @return none
function LibEKL.BuffManager.Init()

	local debugId  
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "LibEKL.BuffManager.Init") end

	if LibEKL.events.checkEvents ("LibEKL.BuffManager", true) == false then return nil end

	buffManagerData.subscriptions[inspectAddonCurrent()] = { buffs = {}, debuffs = {} }

	if buffManagerData.managerInit == true then return end	

	Command.Event.Attach(Event.Buff.Add, buffManagerEvents.buffAdd, "LibEKL.BuffManager.Buff.Add")
	Command.Event.Attach(Event.Buff.Change, buffManagerEvents.buffChange, "LibEKL.BuffManager.Buff.Change")
	Command.Event.Attach(Event.Buff.Remove, buffManagerEvents.buffRemove, "LibEKL.BuffManager.Buff.Remove")
	Command.Event.Attach(Event.Combat.Death, buffManagerEvents.combatDeath, "LibEKL.BuffManager.Combat.Death")
	Command.Event.Attach(Event.Combat.Damage, buffManagerEvents.combatDamage, "LibEKL.BuffManager.Combat.Damage")

	LibEKL.eventHandlers["LibEKL.BuffManager"]["Add"], LibEKL.events["LibEKL.BuffManager"]["Add"] = Utility.Event.Create(addonInfo.identifier, "LibEKL.BuffManager.Add")
	LibEKL.eventHandlers["LibEKL.BuffManager"]["Change"], LibEKL.events["LibEKL.BuffManager"]["Change"] = Utility.Event.Create(addonInfo.identifier, "LibEKL.BuffManager.Change")
	LibEKL.eventHandlers["LibEKL.BuffManager"]["Remove"], LibEKL.events["LibEKL.BuffManager"]["Remove"] = Utility.Event.Create(addonInfo.identifier, "LibEKL.BuffManager.Remove")

	LibEKL.Unit.init()

	buffManagerData.managerInit = true
	
	if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "LibEKL.BuffManager.Init", debugId) end

end

-- Subscribes to buff events for a specific type, ID, caster, target, and stack.
-- @param sType The type of buff to subscribe to ('BUFF' or 'DEBUFF').
-- @param sId The ID of the buff to subscribe to.
-- @param castBy The caster of the buff (can be a unit ID or '*' for any caster).
-- @param sTarget The target of the buff (can be a unit ID, '*' for any target, or an addon type).
-- @param sStack The stack count of the buff (can be a number or '*' for any stack count).
-- @return none
function LibEKL.BuffManager.Subscribe(sType, sId, castBy, sTarget, sStack)

	local debugId  
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "LibEKL.BuffManager.Subscribe") end

	sType = stringUpper(sType)

	if sType == 'BUFF' then sType = 'BUFFS' end
	if sType == 'DEBUFF' then sType = 'DEBUFFS' end

	if buffManagerData.subscriptions[inspectAddonCurrent()] == nil then
		buffManagerData.subscriptions[inspectAddonCurrent()] = { BUFFS = {}, DEBUFFS = {} }
	end

	if buffManagerData.subscriptions[inspectAddonCurrent()][sType] == nil then
		buffManagerData.subscriptions[inspectAddonCurrent()][sType] = {}
	end
	
	buffManagerData.subscriptions[inspectAddonCurrent()][sType][sId] = { caster = castBy, target = sTarget, stack = sStack }

	local list, runEvent = {}, false
	
	if stringFind(sTarget, "addonType") ~= nil then
		sTarget = LibEKL.strings.right (sTarget, "addonType", 1, true)
		if buffManagerData.combatUnits[sTarget] == nil then buffManagerData.combatUnits[sTarget] = {} end
		table.insert(buffManagerData.combatUnits[sTarget], stringFormat("%s-%s", sType, sId))
	end

	if sTarget == "*" then
	
		if buffManagerData.combatUnits["*"] == nil then buffManagerData.combatUnits[sTarget] = {} end
		table.insert(buffManagerData.combatUnits["*"], stringFormat("%s-%s", sType, sId))
	
		for unitId, thisList in pairs(buffManagerData.buffCache1st) do
		
			if buffManagerData.trackedUnits[unitId] ~= true then
				LibEKL.BuffManager.InitUnitBuffs(unitId) 
			else
				if list[unitId] == nil then list[unitId] = {} end
				
				for k, v in pairs(thisList) do
					list[unitId][k] = true
					runEvent = true
				end
			end
		end
	else
		local unitIdList = LibEKL.Unit.GetUnitIDByType(sTarget)
		if unitIdList ~= nil then
		
			for _, unitId in pairs(unitIdList) do
				if buffManagerData.trackedUnits[unitId] ~= true then 
					LibEKL.BuffManager.InitUnitBuffs(unitId) 
				else
					if list[unitId] == nil then list[unitId] = {} end
				
					local thisList = buffManagerData.buffCache1st[unitId]
					if buffManagerData.buffCache1st[unitId] ~= nil then
						for k, v in pairs(thisList) do
							list[unitId][k] = true
							runEvent = true
						end
					end
				end
			end
		end
	end
	
	if runEvent then 
		for unitId, buffList in pairs(list) do
			buffManagerEvents.buffAdd (_, unitId, buffList) 
		end
	end
	
	if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "LibEKL.BuffManager.Subscribe", debugId) end
	
end

-- Unsubscribes from buff events for a specific type and ID.
-- @param sType The type of buff to unsubscribe from ('BUFFS' or 'DEBUFFS').
-- @param sId The ID of the buff to unsubscribe from.
-- @return none
function LibEKL.BuffManager.Unsubscribe(sType, sId)

	local debugId  
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "LibEKL.BuffManager.Unsubscribe") end

	if buffManagerData.subscriptions[inspectAddonCurrent()] ~= nil and buffManagerData.subscriptions[inspectAddonCurrent()][sType] ~= nil and buffManagerData.subscriptions[inspectAddonCurrent()][sType][sId] ~= nil then
	
		local thisSubscription = buffManagerData.subscriptions[inspectAddonCurrent()][sType][sId]
		if stringFind(thisSubscription.target, "addonType") ~= nil then
			local sTarget = LibEKL.strings.right (thisSubscription.target, "addonType", 1, true)
			
			if buffManagerData.combatUnits[sTarget] ~= nil then 
				buffManagerData.combatUnits[sTarget] = LibEKL.Tools.Table.removeValue(buffManagerData.combatUnits[sTarget], stringFormat("%s-%s", sType, sId))
				if #buffManagerData.combatUnits[sTarget] == 0 then buffManagerData.combatUnits[sTarget] = nil end
			end
		elseif thisSubscription.target == "*" then
			
			if buffManagerData.combatUnits["*"] ~= nil then 
				buffManagerData.combatUnits["*"] = LibEKL.Tools.Table.removeValue(buffManagerData.combatUnits["*"], stringFormat("%s-%s", sType, sId))
				if #buffManagerData.combatUnits["*"] == 0 then buffManagerData.combatUnits["*"] = nil end
			end
		end
	
		buffManagerData.subscriptions[inspectAddonCurrent()][sType][sId] = nil
	end
	
	if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "LibEKL.BuffManager.Unsubscribe", debugId) end

end

-- Retrieves detailed information about a specific buff on a unit.
-- @param unit The unit ID to check for the buff.
-- @param buffId The ID of the buff to retrieve details for.
-- @return A table containing buff details if found, or nil if the buff is not found.
function LibEKL.BuffManager.GetBuffDetails(unit, buffId)

	local debugId  
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "LibEKL.BuffManager.GetBuffDetails") end

	if not LibEKLUnitGetUnitIDByType then LibEKLUnitGetUnitIDByType = LibEKL.Unit.GetUnitIDByType end

	if buffManagerData.buffCache1st[unit] == nil then 
		unit = LibEKLUnitGetUnitIDByType(unit)
		if unit == nil then 
			if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "LibEKL.BuffManager.GetBuffDetails", debugId) end
			return
		else
			local found = false
			for _, unitId in pairs(unit) do
				if buffManagerData.buffCache1st[unitId] ~= nil then
					found = true
					unit = unitId
					break
				end
			end
			
			if not found then 
				if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "LibEKL.BuffManager.GetBuffDetails", debugId) end
				return
			end
		end
	end

	local temp = buffManagerData.buffCache1st[unit][buffId]
	
	if temp == nil and buffManagerData.bdByType[unit][buffId] ~= nil then
		temp = buffManagerData.buffCache1st[unit][buffManagerData.bdByType[unit][buffId]]
	end
	
	if temp == nil then
		for id, details in pairs (buffManagerData.buffCache1st[unit]) do
			if details.name == buffId then
				temp = details
				break
			end
		end
	end
	
	if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "LibEKL.BuffManager.GetBuffDetails", debugId) end
	
	return temp

end

-- Retrieves detailed information about a specific buff from the second-level cache.
-- @param unit The unit ID to check for the buff.
-- @param buffId The ID of the buff to retrieve details for.
-- @return A table containing buff details if found, or nil if the buff is not found.
function LibEKL.BuffManager.GetCachedBuffDetails(unit, buffId)

	local debugId  
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "LibEKL.BuffManager.GetCachedBuffDetails") end

	local temp = buffManagerData.buffCache2nd[unit][buffId]
	
	if temp == nil and buffManagerData.bdByType[unit][buffId] ~= nil then
		temp = buffManagerData.buffCache2nd[unit][buffManagerData.bdByType[unit][buffId]]
	end
	
	if temp == nil then
		for id, details in pairs (buffManagerData.buffCache2nd[unit]) do
			if details.name == buffId then
				temp = details
				break
			end
		end
	end
	
	if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "LibEKL.BuffManager.GetCachedBuffDetails", debugId) end
	
	return temp

end

-- Initializes buff tracking for a specific unit.
-- @param unit The unit ID to initialize buff tracking for.
-- @return true if new buffs were found and added, false otherwise.
function LibEKL.BuffManager.InitUnitBuffs(unit)

	local debugId  
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "LibEKL.BuffManager.InitUnitBuffs") end

	buffManagerData.trackedUnits[unit] = true

	local newBuffList, hasNewBuffs = {}, false
	
	local buffList = inspectBuffList(unit)
	
	if buffList == nil then return end
	
	for buffId, _ in pairs(buffList) do
	
		if buffManagerData.bdList[unit] == nil or buffManagerData.buffCache1st[unit] == nil or buffManagerData.buffCache1st[unit][buffId] == nil then
			newBuffList[buffId] = true
			hasNewBuffs = true
		end
	
	end
	
	if hasNewBuffs then buffManagerEvents.buffAdd(_, unit, newBuffList) end
	
	if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "LibEKL.BuffManager.InitUnitBuffs", debugId) end
	
	return hasNewBuffs

end

-- Retrieves the list of active buffs for a specific unit.
-- @param unit The unit ID to retrieve buff list for.
-- @return A table containing the active buffs for the unit, or nil if no buffs are found.
function LibEKL.BuffManager.GetUnitBuffList (unit) 

	local debugId  
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "LibEKL.BuffManager.GetUnitBuffList") end

	if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "LibEKL.BuffManager.GetUnitBuffList", debugId) end
	
	return buffManagerData.buffCache1st[unit]

end

-- Checks if a specific buff is active on a unit.
-- @param unit The unit ID to check for the buff.
-- @param id The ID of the buff to check.
-- @return true if the buff is active, false otherwise.
function LibEKL.BuffManager.IsBuffActive(unit, id) 

	local debugId  
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "LibEKL.BuffManager.IsBuffActive") end

	if buffManagerData.buffCache1st[unit] == nil then 
		local list = LibEKL.Unit.GetUnitIDByType(unit)
		if list == nil then return false end
		unit = list[1] -- nicht sauber. muss ich später mal angehen da es durchaus sein kann das mehrere units gefunden werden
	end

	if buffManagerData.buffCache1st[unit] == nil then 
	
		local flag, buffList = pcall (inspectBuffList, unit)
		
		if flag and buffList ~= nil then
			
			local flag, buffDetails = pcall(inspectBuffDetail, unit, buffList)
			if flag and buffDetails ~= nil then
			
				buffManagerData.buffCache1st[unit] = {}
				if buffManagerData.buffCache2nd[unit] == nil then buffManagerData.buffCache2nd[unit] = {} end
				if buffManagerData.bdList[unit] == nil then buffManagerData.bdList[unit] = {} end
				if buffManagerData.processBDList[unit] == nil then buffManagerData.processBDList[unit] = {} end
				
				for buffId, details in pairs(buffDetails) do
					buffManagerData.bdList[unit][buffId] = true
					buffManagerData.buffCache1st[unit][buffId] = buffDetails
					buffManagerData.buffCache2nd[unit][buffId] = buffDetails

					if details.type ~= nil then
						if buffManagerData.bdByType[unit] == nil then buffManagerData.bdByType[unit] = {} end
						buffManagerData.bdByType[unit][details.type] = buffId
					end
				end
			else
				if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "LibEKL.BuffManager.IsBuffActive", debugId) end
				return false
			end
		else
			if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "LibEKL.BuffManager.IsBuffActive", debugId) end
			return false
		end
	end
	
	if buffManagerData.buffCache1st[unit][id] ~= nil then
		if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "LibEKL.BuffManager.IsBuffActive", debugId) end
		return true
	end
	
	local realID = getRealIDByType(unit, id)
	
	if realID == nil or buffManagerData.buffCache1st[unit][realID] == nil then
		if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "LibEKL.BuffManager.IsBuffActive", debugId) end
		return false
	end
	
	if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "LibEKL.BuffManager.IsBuffActive", debugId) end
	
	return true

end