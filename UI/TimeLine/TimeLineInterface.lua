local TimeLineInterface = {}

local plugin = shared.Plugin

local UIS = game:GetService("UserInputService")

local TimeLineWidget = shared.TimeLineWidget
local Templates = shared.UITemplates
local Globals = shared.Globals
local curTimePosition = Globals.curTimePosition
local maxTimePosition = Globals.maxTimePosition
local framesPerSec = Globals.FramesPerSec

local TimeLineGrid = shared.require("TimeLineGrid")
local Network = shared.require("Network")
local MotorDropsheetContainer = shared.require("MotorDropsheetContainer")
local KeyFrameContainer = shared.require("KeyFrameContainer")
local UIUtils = shared.require("UIUtils")
local Configuration = shared.require("Configuration")
local TimeDragger = shared.require("TimeDragger")

local TIME_STAMP_INTERVAL = 150

local Dragger = nil

function CreateTimeStamps(KeyFrameEditor,timeStampAmount)
	local stampFrameTemplate = Templates.TimeStampTemplate
	
	KeyFrameEditor.KeyFrameEditorHeading:ClearAllChildren()
	
	for i = 1,timeStampAmount+1 do
		local dez = UIUtils.SnapUI((1/timeStampAmount)*(i-1))
		local stampTime = math.round(Globals.maxTimePosition.Value*dez)
		local stampFrame = stampFrameTemplate:Clone()

		stampFrame.Text = stampTime
		stampFrame.Position = UDim2.new(dez,0,.55,0)
		stampFrame.Parent = KeyFrameEditor.KeyFrameEditorHeading
	end
end

function TimeLineInterface.UpdateTimeStamps()
	local TimeLineFrame = TimeLineWidget.TimeLine
	local KeyFrameEditor = TimeLineFrame.KeyFrameEditor
	local timeStampAmount = math.round(TimeLineWidget.AbsoluteSize.X/TIME_STAMP_INTERVAL)
	local curTimeStampAmount = #KeyFrameEditor.KeyFrameEditorHeading:GetChildren()-1
	local stampFrameTemplate = Templates.TimeStampTemplate

	if timeStampAmount ~= curTimeStampAmount then
		CreateTimeStamps(KeyFrameEditor,timeStampAmount)
		TimeLineGrid.Update(TimeLineWidget)
	end
end

function TimeLineInterface.UpdateMotorDropsheet(Rig)
	MotorDropsheetContainer.Update(TimeLineWidget,Rig)
end

function TimeLineInterface.IsDragging()
	return Dragger:IsDragging()
end

function TimeLineInterface.UpdateTimeBar()
	local TimeBar = TimeLineWidget.TimeLine.KeyFrameEditor.TimeBar
	local dez = UIUtils.SnapUI(curTimePosition.Value/maxTimePosition.Value)
	
	TimeBar.Position = UDim2.new(dez,0,.5,0)
	TimeBar.TimeDisplay.Text.Text = curTimePosition.Value
end

function TimeLineInterface.Build()
	local TimeLineFrame = TimeLineWidget.TimeLine
	local KeyFrameEditor = TimeLineFrame.KeyFrameEditor
	local MotorDropSheet = TimeLineFrame.MotorDropSheet
	local MotorDropSheetHeading = TimeLineFrame.MotorDropSheetHeading
	local KeyFrameEditorHeading = KeyFrameEditor.KeyFrameEditorHeading
	local TimeLine = KeyFrameEditor.TimeLine
	local TimeBar = TimeLineFrame.KeyFrameEditor.TimeBar
	
	TimeLineInterface.UpdateTimeBar()
	Dragger = TimeDragger.new(TimeLineWidget,KeyFrameEditor,{TimeBar.TimeDisplay.MouseButton1Down,KeyFrameEditor.KeyFrameEditorHeading.MouseButton1Down})
	
	local function updateUI()
		local MotorDropsheetProp = .2
		local HeadingOffset = 26
		
		local absSize = TimeLineWidget.AbsoluteSize.Y
		local ySize = 1-HeadingOffset/absSize
		local yPos = ((absSize + HeadingOffset)/2)/absSize

		MotorDropSheet.Size = UDim2.new(MotorDropsheetProp,0,ySize,0)
		MotorDropSheet.Position = UDim2.new(MotorDropsheetProp/2,0,yPos,0) 
		TimeLine.Size = UDim2.new(1,0,ySize,0)
		TimeLine.Position = UDim2.new(.5,0,yPos,0)
	end
	
	TimeLineWidget:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		updateUI()
		TimeLineInterface.UpdateTimeStamps()
	end)
	
	MotorDropSheet:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		if TimeLine.CanvasPosition == MotorDropSheet.CanvasPosition then return end
		TimeLine.CanvasPosition = MotorDropSheet.CanvasPosition
	end)
	
	TimeLine:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		if TimeLine.CanvasPosition == MotorDropSheet.CanvasPosition then return end
		MotorDropSheet.CanvasPosition = TimeLine.CanvasPosition
	end)
	
	TimeLineInterface.UpdateTimeStamps()
	TimeLineGrid.Update(TimeLineWidget)
end

curTimePosition.Changed:Connect(function()
	TimeLineInterface.UpdateTimeBar()
end)

maxTimePosition.Changed:Connect(function()
	local TimeLineFrame = TimeLineWidget.TimeLine
	local KeyFrameEditor = TimeLineFrame.KeyFrameEditor
	
	CreateTimeStamps(KeyFrameEditor,0)
	TimeLineInterface.UpdateTimeBar()
	TimeLineInterface.UpdateTimeStamps()
	TimeLineGrid.Update(TimeLineWidget)
end)

return TimeLineInterface