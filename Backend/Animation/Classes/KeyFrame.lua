local HTTPS = game:GetService("HttpService")

local Destructor = shared.require("Destructor")
local OriginData = shared.require("OriginData")
local Configuration = shared.require("Configuration")
local BackendUtils = shared.require("BackendUtils")

local KeyFrame = {}
KeyFrame.__index = KeyFrame

function KeyFrame:Destroy()
	for i,v in pairs(self) do
		self[i] = nil
	end
	setmetatable(self,nil)
end

function KeyFrame:UpdateMotorOffset()
	self.C0 = self.Motor.C0
	self.C1 = self.Motor.C1
	self.Part1CFrame = self.Motor.Part1.CFrame
	self.Part0CFrame = self.Motor.Part0.CFrame
end

function KeyFrame:SetAxisOffset(offsetType,axis,offset)
	local origin = OriginData.GetOriginForMotor(self.Motor) if not origin then return end
	local C1, C0 = self.C1, self.C0
	local part1CF, part0CF = self.Part1CFrame, self.Part0CFrame
	
	local C1NegOffset = part1CF:inverse()
	local C0NegOffset = part0CF:inverse()
	
	local originPivot = part0CF * origin.C0
	local curPivot = part0CF * C0
	
	if offsetType == "Position" then
		local curPos = curPivot.p
		local curRot = curPivot - curPivot.p
		
		offset += originPivot[axis]
		
		local CFrames = {
			X = CFrame.new(offset,curPos.Y,curPos.Z),
			Y = CFrame.new(curPos.X,offset,curPos.Z),
			Z = CFrame.new(curPos.X,curPos.Y,offset),
		}
		
		self.C0 = BackendUtils.repairedCFrame(C0NegOffset * (CFrames[axis] * curRot))
	end
end

function KeyFrame:SetOffsets(C0,C1)
	self.C0 = C0
	self.C1 = C1
end

function KeyFrame.new(timePosition,Motor)
	if not Motor then warn("invalid Motor") return end
	if type(timePosition) ~= "number" then warn("invalid time Position") return end
	
	local self = setmetatable({},KeyFrame)
	
	self.Id = HTTPS:GenerateGUID(false)
	self.TimePosition = math.round(timePosition)
	
	self.Motor = Motor
	self.C0 = Motor.C0
	self.C1 = Motor.C1
	self.Part1CFrame = Motor.Part1.CFrame
	self.Part0CFrame = Motor.Part0.CFrame
	self.CFrame = CFrame.new()
	
	self.EasingStyle = Configuration.DefaultEasingStyle
	self.EasingDirection = Configuration.DefaultEasingDirection
	
	return self
end

return KeyFrame