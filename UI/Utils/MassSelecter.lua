local MassSelecter = {}
MassSelecter.__index = MassSelecter

local RunService = game:GetService("RunService")

local Destructor = shared.require("Destructor")
local EventHolder = shared.require("EventHolder")
local UITemplates = shared.UITemplates

function HasProp(inst,prop)
	local succ = pcall(function()
		inst[prop] = inst[prop]
	end)
	return succ
end

function EvenNum(num)
	if num/2 ~= math.floor(num/2) then
		return num+1
	else
		return num
	end
end

function MassSelecter:Destroy()
	self.EventHolder:Destroy()
	self.Destructor:Destroy()
	setmetatable(self,nil)
end

function MassSelecter:IsOverlapping(UI)
	local Frame1 = UI
	local Frame2 = self.MassSelectFrame
	
	local F1sizeX,F2sizeX = Frame1.AbsoluteSize.X,Frame2.AbsoluteSize.X
	local F1posX,F2posX = Frame1.AbsolutePosition.X,Frame2.AbsolutePosition.X + F2sizeX/2

	local Xdistance = math.abs(F1posX-F2posX+F1sizeX/2)
	local minXdistance = math.abs(F2sizeX/2)

	local F1sizeY,F2sizeY = Frame1.AbsoluteSize.Y,Frame2.AbsoluteSize.Y
	local F1posY,F2posY = Frame1.AbsolutePosition.Y,Frame2.AbsolutePosition.Y + F2sizeY/2

	local Ydistance = math.abs(F1posY-F2posY+F1sizeY/2)
	local minYdistance = math.abs(F2sizeY/2)
	
	if Ydistance < minYdistance and Xdistance < minXdistance then return true end

	return false
end

function MassSelecter:Update()
	local CanvasPos = HasProp(self.Parent,"CanvasPosition") and self.Parent.CanvasPosition
	local CanPosX = CanvasPos and CanvasPos.X or 0
	local CanPosY = CanvasPos and CanvasPos.Y or 0
	
	local curPos = self.Widget:GetRelativeMousePosition()
	local mag = EvenNum((self.startPos - curPos).magnitude)
	local Unit = (curPos - self.startPos).Unit
	local goalPos = self.startPos + Unit*(mag/2) + Vector2.new(CanPosX, CanPosY)/2 + self.startCanvasPos/2 - self.Parent.AbsolutePosition
	local ySize = self.startPos.Y - curPos.Y - CanPosY + self.startCanvasPos.Y
	local xSize = self.startPos.X - curPos.X - CanPosX + self.startCanvasPos.X
	
	self.MassSelectFrame.Size = UDim2.fromOffset(xSize, ySize)
	self.MassSelectFrame.Position = UDim2.fromOffset(goalPos.X, goalPos.Y)
	
	self.EventHolder:Fire("Updated")
end

function MassSelecter.new(Widget,Parent)
	local self = setmetatable({},MassSelecter)
	local MassSelectFrame = UITemplates.MassSelectTemplate:Clone()
	local startPos = Widget:GetRelativeMousePosition()
	local EventHolderObj = EventHolder.new(self,{"Updated"})
	local CanvasPos = HasProp(Parent,"CanvasPosition") and Parent.CanvasPosition
	local CanPosX = CanvasPos and CanvasPos.X or 0
	local CanPosY = CanvasPos and CanvasPos.Y or 0
	
	self.Widget = Widget
	self.Parent = Parent
	self.MassSelectFrame = MassSelectFrame
	
	self.Destructor = Destructor.new()
	self.EventHolder = EventHolderObj
	
	self.startPos = startPos
	self.startCanvasPos = Vector2.new(CanPosX,CanPosY)
	
	self.con = RunService.RenderStepped:Connect(function()
		self:Update()
	end)
	
	self.Destructor:Add(self.MassSelectFrame)
	self.Destructor:Add(self.con)
	self:Update()
	
	MassSelectFrame.Parent = Parent
	
	return self
end

return MassSelecter