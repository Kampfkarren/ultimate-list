local Src = script:FindFirstAncestor("UltimateList")

local DataSources = require(Src.DataSources)
local Dimensions = require(Src.Dimensions)
local React = require(Src.Parent.React)
local ReactStateRenderer = require(Src.Renderers.ReactStateRenderer)
local Renderers = require(Src.Renderers)
local createVirtualizedListController = require(Src.createVirtualizedListController)
local exhaustiveMatch = require(Src.Util.exhaustiveMatch)

local e = React.createElement

local function ScrollingFrame<T>(
	props: {
		dataSource: DataSources.DataSource<T>,
		dimensions: Dimensions.Dimensions<T>,
		renderer: Renderers.Renderer<T>,

		-- Will use index as key otherwise, which is fine for append-only cases.
		getKey: ((value: T, index: number) -> string)?,

		direction: "x" | "y",

		tag: string?,
	}
)
	local virtualizedListController = React.useState(function()
		return createVirtualizedListController(props.dataSource, props.dimensions, props.direction)
	end)

	local canvasSizeBinding, setCanvasSize = React.useBinding(virtualizedListController.getCanvasSize())

	React.useEffect(function()
		return virtualizedListController.bindToUpdate(function()
			setCanvasSize(virtualizedListController.getCanvasSize())
		end)
	end, {})

	local onAbsoluteWindowSizeChanged = React.useCallback(function(instance: ScrollingFrame)
		virtualizedListController.setWindowAxis(
			if props.direction == "x"
				then instance.AbsoluteWindowSize.X
				elseif props.direction == "y" then instance.AbsoluteWindowSize.Y
				else exhaustiveMatch(props.direction)
		)
	end, { props.direction })

	local onCanvasPositionChanged = React.useCallback(function(instance: ScrollingFrame)
		virtualizedListController.setScrollAxis(
			if props.direction == "x"
				then instance.CanvasPosition.X
				elseif props.direction == "y" then instance.CanvasPosition.Y
				else exhaustiveMatch(props.direction)
		)
	end, { props.direction })

	return e("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),

		CanvasSize = canvasSizeBinding,

		-- Luau: No multiple indexers
		[React.Change.AbsoluteWindowSize] = onAbsoluteWindowSizeChanged :: any,
		[React.Change.CanvasPosition] = onCanvasPositionChanged :: any,
		[React.Tag] = props.tag,
	}, {
		Renderer = if props.renderer.type == "byState"
			then e(ReactStateRenderer, {
				virtualizedListController = virtualizedListController,

				dimensions = props.dimensions,
				direction = props.direction,

				callback = props.renderer.callback,
				getKey = props.getKey,
			})
			elseif props.renderer.type == "byBinding" then error("NYI: byBinding")
			else exhaustiveMatch(props.renderer.type),
	})
end

return ScrollingFrame
