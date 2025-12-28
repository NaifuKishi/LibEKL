local addonInfo, privateVars = ...

---------- init namespace ---------

if not LibEKL then LibEKL = {} end

if not privateVars.uiFunctions then privateVars.uiFunctions = {} end

local uiFunctions   = privateVars.uiFunctions
local internalFunc  = privateVars.internalFunc

---------- addon internalFunc function block ---------

local function _uiTextfield(name, parent) 

	local borderColor, focusColor, innerColor

	local textField = LibEKL.UICreateFrame ('nkFrame', name, parent)
	local textFieldInner = LibEKL.UICreateFrame ('nkFrame', name .. ".inner", textField)
	local textFieldEdit = UI.CreateFrame ('RiftTextfield', name .. ".edit", textFieldInner)

	local properties = {}

	local multiLine, restoreOnExit, keyEvent = false, true, false
	local tabTarget
	
	function textField:SetValue(property, value)
		properties[property] = value
	end
	
	function textField:GetValue(property)
		return properties[property]
	end
	
	textField:SetValue("name", name)
	textField:SetValue("parent", parent)
	
	textField:SetValue("valueType", "text")
	textField:SetValue("restoreValue", false)
	textField:SetValue("backupValue", false)
	
	textField:SetWidth(100)
	textField:SetHeight(20)
		
	textFieldInner:SetPoint("TOPLEFT", textField, "TOPLEFT", 1, 1)
	textFieldInner:SetPoint("BOTTOMRIGHT", textField, "BOTTOMRIGHT", -1, -1)
	
	textFieldEdit:SetPoint("TOPLEFT", textFieldInner, "TOPLEFT", 1, 1)
	textFieldEdit:SetPoint("BOTTOMRIGHT", textFieldInner, "BOTTOMRIGHT", -1, -1)
	
	function textField:SetText(text)
		textFieldEdit:SetText(tostring(text))
		textField:SetValue("backupValue", textFieldEdit:GetText())
	end

	function textField:GetText()
		return textFieldEdit:GetText()
	end
	
	function textField:GetConvertedText()
		local tempText = textFieldEdit:GetText()
		
		if textField:GetValue('valueType') == 'number' then
			return tonumber(tempText)
		else
			return tempText
		end
	end
	
	function textField:SetValueType(valueType)
		if valueType == 'text' or valueType == 'number' then
			self:SetValue('valueType', valueType)
		end
	end
	
	function textField:SetFocusColor (newColor) focusColor = newColor end
	
	function textField:SetInnerColor (newColor)
    	innerColor = newColor
    	textFieldInner:SetBackgroundColor(innerColor.r, innerColor.g, innerColor.b, innerColor.a)
  	end
	
	function textField:Leave(flag)
		textField:SetValue('restoreValue', flag or false)
		textFieldEdit:SetKeyFocus(false)
	end
	
	function textField:Enter()
		textField:SetValue("backupValue", textFieldEdit:GetText())
		textField:SetValue("restoreValue", true)
		textFieldEdit:SetKeyFocus(true)
		textField:SetBackgroundColor(focusColor.r, focusColor.g, focusColor.b, focusColor.a)
	end
	
	textFieldEdit:EventAttach(Event.UI.Input.Key.Down, function(self, _, key) 
		local code = string.byte(key)

		if multiLine == true and key == "Return" then
			local cursor = self:GetCursor()
			local startPosition, endPosition = self:GetSelection()
			startPosition = startPosition or cursor
			endPosition = (endPosition or cursor) + 1
			local text = self:GetText()
			self:SetText(text:sub(1, startPosition) .. "\n" .. text:sub(endPosition))
			self:SetCursor(startPosition + 1)
		elseif key == 'Tab' or key == 'Return' then
			textField:SetValue('restoreValue', false)
			textFieldEdit:SetKeyFocus(false)
			textField:SetBackgroundColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
			LibEKL.eventHandlers[name]["TextfieldChanged"](textFieldEdit:GetText())
			if key == 'Tab' then 
				LibEKL.eventHandlers[name]["Tabbed"]()
				if tabTarget ~= nil then tabTarget:Enter() end
			end
			
		end
		
		if keyEvent then LibEKL.eventHandlers[name]["KeyDown"](key) end
		
	end, "nkTextField_" .. name .. "_Key_Down")
	
	textFieldEdit:EventAttach(Event.UI.Input.Mouse.Left.Click, function() 
		
		textField:Enter()
		LibEKL.eventHandlers[name]["Enter"]()
				
	end, "nkTextField_" .. name .. "_Left_Click")
	
	textFieldEdit:EventAttach(Event.UI.Input.Key.Focus.Loss, function() 
				
		if restoreOnExit == true and textField:GetValue("restoreValue") ~= false and textField:GetValue("backupValue") ~= nil then
			textFieldEdit:SetText(textField:GetValue("backupValue"))
		end
		
		textField:SetValue("backupValue", nil)
		textField:SetValue("restoreValue", false)
		
		textField:SetBackgroundColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
		
		LibEKL.eventHandlers[name]["FokusLoss"]()
		
	end, "nkTextField_" .. name .. "_Key_FocusLoss")
	
	function textField:SetBorderColor(newColor)
		borderColor = newColor		
		textField:SetBackgroundColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)		
	end
	
	function textField:SetSelection(startPos, endPos) textFieldEdit:SetSelection(startPos, endPos) end
	function textField:GetSelection() return textFieldEdit:GetSelection() end
	function textField:SetMultiLine(flag) multiLine = flag end
	function textField:SetRestoreOnExit (flag) restoreOnExit = flag end
	function textField:SetKeyEvent(flag) keyEvent = flag end
	function textField:SetCursor(newCursor) textFieldEdit:SetCursor(newCursor) end
	function textField:SetTabTarget(newTarget) tabTarget = newTarget end
	
	LibEKL.eventHandlers[name]["TextfieldChanged"], LibEKL.Events[name]["TextfieldChanged"] = Utility.Event.Create(addonInfo.identifier, name .. "TextfieldChanged")
	LibEKL.eventHandlers[name]["Enter"], LibEKL.Events[name]["Enter"] = Utility.Event.Create(addonInfo.identifier, name .. "Enter")
	LibEKL.eventHandlers[name]["Tabbed"], LibEKL.Events[name]["Tabbed"] = Utility.Event.Create(addonInfo.identifier, name .. "Tabbed")
	LibEKL.eventHandlers[name]["KeyDown"], LibEKL.Events[name]["KeyDown"] = Utility.Event.Create(addonInfo.identifier, name .. "KeyDown")
	LibEKL.eventHandlers[name]["FokusLoss"], LibEKL.Events[name]["FokusLoss"] = Utility.Event.Create(addonInfo.identifier, name .. "FokusLoss")
	
	return textField
		
end

uiFunctions.NKTEXTFIELD = _uiTextfield