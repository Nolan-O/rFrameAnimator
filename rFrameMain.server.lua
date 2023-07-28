if not plugin then return end

local customRequire = require(script.Parent:WaitForChild("CustomRequire"))
local Configuration = shared.require("Configuration")
local Templates = script.Parent:WaitForChild("UI").Templates

local enabled = false
local toolbar = plugin:CreateToolbar("rFrameAnimator")
local button = toolbar:CreateButton(
	"rFrameAnimator",
	"Create Animations",
	"http://www.roblox.com/asset/?id=7229051060"
)


function shared.NewTemplate(name: string, opt_parent: Instance)
	local ins = Templates:WaitForChild(name):Clone()

	if opt_parent then
		ins.Parent = opt_parent
	end

	return ins
end

local NewTemplate = shared.NewTemplate

local TimeLineWidget = plugin:CreateDockWidgetPluginGui("TimeLine", Configuration.TimeLineWigetInfo)
TimeLineWidget.Title = "Time Line"
TimeLineWidget.Enabled = false
NewTemplate("TimeLine", TimeLineWidget)
NewTemplate("inputCatcher", TimeLineWidget)

local EasingStyleWidget = plugin:CreateDockWidgetPluginGui("Graph Editor", Configuration.GraphEditorInfo)
EasingStyleWidget.Title = "Graph Editor"
EasingStyleWidget.Enabled = false
NewTemplate("GraphEditor", EasingStyleWidget)
NewTemplate("inputCatcher", EasingStyleWidget)

local MenuWidget = plugin:CreateDockWidgetPluginGui("Menu", Configuration.MenuInfo)
MenuWidget.Title = "Menu"
MenuWidget.Enabled = false
NewTemplate("Menu", MenuWidget)

shared.Plugin = plugin
shared.UITemplates = Templates
shared.Globals = script.Parent:WaitForChild("GlobalValues")
shared.TimeLineWidget = TimeLineWidget
shared.EasingStyleWidget = EasingStyleWidget
shared.MenuWidget = MenuWidget

local Selection = game:GetService("Selection")
local RunService = game:GetService("RunService")
local StudioService = game:GetService("StudioService")
local UIS = game:GetService("UserInputService")
local CHS = game:GetService("ChangeHistoryService")

local KeyFrameSequence = shared.require("KeyFrameSequence")
local KeyFrame = shared.require("KeyFrame")
local originData = shared.require("OriginData")
local AnimationTrack = shared.require("AnimationTrack")
local Pose = shared.require("Pose")
local TimeLineInterface = shared.require("TimeLineInterface")
local Network = shared.require("Network")
local KeyFrameContainer = shared.require("KeyFrameContainer")
local GraphEditorInterface = shared.require("GraphEditorInterface")
local RigEditHandler = shared.require("RigEditHandler")
local MenuInterface = shared.require("MenuInterface")
local Exporter = shared.require("Exporter")
local Saver = shared.require("Saver")
local Importer = shared.require("Importer")
local ClipboardService = shared.require("ClipboardService")
local SavePointService = shared.require("SavePointService")
local GraphHandler = shared.require("GraphHandler")
local PopupPrompt = shared.require("PopupPrompt")
local InputService = shared.require("InputService")
local ValidateRig = shared.require("ValidateRig")
local BackendUtils = shared.require("BackendUtils")

TimeLineInterface.Build()
GraphEditorInterface.Build()
MenuInterface.Build()

local Globals = script.Parent:WaitForChild("GlobalValues")
local curTimePosition = Globals.curTimePosition
local maxTimePosition = Globals.maxTimePosition
local FramesPerSec = Globals.FramesPerSec

local curSelectedRig = nil
local curAnimation = nil
local playConnection = nil
local currentlyPlaying = false

-----------------Functions---------------------------

function StopAnimation()
	if not currentlyPlaying then return end
	currentlyPlaying = false
	
	if playConnection then
		playConnection:Disconnect()
	end
	
	RigEditHandler:Resume()
end

