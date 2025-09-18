# Core Concepts
In [the introduction](../), you saw an example of a simple UltimateList.

```lua
return React.createElement(UltimateList.Components.ScrollingFrame, {
    dataSource = UltimateList.DataSources.array(letters),

    dimensions = UltimateList.Dimensions.consistentSize(48),

    renderer = UltimateList.Renderers.byState(function(value)
        return React.createElement("TextLabel", {
            BackgroundColor3 = Color3.new(1, 1, 1),
            Font = Enum.Font.BuilderSansBold,
            Text = value,
            TextColor3 = Color3.new(0, 0, 0),
            TextSize = 36,
            Size = UDim2.fromScale(1, 1),
        })
    end),

    direction = "y",
})
```

There are three interesting properties here:
- The [data source](./data-sources), which represents what data it has available
- The [dimensions](./dimensions), which specify how the UI is layed out and shaped.
- The [renderer](./renderers), which specify how the elements will then be displayed.

You will learn each of these step by step.
