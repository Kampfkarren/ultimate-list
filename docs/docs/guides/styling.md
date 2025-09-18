---
sidebar_position: 1
---
# Styling
UltimateList ScrollingFrames start out with default properties except for setting the size to 100% of the container. There are 3 ways to stylize a ScrollingFrame.

## Style the container

For things like size, you can style the container you put the ScrollingFrame into. For example, if you want a ScrollingFrame to be 300x300, you can do that like so:

```lua
return React.createElement("Frame", {
    Size = UDim2.fromOffset(300, 300),
}, {
    ScrollingFrame = React.createElement(UltimateList.Components.ScrollingFrame, {
        -- etc
    })
})
```

## Style sheets

ScrollingFrame comes with a `tag` property that can be used alongside [the Roblox UI styling system](https://create.roblox.com/docs/ui/styling) to do things like remove the background, change the scroll bar, etc.

## `native` property

When style sheets don't work, or when you need to hook onto events, you can use the `native` property, which will forward everything to the ScrollingFrame:

```lua
return React.createElement(UltimateList.Components.ScrollingFrame, {
    native = {
        BackgroundTransparency = 1,
    },

    -- etc
})
```

You cannot set the following keys, as UltimateList relies on them:
- **Size** - Always set to 100% of the container
- **CanvasSize** - Changes based on your [dimensions](../core-concepts/dimensions)
- **React.Change.AbsoluteWindowSize** - Use `onAbsoluteWindowSizeChanged: (Vector2) -> ()` prop instead.
- **React.Change.CanvasPosition** - Use `onScrollAxisChanged: (number) -> ()` prop instead, which gives you the position for the dominant axis (e.g. how far down if direction is Y).

There are some keys that will not error, but that you should use other ways of changing:
- **React.Tag** - Use `tag` prop instead.
- **ref** - Use `scrollingFrameRef` prop instead.
