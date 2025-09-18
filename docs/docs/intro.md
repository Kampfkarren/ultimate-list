---
slug: /
sidebar_position: 1
---
# Introduction
UltimateList is a library for creating fast and efficient virtualized lists in Roblox. A virtualized list is a scrolling frame that only creates elements for items that can actually be seen. This puts less work on the engine, defers running code in React components until they can be seen (as well as cleaning up when they're not), and in some cases can do this while also performing zero React re-renders as a user interacts with the list.

<!-- TODO: Show video comparing non-virtualized and virtualized lists -->

UltimateList supports:
- Arbitrarily sized and positioned elements, so it is just as easy to create a list as it is a grid.
    - Extra optimizations are provided for lists with elements of consistent sizes.
- Rendering elements through simple state, or allowing for the use of bindings to avoid re-renders while scrolling.
- Strictly typed Luau.

## Examples

A basic list can be made with the following code:
```lua
local letters = {}
for offset = 0, 25 do
    table.insert(letters, string.char(string.byte("A") + offset))
end

return e("Frame", {
    Size = UDim2.fromOffset(300, 300),
}, {
    ScrollingFrame = e(UltimateList.Components.ScrollingFrame, {
        dataSource = UltimateList.DataSources.array(letters),

        dimensions = UltimateList.Dimensions.consistentSize(48),

        renderer = UltimateList.Renderers.byState(function(value)
            return e("TextLabel", {
                BackgroundColor3 = Color3.new(1, 1, 1),
                Font = Enum.Font.BuilderSansBold,
                Text = value,
                TextColor3 = Color3.new(0, 0, 0),
                TextSize = 36,
                Size = UDim2.fromScale(1, 1),
            })
        end),

        direction = "y",
    }),
})
```

<!-- TODO: Image -->

Want a grid instead? Just change your [dimensions](./core-concepts/dimensions).
```lua
local letters = {}
for offset = 0, 25 do
    table.insert(letters, string.char(string.byte("A") + offset))
end

return e("Frame", {
    Size = UDim2.fromOffset(300, 300),
}, {
    ScrollingFrame = e(UltimateList.Components.ScrollingFrame, {
        dataSource = UltimateList.DataSources.array(letters),
        
        dimensions = UltimateList.Dimensions.consistentUDim2(
            UDim2.new(0.33, 0, 0, 72)
        ),

        renderer = UltimateList.Renderers.byState(function(value)
            return e("TextLabel", {
                BackgroundColor3 = Color3.new(1, 1, 1),
                Font = Enum.Font.BuilderSansBold,
                Text = value,
                TextColor3 = Color3.new(0, 0, 0),
                TextSize = 36,
                Size = UDim2.fromScale(1, 1),
            })
        end),

        direction = "y",
    }),
})
```

<!-- TODO: Image -->

## Installation
UltimateList is available on [Wally](https://wally.run/). After installing Wally, add the following to your `wally.toml`:

<!-- TODO: Can the version number be automated? -->
```toml
UltimateList = "kampfkarren/ultimate-list@1.0.0"
```

After doing that, run `wally install`. To make strict typing easier, you may also run [`wally-package-types`](https://github.com/JohnnyMorganz/wally-package-types) to re-export the public types.

UltimateList is built on [React](https://roblox.github.io/roact-alignment/).
