
local addonInfo, privateVars = ...

---------- init namespace ---------

if not LibEKL then LibEKL = {} end
if not LibEKL.Inventory then LibEKL.Inventory = {} end

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
local stringFormat	= string.format

local LibEKLUnitGetPlayerDetails

local function buildDebugUI ()

	if debugUI then return end

	if not LibEKLUnitGetPlayerDetails then LibEKLUnitGetPlayerDetails = LibEKL.Unit.GetPlayerDetails end

	local name = "LibEKL.Inventory.debugUI"

	debugUI = LibEKL.UICreateFrame("nkFrame", name, privateVars.uiContext)
	debugUI:SetPoint("TOPLEFT", UIParent, "TOPLEFT")
	debugUI:SetBackgroundColor(0, 0, 0, 1)
	debugUI:SetWidth(250)
	debugUI:SetHeight(800)
	
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
					local thisSlot = LibEKL.UICreateFrame("nkText", name .. "." .. k, debugUI)				
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
				slotInfo.text:SetText(stringFormat("%s: %s %d", slotID, slotInfo.details.id, slotInfo.details.stack))
				from, object, to = "TOPLEFT", slotInfo.text, "BOTTOMLEFT"
			end
		end
	end

	debugUI:update()
	
	return debugUI

end