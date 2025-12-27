local addonInfo, privateVars = ...

---------- init namespace ---------

if not LibEKL then LibEKL = {} end
if not LibEKL.tools then LibEKL.tools = {} end

LibEKL.tools.table = {}
LibEKL.tools.math = {}
LibEKL.tools.lang = {}
LibEKL.tools.error = {}
LibEKL.tools.color = {}
LibEKL.tools.gfx = {}
LibEKL.tools.perf = {}

local data        	= privateVars.data
local internalFunc	= privateVars.internalFunc

---------- init local variables ---------

local InspectSytemLanguage 	= Inspect.System.Language
local InspectSystemWatchdog	= Inspect.System.Watchdog

local mathModf		= math.modf
local mathFloor		= math.floor
local osDate		= os.date
local osTime		= os.time
local stringLower	= string.lower
local stringFind	= string.find
local stringLen		= string.len
local stringFormat	= string.format
local tableInsert	= table.insert
local tableRemove	= table.remove
local tableSort		= table.sort

-- ========== DATE HANDLING ==========

function LibEKL.tools.getDaysInMonth(month, year)

	local daysInMonth = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }   
	local d = daysInMonth[month]
   
	-- check for leap year
	
	if (month == 2) then
		if (mathModf(year,4) == 0) then
			if (mathModf(year,100) == 0) then                
				if (mathModf(year,400) == 0) then                    
					d = 29
				end
			else                
				d = 29
			end
		end
	end

	return d  
	
end

function LibEKL.tools.adjustDate(inDate, adjustBy, value)

	local newDate
	local day, month, year = tonumber(osDate("%d", inDate)), tonumber(osDate("%m", inDate)), tonumber(osDate("%Y", inDate))
	
	if stringLower(adjustBy) == 'day' then
		
		day = day + value
		
		if day < 1 then
			month = month -1
			if month < 1 then
				year = year - 1
				month = 12
			end

			day = LibEKL.tools.getDaysInMonth(month, year) + day
		elseif day > LibEKL.tools.getDaysInMonth(month, year) then
			day = day - LibEKL.tools.getDaysInMonth(month, year)
			month = month + 1
			if month > 12 then 
				year = year + 1 
				month = 1
			end
		end
	
		newDate = osTime{year = year, month = month, day = day }
		
	elseif stringLower(adjustBy) == 'month' then
	
		month = month + value
		if month > 12 then
			year = year + 1		
			month = 1
		elseif month < 1 then
			year = year - 1
			month = 12
		end

		newDate = osTime{year = year, month = month, day = day }
	
	end
	
	return newDate

end

function LibEKL.tools.adjustTime(inTime, adjustBy, value)

	local day, month, year = tonumber(osDate("%d", inTime)), tonumber(osDate("%m", inTime)), tonumber(osDate("%Y", inTime))
	local hour, minute, second = tonumber(osDate("%H", inTime)), tonumber(osDate("%M", inTime)), tonumber(osDate("%S", inTime))
	
	if stringLower(adjustBy) == 'min' then
		
		minute = minute + value
		if minute > 60 then
			minute = minute - 60
			hour = hour + 1
			if hour > 23 then
				hour = 0
				local tempDate = osTime{year = year, month = month, day = day, hour = hour, min = minute, sec = second}
				return LibEKL.tools.adjustDate(tempDate, "day", 1)
			end
		elseif minute < 0 then
			minute = 59 - minute
			hour = hour - 1
			if hour < 0 then
				hour = 23
				local tempDate = osTime{year = year, month = month, day = day, hour = hour, min = minute, sec = second}
				return LibEKL.tools.adjustDate(tempDate, "day", -1)
			end
		end
		
		return osTime{year = year, month = month, day = day, hour = hour, min = minute, sec = second}
				
	end
	
	return nil

end

function LibEKL.tools.isDatePast(inDate)

	if LibEKL.tools.today() > inDate then
		return true
	else
		return false
	end

end

function LibEKL.tools.today()
	return osTime{year = osDate("%Y"), month = osDate("%m"), day = osDate("%d")}
end

function LibEKL.tools.secondsToText (seconds)
	return LibEKL.tools.seoncdsToText(seconds)
end

function LibEKL.tools.seoncdsToText (seconds)

	if seconds < 0 then
		return ""
	elseif seconds > 3600 then
		return tostring(mathFloor(seconds / 3600)).."h"
	elseif seconds > 60 then
		return tostring(mathFloor(seconds / 60)).."m"
	end
	
	return tostring(mathFloor(seconds).."s")

end

-- ========== TABLE HANDLING ==========

function LibEKL.tools.table.isMember (checkTable, element)

	if checkTable == nil then return false end
  
	for idx, value in pairs(checkTable) do
		if value == element then return true end
	end

	return false
  
end

function LibEKL.tools.table.getTablePos (checkTable, element)

	for idx, value in pairs (checkTable) do
		if value == element then return idx end
	end
	
	return -1

