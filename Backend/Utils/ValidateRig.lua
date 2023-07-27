local function checkForCircularRig(motors)
	local traversed = {}
	for Part0, motor in pairs(motors) do
		local part0 = motor.Part0
		if part0 and Part0 and part0 == Part0 then
			return true
		end
		while part0 ~= nil and part0 ~= game.Workspace do
			local connectedMotor = motors[part0]
			if connectedMotor then
				part0 = connectedMotor.Part0
				if not traversed[connectedMotor] then
					traversed[connectedMotor] = {}
				else
					return true
				end
			else
				break
			end
		end
		traversed = {}
	end
	return false
end

local function checkForNameCollisions(motors,root)
	local collisions = {}
	for _,motor in pairs(motors) do
		local p0, p1 = motor.Part0, motor.Part1
		if p0.Name == root.Name and (p0 ~= root) then
			return true
		end
		if p1.Name == root.Name and (p1 ~= root) then
			return true
		end
	end
	return false
end

local function findMotorErrors(motors)
	for _,motor in pairs(motors) do
		local p0, p1 = motor.Part0, motor.Part1
		if not p0 or (p0 and p0.Parent == nil) then
			return true
		end
		if not p1 or (p1 and p1.Parent == nil) then
			return true
		end
	end 
	return false
end

function getMotors(rig)
	local motors = {}
	for _, child in ipairs(rig:GetDescendants()) do
		if child:IsA("Motor6D") then
			table.insert(motors, child)
		end
	end
	return motors
end

function getAnimationController(rig)
	return rig:FindFirstChildOfClass("Humanoid") or rig:FindFirstChildOfClass("AnimationController")
end

return function(Rig)
	if not Rig or not Rig:IsA("Model") then return false, {"Rig must be a model"} end
	if not Rig.PrimaryPart then return false, {"Rig needs a primary part"} end
	if not getAnimationController(Rig) then return false, {"Rig must contain a Humanoid or AnimationController"} end
	
	local err = {}
	local motors = getMotors(Rig)
	local root = Rig.PrimaryPart
	
	if checkForCircularRig(motors) then
		table.insert(err,"Rig is circular")
	end
	
	if findMotorErrors(motors) then
		table.insert(err,"Motor(s) are missing Part0/Part0")
	end
	
	if checkForNameCollisions(motors,root) then
		table.insert(err,"Name collision detected")
	end
	
	return #err == 0, err
end