local TimeDragger = {}
TimeDragger.__index = TimeDragger

local RunService = game:GetService("RunService")

local UIUtils = shared.require("UIUtils")

local Globals = shared.Globals

local curTimePosition = Globals.curTimePosition
local maxTimePosition = Globals.maxTimePosition

function TimeDragger:IsDragging()
	return self.dragging
end

function TimeDragger:StartDragging()
	self.dragging = true
	
	UIUtils.CatchDrop(self.Widget,function()
		self.dragging = false
	end)
	
	local con
	con = RunService.RenderStepped:Connect(function()
		if not self.dragging then
			con:Disconnect()
			return
		end
		
		local absSize = self.Adornee.AbsoluteSize
		local absPos = self.Adornee.AbsolutePosition
		
		local mousep = self.Widget:GetRelativeMousePosition() - absPos
		local XScale = UIUtils.SnapUI(mousep.X/absSize.X)

		XScale = math.clamp(XScale,0,1)
		curTimePosition.Value = maxTimePosition.Value * XScale
	end)
end

function TimeDragger.new(Widget,Adornee,triggerEvents)
	local self = setmetatable({},TimeDragger)
	
	self.Widget = Widget
	self.Adornee = Adornee
	self.dragging = false
	
	for _,event in pairs(triggerEvents) do
		event:Connect(function()
			self:StartDragging()
		end)
	end
	
	return self
end

return TimeDragger