end

function LibEKL.tools.table.addValue (checkTable, element)

	if not LibEKL.tools.table.isMember (checkTable, element) then
		tableInsert(checkTable, element)
	end

end

function LibEKL.tools.table.removeValue (checkTable, element)

	local pos = LibEKL.tools.table.getTablePos (checkTable, element)
	if pos ~= -1 then tableRemove(checkTable, pos) end
	
	return checkTable

end

function LibEKL.tools.table.getSortedKeys (tableData)

	local tempTable = {}
    
	for k, data in pairs(tableData) do tableInsert(tempTable, k) end

	tableSort(tempTable, function (a, b) return stringLower(a) < stringLower(b) end)
	return tempTable
	
end

function LibEKL.tools.table.merge (table1, table2)

	for k, v in pairs (table2) do tableInsert (table1, v) end

end

function LibEKL.tools.table.mergeIndexed (table1, table2)

	for k, v in pairs (table2) do table1[k] = v end

end

function LibEKL.tools.table.getKeyByValue (tableData, value)

	for k, v in pairs (tableData) do
		if v == value then return k end
	end
	
	return nil

end

function LibEKL.tools.table.copy (tableToCopy)

  local lookup_table = {}
  
  local function _copy(tableToCopy)
      if type(tableToCopy) ~= "table" then
          return tableToCopy
      elseif lookup_table[tableToCopy] then
          return lookup_table[tableToCopy]
      end
      local new_table = {}
      lookup_table[tableToCopy] = new_table
      for index, value in pairs(tableToCopy) do
          new_table[_copy(index)] = _copy(value)
      end
      return setmetatable(new_table, getmetatable(tableToCopy))
  end
  
  return _copy(tableToCopy)
    
end

function LibEKL.tools.table.getSize (checkTable)

  local count = 0
  for _ in pairs(checkTable) do count = count + 1 end
  return count
  
end

function LibEKL.tools.table.serialize (inTable)

	if type(inTable) ~= 'table' then return inTable end

	local retValue = ""
	local isFirst = true

	for k, v in pairs (inTable) do
		if isFirst == false then retValue = retValue .. ',' end
	
		if type(k) == 'string' then
			if stringFind(k, " ") or stringFind(k, "-") or stringFind (k, ".", 1, true) then
				retValue = retValue .. '["' .. k .. '"]='
			else
				retValue = retValue .. k .. '='
			end
		end
	
		if type(v) == 'table' then
			retValue = retValue .. "{" .. LibEKL.tools.table.serialize (v) .. "}"
		elseif type(v) == 'string' then
			retValue = retValue .. '"' .. v .. '"'
		elseif type(v) == 'boolean' then
			if v == true then
				retValue = retValue .. "true"
			else
				retValue = retValue .. "false"
			end
		elseif type(v) == 'function' then
			retValue = retValue .. '{function}'
		else
			retValue = retValue .. v
		end
		
		isFirst = false
	end
	
	return retValue
end

function LibEKL.tools.table.getFirstElement (checkTable)

	for key, content in pairs (checkTable) do
		return key, content
	end
	
	return nil, nil

end

function LibEKL.tools.table.getLastElement (checkTable)

	local retKey, retContent

	for key, content in pairs (checkTable) do
		retKey, retContent = key, content
	end
	
	return retKey, retContent

end

-- ========== MATH FUNCTIONS ==========

function LibEKL.tools.math.round (num, idp)

	if num == nil then return nil end

	local mult = 10^(idp or 0)
	return mathFloor(tonumber(num) * mult + 0.5) / mult
	
end

-- ========== PERFORMANCE TOOLS ==========

function LibEKL.tools.perf.addToQueue(func)

	if data.perfQueue == nil then data.perfQueue = {} end
	tableInsert(data.perfQueue, func)

end

function internalFunc.processPerformanceQueue()

	if data.perfQueue == nil or #data.perfQueue == 0 then return end
	if InspectSystemWatchdog() < 0.1 then return end
		
	data.perfQueue[1]()
	tableRemove(data.perfQueue, 1, 1)
	
end

-- ========== LANGUAGE HANDLING ==========

function LibEKL.tools.lang.getLanguage ()

	if LibEKLSetup == nil then
		return InspectSytemLanguage()
	elseif LibEKLSetup.language == nil then 
		return InspectSytemLanguage()
	else
		return LibEKLSetup.language
	end

end

function LibEKL.tools.lang.getLanguageShort ()

	if LibEKL.tools.lang.getLanguage() == 'German' then
		return 'DE'
	elseif LibEKL.tools.lang.getLanguage() == 'French' then		
		return 'FR'
	elseif LibEKL.tools.lang.getLanguage() == 'Russian' then		
		return 'RU'
	else
		return 'EN'
	end

end