function PlayAnimation()
	if currentlyPlaying or not curAnimation or not curSelectedRig then return end
	
	currentlyPlaying = true
	RigEditHandler:Pause()
	
	local Accumulated = 0
	
	if curTimePosition.Value >= curAnimation:GetBiggestTimePos() then
		curTimePosition.Value = 0
	end
	
	if curAnimation:GetKeyFrameAmount() <= 0 then
		return
	end
	
	playConnection = RunService.Heartbeat:Connect(function(deltaTime)
		if TimeLineInterface.IsDragging() or GraphEditorInterface.IsDragging() then return end
		
		local maxTimePos = maxTimePosition.Value
		local stepInterval = 1/FramesPerSec.Value
		
		local defaultFrames = Configuration.DefaultFramesPerSec
		local setFrames = FramesPerSec.Value
		local framesAtOnce = math.round(defaultFrames/setFrames) -- frame increase per step
		local isLooped = curAnimation.Looped
		local biggestTimePos = curAnimation:GetBiggestTimePos()
		
		Accumulated += deltaTime
		
		if biggestTimePos <= curTimePosition.Value then
			if isLooped then
				curTimePosition.Value = 0
			else
				curTimePosition.Value = biggestTimePos
				StopAnimation()
				return
			end
		end
		
		if Accumulated >= stepInterval then
			local newCurTimePos = math.clamp(curTimePosition.Value + framesAtOnce,0,biggestTimePos)
			
			Accumulated -= stepInterval
			curTimePosition.Value = newCurTimePos

			if curTimePosition.Value >= maxTimePos then
				if isLooped then
					curTimePosition.Value = 0
				else
					StopAnimation()
					return
				end
			end
		end
	end)
end

function AttemptAnimationPlay()
	print(1)
	if not curAnimation then return end
	
	if not currentlyPlaying then
		print(2)
		PlayAnimation()
	else
		print(3)
		StopAnimation()
	end
end

function SelectRig()
	if currentlyPlaying then warn("can't select rig while playing animation") return end
	local SelectedRig = Selection:Get()[1]
	
	local succ, errors = ValidateRig(SelectedRig)
	if not succ then
		warn(table.concat(errors, ",\n"))
		return
	end
	
	if curAnimation then
		curAnimation:Destroy()
	end
	
	originData.SetNew(SelectedRig)
	Selection:Remove(Selection:Get())
	
	curSelectedRig = SelectedRig
	curAnimation = AnimationTrack.new(SelectedRig)
	
	TimeLineInterface.UpdateMotorDropsheet(SelectedRig)
	KeyFrameContainer:Update(curAnimation)
	MenuInterface.Update(curAnimation,SelectedRig)
	SavePointService:SetPoint(curAnimation)
	
	return true
end

function DeselectRig()
	StopAnimation()
	originData.ReturnModelToOrigin()
	originData.Clear()
	SavePointService:Clear()
	GraphHandler:Clear()
	
	curSelectedRig = nil
	curAnimation = nil
end

function DeactivatePlugin()
	if not enabled then return end

	local function finish_deactivation()
		enabled = false
		TimeLineWidget.Enabled = false
		EasingStyleWidget.Enabled = false
		MenuWidget.Enabled = false
		
		SavePointService:Disable()
		DeselectRig()
		plugin:Deactivate(true)
	end
	
	if not TimeLineWidget.Enabled or not MenuWidget.Enabled or curAnimation:GetKeyFrameAmount() < 1 then
		Saver:AutoSave(curSelectedRig,curAnimation)
	else
		local text = ("Save animation: %s?"):format(curAnimation.Name)
		local function accept()
			Saver:SaveAnimation(curSelectedRig, curAnimation.Name, curAnimation)
			finish_deactivation()
		end
		local function decline()
			finish_deactivation()
		end
		PopupPrompt:ShowAsync(MenuWidget, text, accept, decline, nil, nil, true)
	end
end

