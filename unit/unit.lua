local addonInfo, privateVars = ...

---------- init namespace ---------

if not LibEKL then LibEKL = {} end
if not LibEKL.Unit then LibEKL.Unit = {} end

if not privateVars.unitEvents then privateVars.unitEvents = {} end
if not privateVars.unitData then privateVars.unitData = {} end

local lang  		= privateVars.langTexts
local data  		= privateVars.data
local unitData		= privateVars.unitData
local unitEvents 	= privateVars.unitEvents

local inspectTimeReal		= Inspect.Time.Real
local inspectAddonCurrent 	= Inspect.Addon.Current
local inspectUnitLookup		= Inspect.Unit.Lookup
local inspectUnitDetail		= Inspect.Unit.Detail
local inspectUnitList		= Inspect.Unit.List

local stringFind	= string.find
local stringFormat	= string.format

---------- init local variables ---------

unitData.unitCache = {}
unitData.idCache = {}
unitData.subscriptions = {}
unitData.unitManager = false
unitData.isRaid = false
unitData.isGroup = false
unitData.isGroup = false
unitData.groupMembers = 0
unitData.raidMembers = 0
unitData.watchUnits = {'player', 'player.pet', 'player.target', 'player.target.target', 'focus', 'focus.target'}
unitData.debugUI = nil

---------- local function block ---------


--[[
   _init
    Description:
        Initializes the unit management system.
        Sets up event handlers and subscriptions for unit tracking.
    Parameters:
        None
    Returns:
        None
    Process:
        1. Checks if the unit manager is already initialized
        2. Sets up event handlers for unit availability and changes
        3. Creates necessary events for unit management
        4. Subscribes to combat events for unit tracking
        5. Registers watch units for tracking
        6. Sets up group and raid tracking
    Notes:
        - This function should be called once at addon initialization
        - Sets up the foundation for all unit tracking functionality
        - Creates events that other parts of the addon can subscribe to
]]
function LibEKL.Unit.init()

	unitData.subscriptions[inspectAddonCurrent()] = {} -- probably useless

	if unitData.unitManager == true then return end

	if LibEKL.Events.CheckEvents ("LibEKL.Unit", true) == false then return nil end

	Command.Event.Attach(Event.Unit.Availability.Full, unitEvents.unitAvailableHandler, "LibEKL.Unit.Availability.Full")
	Command.Event.Attach(Event.Unit.Availability.None, unitEvents.unitUnAvailableHandler, "LibEKL.Unit.Availability.None")
	
	LibEKL.eventHandlers["LibEKL.Unit"]["PlayerAvailable"], LibEKL.Events["LibEKL.Unit"]["PlayerAvailable"] = Utility.Event.Create(addonInfo.identifier, "LibEKL.Unit.PlayerAvailable")
	LibEKL.eventHandlers["LibEKL.Unit"]["GroupStatus"], LibEKL.Events["LibEKL.Unit"]["GroupStatus"] = Utility.Event.Create(addonInfo.identifier, "LibEKL.Unit.GroupStatus")
	LibEKL.eventHandlers["LibEKL.Unit"]["Available"], LibEKL.Events["LibEKL.Unit"]["Available"] = Utility.Event.Create(addonInfo.identifier, "LibEKL.Unit.Available")
	LibEKL.eventHandlers["LibEKL.Unit"]["Unavailable"], LibEKL.Events["LibEKL.Unit"]["Unavailable"] = Utility.Event.Create(addonInfo.identifier, "LibEKL.Unit.Unavailable")
	LibEKL.eventHandlers["LibEKL.Unit"]["Change"], LibEKL.Events["LibEKL.Unit"]["Change"] = Utility.Event.Create(addonInfo.identifier, "LibEKL.Unit.Change")
	
	Command.Event.Attach(Event.Combat.Damage, unitEvents.combatDamage, "LibEKL.Combat.Damage")
	
	for idx = 1, #unitData.watchUnits, 1 do
		local unitEvent = Library.LibUnitChange.Register(unitData.watchUnits[idx])
		Command.Event.Attach(unitEvent, function (_, unitInfo) unitEvents.unitChange(unitInfo, unitData.watchUnits[idx]) end, "LibEKL.Unit.unitChange." .. unitData.watchUnits[idx])
	end

	for idx = 1, 20, 1 do
		local unitEvent = Library.LibUnitChange.Register(stringFormat('group%02d', idx))
		Command.Event.Attach(unitEvent, function (_, unitInfo) unitEvents.unitChange(unitInfo, stringFormat('group%02d', idx)) end, "LibEKL.Unit.unitChange." .. stringFormat('group%02d', idx))

		if idx <= 5 then
			local unitEvent = Library.LibUnitChange.Register(stringFormat('group%02d', idx) .. '.target')
			Command.Event.Attach(unitEvent, function (_, unitInfo) unitEvents.unitChange(unitInfo, stringFormat('group%02d', idx) .. '.target') end, "LibEKL.Unit.unitChange." .. stringFormat('group%02d', idx) .. ".target")
			
			local unitEvent = Library.LibUnitChange.Register(stringFormat('group%02d', idx) .. '.pet')
			Command.Event.Attach(unitEvent, function (_, unitInfo) unitEvents.unitChange(unitInfo, stringFormat('group%02d', idx) .. '.pet') end, "LibEKL.Unit.unitChange." .. stringFormat('group%02d', idx) .. ".pet")
		end
	end

	--if nkDebug then unitData.debugUI = LibEKL.Unit.buildDebugUI() end
	
	unitData.unitManager = true

