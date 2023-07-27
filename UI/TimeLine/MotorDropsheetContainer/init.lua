local MotorDropsheetContainer = {}
local SheetsPositions = {}
local Sheets = {}
local tempCons = {}

local TimeLineGrid = shared.require("TimeLineGrid")
local Network = shared.require("Network")
local Sheet = shared.require("Sheet")

local Widget = nil
local Rig = nil
local curHighlighted = nil

function newSheet(Parent,layers,inst)
	local SheetObj = Sheet.new(Widget,inst,Parent,layers)
	
	SheetsPositions[inst.Name] = SheetObj.YPosition
	table.insert(Sheets,SheetObj)
end

function MotorDropsheetContainer.Clear()
	local MotorDropSheet = Widget.TimeLine.MotorDropSheet
	
	for i,v in pairs(SheetsPositions) do
		SheetsPositions[i] = nil
	end
	
	for i,SheetObj in pairs(Sheets) do
		SheetObj:Destroy()
		Sheets[i] = nil
	end
end

function MotorDropsheetContainer.GetSheetAtYPos(yPos)
	local found
	for _,sheetObj in pairs(Sheets) do
		local frame = sheetObj.Frame
		local absPos, absSize = frame.AbsolutePosition,frame.AbsoluteSize
		local padding = 3 -- too lazy to get the refference
		
		if math.abs(absPos.Y - yPos) < (absSize.Y/2 + padding) then
			found = sheetObj
			break
		end
	end
	return found
end

function MotorDropsheetContainer.GetYPosForKeyFrame(MotorName)
	if SheetsPositions[MotorName] then
		return SheetsPositions[MotorName]
	end
end

function MotorDropsheetContainer.Search(toSearch,layers)
	local MotorDropSheet = Widget.TimeLine.MotorDropSheet
	
	for _,inst in pairs(toSearch:GetChildren()) do
		if inst:IsA("Motor6D") and inst.Part0 ~= nil then
			newSheet(MotorDropSheet,layers,inst)
		end
		if #inst:GetChildren() > 0 then
			MotorDropsheetContainer.Search(inst,layers+1)
		end
	end
end

function MotorDropsheetContainer.LoadFramesForRig()
	local MotorDropSheet = Widget.TimeLine.MotorDropSheet
	
	MotorDropsheetContainer.Clear()
	newSheet(MotorDropSheet,0,Rig)
	MotorDropsheetContainer.Search(Rig,0)
	TimeLineGrid.Update(Widget)
end

function MotorDropsheetContainer.Update(TimeLineWidget,SelectedRig)
	if not SelectedRig then warn("invalid Rig") return end
	
	Rig = SelectedRig
	Widget = TimeLineWidget
	MotorDropsheetContainer.LoadFramesForRig()
end

Network:Register("HighlightSheet",function(Motor)
	if curHighlighted then
		curHighlighted:SetHighlighted(false)
		curHighlighted = nil
	end
	
	if not Motor then return end
	
	for i,Sheet in pairs(Sheets) do
		if Sheet and Sheet.Name == Motor.Name then
			Sheet:SetHighlighted(true)
			curHighlighted = Sheet
		end
	end
end)

return MotorDropsheetContainer