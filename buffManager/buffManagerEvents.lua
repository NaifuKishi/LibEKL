local addonInfo, privateVars = ...

---------- init namespace ---------

if not LibEKL then LibEKL = {} end
if not LibEKL.BuffManager then LibEKL.BuffManager = {} end

if not privateVars.buffManagerEvents then privateVars.buffManagerEvents = {} end
if not privateVars.buffManagerData then privateVars.buffManagerData = {} end

local buffManagerData	= privateVars.buffManagerData
local buffManagerEvents = privateVars.buffManagerEvents

local internalFunc	= privateVars.internalFunc
local data        	= privateVars.data

---------- init local variables ---------

local inspectBuffList		= Inspect.Buff.List
local inspectBuffDetail		= Inspect.Buff.Detail
local inspectTimeReal		= Inspect.Time.Real
local inspectAddonCurrent	= Inspect.Addon.Current

local stringFind	= string.find
local stringUpper	= string.upper
local stringFormat	= string.format

local LibEKLUnitGetUnitDetail
local LibEKLUnitGetUnitTypes
local LibEKLToolsTableIsMember
local LibEKLUnitGetUnitDetail

-- Checks if a buff is subscribed to by any addon.
-- @param unit The unit ID associated with the buff.
-- @param buffDetails Details of the buff to check.
-- @param combatLogFlag Flag indicating if this is from combat logs.
-- @return true if the buff is subscribed, false otherwise, and a table of addon subscriptions.
local function isSubscribed(unit, buffDetails, combatLogFlag)

	local debugId  
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "isSubscribed") end

	if not LibEKLUnitGetUnitTypes then LibEKLUnitGetUnitTypes = LibEKL.Unit.getUnitTypes end
	if not LibEKLToolsTableIsMember then LibEKLToolsTableIsMember = LibEKL.Tools.Table.IsMember end
	if not LibEKLUnitGetUnitDetail then LibEKLUnitGetUnitDetail = LibEKL.Unit.GetUnitDetail end

	local thisType, thisTypeR = "BUFFS", "buff"
	if buffDetails.debuff then thisType, thisTypeR = "DEBUFFS", "debuff" end
	
	local addonSubscriptions = {}
	local hasSubscribed = false

	local unitTypes = LibEKLUnitGetUnitTypes(unit)

	for addon, sDetails in pairs(buffManagerData.subscriptions) do
		local subDetails = sDetails[thisType]

		if subDetails ~= nil then		
			if subDetails["*"] ~= nil then
				local subscription = subDetails["*"]
				if subscription.target == "*" or subscription.target == buffDetails.caster or LibEKLToolsTableIsMember(unitTypes, subscription.target) then
					addonSubscriptions[addon] = { buffType = thisTypeR, subscription = subscription }
					hasSubscribed = true
				end
			else
				local subscription = subDetails[buffDetails.id]

				if subscription == nil then subscription = subDetails[buffDetails.type] end
				if subscription == nil then subscription = subDetails[buffDetails.name] end

				if subscription ~= nil and subscription.caster == buffDetails.caster then

					if LibEKLToolsTableIsMember(unitTypes, subscription.target) then
						addonSubscriptions[addon] = { buffType = thisTypeR, subscription = subscription }
						hasSubscribed = true
					else
						if stringFind(subscription.target, 'addonType') ~= nil then
							local unitDetails = LibEKLUnitGetUnitDetail (unit)
							
							if subscription.target == 'addonType' .. unitDetails.type then
								addonSubscriptions[addon] = { buffType = thisTypeR, subscription = subscription }
								hasSubscribed = true
							end
						end
					end
				end
			end
		end
	end	
	
	if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "isSubscribed", debugId) end
	
	return hasSubscribed, addonSubscriptions

end

-- Checks for buff changes on a combat unit.
-- @param unitId The ID of the unit to check.
-- @return none
local function checkCombatUnit(unitId)

	local debugId  
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "checkCombatUnit") end

	if buffManagerData.combatCheck[unitId] == nil or inspectTimeReal() - buffManagerData.combatCheck[unitId] >= 1 then
		buffManagerData.combatCheck[unitId] = inspectTimeReal()
	else
		if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "checkCombatUnit", debugId) end
		return
	end
	
	local buffList = inspectBuffList(unitId)
	
	if buffList == nil then return end
	
	local adds, hasAdds = {}, false
	local removes, hasRemoves = {}, false
	local updates, hasUpdates = {}, false
	
	if buffManagerData.bdList[unitId] == nil then buffManagerData.bdList[unitId] = {} end
	if buffManagerData.processBDList[unitId] == nil then buffManagerData.processBDList[unitId] = {} end
	
	for buffId, buffDetails in pairs(buffList) do
		if buffManagerData.bdList[unitId][buffId] == nil then
			hasAdds = true
			adds[buffId] = true
		else
			hasUpdates = true
			updates[buffId] = true
		end
	end
	
	if buffManagerData.bdList[unitId] ~= nil then
	
		for buffId, _ in pairs(buffManagerData.bdList[unitId]) do
			if buffList[buffId] == nil then
				hasRemoves = true
				removes[buffId] = true
			end
		end
	end
	
	if hasAdds then buffManagerEvents.buffAdd(_, unitId, adds, true) end
	if hasRemoves then buffManagerEvents.buffRemove(_, unitId, removes, true) end
	if hasUpdates then buffManagerEvents.buffChange(_, unitId, updates, true) end

	if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "checkCombatUnit", debugId) end
	
