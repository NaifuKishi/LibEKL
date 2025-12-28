local addonInfo, privateVars = ...

---------- init namespace ----------

if not LibEKL then LibEKL = {} end
if not LibEKL.Tools then LibEKL.Tools = {} end

LibEKL.Tools.Performance = {}

local data = privateVars.data
local internalFunc = privateVars.internalFunc

---------- init local variables ----------

local inspectSystemWatchdog = Inspect.System.Watchdog

local tableInsert = table.insert
local tableRemove = table.remove

local MIN_WATCHDOG_TIME = 0.1

-- ========== PERFORMANCE TOOLS ========== --

-- Adds a function to the performance queue.
-- @param func The function to add to the queue.
function LibEKL.Tools.Performance.AddToQueue(func)

    -- Initialize the performance queue if it is nil
    if data.perfQueue == nil then data.perfQueue = {} end

    -- Add the function to the performance queue
    tableInsert(data.perfQueue, func)
end

-- Processes the performance queue.
function internalFunc.processPerformanceQueue()

    -- Check if the performance queue is empty
    if data.perfQueue == nil or #data.perfQueue == 0 then return end

    -- Check if there is enough watchdog time to process the queue
    if inspectSystemWatchdog() < MIN_WATCHDOG_TIME then return end

    -- Process the first function in the queue
    data.perfQueue[1]()

    -- Remove the processed function from the queue
    tableRemove(data.perfQueue, 1, 1)
end