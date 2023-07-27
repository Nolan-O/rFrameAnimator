local RigEditTools = {}
RigEditTools.__index = RigEditTools

local plugin = shared.Plugin

local StudioService = game:GetService("StudioService")

local Network = shared.require("Network")
local EventHolder = shared.require("EventHolder")

local HandleColors = {
	[Enum.NormalId.Left] = BrickColor.new("Really red").Color,
	[Enum.NormalId.Right] = BrickColor.new("Really red").Color,
	
	[Enum.NormalId.Front] = BrickColor.new("Really blue").Color,
	[Enum.NormalId.Back] = BrickColor.new("Really blue").Color,
	
	[Enum.NormalId.Top] = BrickColor.new("Lime green").Color,
	[Enum.NormalId.Bottom] = BrickColor.new("Lime green").Color,
}

function RigEditTools:CreateHandles()
	local HandlesCache = {}
	
	local function EnabledHandles(NormalIds)
		for NormalId, Handles in pairs(self.Handles) do
			Handles.Faces = table.find(NormalIds,NormalId) ~= nil and Faces.new(NormalId) or Faces.new()
		end
	end
	
	for _,displayAxis in next,Enum.NormalId:GetEnumItems() do
		local Handles = Instance.new("Handles")
		Handles.Archivable = false
		Handles.Style = "Movement"
		Handles.Color3 = HandleColors[displayAxis]
		Handles.Visible = true
		Handles.Faces = Faces.new(displayAxis)
		
		local accumulated = 0
		local lastInc = 0
		
		Handles.MouseButton1Down:Connect(function(Axis)
			self.dragging = true
			
			accumulated = 0
			lastInc = 0
			
			EnabledHandles({displayAxis})
			Network:Execute("SetWaypoint")
		end)
		
		Handles.MouseButton1Up:Connect(function()
			self.dragging = false
			
			EnabledHandles(Enum.NormalId:GetEnumItems())
			self.EventHolder:Fire("LetGo")
			Network:Execute("SetWaypoint")
		end)
		
		Handles:GetPropertyChangedSignal("Adornee"):Connect(function()
			self.dragging = false
		end)
		
		Handles.MouseDrag:Connect(function(face,distance)
			local MoveIncrement = StudioService.GridSize
			local deltaDist = distance - lastInc
			local snapDist = 0
			
			accumulated += deltaDist
			
			if math.abs(accumulated) >= MoveIncrement then
				local add = math.round(accumulated/MoveIncrement) * MoveIncrement
				
				accumulated = 0
				snapDist = add
			end
			
			local faceCFs = {
				[Enum.NormalId.Top] = CFrame.new(0,snapDist,0),
				[Enum.NormalId.Bottom] = CFrame.new(0,-snapDist,0),
				[Enum.NormalId.Left] = CFrame.new(-snapDist,0,0),
				[Enum.NormalId.Right] = CFrame.new(snapDist,0,0),
				[Enum.NormalId.Front] = CFrame.new(0,0,-snapDist),
				[Enum.NormalId.Back] = CFrame.new(0,0,snapDist),
			}
			
			lastInc = distance
			
			if math.abs(snapDist) > 0 then
				Handles.Adornee.CFrame *= faceCFs[face]
				self.EventHolder:Fire("Dragged",faceCFs[face],"Position")
			end
		end)
		
		HandlesCache[displayAxis] = Handles
	end
	
	self.Handles = HandlesCache
end

function RigEditTools:CreateArcHandles()
	local accumulated = Vector3.new()
	local prevOrientation = Vector3.new()
	local first = false

	local ArcHandles = Instance.new("ArcHandles")
	ArcHandles.Archivable = false
	ArcHandles.Visible = true

	ArcHandles.MouseButton1Down:Connect(function(Axis)
		accumulated = Vector3.new()
		prevOrientation = Vector3.new()

		local Ids = {
			[Enum.Axis.X] = Enum.NormalId.Right,
			[Enum.Axis.Y] = Enum.NormalId.Top,
			[Enum.Axis.Z] = Enum.NormalId.Back,
		}

		ArcHandles.Axes = Axes.new(Ids[Axis])

		Network:Execute("SetWaypoint")
		self.dragging = true
		first = true
	end)

	ArcHandles.MouseButton1Up:Connect(function()
		self.dragging = false

		ArcHandles.Axes = Axes.new(unpack(Enum.NormalId:GetEnumItems()))

		self.EventHolder:Fire("LetGo")
		Network:Execute("SetWaypoint")
	end)

	ArcHandles:GetPropertyChangedSignal("Adornee"):Connect(function()
		self.dragging = false
	end)

	ArcHandles.MouseDrag:Connect(function(Axis,relativeAngle,startDeltaRadius)
		if not self.dragging then return end

		local RotIncrement = math.clamp(StudioService.RotateIncrement,0.01,360)
		local snapRot = CFrame.new()
		local axisString = string.gsub(tostring(Axis),"Enum.Axis.","")

		local axisangle = Vector3.FromAxis(Axis) * relativeAngle
		local deltaOrientation = axisangle - prevOrientation
		local deltaAxis = math.deg(deltaOrientation[axisString])
		
		if math.abs(deltaAxis) >= RotIncrement then
			local add = math.round(deltaAxis/RotIncrement) * RotIncrement
			local increment = CFrame.fromAxisAngle(Vector3.FromAxis(Axis),math.rad(add))

			snapRot = increment
			prevOrientation = axisangle
		end

		if first then first = false return end

		if snapRot ~= CFrame.new() then
			ArcHandles.Adornee.CFrame *= snapRot
			self.EventHolder:Fire("Dragged",snapRot,"Rotation")
		end
	end)

	self.ArcHandles = ArcHandles
end

function RigEditTools:IsDragging()
	return self.dragging
end

function RigEditTools:DisplayArcHandles(jointPart,Adornee)
	self.ArcHandles.Adornee = jointPart
end

function RigEditTools:DisplayHandles(jointPart,Adornee)
	for _,Handles in pairs(self.Handles) do
		Handles.Adornee = jointPart
	end
end

function RigEditTools:HideArcHandles()
	self.ArcHandles.Adornee = nil
end

function RigEditTools:HideHandles()
	for _,Handles in pairs(self.Handles) do
		Handles.Adornee = nil
	end
end

function RigEditTools:SetParent(Parent)
	self.ArcHandles.Parent = Parent
	
	for _,Handles in pairs(self.Handles) do
		Handles.Parent = Parent
	end
end

function Init()
	local self = setmetatable({},RigEditTools)
	
	self.EventHolder = EventHolder.new(self,{"LetGo","Dragged"})
	
	self.ArcHandles = nil
	self.Handles = nil
	
	self:CreateArcHandles()
	self:CreateHandles()
	
	return self
end

return Init()