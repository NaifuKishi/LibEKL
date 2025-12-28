local addonInfo, privateVars = ...

---------- init namespace ---------

if not LibEKL then LibEKL = {} end
if not LibEKL.Coroutines then LibEKL.Coroutines = {} end

local internalFunc = privateVars.internalFunc

local inspectAddonCurrent 	= Inspect.Addon.Current
local inspectTimeReal 		= Inspect.Time.Real

---------- init local variables ---------

local _coRoutines = {}

---------- library public function block ---------

-- Adds a coroutine to the list of coroutines to be processed.
-- @param info The coroutine information.
function LibEKL.Coroutines.Add(info) table.insert(_coRoutines, info) end

---------- addon internalFunc function block ---------

-- Processes the coroutines.
function internalFunc.CoroutinesProcess()

    local debugId
    if nkDebug then debugId = nkDebug.traceStart(inspectAddonCurrent(), "LibEKL internalFunc.CoroutinesProcess") end

    if #_coRoutines == 0 then return end

    local currentTime = inspectTimeReal()
    local idx = 1
    while idx <= #_coRoutines do
        local coroutineInfo = _coRoutines[idx]

        if coroutineInfo.active then
            local shouldExecute = true

            if coroutineInfo.delay then
                if not coroutineInfo.timeStamp then
                    coroutineInfo.timeStamp = currentTime
                end

                if (currentTime - coroutineInfo.timeStamp) < coroutineInfo.delay then
                    shouldExecute = false
                else
                    coroutineInfo.delay = nil
                end
            end

            if shouldExecute then
                local status, value = coroutine.resume(coroutineInfo.func, coroutineInfo.para1, coroutineInfo.para2)

                if not status then
                    local errorMsg = type(value) == 'function' and 'error in coroutine within supplied function' or 'error in coroutine: ' .. tostring(value)
                    LibEKL.Tools.Error.Display("LibEKL", errorMsg, 1)
                    coroutineInfo.active = false
                elseif value == nil or value >= coroutineInfo.counter then
                    coroutineInfo.active = false
                    if coroutineInfo.callBack then coroutineInfo.callBack() end
                end
            end
        end

        if not coroutineInfo.active then
            table.remove(_coRoutines, idx)
        else
            idx = idx + 1
        end
    end

    if nkDebug then nkDebug.traceEnd(inspectAddonCurrent(), "LibEKL internalFunc.CoroutinesProcess", debugId) end

end