local KeyFrameContainer = {}
KeyFrameContainer.__index = KeyFrameContainer

local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local SelectionService = game:GetService("Selection")

local KeyFrameUI = shared.require("KeyFrameUI")
local MotorDropsheetContainer = shared.require("MotorDropsheetContainer")
local Network = shared.require("Network")
local UIUtils = shared.require("UIUtils")
local MassSelecter = shared.require("MassSelecter")
local GraphEditorInterface = shared.require("GraphEditorInterface")
local MenuContainer = shared.require("MenuContainer")
local ClipboardService = shared.require("ClipboardService")
local PopupMenu = shared.require("PopupMenu")
local OriginData = shared.require("OriginData")
local InputService = shared.require("InputService")
local SavePointService = shared.require("SavePointService")

local Widget = shared.TimeLineWidget
local plugin = shared.Plugin
local UITemplates = shared.UITemplates
local Globals = shared.Globals
local curTimePosition = Globals.curTimePosition
local maxTimePosition = Globals.maxTimePosition
local framesPerSec = Globals.FramesPerSec

local TimeLineFrame = Widget.TimeLine
local KeyFrameEditor = TimeLineFrame.KeyFrameEditor
local TimeLine = KeyFrameEditor.TimeLine
local inputCatcher = Widget.inputCatcher

local curSelected = {}
local curPressingKeys = {}
local KeyFrameCache = {}
local keyFramesToCopy = {}

local isMassSelecting = false

function IsPressing(KeyCode)
	return table.find(curPressingKeys,KeyCode) ~= nil
end

function DeselectAll()
	for i,Selected in pairs(curSelected) do
		Selected:Deselect()
		curSelected[i] = nil
	end
end

function SelectAllInRange(MassSelecterObj)
	for id,entry in pairs(KeyFrameCache) do
		local keyFrameUIObj = entry.Obj
		local keyFrame = keyFrameUIObj._frame
		
		if MassSelecterObj:IsOverlapping(keyFrame) then
			keyFrameUIObj:Select()
			if table.find(curSelected,keyFrameUIObj) == nil then
				table.insert(curSelected,keyFrameUIObj)
			end
		end
	end
end

function MassSelect()
	local MassSelecterObj = MassSelecter.new(Widget,TimeLine)
	local con
	
	isMassSelecting = true
	
	con = MassSelecterObj.Updated:Connect(function()
		DeselectAll()
		SelectAllInRange(MassSelecterObj)
	end)
	
	UIUtils.CatchDrop(Widget,function()
		con:Disconnect()
		isMassSelecting = false
		MassSelecterObj:Destroy()
	end)
end

function DeleteSelected()
	local toDelete = {}
	for _,KeyFrameUIObj in pairs(curSelected) do
		table.insert(toDelete,KeyFrameUIObj.Id)
	end
	for i,v in pairs(keyFramesToCopy) do
		-- delete refference to keyframes in copy table
		if table.find(curSelected,v) == nil then continue end
		keyFramesToCopy[i] = nil
	end
	Network:Execute("DeleteKeyFramesById",toDelete)
end

function PasteSelected()
	Network:Execute("PasteKeyFrames")
end

function CopySelected()
	local smallestTimePos = math.huge
	for _,KeyFrame in pairs(curSelected) do
		local framePosX = KeyFrame._frame.Position.X.Scale
		if framePosX < smallestTimePos then
			smallestTimePos = framePosX
		end
	end
	smallestTimePos = maxTimePosition.Value*smallestTimePos

	local copyTable = {}
	for i,KeyFrame in pairs(curSelected) do
		local Frame = KeyFrame._frame
		local timePos = maxTimePosition.Value*Frame.Position.X.Scale

		copyTable[KeyFrame.Id] = math.round(timePos)
	end
	
	Network:Execute("CopyKeyFrames",copyTable)
end

function ResetSelected()
	local Ids = {}
	for _,keyframeObj in pairs(curSelected) do
		table.insert(Ids,keyframeObj.Id)
	end
	Network:Execute("ResetKeyFrames",Ids)
end

function ChangeSelectedEasingStyle(EasingStyle)
	local Ids = {}
	for i,KeyFrameUIObj in pairs(curSelected) do
		KeyFrameUIObj.EasingStyle = EasingStyle
		table.insert(Ids,KeyFrameUIObj.Id)
	end
	DeselectAll()
	Network:Execute("ChangeEasingStyle",Ids,EasingStyle)
end

function AddKeyFrameAtMousePos()
	local absSize,absPos = KeyFrameEditor.AbsoluteSize,KeyFrameEditor.AbsolutePosition
	local mousep = Widget:GetRelativeMousePosition() - absPos
	
	local timePos = math.round((mousep.X/absSize.X) * maxTimePosition.Value)
	local sheet = MotorDropsheetContainer.GetSheetAtYPos(mousep.Y)
	local motor = sheet and sheet.Instance if not motor or not motor:IsA("Motor6D") then return end
	
	Network:Execute("AddKeyFrameAtTimePos",timePos,motor)
