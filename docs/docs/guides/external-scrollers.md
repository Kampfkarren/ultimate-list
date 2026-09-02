---
sidebar_position: 3
---
# Using an external ScrollingFrame

Use `ScrollingFrameContent` when another component creates and owns the native ScrollingFrame. This is useful for containers such as sheets that already provide scrolling behavior and expose a ref.

`ScrollingFrameContent` renders inside the existing scrolling canvas. It reuses the same virtualization controller, dimensions, keys, and renderers as `Components.ScrollingFrame`, but it never creates or configures another ScrollingFrame.

```lua
local scrollingFrameRef = React.useRef(nil :: ScrollingFrame?)

return React.createElement("ScrollingFrame", {
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(),
    ScrollingDirection = Enum.ScrollingDirection.Y,
    Size = UDim2.fromOffset(400, 300),
    ref = scrollingFrameRef,
}, {
    List = React.createElement(UltimateList.Components.ScrollingFrameContent, {
        dataSource = UltimateList.DataSources.array(measuredRows),
        dimensions = UltimateList.Dimensions.getter(function(row)
            return {
                position = UDim2.fromOffset(0, row.yOffset),
                size = UDim2.new(1, 0, 0, row.height),
            }
        end),
        renderer = UltimateList.Renderers.byState(renderRow),
        getKey = function(row)
            return row.id
        end,
        direction = "y",
        scrollingFrameRef = scrollingFrameRef,
    }),
})
```

## Ownership contract

- The owner creates, styles, and destroys the ScrollingFrame. UltimateList only reads its `AbsoluteWindowSize` and `CanvasPosition`.
- `ScrollingFrameContent` must be rendered inside the referenced ScrollingFrame's canvas. Do not place it beside the ScrollingFrame or inside another ScrollingFrame.
- The ref must resolve to that ancestor ScrollingFrame when effects run and remain attached to the same instance while the content is mounted.
- The owner's `ScrollingDirection` and canvas-sizing axis must agree with `direction`.
- The component reports the list extent through its transparent root's `Size`. Use the corresponding `AutomaticCanvasSize` axis, or otherwise make the owner derive its CanvasSize from that content size.
- The list's dominant-axis origin and each getter position use the external canvas coordinate system. Getter positions must be absolute, ordered, and use offsets on the dominant axis.
- The external ScrollingFrame supplies viewport clipping. Intermediate content containers must not clip the counter-translated renderer frame before it reaches that viewport.

The renderer frame moves with the external CanvasPosition inside the scrolling canvas. UltimateList samples again during `RenderStepped` because deferred ScrollingFrame events can arrive before related layout properties have flushed together. Rows still use UltimateList's existing translated absolute positions inside that frame.

## Pre-measured variable rows

Asynchronous measurement happens before an item is inserted into the data source. Store the completed size and absolute offset on the item, then return them synchronously from `Dimensions.getter`.

When an earlier measurement changes, recompute the affected later offsets and provide an updated data source or dimensions getter. UltimateList does not read rendered row `AbsoluteSize` values and does not estimate missing heights.
