local Src = script:FindFirstAncestor("UltimateList")

local DataSources = require(Src.DataSources)
local Dimensions = require(Src.Dimensions)
local React = require(Src.Parent.React)
local ReactBindingsRenderer = require(Src.Renderers.ReactBindingsRenderer)
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

	React.useEffect(function()
		return function()
			return virtualizedListController.destroy()
		end
	end, {})

	local canvasSizeBinding, setCanvasSize = React.useBinding(virtualizedListController.getCanvasSize())
	local windowSizeBinding, setWindowSize = React.useBinding(Vector2.zero)
	local scrollAxisBinding, setScrollAxis = React.useBinding(0)

	React.useEffect(function()
		return virtualizedListController.bindToUpdate(function()
			setCanvasSize(virtualizedListController.getCanvasSize())
		end)
	end, {})

	local onAbsoluteWindowSizeChanged = React.useCallback(function(instance: ScrollingFrame)
		setWindowSize(instance.AbsoluteWindowSize)
		virtualizedListController.setWindowAxis(
			if props.direction == "x"
				then instance.AbsoluteWindowSize.X
				elseif props.direction == "y" then instance.AbsoluteWindowSize.Y
				else exhaustiveMatch(props.direction)
		)
	end, { props.direction })

	local onCanvasPositionChanged = React.useCallback(function(instance: ScrollingFrame)
		local scrollAxis = if props.direction == "x"
			then instance.CanvasPosition.X
			elseif props.direction == "y" then instance.CanvasPosition.Y
			else exhaustiveMatch(props.direction)

		virtualizedListController.setScrollAxis(scrollAxis)
		setScrollAxis(scrollAxis)
	end, { props.direction })

	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		ScrollingFrame = e("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1),

			CanvasSize = canvasSizeBinding,

			-- Luau: No multiple indexers
			[React.Change.AbsoluteWindowSize] = onAbsoluteWindowSizeChanged :: any,
			[React.Change.CanvasPosition] = onCanvasPositionChanged :: any,
			[React.Tag] = props.tag,
		}),

		-- This is outside of the scrolling frame because CanvasPosition updates a bit too late even
		-- in the case of bindings, showing you emptiness before we have a chance to react.
		RendererOverlay = e("Frame", {
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			-- Match window size so you can still see scroll bar
			Size = windowSizeBinding:map(function(windowSize: Vector2)
				return UDim2.fromOffset(windowSize.X, windowSize.Y)
			end),
			ZIndex = 2,
		}, {
			Renderer = if props.renderer.type == "byState"
				then e(ReactStateRenderer, {
					virtualizedListController = virtualizedListController,
					scrollAxisBinding = scrollAxisBinding,

					dimensions = props.dimensions,
					direction = props.direction,

					callback = props.renderer.callback,
					getKey = props.getKey,
				})
				elseif props.renderer.type == "byBinding" then e(ReactBindingsRenderer, {
					virtualizedListController = virtualizedListController,
					scrollAxisBinding = scrollAxisBinding,

					dimensions = props.dimensions,
					direction = props.direction,

					callback = props.renderer.callback,
					getKey = props.getKey,
				})
				else exhaustiveMatch(props.renderer.type),
		}),
	})
end

return ScrollingFrame
