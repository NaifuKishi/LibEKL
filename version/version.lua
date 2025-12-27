local addonInfo, privateVars = ...

---------- init namespace ---------

if not LibEKL then LibEKL = {} end
if not LibEKL.version then LibEKL.version = {} end

local lang      = privateVars.langTexts

---------- init local variables ---------

local inspectUnitDetail     = Inspect.Unit.Detail
local inspectAddonDetail    = Inspect.Addon.Detail
local inspectTimeServer     = Inspect.Time.Server

local stringFormat          = string.format
local stringFind            = string.find

local _playerStore = {}
local _playerUnit = nil

local blacklist = {"5.03v01.R"}

---------- local function block ---------

local function fctCheckVersion(myVersion, reportedVersion)

    if LibEKL.tools.table.isMember(blacklist, reportedVersion) then return true end

    -- Split the version strings into arrays of numbers
    local myVersionArray = LibEKL.strings.split(myVersion, '%.')
    local reportedVersionArray = LibEKL.strings.split(reportedVersion, '%.')

    -- Ensure both version arrays have the same number of parts
    if #myVersionArray ~= #reportedVersionArray then return false end

    -- Compare each part of the version numbers
    for idx = 1, #myVersionArray, 1 do
        local myPart = tonumber(myVersionArray[idx])
        local reportedPart = tonumber(reportedVersionArray[idx])

        -- If either part is not a number, return true (no clue why)
        if myPart == nil or reportedPart == nil then
            return true
        end

        -- Compare the current parts
        if myPart > reportedPart then
            return true
        elseif myPart < reportedPart then
            return false
        end
    end

    -- If all parts are equal, return true
    return true
end

local function _fctLoadSettings() 

  if LibEKLSetup == nil then LibEKLSetup = {} end
  if LibEKLSetup.addonVersions == nil then LibEKLSetup.addonVersions = {} end
end

local function _fctAddonStartupEnd () 
  for k, v in pairs (LibEKLSetup.addonVersions) do
    if v.localVersion ~= nil then
      local detail = inspectAddonDetail(k)
      if detail == nil then
        LibEKLSetup.addonVersions[k].localVersion = nil
      end
    end
  end
end

local function _fctEventUnitAvailable(_, units)

  if _playerUnit == nil then _playerUnit = inspectUnitDetail('player') end
  if _playerUnit == nil or _playerUnit.availability == nil or _playerUnit.availability ~= "full" then
    _playerUnit = nil
    return
  end
  
  for k, v in pairs (units) do
    if k ~= _playerUnit.id and _playerStore[k] == nil then
      local details = inspectUnitDetail(k)
      if details ~= nil and details.availability ~= nil and details.availability == "full" and details.player==true then
        _playerStore[k] = true
        Command.Message.Send(details.name, "LibEKL.version", "getVersions", function() end)
      end
    end
  end

end

local function _fctProcessMessage(_, from, type, channel, identifier, data)

  if identifier ~= "LibEKL.version" then return end
  
  if data == "getVersions" then
  
    local reportTable = {}
    for k, v in pairs (LibEKLSetup.addonVersions) do reportTable[k] = v.latestVersion end
  
    local msgString = "info=" .. LibEKL.tools.table.serialize (reportTable)    
    Command.Message.Send(from, "LibEKL.version", msgString, function() end)
    
  elseif stringFind(data, "info=") == 1 then
  
    local tempString = LibEKL.strings.right (data, "info=")
    local versionsFunc = loadstring("return {".. tempString .. "}")
    local versions = versionsFunc()
             
    if versions == nil then return end
    
    for k, v in pairs (versions) do
    
      if LibEKLSetup.addonVersions[k] == nil then
      
        LibEKLSetup.addonVersions[k] = {}
        LibEKLSetup.addonVersions[k].latestVersion = v
        
      elseif LibEKLSetup.addonVersions[k].localVersion ~= nil then
      
        if fctCheckVersion(LibEKLSetup.addonVersions[k].latestVersion, v) == false then
          -- the highest known version is smaller than the reported version
          Command.Console.Display("general", true, stringFormat(lang.addonUpdate, v, k), true)
          LibEKLSetup.addonVersions[k].latestVersion = v
                             
        elseif fctCheckVersion(LibEKLSetup.addonVersions[k].localVersion, v) == false then
        
          -- the local version is smaller than the reported version 
          
          local now = inspectTimeServer()
          
          if LibEKLSetup.addonVersions[k].lastUserInfo == nil or now - LibEKLSetup.addonVersions[k].lastUserInfo > 86400 then
            -- only report once a day
            LibEKLSetup.addonVersions[k].lastUserInfo = now
            Command.Console.Display("general", true, stringFormat(lang.addonUpdate, v, k), true)
          end
          
        end 
      end
    end   
  end

end

---------- library public function block ---------

function LibEKL.version.init(addonName, addonVersion)	

	if LibEKLSetup.addonVersions [addonName] == nil then LibEKLSetup.addonVersions [addonName] = {} end

	LibEKLSetup.addonVersions [addonName].localVersion = addonVersion
	if LibEKLSetup.addonVersions [addonName].latestVersion == nil or fctCheckVersion (addonVersion, LibEKLSetup.addonVersions [addonName].latestVersion) == true then 
		 LibEKLSetup.addonVersions [addonName].latestVersion = addonVersion
	end 
	
end

-------------------- STARTUP EVENTS --------------------

Command.Message.Accept(nil, "LibEKL.version")
Command.Event.Attach(Event.Unit.Availability.Full, _fctEventUnitAvailable, "LibEKL.version.Unit.Availability.Full")
Command.Event.Attach(Event.Message.Receive, _fctProcessMessage, "LibEKL.version.Message.Receive")
Command.Event.Attach(Event.Addon.SavedVariables.Load.End, _fctLoadSettings, "LibEKL.version.SavedVariables.Load.End")
Command.Event.Attach(Event.Addon.Startup.End, _fctAddonStartupEnd, "LibEKL.version.Startup.End")