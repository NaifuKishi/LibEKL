local addonInfo, privateVars = ...

---------- init namespace ---------

if not LibEKL then LibEKL = {} end

if not privateVars.uiFunctions then privateVars.uiFunctions = {} end

local uiFunctions   = privateVars.uiFunctions
local internalFunc      = privateVars.internalFunc

---------- addon internalFunc function block ---------

local function _uiButton(name, parent) 

	--if LibEKL.internalFunc.checkEvents (name, true) == false then return nil end

	local button = LibEKL.UICreateFrame ('nkCanvas', name, parent)
	local label = LibEKL.UICreateFrame ('nkText', name .. 'label', button)

	local path = {  {xProportional = 0, yProportional = 0},
                  	{xProportional = 1, yProportional = 0},
                  	{xProportional = 1, yProportional = 1},
                  	{xProportional = 0, yProportional = 1},
                  	{xProportional = 0, yProportional = 0}
                  }  
	local stroke, fill, fillHighlight, labelColor, labelHighlight, thisEffect

	local width = 123
	local height = 33	
	local scale = 1

	button:SetWidth(144)
	button:SetHeight(30)

	label:SetPoint("CENTER", button, "CENTER", 0, -1)
	label:SetFontSize(16)
	label:SetHeight(18)
	label:SetLayer(3)

	function button:SetText(newText)
		label:SetText(newText)
	end

	function button:SetFont(addonInfo, fontName) LibEKL.UI.SetFont(label, addonInfo, fontName) end
	function button:SetEffectGlow(effect)
		thisEffect = effect
		label:SetEffectGlow(effect) 
	end

	function button:SetFontSize (newFontSize)
		label:SetFontSize(newFontSize)
	end

	function button:SetFillColor(newFill)
		fill = newFill
		button:SetShape(path, fill, stroke)

		labelHighlight = { r = fill.r, g = fill.g, b = fill.b, a = 1}
	end

	function button:SetBorderColor(newBorderColor)
		stroke = newBorderColor
		button:SetShape(path, fill, stroke)
	end
	
	function button:SetLabelColor(newColor)
		labelColor = newColor		
		label:SetFontColor(labelColor.r, labelColor.g, labelColor.b, labelColor.a)

		fillHighlight = { type = "solid", r = labelColor.r, g = labelColor.g, b = labelColor.b, a = 1}
	end

	function button:SetScale(newScale)
		scale = newScale

		button:SetWidth(width * newScale)
		button:SetHeight(height * newScale)
			
		label:SetFontSize(16 * newScale)
		label:SetHeight (20 * newScale)
	end

	local oSetWidth, oSetHeight = button.SetWidth, button.SetHeight

	function button:SetWidth(newWidth)
		width = newWidth
		oSetWidth(self, newWidth)		
	end 

	function button:SetHeight(newHeight)
		height = newHeight
		oSetHeight(self, newHeight)
	end

	function button:SetMacro(newMacro)
		button:SetSecureMode('restricted')
		button:EventMacroSet(Event.UI.Input.Mouse.Left.Click, newMacro)
	end

	button:EventAttach(Event.UI.Input.Mouse.Left.Click, function ()
		LibEKL.eventHandlers[name]["Clicked"]()
	end, name .. "Mouse.Left.Click")

	button:EventAttach(Event.UI.Input.Mouse.Cursor.In, function ()
		button:SetShape(path, fillHighlight, stroke)
		label:SetFontColor(labelHighlight.r, labelHighlight.g, labelHighlight.b, labelHighlight.a)
		label:SetEffectGlow(nil)
		LibEKL.eventHandlers[name]["MouseIn"]()
	end, name .. ".Mouse.Cursor.In")

	button:EventAttach(Event.UI.Input.Mouse.Cursor.Out, function ()
		button:SetShape(path, fill, stroke)
		label:SetFontColor(labelColor.r, labelColor.g, labelColor.b, labelColor.a)
		label:SetEffectGlow(thisEffect)
		LibEKL.eventHandlers[name]["MouseOut"]()
	end, name .. ".Mouse.Cursor.Out")

	LibEKL.eventHandlers[name]["MouseIn"], LibEKL.Events[name]["MouseIn"] = Utility.Event.Create(addonInfo.identifier, name .. "MouseIn")
	LibEKL.eventHandlers[name]["MouseOut"], LibEKL.Events[name]["MouseOut"] = Utility.Event.Create(addonInfo.identifier, name .. "MouseOut")
	LibEKL.eventHandlers[name]["Clicked"], LibEKL.Events[name]["Clicked"] = Utility.Event.Create(addonInfo.identifier, name .. "Clicked")

	--button:Redraw()
	
	return button
	
end

uiFunctions.NKBUTTON = _uiButton