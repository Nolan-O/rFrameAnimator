local TimeLineGrid = {}

local Grids = {}

local function newGrid()
	local Grid = Instance.new("Frame")

	Grid.Name = "Grid"
	Grid.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
	Grid.BorderSizePixel = 0
	Grid.ZIndex = 2
	
	table.insert(Grids,Grid)
	
	return Grid
end

function TimeLineGrid.Clear()
	for _,inst in pairs(Grids) do
		inst:Destroy()
	end
	table.clear(Grids)
end

function TimeLineGrid.Update(Widget)
	local TimeLineFrame = Widget.TimeLine
	local KeyFrameEditor = TimeLineFrame.KeyFrameEditor
	local MotorDropSheet = TimeLineFrame.MotorDropSheet
	local TimeLine = KeyFrameEditor.TimeLine
	local Heading = KeyFrameEditor.KeyFrameEditorHeading
	local Grid = MotorDropSheet:FindFirstChildOfClass("UIGridLayout")
	local MotorDropSheetGrid = MotorDropSheet:FindFirstChildOfClass("UIGridLayout")
	
	local ContentSize = Grid.AbsoluteContentSize.Y
	
	local count = 1
	local usedGrids = {}
	
	for _,inst in pairs(Heading:GetChildren()) do
		local Grid = Grids[count] or newGrid()

		Grid.Size = UDim2.new(0,1,0,ContentSize)
		Grid.Position = UDim2.new(inst.Position.X,0,.5,0)
		Grid.Parent = TimeLine
		
		usedGrids[count] = Grid
		count += 1
	end
	for i = 1,#MotorDropSheet:GetChildren() do
		local inst = MotorDropSheet:GetChildren()[i]
		if not inst:IsA("GuiButton") then continue end

		local Grid = Grids[count] or newGrid()
		local Ypos = (MotorDropSheetGrid.CellSize.Y.Offset)*(i-1) + (MotorDropSheetGrid.CellPadding.Y.Offset)*(i-1.5)

		Grid.Size = UDim2.new(1,0,0,1)
		Grid.Position = UDim2.new(0,0,0,Ypos)
		Grid.Parent = TimeLine
		
		usedGrids[count] = Grid
		count += 1
	end
	
	for i,Grid in pairs(Grids) do
		if not usedGrids[i] then
			Grid:Destroy()
			Grids[i] = nil
		end
	end
end

return TimeLineGrid