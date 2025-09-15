-- TODO: Throughout this, assert that UDims are what is expected (scale only on opposite direction)
local Src = script:FindFirstAncestor("UltimateList")

local DataSourceMethods = require(Src.DataSources.DataSourceMethods)
local DataSources = require(Src.DataSources)
local Dimensions = require(script.Parent)
local exhaustiveMatch = require(Src.Util.exhaustiveMatch)

local DimensionsMethods = {}

function DimensionsMethods.getCanvasSize<T>(
	dimensions: Dimensions.Dimensions<T>,
	dataSource: DataSources.DataSource<T>,
	direction: "x" | "y"
): UDim2
	local back = DataSourceMethods.back(dataSource)
	if back == nil then
		return UDim2.new()
	end

	local udimRect = DimensionsMethods.getUDimRect(dimensions, back, DataSourceMethods.length(dataSource), direction)
	return if direction == "x"
		then UDim2.fromOffset(udimRect.position.X.Offset + udimRect.size.X.Offset, 0)
		elseif direction == "y" then UDim2.fromOffset(0, udimRect.position.Y.Offset + udimRect.size.Y.Offset)
		else exhaustiveMatch(direction)
end

function DimensionsMethods.getUDimRect<T>(
	dimensions: Dimensions.Dimensions<T>,
	item: T,
	index: number,
	direction: "x" | "y"
): Dimensions.UDimRect
	if dimensions.type == "consistentSize" then
		if direction == "x" then
			return {
				size = UDim2.new(0, dimensions.size, 1, 0),
				position = UDim2.fromOffset(dimensions.size * (index - 1), 0),
			}
		elseif direction == "y" then
			return {
				size = UDim2.new(1, 0, 0, dimensions.size),
				position = UDim2.fromOffset(0, dimensions.size * (index - 1)),
			}
		else
			return exhaustiveMatch(direction)
		end
	elseif dimensions.type == "consistentUDim2" then
		if direction == "x" then
			local amountPerColumn = 1 // dimensions.udim2.Y.Scale
			return {
				size = dimensions.udim2,
				position = UDim2.new(
					0,
					(math.ceil(index / amountPerColumn) - 1) * dimensions.udim2.X.Offset,
					dimensions.udim2.Y.Scale * ((index - 1) % amountPerColumn),
					0
				),
			}
		elseif direction == "y" then
			local amountPerRow = 1 // dimensions.udim2.X.Scale
			return {
				size = dimensions.udim2,
				position = UDim2.new(
					dimensions.udim2.X.Scale * ((index - 1) % amountPerRow),
					0,
					0,
					(math.ceil(index / amountPerRow) - 1) * dimensions.udim2.Y.Offset
				),
			}
		else
			return exhaustiveMatch(direction)
		end
	elseif dimensions.type == "getter" then
		return dimensions.callback(item, index)
	else
		return exhaustiveMatch(dimensions.type)
	end
end

return DimensionsMethods