end

function ChangeSelectedEasingDirection(EasingDirection)
	local Ids = {}
	for i,KeyFrameUIObj in pairs(curSelected) do
		KeyFrameUIObj.EasingDirection = EasingDirection
		table.insert(Ids,KeyFrameUIObj.Id)
	end
	DeselectAll()
	Network:Execute("ChangeEasingDirection",Ids,EasingDirection)
end

function ShowKeyFrameMenu(KeyFrame,KeyFrameUI)
	local callbacks = {
		["Reset Selected"] = function()
			ResetSelected()
		end,
		["Cut Selected"] = function()
			CopySelected()
			DeleteSelected()
		end,
		["Copy Selected"] = function()
			CopySelected()
		end,
		["Delete Selected"] = function()
			DeleteSelected()
		end,
		["Jump to"] = function()
			curTimePosition.Value = KeyFrame.TimePosition or 0
		end,
		["Constant"] = function()
			ChangeSelectedEasingStyle("Constant")
		end,
	}
	
	for _,Style in next,Enum.EasingStyle:GetEnumItems() do
		local Name = string.gsub(tostring(Style),"Enum.EasingStyle.","")
		callbacks[Name] = function()
			ChangeSelectedEasingStyle(Name)
		end
	end

	for _,Style in next,Enum.EasingDirection:GetEnumItems() do
		local Name = string.gsub(tostring(Style),"Enum.EasingDirection.","")
		callbacks[Name] = function()
			ChangeSelectedEasingDirection(Name)
		end
	end

	local chosenAction = MenuContainer:Show("KeyFrame Menu")
	if chosenAction then
		local callback = callbacks[chosenAction.Text] if not callback then return end
		callback()
	end
end

function ShowTimeLineMenu()
	local callbacks = {
		["Add KeyFrame here"] = function()
			AddKeyFrameAtMousePos()
		end,
		["Reset Selected"] = function()
			ResetSelected()
		end,
		["Cut Selected"] = function()
			CopySelected()
			DeleteSelected()
		end,
		["Copy Selected"] = function()
			CopySelected()
		end,
		["Paste KeyFrames"] = function()
			PasteSelected()
		end,
		["Delete Selected"] = function()
			DeleteSelected()
		end,
	}

	local chosenAction = MenuContainer:Show("TimeLine Menu")
	if chosenAction then
		local callback = callbacks[chosenAction.Text] if not callback then return end
		callback()
	end
end

function AddKeyFrame(KeyFrame)
	local Motor = KeyFrame.Motor
	local yPos = MotorDropsheetContainer.GetYPosForKeyFrame(Motor.Name)
	local xPos = UIUtils.SnapUI(KeyFrame.TimePosition/Globals.maxTimePosition.Value)

	local KeyFrameObj = KeyFrameUI.new(TimeLine,Widget,UDim2.new(xPos,0,0,yPos),KeyFrame)
	
	local cacheIndex = KeyFrame.Id
	local cacheEntry = {
		Obj = KeyFrameObj,
		Cons = {},
	}

	cacheEntry.Cons[1] = KeyFrameObj.Dragging:Connect(function(posChange)
		local isSelected = table.find(curSelected,KeyFrameObj) ~= nil if not isSelected then return end

		for _,KeyFrame in pairs(curSelected) do
			if KeyFrame == KeyFrameObj then continue end

			local frame = KeyFrame._frame
			local pos = frame.Position
			local negBound = 0
			local posBound = 1
			local goalPos = math.clamp((frame.Position.X.Scale + posChange.X.Scale),negBound,posBound)

			frame.Position = UDim2.new(goalPos,0,pos.Y.Scale,pos.Y.Offset)
		end
	end)

	cacheEntry.Cons[2] = KeyFrameObj.Selected:Connect(function()
		local isSelected = table.find(curSelected,KeyFrameObj) ~= nil

		if not IsPressing(Enum.KeyCode.LeftControl) then
			if #curSelected < 2 and not isMassSelecting then
				for i,KeyFrame in pairs(curSelected) do
					if KeyFrame ~= KeyFrameObj then
						KeyFrame:Deselect()
						curSelected[i] = nil
					end
				end
			end

			if not isSelected then
				table.insert(curSelected,KeyFrameObj)
			end
		else
			if not isSelected then
				table.insert(curSelected,KeyFrameObj)
			else
				KeyFrameObj:Deselect()
				table.remove(curSelected,table.find(curSelected,KeyFrameObj))
			end
		end
	end)

	cacheEntry.Cons[3] = KeyFrameObj.RightClicked:Connect(function()
		ShowKeyFrameMenu(KeyFrame,KeyFrameObj)
	end)

	cacheEntry.Cons[4] = KeyFrameObj.DragEnded:Connect(function()
		Network:Execute("UpdateKeyFramePositions",KeyFrameContainer:GetKeyFrames())
	end)

	KeyFrameCache[cacheIndex] = cacheEntry
