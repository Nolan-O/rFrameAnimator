local Modules = {}

for _,inst in pairs(script.Parent:GetDescendants()) do
	if not inst:IsA("ModuleScript") then continue end

	if Modules[inst.Name] ~= nil then
		warn("duplicate Modules found for index: ",inst.Name)
	end

	Modules[inst.Name] = inst
end

shared.require = function(ModuleName:string)
	local module = Modules[ModuleName] 

	if not module then
		warn("Module not found: ",ModuleName)
	end
	
	local required
	local succ,err = pcall(function()
		required = require(module)
	end)

	if succ then
		return required
	else
		warn(err)
	end
end

return "initialized"