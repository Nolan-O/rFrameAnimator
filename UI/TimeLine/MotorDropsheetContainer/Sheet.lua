local Sheet = {}
Sheet.__index = Sheet

local Network = shared.require("Network")
local Destructor = shared.require("Destructor")
local MenuContainer = shared.require("MenuContainer")
local MotorFrameTemplate = shared.UITemplates.MotorFrameTemplate
local OriginData = shared.require("OriginData")
local Configuration = shared.require("Configuration")

local ColorPalette = Configuration.ColorPalette

local MOTOR_SHEET_COLOR = ColorPalette.Blue
local SHEET_HIGHLIGHT_COLOR = ColorPalette.LightBlue
local RIG_SHEET_COLOR = ColorPalette.Orange

function Sheet:Destroy()
	self.Destructor:Destroy()
	setmetatable(self,nil)
end

function Sheet:SetHighlighted(bool)
	local ScaledFrame = self.ScaledFrame
	local isModel = self.Instance:IsA("Model")
	
	if isModel then
		ScaledFrame.BackgroundColor3 = RIG_SHEET_COLOR
		return
	end
	ScaledFrame.BackgroundColor3 = bool and SHEET_HIGHLIGHT_COLOR or MOTOR_SHEET_COLOR

	if bool then
		Network:Execute("AddSequenceToGraph", self.Instance)
	else
		Network:Execute("RemoveSequenceToGraph", self.Instance)
	end
end

function Sheet.new(Widget, inst, Parent, layers)
	local Grid = Parent:FindFirstChildOfClass("UIGridLayout")
	local Part1 = inst:IsA("Motor6D") and inst.Part1
	local Frame = MotorFrameTemplate:Clone()
	local ScaledFrame = Frame.ScaledFrame
	local goalSizeX = 1-(layers*.1)
	
	local self = setmetatable({},Sheet)
	self.Destructor = Destructor.new()
	self.Name = inst.Name
	self.Instance = inst
	self.Frame = Frame
	self.ScaledFrame = ScaledFrame
	self.Cons = {}

	ScaledFrame.Size = UDim2.new(math.clamp(goalSizeX, .25, 1), 0, 1, 0)
	ScaledFrame.Position = UDim2.new(math.clamp(1-goalSizeX/2, 0, .8), 0, .5, 0)
	ScaledFrame.MotorName.Text = inst.Name
	Frame.Name = inst.Name or ""
	Frame.Parent = Parent
	
	self.Cons[1] = Frame.MouseButton1Click:Connect(function()
		Network:Execute("SelectPart",Part1)
	end)
	
	self.Cons[2] = Frame.MouseButton2Click:Connect(function()
		if not inst:IsA("Motor6D") then return end
		local callbacks = {}
		
		callbacks["Add Blank KeyFrame"] = function()
			Network:Execute("AddBlankKeyFrames",0,{inst})
		end
		
		callbacks["Add Blank KeyFrame to all"] = function()
			local motors = {}
			
			for motor, _ in pairs(OriginData.Cache) do
				table.insert(motors,motor)
			end
			
			Network:Execute("AddBlankKeyFrames",0,motors)
		end
		
		local chosenAction = MenuContainer:Show("Sheet Menu")
		if chosenAction then
			local callback = callbacks[chosenAction.Text] if not callback then return end
			callback()
		end
	end)
	
	self.YPosition = Grid.AbsoluteContentSize.Y - Grid.CellSize.Y.Offset/2
	self:SetHighlighted(false)
	
	self.Destructor:Add(self.Cons)
	self.Destructor:Add(self.Frame)
	
	return self
end

return Sheet