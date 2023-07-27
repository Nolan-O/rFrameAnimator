local Signal = {}
Signal.__index = Signal

local function parseError(err) -- credits Elttob
	return {
		raw = err,
		message = err:gsub("^.+:%d+:",""),
		trace = debug.traceback(nil,1)
	}
end

local function logError(errLog)
	print("Singal error: ",errLog)
end

function Signal:Create()
	return setmetatable({Listeners = {},}, Signal)
end

function Signal:Connect(Listener)
	local index = #self.Listeners+1
	
	self.Listeners[index] = Listener
	
	return {
		Disconnect = function()
			self.Listeners[index] = nil
		end,
	}
end

function Signal:Fire(...)
	for _,Listener in pairs(self.Listeners) do
		local newThread = coroutine.wrap(Listener)
		local succ, log = xpcall(newThread, parseError, ...)
		
		if not succ then
			logError(log)
		end
	end
end

function Signal:Delete()
	for i,v in pairs(self.Listeners) do
		self.Listeners[i] = nil
	end
	setmetatable(self,nil)
end

return Signal