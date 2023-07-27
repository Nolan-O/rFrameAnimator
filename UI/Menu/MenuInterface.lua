local MenuInterface = {}

local TS = game:GetService("TweenService")

local Configuration = shared.require("Configuration")
local Network = shared.require("Network")
local Cooldowns = shared.require("Cooldowns")

local Globals = shared.Globals
local Templates = shared.UITemplates
local plugin = shared.Plugin
local MenuWidget = shared.MenuWidget

local MenuFrame = MenuWidget.Menu
local Scrolling = MenuFrame.Scrolling
local ButtonFrame = MenuFrame.ButtonFrame
local SaveButton = ButtonFrame.Save
local ExportButton = ButtonFrame.Export
local LoadButton = ButtonFrame.Load
local ExitButton = ButtonFrame.Exit
local NewButton = ButtonFrame.New
local SettingsButton = ButtonFrame.Settings

function DisplayCooldown(Text,Cooldown)
	Cooldown -= .1
	
	coroutine.wrap(function()
		local beforeText = Text.Text
		
		local stepInterval = .1
		local steps = Cooldown/stepInterval
		
		for i = 1, steps do
			Text.Text = tostring(Cooldown - i * stepInterval)
			wait(stepInterval)
		end
		
		Text.Text = beforeText
	end)()
end

function ButtonClickEffect(Button)
	local circle = Instance.new("Frame")
	local corner = Instance.new("UICorner",circle)
	local aspect = Instance.new("UIAspectRatioConstraint",circle)	
	local mousep = MenuWidget:GetRelativeMousePosition() - Button.AbsolutePosition
	
	corner.CornerRadius = UDim.new(1,0)
	
	circle.Size = UDim2.fromScale(0,0)
	circle.BackgroundColor3 = Color3.fromRGB(255,255,255)
	circle.AnchorPoint = Vector2.new(.5,.5)
	circle.BackgroundTransparency = .5
	circle.ZIndex = 100
	circle.Position = UDim2.fromOffset(mousep.X,mousep.Y)
	circle.Parent = Button
	
	local info = TweenInfo.new(.7,Enum.EasingStyle.Quart)
	local goal = {Size = UDim2.fromScale(10,10)}
	local SizeTween = TS:Create(circle,info,goal)
	
	local info = TweenInfo.new(.7,Enum.EasingStyle.Quart)
	local goal = {BackgroundTransparency = 1}
	local TransparencyTween = TS:Create(circle,info,goal)
	
	SizeTween:Play()
	TransparencyTween:Play()
	game:GetService("Debris"):AddItem(circle,.7)
end

function ForceNumber(TextBox,dez,min,max,onChange)
	local lastText = TextBox.Text
	local isFocusing = false
	
	TextBox:GetPropertyChangedSignal("Text"):Connect(function()
		if not isFocusing then
			lastText = TextBox.Text
		end
	end)
	
	TextBox.Focused:Connect(function()
		isFocusing = true
	end)
	
	TextBox.FocusLost:Connect(function()
		local newText = TextBox.Text
		if newText == lastText then return end
		
		if newText == "" then
			TextBox.Text = lastText
			return
		end
		
		if type(tonumber(newText)) == "number" then
			local number = tonumber(newText)
			number = math.round(number*dez)/dez
			
			if number < min then
				number = min
			end
			
			if number > max then
				number = max
			end
			
			lastText = tostring(number)
			TextBox.Text = lastText
			onChange(number)
		end
		
		isFocusing = false
	end)
end

function CreateDropDown(Frame,callback)
	local dropDown = Frame.DropDown
	local buttons = Frame.DropDown.Buttons
	local openButton = Frame.OpenButton
	
	openButton.MouseButton1Click:Connect(function()
		dropDown.Visible = not dropDown.Visible
	end)
	
	dropDown:GetPropertyChangedSignal("Visible"):Connect(function()
		openButton.BackgroundColor3 = dropDown.Visible and Color3.fromRGB(53, 181, 255) or Color3.fromRGB(26, 26, 26)
	end)
	
	for _,button in pairs(buttons:GetChildren()) do
		if not button:IsA("GuiButton") then continue end
		button.MouseButton1Click:Connect(function()
			callback(button.Text)
			dropDown.Visible = false
		end)
	end
	
	dropDown.Visible = false
end

