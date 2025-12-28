local addonInfo, privateVars = ...

---------- init namespace ----------

if not LibEKL then LibEKL = {} end
if not LibEKL.Tools then LibEKL.Tools = {} end

LibEKL.Tools.Error = {}

---------- init local variables ----------

local stringFormat = string.format

-- ========== ERROR HANDLING ========== --

-- Error level constants.
local FATAL_ERROR_LEVEL = 1
local ERROR_LEVEL = 2
local WARNING_LEVEL = 3
local INFO_LEVEL = 4

-- Error color constants.
local FATAL_ERROR_COLOR = "#FF0000"
local ERROR_COLOR = "#FF6A00"
local WARNING_COLOR = "#FFD800"
local INFO_COLOR = "#FFFFFF"

-- Error type constants.
local FATAL_ERROR_TYPE = "FATAL ERROR"
local ERROR_TYPE = "ERROR"
local WARNING_TYPE = "WARNING"
local INFO_TYPE = "INFO"

-- Gets the color and type of an error based on its level.
-- @param level The level of the error.
-- @return The color and type of the error.
local function getErrorDetails(level)
    -- Determine the color and type of the error based on the level
    if level == FATAL_ERROR_LEVEL then
        return FATAL_ERROR_COLOR, FATAL_ERROR_TYPE
    elseif level == ERROR_LEVEL then
        return ERROR_COLOR, ERROR_TYPE
    elseif level == WARNING_LEVEL then
        return WARNING_COLOR, WARNING_TYPE
    else
        return INFO_COLOR, INFO_TYPE
    end
end

-- Displays an error message in the console.
-- @param addon The addon that generated the error.
-- @param message The error message.
-- @param level The level of the error.
function LibEKL.Tools.Error.Display(addon, message, level)

    -- Get the color and type of the error
    local color, errorType = getErrorDetails(level)

    -- Display the error message in the console
    Command.Console.Display("general", true, stringFormat('<font color="%s">%s in %s: %s</font>', color, errorType, addon, message), true)

end