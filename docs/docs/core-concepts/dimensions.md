---
sidebar_position: 3
---
# Dimensions
Dimensions define how elements are sized and placed. **You must know in advance the size of your elements.**

<details>
    <summary>Why do I need to specify dimensions? Other virtualized list libraries support automatic sizing.</summary>

    Doing this either carries extreme performance costs, worsens user experience, or regularly: both.

    There are two primary reasons for this requirement. The first is that a virtualized list has to be able to know what elements you're looking at in a given spot. If elements have a consistent height, then we can figure that out in constant time (e.g. if elements are 10px high, and we scroll down 30px, we'll see element #4). We can't do this unless we know the size of the elements. If the user jumps to a position away from what we've seen, we'd need to render every single element and figure out their size until we know which ones you're actually looking at.

    Secondly, you cannot show a scroll bar unless you know the total height. With user provided dimensions, you can calculate this trivially. With automatic sizing, you need to render every single element to know the total height.

    Virtualized list libraries that allow automatic sizing historically either accept a broken scroll bar, or more often hide the scroll bar entirely, which we do not find to be acceptable UX.

    While some elements are trickier than others, you can always find out the size of your elements in advance. For example, you can know the size text will be by using [`TextService:GetTextBoundsAsync`](https://create.roblox.com/docs/reference/engine/classes/TextService#GetTextBoundsAsync).
</details>

## Consistent, one-dimensional size
If you know the height of all your elements (or width, if going left to right) then you can use `UltimateList.Dimensions.consistentSize(size)`. The non-dominant axis will then be 100% of the window--in other words, every item in a vertical list will be 100% wide, and every item in a horizontal list will be 100% tall.

For example, a list where everything is 32px would use:

```lua
dimensions = UltimateList.Dimensions.consistentSize(32)
```

### Examples
- A vertical list of players.
- A vertical list of files.

## Consistent, two-dimensional size
When creating something like a grid, where every cell is the same size, you can use `Dimensions.consistentUDim2(udim2)`. For example, if you want a vertical grid of 100px tall elements with 4 items shown per row would use:

```lua
dimensions = UltimateList.Dimensions.consistentUDim2(UDim2.new(
    1/4, -- Horizontal scale: 1/4th of a row
    0, -- Horizontal offset, in this case 0px.
    0, -- Vertical scale: MUST be 0, since we are a vertical list.
    100 -- Vertical offset: 100px
))
```

These elements will be layed out left-aligned.

:::warning

You **must not** provide a scale for the dominant axis (Y if vertical, X if horizontal) because it doesn't make sense: what is 10% of a canvas whose height is determined by its contents?

:::

### Examples
- Grid of images

## Dynamically determined size and position

If your dimensions depend on the item, such as if you are including wrapped text or multiple types of items like titles and separators, then you can use `Dimensions.getter` to provide a function that will provide the size and position for a given item.

The usage of `Dimensions.getter` looks like this:
```lua
dimensions = UltimateList.Dimensions.getter(function(value, _index)
    return {
        size = UDim2.new(...),
        position = UDim2.new(...),
    }
end)
```

The callback you provide must be stateless, meaning that it must be able to know the size and position of an item through that item alone. That is to say, the position and size are not relative to anything. This usually involves baking in the data inside the items themselves. For example, if you had a chat, your item might look like:

```ts
type Item = {
    message: string,

    height: number,
    yOffset: number,
}
```

...where the list of items might look like:
```lua
{
    {
        message = "Hello!",
        height = 12,
        yOffset = 0,
    },

    {
        message = "Why hello there, how are you today?",
        height = 24,
        yOffset = 12, -- Height of last messages
    },

    {
        message = "I'm doing well!",
        height = 12,
        yOffset = 12 + 24, -- Height of last two messages
    }
}
```

...which then means our getter will look like:

```lua
dimensions = UltimateList.Dimensions.getter(function(value: Item)
    return {
        size = UDim2.new(1, 0, 0, value.height),
        position = UDim2.fromOffset(0, value.yOffset),
    }
end)
```

The other dimensions all operate in constant time for fetching elements, whereas getters perform an `O(log n)` binary search.

See [Supporting different items](../guides/supporting-different-items) for an example on real code using dynamic getters.

## Spaced dimensions

If you want to space items evenly, you can use `UltimateList.Dimensions.withSpacing(innerDimensions, spacing)`. For example, a list of 32px items with 8px in between would look like:

```lua
dimenions = UltimateList.Dimensions.withSpacing(
    UltimateList.Dimensions.consistentSize(32),
    8
)
```

This is better than including the spacing with your size as that would add additional space at the bottom of the canvas.

You can only use this with `consistentSize` or `consistentUDim2`. When using `consistentUDim2`, this spacing only applies to the dominant axis.
