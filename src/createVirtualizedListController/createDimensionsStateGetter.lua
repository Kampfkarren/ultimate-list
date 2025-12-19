local Src = script:FindFirstAncestor("ultimate-list")

local DataSourceMethods = require(Src.DataSources.DataSourceMethods)
local DataSources = require(Src.DataSources)
local Dimensions = require(Src.Dimensions)

local function createFreshAccumulatingSizeState<T>(
	dimensions_: Dimensions.Dimensions<T> & { type: "accumulatingSize" },
	dataSource: DataSources.DataSource<T>,
	windowSize: Vector2,
	direction: "x" | "y",
	spacing: number
): Dimensions.DimensionsState<T> & { type: "accumulatingSize" }
	local dimensions = dimensions_ :: Dimensions.Dimensions<T>
	assert(dimensions.type == "accumulatingSize", "Luau")

	local udimRects: { Dimensions.UDimRect } = {}
	local dominantSections: { Dimensions.AccumulatingSizeSection } = {}
	local needsSizeRecalculation = false

	local totalDominantSize = 0

	local cursor = DataSourceMethods.get(dataSource, 1)
	local index = 1

	-- State of current section
	local startIndex = 1
	local largestDominantInSection = 0

	local latestNonDominantSizeOffset = 0
	local latestNonDominantSizeScale = 0

	local maxNonDominantSize = if direction == "x" then windowSize.Y else windowSize.X

	while cursor ~= nil do
		local value: T = cursor.value -- Luau: This is an error type otherwise

		local size = dimensions.callback(value, index)
		if (direction == "x" and size.Y.Offset > 0) or (direction == "y" and size.X.Offset > 0) then
			needsSizeRecalculation = true
		end

		local dominantSize = if direction == "x" then size.X.Offset else size.Y.Offset

		local nonDominantSizeTotal = if direction == "x"
			then size.Y.Scale * windowSize.Y + size.Y.Offset
			else size.X.Scale * windowSize.X + size.X.Offset

		local firstInSection = latestNonDominantSizeOffset ~= 0 or latestNonDominantSizeScale ~= 0

		if
			not firstInSection
			and (
						latestNonDominantSizeOffset
						+ latestNonDominantSizeScale * (if direction == "x" then windowSize.Y else windowSize.X)
					)
					+ spacing
					+ nonDominantSizeTotal
				>= maxNonDominantSize
		then
			firstInSection = true
			error("todo soon: create fresh section")
		end

		table.insert(udimRects, {
			size = size,
			position = if direction == "x"
				then UDim2.new(
					0,
					totalDominantSize,
					latestNonDominantSizeScale,
					if firstInSection then 0 else latestNonDominantSizeOffset + spacing
				)
				else UDim2.new(
					latestNonDominantSizeScale,
					if firstInSection then 0 else latestNonDominantSizeOffset + spacing,
					0,
					totalDominantSize
				),
		})

		largestDominantInSection = math.max(largestDominantInSection, dominantSize)
		latestNonDominantSizeScale += if direction == "x" then size.Y.Scale else size.X.Scale
		latestNonDominantSizeOffset += if direction == "x" then size.Y.Offset else size.X.Offset

		cursor = cursor.after()
		index += 1
	end

	if latestNonDominantSizeOffset ~= 0 or latestNonDominantSizeScale ~= 0 then
		table.insert(dominantSections, {
			indexRange = Vector3.new(startIndex, DataSourceMethods.length(dataSource)),
			box = Vector3.new(totalDominantSize, totalDominantSize + largestDominantInSection),
		})
	end

	return {
		type = "accumulatingSize" :: "accumulatingSize",
		udimRects = udimRects,
		dominantSections = dominantSections,
		dataSource = dataSource,
		windowSize = windowSize,
		latestNonDominantSizeScale = latestNonDominantSizeScale,
		latestNonDominantSizeOffset = latestNonDominantSizeOffset,
		sizeRecalculationStrategy = if needsSizeRecalculation
			then {
				needsRecalculation = true :: true,
				lastWindowSize = windowSize,
			}
			else {
				needsRecalculation = false :: false,
			},
	}
end

