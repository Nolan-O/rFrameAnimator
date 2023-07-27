local Destructor = {}
Destructor.__index = Destructor

function Destructor:Destroy()
	self:Clear()
	setmetatable(self,nil)
end

function Destructor:Clear()
	local function ClearTable(t)
		for i,inst in pairs(t) do
			t[i] = nil
			
			if typeof(inst) == "Instance" then
				inst:Destroy()
			elseif typeof(inst) == "RBXScriptConnection" then
				inst:Disconnect() 
			elseif typeof(inst) == "table" then
				if getmetatable(inst) ~= nil then
					setmetatable(inst,nil)
					continue
				end
				if typeof(inst.Destroy) == "function" then
					inst:Destroy()
				end
				if typeof(inst.Disconnect) == "function" then
					inst:Disconnect()
				end 
				ClearTable(inst)
			end
		end
	end
	ClearTable(self.container)
end

function Destructor:Add(...)
	table.insert(self.container,table.pack(...))
end

function Destructor.new()
	local self = setmetatable({},Destructor)
	self.container = {}
	return self
end

return Destructor