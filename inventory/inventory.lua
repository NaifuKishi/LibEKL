local addonInfo, privateVars = ...

---------- init namespace ---------

if not LibEKL then LibEKL = {} end
if not LibEKL.inventory then LibEKL.inventory = {} end

local data			= privateVars.data
local uiElements	= privateVars.uiElements

---------- make global functions local ---------

local inspectItemList           	= Inspect.Item.List
local utilityItemSlotInventory  	= Utility.Item.Slot.Inventory
local utilityItemSlotQuest      	= Utility.Item.Slot.Quest
local utilityItemSlotEquipment		= Utility.Item.Slot.Equipment
local utilityItemSlotBank			= Utility.Item.Slot.Bank
local utilityItemSlotVault			= Utility.Item.Slot.Vault
local inspectItemDetail				= Inspect.Item.Detail
local inspectSystemSecure			= Inspect.System.Secure
local inspectTimeFrame				= Inspect.Time.Frame
local commandSystemWatchdogQuiet	= Command.System.Watchdog.Quiet

local stringFind	= string.find

local LibEKLUnitGetPlayerDetails		= LibEKL.unit.getPlayerDetails

---------- init local variables ---------

local _invManager = false
local debugUI

---------- local function block ---------

local function buildDebugUI ()

	if debugUI then return end

	local name = "LibEKL.inventory.debugUI"

	debugUI = LibEKL.uiCreateFrame("nkFrame", name, privateVars.uiContext)
	debugUI:SetPoint("TOPLEFT", UIParent, "TOPLEFT")
	debugUI:SetBackgroundColor(0, 0, 0, 1)
	debugUI:SetWidth(250)
	debugUI:SetHeight(800)
	
	--local itemCache = LibEKLInv[LibEKLUnitGetPlayerDetails().name].itemCache

	local slotText = {}

	function debugUI:update()

		local inventory = LibEKLInv[LibEKLUnitGetPlayerDetails().name].inventory

		for k, v in pairs(slotText) do
			v.details = nil
			v.text:SetVisible(false)
		end

		for k, v in pairs(inventory.bySlot) do	
			if not LibEKL.strings.startsWith(k, "sibg.") and not LibEKL.strings.startsWith(k, "seqp.") and not LibEKL.strings.startsWith(k, "sqst.") then
				if slotText[k] == nil then
					local thisSlot = LibEKL.uiCreateFrame("nkText", name .. "." .. k, debugUI)				
					slotText[k] = { text = thisSlot, details = v }
				else
					slotText[k].details = v
				end
			end
		end

		local sortedSlots = LibEKL.Tools.Table.GetSortedKeys (slotText)

		local from, object, to = "TOPLEFT", debugUI, "TOPLEFT"

		for idx, slotID in pairs(sortedSlots) do
			local slotInfo = slotText[slotID]

			if slotInfo.details then
				slotInfo.text:SetVisible(true)
				slotInfo.text:SetPoint(from, object, to)
				slotInfo.text:SetText(string.format("%s: %s %d", slotID, slotInfo.details.id, slotInfo.details.stack))
				from, object, to = "TOPLEFT", slotInfo.text, "BOTTOMLEFT"
			end
		end
	end

	debugUI:update()
	
	return debugUI

end

local function storeItem (slot, details)

	if not details then return end

	local inventory = LibEKLInv[LibEKLUnitGetPlayerDetails().name].inventory
	local itemCache = LibEKLInv[LibEKLUnitGetPlayerDetails().name].itemCache
	
	if not details.type then details.type = "t" .. details.id end
	if details.stack == nil then details.stack = 1 end

	local prevId = nil
	if inventory.bySlot[slot] ~= nil then prevId = inventory.bySlot[slot].id end
	
	inventory.bySlot[slot] = { id = details.id, stack = details.stack }
	itemCache[details.id] = { typeId = details.type, stack = details.stack, category = details.category, cooldown = details.cooldown, name = details.name, icon = details.icon, rarity = details.rarity, bind = details.bind, bound = details.bound }
				
	if not inventory.byType[details.type] then
		inventory.byType[details.type] = details.stack
	elseif prevId == details.id then -- just more of the same, details contains new total
		inventory.byType[details.type] = details.stack
	else
		inventory.byType[details.type] = inventory.byType[details.type] + details.stack
	end

	inventory.byID[details.id] = details.type

	if debugUI then debugUI:update() end

end

