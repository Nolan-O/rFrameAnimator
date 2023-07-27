local GraphEditorGrid = {}

local UITemplates = shared.UITemplates
local Globals = shared.Globals

local UIUtils = shared.require("UIUtils")
local Configuration = shared.require("Configuration")
local GraphUtils = shared.require("GraphUtils")

local Widget = nil

local Grids = {}
local Stamps = {}

local function ClearTable(t)
	for _,inst in pairs(t) do
		inst:Destroy()
	end
	table.clear(t)
end

local function NewGrid()
	local G = Instance.new("Frame")
	G.BorderSizePixel = 0
	G.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
	G.ZIndex = 1
	G.Name = "Grid"
	G.AnchorPoint = Vector2.new(.5,.5)
	
	table.insert(Grids,G)
	
	return G
end

function GraphEditorGrid.UpdateGrid(Background,xAmount,yAmount,gridSize)
	local defaultSize = Configuration.GraphEditorConfig.DefaultSize
	local StepSize = Configuration.GraphEditorConfig.StepSize
	local Content = Background.Content
	
	local absSize = Background.AbsoluteSize
	local absPos = Background.AbsolutePosition
	local offset = Vector2.new(Content.Position.X.Offset,Content.Position.Y.Offset)
	
	local remainingXScale = (offset.X - gridSize.X * math.floor(offset.X/gridSize.X))--/absSize.X
	local remainingYScale = (offset.Y - gridSize.Y * math.floor(offset.Y/gridSize.Y))--/absSize.Y
	
	for i = 1,yAmount do -- left
		local normalPos = gridSize.Y*(i-1)
		local addedPos = normalPos + remainingYScale
		local Grid = Grids[i]
		
		local representedValue = math.floor((offset.Y - addedPos) / gridSize.Y) * StepSize.Y
		local lineThickness = math.abs(representedValue) == 0 and 2 or 1
		
		Grid.Position = UDim2.new(.5,0,0,addedPos)
		Grid.Size = UDim2.new(1,0,0,lineThickness)
		Grid.Parent = Background
	end
	
	for i = 1,xAmount do -- top
		local normalPos = gridSize.X*(i-1)
		local addedPos = normalPos + remainingXScale
		local Grid = Grids[yAmount+i]
		
		local representedValue = math.floor((offset.X - addedPos) / gridSize.X) * StepSize.X
		local lineThickness = math.abs(representedValue) == 0 and 2 or 1
		
		Grid.Position = UDim2.new(0,addedPos,.5,0)
		Grid.Size = UDim2.new(0,lineThickness,1,0)
		Grid.Parent = Background
	end
end

function GraphEditorGrid.UpdateTimeStamps(Background,gridSize)
	local defaultSize = Configuration.GraphEditorConfig.DefaultSize
	local StepSize = Configuration.GraphEditorConfig.StepSize
	
	local Content = Background.Content
	local TopBorder = Background.TopBorder
	local LeftBorder = Background.LeftBorder
	
	local usedStamps = {}
	
	local offset = Vector2.new(Content.Position.X.Offset,Content.Position.Y.Offset)
	
	local leftPos = Vector2.new(LeftBorder.Position.X.Offset,LeftBorder.Position.Y.Offset)
	local topPos = Vector2.new(TopBorder.Position.X.Offset,TopBorder.Position.Y.Offset)
	
	for i = 1,#Grids do
		local Grid = Grids[i]
		local Stamp = Stamps[i] or UITemplates.TimeStampTemplate:Clone()
		
		local gridPos = Vector2.new(Grid.Position.X.Offset,Grid.Position.Y.Offset)
		
		Stamp.Name = "Stamp"
		Stamp.Size = UDim2.new(1,0,0,13)
		
		Stamps[i] = Stamp
		usedStamps[i] = Stamp
		
		if Grid.Size.X.Scale > Grid.Size.Y.Scale then
			-- left
			local Text = math.floor((offset.Y - gridPos.Y) / gridSize.Y) * StepSize.Y
			local pos = Grid.Position
			
			Stamp.Text = math.round(Text*100)/100
			Stamp.Position = UDim2.fromOffset(leftPos.X,gridPos.Y)
			Stamp.Parent = Background
		else
			-- top
			local Text = -math.floor((offset.X - gridPos.X) / gridSize.X) * StepSize.X
			local pos = Grid.Position
			
			Stamp.Text = math.round(Text*100)/100
			Stamp.Position = UDim2.fromOffset(gridPos.X,topPos.Y)
			Stamp.Parent = Background
		end
	end
	
	for i,Stamp in pairs(Stamps) do
		if not usedStamps[i] then
			Stamps[i]:Destroy()
			Stamps[i] = nil
		end
	end
	table.clear(usedStamps)
end

function GraphEditorGrid.Update(Data,ratio)
	local EasingStyleFrame = Widget.GraphEditor
	local Background = EasingStyleFrame.Background
	local Content = Background.Content
	
	local absSize = Background.AbsoluteSize
	local contentSize = Vector2.new(Content.Size.X.Offset,Content.Size.Y.Offset)
	local gridSize = Configuration.GraphEditorConfig.GridSize
	
	local gridMultiplier = 1 + ratio - math.floor(ratio)
	local adjustedGridSize = gridSize * gridMultiplier
	
	local yAmount = math.ceil(absSize.Y/adjustedGridSize.Y)
	local xAmount = math.ceil(absSize.X/adjustedGridSize.X)
	
	if #Grids ~= yAmount + xAmount then
		local diff = #Grids - (xAmount + yAmount)
		for i = 1,math.abs(diff) do
			if diff > 0 then
				Grids[#Grids]:Destroy()
				Grids[#Grids] = nil
			else
				NewGrid()
			end
		end
	end
	
	GraphEditorGrid.UpdateGrid(Background,xAmount,yAmount,adjustedGridSize)
	GraphEditorGrid.UpdateTimeStamps(Background,adjustedGridSize)
end

function GraphEditorGrid.Init(createdWidget)
	Widget = createdWidget
end

return GraphEditorGrid