function MenuInterface.Update(curAnimation,selectedRig)
	local framesPerSec = curAnimation.FramesPerSec or Configuration.DefaultFramesPerSec
	local length = curAnimation.Length or Configuration.DefaultAnimationLength
	local name = curAnimation.Name or "Animation"
	
	Scrolling.AnimationName.Box.Text = name
	Scrolling.Framerate.Box.Text = framesPerSec
	Scrolling.Length.Box.Text = length
	Scrolling.Looped.Button.Dot.Visible = curAnimation.Looped
	Scrolling.Priority.OpenButton.Box.Text = curAnimation.Priority
	
	Globals.FramesPerSec.Value = framesPerSec
	Globals.maxTimePosition.Value = length
	
	Scrolling.Priority.DropDown.Visible = false
end

function MenuInterface.Build()
	local ConfigCools = Configuration.Cooldowns
	local SaveCool = ConfigCools.Save
	local ExportCool = ConfigCools.Export
	local ImportCool = ConfigCools.Import
	local NewCool = ConfigCools.New
	
	SaveButton.MouseButton1Click:Connect(function()
		if Cooldowns:Check("Save") then return end
		Cooldowns:Add("Save",SaveCool)
		
		ButtonClickEffect(SaveButton)
		DisplayCooldown(SaveButton.Text,SaveCool)
		Network:Execute("SaveAnimation")
	end)
	
	ExportButton.MouseButton1Click:Connect(function()
		if Cooldowns:Check("Export") then return end
		Cooldowns:Add("Export",ExportCool)
		
		ButtonClickEffect(ExportButton)
		DisplayCooldown(ExportButton.Text,SaveCool)
		Network:Execute("ExportAnimation")
	end)
	
	ExitButton.MouseButton1Click:Connect(function()
		ButtonClickEffect(ExitButton)
		Network:Execute("ExitPlugin")
	end)
	
	LoadButton.MouseButton1Click:Connect(function()
		if Cooldowns:Check("Import") then return end
		Cooldowns:Add("Import",ImportCool)
		
		ButtonClickEffect(LoadButton)
		DisplayCooldown(LoadButton.Text,ImportCool)
		Network:Execute("LoadAnimation")
	end)
	
	NewButton.MouseButton1Click:Connect(function()
		if Cooldowns:Check("New") then return end
		Cooldowns:Add("New",NewCool)
		
		ButtonClickEffect(NewButton)
		DisplayCooldown(NewButton.Text,NewCool)
		Network:Execute("CreateNewAnimation")
	end)
	
	SettingsButton.MouseButton1Click:Connect(function()
		if Cooldowns:Check("Settings") then return end
		Cooldowns:Add("Settings",NewCool)

		ButtonClickEffect(SettingsButton)
		DisplayCooldown(SettingsButton.Text,NewCool)
		--Network:Execute("CreateNewAnimation")
	end)
	
	Scrolling.AnimationName.Box.FocusLost:Connect(function()
		Network:Execute("ChangeAnimationName",Scrolling.AnimationName.Box.Text)
	end)
	
	ForceNumber(Scrolling.Length.Box,10,Configuration.MinAnimationLength,Configuration.MaxAnimationLength,function()
		Network:Execute("ChangeAnimationLength",Scrolling.Length.Box.Text)
	end)
	
	ForceNumber(Scrolling.Framerate.Box,1,Configuration.MinFrameRate,Configuration.MaxFrameRate,function()
		local newFramesPerSec = tonumber(Scrolling.Framerate.Box.Text)
		Network:Execute("ChangeFramesPerSec",newFramesPerSec)
	end)
	
	CreateDropDown(Scrolling.Priority,function(newPriority)
		Network:Execute("ChangePriority",newPriority)
	end)
	
	for _,box in pairs({Scrolling.Length.Box,Scrolling.AnimationName.Box,Scrolling.Framerate.Box}) do
		local outer = box.Parent.Outer
		box.Focused:Connect(function()
			outer.BackgroundColor3 = Color3.fromRGB(53, 181, 255)
		end)
		box.FocusLost:Connect(function()
			outer.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
		end)
	end
	
	Scrolling.Looped.Button.MouseButton1Click:Connect(function()
		local dot = Scrolling.Looped.Button.Dot
		dot.Visible = not dot.Visible
		Network:Execute("ToggleLooping")
	end)
end

return MenuInterface