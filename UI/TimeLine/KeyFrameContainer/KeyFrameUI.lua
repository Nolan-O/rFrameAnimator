local Destructor = shared.require("Destructor")
local UIUtils = shared.require("UIUtils")
local Configuration = shared.require("Configuration")
local PopupMenu = shared.require("PopupMenu")
local EventHolder = shared.require("EventHolder")

local UITemplates = shared.UITemplates
local Globals = shared.Globals
local framesPerSec = Globals.FramesPerSec

local ColorPalette = Configuration.ColorPalette
local HIGHLIGHT_COLOR = ColorPalette.LightBlue

local KeyFrameUI = {}
KeyFrameUI.__index = KeyFrameUI

function KeyFrameUI:Destroy()
	self.Popup:Destroy()
	self._event_holder:Destroy()
	self._destructor:Destroy()
	setmetatable(self,nil)
	self = nil
end

function KeyFrameUI:SetPosition(Position)
	self._frame.Position = Position
end

function KeyFrameUI:UpdateUI()
	self._frame.Border.Visible = self.IsSelected
	self._frame.Border.ImageColor3 = HIGHLIGHT_COLOR
	self._frame.Center.ImageColor3 = Configuration.EasingStyleColors[self.EasingStyle or "Linear"] or Color3.fromRGB(255,255,255)
end

function KeyFrameUI:Deselect()
	self.IsSelected = false
	self:UpdateUI()
end

function KeyFrameUI:Select()
	self.IsSelected = true
	self:UpdateUI()
	self._event_holder:Fire("Selected")
end

function KeyFrameUI.new(Parent,Widget,Pos,KeyFrame)
	local self = setmetatable({},KeyFrameUI)
	local Frame = UITemplates.KeyFrameTemplate:Clone()
	local Popup = UITemplates.PopupTemplate:Clone()
	local Id = KeyFrame.Id
	local holding = false
	
	self.Popup = PopupMenu.new(Widget,Popup,Frame)
	self._destructor = Destructor.new()
	self._event_holder = EventHolder.new(self,{"DragEnded","Dragging","Selected","RightClicked"})
	self._frame = Frame
	
	self.IsSelected = false
	self.Id = Id
	self.EasingStyle = KeyFrame.EasingStyle or "Linear"
	self.EasingDirection = KeyFrame.EasingDirection or "In"
	
	Frame.Position = Pos
	Frame.ZIndex = 6
	Frame.Border.ZIndex = 5
	Frame.Center.ZIndex = 6
	Frame.Name = Id
	Frame.Parent = Parent
	
	self._destructor:Add(Frame)
	
	self._destructor:Add(Frame.MouseButton1Down:Connect(function()
		self:Select()
		holding = true
		UIUtils.CatchDrop(Widget,function()
			holding = false
			self._event_holder:Fire("DragEnded")
		end)
		local lastPosition = Frame.Position
		while holding and wait() do
			if not getmetatable(self) then break end
			local absSize = Parent.AbsoluteSize
			local absPos = Parent.AbsolutePosition
			local mousep = (Widget:GetRelativeMousePosition()-absPos)
			local XScale = mousep.X/absSize.X
			local roundedXScale = UIUtils.SnapUI(XScale)
			
			XScale = math.clamp(roundedXScale,0,1)
			Frame.Position = UDim2.new(XScale,0,0,Frame.Position.Y.Offset)
			self._event_holder:Fire("Dragging",Frame.Position - lastPosition)
			lastPosition = Frame.Position
		end
	end))
	
	self._destructor:Add(Frame.MouseButton2Click:Connect(function()
		self:Select()
		self._event_holder:Fire("RightClicked")
	end))
	
	self._destructor:Add(self.Popup.Shown:Connect(function()
		local data = {
			[1] = "EasingStyle: "..self.EasingStyle,
			[2] = "EasingDirection: "..self.EasingDirection,
		}
		
		self.Popup:LoadContent(data)
	end))
	
	self:Deselect()
	
	return self
end

return KeyFrameUI
