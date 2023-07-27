local Cooldowns = {}
Cooldowns.__index = Cooldowns

function Cooldowns:Check(key:string)
	return self.Cache[key] ~= nil
end

function Cooldowns:Add(key:string,duration:number)
	self.Cache[key] = duration
	delay(duration,function()
		self.Cache[key] = nil
	end)
end

function Init()
	local self = setmetatable({},Cooldowns)
	
	self.Cache = {}
	
	return self
end

return Init()