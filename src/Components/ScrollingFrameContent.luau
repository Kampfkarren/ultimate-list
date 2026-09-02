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

local function getScrollAxis(canvasPosition: Vector2, direction: "x" | "y"): number
	return if direction == "x"
		then canvasPosition.X
		elseif direction == "y" then canvasPosition.Y
		else exhaustiveMatch(direction)
end

local function getPosition(scrollAxis: number, direction: "x" | "y"): UDim2
	return if direction == "x"
		then UDim2.fromOffset(scrollAxis, 0)
		elseif direction == "y" then UDim2.fromOffset(0, scrollAxis)
		else exhaustiveMatch(direction)
end

local function getContentSize(canvasSize: UDim2, direction: "x" | "y"): UDim2
	return if direction == "x"
		then UDim2.new(0, canvasSize.X.Offset, 1, 0)
		elseif direction == "y" then UDim2.new(1, 0, 0, canvasSize.Y.Offset)
		else exhaustiveMatch(direction)
end

local function ScrollingFrameContent<T>(props: {
	dataSource: DataSources.DataSource<T>,
	dimensions: Dimensions.Dimensions<T>,
	renderer: Renderers.Renderer<T>,

	-- Will use index as key otherwise, which is fine for append-only cases.
	getKey: ((value: T, index: number) -> string)?,

	direction: "x" | "y",

	scrollingFrameRef: { current: ScrollingFrame? },
	onAbsoluteWindowSizeChanged: ((newWindowSize: Vector2) -> ())?,
	onScrollAxisChanged: ((newScrollAxis: number) -> ())?,
	overscan: number?,
})
	local virtualizedList = useVirtualizedList(props)
	local overlayPositionBinding, setOverlayPosition = React.useBinding(UDim2.new())

	React.useEffect(function()
		local scrollingFrame = props.scrollingFrameRef.current
		assert(
			scrollingFrame ~= nil,
			"ScrollingFrameContent requires scrollingFrameRef.current to point to its ancestor ScrollingFrame"
		)

		local lastWindowSize: Vector2? = nil
		local lastScrollAxis: number? = nil

		local function syncMetrics()
			local windowSize = scrollingFrame.AbsoluteWindowSize
			if windowSize ~= lastWindowSize then
				lastWindowSize = windowSize
				virtualizedList.setWindowSize(windowSize)

				if props.onAbsoluteWindowSizeChanged ~= nil then
					props.onAbsoluteWindowSizeChanged(windowSize)
				end
			end

			local scrollAxis = getScrollAxis(scrollingFrame.CanvasPosition, props.direction)

			-- CanvasPosition signals can run before related layout properties have flushed in
			-- deferred mode. Re-applying this position on RenderStepped keeps the overlay flush
			-- with the externally owned scrolling window.
			setOverlayPosition(getPosition(scrollAxis, props.direction))
			virtualizedList.setScrollAxis(scrollAxis)

			if scrollAxis ~= lastScrollAxis then
				lastScrollAxis = scrollAxis

				if props.onScrollAxisChanged ~= nil then
					props.onScrollAxisChanged(scrollAxis)
				end
			end
		end

		local connections = {
			scrollingFrame:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(syncMetrics),
			scrollingFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(syncMetrics),
			RunService.RenderStepped:Connect(syncMetrics),
		}

		syncMetrics()

		return function()
			for _, connection in connections do
				connection:Disconnect()
			end
		end
	end, {
		props.scrollingFrameRef,
		props.direction,
		props.onAbsoluteWindowSizeChanged,
		props.onScrollAxisChanged,
		virtualizedList.setWindowSize,
		virtualizedList.setScrollAxis,
	} :: { unknown })

	return e("Frame", {
		BackgroundTransparency = 1,
		Size = virtualizedList.canvasSizeBinding:map(function(canvasSize: UDim2)
			return getContentSize(canvasSize, props.direction)
		end),
	}, {
		RendererOverlay = e(RendererOverlay, {
			dimensions = props.dimensions,
			renderer = props.renderer,
			getKey = props.getKey,
			direction = props.direction,

			virtualizedListController = virtualizedList.virtualizedListController,
			windowSizeBinding = virtualizedList.windowSizeBinding,
			scrollAxisBinding = virtualizedList.scrollAxisBinding,
			positionBinding = overlayPositionBinding,
			fillNonDominantAxis = true,
		}),
	})
end

return ScrollingFrameContent
