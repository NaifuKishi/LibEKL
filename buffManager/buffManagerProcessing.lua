local addonInfo, privateVars = ...

---------- init namespace ---------

if not LibEKL then LibEKL = {} end
if not LibEKL.BuffManager then LibEKL.BuffManager = {} end

if not privateVars.buffManagerEvents then privateVars.buffManagerEvents = {} end
if not privateVars.buffManagerData then privateVars.buffManagerData = {} end

local internalFunc		= privateVars.internalFunc
local data        		= privateVars.data
local buffManagerData	= privateVars.buffManagerData
local buffManagerEvents = privateVars.buffManagerEvents

local inspectBuffList		= Inspect.Buff.List
local inspectBuffDetail		= Inspect.Buff.Detail
local inspectTimeReal		= Inspect.Time.Real
local inspectAddonCurrent	= Inspect.Addon.Current

local stringFind	= string.find
local stringUpper	= string.upper
local stringFormat	= string.format

local LibEKLUnitGetUnitIDByType
local LibEKLToolsTableIsMember

-- Retrieves the buff type by its real ID.
-- @param unit The unit ID associated with the buff.
-- @param buffId The real ID of the buff.
-- @return The buff type if found, nil otherwise.
local function getTypeByRealID (unit, buffId)

	local debugId  
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "getTypeByRealID") end

	for buffType, realId in pairs(buffManagerData.bdByType[unit]) do
		if realId == buffId then
			if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "getTypeByRealID", debugId) end
			return buffType
		end
	end
	
	if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "getTypeByRealID", debugId) end
	
	return nil

end

-- Retrieves the real ID of a buff by its type.
-- @param unit The unit ID associated with the buff.
-- @param buffType The type of the buff.
-- @return The real ID of the buff if found, nil otherwise.
local function getRealIDByType (unit, buffType)

	if buffManagerData.bdByType[unit] == nil then return nil end
	
	local debugId  
	if nkDebug then debugId = nkDebug.traceStart (addonInfo.identifier, "getRealIDByType") end

	for thisBuffType, realID in pairs(buffManagerData.bdByType[unit]) do
		if buffType == thisBuffType then
			if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "getRealIDByType", debugId) end
			return realID
		end
	end
	
	if nkDebug then debugId = nkDebug.traceEnd (addonInfo.identifier, "getRealIDByType", debugId) end
	
	return nil

end

-- Processes the list of buffs and debuffs to check for updates.
-- @return true if updates were found, false otherwise, and a table of updates.
local function processBuffDebuffList()

	local debugId  
	if nkDebug then debugId = nkDebug.traceStart (inspectAddonCurrent(), "processBuffDebuffList") end
	
	local _curTime = inspectTimeReal()

	local updateList = {}
	local updatesFound = false

	for unit, buffList in pairs(buffManagerData.processBDList) do

		for buffId, _ in pairs(buffList) do
		
			local thisBuff = buffManagerData.buffCache1st[unit][buffId]

			if thisBuff.remaining ~= nil then
					if thisBuff.remaining <= 1 or _curTime - thisBuff.lastChange >= 1 then
						thisBuff.remaining = thisBuff.duration - (_curTime - thisBuff.start)
						if thisBuff.remaining < 0 then thisBuff.remaining = 0 end					
						thisBuff.lastChange = _curTime						
						local thisBuffType = getTypeByRealID (unit, buffId)
						if thisBuffType ~= nil then
							if updateList[unit] == nil then updateList[unit] = {} end
							table.insert(updateList[unit], thisBuffType)
							updatesFound = true
						end
					end
				--end
			end
		end
	end
	
	if nkDebug then nkDebug.traceEnd (inspectAddonCurrent(), "processBuffDebuffList", debugId) end
	
	return updatesFound, updateList

end

