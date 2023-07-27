local SavePointService = {}
SavePointService.__index = SavePointService

local CHS = game:GetService("ChangeHistoryService")
local UIS = game:GetService("UserInputService")

local Network = shared.require("Network")
local InputService = shared.require("InputService")

local CacheThreshold = 30

local function deepCopy(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			v = deepCopy(v)
		end
		copy[k] = v
	end
	return copy
end

function SavePointService:Disable()
	CHS:SetEnabled(true)
end

function SavePointService:Enable()
	CHS:ResetWaypoints()
	CHS:SetEnabled(false)
end

function SavePointService:Clear()
	table.clear(self.SafePoints)
end

function SavePointService:PushBack()
	local contentSize = table.getn(self.SafePoints) if contentSize <= CacheThreshold then return end
	
	local function removeLast(t)
		local indexe = {}
		for i,v in pairs(t) do
			if v == nil then continue end
			table.insert(indexe,i)
		end
		if table.getn(indexe) < 1 then return end
		t[math.min(unpack(indexe))] = nil
	end
	
	for i = 1, contentSize - CacheThreshold do
		removeLast(self.SafePoints)
	end
end

function SavePointService:Redo()
	self.index = math.clamp(self.index + 2, 0, self.totalIndex)
	local point = self.SafePoints[self.index] if not point then return end
	Network:Execute("LoadWaypoint",point)
end

function SavePointService:Undo()
	self.index = math.clamp(self.index - 2,0,math.huge)
	local point = self.SafePoints[self.index] if not point then return end
	Network:Execute("LoadWaypoint",point)
end

function SavePointService:SetPoint(Animation)
	if not Animation then return end	
	
	self.totalIndex += 1
	self.SafePoints[self.totalIndex] = deepCopy(Animation)
	self:PushBack()
	
	self.index = self.totalIndex + 1
end

function Init()
	local self = setmetatable({},SavePointService)
	
	self.SafePoints = {}
	
	self.index = 1
	self.totalIndex = 1
	
	InputService:BindToInput({"UserInputService"},Enum.KeyCode.Y,Enum.UserInputState.Begin,function()
		if not InputService:IsKeyDown(Enum.KeyCode.LeftControl) then return end
		self:Undo()
	end)
	
	InputService:BindToInput({"UserInputService"},Enum.KeyCode.Z,Enum.UserInputState.Begin,function()
		if not InputService:IsKeyDown(Enum.KeyCode.LeftControl) then return end
		self:Redo()
	end)
	
	return self
end

return Init()