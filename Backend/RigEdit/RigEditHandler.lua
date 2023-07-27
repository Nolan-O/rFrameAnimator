local RigEditHandler = {}
RigEditHandler.__index = RigEditHandler

local plugin = shared.Plugin

local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local StudioService = game:GetService("StudioService")

local RigEditTools = shared.require("RigEditTools")
local Network = shared.require("Network")
local OriginData = shared.require("OriginData")
local Configuration = shared.require("Configuration")

local ColorPalette = Configuration.ColorPalette
local mouse = plugin:GetMouse()

local selectionBoxColor = ColorPalette.Blue
local proxySelectionBoxColor = ColorPalette.LightBlue

local function setJointPart(part1,jointPart)
	local Motor = OriginData.GetMotorFromPart1(part1) if not Motor then return end
	local pivot = part1.CFrame * Motor.C1
	local rot = part1.CFrame - part1.CFrame.p
	local useLocalSpace = false--StudioService.UseLocalSpace
	
	if useLocalSpace then
		jointPart.CFrame = rot + pivot.p
	else
		jointPart.CFrame = CFrame.new(pivot.p)
	end
	
	jointPart.Size = part1.Size
end

function RigEditHandler:GetProxyPartFromP1(p1)
	for i,v in pairs(self.ProxyRefferences) do
		if v == p1 then
			return i
		end
	end
end

function RigEditHandler:HighlightPart(Part)
	if Part ~= nil and table.find(self.PartWhiteList,Part) ~= nil and Part ~= self.curSelected then
		self.selectionBox.Adornee = Part
	else
		self.selectionBox.Adornee = nil
	end
end

function RigEditHandler:UpdateDummyRig()
	for p, p1 in pairs(self.ProxyRefferences) do
		p.CFrame = p1.CFrame
	end
end

function RigEditHandler:ProcessRig(Rig)
	for _,Motor in pairs(Rig:GetDescendants()) do
		if not Motor:IsA("Motor6D") then continue end
		local p1 = Motor.Part1 if not p1 then continue end
		
		local p = Instance.new("Part")
		p.Archivable = false
		p.CanCollide = false
		p.Anchored = false
		p.Size = p1.Size
		p.Transparency = 1
		p.CFrame = p1.CFrame
		p.Parent = workspace.CurrentCamera
		
		self.Cons[#self.Cons+1] = p1.AncestryChanged:Connect(function()
			if not p1.Parent and not self.CurSelected then
				p:Destroy()
				self:DeselectPart()
			end
		end)
		
		table.insert(self.PartWhiteList,p)
		self.ProxyRefferences[p] = p1
	end
	
	self.Cons[#self.Cons+1] = Rig.AncestryChanged:Connect(function()
		if not Rig.Parent then
			self:Deactivate()
		end
	end)
	
	self.Cons[#self.Cons+1] = RunService.Heartbeat:Connect(function()
		for p, p1 in pairs(self.ProxyRefferences) do
			p.CFrame = p1.CFrame
		end
	end)
end

function RigEditHandler:DisplayTool(bool,Adornee)
	if not self.curSelected then return end

	RigEditTools:HideArcHandles()
	RigEditTools:HideHandles()

	if not bool then return end
	
	if self.CurTool == "Handles" then
		RigEditTools:DisplayHandles(self.jointPart,Adornee)
	end
	
	if self.CurTool == "ArcHandles" then
		RigEditTools:DisplayArcHandles(self.jointPart,Adornee)
	end
	
	setJointPart(Adornee,self.jointPart)
end

function RigEditHandler:SelectPart(Part)
	local p1 = self.ProxyRefferences[Part] if not p1 then return end
	local Motor = OriginData.GetMotorFromPart1(p1) if not Motor then return end
	
	self:DeselectPart()
	self.curSelected = p1
	
	self.proxySelectionBox.Visible = true
	self.proxySelectionBox.Adornee = p1
	
	self:DisplayTool(true,p1)
	Network:Execute("HighlightSheet",Motor)
end

function RigEditHandler:DeselectPart()
	self:DisplayTool(false,nil)
	self.curSelected = nil
	self.proxySelectionBox.Visible = false
	
	Network:Execute("HighlightSheet",nil)
end

function RigEditHandler:Cast()
	local ray = workspace.CurrentCamera:ViewportPointToRay(self.Mousep.X, self.Mousep.Y)
	ray = Ray.new(ray.Origin, ray.Direction.Unit * 512, false, true)
		
	return workspace:FindPartOnRayWithWhitelist(ray, self.PartWhiteList)
