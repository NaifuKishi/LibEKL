local addonInfo, privateVars = ...

---------- init namespace ----------

if not LibEKL then LibEKL = {} end
if not LibEKL.Tools then LibEKL.Tools = {} end

LibEKL.Tools.Math = {}

---------- init local variables ----------

local mathFloor = math.floor

-- Hexadecimal prefix and base constants.
local HEX_PREFIX = "h"
local HEX_BASE = 16

-- ========== MATH FUNCTIONS ========== --

-- Rounds a number to a specified number of decimal places.
-- @param num The number to round.
-- @param idp The number of decimal places to round to.
-- @return The rounded number.
function LibEKL.Tools.Math.Round(num, idp)

    -- Check if the input number is nil
    if num == nil then return nil end

    -- Calculate the multiplier based on the number of decimal places
    local multiplier = 10^(idp or 0)

    -- Round the number to the specified number of decimal places
    return mathFloor(tonumber(num) * multiplier + 0.5) / multiplier

end

-- Checks if a string is a valid hexadecimal string.
-- @param hex_str The string to check.
-- @return true if the string is a valid hexadecimal string, false otherwise.
local function isValidHexString(hex_str)
    return hex_str and type(hex_str) == "string" and hex_str:match("^" .. HEX_PREFIX .. "[xX]?%x+$")
end

-- Extracts the hexadecimal digits from a hexadecimal string.
-- @param hex_str The hexadecimal string.
-- @return The hexadecimal digits.
local function extractHexDigits(hex_str)
    local hexDigits = hex_str:sub(2)
    return hexDigits:gsub("^[xX]", "")
end

-- Converts a hexadecimal string to a number.
-- @param hex_str The hexadecimal string to convert.
-- @return The number represented by the hexadecimal string.
function LibEKL.Tools.Math.Hex2number(hex_str)
    -- Check if the input is a valid hexadecimal string
    if not isValidHexString(hex_str) then
        return nil
    end

    -- Extract the hexadecimal digits from the string
    local hexDigits = extractHexDigits(hex_str)

    -- Convert the hexadecimal digits to a number
    return tonumber(hexDigits, HEX_BASE)
end

-- Checks if a number is NaN (Not a Number).
-- @param x The number to check.
-- @return true if the number is NaN, false otherwise.
function LibEKL.Tools.Math.IsNaN(x)
    -- Check if the input is NaN (Not a Number)
    return x ~= x
end