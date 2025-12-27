local addonInfo, privateVars = ...

---------- init namespace ---------

if not LibEKL then LibEKL = {} end

if not privateVars.uiFunctions then privateVars.uiFunctions = {} end

local uiFunctions   = privateVars.uiFunctions
local internalFunc      = privateVars.internalFunc

---------- addon internalFunc function block ---------

--[[
   _uiButtonMetro

    Description:
        Creates and configures a customizable metro-style button element with rounded corners,
        icon support, and text label. This function provides a framework for creating interactive
        buttons with customizable appearance and behavior.

    Parameters:
        name (string): Unique identifier for the button element
        parent (frame): Parent frame to which this button will be attached

    Returns:
        button (frame): The configured button frame with all child elements and functionality

    Process:
        1. Creates the main button canvas and its components (icon, label)
        2. Sets up default styling and positioning
        3. Configures event handlers for mouse interactions (click, hover, etc.)
        4. Implements various button behaviors (icon animation, text display, etc.)
        5. Provides getter and setter methods for button properties
        6. Sets up event system for button interactions

    Notes:
        - The button has rounded corners created through a custom shape
        - Supports icon display with animation capabilities
        - Provides customization options for appearance (colors, textures, fonts)
        - Implements secure mode support for restricted environments
        - Includes event system for tracking button interactions
        - Supports dynamic resizing and scaling

    Available Methods:

    **Button Behavior Methods:**
        - SetIcon(addon, texture): Sets the button icon from a specified addon and texture
        - SetText(newText): Sets the button text label
        - SetColor(r, g, b): Sets the button fill color
        - SetBorderColor(r, g, b, a): Sets the button border color
        - SetFontColor(r, g, b, a): Sets the text font color
        - SetScale(newScale): Sets the button scale factor
        - SetWidth(newWidth): Sets the width of the button
        - SetHeight(newHeight): Sets the height of the button
        - SetMacro(newMacro): Sets a macro to execute when the button is clicked
        - AnimateIcon(flag): Enables or disables icon animation

    **Button Appearance Methods:**
        - SetFont(addonInfo, fontName): Sets custom font for the button text
        - Redraw(): Redraws the button with current settings

    **UI Element Accessor Methods:**
        - GetValue(property): Gets a specific property value
        - SetValue(property, value): Sets a specific property value

    **Cleanup Method:**
        - destroy(): Cleans up all button elements and prepares them for garbage collection
]]

