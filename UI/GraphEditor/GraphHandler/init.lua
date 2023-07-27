local GraphHandler = {}
GraphHandler.__index = GraphHandler

local Graph = shared.require("Graph")
local EventHolder = shared.require("EventHolder")
local Configuration = shared.require("Configuration")
local InputService = shared.require("InputService")
local MenuContainer = shared.require("MenuContainer")
local Network = shared.require("Network")
local GraphUtils = shared.require("GraphUtils")
local MassSelecter = shared.require("MassSelecter")
local UIUtils = shared.require("UIUtils")
local SavePointService = shared.require("SavePointService")

local AxisColors = Configuration.GraphEditorConfig.AxisColors

local EasingStyleWidget = shared.EasingStyleWidget
local Background = EasingStyleWidget.GraphEditor.Background
local Content = Background.Content
local ContentInputCatcher = Background.ContentInputCatcher

function GraphHandler:GetMetaData()
	return {
		Axis = self.Axis,
		DisplayType = self.DisplayType,
		Color = AxisColors[self.Axis],
		Widget = EasingStyleWidget,
		Parent = Content,
	}
end

function GraphHandler:Clear()
	self:DeselectAll()
	for i,graphObj in pairs(self.Graphs) do
		graphObj:Destroy()
		self.Graphs[i] = nil
	end
end

function GraphHandler:DeselectAll()
	for i,node in pairs(self.SelectedNodes) do
		node:SetSelected(false)
		self.SelectedNodes[i] = nil
	end
end

function GraphHandler:DeleteSelected()
	local keyFramesToDelete = {}

	for i,node in pairs(self.SelectedNodes) do
		table.insert(keyFramesToDelete,node.Id)
		self.SelectedNodes[i] = nil
	end

	Network:Execute("DeleteKeyFramesById",keyFramesToDelete)
end

function GraphHandler:MassSelect()
	local selector = MassSelecter.new(EasingStyleWidget,Content)
	
	selector.Updated:Connect(function()
		self:DeselectAll()
		for _,graphObj in pairs(self.Graphs) do
			for _,nodeObj in pairs(graphObj:GetNodes()) do
				if selector:IsOverlapping(nodeObj.Node) then
					nodeObj:SetSelected(true)
					table.insert(self.SelectedNodes,nodeObj)
				end
			end
		end
	end)
	
	UIUtils.CatchDrop(EasingStyleWidget,function()
		selector:Destroy()
	end)
end

function GraphHandler:ResetSelected()
	local DisplayType = self.DisplayType
	local Axis = self.Axis

	for _,node in pairs(self.SelectedNodes) do
		Network:Execute("SetAxisCFrame",node.Id,0,DisplayType,Axis)
	end

	self:UpdateAll()
end

function GraphHandler:AddNodeAtMousep()
	local total = 0
	for i,v in pairs(self.Graphs) do total += 1 end
	
	if total ~= 1 then return end
	local _,graphObj = next(self.Graphs)
	
	graphObj:AddNodeAtMousep()
end

function GraphHandler:UpdateAll()
	for _,graphObj in pairs(self.Graphs) do
		graphObj:Update()
	end
	self:DeselectAll()
end

function GraphHandler:CreateGraph(Sequence)
	local key = Sequence.Motor
	local exKey, exGraph = next(self.Graphs)
	
	if exKey then -- 1 graph only for the time being
		exGraph:Destroy()
		self.Graphs[exKey] = nil
	end
	
	local graphObj = Graph.new(Sequence,self:GetMetaData())
	
	graphObj.NodeClicked:Connect(function(node)
		local i = table.find(self.SelectedNodes,node)
		if InputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			if not i then
				table.insert(self.SelectedNodes,node)
			else
				table.remove(self.SelectedNodes,i)
			end
		else
			if not i then
				self:DeselectAll()
				table.insert(self.SelectedNodes,node)
			end
		end
		node:SetSelected(table.find(self.SelectedNodes,node) ~= nil)
	end)
	
	graphObj.NodeMoved:Connect(function(node,moveDelta)
		if table.find(self.SelectedNodes,node) == nil then return end
		for _,selectedNode in pairs(self.SelectedNodes) do
			if selectedNode == node then continue end
			selectedNode:SetPosition(selectedNode:GetPosition()+moveDelta)
		end
	end)
	
	graphObj.NodePositionChanged:Connect(function()
		Network:Execute("SetWaypoint")
		for _,selectedNode in pairs(self.SelectedNodes) do
			local Pos = selectedNode:GetPosition()
			local Id = selectedNode.Id
			
			local newValues = GraphUtils.positionToValues(Pos,self.Parent)
			local newTimePos = math.round(newValues.X)

			local newOffset = newValues.Y
			local DisplayType = self.DisplayType
			local Axis = self.Axis

			Network:Execute("SetAxisCFrame",Id,newOffset,DisplayType,Axis)
			Network:Execute("ChangeKeyFrameTimePos",Id,newTimePos)
		end
		Network:Execute("SetWaypoint")
	end)
	
	graphObj.DeleteSelected:Connect(function(node)
		self:DeleteSelected()
	end)
	
	graphObj.ResetSelected:Connect(function(node)
		self:ResetSelected()
	end)
	
	self.Graphs[key] = graphObj
	EasingStyleWidget.Enabled = true
