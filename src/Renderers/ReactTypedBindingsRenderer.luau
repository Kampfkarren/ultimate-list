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

-- Each typed slot carries the type it was created with. Once set, slotType
-- never changes for a given binding--slots are only recycled within their type.
type TypedBindingAndSetter<T> = {
	binding: React.Binding<LocatedItem<T>>,
	set: (LocatedItem<T>) -> (),
	slotType: string,
}

type SetterBucketsByType<T> = { [string]: { (LocatedItem<T>) -> () } }

local function pushInto<T>(buckets: SetterBucketsByType<T>, key: string, setter: (LocatedItem<T>) -> ())
	if not buckets[key] then
		buckets[key] = {}
	end
	table.insert(buckets[key], setter)
end

-- Pop a setter from buckets[itemType], or nil if none available.
local function takeFromBucket<T>(buckets: SetterBucketsByType<T>, itemType: string): ((LocatedItem<T>) -> ())?
	local list = buckets[itemType]
	if list == nil then
		return nil
	end
	return table.remove(list)
end

-- Categorize existing slots by their immutable slotType.
-- - deadByType: slots whose key is no longer in view (or whose item changed type)
-- - vacantByType: slots that were already vacant
-- Still-alive-same-type slots are updated in place.
local function classifyExistingSlots<T>(
	bindingsAndSetters: { TypedBindingAndSetter<T> },
	newView: { T },
	newRange: Vector3,
	newKeyToItemIndexInView: { [string]: number? },
	getItemType: (value: T) -> string
): (SetterBucketsByType<T>, SetterBucketsByType<T>)
	local deadByType: SetterBucketsByType<T> = {}
	local vacantByType: SetterBucketsByType<T> = {}

	for _, bindingAndSetter in bindingsAndSetters do
		local locatedItem = bindingAndSetter.binding:getValue()
		local slotType = bindingAndSetter.slotType

		if locatedItem.contents.type == "vacant" then
			pushInto(vacantByType, slotType, bindingAndSetter.set)
			continue
		end

		local key = locatedItem.contents.key
		local itemIndexInView = newKeyToItemIndexInView[key]

		if itemIndexInView == nil then
			pushInto(deadByType, slotType, bindingAndSetter.set)
			continue
		end

		local newValue = newView[itemIndexInView]
		local newType = getItemType(newValue)

		if newType ~= slotType then
			-- Item's type no longer matches this slot's type.
			-- Vacate the slot so it can be reused by an item of the same slotType.
			pushInto(deadByType, slotType, bindingAndSetter.set)
			continue
		end

		newKeyToItemIndexInView[key] = nil
		if locatedItem.contents.value ~= newValue then
			log("%s existed, but changed", key)
			bindingAndSetter.set({
				contents = {
					type = "full",
					index = itemIndexInView + (newRange.X - 1),
					key = key,
					value = newValue,
				},
			})
		end
	end

	return deadByType, vacantByType
end

-- Assign new/changed items to slots of matching type, preferring dead slots
-- (they'd otherwise become vacant), then vacant slots, then creating fresh ones.
local function assignNewItems<T>(
	newView: { T },
	newRange: Vector3,
	newKeyToItemIndexInView: { [string]: number? },
	deadByType: SetterBucketsByType<T>,
	vacantByType: SetterBucketsByType<T>,
	getItemType: (value: T) -> string,
	renderers: { [string]: (React.Binding<T?>) -> React.Node }
): { TypedBindingAndSetter<T> }
	local newBindingsAndSetters: { TypedBindingAndSetter<T> } = {}

	for newKey, indexInView in newKeyToItemIndexInView do
		assert(indexInView ~= nil, "Luau")
		local value = newView[indexInView]
		local itemType = getItemType(value)

		if renderers[itemType] == nil then
			error(
				`ReactTypedBindingsRenderer: getItemType returned unknown type "{itemType}" `
					.. `for item at index {indexInView + (newRange.X - 1)} (key "{newKey}"); `
					.. `no renderer registered.`
			)
		end

		local newLocatedItem: LocatedItem<T> = {
			contents = {
				type = "full",
				index = indexInView + (newRange.X - 1),
				key = newKey,
				value = value,
			},
		}

		local deadSetter = takeFromBucket(deadByType, itemType)
		if deadSetter then
			log("%s filling dead %s slot", newKey, itemType)
			deadSetter(newLocatedItem)
			continue
		end

		local vacantSetter = takeFromBucket(vacantByType, itemType)
		if vacantSetter then
			log("%s filling vacant %s slot", newKey, itemType)
			vacantSetter(newLocatedItem)
			continue
		end

		log("%s creating new %s slot", newKey, itemType)
		local binding, setBinding = React.createBinding(newLocatedItem)
		table.insert(newBindingsAndSetters, {
			binding = binding,
			set = setBinding,
			slotType = itemType,
		})
	end

	return newBindingsAndSetters
end

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
	local itemBindingsAndSetters: { TypedBindingAndSetter<T> }, setItemBindingsAndSetters = React.useState(function()
		-- Pre-allocated slots are stamped with primaryType; slots for other
		-- types are created lazily as those items scroll in.
		local initial = createInitialSlots(props.dimensions, props.virtualizedListController, props.direction)

		local typed: { TypedBindingAndSetter<T> } = table.create(#initial)
		for _, bindingAndSetter in initial do
			table.insert(typed, {
				binding = bindingAndSetter.binding,
				set = bindingAndSetter.set,
				slotType = props.primaryType,
			})
		end
		return typed
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

			local deadByType, vacantByType = classifyExistingSlots(
				itemBindingsAndSetters,
				newView,
				newRange,
				newKeyToItemIndexInView,
				props.getItemType
			)

			local newBindingsAndSetters = assignNewItems(
				newView,
				newRange,
				newKeyToItemIndexInView,
				deadByType,
				vacantByType,
				props.getItemType,
				props.renderers
			)

			-- Vacate remaining dead slots. slotType is NOT changed; the slot
			-- retains its type so it can be reused for items of the same type.
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
		local slotType = itemBindingAndSetter.slotType
		local callback = props.renderers[slotType]

		-- Should be unreachable: assignNewItems validates types before creating slots
		-- and primaryType is validated at Renderers.byTypedBinding construction time.
		if callback == nil then
			error(`ReactTypedBindingsRenderer: no renderer registered for item type "{slotType}"`)
		end

		-- Key namespaced by slotType because two slots in different pools
		-- can share the same numeric index.
		local key, element = createSlotElement(
			itemBindingAndSetter.binding,
			props.scrollAxisBinding,
			props.dimensions,
			props.direction,
			props.virtualizedListController,
			callback,
			`{slotType}_Item{index}`
		)
		children[key] = element
	end

	return e(React.Fragment, {}, children)
end

ReactTypedBindingsRenderer = React.memo(ReactTypedBindingsRenderer) :: never

return ReactTypedBindingsRenderer
