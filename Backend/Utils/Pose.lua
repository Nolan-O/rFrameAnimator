local Pose = {}

local TS = game:GetService("TweenService")

local OriginData = shared.require("OriginData")
local Network = shared.require("Network")
local Configuration = shared.require("Configuration")

function GetPreviousAndNextKeyFrame(KeyFrames,timePosition)
	local peviousKeyFrame = nil
	local nextKeyFrame = nil

	for i,KeyFrame in pairs(KeyFrames) do
		if KeyFrame.TimePosition <= timePosition then
			if peviousKeyFrame and (peviousKeyFrame.TimePosition > KeyFrame.TimePosition) then
				continue
			end
			peviousKeyFrame = KeyFrame
		end
		if KeyFrame.TimePosition >= timePosition then
			if nextKeyFrame and (nextKeyFrame.TimePosition < KeyFrame.TimePosition) then
				continue
			end
			nextKeyFrame = KeyFrame
		end
	end
	
	return peviousKeyFrame,nextKeyFrame
end

function InterpolateKeyframes(nextKeyFrame,peviousKeyFrame,origin,dec)
	local prevTransfrom = Pose.calculateTransform(origin.Part0CFrame,origin.Part1CFrame,peviousKeyFrame.C0,peviousKeyFrame.C1)
	local nextTransfrom = Pose.calculateTransform(origin.Part0CFrame,origin.Part1CFrame,nextKeyFrame.C0,nextKeyFrame.C1)

	return prevTransfrom:Lerp(nextTransfrom,dec)
end

function IncrementEasingStyle(t,nextKeyFrame)
	local EasingStyle = nextKeyFrame.EasingStyle or Configuration.DefaultEasingStyle
	local EasingDirection = nextKeyFrame.EasingDirection or Configuration.DefaultEasingDirection

	if EasingStyle == "Constant" then
		return 0
	else
		return TS:GetValue(t,EasingStyle,EasingDirection)
	end
end

Pose.calculateTransform = function(p0, p1, c0, c1)
	local invCF = c0:inverse() * p0:inverse() * p1 * c1
	local pos = -invCF.p
	local rot = (invCF - invCF.p):inverse()
	
	return rot + pos
end

Pose.GetTransformAtTime = function(Rig,animationTrack,targetMotor,timePosition)
	local KeyFrameSequences = animationTrack.KeyFrameSequences
	if not KeyFrameSequences then warn("no KeyFrameSequences") return end
	
	local Root = Rig.PrimaryPart:GetRootPart() if not Root then return end
	local Transform = nil
	
	for motorName,KeyFrameSequence in pairs(KeyFrameSequences) do
		local KeyFrames = KeyFrameSequence.KeyFrames if not KeyFrames then continue end
		local Motor = KeyFrameSequence.Motor if Motor ~= targetMotor then continue end
		local peviousKeyFrame,nextKeyFrame = GetPreviousAndNextKeyFrame(KeyFrames,timePosition)
		local origin = OriginData.GetOriginForMotor(Motor)
		
		if peviousKeyFrame == nil then
			peviousKeyFrame = origin
			peviousKeyFrame.TimePosition = 0
		end

		if nextKeyFrame == nil then
			nextKeyFrame = peviousKeyFrame
		end

		local max = nextKeyFrame.TimePosition - peviousKeyFrame.TimePosition
		local min = timePosition - peviousKeyFrame.TimePosition

		if max == 0 then
			max = 1
		end

		local dec = IncrementEasingStyle(math.clamp(min/max,0,1),nextKeyFrame)
		Transform = InterpolateKeyframes(nextKeyFrame,peviousKeyFrame,origin,dec)
	end
	
	return Transform
end

Pose.PoseRig = function(Rig,timePosition,animationTrack)
	local KeyFrameSequences = animationTrack.KeyFrameSequences
	
	for motorName,KeyFrameSequence in pairs(KeyFrameSequences) do
		local KeyFrames = KeyFrameSequence.KeyFrames if not KeyFrames then continue end
		local Motor = KeyFrameSequence.Motor if not Motor then continue end
		local origin = OriginData.GetOriginForMotor(Motor)
		local peviousKeyFrame,nextKeyFrame = GetPreviousAndNextKeyFrame(KeyFrames,timePosition)
		
		if not peviousKeyFrame then
			peviousKeyFrame = origin
			peviousKeyFrame.TimePosition = 0
		end
		
		if not nextKeyFrame then
			nextKeyFrame = peviousKeyFrame
		end
		
		local max = nextKeyFrame.TimePosition - peviousKeyFrame.TimePosition
		local min = timePosition - peviousKeyFrame.TimePosition
		
		if max == 0 then
			max = 1
		end
		
		local dec = IncrementEasingStyle(math.clamp(min/max,0,1),nextKeyFrame)
		
		local newC0 = peviousKeyFrame.C0:Lerp(nextKeyFrame.C0,dec)
		local newC1 = peviousKeyFrame.C1:Lerp(nextKeyFrame.C1,dec)
		
		Motor.C0 = newC0
		Motor.C1 = newC1
	end
end

return Pose