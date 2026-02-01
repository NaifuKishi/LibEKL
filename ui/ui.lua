local addonInfo, privateVars = ...

---------- init namespace ---------

if not LibEKL then LibEKL = {} end
if not LibEKL.UI then LibEKL.UI = {} end

if not privateVars.uiFunctions then privateVars.uiFunctions = {} end
if not privateVars.uiNames then privateVars.uiNames = {} end

if privateVars.uiContext == nil then privateVars.uiContext = UI.CreateContext("LibEKL.UI") end

if not privateVars.uiElements then privateVars.uiElements = {} end

local data       		= privateVars.data
local internalFunc 		= privateVars.internalFunc
local uiFunctions		= privateVars.uiFunctions
local uiNames    		= privateVars.uiNames
local uiElements		= privateVars.uiElements

local uiContext   		= privateVars.uiContext
local uiTooltipContext	= nil

local inspectSystemSecure 		= Inspect.System.Secure
local inspectAddonCurrent 		= Inspect.Addon.Current
local inspectAbilityNewDetail	= Inspect.Ability.New.Detail
local InspectAbilityDetail		= Inspect.Ability.Detail

local stringUpper				= string.upper
local stringFormat				= string.format
local stringLower				= string.lower
local stringGSub				= string.gsub

---------- init variables --------- 

if not uiElements.messageDialog then uiElements.messageDialog = {} end
if not uiElements.confirmDialog then uiElements.confirmDialog = {} end

data.frameCount = 0
data.canvasCount = 0
data.textCount = 0
data.textureCount = 0
data.uiBoundLeft, data.uiBoundTop, data.uiBoundRight, data.uiBoundBottom = UIParent:GetBounds()

---------- init local variables ---------

local _gc = {}
local _freeElements = {}
local _fonts = {}

local function recycleElement (element, elementType)

	element:SetVisible(false)
	element:ClearAll()
	element:SetBackgroundColor(0,0,0,0)
	element:SetStrata('main')
	element:SetLayer(0)
	element:SetMouseMasking('full')
	element:SetWidth(0)
	element:SetHeight(0)
	
	if element:GetMouseoverUnit() ~= nil then element:SetMouseoverUnit(nil) end
	
	--element:SetSecureMode("normal")
	
	for k, v in pairs (element:GetEvents()) do
	  element:EventDetach(k, nil, v.label, v.priority, v.owner)
	end
	
	element:recycle()
	
end

function internalFunc.uiGarbageCollector ()
	local debugId  
    if nkDebug then debugId = nkDebug.traceStart (inspectAddonCurrent(), "LibEKL internal.uiGarbageCollector") end

	local secure = inspectSystemSecure()
	local flag = false
	local restrictedFailed = false

	for elementType, secureModes in pairs(_gc) do

		if secure == false and #_gc[elementType].restricted > 0 then
			for idx = 1, #_gc[elementType].restricted, 1 do

				if _gc[elementType].restricted[idx] ~= false then

					local element = _gc[elementType].restricted[idx]
					local err = pcall (_setInsecure, element)
	
					if err == true then -- no error
						flag = true
						recycleElement(element, elementType)
						uiNames[elementType][element:GetRealName()] = ""

						if _freeElements[elementType] == nil then _freeElements[elementType] = {} end
						table.insert(_freeElements[elementType], element)
						_gc[elementType].restricted[idx] = false
					else
						restrictedFailed = true
					end
				end
			end

			if restrictedFailed == false then _gc[elementType].restricted = {} end
		end

		for idx = 1, #_gc[elementType].normal, 1 do
			flag = true
			local element = _gc[elementType].normal[idx]
			recycleElement(element, elementType)
			uiNames[elementType][element:GetRealName()] = ""

			if _freeElements[elementType] == nil then _freeElements[elementType] = {} end
			table.insert(_freeElements[elementType], element)
		end

		_gc[elementType].normal = {}
		
	end

	if flag == true then LibEKL.eventHandlers["LibEKL.internal"]["gcChanged"]() end

	if nkDebug then nkDebug.traceEnd (inspectAddonCurrent(), "LibEKL internal.uiGarbageCollector", debugId) end	