function ActivatePlugin()
	if enabled then return end
	local succ = SelectRig()
	if not succ then return end
	
	enabled = true
	EasingStyleWidget.Enabled = true
	TimeLineWidget.Enabled = true
	MenuWidget.Enabled = true
	
	PopupPrompt:Hide() -- in case it was still open
	RigEditHandler:Activate(curSelectedRig)
	SavePointService:Enable()
	SavePointService:SetPoint(curAnimation)
	
	MenuInterface.Update(curAnimation,curSelectedRig)
	Pose.PoseRig(curSelectedRig,curTimePosition.Value,curAnimation)
	plugin:Activate(true)
end

-----------------Connections---------------------------

curTimePosition.Changed:Connect(function()
	if not curSelectedRig or not curAnimation then return end
	coroutine.wrap(Pose.PoseRig)(curSelectedRig,curTimePosition.Value,curAnimation)
end)

button.Click:Connect(function()
	if enabled then
		DeactivatePlugin()
	else
		ActivatePlugin()
	end
end)

TimeLineWidget:GetPropertyChangedSignal("Enabled"):Connect(function()
	if enabled and not TimeLineWidget.Enabled then
		DeactivatePlugin()
	end
end)

MenuWidget:GetPropertyChangedSignal("Enabled"):Connect(function()
	if enabled and not MenuWidget.Enabled then
		DeactivatePlugin()
	end
end)

InputService:BindToInput({"UserInputService"},Enum.KeyCode.Space, Enum.UserInputState.Begin, AttemptAnimationPlay)
plugin.Deactivation:Connect(DeactivatePlugin)

------------------Network Connections---------------------------------

Network:Register("StopAnimation",function()
	StopAnimation()
end)

Network:Register("PlayAnimation",function()
	AttemptAnimationPlay()
end)

Network:Register("SaveAnimation",function()
	if not curAnimation or not curSelectedRig then return end
	local Source = Saver:SaveAnimation(curSelectedRig,curAnimation.Name,curAnimation)

	Selection:Set({Source})
end)

Network:Register("ExportAnimation",function()
	if not curAnimation then return end
	if not curSelectedRig then return end
	
	StopAnimation()
	Exporter.Export(curSelectedRig,curAnimation)
end)

Network:Register("ExitPlugin",function()
	DeactivatePlugin()
end)

Network:Register("LoadAnimation",function()
	if not curAnimation or not curSelectedRig then return end
	local AnimationSave = Selection:Get()[1] 
	
	SavePointService:SetPoint(curAnimation)
	StopAnimation()
	Globals.curTimePosition.Value = 0
	
	Importer.ImportSource(curAnimation,AnimationSave,curSelectedRig)
	MenuInterface.Update(curAnimation,curSelectedRig)
	KeyFrameContainer:Update(curAnimation)
	Pose.PoseRig(curSelectedRig,curTimePosition.Value,curAnimation)
	GraphHandler:Clear()
	Selection:Set({})
	SavePointService:SetPoint(curAnimation)
end)

Network:Register("ChangeAnimationName",function(newName)
	if not curAnimation then return end
	SavePointService:SetPoint(curAnimation)
	curAnimation.Name = newName
	SavePointService:SetPoint(curAnimation)
end)

Network:Register("ToggleLooping",function()
	if not curAnimation then return end
	SavePointService:SetPoint(curAnimation)
	curAnimation.Looped = not curAnimation.Looped
	SavePointService:SetPoint(curAnimation)
end)

Network:Register("CreateNewAnimation",function()
	if curAnimation:GetKeyFrameAmount() > 0 then
		local text = ("Save animation: %s?"):format(curAnimation.Name)
		local accept = function()
			Saver:SaveAnimation(curSelectedRig,curAnimation.Name,curAnimation)
		end
		local decline = function() end
		PopupPrompt:ShowAsync(MenuWidget, text, accept, decline, nil, nil, true)
	end
	if not curAnimation then return end
	
	SavePointService:SetPoint(curAnimation)
	
	curAnimation:Destroy()
	curAnimation = AnimationTrack.new(curSelectedRig)
	
	MenuInterface.Update(curAnimation,curSelectedRig)
	KeyFrameContainer:Update(curAnimation)
	Pose.PoseRig(curSelectedRig,curTimePosition.Value,curAnimation)
	GraphHandler:Clear()
	SavePointService:SetPoint(curAnimation)
end)