function LibEKL.tools.lang.setLanguage (language) 

	if LibEKLSetup == nil then LibEKLSetup = {} end
	LibEKLSetup.language = language
	InspectSytemLanguage = language -- this is probably a bug

end

function LibEKL.tools.lang.resetLanguage()

	if LibEKLSetup == nil then LibEKLSetup = {} end
	LibEKLSetup.language = nil

end

-- ========== ERROR HANDLING ==========

function LibEKL.tools.error.display (addon, message, level)

	local color, type
	if level == 1 then
		color = "#FF0000"
		type = "FATAL ERROR"
	elseif level == 2 then
		color = "#FF6A00"
		type = "ERROR"
	elseif level == 3 then
		color = "FFD800"
		type = "WARNING"		
	else
		color = "#FFFFFF"
		type = "INFO"
	end

	Command.Console.Display("general", true, stringFormat('<font color="%s">%s in %s: %s</font>', color, type, addon, message), true)

end

-- ========== COLOR TOOLS ==========

function LibEKL.tools.color.HSV2RGB(h, s, v)

	local i, f, w, q, t, hue
	local r, g, b
	
	if s == 0.0 then
		r, g, b = v, v, v
	else
		hue = h
		if hue == 1.0 then hue = 0.0 end
		hue = hue * 6.0
		
		i = mathFloor(hue)
		f = hue - i
		w = v * (1.0 - s)
		q = v * (1.0 - (s * f))
		t = v * (1.0 - (s * (1.0 - f)))
		if i == 0 then
			r, g, b = v, t, w
		elseif i == 1 then
			r, g, b = q, v, w
		elseif i == 2 then
			r, g, b = w, v, t
		elseif i == 3 then
			r, g, b = w, q, v
		elseif i == 4 then
			r, g, b = t, w, v
		elseif i == 5 then
			r, g, b = v, w, q
		end
	end
	
	return r, g, b
end

function LibEKL.tools.color.RGBToHex(red, green, blue)

	local redHex = stringFormat("%X", red) 	
	local greenHex = stringFormat("%X", green) 
	local blueHex = stringFormat("%X", blue) 
	
	local retValue = ''
	
	if red == 0 then
		retValue = '00'
	elseif stringLen(redHex) == 1 then
		retValue = '0' .. redHex
	else
		retValue = redHex
	end

	if green == 0 then
		retValue = retValue .. '00'
	elseif stringLen(greenHex) == 1 then
		retValue = retValue .. '0' .. greenHex
	else
		retValue = retValue .. greenHex
	end
	
	if blue == 0 then
		retValue = retValue .. '00'
	elseif stringLen(blueHex) == 1 then
		retValue = retValue .. '0' .. blueHex
	else
		retValue = retValue .. blueHex
	end

	return retValue
	
end

function LibEKL.tools.color.adjust(red, green, blue, factor)

  local newRed = red * factor
  if newRed > 1 then newRed = 1 end
  
  local newBlue = blue * factor
  if newBlue > 1 then newBlue = 1 end
  
  local newGreen = green * factor
  if newGreen > 1 then newGreen = 1 end
  
  return newRed, newGreen, newBlue

end

-- ========== GFX TOOLS ==========

function LibEKL.tools.gfx.rotate(frame, angle, scale)

  local midx = frame:GetHeight() / 2
  local midy = frame:GetWidth() / 2
  local m = Libs.Transform2:new()
  
  m:Translate(midx,midy)
  m:Rotate(angle)
  m:Translate(-midx,-midy)
  if scale then m:Scale(scale, scale) end
  
  return m
  
end

--[[
   hex_to_number
    Description:
        Converts a hexadecimal string in the format 'h[hex_digits]' to a number
    Parameters:
        hex_str (string): The hexadecimal string to convert
    Returns:
        number: The converted number
    Notes:
        - The function expects the input to start with 'h' followed by one or more hex digits
        - Returns nil if the input format is invalid
]]
function LibEKL.tools.hex2number(hex_str)
    if not hex_str or type(hex_str) ~= "string" then
        return nil
    end

    -- Check if string matches the expected format
    if not hex_str:match("^h[xX]?%x+$") then
        return nil
    end

    -- Remove the 'h' prefix
    local hex_digits = hex_str:sub(2)

    -- Remove optional "0x" or "0X" prefix if present after 'h'
    hex_digits = hex_digits:gsub("^[xX]", "")

    return tonumber(hex_digits, 16)
end

function LibEKL.tools.updateSettings(defaultSettings, thisSettings)

    if type(defaultSettings) ~= 'table' or type(thisSettings) ~= 'table' then
        return thisSettings
    end

    for key, value in pairs(defaultSettings) do
        if thisSettings[key] == nil then
            thisSettings[key] = value
        elseif type(value) == 'table' and type(thisSettings[key]) == 'table' then
            LibEKL.tools.updateSettings(value, thisSettings[key])
        end
    end

    return thisSettings
	
end

function LibEKL.tools.isNaN(x)
	return x ~= x
end