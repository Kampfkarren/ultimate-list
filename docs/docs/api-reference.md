---
sidebar_position: 4
---
# API Reference

## Components

### `ScrollingFrame<T>`
Creates a ScrollingFrame that will make a virtualized list based on your specifications.

`T` is the type of the items we are representing.

**Props**
- `dataSource: DataSources.DataSource<T>`: The [data source](./core-concepts/data-sources) we are creating a list for.
- `dimensions: Dimensions.Dimensions<T>`: The [dimensions](./core-concepts/dimensions) that will determine how big an item is, and where it is placed.
- `renderer: Renderers.Renderer<T>`: The [renderer](./core-concepts/renderer) that will determine what an item looks like.
- `direction: "x" | "y"`: "y" for a vertical list, "x" for a horizontal list.

**Optional props**
- `tag: string`: A tag to apply onto the ScrollingFrame. Useful for using [the Roblox UI styling system](https://create.roblox.com/docs/ui/styling).
- `native: { [any]: any }`: All fields here will be applied on top of the ScrollingFrame. See also [styling with native](./guides/styling#native-property).
- `getKey: (value: T, index: number) -> string`: A function that will return a unique key for a given item. By default UltimateList will use the index, but you will want to specify this if your list is not append-only.
- `scrollingFrameRef: React.Ref<ScrollingFrame>`: A ref to the underlying ScrollingFrame. Note that the actual contents are stored in a separate frame that you cannot access.
- `onAbsoluteWindowSizeChanged: (newWindowSize: Vector2) -> ()`: A callback that will run when the [window size of the ScrollingFrame](https://create.roblox.com/docs/reference/engine/classes/ScrollingFrame#AbsoluteWindowSize) changes.
- `onScrollAxisChanged: (newScrollAxis: number) -> ()`: A callback that will run when the ScrollingFrame changes CanvasPosition. The number provided is the position of the dominant axis--so in a vertical list, it represents `CanvasPosition.Y`.

## DebugFlags
Flags for configuring UltimateList.

### `shouldLog`
A boolean that will enable verbose logging into the output.

## DataSources
The set of [data sources](./core-concepts/data-sources) that represent what items we are displaying. For all of these, `T` represents the type of the items you are displaying.

### `array`
```ts
DataSources.array<T>(
    array: { T }
): DataSource<T>
```

Represents a data source based on an immutable array. See also [the array data source](./core-concepts/data-sources#arrays).

### `mutableSource`
```ts
DataSources.mutableSource<T>(
    methods: MutableDataSourceMethods<T>
): DataSource<T>
```

Represents a data source based on an abstract mutable structure. See also [mutable sources](./core-concepts/data-sources#mutable-sources), which includes a full breakdown on what methods are accepted.

### `utilities.createGetSimpleCursor`
```ts
DataSources.utilities.createGetSimpleCursor<T>(
    get: (index: number) -> T,
    getLength: () -> number
): (startIndex: number) -> DataSourceCursor<T>?
```

Creates a wrapper around a simple getter function to make it produce the expected `DataSourceCursor` of `get`. See also [the documentation in mutable sources](./core-concepts/data-sources#get-startindex-number---datasourcecursort).

## Dimensions
The set of [dimensions](./core-concepts/dimensions) that represent how items are positioned and sized. For all of these, `T` represents the type of the items you are displaying.

### `consistentSize`
```ts
Dimensions.consistentSize<T>(
    size: number
): Dimensions<T>
```

Dictates that all items are of the same size. In a vertical list, this means they are all the same height. In a horizontal list, this means that they are all the same width.

See also: [consistent, one-dimensonal size](./core-concepts/dimensions#consistent-one-dimensional-size).

### `consistentUDim2`
```ts
Dimenions.consistentUDim2<T>(
    udim2: UDim2
): Dimensions<T>
```

Dictates that all items are of the same size, represented as a UDim2. The items will then be put one after another until they reach the end of the row/column, and wrap around.

See also: [consistent, two-dimensonal size](./core-concepts/dimensions#consistent-two-dimensional-size).

### `getter`
```ts
Dimensions.getter<T>(
    callback: (value: T, index: number) -> UDimRect
): Dimensions<T>
```

Specifies that the size and position of an item is not the same for all of them, and instead uses the callback provided to know what the size and position are.

See also: [dynamically determined size and position](./core-concepts/dimensions#dynamically-determined-size-and-position).

### `withSpacing`
```ts
Dimensions.withSpacing<T>(
    inner: Dimensions<T>,
    spacing: number
)
```

Given a consistent set of dimensions, will adding spacing in between each element.

See also: [spaced dimensions](./core-concepts/dimensions#spaced-dimensions).

## Renderers
The set of [renderers](./core-concepts/renderers) that dictate how an item turns into a React component to display. For all of these, `T` represents the type of the items you are displaying.

### `byState`
```ts
Renderers.byState<T>(
    callback: (T) -> React.Node
): Renderer<T>
```

Takes a callback that turns a direct value into a React node. When the user scrolls, we will trigger a re-render and call that callback again. When an item is no longer visible, it is unmounted--elements are not reused for different items.

See also ["State" section on the renderers documentation](./core-concepts/renderers#state).

### `byBinding`
```ts
Renderers.byBinding<T>(
    callback: (React.Binding<T?>) -> React.Node
): Renderer<T>
```

Takes a callback that provides a React node based on the provided binding. When the user scrolls, these elements will be re-used, and the binding will be updated directly. This means as the user scrolls, there will be zero React re-renders. The value you get will be nil if there is no item occupying that space.

See also ["Bindings" section on the renderers documentation](./core-concepts/renderers#bindings).

## Types
These are the exported types of UltimateList. If you are using Wally, use [`wally-package-types`](https://github.com/JohnnyMorganz/wally-package-types) to get access to them.

### `Dimensions<T>`
Tagged union for the [dimensions](./core-concepts/dimensions). The contents of this are not considered stable, and you should always use the [Dimensions](#dimensions) API directly.

### `DataSource<T>`
Tagged union for a [data source](./core-concepts/data-sources). The contents of this are not considered stable, and you should always use the [DataSources](#data-sources) API directly.

### `Renderer<T>`
Tagged union for a [renderer](./core-concepts/renderers). The contents of this are not considered stable, and you should always use the [Renderers](#renderers) API directly.

### `UDimRect`
```ts
type UDimRect = {
    size: UDim2,
    position: UDim2,
}
```

Used for [dimension getters](#getter).

### `DataSourceCursor<T>`
```ts
type DataSourceCursor<T> = {
    before: () -> DataSourceCursor<T>?,
    value: T,
    after: () -> DataSourceCursor<T>?,
}
```

Represents a place in a data source, and methods for how to go forwards and backwards from there. If `before` is nil, it is assumed there are no elements before it, and if `after` is nil, it is assumed there are no elements after it. Used for [mutable data sources](./core-concepts/data-sources#mutable-sources).

### `MutableDataSourceMethods<T>`
```ts
type MutableDataSourceMethods<T> = {
    -- Get a cursor to the nth element
    get: (startIndex: number) -> DataSourceCursor<T>?,

    -- Get the total length of the data source
    length: () -> number,

    -- Is given a callback to run when the data source changes.
    -- Returns a destructor to disconnect the function.
    bindToChanged: (callback: () -> ()) -> () -> (),

    -- The following have default definitions, but can be specialized to be more efficient.

    -- Get the final element (defaults to get(length()))
    back: (() -> T?)?,

    -- Get the elements from startIndex to and including endIndex.
    -- Defaults to using the `after` in your cursors.
    getByRange: ((startIndex: number, endIndex: number) -> { T })?,
}
```

Methods to pass into [`DataSources.mutableSource`](#mutablesource). Extensive documentation in the [mutable sources documentation](./core-concepts/data-sources#mutable-sources).