Network:Register("ChangeAnimationLength",function(newLength)
	if not curAnimation then return end
	SavePointService:SetPoint(curAnimation)
	
	for _,KeyFrameObj in pairs(curAnimation:GetKeyFrames()) do
		local newTimePos = math.clamp(KeyFrameObj.TimePosition,0,newLength)
		curAnimation:SetNewKeyFrameTimePosition(KeyFrameObj,newTimePos)
	end
	
	curAnimation.Length = newLength
	curTimePosition.Value = newLength * (curTimePosition.Value / maxTimePosition.Value)
	maxTimePosition.Value = newLength
	
	SavePointService:SetPoint(curAnimation)
	KeyFrameContainer:Update(curAnimation)
	Pose.PoseRig(curSelectedRig,curTimePosition.Value,curAnimation)
	GraphHandler:UpdateAll()
end)

Network:Register("ChangeFramesPerSec",function(newFramesPerSec)
	if not curAnimation then return end
	SavePointService:SetPoint(curAnimation)
	Globals.FramesPerSec.Value = newFramesPerSec
	curAnimation.FramesPerSec = newFramesPerSec
	SavePointService:SetPoint(curAnimation)
end)

Network:Register("ChangePriority",function(chosenPriority)
	if not curAnimation or not curSelectedRig then return end
	curAnimation.Priority = chosenPriority
	MenuInterface.Update(curAnimation,curSelectedRig)
end)

Network:Register("UpdateKeyFramePositions",function(data)
	-- called by timeline when keyframe ui is moved
	if not curAnimation then return end
	local sortData = {}
	SavePointService:SetPoint(curAnimation)
	
	-- fill sort data
	for Id, newTimePos in pairs(data) do
		local KF = curAnimation:GetKeyFrameById(Id) if not KF then continue end
		
		KF.TimePosition = newTimePos
		table.insert(sortData,KF)
	end 
	
	-- actually sort the sort data by timepos
	table.sort(sortData,function(a,b)
		return a.TimePosition < b.TimePosition
	end)
	
	-- clear old keyframe indexe
	for motorName, KFS in pairs(curAnimation.KeyFrameSequences) do
		for i,KF in pairs(KFS.KeyFrames) do
			KFS.KeyFrames[i] = nil
		end
	end
	
	for i = 1,#sortData do
		local KF = sortData[i]
		local Motor = KF.Motor
		local newTimePos = KF.TimePosition
		
		local KFS = curAnimation.KeyFrameSequences[Motor.Name] if not KFS then continue end
		
		KFS:DestroyKeyFrameAtPos(newTimePos) -- destroy any keyframes already at that index
		KFS.KeyFrames[newTimePos] = KF
	end
	
	local KeyFrameAmount = curAnimation:GetKeyFrameAmount()
	
	local function GetTableLength(t)
		local total = 0
		for _,_ in pairs(t) do
			total += 1
		end
		return total
	end
	
	if KeyFrameAmount ~= GetTableLength(data) then
		-- a keyframe was overidden so we update the ui
		KeyFrameContainer:Update(curAnimation)
	end
	
	SavePointService:SetPoint(curAnimation)
	GraphHandler:UpdateAll()
	Pose.PoseRig(curSelectedRig,curTimePosition.Value,curAnimation)
end)

Network:Register("DeleteKeyFramesById",function(toDelete)
	if not curAnimation then return end
	SavePointService:SetPoint(curAnimation)
	
	for _,Id in pairs(toDelete) do
		curAnimation:DestroyKeyFrameById(Id)
	end
	
	SavePointService:SetPoint(curAnimation)
	Pose.PoseRig(curSelectedRig,curTimePosition.Value,curAnimation)
	KeyFrameContainer:Update(curAnimation)
	GraphHandler:UpdateAll()
end)