end

function internalFunc.uiAddToGarbageCollector (frameType, element)

	local checkFrameType = stringUpper(frameType) 

	if _gc[checkFrameType] == nil then _gc[checkFrameType] = {} end
	if _gc[checkFrameType].normal == nil then _gc[checkFrameType].normal = {} end
	if _gc[checkFrameType].restricted == nil then _gc[checkFrameType].restricted = {} end
	
	table.insert(_gc[checkFrameType][element:GetSecureMode()], element) 
	if inspectSystemSecure() == false or element:GetSecureMode() == 'normal' then element:SetVisible(false) end
	
	--print ("LibEKL: Added " .. element:GetRealName() .. " to garbage collector")

	LibEKL.eventHandlers["LibEKL.internal"]["gcChanged"]()
  
end  


-- generic ui functions to handle screen size and bounds

function LibEKL.UI.setupBoundCheck()

	local testFrameH = LibEKL.UICreateFrame ('nkFrame', "LibEKL.UI.boundTestFrameH", uiContext)
	testFrameH:SetBackgroundColor(0, 0, 0, 0)
	testFrameH:SetPoint("TOPLEFT", UIParent, "TOPLEFT")
	testFrameH:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 1)

	testFrameH:EventAttach(Event.UI.Layout.Size, function (self)
		data.uiBoundLeft, data.uiBoundTop, data.uiBoundRight, data.uiBoundBottom = UIParent:GetBounds()
	end, testFrameH:GetName() .. ".UI.Layout.Size")

	local testFrameV = LibEKL.UICreateFrame("nkFrame", "LibEKL.UI.boundTestFrameV", uiContext)
	testFrameV:SetBackgroundColor(0, 0, 0, 0)
	testFrameV:SetPoint("TOPLEFT", UIParent, "TOPLEFT")
	testFrameV:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 1, 0)

	testFrameV:EventAttach(Event.UI.Layout.Size, function (self)		
		data.uiBoundLeft, data.uiBoundTop, data.uiBoundRight, data.uiBoundBottom = UIParent:GetBounds()
	end, testFrameV:GetName() .. ".UI.Layout.Size")
	
end

function LibEKL.UI.getBoundBottom() return data.uiBoundBottom end
function LibEKL.UI.getBoundRight() return data.uiBoundRight end

function LibEKL.UI.showWithinBound (element, target)

	local from, to, x, y

	if target:GetTop() + element:GetHeight() > LibEKL.UI.getBoundBottom() then
		if element:GetLeft() + element:GetWidth() > LibEKL.UI.getBoundRight() then
			from, to, x, y = "BOTTOMRIGHT", "TOPLEFT", -5, -5
		else
			from, to, x, y = "BOTTOMLEFT", "BOTTOMLEFT", 5, -5
		end
	else
		if target:GetLeft() + element:GetWidth() > LibEKL.UI.getBoundRight() then
			from, to, x, y = "BOTTOMRIGHT", "TOPLEFT", -5, -5
		else
			from, to, x, y = "TOPLEFT", "BOTTOMLEFT", -5, 5
		end		
	end
	
	if from ~= nil then
		local left, top, right, bottom = element:GetBounds()
		element:ClearAll()
		element:SetPoint(from, target, to, x, y)
		element:SetWidth(right-left)
		element:SetHeight(bottom-top)
	end

end

