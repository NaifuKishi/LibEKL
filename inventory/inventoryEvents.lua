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

---------- local function block ---------

local function storeItem (slot, details)

	if not details then return end

	local inventory = LibEKLInv[LibEKL.Unit.GetPlayerDetails().name].inventory
	local itemCache = LibEKLInv[LibEKL.Unit.GetPlayerDetails().name].itemCache
	
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

	local inventory = LibEKLInv[LibEKL.Unit.GetPlayerDetails().name].inventory
	local itemCache = LibEKLInv[LibEKL.Unit.GetPlayerDetails().name].itemCache
	
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

--------- inventory events

function inventoryEvents.processItems (list)

	local itemList = inspectItemDetail(list)
	
	for slot, v in pairs(itemList) do		
		if v.id ~= nil then
			storeItem (slot, v)
		end
	end   

end

function inventoryEvents.processUpdate (_, updates)

	if LibEKL.Unit.GetPlayerDetails() == nil then return end

	if (not LibEKLInv[LibEKL.Unit.GetPlayerDetails().name]) or (not LibEKLInv[LibEKL.Unit.GetPlayerDetails().name].inventory) then inventory.getInventory() end

	local inventory = LibEKLInv[LibEKL.Unit.GetPlayerDetails().name].inventory
	local itemCache = LibEKLInv[LibEKL.Unit.GetPlayerDetails().name].itemCache

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

	LibEKL.eventHandlers["LibEKL.InventoryManager"]["Update"](updatedKeys)
	LibEKL.eventHandlers["LibEKL.InventoryManager"]["SlotUpdate"](updatedSlots)

end