local function createFreshState<T>(
	dimensions: Dimensions.Dimensions<T>,
	dataSource: DataSources.DataSource<T>,
	windowSize: Vector2,
	direction: "x" | "y"
): Dimensions.DimensionsState<T>?
	if dimensions.type == "accumulatingSize" then
		return createFreshAccumulatingSizeState(dimensions, dataSource, windowSize, direction, 0)
	elseif dimensions.type == "spaced" then
		if dimensions.inner.type == "accumulatingSize" then
			return createFreshAccumulatingSizeState(
				dimensions.inner,
				dataSource,
				windowSize,
				direction,
				dimensions.spacing
			)
		else
			return nil
		end
	else
		return nil
	end
end

local function getUpdatedAccumulatingSizeState<T>(
	dimensions_: Dimensions.Dimensions<T> & { type: "accumulatingSize" },
	lastDimensions_: Dimensions.Dimensions<T> & { type: "accumulatingSize" },
	lastDimensionsState_: Dimensions.DimensionsState<T> & { type: "accumulatingSize" },
	dataSource: DataSources.DataSource<T>,
	windowSize: Vector2,
	direction: "x" | "y",
	spacing: number
): Dimensions.DimensionsState<T>
	-- These are necessary because otherwise you can't actually use it
	local dimensions = dimensions_ :: Dimensions.Dimensions<T>
	local lastDimensions = lastDimensions_ :: Dimensions.Dimensions<T>
	local lastDimensionsState = lastDimensionsState_ :: Dimensions.DimensionsState<T>

	assert(dimensions.type == "accumulatingSize", "Luau")
	assert(lastDimensions.type == "accumulatingSize", "Luau")
	assert(lastDimensionsState.type == "accumulatingSize", "Luau")

	if
		DataSourceMethods.equals(lastDimensionsState.dataSource, dataSource)
		and (
			not lastDimensionsState.sizeRecalculationStrategy.needsRecalculation
			or lastDimensionsState.windowSize == windowSize
		)
	then
		return lastDimensionsState
	end

	-- todo soon: update existing (exact same until appendOnly)

	return createFreshAccumulatingSizeState(dimensions, dataSource, windowSize, direction, spacing)
end

local function createDimensionsStateGetter<T>(): (
	dimensions: Dimensions.Dimensions<T>,
	dataSource: DataSources.DataSource<T>,
	windowSize: Vector2,
	direction: "x" | "y"
) -> Dimensions.DimensionsState<T>
	local NONE_STATE: Dimensions.DimensionsState<T> = {
		type = "none",
	}

	local lastDimensions: Dimensions.Dimensions<T>? = nil
	local lastDimensionsState: Dimensions.DimensionsState<T>? = nil

	return function(
		dimensions: Dimensions.Dimensions<T>,
		dataSource: DataSources.DataSource<T>,
		windowSize: Vector2,
		direction: "x" | "y"
	): Dimensions.DimensionsState<T>
		local nextState = NONE_STATE

		if windowSize ~= Vector2.zero then
			if lastDimensions == nil or lastDimensions.type ~= dimensions.type then
				nextState = createFreshState(dimensions, dataSource, windowSize, direction) or NONE_STATE
			elseif dimensions.type == "accumulatingSize" then
				assert(lastDimensions.type == "accumulatingSize", "Luau")
				assert(
					lastDimensionsState ~= nil and lastDimensionsState.type == "accumulatingSize",
					"lastDimensionsState should be accumulatingSize"
				)

				nextState = getUpdatedAccumulatingSizeState(
					dimensions,
					lastDimensions,
					lastDimensionsState,
					dataSource,
					windowSize,
					direction,
					0
				)
			elseif dimensions.type == "spaced" then
				assert(lastDimensions.type == "spaced", "Luau")

				if dimensions.inner.type ~= lastDimensions.inner.type then
					nextState = createFreshState(dimensions, dataSource, windowSize, direction) or NONE_STATE
				elseif dimensions.inner.type == "accumulatingSize" then
					assert(lastDimensions.inner.type == "accumulatingSize", "Luau")
					assert(lastDimensionsState ~= nil, "Luau")
					assert(
						lastDimensionsState ~= nil and lastDimensionsState.type == "accumulatingSize",
						"lastDimensionsState should be accumulatingSize"
					)

					nextState = getUpdatedAccumulatingSizeState(
						dimensions.inner,
						lastDimensions.inner,
						lastDimensionsState,
						dataSource,
						windowSize,
						direction,
						dimensions.spacing
					)
				end
			end
		end

		lastDimensions = dimensions
		lastDimensionsState = NONE_STATE

		return nextState
	end
end

return createDimensionsStateGetter