end

--[[
   _subscribe
    Description:
        Subscribes to unit change events for a specific unit type.
        This allows addons to receive notifications when the specified unit changes.
    Parameters:
        sType (string): The unit type to subscribe to (e.g., "player.target")
    Returns:
        None
    Process:
        1. Adds the current addon to the subscriptions list for the unit type
        2. Immediately processes the current state of the unit
    Notes:
        - Use this to receive notifications when a specific unit changes
        - The addon will receive Change events for the specified unit type
]]
function LibEKL.Unit.subscribe(sType)

	if unitData.subscriptions == nil then unitData.subscriptions = {} end
	if unitData.subscriptions[sType] == nil then unitData.subscriptions[sType] = {} end

	unitData.subscriptions[sType][inspectAddonCurrent()] = true
	
	if sType == 'player.target' then
		local targetID = inspectUnitLookup('player.target')
		if targetID ~= nil then unitEvents.processUnitChange ('player.target', targetID) end
	elseif sType == 'focus' then
		local focusID = inspectUnitLookup('focus')
		if focusID ~= nil then unitEvents.processUnitChange ('focus', focusID) end
	end

end

--[[
   _unsubscribe
    Description:
        Unsubscribes from unit change events for a specific unit type.
        Stops receiving notifications for the specified unit type.
    Parameters:
        sType (string): The unit type to unsubscribe from
    Returns:
        None
    Process:
        1. Removes the current addon from the subscriptions list for the unit type
    Notes:
        - Use this to stop receiving notifications for a specific unit type
]]

function LibEKL.Unit.unsubscribe(sType)

	if unitData.subscriptions[sType] ~= nil then
		subscriptions[sType][inspectAddonCurrent()] = nil
	end

end


--[[
   _getGroupStatus
    Description:
        Returns the current group status.
        Indicates whether the player is in a group, raid, or acting alone.
    Parameters:
        None
    Returns:
        status (string): The current group status ("single", "group", or "raid")
        count (number): The number of group/raid members (nil for single)
    Notes:
        - Useful for determining the player's current group situation
        - The count parameter is nil when status is "single"
]]
function LibEKL.Unit.getGroupStatus ()

	if unitData.isRaid == true then
		return 'raid', unitData.raidMembers
	elseif unitData.isGroup == true then
		return 'group', unitData.groupMembers
	else
		return 'single', nil
	end

end

--[[
   _getUnitIDByType
    Description:
        Gets unit IDs by unit type.
        Returns all unit IDs that match the specified unit type.
    Parameters:
        unitType (string): The unit type to look up
    Returns:
        unitIDs (table): A table of unit IDs that match the unit type
    Notes:
        - Returns nil if no units match the specified type
        - The table may contain multiple unit IDs for the same type
]]
function LibEKL.Unit.GetUnitIDByType (unitType)

	if unitData.idCache[unitType] == nil then
		local flag, details = pcall (inspectUnitDetail, unitType)
		if flag and details ~= nil then
			unitEvents.setIDCache(unitType, details.id, true, 'LibEKL.Unit.GetUnitIDByType')
			unitData.unitCache[details.id] = details
			unitData.unitCache[details.id].lastUpdate = inspectTimeReal()
		end
	else
		--print "cache not nil"
	end
	
	return unitData.idCache[unitType] 
end

