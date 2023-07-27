local OriginData = {}
OriginData.Rig = nil
OriginData.Cache = {}

OriginData.Clear = function()
	for i,v in pairs(OriginData.Cache) do
		OriginData.Cache[i] = nil
	end
	OriginData.Rig = nil
end

OriginData.GetMotorFromPart1 = function(part1)
	for motor,_ in pairs(OriginData.Cache) do
		if motor.Part1 == part1 then
			return motor
		end
	end
end

OriginData.ReturnModelToOrigin = function()
	if not OriginData.Rig then return end
	
	for motor,data in pairs(OriginData.Cache) do
		motor.C0 = data.C0
		motor.C1 = data.C1
	end
end

OriginData.GetOriginForMotor = function(Motor)
	return OriginData.Cache[Motor]
end

OriginData.GetMotorByName = function(Name:string)
	for motor,_ in pairs(OriginData.Cache) do
		if motor.Name ~= Name then continue end
		return motor
	end
end

OriginData.SetNew = function(Rig)
	if not Rig then warn("Invalid Rig!") return end
	OriginData.Clear()
	
	for _,motor in pairs(Rig:GetDescendants()) do
		if not motor:IsA("Motor6D") then continue end
		
		OriginData.Cache[motor] = {
			C0 = motor.C0,
			C1 = motor.C1,
			Part0CFrame = motor.Part0.CFrame,
			Part1CFrame = motor.Part1.CFrame,
			CFrame = CFrame.new(),
		}
	end
	
	OriginData.Rig = Rig
end

return OriginData