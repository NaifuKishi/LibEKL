local addonInfo, privateVars = ...

---------- init namespace ---------

if not LibEKL then LibEKL = {} end
if not LibEKL.Tools then LibEKL.Tools = {} end

LibEKL.Tools.Lang = {}

---------- init local variables ---------

local inspectSystemLanguage = Inspect.System.Language

local stringLower = string.lower

-- Language constants
local GERMAN_LANGUAGE = 'German'
local FRENCH_LANGUAGE = 'French'
local RUSSIAN_LANGUAGE = 'Russian'
local DEFAULT_LANGUAGE = 'EN'

local GERMAN_SHORT = 'DE'
local FRENCH_SHORT = 'FR'
local RUSSIAN_SHORT = 'RU'

-- ========== LANGUAGE HANDLING ========== --

-- Gets the current language.
-- @return The current language.
function LibEKL.Tools.Lang.GetLanguage()
    -- Check if LibEKLSetup is nil or if the language is not set
    if LibEKLSetup == nil then
        return inspectSystemLanguage()
    elseif LibEKLSetup.language == nil then
        return inspectSystemLanguage()
    else
        -- Return the language set in LibEKLSetup
        return LibEKLSetup.language
    end
end

-- Gets the short form of a language.
-- @param language The language to get the short form for.
-- @return The short form of the language.
local function getLanguageShort(language)
    -- Determine the short form of the language
    if language == GERMAN_LANGUAGE then
        return GERMAN_SHORT
    elseif language == FRENCH_LANGUAGE then
        return FRENCH_SHORT
    elseif language == RUSSIAN_LANGUAGE then
        return RUSSIAN_SHORT
    else
        return DEFAULT_LANGUAGE
    end
end

-- Gets the short form of the current language.
-- @return The short form of the current language.
function LibEKL.Tools.Lang.GetLanguageShort()
    -- Get the short form of the current language
    return getLanguageShort(LibEKL.Tools.Lang.GetLanguage())
end

-- Sets the current language.
-- @param language The language to set.
function LibEKL.Tools.Lang.SetLanguage(language)
    -- Initialize LibEKLSetup if it is nil
    if LibEKLSetup == nil then LibEKLSetup = {} end
    -- Set the language in LibEKLSetup
    LibEKLSetup.language = language
    -- Override the inspectSystemLanguage function to return the set language
    inspectSystemLanguage = function() return LibEKLSetup.language end
end

-- Resets the current language to the system language.
function LibEKL.Tools.Lang.ResetLanguage()
    -- Initialize LibEKLSetup if it is nil
    if LibEKLSetup == nil then LibEKLSetup = {} end
    -- Reset the language in LibEKLSetup to nil
    LibEKLSetup.language = nil
end