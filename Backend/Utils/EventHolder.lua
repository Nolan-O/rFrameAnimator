-- Class wrapper to easily add events / by Chahier

local EventHolder = {}
EventHolder.__index = EventHolder

local Signal = shared.require("Signal")

function EventHolder:Destroy()
	for eventName,event in pairs(self.EventCache) do
		if self.Adornee[eventName] == event then
			self.Adornee[eventName] = nil
		end
		event:Delete()
	end
	setmetatable(self,nil)
end

function EventHolder:Fire(EventName,...)
	local event = self.EventCache[EventName] if not event then warn(EventName," is not a valid event") return end
	event:Fire(...)
end

function EventHolder.new(object,EventList:table)
	local self = setmetatable({},EventHolder)
	
	self.Adornee = object
	self.EventCache = {}
	
	for _,eventName in next,EventList do
		if object[eventName] ~= nil then
			warn(eventName," is already taken")
			continue
		end
		
		local connection = Signal:Create()
		
		self.EventCache[eventName] = connection
		object[eventName] = connection
	end
	
	return self
end

return EventHolder