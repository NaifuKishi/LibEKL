local addonInfo, privateVars = ...

---------- init namespace ---------

if not LibEKL then LibEKL = {} end

if not privateVars.uiFunctions then privateVars.uiFunctions = {} end

local uiFunctions   = privateVars.uiFunctions
local internalFunc  = privateVars.internalFunc

---------- addon internalFunc function block ---------

local function _uiClickButton(name, parent) 

	if LibEKL.Events.CheckEvents (name, true) == false then return nil end

	local color
	local toggled = false
	local toggleable = false

	local icon = LibEKL.uiCreateFrame("nkFrame", name .. '.icon', parent)
	icon:SetWidth(16)
	icon:SetHeight(16)
	
	local iconText = LibEKL.uiCreateFrame('nkText', name .. '.icon.text', icon)	
	iconText:SetPoint("CENTER", icon, "CENTER")
	iconText:SetFontSize(14)
	iconText:SetTextFont(addonInfo.id, "MontserratSemiBold")
	iconText:SetEffectGlow({strength = 3})
	
	iconText:EventAttach(Event.UI.Input.Mouse.Left.Down, function (self)

		toggled = not toggled

		if toggleable then
			if toggled then
				icon:SetBackgroundColor(color.r, color.g, color.b, 1)
				iconText:SetEffectGlow({strength = 0})
				iconText:SetFontColor(0, 0, 0, 1)
				iconText:SetTextFont(addonInfo.id, "MontserratBold")
			else
				icon:SetBackgroundColor(color.r, color.g, color.b, 0)
				iconText:SetFontColor(color.r, color.g, color.b, 1)
				iconText:SetEffectGlow({strength = 3})
				iconText:SetTextFont(addonInfo.id, "MontserratSemiBold")
			end
		end
		
		LibEKL.eventHandlers[name]["Clicked"]()
		
	end, name .. ".icon.text.Mouse.Left.Down")	

	function icon:SetText (newText) iconText:SetText(newText) end
	function icon:SetTooltip (title, text) LibEKL.ui.attachGenericTooltip (iconText, title, text) end
	function icon:SetToggleable (newFlag) toggleable = newFlag end
	
	function icon:SetColor (newColor) 
		color = newColor
		icon:SetBackgroundColor(color.r, color.g, color.b, 0)
		iconText:SetFontColor(color.r, color.g, color.b, 1)
	end

	LibEKL.eventHandlers[name]["Clicked"], LibEKL.Events[name]["Clicked"] = Utility.Event.Create(addonInfo.identifier, name .. "Clicked")
	
	return icon
	
end

uiFunctions.NKCLICKBUTTON = _uiClickButton