-- Processes buff and debuff updates.
-- @param updateList Table containing units and buff types that need updating.
-- @return true if updates were found, false otherwise, and tables of updates and stops.
local function processBuffDebuffUpdates (updateList)

	local debugId  
	if nkDebug then debugId = nkDebug.traceStart (inspectAddonCurrent(), "processBuffDebuffUpdates") end
	
	if not LibEKLUnitGetUnitIDByType then LibEKLUnitGetUnitIDByType = LibEKL.Unit.GetUnitIDByType end
	if not LibEKLToolsTableIsMember then LibEKLToolsTableIsMember = LibEKL.Tools.Table.IsMember end

	local updates, hasUpdates = {}, false
	local stop, hasStop = {}, false

	for addon, bTypeList in pairs(dataBuffManager.subscriptions) do
		
		for bType, sList in pairs(bTypeList) do
			
			local buffType = "buff"
			if bType == "DEBUFFS" then buffType = "debuff" end
			
			for buffId, sDetails in pairs(sList) do
			
				local unitId = LibEKLUnitGetUnitIDByType(sDetails.target)
				
				if unitId ~= nil then
				
					for _, thisUnitId in pairs(unitId) do
				
						if updateList[thisUnitId] ~= nil and LibEKLToolsTableIsMember(updateList[thisUnitId], buffId) then
							local buffDetails = LibEKL.BuffManager.GetBuffDetails(thisUnitId, buffId)
							
							if buffDetails ~= nil then
							
								if buffDetails.remaining ~= nil and buffDetails.remaining <= 0 then
									if stop[addon] == nil then stop[addon] = {} end
									if stop[addon][thisUnitId] == nil then stop[addon][thisUnitId] = {} end
									
									stop[addon][thisUnitId][buffId] = { bType = buffType, typeKey = buffDetails.type, target = sDetails.target, name = buffDetails.name, id = buffId, stack = buffDetails.stack }
									hasStop = true
									
								else
									if updates[addon] == nil then updates[addon] = {} end
									if updates[addon][thisUnitId] == nil then updates[addon][thisUnitId] = {} end
									
									updates[addon][thisUnitId][buffId] = { bType = buffType, typeKey = buffDetails.type, target = sDetails.target, name = buffDetails.name, id = buffId, remaining = buffDetails.remaining, stack = buffDetails.stack }
									hasUpdates = true
								end
							end
						end
					end
				end
			end
		end
	
	end
	
	if nkDebug then nkDebug.traceEnd (inspectAddonCurrent(), "processBuffDebuffUpdates", debugId) end
	
	return hasUpdates, updates, hasStop, stop

end

-- Processes buffs for all units.
function internalFunc.processBuffs ()

	local debugId  
	if nkDebug then debugId = nkDebug.traceStart (inspectAddonCurrent(), "LibEKL internalFunc.processBuffs") end

	if buffManagerData.managerInit == false then
		if nkDebug then nkDebug.traceEnd (inspectAddonCurrent(), "LibEKL internalFunc.processBuffs", debugId) end
		return
	end
	
	local updatesFound, updateList = processBuffDebuffList()
	
	if not updatesFound then
		if nkDebug then nkDebug.traceEnd (inspectAddonCurrent(), "LibEKL internalFunc.processBuffs", debugId) end
		return
	end

	local hasUpdates, updates, hasStop, stop = processBuffDebuffUpdates (updateList)

	if hasUpdates == true then 
		for addon, unitList in pairs(updates) do
			for unitId, changeList  in pairs(unitList) do
				LibEKL.eventHandlers["LibEKL.BuffManager"]["Change"](unitId, addon, changeList) 
			end
		end
	end
	
	if hasStop == true then 
		for addon, unitList in pairs(stop) do
			for unitId, removeList  in pairs(unitList) do
				LibEKL.eventHandlers["LibEKL.BuffManager"]["Remove"](unitId, addon, removeList) 
			end
		end
	end

	if nkDebug then nkDebug.traceEnd (inspectAddonCurrent(), "LibEKL internalFunc.processBuffs", debugId) end

end