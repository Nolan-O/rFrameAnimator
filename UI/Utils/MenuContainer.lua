local MenuContainer = {}
MenuContainer.__index = MenuContainer

local plugin = shared.Plugin

local Actions = {
	"Constant",
	
	"Cut Selected",
	"Copy Selected",
	"Paste KeyFrames",
	"Delete Selected",
	"Reset Selected",
	
	"Add KeyFrame here",
	"Add Blank KeyFrame",
	"Add Blank KeyFrame to all",
	
	"Add Node",
	"Reset",
	
	"Jump to",
	"Toggle Bezier",
	"Edit Graph",
}

for _,Style in next,Enum.EasingStyle:GetEnumItems() do
	local Name = string.gsub(tostring(Style),"Enum.EasingStyle.","")
	table.insert(Actions,Name)
end

for _,Style in next,Enum.EasingDirection:GetEnumItems() do
	local Name = string.gsub(tostring(Style),"Enum.EasingDirection.","")
	table.insert(Actions,Name)
end

function MenuContainer:Show(MenuName)
	for _,Menu in pairs(self.Menus) do
		if Menu.Name ~= MenuName then continue end
		return Menu:ShowAsync()
	end
end

function MenuContainer:CreateGraphNodeMenu()
	local GraphNodeMenu = plugin:CreatePluginMenu(math.random(), "GraphNodeMenu")
	GraphNodeMenu.Name = "Graph Node Menu"
	--GraphNodeMenu:AddAction(self.Actions["Toggle Bezier"])
	GraphNodeMenu:AddAction(self.Actions["Reset"])
	GraphNodeMenu:AddSeparator()
	GraphNodeMenu:AddAction(self.Actions["Delete Selected"])

	table.insert(self.Menus,GraphNodeMenu)
end

function MenuContainer:CreateContentMenu()
	local ContentMenu = plugin:CreatePluginMenu(math.random(), "ContentMenu")
	ContentMenu.Name = "Content Menu"
	ContentMenu:AddAction(self.Actions["Add Node"])
	ContentMenu:AddAction(self.Actions["Delete Selected"])

	table.insert(self.Menus,ContentMenu)
end

function MenuContainer:CreateSheetMenu()
	local SheetMenu = plugin:CreatePluginMenu(math.random(), "SheetMenu")
	
	SheetMenu.Name = "Sheet Menu"
	SheetMenu:AddAction(self.Actions["Add Blank KeyFrame"])
	SheetMenu:AddAction(self.Actions["Add Blank KeyFrame to all"])
	
	table.insert(self.Menus,SheetMenu)
end

function MenuContainer:CreateTimeLineMenu()
	local TimeLineMenu = plugin:CreatePluginMenu(math.random(), "TimeLineMenu")

	TimeLineMenu.Name = "TimeLine Menu"
	TimeLineMenu:AddAction(self.Actions["Add KeyFrame here"])
	TimeLineMenu:AddSeparator()
	TimeLineMenu:AddAction(self.Actions["Reset Selected"])
	TimeLineMenu:AddAction(self.Actions["Cut Selected"])
	TimeLineMenu:AddAction(self.Actions["Copy Selected"])
	TimeLineMenu:AddAction(self.Actions["Paste KeyFrames"])
	TimeLineMenu:AddAction(self.Actions["Delete Selected"])
	
	table.insert(self.Menus,TimeLineMenu)
end

function MenuContainer:CreateKeyFrameMenu()
	local KeyFrameMenu = plugin:CreatePluginMenu(math.random(), "KeyFrameMenu")
	local EasingStyleSub = plugin:CreatePluginMenu(math.random(), "Change Easing Style", "")
	local EasingDirectionSub = plugin:CreatePluginMenu(math.random(), "Change Easing Direction", "")

	KeyFrameMenu.Name = "KeyFrame Menu"
	EasingStyleSub.Name = "Easing Style Sub"
	EasingDirectionSub.Name = "Easing Direction Sub"
	
	KeyFrameMenu:AddAction(self.Actions["Reset Selected"])
	KeyFrameMenu:AddAction(self.Actions["Cut Selected"])
	KeyFrameMenu:AddAction(self.Actions["Copy Selected"])
	KeyFrameMenu:AddAction(self.Actions["Delete Selected"])
	KeyFrameMenu:AddAction(self.Actions["Jump to"])
	KeyFrameMenu:AddSeparator()
	KeyFrameMenu:AddMenu(EasingStyleSub)
	KeyFrameMenu:AddMenu(EasingDirectionSub)
	
	for _,Style in next,Enum.EasingStyle:GetEnumItems() do
		local Name = string.gsub(tostring(Style),"Enum.EasingStyle.","")
		EasingStyleSub:AddAction(self.Actions[Name])
	end
	
	EasingStyleSub:AddAction(self.Actions["Constant"])
	
	for _,Style in next,Enum.EasingDirection:GetEnumItems() do
		local Name = string.gsub(tostring(Style),"Enum.EasingDirection.","")
		EasingDirectionSub:AddAction(self.Actions[Name])
	end
	
	table.insert(self.Menus,KeyFrameMenu)
	table.insert(self.Menus,EasingStyleSub)
	table.insert(self.Menus,EasingDirectionSub)
end

function Init()
	local self = setmetatable({},MenuContainer)
	
	self.Menus = {}
	self.Actions = {}
	
	for _,ActionName in next,Actions do
		local Action = plugin:CreatePluginAction(ActionName,ActionName,"")
		self.Actions[ActionName] = Action
	end
	
	self:CreateKeyFrameMenu()
	self:CreateTimeLineMenu()
	self:CreateSheetMenu()
	self:CreateContentMenu()
	self:CreateGraphNodeMenu()
	
	return self
end

return Init()