function LibEKL.UI.reloadDialog (title)

	if uiElements.reloadDialog ~= nil then
		LibEKL.Events.AddInsecure(function() 
			uiElements.reloadDialog:SetTitle(title)
			uiElements.reloadDialog:SetTitleAlign('center')
			uiElements.reloadDialog:SetVisible(true)
		end, nil, nil)
		return
	end
	
	if privateVars.uiContextSecure == nil then 
		privateVars.uiContextSecure = UI.CreateContext("LibEKL.UI.secure") 
		privateVars.uiContextSecure:SetStrata ('topmost')
		privateVars.uiContextSecure:SetSecureMode('restricted')
	end
	
	local name = "LibEKL.reloadDialog"
	
	uiElements.reloadDialog = LibEKL.UICreateFrame("nkWindow", name, privateVars.uiContextSecure)
	uiElements.reloadDialog:ClearAll()
	uiElements.reloadDialog:SetSecureMode('restricted')
	uiElements.reloadDialog:GetContent():SetSecureMode('restricted')
	uiElements.reloadDialog:SetTitle(title)
	uiElements.reloadDialog:SetTitleAlign('center')
	uiElements.reloadDialog:SetWidth(400)
	uiElements.reloadDialog:SetHeight(150)
	uiElements.reloadDialog:SetCloseable(false)	
	uiElements.reloadDialog:SetPoint("CENTERTOP", UIParent, "CENTERTOP", 0, 50)
	uiElements.reloadDialog:SetTitleFont(addonInfo.id, "MontserratBold")
    uiElements.reloadDialog:SetTitleFontSize(16)
    uiElements.reloadDialog:SetTitleEffect ( {strength = 3})
    uiElements.reloadDialog:SetCloseable(true)
    uiElements.reloadDialog:SetTitleFontColor(1, .8, 0, 1)

    uiElements.reloadDialog:SetColor({
        type = "gradientLinear",
        transform = Utility.Matrix.Create(6, 0.5, math.pi / 4, 0, 0),  -- 45° rotation
        color = {
            {r = 0.08, g = 0.10, b = 0.15, a = 1, position = 0}, -- Start color
            {r = 0.0549, g = 0.0706, b = 0.1059, a = 1, position = 1}  -- End color
        }
    },  { r = 0, g = 0, b = 0, a = 1, thickness = 1})
	
	local msg = LibEKL.UICreateFrame("nkText", name .. ".msg", uiElements.reloadDialog:GetContent())
	msg:SetText(privateVars.langTexts.msgReload)
	msg:SetPoint("CENTERTOP", uiElements.reloadDialog:GetContent(), "CENTERTOP", 0, 10)
	msg:SetFontSize(16)
	msg:SetFontColor(1,1,1,1)

	LibEKL.UI.SetFont(msg, addonInfo.id, "MontserratSemiBold")
	
	local button = LibEKL.UICreateFrame("nkButton", name .. ".button", uiElements.reloadDialog:GetContent())
	button:SetPoint("CENTERTOP", msg, "CENTERBOTTOM", 0, 20)
	button:SetText(privateVars.langTexts.reloadButton)
	button:SetMacro("/reloadui")
	button:SetFont(addonInfo.id, "MontserratSemiBold")
    button:SetLabelColor({r = 1, g = 0.8, b = 0, a = 1})
    button:SetEffectGlow ({ strength = 3 })
    button:SetFillColor({ type = "solid", r = 0, g = 0, b = 0, a = .4})
    button:SetBorderColor({ r = 0, g = 0, b = 0, a = .7, thickness = 1})
	
end

-------- tooltips

