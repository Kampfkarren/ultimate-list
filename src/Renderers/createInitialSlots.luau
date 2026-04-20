--[[
	Shared slot pre-allocation for binding-based renderers.

	Uses elementsDisplayedHint to determine how many slots to create upfront,
	then creates that many vacant LocatedItem bindings.
]]
local Src = script:FindFirstAncestor("ultimate-list")

local Dimensions = require(Src.Dimensions)
local DimensionsMethods = require(Src.Dimensions.DimensionsMethods)
local React = require(Src.Parent.React)
local createSlotElement = require(script.Parent.createSlotElement)
local createVirtualizedListController = require(Src.createVirtualizedListController)

type LocatedItem<T> = createSlotElement.LocatedItem<T>

export type BindingAndSetter<T> = {
	binding: React.Binding<LocatedItem<T>>,
	set: (LocatedItem<T>) -> (),
}

local function createInitialSlots<T>(
	dimensions: Dimensions.Dimensions<T>,
	virtualizedListController: createVirtualizedListController.VirtualizedListController<T>,
	direction: "x" | "y"
): { BindingAndSetter<T> }
	local total: { BindingAndSetter<T> } = {}

	local countHint = DimensionsMethods.elementsDisplayedHint(
		dimensions,
		virtualizedListController.getWindowSize(),
		direction
	)
	if countHint == nil then
		return total
	end

	for _ = 1, countHint do
		local binding, setBinding = React.createBinding({
			contents = { type = "vacant" },
		} :: LocatedItem<T>)

		table.insert(total, {
			binding = binding,
			set = setBinding,
		})
	end

	return total
end

return createInitialSlots
