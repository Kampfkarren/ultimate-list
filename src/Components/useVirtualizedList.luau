local Src = script:FindFirstAncestor("ultimate-list")

local DataSources = require(Src.DataSources)
local Dimensions = require(Src.Dimensions)
local React = require(Src.Parent.React)
local createVirtualizedListController = require(Src.createVirtualizedListController)

export type VirtualizedList<T> = {
	virtualizedListController: createVirtualizedListController.VirtualizedListController<T>,

	canvasSizeBinding: React.Binding<UDim2>,
	windowSizeBinding: React.Binding<Vector2>,
	scrollAxisBinding: React.Binding<number>,

	setWindowSize: (windowSize: Vector2) -> (),
	setScrollAxis: (scrollAxis: number) -> (),
}

local function useVirtualizedList<T>(props: {
	dataSource: DataSources.DataSource<T>,
	dimensions: Dimensions.Dimensions<T>,
	direction: "x" | "y",
	overscan: number?,
}): VirtualizedList<T>
	local virtualizedListController = React.useState(function()
		return createVirtualizedListController(props.dataSource, props.dimensions, props.direction)
	end)

	React.useEffect(function()
		return function()
			virtualizedListController.destroy()
		end
	end, {})

	local canvasSizeBinding, setCanvasSize = React.useBinding(virtualizedListController.getCanvasSize())
	local windowSizeBinding, setWindowSizeBinding = React.useBinding(Vector2.zero)
	local scrollAxisBinding, setScrollAxisBinding = React.useBinding(0)

	React.useEffect(function()
		return virtualizedListController.bindToUpdate(function()
			setCanvasSize(virtualizedListController.getCanvasSize())
		end)
	end, { virtualizedListController })

	local setWindowSize = React.useCallback(function(windowSize: Vector2)
		setWindowSizeBinding(windowSize)
		virtualizedListController.setWindowSize(windowSize)
	end, { virtualizedListController } :: { unknown })

	local setScrollAxis = React.useCallback(function(scrollAxis: number)
		virtualizedListController.setScrollAxis(scrollAxis)
		setScrollAxisBinding(scrollAxis)
	end, { virtualizedListController } :: { unknown })

	React.useEffect(function()
		virtualizedListController.setDataSource(props.dataSource)
	end, { props.dataSource })

	React.useEffect(function()
		virtualizedListController.setDimensions(props.dimensions)
	end, { props.dimensions })

	React.useEffect(function()
		virtualizedListController.setOverscan(props.overscan or 0)
	end, { props.overscan })

	return {
		virtualizedListController = virtualizedListController,

		canvasSizeBinding = canvasSizeBinding,
		windowSizeBinding = windowSizeBinding,
		scrollAxisBinding = scrollAxisBinding,

		setWindowSize = setWindowSize,
		setScrollAxis = setScrollAxis,
	}
end

return useVirtualizedList
