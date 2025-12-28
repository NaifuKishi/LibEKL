local addonInfo, privateVars = ...

---------- init namespace ---------

if not LibEKL then LibEKL = {} end
if not LibEKL.Tools then LibEKL.Tools = {} end

LibEKL.Tools.Color = {}

---------- init local variables ---------

local mathFloor   = math.floor
local stringLen   = string.len
local stringFormat = string.format

-- ========== COLOR TOOLS ==========

-- Maximum value for color components.
local MAX_COLOR_VALUE = 1.0

-- Multiplier for hue adjustment.
local HUE_MULTIPLIER = 6.0

-- Converts HSV (Hue, Saturation, Value) color values to RGB (Red, Green, Blue).
-- @param hue The hue component of the color.
-- @param saturation The saturation component of the color.
-- @param value The value component of the color.
-- @return The red, green, and blue components of the color.
function LibEKL.Tools.Color.HSV2RGB(hue, saturation, value)
    local i, f, w, q, t, adjustedHue
    local red, green, blue

    -- Handle grayscale case
    if saturation == 0.0 then
        red, green, blue = value, value, value
    else
        -- Adjust hue to be within [0, 1)
        adjustedHue = hue
        if adjustedHue == MAX_COLOR_VALUE then adjustedHue = 0.0 end
        adjustedHue = adjustedHue * HUE_MULTIPLIER

        -- Calculate intermediate values
        i = mathFloor(adjustedHue)
        f = adjustedHue - i
        w = value * (MAX_COLOR_VALUE - saturation)
        q = value * (MAX_COLOR_VALUE - (saturation * f))
        t = value * (MAX_COLOR_VALUE - (saturation * (MAX_COLOR_VALUE - f)))

        -- Determine RGB values based on hue sector
        if i == 0 then
            red, green, blue = value, t, w
        elseif i == 1 then
            red, green, blue = q, value, w
        elseif i == 2 then
            red, green, blue = w, value, t
        elseif i == 3 then
            red, green, blue = w, q, value
        elseif i == 4 then
            red, green, blue = t, w, value
        elseif i == 5 then
            red, green, blue = value, w, q
        end
    end

    return red, green, blue
end

-- Formats a hexadecimal value to ensure it has two digits.
-- @param hexValue The hexadecimal value to format.
-- @return The formatted hexadecimal value.
local function formatHexValue(hexValue)
    if stringLen(hexValue) == 1 then
        return '0' .. hexValue
    else
        return hexValue
    end
end

-- Converts RGB (Red, Green, Blue) color values to a hexadecimal string.
-- @param red The red component of the color.
-- @param green The green component of the color.
-- @param blue The blue component of the color.
-- @return The hexadecimal string representation of the color.
function LibEKL.Tools.Color.RGBToHex(red, green, blue)
    local redHex = stringFormat("%X", red)
    local greenHex = stringFormat("%X", green)
    local blueHex = stringFormat("%X", blue)

    local hexValue = ''

    if red == 0 then
        hexValue = '00'
    else
        hexValue = formatHexValue(redHex)
    end

    if green == 0 then
        hexValue = hexValue .. '00'
    else
        hexValue = hexValue .. formatHexValue(greenHex)
    end

    if blue == 0 then
        hexValue = hexValue .. '00'
    else
        hexValue = hexValue .. formatHexValue(blueHex)
    end

    return hexValue
end

-- Adjusts the RGB (Red, Green, Blue) color values by a given factor.
-- @param red The red component of the color.
-- @param green The green component of the color.
-- @param blue The blue component of the color.
-- @param factor The factor to adjust the color by.
-- @return The adjusted red, green, and blue components of the color.
function LibEKL.Tools.Color.Adjust(red, green, blue, factor)
    local adjustedRed = red * factor
    if adjustedRed > MAX_COLOR_VALUE then adjustedRed = MAX_COLOR_VALUE end

    local adjustedBlue = blue * factor
    if adjustedBlue > MAX_COLOR_VALUE then adjustedBlue = MAX_COLOR_VALUE end

    local adjustedGreen = green * factor
    if adjustedGreen > MAX_COLOR_VALUE then adjustedGreen = MAX_COLOR_VALUE end

    return adjustedRed, adjustedGreen, adjustedBlue
end