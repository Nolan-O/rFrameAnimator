local Importer = {}

local KeyFrameSequence = shared.require("KeyFrameSequence")
local Configuration = shared.require("Configuration")
local OriginData = shared.require("OriginData")
local Globals = shared.Globals
local plugin = shared.Plugin

local function saveRequire(module:ModuleScript)
	local source
	local succ,err = pcall(function()
		source = require(module)
	end)
	if not succ then
		warn(err)
	end
	return source
end

function Importer.ImportFromModule(Animation,AnimationSave,Rig)
	local mainData = saveRequire(AnimationSave) if not mainData then return end
	local KFSDatas = {}
	
	Animation:Clear()
	
	for _,module in pairs(AnimationSave:GetChildren()) do
		if not module:IsA("ModuleScript") then continue end
		local source = saveRequire(module) if not source then continue end
		
		KFSDatas[module.Name] = source
	end
	
	for motorName,sequence in pairs(KFSDatas) do
		local motor = OriginData.GetMotorByName(motorName) if not motor then continue end
		local sequenceObj = KeyFrameSequence.new(motor)

		Animation.KeyFrameSequences[motorName] = sequenceObj

		for timePos, keyFrame in pairs(sequence.KeyFrames) do
			local keyFrameObj = sequenceObj:UpdateKeyFrame(timePos)

			for i,v in pairs(keyFrame) do
				if tostring(i) == "Id" then continue end
				keyFrameObj[i] = v
			end
		end
	end
	
	Animation.Length = tonumber(mainData.Length) or Configuration.DefaultAnimationLength
	Animation.FramesPerSec = mainData.FramesPerSec or Configuration.DefaultFramesPerSec
	Animation.Priority = mainData.Priority or Configuration.DefaultAnimationPriority
	Animation.Name = AnimationSave.Name or ""
	Animation.Looped = mainData.Looped or false
end

function Importer.ImportSource(Animation,AnimationSave,Rig)
	if not AnimationSave then warn("invalid Animation Save") return end
	
	local validTypes = {
		ModuleScript = Importer.ImportFromModule,
		--KeyframeSequence = Importer.ImportFromKFS,
		-- TODO beim importieren from KFS instances Weight 0 KeyFrames ignorieren
	}
	
	local func = validTypes[AnimationSave.ClassName]
	if func then
		OriginData.ReturnModelToOrigin()
		func(Animation,AnimationSave,Rig)
	else
		warn("invalid source type: ",AnimationSave.ClassName)
	end
end

return Importer