end

-- Handles buff addition events.
-- @param _ Unused parameter.
-- @param unit The unit ID associated with the buff.
-- @param buffs Table of buff IDs that were added.
function buffManagerEvents.buffAdd (_, unit, buffs)

	local debugId  
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "buffAdd") end

	if buffManagerData.trackedUnits[unit] ~= true then 
		LibEKL.BuffManager.InitUnitBuffs(unit) 
		
		if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "buffAdd", debugId) end
		
		return
	end

	local adds, hasAdds = {}, false
	local buffInfo = inspectBuffDetail(unit, buffs)
	
	for buffId, buffDetails in pairs(buffInfo) do

		buffDetails.start = inspectTimeReal()
		buffDetails.lastChange = buffDetails.start
	
		if buffManagerData.bdList[unit] == nil then buffManagerData.bdList[unit] = {} end
		buffManagerData.bdList[unit][buffId] = true
		
		if buffManagerData.buffCache1st[unit] == nil then 
			buffManagerData.buffCache1st[unit] = {}
			buffManagerData.buffCache2nd[unit] = {}
		end
		
		buffManagerData.buffCache1st[unit][buffId] = buffDetails
		buffManagerData.buffCache2nd[unit][buffId] = buffDetails
		
		if buffDetails.type ~= nil then
			if buffManagerData.bdByType[unit] == nil then buffManagerData.bdByType[unit] = {} end
			buffManagerData.bdByType[unit][buffDetails.type] = buffId
		end
		
		local sFlag, subscriptionList = isSubscribed(unit, buffDetails)

		if sFlag then
		
			if buffManagerData.processBDList[unit] == nil then buffManagerData.processBDList[unit] = {} end
			buffManagerData.processBDList[unit][buffId] = true
		
			for addon, sDetails in pairs(subscriptionList) do
				if adds[addon] == nil then adds[addon] = {} end
				adds[addon][buffDetails.id] = { bType = sDetails.buffType, typeKey = buffDetails.type, target = sDetails.target, name = buffDetails.name, id = buffDetails.id, stack = buffDetails.stack, description = buffDetails.description }
			end
			
			hasAdds = true
		end
	end

	if hasAdds then 
		for addon, addList in pairs(adds) do
			LibEKL.eventHandlers["LibEKL.BuffManager"]["Add"](unit, addon, addList) 
		end
	end
	
	if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "buffAdd", debugId) end
	
end

-- Handles buff removal events.
-- @param _ Unused parameter.
-- @param unit The unit ID associated with the buff.
-- @param buffs Table of buff IDs that were removed.
function buffManagerEvents.buffRemove (_, unit, buffs)

	local debugId  
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "buffRemove") end

	if buffManagerData.trackedUnits[unit] ~= true then 
		LibEKL.BuffManager.InitUnitBuffs(unit)
		
		if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "buffRemove", debugId) end
		
		return
	end

	local removes, hasRemoves = {}, false

	if buffManagerData.buffCache1st[unit] == nil then return end
	
	for buffId, _ in pairs(buffs) do
	
		if buffManagerData.buffCache1st[unit][buffId] ~= nil then
	
			local sFlag, subscriptionList = isSubscribed(unit, buffManagerData.buffCache1st[unit][buffId])
			
			if sFlag then
			
				for addon, sDetails in pairs(subscriptionList) do
					if removes[addon] == nil then removes[addon] = {} end
					removes[addon][buffId] = { bType = sDetails.buffType, typeKey = buffManagerData.buffCache1st[unit][buffId].type, target = sDetails.target, name = buffManagerData.buffCache1st[unit][buffId].name, id = buffId }
				end
			
				hasRemoves = true
			end
			
		end
			
		buffManagerData.bdList[unit][buffId] = nil
		if buffManagerData.processBDList[unit] ~= nil and buffManagerData.processBDList[unit][buffId] ~= nil then buffManagerData.processBDList[unit][buffId] = nil end
		buffManagerData.buffCache1st[unit][buffId] = nil
		
		for k, v in pairs(buffManagerData.bdByType) do
			if v == buffId then
				buffManagerData.bdByType[k] = nil
				break
			end
		end

	end
	
	if hasRemoves then
		for addon, removeList in pairs(removes) do
			LibEKL.eventHandlers["LibEKL.BuffManager"]["Remove"](unit, addon, removeList) 
		end
	end

	if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "buffRemove", debugId) end
	