function LibEKL.UI.attachItemTooltip (target, itemId, callBack)

	local name = "LibEKL.itemTooltip"

	if privateVars.uiTooltipContext == nil then
		privateVars.uiTooltipContext = UI.CreateContext("LibEKL.UI.tooltip")
		privateVars.uiTooltipContext:SetStrata ('topmost')
	end
	
	if uiElements.itemTooltip == nil then	
		uiElements.itemTooltip = LibEKL.UICreateFrame('nkItemTooltip', name, privateVars.uiTooltipContext)
		uiElements.itemTooltip:SetVisible(false)    
		
		LibEKL.eventHandlers[name]["Visible"], LibEKL.Events[name]["Visible"] = Utility.Event.Create(addonInfo.identifier, name .. "Visible")
	end

	if itemId == nil then
		target:EventDetach(Event.UI.Input.Mouse.Cursor.In, nil, target:GetName() .. ".Mouse.Cursor.In")
		target:EventDetach(Event.UI.Input.Mouse.Cursor.Out, nil, target:GetName() .. ".Mouse.Cursor.In")  
		uiElements.itemTooltip:SetVisible(false)
	else
		target:EventAttach(Event.UI.Input.Mouse.Cursor.In, function (self)
			uiElements.itemTooltip:ClearAll()
			uiElements.itemTooltip:SetItem(itemId)
			uiElements.itemTooltip:SetVisible(true)			
			
			uiElements.itemTooltip:SetPoint("TOPLEFT", target, "BOTTOMRIGHT", 5, 5)
			LibEKL.UI.showWithinBound (uiElements.itemTooltip, target)
			
			if callBack ~= nil then callBack(target, itemId) end
			
			LibEKL.eventHandlers[name]["Visible"](true)
			
		end, target:GetName() .. ".Mouse.Cursor.In")
  
		target:EventAttach(Event.UI.Input.Mouse.Cursor.Out, function (self)
			uiElements.itemTooltip:SetVisible(false)
			LibEKL.eventHandlers[name]["Visible"](false)
			
		end, target:GetName() .. ".Mouse.Cursor.Out") 
	end
	
end

function LibEKL.UI.attachGenericTooltip (target, title, text)

	if privateVars.uiTooltipContext == nil then
		privateVars.uiTooltipContext = UI.CreateContext("LibEKL.UI.tooltip")
		privateVars.uiTooltipContext:SetStrata ('topmost')
	end
	
	if uiElements.genericTooltip == nil then
		uiElements.genericTooltip = LibEKL.UICreateFrame('nkTooltip', 'LibEKL.genericTooltip', privateVars.uiTooltipContext)
		uiElements.genericTooltip:SetVisible(false)    
	end

	if text == nil then
		target:EventDetach(Event.UI.Input.Mouse.Cursor.In, nil, target:GetName() .. ".Mouse.Cursor.In")
		target:EventDetach(Event.UI.Input.Mouse.Cursor.Out, nil, target:GetName() .. ".Mouse.Cursor.In")  
		uiElements.genericTooltip:SetVisible(false)
	else
		target:EventAttach(Event.UI.Input.Mouse.Cursor.In, function (self)
			uiElements.genericTooltip:ClearAll()
			
			uiElements.genericTooltip:SetWidth(200)
			if title ~= nil then 
				uiElements.genericTooltip:SetTitle(stringGSub(title, "\n", ""))
			else
				uiElements.genericTooltip:SetTitle("")
			end

			uiElements.genericTooltip:SetLines({{ text = text, wordwrap = true, minWidth = 200 }})							
			uiElements.genericTooltip:SetPoint("TOPLEFT", target, "BOTTOMRIGHT", 5, 5)

			LibEKL.UI.showWithinBound (uiElements.genericTooltip, target)
			
			uiElements.genericTooltip:SetVisible(true)			
		end, target:GetName() .. ".Mouse.Cursor.In")
  
		target:EventAttach(Event.UI.Input.Mouse.Cursor.Out, function (self)
			uiElements.genericTooltip:SetVisible(false)
		end, target:GetName() .. ".Mouse.Cursor.Out") 
	end

end

function LibEKL.UI.genericTooltipSetFont (addonId, fontName)
	if privateVars.uiTooltipContext == nil then return end
	if uiElements.genericTooltip == nil then return end

	uiElements.genericTooltip:SetFont (addonId, fontName)
end

