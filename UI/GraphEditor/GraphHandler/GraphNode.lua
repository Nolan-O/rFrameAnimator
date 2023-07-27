local GraphNode = {}
GraphNode.__index = GraphNode

local RunService = game:GetService("RunService")

local Destructor = shared.require("Destructor")
local EventHolder = shared.require("EventHolder")
local BezierCircle = shared.require("BezierCircle")
local UIUtils = shared.require("UIUtils")
local MenuContainer = shared.require("MenuContainer")
local GraphUtils = shared.require("GraphUtils")
local Configuration = shared.require("Configuration")
local InputService = shared.require("InputService")

local UITemplates = shared.UITemplates
local Globals = shared.Globals
local maxTimePosition = Globals.maxTimePosition

local DEFAULT_COLOR = Color3.fromRGB(0, 123, 255)

local clamp = math.clamp
local round = math.round

function lighten(color, amount)
	amount /= 255
	return Color3.new(color.r + amount, color.g + amount, color.b + amount)
end

function GraphNode:Destroy()
	self.EventHolder:Destroy()
	self.Destructor:Destroy()
	self.BezierCircle:Destroy()
	setmetatable(self,nil)
end

function GraphNode:SetSelected(bool)
	local color = self.Color or DEFAULT_COLOR
	local selectedColor = lighten(color, 80)
	
	self.Node.BackgroundColor3 = bool and selectedColor or color
	self.Selected = bool
end

function GraphNode:SetColor(newColor)
	self.Color = newColor
	self:SetSelected(self.Selected)
end

function GraphNode:SetPosition(Pos)
	self.Node.Position = Pos
	self.BezierCircle:Update()
end

function GraphNode:GetPosition()
	return self.Node.Position
end

function GraphNode.new(Widget,Parent,Color,Pos,Id)
	local self = setmetatable({},GraphNode)
	local Node = UITemplates.NodeTemplate:Clone()
	local EventList = {"Reset","Moved","PositionChanged","Clicked","RightClicked","AttemptDelete","ToggleBezier"}
	local Connections = {}
	
	Node.Parent = Parent
	Node.Position = Pos
	Node.ZIndex = 4
	
	self.EventHolder = EventHolder.new(self,EventList)
	self.Destructor = Destructor.new()
	self.BezierCircle = BezierCircle.new(Node,Widget)
	self.Node = Node
	self.Color = Color
	self.Id = Id
	self.Selected = false
	
	Connections[1] = Node.MouseButton1Down:Connect(function()
		self.EventHolder:Fire("Clicked")
		if InputService:IsKeyDown(Enum.KeyCode.LeftControl) then return end
		
		local con
		local startPos = Vector2.new(Node.Position.X.Scale,Node.Position.Y.Scale)*Node.Parent.AbsoluteSize
		local lastPos = Vector2.new(Node.Position.X.Scale,Node.Position.Y.Scale)
		
		con = RunService.RenderStepped:Connect(function()
			local SNAPX = Configuration.GraphEditorConfig.GridSize.X/Configuration.GraphEditorConfig.StepSize.X
			local SNAPY = 5
			
			local absPos = Node.Parent.AbsolutePosition
			local absSize = Node.Parent.AbsoluteSize
			
			local mousep = Widget:GetRelativeMousePosition() - absPos
			local yAdd = mousep.Y - startPos.Y
			
			local snapped = Vector2.new(round(mousep.X/SNAPX)*SNAPX, startPos.Y + math.round(yAdd/SNAPY)*SNAPY) 
			local scaled = snapped/absSize
			local moveDelta = scaled - lastPos
			local maxXPos = GraphUtils.valuesToPos(Vector2.new(maxTimePosition.Value,0),Parent).X.Scale
			local clamped = UDim2.fromScale(clamp(scaled.X,0,maxXPos),scaled.Y)
			
			Node.Position = clamped
			lastPos = scaled
			
			self.EventHolder:Fire("Moved",Node.Position,UDim2.fromScale(moveDelta.X,moveDelta.Y))
			self.BezierCircle:Update()
		end)

		UIUtils.CatchDrop(Widget,function()
			con:Disconnect()
			self.EventHolder:Fire("PositionChanged",Node.Position)
		end)
	end)
	
	Connections[2] = Node.MouseButton2Click:Connect(function()
		self.EventHolder:Fire("RightClicked")
		
		local callbacks = {
			["Delete Selected"] = function()
				self.EventHolder:Fire("AttemptDelete")
			end,
			["Toggle Bezier"] = function()
				self.BezierCircle:SetEnabled(not self.BezierCircle.Enabled)
				self.EventHolder:Fire("ToggleBezier")
			end,
			["Reset"] = function()
				self.EventHolder:Fire("Reset")
			end,
		}
		
		local chosenAction = MenuContainer:Show("Graph Node Menu")
		if not chosenAction then return end
		
		if callbacks[chosenAction.Text] then
			callbacks[chosenAction.Text]()
		end
	end)
	
	self.Destructor:Add(self.Node)
	self.Destructor:Add(Connections)
	
	self:SetSelected(false)
	
	return self
end

return GraphNode