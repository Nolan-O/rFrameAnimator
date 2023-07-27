local Network = {}

local Signal = shared.require("Signal")

local Signals = {}

function YieldForSignal(name,timeOut)
	local startTime = tick()
	repeat wait() until startTime - tick() >= timeOut or Signals[name]
	return Signals[name]
end

function Network:Execute(name:string,...)
	local signalObj = Signals[name] or YieldForSignal(name,5) if not signalObj then warn(("missing Signal: %s"):format(name)) return end
	return signalObj:Fire(...)
end

function Network:Register(name:string,callback)
	local signalObj = Signal:Create()
	Signals[name] = signalObj
	signalObj:Connect(callback)
end

return Network