Network:Register("CopyKeyFrames",function(keyFrames)
	if not curAnimation then return end
	local ToCopy = {}
	
	for Id,timePosition in pairs(keyFrames) do
		local KeyFrame = curAnimation:GetKeyFrameById(Id) if not KeyFrame then continue end
		local KeyFrameProxy = {}
		
		for i,v in pairs(KeyFrame) do
			KeyFrameProxy[i] = v
		end
		
		table.insert(ToCopy,KeyFrameProxy)
	end

	ClipboardService:Set(ToCopy)
end)

Network:Register("PasteKeyFrames",function()
	if not curAnimation then return end
	SavePointService:SetPoint(curAnimation)
	
	local copyTable = ClipboardService:Get()
	
	local smallestTimePos = math.huge
	for i,KeyFrame in pairs(copyTable) do
		local timePos = KeyFrame.TimePosition
		if timePos < smallestTimePos then
			smallestTimePos = timePos
		end
	end
	
	for i,KeyFrame in pairs(copyTable) do
		local timePos = KeyFrame.TimePosition
		local timePosToCopyTo = math.clamp(curTimePosition.Value+(timePos-smallestTimePos),0,maxTimePosition.Value)
		local newKeyFrame = curAnimation:AddKeyFrame(timePosToCopyTo,KeyFrame.Motor) if not newKeyFrame then continue end
		
		for i, v in pairs(KeyFrame) do
			if i == "TimePosition" or i == "Id" then continue end
			newKeyFrame[i] = v
		end
	end
	
	SavePointService:SetPoint(curAnimation)
	KeyFrameContainer:Update(curAnimation)
	Pose.PoseRig(curSelectedRig,curTimePosition.Value,curAnimation)
	GraphHandler:UpdateAll()
end)

Network:Register("ResetKeyFrames",function(Ids)
	if not curAnimation then return end
	SavePointService:SetPoint(curAnimation)
	
	for _,Id in pairs(Ids) do
		local keyFrameObj = curAnimation:GetKeyFrameById(Id) if not keyFrameObj then continue end
		local origin = originData.GetOriginForMotor(keyFrameObj.Motor)
		
		keyFrameObj.C0 = origin.C0
		keyFrameObj.C1 = origin.C1
		keyFrameObj.Part0CFrame = origin.Part0CFrame
		keyFrameObj.Part1CFrame = origin.Part1CFrame
	end
	
	SavePointService:SetPoint(curAnimation)
	KeyFrameContainer:Update(curAnimation)
	Pose.PoseRig(curSelectedRig,curTimePosition.Value,curAnimation)
	GraphHandler:UpdateAll()
end)

Network:Register("AddKeyFrameAtTimePos",function(timePos,motor)
	if not curAnimation then return end
	SavePointService:SetPoint(curAnimation)
	
	curAnimation:AddKeyFrame(timePos,motor)
	
	SavePointService:SetPoint(curAnimation)
	KeyFrameContainer:Update(curAnimation)
	Pose.PoseRig(curSelectedRig,curTimePosition.Value,curAnimation)
	GraphHandler:UpdateAll()
end)

Network:Register("AddKeyFrameWithOffset",function(data,sequence,timePosition,offset)
	-- called by Graph:AddNodeAtMousep()
	if not curAnimation then return end
	SavePointService:SetPoint(curAnimation)
	
	local displayType = data.DisplayType
	local axis = data.Axis
	local motor = sequence.Motor
	
	timePosition = math.clamp(timePosition,0,maxTimePosition.Value)
	curAnimation:AddKeyFrame(timePosition,motor)
	
	local remainingKeyFrame = sequence:GetKeyFrameAtPos(timePosition)
	local origin = originData.GetOriginForMotor(motor) if not origin then return end
	
	remainingKeyFrame:SetOffsets(origin.C0,origin.C1)
	remainingKeyFrame:SetAxisOffset(displayType,axis,offset)
	
	Pose.PoseRig(curSelectedRig,curTimePosition.Value,curAnimation)
	KeyFrameContainer:Update(curAnimation)
	GraphHandler:UpdateAll()
	
	SavePointService:SetPoint(curAnimation)
end)

