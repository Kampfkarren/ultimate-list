--[[
	ReactTypedBindingsRenderer

	Extension of ReactBindingsRenderer that supports multiple item types
	in a single list. Each item type gets its own binding callback, and
	pool slots are only recycled within the same type.

	When a slot's item changes type, the slot is vacated and a new slot
	of the correct type is created. This ensures React never reconciles
	incompatible element trees (which would break hooks).

	Usage: see Renderers.byTypedBinding
]]
local Src = script:FindFirstAncestor("ultimate-list")

local Dimensions = require(Src.Dimensions)
local React = require(Src.Parent.React)
local createDebugLogger = require(Src.Util.createDebugLogger)
local createInitialSlots = require(script.Parent.createInitialSlots)
local createSlotElement = require(script.Parent.createSlotElement)
local createVirtualizedListController = require(Src.createVirtualizedListController)
local getKeyDefault = require(Src.Util.getKeyDefault)

local e = React.createElement

local log = createDebugLogger("ReactTypedBindingsRenderer")

type LocatedItem<T> = createSlotElement.LocatedItem<T>
type BindingAndSetter<T> = createInitialSlots.BindingAndSetter<T>

local function ReactTypedBindingsRenderer<T>(props: {
	virtualizedListController: createVirtualizedListController.VirtualizedListController<T>,
	scrollAxisBinding: React.Binding<number>,

	dimensions: Dimensions.Dimensions<T>,
	direction: "x" | "y",

	getItemType: (value: T) -> string,
	renderers: { [string]: (React.Binding<T?>) -> React.Node },
	primaryType: string,

	getKey: ((value: T, index: number) -> string)?,
})
	local itemBindingsAndSetters: { BindingAndSetter<T> }, setItemBindingsAndSetters = React.useState(function()
		return createInitialSlots(
			props.dimensions,
			props.virtualizedListController,
			props.direction,
			props.primaryType
		)
	end)

	local getKey: (value: T, index: number) -> string = props.getKey or getKeyDefault

	React.useEffect(function()
		return props.virtualizedListController.bindToUpdate(function()
			local newView = props.virtualizedListController.get()
			local newRange = props.virtualizedListController.getRange()

			local newKeyToItemIndexInView: { [string]: number? } = {}
			for index, itemInNewView in newView do
				newKeyToItemIndexInView[getKey(itemInNewView, index + (newRange.X - 1))] = index
			end

			-- Categorize existing slots by their immutable slotType.
			-- deadByType: slots whose key is no longer in view (or whose item changed type)
			-- vacantByType: slots that were already vacant
			local deadByType: { [string]: { (LocatedItem<T>) -> () } } = {}
			local vacantByType: { [string]: { (LocatedItem<T>) -> () } } = {}

			for _, bindingAndSetter in itemBindingsAndSetters do
				local locatedItem = bindingAndSetter.binding:getValue()
				local slotType = bindingAndSetter.slotType :: string

				if locatedItem.contents.type == "vacant" then
					if not vacantByType[slotType] then
						vacantByType[slotType] = {}
					end
					table.insert(vacantByType[slotType], bindingAndSetter.set)
					continue
				end

				local key = locatedItem.contents.key
				local itemIndexInView = newKeyToItemIndexInView[key]

				if itemIndexInView == nil then
					if not deadByType[slotType] then
						deadByType[slotType] = {}
					end
					table.insert(deadByType[slotType], bindingAndSetter.set)
				else
					local newValue = newView[itemIndexInView]
					local newType = props.getItemType(newValue)

					if newType ~= slotType then
						-- Item's type no longer matches this slot's type.
						-- Vacate the slot so it can be reused by an item of the same slotType.
						if not deadByType[slotType] then
							deadByType[slotType] = {}
						end
						table.insert(deadByType[slotType], bindingAndSetter.set)
					else
						newKeyToItemIndexInView[key] = nil
						if locatedItem.contents.value ~= newValue then
							log("%s existed, but changed", key)
							bindingAndSetter.set({
								contents = {
									type = "full",
									index = itemIndexInView + (newRange.X - 1),
									key = key,
									value = newValue,
									itemType = newType,
								},
							})
						end
					end
				end
			end

			-- Assign new/changed items to slots of matching type
			local newBindingsAndSetters: { BindingAndSetter<T> } = {}

			for newKey, indexInView in newKeyToItemIndexInView do
				assert(indexInView ~= nil, "Luau")
				local value = newView[indexInView]
				local itemType = props.getItemType(value)

				local newLocatedItem: LocatedItem<T> = {
					contents = {
						type = "full",
						index = indexInView + (newRange.X - 1),
						key = newKey,
						value = value,
						itemType = itemType,
					},
				}

				local deadList = deadByType[itemType]
				if deadList then
					local deadSetter = table.remove(deadList)
					if deadSetter then
						log("%s filling dead %s slot", newKey, itemType)
						deadSetter(newLocatedItem)
						continue
					end
				end

				local vacantList = vacantByType[itemType]
				if vacantList then
					local vacantSetter = table.remove(vacantList)
					if vacantSetter then
						log("%s filling vacant %s slot", newKey, itemType)
						vacantSetter(newLocatedItem)
						continue
					end
				end

				log("%s creating new %s slot", newKey, itemType)
				local binding, setBinding = React.createBinding(newLocatedItem)
				table.insert(newBindingsAndSetters, {
					binding = binding,
					set = setBinding,
					slotType = itemType,
				})
			end

			-- Vacate remaining dead slots. slotType on BindingAndSetter is NOT changed;
			-- the slot retains its type so it can be reused for items of the same type.
			for _, deadList in deadByType do
				for _, deadSetter in deadList do
					deadSetter({
						contents = { type = "vacant" },
					})
				end
			end

			-- TODO: Consider periodic compaction of excess vacant slots to bound pool growth.

			if #newBindingsAndSetters > 0 then
				log("Created %d new typed slots", #newBindingsAndSetters)
				setItemBindingsAndSetters(function(total)
					total = table.clone(total)
					table.move(newBindingsAndSetters, 1, #newBindingsAndSetters, #total + 1, total)
					return total
				end)
			end
		end)
	end, { props.virtualizedListController, getKey, itemBindingsAndSetters, props.getItemType } :: { unknown })

	local children: { [string]: React.Node } = {}
	for index, itemBindingAndSetter in itemBindingsAndSetters do
		local binding: React.Binding<LocatedItem<T>> = itemBindingAndSetter.binding :: any
		local slotType = itemBindingAndSetter.slotType :: string
		local callback = props.renderers[slotType]

		if callback == nil then
			error(`ReactTypedBindingsRenderer: no renderer registered for item type "{slotType}"`)
		end

		-- Key includes slot type so React unmounts/remounts on type change
		local key, element = createSlotElement(
			binding,
			props.scrollAxisBinding,
			props.dimensions,
			props.direction,
			props.virtualizedListController,
			callback,
			`{slotType}_{index}`
		)
		children[key] = element
	end

	return e(React.Fragment, {}, children)
end

ReactTypedBindingsRenderer = React.memo(ReactTypedBindingsRenderer) :: never

return ReactTypedBindingsRenderer
