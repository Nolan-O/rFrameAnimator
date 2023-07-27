local Destructor = shared.require("Destructor")
local EventHolder = shared.require("EventHolder")
local KeyFrame = shared.require("KeyFrame")

local KeyFrameSequence = {}
KeyFrameSequence.__index = KeyFrameSequence

function KeyFrameSequence:Destroy()
	for _, keyFrame in pairs(self.KeyFrames) do
		keyFrame:Destroy()
	end
	setmetatable(self,nil)
end

function KeyFrameSequence:Clear()
	for i, keyFrame in pairs(self.KeyFrames) do
		keyFrame:Destroy()
		self.KeyFrames[i] = nil
	end
end

function KeyFrameSequence:DestroyKeyFrameAtPos(targetTimePos)
	for timePosition, keyFrame in pairs(self.KeyFrames) do
		if math.round(timePosition) == math.round(targetTimePos) then
			keyFrame:Destroy()
			self.KeyFrames[timePosition] = nil
		end
	end 
end

function KeyFrameSequence:AddKeyFrameToTrack(timePosition)
	if not timePosition then warn("no time position") return end
	timePosition = math.round(timePosition)
	
	self.KeyFrames[timePosition] = KeyFrame.new(timePosition,self.Motor)
	return self.KeyFrames[timePosition]
end

function KeyFrameSequence:UpdateKeyFrame(timePosition)
	local existingKeyFrame = self.KeyFrames[math.round(timePosition)]
	
	if existingKeyFrame then
		existingKeyFrame:UpdateMotorOffset()
		return existingKeyFrame
	else
		-- trying to add a new one
		return self:AddKeyFrameToTrack(timePosition)
	end
end

function KeyFrameSequence:GetKeyFrameAtPos(timePosition)
	return self.KeyFrames[math.round(timePosition)]
end

function KeyFrameSequence.new(motor)
	local self = setmetatable({},KeyFrameSequence)
	
	self.Motor = motor
	self.KeyFrames = {}
	
	return self
end

return KeyFrameSequence