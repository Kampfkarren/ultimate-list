local Src = script:FindFirstAncestor("UltimateList")

local DataSourceMethods = require(Src.DataSources.DataSourceMethods)
local DataSources = require(Src.DataSources)
local Dimensions = require(Src.Dimensions)
local DimensionsMethods = require(Src.Dimensions.DimensionsMethods)
local binarySearchIndexRangeInView = require(script.binarySearchIndexRangeInView)
local createDebugLogger = require(Src.Util.createDebugLogger)
local exhaustiveMatch = require(Src.Util.exhaustiveMatch)

local log = createDebugLogger("createVirtualizedListController")

export type VirtualizedListController<T> = {
	setScrollAxis: (scrollAxis: number) -> (),

	setWindowAxis: (windowAxis: number) -> (),
	getWindowAxis: () -> number,

	setDataSource: (DataSources.DataSource<T>) -> (),

	-- If the view has not changed, will return the identical last result
	get: () -> { T },
	getCanvasSize: () -> UDim2,
	getRange: () -> Vector3,

	bindToUpdate: (callback: () -> ()) -> () -> (),

	destroy: () -> (),
}

type CurrentView<T> = {
	range: Vector3,
	canvasSize: UDim2,
	cachedLastResult: { T },
	offsetBoundaries: Vector3?,
	dataSourceLength: number,
}

local function createVirtualizedListController<T>(
	dataSource: DataSources.DataSource<T>,
	dimensions: Dimensions.Dimensions<T>,
	direction: "x" | "y"
): VirtualizedListController<T>
	local currentView: CurrentView<T> = {
		range = Vector3.new(),
		canvasSize = UDim2.new(),
		scrollSizeAxis = 0,
		cachedLastResult = {},
		dataSourceLength = 0,
	}

	local scrollAxis = 0
	local windowAxis = 0

	-- consistentUDim2: O(1)
	-- consistentSize: O(1)
	-- getter: O(log n) assuming getter is O(1)
	local function getIndexRangeInView(): Vector3
		if dimensions.type == "consistentUDim2" then
			-- Amount per row if we're Y direction,
			-- amount per column if we're X.
			local amountPerNonDominant = if direction == "x"
				then 1 // dimensions.udim2.Y.Scale
				elseif direction == "y" then 1 // dimensions.udim2.X.Scale
				else exhaustiveMatch(direction)

			local dominantSize = if direction == "x"
				then dimensions.udim2.X.Offset
				elseif direction == "y" then dimensions.udim2.Y.Offset
				else exhaustiveMatch(direction)

			log("getIndexRangeInView: amountPerDominant = %d, dominantSize = %d", amountPerNonDominant, dominantSize)

			local head = 1 + ((scrollAxis // dominantSize) * amountPerNonDominant)
			local tail = (1 + ((scrollAxis + windowAxis) // dominantSize)) * amountPerNonDominant

			return Vector3.new(head, tail)
		elseif dimensions.type == "consistentSize" then
			local head = 1 + scrollAxis // dimensions.size
			local tail = 1 + ((scrollAxis + windowAxis) // dimensions.size)

			return Vector3.new(head, tail)
		elseif dimensions.type == "getter" then
			return binarySearchIndexRangeInView(dataSource, dimensions.callback, scrollAxis, windowAxis, direction)
		else
			return exhaustiveMatch(dimensions.type)
		end
	end

	local callbacks: { [() -> ()]: true? } = {}

	local function callUpdateCallbacks()
		for callback in callbacks do
			callback()
		end
	end

	local function update()
		local length = DataSourceMethods.length(dataSource)

		-- Only re-check if we actually will see anything new
		if
			currentView.offsetBoundaries ~= nil
			and currentView.offsetBoundaries.X <= scrollAxis
			and currentView.offsetBoundaries.Y >= windowAxis + scrollAxis
			and currentView.dataSourceLength == length
		then
			return
		end

		local newIndexRange = getIndexRangeInView()
		local items = DataSourceMethods.getByRange(dataSource, newIndexRange)

		if #items == 0 then
			log("View changed, but no items in list")

			currentView = {
				range = newIndexRange,
				canvasSize = UDim2.new(),
				cachedLastResult = {},
				offsetBoundaries = Vector3.new(scrollAxis, windowAxis + scrollAxis),
				dataSourceLength = length,
			}

			callUpdateCallbacks()

			return
		end

		local topDimensions = DimensionsMethods.getUDimRect(dimensions, items[1], newIndexRange.X, direction)
		local bottomDimensions = DimensionsMethods.getUDimRect(dimensions, items[#items], newIndexRange.Y, direction)

		log(
			"View changed: %d..%d (scroll axis: %d, window axis: %d, offset boundaries: %* - %*)",
			newIndexRange.X,
			newIndexRange.Y,
			scrollAxis,
			windowAxis,
			currentView.offsetBoundaries and currentView.offsetBoundaries.X,
			currentView.offsetBoundaries and currentView.offsetBoundaries.Y
		)

		currentView = {
			range = newIndexRange,
			canvasSize = DimensionsMethods.getCanvasSize(dimensions, dataSource, direction),
			cachedLastResult = items,
			offsetBoundaries = Vector3.new(
				if direction == "x"
					then topDimensions.position.X.Offset
					elseif direction == "y" then topDimensions.position.Y.Offset
					else exhaustiveMatch(direction),

				if direction == "x"
					then bottomDimensions.position.X.Offset + bottomDimensions.size.X.Offset
					elseif direction == "y" then bottomDimensions.position.Y.Offset + bottomDimensions.size.Y.Offset
					else exhaustiveMatch(direction)
			),
			dataSourceLength = length,
		}

		callUpdateCallbacks()
	end

	local function setScrollAxis(newScrollAxis: number)
		scrollAxis = newScrollAxis
		update()
	end

	local function setWindowAxis(newWindowAxis: number)
		windowAxis = newWindowAxis
		update()
	end

	local function getWindowAxis(): number
		return windowAxis
	end

	local function setDataSource(newDataSource: DataSources.DataSource<T>)
		assert(dataSource.type == newDataSource.type, "Data source type changed, you must keep it the same")
		newDataSource = dataSource
		update()
	end

	local function get(): { T }
		return currentView.cachedLastResult
	end

	local function getCanvasSize(): UDim2
		return currentView.canvasSize
	end

	local function getRange(): Vector3
		return currentView.range
	end

	local function bindToUpdate(callback: () -> ()): () -> ()
		callbacks[callback] = true
		return function()
			callbacks[callback] = nil
		end
	end

	local disconnectMutableSourceUpdate: (() -> ())? = if dataSource.type == "mutableSource"
		then dataSource.methods.bindToChanged(update)
		else nil

	local function destroy()
		if disconnectMutableSourceUpdate ~= nil then
			disconnectMutableSourceUpdate()
		end
	end

	return {
		setScrollAxis = setScrollAxis,
		setDataSource = setDataSource,

		setWindowAxis = setWindowAxis,
		getWindowAxis = getWindowAxis,

		get = get,
		getCanvasSize = getCanvasSize,
		getRange = getRange,

		bindToUpdate = bindToUpdate,

		destroy = destroy,
	}
end

return createVirtualizedListController
