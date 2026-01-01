local addonInfo, privateVars = ...

---------- init namespace ---------

if not LibEKL then LibEKL = {} end
if not LibEKL.Unit then LibEKL.Unit = {} end

local lang        	= privateVars.langTexts
local data        	= privateVars.data
local unitData		= privateVars.unitData
local unitEvents 	= privateVars.unitEvents

local inspectTimeReal		= Inspect.Time.Real
local inspectUnitLookup		= Inspect.Unit.Lookup
local inspectUnitDetail		= Inspect.Unit.Detail

local stringFind	= string.find
local stringFormat	= string.format

---------- local function block ---------

local function groupStatus ()

	if unitData.isRaid == true then
		--print ("raid")
		LibEKL.eventHandlers["LibEKL.Unit"]["GroupStatus"]('raid', unitData.raidMembers)
	elseif unitData.isGroup == true then
		--print ("group")
		LibEKL.eventHandlers["LibEKL.Unit"]["GroupStatus"]('group', unitData.groupMembers)
	else
		--print ("single")
		LibEKL.eventHandlers["LibEKL.Unit"]["GroupStatus"]('single', nil)
	end

end

local function processUnitInfo (unitInfo)

	for k, v in pairs (unitInfo) do
		unitEvents.processUnitChange(v, k)
	end
	
end

---------- event function block ---------

function unitEvents.setIDCache(key, value, flag, source)

	--if nkDebug and value then nkDebug.logEntry (addonInfo.identifier, "unitEvents.setIDCache", key, {source = source, value = value, flag = flag}) end

	if key == value then return end
	
	if flag == false then
		if unitData.idCache[key] == nil then return end
		LibEKL.Tools.Table.RemoveValue (unitData.idCache[key], value)
		if #unitData.idCache[key] == 0 then unitData.idCache[key] = nil end
	else
		if unitData.idCache[key] == nil then
			unitData.idCache[key] = {}
		end
		
		if not LibEKL.Tools.Table.IsMember (unitData.idCache[key], value) then
			table.insert(unitData.idCache[key], value)
		end
		
	end

end

function unitEvents.combatDamage(_, info)

	if info.caster ~= nil and unitData.unitCache[info.caster] == nil then 
		local temp = inspectUnitDetail(info.caster)
	
		if temp ~= nil and temp.player ~= true then
			unitData.unitCache[info.caster] = temp
			
			unitEvents.setIDCache(unitData.unitCache[info.caster].type, info.caster, true, "unitEvents.combatDamage")
			
			unitData.unitCache[info.caster].lastUpdate = inspectTimeReal()
			LibEKL.eventHandlers["LibEKL.Unit"]["Available"]({[info.caster] = "combatlog"})
			
			if unitData.debugUI then unitData.debugUI:Update() end
		end
	end
	
	if info.target ~= nil and unitData.unitCache[info.target] == nil then
		local temp = inspectUnitDetail(info.caster)
	
		if temp ~= nil and temp.player ~= true then
			unitData.unitCache[info.target] = temp
			
			unitEvents.setIDCache(unitData.unitCache[info.target].type, info.target, true, "unitEvents.combatDamage")
			
			unitData.unitCache[info.target].lastUpdate = inspectTimeReal()
			LibEKL.eventHandlers["LibEKL.Unit"]["Available"]({[info.target] = "combatlog"})
			
			if unitData.debugUI then unitData.debugUI:Update() end
		end
	end

end


--[[
local function _fctCombatDeath(_, info)

	if info.target ~= nil then
		
		local unitTypes = LibEKL.Unit.getUnitTypes (info.target)
		if unitTypes == nil then return end
		
		for key, _ in pairs(unitTypes) do
		
			unitEvents.setIDCache(key, info.target, false, "_fctCombatDeath")
			unitData.unitCache[info.target] = nil
			LibEKL.eventHandlers["LibEKL.Unit"]["Unavailable"]({[info.target] = false})
					
			if unitData.debugUI then unitData.debugUI:Update() end
		end
	end

end
]]

function unitEvents.unitAvailableHandler (_, unitInfo)

	if nkDebug then nkDebug.logEntry (addonInfo.identifier, "unitEvents.unitAvailableHandler", "Startup", unitInfo) end

	local tempUnitInfo = {}
	local fireEvent = false

	for unitId, unitType in pairs (unitInfo) do

		if unitType ~= false and stringFind(unitType, 'mouseover') == nil then
			if stringFind (unitType, 'group..%.target') ~= nil and unitId == unitData.idCache.player then
				tempUnitInfo[inspectUnitLookup(unitType)] = unitType
			else
				tempUnitInfo[unitId] = unitType				
				unitData.unitCache[unitId] = inspectUnitDetail(unitId)
				unitData.unitCache[unitId].lastUpdate = inspectTimeReal()
				
				unitEvents.setIDCache(unitType, unitId, true, "unitEvents.unitAvailableHandler")
			end

			fireEvent = true
		
			-- process groups if unitType indicated group

			if stringFind(unitType, 'group') == 1 and stringFind(unitType, 'group..%.') == nil then

				for idx = 1, 20, 1 do
					local tempUnitType = stringFormat('group%02d', idx)
					local tempUnitId = inspectUnitLookup(tempUnitType)
					unitEvents.processUnitChange (tempUnitType, tempUnitId)
					
					local tempUnitType = stringFormat('group%02d.target', idx)
					local tempUnitId = inspectUnitLookup(tempUnitType)
					unitEvents.processUnitChange (tempUnitType, tempUnitId)
					
					local tempUnitType = stringFormat('group%02d.pet', idx)
					local tempUnitId = inspectUnitLookup(tempUnitType)
					unitEvents.processUnitChange (tempUnitType, tempUnitId)
				end
			end
			
			-- regular unit change processing

			unitEvents.processUnitChange (unitType, unitId)
			
			-- specific check for player in group

			if unitType == 'player' then
				-- gotta check if player is in a group as Rift API is just stupid

				local lookupTable = {}

				for idx = 1, 20, 1 do
					local tempUnitType = stringFormat('group%02d', idx)
					lookupTable[tempUnitType] = true
				end

				local tempUnitIList= inspectUnitLookup(lookupTable)
				for identifier, thisUnitID in pairs ( tempUnitIList ) do
					if unitId == thisUnitID then
						unitEvents.processUnitChange (identifier, thisUnitID)
					end
				end

				if nkDebug then nkDebug.logEntry (addonInfo.identifier, "unitEvents.unitAvailableHandler", "player group lookup", tempUnitIList) end

				LibEKL.eventHandlers["LibEKL.Unit"]["PlayerAvailable"](unitData.unitCache[unitId])
			end
		end	
	end

	if nkDebug then nkDebug.logEntry (addonInfo.identifier, "unitEvents.unitAvailableHandler", "unit info", tempUnitInfo) end

	if fireEvent then LibEKL.eventHandlers["LibEKL.Unit"]["Available"](tempUnitInfo) end
	
	if unitData.debugUI then unitData.debugUI:Update() end

