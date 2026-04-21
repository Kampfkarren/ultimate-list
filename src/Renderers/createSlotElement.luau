--[[
	Shared render-phase helper for binding-based renderers.

	Given a LocatedItem<T> binding and dimensions context, produces the
	positioned Frame container with Size/Position/Visible bindings, wrapping
	a caller-provided Content node.

	Callers are responsible for deriving the `T?` view of the binding and
	building Content themselves--this helper only owns the Frame wrapper.
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
	},
}

local function createSlotElement<T>(
	binding: React.Binding<LocatedItem<T>>,
	scrollAxisBinding: React.Binding<number>,
	dimensions: Dimensions.Dimensions<T>,
	direction: "x" | "y",
	virtualizedListController: createVirtualizedListController.VirtualizedListController<T>,
	content: React.Node
): React.Node
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

	return e("Frame", {
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
		Content = content,
	})
end

return createSlotElement