Network:Register("ChangeEasingStyle",function(Ids,newEasingStyle)
	if not curAnimation then return end
	SavePointService:SetPoint(curAnimation)
	
	for _,Id in pairs(Ids) do
		local KeyFrame = curAnimation:GetKeyFrameById(Id) if not KeyFrame then continue end
		KeyFrame.EasingStyle = newEasingStyle
	end
	
	SavePointService:SetPoint(curAnimation)
end)

Network:Register("ChangeEasingDirection",function(Ids,newEasingDirection)
	if not curAnimation then return end
	SavePointService:SetPoint(curAnimation)
	
	for _,Id in pairs(Ids) do
		local KeyFrame = curAnimation:GetKeyFrameById(Id) if not KeyFrame then continue end
		KeyFrame.EasingDirection = newEasingDirection
	end
	
	SavePointService:SetPoint(curAnimation)
end)

Network:Register("AddBlankKeyFrames",function(timePos:number,motors:table)
	if not curAnimation then return end
	SavePointService:SetPoint(curAnimation)
	
	for _,motor in pairs(motors) do
		local origin = originData.GetOriginForMotor(motor) if not origin then continue end
		local keyFrame = curAnimation:AddKeyFrame(timePos,motor)
		
		keyFrame:SetOffsets(origin.C0,origin.C1)
	end
	
	SavePointService:SetPoint(curAnimation)
	KeyFrameContainer:Update(curAnimation)
	Pose.PoseRig(curSelectedRig,curTimePosition.Value,curAnimation)
	GraphHandler:UpdateAll()
end)

Network:Register("IncrementCFChange",function(Part,ChangeCF,changeType)
	-- called by Rig Edit
	if currentlyPlaying then return end
	
	local foundMotor, foundSequence = nil, nil
	local curTimePos = curTimePosition.Value
	
	for _,Sequence in pairs(curAnimation.KeyFrameSequences) do
		if Sequence.Motor and Sequence.Motor.Part1 == Part then
			foundMotor = Sequence.Motor
			foundSequence = Sequence
		end
	end
	
	if not foundSequence then return end
	
	-- Add keyframe if it doesn't exist yet
	if not foundSequence:GetKeyFrameAtPos(curTimePos) then
		curAnimation:AddKeyFrame(curTimePos,foundMotor)
		KeyFrameContainer:Update(curAnimation)
	end
	
	local UseLocalSpace = false--StudioService.UseLocalSpace
	local KeyFrame = foundSequence:GetKeyFrameAtPos(curTimePos)
	local Motor = KeyFrame.Motor
	local origin = originData.GetOriginForMotor(Motor)
	
	local Part0 = Motor.Part0
	local Part1 = Motor.Part1
	
	local C1NegOffset = Motor.Part1.CFrame:inverse()
	local C0NegOffset = Motor.Part0.CFrame:inverse()
	
	local PivotCFrame = Motor.Part0.CFrame * Motor.C0
	local curPos = PivotCFrame.p
	local curRot = PivotCFrame - PivotCFrame.p
	
	local partPos = Part.Position
	local partRot = Part.CFrame - Part.CFrame.p
	
	if changeType == "Rotation" then
		local newCFrame
		
		if UseLocalSpace then
			local deltaRot = ChangeCF
			local newRot = (partRot * deltaRot):ToObjectSpace(partRot)
			newCFrame = newRot + curPos
		else
			local deltaRot = ChangeCF:inverse()
			local newRot = deltaRot * curRot
			newCFrame = newRot + curPos
		end
		
		Motor.C1 = BackendUtils.repairedCFrame(C1NegOffset * newCFrame)
	elseif changeType == "Position" then
		local newCFrame
		
		if UseLocalSpace then
			newCFrame = CFrame.new(curPos) + (partRot * ChangeCF).p
		else
			local addedPos = ChangeCF.Position
			newCFrame = CFrame.new(curPos + addedPos) * curRot
		end
		
		Motor.C0 = BackendUtils.repairedCFrame(C0NegOffset * newCFrame)
	end
	
	KeyFrame:UpdateMotorOffset()
end)

