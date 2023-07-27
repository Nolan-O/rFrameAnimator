local Exporter = {}

local Selection = game:GetService("Selection")

local Pose = shared.require("Pose")
local Configuration = shared.require("Configuration")

local Globals = shared.Globals

function SaveToRig(Rig,KFS)
	local animSaves = Rig:FindFirstChild("AnimSaves")
	if not animSaves then
		animSaves = Instance.new("Model")
		animSaves.Name = "AnimSaves"
		animSaves.Parent = Rig
	end
	local save = animSaves:FindFirstChild(KFS.Name)
	if save then
		save:Destroy()
	end
	KFS.Parent = animSaves
end

function getValidMotors(Animation)
	local validMotors = {}
	for _,KF in pairs(Animation:GetKeyFrames()) do
		if table.find(validMotors,KF.Motor) ~= nil then continue end
		table.insert(validMotors,KF.Motor)
	end
	return validMotors
end

function generateKeyframe(Rig,Animation,TimePosInFrames,TimePosInSec)
	local rootPart = Rig.PrimaryPart:GetRootPart() if not rootPart then warn("no root") return end
	local validMotors = getValidMotors(Animation)
	local partsAdded = {rootPart}

	local function addPoses(part, parentPose) 
		for _, joint in pairs(part:GetJoints()) do
			if not joint:IsA("Motor6D") then continue end
			local connectedPart = nil
			local isValid = table.find(validMotors,joint) ~= nil
			
			if joint.Part0 == part then 
				connectedPart = joint.Part1
			end
			if joint.Part1 == part then 
				connectedPart = joint.Part0
			end
			
			if not connectedPart then continue end 	
			if table.find(partsAdded,connectedPart) ~= nil then continue end
			table.insert(partsAdded,connectedPart)
			
			local pose = Instance.new("Pose")
			pose.Name = connectedPart.Name
			pose.CFrame = Pose.GetTransformAtTime(Rig,Animation,joint,TimePosInFrames)
			pose.EasingStyle = "Constant"
			pose.EasingDirection = "In"
			pose.Weight = isValid and 1 or 0
			
			parentPose:AddSubPose(pose)
			addPoses(connectedPart, pose or parentPose)		
		end
	end

	local keyframe = Instance.new("Keyframe")
	local rootPose = Instance.new("Pose")
	
	rootPose.Name = rootPart.Name
	rootPose.EasingStyle = "Constant"
	rootPose.EasingDirection = "InOut"
	rootPose.Weight = 1
	
	addPoses(rootPart, rootPose)
	
	keyframe.Time = TimePosInSec
	keyframe:AddPose(rootPose)

	return keyframe
end

function Exporter.Export(Rig,Animation)
	local Prim = Rig.PrimaryPart if not Prim then warn("could not save: PrimaryPart is nil") return end
	
	local FramesPerSec = Globals.FramesPerSec.Value
	local Length = Animation:GetBiggestTimePos()
	local Name = Animation.Name or ""
	
	local Amount = FramesPerSec * (Animation.Length/60)
	local KFS = Instance.new("KeyframeSequence")
	
	KFS.Loop = Animation.Looped or false
	KFS.Priority = Animation.Priority or Enum.AnimationPriority.Action
	KFS.Name = Name
	
	for i = 1, Amount+1 do
		local TimePositionInFrames = math.round(Length/Amount*(i-1))
		local TimePositionInSec = TimePositionInFrames/Configuration.DefaultFramesPerSec
		local KeyFrame = generateKeyframe(Rig,Animation,TimePositionInFrames,TimePositionInSec)
		
		KeyFrame.Parent = KFS
	end
	
	SaveToRig(Rig,KFS)
	Selection:Set({KFS})
	shared.Plugin:SaveSelectedToRoblox()
end

return Exporter
