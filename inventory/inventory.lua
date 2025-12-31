local addonInfo, privateVars = ...

---------- init namespace ---------

if not LibEKL then LibEKL = {} end
if not LibEKL.Inventory then LibEKL.Inventory = {} end
if not privateVars.inventory then privateVars.inventory = {} end
if not privateVars.inventoryEvents then privateVars.inventoryEvents = {} end

local data				= privateVars.data
local uiElements		= privateVars.uiElements
local inventory			= privateVars.inventory
local inventoryEvents	= privateVars.inventoryEvents

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

local _invManager = false

------ internal inventory functions

function inventory.getInventory ()

	if inspectSystemSecure() == false then commandSystemWatchdogQuiet() end

	if (not LibEKLInv[LibEKL.Unit.GetPlayerDetails().name]) or (not LibEKLInv[LibEKL.Unit.GetPlayerDetails().name].inventory) then
		LibEKLInv[LibEKL.Unit.GetPlayerDetails().name] = {}
	end
	
	LibEKLInv[LibEKL.Unit.GetPlayerDetails().name].inventory = { byID = {}, byType = {}, bySlot = {} }
	LibEKLInv[LibEKL.Unit.GetPlayerDetails().name].itemCache = {}

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
		
		inventoryEvents.processItems (lu)
		
	end
	  
end

------ Library functions

function LibEKL.Inventory.Init (updateFlag, showDebugUI)

	if not LibEKL.Unit.GetPlayerDetails then LibEKL.Unit.GetPlayerDetails = LibEKL.Unit.getPlayerDetails end -- required to not mess up loading of addons

	if not _invManager then
	
		if LibEKL.Events.CheckEvents ("LibEKL.InventoryManager", true) == false then return nil end
		
		if not LibEKLInv then LibEKLInv = {} end
		
		Command.Event.Attach(Event.Item.Slot, inventoryEvents.processUpdate, "LibEKL.Inventory.Item.Slot")
		Command.Event.Attach(Event.Item.Update, inventoryEvents.processUpdate, "LibEKL.Inventory.Item.Update")
		
		LibEKL.eventHandlers["LibEKL.InventoryManager"]["Update"], LibEKL.Events["LibEKL.InventoryManager"]["Update"] = Utility.Event.Create(addonInfo.identifier, "LibEKL.InventoryManagerUpdate")
		LibEKL.eventHandlers["LibEKL.InventoryManager"]["SlotUpdate"], LibEKL.Events["LibEKL.InventoryManager"]["SlotUpdate"] = Utility.Event.Create(addonInfo.identifier, "LibEKL.InventoryManagerSlotUpdate")

		_invManager = true
		
	end

	if showDebugUI then debugUI () end
		
	if updateFlag then LibEKL.Events.AddInsecure(inventory.getInventory, inspectTimeFrame(), 20) end

end

function LibEKL.Inventory.updateDB ()

	if not _invManager then 
		LibEKL.Tools.Error.Display ("LibEKL", "Inventory manager not initialzed", 1)
	else
		inventory.getInventory()
	end

end

function LibEKL.Inventory.findFreeBagSlot(bag)

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

function LibEKL.Inventory.findFreeBankSlot(bag)

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

function LibEKL.Inventory.findFreeVaultSlot(bag)

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

function LibEKL.Inventory.getAllItems ()

	return LibEKLInv[LibEKL.Unit.GetPlayerDetails().name].itemCache
	
end

function LibEKL.Inventory.GetItemByKey (key)
	return LibEKLInv[LibEKL.Unit.GetPlayerDetails().name].itemCache[key]
end

function LibEKL.Inventory.querySlotById (id)

	if not _invManager then 
		LibEKL.Tools.Error.Display ("LibEKL", "Inventory manager not initialzed", 1)
		return
	end
	
	local inventory = LibEKLInv[LibEKL.Unit.GetPlayerDetails().name].inventory

	for slot, v in pairs(inventory.bySlot) do
		if v.id ~= nil and LibEKL.strings.startsWith(id, v.id) then return slot end
	end

	-- try with typeID if available
	
	if inventory.byID[id] ~= nil then
		return LibEKL.Inventory.querySlotByType (inventory.byID[id])
	end
	
	return nil

