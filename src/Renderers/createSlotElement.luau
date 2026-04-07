--[[
	Shared render-phase helper for binding-based renderers.

	Given a LocatedItem<T> binding, dimensions context, and a render callback,
	produces the positioned Frame container with Size/Position/Visible bindings
	and the Content child from the callback.
]]
local Src = script:FindFirstAncestor("ultimate-list")

local Dimensions = require(Src.Dimensions)
local DimensionsMethods = require(Src.Dimensions.DimensionsMethods)
local React = require(Src.Parent.React)
local adjustPositionToScrollAxis = require(Src.Dimensions.adjustPositionToScrollAxis)
local createVirtualizedListController = require(Src.createVirtualizedListController)
local joinAndMapBindings = require(Src.Util.joinAndMapBindings)

local e = React.createElement

export type LocatedItem<T> = {
	contents: {
		type: "vacant",
	} | {
		type: "full",
		index: number,
		key: string,
		value: T,
		-- Present on typed binding items; absent on plain binding items.
		itemType: string?,
	},
}

local function createSlotElement<T>(
	binding: React.Binding<LocatedItem<T>>,
	scrollAxisBinding: React.Binding<number>,
	dimensions: Dimensions.Dimensions<T>,
	direction: "x" | "y",
	virtualizedListController: createVirtualizedListController.VirtualizedListController<T>,
	callback: (React.Binding<T?>) -> React.Node,
	key: string
): (string, React.Node)
	local udimRectBinding: React.Binding<Dimensions.UDimRect> = binding:map(function(locatedItem: LocatedItem<T>)
		if locatedItem.contents.type == "vacant" then
			return {
				size = UDim2.new(),
				position = UDim2.new(),
			}
		end

		return DimensionsMethods.getUDimRect(
			dimensions,
			locatedItem.contents.value,
			locatedItem.contents.index,
			virtualizedListController.getWindowSize(),
			direction
		)
	end)

	local element = e("Frame", {
		BackgroundTransparency = 1,

		Position = joinAndMapBindings(function(udimRect: Dimensions.UDimRect, scrollAxis: number)
			return adjustPositionToScrollAxis(udimRect.position, scrollAxis, direction)
		end, udimRectBinding, scrollAxisBinding),

		Size = udimRectBinding:map(function(udimRect: Dimensions.UDimRect)
			return udimRect.size
		end),

		Visible = binding:map(function(locatedItem: LocatedItem<T>)
			return locatedItem.contents.type == "full"
		end),
	}, {
		Content = callback(binding:map(function(locatedItem: LocatedItem<T>)
			return if locatedItem.contents.type == "full" then locatedItem.contents.value else nil
		end)),
	})

	return key, element
end

return createSlotElement