local function removeItem (slot)

	local inventory = LibEKLInv[LibEKLUnitGetPlayerDetails().name].inventory
	local itemCache = LibEKLInv[LibEKLUnitGetPlayerDetails().name].itemCache
	
	local slotDetails = inventory.bySlot[slot]
	local cacheDetails = itemCache[slotDetails.id]
	
	if cacheDetails == nil then -- wie auch immer das passieren kann
		--print ("cacheDetails == nil")

		local details = inspectItemDetail(slotDetails.id)
		if not details then details = { id = slotDetails.id } end
				
		if not details.type then details.type = "t" .. details.id end
		if details.stack == nil then details.stack = 1 end
		cacheDetails = { typeId = details.type, stack = details.stack, category = details.category, cooldown = details.cooldown, name = details.name, icon = details.icon }

	end
	
	if not inventory.byType[cacheDetails.typeId] then
		inventory.byType[cacheDetails.typeId] = 0
	end
	
	inventory.byType[cacheDetails.typeId] = inventory.byType[cacheDetails.typeId] - slotDetails.stack
	if inventory.byType[cacheDetails.typeId] < 0 then inventory.byType[cacheDetails.typeId] = 0 end
	
	inventory.bySlot[slot] = nil
	itemCache[slotDetails.id] = nil
	inventory.byID[slotDetails.id] = nil

	if debugUI then debugUI:update() end
	
end

local function processItems (list)

	local itemList = inspectItemDetail(list)
	
	for slot, v in pairs(itemList) do		
		if v.id ~= nil then
			storeItem (slot, v)
		end
	end   

end

local function getInventory ()

	if inspectSystemSecure() == false then commandSystemWatchdogQuiet() end

	if (not LibEKLInv[LibEKLUnitGetPlayerDetails().name]) or (not LibEKLInv[LibEKLUnitGetPlayerDetails().name].inventory) then
		LibEKLInv[LibEKLUnitGetPlayerDetails().name] = {}
	end
	
	LibEKLInv[LibEKLUnitGetPlayerDetails().name].inventory = { byID = {}, byType = {}, bySlot = {} }
	LibEKLInv[LibEKLUnitGetPlayerDetails().name].itemCache = {}

	local slots = { inspectItemList(utilityItemSlotInventory()), 
					inspectItemList(utilityItemSlotEquipment()), 
					inspectItemList(utilityItemSlotBank()), 
					inspectItemList(utilityItemSlotVault()), 
					inspectItemList(utilityItemSlotQuest()) }


					for idx = 1, #slots, 1 do
	
		local lu = {}
		
		for slot, key in pairs(slots[idx]) do
		  if key ~= nil and key ~= false then lu[slot] = true end
		end
		
		processItems (lu)
		
	end
	  
end

local function processUpdate (_, updates)

	--dump (updates)

	if LibEKLUnitGetPlayerDetails() == nil then return end

	if (not LibEKLInv[LibEKLUnitGetPlayerDetails().name]) or (not LibEKLInv[LibEKLUnitGetPlayerDetails().name].inventory) then getInventory() end

	local inventory = LibEKLInv[LibEKLUnitGetPlayerDetails().name].inventory
	local itemCache = LibEKLInv[LibEKLUnitGetPlayerDetails().name].itemCache

	local updatedKeys = {}
	local updatedSlots = {}

	for slot, key in pairs(updates) do
	
		if not LibEKL.strings.startsWith(slot, 'sg') then

			if key == "nil" then key = false end

			if inventory.bySlot[slot] ~= nil then -- target slot is not empty
			
				if not inventory.bySlot[slot].id then -- content of slot not known => Error
					print ('content of slot not known')
				else
					if key ~= inventory.bySlot[slot].id then -- not just more of the same
						if updatedKeys[inventory.bySlot[slot].id] == nil then updatedKeys[inventory.bySlot[slot].id] = 0 end
												
						updatedKeys[inventory.bySlot[slot].id] = updatedKeys[inventory.bySlot[slot].id] - inventory.bySlot[slot].stack						
						removeItem (slot)
						updatedSlots[slot] = false
					end
				end
			end

			if key ~= false then
				local updateDetails = inspectItemDetail(key)
				
				if updateDetails ~= nil then
					if updateDetails.stack == nil then updateDetails.stack = 1 end
					local qty = 0
					
					if inventory.bySlot[slot] ~= nil and inventory.bySlot[slot].id == updateDetails.id then
						-- more of the same, get update qty
						qty = updateDetails.stack - inventory.bySlot[slot].stack
					end
					
					storeItem(slot, updateDetails)
					if updatedKeys[inventory.bySlot[slot].id] == nil then updatedKeys[inventory.bySlot[slot].id] = 0 end
					
					if qty == 0 then qty = inventory.bySlot[slot].stack	end
					updatedKeys[inventory.bySlot[slot].id] = updatedKeys[inventory.bySlot[slot].id] + qty
					updatedSlots[slot] = inventory.bySlot[slot].id
				end
			end
			
		end
	end

	--dump (updatedSlots)

	LibEKL.eventHandlers["LibEKL.InventoryManager"]["Update"](updatedKeys)
	LibEKL.eventHandlers["LibEKL.InventoryManager"]["SlotUpdate"](updatedSlots)

