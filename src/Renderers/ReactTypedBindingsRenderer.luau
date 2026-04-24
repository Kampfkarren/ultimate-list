--[[
	ReactTypedBindingsRenderer

	Extension of ReactBindingsRenderer that supports multiple item types in a
	single list via separate recycling pools per renderer.

	Each renderer has signature `(React.Binding<T?>) -> React.Node?`. They
	are tried in array order; the first to return a non-nil node claims the
	slot and its returned node becomes the slot's permanent subtree. As the
	slot is recycled, the binding's value changes and the subtree reacts via
	binding:map -- the renderer itself is never called again for that slot.

	Slots live in per-renderer pools (SlotsByRenderer<T>): a dense array
	indexed by renderer index, each entry a { Slot<T> }. The "recycles only
	within the same renderer's pool" invariant is structural rather than
	enforced at sync time.

	Contract:
	- Return nil ONLY when binding:getValue() is non-nil and of a type
	  this renderer doesn't handle. Callers that decline should early-
	  return before subscribing to the binding (no binding:map, etc.),
	  because decliners' subtrees are discarded and any subscriptions
	  they created leak until GC.
	- The first renderer is the primary: when preAllocate is true (the
	  default), it is called once per pre-allocated slot with a nil-
	  valued binding and must return a non-nil node. Its binding:map
	  callbacks must handle nil gracefully (typical: fall back to
	  empty strings / defaults). When preAllocate is false, no
	  pre-allocation happens and no renderer is ever called with a
	  nil-valued binding.
	- Stable key implies stable type: if two renders of the data source
	  emit the same key, they must resolve to the same renderer.

	Usage: see Renderers.byTypedBinding
]]
local Src = script:FindFirstAncestor("ultimate-list")

local Dimensions = require(Src.Dimensions)
local React = require(Src.Parent.React)
local createDebugLogger = require(Src.Util.createDebugLogger)
local createInitialSlots = require(script.Parent.createInitialSlots)
local createSlotElement = require(script.Parent.createSlotElement)
local createVirtualizedListController = require(Src.createVirtualizedListController)
local deriveValueBinding = require(script.Parent.deriveValueBinding)
local getKeyDefault = require(Src.Util.getKeyDefault)

local e = React.createElement

local log = createDebugLogger("ReactTypedBindingsRenderer")

type LocatedItem<T> = createSlotElement.LocatedItem<T>

-- A slot is a binding + its setter + the React.Node that the slot's
-- renderer produced for it. Which renderer owns the slot is encoded
-- structurally by which pool contains it (see SlotsByRenderer).
type Slot<T> = {
	binding: React.Binding<LocatedItem<T>>,
	set: (LocatedItem<T>) -> (),
	content: React.Node,
}

