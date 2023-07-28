local PopupPrompt = {}
PopupPrompt.__index = PopupPrompt

local TS = game:GetService("TweenService")

local TWEEN_TIME = .3

function PopupPrompt:Tween(open)
	local goalSize = open and UDim2.fromScale(.9,1) or UDim2.new()
	local startSize = open and UDim2.new() or UDim2.fromScale(.9,1)
	local goalTransparency = open and .5 or 1
	local startTransparency = open and 1 or .5
	
	self.UI.Window.Size = startSize
	self.UI.BackgroundTransparency = startTransparency
	
	TS:Create(
		self.UI.Window,
		TweenInfo.new(TWEEN_TIME,Enum.EasingStyle.Back,open and Enum.EasingDirection.Out or Enum.EasingDirection.In),
		{Size = goalSize}
	):Play()
	
	TS:Create(
		self.UI,
		TweenInfo.new(TWEEN_TIME,Enum.EasingStyle.Linear),
		{BackgroundTransparency = goalTransparency}
	):Play()
end

function PopupPrompt:Hide()
	for i,con in pairs(self.Cons) do
		con:Disconnect()
		self.Cons[i] = nil
	end
	
	self:Tween(false)
	self.Occupied = false
	
	task.delay(TWEEN_TIME,function()
		self.UI.Parent = script
	end)
end

function PopupPrompt:ShowAsync(widget, text:string, acceptCallback, declineCallback, acceptText, declineText, opt_default)
	if self.Occupied then return end
	self.Occupied = true
	
	self.UI.Window.Text.Text = text
	self.UI.Window.Confirm.Text.Text = acceptText or "Yes"
	self.UI.Window.Decline.Text.Text = declineText or "No"
	self.UI.Parent = widget

	local resolved = false
	
	local function resolve(callback)
		resolved = true
		callback()
		self:Hide()
	end

	local function accept()
		resolve(acceptCallback)
	end

	local function decline()
		resolve(declineCallback)
	end
	
	self.Cons[1] = self.UI.Window.Confirm.MouseButton1Click:Connect(accept)
	
	self.Cons[2] = self.UI.Window.Decline.MouseButton1Click:Connect(decline)
	
	self:Tween(true)
	
	repeat wait() until not self.Occupied or self.UI.Parent == script

	if resolved == false and opt_default ~= nil then
		if opt_default == true then
			accept()
		elseif opt_default == false then
			decline()
		end
	end
end

function Init()
	local self = setmetatable({},PopupPrompt)
	
	self.Cons = {}
	self.Occupied = false
	self.UI = script:WaitForChild("Popup")
	
	shared.Plugin.Deactivation:Connect(function()
		self:Hide()
	end)
	
	return self
end

return Init()