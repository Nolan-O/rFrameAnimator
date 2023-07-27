local GraphLine = {}
GraphLine.__index = GraphLine

local TS = game:GetService("TweenService")

local Destructor = shared.require("Destructor")

local DEFAULT_SEGMENT_RESOLUTION = 5
local BZIER_SEGMENT_RESOLUTION = 15
local THICKNESS = 2
local SEGMENT_COLOR = Color3.fromRGB(0, 123, 255)

function lerp(a, b, t)
	return a + (b - a) * t
end

function cubicBezier(t, p0, p1, p2, p3)
	local l1 = lerp(p0, p1, t)
	local l2 = lerp(p1, p2, t)
	local l3 = lerp(p2, p3, t)
	local a = lerp(l1, l2, t)
	local b = lerp(l2, l3, t)
	local cubic = lerp(a, b, t)
	return cubic
end

function quadBezier(t, p0, p1, p2)
	local l1 = lerp(p0, p1, t)
	local l2 = lerp(p1, p2, t)
	local quad = lerp(l1, l2, t)
	return quad
end

function GetOffsetPosition(Gui)
	local ParentAbsPos = Gui.Parent.AbsolutePosition
	local absPos = Gui.AbsolutePosition
	local absSize = Gui.AbsoluteSize
	
	return absPos - ParentAbsPos + Vector2.new(absSize.X/2,absSize.Y/2)
end

function GraphLine:Destroy()
	self.Destructor:Destroy()
	setmetatable(self,nil)
	self = nil
end

function GraphLine:GetPosition(t)
	local BezierCircle1 = self.Node1.BezierCircle
	local BezierCircle2 = self.Node2.BezierCircle
	
	if BezierCircle1 and not BezierCircle1.Enabled then
		BezierCircle1 = nil
	end
	
	if BezierCircle2 and not BezierCircle2.Enabled then
		BezierCircle2 = nil
	end
	
	local bezPoints1 = BezierCircle1 and BezierCircle1:GetBezierPoints() or {}
	local bezPoints2 = BezierCircle2 and BezierCircle2:GetBezierPoints() or {}
	
	local Adornee1 = self.Node1.Node
	local Adornee2 = self.Node2.Node
	
	local Ad1Pos = GetOffsetPosition(Adornee1)
	local Ad2Pos = GetOffsetPosition(Adornee2)
	
	self.p0 = Ad1Pos
	self.p3 = Ad2Pos
	
	if BezierCircle1 and BezierCircle2 then
		self.p1 = bezPoints1.p1
		self.p2 = bezPoints2.p2
		return cubicBezier(t, self.p0, self.p1, self.p2, self.p3)
	end
	
	if BezierCircle1 or BezierCircle2 then
		local p1 = BezierCircle1 and bezPoints1.p1 or bezPoints2.p2
		return quadBezier(t, self.p0, p1, self.p3)
	end
	
	if not BezierCircle1 and not BezierCircle2 then
		return self.p0:Lerp(self.p3,t)
	end
end

function GraphLine:Update()
	local function UpdateRotation(Segment, p1, p2)
		local rot = math.round(math.atan2(p2.Y - p1.Y, p2.X - p1.X) * (180 / math.pi))
		
		if Segment.Rotation == rot then return end
		Segment.Rotation = rot
	end
	
	local function UpdatePosition(Segment, p1, p2)
		local absSize = Segment.Parent.AbsoluteSize
		local v = (p1 - p2)
		local offsetPos = p1:Lerp(p2,.5)
		
		local size = UDim2.fromOffset(v.magnitude+2,THICKNESS)
		local pos = UDim2.fromScale(offsetPos.X/absSize.X,offsetPos.Y/absSize.Y)
		
		if Segment.Size ~= size then
			Segment.Size = size
		end
		if Segment.Position ~= pos then
			Segment.Position = pos
		end
	end
	
	local last
	local totalIndex = #self.Segments
	for i = 1,#self.Segments do
		local t = (i-1)/(totalIndex-1)
		local p = self:GetPosition(t)
		local Segment = self.Segments[i]
		
		if last then 
			UpdateRotation(Segment, last, p)
			UpdatePosition(Segment, last, p)
		end
		
		last = p
	end
end

function GraphLine:SetResolution(resolution)
	local function createSegment()
		local Segment = Instance.new("Frame")
		Segment.Parent = self.Parent
		Segment.BackgroundColor3 = self.Color or SEGMENT_COLOR
		Segment.AnchorPoint = Vector2.new(0.5,0.5)
		Segment.ZIndex = 2
		Segment.BorderSizePixel = 0
		
		table.insert(self.Segments,Segment)
	end
	
	if #self.Segments ~= resolution then
		for i,segment in pairs(self.Segments) do
			segment:Destroy()
			self.Segments[i] = nil
		end
		
		for i = 1,resolution do
			createSegment()
		end
	end
	
	self:Update()
end

function GraphLine.new(Node1,Node2,Color)
	local self = setmetatable({},GraphLine)
	local Connections = {}
	local Adornee1,Adornee2 = Node1.Node,Node2.Node
	
	local BezierCircle1 = Node1.BezierCircle
	local BezierCircle2 = Node2.BezierCircle
	
	self.Node1 = Node1
	self.Node2 = Node2
	self.Parent = Adornee1.Parent
	
	self.Destructor = Destructor.new()
	self.Segments = {}
	self.Color = Color
	
	Connections[1] = Adornee1.Parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self:Update()
	end)
	
	Connections[2] = Node1.Node:GetPropertyChangedSignal("Position"):Connect(function()
		self:Update()
	end)

	Connections[3] = Node2.Node:GetPropertyChangedSignal("Position"):Connect(function()
		self:Update()
	end)
	
	Connections[4] = BezierCircle1.Updated:Connect(function()
		self:Update()
	end)
	
	Connections[5] = BezierCircle2.Updated:Connect(function()
		self:Update()
	end)
	
	Connections[6] = BezierCircle1.Toggled:Connect(function()
		local resolution = BezierCircle1.Enabled and BZIER_SEGMENT_RESOLUTION or DEFAULT_SEGMENT_RESOLUTION
		self:SetResolution(resolution)
	end)
	
	Connections[7] = BezierCircle2.Toggled:Connect(function()
		local resolution = BezierCircle2.Enabled and BZIER_SEGMENT_RESOLUTION or DEFAULT_SEGMENT_RESOLUTION
		self:SetResolution(resolution)
	end)
	
	self.Destructor:Add(Connections)
	self.Destructor:Add(self.Segments)
	
	self:SetResolution(DEFAULT_SEGMENT_RESOLUTION)
	
	return self
end

return GraphLine