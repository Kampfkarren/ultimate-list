local Src = script:FindFirstAncestor("ultimate-list")

local Dimensions = require(Src.Dimensions)
local React = require(Src.Parent.React)
local ReactBindingsRenderer = require(Src.Renderers.ReactBindingsRenderer)
local ReactStateRenderer = require(Src.Renderers.ReactStateRenderer)
local Renderers = require(Src.Renderers)
local createVirtualizedListController = require(Src.createVirtualizedListController)
local exhaustiveMatch = require(Src.Util.exhaustiveMatch)

local e = React.createElement

local function RendererOverlay<T>(props: {
	dimensions: Dimensions.Dimensions<T>,
	renderer: Renderers.Renderer<T>,
	getKey: ((value: T, index: number) -> string)?,
	direction: "x" | "y",

	virtualizedListController: createVirtualizedListController.VirtualizedListController<T>,
	windowSizeBinding: React.Binding<Vector2>,
	scrollAxisBinding: React.Binding<number>,
	positionBinding: React.Binding<UDim2>?,
	fillNonDominantAxis: boolean?,
})
	return e("Frame", {
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Position = props.positionBinding,
		Size = props.windowSizeBinding:map(function(windowSize: Vector2)
			if props.fillNonDominantAxis ~= true then
				return UDim2.fromOffset(windowSize.X, windowSize.Y)
			end

			return if props.direction == "x"
				then UDim2.new(0, windowSize.X, 1, 0)
				elseif props.direction == "y" then UDim2.new(1, 0, 0, windowSize.Y)
				else exhaustiveMatch(props.direction)
		end),
		ZIndex = 2,
	}, {
		Renderer = if props.renderer.type == "byState"
			then e(ReactStateRenderer, {
				virtualizedListController = props.virtualizedListController,

				config = props.renderer.config,

				dimensions = props.dimensions,
				direction = props.direction,

				callback = props.renderer.callback,
				getKey = props.getKey,

				scrollAxisBinding = props.scrollAxisBinding,
			})
			elseif props.renderer.type == "byBinding" then e(ReactBindingsRenderer, {
				virtualizedListController = props.virtualizedListController,
				scrollAxisBinding = props.scrollAxisBinding,

				dimensions = props.dimensions,
				direction = props.direction,

				callback = props.renderer.callback,
				getKey = props.getKey,
			})
			else exhaustiveMatch(props.renderer.type),
	})
end

return RendererOverlay