end

function GraphHandler:RemoveGraph(Sequence)
	local key = Sequence.Motor
	local graphObj = self.Graphs[key]
	if graphObj then
		graphObj:Destroy()
		self.Graphs[key] = nil
	end
	self:DeselectAll()
end

function GraphHandler:SetAxis(newAxis)
	if newAxis == self.Axis then return end
	self.Axis = newAxis
	
	for _,graphObj in pairs(self.Graphs) do
		graphObj:SetMetaData(self:GetMetaData())
	end
	
	self:UpdateAll()
	self.EventHolder:Fire("AxisChanged",newAxis)
end

function GraphHandler:SetDisplayType(newDisplayType)
	-- TODO
	
	self.EventHolder:Fire("DisplayTypeChanged",newDisplayType)
end

function Init()
	local self = setmetatable({},GraphHandler)
	
	self.Graphs = {}
	self.SelectedNodes = {}
	self.EventHolder = EventHolder.new(self,{"AxisChanged","DisplayTypeChanged"})
	
	self.Axis = "X"
	self.DisplayType = "Position"
	self.Widget = EasingStyleWidget
	self.Parent = Content
	
	InputService:AddInputSource(ContentInputCatcher)

	InputService:BindToInput({ContentInputCatcher},Enum.UserInputType.MouseButton1,Enum.UserInputState.Begin,function()
		self:DeselectAll()
		
		if InputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			self:MassSelect()
		end
	end)

	InputService:BindToInput({ContentInputCatcher},Enum.KeyCode.R,Enum.UserInputState.Begin,function()
		if not InputService:IsKeyDown(Enum.KeyCode.LeftControl) then return end
		self:ResetSelected()
	end)

	InputService:BindToInput({ContentInputCatcher},Enum.UserInputType.MouseButton2,Enum.UserInputState.Begin,function()
		local callbacks = {
			["Add Node"] = function()
				self:AddNodeAtMousep()
			end,
			["Delete Selected"] = function()
				self:DeleteSelected()
			end,
		}

		local chosenAction = MenuContainer:Show("Content Menu") or {}
		if callbacks[chosenAction.Text] then
			callbacks[chosenAction.Text]()
		end
	end)

	InputService:BindToInput({ContentInputCatcher},Enum.KeyCode.Delete,Enum.UserInputState.Begin,function()
		self:DeleteSelected()
	end)

	InputService:BindToInput({ContentInputCatcher},Enum.KeyCode.Space,Enum.UserInputState.Begin,function()
		Network:Execute("PlayAnimation")
	end)

	InputService:BindToInput({ContentInputCatcher},Enum.KeyCode.G,Enum.UserInputState.Begin,function()
		if not InputService:IsKeyDown(Enum.KeyCode.LeftControl) then return end
		self:AddNodeAtMousep()
	end)
	
	InputService:BindToInput({ContentInputCatcher},Enum.KeyCode.Y,Enum.UserInputState.Begin,function()
		if not InputService:IsKeyDown(Enum.KeyCode.LeftControl) then return end
		SavePointService:Undo()
	end)

	InputService:BindToInput({ContentInputCatcher},Enum.KeyCode.Z,Enum.UserInputState.Begin,function()
		if not InputService:IsKeyDown(Enum.KeyCode.LeftControl) then return end
		SavePointService:Redo()
	end)
	
	return self
end

return Init()