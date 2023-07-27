return {
	TimeLineWigetInfo = DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Bottom,  -- Widget will be initialized in floating panel
		true,   -- Widget will be initially enabled
		false,  -- Don't override the previous enabled state
		450,    -- Default width of the floating window
		300,    -- Default height of the floating window
		0,    -- Minimum width of the floating window (optional)
		0     -- Minimum height of the floating window (optional)
	),
	
	GraphEditorInfo = DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Left,  -- Widget will be initialized in floating panel
		true,   -- Widget will be initially enabled
		false,  -- Don't override the previous enabled state
		270,    -- Default width of the floating window
		350,    -- Default height of the floating window
		270,    -- Minimum width of the floating window (optional)
		350     -- Minimum height of the floating window (optional)
	),
	
	MenuInfo = DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Right,  -- Widget will be initialized in floating panel
		true,   -- Widget will be initially enabled
		false,  -- Don't override the previous enabled state
		240,    -- Default width of the floating window
		350,    -- Default height of the floating window
		240,    -- Minimum width of the floating window (optional)
		350     -- Minimum height of the floating window (optional)
	),
	
	EasingStyleColors = {
		Linear = Color3.fromRGB(255, 255, 255),
		Sine = Color3.fromRGB(255, 255, 127),
		Back = Color3.fromRGB(255, 255, 0),
		Quad = Color3.fromRGB(199, 183, 0),
		Quart = Color3.fromRGB(255, 106, 0),
		Quint = Color3.fromRGB(255, 51, 0),
		Bounce = Color3.fromRGB(197, 0, 0),
		Elastic = Color3.fromRGB(0, 255, 102),
		Exponential = Color3.fromRGB(4, 255, 0),
		Circular = Color3.fromRGB(18, 185, 0),
		Cubic = Color3.fromRGB(255, 0, 196),
		Constant = Color3.fromRGB(164, 0, 223),
	},
	
	Cooldowns = {
		Save = 2,
		Export = 3,
		Import = 1,
		New = 3,
	},
	
	GraphEditorConfig = {
		MaxDimension = 2.9,
		MinDimension = .1,
		DimensionStep = .1,
		
		DefaultGridSize = Vector2.new(80,80),
		DefaultSize = Vector2.new(2000,2000),
		DefaultStepSize = Vector2.new(5,1),
		
		GridSize = Vector2.new(80,80),
		StepSize = Vector2.new(5,1),
		
		AxisColors = {
			X = Color3.fromRGB(204, 52, 25),
			Y = Color3.fromRGB(41, 223, 53),
			Z = Color3.fromRGB(38, 153, 229),
		},
		
		DisplayTypeColor = Color3.fromRGB(0, 157, 255),
	},
	
	ColorPalette = {
		Blue = Color3.fromRGB(0, 157, 255),
		LightBlue = Color3.fromRGB(53, 181, 255),
		Orange = Color3.fromRGB(255, 157, 0),
	},
	
	PluginVersion = .5,
	
	MinAnimationLength = 10,
	MaxAnimationLength = 1000,
	
	MinFrameRate = 12,
	MaxFrameRate = 60,
	
	DefaultFramesPerSec = 60,
	DefaultAnimationLength = 60,
	DefaultAnimationPriority = "Action",
	
	DefaultEasingStyle = "Linear",
	DefaultEasingDirection = "In",
	
	AutoSaveName = "rFrameAutoSafe",
}