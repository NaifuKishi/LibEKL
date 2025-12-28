local addonInfo, privateVars = ...

---------- init namespace ---------

if not LibEKL then LibEKL = {} end

if not privateVars.uiFunctions then privateVars.uiFunctions = {} end

local uiFunctions   = privateVars.uiFunctions
local internalFunc  = privateVars.internalFunc
local data          = privateVars.data

local inspectSystemSecure = Inspect.System.Secure

---------- addon internalFunc function block ---------

local function _uiWindow(name, parent)

  local window = LibEKL.uiCreateFrame("nkCanvas", name, parent)  
  
  if window == nil then return nil end -- event check failed
  
  local body = LibEKL.uiCreateFrame("nkFrame", name .. '.body', window)
  local header = LibEKL.uiCreateFrame("nkFrame", name .. '.header', window)
  local title = LibEKL.uiCreateFrame("nkText", name .. ".title", window)
  local closeIcon = LibEKL.uiCreateFrame("nkClickButton", name .. ".closeIcon", window)
   
  -- GARBAGE COLLECTOR ROUTINES
  
  function window:destroy()
    internalFunc.uiAddToGarbageCollector ('nkCanvas', window)
    internalFunc.uiAddToGarbageCollector ('nkFrame', body)
	  internalFunc.uiAddToGarbageCollector ('nkFrame', header)
    internalFunc.uiAddToGarbageCollector ('nkText', title)
    internalFunc.uiAddToGarbageCollector ('nkFrame', closeIcon)
  end 
  
  -- SPECIFIC FUNCTIONS
  
  local dragable = true
  local closeable = true
  local titleAlign = "left"
  local titleOffSet = 10
  local headerColor
  local windowFill
  local windowStroke
  local windowPath = {{xProportional = 0, yProportional = 0},
                      {xProportional = 0, yProportional = 1},
                      {xProportional = 1, yProportional = 1},
                      {xProportional = 1, yProportional = 0},
                      {xProportional = 0, yProportional = 0},
                }  
    
  window:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 200, 0)
  window:SetWidth(100)
  window:SetHeight(100)
  
  header:SetPoint("TOPLEFT", window, "TOPLEFT")
  header:SetPoint("TOPRIGHT", window, "TOPRIGHT", 0, 10)
  header:SetLayer(1)
  
  body:SetPoint("TOPLEFT", window, "TOPLEFT", 0, 30)
  body:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT")

  title:SetPoint("TOPLEFT", window, "TOPLEFT", 15, 15)
  title:SetFontSize(14)
  
  closeIcon:SetPoint("TOPRIGHT", window, "TOPRIGHT", -10, 10)
  closeIcon:SetText("X")
  closeIcon:SetHeight(12)
  closeIcon:SetWidth(12)
  closeIcon:SetLayer(2)
  
  Command.Event.Attach(LibEKL.events[name .. ".closeIcon"].Clicked, function (_, newValue)		
		window:SetVisible(false)
    LibEKL.eventHandlers[name]["Closed"]()
	end, name .. ".closeIcon.Clicked")
  
  function window:SetTitleFontColor(r, g, b, a)
    title:SetFontColor(r, g, b, a)
    headerColor = {r = r, g = g, b = b, a = a}
  end

  function window:SetTitleEffect(newEffect) title:SetEffectGlow(newEffect) end
  
  window:EventAttach(Event.UI.Input.Mouse.Left.Down, function (self)
    -- dummy event to prevent click through
  end, name .. ".Left.Down")
  
  window:EventAttach(Event.UI.Input.Mouse.Right.Down, function (self)
    -- dummy event to prevent click through
  end, name .. ".Right.Down")
  
  header:EventAttach(Event.UI.Input.Mouse.Left.Down, function (self)    
    if dragable == false then return end
    if window:GetSecureMode() == 'restricted' and inspectSystemSecure() == true then return end
    
    self.leftDown = true
    local mouse = Inspect.Mouse()
    
    self.originalXDiff = mouse.x - self:GetLeft()
    self.originalYDiff = mouse.y - self:GetTop()
    
    local left, top, right, bottom = window:GetBounds()
    
    window:ClearPoint("TOPLEFT")
    window:SetPoint("TOPLEFT", UIParent, "TOPLEFT", left, top)
  end, name .. ".header.Left.Down")
  
  header:EventAttach( Event.UI.Input.Mouse.Cursor.Move, function (self, _, x, y)  
    if self.leftDown ~= true then return end
    
    local newX, newY = x - self.originalXDiff, y - self.originalYDiff
    
    if newX >= data.uiBoundLeft and newX <= data.uiBoundRight and newY + window:GetHeight() >= data.uiBoundTop and newY + window:GetHeight() <= data.uiBoundBottom then    
      window:SetPoint("TOPLEFT", UIParent, "TOPLEFT", newX, newY)
    end
  end, name .. ".header.Cursor.Move")
  
  header:EventAttach( Event.UI.Input.Mouse.Left.Up, function (self) 
    if self.leftDown ~= true then return end
      self.leftDown = false
    LibEKL.eventHandlers[name]["Moved"](window:GetLeft(), window:GetTop())
  end, name .. ".header.Left.Up")
  
  header:EventAttach( Event.UI.Input.Mouse.Left.Upoutside, function (self)
    if self.leftDown ~= true then return end
    self.leftDown = false
    LibEKL.eventHandlers[name]["Moved"](window:GetLeft(), window:GetTop())
  end , name .. ".header.Left.Upoutside")
  
  local oSetVisible = window.SetVisible

	function window:SetVisible(flag)
		oSetVisible(self, flag)
		if flag == true then LibEKL.eventHandlers[name]["Shown"]() end
	end
 
  function window:SetCloseable(flag)
    closeable = flag
    closeIcon:SetVisible(flag)
  end
  
  function window:SetDragable(flag) dragable = flag end  

  function window:GetContent() return body end

  function window:SetTitle(newTitle)
    title:ClearAll()
    title:SetText(newTitle)
    if title:GetWidth() > window:GetWidth() then title:SetWidth(window:GetWidth()) end
    
    if titleAlign == "center" then
      title:SetPoint("CENTERTOP", window, "CENTERTOP", titleOffSet, 5)
    elseif titleAlign == "left" then
      title:SetPoint("TOPLEFT", window, "TOPLEFT", titleOffSet, 5)
    else
      title:SetPoint("TOPRIGHT", window, "TOPRIGHT", titleOffSet, 5)
    end
  end
  
  function window:SetTitleAlign(newAlign, newOffSet)
    if newAlign == "center" or newAlign == "left" or newAlign == "right" then titleAlign = newAlign end
    if newOffSet ~= nil then titleOffSet = tonumber(newOffSet) end
    window:SetTitle(title:GetText())
  end

  function window:SetFontSize(newFontSize)
    title:SetFontSize(newFontSize)
    window:SetTitle(title:GetText())    
  end

	local oSetWidth, oSetHeight = window.SetWidth, window.SetHeight
    
  function window:SetWidth(newWidth)
    oSetWidth(self, newWidth)
    window:SetTitle(title:GetText())
  end 
  
  function window:SetHeight(newHeight)
    oSetHeight(self, newHeight)
  end
  
  function window:SetBorderColor(newStroke)    
    windowStroke = newStroke
    window:SetShape(windowPath, windowFill, windowStroke)
  end

  function window:SetFillColor(newFill) 
    windowFill = newFill
    window:SetShape(windowPath, windowFill, windowStroke)
  end

  function window:SetColor(newFill, newStroke)
    windowStroke = newStroke
    windowFill = newFill
    window:SetShape(windowPath, windowFill, windowStroke)
  end

  function window:SetTitleFont (addonId, fontName) LibEKL.ui.setFont(title, addonId, fontName) end
  function window:SetTitleFontSize (fontSize) title:SetFontSize(fontSize) end  
    
  LibEKL.eventHandlers[name]["Moved"], LibEKL.events[name]["Moved"] = Utility.Event.Create(addonInfo.identifier, name .. "Moved") 
  LibEKL.eventHandlers[name]["Closed"], LibEKL.events[name]["Closed"] = Utility.Event.Create(addonInfo.identifier, name .. "Closed")
  LibEKL.eventHandlers[name]["Dragable"], LibEKL.events[name]["Dragable"] = Utility.Event.Create(addonInfo.identifier, name .. "Dragable")
  LibEKL.eventHandlers[name]["Shown"], LibEKL.events[name]["Shown"] = Utility.Event.Create(addonInfo.identifier, name .. "Shown")
    
  return window
end

uiFunctions.NKWINDOW = _uiWindow