--[[
   _getUnitTypes
    Description:
        Gets all unit types for a specific unit ID.
        Returns all unit types that the specified unit ID belongs to.
    Parameters:
        unitID (string): The unit ID to look up
    Returns:
        unitTypes (table): A table of unit types that the unit ID belongs to
    Notes:
        - Returns an empty table if the unit ID is not found
        - A unit can belong to multiple types (e.g., "player" and "group01")
]]

function LibEKL.Unit.getUnitTypes (unitID) 

	local retValues = {}

	for unitType, list in pairs (unitData.idCache) do
		if LibEKL.Tools.Table.IsMember(list, unitID) then
			table.insert(retValues, unitType) 
		end
	end
	
	return retValues

end

--[[
   _GetUnitDetail
    Description:
        Gets detailed information about a unit.
        Returns a table with detailed information about the specified unit.
    Parameters:
        unitID (string): The unit ID to get details for
		This can also by unit type like player
    Returns:
        unitDetails (table): A table with detailed information about the unit
    Notes:
        - Returns nil if the unit ID is not found
        - The returned table contains various unit properties
        - Information is cached to minimize API calls
]]
function LibEKL.Unit.GetUnitDetail (unitID, force)

	if unitID ==nil then return nil end

	if unitData.idCache[unitID] ~= nil and #unitData.idCache[unitID] > 0 then
		unitID = unitData.idCache[unitID][1] -- check for case taht unitID is a unit type like player
	end

	--print ("LibEKL.Unit.GetUnitDetail", unitID)
	
	if force == true or unitData.unitCache[unitID] == nil then
		local temp = inspectUnitDetail(unitID)
		if temp ~= nil then
			unitData.unitCache[temp.id] = temp
			unitData.unitCache[temp.id].lastUpdate = inspectTimeReal()
		end
	end
	
	return unitData.unitCache[unitID]

end

function LibEKL.Unit.GetUnitByIdentifier (identifier)

	local units = inspectUnitList()
	for unitId, thisIdentifier in pairs(units) do
		if thisIdentifier == identifier then return unitId end
	end

	if identifier == "player.target" then -- if player targets himself this is needed
		local details = inspectUnitDetail("player.target")
		if details then return details.id end
	end

	return nil

end

function LibEKL.Unit.UpdateGroupUnit()

	local addon = inspectAddonCurrent()
	local unitInfo = {}
	local callEvent = false

	for unitType, value in pairs (unitData.subscriptions) do
		if value[addon] == true then
			if stringFind(unitType, "group") then
				local unitID = LibEKL.Unit.GetUnitIDByType (unitType) 				
				if unitID then
					for key, thisUnit in pairs(unitID) do
						unitInfo[thisUnit] = unitType
						callEvent = true
					end
				end	
			end
		end
	end

	if callEvent then 
		if nkDebug then nkDebug.logEntry (addonInfo.identifier, "LibEKL.Unit.UpdateGroupUnit", "", unitInfo) end
		unitEvents.unitAvailableHandler (_, unitInfo)
	end

end


--[[
   _getPlayerDetails
    Description:
        Gets detailed information about the player.
        Returns a table with detailed information about the player unit.
    Parameters:
        None
    Returns:
        playerDetails (table): A table with detailed information about the player
    Notes:
        - This is a convenience function for getting player unit details
        - The returned table contains various player properties
]]
function LibEKL.Unit.getPlayerDetails()
  
	if unitData.idCache.player == nil or unitData.unitCache[unitData.idCache.player[1]] == nil then 
		local temp = inspectUnitDetail('player') 
		
		if temp.id ~= 'player' then
			unitEvents.setIDCache('player', temp.id, true, 'LibEKL.Unit.getPlayerDetails')
			unitData.unitCache[unitData.idCache.player[1]] = temp
			unitData.unitCache[unitData.idCache.player[1]].lastUpdate = inspectTimeReal()
		end
		
		return temp
	end
	
	return unitData.unitCache[unitData.idCache.player[1]]
   
end

function LibEKL.Unit.getPlayerID()
  
	return LibEKL.Unit.getPlayerDetails().id
   
end



function LibEKL.Unit.setPlayerDetails(detail, value)
	LibEKL.Unit.getPlayerDetails()
	unitData.unitCache[unitData.idCache.player[1]][detail] = value
end

--[[
   _getCallingText
    Description:
        Gets localized text for a calling.
        Returns the localized text for the specified calling.
    Parameters:
        calling (string): The calling to get text for
    Returns:
        callingText (string): The localized text for the calling
    Notes:
        - Returns nil if the calling is not found
        - Uses the addon's language settings for localization
]]
function LibEKL.Unit.getCallingText (calling) return lang.callings[calling] end