-- Dense array indexed by rendererIndex in [1, #renderers]. Every index
-- exists and holds an array (possibly empty). The invariant "a slot is
-- only recycled for items of the same classified type" is enforced by
-- the outer key: a slot lives in exactly one pool for its lifetime.
type SlotsByRenderer<T> = { [number]: { Slot<T> } }

-- Per-renderer recycle queues built each sync: dead (slot's key left view)
-- and vacant (slot was already empty). Dense over the same 1..#renderers
-- range as SlotsByRenderer, so lookups never need a nil-guard.
type RecycleQueuesByRenderer<T> = { [number]: { (LocatedItem<T>) -> () } }

local function createEmptyPools<T>(rendererCount: number): { { any } }
	local pools = table.create(rendererCount)
	for i = 1, rendererCount do
		pools[i] = {}
	end
	return pools
end

-- Iterate renderers in order with the slot's T? binding. The first to
-- return non-nil claims the slot; its index and returned node are both
-- the slot's for life. Errors if no renderer accepts.
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
		`ReactTypedBindingsRenderer: no renderer accepted the current value. `
			.. `Ensure at least one renderer returns a non-nil React.Node for `
			.. `every possible item value.`
	)
end

-- Build the initial SlotsByRenderer<T>. Pools are always dense over
-- 1..#renderers; when preAllocate is true (the default) we pre-populate
-- the first renderer's pool with countHint slots whose subtree comes
-- from renderers[1] called with a nil-valued binding (same as any
-- vacant slot). Every other pool starts empty and grows on demand as
-- matching items scroll in.
local function createSlotsByRenderer<T>(
	dimensions: Dimensions.Dimensions<T>,
	virtualizedListController: createVirtualizedListController.VirtualizedListController<T>,
	direction: "x" | "y",
	renderers: { (React.Binding<T?>) -> React.Node? },
	preAllocate: boolean
): SlotsByRenderer<T>
	local pools: SlotsByRenderer<T> = createEmptyPools(#renderers) :: any

	if not preAllocate then
		return pools
	end

	local primaryRenderer = renderers[1]
	local primaryPool = pools[1]
	for _, bindingAndSetter in createInitialSlots(dimensions, virtualizedListController, direction) do
		local content = primaryRenderer(deriveValueBinding(bindingAndSetter.binding))
		if content == nil then
			error(
				`ReactTypedBindingsRenderer: the first renderer (primary) returned nil for a `
					.. `vacant slot. The first renderer must return a node for nil values so `
					.. `pre-allocated slots have a committed subtree. Either reorder renderers `
					.. `so the one that handles vacant slots is first, or pass preAllocate = false.`
			)
		end

		table.insert(primaryPool, {
			binding = bindingAndSetter.binding,
			set = bindingAndSetter.set,
			content = content,
		})
	end
	return pools
end

-- Walk every pool: update-in-place any slot whose key is still in view,
-- and bucket the rest into dead / vacant recycle queues. The outer key
-- gives us the rendererIndex for free, so slots don't need to carry it.
local function bucketExistingSlots<T>(
	slotsByRenderer: SlotsByRenderer<T>,
	newView: { T },
	newRange: Vector3,
	newKeyToItemIndexInView: { [string]: number? }
): (RecycleQueuesByRenderer<T>, RecycleQueuesByRenderer<T>)
	local rendererCount = #slotsByRenderer
	local dead = createEmptyPools(rendererCount)
	local vacant = createEmptyPools(rendererCount)

	for rendererIndex, pool in slotsByRenderer do
		for _, slot in pool do
			local locatedItem = slot.binding:getValue()

			if locatedItem.contents.type == "vacant" then
				table.insert(vacant[rendererIndex], slot.set)
				continue
			end

			local key = locatedItem.contents.key
			local itemIndexInView = newKeyToItemIndexInView[key]

			if itemIndexInView == nil then
				log("%s is now dead", key)
				table.insert(dead[rendererIndex], slot.set)
				continue
			end

			newKeyToItemIndexInView[key] = nil
			local newValue = newView[itemIndexInView]
			if locatedItem.contents.value ~= newValue then
				log("%s existed, but changed", key)
				slot.set({
					contents = {
						type = "full",
						index = itemIndexInView + (newRange.X - 1),
						key = key,
						value = newValue,
					},
				})
			end
		end
	end

	return dead, vacant
end

-- Assign new items to slots. To pick the right pool we build each
-- item's binding and classify it up front. If a dead or vacant setter
-- is available in the winning renderer's queue, reuse it (discarding
-- the just-built binding + node; never mounted, so any subscriptions
-- die with it). Otherwise append the new slot to that renderer's pool
-- in the returned SlotsByRenderer. Returns the new pools alongside a
-- flag indicating whether any were populated, so callers don't have
-- to scan pools afterwards to decide if a state update is needed.
local function assignNewItems<T>(
	newView: { T },
	newRange: Vector3,
	newKeyToItemIndexInView: { [string]: number? },
	dead: RecycleQueuesByRenderer<T>,
	vacant: RecycleQueuesByRenderer<T>,
	renderers: { (React.Binding<T?>) -> React.Node? }
): (SlotsByRenderer<T>, boolean)
	local newSlotsByRenderer: SlotsByRenderer<T> = createEmptyPools(#renderers) :: any
	local hasNewSlots = false

	for newKey, indexInView in newKeyToItemIndexInView do
		assert(indexInView ~= nil, "Luau")
		local value = newView[indexInView]

		local newLocatedItem: LocatedItem<T> = {
			contents = {
				type = "full",
				index = indexInView + (newRange.X - 1),
				key = newKey,
				value = value,
			},
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
	preAllocate: boolean?,

	getKey: ((value: T, index: number) -> string)?,
})
	local preAllocate = if props.preAllocate ~= nil then props.preAllocate else true

	local slotsByRenderer: SlotsByRenderer<T>, setSlotsByRenderer = React.useState(function()
		return createSlotsByRenderer(
			props.dimensions,
			props.virtualizedListController,
			props.direction,
			props.renderers,
			preAllocate
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

			-- Vacate any leftover dead setters. The slot stays in its pool
			-- (the pool is the renderer it committed to), just flipped to
			-- vacant so the next matching item can reuse it cheaply.
			-- TODO: Consider periodic compaction of excess vacant slots to bound pool growth.
			for _, deadQueue in dead do
				for _, deadSetter in deadQueue do
					deadSetter({
						contents = { type = "vacant" },
					})
				end
			end
		end)
	end, { props.virtualizedListController, getKey, slotsByRenderer, props.renderers } :: { unknown })

	local children: { [string]: React.Node } = {}
	for rendererIndex, pool in slotsByRenderer do
		for index, slot in pool do
			-- The outer rendererIndex is the structural pool identity, so
			-- numeric indices in different pools don't collide.
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
