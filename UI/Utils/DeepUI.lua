local DeepUI = {}
DeepUI.__index = DeepUI

local EventHolder = shared.require("EventHolder")
local Configuration = shared.require("Configuration")
local InputService = shared.require("InputService")

local DefaultSize = Configuration.GraphEditorConfig.DefaultSize
local AnchorPoint = Vector2.new(0,0)

function DeepUI:GetRatio()
	return self.scrollMultiplier
end

function DeepUI:ResetPosition()
	local parentAbsSize = self.UIParent.AbsoluteSize
	local absSize = self.UI.AbsoluteSize
	
	local pos = parentAbsSize/2
	
	self.dragging = false
	self.curPos = pos
	self.startDrag = pos
	
	self.UI.Position = UDim2.fromOffset(pos.X,pos.Y)
end

local lastDimension = 1
function DeepUI:SetDimension(newDimension)
	local maxDimension = Configuration.GraphEditorConfig.MaxDimension
	local minDimension = Configuration.GraphEditorConfig.MinDimension
	
	local gridSize = Configuration.GraphEditorConfig.DefaultGridSize
	local deltaDimension = math.abs(lastDimension - newDimension)
	local uiOffset = deltaDimension * gridSize
	
	--self.UI.Position += UDim2.fromOffset(uiOffset.X,uiOffset.Y)
	
	self.dimension = math.clamp(newDimension,minDimension,maxDimension)
	lastDimension = self.dimension
	
	self.EventHolder:Fire("DimensionChanged",self.dimension)
end

function DeepUI.new(UI,InputCatcher)
	local self = setmetatable({},DeepUI)
	
	self.UI = UI
	self.UIParent = UI.Parent
	self.EventHolder = EventHolder.new(self,{"PositionChanged","DimensionChanged"})
	
	self.curPos = Vector2.new()
	self.startDrag = Vector2.new()
	self.dimension = 1
	
	self.dragging = false
	
	UI.AnchorPoint = AnchorPoint
	UI.Size = UDim2.fromOffset(DefaultSize.X,DefaultSize.Y)
	
	InputCatcher.MouseMoved:Connect(function(x,y)
		if not self.dragging then return end
		
		local mousep = Vector2.new(x,y)
		local difference = (self.startDrag - mousep)
		
		UI.Position = UDim2.fromOffset(self.curPos.X - difference.X,self.curPos.Y - difference.Y)
		self.EventHolder:Fire("PositionChanged",UI.Position)
	end)

	InputCatcher.MouseButton1Down:Connect(function(x,y)
		if InputService:IsKeyDown(Enum.KeyCode.LeftControl) then return end
		self.startDrag = Vector2.new(x,y)
		self.curPos = Vector2.new(UI.Position.X.Offset,UI.Position.Y.Offset)
		self.dragging = true
	end)
	
	InputCatcher.MouseButton1Up:Connect(function(x,y)
		self.dragging = false
	end)

	InputCatcher.MouseLeave:Connect(function()
		self.dragging = false
	end)
	
	InputCatcher.MouseWheelForward:Connect(function()
		local stepSize = Configuration.GraphEditorConfig.DimensionStep
		self:SetDimension(self.dimension + stepSize)
	end)
	
	InputCatcher.MouseWheelBackward:Connect(function()
		local stepSize = Configuration.GraphEditorConfig.DimensionStep
		self:SetDimension(self.dimension - stepSize)
	end)
	
	self:ResetPosition()
	
	return self
end

return DeepUI