end

---------- deprecated function block ---------

function LibEKL.inventory.querySlotByKey (key)

	return LibEKL.inventory.querySlotByType (key)

end

function LibEKL.inventory.queryByKey (key)

	return LibEKL.inventory.queryQtyById (key)

end

---------- library public function block ---------

function LibEKL.inventory.init (updateFlag, showDebugUI)

	if not _invManager then
	
		if LibEKL.events.checkEvents ("LibEKL.InventoryManager", true) == false then return nil end
		
		if not LibEKLInv then LibEKLInv = {} end
		
		Command.Event.Attach(Event.Item.Slot, processUpdate, "LibEKL.inventory.Item.Slot")
		Command.Event.Attach(Event.Item.Update, processUpdate, "LibEKL.inventory.Item.Update")
		
		LibEKL.eventHandlers["LibEKL.InventoryManager"]["Update"], LibEKL.events["LibEKL.InventoryManager"]["Update"] = Utility.Event.Create(addonInfo.identifier, "LibEKL.InventoryManagerUpdate")
		LibEKL.eventHandlers["LibEKL.InventoryManager"]["SlotUpdate"], LibEKL.events["LibEKL.InventoryManager"]["SlotUpdate"] = Utility.Event.Create(addonInfo.identifier, "LibEKL.InventoryManagerSlotUpdate")

		_invManager = true
		
	end

	if showDebugUI then debugUI () end
		
	if updateFlag then LibEKL.events.addInsecure(getInventory, inspectTimeFrame(), 20) end

end

function LibEKL.inventory.updateDB ()

	if not _invManager then 
		LibEKL.Tools.Error.Display ("LibEKL", "Inventory manager not initialzed", 1)
	else
		getInventory()
	end

end

function LibEKL.inventory.findFreeBagSlot(bag)

	local startBag, endBag = 1, 8
	if bag then startBag, endBag = bag, bag end

	for idx = startBag, endBag, 1 do
		local bagSlot = utilityItemSlotInventory(idx)
		
		if bagSlot then
			local bagInfo = inspectItemList(bagSlot)

			for slot, details in pairs (bagInfo) do
				if details == false then return slot end    
			end
		end
	end
	
	return nil

end

function LibEKL.inventory.findFreeBankSlot(bag)

	local startBag, endBag = 1, 8
	if bag then startBag, endBag = bag, bag end

	for idx = startBag, endBag, 1 do
		local bagSlot = utilityItemSlotBank(idx)
		
		if bagSlot then
			local bagInfo = inspectItemList(bagSlot)

			for slot, details in pairs (bagInfo) do
				if details == false then return slot end    
			end
		end
	end
	
	return nil

end

function LibEKL.inventory.findFreeVaultSlot(bag)

	local startBag, endBag = 1, 4
	if bag then startBag, endBag = bag, bag end

	for idx = startBag, endBag, 1 do
		local bagSlot = utilityItemSlotVault(idx)
		
		if bagSlot then
			local bagInfo = inspectItemList(bagSlot)

			for slot, details in pairs (bagInfo) do
				if details == false then return slot end    
			end
		end
	end
	
	return nil

end

function LibEKL.inventory.getAllItems ()

	return LibEKLInv[LibEKLUnitGetPlayerDetails().name].itemCache
	
end

function LibEKL.inventory.GetItemByKey (key)
	return LibEKLInv[LibEKLUnitGetPlayerDetails().name].itemCache[key]
end

function LibEKL.inventory.querySlotById (id)

	if not _invManager then 
		LibEKL.Tools.Error.Display ("LibEKL", "Inventory manager not initialzed", 1)
		return
	end
	
	local inventory = LibEKLInv[LibEKLUnitGetPlayerDetails().name].inventory

	for slot, v in pairs(inventory.bySlot) do
		if v.id ~= nil and LibEKL.strings.startsWith(id, v.id) then return slot end
	end

	-- try with typeID if available
	
	if inventory.byID[id] ~= nil then
		return LibEKL.inventory.querySlotByType (inventory.byID[id])
	end
	
	return nil

end

function LibEKL.inventory.querySlotByType (typeId)

	if _invManager == false then 
		LibEKL.Tools.Error.Display ("LibEKL", "Inventory manager not initialzed", 1)
		return
	end
	
	local inventory = LibEKLInv[LibEKLUnitGetPlayerDetails().name].inventory
	local itemCache = LibEKLInv[LibEKLUnitGetPlayerDetails().name].itemCache

	for slot, v in pairs(inventory.bySlot) do
		if itemCache[v.id] ~= nil and LibEKL.strings.startsWith(typeId, itemCache[v.id].typeId) then return slot end
	end

	return nil

end

