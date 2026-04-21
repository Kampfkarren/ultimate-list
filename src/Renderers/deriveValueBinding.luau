--[[
	Derive the T? view of a slot's LocatedItem<T> binding: the current item
	value when the slot is full, or nil when vacant. Used by binding-based
	renderers to hand user callbacks a simple Binding<T?> without exposing
	the LocatedItem wrapper.
]]
local Src = script:FindFirstAncestor("ultimate-list")

local React = require(Src.Parent.React)
local createSlotElement = require(script.Parent.createSlotElement)

type LocatedItem<T> = createSlotElement.LocatedItem<T>

local function deriveValueBinding<T>(binding: React.Binding<LocatedItem<T>>): React.Binding<T?>
	return binding:map(function(locatedItem: LocatedItem<T>)
		return if locatedItem.contents.type == "full" then locatedItem.contents.value else nil
	end)
end

return deriveValueBinding
