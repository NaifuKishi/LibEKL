local addonInfo, privateVars = ...

---------- init namespace ---------

if not LibEKL then LibEKL = {} end

if not privateVars.uiFunctions then privateVars.uiFunctions = {} end

local uiFunctions   = privateVars.uiFunctions
local internalFunc  = privateVars.internalFunc
local lang          = privateVars.langTexts

---------- addon internalFunc function block ---------

local function _uiDialog(name, parent) 

	--if LibEKL.internalFunc.checkEvents (name, false) == false then return nil end

	local dialog = LibEKL.uiCreateFrame("nkwindow", name, parent)
	local message = LibEKL.uiCreateFrame ('nkText', name .. "message", dialog)
	local leftButton = LibEKL.uiCreateFrame ('nkButton', name .. "leftButton", dialog)
	local centerButton = LibEKL.uiCreateFrame ('nkButton', name .. "centerButton", dialog)
	local rightButton = LibEKL.uiCreateFrame ('nkButton', name .. "rightButton", dialog)

	local properties = {}

	function dialog:SetValue(property, value)
		properties[property] = value
	end
	
	function dialog:GetValue(property)
		return properties[property]
	end
	
	-- GARBAGE COLLECTOR ROUTINES
  
	local oDialogDestroy = dialog.destroy
  
	function dialog:destroy()
		rightButton:destroy()
		centerButton:destroy()
		leftButton:destroy()
		message:destroy()
		oDialogDestroy()
	end 
	
	dialog:SetValue("name", name)
	dialog:SetValue("parent", parent)

	--dialog:SetDragable(true)
	dialog:SetCloseable(true)
	dialog:SetStrata('main')
	dialog:SetTitle("")
		
	message:SetPoint("CENTER", dialog:GetContent(), "CENTER", 0, -30)
	message:SetFontColor(1, 1, 1, 1)
	message:SetFontSize(16)
	message:SetWordwrap(true)
	
	leftButton:SetPoint("BOTTOMLEFT", dialog:GetContent(), "BOTTOMLEFT", 5, -5)
	
	leftButton:EventAttach(Event.UI.Input.Mouse.Left.Click, function ()
		dialog:SetVisible(false)
		LibEKL.eventHandlers[name]["LeftButtonClicked"]()
	end, name .. "_leftButton_LeftClick")
	
	centerButton:SetPoint("BOTTOMCENTER", dialog:GetContent(), "BOTTOMCENTER", 0, -5)
	
	centerButton:EventAttach(Event.UI.Input.Mouse.Left.Click, function ()
		dialog:SetVisible(false)
		LibEKL.eventHandlers[name]["CenterButtonClicked"]()
	end, name .. "_centerButton_LeftClick")
	
	rightButton:SetPoint("BOTTOMRIGHT", dialog:GetContent(), "BOTTOMRIGHT", -5, -5)
	
	rightButton:EventAttach(Event.UI.Input.Mouse.Left.Click, function ()
		dialog:SetVisible(false)
		LibEKL.eventHandlers[name]["RightButtonClicked"]()
	end, name .. "_rightButton_LeftClick")
	
	function dialog:SetType(dialogType)
	
		if dialogType == "confirm" then
			leftButton:SetText(lang.yes)
			rightButton:SetText(lang.no)
			leftButton:SetVisible(true)
			rightButton:SetVisible(true)
			centerButton:SetVisible(false)
		else
			centerButton:SetText(lang.ok)			
			leftButton:SetVisible(false)
			rightButton:SetVisible(false)
			centerButton:SetVisible(true)
		end
	
	end
	
	function dialog:SetMessage(messageText)
		message:ClearAll()
		message:SetPoint("CENTER", dialog:GetContent(), "CENTER", 0, -30)		
		message:SetText(messageText)
		
		if message:GetWidth() > ( dialog:GetWidth() - 40) then		
			message:SetWidth(dialog:GetWidth() - 40)
		end
		
		dialog:SetHeight(message:GetHeight()+120)
	end
	
	local oSetWidth, oSetHeight = dialog.SetWidth, dialog.SetHeight
	
	function dialog:SetWidth(width)
		oSetWidth(self, width)
		dialog:SetPoint("TOPLEFT", UIParent, "TOPLEFT", (LibEKL.ui.getBoundRight() / 2 ) - (dialog:GetWidth() / 2), (LibEKL.ui.getBoundBottom() / 2 ) - (dialog:GetHeight() / 2))
		message:SetWidth( width - 40)
	end
	
	function dialog:SetHeight(height)
		oSetHeight(self, height)
		dialog:SetPoint("TOPLEFT", UIParent, "TOPLEFT", (LibEKL.ui.getBoundRight() / 2 ) - (dialog:GetWidth() / 2), (LibEKL.ui.getBoundBottom() / 2 ) - (dialog:GetHeight() / 2))
		message:SetHeight( height - 120)
	end

	function dialog:SetFont(addonID, font)
		LibEKL.ui.setFont(message, addonID, font)
	end

	function dialog:SetEffectGlow(effect)
		message:SetEffectGlow(effect)
	end

	function dialog:SetButtonFont(addonId, font)
		leftButton:SetFont(addonId, font)
		rightButton:SetFont(addonId, font)
		centerButton:SetFont(addonId, font)	
	end

	function dialog:SetButtonFillColor(newColor)
		leftButton:SetFillColor(newColor)
		rightButton:SetFillColor(newColor)
		centerButton:SetFillColor(newColor)
	end

	function dialog:SetButtonLabelColor (color)
		leftButton:SetLabelColor(color)
		rightButton:SetLabelColor(color)
		centerButton:SetLabelColor(color)
	end

	function dialog:SetButtonBorderColor (newColor)
		leftButton:SetBorderColor(newColor)
		rightButton:SetBorderColor(newColor)
		centerButton:SetBorderColor(newColor)
	end
	
	function dialog:SetButtonEffect(effect)
		leftButton:SetEffectGlow(effect)
		rightButton:SetEffectGlow(effect)
		centerButton:SetEffectGlow(effect)
	end

	LibEKL.eventHandlers[name]["LeftButtonClicked"], LibEKL.Events[name]["LeftButtonClicked"] = Utility.Event.Create(addonInfo.identifier, name .. "LeftButtonClicked")
	LibEKL.eventHandlers[name]["RightButtonClicked"], LibEKL.Events[name]["RightButtonClicked"] = Utility.Event.Create(addonInfo.identifier, name .. "RightButtonClicked")
	LibEKL.eventHandlers[name]["CenterButtonClicked"], LibEKL.Events[name]["CenterButtonClicked"] = Utility.Event.Create(addonInfo.identifier, name .. "CenterButtonClicked")
	
	return dialog
	
end

uiFunctions.NKDIALOG = _uiDialog