function LibEKL.inventory.queryQtyById (key)

	if not _invManager then 
		LibEKL.Tools.Error.Display ("LibEKL", "Inventory manager not initialzed", 1)
		return
	end
	
	if (not LibEKLInv[LibEKLUnitGetPlayerDetails().name]) or (not LibEKLInv[LibEKLUnitGetPlayerDetails().name].inventory) then getInventory() end

	local inventory = LibEKLInv[LibEKLUnitGetPlayerDetails().name].inventory	

	if not stringFind(key, ',') then
		-- key is an id, get type			
		key = inventory.byID[key]
	end
	
	if inventory.byType[key] ~= nil then
		return inventory.byType[key]
	end
	
	return 0

end

function LibEKL.inventory.queryByCategory (category)

	if not _invManager then 
		LibEKL.Tools.Error.Display ("LibEKL", "Inventory manager not initialzed", 1)
		return
	end

	if LibEKLInv[LibEKLUnitGetPlayerDetails().name] == nil then getInventory() end
	
	local retValues = {}
	
	local itemCache = LibEKLInv[LibEKLUnitGetPlayerDetails().name].itemCache
	
	for id, details in pairs(itemCache) do
		if details.category == category then
			local err, details = pcall(inspectItemDetail, id)
			if err and details then
				retValues[id] = details
			else
				LibEKL.Tools.Error.Display ("LibEKL", "Getting item information for " .. id .. " failed", 1)				
			end
		end
			
	end
	
	return retValues
	
end

function LibEKL.inventory.getAvailableSlots()

	local availSlots = {}
	local allSlots = nil
	
	local slots = inspectItemList(utilityItemSlotInventory())
	local initOk = false
	
	for slot, details in pairs (slots) do
		if not LibEKL.strings.startsWith(slot, "sibg.") then initOk = true end 		
		if details == false then table.insert (availSlots, slot) end
	end
	
	if not initOk then return false end
	
	return availSlots

end

function LibEKL.inventory.getQuestItems ()

	local slots = inspectItemList(utilityItemSlotQuest())
	local lu = {}
	
	for slot, key in pairs(slots) do
		if key ~= nil then lu[slot] = true end
	end
	
	return inspectItemDetail(lu)		

end

 function LibEKL.inventory.getQuestItemSlot (typeId)
 
 	local info = LibEKL.inventory.getQuestItems ()
 	
 	for slot, details in pairs(info) do
 		if details.type == typeId then
 			return slot
 		end
 	end
 
 	return nil
 
 end 

function LibEKL.inventory.getBagItems()

    if not _invManager then
        LibEKL.Tools.Error.Display("LibEKL", "Inventory manager not initialized", 1)
        return
    end

    local inventory = LibEKLInv[LibEKLUnitGetPlayerDetails().name].inventory
    local itemCache = LibEKLInv[LibEKLUnitGetPlayerDetails().name].itemCache
    local allItems = {}

	for slot, details in pairs(inventory.bySlot) do
		if stringFind(slot, "si") and not stringFind(slot, "sibg") and details.id and itemCache[details.id] then
            allItems[slot] = {
                id = details.id,
                stack = details.stack,
                typeId = itemCache[details.id].typeId,
                category = itemCache[details.id].category,
                cooldown = itemCache[details.id].cooldown,
                name = itemCache[details.id].name,
                icon = itemCache[details.id].icon,
				rarity = itemCache[details.id].rarity,
				bind = itemCache[details.id].bind,
				bound = itemCache[details.id].bound,
            }
        end
    end

    return allItems
end

function LibEKL.inventory.getBagSlots()

	if not _invManager then
        LibEKL.Tools.Error.Display("LibEKL", "Inventory manager not initialized", 1)
        return
    end

    local inventory = LibEKLInv[LibEKLUnitGetPlayerDetails().name].inventory
    local itemCache = LibEKLInv[LibEKLUnitGetPlayerDetails().name].itemCache
    local allItems = {
		["sibg.001"] = {},
		["sibg.002"] = {},
		["sibg.003"] = {},
		["sibg.004"] = {},
		["sibg.005"] = {},
		["sibg.006"] = {},
		["sibg.007"] = {},
		["sibg.008"] = {}
	}

	for slot, details in pairs(inventory.bySlot) do
		
		if stringFind(slot, "sibg") then

            allItems[slot] = {
                id = details.id,
                stack = details.stack,
                typeId = itemCache[details.id].typeId,
                category = itemCache[details.id].category,
                cooldown = itemCache[details.id].cooldown,
                name = itemCache[details.id].name,
                icon = itemCache[details.id].icon,
				rarity = itemCache[details.id].rarity,
				bind = itemCache[details.id].bind,
				bound = itemCache[details.id].bound,
            }
        end
    end

    return allItems

end