local function _uiButtonMetro(name, parent) 

	--if LibEKL.internalFunc.checkEvents (name, true) == false then return nil end

	local button = LibEKL.uiCreateFrame ('nkCanvas', name, parent)

	local icon = LibEKL.uiCreateFrame ('nkCanvas', name .. 'texture', button)
	local label = LibEKL.uiCreateFrame ('nkText', name .. 'label', button)

	local path = {{xProportional = 0, yProportional = 0}, {xProportional = 0, yProportional = 1}, {xProportional = 1, yProportional = 1},  {xProportional = 1, yProportional = 0}, {xProportional = 0, yProportional = 0}}
	local stroke, fill, fillHighlight
	--local stroke = { thickness = 1, r = LibEKL.art.GetThemeColor('elementMainColor').r, g = LibEKL.art.GetThemeColor('elementMainColor').g, b = LibEKL.art.GetThemeColor('elementMainColor').b, a = LibEKL.art.GetThemeColor('elementMainColor').a}
	--local fill = { type = 'solid', r = LibEKL.art.GetThemeColor('elementSubColor').r, g = LibEKL.art.GetThemeColor('elementSubColor').g, b = LibEKL.art.GetThemeColor('elementSubColor').b, a = LibEKL.art.GetThemeColor('elementSubColor').a}
	--local fillHighlight = { type = 'solid', r = LibEKL.art.GetThemeColor('elementSubColor').r * .8, g = LibEKL.art.GetThemeColor('elementSubColor').g * .8, b = LibEKL.art.GetThemeColor('elementSubColor').b * .8, a = LibEKL.art.GetThemeColor('elementSubColor').a} 

	local selected = false
	local width = 123
	local height = 33
	local animatedIcon = false
	
	local iconPath = {{xProportional = 0, yProportional = 0}, {xProportional = 0, yProportional = 1}, {xProportional = 1, yProportional = 1},  {xProportional = 1, yProportional = 0}, {xProportional = 0, yProportional = 0}}
	local iconFill = { type = "texture" }

	local properties = {}

	function button:SetValue(property, value) properties[property] = value end
	function button:GetValue(property) return properties[property] end

	--local labelColor = LibEKL.art.GetThemeColor('labelColor')
	local labelColor
	local scale = 1

	button:SetWidth(144)
	button:SetHeight(30)

	label:SetPoint("CENTER", button, "CENTER", 0, -1)
	label:SetFontSize(16)
	--label:SetFontColor(labelColor.r, labelColor.g, labelColor.b, labelColor.a )
	label:SetHeight(18)
	label:SetLayer(3)

	icon:SetPoint("CENTERRIGHT", button, "CENTERRIGHT", -7, 0)
	icon:SetHeight(22)
	icon:SetWidth(22)
	icon:SetLayer(3)
	icon:SetVisible(false)

	--[[function button:Redraw()

		local x1 = 1/button:GetWidth()*2
		local x2 = 1-x1
		local y1 = 1/button:GetHeight()*2
		local y2 = 1-y1

		path = {  {xProportional = x1, yProportional = 0},
		{xProportional = x2, yProportional = 0},
		{xProportional = 1, yProportional = y1, xControlProportional = 1, yControlProportional = 0},
		{xProportional = 1, yProportional = y2},
		{xProportional = x2, yProportional = 1, xControlProportional = 1, yControlProportional = 1},
		{xProportional = x1, yProportional = 1},
		{xProportional = 0, yProportional = y2, xControlProportional = 0, yControlProportional = 1},
		{xProportional = 0, yProportional = y1},
		{xProportional = x1, yProportional = 0, xControlProportional = 0, yControlProportional = 0}
		}  

		button:SetShape(path, fill, stroke)/home/dirk/Games/Heroic/Prefixes/default/Glyph/drive_c/users/dirk/Documents/RIFT/Interface/Addons/EnKai/ui/button/buttonMetro.lua
			local scale = 1 / 36 * (22 * scale)
			LibEKL.fx.register (name .. ".icon", icon, {id = "rotateCanvas", speed = 0, scale = scale, path = iconPath, fill = iconFill })
		elseif flag == false and animatedIcon == true then
			LibEKL.fx.cancel(name .. ".icon")
		end
		
		animatedIcon = flag
		
	end
]]
	function button:SetIcon(addon, texture)

		if addon == nil then
			icon:SetVisible(false)
			label:SetPoint("CENTER", button, "CENTER")
		else  
			iconFill = { type = "texture", source = addon, texture = texture }
			iconFill.transform = Utility.Matrix.Create(1 / 36 * (22 * scale), 1 / 36 * (22 * scale), 0, 0, 0) 
			icon:SetHeight(22 * scale)
			icon:SetWidth(22 * scale)
			icon:SetShape(iconPath, iconFill, nil)
			
			--icon:SetTextureAsync (addon, texture)
			icon:SetVisible(true)
			label:SetPoint("CENTER", button, "CENTER", -19 * scale, -1 * scale)
		end  
		
	end

	function button:SetText(newText)
		label:SetText(newText)
		label:ClearAll()

		if icon:GetVisible() == true then
			label:SetPoint("CENTER", button, "CENTER", -(19 * scale), -1*scale)
		else
			label:SetPoint("CENTER", button, "CENTER")
		end
	end

	function button:SetFont(addonInfo, fontName) LibEKL.ui.setFont(label, addonInfo, fontName) end
	function button:SetEffectGlow(effect) label:SetEffectGlow(effect) end

	function button:SetColor(r, g, b, a)

		if type(r) == "table" then
			fill = r
		else
			if not fill then fill = {} end
			fill.r, fill.g, fill.b, fill.a = r, g, b, a			
		end

		if not fillHighlight then fillHighlight = {} end

		fillHighlight.r, fillHighlight.g, fillHighlight.b, fillHighlight.a = fill.r * .8, fill.g * .8, fill.b * .8, fill.a
		
		--button:Redraw()
	end

	function button:SetBorderColor(r, g, b, a)
		if not stroke then stroke = {} end

		stroke.r, stroke.g, stroke.b = r, g, b
		if a ~= nil then stroke.a = a end
		--fillHighlight.r, fillHighlight.g, fillHighlight.b = r * .8, g * .8, b * .8
		--button:Redraw()
	end
	
	function button:SetFontColor(r, g, b, a)
		if type (r) == "table" then
			labelColor = r
		else
			if a == nil then a = 1 end
			labelColor = { r = r, g = g, b = b, a = a }
		end
		
		label:SetFontColor(labelColor.r, labelColor.g, labelColor.b, labelColor.a )
	end

	function button:SetScale(newScale)
		scale = newScale

		button:SetWidth(width * newScale)
		button:SetHeight(height * newScale)
		icon:SetWidth(22 * newScale)
		icon:SetHeight(22 * newScale)
	
		if iconFill.texture ~= nil then 
			iconFill.transform = Utility.Matrix.Create(1 / 36 * (22 * newScale), 1 / 36 * (22 * newScale), 0, 0, 0) 
			icon:SetShape(iconPath, iconFill, nil) 
			
			if animatedIcon then
				local scale = 1 / 36 * (22 * newScale)
				LibEKL.fx.update (effectName, { scale = scale}) 
			end
			
		end
		
		label:SetFontSize(16 * newScale)
		label:SetHeight (20 * newScale)

		icon:SetPoint("CENTERRIGHT", button, "CENTERRIGHT", (-7 * scale), 0)

		if icon:GetVisible() == true then
			label:SetPoint("CENTER", button, "CENTER", -(19 * scale), -1 * scale)
		end

		--button:Redraw()

	end

	local oSetWidth, oSetHeight = button.SetWidth, button.SetHeight

	function button:SetWidth(newWidth)
		width = newWidth
		oSetWidth(self, newWidth)
		--button:Redraw()
	end 

	function button:SetHeight(newHeight)
		height = newHeight
		oSetHeight(self, newHeight)
		--button:Redraw()
	end

	function button:SetMacro(newMacro)
		button:SetSecureMode('restricted')
		button:EventMacroSet(Event.UI.Input.Mouse.Left.Click, newMacro)
	end

	button:EventAttach(Event.UI.Input.Mouse.Left.Click, function ()
		LibEKL.eventHandlers[name]["Clicked"]()
	end, name .. "Mouse.Left.Click")
--[[
	button:EventAttach(Event.UI.Input.Mouse.Cursor.In, function ()
		button:SetShape(path, fillHighlight, stroke)
		LibEKL.eventHandlers[name]["MouseIn"]()
	end, name .. ".Mouse.Cursor.In")

	button:EventAttach(Event.UI.Input.Mouse.Cursor.Out, function ()
		button:SetShape(path, fill, stroke)
		LibEKL.eventHandlers[name]["MouseOut"]()
	end, name .. ".Mouse.Cursor.Out")

	LibEKL.eventHandlers[name]["MouseIn"], LibEKL.events[name]["MouseIn"] = Utility.Event.Create(addonInfo.identifier, name .. "MouseIn")
	LibEKL.eventHandlers[name]["MouseOut"], LibEKL.events[name]["MouseOut"] = Utility.Event.Create(addonInfo.identifier, name .. "MouseOut")

]]
	LibEKL.eventHandlers[name]["Clicked"], LibEKL.events[name]["Clicked"] = Utility.Event.Create(addonInfo.identifier, name .. "Clicked")

	--button:Redraw()
	
	return button
	
end

uiFunctions.NKBUTTONMETRO = _uiButtonMetro