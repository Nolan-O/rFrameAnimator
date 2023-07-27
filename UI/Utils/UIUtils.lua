local UIUtils = {}
local UIS = game:GetService("UserInputService")

local Configuration = shared.require("Configuration")
local Globals = shared.Globals

local curTimePosition = Globals.curTimePosition
local maxTimePosition = Globals.maxTimePosition

function Resolve(Cons,callback)
	for _,con in pairs(Cons) do
		con:Disconnect()
	end
	callback()
end

function canResolve(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		return true
	end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		return true
	end
end

function setCons(inputState,Widget,callback)
	local inputCatcher = Widget:FindFirstChild("inputCatcher")
	local Cons = {}
	
	Cons[1] = UIS[inputState]:Connect(function(input)
		if not canResolve(input) then return end
		Resolve(Cons,callback)
	end)
	
	Cons[2] = inputCatcher[inputState]:Connect(function(input)
		if not canResolve(input) then return end
		Resolve(Cons,callback)
	end)
	
	return Cons
end

function UIUtils.CatchDrop(Widget,callback)
	setCons("InputEnded",Widget,callback)
end

function UIUtils.CatchClick(Widget,callback)
	setCons("InputBegan",Widget,callback)
end

function UIUtils.SnapUI(Number)
	local divider = maxTimePosition.Value
	local snap = math.round(Number*divider)/divider
	
	return snap
end

return UIUtils