function LibEKL.UI.attachAbilityTooltip (target, abilityId)

	if privateVars.uiTooltipContext == nil then
		privateVars.uiTooltipContext = UI.CreateContext("LibEKL.UI.tooltip")
		privateVars.uiTooltipContext:SetStrata ('topmost')
	end
	
	if uiElements.abilityTooltip == nil then	
		uiElements.abilityTooltip = LibEKL.UICreateFrame('nkTooltip', 'LibEKL.abilityTooltip', privateVars.uiTooltipContext)
		uiElements.abilityTooltip:SetVisible(false)    
	end

	if abilityId == nil then
		target:EventDetach(Event.UI.Input.Mouse.Cursor.In, nil, target:GetName() .. ".Mouse.Cursor.In")
		target:EventDetach(Event.UI.Input.Mouse.Cursor.Out, nil, target:GetName() .. ".Mouse.Cursor.In")  
		uiElements.abilityTooltip:SetVisible(false)
	else
		target:EventAttach(Event.UI.Input.Mouse.Cursor.In, function (self)
			--print (abilityId)

			uiElements.abilityTooltip:ClearAll()
			local err, abilityDetails = pcall (inspectAbilityNewDetail, abilityId)
			if err == false or abilityDetails == nil then
				err, abilityDetails = pcall (InspectAbilityDetail, abilityId)
				if err == false or abilityDetails == nil then
					LibEKL.Tools.Error.Display (addonInfo.identifier, "LibEKL.UI.attachAbilityTooltip: unable to get details of ability with id " .. abilityId)	
					LibEKL.UI.attachAbilityTooltip (target, nil)
					return
				end
			end
			
			uiElements.abilityTooltip:SetWidth(200)
			uiElements.abilityTooltip:SetTitle(stringGSub(abilityDetails.name, "\n", ""))

			if abilityDetails.description then	
				uiElements.abilityTooltip:SetLines({{ text = abilityDetails.description, wordwrap = true, minWidth = 200  }})
			else
				uiElements.abilityTooltip:ClearLines()
			end
						
			uiElements.abilityTooltip:SetPoint("TOPLEFT", target, "BOTTOMRIGHT", 5, 5)
			LibEKL.UI.showWithinBound (uiElements.abilityTooltip, target)
			
			uiElements.abilityTooltip:SetVisible(true)			
		end, target:GetName() .. ".Mouse.Cursor.In")
  
		target:EventAttach(Event.UI.Input.Mouse.Cursor.Out, function (self)
			uiElements.abilityTooltip:SetVisible(false)
		end, target:GetName() .. ".Mouse.Cursor.Out") 
	end
end

function LibEKL.UI.abilityTooltipSetFont (addonId, fontName)
	if privateVars.uiTooltipContext == nil then return end
	if uiElements.abilityTooltip == nil then return end

	uiElements.abilityTooltip:SetFont (addonId, fontName)
end

-------- font management

function LibEKL.UI.registerFont (addonId, name, path)

	if _fonts[addonId] == nil then _fonts[addonId] = {} end

	_fonts[addonId][name] = path

end

function LibEKL.UI.SetFont (uiElement, addonId, name)	

	if not _fonts[addonId] then return end

	--print (addonId, _fonts[addonId][name])

	uiElement:SetFont(addonId, _fonts[addonId][name])

end

--------- dialogs

