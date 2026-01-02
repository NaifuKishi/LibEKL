local addonInfo, privateVars = ...

---------- init namespace ---------

if not LibEKL then LibEKL = {} end
if not LibEKL.Tools then LibEKL.Tools = {} end

local mathRandom    = math.random
local stringGSub    = string.gsub
local stringFormat  = string.format

-- Generates a UUID (Universally Unique Identifier).
-- @return A string representing a UUID.
function LibEKL.Tools.UUID()

    local function generateUuid()
        local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'

        return stringGSub(template, '[xy]', function(c)
            local v = (c == 'x') and mathRandom(0, 0xf) or mathRandom(8, 0xb)
            return stringFormat('%x', v)
        end)
    end

    return generateUuid()
end