end

function RigEditHandler:Pause()
	self.Paused = true
	self:DeselectPart()
end

function RigEditHandler:Resume()
	self.Paused = false
	self:UpdateDummyRig()
end

function RigEditHandler:Activate(curRig)
	self:Deactivate()
	
	self.Rig = curRig
	self:ProcessRig(curRig)
	
	self.Cons[#self.Cons+1] = RunService.RenderStepped:Connect(function()
		if self.curSelected and not RigEditTools:IsDragging() then
			setJointPart(self.curSelected,self.jointPart)
		end
		
		if RigEditTools:IsDragging() or self.Paused then
			self:HighlightPart(nil)
		else
			self:HighlightPart(self:Cast())
		end
	end)
end

function RigEditHandler:Deactivate()
	self:DeselectPart()
	self:DisplayTool(false)
	
	for _,con in pairs(self.Cons) do
		con:Disconnect()
	end
	
	for p,p1 in pairs(self.ProxyRefferences) do
		p:Destroy()
	end
	
	table.clear(self.ProxyRefferences)
	table.clear(self.PartWhiteList)
	table.clear(self.Cons)
	
	self.selectionBox.Adornee = nil
	self.proxySelectionBox.Adornee = nil
	self.Rig = nil
end

function Init()
	local self = setmetatable({},RigEditHandler)
	
	local rFrameFolder = CoreGui:FindFirstChild("rFrameStuff") or Instance.new("Folder",CoreGui)
	rFrameFolder.Name = "rFrameStuff"
	rFrameFolder:ClearAllChildren()
	
	local selectionBox = Instance.new("SelectionBox")
	selectionBox.Color3 = selectionBoxColor
	selectionBox.Visible = true
	selectionBox.Archivable = false
	selectionBox.LineThickness = .02
	selectionBox.Transparency = .5
	selectionBox.Parent = rFrameFolder

	local proxySelectionBox = Instance.new("SelectionBox")
	proxySelectionBox.Color3 = proxySelectionBoxColor
	proxySelectionBox.Visible = true
	proxySelectionBox.Archivable = false
	proxySelectionBox.LineThickness = .021
	proxySelectionBox.Transparency = 0
	proxySelectionBox.Adornee = nil
	proxySelectionBox.Parent = rFrameFolder

	local jointPart = Instance.new("Part")
	jointPart.Archivable = false
	jointPart.Locked = true
	jointPart.Transparency = 1
	jointPart.Anchored = false
	jointPart.CanCollide = false
	jointPart.Parent = rFrameFolder

	self.selectionBox = selectionBox
	self.proxySelectionBox = proxySelectionBox
	self.jointPart = jointPart
	self.Folder = rFrameFolder

	self.Cons = {}
	self.PartWhiteList = {}
	self.ProxyRefferences = {}
	
	self.Mousep = Vector2.new(0,0)
	self.CurTool = "Handles"
	self.Paused = false
	
	self.Rig = nil
	self.curSelected = nil
	
	plugin.Deactivation:Connect(function()
		self:Deactivate()
	end)
	
	UIS.InputBegan:Connect(function(input)
		if not self.Rig or RigEditTools:IsDragging() then return end
		
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local hitPart = self:Cast()
			if hitPart then
				self:SelectPart(hitPart)
			else
				self:DeselectPart()
			end
		end
		
		if input.KeyCode == Enum.KeyCode.R then
			self.CurTool = self.CurTool == "ArcHandles" and "Handles" or "ArcHandles"
			self:DisplayTool(true,self.curSelected)
		end
	end)
	
	UIS.InputChanged:connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			self.Mousep = Vector2.new(input.Position.X, input.Position.Y)
		end
	end)
	
	RigEditTools.Dragged:Connect(function(...)
		Network:Execute("IncrementCFChange",self.curSelected,...)
	end)
	
	RigEditTools.LetGo:Connect(function()
		self:UpdateDummyRig()
	end)
	
	Network:Register("SelectPart",function(Part)
		if not Part or not self.Rig then return end
		if not Part:IsDescendantOf(self.Rig) then return end
		
		local proxyPart = self:GetProxyPartFromP1(Part) if not proxyPart then return end
		
		if self.curSelected == Part then
			self:DeselectPart()
		else
			self:SelectPart(proxyPart)
		end
	end)
	
	RigEditTools:SetParent(rFrameFolder)
	
	return self
end

return Init()