end

function LibEKL.Inventory.querySlotByType (typeId)

	if _invManager == false then 
		LibEKL.Tools.Error.Display ("LibEKL", "Inventory manager not initialzed", 1)
		return
	end
	
	local inventory = LibEKLInv[LibEKL.Unit.GetPlayerDetails().name].inventory
	local itemCache = LibEKLInv[LibEKL.Unit.GetPlayerDetails().name].itemCache

	for slot, v in pairs(inventory.bySlot) do
		if itemCache[v.id] ~= nil and LibEKL.strings.startsWith(typeId, itemCache[v.id].typeId) then return slot end
	end

	return nil

end

function LibEKL.Inventory.queryQtyById (key)

	if not _invManager then 
		LibEKL.Tools.Error.Display ("LibEKL", "Inventory manager not initialzed", 1)
		return
	end
	
	if (not LibEKLInv[LibEKL.Unit.GetPlayerDetails().name]) or (not LibEKLInv[LibEKL.Unit.GetPlayerDetails().name].inventory) then inventory.getInventory() end

	local inventory = LibEKLInv[LibEKL.Unit.GetPlayerDetails().name].inventory	

	if not stringFind(key, ',') then
		-- key is an id, get type			
		key = inventory.byID[key]
	end
	
	if inventory.byType[key] ~= nil then
		return inventory.byType[key]
	end
	
	return 0

end

function LibEKL.Inventory.queryByCategory (category)

	if not _invManager then 
		LibEKL.Tools.Error.Display ("LibEKL", "Inventory manager not initialzed", 1)
		return
	end

	if LibEKLInv[LibEKL.Unit.GetPlayerDetails().name] == nil then inventory.getInventory() end
	
	local retValues = {}
	
	local itemCache = LibEKLInv[LibEKL.Unit.GetPlayerDetails().name].itemCache
	
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

function LibEKL.Inventory.getAvailableSlots()

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

function LibEKL.Inventory.getQuestItems ()

	local slots = inspectItemList(utilityItemSlotQuest())
	local lu = {}
	
	for slot, key in pairs(slots) do
		if key ~= nil then lu[slot] = true end
	end
	
	return inspectItemDetail(lu)		

end

 function LibEKL.Inventory.getQuestItemSlot (typeId)
 
 	local info = LibEKL.Inventory.getQuestItems ()
 	
 	for slot, details in pairs(info) do
 		if details.type == typeId then
 			return slot
 		end
 	end
 
 	return nil
 
 end 

function LibEKL.Inventory.getBagItems()

    if not _invManager then
        LibEKL.Tools.Error.Display("LibEKL", "Inventory manager not initialized", 1)
        return
    end

    local inventory = LibEKLInv[LibEKL.Unit.GetPlayerDetails().name].inventory
    local itemCache = LibEKLInv[LibEKL.Unit.GetPlayerDetails().name].itemCache
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

function LibEKL.Inventory.getBagSlots()

	if not _invManager then
        LibEKL.Tools.Error.Display("LibEKL", "Inventory manager not initialized", 1)
        return
    end

    local inventory = LibEKLInv[LibEKL.Unit.GetPlayerDetails().name].inventory
    local itemCache = LibEKLInv[LibEKL.Unit.GetPlayerDetails().name].itemCache
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

function LibEKL.Inventory.GetItemColor(rarity)

	local rarityColor = {
		sellable = {r=0.616, g=0.616, b=0.616},
		uncommon = {r=0.118, g=1.000, b=0.000},
		rare = {r=0.000, g=0.439, b=0.867},
		epic = {r=0.639, g=0.208, b=0.933},
		relic = {r=1.000, g=0.647, b=0.000},
		transcendent = {r = 1, g = 0.5, b = 0},
		quest = {r = .843, g = .796, b = 0}
	}

	local color = rarityColor[rarity]
	if color == nil then 
		color = {r=1.000, g=1.000, b=1.000}
	end

	return color

end