end

-- Handles buff change events.
-- @param _ Unused parameter.
-- @param unit The unit ID associated with the buff.
-- @param buffs Table of buff IDs that changed.
-- @param combatLogFlag Flag indicating if this is from combat logs.
function buffManagerEvents.buffChange (_, unit, buffs, combatLogFlag)

	local debugId  
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "buffChange") end

	if buffManagerData.trackedUnits[unit] ~= true then 
		LibEKL.BuffManager.InitUnitBuffs(unit)
		
		if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "buffChange", debugId) end
		
		return
	end

	if buffManagerData.bdList[unit] == nil then return end
	
	local changes, hasChanges = {}, false

	local buffInfo = inspectBuffDetail(unit, buffs)
	  
	for buffId, buffDetails in pairs(buffInfo) do
	
		if buffDetails.type ~= nil then
		
			if buffManagerData.bdList[unit][buffDetails.id] == nil then -- buff changed before add (or potentially after remove but come on seriously Trion ...)
				buffManagerEvents.buffAdd (_, unit, {[buffId] = true})
			else
			
				local sFlag, subscriptionList = isSubscribed(unit, buffDetails, combatLogFlag)
				
				if sFlag then
					
					for addon, sDetails in pairs(subscriptionList) do
						if changes[addon] == nil then changes[addon] = {} end
						changes[addon][buffId] = { bType = sDetails.buffType, typeKey = buffDetails.type, target = sDetails.target, name = buffDetails.name, id = buffId, stack = buffDetails.stack, remaining = buffDetails.remaining }
					end
					
					if buffManagerData.processBDList[unit] == nil then buffManagerData.processBDList[unit] = {} end
					buffManagerData.processBDList[unit][buffId] = true
				
					hasChanges = true
				end
				
				buffManagerData.bdList[unit][buffDetails.id] = true
				
				buffDetails.start = buffManagerData.buffCache1st[unit][buffDetails.id].start
				
				buffManagerData.buffCache1st[unit][buffDetails.id] = buffDetails
				buffManagerData.buffCache1st[unit][buffDetails.id].lastChange = inspectTimeReal()
				
				buffManagerData.buffCache2nd[unit][buffDetails.id] = buffDetails
				
				if buffManagerData.bdByType[unit] == nil then buffManagerData.bdByType[unit] = {} end
				
				if buffDetails.type == nil then
					
				else
					buffManagerData.bdByType[unit][buffDetails.type] = buffId
				end
			end
			
		end

	end
	
	if hasChanges then
		for addon, changeList in pairs(changes) do
			LibEKL.eventHandlers["LibEKL.BuffManager"]["Change"](unit, addon, changeList) 
		end
	end
	
	if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "buffChange", debugId) end
	
end

-- Handles combat death events.
-- @param _ Unused parameter.
-- @param info Table containing combat death information.
-- @return none
function buffManagerEvents.combatDeath(_, info)

	if buffManagerData.bdList[info.target] == nil then return end
	
	local debugId  
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "combatDeath") end
	
	buffManagerData.combatCheck[info.target] = nil
	
	local temp = {}
	for key, _ in pairs(buffManagerData.bdList[info.target]) do
		temp[key] = true
	end
	
	buffManagerEvents.buffRemove (_, info.target, temp)
	
	if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "combatDeath", debugId) end
	
end

-- Handles combat damage events.
-- @param _ Unused parameter.
-- @param info Table containing combat damage information.
function buffManagerEvents.combatDamage(_, info)

	local debugId  
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "combatDamage") end

	-- !!!!! Hier liegt das Problem bei grossen Gruppen. Es wird für Target und Caster heftigst gepollt

	if not LibEKLUnitGetUnitDetail then LibEKLUnitGetUnitDetail = LibEKLUnitGetUnitDetail end
	
	if info.target ~= nil then
		local details = LibEKLUnitGetUnitDetail(info.target)
		if details ~= nil and details.player ~= true then
			if buffManagerData.combatUnits["*"] ~= nil or buffManagerData.combatUnits[details.type] ~= nil then checkCombatUnit(info.target) end
		end
	end
	
	
	if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "combatDamage", debugId) end

end