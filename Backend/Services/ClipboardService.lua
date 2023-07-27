local ClipboardService = {}
ClipboardService.__index = ClipboardService

local Serialization = shared.require("Serialization")
local plugin = shared.Plugin

function ClipboardService:Get()
	return self.Cache
end

function ClipboardService:Set(t)
	self.Cache = t
end

local function Init()
	local self = setmetatable({},ClipboardService)
	
	self.Cache = plugin:GetSetting("Clipboard") or {}
	
	plugin.Deactivation:Connect(function()
		plugin:SetSetting("Clipboard",self.Cache or {})
	end)
	
	return self
end

return Init()