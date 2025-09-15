local Src = script:FindFirstAncestor("UltimateList")

local Dimensions = require(Src.Dimensions)
local DimensionsMethods = require(Src.Dimensions.DimensionsMethods)
local React = require(Src.Parent.React)
local createVirtualizedListController = require(Src.createVirtualizedListController)

local e = React.createElement

local function getKeyDefault<T>(_value: T, index: number): string
	return tostring(index)
end

local function ReactStateRenderer<T>(props: {
	virtualizedListController: createVirtualizedListController.VirtualizedListController<T>,

	dimensions: Dimensions.Dimensions<T>,
	direction: "x" | "y",

	callback: (T) -> React.Node,
	getKey: ((value: T, index: number) -> string)?,
})
	local items, setItems = React.useState(props.virtualizedListController.get)

	React.useEffect(function()
		return props.virtualizedListController.bindToUpdate(function()
			setItems(props.virtualizedListController.get())
		end)
	end, { props.virtualizedListController })

	local children: { [string]: React.Node } = {}
	local getKey: (value: T, index: number) -> string = props.getKey or getKeyDefault
	local range = props.virtualizedListController.getRange()

	for relativeIndex, item in items do
		local index = range.X + (relativeIndex - 1)

		local dimensionsRect = DimensionsMethods.getUDimRect(props.dimensions, item, index, props.direction)

		children[getKey(item, index)] = e("Frame", {
			BackgroundTransparency = 1,
			Position = dimensionsRect.position,
			Size = dimensionsRect.size,
		}, props.callback(item))
	end

	return e(React.Fragment, nil, children)
end

return ReactStateRenderer
