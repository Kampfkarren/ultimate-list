---
sidebar_position: 4
---
# Renderers
Renderers define what an element looks like. UltimateList will create a frame with the size and position specified by [your dimensions](./dimensions), and you fill it in.

## State
The simplest and most flexible approach is `UltimateList.Renderers.byState`. This takes a callback that will provide the value directly, as if it were a prop. These elements will then be mounted when visible, and unmounted when hidden.

A simple example for a virtualized list of strings would look like:

```lua
-- ...
renderer = UltimateList.Renderers.byState(function(item: string)
    return React.createElement("TextLabel", {
        -- UltimateList puts your item in a frame matching
        -- your specified size and position.
        Size = UDim2.fromScale(1, 1),
        Text = item,
    })
end)
```

...but this can of course get more complicated, with things like dynamic children and hooks:
```lua
-- Example of component that takes full advantage of state
local function MyComplicatedComponent(props: {
    player: Player,
})
    local inventory = useInventory(props.player)
    local inventoryItems = {}

    for _, item in inventory do
        inventoryItems[item.key] = React.createElement(InventoryItem, {
            item = item,
        })
    end

    return React.createElement(PlayerCard, {
        name = name,
    }, inventoryItems)
end

-- ...
renderer = UltimateList.Renderers.byState(function(item: Player)
    return React.createElement(MyComplicatedComponent, {
        player = item,
    })
end)
```

## Bindings
If you can represent the data of your item entirely through properties, then you can opt instead to use `UltimateList.Renderers.byBinding`, which will provide a binding to the item.

For example, a player list might only need to represent the player's name as text, and thus can use:
```lua
renderer = UltimateList.Renderers.byBinding(function(playerBinding: React.Binding<Player?>)
    return React.createElement("TextLabel", {
        Size = UDim2.fromScale(1, 1),

        Text = playerBinding:map(function(player: Player?)
            return if player then player.DisplayName else ""
        end),
    })
end)
```

UltimateList will render as many of these elements as it thinks it will need (e.g. if your [dimensions are a consistent height](./dimensions#consistent-one-dimensional-size), then it will create as many of those as will fit in the height). It will then avoid any re-renders until it has to, such as when it realizes it doesn't have enough elements to render. That is why the binding returns `T?`--you must be able to represent an as-of-yet unused rendered item. It doesn't matter what you do with that, the container its in will be invisible no matter what, you just have to make sure you don't error.

## Typed Bindings
If your list contains multiple kinds of items (e.g. images, text, and buttons), you can use `UltimateList.Renderers.byTypedBinding`. This gives you the zero-rerender recycling performance of `byBinding`, but with separate recycling pools for each item type. Slots are never recycled across types, so each type can safely use different hooks and component trees.

You provide an ordered array of self-classifying renderers. Each renderer takes a `Binding<T?>` and returns either a `React.Node` ("I handle this value") or `nil` ("try the next renderer"). When a new item enters the viewport, renderers are tried in array order; the first to return a non-nil node claims the slot, and its returned node becomes the slot's subtree for life.

```lua
renderer = UltimateList.Renderers.byTypedBinding({
    primaryRendererIndex = 1,

    renderers = {
        -- Text rows (most common; primary).
        function(binding: React.Binding<Item?>): React.Node?
            local current = binding:getValue()
            if current ~= nil and current.type ~= "text" then
                return nil
            end

            return React.createElement("TextLabel", {
                Size = UDim2.fromScale(1, 1),
                Font = Enum.Font.BuilderSans,
                TextSize = 20,
                Text = binding:map(function(item: Item?)
                    return if item and item.type == "text" then item.text else ""
                end),
            })
        end,

        -- Category headers.
        function(binding: React.Binding<Item?>): React.Node?
            local current = binding:getValue()
            if current ~= nil and current.type ~= "category" then
                return nil
            end

            return React.createElement("TextLabel", {
                Size = UDim2.fromScale(1, 1),
                Font = Enum.Font.BuilderSansBold,
                TextSize = 30,
                Text = binding:map(function(item: Item?)
                    return if item and item.type == "category" then item.name else ""
                end),
            })
        end,
    },
})
```

:::info Contract
- **Return `nil` only when `binding:getValue()` is non-nil and not a type your renderer handles.** Early-return before subscribing to the binding -- decliners' subtrees are discarded, and any `binding:map` subscriptions they create leak until GC.
- **When `primaryRendererIndex` is set, that renderer is additionally called with a nil-valued binding for each pre-allocated slot and must return a non-nil node.** In practice this means your `binding:map` callbacks should fall back to empty strings / defaults when the value is nil (the same thing you'd do in `byBinding`).
- **Stable key implies stable type.** If two renders of your data source emit the same key, they must resolve to the same renderer. If you need an item to change type, give it a new key.
:::

You optionally provide:
- **`primaryRendererIndex`**: the index (1-based) of the renderer to pre-allocate slots for. When set, UltimateList mounts a starting pool of slots of that renderer's type so items of that type can fill them without triggering a React re-render on first appearance. Slots for other renderers are created lazily as matching items scroll in. When omitted (`nil`), no pre-allocation happens -- slots are created on demand for every type. Set this only when one renderer clearly dominates your list; for balanced heterogeneous lists, leaving it unset avoids mounting pre-alloc slots that won't be reused. Slot pools currently only grow -- if your item distribution shifts drastically over time, the combined pool size tracks the historical worst case per renderer.

## What should I choose?
Which renderer to choose depends on your use case. `byState` is significantly more flexible and will work with any kind of element, `byBinding` is more performant due to not triggering any React re-renders during scroll, but will not work for everything. Even when bindings do work, very complicated UIs will have significantly more complicated code and need to use more trickery than elements using state. `byTypedBinding` sits in between: it gives you the binding performance of `byBinding` while supporting heterogeneous item types that would otherwise require `byState`.
