local InputService = {}
InputService.__index = InputService

local UIS = game:GetService("UserInputService")

function InputService:FireBinds(source,key,state)
	for _,entryData in pairs(self.binds) do
		for _,entrySource in pairs(entryData.sources) do
			if entrySource == source then
				if entryData.key ~= key then continue end
				if entryData.state ~= state then continue end
				
				entryData.callback()
			end
		end
	end
end

function InputService:OnInput(source,input,state)
	if state == Enum.UserInputState.Begin then
		self.curPressing[input.KeyCode] = true
		self.curPressing[input.UserInputType] = true
	else
		self.curPressing[input.KeyCode] = false
		self.curPressing[input.UserInputType] = false
	end
	
	self:FireBinds(source,input.KeyCode,state)
	self:FireBinds(source,input.UserInputType,state)
end

function InputService:AddInputSource(source)
	source.InputBegan:Connect(function(input)
		self:OnInput(source,input,Enum.UserInputState.Begin)
	end)
	source.InputEnded:Connect(function(input)
		self:OnInput(source,input,Enum.UserInputState.End)
	end)
end

function InputService:ClearPressingKeys()
	for i,_ in pairs(self.curPressing) do
		self.curPressing[i] = false
	end
end

function InputService:IsKeyDown(key)
	return self.curPressing[key]
end

function InputService:BindToInput(sources:table,key,state,callback)
	table.insert(self.binds,{
		sources = sources,
		key = key,
		state = state,
		callback = callback,
	})
end

function Init()
	local self = setmetatable({},InputService)
	
	self.curPressing = {}
	self.binds = {}
	self.sourceContainer = {}
	
	for _,keyCode in pairs(Enum.KeyCode:GetEnumItems()) do
		self.curPressing[keyCode] = false
	end
	
	for _,inputType in pairs(Enum.UserInputType:GetEnumItems()) do
		self.curPressing[inputType] = false
	end
	
	UIS.InputBegan:Connect(function(input)
		self:OnInput("UserInputService",input,Enum.UserInputState.Begin)
	end)
	
	UIS.InputEnded:Connect(function(input)
		self:OnInput("UserInputService",input,Enum.UserInputState.End)
	end)
	
	return self
end

return Init()