end

function KeyFrameContainer:Clear()
	for i,KeyFrameObj in pairs(KeyFrameCache) do
		KeyFrameObj:Destroy()
		KeyFrameCache[i] = nil
	end
end

function KeyFrameContainer:GetKeyFrames()
	local toReturn = {}
	
	for id,entry in pairs(KeyFrameCache) do
		local keyFrameObj = entry.Obj
		local keyFramePos = keyFrameObj._frame.Position
		local keyFrameId = keyFrameObj.Id
		
		local timePos = UIUtils.SnapUI(maxTimePosition.Value*keyFramePos.X.Scale)
		toReturn[keyFrameId] = timePos
	end
	
	return toReturn
end

function KeyFrameContainer:Update(Animation)
	local newKeyFrames = Animation:GetKeyFrames()
	
	local superfluous = {}
	local missing = {}
	local newIds = {}
	
	DeselectAll()
	table.clear(curPressingKeys)
	
	for _,KeyFrame in pairs(newKeyFrames) do
		newIds[KeyFrame.Id] = true
	end
	
	for _,KeyFrame in pairs(newKeyFrames) do
		local existing = KeyFrameCache[KeyFrame.Id]
		if not existing then
			table.insert(missing,KeyFrame)
		else
			-- update position
			local Motor = KeyFrame.Motor
			local yPos = MotorDropsheetContainer.GetYPosForKeyFrame(Motor.Name)
			local xPos = UIUtils.SnapUI(KeyFrame.TimePosition/Globals.maxTimePosition.Value)

			existing.Obj:SetPosition(UDim2.new(xPos,0,0,yPos))
		end
	end
	
	for id,entry in pairs(KeyFrameCache) do
		local isMissing = newIds[id] == nil
		if isMissing then
			table.insert(superfluous,entry)
			KeyFrameCache[id] = nil
		end
	end
	
	for i,KeyFrame in pairs(missing) do -- create newly added
		AddKeyFrame(KeyFrame)
	end
	
	for i,entry in pairs(superfluous) do -- destroy superfluous
		entry.Obj:Destroy()
		for _,con in pairs(entry.Cons) do
			con:Disconnect()
		end
	end
end

function Init()
	local self = setmetatable({},KeyFrameContainer)
	
	InputService:AddInputSource(inputCatcher)
	InputService:AddInputSource(TimeLine)
	
	InputService:BindToInput({inputCatcher},Enum.KeyCode.Delete,Enum.UserInputState.Begin,DeleteSelected)
	
	InputService:BindToInput({inputCatcher},Enum.KeyCode.C,Enum.UserInputState.Begin,function()
		if not InputService:IsKeyDown(Enum.KeyCode.LeftControl) then return end
		CopySelected()
	end)
	
	InputService:BindToInput({inputCatcher},Enum.KeyCode.V,Enum.UserInputState.Begin,function()
		if not InputService:IsKeyDown(Enum.KeyCode.LeftControl) then return end
		PasteSelected()
	end)
	
	InputService:BindToInput({inputCatcher},Enum.KeyCode.G,Enum.UserInputState.Begin,function()
		if not InputService:IsKeyDown(Enum.KeyCode.LeftControl) then return end
		AddKeyFrameAtMousePos()
	end)
	
	InputService:BindToInput({inputCatcher},Enum.KeyCode.R,Enum.UserInputState.Begin,function()
		if not InputService:IsKeyDown(Enum.KeyCode.LeftControl) then return end
		ResetSelected()
	end)
	
	InputService:BindToInput({inputCatcher},Enum.KeyCode.Y,Enum.UserInputState.Begin,function()
		if not InputService:IsKeyDown(Enum.KeyCode.LeftControl) then return end
		SavePointService:Undo()
	end)

	InputService:BindToInput({inputCatcher},Enum.KeyCode.Z,Enum.UserInputState.Begin,function()
		if not InputService:IsKeyDown(Enum.KeyCode.LeftControl) then return end
		SavePointService:Redo()
	end)
	
	InputService:BindToInput({TimeLine},Enum.UserInputType.MouseButton1,Enum.UserInputState.Begin,function()
		DeselectAll()
		MassSelect()
		SelectionService:Set({})
	end)
	
	InputService:BindToInput({TimeLine},Enum.UserInputType.MouseButton2,Enum.UserInputState.Begin,function()
		ShowTimeLineMenu()
	end)
	
	InputService:BindToInput({TimeLine},Enum.KeyCode.Space,Enum.UserInputState.Begin,function()
		Network:Execute("PlayAnimation")
	end)
	
	shared.Plugin.Deactivation:Connect(function()
		for i,v in pairs(keyFramesToCopy) do
			keyFramesToCopy[i] = nil
		end
	end)

	Widget.WindowFocused:Connect(function()
		InputService:ClearPressingKeys()
	end)

	return self
end

return Init()