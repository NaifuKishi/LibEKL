local addonInfo, privateVars = ...

---------- init namespace ---------

if not LibEKL then LibEKL = {} else return end
if not LibEKL.manager then LibEKL.ui = {} end

if not LibEKL.eventHandlers then LibEKL.eventHandlers = {} end
if not LibEKL.events then LibEKL.events = {} end
if not LibEKL.internal then LibEKL.internal = {} end -- sobald nkRadial umgebaut ist das hier komplett auf internal umbauen

privateVars.internalFunc = {}
privateVars.data = {}
privateVars.oFuncs = {}

local internalFunc  = privateVars.internalFunc
local data          = privateVars.data

