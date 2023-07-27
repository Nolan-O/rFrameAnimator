local GraphAnchor = {}
GraphAnchor.__index = GraphAnchor

local UITemplates = shared.UITemplates
local Destructor = shared.require("Destructor")

local COLOR = Color3.fromRGB(0, 0, 255)

function GraphAnchor:Destroy()
	self.Destructor:Destroy()
	setmetatable(self,nil)
end

function GraphAnchor.new(Parent,Pos)
	local self = setmetatable({},GraphAnchor)
	local Node = UITemplates.NodeTemplate:Clone()
	
	self.Node = Node
	self.Destructor = Destructor.new()
	
	Node.Parent = Parent
	Node.Position = Pos
	Node.BackgroundColor3 = COLOR
	Node.ZIndex = 4
	
	self.Destructor:Add(Node)
	
	return self
end

return GraphAnchor