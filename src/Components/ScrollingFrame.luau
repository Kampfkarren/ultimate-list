local RunService = game:GetService("RunService")
local Src = script:FindFirstAncestor("ultimate-list")

local DataSources = require(Src.DataSources)
local Dimensions = require(Src.Dimensions)
local React = require(Src.Parent.React)
local RendererOverlay = require(script.Parent.RendererOverlay)
local Renderers = require(Src.Renderers)
local exhaustiveMatch = require(Src.Util.exhaustiveMatch)
local useVirtualizedList = require(script.Parent.useVirtualizedList)

local e = React.createElement

local function ScrollingFrame<T>(
	props: {
		dataSource: DataSources.DataSource<T>,
		dimensions: Dimensions.Dimensions<T>,
		renderer: Renderers.Renderer<T>,

		-- Will use index as key otherwise, which is fine for append-only cases.
		getKey: ((value: T, index: number) -> string)?,

		direction: "x" | "y",

		scrollingFrameRef: React.Ref<ScrollingFrame>?,
		onAbsoluteWindowSizeChanged: ((newWindowSize: Vector2) -> ())?,
		onScrollAxisChanged: ((newScrollAxis: number) -> ())?,

		tag: string?,
		native: { [any]: any }?,
	}
)
	local virtualizedList = useVirtualizedList(props)

	local onAbsoluteWindowSizeChanged = React.useCallback(function(instance: ScrollingFrame)
		virtualizedList.setWindowSize(instance.AbsoluteWindowSize)

		if props.onAbsoluteWindowSizeChanged ~= nil then
			props.onAbsoluteWindowSizeChanged(instance.AbsoluteWindowSize)
		end
	end, { props.direction, props.onAbsoluteWindowSizeChanged } :: { unknown })

	local onCanvasPositionChanged = React.useCallback(function(instance: ScrollingFrame)
		local scrollAxis = if props.direction == "x"
			then instance.CanvasPosition.X
			elseif props.direction == "y" then instance.CanvasPosition.Y
			else exhaustiveMatch(props.direction)

		-- In deferred signals, position properties update only on the frame *after*,
		-- which causes visible flickering.
		RunService.Heartbeat:Once(function()
			virtualizedList.setScrollAxis(scrollAxis)

			if props.onScrollAxisChanged ~= nil then
				props.onScrollAxisChanged(scrollAxis)
			end
		end)
	end, { props.direction, props.onScrollAxisChanged } :: { unknown })

	local scrollingFrameProps = {
		Size = UDim2.fromScale(1, 1),

		CanvasSize = virtualizedList.canvasSizeBinding,

		-- Luau: No multiple indexers
		[React.Change.AbsoluteWindowSize] = onAbsoluteWindowSizeChanged :: any,
		[React.Change.CanvasPosition] = onCanvasPositionChanged :: any,
		[React.Tag] = props.tag,

		ref = props.scrollingFrameRef,
	}

	if props.native ~= nil then
		for key, value in props.native do
			if scrollingFrameProps[key] ~= nil then
				error(`{key} is already used by UltimateList`)
			end

			scrollingFrameProps[key] = value
		end
	end

	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		ScrollingFrame = e("ScrollingFrame", scrollingFrameProps),

		-- This is outside of the scrolling frame because CanvasPosition updates a bit too late even
		-- in the case of bindings, showing you emptiness before we have a chance to react.
		RendererOverlay = e(RendererOverlay, {
			dimensions = props.dimensions,
			renderer = props.renderer,
			getKey = props.getKey,
			direction = props.direction,

			virtualizedListController = virtualizedList.virtualizedListController,
			windowSizeBinding = virtualizedList.windowSizeBinding,
			scrollAxisBinding = virtualizedList.scrollAxisBinding,
		}),
	})
end

return ScrollingFrame
