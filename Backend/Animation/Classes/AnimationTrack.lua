local AnimationTrack = {}
AnimationTrack.__index = AnimationTrack

local Destructor = shared.require("Destructor")
local KeyFrameSequence = shared.require("KeyFrameSequence")
local KeyFrame = shared.require("KeyFrame")
local Configuration = shared.require("Configuration")

function AnimationTrack:Destroy()
	for _,Sequence in pairs(self.KeyFrameSequences) do
		Sequence:Destroy()
	end
	setmetatable(self,nil)
end

function AnimationTrack:Clear()
	for _,Sequence in pairs(self.KeyFrameSequences) do
		Sequence:Destroy()
	end
	self.KeyFrameSequences = {}
end

function AnimationTrack:GetKeyFrames()
	local toReturn = {}
	for _,Sequence in pairs(self.KeyFrameSequences) do
		for _,KeyFrame in pairs(Sequence.KeyFrames) do
			table.insert(toReturn,KeyFrame)
		end
	end
	return toReturn
end

function AnimationTrack:GetKeyFrameAmount()
	local total = 0
	for _,Sequence in pairs(self.KeyFrameSequences) do
		for _,KeyFrame in pairs(Sequence.KeyFrames) do
			total += 1
		end
	end
	return total
end

function AnimationTrack:DestroyKeyFrame(timePos,motor)
	timePos = math.round(timePos)
	
	for _,Sequence in pairs(self.KeyFrameSequences) do
		if Sequence.Motor ~= motor then continue end
		for oldTimePos,KeyFrame in pairs(Sequence.KeyFrames) do
			if KeyFrame.TimePosition == timePos then
				Sequence.KeyFrames[timePos]:Destroy()
				Sequence.KeyFrames[timePos] = nil
			end
		end
	end
end

function AnimationTrack:DestroyKeyFrameById(Id)
	local KeyFrame = self:GetKeyFrameById(Id) if not KeyFrame then return end
	local TimePosition = KeyFrame.TimePosition or math.huge
	local Motor = KeyFrame.Motor

	self:DestroyKeyFrame(TimePosition,Motor)
end

function AnimationTrack:SetNewKeyFrameTimePosition(KeyFrameObj,newTimePos)
	if not KeyFrameObj or KeyFrameObj.TimePosition == newTimePos then return end
	newTimePos = math.round(newTimePos)
	
	for _,Sequence in pairs(self.KeyFrameSequences) do
		for oldTimePos,KeyFrame in pairs(Sequence.KeyFrames) do
			if KeyFrame ~= KeyFrameObj then continue end
				
			local existingKeyFrame = Sequence:GetKeyFrameAtPos(newTimePos)
			if existingKeyFrame and existingKeyFrame ~= KeyFrameObj then
				Sequence:DestroyKeyFrameAtPos(existingKeyFrame.TimePosition)
			end
			
			Sequence.KeyFrames[oldTimePos] = nil
			Sequence.KeyFrames[newTimePos] = KeyFrameObj
			KeyFrameObj.TimePosition = newTimePos
		end
	end
end

function AnimationTrack:AddKeyFrame(timePosition,motor)
	local foundKeyFrameSequence = self.KeyFrameSequences[motor.Name]
	if foundKeyFrameSequence == nil then return end
	
	return foundKeyFrameSequence:UpdateKeyFrame(math.round(timePosition))
end

function AnimationTrack:GetKeyFrameById(Id)
	for _,KeyFrame in pairs(self:GetKeyFrames()) do
		if tostring(KeyFrame.Id) ~= tostring(Id) then continue end
		return KeyFrame
	end
end

function AnimationTrack:GetBiggestTimePos()
	local biggest = 0
	for _,KeyFrame in pairs(self:GetKeyFrames()) do
		if KeyFrame.TimePosition > biggest then
			biggest = KeyFrame.TimePosition
		end
	end
	return biggest
end

function AnimationTrack.new(Rig)
	local self = setmetatable({},AnimationTrack)
	
	self.Name = "Animation"
	self.Looped = false
	self.FramesPerSec = 60
	self.Length = Configuration.DefaultAnimationLength
	self.Priority = "Action"
	self.KeyFrameSequences = {}
	
	for _,motor in pairs(Rig:GetDescendants()) do
		if not motor:IsA("Motor6D") then continue end
		self.KeyFrameSequences[motor.Name] = KeyFrameSequence.new(motor)
	end
	
	return self
end

return AnimationTrack