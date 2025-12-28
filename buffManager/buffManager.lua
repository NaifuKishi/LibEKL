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

local inspectAddonCurrent	= Inspect.Addon.Current

local stringUpper	= string.upper
local stringFind	= string.find

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

function LibEKL.BuffManager.init()

	local debugId  
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "LibEKL.BuffManager.init") end

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
	
	if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "LibEKL.BuffManager.init", debugId) end

end

function LibEKL.BuffManager.subscribe(sType, sId, castBy, sTarget, sStack)

	local debugId  
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "LibEKL.BuffManager.subscribe") end

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
				LibEKL.BuffManager.initUnitBuffs(unitId) 
			else
				if list[unitId] == nil then list[unitId] = {} end
				
				for k, v in pairs(thisList) do
					list[unitId][k] = true
					runEvent = true
				end
			end
		end
	else
		local unitIdList = LibEKL.Unit.getUnitIDByType(sTarget)
		if unitIdList ~= nil then
		
			for _, unitId in pairs(unitIdList) do
				if buffManagerData.trackedUnits[unitId] ~= true then 
					LibEKL.BuffManager.initUnitBuffs(unitId) 
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
			buffAdd (_, unitId, buffList) 
		end
	end
	
	if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "LibEKL.BuffManager.subscribe", debugId) end
	
end

function LibEKL.BuffManager.unsubscribe(sType, sId)

	local debugId  
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "LibEKL.BuffManager.unsubscribe") end

	if buffManagerData.subscriptions[inspectAddonCurrent()] ~= nil and buffManagerData.subscriptions[inspectAddonCurrent()][sType] ~= nil and buffManagerData.subscriptions[inspectAddonCurrent()][sType][sId] ~= nil then
	
		local thisSubscription = buffManagerData.subscriptions[inspectAddonCurrent()][sType][sId]
		if stringFind(thisSubscription.target, "addonType") ~= nil then
			local sTarget = LibEKL.strings.right (thisSubscription.target, "addonType", 1, true)
			
			if buffManagerData.combatUnits[sTarget] ~= nil then 
				buffManagerData.combatUnits[sTarget] = LibEKL.tools.table.removeValue(buffManagerData.combatUnits[sTarget], stringFormat("%s-%s", sType, sId))
				if #buffManagerData.combatUnits[sTarget] == 0 then buffManagerData.combatUnits[sTarget] = nil end
			end
		elseif thisSubscription.target == "*" then
			
			if buffManagerData.combatUnits["*"] ~= nil then 
				buffManagerData.combatUnits["*"] = LibEKL.tools.table.removeValue(buffManagerData.combatUnits["*"], stringFormat("%s-%s", sType, sId))
				if #buffManagerData.combatUnits["*"] == 0 then buffManagerData.combatUnits["*"] = nil end
			end
			
		end
	
		buffManagerData.subscriptions[inspectAddonCurrent()][sType][sId] = nil
	end
	
	if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "LibEKL.BuffManager.unsubscribe", debugId) end

end

function LibEKL.BuffManager.GetBuffDetails(unit, buffId)

	local debugId  
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "LibEKL.BuffManager.GetBuffDetails") end

	if buffManagerData.buffCache1st[unit] == nil then 
		unit = LibEKL.Unit.getUnitIDByType(unit)
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

function LibEKL.BuffManager.initUnitBuffs(unit)

	local debugId  
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "LibEKL.BuffManager.initUnitBuffs") end

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
	
	if hasNewBuffs then buffAdd(_, unit, newBuffList) end
	
	if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "LibEKL.BuffManager.initUnitBuffs", debugId) end
	
	return hasNewBuffs

end

function LibEKL.BuffManager.GetUnitBuffList (unit) 

	local debugId  
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "LibEKL.BuffManager.GetUnitBuffList") end

	if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "LibEKL.BuffManager.GetUnitBuffList", debugId) end
	
	return buffManagerData.buffCache1st[unit]

end

function LibEKL.BuffManager.isBuffActive(unit, id) 

	local debugId  
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "LibEKL.BuffManager.isBuffActive") end

	if buffManagerData.buffCache1st[unit] == nil then 
		local list = LibEKL.Unit.getUnitIDByType(unit)
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
				if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "LibEKL.BuffManager.isBuffActive", debugId) end
				return false
			end
		else
			if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "LibEKL.BuffManager.isBuffActive", debugId) end
			return false
		end
	end
	
	if buffManagerData.buffCache1st[unit][id] ~= nil then
		if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "LibEKL.BuffManager.isBuffActive", debugId) end
		return true
	end
	
	local realID = getRealIDByType(unit, id)
	
	if realID == nil or buffManagerData.buffCache1st[unit][realID] == nil then
		if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "LibEKL.BuffManager.isBuffActive", debugId) end
		return false
	end
	
	if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "LibEKL.BuffManager.isBuffActive", debugId) end
	
	return true

end