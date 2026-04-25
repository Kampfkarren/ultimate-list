local Src = script:FindFirstAncestor("ultimate-list")

local Dimensions = require(Src.Dimensions)
local React = require(Src.Parent.React)
local createDebugLogger = require(Src.Util.createDebugLogger)
local createSlotElement = require(script.Parent.createSlotElement)
local createVirtualizedListController = require(Src.createVirtualizedListController)
local deriveValueBinding = require(script.Parent.deriveValueBinding)
local getKeyDefault = require(Src.Util.getKeyDefault)

local e = React.createElement

local log = createDebugLogger("ReactTypedBindingsRenderer")

type LocatedItem<T> = createSlotElement.LocatedItem<T>

type Slot<T> = {
	binding: React.Binding<LocatedItem<T>>,
	set: (LocatedItem<T>) -> (),
	content: React.Node,
}

-- A slot lives in exactly one pool for its lifetime; that structurally
-- enforces the "only recycled for items classified to the same renderer"
-- invariant without needing to carry the rendererIndex on each slot.
type SlotsByRenderer<T> = { [number]: { Slot<T> } }

type RecycleQueuesByRenderer<T> = { [number]: { (LocatedItem<T>) -> () } }

local function createEmptyPools<T>(rendererCount: number): { { T } }
	local pools = table.create(rendererCount)
	for index = 1, rendererCount do
		pools[index] = {}
	end
	return pools
end

local function classifyAndBuild<T>(
	valueBinding: React.Binding<T?>,
	renderers: { (React.Binding<T?>) -> React.Node? }
): (number, React.Node)
	for index, renderer in renderers do
		local node = renderer(valueBinding)
		if node ~= nil then
			return index, node
		end
	end

	error(
		"ReactTypedBindingsRenderer: no renderer accepted the current value. "
			.. "Ensure at least one renderer returns a non-nil React.Node for "
			.. "every possible item value."
	)
end

local function bucketExistingSlots<T>(
	slotsByRenderer: SlotsByRenderer<T>,
	newView: { T },
	newRange: Vector3,
	newKeyToItemIndexInView: { [string]: number? }
): (RecycleQueuesByRenderer<T>, RecycleQueuesByRenderer<T>)
	local rendererCount = #slotsByRenderer
	local dead: RecycleQueuesByRenderer<T> = createEmptyPools(rendererCount)
	local vacant: RecycleQueuesByRenderer<T> = createEmptyPools(rendererCount)

	for rendererIndex, pool in slotsByRenderer do
		for _, slot in pool do
			local locatedItem = slot.binding:getValue()

			if locatedItem.type == "vacant" then
				table.insert(vacant[rendererIndex], slot.set)
				continue
			end

			local key = locatedItem.key
			local itemIndexInView = newKeyToItemIndexInView[key]

			if itemIndexInView == nil then
				log("%s is now dead", key)
				table.insert(dead[rendererIndex], slot.set)
				continue
			end

			newKeyToItemIndexInView[key] = nil
			local newValue = newView[itemIndexInView]
			if locatedItem.value ~= newValue then
				log("%s existed, but changed", key)
				slot.set({
					type = "full",
					index = itemIndexInView + (newRange.X - 1),
					key = key,
					value = newValue,
				})
			end
		end
	end

	return dead, vacant
end

local function assignNewItems<T>(
	newView: { T },
	newRange: Vector3,
	newKeyToItemIndexInView: { [string]: number? },
	dead: RecycleQueuesByRenderer<T>,
	vacant: RecycleQueuesByRenderer<T>,
	renderers: { (React.Binding<T?>) -> React.Node? }
): (SlotsByRenderer<T>, boolean)
	local newSlotsByRenderer: SlotsByRenderer<T> = createEmptyPools(#renderers)
	local hasNewSlots = false

	for newKey, indexInView in newKeyToItemIndexInView do
		assert(indexInView ~= nil, "Luau")
		local value = newView[indexInView]

		local newLocatedItem: LocatedItem<T> = {
			type = "full",
			index = indexInView + (newRange.X - 1),
			key = newKey,
			value = value,
		}

		local binding, setBinding = React.createBinding(newLocatedItem)
		local rendererIndex, content = classifyAndBuild(deriveValueBinding(binding), renderers)

		local deadSetter = table.remove(dead[rendererIndex], #dead[rendererIndex])
		if deadSetter then
			log("%s is filling dead renderer[%d] spot", newKey, rendererIndex)
			deadSetter(newLocatedItem)
			continue
		end

		local vacantSetter = table.remove(vacant[rendererIndex], #vacant[rendererIndex])
		if vacantSetter then
			log("%s is filling vacant renderer[%d] spot", newKey, rendererIndex)
			vacantSetter(newLocatedItem)
			continue
		end

		log("%s needs a new renderer[%d] slot", newKey, rendererIndex)
		table.insert(newSlotsByRenderer[rendererIndex], {
			binding = binding,
			set = setBinding,
			content = content,
		})
		hasNewSlots = true
	end

	return newSlotsByRenderer, hasNewSlots
end

local function ReactTypedBindingsRenderer<T>(props: {
	virtualizedListController: createVirtualizedListController.VirtualizedListController<T>,
	scrollAxisBinding: React.Binding<number>,

	dimensions: Dimensions.Dimensions<T>,
	direction: "x" | "y",

	renderers: { (React.Binding<T?>) -> React.Node? },

	getKey: ((value: T, index: number) -> string)?,
})
	local slotsByRenderer: SlotsByRenderer<T>, setSlotsByRenderer = React.useState(function()
		return createEmptyPools(#props.renderers)
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

			local dead, vacant = bucketExistingSlots(slotsByRenderer, newView, newRange, newKeyToItemIndexInView)

			local newSlotsByRenderer, hasNewSlots =
				assignNewItems(newView, newRange, newKeyToItemIndexInView, dead, vacant, props.renderers)

			if hasNewSlots then
				log("Created new typed slots")
				setSlotsByRenderer(function(prev)
					local nextPools = table.clone(prev)
					for rendererIndex, newSlots in newSlotsByRenderer do
						if #newSlots == 0 then
							continue
						end
						local extended = table.clone(prev[rendererIndex])
						table.move(newSlots, 1, #newSlots, #extended + 1, extended)
						nextPools[rendererIndex] = extended
					end
					return nextPools
				end)
			end

			for _, deadQueue in dead do
				for _, deadSetter in deadQueue do
					deadSetter({
						type = "vacant",
					})
				end
			end
		end)
	end, { props.virtualizedListController, getKey, slotsByRenderer, props.renderers } :: { unknown })

	local children: { [string]: React.Node } = {}
	for rendererIndex, pool in slotsByRenderer do
		for index, slot in pool do
			local key = `renderer{rendererIndex}_Item{index}`
			children[key] = createSlotElement(
				slot.binding,
				props.scrollAxisBinding,
				props.dimensions,
				props.direction,
				props.virtualizedListController,
				slot.content
			)
		end
	end

	return e(React.Fragment, {}, children)
end

ReactTypedBindingsRenderer = React.memo(ReactTypedBindingsRenderer) :: never

return ReactTypedBindingsRenderer