Network:Register("SetWaypoint",function()
	if not curAnimation then return end
	SavePointService:SetPoint(curAnimation)
end)

Network:Register("LoadWaypoint",function(SavePoint)
	-- called by savepointservice on redo or undo
	if not curAnimation then return end
	
	curAnimation.Looped = SavePoint.Looped
	curAnimation.Name = SavePoint.Name
	curAnimation.FramesPerSec = SavePoint.FramesPerSec
	curAnimation.Length = SavePoint.Length
	
	local foundKeyFrames = {}
	
	for motorName,KFS in pairs(SavePoint.KeyFrameSequences) do
		local curAnimKFS = curAnimation.KeyFrameSequences[motorName]
		for timePos,KF in pairs(KFS.KeyFrames) do
			local curAnimKF = curAnimation:GetKeyFrameById(KF.Id)
			
			if not curAnimKF then
				curAnimKF = curAnimation:AddKeyFrame(timePos,KF.Motor)
			end
			
			curAnimKF.C0 = KF.C0
			curAnimKF.C1 = KF.C1
			curAnimKF.Part1CFrame = KF.Part1CFrame
			curAnimKF.Part0CFrame = KF.Part0CFrame
			curAnimKF.EasingStyle = KF.EasingStyle 
			curAnimKF.EasingDirection = KF.EasingDirection
			curAnimation:SetNewKeyFrameTimePosition(curAnimKF,KF.TimePosition)
			
			table.insert(foundKeyFrames,curAnimKF.Id)
		end
	end
	
	for _,KeyFrameObj in pairs(curAnimation:GetKeyFrames()) do
		if table.find(foundKeyFrames,KeyFrameObj.Id) == nil then
			curAnimation:DestroyKeyFrameById(KeyFrameObj.Id)
		end
	end
	
	table.clear(foundKeyFrames)
	
	KeyFrameContainer:Update(curAnimation)
	Pose.PoseRig(curSelectedRig,curTimePosition.Value,curAnimation)
	MenuInterface.Update(curAnimation,curSelectedRig)
	RigEditHandler:UpdateDummyRig()
	GraphHandler:UpdateAll()
end)

Network:Register("AddSequenceToGraph",function(Motor)
	if not curAnimation then return end
	local Sequence = curAnimation.KeyFrameSequences[Motor.Name]
	if not Sequence then return end
	local origin = originData.GetOriginForMotor(Motor)
	if not origin then return end

	GraphHandler:AddSequence(Sequence)
end)
Network:Register("RemoveSequenceToGraph",function(Motor)
	if not curAnimation then return end
	local Sequence = curAnimation.KeyFrameSequences[Motor.Name]
	if not Sequence then return end
	local origin = originData.GetOriginForMotor(Motor)
	if not origin then return end

	GraphHandler:RemoveSequence(Sequence)
end)

Network:Register("SetAxisCFrame",function(Id,newOffset,changeType,Axis)
	-- called when moving Nodes in the Graph Editor
	if not curAnimation then return end
	
	local KeyFrame = curAnimation:GetKeyFrameById(Id) if not KeyFrame then return end
	local origin = originData.GetOriginForMotor(KeyFrame.Motor) if not origin then return end
	
	KeyFrame:SetAxisOffset(changeType,Axis,newOffset)
	Pose.PoseRig(curSelectedRig,curTimePosition.Value,curAnimation)
end)

Network:Register("ChangeKeyFrameTimePos",function(Id,newTimePos)
	-- called by Graph when moving a Node
	if not curAnimation then return end
	
	local KeyFrameObj = curAnimation:GetKeyFrameById(Id) if not KeyFrameObj then return end
	local beforeAmount = curAnimation:GetKeyFrameAmount()
	
	curAnimation:SetNewKeyFrameTimePosition(KeyFrameObj,newTimePos)
	KeyFrameContainer:Update(curAnimation)
	Pose.PoseRig(curSelectedRig,curTimePosition.Value,curAnimation)
	
	if beforeAmount - curAnimation:GetKeyFrameAmount() ~= 0 then
		GraphHandler:UpdateAll()
	end
end)