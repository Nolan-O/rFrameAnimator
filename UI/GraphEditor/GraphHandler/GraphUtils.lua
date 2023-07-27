local GraphUtils = {}

local Configuration = shared.require("Configuration")
local OriginData = shared.require("OriginData")

function GraphUtils.valuesToPos(values,Parent)
	local GridSize = Configuration.GraphEditorConfig.GridSize
	local StepSize = Configuration.GraphEditorConfig.StepSize
	
	local absSize = Parent.AbsoluteSize

	local xOffset = GridSize.X * values.X / StepSize.X
	local yOffset = GridSize.Y * values.Y / StepSize.Y

	local xScale = xOffset/absSize.X
	local yScale = yOffset/absSize.Y

	return UDim2.fromScale(xScale,-yScale)
end

function GraphUtils.positionToValues(position,Parent)
	local GridSize = Configuration.GraphEditorConfig.GridSize
	local StepSize = Configuration.GraphEditorConfig.StepSize
	
	local absSize = Parent.AbsoluteSize
	local absPos = Vector2.new(position.X.Scale * absSize.X,position.Y.Scale * absSize.Y)
	local values = absPos/GridSize*StepSize

	return Vector2.new(values.X,-values.Y)
end

function GraphUtils.sequenceToValues(sequence,axis)
	local values = {}

	local origin = OriginData.GetOriginForMotor(sequence.Motor) if not origin then return end
	local originPivot = origin.C0 * origin.Part0CFrame

	for TimePos,KeyFrame in next,sequence.KeyFrames do
		local pivot = KeyFrame.C0 * origin.Part0CFrame
		local pivotDelta = pivot * originPivot:Inverse()

		values[KeyFrame.Id] = Vector2.new(TimePos,pivotDelta.p[axis])
	end
	
	return values
end

return GraphUtils