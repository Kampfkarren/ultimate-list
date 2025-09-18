---
sidebar_position: 4
---
# Renderers
Renderers define what an element looks like. UltimateList will create a frame with the size and position specified by [your dimensions](./dimensions), and you fill it in.

## State
The simplest and most flexible approach is `UltimateList.Renderers.byState`. This takes a callback that will provide the value directly, as if it were a prop. These elements will then be mounted when visible, and unmounted when hidden.

A simple example for a virtualized list of strings would look like:

```lua
local e = React.createElement

-- ...
renderer = UltimateList.Renderers.byState(function(item: string)
    return e("TextLabel", {
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
        inventoryItems[item.key] = e(InventoryItem, {
            item = item,
        })
    end

    return e(PlayerCard, {
        name = name,
    }, inventoryItems)
end

-- ...
renderer = UltimateList.Renderers.byState(function(item: Player)
    return e(MyComplicatedComponent, {
        player = item,
    })
end)
```

## Bindings
If you can represent the data of your item entirely through properties, then you can opt instead to use `UltimateList.Renderers.byBinding`, which will provide a binding to the item.

For example, a player list might only need to represent the player's name as text, and thus can use:
```lua
renderer = UltimateList.Renderers.byBinding(function(playerBinding: React.Binding<Player?>)
    return e("TextLabel", {
        Size = UDim2.fromScale(1, 1),

        Text = playerBinding:map(function(player: Player?)
            return if player then player.DisplayName else ""
        end),
    })
end)
```

UltimateList will render as many of these elements as it thinks it will need (e.g. if your [dimensions are a consistent height](./dimensions#consistent-one-dimensional-size), then it will create as many of those as will fit in the height). It will then avoid any re-renders until it has to, such as when it realizes it doesn't have enough elements to render. That is why the binding returns `T?`--you must be able to represent an as-of-yet unused rendered item. It doesn't matter what you do with that, the container its in will be invisible no matter what, you just have to make sure you don't error.

## What should I choose?
Which renderer to choose depends on your use case. `byState` is significantly more flexible and will work with any kind of element, `byBinding` is more performant due to not triggering any React re-renders during scroll, but will not work for everything. Even when bindings do work, very complicated UIs will have significantly more complicated code and need to use more trickery than elements using state.
