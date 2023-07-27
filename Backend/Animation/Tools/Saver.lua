local Saver = {}
Saver.__index = Saver

local KeyFrameSequence = shared.require("KeyFrameSequence")
local Configuration = shared.require("Configuration")
local Serialization = shared.require("Serialization")

local plugin = shared.Plugin

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

local function GetSave(Parent,Name)
	local existingModule = Parent:FindFirstChild(Name)
	
	if existingModule then
		existingModule:Destroy()
	end
	
	existingModule = Instance.new("ModuleScript")
	existingModule.Name = Name
	existingModule.Parent = Parent
	
	return existingModule
end

function Saver:SaveAnimation(Parent,Name,Animation)
	local existingModule = Parent:FindFirstChild(Name)
	local mainModule = GetSave(Parent,Name)
	
	local mainData = deepCopy(Animation)
	local KFSData = Animation.KeyFrameSequences
	
	mainData.KeyFrameSequences = nil -- erase unnecessary info from main module
	mainModule.Source = "return"..Serialization.SerializeTable(mainData)
	
	for motorName,data in pairs(KFSData) do
		local module = Instance.new("ModuleScript",mainModule)
		
		module.Name = motorName
		module.Source = "return"..Serialization.SerializeTable(data)
	end
	
	print("Saved Animation: ",Name)
	
	return mainModule
end

function Saver:AutoSave(Rig,Animation)
	if Animation:GetKeyFrameAmount() < 1 then return end
	
	self:SaveAnimation(Rig,Configuration.AutoSaveName,Animation)
	print("Auto saved")
end

function Build()
	local self = setmetatable({},Saver)
	
	return self
end
	
return Build()