end

function unitEvents.unitUnAvailableHandler (_, unitInfo)

	if nkDebug then nkDebug.logEntry (addonInfo.identifier, "unitEvents.unitUnAvailableHandler", "Startup", unitInfo) end

	for unitId, _ in pairs (unitInfo) do
	
		local unitTypes = LibEKL.Unit.getUnitTypes (unitId)
		
		for idx = 1, #unitTypes, 1 do
			unitEvents.processUnitChange (unitTypes[idx], nil)
		end
	end	
	
	LibEKL.eventHandlers["LibEKL.Unit"]["Unavailable"](unitInfo)

	if unitData.debugUI then unitData.debugUI:Update() end
	
end

function unitEvents.unitChange (unitId, unitType)

	if nkDebug then nkDebug.logEntry (addonInfo.identifier, "unitEvents.unitChange", unitId, unitType) end

	unitData.idCache[unitType] = {}
	
	if unitId == false then
		unitEvents.processUnitChange(unitType, nil)
	else
		unitEvents.setIDCache(unitType, unitId, true, 'unitEvents.unitChange')
		
		local details = inspectUnitDetail(unitType)
		if details ~= nil and details.player ~= true then
			unitEvents.setIDCache(details.type, unitId, true, 'unitEvents.unitChange')
		
			unitData.unitCache[unitId] = details
			unitData.unitCache[unitId].lastUpdate = inspectTimeReal()
		end
		
		unitEvents.processUnitChange(unitType, unitId)
	end
	
	if unitData.subscriptions[unitType] == nil then return end
	
	for addon, _ in pairs(unitData.subscriptions[unitType]) do
		LibEKL.eventHandlers["LibEKL.Unit"]["Change"](unitId, unitType)
		
		if unitData.debugUI then unitData.debugUI:Update() end
		break
	end

end

function unitEvents.processUnitChange (unitType, unitId)

	if unitId == false or unitId == nil then
		 unitEvents.setIDCache(unitType, nil, false, 'unitEvents.processUnitChange')
	else
		 unitEvents.setIDCache(unitType, unitId, true, 'unitEvents.processUnitChange')
	end

	--print ("---------------------------------")

	if stringFind(unitType, 'group') == 1 and stringFind (unitType, 'group..%.') == nil then

		-- process groups and check for group size change

		local newStatus = nil
		unitData.groupMembers, unitData.raidMembers = 0, 0

		local thisIsGroup, thisIsRaid = false, false

		for idx = 1, 20, 1 do
			local thisGroupTable = unitData.idCache[stringFormat('group%02d', idx)]
			--dump (idx, thisGroupTable)			

			if thisGroupTable and next(thisGroupTable) ~= nil then 				
				if idx > 5 then 
					thisIsRaid = true 
					thisIsGroup = false
					unitData.groupMembers = 0
					unitData.raidMembers = unitData.raidMembers + 1
				else
					thisIsGroup = true
					unitData.groupMembers = unitData.groupMembers + 1 
					unitData.raidMembers = unitData.raidMembers + 1
				end
			end
		end

		--print ("raid", thisIsRaid, unitData.isRaid)
		--print ("group", thisIsGroup, unitData.isGroup)

		if thisIsRaid == true and unitData.isRaid == false then
			unitData.isRaid = true
			groupStatus()
		elseif thisIsGroup == true and unitData.isGroup == false then
			unitData.isGroup = true
			groupStatus()
		end
		
	elseif stringFind(unitType, 'group..%.pet') == 1 or stringFind(unitType, 'group..%.target') == 1 then
		if unitData.idCache[unitType] == nil then
			local luID = inspectUnitLookup(unitType)
			if luID ~= nil then 
				local unitInfoTable = {}
				unitInfoTable[luID] = unitType
				processUnitInfo (unitInfoTable)
			end
		end
	elseif stringFind(unitType, 'player') == 1 then
		
		local playerId = inspectUnitLookup('player')
	
		for idx = 1, 20, 1 do
			local luID = inspectUnitLookup(stringFormat('group%02d', idx))
			
			if luID == playerId then
				local unitInfoTable = {}
				if unitId == nil then
					unitInfoTable[false] = stringFormat('group%02d', idx)
				else
					unitInfoTable[luID] = stringFormat('group%02d', idx)
				end
				processUnitInfo (unitInfoTable)
				break
			end
		end
	end

end