function LibEKL.UI.confirmDialog (message, yesFunc, noFunc)

	local thisDialog

	for idx = 1, #uiElements.confirmDialog, 1 do
		if uiElements.confirmDialog[idx]:GetVisible() == false then
			thisDialog = uiElements.confirmDialog[idx]

			break
		end
	end

	if thisDialog == nil then
		if privateVars.uiDialogContext == nil then 
			privateVars.uiDialogContext = UI.CreateContext("LibEKL.UI.dialog") 
			privateVars.uiDialogContext:SetStrata ('topmost')
		end
	
		local name = "LibEKLConfirmDialog." .. (#uiElements.messageDialog+1)
	
		thisDialog = LibEKL.UICreateFrame("nkDialog", name, privateVars.uiDialogContext)
		thisDialog:SetWarn(false)
		thisDialog:SetLayer(2)
		thisDialog:SetWidth(500)
		thisDialog:SetHeight(250)
		thisDialog:SetType('confirm')
		
		table.insert(uiElements.confirmDialog, thisDialog)
	end
	
	thisDialog:SetMessage(message)
	thisDialog:SetVisible(true)

	Command.Event.Detach(LibEKL.Events[thisDialog:GetName()].LeftButtonClicked, nil, thisDialog:GetName() .. ".LeftButtonClicked") -- detach event if was previously used
	
	Command.Event.Attach(LibEKL.Events[thisDialog:GetName()].LeftButtonClicked, function ()
		if yesFunc ~= nil then yesFunc() end
	end, thisDialog:GetName() .. ".LeftButtonClicked")
	
	Command.Event.Detach(LibEKL.Events[thisDialog:GetName()].RightButtonClicked, nil, thisDialog:GetName() .. ".RightButtonClicked") -- detach event if was previously used
	
	Command.Event.Attach(LibEKL.Events[thisDialog:GetName()].RightButtonClicked, function ()
		if noFunc ~= nil then noFunc() end
	end, thisDialog:GetName() .. ".RightButtonClicked")

	return thisDialog
	    
end

function LibEKL.UI.messageDialog (message, okFunc)

	local thisDialog

	for idx = 1, #uiElements.messageDialog, 1 do
		if uiElements.messageDialog[idx]:GetVisible() == false then
			thisDialog = uiElements.messageDialog[idx]
			break
		end
	end
	
	if thisDialog == nil then
		if privateVars.uiDialogContext == nil then 
			privateVars.uiDialogContext = UI.CreateContext("LibEKL.UI.dialog") 
			privateVars.uiDialogContext:SetStrata ('topmost')
		end
		
		local name = "LibEKLMessageDialog." .. LibEKL.Tools.UUID ()
	
		thisDialog = LibEKL.UICreateFrame("nkDialog", name, privateVars.uiDialogContext)
		thisDialog:SetWarn(false)
		thisDialog:SetLayer(2)
		thisDialog:SetWidth(500)
		thisDialog:SetHeight(250)
		thisDialog:SetType('message')
		
		table.insert(uiElements.messageDialog, thisDialog)
	end
  
	thisDialog:SetMessage(message)
	thisDialog:SetVisible(true)
	
	Command.Event.Detach(LibEKL.Events[thisDialog:GetName()].CenterButtonClicked, nil, thisDialog:GetName() .. ".CenterButtonClicked") -- detach event if was previously used
	
	if okFunc ~= nil then
		Command.Event.Attach(LibEKL.Events[thisDialog:GetName()].CenterButtonClicked, function ()
			okFunc()
		end, thisDialog:GetName() .. ".CenterButtonClicked")
	end

	return thisDialog
	
end

-------- ui element creation

function LibEKL.UICreateFrame (frameType, name, parent)

	if frameType == nil or name == nil or parent == nil then
		LibEKL.Tools.Error.Display (addonInfo.identifier, stringFormat("LibEKL.UICreateFrame - invalid number of parameters\nexpecting: type of frame (string), name of frame (string), parent of frame (object)\nreceived: %s, %s, %s", frameType, name, parent))
		return
	end

	local uiObject = nil

	local checkFrameType = stringUpper(frameType) 

	if _freeElements[checkFrameType] ~= nil and #_freeElements[checkFrameType] > 0 then

		--print ("recycling " .. checkFrameType)

		if LibEKL.Events.CheckEvents (name, true) == false then return nil end

		uiObject = _freeElements[checkFrameType][1]    
		uiObject:SetParent(parent)

		if uiNames[checkFrameType] == nil then uiNames[checkFrameType] = {} end
		
		uiNames[checkFrameType][uiObject:GetRealName()] = name
		uiObject:SetVisible(true)
		uiObject:ClearAll() -- no clue why this is needed for canvas here but the one in _recycleElement doesn't seem to work

		table.remove(_freeElements[checkFrameType], 1)
		
		LibEKL.eventHandlers["LibEKL.internal"]["gcChanged"]()
		
	else
		local func = uiFunctions[checkFrameType]
		if func == nil then
			LibEKL.Tools.Error.Display (addonInfo.identifier, stringFormat("LibEKL.UICreateFrame - unknown frame type [%s]", frameType))
		else
			uiObject = func(name, parent)
		end
	end

	return uiObject

end