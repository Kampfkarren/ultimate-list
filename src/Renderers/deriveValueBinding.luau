local Src = script:FindFirstAncestor("ultimate-list")

local React = require(Src.Parent.React)
local createSlotElement = require(script.Parent.createSlotElement)

type LocatedItem<T> = createSlotElement.LocatedItem<T>

local function deriveValueBinding<T>(binding: React.Binding<LocatedItem<T>>): React.Binding<T?>
	return binding:map(function(locatedItem: LocatedItem<T>)
		return if locatedItem.type == "full" then locatedItem.value else nil
	end)
end

return deriveValueBinding
