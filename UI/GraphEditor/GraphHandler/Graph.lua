local Graph = {}
Graph.__index = Graph

local Destructor = shared.require("Destructor")
local EventHolder = shared.require("EventHolder")
local GraphLine = shared.require("GraphLine")
local GraphNode = shared.require("GraphNode")
local GraphAnchor = shared.require("GraphAnchor")
local Configuration = shared.require("Configuration")
local Network = shared.require("Network")
local GraphUtils = shared.require("GraphUtils")
local OriginData = shared.require("OriginData")

function Graph:Destroy()
	for i,node in pairs(self.nodes) do
		node:Destroy()
		self.nodes[i] = nil
	end
	for i,lines in pairs(self.lines) do
		lines:Destroy()
		self.lines[i] = nil
	end
end

function Graph:AddNodeAtMousep()
	local parent = self.metaData.Parent
	local widget = self.metaData.Widget
	
	local mousep = widget:GetRelativeMousePosition()-parent.AbsolutePosition
	local absSize = parent.AbsoluteSize
	local scalePos = mousep/absSize
	local values = GraphUtils.positionToValues(UDim2.fromScale(scalePos.X,scalePos.Y),parent)

	Network:Execute("AddKeyFrameWithOffset",self.metaData,self.sequence,values.X,values.Y)
end

function Graph:AddNode(Id,nodeValues)
	local Widget = self.metaData.Widget
	local Parent = self.metaData.Parent
	local Color = self.metaData.Color
	
	local Pos = GraphUtils.valuesToPos(nodeValues,Parent)
	local node = GraphNode.new(Widget,Parent,Color,Pos,Id)
	
	node.Clicked:Connect(function()
		self.EventHolder:Fire("NodeClicked",node)
	end)

	node.RightClicked:Connect(function()
		self.EventHolder:Fire("NodeClicked",node)
	end)
	
	node.Moved:Connect(function(pos,moveDelta)
		self.EventHolder:Fire("NodeMoved",node,moveDelta)
	end)
	
	node.PositionChanged:Connect(function()
		self.EventHolder:Fire("NodePositionChanged")
	end)

	node.Reset:Connect(function()
		self.EventHolder:Fire("ResetSelected")
	end)
	
	node.AttemptDelete:Connect(function()
		self.EventHolder:Fire("DeleteSelected")
	end)
	
	return node
end

function Graph:UpdateLines()
	for i,line in pairs(self.lines) do
		line:Destroy()
		self.lines[i] = nil
	end
	
	local Color = self.metaData.Color
	for i = 1,#self.nodes do
		local node = self.nodes[i]
		local nextNode = self.nodes[i+1] if not nextNode then continue end

		local Line = GraphLine.new(node,nextNode,Color)
		table.insert(self.lines,Line)
	end
end

function Graph:UpdateNodes()
	local axis = self.metaData.Axis
	local sequence = self.sequence
	
	local newValues = GraphUtils.sequenceToValues(sequence,axis)
	local curNodes = self.nodes
	
	local idReferences = {}
	for _,node in pairs(curNodes) do
		idReferences[node.Id] = node
	end
	
	-- create missing
	for id, nodeValues in pairs(newValues) do
		local existing = idReferences[id]
		if not existing then
			local node = self:AddNode(id,nodeValues)
			table.insert(self.nodes,node)
		else -- or update existing
			local Parent = self.metaData.Parent
			local Color = self.metaData.Color
			local Pos = GraphUtils.valuesToPos(nodeValues,Parent)
			
			existing:SetPosition(Pos)
			existing:SetColor(Color)
		end
	end
	
	-- get superfluous
	local superfluous = {}
	for id, node in pairs(idReferences) do
		local existing = newValues[id]
		if not existing then
			table.insert(superfluous,node)
		end
	end
	
	-- remove superfluous
	for _,node in pairs(superfluous) do
		local i = table.find(self.nodes,node) if not i then continue end
		table.remove(self.nodes,i)
		node:Destroy()
	end
	
	-- sort by x position
	table.sort(self.nodes,function(a,b)
		local aPos, bPos = a:GetPosition(), b:GetPosition()
		return aPos.X.Scale > bPos.X.Scale
	end)
end

function Graph:Update()
	local updateLines = #self.nodes < 1 and true or #self.sequence.KeyFrames ~= #self.nodes
	
	self:UpdateNodes()
	
	if updateLines then
		self:UpdateLines()
	end
end

function Graph:SetMetaData(newMetaData)
	self.metaData = newMetaData
end

function Graph:GetNodes()
	return self.nodes
end

function Graph.new(sequence,metaData)
	local self = setmetatable({},Graph)
	
	self.EventHolder = EventHolder.new(self,{"NodeClicked","DeleteSelected","ResetSelected","NodeMoved","NodePositionChanged"})
	
	self.sequence = sequence
	self.metaData = metaData
	
	self.nodes = {}
	self.lines = {}
	
	self:Update()
	
	return self
end

return Graph