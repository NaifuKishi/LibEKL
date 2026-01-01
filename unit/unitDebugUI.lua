local addonInfo, privateVars = ...

---------- init namespace ---------

if not LibEKL then LibEKL = {} end
if not LibEKL.Unit then LibEKL.Unit = {} end

local unitData		= privateVars.unitData

local stringFind	= string.find
local stringFormat	= string.format
local stringSub		= string.sub
local stringMatch	= string.match

---------- local function block ---------

function LibEKL.Unit.buildDebugUI ()

	local context = UI.CreateContext("nkUI") 
	context:SetStrata ('dialog')

	local frame = LibEKL.UICreateFrame("nkFrame", "LibEKL.Unit.testFrame", context)
	frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 500, 0)
	frame:SetHeight(300)
	frame:SetWidth(600)
	frame:SetBackgroundColor(0,0,0,1)

	local text = LibEKL.UICreateFrame("nkText", "LibEKL.Unit.testFrame.text", frame)
	text:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, 2)
	text:SetWidth(598)
	text:SetHeight(298)
	text:SetFontColor(1,1, 1, 1)
	text:SetWordwrap(true)
	text:SetFontSize(12)

	function frame:Update()
		local thisText, thisText2 = "", ""

		local sortedKeys = LibEKL.Tools.Table.GetSortedKeys (unitData.idCache)
		
		for _, key in pairs(sortedKeys) do
			local units = unitData.idCache[key]
			thisText = stringFormat("%s%s: %s\n", thisText, key, LibEKL.Tools.Table.Serialize(units))
		end

		text:SetText(thisText)
	end

	return frame

end