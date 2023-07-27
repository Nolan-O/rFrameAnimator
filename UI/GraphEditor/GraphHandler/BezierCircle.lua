local BezierCircle = {}
BezierCircle.__index = BezierCircle

local RunService = game:GetService("RunService")

local UITemplates = shared.UITemplates
local Destructor = shared.require("Destructor")
local EventHolder = shared.require("EventHolder")
local UIUtils = shared.require("UIUtils")

local UI_COLOR = Color3.fromRGB(211, 204, 0)

local maxRadius = 150
local minRadius = 20
local rotSnap = 3

function GetOffsetPosition(Gui)
	local ParentAbsPos = Gui.Parent.AbsolutePosition
	local absPos = Gui.AbsolutePosition
	local absSize = Gui.AbsoluteSize
	
	return absPos - ParentAbsPos + Vector2.new(absSize.X/2,absSize.Y/2)
end

function BezierCircle:Destroy()
	self.EventHolder:Destroy()
	self.Destructor:Destroy()
	setmetatable(self,nil)
end

function BezierCircle:SetEnabled(bool)
	self.Enabled = bool
	self.Node1.Visible = bool
	self.Node2.Visible = bool
	self.NodeConnection.Visible = bool
	
	self:Update()
	self.EventHolder:Fire("Toggled")
end

function BezierCircle:GetBezierPoints()
	return {
		p1 = GetOffsetPosition(self.Node1),
		p2 = GetOffsetPosition(self.Node2)
	}
end

function BezierCircle:Update()
	if not self.Enabled then return end
	
	local absSize = self.Adornee.Parent.AbsoluteSize
	local absPos = self.Adornee.Parent.AbsolutePosition
	local Pos = self.Adornee.Position
	
	local radius = self.curRadius
	local diameter = self.curRadius*2
	local Node1angle = math.rad(self.curAngle)
	local Node2angle = math.rad(self.curAngle - 180)
	
	local Node1X = math.cos(Node1angle) * radius
	local Node1Y = math.sin(Node1angle) * radius
	
	local Node2X = math.cos(Node2angle) * radius
	local Node2Y = math.sin(Node2angle) * radius
	
	self.Node1.Position = Pos + UDim2.fromOffset(Node1X,Node1Y)
	self.Node2.Position = Pos + UDim2.fromOffset(Node2X,Node2Y)
	
	self.NodeConnection.Position = Pos
	self.NodeConnection.Size = UDim2.new(0,diameter,0,1)
	self.NodeConnection.Rotation = self.curAngle
	
	self.EventHolder:Fire("Updated")
end

function BezierCircle:StartDragging(RotOffset)
	local con
	
	con = RunService.RenderStepped:Connect(function()
		local absPos = self.Adornee.Parent.AbsolutePosition
		local absSize = self.Adornee.Parent.AbsoluteSize
		
		local adorneeSize = self.Adornee.AbsoluteSize
		local adorneePos = self.Adornee.AbsolutePosition - absPos + adorneeSize/2
		
		local mousep = self.Widget:GetRelativeMousePosition() - absPos
		local angle = -math.deg(math.atan2(mousep.X - adorneePos.X, mousep.Y - adorneePos.Y) - math.pi/2) + RotOffset
		local mag = (mousep - adorneePos).Magnitude
		
		self.curAngle = math.round(angle/rotSnap)*rotSnap
		self.curRadius = math.clamp(mag,minRadius,maxRadius)
		self:Update()
	end)
	
	UIUtils.CatchDrop(self.Widget,function()
		con:Disconnect()
	end)
end

function BezierCircle.new(Adornee,Widget)
	local self = setmetatable({},BezierCircle)
	local EventList = {"Updated","Toggled"}
	local Connections = {}
	
	self.Node1 = UITemplates.NodeTemplate:Clone()
	self.Node2 = UITemplates.NodeTemplate:Clone()
	self.NodeConnection = UITemplates.NodeConnectionTemplate:Clone()
	self.Adornee = Adornee
	self.Widget = Widget
	self.curAngle = 0
	self.curRadius = 30
	self.Enabled = false
	
	self.Node1.BackgroundColor3 = UI_COLOR
	self.Node2.BackgroundColor3 = UI_COLOR
	self.NodeConnection.BackgroundColor3 = UI_COLOR
	
	self.EventHolder = EventHolder.new(self,EventList)
	
	Connections[1] = self.Node1.MouseButton1Down:Connect(function()
		self:StartDragging(0)
	end)
	
	Connections[2] = self.Node2.MouseButton1Down:Connect(function()
		self:StartDragging(180)
	end)
	
	self.Node1.Parent = Adornee.Parent
	self.Node2.Parent = Adornee.Parent
	self.Node1.Dot.Visible = true
	self.Node2.Dot.Visible = true
	self.NodeConnection.Parent = Adornee.Parent
	
	self.Destructor = Destructor.new()
	self.Destructor:Add(self.Node1)
	self.Destructor:Add(self.Node2)
	self.Destructor:Add(self.NodeConnection)
	self.Destructor:Add(Connections)
	
	self:SetEnabled(false)
	
	return self
end

return BezierCircle