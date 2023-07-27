local PopupMenu = {}
PopupMenu.__index = PopupMenu

local RunService = game:GetService("RunService")

local Destructor = shared.require("Destructor")
local EventHolder = shared.require("EventHolder")

local UITemplates = shared.UITemplates

local TRIGGER_TIME = .5
local MOUSE_MAG_THRESHOLD = 2

function PopupMenu:Destroy()
	self.Destructor:Destroy()
	self.EventHolder:Destroy()
	setmetatable(self,nil)
	self = nil
end

function PopupMenu:LoadContent(t)
	for i,v in pairs(self.Popup:GetChildren()) do
		if not v:IsA("UIListLayout") then
			v:Destroy()
		end
	end
	
	for i = 1,#t do
		local text = t[i] or ""
		local slot = UITemplates.PopupSlotTemplate:Clone()
		
		slot.Text.Text = text
		slot.Parent = self.Popup
	end
end

function PopupMenu:UpdatePosition()
	local absSize = self.Popup.AbsoluteSize
	local mousep = self.Widget:GetRelativeMousePosition()
	local pos = mousep + Vector2.new(absSize.X/2,-absSize.Y/2)
	
	self.Popup.Position = UDim2.fromOffset(pos.X,pos.Y)
end

function PopupMenu.new(Widget,Popup,Button)
	local self = setmetatable({},PopupMenu)
	local Events = {"Shown","Hidden"}
	local count = 0
	local lastPos = Vector2.new(-1,-1)
	local showing = false
	
	self.Destructor = Destructor.new()
	self.EventHolder = EventHolder.new(self,Events)
	self.Popup = Popup
	self.Widget = Widget
	self.Connections = {}
	
	Popup.Visible = false
	Popup.Parent = Widget
	
	self.Connections[1] = Button.MouseEnter:Connect(function()
		count = 0
		lastPos = Vector2.new(-1,-1)
		showing = false
		
		if self.Connections[3] then
			self.Connections[3]:Disconnect()
		end

		self.Connections[3] = RunService.RenderStepped:Connect(function()
			local mousep = Widget:GetRelativeMousePosition()
			local mag = (lastPos - mousep).Magnitude
			
			lastPos = mousep
			self:UpdatePosition()
			
			if showing then
				Popup.Visible = true
			end
			
			if mag > MOUSE_MAG_THRESHOLD then
				count = 0
			else
				count += 1
			end
			
			if count >= TRIGGER_TIME*60 then
				self:UpdatePosition()
				self.EventHolder:Fire("Shown")
				showing = true
			end	
		end)
	end)

	self.Connections[2] = Button.MouseLeave:Connect(function()
		showing = false
		Popup.Visible = false
		self.EventHolder:Fire("Hidden")
		
		if self.Connections[3] then
			self.Connections[3]:Disconnect()
		end
	end)
	
	self.Connections[4] = Button.AncestryChanged:Connect(function()
		if not Button or not Button.Parent then
			self:Destroy()
		end
	end)
	
	self.Destructor:Add(self.Connections)
	self.Destructor:Add(Popup)
	
	return self
end

return PopupMenu