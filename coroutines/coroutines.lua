local addonInfo, privateVars = ...

---------- init namespace ---------

if not LibEKL then LibEKL = {} end
if not LibEKL.coroutines then LibEKL.coroutines = {} end

local internalFunc   = privateVars.internalFunc

local inspectAddonCurrent	= Inspect.Addon.Current
local inspectTimeReal		= Inspect.Time.Real

---------- init local variables ---------

local _coRoutines = {}

---------- library public function block ---------

function LibEKL.coroutines.add ( info ) table.insert(_coRoutines, info ) end

---------- addon internalFunc function block ---------

function internalFunc.coroutinesProcess ()

	local debugId  
    if nkDebug then debugId = nkDebug.traceStart (inspectAddonCurrent(), "LibEKL internalFunc.coroutinesProcess") end

	if #_coRoutines == 0 then return end
	
	for idx = 1, #_coRoutines, 1 do
		if _coRoutines[idx].active == true then
		
			local go = true
			if _coRoutines[idx].delay ~= nil then
				
				if _coRoutines[idx].timeStamp == nil then _coRoutines[idx].timeStamp = inspectTimeReal() end
				
				if LibEKL.Tools.Math.Round((inspectTimeReal() - _coRoutines[idx].timeStamp), 1) < _coRoutines[idx].delay then 
					go = false
				else
					_coRoutines[idx].delay = nil						
				end					
			end			
		
			if go == true then
				local status, value = coroutine.resume(_coRoutines[idx].func, _coRoutines[idx].para1, _coRoutines[idx].para2)
				
				if status == false then
					if type(value) == 'function' then
						LibEKL.Tools.Error.Display ("LibEKL", 'error in coroutine within supplied function', 1)
					else
						LibEKL.Tools.Error.Display ("LibEKL", 'error in coroutine: ' .. value, 1)
					end 
					_coRoutines[idx].active = false
				elseif value == nil or value >= _coRoutines[idx].counter or status == false then
					_coRoutines[idx].active = false
					if _coRoutines[idx].callBack ~= nil then _coRoutines[idx].callBack() end 
				end
			end
		end
	end

	if nkDebug then nkDebug.traceEnd (inspectAddonCurrent(), "LibEKL internalFunc.coroutinesProcess", debugId) end	

end