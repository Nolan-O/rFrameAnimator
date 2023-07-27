local GraphEditorInterface = {}

local RunService = game:GetService("RunService")

local plugin = shared.Plugin

local Templates = shared.UITemplates
local Globals = shared.Globals

local curTimePosition = Globals.curTimePosition
local maxTimePosition = Globals.maxTimePosition

local Configuration = shared.require("Configuration")
local UIUtils = shared.require("UIUtils")
local GraphEditorGrid = shared.require("GraphEditorGrid")
local GraphHandler = shared.require("GraphHandler")
local MassSelecter = shared.require("MassSelecter")
local MenuContainer = shared.require("MenuContainer")
local Network = shared.require("Network")
local DeepUI = shared.require("DeepUI")
local originData = shared.require("OriginData")
local GraphUtils = shared.require("GraphUtils")
local RigEditTools = shared.require("RigEditTools")
local InputService = shared.require("InputService")

local EasingStyleWidget = shared.EasingStyleWidget
local EasingStyleFrame = EasingStyleWidget.GraphEditor
local Background = EasingStyleFrame.Background
local Content = Background.Content
local TimeBar = Background.TimeBar
local ContentInputCatcher = Background.ContentInputCatcher
local TopBorder = Background.TopBorder
local TimeDisplay = TimeBar.TimeDisplay
local inputCatcher = EasingStyleWidget.inputCatcher
local ActionBorder = Background.ActionBorder

local Dragger = nil
local GraphDeepUI = nil

local isDragging = false
local holdingCtrl = false
local BorderSize = 26

function InitActionButtons()
	local AxisButtons = {}
	local DisplayTypeButtons = {}
	
	local buttonColor = Color3.fromRGB(31, 30, 31)
	
	local function newAxisButton(Button)
		local Axis = GraphHandler:GetMetaData().Axis
		
		Button.MouseButton1Click:Connect(function()
			GraphHandler:SetAxis(Button.Name)
		end)
		
		Button.BackgroundColor3 = Axis == Button.Name and Configuration.GraphEditorConfig.AxisColors[Axis] or buttonColor
		table.insert(AxisButtons,Button)
	end
	
	local function newDisplayTypeButton(Button)
		local DisplayType = GraphHandler:GetMetaData().DisplayType
		
		Button.MouseButton1Click:Connect(function()
			GraphHandler:SetDisplayType(Button.Name)
		end)

		Button.BackgroundColor3 = DisplayType == Button.Name and Configuration.GraphEditorConfig.DisplayTypeColor or buttonColor
		table.insert(DisplayTypeButtons,Button)
	end
	
	GraphHandler.AxisChanged:Connect(function(Axis)
		for _,button in pairs(AxisButtons) do
			button.BackgroundColor3 = Axis == button.Name and Configuration.GraphEditorConfig.AxisColors[Axis] or buttonColor 
		end
	end)
	
	GraphHandler.DisplayTypeChanged:Connect(function(DisplayType)
		for _,button in pairs(DisplayTypeButtons) do
			button.BackgroundColor3 = DisplayType == button.Name and Configuration.GraphEditorConfig.DisplayTypeColor or buttonColor
		end
	end)
	
	newAxisButton(ActionBorder:WaitForChild("X"))
	newAxisButton(ActionBorder:WaitForChild("Y"))
	newAxisButton(ActionBorder:WaitForChild("Z"))
	
	newDisplayTypeButton(ActionBorder:WaitForChild("Rotation"))
	newDisplayTypeButton(ActionBorder:WaitForChild("Position"))
end

function GraphEditorInterface.IsDragging()
	return isDragging
end

function GraphEditorInterface.UpdateGrid()
	local ratio = (GraphDeepUI and GraphDeepUI:GetRatio() or 1)
	
	GraphEditorGrid.Update(GraphHandler:GetMetaData(),ratio)
end

function GraphEditorInterface.UpdateTimeBar()
	local values = Vector2.new(curTimePosition.Value,0)
	local inUdim2 = GraphUtils.valuesToPos(values,Background)
	local xScale = inUdim2.X.Scale
	local xOffset = Content.Position.X.Offset
	
	TimeBar.Position = UDim2.new(xScale,xOffset,.5,0)
	TimeBar.TimeDisplay.Text.Text = curTimePosition.Value
end

function GraphEditorInterface.DragTimeBar()
	local con
	con = RunService.RenderStepped:Connect(function()
		local rel = EasingStyleWidget:GetRelativeMousePosition() - Content.AbsolutePosition -- TimeBar.AbsoluteSize/2
		local dez = rel/Content.AbsoluteSize
		local inUdim2 = UDim2.fromScale(dez.X,dez.Y)
		local values = GraphUtils.positionToValues(inUdim2,Content)
		
		curTimePosition.Value = math.clamp(math.round(values.X),0,maxTimePosition.Value)
	end)
	
	isDragging = true
	UIUtils.CatchDrop(EasingStyleWidget,function()
		con:Disconnect()
		isDragging = false
	end)
end

function GraphEditorInterface.Build()
	GraphDeepUI = DeepUI.new(Content,ContentInputCatcher)
	GraphDeepUI:ResetPosition()
	
	maxTimePosition.Changed:Connect(function()
		GraphEditorInterface.UpdateTimeBar()
		GraphEditorInterface.UpdateGrid()
	end)

	GraphDeepUI.PositionChanged:Connect(function()
		GraphEditorInterface.UpdateTimeBar()
		GraphEditorInterface.UpdateGrid()
	end)

	RigEditTools.LetGo:Connect(function()
		GraphHandler:UpdateAll()
	end)

	EasingStyleWidget.WindowFocused:Connect(function()
		InputService:ClearPressingKeys()
	end)

	GraphDeepUI.DimensionChanged:Connect(function(dec)
		local config = Configuration.GraphEditorConfig
		local defaultGridSize = config.DefaultGridSize
		local defaultStepSize = config.DefaultStepSize

		local snap = 1 + (dec - math.floor(dec))
		local stepDiv = math.floor(dec)

		if stepDiv <= 0 then
			stepDiv = .5
		end

		config.GridSize = defaultGridSize * snap
		config.StepSize = defaultStepSize / stepDiv

		GraphEditorInterface.UpdateTimeBar()
		GraphEditorInterface.UpdateGrid()
		GraphHandler:UpdateAll()
	end)

	TimeDisplay.MouseButton1Down:Connect(GraphEditorInterface.DragTimeBar)
	TopBorder.MouseButton1Down:Connect(GraphEditorInterface.DragTimeBar)

	curTimePosition.Changed:Connect(GraphEditorInterface.UpdateTimeBar)
	Background:GetPropertyChangedSignal("AbsoluteSize"):Connect(GraphEditorInterface.UpdateGrid)
	Background:GetPropertyChangedSignal("AbsoluteSize"):Connect(GraphEditorInterface.UpdateTimeBar)

	GraphEditorGrid.Init(EasingStyleWidget)
	GraphEditorInterface.UpdateTimeBar()

	InitActionButtons()
end

return GraphEditorInterface