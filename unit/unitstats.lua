local addonInfo, privateVars = ...

---------- init namespace ---------

if not LibEKL then LibEKL = {} end
if not LibEKL.Stat then LibEKL.Stat = {} end

local lang        = privateVars.langTexts
local data        = privateVars.data

local inspectUnitDetail	= Inspect.Unit.Detail

local lastFocus

local function checkFocus()

	local details = inspectUnitDetail("player")

	if details.focus == lastFocus then return end
	lastFocus = details.focus

	LibEKL.eventHandlers["LibEKL.Stat"]["Focus"](details.focus)		

end

local function cooldownBegin(self, cooldowns) checkFocus() end

local function regularUpdateFocus(self) 

	if lastFocus ~= 100 then checkFocus() end

end

function LibEKL.Stat.Init()

	if LibEKL.Events.CheckEvents ("LibEKL.Stat", true) == false then return nil end

end

function LibEKL.Stat.Subscribe (stat)

	if stat == "focus" then
		LibEKL.Events.AddInsecure(regularUpdateFocus, 10)
		LibEKL.eventHandlers["LibEKL.Stat"]["Focus"], LibEKL.Events["LibEKL.Stat"]["Focus"] = Utility.Event.Create(addonInfo.identifier, "LibEKL.Stat.Focus")
		Command.Event.Attach(Event.Ability.New.Cooldown.Begin, cooldownBegin, "LibEKL.Stat.Ability.New.Cooldown.Begin")
	end

end

--LibEKL.Events.AddPeriodic(func, period, tries)



